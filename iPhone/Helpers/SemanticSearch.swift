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

    /// Corpus build state, published for the UI's progress row. 1.0 == ready.
    @Published private(set) var buildProgress: [String: Double] = [:]
    /// Ids whose vectors are loaded in memory and queryable right now.
    @Published private(set) var readyCorpora: Set<String> = []
    /// A build that failed (embedding unavailable, disk write failure) - the UI stays keyword-only.
    @Published private(set) var failedCorpora: Set<String> = []

    /// Whether this device can embed English words at all (the word embedding ships with the OS; on the
    /// rare configuration without it, AI search hides itself instead of showing a dead section).
    static let isSupported: Bool = NLEmbedding.wordEmbedding(for: .english) != nil

    private var corpora: [String: SemanticCorpus] = [:]
    private var buildsInFlight: Set<String> = []
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
    func isBuilding(_ corpusID: String) -> Bool { buildsInFlight.contains(corpusID) }
    func progress(_ corpusID: String) -> Double { buildProgress[corpusID] ?? 0 }

    /// The loaded corpus, for callers that need its per-item keys (the all-books hadith corpus maps
    /// positional results back to "slug|idInBook" through them).
    func corpus(_ corpusID: String) -> SemanticCorpus? {
        corpora[corpusID]
    }

    /// Load-or-build the corpus. Safe to call repeatedly - it no-ops when ready or already building.
    /// `texts` is resolved ON MAIN by the caller and copied into the build task. `keys`, when given,
    /// are persisted positional identifiers (one per text) that survive across launches - how a
    /// cross-book corpus knows which book+hadith each row is without re-decoding every book.
    func prepare(corpusID: String, version: String, texts: @autoclosure () -> [String], keys: [String]? = nil) {
        guard Self.isSupported else { return }
        guard corpora[corpusID] == nil, !buildsInFlight.contains(corpusID) else { return }
        failedCorpora.remove(corpusID)

        // Disk first: a corpus built in ANY earlier session loads in one read.
        if let loaded = SemanticCorpus.load(id: corpusID, version: version) {
            store(loaded, id: corpusID)
            return
        }

        let list = texts()
        let itemKeys = keys
        guard !list.isEmpty, itemKeys == nil || itemKeys?.count == list.count else { return }
        buildsInFlight.insert(corpusID)
        buildProgress[corpusID] = 0

        // userInitiated: the user is literally watching the progress row.
        Task.detached(priority: .userInitiated) {
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
                await MainActor.run { SemanticSearchEngine.shared.buildProgress[corpusID] = fraction }
            }

            guard dim > 0, !keptWords.isEmpty else {
                await MainActor.run {
                    let engine = SemanticSearchEngine.shared
                    engine.buildsInFlight.remove(corpusID)
                    engine.buildProgress[corpusID] = nil
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
        buildProgress[id] = 1
        readyCorpora.insert(id)
        lruOrder.removeAll { $0 == id }
        lruOrder.append(id)
        while lruOrder.count > Self.maxResidentCorpora, let oldest = lruOrder.first {
            lruOrder.removeFirst()
            corpora.removeValue(forKey: oldest)
            readyCorpora.remove(oldest)
            buildProgress[oldest] = nil
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

        return await Task.detached(priority: .userInitiated) {
            let queryVectors = queryTokens.compactMap { Self.wordVector($0) }
            guard !queryVectors.isEmpty else { return [] }
            return corpus.topMatches(queryVectors: queryVectors, limit: limit)
        }.value
    }
}

/// One corpus's immutable MaxSim tables - safe to hand to any thread.
/// `vocabVectors` is the row-major (vocab × dim) matrix of normalized word vectors; each item is the
/// list of its words' rows. Scoring: mean over query words of the best per-word similarity in the item.
final class SemanticCorpus: @unchecked Sendable {
    let id: String
    let version: String
    let dimension: Int
    let vocabWords: [String]
    let vocabVectors: [Float]
    let itemWordIndices: [[Int32]]
    /// Optional positional identifiers ("slug|idInBook"), persisted - lets the all-books corpus map a
    /// result row back to its book without re-decoding anything.
    let itemKeys: [String]?

    init(id: String, version: String, dimension: Int,
         vocabWords: [String], vocabVectors: [Float], itemWordIndices: [[Int32]],
         itemKeys: [String]? = nil) {
        self.id = id
        self.version = version
        self.dimension = dimension
        self.vocabWords = vocabWords
        self.vocabVectors = vocabVectors
        self.itemWordIndices = itemWordIndices
        self.itemKeys = itemKeys
    }

    func topMatches(queryVectors: [[Float]], limit: Int) -> [(index: Int, score: Float)] {
        let vocabCount = vocabWords.count
        guard vocabCount > 0, !itemWordIndices.isEmpty else { return [] }

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
        scored.reserveCapacity(min(limit * 4, itemWordIndices.count))
        var best: Float = 0
        for (index, wordRows) in itemWordIndices.enumerated() {
            guard !wordRows.isEmpty else { continue }
            var total: Float = 0
            for table in similarityTables {
                var maxSim: Float = -1
                for row in wordRows {
                    let sim = table[Int(row)]
                    if sim > maxSim { maxSim = sim }
                }
                total += maxSim
            }
            let score = total / Float(similarityTables.count)
            if score > best { best = score }
            if score >= 0.30 {   // coarse pre-filter; the calibrated floor below does the real gating
                scored.append((index, score))
            }
        }

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
        appendU32(UInt32(itemWordIndices.count))
        appendU32(UInt32(wordsBlob.count))
        data.append(wordsBlob)
        appendU32(UInt32(keysBlob?.count ?? 0))
        if let keysBlob { data.append(keysBlob) }
        vocabVectors.withUnsafeBufferPointer { data.append(Data(buffer: $0)) }
        for indices in itemWordIndices {
            appendU32(UInt32(indices.count))
            indices.withUnsafeBufferPointer { data.append(Data(buffer: $0)) }
        }
        try? data.write(to: url, options: .atomic)
    }

    static func load(id: String, version: String) -> SemanticCorpus? {
        guard let url = fileURL(id: id, version: version),
              let data = try? Data(contentsOf: url), data.count > 24 else { return nil }

        var offset = 0
        func readU32() -> UInt32? {
            guard offset + 4 <= data.count else { return nil }
            var value: UInt32 = 0
            _ = withUnsafeMutableBytes(of: &value) { data.copyBytes(to: $0, from: offset..<(offset + 4)) }
            offset += 4
            return UInt32(littleEndian: value)
        }
        func readBlob(_ length: Int) -> String? {
            guard length >= 0, offset + length <= data.count else { return nil }
            defer { offset += length }
            return String(data: data.subdata(in: offset..<(offset + length)), encoding: .utf8)
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

        let vectorBytes = vocabCount * dim * 4
        guard offset + vectorBytes <= data.count else { return nil }
        let vectors = data.subdata(in: offset..<(offset + vectorBytes)).withUnsafeBytes {
            [Float]($0.bindMemory(to: Float.self))
        }
        offset += vectorBytes

        var items: [[Int32]] = []
        items.reserveCapacity(itemCount)
        for _ in 0..<itemCount {
            guard let count32 = readU32() else { return nil }
            let count = Int(count32)
            let bytes = count * 4
            guard offset + bytes <= data.count else { return nil }
            let indices = data.subdata(in: offset..<(offset + bytes)).withUnsafeBytes {
                [Int32]($0.bindMemory(to: Int32.self))
            }
            offset += bytes
            guard indices.allSatisfy({ Int($0) < vocabCount }) else { return nil }
            items.append(indices)
        }

        return SemanticCorpus(id: id, version: version, dimension: dim,
                              vocabWords: words, vocabVectors: vectors, itemWordIndices: items,
                              itemKeys: keys)
    }
}

// MARK: - Shared UI: the build-progress row
// (AI results appear automatically alongside keyword results - there is deliberately no mode toggle.)

/// The one-time build state row: progress while vectors build, a plain note when unsupported/failed.
struct AISearchStatusRow: View {
    let progress: Double
    let failed: Bool

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
