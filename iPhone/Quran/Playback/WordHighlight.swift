import AVFoundation
import Combine
import SwiftUI

// The word being recited (Abu, 2026-11-02: "Play word by word for ayah sheet and for play ayah
// highlighting each word"). Two sources feed one state:
//
// - `WordHighlightTracker`: while the Quran player recites an ayah, quran.com's word segments for the
//   reciter (`AyahWordTimingStore`, the same `audio_files?segments=true` call the surah downloads
//   already make) say which word the playhead is on. The segments describe quran.com's own surah
//   encode; a single ayah streamed from cdn.islamic.network or everyayah is the same recording cut at
//   the same places (measured 2026-11-02: the files match the verse windows within 6 ms for Alafasy,
//   within 80 ms for Husary, Abdul Basit, Sudais, Shatri and Shuraim), so the ayah's segments shifted
//   to its start line up, and a file whose length disagrees with the window by more than
//   `durationTolerance` gets no words (the ayah wash alone, as before). A downloaded surah's slice IS
//   the quran.com encode, so it needs no check.
// - `WordClipPlayer`: "Play Word by Word" plays quran.com's per-word clips one after another
//   (audio.qurancdn.com/wbw/SSS_AAA_WWW.mp3, the same voice for every reciter), lighting each word
//   as its clip plays. Exact by construction, and it works for every reciter.
//
// Nothing here is observed by the reader rows directly: a row (or a page, or a preview card) holds a
// `PlayingWordLink` that subscribes only while it may be the one playing, so a word change re-renders
// the one view showing that ayah and nothing else (the rule behind `AyahRow.isPlayingThis`).

#if os(iOS)

/// Which word of which ayah is sounding right now. One publisher for the whole app.
@MainActor
final class WordHighlightState: ObservableObject {
    static let shared = WordHighlightState()

    struct PlayingWord: Equatable {
        let surah: Int
        let ayah: Int
        /// The 0-based word of the ayah's Hafs text, counting words as the display does (the
        /// standalone ۞ is not a word).
        let index: Int
        /// How many words the source counted for this ayah. A renderer whose own token count differs
        /// (beginner spacing, a text the source numbers otherwise) paints nothing rather than the
        /// wrong word.
        let count: Int
    }

    enum Owner { case recitation, clips }

    @Published private(set) var playing: PlayingWord?
    private var owner: Owner?

    private init() {
        ObjectPublishCounter.attach(self, label: "WordHighlightState")
    }

    func set(_ word: PlayingWord?, owner: Owner) {
        self.owner = owner
        if playing != word { playing = word }
    }

    /// Clears the word only when `owner` is the one that lit it: the clip player stopping must not
    /// darken a recitation that took over, and the other way round.
    func clear(owner: Owner) {
        guard self.owner == owner else { return }
        self.owner = nil
        if playing != nil { playing = nil }
    }

    /// The playing word's index for one ayah, or nil.
    func index(surah: Int, ayah: Int) -> Int? {
        guard let playing, playing.surah == surah, playing.ayah == ayah else { return nil }
        return playing.index
    }
}

/// A view's own subscription to `WordHighlightState`, filtered to the ayahs it shows and switched on
/// only while it may be playing: the reader rows hold one each, so a word change publishes into the
/// row of that ayah alone.
@MainActor
final class PlayingWordLink: ObservableObject {
    @Published private(set) var word: WordHighlightState.PlayingWord?
    private var cancellable: AnyCancellable?
    private var keys: Set<AyahKey> = []

    struct AyahKey: Hashable {
        let surah: Int
        let ayah: Int
    }

    func bind(surah: Int, ayahs: [Int], active: Bool) {
        bind(keys: Set(ayahs.map { AyahKey(surah: surah, ayah: $0) }), active: active)
    }

    func bind(keys: Set<AyahKey>, active: Bool) {
        self.keys = keys
        guard active else {
            cancellable = nil
            if word != nil { word = nil }
            return
        }
        if cancellable == nil {
            cancellable = WordHighlightState.shared.$playing.sink { [weak self] playing in
                self?.receive(playing)
            }
        } else {
            receive(WordHighlightState.shared.playing)
        }
    }

    private func receive(_ playing: WordHighlightState.PlayingWord?) {
        let next: WordHighlightState.PlayingWord?
        if let playing, keys.contains(AyahKey(surah: playing.surah, ayah: playing.ayah)) {
            next = playing
        } else {
            next = nil
        }
        if word != next { word = next }
    }
}

/// `PlayingWordLink` as a view: wraps content that draws one or more ayahs and hands it the playing
/// word, re-rendering only the content when the word moves. `active` false unsubscribes (a row that
/// is not the playing one).
struct PlayingWordHost<Content: View>: View {
    let keys: Set<PlayingWordLink.AyahKey>
    var active: Bool = true
    @ViewBuilder let content: (WordHighlightState.PlayingWord?) -> Content

    @StateObject private var link = PlayingWordLink()

    init(surah: Int, ayahs: [Int], active: Bool = true,
         @ViewBuilder content: @escaping (WordHighlightState.PlayingWord?) -> Content) {
        self.keys = Set(ayahs.map { PlayingWordLink.AyahKey(surah: surah, ayah: $0) })
        self.active = active
        self.content = content
    }

    init(keys: Set<PlayingWordLink.AyahKey>, active: Bool = true,
         @ViewBuilder content: @escaping (WordHighlightState.PlayingWord?) -> Content) {
        self.keys = keys
        self.active = active
        self.content = content
    }

    var body: some View {
        content(link.word)
            .onAppear { link.bind(keys: keys, active: active) }
            .onChange(of: active) { link.bind(keys: keys, active: $0) }
            .onChange(of: keys) { link.bind(keys: $0, active: active) }
    }
}

// MARK: - Words as the Hafs text counts them

enum QuranWords {
    /// The UTF-16 ranges of the words of a display text, in order: the whitespace tokens that carry
    /// at least one Arabic letter. A standalone ۞ (or any mark-only token) is skipped, so the index
    /// matches quran.com's word positions, which never count it.
    static func ranges(in text: String) -> [NSRange] {
        let ns = text as NSString
        return WordTokens.ranges(in: text).filter { range in
            let token = ns.substring(with: range)
            return token.unicodeScalars.contains { isArabicLetter($0) }
        }
    }

    static func count(in text: String) -> Int { ranges(in: text).count }

    /// The range of word `index` (0-based) in `text`, when the text has exactly `count` words.
    static func range(of index: Int, in text: String, expecting count: Int) -> NSRange? {
        let ranges = ranges(in: text)
        guard ranges.count == count, ranges.indices.contains(index) else { return nil }
        return ranges[index]
    }

    /// The index among ALL of `text`'s whitespace tokens (`WordTokens`, what the word renderers number)
    /// of word `index`, when the text has exactly `count` words.
    static func tokenIndex(ofWord index: Int, in text: String, expecting count: Int) -> Int? {
        let ns = text as NSString
        let all = WordTokens.ranges(in: text)
        var seen = 0
        var found: Int?
        for (position, range) in all.enumerated() {
            let token = ns.substring(with: range)
            guard token.unicodeScalars.contains(where: isArabicLetter) else { continue }
            if seen == index { found = position }
            seen += 1
        }
        guard seen == count else { return nil }
        return found
    }

    /// The range of word `index` inside `ayahRange` of a page's text (the mushaf composer's run for
    /// one ayah: its words, then its number ornament, which carries no letter and is skipped), when
    /// the run has exactly `count` words.
    static func range(ofWord index: Int, in ayahRange: NSRange, of text: NSString, expecting count: Int) -> NSRange? {
        guard NSMaxRange(ayahRange) <= text.length else { return nil }
        let slice = text.substring(with: ayahRange)
        guard let local = range(of: index, in: slice, expecting: count) else { return nil }
        return NSRange(location: ayahRange.location + local.location, length: local.length)
    }

    static func isArabicLetter(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x0621...0x063A, 0x0641...0x064A, 0x0671, 0x066E, 0x066F, 0x0679...0x06D3: return true
        default: return false
        }
    }
}

// MARK: - quran.com's word segments

/// One reciter's word timings for one surah, fetched once and kept beside the reciter's downloads
/// (`<surah>.words.json`), then read from memory. Milliseconds in the reciter's quran.com surah file.
@MainActor
final class AyahWordTimingStore {
    static let shared = AyahWordTimingStore()

    struct Verse: Codable, Equatable {
        /// The verse's window in the surah file.
        let from: Int
        let to: Int
        /// `[position (1-based), fromMs, toMs]` per word, one entry per position, ascending. The API
        /// repeats a position when a word was recorded in two pieces; those are merged (the first
        /// start, the last end).
        let words: [[Int]]

        var wordCount: Int { words.last?.first ?? 0 }
        var duration: Int { abs(to - from) }
    }

    struct Table: Codable {
        let verses: [Int: Verse]
    }

    private var cache: [String: Table] = [:]
    private var waiting: [String: [@MainActor () -> Void]] = [:]
    /// Keys whose fetch failed this session: asked again on the next launch, not on every ayah.
    private var failed: Set<String> = []

    private init() {}

    private func key(_ reciter: Reciter, _ surah: Int) -> String { "\(reciter.id)|\(surah)" }

    private func fileURL(reciter: Reciter, surah: Int) -> URL {
        ReciterDownloadManager.shared.wordTimingsFileURL(reciter: reciter, surahNumber: surah)
    }

    /// The verse's words when the table is already in memory or on disk; nil otherwise (and no fetch).
    func verse(reciter: Reciter, surah: Int, ayah: Int) -> Verse? {
        table(reciter: reciter, surah: surah)?.verses[ayah]
    }

    func table(reciter: Reciter, surah: Int) -> Table? {
        let k = key(reciter, surah)
        if let hit = cache[k] { return hit }
        if let data = try? Data(contentsOf: fileURL(reciter: reciter, surah: surah)),
           let decoded = try? JSONDecoder().decode(Table.self, from: data) {
            cache[k] = decoded
            return decoded
        }
        // The shipped pack, once the reciter's blob is inflated (`fetchIfNeeded` does that off main).
        if let qdcID = reciter.qdcReciterID, let shipped = ShippedWordTimings.tableIfInflated(reciter: qdcID, surah: surah) {
            cache[k] = shipped
            return shipped
        }
        return nil
    }

    /// Fetches the surah's table when nothing is cached, then calls `completion` on main (also when
    /// the table was already there, and when the fetch failed: the caller re-reads and decides).
    func fetchIfNeeded(reciter: Reciter, surah: Int, completion: @escaping @MainActor () -> Void) {
        let k = key(reciter, surah)
        if table(reciter: reciter, surah: surah) != nil || failed.contains(k) || reciter.qdcReciterID == nil {
            completion()
            return
        }
        if waiting[k] != nil {
            waiting[k]?.append(completion)
            return
        }
        waiting[k] = [completion]
        guard let qdcID = reciter.qdcReciterID else {
            finish(k, table: nil, reciter: reciter, surah: surah)
            return
        }
        if ShippedWordTimings.has(reciter: qdcID) {
            // Inflating a reciter's blob is a few milliseconds of xz: off main, once per reciter.
            Task.detached(priority: .userInitiated) { [weak self] in
                let shipped = ShippedWordTimings.table(reciter: qdcID, surah: surah)
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    if let shipped {
                        self.finish(k, table: shipped, reciter: reciter, surah: surah, persist: false)
                    } else {
                        self.fetchRemote(k, qdcID: qdcID, reciter: reciter, surah: surah)
                    }
                }
            }
            return
        }
        fetchRemote(k, qdcID: qdcID, reciter: reciter, surah: surah)
    }

    private func fetchRemote(_ k: String, qdcID: Int, reciter: Reciter, surah: Int) {
        guard let url = URL(string: "https://api.qurancdn.com/api/qdc/audio/reciters/\(qdcID)/audio_files?chapter=\(surah)&segments=true") else {
            finish(k, table: nil, reciter: reciter, surah: surah)
            return
        }
        Task { [weak self] in
            var parsed: Table?
            if let (data, response) = try? await URLSession.shared.data(from: url),
               (response as? HTTPURLResponse)?.statusCode == 200 {
                parsed = Self.parse(data: data, surah: surah)
            }
            let result = parsed
            await MainActor.run { [weak self] in
                self?.finish(k, table: result, reciter: reciter, surah: surah)
            }
        }
    }

    /// `persist` writes a fetched table beside the reciter's downloads; a shipped one stays in the bundle.
    private func finish(_ k: String, table: Table?, reciter: Reciter, surah: Int, persist: Bool = true) {
        if let table {
            cache[k] = table
            if persist, let encoded = try? JSONEncoder().encode(table) {
                try? encoded.write(to: fileURL(reciter: reciter, surah: surah), options: .atomic)
            }
        } else {
            failed.insert(k)
        }
        let continuations = waiting.removeValue(forKey: k) ?? []
        for continuation in continuations { continuation() }
    }

    /// Drops every table from memory (a memory warning); the disk copies and the shipped pack stay.
    func purge() {
        cache = [:]
        ShippedWordTimings.dropInflated()
    }

    /// Drops a reciter's tables from memory (its files go with its downloads folder).
    func forget(reciterID: String) {
        cache = cache.filter { !$0.key.hasPrefix("\(reciterID)|") }
    }

    /// A JSON number as whole milliseconds: some reciters' segments arrive as floats ("6520.0", and
    /// the odd half), which `as? Int` would drop whole.
    nonisolated private static func millis(_ value: Any?) -> Int? {
        if let int = value as? Int { return int }
        if let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse {
            let double = number.doubleValue
            return double.isFinite ? Int(double.rounded()) : nil
        }
        return nil
    }

    /// `verse_timings[].segments` out of the QDC response. Pure parsing.
    nonisolated static func parse(data: Data, surah: Int) -> Table? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let files = root["audio_files"] as? [[String: Any]],
              let file = files.first,
              let timings = file["verse_timings"] as? [[String: Any]] else { return nil }
        var verses: [Int: Verse] = [:]
        for entry in timings {
            guard let verseKey = entry["verse_key"] as? String,
                  let from = millis(entry["timestamp_from"]),
                  let to = millis(entry["timestamp_to"]) else { continue }
            let parts = verseKey.split(separator: ":")
            guard parts.count == 2, Int(parts[0]) == surah, let ayah = Int(parts[1]) else { continue }
            var byPosition: [Int: (from: Int, to: Int)] = [:]
            for segment in (entry["segments"] as? [[Any]]) ?? [] {
                // The API ships the odd one-element segment; only `[position, from, to]` counts.
                guard segment.count == 3,
                      let position = millis(segment[0]), position >= 1,
                      let segFrom = millis(segment[1]), let segTo = millis(segment[2]), segTo > segFrom else { continue }
                if let existing = byPosition[position] {
                    byPosition[position] = (min(existing.from, segFrom), max(existing.to, segTo))
                } else {
                    byPosition[position] = (segFrom, segTo)
                }
            }
            guard !byPosition.isEmpty else { continue }
            let words = byPosition.keys.sorted().map { [$0, byPosition[$0]!.from, byPosition[$0]!.to] }
            verses[ayah] = Verse(from: min(from, to), to: max(from, to), words: words)
        }
        guard !verses.isEmpty else { return nil }
        return Table(verses: verses)
    }
}

// MARK: - The shipped timings

/// quran.com's word timings for every reciter with a `qdcReciterID`, packed ahead of time
/// (Resources/Data/Quran/WordTimings.bin, Scripts/build_word_timings.py, which documents the bytes):
/// one xz blob per reciter behind a JSON index. A blob is inflated the first time its reciter plays
/// (`table`, off main) and a surah's verses are decoded out of it when asked (`tableIfInflated`,
/// cheap enough for main). What comes out is what `AyahWordTimingStore.parse` would have kept from
/// the same response. Thread-safe.
enum ShippedWordTimings {
    private struct Index {
        let data: Data
        let payloadStart: Int
        let entries: [Int: Range<Int>]
    }

    private static let lock = NSLock()
    /// nil = not looked at yet; .some(nil) = no pack in the bundle.
    private static var index: Index??
    private static var inflated: [Int: Data] = [:]

    private static var url: URL? {
        Bundle.main.url(forResource: "WordTimings", withExtension: "bin", subdirectory: "Data/Quran")
            ?? Bundle.main.url(forResource: "WordTimings", withExtension: "bin", subdirectory: "Quran")
            ?? Bundle.main.url(forResource: "WordTimings", withExtension: "bin")
    }

    /// The reciters the pack carries, by quran.com id.
    static var reciters: [Int] { loadIndex()?.entries.keys.sorted() ?? [] }

    static func has(reciter qdcID: Int) -> Bool { loadIndex()?.entries[qdcID] != nil }

    /// Inflates the reciter's blob when needed, then decodes the surah. Call off main the first time.
    static func table(reciter qdcID: Int, surah: Int) -> AyahWordTimingStore.Table? {
        guard let blob = blob(reciter: qdcID) else { return nil }
        return decode(blob, surah: surah)
    }

    /// The surah when the reciter's blob is already inflated; nil otherwise (and no work).
    static func tableIfInflated(reciter qdcID: Int, surah: Int) -> AyahWordTimingStore.Table? {
        lock.lock()
        let blob = inflated[qdcID]
        lock.unlock()
        guard let blob else { return nil }
        return decode(blob, surah: surah)
    }

    /// Lets go of the inflated blobs (a memory warning); the next play inflates again.
    static func dropInflated() {
        lock.lock()
        inflated = [:]
        lock.unlock()
    }

    private static func loadIndex() -> Index? {
        lock.lock()
        defer { lock.unlock() }
        if let known = index { return known }
        let parsed = url.flatMap { url -> Index? in
            guard let data = try? Data(contentsOf: url, options: .mappedIfSafe), data.count > 12,
                  data.prefix(8) == Data("AIWT0001".utf8) else { return nil }
            let headerLength = data.subdata(in: 8..<12).withUnsafeBytes { Int($0.loadUnaligned(as: UInt32.self).littleEndian) }
            let payloadStart = 12 + headerLength
            guard headerLength > 0, payloadStart <= data.count,
                  let header = try? JSONSerialization.jsonObject(with: data.subdata(in: 12..<payloadStart)) as? [String: Any],
                  let reciters = header["reciters"] as? [[String: Any]] else { return nil }
            var entries: [Int: Range<Int>] = [:]
            for entry in reciters {
                guard let id = entry["id"] as? Int, let offset = entry["offset"] as? Int, let length = entry["length"] as? Int,
                      offset >= 0, length > 0, payloadStart + offset + length <= data.count else { continue }
                entries[id] = (payloadStart + offset)..<(payloadStart + offset + length)
            }
            return Index(data: data, payloadStart: payloadStart, entries: entries)
        }
        index = .some(parsed)
        return parsed
    }

    private static func blob(reciter qdcID: Int) -> Data? {
        lock.lock()
        if let hit = inflated[qdcID] {
            lock.unlock()
            return hit
        }
        lock.unlock()
        guard let index = loadIndex(), let range = index.entries[qdcID],
              let raw = SolidPack.xzDecompress(index.data.subdata(in: range)), raw.count > 2 else { return nil }
        lock.lock()
        inflated[qdcID] = raw
        lock.unlock()
        return raw
    }

    /// One surah's verses out of an inflated reciter blob (the layout in build_word_timings.py).
    static func decode(_ blob: Data, surah: Int) -> AyahWordTimingStore.Table? {
        blob.withUnsafeBytes { raw -> AyahWordTimingStore.Table? in
            guard let base = raw.bindMemory(to: UInt8.self).baseAddress else { return nil }
            let length = raw.count
            guard length > 2, base[0] == 1 else { return nil }
            let surahCount = Int(base[1])
            guard surah >= 1, surah <= surahCount else { return nil }
            let tableStart = 2
            let sectionsStart = tableStart + 4 * (surahCount + 1)
            guard sectionsStart <= length else { return nil }
            func u32(_ at: Int) -> Int {
                Int(base[at]) | Int(base[at + 1]) << 8 | Int(base[at + 2]) << 16 | Int(base[at + 3]) << 24
            }
            var cursor = sectionsStart + u32(tableStart + 4 * (surah - 1))
            let end = sectionsStart + u32(tableStart + 4 * surah)
            guard cursor <= end, end <= length else { return nil }
            func varint() -> Int? {
                var result = 0
                var shift = 0
                while cursor < end {
                    let byte = Int(base[cursor])
                    cursor += 1
                    result |= (byte & 0x7F) << shift
                    if byte & 0x80 == 0 { return result }
                    shift += 7
                    if shift > 56 { return nil }
                }
                return nil
            }
            func zigzag() -> Int? {
                guard let value = varint() else { return nil }
                return (value >> 1) ^ -(value & 1)
            }
            guard let verseCount = varint(), verseCount > 0 else { return nil }
            var verses: [Int: AyahWordTimingStore.Verse] = [:]
            verses.reserveCapacity(verseCount)
            var ayah = 0
            var previousTo = 0
            for _ in 0..<verseCount {
                guard let ayahStep = varint(), let fromDelta = zigzag(), let duration = varint(), let wordCount = varint() else { return nil }
                ayah += ayahStep
                let from = previousTo + fromDelta
                let to = from + duration
                previousTo = to
                var words: [[Int]] = []
                words.reserveCapacity(wordCount)
                var position = 0
                var previousEnd = from
                for _ in 0..<wordCount {
                    guard let gap = varint(), let startDelta = zigzag(), let wordLength = varint() else { return nil }
                    position += gap + 1
                    let start = previousEnd + startDelta
                    let wordEnd = start + wordLength
                    previousEnd = wordEnd
                    words.append([position, start, wordEnd])
                }
                verses[ayah] = AyahWordTimingStore.Verse(from: from, to: to, words: words)
            }
            return AyahWordTimingStore.Table(verses: verses)
        }
    }
}

// MARK: - Following the recitation

/// Lights the recited word while the Quran player plays. Owned by `QuranPlayer`; started when an
/// ayah item becomes current and stopped with the player's observers.
@MainActor
final class WordHighlightTracker {
    /// A streamed ayah file may differ from the quran.com verse window by this much and still take
    /// the window's words (the largest honest drift measured was Minshawi's 250 ms on 18:10).
    static let durationTolerance = 250.0
    /// A word lights this early: the eye should land on it as its first sound arrives.
    static let leadMs = 60

    private struct Window {
        let startMs: Int
        let endMs: Int
        let word: WordHighlightState.PlayingWord
    }

    private var windows: [Window] = []
    private var observer: Any?
    private weak var observedPlayer: AVPlayer?
    private var generation = 0
    private var durationObservation: NSKeyValueObservation?

    /// Built as a stored property of the (non-isolated) player; nothing isolated happens until a track call.
    nonisolated init() {}

    private var state: WordHighlightState { .shared }

    /// An ayah item became current: find its words and follow them. `item` plays from zero, as a
    /// streamed ayah file or as a slice of the downloaded surah (`AyahTimingStore.makeSegmentItem`).
    func trackAyah(player: AVPlayer, item: AVPlayerItem, surah: Int, ayah: Int, reciter: Reciter, isBismillah: Bool = false) {
        stop()
        guard Settings.shared.highlightPlayingWords, !isBismillah, reciter.qdcReciterID != nil else { return }
        generation += 1
        let myGeneration = generation
        let store = AyahWordTimingStore.shared
        let resume: @MainActor () -> Void = { [weak self, weak player, weak item] in
            guard let self, self.generation == myGeneration, let player, let item else { return }
            guard let verse = store.verse(reciter: reciter, surah: surah, ayah: ayah), !verse.words.isEmpty else { return }
            // A downloaded surah's slice is the quran.com encode cut at the verse window: no check
            // needed. A streamed file must be the same length as the window.
            let isSlice = !isBismillah
                && ReciterDownloadManager.shared.localSurahURL(reciter: reciter, surahNumber: surah) != nil
                && AyahTimingStore.shared.validatedWindow(reciter: reciter, surahNumber: surah, ayahNumber: ayah) != nil
            if isSlice {
                self.install(player: player, windows: Self.windows(for: verse, offset: verse.from, surah: surah, ayah: ayah,
                                                                   lastEnd: nil))
            } else {
                self.whenDurationKnown(item: item, generation: myGeneration) { [weak self, weak player] durationMs in
                    guard let self, let player, self.generation == myGeneration else { return }
                    guard abs(durationMs - Double(verse.duration)) <= Self.durationTolerance else { return }
                    self.install(player: player, windows: Self.windows(for: verse, offset: verse.from, surah: surah, ayah: ayah,
                                                                       lastEnd: Int(durationMs)))
                }
            }
        }
        if store.verse(reciter: reciter, surah: surah, ayah: ayah) != nil {
            resume()
        } else {
            store.fetchIfNeeded(reciter: reciter, surah: surah, completion: resume)
        }
    }

    /// A whole surah playing from its DOWNLOADED quran.com file: every verse's words at their absolute
    /// times. Nothing for a stream or a cached copy of another encode.
    func trackSurah(player: AVPlayer, item: AVPlayerItem, surah: Int, reciter: Reciter) {
        stop()
        guard Settings.shared.highlightPlayingWords, reciter.qdcReciterID != nil,
              let local = ReciterDownloadManager.shared.localSurahURL(reciter: reciter, surahNumber: surah),
              let asset = item.asset as? AVURLAsset, asset.url.standardizedFileURL == local.standardizedFileURL,
              AyahTimingStore.shared.validatedWindow(reciter: reciter, surahNumber: surah, ayahNumber: 1) != nil else { return }
        generation += 1
        let myGeneration = generation
        let store = AyahWordTimingStore.shared
        let resume: @MainActor () -> Void = { [weak self, weak player] in
            guard let self, self.generation == myGeneration, let player,
                  let table = store.table(reciter: reciter, surah: surah) else { return }
            var all: [Window] = []
            for ayah in table.verses.keys.sorted() {
                guard let verse = table.verses[ayah], !verse.words.isEmpty else { continue }
                all += Self.windows(for: verse, offset: 0, surah: surah, ayah: ayah, lastEnd: nil)
            }
            all.sort { $0.startMs < $1.startMs }
            // Each window ends where the next begins, across ayahs too.
            var closed: [Window] = []
            closed.reserveCapacity(all.count)
            for (index, window) in all.enumerated() {
                let end = index + 1 < all.count ? min(window.endMs, all[index + 1].startMs) : window.endMs
                closed.append(Window(startMs: window.startMs, endMs: max(end, window.startMs + 1), word: window.word))
            }
            self.install(player: player, windows: closed)
        }
        if store.table(reciter: reciter, surah: surah) != nil {
            resume()
        } else {
            store.fetchIfNeeded(reciter: reciter, surah: surah, completion: resume)
        }
    }

    func stop() {
        generation += 1
        durationObservation = nil
        if let observer, let observedPlayer {
            observedPlayer.removeTimeObserver(observer)
        }
        observer = nil
        observedPlayer = nil
        windows = []
        state.clear(owner: .recitation)
    }

    /// The verse's windows shifted by `offset`: each word starts a little early and runs to the
    /// next word's start (silence between words keeps the earlier word lit); the last runs to the
    /// verse's end plus a moment, capped at the item's end when known.
    private static func windows(for verse: AyahWordTimingStore.Verse, offset: Int, surah: Int, ayah: Int,
                                lastEnd: Int?) -> [Window] {
        let count = verse.wordCount
        var out: [Window] = []
        out.reserveCapacity(verse.words.count)
        for (index, entry) in verse.words.enumerated() {
            guard entry.count == 3 else { continue }
            let start = max(0, entry[1] - offset - leadMs)
            let end: Int
            if index + 1 < verse.words.count {
                end = max(start + 1, verse.words[index + 1][1] - offset - leadMs)
            } else {
                let tail = entry[2] - offset + 200
                end = max(start + 1, lastEnd.map { min(tail, $0 + 50) } ?? tail)
            }
            out.append(Window(startMs: start, endMs: end,
                              word: WordHighlightState.PlayingWord(surah: surah, ayah: ayah, index: entry[0] - 1, count: count)))
        }
        return out
    }

    /// The item's length in ms once it is known (immediately for a ready item).
    private func whenDurationKnown(item: AVPlayerItem, generation: Int, _ then: @escaping @MainActor (Double) -> Void) {
        let seconds = CMTimeGetSeconds(item.duration)
        if item.status == .readyToPlay, seconds.isFinite, seconds > 0 {
            then(seconds * 1000)
            return
        }
        durationObservation = item.observe(\.status, options: [.new]) { [weak self] observed, _ in
            Task { @MainActor [weak self] in
                guard let self, self.generation == generation, observed.status == .readyToPlay else { return }
                self.durationObservation = nil
                let seconds = CMTimeGetSeconds(observed.duration)
                guard seconds.isFinite, seconds > 0 else { return }
                then(seconds * 1000)
            }
        }
    }

    private func install(player: AVPlayer, windows: [Window]) {
        guard !windows.isEmpty else { return }
        self.windows = windows
        observedPlayer = player
        // Twenty times a second: a short word lasts 250-400 ms, and the eye wants the change within a
        // frame or two of the sound. Publishes only when the word changes (a few times a second).
        observer = player.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 20), queue: .main) { [weak self] time in
            let seconds = CMTimeGetSeconds(time)
            guard seconds.isFinite else { return }
            // Delivered on the main queue (asked for above): the isolation statement, not a hop.
            MainActor.assumeIsolated { self?.tick(ms: Int(seconds * 1000)) }
        }
        tick(ms: 0)
    }

    private func tick(ms: Int) {
        // The last window whose start is at or before the playhead.
        var low = 0, high = windows.count - 1, found = -1
        while low <= high {
            let mid = (low + high) / 2
            if windows[mid].startMs <= ms { found = mid; low = mid + 1 } else { high = mid - 1 }
        }
        guard found >= 0, ms < windows[found].endMs else {
            // Before the first word: nothing yet. Past the last: keep it lit (a trailing silence).
            if found < 0 { state.set(nil, owner: .recitation) }
            return
        }
        state.set(windows[found].word, owner: .recitation)
    }
}

// MARK: - Word by word, from the clips

/// The Play Word by Word row of an ayah menu, reading Stop while that ayah's words are playing, as
/// the actions sheet's tile does (the menus said Play throughout a run until 2026-11-18). A view of
/// its own because a menu's rows are built when its HOST renders, not when the menu opens (see
/// `ReciterCaptionedMenuLabel`): read once, the row would still say Play on a menu opened mid-run.
/// The player publishes on start and stop only.
struct WordByWordMenuLabel: View {
    @ObservedObject private var player = WordClipPlayer.shared

    let surah: Int
    let ayah: Int

    var body: some View {
        if player.isPlaying(surah: surah, ayah: ayah) {
            Label("Stop Word by Word", systemImage: "stop.circle")
        } else {
            Label("Play Word by Word", systemImage: "text.word.spacing")
        }
    }
}

/// "Play Word by Word": quran.com's per-word clips, one after the other, each word lit as it sounds.
/// Its own queue player, yielding to and from the Quran player like the riwayah clips.
@MainActor
final class WordClipPlayer: ObservableObject {
    static let shared = WordClipPlayer()

    struct Target: Equatable {
        let surah: Int
        let ayah: Int
        /// One word (its quran.com position) when the word card plays a single clip; nil for the whole ayah.
        var position: Int? = nil
    }

    /// The ayah whose words are playing (nil when idle).
    @Published private(set) var current: Target?
    /// Called once (on main) when the clips could not be played at all: the word card then reads the
    /// word aloud instead. Cleared by `stop()`.
    private var onFailure: (() -> Void)?
    @Published private(set) var isLoading = false

    private var queue: AVQueuePlayer?
    private var itemIndex: [ObjectIdentifier: Int] = [:]
    private var count = 0
    private var currentItemObservation: NSKeyValueObservation?
    private var statusObservations: [NSKeyValueObservation] = []
    private var endObserver: NSObjectProtocol?

    private init() {
        ObjectPublishCounter.attach(self, label: "WordClipPlayer")
    }

    nonisolated static func clipURL(surah: Int, ayah: Int, position: Int) -> URL? {
        URL(string: String(format: "https://audio.qurancdn.com/wbw/%03d_%03d_%03d.mp3", surah, ayah, position))
    }

    /// Whether any of the ayah's words is playing (the whole run or a single word): the ayah's wash.
    func isPlaying(surah: Int, ayah: Int) -> Bool {
        current?.surah == surah && current?.ayah == ayah
    }

    /// Whether this one word is playing on its own (the word card's Listen).
    func isPlaying(surah: Int, ayah: Int, position: Int) -> Bool {
        current == Target(surah: surah, ayah: ayah, position: position)
    }

    /// Starts the ayah's words, or stops them when they are the ones playing.
    func toggle(surah: Int, ayah: Int) {
        if current == Target(surah: surah, ayah: ayah) {
            stop()
        } else {
            play(surah: surah, ayah: ayah)
        }
    }

    /// Every word of the ayah, in order.
    func play(surah: Int, ayah: Int) {
        start(surah: surah, ayah: ayah, position: nil, onFailure: nil)
    }

    /// One word of the ayah (`position` as quran.com numbers it, 1-based), lit while it sounds.
    /// `onFailure` runs when the clip cannot play (no network and no cached copy).
    func playWord(surah: Int, ayah: Int, position: Int, onFailure: (() -> Void)? = nil) {
        start(surah: surah, ayah: ayah, position: position, onFailure: onFailure)
    }

    private func start(surah: Int, ayah: Int, position: Int?, onFailure: (() -> Void)?) {
        stop()
        guard let surahData = QuranData.shared.quran.first(where: { $0.id == surah }),
              let ayahData = surahData.ayahs.first(where: { $0.id == ayah }) else { return }
        let wordCount = QuranWords.count(in: ayahData.textHafs)
        guard wordCount > 0 else { return }
        let positions: [Int]
        if let position {
            guard position >= 1, position <= wordCount else { return }
            positions = [position]
        } else {
            positions = Array(1...wordCount)
        }

        AuxiliaryAudio.prepareToPlay(stopping: {
            QiraatClipPlayer.shared.stop()
            HisnDuaPlayer.shared.stop()
        })

        var items: [AVPlayerItem] = []
        var remotes: [URL] = []
        var wordOfItem: [Int] = []
        for position in positions {
            guard let remote = Self.clipURL(surah: surah, ayah: ayah, position: position) else { continue }
            wordOfItem.append(position - 1)
            // A clip fetched before plays from disk; the rest stream, and are copied for next time.
            if let local = PlaybackAudioCache.shared.localURL(for: remote) {
                items.append(AVPlayerItem(url: local))
            } else {
                items.append(AVPlayerItem(url: remote))
                remotes.append(remote)
            }
        }
        guard !items.isEmpty else { return }
        if !remotes.isEmpty { PlaybackAudioCache.shared.prefetch(remotes) }

        let player = AVQueuePlayer(items: items)
        player.actionAtItemEnd = .advance
        player.automaticallyWaitsToMinimizeStalling = true
        queue = player
        count = wordCount
        itemIndex = Dictionary(uniqueKeysWithValues: items.enumerated().map { (ObjectIdentifier($0.element), wordOfItem[$0.offset]) })
        self.onFailure = onFailure
        current = Target(surah: surah, ayah: ayah, position: position)
        isLoading = true

        currentItemObservation = player.observe(\.currentItem, options: [.initial, .new]) { [weak self] observed, _ in
            Task { @MainActor [weak self] in
                guard let self, self.queue === observed else { return }
                guard let item = observed.currentItem, let index = self.itemIndex[ObjectIdentifier(item)] else {
                    // The queue ran dry: the last word has sounded.
                    if observed.items().isEmpty { self.stop() }
                    return
                }
                WordHighlightState.shared.set(
                    .init(surah: surah, ayah: ayah, index: index, count: self.count), owner: .clips)
            }
        }
        statusObservations = items.map { item in
            item.observe(\.status, options: [.new]) { [weak self] observed, _ in
                Task { @MainActor [weak self] in
                    guard let self, let queue = self.queue else { return }
                    switch observed.status {
                    case .readyToPlay:
                        if queue.currentItem === observed { self.isLoading = false }
                    case .failed:
                        // A clip that will not play (a word the source numbers differently, no
                        // network): skip to the next rather than stall the run.
                        if queue.currentItem === observed {
                            if queue.items().count > 1 {
                                queue.advanceToNextItem()
                            } else {
                                let failed = self.onFailure
                                self.stop()
                                failed?()
                            }
                        }
                    default:
                        break
                    }
                }
            }
        }
        if let last = items.last {
            endObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: last, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self, weak player] in
                    guard let self, let player, self.queue === player else { return }
                    self.stop()
                }
            }
        }
        player.play()
    }

    func stop() {
        currentItemObservation = nil
        statusObservations = []
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        endObserver = nil
        queue?.pause()
        queue?.removeAllItems()
        queue = nil
        itemIndex = [:]
        count = 0
        onFailure = nil
        if current != nil { current = nil }
        if isLoading { isLoading = false }
        WordHighlightState.shared.clear(owner: .clips)
    }
}

#endif
