#if os(iOS)
import SwiftUI

// Tab Tutorials (Abu, 2026-10-31: "would be fire to have a full tutorial for each one"). One tutorial per
// tab, the basics first: how the tab works for someone who has never opened it. Tips & Tricks lists what
// is hard to find; nothing taught the basics, and the complaints that started this (the home city set
// without the reader knowing) were about basics. Design: Docs/Product/Tab Tutorials Design.md; plan:
// Docs/Product/Tab Tutorials Plan.md.
//
// A tutorial is the Tips & Tricks tour's pager (`TourPager`, `TourCard`, TipsAndTricks.swift) over this
// file's cards. A card can carry up to two buttons that open the real setting, the home city picker or
// the tab's Tips & Tricks, pushed inside the tutorial's own stack (Back returns to the card). Not coach
// marks drawn over the live tab: Simple Mode, hidden sections and the iPad layout all move what they
// would point at.
//
// It opens from the tab's ⋯ menu, a one-time nudge on the tab (`TutorialNudgeSection`), the first row of
// the tab's Tips & Tricks on its settings page, a "New to This Tab?" door in Need a Hand?, the welcome's
// LEARN EACH TAB card, and settings search. The tab's own requests go through ONE sheet on the tab bar
// root (`tabTutorialPresenter()`), so no tab grows another sheet bridge.
//
// EVERY CARD WAS CHECKED AGAINST THE CODE (four surveys with file and line, 2026-10-31), the same rule as
// the tips: a card that describes something the app does not do is worse than no card, so a card changes
// in the same commit as its feature. Quoted labels are the app's own. A card about something Simple Mode,
// a device or this app's build takes away is not offered (`isAvailable`), and its copy is worded by the
// same flags (HAS_ADHAN, HAS_QURAN, HAS_HADITH, HAS_WEATHER): this file compiles in Al-Adhan and Al-Quran.
//
// No em dashes and no spaced hyphens in any of this text (house rule).

// MARK: - Model

/// A tab with a tutorial. Each app lists only the tabs it has, like `HelpDoorArea`.
enum TutorialTab: String, CaseIterable, Identifiable {
    #if HAS_ADHAN
    case adhan
    #endif
    #if HAS_QURAN
    case quran
    #endif
    #if HAS_HADITH
    case hadith
    #endif
    case islam

    var id: String { rawValue }

    /// The tutorial's title, on its navigation bar, its door rows and its search entry.
    var title: String {
        switch self {
        #if HAS_ADHAN
        case .adhan: return String(localized: "Adhan Tutorial")
        #endif
        #if HAS_QURAN
        case .quran: return String(localized: "Quran Tutorial")
        #endif
        #if HAS_HADITH
        case .hadith: return String(localized: "Hadith Tutorial")
        #endif
        case .islam: return String(localized: "Islam Tutorial")
        }
    }

    /// What it covers, under the nudge's question and the welcome's rows.
    var summary: String {
        switch self {
        #if HAS_ADHAN
        case .adhan: return String(localized: "Prayer times, your home city, the adhan and the Qibla, one card at a time.")
        #endif
        #if HAS_QURAN
        case .quran: return String(localized: "Reading, listening, tajweed colors and search, one card at a time.")
        #endif
        #if HAS_HADITH
        case .hadith: return String(localized: "The books, grades, chains and search, one card at a time.")
        #endif
        case .islam: return String(localized: "The library, favorites, learning Arabic and search, one card at a time.")
        }
    }

    /// The Tips & Tricks the last card opens, and whose colours the cards wear.
    var tipsArea: TipArea {
        switch self {
        #if HAS_ADHAN
        case .adhan: return .adhan
        #endif
        #if HAS_QURAN
        case .quran: return .quran
        #endif
        #if HAS_HADITH
        case .hadith: return .hadith
        #endif
        case .islam: return .islam
        }
    }

    /// The tab whose Need a Hand? run opens this tutorial, and whose name the nudge says.
    var helpDoorArea: HelpDoorArea {
        switch self {
        #if HAS_ADHAN
        case .adhan: return .adhan
        #endif
        #if HAS_QURAN
        case .quran: return .quran
        #endif
        #if HAS_HADITH
        case .hadith: return .hadith
        #endif
        case .islam: return .islam
        }
    }

    /// The tutorial of a Tips & Tricks area that is one tab's (Notifications and The App are not).
    init?(tipsArea: TipArea) {
        guard let tab = Self.allCases.first(where: { $0.tipsArea == tipsArea }) else { return nil }
        self = tab
    }

    init(helpDoorArea: HelpDoorArea) {
        self = Self.allCases.first { $0.helpDoorArea == helpDoorArea } ?? .islam
    }

    var tint: Color { tipsArea.tint }
    var secondaryTint: Color? { tipsArea.secondaryTint }
    var systemImage: String { tipsArea.systemImage }
    static let doorSymbol = "graduationcap.fill"
}

/// What a card's button opens.
enum TutorialAction: Identifiable {
    /// A settings page, as the root of what is pushed (`SettingsSearchDestinationView.view(for:)`).
    case setting(SettingsSearchEntry.Destination, label: InterfaceText)
    #if HAS_ADHAN
    /// The Set Home City picker (`MapView(choosingPrayerTimes: false)`), as a sheet: the same picker
    /// Settings › Prayer Settings › Traveling Mode and the Location card's Change open.
    case homeCity
    #endif
    /// The tab's Tips & Tricks list.
    case tips(TipArea)

    var id: String {
        switch self {
        case .setting(_, let label): return "setting." + label.english
        #if HAS_ADHAN
        case .homeCity: return "homeCity"
        #endif
        case .tips(let area): return "tips." + area.rawValue
        }
    }

    var label: String {
        switch self {
        case .setting(_, let label): return label.display
        #if HAS_ADHAN
        case .homeCity: return String(localized: "Change Home City")
        #endif
        case .tips: return String(localized: "Tips & Tricks")
        }
    }

    var systemImage: String {
        switch self {
        case .setting(let destination, _): return destination.icon
        #if HAS_ADHAN
        case .homeCity: return "house.fill"
        #endif
        case .tips: return "lightbulb.fill"
        }
    }
}

/// One card. Shaped like `AppTip`: each text is written as the literal `String(localized:)` would take,
/// and kept in English as well, so the tests read the copy in every interface language.
struct TutorialStep: Identifiable {
    let id: String
    let tab: TutorialTab
    let systemImage: String
    let title: InterfaceText
    let detail: InterfaceText
    /// Where it is done, in the app's own words: "Adhan tab", "Settings › Quran Settings › Arabic Text".
    let place: InterfaceText
    /// Zero to two buttons; the first is the one the card is about.
    var actions: [TutorialAction] = []
    /// The card shows the home city as it is now, and again when the picker closes.
    var showsHomeCity = false
    /// False where the reader cannot use what the card describes right now (Simple Mode hid it, the
    /// setting that shows it is off).
    var isAvailable: () -> Bool = { true }
}

// MARK: - The cards

enum TutorialCatalog {
    static let all: [TutorialStep] = {
        var steps: [TutorialStep] = []
        #if HAS_ADHAN
        steps += adhan
        #endif
        #if HAS_QURAN
        steps += quran
        #endif
        #if HAS_HADITH
        steps += hadith
        #endif
        steps += islam
        return steps
    }()

    /// The tab's cards the reader can use right now, in order.
    static func steps(for tab: TutorialTab) -> [TutorialStep] {
        all.filter { $0.tab == tab && $0.isAvailable() }
    }

    #if HAS_ADHAN
    private static let adhan: [TutorialStep] = [
        TutorialStep(id: "adhan.times", tab: .adhan, systemImage: "clock.fill",
                     title: InterfaceText("Prayer times for where you are"),
                     detail: InterfaceText("Allow location and the tab shows today's prayers, the current and the upcoming one, and the time left. Tap a prayer for its details, or pull down for a fresh location. The ⋯ menu holds the “Prayer Calendar”, the “Hijri Calendar” and the “Prayer Times Layout”."),
                     place: InterfaceText("Adhan tab")),
        TutorialStep(id: "adhan.calculation", tab: .adhan, systemImage: "function",
                     title: InterfaceText("How the times are worked out"),
                     detail: InterfaceText("With “Choose Automatically” on, the app switches to the method used in your country and tells you, so you can keep the one you had. Choosing a method yourself turns it off. “Hanafi Calculation for Asr” is there too."),
                     place: InterfaceText("Settings › Prayer Settings › Prayer Calculation"),
                     actions: [.setting(.prayerPage(.prayerCalculation), label: InterfaceText("Prayer Calculation"))]),
        TutorialStep(id: "adhan.homecity", tab: .adhan, systemImage: "house.fill",
                     title: InterfaceText("Your home city"),
                     detail: InterfaceText("The first place the app finds you is saved as your home city, and Traveling Mode measures how far you are from it. If that is not where you live, change it."),
                     place: InterfaceText("Settings › Prayer Settings › Traveling Mode"),
                     actions: [.homeCity, .setting(.prayerPage(.travelingMode), label: InterfaceText("Traveling Mode Settings"))],
                     showsHomeCity: true),
        TutorialStep(id: "adhan.travel", tab: .adhan, systemImage: "airplane",
                     title: InterfaceText("Traveling Mode"),
                     detail: InterfaceText("More than 48 mi from home, with “Automatic Traveling Mode” on, Traveling Mode turns on and asks you to “Keep On” or “Turn Off” (which also stops the automatic switch). Prayers then show shortened and combined, and “Show Full Prayers” on its page brings each back to its own time."),
                     place: InterfaceText("Settings › Prayer Settings › Traveling Mode"),
                     actions: [.setting(.prayerPage(.travelingMode), label: InterfaceText("Traveling Mode"))]),
        TutorialStep(id: "adhan.notifications", tab: .adhan, systemImage: "bell.fill",
                     title: InterfaceText("The adhan and reminders"),
                     detail: InterfaceText("Tap a prayer's bell to switch between “Notification”, “Prenotification” and “No Notification”, or hold it to choose one. In the Grid and Split layouts, open the prayer first. “Adhan Sound” and everything else is in Notifications."),
                     place: InterfaceText("Adhan tab"),
                     actions: [.setting(.notifications, label: InterfaceText("Notifications"))]),
        TutorialStep(id: "adhan.qibla", tab: .adhan, systemImage: "location.north.circle.fill",
                     title: InterfaceText("The Qibla and the Hijri date"),
                     detail: InterfaceText("Tap the compass beside your city to make it larger and show your coordinates. Tap the date for the “Hijri Calendar”, or hold it to copy. If your local date differs, “Hijri Offset” moves it by up to three days."),
                     place: InterfaceText("Adhan tab"),
                     actions: [.setting(.prayerPage(.manualOffsets), label: InterfaceText("Manual Offsets"))]),
        // The tracker's own section rule: the reader's switch under ON THE ADHAN TAB, and Simple Mode's
        // (shown to someone who marked a prayer in the last fourteen days).
        TutorialStep(id: "adhan.tracker", tab: .adhan, systemImage: "checkmark.circle.fill",
                     title: InterfaceText("Track your prayers"),
                     detail: InterfaceText("Under the prayer times, the Prayer Tracker has a circle for each prayer. Once a prayer's time has begun, tap its circle to mark it on time, or hold it for late or missed. “History & Insights” shows your record and streaks."),
                     place: InterfaceText("Adhan tab, Prayer Tracker"),
                     actions: [.setting(.prayerTracker, label: InterfaceText("Prayer Tracker"))],
                     isAvailable: { Settings.shared.showsTabSection(.adhanTracker) }),
        TutorialStep(id: "adhan.sky", tab: .adhan, systemImage: "sun.horizon.fill",
                     title: InterfaceText("The sky"),
                     detail: skyDetail,
                     place: InterfaceText("Adhan tab"),
                     actions: [.setting(.prayerPage(.sky), label: InterfaceText("Sky"))],
                     isAvailable: { Settings.shared.showSkyView }),
        TutorialStep(id: "adhan.further", tab: .adhan, systemImage: "lightbulb.fill",
                     title: InterfaceText("Go further"),
                     detail: InterfaceText("“Nagging Mode” asks “Did you pray?” until you answer, to help you pray on time. Tips & Tricks has everything else the prayer times can do, each with where to find it."),
                     place: InterfaceText("Settings › Notifications › Nagging Mode"),
                     actions: [.setting(.notificationsPage(.naggingMode), label: InterfaceText("Nagging Mode")), .tips(.adhan)]),
    ]

    /// Weather is Al-Islam's alone, and opt-in.
    private static var skyDetail: InterfaceText {
        #if HAS_WEATHER
        return InterfaceText("Drag the sun across the sky to see any moment of the day; let go to come back to now. Tap the moon to see it up close. Sky settings hold “Skyline”, “Sky Colors” and “Weather”, which is off until you turn it on.")
        #else
        return InterfaceText("Drag the sun across the sky to see any moment of the day; let go to come back to now. Tap the moon to see it up close. Sky settings hold “Show Sky”, “Skyline” and “Sky Colors”.")
        #endif
    }
    #endif

    #if HAS_QURAN
    // Most of the readers' gestures and menus are Hafs an Asim's, the default; the cards say so where a
    // riwayah changes them, rather than hiding.
    private static let quran: [TutorialStep] = [
        TutorialStep(id: "quran.tab", tab: .quran, systemImage: "character.book.closed.ar",
                     title: InterfaceText("Your Quran tab"),
                     detail: InterfaceText("Your Summary comes first, with the “Last Read Ayah” and the “Ayah of the Day”, then every surah: tap one to read it. Hold a surah for “Favorite Surah” to keep it under Favorites. Ayahs you bookmark gather under Bookmarks."),
                     place: InterfaceText("Quran tab")),
        TutorialStep(id: "quran.modes", tab: .quran, systemImage: "book.fill",
                     title: InterfaceText("List or pages"),
                     detail: InterfaceText("The list shows ayah by ayah with the translation; pages show the mushaf. Switch with “Read as Pages” or “Read as List” in the reader's title menu or the tab's ⋯ menu."),
                     place: InterfaceText("Quran reader, title menu"),
                     actions: [.setting(.quranSettings, label: InterfaceText("Quran Settings"))]),
        TutorialStep(id: "quran.moving", tab: .quran, systemImage: "arrow.left.arrow.right",
                     title: InterfaceText("Moving around"),
                     detail: InterfaceText("Hold the surah title for “Choose Surah”; a tap opens its full menu. On pages, swipe to turn, and tap the page or juz number on the pill at the foot to jump. In the list, “Previous” and “Next” at the end move between surahs."),
                     place: InterfaceText("Quran reader")),
        TutorialStep(id: "quran.gestures", tab: .quran, systemImage: "hand.tap.fill",
                     title: InterfaceText("Tap, double tap, hold"),
                     detail: InterfaceText("Tap an ayah to mark it, and hold it for its actions, like “Add Note” and “Share Ayah”. In the list, tap its number to bookmark it, and in Hafs, double tap its text to hear it. On pages, a double tap on a word opens Word Study."),
                     place: InterfaceText("Quran reader")),
        TutorialStep(id: "quran.listen", tab: .quran, systemImage: "play.circle.fill",
                     title: InterfaceText("Listen"),
                     detail: InterfaceText("Tap the reader's play button for “Play Surah” and “Choose Reciter”; in Hafs, hold it for “Play Custom Range”. While a recitation plays, the Now Playing bar stays at the foot of every tab."),
                     place: InterfaceText("Quran reader"),
                     actions: [.setting(.reciters, label: InterfaceText("Choose Reciter"))]),
        TutorialStep(id: "quran.tajweed", tab: .quran, systemImage: "paintpalette.fill",
                     title: InterfaceText("Tajweed colors"),
                     detail: InterfaceText("“Show Tajweed Colors” is on from the start. Tap the “Legend” pill in the reader for the full guide to the colors, or hold it for a quick look."),
                     place: InterfaceText("Quran reader"),
                     actions: [.setting(.quranPage(.arabicText), label: InterfaceText("Arabic Text"))]),
        TutorialStep(id: "quran.english", tab: .quran, systemImage: "textformat",
                     title: InterfaceText("Translation and transliteration"),
                     detail: InterfaceText("In Hafs, the translation is Saheeh International at first, and English Text can add the Clear Quran (Mustafa Khattab) or show it instead. “Show Transliteration” there puts Latin letters under the Arabic."),
                     place: InterfaceText("Settings › Quran Settings › English Text"),
                     actions: [.setting(.quranPage(.englishText), label: InterfaceText("English Text"))]),
        TutorialStep(id: "quran.beginner", tab: .quran, systemImage: "text.word.spacing",
                     title: InterfaceText("Need help reading?"),
                     detail: InterfaceText("“Enable Arabic Beginner Mode” puts a space between each Arabic letter, so the Quran is easier to read while you learn."),
                     place: InterfaceText("Settings › Quran Settings › Arabic Text"),
                     actions: [.setting(.quranPage(.arabicText), label: InterfaceText("Arabic Text"))]),
        TutorialStep(id: "quran.search", tab: .quran, systemImage: "magnifyingglass",
                     title: InterfaceText("Search"),
                     detail: InterfaceText("The tab's “Search” finds a surah by name or number, an ayah by its words in Arabic, English or transliteration, or a reference such as 2:255, page 5 or juz 30."),
                     place: InterfaceText("Quran tab")),
        TutorialStep(id: "quran.further", tab: .quran, systemImage: "lightbulb.fill",
                     title: InterfaceText("Go further"),
                     detail: InterfaceText("“Arabic Font” and “Arabic Font Size” are on Arabic Text, with “Show Riwayah / Qiraah” for the other readings. Tips & Tricks has everything else the Quran can do, each with where to find it."),
                     place: InterfaceText("Settings › Quran Settings › Arabic Text"),
                     actions: [.tips(.quran), .setting(.quranPage(.arabicText), label: InterfaceText("Arabic Text"))]),
    ]
    #endif

    #if HAS_HADITH
    private static let hadith: [TutorialStep] = [
        TutorialStep(id: "hadith.books", tab: .hadith, systemImage: "books.vertical.fill",
                     title: InterfaceText("The books"),
                     detail: InterfaceText { _ in "Your Summary keeps the “Hadith of the Day” and the “Last Read Hadith”. Below it, \(HadithCatalogBook.all.count) collections sit in four groups, from The Six Books to Other Books. Tap a book for its chapters." },
                     place: InterfaceText("Hadith tab")),
        TutorialStep(id: "hadith.reading", tab: .hadith, systemImage: "text.book.closed.fill",
                     title: InterfaceText("Reading a hadith"),
                     detail: InterfaceText("Each hadith shows its number and book, the Arabic, the narrator and the English, then its grade. “Previous” and “Next” move between chapters. Tap the chapter title for “Choose Chapter”."),
                     place: InterfaceText("Hadith reader")),
        TutorialStep(id: "hadith.grades", tab: .hadith, systemImage: "checkmark.seal.fill",
                     title: InterfaceText("Grades"),
                     detail: InterfaceText("Where a hadith has been graded, the “Grade:” line gives each scholar's verdict word for word, with the scholar's name. Sahih al-Bukhari and Sahih Muslim carry no grade line. Where a chain icon follows the grade, tap the grade for the Chain of Narrators."),
                     place: InterfaceText("Hadith reader")),
        TutorialStep(id: "hadith.bookmarks", tab: .hadith, systemImage: "bookmark.fill",
                     title: InterfaceText("Bookmarks, notes and favorites"),
                     detail: InterfaceText("Tap a hadith's number, or swipe it right, to bookmark it; “Add Note” in its menu saves a note and bookmarks it too. Bookmarks gather on the Hadith tab. Tap the number beside a book, or swipe it, to make it a favorite."),
                     place: InterfaceText("Hadith reader")),
        TutorialStep(id: "hadith.menu", tab: .hadith, systemImage: "ellipsis.circle.fill",
                     title: InterfaceText("The hadith menu"),
                     detail: InterfaceText("Touch and hold a hadith, or tap its ⋯, for “Bookmark Hadith”, “Add Note”, “Select Text”, “Copy Hadith” and “Share Hadith”, which makes an image or text. Where Apple Intelligence is available, “Summarize with AI” is there too."),
                     place: InterfaceText("A hadith's menu")),
        TutorialStep(id: "hadith.chains", tab: .hadith, systemImage: "point.3.connected.trianglepath.dotted",
                     title: InterfaceText("Chains and narrators"),
                     detail: InterfaceText("Many hadiths have “Chain of Narrators” in their menu: the isnad, narrator by narrator. Tap a narrator to see every narration that names them, with “Same Chain of Narrators” and “Tree of Narrators” under the chain where they exist. “Similar Hadiths”, in the same menu, finds narrations close to this one."),
                     place: InterfaceText("A hadith's menu")),
        TutorialStep(id: "hadith.search", tab: .hadith, systemImage: "magnifyingglass",
                     title: InterfaceText("Search"),
                     detail: InterfaceText("Search every collection in Arabic or English, or type a reference such as bukhari 5103. While you search, the buttons above the results keep only “Sahih”, “Hasan” or “Da'if” narrations."),
                     place: InterfaceText("Hadith tab")),
        TutorialStep(id: "hadith.language", tab: .hadith, systemImage: "textformat",
                     title: InterfaceText("Arabic, English or both"),
                     detail: InterfaceText("Turn off “Show Arabic” or “Show English” to read in one language; the two are never both off. The narrator line goes with the English."),
                     place: InterfaceText("Settings › Hadith Settings"),
                     actions: [.setting(.hadithPage(.arabicText), label: InterfaceText("Arabic Text")),
                               .setting(.hadithPage(.englishText), label: InterfaceText("English Text"))]),
        TutorialStep(id: "hadith.further", tab: .hadith, systemImage: "lightbulb.fill",
                     title: InterfaceText("Go further"),
                     detail: InterfaceText("Tips & Tricks has everything else the hadith books can do, each with where to find it."),
                     place: InterfaceText("Settings › Hadith Settings"),
                     actions: [.tips(.hadith)]),
    ]
    #endif

    private static let islam: [TutorialStep] = [
        // Offered to everyone who has not said they were raised Muslim (the guide's own rule), so a
        // reader who hid it learns how to bring it back.
        TutorialStep(id: "islam.starthere", tab: .islam, systemImage: "sparkles",
                     title: InterfaceText("Start Here"),
                     detail: InterfaceText("If you told About You you are new to Islam or learning about it, Start Here leads the tab with steps chosen for you. Each step is checked once you open it. “Hide” puts the guide away, and “Show the Start Here Guide” in About You brings it back."),
                     place: InterfaceText("Islam tab"),
                     actions: [.setting(.aboutYou, label: InterfaceText("About You"))],
                     isAvailable: { Settings.shared.userBackground?.wantsStartHere != false }),
        TutorialStep(id: "islam.library", tab: .islam, systemImage: "books.vertical.fill",
                     title: InterfaceText("The library"),
                     detail: InterfaceText("The ⋯ menu shows the resources as a grid or a list, grouped by subject (Learn, Remembrance, Faith & Proofs and more) or in one section. In Simple Mode, the Tools wait under “More Resources”."),
                     place: InterfaceText("Islam tab")),
        TutorialStep(id: "islam.favorites", tab: .islam, systemImage: "star.fill",
                     title: InterfaceText("Favorites"),
                     detail: InterfaceText("Touch and hold a resource and choose “Favorite”, or swipe its row in the list. Outside Simple Mode, the star in a tile's corner does it too. Favorites gather at the top of the tab."),
                     place: InterfaceText("Islam tab")),
        TutorialStep(id: "islam.basics", tab: .islam, systemImage: "building.columns.fill",
                     title: InterfaceText("Begin with the basics"),
                     detail: InterfaceText("“Pillars & Beliefs” holds the Five Pillars of Islam and the Six Pillars of Iman. “How-To Guides” walks you through wudu, salah, Jumuah and more."),
                     place: InterfaceText("Islam tab")),
        TutorialStep(id: "islam.arabic", tab: .islam, systemImage: "character.ar",
                     title: InterfaceText("Learn to read Arabic"),
                     detail: arabicDetail,
                     place: InterfaceText("Islam tab"),
                     actions: [.setting(.islamPage(.alphabet), label: InterfaceText("Alphabet Settings"))]),
        TutorialStep(id: "islam.remember", tab: .islam, systemImage: "hands.and.sparkles.fill",
                     title: InterfaceText("Remember Allah"),
                     detail: InterfaceText("“Dua & Supplications” holds Morning & Evening and all of Hisn al-Muslim. “Dhikr & Remembrances”, the “Tasbih Counter” and the “99 Names of Allah” sit beside it."),
                     place: InterfaceText("Islam tab")),
        TutorialStep(id: "islam.search", tab: .islam, systemImage: "magnifyingglass",
                     title: InterfaceText("Search"),
                     detail: InterfaceText("The search bar at the foot of the tab finds resources by name, and the titles and text of the articles in Pillars & Beliefs, the How-To Guides and Proving Islam."),
                     place: InterfaceText("Islam tab")),
        TutorialStep(id: "islam.readable", tab: .islam, systemImage: "textformat.size",
                     title: InterfaceText("Make it readable"),
                     detail: readableDetail,
                     place: InterfaceText("Settings › Islam Settings"),
                     actions: [.setting(.islamPage(.textSize), label: InterfaceText("Text Size")),
                               .setting(.islamPage(.arabicText), label: InterfaceText("Arabic Text"))]),
        TutorialStep(id: "islam.further", tab: .islam, systemImage: "lightbulb.fill",
                     title: InterfaceText("Go further"),
                     detail: InterfaceText("“Today” in the ⋯ menu gathers the day's picks, and the Reminder of the Day sits near the foot of the tab. Tips & Tricks has everything else, each with where to find it."),
                     place: InterfaceText("Islam tab"),
                     actions: [.tips(.islam)]),
    ]

    /// The Tajweed Course ships with the Quran domain (`TajweedLessonsStore.isBundled`): Al-Adhan has the
    /// letters and the rules only.
    private static var arabicDetail: InterfaceText {
        TajweedLessonsStore.isBundled
            ? InterfaceText("“Arabic Alphabet” teaches every letter and mark, “Tajweed Foundations” gives each rule a page, and the “Tajweed Course” goes lesson by lesson, with a “Check Yourself” quiz in each.")
            : InterfaceText("“Arabic Alphabet” teaches every letter and mark, and “Tajweed Foundations” gives each rule of recitation a page.")
    }

    /// Worded by the books this app has, as the Arabic font's tip is (`islamFontDetail`).
    private static var readableDetail: InterfaceText {
        #if HAS_QURAN && HAS_HADITH
        return InterfaceText("“Text Size” sizes everything on the Islam tab. “Arabic Font” sets the face for the duas, the dhikr, the 99 Names and the alphabet; the Quran and the hadith books keep their own. The gear at the top of the tab opens Islam Settings.")
        #elseif HAS_QURAN
        return InterfaceText("“Text Size” sizes everything on the Islam tab. “Arabic Font” sets the face for the duas, the dhikr, the 99 Names and the alphabet; the Quran keeps its own. The gear at the top of the tab opens Islam Settings.")
        #else
        return InterfaceText("“Text Size” sizes everything on the Islam tab, and “Arabic Font” sets the face for the duas, the dhikr, the 99 Names and the alphabet. The gear at the top of the tab opens Islam Settings.")
        #endif
    }
}

// MARK: - The nudge's memory

extension Settings {
    private static func tutorialTabs(_ raw: String) -> Set<String> {
        Set(raw.split(separator: ",").map(String.init))
    }

    /// Whether the tab's first-visit nudge has been answered: the tutorial taken (from anywhere that
    /// marks it) or the nudge closed.
    func tutorialNudgeSeen(_ tab: TutorialTab) -> Bool {
        Self.tutorialTabs(tutorialNudgesSeenRaw).contains(tab.rawValue)
    }

    /// From a button only. A defaults write is a publish, and one inside a body, an appear or a push
    /// re-enters the navigation frame (render-pass-defaults-write-loop). Writes nothing when it is
    /// already marked, so the tutorial's Finish costs nothing the second time.
    func markTutorialNudgeSeen(_ tab: TutorialTab) {
        var seen = Self.tutorialTabs(tutorialNudgesSeenRaw)
        guard !seen.contains(tab.rawValue) else { return }
        seen.insert(tab.rawValue)
        tutorialNudgesSeenRaw = TutorialTab.allCases.map(\.rawValue).filter(seen.contains).joined(separator: ",")
    }
}

// MARK: - The tutorial

/// A tab's tutorial. As a sheet it stands in its own stack with the house X, at the large detent since
/// the cards carry buttons; pushed (settings search, the Tips & Tricks row) or as a door's landing
/// (`HelpDoorSheet` brings the stack and the X), it is the pager alone. Finish closes it either way.
struct TabTutorialView: View {
    private let settings = Settings.shared
    @Environment(\.dismiss) private var dismiss

    let tab: TutorialTab
    var presentedAsSheet = false
    /// The card to open on (DEBUG `-tutorialCard <n>`).
    var initialPage = 0

    /// The card's setting or Tips & Tricks, pushed in this stack: one piece of state for the flag and
    /// the target (`PushItemDestination`), and never a link inside the pager.
    @State private var pushed: TutorialAction?
    @State private var choosingHomeCity = false

    var body: some View {
        if presentedAsSheet {
            SheetNavigationContainer {
                pager
                    .sheetDismissToolbar()
            }
            .smallMediumSheetPresentation(startLarge: true)
        } else {
            pager
        }
    }

    private var pager: some View {
        let steps = TutorialCatalog.steps(for: tab)
        return TourPager(ids: steps.map(\.id), initialPage: initialPage, onFinish: finish) { index in
            let step = steps[index]
            TourCard(systemImage: step.systemImage, tint: tab.tint, secondaryTint: tab.secondaryTint,
                     index: index, count: steps.count, title: step.title.display, detail: step.detail.display,
                     place: step.place.display, status: status(for: step),
                     actions: step.actions.map { action in
                         TourCard.Action(id: action.id, title: action.label, systemImage: action.systemImage) { perform(action) }
                     })
        }
        .navigationTitle(tab.title)
        .navigationBarTitleDisplayMode(.inline)
        .pushDestination(item: $pushed) { action in
            destination(for: action)
        }
        // Outside the push, so a "Show me" page sees this tutorial open: its settings page's door back
        // into the same tutorial greys out instead of starting a corridor (OpenScreens.swift).
        .openScreen(.tabTutorial, id: tab.rawValue)
        #if HAS_ADHAN
        .sheet(isPresented: $choosingHomeCity) {
            MapView(choosingPrayerTimes: false)
                .environmentObject(settings)
                .smallMediumSheetPresentation()
        }
        #endif
        #if DEBUG
        // "-tutorialAction <n>": press the opening card's nth button a moment after it appears, so a
        // script can record where "Show me" lands (there is no tap tooling for the simulator).
        .onAppear {
            let args = ProcessInfo.processInfo.arguments
            guard let i = args.firstIndex(of: "-tutorialAction"), args.indices.contains(i + 1),
                  let n = Int(args[i + 1]), steps.indices.contains(initialPage) else { return }
            let actions = steps[initialPage].actions
            guard actions.indices.contains(n) else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { perform(actions[n]) }
        }
        #endif
    }

    private func status(for step: TutorialStep) -> AnyView? {
        #if HAS_ADHAN
        if step.showsHomeCity { return AnyView(TutorialHomeCityLine()) }
        #endif
        return nil
    }

    private func perform(_ action: TutorialAction) {
        switch action {
        case .setting, .tips:
            guard pushed == nil else { return }
            pushed = action
        #if HAS_ADHAN
        case .homeCity:
            choosingHomeCity = true
        #endif
        }
    }

    @ViewBuilder
    private func destination(for action: TutorialAction) -> some View {
        switch action {
        case .setting(let destination, _):
            SettingsSearchDestinationView.view(for: destination)
        case .tips(let area):
            TipsView(area: area)
        #if HAS_ADHAN
        case .homeCity:
            EmptyView()
        #endif
        }
    }

    private func finish() {
        settings.markTutorialNudgeSeen(tab)
        dismiss()
    }
}

#if HAS_ADHAN
/// The home city card's live line: the city as it is now, so the Change Home City picker's choice shows
/// as soon as it closes.
private struct TutorialHomeCityLine: View {
    @ObservedObject private var adhanSettings = AdhanSettings.shared
    @Environment(\.appearance) private var appearance

    var body: some View {
        let city = adhanSettings.homeLocation?.displayCity.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        Label(city.isEmpty ? String(localized: "No home city yet: it is saved once the app finds you.") : String(localized: "Home city: \(city)"),
              systemImage: "house.fill")
            .font(.subheadline.weight(.semibold))
            .foregroundColor(city.isEmpty ? .secondary : .primary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }
}
#endif

// MARK: - Opening it from a tab

/// The tutorial a tab asked for: its ⋯ menu, its nudge, a DEBUG launch. ONE sheet on the tab bar root
/// presents it (`tabTutorialPresenter()`), so the tabs' own sheet bridges are untouched.
@MainActor
final class TabTutorialPresenter: ObservableObject {
    static let shared = TabTutorialPresenter()

    @Published var showing: TutorialTab?

    /// How many windows carry the presenter (`tabTutorialPresenter()`). An app root that never got the
    /// modifier (a companion app's, before its port) has none, and a request there must not answer the
    /// nudge or set `showing` with nothing to present it: the nudge would vanish, nothing would open,
    /// and every later request would be dropped.
    fileprivate var mountedPresenters = 0

    private init() {}

    /// Opening a tutorial answers its nudge. A request while one is up is dropped: a second sheet
    /// raised over the first is refused, and SwiftUI then holds it for the rest of the session.
    ///
    /// Like the app's other shared presenters (`FocusOverlayPresenter`, `AppNavigation`), it drives
    /// every window on an iPad or a Mac with several open.
    func open(_ tab: TutorialTab) {
        guard showing == nil, mountedPresenters > 0 else { return }
        Settings.shared.markTutorialNudgeSeen(tab)
        showing = tab
    }
}

private struct TabTutorialPresenterModifier: ViewModifier {
    @ObservedObject private var presenter = TabTutorialPresenter.shared

    func body(content: Content) -> some View {
        content
            .sheet(item: $presenter.showing) { tab in
                TabTutorialView(tab: tab, presentedAsSheet: true, initialPage: Self.debugInitialPage)
            }
            // In memory only, no defaults write. The last window to close takes an open request with
            // it: a sheet closed with its window may never write nil back through the binding.
            .onAppear { presenter.mountedPresenters += 1 }
            .onDisappear {
                presenter.mountedPresenters -= 1
                if presenter.mountedPresenters <= 0 { presenter.showing = nil }
            }
            #if DEBUG
            // "-tutorial adhan|quran|hadith|islam" opens that tutorial after the reveal;
            // "-tutorialCard <n>" opens it on card n (from 0).
            .task {
                let args = ProcessInfo.processInfo.arguments
                guard let i = args.firstIndex(of: "-tutorial"), args.indices.contains(i + 1),
                      let tab = TutorialTab(rawValue: args[i + 1]) else { return }
                await AppReveal.waitUntilRevealed()
                try? await Task.sleep(nanoseconds: 900_000_000)
                presenter.open(tab)
            }
            #endif
    }

    private static var debugInitialPage: Int {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-tutorialCard"), args.indices.contains(i + 1), let n = Int(args[i + 1]) {
            return n
        }
        #endif
        return 0
    }
}

extension View {
    /// The tab bar root's one presenter for every tab's tutorial (Al-IslamApp.swift).
    func tabTutorialPresenter() -> some View {
        modifier(TabTutorialPresenterModifier())
    }
}

/// The ⋯ menu's item, the same on all four tabs and in both modes: a door, not a detail.
struct TutorialMenuItem: View {
    let tab: TutorialTab

    var body: some View {
        TabMoreMenuItem(String(localized: "Tutorial"), systemImage: TutorialTab.doorSymbol) {
            Settings.shared.hapticFeedback()
            TabTutorialPresenter.shared.open(tab)
        }
    }
}

// MARK: - The nudge

/// The tab's first-visit nudge: "New to the Adhan tab?", what the tutorial covers, Take the Tutorial and
/// a close button. Shown until one of them is pressed, or the tutorial is taken from anywhere that marks
/// it; never written from an appear. In Simple Mode too: it is a door for exactly the reader Simple Mode
/// is for.
struct TutorialNudgeSection: View {
    private let settings = Settings.shared
    /// The slice that publishes `tutorialNudgesSeen`.
    @ObservedObject private var systemSettings = SystemSettings.shared
    @Environment(\.appearance) private var appearance

    let tab: TutorialTab

    var body: some View {
        if !settings.tutorialNudgeSeen(tab) {
            Section {
                card
            }
            .transition(.opacity)
        }
    }

    private var card: some View {
        HStack(alignment: .top, spacing: 12) {
            AccentIconChip(systemImage: TutorialTab.doorSymbol, tint: tab.tint, secondaryTint: tab.secondaryTint, size: 34)

            VStack(alignment: .leading, spacing: 4) {
                Text("New to the \(tab.helpDoorArea.tabName) tab?")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(tab.summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Borderless: two buttons in one List row each keep their own tap.
                Button {
                    settings.hapticFeedback()
                    TabTutorialPresenter.shared.open(tab)
                } label: {
                    Text("Take the Tutorial")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(appearance.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(appearance.accent.opacity(0.14)))
                }
                .buttonStyle(.borderless)
                .padding(.top, 4)
                .accessibilityIdentifier("tutorialNudgeTake")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                settings.hapticFeedback()
                withAnimation(.easeInOut) { settings.markTutorialNudgeSeen(tab) }
            } label: {
                Image(systemName: "xmark")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(Text("Close"))
            .accessibilityIdentifier("tutorialNudgeClose")
        }
        .padding(.vertical, 4)
    }
}

// MARK: - The door on a settings page

/// The tutorial's row, first in the tab's Tips & Tricks section (`TipsSection`): pushed in the settings
/// stack, so its "Show me" pages stack on it and Back walks home.
struct TutorialDoorRow: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    let tab: TutorialTab

    var body: some View {
        // Greyed when this page was opened from the same tutorial's card (`openScreen` there).
        OpenScreenLink(screen: .tabTutorial, id: tab.rawValue) {
            TabTutorialView(tab: tab)
        } label: {
            SettingsRowLabel(title: tab.title, systemImage: TutorialTab.doorSymbol,
                             subtitle: String(localized: "\(TutorialCatalog.steps(for: tab).count) cards, the basics first"),
                             tint: tab.tint, secondaryTint: tab.secondaryTint)
        }
        .tint(settings.accentColor.color)
    }
}

// MARK: - Settings-search entries (kept in THIS file, next to the screens they describe)

extension SettingsSearchEntry {
    private static let tutorialKeywords = "tutorial guide walkthrough how to basics beginner new start learn help introduction getting started first time"

    static let tutorialEntries: [SettingsSearchEntry] = {
        var entries: [SettingsSearchEntry] = []
        #if HAS_ADHAN
        entries.append(.init(title: "Adhan Tutorial", path: "Prayer Settings", keywords: tutorialKeywords + " prayer times home city traveling qibla hijri adhan notifications sky tracker", destination: .tutorial(.adhan)))
        #endif
        #if HAS_QURAN
        entries.append(.init(title: "Quran Tutorial", path: "Quran Settings", keywords: tutorialKeywords + " reader mushaf pages list tajweed reciter listen bookmark translation", destination: .tutorial(.quran)))
        #endif
        #if HAS_HADITH
        entries.append(.init(title: "Hadith Tutorial", path: "Hadith Settings", keywords: tutorialKeywords + " books grades chains narrators bookmark search", destination: .tutorial(.hadith)))
        #endif
        entries.append(.init(title: "Islam Tutorial", path: "Islam Settings", keywords: tutorialKeywords + " start here resources library favorites arabic alphabet dua dhikr", destination: .tutorial(.islam)))
        return entries
    }()
}
#endif
