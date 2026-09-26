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
// 2026-09-20). A tip that describes something the app does not do is worse than no tip, so: when a
// feature's labels or gestures change, change its tip in the same commit, and never add one from
// memory. Things the app does NOT have, which a tip must therefore never promise: a sleep timer, a
// playback speed control, a hadith page mode, a narrator search, favorites or counters on individual
// duas, Hadith or Islam widgets and Siri shortcuts, and an .ics export of prayer times.
//
// No em dashes and no spaced hyphens in any of this text (house rule); quoted labels are the app's own.

// MARK: - Model

/// The settings page a tip belongs to, which is also the list it appears in.
enum TipArea: String, CaseIterable, Identifiable {
    case adhan, notifications, quran, hadith, islam, app

    var id: String { rawValue }

    var title: String {
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
        case .adhan: return "Prayer Times Tips"
        case .notifications: return "Notification Tips"
        case .quran: return "Quran Tips"
        case .hadith: return "Hadith Tips"
        case .islam: return "Islam Tips"
        case .app: return "App Tips"
        }
    }

    var tourTitle: String {
        switch self {
        case .adhan: return "Prayer Times Tour"
        case .notifications: return "Notifications Tour"
        case .quran: return "Quran Tour"
        case .hadith: return "Hadith Tour"
        case .islam: return "Islam Tour"
        case .app: return "App Tour"
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
    /// False where the device cannot do it (Apple Intelligence, an OS version), so nobody is told
    /// about a control they do not have.
    var isAvailable: () -> Bool = { true }

    fileprivate var searchBlob: String {
        "\(title) \(detail) \(place) \(group)".folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}

// MARK: - The catalogue

enum TipCatalog {
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
        return order.map { ($0, byGroup[$0] ?? []) }
    }

    static func tour(in area: TipArea) -> [AppTip] {
        tips(in: area).filter(\.tour)
    }

    /// The Settings tab's cards, in the order they are worth meeting: the mode nobody else has first.
    private static let spotlightOrder = [
        "notif.nagging", "adhan.travel", "quran.wordtap", "adhan.menses", "quran.tajweedcolors",
        "quran.themes", "notif.sunnah", "quran.compare", "adhan.names", "adhan.skycolors",
        "islam.fajr", "app.themes",
    ]

    static var spotlight: [AppTip] {
        let cards = Dictionary(uniqueKeysWithValues: all.filter { $0.spotlight && $0.isAvailable() }.map { ($0.id, $0) })
        return spotlightOrder.compactMap { cards[$0] }
    }

    private static let app = AppIdentifiers.appName
    private static var hasAppleIntelligence: Bool { OnDeviceAsk.isAvailable }
    private static var hasLiquidGlass: Bool {
        if #available(iOS 26.0, *) { return true }
        return false
    }
    private static var hasSiriShortcuts: Bool {
        if #available(iOS 16.0, *) { return true }
        return false
    }
    private static var hasLiveActivities: Bool {
        if #available(iOS 16.2, *) { return true }
        return false
    }

    static let all: [AppTip] = adhan + notifications + quran + hadith + islam + general

    // MARK: Prayer times

    private static let adhan: [AppTip] = [
        AppTip(id: "adhan.scrub", area: .adhan, group: "THE SKY", systemImage: "sun.max.fill",
               title: "Drag the sun through the day",
               detail: "On the sky card, drag the sun along its arc (at night, the moon). The sky recolors, a readout names the prayer and the time at that moment, and the prayer list follows along. Let go and it returns to now.",
               place: "Adhan tab, with Show Sky on", destination: .prayerPage(.sky), tour: true),
        AppTip(id: "adhan.moon", area: .adhan, group: "THE SKY", systemImage: "moonphase.waxing.gibbous",
               title: "The moon is tonight's moon",
               detail: "The moon at the foot of the sky card shows the true phase and how much of it is lit. Pick another day under the prayer list and it shows that night's moon instead.",
               place: "Adhan tab"),
        AppTip(id: "adhan.moon3d", area: .adhan, group: "THE SKY", systemImage: "moon.circle.fill",
               title: "Tap the moon to hold it",
               detail: "Tap the moon at the foot of the sky card (or, with the skyline on, the one riding the arc at night) and it fills the screen as a globe, lit the way it is that night. Drag to turn it, pinch to zoom, double-tap to face Earth, and slide through the month to watch the phases move. Full Light shows the whole face at once.",
               place: "Adhan tab, with Show Sky on"),
        AppTip(id: "adhan.skyline", area: .adhan, group: "THE SKY", systemImage: "building.columns.fill",
               title: "Give the horizon a skyline",
               detail: "Skyline draws pyramids and a mosque along the horizon, in the app and on the Solar Arc and Day & Night widgets. Choose the pair, only pyramids, or only mosques.",
               place: "Prayer Settings, Sky", destination: .prayerPage(.sky)),
        AppTip(id: "adhan.skycolors", area: .adhan, group: "THE SKY", systemImage: "paintpalette.fill",
               title: "Paint your own sky",
               detail: "Sky Colors gives every prayer two colors of its own. Tap a prayer's row to preview it, and Restore Default Colors brings the originals back.",
               place: "Prayer Settings, Sky, Sky Colors", destination: .prayerPage(.skyColors), card: ("Sky Colors", "Two colors of your own for every prayer's sky.")),
        AppTip(id: "adhan.stopadhan", area: .adhan, group: "THE SKY", systemImage: "stop.circle.fill",
               title: "Stop an adhan that is playing",
               detail: "While the adhan sounds inside the app, a capsule that reads \u{201C}Tap to stop\u{201D} appears at the foot of the sky card.",
               place: "Adhan tab"),

        AppTip(id: "adhan.rowdetail", area: .adhan, group: "THE PRAYER LIST", systemImage: "list.bullet.rectangle",
               title: "Tap a prayer for its details",
               detail: "Tap any prayer to unfold its rakah counts, the sunnah prayers around it, and its exact window. Tap again to fold it.",
               place: "Adhan tab", tour: true),
        AppTip(id: "adhan.bell", area: .adhan, group: "THE PRAYER LIST", systemImage: "bell.fill",
               title: "The bell is a three-way switch",
               detail: "Tap the small bell on a prayer to step through prenotification, notification, and off. Touch and hold it to jump straight to the one you want.",
               place: "Adhan tab", tour: true),
        AppTip(id: "adhan.layouts", area: .adhan, group: "THE PRAYER LIST", systemImage: "square.grid.2x2",
               title: "Four layouts for the prayer list",
               detail: "The menu in the PRAYER TIMES header switches between Prayer Tiles, Prayer Grid, Prayer List, and Prayer Split.",
               place: "Adhan tab"),
        AppTip(id: "adhan.optionalpill", area: .adhan, group: "THE PRAYER LIST", systemImage: "moon.stars",
               title: "Optional times without leaving the tab",
               detail: "The Optional Times pill under the prayer list turns on Duhaa, Islamic Midnight, and the Last Third of the Night right there. They show in the app only, never in widgets.",
               place: "Adhan tab", destination: .prayerPage(.optionalPrayers)),
        AppTip(id: "adhan.rakaah", area: .adhan, group: "THE PRAYER LIST", systemImage: "tablecells",
               title: "A rakah table at hand",
               detail: "The Rakaah Guide pill unfolds the fard and sunnah rakahs of every prayer, with what changes on Friday and while traveling.",
               place: "Adhan tab"),
        AppTip(id: "adhan.otherday", area: .adhan, group: "THE PRAYER LIST", systemImage: "calendar",
               title: "Look at any other day",
               detail: "The date picker under the prayer list shows any day's times, and its arrows step a day at a time. Compare Today sets that day beside today's, and Back to Today returns.",
               place: "Adhan tab"),
        AppTip(id: "adhan.pull", area: .adhan, group: "THE PRAYER LIST", systemImage: "arrow.down.circle",
               title: "Pull down for a fresh location",
               detail: "Pulling down on the Adhan tab takes a new GPS fix, which is what corrects the city after a flight.",
               place: "Adhan tab"),
        AppTip(id: "adhan.countdown", area: .adhan, group: "THE PRAYER LIST", systemImage: "timer",
               title: "More on the countdown",
               detail: "Tap the countdown card to show or hide the extra prayer details beneath it.",
               place: "Adhan tab"),

        AppTip(id: "adhan.compass", area: .adhan, group: "QIBLA AND PLACE", systemImage: "location.north.line.fill",
               title: "Enlarge the compass",
               detail: "Tap the row with your city and the small compass to enlarge the Qibla compass. It then shows your coordinates and elevation, and you can feel it: light taps while you are off, firmer ones as you close in, and a distinct one within five degrees.",
               place: "Adhan tab", tour: true),
        AppTip(id: "adhan.copy", area: .adhan, group: "QIBLA AND PLACE", systemImage: "doc.on.doc",
               title: "Copy where and when you are",
               detail: "Touch and hold the city name, the coordinates, or the Hijri date to copy them.",
               place: "Adhan tab"),
        AppTip(id: "adhan.citytimes", area: .adhan, group: "QIBLA AND PLACE", systemImage: "globe.europe.africa.fill",
               title: "Another city's prayer times",
               detail: "Tap the city pill for City Prayer Times. Star the cities you check often, compare one with your own location, and read its times in its clock or yours. It never changes your own times.",
               place: "Adhan tab"),
        AppTip(id: "adhan.glance", area: .adhan, group: "QIBLA AND PLACE", systemImage: "rectangle.grid.2x2.fill",
               title: "Every tile is a button",
               detail: "The AT A GLANCE tiles all open something. Qibla opens a large compass, Daylight and Fasting Window open the Prayer Calendar, Moon opens the Hijri Calendar, and Prayer Calculation and Distance From Home open their settings.",
               place: "Adhan tab", tour: true),

        AppTip(id: "adhan.trackerhold", area: .adhan, group: "THE PRAYER TRACKER", systemImage: "checkmark.circle.fill",
               title: "Tap for on time, hold for more",
               detail: "Tap a prayer's circle to mark it prayed on time, and tap again to clear it. Touch and hold for Late and Missed.",
               place: "Adhan tab, Prayer Tracker", tour: true),
        AppTip(id: "adhan.history", area: .adhan, group: "THE PRAYER TRACKER", systemImage: "chart.bar.fill",
               title: "History & Insights",
               detail: "Under the tracker, History & Insights shows your days, weeks, months, and years, with streaks. Tap a day in the month, or a month in the year, to open it.",
               place: "Adhan tab, Prayer Tracker", destination: .prayerTracker),
        AppTip(id: "adhan.menses", area: .adhan, group: "THE PRAYER TRACKER", systemImage: "pause.circle.fill",
               title: "Pause for menstruation and postpartum",
               detail: "Pause tracking, on the history page, exempts those days. They never break your streak, they stay out of every statistic, and the \u{201C}Did you pray?\u{201D} reminders stay silent while prayer-time notifications continue. Any single past day can be marked exempt too.",
               place: "Prayer Tracker, History & Insights", destination: .prayerTracker, card: ("Tracker Pause", "Menstruation and postpartum days that never break a streak.")),
        AppTip(id: "adhan.markgate", area: .adhan, group: "THE PRAYER TRACKER", systemImage: "lock.fill",
               title: "Mark only after the time begins",
               detail: "A switch on the history page keeps a prayer from being marked before its time has come in. Past days can always be filled in.",
               place: "Prayer Tracker, History & Insights", destination: .prayerTracker),
        AppTip(id: "adhan.jumuah", area: .adhan, group: "THE PRAYER TRACKER", systemImage: "person.3.fill",
               title: "Jumuah counts as Dhuhr",
               detail: "Marking either one covers Friday's noon prayer.",
               place: "Prayer Tracker"),

        AppTip(id: "adhan.export", area: .adhan, group: "CALENDARS", systemImage: "square.and.arrow.up",
               title: "Export a year of prayer times",
               detail: "The Prayer Calendar covers this month and the year ahead. Its share button exports them as a PDF or a CSV, under your own prayer names.",
               place: "Adhan tab, Prayer Calendar"),
        AppTip(id: "adhan.hijri", area: .adhan, group: "CALENDARS", systemImage: "calendar.badge.clock",
               title: "Two Hijri calendars in one",
               detail: "The Hijri Calendar's toolbar button switches between a month grid and the list of Islamic dates. Tap a day for its details, and touch and hold an Islamic date to copy it.",
               place: "Adhan tab, Hijri Calendar"),

        AppTip(id: "adhan.travel", area: .adhan, group: "TRAVEL AND CALCULATION", systemImage: "airplane",
               title: "Traveling mode turns itself on",
               detail: "Set a home city and the app notices when you are more than 48 miles (about 77 km) from it, offers to shorten and combine your prayers, and offers to switch back when you return.",
               place: "Prayer Settings, Traveling Mode", destination: .prayerPage(.travelingMode), tour: true, card: ("Auto Traveling Mode", "Notices when you are 48 miles from home and offers to shorten your prayers.")),
        AppTip(id: "adhan.autocalc", area: .adhan, group: "TRAVEL AND CALCULATION", systemImage: "function",
               title: "The method follows the country",
               detail: "With Choose Automatically on, the calculation method changes to the one customary where you are, and asks you first. The list of methods is searchable.",
               place: "Prayer Settings, Prayer Calculation", destination: .prayerPage(.prayerCalculation)),
        AppTip(id: "adhan.angles", area: .adhan, group: "TRAVEL AND CALCULATION", systemImage: "angle",
               title: "Match your mosque's angles",
               detail: "Under the Custom method, the Fajr and Isha angles can each be set from 8 to 25 degrees, for a mosque that publishes its own.",
               place: "Prayer Settings, Prayer Calculation", destination: .prayerPage(.prayerCalculation), advanced: true),
        AppTip(id: "adhan.names", area: .adhan, group: "TRAVEL AND CALCULATION", systemImage: "character.cursor.ibeam",
               title: "Call the prayers what you call them",
               detail: "Custom Prayer Names renames any prayer everywhere at once: the app, its notifications, the widgets, and the Apple Watch.",
               place: "Prayer Settings, Custom Prayer Names", destination: .prayerPage(.customPrayerNames), advanced: true, card: ("Custom Prayer Names", "Call the prayers what you call them, everywhere at once.")),
        AppTip(id: "adhan.offsets", area: .adhan, group: "TRAVEL AND CALCULATION", systemImage: "slider.horizontal.3",
               title: "Follow your mosque's clock",
               detail: "Manual Offsets move any prayer by up to 190 minutes either way, and the Hijri date by up to three days.",
               place: "Prayer Settings, Manual Offsets", destination: .prayerPage(.manualOffsets)),
        AppTip(id: "adhan.maghribdate", area: .adhan, group: "TRAVEL AND CALCULATION", systemImage: "sunset.fill",
               title: "A day that begins at sunset",
               detail: "Switch Hijri Date at Maghrib turns the Hijri date over at Maghrib instead of midnight, the way the Islamic day runs.",
               place: "Prayer Settings, Manual Offsets", destination: .prayerPage(.manualOffsets)),

        AppTip(id: "adhan.siri", area: .adhan, group: "BEYOND THE APP", systemImage: "mic.fill",
               title: "Ask Siri",
               detail: "\u{201C}When is Asr in \(app)\u{201D}, \u{201C}Current prayer in \(app)\u{201D}, and \u{201C}Next prayer in \(app)\u{201D} are answered aloud without opening the app.",
               place: "Siri and Shortcuts", isAvailable: { hasSiriShortcuts }),
        AppTip(id: "adhan.widgets", area: .adhan, group: "BEYOND THE APP", systemImage: "rectangle.3.group.fill",
               title: "Widgets with a sky",
               detail: "Most prayer widgets come in a Sky version painted with your sky colors. The Lock Screen has prayer-time and Hijri date widgets, including one that sits above the clock.",
               place: "Home Screen and Lock Screen"),
        AppTip(id: "adhan.liveactivity", area: .adhan, group: "BEYOND THE APP", systemImage: "fork.knife",
               title: "Ramadan on the Lock Screen",
               detail: "In Ramadan a Live Activity counts down to the end of suhoor and to iftar, appearing an hour before each.",
               place: "Lock Screen and Dynamic Island", isAvailable: { hasLiveActivities }),
        AppTip(id: "adhan.watch", area: .adhan, group: "BEYOND THE APP", systemImage: "applewatch",
               title: "On your wrist",
               detail: "The Apple Watch app has a sky strip of its own that you can drag through the day, complications with the current prayer and a live countdown, and settings that stay in step with the iPhone.",
               place: "Apple Watch"),
    ]

    // MARK: Notifications

    private static let notifications: [AppTip] = [
        AppTip(id: "notif.nagging", area: .notifications, group: "PRAYING ON TIME", systemImage: "exclamationmark.bubble.fill",
               title: "Nagging Mode",
               detail: "Asks \u{201C}Did you pray it?\u{201D} as each prayer's time runs out and keeps asking until you answer. You choose when it starts, how often it repeats, which prayers, a check-in after the adhan, the tone, and a pause.",
               place: "Notifications, Nagging Mode", destination: .notificationsPage(.naggingMode), tour: true, card: ("Nagging Mode", "Asks \u{201C}Did you pray?\u{201D} until you answer. Now with its own schedule, tone, and pause.")),
        AppTip(id: "notif.lockscreen", area: .notifications, group: "PRAYING ON TIME", systemImage: "hand.tap.fill",
               title: "Answer from the Lock Screen",
               detail: "Touch and hold a \u{201C}Did you pray?\u{201D} reminder for \u{201C}Yes, on time\u{201D} and \u{201C}Yes, but late\u{201D}. Either one marks the prayer tracker and cancels the rest of that prayer's reminders, without opening the app.",
               place: "Lock Screen", tour: true),
        AppTip(id: "notif.tapasks", area: .notifications, group: "PRAYING ON TIME", systemImage: "questionmark.bubble.fill",
               title: "Tapping a notification logs the prayer",
               detail: "Open the app from any prayer notification and it asks \u{201C}Did you pray it?\u{201D} about the prayer that notification was for, even days later, and records your answer in the tracker.",
               place: "Any prayer notification"),

        AppTip(id: "notif.fulladhan", area: .notifications, group: "THE ADHAN", systemImage: "speaker.wave.3.fill",
               title: "Open the app, hear the whole adhan",
               detail: "iOS lets a notification play 30 seconds at most. Open the app within ten minutes of a prayer time and the adhan plays in full, and it plays in full whenever the app is already open as the time comes in.",
               place: "Adhan tab", tour: true),
        AppTip(id: "notif.silent", area: .notifications, group: "THE ADHAN", systemImage: "bell.slash.fill",
               title: "Through silent mode",
               detail: "Play In-App Adhan in Silent Mode lets the adhan that plays inside the app sound even with the ringer switched off. Notifications outside the app still follow the iPhone's own sound settings.",
               place: "Notifications", destination: .notifications, advanced: true),
        AppTip(id: "notif.preview", area: .notifications, group: "THE ADHAN", systemImage: "play.circle.fill",
               title: "Preview plays the full recording",
               detail: "Preview Sound plays the chosen adhan from beginning to end, not the 30 seconds a notification carries.",
               place: "Notifications", destination: .notifications),
        AppTip(id: "notif.perprayer", area: .notifications, group: "THE ADHAN", systemImage: "slider.horizontal.below.rectangle",
               title: "A different sound for each prayer",
               detail: "Every prayer chooses for itself between the adhan, a short excerpt of it, and an ordinary sound: a full adhan at Maghrib and a quiet tone at Fajr, if that suits your house.",
               place: "Notifications, Prayer Notifications", destination: .notificationsPage(.prayerReminders), advanced: true),
        AppTip(id: "notif.alerttone", area: .notifications, group: "THE ADHAN", systemImage: "waveform",
               title: "A tone for being told, not called",
               detail: "The Alert Tone plays for everything that is not a call to prayer: prenotifications, Shurooq, the optional times, and prayers whose adhan is off. Echo and Takbir are soft; Chime, Ring, and Alarm are made to carry through noise.",
               place: "Notifications", destination: .notifications, advanced: true),

        AppTip(id: "notif.meanings", area: .notifications, group: "WORDING AND DATES", systemImage: "textformat",
               title: "Say what the names mean",
               detail: "Show English Meanings words a notification as \u{201C}Time for Maghrib (sunset)\u{201D}.",
               place: "Notifications, Prayer Notifications", destination: .notificationsPage(.prayerReminders)),
        AppTip(id: "notif.daybefore", area: .notifications, group: "WORDING AND DATES", systemImage: "calendar.badge.exclamationmark",
               title: "Never surprised by Ramadan",
               detail: "Remind a Day Before sends a heads-up the evening before each Islamic date, so Ramadan, Eid, and the days of fasting do not arrive unannounced.",
               place: "Notifications", destination: .notifications, advanced: true),
        AppTip(id: "notif.sunnah", area: .notifications, group: "WORDING AND DATES", systemImage: "bell.badge",
               title: "Sunnah Reminders",
               detail: "Al-Kahf on Friday, al-Mulk before sleep, and more, each at a time you choose and each with the hadith it comes from. Tapping one opens the surah.",
               place: "Notifications, Sunnah Reminders", destination: .notificationsPage(.sunnahReminders), card: ("Sunnah Reminders", "Al-Kahf on Friday, al-Mulk before sleep, each with its hadith.")),
        AppTip(id: "notif.focus", area: .notifications, group: "WORDING AND DATES", systemImage: "moon.zzz.fill",
               title: "Through a Focus, if you allow it",
               detail: "Prayer notifications are marked Time Sensitive. Allow Time Sensitive notifications for \(app) in a Focus such as Sleep or Do Not Disturb and they still come through.",
               place: "iPhone Settings, Focus"),
    ]

    // MARK: Quran

    private static let quran: [AppTip] = [
        AppTip(id: "quran.holdtitle", area: .quran, group: "MOVING AROUND", systemImage: "hand.tap.fill",
               title: "Hold the title to choose a surah",
               detail: "In the reader, touch and hold the title at the top to go straight to Choose Surah. In page mode, holding the pill at the foot of the page does the same. A plain tap on the title opens its whole menu.",
               place: "Quran reader", tour: true),
        AppTip(id: "quran.modes", area: .quran, group: "MOVING AROUND", systemImage: "book",
               title: "Pages or a list, same place",
               detail: "Read as Pages and Read as List, in the title's menu, switch the reader and keep you on the same ayah.",
               place: "Quran reader, title menu"),
        AppTip(id: "quran.wheel", area: .quran, group: "MOVING AROUND", systemImage: "number",
               title: "Jump to a page or a juz",
               detail: "In page mode, tap the page or juz number at the foot of the page for a wheel, and the keyboard icon inside it to type the number instead.",
               place: "Quran reader, page mode"),
        AppTip(id: "quran.chevron", area: .quran, group: "MOVING AROUND", systemImage: "chevron.down",
               title: "Fold the controls away",
               detail: "The small chevron at the very bottom of a page hides every bar for a clean mushaf page, and brings them back.",
               place: "Quran reader, page mode", tour: true),
        AppTip(id: "quran.pdf", area: .quran, group: "MOVING AROUND", systemImage: "doc.richtext",
               title: "Read the printed mushaf",
               detail: "In page mode the title's menu offers Read Pages as Printed Mushaf (PDF) wherever that riwayah's mushaf is included, with Automatic, Light, and Night lighting.",
               place: "Quran reader, page mode"),
        AppTip(id: "quran.pinch", area: .quran, group: "MOVING AROUND", systemImage: "plus.magnifyingglass",
               title: "Pinch a page to magnify it",
               detail: "Pinch a mushaf page to zoom into it, up to five times its size.",
               place: "Quran reader, page mode"),
        AppTip(id: "quran.fitpage", area: .quran, group: "MOVING AROUND", systemImage: "rectangle.portrait.arrowtriangle.2.inward",
               title: "Pages set like the printed mushaf",
               detail: "Fit Page to Screen sets each page the way the printed mushaf sets it, the same lines broken at the same words, at the largest size that fits your screen, in your own font and colors.",
               place: "Quran Settings, Arabic Text", destination: .quranPage(.arabicText)),

        AppTip(id: "quran.holdayah", area: .quran, group: "AYAHS AND WORDS", systemImage: "ellipsis.circle.fill",
               title: "Touch and hold an ayah",
               detail: "In either reader, touch and hold an ayah for everything you can do with it: tafsir, notes, highlights, playback, comparison, sharing. In list mode the row's ellipsis opens the same actions.",
               place: "Quran reader", tour: true),
        AppTip(id: "quran.wordtap", area: .quran, group: "AYAHS AND WORDS", systemImage: "character.magnify",
               title: "Tap a word twice",
               detail: "Two taps on a word open its meaning, its root, every other word from that root, the tajweed rules inside it, and a Listen button. A single tap still marks the ayah. It works offline, on Hafs.",
               place: "Quran reader", destination: .quranPage(.arabicText), tour: true, card: ("Word Meanings", "Tap a word twice for its meaning, root, and tajweed.")),
        AppTip(id: "quran.pins", area: .quran, group: "AYAHS AND WORDS", systemImage: "slider.horizontal.2.square",
               title: "Settings for one ayah",
               detail: "Apply Settings, in an ayah's actions, changes how that one ayah is shown: beginner spacing, tajweed, tashkeel, dots, word by word. Reset to App Settings puts it back.",
               place: "Quran reader, ayah actions"),
        AppTip(id: "quran.select", area: .quran, group: "AYAHS AND WORDS", systemImage: "checklist",
               title: "Select several ayahs",
               detail: "Select Ayahs, in the title's menu, lets you tap as many ayahs as you like and then copy, share, bookmark, highlight, or annotate them together.",
               place: "Quran reader, title menu"),
        AppTip(id: "quran.notes", area: .quran, group: "AYAHS AND WORDS", systemImage: "note.text",
               title: "Notes and colors",
               detail: "Give any ayah a note or a highlight color. Either one bookmarks it, and your notes also gather in the Islamic Journal.",
               place: "Quran reader, ayah actions"),
        AppTip(id: "quran.keepopen", area: .quran, group: "AYAHS AND WORDS", systemImage: "rectangle.stack",
               title: "Keep the actions open",
               detail: "With Keep Sheet Open on, tafsir and the other tools open on top of an ayah's actions instead of replacing them, so you come back to where you were.",
               place: "Quran Settings, Reading View", destination: .quranPage(.readingView), advanced: true),
        AppTip(id: "quran.similar", area: .quran, group: "AYAHS AND WORDS", systemImage: "arrow.triangle.branch",
               title: "Ayahs that resemble each other",
               detail: "Similar Ayahs and Mutashabihat, in an ayah's actions, list the ayahs that resemble it and the phrases it shares with others: a help in memorizing.",
               place: "Quran reader, ayah actions"),
        AppTip(id: "quran.surahinfo", area: .quran, group: "AYAHS AND WORDS", systemImage: "info.circle.fill",
               title: "About this Surah",
               detail: "Tap a surah's heading on a page, or Surah Info in the title's menu, for its background from several sources.",
               place: "Quran reader"),
        AppTip(id: "quran.previewsize", area: .quran, group: "AYAHS AND WORDS", systemImage: "textformat.size",
               title: "Resize the ayah card",
               detail: "The minus and plus on the card at the top of an ayah's actions resize its Arabic, and tapping the percentage between them resets it.",
               place: "Quran reader, ayah actions"),

        AppTip(id: "quran.legend", area: .quran, group: "TAJWEED AND QIRAAT", systemImage: "circle.hexagongrid.fill",
               title: "The Legend pill does two things",
               detail: "Tap the row of colored dots for the full tajweed guide. Touch and hold it for a quick reminder of what the colors mean.",
               place: "Quran reader", tour: true),
        AppTip(id: "quran.tajweedcolors", area: .quran, group: "TAJWEED AND QIRAAT", systemImage: "eyedropper.halffull",
               title: "Choose your own tajweed colors",
               detail: "Open the tajweed guide from the reader's Legend pill, or from Customize Tajweed Colors in Quran Settings. Under More Detail, tap a rule's card to show or hide that rule, and use the color well on the card to recolor it.",
               place: "Quran Settings, Arabic Text", destination: .quranPage(.arabicText), card: ("Your Tajweed Colors", "Show, hide, and recolor every tajweed rule.")),
        AppTip(id: "quran.compare", area: .quran, group: "TAJWEED AND QIRAAT", systemImage: "rectangle.split.2x1",
               title: "Compare the riwayat",
               detail: "With Comparison mode on, a riwayah picker sits above the reader's search bar, and an ayah's Compare Ayah sets the readings side by side. The Qiraat Explorer steps through every place the riwayat differ.",
               place: "Quran Settings, Arabic Text", destination: .quranPage(.arabicText), advanced: true, card: ("Compare Riwayat", "Read the riwayat side by side and step through where they differ.")),
        AppTip(id: "quran.bare", area: .quran, group: "TAJWEED AND QIRAAT", systemImage: "textformat.abc.dottedunderline",
               title: "The text without its marks",
               detail: "Hide Arabic Tashkeel and Hide Arabic Dots show the words the way the earliest mushafs were written, across every riwayah.",
               place: "Quran Settings, Arabic Text", destination: .quranPage(.arabicText), advanced: true),

        AppTip(id: "quran.refs", area: .quran, group: "SEARCH", systemImage: "magnifyingglass",
               title: "Search understands references",
               detail: "Type 2:255, \u{201C}page 50\u{201D}, \u{201C}juz 30\u{201D}, or a surah's number or name. Negative numbers count from the end: \u{201C}-1\u{201D} is the last surah, page, and juz.",
               place: "Quran tab, search", tour: true),
        AppTip(id: "quran.filters", area: .quran, group: "SEARCH", systemImage: "slider.horizontal.3",
               title: "Search filter buttons",
               detail: "A row of buttons appears above the results while you search. Tap several at once: Whole Word, All Words or Any Word, Makki or Madani, inside chosen juz or surahs, translation or transliteration only, Best Match order, Go To a page or hizb, and which kinds of result to show. The first button opens every filter on one page, including words to leave out.",
               place: "Quran tab, search", tour: true),
        AppTip(id: "quran.operators", area: .quran, group: "SEARCH", systemImage: "character.cursor.ibeam",
               title: "Whole words, every word, without a word",
               detail: "The Match button finds whole words only, or words that start or end with what you typed. Words asks for every word anywhere in the ayah, or any one of them, and Without leaves words out. The same buttons sit over the search inside a surah and over page mode's find bar.",
               place: "Quran tab, search"),
        AppTip(id: "quran.spelling", area: .quran, group: "SEARCH", systemImage: "textformat.abc",
               title: "Spell it your way",
               detail: "Yaseen, Yasin, Bakara, Rehman: romanized spellings find the right surah. \u{201C}makki\u{201D} and \u{201C}madani\u{201D} list the surahs by where they were revealed.",
               place: "Quran tab, search"),
        AppTip(id: "quran.semantic", area: .quran, group: "SEARCH", systemImage: "sparkles",
               title: "Search by meaning",
               detail: "Ayah search also matches by meaning, on your device, so a phrase like \u{201C}being patient in hardship\u{201D} finds ayahs that never use those words. When both kinds of result exist, a switch chooses between AI Results and Keyword Results.",
               place: "Quran tab, search"),
        AppTip(id: "quran.findbar", area: .quran, group: "SEARCH", systemImage: "doc.text.magnifyingglass",
               title: "Find on this page",
               detail: "In page mode, Search opens a find bar for the page or the whole surah, with arrows to step through the matches. Type a reference there, such as 2:255, to jump to it.",
               place: "Quran reader, page mode"),

        AppTip(id: "quran.playmenu", area: .quran, group: "LISTENING", systemImage: "play.circle.fill",
               title: "The play button is a menu",
               detail: "Tap play for Choose Reciter and Play Ayah by Ayah, and under Other Options a custom range, a random ayah, a random reciter, and Repeat Surah up to 20 times.",
               place: "Quran reader", tour: true),
        AppTip(id: "quran.range", area: .quran, group: "LISTENING", systemImage: "repeat",
               title: "A range built for memorizing",
               detail: "Play Custom Range takes a range of ayahs or of pages, and repeats each ayah and the whole section as many times as you set.",
               place: "Quran reader, play menu"),
        AppTip(id: "quran.nowplaying", area: .quran, group: "LISTENING", systemImage: "waveform.circle.fill",
               title: "Hold the Now Playing bar",
               detail: "Touch and hold the player for Stop Playing, Play from Beginning, and the queue. Inside the reader, tapping the player jumps to the ayah being recited.",
               place: "Now Playing bar"),
        AppTip(id: "quran.dots", area: .quran, group: "LISTENING", systemImage: "circle.fill",
               title: "What the reciter dots mean",
               detail: "In the reciter list, tap the colored dot beside a name to learn what that reciter offers: ayah by ayah in their own voice, offline, or full surahs only. A purple dot means the recording is incomplete, and tapping it says which surahs exist.",
               place: "Quran Settings, Recitation", destination: .reciters),
        AppTip(id: "quran.download", area: .quran, group: "LISTENING", systemImage: "icloud.and.arrow.down",
               title: "Take a reciter offline",
               detail: "The cloud button on a reciter downloads every surah for listening without a connection, and Reciter Filter shows only the ones you have downloaded.",
               place: "Quran Settings, Recitation", destination: .reciters),
        AppTip(id: "quran.afterend", area: .quran, group: "LISTENING", systemImage: "forward.end.fill",
               title: "When a surah ends",
               detail: "After Surah Recitation Ends chooses between going on to the next surah, going back to the previous one, and stopping.",
               place: "Quran Settings, Recitation", destination: .quranPage(.recitation), advanced: true),

        AppTip(id: "quran.swipe", area: .quran, group: "THE QURAN TAB", systemImage: "hand.draw.fill",
               title: "Swipe a surah",
               detail: "Swipe a surah right to favorite it and left to play it. Touch and hold for View Fullscreen, Share Surah, Play Random Ayah, and Add to Queue.",
               place: "Quran tab", tour: true),
        AppTip(id: "quran.tiles", area: .quran, group: "THE QURAN TAB", systemImage: "square.grid.3x3.fill",
               title: "Hold a tile for its menu",
               detail: "In any grid, a tap opens the tile and a touch and hold opens its menu. The small star in a tile's corner favorites it without opening it.",
               place: "Quran tab, grid view"),
        AppTip(id: "quran.sort", area: .quran, group: "THE QURAN TAB", systemImage: "arrow.up.arrow.down",
               title: "Nine ways to sort",
               detail: "The sort menu orders the surahs by revelation, page, length in ayahs, words, or letters, by juz, and more. Its Khatm mode tracks a full reading and marks ayahs as you read them.",
               place: "Quran tab"),
        AppTip(id: "quran.planner", area: .quran, group: "THE QURAN TAB", systemImage: "calendar.badge.clock",
               title: "Plan a khatm",
               detail: "The Quran Planner, the calendar button at the top of the Quran tab, sets a goal of one, two, or three months and can remind you daily.",
               place: "Quran tab"),
        AppTip(id: "quran.themes", area: .quran, group: "THE QURAN TAB", systemImage: "paintbrush.pointed.fill",
               title: "Highlight Themes",
               detail: "Wash passages in the color of what they speak about, in both readers, or light one subject across the whole Quran with Browse by Theme.",
               place: "Quran Settings, Highlight Themes", destination: .quranPage(.highlightThemes), card: ("Highlight Themes", "Passages washed in the color of what they speak about.")),
        AppTip(id: "quran.shuffleaotd", area: .quran, group: "THE QURAN TAB", systemImage: "shuffle",
               title: "Another Ayah of the Day",
               detail: "The shuffle beside today's Ayah of the Day picks a different one, and the Today pill gathers the ayah, word, hadith, dua, and reminder of the day on one screen.",
               place: "Quran tab, Your Summary"),
        AppTip(id: "quran.share", area: .quran, group: "THE QURAN TAB", systemImage: "photo.fill",
               title: "Share an ayah as an image",
               detail: "Share Ayah makes an image or plain text, with your choice of font and backdrop, tajweed colors, your note, and the ayah's details.",
               place: "Quran reader, ayah actions"),
        AppTip(id: "quran.siri", area: .quran, group: "THE QURAN TAB", systemImage: "mic.fill",
               title: "Ask Siri to recite",
               detail: "\u{201C}Play surah Yaseen in \(app)\u{201D}, \u{201C}Play random surah in \(app)\u{201D}, and \u{201C}Play last listened surah in \(app)\u{201D}. Siri understands names, numbers, and common spellings.",
               place: "Siri and Shortcuts", isAvailable: { hasSiriShortcuts }),
        AppTip(id: "quran.widgets", area: .quran, group: "THE QURAN TAB", systemImage: "rectangle.3.group.fill",
               title: "The Quran on your Home Screen",
               detail: "Widgets for the Ayah of the Day, the Reminder of the Day, a Name of Allah, your Last Read Ayah, and your Last Listened Surah.",
               place: "Home Screen"),
    ]

    // MARK: Hadith

    private static let hadith: [AppTip] = [
        AppTip(id: "hadith.pills", area: .hadith, group: "SAVING", systemImage: "number.circle.fill",
               title: "The number badges are buttons",
               detail: "Tap the number beside a book or a chapter to favorite it. Tap a hadith's reference badge, such as Bukhari 5103, to bookmark it.",
               place: "Hadith tab", tour: true),
        AppTip(id: "hadith.rowmenu", area: .hadith, group: "SAVING", systemImage: "ellipsis.circle.fill",
               title: "Every hadith has a menu",
               detail: "Touch and hold a hadith, or tap its ellipsis, for Bookmark Hadith, Add Note, Copy Hadith, and Share Hadith. Your notes show under the hadith and gather in the Islamic Journal.",
               place: "Hadith reader", tour: true),
        AppTip(id: "hadith.swipe", area: .hadith, group: "SAVING", systemImage: "hand.draw.fill",
               title: "Swipe a book or a chapter",
               detail: "Swipe right to favorite it. Touch and hold for View Fullscreen and for sharing the book or the whole chapter.",
               place: "Hadith tab"),
        AppTip(id: "hadith.asks", area: .hadith, group: "SAVING", systemImage: "checkmark.shield.fill",
               title: "It asks before removing",
               detail: "Removing a bookmark or a favorite always asks first, and says so when a note would go with it.",
               place: "Everywhere"),

        AppTip(id: "hadith.reference", area: .hadith, group: "SEARCH", systemImage: "arrow.right.circle.fill",
               title: "Go straight to a hadith",
               detail: "Search \u{201C}bukhari 5103\u{201D} or \u{201C}muslim 3:12\u{201D} to open that exact narration. A bare number finds that chapter and that hadith in every collection. Inside a book the name is optional: \u{201C}1:4\u{201D} is chapter 1, hadith 4.",
               place: "Hadith tab, search", tour: true),
        AppTip(id: "hadith.filters", area: .hadith, group: "SEARCH", systemImage: "slider.horizontal.3",
               title: "Search filter buttons",
               detail: "A row of buttons appears above the results while you search. Choose the collections (or tap Six Books, or Bukhari & Muslim), keep only Sahih, Hasan, or Da'if narrations, switch several words to All Words or Any Word, and order the hadiths by Best Match. The first button opens every filter on one page. The same row, without the collections, sits over the search inside a book and inside a chapter.",
               place: "Hadith tab, search", tour: true),
        AppTip(id: "hadith.semantic", area: .hadith, group: "SEARCH", systemImage: "sparkles",
               title: "Search by meaning",
               detail: "Search also matches by meaning across all 17 collections, on your device, so \u{201C}controlling anger\u{201D} finds narrations that never say those words.",
               place: "Hadith tab, search", tour: true),
        AppTip(id: "hadith.crosslanguage", area: .hadith, group: "SEARCH", systemImage: "character.bubble.fill",
               title: "One language lights the other",
               detail: "An English search highlights the matching words in the Arabic too, and an Arabic search the English.",
               place: "Hadith tab, search"),
        AppTip(id: "hadith.help", area: .hadith, group: "SEARCH", systemImage: "questionmark.circle.fill",
               title: "Help appears when you need it",
               detail: "Tap the search field while it is empty for Quick Search Help and your recent searches. The minus folds the help away and keeps the searches.",
               place: "Hadith tab, search"),

        AppTip(id: "hadith.titlemenu", area: .hadith, group: "READING", systemImage: "list.bullet.indent",
               title: "The chapter title is a menu",
               detail: "In a chapter, tap the title for Choose Chapter and for Select Hadiths, which copies, shares, or bookmarks several at once.",
               place: "Hadith reader", tour: true),
        AppTip(id: "hadith.grades", area: .hadith, group: "READING", systemImage: "rosette",
               title: "Grades, with who gave them",
               detail: "Where a narration has been graded, the grade shows under it with the scholar's name, and stays visible whichever language you hide.",
               place: "Hadith reader"),
        AppTip(id: "hadith.onelanguage", area: .hadith, group: "READING", systemImage: "textformat",
               title: "Read in one language",
               detail: "Hide the Arabic or the English to read only the other. A search still shows the hidden language wherever it matched.",
               place: "Hadith Settings", destination: .hadithPage(.arabicText)),
        AppTip(id: "hadith.allah", area: .hadith, group: "READING", systemImage: "paintbrush.fill",
               title: "The name of Allah in red",
               detail: "Highlight Allah colors His name in both the Arabic and the English.",
               place: "Hadith Settings, Reading View", destination: .hadithPage(.readingView)),
        AppTip(id: "hadith.share", area: .hadith, group: "READING", systemImage: "photo.fill",
               title: "Share as an image",
               detail: "Share Hadith builds an image or plain text, and lets you choose which of the reference, the Arabic, and the English go in.",
               place: "Hadith reader"),

        AppTip(id: "hadith.daily", area: .hadith, group: "YOUR SUMMARY", systemImage: "sun.max.fill",
               title: "Another Hadith of the Day",
               detail: "The shuffle beside today's hadith picks a different one, and the plus in YOUR SUMMARY unfolds the days before.",
               place: "Hadith tab"),
        AppTip(id: "hadith.shuffle", area: .hadith, group: "YOUR SUMMARY", systemImage: "shuffle",
               title: "Open something at random",
               detail: "The shuffle in the BOOKMARKS header opens one of your bookmarks at random, and the one above a group of books opens a random book.",
               place: "Hadith tab"),
        AppTip(id: "hadith.doors", area: .hadith, group: "YOUR SUMMARY", systemImage: "rectangle.3.group",
               title: "Topics, Encyclopedia, History",
               detail: "Three doors under your summary: hadiths gathered by topic, an encyclopedia of explained narrations, and everything you have opened or searched. Tapping a past search in History runs it again.",
               place: "Hadith tab"),
        AppTip(id: "hadith.ai", area: .hadith, group: "YOUR SUMMARY", systemImage: "sparkles",
               title: "Summaries, on your device",
               detail: "A hadith's menu offers Summarize with AI, and search offers Ask AI about what you typed. Both run on the iPhone itself.",
               place: "Hadith reader", isAvailable: { hasAppleIntelligence }),
    ]

    // MARK: Islam

    private static let islam: [AppTip] = [
        AppTip(id: "islam.tasbih", area: .islam, group: "DHIKR AND DUA", systemImage: "circles.hexagonpath.fill",
               title: "The whole card counts",
               detail: "In the Tasbih Counter, tap anywhere on the counter card to count. Tap a dhikr in the list to count that one, and set the ring to complete every 33, 99, 100, 500, or 1,000.",
               place: "Islam tab, Tasbih Counter", tour: true),
        AppTip(id: "islam.tasbihstats", area: .islam, group: "DHIKR AND DUA", systemImage: "flame.fill",
               title: "Your dhikr adds up",
               detail: "The Tasbih keeps today's count, your day streak, your best streak, and a lifetime total that resets and corrections never lower.",
               place: "Islam tab, Tasbih Counter"),
        AppTip(id: "islam.session", area: .islam, group: "DHIKR AND DUA", systemImage: "play.rectangle.fill",
               title: "Guided dua sessions",
               detail: "Start Session, at the top of a dua collection, walks its duas one at a time, full screen, with a ring you tap to count repetitions. It moves on when you reach your target and remembers where you stopped.",
               place: "Islam tab, Dua & Supplications", tour: true),
        AppTip(id: "islam.listenall", area: .islam, group: "DHIKR AND DUA", systemImage: "speaker.wave.2.fill",
               title: "Listen All",
               detail: "In the duas and the dhikr, Listen All reads a whole section aloud in Arabic and highlights the line being read. For a better voice, download an Enhanced Arabic voice under Accessibility, Spoken Content, Voices in the iPhone's Settings.",
               place: "Islam tab, Duas and Dhikr"),
        AppTip(id: "islam.copyrows", area: .islam, group: "DHIKR AND DUA", systemImage: "doc.on.doc",
               title: "Copy any part of a dua",
               detail: "Touch and hold a dua or a dhikr to copy its Arabic, its transliteration, or its translation.",
               place: "Islam tab, Duas and Dhikr"),

        AppTip(id: "islam.letters", area: .islam, group: "LEARNING", systemImage: "textformat.size.ar",
               title: "Hear every letter",
               detail: "On a letter's page, tap a syllable and press play to hear it. The eye button hides the English readings, so the marks can be practiced from the Arabic alone.",
               place: "Islam tab, Arabic Alphabet", destination: .islamPage(.alphabet), tour: true),
        AppTip(id: "islam.letterfamilies", area: .islam, group: "LEARNING", systemImage: "wind",
               title: "Group the alphabet by tajweed",
               detail: "The button beside the alphabet's search regroups the letters by where they are made, by a quality such as whistling (safeer) or breath (hams), or by the rule they trigger after a noon sakinah. Every family is named in Arabic and English, and a chip above the letters narrows the alphabet to one family.",
               place: "Islam tab, Arabic Alphabet"),
        AppTip(id: "islam.letterprofile", area: .islam, group: "LEARNING", systemImage: "mouth",
               title: "Every letter's tajweed profile",
               detail: "A letter's page lists where it is made, the qualities it is said with, and the rule it triggers after a noon sakinah, a meem sakinah and the definite article, each with an example from the Quran. The arrows beside the size slider step to the next letter without going back.",
               place: "Islam tab, Arabic Alphabet"),
        AppTip(id: "islam.letterquiz", area: .islam, group: "LEARNING", systemImage: "checkmark.circle",
               title: "Sound-alike letters and a quiz",
               detail: "Explore, at the top of the alphabet, opens the pairs people mix up side by side with what separates them, and a ten-question quiz: name a letter, read a joined form, place a letter in its family, or pick the letter you hear.",
               place: "Islam tab, Arabic Alphabet"),
        AppTip(id: "islam.readingtest", area: .islam, group: "LEARNING", systemImage: "text.book.closed.fill",
               title: "A reading test, tier by tier",
               detail: "Reading Test, under Explore at the top of the alphabet, climbs 21 tiers in the order a qaa'idah teaches reading: single letters, short vowels, long vowels, sukoon and shaddah, the marks of the mushaf, and last of all words printed with no tashkeel. Each tier tests reading, spelling and listening. The hint spaces a word out letter by letter, and Find My Level picks the tier to start on.",
               place: "Islam tab, Arabic Alphabet"),
        AppTip(id: "islam.course", area: .islam, group: "LEARNING", systemImage: "graduationcap.fill",
               title: "A tajweed course with quizzes",
               detail: "Tajweed Foundations is one course, from reading the letters to reading the mushaf. Each lesson gives the rule, its letters (tap one for its page), words to read aloud, example ayahs played in your own reciter, and a Check Yourself quiz. Mark lessons done, step through with the arrows at the top, and Continue picks up where you left off.",
               place: "Islam tab, Tajweed Foundations"),
        AppTip(id: "islam.names", area: .islam, group: "LEARNING", systemImage: "signature",
               title: "A Name, full screen",
               detail: "Tap a Name of Allah in the grid, or choose View Fullscreen from any row's menu, to fill the screen with it. Tap a name's number badge to favorite it, and the shuffle in the header to land on one at random.",
               place: "Islam tab, 99 Names of Allah", tour: true),
        AppTip(id: "islam.diagrams", area: .islam, group: "LEARNING", systemImage: "arrow.up.left.and.arrow.down.right",
               title: "Tap any diagram",
               detail: "The charts and photographs in the articles open full screen with a tap. Pinch to zoom, drag to move around, and tap twice to fit.",
               place: "Islam tab, articles"),
        AppTip(id: "islam.articles", area: .islam, group: "LEARNING", systemImage: "doc.text.magnifyingglass",
               title: "Find within an article",
               detail: "An article's search bar searches that article and scrolls to the match. Its text can be selected and copied, and a touch and hold on a quotation copies it with its citation.",
               place: "Islam tab, articles", tour: true),
        AppTip(id: "islam.askai", area: .islam, group: "LEARNING", systemImage: "sparkles",
               title: "Ask AI, with its sources",
               detail: "Ask AI answers from the Quran, the hadith collections, and the app's articles, on your device. Every citation opens its source, and wording it could not verify is marked as such.",
               place: "Islam tab, Ask AI", isAvailable: { hasAppleIntelligence }),

        AppTip(id: "islam.favorites", area: .islam, group: "THE ISLAM TAB", systemImage: "star.fill",
               title: "Favorite a resource",
               detail: "Swipe a resource right, tap the star in its tile's corner, or touch and hold the tile. Favorites gather in a section of their own at the top.",
               place: "Islam tab"),
        AppTip(id: "islam.reminder", area: .islam, group: "THE ISLAM TAB", systemImage: "bookmark.fill",
               title: "Keep a Reminder of the Day",
               detail: "Save keeps a Reminder of the Day, with its source, in Saved Reflections. The Today pill gathers the ayah, word, hadith, dua, and reminder of the day on one screen.",
               place: "Islam tab"),
        AppTip(id: "islam.fajr", area: .islam, group: "THE ISLAM TAB", systemImage: "sunrise.fill",
               title: "Days that begin at Fajr",
               detail: "Turn Over at Fajr changes every daily feature at Fajr rather than at midnight, so the day begins with the prayer.",
               place: "Islam Settings, Libraries", destination: .islamPage(.libraries), advanced: true, card: ("Days Begin at Fajr", "Every daily feature turns over with the prayer, not at midnight.")),
        AppTip(id: "islam.font", area: .islam, group: "THE ISLAM TAB", systemImage: "textformat.ar",
               title: "One Arabic font for everything else",
               detail: "The duas, the dhikr, the 99 Names, and the alphabet share one Arabic font, chosen here. The Quran and the hadith books keep their own.",
               place: "Islam Settings, Arabic Text", destination: .islamPage(.arabicText)),

        AppTip(id: "islam.zakah", area: .islam, group: "CALCULATORS AND TOOLS", systemImage: "percent",
               title: "Zakah, on either calendar",
               detail: "The Zakah Calculator works on a lunar year at 2.5% or a solar year at 2.577%. The small information buttons beside its fields open the scholarly detail behind each rule, and a touch and hold on the result copies it.",
               place: "Islam tab, Zakah Calculator"),
        AppTip(id: "islam.inheritance", area: .islam, group: "CALCULATORS AND TOOLS", systemImage: "divide.circle.fill",
               title: "Inheritance, exactly",
               detail: "The Inheritance Calculator works in exact fractions, applies \u{2018}awl and radd where the shares call for them, and names each relative who is present but does not inherit, with the reason.",
               place: "Islam tab, Inheritance Calculator"),
        AppTip(id: "islam.journal", area: .islam, group: "CALCULATORS AND TOOLS", systemImage: "square.and.pencil",
               title: "A journal that gathers your notes",
               detail: "The Islamic Journal collects the notes you leave on ayahs and hadiths beside your own entries. Swipe an entry to pin or delete it, and export everything as text from its menu.",
               place: "Islam tab, Islamic Journal"),
        AppTip(id: "islam.converter", area: .islam, group: "CALCULATORS AND TOOLS", systemImage: "calendar",
               title: "Copy a converted date",
               detail: "In the Hijri Date Converter, touch and hold either date to copy it.",
               place: "Islam tab, Hijri Date Converter"),
        AppTip(id: "islam.wallpapers", area: .islam, group: "CALCULATORS AND TOOLS", systemImage: "photo.on.rectangle",
               title: "Save a wallpaper",
               detail: "Touch and hold a wallpaper for Save to Photos and Copy Image.",
               place: "Islam tab, Islamic Wallpapers"),
    ]

    // MARK: The app

    private static let general: [AppTip] = generalLead + backupTips + generalTrail

    private static let generalLead: [AppTip] = [
        AppTip(id: "app.advanced", area: .app, group: "FINDING THINGS", systemImage: "slider.horizontal.3",
               title: "Simple until you ask for more",
               detail: "Every settings screen keeps to its essentials. Show Advanced Settings, at the foot of a screen that has more to show, reveals the rest of THAT screen: each one has its own switch, so turning Nagging Mode's on leaves Arabic Text simple. A search result or a tip marked Advanced turns them on for you.",
               place: "The foot of a settings screen"),

        AppTip(id: "app.search", area: .app, group: "FINDING THINGS", systemImage: "magnifyingglass",
               title: "Search every setting",
               detail: "The search bar at the foot of Settings finds any setting, and matches by meaning too: try \u{201C}make text bigger\u{201D}. Every settings page has a search bar of its own as well.",
               place: "Settings tab", tour: true),
        AppTip(id: "app.headers", area: .app, group: "FINDING THINGS", systemImage: "shuffle",
               title: "Headers that do things",
               detail: "Section headers across the app carry small controls: a shuffle that opens something at random, and a chevron that folds the section away.",
               place: "Everywhere", tour: true),
        AppTip(id: "app.hold", area: .app, group: "FINDING THINGS", systemImage: "hand.tap.fill",
               title: "Touch and hold is worth trying",
               detail: "Most rows, cards, tiles, and images answer a touch and hold with a menu: Copy, Share, Favorite, View Fullscreen, or Scroll To.",
               place: "Everywhere", tour: true),
        AppTip(id: "app.bars", area: .app, group: "FINDING THINGS", systemImage: "rectangle.compress.vertical",
               title: "Bars that get out of the way",
               detail: "Search bars and players shrink as you scroll down and come back when you scroll up.",
               place: "Everywhere"),

        AppTip(id: "app.progress", area: .app, group: "YOU", systemImage: "chart.line.uptrend.xyaxis",
               title: "Your Progress",
               detail: "Your prayers, reading, dhikr, and badges in one place. Streaks forgive one missed day a month, and reading on your Apple Watch counts once it syncs. Tap a badge for what it took to earn.",
               place: "Settings tab, Your Progress", tour: true),
        AppTip(id: "app.aboutyou", area: .app, group: "YOU", systemImage: "person.crop.circle.fill",
               title: "Tell the app who you are",
               detail: "About You remembers whether you grew up Muslim, embraced Islam, are just getting started, or are learning about Islam, and tailors the Start Here guide on the Islam tab. It never leaves your iPhone.",
               place: "Settings tab, About You", destination: .aboutYou),
    ]

    // iCloud Backup's tips, Al-Islam's alone (`HAS_ICLOUD_BACKUP`; the companion apps never receive the
    // backup). Their own list, between About You and Reset, where they always stood.
    #if HAS_ICLOUD_BACKUP
    private static let backupTips: [AppTip] = [
        AppTip(id: "app.icloud", area: .app, group: "YOU", systemImage: "icloud.fill",
               title: "Back up to your own iCloud",
               detail: "iCloud Backup keeps your bookmarks, prayer tracker, khatm, tasbih counts, journal and settings in your private iCloud. Up to six people or devices on one account each get a profile of their own, and a new iPhone can restore any of them, replacing what is there or merging with it. Your location is never included.",
               place: "Settings tab, iCloud Backup", destination: .cloudBackup),
        AppTip(id: "app.icloudIncluded", area: .app, group: "YOU", systemImage: "list.bullet.rectangle.fill",
               title: "See exactly what a backup holds",
               detail: "What's Included, on the iCloud Backup page, lists every kind of thing a backup of this iPhone carries right now, with counts and the size, and everything a backup never includes. Every restore shows the same categories side by side, here against the backup, before you choose Replace or Merge.",
               place: "Settings tab, iCloud Backup, What's Included", destination: .cloudBackup),
        AppTip(id: "app.backupFile", area: .app, group: "YOU", systemImage: "square.and.arrow.up",
               title: "Keep a backup as a file",
               detail: "Export a Backup File writes the same backup to a file you keep yourself: AirDrop it to a family member's iPhone or save it in Files. Restore from a File reads one back. No iCloud needed on either side.",
               place: "Settings tab, iCloud Backup, Backup File", destination: .cloudBackup),
    ]
    #else
    private static let backupTips: [AppTip] = []
    #endif

    /// Reset's tip names the iCloud claim a keep-content reset spares only where there is one.
    private static var resetTipDetail: String {
        #if HAS_ICLOUD_BACKUP
        return "Reset All Settings offers two choices: put every option back and keep your bookmarks, favorites, progress and this iPhone's iCloud Backup, or erase everything. Both say exactly what they keep and what they remove."
        #else
        return "Reset All Settings offers two choices: put every option back and keep your bookmarks, favorites and progress, or erase everything. Both say exactly what they keep and what they remove."
        #endif
    }

    private static let generalTrail: [AppTip] = [
        AppTip(id: "app.reset", area: .app, group: "YOU", systemImage: "arrow.counterclockwise",
               title: "Reset without losing anything",
               detail: resetTipDetail,
               place: "Settings tab"),

        AppTip(id: "app.themes", area: .app, group: "HOW IT LOOKS", systemImage: "paintpalette.fill",
               title: "Reading themes",
               detail: "Beyond light and dark there are Gray and Sepia themes, and under Custom Colors a background color of your own, with any accent color to match.",
               place: "Settings tab, Appearance", destination: .appearance, card: ("Reading Themes", "Gray, Sepia, or a background color of your own.")),
        AppTip(id: "app.classic", area: .app, group: "HOW IT LOOKS", systemImage: "square.on.square",
               title: "Classic Look",
               detail: "Classic Look turns off Liquid Glass for a faster app that is easier on the battery, and can switch itself on in Low Power Mode.",
               place: "Settings tab, Appearance, Look and Feel", destination: .appearancePage(.lookAndFeel), isAvailable: { hasLiquidGlass }),
        AppTip(id: "app.glow", area: .app, group: "HOW IT LOOKS", systemImage: "sun.haze.fill",
               title: "The glow at the top",
               detail: "Top Accent Glow washes the top of each screen in your accent color. Al-Islam Glow paints it yellow and green instead, and turning it off gives a flat background.",
               place: "Settings tab, Appearance, Custom Colors", destination: .appearancePage(.customColors)),
        AppTip(id: "app.launchtab", area: .app, group: "HOW IT LOOKS", systemImage: "rectangle.portrait.and.arrow.forward",
               title: "Choose the tab the app opens on",
               detail: "Open the App On picks where the app lands: Adhan, Quran, Hadith, or Islam. A notification or a reminder you tap still opens where it points.",
               place: "Settings tab, Appearance, Look and Feel", destination: .appearancePage(.lookAndFeel)),
    ]
}

// MARK: - The door on each settings page

/// "Tips & Tricks", the first row of a settings page. `resolve` is the page's own search resolver, so
/// a tip that opens one of that page's screens pushes it directly instead of a second page root.
struct TipsSection: View {
    @ObservedObject private var settings = Settings.shared

    let area: TipArea
    var resolve: (SettingsSearchEntry.Destination) -> AnyView? = { _ in nil }

    var body: some View {
        Section {
            NavigationLink(destination: LazyDestination { TipsView(area: area, resolve: resolve) }) {
                SettingsRowLabel(title: "Tips & Tricks", systemImage: "lightbulb.fill",
                                 subtitle: "\(TipCatalog.tips(in: area).count) things that are easy to miss",
                                 tint: area.tint, secondaryTint: area.secondaryTint)
            }
            .tint(settings.accentColor.color)
        }
    }
}

// MARK: - The list

struct TipsView: View {
    @ObservedObject private var settings = Settings.shared

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
                          placeholder: "Search these tips")
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

                Image(systemName: "chevron.right")
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

                Text(tip.detail)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                // HStacks, not Labels: inside a List a Label's icon takes the row's full icon column,
                // which left a 30 pt gap between a 10 pt pin and its text.
                caption(tip.place, systemImage: "mappin.and.ellipse",
                        color: tip.destination == nil ? appearance.accent : .secondary)
                    .padding(.top, 1)

                if tip.destination != nil {
                    caption(tip.advanced ? "Opens the setting (Advanced Settings)" : "Opens the setting",
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
    @ObservedObject private var settings = Settings.shared
    @Environment(\.dismiss) private var dismiss

    let area: TipArea
    /// Extra cards ahead of the area's own (the welcome flow's tour passes a hand-picked set).
    var tips: [AppTip]? = nil

    @State private var page = 0

    private var cards: [AppTip] { tips ?? TipCatalog.tour(in: area) }

    var body: some View {
        NavigationView {
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
            .navigationTitle(area.tourTitle)
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
        }
        .navigationViewStyle(.stack)
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
                Text(page < cards.count - 1 ? "Next" : "Finish")
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

                Text(tip.detail)
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
    @ObservedObject private var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(footer: Text("Each settings page opens with its own list too, and every list has a tour.")) {
                    ForEach(TipArea.allCases) { area in
                        NavigationLink(destination: LazyDestination { TipsView(area: area) }) {
                            SettingsRowLabel(title: area.title, systemImage: area.systemImage,
                                             subtitle: TipCatalog.tips(in: area).first?.title,
                                             tint: area.tint, secondaryTint: area.secondaryTint,
                                             value: "\(TipCatalog.tips(in: area).count)")
                        }
                        .tint(settings.accentColor.color)
                    }
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
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
    @ObservedObject private var settings = Settings.shared

    /// True for the fallback shape: one settings row per tip.
    let rows: Bool
    /// The card whose screen fills the iPad/Mac detail column. It wears the ring every sidebar grid
    /// marks its open tile with (`gridSelectionRing`), since the hub rows drop their highlight then.
    var selectedTipID: String? = nil
    /// Opens a card: the iPhone push (`SettingsView.spotlightTarget`) or the split's detail column.
    var open: (AppTip) -> Void = { _ in }

    var body: some View {
        let tips = TipCatalog.spotlight
        Section(header: Text("ONLY IN \(AppIdentifiers.appName.uppercased())")) {
            if rows {
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
                    .padding(.horizontal, 16)
                    .padding(.vertical, 2)
                }
                // Edge to edge inside the section's card, so the strip scrolls under its corners
                // instead of stopping short of them.
                .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
            }

            NavigationLink(destination: LazyDestination { TipsHubView() }) {
                SettingsRowLabel(title: "All Tips & Tricks", systemImage: "lightbulb.fill",
                                 subtitle: "\(TipCatalog.all.filter { $0.isAvailable() }.count) things that are easy to miss",
                                 tint: SettingsTint.appearance)
            }
            .tint(settings.accentColor.color)
        }
    }
}

// MARK: - Settings-search entries (kept in THIS file, next to the screens they describe)
extension SettingsSearchEntry {
    private static let tipKeywords = "tips tricks hidden features gestures shortcuts tutorial tour how to help discover easy to miss did you know"

    static let tipsEntries: [SettingsSearchEntry] = [
        .init(title: "Tips & Tricks", path: "Settings", keywords: tipKeywords, destination: .tips(nil)),
        .init(title: "Prayer Times Tips & Tricks", path: "Prayer Settings", keywords: tipKeywords + " adhan sky qibla tracker", destination: .tips(.adhan)),
        .init(title: "Notification Tips & Tricks", path: "Notifications", keywords: tipKeywords + " adhan nagging lock screen", destination: .tips(.notifications)),
        .init(title: "Quran Tips & Tricks", path: "Quran Settings", keywords: tipKeywords + " reader mushaf tajweed word search", destination: .tips(.quran)),
        .init(title: "Hadith Tips & Tricks", path: "Hadith Settings", keywords: tipKeywords + " bookmark search reference", destination: .tips(.hadith)),
        .init(title: "Islam Tips & Tricks", path: "Islam Settings", keywords: tipKeywords + " tasbih dua dhikr names alphabet", destination: .tips(.islam)),
    ]
}

private struct SpotlightCard: View {
    /// The card's own curve, which a selection ring drawn on it must follow.
    static let cornerRadius: CGFloat = 18

    let tip: AppTip

    var body: some View {
        let tint = tip.area.tint
        VStack(alignment: .leading, spacing: 8) {
            AccentIconChip(systemImage: tip.systemImage, tint: tint,
                           secondaryTint: tip.area.secondaryTint, size: 34)

            Text(tip.card?.title ?? tip.title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Text(tip.card?.pitch ?? tip.detail)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(4)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)

            HStack(spacing: 3) {
                Text(tip.area.title)
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
            }
            .font(.caption2.weight(.semibold))
            .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(width: 164, height: 176, alignment: .topLeading)
        // The area's own colour as a wash, not glass: the cards sit on a list row, where clear glass
        // has nothing behind it to bend and showed no surface at all in the light themes.
        .background(
            RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                .fill(LinearGradient(colors: [tint.opacity(0.16), (tip.area.secondaryTint ?? tint).opacity(0.07)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                .strokeBorder(tint.opacity(0.28), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
    }
}
#endif
