import Foundation

// Ask AI - the chat's own retrieval: every question runs the app's lanes, and their results are
// fused into ONE ranked list of sources the model is handed.
//
// Lanes: what the question NAMES (a verse with its tafsir, a surah's background, a hadith by number,
// a Name of Allah), the Quran's meaning search and its ranked keyword search, the Quran topic and
// passage indexes, the all-books hadith meaning search and the ranked hadith search over the major
// collections, the curated hadith topics, the Islam tab's articles, the Names, the duas (the app's
// collections and Hisn al-Muslim), the Tips & Tricks catalogue (how to use THIS app), and today's
// prayer times. Each lane scores its hits by rank; the question's intent weights the lanes
// (a how-to leans on the articles, a hadith question on the collections, an app question on the
// tips alone); the scores are summed per source (reciprocal-rank fusion), the subject always leads,
// and a diversity cap keeps one family from crowding the others out of the budget.
//
// Nothing here reads a search field or a results list: the answer never depends on what happened to
// be typed or retrieved elsewhere.

#if os(iOS)

@MainActor
enum AskAIRetriever {
    enum Lane: String, CaseIterable {
        case subject, surahName, carried, prayer, tips, settings, articles
        case quranSemantic, quranKeyword, quranTopics
        case hadithSemantic, hadithRanked, hadithTopics
        case names, duas
    }

    struct Outcome {
        var sources: [AskAISource] = []
        /// Per lane, how many candidates it contributed (for the debug log).
        var laneCounts: [Lane: Int] = [:]
        /// The fused ranking, best first (reference and score), for the debug log.
        var ranking: [(reference: String, score: Double)] = []
        var searchText = ""
        var elapsed: TimeInterval = 0
    }

    /// The budget for one turn: how many sources, how much of each, how much of a subject text.
    struct Budget {
        var limit: Int
        var sourceCharacters: Int
        var subjectCharacters: Int
    }

    // MARK: - Lane weights

    /// How much a lane's hits are worth for this kind of question. Summed per source over the lanes
    /// it appears in, each hit worth `weight / (2 + rank)`.
    static func weights(for question: AskAIQuestion) -> [Lane: Double] {
        var w: [Lane: Double] = [
            .subject: 24, .surahName: 1.6, .carried: 0.6, .prayer: 12, .tips: 0.15, .settings: 0.15, .articles: 1.1,
            .quranSemantic: 1.0, .quranKeyword: 0.95, .quranTopics: 0.7,
            .hadithSemantic: 0.9, .hadithRanked: 0.9, .hadithTopics: 0.85,
            .names: 0.8, .duas: 0.8,
        ]
        func scale(_ lanes: [Lane], _ factor: Double) { for lane in lanes { w[lane, default: 0] *= factor } }
        switch question.intent {
        case .appHelp:
            w[.tips] = 30
            w[.settings] = 34
            scale([.articles, .quranSemantic, .quranKeyword, .quranTopics, .hadithSemantic, .hadithRanked, .hadithTopics, .names, .duas, .surahName], 0.05)
        case .scripture:
            scale([.quranSemantic, .quranKeyword, .quranTopics], 1.3)
        case .hadith:
            scale([.hadithSemantic, .hadithRanked, .hadithTopics], 1.5)
            scale([.quranSemantic, .quranKeyword, .quranTopics], 0.75)
        case .define:
            scale([.articles], 1.6)
            scale([.names], 1.3)
        case .story:
            scale([.articles], 1.7)
            scale([.quranSemantic, .quranKeyword], 1.1)
        case .howTo:
            scale([.articles], 1.8)
            scale([.hadithRanked, .hadithTopics], 1.15)
        case .ruling:
            scale([.articles], 1.4)
            scale([.hadithRanked, .hadithSemantic], 1.2)
        case .dua:
            w[.duas] = 4
            scale([.articles], 0.6)
        case .reference:
            scale([.quranSemantic, .quranKeyword, .quranTopics, .hadithSemantic, .hadithRanked, .hadithTopics, .articles], 0.55)
        case .prayerTimes:
            scale([.quranSemantic, .quranKeyword, .quranTopics, .hadithSemantic, .hadithRanked, .hadithTopics], 0.5)
            scale([.articles, .tips], 0.9)
        default:
            break
        }
        if question.leansQuran, question.intent != .hadith { scale([.quranSemantic, .quranKeyword, .quranTopics], 1.2) }
        if question.leansHadith, question.intent != .hadith { scale([.hadithSemantic, .hadithRanked, .hadithTopics], 1.2) }
        if question.mentionsApp, question.intent != .appHelp { w[.tips] = 0.6; w[.settings] = 0.7 }
        return w
    }

    // MARK: - Retrieval

    /// The sources for `question`. `carried` are the previous turn's sources and `carriedCited` the
    /// ones its answer actually used: a follow-up keeps them in the pool ("why?" is about THOSE).
    static func retrieve(_ question: AskAIQuestion, budget: Budget,
                         carried: [AskAISource] = [], carriedCited: [AskAISource] = []) async -> Outcome {
        let started = CFAbsoluteTimeGetCurrent()
        var outcome = Outcome()
        outcome.searchText = question.searchText
        guard question.raw.count >= 2 else { return outcome }

        #if HAS_QURAN
        let quranData = QuranData.shared
        await quranData.waitUntilCoreLoaded()
        #endif
        let weights = weights(for: question)
        var pool = Pool(weights: weights)

        // Lane 0: what the question NAMES, always first; a surah named only by a bare word
        // ("tell me about yusuf") is support, not the subject.
        let named = await subjectSources(for: question, budget: budget)
        for (rank, source) in named.subjects.enumerated() { pool.add(source, lane: .subject, rank: rank) }
        // "what does al-wadud mean": the Name and its verses answer it; a hadith lane fed the bare
        // words ("al", "wadud") returned narrators' names and a hadith about garlic.
        let nameOnly = named.subjects.contains(where: { if case .name = $0.kind { return true } else { return false } })
            && question.contentWords.count <= 2
        for (rank, source) in named.support.enumerated() { pool.add(source, lane: .surahName, rank: rank) }
        if question.isFollowUp {
            // The previous turn's sources stay in the pool ("why?" is about THOSE), stripped of
            // their subject mark: a subject belongs to the question that named it.
            func carriedForm(_ source: AskAISource, quotedBefore: Bool) -> AskAISource? {
                switch source.kind {
                case .prayer: return nil
                case .tip, .setting: return question.mentionsApp ? source : nil
                default:
                    var copy = source
                    copy.isSubject = false
                    copy.wasQuotedBefore = quotedBefore
                    return copy
                }
            }
            for (rank, source) in carriedCited.compactMap({ carriedForm($0, quotedBefore: true) }).prefix(4).enumerated() { pool.add(source, lane: .carried, rank: rank, boost: 0.8) }
            for (rank, source) in carried.compactMap({ carriedForm($0, quotedBefore: false) }).prefix(6).enumerated() { pool.add(source, lane: .carried, rank: rank) }
        }
        #if HAS_ADHAN
        if question.intent == .prayerTimes, let prayer = AskAISourceFactory.prayerTimes() {
            pool.add(prayer, lane: .prayer, rank: 0)
        }
        #endif
        if Task.isCancelled { return outcome }

        // An app question is answered from the settings index and the tips alone: no verse can say
        // where a setting is.
        if question.intent == .appHelp {
            for (rank, source) in settingSources(for: question, limit: 4).enumerated() { pool.add(source, lane: .settings, rank: rank) }
            #if HAS_TIPS
            for (rank, source) in tipSources(for: question, limit: 4).enumerated() { pool.add(source, lane: .tips, rank: rank) }
            #endif
            outcome.laneCounts = pool.counts
            (outcome.sources, outcome.ranking) = pool.select(limit: budget.limit)
            outcome.elapsed = CFAbsoluteTimeGetCurrent() - started
            return outcome
        }

        let semantic = !question.isArabic && SemanticSearchEngine.isSupported
        let engine = SemanticSearchEngine.shared
        let searchText = question.searchText
        let contentWords = question.contentWords
        let semanticQuery = semanticQueryText(for: question)
        // The article index scores plain substrings, so "wudu" must also try "wudhu" and "zakat"
        // "zakah": the articles are searched with the synonyms folded in.
        let articleQuery = question.isArabic ? searchText : keywordQueryText(for: question)

        // The indexes this turn needs, kicked off together. The verse index and the Quran vectors
        // load from the bundle in well under a second on a warm launch; a cold one waits a little
        // rather than answer a Quran question with no Quran (which is what happened when the lanes
        // were skipped the moment they were not ready).
        #if HAS_QURAN
        quranData.ensureVerseSearchIndex()
        if semantic { QuranSemanticCorpus.prepare(quranData: quranData, engine: engine) }
        #endif
        #if HAS_HADITH
        let store = HadithStore.shared
        var hadithReady = false
        if semantic {
            hadithReady = await HadithSemanticCorpus.probeDisk(engine: engine)
            if !hadithReady { Task { await HadithSemanticCorpus.prepare(engine: engine, store: store) } }
        }
        #endif

        // The detached scans run concurrently; each is pure work on immutable data.
        async let articleHits = Task.detached(priority: .userInitiated) {
            IslamArticles.search(articleQuery, limit: 4)
        }.value
        #if HAS_HADITH
        let books = keywordBookOrder.compactMap { slug -> (HadithCatalogBook, HadithBookData)? in
            guard let book = HadithCatalogBook.bySlug[slug], let data = store.book(book) else { return nil }
            return (book, data)
        }
        async let rankedHadiths = Task.detached(priority: .userInitiated) { () -> [(bookIndex: Int, row: Int)] in
            Self.rankHadiths(query: searchText, books: books, limit: 6)
        }.value
        async let topicHadiths = Task.detached(priority: .userInitiated) { () -> [HadithTopicEntry] in
            Self.topicHadiths(words: contentWords, limit: 3)
        }.value
        #endif
        #if HAS_QURAN
        async let topicAyahs = Task.detached(priority: .userInitiated) { () -> [(surah: Int, ayah: Int)] in
            Self.topicAyahs(terms: question.searchTerms, limit: 5)
        }.value

        // Lane: the Quran's ranked keyword search (the only Quran lane an Arabic question has).
        await waitUntilVerseIndexReady(quranData, timeout: 4)
        if !Task.isCancelled, let snapshot = quranData.verseSearchSnapshot() {
            let keywordQuery = question.isArabic ? question.raw : keywordQueryText(for: question)
            let scan = Task.detached(priority: .userInitiated) {
                QuranRankedSearch.search(keywordQuery, snapshot: snapshot, limit: 6).hits
            }
            let hits = await withTaskCancellationHandler { await scan.value } onCancel: { scan.cancel() }
            for (rank, hit) in hits.enumerated() {
                if let source = AskAISourceFactory.ayah(surah: hit.surah, ayah: hit.ayah, quranData: quranData,
                                                        maxCharacters: budget.sourceCharacters) {
                    pool.add(source, lane: .quranKeyword, rank: rank)
                }
            }
        }
        if Task.isCancelled { return outcome }

        // Lane: the Quran's meaning search.
        if semantic {
            await engine.awaitDiskLoad(QuranSemanticCorpus.id)
            if engine.isReady(QuranSemanticCorpus.id) {
                let hits = await engine.search(corpusID: QuranSemanticCorpus.id, query: semanticQuery, limit: 7)
                for (rank, hit) in hits.enumerated() where QuranSemanticCorpus.ayahMap.indices.contains(hit.index) {
                    let ref = QuranSemanticCorpus.ayahMap[hit.index]
                    if let source = AskAISourceFactory.ayah(surah: ref.surah, ayah: ref.ayah, quranData: quranData,
                                                            maxCharacters: budget.sourceCharacters) {
                        pool.add(source, lane: .quranSemantic, rank: rank)
                    }
                }
            }
        }
        if Task.isCancelled { return outcome }
        #endif

        #if HAS_HADITH
        // Lane: the all-books hadith meaning search (only when a persisted build answers now).
        if semantic, !nameOnly, hadithReady || engine.isReady(HadithSemanticCorpus.id),
           let keys = engine.corpus(HadithSemanticCorpus.id)?.itemKeys {
            let hits = await engine.search(corpusID: HadithSemanticCorpus.id, query: semanticQuery, limit: 6)
            var found: [(rank: Int, book: HadithCatalogBook, data: HadithBookData, hadith: HadithBookData.Hadith)] = []
            for (rank, hit) in hits.enumerated() where keys.indices.contains(hit.index) {
                let parts = keys[hit.index].split(separator: "|")
                guard parts.count >= 2, let idInBook = Int(parts[1]),
                      let book = HadithCatalogBook.bySlug[String(parts[0])],
                      let data = store.book(book),
                      let hadith = data.hadiths.first(where: { $0.idInBook == idInBook }) else { continue }
                found.append((rank, book, data, hadith))
            }
            await prewarmHadithText(found.map { ($0.data, $0.hadith.row) })
            for entry in found {
                guard let source = AskAISourceFactory.hadith(book: entry.book, data: entry.data, hadith: entry.hadith,
                                                             maxCharacters: budget.sourceCharacters + 100) else { continue }
                pool.add(source, lane: .hadithSemantic, rank: entry.rank)
            }
        }
        if Task.isCancelled { return outcome }

        // The concurrent scans.
        for (rank, hit) in (await rankedHadiths).enumerated() where !nameOnly && books.indices.contains(hit.bookIndex) {
            let (book, data) = books[hit.bookIndex]
            guard data.hadiths.indices.contains(hit.row),
                  let source = AskAISourceFactory.hadith(book: book, data: data, hadith: data.hadiths[hit.row],
                                                         maxCharacters: budget.sourceCharacters + 100) else { continue }
            pool.add(source, lane: .hadithRanked, rank: rank)
        }
        var topicFound: [(rank: Int, book: HadithCatalogBook, data: HadithBookData, hadith: HadithBookData.Hadith)] = []
        for (rank, entry) in (await topicHadiths).enumerated() where !nameOnly {
            let parts = entry.citationParts
            guard let book = HadithCatalogBook.bySlug[entry.slug], let data = store.book(book),
                  let hadith = data.hadith(referenced: parts.number, suffix: parts.suffix) else { continue }
            topicFound.append((rank, book, data, hadith))
        }
        await prewarmHadithText(topicFound.map { ($0.data, $0.hadith.row) })
        for entry in topicFound {
            guard let source = AskAISourceFactory.hadith(book: entry.book, data: entry.data, hadith: entry.hadith,
                                                         maxCharacters: budget.sourceCharacters + 100) else { continue }
            pool.add(source, lane: .hadithTopics, rank: entry.rank)
        }
        #endif
        #if HAS_QURAN
        for (rank, ref) in (await topicAyahs).enumerated() {
            if let source = AskAISourceFactory.ayah(surah: ref.surah, ayah: ref.ayah, quranData: quranData,
                                                    maxCharacters: budget.sourceCharacters) {
                pool.add(source, lane: .quranTopics, rank: rank)
            }
        }
        #endif
        for (rank, hit) in (await articleHits).enumerated() {
            // A how-to wants the article's steps, whichever section scored the words, and the
            // steps get a subject's room: they ARE the answer. Otherwise a section whose HEADING
            // carries a question word ("What breaks wudhu") beats the section that merely scored.
            let steps = question.intent == .howTo ? stepSection(of: hit.article) : nil
            let headed = steps == nil ? headingSection(of: hit.article, for: question) : nil
            pool.add(AskAISourceFactory.article(hit.article, section: steps ?? headed ?? hit.section,
                                                maxCharacters: steps != nil ? budget.subjectCharacters : budget.sourceCharacters + 200),
                     lane: .articles, rank: rank)
        }
        // A follow-up about an article the previous answer used ("how much is it?" after zakat):
        // the section of THAT article that answers the new words, which a fresh search across all
        // the articles scores too low to surface.
        if question.isFollowUp {
            // The ARTICLES the previous answer cited (not its first three sources of any kind, which
            // skipped the zakat guide behind two hadiths and a verse).
            let citedArticles = carriedCited.filter { if case .article = $0.kind { return true } else { return false } }
            for source in citedArticles.prefix(3) {
                guard case .article(let id, let heading) = source.kind,
                      let article = IslamArticles.all.first(where: { $0.id == id }) else { continue }
                for (rank, hit) in bestSections(of: article, for: question, excludingHeading: heading, limit: 2).enumerated() {
                    // A section whose heading answers the question's shape ("3. Calculate 2.5%" for
                    // "how much") is the answer: it must not be cut by a near-namesake guide.
                    let boost = hit.headingAnswersShape ? 1.2 : (rank == 0 ? 0.4 : 0.2)
                    pool.add(AskAISourceFactory.article(article, section: hit.section, maxCharacters: budget.sourceCharacters + 200),
                             lane: .articles, rank: rank, boost: boost)
                }
            }
        }
        if Task.isCancelled { return outcome }

        // Lanes with small, in-memory data.
        for (rank, source) in nameSources(for: question, limit: 2).enumerated() { pool.add(source, lane: .names, rank: rank) }
        if question.intent == .dua || question.contentWords.contains(where: { ["dua", "duas", "dhikr", "adhkar", "supplication"].contains($0) }) {
            // Hisn al-Muslim parses from its xz pack on first use: off the main actor.
            let hisn = HisnDuasStore.shared.libraryIfLoaded == nil
                ? await Task.detached(priority: .userInitiated) { HisnDuasStore.shared.loaded() }.value
                : HisnDuasStore.shared.libraryIfLoaded
            for (rank, source) in duaSources(for: question, limit: 4, hisn: hisn).enumerated() { pool.add(source, lane: .duas, rank: rank) }
        }
        if question.mentionsApp {
            for (rank, source) in settingSources(for: question, limit: 2).enumerated() { pool.add(source, lane: .settings, rank: rank) }
            #if HAS_TIPS
            for (rank, source) in tipSources(for: question, limit: 2).enumerated() { pool.add(source, lane: .tips, rank: rank) }
            #endif
        }
        #if HAS_ADHAN
        if question.intent != .prayerTimes, mentionsTodaysPrayer(question), let prayer = AskAISourceFactory.prayerTimes() {
            pool.add(prayer, lane: .prayer, rank: 0)
        }
        #endif
        _ = (semantic, engine, semanticQuery, nameOnly)

        outcome.laneCounts = pool.counts
        (outcome.sources, outcome.ranking) = pool.select(limit: budget.limit)
        // A long source is clipped around the sentence that matched, not from its opening; a
        // subject is the whole point of the question, so it keeps its opening.
        let focus = question.searchTerms
        outcome.sources = outcome.sources.map { source in
            guard !source.isSubject else { return source }
            var focused = source
            focused.focusTerms = focus
            return focused
        }
        outcome.elapsed = CFAbsoluteTimeGetCurrent() - started
        return outcome
    }

    // MARK: - Fusion

    private struct Pool {
        let weights: [Lane: Double]
        private var scores: [String: Double] = [:]
        private var sources: [String: AskAISource] = [:]
        private var order: [String] = []
        private(set) var counts: [Lane: Int] = [:]

        init(weights: [Lane: Double]) { self.weights = weights }

        mutating func add(_ source: AskAISource, lane: Lane, rank: Int, boost: Double = 0) {
            let weight = weights[lane] ?? 0
            guard weight > 0 else { return }
            counts[lane, default: 0] += 1
            let key = source.reference
            scores[key, default: 0] += weight / Double(2 + rank) + boost
            if var existing = sources[key] {
                // A source found by several lanes keeps its richest form and its marks.
                if source.isSubject { existing.isSubject = true }
                if source.wasQuotedBefore { existing.wasQuotedBefore = true }
                if source.maxCharacters > existing.maxCharacters { existing.maxCharacters = source.maxCharacters }
                sources[key] = existing
            } else {
                sources[key] = source
                order.append(key)
            }
        }

        /// Best first, subjects always leading, with a diversity cap: no family takes more than
        /// three fifths of the budget while another family still has candidates.
        func select(limit: Int) -> ([AskAISource], [(reference: String, score: Double)]) {
            let ranked = order.map { ($0, scores[$0] ?? 0) }
                .sorted { a, b in
                    let sa = sources[a.0]?.isSubject ?? false, sb = sources[b.0]?.isSubject ?? false
                    if sa != sb { return sa }
                    return a.1 > b.1
                }
            let cap = max(2, Int((Double(limit) * 0.6).rounded(.up)))
            var perFamily: [AskAISource.Family: Int] = [:]
            var chosen: [AskAISource] = []
            var skipped: [AskAISource] = []
            for (key, _) in ranked where chosen.count < limit {
                guard let source = sources[key] else { continue }
                if source.isSubject || (perFamily[source.family] ?? 0) < cap {
                    chosen.append(source)
                    perFamily[source.family, default: 0] += 1
                } else {
                    skipped.append(source)
                }
            }
            // Room left (the other families ran dry): the capped family's best fill it.
            for source in skipped where chosen.count < limit { chosen.append(source) }
            return (chosen, ranked.map { (reference: $0.0, score: $0.1) })
        }
    }

    // MARK: - Query shaping

    /// The meaning lanes score the mean over query words, so "what does the Quran say about"
    /// dilutes the topic: the semantic query is the content words with a few synonyms.
    private static func semanticQueryText(for question: AskAIQuestion) -> String {
        let terms = Array(question.searchTerms.prefix(question.contentWords.count + 3))
        return terms.isEmpty ? question.searchText : terms.joined(separator: " ")
    }

    /// The ranked keyword and article searches match words independently and score where they
    /// land, so they get the content words, their synonyms and the phrase hints, up to eight.
    private static func keywordQueryText(for question: AskAIQuestion) -> String {
        let terms = Array(question.searchTerms.prefix(8))
        return terms.isEmpty ? question.searchText : terms.joined(separator: " ")
    }

    /// Whether a non-clock question still names today's schedule ("did I miss asr", "how many
    /// rakahs is dhuhr" without a clock word): a named prayer with prayer-general words.
    private static func mentionsTodaysPrayer(_ question: AskAIQuestion) -> Bool {
        let words = Set(AskAILexicon.fold(question.raw).split(separator: " ").map(String.init))
        return !words.isDisjoint(with: AskAILexicon.prayerNames) && !words.isDisjoint(with: AskAILexicon.clockWords)
    }

    #if HAS_QURAN
    private static func waitUntilVerseIndexReady(_ quranData: QuranData, timeout: TimeInterval) async {
        let deadline = CFAbsoluteTimeGetCurrent() + timeout
        while !quranData.isVerseSearchReady, CFAbsoluteTimeGetCurrent() < deadline, !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
    }
    #endif

    // MARK: - Lane: what the question names

    private static let ayahReferenceRegex = try! NSRegularExpression(pattern: #"(?<![\d:])(\d{1,3})\s*:\s*(\d{1,3})(?![\d:])"#)
    /// "surah al-kahf", "Surat Yusuf", "chapter 18", "sura al baqarah" - the name (one or two words)
    /// or number after the word. Case-insensitive; apostrophes bind.
    private static let surahMentionRegex = try! NSRegularExpression(
        pattern: #"(?i)\b(?:surah|surat|soorah|sura|chapter)\s+([\p{L}'’\-]+|\d{1,3}\b)(?:\s+([\p{L}'’\-]+))?"#)
    private static let ayahMentionRegex = try! NSRegularExpression(pattern: #"(?i)\b(?:ayah|ayat|aya|verse)\s+(\d{1,3})\b"#)
    /// Household names for specific verses that no regex catches.
    private static let namedAyahs: [(names: [String], surah: Int, ayah: Int)] = [
        (["ayat al-kursi", "ayatul kursi", "ayat ul kursi", "ayat al kursi", "ayatul-kursi", "ayat alkursi", "ayatul-kursi",
          "throne verse", "verse of the throne"], 2, 255),
        (["verse of light", "ayat an-nur", "ayat al-nur", "ayat an nur", "light verse"], 24, 35),
        (["verse of the sword", "sword verse"], 9, 5),
        (["verse of debt", "debt verse", "longest verse"], 2, 282),
    ]

    /// Words that are also surah names but almost always mean the ordinary word ("light", "the
    /// cow" never come up here, but "muhammad", "yusuf", "maryam" name people): a bare person's
    /// name adds the surah as SUPPORT, not as the subject, unless the question says "surah".
    private static let surahWordStop: Set<String> = [
        "the", "and", "for", "with", "from", "that", "this", "what", "when", "where", "which", "about", "does", "mean",
        "time", "light", "cow", "women", "table", "cattle", "spoils", "thunder", "bee", "cave", "poets", "ants", "spider",
        "smoke", "star", "moon", "iron", "pen", "jinn", "dawn", "sun", "night", "morning", "fig", "clot", "elephant",
        "quraysh", "people", "men", "man", "help", "rome", "story", "stories", "ranks", "friday", "mutual", "divorce",
        "prohibition", "kingdom", "reality", "ways", "resurrection", "human", "news", "overwhelming", "city", "town",
        "declaration", "clear", "evidence", "earthquake", "chargers", "calamity", "competition", "afternoon", "slanderer",
        "kindness", "abundance", "disbelievers", "victory", "flame", "sincerity", "daybreak", "mankind", "opening", "family",
        "repentance", "prophets", "believers", "criterion", "wise", "creator", "groups", "forgiver", "consultation",
        "ornaments", "crouching", "dunes", "chambers", "scatterer", "mount", "beneficent", "event", "gathering", "exile",
        "examined", "ranks", "hypocrites", "loss", "sovereignty", "ascending", "wrapped", "cloaked", "tidings", "frowned",
        "splitting", "cleaving", "sky", "traveller", "most", "high", "morning", "brightness", "relief", "consolation",
    ]

    private static func subjectSources(for question: AskAIQuestion, budget: Budget) async -> (subjects: [AskAISource], support: [AskAISource]) {
        var out: [AskAISource] = []
        var support: [AskAISource] = []
        var seen = Set<String>()
        // A time of day ("I prayed isha at 11:30") is not Hud 11:30: the times are blanked first.
        let text = AskAILexicon.maskingClockTimes(question.raw)
        #if HAS_QURAN
        let quranData = QuranData.shared
        let ns = text as NSString
        let whole = NSRange(location: 0, length: ns.length)
        var ayahs: [(surah: Int, ayah: Int)] = []
        var surahs: [(id: Int, subject: Bool)] = []

        for match in ayahReferenceRegex.matches(in: text, range: whole) {
            guard let surahID = Int(ns.substring(with: match.range(at: 1))),
                  let ayahID = Int(ns.substring(with: match.range(at: 2))),
                  quranData.ayah(surah: surahID, ayah: ayahID) != nil else { continue }
            ayahs.append((surahID, ayahID))
        }
        let lowered = AskAILexicon.fold(text)
        for named in namedAyahs where named.names.contains(where: { lowered.contains(AskAILexicon.fold($0)) }) {
            ayahs.append((named.surah, named.ayah))
        }
        for match in surahMentionRegex.matches(in: text, range: whole) {
            let first = ns.substring(with: match.range(at: 1))
            let second = match.range(at: 2).location != NSNotFound ? ns.substring(with: match.range(at: 2)) : nil
            var resolved: Surah?
            if let second { resolved = quranData.resolveSurahIdentifier(first + " " + second) }
            if resolved == nil { resolved = quranData.resolveSurahIdentifier(first) }
            guard let surah = resolved else { continue }
            // "surah al-kahf ayah 10" names the ayah; "surah al-kahf" alone names the surah.
            if let ayahMatch = ayahMentionRegex.firstMatch(in: text, range: whole),
               let ayahID = Int(ns.substring(with: ayahMatch.range(at: 1))),
               quranData.ayah(surah: surah.id, ayah: ayahID) != nil {
                ayahs.append((surah.id, ayahID))
            } else {
                surahs.append((surah.id, true))
            }
        }
        // A surah named WITHOUT the word: "what is al-kahf about", "explain yaseen", "tell me about
        // yusuf". Only an exact spelling of one surah's name counts, never a substring; a person's
        // name adds the surah as support, so the prophet's own article can still lead.
        if surahs.isEmpty, !question.isArabic {
            let words = lowered.split(separator: " ").map(String.init)
            for (index, word) in words.enumerated() where word.count >= 3 && !surahWordStop.contains(word) && !AskAILexicon.stopWords.contains(word) {
                var candidates = [word]
                if index + 1 < words.count { candidates.insert(word + " " + words[index + 1], at: 0) }
                for candidate in candidates {
                    // Whole-key matches only: the looser tier read "wudu" as Ad-Duhaa.
                    let matches = SurahSpelling.matches(candidate, in: quranData.quran, wholeKeyOnly: true)
                    if matches.count == 1, let surah = matches.first {
                        let saysSurah = question.leansQuran
                        if !surahs.contains(where: { $0.id == surah.id }) { surahs.append((surah.id, saysSurah)) }
                        break
                    }
                }
                if !surahs.isEmpty { break }
            }
        }

        for (surahID, ayahID) in ayahs.prefix(2) {
            let reference = "\(surahID):\(ayahID)"
            guard seen.insert(reference).inserted,
                  let source = AskAISourceFactory.ayah(surah: surahID, ayah: ayahID, quranData: quranData,
                                                       isSubject: true, maxCharacters: budget.sourceCharacters + 200) else { continue }
            out.append(source)
            if let tafsir = AskAISourceFactory.tafsir(surah: surahID, ayah: ayahID, quranData: quranData,
                                                      maxCharacters: budget.subjectCharacters) {
                out.append(tafsir)
            }
        }
        for entry in surahs.prefix(1) {
            if let source = AskAISourceFactory.surah(entry.id, quranData: quranData, isSubject: entry.subject,
                                                     maxCharacters: entry.subject ? budget.subjectCharacters : budget.sourceCharacters + 300),
               seen.insert(source.reference).inserted {
                if entry.subject { out.append(source) } else { support.append(source) }
            }
        }
        #endif

        #if HAS_HADITH
        // A hadith by number: "bukhari 6114", "sahih muslim 8a", "nawawi 40 hadith 1".
        if let reference = HadithReferenceParser.parse(text), let data = HadithStore.shared.book(reference.book) {
            let hadith: HadithBookData.Hadith? = reference.chapter.map { data.hadith(chapterPosition: $0, position: reference.hadith) }
                ?? data.hadith(referenced: reference.hadith, suffix: reference.suffix, introduction: reference.introduction)
            if let hadith { await prewarmHadithText([(data, hadith.row)]) }
            if let hadith, let source = AskAISourceFactory.hadith(book: reference.book, data: data, hadith: hadith,
                                                                  maxCharacters: budget.subjectCharacters, isSubject: true),
               seen.insert(source.reference).inserted {
                out.append(source)
            }
        }
        #endif

        // A Name of Allah spelled as the app spells it ("al-wadud", "ar-rahman"): the subject. The
        // looser spelling fold stays for the names LANE; as a subject it read "al-fatiha" as Al-Fattah.
        for name in typedNames(in: question).prefix(1) {
            let source = AskAISourceFactory.name(name, isSubject: true)
            if seen.insert(source.reference).inserted { out.append(source) }
        }
        return (out, support)
    }

    private static let nameArticles: Set<String> = ["al", "ar", "as", "an", "ad", "at", "ash", "az", "adh", "ath"]
    /// Words that say the question is about a Name: "the name salam", "asma ul husna".
    private static let nameCues: Set<String> = ["name", "names", "asma", "husna", "attribute", "attributes"]

    /// Names whose transliteration (article dropped) is a word of the question, exactly as folded,
    /// AND written the way a Name is meant: with its article ("as-salam", "al wali", "assalam") or
    /// beside a Names cue ("what does the name wali mean"). Bare, the word is usually the ordinary
    /// one: "how should I reply to salam" made As-Salam the subject and skipped every hadith lane,
    /// "what is a wali" was told to explain a Name (salam, mumin, malik, wali, haqq, karim).
    private static func typedNames(in question: AskAIQuestion) -> [NameOfAllah] {
        let names = NamesViewModel.shared.namesOfAllah
        guard !names.isEmpty, !question.isArabic else { return [] }
        let folded = AskAILexicon.fold(question.raw)
        let allWords = folded.split(separator: " ").map(String.init)
        let words = Set(allWords.filter { $0.count >= 4 })
        guard !words.isEmpty else { return [] }
        let cued = !Set(allWords).isDisjoint(with: nameCues)
        let padded = " " + folded + " "
        return names.filter { name in
            var parts = AskAILexicon.fold(name.transliteration).split(separator: " ").map(String.init)
            var article: String?
            if let first = parts.first, nameArticles.contains(first) { article = first; parts.removeFirst() }
            let key = parts.joined(separator: " ")
            guard key.count >= 4, words.contains(key) else { return false }
            if cued { return true }
            guard let article else { return false }
            return padded.contains(" \(article) \(key) ") || padded.contains(" \(article)\(key) ")
        }
    }

    // MARK: - Warm-up

    /// Readies the indexes a first question needs (the verse index, the Quran vectors, the hadith
    /// vectors from disk), so the first answer does not also pay for them. The chat calls this on
    /// appear; every step no-ops once done.
    static func prewarm() {
        Task { @MainActor in
            #if HAS_QURAN
            let quranData = QuranData.shared
            await quranData.waitUntilCoreLoaded()
            quranData.ensureVerseSearchIndex(priority: .utility)
            #endif
            guard SemanticSearchEngine.isSupported else { return }
            let engine = SemanticSearchEngine.shared
            #if HAS_QURAN
            QuranSemanticCorpus.prepare(quranData: quranData, engine: engine)
            #endif
            #if HAS_HADITH
            _ = await HadithSemanticCorpus.probeDisk(engine: engine)
            #endif
            _ = engine
        }
    }

    /// The section of a how-to article that carries its steps, if it has one.
    private static func stepSection(of article: IslamArticle) -> IslamArticle.Section? {
        article.sections.first { section in
            let heading = AskAILexicon.fold(section.heading)
            return heading.contains("step") || heading.hasPrefix("how to") || heading.contains("the way")
        }
    }

    /// Headings that name no subject ("Summary", "Overview", "In summary").
    private static let genericHeadings: Set<String> = ["summary", "overview", "in summary", "introduction", "conclusion", "sources", "see also"]

    /// A section whose heading carries one of the question's own words or hints ("What breaks
    /// wudhu" for "what breaks wudu"), or nil.
    private static func headingSection(of article: IslamArticle, for question: AskAIQuestion) -> IslamArticle.Section? {
        let terms = question.searchTerms.filter { $0.count >= 4 }
        guard !terms.isEmpty else { return nil }
        var best: (IslamArticle.Section, Int)?
        for section in article.sections {
            let heading = AskAILexicon.fold(section.heading)
            guard !heading.isEmpty, !genericHeadings.contains(heading) else { continue }
            let hits = terms.filter { heading.contains($0) }.count
            if hits > 0, hits > (best?.1 ?? 0) { best = (section, hits) }
        }
        return best?.0
    }

    /// The sections of `article` that best match the question's search terms, other than the one
    /// already carried, best first; empty when no section carries any of them.
    private static func bestSections(of article: IslamArticle, for question: AskAIQuestion, excludingHeading: String,
                                     limit: Int) -> [(section: IslamArticle.Section, headingAnswersShape: Bool)] {
        let terms = question.searchTerms.filter { $0.count >= 3 }
        guard !terms.isEmpty else { return [] }
        let hints = Set(question.hintTerms)
        var scored: [(IslamArticle.Section, Int, Bool)] = []
        for section in article.sections where section.heading != excludingHeading {
            var score = 0
            var headingHint = false
            let heading = AskAILexicon.fold(section.heading)
            guard !genericHeadings.contains(heading) else { continue }
            for term in terms {
                // A heading that answers the question's SHAPE ("3. Calculate 2.5%" for "how much")
                // outranks a section that merely repeats the topic word many times.
                if heading.contains(term) {
                    if hints.contains(term) { score += 10; headingHint = true } else { score += 4 }
                }
                score += min(hints.contains(term) ? 3 : 2, section.folded.components(separatedBy: term).count - 1)
            }
            if score > 0 { scored.append((section, score, headingHint)) }
        }
        return scored.sorted { $0.1 > $1.1 }.prefix(limit).map { (section: $0.0, headingAnswersShape: $0.2) }
    }

    // MARK: - Lane: hadith, ranked over the major collections

    #if HAS_HADITH

    /// The books the ranked hadith lane scores, most authoritative first.
    private static let keywordBookOrder = ["bukhari", "muslim", "nawawi40", "riyad_assalihin", "tirmidhi", "abudawud", "nasai", "ibnmajah"]

    nonisolated private static func rankHadiths(query: String, books: [(HadithCatalogBook, HadithBookData)], limit: Int) -> [(bookIndex: Int, row: Int)] {
        guard !books.isEmpty else { return [] }
        HadithVocabulary.shared.buildIfNeeded(books: books.map(\.1))
        guard !Task.isCancelled, let parsed = HadithRankedSearch.parse(query, vocabulary: HadithVocabulary.shared) else { return [] }
        struct Scored { let bookIndex: Int; let row: Int; let score: Int }
        var strictHits: [Scored] = []
        var relaxedHits: [Scored] = []
        let tokenCount = parsed.tokens.count
        for (index, entry) in books.enumerated() {
            if Task.isCancelled { break }
            for hit in HadithRankedSearch.rank(book: entry.0, data: entry.1, query: parsed) {
                if hit.matched == tokenCount {
                    strictHits.append(Scored(bookIndex: index, row: hit.row, score: hit.score))
                } else if tokenCount > 1 {
                    relaxedHits.append(Scored(bookIndex: index, row: hit.row, score: hit.score + HadithRankedSearch.relaxedBonus(matched: hit.matched)))
                }
            }
        }
        let chosen = strictHits.isEmpty ? relaxedHits : strictHits
        let top = chosen.sorted { a, b in
            if a.score != b.score { return a.score > b.score }
            if a.bookIndex != b.bookIndex { return a.bookIndex < b.bookIndex }
            return a.row < b.row
        }.prefix(limit).map { (bookIndex: $0.bookIndex, row: $0.row) }
        // The winners' text blocks inflated here, off the main actor, so the sources the main actor
        // then builds from them read the cache instead of decompressing a block each.
        for hit in top where !Task.isCancelled { books[hit.bookIndex].1.prewarmText(rows: hit.row..<(hit.row + 1)) }
        return top
    }

    /// Inflates the text blocks behind these hadiths off the main actor (about 130 ms a block on
    /// the simulator, several times that on an older phone), so building their sources afterwards,
    /// on the main actor, reads the cache ("HADITH BLOCK ... MAIN" no longer fires for Ask AI).
    private static func prewarmHadithText(_ items: [(HadithBookData, Int)]) async {
        let cold = items.filter { $0.1 >= 0 && !$0.0.hasText(rows: $0.1..<($0.1 + 1)) }
        guard !cold.isEmpty else { return }
        await withTaskGroup(of: Void.self) { group in
            for (data, row) in cold {
                group.addTask(priority: .userInitiated) { data.prewarmText(rows: row..<(row + 1)) }
            }
        }
    }

    // MARK: - Lane: curated hadith topics

    nonisolated private static func topicHadiths(words: [String], limit: Int) -> [HadithTopicEntry] {
        let terms = words.filter { $0.count >= 4 }
        guard !terms.isEmpty else { return [] }
        var scored: [(HadithTopicEntry, Int)] = []
        for entry in HadithTopicsStore.shared.entries {
            let haystack = AskAILexicon.fold(entry.title + " " + entry.topic + " " + entry.tags.joined(separator: " "))
            var score = 0
            for term in terms where haystack.contains(term) {
                score += entry.tags.contains(where: { AskAILexicon.fold($0) == term }) ? 3 : 2
                if AskAILexicon.fold(entry.topic).contains(term) { score += 2 }
            }
            if score > 0 { scored.append((entry, score)) }
        }
        return scored.sorted { a, b in a.1 != b.1 ? a.1 > b.1 : a.0.rank < b.0.rank }.prefix(limit).map(\.0)
    }

    #endif

    // MARK: - Lane: Quran topics and passage themes

    #if HAS_QURAN

    nonisolated private static func topicAyahs(terms: [String], limit: Int) -> [(surah: Int, ayah: Int)] {
        var out: [(surah: Int, ayah: Int)] = []
        var seen = Set<String>()
        func parse(_ key: String) -> (Int, Int)? {
            let parts = key.split(separator: ":")
            guard parts.count == 2, let s = Int(parts[0]), let a = Int(parts[1]) else { return nil }
            return (s, a)
        }
        for term in terms.prefix(4) where term.count >= 4 {
            for topic in QuranTopicsStore.shared.search(term, limit: 2) {
                for key in topic.ayahs.prefix(3) where seen.insert(key).inserted {
                    if let ref = parse(key) { out.append((ref.0, ref.1)) }
                    if out.count >= limit { return out }
                }
            }
            for theme in AyahThemesStore.shared.search(term, limit: 2) {
                let key = "\(theme.surah):\(theme.start)"
                if seen.insert(key).inserted { out.append((theme.surah, theme.start)) }
                if out.count >= limit { return out }
            }
        }
        return out
    }

    #endif

    // MARK: - Lane: the Names of Allah

    /// Names the question spells out ("al-wadud", "ar rahman", "Al-Karim") as exact folded matches.
    private static func exactNames(in question: AskAIQuestion) -> [NameOfAllah] {
        let names = NamesViewModel.shared.namesOfAllah
        guard !names.isEmpty, !question.isArabic else { return [] }
        let lowered = AskAILexicon.fold(question.raw)
        let words = lowered.split(separator: " ").map(String.init)
        var out: [NameOfAllah] = []
        for (index, word) in words.enumerated() {
            // The article is optional and spelled many ways: "al", "ar", "as", "an"... A bare name
            // counts only when it is not an ordinary English word ("the light" vs "an-Nur").
            let isArticle = AskAILexicon.stopWords.contains(word) || ["al", "ar", "as", "an", "ad", "at", "ash", "az", "adh", "ath"].contains(word)
            guard !isArticle, word.count >= 4 else { continue }
            let candidates = index > 0 ? [words[index - 1] + " " + word, word] : [word]
            for candidate in candidates {
                let hits = SpellingFold.matches(candidate, in: names) { $0.spelling }
                    .filter { name in
                        // Exact whole-key matches only: "rahman" finds Ar-Rahman, "rah" finds nothing.
                        guard let query = SpellingFold.Query(candidate) else { return false }
                        let strength = SpellingFold.strength(of: query, in: name.spelling)
                        return strength == .keyExact || strength == .skeletonExact
                    }
                if hits.count == 1, let name = hits.first, !out.contains(name) {
                    out.append(name)
                    break
                }
            }
        }
        return out
    }

    private static func nameSources(for question: AskAIQuestion, limit: Int) -> [AskAISource] {
        let lowered = AskAILexicon.fold(question.raw)
        let asksNames = lowered.contains("name") || lowered.contains("asma")
        var out: [AskAISource] = []
        for name in exactNames(in: question).prefix(limit) { out.append(AskAISourceFactory.name(name)) }
        guard asksNames, out.count < limit else { return out }
        // "which name of Allah means the most loving": the meaning matched against the content words.
        for name in NamesViewModel.shared.namesOfAllah where out.count < limit {
            let meaning = AskAILexicon.fold(name.meaning + " " + name.otherNames.joined(separator: " "))
            let hits = question.contentWords.filter { $0.count >= 4 && !["name", "names", "allah", "means", "meaning"].contains($0) && meaning.contains($0) }
            if !hits.isEmpty, !out.contains(where: { $0.reference == name.transliteration }) {
                out.append(AskAISourceFactory.name(name))
            }
        }
        return out
    }

    // MARK: - Lane: duas

    /// The dua catalogues folded once, keyed by the text they were folded from: every question
    /// re-folded all ~900 entries on the main actor (about 60 ms on a Mac). The app's collections
    /// fill in their referenced duas once after launch, which changes the key and refolds them.
    private struct FoldedDuaIndex {
        var key = -1
        var duas: [(collection: Int, item: Int, title: String, blob: String)] = []
        var hisnKey = -1
        var hisn: [(entry: Int, category: String, head: String, body: String)] = []
    }
    private static var foldedDuas = FoldedDuaIndex()

    private static func duaSources(for question: AskAIQuestion, limit: Int, hisn: HisnDuasStore.Library?) -> [AskAISource] {
        let terms = question.searchTerms.filter { $0.count >= 3 && !["dua", "duas", "dhikr", "adhkar", "supplication", "say", "recite"].contains($0) }
        guard !terms.isEmpty else { return [] }
        var scored: [(AskAISource, Int)] = []
        let library = DuaLibrary.shared
        library.load()
        let collections = library.collections
        let key = collections.reduce(0) { $0 + $1.items.reduce(0) { $0 + $1.searchBlob.utf8.count } }
        if key != foldedDuas.key {
            var folded: [(collection: Int, item: Int, title: String, blob: String)] = []
            for (c, collection) in collections.enumerated() {
                let title = AskAILexicon.fold(collection.title + " " + collection.subtitle)
                for (i, item) in collection.items.enumerated() {
                    folded.append((c, i, title, AskAILexicon.fold(item.searchBlob)))
                }
            }
            foldedDuas.duas = folded
            foldedDuas.key = key
        }
        for entry in foldedDuas.duas {
            var score = 0
            for term in terms {
                if entry.title.contains(term) { score += 3 }
                if entry.blob.contains(term) { score += 1 }
            }
            guard score > 0 else { continue }
            let collection = collections[entry.collection]
            if let source = AskAISourceFactory.dua(collection.items[entry.item], collection: collection) { scored.append((source, score)) }
        }
        if let hisn {
            if hisn.entries.count != foldedDuas.hisnKey {
                let categoryLabel = Dictionary(hisn.categories.map { ($0.id, $0.label) }, uniquingKeysWith: { first, _ in first })
                foldedDuas.hisn = hisn.entries.enumerated().map { index, entry in
                    let category = categoryLabel[entry.categoryID] ?? ""
                    return (index, category, AskAILexicon.fold(entry.title + " " + category), AskAILexicon.fold(entry.translation))
                }
                foldedDuas.hisnKey = hisn.entries.count
            }
            for entry in foldedDuas.hisn {
                var score = 0
                for term in terms {
                    if entry.head.contains(term) { score += 3 }
                    if entry.body.contains(term) { score += 1 }
                }
                if score > 0, let source = AskAISourceFactory.hisn(hisn.entries[entry.entry], category: entry.category) { scored.append((source, score)) }
            }
        }
        return scored.sorted { $0.1 > $1.1 }.prefix(limit).map(\.0)
    }

    // MARK: - Lane: the settings index (where a setting lives)

    private static func settingSources(for question: AskAIQuestion, limit: Int) -> [AskAISource] {
        let terms = question.searchTerms.filter { $0.count >= 3 && !["app", "setting", "settings", "change", "turn", "use", "find", "open"].contains($0) }
        guard !terms.isEmpty else { return [] }
        var scored: [(SettingsSearchEntry, Int)] = []
        for entry in SettingsSearchEntry.all {
            let title = AskAILexicon.fold(entry.title)
            let path = AskAILexicon.fold(entry.path)
            let keywords = AskAILexicon.fold(entry.keywords)
            var score = 0
            for term in terms {
                if title.contains(term) { score += 4 }
                if path.contains(term) { score += 2 }
                if keywords.contains(term) { score += 1 }
            }
            if score > 0 { scored.append((entry, score)) }
        }
        return scored.sorted { $0.1 > $1.1 }.prefix(limit).map { AskAISourceFactory.setting($0.0) }
    }

    // MARK: - Lane: Tips & Tricks (how to use this app)

    #if HAS_TIPS

    private static func tipSources(for question: AskAIQuestion, limit: Int) -> [AskAISource] {
        let terms = question.contentWords.filter { $0.count >= 3 && !["app", "setting", "settings", "change", "turn", "use"].contains($0) }
        guard !terms.isEmpty else { return [] }
        var scored: [(AppTip, Int)] = []
        for tip in TipCatalog.all where tip.isAvailable() {
            let title = AskAILexicon.fold(tip.title + " " + tip.group)
            let body = AskAILexicon.fold(tip.detail + " " + tip.place)
            var score = 0
            for term in terms {
                if title.contains(term) { score += 3 }
                if body.contains(term) { score += 1 }
            }
            if score > 0 { scored.append((tip, score)) }
        }
        return scored.sorted { $0.1 > $1.1 }.prefix(limit).map { AskAISourceFactory.tip($0.0) }
    }
    #endif
}

#endif
