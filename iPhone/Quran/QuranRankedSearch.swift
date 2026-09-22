import Foundation

// Ranked, forgiving ayah search: the "top results" lane of the Quran tab's keyword search.
//
// The mushaf-ordered substring scan (`VerseSearchSnapshot.search`) is exhaustive and exact, and that
// is also its limit: "controlling anger" finds nothing unless those two words sit together, "praying"
// never reaches "prayer", a typo returns an empty list, and "alhamdulillah" typed in Latin letters
// reaches no Arabic at all. This engine matches the words of a query INDEPENDENTLY, in three tiers
// ranked below each other so recall never costs precision:
//
//   1. the words as typed (a whole-word hit beats a substring hit)
//   2. stemmed and spell-corrected forms ("praying" -> "pray", "رحمته" -> "رحمة", "mercyful" -> "merciful")
//   3. the consonant skeleton, a poor man's root search for Arabic ("صبر" -> "الصابرين") and a
//      transliteration match for Latin ("rabbana" -> "ربنا")
//
// Every ayah is then scored on where its words landed, how much of the query it covers, how short it
// is and how early the match sits, and the list is the ayahs carrying the WHOLE query - or, when none
// does, the ones carrying the most of it (`relaxed`), rather than an empty screen.
//
// Ported from the Tilawa app's quranSearchEngine.ts and translit.ts (Jamil Hammoudeh), with
// permission. The corpus lanes are derived from the app's own `VerseIndexEntry` folds, so a query is
// folded by the same `Settings.cleanSearch` rules the index was built with.

enum QuranRankedSearch {
    struct Correction: Hashable {
        let from: String
        let to: String
    }

    struct Outcome {
        var hits: [VerseIndexEntry] = []
        /// Matches found before `limit` cut the list.
        var total = 0
        /// Typos searched for instead, so the screen can say so.
        var corrections: [Correction] = []
        /// True when nothing carried the whole query and partial hits are shown.
        var relaxed = false
        /// Every form the engine matched on (typed, stemmed, corrected), for the result rows' highlight.
        var highlightQuery = ""

        var isEmpty: Bool { hits.isEmpty }
    }

    // MARK: - Scoring constants (only meaningful relative to each other)

    private static let arabicWeight = 14
    private static let englishWeight = 10
    private static let transliterationWeight = 5
    private static let wholeWordBonus = 8
    private static let phraseBonus = 45
    private static let wholePhraseBonus = 20
    private static let stemPenalty = 3
    private static let fuzzyPenalty = 6
    private static let skeletonPenalty = 7
    private static let skeletonWholeWordBonus = 25
    private static let coverageWeight = 34
    private static let brevityWeight = 12
    private static let brevityWordsPerPoint = 4
    private static let positionWeight = 8
    private static let positionCharsPerPoint = 25

    private static let fuzzyMinLength = 4
    private static let fuzzyLongWord = 7
    private static let minSkeletonLength = 4
    private static let minArabicSkeleton = 3
    private static let longRomanisedWord = 6

    // MARK: - Corpus lanes

    /// The per-ayah folds the scorer reads, derived once per index build and shared by every query.
    /// Stored as UTF-8 bytes and searched with `memmem`: the same tests on Swift strings cost over a
    /// second per query on the simulator (`String.contains` is a Unicode-aware search, and a query
    /// runs it up to eight times per ayah over 6,236 of them).
    private final class Lanes {
        let key: String
        /// Space-padded folds, so a whole-word test is a plain search for " word ".
        let english: [[UInt8]]
        let arabic: [[UInt8]]
        let arabicStems: [[UInt8]]
        /// Consonant skeletons of the Arabic, word breaks kept (precision) and removed (recall).
        let skeletonWords: [[UInt8]]
        let skeletonTight: [[UInt8]]
        let wordCounts: [Int]
        /// Every Latin word the translations use, for spelling correction: the set for membership,
        /// the space-joined blob (bytes) for the substring test, the words by length (bytes) for the
        /// edit-distance walk, which used to allocate a `[Character]` per candidate.
        let vocabulary: Set<String>
        let vocabularyBlob: [UInt8]
        let vocabularyByLength: [Int: [VocabularyWord]]

        init(snapshot: QuranData.VerseSearchSnapshot) {
            key = Self.key(for: snapshot)
            let entries = snapshot.verseIndex
            var english: [[UInt8]] = []
            var arabic: [[UInt8]] = []
            var arabicStems: [[UInt8]] = []
            var skeletonWords: [[UInt8]] = []
            var skeletonTight: [[UInt8]] = []
            var wordCounts: [Int] = []
            english.reserveCapacity(entries.count)
            arabic.reserveCapacity(entries.count)
            arabicStems.reserveCapacity(entries.count)
            skeletonWords.reserveCapacity(entries.count)
            skeletonTight.reserveCapacity(entries.count)
            wordCounts.reserveCapacity(entries.count)
            var words = Set<String>()
            for entry in entries {
                english.append(Array((" " + entry.englishBlob + " ").utf8))
                arabic.append(Array((" " + entry.arabicBlob + " ").utf8))
                // The clean Arabic (the second of the blob's folds) is the one the skeletons and stems
                // are taken from: one copy of the text, no diacritics, no duplicated lanes.
                let cleanTokens = Self.cleanArabicTokens(entry, snapshot: snapshot)
                arabicStems.append(Array((" " + cleanTokens.map(stemArabic).joined(separator: " ") + " ").utf8))
                let skeletons = cleanTokens.map(arabicSkeleton).filter { !$0.isEmpty }
                skeletonWords.append(Array((" " + skeletons.joined(separator: " ") + " ").utf8))
                skeletonTight.append(Array(collapseSkeleton(skeletons.joined()).utf8))
                wordCounts.append(max(1, cleanTokens.count))
                for word in entry.englishTokens where word.count >= fuzzyMinLength && Self.isLatinWord(word) {
                    words.insert(word)
                }
            }
            self.english = english
            self.arabic = arabic
            self.arabicStems = arabicStems
            self.skeletonWords = skeletonWords
            self.skeletonTight = skeletonTight
            self.wordCounts = wordCounts
            vocabulary = words
            vocabularyBlob = Array((" " + words.joined(separator: " ") + " ").utf8)
            var byLength: [Int: [VocabularyWord]] = [:]
            for word in words { byLength[word.utf8.count, default: []].append(VocabularyWord(Array(word.utf8))) }
            vocabularyByLength = byLength
        }

        static func key(for snapshot: QuranData.VerseSearchSnapshot) -> String {
            "\(snapshot.qiraahKey)|\(snapshot.verseIndex.count)|\(snapshot.verseIndex.first?.arabicBlob.hashValue ?? 0)"
        }

        private static func cleanArabicTokens(_ entry: VerseIndexEntry, snapshot: QuranData.VerseSearchSnapshot) -> [String] {
            let si = Int(entry.surahOffset), ai = Int(entry.ayahOffset)
            guard snapshot.surahs.indices.contains(si), snapshot.surahs[si].ayahs.indices.contains(ai) else {
                return entry.arabicTokens
            }
            let surah = snapshot.surahs[si]
            let clean = surah.ayahs[ai].textCleanArabic(for: snapshot.displayQiraah, surahID: surah.id)
            return Settings.shared.cleanSearch(clean, whitespace: true)
                .split(separator: " ").map(String.init).filter { !$0.isEmpty }
        }

        static func isLatinWord(_ word: String) -> Bool {
            word.unicodeScalars.allSatisfy { (97...122).contains($0.value) }
        }
    }

    private static let lanesLock = NSLock()
    private static var cachedLanes: Lanes?
    /// The key being built right now, so a second query in flight waits for it instead of building
    /// a copy of its own (the old cache released the lock during the build).
    private static var lanesBuildingKey: String?
    private static let lanesBuilt = DispatchGroup()

    /// The lanes for `snapshot`, built here when nobody has (tens of milliseconds on the simulator,
    /// once per index build) with the build time, so the query that paid for it can say so.
    private static func lanes(for snapshot: QuranData.VerseSearchSnapshot) -> (lanes: Lanes, buildMs: Double) {
        let key = Lanes.key(for: snapshot)
        while true {
            lanesLock.lock()
            if let cached = cachedLanes, cached.key == key {
                lanesLock.unlock()
                return (cached, 0)
            }
            if lanesBuildingKey == key {
                lanesLock.unlock()
                lanesBuilt.wait()
                continue
            }
            lanesBuildingKey = key
            lanesBuilt.enter()
            lanesLock.unlock()
            break
        }
        let started = DispatchTime.now().uptimeNanoseconds
        let built = Lanes(snapshot: snapshot)
        let ms = Double(DispatchTime.now().uptimeNanoseconds - started) / 1_000_000
        lanesLock.lock()
        cachedLanes = built
        lanesBuildingKey = nil
        lanesLock.unlock()
        QuranData.adoptTranslationVocabulary(built.vocabulary)
        lanesBuilt.leave()
        return (built, ms)
    }

    /// Builds the lanes ahead of the first ranked query, off the main thread: the post-reveal
    /// schedule does it on the full tier, the search field's focus on the reduced one (Tilawa
    /// Guide, Phase 4 step 2). A no-op once they are cached.
    static func prewarmLanes(snapshot: QuranData.VerseSearchSnapshot) {
        let (_, ms) = lanes(for: snapshot)
        #if DEBUG
        if RenderCounter.enabled, ms > 0 { NSLog("RANKED quran lanes prebuilt %.1f ms", ms) }
        #endif
    }

    // MARK: - Query parsing

    private struct Token {
        let text: String
        /// Affix-stripped forms, longest first. Empty when the word is its own stem.
        let stems: [String]
        /// The corpus word this one was probably a misspelling of.
        let fuzzy: String?
        /// Consonant skeleton, or nil when it is too short to mean anything.
        let skeleton: String?
        /// The same skeleton ungated, for joining a multi-word query into one run.
        let rawSkeleton: String
        // The same forms as bytes, bare and space-padded, for the lanes.
        let textBytes: [UInt8]
        let textPadded: [UInt8]
        let stemBytes: [[UInt8]]
        let fuzzyBytes: [UInt8]?
        let fuzzyPadded: [UInt8]?
        let skeletonBytes: [UInt8]?
        let skeletonPadded: [UInt8]?

        init(text: String, stems: [String], fuzzy: String?, skeleton: String?, rawSkeleton: String) {
            self.text = text
            self.stems = stems
            self.fuzzy = fuzzy
            self.skeleton = skeleton
            self.rawSkeleton = rawSkeleton
            textBytes = Array(text.utf8)
            textPadded = Array(" \(text) ".utf8)
            stemBytes = stems.map { Array($0.utf8) }
            fuzzyBytes = fuzzy.map { Array($0.utf8) }
            fuzzyPadded = fuzzy.map { Array(" \($0) ".utf8) }
            skeletonBytes = skeleton.map { Array($0.utf8) }
            skeletonPadded = skeleton.map { Array(" \($0) ".utf8) }
        }
    }

    private struct Query {
        let isArabic: Bool
        let phrase: String
        let required: [String]
        let tokens: [Token]
        let corrections: [Correction]
        let terms: [String]
        let phraseBytes: [UInt8]
        let phrasePadded: [UInt8]
        let requiredBytes: [[UInt8]]
        /// The tokens' skeletons as one run (adjacency is the precision story for a multi-word query).
        let joinedSkeleton: [UInt8]

        init(isArabic: Bool, phrase: String, required: [String], tokens: [Token], corrections: [Correction], terms: [String]) {
            self.isArabic = isArabic
            self.phrase = phrase
            self.required = required
            self.tokens = tokens
            self.corrections = corrections
            self.terms = terms
            phraseBytes = Array(phrase.utf8)
            phrasePadded = Array(" \(phrase) ".utf8)
            requiredBytes = required.map { Array($0.utf8) }
            joinedSkeleton = Array(collapseSkeleton(tokens.map(\.rawSkeleton).joined()).utf8)
        }
    }

    private static let englishStopwords: Set<String> = [
        "a", "an", "and", "are", "as", "at", "be", "but", "by", "for", "from", "had", "has", "have", "he",
        "her", "him", "his", "in", "is", "it", "its", "not", "of", "on", "or", "our", "that", "the",
        "their", "them", "then", "there", "they", "this", "to", "was", "we", "were", "what", "when",
        "which", "who", "will", "with", "you", "your",
    ]

    private static let arabicStopwords: Set<String> = {
        let source = ["من", "في", "على", "إلى", "أن", "ما", "لا", "ولا", "هو", "هي", "ذلك", "الذي", "التي",
                      "وما", "بما", "لما", "قد", "ثم", "إذا", "إنه", "له", "لهم", "عن", "كل"]
        return Set(source.map { Settings.shared.cleanSearch($0, whitespace: true) }.filter { !$0.isEmpty })
    }()

    private static let englishSuffixes = ["ings", "ing", "edly", "ness", "ies", "ed", "es", "ly", "s"]

    private static func stemEnglish(_ token: String) -> String? {
        guard token.count >= 5, Lanes.isLatinWord(token) else { return nil }
        for suffix in englishSuffixes where token.hasSuffix(suffix) && token.count - suffix.count >= 4 {
            let stem = String(token.dropLast(suffix.count))
            // The doubled consonant of "controlling"/"stopped" comes off with the suffix
            // (the hadith lane's rule, shared so both lanes stem alike).
            return suffix == "ies" ? stem + "y" : undoubled(stem)
        }
        return nil
    }

    /// The consonant English doubles before -ing/-ed comes off again, so the stem is a prefix of the
    /// word's other forms: "controlling" and "controls" both reach "control", "stopped" reaches "stop".
    /// A short stem keeps its double ("falling" stays "fall", "passed" stays "pass"), and s/z never
    /// collapse: the doubled letter there is the word itself ("bless", "buzz"). Lives here, in a file
    /// both targets compile, for the hadith lane too.
    static func undoubled(_ stem: String) -> String {
        let letters = Array(stem)
        guard letters.count >= 2, let last = letters.last, last == letters[letters.count - 2],
              "bdgmnprtl".contains(last) else { return stem }
        if last == "l" {
            // "controll", "compell", "travell" lose an l; "fall", "spell", "dwell" keep both.
            return letters.count >= 7 ? String(letters.dropLast()) : stem
        }
        return letters.count >= 4 ? String(letters.dropLast()) : stem
    }

    private static let arabicPrefixes = ["وال", "فال", "بال", "كال", "لل", "ال", "و", "ف", "ب", "ك", "ل", "س"]
    private static let arabicSuffixes = ["كما", "هما", "تما", "هم", "هن", "كم", "كن", "نا", "ها", "تم", "تن",
                                         "ون", "ين", "ان", "ات", "وا", "ه", "ي", "ك", "ا"]

    /// The light Arabic stemmer: clitics and inflectional endings stripped, each length-guarded so a
    /// short word is never eaten down to noise ("الله" keeps its ال; a one-letter affix needs four
    /// letters left over, so the ه of الله is not read as a pronoun).
    static func stemArabic(_ word: String) -> String {
        var stem = word
        for prefix in arabicPrefixes where stem.hasPrefix(prefix) {
            let floor = prefix.count == 1 ? 4 : 3
            if stem.count - prefix.count >= floor {
                stem = String(stem.dropFirst(prefix.count))
                break
            }
        }
        for suffix in arabicSuffixes where stem.hasSuffix(suffix) {
            let floor = suffix.count == 1 ? 4 : 3
            if stem.count - suffix.count >= floor {
                stem = String(stem.dropLast(suffix.count))
                break
            }
        }
        return stem
    }

    /// The corpus word a mistyped one most likely meant, or nil. Anything the translations already use
    /// as a substring is left alone: a half-typed "merc" is a prefix, not a typo for "merciful".
    private static func nearestWord(_ token: String, lanes: Lanes) -> String? {
        guard token.count >= fuzzyMinLength, Lanes.isLatinWord(token) else { return nil }
        let bytes = Array(token.utf8)
        if contains(bytes, in: lanes.vocabularyBlob) { return nil }
        let max = token.count >= fuzzyLongWord ? 2 : 1
        let mask = VocabularyWord.letterMask(of: bytes)
        var best: [UInt8]?
        var bestDistance = max + 1
        for length in (bytes.count - max)...(bytes.count + max) {
            for candidate in lanes.vocabularyByLength[length] ?? [] {
                guard candidate.mayBeWithin(max, of: mask) else { continue }
                let distance = boundedEditDistance(bytes, candidate.bytes, max: max)
                if distance < bestDistance {
                    bestDistance = distance
                    best = candidate.bytes
                    if distance == 1 { return String(decoding: candidate.bytes, as: UTF8.self) }
                }
            }
        }
        return best.map { String(decoding: $0, as: UTF8.self) }
    }

    /// A vocabulary word with the set of letters it uses, for the exact pre-test that spares the edit
    /// distance most of its candidates: every letter of the query that the word lacks (and the other
    /// way round) costs at least one edit, so a word within `max` edits shares all but `max` of them.
    struct VocabularyWord {
        let bytes: [UInt8]
        let mask: UInt32

        init(_ bytes: [UInt8]) {
            self.bytes = bytes
            mask = Self.letterMask(of: bytes)
        }

        /// One bit per lowercase ASCII letter (the vocabularies hold nothing else).
        static func letterMask(of bytes: [UInt8]) -> UInt32 {
            var mask: UInt32 = 0
            for byte in bytes where byte >= 0x61 && byte <= 0x7A {
                mask |= 1 << UInt32(byte - 0x61)
            }
            return mask
        }

        func mayBeWithin(_ max: Int, of other: UInt32) -> Bool {
            (other & ~mask).nonzeroBitCount <= max && (mask & ~other).nonzeroBitCount <= max
        }
    }

    /// Levenshtein, abandoned as soon as every cell in a row exceeds the budget. One row buffer per
    /// call (the classic single-row form): the version that allocated a fresh row per step spent
    /// most of a query's parse time in the allocator, over the thousands of candidates a correction
    /// walks. Over any elements (both lanes call it on ASCII bytes).
    static func boundedEditDistance<Element: Equatable>(_ a: [Element], _ b: [Element], max: Int) -> Int {
        if abs(a.count - b.count) > max { return max + 1 }
        if a.isEmpty { return b.count > max ? max + 1 : b.count }
        if b.isEmpty { return a.count > max ? max + 1 : a.count }
        var row = [Int](0...b.count)
        for i in 1...a.count {
            var diagonal = row[0]
            row[0] = i
            var rowBest = i
            for j in 1...b.count {
                let above = row[j]
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                let value = Swift.min(above + 1, row[j - 1] + 1, diagonal + cost)
                row[j] = value
                diagonal = above
                if value < rowBest { rowBest = value }
            }
            if rowBest > max { return max + 1 }
        }
        return row[b.count]
    }

    private static func parse(_ raw: String, lanes: Lanes) -> Query? {
        let isArabic = raw.containsArabicLetters
        var rest = raw
        var required: [String] = []
        // Quoted phrases every result must carry, pulled out first so their words are not also loose tokens.
        if let regex = try? NSRegularExpression(pattern: "\"([^\"]+)\"|“([^”]+)”") {
            let matches = regex.matches(in: raw, range: NSRange(raw.startIndex..., in: raw))
            for match in matches.reversed() {
                let inner = (1...2).compactMap { Range(match.range(at: $0), in: raw) }.first.map { String(raw[$0]) } ?? ""
                let folded = Settings.shared.cleanSearch(inner, whitespace: true)
                if !folded.isEmpty { required.insert(folded, at: 0) }
                if let whole = Range(match.range, in: rest) { rest.replaceSubrange(whole, with: " ") }
            }
        }
        let normalized = Settings.shared.cleanSearch(rest, whitespace: true)
        let phrase = Settings.shared.cleanSearch(raw, whitespace: true)
        let words = normalized.split(separator: " ").map(String.init).filter { !$0.isEmpty }
        let stopwords = isArabic ? arabicStopwords : englishStopwords
        let meaningful = words.filter { !stopwords.contains($0) }
        var used = meaningful.isEmpty ? words : meaningful
        if used.isEmpty, !required.isEmpty {
            used = required.joined(separator: " ").split(separator: " ").map(String.init)
        }
        guard !used.isEmpty else { return nil }

        var corrections: [Correction] = []
        var terms: [String] = []
        var seen = Set<String>()
        func remember(_ term: String) {
            if seen.insert(term).inserted { terms.append(term) }
        }
        let tokens: [Token] = used.map { text in
            remember(text)
            var stems: [String] = []
            if isArabic {
                let stemmed = stemArabic(text)
                if stemmed != text { stems.append(stemmed) }
            } else if let stem = stemEnglish(text) {
                stems.append(stem)
            }
            stems.forEach(remember)
            #if DEBUG
            let fuzzyStarted = DispatchTime.now().uptimeNanoseconds
            #endif
            let fuzzy = isArabic ? nil : nearestWord(text, lanes: lanes)
            #if DEBUG
            if RenderCounter.enabled {
                let candidates = ((text.count - 2)...(text.count + 2)).reduce(0) { $0 + (lanes.vocabularyByLength[$1]?.count ?? 0) }
                NSLog("RANKED quran fuzzy %@ -> %@ %.1f ms (%d candidates of %d words)", text, fuzzy ?? "-",
                      Double(DispatchTime.now().uptimeNanoseconds - fuzzyStarted) / 1_000_000, candidates, lanes.vocabulary.count)
            }
            #endif
            if let fuzzy {
                corrections.append(Correction(from: text, to: fuzzy))
                remember(fuzzy)
            }
            let skeleton = isArabic ? arabicSkeleton(text) : latinSkeleton(text)
            let minimum = (isArabic || text.count >= longRomanisedWord) ? minArabicSkeleton : minSkeletonLength
            return Token(text: text, stems: stems, fuzzy: fuzzy,
                         skeleton: skeleton.count >= minimum ? skeleton : nil, rawSkeleton: skeleton)
        }
        required.forEach(remember)
        return Query(isArabic: isArabic, phrase: phrase, required: required, tokens: tokens,
                     corrections: corrections, terms: terms)
    }

    // MARK: - Matching

    private struct FieldScore {
        var score: Int
        var matched: Int
        var position: Int
    }

    /// The byte offset of the first occurrence of `needle` in `haystack`, or nil.
    private static func find(_ needle: [UInt8], in haystack: [UInt8]) -> Int? {
        guard !needle.isEmpty, haystack.count >= needle.count else { return nil }
        return haystack.withUnsafeBufferPointer { text -> Int? in
            needle.withUnsafeBufferPointer { pattern -> Int? in
                guard let base = text.baseAddress, let patternBase = pattern.baseAddress,
                      let hit = memmem(base, text.count, patternBase, pattern.count) else { return nil }
                return UnsafeRawPointer(hit).assumingMemoryBound(to: UInt8.self) - base
            }
        }
    }

    private static func contains(_ needle: [UInt8], in haystack: [UInt8]) -> Bool {
        find(needle, in: haystack) != nil
    }

    /// The position score's unit is UTF-16 units into the field, as it was on strings: for Arabic
    /// and Latin (both in the BMP) that is one unit per scalar, so the continuation bytes are skipped.
    private static func units(before byteOffset: Int, in haystack: [UInt8]) -> Int {
        var count = 0
        var index = 0
        while index < byteOffset {
            if haystack[index] & 0xC0 != 0x80 { count += 1 }
            index += 1
        }
        return count
    }

    /// What one query word is worth against one padded field, or nil.
    private static func tokenHit(_ text: [UInt8], token: Token, weight: Int) -> FieldScore? {
        if let at = find(token.textBytes, in: text) {
            let whole = contains(token.textPadded, in: text)
            return FieldScore(score: weight + (whole ? wholeWordBonus : 0), matched: 1, position: units(before: at, in: text))
        }
        for stem in token.stemBytes {
            if let at = find(stem, in: text) {
                return FieldScore(score: weight - stemPenalty, matched: 1, position: units(before: at, in: text))
            }
        }
        if let fuzzy = token.fuzzyBytes, let at = find(fuzzy, in: text) {
            let whole = token.fuzzyPadded.map { contains($0, in: text) } ?? false
            return FieldScore(score: weight - fuzzyPenalty + (whole ? wholeWordBonus : 0), matched: 1,
                              position: units(before: at, in: text))
        }
        return nil
    }

    private static func scoreField(_ text: [UInt8], query: Query, weight: Int) -> FieldScore? {
        var score = 0
        var matched = 0
        var position = Int.max
        for token in query.tokens {
            guard let hit = tokenHit(text, token: token, weight: weight) else { continue }
            score += hit.score
            matched += 1
            position = Swift.min(position, hit.position)
        }
        guard matched > 0 else { return nil }
        if query.tokens.count > 1, !query.phraseBytes.isEmpty, contains(query.phraseBytes, in: text) {
            score += phraseBonus
            if contains(query.phrasePadded, in: text) { score += wholePhraseBonus }
        }
        return FieldScore(score: score, matched: matched, position: position == Int.max ? 0 : position)
    }

    private static func scoreSkeleton(words: [UInt8], tight: [UInt8], query: Query, weight: Int, wholeBonus: Int) -> FieldScore? {
        // Adjacency is the whole precision story for a multi-word query, so it is matched as ONE run
        // against the tight view: "qul huwa allahu" must not be satisfied by three fragments.
        let joined = query.joinedSkeleton
        if query.tokens.count > 1, joined.count >= minSkeletonLength, let at = find(joined, in: tight) {
            let score = (Swift.max(1, weight - skeletonPenalty) + wholeBonus) * query.tokens.count
            return FieldScore(score: score, matched: query.tokens.count, position: units(before: at, in: tight))
        }
        var score = 0
        var matched = 0
        var position = Int.max
        let base = Swift.max(1, weight - skeletonPenalty)
        for token in query.tokens {
            guard let skeleton = token.skeletonBytes, let padded = token.skeletonPadded else { continue }
            if let at = find(skeleton, in: words) {
                score += base + (contains(padded, in: words) ? wholeBonus : 0)
                position = Swift.min(position, units(before: at, in: words))
            } else if let at = find(skeleton, in: tight) {
                // One romanised token routinely spans two Arabic ones ("alhamdulillah" is الحمد لله).
                score += base + (skeleton.count >= minSkeletonLength ? wholeBonus : 0)
                position = Swift.min(position, units(before: at, in: tight))
            } else {
                continue
            }
            matched += 1
        }
        guard matched > 0 else { return nil }
        return FieldScore(score: score, matched: matched, position: position == Int.max ? 0 : position)
    }

    private struct Candidate {
        let index: Int
        let score: Int
        let matched: Int
        /// Reached through the consonant skeleton alone (see the last-resort rule in `search`).
        var viaSkeleton = false
    }

    // MARK: - Search

    /// The ranked ayahs for `raw`. Runs off the main thread on an immutable snapshot; the first call
    /// after an index build also derives the corpus lanes (a few tens of milliseconds).
    static func search(_ raw: String, snapshot: QuranData.VerseSearchSnapshot, limit: Int,
                       scope: QuranSearchScope? = nil) -> Outcome {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !snapshot.verseIndex.isEmpty else { return Outcome() }
        // The lanes fold translation and transliteration into one text, so a Search In filter on a
        // Latin query is the exact scan's to answer alone.
        if let scope, scope.lane != .all, !trimmed.containsArabicLetters { return Outcome() }
        // Digits are references and count queries, which other lanes answer; operator syntax belongs to
        // the exact scan.
        if trimmed.rangeOfCharacter(from: .decimalDigits) != nil { return Outcome() }
        if trimmed.contains(where: { "&|!#^%$=".contains($0) }) { return Outcome() }
        #if DEBUG
        let searchStarted = DispatchTime.now().uptimeNanoseconds
        var lanesMs = 0.0
        var parseMs = 0.0
        defer {
            if RenderCounter.enabled {
                NSLog("RANKED quran %.1f ms (lanes %.1f ms, parse %.1f ms)",
                      Double(DispatchTime.now().uptimeNanoseconds - searchStarted) / 1_000_000, lanesMs, parseMs)
            }
        }
        #endif
        let (lanes, builtMs) = lanes(for: snapshot)
        #if DEBUG
        lanesMs = builtMs
        let parseStarted = DispatchTime.now().uptimeNanoseconds
        #endif
        let parsed = parse(trimmed, lanes: lanes)
        #if DEBUG
        parseMs = Double(DispatchTime.now().uptimeNanoseconds - parseStarted) / 1_000_000
        #endif
        guard let query = parsed else { return Outcome() }

        let entries = snapshot.verseIndex
        // The skeleton tier is the noisiest one, so it is only consulted for words the translations do
        // not recognise: "mercy" means what it says; "alhamdulillah" and "صبر" are what it is for.
        let useSkeleton = query.tokens.contains { !$0.rawSkeleton.isEmpty && !lanes.vocabulary.contains($0.text) }
        var candidates: [Candidate] = []
        var best = 0

        for index in entries.indices {
            if index & 0x1FF == 0, Task.isCancelled { return Outcome() }
            if let scope, !scope.contains(surah: entries[index].surah, ayah: entries[index].ayah) { continue }
            let arabicText = lanes.arabic[index]
            let englishText = lanes.english[index]
            if !query.requiredBytes.isEmpty {
                let carries = query.requiredBytes.allSatisfy { contains($0, in: arabicText) || contains($0, in: englishText) }
                if !carries { continue }
            }

            var score = 0
            var matched = 0
            var position = 0
            var viaSkeleton = false

            if query.isArabic {
                var field = scoreField(arabicText, query: query, weight: arabicWeight)
                if field == nil || field!.matched < query.tokens.count {
                    if let stemmed = scoreField(lanes.arabicStems[index], query: query, weight: arabicWeight - stemPenalty),
                       stemmed.matched > (field?.matched ?? 0) {
                        field = stemmed
                    }
                    if useSkeleton, (field?.matched ?? 0) < query.tokens.count,
                       let skeleton = scoreSkeleton(words: lanes.skeletonWords[index], tight: lanes.skeletonTight[index],
                                                    query: query, weight: arabicWeight, wholeBonus: wholeWordBonus),
                       skeleton.matched > (field?.matched ?? 0) {
                        field = skeleton
                        viaSkeleton = true
                    }
                }
                if let field {
                    score = field.score
                    matched = field.matched
                    position = field.position
                }
            } else {
                if let direct = scoreField(englishText, query: query, weight: englishWeight) {
                    score = direct.score
                    matched = direct.matched
                    position = direct.position
                }
                // Romanised queries reach the Arabic only through the skeleton, ranked below the words:
                // someone typing Latin letters usually means the words, and only sometimes the sound.
                if useSkeleton, matched < query.tokens.count,
                   let skeleton = scoreSkeleton(words: lanes.skeletonWords[index], tight: lanes.skeletonTight[index],
                                                query: query, weight: transliterationWeight, wholeBonus: skeletonWholeWordBonus),
                   skeleton.matched > matched {
                    score = skeleton.score
                    matched = skeleton.matched
                    position = skeleton.position
                    viaSkeleton = true
                }
            }

            guard matched > 0 else { continue }
            score += Int((Double(coverageWeight * matched) / Double(query.tokens.count)).rounded())
            score += Swift.max(0, brevityWeight - lanes.wordCounts[index] / brevityWordsPerPoint)
            score += Swift.max(0, positionWeight - position / positionCharsPerPoint)
            if matched > best { best = matched }
            candidates.append(Candidate(index: index, score: score, matched: matched, viaSkeleton: viaSkeleton))
        }

        // Everything carrying the WHOLE query, or, when nothing does, the rows covering the most of it.
        //
        // The skeleton is the LAST resort: when any ayah carries the words themselves (as typed or by
        // stem), the rows that only share their consonants stand down. Without this a run of consonants
        // across a word break outranked the word with a prefix on it: "الصبر" led with 23:86
        // (ٱلسَّبۡعِ وَرَبُّ reads l-s-b-r), above every بِٱلصَّبۡرِ in the Quran.
        let covering = candidates.filter { $0.matched == best }
        let direct = covering.filter { !$0.viaSkeleton }
        let kept = (direct.isEmpty ? covering : direct)
            .sorted { $0.score != $1.score ? $0.score > $1.score : $0.index < $1.index }
        var outcome = Outcome()
        outcome.total = kept.count
        outcome.hits = kept.prefix(limit).map { entries[$0.index] }
        outcome.corrections = query.corrections
        outcome.relaxed = best > 0 && best < query.tokens.count
        // The typed words with their corrections applied: what the rows should paint.
        outcome.highlightQuery = query.tokens.map { $0.fuzzy ?? $0.text }.joined(separator: " ")
        return outcome
    }

    // MARK: - Skeletons

    /// Arabic letter -> skeleton consonant. Letters that share a Latin spelling collapse together;
    /// vowel carriers, hamza forms and marks are dropped.
    private static let arabicSkeletonMap: [Character: Character] = [
        "ب": "b", "پ": "b",
        "ت": "t", "ث": "t", "ط": "t",
        "ة": "h",
        "ج": "j", "چ": "j",
        "ح": "h", "خ": "h", "ه": "h", "ھ": "h",
        "د": "d", "ض": "d",
        "ذ": "z", "ز": "z", "ظ": "z", "ژ": "z",
        "ر": "r",
        "س": "s", "ص": "s", "ش": "s",
        "غ": "g", "گ": "g",
        "ف": "f", "ڤ": "f",
        "ق": "k", "ك": "k", "ک": "k",
        "ل": "l", "م": "m",
        "ن": "n", "ں": "n", "ڻ": "n",
        "ٹ": "t", "ڈ": "d", "ڑ": "r", "ړ": "r", "ہ": "h", "ۃ": "h", "ۀ": "h",
    ]

    private static let latinDigraphs: [(String, String)] = [
        ("kh", "h"), ("gh", "g"), ("th", "t"), ("dh", "z"), ("sh", "s"), ("ch", "s"), ("ph", "f"), ("ck", "k"),
    ]

    private static let latinSingles: [Character: Character] = [
        "b": "b", "p": "b", "t": "t", "j": "j", "h": "h", "d": "d", "z": "z", "r": "r", "s": "s", "c": "k",
        "g": "g", "f": "f", "v": "f", "k": "k", "q": "k", "x": "k", "l": "l", "m": "m", "n": "n",
    ]

    /// Runs of the same consonant collapse, so shadda and "ll" in "allah" agree.
    static func collapseSkeleton(_ skeleton: String) -> String {
        var out = ""
        var last: Character?
        for character in skeleton where character != last {
            out.append(character)
            last = character
        }
        return out
    }

    static func arabicSkeleton(_ text: String) -> String {
        var out = ""
        for character in text {
            if let mapped = arabicSkeletonMap[character] { out.append(mapped) }
        }
        return collapseSkeleton(out)
    }

    static func latinSkeleton(_ text: String) -> String {
        var lowered = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil).lowercased()
        for (pattern, replacement) in latinDigraphs {
            lowered = lowered.replacingOccurrences(of: pattern, with: replacement)
        }
        var out = ""
        for character in lowered {
            if let mapped = latinSingles[character] { out.append(mapped) }
        }
        return collapseSkeleton(out)
    }
}
