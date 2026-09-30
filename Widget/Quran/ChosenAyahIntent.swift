#if os(iOS)
import AppIntents
import Foundation

// The Chosen Ayah widget's configuration (Abu, 2026-09-28: "customize lock screen and Home Screen
// Quran widgets from bookmarks or allow me to enter them so I can customize them").
//
// Compiled into the app AND the widget extension. The extension runs the picker (`ChosenAyahQuery`,
// behind "Edit Widget") and renders the widget; the app reads the placed widgets' choices back
// (`WidgetCenter.getCurrentConfigurations`) to pre-render every chosen ayah with the reader's own
// font, tajweed colors and text settings (`Settings.refreshQuranWidgets(.chosenAyahs)`). What the
// two processes share is the App Group snapshot (`QuranWidgetSnapshot`): the app writes the bookmark
// list and the rendered cards, the extension reads them.

/// The 114 surahs: transliterated name, Arabic name, ayah count. Static so the picker can name and
/// validate a typed reference ("2:255", "Baqarah 255") with no pack open in the extension process.
/// GENERATED from Quran.json (names as the app spells them); every count matches quran.qpk.
enum ChosenAyahCatalog {
    struct Entry {
        let id: Int
        let name: String
        let arabicName: String
        let ayahCount: Int
    }

    static let surahs: [Entry] = [
        (1, "Al-Fatihah", "الفَاتِحَة", 7),
        (2, "Al-Baqarah", "البَقَرَة", 286),
        (3, "Ali 'Imran", "آلِ عِمرَان", 200),
        (4, "An-Nisa", "النِّسَاء", 176),
        (5, "Al-Ma'idah", "المَائِدَة", 120),
        (6, "Al-An'am", "الأَنعَام", 165),
        (7, "Al-A'raf", "الأَعرَاف", 206),
        (8, "Al-Anfal", "الأَنفَال", 75),
        (9, "At-Tawbah", "التَّوبَة", 129),
        (10, "Yunus", "يُونُس", 109),
        (11, "Hud", "هُود", 123),
        (12, "Yusuf", "يُوسُف", 111),
        (13, "Ar-Ra'd", "الرَّعد", 43),
        (14, "Ibrahim", "إِبرَاهِيم", 52),
        (15, "Al-Hijr", "الحِجر", 99),
        (16, "An-Nahl", "النَّحل", 128),
        (17, "Al-Israa", "الإِسرَاء", 111),
        (18, "Al-Kahf", "الكَهف", 110),
        (19, "Maryam", "مَريَم", 98),
        (20, "Taha", "طه", 135),
        (21, "Al-Anbya", "الأَنبِيَاء", 112),
        (22, "Al-Hajj", "الحَج", 78),
        (23, "Al-Mu'minun", "المُؤمِنُون", 118),
        (24, "An-Noor", "النُّور", 64),
        (25, "Al-Furqan", "الفُرقَان", 77),
        (26, "Ash-Shu'ara", "الشُّعَرَاء", 227),
        (27, "An-Naml", "النَّمل", 93),
        (28, "Al-Qasas", "القَصَص", 88),
        (29, "Al-'Ankabut", "العَنكَبُوت", 69),
        (30, "Ar-Rum", "الرُّوم", 60),
        (31, "Luqman", "لُقمَان", 34),
        (32, "As-Sajdah", "السَّجدَة", 30),
        (33, "Al-Ahzab", "الأَحزَاب", 73),
        (34, "Saba", "سَبَإ", 54),
        (35, "Fatir", "فَاطِر", 45),
        (36, "Ya-Sin", "يسٓ", 83),
        (37, "As-Saffat", "الصَّافَّات", 182),
        (38, "Sad", "ص", 88),
        (39, "Az-Zumar", "الزُّمَر", 75),
        (40, "Ghafir", "غَافِر", 85),
        (41, "Fussilat", "فُصِّلَت", 54),
        (42, "Ash-Shuraa", "الشُّورَى", 53),
        (43, "Az-Zukhruf", "الزُّخرُف", 89),
        (44, "Ad-Dukhan", "الدُّخَان", 59),
        (45, "Al-Jathiyah", "الجَاثِيَة", 37),
        (46, "Al-Ahqaf", "الأَحقَاف", 35),
        (47, "Muhammad", "مُحَمَّد", 38),
        (48, "Al-Fath", "الفَتح", 29),
        (49, "Al-Hujurat", "الحُجُرَات", 18),
        (50, "Qaf", "ق", 45),
        (51, "Adh-Dhariyat", "الذَّارِيَات", 60),
        (52, "At-Tur", "الطُّور", 49),
        (53, "An-Najm", "النَّجم", 62),
        (54, "Al-Qamar", "القَمَر", 55),
        (55, "Ar-Rahman", "الرَّحمَٰن", 78),
        (56, "Al-Waqi'ah", "الوَاقِعَة", 96),
        (57, "Al-Hadid", "الحَدِيد", 29),
        (58, "Al-Mujadila", "المُجَادِلَة", 22),
        (59, "Al-Hashr", "الحَشر", 24),
        (60, "Al-Mumtahanah", "المُمتَحَنَة", 13),
        (61, "As-Saf", "الصَّف", 14),
        (62, "Al-Jumu'ah", "الجُمُعَة", 11),
        (63, "Al-Munafiqun", "المُنَافِقُون", 11),
        (64, "At-Taghabun", "التَّغَابُن", 18),
        (65, "At-Talaq", "الطَّلَاق", 12),
        (66, "At-Tahrim", "التَّحرِيم", 12),
        (67, "Al-Mulk", "المُلك", 30),
        (68, "Al-Qalam", "القَلَم", 52),
        (69, "Al-Haqqah", "الحَاقَّة", 52),
        (70, "Al-Ma'arij", "المَعَارِج", 44),
        (71, "Nuh", "نُوح", 28),
        (72, "Al-Jinn", "الجِنّ", 28),
        (73, "Al-Muzzammil", "المُزَّمِّل", 20),
        (74, "Al-Muddaththir", "المُدَّثِّر", 56),
        (75, "Al-Qiyamah", "القِيَامَة", 40),
        (76, "Al-Insan", "الإِنسَان", 31),
        (77, "Al-Mursalat", "المُرسَلَات", 50),
        (78, "An-Naba", "النَّبَإ", 40),
        (79, "An-Nazi'at", "النَّازِعَات", 46),
        (80, "'Abasa", "عَبَس", 42),
        (81, "At-Takwir", "التَّكوِير", 29),
        (82, "Al-Infitar", "الإنفِطَار", 19),
        (83, "Al-Mutaffifin", "المُطَفِّفِين", 36),
        (84, "Al-Inshiqaq", "الإنشِقَاق", 25),
        (85, "Al-Buruj", "البُرُوج", 22),
        (86, "At-Tariq", "الطَّارِق", 17),
        (87, "Al-A'la", "الأَعلَى", 19),
        (88, "Al-Ghashiyah", "الغَاشِية", 26),
        (89, "Al-Fajr", "الفَجر", 30),
        (90, "Al-Balad", "البَلَد", 20),
        (91, "Ash-Shams", "الشَّمس", 15),
        (92, "Al-Layl", "اللَّيل", 21),
        (93, "Ad-Duhaa", "الضُّحَى", 11),
        (94, "Ash-Sharh", "الشَّرح", 8),
        (95, "At-Tin", "التِّين", 8),
        (96, "Al-'Alaq", "العَلَق", 19),
        (97, "Al-Qadr", "القَدر", 5),
        (98, "Al-Bayyinah", "البَيِّنَة", 8),
        (99, "Az-Zalzalah", "الزَّلزَلَة", 8),
        (100, "Al-'Adiyat", "العَادِيَات", 11),
        (101, "Al-Qari'ah", "القَارِعَة", 11),
        (102, "At-Takathur", "التَّكَاثُر", 8),
        (103, "Al-'Asr", "العَصر", 3),
        (104, "Al-Humazah", "الهُمَزَة", 9),
        (105, "Al-Fil", "الفِيل", 5),
        (106, "Quraysh", "قُرَيش", 4),
        (107, "Al-Ma'un", "المَاعُون", 7),
        (108, "Al-Kawthar", "الكَوثَر", 3),
        (109, "Al-Kafirun", "الكَافِرُون", 6),
        (110, "An-Nasr", "النَّصر", 3),
        (111, "Al-Masad", "المَسَد", 5),
        (112, "Al-Ikhlas", "الإِخلَاص", 4),
        (113, "Al-Falaq", "الفَلَق", 5),
        (114, "An-Nas", "النَّاس", 6),
    ].map { Entry(id: $0.0, name: $0.1, arabicName: $0.2, ayahCount: $0.3) }

    static func surah(_ id: Int) -> Entry? {
        guard (1...surahs.count).contains(id) else { return nil }
        return surahs[id - 1]
    }

    static func isValid(surah: Int, ayah: Int) -> Bool {
        guard let entry = Self.surah(surah) else { return false }
        return (1...entry.ayahCount).contains(ayah)
    }

    /// "Al-Baqarah 2:255": the reference every surface of the widget shows.
    static func reference(surah: Int, ayah: Int) -> String {
        guard let entry = Self.surah(surah) else { return "\(surah):\(ayah)" }
        return "\(entry.name) \(surah):\(ayah)"
    }

    /// The name index the picker's text search uses: every surah's transliterated and English-ish
    /// spellings plus the curated aliases (`SurahSpelling.latin`), folded the way the Quran tab folds
    /// a typed surah name. Built once per process.
    private static let foldedNames: [(id: Int, names: [String])] = surahs.map { entry in
        var names = Set<String>()
        names.insert(entry.name.normalizedForSurahQuery)
        names.formUnion(entry.name.transliterationSearchAliases)
        names.insert(entry.arabicName.normalizedForSurahQuery)
        for alias in SurahSpelling.latin[entry.id] ?? [] {
            names.insert(alias.normalizedForSurahQuery)
            names.formUnion(alias.transliterationSearchAliases)
        }
        return (entry.id, Array(names).filter { !$0.isEmpty })
    }

    /// Surahs whose name matches a folded query: exact names first, then names containing it, and
    /// when neither finds anything, the Quran tab's spelling fold (`SpellingFold`), so "Yaseen" and
    /// "Rehman" resolve the way they do in the surah list and for Siri.
    static func surahs(named query: String) -> [Entry] {
        let folded = query.normalizedSurahIntentQuery
        guard !folded.isEmpty else { return [] }
        let exact = foldedNames.filter { $0.names.contains(folded) }.map(\.id)
        let partial = foldedNames.filter { row in row.names.contains { $0.contains(folded) } }.map(\.id)
        var seen = Set<Int>()
        let direct = (exact + partial).filter { seen.insert($0).inserted }.compactMap(surah)
        if !direct.isEmpty { return direct }
        return SpellingFold.matches(folded, in: surahs) { foldEntries[$0.id - 1] }
    }

    /// One fold entry per surah (its name plus the curated aliases), built once per process.
    private static let foldEntries: [SpellingFold.Entry] = surahs.map {
        SpellingFold.Entry(names: [$0.name] + (SurahSpelling.latin[$0.id] ?? []))
    }
}

/// One ayah, as the thing the widget is configured with. The id is the reference ("2:255"), so an
/// ayah typed into the picker and one picked from the bookmarks resolve to the same entity.
@available(iOS 17.0, *)
struct ChosenAyahEntity: AppEntity, Identifiable {
    let id: String
    let surah: Int
    let ayah: Int
    /// The picker row's second line: the bookmark's note when it has one, else a translation snippet.
    var subtitle: String?

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Ayah" }
    static var defaultQuery = ChosenAyahQuery()

    var displayRepresentation: DisplayRepresentation {
        let title = ChosenAyahCatalog.reference(surah: surah, ayah: ayah)
        if let subtitle, !subtitle.isEmpty {
            return DisplayRepresentation(title: "\(title)", subtitle: "\(subtitle)")
        }
        return DisplayRepresentation(title: "\(title)")
    }

    init(surah: Int, ayah: Int, subtitle: String? = nil) {
        self.id = "\(surah):\(ayah)"
        self.surah = surah
        self.ayah = ayah
        self.subtitle = subtitle
    }

    /// From a stored id ("2:255"); nil for anything that is not a real ayah.
    init?(id: String) {
        guard let ref = ChosenAyahReference.parse(id), ChosenAyahCatalog.isValid(surah: ref.surah, ayah: ref.ayah) else { return nil }
        self.init(surah: ref.surah, ayah: ref.ayah)
    }
}

/// Turns what a person types into an ayah: "2:255", "2 255", "2.255", "Baqarah 255", "surah
/// al-baqarah ayah 255", "kursi 255", a bare "36" (the surah's first ayah), Arabic-Indic digits.
enum ChosenAyahReference {
    static func parse(_ raw: String) -> (surah: Int, ayah: Int)? {
        let text = raw.normalizedSurahIntentQuery
            .replacingOccurrences(of: #"\b(ayah|ayat|verse|aya|آية|اية)\b"#, with: " ", options: .regularExpression)
        guard !text.isEmpty else { return nil }

        // Every number in the text, in order; the letters left over are a surah name (if any).
        let numbers = text.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }
        let letters = text.components(separatedBy: CharacterSet.decimalDigits)
            .joined(separator: " ")
            .trimmingCharacters(in: CharacterSet(charactersIn: " :.,-/"))
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if numbers.count >= 2, letters.isEmpty {
            return validated(surah: numbers[0], ayah: numbers[1])
        }
        if !letters.isEmpty, let surah = ChosenAyahCatalog.surahs(named: letters).first {
            // "Baqarah 255" names the ayah; "Al-Baqarah 2:255" (the widget's own title format)
            // carries the surah's number first and the ayah LAST: taking the first number read
            // it as 2:2, and "An-Nas 114:1" as ayah 114 of An-Nas, which is nothing.
            return validated(surah: surah.id, ayah: numbers.count >= 2 ? numbers[numbers.count - 1] : (numbers.first ?? 1))
        }
        if numbers.count == 1, letters.isEmpty {
            return validated(surah: numbers[0], ayah: 1)
        }
        return nil
    }

    private static func validated(surah: Int, ayah: Int) -> (surah: Int, ayah: Int)? {
        ChosenAyahCatalog.isValid(surah: surah, ayah: ayah) ? (surah, ayah) : nil
    }
}

/// What the widget shows when nobody has chosen an ayah yet: the most recent bookmark, else Ayat
/// al-Kursi. One rule, used by the extension (to render) and by the app (to pre-render the same ayah).
enum ChosenAyahDefault {
    static let fallback = (surah: 2, ayah: 255)

    static func resolve(bookmarks: [QuranWidgetSnapshot.BookmarkCard]?) -> (surah: Int, ayah: Int) {
        guard let bookmarks, !bookmarks.isEmpty else { return fallback }
        // Newest by its stamp; rows from before the stamp existed (2026-09-07) count as oldest, and
        // among those the last appended wins.
        let newest = bookmarks.enumerated().max { a, b in
            let aStamp = a.element.createdAt ?? .distantPast
            let bStamp = b.element.createdAt ?? .distantPast
            return aStamp == bStamp ? a.offset < b.offset : aStamp < bStamp
        }
        guard let pick = newest?.element else { return fallback }
        return (pick.surah, pick.ayah)
    }
}

@available(iOS 17.0, *)
struct ChosenAyahQuery: EntityQuery, EntityStringQuery {
    /// The bookmarks the app mirrored for the picker (nil before the app has run this version).
    private var bookmarks: [QuranWidgetSnapshot.BookmarkCard] {
        QuranWidgetStore.load()?.bookmarks ?? []
    }

    private func entity(surah: Int, ayah: Int, bookmarks: [QuranWidgetSnapshot.BookmarkCard]) -> ChosenAyahEntity {
        let bookmark = bookmarks.first { $0.surah == surah && $0.ayah == ayah }
        return ChosenAyahEntity(surah: surah, ayah: ayah, subtitle: bookmark?.pickerSubtitle)
    }

    func entities(for identifiers: [String]) async throws -> [ChosenAyahEntity] {
        let bookmarks = self.bookmarks
        return identifiers.compactMap { id in
            guard let ref = ChosenAyahReference.parse(id), ChosenAyahCatalog.isValid(surah: ref.surah, ayah: ref.ayah) else { return nil }
            return entity(surah: ref.surah, ayah: ref.ayah, bookmarks: bookmarks)
        }
    }

    /// The list under the search field: every bookmark in mushaf order, or a few well-known ayahs
    /// for someone who has none yet.
    func suggestedEntities() async throws -> [ChosenAyahEntity] {
        let bookmarks = self.bookmarks
        if !bookmarks.isEmpty {
            return bookmarks.map { ChosenAyahEntity(surah: $0.surah, ayah: $0.ayah, subtitle: $0.pickerSubtitle) }
        }
        return Self.starters.map { ChosenAyahEntity(surah: $0.surah, ayah: $0.ayah, subtitle: $0.label) }
    }

    /// Typed text: a reference first ("2:255", "Yaseen 9"), then bookmarks whose reference, note or
    /// translation contains the words, then the surahs whose name matches (their first ayah).
    func entities(matching string: String) async throws -> [ChosenAyahEntity] {
        let bookmarks = self.bookmarks
        let query = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return try await suggestedEntities() }

        var results: [ChosenAyahEntity] = []
        var seen = Set<String>()
        func add(_ entity: ChosenAyahEntity) {
            if seen.insert(entity.id).inserted { results.append(entity) }
        }

        if let ref = ChosenAyahReference.parse(query) {
            add(entity(surah: ref.surah, ayah: ref.ayah, bookmarks: bookmarks))
        }
        let folded = query.normalizedForSurahQuery
        for bookmark in bookmarks {
            let blob = [
                ChosenAyahCatalog.reference(surah: bookmark.surah, ayah: bookmark.ayah),
                "\(bookmark.surah):\(bookmark.ayah)",
                bookmark.note ?? "",
                bookmark.english
            ].joined(separator: " ").normalizedForSurahQuery
            if blob.contains(folded) {
                add(ChosenAyahEntity(surah: bookmark.surah, ayah: bookmark.ayah, subtitle: bookmark.pickerSubtitle))
            }
        }
        // The surah-name fallback reads the words alone: "Yaseen 36:9" searched surahs named
        // "yaseen 36 9".
        let words = query.components(separatedBy: CharacterSet.decimalDigits.union(CharacterSet(charactersIn: ":.")))
            .joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        for surah in ChosenAyahCatalog.surahs(named: words.isEmpty ? query : words).prefix(8) {
            add(entity(surah: surah.id, ayah: 1, bookmarks: bookmarks))
        }
        return results
    }

    /// Well-known places, offered only to someone with no bookmarks.
    private static let starters: [(surah: Int, ayah: Int, label: String)] = [
        (2, 255, "Ayat al-Kursi"),
        (1, 1, "Al-Fatihah"),
        (2, 286, "The last ayah of al-Baqarah"),
        (36, 1, "Ya-Sin"),
        (55, 1, "Ar-Rahman"),
        (67, 1, "Al-Mulk"),
        (112, 1, "Al-Ikhlas"),
    ]
}

extension QuranWidgetSnapshot.BookmarkCard {
    /// The note when there is one, else the translation snippet.
    var pickerSubtitle: String? {
        if let note = note?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty { return note }
        return english.isEmpty ? nil : english
    }
}

/// The widget's configuration: which ayah, and whether the translation rides along.
@available(iOS 17.0, *)
struct ChosenAyahConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Chosen Ayah"
    static var description = IntentDescription("Pick one of your bookmarks, or type a reference such as 2:255 or Yaseen 9.")

    @Parameter(title: "Ayah")
    var ayah: ChosenAyahEntity?

    @Parameter(title: "Show Translation", default: true)
    var showTranslation: Bool

    /// The surah and ayah this configuration resolves to: the choice, else the newest bookmark, else
    /// Ayat al-Kursi (`ChosenAyahDefault`).
    func resolvedAyah(bookmarks: [QuranWidgetSnapshot.BookmarkCard]?) -> (surah: Int, ayah: Int) {
        if let ayah, ChosenAyahCatalog.isValid(surah: ayah.surah, ayah: ayah.ayah) {
            return (ayah.surah, ayah.ayah)
        }
        return ChosenAyahDefault.resolve(bookmarks: bookmarks)
    }
}

#if DEBUG
/// "-chosenAyahProbe": runs the picker's parser and search in the APP process (the same code the
/// extension runs) and prints what each query resolves to, so the picker can be checked without
/// placing a widget. Pass `-chosenAyahProbe "2:255|baqarah 255|kursi|yaseen 9|٣٦:٩|99"`.
enum ChosenAyahProbe {
    static func runIfRequested() async {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-chosenAyahProbe"), args.indices.contains(index + 1) else { return }
        guard #available(iOS 17.0, *) else { return }
        let queries = args[index + 1].split(separator: "|").map(String.init)
        let query = ChosenAyahQuery()
        for text in queries {
            let parsed = ChosenAyahReference.parse(text).map { "\($0.surah):\($0.ayah)" } ?? "nil"
            let matches = (try? await query.entities(matching: text)) ?? []
            let listed = matches.prefix(5).map { match in
                match.id + (match.subtitle.map { " (\($0.prefix(30)))" } ?? "")
            }
            NSLog("CHOSEN AYAH PROBE %@ -> parse %@, matches %d: %@", text, parsed, matches.count, listed.joined(separator: ", "))
        }
        let suggested = (try? await query.suggestedEntities()) ?? []
        NSLog("CHOSEN AYAH PROBE suggested %d: %@", suggested.count, suggested.prefix(6).map(\.id).joined(separator: ", "))
        let bookmarks = QuranWidgetStore.load()?.bookmarks
        let fallback = ChosenAyahDefault.resolve(bookmarks: bookmarks)
        NSLog("CHOSEN AYAH PROBE default %d:%d (bookmarks mirrored: %d)", fallback.surah, fallback.ayah, bookmarks?.count ?? -1)
    }
}
#endif
#endif
