#if os(iOS)
import SwiftUI
import AVFoundation

// Hearing a variant, not just reading it. For every place Warsh, Qalun, ad-Duri or Shubah reads a
// word differently from Hafs, the SAME reciter reading the verse both ways, so the two clips differ
// in the reading and in nothing else: a pair drawn from two shaykhs would differ in voice, pace
// and maqam as well, and teach nothing about the variant. al-Bazzi, Qunbul, as-Susi and the rest
// have no reciter who published both sides with timings, so they carry no clips: a fact about
// the world, shown as "no recording", never as a button that does nothing.
//
// The table is Tilawa's (Jamil Hammoudeh, with permission), built into
// Resources/Data/Quran/QiraatVariantAudio.json.xz by Scripts/build_qiraat_variant_audio.py.
// A clip is a whole per-verse file (EveryAyah) or a span inside a full-surah recording
// (mp3quran, the servers the app already streams), seeked to and stopped at its offsets.

final class QiraatVariantAudioStore: @unchecked Sendable {
    static let shared = QiraatVariantAudioStore()

    struct Clip: Equatable {
        let url: URL
        /// nil for a whole per-verse file.
        let startMs: Int?
        let endMs: Int?
    }

    struct Pair: Equatable {
        let reciter: String
        let hafs: Clip
        let riwayah: Clip
    }

    private struct Source {
        let reciter: String
        let isSpan: Bool
        let hafsBase: String
        let riwayahBase: String
    }

    static let isBundled: Bool = ThemesPack.url("QiraatVariantAudio") != nil

    private let lock = NSLock()
    private var sources: [Source] = []
    /// tag -> surah -> hafs ayah -> [ayah, source, h0, h1, r0, r1]
    private var table: [String: [Int: [Int: [Int]]]] = [:]
    private var loaded = false

    private init() {}

    /// Reads the clip table off the calling thread (the explorer's detached task), once.
    func prewarm() {
        load()
    }

    /// The riwayat that have any clips at all.
    var tags: [String] {
        load()
        return Array(table.keys)
    }

    func hasClips(tag: String) -> Bool {
        load()
        return table[tag] != nil
    }

    func pair(tag: String, surah: Int, ayah: Int) -> Pair? {
        load()
        guard let row = table[tag]?[surah]?[ayah], row.count == 6,
              sources.indices.contains(row[1]) else { return nil }
        let source = sources[row[1]]
        func clip(base: String, start: Int, end: Int) -> Clip? {
            let path: String
            if source.isSpan {
                path = base + String(format: "%03d.mp3", surah)
            } else {
                path = base + "/" + String(format: "%03d%03d.mp3", surah, ayah)
            }
            guard let url = URL(string: path) else { return nil }
            return Clip(url: url, startMs: source.isSpan ? start : nil, endMs: source.isSpan ? end : nil)
        }
        guard let hafs = clip(base: source.hafsBase, start: row[2], end: row[3]),
              let theirs = clip(base: source.riwayahBase, start: row[4], end: row[5]) else { return nil }
        return Pair(reciter: source.reciter, hafs: hafs, riwayah: theirs)
    }

    private func load() {
        lock.lock(); defer { lock.unlock() }
        guard !loaded else { return }
        loaded = true
        guard let root = ThemesPack.json("QiraatVariantAudio") as? [String: Any] else { return }
        sources = (root["sources"] as? [[String: Any]] ?? []).map { row in
            Source(reciter: row["reciter"] as? String ?? "",
                   isSpan: (row["kind"] as? String) == "span",
                   hafsBase: row["hafsBase"] as? String ?? "",
                   riwayahBase: row["riwayahBase"] as? String ?? "")
        }
        var built: [String: [Int: [Int: [Int]]]] = [:]
        for (tag, surahs) in root["riwayat"] as? [String: [String: [[Int]]]] ?? [:] {
            var bySurah: [Int: [Int: [Int]]] = [:]
            for (surahKey, rows) in surahs {
                guard let surah = Int(surahKey) else { continue }
                var byAyah: [Int: [Int]] = [:]
                for row in rows where row.count == 6 {
                    byAyah[row[0]] = row
                }
                bySurah[surah] = byAyah
            }
            built[tag] = bySurah
        }
        table = built
    }
}

/// Plays one clip at a time: seeks into a full-surah stream and stops at the span's end, or plays
/// The short players (the qiraat clips here, the Hisn recitations in DuaView.swift) and the Quran
/// player share one audio session; this is where they yield to each other (Tilawa Guide, Phase 6
/// step 4). Before a clip or a dua starts, a playing surah pauses (and is not resumed afterwards:
/// the listener chose the clip), the other short player stops, and the session takes the Quran
/// player's own configuration; an interruption (a call, another app's audio) or a route change
/// stops both short players the way the Quran player stops itself.
@MainActor
enum AuxiliaryAudio {
    private static var observers: [NSObjectProtocol] = []

    static func prepareToPlay(stopping other: () -> Void) {
        if QuranPlayer.shared.isPlaying { QuranPlayer.shared.pause() }
        other()
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)
        installObservers()
    }

    static func stopAll() {
        QiraatClipPlayer.shared.stop()
        HisnDuaPlayer.shared.stop()
    }

    private static func installObservers() {
        guard observers.isEmpty else { return }
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { note in
            guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  AVAudioSession.InterruptionType(rawValue: raw) == .began else { return }
            Task { @MainActor in stopAll() }
        })
        observers.append(center.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { note in
            guard let raw = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
                  AVAudioSession.RouteChangeReason(rawValue: raw) == .oldDeviceUnavailable else { return }
            Task { @MainActor in stopAll() }
        })
    }
}

/// a per-verse file through. Its own player, so a clip never disturbs the Quran player's queue.
@MainActor
final class QiraatClipPlayer: ObservableObject {
    static let shared = QiraatClipPlayer()

    @Published private(set) var playingKey: String?
    @Published private(set) var isLoading = false

    private var player: AVPlayer?
    private var boundaryObserver: Any?
    private var endObserver: Any?
    private var statusObservation: NSKeyValueObservation?

    private init() {
        ObjectPublishCounter.attach(self, label: "QiraatClipPlayer")
    }

    func toggle(key: String, clip: QiraatVariantAudioStore.Clip) {
        if playingKey == key {
            stop()
            return
        }
        stop()
        AuxiliaryAudio.prepareToPlay(stopping: { HisnDuaPlayer.shared.stop() })

        let item = AVPlayerItem(url: clip.url)
        let player = AVPlayer(playerItem: item)
        player.automaticallyWaitsToMinimizeStalling = true
        self.player = player
        playingKey = key
        isLoading = true

        endObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.stop() }
        }
        statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            Task { @MainActor in
                guard let self, self.player?.currentItem === item else { return }
                if item.status == .failed { self.stop() }
                if item.status == .readyToPlay { self.isLoading = false }
            }
        }

        if let endMs = clip.endMs {
            let end = CMTime(value: CMTimeValue(endMs), timescale: 1000)
            boundaryObserver = player.addBoundaryTimeObserver(forTimes: [NSValue(time: end)], queue: .main) { [weak self] in
                Task { @MainActor in self?.stop() }
            }
        }
        if let startMs = clip.startMs {
            let start = CMTime(value: CMTimeValue(startMs), timescale: 1000)
            player.seek(to: start, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
                player.play()
            }
        } else {
            player.play()
        }
    }

    func stop() {
        if let boundaryObserver { player?.removeTimeObserver(boundaryObserver) }
        boundaryObserver = nil
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        endObserver = nil
        statusObservation = nil
        player?.pause()
        player = nil
        playingKey = nil
        isLoading = false
    }
}

/// The two buttons under a riwayah's row: the verse as Hafs reads it and as this riwayah reads
/// it, the same reciter both times, with the reciter named.
struct QiraatVariantAudioButtons: View {
    @Environment(\.appearance) private var appearance
    @ObservedObject private var player = QiraatClipPlayer.shared

    let tag: String
    let surah: Int
    let ayah: Int
    /// Compact: one row of two pills. Otherwise the reciter line sits beneath.
    var compact = false

    private var pair: QiraatVariantAudioStore.Pair? {
        QiraatVariantAudioStore.shared.pair(tag: tag, surah: surah, ayah: ayah)
    }

    var body: some View {
        if let pair {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    clipButton("Hafs", key: key("hafs"), clip: pair.hafs)
                    clipButton(QiraatProfiles.shortName(of: tag), key: key("riwayah"), clip: pair.riwayah)
                    if !compact {
                        Spacer(minLength: 0)
                    }
                }
                Text("Both readings by \(pair.reciter), the same verse in each.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func key(_ side: String) -> String { "\(tag)|\(surah):\(ayah)|\(side)" }

    private func clipButton(_ label: String, key: String, clip: QiraatVariantAudioStore.Clip) -> some View {
        let playing = player.playingKey == key
        let loading = playing && player.isLoading
        return Button {
            Settings.shared.hapticFeedback()
            player.toggle(key: key, clip: clip)
        } label: {
            HStack(spacing: 6) {
                if loading {
                    ProgressView()
                        .controlSize(.mini)
                        .tint(.white)
                } else {
                    Image(systemName: playing ? "stop.fill" : "play.fill")
                        .font(.caption2)
                }
                Text(playing ? "Stop" : "Hear \(label)")
                    .font(.caption.weight(.semibold))
            }
            .foregroundColor(playing ? .white : appearance.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(playing ? appearance.accent : appearance.accent.opacity(0.12)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(playing ? "Stop" : "Hear the verse as \(label) reads it")
    }
}
#endif
