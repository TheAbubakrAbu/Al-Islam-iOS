#if os(iOS)
import SwiftUI

/// A deliberately simple zakah calculator: enter what you own, subtract what you owe, and 2.5% of the rest
/// is due - provided the net is at or above the nisab and has been held for one lunar year. It does no
/// currency conversion and fetches no metal prices; every field is a plain amount in the user's own currency.
/// (`ZakahView` is taken - that's the Pillars & Beliefs page ABOUT zakah, in PillarViews.swift.)
struct ZakahCalculatorView: View {
    @ObservedObject private var settings = Settings.shared

    // Persisted so a work-in-progress calculation survives leaving the screen. Stored as strings because
    // they back TextFields directly; parsing happens in one place (`amount(_:)`).
    @AppStorage("zakahCash") private var cash = ""
    @AppStorage("zakahGoldSilver") private var goldSilver = ""
    @AppStorage("zakahInvestments") private var investments = ""
    @AppStorage("zakahBusiness") private var business = ""
    @AppStorage("zakahOwedToYou") private var owedToYou = ""
    @AppStorage("zakahDebts") private var debts = ""
    @AppStorage("zakahNisab") private var nisab = ""

    @FocusState private var focusedField: Bool

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    /// Tolerant parse: grouping separators and currency symbols are stripped rather than rejected.
    private func amount(_ text: String) -> Double {
        let cleaned = text.filter { $0.isNumber || $0 == "." || $0 == "," }
        // Treat a comma as a decimal separator only when there is no period competing for the job.
        let normalized = cleaned.contains(".")
            ? cleaned.replacingOccurrences(of: ",", with: "")
            : cleaned.replacingOccurrences(of: ",", with: ".")
        return Double(normalized) ?? 0
    }

    private var totalAssets: Double {
        [cash, goldSilver, investments, business, owedToYou].map(amount).reduce(0, +)
    }

    private var netWealth: Double {
        max(totalAssets - amount(debts), 0)
    }

    private var nisabValue: Double { amount(nisab) }

    /// Below-nisab only when the user actually supplied a nisab; with the field empty the calculator
    /// doesn't pretend to know the threshold and simply shows the 2.5%.
    private var isBelowNisab: Bool {
        nisabValue > 0 && netWealth < nisabValue
    }

    private var zakahDue: Double { netWealth * 0.025 }

    private func formatted(_ value: Double) -> String {
        Self.currencyFormatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }

    var body: some View {
        List {
            Group {
                assetsSection
                liabilitiesSection
                nisabSection
                resultSection
                notesSection
            }
            .themedListRowBackground()
        }
        .navigationTitle("Zakah Calculator")
        .applyConditionalListStyle()
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = false }
            }
        }
    }

    private var assetsSection: some View {
        Section(header: Text("ZAKATABLE ASSETS"), footer: Text("Amounts you have owned for one full lunar year, in your own currency.")) {
            amountRow("Cash & bank balances", systemImage: "banknote", text: $cash)
            amountRow("Gold & silver value", systemImage: "circle.hexagongrid", text: $goldSilver)
            amountRow("Stocks & investments", systemImage: "chart.line.uptrend.xyaxis", text: $investments)
            amountRow("Business inventory", systemImage: "shippingbox", text: $business)
            amountRow("Money owed to you", systemImage: "person.crop.circle.badge.checkmark", text: $owedToYou)
        }
    }

    private var liabilitiesSection: some View {
        Section(header: Text("LIABILITIES"), footer: Text("Debts and bills due now. These are subtracted from your assets.")) {
            amountRow("Debts you owe", systemImage: "creditcard", text: $debts)
        }
    }

    private var nisabSection: some View {
        Section(header: Text("NISAB (OPTIONAL)"), footer: Text("The nisab is the minimum wealth before zakah is due: the value of 85g of gold or 595g of silver. Look up today's value in your currency and enter it here; leave it empty to skip the check.")) {
            amountRow("Nisab threshold", systemImage: "scalemass", text: $nisab)
        }
    }

    private var resultSection: some View {
        Section(header: Text("RESULT")) {
            resultRow("Total assets", value: totalAssets)
            resultRow("Net zakatable wealth", value: netWealth)

            if isBelowNisab {
                Text("Your net wealth is below the nisab you entered, so no zakah is due.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                HStack {
                    Text("Zakah due (2.5%)")
                        .font(.headline)

                    Spacer()

                    Text(formatted(zakahDue))
                        .font(.headline.monospacedDigit())
                        .foregroundColor(settings.accentColor.accent2)
                }
                .padding(.vertical, 2)
                .contextMenu {
                    Button {
                        settings.hapticFeedback()
                        UIPasteboard.general.string = formatted(zakahDue)
                    } label: {
                        Label("Copy Amount", systemImage: "doc.on.doc")
                    }
                }
            }
        }
    }

    private var notesSection: some View {
        Section {
            Text("Zakah is 2.5% of wealth held for one full lunar year (hawl), due once your net wealth reaches the nisab. وَأَقِيمُواْ ٱلصَّلَوٰةَ وَءَاتُواْ ٱلزَّكَوٰةَ \"And establish prayer and give zakah\" (Quran 2:110). This simple calculator is a guide; for complex situations (property, retirement accounts, crops, livestock), consult a knowledgeable scholar.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func amountRow(_ title: String, systemImage: String, text: Binding<String>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundColor(settings.accentColor.color)
                .frame(width: 24, alignment: .center)

            Text(title)
                .font(.subheadline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 8)

            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.subheadline.monospacedDigit())
                .frame(maxWidth: 120)
                .focused($focusedField)
        }
        .padding(.vertical, 2)
    }

    private func resultRow(_ title: String, value: Double) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)

            Spacer()

            Text(formatted(value))
                .font(.subheadline.monospacedDigit())
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    AlIslamPreviewContainer {
        ZakahCalculatorView()
    }
}
#endif
