import CarPlay
import XCTest
@testable import iPhone

/// The CarPlay screens with no car attached: the row builders on fixed inputs, and the controller on a
/// recording stand-in for `CPInterfaceController`, tapping rows through their real handlers.
final class CarPlayTests: XCTestCase {

    // MARK: Builders

    func testSurahGroupsCoverTheQuranOnceInTwelveRows() {
        let groups = CarPlayContent.surahGroups()
        XCTAssertEqual(groups.count, 12)
        XCTAssertEqual(groups.flatMap { Array($0) }, Array(1...114))
        XCTAssertEqual(groups.last, 111...114)
        XCTAssertEqual(CarPlayContent.groupTitle(groups[1]), "Surahs 11–20")
    }

    func testListenTabWithNothingPlayedYetOffersARandomSurah() {
        let sections = CarPlayContent.listenSections(
            lastSurah: nil, lastAyah: nil, favorites: [], bookmarks: [], history: [],
            surahs: Self.surahs, playback: CarPlayPlayback(), maxItems: 100, maxSections: 10
        )
        XCTAssertEqual(sections, [CarPlaySection(rows: [
            CarPlayRow(text: "Random Surah", artwork: .symbol("shuffle"), action: .playRandomSurah)
        ])])
    }

    func testListenTabResumesFavoritesBookmarksAndHistory() {
        let reciter = reciters[0]
        let other = reciters[1]
        let last = LastListenedSurah(surahNumber: 2, surahName: "Al-Baqarah", reciter: reciter, currentDuration: 750, fullDuration: 7510)
        let history = [
            ListeningHistoryItem(surahNumber: 2, surahName: "Al-Baqarah", reciter: reciter, currentDuration: 30, fullDuration: 7510),
            ListeningHistoryItem(surahNumber: 18, surahName: "Al-Kahf", reciter: other, currentDuration: 125, fullDuration: 1900),
        ]
        let sections = CarPlayContent.listenSections(
            lastSurah: last,
            lastAyah: LastListenedAyah(surahNumber: 18, surahName: "Al-Kahf", ayahNumber: 10, reciter: reciter),
            favorites: [1, 999, 18],
            bookmarks: [BookmarkedAyah(surah: 2, ayah: 255, note: "Ayat al-Kursi\nmemorize")],
            history: history,
            surahs: Self.surahs,
            playback: CarPlayPlayback(surah: 2, isPlaying: true),
            maxItems: 100,
            maxSections: 10
        )

        XCTAssertEqual(sections.map(\.header), ["Continue Listening", "Favorite Surahs", "Bookmarks", "Recently Played"])

        let resume = sections[0].rows
        XCTAssertEqual(resume.map(\.text), ["Al-Baqarah", "Al-Kahf, Ayah 10", "Random Surah"])
        XCTAssertEqual(resume[0].detail, "\(reciter.displayNameWithEnglishQiraah) · 12:30 of 2:05:10")
        XCTAssertTrue(resume[0].isPlaying)
        XCTAssertEqual(resume[0].action, .resumeLastSurah)
        XCTAssertEqual(resume[1].action, .resumeLastAyah)

        // An unknown surah number is skipped, not shown as a broken row.
        XCTAssertEqual(sections[1].rows.map(\.action), [.playSurah(1), .playSurah(18)])
        XCTAssertEqual(sections[1].rows[0].detail, "The Opening · 7 ayahs")

        XCTAssertEqual(sections[2].rows, [CarPlayRow(
            text: "Al-Baqarah 2:255", detail: "Ayat al-Kursi", artwork: .symbol("bookmark.fill"),
            action: .playAyah(surah: 2, ayah: 255)
        )])

        // The history entry that IS Last Listened (same surah, same reciter) is not repeated.
        XCTAssertEqual(sections[3].rows.map(\.action), [.resumeHistory(history[1].id)])
        XCTAssertEqual(sections[3].rows[0].detail, "\(other.displayNameWithEnglishQiraah) · 02:05")
    }

    func testListsAreClippedToTheCarsLimits() {
        let favorites = Array(1...12)
        let sections = CarPlayContent.listenSections(
            lastSurah: nil, lastAyah: nil, favorites: favorites, bookmarks: [], history: [],
            surahs: Self.surahs, playback: CarPlayPlayback(), maxItems: 5, maxSections: 10
        )
        XCTAssertEqual(sections.flatMap(\.rows).count, 5)
        XCTAssertEqual(sections.map(\.header), [nil, "Favorite Surahs"])
        XCTAssertTrue(CarPlayContent.listenSections(
            lastSurah: nil, lastAyah: nil, favorites: favorites, bookmarks: [], history: [],
            surahs: Self.surahs, playback: CarPlayPlayback(), maxItems: 100, maxSections: 1
        ).count == 1)
    }

    func testUpNextListsTheQueueAndEndsWithClear() {
        let queue = [
            SurahQueueItem(surahNumber: 18, surahName: "Al-Kahf"),
            SurahQueueItem(surahNumber: 2, surahName: "Al-Baqara"),
        ]
        let sections = CarPlayContent.upNextSections(queue: queue, surahs: Self.surahs)
        XCTAssertEqual(sections.count, 2)
        XCTAssertEqual(sections[0].rows.map(\.text), ["Al-Kahf", "Al-Baqarah"])
        XCTAssertEqual(sections[0].rows.map(\.action), [.playQueued(queue[0].id), .playQueued(queue[1].id)])
        XCTAssertEqual(sections[0].rows[0].detail, "The Cave · 110 ayahs")
        XCTAssertEqual(sections[1].rows.map(\.action), [.clearQueue])
        XCTAssertTrue(CarPlayContent.upNextSections(queue: [], surahs: Self.surahs).isEmpty)
    }

    func testLongReciterGroupsSplitIntoNamedSlices() throws {
        let group = try XCTUnwrap(CarPlayContent.reciterGroups(includeRiwayat: false).first { $0.id == "murattal" })
        XCTAssertGreaterThan(group.reciters.count, 12)
        // A long group reads A to Z in the car (the phone keeps its curated order).
        let sorted = group.reciters.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        let slices = CarPlayContent.reciterGroupSections(group, page: nil, selectedID: nil, maxItems: 12)[0].rows
        XCTAssertEqual(slices.count, Int((Double(group.reciters.count) / 12).rounded(.up)))
        XCTAssertEqual(slices[0].text, "\(sorted[0].name) to \(sorted[11].name)")
        XCTAssertEqual(slices[0].action, .openReciterGroup(id: "murattal", page: 0))

        let selected = sorted[13]
        let second = CarPlayContent.reciterGroupSections(group, page: 1, selectedID: selected.id, maxItems: 12).flatMap(\.rows)
        XCTAssertEqual(second.first?.action, .selectReciter(id: sorted[12].id))
        XCTAssertEqual(second[1].accessory, .checkmark)

        // Short enough for one list: the reciters themselves under letter headers, each letter in the
        // jump bar, every reciter once.
        let whole = CarPlayContent.reciterGroupSections(group, page: nil, selectedID: nil, maxItems: 500)
        XCTAssertEqual(whole.flatMap(\.rows).map(\.action), sorted.map { .selectReciter(id: $0.id) })
        XCTAssertGreaterThan(whole.count, 1)
        XCTAssertTrue(whole.allSatisfy { $0.indexTitle != nil && $0.header == $0.indexTitle })
        XCTAssertEqual(Set(whole.compactMap(\.indexTitle)).count, whole.count, "one section per letter")
        XCTAssertEqual(whole.first?.indexTitle, "A")

        // Too many letters for the car's sections: one plain list instead.
        let plain = CarPlayContent.reciterGroupSections(group, page: nil, selectedID: nil, maxItems: 500, maxSections: 2)
        XCTAssertEqual(plain.count, 1)
        XCTAssertNil(plain[0].indexTitle)
        XCTAssertEqual(plain[0].rows.count, group.reciters.count)
    }

    func testShortReciterGroupsKeepThePhonePickersOrder() throws {
        let group = try XCTUnwrap(CarPlayContent.reciterGroups(includeRiwayat: true).first { $0.isRiwayah && $0.reciters.count > 1 })
        XCTAssertLessThan(group.reciters.count, CarPlayContent.letteredGroupMinimum)
        let sections = CarPlayContent.reciterGroupSections(group, page: nil, selectedID: nil, maxItems: 500)
        XCTAssertEqual(sections.count, 1)
        XCTAssertNil(sections[0].indexTitle)
        XCTAssertEqual(sections[0].rows.map(\.action), group.reciters.map { .selectReciter(id: $0.id) })
    }

    func testJumpBarLetters() {
        XCTAssertEqual(CarPlayContent.initial("Abdul Basit"), "A")
        XCTAssertEqual(CarPlayContent.initial("ʿAli Jaber"), "A")
        XCTAssertEqual(CarPlayContent.initial("Élan"), "E")
        XCTAssertEqual(CarPlayContent.initial("saad"), "S")
        XCTAssertEqual(CarPlayContent.initial(""), "#")
    }

    // MARK: Sunnah Recitations

    func testSunnahRecitationsComeFromTheReminderPresets() throws {
        let recitations = CarPlayContent.sunnahRecitations(from: SunnahReminderPreset.all)
        // The wird is the reader's own portion; morning and evening Mu'awwidhat are one recitation.
        XCTAssertEqual(recitations.map(\.id), ["mulk", "kahf", "baqarah-last-two", "muawwidhat-morning", "friday-fajr", "al-imran-night"])

        let byID = Dictionary(uniqueKeysWithValues: recitations.map { ($0.id, $0) })
        XCTAssertEqual(byID["mulk"]?.start, .surah(67))
        XCTAssertEqual(byID["mulk"]?.detail, "Each night before sleep")
        XCTAssertEqual(byID["kahf"]?.weekday, 6)
        XCTAssertEqual(byID["baqarah-last-two"]?.start, .ayah(surah: 2, ayah: 285))
        XCTAssertEqual(byID["baqarah-last-two"]?.surahs, [], "part of a surah never lights up the whole surah")
        XCTAssertEqual(byID["al-imran-night"]?.start, .ayah(surah: 3, ayah: 190))

        let muawwidhat = try XCTUnwrap(byID["muawwidhat-morning"])
        XCTAssertEqual(muawwidhat.title, "Al-Mu'awwidhat")
        XCTAssertEqual(muawwidhat.detail, "Al-Ikhlas, al-Falaq and an-Nas, morning and evening")
        XCTAssertEqual(muawwidhat.surahs, [112, 113, 114])
        XCTAssertNil(muawwidhat.weekday)

        let friday = try XCTUnwrap(byID["friday-fajr"])
        XCTAssertEqual(friday.surahs, [32, 76])
        XCTAssertEqual(friday.weekday, 6)
    }

    func testOnFridayItsRecitationsLead() {
        let recitations = CarPlayContent.sunnahRecitations(from: SunnahReminderPreset.all)
        let friday = CarPlayContent.sunnahSections(recitations, weekday: 6, playback: CarPlayPlayback())
        XCTAssertEqual(friday.count, 1)
        XCTAssertEqual(friday[0].rows.prefix(2).map(\.action), [.playSunnah(id: "kahf"), .playSunnah(id: "friday-fajr")])
        XCTAssertEqual(friday[0].rows.count, recitations.count)

        let monday = CarPlayContent.sunnahSections(recitations, weekday: 2, playback: CarPlayPlayback(surah: 113, isPlaying: true))
        XCTAssertEqual(monday[0].rows.map(\.action), recitations.map { .playSunnah(id: $0.id) })
        XCTAssertEqual(monday[0].rows.filter(\.isPlaying).map(\.action), [.playSunnah(id: "muawwidhat-morning")])
        XCTAssertEqual(monday[0].rows[0].artwork, .symbol("moon.stars"))
    }

    func testListenTabOpensTheSunnahRecitations() {
        let sections = CarPlayContent.listenSections(
            lastSurah: nil, lastAyah: nil, favorites: [], bookmarks: [], history: [],
            surahs: Self.surahs, playback: CarPlayPlayback(), showsSunnah: true, maxItems: 100, maxSections: 10
        )
        XCTAssertEqual(sections[0].rows.map(\.action), [.playRandomSurah, .openSunnah])
        XCTAssertEqual(sections[0].rows[1].accessory, .disclosure)
    }

    @MainActor
    func testQueuedNextGoesAheadOfThePhonesQueue() async {
        await QuranData.shared.waitUntilLoaded()
        let player = QuranPlayer.shared
        let saved = player.surahQueue
        player.clearSurahQueue()
        defer {
            player.clearSurahQueue()
            saved.forEach { player.addSurahToQueue(surahNumber: $0.surahNumber, surahName: $0.surahName) }
        }

        player.addSurahToQueue(surahNumber: 36, surahName: "Ya-Sin")
        player.addSurahToQueue(surahNumber: 113, surahName: "Al-Falaq")
        player.queueSurahsNext([113, 114, 0, 200])
        XCTAssertEqual(player.surahQueue.map(\.surahNumber), [113, 114, 36], "a queued copy moves up; out-of-range numbers are dropped")
        XCTAssertEqual(player.surahQueue[1].surahName, QuranData.shared.surah(114)?.nameTransliteration)
    }

    func testRiwayatFollowThePhonePickerAndOnlyWhenTurnedOn() {
        XCTAssertTrue(CarPlayContent.reciterGroups(includeRiwayat: false).allSatisfy { !$0.isRiwayah })
        let riwayat = CarPlayContent.reciterGroups(includeRiwayat: true).filter(\.isRiwayah)
        XCTAssertEqual(riwayat.count, 19)
        XCTAssertEqual(riwayat.first?.title, Settings.Riwayah.shubah)
        XCTAssertEqual(riwayat.last?.title, recitersIdris.first?.qiraah)
        XCTAssertTrue(riwayat.allSatisfy { group in group.reciters.allSatisfy { $0.qiraah == group.title } })
    }

    func testReciterTabNeverClipsAwayTheBrowseRows() {
        let groups = CarPlayContent.reciterGroups(includeRiwayat: true)
        let sections = CarPlayContent.reciterSections(
            selected: reciters[0], isRandom: false, favorites: Array(reciters.prefix(20)), downloaded: [],
            groups: groups, maxItems: 12, maxSections: 4
        )
        XCTAssertLessThanOrEqual(sections.flatMap(\.rows).count, 12)
        XCTAssertEqual(sections.last?.header, "All Reciters")
        XCTAssertEqual(sections.last?.rows.map(\.text), [
            Settings.randomReciterName, "Normal (Murattal)", "Slow & Melodic (Mujawwad)", "Teaching (Muallim)", "Other Riwayat",
        ])
        XCTAssertEqual(sections.first?.rows.first?.accessory, .checkmark)
    }

    func testDownloadedRecitersSayHowMuchIsOnThePhone() {
        let full = reciters[0]
        let sections = CarPlayContent.reciterSections(
            selected: nil, isRandom: true, favorites: [],
            downloaded: [
                CarPlayDownloadedReciter(reciter: full, completedSurahs: full.carriedSurahCount, isDownloading: false),
                CarPlayDownloadedReciter(reciter: reciters[1], completedSurahs: 12, isDownloading: false),
                CarPlayDownloadedReciter(reciter: reciters[2], completedSurahs: 3, isDownloading: true),
            ],
            groups: [], maxItems: 100, maxSections: 10
        )
        XCTAssertEqual(sections[0].rows[0].text, Settings.randomReciterName)
        let downloaded = sections[1].rows.compactMap(\.detail)
        XCTAssertEqual(downloaded, [
            "All \(full.carriedSurahCount) surahs on this iPhone",
            "12 of \(reciters[1].carriedSurahCount) surahs on this iPhone",
            "Downloading, 3 of \(reciters[2].carriedSurahCount) surahs",
        ])
        XCTAssertEqual(sections.last?.rows.first?.accessory, .checkmark)
    }

    func testPrayerTimesCountDownToTheNextOne() {
        let base = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let today = [
            Self.prayer("Fajr", base, "sunrise"),
            Self.prayer("Dhuhr", base.addingTimeInterval(7 * 3600), "sun.max"),
            Self.prayer("Asr", base.addingTimeInterval(10 * 3600), "sun.min"),
        ]
        let sections = CarPlayContent.prayerSections(
            today: today, tomorrowFirst: nil, city: "Irvine",
            now: base.addingTimeInterval(5 * 3600 + 55 * 60), formatTime: { _ in "T" }
        )
        XCTAssertEqual(sections.map(\.header), ["Today in Irvine"])
        XCTAssertEqual(sections[0].rows.map(\.detail), ["T", "T · in 1 hr 5 min", "T"])
        XCTAssertEqual(sections[0].rows.map(\.artwork), [.symbol("sunrise"), .symbol("sun.max"), .symbol("sun.min")])
        XCTAssertTrue(sections[0].rows.allSatisfy { $0.action == nil })
    }

    func testAfterTheLastPrayerTomorrowsFajrIsNext() {
        let base = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let fajr = Self.prayer("Fajr", base.addingTimeInterval(20 * 3600), "sunrise")
        let sections = CarPlayContent.prayerSections(
            today: [Self.prayer("Isha", base, "moon.stars")], tomorrowFirst: fajr, city: nil,
            now: base.addingTimeInterval(60), formatTime: { _ in "T" }
        )
        XCTAssertEqual(sections.map(\.header), ["Today", "Tomorrow"])
        XCTAssertEqual(sections[1].rows.map(\.detail), ["T · in 19 hr 59 min"])
        XCTAssertTrue(CarPlayContent.prayerSections(today: [], tomorrowFirst: fajr, city: nil, now: base, formatTime: { _ in "" }).isEmpty)
    }

    func testCountdownWording() {
        let now = Date(timeIntervalSinceReferenceDate: 0)
        XCTAssertEqual(CarPlayContent.countdown(to: now.addingTimeInterval(30), from: now), "in 1 min")
        XCTAssertEqual(CarPlayContent.countdown(to: now.addingTimeInterval(59 * 60), from: now), "in 59 min")
        XCTAssertEqual(CarPlayContent.countdown(to: now.addingTimeInterval(2 * 3600), from: now), "in 2 hr")
        XCTAssertEqual(CarPlayContent.countdown(to: now, from: now), "now")
    }

    func testSurahBadgeFitsTheRowAndStaysLegible() {
        let image = CarPlayBadge.image(number: 114, color: .systemGreen, scale: 3)
        XCTAssertGreaterThan(image.size.width, 0)
        XCTAssertEqual(image.size.width, image.size.height)
        XCTAssertEqual(image.scale, 3)
        XCTAssertEqual(CarPlayBadge.inkColor(on: .yellow), UIColor(white: 0.1, alpha: 1))
        XCTAssertEqual(CarPlayBadge.inkColor(on: UIColor(red: 0, green: 0.3, blue: 0.7, alpha: 1)), .white)
    }

    // MARK: Controller

    @MainActor
    func testTabsAndTheSurahDrillDown() async throws {
        await QuranData.shared.waitUntilLoaded()
        let car = RecordingCarInterface()
        let controller = CarPlayController(interface: car)
        controller.start()
        defer { controller.stop() }

        let tabs = try XCTUnwrap(car.root as? CPTabBarTemplate)
        XCTAssertEqual(tabs.templates.map { ($0 as? CPListTemplate)?.title }, ["Listen", "Surahs", "Reciters", "Prayers"])
        XCTAssertEqual(tabs.templates.map(\.tabTitle), ["Listen", "Surahs", "Reciters", "Prayers"])

        let index = controller.surahsTemplate.sections.flatMap(\.items).compactMap { $0 as? CPListItem }
        XCTAssertEqual(index.count, 12)
        XCTAssertEqual(index[1].text, "Surahs 11–20")
        XCTAssertEqual(index[1].accessoryType, .disclosureIndicator)

        tap(index[1])
        let pushed = try XCTUnwrap(car.stack.last as? CPListTemplate)
        XCTAssertEqual(pushed.title, "Surahs 11–20")
        let surahs = pushed.sections.flatMap(\.items).compactMap { $0 as? CPListItem }
        XCTAssertEqual(surahs.map(\.text), (11...20).map { QuranData.shared.surah($0)?.nameTransliteration })
        XCTAssertNotNil(surahs.first?.image)
        XCTAssertNotNil(surahs.first?.handler)
    }

    @MainActor
    func testChoosingAReciterSelectsItAndReturnsToTheTabs() throws {
        let settings = Settings.shared
        let savedName = settings.reciter
        let savedID = settings.reciterId
        defer {
            settings.reciter = savedName
            settings.reciterId = savedID
        }

        let car = RecordingCarInterface()
        let controller = CarPlayController(interface: car)
        controller.start()
        defer { controller.stop() }

        controller.perform(.openReciterGroup(id: "mujawwad", page: nil))
        let list = try XCTUnwrap(car.stack.last as? CPListTemplate)
        XCTAssertEqual(list.title, "Slow & Melodic (Mujawwad)")
        let choice = recitersMujawwad.first { $0.id != savedID } ?? recitersMujawwad[0]
        let row = try XCTUnwrap(list.sections.flatMap(\.items).compactMap { $0 as? CPListItem }.first { $0.text == choice.name })

        tap(row)
        XCTAssertEqual(settings.reciterId, choice.id)
        XCTAssertEqual(car.poppedToRoot, 1)
        let selected = controller.recitersTemplate.sections.first
        XCTAssertEqual(selected?.header, "Selected Reciter")
        XCTAssertEqual((selected?.items.first as? CPListItem)?.text, choice.displayNameWithEnglishQiraah)
    }

    @MainActor
    func testSunnahListAndTheReciterJumpBarReachTheCar() throws {
        let car = RecordingCarInterface()
        let controller = CarPlayController(interface: car)
        controller.start()
        defer { controller.stop() }

        let listen = controller.listenTemplate.sections.flatMap(\.items).compactMap { $0 as? CPListItem }
        let door = try XCTUnwrap(listen.first { $0.text == "Sunnah Recitations" })
        tap(door)
        let sunnah = try XCTUnwrap(car.stack.last as? CPListTemplate)
        XCTAssertEqual(sunnah.title, "Sunnah Recitations")
        XCTAssertEqual(sunnah.sections.flatMap(\.items).count, 6)

        controller.perform(.openReciterGroup(id: "murattal", page: nil))
        let murattal = try XCTUnwrap(car.stack.last as? CPListTemplate)
        XCTAssertEqual(murattal.sections.first?.sectionIndexTitle, "A")
        XCTAssertEqual(murattal.sections.flatMap(\.items).count, recitersMurattal.count)
    }

    /// A list closed and opened again can come back at the same address with the same rows; it must
    /// still arrive filled (the controller once skipped it as "already sent").
    @MainActor
    func testReopenedListsAreNeverBlank() throws {
        let car = RecordingCarInterface()
        let controller = CarPlayController(interface: car)
        controller.start()
        defer { controller.stop() }

        for _ in 0..<25 {
            controller.perform(.openReciterGroup(id: "muallim", page: nil))
            let list = try XCTUnwrap(car.stack.last as? CPListTemplate)
            XCTAssertEqual(list.sections.flatMap(\.items).count, recitersMuallim.count)
            car.popTemplate(animated: false, completion: nil)
        }
    }

    @MainActor
    func testPlaybackFailureShowsOnTheCarAndOKClearsIt() async throws {
        let player = QuranPlayer.shared
        let car = RecordingCarInterface()
        let controller = CarPlayController(interface: car)
        controller.start()
        defer {
            controller.stop()
            player.showInternetAlert = false
        }

        player.playbackAlertTitle = "Reciter Not Downloaded"
        player.playbackAlertMessage = "Test message"
        player.showInternetAlert = true
        try await Task.sleep(nanoseconds: 200_000_000)

        let sheet = try XCTUnwrap(car.presented as? CPActionSheetTemplate)
        XCTAssertEqual(sheet.title, "Reciter Not Downloaded")
        XCTAssertEqual(sheet.message, "Test message")
        let ok = try XCTUnwrap(sheet.actions.first { $0.style == .cancel })
        ok.handler(ok)
        XCTAssertFalse(player.showInternetAlert)
        XCTAssertNil(car.presented)
    }

    @MainActor
    func testUpNextFollowsThePhonesQueue() async throws {
        await QuranData.shared.waitUntilLoaded()
        let player = QuranPlayer.shared
        let saved = player.surahQueue
        player.clearSurahQueue()
        defer {
            player.clearSurahQueue()
            saved.forEach { player.addSurahToQueue(surahNumber: $0.surahNumber, surahName: $0.surahName) }
        }

        let car = RecordingCarInterface()
        let controller = CarPlayController(interface: car)
        controller.start()
        defer { controller.stop() }
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertFalse(CPNowPlayingTemplate.shared.isUpNextButtonEnabled)

        player.addSurahToQueue(surahNumber: 36, surahName: "Ya-Sin")
        player.addSurahToQueue(surahNumber: 67, surahName: "Al-Mulk")
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertTrue(CPNowPlayingTemplate.shared.isUpNextButtonEnabled)

        controller.showUpNext()
        let list = try XCTUnwrap(car.stack.last as? CPListTemplate)
        XCTAssertEqual(list.title, "Up Next")
        let rows = list.sections[0].items.compactMap { $0 as? CPListItem }
        XCTAssertEqual(rows.map(\.text), [36, 67].map { QuranData.shared.surah($0)?.nameTransliteration })

        // Clear rather than play: playing would stream a recitation inside the test host.
        let clear = try XCTUnwrap(list.sections[1].items.first as? CPListItem)
        tap(clear)
        XCTAssertTrue(player.surahQueue.isEmpty)
        XCTAssertTrue(car.stack.isEmpty, "back on Now Playing")
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertFalse(CPNowPlayingTemplate.shared.isUpNextButtonEnabled)
    }

    // MARK: Helpers

    private func tap(_ item: CPListItem) {
        item.handler?(item, {})
    }

    private static let surahs: [Int: CarPlaySurah] = [
        1: CarPlaySurah(number: 1, name: "Al-Fatihah", meaning: "The Opening", ayahCount: 7),
        2: CarPlaySurah(number: 2, name: "Al-Baqarah", meaning: "The Cow", ayahCount: 286),
        18: CarPlaySurah(number: 18, name: "Al-Kahf", meaning: "The Cave", ayahCount: 110),
    ].merging((3...12).map { ($0, CarPlaySurah(number: $0, name: "Surah \($0)", meaning: "", ayahCount: 1)) }) { first, _ in first }

    private static func prayer(_ name: String, _ time: Date, _ image: String) -> Prayer {
        Prayer(nameArabic: "", nameTransliteration: name, nameEnglish: name, time: time, image: image,
               rakah: "", sunnahBefore: "", sunnahAfter: "")
    }
}

/// Records what the controller asks of the car, standing in for `CPInterfaceController`.
@MainActor
private final class RecordingCarInterface: CarPlayInterfacing {
    var root: CPTemplate?
    var stack: [CPTemplate] = []
    var presented: CPTemplate?
    var poppedToRoot = 0

    var topTemplate: CPTemplate? { stack.last ?? root }
    var presentedTemplate: CPTemplate? { presented }
    var carTraitCollection: UITraitCollection { UITraitCollection(displayScale: 2) }

    func setRootTemplate(_ rootTemplate: CPTemplate, animated: Bool, completion: ((Bool, Error?) -> Void)?) {
        root = rootTemplate
        stack = []
        completion?(true, nil)
    }

    func pushTemplate(_ templateToPush: CPTemplate, animated: Bool, completion: ((Bool, Error?) -> Void)?) {
        stack.append(templateToPush)
        completion?(true, nil)
    }

    func popTemplate(animated: Bool, completion: ((Bool, Error?) -> Void)?) {
        if !stack.isEmpty { stack.removeLast() }
        completion?(true, nil)
    }

    func popToRootTemplate(animated: Bool, completion: ((Bool, Error?) -> Void)?) {
        stack = []
        poppedToRoot += 1
        completion?(true, nil)
    }

    func presentTemplate(_ templateToPresent: CPTemplate, animated: Bool, completion: ((Bool, Error?) -> Void)?) {
        presented = templateToPresent
        completion?(true, nil)
    }

    func dismissTemplate(animated: Bool, completion: ((Bool, Error?) -> Void)?) {
        presented = nil
        completion?(true, nil)
    }
}
