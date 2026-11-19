import SwiftUI

// The prayer tracker's one symbol, shared by the Adhan tab's card, the history page and the
// tracker widgets (so this file compiles into the iPhone and Widget targets).

/// How each mark presents: its words, its symbol, and its color. Each mark keeps ONE fixed color whatever
/// accent is chosen: on time green, late orange, missed red (Abu, 2026-09-27: "for prayed on time always
/// make it green", it wore the accent until then), so a blue or orange accent can never make one answer
/// look like another.
extension PrayerMark {
    var title: String {
        switch self {
        case .onTime: return String(localized: "Prayed On Time")
        case .late: return String(localized: "Prayed Late")
        case .missed: return String(localized: "Missed")
        }
    }

    var shortTitle: String {
        switch self {
        case .onTime: return String(localized: "On time")
        case .late: return String(localized: "Late")
        case .missed: return String(localized: "Missed")
        }
    }

    var spokenTitle: String {
        switch self {
        case .onTime: return String(localized: "prayed on time")
        case .late: return String(localized: "prayed late")
        case .missed: return String(localized: "missed")
        }
    }

    var symbol: String {
        switch self {
        case .onTime: return "checkmark"
        case .late: return "clock"
        case .missed: return "xmark"
        }
    }

    /// The app's readable shades of the three (`AccentColor.color`): the system colors in dark mode, and
    /// in light mode deep enough to read as text and behind a white glyph (the plain light green, orange
    /// and red measure 2.2, 2.2 and 3.6:1 on white).
    var tint: Color {
        switch self {
        case .onTime: return AccentColor.green.color
        case .late: return AccentColor.orange.color
        case .missed: return AccentColor.red.color
        }
    }
}

/// "In congregation" keeps ONE fixed colour too, for the same reason the marks do: in the accent it
/// was the on-time green under a green accent, and a row read as two "on time" chips.
enum TrackerTint {
    static var congregation: Color { AccentColor.blue.color }
}

/// One arc of the day ring: slice `index` of `count`, starting at twelve o'clock and running
/// clockwise, drawn short of its neighbours by a gap that survives the round caps.
struct PrayerRingArc: Shape {
    let index: Int
    var count = 5
    let lineWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        let radius = (min(rect.width, rect.height) - lineWidth) / 2
        guard radius > 0, count > 0 else { return Path() }
        let slice = 2 * CGFloat.pi / CGFloat(count)
        // A round cap reaches half the line's width past each end, so each end gives that back
        // and half of the visible gap besides.
        let inset = min((lineWidth / 2 + max(lineWidth * 0.3, 0.75)) / radius, slice * 0.4)
        let start = -CGFloat.pi / 2 + slice * CGFloat(index) + inset
        let end = -CGFloat.pi / 2 + slice * CGFloat(index + 1) - inset
        var path = Path()
        // `clockwise: false` in SwiftUI's flipped space is clockwise on screen.
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: radius,
                    startAngle: .radians(Double(start)), endAngle: .radians(Double(end)), clockwise: false)
        return path
    }
}

/// A day of prayer as a ring of five arcs, Fajr at twelve o'clock and on round the clock to Isha,
/// each arc in its answer's own colour: green on time, orange late, red missed, a faint track while
/// unanswered. Where the old ring and the month's heat cells could say only HOW MANY were prayed,
/// this says which, and how (Abu, 2026-11-18: "make prayer tracker so much better ui").
///
/// It always draws the five canonical prayers, also on a traveling day whose list shows three rows:
/// a combined "Dhuhr/Asr" fills two arcs, so a day reads the same whichever way it was recorded.
struct PrayerDayRing: View {
    /// The five answers in day order (`PrayerDayRing.marks(from:)`).
    let marks: [PrayerMark?]
    var lineWidth: CGFloat = 5
    /// The colour of an unanswered arc.
    var track: Color = Color.secondary.opacity(0.22)
    /// The Lock Screen draws in one colour: there a prayed arc is solid, a missed one half, and an
    /// unanswered one the faint track, since green, orange and red are not its to show.
    var monochrome = false

    var body: some View {
        ZStack {
            ForEach(0..<Self.prayers.count, id: \.self) { index in
                PrayerRingArc(index: index, count: Self.prayers.count, lineWidth: lineWidth)
                    .stroke(color(index < marks.count ? marks[index] : nil),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            }
        }
        // The arc changes colour, nothing moves: safe inside a List row whose row set must not animate.
        .animation(.easeInOut(duration: 0.25), value: marks)
        .accessibilityHidden(true)
    }

    private func color(_ mark: PrayerMark?) -> Color {
        guard monochrome else { return mark?.tint ?? track }
        switch mark {
        case .onTime, .late: return .primary
        case .missed: return Color.primary.opacity(0.5)
        case nil: return Color.primary.opacity(0.22)
        }
    }

    /// The five the ring draws, in the order it draws them.
    static let prayers = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]

    /// A day's canonical marks (`Settings.canonicalMarks`) as the ring's five.
    static func marks(from canonical: [String: PrayerMark]) -> [PrayerMark?] {
        prayers.map { canonical[$0] }
    }

    /// The ring with nothing answered: an exempt day, a day still to come.
    static let empty: [PrayerMark?] = Array(repeating: nil, count: prayers.count)
}

// MARK: - What today's card says (and the widgets, in the same words)

/// The one line the Adhan tab's tracker card leads with: what is waiting, or that nothing is.
enum TrackerDayHeadline: Equatable {
    /// Every slot prayed on time.
    case perfect
    /// Every slot prayed, at least one of them late.
    case complete
    /// `name` has begun and carries no answer; `count` slots are in that state.
    case waiting(name: String, count: Int)
    /// Nothing is waiting, and `name` begins at `time`.
    case upToDate(next: String, time: Date)
    /// Nothing is waiting and nothing more begins today (a missed mark keeps a day from complete).
    case settled
    /// A day a pause ended on, with nothing being asked of it and not all five prayed.
    case resumed
    /// No slots at all (no prayer times).
    case empty

    /// - Parameter slots: the day's trackable slots in time order, each with its display name, its
    ///   start, and its mark.
    static func make(slots: [(name: String, time: Date, mark: PrayerMark?)], isToday: Bool, now: Date) -> TrackerDayHeadline {
        guard !slots.isEmpty else { return .empty }
        if slots.allSatisfy({ $0.mark?.isPrayed == true }) {
            return slots.allSatisfy({ $0.mark == .onTime }) ? .perfect : .complete
        }
        // A day that is not today has every slot begun.
        let waiting = slots.filter { $0.mark == nil && (!isToday || $0.time <= now) }
        if let first = waiting.first {
            return .waiting(name: first.name, count: waiting.count)
        }
        if isToday, let next = slots.first(where: { $0.mark == nil && $0.time > now }) {
            return .upToDate(next: next.name, time: next.time)
        }
        return .settled
    }

    /// The headline on a day a pause ended (`Settings.isTrackerResumeDay`), made from the answered
    /// slots and the unanswered ones whose time is not over. A prayer whose time ended unanswered
    /// may have fallen inside the period, so the line never asks for it: no answer the tracker
    /// offers would be true of it.
    /// - Parameter ended: whether the slot at an index is past its time. Left out (the widgets, which
    ///   carry no end times), a slot is over once a later one has begun.
    static func makeResumed(
        slots: [(name: String, time: Date, mark: PrayerMark?)],
        isToday: Bool,
        now: Date,
        ended: ((Int) -> Bool)? = nil
    ) -> TrackerDayHeadline {
        guard !slots.isEmpty else { return .empty }
        let kept = slots.enumerated().filter { index, slot in
            if slot.mark != nil { return true }
            guard isToday else { return false }
            if let ended { return !ended(index) }
            return !slots[(index + 1)...].contains { $0.time <= now }
        }.map(\.element)
        guard !kept.isEmpty else { return .resumed }
        let headline = make(slots: kept, isToday: isToday, now: now)
        // Everything still asked for is answered, but not all five were: the day is done, and it
        // is not the complete day the ring would contradict.
        if kept.count < slots.count, headline == .perfect || headline == .complete || headline == .settled {
            return .resumed
        }
        return headline
    }

    /// The line under the day's title. `firstUse`: someone who has never marked a prayer is told
    /// how; after that the line is about the day.
    func line(firstUse: Bool = false) -> String {
        switch self {
        case .perfect:
            return String(localized: "Alhamdulillah, every prayer prayed on time.")
        case .complete:
            return String(localized: "Alhamdulillah, every prayer prayed.")
        case .waiting(let name, let count):
            if firstUse { return String(localized: "Tap a prayer to mark it prayed. Hold for late or missed.") }
            return count == 1
                ? String(localized: "\(name) is next to mark.")
                : String(localized: "\(name) and \(count - 1) more to mark.")
        case .upToDate(let next, let time):
            return String(localized: "Up to date. \(next) begins at \(time.formatted(date: .omitted, time: .shortened)).")
        case .settled:
            return String(localized: "Nothing left to mark.")
        case .resumed:
            return String(localized: "Tracking resumed. Unmarked prayers on this day are not counted.")
        case .empty:
            return String(localized: "Prayer times aren't available for this day.")
        }
    }
}
