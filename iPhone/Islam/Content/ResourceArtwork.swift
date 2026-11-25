#if os(iOS)
import SwiftUI
import UIKit

// The pictures at the foot of the Islam resources' opening cards (`ResourceHero`).
//
// Abu, 2026-11-24: "for pillars and beliefs u know how there's cool artwork at the top? Each Islamic
// resource should get one". Pillars & Beliefs opens on the hadith of the five drawn as a building
// (`IslamPillarsHero`); every other resource now opens on a drawing of the same kind: a real count,
// cycle or structure from its subject, in shapes, SF Symbols and a few words. None of it is
// decoration: each piece's doc comment says what it draws and the source it rests on.
//
// House rules for every piece here:
// - colours only from the accent (fills 0.06 to 0.16, hairlines 0.25 to 0.35) and .primary/.secondary,
//   so it reads in light and dark and with any accent;
// - a fixed height that never depends on a measured width (each piece is part of ONE List row, and a
//   row that answers a different height on each self-sizing pass traps on iOS 26): no GeometryReader,
//   no lazy grid, no continuous animation;
// - one VoiceOver element per piece, describing what it shows (`artFrame`);
// - type grows with Dynamic Type only so far (`artFrame`), and every line can shrink to fit;
// - pure drawing: no Quran, Hadith or prayer-time types, so Al-Quran and Al-Adhan compile it too
//   (their floor is iOS 15, so nothing here needs iOS 16 unguarded);
// - the pieces that sit on English article pages (Miracles of the Quran, Miracles of the Prophets,
//   Prophecies, Sunnahs, Proving Islam, and the six reading libraries: Stories of the Prophets;
//   Sahabah, Ahlul Bayt & Salaf; Refuting Religions; Preservation of the Quran; Science of Hadith;
//   The Domino Process) keep English the way those pages do (`AppLanguage.article`), as the Pillars
//   building does; the rest are catalog keys.

// MARK: - Shared pieces

/// The art's tracked caption, the Pillars building's own type ("ISLAM IS BUILT ON FIVE").
private struct ArtCaption: View {
    @Environment(\.appearance) private var appearance
    private let text: Text
    private let color: Color?

    init(_ key: LocalizedStringKey, color: Color? = nil) {
        text = Text(key)
        self.color = color
    }

    /// On an English article page: English while the articles are (`AppLanguage.article`).
    init(article english: String, color: Color? = nil) {
        text = Text(verbatim: AppLanguage.article(english))
        self.color = color
    }

    var body: some View {
        text
            .font(.system(size: 9, weight: .heavy))
            .tracking(AppLanguage.letterSpacing(1.4))
            .foregroundColor(color ?? appearance.accent)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }
}

/// Arabic in the art: the Islam tab's face, or the Quran face for Quranic words, which carry the
/// mushaf's marks the system face cannot draw (`QuranicInline`).
private struct ArtArabic: View {
    @Environment(\.appearance) private var appearance

    let text: String
    let size: CGFloat
    var quran = false
    var color: Color = .primary
    var highlightAllah = true
    /// Printed plain, in the system face whatever the reader's Arabic face, as `StudyArabicText` prints a
    /// bare letter: a mushaf face draws a lone yaa without its dots (ى), which spells another letter.
    var plain = false

    init(_ text: String, size: CGFloat, quran: Bool = false, color: Color = .primary, highlightAllah: Bool = true,
         plain: Bool = false) {
        self.text = text
        self.size = size
        self.quran = quran
        self.color = color
        self.highlightAllah = highlightAllah
        self.plain = plain && !quran
    }

    var body: some View {
        Text.islamArabic(text, highlightAllah: highlightAllah && appearance.highlightAllahIslam)
            .font(quran
                  ? Font.arabic(appearance.quranDisplayFace, size: size * QuranicInline.scale)
                  : plain ? .system(size: size * 0.9) : appearance.islamArabicFont(base: size, relativeTo: .caption))
            .arabicFontDesign(custom: quran || (!plain && appearance.islamUsesCustomArabicFace))
            .foregroundColor(color)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }
}

/// A fraction set the way it is written by hand, the numerator over the denominator, in the
/// locale's digits.
private struct ArtFraction: View {
    let numerator: Int
    let denominator: Int
    var size: CGFloat = 13
    let color: Color

    var body: some View {
        VStack(spacing: 1) {
            Text(verbatim: "\(numerator)".localizedDigits)
            Rectangle()
                .fill(color)
                .frame(width: size * 0.95, height: 1.2)
            Text(verbatim: "\(denominator)".localizedDigits)
        }
        .font(.system(size: size, weight: .bold, design: .rounded))
        .foregroundColor(color)
        .fixedSize()
    }
}

/// An SF Symbol newer than the siblings' iOS 15 floor gets a stand-in there, never an empty hole.
private func artSymbol(_ name: String, or fallback: String) -> String {
    UIImage(systemName: name) == nil ? fallback : name
}

/// A point at `radius` from the centre, `degrees` clockwise from twelve o'clock.
private func artPoint(degrees: Double, radius: CGFloat) -> CGSize {
    let radians = degrees * .pi / 180
    return CGSize(width: radius * CGFloat(sin(radians)), height: -radius * CGFloat(cos(radians)))
}

private extension View {
    /// The panel a piece sits on: the Pillars foundation's wash and hairline.
    func artPanel(_ accent: Color, radius: CGFloat = 12) -> some View {
        background(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(accent.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(accent.opacity(0.25), lineWidth: 1))
        )
    }

    /// Every piece: one element for VoiceOver with what it shows, and type that grows only so far
    /// inside a drawing of fixed size (every line also shrinks to fit).
    func artFrame(_ label: Text) -> some View {
        dynamicTypeSize(...DynamicTypeSize.xxLarge)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
    }
}

/// A circle's slice from twelve o'clock, clockwise: an inheritance share as a pie.
private struct PieSlice: Shape {
    var fraction: Double

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: .degrees(-90),
                    endAngle: .degrees(-90 + 360 * fraction), clockwise: false)
        path.closeSubpath()
        return path
    }
}

/// An arc of a ring between two clock angles (degrees clockwise from twelve).
private struct RingArc: Shape {
    let from: Double
    let to: Double
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: radius,
                    startAngle: .degrees(from - 90), endAngle: .degrees(to - 90), clockwise: false)
        return path
    }
}

// MARK: - Dua & Supplications

/// Dua & Supplications (Abu, 2026-11-24: "Each Islamic resource should get one"): the hours a dua is
/// most hoped to be answered, as three lines of time with the hour lit on each.
/// - The night, Maghrib to Fajr in thirds, the last lit: Allah descends when the last third remains and
///   asks who is calling on Him (Sahih al-Bukhari 1145).
/// - The prayer: between the adhan and the iqamah (Sunan Abi Dawud 521, Jami at-Tirmidhi 212, sahih),
///   then the prayer with its prostrations lit, the nearest a servant is to his Lord (Sahih Muslim 482).
/// - Friday: the other six days, then Friday's twelve hours with the last lit, the hour of answer
///   sought "in the last hour after 'Asr" (Sunan Abi Dawud 1048, sahih; the hour itself, Sahih
///   al-Bukhari 935).
struct DuaAnswerHoursArt: View {
    @Environment(\.appearance) private var appearance

    /// Saturday to Thursday by the Calendar's weekday numbers (Sunday is 1): the week the way the
    /// Arabic calendar runs it, so it ends on Friday.
    private static let daysBeforeFriday = [7, 1, 2, 3, 4, 5]

    var body: some View {
        let accent = appearance.accent
        return VStack(alignment: .leading, spacing: 10) {
            ArtCaption("THE HOURS OF ANSWER")

            line(symbol: "moon.stars.fill", title: Text("Night"), accent: accent) {
                night(accent)
            }
            line(symbol: "speaker.wave.2.fill", title: Text("Prayer"), accent: accent) {
                prayer(accent)
            }
            line(symbol: "calendar", title: Text("Friday"), accent: accent) {
                friday(accent)
            }
        }
        .padding(12)
        .artPanel(accent)
        .artFrame(Text("When a dua is most hoped to be answered: in the last third of the night, between the adhan and the iqamah, in prostration, and in the last hour of Friday, after Asr."))
    }

    private func line<Bar: View>(symbol: String, title: Text, accent: Color, @ViewBuilder bar: () -> Bar) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 2) {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(accent)
                title
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(width: 52)

            bar()
        }
    }

    private func tick(_ text: Text) -> some View {
        text
            .font(.system(size: 9, weight: .semibold))
            .foregroundColor(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }

    private func night(_ accent: Color) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { third in
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(third == 2 ? accent.opacity(0.9) : accent.opacity(0.13))
                        .overlay(
                            Group {
                                if third == 2 {
                                    Text(verbatim: "1/3".localizedDigits)
                                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                                        .foregroundColor(.white)
                                }
                            }
                        )
                }
            }
            .frame(height: 18)

            HStack {
                tick(Text("Maghrib"))
                Spacer(minLength: 4)
                tick(Text("Fajr"))
            }
        }
    }

    private func prayer(_ accent: Color) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 3) {
                // Between the adhan and the iqamah.
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(accent.opacity(0.9))
                // The prayer, its prostrations lit.
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(accent.opacity(0.13))
                    .overlay(
                        HStack(spacing: 9) {
                            ForEach(0..<4, id: \.self) { _ in
                                Circle()
                                    .fill(accent.opacity(0.9))
                                    .frame(width: 6, height: 6)
                            }
                        }
                    )
            }
            .frame(height: 18)

            HStack(spacing: 3) {
                HStack {
                    tick(Text("Adhan"))
                    Spacer(minLength: 2)
                    tick(Text("Iqamah"))
                }
                .frame(maxWidth: .infinity)
                tick(Text("Prostration"))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func friday(_ accent: Color) -> some View {
        let symbols = Calendar.current.veryShortWeekdaySymbols
        return VStack(spacing: 3) {
            HStack(spacing: 3) {
                ForEach(Self.daysBeforeFriday, id: \.self) { weekday in
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(accent.opacity(0.07))
                        .overlay(
                            Text(verbatim: symbols.indices.contains(weekday - 1) ? symbols[weekday - 1] : "")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        )
                        .frame(width: 15)
                }

                // Friday's twelve hours, the last lit.
                HStack(spacing: 1.5) {
                    ForEach(0..<12, id: \.self) { hour in
                        Capsule()
                            .fill(hour == 11 ? accent.opacity(0.95) : accent.opacity(0.25))
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 5, style: .continuous).fill(accent.opacity(0.13)))
            }
            .frame(height: 18)

            HStack {
                Spacer(minLength: 4)
                tick(Text("Asr"))
            }
        }
    }
}

// MARK: - Tasbih Counter

/// Tasbih Counter: a string of a hundred beads, the words said after every prescribed prayer.
/// "Glory be to Allah" thirty-three times, "Praise be to Allah" thirty-three times, "Allah is most
/// Great" thirty-four times (Sahih Muslim 596). Three arcs of one loop, a marker bead between them and
/// the head bead and its tassel where they meet; the words sit inside, each beside its own arc.
struct TasbihBeadsArt: View {
    @Environment(\.appearance) private var appearance

    private static let words: [(count: Int, arabic: String)] = [
        (33, "سُبْحَانَ اللَّهِ"),
        (33, "الْحَمْدُ لِلَّهِ"),
        (34, "اللَّهُ أَكْبَرُ"),
    ]

    var body: some View {
        let accent = appearance.accent
        return VStack(alignment: .leading, spacing: 8) {
            ArtCaption("AFTER EVERY PRAYER")

            VStack(spacing: -5) {
                ZStack {
                    TasbihLoop(part: .beads).fill(accent.opacity(0.7))
                        .flipsForRightToLeftLayoutDirection(true)
                    TasbihLoop(part: .markers).fill(accent)
                        .flipsForRightToLeftLayoutDirection(true)

                    HStack(spacing: 6) {
                        ForEach(Self.words.indices, id: \.self) { index in
                            VStack(spacing: 3) {
                                Text(verbatim: "\(Self.words[index].count)".localizedDigits)
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(accent)
                                ArtArabic(Self.words[index].arabic, size: 14)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 22)
                }
                .frame(height: 116)

                TasbihTassel()
                    .stroke(accent.opacity(0.85), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                    .frame(width: 22, height: 18)
            }
        }
        .padding(.vertical, 2)
        .artFrame(Text("A string of a hundred beads: thirty-three for Subhan Allah, thirty-three for Alhamdulillah and thirty-four for Allahu Akbar, said after every prayer."))
    }
}

/// The misbaha's loop: 33, 33 and 34 beads round a capsule, a marker bead between the groups and the
/// head bead at the bottom, where the counting starts and ends.
private struct TasbihLoop: Shape {
    enum Part { case beads, markers }
    let part: Part

    private static let groups = [33, 33, 34]
    /// Slots along the loop, in bead widths: a marker takes a little more than a bead, the head more.
    private static let marker: CGFloat = 1.7
    private static let head: CGFloat = 3.4

    func path(in rect: CGRect) -> Path {
        let loop = rect.insetBy(dx: 5, dy: 5)
        let radius = loop.height / 2
        let straight = max(0, loop.width - loop.height)
        let arc = CGFloat.pi * radius
        let perimeter = 2 * straight + 2 * arc
        let units = CGFloat(Self.groups.reduce(0, +)) + CGFloat(Self.groups.count - 1) * Self.marker + Self.head
        let unit = perimeter / units
        let beadRadius = min(unit * 0.42, 3.6)

        // From the bottom centre, round to the left, over the top and back: clockwise on screen.
        func point(_ distance: CGFloat) -> CGPoint {
            var s = distance.truncatingRemainder(dividingBy: perimeter)
            if s < straight / 2 { return CGPoint(x: loop.midX - s, y: loop.maxY) }
            s -= straight / 2
            if s < arc {
                let angle = CGFloat.pi / 2 + s / radius
                return CGPoint(x: loop.minX + radius + radius * cos(angle), y: loop.midY + radius * sin(angle))
            }
            s -= arc
            if s < straight { return CGPoint(x: loop.minX + radius + s, y: loop.minY) }
            s -= straight
            if s < arc {
                let angle = -CGFloat.pi / 2 + s / radius
                return CGPoint(x: loop.maxX - radius + radius * cos(angle), y: loop.midY + radius * sin(angle))
            }
            s -= arc
            return CGPoint(x: loop.maxX - radius - s, y: loop.maxY)
        }

        func circle(_ center: CGPoint, _ r: CGFloat) -> CGRect {
            CGRect(x: center.x - r, y: center.y - r, width: 2 * r, height: 2 * r)
        }

        var path = Path()
        var distance = Self.head / 2 * unit
        for (index, count) in Self.groups.enumerated() {
            for _ in 0..<count {
                if part == .beads { path.addEllipse(in: circle(point(distance + unit / 2), beadRadius)) }
                distance += unit
            }
            if index < Self.groups.count - 1 {
                if part == .markers {
                    path.addEllipse(in: circle(point(distance + Self.marker * unit / 2), beadRadius * 1.45))
                }
                distance += Self.marker * unit
            }
        }
        if part == .markers {
            // The head bead, long, where the tassel hangs.
            let head = point(0)
            path.addRoundedRect(in: CGRect(x: head.x - beadRadius * 1.3, y: head.y - beadRadius * 1.5,
                                           width: beadRadius * 2.6, height: beadRadius * 3.6),
                                cornerSize: CGSize(width: beadRadius * 1.3, height: beadRadius * 1.3))
        }
        return path
    }
}

/// The tassel under the head bead.
private struct TasbihTassel: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let top = CGPoint(x: rect.midX, y: rect.minY)
        for strand in -3...3 {
            path.move(to: top)
            path.addLine(to: CGPoint(x: rect.midX + CGFloat(strand) * rect.width / 7, y: rect.maxY))
        }
        return path
    }
}

// MARK: - 99 Names of Allah

/// 99 Names of Allah: ninety-nine points in three rings of thirty-three around the name of Allah, one
/// for each of His names in the list's order, the reader's favorites lit. "Allah has ninety-nine
/// names, one hundred minus one; whoever enumerates them enters Paradise" (Sahih al-Bukhari 2736),
/// whose "مِائَةً إِلَّا وَاحِدًا" stands beside it.
struct NamesRosetteArt: View {
    @Environment(\.appearance) private var appearance

    /// The numbers (1...99) of the names the reader has favorited.
    let favorites: Set<Int>

    var body: some View {
        let accent = appearance.accent
        return HStack(spacing: 16) {
            ZStack {
                NamesRosette(numbers: Set(1...99).subtracting(favorites), radius: 2.3)
                    .fill(accent.opacity(0.5))
                NamesRosette(numbers: favorites, radius: 3.6)
                    .fill(accent)
                ArtArabic("اللَّه", size: 26, color: accent)
            }
            .frame(width: 150, height: 150)

            VStack(alignment: .leading, spacing: 5) {
                ArtCaption("ONE HUNDRED MINUS ONE")
                ArtArabic("مِائَةً إِلَّا وَاحِدًا", size: 16)
                Text(verbatim: "99".localizedDigits)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(accent)
                HStack(spacing: 5) {
                    Circle()
                        .fill(accent)
                        .frame(width: 7, height: 7)
                    Text("favorites")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                // The line keeps its place with no favorites, so the card's height never changes.
                .opacity(favorites.isEmpty ? 0 : 1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .artFrame(Text("Ninety-nine points around the name of Allah, one for each of His names, with your favorites lit."))
    }
}

/// The names' points: name n sits on ring (n - 1) / 33 at place (n - 1) % 33, each ring turned half
/// a step from the one inside it so the three make a rosette.
private struct NamesRosette: Shape {
    let numbers: Set<Int>
    let radius: CGFloat

    private static let rings: [CGFloat] = [40, 55, 70]

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let scale = min(rect.width, rect.height) / 150
        var path = Path()
        for number in numbers where (1...99).contains(number) {
            let ring = (number - 1) / 33
            let place = (number - 1) % 33
            let degrees = (Double(place) + Double(ring) * 0.5) * 360 / 33
            let offset = artPoint(degrees: degrees, radius: Self.rings[ring] * scale)
            path.addEllipse(in: CGRect(x: center.x + offset.width - radius, y: center.y + offset.height - radius,
                                       width: 2 * radius, height: 2 * radius))
        }
        return path
    }
}

// MARK: - Zakah Calculator

/// Zakah Calculator: the rate as the Prophet's letter on zakah words it, "a quarter of a tenth" (رُبْعُ
/// الْعُشْرِ, on silver: Sahih al-Bukhari 1454). Forty cells in ten columns: one column, a tenth, marked;
/// one cell of it, a quarter of that tenth, filled: one fortieth, the 2.5% the card's first figure gives.
struct ZakahQuarterTenthArt: View {
    @Environment(\.appearance) private var appearance

    var body: some View {
        let accent = appearance.accent
        return VStack(alignment: .leading, spacing: 9) {
            ArtCaption("A QUARTER OF A TENTH")

            HStack(alignment: .center, spacing: 16) {
                HStack(spacing: 3) {
                    ForEach(0..<10, id: \.self) { column in
                        VStack(spacing: 3) {
                            ForEach(0..<4, id: \.self) { row in
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(fill(column: column, row: row, accent: accent))
                                    .frame(height: 11)
                            }
                        }
                        .background(
                            Group {
                                if column == 9 {
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .strokeBorder(accent.opacity(0.6), lineWidth: 1)
                                        .padding(-2.5)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 2.5)

                // The sum the grid draws (the rate itself is the card's first figure).
                VStack(alignment: .leading, spacing: 2) {
                    ArtArabic("رُبْعُ الْعُشْرِ", size: 17, color: accent)
                    Text(verbatim: "1/4 \u{00D7} 1/10".localizedDigits)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                    Text(verbatim: "= 1/40".localizedDigits)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .fixedSize()
            }
        }
        .padding(12)
        .artPanel(accent)
        .artFrame(Text("Forty cells: one tenth of them marked, and a quarter of that tenth filled. One fortieth, two and a half percent: the zakah due on wealth held for a lunar year."))
    }

    private func fill(column: Int, row: Int, accent: Color) -> Color {
        guard column == 9 else { return accent.opacity(0.13) }
        return row == 0 ? accent.opacity(0.95) : accent.opacity(0.32)
    }
}

// MARK: - Inheritance Calculator

/// Inheritance Calculator: the six shares Surah an-Nisa names, as pies, with the heirs who can take
/// each. They come in two families, as the scholars of fara'id teach them: a half, its half and its
/// quarter (½, ¼, ⅛), and two thirds, its half and its quarter (⅔, ⅓, ⅙). Every pairing is the ayah's:
/// - ½ the husband with no child (4:12), an only daughter (4:11), an only full sister (4:176);
/// - ¼ the husband with a child, the wives with none (4:12); ⅛ the wives with a child (4:12);
/// - ⅔ two or more daughters (4:11), two or more sisters (4:176);
/// - ⅓ the mother with no child and fewer than two siblings (4:11), maternal half-siblings together (4:12);
/// - ⅙ the father or the mother beside a child (4:11).
/// The conditions are the calculator's to apply; the art shows only who can ever take each share.
struct InheritanceSharesArt: View {
    @Environment(\.appearance) private var appearance

    private struct Share {
        let numerator: Int
        let denominator: Int
        let heirs: [Text]
    }

    private var shares: [Share] {
        [
            Share(numerator: 1, denominator: 2, heirs: [Text("Husband"), Text("Daughter"), Text("Full sister")]),
            Share(numerator: 1, denominator: 4, heirs: [Text("Husband"), Text("Wives")]),
            Share(numerator: 1, denominator: 8, heirs: [Text("Wives")]),
            Share(numerator: 2, denominator: 3, heirs: [Text("Daughters"), Text("Full sisters")]),
            Share(numerator: 1, denominator: 3, heirs: [Text("Mother"), Text("Maternal half-siblings")]),
            Share(numerator: 1, denominator: 6, heirs: [Text("Father"), Text("Mother")]),
        ]
    }

    var body: some View {
        let accent = appearance.accent
        return VStack(alignment: .leading, spacing: 8) {
            ArtCaption("WHO CAN TAKE EACH SHARE")

            // Not lazy (`SummaryTileGrid`): a lazy grid in a List row can answer a different height on
            // each self-sizing pass, which iOS 26 traps on.
            SummaryTileGrid(columns: 3, spacing: 6) {
                ForEach(shares.indices, id: \.self) { index in
                    tile(shares[index], accent: accent)
                }
            }
        }
        .artFrame(Text("The six shares Surah an-Nisa names. One half: the husband, an only daughter, an only full sister. One quarter: the husband, the wives. One eighth: the wives. Two thirds: daughters, full sisters. One third: the mother, maternal half-siblings. One sixth: the father, the mother."))
    }

    private func tile(_ share: Share, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                ZStack {
                    Circle().fill(accent.opacity(0.13))
                    PieSlice(fraction: Double(share.numerator) / Double(share.denominator))
                        .fill(accent.opacity(0.9))
                    Circle().strokeBorder(accent.opacity(0.4), lineWidth: 1)
                }
                .frame(width: 26, height: 26)

                ArtFraction(numerator: share.numerator, denominator: share.denominator, size: 12, color: accent)
            }

            VStack(alignment: .leading, spacing: 1) {
                ForEach(share.heirs.indices, id: \.self) { index in
                    share.heirs[index]
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 40, maxHeight: 40, alignment: .topLeading)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .artPanel(accent, radius: 10)
    }
}

// MARK: - Hijri Date Converter

/// Hijri Date Converter: the twelve lunar months as new crescents round a ring, Muharram at the top.
/// "The number of months with Allah is twelve; of these, four are sacred" (Quran 9:36), and the ring
/// shows where they fall: Dhul-Qa'dah, Dhul-Hijjah and Muharram in a row, and Rajab, alone, straight
/// across from Muharram ("three in succession ... and Rajab of Mudar, between Jumada and Sha'ban",
/// Sahih al-Bukhari 3197). Ramadan carries its star; the month of the date on the converter is ringed.
struct HijriMonthsRingArt: View {
    @Environment(\.appearance) private var appearance

    /// The Hijri month (1...12) of the date on the converter, ringed; nil rings none.
    let month: Int?

    private static let names = [
        "مُحَرَّم", "صَفَر", "رَبِيع الأَوَّل", "رَبِيع الآخِر", "جُمَادَى الأُولَى", "جُمَادَى الآخِرَة",
        "رَجَب", "شَعْبَان", "رَمَضَان", "شَوَّال", "ذُو القَعْدَة", "ذُو الحِجَّة",
    ]
    private static let sacred: Set<Int> = [1, 7, 11, 12]
    private static let ring: CGFloat = 58
    private static let labelRadius: CGFloat = 80
    private static let labelWidth: CGFloat = 66

    private static func degrees(_ month: Int) -> Double { Double(month - 1) * 30 }

    var body: some View {
        let accent = appearance.accent
        return VStack(alignment: .leading, spacing: 4) {
            ArtCaption("TWELVE MONTHS, FOUR SACRED")

            ZStack {
                // The three sacred months in a row, and Rajab on its own across the ring.
                RingArc(from: Self.degrees(11), to: Self.degrees(13), radius: Self.ring)
                    .stroke(accent.opacity(0.16), style: StrokeStyle(lineWidth: 28, lineCap: .round))
                Circle()
                    .fill(accent.opacity(0.16))
                    .frame(width: 28, height: 28)
                    .offset(artPoint(degrees: Self.degrees(7), radius: Self.ring))

                Circle()
                    .stroke(accent.opacity(0.25), lineWidth: 1)
                    .frame(width: 2 * Self.ring, height: 2 * Self.ring)

                ForEach(1...12, id: \.self) { month in
                    crescent(month, accent: accent)
                        .offset(artPoint(degrees: Self.degrees(month), radius: Self.ring))
                }

                ForEach(1...12, id: \.self) { month in
                    label(month, accent: accent)
                }

                VStack(spacing: 0) {
                    Text(verbatim: "12".localizedDigits)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(accent)
                    ArtArabic("أَرۡبَعَةٌ حُرُمٞ", size: 10, quran: true, color: .secondary)
                        .frame(width: 70)
                }
            }
            .frame(width: 2 * (Self.labelRadius + Self.labelWidth), height: 2 * Self.labelRadius + 18)
            // A drawing, not a layout: the ring keeps its clockwise order in every language.
            .environment(\.layoutDirection, .leftToRight)
            .frame(maxWidth: .infinity)
        }
        .artFrame(Text("The twelve lunar months in a ring. Four are sacred: Dhul-Qa'dah, Dhul-Hijjah and Muharram in a row, and Rajab, alone, across the ring from Muharram."))
    }

    private func crescent(_ month: Int, accent: Color) -> some View {
        let sacred = Self.sacred.contains(month)
        return ZStack {
            Circle()
                .fill(sacred ? accent : accent.opacity(month == 9 ? 0.25 : 0.1))
            Image(systemName: month == 9 ? "moon.stars.fill" : "moon.fill")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(sacred ? .white : accent)
        }
        .frame(width: 22, height: 22)
        .overlay(
            Circle()
                .strokeBorder(Color.primary.opacity(month == self.month ? 0.85 : 0), lineWidth: 1.5)
                .padding(-4)
        )
    }

    private func label(_ month: Int, accent: Color) -> some View {
        let point = artPoint(degrees: Self.degrees(month), radius: Self.labelRadius)
        let side = point.width / Self.labelRadius
        let alignment: Alignment = abs(side) < 0.3 ? .center : (side > 0 ? .leading : .trailing)
        let shift: CGFloat = abs(side) < 0.3 ? 0 : (side > 0 ? Self.labelWidth / 2 - 6 : -Self.labelWidth / 2 + 6)
        return ArtArabic(Self.names[month - 1], size: 10,
                         color: Self.sacred.contains(month) ? accent : .secondary)
            .frame(width: Self.labelWidth, alignment: alignment)
            .offset(x: point.width + shift, y: point.height)
    }
}

// MARK: - Islamic Wallpapers

/// Islamic Wallpapers: the screens the wallpapers are made for, at their shapes: a fan of phones, one
/// for each phone wallpaper (1893 by 4096), a laptop and a wide desktop (3840 by 1620), each screen
/// filled with the eight-pointed star, two squares turned on each other, the figure at the heart of
/// Islamic geometric art.
struct WallpaperFormatsArt: View {
    @Environment(\.appearance) private var appearance

    /// How many of the wallpapers are for a phone.
    let phones: Int

    var body: some View {
        let accent = appearance.accent
        let count = min(max(phones, 1), 4)
        let middle = Double(count - 1) / 2
        return HStack(alignment: .bottom, spacing: 12) {
            ZStack {
                ForEach(0..<count, id: \.self) { index in
                    phone(accent)
                        .rotationEffect(.degrees((Double(index) - middle) * 11), anchor: .bottom)
                        .offset(x: CGFloat(Double(index) - middle) * 19)
                }
            }
            .frame(width: 32 + CGFloat(count - 1) * 19 + 12, height: 74, alignment: .bottom)
            laptop(accent)
            desktop(accent)
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity)
        .artFrame(Text("Phones, a laptop and a desktop, each screen filled with an eight-pointed star pattern: the screens the wallpapers are made for."))
    }

    private func screen(_ accent: Color, corner: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(LinearGradient(colors: [accent.opacity(0.22), accent.opacity(0.06)],
                                     startPoint: .top, endPoint: .bottom))
            StarLattice(cell: 12)
                .stroke(accent.opacity(0.5), lineWidth: 0.7)
                .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        }
    }

    private func phone(_ accent: Color) -> some View {
        screen(accent, corner: 6)
            .padding(2.5)
            // Solid under the glass, so the phones of the fan cover one another as phones do.
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color(.systemBackground)))
            .overlay(
                Capsule()
                    .fill(Color.primary.opacity(0.55))
                    .frame(width: 10, height: 3)
                    .padding(.top, 5),
                alignment: .top
            )
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(accent.opacity(0.7), lineWidth: 1.5))
            .frame(width: 32, height: 70)
    }

    private func laptop(_ accent: Color) -> some View {
        VStack(spacing: 0) {
            screen(accent, corner: 2)
                .padding(3)
                .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(accent.opacity(0.7), lineWidth: 1.5))
                .frame(width: 80, height: 54)
            LaptopBase()
                .fill(accent.opacity(0.55))
                .frame(width: 96, height: 5)
        }
    }

    private func desktop(_ accent: Color) -> some View {
        VStack(spacing: 0) {
            screen(accent, corner: 2)
                .padding(3)
                .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(accent.opacity(0.7), lineWidth: 1.5))
                .frame(width: 102, height: 46)
            Rectangle()
                .fill(accent.opacity(0.45))
                .frame(width: 7, height: 9)
            Capsule()
                .fill(accent.opacity(0.55))
                .frame(width: 34, height: 3)
        }
    }
}

/// The eight-pointed star (two squares, one turned through 45 degrees) on a square lattice.
private struct StarLattice: Shape {
    let cell: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let half = cell * 0.34
        let tip = half * 1.414
        var y = rect.minY + cell / 2
        while y < rect.maxY + cell {
            var x = rect.minX + cell / 2
            while x < rect.maxX + cell {
                path.addRect(CGRect(x: x - half, y: y - half, width: 2 * half, height: 2 * half))
                path.move(to: CGPoint(x: x, y: y - tip))
                path.addLine(to: CGPoint(x: x + tip, y: y))
                path.addLine(to: CGPoint(x: x, y: y + tip))
                path.addLine(to: CGPoint(x: x - tip, y: y))
                path.closeSubpath()
                x += cell
            }
            y += cell
        }
        return path
    }
}

/// The laptop's keyboard deck, seen edge on.
private struct LaptopBase: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 6, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - 6, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 1.5))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - 2, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + 2, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - 1.5), control: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Islamic Journal

/// Islamic Journal: an open notebook and a reed pen. One page carries "Nun. By the pen and what they
/// inscribe" (Quran 68:1, in the mushaf's own text), the other a ruled line inked for each entry the
/// reader has written (up to six), with a dot in its margin for each note left on an ayah or a hadith.
struct JournalNotebookArt: View {
    @Environment(\.appearance) private var appearance

    let entries: Int
    let notes: Int

    private static let lines = 6
    private static let inkLengths: [CGFloat] = [0.94, 0.72, 0.86, 0.58, 0.8, 0.66]

    var body: some View {
        let accent = appearance.accent
        return HStack(spacing: 2) {
            page(accent) {
                VStack(spacing: 6) {
                    ArtArabic("نٓۚ وَٱلۡقَلَمِ وَمَا يَسۡطُرُونَ", size: 13, quran: true, color: accent)
                    Text(verbatim: "68:1".localizedDigits)
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                    ruled(count: 3, inked: 0, margin: 0, accent: accent)
                }
            }
            page(accent) {
                ruled(count: Self.lines, inked: min(max(entries, 0), Self.lines),
                      margin: min(max(notes, 0), Self.lines), accent: accent)
            }
        }
        .frame(height: 118)
        .overlay(
            LinearGradient(colors: [.clear, accent.opacity(0.3), .clear], startPoint: .leading, endPoint: .trailing)
                .frame(width: 12)
        )
        .overlay(
            ReedPen()
                .fill(LinearGradient(colors: [accent.opacity(0.95), accent.opacity(0.6)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 7, height: 84)
                .rotationEffect(.degrees(38))
                .offset(x: -26, y: 12),
            alignment: .bottomTrailing
        )
        .padding(.vertical, 2)
        .artFrame(Text("An open notebook and a reed pen: one page carries the ayah \"Nun. By the pen and what they inscribe\", the other a line inked for each entry you write."))
    }

    private func page<Content: View>(_ accent: Color, @ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(accent.opacity(0.07)))
            .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).strokeBorder(accent.opacity(0.28), lineWidth: 1))
    }

    private func ruled(count: Int, inked: Int, margin: Int, accent: Color) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<count, id: \.self) { line in
                HStack(spacing: 5) {
                    ZStack(alignment: .bottomLeading) {
                        Rectangle()
                            .fill(accent.opacity(0.25))
                            .frame(height: 0.75)
                        Capsule()
                            .fill(accent.opacity(0.75))
                            .frame(height: 2.2)
                            .scaleEffect(x: Self.inkLengths[line % Self.inkLengths.count], y: 1, anchor: .leading)
                            .offset(y: -3)
                            .opacity(line < inked ? 1 : 0)
                    }
                    Circle()
                        .fill(accent)
                        .frame(width: 4, height: 4)
                        .opacity(line < margin ? 1 : 0)
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
    }
}

/// A reed pen (qalam): a slim shaft and a nib cut on the slant.
private struct ReedPen: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let nib = rect.height * 0.2
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.width / 2))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + rect.width / 2), control: CGPoint(x: rect.midX, y: rect.minY - rect.width / 2))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - nib))
        path.addLine(to: CGPoint(x: rect.midX + rect.width * 0.1, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - nib * 0.55))
        path.closeSubpath()
        return path
    }
}

// MARK: - Miracles of the Quran

/// Miracles of the Quran: the ayah the library opens on, drawn. "We will show them Our signs in the
/// horizons and within themselves" (Quran 41:53): a horizon, its two phrases in the mushaf's text,
/// and the library's own fields placed where the ayah puts them (their symbols are the field list's):
/// the heavens, the rain, the earth's layers, water, plants and animals above it, and the embryo, the
/// heart and the body's cells below. English, like the page (`AppLanguage.article`).
struct MiraclesHorizonsArt: View {
    @Environment(\.appearance) private var appearance

    private static let heavens = ["cloud.rain", "star", "sparkles"]
    private static let earth = ["square.stack.3d.up", "drop", "leaf", "pawprint"]
    private static let selves = ["figure.and.child.holdinghands", "heart", "allergens"]

    var body: some View {
        let accent = appearance.accent
        return ZStack(alignment: .topLeading) {
            LinearGradient(colors: [accent.opacity(0.22), accent.opacity(0.05)], startPoint: .top, endPoint: .bottom)
            HorizonGround()
                .fill(accent.opacity(0.11))
            HorizonGround(lineOnly: true)
                .stroke(accent.opacity(0.55), lineWidth: 1.2)

            // In the horizons.
            VStack(alignment: .leading, spacing: 2) {
                ArtArabic("فِي ٱلۡأٓفَاقِ", size: 14, quran: true, color: accent)
                ArtCaption(article: "IN THE HORIZONS")
            }
            .padding(.leading, 12)
            .padding(.top, 10)

            HStack(spacing: 22) {
                ForEach(Self.heavens.indices, id: \.self) { index in
                    symbol(Self.heavens[index], accent: accent)
                        .offset(y: [26, 0, 14][index % 3])
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 22)
            .padding(.top, 12)

            HStack(spacing: 0) {
                ForEach(Self.earth.indices, id: \.self) { index in
                    symbol(Self.earth[index], accent: accent)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.leading, 120)
            .padding(.trailing, 8)
            .padding(.top, 64)

            // Within themselves.
            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    ArtArabic("وَفِيٓ أَنفُسِهِمۡ", size: 14, quran: true, color: accent)
                    ArtCaption(article: "WITHIN THEMSELVES")
                }
                Spacer(minLength: 12)
                HStack(spacing: 26) {
                    ForEach(Self.selves, id: \.self) { name in
                        symbol(name, accent: accent)
                    }
                }
                Spacer(minLength: 12)
            }
            .padding(.leading, 12)
            .padding(.trailing, 24)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 10)
        }
        .frame(height: 156)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(accent.opacity(0.25), lineWidth: 1))
        .artFrame(Text(verbatim: AppLanguage.article("Quran 41:53 as a horizon: above it, the signs in the horizons, the heavens, the rain, the earth's layers, water, plants and animals; below it, the signs within themselves, the embryo, the heart and the body's cells.")))
    }

    private func symbol(_ name: String, accent: Color) -> some View {
        Image(systemName: name)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(accent.opacity(0.85))
    }
}

/// The ground under a horizon that bows up a little in the middle, as the earth's edge does; with
/// `lineOnly`, the horizon alone.
private struct HorizonGround: Shape {
    var lineOnly = false

    func path(in rect: CGRect) -> Path {
        let edge = rect.minY + rect.height * 0.66
        let crown = rect.minY + rect.height * 0.56
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: edge))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: edge), control: CGPoint(x: rect.midX, y: 2 * crown - edge))
        if !lineOnly {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
        return path
    }
}

// MARK: - Miracles of the Prophets

/// Miracles of the Prophets: the house of prophethood, with its last brick. "My likeness among the
/// prophets before me is that of a man who built a house, made it fine and beautiful, except for the
/// place of one brick in a corner ... I am that brick, and I am the last of the prophets" (Sahih
/// al-Bukhari 3535). Each brick is a prophet with a sign the library tells (in its order): Nuh's ark,
/// Hud's wind, Ibrahim's fire made cool, Yusuf's dream of the sun, moon and stars, Musa's sea, Dawud's
/// armour, Sulayman's birds, Yunus's fish, Zakariya's son, 'Isa's healing of the blind. The corner
/// brick is the Prophet ﷺ, with the revelation: "Every prophet was given signs ... what I was given is
/// revelation" (Sahih al-Bukhari 4981). English, like the page (`AppLanguage.article`).
struct ProphetsLastBrickArt: View {
    @Environment(\.appearance) private var appearance

    private struct Brick {
        let arabic: String
        let symbol: String
    }

    private static let top = [
        Brick(arabic: "يُونُس", symbol: artSymbol("fish", or: "drop")),
        Brick(arabic: "زَكَرِيَّا", symbol: artSymbol("figure.and.child.holdinghands", or: "person.2")),
        Brick(arabic: "عِيسَى", symbol: "eye"),
    ]
    private static let middle = [
        Brick(arabic: "مُوسَى", symbol: artSymbol("water.waves", or: "drop")),
        Brick(arabic: "دَاوُود", symbol: "shield"),
        Brick(arabic: "سُلَيْمَان", symbol: artSymbol("bird", or: "leaf")),
    ]
    private static let bottom = [
        Brick(arabic: "نُوح", symbol: artSymbol("sailboat", or: "drop")),
        Brick(arabic: "هُود", symbol: "wind"),
        Brick(arabic: "إِبْرَاهِيم", symbol: "flame"),
        Brick(arabic: "يُوسُف", symbol: "moon.stars"),
    ]

    var body: some View {
        let accent = appearance.accent
        return VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                ArtCaption(article: "A SIGN FOR EVERY PROPHET")
                Spacer(minLength: 8)
                ArtArabic("فَأَنَا اللَّبِنَةُ", size: 12, color: accent)
            }

            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    ForEach(Self.top.indices, id: \.self) { brick(Self.top[$0], accent: accent) }
                    lastBrick(accent)
                }
                HStack(spacing: 4) {
                    plain(accent).frame(width: 34)
                    ForEach(Self.middle.indices, id: \.self) { brick(Self.middle[$0], accent: accent) }
                    plain(accent).frame(width: 34)
                }
                HStack(spacing: 4) {
                    ForEach(Self.bottom.indices, id: \.self) { brick(Self.bottom[$0], accent: accent) }
                }
            }

            Capsule()
                .fill(accent.opacity(0.3))
                .frame(height: 2)
        }
        // The house stands as the hadith builds it, in every interface.
        .environment(\.layoutDirection, .leftToRight)
        .artFrame(Text(verbatim: AppLanguage.article("A wall of bricks, each a prophet with one of his signs: Nuh's ark, Hud's wind, Ibrahim's fire, Yusuf's dream, Musa's sea, Dawud's armour, Sulayman's birds, Yunus's fish, Zakariya's son, 'Isa healing the blind. The last brick, at the corner, is Muhammad, peace and blessings be upon him, with the revelation he was given.")))
    }

    private func brick(_ brick: Brick, accent: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: brick.symbol)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(accent)
            ArtArabic(brick.arabic, size: 12)
        }
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity)
        .frame(height: 30)
        .background(plain(accent))
    }

    private func plain(_ accent: Color) -> some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(accent.opacity(0.1))
            .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous).strokeBorder(accent.opacity(0.28), lineWidth: 1))
            .frame(height: 30)
    }

    private func lastBrick(_ accent: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 10, weight: .semibold))
            ArtArabic("مُحَمَّد ﷺ", size: 12, color: .white, highlightAllah: false)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity)
        .frame(height: 30)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(LinearGradient(colors: [accent.opacity(0.95), accent.opacity(0.7)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
        )
    }
}

// MARK: - Prophecies of the Prophet

/// Prophecies of the Prophet: a line of time from the first revelation (610), each stop a prophecy
/// from the library, fulfilled while people who heard it lived, then our own day, then a dashed line
/// on to the signs still to come. The stops and their years:
/// - 624, Badr: "their assembly will be defeated" (Quran 54:45, revealed years before in Makkah);
/// - 630, Makkah: "He will return you to a place of return" (Quran 28:85; Sahih al-Bukhari 4773);
/// - 651, the last Chosroes dies, his line with him (Sahih al-Bukhari 3618);
/// - 657, 'Ammar killed at Siffin by "the transgressing party" (Sahih al-Bukhari 2812);
/// - 661, al-Hasan reconciles two great parties of Muslims (Sahih al-Bukhari 3629);
/// - today, the barefoot shepherds competing in tall buildings (Sahih Muslim 8), then what is awaited.
/// The symbols are the library's groups' own. English, like the page (`AppLanguage.article`).
struct PropheciesTimelineArt: View {
    @Environment(\.appearance) private var appearance

    private enum Kind { case origin, fulfilled, gap, now, awaited }

    private struct Stop {
        let label: String
        let symbol: String
        let kind: Kind
    }

    private static let stops: [Stop] = [
        Stop(label: "610", symbol: "book.closed", kind: .origin),
        Stop(label: "624", symbol: "book", kind: .fulfilled),
        Stop(label: "630", symbol: "book", kind: .fulfilled),
        Stop(label: "651", symbol: "crown", kind: .fulfilled),
        Stop(label: "657", symbol: "person.2", kind: .fulfilled),
        Stop(label: "661", symbol: "person.2", kind: .fulfilled),
        Stop(label: "", symbol: "", kind: .gap),
        Stop(label: "Today", symbol: "hourglass", kind: .now),
        Stop(label: "", symbol: "hourglass.bottomhalf.filled", kind: .awaited),
        Stop(label: "", symbol: "hourglass.bottomhalf.filled", kind: .awaited),
        Stop(label: "", symbol: "hourglass.bottomhalf.filled", kind: .awaited),
    ]

    private static var gapIndex: Int { stops.firstIndex { $0.kind == .gap } ?? 0 }
    private static var nowIndex: Int { stops.firstIndex { $0.kind == .now } ?? 0 }
    /// The rail runs through the nodes' centres: the symbol row, its spacing and half a node down.
    private static let railY: CGFloat = 18 + 5 + 11

    var body: some View {
        let accent = appearance.accent
        let count = CGFloat(Self.stops.count)
        return VStack(spacing: 8) {
            HStack {
                ArtCaption(article: "FULFILLED")
                Spacer(minLength: 8)
                ArtCaption(article: "AWAITED", color: .secondary)
            }

            ZStack(alignment: .topLeading) {
                Rail(count: count, from: 0, to: CGFloat(Self.gapIndex) - 0.3, y: Self.railY)
                    .stroke(accent.opacity(0.6), lineWidth: 2)
                Rail(count: count, from: CGFloat(Self.gapIndex) + 0.3, to: CGFloat(Self.nowIndex), y: Self.railY)
                    .stroke(accent.opacity(0.6), lineWidth: 2)
                Rail(count: count, from: CGFloat(Self.nowIndex), to: count - 1, y: Self.railY)
                    .stroke(accent.opacity(0.45), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [3, 4]))

                HStack(spacing: 0) {
                    ForEach(Self.stops.indices, id: \.self) { index in
                        column(Self.stops[index], accent: accent)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(height: 18 + 5 + 22 + 5 + 13)
        }
        .padding(12)
        .artPanel(accent)
        // Time runs left to right, as on the page.
        .environment(\.layoutDirection, .leftToRight)
        .artFrame(Text(verbatim: AppLanguage.article("A timeline from the first revelation in 610: prophecies fulfilled at Badr in 624, at the return to Makkah in 630, in the end of the Persian kings in 651, in 'Ammar's death in 657 and al-Hasan's peace in 661, signs seen in our own day, and a dashed line on to the signs still to come.")))
    }

    private func column(_ stop: Stop, accent: Color) -> some View {
        VStack(spacing: 5) {
            Group {
                if stop.symbol.isEmpty {
                    Color.clear
                } else {
                    Image(systemName: stop.symbol)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(stop.kind == .awaited ? .secondary : accent)
                }
            }
            .frame(height: 18)

            node(stop.kind, accent: accent)
                .frame(width: 22, height: 22)

            Text(verbatim: stop.kind == .now ? AppLanguage.article(stop.label) : stop.label)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(height: 13)
        }
    }

    @ViewBuilder
    private func node(_ kind: Kind, accent: Color) -> some View {
        switch kind {
        case .origin:
            Circle()
                .fill(accent.opacity(0.55))
                .frame(width: 10, height: 10)
        case .fulfilled, .now:
            ZStack {
                Circle().fill(accent)
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundColor(.white)
            }
            .overlay(
                Circle()
                    .strokeBorder(accent.opacity(kind == .now ? 0.4 : 0), lineWidth: 1.5)
                    .padding(-4)
            )
        case .gap:
            HStack(spacing: 3) {
                ForEach(0..<2, id: \.self) { _ in
                    Capsule()
                        .fill(accent.opacity(0.6))
                        .frame(width: 2, height: 13)
                        .rotationEffect(.degrees(25))
                }
            }
        case .awaited:
            Circle()
                .strokeBorder(accent.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: [2.5, 2.5]))
                .frame(width: 16, height: 16)
        }
    }
}

/// A stretch of the timeline's rail, between two columns' centres.
private struct Rail: Shape {
    let count: CGFloat
    let from: CGFloat
    let to: CGFloat
    let y: CGFloat

    func path(in rect: CGRect) -> Path {
        let slot = rect.width / count
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + slot * (from + 0.5), y: rect.minY + y))
        path.addLine(to: CGPoint(x: rect.minX + slot * (to + 0.5), y: rect.minY + y))
        return path
    }
}

// MARK: - Sunnahs of the Prophet

/// Sunnahs of the Prophet: his day as a dial, the day above the horizon and the night below, with
/// sunnahs from the library set at their hours: the night prayer and Witr in the last part of the
/// night, the siwak on rising, the two rak'ahs before Fajr, Duha, the evening remembrances, sleeping
/// soon after 'Isha, and lying down on the right side. Each rests on the narration its article quotes.
/// English, like the page (`AppLanguage.article`).
struct SunnahDayDialArt: View {
    @Environment(\.appearance) private var appearance

    private struct Mark {
        let symbol: String
        let english: String
        /// Degrees clockwise from noon at the top: dawn on the left, dusk on the right, midnight below.
        let angle: Double
    }

    private static let marks = [
        Mark(symbol: "moon.stars.fill", english: "Night prayer and Witr", angle: 212),
        Mark(symbol: "sunrise.fill", english: "Siwak on rising", angle: 240),
        Mark(symbol: "sparkle", english: "Two rak'ahs before Fajr", angle: 267),
        Mark(symbol: "sun.max.fill", english: "Duha", angle: 312),
        Mark(symbol: "sunset.fill", english: "Evening remembrances", angle: 70),
        Mark(symbol: "bed.double.fill", english: "Sleep soon after Isha", angle: 118),
        Mark(symbol: "moon.zzz.fill", english: "On the right side", angle: 148),
    ]

    var body: some View {
        let accent = appearance.accent
        return HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle().fill(accent.opacity(0.06))
                // The day: the disc's top half.
                Circle()
                    .fill(accent.opacity(0.17))
                    .mask(VStack(spacing: 0) { Rectangle(); Color.clear })
                Rectangle()
                    .fill(accent.opacity(0.4))
                    .frame(width: 132, height: 1)
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(accent)
                    .offset(y: -24)
                Image(systemName: "moon.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(accent.opacity(0.6))
                    .offset(y: 24)
                Circle().strokeBorder(accent.opacity(0.3), lineWidth: 1)

                ForEach(Self.marks.indices, id: \.self) { index in
                    ZStack {
                        Circle().fill(accent)
                        Image(systemName: Self.marks[index].symbol)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 19, height: 19)
                    .offset(artPoint(degrees: Self.marks[index].angle, radius: 55))
                }
            }
            .frame(width: 134, height: 134)

            VStack(alignment: .leading, spacing: 5) {
                ArtCaption(article: "HIS DAY, HOUR BY HOUR")
                ForEach(Self.marks.indices, id: \.self) { index in
                    HStack(spacing: 6) {
                        Image(systemName: Self.marks[index].symbol)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(accent)
                            .frame(width: 14)
                        Text(verbatim: AppLanguage.article(Self.marks[index].english))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        // The dial runs clockwise and the page reads left to right, in every interface.
        .environment(\.layoutDirection, .leftToRight)
        .artFrame(Text(verbatim: AppLanguage.article("His day as a dial, the day above the horizon and the night below: the night prayer and Witr, the siwak on rising, the two rak'ahs before Fajr, Duha, the evening remembrances, sleeping soon after Isha, and lying down on the right side.")))
    }
}

// MARK: - Proving Islam

/// Proving Islam: the case the library makes, drawn as its hero states it. A human author leaves
/// errors, a fraud leaves motives, a borrowed text leaves its sources, a fragile scripture leaves scars
/// (the chapters on science, the Prophet's character, his sources and preservation). Each is looked
/// for and struck through, and the four lines meet in the one explanation left: "a revelation from
/// the Lord of the worlds" (Quran 56:80, in the mushaf's text). The test is the Quran's own: "Had it
/// been from other than Allah, they would have found in it much contradiction" (4:82). English, like
/// the page (`AppLanguage.article`).
struct ProvingFingerprintsArt: View {
    @Environment(\.appearance) private var appearance

    private static let marks: [(english: String, symbol: String)] = [
        ("Errors", "exclamationmark.triangle"),
        ("Motives", "crown"),
        ("Sources", "books.vertical"),
        ("Scars", artSymbol("bandage", or: "cross.case")),
    ]

    var body: some View {
        let accent = appearance.accent
        return VStack(spacing: 0) {
            HStack {
                ArtCaption(article: "THE HUMAN FINGERPRINTS")
                Spacer(minLength: 8)
                ArtCaption(article: "NONE FOUND", color: .secondary)
            }
            .padding(.bottom, 10)

            HStack(spacing: 0) {
                ForEach(Self.marks.indices, id: \.self) { index in
                    VStack(spacing: 4) {
                        ZStack {
                            Circle().fill(accent.opacity(0.1))
                            Circle().strokeBorder(accent.opacity(0.3), lineWidth: 1)
                            Image(systemName: Self.marks[index].symbol)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(accent.opacity(0.75))
                            Capsule()
                                .fill(accent)
                                .frame(width: 1.8, height: 34)
                                .rotationEffect(.degrees(45))
                        }
                        .frame(width: 38, height: 38)

                        Text(verbatim: AppLanguage.article(Self.marks[index].english))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            Converge(count: Self.marks.count)
                .stroke(accent.opacity(0.4), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                .frame(height: 30)

            HStack(spacing: 8) {
                ArtArabic("تَنزِيلٞ مِّن رَّبِّ ٱلۡعَٰلَمِينَ", size: 13, quran: true, color: .white, highlightAllah: false)
                Text(verbatim: "56:80")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(LinearGradient(colors: [accent.opacity(0.95), accent.opacity(0.72)],
                                              startPoint: .leading, endPoint: .trailing))
            )
        }
        .environment(\.layoutDirection, .leftToRight)
        .artFrame(Text(verbatim: AppLanguage.article("Four fingerprints a human author would leave: errors, motives, sources and scars. None is found, and the four lines meet in the one explanation left: a revelation from the Lord of the worlds, Quran 56:80.")))
    }
}

/// Lines from evenly spaced points along the top edge, meeting at the bottom centre.
private struct Converge: Shape {
    let count: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let end = CGPoint(x: rect.midX, y: rect.maxY)
        for index in 0..<count {
            let x = rect.minX + rect.width * (CGFloat(index) + 0.5) / CGFloat(count)
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addQuadCurve(to: end, control: CGPoint(x: x, y: rect.maxY * 0.85))
        }
        return path
    }
}

// MARK: - Arabic Alphabet

/// Arabic Alphabet: the twenty-eight letters in their order, read from the right, split the way the
/// alphabet splits itself before the article al-: fourteen sun letters, which take the laam into
/// themselves (ash-shams), and fourteen moon letters, before which it is said (al-qamar). The moon
/// letters are the ones in the old mnemonic ابغ حجك وخف عقيمه.
struct ArabicSunMoonLettersArt: View {
    @Environment(\.appearance) private var appearance

    private static let letters = "ابتثجحخدذرزسشصضطظعغفقكلمنهوي".map(String.init)
    private static let sun = Set("تثدذرزسشصضطظلن".map(String.init))

    var body: some View {
        let accent = appearance.accent
        return VStack(spacing: 8) {
            VStack(spacing: 4) {
                ForEach(0..<4, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<7, id: \.self) { column in
                            cell(Self.letters[row * 7 + column], accent: accent)
                        }
                    }
                }
            }
            // The alphabet runs from the right in every interface.
            .environment(\.layoutDirection, .rightToLeft)

            HStack(spacing: 6) {
                legend(symbol: "sun.max.fill", tint: accent, label: Text("Sun letters"))
                Spacer(minLength: 8)
                legend(symbol: "moon.fill", tint: .secondary, label: Text("Moon letters"))
            }
        }
        .artFrame(Text("The twenty-eight letters in order: fourteen sun letters, which take the laam of al- into themselves, and fourteen moon letters, before which the laam is said."))
    }

    private func cell(_ letter: String, accent: Color) -> some View {
        let sun = Self.sun.contains(letter)
        return ArtArabic(letter, size: 21, color: sun ? accent : .primary, plain: true)
            .frame(maxWidth: .infinity)
            .frame(height: 29)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(sun ? accent.opacity(0.16) : Color.primary.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(accent.opacity(sun ? 0.35 : 0), lineWidth: 1)
            )
    }

    private func legend(symbol: String, tint: Color, label: Text) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(tint)
            Text(verbatim: "14".localizedDigits)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(tint)
            label
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

// MARK: - Tajweed Course

/// One stage of the Tajweed Course as its path draws it: its names, how many of its lessons are done,
/// and which of its chapters are finished.
struct TajweedPathStage: Identifiable {
    let id: String
    let title: String
    let arabic: String
    let lessons: Int
    let done: Int
    let chaptersDone: [Bool]

    /// The four stages before the course pack is parsed (the pack's own names and chapter counts), so
    /// the card has its height from the first frame.
    static var placeholder: [TajweedPathStage] {
        [
            TajweedPathStage(id: "read", title: "Read the letters".localizedDisplay, arabic: "القراءة",
                             lessons: 0, done: 0, chaptersDone: [false]),
            TajweedPathStage(id: "shape", title: "Shape the letters".localizedDisplay, arabic: "المخارج والصفات",
                             lessons: 0, done: 0, chaptersDone: [false, false, false]),
            TajweedPathStage(id: "rules", title: "Apply the rules".localizedDisplay, arabic: "الأحكام",
                             lessons: 0, done: 0, chaptersDone: [false, false, false, false]),
            TajweedPathStage(id: "mushaf", title: "Read the mushaf".localizedDisplay, arabic: "الوقف والابتداء",
                             lessons: 0, done: 0, chaptersDone: [false, false]),
        ]
    }
}

/// Tajweed Course: the course's four stages as a road climbing from the letters to the mushaf, in the
/// classical order it teaches them (read the letters, shape them, apply the rules, read the mushaf).
/// Each stage's ring fills as its lessons are done, and a dot under it lights for each finished chapter.
struct TajweedCoursePathArt: View {
    @Environment(\.appearance) private var appearance

    let stages: [TajweedPathStage]

    /// How far the second and fourth stages sit below the first and third.
    private static let dip: CGFloat = 24
    private static let medallion: CGFloat = 38

    var body: some View {
        let accent = appearance.accent
        return VStack(alignment: .leading, spacing: 8) {
            ArtCaption("THE COURSE, STAGE BY STAGE")

            ZStack(alignment: .top) {
                Winding(count: stages.count, top: Self.medallion / 2, dip: Self.dip, gap: Self.medallion / 2 + 3)
                    .stroke(accent.opacity(0.35), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 4]))
                    .flipsForRightToLeftLayoutDirection(true)

                HStack(alignment: .top, spacing: 0) {
                    ForEach(stages.indices, id: \.self) { index in
                        column(index, accent: accent)
                            .padding(.top, index % 2 == 0 ? 0 : Self.dip)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .artFrame(Text("The course's four stages as a road: read the letters, shape them, apply the rules, then read the mushaf. Each stage's ring fills as you finish its lessons."))
    }

    private func column(_ index: Int, accent: Color) -> some View {
        let stage = stages[index]
        let progress = stage.lessons > 0 ? Double(stage.done) / Double(stage.lessons) : 0
        let complete = stage.lessons > 0 && stage.done >= stage.lessons
        return VStack(spacing: 3) {
            ZStack {
                Circle()
                    .fill(complete
                          ? AnyShapeStyle(LinearGradient(colors: [accent.opacity(0.95), accent.opacity(0.7)],
                                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                          : AnyShapeStyle(accent.opacity(0.12)))
                Circle()
                    .strokeBorder(accent.opacity(0.3), lineWidth: 1)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(1.5)
                Text(verbatim: "\(index + 1)".localizedDigits)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(complete ? .white : accent)
            }
            .frame(width: Self.medallion, height: Self.medallion)

            ArtArabic(stage.arabic, size: 11, color: accent)
                .padding(.horizontal, 2)

            Text(verbatim: stage.title)
                .font(.system(size: 9.5, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .frame(height: 24, alignment: .top)
                .padding(.horizontal, 2)

            HStack(spacing: 3) {
                ForEach(stage.chaptersDone.indices, id: \.self) { chapter in
                    Circle()
                        .fill(stage.chaptersDone[chapter] ? accent : accent.opacity(0.22))
                        .frame(width: 5, height: 5)
                }
            }
        }
    }
}

/// The dashed road between the stages' medallions, which alternate high and low; it stops `gap` short
/// of each centre, at the medallion's edge, so it never shows through one.
private struct Winding: Shape {
    let count: Int
    let top: CGFloat
    let dip: CGFloat
    let gap: CGFloat

    func path(in rect: CGRect) -> Path {
        guard count > 1 else { return Path() }
        let slot = rect.width / CGFloat(count)
        let points = (0..<count).map { index in
            CGPoint(x: rect.minX + slot * (CGFloat(index) + 0.5), y: rect.minY + top + (index % 2 == 0 ? 0 : dip))
        }
        var path = Path()
        for index in 1..<points.count {
            let from = CGPoint(x: points[index - 1].x + gap, y: points[index - 1].y)
            let to = CGPoint(x: points[index].x - gap, y: points[index].y)
            let midX = (from.x + to.x) / 2
            path.move(to: from)
            path.addCurve(to: to, control1: CGPoint(x: midX, y: from.y), control2: CGPoint(x: midX, y: to.y))
        }
        return path
    }
}

// MARK: - Dhikr & Remembrances

/// Dhikr & Remembrances: "The dearest words to Allah are four: Subhan Allah, Alhamdulillah, La ilaha
/// illa Allah and Allahu Akbar. It does not matter which of them you begin with" (Sahih Muslim 2137).
/// The four sit round a ring with the number four at its heart, and the ring has no first.
struct DhikrFourWordsArt: View {
    @Environment(\.appearance) private var appearance

    private static let words = ["سُبْحَانَ اللَّهِ", "الْحَمْدُ لِلَّهِ", "لَا إِلَهَ إِلَّا اللَّهُ", "اللَّهُ أَكْبَرُ"]
    private static let rx: CGFloat = 92
    private static let ry: CGFloat = 44

    var body: some View {
        let accent = appearance.accent
        return VStack(alignment: .leading, spacing: 6) {
            ArtCaption("MOST BELOVED TO ALLAH")

            ZStack {
                Ellipse()
                    .stroke(accent.opacity(0.3), style: StrokeStyle(lineWidth: 1.2, dash: [3, 3]))
                    .frame(width: 2 * Self.rx, height: 2 * Self.ry)

                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [accent.opacity(0.95), accent.opacity(0.7)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                    Text(verbatim: "4".localizedDigits)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(width: 42, height: 42)

                ForEach(Self.words.indices, id: \.self) { index in
                    word(Self.words[index], accent: accent)
                        .offset(position(index))
                }
            }
            .frame(height: 2 * Self.ry + 34)
            .frame(maxWidth: .infinity)

            ArtCaption("IN ANY ORDER", color: .secondary)
                .frame(maxWidth: .infinity)
        }
        .artFrame(Text("The four words most beloved to Allah, round a ring with no first: Subhan Allah, Alhamdulillah, La ilaha illa Allah and Allahu Akbar. It does not matter which you begin with."))
    }

    private func position(_ index: Int) -> CGSize {
        switch index {
        case 0: return CGSize(width: 0, height: -Self.ry)
        case 1: return CGSize(width: Self.rx, height: 0)
        case 2: return CGSize(width: 0, height: Self.ry)
        default: return CGSize(width: -Self.rx, height: 0)
        }
    }

    private func word(_ arabic: String, accent: Color) -> some View {
        ArtArabic(arabic, size: 14)
            .padding(.horizontal, 10)
            .frame(width: 106, height: 30)
            .background(
                Capsule()
                    .fill(accent.opacity(0.14))
                    .overlay(Capsule().strokeBorder(accent.opacity(0.35), lineWidth: 1))
            )
    }
}

// MARK: - Stories of the Prophets

/// Stories of the Prophets: the twenty-five prophets the Quran names, as twenty-five marks along one
/// arc of time, from Adam to Muhammad ﷺ in the order they lived, the library's order. Eighteen are
/// named in one passage (Quran 6:83-86); Adam, Idris, Hud, Salih, Shu'ayb, Dhul-Kifl and Muhammad ﷺ
/// elsewhere. The five of firm resolve stand larger, with their names: "So be patient, as those of firm
/// resolve among the messengers were patient" (Quran 46:35), the five the covenant names, "from you,
/// and from Nuh, Ibrahim, Musa and 'Isa son of Maryam" (Quran 33:7). Adam and the last are named under
/// the line and the four between over it, and the line is dashed before the last, who came "after an
/// interval of the messengers" (Quran 5:19). English, like the library (`AppLanguage.article`).
struct ProphetStoriesArt: View {
    @Environment(\.appearance) private var appearance

    private static let names = [
        "Adam", "Idris", "Nuh", "Hud", "Salih", "Ibrahim", "Lut", "Isma'il", "Ishaq", "Ya'qub", "Yusuf",
        "Ayyub", "Shu'ayb", "Musa", "Harun", "Dhul-Kifl", "Dawud", "Sulayman", "Ilyas", "Alyasa'", "Yunus",
        "Zakariya", "Yahya", "Isa", "Muhammad",
    ]
    /// Nuh, Ibrahim, Musa, 'Isa and Muhammad ﷺ: the five of firm resolve (Quran 46:35, 33:7).
    private static let firm: Set<Int> = [2, 5, 13, 23, 24]
    /// A slot for each prophet and one more, empty, before the last: the interval (Quran 5:19).
    private static let slots = 26
    /// The arc, in points from the drawing's top: its two ends, and how far its middle rises above them.
    private static let ends: CGFloat = 57
    private static let rise: CGFloat = 32
    private static let labelHeight: CGFloat = 12
    private static let height: CGFloat = 82
    /// The caption row's own height, so a caption that shrinks to fit never changes the piece's.
    private static let captionHeight: CGFloat = 12

    private static var last: Int { names.count - 1 }

    /// The prophet in `slot`; nil for the interval before the last.
    private static func prophet(_ slot: Int) -> Int? {
        if slot < last { return slot }
        return slot == slots - 1 ? last : nil
    }

    private static func radius(_ index: Int) -> CGFloat {
        if index == last { return 7.5 }
        if firm.contains(index) { return 6.5 }
        return index == 0 ? 4.5 : 2.6
    }

    var body: some View {
        let accent = appearance.accent
        let slots = CGFloat(Self.slots)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                ArtCaption(article: "25 NAMED IN THE QURAN")
                Spacer(minLength: 8)
                Circle()
                    .fill(accent)
                    .frame(width: 7, height: 7)
                ArtCaption(article: "FIVE OF FIRM RESOLVE", color: .secondary)
            }
            .frame(height: Self.captionHeight)

            ZStack(alignment: .topLeading) {
                ProphetArc(slots: slots, from: 0, to: slots - 3, ends: Self.ends, rise: Self.rise)
                    .stroke(accent.opacity(0.3), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                ProphetArc(slots: slots, from: slots - 3, to: slots - 1, ends: Self.ends, rise: Self.rise)
                    .stroke(accent.opacity(0.35), style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [2, 3]))

                HStack(spacing: 0) {
                    ForEach(0..<Self.slots, id: \.self) { slot in
                        column(slot, accent: accent)
                    }
                }
            }
            .frame(height: Self.height)
        }
        // Time runs left to right, as in the library.
        .environment(\.layoutDirection, .leftToRight)
        .artFrame(Text(verbatim: AppLanguage.article("The twenty-five prophets named in the Quran along one arc of time, from Adam to Muhammad, peace and blessings be upon him. The five of firm resolve stand larger: Nuh, Ibrahim, Musa, 'Isa and Muhammad.")))
    }

    private func column(_ slot: Int, accent: Color) -> some View {
        let index = Self.prophet(slot)
        let y = ProphetArc.y((CGFloat(slot) + 0.5) / CGFloat(Self.slots), ends: Self.ends, rise: Self.rise)
        let alignment: Alignment = index == 0 ? .topLeading : (index == Self.last ? .topTrailing : .top)
        // The column only places its mark and name; the name may run wider than the column.
        return Color.clear
            .frame(maxWidth: .infinity)
            .overlay(Group { if let index { mark(index, y: y, accent: accent) } }, alignment: .top)
            .overlay(Group { if let index { label(index, y: y) } }, alignment: alignment)
    }

    @ViewBuilder
    private func mark(_ index: Int, y: CGFloat, accent: Color) -> some View {
        let radius = Self.radius(index)
        if index == Self.last {
            Circle()
                .fill(LinearGradient(colors: [accent.opacity(0.95), accent.opacity(0.7)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 2 * radius, height: 2 * radius)
                .overlay(Circle().strokeBorder(accent.opacity(0.4), lineWidth: 1.5).padding(-3))
                .offset(y: y - radius)
        } else {
            Circle()
                .fill(Self.firm.contains(index) ? accent : accent.opacity(index == 0 ? 0.7 : 0.45))
                .frame(width: 2 * radius, height: 2 * radius)
                .offset(y: y - radius)
        }
    }

    /// Adam and the five of firm resolve: the first and the last under the line, the rest over it.
    @ViewBuilder
    private func label(_ index: Int, y: CGFloat) -> some View {
        if index == 0 || Self.firm.contains(index) {
            let radius = Self.radius(index)
            let under = index == 0 || index == Self.last
            Text(verbatim: AppLanguage.article(Self.names[index]))
                .font(.system(size: 10, weight: index == 0 ? .semibold : .bold))
                .foregroundColor(index == 0 ? .secondary : .primary)
                .lineLimit(1)
                .fixedSize()
                .frame(height: Self.labelHeight)
                .offset(y: under
                        ? y + radius + (index == Self.last ? 6 : 3)
                        : y - radius - 3 - Self.labelHeight)
        }
    }
}

/// A stretch of the prophets' arc between two slots' centres. It bows up `rise` points in the middle
/// from `ends` at either side (points from the top): the curve the marks sit on (`y`).
private struct ProphetArc: Shape {
    let slots: CGFloat
    let from: CGFloat
    let to: CGFloat
    let ends: CGFloat
    let rise: CGFloat

    /// The arc's height `t` of the way across (0 to 1), in points from the top.
    static func y(_ t: CGFloat, ends: CGFloat, rise: CGFloat) -> CGFloat {
        ends - rise * 4 * t * (1 - t)
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let steps = max(1, Int((to - from) * 4))
        for step in 0...steps {
            let t = (from + (to - from) * CGFloat(step) / CGFloat(steps) + 0.5) / slots
            let point = CGPoint(x: rect.minX + rect.width * t, y: rect.minY + Self.y(t, ends: ends, rise: rise))
            if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        return path
    }
}

// MARK: - Sahabah, Ahlul Bayt & Salaf

/// Sahabah, Ahlul Bayt & Salaf: "The best of people is my generation, then those who follow them, then
/// those who follow them" (Sahih al-Bukhari 2652). The three generations as three tiers, each joined to
/// the one before it and a step shorter, the first the fullest: the Sahabah, the Tabi'un and the Atba'
/// at-Tabi'in, together the Salaf. Each tier carries the hadith's own words for it. English, like the
/// library (`AppLanguage.article`).
struct BestGenerationsArt: View {
    @Environment(\.appearance) private var appearance

    private static let tiers: [(name: String, words: String)] = [
        ("Sahabah", "My generation"),
        ("Tabi‘un", "Then those who follow them"),
        ("Atba‘ at-Tabi‘in", "Then those who follow them"),
    ]
    /// The first fullest: each tier's wash and figures, and how far it stops short of the one above.
    private static let wash: [Double] = [0.16, 0.1, 0.06]
    private static let ink: [Double] = [1, 0.6, 0.4]
    private static let step: CGFloat = 20
    private static let row: CGFloat = 34
    private static let spacing: CGFloat = 5
    private static let medallion: CGFloat = 22
    private static let inset: CGFloat = 8

    var body: some View {
        let accent = appearance.accent
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                ArtCaption(article: "THE THREE BEST GENERATIONS")
                Spacer(minLength: 8)
                ArtCaption(article: "AL-BUKHARI 2652", color: .secondary)
            }
            .frame(height: 12)

            VStack(alignment: .leading, spacing: Self.spacing) {
                ForEach(Self.tiers.indices, id: \.self) { index in
                    tier(index, accent: accent)
                        .padding(.trailing, CGFloat(index) * Self.step)
                }
            }
        }
        // The tiers step in from the right in every interface, as the drawing has it.
        .environment(\.layoutDirection, .leftToRight)
        .artFrame(Text(verbatim: AppLanguage.article("The three best generations as three tiers, the first the fullest: the Sahabah, the Prophet's generation, then the Tabi'un who followed them, then the Atba' at-Tabi'in who followed them.")))
    }

    private func tier(_ index: Int, accent: Color) -> some View {
        HStack(spacing: 8) {
            medallion(index, accent: accent)

            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: AppLanguage.article(Self.tiers[index].name))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.primary)
                Text(verbatim: AppLanguage.article(Self.tiers[index].words))
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            Spacer(minLength: 6)

            Image(systemName: "person.3.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(accent.opacity(Self.ink[index]))
        }
        .padding(.horizontal, Self.inset)
        .frame(maxWidth: .infinity)
        .frame(height: Self.row)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(accent.opacity(Self.wash[index]))
                .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(accent.opacity(index == 0 ? 0.35 : 0.25), lineWidth: 1))
        )
        // "Then those who follow them": a link down to the next tier's medallion.
        .overlay(
            Rectangle()
                .fill(accent.opacity(0.4))
                .frame(width: 1.5, height: Self.row - Self.medallion + Self.spacing)
                .offset(x: Self.inset + Self.medallion / 2 - 0.75, y: (Self.row + Self.medallion) / 2)
                .opacity(index < Self.tiers.count - 1 ? 1 : 0),
            alignment: .topLeading
        )
    }

    private func medallion(_ index: Int, accent: Color) -> some View {
        let first = index == 0
        return ZStack {
            Circle()
                .fill(LinearGradient(colors: first ? [accent.opacity(0.95), accent.opacity(0.7)]
                                                   : [accent.opacity(0.16), accent.opacity(0.16)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle()
                .strokeBorder(accent.opacity(first ? 0 : 0.35), lineWidth: 1)
            Text(verbatim: "\(index + 1)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(first ? .white : accent)
        }
        .frame(width: Self.medallion, height: Self.medallion)
    }
}

// MARK: - Refuting Religions

/// Refuting Religions: "And this is My path, straight, so follow it, and do not follow the other ways,
/// for they will separate you from His way" (Quran 6:153), drawn as Ibn Mas'ud describes the Prophet ﷺ
/// drawing it: he drew a line and said, "This is the path of Allah," then drew lines to its right and
/// its left and said, "These are paths, on each of which is a devil calling to it," then recited the
/// ayah (Musnad Ahmad, an-Nasa'i, ad-Darimi; Mishkat al-Masabih 166, its chain graded hasan). One straight path in the accent, and short paths leaving it on both sides,
/// each bending away from it and ending at its caller. English, like the library (`AppLanguage.article`).
struct StraightPathArt: View {
    @Environment(\.appearance) private var appearance

    private static let height: CGFloat = 80

    var body: some View {
        let accent = appearance.accent
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                ArtCaption(article: "THIS IS MY STRAIGHT PATH")
                Spacer(minLength: 8)
                Text(verbatim: "6:153")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .frame(height: 12)

            ZStack {
                PathWays(part: .ways)
                    .stroke(accent.opacity(0.32), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                PathWays(part: .callers)
                    .stroke(accent.opacity(0.35), lineWidth: 1)

                // The straight path, over the places the others leave it.
                HStack(spacing: 0) {
                    Circle()
                        .fill(accent)
                        .frame(width: 9, height: 9)
                    Capsule()
                        .fill(LinearGradient(colors: [accent.opacity(0.75), accent], startPoint: .leading, endPoint: .trailing))
                        .frame(height: 3.5)
                    Image(systemName: "arrowtriangle.right.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(accent)
                        .padding(.leading, -2)
                }
            }
            .frame(height: Self.height)

            HStack(spacing: 6) {
                Capsule()
                    .fill(accent)
                    .frame(width: 16, height: 3)
                legend("The path of Allah")
                Spacer(minLength: 8)
                Circle()
                    .strokeBorder(accent.opacity(0.5), lineWidth: 1)
                    .frame(width: 7, height: 7)
                legend("Side paths, a devil on each")
            }
            .frame(height: 12)
        }
        // The path runs left to right, as drawn, in every interface.
        .environment(\.layoutDirection, .leftToRight)
        .artFrame(Text(verbatim: AppLanguage.article("One straight path, the path of Allah, with short paths leaving it on both sides and a devil calling on each, as the Prophet, peace and blessings be upon him, drew it for Quran 6:153.")))
    }

    private func legend(_ english: String) -> some View {
        Text(verbatim: AppLanguage.article(english))
            .font(.system(size: 9.5, weight: .semibold))
            .foregroundColor(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}

/// The paths leaving the straight one, over and under it in turn, each starting along it and bending
/// away ("they will separate you from His way", Quran 6:153); `callers` draws the ring at the end of
/// each, where its devil calls (Musnad Ahmad, an-Nasa'i, ad-Darimi; Mishkat al-Masabih 166, its chain graded hasan).
private struct PathWays: Shape {
    enum Part { case ways, callers }
    let part: Part

    /// Where each path leaves (a fraction of the width) and how far it climbs from the straight one:
    /// over it when positive, under it when negative.
    private static let ways: [(at: CGFloat, rise: CGFloat)] = [
        (0.10, 26), (0.165, -22), (0.23, 32), (0.295, -27), (0.36, 22), (0.425, -31),
        (0.49, 28), (0.555, -22), (0.62, 31), (0.685, -26), (0.75, 23), (0.815, -30),
    ]
    private static let caller: CGFloat = 2.5

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for way in Self.ways {
            let start = CGPoint(x: rect.minX + rect.width * way.at, y: rect.midY)
            let reach = abs(way.rise) * 0.95
            let end = CGPoint(x: start.x + reach, y: rect.midY - way.rise)
            switch part {
            case .ways:
                let control = CGPoint(x: start.x + reach * 0.6, y: rect.midY - way.rise * 0.12)
                // Stop at the caller's ring, not inside it.
                let dx = end.x - control.x
                let dy = end.y - control.y
                let length = max((dx * dx + dy * dy).squareRoot(), 1)
                path.move(to: start)
                path.addQuadCurve(to: CGPoint(x: end.x - dx / length * Self.caller, y: end.y - dy / length * Self.caller),
                                  control: control)
            case .callers:
                path.addEllipse(in: CGRect(x: end.x - Self.caller, y: end.y - Self.caller,
                                           width: 2 * Self.caller, height: 2 * Self.caller))
            }
        }
        return path
    }
}

// MARK: - Preservation of the Quran

/// Preservation of the Quran: "Indeed, it is We who sent down the Reminder, and indeed, We will be its
/// guardian" (Quran 15:9), and the two ways it was kept, side by side from the revelation (610) to
/// today. In the hearts, "clear ayat in the breasts of those given knowledge" (Quran 29:49): a line of
/// dots, a memoriser in every generation, never broken. On the page, with its milestones, every date
/// approximate: the whole gathered into one copy under Abu Bakr after al-Yamamah (632; Sahih al-Bukhari
/// 4986), the copies 'Uthman sent to the cities (~650; Sahih al-Bukhari 4987), the dots that tell the
/// letters apart (~690, under the Umayyads), and the vowel signs still written today, al-Khalil ibn
/// Ahmad's (~770). The same Quran stands at both ends. English, like the library (`AppLanguage.article`).
struct QuranTwoWaysArt: View {
    @Environment(\.appearance) private var appearance

    private enum Kind { case revealed, milestone, gap, today }

    private struct Stop {
        let name: String
        let year: String
        let kind: Kind
    }

    private static let stops = [
        Stop(name: "Revealed", year: "610", kind: .revealed),
        Stop(name: "Abu Bakr", year: "632", kind: .milestone),
        Stop(name: "Uthman", year: "~650", kind: .milestone),
        Stop(name: "Dots", year: "~690", kind: .milestone),
        Stop(name: "Vowels", year: "~770", kind: .milestone),
        Stop(name: "", year: "", kind: .gap),
        Stop(name: "Today", year: "", kind: .today),
    ]

    private static var gapIndex: CGFloat { CGFloat(stops.firstIndex { $0.kind == .gap } ?? 0) }
    /// The two lines, in points from the drawing's top; each one's caption sits just above it.
    private static let heartsY: CGFloat = 18
    private static let pageY: CGFloat = 48
    private static let pageCaptionY: CGFloat = 26
    private static let labelsY: CGFloat = 58
    private static let height: CGFloat = 82
    private static let node: CGFloat = 10
    private static let pill: CGFloat = 14

    var body: some View {
        let accent = appearance.accent
        let count = CGFloat(Self.stops.count)
        return ZStack(alignment: .topLeading) {
            // In the hearts: unbroken, through every generation.
            Rail(count: count, from: 0, to: count - 1, y: Self.heartsY)
                .stroke(accent.opacity(0.7), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [0.1, 4.5]))
            // On the page, its long last stretch cut short.
            Rail(count: count, from: 0, to: Self.gapIndex - 0.3, y: Self.pageY)
                .stroke(accent.opacity(0.6), lineWidth: 2)
            Rail(count: count, from: Self.gapIndex + 0.3, to: count - 1, y: Self.pageY)
                .stroke(accent.opacity(0.6), lineWidth: 2)

            HStack(spacing: 0) {
                ForEach(Self.stops.indices, id: \.self) { index in
                    column(index, accent: accent)
                }
            }
        }
        .frame(height: Self.height)
        // A little narrower at the sides than the other panels: "Abu Bakr" keeps its full size.
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .artPanel(accent)
        // Time runs left to right, as in the library.
        .environment(\.layoutDirection, .leftToRight)
        .artFrame(Text(verbatim: AppLanguage.article("The Quran kept two ways, side by side from its revelation in 610 to today: in the hearts, memorised in every generation, and on the page, gathered under Abu Bakr in 632, copied under Uthman around 650, given its dots around 690 and its vowel signs around 770.")))
    }

    private func column(_ index: Int, accent: Color) -> some View {
        let stop = Self.stops[index]
        // The column only places its marker and words; the line captions run on across the next ones.
        return Color.clear
            .frame(maxWidth: .infinity)
            .overlay(marker(stop.kind, accent: accent), alignment: .top)
            .overlay(
                VStack(spacing: 0) {
                    Text(verbatim: stop.name.isEmpty ? "" : AppLanguage.article(stop.name))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.primary)
                    Text(verbatim: stop.year)
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .offset(y: Self.labelsY),
                alignment: .top
            )
            .overlay(Group { if index == 1 { captions(accent) } }, alignment: .topLeading)
    }

    @ViewBuilder
    private func marker(_ kind: Kind, accent: Color) -> some View {
        switch kind {
        case .revealed, .today:
            // The same Quran at both ends, across both lines.
            Capsule()
                .fill(LinearGradient(colors: [accent.opacity(0.95), accent.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                .frame(width: Self.pill, height: Self.pageY - Self.heartsY + Self.pill)
                .offset(y: Self.heartsY - Self.pill / 2)
        case .milestone:
            Circle()
                .fill(accent)
                .frame(width: Self.node, height: Self.node)
                .offset(y: Self.pageY - Self.node / 2)
        case .gap:
            HStack(spacing: 3) {
                ForEach(0..<2, id: \.self) { _ in
                    Capsule()
                        .fill(accent.opacity(0.6))
                        .frame(width: 2, height: 13)
                        .rotationEffect(.degrees(25))
                }
            }
            .offset(y: Self.pageY - 6.5)
        }
    }

    private func captions(_ accent: Color) -> some View {
        ZStack(alignment: .topLeading) {
            caption("heart.fill", "IN THE HEARTS", accent: accent)
            caption("book.closed.fill", "ON THE PAGE", accent: accent)
                .offset(y: Self.pageCaptionY)
        }
        .padding(.leading, 2)
    }

    private func caption(_ symbol: String, _ english: String, accent: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(accent)
            ArtCaption(article: english)
        }
        .fixedSize()
    }
}

// MARK: - Science of Hadith

/// Science of Hadith: the five conditions of a sahih hadith in Ibn as-Salah's definition, the one the
/// library's chapter on them opens with: "the musnad hadith whose chain is connected by the transmission
/// of an upright, precise narrator from an upright, precise narrator to its end, and which is neither
/// shadh nor mu'allal" ('Ulum al-Hadith). Five ticked links of one chain, each with its term (ittisal
/// as-sanad, 'adalah, dabt, shudhudh, 'illah), and the five lines meeting in the grade they earn
/// together, and only together: sahih. English, like the library (`AppLanguage.article`).
struct SahihConditionsArt: View {
    @Environment(\.appearance) private var appearance

    private static let conditions: [(english: String, term: String)] = [
        ("Connected chain", "ittisal"),
        ("Upright narrators", "‘adalah"),
        ("Precise narrators", "dabt"),
        ("No irregularity", "shudhudh"),
        ("No hidden defect", "‘illah"),
    ]
    private static let row: CGFloat = 20
    private static let spacing: CGFloat = 4
    private static let tick: CGFloat = 14
    private static let tickInset: CGFloat = 3
    private static let badge: CGFloat = 46
    private static var listHeight: CGFloat {
        CGFloat(conditions.count) * row + CGFloat(conditions.count - 1) * spacing
    }

    var body: some View {
        let accent = appearance.accent
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                ArtCaption(article: "FIVE CONDITIONS")
                Spacer(minLength: 8)
                ArtCaption(article: "IBN AS-SALAH", color: .secondary)
            }
            .frame(height: 12)

            HStack(spacing: 0) {
                VStack(spacing: Self.spacing) {
                    ForEach(Self.conditions.indices, id: \.self) { index in
                        chip(index, accent: accent)
                    }
                }
                // One chain through the five ticks.
                .background(
                    Rectangle()
                        .fill(accent.opacity(0.4))
                        .frame(width: 1.5)
                        .padding(.vertical, Self.row / 2)
                        .padding(.leading, Self.tickInset + Self.tick / 2 - 0.75),
                    alignment: .leading
                )

                JoinRight(rows: Self.conditions.count, row: Self.row, spacing: Self.spacing, to: Self.listHeight / 2)
                    .stroke(accent.opacity(0.35), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                    .frame(width: 24)

                seal(accent)
                    .frame(width: 64)
            }
            .frame(height: Self.listHeight)
        }
        // The chain runs into the grade on the right, in every interface.
        .environment(\.layoutDirection, .leftToRight)
        .artFrame(Text(verbatim: AppLanguage.article("The five conditions of a sahih hadith, all met: a connected chain, upright narrators, precise narrators, no irregularity and no hidden defect. Together they make it sahih.")))
    }

    private func chip(_ index: Int, accent: Color) -> some View {
        HStack(spacing: 6) {
            ZStack {
                Circle().fill(accent)
                Image(systemName: "checkmark")
                    .font(.system(size: 7.5, weight: .heavy))
                    .foregroundColor(.white)
            }
            .frame(width: Self.tick, height: Self.tick)

            Text(verbatim: AppLanguage.article(Self.conditions[index].english))
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 4)

            Text(verbatim: Self.conditions[index].term)
                .font(.system(size: 9, weight: .semibold).italic())
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.leading, Self.tickInset)
        .padding(.trailing, 8)
        .frame(maxWidth: .infinity)
        .frame(height: Self.row)
        .background(
            Capsule()
                .fill(accent.opacity(0.1))
                .overlay(Capsule().strokeBorder(accent.opacity(0.28), lineWidth: 1))
        )
    }

    private func seal(_ accent: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [accent.opacity(0.95), accent.opacity(0.7)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(width: Self.badge, height: Self.badge)
            .overlay(Circle().strokeBorder(accent.opacity(0.35), lineWidth: 1.5).padding(-4))

            Text(verbatim: AppLanguage.article("SAHIH"))
                .font(.system(size: 11, weight: .heavy))
                .tracking(AppLanguage.letterSpacing(1.6))
                .foregroundColor(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        // The badge's centre on the middle link, where the five lines meet.
        .padding(.top, Self.listHeight / 2 - Self.badge / 2)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

/// Lines from the middle of each of `rows` stacked rows at the left edge, meeting `to` points down the
/// right edge: the five conditions joining in the grade.
private struct JoinRight: Shape {
    let rows: Int
    let row: CGFloat
    let spacing: CGFloat
    let to: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let end = CGPoint(x: rect.maxX, y: rect.minY + to)
        for index in 0..<rows {
            let y = rect.minY + CGFloat(index) * (row + spacing) + row / 2
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addQuadCurve(to: end, control: CGPoint(x: rect.minX + rect.width * 0.55, y: y))
        }
        return path
    }
}

// MARK: - The Domino Process

/// The Domino Process: the library's one argument (adapted from the Domino Process dawah workshops) as
/// seven dominoes, each toppled by the one before it, the seven steps its opening card names: something
/// exists (Reality), something exists necessarily (Necessary), it has will and knowledge (Creator), it is
/// one (One), it has spoken (Revelation), its word can be tested (Which?), and one revelation passes
/// every test (Islam). No step may be skipped, as the Pillars page's own Domino Effect puts it, and
/// nobody is asked to assume Islam at the start. A still of the fall, drawn, never animated: the first
/// leans furthest, the last still stands. English, like the library (`AppLanguage.article`).
struct DominoesArt: View {
    @Environment(\.appearance) private var appearance

    private static let steps = ["Reality", "Necessary", "Creator", "One", "Revelation", "Which?", "Islam"]
    /// Each domino's lean in degrees, pivoting on its front foot: the first furthest over, the last upright.
    /// Small enough that no domino reaches the next on the narrowest phone (columns of about 43 points).
    private static let tilts: [Double] = [45, 37, 29, 21, 14, 7, 0]
    private static let domino = CGSize(width: 22, height: 48)

    private static var last: Int { steps.count - 1 }

    var body: some View {
        let accent = appearance.accent
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                ArtCaption(article: "SEVEN DOMINOES")
                Spacer(minLength: 8)
                ArtCaption(article: "EACH LEADS TO THE NEXT", color: .secondary)
            }
            .frame(height: 12)

            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(Self.steps.indices, id: \.self) { index in
                        domino(index, accent: accent)
                            .rotationEffect(.degrees(Self.tilts[index]), anchor: .bottomTrailing)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: Self.domino.height + 2, alignment: .bottom)

                Capsule()
                    .fill(accent.opacity(0.3))
                    .frame(height: 2)

                HStack(spacing: 0) {
                    ForEach(Self.steps.indices, id: \.self) { index in
                        Text(verbatim: AppLanguage.article(Self.steps[index]))
                            .font(.system(size: 9, weight: index == Self.last ? .bold : .semibold))
                            .foregroundColor(index == Self.last ? accent : .secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 12)
                .padding(.top, 5)
            }
        }
        // No panel: the seven labels need the card's full width to keep one size.
        // They fall left to right, as the argument runs, in every interface.
        .environment(\.layoutDirection, .leftToRight)
        .artFrame(Text(verbatim: AppLanguage.article("Seven dominoes falling one into the next: reality, the necessary, a Creator, that He is One, revelation, which revelation, and Islam.")))
    }

    private func domino(_ index: Int, accent: Color) -> some View {
        let isLast = index == Self.last
        return VStack(spacing: 0) {
            Text(verbatim: "\(index + 1)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(isLast ? .white : accent)
                .frame(maxHeight: .infinity)
            Rectangle()
                .fill(isLast ? Color.white.opacity(0.5) : accent.opacity(0.35))
                .frame(height: 1)
                .padding(.horizontal, 4)
            Circle()
                .fill(isLast ? Color.white.opacity(0.85) : accent.opacity(0.5))
                .frame(width: 4, height: 4)
                .frame(maxHeight: .infinity)
        }
        .frame(width: Self.domino.width, height: Self.domino.height)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(LinearGradient(colors: isLast ? [accent.opacity(0.95), accent.opacity(0.7)]
                                                    : [accent.opacity(0.16), accent.opacity(0.08)],
                                     startPoint: .top, endPoint: .bottom))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .strokeBorder(accent.opacity(isLast ? 0 : 0.35), lineWidth: 1)
        )
    }
}
#endif
