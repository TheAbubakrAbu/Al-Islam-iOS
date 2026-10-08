#if os(iOS)
import Foundation
import AVFoundation
import os

/// The notification cuts of the bundled adhans, rendered ON THE DEVICE from the full recording.
///
/// iOS refuses a notification sound longer than 30 seconds, so every adhan needs a 30-second cut and
/// a short excerpt, and `UNNotificationSound` only plays PCM/IMA4 in a .caf - AAC is refused - which
/// is four to six times the bytes of the AAC full recording. The app used to ship all 26 cuts: 7 MB of
/// IMA4 on every install, almost all of it for adhans the listener never picks. Now the full recording
/// is the only bundled asset, and the two cuts of the SELECTED adhan are written into Library/Sounds,
/// where `UNNotificationSound(named:)` looks right after the bundle.
///
/// Each cut follows the recipe of the file it replaces - same start offset, same length, same linear
/// fades (measured off the shipped files in 50 ms windows; madina's 30-second cut also carried +5.7 dB,
/// kept) - so a listener hears exactly what they heard before. The recipes are keyed by the adhan id;
/// the alert tones (echo, takbir, chime, ring, alarm) are a few seconds long, stay bundled as they were,
/// and never come through here.
enum AdhanClipStore {
    struct Recipe {
        /// Seconds into the full recording where the cut starts.
        let start: Double
        /// Length of the cut in seconds (every 30-second cut is under 30).
        let length: Double
        let fadeIn: Double
        let fadeOut: Double
        /// Linear gain applied to the samples (1 = as recorded).
        let gain: Float
    }

    struct Cuts {
        let thirty: Recipe
        let short: Recipe
    }

    private static func cut(_ start: Double, _ length: Double, in fadeIn: Double, out fadeOut: Double,
                            gain: Float = 1) -> Recipe {
        Recipe(start: start, length: length, fadeIn: fadeIn, fadeOut: fadeOut, gain: gain)
    }

    /// One entry per adhan in `Settings.supportedAdhanSounds` (the tones are absent on purpose).
    static let cuts: [String: Cuts] = [
        "aaqib":        Cuts(thirty: cut(0,     27.700, in: 0,    out: 0.60), short: cut(0,     10.500, in: 0,    out: 0.60)),
        "abdulbaset":   Cuts(thirty: cut(0,     26.848, in: 0.15, out: 0.10), short: cut(0,     12.492, in: 0.15, out: 0.05)),
        "abdulghaffar": Cuts(thirty: cut(0.060, 29.200, in: 0.10, out: 0.45), short: cut(0.060, 12.500, in: 0.10, out: 0.45)),
        "al-qatami":    Cuts(thirty: cut(0,     26.568, in: 0.25, out: 0),    short: cut(0,     13.513, in: 0.25, out: 0)),
        "alaqsa-2":     Cuts(thirty: cut(0,     28.609, in: 0,    out: 0.10), short: cut(0,     12.500, in: 0,    out: 0.45)),
        "alaqsa":       Cuts(thirty: cut(0.037, 25.844, in: 0,    out: 0.10), short: cut(0.037, 12.500, in: 0,    out: 0.45)),
        "egypt":        Cuts(thirty: cut(0,     29.200, in: 0.05, out: 0.45), short: cut(0,     12.500, in: 0.05, out: 0.10)),
        "madina":       Cuts(thirty: cut(0,     29.466, in: 0.20, out: 0, gain: 1.92), short: cut(0, 8.140, in: 0.15, out: 0)),
        "makkah":       Cuts(thirty: cut(0,     24.719, in: 0.15, out: 0.10), short: cut(0,     11.147, in: 0.15, out: 0.10)),
        "minshawi-1":   Cuts(thirty: cut(1.163, 27.829, in: 0.30, out: 0.05), short: cut(1.163, 12.295, in: 0.30, out: 0.10)),
        "minshawi-2":   Cuts(thirty: cut(0.350, 29.071, in: 0.05, out: 0.05), short: cut(0.350, 12.084, in: 0.05, out: 0.05)),
        "serene":       Cuts(thirty: cut(0,     29.400, in: 0.05, out: 1.25), short: cut(0,     17.400, in: 0.05, out: 0.50)),
        "zakariya":     Cuts(thirty: cut(0,     22.571, in: 0.05, out: 0.10), short: cut(0,     12.500, in: 0.05, out: 0.45))
    ]

    /// Bump when a recipe or the rendering changes, so existing installs re-render.
    private static let recipeVersion = 1
    private static let stampsKey = "adhanClipStamps"
    private static let logger = Logger(subsystem: "com.Quran.Elmallah.Islamic-Pillars", category: "AdhanClipStore")

    // MARK: - Where the cuts live

    /// `Library/Sounds`: the one place outside the bundle that `UNNotificationSound(named:)` searches.
    static var soundsDirectory: URL {
        let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library")
        return library.appendingPathComponent("Sounds", isDirectory: true)
    }

    /// The file a resource name ("makkah-30") resolves to once rendered.
    static func fileURL(for resource: String) -> URL {
        soundsDirectory.appendingPathComponent("\(resource).caf")
    }

    /// Whether the cut for a resource name exists and was rendered by this recipe version from this
    /// bundled recording. Cheap (one file-exists check plus a defaults read) and safe from any thread.
    static func isReady(resource: String) -> Bool {
        guard let id = adhanID(for: resource), let stamp = expectedStamp(for: id) else { return false }
        let stamps = UserDefaults.standard.dictionary(forKey: stampsKey) as? [String: String] ?? [:]
        return stamps[resource] == stamp && FileManager.default.fileExists(atPath: fileURL(for: resource).path)
    }

    /// "makkah-30" / "makkah-short" -> "makkah", or nil for anything that is not an adhan cut.
    static func adhanID(for resource: String) -> String? {
        for suffix in [Settings.adhanNotificationClipSuffix, Settings.adhanShortClipSuffix] where resource.hasSuffix(suffix) {
            let id = String(resource.dropLast(suffix.count))
            return cuts[id] != nil ? id : nil
        }
        return nil
    }

    /// Recipe version + the bundled recording's byte size: a new recording or a new recipe re-renders,
    /// a reinstall of the same build does not.
    private static func expectedStamp(for id: String) -> String? {
        guard let url = Bundle.main.url(forResource: id, withExtension: "caf"),
              let size = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.size] as? NSNumber else {
            return nil
        }
        return "v\(recipeVersion)|\(size.int64Value)"
    }

    // MARK: - Rendering

    private static let queue = DispatchQueue(label: "com.Quran.Elmallah.Islamic-Pillars.adhan-clips", qos: .utility)
    private static let inFlightLock = NSLock()
    private static var inFlight: [String: [(Bool) -> Void]] = [:]

    /// Makes sure both cuts of an adhan exist in Library/Sounds, rendering whichever is missing or
    /// stale on a background queue. `onFinished` runs on the main queue ONLY when rendering happened
    /// (true = both cuts now exist, false = rendering failed); when nothing needed doing it is not
    /// called at all, so callers can treat it as "the sound files changed, schedule again". Repeated
    /// calls for an adhan already being rendered attach to that render instead of starting another.
    static func ensureClips(for id: String, onFinished: ((Bool) -> Void)? = nil) {
        guard Settings.isAppProcess, cuts[id] != nil else { return }
        let resources = [id + Settings.adhanNotificationClipSuffix, id + Settings.adhanShortClipSuffix]
        guard !resources.allSatisfy(isReady(resource:)) else { return }

        inFlightLock.lock()
        if inFlight[id] != nil {
            if let onFinished { inFlight[id]?.append(onFinished) }
            inFlightLock.unlock()
            return
        }
        inFlight[id] = onFinished.map { [$0] } ?? []
        inFlightLock.unlock()

        queue.async {
            let ok = renderBothCuts(for: id)
            inFlightLock.lock()
            let callbacks = inFlight.removeValue(forKey: id) ?? []
            inFlightLock.unlock()
            DispatchQueue.main.async {
                Settings.invalidateAdhanSoundResourceCache()
                callbacks.forEach { $0(ok) }
            }
        }
    }

    private static func renderBothCuts(for id: String) -> Bool {
        guard let cuts = cuts[id], let stamp = expectedStamp(for: id),
              let source = Bundle.main.url(forResource: id, withExtension: "caf") else { return false }
        do {
            try FileManager.default.createDirectory(at: soundsDirectory, withIntermediateDirectories: true)
        } catch {
            logger.error("Library/Sounds could not be created: \(error.localizedDescription)")
            return false
        }
        var allGood = true
        for (suffix, recipe) in [(Settings.adhanNotificationClipSuffix, cuts.thirty), (Settings.adhanShortClipSuffix, cuts.short)] {
            let resource = id + suffix
            if isReady(resource: resource) { continue }
            do {
                try render(recipe, from: source, to: fileURL(for: resource))
                var stamps = UserDefaults.standard.dictionary(forKey: stampsKey) as? [String: String] ?? [:]
                stamps[resource] = stamp
                UserDefaults.standard.set(stamps, forKey: stampsKey)
                logger.info("Rendered \(resource).caf")
            } catch {
                allGood = false
                logger.error("Rendering \(resource).caf failed: \(error.localizedDescription)")
            }
        }
        if allGood { pruneOtherAdhans(keeping: id) }
        return allGood
    }

    /// A listener has one adhan selected at a time; the cuts of the others are a re-render away.
    private static func pruneOtherAdhans(keeping id: String) {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: soundsDirectory.path) else { return }
        var stamps = UserDefaults.standard.dictionary(forKey: stampsKey) as? [String: String] ?? [:]
        for file in files where file.hasSuffix(".caf") {
            let resource = String(file.dropLast(4))
            guard let owner = adhanID(for: resource), owner != id else { continue }
            try? fm.removeItem(at: soundsDirectory.appendingPathComponent(file))
            stamps.removeValue(forKey: resource)
        }
        UserDefaults.standard.set(stamps, forKey: stampsKey)
    }

    private enum RenderError: Error { case emptySource, converter, noOutput }

    /// Decode the AAC full recording, take the recipe's window, fold to mono, apply gain and the linear
    /// fades, resample down to 22.05 kHz where the source is higher, and write IMA4 into a .caf - the
    /// same shape the shipped cuts had (mono, 22.05 kHz or the recording's own lower rate).
    private static func render(_ recipe: Recipe, from source: URL, to destination: URL) throws {
        let file = try AVAudioFile(forReading: source)
        let sourceFormat = file.processingFormat
        let sourceRate = sourceFormat.sampleRate
        let channels = Int(sourceFormat.channelCount)
        let totalFrames = AVAudioFramePosition(file.length)

        let startFrame = min(max(0, AVAudioFramePosition(recipe.start * sourceRate)), max(0, totalFrames - 1))
        let wanted = AVAudioFrameCount(recipe.length * sourceRate)
        let available = AVAudioFrameCount(max(0, totalFrames - startFrame))
        let frames = min(wanted, available)
        guard frames > 0, let monoFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sourceRate,
                                                          channels: 1, interleaved: false) else {
            throw RenderError.emptySource
        }

        file.framePosition = startFrame
        guard let input = AVAudioPCMBuffer(pcmFormat: sourceFormat, frameCapacity: frames) else { throw RenderError.emptySource }
        try file.read(into: input, frameCount: frames)
        let count = Int(input.frameLength)
        guard count > 0, let mono = AVAudioPCMBuffer(pcmFormat: monoFormat, frameCapacity: AVAudioFrameCount(count)),
              let out = mono.floatChannelData?[0], let inData = input.floatChannelData else { throw RenderError.emptySource }
        mono.frameLength = AVAudioFrameCount(count)

        // Fold-down (an average of the channels), gain, then the fades - all linear, like `afade`.
        let scale = recipe.gain / Float(channels)
        for i in 0..<count {
            var sum: Float = 0
            for ch in 0..<channels { sum += inData[ch][i] }
            out[i] = sum * scale
        }
        let fadeInFrames = min(count, Int(recipe.fadeIn * sourceRate))
        if fadeInFrames > 0 {
            for i in 0..<fadeInFrames { out[i] *= Float(i) / Float(fadeInFrames) }
        }
        let fadeOutFrames = min(count, Int(recipe.fadeOut * sourceRate))
        if fadeOutFrames > 0 {
            for i in 0..<fadeOutFrames { out[count - 1 - i] *= Float(i) / Float(fadeOutFrames) }
        }
        // IMA4 is 16-bit inside; keep the samples where a 16-bit converter can represent them.
        for i in 0..<count { out[i] = max(-1, min(1, out[i])) }

        let outputRate = min(sourceRate, 22_050)
        var rendered = mono
        if outputRate != sourceRate {
            guard let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: outputRate,
                                                   channels: 1, interleaved: false),
                  let converter = AVAudioConverter(from: monoFormat, to: outputFormat) else { throw RenderError.converter }
            let outputFrames = AVAudioFrameCount(Double(count) * outputRate / sourceRate) + 64
            guard let resampled = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: outputFrames) else {
                throw RenderError.converter
            }
            var consumed = false
            var conversionError: NSError?
            let status = converter.convert(to: resampled, error: &conversionError) { _, outStatus in
                if consumed {
                    outStatus.pointee = .endOfStream
                    return nil
                }
                consumed = true
                outStatus.pointee = .haveData
                return mono
            }
            guard status != .error, conversionError == nil, resampled.frameLength > 0 else { throw RenderError.converter }
            rendered = resampled
        }

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatAppleIMA4,
            AVSampleRateKey: outputRate,
            AVNumberOfChannelsKey: 1
        ]
        let temporary = destination.deletingLastPathComponent()
            .appendingPathComponent(".\(destination.lastPathComponent).\(UUID().uuidString).tmp.caf")
        try? FileManager.default.removeItem(at: temporary)
        do {
            let writer = try AVAudioFile(forWriting: temporary, settings: settings,
                                         commonFormat: .pcmFormatFloat32, interleaved: false)
            try writer.write(from: rendered)
        }
        guard (try? FileManager.default.attributesOfItem(atPath: temporary.path))?[.size] as? NSNumber != nil else {
            throw RenderError.noOutput
        }
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: temporary, to: destination)
    }
}
#endif
