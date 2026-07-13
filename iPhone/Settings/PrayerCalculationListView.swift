import SwiftUI

/// The calculation-method picker: a searchable list, one row per method, each showing the angles it actually
/// uses. Built like `ReciterListView` on purpose - it is the same shape of problem (a long list of named
/// options where the user is hunting for one), and it deserves the same affordances.
///
/// It replaced a wheel `Picker`, which could show neither the angles nor a search field, and which offered
/// only the dozen methods the Adhan package's enum happened to contain.
struct PrayerCalculationListView: View {
    @ObservedObject var settings = Settings.shared

    @State private var searchText = ""

    private var customMethod: PrayerCalculationMethod {
        PrayerCalculationCatalog.custom(
            fajrAngle: settings.customFajrAngle,
            ishaAngle: settings.customIshaAngle
        )
    }

    private var selectedID: String {
        settings.canonicalPrayerCalculationMethod(settings.prayerCalculation)
    }

    private func normalized(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var query: String { normalized(searchText) }
    private var isSearching: Bool { !query.isEmpty }

    /// Name, region and angles are all searchable: people look for "Karachi", for "Malaysia", and for "18".
    private func matches(_ method: PrayerCalculationMethod) -> Bool {
        guard isSearching else { return true }
        let haystack = [method.name, method.region ?? "", method.angleSummary, method.id]
            .map(normalized)
            .joined(separator: " ")
        return haystack.contains(query)
    }

    private var results: [PrayerCalculationMethod] {
        PrayerCalculationCatalog.methods.filter(matches)
    }

    var body: some View {
        List {
            Group {
                automaticSection

                if isSearching {
                    searchResultsBanner

                    if results.isEmpty && !matches(customMethod) {
                        Text("No calculation methods matched your search.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(results) { methodRow($0) }
                        if matches(customMethod) { customSection }
                    }
                } else {
                    Section(header: Text("METHODS")) {
                        ForEach(PrayerCalculationCatalog.methods) { methodRow($0) }
                    }

                    customSection
                    explanationSection
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Prayer Calculation")
        #if os(iOS)
        .adaptiveSafeArea(edge: .bottom) {
            SearchBar(text: $searchText.animation(.easeInOut))
                .padding([.leading, .top], -8)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
                .background(Color.white.opacity(0.00001))
        }
        #elseif os(watchOS)
        .searchable(text: $searchText.animation(.easeInOut))
        #endif
        .applyConditionalListStyle()
    }

    private var automaticSection: some View {
        Section(header: Text("AUTOMATIC")) {
            Toggle("Choose Automatically", isOn: $settings.calculationAutomatic.animation(.easeInOut))
                .font(.subheadline)
                .tint(settings.accentColor.color)
                .onChange(of: settings.calculationAutomatic) { _ in settings.hapticFeedback() }

            Text("Picks the method customary in the country you are in. Choosing a method by hand below turns this off.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var searchResultsBanner: some View {
        HStack(spacing: 10) {
            Text("Search Results")
            Spacer()
            Text("\(results.count + (matches(customMethod) ? 1 : 0))")
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(settings.accentColor.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .conditionalGlassEffect()
                .padding(.vertical, -16)
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.secondary)
    }

    private func methodRow(_ method: PrayerCalculationMethod) -> some View {
        let isSelected = selectedID == method.id

        return VStack(alignment: .leading, spacing: 4) {
            // The angles lead: they are the thing that actually differs between two methods, and the reason
            // someone is on this screen at all.
            Text(method.angleSummary)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.secondary.opacity(0.12))
                )

            HStack {
                HighlightedSnippet(
                    source: method.name,
                    term: searchText,
                    font: .subheadline.weight(.semibold),
                    accent: settings.accentColor.color,
                    fg: isSelected ? settings.accentColor.color : .primary
                )

                Spacer(minLength: 8)

                Image(systemName: "checkmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(settings.accentColor.color)
                    .opacity(isSelected ? 1 : 0)
            }

            if let region = method.region {
                Text(region)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture {
            settings.hapticFeedback()
            withAnimation(.easeInOut) {
                settings.setPrayerCalculationManually(method.id)
            }
        }
    }

    @ViewBuilder
    private var customSection: some View {
        Section(header: Text("CUSTOM")) {
            methodRow(customMethod)

            // Only editable while the custom method is the one in use - otherwise these steppers would be
            // silently adjusting angles that nothing is computing with.
            if selectedID == PrayerCalculationCatalog.customID {
                Stepper(value: $settings.customFajrAngle, in: 8...25, step: 0.5) {
                    HStack {
                        Text("Fajr Angle")
                        Spacer()
                        Text("\(IshaRule.format(settings.customFajrAngle))°")
                            .monospacedDigit()
                            .foregroundColor(settings.accentColor.color)
                    }
                }
                .font(.subheadline)

                Stepper(value: $settings.customIshaAngle, in: 8...25, step: 0.5) {
                    HStack {
                        Text("Isha Angle")
                        Spacer()
                        Text("\(IshaRule.format(settings.customIshaAngle))°")
                            .monospacedDigit()
                            .foregroundColor(settings.accentColor.color)
                    }
                }
                .font(.subheadline)

                Text("Only set your own angles if you know the values your local mosque uses. A wrong angle means praying at the wrong time.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var explanationSection: some View {
        Section(header: Text("ABOUT THESE ANGLES")) {
            Text("Fajr begins at true dawn and Isha at nightfall. Neither is a clock time: both are defined by how far the sun has sunk below the horizon, and the bodies below differ on where exactly to draw that line. A larger angle means an earlier Fajr and a later Isha.")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("Umm Al-Qura and Qatar use a fixed interval after Maghrib for Isha instead of an angle, because at their latitude the twilight is consistent enough for a clock to be reliable.")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("Use the method your local mosque uses. If you do not know it, leave this on automatic.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
