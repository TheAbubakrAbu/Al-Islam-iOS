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

    /// A trailing "References:" / "Sources:" list is the model restating its citations; the cards
    /// beneath the answer are the references, so the block goes.
    static func droppingTrailingReferences(_ text: String) -> String {
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

    /// Every marker group rewritten to the canonical "[n]" form, one bracket per number, with the
    /// numbers that name no source removed; the count of those removed is disclosed to the reader.
    /// A marker glued to a word gets its space back ("patience[1]" -> "patience [1]").
    static func normalizeMarkers(_ text: String, sourceCount: Int) -> (text: String, removed: Int) {
        guard !text.isEmpty else { return (text, 0) }
        var removed = 0
        func rewrite(_ input: String, regex: NSRegularExpression) -> String {
            let ns = input as NSString
            var result = input
            for match in regex.matches(in: input, range: NSRange(location: 0, length: ns.length)).reversed() {
                let group = ns.substring(with: match.range)
                let groupNS = group as NSString
                var numbers: [Int] = []
                for digits in digitsRegex.matches(in: group, range: NSRange(location: 0, length: groupNS.length)) {
                    if let n = Int(groupNS.substring(with: digits.range)) {
                        if (1...sourceCount).contains(n) {
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
                if replacement.isEmpty, before == " " {
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
        return (out, removed)
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
                guard let n = Int(group.substring(with: digits.range)), (1...sources.count).contains(n) else { continue }
                if claimed.insert(n - 1).inserted { positions.append((match.range.location, n - 1)) }
            }
        }
        let lowered = text.lowercased()
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: #"\s+(?:no\.?|number|#)\s*"#, with: " ", options: .regularExpression)
        for (index, source) in sources.enumerated() where !claimed.contains(index) {
            let needles = [source.reference.lowercased()] + source.aliases
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

    /// Removes every parenthetical that cites a reference the app did NOT give the model (a verse
    /// number or a hadith number recalled from memory), returning the cleaned text and how many were
    /// removed. A parenthetical is kept when at least one of its references is a real source.
    static func policeCitations(_ text: String, sources: [AskAISource]) -> (text: String, removed: Int) {
        guard !text.isEmpty else { return (text, 0) }
        let verified = sources.flatMap { [$0.reference.lowercased()] + $0.aliases }.filter { $0.count >= 3 }
        let ns = text as NSString
        var result = text
        var removed = 0
        for match in parentheticalRegex.matches(in: text, range: NSRange(location: 0, length: ns.length)).reversed() {
            let content = ns.substring(with: match.range(at: 1))
            let contentNS = content as NSString
            let contentRange = NSRange(location: 0, length: contentNS.length)
            let citesAyah = ayahRefRegex.firstMatch(in: content, range: contentRange) != nil
            let citesHadith = hadithRefRegex.firstMatch(in: content, range: contentRange) != nil
            guard citesAyah || citesHadith else { continue }
            let lowered = content.lowercased()
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
    private static let quotationRegex = try! NSRegularExpression(pattern: #"[\"\u201C]([^\"\u201C\u201D\n]{24,400})[\"\u201D]"#)

    /// Every quotation of five or more words that is not the wording of a source the model was
    /// given is scripture recalled from memory: the quote marks come off and the span is flagged
    /// "(wording not verified)"; the count is disclosed.
    static func policeQuotations(_ text: String, sources: [AskAISource]) -> (text: String, flagged: Int) {
        guard !text.isEmpty else { return (text, 0) }
        func fold(_ s: String) -> String {
            s.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }.joined(separator: " ")
        }
        let corpus = sources.map { fold($0.text + " " + ($0.transliteration ?? "")) }
        let ns = text as NSString
        var result = text
        var flagged = 0
        for match in quotationRegex.matches(in: text, range: NSRange(location: 0, length: ns.length)).reversed() {
            let quoted = ns.substring(with: match.range(at: 1))
            let folded = fold(quoted)
            guard folded.split(separator: " ").count >= 5 else { continue }
            if corpus.contains(where: { $0.contains(folded) }) { continue }
            guard let range = Range(match.range, in: result) else { continue }
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
            result.append(NSAttributedString(string: numbers.joined(separator: "\u{2009}"), attributes: marker))
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
            text += "\n\nSources:\n" + cited.map { source in
                var line = "\u{2022} \(source.reference)"
                if !source.provenanceLine.isEmpty { line += " (\(source.provenanceLine))" }
                line += ": \u{201C}\(AskAISource.clip(source.text, to: 240))\u{201D}"
                return line
            }.joined(separator: "\n")
        }
        return text.replacingOccurrences(of: #" {2,}"#, with: " ", options: .regularExpression)
    }

    // MARK: - Follow-up suggestions

    /// Two or three next questions, built locally from the question's intent and what the answer
    /// cited: no model call, so they appear the moment the answer settles.
    static func suggestions(for question: AskAIQuestion, cited: [AskAISource]) -> [String] {
        let topic = question.topic.isEmpty ? nil : question.topic
        var out: [String] = []
        func add(_ text: String) { if !out.contains(text), out.count < 3 { out.append(text) } }

        let firstAyah = cited.first { if case .ayah = $0.kind { return true } else { return false } }
        let firstHadith = cited.first { if case .hadith = $0.kind { return true } else { return false } }
        let firstSurah = cited.first { if case .surah = $0.kind { return true } else { return false } }

        switch question.intent {
        case .greeting, .thanks, .farewell, .capabilities, .smallTalk:
            add("What does the Quran say about patience?")
            add("How do I make up a missed prayer?")
            add("Explain Ayat al-Kursi")
        case .reference:
            if let firstAyah, case .ayah(let s, let a) = firstAyah.kind {
                add("What comes before and after \(s):\(a)?")
                add("What does Ibn Kathir say about \(s):\(a)?")
                add("Are there similar verses to \(s):\(a)?")
            } else if let firstSurah, case .surah(let id) = firstSurah.kind {
                add("What are the main themes of surah \(id)?")
                add("When was surah \(id) revealed?")
                add("Which verses of surah \(id) are most often quoted?")
            } else if let firstHadith {
                add("Who narrated \(firstHadith.reference)?")
                add("What lessons does \(firstHadith.reference) teach?")
                add("Is there a Quran verse on the same point?")
            }
        case .scripture, .hadith, .general:
            if let topic {
                if question.intent != .hadith { add("What do the hadith say about \(topic)?") }
                add("Is there a dua about \(topic)?")
                if let firstAyah { add("Explain \(firstAyah.title) in more detail") }
                add("Which surah speaks most about \(topic)?")
            }
        case .define:
            if let topic {
                add("Give an example of \(topic) from the Prophet\u{2019}s life")
                add("What does the Quran say about \(topic)?")
                add("What is the opposite of \(topic)?")
            }
        case .howTo:
            if let topic {
                add("What invalidates \(topic)?")
                add("Common mistakes when doing \(topic)?")
                add("What did the Prophet say about \(topic)?")
            }
        case .ruling:
            if let topic {
                add("What is the evidence about \(topic)?")
                add("Do the schools of thought differ on \(topic)?")
            }
        case .story:
            if let topic {
                add("What lessons does the story of \(topic) teach?")
                add("Which surah tells the story of \(topic)?")
                add("Is there a hadith about \(topic)?")
            }
        case .dua:
            if let topic {
                add("When exactly is the dua for \(topic) said?")
                add("Is there a hadith on the virtue of this dua?")
            }
            add("What are the morning and evening adhkar?")
        case .appHelp:
            add("What else can I customize in this app?")
            add("How do I set up prayer notifications?")
            add("How do I change the Arabic font?")
        case .prayerTimes:
            add("How many rakahs is each prayer?")
            add("What are the sunnah prayers around the fard ones?")
            add("How do I make up a missed prayer?")
        case .sourceQuestion:
            if let firstHadith { add("Explain \(firstHadith.reference) in more detail") }
            if let firstAyah { add("What is the context of \(firstAyah.title)?") }
            add("Are there other narrations on the same point?")
        }
        if out.isEmpty {
            add("Can you explain that more simply?")
            add("Is there a dua related to this?")
        }
        return out
    }
}

#endif
