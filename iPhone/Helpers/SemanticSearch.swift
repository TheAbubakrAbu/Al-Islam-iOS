import Foundation
import Combine
import NaturalLanguage
import Accelerate
import SwiftUI

#if os(iOS)

/// On-device semantic ("AI") search: meaning-based matching over a corpus of texts, fully local and
/// private - no network, no keys. "Patience in hardship" finds ayahs about sabr whether or not either
/// word appears.
///
/// HOW IT SCORES - measured, not assumed: Apple's *sentence* embedding turned out to rank this corpus
/// almost randomly (the lashing verse outscored the patience verse for "patience in hardship"), so the
/// engine uses **word-embedding MaxSim** instead: every corpus word gets its NLEmbedding word vector,
/// and a query scores each text as the mean over query words of the best-matching text word. On real
/// verses that separates related (0.42-0.70) from unrelated (0.27-0.41) cleanly.
///
/// Corpora are registered by id ("quran-en", "hadith-<slug>"); vectors build once per corpus off the
/// main thread (with published progress), persist to Caches, and load instantly forever after.
@MainActor
final class SemanticSearchEngine: ObservableObject {
    static let shared = SemanticSearchEngine()

    private init() {
        ObjectPublishCounter.attach(self, label: "SemanticSearchEngine")
        #if os(iOS)
        // Up to 3 resident corpora × ~10-25MB of vectors is the app's largest droppable allocation.
        // Under a real memory warning, shed everything but the most recently used corpus - the evicted
        // ones reload from disk in one read on their next search (a latency blip, not a rebuild).
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification, object: nil, queue: .main
        ) { _ in
            MainActor.assumeIsolated {
                SemanticSearchEngine.shared.trimForMemoryPressure()
            }
        }
        #endif
    }

    /// Keep only the most recently used corpus (Ask AI's `onDisappear`; Phase 6 step 5).
    func releaseIdleCorpora() {
        trimForMemoryPressure()
    }

    private func trimForMemoryPressure() {
        while lruOrder.count > 1, let oldest = lruOrder.first {
            lruOrder.removeFirst()
            corpora.removeValue(forKey: oldest)
            readyCorpora.remove(oldest)
            SemanticBuildProgress.shared.set(oldest, nil)
        }
    }

    /// Corpus build state, 1.0 == ready. Lives in `SemanticBuildProgress` - its own publisher - so a
    /// build's per-chunk ticks re-render only the status row, never the List observing this engine.
    var buildProgress: [String: Double] { SemanticBuildProgress.shared.progress }
    /// Ids whose vectors are loaded in memory and queryable right now.
    @Published private(set) var readyCorpora: Set<String> = []
    /// A build that failed (embedding unavailable, disk write failure) - the UI stays keyword-only.
    @Published private(set) var failedCorpora: Set<String> = []

    /// Whether this device can embed English words at all (the word embedding ships with the OS; on the
    /// rare configuration without it, AI search hides itself instead of showing a dead section).
    ///
    /// Resolved through `embedQueue`, REUSING the one shared embedder - the old `static let` loaded the
    /// model a second time just to discard it, and its first touch happened on the MAIN thread (from
    /// `aiQueryEligible` / corpus prep during the launch window): a disk-backed model load as a body
    /// side-effect. `prewarmOffMain()` pays it on the serial lane at startup; after that this is a
    /// lock-free Bool read (the unsynchronized fast path is a set-once word-sized value - the same
    /// `nonisolated(unsafe)` discipline as `embedder`, whose safety invariant is the queue).
    nonisolated(unsafe) private static var supportedResolved: Bool?
    nonisolated static var isSupported: Bool {
        if let resolved = supportedResolved { return resolved }
        return embedQueue.sync {
            if let resolved = supportedResolved { return resolved }
            if embedder == nil { embedder = NLEmbedding.wordEmbedding(for: .english) }
            let supported = embedder != nil
            supportedResolved = supported
            return supported
        }
    }

    /// `isSupported` when the probe has already run, nil when reading it would load the model here.
    nonisolated static var isSupportedIfResolved: Bool? { supportedResolved }

    /// Forces the `isSupported` model load onto the serial lane from a background context. Called from
    /// the Quran data load, so the first body that reads `isSupported` gets a cached Bool, not a model load.
    nonisolated static func prewarmOffMain() {
        _ = isSupported
    }

    private var corpora: [String: SemanticCorpus] = [:]
    private var buildsInFlight: Set<String> = []
    /// Disk loads in progress, by corpus id: `prepare` reads a persisted corpus in a detached task
    /// (a 22 MB file parsed on the main actor was a 100-300 ms stall on every search-field focus).
    private var loadsInFlight: [String: Task<SemanticCorpus?, Never>] = [:]
    /// Most-recently-used corpus ids, newest last - memory cap: a corpus's vocab matrix is ~10-25MB of
    /// Float32s, so only the few the user is actively searching stay resident.
    private var lruOrder: [String] = []
    private static let maxResidentCorpora = 3

    /// One shared word embedder, confined to `embedQueue` (NLEmbedding's thread-safety is undocumented,
    /// so every touch - corpus build and query alike - goes through the same serial lane).
    nonisolated(unsafe) private static var embedder: NLEmbedding?
    nonisolated private static let embedQueue = DispatchQueue(label: "semantic.embed", qos: .userInitiated)

    // MARK: Tokenization (ONE rule for corpus build and queries, or scores are meaningless)

    /// Filler words that would let "the/and/of" dominate the max-similarity scores.
    nonisolated private static let stopwords: Set<String> = [
        "the", "and", "for", "you", "your", "yours", "them", "they", "their", "with", "that", "this",
        "these", "those", "have", "has", "had", "not", "are", "was", "were", "will", "shall", "who",
        "whom", "whose", "then", "than", "him", "her", "his", "hers", "its", "one", "all", "any",
        "but", "from", "into", "unto", "upon", "over", "under", "about", "there", "here", "when",
        "what", "which", "while", "been", "being", "does", "did", "doing", "can", "could", "would",
        "should", "may", "might", "must", "let", "each", "every", "some", "such", "own", "same",
        "say", "said", "says", "indeed", "verily", "surely"
    ]

    /// Lowercased alphanumeric words, 3+ letters, minus stopwords, deduped in order.
    nonisolated static func tokens(of text: String) -> [String] {
        var seen = Set<String>()
        return text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 2 && !stopwords.contains($0) && seen.insert($0).inserted }
    }

    nonisolated private static func normalized(_ vector: [Double]) -> [Float] {
        var floats = vector.map { Float($0) }
        var norm: Float = 0
        vDSP_svesq(floats, 1, &norm, vDSP_Length(floats.count))
        norm = sqrt(norm)
        if norm > 0 {
            var divisor = norm
            vDSP_vsdiv(floats, 1, &divisor, &floats, 1, vDSP_Length(floats.count))
        }
        return floats
    }

    /// Normalized word vector via the serial lane. `nil` for out-of-vocabulary words.
    nonisolated private static func wordVector(_ word: String) -> [Float]? {
        embedQueue.sync {
            if embedder == nil { embedder = NLEmbedding.wordEmbedding(for: .english) }
            guard let embedder, let vector = embedder.vector(for: word) else { return nil }
            return normalized(vector)
        }
    }

    /// A whole CHUNK of words in one queue hop - the per-word `sync` overhead was most of the build
    /// time for a large vocabulary (tens of thousands of hops collapsed into a few dozen).
    nonisolated private static func wordVectors(for words: ArraySlice<String>) -> [[Float]?] {
        embedQueue.sync {
            if embedder == nil { embedder = NLEmbedding.wordEmbedding(for: .english) }
            guard let embedder else { return Array(repeating: nil, count: words.count) }
            return words.map { word in
                embedder.vector(for: word).map { normalized($0) }
            }
        }
    }

    func isReady(_ corpusID: String) -> Bool { readyCorpora.contains(corpusID) }
    /// True while the corpus is being built OR loaded from disk - either way a `prepare` would be a
    /// duplicate, and the UI shows the preparing row.
    func isBuilding(_ corpusID: String) -> Bool {
        buildsInFlight.contains(corpusID) || loadsInFlight[corpusID] != nil
    }
    func progress(_ corpusID: String) -> Double { buildProgress[corpusID] ?? 0 }

    /// Waits for an in-flight DISK LOAD of this corpus to land (or fail over to a build). Callers
    /// that used to read the corpus in the same turn as `prepare` await this instead.
    func awaitDiskLoad(_ corpusID: String) async {
        while let load = loadsInFlight[corpusID] {
            _ = await load.value
            // The load's own continuation stores the corpus on the main actor; let it run first.
            await Task.yield()
        }
    }

    /// The loaded corpus, for callers that need its per-item keys (the all-books hadith corpus maps
    /// positional results back to "slug|idInBook" through them).
    func corpus(_ corpusID: String) -> SemanticCorpus? {
        corpora[corpusID]
    }

    /// Load-or-build the corpus. Safe to call repeatedly - it no-ops when ready or already building.
    /// `texts` is resolved ON MAIN by the caller and copied into the build task. `keys`, when given,
    /// are persisted positional identifiers (one per text) that survive across launches - how a
    /// cross-book corpus knows which book+hadith each row is without re-decoding every book.
    func prepare(corpusID: String, version: String, texts: @escaping @autoclosure () -> [String], keys: [String]? = nil) {
        guard Self.isSupported else { return }
        guard corpora[corpusID] == nil, !buildsInFlight.contains(corpusID), loadsInFlight[corpusID] == nil else { return }
        failedCorpora.remove(corpusID)

        // Disk first: a corpus built in ANY earlier session loads in one read - OFF the main actor
        // (Performance Guide, Phase 7 step 2). `isBuilding` is true meanwhile, so a second caller
        // neither duplicates the load nor gathers texts it will not need.
        if SemanticCorpus.exists(id: corpusID, version: version) {
            let load = Task.detached(priority: .userInitiated) {
                SemanticCorpus.load(id: corpusID, version: version)
            }
            loadsInFlight[corpusID] = load
            Task { @MainActor [weak self] in
                let loaded = await load.value
                guard let self else { return }
                self.loadsInFlight[corpusID] = nil
                if let loaded {
                    self.store(loaded, id: corpusID)
                } else {
                    // Unreadable or stale file: build from the texts as if it never existed.
                    self.startBuild(corpusID: corpusID, version: version, texts: texts(), keys: keys)
                }
            }
            return
        }
        startBuild(corpusID: corpusID, version: version, texts: texts(), keys: keys)
    }

    private func startBuild(corpusID: String, version: String, texts list: [String], keys: [String]?) {
        guard corpora[corpusID] == nil, !buildsInFlight.contains(corpusID) else { return }
        let itemKeys = keys
        guard !list.isEmpty, itemKeys == nil || itemKeys?.count == list.count else { return }
        buildsInFlight.insert(corpusID)
        SemanticBuildProgress.shared.set(corpusID, 0)

        // userInitiated: the user is literally watching the progress row. Every build is behind a
        // typed query or a search-field focus (nothing builds speculatively any more); on the reduced
        // tier it still runs, at utility, so a 51k-hadith embedding never competes with the taps
        // that asked for it (Performance Guide, Phase 6 step 6).
        let priority: TaskPriority = AppPerformance.shouldAvoidBroadPrewarm ? .utility : .userInitiated
        Task.detached(priority: priority) {
            // Pass 1: tokenize every text and collect the vocabulary.
            var itemTokens: [[String]] = []
            itemTokens.reserveCapacity(list.count)
            var vocabIndex: [String: Int32] = [:]
            var vocabWords: [String] = []
            for text in list {
                let toks = Self.tokens(of: text)
                itemTokens.append(toks)
                for tok in toks where vocabIndex[tok] == nil {
                    vocabIndex[tok] = Int32(vocabWords.count)
                    vocabWords.append(tok)
                }
            }

            // Pass 2: embed the vocabulary (the expensive part - thousands of words, not thousands of
            // sentences), CHUNKED so the serial-queue overhead is paid dozens of times, not per word.
            var vectors: [Float] = []
            var dim = 0
            var kept: [String: Int32] = [:]      // word -> index into the KEPT matrix (OOV dropped)
            var keptWords: [String] = []
            let chunkSize = 512
            var position = 0
            while position < vocabWords.count {
                let end = min(position + chunkSize, vocabWords.count)
                let chunk = Self.wordVectors(for: vocabWords[position..<end])
                for (offset, maybeVector) in chunk.enumerated() {
                    guard let vector = maybeVector else { continue }
                    if dim == 0 {
                        dim = vector.count
                        vectors.reserveCapacity(dim * vocabWords.count)
                    }
                    kept[vocabWords[position + offset]] = Int32(keptWords.count)
                    keptWords.append(vocabWords[position + offset])
                    vectors.append(contentsOf: vector)
                }
                position = end
                let fraction = Double(position) / Double(max(vocabWords.count, 1))
                await MainActor.run { SemanticBuildProgress.shared.set(corpusID, fraction) }
            }

            guard dim > 0, !keptWords.isEmpty else {
                await MainActor.run {
                    let engine = SemanticSearchEngine.shared
                    engine.buildsInFlight.remove(corpusID)
                    SemanticBuildProgress.shared.set(corpusID, nil)
                    engine.failedCorpora.insert(corpusID)
                }
                return
            }

            // Pass 3: each item as its kept-word indices (positional - item i is texts[i]).
            var itemWordIndices: [[Int32]] = []
            itemWordIndices.reserveCapacity(itemTokens.count)
            for toks in itemTokens {
                itemWordIndices.append(toks.compactMap { kept[$0] })
            }

            let corpus = SemanticCorpus(
                id: corpusID, version: version, dimension: dim,
                vocabWords: keptWords, vocabVectors: vectors, itemWordIndices: itemWordIndices,
                itemKeys: itemKeys
            )
            corpus.persist()

            await MainActor.run {
                let engine = SemanticSearchEngine.shared
                engine.buildsInFlight.remove(corpusID)
                engine.store(corpus, id: corpusID)
            }
        }
    }

    private func store(_ corpus: SemanticCorpus, id: String) {
        corpora[id] = corpus
        SemanticBuildProgress.shared.set(id, 1)
        readyCorpora.insert(id)
        lruOrder.removeAll { $0 == id }
        lruOrder.append(id)
        while lruOrder.count > Self.maxResidentCorpora, let oldest = lruOrder.first {
            lruOrder.removeFirst()
            corpora.removeValue(forKey: oldest)
            readyCorpora.remove(oldest)
            SemanticBuildProgress.shared.set(oldest, nil)
        }
    }

    /// Top matches: (positional index into the corpus texts, score). MaxSim with a DATA-CALIBRATED
    /// relative floor - `max(0.38, best × 0.85)` - measured so related verses pass and near-miss
    /// unrelated ones don't. The scan runs detached on the corpus's immutable tables.
    func search(corpusID: String, query: String, limit: Int = 20) async -> [(index: Int, score: Float)] {
        guard let corpus = corpora[corpusID] else { return [] }
        lruOrder.removeAll { $0 == corpusID }
        lruOrder.append(corpusID)

        let queryTokens = Self.tokens(of: query)
        guard !queryTokens.isEmpty else { return [] }

        // Bridge cancellation into the DETACHED scan (same fix as the keyword scans in QuranView):
        // detached tasks don't inherit it, so `topMatches`' Task.isCancelled poll never fired and an
        // abandoned query's scan always ran to completion - proportionally worst for the
        // tens-of-thousands-item all-books hadith corpus.
        let scan = Task.detached(priority: .userInitiated) {
            let queryVectors = queryTokens.compactMap { Self.wordVector($0) }
            guard !queryVectors.isEmpty else { return [(index: Int, score: Float)]() }
            return corpus.topMatches(queryVectors: queryVectors, limit: limit)
        }
        return await withTaskCancellationHandler {
            await scan.value
        } onCancel: {
            scan.cancel()
        }
    }
}

/// The build-progress publisher, split out of the engine: the engine's `objectWillChange` is
/// observed by whole search screens (their `readyCorpora` onChange needs it), and a 51k-hadith
/// build used to publish 60-120 times through it - each a full List rebuild. Only
/// `AISearchStatusRow` observes this object, and it publishes at most every 100 ms.
@MainActor
final class SemanticBuildProgress: ObservableObject {
    static let shared = SemanticBuildProgress()

    @Published private(set) var progress: [String: Double] = [:]
    private var lastPublish: [String: CFAbsoluteTime] = [:]

    /// nil clears the entry; 1.0 (ready) and nil always publish, intermediate ticks are throttled.
    func set(_ corpusID: String, _ value: Double?) {
        guard let value else {
            lastPublish[corpusID] = nil
            if progress[corpusID] != nil { progress[corpusID] = nil }
            return
        }
        let now = CFAbsoluteTimeGetCurrent()
        if value < 1, let last = lastPublish[corpusID], now - last < 0.1 { return }
        lastPublish[corpusID] = now
        progress[corpusID] = value
    }
}

/// One corpus's immutable MaxSim tables - safe to hand to any thread.
/// `vocabVectors` is the row-major (vocab × dim) matrix of normalized word vectors; each item is the
/// list of its words' rows. Scoring: mean over query words of the best per-word similarity in the item.
///
/// The per-item word rows are stored FLAT (`itemWords` + `itemOffsets`, CSR-style) rather than as
/// `[[Int32]]`: the all-books hadith corpus has 50,884 items, and one heap array each was 50,884
/// allocations on every load plus a `subdata` copy apiece (performance plan, Phase 7 step 2).
final class SemanticCorpus: @unchecked Sendable {
    let id: String
    let version: String
    let dimension: Int
    let vocabWords: [String]
    let vocabVectors: [Float]
    /// Item i's word rows are `itemWords[itemOffsets[i]..<itemOffsets[i + 1]]`.
    let itemWords: [Int32]
    let itemOffsets: [Int32]
    /// Optional positional identifiers ("slug|idInBook"), persisted - lets the all-books corpus map a
    /// result row back to its book without re-decoding anything.
    let itemKeys: [String]?

    var itemCount: Int { max(itemOffsets.count - 1, 0) }

    convenience init(id: String, version: String, dimension: Int,
         vocabWords: [String], vocabVectors: [Float], itemWordIndices: [[Int32]],
         itemKeys: [String]? = nil) {
        var words: [Int32] = []
        var offsets: [Int32] = [0]
        words.reserveCapacity(itemWordIndices.reduce(0) { $0 + $1.count })
        offsets.reserveCapacity(itemWordIndices.count + 1)
        for indices in itemWordIndices {
            words.append(contentsOf: indices)
            offsets.append(Int32(words.count))
        }
        self.init(id: id, version: version, dimension: dimension, vocabWords: vocabWords,
                  vocabVectors: vocabVectors, itemWords: words, itemOffsets: offsets, itemKeys: itemKeys)
    }

    init(id: String, version: String, dimension: Int,
         vocabWords: [String], vocabVectors: [Float], itemWords: [Int32], itemOffsets: [Int32],
         itemKeys: [String]? = nil) {
        self.id = id
        self.version = version
        self.dimension = dimension
        self.vocabWords = vocabWords
        self.vocabVectors = vocabVectors
        self.itemWords = itemWords
        self.itemOffsets = itemOffsets
        self.itemKeys = itemKeys
    }

    func topMatches(queryVectors: [[Float]], limit: Int) -> [(index: Int, score: Float)] {
        let vocabCount = vocabWords.count
        let itemCount = self.itemCount
        guard vocabCount > 0, itemCount > 0 else { return [] }

        // One sgemv per query word: its similarity against the WHOLE vocabulary at once.
        var similarityTables: [[Float]] = []
        similarityTables.reserveCapacity(queryVectors.count)
        for queryVector in queryVectors where queryVector.count == dimension {
            var table = [Float](repeating: 0, count: vocabCount)
            vocabVectors.withUnsafeBufferPointer { matrix in
                queryVector.withUnsafeBufferPointer { q in
                    table.withUnsafeMutableBufferPointer { out in
                        cblas_sgemv(CblasRowMajor, CblasNoTrans, Int32(vocabCount), Int32(dimension),
                                    1, matrix.baseAddress, Int32(dimension),
                                    q.baseAddress, 1, 0, out.baseAddress, 1)
                    }
                }
            }
            similarityTables.append(table)
        }
        guard !similarityTables.isEmpty else { return [] }

        // MaxSim per item: mean over query words of the best table value among the item's words.
        var scored: [(index: Int, score: Float)] = []
        scored.reserveCapacity(min(limit * 4, itemCount))
        var best: Float = 0
        var cancelled = false
        let tableCount = Float(similarityTables.count)
        itemWords.withUnsafeBufferPointer { words in
            itemOffsets.withUnsafeBufferPointer { offsets in
                for index in 0..<itemCount {
                    // Abandoned query (the debounce task was cancelled after this scan started): stop
                    // burning CPU. Cheap flag check, meaningful for the 51k-item all-books corpus.
                    if index & 0x3FF == 0, Task.isCancelled { cancelled = true; return }
                    let start = Int(offsets[index]), end = Int(offsets[index + 1])
                    guard end > start else { continue }
                    var total: Float = 0
                    for table in similarityTables {
                        var maxSim: Float = -1
                        for position in start..<end {
                            let sim = table[Int(words[position])]
                            if sim > maxSim { maxSim = sim }
                        }
                        total += maxSim
                    }
                    let score = total / tableCount
                    if score > best { best = score }
                    if score >= 0.30 {   // coarse pre-filter; the calibrated floor below does the real gating
                        scored.append((index, score))
                    }
                }
            }
        }
        if cancelled { return [] }

        // The calibrated floor: absolute 0.38 (below it nothing is a real match), tightened toward the
        // best hit so a strong result set sheds its weak tail.
        let floor = max(0.38, best * 0.85)
        return scored
            .filter { $0.score >= floor }
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: Disk persistence (Caches - rebuildable data)
    // [magic][dim][vocabCount][itemCount][vocab blob len][vocab words \n][keys blob len (0 = none)]
    // [keys \n][vectors][per-item counts][indices]

    private static let magic: UInt32 = 0x53454D33   // "SEM3" - older cache formats are ignored

    private static func fileURL(id: String, version: String) -> URL? {
        guard let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        let dir = caches.appendingPathComponent("SemanticVectors", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let safe = "\(id)-\(version)".replacingOccurrences(of: "/", with: "_")
        return dir.appendingPathComponent("\(safe).vec3")
    }

    func persist() {
        guard let url = Self.fileURL(id: id, version: version) else { return }
        var data = Data()
        func appendU32(_ value: UInt32) {
            withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
        }
        let wordsBlob = Data(vocabWords.joined(separator: "\n").utf8)
        let keysBlob = itemKeys.map { Data($0.joined(separator: "\n").utf8) }
        appendU32(Self.magic)
        appendU32(UInt32(dimension))
        appendU32(UInt32(vocabWords.count))
        appendU32(UInt32(itemCount))
        appendU32(UInt32(wordsBlob.count))
        data.append(wordsBlob)
        appendU32(UInt32(keysBlob?.count ?? 0))
        if let keysBlob { data.append(keysBlob) }
        vocabVectors.withUnsafeBufferPointer { data.append(Data(buffer: $0)) }
        itemWords.withUnsafeBufferPointer { words in
            for index in 0..<itemCount {
                let start = Int(itemOffsets[index]), end = Int(itemOffsets[index + 1])
                appendU32(UInt32(end - start))
                if end > start {
                    data.append(Data(buffer: UnsafeBufferPointer(rebasing: words[start..<end])))
                }
            }
        }
        try? data.write(to: url, options: .atomic)
        // Older versions of the SAME corpus are dead weight from here on: the Quran corpus folds the
        // bundled source's stamp into its version, so every app update (and every dev rebuild) left
        // one more 8 MB file behind - six of them on the dev simulator. One id, one file.
        let prefix = "\(id)-"
        let keep = url.lastPathComponent
        if let files = try? FileManager.default.contentsOfDirectory(at: url.deletingLastPathComponent(),
                                                                    includingPropertiesForKeys: nil) {
            for file in files where file.pathExtension == "vec3" {
                let name = file.lastPathComponent
                guard name != keep, name.hasPrefix(prefix) else { continue }
                // "quran-en-…" must not match "quran-en-extra-…": the version follows the id directly,
                // and no other corpus id starts with this id plus a dash today; kept exact by prefix.
                try? FileManager.default.removeItem(at: file)
            }
        }
    }

    /// Whether a persisted build exists for this id + version - the cheap check `prepare` makes on
    /// the main actor before starting the (detached) load.
    static func exists(id: String, version: String) -> Bool {
        guard let url = fileURL(id: id, version: version) else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    /// Parse a persisted corpus. Runs OFF the main actor (see `SemanticSearchEngine.prepare`): the
    /// file is mapped, every table is copied out with one `memcpy` per table - no `subdata` per
    /// item - and the item rows land in the flat CSR arrays directly.
    static func load(id: String, version: String) -> SemanticCorpus? {
        guard let url = fileURL(id: id, version: version),
              let data = try? Data(contentsOf: url, options: [.mappedIfSafe]), data.count > 24 else { return nil }

        return data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) -> SemanticCorpus? in
            guard let base = raw.baseAddress else { return nil }
            let total = raw.count
            var offset = 0
            func readU32() -> UInt32? {
                guard offset + 4 <= total else { return nil }
                let value = UInt32(littleEndian: base.loadUnaligned(fromByteOffset: offset, as: UInt32.self))
                offset += 4
                return value
            }
            func readBlob(_ length: Int) -> String? {
                guard length >= 0, offset + length <= total else { return nil }
                defer { offset += length }
                let bytes = UnsafeRawBufferPointer(rebasing: raw[offset..<(offset + length)])
                return String(decoding: bytes, as: UTF8.self)
            }

            guard readU32() == magic,
                  let dim32 = readU32(), let vocabCount32 = readU32(),
                  let itemCount32 = readU32(), let blobLen32 = readU32() else { return nil }
            let dim = Int(dim32), vocabCount = Int(vocabCount32)
            let itemCount = Int(itemCount32)

            guard dim > 0, vocabCount > 0,
                  let wordsString = readBlob(Int(blobLen32)) else { return nil }
            let words = wordsString.components(separatedBy: "\n")
            guard words.count == vocabCount else { return nil }

            guard let keysLen32 = readU32() else { return nil }
            var keys: [String]?
            if keysLen32 > 0 {
                guard let keysString = readBlob(Int(keysLen32)) else { return nil }
                let parsed = keysString.components(separatedBy: "\n")
                guard parsed.count == itemCount else { return nil }
                keys = parsed
            }

            let vectorCount = vocabCount * dim
            let vectorBytes = vectorCount * 4
            guard offset + vectorBytes <= total else { return nil }
            let vectorStart = offset
            let vectors = [Float](unsafeUninitializedCapacity: vectorCount) { buffer, initialized in
                memcpy(buffer.baseAddress!, base + vectorStart, vectorBytes)
                initialized = vectorCount
            }
            offset += vectorBytes

            // Every remaining byte past the per-item counts is a word row: an upper bound that lets
            // the flat array reserve once.
            var itemWords: [Int32] = []
            itemWords.reserveCapacity(max(0, (total - offset) / 4 - itemCount))
            var itemOffsets: [Int32] = [0]
            itemOffsets.reserveCapacity(itemCount + 1)
            for _ in 0..<itemCount {
                guard let count32 = readU32() else { return nil }
                let count = Int(count32)
                let bytes = count * 4
                guard offset + bytes <= total else { return nil }
                let start = offset
                let previous = itemWords.count
                itemWords.append(contentsOf: [Int32](unsafeUninitializedCapacity: count) { buffer, initialized in
                    if count > 0 { memcpy(buffer.baseAddress!, base + start, bytes) }
                    initialized = count
                })
                for position in previous..<itemWords.count where Int(itemWords[position]) >= vocabCount {
                    return nil
                }
                offset += bytes
                itemOffsets.append(Int32(itemWords.count))
            }

            return SemanticCorpus(id: id, version: version, dimension: dim,
                                  vocabWords: words, vocabVectors: vectors,
                                  itemWords: itemWords, itemOffsets: itemOffsets, itemKeys: keys)
        }
    }
}

// MARK: - Shared UI: the build-progress row
// (AI results appear automatically alongside keyword results - there is deliberately no mode toggle.)

/// The one-time build state row: progress while vectors build, a plain note when unsupported/failed.
/// It observes `SemanticBuildProgress` ITSELF, so a build's ticks re-render this row alone and not
/// the search screen hosting it.
struct AISearchStatusRow: View {
    @ObservedObject private var build = SemanticBuildProgress.shared

    let corpusID: String
    let failed: Bool

    private var progress: Double { build.progress[corpusID] ?? 0 }

    var body: some View {
        HStack(spacing: 10) {
            if failed {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.secondary)
                Text("AI search couldn't prepare on this device - keyword results are shown.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ProgressView(value: progress)
                    .frame(maxWidth: 120)
                Text("Preparing AI search… \(Int(progress * 100))%")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 6)
    }
}

#endif
