import Foundation

/// How the ayah actions sheet lays its tiles out: three across, group by group, and never a tile
/// alone on a row beside empty cells.
///
/// The tiles come in the ayah menus' own groups (mark, study, play, text), and which of them exist
/// depends on the riwayah on display, the bundled packs and Apple Intelligence. A plain three-column
/// grid over a count that moves left the last tile by itself (Abu, 2026-11-18: "long hold ayah has
/// copy ayah on its own row which is ugly"). Here every row is as wide as the sheet, its tiles
/// sharing it equally: three to a row, a last pair as halves, and where one tile would be left over
/// it takes a neighbour from the row above (two and two, never three and one).
enum AyahActionLayout {
    static let columns = 3

    /// The number of tiles in each row for `count` tiles, top to bottom.
    static func rowSizes(count: Int) -> [Int] {
        guard count > 0 else { return [] }
        guard count > 1 else { return [1] }
        switch count % columns {
        case 0:
            return Array(repeating: columns, count: count / columns)
        case 1:
            // One left over: the last full row gives one up, so the end is two rows of two.
            return Array(repeating: columns, count: (count - 4) / columns) + [2, 2]
        default:
            return Array(repeating: columns, count: count / columns) + [2]
        }
    }

    /// `items` cut into those rows, in order.
    static func rows<Item>(of items: [Item]) -> [[Item]] {
        var rows: [[Item]] = []
        var start = 0
        for size in rowSizes(count: items.count) {
            rows.append(Array(items[start ..< start + size]))
            start += size
        }
        return rows
    }

    /// The groups as they are drawn: empty ones dropped, and a group of ONE folded into the group
    /// before it (the one after, when it comes first), since one tile cannot share a row with
    /// itself. A lone group of one stays: there is nothing to join.
    static func merged<Item>(_ groups: [[Item]]) -> [[Item]] {
        var result: [[Item]] = []
        var carried: [Item] = []
        for group in groups where !group.isEmpty {
            if group.count == 1, !result.isEmpty {
                result[result.count - 1].append(contentsOf: group)
            } else if group.count == 1, carried.isEmpty {
                // A leading single: held for the next group.
                carried = group
            } else {
                result.append(carried + group)
                carried = []
            }
        }
        if !carried.isEmpty { result.append(carried) }
        return result
    }
}
