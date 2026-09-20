#if os(iOS)
import SwiftUI

/// Zakat al-Fitr, on its own screen.
///
/// It used to be a section at the foot of the wealth calculator, which is where a lot of the
/// confusion came from (Abu, 2026-09-19): it is a different obligation, on a different basis, with
/// a different unit. Nothing here is worked out on wealth - it is one sa' of food per person, and
/// the money field exists only to tell you what that food will cost.
///
/// The position followed is the one Ibn Baz, Ibn 'Uthaymin and the Permanent Committee held: it is
/// given as FOOD, not as its price.
struct ZakatAlFitrView: View {
    @ObservedObject private var settings = Settings.shared

    @AppStorage("zakahFitrPeople") private var fitrPeople = 1
    @AppStorage("zakahFitrCost") private var fitrCost = ""

    @FocusState private var focusedField: Bool

    /// One sa' is about 3 kg of rice or dates.
    private static let kilosPerSa: Double = 3

    private var totalKilos: Int { Int((Double(fitrPeople) * Self.kilosPerSa).rounded()) }

    private func amount(_ text: String) -> Double {
        let cleaned = text.filter { $0.isNumber || $0 == "." || $0 == "," }
        let normalized = cleaned.contains(".")
            ? cleaned.replacingOccurrences(of: ",", with: "")
            : cleaned.replacingOccurrences(of: ",", with: ".")
        return Double(normalized) ?? 0
    }

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private func formatted(_ value: Double) -> String {
        Self.currencyFormatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }

    var body: some View {
        List {
            Group {
                Section {
                    CalculatorResultCard(title: "Food to give",
                                         value: "\(fitrPeople) sa\u{2018}") {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("About \(totalKilos) kg of the staple your household eats \u{2014} rice, dates, flour.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)

                            if amount(fitrCost) > 0 {
                                Text("Roughly \(formatted(amount(fitrCost) * Double(fitrPeople))) to buy.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section(header: Text("YOUR HOUSEHOLD")) {
                    Stepper(value: $fitrPeople, in: 1...30) {
                        HStack {
                            Text("People you are responsible for")
                                .font(.subheadline)
                                .lineLimit(2)
                                .minimumScaleFactor(0.7)
                            Spacer(minLength: 8)
                            Text("\(fitrPeople)")
                                .font(.subheadline.monospacedDigit())
                                .foregroundColor(settings.accentColor.accent2)
                        }
                    }
                    .padding(.vertical, 2)

                    HStack(spacing: 10) {
                        Image(systemName: "cart")
                            .foregroundColor(settings.accentColor.color)
                            .frame(width: 24)

                        Text("Cost of one sa\u{2018} locally")
                            .font(.subheadline)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)

                        Spacer(minLength: 8)

                        TextField("0", text: $fitrCost)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.subheadline.monospacedDigit())
                            .frame(maxWidth: 120)
                            .focused($focusedField)
                    }
                    .padding(.vertical, 2)

                    ExplainerButton(
                        title: "Why the cost is only a guide",
                        body_: "Ibn Baz, Ibn \u{2018}Uthaymin and the Permanent Committee all held that zakat al-Fitr must be given as FOOD and not as its price; Abu Hanifa allowed the money. This app follows the first view, so the amount here is only to tell you what the food will run to \u{2014} it is not the thing you give.",
                        caption: "Given as food, not money. The cost is only so you can budget for it."
                    )
                }

                Section(header: Text("WHAT IT IS")) {
                    Text(verbatim: "A separate obligation from the zakah on wealth, and it is not worked out on wealth at all. One sa\u{2018} of the staple food people eat, for every person you are responsible for, given before the Eid prayer.")
                        .font(.subheadline)

                    ScriptureQuote(hadith: "bukhari:1503", cite: "Sahih al-Bukhari 1503",
                                   arabic: 29...62, english: 0...46)
                }

                Section(header: Text("WHEN TO GIVE IT")) {
                    Text(verbatim: "Before the Eid prayer. Ibn \u{2018}Abbas said the Prophet (peace and blessings be upon him) made it obligatory as a purification for the fasting person from idle talk and obscenity, and as food for the poor: whoever gives it before the prayer, it is an accepted zakah, and whoever gives it after the prayer, it is one charity among charities.")
                        .font(.subheadline)

                    Text(verbatim: "It may be given a day or two early, as Ibn \u{2018}Umar used to do, so that it reaches the poor in time for the day itself.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Zakat al-Fitr")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                if focusedField {
                    Spacer(minLength: 0)
                    Button("Done") { focusedField = false }
                }
            }
        }
    }
}

#Preview {
    AlIslamPreviewContainer {
        ZakatAlFitrView()
    }
}
#endif
