#if os(iOS)
import SwiftUI

// Tips & Tricks (Abu, 2026-09-20: "for each settings page like for Quran Hadith adhan add a section that
// shows like tips and tricks especially those that are hard to discover and just list them all and
// maybe have a tutorial with them", and "make each obscure cool unique setting easy to find and front
// and center").
//
// The app had grown a great many gestures and settings that nothing on screen announces: holding the
// reader's title, tapping a word twice, dragging the sun, the number badges that are really buttons.
// This file is where they are written down, once, and three surfaces read from it:
//
//   - `TipsSection`, the first row of every settings page, opens that page's list (`TipsView`);
//   - `TipsTourView`, the tutorial: the same tips one card at a time, for the ones marked `tour`;
//   - `SettingsSpotlightSection`, on the Settings tab itself: the tips that are SETTINGS rather than
//     gestures (`spotlight`), as cards that open the setting they describe.
//
// EVERY TIP HERE WAS CHECKED AGAINST THE CODE THAT IMPLEMENTS IT (three catalogues with file and line,
// 2026-09-20; re-audited line by line on 2026-10-19, when Test Mode, the Revision plan, the Control
// Center controls, the menu shortcuts, History and the locators got their tips). A tip that describes
// something the app does not do is worse than no tip, so: when a feature's labels or gestures change,
// change its tip in the same commit, and never add one from memory. Things the app does NOT have, which
// a tip must therefore never promise: a sleep timer, a playback speed control, a hadith page mode, a
// narrator search, favorites or counters on individual duas, Hadith or Islam widgets and Siri
// shortcuts, and an .ics export of prayer times.
//
// No em dashes and no spaced hyphens in any of this text (house rule); quoted labels are the app's own.
//
// The companion apps (Al-Adhan, Al-Quran) compile this file too (HAS_TIPS in both sync manifests,
// 2026-10-11), each with only its own domains. An area whose tab an app does not have is compiled out
// with its flag (HAS_ADHAN, HAS_QURAN, HAS_HADITH), and the hub lists the areas that are left
// (`TipArea.offered`). A tip in an area every app has (Islam, the app) that names another domain
// either words itself by the same flags or hides (`shipsQuran`, `shipsPrayerTimes`): write new tips
// the same way, since a tip about a tab the reader does not have is exactly the wrong tip.

// MARK: - Model

/// The settings page a tip belongs to, which is also the list it appears in.
enum TipArea: String, CaseIterable, Identifiable {
    case adhan, notifications, quran, hadith, islam, app

    var id: String { rawValue }

    var title: String { String(localized: titleValue) }

    /// `title` in English in every interface language, for Ask AI's provenance line.
    var englishTitle: String { InterfaceText.english(titleValue) }

    private var titleValue: String.LocalizationValue {
        switch self {
        case .adhan: return "Prayer Times"
        case .notifications: return "Notifications"
        case .quran: return "Quran"
        case .hadith: return "Hadith"
        case .islam: return "Islam"
        case .app: return "The App"
        }
    }

    /// The list's and the tour's navigation titles ("The App Tips" is not English).
    var listTitle: String {
        switch self {
        case .adhan: return String(localized: "Prayer Times Tips")
        case .notifications: return String(localized: "Notification Tips")
        case .quran: return String(localized: "Quran Tips")
        case .hadith: return String(localized: "Hadith Tips")
        case .islam: return String(localized: "Islam Tips")
        case .app: return String(localized: "App Tips")
        }
    }

    var tourTitle: String {
        switch self {
        case .adhan: return String(localized: "Prayer Times Tour")
        case .notifications: return String(localized: "Notifications Tour")
        case .quran: return String(localized: "Quran Tour")
        case .hadith: return String(localized: "Hadith Tour")
        case .islam: return String(localized: "Islam Tour")
        case .app: return String(localized: "App Tour")
        }
    }

    var systemImage: String {
        switch self {
        case .adhan: return "safari.fill"
        case .notifications: return "bell.badge.fill"
        case .quran: return "character.book.closed.ar"
        case .hadith: return "text.book.closed.fill"
        case .islam: return "moon.stars.fill"
        case .app: return "gearshape.fill"
        }
    }

    /// The Settings hub's colour for the same area, so a tip's chip says where it lives at a glance.
    var tint: Color {
        switch self {
        case .adhan: return SettingsTint.prayer
        case .notifications: return SettingsTint.notifications
        case .quran: return SettingsTint.quran
        case .hadith: return SettingsTint.hadith
        case .islam: return SettingsTint.islam
        case .app: return SettingsTint.appearance
        }
    }

    var secondaryTint: Color? {
        self == .islam ? SettingsTint.islamSecondary : nil
    }

    /// The areas this app has tips for, in the hub's order. In Al-Adhan and Al-Quran a domain they do
    /// not ship compiles its areas out of `TipCatalog`, so the hub and its search entries list these.
    static let offered: [TipArea] = allCases.filter { area in TipCatalog.all.contains { $0.area == area } }
}

/// The two settings lists every settings page opens beside its Tips & Tricks (Abu, 2026-10-26: "add for
/// each settings page unique features where it's just a settings list of all of them and another one
/// called beginner features"). Each is a plain list of settings rows, never cards: a row is a tip with
/// a `destination`, and opens that setting's own screen (`FeatureListView`).
enum FeatureList: String, CaseIterable, Identifiable {
    /// What only this app has: the Settings tab's ONLY IN AL-ISLAM cards, as rows (`TipCatalog.spotlight`),
    /// so the two never drift apart.
    case unique
    /// What helps a new Muslim or an Arabic learner (`AppTip.beginner`).
    case beginner

    var id: String { rawValue }

    var title: String {
        switch self {
        case .unique: return String(localized: "Unique Features")
        case .beginner: return String(localized: "Beginner Features")
        }
    }

    var systemImage: String {
        switch self {
        case .unique: return "checkmark.seal.fill"
        case .beginner: return "leaf.fill"
        }
    }

    var tips: [AppTip] {
        switch self {
        case .unique: return TipCatalog.spotlight
        case .beginner: return TipCatalog.beginner
        }
    }

    /// The door row's caption on a settings page: how many, and for whom.
    var caption: String {
        let count = tips.count
        switch self {
        case .unique: return String(localized: "\(count) settings only \(AppIdentifiers.displayName) has")
        case .beginner: return String(localized: "\(count) settings for new Muslims and Arabic learners")
        }
    }
}

struct AppTip: Identifiable {
    let id: String
    let area: TipArea
    /// The list's section header ("THE SKY", "SEARCH").
    let group: String
    let systemImage: String
    let title: String
    let detail: String
    /// Where it is done, in the app's own words: "Adhan tab", "Quran reader, page mode".
    let place: String
    /// The setting the tip is about, when it is about one: the row then opens it.
    var destination: SettingsSearchEntry.Destination? = nil
    /// The setting is one its screen shows only with Advanced Settings on: the row says so, and
    /// opening it turns the switch on (`revealsAdvancedSettings`).
    var advanced = false
    /// One of the cards of the area's tour.
    var tour = false
    /// A setting worth a card on the Settings tab itself: the card's own short title and pitch (the
    /// tip's full title and detail are written for a list row, and truncate on a 168 pt card).
    var card: (title: String, pitch: String)? = nil
    var spotlight: Bool { card != nil }
    /// A setting made for a new Muslim or an Arabic learner: one row of the Beginner Features list
    /// (`FeatureList.beginner`, 2026-10-26). Only a tip with a `destination` belongs there, since that
    /// list is a settings list and every row opens its setting.
    var beginner = false
    /// False where the device cannot do it (Apple Intelligence, an OS version), so nobody is told
    /// about a control they do not have.
    var isAvailable: () -> Bool = { true }
    /// The group, title, detail and place in English in every interface language (`InterfaceText`):
    /// what Ask AI matches a question against and hands the model. The fields above are the screens'.
    let english: (group: String, title: String, detail: String, place: String)

    /// Each text is written as the literal `String(localized:)` would take (`InterfaceText("...")`), so
    /// its catalog key is unchanged, and resolved for the screens and in English.
    init(id: String, area: TipArea, group: InterfaceText, systemImage: String, title: InterfaceText,
         detail: InterfaceText, place: InterfaceText, destination: SettingsSearchEntry.Destination? = nil,
         advanced: Bool = false, tour: Bool = false, card: (title: InterfaceText, pitch: InterfaceText)? = nil,
         beginner: Bool = false, isAvailable: @escaping () -> Bool = { true }) {
        self.id = id
        self.area = area
        self.group = group.display
        self.systemImage = systemImage
        self.title = title.display
        self.detail = detail.display
        self.place = place.display
        self.destination = destination
        self.advanced = advanced
        self.tour = tour
        self.card = card.map { (title: $0.title.display, pitch: $0.pitch.display) }
        self.beginner = beginner
        self.isAvailable = isAvailable
        english = (group: group.english, title: title.english, detail: detail.english, place: place.english)
    }

    fileprivate var searchBlob: String {
        "\(title) \(detail) \(place) \(group)".folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}

// MARK: - The catalogue

enum TipCatalog {
    /// A tip about a control Simple Mode takes off the screen (the Optional Times pill, the date
    /// picker, the shuffles, the summary doors, Need a Hand?) is not offered while Simple Mode is on:
    /// it would teach a button the reader cannot see (Docs/Product/Simple Mode Guide.md).
    static let outsideSimpleMode: () -> Bool = { !Settings.shared.simpleMode }

    static func tips(in area: TipArea) -> [AppTip] {
        all.filter { $0.area == area && $0.isAvailable() }
    }

    /// The area's tips grouped under their headers, in the order written below.
    static func groups(in area: TipArea, matching query: String = "") -> [(title: String, tips: [AppTip])] {
        let terms = query
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .split(separator: " ").map(String.init)
        var order: [String] = []
        var byGroup: [String: [AppTip]] = [:]
        for tip in tips(in: area) where terms.allSatisfy({ tip.searchBlob.contains($0) }) {
            if byGroup[tip.group] == nil { order.append(tip.group) }
            byGroup[tip.group, default: []].append(tip)
        }
        guard !terms.isEmpty else { return order.map { ($0, byGroup[$0] ?? []) } }
        // Searching: within a group, the tip titled for the query leads the ones that mention it.
        return order.map { group in (group, SearchRank.sorted(byGroup[group] ?? [], by: query) { [$0.title] }) }
    }

    /// Every area's matching tips, grouped BY AREA, for the hub's own search bar. The hub lists the
    /// six areas as doors; searching it looks inside all six at once, so a half-remembered tip is
    /// found without first guessing which settings page owns it. Empty query = no sections, and the
    /// hub shows its ordinary six rows instead.
    static func areaMatches(matching query: String) -> [(area: TipArea, tips: [AppTip])] {
        let terms = query
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .split(separator: " ").map(String.init)
        guard !terms.isEmpty else { return [] }
        return TipArea.allCases.compactMap { area in
            let hits = tips(in: area).filter { tip in terms.allSatisfy { tip.searchBlob.contains($0) } }
            guard !hits.isEmpty else { return nil }
            // Same rule as a single area's list: the tip TITLED for the query leads the ones that
            // only mention it.
            return (area, SearchRank.sorted(hits, by: query) { [$0.title] })
        }
    }

    /// Three words worth trying when the hub's search finds nothing, each from an area this app has
    /// ("adhan" finds nothing in Al-Quran).
    static var searchHint: String {
        #if HAS_ADHAN && HAS_QURAN
        return String(localized: "\"adhan\", \"tajweed\" or \"widget\"")
        #elseif HAS_ADHAN
        return String(localized: "\"adhan\", \"qibla\" or \"widget\"")
        #elseif HAS_QURAN
        return String(localized: "\"tajweed\", \"reciter\" or \"widget\"")
        #else
        return String(localized: "\"tasbih\", \"dua\" or \"zakah\"")
        #endif
    }

    static func tour(in area: TipArea) -> [AppTip] {
        tips(in: area).filter(\.tour)
    }

    /// The Beginner Features rows (`FeatureList.beginner`): every tip marked `beginner` that opens a
    /// setting, in the catalogue's order, so the list reads area by area as the hub does.
    static var beginner: [AppTip] {
        all.filter { $0.beginner && $0.destination != nil && $0.isAvailable() }
    }

    /// A feature list's tips grouped by area, in area order, for its sections.
    static func areaGroups(_ tips: [AppTip]) -> [(area: TipArea, tips: [AppTip])] {
        TipArea.allCases.compactMap { area in
            let hits = tips.filter { $0.area == area }
            return hits.isEmpty ? nil : (area, hits)
        }
    }

    /// The Settings tab's cards, in the order they are worth meeting: the mode nobody else has first.
    private static let spotlightOrder = [
        "notif.nagging", "adhan.travel", "quran.wordtap", "quran.testmode", "adhan.menses", "quran.tajweedcolors",
        "quran.themes", "notif.sunnah", "quran.compare", "adhan.names", "adhan.skycolors",
        "islam.fajr", "app.themes",
    ]

    static var spotlight: [AppTip] {
        let cards = Dictionary(uniqueKeysWithValues: all.filter { $0.spotlight && $0.isAvailable() }.map { ($0.id, $0) })
        return spotlightOrder.compactMap { cards[$0] }
    }

    /// The app's name in a tip: الإسلام on an Arabic screen, Al-Islam to Ask AI.
    private static let app = InterfaceText(display: AppIdentifiers.displayName, english: AppIdentifiers.appName)
    /// The app's name inside a phrase said to Siri. Siri has no Urdu: an Urdu screen quotes the phrases in
    /// English, the language Siri runs in there, so the name is the one Siri hears, Al-Islam.
    private static let siriApp = InterfaceText(display: AppLanguage.isUrdu ? AppIdentifiers.appName : AppIdentifiers.displayName,
                                               english: AppIdentifiers.appName)
    private static var hasAppleIntelligence: Bool { OnDeviceAsk.isAvailable }
    private static var hasLiquidGlass: Bool {
        if #available(iOS 26.0, *) { return true }
        return false
    }
    private static var hasSiriShortcuts: Bool {
        if #available(iOS 16.0, *) { return true }
        return false
    }
    /// The Chosen Ayah widget is configured through App Intents, which widgets gained in iOS 17.
    private static var hasChosenAyahWidget: Bool {
        if #available(iOS 17.0, *) { return true }
        return false
    }
    private static var hasLiveActivities: Bool {
        if #available(iOS 16.2, *) { return true }
        return false
    }
    /// Control Center controls (Widget/ControlWidgets.swift) arrived with iOS 18.
    private static var hasControls: Bool {
        if #available(iOS 18.0, *) { return true }
        return false
    }
    /// The double tap and hold on a menu button (`ShortcutMenu`) need iOS 17.4.
    private static var hasMenuShortcuts: Bool {
        if #available(iOS 17.4, *) { return true }
        return false
    }

    /// The Quran domain (the readers, the reciters, the tajweed lessons): Al-Adhan has none of it.
    private static var shipsQuran: Bool {
        #if HAS_QURAN
        return true
        #else
        return false
        #endif
    }
    /// The prayer times and their calculation: Al-Quran has neither.
    private static var shipsPrayerTimes: Bool {
        #if HAS_ADHAN
        return true
        #else
        return false
        #endif
    }

    static let all: [AppTip] = adhan + adhanWeather + notifications + quran + hadith + islam + general

    /// The weather's tip, in Al-Islam alone (`HAS_WEATHER`, like iCloud Backup).
    private static var adhanWeather: [AppTip] {
        #if HAS_WEATHER
        return [
            AppTip(id: "adhan.weather", area: .adhan, group: InterfaceText("THE SKY"), systemImage: "cloud.sun.fill",
                   title: InterfaceText("Put the weather on the sky"),
                   detail: InterfaceText("Turn on Weather and the sky clouds over, rains and fogs with the real weather outside. The temperature sits at the top of the card (tap it for the UV index, humidity, wind and more, and for Try Another Sky, which dresses the sky in any condition while you look), At a Glance gains a Weather group, and the sky widgets show the temperature beside the city. It uses Apple Weather, so your location is sent to Apple while it is on."),
                   place: InterfaceText("Prayer Settings, Sky"), destination: .prayerPage(.sky)),
        ]
        #else
        return []
        #endif
    }

    private static var skyFillDetail: InterfaceText {
        #if HAS_WEATHER
        return InterfaceText("Sky Fills the Screen paints the Adhan tab's whole background with the sky: its colors, its stars at night and its weather, behind the prayer times and everything under them.")
        #else
        return InterfaceText("Sky Fills the Screen paints the Adhan tab's whole background with the sky: its colors and its stars at night, behind the prayer times and everything under them.")
        #endif
    }

    // MARK: Prayer times

    // The prayer times and their notifications are one domain: Al-Quran compiles both lists out.
    #if HAS_ADHAN
    private static let adhan: [AppTip] = [
        AppTip(id: "adhan.scrub", area: .adhan, group: InterfaceText("THE SKY"), systemImage: "sun.max.fill",
               title: InterfaceText("Drag the sun through the day"),
               detail: InterfaceText("On the sky card, drag the sun along its arc (at night, the moon). The sky recolors, a readout names the prayer and the time at that moment, and the prayer list follows along. Let go and it returns to now."),
               place: InterfaceText("Adhan tab, with Show Sky on"), destination: .prayerPage(.sky), tour: true),
        AppTip(id: "adhan.moon", area: .adhan, group: InterfaceText("THE SKY"), systemImage: "moonphase.waxing.gibbous",
               title: InterfaceText("The moon is tonight's moon"),
               detail: InterfaceText("The moon at the foot of the sky card shows the true phase and how much of it is lit. Pick another day under the prayer list and it shows that night's moon instead."),
               place: InterfaceText("Adhan tab")),
        AppTip(id: "adhan.moon3d", area: .adhan, group: InterfaceText("THE SKY"), systemImage: "moon.circle.fill",
               title: InterfaceText("Tap the moon to hold it"),
               detail: InterfaceText("Tap the moon at the foot of the sky card (or, with the skyline on, the one riding the arc at night) and it fills the screen as a globe, lit the way it is that night. Drag to turn it, pinch to zoom, double-tap to face Earth, and slide through the month to watch the phases move. Full Light shows the whole face at once."),
               place: InterfaceText("Adhan tab, with Show Sky on")),
        AppTip(id: "adhan.skyline", area: .adhan, group: InterfaceText("THE SKY"), systemImage: "building.columns.fill",
               title: InterfaceText("Give the horizon a skyline"),
               detail: InterfaceText("Skyline draws pyramids and a mosque along the horizon, in the app and on the Solar Arc and Day & Night widgets. Choose the pair, only pyramids, or only mosques."),
               place: InterfaceText("Prayer Settings, Sky"), destination: .prayerPage(.sky)),
        AppTip(id: "adhan.skycolors", area: .adhan, group: InterfaceText("THE SKY"), systemImage: "paintpalette.fill",
               title: InterfaceText("Paint your own sky"),
               detail: InterfaceText("Sky Colors gives every prayer two colors of its own. Tap a prayer's row to preview it, and Restore Default Colors brings the originals back."),
               place: InterfaceText("Prayer Settings, Sky, Sky Colors"), destination: .prayerPage(.skyColors), card: (InterfaceText("Sky Colors"), InterfaceText("Two colors of your own for every prayer's sky."))),
        AppTip(id: "adhan.skyfill", area: .adhan, group: InterfaceText("THE SKY"), systemImage: "rectangle.inset.filled",
               title: InterfaceText("Let the sky fill the whole tab"),
               detail: skyFillDetail,
               place: InterfaceText("Prayer Settings, Sky"), destination: .prayerPage(.sky)),
        AppTip(id: "adhan.stopadhan", area: .adhan, group: InterfaceText("THE SKY"), systemImage: "stop.circle.fill",
               title: InterfaceText("Stop an adhan, or play the one waiting"),
               detail: InterfaceText("While the adhan sounds inside the app, a capsule that reads \u{201C}Tap to stop\u{201D} sits at the foot of the sky card, and a banner with a Stop button shows on every tab. When an adhan is waiting instead (a silenced phone, or Play Automatically off), the same capsule and banner offer Play."),
               place: InterfaceText("Adhan tab")),

        AppTip(id: "adhan.rowdetail", area: .adhan, group: InterfaceText("THE PRAYER LIST"), systemImage: "list.bullet.rectangle",
               title: InterfaceText("Tap a prayer for its details"),
               detail: InterfaceText("Tap any prayer to unfold its rakah counts, the sunnah prayers around it, and its exact window. Tap again to fold it."),
               place: InterfaceText("Adhan tab"), tour: true),
        AppTip(id: "adhan.bell", area: .adhan, group: InterfaceText("THE PRAYER LIST"), systemImage: "bell.fill",
               title: InterfaceText("The bell is a three-way switch"),
               detail: InterfaceText("Tap the small bell on a prayer to step through prenotification, notification, and off. Touch and hold it to jump straight to the one you want."),
               place: InterfaceText("Adhan tab"), tour: true),
        AppTip(id: "adhan.layouts", area: .adhan, group: InterfaceText("THE PRAYER LIST"), systemImage: "square.grid.2x2",
               title: InterfaceText("Four layouts for the prayer list"),
               detail: InterfaceText("The ⋯ menu at the top of the Adhan tab switches between Prayer Tiles, Prayer Grid, Prayer List, and Prayer Split. Prayer Settings offers the same choice."),
               place: InterfaceText("Adhan tab")),
        AppTip(id: "adhan.optionalpill", area: .adhan, group: InterfaceText("THE PRAYER LIST"), systemImage: "moon.stars",
               title: InterfaceText("Optional times without leaving the tab"),
               detail: InterfaceText("The Optional Times pill under the prayer list turns on Duhaa, Islamic Midnight, and the Last Third of the Night right there. They show in the app only, never in widgets."),
               place: InterfaceText("Adhan tab"), destination: .prayerPage(.optionalPrayers), isAvailable: TipCatalog.outsideSimpleMode),
        AppTip(id: "adhan.rakaah", area: .adhan, group: InterfaceText("THE PRAYER LIST"), systemImage: "tablecells",
               title: InterfaceText("A rakah table at hand"),
               detail: InterfaceText("The Rakaah Guide pill unfolds the fard and sunnah rakahs of every prayer, with what changes on Friday and while traveling."),
               place: InterfaceText("Adhan tab")),
        AppTip(id: "adhan.otherday", area: .adhan, group: InterfaceText("THE PRAYER LIST"), systemImage: "calendar",
               title: InterfaceText("Look at any other day"),
               detail: InterfaceText("The date picker under the prayer list shows any day's times, and its arrows step a day at a time. Compare Today sets that day beside today's, and Back to Today returns."),
               place: InterfaceText("Adhan tab"), isAvailable: TipCatalog.outsideSimpleMode),
        AppTip(id: "adhan.pull", area: .adhan, group: InterfaceText("THE PRAYER LIST"), systemImage: "arrow.down.circle",
               title: InterfaceText("Pull down for a fresh location"),
               detail: InterfaceText("Pulling down on the Adhan tab takes a new GPS fix, which is what corrects the city after a flight."),
               place: InterfaceText("Adhan tab")),
        AppTip(id: "adhan.countdown", area: .adhan, group: InterfaceText("THE PRAYER LIST"), systemImage: "timer",
               title: InterfaceText("More on the countdown"),
               detail: InterfaceText("Tap the countdown card to show or hide the extra prayer details beneath it."),
               place: InterfaceText("Adhan tab")),

        AppTip(id: "adhan.compass", area: .adhan, group: InterfaceText("QIBLA AND PLACE"), systemImage: "location.north.line.fill",
               title: InterfaceText("Enlarge the compass"),
               detail: InterfaceText("Tap the row with your city and the small compass to enlarge the Qibla compass. It then shows your coordinates and elevation, and you can feel it: light taps while you are off, firmer ones as you close in, and a distinct one within five degrees."),
               place: InterfaceText("Adhan tab"), tour: true),
        AppTip(id: "adhan.copy", area: .adhan, group: InterfaceText("QIBLA AND PLACE"), systemImage: "doc.on.doc",
               title: InterfaceText("Copy where and when you are"),
               detail: InterfaceText("Touch and hold the city name, the coordinates, or the Hijri date to copy them."),
               place: InterfaceText("Adhan tab")),
        AppTip(id: "adhan.citytimes", area: .adhan, group: InterfaceText("QIBLA AND PLACE"), systemImage: "globe.europe.africa.fill",
               title: InterfaceText("Another city's prayer times"),
               detail: InterfaceText("Tap the city pill for City Prayer Times. Star the cities you check often, compare one with your own location, and read its times in its clock or yours. It never changes your own times."),
               place: InterfaceText("Adhan tab")),
        AppTip(id: "adhan.glance", area: .adhan, group: InterfaceText("QIBLA AND PLACE"), systemImage: "rectangle.grid.2x2.fill",
               title: InterfaceText("Every tile is a button"),
               detail: InterfaceText("The AT A GLANCE tiles all open something. Qibla opens a large compass, Daylight and Fasting Window open the Prayer Calendar, Moon opens the Hijri Calendar, and Prayer Calculation and Distance From Home open their settings."),
               place: InterfaceText("Adhan tab"), tour: true, isAvailable: TipCatalog.outsideSimpleMode),

        AppTip(id: "adhan.trackerhold", area: .adhan, group: InterfaceText("THE PRAYER TRACKER"), systemImage: "checkmark.circle.fill",
               title: InterfaceText("Tap for on time, hold for more"),
               detail: InterfaceText("Tap a prayer's circle to mark it prayed on time, and tap again to clear it. Touch and hold for Late and Missed."),
               place: InterfaceText("Adhan tab, Prayer Tracker"), tour: true),
        AppTip(id: "adhan.history", area: .adhan, group: InterfaceText("THE PRAYER TRACKER"), systemImage: "chart.bar.fill",
               title: InterfaceText("History & Insights"),
               detail: InterfaceText("Under the tracker, History & Insights shows your days, weeks, months, and years, with streaks. Tap a day in the month, or a month in the year, to open it."),
               place: InterfaceText("Adhan tab, Prayer Tracker"), destination: .prayerTracker),
        AppTip(id: "adhan.menses", area: .adhan, group: InterfaceText("THE PRAYER TRACKER"), systemImage: "pause.circle.fill",
               title: InterfaceText("Pause for menstruation and postpartum"),
               detail: InterfaceText("Pause tracking, on the history page, exempts those days. They never break your streak, they stay out of every statistic, and the \u{201C}Did you pray?\u{201D} reminders stay silent while prayer-time notifications continue. Any single past day can be marked exempt too."),
               place: InterfaceText("Prayer Tracker, History & Insights"), destination: .prayerTracker, card: (InterfaceText("Tracker Pause"), InterfaceText("Menstruation and postpartum days that never break a streak."))),
        AppTip(id: "adhan.markgate", area: .adhan, group: InterfaceText("THE PRAYER TRACKER"), systemImage: "lock.fill",
               title: InterfaceText("Marks wait for the adhan"),
               detail: InterfaceText("A prayer can be marked only once its time has come in, so today's row shows what is still left to pray. Past days can always be filled in from History & Insights."),
               place: InterfaceText("Prayer Tracker, History & Insights"), destination: .prayerTracker),
        AppTip(id: "adhan.jumuah", area: .adhan, group: InterfaceText("THE PRAYER TRACKER"), systemImage: "person.3.fill",
               title: InterfaceText("Jumuah counts as Dhuhr"),
               detail: InterfaceText("Marking either one covers Friday's noon prayer."),
               place: InterfaceText("Prayer Tracker")),

        AppTip(id: "adhan.export", area: .adhan, group: InterfaceText("CALENDARS"), systemImage: "square.and.arrow.up",
               title: InterfaceText("Export a year of prayer times"),
               detail: InterfaceText("The Prayer Calendar covers this month and the year ahead. Its share button exports them as a PDF or a CSV, under your own prayer names."),
               place: InterfaceText("Adhan tab, Prayer Calendar")),
        AppTip(id: "adhan.hijri", area: .adhan, group: InterfaceText("CALENDARS"), systemImage: "calendar.badge.clock",
               title: InterfaceText("Two Hijri calendars in one"),
               detail: InterfaceText("The Hijri Calendar's toolbar button switches between a month grid and the list of Islamic dates. Tap a day for its details, and touch and hold an Islamic date to copy it."),
               place: InterfaceText("Adhan tab, Hijri Calendar")),

        AppTip(id: "adhan.travel", area: .adhan, group: InterfaceText("TRAVEL AND CALCULATION"), systemImage: "airplane",
               title: InterfaceText("Traveling mode turns itself on"),
               detail: InterfaceText("Set a home city and the app notices when you are more than 48 miles (about 77 km) from it, offers to shorten and combine your prayers, and offers to switch back when you return."),
               place: InterfaceText("Prayer Settings, Traveling Mode"), destination: .prayerPage(.travelingMode), tour: true, card: (InterfaceText("Auto Traveling Mode"), InterfaceText("Notices when you are 48 miles from home and offers to shorten your prayers."))),
        AppTip(id: "adhan.autocalc", area: .adhan, group: InterfaceText("TRAVEL AND CALCULATION"), systemImage: "function",
               title: InterfaceText("The method follows the country"),
               detail: InterfaceText("With Choose Automatically on, the calculation method changes to the one customary where you are, and asks you first. The list of methods is searchable."),
               place: InterfaceText("Prayer Settings, Prayer Calculation"), destination: .prayerPage(.prayerCalculation)),
        AppTip(id: "adhan.angles", area: .adhan, group: InterfaceText("TRAVEL AND CALCULATION"), systemImage: "angle",
               title: InterfaceText("Match your mosque's angles"),
               detail: InterfaceText("Under the Custom method, the Fajr and Isha angles can each be set from 8 to 25 degrees, for a mosque that publishes its own."),
               place: InterfaceText("Prayer Settings, Prayer Calculation"), destination: .prayerPage(.prayerCalculation), advanced: true),
        AppTip(id: "adhan.names", area: .adhan, group: InterfaceText("TRAVEL AND CALCULATION"), systemImage: "character.cursor.ibeam",
               title: InterfaceText("Call the prayers what you call them"),
               detail: InterfaceText("Custom Prayer Names renames any prayer everywhere at once: the app, its notifications, the widgets, and the Apple Watch."),
               place: InterfaceText("Prayer Settings, Custom Prayer Names"), destination: .prayerPage(.customPrayerNames), card: (InterfaceText("Custom Prayer Names"), InterfaceText("Call the prayers what you call them, everywhere at once."))),
        AppTip(id: "adhan.offsets", area: .adhan, group: InterfaceText("TRAVEL AND CALCULATION"), systemImage: "slider.horizontal.3",
               title: InterfaceText("Follow your mosque's clock"),
               detail: InterfaceText("Manual Offsets move any prayer by up to 190 minutes either way, and the Hijri date by up to three days."),
               place: InterfaceText("Prayer Settings, Manual Offsets"), destination: .prayerPage(.manualOffsets)),
        AppTip(id: "adhan.maghribdate", area: .adhan, group: InterfaceText("TRAVEL AND CALCULATION"), systemImage: "sunset.fill",
               title: InterfaceText("A day that begins at sunset"),
               detail: InterfaceText("Switch Hijri Date at Maghrib turns the Hijri date over at Maghrib instead of midnight, the way the Islamic day runs."),
               place: InterfaceText("Prayer Settings, Manual Offsets"), destination: .prayerPage(.manualOffsets)),

        AppTip(id: "adhan.siri", area: .adhan, group: InterfaceText("BEYOND THE APP"), systemImage: "mic.fill",
               title: InterfaceText("Ask Siri"),
               detail: InterfaceText { "\u{201C}When is Asr in \(siriApp[$0])\u{201D}, \u{201C}Current prayer in \(siriApp[$0])\u{201D}, and \u{201C}Next prayer in \(siriApp[$0])\u{201D} are answered aloud without opening the app." },
               place: InterfaceText("Siri and Shortcuts"), isAvailable: { hasSiriShortcuts }),
        AppTip(id: "adhan.widgets", area: .adhan, group: InterfaceText("BEYOND THE APP"), systemImage: "rectangle.3.group.fill",
               title: InterfaceText("Widgets with a sky"),
               detail: InterfaceText("Most prayer widgets come in a Sky version painted with your sky colors. The Lock Screen has prayer-time and Hijri date widgets, including one that sits above the clock."),
               place: InterfaceText("Home Screen and Lock Screen")),
        AppTip(id: "adhan.controls", area: .adhan, group: InterfaceText("BEYOND THE APP"), systemImage: "switch.2",
               title: InterfaceText("The next prayer in Control Center"),
               detail: InterfaceText("Two controls for Control Center, the Lock Screen, and the Action button: Prayer Times shows the next prayer and its time on the control itself and opens today's times, and Qibla opens the compass."),
               place: InterfaceText("Control Center, Add a Control"), isAvailable: { hasControls }),
        AppTip(id: "adhan.liveactivity", area: .adhan, group: InterfaceText("BEYOND THE APP"), systemImage: "fork.knife",
               title: InterfaceText("Ramadan on the Lock Screen"),
               detail: InterfaceText("In Ramadan a Live Activity counts down to the end of suhoor and to iftar, appearing an hour before each."),
               place: InterfaceText("Lock Screen and Dynamic Island"), isAvailable: { hasLiveActivities }),
        AppTip(id: "adhan.watch", area: .adhan, group: InterfaceText("BEYOND THE APP"), systemImage: "applewatch",
               title: InterfaceText("On your wrist"),
               detail: InterfaceText("The Apple Watch app has a sky strip of its own that you can drag through the day, complications with the current prayer and a live countdown, and settings that stay in step with the iPhone."),
               place: InterfaceText("Apple Watch")),
    ]

    // MARK: Notifications

    private static let notifications: [AppTip] = [
        AppTip(id: "notif.nagging", area: .notifications, group: InterfaceText("PRAYING ON TIME"), systemImage: "exclamationmark.bubble.fill",
               title: InterfaceText("Nagging Mode"),
               detail: InterfaceText("Asks \u{201C}Did you pray it?\u{201D} as each prayer's time runs out and keeps asking until you answer. You choose when it starts, how often it repeats, which prayers, a check-in after the adhan, the tone, and a pause."),
               place: InterfaceText("Notifications, Nagging Mode"), destination: .notificationsPage(.naggingMode), tour: true, card: (InterfaceText("Nagging Mode"), InterfaceText("Asks \u{201C}Did you pray?\u{201D} until you answer. Now with its own schedule, tone, and pause.")), beginner: true),
        AppTip(id: "notif.lockscreen", area: .notifications, group: InterfaceText("PRAYING ON TIME"), systemImage: "hand.tap.fill",
               title: InterfaceText("Answer from the Lock Screen"),
               detail: InterfaceText("Touch and hold a \u{201C}Did you pray?\u{201D} reminder for \u{201C}Yes, on time\u{201D} and \u{201C}Yes, but late\u{201D}. Either one marks the prayer tracker and cancels the rest of that prayer's reminders, without opening the app."),
               place: InterfaceText("Lock Screen"), tour: true),
        AppTip(id: "notif.tapasks", area: .notifications, group: InterfaceText("PRAYING ON TIME"), systemImage: "questionmark.bubble.fill",
               title: InterfaceText("Tapping a notification logs the prayer"),
               detail: InterfaceText("Open the app from any prayer notification and it asks \u{201C}Did you pray it?\u{201D} about the prayer that notification was for, even days later, and records your answer in the tracker."),
               place: InterfaceText("Any prayer notification")),

        AppTip(id: "notif.fulladhan", area: .notifications, group: InterfaceText("THE ADHAN"), systemImage: "speaker.wave.3.fill",
               title: InterfaceText("Open the app, hear the whole adhan"),
               detail: InterfaceText("iOS lets a notification play 30 seconds at most. With the app open at prayer time, or opened within five minutes of it, the adhan plays in full. On a silenced phone, or with Play Automatically off, a Play button appears instead, on the prayer card and in a banner on every tab."),
               place: InterfaceText("Adhan tab"), tour: true),
        AppTip(id: "notif.silent", area: .notifications, group: InterfaceText("THE ADHAN"), systemImage: "bell.slash.fill",
               title: InterfaceText("Through Silent Mode"),
               detail: InterfaceText("The app reads Silent Mode before it starts an adhan: silenced, it offers a Play button rather than playing to no one. Play in Silent Mode lets the in-app adhan sound anyway. Notifications outside the app always follow the iPhone's own sound settings."),
               place: InterfaceText("Notifications"), destination: .notifications),
        AppTip(id: "notif.preview", area: .notifications, group: InterfaceText("THE ADHAN"), systemImage: "play.circle.fill",
               title: InterfaceText("Preview plays the full recording"),
               detail: InterfaceText("Preview Sound plays the chosen adhan from beginning to end, not the 30 seconds a notification carries."),
               place: InterfaceText("Notifications"), destination: .notifications),
        AppTip(id: "notif.perprayer", area: .notifications, group: InterfaceText("THE ADHAN"), systemImage: "slider.horizontal.below.rectangle",
               title: InterfaceText("A different sound for each prayer"),
               detail: InterfaceText("Tap a prayer under Prayer Notifications to choose between the adhan, a short excerpt of it, and an ordinary tone: a full adhan at Maghrib and a quiet tone at Fajr, if that suits your house."),
               place: InterfaceText("Notifications, Prayer Notifications"), destination: .notificationsPage(.prayerReminders)),
        AppTip(id: "notif.alerttone", area: .notifications, group: InterfaceText("THE ADHAN"), systemImage: "waveform",
               title: InterfaceText("A tone for being told, not called"),
               detail: InterfaceText("The Alert Tone plays for everything that is not a call to prayer: prenotifications, Shurooq, the optional times, and prayers whose adhan is off. Echo and Takbir are soft; Chime, Ring, and Alarm are made to carry through noise."),
               place: InterfaceText("Notifications"), destination: .notifications),

        AppTip(id: "notif.meanings", area: .notifications, group: InterfaceText("WORDING AND DATES"), systemImage: "textformat",
               title: InterfaceText("Say what the names mean"),
               detail: InterfaceText("Show English Meanings words a notification as \u{201C}Time for Maghrib (sunset)\u{201D}."),
               place: InterfaceText("Notifications, Prayer Notifications"), destination: .notificationsPage(.prayerReminders), beginner: true),
        AppTip(id: "notif.daybefore", area: .notifications, group: InterfaceText("WORDING AND DATES"), systemImage: "calendar.badge.exclamationmark",
               title: InterfaceText("Never surprised by Ramadan"),
               detail: InterfaceText("Remind a Day Before sends a heads-up the evening before each Islamic date, so Ramadan, Eid, and the days of fasting do not arrive unannounced."),
               place: InterfaceText("Notifications"), destination: .notifications),
    ] + sunnahReminderTips + [
        AppTip(id: "notif.focus", area: .notifications, group: InterfaceText("WORDING AND DATES"), systemImage: "moon.zzz.fill",
               title: InterfaceText("Through a Focus, if you allow it"),
               detail: InterfaceText { "Prayer notifications are marked Time Sensitive. Allow Time Sensitive notifications for \(app[$0]) in a Focus such as Sleep or Do Not Disturb and they still come through." },
               place: InterfaceText("iPhone Settings, Focus")),
    ]

    // Its screen lives in the Quran domain (iPhone/Quran/Models/SunnahReminders.swift), which
    // Al-Adhan never receives, and a reminder's tap opens the surah in the reader. Its own list, so the
    // page it names (`SettingsNotificationsPage.sunnahReminders`) compiles out with it.
    #if HAS_QURAN
    private static let sunnahReminderTips: [AppTip] = [
        AppTip(id: "notif.sunnah", area: .notifications, group: InterfaceText("WORDING AND DATES"), systemImage: "bell.badge",
               title: InterfaceText("Sunnah Reminders"),
               detail: InterfaceText("Al-Kahf on Friday, al-Mulk before sleep, and more, each at a time you choose and each with the hadith it comes from. Tapping one opens the surah."),
               place: InterfaceText("Notifications, Sunnah Reminders"), destination: .notificationsPage(.sunnahReminders), card: (InterfaceText("Sunnah Reminders"), InterfaceText("Al-Kahf on Friday, al-Mulk before sleep, each with its hadith.")), isAvailable: { shipsQuran }),
    ]
    #else
    private static let sunnahReminderTips: [AppTip] = []
    #endif
    #else
    private static let adhan: [AppTip] = []
    private static let notifications: [AppTip] = []
    #endif

    // MARK: Quran

    // Al-Adhan has no Quran reader.
    #if HAS_QURAN
    private static let quran: [AppTip] = [
        AppTip(id: "quran.testmode", area: .quran, group: InterfaceText("READING"), systemImage: "eye.slash",
               title: InterfaceText("Test Mode: recite from memory"),
               detail: InterfaceText("Test Mode, in the reader's play menu, hides the Quran's text in both readers until you tap an ayah, so you can recite from memory and check yourself. Its settings choose whether the Arabic alone or everything hides, whether a tap shows one ayah or everything before it too, and whether Reveal as It's Recited uncovers each ayah as the reciter reaches it. Hide All Again, in the same menu, starts over."),
               place: InterfaceText("Quran reader, play menu"), destination: .quranPage(.testMode), tour: true, card: (InterfaceText("Test Mode"), InterfaceText("Hide the text, recite from memory, tap an ayah to check."))),
        AppTip(id: "quran.menushortcuts", area: .quran, group: InterfaceText("READING"), systemImage: "hand.tap.fill",
               title: InterfaceText("Double tap for a shortcut"),
               detail: InterfaceText("Double tap an ayah's text, anywhere off a word, to play just that ayah. Tap its play button for Choose Reciter, Repeat Ayah, Play From Ayah and Play This Ayah; double tap the button to play from there to the end of the surah, or hold it for a custom range. Double tap its ellipsis to copy; hold to share. The reader's own play button at the bottom opens its menu on a tap: double tap it to play the surah, or hold it for a custom range (Choose Reciter, in a riwayah other than Hafs). Hadith ellipsis buttons use the same copy and share shortcuts. A Copied badge confirms when the copy is ready. With VoiceOver, use the named actions or the menu."),
               place: InterfaceText("Ayah and hadith controls"), isAvailable: { hasMenuShortcuts }),
        // The two settings the app was first known for, written down so the Beginner Features list can
        // open them (2026-10-26). Checked against SettingsQuranView (Enable Arabic Beginner Mode on Arabic
        // Text, Show Transliteration on English Text) and `AyahDisplayOption.beginner`.
        AppTip(id: "quran.beginnermode", area: .quran, group: InterfaceText("READING"), systemImage: "text.word.spacing",
               title: InterfaceText("Arabic Beginner Mode"),
               detail: InterfaceText("Enable Arabic Beginner Mode, on Arabic Text, puts a space between each Arabic letter, so a learner can tell the letters apart while reading the Quran. Apply Settings on an ayah, or on several selected at once, turns Beginner Mode on for just those."),
               place: InterfaceText("Quran Settings, Arabic Text"), destination: .quranPage(.arabicText), beginner: true),
        AppTip(id: "quran.transliteration", area: .quran, group: InterfaceText("READING"), systemImage: "character.textbox",
               title: InterfaceText("Read the Arabic in Latin letters"),
               detail: InterfaceText("Show Transliteration, on English Text, writes each ayah in Latin letters beneath the Arabic, so it can be read aloud before the script is familiar. Hafs only, with Include English on."),
               place: InterfaceText("Quran Settings, English Text"), destination: .quranPage(.englishText), beginner: true),
        AppTip(id: "quran.holdtitle", area: .quran, group: InterfaceText("MOVING AROUND"), systemImage: "hand.tap.fill",
               title: InterfaceText("Hold the title to choose a surah"),
               detail: InterfaceText("In the reader, touch and hold the title at the top to go straight to Choose Surah. In page mode, holding the pill at the foot of the page does the same. A plain tap on the title opens its whole menu."),
               place: InterfaceText("Quran reader"), tour: true),
        AppTip(id: "quran.modes", area: .quran, group: InterfaceText("MOVING AROUND"), systemImage: "book",
               title: InterfaceText("Pages or a list, same place"),
               detail: InterfaceText("Read as Pages and Read as List, in the title's menu, switch the reader and keep you on the same ayah."),
               place: InterfaceText("Quran reader, title menu")),
        AppTip(id: "quran.wheel", area: .quran, group: InterfaceText("MOVING AROUND"), systemImage: "number",
               title: InterfaceText("Jump to a page or a juz"),
               detail: InterfaceText("In page mode, tap the page or juz number at the foot of the page for a wheel, and the keyboard icon inside it to type the number instead."),
               place: InterfaceText("Quran reader, page mode")),
        AppTip(id: "quran.chevron", area: .quran, group: InterfaceText("MOVING AROUND"), systemImage: "chevron.down",
               title: InterfaceText("Fold the controls away"),
               detail: InterfaceText("The small chevron at the very bottom of a page hides every bar for a clean mushaf page, and brings them back."),
               place: InterfaceText("Quran reader, page mode"), tour: true),
        AppTip(id: "quran.pdf", area: .quran, group: InterfaceText("MOVING AROUND"), systemImage: "doc.richtext",
               title: InterfaceText("Read the printed mushaf"),
               detail: InterfaceText("In page mode the title's menu offers Read Pages as Printed Mushaf (PDF) wherever that riwayah's mushaf is included, with Automatic, Light, and Night lighting."),
               place: InterfaceText("Quran reader, page mode")),
        AppTip(id: "quran.pinch", area: .quran, group: InterfaceText("MOVING AROUND"), systemImage: "plus.magnifyingglass",
               title: InterfaceText("Pinch a page to magnify it"),
               detail: InterfaceText("Pinch a mushaf page to zoom into it, up to five times its size."),
               place: InterfaceText("Quran reader, page mode")),
        AppTip(id: "quran.fitpage", area: .quran, group: InterfaceText("MOVING AROUND"), systemImage: "rectangle.portrait.arrowtriangle.2.inward",
               title: InterfaceText("Pages set like the printed mushaf"),
               detail: InterfaceText("Fit Page to Screen sets each page the way the printed mushaf sets it, the same lines broken at the same words, at the largest size that fits your screen, in your own font and colors."),
               place: InterfaceText("Quran Settings, Arabic Text"), destination: .quranPage(.arabicText)),

        AppTip(id: "quran.holdayah", area: .quran, group: InterfaceText("AYAHS AND WORDS"), systemImage: "ellipsis.circle.fill",
               title: InterfaceText("Touch and hold an ayah"),
               detail: InterfaceText("In either reader, touch and hold an ayah for everything you can do with it: tafsir, notes, highlights, playback, comparison, sharing. In list mode the row's ellipsis opens the same actions."),
               place: InterfaceText("Quran reader"), tour: true),
        AppTip(id: "quran.wordtap", area: .quran, group: InterfaceText("AYAHS AND WORDS"), systemImage: "character.magnify",
               title: InterfaceText("Tap a word twice"),
               detail: InterfaceText("Two taps on a word open Word Study: its meaning, its grammar with each part of the word lit in turn (prefix, stem, suffix), its root with every word built on it, the ayah's themes, and its tajweed. Switch to any other word of the ayah from the strip, or tap a word of the same root to study it there. A single tap still marks the ayah. It works offline, on Hafs."),
               place: InterfaceText("Quran reader"), destination: .quranPage(.arabicText), tour: true, card: (InterfaceText("Word Study"), InterfaceText("Tap a word twice for its meaning, grammar, root, and themes.")), beginner: true),
        AppTip(id: "quran.pins", area: .quran, group: InterfaceText("AYAHS AND WORDS"), systemImage: "slider.horizontal.2.square",
               title: InterfaceText("Settings for one ayah"),
               detail: InterfaceText("Apply Settings, in an ayah's actions, changes how that one ayah is shown: beginner spacing, tajweed, tashkeel, dots, word by word. Reset to App Settings puts it back."),
               place: InterfaceText("Quran reader, ayah actions")),
        AppTip(id: "quran.select", area: .quran, group: InterfaceText("AYAHS AND WORDS"), systemImage: "checklist",
               title: InterfaceText("Select several ayahs"),
               detail: InterfaceText("Select Ayahs, in the title's menu, lets you tap as many ayahs as you like and then copy, share, bookmark, highlight, or annotate them together."),
               place: InterfaceText("Quran reader, title menu")),
        AppTip(id: "quran.notes", area: .quran, group: InterfaceText("AYAHS AND WORDS"), systemImage: "note.text",
               title: InterfaceText("Notes and colors"),
               detail: InterfaceText("Give any ayah a note or a highlight color. Either one bookmarks it, and your notes also gather in the Islamic Journal."),
               place: InterfaceText("Quran reader, ayah actions")),
        AppTip(id: "quran.keepopen", area: .quran, group: InterfaceText("AYAHS AND WORDS"), systemImage: "rectangle.stack",
               title: InterfaceText("Keep the actions open"),
               detail: InterfaceText("With Keep Sheet Open on, tafsir and the other tools open on top of an ayah's actions instead of replacing them, so you come back to where you were. Keep Sheet Open While Playing, in the actions themselves, leaves them up while Play This Ayah or Repeat Ayah recites (Play From Ayah still closes them), and Keep Screen On stops the screen from sleeping while they are open."),
               place: InterfaceText("Quran Settings, Reading View"), destination: .quranPage(.readingView)),
        AppTip(id: "quran.similar", area: .quran, group: InterfaceText("AYAHS AND WORDS"), systemImage: "arrow.triangle.branch",
               title: InterfaceText("Ayahs that resemble each other"),
               detail: InterfaceText("Similar Ayahs and Mutashabihat, in an ayah's actions, list the ayahs that resemble it and the phrases it shares with others: a help in memorizing."),
               place: InterfaceText("Quran reader, ayah actions")),
        AppTip(id: "quran.surahinfo", area: .quran, group: InterfaceText("AYAHS AND WORDS"), systemImage: "info.circle.fill",
               title: InterfaceText("About this Surah"),
               detail: InterfaceText("Tap a surah's heading on a page, or Surah Info in the title's menu, for its background from several sources."),
               place: InterfaceText("Quran reader")),
        AppTip(id: "quran.previewsize", area: .quran, group: InterfaceText("AYAHS AND WORDS"), systemImage: "textformat.size",
               title: InterfaceText("Resize the ayah card"),
               detail: InterfaceText("The minus and plus on the card at the top of an ayah's actions resize its Arabic, and tapping the percentage between them resets it."),
               place: InterfaceText("Quran reader, ayah actions")),

        AppTip(id: "quran.legend", area: .quran, group: InterfaceText("TAJWEED AND QIRAAT"), systemImage: "circle.hexagongrid.fill",
               title: InterfaceText("The Legend pill does two things"),
               detail: InterfaceText("Tap the row of colored dots for the full tajweed guide. Touch and hold it for a quick reminder of what the colors mean. With tajweed colors and theme highlights both off, the dots turn grey and a tap opens the switches that bring them back."),
               place: InterfaceText("Quran reader"), tour: true),
        AppTip(id: "quran.tajweedcolors", area: .quran, group: InterfaceText("TAJWEED AND QIRAAT"), systemImage: "eyedropper.halffull",
               title: InterfaceText("Choose your own tajweed colors"),
               detail: InterfaceText("Open the tajweed guide from the reader's Legend pill, or from Customize Tajweed Colors in Quran Settings. Under More Detail, tap a rule's card to show or hide that rule, and use the color well on the card to recolor it."),
               place: InterfaceText("Quran Settings, Arabic Text"), destination: .quranPage(.arabicText), card: (InterfaceText("Your Tajweed Colors"), InterfaceText("Show, hide, and recolor every tajweed rule."))),
        AppTip(id: "quran.compare", area: .quran, group: InterfaceText("TAJWEED AND QIRAAT"), systemImage: "rectangle.split.2x1",
               title: InterfaceText("Compare the riwayat"),
               detail: InterfaceText("With Comparison mode on, a riwayah picker sits above the reader's search bar, and an ayah's Compare Ayah sets the readings side by side. The Qiraat Explorer steps through every place the riwayat differ."),
               place: InterfaceText("Quran Settings, Arabic Text"), destination: .quranPage(.arabicText), card: (InterfaceText("Compare Riwayat"), InterfaceText("Read the riwayat side by side and step through where they differ."))),
        AppTip(id: "quran.bare", area: .quran, group: InterfaceText("TAJWEED AND QIRAAT"), systemImage: "textformat.abc.dottedunderline",
               title: InterfaceText("The text without its marks"),
               detail: InterfaceText("Hide Arabic Tashkeel and Hide Arabic Dots show the words the way the earliest mushafs were written, across every riwayah."),
               place: InterfaceText("Quran Settings, Arabic Text"), destination: .quranPage(.arabicText)),

        AppTip(id: "quran.refs", area: .quran, group: InterfaceText("SEARCH"), systemImage: "magnifyingglass",
               title: InterfaceText("Search understands references"),
               detail: InterfaceText("Type 2:255, \u{201C}page 50\u{201D}, \u{201C}juz 30\u{201D}, or a surah's number or name. Negative numbers count from the end: \u{201C}-1\u{201D} is the last surah, page, and juz. An ayah known by a name opens by it: \u{201C}Ayatul Kursi\u{201D} is 2:255."),
               place: InterfaceText("Quran tab, search"), tour: true),
        AppTip(id: "quran.filters", area: .quran, group: InterfaceText("SEARCH"), systemImage: "slider.horizontal.3",
               title: InterfaceText("Search filter buttons"),
               detail: InterfaceText("A short row of buttons appears above the results while you search: your Bookmarks and Favorites, Makki or Madani, and Best Match. Tap More for the rest, several at once: Whole Word, All Words or Any Word, chosen juz or surahs, translation or transliteration only, Go To a page or hizb, and which kinds of result to show. The first button opens every filter on one page, including words to leave out."),
               place: InterfaceText("Quran tab, search"), tour: true),
        AppTip(id: "quran.operators", area: .quran, group: InterfaceText("SEARCH"), systemImage: "character.cursor.ibeam",
               title: InterfaceText("Whole words, every word, without a word"),
               detail: InterfaceText("Tap More in the filter row for Match, Words and Without. Match finds whole words only, or words that start or end with what you typed. Words asks for every word anywhere in the ayah, or any one of them, and Without leaves words out. The same buttons sit over the search inside a surah and over page mode's find bar."),
               place: InterfaceText("Quran tab, search")),
        AppTip(id: "quran.spelling", area: .quran, group: InterfaceText("SEARCH"), systemImage: "textformat.abc",
               title: InterfaceText("Spell it your way"),
               detail: InterfaceText("Yaseen, Yasin, Bakara, Rehman: romanized spellings find the right surah. Romanized words find their ayahs too, however you spell them: sabr, tawbah, dhikr, shaytan, alhamdulillah. \u{201C}makki\u{201D} and \u{201C}madani\u{201D} list the surahs by where they were revealed."),
               place: InterfaceText("Quran tab, search")),
        AppTip(id: "quran.semantic", area: .quran, group: InterfaceText("SEARCH"), systemImage: "sparkles",
               title: InterfaceText("Search by meaning"),
               detail: InterfaceText("Ayah search also matches by meaning, on your device, so a phrase like \u{201C}being patient in hardship\u{201D} finds ayahs that never use those words. When both kinds of result exist, a switch chooses between Keyword Results and AI Results, and the search filters choose which one opens first."),
               place: InterfaceText("Quran tab, search")),
        AppTip(id: "quran.findbar", area: .quran, group: InterfaceText("SEARCH"), systemImage: "doc.text.magnifyingglass",
               title: InterfaceText("Find on this page"),
               detail: InterfaceText("In page mode, Search opens a find bar for the page or the whole surah, with arrows to step through the matches. Type a reference there, such as 2:255, to jump to it."),
               place: InterfaceText("Quran reader, page mode")),

        AppTip(id: "quran.playmenu", area: .quran, group: InterfaceText("LISTENING"), systemImage: "play.circle.fill",
               title: InterfaceText("The play button is a menu"),
               detail: InterfaceText("Tap play for Choose Reciter and Play Ayah by Ayah, and under Other Options a custom range, a random ayah, a random reciter, and Repeat Surah up to 20 times."),
               place: InterfaceText("Quran reader"), tour: true),
        AppTip(id: "quran.range", area: .quran, group: InterfaceText("LISTENING"), systemImage: "repeat",
               title: InterfaceText("A range built for memorizing"),
               detail: InterfaceText("Play Custom Range takes a range of ayahs or of pages, with Whole Page and Whole Surah a tap away, repeats Each Ayah and the Whole Range as many times as you set (or forever), and lists every ayah of the range before you press Play Range. While it plays, the range line under the reciter on the Now Playing bar opens the same list, with the ayah being recited marked and kept in view. Tap any ayah there to jump to it."),
               place: InterfaceText("Quran reader, play menu")),
        AppTip(id: "quran.nowplaying", area: .quran, group: InterfaceText("LISTENING"), systemImage: "waveform.circle.fill",
               title: InterfaceText("Hold the Now Playing bar"),
               detail: InterfaceText("Touch and hold the player for Stop Playing, Play from Beginning, the queue, and favoriting the surah or bookmarking the ayah. While a custom range plays it adds Range Ayahs. Inside the reader, tapping the player jumps to the ayah being recited."),
               place: InterfaceText("Now Playing bar")),
        AppTip(id: "quran.dots", area: .quran, group: InterfaceText("LISTENING"), systemImage: "circle.fill",
               title: InterfaceText("What the reciter dots mean"),
               detail: InterfaceText("In the reciter list, tap the colored dot beside a name to learn what that reciter offers: ayah by ayah in their own voice, offline, or full surahs only. A purple dot means the recording is incomplete, and tapping it says which surahs exist."),
               place: InterfaceText("Quran Settings, Recitation"), destination: .reciters),
        AppTip(id: "quran.download", area: .quran, group: InterfaceText("LISTENING"), systemImage: "icloud.and.arrow.down",
               title: InterfaceText("Take a reciter offline"),
               detail: InterfaceText("The cloud button on a reciter downloads every surah for listening without a connection, and Reciter Filter shows only the ones you have downloaded."),
               place: InterfaceText("Quran Settings, Recitation"), destination: .reciters),
        AppTip(id: "quran.afterend", area: .quran, group: InterfaceText("LISTENING"), systemImage: "forward.end.fill",
               title: InterfaceText("When a surah ends"),
               detail: InterfaceText("After Surah Recitation Ends chooses between going on to the next surah, going back to the previous one, and stopping."),
               place: InterfaceText("Quran Settings, Recitation"), destination: .quranPage(.recitation)),
        AppTip(id: "quran.awake", area: .quran, group: InterfaceText("LISTENING"), systemImage: "light.max",
               title: InterfaceText("The screen stays on while you follow along"),
               detail: InterfaceText("While the recitation is highlighting the ayah being read in either reader, the screen does not go to sleep. Pause, stop, or leave the reader and it sleeps as usual, so listening with the phone put away costs the screen nothing."),
               place: InterfaceText("Quran reader, during playback")),

        AppTip(id: "quran.swipe", area: .quran, group: InterfaceText("THE QURAN TAB"), systemImage: "hand.draw.fill",
               title: InterfaceText("Swipe a surah"),
               detail: InterfaceText("Swipe a surah right to favorite it and left to play it. Touch and hold for View Fullscreen, Share Surah, Play Random Ayah, and Add to Queue."),
               place: InterfaceText("Quran tab"), tour: true),
        AppTip(id: "quran.tiles", area: .quran, group: InterfaceText("THE QURAN TAB"), systemImage: "square.grid.3x3.fill",
               title: InterfaceText("Hold a tile for its menu"),
               detail: InterfaceText("In any grid, a tap opens the tile and a touch and hold opens its menu. The small star in a tile's corner favorites it without opening it."),
               place: InterfaceText("Quran tab, grid view")),
        AppTip(id: "quran.sort", area: .quran, group: InterfaceText("THE QURAN TAB"), systemImage: "arrow.up.arrow.down",
               title: InterfaceText("Eleven ways to sort"),
               detail: InterfaceText("The sort menu orders the surahs by revelation, by juz, by page, by their length in ayahs, pages, words, or letters, and by the sajdahs and the broken letters they carry. Its Khatm mode tracks a full reading and marks ayahs as you read them."),
               place: InterfaceText("Quran tab")),
        AppTip(id: "quran.planner", area: .quran, group: InterfaceText("THE QURAN TAB"), systemImage: "calendar.badge.clock",
               title: InterfaceText("Plan a khatm, or a revision"),
               detail: InterfaceText("The Quran Planner, under Explore in the ⋯ menu at the top of the Quran tab, holds two plans. Khatm sets a finish of one, two, or three months and recomputes each day's amount from what is left, so a missed day is absorbed. Revision keeps a juz range or chosen surahs in rotation, revised in full every week, two weeks, or month, with Continue Revising and Mark as Revised. One Daily Reminder covers both."),
               place: InterfaceText("Quran tab, ⋯ menu")),
        AppTip(id: "quran.history", area: .quran, group: InterfaceText("THE QURAN TAB"), systemImage: "clock.arrow.circlepath",
               title: InterfaceText("What you read, heard, and searched"),
               detail: InterfaceText("History, in the ⋯ menu at the top of the Quran tab, keeps what you read, the ayahs and surahs you listened to, earlier Ayahs of the Day, and your recent searches. Tap a past search to run it again."),
               place: InterfaceText("Quran tab, ⋯ menu")),
        AppTip(id: "quran.themes", area: .quran, group: InterfaceText("THE QURAN TAB"), systemImage: "paintbrush.pointed.fill",
               title: InterfaceText("Highlight Themes"),
               detail: InterfaceText("Wash passages in the color of what they speak about, in both readers, or light one subject across the whole Quran with Browse by Theme."),
               place: InterfaceText("Quran Settings, Highlight Themes"), destination: .quranPage(.highlightThemes), card: (InterfaceText("Highlight Themes"), InterfaceText("Passages washed in the color of what they speak about."))),
        AppTip(id: "quran.shuffleaotd", area: .quran, group: InterfaceText("THE QURAN TAB"), systemImage: "shuffle",
               title: InterfaceText("Another Ayah of the Day"),
               detail: InterfaceText("The shuffle beside today's Ayah of the Day picks a different one, and the Today pill gathers the ayah, word, hadith, dua, and reminder of the day on one screen."),
               place: InterfaceText("Quran tab, Your Summary"), isAvailable: TipCatalog.outsideSimpleMode),
        AppTip(id: "quran.share", area: .quran, group: InterfaceText("THE QURAN TAB"), systemImage: "photo.fill",
               title: InterfaceText("Share an ayah as an image"),
               detail: InterfaceText("Share Ayah makes an image or plain text, with your choice of font and backdrop, tajweed colors, your note, and the ayah's details."),
               place: InterfaceText("Quran reader, ayah actions")),
        AppTip(id: "quran.siri", area: .quran, group: InterfaceText("THE QURAN TAB"), systemImage: "mic.fill",
               title: InterfaceText("Ask Siri to recite"),
               detail: InterfaceText { "\u{201C}Play surah Yaseen in \(siriApp[$0])\u{201D}, \u{201C}Play random surah in \(siriApp[$0])\u{201D}, and \u{201C}Play last listened surah in \(siriApp[$0])\u{201D}. Siri understands names, numbers, and common spellings." },
               place: InterfaceText("Siri and Shortcuts"), isAvailable: { hasSiriShortcuts }),
        AppTip(id: "quran.widgets", area: .quran, group: InterfaceText("THE QURAN TAB"), systemImage: "rectangle.3.group.fill",
               title: InterfaceText("The Quran on your Home Screen"),
               detail: InterfaceText("Widgets for the Ayah of the Day, the Reminder of the Day, a Name of Allah, your Last Read Ayah, your Last Listened Surah, and a Chosen Ayah you pick yourself. Tapping an ayah widget opens that ayah."),
               place: InterfaceText("Home Screen and Lock Screen")),
        AppTip(id: "quran.chosenWidget", area: .quran, group: InterfaceText("THE QURAN TAB"), systemImage: "bookmark.fill",
               title: InterfaceText("Choose the ayah on your widget"),
               detail: InterfaceText("Add the Chosen Ayah widget to your Home Screen or Lock Screen, then hold it and choose Edit Widget. Pick one of your bookmarks, or type a reference such as 2:255 or Yaseen 9. Until you choose, it shows your newest bookmark."),
               place: InterfaceText("Home Screen and Lock Screen, Edit Widget"), isAvailable: { hasChosenAyahWidget }),
        AppTip(id: "quran.controls", area: .quran, group: InterfaceText("THE QURAN TAB"), systemImage: "switch.2",
               title: InterfaceText("Resume from Control Center"),
               detail: InterfaceText("Add the Resume Recitation control to Control Center, the Lock Screen, or the Action button, and it plays the last surah you were listening to, from where you left off, without opening the app."),
               place: InterfaceText("Control Center, Add a Control"), isAvailable: { hasControls }),
    ]
    #else
    private static let quran: [AppTip] = []
    #endif

    // MARK: Hadith

    // The Hadith tab is Al-Islam's alone.
    #if HAS_HADITH
    private static let hadith: [AppTip] = [
        AppTip(id: "hadith.pills", area: .hadith, group: InterfaceText("SAVING"), systemImage: "number.circle.fill",
               title: InterfaceText("The number badges are buttons"),
               detail: InterfaceText("Tap the number beside a book or a chapter to favorite it. Tap a hadith's reference badge, such as Bukhari 5103, to bookmark it."),
               place: InterfaceText("Hadith tab"), tour: true),
        AppTip(id: "hadith.rowmenu", area: .hadith, group: InterfaceText("SAVING"), systemImage: "ellipsis.circle.fill",
               title: InterfaceText("Every hadith has a menu"),
               detail: InterfaceText("Touch and hold a hadith, or tap its ellipsis, for Bookmark Hadith, Add Note, Copy Hadith, and Share Hadith. Your notes show under the hadith and gather in the Islamic Journal."),
               place: InterfaceText("Hadith reader"), tour: true),
        AppTip(id: "hadith.swipe", area: .hadith, group: InterfaceText("SAVING"), systemImage: "hand.draw.fill",
               title: InterfaceText("Swipe a book or a chapter"),
               detail: InterfaceText("Swipe right to favorite it. Touch and hold for View Fullscreen and for sharing the book or the whole chapter."),
               place: InterfaceText("Hadith tab")),
        AppTip(id: "hadith.asks", area: .hadith, group: InterfaceText("SAVING"), systemImage: "checkmark.shield.fill",
               title: InterfaceText("It asks before removing"),
               detail: InterfaceText("Removing a bookmark or a favorite always asks first, and says so when a note would go with it."),
               place: InterfaceText("Everywhere")),

        AppTip(id: "hadith.reference", area: .hadith, group: InterfaceText("SEARCH"), systemImage: "arrow.forward.circle.fill",
               title: InterfaceText("Go straight to a hadith"),
               detail: InterfaceText("Search \u{201C}bukhari 5103\u{201D} or \u{201C}muslim 3:12\u{201D} to open that exact narration. A bare number finds that chapter and that hadith in every collection. Inside a book the name is optional: \u{201C}1:4\u{201D} is chapter 1, hadith 4."),
               place: InterfaceText("Hadith tab, search"), tour: true),
        AppTip(id: "hadith.filters", area: .hadith, group: InterfaceText("SEARCH"), systemImage: "slider.horizontal.3",
               title: InterfaceText("Search filter buttons"),
               detail: InterfaceText("A short row of buttons appears above the results while you search. Choose the collections (or tap Bukhari & Muslim), keep only Sahih, Hasan, or Da'if narrations, and order the hadiths by Best Match. Tap More for Six Books, All Words or Any Word, and which kinds of result to show. The first button opens every filter on one page. The same row, without the collections, sits over the search inside a book and inside a chapter."),
               place: InterfaceText("Hadith tab, search"), tour: true),
        AppTip(id: "hadith.semantic", area: .hadith, group: InterfaceText("SEARCH"), systemImage: "sparkles",
               title: InterfaceText("Search by meaning"),
               detail: InterfaceText("Search also matches by meaning across all 17 collections, on your device, so \u{201C}controlling anger\u{201D} finds narrations that never say those words."),
               place: InterfaceText("Hadith tab, search"), tour: true),
        AppTip(id: "hadith.crosslanguage", area: .hadith, group: InterfaceText("SEARCH"), systemImage: "character.bubble.fill",
               title: InterfaceText("One language lights the other"),
               detail: InterfaceText("An English search highlights the matching words in the Arabic too, and an Arabic search the English."),
               place: InterfaceText("Hadith tab, search")),
        AppTip(id: "hadith.help", area: .hadith, group: InterfaceText("SEARCH"), systemImage: "questionmark.circle.fill",
               title: InterfaceText("Help appears when you need it"),
               detail: InterfaceText("Tap the search field while it is empty for Quick Search Help and your recent searches. The minus folds the help away and keeps the searches."),
               place: InterfaceText("Hadith tab, search")),

        AppTip(id: "hadith.titlemenu", area: .hadith, group: InterfaceText("READING"), systemImage: "list.bullet.indent",
               title: InterfaceText("The chapter title is a menu"),
               detail: InterfaceText("In a chapter, tap the title for Choose Chapter and for Select Hadiths, which copies, shares, or bookmarks several at once."),
               place: InterfaceText("Hadith reader"), tour: true),
        AppTip(id: "hadith.grades", area: .hadith, group: InterfaceText("READING"), systemImage: "rosette",
               title: InterfaceText("Grades, with who gave them"),
               detail: InterfaceText("Where a narration has been graded, the grade shows under it with the scholar's name, and stays visible whichever language you hide."),
               place: InterfaceText("Hadith reader")),
        AppTip(id: "hadith.onelanguage", area: .hadith, group: InterfaceText("READING"), systemImage: "textformat",
               title: InterfaceText("Read in one language"),
               detail: InterfaceText("Hide the Arabic or the English to read only the other. A search still shows the hidden language wherever it matched."),
               place: InterfaceText("Hadith Settings"), destination: .hadithPage(.arabicText), beginner: true),
        AppTip(id: "hadith.allah", area: .hadith, group: InterfaceText("READING"), systemImage: "paintbrush.fill",
               title: InterfaceText("The name of Allah in red"),
               detail: InterfaceText("Highlight Allah colors His name in both the Arabic and the English."),
               place: InterfaceText("Hadith Settings, Reading View"), destination: .hadithPage(.readingView)),
        AppTip(id: "hadith.share", area: .hadith, group: InterfaceText("READING"), systemImage: "photo.fill",
               title: InterfaceText("Share as an image"),
               detail: InterfaceText("Share Hadith builds an image or plain text, and lets you choose which of the reference, the Arabic, and the English go in."),
               place: InterfaceText("Hadith reader")),

        AppTip(id: "hadith.daily", area: .hadith, group: InterfaceText("YOUR SUMMARY"), systemImage: "sun.max.fill",
               title: InterfaceText("Another Hadith of the Day"),
               detail: InterfaceText("The shuffle beside today's hadith picks a different one, and the plus in YOUR SUMMARY unfolds the days before."),
               place: InterfaceText("Hadith tab"), isAvailable: TipCatalog.outsideSimpleMode),
        AppTip(id: "hadith.shuffle", area: .hadith, group: InterfaceText("YOUR SUMMARY"), systemImage: "shuffle",
               title: InterfaceText("Open something at random"),
               detail: InterfaceText("The shuffle in the BOOKMARKS header opens one of your bookmarks at random, and the one above a group of books opens a random book."),
               place: InterfaceText("Hadith tab"), isAvailable: TipCatalog.outsideSimpleMode),
        AppTip(id: "hadith.doors", area: .hadith, group: InterfaceText("YOUR SUMMARY"), systemImage: "rectangle.3.group",
               title: InterfaceText("Topics, Encyclopedia, History"),
               detail: InterfaceText("Three doors in the ⋯ menu at the top of the Hadith tab: hadiths gathered by topic, an encyclopedia of explained narrations, and everything you have opened or searched. Tapping a past search in History runs it again."),
               place: InterfaceText("Hadith tab, ⋯ menu")),
        AppTip(id: "hadith.ai", area: .hadith, group: InterfaceText("YOUR SUMMARY"), systemImage: "sparkles",
               title: InterfaceText("Summaries, on your device"),
               detail: InterfaceText("A hadith's menu offers Summarize with AI, and search offers Ask AI about what you typed. Both run on the iPhone itself."),
               place: InterfaceText("Hadith reader"), isAvailable: { hasAppleIntelligence }),
    ]
    #else
    private static let hadith: [AppTip] = []
    #endif

    // MARK: Islam

    // Every app of the family has the Islam tab, so these always compile; the few that name the Quran
    // or the hadith say only what this app has.

    /// Ask AI's sources, which follow the same flags (`AskAIRetrieval.retrieve`).
    private static var askAISources: InterfaceText {
        #if HAS_QURAN && HAS_HADITH
        return InterfaceText("the Quran, the hadith collections, and the app's articles")
        #elseif HAS_QURAN
        return InterfaceText("the Quran and the app's articles")
        #elseif HAS_HADITH
        return InterfaceText("the hadith collections and the app's articles")
        #else
        return InterfaceText("the app's articles")
        #endif
    }

    private static var islamFontDetail: InterfaceText {
        let shared = InterfaceText("The duas, the dhikr, the 99 Names, and the alphabet share one Arabic font, chosen here.")
        #if HAS_QURAN && HAS_HADITH
        return InterfaceText { "\(shared[$0]) The Quran and the hadith books keep their own." }
        #elseif HAS_QURAN
        return InterfaceText { "\(shared[$0]) The Quran keeps its own." }
        #elseif HAS_HADITH
        return InterfaceText { "\(shared[$0]) The hadith books keep their own." }
        #else
        return shared
        #endif
    }

    /// The journal gathers the notes left in the readers, so without one it holds your entries alone.
    private static var journalTitle: InterfaceText {
        #if HAS_QURAN || HAS_HADITH
        return InterfaceText("A journal that gathers your notes")
        #else
        return InterfaceText("A journal of your own")
        #endif
    }

    private static var journalDetail: InterfaceText {
        let rest = InterfaceText("Swipe an entry to pin or delete it, and export everything as text from its menu.")
        #if HAS_QURAN && HAS_HADITH
        return InterfaceText { "The Islamic Journal collects the notes you leave on ayahs and hadiths beside your own entries. \(rest[$0])" }
        #elseif HAS_QURAN
        return InterfaceText { "The Islamic Journal collects the notes you leave on ayahs beside your own entries. \(rest[$0])" }
        #elseif HAS_HADITH
        return InterfaceText { "The Islamic Journal collects the notes you leave on hadiths beside your own entries. \(rest[$0])" }
        #else
        return InterfaceText { "The Islamic Journal keeps your own entries. \(rest[$0])" }
        #endif
    }

    private static let islam: [AppTip] = [
        AppTip(id: "islam.tasbih", area: .islam, group: InterfaceText("DHIKR AND DUA"), systemImage: "circles.hexagonpath.fill",
               title: InterfaceText("The whole card counts"),
               detail: InterfaceText("In the Tasbih Counter, tap anywhere on the counter card to count. Tap a dhikr in the list to count that one, and set the ring to complete every 33, 99, 100, 500, or 1,000."),
               place: InterfaceText("Islam tab, Tasbih Counter"), tour: true),
        AppTip(id: "islam.tasbihstats", area: .islam, group: InterfaceText("DHIKR AND DUA"), systemImage: "flame.fill",
               title: InterfaceText("Your dhikr adds up"),
               detail: InterfaceText("The Tasbih keeps today's count, your day streak, your best streak, and a lifetime total that resets and corrections never lower."),
               place: InterfaceText("Islam tab, Tasbih Counter")),
        AppTip(id: "islam.session", area: .islam, group: InterfaceText("DHIKR AND DUA"), systemImage: "play.rectangle.fill",
               title: InterfaceText("Guided dua sessions"),
               detail: InterfaceText("Start Session, at the top of a dua collection, walks its duas one at a time, full screen, with a ring you tap to count repetitions. It moves on when you reach your target and remembers where you stopped."),
               place: InterfaceText("Islam tab, Dua & Supplications"), tour: true),
        AppTip(id: "islam.listenall", area: .islam, group: InterfaceText("DHIKR AND DUA"), systemImage: "speaker.wave.2.fill",
               title: InterfaceText("Listen All"),
               detail: InterfaceText("In the duas and the dhikr, Listen All reads a whole section aloud in Arabic and highlights the line being read. For a better voice, download an Enhanced Arabic voice under Accessibility, Spoken Content, Voices in the iPhone's Settings."),
               place: InterfaceText("Islam tab, Duas and Dhikr")),
        AppTip(id: "islam.copyrows", area: .islam, group: InterfaceText("DHIKR AND DUA"), systemImage: "doc.on.doc",
               title: InterfaceText("Copy any part of a dua"),
               detail: InterfaceText("Touch and hold a dua or a dhikr to copy its Arabic, its transliteration, or its translation."),
               place: InterfaceText("Islam tab, Duas and Dhikr")),

        AppTip(id: "islam.letters", area: .islam, group: InterfaceText("LEARNING"), systemImage: "textformat.size.ar",
               title: InterfaceText("Hear every letter"),
               detail: InterfaceText("On a letter's page, tap a syllable and press play to hear it. The eye button hides the English readings, so the marks can be practiced from the Arabic alone."),
               place: InterfaceText("Islam tab, Arabic Alphabet"), destination: .islamPage(.alphabet), tour: true, beginner: true),
        AppTip(id: "islam.letterfamilies", area: .islam, group: InterfaceText("LEARNING"), systemImage: "wind",
               title: InterfaceText("Group the alphabet by tajweed"),
               detail: InterfaceText("The button beside the alphabet's search regroups the letters by where they are made, by a quality such as whistling (safeer) or breath (hams), or by the rule they trigger after a noon sakinah. Every family is named in Arabic and English, and a chip above the letters narrows the alphabet to one family."),
               place: InterfaceText("Islam tab, Arabic Alphabet")),
        AppTip(id: "islam.letterprofile", area: .islam, group: InterfaceText("LEARNING"), systemImage: "mouth",
               title: InterfaceText("Every letter's tajweed profile"),
               detail: InterfaceText("A letter's page lists where it is made, the qualities it is said with, and the rule it triggers after a noon sakinah, a meem sakinah and the definite article, each with an example from the Quran. The arrows beside the size slider step to the next letter without going back."),
               place: InterfaceText("Islam tab, Arabic Alphabet")),
        AppTip(id: "islam.letterquiz", area: .islam, group: InterfaceText("LEARNING"), systemImage: "checkmark.circle",
               title: InterfaceText("Sound-alike letters and a quiz"),
               detail: InterfaceText("Explore, at the top of the alphabet, opens the pairs people mix up side by side with what separates them, and a ten-question quiz: name a letter, read a joined form, place a letter in its family, or pick the letter you hear."),
               place: InterfaceText("Islam tab, Arabic Alphabet")),
        AppTip(id: "islam.readingtest", area: .islam, group: InterfaceText("LEARNING"), systemImage: "text.book.closed.fill",
               title: InterfaceText("A reading test, tier by tier"),
               detail: InterfaceText("Reading Test, under Explore at the top of the alphabet, climbs 21 tiers in the order a qaa'idah teaches reading: single letters, short vowels, long vowels, sukoon and shaddah, the marks of the mushaf, and last of all words printed with no tashkeel. Each tier tests reading, spelling and listening. The hint spaces a word out letter by letter, and Find My Level picks the tier to start on."),
               place: InterfaceText("Islam tab, Arabic Alphabet")),
        // The lessons ship with the Quran domain (the tab shows the course only when
        // `TajweedLessonsStore.isBundled`) and play their ayahs in your reciter: Al-Adhan has neither.
        AppTip(id: "islam.course", area: .islam, group: InterfaceText("LEARNING"), systemImage: "graduationcap.fill",
               title: InterfaceText("A tajweed course with quizzes"),
               detail: InterfaceText("The Tajweed Course runs from reading the letters to reading the mushaf. Each lesson gives the rule, its letters (tap one for its page), words to read aloud, example ayahs played in your own reciter, and a Check Yourself quiz. Mark lessons done, step through with the arrows at the top, and Continue picks up where you left off. Tajweed Foundations, beside it, keeps every rule on a page of its own to look up."),
               place: InterfaceText("Islam tab, Tajweed Course"), isAvailable: { shipsQuran }),
        AppTip(id: "islam.names", area: .islam, group: InterfaceText("LEARNING"), systemImage: "signature",
               title: InterfaceText("A Name, full screen"),
               detail: InterfaceText("Tap a Name of Allah in the grid, or choose View Fullscreen from any row's menu, to fill the screen with it. Tap a name's number badge to favorite it, and the shuffle in the header to land on one at random."),
               place: InterfaceText("Islam tab, 99 Names of Allah"), tour: true, isAvailable: TipCatalog.outsideSimpleMode),
        AppTip(id: "islam.diagrams", area: .islam, group: InterfaceText("LEARNING"), systemImage: "arrow.up.left.and.arrow.down.right",
               title: InterfaceText("Tap any diagram"),
               detail: InterfaceText("The charts and photographs in the articles open full screen with a tap. Pinch to zoom, drag to move around, and tap twice to fit."),
               place: InterfaceText("Islam tab, articles")),
        AppTip(id: "islam.articles", area: .islam, group: InterfaceText("LEARNING"), systemImage: "doc.text.magnifyingglass",
               title: InterfaceText("Find within an article"),
               detail: InterfaceText("An article's search bar searches that article and scrolls to the match. Drag across any paragraph to select and copy part of it, and a touch and hold on a quotation copies it with its citation."),
               place: InterfaceText("Islam tab, articles"), tour: true),
        AppTip(id: "islam.askai", area: .islam, group: InterfaceText("LEARNING"), systemImage: "sparkles",
               title: InterfaceText("Ask AI, with its sources"),
               detail: InterfaceText { "Ask AI answers from \(askAISources[$0]), on your device. Every citation opens its source, and wording it could not verify is marked as such." },
               place: InterfaceText("Islam tab, Ask AI"), isAvailable: { hasAppleIntelligence }),

        AppTip(id: "islam.favorites", area: .islam, group: InterfaceText("THE ISLAM TAB"), systemImage: "star.fill",
               title: InterfaceText("Favorite a resource"),
               detail: InterfaceText("Swipe a resource right, tap the star in its tile's corner, or touch and hold the tile. Favorites gather in a section of their own at the top."),
               place: InterfaceText("Islam tab")),
        AppTip(id: "islam.reminder", area: .islam, group: InterfaceText("THE ISLAM TAB"), systemImage: "bookmark.fill",
               title: InterfaceText("Keep a Reminder of the Day"),
               detail: InterfaceText("Save keeps a Reminder of the Day, with its source, in Saved Reflections. The Today pill gathers the ayah, word, hadith, dua, and reminder of the day on one screen."),
               place: InterfaceText("Islam tab")),
        // Fajr comes from the app's own prayer calculation: Al-Quran has none, and its day turns
        // over at midnight whatever the switch says (`Settings.dailyFajr`).
        AppTip(id: "islam.fajr", area: .islam, group: InterfaceText("THE ISLAM TAB"), systemImage: "sunrise.fill",
               title: InterfaceText("Days that begin at Fajr"),
               detail: InterfaceText("Turn Over at Fajr changes every daily feature at Fajr rather than at midnight, so the day begins with the prayer."),
               place: InterfaceText("Islam Settings, Libraries"), destination: .islamPage(.libraries), card: (InterfaceText("Days Begin at Fajr"), InterfaceText("Every daily feature turns over with the prayer, not at midnight.")), isAvailable: { shipsPrayerTimes }),
        AppTip(id: "islam.font", area: .islam, group: InterfaceText("THE ISLAM TAB"), systemImage: "textformat.ar",
               title: InterfaceText("One Arabic font for everything else"),
               detail: islamFontDetail,
               place: InterfaceText("Islam Settings, Arabic Text"), destination: .islamPage(.arabicText)),

        AppTip(id: "islam.zakah", area: .islam, group: InterfaceText("CALCULATORS AND TOOLS"), systemImage: "percent",
               title: InterfaceText("Zakah, on either calendar"),
               detail: InterfaceText("The Zakah Calculator works on a lunar year at 2.5% or a solar year at 2.577%. The small information buttons beside its fields open the scholarly detail behind each rule, and a touch and hold on the result copies it."),
               place: InterfaceText("Islam tab, Zakah Calculator")),
        AppTip(id: "islam.inheritance", area: .islam, group: InterfaceText("CALCULATORS AND TOOLS"), systemImage: "divide.circle.fill",
               title: InterfaceText("Inheritance, exactly"),
               detail: InterfaceText("The Inheritance Calculator works in exact fractions, applies \u{2018}awl and radd where the shares call for them, and names each relative who is present but does not inherit, with the reason."),
               place: InterfaceText("Islam tab, Inheritance Calculator")),
        AppTip(id: "islam.journal", area: .islam, group: InterfaceText("CALCULATORS AND TOOLS"), systemImage: "square.and.pencil",
               title: journalTitle,
               detail: journalDetail,
               place: InterfaceText("Islam tab, Islamic Journal")),
        AppTip(id: "islam.converter", area: .islam, group: InterfaceText("CALCULATORS AND TOOLS"), systemImage: "calendar",
               title: InterfaceText("Copy a converted date"),
               detail: InterfaceText("In the Hijri Date Converter, touch and hold either date to copy it."),
               place: InterfaceText("Islam tab, Hijri Date Converter")),
        AppTip(id: "islam.locators", area: .islam, group: InterfaceText("CALCULATORS AND TOOLS"), systemImage: "mappin.and.ellipse",
               title: InterfaceText("Mosques and halal food around you"),
               detail: InterfaceText("The Masjid Locator and the Halal Food Locator search near you, or wherever you move the map with Search This Area. Tap a result for directions in Maps, and touch and hold it to copy its name or address."),
               place: InterfaceText("Islam tab, Masjid Locator and Halal Food Locator")),
        AppTip(id: "islam.wallpapers", area: .islam, group: InterfaceText("CALCULATORS AND TOOLS"), systemImage: "photo.on.rectangle",
               title: InterfaceText("Save a wallpaper"),
               detail: InterfaceText("Touch and hold a wallpaper for Save to Photos and Copy Image."),
               place: InterfaceText("Islam tab, Islamic Wallpapers")),
    ]

    // MARK: The app

    private static let general: [AppTip] = generalLead + backupTips + generalTrail

    // Tips about the whole app that name a tab: each app names only its own.

    /// Both screens are prayer-times features, so the tip ships only where they do (`shipsPrayerTimes`).
    private static var advancedDetail: InterfaceText {
        InterfaceText("Two settings screens keep their fine-tuning behind Show Advanced Settings, at their foot: Prayer Calculation (custom angles, the high latitude rule) and Nagging Mode (how often it repeats, the last calls, its tone). Each has its own switch; every other screen shows everything it has. A search result or a tip marked Advanced turns the switch on for you.")
    }

    /// At a Glance is the Adhan tab's.
    private static var simpleModeDetail: InterfaceText {
        #if HAS_ADHAN
        let extras = InterfaceText("extras like Need a Hand? and At a Glance step aside")
        #else
        let extras = InterfaceText("extras like Need a Hand? step aside")
        #endif
        return InterfaceText { "Simple Mode keeps each tab to its essentials. Shortcuts move into a ⋯ menu at the top of the tab or into Settings, and \(extras[$0]). Nothing is turned off, and turning it back off brings everything back. What Moves Where, on the Simple Mode page, lists every shortcut and where it went." }
    }

    /// The tabs with a NEED A HAND? section (`HelpDoorsSection`), in tab-bar order.
    private static var helpDoorsPlace: InterfaceText {
        #if HAS_ADHAN && HAS_QURAN && HAS_HADITH
        return InterfaceText("Adhan, Quran, Hadith and Islam tabs")
        #elseif HAS_ADHAN && HAS_QURAN
        return InterfaceText("Adhan, Quran and Islam tabs")
        #elseif HAS_ADHAN
        return InterfaceText("Adhan and Islam tabs")
        #elseif HAS_QURAN
        return InterfaceText("Quran and Islam tabs")
        #else
        return InterfaceText("Islam tab")
        #endif
    }

    private static var helpDoorsDetail: InterfaceText {
        #if HAS_ADHAN && HAS_QURAN && HAS_HADITH
        let examples = InterfaceText("Need Help Praying? on the prayer times opens Nagging Mode, Need Help Reading? on the Quran answers with Arabic Beginner Mode, and Reading in One Language? on the hadith picks the Arabic, the English or both.")
        #elseif HAS_ADHAN
        let examples = InterfaceText("Need Help Praying? on the prayer times opens Nagging Mode.")
        #elseif HAS_QURAN
        let examples = InterfaceText("Need Help Reading? on the Quran answers with Arabic Beginner Mode.")
        #else
        let examples = InterfaceText(display: "", english: "")
        #endif
        return InterfaceText.joined([
            InterfaceText("Each tab keeps a Need a Hand? section: a few questions, each with the setting that answers it."),
            examples,
            InterfaceText("Hold a question for a quick switch, tap the arrow beside the header to fold them away, and use each tab's settings page (or Show on Every Tab, in Look and Feel) to hide them."),
        ], separator: " ")
    }

    /// The tabs whose ⋯ menu answers a hold (`TabMoreMenu(hold:)`); the Adhan tab's does not. A hold and
    /// not a double tap since 2026-10-26: the double tap made every plain tap wait (see `ShortcutMenu`).
    private static var menuShortcutDetail: InterfaceText {
        #if HAS_QURAN && HAS_HADITH
        let tabs = InterfaceText("the Quran, Hadith, Islam, and Settings tabs")
        #elseif HAS_QURAN
        let tabs = InterfaceText("the Quran, Islam, and Settings tabs")
        #else
        let tabs = InterfaceText("the Islam and Settings tabs")
        #endif
        return InterfaceText { "Touch and hold the ⋯ menu at the top of \(tabs[$0]) to switch between the grid and the list without opening it. A single tap opens the whole menu at once." }
    }

    private static let generalLead: [AppTip] = [
        AppTip(id: "app.advanced", area: .app, group: InterfaceText("FINDING THINGS"), systemImage: "slider.horizontal.3",
               title: InterfaceText("Simple until you ask for more"),
               detail: advancedDetail,
               place: InterfaceText("Prayer Calculation and Nagging Mode"), isAvailable: { shipsPrayerTimes }),

        AppTip(id: "app.simple", area: .app, group: InterfaceText("FINDING THINGS"), systemImage: "rectangle.compress.vertical",
               title: InterfaceText("Too much on screen? Simple Mode"),
               detail: simpleModeDetail,
               place: InterfaceText("Settings tab, under the settings"), destination: .simpleMode, beginner: true),

        AppTip(id: "app.search", area: .app, group: InterfaceText("FINDING THINGS"), systemImage: "magnifyingglass",
               title: InterfaceText("Search every setting"),
               detail: InterfaceText("The search bar at the foot of Settings finds any setting, and matches by meaning too: try \u{201C}make text bigger\u{201D}. Every settings page has a search bar of its own as well."),
               place: InterfaceText("Settings tab"), tour: true),
        AppTip(id: "app.headers", area: .app, group: InterfaceText("FINDING THINGS"), systemImage: "shuffle",
               title: InterfaceText("Headers that do things"),
               detail: InterfaceText("Section headers across the app carry small controls: a shuffle that opens something at random, and a chevron that folds the section away."),
               place: InterfaceText("Everywhere"), tour: true, isAvailable: TipCatalog.outsideSimpleMode),
        AppTip(id: "app.hold", area: .app, group: InterfaceText("FINDING THINGS"), systemImage: "hand.tap.fill",
               title: InterfaceText("Touch and hold is worth trying"),
               detail: InterfaceText("Most rows, cards, tiles, and images answer a touch and hold with a menu: Copy, Share, Favorite, View Fullscreen, or Scroll To."),
               place: InterfaceText("Everywhere"), tour: true),
        AppTip(id: "app.menushortcuts", area: .app, group: InterfaceText("FINDING THINGS"), systemImage: "ellipsis.circle.fill",
               title: InterfaceText("Hold the ⋯ menu"),
               detail: menuShortcutDetail,
               place: InterfaceText("The ⋯ menu at the top of a tab"), isAvailable: { hasMenuShortcuts }),
        AppTip(id: "app.bars", area: .app, group: InterfaceText("FINDING THINGS"), systemImage: "rectangle.compress.vertical",
               title: InterfaceText("Bars that get out of the way"),
               detail: InterfaceText("Search bars and players shrink as you scroll down and come back when you scroll up."),
               place: InterfaceText("Everywhere")),

        AppTip(id: "app.progress", area: .app, group: InterfaceText("YOU"), systemImage: "chart.line.uptrend.xyaxis",
               title: InterfaceText("Your Progress"),
               detail: InterfaceText("Your prayers, reading, dhikr, and badges in one place. Streaks forgive one missed day a month, and reading on your Apple Watch counts once it syncs. Tap a badge for what it took to earn."),
               place: InterfaceText("Settings tab, Your Progress"), tour: true),
        AppTip(id: "app.aboutyou", area: .app, group: InterfaceText("YOU"), systemImage: "person.crop.circle.fill",
               title: InterfaceText("Tell the app who you are"),
               detail: InterfaceText("About You remembers whether you grew up Muslim, embraced Islam, are just getting started, or are learning about Islam, and tailors the Start Here guide on the Islam tab. It never leaves your iPhone. Replay the Welcome Tutorial, on the same page, walks the welcome again."),
               place: InterfaceText("Settings tab, About You"), destination: .aboutYou, beginner: true),
    ]

    // iCloud Backup's tips, Al-Islam's alone (`HAS_ICLOUD_BACKUP`; the companion apps never receive the
    // backup). Their own list, between About You and Reset, where they always stood.
    #if HAS_ICLOUD_BACKUP
    private static let backupTips: [AppTip] = [
        AppTip(id: "app.icloud", area: .app, group: InterfaceText("YOU"), systemImage: "icloud.fill",
               title: InterfaceText("Back up to your own iCloud"),
               detail: InterfaceText("iCloud Backup keeps your bookmarks, prayer tracker, khatm, tasbih counts, journal and settings in your private iCloud. Up to six people or devices on one account each get a profile of their own, and a new iPhone can restore any of them, replacing what is there or merging with it. Your location is never included."),
               place: InterfaceText("Settings tab, iCloud Backup"), destination: .cloudBackup),
        AppTip(id: "app.icloudIncluded", area: .app, group: InterfaceText("YOU"), systemImage: "list.bullet.rectangle.fill",
               title: InterfaceText("See exactly what a backup holds"),
               detail: InterfaceText("What's Included, on the iCloud Backup page, lists every kind of thing a backup of this iPhone carries right now, with counts and the size, and everything a backup never includes. Every restore shows the same categories side by side, here against the backup, before you choose Replace or Merge."),
               place: InterfaceText("Settings tab, iCloud Backup, What's Included"), destination: .cloudBackup),
        AppTip(id: "app.backupFile", area: .app, group: InterfaceText("YOU"), systemImage: "square.and.arrow.up",
               title: InterfaceText("Keep a backup as a file"),
               detail: InterfaceText("Export a Backup File writes the same backup to a file you keep yourself: AirDrop it to a family member's iPhone or save it in Files. Restore from a File reads one back. No iCloud needed on either side."),
               place: InterfaceText("Settings tab, iCloud Backup, Backup File"), destination: .cloudBackup),
    ]
    #else
    private static let backupTips: [AppTip] = []
    #endif

    /// Reset's tip names the iCloud claim a keep-content reset spares only where there is one.
    private static var resetTipDetail: InterfaceText {
        #if HAS_ICLOUD_BACKUP
        return InterfaceText("Reset All Settings offers two choices: put every option back and keep your bookmarks, favorites, progress and this iPhone's iCloud Backup, or erase everything. Both say exactly what they keep and what they remove.")
        #else
        return InterfaceText("Reset All Settings offers two choices: put every option back and keep your bookmarks, favorites and progress, or erase everything. Both say exactly what they keep and what they remove.")
        #endif
    }

    private static let generalTrail: [AppTip] = [
        AppTip(id: "app.reset", area: .app, group: InterfaceText("YOU"), systemImage: "arrow.counterclockwise",
               title: InterfaceText("Reset without losing anything"),
               detail: resetTipDetail,
               place: InterfaceText("Settings tab")),

        AppTip(id: "app.themes", area: .app, group: InterfaceText("HOW IT LOOKS"), systemImage: "paintpalette.fill",
               title: InterfaceText("Reading themes"),
               detail: InterfaceText("Beyond light and dark there are Gray and Sepia themes, and under Custom Colors a background color of your own, with any accent color to match."),
               place: InterfaceText("Settings tab, Appearance"), destination: .appearance, card: (InterfaceText("Reading Themes"), InterfaceText("Gray, Sepia, or a background color of your own."))),
        AppTip(id: "app.classic", area: .app, group: InterfaceText("HOW IT LOOKS"), systemImage: "square.on.square",
               title: InterfaceText("Show Liquid Glass"),
               detail: InterfaceText("Turn Show Liquid Glass off for the Classic Look: a faster app that is easier on the battery, and it can turn itself off in Low Power Mode. The tab bar, navigation bars, sheets, and the search field are drawn by iOS and keep their glass either way."),
               place: InterfaceText("Settings tab, Appearance, Look and Feel"), destination: .appearancePage(.lookAndFeel), isAvailable: { hasLiquidGlass }),
        AppTip(id: "app.glow", area: .app, group: InterfaceText("HOW IT LOOKS"), systemImage: "sun.haze.fill",
               title: InterfaceText("The glow at the top"),
               detail: InterfaceText("Top Accent Glow washes the top of each screen in your accent color. Al-Islam Glow paints it yellow and green instead, and turning it off gives a flat background."),
               place: InterfaceText("Settings tab, Appearance, Custom Colors"), destination: .appearancePage(.customColors)),
        AppTip(id: "app.launchtab", area: .app, group: InterfaceText("HOW IT LOOKS"), systemImage: "rectangle.portrait.and.arrow.forward",
               title: InterfaceText("Choose the tab the app opens on"),
               detail: InterfaceText("Open the App On picks where the app lands: Adhan, Quran, Hadith, or Islam. A notification or a reminder you tap still opens where it points."),
               place: InterfaceText("Settings tab, Appearance, Look and Feel"), destination: .appearancePage(.lookAndFeel), isAvailable: { LaunchTab.isOffered }),
        AppTip(id: "app.helpdoors", area: .app, group: InterfaceText("HOW IT LOOKS"), systemImage: "questionmark.circle.fill",
               title: InterfaceText("A question on every tab"),
               detail: helpDoorsDetail,
               place: helpDoorsPlace, destination: .appearancePage(.lookAndFeel), beginner: true, isAvailable: TipCatalog.outsideSimpleMode),
    ]
}

// MARK: - The door on each settings page

/// "Tips & Tricks", the door on every settings page, with Unique Features and Beginner Features under
/// it since 2026-10-26 (`FeatureList`): the page's own tips, then the two settings lists every page
/// shares. `resolve` is the page's own search resolver, so a tip or a feature that opens one of that
/// page's screens pushes it directly instead of a second page root.
struct TipsSection: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    let area: TipArea
    var resolve: (SettingsSearchEntry.Destination) -> AnyView? = { _ in nil }

    var body: some View {
        Section(header: Text("DISCOVER")) {
            NavigationLink(destination: LazyDestination { TipsView(area: area, resolve: resolve) }) {
                SettingsRowLabel(title: String(localized: "Tips & Tricks"), systemImage: "lightbulb.fill",
                                 subtitle: String(localized: "\(TipCatalog.tips(in: area).count) things that are easy to miss"),
                                 tint: area.tint, secondaryTint: area.secondaryTint)
            }
            .tint(settings.accentColor.color)

            // The lists span every area, so their chips wear the Settings tab's own colour, as the
            // root's All Tips & Tricks row does.
            ForEach(FeatureList.allCases) { list in
                NavigationLink(destination: LazyDestination { FeatureListView(list: list, resolve: resolve) }) {
                    SettingsRowLabel(title: list.title, systemImage: list.systemImage, subtitle: list.caption,
                                     tint: SettingsTint.appearance)
                }
                .tint(settings.accentColor.color)
            }
        }
        // Simple Mode keeps one door to the tips, the All Tips & Tricks row on the Settings tab, and
        // drops the two lists the way it drops the root's ONLY IN AL-ISLAM cards: every setting in
        // them is still on its own page and in the search.
        .hiddenInSimple(.pageTipsRows)
    }
}

// MARK: - Unique Features and Beginner Features

/// One of the two feature lists (`FeatureList`): a plain settings list, every row a `SettingsRowLabel`
/// that opens the setting it names, in sections by the settings page that owns it. `resolve` is the
/// opening page's own resolver, as `TipsView` takes it.
struct FeatureListView: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    let list: FeatureList
    var resolve: (SettingsSearchEntry.Destination) -> AnyView? = { _ in nil }

    var body: some View {
        let groups = TipCatalog.areaGroups(list.tips)
        List {
            Group {
                ForEach(groups, id: \.area.id) { group in
                    Section(header: Text(group.area.title.uppercased())) {
                        ForEach(group.tips) { tip in
                            row(for: tip)
                        }
                    }
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .compactListSectionSpacing()
        .navigationTitle(list.title)
    }

    /// The card's short title where the tip has one (the tip's own is written for a list row with room
    /// to wrap), the place it is done as the caption, exactly the root's fallback rows.
    @ViewBuilder
    private func row(for tip: AppTip) -> some View {
        if let destination = tip.destination {
            NavigationLink(destination: LazyDestination {
                Group {
                    if let own = resolve(destination) {
                        own
                    } else {
                        AnyView(SettingsSearchDestinationView.view(for: destination))
                    }
                }
                .revealsAdvancedSettings(tip.advanced)
            }) {
                SettingsRowLabel(title: tip.card?.title ?? tip.title, systemImage: tip.systemImage,
                                 subtitle: tip.place,
                                 tint: tip.area.tint, secondaryTint: tip.area.secondaryTint)
            }
            .tint(settings.accentColor.color)
        }
    }
}

// MARK: - The list

struct TipsView: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    let area: TipArea
    var resolve: (SettingsSearchEntry.Destination) -> AnyView? = { _ in nil }

    @State private var query = ""
    @State private var barsCollapsed = false
    @State private var showTour = false

    private var trimmedQuery: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        let groups = TipCatalog.groups(in: area, matching: trimmedQuery)
        List {
            Group {
                if trimmedQuery.isEmpty, !TipCatalog.tour(in: area).isEmpty {
                    Section {
                        tourRow
                    }
                }

                if groups.isEmpty {
                    Section {
                        Text("No tip here matches. Each settings page keeps its own list.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                ForEach(groups, id: \.title) { group in
                    Section(header: Text(group.title)) {
                        ForEach(group.tips) { tip in
                            row(for: tip)
                        }
                    }
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .compactListSectionSpacing()
        .collapseBarsOnScroll($barsCollapsed)
        .dismissKeyboardOnScroll()
        .adaptiveSafeArea(edge: .bottom) {
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                SearchBar(text: AppPerformance.shouldReduceAnimations ? $query : $query.animation(.easeInOut),
                          placeholder: String(localized: "Search these tips"))
                    .minimizedBarStyle(barsCollapsed)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: barsCollapsed)
            .padding(.horizontal, 24)
            .padding(.bottom, BottomBarCushion.standard)
            .background(Color.white.opacity(0.00001))
        }
        .navigationTitle(area.listTitle)
        .sheet(isPresented: $showTour) {
            TipsTourView(area: area)
                .smallMediumSheetPresentation()
        }
        #if DEBUG
        // "-tipsTour": open the tour a moment after the list appears (a sheet cannot be tapped open
        // from a script without idb).
        .onAppear {
            guard ProcessInfo.processInfo.arguments.contains("-tipsTour") else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { showTour = true }
        }
        #endif
    }

    private var tourRow: some View {
        Button {
            settings.hapticFeedback()
            showTour = true
        } label: {
            HStack(spacing: 12) {
                AccentIconChip(systemImage: "play.fill", tint: area.tint, secondaryTint: area.secondaryTint, size: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Take the Tour")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("The \(TipCatalog.tour(in: area).count) worth knowing first, one at a time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.forward")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// A tip about a setting opens that setting; every other tip is plain text. ONE link per row,
    /// the row itself (two links in one List row both fire on any tap).
    @ViewBuilder
    private func row(for tip: AppTip) -> some View {
        if let destination = tip.destination {
            NavigationLink(destination: LazyDestination {
                Group {
                    if let own = resolve(destination) {
                        own
                    } else {
                        AnyView(SettingsSearchDestinationView.view(for: destination))
                    }
                }
                .revealsAdvancedSettings(tip.advanced)
            }) {
                TipRow(tip: tip)
            }
            .tint(settings.accentColor.color)
        } else {
            TipRow(tip: tip)
        }
    }
}

struct TipRow: View {
    @Environment(\.appearance) private var appearance

    let tip: AppTip

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AccentIconChip(systemImage: tip.systemImage, tint: tip.area.tint, secondaryTint: tip.area.secondaryTint)

            VStack(alignment: .leading, spacing: 3) {
                Text(tip.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(tip.detail.localizedDigits)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                // HStacks, not Labels: inside a List a Label's icon takes the row's full icon column,
                // which left a 30 pt gap between a 10 pt pin and its text.
                caption(tip.place, systemImage: "mappin.and.ellipse",
                        color: tip.destination == nil ? appearance.accent : .secondary)
                    .padding(.top, 1)

                if tip.destination != nil {
                    caption(tip.advanced ? String(localized: "Opens the setting (Advanced Settings)") : String(localized: "Opens the setting"),
                            systemImage: "gearshape.fill", color: appearance.accent)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func caption(_ text: String, systemImage: String, color: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Image(systemName: systemImage)
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.caption2.weight(.medium))
        .foregroundColor(color)
    }
}

// MARK: - The tour

/// The tutorial: an area's `tour` tips as cards to swipe through, one idea to a card.
struct TipsTourView: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @Environment(\.dismiss) private var dismiss

    let area: TipArea
    /// A hand-picked set in place of the area's own cards (the welcome's tour passes the spotlight tips,
    /// WelcomePages.swift).
    var tips: [AppTip]? = nil
    /// A title of its own, when the cards are not one area's ("Only in Al-Islam").
    var title: String? = nil

    @State private var page = 0

    private var cards: [AppTip] { tips ?? TipCatalog.tour(in: area) }

    var body: some View {
        SheetNavigationContainer {
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(cards.enumerated()), id: \.element.id) { index, tip in
                        TipTourCard(tip: tip, index: index, count: cards.count)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                footer
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
            .navigationTitle(title ?? area.tourTitle)
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
        }
    }

    private var footer: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                ForEach(cards.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? settings.accentColor.color : Color.secondary.opacity(0.3))
                        .frame(width: index == page ? 18 : 6, height: 6)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: page)
            .accessibilityHidden(true)

            Button {
                settings.hapticFeedback()
                if page < cards.count - 1 {
                    withAnimation(.easeInOut) { page += 1 }
                } else {
                    dismiss()
                }
            } label: {
                Text(page < cards.count - 1 ? String(localized: "Next") : String(localized: "Finish"))
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .conditionalGlassEffect(rectangle: true, useColor: 0.38, customTint: settings.accentColor.color)
        }
    }
}

private struct TipTourCard: View {
    @Environment(\.appearance) private var appearance

    let tip: AppTip
    let index: Int
    let count: Int

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                AccentIconChip(systemImage: tip.systemImage, tint: tip.area.tint,
                               secondaryTint: tip.area.secondaryTint, size: 92)
                    .padding(.top, 28)

                Text("\(index + 1) of \(count)")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)

                Text(tip.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(tip.detail.localizedDigits)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Label(tip.place, systemImage: "mappin.and.ellipse")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(appearance.accent)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 12)
                    .background(Capsule().fill(appearance.accent.opacity(0.12)))
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Every area, from the Settings tab

/// "All Tips & Tricks": the six lists behind one door, for the Settings tab's own root.
struct TipsHubView: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @State private var query = ""
    @State private var barsCollapsed = false

    private var trimmedQuery: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        // Searching the hub looks inside all six areas at once (`TipCatalog.areaMatches`): this screen
        // is the door everyone arrives at from the Settings tab, and a half-remembered tip should not
        // need you to guess which page owns it first. With the field empty the hub is unchanged - the
        // six area rows, as before.
        let matches = TipCatalog.areaMatches(matching: trimmedQuery)
        List {
            Group {
                if trimmedQuery.isEmpty {
                    Section(footer: Text("Each settings page opens with its own list too, and every list has a tour.")) {
                        ForEach(TipArea.offered) { area in
                            NavigationLink(destination: LazyDestination { TipsView(area: area) }) {
                                SettingsRowLabel(title: area.title, systemImage: area.systemImage,
                                                 subtitle: TipCatalog.tips(in: area).first?.title,
                                                 tint: area.tint, secondaryTint: area.secondaryTint,
                                                 value: "\(TipCatalog.tips(in: area).count)".localizedDigits)
                            }
                            .tint(settings.accentColor.color)
                        }
                    }
                } else if matches.isEmpty {
                    Section {
                        Text("No tip matches. Try a word from what you are looking for, like \(TipCatalog.searchHint).")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    // A section per area, so a result always says WHICH settings page it belongs to -
                    // the header is the only thing that places it, since the rows come from all six.
                    ForEach(matches, id: \.area.id) { match in
                        Section(header: Text(match.area.title.uppercased())) {
                            ForEach(match.tips) { tip in
                                TipRow(tip: tip)
                            }
                        }
                    }
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .compactListSectionSpacing()
        .collapseBarsOnScroll($barsCollapsed)
        .dismissKeyboardOnScroll()
        .adaptiveSafeArea(edge: .bottom) {
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                SearchBar(text: AppPerformance.shouldReduceAnimations ? $query : $query.animation(.easeInOut),
                          placeholder: String(localized: "Search every tip"))
                    .minimizedBarStyle(barsCollapsed)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: barsCollapsed)
            .padding(.horizontal, 24)
            .padding(.bottom, BottomBarCushion.standard)
            .background(Color.white.opacity(0.00001))
        }
        .navigationTitle("Tips & Tricks")
    }
}

// MARK: - Front and center: the Settings tab's featured settings

/// The app's unusual SETTINGS, as cards at the top of the Settings tab, each opening the screen that
/// owns it. These were the hardest things in the app to find: Nagging Mode sat three pushes deep, the
/// tracker's pause lives on a history page, Highlight Themes behind a row named MORE.
///
/// The cards are Buttons feeding ONE destination, never a link apiece: several NavigationLinks inside
/// one List row all fire on any tap (see `one-link-per-list-row`). On iPhone that is a `pushDestination`
/// on the list; in the iPad/Mac sidebar, where a push would land inside the narrow column, it is the
/// split's detail column (`SettingsDestination.spotlight`). Only iOS 15, which has neither, takes
/// `rows: true`: the same tips as ordinary rows.
struct SettingsSpotlightSection: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    /// True for the fallback shape: one settings row per tip.
    let rows: Bool
    /// The card whose screen fills the iPad/Mac detail column. It wears the ring every sidebar grid
    /// marks its open tile with (`gridSelectionRing`), since the hub rows drop their highlight then.
    var selectedTipID: String? = nil
    /// Opens a card: the iPhone push (`SettingsView.spotlightTarget`) or the split's detail column.
    var open: (AppTip) -> Void = { _ in }

    var body: some View {
        let tips = TipCatalog.spotlight
        // Simple Mode keeps the one row to every tip and leaves the thirteen cards out
        // (Docs/Product/Simple Mode Guide.md).
        Section(header: SectionIconHeader(settings.hides(.spotlightCards) ? String(localized: "TIPS & TRICKS") : String(localized: "ONLY IN \(AppIdentifiers.displayName.uppercased())"), icon: "lightbulb.fill")) {
            if settings.hides(.spotlightCards) {
                EmptyView()
            } else if rows {
                ForEach(tips) { tip in
                    if let destination = tip.destination {
                        NavigationLink(destination: LazyDestination {
                            SettingsSearchDestinationView.view(for: destination)
                                .revealsAdvancedSettings(tip.advanced)
                        }) {
                            // The card's short title: the tip's own is written for a list row with
                            // room to wrap, and truncated in these rows when the iPad sidebar still
                            // used them ("Traveling mode turns its...").
                            SettingsRowLabel(title: tip.card?.title ?? tip.title, systemImage: tip.systemImage,
                                             subtitle: tip.place,
                                             tint: tip.area.tint, secondaryTint: tip.area.secondaryTint)
                        }
                        .tint(settings.accentColor.color)
                    }
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 10) {
                        ForEach(tips) { tip in
                            Button {
                                settings.hapticFeedback()
                                open(tip)
                            } label: {
                                SpotlightCard(tip: tip)
                                    .gridSelectionRing(tip.id == selectedTipID, cornerRadius: SpotlightCard.cornerRadius)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    // Every card the tallest card's height: they are all 176 pt at the default sizes,
                    // and grow with the text at the accessibility sizes (`SpotlightCard.grows`).
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 2)
                }
                // Edge to edge inside the section's card, so the strip scrolls under its corners
                // instead of stopping short of them.
                .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
            }

            NavigationLink(destination: LazyDestination { TipsHubView() }) {
                SettingsRowLabel(title: String(localized: "All Tips & Tricks"), systemImage: "lightbulb.fill",
                                 subtitle: String(localized: "\(TipCatalog.all.filter { $0.isAvailable() }.count) things that are easy to miss"),
                                 tint: SettingsTint.appearance)
            }
            .tint(settings.accentColor.color)
        }
    }
}

// MARK: - Settings-search entries (kept in THIS file, next to the screens they describe)
extension SettingsSearchEntry {
    private static let tipKeywords = "tips tricks hidden features gestures shortcuts tutorial tour how to help discover easy to miss did you know"

    /// The two feature lists, found by what they are for (a new Muslim, what only this app has).
    static let featureListEntries: [SettingsSearchEntry] = [
        .init(title: "Unique Features", path: "Settings", keywords: tipKeywords + " only in al-islam exclusive special unusual what makes different spotlight cards", destination: .featureList(.unique)),
        .init(title: "Beginner Features", path: "Settings", keywords: tipKeywords + " new muslim convert revert beginner learner learning arabic start here simple mode transliteration", destination: .featureList(.beginner)),
    ]

    static let tipsEntries: [SettingsSearchEntry] = [
        .init(title: "Tips & Tricks", path: "Settings", keywords: tipKeywords, destination: .tips(nil)),
        .init(title: "Prayer Times Tips & Tricks", path: "Prayer Settings", keywords: tipKeywords + " adhan sky qibla tracker control center", destination: .tips(.adhan)),
        .init(title: "Notification Tips & Tricks", path: "Notifications", keywords: tipKeywords + " adhan nagging lock screen", destination: .tips(.notifications)),
        .init(title: "Quran Tips & Tricks", path: "Quran Settings", keywords: tipKeywords + " reader mushaf tajweed word search test mode planner revision history", destination: .tips(.quran)),
        .init(title: "Hadith Tips & Tricks", path: "Hadith Settings", keywords: tipKeywords + " bookmark search reference", destination: .tips(.hadith)),
        .init(title: "Islam Tips & Tricks", path: "Islam Settings", keywords: tipKeywords + " tasbih dua dhikr names alphabet masjid halal", destination: .tips(.islam)),
    ].filter { entry in
        // An area this app compiles out has no list to open (`TipArea.offered`).
        guard case .tips(let area?) = entry.destination else { return true }
        return TipArea.offered.contains(area)
    }
}

private struct SpotlightCard: View {
    /// The card's own curve, which a selection ring drawn on it must follow.
    static let cornerRadius: CGFloat = 18

    let tip: AppTip

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .subheadline) private var scaledWidth: CGFloat = 164

    /// At the accessibility sizes the fixed 164 x 176 card cut every title and pitch ("Auto
    /// Travelin...", "Asks "Did..."), so the card widens with the text (short of the screen, so the
    /// next one still peeks in) and grows to fit it; the strip evens the heights out.
    private var grows: Bool { dynamicTypeSize.isAccessibilitySize }

    var body: some View {
        let tint = tip.area.tint
        // Islam wears both of Al-Islam's colours (`TipArea.secondaryTint`), yellow into green, on the
        // card as on its chip: at one strength corner to corner, since the one-colour fade left the
        // green end at 0.07 and the edge plain yellow, so the card read as a Prayer Times card.
        let wash: [Color] = tip.area.secondaryTint.map { [tint.opacity(0.15), $0.opacity(0.15)] }
            ?? [tint.opacity(0.16), tint.opacity(0.07)]
        let edge: [Color] = tip.area.secondaryTint.map { [tint.opacity(0.4), $0.opacity(0.4)] }
            ?? [tint.opacity(0.28), tint.opacity(0.28)]
        VStack(alignment: .leading, spacing: 8) {
            AccentIconChip(systemImage: tip.systemImage, tint: tint,
                           secondaryTint: tip.area.secondaryTint, size: 34)

            Text(tip.card?.title ?? tip.title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
                .lineLimit(grows ? nil : 2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Text((tip.card?.pitch ?? tip.detail).localizedDigits)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(grows ? nil : 4)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: grows)

            Spacer(minLength: 0)

            HStack(spacing: 3) {
                Text(tip.area.title)
                Image(systemName: "chevron.forward")
                    .font(.caption2.weight(.bold))
            }
            .font(.caption2.weight(.semibold))
            .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(width: grows ? min(scaledWidth, 280) : 164, height: grows ? nil : 176, alignment: .topLeading)
        .frame(maxHeight: grows ? .infinity : nil, alignment: .top)
        // The area's own colour as a wash, not glass: the cards sit on a list row, where clear glass
        // has nothing behind it to bend and showed no surface at all in the light themes.
        .background(
            RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                .fill(LinearGradient(colors: wash, startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                .strokeBorder(LinearGradient(colors: edge, startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
    }
}
#endif
