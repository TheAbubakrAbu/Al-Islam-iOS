import SwiftUI

/// Lets the user spell the five daily prayers however they say them - "Fadjr", "Zuhr", "Maghrib" → "Maghreb".
///
/// Only the *displayed* name changes. `Prayer.nameTransliteration` stays canonical, because notification
/// preferences, the optional-prayer set, Siri's search keys and the scrubber's highlight all key off it.
/// Names live in the app group, so widgets and the Watch render them too.
struct CustomPrayerNamesSection: View {
    @ObservedObject var settings = Settings.shared

    /// Edited locally and committed on blur. Writing straight through on every keystroke would recompute
    /// prayer times and reschedule notifications once per typed character.
    @State private var drafts: [String: String] = [:]
    @FocusState private var focusedPrayer: String?

    private var hasAnyCustomName: Bool {
        Settings.renameablePrayerNames.contains { settings.customPrayerName(for: $0) != nil }
    }

    var body: some View {
        Section(header: Text("CUSTOM PRAYER NAMES")) {
            ForEach(Settings.renameablePrayerNames, id: \.self) { prayer in
                row(for: prayer)
            }

            Text("Renaming a prayer only changes how it is displayed: in the app, its notifications, the widgets and on your Apple Watch. Leave a field blank to use the default spelling.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 2)
        }

        if hasAnyCustomName {
            Section {
                Button(role: .destructive) {
                    settings.hapticFeedback()
                    focusedPrayer = nil
                    drafts = [:]
                    withAnimation { settings.customPrayerNames = [:] }
                } label: {
                    Text("Reset to Default Names")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func row(for prayer: String) -> some View {
        HStack {
            Text(prayer)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 84, alignment: .leading)

            TextField(prayer, text: draft(for: prayer))
                .font(.subheadline)
                .multilineTextAlignment(.trailing)
                .autocorrectionDisabled()
                .focused($focusedPrayer, equals: prayer)
                .submitLabel(.done)
                .onSubmit { commit(prayer) }
                #if os(iOS)
                .textInputAutocapitalization(.words)
                #endif
        }
        .onChange(of: focusedPrayer) { newFocus in
            // Committing when focus *leaves* this row covers tapping another field or dismissing the keyboard,
            // neither of which fires onSubmit.
            if newFocus != prayer, drafts[prayer] != nil { commit(prayer) }
        }
    }

    private func draft(for prayer: String) -> Binding<String> {
        Binding(
            get: { drafts[prayer] ?? settings.customPrayerName(for: prayer) ?? "" },
            set: { drafts[prayer] = $0 }
        )
    }

    private func commit(_ prayer: String) {
        guard let draft = drafts.removeValue(forKey: prayer) else { return }
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)

        // A name identical to the default, or an empty one, is stored as "no custom name" rather than as a
        // redundant entry - that keeps `hasAnyCustomName` and the reset button honest.
        var names = settings.customPrayerNames
        if trimmed.isEmpty || trimmed == prayer {
            guard names[prayer] != nil else { return }
            names.removeValue(forKey: prayer)
        } else {
            guard names[prayer] != trimmed else { return }
            names[prayer] = trimmed
        }
        settings.customPrayerNames = names
    }
}
