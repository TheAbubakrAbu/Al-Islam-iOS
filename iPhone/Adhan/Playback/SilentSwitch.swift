import Foundation
import AudioToolbox

#if os(iOS)

/// Reads Silent Mode: the ring/silent switch, or the Action button set to Silent Mode on the
/// phones that have no switch.
///
/// iOS has no API for it. What it does have is a system sound that OBEYS it: play half a second of
/// silence through AudioServices with the UI-sound flag set, and time the completion. On a silenced
/// phone the sound is dropped and the completion returns at once; on an audible phone it returns
/// after the half second. The trick dates from iOS 5 and has survived every release since. It only
/// answers truthfully while the audio session is on a category that respects the switch
/// (`.ambient`, `.soloAmbient`), which is the category the in-app adhan uses whenever it is meant
/// to respect it; under `.playback` the sound plays regardless and the answer is always `.audible`.
///
/// Why a hack is worth it: with "Play In-App Adhan in Silent Mode" off, the adhan used to start on
/// `.ambient` without looking, which on a silenced phone meant a three-minute recording running
/// inaudibly under a banner saying ADHAN PLAYING (Abu, 2026-10-19: "nothing is playing and it
/// shouldn't be playing"). Now the player asks first, and a silenced phone gets a Play button.
enum SilentSwitch {
    enum State {
        case muted, audible
        /// The completion never came (two seconds), or the probe sound could not be made. Treated
        /// as audible by the caller: an adhan that plays by mistake is a lesser wrong than one that
        /// never plays.
        case unknown
    }

    #if DEBUG
    /// `-fakeSilentSwitch on|off` pins the answer, since the simulator has no switch; the tests set
    /// it directly. Nil asks the real switch.
    nonisolated(unsafe) static var debugOverride: State? = {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-fakeSilentSwitch"), index + 1 < args.count else { return nil }
        return args[index + 1] == "on" ? .muted : .audible
    }()
    #endif

    /// The probe sound's length. Muted, the completion fires in a few milliseconds; audible, after
    /// this long. The verdict line is drawn well inside the gap.
    private static let probeSeconds: TimeInterval = 0.5
    private static let lock = NSLock()
    private static var soundID: SystemSoundID = 0

    /// Asks the switch. Call with the session on `.ambient` (see above); never blocks the caller.
    static func probe() async -> State {
        #if DEBUG
        if let debugOverride { return debugOverride }
        #endif
        guard let id = probeSoundID() else { return .unknown }
        return await withCheckedContinuation { (continuation: CheckedContinuation<State, Never>) in
            let gate = ResumeOnce(continuation)
            let started = DispatchTime.now()
            AudioServicesPlaySystemSoundWithCompletion(id) {
                let elapsed = Double(DispatchTime.now().uptimeNanoseconds - started.uptimeNanoseconds) / 1_000_000_000
                gate.resume(elapsed < probeSeconds * 0.4 ? .muted : .audible)
            }
            // Never leave the adhan waiting on a completion that does not come.
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 2) {
                gate.resume(.unknown)
            }
        }
    }

    /// The completion and the timeout race; whichever lands first resumes, the other is dropped.
    private final class ResumeOnce: @unchecked Sendable {
        private let lock = NSLock()
        private var continuation: CheckedContinuation<State, Never>?

        init(_ continuation: CheckedContinuation<State, Never>) {
            self.continuation = continuation
        }

        func resume(_ state: State) {
            lock.lock()
            let pending = continuation
            continuation = nil
            lock.unlock()
            pending?.resume(returning: state)
        }
    }

    /// The registered probe sound, made on first use.
    private static func probeSoundID() -> SystemSoundID? {
        lock.lock()
        defer { lock.unlock() }
        if soundID != 0 { return soundID }
        guard let url = silenceFileURL() else { return nil }
        var id: SystemSoundID = 0
        guard AudioServicesCreateSystemSoundID(url as CFURL, &id) == kAudioServicesNoError, id != 0 else { return nil }
        // A UI sound is what the switch silences. Without the flag the probe would play through it
        // and answer "audible" on every phone.
        var isUISound: UInt32 = 1
        AudioServicesSetProperty(kAudioServicesPropertyIsUISound,
                                 UInt32(MemoryLayout<SystemSoundID>.size), &id,
                                 UInt32(MemoryLayout<UInt32>.size), &isUISound)
        soundID = id
        return id
    }

    /// Half a second of silence as a WAV in Caches, written once. Generated rather than bundled:
    /// eight kilobytes of zeros are not worth a project entry, and Caches being emptied just means
    /// it is written again.
    private static func silenceFileURL() -> URL? {
        guard let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        let url = caches.appendingPathComponent("silent-switch-probe.wav")
        if FileManager.default.fileExists(atPath: url.path) { return url }

        let sampleRate: UInt32 = 8000
        let channels: UInt16 = 1
        let bitsPerSample: UInt16 = 16
        let frames = UInt32(Double(sampleRate) * probeSeconds)
        let bytesPerFrame = UInt32(channels) * UInt32(bitsPerSample / 8)
        let dataSize = frames * bytesPerFrame

        var data = Data()
        func tag(_ text: String) { data.append(contentsOf: Array(text.utf8)) }
        func u32(_ value: UInt32) { var little = value.littleEndian; data.append(Data(bytes: &little, count: 4)) }
        func u16(_ value: UInt16) { var little = value.littleEndian; data.append(Data(bytes: &little, count: 2)) }
        tag("RIFF"); u32(36 + dataSize); tag("WAVE")
        tag("fmt "); u32(16); u16(1); u16(channels); u32(sampleRate)
        u32(sampleRate * bytesPerFrame); u16(UInt16(bytesPerFrame)); u16(bitsPerSample)
        tag("data"); u32(dataSize)
        data.append(Data(count: Int(dataSize)))

        do {
            try data.write(to: url, options: .atomic)
        } catch {
            return nil
        }
        return url
    }
}

#endif
