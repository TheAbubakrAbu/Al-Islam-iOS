import Foundation
import Combine
import NaturalLanguage
import Accelerate

#if os(iOS)

/// On-device semantic ("AI") search over a corpus of texts, powered by Apple's NLEmbedding sentence
/// vectors. Everything is local and private: vectors build once per corpus off the main thread (with
/// published progress), persist to the caches directory, and a query is one vDSP cosine scan over the
/// flattened matrix - no network, no keys, instant after the one-time build.
///
/// Corpora are registered by id ("quran-en", "hadith-<slug>"); the UI asks `prepare` when the user first
/// flips into AI mode and `search` on each (debounced) query. Meaning-based matching is the point:
/// "patience in hardship" finds ayahs about sabr whether or not they contain either word.
@MainActor
final class SemanticSearchEngine: ObservableObject {
    static let shared = SemanticSearchEngine()

    /// Corpus build state, published for the UI's progress row. 1.0 == ready.
    @Published private(set) var buildProgress: [String: Double] = [:]
    /// Ids whose vectors are loaded in memory and queryable right now.
    @Published private(set) var readyCorpora: Set<String> = []
    /// A build that failed (embedding unavailable mid-run, disk write failure) - the UI shows keyword-only.
    @Published private(set) var failedCorpora: Set<String> = []

    /// Whether this device can embed English sentences at all (NLEmbedding ships with the OS; on the rare
    /// configuration without it, AI mode hides itself instead of showing a dead toggle).
    static let isSupported: Bool = NLEmbedding.sentenceEmbedding(for: .english) != nil

    private var corpora: [String: SemanticCorpus] = [:]
    private var buildsInFlight: Set<String> = []
    /// Most-recently-used corpus ids, newest last - memory cap: a corpus is ~2-15MB of Float32s, so only
    /// the few the user is actively searching stay resident (evicted ones reload from disk instantly).
    private var lruOrder: [String] = []
    private static let maxResidentCorpora = 3

    /// One shared sentence embedder, confined to `embedQueue` (NLEmbedding's thread-safety is undocumented,
    /// so every touch - corpus build and query alike - goes through the same serial lane).
    nonisolated(unsafe) private static var embedder: NLEmbedding?
    nonisolated private static let embedQueue = DispatchQueue(label: "semantic.embed", qos: .userInitiated)

    /// Embed one text on the serial lane. `nil` when the embedder is unavailable or the text is empty.
    /// Long texts are truncated - the sentence embedding saturates anyway, and shorter is much faster.
    nonisolated private static func embed(_ text: String) -> [Float]? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let clipped = String(trimmed.prefix(600))
        return embedQueue.sync {
            if embedder == nil { embedder = NLEmbedding.sentenceEmbedding(for: .english) }
            guard let embedder, let vector = embedder.vector(for: clipped) else { return nil }
            var floats = vector.map { Float($0) }
            // L2-normalize now so cosine similarity is a plain dot product at query time.
            var norm: Float = 0
            vDSP_svesq(floats, 1, &norm, vDSP_Length(floats.count))
            norm = sqrt(norm)
            if norm > 0 {
                var divisor = norm
                vDSP_vsdiv(floats, 1, &divisor, &floats, 1, vDSP_Length(floats.count))
            }
            return floats
        }
    }

    func isReady(_ corpusID: String) -> Bool { readyCorpora.contains(corpusID) }
    func isBuilding(_ corpusID: String) -> Bool { buildsInFlight.contains(corpusID) }
    func progress(_ corpusID: String) -> Double { buildProgress[corpusID] ?? 0 }

    /// Load-or-build the corpus. Safe to call repeatedly (a flip into AI mode, every appearance) - it
    /// no-ops when ready or already building. `texts` is resolved ON MAIN by the caller and copied into
    /// the build task, so the build never touches live model state (the verse-search snapshot's rule).
    func prepare(corpusID: String, version: String, texts: @autoclosure () -> [String]) {
        guard Self.isSupported else { return }
        guard corpora[corpusID] == nil, !buildsInFlight.contains(corpusID) else { return }
        failedCorpora.remove(corpusID)

        // Disk first: a corpus built in ANY earlier session loads in one read.
        if let loaded = SemanticCorpus.load(id: corpusID, version: version) {
            store(loaded, id: corpusID)
            return
        }

        let list = texts()
        guard !list.isEmpty else { return }
        buildsInFlight.insert(corpusID)
        buildProgress[corpusID] = 0

        Task.detached(priority: .utility) {
            var flat: [Float] = []
            var dim = 0
            var failed = false

            for (index, text) in list.enumerated() {
                if let vector = Self.embed(text) {
                    if dim == 0 {
                        dim = vector.count
                        flat.reserveCapacity(dim * list.count)
                    }
                    flat.append(contentsOf: vector)
                } else if dim > 0 {
                    // An unembeddable entry (empty/foreign text) keeps its slot as a zero vector so
                    // index -> item mapping stays positional - a zero row simply never ranks.
                    flat.append(contentsOf: [Float](repeating: 0, count: dim))
                } else if index == list.count - 1, dim == 0 {
                    failed = true
                }

                if index % 64 == 0 {
                    let fraction = Double(index) / Double(list.count)
                    await MainActor.run { SemanticSearchEngine.shared.buildProgress[corpusID] = fraction }
                }
            }

            guard !failed, dim > 0 else {
                await MainActor.run {
                    let engine = SemanticSearchEngine.shared
                    engine.buildsInFlight.remove(corpusID)
                    engine.buildProgress[corpusID] = nil
                    engine.failedCorpora.insert(corpusID)
                }
                return
            }

            let corpus = SemanticCorpus(id: corpusID, version: version, dimension: dim,
                                        count: flat.count / dim, vectors: flat)
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
        // Evict the least-recently-used resident corpus beyond the cap (its file stays on disk, so a
        // return to it is one load, not a rebuild).
        while lruOrder.count > Self.maxResidentCorpora, let oldest = lruOrder.first {
            lruOrder.removeFirst()
            corpora.removeValue(forKey: oldest)
            readyCorpora.remove(oldest)
            buildProgress[oldest] = nil
        }
    }

    /// Top-`limit` semantically-closest items: (positional index into the corpus texts, cosine score).
    /// The scan runs detached on the corpus's immutable vectors; only the snapshot handoff is on main.
    func search(corpusID: String, query: String, limit: Int = 20, minScore: Float = 0.42) async -> [(index: Int, score: Float)] {
        guard let corpus = corpora[corpusID] else { return [] }
        lruOrder.removeAll { $0 == corpusID }
        lruOrder.append(corpusID)

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else { return [] }

        return await Task.detached(priority: .userInitiated) {
            guard let queryVector = Self.embed(trimmed), queryVector.count == corpus.dimension else { return [] }
            return corpus.topMatches(queryVector: queryVector, limit: limit, minScore: minScore)
        }.value
    }
}

/// One corpus's immutable, flattened vector matrix - safe to hand to any thread (the engine's
/// `VerseSearchSnapshot` discipline). Row i is the L2-normalized embedding of text i.
final class SemanticCorpus: @unchecked Sendable {
    let id: String
    let version: String
    let dimension: Int
    let count: Int
    let vectors: [Float]

    init(id: String, version: String, dimension: Int, count: Int, vectors: [Float]) {
        self.id = id
        self.version = version
        self.dimension = dimension
        self.count = count
        self.vectors = vectors
    }

    /// Cosine scores against every row in ONE `cblas_sgemv` (matrix × query), then a top-K pick.
    /// 6,236 ayahs × 512 dims is ~3M multiply-adds - well under a millisecond on device.
    func topMatches(queryVector: [Float], limit: Int, minScore: Float) -> [(index: Int, score: Float)] {
        guard count > 0, queryVector.count == dimension else { return [] }
        var scores = [Float](repeating: 0, count: count)
        vectors.withUnsafeBufferPointer { matrix in
            queryVector.withUnsafeBufferPointer { q in
                scores.withUnsafeMutableBufferPointer { out in
                    cblas_sgemv(CblasRowMajor, CblasNoTrans, Int32(count), Int32(dimension),
                                1, matrix.baseAddress, Int32(dimension),
                                q.baseAddress, 1, 0, out.baseAddress, 1)
                }
            }
        }

        var ranked: [(index: Int, score: Float)] = []
        ranked.reserveCapacity(min(limit * 2, count))
        for (index, score) in scores.enumerated() where score >= minScore {
            ranked.append((index, score))
        }
        ranked.sort { $0.score > $1.score }
        return Array(ranked.prefix(limit))
    }

    // MARK: Disk persistence: [magic][dim][count][Float32 * dim * count] in Caches (rebuildable data).

    private static let magic: UInt32 = 0x53454D31   // "SEM1"

    private static func fileURL(id: String, version: String) -> URL? {
        guard let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        let dir = caches.appendingPathComponent("SemanticVectors", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let safe = "\(id)-\(version)".replacingOccurrences(of: "/", with: "_")
        return dir.appendingPathComponent("\(safe).vec")
    }

    func persist() {
        guard let url = Self.fileURL(id: id, version: version) else { return }
        var data = Data(capacity: 12 + vectors.count * 4)
        for value in [Self.magic, UInt32(dimension), UInt32(count)] {
            withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
        }
        vectors.withUnsafeBufferPointer { data.append(Data(buffer: $0)) }
        try? data.write(to: url, options: .atomic)
    }

    static func load(id: String, version: String) -> SemanticCorpus? {
        guard let url = fileURL(id: id, version: version),
              let data = try? Data(contentsOf: url), data.count > 12 else { return nil }
        let header = data.prefix(12).withUnsafeBytes { raw -> (UInt32, UInt32, UInt32) in
            let values = raw.bindMemory(to: UInt32.self)
            return (UInt32(littleEndian: values[0]), UInt32(littleEndian: values[1]), UInt32(littleEndian: values[2]))
        }
        guard header.0 == magic else { return nil }
        let dim = Int(header.1), count = Int(header.2)
        guard dim > 0, count > 0, data.count == 12 + dim * count * 4 else { return nil }
        let vectors = data.dropFirst(12).withUnsafeBytes { raw in
            [Float](raw.bindMemory(to: Float.self))
        }
        return SemanticCorpus(id: id, version: version, dimension: dim, count: count, vectors: vectors)
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
