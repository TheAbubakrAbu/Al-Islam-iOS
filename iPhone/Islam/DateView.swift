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
            ScrollViewReader { proxy in
                List {
                    Group {
                    selectionSection
                    convertedDateSection
                    aboutHijriSection
                        #if DEBUG
                        .id("aboutHijri")
                        #endif
                    }
                    .themedListRowBackground()
                }
                #if DEBUG
                // The card sits past the graphical date picker, well below the fold, and a simulator
                // screenshot cannot scroll. `-hijriChainProbe` brings it into view.
                .onAppear {
                    guard Self.chainProbe else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { proxy.scrollTo("aboutHijri", anchor: .center) }
                    }
                }
                #endif
            }
            #endif
        }
        .navigationTitle("Hijri Converter")
        .applyConditionalListStyle()
        #if os(iOS)
        .openScreen(.hijriConverter)
        #endif
        #if DEBUG && os(iOS)
        .modifier(HijriChainProbe(active: Self.chainProbe))
        #endif
    }

    #if DEBUG && os(iOS)
    /// "-hijriChainProbe": pretend this Converter was reached FROM the Hijri Calendar, so the
    /// "already here" rows can be screenshotted without a tap (the real route needs one).
    private static let chainProbe = ProcessInfo.processInfo.arguments.contains("-hijriChainProbe")
    #endif

    #if os(iOS)
    /// The orientation card this screen never had (Abu, 2026-09-19). Converting a date is a mechanical
    /// act; a reader who does not already know what the Hijri calendar IS met two date pickers and no
    /// explanation. The prose is the Hijri Calendar screen's own opening paragraph, kept word for word
    /// so the two screens cannot drift, and the doors go to the places that say more: the full events
    /// list and the article.
    private var aboutHijriSection: some View {
        Section(header: Text("WHAT IS HIJRI?")) {
            Text("The Hijri calendar is the Islamic lunar calendar. It tracks months by moon cycles, so dates shift through the solar year and are primarily used for Islamic worship and sacred days.")
                .font(.subheadline)
                .foregroundColor(.primary)

            Text("Conversions use the Umm al-Qura Hijri method, with the Hijri offset set in app settings.")
                .font(.caption)
                .foregroundColor(.secondary)

            // Forced to `.events`: this row promises the dates, so it must not land on the month grid
            // just because that is the half the reader last had open.
            //
            // All three are `OpenScreenLink`s: the Calendar offers the Converter and the Converter
            // offers the Calendar, which is a corridor you could walk forever. Arriving here FROM the
            // Calendar greys these out rather than hiding them, so the screen keeps its shape.
            OpenScreenLink(screen: .hijriCalendar) {
                CalendarView(mode: .events)
            } label: {
                hijriDoorLabel("See All Hijri Events", systemImage: "star.circle")
            }

            OpenScreenLink(screen: .hijriArticle) {
                HijriCalendarView()
            } label: {
                hijriDoorLabel("Learn About the Hijri Calendar", systemImage: "book.pages")
            }

            OpenScreenLink(screen: .hijriCalendar) {
                CalendarView(mode: .calendar)
            } label: {
                hijriDoorLabel("Open Hijri Calendar", systemImage: "calendar")
            }
        }
    }

    /// The shared look of this card's three doors, so a disabled one differs from a live one only in
    /// colour and the missing chevron.
    private func hijriDoorLabel(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
            Text(title)
        }
        .font(.caption.weight(.semibold))
        .foregroundColor(settings.accentColor.color)
    }
    #endif

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
                // transliteration of it. Dates always render in the basic system face - the classical
                // Quranic faces are for scripture, and their ornamental digits make dates hard to read.
                Text(hijriArabicText)
                    .font(.body)
                    .arabicFontDesign(custom: false)
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
        Picker("Conversion Type", selection: $selectedTab) {
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

#if DEBUG && os(iOS)
/// Declares the Hijri Calendar "open" above this screen, for the headless screenshot of the disabled
/// rows. DEBUG only, and inert unless `-hijriChainProbe` was passed.
private struct HijriChainProbe: ViewModifier {
    let active: Bool

    func body(content: Content) -> some View {
        if active {
            content.openScreen(.hijriCalendar).openScreen(.hijriArticle)
        } else {
            content
        }
    }
}
#endif
