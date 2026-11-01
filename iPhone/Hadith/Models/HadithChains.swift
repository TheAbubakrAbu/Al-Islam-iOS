import Foundation

// Each hadith's chain of narrators, drawn from its own Arabic (Abu, 2026-10-27: "for each Hadith ... see
// chain and then we show the chain in Arabic and then write an image that we can share").
//
// Nothing here reads Arabic. Scripts/build_hadith_chains.py read the chains of the eleven books whose
// rows carry them, kept only the ones it could read cleanly (27,650 of them; see its header for what is
// left out and why), and shipped each as token ranges into the row's own text:
// Resources/Data/Hadith/HadithChains.qpk. This file slices those ranges out of the narration the
// reader is looking at and builds the isnad diagram (IsnadDiagram.swift): every narrator as the
// narration names him, and above him the word by which he received it from the one above (حدثنا,
// أخبرنا, عن, سمعت). `HadithChainSamples` (generated with the pack) holds the two sides together.
//
// Since later the same day, a code also names each narrator's id in the shelf's narrator index
// ("@id" on a node) and the group of chains this one is the same as ("~id" at the end), both read by
// HadithNarrators.swift from HadithNarrators.qpk: a tap on a narrator opens every narration naming
// him, and a chain lists the narrations carried by exactly the same chain. Nothing here is computed:
// the script numbered them.

/// HadithChains.qpk in the app's pack container (`QuranPackContainer`): the eager section names the
/// books (slug, compiler, chain count), and each book is one LZMA block of its chains, sorted by
/// `idInBook` (`book_block` in the script): u32 ids, u32 offsets into the codes, the ASCII codes.
/// Mapped, not read; a block is decompressed the first time a row of its book asks, cached by the
/// container, and searched where it lies, so no chain becomes an object until its sheet opens.
final class HadithChainPack: @unchecked Sendable {
    struct Book {
        let block: Int
        let compilerArabic: String
        let count: Int
    }

    let books: [String: Book]
    /// Every book's chains together: the header's unit count.
    let chainCount: Int
    private let container: QuranPackContainer

    static func bundledURL() -> URL? {
        Bundle.main.url(forResource: "HadithChains", withExtension: "qpk", subdirectory: "Data/Hadith")
            ?? Bundle.main.url(forResource: "HadithChains", withExtension: "qpk", subdirectory: "Hadith")
            ?? Bundle.main.url(forResource: "HadithChains", withExtension: "qpk")
    }

    /// The whole file decompressed comes to 1.5 MB, so every book fits the cache at once: the budget
    /// only bounds a corrupt header, and a memory warning still empties it (`purge`).
    init?(url: URL) {
        guard let container = QuranPackContainer(url: url, budget: 2 * 1024 * 1024) else { return nil }
        var reader = QuranPackReader(bytes: container.eager)
        let count = reader.u32()
        guard count > 0, count == container.recordCount, count == container.blockCount else { return nil }
        var books: [String: Book] = [:]
        var total = 0
        for block in 0..<count {
            let slug = reader.string()
            let compiler = reader.string()
            let chains = reader.u32()
            guard !slug.isEmpty, chains > 0 else { return nil }
            books[slug] = Book(block: block, compilerArabic: compiler, count: chains)
            total += chains
        }
        guard reader.remaining == 0, total == container.unitCount else { return nil }
        self.books = books
        self.chainCount = total
        self.container = container
    }

    /// The row's chain code, or nil when the script drew none for it.
    func code(slug: String, idInBook: Int) -> String? {
        withBlock(slug) { block, count in
            block.index(of: idInBook, count: count).flatMap { block.code(at: $0, count: count) }
        } ?? nil
    }

    /// A binary search and nothing more: what a row asks on every render.
    func contains(slug: String, idInBook: Int) -> Bool {
        withBlock(slug) { block, count in block.index(of: idInBook, count: count) != nil } ?? false
    }

    /// Every chain of a book in `idInBook` order: for the tests, which hold each one to its narration.
    func chains(slug: String) -> [(idInBook: Int, code: String)] {
        withBlock(slug) { block, count in
            (0..<count).compactMap { index in
                block.code(at: index, count: count).map { (idInBook: block.u32(4 * index), code: $0) }
            }
        } ?? []
    }

    func purge() { container.purge() }

    private func withBlock<T>(_ slug: String, _ body: (HadithRowBlock, Int) -> T) -> T? {
        guard let book = books[slug], let bytes = container.block(book.block),
              // The ids, the offsets, and at least the codes' start: anything shorter is not this layout.
              bytes.count >= 8 * book.count + 4 else { return nil }
        return body(HadithRowBlock(bytes: bytes), book.count)
    }
}

/// One decompressed book block of a per-row hadith pack (HadithChains.qpk, SimilarHadiths.qpk), read in
/// place: u32 row ids ascending, u32 byte offsets (one more than the rows) into the payload, then the
/// rows' payloads back to back. Integers are assembled byte by byte, as everywhere in the packs, and
/// every read is bounds-checked against the block.
struct HadithRowBlock {
    let bytes: [UInt8]

    func u32(_ at: Int) -> Int {
        guard at >= 0, at + 4 <= bytes.count else { return -1 }
        return Int(bytes[at]) | Int(bytes[at + 1]) << 8 | Int(bytes[at + 2]) << 16 | Int(bytes[at + 3]) << 24
    }

    /// The row's position among `count` rows, by binary search of the ids.
    func index(of id: Int, count: Int) -> Int? {
        var low = 0
        var high = count - 1
        while low <= high {
            let middle = (low + high) / 2
            let value = u32(4 * middle)
            if value == id { return middle }
            if value < id { low = middle + 1 } else { high = middle - 1 }
        }
        return nil
    }

    /// The id of the row at `index`.
    func id(at index: Int) -> Int { u32(4 * index) }

    /// The payload bytes of the row at `index`, or nil when the offsets do not fit the block.
    func payload(at index: Int, count: Int) -> ArraySlice<UInt8>? {
        let start = u32(4 * (count + index))
        let end = u32(4 * (count + index + 1))
        let base = 8 * count + 4
        guard start >= 0, start <= end, base + end <= bytes.count else { return nil }
        return bytes[(base + start)..<(base + end)]
    }

    /// The row's payload as ASCII text (the chains' codes); nil for an empty or ill-placed payload.
    func code(at index: Int, count: Int) -> String? {
        guard let slice = payload(at: index, count: count), !slice.isEmpty else { return nil }
        return String(decoding: slice, as: UTF8.self)
    }
}

/// The shipped chains, opened on first use. Opening maps the file and reads its header (eleven books,
/// 0.15 ms warm); a book's block is decompressed once (2 ms for al-Bukhari's 5,246 chains, measured on
/// the simulator), and from then on a row's question is a binary search. The book screen inflates its
/// book off the main thread as it appears (`prewarm(slug:)`), a chapter before any row asks; a row that
/// gets there first (search, bookmarks) inflates it itself. Either way a row drawn at any moment gets
/// the true answer, so nothing is published and no row observes this.
final class HadithChainStore: @unchecked Sendable {
    static let shared = HadithChainStore()
    private init() {}

    private let lock = NSLock()
    private var opened = false
    private var openedPack: HadithChainPack?

    /// The pack, opened once; nil for good when it is missing or does not parse (no chain is offered).
    var pack: HadithChainPack? {
        lock.lock()
        defer { lock.unlock() }
        if !opened {
            opened = true
            openedPack = HadithChainPack.bundledURL().flatMap(HadithChainPack.init(url:))
        }
        return openedPack
    }

    /// Opens the pack and inflates one book's chains off the main thread. The container decompresses
    /// outside its lock, so a row asking meanwhile never waits on this; at worst both inflate the block.
    func prewarm(slug: String) {
        DispatchQueue.global(qos: .utility).async {
            _ = self.pack?.contains(slug: slug, idInBook: 0)
        }
    }

    func hasChain(slug: String, idInBook: Int) -> Bool {
        pack?.contains(slug: slug, idInBook: idInBook) ?? false
    }

    /// The chain of this narration, or nil when it has none the app can draw. With `english`, every
    /// chip and every word of transmission carries its English too (`HadithIsnadEnglish`): the
    /// narrators' names from the narrator index, so this reads that pack as well (off the main thread).
    func chain(slug: String, idInBook: Int, arabic: String, bookTitle: String, english: Bool = false) -> IsnadChain? {
        guard let pack, let book = pack.books[slug], let code = pack.code(slug: slug, idInBook: idInBook) else { return nil }
        return HadithChainDecoder.chain(code: code, arabic: arabic, compilerArabic: book.compilerArabic, bookTitle: bookTitle,
                                        english: english ? HadithIsnadEnglish(slug: slug) : nil)
    }

    /// The group of chains this narration's is the same as (HadithNarrators.qpk), or nil when no other
    /// narration on the shelf is carried by exactly this chain. A binary search and a short parse.
    func chainGroup(slug: String, idInBook: Int) -> Int? {
        guard let code = pack?.code(slug: slug, idInBook: idInBook),
              let tilde = code.firstIndex(of: "~") else { return nil }
        return Int(code[code.index(after: tilde)...])
    }

    /// Memory pressure (`MemoryTrim`): the decompressed books go; the next row to ask inflates its own again.
    func purge() {
        lock.lock()
        let loaded = openedPack
        lock.unlock()
        loaded?.purge()
    }
}

/// A chain code turned back into names: the mirror of `encode` and `layers_top_down` in
/// Scripts/build_hadith_chains.py.
enum HadithChainDecoder {
    struct Node {
        let first: Int
        let last: Int
        let verb: Int?
        let aside: ClosedRange<Int>?
        /// Joined to the narrator before it by "، و": its first word carries the و.
        let joint: Bool
        /// His row in HadithNarrators.qpk; nil for a relation ("أبيه", "عمه"), who is no one's profile.
        let narrator: Int?
    }

    typealias Layer = [Node]

    struct Parsed {
        let tokenCount: Int
        /// Each road below the meeting point, layers upward, and the word its top received by.
        let branches: [(layers: [Layer], topVerb: Int?)]
        /// From the meeting point (or the collector's teacher) up to the last narrator.
        let shared: [Layer]
        let prophet: Bool
        let prophetVerb: Int?
        /// The group of chains this one is the same as (HadithNarrators.qpk), when another has it too.
        let group: Int?
    }

    /// The narration's words as Python's `str.split()` counts them: runs of non-whitespace scalars.
    static func tokens(_ text: String) -> [String] {
        var out: [String] = []
        var current = String.UnicodeScalarView()
        for scalar in text.unicodeScalars {
            if scalar.properties.isWhitespace {
                if !current.isEmpty { out.append(String(current)); current = String.UnicodeScalarView() }
            } else {
                current.append(scalar)
            }
        }
        if !current.isEmpty { out.append(String(current)) }
        return out
    }

    private static let stripped: Set<UInt32> = [0x060C, 0x2C, 0x200F, 0x200E, 0x22, 0x201C, 0x201D, 0x3A, 0x061B, 0x3B, 0x2E]

    static func clean(_ text: String) -> String {
        var kept = String.UnicodeScalarView()
        for scalar in text.unicodeScalars where !stripped.contains(scalar.value) {
            kept.append(scalar)
        }
        return tokens(String(kept)).joined(separator: " ")
    }

    /// "وَحَرْمَلَةُ" -> "حَرْمَلَةُ": the و (or ف) that joins a word, with its vowel.
    static func droppingConjunction(_ text: String) -> String {
        let scalars = Array(text.unicodeScalars)
        guard let first = scalars.first, first.value == 0x0648 || first.value == 0x0641 else { return text }
        var index = 1
        while index < scalars.count, (0x064B...0x065F).contains(scalars[index].value) || scalars[index].value == 0x0670 {
            index += 1
        }
        var view = String.UnicodeScalarView()
        view.append(contentsOf: scalars[index...])
        return String(view)
    }

    static func parse(_ code: String) -> Parsed? {
        var code = Substring(code)
        var group: Int?
        if let tilde = code.firstIndex(of: "~") {
            group = Int(code[code.index(after: tilde)...])
            code = code[..<tilde]
        }
        guard let colon = code.firstIndex(of: ":"), let count = Int(code[..<colon]) else { return nil }
        var body = String(code[code.index(after: colon)...])
        var prophet = false
        var prophetVerb: Int?
        if let bang = body.firstIndex(of: "!") {
            prophet = true
            prophetVerb = Int(body[body.index(after: bang)...])
            body = String(body[..<bang])
        }
        var branches: [(layers: [Layer], topVerb: Int?)] = []
        var sharedPart = body
        if let equals = body.firstIndex(of: "=") {
            sharedPart = String(body[body.index(after: equals)...])
            for road in body[..<equals].split(separator: "#") {
                let pieces = road.split(separator: "^", omittingEmptySubsequences: false)
                guard let layers = parseLayers(String(pieces[0])) else { return nil }
                branches.append((layers, pieces.count > 1 ? Int(pieces[1]) : nil))
            }
        }
        guard let shared = parseLayers(sharedPart), !shared.isEmpty else { return nil }
        return Parsed(tokenCount: count, branches: branches, shared: shared, prophet: prophet, prophetVerb: prophetVerb,
                      group: group)
    }

    private static func parseLayers(_ text: String) -> [Layer]? {
        var layers: [Layer] = []
        for layerText in text.split(separator: "|") {
            var layer: Layer = []
            for nodeText in layerText.split(separator: "+") {
                var fields = String(nodeText)
                var narrator: Int?
                if let at = fields.firstIndex(of: "@") {
                    narrator = Int(fields[fields.index(after: at)...])
                    fields = String(fields[..<at])
                }
                let joint = fields.hasSuffix("j")
                if joint { fields.removeLast() }
                let numbers = fields.split(separator: ".").compactMap { Int($0) }
                guard numbers.count == 3 || numbers.count == 5 else { return nil }
                layer.append(Node(first: numbers[0], last: numbers[1], verb: numbers[2],
                                  aside: numbers.count == 5 ? numbers[3]...numbers[4] : nil, joint: joint,
                                  narrator: narrator))
            }
            guard !layer.isEmpty else { return nil }
            layers.append(layer)
        }
        return layers
    }

    static func name(_ node: Node, _ words: [String]) -> String {
        let text = clean(words[node.first...node.last].joined(separator: " "))
        return node.joint ? droppingConjunction(text) : text
    }

    static func verb(_ index: Int?, _ words: [String]) -> String {
        guard let index, words.indices.contains(index) else { return "" }
        return droppingConjunction(clean(words[index]))
    }

    /// (title, names) top to bottom, the Prophet ﷺ and the collector left out: what the samples test
    /// compares with the script.
    static func columns(_ parsed: Parsed, _ words: [String]) -> (top: [(String, [String])], branches: [[(String, [String])]]) {
        func column(_ layers: [Layer], topVerb: Int?) -> [(String, [String])] {
            layers.indices.map { index -> (String, [String]) in
                let above = index + 1 < layers.count ? layers[index + 1][0].verb : topVerb
                return (verb(above, words), layers[index].map { name($0, words) })
            }.reversed()
        }
        let top = column(parsed.shared, topVerb: parsed.prophet ? parsed.prophetVerb : nil)
        return (top, parsed.branches.map { column($0.layers, topVerb: $0.topVerb) })
    }

    private static func fits(_ parsed: Parsed, count: Int) -> Bool {
        guard parsed.tokenCount == count else { return false }
        let nodes = (parsed.branches.flatMap(\.layers) + parsed.shared).flatMap { $0 }
        return nodes.allSatisfy { node in
            node.first >= 0 && node.first <= node.last && node.last < count
                && (node.verb.map { $0 < count } ?? true)
                && (node.aside.map { $0.upperBound < count } ?? true)
        }
    }

    /// The diagram's chain. Nil when the narration's words no longer match what the code was read
    /// from (a rebuilt pack): a misplaced name is never drawn. With `english`, each node's `name` is
    /// its English and each layer's `subtitle` the English of its word of transmission.
    static func chain(code: String, arabic: String, compilerArabic: String, bookTitle: String,
                      english: HadithIsnadEnglish? = nil) -> IsnadChain? {
        guard let parsed = parse(code) else { return nil }
        let words = tokens(arabic)
        guard fits(parsed, count: words.count) else { return nil }

        let meets = !parsed.branches.isEmpty
        func nodes(_ layer: Layer, role: IsnadNode.Role) -> [IsnadNode] {
            layer.map { node in
                let arabic = name(node, words)
                return IsnadNode(name: english?.narrator(arabic: arabic, id: node.narrator) ?? "", arabic: arabic,
                                 detail: node.aside.map { clean(words[$0].joined(separator: " ")) },
                                 role: role, narratorID: node.narrator)
            }
        }
        func layer(title: String, nodes: [IsnadNode]) -> IsnadLayer {
            var out = IsnadLayer(title: title, nodes: nodes)
            out.subtitle = english?.transmission(title)
            return out
        }
        func layers(_ column: [Layer], topVerb: Int?, isShared: Bool) -> [IsnadLayer] {
            column.indices.map { index -> IsnadLayer in
                let above = index + 1 < column.count ? column[index + 1][0].verb : topVerb
                let isTop = isShared && index == column.count - 1
                let role: IsnadNode.Role = isTop && parsed.prophet ? .companion
                    : (isShared && meets && index == 0 ? .imam : .link)
                return layer(title: verb(above, words), nodes: nodes(column[index], role: role))
            }.reversed()
        }

        var top: [IsnadLayer] = []
        if parsed.prophet {
            top.append(IsnadLayer(title: "", nodes: [IsnadNode(name: english == nil ? "" : HadithIsnadEnglish.prophet,
                                                               arabic: "رَسُولُ اللَّهِ ﷺ", role: .prophet)]))
        }
        top += layers(parsed.shared, topVerb: parsed.prophet ? parsed.prophetVerb : nil, isShared: true)
        let branches = parsed.branches.enumerated().map { index, road in
            IsnadBranch(id: "road-\(index)", highlighted: true, layers: layers(road.layers, topVerb: road.topVerb, isShared: false))
        }
        let firstRoad = parsed.branches.first?.layers ?? parsed.shared
        let collector = layer(title: verb(firstRoad[0][0].verb, words),
                              nodes: [IsnadNode(name: english?.compiler ?? "", arabic: compilerArabic, detail: bookTitle, role: .narrator)])
        return IsnadChain(top: top, branches: branches, bottom: [collector])
    }
}

// MARK: - The chain in English

/// The English of a hadith chain (Abu, 2026-10-31: "would be fire if we can also translate the chain
/// for English and the chain of narrators"): a narrator's name from the narrator index, where the
/// script transliterated it (Scripts/arabic_translit.py), a relation ("أبيه") and a word of
/// transmission ("حدثنا") from the two short tables here, the compiler by his book. Looked up while
/// the chain is decoded, off the main thread; nothing is translated at render.
struct HadithIsnadEnglish {
    static let prophet = String(localized: "The Messenger of Allah ﷺ")

    /// Who stands at the foot of each book's chains, as Scripts/build_hadith_chains.py names him.
    private static let compilers: [String: String] = [
        "bukhari": "al-Bukhari", "muslim": "Muslim", "abudawud": "Abu Dawud", "tirmidhi": "at-Tirmidhi",
        "nasai": "an-Nasa'i", "ibnmajah": "Ibn Majah", "malik": "Yahya al-Laythi", "darimi": "ad-Darimi",
        "ahmed": "Ahmad ibn Hanbal", "aladab_almufrad": "al-Bukhari", "shamail_muhammadiyah": "at-Tirmidhi",
    ]

    /// The words a narrator receives a narration by, as the script's `key` folds them (marks off,
    /// hamza seats to alef, ى to ي, ة to ه), with the و or ف that joins them to the sentence dropped.
    private static let transmissions: [String: String] = [
        "حدثنا": "narrated to us", "حدثني": "narrated to me", "حدثناه": "narrated it to us", "حدثنيه": "narrated it to me",
        "حدثه": "narrated to him", "حدثهم": "narrated to them", "حدثهما": "narrated to the two of them",
        "حدثتني": "she narrated to me", "حدثتنا": "she narrated to us", "حدثها": "narrated to her",
        "حدثته": "she narrated to him", "حدثتها": "she narrated to her", "حدثتهم": "she narrated to them",
        "حدثتهما": "she narrated to the two of them", "حدثاه": "the two narrated to him", "حدثوه": "they narrated to him",
        "حدثونا": "they narrated to us", "حدثوهم": "they narrated to them", "ثنا": "narrated to us",
        "اخبرنا": "informed us", "اخبرني": "informed me", "اخبرناه": "informed us of it", "اخبرنيه": "informed me of it",
        "اخبره": "informed him", "اخبرهم": "informed them", "اخبرهما": "informed the two of them",
        "اخبرتني": "she informed me", "اخبرتنا": "she informed us", "اخبرها": "informed her",
        "اخبرته": "she informed him", "اخبرتها": "she informed her", "اخبرتهم": "she informed them",
        "اخبراه": "the two informed him", "اخبروه": "they informed him", "اخبرونا": "they informed us",
        "انبانا": "told us", "انباني": "told me", "نبانا": "told us",
        "سمعت": "I heard", "سمع": "heard", "سمعنا": "we heard", "سمعا": "the two heard",
        "سمعته": "I heard him", "سمعاه": "the two heard him",
        "قرات": "I read to", "قرئ": "it was read to", "قراه": "he read it to", "قرانا": "we read to",
        "عن": "from", "ان": "that", "انه": "that he", "انها": "that she", "انهم": "that they", "انهما": "that the two",
        "قال": "said", "قالت": "she said", "قالا": "the two said", "قالوا": "they said", "يقول": "says",
        "تقول": "she says", "يقولان": "the two say", "يحدث": "narrates", "تحدث": "she narrates",
        "يخبر": "informs", "يحدثه": "narrates to him", "يذكر": "mentions", "ذكر": "mentioned", "فقال": "then said",
    ]

    /// A narrator named by his relation to the one below him.
    private static let relations: [String: String] = [
        "ابيه": "his father", "ابيها": "her father", "امه": "his mother", "امها": "her mother",
        "جده": "his grandfather", "جدته": "his grandmother", "جدها": "her grandfather", "جديه": "his two grandfathers",
        "عمه": "his paternal uncle", "عمها": "her paternal uncle", "عمته": "his paternal aunt",
        "خاله": "his maternal uncle", "خالها": "her maternal uncle", "خالته": "his maternal aunt",
        "اخيه": "his brother", "اخيها": "her brother", "اخوه": "his brother", "اخته": "his sister",
        "ابنه": "his son", "ابنته": "his daughter", "ابويه": "his parents",
        "مولاه": "his mawla", "مولاته": "her mawla", "زوجها": "her husband", "زوجته": "his wife",
        "امراته": "his wife", "امراه": "a woman",
    ]

    let compiler: String

    init(slug: String) {
        compiler = Self.compilers[slug] ?? HadithCatalogBook.bySlug[slug]?.displayAuthor ?? ""
    }

    /// The script's `key`: marks off, the hamza seats and alefs to one alef, ى to ي, ة to ه, the
    /// punctuation the names carry out.
    static func fold(_ text: String) -> String {
        var out = String.UnicodeScalarView()
        for scalar in text.removingArabicDiacriticsAndSigns.unicodeScalars {
            switch scalar.value {
            case 0x0623, 0x0625, 0x0622, 0x0671: out.append(UnicodeScalar(0x0627)!)
            case 0x0649: out.append(UnicodeScalar(0x064A)!)
            case 0x0629: out.append(UnicodeScalar(0x0647)!)
            case 0x060C, 0x002C, 0x003A, 0x061B, 0x003B, 0x002E, 0x0022, 0x201C, 0x201D, 0x200F, 0x200E: continue
            default: out.append(scalar)
            }
        }
        return String(out)
    }

    /// The English of a word of transmission; nil when the word is not one the table knows (the
    /// Arabic then stands alone, as it did).
    func transmission(_ arabic: String) -> String? {
        guard !arabic.isEmpty else { return nil }
        let key = Self.fold(HadithChainDecoder.droppingConjunction(arabic))
        if let found = Self.transmissions[key] { return found }
        // "وحدثنا" and "فقال" fold with their conjunction kept when the vowel sat on it.
        for prefix in ["و", "ف"] where key.hasPrefix(prefix) {
            if let found = Self.transmissions[String(key.dropFirst())] { return found }
        }
        return nil
    }

    /// A narrator's English: his indexed name when he has a profile, his relation when he is named
    /// by one, else nothing.
    func narrator(arabic: String, id: Int?) -> String {
        if let id, let profile = HadithNarratorStore.shared.profile(id: id), !profile.english.isEmpty {
            return profile.english
        }
        return Self.relations[Self.fold(arabic)] ?? ""
    }
}
