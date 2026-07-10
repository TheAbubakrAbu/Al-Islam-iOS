#if os(iOS)
import UIKit

/// Writes the prayer calendar to a temporary file for the share sheet.
///
/// The PDF is drawn with `UIGraphicsPDFRenderer` rather than a third-party library — a table of text in boxes
/// needs nothing more, and it keeps the dependency list empty.
enum PrayerCalendarExport {

    // US Letter at 72 dpi, the default `UIGraphicsPDFRenderer` page.
    private static let pageSize = CGSize(width: 612, height: 792)
    private static let margin: CGFloat = 40
    private static let rowHeight: CGFloat = 16
    private static let headerHeight: CGFloat = 20

    // MARK: - CSV

    static func writeCSV(months: [MonthModel], columns: [String], titles: [String], city: String) -> URL? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var lines = ["Date," + titles.map(escapeCSV).joined(separator: ",")]
        for month in months {
            for day in month.days {
                let cells = columns.map { day.times[$0] ?? "" }
                lines.append(dateFormatter.string(from: day.date) + "," + cells.map(escapeCSV).joined(separator: ","))
            }
        }

        let body = lines.joined(separator: "\n") + "\n"
        return write(body.data(using: .utf8), filename: filename(city: city, ext: "csv"))
    }

    /// RFC 4180: a field containing a comma, quote or newline is quoted, and inner quotes are doubled.
    /// Prayer names are user-editable, so a comma really can end up in a header cell.
    private static func escapeCSV(_ field: String) -> String {
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    // MARK: - PDF

    static func writePDF(months: [MonthModel], columns: [String], titles: [String], city: String) -> URL? {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))

        let data = renderer.pdfData { context in
            var y: CGFloat = .greatestFiniteMagnitude   // forces a page break before the first month
            var pageStarted = false

            func newPage() {
                context.beginPage()
                pageStarted = true
                y = margin
            }

            for month in months {
                // Keep a month's title with at least a few of its rows rather than orphaning it at a page foot.
                let neededForHeader = headerHeight * 2 + rowHeight * 3
                if !pageStarted || y + neededForHeader > pageSize.height - margin {
                    newPage()
                }

                draw(month.title, at: CGPoint(x: margin, y: y), font: .boldSystemFont(ofSize: 13))
                if !city.isEmpty {
                    let subtitle = city
                    let size = subtitle.size(withAttributes: [.font: UIFont.systemFont(ofSize: 9)])
                    draw(subtitle, at: CGPoint(x: pageSize.width - margin - size.width, y: y + 3),
                         font: .systemFont(ofSize: 9), color: .gray)
                }
                y += headerHeight

                drawRow(["Date"] + titles, y: y, font: .boldSystemFont(ofSize: 8.5), color: .darkGray)
                y += headerHeight
                drawSeparator(at: y - 4)

                for day in month.days {
                    if y + rowHeight > pageSize.height - margin {
                        newPage()
                        drawRow(["Date"] + titles, y: y, font: .boldSystemFont(ofSize: 8.5), color: .darkGray)
                        y += headerHeight
                        drawSeparator(at: y - 4)
                    }
                    let cells = [String(day.dayOfMonth)] + columns.map { day.times[$0] ?? "—" }
                    drawRow(cells, y: y,
                            font: day.isToday ? .boldSystemFont(ofSize: 9) : .systemFont(ofSize: 9),
                            color: .black)
                    y += rowHeight
                }
                y += 12
            }

            // A months list that is somehow empty would otherwise produce a zero-page, unopenable PDF.
            if !pageStarted { newPage() }
        }

        return write(data, filename: filename(city: city, ext: "pdf"))
    }

    private static func draw(_ text: String, at point: CGPoint, font: UIFont, color: UIColor = .black) {
        text.draw(at: point, withAttributes: [.font: font, .foregroundColor: color])
    }

    /// First cell left-aligned (the date), the rest right-aligned in equal columns — matching the on-screen table.
    private static func drawRow(_ cells: [String], y: CGFloat, font: UIFont, color: UIColor) {
        guard let first = cells.first else { return }
        let dateWidth: CGFloat = 40
        let usable = pageSize.width - 2 * margin - dateWidth
        let columnWidth = usable / CGFloat(max(cells.count - 1, 1))

        draw(first, at: CGPoint(x: margin, y: y), font: font, color: color)

        for (index, cell) in cells.dropFirst().enumerated() {
            let right = margin + dateWidth + columnWidth * CGFloat(index + 1)
            let size = cell.size(withAttributes: [.font: font])
            draw(cell, at: CGPoint(x: right - size.width - 4, y: y), font: font, color: color)
        }
    }

    private static func drawSeparator(at y: CGFloat) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: y))
        path.addLine(to: CGPoint(x: pageSize.width - margin, y: y))
        UIColor.lightGray.setStroke()
        path.lineWidth = 0.5
        path.stroke()
    }

    // MARK: - Files

    private static func filename(city: String, ext: String) -> String {
        // The city goes in the filename, so strip anything a filesystem would object to.
        let slug = city
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
            .lowercased()
        return slug.isEmpty ? "prayer-calendar.\(ext)" : "prayer-calendar-\(slug).\(ext)"
    }

    private static func write(_ data: Data?, filename: String) -> URL? {
        guard let data else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            logger.error("Prayer calendar export write failed: \(error.localizedDescription)")
            return nil
        }
    }
}
#endif
