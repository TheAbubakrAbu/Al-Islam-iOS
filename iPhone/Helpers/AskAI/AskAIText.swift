import SwiftUI
import Foundation

// Ask AI - what the model's text goes through before a reader sees it, and how its citations are
// read off the text.
//
// The on-device model ignores "no markdown" now and then, invents hadith numbers and verse
// references from memory despite being told to cite only the sources, and sometimes puts words in
// quotation marks that are in no source. So: markdown is stripped, a citation marker that names no
// source is removed and counted, a parenthetical carrying a recalled reference is removed and
// counted, a quotation that matches no source's wording is unmarked and flagged, and the rows
// beneath the answer are exactly the sources it was shown.

#if os(iOS)

enum AskAIText {
    // MARK: - Hygiene

    private static let preambleRegex = try! NSRegularExpression(
        pattern: #"(?i)\A\s*(?:sure|certainly|of course|absolutely|great question|good question|okay|ok)[^\n]{0,60}[!:.]\s*\n+"#)

    /// The transcript's label grammar, echoed back: a reply that opens with "User: ...\n\nAssistant:"
    /// (or Q:/A:) is cut to what follows the label (nothing, while the echo is still streaming), a bare
    /// "Assistant:" label is dropped, then a "Sure, I can help!" first line goes too.
    static func stripEcho(_ text: String) -> String {
        var out = text
        let trimmedStart = out.drop(while: { $0.isWhitespace })
        let lowered = trimmedStart.lowercased()
        if lowered.hasPrefix("q:") || lowered.hasPrefix("question:") || lowered.hasPrefix("user:") {
            if let answerLabel = out.range(of: #"\n\s*(?:A|Answer|Assistant):\s*"#, options: .regularExpression) {
                out = String(out[answerLabel.upperBound...])
            } else {
                return ""
            }
        }
        out = out.replacingOccurrences(of: #"\A\s*(?:A|Answer|Assistant|AI):\s*"#, with: "", options: .regularExpression)
        let ns = out as NSString
        if let match = preambleRegex.firstMatch(in: out, range: NSRange(location: 0, length: ns.length)) {
            out = ns.substring(from: match.range.location + match.range.length)
        }
        return out
    }

    /// Markdown emphasis and headings stripped; bullet markers become a bullet character.
    static func stripMarkdown(_ text: String) -> String {
        var out = stripEcho(text).replacingOccurrences(of: "**", with: "")
        out = out.replacingOccurrences(of: "__", with: "")
        let lines = out.components(separatedBy: "\n").map { line -> String in
            var trimmed = Substring(line)
            let leading = trimmed.prefix(while: { $0 == " " })
            trimmed = trimmed.dropFirst(leading.count)
            if trimmed.hasPrefix("#") {
                trimmed = trimmed.drop(while: { $0 == "#" || $0 == " " })
                return String(trimmed)
            }
            if trimmed.hasPrefix("* ") || trimmed.hasPrefix("- ") || trimmed.hasPrefix("\u{2022} ") {
                return String(leading) + "\u{2022} " + trimmed.dropFirst(2)
            }
            return line
        }
        out = lines.joined(separator: "\n")
        while out.contains("\n\n\n") { out = out.replacingOccurrences(of: "\n\n\n", with: "\n\n") }
        return out
    }

    /// Tafsir and surah-background sources are markdown-ish prose: headings, emphasis, links.
    /// Reduced to plain sentences for the model's context.
    static func plainProse(_ text: String) -> String {
        var out = stripMarkdown(text)
        out = out.replacingOccurrences(of: #"\[([^\]]+)\]\([^)]*\)"#, with: "$1", options: .regularExpression)
        out = out.replacingOccurrences(of: "`", with: "")
        out = out.replacingOccurrences(of: "*", with: "")
        out = out.replacingOccurrences(of: #"\s*\n+\s*"#, with: " ", options: .regularExpression)
        out = out.replacingOccurrences(of: #" {2,}"#, with: " ", options: .regularExpression)
        return out.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func paragraphKey(_ paragraph: String) -> String {
        paragraph.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }.joined(separator: " ")
    }

    private static let properNouns: [(String, String)] = [
        ("allah", "Allah"), ("quran", "Quran"), ("qur'an", "Qur'an"), ("islam", "Islam"), ("islamic", "Islamic"),
        ("muslim", "Muslim"), ("muslims", "Muslims"), ("ramadan", "Ramadan"), ("makkah", "Makkah"), ("mecca", "Mecca"),
        ("madinah", "Madinah"), ("medina", "Medina"), ("muhammad", "Muhammad"), ("jannah", "Jannah"),
        ("the prophet", "the Prophet"), ("prophet muhammad", "Prophet Muhammad"), ("ibn kathir", "Ibn Kathir"),
        ("bukhari", "Bukhari"), ("sahih al-bukhari", "Sahih al-Bukhari"), ("sahih muslim", "Sahih Muslim"),
    ]
    /// The proper nouns as compiled whole-word patterns: `capitalizing` runs on every stream flush,
    /// and rebuilt its twenty patterns each time.
    // Longest first: "sahih muslim" must run before "muslim" rewrites its inner word, or the compound
    // entries never match and the answer reads "sahih Muslim".
    private static let properNounRegexes: [(NSRegularExpression, String)] = properNouns
        .sorted { $0.0.count > $1.0.count }
        .compactMap { lower, proper in
        guard let regex = try? NSRegularExpression(pattern: "\\b" + NSRegularExpression.escapedPattern(for: lower) + "\\b") else { return nil }
        return (regex, NSRegularExpression.escapedTemplate(for: proper))
    }
    private static let surahNameRegex = try! NSRegularExpression(pattern: #"\b(surah|surat) ((?:al|an|as|ar|at|ad|ash|az)-)?([a-z][a-z'’-]*)"#)

    /// The first letter of every sentence upper-cased, and the names that are always capitals
    /// ("allah", "quran", "the prophet") restored: the on-device model drifts into lower case for
    /// whole answers now and then.
    static func capitalizing(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        var out = ""
        out.reserveCapacity(text.count)
        var atSentenceStart = true
        var previous: Character = " "
        var beforePrevious: Character = " "
        for character in text {
            if atSentenceStart, character.isLetter {
                out.append(contentsOf: String(character).uppercased())
                atSentenceStart = false
                beforePrevious = previous
                previous = character
                continue
            }
            out.append(character)
            if character == "." {
                // "i.e.", "e.g.", "a.m.": a period after a lone letter ends no sentence.
                let abbreviation = previous.isLetter && !beforePrevious.isLetter
                if !abbreviation { atSentenceStart = true }
            } else if character == "!" || character == "?" || character == "\n" {
                atSentenceStart = true
            } else if character.isLetter || character.isNumber {
                atSentenceStart = false
            }
            beforePrevious = previous
            previous = character
        }
        for (regex, template) in properNounRegexes {
            out = regex.stringByReplacingMatches(in: out, range: NSRange(location: 0, length: (out as NSString).length), withTemplate: template)
        }
        // "surah al-baqarah" -> "Surah Al-Baqarah": only with the article, or a word that IS a
        // surah's name ("surah yusuf"); "surah of the quran" keeps its "of".
        let ns = out as NSString
        var result = out
        for match in surahNameRegex.matches(in: out, range: NSRange(location: 0, length: ns.length)).reversed() {
            let word = ns.substring(with: match.range(at: 1)).capitalized
            let hasArticle = match.range(at: 2).location != NSNotFound
            let article = hasArticle ? ns.substring(with: match.range(at: 2)).capitalized : ""
            let name = ns.substring(with: match.range(at: 3))
            guard hasArticle || surahNameTokens.contains(AskAILexicon.fold(name)) else { continue }
            let capitalizedName = name.prefix(1).uppercased() + name.dropFirst()
            if let range = Range(match.range, in: result) { result.replaceSubrange(range, with: word + " " + article + capitalizedName) }
        }
        return result
    }

    /// The words of the surahs' transliterated names ("yusuf", "kahf", "baqarah"), folded, handed
    /// over by the conversation once the Quran is loaded; what `capitalizing` recognises after "surah".
    nonisolated(unsafe) static var surahNameTokens: Set<String> = []

    /// An em dash, and a spaced en dash, become a comma: the model writes them freely, and the app's
    /// prose never does (the en dash in a range such as 2020–24 is left alone).
    static func replacingDashes(_ text: String) -> String {
        var out = text.replacingOccurrences(of: #"\s*\u2014\s*"#, with: ", ", options: .regularExpression)
        out = out.replacingOccurrences(of: #"\s+\u2013\s+"#, with: ", ", options: .regularExpression)
        out = out.replacingOccurrences(of: ",,", with: ",").replacingOccurrences(of: ", ,", with: ",")
        out = out.replacingOccurrences(of: #"([.!?:])\s*,\s*"#, with: "$1 ", options: .regularExpression)
        return out
    }

    /// Drops the paragraphs of a new answer that repeat an earlier answer of the conversation.
    /// The small model, shown the transcript, likes to restate its last reply before adding to it
    /// ("why?" came back with the whole previous answer on top): a paragraph whose folded text sits
    /// inside an earlier answer, or shares most of its four-word shingles with one, is an echo.
    struct EchoGuard {
        private let folded: [String]
        private let shingles: Set<String>

        init(previousAnswers: [String]) {
            let folds = previousAnswers.map { AskAIText.paragraphKey($0) }.filter { $0.count >= 40 }
            folded = folds
            var set = Set<String>()
            for fold in folds {
                let words = fold.split(separator: " ").map(String.init)
                guard words.count >= 4 else { continue }
                for index in 0...(words.count - 4) { set.insert(words[index..<index + 4].joined(separator: " ")) }
            }
            shingles = set
        }

        var isEmpty: Bool { folded.isEmpty }

        func filter(_ text: String) -> String {
            guard !isEmpty, !text.isEmpty else { return text }
            let paragraphs = text.components(separatedBy: "\n\n")
            var kept: [String] = []
            for paragraph in paragraphs {
                let key = AskAIText.paragraphKey(paragraph)
                if key.count >= 40, isEcho(key) { continue }
                kept.append(paragraph)
            }
            return kept.joined(separator: "\n\n").trimmingCharacters(in: .whitespacesAndNewlines)
        }

        private func isEcho(_ key: String) -> Bool {
            if folded.contains(where: { $0.contains(key) }) { return true }
            let words = key.split(separator: " ").map(String.init)
            guard words.count >= 6 else { return false }
            var hits = 0
            let total = words.count - 3
            for index in 0..<total where shingles.contains(words[index..<index + 4].joined(separator: " ")) { hits += 1 }
            return Double(hits) / Double(total) >= 0.6
        }
    }

    /// True once a completed paragraph has appeared before: the model is looping and nothing
    /// after this point will be new.
    static func isLooping(_ text: String) -> Bool {
        let paragraphs = text.components(separatedBy: "\n\n").dropLast()   // the last one is still streaming
        var seen = Set<String>()
        for paragraph in paragraphs {
            let key = paragraphKey(paragraph)
            guard key.count >= 40 else { continue }
            if !seen.insert(key).inserted { return true }
        }
        return false
    }

    /// The text up to (not including) the first repeated paragraph.
    static func collapsingRepetition(_ text: String) -> String {
        let paragraphs = text.components(separatedBy: "\n\n")
        var kept: [String] = []
        var seen = Set<String>()
        for paragraph in paragraphs {
            let key = paragraphKey(paragraph)
            if key.count >= 40, !seen.insert(key).inserted { break }
            kept.append(paragraph)
        }
        return kept.joined(separator: "\n\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The model sometimes copies the prompt's SOURCES block into its answer ("[1] How to Make
    /// Wudhu (Al-Islam's own article...): ..."): a line that opens with a marker followed by that
    /// source's reference or title AND then its provenance is a copied source line, and goes.
    ///
    /// A line that opens "[1] Jami` at-Tirmidhi 1956, “Your smiling in the face of your brother is
    /// charity...”" is not one: it is the model saying where a passage is and quoting it, which a
    /// reader looking for a passage is told to expect (`AskAIPrompt.findTask`). It was dropped as a
    /// copy, and the answer to "is there a hadith about smiling being charity?" lost the hadith
    /// (2026-11-25). Such a line stays, its marker moved to the end, where a citation goes.
    static func droppingSourceEchoes(_ text: String, sources: [AskAISource]) -> String {
        guard !sources.isEmpty, !text.isEmpty else { return text }
        enum Opening { case other, named, copied }
        /// What the text right after a "[n]" marker is: that source's line from the prompt (its
        /// reference or title followed by the provenance in parentheses, or the provenance itself),
        /// the source merely named, or neither.
        func opening(_ n: Int, after rest: String) -> Opening {
            // `n > 0` first: a reply line "[-9223372036854775808]" reads as Int.min, and `n - 1` trapped.
            guard n > 0, sources.indices.contains(n - 1) else { return .other }
            var rest = rest.trimmingCharacters(in: .whitespaces)
            var marked = false
            if rest.hasPrefix("subject of the question:") {
                rest = String(rest.dropFirst(24)).trimmingCharacters(in: .whitespaces)
                marked = true
            }
            let source = sources[n - 1]
            let head = String(rest.prefix(140))
            if source.provenance.contains(where: { $0.count >= 4 && head.hasPrefix($0.lowercased().prefix(28)) }) { return .copied }
            for name in [source.reference.lowercased(), source.title.lowercased()] where name.count >= 4 && head.hasPrefix(name) {
                let after = head.dropFirst(name.count).trimmingCharacters(in: .whitespaces)
                // The prompt's own line goes on with the provenance in parentheses (straight to the
                // text after a colon when the source has none).
                if marked || after.hasPrefix("(") || (source.provenance.isEmpty && after.hasPrefix(":")) { return .copied }
                return .named
            }
            return .other
        }
        func namesSource(_ n: Int, after rest: String) -> Bool { opening(n, after: rest) == .copied }
        let paragraphs = text.components(separatedBy: "\n\n")
        var kept: [String] = []
        for paragraph in paragraphs {
            // A whole reference list in one paragraph ("[1] 48:10 (Surah Al-Fath...); [2] 47:33
            // ..."): two or more markers each followed by its source's name.
            let lowered = paragraph.lowercased()
            var listed = 0
            let ns = lowered as NSString
            for match in markerRegex.matches(in: lowered, range: NSRange(location: 0, length: ns.length)) {
                let group = ns.substring(with: match.range) as NSString
                guard let digits = digitsRegex.firstMatch(in: group as String, range: NSRange(location: 0, length: group.length)),
                      let n = Int(group.substring(with: digits.range)) else { continue }
                let after = ns.substring(from: match.range.location + match.range.length)
                if namesSource(n, after: after) { listed += 1 }
            }
            if listed >= 2 { continue }
            let lines: [String] = paragraph.components(separatedBy: "\n").compactMap { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces).lowercased()
                // A copied note line: "With [2], the tafsir Ibn Kathir on this verse: ...".
                if copiedNoteLine(trimmed, sources: sources) { return nil }
                guard let close = trimmed.firstIndex(of: "]"), trimmed.hasPrefix("[") else { return line }
                let number = trimmed[trimmed.index(after: trimmed.startIndex)..<close]
                guard let n = Int(number) else { return line }
                switch opening(n, after: String(trimmed[trimmed.index(after: close)...])) {
                case .copied: return nil
                case .other: return line
                case .named:
                    // "[1] Sahih Muslim 2766a, “...”" reads as "Sahih Muslim 2766a, “...” [1]".
                    let original = line.trimmingCharacters(in: .whitespaces)
                    guard let bracket = original.firstIndex(of: "]") else { return line }
                    let marker = String(original[...bracket])
                    let body = original[original.index(after: bracket)...].trimmingCharacters(in: .whitespaces)
                    return body.contains(marker) ? body : body + " " + marker
                }
            }
            let joined = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !joined.isEmpty { kept.append(joined) }
        }
        return kept.joined(separator: "\n\n")
    }

    private static let noteLineRegex = try! NSRegularExpression(pattern: #"^with \[(\d{1,2})\],\s*"#)

    /// Whether a (lowercased) answer line is one of the prompt's note lines copied out: it opens
    /// "with [n]," and goes on with the label of a note that source carries.
    private static func copiedNoteLine(_ line: String, sources: [AskAISource]) -> Bool {
        let ns = line as NSString
        guard let match = noteLineRegex.firstMatch(in: line, range: NSRange(location: 0, length: ns.length)),
              let n = Int(ns.substring(with: match.range(at: 1))), n > 0, sources.indices.contains(n - 1) else { return false }
        let rest = ns.substring(from: match.range.length)
        return sources[n - 1].notes.contains { rest.hasPrefix($0.promptLabel.lowercased()) }
    }

    /// A trailing "References:" / "Sources:" list is the model restating its citations; the cards
    /// beneath the answer are the references, so the block goes. So does a bare run of markers
    /// tacked on after the last sentence ("...consult a qualified scholar. [1] [2] [3] [5]").
    static func droppingTrailingReferences(_ text: String) -> String {
        var text = text.replacingOccurrences(of: #"(?<=[.!?])\s*(?:\[\d{1,2}\]\s*){2,}[.]?\s*$"#, with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: #"^\s*(?:\[\d{1,2}\]\s*){2,}[.]?\s*$"#, with: "", options: [.regularExpression, .anchored])
        var lines = text.components(separatedBy: "\n")
        lines.removeAll { $0.range(of: #"^\s*(?:[\u2022\-\*]|\d{1,2}[.)])\s*$"#, options: .regularExpression) != nil }
        if let heading = lines.lastIndex(where: {
            $0.range(of: #"(?i)^\s*(?:references|sources|citations|sources used|sources cited)\s*:?\s*$"#, options: .regularExpression) != nil
        }) {
            let tail = lines[(heading + 1)...]
            let isReferenceLine: (String) -> Bool = { line in
                let t = line.trimmingCharacters(in: .whitespaces)
                return t.isEmpty || t.hasPrefix("\u{2022}") || t.hasPrefix("-") || t.hasPrefix("(") || t.hasPrefix("[")
                    || t.contains("http") || t.count <= 80
                    || t.range(of: #"^\d{1,2}[.)]"#, options: .regularExpression) != nil
                    || t.range(of: #"^\d{1,3}:\d{1,3}"#, options: .regularExpression) != nil
            }
            if tail.allSatisfy(isReferenceLine) {
                lines.removeSubrange(heading...)
            }
        }
        var out = lines.joined(separator: "\n")
        while out.contains("\n\n\n") { out = out.replacingOccurrences(of: "\n\n\n", with: "\n\n") }
        return out.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Citation markers

    /// "[1]", "[2, 4]", "[Source 3]", "[1][2]": one bracket group with every number inside it.
    private static let markerRegex = try! NSRegularExpression(
        pattern: #"\[(?:\s*(?:sources?|src)?\s*\d{1,2}\s*(?:[,;&]|and)?\s*)+\]"#, options: [.caseInsensitive])
    /// "(source 2)", "(sources 1 and 3)": the parenthetical form some answers use.
    private static let parenMarkerRegex = try! NSRegularExpression(
        pattern: #"\(\s*sources?\s+\d{1,2}(?:\s*(?:,|and|&)\s*\d{1,2})*\s*\)"#, options: [.caseInsensitive])
    private static let digitsRegex = try! NSRegularExpression(pattern: #"\d{1,2}"#)
    /// "[2:83]", "[3:14]": a verse-shaped reference written where a marker belongs.
    private static let referenceMarkerRegex = try! NSRegularExpression(pattern: #"\[\s*(\d{1,3})\s*:\s*(\d{1,4})\s*\]"#)

    /// The source a verse-shaped bracket means, as its number: the source whose reference it is
    /// ("[2:83]" where a source IS 2:83), else the source of that number when the second figure is
    /// its own ayah or hadith number ("[3:14]" for source 3, Luqman 31:14: the model had glued the
    /// marker to the verse). Nil when it names nothing the model was given.
    private static func sourceNumber(forReference first: Int, _ second: Int, sources: [AskAISource]) -> Int? {
        if let index = sources.firstIndex(where: { $0.reference == "\(first):\(second)" }) { return index + 1 }
        guard first >= 1, first <= sources.count else { return nil }
        switch sources[first - 1].kind {
        case .ayah(_, let ayah), .tafsir(_, let ayah, _):
            return ayah == second ? first : nil
        case .hadith:
            return sources[first - 1].reference.hasSuffix(" \(second)") ? first : nil
        default:
            return nil
        }
    }

    /// Every marker group rewritten to the canonical "[n]" form, one bracket per number, with the
    /// numbers that name no source removed; the count of those removed is disclosed to the reader.
    /// A marker glued to a word gets its space back ("patience[1]" -> "patience [1]"). With the
    /// turn's `sources`, a verse-shaped bracket ("[2:83]", seen once the prompt carried note lines)
    /// becomes the marker of the source it means, or goes like any reference recalled from memory.
    static func normalizeMarkers(_ text: String, sourceCount: Int, sources: [AskAISource] = []) -> (text: String, removed: Int) {
        guard !text.isEmpty else { return (text, 0) }
        var removed = 0
        var text = text
        if !sources.isEmpty {
            let ns = text as NSString
            for match in referenceMarkerRegex.matches(in: text, range: NSRange(location: 0, length: ns.length)).reversed() {
                guard let first = Int(ns.substring(with: match.range(at: 1))), let second = Int(ns.substring(with: match.range(at: 2))),
                      let range = Range(match.range, in: text) else { continue }
                if let number = sourceNumber(forReference: first, second, sources: sources) {
                    text.replaceSubrange(range, with: "[\(number)]")
                } else {
                    // Left as an out-of-range marker for the pass below to remove and count.
                    text.replaceSubrange(range, with: "[99]")
                }
            }
        }
        func rewrite(_ input: String, regex: NSRegularExpression) -> String {
            let ns = input as NSString
            var result = input
            for match in regex.matches(in: input, range: NSRange(location: 0, length: ns.length)).reversed() {
                let group = ns.substring(with: match.range)
                let groupNS = group as NSString
                var numbers: [Int] = []
                for digits in digitsRegex.matches(in: group, range: NSRange(location: 0, length: groupNS.length)) {
                    if let n = Int(groupNS.substring(with: digits.range)) {
                        // Never `(1...sourceCount)`: a sourceless turn (a greeting, the second
                        // guardrail retry) has sourceCount 0, and 1...0 traps.
                        if n >= 1, n <= sourceCount {
                            if !numbers.contains(n) { numbers.append(n) }
                        } else {
                            removed += 1
                        }
                    }
                }
                var replacement = numbers.map { "[\($0)]" }.joined()
                // The space before a marker: keep one when the marker stays, drop it when it goes.
                let before = match.range.location > 0 ? ns.substring(with: NSRange(location: match.range.location - 1, length: 1)) : " "
                if !replacement.isEmpty, before != " ", before != "\n", before != "(" { replacement = " " + replacement }
                // A removed marker takes the space before it, when there is one. (`before` is " "
                // for a marker at position 0 too: without the location check this built a range
                // at -1 and trapped, which is how a reply that OPENED with "[1]" and no sources
                // crashed the app mid-stream.)
                if replacement.isEmpty, before == " ", match.range.location > 0 {
                    if let range = Range(NSRange(location: match.range.location - 1, length: match.range.length + 1), in: result) {
                        result.replaceSubrange(range, with: "")
                        continue
                    }
                }
                if let range = Range(match.range, in: result) { result.replaceSubrange(range, with: replacement) }
            }
            return result
        }
        var out = rewrite(text, regex: markerRegex)
        out = rewrite(out, regex: parenMarkerRegex)
        // A marker before sentence punctuation reads better after it: "[1]." -> ".[1]" is what
        // print does, but on screen "[1]." is clearer; only stray double spaces are cleaned here.
        out = out.replacingOccurrences(of: #" {2,}"#, with: " ", options: .regularExpression)
        out = out.replacingOccurrences(of: " ,", with: ",").replacingOccurrences(of: " .", with: ".")
        // A removed marker that opened the reply leaves its following space at the front.
        while out.first == " " { out.removeFirst() }
        return (out, removed)
    }

    /// Every "[n]" marker rewritten through `map` (old number to new); a number the map lacks is
    /// dropped. A recap or a source question hands the model the previous answer beside a NEW
    /// numbering of its sources, so the answer's markers must speak the new numbering.
    static func renumberingMarkers(_ text: String, map: [Int: Int]) -> String {
        guard !text.isEmpty else { return text }
        let ns = text as NSString
        var result = text
        for match in markerRegex.matches(in: text, range: NSRange(location: 0, length: ns.length)).reversed() {
            let group = ns.substring(with: match.range) as NSString
            var numbers: [Int] = []
            for digits in digitsRegex.matches(in: group as String, range: NSRange(location: 0, length: group.length)) {
                if let n = Int(group.substring(with: digits.range)), let renumbered = map[n], !numbers.contains(renumbered) {
                    numbers.append(renumbered)
                }
            }
            if let range = Range(match.range, in: result) {
                result.replaceSubrange(range, with: numbers.map { "[\($0)]" }.joined())
            }
        }
        return result.replacingOccurrences(of: #" {2,}"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: " .", with: ".").replacingOccurrences(of: " ,", with: ",")
    }

    /// The text with its citation markers removed: an earlier answer re-sent as context must not
    /// carry numbers that point into another turn's sources.
    static func strippingMarkers(_ text: String) -> String {
        renumberingMarkers(text, map: [:])
    }

    /// The sources the text cites, in order of first appearance: by marker number, then by a
    /// reference or alias written in words ("Sahih al-Bukhari 6114", "2:153"), whole-reference
    /// only ("2:15" must not claim "2:153"). Subject sources always count, first.
    static func citedSources(in text: String, sources: [AskAISource]) -> [AskAISource] {
        guard !sources.isEmpty else { return [] }
        var positions: [(position: Int, index: Int)] = []
        var claimed = Set<Int>()
        for (index, source) in sources.enumerated() where source.isSubject {
            positions.append((-1, index))
            claimed.insert(index)
        }
        guard !text.isEmpty else { return positions.map { sources[$0.index] } }
        let ns = text as NSString
        for match in markerRegex.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
            let group = ns.substring(with: match.range) as NSString
            for digits in digitsRegex.matches(in: group as String, range: NSRange(location: 0, length: group.length)) {
                guard let n = Int(group.substring(with: digits.range)), n >= 1, n <= sources.count else { continue }
                if claimed.insert(n - 1).inserted { positions.append((match.range.location, n - 1)) }
            }
        }
        let lowered = citationKey(text)
        for (index, source) in sources.enumerated() where !claimed.contains(index) {
            let needles = ([source.reference] + source.aliases).map(citationKey)
            var best: Int?
            for needle in needles where needle.count >= 3 {
                var searchStart = lowered.startIndex
                while let range = lowered.range(of: needle, range: searchStart..<lowered.endIndex) {
                    let before = range.lowerBound > lowered.startIndex ? lowered[lowered.index(before: range.lowerBound)] : " "
                    let after = range.upperBound < lowered.endIndex ? lowered[range.upperBound] : " "
                    if !before.isNumber, !after.isNumber, !before.isLetter, !after.isLetter {
                        let position = lowered.distance(from: lowered.startIndex, to: range.lowerBound)
                        if best == nil || position < best! { best = position }
                        break
                    }
                    searchStart = range.upperBound
                }
            }
            if let best {
                claimed.insert(index)
                positions.append((best, index))
            }
        }
        return positions.sorted { $0.position < $1.position }.map { sources[$0.index] }
    }

    // MARK: - Recalled references and quotations

    private static let ayahRefRegex = try! NSRegularExpression(pattern: #"(?<![\d:])\d{1,3}\s*:\s*\d{1,3}(?![\d:])"#)
    private static let hadithRefRegex = try! NSRegularExpression(
        pattern: #"(?i)\b(bukhari|bukhaari|muslim|tirmidhi|tirmidhee|nasa'?i|nasaa'?i|abi dawud|abu dawud|abu dawood|ibn majah|ibn maajah|muwatta|malik|musnad|ahmad|darimi|riyad|riyadh|nawawi|qudsi|mishkat|bulugh|shama'?il|adab)\b[^()]{0,40}?\d"#)
    private static let parentheticalRegex = try! NSRegularExpression(pattern: #"\s?\(([^()]{1,160})\)"#)

    /// A citation as `citedSources` and `policeCitations` compare it: lowercased, commas gone, a
    /// "no." / "number" / "#" before the number dropped, the spaces around a colon closed ("2: 153").
    /// Both sides of a comparison go through it, so "(Sahih al-Bukhari, 6114)" and "(Bukhari no.
    /// 6114)" match the source they name instead of reading as recalled.
    static func citationKey(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: #"\s+(?:no\.?|number|#)\s*"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"(?<=\d)\s*:\s*(?=\d)"#, with: ":", options: .regularExpression)
    }

    /// Removes every parenthetical that cites a reference the app did NOT give the model (a verse
    /// number or a hadith number recalled from memory), returning the cleaned text and how many were
    /// removed. A parenthetical is kept when at least one of its references is a real source, and a
    /// time of day ("Asr (4:45 PM)") is not a verse.
    static func policeCitations(_ text: String, sources: [AskAISource]) -> (text: String, removed: Int) {
        guard !text.isEmpty else { return (text, 0) }
        // A hadith a note names (where else the report is recorded) was given to the model too.
        let verified = sources.flatMap { [$0.reference] + $0.aliases + $0.notes.flatMap(\.references) }
            .map(citationKey).filter { $0.count >= 3 }
        let ns = text as NSString
        // The clock times blanked with the whole text as context (a prayer's name in the sentence
        // makes "4:45" a time); the mask keeps the UTF-16 length, so the ranges below index both.
        let masked = AskAILexicon.maskingClockTimes(text) as NSString
        var result = text
        var removed = 0
        for match in parentheticalRegex.matches(in: text, range: NSRange(location: 0, length: ns.length)).reversed() {
            let content = ns.substring(with: match.range(at: 1))
            let maskedContent = masked.substring(with: match.range(at: 1))
            let contentRange = NSRange(location: 0, length: (maskedContent as NSString).length)
            let citesAyah = ayahRefRegex.firstMatch(in: maskedContent, range: contentRange) != nil
            let citesHadith = hadithRefRegex.firstMatch(in: maskedContent, range: contentRange) != nil
            guard citesAyah || citesHadith else { continue }
            let lowered = citationKey(content)
            let isVerified = verified.contains { reference in
                guard let range = lowered.range(of: reference) else { return false }
                let before = range.lowerBound > lowered.startIndex ? lowered[lowered.index(before: range.lowerBound)] : " "
                let after = range.upperBound < lowered.endIndex ? lowered[range.upperBound] : " "
                return !before.isNumber && !after.isNumber
            }
            if isVerified { continue }
            if let swiftRange = Range(match.range, in: result) {
                result.removeSubrange(swiftRange)
                removed += 1
            }
        }
        if removed > 0 {
            result = result.replacingOccurrences(of: " .", with: ".")
            result = result.replacingOccurrences(of: " ,", with: ",")
            result = result.replacingOccurrences(of: #" {2,}"#, with: " ", options: .regularExpression)
            result = droppingTrailingReferences(result)
        }
        return (result, removed)
    }

    /// A quote within ONE line: an unclosed quote must never pair with the next paragraph's opening.
    /// Every quoted span is matched, however short, so that quote marks pair as written: with a
    /// minimum length, a two-word quote's closing mark paired with the NEXT quote's opening mark and
    /// the prose between them was flagged as a fabricated quotation.
    private static let quotationRegex = try! NSRegularExpression(pattern: #"[\"\u201C]([^\"\u201C\u201D\n]{1,400})[\"\u201D]"#)

    /// Every quotation of five or more words that is not the wording of a source the model was
    /// given is scripture recalled from memory: the quote marks come off and the span is flagged
    /// "(wording not verified)"; the count is disclosed. A quotation that is the wording of a
    /// COMMENTARY read with a source (a tafsir, a hadith's explanation: `AskAISourceNote`) keeps
    /// its marks and is followed by where it is from, so it cannot pass for the verse or the hadith.
    static func policeQuotations(_ text: String, sources: [AskAISource]) -> (text: String, flagged: Int) {
        guard !text.isEmpty else { return (text, 0) }
        func fold(_ s: String) -> String {
            s.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }.joined(separator: " ")
        }
        // The scripture's own wording: each source's text, and the notes that are wording too (the
        // other translation, another collection's wording). Then the commentary read with it (a
        // tafsir, an explanation), which is wording the model was given but not the scripture's.
        let corpus = sources.map { source in
            fold(([source.text, source.transliteration ?? ""] + source.notes.filter { $0.quotedAttribution == nil }.map(\.text))
                .joined(separator: " "))
        }
        let commentary: [(text: String, attribution: String)] = sources.flatMap { source in
            source.notes.compactMap { note in note.quotedAttribution.map { (fold(note.text), $0) } }
        }
        func holds(_ haystack: String, _ pieces: [String]) -> Bool {
            var cursor = haystack.startIndex
            for piece in pieces {
                guard let range = haystack.range(of: piece, range: cursor..<haystack.endIndex) else { return false }
                cursor = range.upperBound
            }
            return true
        }
        let ns = text as NSString
        var result = text
        var flagged = 0
        for match in quotationRegex.matches(in: text, range: NSRange(location: 0, length: ns.length)).reversed() {
            let quoted = ns.substring(with: match.range(at: 1))
            // An elided quotation ("seek help... with the patient") is verified piece by piece: every
            // piece must sit in ONE source, in order.
            let pieces = quoted.replacingOccurrences(of: "\u{2026}", with: "...").components(separatedBy: "...")
                .map(fold).filter { !$0.isEmpty }
            let words = pieces.reduce(0) { $0 + $1.split(separator: " ").count }
            guard words >= 5, !pieces.isEmpty else { continue }
            if corpus.contains(where: { holds($0, pieces) }) { continue }
            guard let range = Range(match.range, in: result) else { continue }
            // A commentary's words, quoted: real wording, but never the verse's or the hadith's
            // own. Whatever the sentence around it claims ("He also explained this as: ..."), the
            // quotation says where it is from.
            if let note = commentary.first(where: { holds($0.text, pieces) }) {
                result.insert(contentsOf: " " + note.attribution, at: range.upperBound)
                continue
            }
            result.replaceSubrange(range, with: quoted + " (wording not verified)")
            flagged += 1
        }
        return (result, flagged)
    }

    // MARK: - Rendering

    /// The answer as an attributed string for the selectable text view: the prose in the app's
    /// rounded face, and each "[n]" marker set smaller, raised and in the accent, so a citation
    /// reads like a footnote mark rather than a bracketed number in the sentence.
    static func attributedAnswer(_ text: String, font: UIFont, color: UIColor, accent: UIColor,
                                 lineSpacing: CGFloat = 3) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = lineSpacing
        paragraph.paragraphSpacing = 6
        let base: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: paragraph]
        let markerFont = UIFont.roundedSystemFont(ofSize: max(10, font.pointSize * 0.72), weight: .semibold)
        let marker: [NSAttributedString.Key: Any] = [.font: markerFont, .foregroundColor: accent, .paragraphStyle: paragraph,
                                                     .baselineOffset: font.pointSize * 0.28]
        let result = NSMutableAttributedString()
        let ns = text as NSString
        var cursor = 0
        for match in markerRegex.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
            if match.range.location > cursor {
                result.append(NSAttributedString(string: ns.substring(with: NSRange(location: cursor, length: match.range.location - cursor)), attributes: base))
            }
            // "[1][2]" as "1 2" superscripts: the brackets go, a thin space joins a run.
            let group = ns.substring(with: match.range) as NSString
            var numbers: [String] = []
            for digits in digitsRegex.matches(in: group as String, range: NSRange(location: 0, length: group.length)) {
                numbers.append(group.substring(with: digits.range))
            }
            // In the interface's digits, like the numbered source cards the marks point to.
            result.append(NSAttributedString(string: numbers.joined(separator: "\u{2009}").localizedDigits, attributes: marker))
            cursor = match.range.location + match.range.length
        }
        if cursor < ns.length {
            result.append(NSAttributedString(string: ns.substring(from: cursor), attributes: base))
        }
        return result
    }

    /// The answer as plain text for copying and sharing: markers become "[Quran 2:153]"-style
    /// citations and the sources follow as a list.
    static func shareText(answer: String, cited: [AskAISource], allSources: [AskAISource]) -> String {
        var text = answer
        let ns = text as NSString
        for match in markerRegex.matches(in: text, range: NSRange(location: 0, length: ns.length)).reversed() {
            let group = ns.substring(with: match.range) as NSString
            var names: [String] = []
            for digits in digitsRegex.matches(in: group as String, range: NSRange(location: 0, length: group.length)) {
                if let n = Int(group.substring(with: digits.range)), allSources.indices.contains(n - 1) {
                    names.append(allSources[n - 1].reference)
                }
            }
            if let range = Range(match.range, in: text) {
                text.replaceSubrange(range, with: names.isEmpty ? "" : " [" + names.joined(separator: "; ") + "]")
            }
        }
        if !cited.isEmpty {
            text += "\n\n" + String(localized: "Sources:") + "\n" + cited.map { source in
                var line = "\u{2022} \(source.reference)"
                if !source.provenanceLine.isEmpty { line += " (\(source.provenanceLine))" }
                line += ": \u{201C}\(AskAISource.clip(source.text, to: 240))\u{201D}"
                return line
            }.joined(separator: "\n")
        }
        return text.replacingOccurrences(of: #" {2,}"#, with: " ", options: .regularExpression)
    }

    // MARK: - Follow-up suggestions

    /// Two or three next questions, built locally from the question's intent, its canonical topic
    /// and what the answer cited: no model call, so they appear the moment the answer settles.
    /// The topic is the synonym HEAD of the question's first content word that has one ("zakat"
    /// asks about charity, "mother" about parents); a word outside the table names nothing, so the
    /// chips say "this" rather than "pay mahr" or "stop lazy". A follow-up never borrows the
    /// conversation's earlier topic (a misread follow-up carried "go back sleep after fajr" into a
    /// question about hair dye). A dua chip appears only when a dua on the topic exists.
    static func suggestions(for question: AskAIQuestion, cited: [AskAISource], duaTopics: Set<String>, starters: [String]) -> [String] {
        // A question about suicide or self-harm never gets templated chips ("Give an example of
        // suicide from the Prophet's life"): the crisis chips, which lead to a dua and to hope.
        if question.intent == .crisis || AskAICrisis.mentionsSelfHarm(question.raw) { return AskAICrisis.suggestions }
        let head = AskAILexicon.canonicalTopic(in: question.contentWords)
        if head == "suicide" { return AskAICrisis.suggestions }
        let topic = head.map(AskAILexicon.displayTopic)
        let subject = topic ?? "this"
        // A dua for the TOPIC itself (its head or a synonym is a dua title's word); with no topic,
        // for any search term. "Prophet" alone is in dozens of Hisn titles and offered a dua for
        // whatever the question was about.
        let hasDua: Bool
        if let head {
            hasDua = AskAILexicon.expand([head]).contains { duaTopics.contains($0) }
        } else {
            hasDua = question.searchTerms.contains { duaTopics.contains($0) }
        }
        var out: [String] = []
        func add(_ text: String) { if !out.contains(text), out.count < 3 { out.append(text) } }
        func addDuaChip() {
            guard hasDua else { return }
            add(topic.map { "Is there a dua for \($0)?" } ?? "Is there a dua for this?")
        }

        let firstAyah = cited.first { if case .ayah = $0.kind { return true } else { return false } }
        let firstHadith = cited.first { if case .hadith = $0.kind { return true } else { return false } }
        let firstSurah = cited.first { if case .surah = $0.kind { return true } else { return false } }

        switch question.intent {
        case .greeting, .thanks, .farewell, .capabilities, .smallTalk:
            return Array(starters.prefix(3))
        case .reference:
            if let firstAyah, case .ayah(let s, let a) = firstAyah.kind {
                add("What comes before and after \(s):\(a)?")
                add("What does Ibn Kathir say about \(s):\(a)?")
                add("Are there similar verses to \(s):\(a)?")
            } else if let firstSurah, case .surah(let id) = firstSurah.kind {
                // By name ("Surah Al-Kahf"), which the next question resolves as its subject; the
                // reference is "Surah 18 Al-Kahf".
                let name = firstSurah.reference.hasPrefix("Surah \(id) ") ? String(firstSurah.reference.dropFirst("Surah \(id) ".count)) : "\(id)"
                add("What are the main themes of Surah \(name)?")
                add("When was Surah \(name) revealed?")
                add("Which verses of Surah \(name) are most often quoted?")
            } else if let firstHadith {
                add("Who narrated \(firstHadith.reference)?")
                add("What lessons does \(firstHadith.reference) teach?")
                add("Is there a Quran verse on the same point?")
            }
        case .scripture, .hadith, .general:
            addDuaChip()
            #if HAS_HADITH
            if question.intent != .hadith { add("What do the hadith say about \(subject)?") }
            #endif
            if let firstAyah { add("Explain \(firstAyah.title) in more detail") }
            #if HAS_QURAN
            if let topic { add("Which surah speaks most about \(topic)?") } else { add("Which verses of the Quran speak about this?") }
            #endif
        case .define:
            addDuaChip()
            add("What does the Quran say about \(subject)?")
            add("What did the Prophet say about \(subject)?")
        case .ruling:
            add("What is the evidence on this?")
            add("Do the schools of thought differ on this?")
        case .story:
            add(topic.map { "What lessons does the story of \($0) teach?" } ?? "What lessons does this story teach?")
            #if HAS_QURAN
            if firstAyah != nil || firstSurah != nil { add("Which surah tells this story?") }
            #endif
            #if HAS_HADITH
            add("Is there a hadith about \(subject)?")
            #endif
        case .howTo:
            addDuaChip()
            add("What are the conditions for \(subject)?")
            add("Common mistakes when doing \(subject)?")
            add(topic.map { "What did the Prophet say about \($0)?" } ?? "What did the Prophet say about it?")
        case .dua:
            add("When exactly is this dua said?")
            add("Is there a hadith on the virtue of this dua?")
            add("What are the morning and evening adhkar?")
        case .appHelp:
            add("What else can I customize in this app?")
            add("How do I set up prayer notifications?")
            add("How do I change the Arabic font?")
        case .prayerTimes:
            #if HAS_ADHAN
            // Another day, and another place (AskAIPrayerRequest): Ask AI computes both now.
            add("What are the prayer times tomorrow?")
            add("When is Maghrib in Makkah today?")
            #endif
            add("How many rakahs is each prayer?")
        case .sourceQuestion, .recap:
            if let firstHadith { add("Explain \(firstHadith.reference) in more detail") }
            if let firstAyah { add("What is the context of \(firstAyah.title)?") }
            add("Are there other narrations on the same point?")
        case .crisis:
            return AskAICrisis.suggestions
        }
        if out.isEmpty {
            add("Can you explain that more simply?")
            add("Which sources did you use for that?")
        }
        return out
    }
}

/// The empty screen's starter questions, rotated by the day of the year.
enum AskAIStarters {
    #if HAS_QURAN
    static let pool = [
        "What does the Quran say about patience in hardship?",
        "How do I make up a missed prayer?",
        "Why is Surah Al-Kahf read on Fridays?",
        "What did the Prophet say about kindness to parents?",
        "Explain Ayat al-Kursi",
        "What is the difference between zakat and sadaqah?",
        "Tell me the story of Prophet Yusuf",
        "Is there a dua for anxiety?",
        "What does Al-Wadud mean?",
        "How do I perform wudu?",
        "What are the signs of the Day of Judgment?",
        "How do I change the reciter in this app?",
    ]
    #else
    // Without the Quran reader (Al-Adhan): the same pool, with the four starters that lean on the
    // Quran's text or its reciters swapped for ones this app's own sources answer (its prayer times,
    // articles, duas, Names and tips).
    static let pool = [
        "When does the time for Isha end tonight?",
        "How do I make up a missed prayer?",
        "What are the sunnahs of Friday?",
        "What did the Prophet say about kindness to parents?",
        "What should I say after the adhan?",
        "What is the difference between zakat and sadaqah?",
        "Tell me the story of Prophet Yusuf",
        "Is there a dua for anxiety?",
        "What does Al-Wadud mean?",
        "How do I perform wudu?",
        "What are the signs of the Day of Judgment?",
        "How do I change the adhan sound in this app?",
    ]
    #endif

    /// Four starters for a day of the year, so the empty screen does not read the same every time.
    static func forDay(_ dayOfYear: Int) -> [String] {
        (0..<4).map { pool[(dayOfYear * 3 + $0 * 5) % pool.count] }
    }

    static func today() -> [String] {
        forDay(Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0)
    }
}

#if DEBUG
/// "-askAITextProbe": the chat's pure text functions run on the inputs that broke them in the
/// 2026-09-28 audit (Docs/Engineering/Quality Guide.md, Phase 0), one NSLog line per case with PASS or FAIL.
/// No model, no retrieval: read with `log stream --predicate 'eventMessage CONTAINS "ASKAI PROBE"'`.
enum AskAITextProbe {
    static func runIfRequested() {
        guard ProcessInfo.processInfo.arguments.contains("-askAITextProbe") else { return }
        var failures = 0
        func check(_ name: String, _ ok: Bool, _ detail: String) {
            if !ok { failures += 1 }
            NSLog("ASKAI PROBE %@ %@: %@", ok ? "PASS" : "FAIL", name, detail)
        }
        // U1: zero sources never trap, and the marker goes.
        for text in ["[1] Wa alaikum assalam!", "Peace be upon you [1].", "As the source says (source 1), yes.", "[2][4] and [1, 3]"] {
            let result = AskAIText.normalizeMarkers(text, sourceCount: 0)
            check("U1 zero sources", !result.text.contains("[") && result.removed > 0, "\(text) -> \(result.text) (removed \(result.removed))")
        }
        // U9: citations written out in words match their source; clock times are not verses.
        let hadith = AskAISource(kind: .hadith(slug: "bukhari", idInBook: 6114), reference: "Sahih al-Bukhari 6114",
                                 title: "Sahih al-Bukhari 6114", text: "The strong is not the one who overcomes people by his strength.",
                                 aliases: ["bukhari 6114", "sahih al-bukhari 6114"])
        let ayah = AskAISource(kind: .ayah(surah: 2, ayah: 153), reference: "2:153", title: "Al-Baqarah 2:153",
                               text: "O you who have believed, seek help through patience and prayer.",
                               aliases: ["quran 2:153"])
        for (text, removed) in [("Strength is self-control (Sahih al-Bukhari, 6114).", 0), ("As taught (Bukhari no. 6114).", 0),
                                ("Seek help in patience (2: 153).", 0), ("Pray Asr (4:45 PM) before Maghrib (7:12 PM).", 0),
                                ("A recalled one (Bukhari 9999).", 1), ("A recalled verse (3:200).", 1)] {
            let result = AskAIText.policeCitations(text, sources: [hadith, ayah])
            check("U9 police", result.removed == removed, "\(text) -> \(result.text) (removed \(result.removed), expected \(removed))")
        }
        // U10: markers renumbered to a new list; history stripped.
        let renumbered = AskAIText.renumberingMarkers("First [3], then [1][2].", map: [3: 1, 1: 2])
        check("U10 renumber", renumbered == "First [1], then [2].", renumbered)
        check("U10 strip", AskAIText.strippingMarkers("A point [1][2].") == "A point.", AskAIText.strippingMarkers("A point [1][2]."))
        // U6, U7, U8, U13: what each question is.
        let intents: [(String, Bool, AskAIIntent?, Bool?)] = [
            ("How do I get closer to Allah?", false, nil, false),
            ("Where is the Kaaba?", false, nil, false),
            ("What does the Quran say about charitable donations?", false, nil, false),
            ("What does Islam say about compassion?", false, nil, false),
            ("How do I share inheritance among my children?", false, nil, false),
            ("How do I change the reciter?", false, .appHelp, true),
            ("How do I share an ayah?", false, .appHelp, true),
            ("Who narrated the hadith of Jibril?", true, nil, nil),
            ("who narrated that?", true, .sourceQuestion, nil),
            ("I prayed isha at 11:30, is that ok?", false, nil, nil),
            ("Is 11:30 too late for isha?", false, nil, nil),
            ("What does 2:45 say about prayer?", false, .reference, nil),
            ("What are the main themes of Surah Al-Kahf?", false, .reference, nil),
            ("What are the main themes of surah 18?", false, .reference, nil),
        ]
        for (question, hasHistory, expected, app) in intents {
            let analysed = AskAIQuestion.analyze(question, previousTopic: hasHistory ? "patience" : nil, hasHistory: hasHistory)
            var ok = expected.map { analysed.intent == $0 } ?? true
            if expected == nil {
                // Not app help, not a source question, not a verse reference.
                ok = ![.appHelp, .sourceQuestion, .reference].contains(analysed.intent)
            }
            if let app { ok = ok && analysed.mentionsApp == app }
            check("intent", ok, "\(question) -> \(analysed.intent.rawValue) mentionsApp=\(analysed.mentionsApp)")
        }
        // U8: the mask keeps the length and blanks only times.
        let masked = AskAILexicon.maskingClockTimes("I prayed isha at 11:30 and read 2:255.")
        check("U8 mask", masked.utf16.count == 38 && masked.contains("2:255") && !masked.contains("11:30"), masked)
        // U11: a long source clipped around the sentence that matched.
        let long = "Narrated Aisha: " + String(repeating: "He used to draw lots among his wives before a journey. ", count: 12)
            + "Then Yaqub said: beautiful patience is most fitting. " + String(repeating: "And the story went on. ", count: 6)
        let clipped = AskAISource.clip(long, to: 300, around: ["patience", "sabr"])
        check("U11 clip", clipped.contains("patience") && clipped.hasPrefix("\u{2026}"), String(clipped.prefix(90)))
        // U3: a transcript written before `wasQuotedBefore`, or with a field this build lacks, loads.
        let old = #"{"kind":{"ayah":{"surah":2,"ayah":153}},"reference":"2:153","title":"Al-Baqarah 2:153","text":"t","provenance":[],"aliases":[],"maxCharacters":500,"isSubject":false,"somethingNew":1}"#
        let decoded = try? JSONDecoder().decode(AskAISource.self, from: Data(old.utf8))
        check("U3 source decode", decoded?.reference == "2:153", decoded.map { "decoded \($0.reference)" } ?? "nil")
        let message = #"{"role":"assistant","text":"hi","sources":[\#(old)]}"#
        let decodedMessage = try? JSONDecoder().decode(AskAIConversation.Message.self, from: Data(message.utf8))
        check("U3 message decode", decodedMessage?.sources.count == 1, decodedMessage.map { "sources \($0.sources.count)" } ?? "nil")
        // A11: amounts typed on any keyboard.
        for (typed, expected) in [("١٢٣٤٥", 12345.0), ("1.234,56", 1234.56), ("1,234.56", 1234.56), ("٣٫٥", 3.5),
                                  ("$ 2,500", 2500.0), ("۱۰۰۰", 1000.0), ("", 0.0)] {
            let parsed = TypedAmount.parse(typed)
            check("A11 amount", abs(parsed - expected) < 0.0001, "\(typed) -> \(parsed) (expected \(expected))")
        }
        #if HAS_HADITH
        // C3: a range found in the lowercased copy sliced the original; "İ" lowercases to two scalars.
        let dotted = String(repeating: "\u{0130}", count: 16) + " sunnah.com/bukhari:1"
        let canonical = HadithReferenceParser.canonical(dotted)
        check("C3 sunnah.com slice", canonical == "bukhari 1", canonical)
        #endif
                NSLog("ASKAI PROBE DONE: %d failure(s)", failures)
    }
}
#endif

#endif
