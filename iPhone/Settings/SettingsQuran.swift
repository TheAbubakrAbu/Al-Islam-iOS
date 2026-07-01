import SwiftUI
import Combine
import WidgetKit

extension Settings {
    // MARK: - Quran types and constants

    static let randomReciterName = "Random Reciter"
    static let hafsUthmaniFontName = "KFGQPCHAFSUthmanicScript-Regula"
    static let qiraatUthmaniFontName = "KFGQPCQUMBULUthmanicScript-Regu"
    static let indopakFontName = "Al_Mushaf"

    enum QuranSortMode: String, CaseIterable, Identifiable {
        case surah
        case juz
        case revelation
        case khatm
        case page
        case ayahs
        case pages
        case sajdah
        case muqattaat
        case words
        case letters

        var id: String { rawValue }

        var title: String {
            switch self {
            case .surah: return "Surah"
            case .ayahs: return "Ayah Count"
            case .juz: return "Juz"
            case .page: return "Page Count"
            case .pages: return "Pages"
            case .revelation: return "Revelation"
            case .khatm: return "Khatm"
            case .sajdah: return "Sajdahs"
            case .muqattaat: return "Broken Letters"
            case .words: return "Words"
            case .letters: return "Letters"
            }
        }

        var systemImage: String {
            switch self {
            case .surah: return "list.number"
            case .ayahs: return "number"
            case .juz: return "square.grid.3x3"
            case .page: return "doc.text"
            case .pages: return "doc.text.fill"
            case .revelation: return "sparkles"
            case .khatm: return "checkmark.seal"
            case .sajdah: return "moon.stars.fill"
            case .muqattaat: return "character.book.closed.fill.ar"
            case .words: return "textformat.abc"
            case .letters: return "textformat"
            }
        }
    }

    enum QuranSortDirection: String, CaseIterable, Identifiable {
        case surahOrder = "surah"
        case ascending
        case descending

        var id: String { rawValue }

        var title: String {
            switch self {
            case .surahOrder: return "Surah"
            case .ascending: return "Asc"
            case .descending: return "Desc"
            }
        }

        var accessibilityTitle: String {
            switch self {
            case .surahOrder: return "Surah order"
            case .ascending: return "Ascending"
            case .descending: return "Descending"
            }
        }
    }

    enum Riwayah {
        struct Option: Identifiable, Hashable {
            let label: String
            let tag: String
            let arabic: String
            let teacher: String
            let teacherArabic: String
            let order: Int

            var id: String { tag.isEmpty ? "Hafs" : tag }
        }

        struct Group: Identifiable, Hashable {
            let teacher: String
            let teacherArabic: String
            let options: [Option]

            var id: String { teacher }
        }

        static let hafsTag = ""
        static let hafsLabel = "Hafs an Asim (default)"

        static let shubah = "Shubah an Asim"
        static let khalaf = "Khalaf an Hamzah"
        static let buzzi = "al-Bazzi an Ibn Kathir"
        static let qunbul = "Qunbul an Ibn Kathir"
        static let warsh = "Warsh an Nafi"
        static let qaloon = "Qalun an Nafi"
        static let duri = "ad-Duri an Abi Amr"
        static let susi = "as-Susi an Abi Amr"

        static let asimTeacher = "Asim"
        static let nafiTeacher = "Nafi"
        static let ibnKathirTeacher = "Ibn Kathir"
        static let abiAmrTeacher = "Abu Amr"
        static let hamzahTeacher = "Hamzah"

        static let asimTeacherArabic = "عَاصِم"
        static let nafiTeacherArabic = "نَافِع"
        static let ibnKathirTeacherArabic = "ابنِ كَثِير"
        static let abiAmrTeacherArabic = "أَبُو عَمرٍو"
        static let hamzahTeacherArabic = "حَمزَة"

        static let hafsArabic = "حَفص عَن عَاصِم"
        static let warshArabic = "وَرش عَن نَافِع"
        static let qaloonArabic = "قَالُون عَن نَافِع"
        static let duriArabic = "الدُّورِي عَن أَبِي عَمرٍو"
        static let susiArabic = "السُّوسِي عَن أَبِي عَمرٍو"
        static let buzziArabic = "البَزِّي عَن ابنِ كَثِير"
        static let qunbulArabic = "قُنبُل عَن ابنِ كَثِير"
        static let shubahArabic = "شُعبَة عَن عَاصِم"
        static let khalafArabic = "خَلَف عَن حَمزَة"

        static let options: [Option] = [
            Option(label: hafsLabel, tag: hafsTag, arabic: hafsArabic, teacher: asimTeacher, teacherArabic: asimTeacherArabic, order: 0),
            Option(label: shubah, tag: shubah, arabic: shubahArabic, teacher: asimTeacher, teacherArabic: asimTeacherArabic, order: 1),
            Option(label: warsh, tag: warsh, arabic: warshArabic, teacher: nafiTeacher, teacherArabic: nafiTeacherArabic, order: 2),
            Option(label: qaloon, tag: qaloon, arabic: qaloonArabic, teacher: nafiTeacher, teacherArabic: nafiTeacherArabic, order: 3),
            Option(label: buzzi, tag: buzzi, arabic: buzziArabic, teacher: ibnKathirTeacher, teacherArabic: ibnKathirTeacherArabic, order: 4),
            Option(label: qunbul, tag: qunbul, arabic: qunbulArabic, teacher: ibnKathirTeacher, teacherArabic: ibnKathirTeacherArabic, order: 5),
            Option(label: duri, tag: duri, arabic: duriArabic, teacher: abiAmrTeacher, teacherArabic: abiAmrTeacherArabic, order: 6),
            Option(label: susi, tag: susi, arabic: susiArabic, teacher: abiAmrTeacher, teacherArabic: abiAmrTeacherArabic, order: 7),
        ]

        static let groups: [Group] = [
            Group(teacher: asimTeacher, teacherArabic: asimTeacherArabic, options: options.filter { $0.teacher == asimTeacher }),
            Group(teacher: nafiTeacher, teacherArabic: nafiTeacherArabic, options: options.filter { $0.teacher == nafiTeacher }),
            Group(teacher: ibnKathirTeacher, teacherArabic: ibnKathirTeacherArabic, options: options.filter { $0.teacher == ibnKathirTeacher }),
            Group(teacher: abiAmrTeacher, teacherArabic: abiAmrTeacherArabic, options: options.filter { $0.teacher == abiAmrTeacher }),
        ]

        static let menuOptions: [(label: String, tag: String)] = [
            (options[0].label, options[0].tag),
            (options[1].label, options[1].tag),
            (options[2].label, options[2].tag),
            (options[3].label, options[3].tag),
            (options[4].label, options[4].tag),
            (options[5].label, options[5].tag),
            (options[6].label, options[6].tag),
            (options[7].label, options[7].tag),
        ]

        static let arabicCaptionByTag: [String: String] = [
            hafsTag: hafsArabic,
            warsh: warshArabic,
            qaloon: qaloonArabic,
            duri: duriArabic,
            susi: susiArabic,
            buzzi: buzziArabic,
            qunbul: qunbulArabic,
            shubah: shubahArabic,
            khalaf: khalafArabic,
        ]

        static let optionByTag: [String: Option] = Dictionary(uniqueKeysWithValues: options.map { ($0.tag, $0) })

        static func option(for tag: String) -> Option {
            let key = canonicalTag(tag)
            return optionByTag[key] ?? options[0]
        }

        static func canonicalTag(_ stored: String) -> String {
            let raw = stored.trimmingCharacters(in: .whitespacesAndNewlines)
            switch raw {
            case "", "Hafs", "Hafs an Asim", hafsLabel: return hafsTag
            case warsh, "Warsh An Nafi": return warsh
            case qaloon, "Qaloon an Nafi", "Qaloon An Nafi": return qaloon
            case duri, "Ad-Duri an Abi Amr": return duri
            case susi, "As-Susi an Abi Amr": return susi
            case buzzi, "Al-Buzzi an Ibn Kathir": return buzzi
            case qunbul, "Qumbul an Ibn Kathir": return qunbul
            case shubah, "Shu'bah an Asim", "Shu'bah an Aasim", "Shouba an Asim": return shubah
            case khalaf: return khalaf
            default: return raw
            }
        }
    }

    // MARK: - Quran migrations and reciter selection

    /// Consolidated startup migrations for Quran sort mode and reciter persistence.
    func runQuranStartupMigrations() {
        let defaults = UserDefaults(suiteName: AppIdentifiers.appGroupSuiteName)

        if fontArabic == Self.qiraatUthmaniFontName {
            fontArabic = Self.hafsUthmaniFontName
        }

        if defaults?.object(forKey: "quranSortMode") == nil,
           let legacyGroupBySurah = defaults?.object(forKey: "groupBySurah") as? Bool {
            quranSortModeRaw = legacyGroupBySurah ? QuranSortMode.surah.rawValue : QuranSortMode.juz.rawValue
        }

        if reciter == Self.randomReciterName {
            // Keep the saved random-reciter preference as-is.
        } else if reciter.starts(with: "ar") {
            if let match = reciters.first(where: { $0.ayahIdentifier == reciter }) {
                reciter = match.name
            } else {
                reciter = "Muhammad Al-Minshawi (Murattal)"
            }
        } else if reciter.isEmpty {
            reciter = "Muhammad Al-Minshawi (Murattal)"
        }

        migrateLegacyReciterIdIfNeeded()
        if reciter != Self.randomReciterName,
           let resolved = resolvedSelectedReciterIgnoringRandom(),
           reciterId != resolved.id {
            reciterId = resolved.id
        }
    }

    /// If the user has a legacy name-only save, attach a stable id. When several rows share the same display name (e.g. Ahmad Deban in multiple riwayat), prefer the Hafs / default surah feed (`qiraah == nil`).
    func migrateLegacyReciterIdIfNeeded() {
        guard reciter != Self.randomReciterName else { return }
        guard reciterId.isEmpty else { return }
        let matches = reciters.filter { $0.name == reciter }
        guard let r = Self.disambiguateReciters(sharingDisplayName: matches) else { return }
        reciterId = r.id
    }

    /// Picks one row when several share the same `name` (e.g. multiple qiraat). Prefers Hafs surah URL (`qiraah == nil`).
    static func disambiguateReciters(sharingDisplayName matches: [Reciter]) -> Reciter? {
        guard !matches.isEmpty else { return nil }
        if matches.count == 1 { return matches.first }
        return matches.first(where: { $0.qiraah == nil }) ?? matches.first
    }

    func setSelectedReciter(_ r: Reciter) {
        reciterId = r.id
        reciter = r.name
    }

    func setRandomReciterMode() {
        reciterId = ""
        reciter = Self.randomReciterName
    }

    func applyDefaultReciterSelection() {
        let defaultName = "Muhammad Al-Minshawi (Murattal)"
        if let r = reciters.first(where: { $0.name == defaultName }) {
            setSelectedReciter(r)
        } else {
            reciterId = ""
            reciter = defaultName
        }
    }

    /// When not using Random Reciter: resolve by stored id first, then by legacy display name (disambiguated when multiple rows share a name).
    func resolvedSelectedReciterIgnoringRandom() -> Reciter? {
        guard reciter != Self.randomReciterName else { return nil }
        if !reciterId.isEmpty, let match = reciters.first(where: { $0.id == reciterId }) {
            return match
        }
        let matches = reciters.filter { $0.name == reciter }
        return Self.disambiguateReciters(sharingDisplayName: matches)
    }

    /// Normalizes older saved `displayQiraah` tags to canonical Unicode transliteration (matches on-screen riwayah names).
    static func normalizeLegacyRiwayahTag(_ stored: String) -> String {
        Riwayah.canonicalTag(stored)
    }

    static func normalizedArabicFontName(_ fontName: String) -> String {
        fontName == qiraatUthmaniFontName ? hafsUthmaniFontName : fontName
    }

    static func isUthmaniArabicFont(_ fontName: String) -> Bool {
        let trimmed = fontName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed == hafsUthmaniFontName || trimmed == qiraatUthmaniFontName
    }

    static func isNonHafsQiraah(_ qiraah: String?) -> Bool {
        let normalizedQiraah = normalizeLegacyRiwayahTag(qiraah ?? Riwayah.hafsTag)
        return Riwayah.options.contains { !$0.tag.isEmpty && $0.tag == normalizedQiraah }
    }

    static func quranArabicFontName(selectedFontName: String, qiraah: String?) -> String {
        guard isUthmaniArabicFont(selectedFontName) else {
            return normalizedArabicFontName(selectedFontName)
        }
        return isNonHafsQiraah(qiraah) ? qiraatUthmaniFontName : hafsUthmaniFontName
    }

    var normalizedArabicFontName: String {
        Self.normalizedArabicFontName(fontArabic)
    }

    var usesUthmaniArabicFont: Bool {
        Self.isUthmaniArabicFont(fontArabic)
    }

    func quranArabicFontName(for qiraah: String?) -> String {
        Self.quranArabicFontName(selectedFontName: fontArabic, qiraah: qiraah)
    }

    func toggleSurahFavorite(surah: Int) {
        withAnimation {
            if isSurahFavorite(surah: surah) {
                favoriteSurahs.removeAll(where: { $0 == surah })
            } else {
                favoriteSurahs.append(surah)
            }
        }
    }

    func isSurahFavorite(surah: Int) -> Bool {
        return favoriteSurahs.contains(surah)
    }

    func toggleQiraahFavorite(tag: String) {
        let normalizedTag = Self.normalizeLegacyRiwayahTag(tag)
        withAnimation {
            if isQiraahFavorite(tag: normalizedTag) {
                favoriteQiraahTags.removeAll { Self.normalizeLegacyRiwayahTag($0) == normalizedTag }
            } else {
                favoriteQiraahTags.append(normalizedTag)
            }
        }
    }

    func isQiraahFavorite(tag: String) -> Bool {
        let normalizedTag = Self.normalizeLegacyRiwayahTag(tag)
        return favoriteQiraahTags.contains { Self.normalizeLegacyRiwayahTag($0) == normalizedTag }
    }

    func toggleEnglishTranslationFavorite(id: String) {
        withAnimation {
            if isEnglishTranslationFavorite(id: id) {
                favoriteEnglishTranslationIDs.removeAll { $0 == id }
            } else {
                favoriteEnglishTranslationIDs.append(id)
            }
        }
    }

    func isEnglishTranslationFavorite(id: String) -> Bool {
        favoriteEnglishTranslationIDs.contains(id)
    }

    private func khatmKey(surah: Int, ayah: Int) -> String {
        "\(surah):\(ayah)"
    }

    func loadKhatmProgressCacheFromStorage() {
        let savedKeys = (try? Self.decoder.decode([String].self, from: khatmCompletedAyahsData)) ?? []
        applyKhatmCompletedAyahKeys(savedKeys, persistImmediately: false)
    }

    func applyKhatmCompletedAyahKeys(_ keys: [String], persistImmediately: Bool) {
        khatmProgressSaveTask?.cancel()
        khatmProgressSaveTask = nil
        khatmProgressRefreshPending = false
        khatmCompletedAyahSetCache = Set(keys)
        khatmCompletedSurahCountsCache = Self.khatmSurahCounts(from: khatmCompletedAyahSetCache)

        if persistImmediately {
            persistKhatmProgressNow()
            objectWillChange.send()
        }
    }

    private static func khatmSurahCounts(from keys: Set<String>) -> [Int: Int] {
        var counts: [Int: Int] = [:]
        counts.reserveCapacity(114)

        for key in keys {
            guard let separator = key.firstIndex(of: ":"),
                  let surah = Int(key[..<separator]) else { continue }
            counts[surah, default: 0] += 1
        }

        return counts
    }

    private func persistKhatmProgressNow() {
        let keys = Array(khatmCompletedAyahSetCache)
        khatmCompletedAyahsData = (try? Self.encoder.encode(keys)) ?? Data()
    }

    /// Debounces the expensive work of a khatm mark. The disk write (encode + UserDefaults) is always
    /// coalesced onto a 250ms trailing timer so rapid marks — e.g. auto-marking while scrolling — never
    /// hit storage per ayah. `refresh` controls whether this task is also responsible for the UI update:
    /// auto-marking passes `true` so the checkmark/progress snap in once scrolling settles; a manual tap
    /// passes `false` because it already fired `objectWillChange` synchronously for instant feedback.
    private func scheduleKhatmProgressSaveAndRefresh(refresh: Bool = true) {
        if refresh { khatmProgressRefreshPending = true }
        // Re-arm the existing debounce instead of churning a fresh Task per ayah. Auto-marking while
        // scrolling can fire this many times a second; allocating/cancelling a main-actor Task each time
        // is exactly the overhead that made scrolling stutter.
        khatmSaveGeneration &+= 1
        guard khatmProgressSaveTask == nil else { return }
        khatmProgressSaveTask = Task { @MainActor [weak self] in
            var lastSeen = -1
            while true {
                guard let self else { return }
                // Cancellation only comes from applyKhatmCompletedAyahKeys, which frees the slot itself,
                // so just bail — don't touch the shared task handle (it may already hold a newer task).
                if Task.isCancelled { return }
                if self.khatmSaveGeneration == lastSeen { break }   // no new marks in the last window
                lastSeen = self.khatmSaveGeneration
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
            guard let self else { return }
            self.khatmProgressSaveTask = nil
            // No withAnimation here: animating objectWillChange animates every khatm view observing
            // `settings` at once, which makes the checkmark appear laggy. Let it snap in.
            self.persistKhatmProgressNow()
            if self.khatmProgressRefreshPending {
                self.khatmProgressRefreshPending = false
                self.objectWillChange.send()
            }
        }
    }

    func isKhatmAyahComplete(surah: Int, ayah: Int) -> Bool {
        guard isHafsDisplay else { return false }
        return khatmCompletedAyahSetCache.contains(khatmKey(surah: surah, ayah: ayah))
    }

    /// - Parameter immediate: pass `true` for a deliberate user tap so the checkmark appears at once;
    ///   leave `false` for automatic marking while scrolling so the UI update is coalesced with the
    ///   debounced disk write and never stutters the scroll.
    func markKhatmAyahComplete(surah: Int, ayah: Int, immediate: Bool = false) {
        guard isHafsDisplay else { return }
        let key = khatmKey(surah: surah, ayah: ayah)
        guard khatmCompletedAyahSetCache.insert(key).inserted else { return }
        khatmCompletedSurahCountsCache[surah, default: 0] += 1
        if immediate { objectWillChange.send() }
        scheduleKhatmProgressSaveAndRefresh(refresh: !immediate)
    }

    func khatmCompletedCount(for surah: Surah) -> Int {
        guard isHafsDisplay else { return 0 }
        return min(khatmCompletedSurahCountsCache[surah.id, default: 0], surah.numberOfAyahs)
    }

    func resetKhatmProgress(for surah: Surah) {
        let keys = Set(surah.ayahs.map { khatmKey(surah: surah.id, ayah: $0.id) })
        khatmCompletedAyahSetCache.subtract(keys)
        khatmCompletedSurahCountsCache[surah.id] = nil
        persistKhatmProgressNow()
        objectWillChange.send()
    }

    func resetAllKhatmProgress() {
        khatmCompletedAyahSetCache.removeAll(keepingCapacity: true)
        khatmCompletedSurahCountsCache.removeAll(keepingCapacity: true)
        persistKhatmProgressNow()
        objectWillChange.send()
    }

    func khatmTotalCompleted(in surahs: [Surah]) -> Int {
        guard isHafsDisplay else { return 0 }
        return khatmCompletedAyahSetCache.count
    }

    static let bookmarkNoteRemovalDialogTitle = "Remove bookmark and delete note?"
    static let bookmarkNoteRemovalDialogMessage = "This ayah has a note. Unbookmarking will delete the note."

    func bookmarkIndex(surah: Int, ayah: Int) -> Int? {
        bookmarkedAyahs.firstIndex { $0.surah == surah && $0.ayah == ayah }
    }

    func bookmarkedAyah(surah: Int, ayah: Int) -> BookmarkedAyah? {
        bookmarkIndex(surah: surah, ayah: ayah).map { bookmarkedAyahs[$0] }
    }

    func bookmarkHasNote(surah: Int, ayah: Int) -> Bool {
        bookmarkedAyah(surah: surah, ayah: ayah)?.hasNote ?? false
    }

    func bookmarkNoteText(surah: Int, ayah: Int) -> String {
        bookmarkedAyah(surah: surah, ayah: ayah)?
            .note?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    func toggleBookmark(surah: Int, ayah: Int) {
        withAnimation {
            let bookmark = BookmarkedAyah(surah: surah, ayah: ayah)
            if let index = bookmarkedAyahs.firstIndex(where: {$0.id == bookmark.id}) {
                bookmarkedAyahs.remove(at: index)
            } else {
                bookmarkedAyahs.append(bookmark)
            }
        }
    }

    func isBookmarked(surah: Int, ayah: Int) -> Bool {
        let bookmark = BookmarkedAyah(surah: surah, ayah: ayah)
        return bookmarkedAyahs.contains(where: {$0.id == bookmark.id})
    }

    @discardableResult
    func toggleBookmarkIfNoNoteLoss(surah: Int, ayah: Int) -> Bool {
        guard !(isBookmarked(surah: surah, ayah: ayah) && bookmarkHasNote(surah: surah, ayah: ayah)) else {
            return false
        }

        toggleBookmark(surah: surah, ayah: ayah)
        return true
    }

    func ensureBookmarkExists(surah: Int, ayah: Int) {
        guard !isBookmarked(surah: surah, ayah: ayah) else { return }
        toggleBookmark(surah: surah, ayah: ayah)
    }

    func setBookmarkNote(surah: Int, ayah: Int, note: String?) {
        withAnimation {
            let normalized = note?.trimmingCharacters(in: .whitespacesAndNewlines)
            let storedNote = (normalized?.isEmpty == true) ? nil : normalized

            if let index = bookmarkIndex(surah: surah, ayah: ayah) {
                var bookmark = bookmarkedAyahs[index]
                bookmark.note = storedNote
                bookmarkedAyahs[index] = bookmark
            } else {
                bookmarkedAyahs.append(BookmarkedAyah(surah: surah, ayah: ayah, note: storedNote))
            }
        }
    }

    func removeBookmarkNote(surah: Int, ayah: Int) {
        guard let index = bookmarkIndex(surah: surah, ayah: ayah) else { return }

        withAnimation {
            var bookmark = bookmarkedAyahs[index]
            bookmark.note = nil
            bookmarkedAyahs[index] = bookmark
        }
    }

    func isTajweedCategoryVisible(_ category: TajweedLegendCategory) -> Bool {
        switch category {
        case .tafkhim: return showTajweedTafkhim
        case .qalqalah: return showTajweedQalqalah
        case .lamShamsiyah: return showTajweedLamShamsiyah
        case .droppedLetter: return showTajweedDroppedLetter
        case .idghamGhunnah: return showTajweedIdghamBiGhunnahHeavy
        case .generalGhunnah: return showTajweedGeneralGhunnah
        case .ikhfaaLight: return showTajweedIdghamBiGhunnahLight
        case .ikhfaaHeavy: return showTajweedIkhfaa
        case .iqlaab: return showTajweedIqlab
        case .idghamBilaGhunnah: return showTajweedIdghamBilaGhunnah
        case .hamzatWaslSilent: return showTajweedHamzatWaslSilent
        case .maddNatural: return showTajweedMaddNatural2
        case .maddNaturalMiniature: return showTajweedMaddNaturalMiniature
        case .maddSukoon: return showTajweedMaddAaridLisSukoon
        case .maddNecessary: return showTajweedMaddNecessary6
        case .maddSeparated: return showTajweedMaddSeparated
        case .maddConnected: return showTajweedMaddConnected
        }
    }

    func setTajweedCategory(_ category: TajweedLegendCategory, visible: Bool) {
        switch category {
        case .tafkhim: showTajweedTafkhim = visible
        case .qalqalah: showTajweedQalqalah = visible
        case .lamShamsiyah: showTajweedLamShamsiyah = visible
        case .droppedLetter: showTajweedDroppedLetter = visible
        case .idghamGhunnah: showTajweedIdghamBiGhunnahHeavy = visible
        case .generalGhunnah: showTajweedGeneralGhunnah = visible
        case .ikhfaaLight: showTajweedIdghamBiGhunnahLight = visible
        case .ikhfaaHeavy: showTajweedIkhfaa = visible
        case .iqlaab: showTajweedIqlab = visible
        case .idghamBilaGhunnah: showTajweedIdghamBilaGhunnah = visible
        case .hamzatWaslSilent: showTajweedHamzatWaslSilent = visible
        case .maddNatural: showTajweedMaddNatural2 = visible
        case .maddNaturalMiniature: showTajweedMaddNaturalMiniature = visible
        case .maddSukoon: showTajweedMaddAaridLisSukoon = visible
        case .maddNecessary: showTajweedMaddNecessary6 = visible
        case .maddSeparated: showTajweedMaddSeparated = visible
        case .maddConnected: showTajweedMaddConnected = visible
        }
    }

    func addQuranSearchHistory(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var history = quranSearchHistory.filter {
            $0.caseInsensitiveCompare(trimmed) != .orderedSame
        }
        history.insert(trimmed, at: 0)
        quranSearchHistory = Array(history.prefix(10))
    }

    func removeQuranSearchHistory(_ query: String) {
        quranSearchHistory.removeAll { $0.caseInsensitiveCompare(query) == .orderedSame }
    }

    // MARK: - Quran favorites

    func toggleReciterFavorite(reciterID: String) {
        let trimmed = reciterID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        withAnimation {
            if isReciterFavorite(reciterID: trimmed) {
                favoriteReciterIDs.removeAll(where: { $0 == trimmed })
            } else {
                favoriteReciterIDs.append(trimmed)
            }
        }
    }

    func isReciterFavorite(reciterID: String) -> Bool {
        let trimmed = reciterID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return favoriteReciterIDs.contains(trimmed)
    }
}

// MARK: - Quran logic moved out of Settings.swift
//
// Behavior that operates on Quran data lives here so Settings.swift holds (mostly) just the stored
// settings. Only the @AppStorage/@Published *storage* must stay in the main class — Swift forbids stored
// property wrappers in extensions — but methods and `static` caches are free to live here.
extension Settings {

    // MARK: Saved sajdah / muqatta'at ayahs

    func toggleSavedSajdah(surah: Int, ayah: Int) {
        let key = "\(surah)-\(ayah)"
        var s = savedSajdahAyahIDs
        if s.contains(key) { s.remove(key) } else { s.insert(key) }
        savedSajdahAyahIDs = s
    }

    func toggleSavedBrokenLetter(surah: Int, ayah: Int) {
        let key = "\(surah)-\(ayah)"
        var s = savedBrokenLetterAyahIDs
        if s.contains(key) { s.remove(key) } else { s.insert(key) }
        savedBrokenLetterAyahIDs = s
    }

    // MARK: Ayah of the Day

    /// Stable yyyy-MM-dd key for a date, used to seed the Ayah of the Day and gate "Hide for Today".
    static func dayKey(_ date: Date = Date()) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    /// True when the user tapped "Hide for Today" on the Ayah of the Day card for the current day.
    var isAyahOfTheDayHiddenToday: Bool {
        ayahOfTheDayHiddenDate == Self.dayKey()
    }

    /// Words that keep an ayah out of the Ayah of the Day rotation — not because anything is wrong with
    /// them, just to keep the daily card gentle/uplifting (matches the widget's safe-pool filter).
    private static let ayahOfTheDayBlockedWords = [
        "kill", "killing", "fight", "fighting", "violence", "violent",
        "murder", "slay", "slaughter", "battle", "war"
    ]

    private static func isAyahGentle(_ ayah: Ayah) -> Bool {
        let combined = [ayah.textEnglishSaheeh, ayah.textEnglishMustafa, ayah.textTransliteration]
            .joined(separator: " ").lowercased()
        return !ayahOfTheDayBlockedWords.contains { !$0.isEmpty && combined.contains($0) }
    }

    /// Keeps the daily card to roughly two lines by skipping long ayahs. Caps are approximate — tuned so
    /// both the Arabic and the English translation fit a compact card without overflowing.
    private static func isAyahShort(_ ayah: Ayah) -> Bool {
        ayah.textHafs.count <= 120 && ayah.textEnglishSaheeh.count <= 150
    }

    private static var gentleAyahRefsCache: [(surahID: Int, ayahID: Int)]? = nil

    /// All (surahID, ayahID) pairs eligible for Ayah of the Day, filtered to gentle ayahs. Built once.
    private static func gentleAyahRefs(_ data: QuranData) -> [(surahID: Int, ayahID: Int)] {
        if let cached = gentleAyahRefsCache { return cached }
        var refs: [(surahID: Int, ayahID: Int)] = []
        for surah in data.quran {
            for ayah in surah.ayahs where isAyahGentle(ayah) && isAyahShort(ayah) {
                refs.append((surah.id, ayah.id))
            }
        }
        guard !refs.isEmpty else { return [] }   // don't cache before Quran data is loaded
        gentleAyahRefsCache = refs
        return refs
    }

    /// Deterministic (surahID, ayahID) for the Ayah of the Day on the given day. Same input day always
    /// yields the same ayah, so the in-app card and the widget agree. Picks from the gentle-ayah pool
    /// using a day-seeded multiplicative hash.
    func ayahOfTheDayReference(for date: Date = Date(), data: QuranData = .shared) -> (surahID: Int, ayahID: Int)? {
        let refs = Self.gentleAyahRefs(data)
        guard !refs.isEmpty else { return nil }

        let day = UInt64(bitPattern: Int64(date.timeIntervalSince1970 / 86_400))
        // Knuth multiplicative hash (UInt64 to stay valid on 32-bit Int platforms like older watchOS).
        let index = Int((day &* 2_654_435_761) % UInt64(refs.count))
        return refs[index]
    }

    // MARK: Quran widgets

    /// Rebuilds the App Group payload the Quran widgets read (last read ayah, last listened surah, and a
    /// pool of safe random ayahs) and reloads their timelines. Runs only in the main app — the widget
    /// extension just consumes the snapshot. Cheap to call from lifecycle/save hooks.
    func refreshQuranWidgets() {
        guard Bundle.main.bundleIdentifier?.contains("Widget") != true else { return }
        let data = QuranData.shared
        guard !data.quran.isEmpty else { return }

        // Preserve the existing random pool so this stays cheap when called frequently (e.g. on every
        // surah navigation) — the widget rotates through the pool over time for variety.
        var snapshot = QuranWidgetStore.load() ?? QuranWidgetSnapshot()
        snapshot.lastRead = nil

        if lastReadSurah > 0, lastReadAyah > 0,
           let surah = data.quran.first(where: { $0.id == lastReadSurah }),
           let ayah = surah.ayahs.first(where: { $0.id == lastReadAyah }) {
            snapshot.lastRead = quranWidgetAyahCard(surah: surah, ayah: ayah)
        }

        if let listened = lastListenedSurah {
            snapshot.lastListened = QuranWidgetSnapshot.ListenCard(
                name: listened.surahName,
                reciter: listened.reciter.displayNameForNowPlaying,
                current: listened.currentDuration,
                full: listened.fullDuration
            )
        }

        snapshot.lastListenedAyah = nil
        if saveLastListenedAyah,
           let listenedAyah = lastListenedAyah,
           let surah = data.quran.first(where: { $0.id == listenedAyah.surahNumber }),
           let ayah = surah.ayahs.first(where: { $0.id == listenedAyah.ayahNumber }) {
            snapshot.lastListenedAyah = quranWidgetAyahCard(surah: surah, ayah: ayah)
        }

        snapshot.ayahOfTheDay = nil
        if showAyahOfTheDay,
           let ref = ayahOfTheDayReference(data: data),
           let surah = data.quran.first(where: { $0.id == ref.surahID }),
           let ayah = surah.ayahs.first(where: { $0.id == ref.ayahID }) {
            snapshot.ayahOfTheDay = quranWidgetAyahCard(surah: surah, ayah: ayah)
        }

        // Rebuild the pool when it's empty or built by an older app version (cards missing the font tag),
        // so the ayah-of-the-day widget can fall back to it.
        if snapshot.randomPool.isEmpty || snapshot.randomPool.contains(where: { $0.fontName == nil }) {
            snapshot.randomPool = buildQuranWidgetRandomPool(from: data)
        }

        QuranWidgetStore.save(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Builds a widget ayah card with the Arabic rendered per the user's display settings (clean text /
    /// dots) and tagged with the selected Arabic font so the widget can match the in-app look.
    private func quranWidgetAyahCard(surah: Surah, ayah: Ayah) -> QuranWidgetSnapshot.AyahCard {
        let arabic = ayah.displayArabicText(surahId: surah.id, clean: cleanArabicText)
        return QuranWidgetSnapshot.AyahCard(
            arabic: arabic,
            reference: "Surah \(surah.id):\(ayah.id) • \(surah.nameTransliteration)",
            english: ayah.textEnglishSaheeh,
            fontName: fontArabic,
            colorRuns: quranWidgetTajweedRuns(surah: surah, ayah: ayah, displayText: arabic)
        )
    }

    /// Extracts tajweed color spans (UTF-16 offsets + RGB) over `displayText` so the widget can re-apply
    /// them without running the tajweed engine. Returns nil when tajweed is off. iOS-only (uses UIKit).
    private func quranWidgetTajweedRuns(surah: Surah, ayah: Ayah, displayText: String) -> [QuranWidgetSnapshot.ColorRun]? {
        #if os(iOS)
        guard showTajweedColors, showArabicText, isHafsDisplay else { return nil }
        let raw = ayah.displayArabicText(surahId: surah.id, clean: false)
        guard let attributed = TajweedStore.shared.attributedText(
            surah: surah.id,
            ayah: ayah.id,
            text: raw,
            displayText: displayText,
            cleanDisplayText: cleanArabicText
        ) else { return nil }

        let ns = NSAttributedString(attributed)
        // Resolve the adaptive base label color so it can be skipped — only the tajweed hues are stored;
        // the widget keeps un-colored text in its own primary color.
        let label = UIColor.label.resolvedColor(with: .current)
        var lr: CGFloat = 0, lg: CGFloat = 0, lb: CGFloat = 0, la: CGFloat = 0
        label.getRed(&lr, green: &lg, blue: &lb, alpha: &la)

        var runs: [QuranWidgetSnapshot.ColorRun] = []
        ns.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: ns.length)) { value, range, _ in
            guard let color = value as? UIColor else { return }
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            guard color.getRed(&r, green: &g, blue: &b, alpha: &a) else { return }
            if abs(r - lr) < 0.03, abs(g - lg) < 0.03, abs(b - lb) < 0.03 { return }
            runs.append(QuranWidgetSnapshot.ColorRun(start: range.location, length: range.length, r: Double(r), g: Double(g), b: Double(b)))
        }
        return runs.isEmpty ? nil : runs
        #else
        return nil
        #endif
    }

    private func buildQuranWidgetRandomPool(from data: QuranData, count: Int = 20) -> [QuranWidgetSnapshot.AyahCard] {
        var cards: [QuranWidgetSnapshot.AyahCard] = []
        var attempts = 0
        while cards.count < count, attempts < count * 8 {
            attempts += 1
            // Same gentle + short filter as the in-app Ayah of the Day pool, so the widget's fallback matches.
            guard let surah = data.quran.randomElement(),
                  let ayah = surah.ayahs.filter({ Self.isAyahGentle($0) && Self.isAyahShort($0) }).randomElement()
            else { continue }
            cards.append(quranWidgetAyahCard(surah: surah, ayah: ayah))
        }
        return cards
    }
}
