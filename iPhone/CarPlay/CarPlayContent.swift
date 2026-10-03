// The car plays the Quran, so CarPlay exists only where the Quran does (not in Al-Adhan); the
// Prayers tab needs the prayer times as well (not in Al-Quran).
#if os(iOS) && HAS_QURAN
import Foundation

// What the car's screen shows, as plain values. `CarPlayController` turns these into CarPlay
// templates; building them as data first lets the controller skip re-sending a list that did not
// change (a resend can jump the driver's scroll position) and lets the unit tests read every row
// without a car attached.

/// What a CarPlay row does when the driver taps it.
enum CarPlayAction: Equatable {
    /// The Last Listened surah from its saved position, with its own reciter ("Play Last Listened").
    case resumeLastSurah
    /// The Last Listened ayah, playing on through the rest of the surah.
    case resumeLastAyah
    case playSurah(Int)
    /// A bookmark: from this ayah on through the surah, like the Last Listened ayah row.
    case playAyah(surah: Int, ayah: Int)
    /// A Recently Played entry: it becomes Last Listened again, with its reciter and position, the
    /// same way the history row's "Resume" does on the phone.
    case resumeHistory(UUID)
    case playRandomSurah
    case openSurahGroup(ClosedRange<Int>)
    case selectReciter(id: String)
    case selectRandomReciter
    /// A reciter group's list; `page` picks one slice when the group is longer than the car allows.
    case openReciterGroup(id: String, page: Int?)
    case openRiwayat
    /// An Up Next entry: it leaves the queue and plays now.
    case playQueued(UUID)
    case clearQueue
    /// The Sunnah Recitations list, and one of its recitations (by its Sunnah Reminder preset id).
    case openSunnah
    case playSunnah(id: String)
}

struct CarPlayRow: Equatable {
    enum Artwork: Equatable {
        case none
        /// The surah number on an accent badge.
        case number(Int)
        case symbol(String)
    }

    enum Accessory: Equatable {
        case none
        case disclosure
        case checkmark
    }

    var text: String
    var detail: String? = nil
    var artwork: Artwork = .none
    var accessory: Accessory = .none
    /// CarPlay's animated now-playing bars on the row.
    var isPlaying = false
    /// Nil for a row that only informs (a prayer time, the selected reciter).
    var action: CarPlayAction? = nil
}

struct CarPlaySection: Equatable {
    var header: String? = nil
    var rows: [CarPlayRow]
    /// The section's letter in the jump bar down the list's edge.
    var indexTitle: String? = nil
}

/// The surah facts a row shows, so the builders and their tests never need a full `Surah`.
struct CarPlaySurah: Equatable {
    let number: Int
    let name: String
    let meaning: String
    let ayahCount: Int
}

/// Which surah is sounding right now, for the rows' now-playing bars.
struct CarPlayPlayback: Equatable {
    var surah: Int? = nil
    var isPlaying = false

    func isPlaying(_ surah: Int) -> Bool { isPlaying && self.surah == surah }
}

struct CarPlayReciterGroup: Equatable {
    let id: String
    let title: String
    let reciters: [Reciter]
    let isRiwayah: Bool
}

/// One of the Sunnah Reminder presets (SunnahReminders.swift) as something to play: where it starts,
/// and the surahs it names after the first, which wait at the head of Up Next.
struct CarPlaySunnahRecitation: Equatable {
    enum Start: Equatable {
        case surah(Int)
        /// From this ayah on through the end of the surah.
        case ayah(surah: Int, ayah: Int)
    }

    let id: String
    let title: String
    let detail: String
    let symbol: String
    let start: Start
    var followedBy: [Int] = []
    /// The preset's weekday (Calendar's, 1 = Sunday); nil for a daily one.
    var weekday: Int? = nil

    /// Every surah it plays whole, for the now-playing bars. An ayah start plays part of a surah,
    /// which is not this recitation whenever that surah is playing.
    var surahs: [Int] {
        guard case .surah(let first) = start else { return [] }
        return [first] + followedBy
    }
}

/// A reciter with surahs on disk: the ones that keep playing with no signal on the road.
struct CarPlayDownloadedReciter: Equatable {
    let reciter: Reciter
    let completedSurahs: Int
    let isDownloading: Bool
}

enum CarPlayContent {
    /// Ten surahs per row of the Surahs tab: twelve rows, each opening at most ten, which stays inside
    /// the shortest list a car allows while moving.
    static let surahGroupSize = 10
    static let favoriteLimit = 12
    static let bookmarkLimit = 12
    static let recentLimit = 5
    /// A reciter group longer than this is listed A to Z under letter headers with a jump bar, the way
    /// a long list reads at a glance. A shorter one keeps the phone picker's own order.
    static let letteredGroupMinimum = 13

    // MARK: Listen

    static func listenSections(
        lastSurah: LastListenedSurah?,
        lastAyah: LastListenedAyah?,
        favorites: [Int],
        bookmarks: [BookmarkedAyah],
        history: [ListeningHistoryItem],
        surahs: [Int: CarPlaySurah],
        playback: CarPlayPlayback,
        showsSunnah: Bool = false,
        maxItems: Int,
        maxSections: Int
    ) -> [CarPlaySection] {
        var sections: [CarPlaySection] = []

        var resume: [CarPlayRow] = []
        if let last = lastSurah, let surah = surahs[last.surahNumber] {
            var detail = last.reciter.displayNameWithEnglishQiraah
            if last.currentDuration > 1 {
                detail += " · " + (last.fullDuration > 0
                    ? "\(formatMMSS(last.currentDuration)) of \(formatMMSS(last.fullDuration))"
                    : formatMMSS(last.currentDuration))
            }
            resume.append(CarPlayRow(
                text: surah.name,
                detail: detail,
                artwork: .number(surah.number),
                isPlaying: playback.isPlaying(surah.number),
                action: .resumeLastSurah
            ))
        }
        if let last = lastAyah, let surah = surahs[last.surahNumber] {
            resume.append(CarPlayRow(
                text: "\(surah.name), Ayah \(last.ayahNumber)",
                detail: "Plays on through the surah",
                artwork: .number(surah.number),
                action: .resumeLastAyah
            ))
        }
        var start = [CarPlayRow(text: "Random Surah", artwork: .symbol("shuffle"), action: .playRandomSurah)]
        if showsSunnah {
            start.append(CarPlayRow(
                text: "Sunnah Recitations",
                detail: "Al-Kahf on Friday, al-Mulk before sleep",
                artwork: .symbol("moon.stars"),
                accessory: .disclosure,
                action: .openSunnah
            ))
        }
        sections.append(resume.isEmpty
            ? CarPlaySection(rows: start)
            : CarPlaySection(header: "Continue Listening", rows: resume + start))

        let favoriteRows = favorites.compactMap { surahs[$0] }.prefix(favoriteLimit).map { surahRow($0, playback: playback) }
        if !favoriteRows.isEmpty {
            sections.append(CarPlaySection(header: "Favorite Surahs", rows: Array(favoriteRows)))
        }

        let bookmarkRows: [CarPlayRow] = bookmarks.prefix(bookmarkLimit).compactMap { bookmark in
            guard let surah = surahs[bookmark.surah] else { return nil }
            let note = bookmark.note?
                .split(whereSeparator: \.isNewline).first
                .map { $0.trimmingCharacters(in: .whitespaces) }
            return CarPlayRow(
                text: "\(surah.name) \(bookmark.surah):\(bookmark.ayah)",
                detail: (note?.isEmpty ?? true) ? nil : note,
                artwork: .symbol("bookmark.fill"),
                action: .playAyah(surah: bookmark.surah, ayah: bookmark.ayah)
            )
        }
        if !bookmarkRows.isEmpty {
            sections.append(CarPlaySection(header: "Bookmarks", rows: bookmarkRows))
        }

        // History never repeats the Last Listened row above it (same surah, same reciter).
        let recentRows: [CarPlayRow] = history
            .filter { item in
                guard let last = lastSurah else { return true }
                return !(item.surahNumber == last.surahNumber && item.reciter.name == last.reciter.name)
            }
            .prefix(recentLimit)
            .compactMap { item in
                guard let surah = surahs[item.surahNumber] else { return nil }
                var detail = item.reciter.displayNameWithEnglishQiraah
                if let position = item.currentDuration, position > 1 {
                    detail += " · \(formatMMSS(position))"
                }
                return CarPlayRow(text: surah.name, detail: detail, artwork: .number(surah.number), action: .resumeHistory(item.id))
            }
        if !recentRows.isEmpty {
            sections.append(CarPlaySection(header: "Recently Played", rows: recentRows))
        }

        return clipped(sections, maxItems: maxItems, maxSections: maxSections)
    }

    // MARK: Sunnah Recitations

    /// The surahs a preset names after its first: al-Insan after as-Sajdah, al-Falaq and an-Nas after
    /// al-Ikhlas. The presets open one place in the reader; the car plays the whole recitation.
    private static let sunnahFollowOn: [String: [Int]] = [
        "friday-fajr": [76],
        "muawwidhat-morning": [113, 114],
        "muawwidhat-evening": [113, 114],
    ]

    /// The Sunnah Reminder presets the car can play, in the reminder screen's order. The daily wird is
    /// the reader's own portion rather than one recitation, so it stays on the phone; the morning and
    /// evening Mu'awwidhat are the same recitation, listed once for both.
    static func sunnahRecitations(from presets: [SunnahReminderPreset]) -> [CarPlaySunnahRecitation] {
        var result: [CarPlaySunnahRecitation] = []
        for preset in presets {
            let start: CarPlaySunnahRecitation.Start
            switch preset.target {
            case .tab: continue
            case .surah(let surah): start = .surah(surah)
            case .ayah(let surah, let ayah): start = .ayah(surah: surah, ayah: ayah)
            }
            if let index = result.firstIndex(where: { $0.start == start }) {
                if preset.id.hasPrefix("muawwidhat") {
                    result[index] = CarPlaySunnahRecitation(
                        id: result[index].id,
                        title: "Al-Mu'awwidhat",
                        detail: "Al-Ikhlas, al-Falaq and an-Nas, morning and evening",
                        symbol: "sun.max",
                        start: start,
                        followedBy: result[index].followedBy
                    )
                }
                continue
            }
            result.append(CarPlaySunnahRecitation(
                id: preset.id,
                title: preset.title,
                detail: preset.subtitle,
                symbol: preset.symbol,
                start: start,
                followedBy: sunnahFollowOn[preset.id] ?? [],
                weekday: preset.defaultWeekday
            ))
        }
        return result
    }

    /// The Sunnah Recitations list. On its day a weekly recitation leads (al-Kahf and the Friday Fajr
    /// surahs on a Friday); otherwise the reminder screen's order.
    static func sunnahSections(_ recitations: [CarPlaySunnahRecitation], weekday: Int, playback: CarPlayPlayback) -> [CarPlaySection] {
        guard !recitations.isEmpty else { return [] }
        let today = recitations.filter { $0.weekday == weekday }
        let rest = recitations.filter { $0.weekday != weekday }
        let rows = (today + rest).map { recitation in
            CarPlayRow(
                text: recitation.title,
                detail: recitation.detail,
                artwork: .symbol(recitation.symbol),
                isPlaying: playback.isPlaying && playback.surah.map { recitation.surahs.contains($0) } == true,
                action: .playSunnah(id: recitation.id)
            )
        }
        return [CarPlaySection(rows: rows)]
    }

    // MARK: Surahs

    static func surahGroups() -> [ClosedRange<Int>] {
        stride(from: 1, through: 114, by: surahGroupSize).map { $0...min($0 + surahGroupSize - 1, 114) }
    }

    static func groupTitle(_ range: ClosedRange<Int>) -> String {
        "Surahs \(range.lowerBound)–\(range.upperBound)"
    }

    static func surahRow(_ surah: CarPlaySurah, playback: CarPlayPlayback) -> CarPlayRow {
        CarPlayRow(
            text: surah.name,
            detail: "\(surah.meaning) · \(surah.ayahCount) ayahs",
            artwork: .number(surah.number),
            isPlaying: playback.isPlaying(surah.number),
            action: .playSurah(surah.number)
        )
    }

    /// The Surahs tab: one row per ten surahs, named by the first and last of them.
    static func surahIndexSections(surahs: [Int: CarPlaySurah], playback: CarPlayPlayback) -> [CarPlaySection] {
        guard !surahs.isEmpty else { return [] }
        let rows = surahGroups().map { range in
            let first = surahs[range.lowerBound]?.name ?? "Surah \(range.lowerBound)"
            let last = surahs[range.upperBound]?.name ?? "Surah \(range.upperBound)"
            return CarPlayRow(
                text: groupTitle(range),
                detail: "\(first) to \(last)",
                accessory: .disclosure,
                isPlaying: playback.isPlaying && playback.surah.map { range.contains($0) } == true,
                action: .openSurahGroup(range)
            )
        }
        return [CarPlaySection(rows: rows)]
    }

    static func surahGroupSections(_ range: ClosedRange<Int>, surahs: [Int: CarPlaySurah], playback: CarPlayPlayback) -> [CarPlaySection] {
        [CarPlaySection(rows: range.compactMap { surahs[$0] }.map { surahRow($0, playback: playback) })]
    }

    /// Up Next on the Now Playing screen: the phone's surah queue, which plays on when the current
    /// surah ends. Empty, the list shows its empty state instead.
    static func upNextSections(queue: [SurahQueueItem], surahs: [Int: CarPlaySurah]) -> [CarPlaySection] {
        guard !queue.isEmpty else { return [] }
        let rows = queue.map { item -> CarPlayRow in
            let surah = surahs[item.surahNumber]
            return CarPlayRow(
                text: surah?.name ?? item.surahName,
                detail: surah.map { "\($0.meaning) · \($0.ayahCount) ayahs" },
                artwork: .number(item.surahNumber),
                action: .playQueued(item.id)
            )
        }
        return [
            CarPlaySection(rows: rows),
            CarPlaySection(rows: [CarPlayRow(text: "Clear Up Next", artwork: .symbol("xmark.circle"), action: .clearQueue)]),
        ]
    }

    // MARK: Reciters

    /// The phone picker's groups in its order and with its names: the three recitation styles, then
    /// every riwayah's own reciters when the user has turned the other riwayat on.
    static func reciterGroups(includeRiwayat: Bool) -> [CarPlayReciterGroup] {
        var groups = [
            CarPlayReciterGroup(id: "murattal", title: "Normal (Murattal)", reciters: recitersMurattal, isRiwayah: false),
            CarPlayReciterGroup(id: "mujawwad", title: "Slow & Melodic (Mujawwad)", reciters: recitersMujawwad, isRiwayah: false),
            CarPlayReciterGroup(id: "muallim", title: "Teaching (Muallim)", reciters: recitersMuallim, isRiwayah: false),
        ]
        guard includeRiwayat else { return groups }
        let riwayat: [[Reciter]] = [
            recitersShubah, recitersKhalaf, recitersWarsh, recitersQaloon, recitersBuzzi, recitersQunbul,
            recitersDuri, recitersSusi, recitersHisham, recitersIbnDhakwan, recitersKhallad, recitersAbuHarith,
            recitersDuriKisai, recitersIbnWardan, recitersIbnJammaz, recitersRuways, recitersRawh,
            recitersIshaq, recitersIdris,
        ]
        for list in riwayat {
            guard let tag = list.first?.qiraah else { continue }
            groups.append(CarPlayReciterGroup(id: "riwayah:\(tag)", title: tag, reciters: list, isRiwayah: true))
        }
        return groups
    }

    static func reciterRow(_ reciter: Reciter, selectedID: String?, detail: String? = nil, showRiwayah: Bool = true) -> CarPlayRow {
        CarPlayRow(
            text: showRiwayah ? reciter.displayNameWithEnglishQiraah : reciter.name,
            detail: detail,
            accessory: reciter.id == selectedID ? .checkmark : .none,
            action: .selectReciter(id: reciter.id)
        )
    }

    /// The Reciters tab. `selected` is nil in Random Reciter mode.
    static func reciterSections(
        selected: Reciter?,
        isRandom: Bool,
        favorites: [Reciter],
        downloaded: [CarPlayDownloadedReciter],
        groups: [CarPlayReciterGroup],
        maxItems: Int,
        maxSections: Int
    ) -> [CarPlaySection] {
        var sections: [CarPlaySection] = []
        let selectedID = isRandom ? nil : selected?.id

        if isRandom {
            sections.append(CarPlaySection(header: "Selected Reciter", rows: [
                CarPlayRow(text: Settings.randomReciterName, detail: "A new reciter for each surah", artwork: .symbol("shuffle"), accessory: .checkmark)
            ]))
        } else if let selected {
            sections.append(CarPlaySection(header: "Selected Reciter", rows: [
                CarPlayRow(text: selected.displayNameWithEnglishQiraah, accessory: .checkmark)
            ]))
        }

        if !favorites.isEmpty {
            sections.append(CarPlaySection(header: "Favorites", rows: favorites.map { reciterRow($0, selectedID: selectedID) }))
        }

        if !downloaded.isEmpty {
            sections.append(CarPlaySection(header: "Downloaded", rows: downloaded.map { entry in
                let carried = entry.reciter.carriedSurahCount
                let detail = entry.isDownloading
                    ? "Downloading, \(entry.completedSurahs) of \(carried) surahs"
                    : entry.completedSurahs >= carried
                        ? "All \(carried) surahs on this iPhone"
                        : "\(entry.completedSurahs) of \(carried) surahs on this iPhone"
                return reciterRow(entry.reciter, selectedID: selectedID, detail: detail)
            }))
        }

        var browse = [CarPlayRow(
            text: Settings.randomReciterName,
            artwork: .symbol("shuffle"),
            accessory: isRandom ? .checkmark : .none,
            action: .selectRandomReciter
        )]
        for group in groups where !group.isRiwayah {
            browse.append(CarPlayRow(
                text: group.title,
                detail: "\(group.reciters.count) reciters",
                accessory: .disclosure,
                action: .openReciterGroup(id: group.id, page: nil)
            ))
        }
        let riwayatCount = groups.filter(\.isRiwayah).count
        if riwayatCount > 0 {
            browse.append(CarPlayRow(text: "Other Riwayat", detail: "\(riwayatCount) riwayat", accessory: .disclosure, action: .openRiwayat))
        }
        sections.append(CarPlaySection(header: "All Reciters", rows: browse))

        // Clip from the top sections down, but never lose the browse rows: they reach every reciter.
        let head = clipped(Array(sections.dropLast()), maxItems: max(0, maxItems - browse.count), maxSections: max(0, maxSections - 1))
        return head + [sections[sections.count - 1]]
    }

    static func riwayatSections(groups: [CarPlayReciterGroup]) -> [CarPlaySection] {
        [CarPlaySection(rows: groups.filter(\.isRiwayah).map { group in
            CarPlayRow(
                text: group.title,
                detail: group.reciters.count == 1 ? "1 reciter" : "\(group.reciters.count) reciters",
                accessory: .disclosure,
                action: .openReciterGroup(id: group.id, page: nil)
            )
        })]
    }

    /// One reciter group. A long one reads A to Z under letter headers with a jump bar; longer than the
    /// car allows, it becomes a list of alphabetical slices, each named by its first and last reciter,
    /// and `page` is one of those slices.
    static func reciterGroupSections(_ group: CarPlayReciterGroup, page: Int?, selectedID: String?, maxItems: Int, maxSections: Int = 50) -> [CarPlaySection] {
        let lettered = group.reciters.count >= letteredGroupMinimum
        let ordered = lettered
            ? group.reciters.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            : group.reciters
        let size = max(1, maxItems)
        let pages = stride(from: 0, to: ordered.count, by: size).map {
            Array(ordered[$0..<min($0 + size, ordered.count)])
        }
        let showRiwayah = !group.isRiwayah
        func list(_ reciters: [Reciter]) -> [CarPlaySection] {
            let rows = reciters.map { reciterRow($0, selectedID: selectedID, showRiwayah: showRiwayah) }
            guard lettered else { return [CarPlaySection(rows: rows)] }
            return letterSections(zip(reciters, rows).map { (letter: initial($0.name), row: $1) }, maxSections: maxSections)
        }
        if let page, pages.indices.contains(page) {
            return list(pages[page])
        }
        if pages.count <= 1 {
            return list(ordered)
        }
        return [CarPlaySection(rows: pages.enumerated().map { index, slice in
            CarPlayRow(
                text: "\(slice[0].name) to \(slice[slice.count - 1].name)",
                detail: "\(slice.count) reciters",
                accessory: .disclosure,
                action: .openReciterGroup(id: group.id, page: index)
            )
        })]
    }

    /// The jump bar's letter for a name: its first cased letter without accents (an ʿayn mark before
    /// it is skipped), "#" when it has none.
    static func initial(_ name: String) -> String {
        let folded = name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
        guard let first = folded.first(where: { $0.isLetter && $0.isCased }) else { return "#" }
        return String(first).uppercased()
    }

    /// Rows in A to Z order, one section per letter (a row whose letter came earlier joins that
    /// letter's section). More letters than the car has sections for, they stay one plain list.
    static func letterSections(_ rows: [(letter: String, row: CarPlayRow)], maxSections: Int) -> [CarPlaySection] {
        var sections: [CarPlaySection] = []
        for (letter, row) in rows {
            if let index = sections.firstIndex(where: { $0.indexTitle == letter }) {
                sections[index].rows.append(row)
            } else {
                sections.append(CarPlaySection(header: letter, rows: [row], indexTitle: letter))
            }
        }
        guard sections.count <= max(1, maxSections) else { return [CarPlaySection(rows: rows.map(\.row))] }
        return sections
    }

    #if HAS_ADHAN
    // MARK: Prayers

    /// Today's prayer times, the next one counting down. After the last prayer of the day the next is
    /// tomorrow's first, in a section of its own.
    static func prayerSections(
        today: [Prayer],
        tomorrowFirst: Prayer?,
        city: String?,
        now: Date,
        formatTime: (Date) -> String
    ) -> [CarPlaySection] {
        guard !today.isEmpty else { return [] }
        let next = today.first { $0.time > now }

        func row(_ prayer: Prayer, isNext: Bool) -> CarPlayRow {
            var detail = formatTime(prayer.time)
            if isNext { detail += " · " + countdown(to: prayer.time, from: now) }
            return CarPlayRow(text: prayer.displayName, detail: detail, artwork: .symbol(prayer.image))
        }

        let header = city.map { $0.isEmpty ? "Today" : "Today in \($0)" } ?? "Today"
        var sections = [CarPlaySection(header: header, rows: today.map { row($0, isNext: $0.id == next?.id) })]
        if next == nil, let tomorrowFirst {
            sections.append(CarPlaySection(header: "Tomorrow", rows: [row(tomorrowFirst, isNext: true)]))
        }
        return sections
    }

    /// "in 1 hr 5 min", rounded up to the minute so it never reads "in 0 min" before the time.
    static func countdown(to date: Date, from now: Date) -> String {
        let minutes = Int((date.timeIntervalSince(now) / 60).rounded(.up))
        guard minutes > 0 else { return "now" }
        let hours = minutes / 60
        let rest = minutes % 60
        if hours == 0 { return "in \(rest) min" }
        return rest == 0 ? "in \(hours) hr" : "in \(hours) hr \(rest) min"
    }
    #endif

    // MARK: Limits

    /// Keeps a list inside the car's limits, dropping rows from the end and then emptied sections.
    static func clipped(_ sections: [CarPlaySection], maxItems: Int, maxSections: Int) -> [CarPlaySection] {
        var remaining = max(0, maxItems)
        var result: [CarPlaySection] = []
        for section in sections.prefix(max(0, maxSections)) {
            guard remaining > 0 else { break }
            let rows = Array(section.rows.prefix(remaining))
            remaining -= rows.count
            if !rows.isEmpty { result.append(CarPlaySection(header: section.header, rows: rows, indexTitle: section.indexTitle)) }
        }
        return result
    }
}
#endif
