#if os(iOS)
import SwiftUI
import MapKit
import CoreLocation
import UIKit
import Contacts

struct MasjidLocatorView: View {
    @ObservedObject private var settings = Settings.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var sysScheme

    @AppStorage("masjidLocatorHomeCacheData") private var homeCacheData = Data()

    @State private var searchText = ""
    @State private var results = [MKMapItem]()
    @State private var selectedItem: MKMapItem?
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?

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

    init() {
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

    private struct MarkerItem: Identifiable {
        let id: String
        let coordinate: CLLocationCoordinate2D
        let tint: Color
        let systemImage: String
    }

    private struct CachedMasjidItem: Codable, Equatable {
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

    private struct CachedMasjidHomeResults: Codable, Equatable {
        let homeLocation: Location
        let savedAt: Date
        let items: [CachedMasjidItem]
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

        if let cur = settings.currentLocation,
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
            .navigationTitle("Masjid Locator")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                configureInitialRegion()
                loadCachedHomeResultsIfPossible()
                scheduleSearch(for: "", force: true)
                warmHomeCacheIfNeeded()
            }
            .onChange(of: searchText) { newValue in
                scheduleSearch(for: newValue, force: false)
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
                .padding(-8)

            if shouldShowResultsPanel {
                HStack {
                    if isSearching {
                        Text("Loading masaajid…")
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
                centerOnCurrentLocation()
                scheduleSearch(for: searchText, force: true)
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
                    Text("Searching nearby masaajid…")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else if results.isEmpty {
                Text("No masaajid found in this area")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.subheadline)
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(results.enumerated()), id: \.offset) { _, item in
                            HStack(alignment: .top, spacing: 10) {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "mappin.and.ellipse")
                                        .foregroundColor(settings.accentColor.color)

                                    VStack(alignment: .leading, spacing: 3) {
                                        HighlightedSnippet(
                                            source: item.name ?? "Masjid",
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
                                Text("Masjid Info")
                                    .foregroundStyle(.secondary)

                                Button {
                                    settings.hapticFeedback()
                                    UIPasteboard.general.string = item.name ?? "Masjid"
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
        if let cur = settings.currentLocation, cur.latitude != 1000, cur.longitude != 1000 {
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
        guard let cur = settings.currentLocation,
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
        let items = await performSearch(for: text, in: searchRegion)

        guard !Task.isCancelled else { return }

        await MainActor.run {
            withAnimation {
                results = items
                isSearching = false
                if selectedItem == nil || !items.contains(where: { isSameItem($0, selectedItem) }) {
                    selectedItem = items.first
                }
                persistHomeCacheIfNeeded(items: items, query: text, region: searchRegion)
            }
        }
    }

    private func performSearch(for text: String, in searchRegion: MKCoordinateRegion) async -> [MKMapItem] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let queries: [String] = {
            if trimmed.isEmpty {
                return ["mosque", "masjid", "islamic center", "muslim", "rahma"]
            } else {
                return Array(NSOrderedSet(array: [
                    trimmed,
                    "\(trimmed) mosque",
                    "\(trimmed) masjid",
                    "\(trimmed) islamic",
                    "\(trimmed) islamic center",
                    "\(trimmed) muslim",
                    "\(trimmed) rahma"
                ])).compactMap { $0 as? String }
            }
        }()

        var combinedItems: [MKMapItem] = []

        for query in queries {
            guard !Task.isCancelled else { return [] }

            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.resultTypes = .pointOfInterest
            request.region = searchRegion

            let response = try? await MKLocalSearch(request: request).start()
            combinedItems.append(contentsOf: response?.mapItems ?? [])
        }

        let items = combinedItems.filter { item in
            let name = (item.name ?? "").lowercased()
            let title = (item.placemark.title ?? "").lowercased()
            let keywords = ["masjid", "mosque", "islam", "islamic", "muslim", "rahma"]
            return keywords.contains { keyword in
                name.contains(keyword) || title.contains(keyword)
            }
        }

        var seen = Set<String>()
        let unique = items.filter { item in
            let key = "\(item.name ?? "")|\(item.placemark.coordinate.latitude)|\(item.placemark.coordinate.longitude)"
            return seen.insert(key).inserted
        }

        if trimmed.isEmpty {
            let originCoordinate: CLLocationCoordinate2D = {
                if let cur = settings.currentLocation,
                   cur.latitude != 1000,
                   cur.longitude != 1000 {
                    return cur.coordinate
                }
                if let homeCoordinate {
                    return homeCoordinate
                }
                return searchRegion.center
            }()

            let origin = CLLocation(latitude: originCoordinate.latitude, longitude: originCoordinate.longitude)
            let sortedByDistance = unique.sorted { lhs, rhs in
                let lhsDistance = origin.distance(from: CLLocation(
                    latitude: lhs.placemark.coordinate.latitude,
                    longitude: lhs.placemark.coordinate.longitude
                ))
                let rhsDistance = origin.distance(from: CLLocation(
                    latitude: rhs.placemark.coordinate.latitude,
                    longitude: rhs.placemark.coordinate.longitude
                ))
                return lhsDistance < rhsDistance
            }

            return Array(sortedByDistance.prefix(12))
        }

        return Array(unique.prefix(12))
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
        guard let home = settings.homeLocation else { return }

        Task(priority: .utility) {
            let homeRegion = MKCoordinateRegion(
                center: home.coordinate,
                span: .init(latitudeDelta: 0.15, longitudeDelta: 0.15)
            )
            let items = await performHomeCacheRefresh(for: homeRegion)
            guard !items.isEmpty else { return }

            let cache = CachedMasjidHomeResults(
                homeLocation: home,
                savedAt: Date(),
                items: items.map(CachedMasjidItem.init)
            )

            if let data = try? Settings.encoder.encode(cache) {
                await MainActor.run {
                    homeCacheData = data
                }
            }
        }
    }

    private func decodeHomeCache() -> CachedMasjidHomeResults? {
        guard !homeCacheData.isEmpty else { return nil }
        return try? Settings.decoder.decode(CachedMasjidHomeResults.self, from: homeCacheData)
    }

    private func persistHomeCacheIfNeeded(items: [MKMapItem], query: String, region: MKCoordinateRegion) {
        guard query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let home = settings.homeLocation,
              coordinateDistance(region.center, home.coordinate) <= Self.homeRefreshRadiusMeters else { return }

        let cache = CachedMasjidHomeResults(
            homeLocation: home,
            savedAt: Date(),
            items: items.map(CachedMasjidItem.init)
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

private func performHomeCacheRefresh(for searchRegion: MKCoordinateRegion) async -> [MKMapItem] {
    let queries = ["mosque", "masjid", "islamic center", "muslim", "rahma"]
    var combinedItems: [MKMapItem] = []

    for query in queries {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest
        request.region = searchRegion

        let response = try? await MKLocalSearch(request: request).start()
        combinedItems.append(contentsOf: response?.mapItems ?? [])
    }

    let items = combinedItems.filter { item in
        let name = (item.name ?? "").lowercased()
        let title = (item.placemark.title ?? "").lowercased()
        let keywords = ["masjid", "mosque", "islam", "islamic", "muslim", "rahma"]
        return keywords.contains { keyword in
            name.contains(keyword) || title.contains(keyword)
        }
    }

    var seen = Set<String>()
    let unique = items.filter { item in
        let key = "\(item.name ?? "")|\(item.placemark.coordinate.latitude)|\(item.placemark.coordinate.longitude)"
        return seen.insert(key).inserted
    }

    return Array(unique.prefix(12))
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        MasjidLocatorView()
    }
}
#endif
