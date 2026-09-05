#if os(iOS)
import SwiftUI
import CoreLocation

// MARK: - PrayerTimesMapView

struct PrayerTimesMapView: View {
    @ObservedObject private var settings = Settings.shared
    /// Prayer times and the location publish from `LiveState`, not `Settings` (see its comment).
    @ObservedObject private var live = LiveState.shared
    @Environment(\.dismiss) private var dismiss

    @AppStorage("prayerTimesMapShowCityTime") private var showCityTime: Bool = true
    @State private var selectedLocation: Location?
    @State private var selectedDate = Date()
    @State private var prayers: [Prayer] = []
    @State private var currentLocationPrayers: [Prayer] = []
    @State private var showCityPicker = false
    @State private var compareAutomaticLocation = false
    @State private var timeZones: [String: TimeZone] = [:]

    // Optional times for this view-only screen. Each follows the user's own Adhan toggle until
    // it is flipped here, then remembers that choice; the real toggles (and so notifications,
    // widgets and the Adhan tab) are never touched from this sheet.
    @AppStorage("prayerTimesMapShowDuha") private var mapShowDuha: Bool?
    @AppStorage("prayerTimesMapShowIslamicMidnight") private var mapShowIslamicMidnight: Bool?
    @AppStorage("prayerTimesMapShowLastThird") private var mapShowLastThird: Bool?

    // The selected city always uses the calculation method auto-matched to its own country
    // (detected via reverse-geocoding). The current-location side of a comparison always
    // keeps the user's own global method.
    @State private var selectedCalculation: String = ""

    private let columnWidth: CGFloat = 80

    private var effectiveLocation: Location? {
        selectedLocation ?? live.currentLocation
    }

    private var canCompareAutomaticLocation: Bool {
        guard let current = live.currentLocation,
              let selected = selectedLocation else { return false }
        return !isSameLocation(current, selected)
    }

    private var isComparing: Bool {
        compareAutomaticLocation && canCompareAutomaticLocation
    }

    private var activeMethod: String {
        if selectedLocation == nil { return settings.prayerCalculation }
        return selectedCalculation.isEmpty ? settings.prayerCalculation : selectedCalculation
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                heroSection
                if !settings.favoriteLocations.isEmpty {
                    favoritesSection
                }
                if selectedLocation != nil {
                    optionsSection
                }
                prayerTimesSection
                optionalTimesSection
                    .id("optionalTimes")
            }
            #if DEBUG
            // "-cityPrayerTimesScrollToOptional": land on the optional-times switches (screenshot runs).
            .onAppear {
                guard ProcessInfo.processInfo.arguments.contains("-cityPrayerTimesScrollToOptional") else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { proxy.scrollTo("optionalTimes", anchor: .bottom) }
                }
            }
            #endif
        }
        .applyConditionalListStyle()
        .navigationTitle("City Prayer Times")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { settings.hapticFeedback(); dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                }
                .tint(settings.accentColor.color)
            }
        }
        .sheet(isPresented: $showCityPicker) {
            MapView(choosingPrayerTimes: true, onSelectCity: { location in
                selectedLocation = location
                showCityPicker = false
            })
            .environmentObject(settings)
            .smallMediumSheetPresentation()
        }
        .onAppear {
            refreshPrayers()
            #if DEBUG
            // "-cityPrayerTimesCity Makkah:21.4225:39.8262" selects that city on appear, and
            // "-cityPrayerTimesCompare" also switches the comparison on (screenshot runs).
            let args = ProcessInfo.processInfo.arguments
            // "-cityPrayerTimesOptional" switches all three optional times on for this screen.
            if args.contains("-cityPrayerTimesOptional") {
                mapShowDuha = true; mapShowIslamicMidnight = true; mapShowLastThird = true
            }
            if let i = args.firstIndex(of: "-cityPrayerTimesCity"), args.indices.contains(i + 1) {
                let parts = args[i + 1].split(separator: ":")
                if parts.count == 3, let lat = Double(parts[1]), let lon = Double(parts[2]) {
                    selectedLocation = Location(city: String(parts[0]), latitude: lat, longitude: lon)
                    if args.contains("-cityPrayerTimesCompare") {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { compareAutomaticLocation = true }
                    }
                }
            }
            #endif
        }
        .onChange(of: selectedDate) { _ in refreshPrayers() }
        .onChange(of: selectedLocation) { newValue in
            if newValue == nil {
                selectedCalculation = ""
                compareAutomaticLocation = false
            } else {
                // Show the user's own method provisionally until the city's country is detected.
                selectedCalculation = settings.prayerCalculation
            }
            refreshPrayers()
            if newValue != nil { detectCalculationMethod() }
        }
        .onChange(of: selectedCalculation) { _ in refreshPrayers() }
        .onChange(of: showCityTime) { _ in settings.hapticFeedback(); refreshTimeZones() }
        .onChange(of: live.currentLocation) { _ in refreshPrayers() }
        .onChange(of: showDuhaHere) { _ in refreshPrayers() }
        .onChange(of: showIslamicMidnightHere) { _ in refreshPrayers() }
        .onChange(of: showLastThirdHere) { _ in refreshPrayers() }
    }

    // MARK: - Optional Times

    private var showDuhaHere: Bool { mapShowDuha ?? settings.showDuha }
    private var showIslamicMidnightHere: Bool { mapShowIslamicMidnight ?? settings.showIslamicMidnight }
    private var showLastThirdHere: Bool { mapShowLastThird ?? settings.showLastThird }

    private var showsAnyOptionalTime: Bool {
        showDuhaHere || showIslamicMidnightHere || showLastThirdHere
    }

    @ViewBuilder
    private var optionalTimesSection: some View {
        if effectiveLocation != nil {
            Section {
                optionalTimeToggle("Duhaa", icon: "sun.haze.fill", isOn: optionalBinding($mapShowDuha, fallback: settings.showDuha))
                optionalTimeToggle("Islamic Midnight", icon: "moon.fill", isOn: optionalBinding($mapShowIslamicMidnight, fallback: settings.showIslamicMidnight))
                optionalTimeToggle("Last Third of the Night", icon: "moon.stars.fill", isOn: optionalBinding($mapShowLastThird, fallback: settings.showLastThird))
            } header: {
                Text("Optional Times")
            } footer: {
                Text(isComparing
                     ? "Computed for both cities from their own sunrise, Maghrib and next Fajr. These switches only affect this screen."
                     : "Computed from this city\u{2019}s own sunrise, Maghrib and next Fajr. These switches only affect this screen.")
            }
        }
    }

    /// A `Bool?` store that reads as the user's real toggle until it is set here.
    private func optionalBinding(_ stored: Binding<Bool?>, fallback: Bool) -> Binding<Bool> {
        Binding(
            get: { stored.wrappedValue ?? fallback },
            set: { stored.wrappedValue = $0 }
        )
    }

    private func optionalTimeToggle(_ title: String, icon: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn.animation(.easeInOut)) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(settings.accentColor.color)
                    .frame(width: 22, alignment: .center)
                Text(title)
                    .foregroundColor(.primary)
            }
            .font(.subheadline)
        }
        .tint(settings.accentColor.color)
        .onChange(of: isOn.wrappedValue) { _ in settings.hapticFeedback() }
    }

    // MARK: - Hero

    @ViewBuilder
    private var heroSection: some View {
        Section {
            if let location = effectiveLocation {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(settings.accentColor.color.opacity(0.15))
                                .frame(width: 52, height: 52)
                            Image(systemName: selectedLocation == nil ? "location.fill" : "mappin")
                                .font(.title2)
                                .foregroundStyle(settings.accentColor.color)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(location.city)
                                .font(.title3.weight(.bold))
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                            Text(selectedLocation == nil
                                 ? "Your current location"
                                 : String(format: "%.3f°, %.3f°", location.latitude, location.longitude))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 0)

                        if selectedLocation != nil {
                            Button {
                                settings.hapticFeedback()
                                toggleFavorite(location)
                            } label: {
                                Image(systemName: isFavorite(location) ? "star.fill" : "star")
                                    .font(.title3)
                                    .foregroundStyle(settings.accentColor.color)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    HStack(spacing: 6) {
                        infoChip(activeMethod, systemImage: "function")
                        if selectedLocation != nil {
                            infoChip("Auto", systemImage: "wand.and.stars")
                        }
                    }
                }
                .padding(.vertical, 4)
            } else {
                Label("No location available", systemImage: "location.slash")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button {
                settings.hapticFeedback()
                showCityPicker = true
            } label: {
                Label(selectedLocation == nil ? "Choose a City" : "Choose Another City",
                      systemImage: "map.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(settings.accentColor.color)
            }

            if selectedLocation != nil {
                Button {
                    settings.hapticFeedback()
                    withAnimation {
                        selectedLocation = nil
                        compareAutomaticLocation = false
                    }
                } label: {
                    Label("Back to My Location", systemImage: "location.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(settings.accentColor.color)
                }
            }
            Text("View-only: this never changes your real prayer times, notifications, or widgets.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.vertical, 2)
        }
    }

    // MARK: - Favorites

    private var favoritesSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(settings.favoriteLocations, id: \.city) { location in
                        favoriteChip(location)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .listRowInsets(EdgeInsets())

            Text("Touch and hold a city to remove it.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.vertical, 2)
        } header: {
            Text("Favorites")
        }
    }

    private func favoriteChip(_ location: Location) -> some View {
        let isSelected = selectedLocation?.city == location.city
        return Button {
            settings.hapticFeedback()
            withAnimation { selectedLocation = location }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "star.fill").font(.caption2)
                Text(shortCity(location))
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .background(
                isSelected ? settings.accentColor.color : settings.accentColor.color.opacity(0.12),
                in: Capsule()
            )
            .foregroundStyle(isSelected ? Color.white : settings.accentColor.color)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                withAnimation { settings.favoriteLocations.removeAll { $0.city == location.city } }
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }

    // MARK: - Options

    private var optionsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Picker("Show Times In", selection: $showCityTime.animation(.easeInOut)) {
                    Text("City Time").tag(true)
                    Text("My Time").tag(false)
                }
                .pickerStyle(.segmented)
                .onChange(of: showCityTime) { _ in settings.hapticFeedback() }

                Text(timeZoneCaption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 2)
            }

            VStack(alignment: .leading, spacing: 6) {
                Toggle(isOn: $compareAutomaticLocation.animation(.easeInOut)) {
                    Label("Compare With My Location", systemImage: "arrow.left.arrow.right")
                        .font(.subheadline)
                }
                .tint(settings.accentColor.color)
                .disabled(!canCompareAutomaticLocation)
                .onChange(of: compareAutomaticLocation) { _ in settings.hapticFeedback() }

                Text(methodCaption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 2)
            }
        } header: {
            Text("Options")
        }
    }

    private var timeZoneCaption: String {
        let city = selectedLocation.map(shortCity) ?? "the city"
        return "“City Time” shows each prayer on \(city)’s local clock, the time you’d see if you were there. “My Time” converts those same moments to your current time zone."
    }

    private var methodCaption: String {
        let city = selectedLocation.map(shortCity) ?? "this city"
        return "Fajr and Isha vary by method, so \(city) uses the \(activeMethod) method matched to its region. Your location keeps your own method."
    }

    // MARK: - Prayer Times

    @ViewBuilder
    private var prayerTimesSection: some View {
        if let location = effectiveLocation {
            Section {
                if isComparing, let current = live.currentLocation, let selected = selectedLocation {
                    comparisonContent(current: current, selected: selected)
                } else if prayers.isEmpty {
                    emptyPrayersLabel
                } else {
                    ForEach(prayers) { prayer in
                        cityPrayerRow(prayer: prayer, location: location)
                    }
                }

                DatePicker(selection: $selectedDate.animation(.easeInOut), displayedComponents: .date) {
                    Label("Date", systemImage: "calendar")
                        .font(.subheadline)
                }
                .tint(settings.accentColor.color)

                if !Calendar.current.isDateInToday(selectedDate) {
                    Button {
                        settings.hapticFeedback()
                        withAnimation { selectedDate = Date() }
                    } label: {
                        Label("Jump to Today", systemImage: "arrow.uturn.backward")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(settings.accentColor.color)
                    }
                }
            } header: {
                HStack {
                    Text("Prayer Times")
                    Spacer()
                    Text(isComparing ? "Comparison" : shortCity(location))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(settings.accentColor.color)
                }
            }
        } else {
            Section {
                Label("Choose a city to see prayer times.", systemImage: "mappin.slash")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Prayer Times")
            }
        }
    }

    private var emptyPrayersLabel: some View {
        Label("No prayer times available", systemImage: "moon.zzz")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 6)
    }

    private func cityPrayerRow(prayer: Prayer, location: Location) -> some View {
        HStack(spacing: 12) {
            Image(systemName: prayer.image)
                .font(.title3)
                .foregroundColor(prayer.nameTransliteration == "Shurooq" ? .primary : settings.accentColor.color)
                .frame(width: 30, alignment: .center)

            VStack(alignment: .leading, spacing: 1) {
                Text(prayer.displayName)
                    .font(.headline)
                Text(prayer.nameEnglish)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(formattedTime(prayer.time, for: location))
                .font(.body.monospacedDigit().weight(.medium))
        }
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }

    // MARK: - Comparison

    @ViewBuilder
    private func comparisonContent(current: Location, selected: Location) -> some View {
        let rows = comparisonRows(selected: prayers, current: currentLocationPrayers)
        if rows.isEmpty {
            Label("No comparison available", systemImage: "arrow.left.arrow.right")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 6)
        } else {
            // Column header: the two city names appear once instead of on every row.
            HStack(spacing: 10) {
                Text("Cities:")
                    .font(.subheadline)

                Spacer()

                Text(shortCity(selected))
                    .foregroundStyle(settings.accentColor.color)
                    .frame(width: columnWidth, alignment: .trailing)
                Text(shortCity(current))
                    .foregroundStyle(.secondary)
                    .frame(width: columnWidth, alignment: .trailing)
            }
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            ForEach(rows, id: \.name) { row in
                comparisonRow(row: row, current: current, selected: selected)
            }
        }
    }

    private func comparisonRow(
        row: (name: String, image: String, current: Prayer, selected: Prayer),
        current: Location,
        selected: Location
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: row.image)
                .font(.title3)
                .foregroundColor(row.name == "Shurooq" ? .primary : settings.accentColor.color)
                .frame(width: 30, alignment: .center)

            Text(row.name)
                .font(.headline)

            Spacer()

            Text(formattedTime(row.selected.time, for: selected))
                .font(.subheadline.monospacedDigit().weight(.medium))
                .foregroundStyle(settings.accentColor.color)
                .frame(width: columnWidth, alignment: .trailing)

            Text(formattedTime(row.current.time, for: current))
                .font(.subheadline.monospacedDigit())
                .frame(width: columnWidth, alignment: .trailing)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }

    // MARK: - Small components

    private func infoChip(_ text: String, systemImage: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage).font(.caption2)
            Text(text).font(.caption2.weight(.semibold))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(settings.accentColor.color.opacity(0.15), in: Capsule())
        .foregroundStyle(settings.accentColor.color)
        .lineLimit(1)
    }

    // MARK: - Helpers

    private func refreshPrayers() {
        guard let location = effectiveLocation else {
            prayers = []
            currentLocationPrayers = []
            return
        }

        // The selected city uses its own (auto-detected or manually chosen) method.
        // The current location always keeps the user's own global method.
        let override = (selectedLocation == nil || selectedCalculation.isEmpty) ? nil : selectedCalculation
        prayers = prayersWithOptionalTimes(at: location, calculationOverride: override)
        if canCompareAutomaticLocation, let current = live.currentLocation {
            currentLocationPrayers = prayersWithOptionalTimes(at: current, calculationOverride: nil)
        } else {
            currentLocationPrayers = []
            compareAutomaticLocation = false
        }

        refreshTimeZones()
    }

    /// The base prayers for `location` plus whichever optional times are switched on for this screen,
    /// each computed for that location (and, for the selected city, with its own method).
    private func prayersWithOptionalTimes(at location: Location, calculationOverride: String?) -> [Prayer] {
        let base = settings.getPrayerTimes(for: selectedDate, at: location, fullPrayers: true, calculationOverride: calculationOverride) ?? []
        guard !base.isEmpty, showsAnyOptionalTime else { return base }

        let optional = settings.optionalPrayers(
            for: selectedDate,
            at: location,
            calculationOverride: calculationOverride,
            duha: showDuhaHere,
            islamicMidnight: showIslamicMidnightHere,
            lastThird: showLastThirdHere
        )
        guard !optional.isEmpty else { return base }

        let existingNames = Set(base.map(\.nameTransliteration))
        return (base + optional.filter { !existingNames.contains($0.nameTransliteration) })
            .sorted { $0.time < $1.time }
    }

    /// Reverse-geocodes the selected city to find its country, then (when automatic) picks the
    /// calculation method appropriate to that country. Updating `selectedCalculation` re-runs `refreshPrayers`.
    private func detectCalculationMethod() {
        guard let location = selectedLocation else { return }
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: location.latitude, longitude: location.longitude)) { placemarks, _ in
            let code = placemarks?.first?.isoCountryCode?.uppercased() ?? ""
            DispatchQueue.main.async {
                guard selectedLocation == location else { return }
                let method = code.isEmpty
                    ? settings.prayerCalculation
                    : settings.recommendedCalculationMethod(forCountryCode: code)
                if method != selectedCalculation {
                    withAnimation { selectedCalculation = method }
                }
            }
        }
    }

    /// Shared instance: DateFormatter construction is heavy, and this ran once per prayer row per render.
    /// Only the timeZone varies per call (cheap to set); main-thread-only, like the rest of this view.
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    private func formattedTime(_ date: Date, for location: Location) -> String {
        let formatter = Self.timeFormatter
        formatter.timeZone = showCityTime ? (timeZones[timeZoneKey(for: location)] ?? .current) : .current
        return formatter.string(from: date)
    }

    private func refreshTimeZones() {
        guard showCityTime else { return }
        if let location = effectiveLocation {
            requestTimeZone(for: location)
        }
        if canCompareAutomaticLocation, let current = live.currentLocation {
            requestTimeZone(for: current)
        }
    }

    private func requestTimeZone(for location: Location) {
        let key = timeZoneKey(for: location)
        guard timeZones[key] == nil else { return }

        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: location.latitude, longitude: location.longitude)) { placemarks, _ in
            guard let timeZone = placemarks?.first?.timeZone else { return }
            DispatchQueue.main.async {
                timeZones[key] = timeZone
            }
        }
    }

    private func timeZoneKey(for location: Location) -> String {
        "\(location.latitude.stringRepresentation),\(location.longitude.stringRepresentation)"
    }

    private func shortCity(_ location: Location) -> String {
        location.city
            .split(separator: ",")
            .first
            .map { $0.trimmingCharacters(in: .whitespaces) } ?? location.city
    }

    private func comparisonRows(selected: [Prayer], current: [Prayer]) -> [(name: String, image: String, current: Prayer, selected: Prayer)] {
        selected.compactMap { selectedPrayer in
            guard let currentPrayer = current.first(where: { $0.nameTransliteration == selectedPrayer.nameTransliteration }) else {
                return nil
            }
            return (selectedPrayer.displayName, selectedPrayer.image, currentPrayer, selectedPrayer)
        }
    }

    private func isSameLocation(_ lhs: Location, _ rhs: Location) -> Bool {
        abs(lhs.latitude - rhs.latitude) < 0.0001 && abs(lhs.longitude - rhs.longitude) < 0.0001
    }

    private func isFavorite(_ location: Location) -> Bool {
        settings.favoriteLocations.contains(where: { $0.city == location.city })
    }

    private func toggleFavorite(_ location: Location) {
        withAnimation {
            if isFavorite(location) {
                settings.favoriteLocations.removeAll { $0.city == location.city }
            } else {
                settings.favoriteLocations.append(location)
            }
        }
    }
}

#Preview {
    NavigationView {
        PrayerTimesMapView()
            .environmentObject(Settings.shared)
    }
    .navigationViewStyle(.stack)
}
#endif
