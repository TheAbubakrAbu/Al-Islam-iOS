#if os(iOS)
import SwiftUI
import UIKit

/// Thirteen months of prayer times - this month plus a year ahead - browsable, and exportable as PDF or CSV.
///
/// Months are computed lazily as they scroll into view. A full year is ~400 days × 6 prayers, and computing
/// that eagerly on `onAppear` stalls the push animation; `MonthModel` is built on demand and cached.
struct PrayerCalendarView: View {
    @ObservedObject var settings = Settings.shared

    @State private var months: [MonthModel] = []
    @State private var shareItem: ShareItem?
    @State private var isExporting = false

    /// The `.caf`-style ordering the app uses everywhere else. Shurooq is included because a prayer
    /// calendar without sunrise is far less useful, even though it isn't a prayer.
    private static let columns = ["Fajr", "Shurooq", "Dhuhr", "Asr", "Maghrib", "Isha"]

    private struct ShareItem: Identifiable {
        let id = UUID()
        let url: URL
    }

    var body: some View {
        List {
            if settings.currentLocation == nil {
                Text("Prayer times need a location before a calendar can be built.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ForEach(months) { month in
                    Section(header: monthHeader(month)) {
                        columnHeader
                            .listRowInsets(EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10))
                        ForEach(month.days) { day in
                            dayRow(day)
                        }
                    }
                }
            }
        }
        .themedListRowBackground()
        .applyConditionalListStyle()
        .navigationTitle("Prayer Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { exportMenu }
        .task { buildMonthsIfNeeded() }
        .sheet(item: $shareItem) { item in
            ActivityView(activityItems: [item.url])
        }
    }

    // MARK: Rows

    private func monthHeader(_ month: MonthModel) -> some View {
        Text(month.title.uppercased())
    }

    private var columnHeader: some View {
        HStack(spacing: 2) {
            Text("")
                .frame(width: dayColumnWidth, alignment: .leading)
            ForEach(Self.columns, id: \.self) { column in
                // Full names, scaled to fit. `Al-Asr` truncates to a meaningless "Al-" if you clip to three
                // characters, and a user's own spelling can be any length at all.
                Text(settings.customPrayerName(for: column) ?? column)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .font(.caption2.weight(.semibold))
        .foregroundColor(.secondary)
    }

    private let dayColumnWidth: CGFloat = 38

    private func dayRow(_ day: DayModel) -> some View {
        HStack(spacing: 2) {
            HStack(spacing: 3) {
                Text("\(day.dayOfMonth)")
                    .font(.caption2.weight(day.isToday ? .bold : .regular).monospacedDigit())
                MoonPhaseGlyph(illumination: day.moon.illumination, isWaxing: day.moon.isWaxing)
                    .frame(width: 8, height: 8)
                    .foregroundColor(.secondary)
            }
            .frame(width: dayColumnWidth, alignment: .leading)

            ForEach(Self.columns, id: \.self) { column in
                Text(day.times[column] ?? "- ")
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    // Six times across a phone is tight; let them shrink rather than wrap onto a second line.
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            }
        }
        .font(.caption2.monospacedDigit())
        .foregroundColor(day.isToday ? settings.accentColor.color : .primary)
        .listRowInsets(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
        .listRowBackground(day.isToday ? settings.accentColor.color.opacity(0.12) : nil)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(day.accessibilityLabel)
    }

    // MARK: Export

    private var exportMenu: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button {
                    settings.hapticFeedback()
                    export(.pdf)
                } label: {
                    Label("Export PDF", systemImage: "doc.richtext")
                }
                Button {
                    settings.hapticFeedback()
                    export(.csv)
                } label: {
                    Label("Export CSV", systemImage: "tablecells")
                }
            } label: {
                if isExporting {
                    ProgressView()
                } else {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            .disabled(months.isEmpty || isExporting)
        }
    }

    private enum ExportFormat { case pdf, csv }

    private func export(_ format: ExportFormat) {
        isExporting = true
        let months = self.months
        let city = settings.currentLocation?.city ?? ""
        let columns = Self.columns
        let titles = columns.map { settings.customPrayerName(for: $0) ?? $0 }

        // Rendering a year of tables is slow enough to drop frames on the main thread.
        DispatchQueue.global(qos: .userInitiated).async {
            let url: URL?
            switch format {
            case .csv: url = PrayerCalendarExport.writeCSV(months: months, columns: columns, titles: titles, city: city)
            case .pdf: url = PrayerCalendarExport.writePDF(months: months, columns: columns, titles: titles, city: city)
            }
            DispatchQueue.main.async {
                isExporting = false
                guard let url else {
                    logger.error("Prayer calendar export failed")
                    return
                }
                shareItem = ShareItem(url: url)
            }
        }
    }

    // MARK: Model

    private func buildMonthsIfNeeded() {
        guard months.isEmpty, settings.currentLocation != nil else { return }
        months = PrayerCalendarBuilder.months(count: 13, settings: settings, columns: Self.columns)
    }
}

// MARK: - Models

struct DayModel: Identifiable {
    let id: Date
    let date: Date
    let dayOfMonth: Int
    let isToday: Bool
    let moon: MoonPhase
    /// Formatted times keyed by canonical transliteration. Missing keys (polar day) render as an em dash.
    let times: [String: String]

    var accessibilityLabel: String {
        let list = times.map { "\($0.key) \($0.value)" }.sorted().joined(separator: ", ")
        return "Day \(dayOfMonth). \(list)"
    }
}

struct MonthModel: Identifiable {
    let id: Date
    let title: String
    let days: [DayModel]
}

enum PrayerCalendarBuilder {
    private static let monthTitleFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy"
        return f
    }()

    static func months(count: Int, settings: Settings, columns: [String]) -> [MonthModel] {
        let calendar = Calendar.current
        let today = Date()
        let thisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today

        return (0..<count).compactMap { offset in
            guard let monthStart = calendar.date(byAdding: .month, value: offset, to: thisMonth),
                  let range = calendar.range(of: .day, in: .month, for: monthStart) else { return nil }

            let days: [DayModel] = range.compactMap { dayOfMonth in
                guard let date = calendar.date(byAdding: .day, value: dayOfMonth - 1, to: monthStart) else { return nil }
                let prayers = settings.getPrayerTimes(for: date, fullPrayers: true) ?? []

                var times: [String: String] = [:]
                for prayer in prayers where columns.contains(prayer.nameTransliteration) {
                    times[prayer.nameTransliteration] = settings.formatDate(prayer.time)
                }
                // Friday replaces Dhuhr with Jumuah, but a calendar column is a time slot, not a name.
                if let jumuah = prayers.first(where: { $0.nameTransliteration == "Jumuah" }) {
                    times["Dhuhr"] = settings.formatDate(jumuah.time)
                }

                return DayModel(
                    id: date,
                    date: date,
                    dayOfMonth: dayOfMonth,
                    isToday: calendar.isDate(date, inSameDayAs: today),
                    moon: .on(calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date),
                    times: times
                )
            }

            return MonthModel(id: monthStart, title: monthTitleFormatter.string(from: monthStart), days: days)
        }
    }
}
#endif
