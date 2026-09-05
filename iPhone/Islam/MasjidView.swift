#if os(iOS)
import SwiftUI
import MapKit
import CoreLocation
import UIKit
import Contacts

/// Everything that distinguishes one place locator from another - the Masjid Locator and the Halal Food
/// Locator are the same map, search, cache, and result UI over different queries and filters.
struct PlaceLocatorProfile {
    let title: String
    /// Shown next to the spinner in the results header.
    let loadingText: String
    /// Shown while the first search of an area is in flight.
    let searchingText: String
    let emptyText: String
    /// Stands in for a result whose POI has no name.
    let fallbackName: String
    let contextMenuTitle: String
    /// What an empty search bar looks for.
    let baseQueries: [String]
    /// How the user's own search text is expanded into queries.
    let queries: (String) -> [String]
    /// Post-filter on result names/titles. Empty means "trust MapKit's relevance ranking" - right for a
    /// query like "halal", where most matching restaurants don't carry the word in their name.
    let nameKeywords: [String]
    /// Category filter handed to MKLocalSearch. Nil means all point-of-interest kinds.
    let poiFilter: MKPointOfInterestFilter?
    /// Where the home-area results are cached, so each locator remembers its own neighbourhood.
    let homeCacheKey: String

    /// Mosques have no MKPointOfInterestCategory, so the masjid profile filters by name instead - including
    /// the Arabic spellings, which used to be dropped: a masjid named only مسجد… never matched the
    /// Latin-only keyword list even when MapKit returned it.
    static let masjid = PlaceLocatorProfile(
        title: "Masjid Locator",
        loadingText: "Loading masaajid…",
        searchingText: "Searching nearby masaajid…",
        emptyText: "No masaajid found in this area",
        fallbackName: "Masjid",
        contextMenuTitle: "Masjid Info",
        baseQueries: ["mosque", "masjid", "islamic center", "muslim", "rahma", "مسجد"],
        queries: { trimmed in
            var seen = Set<String>()
            return [
                trimmed,
                "\(trimmed) mosque",
                "\(trimmed) masjid",
                "\(trimmed) islamic",
                "\(trimmed) islamic center",
                "\(trimmed) muslim",
                "\(trimmed) rahma"
            ].filter { seen.insert($0).inserted }
        },
        nameKeywords: ["masjid", "mosque", "islam", "islamic", "muslim", "rahma", "مسجد", "جامع"],
        poiFilter: nil,
        homeCacheKey: "masjidLocatorHomeCacheData"
    )

    /// Food is the opposite shape from mosques: the category filter does the narrowing (restaurants, cafes,
    /// markets - not hotels and gas stations), and the "halal" relevance comes from the query itself, because
    /// most halal restaurants don't have "halal" in their NAME and a name filter would throw them away.
    static let halalFood = PlaceLocatorProfile(
        title: "Halal Food Locator",
        loadingText: "Loading halal places…",
        searchingText: "Searching nearby halal food…",
        emptyText: "No halal places found in this area",
        fallbackName: "Halal Place",
        contextMenuTitle: "Place Info",
        baseQueries: ["halal restaurant", "halal food", "halal market", "halal butcher", "حلال"],
        queries: { trimmed in
            var seen = Set<String>()
            return [
                "\(trimmed) halal",
                "halal \(trimmed)",
                trimmed
            ].filter { seen.insert($0).inserted }
        },
        // Food categories only - `.store` let any supermarket that ranked near a "halal X" query through,
        // and with no name filter there was nothing downstream to catch it. Halal butchers and groceries
        // are `.foodMarket`.
        nameKeywords: [],
        poiFilter: MKPointOfInterestFilter(including: [.restaurant, .cafe, .bakery, .foodMarket]),
        homeCacheKey: "halalLocatorHomeCacheData"
    )
}

struct PlaceLocatorView: View {
    @ObservedObject private var settings = Settings.shared
    /// Prayer times and the location publish from `LiveState`, not `Settings` (see its comment).
    @ObservedObject private var live = LiveState.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var sysScheme

    let profile: PlaceLocatorProfile

    @AppStorage private var homeCacheData: Data

    @State private var searchText = ""
    @State private var results = [MKMapItem]()
    @State private var selectedItem: MKMapItem?
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    /// The map opened without a fix (fresh install, or permission granted just now); when the first real
    /// location arrives, recenter on it once and re-search - without this, a first-time user stared at the
    /// Kaaba fallback with no nearby results and no way to know why.
    @State private var awaitingFirstFix = false

    @State private var region = MKCoordinateRegion(
        center: .init(latitude: 21.422445, longitude: 39.826388),
        span: .init(latitudeDelta: 0.15, longitudeDelta: 0.15)
    )

    private static let homeCacheMatchDistanceMeters: CLLocationDistance = 150
    private static let homeRefreshRadiusMeters: CLLocationDistance = 10_000

    private var scheme: ColorScheme { settings.colorScheme ?? sysScheme }

    private var homeCoordinate: CLLocationCoordinate2D? {
        settings.homeLocation?.coordinate
    }

    init(profile: PlaceLocatorProfile) {
        self.profile = profile
        _homeCacheData = AppStorage(wrappedValue: Data(), profile.homeCacheKey)

        let coord: CLLocationCoordinate2D = {
            let s = Settings.shared
            if let cur = s.currentLocation, cur.latitude != 1000, cur.longitude != 1000 {
                return cur.coordinate
            }
            if let home = s.homeLocation {
                return home.coordinate
            }
            return .init(latitude: 21.422445, longitude: 39.826388)
        }()

        _region = State(initialValue: MKCoordinateRegion(
            center: coord,
            span: .init(latitudeDelta: 0.15, longitudeDelta: 0.15)
        ))
    }

    private var hasRealLocation: Bool {
        if let cur = live.currentLocation, cur.latitude != 1000, cur.longitude != 1000 { return true }
        return false
    }

    private struct MarkerItem: Identifiable {
        let id: String
        let coordinate: CLLocationCoordinate2D
        let tint: Color
        let systemImage: String
    }

    private struct CachedPlaceItem: Codable, Equatable {
        let name: String?
        let latitude: Double
        let longitude: Double
        let subThoroughfare: String?
        let thoroughfare: String?
        let locality: String?
        let administrativeArea: String?
        let postalCode: String?
        let country: String?

        init(item: MKMapItem) {
            name = item.name
            latitude = item.placemark.coordinate.latitude
            longitude = item.placemark.coordinate.longitude
            subThoroughfare = item.placemark.subThoroughfare
            thoroughfare = item.placemark.thoroughfare
            locality = item.placemark.locality
            administrativeArea = item.placemark.administrativeArea
            postalCode = item.placemark.postalCode
            country = item.placemark.country
        }

        func mapItem() -> MKMapItem {
            let address = CNMutablePostalAddress()
            address.street = [subThoroughfare, thoroughfare]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            address.city = locality ?? ""
            address.state = administrativeArea ?? ""
            address.postalCode = postalCode ?? ""
            address.country = country ?? ""

            let placemark = MKPlacemark(
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                postalAddress: address
            )
            let item = MKMapItem(placemark: placemark)
            item.name = name
            return item
        }
    }

    private struct CachedPlaceHomeResults: Codable, Equatable {
        let homeLocation: Location
        let savedAt: Date
        let items: [CachedPlaceItem]
    }

    private struct AnimatedMarkerBubble: View {
        let tint: Color
        let systemImage: String

        @State private var isVisible = false

        var body: some View {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(9)
                .background(Circle().fill(tint))
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.9), lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.18), radius: 6, y: 2)
                .scaleEffect(isVisible ? 1 : 0.72)
                .opacity(isVisible ? 1 : 0)
                .onAppear {
                    withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                        isVisible = true
                    }
                }
        }
    }

    private var markers: [MarkerItem] {
        var items: [MarkerItem] = []

        if let cur = live.currentLocation,
           cur.latitude != 1000,
           cur.longitude != 1000 {
            items.append(
                MarkerItem(
                    id: "current",
                    coordinate: cur.coordinate,
                    tint: .cyan,
                    systemImage: "location.fill"
                )
            )
        }

        items += results.enumerated().map { index, item in
            MarkerItem(
                id: "result-\(index)-\(item.placemark.coordinate.latitude)-\(item.placemark.coordinate.longitude)",
                coordinate: item.placemark.coordinate,
                tint: settings.accentColor.color,
                systemImage: "mappin.circle.fill"
            )
        }

        if let selectedItem {
            items.insert(
                MarkerItem(
                    id: "selected",
                    coordinate: selectedItem.placemark.coordinate,
                    tint: .green,
                    systemImage: "mappin.circle.fill"
                ),
                at: 0
            )
        }

        return items
    }

    var body: some View {
        mapContent
            .edgesIgnoringSafeArea(.all)
            .overlay(alignment: .top) {
                searchOverlay
            }
            .adaptiveSafeArea(edge: .bottom) {
                actionInset
            }
            .navigationTitle(profile.title)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // This screen is all about "near me", so it asks for location itself instead of assuming the
                // prayer-times flow already did. No-op when already granted or denied.
                settings.requestLocationAuthorization()
                awaitingFirstFix = !hasRealLocation
                configureInitialRegion()
                loadCachedHomeResultsIfPossible()
                scheduleSearch(for: "", force: true)
                warmHomeCacheIfNeeded()
            }
            .onChange(of: searchText) { newValue in
                scheduleSearch(for: newValue, force: false)
            }
            // A fan-out of ~6 concurrent MKLocalSearch requests started just before leaving would run to
            // completion for a screen nobody is looking at - cancel it with the screen.
            .onDisappear { searchTask?.cancel() }
            .onReceive(live.$currentLocation) { location in
                guard awaitingFirstFix,
                      let location, location.latitude != 1000, location.longitude != 1000 else { return }
                awaitingFirstFix = false
                updateRegion(to: location.coordinate)
                scheduleSearch(for: searchText, force: true)
            }
            .preferredColorScheme(scheme)
            .accentColor(settings.accentColor.color)
            .tint(settings.accentColor.color)
    }

    private var mapContent: some View {
        Map(coordinateRegion: $region, annotationItems: markers) { item in
            MapAnnotation(coordinate: item.coordinate) {
                markerBubble(for: item)
            }
        }
    }

    private var searchOverlay: some View {
        VStack(alignment: .leading, spacing: 10) {
            searchPanel
            if shouldShowResultsPanel {
                resultsPanel
            }
        }
        .conditionalGlassEffect(rectangle: true)
        .padding(.horizontal)
    }

    private var searchPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            SearchBar(text: $searchText.animation(.easeInOut))

            if shouldShowResultsPanel {
                HStack {
                    if isSearching {
                        Text(profile.loadingText)
                    } else {
                        Text("\(results.count) match\(results.count == 1 ? "" : "es") found")
                    }

                    Spacer()
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(settings.accentColor.color)
                .padding(.horizontal, 6)
            }
        }
        .padding(8)
        .padding(.bottom, -8)
    }

    private var actionInset: some View {
        VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
            actionButtonsRow
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .padding(.horizontal)
        .padding(.bottom, 26)
    }

    private var actionButtonsRow: some View {
        HStack {
            Button {
                settings.hapticFeedback()
                scheduleSearch(for: searchText, force: true)
            } label: {
                Label("Search This Area", systemImage: "magnifyingglass")
                    .frame(maxWidth: .infinity)
            }
            .font(.headline)
            .foregroundColor(settings.accentColor.color)
            .padding()
            .conditionalGlassEffect()

            Button {
                settings.hapticFeedback()
                if hasRealLocation {
                    centerOnCurrentLocation()
                    scheduleSearch(for: searchText, force: true)
                } else {
                    // Nothing to center on: ask (again) rather than silently doing nothing, and let the
                    // first-fix hook above finish the job when a location arrives.
                    settings.requestLocationAuthorization()
                    awaitingFirstFix = true
                }
            } label: {
                Label("Near Me", systemImage: "location.fill")
                    .frame(maxWidth: .infinity)
            }
            .font(.headline)
            .foregroundColor(settings.accentColor.color)
            .padding()
            .conditionalGlassEffect()
        }
    }

    private var shouldShowResultsPanel: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSearching || !results.isEmpty
    }

    private func markerBubble(for item: MarkerItem) -> some View {
        AnimatedMarkerBubble(tint: item.tint, systemImage: item.systemImage)
    }

    private var resultsPanel: some View {
        Group {
            if isSearching && results.isEmpty {
                HStack(spacing: 10) {
                    ProgressView()
                    Text(profile.searchingText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else if results.isEmpty {
                Text(profile.emptyText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.subheadline)
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        // Identity by object, not position: when a new search replaces `results`, rows are
                        // replaced rather than morphing one place's text into another's in place.
                        ForEach(results, id: \.self) { item in
                            HStack(alignment: .top, spacing: 10) {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "mappin.and.ellipse")
                                        .foregroundColor(settings.accentColor.color)

                                    VStack(alignment: .leading, spacing: 3) {
                                        HighlightedSnippet(
                                            source: item.name ?? profile.fallbackName,
                                            term: searchText,
                                            font: .subheadline.weight(.semibold),
                                            accent: settings.accentColor.color,
                                            fg: .primary
                                        )
                                            .multilineTextAlignment(.leading)

                                        HighlightedSnippet(
                                            source: formattedAddress(for: item),
                                            term: searchText,
                                            font: .caption,
                                            accent: settings.accentColor.color,
                                            fg: .secondary
                                        )
                                            .multilineTextAlignment(.leading)

                                        if let distance = distanceFromCurrentLocation(to: item) {
                                            Label(distance, systemImage: "location")
                                                .font(.caption2)
                                                .foregroundColor(settings.accentColor.color)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    select(item)
                                }

                                Button {
                                    settings.hapticFeedback()
                                    openInMaps(item)
                                } label: {
                                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                        .font(.headline)
                                        .foregroundColor(settings.accentColor.color)
                                        .frame(width: 36, height: 36)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding()
                            .contextMenu {
                                Text(profile.contextMenuTitle)
                                    .foregroundStyle(.secondary)

                                Button {
                                    settings.hapticFeedback()
                                    UIPasteboard.general.string = item.name ?? profile.fallbackName
                                } label: {
                                    Label("Copy Name", systemImage: "doc.on.doc")
                                }

                                Button {
                                    settings.hapticFeedback()
                                    UIPasteboard.general.string = formattedAddress(for: item)
                                } label: {
                                    Label("Copy Address", systemImage: "doc.on.doc")
                                }

                                Button {
                                    settings.hapticFeedback()
                                    UIPasteboard.general.string = fullAddress(for: item)
                                } label: {
                                    Label("Copy Full Address", systemImage: "doc.on.doc")
                                }
                            }
                        }
                    }
                }
                .frame(height: min(CGFloat(results.count) * 76, 150))
            }
        }
    }

    private func centerOnCurrentLocation() {
        if let cur = live.currentLocation, cur.latitude != 1000, cur.longitude != 1000 {
            updateRegion(to: cur.coordinate)
        } else if let home = settings.homeLocation {
            updateRegion(to: home.coordinate)
        }
    }

    private func select(_ item: MKMapItem) {
        settings.hapticFeedback()
        withAnimation {
            selectedItem = item
            updateRegion(to: item.placemark.coordinate)
        }
    }

    private func openInMaps(_ item: MKMapItem) {
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    private func formattedAddress(for item: MKMapItem) -> String {
        let streetParts = [
            item.placemark.subThoroughfare,
            item.placemark.thoroughfare
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

        let street = streetParts.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)

        let parts = [
            street.isEmpty ? nil : street,
            item.placemark.locality,
            item.placemark.country
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }

        if parts.isEmpty {
            return "Address unavailable"
        }

        return Array(NSOrderedSet(array: parts)).compactMap { $0 as? String }.joined(separator: ", ")
    }

    private func fullAddress(for item: MKMapItem) -> String {
        let streetParts = [
            item.placemark.subThoroughfare,
            item.placemark.thoroughfare
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

        let street = streetParts.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)

        let parts = [
            street.isEmpty ? nil : street,
            item.placemark.locality,
            item.placemark.administrativeArea,
            item.placemark.postalCode,
            item.placemark.country
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }

        if parts.isEmpty {
            return formattedAddress(for: item)
        }

        return Array(NSOrderedSet(array: parts)).compactMap { $0 as? String }.joined(separator: ", ")
    }

    private func distanceFromCurrentLocation(to item: MKMapItem) -> String? {
        guard let cur = live.currentLocation,
              cur.latitude != 1000,
              cur.longitude != 1000 else { return nil }

        let here = CLLocation(latitude: cur.latitude, longitude: cur.longitude)
        let there = CLLocation(
            latitude: item.placemark.coordinate.latitude,
            longitude: item.placemark.coordinate.longitude
        )

        let miles = here.distance(from: there) / 1_609.344
        return String(format: "%.1f miles away", miles)
    }

    private func updateRegion(to coord: CLLocationCoordinate2D) {
        region = .init(center: coord, span: .init(latitudeDelta: 0.08, longitudeDelta: 0.08))
    }

    private func configureInitialRegion() {
        centerOnCurrentLocation()
    }

    private func search(for text: String) async {
        let searchRegion = region
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Read main-actor state (settings, region) before hopping off; the fan-out, filtering, and
        // distance sort all run in `performPlaceSearch`, off the main actor.
        let sortOrigin: CLLocationCoordinate2D? = {
            guard trimmed.isEmpty else { return nil }
            if let cur = live.currentLocation, cur.latitude != 1000, cur.longitude != 1000 {
                return cur.coordinate
            }
            if let homeCoordinate {
                return homeCoordinate
            }
            return searchRegion.center
        }()

        let items = await performPlaceSearch(
            queries: trimmed.isEmpty ? profile.baseQueries : profile.queries(trimmed),
            nameKeywords: profile.nameKeywords,
            poiFilter: profile.poiFilter,
            in: searchRegion,
            sortOrigin: sortOrigin
        )

        guard !Task.isCancelled else { return }

        withAnimation {
            results = items
            isSearching = false
            if selectedItem == nil || !items.contains(where: { isSameItem($0, selectedItem) }) {
                selectedItem = items.first
            }
        }
        // The encode + UserDefaults write has no business inside an animation transaction.
        persistHomeCacheIfNeeded(items: items, query: text, region: searchRegion)
    }

    private func scheduleSearch(for text: String, force: Bool) {
        searchTask?.cancel()
        searchTask = Task {
            await MainActor.run { isSearching = true }
            if !force {
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
            guard !Task.isCancelled else { return }
            await search(for: text)
        }
    }

    private func loadCachedHomeResultsIfPossible() {
        guard searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              results.isEmpty,
              isRegionNearHome(region),
              let cache = decodeHomeCache(),
              isSameHome(cache.homeLocation, settings.homeLocation) else { return }

        let cachedItems = cache.items.map { $0.mapItem() }
        guard !cachedItems.isEmpty else { return }

        results = cachedItems
        if selectedItem == nil {
            selectedItem = cachedItems.first
        }
    }

    private func warmHomeCacheIfNeeded() {
        // Reduced tier: the visible search is enough traffic; the home cache refreshes on a full-tier
        // visit or when the map opens at home (Performance Guide, Phase 6 step 13).
        guard !AppPerformance.shouldAvoidBroadPrewarm, let home = settings.homeLocation else { return }
        // When the map opened near home, the live search running right now covers the same area and
        // already persists into the cache (`persistHomeCacheIfNeeded` uses the same radius) - a second
        // identical five-query fan-out would just double the MKLocalSearch traffic. Warm only when the
        // map opened somewhere else, so the cache is still fresh for the next open at home.
        guard !isRegionNearHome(region) else { return }

        let profile = profile
        Task(priority: .utility) {
            let homeRegion = MKCoordinateRegion(
                center: home.coordinate,
                span: .init(latitudeDelta: 0.15, longitudeDelta: 0.15)
            )
            let items = await performPlaceSearch(
                queries: profile.baseQueries,
                nameKeywords: profile.nameKeywords,
                poiFilter: profile.poiFilter,
                in: homeRegion,
                sortOrigin: nil
            )
            guard !items.isEmpty else { return }

            let cache = CachedPlaceHomeResults(
                homeLocation: home,
                savedAt: Date(),
                items: items.map(CachedPlaceItem.init)
            )

            if let data = try? Settings.encoder.encode(cache) {
                await MainActor.run {
                    homeCacheData = data
                }
            }
        }
    }

    private func decodeHomeCache() -> CachedPlaceHomeResults? {
        guard !homeCacheData.isEmpty else { return nil }
        return try? Settings.decoder.decode(CachedPlaceHomeResults.self, from: homeCacheData)
    }

    private func persistHomeCacheIfNeeded(items: [MKMapItem], query: String, region: MKCoordinateRegion) {
        guard query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let home = settings.homeLocation,
              coordinateDistance(region.center, home.coordinate) <= Self.homeRefreshRadiusMeters else { return }

        let cache = CachedPlaceHomeResults(
            homeLocation: home,
            savedAt: Date(),
            items: items.map(CachedPlaceItem.init)
        )

        if let data = try? Settings.encoder.encode(cache) {
            homeCacheData = data
        }
    }

    private func isSameHome(_ lhs: Location, _ rhs: Location?) -> Bool {
        guard let rhs else { return false }
        return coordinateDistance(lhs.coordinate, rhs.coordinate) <= Self.homeCacheMatchDistanceMeters
    }

    private func isRegionNearHome(_ region: MKCoordinateRegion) -> Bool {
        guard let homeCoordinate else { return false }
        return coordinateDistance(region.center, homeCoordinate) <= Self.homeRefreshRadiusMeters
    }

    private func coordinateDistance(_ lhs: CLLocationCoordinate2D, _ rhs: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: lhs.latitude, longitude: lhs.longitude)
            .distance(from: CLLocation(latitude: rhs.latitude, longitude: rhs.longitude))
    }

    private func isSameItem(_ lhs: MKMapItem, _ rhs: MKMapItem?) -> Bool {
        guard let rhs else { return false }
        let lhsName = lhs.name ?? ""
        let rhsName = rhs.name ?? ""
        let lhsCoordinate = lhs.placemark.coordinate
        let rhsCoordinate = rhs.placemark.coordinate
        return lhsName == rhsName
            && abs(lhsCoordinate.latitude - rhsCoordinate.latitude) < 0.000_001
            && abs(lhsCoordinate.longitude - rhsCoordinate.longitude) < 0.000_001
    }
}

/// The shared search core for the live search and the home-cache warmer. Top-level (not a `View` member,
/// which would pin it to the main actor): the queries fan out concurrently instead of serially - the
/// wall-clock cost is one round-trip, not five to seven - and the filter/dedup/sort never touch the main
/// thread. Result order is kept deterministic by reassembling buckets in query order.
private func performPlaceSearch(
    queries: [String],
    nameKeywords: [String],
    poiFilter: MKPointOfInterestFilter?,
    in searchRegion: MKCoordinateRegion,
    sortOrigin: CLLocationCoordinate2D?,
    limit: Int = 12
) async -> [MKMapItem] {
    var buckets = [[MKMapItem]](repeating: [], count: queries.count)
    // Five or six MKLocalSearch requests in flight at once on the full tier; two at a time on the
    // reduced tier, where the radio and the CPU are what Low Power Mode is rationing.
    let maxInFlight = AppPerformance.shouldAvoidBroadPrewarm ? 2 : queries.count

    await withTaskGroup(of: (Int, [MKMapItem]).self) { group in
        var inFlight = 0
        for (index, query) in queries.enumerated() {
            if inFlight >= maxInFlight, let (doneIndex, items) = await group.next() {
                buckets[doneIndex] = items
                inFlight -= 1
            }
            group.addTask {
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = query
                request.resultTypes = .pointOfInterest
                request.region = searchRegion
                if let poiFilter {
                    request.pointOfInterestFilter = poiFilter
                }

                let response = try? await MKLocalSearch(request: request).start()
                return (index, response?.mapItems ?? [])
            }
            inFlight += 1
        }
        for await (index, items) in group {
            buckets[index] = items
        }
    }

    guard !Task.isCancelled else { return [] }

    let matching = buckets.joined().filter { item in
        guard !nameKeywords.isEmpty else { return true }
        let name = (item.name ?? "").lowercased()
        let title = (item.placemark.title ?? "").lowercased()
        return nameKeywords.contains { keyword in
            name.contains(keyword) || title.contains(keyword)
        }
    }

    var seen = Set<String>()
    let unique = matching.filter { item in
        let key = "\(item.name ?? "")|\(item.placemark.coordinate.latitude)|\(item.placemark.coordinate.longitude)"
        return seen.insert(key).inserted
    }

    guard let sortOrigin else { return Array(unique.prefix(limit)) }

    let origin = CLLocation(latitude: sortOrigin.latitude, longitude: sortOrigin.longitude)
    let sorted = unique
        .map { item -> (MKMapItem, CLLocationDistance) in
            let coord = item.placemark.coordinate
            return (item, origin.distance(from: CLLocation(latitude: coord.latitude, longitude: coord.longitude)))
        }
        .sorted { $0.1 < $1.1 }
        .map { $0.0 }

    return Array(sorted.prefix(limit))
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        PlaceLocatorView(profile: .masjid)
    }
}
#endif
