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
//   3. for a romanised word, the SOUND OUTLINE of the app's own transliteration ("tawbah" reaches
//      "tawbatu", "dhikr" reaches "zikr", "shaytan" reaches "Shaitaana": see `romanKey`)
//   4. the consonant skeleton, a poor man's root search for Arabic ("صبر" -> "الصابرين") and the
//      last resort for a romanised word the transliteration spells too differently to reach
//
// Every ayah is then scored on where its words landed, how much of the query it covers, how short it
// is and how early the match sits, and the list is the ayahs carrying the WHOLE query - or, when none
// does, the ones carrying the most of it (`relaxed`), rather than an empty screen.
//
// HOW a word matched always outranks WHERE: the match quality is scaled above the tie-breakers
// (brevity, position, the words sitting near each other), so a short ayah that merely contains the
// stem can never lead an ayah carrying the word that was typed.
//
// Two rules run after the scan, for Latin-script queries only, to settle "a misspelt English word"
// against "a romanised Arabic one", which "shirk" or "fajr" cannot settle on their own (Tilawa,
// update 79): a one-word query with a correction whose skeleton is a WHOLE Arabic word in a few
// ayahs is a romanisation, so the correction goes; otherwise, when the words themselves answered in
// more ayahs than the skeleton did, the skeleton's guesses go.
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
    private static let wholeWordBonus = 8
    private static let phraseBonus = 45
    private static let wholePhraseBonus = 20
    private static let stemPenalty = 3
    private static let fuzzyPenalty = 6
    private static let skeletonPenalty = 7
    /// A Latin word typed as the START of a word ("merc" in "mercy") beats the same letters inside
    /// one ("merc" in "commerce"). Arabic words wear clitics in front, so there it says nothing.
    private static let prefixBonus = 4
    /// What a romanised word is worth when its skeleton is a whole Arabic word, and when it is only
    /// a run inside one. The whole-word value sits between a typed word found inside another (10)
    /// and one found standing alone (18): the Arabic word is very likely the one meant, and it must
    /// still never outrank the row that carries what was typed.
    private static let latinSkeletonWhole = 11
    private static let latinSkeletonInside = 2
    /// What a romanised word is worth against the transliteration's sound outlines. Arabic builds a
    /// word by wrapping its stem, so WHERE the outline sits in a word says how likely it is the word:
    ///
    ///   whole   "tawbah" is "tawbatu"                                        the word itself
    ///   tight   "alhamdulillah" is "alhamdu lillaahi"                        the word, split by the recitation
    ///   ending  "sabr" ends "bissabri", "shaytan" ends "ash-shaitaanu"       the word behind its clitics
    ///   start   "salah" starts "saalihaati"                                  usually another word
    ///   inside  a long outline in the middle of a word                       a guess
    private static let romanWhole = 12
    private static let romanTight = 11
    private static let romanEnding = 10
    private static let romanStart = 7
    private static let romanInside = 5
    /// An outline's least length per tier: three symbols name a whole word and nothing less.
    private static let minRomanKey = 3
    private static let minRomanEdge = 4
    private static let minRomanInside = 6
    private static let minRomanTight = 7
    /// A ROMANISED word (one the translations do not use, even as part of a word) found in the
    /// transliteration as typed: standing alone it is the word (`wholeWordBonus`, as ever); as the
    /// start of a longer word or inside one it is usually another word ("salah" in "sa-alahaa"), so
    /// both rank below the outline tiers above instead of above them.
    private static let romanisedPrefixPenalty = 2
    private static let romanisedInsidePenalty = 3
    private static let coverageWeight = 34
    private static let brevityWeight = 12
    private static let brevityWordsPerPoint = 4
    private static let positionWeight = 8
    private static let positionCharsPerPoint = 25
    /// The words of a several-word query sitting near each other (short of the phrase bonus).
    private static let proximityWeight = 6
    private static let proximityCharsPerPoint = 12
    /// Match quality is multiplied by this before the tie-breakers (at most 26 together) are added,
    /// so they order rows of EQUAL quality and nothing else.
    private static let qualityScale = 32

    private static let fuzzyMinLength = 4
    private static let fuzzyLongWord = 7
    private static let minSkeletonLength = 4
    private static let minArabicSkeleton = 3
    private static let longRomanisedWord = 6
    /// A short romanised word ("sabr" is "sbr", "dhikr" is "zkr") folds to three consonants: too
    /// generic to search as a run, so it is matched as a WHOLE Arabic word, allowing the clitics a
    /// word wears in front (ال is "l"; ب ك ف with or without it; the verb prefixes ت ن; س / است).
    private static let shortSkeletonLength = 3
    private static let shortSkeletonPrefixes = ["", "l", "b", "bl", "k", "kl", "f", "fl", "fb", "t", "n", "s", "st"]
    /// A one-word query with a spelling correction is read as a romanisation when its skeleton is a
    /// whole Arabic word in at least this many ayahs.
    private static let romanisedMinWholeWords = 3

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
        /// The transliteration as sound outlines (`romanKey`): each word's outline, space-padded, and
        /// every word's outline as one run (so a romanised phrase, or one word the recitation splits
        /// in two, is found across the breaks).
        let romanWords: [[UInt8]]
        let romanTight: [[UInt8]]
        let wordCounts: [Int]
        /// Every Latin word the translations use, for spelling correction: the set for membership,
        /// the space-joined blob (bytes) for the substring test, the words by length (bytes) for the
        /// edit-distance walk, which used to allocate a `[Character]` per candidate.
        let vocabulary: Set<String>
        let vocabularyBlob: [UInt8]
        /// The words of the TRANSLATIONS alone. `vocabulary` also holds every romanised word of the
        /// transliteration, and two decisions must not see those: "is this an ordinary English word"
        /// (which keeps the skeleton tier off; "qul huwa allahu ahad" used to answer with 2:282
        /// because all four are transliteration words) and "what did they mean to type" ("tawbah"
        /// was corrected to "tawrah", the transliteration's Torah).
        let translationWords: Set<String>
        /// The same words space-joined, for "is this part of an English word" (a half-typed "merc").
        let translationBlob: [UInt8]
        let correctionsByLength: [Int: [VocabularyWord]]
        /// Corrections already looked up, the "none" answer included: the walk is repeated for every
        /// keystroke typed after a misspelt word.
        private var nearest: [String: String?] = [:]
        private let nearestLock = NSLock()

        /// Whether a precomputed pack answered for this riwayah (`VerseSearchPack`, Phase 10.14). The
        /// rows it had no record for were folded live; when there was no pack at all, the build is
        /// written to Caches for the next launch (see `lanes(for:)`).
        let readFromPack: Bool

        /// One ayah's rows and its words for the two vocabularies, as `init` computed them inline
        /// before the pack existed. The pack stores exactly these per record; an entry the pack lacks
        /// (an ayah only another riwayah numbers) still comes through here.
        struct Row {
            var arabicStems: [UInt8]
            var skeletonWords: [UInt8]
            var skeletonTight: [UInt8]
            var romanWords: [UInt8]
            var romanTight: [UInt8]
            var wordCount: Int
            var vocabularyWords: [String]
            var translationWords: [String]
        }

        static func row(for entry: VerseIndexEntry, snapshot: QuranData.VerseSearchSnapshot) -> Row {
            // The clean Arabic (the second of the blob's folds) is the one the skeletons and stems
            // are taken from: one copy of the text, no diacritics, no duplicated lanes.
            let cleanTokens = Self.cleanArabicTokens(entry, snapshot: snapshot)
            let arabicStems = Array((" " + cleanTokens.map(stemArabic).joined(separator: " ") + " ").utf8)
            let skeletons = cleanTokens.map(arabicSkeleton).filter { !$0.isEmpty }
            let skeletonWords = Array((" " + skeletons.joined(separator: " ") + " ").utf8)
            let skeletonTight = Array(collapseSkeleton(skeletons.joined()).utf8)
            var vocabularyWords: [String] = []
            for word in entry.englishTokens where word.count >= fuzzyMinLength && Self.isLatinWord(word) {
                vocabularyWords.append(word)
            }
            let latin = Self.latinTokens(entry, snapshot: snapshot)
            var translationWords: [String] = []
            for word in latin.translation where Self.isLatinWord(word) {
                translationWords.append(word)
            }
            var outlineWords: [UInt8] = [0x20]
            var outlineTight: [UInt8] = []
            for word in latin.transliteration {
                let key = romanKey(word)
                guard !key.isEmpty else { continue }
                outlineWords.append(contentsOf: key)
                outlineWords.append(0x20)
                appendRun(key, to: &outlineTight)
            }
            return Row(arabicStems: arabicStems, skeletonWords: skeletonWords, skeletonTight: skeletonTight,
                       romanWords: outlineWords, romanTight: outlineTight,
                       wordCount: Swift.max(1, cleanTokens.count),
                       vocabularyWords: vocabularyWords, translationWords: translationWords)
        }

        init(snapshot: QuranData.VerseSearchSnapshot, allowPack: Bool = true) {
            key = Self.key(for: snapshot)
            let entries = snapshot.verseIndex
            // ONE thread on purpose. Building the corpus in stretches on every core was measured
            // slower, repeatably (1.0 to 1.4 s against 0.66 to 0.70 s, optimized build, 2026-10-02):
            // the folds contend with each other.
            var english: [[UInt8]] = []
            var arabic: [[UInt8]] = []
            var arabicStems: [[UInt8]] = []
            var skeletonWords: [[UInt8]] = []
            var skeletonTight: [[UInt8]] = []
            var romanWords: [[UInt8]] = []
            var romanTight: [[UInt8]] = []
            var wordCounts: [Int] = []
            romanWords.reserveCapacity(entries.count)
            romanTight.reserveCapacity(entries.count)
            english.reserveCapacity(entries.count)
            arabic.reserveCapacity(entries.count)
            arabicStems.reserveCapacity(entries.count)
            skeletonWords.reserveCapacity(entries.count)
            skeletonTight.reserveCapacity(entries.count)
            wordCounts.reserveCapacity(entries.count)
            var words = Set<String>()
            var translation = Set<String>()
            // The precomputed rows for this riwayah's texts, when a pack has them (the shipped Hafs
            // pack, or the one this build wrote to Caches). The padded english and arabic lanes are
            // the index's own blobs and are made here either way.
            let pack = allowPack ? VerseSearchPack.pack(for: snapshot.qiraahKey, surahs: snapshot.surahs) : nil
            var packRows = 0
            for entry in entries {
                english.append(Array((" " + entry.englishBlob + " ").utf8))
                arabic.append(Array((" " + entry.arabicBlob + " ").utf8))
                if let pack, let index = pack.recordIndex(surah: entry.surah, ayah: entry.ayah) {
                    let record = pack.record(at: index)
                    arabicStems.append(pack.bytes(record, field: VerseSearchPack.Field.arabicStems))
                    skeletonWords.append(pack.bytes(record, field: VerseSearchPack.Field.skeletonWords))
                    skeletonTight.append(pack.bytes(record, field: VerseSearchPack.Field.skeletonTight))
                    romanWords.append(pack.bytes(record, field: VerseSearchPack.Field.romanWords))
                    romanTight.append(pack.bytes(record, field: VerseSearchPack.Field.romanTight))
                    wordCounts.append(record.wordCount)
                    packRows += 1
                    continue
                }
                let row = Self.row(for: entry, snapshot: snapshot)
                arabicStems.append(row.arabicStems)
                skeletonWords.append(row.skeletonWords)
                skeletonTight.append(row.skeletonTight)
                wordCounts.append(row.wordCount)
                words.formUnion(row.vocabularyWords)
                translation.formUnion(row.translationWords)
                romanWords.append(row.romanWords)
                romanTight.append(row.romanTight)
            }
            if let pack, packRows > 0 {
                words.formUnion(pack.vocabulary)
                translation.formUnion(pack.translationWords)
            }
            readFromPack = pack != nil
            // No translation text to read (a snapshot whose offsets do not resolve): fall back to
            // the mixed list, which is what both decisions used before.
            if translation.isEmpty { translation = words }
            self.english = english
            self.arabic = arabic
            self.arabicStems = arabicStems
            self.skeletonWords = skeletonWords
            self.skeletonTight = skeletonTight
            self.romanWords = romanWords
            self.romanTight = romanTight
            self.wordCounts = wordCounts
            vocabulary = words
            vocabularyBlob = Array((" " + words.joined(separator: " ") + " ").utf8)
            translationWords = translation
            translationBlob = Array((" " + translation.joined(separator: " ") + " ").utf8)
            var byLength: [Int: [VocabularyWord]] = [:]
            for word in translation where word.count >= fuzzyMinLength {
                byLength[word.utf8.count, default: []].append(VocabularyWord(Array(word.utf8)))
            }
            correctionsByLength = byLength
        }

        /// These lanes as pack records (`VerseSearchPack.RecordInput`): what the index stores for each
        /// ayah beside what was derived from it here, with the daily-card flags of its text. Written to
        /// Caches after a live build, and exported for the shipped Hafs pack. `hafsOnly` leaves out the
        /// ayahs only another riwayah numbers (their Hafs text is empty), so the shipped file is the
        /// same whether or not the exporting host had the riwayah overlays loaded.
        func recordInputs(snapshot: QuranData.VerseSearchSnapshot, hafsOnly: Bool) -> [VerseSearchPack.RecordInput] {
            var inputs: [VerseSearchPack.RecordInput] = []
            inputs.reserveCapacity(snapshot.verseIndex.count)
            for (index, entry) in snapshot.verseIndex.enumerated() {
                let si = Int(entry.surahOffset), ai = Int(entry.ayahOffset)
                guard snapshot.surahs.indices.contains(si), snapshot.surahs[si].ayahs.indices.contains(ai) else { continue }
                let ayah = snapshot.surahs[si].ayahs[ai]
                if hafsOnly, ayah.textHafs.isEmpty { continue }
                inputs.append(VerseSearchPack.RecordInput(
                    surah: entry.surah, ayah: entry.ayah,
                    flags: Settings.dailyCardFlags(for: ayah), wordCount: wordCounts[index],
                    arabic: Array(entry.arabicBlob.utf8), silent: Array(entry.silentArabicBlob.utf8),
                    hamza: entry.hamzaArabicBlob.map { Array($0.utf8) }, english: Array(entry.englishBlob.utf8),
                    arabicStems: arabicStems[index], skeletonWords: skeletonWords[index], skeletonTight: skeletonTight[index],
                    romanWords: romanWords[index], romanTight: romanTight[index]))
            }
            return inputs
        }

        /// The folded words of the translations and of the transliteration (its pause hints left out),
        /// read off the index's own `englishTokens` wherever that is provably the same thing, folded
        /// afresh otherwise. `englishTokens` is the two translations, the transliteration and its
        /// vowel-folded twin, each folded and split, one after another; the transliteration's chunks
        /// map one to one onto its tokens, so counting them says where each part begins. The reading
        /// is trusted only when the twin folds back exactly at both ends (see `verifyLatinTokens`).
        /// Folding everything again cost half of the corpus build (optimized, 2026-10-02: 280 of 640 ms).
        fileprivate static func latinTokens(_ entry: VerseIndexEntry, snapshot: QuranData.VerseSearchSnapshot)
            -> (translation: [String], transliteration: [String]) {
            let si = Int(entry.surahOffset), ai = Int(entry.ayahOffset)
            guard snapshot.surahs.indices.contains(si), snapshot.surahs[si].ayahs.indices.contains(ai) else { return ([], []) }
            let ayah = snapshot.surahs[si].ayahs[ai]
            let tokens = entry.englishTokens
            if let shape = transliterationShape(ayah.textTransliteration), !shape.isEmpty {
                let count = shape.count
                let start = tokens.count - 2 * count
                if start >= 0,
                   foldedTransliterationToken(tokens[start]) == tokens[start + count],
                   foldedTransliterationToken(tokens[start + count - 1]) == tokens[tokens.count - 1] {
                    var transliteration: [String] = []
                    transliteration.reserveCapacity(count)
                    for (offset, chunk) in shape.enumerated() {
                        if chunk.touched {
                            // A pause hint rode on this chunk ("Salaah,(ti)"): fold what stands outside it.
                            let outside = Settings.shared.cleanSearch(String(decoding: chunk.outside, as: UTF8.self), whitespace: true)
                            if !outside.isEmpty { transliteration.append(contentsOf: outside.split(separator: " ").map(String.init)) }
                        } else {
                            transliteration.append(tokens[start + offset])
                        }
                    }
                    return (Array(tokens[0..<start]), transliteration)
                }
            }
            return (translationTokens(entry, snapshot: snapshot), transliterationTokens(entry, snapshot: snapshot))
        }

        private struct TransliterationChunk {
            var outside: [UInt8] = []
            var touched = false
            var survives = false
        }

        /// The transliteration's chunks (its whitespace-separated runs that the search fold keeps),
        /// each with the bytes it holds outside any parentheses and whether it touched one. Nil when a
        /// character the fold might drop or keep is in it (anything beyond ASCII): then it is folded.
        private static func transliterationShape(_ text: String) -> [TransliterationChunk]? {
            var chunks: [TransliterationChunk] = []
            var current = TransliterationChunk()
            var open = false
            var depth = 0
            func close() {
                if open, current.survives { chunks.append(current) }
                current = TransliterationChunk()
                open = false
            }
            for byte in text.utf8 {
                if byte >= 0x80 { return nil }
                switch byte {
                case 0x20, 0x09, 0x0A, 0x0D:
                    close()
                case 0x28:                                           // (
                    open = true; current.touched = true; depth += 1
                case 0x29:                                           // )
                    open = true; current.touched = true; depth = Swift.max(0, depth - 1)
                default:
                    open = true
                    let letter = (0x61...0x7A).contains(byte) || (0x41...0x5A).contains(byte) || (0x30...0x39).contains(byte)
                    if letter { current.survives = true }
                    if depth > 0 { current.touched = true } else { current.outside.append(byte) }
                }
            }
            close()
            return chunks
        }

        /// `Settings.foldedTransliterationForSearch` on one folded token: the same replacements in the
        /// same order.
        private static func foldedTransliterationToken(_ token: String) -> String {
            var folded = token
            for (long, short) in [("aa", "a"), ("ee", "i"), ("ii", "i"), ("oo", "u"), ("uu", "u")] {
                folded = folded.replacingOccurrences(of: long, with: short)
            }
            return folded
        }

        #if DEBUG
        /// How many ayahs the shortcut reads differently from the folds (a unit test holds it at 0).
        static func verifyLatinTokens(snapshot: QuranData.VerseSearchSnapshot) -> Int {
            var mismatches = 0
            for entry in snapshot.verseIndex {
                let fast = latinTokens(entry, snapshot: snapshot)
                if fast.translation != translationTokens(entry, snapshot: snapshot)
                    || fast.transliteration != transliterationTokens(entry, snapshot: snapshot) {
                    mismatches += 1
                }
            }
            return mismatches
        }
        #endif

        /// The folded words of the ayah's two translations (the transliteration left out).
        fileprivate static func translationTokens(_ entry: VerseIndexEntry, snapshot: QuranData.VerseSearchSnapshot) -> [String] {
            let si = Int(entry.surahOffset), ai = Int(entry.ayahOffset)
            guard snapshot.surahs.indices.contains(si), snapshot.surahs[si].ayahs.indices.contains(ai) else { return [] }
            let ayah = snapshot.surahs[si].ayahs[ai]
            return Settings.shared.cleanSearch(ayah.textEnglishSaheeh + " " + ayah.textEnglishMustafa, whitespace: true)
                .split(separator: " ").map(String.init)
        }

        /// The folded words of the ayah's transliteration, its pause hints ("Salaah,(ti)") left out:
        /// they are alternatives to the ending before them, not words of their own.
        fileprivate static func transliterationTokens(_ entry: VerseIndexEntry, snapshot: QuranData.VerseSearchSnapshot) -> [String] {
            let si = Int(entry.surahOffset), ai = Int(entry.ayahOffset)
            guard snapshot.surahs.indices.contains(si), snapshot.surahs[si].ayahs.indices.contains(ai) else { return [] }
            var text = ""
            var depth = 0
            for character in snapshot.surahs[si].ayahs[ai].textTransliteration {
                if character == "(" { depth += 1; continue }
                if character == ")" { depth = Swift.max(0, depth - 1); continue }
                if depth == 0 { text.append(character) }
            }
            return Settings.shared.cleanSearch(text, whitespace: true).split(separator: " ").map(String.init)
        }

        func cachedCorrection(for token: String) -> String?? {
            nearestLock.lock(); defer { nearestLock.unlock() }
            return nearest[token]
        }

        func remember(correction: String?, for token: String) {
            nearestLock.lock(); defer { nearestLock.unlock() }
            if nearest.count >= 2048 { nearest.removeAll(keepingCapacity: true) }
            nearest[token] = correction
        }

        static func key(for snapshot: QuranData.VerseSearchSnapshot) -> String {
            "\(snapshot.qiraahKey)|\(snapshot.verseIndex.count)|\(snapshot.verseIndex.first?.arabicBlob.hashValue ?? 0)"
        }

        fileprivate static func cleanArabicTokens(_ entry: VerseIndexEntry, snapshot: QuranData.VerseSearchSnapshot) -> [String] {
            let si = Int(entry.surahOffset), ai = Int(entry.ayahOffset)
            guard snapshot.surahs.indices.contains(si), snapshot.surahs[si].ayahs.indices.contains(ai) else {
                return entry.arabicTokens
            }
            let surah = snapshot.surahs[si]
            // `removeDots: false`: the default follows the Hide Arabic Dots switch, and with it on the
            // stems and skeletons were taken from the dotless rasm (ب ت ث one letter), so the lanes no
            // longer met a typed query and no longer equalled the shipped pack.
            let clean = surah.ayahs[ai].textCleanArabic(for: snapshot.displayQiraah, surahID: surah.id, removeDots: false)
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
        #if DEBUG
        if RenderCounter.enabled { NSLog("RANKED quran lanes %@ %.1f ms", built.readFromPack ? "from pack" : "built", ms) }
        #endif
        if !built.readFromPack {
            // Nothing precomputed served this riwayah: keep what was just built for the next launch
            // (Phase 10.14; the shipped file covers Hafs, this covers the riwayah on display).
            VerseSearchPack.saveToCaches(qiraahKey: snapshot.qiraahKey, surahs: snapshot.surahs,
                                         records: built.recordInputs(snapshot: snapshot, hafsOnly: false),
                                         vocabulary: Array(built.vocabulary),
                                         translationWords: Array(built.translationWords))
        }
        return (built, ms)
    }

    #if DEBUG
    /// For the unit test: ayahs whose Latin tokens the shortcut reads differently from the folds.
    static func verifyLatinTokenShortcut(snapshot: QuranData.VerseSearchSnapshot) -> Int {
        Lanes.verifyLatinTokens(snapshot: snapshot)
    }

    /// `PrecomputedPackTests`: everything the lanes hold, built live or read out of the pack, so the
    /// two can be compared field by field. Nothing is cached.
    struct LanesForTests: Equatable {
        let english: [[UInt8]]
        let arabic: [[UInt8]]
        let arabicStems: [[UInt8]]
        let skeletonWords: [[UInt8]]
        let skeletonTight: [[UInt8]]
        let romanWords: [[UInt8]]
        let romanTight: [[UInt8]]
        let wordCounts: [Int]
        let vocabulary: Set<String>
        let translationWords: Set<String>
        let correctionsByLength: [Int: Set<[UInt8]>]
        let readFromPack: Bool
    }

    static func lanesForTests(snapshot: QuranData.VerseSearchSnapshot, allowPack: Bool) -> LanesForTests {
        let lanes = Lanes(snapshot: snapshot, allowPack: allowPack)
        return LanesForTests(
            english: lanes.english, arabic: lanes.arabic, arabicStems: lanes.arabicStems,
            skeletonWords: lanes.skeletonWords, skeletonTight: lanes.skeletonTight,
            romanWords: lanes.romanWords, romanTight: lanes.romanTight, wordCounts: lanes.wordCounts,
            vocabulary: lanes.vocabulary, translationWords: lanes.translationWords,
            correctionsByLength: lanes.correctionsByLength.mapValues { Set($0.map(\.bytes)) },
            readFromPack: lanes.readFromPack)
    }

    /// `PrecomputedPackTests`: the records and word lists of a live build, for the export of the shipped
    /// Hafs pack.
    static func packInputsForTests(snapshot: QuranData.VerseSearchSnapshot)
        -> (records: [VerseSearchPack.RecordInput], vocabulary: [String], translationWords: [String]) {
        let lanes = Lanes(snapshot: snapshot, allowPack: false)
        return (lanes.recordInputs(snapshot: snapshot, hafsOnly: true), Array(lanes.vocabulary), Array(lanes.translationWords))
    }

    /// "-rankedBench": what one build of the lanes costs away from the launch's own work, and what
    /// each kind of folding in it costs alone. Nothing is cached.
    static func benchmarkLanesBuild(snapshot: QuranData.VerseSearchSnapshot) -> String {
        func time(_ work: () -> Void) -> Double {
            let started = DispatchTime.now().uptimeNanoseconds
            work()
            return Double(DispatchTime.now().uptimeNanoseconds - started) / 1_000_000
        }
        let entries = snapshot.verseIndex
        let whole = time { _ = Lanes(snapshot: snapshot) }
        let arabic = time { for entry in entries { _ = Lanes.cleanArabicTokens(entry, snapshot: snapshot) } }
        let translation = time { for entry in entries { _ = Lanes.translationTokens(entry, snapshot: snapshot) } }
        let outlines = time {
            for entry in entries {
                for word in Lanes.transliterationTokens(entry, snapshot: snapshot) { _ = romanKey(word) }
            }
        }
        let shortcut = time {
            for entry in entries {
                for word in Lanes.latinTokens(entry, snapshot: snapshot).transliteration { _ = romanKey(word) }
            }
        }
        return String(format: "whole %.1f ms, arabic tokens %.1f, translation tokens %.1f, outlines %.1f, both by the shortcut %.1f",
                      whole, arabic, translation, outlines, shortcut)
    }
    #endif

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
        /// " word": the typed word at the start of a word (Latin lanes only).
        let textLeading: [UInt8]
        /// The whole-word needles of a short romanised word, one per clitic it may wear (see
        /// `shortSkeletonPrefixes`). Empty for Arabic script, for a word the run search already
        /// covers, and for fewer than three consonants, where even a whole word says nothing
        /// ("iman" is "mn").
        let shortSkeletonNeedles: [[UInt8]]
        /// The word's sound outlines (see `romanKey`), one per way its spelling can be read. Empty
        /// for Arabic script and for a word too short to mean anything.
        let romanKeys: [RomanKey]
        /// A Latin word the translations do not use, even as part of a word: a romanised one.
        let romanised: Bool
        /// The first letters of a longer romanised word as typed ("tawb" of "tawbah"). Two words can
        /// share a sound outline ("tawbatu" repentance, "tabbat" may they perish); the transliteration
        /// that also STARTS the way the word was typed is the likelier one, and leads its tier.
        let literalStart: [UInt8]?
        /// What a result row should paint for this word: the correction, else the typed word, else
        /// (when only its stem is a word of the corpus) the stem.
        let highlight: String
        /// Other spellings of an Arabic word, tried only when the word as typed stands whole nowhere
        /// in the Quran (`SearchFoldTables.arabicQueryVariants`): "شيئا" as the mushaf's seatless
        /// "شيا", "موسي" as "موسا". Bare and space-padded, like the text.
        let alternateBytes: [[UInt8]]
        let alternatePadded: [[UInt8]]
        /// Set when the word was typed with a bare ء: a row counts for it only when its hamza lane
        /// carries the word with the hamza kept (the exact scan's own rule).
        let hamza: Settings.HamzaPrecisionFilter?

        init(text: String, stems: [String], fuzzy: String?, skeleton: String?, rawSkeleton: String,
             isArabic: Bool, romanised: Bool, highlight: String,
             alternates: [String] = [], hamza: Settings.HamzaPrecisionFilter? = nil) {
            self.text = text
            alternateBytes = alternates.map { Array($0.utf8) }
            alternatePadded = alternates.map { Array(" \($0) ".utf8) }
            self.hamza = hamza
            self.romanised = romanised
            self.stems = stems
            self.fuzzy = fuzzy
            self.skeleton = skeleton
            self.rawSkeleton = rawSkeleton
            self.highlight = highlight
            textBytes = Array(text.utf8)
            textPadded = Array(" \(text) ".utf8)
            textLeading = Array(" \(text)".utf8)
            // An English stem is matched at the START of a word: "kindness" reaches "kind" and
            // "kindly", and no longer "mankind". An Arabic stem sits behind its clitics, so there
            // it stays a plain run.
            stemBytes = stems.map { Array((isArabic ? $0 : " \($0)").utf8) }
            fuzzyBytes = fuzzy.map { Array($0.utf8) }
            fuzzyPadded = fuzzy.map { Array(" \($0) ".utf8) }
            skeletonBytes = skeleton.map { Array($0.utf8) }
            skeletonPadded = skeleton.map { Array(" \($0) ".utf8) }
            if !isArabic, skeleton == nil, rawSkeleton.count == QuranRankedSearch.shortSkeletonLength {
                shortSkeletonNeedles = QuranRankedSearch.shortSkeletonPrefixes.map { Array(" \($0)\(rawSkeleton) ".utf8) }
            } else {
                shortSkeletonNeedles = []
            }
            romanKeys = isArabic ? [] : QuranRankedSearch.romanKeys(for: text)
            literalStart = !isArabic && romanised && text.count >= 5 ? Array(text.utf8.prefix(4)) : nil
        }
    }

    /// One reading of a romanised word, ready for the lanes.
    struct RomanKey {
        /// The outline as typed: the run searched for across word breaks.
        let full: [UInt8]
        /// The outline without the vowel it ends on, bare and at a word start (" key").
        let bare: [UInt8]
        let leading: [UInt8]
        /// The word standing whole, and ending a longer one, each with the closing vowels a word of
        /// the recitation may carry: "tawbat" is "tawbatu", "tawbata" and "tawbati". The endings are
        /// empty for an outline that opens on a vowel: nothing anchors it, and "-aman" ends every
        /// accusative from "'aleeman" to "hakeeman".
        let wholes: [[UInt8]]
        let endings: [[UInt8]]

        /// `pauseForm` is a word typed with the "-ah" of a ta marbuta, read as it stands: that is how
        /// the word sounds at a pause and nowhere else, so it takes no closing vowel ("tawbah" is
        /// not "ijtabaahu").
        init(full: [UInt8], pauseForm: Bool) {
            self.full = full
            let stem = pauseForm ? full : QuranRankedSearch.strippedRomanKey(full)
            bare = stem
            leading = [0x20] + stem
            let closings: [[UInt8]] = pauseForm ? [[]] : [[], [0x61], [0x75]]
            var standing: [[UInt8]] = []
            var closing: [[UInt8]] = []
            let anchored = stem.first.map { !QuranRankedSearch.isOutlineVowel($0) } ?? false
            for vowel in closings {
                let ended = stem + vowel + [0x20]
                standing.append([0x20] + ended)
                if anchored { closing.append(ended) }
            }
            wholes = standing
            endings = closing
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
        /// The tokens' sound outlines as one run, one per reading of the query's spelling.
        let joinedRoman: [[UInt8]]
        /// A word of the query was typed with a bare ء (see `Token.hamza`).
        let filtersHamza: Bool

        init(isArabic: Bool, phrase: String, required: [String], tokens: [Token], corrections: [Correction], terms: [String]) {
            filtersHamza = tokens.contains { $0.hamza != nil }
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
            joinedRoman = isArabic || tokens.count < 2 ? [] : QuranRankedSearch.joinedRomanKeys(for: tokens.map(\.text))
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

    /// The one English stemmer of both ranked lanes (the hadith lane calls this too).
    static func stemEnglish(_ token: String) -> String? {
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
    ///
    /// A word whose STEM the corpus knows is an inflection, not a typo: "mercies" stems to "mercy",
    /// and used to be "corrected" to "merges" (two edits away) ahead of it. The candidates are the
    /// translations' words only: a correction is English spelling, and the transliteration's words
    /// are not English ("tawbah" became "tawrah").
    private static func nearestWord(_ token: String, stems: [String], lanes: Lanes) -> String? {
        guard token.count >= fuzzyMinLength, Lanes.isLatinWord(token) else { return nil }
        let bytes = Array(token.utf8)
        if contains(bytes, in: lanes.vocabularyBlob) { return nil }
        for stem in stems where contains(Array(" \(stem)".utf8), in: lanes.vocabularyBlob) { return nil }
        if let cached = lanes.cachedCorrection(for: token) { return cached }
        let max = token.count >= fuzzyLongWord ? 2 : 1
        let mask = VocabularyWord.letterMask(of: bytes)
        var best: [UInt8]?
        var bestDistance = max + 1
        search: for length in (bytes.count - max)...(bytes.count + max) {
            for candidate in lanes.correctionsByLength[length] ?? [] {
                guard candidate.mayBeWithin(max, of: mask) else { continue }
                let distance = boundedEditDistance(bytes, candidate.bytes, max: max)
                if distance < bestDistance {
                    bestDistance = distance
                    best = candidate.bytes
                    // One edit is as close as a different word gets.
                    if distance == 1 { break search }
                }
            }
        }
        let found = best.map { String(decoding: $0, as: UTF8.self) }
        lanes.remember(correction: found, for: token)
        return found
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
        // What the fold erases from an Arabic word and the lane still has to know, read off the RAW
        // words and keyed by their fold: the other spellings to try ("شيئا" found nothing, in either
        // lane, because the mushaf writes that hamza without a seat), and whether a bare ء was typed
        // ("ماء" folded to "ما" and led with ayahs of the particle).
        var spellings: [String: [String]] = [:]
        var hamzaFilters: [String: Settings.HamzaPrecisionFilter] = [:]
        if isArabic {
            for piece in rest.split(whereSeparator: { $0.isWhitespace }) {
                let word = String(piece)
                let folded = Settings.shared.cleanSearch(word, whitespace: true)
                guard !folded.isEmpty else { continue }
                if spellings[folded] == nil { spellings[folded] = SearchFoldTables.arabicQueryVariants(of: word) }
                if hamzaFilters[folded] == nil, let filter = Settings.HamzaPrecisionFilter(query: word) {
                    hamzaFilters[folded] = filter
                }
            }
        }
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
            let fuzzy = isArabic ? nil : nearestWord(text, stems: stems, lanes: lanes)
            #if DEBUG
            if RenderCounter.enabled {
                let candidates = ((text.count - 2)...(text.count + 2)).reduce(0) { $0 + (lanes.correctionsByLength[$1]?.count ?? 0) }
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
            // The word a row should paint. A typed word that is no word of the corpus but whose
            // stem is ("forgivness" -> "forgiv") paints the stem, or the row would paint nothing.
            var paint = fuzzy ?? text
            if fuzzy == nil, !isArabic, let stem = stems.first,
               !contains(Array(text.utf8), in: lanes.vocabularyBlob),
               contains(Array(" \(stem)".utf8), in: lanes.vocabularyBlob) {
                paint = stem
            }
            // The other spellings are a FALLBACK: a word that stands whole somewhere as typed keeps
            // exactly the rows it had ("في" must not also mean "فا"), and only the spellings the
            // text really carries are kept, the first of them being what a row paints.
            var alternates: [String] = []
            if isArabic, let variants = spellings[text], !variants.isEmpty {
                let padded = Array(" \(text) ".utf8)
                if !lanes.arabic.contains(where: { contains(padded, in: $0) }) {
                    alternates = variants.filter { variant in
                        let bytes = Array(variant.utf8)
                        return lanes.arabic.contains { contains(bytes, in: $0) }
                    }
                    if let first = alternates.first { paint = first }
                }
            }
            return Token(text: text, stems: stems, fuzzy: fuzzy,
                         skeleton: skeleton.count >= minimum ? skeleton : nil, rawSkeleton: skeleton,
                         isArabic: isArabic,
                         romanised: !isArabic && !contains(Array(text.utf8), in: lanes.translationBlob),
                         highlight: paint, alternates: alternates, hamza: hamzaFilters[text])
        }
        required.forEach(remember)
        return Query(isArabic: isArabic, phrase: phrase, required: required, tokens: tokens,
                     corrections: corrections, terms: terms)
    }

    // MARK: - Matching

    private struct FieldScore {
        var score: Int
        var matched: Int
        /// Where the earliest match starts, for the position bonus.
        var position: Int
        /// How far apart the first and last matched words sit (0 for one word).
        var span = 0
        /// A word was reached only through its spelling correction.
        var fuzzy = false
        /// Skeleton tier only: a skeleton matched a WHOLE Arabic word, not a run inside one.
        var whole = false
        /// A word was reached only through its stem (for Arabic that is a run of letters, which may
        /// sit inside an unrelated word).
        var stem = false
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
    /// `latin` is the translation lane: a word-start hit earns `prefixBonus` there.
    private static func tokenHit(_ text: [UInt8], token: Token, weight: Int, latin: Bool) -> FieldScore? {
        if let at = find(token.textBytes, in: text) {
            // The best-placed occurrence decides the worth AND the position: a word standing alone
            // later in the ayah counts as that, not as the run inside another word before it.
            if let whole = find(token.textPadded, in: text) {
                return FieldScore(score: weight + wholeWordBonus, matched: 1, position: units(before: whole, in: text))
            }
            if latin, let start = find(token.textLeading, in: text) {
                return FieldScore(score: weight + (token.romanised ? -romanisedPrefixPenalty : prefixBonus), matched: 1,
                                  position: units(before: start, in: text))
            }
            return FieldScore(score: weight - (latin && token.romanised ? romanisedInsidePenalty : 0), matched: 1,
                              position: units(before: at, in: text))
        }
        // Another spelling of the word (Arabic only, and only when the typed one stands whole
        // nowhere): worth what the typed word would have been.
        for (index, alternate) in token.alternateBytes.enumerated() {
            guard let at = find(alternate, in: text) else { continue }
            if let whole = find(token.alternatePadded[index], in: text) {
                return FieldScore(score: weight + wholeWordBonus, matched: 1, position: units(before: whole, in: text))
            }
            return FieldScore(score: weight, matched: 1, position: units(before: at, in: text))
        }
        for stem in token.stemBytes {
            if let at = find(stem, in: text) {
                return FieldScore(score: weight - stemPenalty, matched: 1, position: units(before: at, in: text), stem: true)
            }
        }
        if let fuzzy = token.fuzzyBytes, let at = find(fuzzy, in: text) {
            let whole = token.fuzzyPadded.map { contains($0, in: text) } ?? false
            return FieldScore(score: weight - fuzzyPenalty + (whole ? wholeWordBonus : 0), matched: 1,
                              position: units(before: at, in: text), fuzzy: true)
        }
        return nil
    }

    /// `blocked` marks the words this row may not count (one per token, see `Token.hamza`).
    private static func scoreField(_ text: [UInt8], query: Query, weight: Int, latin: Bool = false,
                                   blocked: [Bool]? = nil) -> FieldScore? {
        var score = 0
        var matched = 0
        var fuzzy = false
        var stem = false
        var position = Int.max
        var last = 0
        for (index, token) in query.tokens.enumerated() {
            if let blocked, blocked[index] { continue }
            guard let hit = tokenHit(text, token: token, weight: weight, latin: latin) else { continue }
            score += hit.score
            matched += 1
            if hit.fuzzy { fuzzy = true }
            if hit.stem { stem = true }
            position = Swift.min(position, hit.position)
            last = Swift.max(last, hit.position)
        }
        guard matched > 0 else { return nil }
        // The folded phrase has lost its hamza, so a row that was refused a word cannot earn it.
        let anyBlocked = blocked?.contains(true) ?? false
        if query.tokens.count > 1, !anyBlocked, !query.phraseBytes.isEmpty, contains(query.phraseBytes, in: text) {
            score += phraseBonus
            if contains(query.phrasePadded, in: text) { score += wholePhraseBonus }
        }
        let first = position == Int.max ? 0 : position
        return FieldScore(score: score, matched: matched, position: first, span: matched > 1 ? last - first : 0,
                          fuzzy: fuzzy, stem: stem)
    }

    /// `whole` is what a skeleton standing as a whole Arabic word is worth, `inside` a run inside one;
    /// `phrase` is added when a several-word query is found as ONE run.
    private static func scoreSkeleton(words: [UInt8], tight: [UInt8], query: Query,
                                      whole wholeScore: Int, inside insideScore: Int, phrase: Int,
                                      blocked: [Bool]? = nil) -> FieldScore? {
        // Adjacency is the whole precision story for a multi-word query, so it is matched as ONE run
        // against the tight view: "qul huwa allahu" must not be satisfied by three fragments.
        let joined = query.joinedSkeleton
        let anyBlocked = blocked?.contains(true) ?? false
        if query.tokens.count > 1, !anyBlocked, joined.count >= minSkeletonLength, let at = find(joined, in: tight) {
            return FieldScore(score: wholeScore * query.tokens.count + phrase, matched: query.tokens.count,
                              position: units(before: at, in: tight), whole: true)
        }
        var score = 0
        var matched = 0
        var whole = false
        var position = Int.max
        for (index, token) in query.tokens.enumerated() {
            if let blocked, blocked[index] { continue }
            if !token.shortSkeletonNeedles.isEmpty {
                var found: Int?
                for needle in token.shortSkeletonNeedles {
                    if let at = find(needle, in: words) { found = Swift.min(found ?? Int.max, at) }
                }
                guard let at = found else { continue }
                score += wholeScore
                whole = true
                matched += 1
                position = Swift.min(position, units(before: at, in: words))
                continue
            }
            guard let skeleton = token.skeletonBytes, let padded = token.skeletonPadded else { continue }
            if let at = find(skeleton, in: words) {
                if let standing = find(padded, in: words) {
                    score += wholeScore
                    whole = true
                    position = Swift.min(position, units(before: standing, in: words))
                } else {
                    score += insideScore
                    position = Swift.min(position, units(before: at, in: words))
                }
            } else if let at = find(skeleton, in: tight) {
                // One romanised token routinely spans two Arabic ones ("alhamdulillah" is الحمد لله).
                // A long one is paid like a whole word: six consonants across a word break is no accident.
                score += skeleton.count >= minSkeletonLength ? wholeScore : insideScore
                position = Swift.min(position, units(before: at, in: tight))
            } else {
                continue
            }
            matched += 1
        }
        guard matched > 0 else { return nil }
        return FieldScore(score: score, matched: matched, position: position == Int.max ? 0 : position, whole: whole)
    }

    /// The earliest occurrence of any of `needles`, or nil.
    private static func firstHit(of needles: [[UInt8]], in haystack: [UInt8]) -> Int? {
        var earliest: Int?
        for needle in needles {
            if let at = find(needle, in: haystack), at < (earliest ?? Int.max) { earliest = at }
        }
        return earliest
    }

    /// What the query is worth against one ayah's transliteration outlines, or nil. `text` is the
    /// ayah's Latin lane, for the literal-start nudge (see `Token.literalStart`).
    private static func scoreRoman(words: [UInt8], tight: [UInt8], text: [UInt8], query: Query) -> FieldScore? {
        // A romanised phrase is matched as ONE run first, for the same reason the skeleton is.
        for joined in query.joinedRoman {
            if let at = find(joined, in: tight) {
                return FieldScore(score: romanWhole * query.tokens.count + phraseBonus, matched: query.tokens.count,
                                  position: at, whole: true)
            }
        }
        var score = 0
        var matched = 0
        var whole = false
        var position = Int.max
        for token in query.tokens {
            var best = 0
            var bestAt = 0
            for key in token.romanKeys {
                var worth = 0
                var at = 0
                if let hit = firstHit(of: key.wholes, in: words) {
                    worth = romanWhole; at = hit
                } else if key.full.count >= minRomanTight, let hit = find(key.full, in: tight) {
                    worth = romanTight; at = hit
                } else if key.bare.count >= minRomanEdge, let hit = firstHit(of: key.endings, in: words) {
                    worth = romanEnding; at = hit
                } else if key.bare.count >= minRomanEdge, let hit = find(key.leading, in: words) {
                    worth = romanStart; at = hit
                } else if key.bare.count >= minRomanInside, let hit = find(key.bare, in: words) {
                    worth = romanInside; at = hit
                }
                if worth > best { best = worth; bestAt = at }
            }
            guard best > 0 else { continue }
            score += best
            if let start = token.literalStart, contains(start, in: text) { score += 1 }
            matched += 1
            if best >= romanEnding { whole = true }
            position = Swift.min(position, bestAt)
        }
        guard matched > 0 else { return nil }
        return FieldScore(score: score, matched: matched, position: position == Int.max ? 0 : position, whole: whole)
    }

    private struct Candidate {
        let index: Int
        let score: Int
        let matched: Int
        /// Reached through the consonant skeleton alone (see the last-resort rule in `search`).
        var viaSkeleton = false
        /// Reached through the transliteration's sound outlines.
        var viaRoman = false
        /// The winning lane reached the query only through a spelling correction.
        var viaFuzzy = false
        /// The row is here only by its SOUND: the words themselves covered less of the query.
        var guessed = false
        /// A romanised reading (outline or skeleton) matched this row too, whichever lane won it...
        var echo = false
        /// ...and matched a whole word (or the start of one), not a run inside one.
        var echoWhole = false
        /// Arabic: the row carries the query only as a stem's run of letters, maybe inside another word.
        var viaStem = false
        /// Arabic: the skeleton tier won the row with a WHOLE word.
        var skeletonWhole = false
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
        // One Latin letter is in most of the Quran: nothing to rank, and the exact scan lists it.
        if !trimmed.containsArabicLetters, trimmed.filter(\.isLetter).count < 2 { return Outcome() }
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
        // The TRANSLATIONS' words, not the transliteration's: a romanised word is exactly the kind
        // the tier exists for, and the transliteration spells each one a single way.
        let useSkeleton = query.tokens.contains { !$0.rawSkeleton.isEmpty && !lanes.translationWords.contains($0.text) }
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
            var span = 0
            var viaSkeleton = false
            var viaRoman = false
            var viaFuzzy = false
            var echo = false
            var echoWhole = false
            var worded = 0
            var viaStem = false
            var skeletonWhole = false

            if query.isArabic {
                // A word typed with a bare ء counts only where this row's hamza lane carries it, the
                // exact scan's own rule: "ماء" folds to "ما", and the particle's ayahs led the list
                // above the 177 with water in them (2026-10-04; سوء, جاء, نساء alike).
                var blocked: [Bool]?
                if query.filtersHamza {
                    let lane = entries[index].hamzaArabicBlob
                    let refused = query.tokens.map { token in token.hamza.map { !$0.matches(lanes: lane) } ?? false }
                    if !refused.contains(false) { continue }
                    blocked = refused
                }
                var field = scoreField(arabicText, query: query, weight: arabicWeight, blocked: blocked)
                if field == nil || field!.matched < query.tokens.count {
                    if let stemmed = scoreField(lanes.arabicStems[index], query: query, weight: arabicWeight - stemPenalty,
                                                blocked: blocked),
                       stemmed.matched > (field?.matched ?? 0) {
                        field = stemmed
                    }
                    let base = Swift.max(1, arabicWeight - skeletonPenalty)
                    if useSkeleton, (field?.matched ?? 0) < query.tokens.count,
                       let skeleton = scoreSkeleton(words: lanes.skeletonWords[index], tight: lanes.skeletonTight[index],
                                                    query: query, whole: base + wholeWordBonus, inside: base, phrase: 0,
                                                    blocked: blocked),
                       skeleton.matched > (field?.matched ?? 0) {
                        field = skeleton
                        viaSkeleton = true
                    }
                }
                if let field {
                    score = field.score
                    matched = field.matched
                    position = field.position
                    span = field.span
                    viaStem = field.stem && !viaSkeleton
                    skeletonWhole = viaSkeleton && field.whole
                }
            } else {
                if let direct = scoreField(englishText, query: query, weight: englishWeight, latin: true) {
                    score = direct.score
                    matched = direct.matched
                    position = direct.position
                    span = direct.span
                    viaFuzzy = direct.fuzzy
                    worded = direct.matched
                }
                // A romanised query reaches the Arabic through its SOUND: first the transliteration's
                // outlines, then the consonant skeleton. Both rank below the words: someone typing
                // Latin letters usually means the words, and only sometimes the sound. A row the words
                // reached only through a spelling correction is asked as well, so the contest below
                // can tell a row carrying the Arabic word from one carrying the corrector's guess.
                //
                // The outlines are asked of EVERY row once the query holds a romanised word, and win a
                // row they answer better: "salah" found as the start of "sa-alahaa" must not keep the
                // row from being read as what it is, and "sabr" is the whole word in "sabru".
                if useSkeleton, let roman = scoreRoman(words: lanes.romanWords[index], tight: lanes.romanTight[index],
                                                       text: englishText, query: query) {
                    echo = true
                    echoWhole = roman.whole
                    if roman.matched > matched || (roman.matched == matched && (viaFuzzy || roman.score > score)) {
                        score = roman.score
                        matched = roman.matched
                        position = roman.position
                        span = 0
                        viaRoman = true
                        viaFuzzy = false
                    }
                }
                if useSkeleton, matched < query.tokens.count || viaFuzzy,
                   let skeleton = scoreSkeleton(words: lanes.skeletonWords[index], tight: lanes.skeletonTight[index],
                                                query: query, whole: latinSkeletonWhole, inside: latinSkeletonInside,
                                                phrase: phraseBonus) {
                    echo = true
                    if skeleton.whole { echoWhole = true }
                    if skeleton.matched > matched {
                        score = skeleton.score
                        matched = skeleton.matched
                        position = skeleton.position
                        span = 0
                        viaSkeleton = true
                        viaRoman = false
                        viaFuzzy = false
                    }
                }
            }

            guard matched > 0 else { continue }
            // Quality first, scaled clear of the tie-breakers: covering the query, then how each word
            // matched. Brevity, position and nearness only order rows the quality cannot tell apart.
            score += Int((Double(coverageWeight * matched) / Double(query.tokens.count)).rounded())
            score *= qualityScale
            score += Swift.max(0, brevityWeight - lanes.wordCounts[index] / brevityWordsPerPoint)
            score += Swift.max(0, positionWeight - position / positionCharsPerPoint)
            if matched > 1 { score += Swift.max(0, proximityWeight - span / proximityCharsPerPoint) }
            if matched > best { best = matched }
            candidates.append(Candidate(index: index, score: score, matched: matched, viaSkeleton: viaSkeleton,
                                        viaRoman: viaRoman, viaFuzzy: viaFuzzy,
                                        guessed: (viaRoman || viaSkeleton) && worded < matched,
                                        echo: echo, echoWhole: echoWhole,
                                        viaStem: viaStem, skeletonWhole: skeletonWhole))
        }

        // Everything carrying the WHOLE query, or, when nothing does, the rows covering the most of it.
        //
        // For an ARABIC query the skeleton is the LAST resort: when any ayah carries the words themselves
        // (as typed or by stem), the rows that only share their consonants stand down. Without this a run of consonants
        // across a word break outranked the word with a prefix on it: "الصبر" led with 23:86
        // (ٱلسَّبۡعِ وَرَبُّ reads l-s-b-r), above every بِٱلصَّبۡرِ in the Quran.
        var kept = candidates.filter { $0.matched == best }
        var corrections = query.corrections
        var romanised = false
        if query.isArabic {
            // ...but only rows that carry a typed WORD count as the words. A stem is a run of letters
            // and may sit inside another word: "الصلاة" found صلاه inside يَصۡلَىٰهَا ("burn in it",
            // 92:15 and 17:18), and those two rows threw out the 61 ayahs whose ٱلصَّلَوٰةَ the skeleton
            // matched whole (2026-10-04; الزكاة, الحياة, السموات alike). With stems alone, whole-word
            // skeleton rows stay beside them, and outscore them.
            let direct = kept.filter { !$0.viaSkeleton }
            if direct.contains(where: { !$0.viaStem }) {
                kept = direct
            } else if !direct.isEmpty {
                kept = kept.filter { !$0.viaSkeleton || $0.skeletonWhole }
            }
        } else if useSkeleton {
            // A one-word query the corrector "fixed" that is also a whole Arabic word in a few ayahs
            // was a romanisation, not a typo. The correction goes, and with it the rows only the
            // correction reached; a row carrying the Arabic word as well stays.
            if query.tokens.count == 1, corrections.count == 1,
               kept.reduce(0, { $0 + ($1.echoWhole ? 1 : 0) }) >= romanisedMinWholeWords {
                romanised = true
                corrections = []
                kept = kept.filter { !$0.viaFuzzy || $0.echo }
            } else {
                // A typo ("patiance") or a half-typed word ("forgiv") is no word of the translations
                // either, so the romanised tiers fire and guess at rows that have nothing to do with
                // what was meant. When the words answered in more ayahs than the guess did, the
                // guesses go. A romanisation the text carries nowhere is untouched: there the sound
                // IS the answer.
                let guessed = kept.reduce(0) { $0 + ($1.guessed ? 1 : 0) }
                if guessed > 0, kept.count - guessed > guessed {
                    kept = kept.filter { !$0.guessed }
                }
            }
            // The consonant skeleton is the last resort here too: it reads Arabic LETTERS, so "tawbah"
            // (t-b-h) is also تتبعها, while the transliteration tells the two apart. Once the words or
            // the outlines answered anywhere, the rows only the skeleton reached stand down.
            let heard = kept.filter { !$0.viaSkeleton }
            if !heard.isEmpty { kept = heard }
        }
        kept.sort { $0.score != $1.score ? $0.score > $1.score : $0.index < $1.index }
        var outcome = Outcome()
        outcome.total = kept.count
        outcome.hits = kept.prefix(limit).map { entries[$0.index] }
        outcome.corrections = corrections
        outcome.relaxed = best > 0 && best < query.tokens.count
        // The typed words with their corrections applied: what the rows should paint.
        outcome.highlightQuery = query.tokens.map { romanised ? $0.text : $0.highlight }.joined(separator: " ")
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

    // MARK: - Sound outlines

    /// A romanised word reduced to how it sounds in outline, the same way on both sides: the query
    /// word and every word of the app's transliteration. Nobody spells romanised Arabic one way
    /// ("tawbah" / "tauba", "shaytan" / "shaitan", "Rahmaan" / "Rahman"), and the transliteration
    /// spells each word a single way, so a typed spelling rarely matches it letter for letter. In
    /// outline they agree:
    ///
    ///   - a run of vowels is ONE vowel, of one of two kinds by its first letter: a, e and i are
    ///     "a"; o and u are "u". How long a vowel is and which of a/e/i it is are a writer's choice
    ///     ("Rahmaan" / "Rahman", "Muslim" / "Moslem"); a/i against u is not ("salaah" the prayer,
    ///     "sallooh" burn him, "su-ilat" she is asked)
    ///   - w and y are vowels unless a vowel follows them ("yawm" / "yaum", "shaytan" / "shaitan");
    ///     before a vowel they are the consonant ("tawwaab", "qaiyoom")
    ///   - doubled letters collapse (shadda is written "bb" or "b")
    ///   - sh, kh and gh are one sound each; c is k, p is b, v is w
    ///
    /// q stays apart from k: the transliteration always writes ق as q, and most people type it so.
    /// Unlike the consonant skeleton this keeps WHERE the vowels fall, so "kufr" is not "kafara"
    /// and "sabr" is not "saabir", and it reads the transliteration rather than the Arabic letters,
    /// so "tawbah" is not "tatba'uhaa".
    static func romanKey(_ word: String) -> [UInt8] {
        var letters: [UInt8] = []
        letters.reserveCapacity(word.utf8.count)
        for byte in word.utf8 where byte >= 0x61 && byte <= 0x7A { letters.append(byte) }
        var out: [UInt8] = []
        out.reserveCapacity(letters.count)
        func isVowel(_ byte: UInt8) -> Bool {
            byte == 0x61 || byte == 0x65 || byte == 0x69 || byte == 0x6F || byte == 0x75
        }
        // A vowel after a vowel belongs to the run already open (which keeps its first kind); a
        // consonant after itself is the same consonant doubled.
        func push(_ symbol: UInt8) {
            if let last = out.last, last == symbol || (isOutlineVowel(symbol) && isOutlineVowel(last)) { return }
            out.append(symbol)
        }
        var index = 0
        while index < letters.count {
            let letter = letters[index]
            let next: UInt8? = index + 1 < letters.count ? letters[index + 1] : nil
            switch letter {
            case 0x61, 0x65, 0x69:                                // a e i
                push(0x61)
            case 0x6F, 0x75:                                      // o u
                push(0x75)
            case 0x77:                                            // w
                if let next, isVowel(next) { push(letter) } else { push(0x75) }
            case 0x79:                                            // y
                if let next, isVowel(next) { push(letter) } else { push(0x61) }
            case 0x73 where next == 0x68:                         // sh
                push(0x53); index += 1
            case 0x6B where next == 0x68:                         // kh
                push(0x4B); index += 1
            case 0x67 where next == 0x68:                         // gh
                push(0x47); index += 1
            case 0x63 where next == 0x68:                         // ch, a French or Maghrebi sh
                push(0x53); index += 1
            case 0x63, 0x78:                                      // c x
                push(0x6B)
            case 0x70:                                            // p
                push(0x62)
            case 0x76:                                            // v
                push(0x77)
            default:
                push(letter)
            }
            index += 1
        }
        return out
    }

    /// The outline without the vowel a word ends on: the case ending in connected recitation
    /// ("tawbatu", "tawbata", "tawbati" are one word), and on the query side whatever vowel the
    /// writer closed the word with.
    static func strippedRomanKey(_ key: [UInt8]) -> [UInt8] {
        guard key.count > 2, let last = key.last, isOutlineVowel(last) else { return key }
        return Array(key.dropLast())
    }

    /// The two vowel symbols of an outline.
    static func isOutlineVowel(_ symbol: UInt8) -> Bool { symbol == 0x61 || symbol == 0x75 }

    /// Appends a word's outline to a run of them, merging across the join the way `romanKey` does
    /// inside a word, so the run reads the same however the words were divided.
    static func appendRun(_ key: [UInt8], to run: inout [UInt8]) {
        for symbol in key {
            if let last = run.last, last == symbol || (isOutlineVowel(symbol) && isOutlineVowel(last)) { continue }
            run.append(symbol)
        }
    }

    /// The ways the letters of one typed word can be read before it is reduced: as written; with
    /// "th" as ث and "dh" as ذ (the transliteration writes them s and z); with "dh" as ض
    /// ("ramadhan"); and with k as ق ("koran", "kadr").
    private static func letterReadings(_ word: String) -> [String] {
        var readings = [word]
        if word.contains("th") || word.contains("dh") {
            readings.append(word.replacingOccurrences(of: "th", with: "s").replacingOccurrences(of: "dh", with: "z"))
        }
        if word.contains("dh") {
            readings.append(word.replacingOccurrences(of: "dh", with: "d"))
        }
        if word.contains("k") {
            // Not the k of "kh", which is one sound of its own.
            let swapped = word.replacingOccurrences(of: "kh", with: "\u{1}")
                .replacingOccurrences(of: "k", with: "q").replacingOccurrences(of: "\u{1}", with: "kh")
            if swapped != word { readings.append(swapped) }
        }
        return readings
    }

    /// Every reading of one typed word as an outline. A final "-ah" is read twice: as the ta
    /// marbuta it usually is, "-at" in connected speech ("tawbah" is "tawbatu"), and as it stands,
    /// the way the word sounds at a pause.
    fileprivate static func romanKeys(for word: String) -> [RomanKey] {
        guard word.count >= minRomanKey, Lanes.isLatinWord(word) else { return [] }
        var seen = Set<[UInt8]>()
        var keys: [RomanKey] = []
        func add(_ reading: String, pauseForm: Bool) {
            let full = romanKey(reading)
            guard strippedRomanKey(full).count >= minRomanKey, seen.insert(full).inserted else { return }
            keys.append(RomanKey(full: full, pauseForm: pauseForm))
        }
        for reading in letterReadings(word) {
            if reading.count > 3, reading.hasSuffix("ah") || reading.hasSuffix("eh") {
                add(String(reading.dropLast()) + "t", pauseForm: false)
                add(reading, pauseForm: true)
            } else {
                add(reading, pauseForm: false)
            }
        }
        return keys
    }

    /// A several-word query as one run of outlines, per reading of its spelling.
    fileprivate static func joinedRomanKeys(for words: [String]) -> [[UInt8]] {
        guard words.allSatisfy(Lanes.isLatinWord) else { return [] }
        let readings: [(String) -> String] = [
            { $0 },
            { $0.replacingOccurrences(of: "th", with: "s").replacingOccurrences(of: "dh", with: "z") },
            { $0.replacingOccurrences(of: "dh", with: "d") },
        ]
        var seen = Set<[UInt8]>()
        var runs: [[UInt8]] = []
        for reading in readings {
            var run: [UInt8] = []
            for word in words { appendRun(romanKey(reading(word)), to: &run) }
            // The last word's closing vowel is the writer's, and the recitation may run on past it.
            let trimmed = strippedRomanKey(run)
            guard trimmed.count >= minRomanTight + 1, seen.insert(trimmed).inserted else { continue }
            runs.append(trimmed)
        }
        return runs
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

// MARK: - Ayahs known by a name

/// The ayahs people ask for by NAME. No text search can answer these: the name is in none of
/// them ("Ayat al-Kursi" is 2:255, whose text says "kursiyyuhu" once and "ayah" nowhere), so
/// "ayatul kursi" used to list the ayahs that open "tilka aayaatul kitaab". Only names every
/// reader means the same ayah by are here; a WHOLE query has to be the name, so "kursi" and
/// "light" stay ordinary searches.
enum NamedAyah {
    struct Entry: Equatable {
        let surah: Int
        let ayah: Int
        let title: String
    }

    private static let table: [(entry: Entry, latin: [String], arabic: [String])] = [
        (Entry(surah: 2, ayah: 255, title: "Ayat al-Kursi"),
         ["ayatul kursi", "ayat al kursi", "ayat kursi", "ayah al kursi", "ayah kursi", "ayathul kursi",
          "ayat ul kursi", "ayat el kursi", "ayatal kursiy", "throne verse", "the throne verse",
          "verse of the throne", "the verse of the throne"],
         ["آية الكرسي", "اية الكرسي", "آيه الكرسي"]),
        (Entry(surah: 24, ayah: 35, title: "Ayat an-Nur"),
         ["ayatun nur", "ayat an nur", "ayat al nur", "ayat nur", "ayah an nur", "ayat un nur", "ayat en nur",
          "light verse", "the light verse", "verse of light", "the verse of light"],
         ["آية النور", "اية النور"]),
        (Entry(surah: 2, ayah: 282, title: "Ayat ad-Dayn"),
         ["ayatud dayn", "ayat ad dayn", "ayat al dayn", "ayat dayn", "ayah ad dayn", "ayat ud dayn",
          "ayat al mudayanah", "ayatul mudayanah", "debt verse", "the debt verse", "verse of debt",
          "the verse of debt"],
         ["آية الدين", "اية الدين", "آية المداينة", "اية المداينة"]),
    ]

    /// Spaces and marks removed, then reduced to a sound outline, so "Ayatul Kursi", "ayat-ul-kursee"
    /// and "Āyat al-Kursī" are one name.
    private static func latinKey(_ text: String) -> [UInt8] {
        let letters = text.foldingLatinDiacritics.lowercased().filter { $0.isASCII && $0.isLetter }
        return QuranRankedSearch.strippedRomanKey(QuranRankedSearch.romanKey(String(letters)))
    }

    private static func arabicKey(_ text: String) -> String {
        Settings.shared.cleanSearch(text, whitespace: true).filter { !$0.isWhitespace }
    }

    private static let latinIndex: [[UInt8]: Entry] = {
        var index: [[UInt8]: Entry] = [:]
        for row in table { for name in row.latin { index[latinKey(name)] = row.entry } }
        return index
    }()

    private static let arabicIndex: [String: Entry] = {
        var index: [String: Entry] = [:]
        for row in table { for name in row.arabic { index[arabicKey(name)] = row.entry } }
        return index
    }()

    static func resolve(_ query: String) -> Entry? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        // Every name is between a handful and a few dozen letters, and none carries a digit.
        guard trimmed.count >= 7, trimmed.count <= 32,
              trimmed.rangeOfCharacter(from: .decimalDigits) == nil else { return nil }
        if trimmed.containsArabicLetters { return arabicIndex[arabicKey(trimmed)] }
        return latinIndex[latinKey(trimmed)]
    }
}
