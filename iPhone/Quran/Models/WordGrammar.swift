#if os(iOS)
import SwiftUI

// The grammar of every word of the Quran, split into its segments (prefix, stem, suffix), from
// `Resources/Data/Quran/WordGrammar.json.xz` (Scripts/build_word_grammar.py): the Quranic Arabic Corpus
// morphology (Kais Dukes), as Tilawa ships it, mapped onto THIS APP's raw Hafs tokens at build time.
// The word card (WordByWord.swift) reads it for its Grammar page and to light one part of the word.
//
// THE INVARIANT: like the gloss and root packs, one entry per whitespace token of the app's raw Hafs
// text. A segment's text is cut out of the app's OWN token by counting base letters (Tilawa's rule,
// `slice` below and `slice_by_letters` in the builder are twins); the builder keeps a count only
// where the token's letters add up, and spells the 14 words it cannot cut.
//
// The labels and the two sentence builders (`describe`, `facts`) are Tilawa's
// (src/data/morphologyLabels.ts, src/data/wordMorphology.ts), English only, with Abu's permission.

/// One morphological segment of a word, in reading order.
struct WordSegment: Equatable, Identifiable {
    enum Kind: String {
        case prefix, stem, suffix

        var title: String {
            switch self {
            case .prefix: return String(localized: "Prefix")
            case .stem: return String(localized: "Stem")
            case .suffix: return String(localized: "Suffix")
            }
        }
    }

    let index: Int
    /// The segment's letters with their marks. Empty for an implied segment (the elided "my" of يَٰقَوۡمِ).
    let form: String
    /// Corpus part-of-speech tag: N, V, PRON, P, ...
    let tag: String
    let kind: Kind
    /// The remaining corpus feature tokens, as written: "MS", "GEN", "PERF", "(IV)", "PRON:3MS", ...
    let features: [String]

    var id: Int { index }
    var isImplied: Bool { form.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}

/// A word's segments, and whether they were cut from the token itself (so their texts join back into
/// the word and one can be colored inside it).
struct WordGrammar: Equatable {
    let segments: [WordSegment]
    let isCutFromToken: Bool

    /// The stem: the segment the word's part of speech, root and analysis belong to.
    var stem: WordSegment? { segments.first { $0.kind == .stem } }
}

final class WordGrammarStore: @unchecked Sendable {
    static let shared = WordGrammarStore()
    private init() {}

    static let isBundled: Bool = ThemesPack.url("WordGrammar") != nil

    private struct Signature {
        let tag: String
        let kind: WordSegment.Kind
        let features: [String]
    }

    private struct Table {
        let signatures: [Signature]
        let forms: [String]
        /// surah id (as a string) -> ayahs -> tokens -> [sig, n, sig, n, ...]; cast per surah on use.
        let words: [String: Any]
    }

    private let lock = NSLock()
    private var table: Table?
    private var loadFailed = false
    private var surahs: [Int: [[[Int]]]] = [:]

    // MARK: Lookups

    /// The grammar of one token of the ayah's RAW Hafs text. `tokenText` is that token (the text the
    /// counts cut); nil when the pack is missing or says nothing about the word.
    func grammar(surah: Int, ayah: Int, token: Int, tokenText: String) -> WordGrammar? {
        guard let table = loadedTable(), let ayahs = rows(surah: surah, table: table),
              ayahs.indices.contains(ayah - 1), ayahs[ayah - 1].indices.contains(token) else { return nil }
        let flat = ayahs[ayah - 1][token]
        guard flat.count >= 2, flat.count.isMultiple(of: 2) else { return nil }

        var signatures: [Signature] = []
        var counts: [Int] = []
        for pair in stride(from: 0, to: flat.count, by: 2) {
            guard table.signatures.indices.contains(flat[pair]) else { return nil }
            signatures.append(table.signatures[flat[pair]])
            counts.append(flat[pair + 1])
        }

        let forms: [String]
        let cut: Bool
        if counts.allSatisfy({ $0 >= 0 }),
           counts.reduce(0, +) == Self.baseLetterCount(tokenText) {
            forms = Self.slice(tokenText, counts: counts)
            cut = true
        } else {
            // Spelled out by the builder (or a count that no longer fits the text: never cut wrong).
            forms = counts.map { count in
                let index = -count - 1
                return count < 0 && table.forms.indices.contains(index) ? table.forms[index] : ""
            }
            cut = false
        }
        let segments = signatures.enumerated().map { index, signature in
            WordSegment(index: index, form: forms[index], tag: signature.tag,
                        kind: signature.kind, features: signature.features)
        }
        return WordGrammar(segments: segments, isCutFromToken: cut)
    }

    /// Parses the pack off the calling thread's critical path.
    static func prewarm() {
        guard isBundled else { return }
        Task.detached(priority: .utility) {
            _ = WordGrammarStore.shared.loadedTable()
        }
    }

    func unload() {
        lock.lock(); defer { lock.unlock() }
        table = nil
        surahs = [:]
        loadFailed = false
    }

    // MARK: Slicing (Tilawa's rule; Scripts/build_word_grammar.py is its twin)

    /// A consonant or long vowel. Every other scalar (tashkeel, hamza marks, the dagger alif,
    /// annotation marks, the tatweel) rides on the letter before it.
    static func isBaseLetter(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x0621...0x063A, 0x0641...0x064A, 0x0671, 0x066E, 0x066F, 0x06CC: return true
        default: return false
        }
    }

    /// The word without a trailing, space-separated pause mark (" ۖ"), which belongs to no segment.
    static func coreScalars(_ text: String) -> [Unicode.Scalar] {
        var scalars = Array(text.unicodeScalars)
        // Trailing whitespace, then pause marks, then the whitespace before them.
        var end = scalars.count
        while end > 0, CharacterSet.whitespacesAndNewlines.contains(scalars[end - 1]) { end -= 1 }
        var markEnd = end
        while markEnd > 0, (0x06D6...0x06ED).contains(scalars[markEnd - 1].value) { markEnd -= 1 }
        if markEnd < end, markEnd > 0, CharacterSet.whitespacesAndNewlines.contains(scalars[markEnd - 1]) {
            end = markEnd
            while end > 0, CharacterSet.whitespacesAndNewlines.contains(scalars[end - 1]) { end -= 1 }
        }
        scalars = Array(scalars[..<end])
        var start = 0
        while start < scalars.count, CharacterSet.whitespacesAndNewlines.contains(scalars[start]) { start += 1 }
        return Array(scalars[start...])
    }

    static func baseLetterCount(_ text: String) -> Int {
        coreScalars(text).reduce(0) { $0 + (isBaseLetter($1) ? 1 : 0) }
    }

    /// The word cut into pieces of `counts` base letters each; the last piece takes the rest.
    static func slice(_ text: String, counts: [Int]) -> [String] {
        let scalars = coreScalars(text)
        var parts: [String] = []
        var i = 0
        for (k, count) in counts.enumerated() {
            let start = i
            var taken = 0
            while i < scalars.count, taken < count {
                if isBaseLetter(scalars[i]) { taken += 1 }
                i += 1
            }
            while i < scalars.count, !isBaseLetter(scalars[i]), scalars[i] != " " { i += 1 }
            if k == counts.count - 1 { i = scalars.count }
            var piece = String.UnicodeScalarView()
            piece.append(contentsOf: scalars[start..<i])
            parts.append(String(piece).trimmingCharacters(in: .whitespaces))
        }
        return parts
    }

    // MARK: Loading

    private func rows(surah: Int, table: Table) -> [[[Int]]]? {
        lock.lock()
        if let cached = surahs[surah] { lock.unlock(); return cached }
        lock.unlock()
        guard let rows = table.words[String(surah)] as? [[[Int]]] else { return nil }
        lock.lock(); defer { lock.unlock() }
        surahs[surah] = rows
        return rows
    }

    private func loadedTable() -> Table? {
        lock.lock()
        if let table { lock.unlock(); return table }
        if loadFailed { lock.unlock(); return nil }
        lock.unlock()

        guard let parsed = Self.load() else {
            lock.lock(); loadFailed = true; lock.unlock()
            return nil
        }
        lock.lock(); defer { lock.unlock() }
        if let table { return table }
        table = parsed
        return parsed
    }

    private static func load() -> Table? {
        guard let root = ThemesPack.json("WordGrammar") as? [String: Any],
              let signatureRows = root["sig"] as? [String],
              let forms = root["forms"] as? [String],
              let words = root["w"] as? [String: Any] else { return nil }
        let signatures = signatureRows.map { row -> Signature in
            let parts = row.components(separatedBy: "|")
            let kind: WordSegment.Kind
            switch parts.count > 1 ? parts[1] : "s" {
            case "p": kind = .prefix
            case "x": kind = .suffix
            default: kind = .stem
            }
            return Signature(tag: parts.first ?? "", kind: kind, features: Array(parts.dropFirst(2)))
        }
        return signatures.isEmpty ? nil : Table(signatures: signatures, forms: forms, words: words)
    }
}

// MARK: - Plain-English labels (Tilawa's tables)

enum WordGrammarLabels {
    static let pos: [String: String] = [
        "N": String(localized: "Noun"), "PN": String(localized: "Proper noun"), "ADJ": String(localized: "Adjective"), "PRON": String(localized: "Pronoun"), "V": String(localized: "Verb"),
        "P": String(localized: "Preposition"), "CONJ": String(localized: "Conjunction"), "DET": String(localized: "Definite article"), "REL": String(localized: "Relative pronoun"),
        "DEM": String(localized: "Demonstrative"), "T": String(localized: "Time adverb"), "LOC": String(localized: "Location adverb"), "NEG": String(localized: "Negative particle"),
        "ACC": String(localized: "Accusative particle"), "EMPH": String(localized: "Emphatic particle"), "COND": String(localized: "Conditional particle"),
        "INTG": String(localized: "Question particle"), "SUB": String(localized: "Subordinating conjunction"), "RES": String(localized: "Restriction particle"),
        "CERT": String(localized: "Particle of certainty"), "VOC": String(localized: "Vocative particle"), "RSLT": String(localized: "Result particle"),
        "PRO": String(localized: "Prohibition particle"), "PRP": String(localized: "Purpose particle"), "CIRC": String(localized: "Circumstantial particle"),
        "SUP": String(localized: "Supplemental particle"), "PREV": String(localized: "Preventive particle"), "FUT": String(localized: "Future particle"),
        "RET": String(localized: "Retraction particle"), "EXP": String(localized: "Exception particle"), "INC": String(localized: "Inceptive particle"),
        "CAUS": String(localized: "Particle of cause"), "IMPV": String(localized: "Imperative particle"), "EXL": String(localized: "Explanation particle"),
        "AMD": String(localized: "Amendment particle"), "INT": String(localized: "Interpretive particle"), "EXH": String(localized: "Exhortation particle"),
        "ANS": String(localized: "Answer particle"), "SUR": String(localized: "Surprise particle"), "AVR": String(localized: "Aversion particle"),
        "INL": String(localized: "Quranic initials"), "EQ": String(localized: "Equalization particle"), "COM": String(localized: "Comitative particle"),
        "IMPN": String(localized: "Imperative verbal noun"), "REM": String(localized: "Resumption particle"),
    ]

    static let prefix: [String: String] = [
        "Al+": String(localized: "the"), "bi+": String(localized: "with, by, in"), "l:P+": String(localized: "for, to"), "l:EMPH+": String(localized: "indeed, surely"),
        "l:PRP+": String(localized: "so that, in order to"), "l:IMPV+": String(localized: "let, so command"), "w:CONJ+": String(localized: "and"),
        "w:REM+": String(localized: "and, resuming"), "w:CIRC+": String(localized: "while"), "w:SUP+": String(localized: "and, supplemental"), "w:P+": String(localized: "by, an oath"),
        "w:COM+": String(localized: "together with"), "f:CONJ+": String(localized: "and then"), "f:REM+": String(localized: "so, then"), "f:RSLT+": String(localized: "then, as a result"),
        "f:SUP+": String(localized: "then, supplemental"), "f:CAUS+": String(localized: "so, because of that"), "ka+": String(localized: "like, as"), "sa+": String(localized: "will, soon"),
        "ya+": String(localized: "O, calling"), "A:INTG+": String(localized: "is it? a question"), "A:EQ+": String(localized: "whether"), "ha+": String(localized: "behold"),
        "ta+": String(localized: "by, an oath"),
    ]

    static let feature: [String: String] = [
        "PERF": String(localized: "past tense"), "IMPF": String(localized: "present tense"), "IMPV": String(localized: "command"), "ACT": String(localized: "active"), "PASS": String(localized: "passive"),
        "VN": String(localized: "verbal noun"), "PCPL:ACT": String(localized: "active participle"), "PCPL:PASS": String(localized: "passive participle"),
        "PCPL": String(localized: "participle"), "INDEF": String(localized: "indefinite"), "DEF": String(localized: "definite"), "NOM": String(localized: "nominative"),
        "ACC": String(localized: "accusative"), "GEN": String(localized: "genitive"), "MOOD:IND": String(localized: "indicative"), "MOOD:SUBJ": String(localized: "subjunctive"),
        "MOOD:JUS": String(localized: "jussive"), "MOOD:ENG": String(localized: "energetic"), "SP:kaAn": String(localized: "kāna and its sisters"),
        "SP:<in~": String(localized: "inna and its sisters"), "SP:kaAd": String(localized: "kāda and its sisters"), "+n:EMPH": String(localized: "emphatic nun"),
        "+VOC": String(localized: "vocative ending"),
    ]

    static let verbForm: [String: String] = [
        "(I)": String(localized: "Form I (فَعَلَ)"), "(II)": String(localized: "Form II (فَعَّلَ)"), "(III)": String(localized: "Form III (فَاعَلَ)"),
        "(IV)": String(localized: "Form IV (أَفْعَلَ)"), "(V)": String(localized: "Form V (تَفَعَّلَ)"), "(VI)": String(localized: "Form VI (تَفَاعَلَ)"),
        "(VII)": String(localized: "Form VII (اِنْفَعَلَ)"), "(VIII)": String(localized: "Form VIII (اِفْتَعَلَ)"), "(IX)": String(localized: "Form IX (اِفْعَلَّ)"),
        "(X)": String(localized: "Form X (اِسْتَفْعَلَ)"), "(XI)": String(localized: "Form XI (اِفْعَالَّ)"), "(XII)": String(localized: "Form XII (اِفْعَوْعَلَ)"),
    ]

    static let person: [String: String] = ["1": String(localized: "first person"), "2": String(localized: "second person"), "3": String(localized: "third person")]
    static let gender: [String: String] = ["M": String(localized: "masculine"), "F": String(localized: "feminine")]
    static let number: [String: String] = ["S": String(localized: "singular"), "D": String(localized: "dual"), "P": String(localized: "plural")]

    static let pronoun: [String: String] = [
        "1S": String(localized: "I, me, my"), "1P": String(localized: "we, us, our"), "2MS": String(localized: "you (one man)"), "2FS": String(localized: "you (one woman)"),
        "2D": String(localized: "you two"), "2MD": String(localized: "you two"), "2FD": String(localized: "you two"), "2MP": String(localized: "you (all)"), "2FP": String(localized: "you (all, women)"),
        "3MS": String(localized: "he, him, his"), "3FS": String(localized: "she, her"), "3D": String(localized: "they two"), "3MD": String(localized: "they two"), "3FD": String(localized: "they two"),
        "3MP": String(localized: "they, them, their"), "3FP": String(localized: "they (women)"),
    ]

    /// One plain sentence under a few analysis values, for a reader who has never met the term.
    static let explainer: [String: String] = Dictionary([
        (String(localized: "nominative"), String(localized: "The subject's case; the word usually ends in -u.")),
        (String(localized: "accusative"), String(localized: "The object's case; the word usually ends in -a.")),
        (String(localized: "genitive"), String(localized: "After a preposition, or the owner in a possessive; the word usually ends in -i.")),
        (String(localized: "past tense"), String(localized: "A completed action.")),
        (String(localized: "present tense"), String(localized: "An action going on, or still to come.")),
        (String(localized: "command"), String(localized: "An order or a request.")),
        (String(localized: "indefinite"), String(localized: "Without al-: \u{201C}a\u{201D} or \u{201C}an\u{201D}.")),
        (String(localized: "definite"), String(localized: "With al-: \u{201C}the\u{201D}.")),
        (String(localized: "active participle"), String(localized: "The doer: one who does the action.")),
        (String(localized: "passive participle"), String(localized: "The one the action is done to.")),
        (String(localized: "verbal noun"), String(localized: "The action itself as a noun.")),
        (String(localized: "jussive"), String(localized: "A verb after لَمْ, لَا of forbidding, or a condition.")),
        (String(localized: "subjunctive"), String(localized: "A verb after أَنْ, لَنْ, كَيْ and similar particles.")),
    ], uniquingKeysWith: { first, _ in first })
}

// MARK: - Sentences

enum WordGrammarText {
    static let separator = " · "

    /// "3MS" -> (3, M, S); nil for anything that is not a person/gender/number code.
    static func personCode(_ token: String) -> (person: String?, gender: String?, number: String?)? {
        guard !token.isEmpty, token.count <= 3 else { return nil }
        var scalars = Array(token)
        var person: String?
        var gender: String?
        var number: String?
        if let first = scalars.first, "123".contains(first) { person = String(first); scalars.removeFirst() }
        if let first = scalars.first, "MF".contains(first) { gender = String(first); scalars.removeFirst() }
        if let first = scalars.first, "SDP".contains(first) { number = String(first); scalars.removeFirst() }
        guard scalars.isEmpty else { return nil }
        return (person, gender, number)
    }

    static func personPhrase(_ code: (person: String?, gender: String?, number: String?)?) -> String {
        guard let code else { return "" }
        return [code.person.flatMap { WordGrammarLabels.person[$0] },
                code.gender.flatMap { WordGrammarLabels.gender[$0] },
                code.number.flatMap { WordGrammarLabels.number[$0] }]
            .compactMap { $0 }.joined(separator: " ")
    }

    /// One line for one segment: "Preposition · with, by, in", "Noun · masculine singular · genitive",
    /// "Pronoun · they, them, their".
    static func describe(_ segment: WordSegment) -> String {
        var parts: [String] = []
        switch segment.kind {
        case .prefix:
            parts.append(WordGrammarLabels.pos[segment.tag] ?? "")
            if let gloss = segment.features.lazy.compactMap({ WordGrammarLabels.prefix[$0] }).first {
                parts.append(gloss)
            }
        case .suffix:
            for token in segment.features {
                if token.hasPrefix("PRON:") {
                    parts.append(WordGrammarLabels.pos["PRON"] ?? "")
                    let code = String(token.dropFirst(5))
                    parts.append(WordGrammarLabels.pronoun[code] ?? personPhrase(personCode(code)))
                } else {
                    parts.append(WordGrammarLabels.feature[token] ?? "")
                }
            }
            if parts.allSatisfy(\.isEmpty) { parts = [WordGrammarLabels.pos[segment.tag] ?? ""] }
        case .stem:
            parts.append(WordGrammarLabels.pos[segment.tag] ?? "")
            let personToken = segment.features.first { personCode($0) != nil }
            if let personToken {
                if segment.tag == "PRON" {
                    parts.append(WordGrammarLabels.pronoun[personToken] ?? personPhrase(personCode(personToken)))
                } else {
                    parts.append(personPhrase(personCode(personToken)))
                }
            }
            for token in segment.features where personCode(token) == nil {
                if token == "PCPL" {
                    let voice = segment.features.contains("PASS") ? "PASS" : "ACT"
                    parts.append(WordGrammarLabels.feature["PCPL:\(voice)"] ?? "")
                    continue
                }
                if (token == "ACT" || token == "PASS") && segment.features.contains("PCPL") { continue }
                parts.append(WordGrammarLabels.verbForm[token] ?? WordGrammarLabels.feature[token] ?? "")
            }
        }
        return parts.filter { !$0.isEmpty }.joined(separator: separator)
    }

    struct Fact: Identifiable {
        let label: String
        let value: String
        var arabic: Bool = false
        /// A second line under the value: the pronoun in plain words, else the term explained.
        var detail: String? = nil
        var id: String { label }
        var explainer: String? { detail ?? WordGrammarLabels.explainer[value] }
    }

    /// The analysis card's rows for the word's stem, in the order a grammar lesson gives them.
    static func facts(_ grammar: WordGrammar, root: String?, lemma: String?) -> [Fact] {
        guard let stem = grammar.stem else { return [] }
        var facts: [Fact] = []
        func add(_ label: String, _ value: String, arabic: Bool = false, detail: String? = nil) {
            if !value.isEmpty, !facts.contains(where: { $0.label == label }) {
                facts.append(Fact(label: label, value: value, arabic: arabic, detail: detail))
            }
        }
        func has(_ token: String) -> Bool { stem.features.contains(token) }
        func label(_ token: String) -> String { WordGrammarLabels.feature[token] ?? "" }

        add(String(localized: "Part of speech"), WordGrammarLabels.pos[stem.tag] ?? "")
        if let root { add(String(localized: "Root"), root, arabic: true) }
        if let lemma { add(String(localized: "Dictionary form"), lemma, arabic: true) }
        if let form = stem.features.first(where: { WordGrammarLabels.verbForm[$0] != nil }) {
            add(String(localized: "Verb form"), WordGrammarLabels.verbForm[form] ?? "")
        }
        if stem.tag == "V" {
            add(String(localized: "Tense"), has("PERF") ? label("PERF") : has("IMPF") ? label("IMPF") : has("IMPV") ? label("IMPV") : "")
            if let mood = stem.features.first(where: { $0.hasPrefix("MOOD:") }) { add(String(localized: "Mood"), label(mood)) }
            add(String(localized: "Voice"), has("PASS") ? label("PASS") : label("ACT"))
        } else {
            if has("VN") { add(String(localized: "Derivation"), label("VN")) }
            if has("PCPL") { add(String(localized: "Derivation"), label(has("PASS") ? "PCPL:PASS" : "PCPL:ACT")) }
        }
        if let personToken = stem.features.first(where: { personCode($0) != nil }) {
            let code = personCode(personToken)
            let phrase = personPhrase(code)
            let pronoun = (stem.tag == "V" || stem.tag == "PRON") ? (WordGrammarLabels.pronoun[personToken] ?? "") : ""
            // A noun has a gender and a number but no person: "masculine singular" is not an answer
            // to "who is speaking".
            add(code?.person != nil ? String(localized: "Person and number") : String(localized: "Gender and number"), phrase,
                detail: !pronoun.isEmpty && pronoun != phrase ? "\u{201C}\(pronoun)\u{201D}" : nil)
        }
        if let caseToken = stem.features.first(where: { ["NOM", "ACC", "GEN"].contains($0) }) {
            add(String(localized: "Case"), label(caseToken))
        }
        if has("INDEF") {
            add(String(localized: "Definiteness"), label("INDEF"))
        } else if grammar.segments.contains(where: { $0.kind == .prefix && $0.features.contains("Al+") }) {
            add(String(localized: "Definiteness"), label("DEF"))
        }
        if let group = stem.features.first(where: { $0.hasPrefix("SP:") }) { add(String(localized: "Group"), label(group)) }
        return facts
    }

    /// The short chips under the word: its part of speech and, for a verb, its form ("Form IV").
    static func chips(_ grammar: WordGrammar) -> (pos: String?, form: String?) {
        guard let stem = grammar.stem else { return (nil, nil) }
        let form = stem.features.first { WordGrammarLabels.verbForm[$0] != nil }
            .map { String($0.dropFirst().dropLast()) }
            .map { String(localized: "Form \($0)") }
        return (WordGrammarLabels.pos[stem.tag], form)
    }
}

// MARK: - The word card's Grammar page

/// The Grammar page: the word with one part lit, a chip per part to choose it, every part described,
/// then the analysis. `selected` is the card's own state, shared with the hero above the tabs.
struct WordGrammarPage: View {
    @Environment(\.appearance) private var appearance

    let grammar: WordGrammar?
    let root: String?
    let lemma: String?
    let fontName: String
    @Binding var selected: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let grammar, !grammar.segments.isEmpty {
                breakdownCard(grammar)
                analysisCard(grammar)
                Text("Grammar from the Quranic Arabic Corpus (Kais Dukes, corpus.quran.com), as prepared by Tilawa.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                emptyCard(String(localized: "No grammar annotation is available for this word."))
            }
        }
    }

    private func breakdownCard(_ grammar: WordGrammar) -> some View {
        let current = selected ?? grammar.stem?.index ?? 0
        return StudyCard(title: String(localized: "WORD BREAKDOWN")) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Tap a part to light it in the word above.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)

                ForEach(grammar.segments) { segment in
                    let isOn = segment.index == current
                    Button {
                        Settings.shared.hapticFeedback()
                        withAnimation(.easeInOut(duration: 0.2)) { selected = segment.index }
                    } label: {
                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(segment.kind.title.uppercased())
                                    .font(.caption2.weight(.bold))
                                    .tracking(0.6)
                                    .foregroundStyle(isOn ? appearance.accent : .secondary)
                                Text(WordGrammarText.describe(segment))
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer(minLength: 8)
                            Group {
                                if segment.isImplied {
                                    Text("implied")
                                        .font(.caption.italic())
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text(segment.form)
                                        .font(.custom(fontName, size: 28))
                                        .arabicFontDesign(custom: true)
                                        .foregroundColor(isOn ? appearance.accent : .primary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
                                }
                            }
                            .frame(minWidth: 56, alignment: .trailing)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(isOn ? appearance.accent.opacity(0.14) : Color.clear)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
                }
            }
        }
    }

    private func analysisCard(_ grammar: WordGrammar) -> some View {
        let facts = WordGrammarText.facts(grammar, root: root, lemma: lemma)
        return StudyCard(title: String(localized: "ANALYSIS")) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(facts.enumerated()), id: \.element.id) { index, fact in
                    if index > 0 { Divider() }
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(fact.label)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 8)
                        VStack(alignment: .trailing, spacing: 2) {
                            if fact.arabic {
                                Text(fact.value)
                                    .font(.custom(fontName, size: 22))
                                    .arabicFontDesign(custom: true)
                            } else {
                                Text(fact.value)
                                    .font(.subheadline.weight(.semibold))
                                    .multilineTextAlignment(.trailing)
                            }
                            if let explainer = fact.explainer {
                                Text(explainer)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.trailing)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(.vertical, 9)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}

// MARK: - The word card's Root page

/// The Root page: the root and dictionary form, every word of the root in mushaf order (a page at a
/// time, each one opening that word in this card), and the other dictionary forms built on it.
struct WordRootPage: View {
    @Environment(\.appearance) private var appearance

    let location: WordLocation
    let fontName: String
    /// Moves the card to another word (an occurrence, or another form's first use).
    let onOpenWord: (WordLocation) -> Void

    @State private var shown = 10

    private struct Sibling: Identifiable {
        let id: Int
        let lemma: MorphologyStore.Lemma
        let count: Int
        let first: WordLocation
    }

    var body: some View {
        let store = MorphologyStore.shared
        let rootInfo = store.root(surah: location.surah, ayah: location.ayah, token: location.token)
        let lemmaInfo = store.lemma(surah: location.surah, ayah: location.ayah, token: location.token)

        VStack(alignment: .leading, spacing: 14) {
            if let rootInfo {
                let occurrences = store.occurrences(ofRoot: rootInfo.id)
                rootCard(rootInfo.root, lemma: lemmaInfo, count: occurrences.count, occurrences: occurrences, rootID: rootInfo.id)
                occurrencesCard(occurrences)
                siblingsCard(rootID: rootInfo.id, occurrences: occurrences, current: lemmaInfo?.id)
            } else {
                emptyCard(String(localized: "No root is recorded for this word. Particles and some names have no root entry."))
                if let lemmaInfo {
                    StudyCard(title: String(localized: "DICTIONARY FORM")) {
                        Text(lemmaInfo.lemma.text)
                            .font(.custom(fontName, size: 30))
                            .arabicFontDesign(custom: true)
                            .foregroundColor(appearance.accent)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            // Arabic keeps the right edge: in the Arabic interface `.trailing` is the left.
                            .environment(\.layoutDirection, .leftToRight)
                    }
                }
            }
        }
        .onChange(of: location) { _ in shown = 10 }
    }

    private func rootCard(_ root: MorphologyStore.Root, lemma: (id: Int, lemma: MorphologyStore.Lemma)?,
                          count: Int, occurrences: [WordLocation], rootID: Int) -> some View {
        StudyCard(title: String(localized: "ROOT")) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(count == 1 ? String(localized: "1 word in the Quran") : String(localized: "\(count) words in the Quran"))
                            .font(.subheadline.weight(.semibold))
                        if let lemma {
                            let lemmaCount = MorphologyStore.shared.occurrences(ofLemma: lemma.id).count
                            Text(lemmaCount == 1 ? String(localized: "This form: once") : String(localized: "This form: \(lemmaCount) times"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Text(root.letters)
                        .font(.custom(fontName, size: 34))
                        .arabicFontDesign(custom: true)
                        .foregroundColor(appearance.accent)
                }

                NavigationLink {
                    LazyDestination {
                        RootOccurrencesView(title: String(localized: "Root \(root.letters)"), locations: occurrences, highlight: location)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "text.magnifyingglass")
                        Text("Every Ayah With This Root")
                            .fontWeight(.medium)
                        Spacer()
                        Image(systemName: "chevron.forward")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .font(.subheadline)
                    .foregroundColor(appearance.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(appearance.accent.opacity(0.10))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func occurrencesCard(_ occurrences: [WordLocation]) -> some View {
        let page = Array(occurrences.prefix(shown))
        return StudyCard(title: String(localized: "WORDS FROM THIS ROOT")) {
            VStack(alignment: .leading, spacing: 0) {
                Text("In mushaf order. Tap one to study it here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 6)

                ForEach(Array(page.enumerated()), id: \.element.id) { index, occurrence in
                    if index > 0 { Divider() }
                    OccurrenceLine(location: occurrence, isCurrent: occurrence == location,
                                   fontName: fontName, accent: appearance.accent) {
                        onOpenWord(occurrence)
                    }
                }

                if occurrences.count > shown {
                    Button {
                        Settings.shared.hapticFeedback()
                        shown += 20
                    } label: {
                        Text("Show More (\(occurrences.count - shown) left)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(appearance.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func siblingsCard(rootID: Int, occurrences: [WordLocation], current: Int?) -> some View {
        let siblings = Self.siblings(occurrences: occurrences, excluding: current)
        if !siblings.isEmpty {
            StudyCard(title: String(localized: "OTHER WORDS FROM THIS ROOT")) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(siblings.enumerated()), id: \.element.id) { index, sibling in
                        if index > 0 { Divider() }
                        Button {
                            Settings.shared.hapticFeedback()
                            onOpenWord(sibling.first)
                        } label: {
                            HStack(spacing: 10) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(Self.gloss(at: sibling.first))
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                        .lineLimit(2)
                                        // The English gloss keeps its own direction in the Arabic interface.
                                        .leftToRightContent()
                                    Text(sibling.count == 1 ? String(localized: "once in the Quran") : String(localized: "\(sibling.count) times in the Quran"))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 8)
                                Text(sibling.lemma.text)
                                    .font(.custom(fontName, size: 22))
                                    .arabicFontDesign(custom: true)
                                    .foregroundColor(appearance.accent)
                                Image(systemName: "chevron.forward")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 9)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    /// The root's other dictionary forms, most used first, each with where it first appears.
    private static func siblings(occurrences: [WordLocation], excluding current: Int?) -> [Sibling] {
        var counts: [Int: Int] = [:]
        var firsts: [Int: WordLocation] = [:]
        for occurrence in occurrences {
            guard let lemma = MorphologyStore.shared.lemma(surah: occurrence.surah, ayah: occurrence.ayah, token: occurrence.token)
            else { continue }
            counts[lemma.id, default: 0] += 1
            if firsts[lemma.id] == nil { firsts[lemma.id] = occurrence }
        }
        return counts.keys
            .filter { $0 != current }
            .compactMap { id -> Sibling? in
                guard let lemma = MorphologyStore.shared.lemma(id: id), let first = firsts[id] else { return nil }
                return Sibling(id: id, lemma: lemma, count: counts[id] ?? 0, first: first)
            }
            .sorted { $0.count != $1.count ? $0.count > $1.count : $0.id < $1.id }
            .prefix(12)
            .map { $0 }
    }

    static func gloss(at location: WordLocation) -> String {
        guard let glosses = WordByWordStore.shared.glosses(surah: location.surah, ayah: location.ayah),
              glosses.indices.contains(location.token) else { return "" }
        return glosses[location.token]
    }
}

/// One occurrence of a root: the reference, its gloss, and the word itself.
private struct OccurrenceLine: View {
    let location: WordLocation
    let isCurrent: Bool
    let fontName: String
    let accent: Color
    let action: () -> Void

    var body: some View {
        let word = Self.token(at: location)
        Button(action: {
            Settings.shared.hapticFeedback()
            action()
        }) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("\(QuranData.shared.surah(location.surah)?.displayName ?? "") \(location.surah):\(location.ayah)")
                            .font(.caption.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.secondary)
                        if isCurrent {
                            Text("This word")
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(Capsule().fill(accent.opacity(0.15)))
                                .foregroundColor(accent)
                        }
                    }
                    Text(WordRootPage.gloss(at: location))
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .leftToRightContent()
                }
                Spacer(minLength: 8)
                Text(word)
                    .font(.custom(fontName, size: 22))
                    .arabicFontDesign(custom: true)
                    .foregroundColor(isCurrent ? accent : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(.vertical, 9)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isCurrent)
    }

    static func token(at location: WordLocation) -> String {
        guard let ayah = QuranData.shared.ayah(surah: location.surah, ayah: location.ayah) else { return "" }
        let tokens = WordTokens.tokens(in: ayah.rawArabicText(surahId: location.surah, qiraahOverride: ""))
        return tokens.indices.contains(location.token) ? tokens[location.token] : ""
    }
}

// MARK: - Shared pieces

/// A rounded card with a small caps title, the word card's one container.
struct StudyCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .tracking(0.6)
                .foregroundStyle(.secondary)
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.primary.opacity(0.05))
        )
    }
}

private func emptyCard(_ text: String) -> some View {
    Text(text)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.primary.opacity(0.05))
        )
}
#endif
