#if os(iOS) && HAS_QURAN
import CarPlay
import Combine
import UIKit

/// The car's screen. iOS connects this scene (the `CPTemplateApplicationSceneSessionRoleApplication`
/// entry in Info-Main.plist) when the iPhone joins a CarPlay head unit. It can arrive beside the phone's
/// window or on its own: CarPlay launches the app in the background with no window at all, which is why
/// nothing here waits on the launch cover (`AppReveal` stays revealed when no window ever mounts).
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private var controller: CarPlayController?

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didConnect interfaceController: CPInterfaceController) {
        let controller = CarPlayController(interface: interfaceController)
        self.controller = controller
        controller.start()
    }

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        controller?.stop()
        controller = nil
    }
}

/// What `CarPlayController` asks of the car's interface controller. A protocol so the unit tests can hand
/// in a recorder: a `CPInterfaceController` only exists inside a connected scene.
@MainActor
protocol CarPlayInterfacing: AnyObject {
    var topTemplate: CPTemplate? { get }
    var presentedTemplate: CPTemplate? { get }
    var carTraitCollection: UITraitCollection { get }
    func setRootTemplate(_ rootTemplate: CPTemplate, animated: Bool, completion: ((Bool, Error?) -> Void)?)
    func pushTemplate(_ templateToPush: CPTemplate, animated: Bool, completion: ((Bool, Error?) -> Void)?)
    func popTemplate(animated: Bool, completion: ((Bool, Error?) -> Void)?)
    func popToRootTemplate(animated: Bool, completion: ((Bool, Error?) -> Void)?)
    func presentTemplate(_ templateToPresent: CPTemplate, animated: Bool, completion: ((Bool, Error?) -> Void)?)
    func dismissTemplate(animated: Bool, completion: ((Bool, Error?) -> Void)?)
}

extension CPInterfaceController: CarPlayInterfacing {}

/// Four tabs (Listen, Surahs, Reciters, Prayers) over the app's own player and settings. Playback is the
/// phone's `QuranPlayer`, so the car's Now Playing screen, the lock screen and the phone's bar are one
/// session: the player already publishes Now Playing info and answers the remote commands CarPlay sends.
@MainActor
final class CarPlayController {
    private let interface: CarPlayInterfacing
    private let settings = Settings.shared
    private let player = QuranPlayer.shared
    private let quranData = QuranData.shared

    let listenTemplate = CPListTemplate(title: "Listen", sections: [])
    let surahsTemplate = CPListTemplate(title: "Surahs", sections: [])
    let recitersTemplate = CPListTemplate(title: "Reciters", sections: [])
    #if HAS_ADHAN
    let prayersTemplate = CPListTemplate(title: "Prayers", sections: [])
    #endif
    private(set) lazy var tabBar = CPTabBarTemplate(templates: tabs)

    private var tabs: [CPTemplate] {
        var tabs: [CPTemplate] = [listenTemplate, surahsTemplate, recitersTemplate]
        #if HAS_ADHAN
        tabs.append(prayersTemplate)
        #endif
        return tabs
    }

    /// The sections each list last received, so an unchanged list is never re-sent to the car.
    private var sent: [ObjectIdentifier: [CarPlaySection]] = [:]
    /// Pushed lists that stay live while open (their now-playing bars move as the recitation does),
    /// each with how to rebuild its rows. Held weakly: a list the driver backed out of goes away.
    private var liveLists: [LiveList] = []
    private struct LiveList {
        weak var template: CPListTemplate?
        let build: (_ surahs: [Int: CarPlaySurah], _ playback: CarPlayPlayback) -> [CarPlaySection]
    }
    /// The Sunnah Reminder presets the car can play (fixed data, built once).
    private lazy var sunnahRecitations = CarPlayContent.sunnahRecitations(from: SunnahReminderPreset.all)
    /// The Up Next list while it is open, kept in step with the queue.
    private var upNextTemplate: CPListTemplate?
    private lazy var nowPlayingButtons = NowPlayingButtons(controller: self)
    private var failureSheet: CPActionSheetTemplate?
    private var cancellables = Set<AnyCancellable>()
    private var clock: Timer?

    init(interface: CarPlayInterfacing) {
        self.interface = interface
    }

    func start() {
        configureTemplates()
        refresh()
        interface.setRootTemplate(tabBar, animated: false, completion: nil)
        observe()

        #if HAS_ADHAN
        // A car that launched the app on its own never mounted the Adhan tab, whose appearance is what
        // computes today's times; the stored list may be from the last day the phone was opened.
        let hasTodaysTimes = settings.prayers.map { Calendar.current.isDateInToday($0.day) } ?? false
        if !hasTodaysTimes {
            settings.fetchPrayerTimes()
        }
        #endif
        // The Downloaded section reads each reciter's count of files on disk: one pass, after the first
        // frame of templates has gone out (the phone's reciter list does the same on appear).
        DispatchQueue.main.async {
            ReciterDownloadManager.shared.ensureStatesLoaded(for: reciters)
        }
    }

    func stop() {
        CPNowPlayingTemplate.shared.remove(nowPlayingButtons)
        cancellables.removeAll()
        clock?.invalidate()
        clock = nil
    }

    // MARK: Templates

    private func configureTemplates() {
        listenTemplate.tabTitle = "Listen"
        listenTemplate.tabImage = UIImage(systemName: "play.circle")
        surahsTemplate.tabTitle = "Surahs"
        surahsTemplate.tabImage = UIImage(systemName: "book")
        surahsTemplate.emptyViewTitleVariants = ["Loading the Quran"]
        recitersTemplate.tabTitle = "Reciters"
        recitersTemplate.tabImage = UIImage(systemName: "person.wave.2")
        #if HAS_ADHAN
        prayersTemplate.tabTitle = "Prayers"
        prayersTemplate.tabImage = UIImage(systemName: "clock")
        prayersTemplate.emptyViewTitleVariants = ["No Prayer Times Yet"]
        prayersTemplate.emptyViewSubtitleVariants = ["Open \(AppIdentifiers.appName) on your iPhone to set your location."]
        #endif

        let nowPlaying = CPNowPlayingTemplate.shared
        nowPlaying.isUpNextButtonEnabled = !player.surahQueue.isEmpty
        nowPlaying.isAlbumArtistButtonEnabled = false
        nowPlaying.add(nowPlayingButtons)
    }

    /// Rebuilds every list from the stores and sends the ones that changed.
    func refresh() {
        refreshQuran()
        #if HAS_ADHAN
        refreshPrayers()
        #endif
    }

    private var playback: CarPlayPlayback {
        CarPlayPlayback(surah: player.currentSurahNumber, isPlaying: player.isPlaying)
    }

    private func refreshQuran() {
        let surahs = surahIndex()
        let playback = playback
        let maxItems = Self.maxItems
        let maxSections = Self.maxSections

        update(listenTemplate, with: CarPlayContent.listenSections(
            lastSurah: settings.lastListenedSurah,
            lastAyah: settings.lastListenedAyah,
            favorites: settings.favoriteSurahs,
            bookmarks: settings.bookmarkedAyahsInMushafOrder,
            history: player.listeningHistory,
            surahs: surahs,
            playback: playback,
            showsSunnah: !sunnahRecitations.isEmpty,
            maxItems: maxItems,
            maxSections: maxSections
        ))
        update(surahsTemplate, with: CarPlayContent.surahIndexSections(surahs: surahs, playback: playback))
        liveLists.removeAll { $0.template == nil }
        for list in liveLists {
            if let template = list.template { update(template, with: list.build(surahs, playback)) }
        }

        let isRandom = settings.reciter == Settings.randomReciterName
        let downloads = ReciterDownloadManager.shared
        update(recitersTemplate, with: CarPlayContent.reciterSections(
            selected: settings.resolvedSelectedReciterIgnoringRandom(),
            isRandom: isRandom,
            favorites: reciters.filter { settings.isReciterFavorite(reciterID: $0.id) },
            downloaded: reciters.compactMap { reciter in
                guard let state = downloads.statesByReciterID[reciter.id], state.completedSurahs > 0 || state.isDownloading else { return nil }
                return CarPlayDownloadedReciter(reciter: reciter, completedSurahs: state.completedSurahs, isDownloading: state.isDownloading)
            },
            groups: reciterGroups,
            maxItems: maxItems,
            maxSections: maxSections
        ))
    }

    #if HAS_ADHAN
    private func refreshPrayers(now: Date = Date()) {
        update(prayersTemplate, with: CarPlayContent.prayerSections(
            today: todaysPrayers(now: now),
            tomorrowFirst: Calendar.current.date(byAdding: .day, value: 1, to: now).flatMap { tomorrow in
                displayedPrayers(settings.getPrayerTimes(for: tomorrow, fullPrayers: showsFullPrayers) ?? [], for: tomorrow).first
            },
            city: settings.currentLocation?.city,
            now: now,
            formatTime: settings.formatDate
        ))
    }

    /// Today's list exactly as the Adhan tab shows it: the traveling "full prayers" choice, plus the
    /// optional prayers the user turned on (`PrayerList.prayers(for:)`).
    private func todaysPrayers(now: Date) -> [Prayer] {
        if let prayers = settings.prayers, Calendar.current.isDate(prayers.day, inSameDayAs: now) {
            return displayedPrayers(showsFullPrayers ? prayers.fullPrayers : prayers.prayers, for: prayers.day)
        }
        return displayedPrayers(settings.getPrayerTimes(for: now, fullPrayers: showsFullPrayers) ?? [], for: now)
    }

    private var showsFullPrayers: Bool { settings.travelingMode && settings.travelingShowFullPrayers }

    private func displayedPrayers(_ base: [Prayer], for date: Date) -> [Prayer] {
        settings.prayersIncludingOptional(base, for: date)
    }
    #endif

    private var reciterGroups: [CarPlayReciterGroup] {
        CarPlayContent.reciterGroups(includeRiwayat: settings.showQiraahDetails)
    }

    private func surahIndex() -> [Int: CarPlaySurah] {
        Dictionary(quranData.quran.map {
            ($0.id, CarPlaySurah(number: $0.id, name: $0.nameTransliteration, meaning: $0.nameEnglish, ayahCount: $0.numberOfAyahs))
        }, uniquingKeysWith: { first, _ in first })
    }

    /// The car's list limits. They vary by vehicle and shrink while it moves; zero (no car attached, as
    /// in the unit tests) means no limit worth applying.
    static var maxItems: Int { CPListTemplate.maximumItemCount > 0 ? Int(CPListTemplate.maximumItemCount) : 500 }
    static var maxSections: Int { CPListTemplate.maximumSectionCount > 0 ? Int(CPListTemplate.maximumSectionCount) : 50 }

    /// A new list, filled at creation. Its record in `sent` is written fresh: a key is an object
    /// identity, and a popped list's address can come back for the next one, whose sections may well
    /// be identical (the same group opened again), which `update` would then skip, leaving it blank.
    private func makeList(title: String, sections: [CarPlaySection]) -> CPListTemplate {
        let template = CPListTemplate(title: title, sections: sections.map(listSection))
        sent[ObjectIdentifier(template)] = sections
        return template
    }

    private func update(_ template: CPListTemplate, with sections: [CarPlaySection]) {
        let key = ObjectIdentifier(template)
        guard sent[key] != sections else { return }
        sent[key] = sections
        template.updateSections(sections.map(listSection))
    }

    private func listSection(_ section: CarPlaySection) -> CPListSection {
        CPListSection(items: section.rows.map(listItem), header: section.header, sectionIndexTitle: section.indexTitle)
    }

    private func listItem(_ row: CarPlayRow) -> CPListItem {
        let item = CPListItem(
            text: row.text,
            detailText: row.detail,
            image: image(for: row.artwork),
            accessoryImage: row.accessory == .checkmark ? UIImage(systemName: "checkmark") : nil,
            accessoryType: row.accessory == .disclosure ? .disclosureIndicator : .none
        )
        item.isPlaying = row.isPlaying
        item.playingIndicatorLocation = .trailing
        if let action = row.action {
            item.handler = { [weak self] _, completion in
                self?.perform(action)
                completion()
            }
        }
        return item
    }

    private func image(for artwork: CarPlayRow.Artwork) -> UIImage? {
        switch artwork {
        case .none:
            return nil
        case .symbol(let name):
            return UIImage(systemName: name)
        case .number(let number):
            let accent = UIColor(settings.accentColor.color).resolvedColor(with: interface.carTraitCollection)
            return CarPlayBadge.image(number: number, color: accent, scale: interface.carTraitCollection.displayScale)
        }
    }

    // MARK: Actions

    func perform(_ action: CarPlayAction) {
        switch action {
        case .resumeLastSurah:
            guard let last = settings.lastListenedSurah else { return }
            player.playSurah(surahNumber: last.surahNumber, surahName: last.surahName, certainReciter: true)
            showNowPlaying()
        case .resumeLastAyah:
            guard let last = settings.lastListenedAyah else { return }
            player.playAyah(surahNumber: last.surahNumber, ayahNumber: last.ayahNumber, continueRecitation: true)
            showNowPlaying()
        case .playSurah(let number):
            player.playSurah(surahNumber: number, surahName: quranData.surah(number)?.nameTransliteration ?? "Surah \(number)")
            showNowPlaying()
        case .playAyah(let surah, let ayah):
            player.playAyah(surahNumber: surah, ayahNumber: ayah, continueRecitation: true)
            showNowPlaying()
        case .resumeHistory(let id):
            guard let item = player.listeningHistory.first(where: { $0.id == id }) else { return }
            settings.lastListenedSurah = LastListenedSurah(
                surahNumber: item.surahNumber,
                surahName: item.surahName,
                reciter: item.reciter,
                currentDuration: item.currentDuration ?? 0,
                fullDuration: item.fullDuration ?? 0
            )
            player.playSurah(surahNumber: item.surahNumber, surahName: item.surahName, certainReciter: true)
            showNowPlaying()
        case .playRandomSurah:
            guard let surah = quranData.quran.randomElement() else { return }
            player.playSurah(surahNumber: surah.id, surahName: surah.nameTransliteration)
            showNowPlaying()
        case .openSurahGroup(let range):
            pushLiveList(title: CarPlayContent.groupTitle(range)) { surahs, playback in
                CarPlayContent.surahGroupSections(range, surahs: surahs, playback: playback)
            }
        case .selectReciter(let id):
            guard let reciter = reciters.first(where: { $0.id == id }) else { return }
            // The phone's picker only changes the selection: what is playing carries on, and the next
            // surah started plays the new reciter.
            settings.setSelectedReciter(reciter)
            refresh()
            interface.popToRootTemplate(animated: true, completion: nil)
        case .selectRandomReciter:
            settings.setRandomReciterMode()
            refresh()
            interface.popToRootTemplate(animated: true, completion: nil)
        case .openReciterGroup(let id, let page):
            guard let group = reciterGroups.first(where: { $0.id == id }) else { return }
            let selectedID = settings.reciter == Settings.randomReciterName ? nil : settings.resolvedSelectedReciterIgnoringRandom()?.id
            pushList(title: group.title, sections: CarPlayContent.reciterGroupSections(
                group, page: page, selectedID: selectedID, maxItems: Self.maxItems, maxSections: Self.maxSections
            ))
        case .openRiwayat:
            pushList(title: "Other Riwayat", sections: CarPlayContent.riwayatSections(groups: reciterGroups))
        case .playQueued(let id):
            guard let item = player.surahQueue.first(where: { $0.id == id }) else { return }
            player.removeQueuedSurah(id: id)
            player.playSurah(surahNumber: item.surahNumber, surahName: item.surahName)
            closeUpNext()
        case .clearQueue:
            player.clearSurahQueue()
            closeUpNext()
        case .openSunnah:
            let recitations = sunnahRecitations
            pushLiveList(title: "Sunnah Recitations") { _, playback in
                CarPlayContent.sunnahSections(recitations, weekday: Calendar.current.component(.weekday, from: Date()), playback: playback)
            }
        case .playSunnah(let id):
            guard let recitation = sunnahRecitations.first(where: { $0.id == id }) else { return }
            switch recitation.start {
            case .surah(let number):
                player.playSurah(surahNumber: number, surahName: quranData.surah(number)?.nameTransliteration ?? "Surah \(number)")
            case .ayah(let surah, let ayah):
                player.playAyah(surahNumber: surah, ayahNumber: ayah, continueRecitation: true)
            }
            // The rest of the recitation waits at the head of Up Next, ahead of anything queued on the
            // phone. A start that failed on the spot queues nothing: its explanation is up instead.
            if !recitation.followedBy.isEmpty, !player.showInternetAlert {
                player.queueSurahsNext(recitation.followedBy)
            }
            showNowPlaying()
        }
    }

    /// The Now Playing screen's Up Next button: the phone's surah queue, pushed over Now Playing.
    func showUpNext() {
        let template = makeList(title: "Up Next", sections: CarPlayContent.upNextSections(queue: player.surahQueue, surahs: surahIndex()))
        template.emptyViewTitleVariants = ["Nothing Up Next"]
        template.emptyViewSubtitleVariants = ["Add surahs to the queue on your iPhone."]
        upNextTemplate = template
        interface.pushTemplate(template, animated: true, completion: nil)
    }

    /// Back to Now Playing after an Up Next choice.
    private func closeUpNext() {
        if let template = upNextTemplate, interface.topTemplate === template {
            interface.popTemplate(animated: true, completion: nil)
        }
        upNextTemplate = nil
    }

    private func queueChanged(_ queue: [SurahQueueItem]) {
        CPNowPlayingTemplate.shared.isUpNextButtonEnabled = !queue.isEmpty
        if let template = upNextTemplate {
            update(template, with: CarPlayContent.upNextSections(queue: queue, surahs: surahIndex()))
        }
    }

    private func pushList(title: String, sections: [CarPlaySection]) {
        interface.pushTemplate(makeList(title: title, sections: sections), animated: true, completion: nil)
    }

    /// A pushed list whose rows follow playback until the driver backs out of it.
    private func pushLiveList(title: String, build: @escaping (_ surahs: [Int: CarPlaySurah], _ playback: CarPlayPlayback) -> [CarPlaySection]) {
        let template = makeList(title: title, sections: build(surahIndex(), playback))
        liveLists.append(LiveList(template: template, build: build))
        interface.pushTemplate(template, animated: true, completion: nil)
    }

    private func showNowPlaying() {
        // A play that failed on the spot (offline with nothing downloaded, a reciter who never recorded
        // the surah) has raised its explanation instead; Now Playing would only sit silent behind it.
        guard !player.showInternetAlert else { return }
        let nowPlaying = CPNowPlayingTemplate.shared
        guard interface.topTemplate !== nowPlaying else { return }
        interface.pushTemplate(nowPlaying, animated: true, completion: nil)
    }

    // MARK: Playback failures

    /// The phone's playback alert, as an action sheet on the car: its title and message, plus the
    /// "switch to a downloaded reciter" offer when there is one.
    private func presentFailure() {
        let alerts = player.alerts
        var actions: [CPAlertAction] = []
        if let offer = alerts.offlineReciterSwitch {
            actions.append(CPAlertAction(title: "Play \(offer.suggested.name)", style: .default) { [weak self] _ in
                self?.dismissFailure()
                QuranPlayer.shared.acceptOfflineReciterSwitch()
                self?.showNowPlaying()
            })
        }
        actions.append(CPAlertAction(title: "OK", style: .cancel) { [weak self] _ in
            self?.dismissFailure()
            QuranPlayer.shared.offlineReciterSwitch = nil
            QuranPlayer.shared.showInternetAlert = false
        })
        let sheet = CPActionSheetTemplate(title: alerts.playbackAlertTitle, message: alerts.playbackAlertMessage, actions: actions)
        failureSheet = sheet
        // One presented template at a time: anything already up is dismissed first, and the sheet goes
        // up once that has finished.
        guard interface.presentedTemplate != nil else {
            interface.presentTemplate(sheet, animated: true, completion: nil)
            return
        }
        interface.dismissTemplate(animated: false) { [weak self] _, _ in
            DispatchQueue.main.async {
                guard let self, self.failureSheet === sheet else { return }
                self.interface.presentTemplate(sheet, animated: true, completion: nil)
            }
        }
    }

    private func dismissFailure() {
        guard let sheet = failureSheet else { return }
        failureSheet = nil
        if interface.presentedTemplate === sheet {
            interface.dismissTemplate(animated: true, completion: nil)
        }
    }

    // MARK: Observation

    private func observe() {
        // `objectWillChange` fires BEFORE the write lands, so hop to the next main-queue turn first, then
        // throttle (not debounce: a reciter download publishes progress several times a second, and a
        // debounce would hold back every other refresh until it finished). The player is watched through
        // `nowPlaying`, which publishes only when what it holds changes; the player itself publishes on
        // every progress tick.
        let quranChanges: [AnyPublisher<Void, Never>] = [
            settings.objectWillChange.map { _ in () }.eraseToAnyPublisher(),
            quranData.objectWillChange.map { _ in () }.eraseToAnyPublisher(),
            player.history.objectWillChange.map { _ in () }.eraseToAnyPublisher(),
            ReciterDownloadManager.shared.objectWillChange.map { _ in () }.eraseToAnyPublisher(),
            player.nowPlaying.$snapshot
                .map { CarPlayPlayback(surah: $0.currentSurahNumber, isPlaying: $0.isPlaying) }
                .removeDuplicates()
                .map { _ in () }
                .eraseToAnyPublisher(),
        ]
        Publishers.MergeMany(quranChanges)
            .receive(on: DispatchQueue.main)
            .throttle(for: .milliseconds(400), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] in self?.refreshQuran() }
            .store(in: &cancellables)

        // A surah queued on the phone (or played off the queue) turns Up Next on or off.
        player.nowPlaying.$snapshot
            .map(\.surahQueue)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] queue in self?.queueChanged(queue) }
            .store(in: &cancellables)

        // An error already showing on the phone when the car connects stays the phone's to answer.
        player.alerts.$showInternetAlert
            .dropFirst()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] showing in
                if showing { self?.presentFailure() } else { self?.dismissFailure() }
            }
            .store(in: &cancellables)

        #if HAS_ADHAN
        // Prayer times move with the location, the day's recompute and the prayer settings.
        Publishers.Merge(
            settings.objectWillChange.map { _ in () },
            LiveState.shared.objectWillChange.map { _ in () }
        )
        .receive(on: DispatchQueue.main)
        .throttle(for: .seconds(1), scheduler: DispatchQueue.main, latest: true)
        .sink { [weak self] in self?.refreshPrayers() }
        .store(in: &cancellables)

        // The next prayer's countdown and the day rolling over. Cheap: an unchanged list is not re-sent.
        clock = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.refreshPrayers() }
        }
        #endif
    }
}

/// Forwards the Now Playing screen's Up Next button to the controller (the observer protocol is an
/// Objective-C one, so it needs an NSObject).
private final class NowPlayingButtons: NSObject, CPNowPlayingTemplateObserver {
    private weak var controller: CarPlayController?

    init(controller: CarPlayController) {
        self.controller = controller
    }

    func nowPlayingTemplateUpNextButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {
        DispatchQueue.main.async { [weak controller] in controller?.showUpNext() }
    }
}

/// The surah number on a disc of the accent color, the car's version of the phone's numbered surah rows.
enum CarPlayBadge {
    private static var cache: [String: UIImage] = [:]

    static func image(number: Int, color: UIColor, scale: CGFloat) -> UIImage {
        let key = "\(number)|\(color.hashValue)|\(scale)"
        if let cached = cache[key] { return cached }

        let limit = CPListItem.maximumImageSize
        let side = min(limit.width, limit.height) > 0 ? min(limit.width, limit.height) : 44
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale > 0 ? scale : 2
        let bounds = CGRect(x: 0, y: 0, width: side, height: side)
        let image = UIGraphicsImageRenderer(size: bounds.size, format: format).image { _ in
            color.setFill()
            UIBezierPath(ovalIn: bounds.insetBy(dx: 1, dy: 1)).fill()

            var font = UIFont.systemFont(ofSize: side * (number >= 100 ? 0.36 : 0.44), weight: .bold)
            if let rounded = font.fontDescriptor.withDesign(.rounded) {
                font = UIFont(descriptor: rounded, size: font.pointSize)
            }
            let text = "\(number)" as NSString
            let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: inkColor(on: color)]
            let size = text.size(withAttributes: attributes)
            text.draw(at: CGPoint(x: (side - size.width) / 2, y: (side - size.height) / 2), withAttributes: attributes)
        }
        cache[key] = image
        return image
    }

    /// White on a dark accent, near-black on a light one (yellow, mint, cyan).
    static func inkColor(on color: UIColor) -> UIColor {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return .white }
        let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue
        return luminance > 0.6 ? UIColor(white: 0.1, alpha: 1) : .white
    }
}
#endif
