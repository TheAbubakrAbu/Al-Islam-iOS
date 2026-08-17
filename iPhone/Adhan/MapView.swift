#if os(iOS)
import SwiftUI
import MapKit
import CoreLocation
import UIKit

struct MapView: View {
    @ObservedObject private var settings = Settings.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var systemScheme

    @State private var searchText = ""
    @State private var cityItems: [MKMapItem] = []
    @State private var selectedItem: MKMapItem?
    @State private var showAlert = false
    @State private var searchTask: Task<Void, Never>?
    @State private var choosingPrayerTimes: Bool
    @State private var region: MKCoordinateRegion

    /// When set, tapping a city calls this instead of setting homeLocation.
    var onSelectCity: ((Location) -> Void)? = nil

    private let kaabaCoordinate = CLLocationCoordinate2D(latitude: 21.422445, longitude: 39.826388)

    private static let distanceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    init(choosingPrayerTimes: Bool, onSelectCity: ((Location) -> Void)? = nil) {
        _choosingPrayerTimes = State(initialValue: choosingPrayerTimes)
        self.onSelectCity = onSelectCity

        let coordinate: CLLocationCoordinate2D = {
            let settings = Settings.shared
            if let home = settings.homeLocation {
                return home.coordinate
            }
            if let current = settings.currentLocation, current.latitude != 1000, current.longitude != 1000 {
                return current.coordinate
            }
            return CLLocationCoordinate2D(latitude: 21.422445, longitude: 39.826388)
        }()

        _region = State(initialValue: MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        ))
    }

    private var scheme: ColorScheme {
        settings.colorScheme ?? systemScheme
    }

    private var markers: [MarkerItem] {
        var items: [MarkerItem] = []

        if let current = settings.currentLocation,
           current.latitude != 1000,
           current.longitude != 1000 {
            items.append(
                MarkerItem(
                    id: "current",
                    coordinate: CLLocationCoordinate2D(latitude: current.latitude, longitude: current.longitude),
                    tint: .cyan,
                    systemImage: "location.fill"
                )
            )
        }

        if let selectedItem {
            items.append(
                MarkerItem(
                    id: "selected",
                    coordinate: selectedItem.placemark.coordinate,
                    tint: .green,
                    systemImage: "mappin.circle.fill"
                )
            )
            return items
        }

        if let home = settings.homeLocation {
            items.append(
                MarkerItem(
                    id: "home",
                    coordinate: home.coordinate,
                    tint: settings.accentColor.color,
                    systemImage: "house.fill"
                )
            )
        }

        return items
    }

    private var distanceString: String? {
        guard
            let current = settings.currentLocation,
            let home = settings.homeLocation,
            current.latitude != 1000,
            current.longitude != 1000
        else { return nil }

        let here = CLLocation(latitude: current.latitude, longitude: current.longitude)
        let there = CLLocation(latitude: home.latitude, longitude: home.longitude)
        let meters = here.distance(from: there)
        let kilometers = meters / 1_000
        let miles = meters / 1_609.344

        guard
            let kmText = Self.distanceFormatter.string(from: kilometers as NSNumber),
            let mileText = Self.distanceFormatter.string(from: miles as NSNumber)
        else { return nil }

        return "\(mileText) mi / \(kmText) km"
    }

    var body: some View {
        NavigationView {
            interactiveMap
                .edgesIgnoringSafeArea(.all)
                .overlay(alignment: .top) {
                    SearchOverlay(
                        searchText: $searchText,
                        cityItems: cityItems,
                        onSelect: select(_:),
                        primaryLocationName: primaryLocationName(for:),
                        secondaryLocationName: secondaryLocationName(for:),
                        cityIconName: cityIconName(for:)
                    )
                }
                .adaptiveSafeArea(edge: .bottom) {
                    bottomInsetContent
                }
                .navigationTitle(onSelectCity != nil ? "Choose City" : "Select Location")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            settings.hapticFeedback()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.body.weight(.semibold))
                        }
                        .tint(settings.accentColor.color)
                    }
                }
                .confirmationDialog("Location Access Denied", isPresented: $showAlert) {
                    Button("Open Settings") { settings.hapticFeedback(); openSettings() }
                    Button("Never Ask Again", role: .destructive) { settings.hapticFeedback(); settings.locationNeverAskAgain = true }
                    Button("Ignore") { settings.hapticFeedback() }
                } message: {
                    Text("Please enable location services to accurately determine prayer times.")
                }
                .onChange(of: searchText) { newText in
                    scheduleSearch(for: newText)
                }
                .onAppear {
                    configureInitialRegion()
                }
                .preferredColorScheme(scheme)
        }
        .navigationViewStyle(.stack)
        .accentColor(settings.accentColor.color)
        .tint(settings.accentColor.color)
    }

    private var interactiveMap: some View {
        Map(coordinateRegion: $region, annotationItems: markers) { marker in
            MapAnnotation(coordinate: marker.coordinate) {
                AnimatedMarkerBubble(tint: marker.tint, systemImage: marker.systemImage)
            }
        }
    }

    @ViewBuilder
    private var bottomInsetContent: some View {
        // City-picker mode: show a confirm bar for the selected item
        if let onSelectCity, let selectedItem {
            let city = selectedItem.placemark.locality ?? selectedItem.placemark.name ?? "Unknown"
            let state = selectedItem.placemark.administrativeArea ?? ""
            let country = selectedItem.placemark.country ?? ""
            let fullName = [city, state, country].filter { !$0.isEmpty }.joined(separator: ", ")
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(settings.accentColor.color)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(city.isEmpty ? fullName : city)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        if !state.isEmpty || !country.isEmpty {
                            Text([state, country].filter { !$0.isEmpty }.joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal)

                Button {
                    settings.hapticFeedback()
                    let location = Location(
                        city: [city, state].filter { !$0.isEmpty }.joined(separator: ", "),
                        latitude: selectedItem.placemark.coordinate.latitude,
                        longitude: selectedItem.placemark.coordinate.longitude
                    )
                    onSelectCity(location)
                } label: {
                    Text("Select \(city.isEmpty ? "City" : city)")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .conditionalGlassEffect(rectangle: true, useColor: 0.25, customTint: settings.accentColor.color)
                .padding(.horizontal)
            }
            .padding(.vertical, 12)
            .conditionalGlassEffect(rectangle: true, useColor: 0.08)
        } else if !choosingPrayerTimes, settings.homeLocation != nil || hasValidCurrentLocation {
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                if let home = settings.homeLocation {
                    HomeLocationSummaryCard(home: home, distanceString: distanceString)
                }
                // Always offer the one-tap "use my location" shortcut whenever a real fix exists,
                // even before a home has been chosen.
                if hasValidCurrentLocation {
                    useCurrentButton
                }
            }
            .padding(.bottom, 26)
            .padding(.horizontal)
        }
    }

    private var hasValidCurrentLocation: Bool {
        guard let current = settings.currentLocation else { return false }
        return current.latitude != 1000 && current.longitude != 1000
    }

    private var useCurrentButton: some View {
        Button {
            settings.hapticFeedback()
            guard let current = settings.currentLocation else { return }

            withAnimation {
                let coordinate = CLLocationCoordinate2D(latitude: current.latitude, longitude: current.longitude)
                updateRegion(to: coordinate)
                selectedItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
                settings.homeLocation = Location(city: current.city, latitude: current.latitude, longitude: current.longitude)
            }

            settings.fetchPrayerTimes {
                if !settings.locationNeverAskAgain && settings.showLocationAlert {
                    showAlert = true
                }
            }
        } label: {
            Text("Automatically Use Current Location")
                .foregroundColor(.primary)
                .contentShape(Rectangle())
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .font(.headline)
        .foregroundColor(settings.accentColor.color)
        .padding(18)
        .conditionalGlassEffect(useColor: 0.25)
    }

    private func select(_ item: MKMapItem) {
        settings.hapticFeedback()

        let city = item.placemark.locality ?? item.placemark.name ?? "Unknown"
        let state = item.placemark.administrativeArea ?? ""
        let fullName = state.isEmpty ? city : "\(city), \(state)"

        withAnimation {
            selectedItem = item
            updateRegion(to: item.placemark.coordinate)
            searchText = ""

            // In home-picker mode, also update homeLocation
            if onSelectCity == nil {
                settings.homeLocation = Location(
                    city: fullName,
                    latitude: item.placemark.coordinate.latitude,
                    longitude: item.placemark.coordinate.longitude
                )
            }
        }
    }

    private func formattedName(for item: MKMapItem) -> String {
        let city = item.placemark.locality ?? item.placemark.name ?? ""
        let state = item.placemark.administrativeArea ?? ""
        let name = state.isEmpty ? city : "\(city), \(state)"
        return name + ", " + (item.placemark.country ?? "")
    }

    private func primaryLocationName(for item: MKMapItem) -> String {
        item.placemark.locality ?? item.placemark.name ?? "Unknown"
    }

    private func secondaryLocationName(for item: MKMapItem) -> String {
        let state = item.placemark.administrativeArea ?? ""
        let country = item.placemark.country ?? ""
        let parts = [state, country].filter { !$0.isEmpty }
        return parts.isEmpty ? formattedName(for: item) : parts.joined(separator: ", ")
    }

    private func cityIconName(for item: MKMapItem) -> String {
        guard let home = settings.homeLocation else { return "location" }
        let coordinate = item.placemark.coordinate
        let latitudeMatches = abs(coordinate.latitude - home.latitude) < 0.0001
        let longitudeMatches = abs(coordinate.longitude - home.longitude) < 0.0001
        return (latitudeMatches && longitudeMatches) ? "house.fill" : "location"
    }

    private func updateRegion(to coordinate: CLLocationCoordinate2D) {
        region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        )
    }

    private func configureInitialRegion() {
        if let home = settings.homeLocation {
            updateRegion(to: home.coordinate)
        } else if let current = settings.currentLocation {
            updateRegion(to: CLLocationCoordinate2D(latitude: current.latitude, longitude: current.longitude))
        } else {
            updateRegion(to: kaabaCoordinate)
        }
    }

    private func search(for text: String) async {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            await MainActor.run { cityItems = [] }
            return
        }

        // Run address + point-of-interest searches in parallel for better city coverage
        async let addressSearch: [MKMapItem] = {
            let req = MKLocalSearch.Request()
            req.naturalLanguageQuery = query
            req.resultTypes = .address
            return (try? await MKLocalSearch(request: req).start())?.mapItems ?? []
        }()

        async let poiSearch: [MKMapItem] = {
            let req = MKLocalSearch.Request()
            req.naturalLanguageQuery = query
            req.resultTypes = .pointOfInterest
            return (try? await MKLocalSearch(request: req).start())?.mapItems ?? []
        }()

        let (addressItems, poiItems) = await (addressSearch, poiSearch)

        // Merge: prefer items that have a locality (city) set, deduplicate by name
        let combined = (addressItems + poiItems)
            .sorted { a, b in
                let aHasCity = a.placemark.locality != nil
                let bHasCity = b.placemark.locality != nil
                if aHasCity != bHasCity { return aHasCity }
                return false
            }

        var seen = Set<String>()
        let uniqueItems = combined.filter {
            let key = formattedName(for: $0)
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }

        await MainActor.run {
            cityItems = Array(uniqueItems.prefix(10))
        }
    }

    private func scheduleSearch(for text: String) {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else { return }
            await search(for: text)
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

private struct MarkerItem: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let tint: Color
    let systemImage: String
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

private struct SearchOverlay: View {
    @ObservedObject private var settings = Settings.shared

    @Binding var searchText: String
    let cityItems: [MKMapItem]
    let onSelect: (MKMapItem) -> Void
    let primaryLocationName: (MKMapItem) -> String
    let secondaryLocationName: (MKMapItem) -> String
    let cityIconName: (MKMapItem) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            searchHeader
            resultsList
        }
        .conditionalGlassEffect(rectangle: true)
        .padding(.horizontal)
    }

    private var searchHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            SearchBar(text: $searchText.animation(.easeInOut))

            if !searchText.isEmpty {
                Text("\(cityItems.count) match\(cityItems.count == 1 ? "" : "es") found")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(settings.accentColor.color)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 6)
                    .padding(.bottom, -8)
            }
        }
        .padding(8)
    }

    @ViewBuilder
    private var resultsList: some View {
        if !searchText.isEmpty {
            if cityItems.isEmpty {
                Text("No matches found")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.subheadline)
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(cityItems.enumerated()), id: \.offset) { _, item in
                            SearchResultRow(
                                item: item,
                                primaryTitle: primaryLocationName(item),
                                secondaryTitle: secondaryLocationName(item),
                                iconName: cityIconName(item),
                                searchQuery: searchText,
                                onSelect: { onSelect(item) }
                            )
                        }
                    }
                }
                .frame(height: min(CGFloat(cityItems.count) * 76, 150))
            }
        }
    }
}

private struct SearchResultRow: View {
    @ObservedObject private var settings = Settings.shared

    let item: MKMapItem
    let primaryTitle: String
    let secondaryTitle: String
    let iconName: String
    let searchQuery: String
    let onSelect: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: iconName)
                    .foregroundColor(settings.accentColor.color)

                VStack(alignment: .leading, spacing: 3) {
                    HighlightedSnippet(
                        source: primaryTitle,
                        term: searchQuery,
                        font: .subheadline.weight(.semibold),
                        accent: settings.accentColor.color,
                        fg: .primary
                    )
                        .multilineTextAlignment(.leading)

                    HighlightedSnippet(
                        source: secondaryTitle,
                        term: searchQuery,
                        font: .caption,
                        accent: settings.accentColor.color,
                        fg: .secondary
                    )
                        .multilineTextAlignment(.leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect()
            }

            Image(systemName: "checkmark.circle")
                .font(.headline)
                .foregroundColor(settings.accentColor.color)
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
                .onTapGesture {
                    settings.hapticFeedback()
                    onSelect()
                }
        }
        .padding()
    }
}

private struct HomeLocationSummaryCard: View {
    @ObservedObject private var settings = Settings.shared

    let home: Location
    let distanceString: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            locationInfoRow("Home", value: home.city, systemImage: "house.fill", accent: true)

            if let current = settings.currentLocation {
                locationInfoRow("Current", value: current.city, systemImage: "location.fill", accent: true)

                if let distanceString {
                    locationInfoRow("Distance", value: distanceString, systemImage: "arrow.right.arrow.left")
                        .font(.subheadline)
                }
            }

            Text("• Must be at least 48 miles (≈ 77 km) from home to be considered traveling")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.top, 4)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .conditionalGlassEffect(rectangle: true)
    }

    private func locationInfoRow(_ title: String, value: String, systemImage: String, accent: Bool = false) -> some View {
        Label {
            HStack(spacing: 4) {
                Text(title)
                    .fontWeight(.semibold)
                Text(value)
                    .lineLimit(1)
            }
        } icon: {
            Image(systemName: systemImage)
                .frame(width: 18)
        }
        .font(.headline)
        .foregroundColor(accent ? settings.accentColor.color : .primary)
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        MapView(choosingPrayerTimes: false)
    }
}
#endif
