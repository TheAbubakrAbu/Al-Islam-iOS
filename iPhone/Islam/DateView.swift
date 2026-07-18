import SwiftUI

struct DateView: View {
    @ObservedObject private var settings = Settings.shared

    @State private var sourceDate = Date()
    @State private var selectedTab: ConversionTab = .hijriToGregorian

    private let hijriCalendar: Calendar = {
        var cal = Calendar(identifier: .islamicUmmAlQura)
        cal.locale = Locale(identifier: "ar")
        return cal
    }()
    private let gregorianCalendar = Calendar(identifier: .gregorian)

    enum ConversionTab {
        case hijriToGregorian
        case gregorianToHijri
    }

    private static let hijriFormatterEn: DateFormatter = {
        let fmt = DateFormatter()
        var hijriCal = Calendar(identifier: .islamicUmmAlQura)
        hijriCal.locale = Locale(identifier: "ar")
        fmt.calendar = hijriCal
        fmt.locale = Locale(identifier: "en")
        fmt.dateFormat = "d MMMM yyyy"
        return fmt
    }()
    private static let gregFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.calendar = Calendar(identifier: .gregorian)
        fmt.dateFormat = "d MMMM yyyy"
        return fmt
    }()

    private var convertedDate: Date { sourceDate }

    var body: some View {
        VStack {
            #if os(iOS)
            List {
                Group {
                selectionSection
                convertedDateSection
                }
                .themedListRowBackground()
            }
            #endif
        }
        .navigationTitle("Hijri Converter")
        .applyConditionalListStyle()
    }

    private var selectionSection: some View {
        Section("SELECT DATE") {
            datePickerSection
            conversionPicker
        }
    }

    /// The same Hijri date written in Arabic: Arabic-Indic day, the month's Arabic name from the shared table, and
    /// the year followed by هـ (for hijriyyah).
    private var hijriArabicText: String {
        let components = hijriCalendar.dateComponents([.day, .month, .year], from: convertedDate)
        guard let day = components.day, let month = components.month, let year = components.year,
              let name = hijriMonths.first(where: { $0.number == month })?.arabic
        else { return "" }
        return "\(arabicNumberString(from: day)) \(name) \(arabicNumberString(from: year)) هـ"
    }

    private var convertedDateSection: some View {
        Section("CONVERTED DATES") {
            let hijriDateText = formatted(convertedDate, using: hijriCalendar)
            let gregorianDateText = formatted(convertedDate, using: gregorianCalendar)

            VStack(alignment: .leading, spacing: 6) {
                Text("Hijri")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(hijriDateText)
                    .bold()
                    .foregroundColor(settings.accentColor.color)

                // The Hijri month has an Arabic name, and this screen only ever showed the English
                // transliteration of it.
                Text(hijriArabicText)
                    .font(
                        settings.islamUsesCustomArabicFace
                            ? Font.arabic(settings.nonQuranArabicFontName, size: 20, relativeTo: .body)
                            : .body
                    )
                    .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                    .foregroundColor(.secondary)
            }
            #if os(iOS)
            .contextMenu {
                Text("Date Actions")
                    .foregroundStyle(.secondary)

                Button {
                    settings.hapticFeedback()
                    UIPasteboard.general.string = hijriDateText
                } label: {
                    Label("Copy Hijri Date", systemImage: "doc.on.doc")
                }

                Button {
                    settings.hapticFeedback()
                    UIPasteboard.general.string = hijriArabicText
                } label: {
                    Label("Copy Arabic Date", systemImage: "doc.on.doc")
                }
            }
            #endif

            VStack(alignment: .leading, spacing: 6) {
                Text("Gregorian")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(gregorianDateText)
                    .bold()
                    .foregroundColor(settings.accentColor.color)
            }
            #if os(iOS)
            .contextMenu {
                Text("Date Actions")
                    .foregroundStyle(.secondary)

                Button {
                    settings.hapticFeedback()
                    UIPasteboard.general.string = gregorianDateText
                } label: {
                    Label("Copy Gregorian Date", systemImage: "doc.on.doc")
                }
            }
            #endif
        }
    }

    @ViewBuilder
    private var datePickerSection: some View {
        let calendar = selectedTab == .hijriToGregorian ? hijriCalendar : gregorianCalendar
        let title = selectedTab == .hijriToGregorian ? "Select Hijri Date" : "Select Gregorian Date"

        VStack(alignment: .leading) {
            #if os(iOS)
            DatePicker(title, selection: $sourceDate.animation(.easeInOut), displayedComponents: .date)
                .environment(\.calendar, calendar)
                .datePickerStyle(.graphical)
                .frame(maxHeight: 400)
            #endif
        }
    }

    @ViewBuilder
    private var conversionPicker: some View {
        Picker("Conversion Type", selection: $selectedTab.animation(.easeInOut)) {
            Text("Hijri to Gregorian").tag(ConversionTab.hijriToGregorian)
            Text("Gregorian to Hijri").tag(ConversionTab.gregorianToHijri)
        }
        #if os(iOS)
        .pickerStyle(.segmented)
        #endif
        .onChange(of: selectedTab) { _ in settings.hapticFeedback() }
    }

    private func formatted(_ date: Date, using calendar: Calendar) -> String {
        if calendar.identifier == .islamicUmmAlQura {
            return Self.hijriFormatterEn.string(from: date)
        } else {
            return Self.gregFormatter.string(from: date)
        }
    }
}

#Preview {
    AlIslamPreviewContainer {
        DateView()
    }
}
