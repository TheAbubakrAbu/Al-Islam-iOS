import Foundation

// The search fold, and the fingerprints that keep it honest.
//
// THIS FILE IS THE ORIGINAL. `tools/pack/build.sh` copies it verbatim into
// Al-Islam-iOS/iPhone/Hadith/HadithFold.swift - edit it HERE, never there.
//
// Why it exists in two places at all: the packs ship text that was folded at BUILD time, and a query
// is only ever found in that text if the query folds through the exact same rules at RUN time. The
// packer (this repo) and the app (the other one) must therefore agree scalar for scalar. Copying one
// file is the cheapest way to guarantee that, and `fingerprint` below is the alarm if the copy ever
// drifts: the packer stamps it into every pack, and the app refuses to trust the prebuilt search text
// unless its own fold produces the same value.
//
// The rules themselves are the ones the app has always used for hadith search:
//   English  strip punctuation/symbols/marks, lowercase
//   Arabic   canonical letter folds and mark stripping, then whitespace collapsing

enum HadithFold {

    // MARK: English

    /// Punctuation, symbols, and combining marks - dropped so "aishah" matches "'A'ishah" and
    /// "ﷺ" never sits between a query and its match.
    private static let englishStripSet: CharacterSet =
        CharacterSet.punctuationCharacters.union(.symbols).union(.nonBaseCharacters)

    /// The English fold: strip, then lowercase. No whitespace collapsing (the app's highlighter twin
    /// doesn't collapse either, and a query folded the same way lines up with it).
    static func english(_ text: String) -> String {
        String(text.unicodeScalars.filter { !englishStripSet.contains($0) }).lowercased()
    }

    // MARK: Arabic

    /// Canonical Arabic search folds: hamza carriers to bare letters, dagger alif to alif, alif
    /// maqsurah to alif, teh marbuta to heh. A `nil` value means "drop this scalar".
    private static let canonicalMap: [UnicodeScalar: UnicodeScalar?] = {
        let pairs: [(UInt32, UInt32?)] = [
            (0x0670, 0x0627),   // dagger alif -> alif
            (0x0671, 0x0627),   // hamzatul-wasl -> alif
            (0x0623, 0x0627),   // أ
            (0x0625, 0x0627),   // إ
            (0x0622, 0x0627),   // آ
            (0x0672, 0x0627),   // ٲ
            (0x0673, 0x0627),   // ٳ
            (0x0675, 0x0627),   // ٵ
            (0x0624, 0x0648),   // ؤ -> و
            (0x0626, 0x064A),   // ئ -> ي
            (0x0621, nil),      // bare hamza - dropped
            (0x0674, nil),      // high hamza - dropped
            (0x0676, 0x0648),   // ٶ -> و
            (0x0677, 0x0648),   // ٷ -> و
            (0x0678, 0x064A),   // ٸ -> ي
            (0x06E5, 0x0648),   // ۥ -> و
            (0x06E6, 0x064A),   // ۦ -> ي
            (0x0649, 0x0627),   // alif maqsurah -> alif
            (0x0629, 0x0647),   // teh marbuta -> heh
        ]
        var map: [UnicodeScalar: UnicodeScalar?] = [:]
        for (key, value) in pairs {
            guard let scalar = UnicodeScalar(key) else { continue }
            map.updateValue(value.flatMap { UnicodeScalar($0) }, forKey: scalar)
        }
        return map
    }()

    /// Punctuation/symbols/marks dropped from Arabic, minus the boolean-search operators the app's
    /// query parser owns.
    private static let unwantedSet: CharacterSet = {
        var set = CharacterSet.punctuationCharacters.union(.symbols).union(.nonBaseCharacters)
        set.remove(charactersIn: "&|!#")
        return set
    }()

    /// Tashkeel, Quranic annotation signs, and the loose marks.
    private static let stripScalars: Set<UnicodeScalar> = {
        var set = Set<UnicodeScalar>()
        for value in 0x064B...0x065F { if let scalar = UnicodeScalar(value) { set.insert(scalar) } }
        for value in 0x06D6...0x06ED { if let scalar = UnicodeScalar(value) { set.insert(scalar) } }
        for value in [0x0670, 0x0657, 0x0674, 0x0656] {
            if let scalar = UnicodeScalar(value) { set.insert(scalar) }
        }
        return set
    }()

    /// The Arabic fold: the canonical letter folds and whitespace collapsing, then the diacritic and
    /// sign strip - in that order, because the second pass reads what the first one produced.
    static func arabic(_ text: String) -> String {
        var built = String.UnicodeScalarView()
        built.reserveCapacity(text.unicodeScalars.count)
        for scalar in text.unicodeScalars {
            if let mapped = canonicalMap[scalar] {
                guard let replacement = mapped else { continue }
                if unwantedSet.contains(replacement) { continue }
                built.append(replacement)
            } else {
                if unwantedSet.contains(scalar) { continue }
                built.append(scalar)
            }
        }

        let collapsed = String(built).lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        var out = String.UnicodeScalarView()
        out.reserveCapacity(collapsed.unicodeScalars.count)
        for scalar in collapsed.unicodeScalars {
            if scalar.value == 0x0671 {
                out.append(UnicodeScalar(0x0627)!)
            } else if !stripScalars.contains(scalar) {
                out.append(scalar)
            }
        }
        return String(out)
    }

    // MARK: Queries

    /// Whether the text carries Arabic script - the same script test the search screens use to decide
    /// which field a query can possibly match.
    static func isArabicScript(_ text: String) -> Bool {
        text.unicodeScalars.contains {
            (0x0600...0x06FF).contains($0.value)
                || (0x0750...0x077F).contains($0.value)
                || (0x08A0...0x08FF).contains($0.value)
        }
    }

    /// A folded query, kept as UTF-8 bytes: matching runs as a byte search inside a decompressed
    /// pack block, so a keystroke never allocates a String per hadith.
    struct Query {
        /// The folded query, UTF-8.
        let bytes: [UInt8]
        /// Arabic queries are matched against the Arabic fold only, Latin ones against the English -
        /// the script-aware rule the search screens have always applied.
        let isArabic: Bool
        /// The folded query as text, for the paths that still match Strings (chapter names).
        let folded: String

        var isEmpty: Bool { bytes.isEmpty }
    }

    /// Fold a raw query the way its script demands.
    static func query(_ raw: String) -> Query {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let isArabic = isArabicScript(trimmed)
        let folded = isArabic ? arabic(trimmed) : english(trimmed)
        return Query(bytes: Array(folded.utf8), isArabic: isArabic, folded: folded)
    }

    // MARK: Fingerprints

    /// FNV-1a, 64-bit. Deliberately NOT Swift's `Hasher`, which is seeded per process and would give a
    /// different answer in the packer than in the app - the one thing a fingerprint must never do.
    static func fingerprint(of text: String) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01B3
        }
        return hash
    }

    /// Strings chosen to exercise every rule above: hamza carriers, dagger alif, alif maqsurah, teh
    /// marbuta, tashkeel, Quranic signs, the salawat ligature, apostrophes, punctuation, digits, and
    /// whitespace collapsing. Change a fold rule and at least one of these changes with it.
    static let probes: [String] = [
        "إنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ",
        "قَالَ رَسُولُ اللَّهِ ﷺ",
        "ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ",
        "الصَّلَاةُ خَيْرٌ مِنَ النَّوْمِ",
        "أَبُو هُرَيْرَةَ، ؤ، ئ، ء، ٱ، ى، ة، ٰ",
        "مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الْآخِرِ",
        "Narrated 'A'ishah (may Allah be pleased with her):",
        "The Messenger of Allah (ﷺ) said: \"Actions are (judged) by motives (niyyah)\"",
        "Mu'adh ibn Jabal - [of His] - Abu Dawud 1:23",
        "  doubled   spaces\tand\ttabs\nand\nnewlines  ",
        "MiXeD CaSe, punctuation!? and symbols +=%$#@ and digits 0123456789",
        "",
    ]

    /// One value standing for the whole fold: every probe run through BOTH folds, hashed. The packer
    /// writes it into each pack; the app checks its own against it before trusting prebuilt text.
    static var foldFingerprint: UInt64 {
        var joined = ""
        for probe in probes {
            joined += arabic(probe)
            joined += "\u{1}"
            joined += english(probe)
            joined += "\u{2}"
        }
        return fingerprint(of: joined)
    }

    /// The fingerprint of a daily-card blocked-word list: order-independent, so the two copies only
    /// have to agree on CONTENT. The packer stamps the list it used into the pack, and the app
    /// compares its own - a mismatch just means the app rechecks the words itself instead of trusting
    /// the precomputed flag, so an edit on one side can never produce a wrong daily card.
    static func wordListFingerprint(_ words: Set<String>) -> UInt64 {
        fingerprint(of: words.map { $0.lowercased() }.sorted().joined(separator: "\n"))
    }
}
