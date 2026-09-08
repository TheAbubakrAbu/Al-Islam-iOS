#if os(iOS)
import SwiftUI

/// The zakah calculator: enter what you own, subtract what is due now, and a fortieth of the rest is
/// owed once it has sat at or above the nisab for a lunar year. It does no currency conversion and
/// fetches no metal prices; every field is a plain amount in the user's own currency, and the nisab
/// is worked out from a price per gram the user looks up.
/// (`ZakahView` is taken - that's the Pillars & Beliefs page ABOUT zakah, in PillarViews.swift.)
struct ZakahCalculatorView: View {
    @ObservedObject private var settings = Settings.shared

    /// Which metal sets the threshold. Silver is the default because it is nearly always the lower
    /// of the two, and the lower one takes in more payers: the reading Ibn Baz and the Permanent
    /// Committee gave for banknotes, which have no metal of their own.
    private enum NisabBasis: String, CaseIterable {
        case silver, gold, custom

        var label: String {
            switch self {
            case .silver: return "Silver"
            case .gold: return "Gold"
            case .custom: return "Enter it"
            }
        }

        /// Ibn Baz's figures: twenty mithqal of gold and a hundred and forty of silver.
        var grams: Double {
            switch self {
            case .silver: return 595
            case .gold: return 85
            case .custom: return 0
            }
        }
    }

    /// A lunar year is the year zakah is measured in. Somebody who counts on the Gregorian calendar
    /// pays over eleven extra days each year, so the rate is raised to keep the two equal: the
    /// correction contemporary fatwa bodies settled on.
    private enum YearBasis: String, CaseIterable {
        case lunar, solar

        var label: String { self == .lunar ? "Lunar year" : "Solar year" }
        var rate: Double { self == .lunar ? 0.025 : 0.02577 }
        var rateText: String { self == .lunar ? "2.5%" : "2.577%" }
    }

    // Persisted so a work-in-progress calculation survives leaving the screen. Stored as strings
    // because they back TextFields directly; parsing happens in one place (`amount(_:)`).
    @AppStorage("zakahCash") private var cash = ""
    @AppStorage("zakahGold") private var gold = ""
    @AppStorage("zakahSilver") private var silver = ""
    @AppStorage("zakahTradeShares") private var tradeShares = ""
    @AppStorage("zakahLongShares") private var longShares = ""
    @AppStorage("zakahBusiness") private var business = ""
    @AppStorage("zakahOwedToYou") private var owedToYou = ""
    @AppStorage("zakahDebts") private var debts = ""

    @AppStorage("zakahNisabBasis") private var nisabBasisRaw = NisabBasis.silver.rawValue
    @AppStorage("zakahMetalPrice") private var metalPrice = ""
    @AppStorage("zakahNisab") private var customNisab = ""
    @AppStorage("zakahYearBasis") private var yearBasisRaw = YearBasis.lunar.rawValue

    @AppStorage("zakahFitrPeople") private var fitrPeople = 1
    @AppStorage("zakahFitrCost") private var fitrCost = ""

    @FocusState private var focusedField: Bool

    private var nisabBasis: NisabBasis { NisabBasis(rawValue: nisabBasisRaw) ?? .silver }
    private var yearBasis: YearBasis { YearBasis(rawValue: yearBasisRaw) ?? .lunar }

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
        [cash, gold, silver, tradeShares, longShares, business, owedToYou].map(amount).reduce(0, +)
    }

    private var debtsDue: Double { amount(debts) }
    private var netWealth: Double { max(totalAssets - debtsDue, 0) }

    /// The threshold in the user's own currency: grams of metal times the price they looked up, or
    /// a figure they entered themselves.
    private var nisabValue: Double {
        nisabBasis == .custom ? amount(customNisab) : amount(metalPrice) * nisabBasis.grams
    }

    /// Below-nisab only when the threshold is actually known; with the price field empty the
    /// calculator doesn't pretend to know it and simply shows the fortieth.
    private var knowsNisab: Bool { nisabValue > 0 }
    private var isBelowNisab: Bool { knowsNisab && netWealth < nisabValue }

    private var zakahDue: Double { netWealth * yearBasis.rate }
    /// The same sum with nothing taken off for the debt, because whether a debt cancels zakah on
    /// wealth already in hand is a real difference among the scholars.
    private var zakahBeforeDebts: Double { totalAssets * yearBasis.rate }

    private func formatted(_ value: Double) -> String {
        Self.currencyFormatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }

    /// "-zakahSection <name>": render one section alone. Everything below the nisab picker sits
    /// past the fold on a phone, and a simulator screenshot cannot scroll, so this is how the lower
    /// half gets verified headlessly.
    private func shows(_ name: String) -> Bool {
        #if DEBUG
        return Self.debugSection == nil || Self.debugSection == name
        #else
        return true
        #endif
    }

    #if DEBUG
    private static let debugSection: String? = {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-zakahSection"),
              index + 1 < arguments.count else { return nil }
        return arguments[index + 1]
    }()
    #endif

    var body: some View {
        List {
            Group {
                if shows("assets") { assetsSection }
                if shows("liabilities") { liabilitiesSection }
                if shows("nisab") { nisabSection }
                if shows("year") { yearSection }
                if shows("result") { resultSection }
                if shows("fitr") { fitrSection }
                if shows("other") { otherZakahSection }
                if shows("notes") { notesSection }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Zakah Calculator")
        .applyConditionalListStyle()
        #if DEBUG
        // "-focusAmount": focus the amount fields after appear (keyboard toolbar screenshot runs).
        // "-zakahSeed": a worked example, for screenshot runs.
        .onAppear {
            let arguments = ProcessInfo.processInfo.arguments
            if arguments.contains("-zakahSeed") {
                cash = "12000"; gold = "4500"; silver = ""; tradeShares = "3000"
                longShares = ""; business = "1500"; owedToYou = "800"; debts = "2000"
                nisabBasisRaw = NisabBasis.silver.rawValue
                metalPrice = "0.95"
                fitrPeople = 4
                fitrCost = "12"
            }
            if arguments.contains("-focusAmount") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { focusedField = true }
            }
        }
        #endif
        .toolbar {
            // Content only while a field is focused: with no keyboard up, SwiftUI laid the accessory
            // bar's item out with a negative width ("Invalid frame dimension" runtime issue; see
            // InheritanceView, lldb-verified 2026-09-04).
            ToolbarItemGroup(placement: .keyboard) {
                if focusedField {
                    Spacer(minLength: 0)
                    Button("Done") { focusedField = false }
                }
            }
        }
    }

    // MARK: What you own

    private var assetsSection: some View {
        Section(header: Text("ZAKATABLE ASSETS"),
                footer: Text("What you have held for a full lunar year, in your own currency. Your home, your car, your furniture and the tools you work with are not zakatable, and neither is a pension you cannot draw on yet. Gold and silver count whatever they are for, jewellery included: see the note at the bottom.")) {
            amountRow("Cash & bank balances", systemImage: "banknote", text: $cash)
            amountRow("Gold you own", systemImage: "circle.hexagongrid", text: $gold)
            amountRow("Silver you own", systemImage: "circle.grid.cross", text: $silver)
            amountRow("Shares held to trade", systemImage: "chart.line.uptrend.xyaxis", text: $tradeShares)
            amountRow("Long-term shares", systemImage: "building.columns", text: $longShares)
            amountRow("Business stock", systemImage: "shippingbox", text: $business)
            amountRow("Money owed to you", systemImage: "person.crop.circle.badge.checkmark", text: $owedToYou)
        }
    }

    private var liabilitiesSection: some View {
        Section(header: Text("WHAT YOU OWE"),
                footer: Text("Only what is actually due now: this month's bills, this year's instalments, a debt somebody can demand today. A mortgage stretching over twenty years is not subtracted whole, or almost nobody would ever pay zakah again.")) {
            amountRow("Debts due now", systemImage: "creditcard", text: $debts)
        }
    }

    // MARK: The threshold

    private var nisabSection: some View {
        Section(header: Text("NISAB"),
                footer: Text(nisabFooter)) {
            Picker("Nisab basis", selection: $nisabBasisRaw) {
                ForEach(NisabBasis.allCases, id: \.rawValue) { basis in
                    Text(basis.label).tag(basis.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.vertical, 2)

            if nisabBasis == .custom {
                amountRow("Nisab threshold", systemImage: "scalemass", text: $customNisab)
            } else {
                amountRow(nisabBasis == .gold ? "Gold price per gram" : "Silver price per gram",
                          systemImage: "tag", text: $metalPrice)

                HStack {
                    Text("Nisab (\(Int(nisabBasis.grams))g)")
                        .font(.subheadline)
                    Spacer()
                    Text(knowsNisab ? formatted(nisabValue) : "Enter a price")
                        .font(.subheadline.monospacedDigit())
                        .foregroundColor(knowsNisab ? .primary : .secondary)
                }
            }
        }
    }

    private var nisabFooter: String {
        switch nisabBasis {
        case .silver:
            return "The silver nisab is 595g, and it is nearly always the lower of the two. Banknotes are not gold or silver, so they are measured against whichever nisab is lower: that takes in more payers and is the better of the two for the poor, which is how Ibn Baz and the Permanent Committee read it. Look up today's silver price per gram and enter it."
        case .gold:
            return "The gold nisab is 85g, twenty mithqal. Look up today's gold price per gram and enter it. Gold you actually own is measured against this one; for cash, most scholars use the lower threshold instead."
        case .custom:
            return "Enter the threshold directly if you already know it in your currency. Leave it empty to skip the check and just see the fortieth."
        }
    }

    private var yearSection: some View {
        Section(header: Text("THE YEAR"),
                footer: Text("Zakah falls due when wealth has been at or above the nisab for one full lunar year (hawl). Dipping below in the middle of the year does not restart it, on the view most scholars take; only the two ends matter. If you count your year on the Gregorian calendar instead, the rate is raised to 2.577% to make up the eleven extra days.")) {
            Picker("Year", selection: $yearBasisRaw) {
                ForEach(YearBasis.allCases, id: \.rawValue) { basis in
                    Text(basis.label).tag(basis.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.vertical, 2)
        }
    }

    // MARK: The answer

    private var resultSection: some View {
        Section(header: Text("RESULT")) {
            resultRow("Total assets", value: totalAssets)
            if debtsDue > 0 {
                resultRow("Net after debts due", value: netWealth)
            }
            if knowsNisab {
                resultRow("Nisab", value: nisabValue)
            }

            if isBelowNisab {
                Text("Your wealth is below the nisab, so no zakah is due on it. Give what you like as sadaqah instead.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                HStack {
                    Text("Zakah due (\(yearBasis.rateText))")
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

                if debtsDue > 0 {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("Without deducting the debt")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatted(zakahBeforeDebts))
                                .font(.caption.monospacedDigit())
                                .foregroundColor(.secondary)
                        }
                        Text("Whether a debt cancels the zakah on wealth already in your hand is a real difference among the scholars, so both figures are shown. The safer of the two is the larger.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    // MARK: Zakat al-Fitr

    private var fitrSection: some View {
        Section(header: Text("ZAKAT AL-FITR"),
                footer: Text("A separate obligation from the zakah above, and it is not worked out on wealth. One sa‘ of the staple food people eat, for every person you are responsible for, given before the Eid prayer. Ibn ‘Umar said the Messenger of Allah (peace be upon him) made it obligatory: a sa‘ of dates or a sa‘ of barley, on the slave and the free, the male and the female, the young and the old (al-Bukhari 1503). A sa‘ is about 3kg of rice or dates. Ibn Baz, Ibn ‘Uthaymin and the Permanent Committee all held it must be given as food and not as its price; Abu Hanifa allowed the money, so the cost here is only to tell you what the food will run to.")) {
            Stepper(value: $fitrPeople, in: 1...30) {
                HStack {
                    Text("People in your household")
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

            HStack {
                Text("Food to give")
                    .font(.headline)
                Spacer()
                Text("\(fitrPeople) sa‘ (about \(Int((Double(fitrPeople) * 3).rounded()))kg)")
                    .font(.headline.monospacedDigit())
                    .foregroundColor(settings.accentColor.accent2)
            }
            .padding(.vertical, 2)

            amountRow("Cost of one sa‘ locally", systemImage: "cart", text: $fitrCost)

            if amount(fitrCost) > 0 {
                resultRow("Roughly what that costs", value: amount(fitrCost) * Double(fitrPeople))
            }
        }
    }

    // MARK: The kinds this screen does not compute

    private var otherZakahSection: some View {
        Section(header: Text("OTHER ZAKAH, NOT COUNTED ABOVE")) {
            otherRow("Crops and fruit",
                     detail: "A tenth of what rain or a spring watered, a twentieth of what you paid to irrigate (al-Bukhari 1483). Due on harvest day, with no year to wait out: وَءَاتُواْ حَقَّهُۥ يَوْمَ حَصَادِهِۦ, \"and give its due on the day of its harvest\" (6:141). The threshold is five awsuq, about 612kg of the dried crop.")
            otherRow("Grazing livestock",
                     detail: "Camels, cattle and sheep left to graze for most of the year and kept for milk or breeding. The first thresholds are five camels, thirty cattle and forty sheep, and the tables above them are long, so take the herd to someone who knows them.")
            otherRow("Buried treasure (rikaz)",
                     detail: "A fifth, straight away: وَفِى ٱلرِّكَازِ ٱلْخُمُسُ (al-Bukhari 1499). No threshold and no year to wait.")
        }
    }

    private func otherRow(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(detail)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
    }

    private var notesSection: some View {
        Section(header: Text("WHAT THIS ASSUMES")) {
            Text(Self.notes)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    static let notes = "Zakah is a fortieth of the wealth that has sat with you at or above the nisab for a lunar year. وَأَقِيمُواْ ٱلصَّلَوٰةَ وَءَاتُواْ ٱلزَّكَوٰةَ \"And establish prayer and give zakah\" (2:110). It goes to the eight kinds of people named in 9:60, and not to your parents, your children or your wife, who are yours to support anyway.\n\nWhere scholars differ, this calculator takes a side, and you should know which:\n\nGold and silver jewellery is counted, even a woman's own jewellery kept for wearing. Abu Hanifa held it is due; Malik, ash-Shafi‘i and Ahmad exempted jewellery kept for lawful use. Ibn Baz, al-Albani and the Permanent Committee held it is due, on the hadith of the woman whose daughter wore two heavy gold bangles and who was asked \"Do you pay the zakah on this?\" (Abu Dawud 1563). If you follow the other view, leave the field empty.\n\nBanknotes are measured against the lower of the two nisabs, which is silver.\n\nA debt somebody owes YOU and you expect back counts every year, as if it were in your hand. A debt on somebody who denies it or cannot pay is not counted until you actually receive it, and then for one year.\n\nShares bought to trade are counted at today's market value. Shares held for the long term are counted on the zakatable assets of the company behind them, not on the share price, so enter that part alone.\n\nBusiness stock is valued at what you would sell it for today, not what you paid.\n\nThis is a quick guide for the ordinary case, and nothing more. It is not a fatwa. Property held to rent, a business with debtors and creditors on both sides, retirement accounts, crops, livestock, gold mixed with stones, a year you are unsure of: every one of those needs a knowledgeable scholar of Ahl as-Sunnah wa al-Jamaʿah who can hear your actual situation. Ask one before you rely on this number."

    // MARK: Rows

    private func amountRow(_ title: String, systemImage: String, text: Binding<String>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundColor(settings.accentColor.color)
                .frame(width: 24, alignment: .center)

            Text(title)
                .font(.subheadline)
                // Wraps before it scales: at the large text sizes "Cash & bank balances" was
                // "Cash & bank bala..." beside the amount field.
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
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
