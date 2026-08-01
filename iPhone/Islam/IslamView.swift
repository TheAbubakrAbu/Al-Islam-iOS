import SwiftUI

struct IslamView: View {
    @ObservedObject var settings = Settings.shared
    // No NamesViewModel observation: this body renders nothing from it, and observing it re-ran the
    // whole tab root when the 99 Names JSON finished its background load. NamesView observes it itself.
    #if os(iOS)
    @State private var selectedResource: IslamDestination? = .arabicAlphabet
    /// Programmatic pushes for the grid tiles (a `NavigationLink` inside a List row drags the row chevron
    /// into each tile; a path append does not).
    @State private var islamPath: [IslamDestination] = []

    /// String-backed so favorites persist by raw value, CaseIterable so the resource list, the grid, and the
    /// favorites section all draw from one source of truth instead of three hand-maintained row lists.
    private enum IslamDestination: String, Hashable, CaseIterable {
        case arabicAlphabet
        case tajweedFoundations
        case commonAdhkar
        case commonDuas
        case tasbihCounter
        // Zakah Calculator is built (ZakahView.swift) but hidden for now - uncomment this case and its
        // title/systemImage/gridTitle/destination/resourceLink entries below to ship it.
        // case zakahCalculator
        case namesOfAllah
        case hijriCalendarConverter
        case masjidLocator
        case halalFoodLocator
        case islamicWallpapers
        case pillarsAndBasics
        case howToGuides

        var title: String {
            switch self {
            case .arabicAlphabet: return "Arabic Alphabet"
            case .tajweedFoundations: return "Tajweed Foundations"
            case .commonAdhkar: return "Dhikr & Remembrances"
            case .commonDuas: return "Dua & Supplications"
            case .tasbihCounter: return "Tasbih Counter"
            // case .zakahCalculator: return "Zakah Calculator"
            case .namesOfAllah: return "99 Names of Allah"
            case .hijriCalendarConverter: return "Hijri Date Converter"
            case .masjidLocator: return "Masjid Locator"
            case .halalFoodLocator: return "Halal Food Locator"
            case .islamicWallpapers: return "Islamic Wallpapers"
            case .pillarsAndBasics: return "Pillars & Beliefs"
            case .howToGuides: return "How-To Guides"
            }
        }

        var systemImage: String {
            switch self {
            case .arabicAlphabet: return "textformat.size.ar"
            case .tajweedFoundations: return "waveform"
            case .commonAdhkar: return "book.closed"
            case .commonDuas: return "text.book.closed"
            case .tasbihCounter: return "circles.hexagonpath.fill"
            // case .zakahCalculator: return "percent"
            case .namesOfAllah: return "signature"
            case .hijriCalendarConverter: return "calendar"
            case .masjidLocator: return "mappin.and.ellipse"
            case .halalFoodLocator: return "fork.knife"
            case .islamicWallpapers: return "photo.on.rectangle"
            case .pillarsAndBasics: return "moon.stars"
            case .howToGuides: return "list.bullet.rectangle"
            }
        }

        /// One line of what lives behind the row - the Settings hub's caption column, here.
        var subtitle: String {
            switch self {
            case .arabicAlphabet: return "Letters, forms, diacritics, and signs"
            case .tajweedFoundations: return "The rules of beautiful recitation"
            case .commonAdhkar: return "Morning, evening, and daily remembrances"
            case .commonDuas: return "Authenticated supplications with sources"
            case .tasbihCounter: return "Count dhikr with a tap"
            // case .zakahCalculator: return "Work out what you owe"
            case .namesOfAllah: return "Asma ul-Husna with meanings"
            case .hijriCalendarConverter: return "Convert Hijri and Gregorian dates"
            case .masjidLocator: return "Find mosques near you"
            case .halalFoodLocator: return "Find halal food near you"
            case .islamicWallpapers: return "Beautiful wallpapers to save"
            case .pillarsAndBasics: return "The Five Pillars and Six Beliefs"
            case .howToGuides: return "Wudu, salah, Jumuah, and more"
            }
        }

        /// The tile title with its line break CHOSEN, not wherever truncation lands: every grid tile is
        /// exactly two lines, broken at the natural point, so a whole grid of tiles shares one height and
        /// one rhythm.
        var gridTitle: String {
            switch self {
            case .arabicAlphabet: return "Arabic\nAlphabet"
            case .tajweedFoundations: return "Tajweed\nFoundations"
            case .commonAdhkar: return "Dhikr &\nRemembrances"
            case .commonDuas: return "Dua &\nSupplications"
            case .tasbihCounter: return "Tasbih\nCounter"
            // case .zakahCalculator: return "Zakah\nCalculator"
            case .namesOfAllah: return "99 Names\nof Allah"
            case .hijriCalendarConverter: return "Hijri Date\nConverter"
            case .masjidLocator: return "Masjid\nLocator"
            case .halalFoodLocator: return "Halal Food\nLocator"
            case .islamicWallpapers: return "Islamic\nWallpapers"
            case .pillarsAndBasics: return "Pillars &\nBeliefs"
            case .howToGuides: return "How-To\nGuides"
            }
        }
    }

    /// Collapse state for the favorites section, same as the Quran tab's Favorite Surahs.
    @AppStorage("showIslamFavorites") private var showIslamFavorites = true

    private var favoriteResources: [IslamDestination] {
        IslamDestination.allCases.filter { settings.isIslamResourceFavorite($0.rawValue) }
    }

    private func favoriteToggleButton(_ item: IslamDestination) -> some View {
        let isFavorite = settings.isIslamResourceFavorite(item.rawValue)
        return Button {
            settings.hapticFeedback()
            withAnimation(.easeInOut) {
                settings.toggleIslamResourceFavorite(item.rawValue)
            }
        } label: {
            Label(isFavorite ? "Unfavorite" : "Favorite", systemImage: isFavorite ? "star.fill" : "star")
        }
    }
    #endif

    var body: some View {
        navigationContainer
    }

    private var navigationContainer: some View {
        Group {
            #if os(iOS)
            if #available(iOS 16.0, *), UIDevice.current.userInterfaceIdiom == .pad {
                NavigationSplitView {
                    islamSidebar
                } detail: {
                    // The detail needs its own NavigationStack so NavigationLinks inside a destination
                    // (e.g. tapping a letter in ArabicView) push within the detail column instead of
                    // hijacking the whole split. `.id` rebuilds the stack when the sidebar selection
                    // changes, so switching sections always resets to that section's root.
                    NavigationStack {
                        islamDetail
                    }
                    .id(selectedResource ?? .arabicAlphabet)
                }
            } else if #available(iOS 16.0, *) {
                NavigationStack(path: $islamPath) {
                    islamList
                        .navigationDestination(for: IslamDestination.self) { destination in
                            destinationView(for: destination)
                        }
                }
            } else {
                NavigationView {
                    islamList
                }
                .navigationViewStyle(.stack)
            }
            #else
            NavigationView {
                islamList
            }
            #endif
        }
    }

    private var islamList: some View {
        List {
            Group {
            #if os(iOS)
            if #available(iOS 16.0, *) {
                modernResourceSections
            } else {
                resourcesSection
            }
            #else
            resourcesSection
            #endif
            ProphetQuote()
            AlIslamAppsSection()
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Al-Islam")
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if #available(iOS 16.0, *) {
                    Button {
                        settings.hapticFeedback()
                        withAnimation { settings.islamGridMode.toggle() }
                    } label: {
                        Image(systemName: settings.islamGridMode ? "list.bullet" : "square.grid.2x2")
                    }
                    .accessibilityLabel(settings.islamGridMode ? "Show list" : "Show grid")
                    .tint(settings.accentColor.accent1)
                }
            }
        }
        #endif
    }

    #if os(iOS)
    /// The favorites section plus the full resource list, honoring the app-wide grid toggle. Value-based
    /// navigation (iOS 16+): the enum IS the row, so favorites, grid tiles, and list rows all push through
    /// the same `navigationDestination`.
    @available(iOS 16.0, *)
    @ViewBuilder
    private var modernResourceSections: some View {
        let favorites = favoriteResources
        if !favorites.isEmpty {
            Section(header: SectionPillHeader(
                title: "FAVORITES",
                count: favorites.count,
                icon: "star.fill",
                accentTitle: true,
                isExpanded: $showIslamFavorites
            )) {
                if showIslamFavorites {
                    resourceItems(favorites)
                }
            }
        }

        Section(header: SectionPillHeader(title: "ISLAMIC RESOURCES", count: IslamDestination.allCases.count)) {
            resourceItems(IslamDestination.allCases)
        }
    }

    @available(iOS 16.0, *)
    @ViewBuilder
    private func resourceItems(_ items: [IslamDestination]) -> some View {
        if settings.islamGridMode {
            // No contextMenu on the tiles: a context menu inside a LazyVGrid-in-a-List-row lifts the WHOLE
            // row (every tile at once) as the preview. Favoriting lives on the star inside each tile instead,
            // the same pattern the Arabic-letter and 99-Names grids use.
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Button {
                        settings.hapticFeedback()
                        islamPath.append(item)
                    } label: {
                        resourceGridTile(item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        } else {
            ForEach(items, id: \.self) { item in
                NavigationLink(value: item) {
                    toolLabel(item.title, systemImage: item.systemImage, subtitle: item.subtitle)
                }
                .contextMenu { favoriteToggleButton(item) }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    resourceSwipeFavoriteButton(item)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    resourceSwipeFavoriteButton(item)
                }
            }
        }
    }

    @available(iOS 16.0, *)
    private func resourceSwipeFavoriteButton(_ item: IslamDestination) -> some View {
        Button {
            settings.hapticFeedback()
            withAnimation(.easeInOut) {
                settings.toggleIslamResourceFavorite(item.rawValue)
            }
        } label: {
            Image(systemName: settings.isIslamResourceFavorite(item.rawValue) ? "star.fill" : "star")
        }
        .tint(settings.accentColor.color)
    }

    @available(iOS 16.0, *)
    private func resourceGridTile(_ item: IslamDestination) -> some View {
        VStack(spacing: 6) {
            AccentIconChip(systemImage: item.systemImage, size: 32)

            Text(item.gridTitle)
                .font(.caption2.weight(.medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2, reservesSpace: true)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        // Favorites are accent-tinted, everything else is clear - the same pattern as the surah, 99 Names,
        // and Arabic letter grids, so a favorite reads the same way everywhere.
        .conditionalGlassEffect(
            clear: !settings.isIslamResourceFavorite(item.rawValue),
            rectangle: true,
            useColor: settings.isIslamResourceFavorite(item.rawValue) ? 0.25 : nil,
            customTint: settings.isIslamResourceFavorite(item.rawValue) ? settings.accentColor.color : nil
        )
        .gridFavoriteStar(
            isFavorite: settings.isIslamResourceFavorite(item.rawValue),
            accent: settings.accentColor.color,
            accessibilityName: item.title
        ) {
            settings.toggleIslamResourceFavorite(item.rawValue)
        }
    }
    #endif

    #if os(iOS)
    @available(iOS 16.0, *)
    private var islamSidebar: some View {
        List(selection: $selectedResource) {
            Group {
            resourcesSectionSplit
            ProphetQuote()
            AlIslamAppsSection()
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Al-Islam")
    }

    @available(iOS 16.0, *)
    private var islamDetail: some View {
        // Re-identify the detail by the current selection so the split-view detail always rebuilds when the
        // sidebar selection changes. Without this the detail could get "stuck" on a previous item after the
        // view disappeared and came back on iPad/Mac.
        destinationView(for: selectedResource ?? .arabicAlphabet)
            .id(selectedResource ?? .arabicAlphabet)
    }

    @available(iOS 16.0, *)
    @ViewBuilder
    private func destinationView(for destination: IslamDestination) -> some View {
        switch destination {
        case .arabicAlphabet:
            ArabicView()
        case .tajweedFoundations:
            TajweedFoundationsView()
        case .commonAdhkar:
            AdhkarView()
        case .commonDuas:
            DuaView()
        case .tasbihCounter:
            TasbihView()
        // case .zakahCalculator:
        //     ZakahCalculatorView()
        case .namesOfAllah:
            NamesView()
        case .hijriCalendarConverter:
            DateView()
        case .masjidLocator:
            PlaceLocatorView(profile: .masjid)
        case .halalFoodLocator:
            PlaceLocatorView(profile: .halalFood)
        case .islamicWallpapers:
            WallpaperView()
        case .pillarsAndBasics:
            PillarsView()
        case .howToGuides:
            GuidesView()
        }
    }
    #endif

    private var resourcesSection: some View {
        Section(header: Text("ISLAMIC RESOURCES")) {
            resourceLink(title: "Arabic Alphabet", systemImage: "textformat.size.ar") {
                ArabicView()
            }

            resourceLink(title: "Tajweed Foundations", systemImage: "waveform") {
                TajweedFoundationsView()
            }

            resourceLink(title: "Dhikr & Remembrances", systemImage: "book.closed") {
                AdhkarView()
            }

            resourceLink(title: "Dua & Supplications", systemImage: "text.book.closed") {
                DuaView()
            }

            resourceLink(title: "Tasbih Counter", systemImage: "circles.hexagonpath.fill") {
                TasbihView()
            }

            // #if os(iOS)
            // resourceLink(title: "Zakah Calculator", systemImage: "percent") {
            //     ZakahCalculatorView()
            // }
            // #endif

            resourceLink(title: "99 Names of Allah", systemImage: "signature") {
                NamesView()
            }

            #if os(iOS)
            resourceLink(title: "Hijri Date Converter", systemImage: "calendar") {
                DateView()
            }

            resourceLink(title: "Masjid Locator", systemImage: "mappin.and.ellipse") {
                PlaceLocatorView(profile: .masjid)
            }

            resourceLink(title: "Halal Food Locator", systemImage: "fork.knife") {
                PlaceLocatorView(profile: .halalFood)
            }
            #endif

            resourceLink(title: "Islamic Wallpapers", systemImage: "photo.on.rectangle") {
                WallpaperView()
            }

            resourceLink(title: "Pillars & Beliefs", systemImage: "moon.stars") {
                PillarsView()
            }

            resourceLink(title: "How-To Guides", systemImage: "list.bullet.rectangle") {
                GuidesView()
            }
        }
    }

    #if os(iOS)
    @available(iOS 16.0, *)
    @ViewBuilder
    private var resourcesSectionSplit: some View {
        // The sidebar stays a list whatever the grid toggle says - a two-column grid crammed into a sidebar
        // column reads worse than rows - but it shares the favorites and the context menu with the iPhone.
        let favorites = favoriteResources
        if !favorites.isEmpty {
            Section(header: Text("FAVORITES")) {
                ForEach(favorites, id: \.self) { splitResourceLink($0) }
            }
        }

        Section(header: Text("ISLAMIC RESOURCES")) {
            ForEach(IslamDestination.allCases, id: \.self) { splitResourceLink($0) }
        }
    }

    @available(iOS 16.0, *)
    private func splitResourceLink(_ value: IslamDestination) -> some View {
        Button {
            settings.hapticFeedback()
            withAnimation(.easeInOut) {
                selectedResource = value
            }
        } label: {
            toolLabel(value.title, systemImage: value.systemImage)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .tag(value)
        .contextMenu { favoriteToggleButton(value) }
    }
    #endif

    private func resourceLink<Destination: View>(
        title: String,
        systemImage: String,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        // The destination is wrapped so it is built only when the row is actually pushed. The plain
        // `NavigationLink(destination:)` initializer evaluates its destination immediately, which meant every
        // body pass of this list constructed all nine destination views - the watch's swipe-into-this-tab
        // hitch (iOS 16+ uses the lazy `navigationDestination(for:)` path instead and never hit this).
        NavigationLink(destination: LazyDestination(build: destination)) {
            toolLabel(title, systemImage: systemImage)
        }
    }

    private func toolLabel(_ title: String, systemImage: String, subtitle: String? = nil) -> some View {
        HStack(spacing: 12) {
            AccentIconChip(systemImage: systemImage)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .foregroundColor(.primary)

                // The caption column is an iPhone luxury - the 40mm screen has no room for it.
                #if os(iOS)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                #endif
            }
        }
        .padding(.vertical, 3)
    }
}

/// The quote card sits between two first-accent sections (resources above, apps below), so it is the screen's
/// second-accent section - every tint in here reads from `accent2`.
struct ProphetQuote: View {
    @ObservedObject var settings = Settings.shared
    @State private var isCardVisible = false
    @State private var animateBadge = false
    @State private var rotateRing = false

    private let quoteText = "“O people, your Lord is one and your father Adam is one. There is no superiority of an Arab over a non-Arab, nor of a non-Arab over an Arab, nor of a red man over a black man, nor of a black man over a red man, except by taqwa.“"
    private let attributionText1 = "Farewell Sermon\nMusnad Ahmad 22978"
    private let attributionText2 = "Jumuah, 9 Dhul-Hijjah 10 AH\nFriday, 6 March 632 CE"

    var body: some View {
        Section(header: Text("PROPHET MUHAMMAD ﷺ QUOTE")) {
            ZStack {
                if #available(iOS 26.0, *) {
                    quoteCardBackground
                }

                VStack(alignment: .center, spacing: 12) {
                    quoteBadge
                    quoteBody
                    attribution
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 16)
                .conditionalGlassEffect(rectangle: true, useColor: 0.16)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 2)
            .scaleEffect(isCardVisible ? 1 : 0.97)
            .opacity(isCardVisible ? 1 : 0.9)
            .offset(y: isCardVisible ? 0 : 10)
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: isCardVisible)
            .onAppear {
                isCardVisible = true
                // Purely decorative; in Low Power Mode two forever-animations are exactly the CPU the system
                // is asking apps not to spend. The card renders identically, just still.
                // Never on the watch: its paging TabView fires onAppear/onDisappear on every swipe, so these
                // forever-animations were being torn down and restarted each tab change - a steady CPU drain
                // that read as the Quran → Islam swipe lag.
                #if os(watchOS)
                return
                #else
                guard !AppPerformance.shouldReduceAnimations else { return }
                withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                    animateBadge = true
                }
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                    rotateRing = true
                }
                #endif
            }
            .onDisappear {
                withAnimation {
                    isCardVisible = false
                    animateBadge = false
                }
                rotateRing = false
            }
        }
        #if os(iOS)
        .contextMenu {
            Text("Copy")
                .foregroundStyle(.secondary)

            Button {
                UIPasteboard.general.string = "O people, your Lord is one and your father Adam is one. There is no superiority of an Arab over a non-Arab, nor of a non-Arab over an Arab, nor of a red man over a black man, nor of a black man over a red man, except by taqwa.\n\n– Farewell Sermon\nMusnad Ahmad 22978\n\nJumuah, 9 Dhul-Hijjah 10 AH\nFriday, 6 March 632 CE"
            } label: {
                Label("Copy Text", systemImage: "doc.on.doc")
            }
        }
        #endif
    }

    private var quoteCardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        settings.accentColor.accent2.opacity(0.18),
                        Color.secondary.opacity(0.08),
                        settings.accentColor.accent2.opacity(0.08)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(settings.accentColor.accent2.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: settings.accentColor.accent2.opacity(0.12), radius: 10, x: 0, y: 3)
    }

    private var quoteBadge: some View {
        ZStack {
            // A slowly rotating shimmer ring behind the badge for a subtle "cool" glow.
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            settings.accentColor.accent2.opacity(0.0),
                            settings.accentColor.accent2.opacity(0.55),
                            settings.accentColor.accent2.opacity(0.0)
                        ]),
                        center: .center
                    ),
                    lineWidth: 2.5
                )
                .frame(width: 66, height: 66)
                .rotationEffect(.degrees(rotateRing ? 360 : 0))

            Circle()
                .strokeBorder(settings.accentColor.accent2, lineWidth: 1)
                .frame(width: 60, height: 60)

            Text("ﷺ")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(settings.accentColor.accent2)
                .padding()
                .clipShape(Circle())
        }
        .conditionalGlassEffect(circle: true)
        .scaleEffect(animateBadge ? 1.04 : 0.98)
        .shadow(color: settings.accentColor.accent2.opacity(animateBadge ? 0.45 : 0.12),
                radius: animateBadge ? 12 : 4)
        .padding(4)
    }

    private var quoteBody: some View {
        Text(quoteText)
            .font(.subheadline)
            .multilineTextAlignment(.center)
            .foregroundColor(settings.accentColor.accent2)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 2)
    }

    private var attribution: some View {
        VStack(spacing: 10) {
            Text(attributionText1)
                .foregroundColor(.primary)
                .font(.caption)

            Text(attributionText2)
                .foregroundColor(.secondary)
                .font(.caption2)
        }
        .multilineTextAlignment(.center)
        .lineLimit(nil)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 8)
    }
}

struct AlIslamAppsSection: View {
    @ObservedObject var settings = Settings.shared
    #if os(iOS)
    @State private var showLearnMoreSheet = false
    #endif
    @State private var popLeft = false
    @State private var popCenter = false
    @State private var popRight = false

    #if os(iOS)
    let spacing: CGFloat = 20
    #else
    let spacing: CGFloat = 10
    #endif

    var body: some View {
        Section(header: Text("AL-ISLAMIC APPS")) {
            ZStack {
                cardBackground

                VStack(spacing: 10) {
                    appCardsRow
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                    #if os(iOS)
                    Button {
                        settings.hapticFeedback()
                        showLearnMoreSheet = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles.rectangle.stack")
                            Text("Learn More")
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                    }
                    .contentShape(Rectangle())
                    .conditionalGlassEffect()
                    .padding([.horizontal, .bottom], 8)
                    #endif
                }
            }
            .conditionalGlassEffect(rectangle: true)
            .onAppear(perform: runAppCardsPopAnimation)
            .onDisappear {
                withAnimation {
                    popLeft = false
                    popCenter = false
                    popRight = false
                }
            }
            #if os(iOS)
            .sheet(isPresented: $showLearnMoreSheet) {
                SplashScreen()
            }
            #endif
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [.yellow.opacity(0.25), .green.opacity(0.25)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: .primary.opacity(0.25), radius: 5, x: 0, y: 1)
    }

    #if os(iOS)
    private var alIslamAppsCardBackgroundVerticalPadding: CGFloat {
        if #available(iOS 26.0, *) {
            return -11
        }
        return -2
    }
    #endif

    private var appCardsRow: some View {
        HStack(spacing: spacing) {
            if let url = URL(string: "https://apps.apple.com/us/app/al-adhan-prayer-times/id6475015493?platform=iphone") {
                Card(title: "Al-Adhan", url: url)
                    .frame(maxWidth: .infinity)
                    .scaleEffect(popLeft ? 1 : 0.2)
                    .offset(y: popLeft ? 0 : 80)
                    .opacity(popLeft ? 1 : 0.35)
                    .rotationEffect(.degrees(-6))
            }

            if let url = URL(string: "https://apps.apple.com/us/app/al-islam-islamic-pillars/id6449729655?platform=iphone") {
                Card(title: "Al-Islam", url: url)
                    .frame(maxWidth: .infinity)
                    .scaleEffect(popCenter ? 1.02 : 0.24)
                    .offset(y: popCenter ? 0 : 86)
                    .opacity(popCenter ? 1 : 0.4)
            }

            if let url = URL(string: "https://apps.apple.com/us/app/al-quran-beginner-quran/id6474894373?platform=iphone") {
                Card(title: "Al-Quran", url: url)
                    .frame(maxWidth: .infinity)
                    .scaleEffect(popRight ? 1 : 0.2)
                    .offset(y: popRight ? 0 : 80)
                    .opacity(popRight ? 1 : 0.35)
                    .rotationEffect(.degrees(6))
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 8)
        .padding(.horizontal)
    }

    private var popSpring: Animation {
        .spring(response: 0.52, dampingFraction: 0.62, blendDuration: 0)
    }

    private func runAppCardsPopAnimation() {
        // The watch's paging TabView re-fires onAppear on every swipe, and this section sits on BOTH the
        // Islam and Settings tabs - replaying a three-stage spring (plus decoding three card images) on
        // each swipe was a real slice of the tab-switch lag. The cards just show, settled.
        #if os(watchOS)
        popLeft = true
        popCenter = true
        popRight = true
        #else
        popLeft = false
        popCenter = false
        popRight = false

        withAnimation(popSpring) {
            popCenter = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(popSpring) {
                popLeft = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(popSpring) {
                popRight = true
            }
        }
        #endif
    }
}

private struct Card: View {
    @ObservedObject var settings = Settings.shared
    @Environment(\.openURL) private var openURL
    @State private var showActions = false

    let title: String
    let url: URL

    private var iconImage: UIImage? {
        UIImage(named: title)
    }

    var body: some View {
        VStack {
            Image(title)
                .resizable()
                .scaledToFit()
                .cornerRadius(18)
                .shadow(radius: 4)

            #if os(iOS)
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.top, 4)
            #endif
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                settings.hapticFeedback()
                openURL(url)
            }
        }
        #if os(iOS)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.4).onEnded { _ in
                settings.hapticFeedback()
                showActions = true
            }
        )
        .confirmationDialog(title, isPresented: $showActions, titleVisibility: .visible) {
            Button {
                UIPasteboard.general.string = url.absoluteString
                settings.hapticFeedback()
            } label: {
                Label("Copy Link", systemImage: "link")
            }

            if iconImage != nil {
                Button {
                    if let iconImage {
                        UIPasteboard.general.image = iconImage
                        settings.hapticFeedback()
                    }
                } label: {
                    Label("Copy Icon", systemImage: "doc.on.doc")
                }
            }

            Button("Cancel") { }
        }
        #endif
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: true) {
        IslamView()
    }
}
