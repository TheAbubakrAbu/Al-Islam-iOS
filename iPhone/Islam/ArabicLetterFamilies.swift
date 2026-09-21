import SwiftUI

// The screens built on `LetterTraits` (ArabicLetterTraits.swift): the Letter Families index, one
// family's page, the tajweed profile every letter page carries, and the sound-alike comparison.
// Compiled for the Watch too, like the rest of the alphabet.

// MARK: - Doors

/// Where a tap on one of these screens leads. Letter tiles sit many to a List row, and a row may hold
/// only ONE NavigationLink (every link in a row fires on any tap), so tiles are Buttons that write
/// one of these and the List owns a single destination: `arabicDoorDestination`.
enum ArabicDoor {
    case letter(LetterData)
    case family(LetterFamily)
    case axes(title: String, axes: [LetterAxis])
    case families
    case soundAlikes
    case quiz
}

extension LetterTraits {
    /// The alphabet's own record of a letter, by its glyph.
    static func letterData(for glyph: String) -> LetterData? {
        standardArabicLetters.first { $0.letter == glyph } ?? otherArabicLetters.first { $0.letter == glyph }
    }
}

private struct ArabicDoorDestination: ViewModifier {
    @Binding var door: ArabicDoor?
    /// The door last opened, kept so the page being popped still has content while it slides away
    /// (the binding is already nil by then).
    @State private var lastDoor: ArabicDoor?

    private var isPresented: Binding<Bool> {
        Binding(
            get: { door != nil },
            set: { if !$0 { door = nil } }
        )
    }

    func body(content: Content) -> some View {
        Group {
            if #available(iOS 16.0, watchOS 9.0, *) {
                content.navigationDestination(isPresented: isPresented) { destination }
            } else {
                content.background(
                    NavigationLink(isActive: isPresented) { destination } label: { EmptyView() }
                        .opacity(0)
                )
            }
        }
        .onChange(of: door != nil) { open in
            if open { lastDoor = door }
        }
    }

    @ViewBuilder
    private var destination: some View {
        switch door ?? lastDoor {
        case .letter(let letter): ArabicLetterView(letterData: letter)
        case .family(let family): LetterFamilyView(family: family)
        case .axes(let title, let axes): LetterFamiliesView(title: title, axes: axes)
        case .families: LetterFamiliesView()
        case .soundAlikes: SoundAlikeLettersView()
        case .quiz: quizDestination
        case nil: EmptyView()
        }
    }

    /// The quiz is a phone screen: it wants a two-by-two answer grid the watch has no room for.
    @ViewBuilder
    private var quizDestination: some View {
        #if os(iOS)
        LetterQuizView()
        #else
        EmptyView()
        #endif
    }
}

extension View {
    /// The ONE destination a screen's letter tiles and chips share. Attach it to the List: a lazy
    /// row's own destination never fires.
    func arabicDoorDestination(_ door: Binding<ArabicDoor?>) -> some View {
        modifier(ArabicDoorDestination(door: door))
    }
}

// MARK: - Shared pieces

/// An Arabic term or letter in the Islam tab's Arabic face.
private struct TraitArabicText: View {
    @Environment(\.appearance) private var appearance

    let text: String
    let base: CGFloat
    let style: Font.TextStyle

    var body: some View {
        Text(text)
            .font(appearance.useFontArabic ? appearance.islamArabicFont(base: base, relativeTo: style) : .system(style))
            .arabicFontDesign(custom: appearance.useFontArabic && appearance.islamUsesCustomArabicFace)
    }
}

/// One letter as a small tile: the glyph over its name. The family pages, the Tajweed topic pages
/// and the comparison page all draw their letters with it.
struct LetterGlyphTile: View {
    @Environment(\.appearance) private var appearance

    let letter: LetterData
    /// This page's own letter, or the one being spoken: drawn filled.
    var isLit: Bool = false
    /// Already open further up the stack: drawn dimmed, and its button does nothing.
    var isDimmed: Bool = false
    var tint: Color? = nil

    var body: some View {
        let color = tint ?? appearance.accent
        VStack(spacing: 1) {
            TraitArabicText(text: letter.letter, base: 26, style: .title2)
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.4)

            Text(letter.transliteration)
                .font(.caption2.weight(.semibold))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, appearance.useFontArabic ? 4 : 8)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(isLit ? 0.24 : 0.09))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isLit ? color : .clear, lineWidth: 1.5)
        )
        .opacity(isDimmed ? 0.4 : 1)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(letter.transliteration)
    }
}

/// A family's letters as tappable tiles, all in one List row. Each opens that letter's page through
/// the parent's door, except a letter whose page is already open above this one.
struct LetterTileStrip: View {
    @Environment(\.openScreenInstances) private var openInstances
    @ObservedObject private var speech = ArabicSpeech.shared

    let letters: [String]
    /// The letter whose page this strip sits on, if it sits on one.
    var current: String? = nil
    var tint: Color? = nil
    let onOpen: (LetterData) -> Void

    #if os(watchOS)
    private static let tileMinimum: CGFloat = 44
    #else
    private static let tileMinimum: CGFloat = 60
    #endif

    private func isOpen(_ glyph: String) -> Bool {
        openInstances.contains(OpenScreenInstance(screen: .arabicLetter, id: glyph))
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: Self.tileMinimum), spacing: 8)], spacing: 8) {
            ForEach(letters, id: \.self) { glyph in
                if let letter = LetterTraits.letterData(for: glyph) {
                    let open = isOpen(glyph)
                    Button {
                        guard !open else { return }
                        Settings.shared.hapticFeedback()
                        onOpen(letter)
                    } label: {
                        LetterGlyphTile(
                            letter: letter,
                            isLit: glyph == current || speech.currentText == letter.name,
                            isDimmed: open && glyph != current,
                            tint: tint
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(open ? "You are already on this letter's page" : "Opens the letter")
                }
            }
        }
        .padding(.vertical, 4)
    }
}

/// The header of a letters section: the title, the count, and a Listen pill that says every letter's
/// name in turn (nothing, where the device has no Arabic voice).
private struct LettersHeader: View {
    @Environment(\.appearance) private var appearance
    @ObservedObject private var speech = ArabicSpeech.shared

    let title: String
    let letters: [String]

    private var names: [String] { letters.compactMap { LetterTraits.letterData(for: $0)?.name } }

    var body: some View {
        HStack(spacing: 8) {
            Text(title)

            Spacer()

            CountPill(count: letters.count)

            if speech.isAvailable, !names.isEmpty {
                Image(systemName: speech.isSpeakingQueue ? "stop.fill" : "speaker.wave.2.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(appearance.accent)
                    .frame(width: SectionPillHeader.pillHeight, height: SectionPillHeader.pillHeight)
                    .conditionalGlassEffect(circle: true)
                    .onTapGesture {
                        Settings.shared.hapticFeedback()
                        if speech.isSpeakingQueue { speech.stop() } else { speech.speakAll(names) }
                    }
                    .accessibilityLabel(speech.isSpeakingQueue ? "Stop" : "Hear every letter's name")
                    .accessibilityAddTraits(.isButton)
            }
        }
    }
}

/// One line of a letter's profile or of the families index: an icon tile, the family in English and
/// in Arabic, and what it means underneath.
struct LetterTraitRow: View {
    @Environment(\.appearance) private var appearance

    let systemImage: String
    var tint: Color? = nil
    /// A small line over the title saying which question the row answers ("After noon sakinah").
    var lead: String? = nil
    let title: String
    let arabic: String
    let caption: String
    /// A line of Arabic under the caption: the family's letters on the index, the surah openings on
    /// a letter's page.
    var letters: [String] = []

    private var titleText: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.primary)
    }

    private var arabicText: some View {
        TraitArabicText(text: arabic, base: 18, style: .body)
            .foregroundColor(tint ?? appearance.accent)
    }

    /// The Arabic term sits opposite the English one when the two fit on a line, and under it when
    /// they do not. It is never shrunk or cut to make room: a long rule name used to squeeze it down
    /// to an unreadable stub with an ellipsis.
    @ViewBuilder
    private var heading: some View {
        if #available(iOS 16.0, watchOS 9.0, *) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    titleText
                    Spacer(minLength: 8)
                    arabicText
                }

                VStack(alignment: .leading, spacing: 1) {
                    titleText.fixedSize(horizontal: false, vertical: true)
                    arabicText
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 1) {
                titleText.fixedSize(horizontal: false, vertical: true)
                arabicText
            }
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AccentIconChip(systemImage: systemImage, tint: tint, size: 30)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                if let lead {
                    Text(lead.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.secondary)
                }

                heading

                Text(caption)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if !letters.isEmpty {
                    TraitArabicText(text: letters.joined(separator: "\u{2002}"), base: 18, style: .body)
                        .foregroundColor((tint ?? appearance.accent).opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.35)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .environment(\.layoutDirection, .rightToLeft)
                }
            }
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
    }
}

/// A row that opens one of the alphabet's tajweed pages, or sits greyed out when that very page is
/// already open further up the stack. A letter links to its families and topics, and each of those
/// links back to letters: without this the pair is a corridor you can walk forever. The Watch
/// compiles these screens too, so this is `OpenScreenLink` without its iOS-only parts.
struct GuardedScreenLink<Destination: View, Label: View>: View {
    @Environment(\.openScreenInstances) private var openInstances

    let screen: OpenScreen
    let id: String
    var alreadyHere: String? = nil
    @ViewBuilder let destination: () -> Destination
    @ViewBuilder let label: () -> Label

    private var isOpen: Bool { openInstances.contains(OpenScreenInstance(screen: screen, id: id)) }

    var body: some View {
        if isOpen {
            VStack(alignment: .leading, spacing: 2) {
                label()

                Text(alreadyHere ?? screen.alreadyHereCaption)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .opacity(0.55)
            .accessibilityElement(children: .combine)
        } else {
            NavigationLink(destination: LazyDestination(build: destination)) {
                label()
            }
        }
    }
}

/// A row that opens a family's page.
struct LetterFamilyLink<Label: View>: View {
    let family: LetterFamily
    @ViewBuilder let label: () -> Label

    var body: some View {
        GuardedScreenLink(screen: .letterFamily, id: family.id) {
            LetterFamilyView(family: family)
        } label: {
            label()
        }
    }
}

extension LetterFamily {
    /// The reader's colour for this rule, where the mushaf paints one. The solar laam is the
    /// exception: the reader paints it GREY, as a letter that is not read, and a grey icon tile or a
    /// grey row of tiles reads as switched off. Its family page still shows the grey swatch.
    var legendColor: Color? { legend == .lamShamsiyah ? nil : legend?.color }
}

// MARK: - The index

/// Every family of letters, shelf by shelf: where letters are made, how they sound, and what they do
/// to their neighbours. Given `axes`, it shows only those (the Tajweed Foundations topics and the
/// alphabet's "about this grouping" link open it that way).
struct LetterFamiliesView: View {
    @Environment(\.appearance) private var appearance

    var title: String = "Letter Families"
    var axes: [LetterAxis]? = nil

    private var shownShelves: [LetterAxis.Shelf] {
        guard let axes else { return LetterAxis.Shelf.allCases }
        return LetterAxis.Shelf.allCases.filter { shelf in axes.contains { $0.shelf == shelf } }
    }

    private func shownAxes(on shelf: LetterAxis.Shelf) -> [LetterAxis] {
        shelf.axes.filter { axes?.contains($0) ?? true }
    }

    var body: some View {
        List {
            Group {
                if axes == nil { introSection }

                ForEach(shownShelves) { shelf in
                    if axes == nil || shownShelves.count > 1 {
                        shelfHeading(shelf)
                    }

                    ForEach(shownAxes(on: shelf)) { axis in
                        axisSection(axis)
                    }
                }

                if axes == nil || axes?.contains(.makhraj) == true {
                    makharijSection
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle(title)
        .openScreen(.letterFamilies)
        .onDisappear { ArabicSpeech.shared.stop() }
    }

    private var introSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Every letter has a place it is made (its makhraj) and qualities it is said with (its sifaat). Letters that share one are a family, and the tajweed books give every family an Arabic name.")
                    .font(.body)

                Text("Open a family to see its letters, how to hear what they share, and the phrase that gathers them.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 2)
        }
    }

    /// A shelf's name in both languages, as a row of its own above the shelf's sections.
    private func shelfHeading(_ shelf: LetterAxis.Shelf) -> some View {
        Section {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(shelf.title)
                        .font(.headline)
                        .foregroundColor(appearance.accent)

                    Text(shelf.transliteration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer(minLength: 8)

                TraitArabicText(text: shelf.arabic, base: 24, style: .title2)
                    .foregroundColor(appearance.accent)
            }
            .padding(.vertical, 2)
            .accessibilityElement(children: .combine)
        }
    }

    private func axisSection(_ axis: LetterAxis) -> some View {
        Section {
            ForEach(axis.families) { family in
                LetterFamilyLink(family: family) {
                    LetterTraitRow(
                        systemImage: family.systemImage,
                        tint: family.legendColor,
                        title: family.title,
                        arabic: family.arabic,
                        caption: family.summary,
                        letters: family.letters
                    )
                }
            }
        } header: {
            HStack(alignment: .firstTextBaseline) {
                Text(axis.title.uppercased())

                Spacer(minLength: 8)

                Text(axis.arabic)
                    .textCase(nil)
            }
        } footer: {
            Text(axis.question)
        }
    }

    /// The seventeen exits in full, deepest first: the zones above are how they are taught, this is
    /// how the books count them.
    private var makharijSection: some View {
        Section {
            ForEach(LetterTraits.makharij) { makhraj in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(makhraj.id)")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundColor(appearance.accent)
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(appearance.accent.opacity(0.12)))

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(makhraj.name)
                                .font(.subheadline.weight(.semibold))

                            Spacer(minLength: 4)

                            TraitArabicText(text: makhraj.arabic, base: 16, style: .subheadline)
                                .foregroundColor(appearance.accent)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }

                        Text(makhraj.place + ".")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        if !makhraj.letters.isEmpty {
                            TraitArabicText(text: makhraj.letters.joined(separator: "\u{2002}"), base: 18, style: .body)
                                .foregroundColor(appearance.accent.opacity(0.9))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .environment(\.layoutDirection, .rightToLeft)
                        }
                    }
                }
                .padding(.vertical, 2)
                .accessibilityElement(children: .combine)
            }
        } header: {
            HStack(alignment: .firstTextBaseline) {
                Text("THE SEVENTEEN EXITS")

                Spacer(minLength: 8)

                Text("المَخَارِج السَّبعَة عَشَر")
                    .textCase(nil)
            }
        } footer: {
            Text("Deepest first, as Ibn al-Jazari counts them. Neighbouring exits are the letters most easily confused, because they are made a few millimetres apart.")
        }
    }
}

// MARK: - One family

struct LetterFamilyView: View {
    @Environment(\.appearance) private var appearance
    @State private var door: ArabicDoor?

    let family: LetterFamily

    private var axis: LetterAxis? { LetterTraits.axis(of: family) }
    private var siblings: [LetterFamily] { (axis?.families ?? []).filter { $0 != family } }

    var body: some View {
        List {
            Group {
                heroSection
                lettersSection
                detailSection
                siblingsSection
                legendSection
                lessonSection
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .arabicDoorDestination($door)
        .navigationTitle(family.name)
        .openScreen(.letterFamily, id: family.id)
        .onDisappear { ArabicSpeech.shared.stop() }
    }

    private var heroSection: some View {
        Section {
            VStack(spacing: 6) {
                TraitArabicText(text: family.arabic, base: 40, style: .largeTitle)
                    .foregroundColor(family.legendColor ?? appearance.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)

                Text(family.title)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Text(family.summary)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .accessibilityElement(children: .combine)
        } footer: {
            if let axis { Text(axis.question) }
        }
    }

    private var lettersSection: some View {
        Section {
            LetterTileStrip(letters: family.letters, tint: family.legendColor) { door = .letter($0) }

            if let mnemonic = family.mnemonic {
                VStack(spacing: 6) {
                    TraitArabicText(text: mnemonic, base: 24, style: .title3)
                        .foregroundColor(family.legendColor ?? appearance.accent)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    if let note = family.mnemonicNote {
                        Text(note)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
            }
        } header: {
            LettersHeader(title: "THE LETTERS", letters: family.letters)
        } footer: {
            Text("Tap a letter to open its page.")
        }
    }

    @ViewBuilder
    private var detailSection: some View {
        if !family.detail.isEmpty {
            Section(header: Text("HOW TO HEAR IT")) {
                ForEach(family.detail, id: \.self) { paragraph in
                    Text(paragraph)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    @ViewBuilder
    private var siblingsSection: some View {
        if let axis, !siblings.isEmpty {
            Section {
                ForEach(siblings) { sibling in
                    LetterFamilyLink(family: sibling) {
                        LetterTraitRow(
                            systemImage: sibling.systemImage,
                            tint: sibling.legendColor,
                            title: sibling.title,
                            arabic: sibling.arabic,
                            caption: sibling.summary,
                            letters: sibling.letters
                        )
                    }
                }
            } header: {
                HStack(alignment: .firstTextBaseline) {
                    Text(axis.title.uppercased())

                    Spacer(minLength: 8)

                    Text(axis.arabic)
                        .textCase(nil)
                }
            } footer: {
                Text("The other answers to the same question.")
            }
        }
    }

    /// The reader's own paint for this rule, so the letter page, this page and the mushaf agree.
    @ViewBuilder
    private var legendSection: some View {
        if let legend = family.legend {
            Section(header: Text("IN THE QURAN READER")) {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(legend.color)
                        .frame(width: 26, height: 26)

                    Text("With tajweed colors on, the reader paints this rule in this color (\(legend.englishTitle)).")
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 2)
                .accessibilityElement(children: .combine)
            }
        }
    }

    @ViewBuilder
    private var lessonSection: some View {
        #if os(iOS)
        if let lessonID = family.lessonID, TajweedLessonsStore.isBundled {
            Section(header: Text("IN THE TAJWEED COURSE")) {
                NavigationLink(destination: LazyDestination { LetterFamilyLessonView(lessonID: lessonID) }) {
                    Label("Study the Full Lesson", systemImage: "graduationcap")
                        .font(.body)
                        .foregroundColor(appearance.accent)
                }
            }
        }
        #endif
    }
}

#if os(iOS)
/// The course lesson behind a family. The pack is parsed off the main thread (it is 467 KB), so the
/// page shows a spinner for the moment that takes on a cold open.
private struct LetterFamilyLessonView: View {
    let lessonID: String
    @State private var lesson: TajweedLesson?
    @State private var missing = false

    var body: some View {
        Group {
            if let lesson {
                TajweedLessonDetailView(lesson: lesson)
            } else if missing {
                Text("This lesson could not be loaded.")
                    .foregroundColor(.secondary)
            } else {
                ProgressView()
            }
        }
        .task {
            guard lesson == nil else { return }
            let id = lessonID
            let found = await Task.detached(priority: .userInitiated) {
                TajweedLessonsStore.shared.lesson(id: id)
            }.value
            lesson = found
            missing = found == nil
        }
    }
}
#endif

// MARK: - A letter's tajweed profile

/// The tajweed sections of a letter's page: where it is made, the qualities it is said with, and the
/// rules it triggers in the letters around it, each with a Quran example (Abu, 2026-09-20: "yaa is an
/// idgham bighunnah letter show that there").
struct LetterTajweedProfile: View {
    @Environment(\.appearance) private var appearance

    /// The letter the tables are read by (the hamza, for every seat a hamza sits on).
    let letter: String
    let letterData: LetterData

    private var makharij: [LetterMakhraj] { LetterTraits.makharij(of: letter) }
    private var sifaat: [LetterFamily] { LetterTraits.sifaat(of: letter) }

    var body: some View {
        Group {
            profileSection
            rulesSection
            soundAlikeSection
        }
    }

    // MARK: Where and how

    private func groupLine(_ makhraj: LetterMakhraj) -> String {
        var line = makhraj.place
        if let role = makhraj.roleNote, makharij.count > 1 { line += " (\(role))" }
        line += "."
        if let group = makhraj.groupName, let arabic = makhraj.groupArabic, makhraj.letters.count > 1 {
            line += " One of the \(group.lowercased()) letters (\(arabic)): \(makhraj.letters.joined(separator: " "))."
        }
        return line
    }

    private var profileSection: some View {
        Section {
            ForEach(makharij) { makhraj in
                if let zone = LetterTraits.family(id: makhraj.zoneID) {
                    LetterFamilyLink(family: zone) {
                        LetterTraitRow(
                            systemImage: "mouth",
                            lead: "Where it is made",
                            title: zone.meaning,
                            arabic: makhraj.arabic,
                            caption: groupLine(makhraj)
                        )
                    }
                }
            }

            ForEach(sifaat) { family in
                LetterFamilyLink(family: family) {
                    LetterTraitRow(
                        systemImage: family.systemImage,
                        tint: family.legendColor,
                        title: family.title,
                        arabic: family.arabic,
                        caption: family.summary
                    )
                }
            }
        } header: {
            HStack(alignment: .firstTextBaseline) {
                Text("TAJWEED PROFILE")

                Spacer(minLength: 8)

                Text("المَخرَج وَالصِّفَات")
                    .textCase(nil)
            }
        } footer: {
            Text("Where the letter is made, then the qualities it is said with. Tap a line to meet the rest of its family.")
        }
    }

    // MARK: What it does to its neighbours

    private var noonRule: LetterFamily? { LetterTraits.family(of: letter, on: .noonSakinah) }
    private var meemRule: LetterFamily? { LetterTraits.family(of: letter, on: .meemSakinah) }
    private var lamRule: LetterFamily? { LetterTraits.family(of: letter, on: .lamOfAl) }
    private var maddRule: LetterFamily? { LetterTraits.family(of: letter, on: .madd) }
    private var openerRule: LetterFamily? { LetterTraits.family(of: letter, on: .openers) }

    /// The ikhfaa before a heavy letter is itself heavy, and the reader paints it its own colour.
    private var noonTint: Color? {
        guard let noonRule else { return nil }
        if noonRule.id == "ikhfaa", let first = letter.first, TajweedRules.ikhfaaHeavyLetters.contains(first) {
            return TajweedLegendCategory.ikhfaaHeavy.color
        }
        return noonRule.legendColor
    }

    private func ruleRow(
        _ family: LetterFamily, lead: String, tint: Color? = nil, caption: String? = nil, letters: [String] = []
    ) -> some View {
        LetterFamilyLink(family: family) {
            LetterTraitRow(
                systemImage: family.systemImage,
                tint: tint ?? family.legendColor,
                lead: lead,
                title: family.title,
                arabic: family.arabic,
                caption: caption ?? family.summary,
                letters: letters
            )
        }
    }

    private func exampleRow(_ example: LetterRuleExample?) -> some View {
        Group {
            if let example {
                ArabicExampleRow(arabic: example.text, transliteration: "Example", note: example.citation)
            }
        }
    }

    /// How many surahs this letter helps open, ahead of the openings themselves (drawn as their own
    /// line of Arabic: inside an English sentence they came out tiny and in the wrong face).
    private var openingsLine: String {
        let count = Set(LetterTraits.openings(containing: letter).flatMap(\.surahs)).count
        return "In the openings of \(count) \(count == 1 ? "surah" : "surahs"), shown below."
    }

    @ViewBuilder
    private var rulesSection: some View {
        if noonRule != nil || meemRule != nil || lamRule != nil || maddRule != nil || openerRule != nil {
            Section {
                if let noonRule {
                    ruleRow(noonRule, lead: "After noon sakinah or tanween", tint: noonTint)
                    exampleRow(LetterTraits.noonExamples[letter])
                }

                if let meemRule {
                    ruleRow(meemRule, lead: "After meem sakinah")
                    exampleRow(LetterTraits.meemExamples[letter])
                }

                if let lamRule {
                    ruleRow(lamRule, lead: "After the definite article")
                    exampleRow(LetterTraits.lamExamples[letter])
                }

                if let maddRule {
                    ruleRow(maddRule, lead: "As a vowel")
                }

                if let openerRule {
                    ruleRow(openerRule, lead: "As an opening letter",
                            caption: openerRule.summary + " " + openingsLine,
                            letters: LetterTraits.openings(containing: letter).map(\.text))
                }
            } header: {
                HStack(alignment: .firstTextBaseline) {
                    Text("RULES THIS LETTER TRIGGERS")

                    Spacer(minLength: 8)

                    Text("الأَحكَام")
                        .textCase(nil)
                }
            } footer: {
                Text(rulesFooter)
            }
        }
    }

    private var rulesFooter: String {
        if letter == "ا" {
            return "Alif only ever follows a fatha, so it never comes after a noon sakinah, a meem sakinah or the laam of \u{0671}\u{0644}. Tap an example to select it, then press play to hear it."
        }
        return "What happens when \(letterData.transliteration) FOLLOWS each of these. Every example is from the Quran: tap one to select it, then press play to hear it."
    }

    // MARK: Sound-alikes

    @ViewBuilder
    private var soundAlikeSection: some View {
        let pairs = LetterTraits.soundAlikes(for: letter)
        if !pairs.isEmpty {
            Section {
                ForEach(pairs) { pair in
                    SoundAlikeLink(pair: pair, from: letter)
                }

                SoundAlikeIndexLink()
            } header: {
                Text("OFTEN CONFUSED WITH")
            }
        }
    }
}

/// One confusable partner on a letter's page: both glyphs, then what tells them apart. Opens the
/// partner's page, unless that page is already open above this one.
private struct SoundAlikeLink: View {
    @Environment(\.appearance) private var appearance
    @Environment(\.openScreenInstances) private var openInstances

    let pair: SoundAlikePair
    let from: String

    private var partner: LetterData? { LetterTraits.letterData(for: pair.partner(of: from)) }

    private var label: some View {
        HStack(alignment: .center, spacing: 12) {
            TraitArabicText(text: "\(from)  \(pair.partner(of: from))", base: 26, style: .title2)
                .foregroundColor(appearance.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(minWidth: 58)
                .padding(.vertical, appearance.useFontArabic ? 0 : 6)
                .padding(.horizontal, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(appearance.accent.opacity(0.10))
                )
                .environment(\.layoutDirection, .rightToLeft)

            VStack(alignment: .leading, spacing: 2) {
                if let partner {
                    Text(partner.transliteration.prefix(1).uppercased() + partner.transliteration.dropFirst())
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                }

                Text(pair.tip)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
    }

    var body: some View {
        if let partner, !openInstances.contains(OpenScreenInstance(screen: .arabicLetter, id: partner.letter)) {
            NavigationLink(destination: LazyDestination { ArabicLetterView(letterData: partner) }) { label }
        } else {
            label.opacity(0.55)
        }
    }
}

/// The door to the full comparison page, inert when that page is what brought you here.
private struct SoundAlikeIndexLink: View {
    @Environment(\.appearance) private var appearance
    @Environment(\.openScreens) private var openScreens

    var body: some View {
        if openScreens.contains(.soundAlikes) {
            Label("You came from Sound-Alike Letters", systemImage: "ear")
                .font(.body)
                .foregroundColor(.secondary)
                .opacity(0.55)
        } else {
            NavigationLink(destination: LazyDestination { SoundAlikeLettersView() }) {
                Label("Compare All Sound-Alike Letters", systemImage: "ear")
                    .font(.body)
                    .foregroundColor(appearance.accent)
            }
        }
    }
}

// MARK: - Sound-alike letters

/// The pairs a learner swaps, side by side: hear each one, read the one thing that separates them,
/// and see which qualities they share and which they do not. The qualities are read from
/// `LetterTraits`, never written by hand, so the comparison cannot drift from the letter pages.
struct SoundAlikeLettersView: View {
    @Environment(\.appearance) private var appearance
    @ObservedObject private var speech = ArabicSpeech.shared
    @State private var door: ArabicDoor?

    /// The syllable a letter is heard in: the letter with a fatha (a hamza needs its alif seat).
    private static func syllable(_ letter: String) -> String {
        (letter == "ء" ? "أ" : letter) + "\u{064E}"
    }

    var body: some View {
        List {
            Group {
                Section {
                    Text("Most mistakes in recitation are one letter said as its neighbour. Each pair below shares almost everything, which is why the ear confuses them, and differs in the one or two things listed.")
                        .font(.body)

                    Text("Listen to a pair back to back, then say it yourself. Alternating the two is what trains the difference: drilling one letter alone only repeats what you already do.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                ForEach(LetterTraits.soundAlikes) { pair in
                    pairSection(pair)
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .arabicDoorDestination($door)
        .navigationTitle("Sound-Alike Letters")
        .openScreen(.soundAlikes)
        .onDisappear { ArabicSpeech.shared.stop() }
    }

    private func pairSection(_ pair: SoundAlikePair) -> some View {
        let differences = LetterTraits.differences(between: pair.first, and: pair.second)
        let sameExit = LetterTraits.shareExit(pair.first, pair.second)

        return Section {
            HStack(alignment: .top, spacing: 10) {
                ForEach([pair.first, pair.second], id: \.self) { glyph in
                    letterColumn(glyph)
                }
            }
            .padding(.vertical, 4)

            Text(pair.tip)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(differences) { difference in
                    differenceRow(difference, pair: pair, sameExit: sameExit)
                }
            }
            .padding(.vertical, 2)
        } header: {
            HStack(spacing: 8) {
                Text(pairTitle(pair))

                Spacer()

                if speech.isAvailable {
                    let texts = [Self.syllable(pair.first), Self.syllable(pair.second)]
                    let playing = speech.isSpeakingQueue && texts.contains(speech.currentText ?? "")
                    Image(systemName: playing ? "stop.fill" : "speaker.wave.2.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(appearance.accent)
                        .frame(width: SectionPillHeader.pillHeight, height: SectionPillHeader.pillHeight)
                        .conditionalGlassEffect(circle: true)
                        .onTapGesture {
                            Settings.shared.hapticFeedback()
                            if playing { speech.stop() } else { speech.speakAll(texts, rate: 0.3) }
                        }
                        .accessibilityLabel(playing ? "Stop" : "Hear the pair back to back")
                        .accessibilityAddTraits(.isButton)
                }
            }
        }
    }

    private func pairTitle(_ pair: SoundAlikePair) -> String {
        let names = [pair.first, pair.second].compactMap { LetterTraits.letterData(for: $0)?.transliteration.uppercased() }
        return names.joined(separator: "  AND  ")
    }

    private func letterColumn(_ glyph: String) -> some View {
        let syllable = Self.syllable(glyph)
        return VStack(spacing: 6) {
            if let letter = LetterTraits.letterData(for: glyph) {
                Button {
                    Settings.shared.hapticFeedback()
                    door = .letter(letter)
                } label: {
                    LetterGlyphTile(letter: letter, isLit: speech.currentText == syllable)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens the letter")
            }

            PracticeListenButton(text: syllable)
        }
        .frame(maxWidth: .infinity)
    }

    /// One question, and each letter's answer to it: grey when they agree, accent when they differ.
    private func differenceRow(_ difference: LetterTraits.Difference, pair: SoundAlikePair, sameExit: Bool) -> some View {
        // Sharing a zone is not sharing an exit: ذ and ز are both at the tongue tip, a few
        // millimetres apart, and that gap is the whole difference between them.
        let isPlace = difference.axis == .makhraj
        let shared = isPlace ? sameExit : difference.isShared
        let firstText = answer(difference.first, letter: pair.first, isPlace: isPlace, shared: shared)
        let secondText = answer(difference.second, letter: pair.second, isPlace: isPlace, shared: shared)

        return VStack(alignment: .leading, spacing: 2) {
            Text(difference.axis.title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundColor(.secondary)

            if shared {
                Label(isPlace ? "Same exit: \(firstText)" : "Both: \(firstText)", systemImage: "equal.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Label("\(pair.first)  \(firstText)", systemImage: "arrow.left.arrow.right.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(appearance.accent)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(pair.second)  \(secondText)")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(appearance.accent)
                    .padding(.leading, 26)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func answer(_ family: LetterFamily?, letter: String, isPlace: Bool, shared: Bool) -> String {
        if isPlace, !shared, let makhraj = LetterTraits.makharij(of: letter).last {
            return makhraj.place
        }
        return family?.title ?? "None"
    }
}

// MARK: - Letter quiz

#if os(iOS)
/// Ten quick questions on the alphabet, five ways: name a letter, find one, read a joined form, place
/// a letter in its tajweed family, or pick the letter you hear. Every answer comes out of the same
/// tables the pages are drawn from (`standardArabicLetters`, `LetterTraits`), so the quiz can never
/// teach something the letter pages do not say.
struct LetterQuizView: View {
    @Environment(\.appearance) private var appearance
    @ObservedObject private var speech = ArabicSpeech.shared
    @AppStorage("letterQuizBestStreak") private var bestStreak = 0

    enum Mode: String, CaseIterable, Identifiable {
        case name
        case glyph
        case form
        case family
        case listen

        var id: String { rawValue }

        var title: String {
            switch self {
            case .name: return "Name the Letter"
            case .glyph: return "Find the Letter"
            case .form: return "Read the Joined Form"
            case .family: return "Which Family?"
            case .listen: return "Listen and Pick"
            }
        }

        var caption: String {
            switch self {
            case .name: return "See a letter, choose its name"
            case .glyph: return "See a name, choose its letter"
            case .form: return "A letter as it looks inside a word: whose shape is it?"
            case .family: return "Whistling, bouncing, throat, sun and moon: place the letter"
            case .listen: return "Hear a letter's name, choose the letter"
            }
        }

        var specimen: String {
            switch self {
            case .name: return "ب"
            case .glyph: return "؟"
            case .form: return "ـعـ"
            case .family: return "ص س ز"
            case .listen: return "نُون"
            }
        }
    }

    struct Choice: Identifiable {
        let id: Int
        let text: String
        var caption: String? = nil
        var isArabic = false
    }

    struct Question {
        let prompt: String
        var promptIsArabic = true
        let ask: String
        let choices: [Choice]
        let answer: Int
        let explanation: String
        /// Set for the listening quiz: what the speaker button says.
        var spoken: String? = nil
    }

    private static let roundLength = 10

    @State private var mode: Mode?
    @State private var questions: [Question] = []
    @State private var index = 0
    @State private var chosen: Int?
    @State private var correct = 0
    @State private var streak = 0
    @State private var finished = false

    private var modes: [Mode] {
        Mode.allCases.filter { $0 != .listen || speech.isAvailable }
    }

    var body: some View {
        List {
            Group {
                if mode == nil {
                    chooserSection
                } else if finished {
                    resultsSection
                } else if questions.indices.contains(index) {
                    questionSections(questions[index])
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle(mode?.title ?? "Letter Quiz")
        .onDisappear { ArabicSpeech.shared.stop() }
    }

    // MARK: Choosing

    private var chooserSection: some View {
        Section {
            ForEach(modes) { mode in
                Button {
                    Settings.shared.hapticFeedback()
                    start(mode)
                } label: {
                    HStack(spacing: 0) {
                        ArabicTopicLinkLabel(specimen: mode.specimen, title: mode.title, caption: mode.caption)

                        Spacer(minLength: 8)

                        Image(systemName: "play.circle.fill")
                            .font(.title3)
                            .foregroundColor(appearance.accent)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("CHOOSE A QUIZ")
        } footer: {
            Text(bestStreak > 0
                 ? "Ten questions a round. Your best run of right answers so far: \(bestStreak)."
                 : "Ten questions a round.")
        }
    }

    // MARK: Asking

    @ViewBuilder
    private func questionSections(_ question: Question) -> some View {
        Section {
            VStack(spacing: 10) {
                if let spoken = question.spoken {
                    Button {
                        Settings.shared.hapticFeedback()
                        speech.speak(spoken)
                    } label: {
                        Image(systemName: speech.currentText == spoken ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundColor(appearance.accent)
                            .frame(width: 96, height: 96)
                            .background(Circle().fill(appearance.accent.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Hear it again")
                } else if question.promptIsArabic {
                    TraitArabicText(text: question.prompt, base: 64, style: .largeTitle)
                        .foregroundColor(appearance.accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.3)
                        .frame(minHeight: 96)
                } else {
                    Text(question.prompt)
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(appearance.accent)
                        .multilineTextAlignment(.center)
                        .frame(minHeight: 96)
                }

                Text(question.ask)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        } header: {
            HStack {
                Text("QUESTION \(index + 1) OF \(questions.count)")

                Spacer()

                if streak > 1 {
                    Label("\(streak) in a row", systemImage: "flame.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(appearance.accent)
                        .textCase(nil)
                }
            }
        }

        Section {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                ForEach(question.choices) { choice in
                    choiceButton(choice, in: question)
                }
            }
            .padding(.vertical, 4)

            if let chosen {
                VStack(alignment: .leading, spacing: 6) {
                    Label(chosen == question.answer ? "Right" : "Not quite",
                          systemImage: chosen == question.answer ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(chosen == question.answer ? .green : .red)

                    Text(question.explanation)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 2)

                Button {
                    Settings.shared.hapticFeedback()
                    advance()
                } label: {
                    Text(index + 1 == questions.count ? "See Results" : "Next Question")
                        .font(.body.weight(.semibold))
                        .foregroundColor(appearance.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .conditionalGlassEffect(rectangle: true)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func choiceButton(_ choice: Choice, in question: Question) -> some View {
        let answered = chosen != nil
        let isAnswer = choice.id == question.answer
        let isWrongPick = chosen == choice.id && !isAnswer
        let stroke: Color = !answered ? .clear : isAnswer ? .green : isWrongPick ? .red : .clear

        return Button {
            guard chosen == nil else { return }
            Settings.shared.hapticFeedback()
            choose(choice.id, in: question)
        } label: {
            VStack(spacing: 2) {
                if choice.isArabic {
                    TraitArabicText(text: choice.text, base: 34, style: .title)
                        .foregroundColor(appearance.accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                } else {
                    Text(choice.text)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }

                // The caption NAMES the choice, so it appears only once the question is answered.
                if let caption = choice.caption, answered {
                    Text(caption)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 64)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(appearance.accent.opacity(answered && isAnswer ? 0.18 : 0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(stroke, lineWidth: 2)
            )
            .opacity(answered && !isAnswer && !isWrongPick ? 0.45 : 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(choice.caption.map { "\(choice.text), \($0)" } ?? choice.text)
    }

    // MARK: Results

    private var resultsSection: some View {
        Section {
            VStack(spacing: 8) {
                Text("\(correct) of \(questions.count)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(appearance.accent)

                Text(correct == questions.count ? "Every one right."
                     : correct * 2 >= questions.count ? "Most of it is there. Another round will settle the rest."
                     : "Open the letters you missed, then come back for another round.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                if bestStreak > 0 {
                    Label("Best run of right answers: \(bestStreak)", systemImage: "flame.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(appearance.accent)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)

            Button {
                Settings.shared.hapticFeedback()
                if let mode { start(mode) }
            } label: {
                Label("Play Again", systemImage: "arrow.clockwise")
                    .font(.body.weight(.semibold))
                    .foregroundColor(appearance.accent)
            }

            Button {
                Settings.shared.hapticFeedback()
                mode = nil
            } label: {
                Label("Choose Another Quiz", systemImage: "list.bullet")
                    .font(.body)
                    .foregroundColor(appearance.accent)
            }
        } header: {
            Text("RESULTS")
        }
    }

    // MARK: Running a round

    private func start(_ mode: Mode) {
        self.mode = mode
        questions = Self.makeRound(mode)
        index = 0
        chosen = nil
        correct = 0
        finished = false
        speakCurrent()
    }

    private func choose(_ id: Int, in question: Question) {
        chosen = id
        if id == question.answer {
            correct += 1
            streak += 1
            if streak > bestStreak { bestStreak = streak }
        } else {
            streak = 0
        }
    }

    private func advance() {
        chosen = nil
        if index + 1 >= questions.count {
            finished = true
        } else {
            index += 1
            speakCurrent()
        }
    }

    /// The listening quiz says its letter as the question arrives.
    private func speakCurrent() {
        guard questions.indices.contains(index), let spoken = questions[index].spoken else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { speech.speak(spoken) }
    }

    // MARK: Building questions

    /// Letters whose shapes differ only by dots, so a wrong answer is a plausible one.
    private static let shapeGroups: [[String]] = [
        ["ب", "ت", "ث", "ن", "ي"], ["ج", "ح", "خ"], ["د", "ذ"], ["ر", "ز"], ["س", "ش"],
        ["ص", "ض"], ["ط", "ظ"], ["ع", "غ"], ["ف", "ق"], ["ك", "ل"],
    ]

    /// Three wrong letters for `letter`: look-alikes and sound-alikes first, then anyone.
    private static func distractors(for letter: LetterData) -> [LetterData] {
        let lookAlikes = shapeGroups.first { $0.contains(letter.letter) } ?? []
        let soundAlikes = LetterTraits.soundAlikes(for: letter.letter).map { $0.partner(of: letter.letter) }
        var picked: [LetterData] = []
        for glyph in (lookAlikes + soundAlikes).shuffled() where glyph != letter.letter {
            guard let data = standardArabicLetters.first(where: { $0.letter == glyph }),
                  !picked.contains(data) else { continue }
            picked.append(data)
            if picked.count == 2 { break }
        }
        for data in standardArabicLetters.shuffled() where data != letter && !picked.contains(data) {
            if picked.count == 3 { break }
            picked.append(data)
        }
        return picked
    }

    /// The four choices in random order, and where the right one landed.
    private static func shuffledChoices(
        right: LetterData, wrong: [LetterData], arabic: Bool
    ) -> (choices: [Choice], answer: Int) {
        let order = ([right] + wrong).shuffled()
        let choices = order.enumerated().map { offset, data in
            arabic
                ? Choice(id: offset, text: data.letter, caption: data.transliteration, isArabic: true)
                : Choice(id: offset, text: data.transliteration)
        }
        return (choices, order.firstIndex(of: right) ?? 0)
    }

    private static let formPositions = ["at the end of a word", "in the middle of a word", "at the start of a word"]

    /// Families a letter can sensibly be "placed in": the named side of each pair and the small
    /// groups, not the complements ("every other letter" is not a fair question).
    private static let quizFamilies: [LetterFamily] = [
        LetterTraits.hams, LetterTraits.shiddah, LetterTraits.tawassut, LetterTraits.istila,
        LetterTraits.itbaq, LetterTraits.idhlaq, LetterTraits.safeer, LetterTraits.qalqalah,
        LetterTraits.inhiraf, LetterTraits.ghunnah, LetterTraits.halq, LetterTraits.aqsaLisan,
        LetterTraits.wasatLisan, LetterTraits.shafatan, LetterTraits.idhaar, LetterTraits.idghamGhunnah,
        LetterTraits.idghamBilaGhunnah, LetterTraits.ikhfaa, LetterTraits.sunLetters,
        LetterTraits.moonLetters, LetterTraits.heavy, LetterTraits.maddLetters,
    ]

    private static func makeRound(_ mode: Mode) -> [Question] {
        switch mode {
        case .family:
            return quizFamilies.shuffled().prefix(roundLength).compactMap(familyQuestion)
        default:
            return standardArabicLetters.shuffled().prefix(roundLength).map { letterQuestion($0, mode: mode) }
        }
    }

    private static func letterQuestion(_ letter: LetterData, mode: Mode) -> Question {
        let wrong = distractors(for: letter)
        let name = letter.transliteration
        let sound = letter.englishSound.map { " " + $0 } ?? ""

        switch mode {
        case .glyph:
            let (choices, answer) = shuffledChoices(right: letter, wrong: wrong, arabic: true)
            return Question(prompt: name, promptIsArabic: false, ask: "Which letter is \(name)?",
                            choices: choices, answer: answer, explanation: "\(letter.letter) is \(name).\(sound)")
        case .form:
            let position = Int.random(in: 0..<min(3, letter.forms.count))
            let (choices, answer) = shuffledChoices(right: letter, wrong: wrong, arabic: false)
            return Question(prompt: letter.forms[position], ask: "This is a letter \(formPositions[position]). Which one?",
                            choices: choices, answer: answer,
                            explanation: "\(letter.forms[position]) is \(name) (\(letter.letter)) \(formPositions[position]).")
        case .listen:
            let (choices, answer) = shuffledChoices(right: letter, wrong: wrong, arabic: true)
            return Question(prompt: "", ask: "Which letter did you hear named?", choices: choices, answer: answer,
                            explanation: "That was \(name) (\(letter.letter)).\(sound)", spoken: letter.name)
        default:
            let (choices, answer) = shuffledChoices(right: letter, wrong: wrong, arabic: false)
            return Question(prompt: letter.letter, ask: "Which letter is this?", choices: choices, answer: answer,
                            explanation: "\(letter.letter) is \(name).\(sound)")
        }
    }

    private static func familyQuestion(_ family: LetterFamily) -> Question? {
        guard let rightGlyph = family.letters.randomElement(),
              let right = LetterTraits.letterData(for: rightGlyph) else { return nil }
        let outsiders = LetterTraits.alphabet
            .filter { !family.contains($0) }
            .compactMap { LetterTraits.letterData(for: $0) }
            .shuffled()
            .prefix(3)
        guard outsiders.count == 3 else { return nil }
        let (choices, answer) = shuffledChoices(right: right, wrong: Array(outsiders), arabic: true)
        return Question(
            prompt: family.arabic,
            ask: "Which of these is a \(family.name) letter? \(family.summary)",
            choices: choices, answer: answer,
            explanation: "\(family.title): \(family.letters.joined(separator: " "))"
        )
    }
}
#endif
