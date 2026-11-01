//
//  SettingsControls.swift
//  Al-Islam
//
//  The controls every settings page is built from, in one grammar (Abu, 2026-10-21: "redo all of
//  settings and make it look good ... small baa on the left, big baa on the right ... switching
//  arabic font size is mad laggy, switching some settings in general very laggy").
//
//  Compiles into the iPhone and Watch targets (SettingsQuranView and SettingsAdhanView are shared),
//  so nothing here may need UIKit outside `#if os(iOS)`.
//

import SwiftUI

// MARK: - Page animations

/// Why a settings write carries a FLAGGED animation, and why the readers refuse it.
///
/// A settings write is a publish: an `@AppStorage` write republishes `Settings` to every observer in
/// the app. `$settings.x.animation(.easeInOut)` put that write inside an animated transaction, so
/// the mushaf pages behind the sheet and every ayah row re-laid themselves out INSIDE the animation
/// on every flip (the trap recorded in `page-mode-chrome-bands` and in the Two-Page Spread comment
/// that used to sit in SettingsQuranView). All the animation was ever for was the settings page: a
/// dependent row sliding in under its switch.
///
/// SwiftUI gives no way to animate only the page: a List's row insert animates only when the
/// transaction of the state change that inserted it carries an animation, and that state is
/// `Settings` itself (tried and measured 2026-10-21: a page-local counter animated through
/// `.animation(_:value:)` on the List left the row popping in one frame). So the write keeps its
/// animation and is flagged (`Transaction.isSettingsWrite`), and the reading surfaces strip the
/// animation from that one kind of transaction (`ignoresSettingsPageAnimation()`), keeping their own.
/// The flag needs iOS 17's `TransactionKey`; on iOS 16 the write animates everything, as it always did.
@available(iOS 17.0, watchOS 10.0, *)
private struct SettingsWriteTransactionKey: TransactionKey {
    static let defaultValue = false
}

extension Transaction {
    /// True for the transaction a settings control writes in (see above).
    var isSettingsWrite: Bool {
        get {
            if #available(iOS 17.0, watchOS 10.0, *) { return self[SettingsWriteTransactionKey.self] }
            return false
        }
        set {
            if #available(iOS 17.0, watchOS 10.0, *) { self[SettingsWriteTransactionKey.self] = newValue }
        }
    }
}

/// Runs `write` in the transaction every settings control writes in: the page's ease-in-out (none
/// under Reduce Motion or Low Power Mode), flagged so the readers can refuse it.
func withSettingsPageAnimation(_ write: () -> Void) {
    var transaction = Transaction(animation: AppPerformance.shouldReduceAnimations ? nil : .easeInOut)
    transaction.isSettingsWrite = true
    withTransaction(transaction, write)
}

extension View {
    /// For the reading surfaces (the mushaf pager, the ayah list): a settings page's animated write
    /// updates this view plainly, while the view's own animations are untouched. Put it INSIDE any
    /// `.sheet` that hosts a settings page, or that page loses its row animations too.
    func ignoresSettingsPageAnimation() -> some View {
        transaction { transaction in
            if transaction.isSettingsWrite { transaction.animation = nil }
        }
    }
}

// MARK: - Labels and captions

/// A control's label in the Settings grammar: an optional accent symbol, the title, and the caption
/// under the title. Inside a `Toggle`'s label, so the switch centres on title and caption together
/// and the caption never runs on under the switch, which is where the old free-standing caption
/// `Text` under each toggle ended up.
struct SettingsControlLabel: View {
    let title: String
    var caption: String? = nil
    var systemImage: String? = nil

    @Environment(\.appearance) private var appearance

    var body: some View {
        HStack(spacing: 12) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundColor(appearance.accent)
                    .frame(width: 22, alignment: .center)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title.localizedDigits)
                    .foregroundColor(.primary)

                // The caption is an iPhone luxury; the watch's rows have no room for it.
                #if os(iOS)
                if let caption, !caption.isEmpty {
                    SettingsCaption(caption)
                }
                #endif
            }
        }
        .padding(.vertical, caption == nil ? 0 : 3)
    }
}

/// The one caption style: `.caption`, secondary, wrapping. Under a control, or free-standing in a
/// section for a note that belongs to no single control.
struct SettingsCaption: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text.localizedDigits)
            .font(.caption)
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Toggle

/// A switch in the Settings grammar: title, caption under it inside the label, the accent tint, a
/// haptic on every flip, and the flagged page animation described under "Page animations" above.
///
/// Pass a plain binding (`$settings.x` or a hand-rolled `Binding`), never one with `.animation`
/// on it, and never wrap a hand-rolled setter's writes in `withAnimation`: this control supplies
/// the one transaction the readers know how to refuse.
struct SettingsToggle: View {
    let title: String
    var caption: String? = nil
    var systemImage: String? = nil
    @Binding var isOn: Bool

    @Environment(\.appearance) private var appearance

    init(_ title: String, caption: String? = nil, systemImage: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.caption = caption
        self.systemImage = systemImage
        self._isOn = isOn
    }

    var body: some View {
        Toggle(isOn: pageAnimatedBinding) {
            SettingsControlLabel(title: title, caption: caption, systemImage: systemImage)
        }
        .tint(appearance.accent)
    }

    private var pageAnimatedBinding: Binding<Bool> {
        Binding(
            get: { isOn },
            set: { newValue in
                guard newValue != isOn else { return }
                Settings.shared.hapticFeedback()
                withSettingsPageAnimation { isOn = newValue }
            }
        )
    }
}

// MARK: - Font size

/// A text-size control the way iOS draws its own (Settings > Display & Brightness > Text Size): the
/// title and the size, a sample of the text at that size, and a slider running from a small glyph
/// to a large one of the same letter: a small ب and a big ب for Arabic, a small A and a big A for
/// English (Abu, 2026-10-21). The two glyphs are buttons: a tap steps the size one point, which is
/// what the Stepper row that used to sit above the slider was for.
///
/// Performance: the control holds the size LOCALLY while the thumb moves and writes `value` once,
/// on release. Bound straight to `Settings`, the slider wrote UserDefaults on every point the thumb
/// passed, and every write republished Settings inside an animated transaction: the mushaf pages
/// behind the sheet recomposed, every ayah row re-laid itself out and every tab root re-rendered,
/// once per point, which was the "mad laggy" Arabic font size slider. Now the sample line is what
/// moves while the thumb does; the reader moves once, when the thumb lifts.
struct FontSizeSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    /// The sample text drawn at the live size; nil for a control whose page previews elsewhere.
    let sample: String?
    /// The face the sample and the two glyphs are set in; nil is the system face.
    var fontName: String? = nil
    /// The letter at the slider's two ends.
    var glyph: String = "A"
    /// The size as the row's trailing read-out.
    var label: (Double) -> String = { String(localized: "\(Int($0.rounded())) pt") }
    /// Every size the thumb passes, for a page that previews the size outside this control.
    var onLiveChange: ((Double) -> Void)? = nil
    /// For a control whose value is a Dynamic Type STEP rather than a point size (the Islam tab's
    /// two sliders): the type size the sample reads at for a value. The sample is then the body
    /// style at that size, in `fontName` when one is given, instead of `value` points.
    var sampleTypeSize: ((Double) -> DynamicTypeSize)? = nil
    /// Without the title row: the two glyph steps and the slider alone, for a floating bar that has
    /// no room for a title (the riwayah comparison sheet's text size bar). The title still names the
    /// control to accessibility.
    var compact = false

    @Environment(\.appearance) private var appearance
    /// The size while the thumb is down; nil otherwise.
    @State private var dragging: Double? = nil

    init(_ title: String, value: Binding<Double>, in range: ClosedRange<Double>, sample: String?,
         fontName: String? = nil, glyph: String = "A",
         label: @escaping (Double) -> String = { String(localized: "\(Int($0.rounded())) pt") },
         onLiveChange: ((Double) -> Void)? = nil,
         sampleTypeSize: ((Double) -> DynamicTypeSize)? = nil,
         compact: Bool = false) {
        self.title = title
        self._value = value
        self.range = range
        self.sample = sample
        self.fontName = fontName
        self.glyph = glyph
        self.label = label
        self.onLiveChange = onLiveChange
        self.sampleTypeSize = sampleTypeSize
        self.compact = compact
    }

    private var shown: Double { dragging ?? value }

    private func font(size: Double) -> Font {
        fontName.map { Font.arabic($0, size: CGFloat(size)) } ?? .system(size: CGFloat(size))
    }

    /// The sample at the live size: `shown` points, or the body style at the Dynamic Type step
    /// `sampleTypeSize` names for it.
    @ViewBuilder
    private func sampleText(_ sample: String) -> some View {
        if let sampleTypeSize {
            Text(sample)
                .font(scaledSampleFont)
                .dynamicTypeSize(sampleTypeSize(shown))
        } else {
            Text(sample)
                .font(font(size: shown))
        }
    }

    /// The body style in `fontName`, scaling with Dynamic Type. The Basic sentinel is the rounded
    /// system face (`Font.arabic`'s fixed-size branch would not scale).
    private var scaledSampleFont: Font {
        guard let fontName else { return .body }
        if fontName == Settings.systemArabicFontName { return .system(.body, design: .rounded) }
        return .custom(fontName, size: 17, relativeTo: .body)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !compact {
                HStack {
                    Text(title)
                    Spacer()
                    Text(label(shown))
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
            }

            if let sample {
                sampleText(sample)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
                    .accessibilityHidden(true)
            }

            #if os(iOS)
            HStack(spacing: 10) {
                stepButton(delta: -1, glyphSize: 13)
                slider
                stepButton(delta: 1, glyphSize: 26)
            }
            #else
            slider
            #endif
        }
        .padding(.vertical, 4)
        // A drag the system cancels (the sheet pulled down mid-drag) never sends the release.
        .onDisappear(perform: commit)
    }

    private var slider: some View {
        Slider(
            value: Binding(get: { shown }, set: { dragging = $0; onLiveChange?($0) }),
            in: range,
            step: 1
        ) { editing in
            if !editing { commit() }
        }
        .tint(appearance.accent)
        .accessibilityLabel(title)
        .accessibilityValue(label(shown))
    }

    /// Writes the dragged size once, on release.
    private func commit() {
        guard let dragged = dragging else { return }
        dragging = nil
        let clamped = min(max(dragged.rounded(), range.lowerBound), range.upperBound)
        guard clamped != value else { return }
        Settings.shared.hapticFeedback()
        value = clamped
    }

    #if os(iOS)
    private func stepButton(delta: Double, glyphSize: CGFloat) -> some View {
        let enabled = range.contains(value + delta)
        return Button {
            dragging = nil
            Settings.shared.hapticFeedback()
            value = min(max(value + delta, range.lowerBound), range.upperBound)
        } label: {
            Text(glyph)
                .font(font(size: glyphSize))
                .foregroundColor(enabled ? .primary : .secondary)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(delta < 0 ? String(localized: "Smaller") : String(localized: "Larger"))
    }
    #endif
}

// MARK: - The samples

extension Settings {
    /// What the size sliders draw at the live size where a page has no reading preview (the watch).
    /// Short on purpose: the Quran's Arabic runs to 75 pt, where even the Basmalah alone takes two
    /// lines of a phone. On the iPhone the Quran, hadith and Al-Islam size pages show the reader's
    /// own row instead (`QuranReadingPreview` and its siblings below).
    static let arabicSizeSample = "بِسْمِ ٱللَّهِ"
    static let englishSizeSample = "In the name of Allah, the Entirely Merciful, the Especially Merciful."
    static let hadithArabicSizeSample = "قَالَ رَسُولُ اللَّهِ"
    static let hadithEnglishSizeSample = "The Messenger of Allah (ﷺ) said:"
}

#if os(iOS)
// MARK: - Reading previews

/// The settings previews (Abu, 2026-11-01: "for the preview make it actually look like the preview we
/// have ... actually make it a full preview and do stuff like that everywhere in the app"): each size
/// page shows the row the reader will draw, every setting of the page applied, at the size its slider
/// is at RIGHT NOW. The sliders feed the live size every point the thumb passes
/// (`FontSizeSlider.onLiveChange`), so the card moves with the thumb while the reader itself still
/// moves once, on release. Nothing in a preview is tappable: it is a picture of the row, not the row.

/// A header control the reader's rows wear (the ▶ and ⋯), drawn, not wired.
private struct PreviewHeaderIcon: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 25, height: 25)
            .foregroundColor(Settings.shared.accentColor.color)
            .conditionalGlassEffect(interactive: false)
            .frame(width: 28, height: 28)
            .accessibilityHidden(true)
    }
}

/// The Quran reader's row, as Quran Settings previews it: the "S:A" pill, the Arabic through the
/// reader's own pipeline (`AyahArabicSnippet`: the face, the tajweed colors, beginner spacing, hidden
/// tashkeel or dots, the riwayah on screen), then the transliteration and translations the reader
/// shows, numbered the way the reader numbers them.
struct QuranReadingPreview: View {
    private let settings = Settings.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    /// The Arabic size while a slider's thumb is down; nil reads the setting.
    var arabicSize: Double? = nil
    /// The English size while a slider's thumb is down; nil reads the setting.
    var englishSize: Double? = nil

    /// Al-Fatihah's second ayah: short, known by heart, and colored by four tajweed rules.
    private static let surahNumber = 1
    private static let ayahNumber = 2

    private var arabicScale: CGFloat {
        let current = max(settings.fontArabicSize, 1)
        return CGFloat((arabicSize ?? current) / current)
    }

    var body: some View {
        if let surah = QuranData.shared.surah(Self.surahNumber),
           let ayah = QuranData.shared.ayah(surah: Self.surahNumber, ayah: Self.ayahNumber) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text("\(Self.surahNumber):\(Self.ayahNumber)")
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                        .foregroundColor(settings.accentColor.color)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .frame(height: 28)
                        .conditionalGlassEffect(interactive: false)

                    Text(surah.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    if settings.isHafsDisplay, !settings.hides(.ayahPlayMenu) {
                        PreviewHeaderIcon(systemName: "play.circle")
                    }
                    PreviewHeaderIcon(systemName: "ellipsis.circle")
                }

                if settings.showArabicText {
                    AyahArabicSnippet(surah: surah, ayah: ayah, scale: arabicScale, lineLimit: nil)
                }

                englishLines(ayah)
            }
            .padding(.vertical, 4)
            .allowsHitTesting(false)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Preview of the reader")
        }
    }

    /// The reader's English lines (`AyahRow.ayahTextBlock`): the ayah number leads the first of them.
    @ViewBuilder
    private func englishLines(_ ayah: Ayah) -> some View {
        if settings.isHafsDisplay {
            let size = CGFloat(englishSize ?? settings.englishFontSize)
            let showTranslit = settings.showTransliteration
            let showSaheeh = settings.showEnglishSaheeh
            let showMustafa = settings.showEnglishMustafa
            let prefix = "\(Self.ayahNumber). "
            if showTranslit {
                englishLine(prefix + ayah.textTransliteration, size: size)
            }
            if showSaheeh {
                englishLine((showTranslit ? "" : prefix) + ayah.textEnglishSaheeh, size: size)
            }
            if showMustafa {
                englishLine((showTranslit || showSaheeh ? "" : prefix) + ayah.textEnglishMustafa, size: size)
            }
        }
    }

    private func englishLine(_ text: String, size: CGFloat) -> some View {
        Text(text)
            .font(.system(size: size))
            .foregroundColor(.primary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .leftToRightContent()
    }
}

/// A hadith row (`HadithRow`), as Hadith Settings previews it: the citation pill, the Arabic in the
/// hadith face, the narrator line and the narration, at the live sizes.
struct HadithReadingPreview: View {
    private let settings = Settings.shared
    @ObservedObject private var hadithSettings = HadithSettings.shared
    @ObservedObject private var islamSettings = IslamSettings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    var arabicSize: Double? = nil
    var englishSize: Double? = nil

    /// Sahih al-Bukhari 13 as sunnah.com prints it: short, and one every reader knows.
    private static let arabic = "عَنْ أَنَسٍ عَنِ النَّبِيِّ صلى الله عليه وسلم قَالَ: لاَ يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ."
    private static let narrator = "Narrated Anas:"
    private static let english = "The Prophet (ﷺ) said, \"None of you will have faith till he wishes for his (Muslim) brother what he likes for himself.\""

    var body: some View {
        let arabicPoints = CGFloat(arabicSize ?? settings.hadithArabicFontSize)
        let englishPoints = CGFloat(englishSize ?? settings.hadithEnglishFontSize)
        let customFace = settings.hadithArabicWantsCustomFace
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                HStack(spacing: 5) {
                    Text("13")
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                    Text("Sahih al-Bukhari")
                        .font(.caption.weight(.semibold))
                }
                .foregroundColor(settings.accentColor.color)
                .lineLimit(1)
                .padding(.horizontal, 8)
                .frame(height: 28)
                .conditionalGlassEffect(interactive: false)

                Spacer(minLength: 4)

                PreviewHeaderIcon(systemName: "ellipsis.circle")
            }

            if settings.showHadithArabic {
                HighlightedSnippet(
                    source: Self.arabic,
                    term: "",
                    font: customFace ? Font.arabic(settings.nonQuranArabicFontName, size: arabicPoints) : .system(size: arabicPoints),
                    accent: settings.accentColor.color,
                    fg: .primary,
                    highlightAllahNames: settings.highlightAllahNamesHadith
                )
                .arabicFontDesign(custom: customFace)
                .multilineTextAlignment(.trailing)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .environment(\.layoutDirection, .leftToRight)
                .fixedSize(horizontal: false, vertical: true)
            }

            if settings.showHadithEnglish {
                HighlightedSnippet(
                    source: Self.narrator,
                    term: "",
                    font: .system(size: englishPoints).italic(),
                    accent: settings.accentColor.color,
                    fg: .secondary,
                    highlightAllahNames: settings.highlightAllahNamesHadith
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .leftToRightContent()

                HighlightedSnippet(
                    source: Self.english,
                    term: "",
                    font: .system(size: englishPoints),
                    accent: settings.accentColor.color,
                    fg: .primary,
                    highlightAllahNames: settings.highlightAllahNamesHadith
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .leftToRightContent()
            }
        }
        .padding(.vertical, 4)
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Preview of a hadith")
    }
}

/// An Al-Islam article, as Islam Settings' Text Size previews it: a heading, a paragraph, and an
/// Arabic card with its translation, in the tab's face, at the live size.
struct IslamReadingPreview: View {
    private let settings = Settings.shared
    @ObservedObject private var islamSettings = IslamSettings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @Environment(\.dynamicTypeSize) private var inherited
    /// The size the Al-Islam tab reads at; nil follows the device.
    let size: DynamicTypeSize?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Morning Remembrance")
                .font(.headline)

            Text("Said after Fajr, before the day's first errand. The morning is given back to its Owner before anyone makes plans for it.")
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 6) {
                Text("أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ")
                    .font(settings.scalableIslamArabicFont(base: 24, relativeTo: .title3))
                    .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .environment(\.layoutDirection, .rightToLeft)

                Text("We have reached the morning, and the dominion has reached the morning belonging to Allah.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(12)
            .conditionalGlassEffect(clear: true, rectangle: true)
        }
        .dynamicTypeSize(size ?? inherited)
        .padding(.vertical, 4)
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Preview of an article")
    }
}

/// The alphabet's rows (`ArabicLetterRow`), as Islam Settings' Arabic Size previews them: the letter
/// in its glass badge, its name and transliteration, its three joined forms, at the live size.
struct AlphabetReadingPreview: View {
    private let settings = Settings.shared
    @ObservedObject private var islamSettings = IslamSettings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    /// The size the letters read at (the floor the slider sets, over the tab's size).
    let size: DynamicTypeSize

    /// The first three letters: enough rows to read as the alphabet screen.
    private var letters: [LetterData] { Array(standardArabicLetters.prefix(3)) }

    var body: some View {
        let useFace = settings.useFontArabic
        let face = settings.nonQuranArabicFontName
        let custom = useFace && face != Settings.systemArabicFontName
        VStack(spacing: 0) {
            ForEach(Array(letters.enumerated()), id: \.element.id) { index, letter in
                if index > 0 { Divider() }
                HStack(spacing: 12) {
                    Text(letter.letter.components(separatedBy: " - ").last ?? letter.letter)
                        .font(useFace ? Font.arabic(face, size: 24, relativeTo: .title2) : .title2)
                        .arabicFontDesign(custom: custom)
                        .foregroundColor(settings.accentColor.color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(width: 42, height: 38)
                        .conditionalGlassEffect(clear: true, rectangle: true)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(letter.name)
                            .font(useFace ? Font.arabic(face, size: 16, relativeTo: .subheadline) : .subheadline)
                            .arabicFontDesign(custom: custom)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        Text(letter.transliteration)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 4)

                    Text(letter.writtenForms.reversed().joined(separator: "\u{2002}"))
                        .font(useFace ? Font.arabic(face, size: 13, relativeTo: .caption) : .caption)
                        .arabicFontDesign(custom: custom)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .padding(.vertical, 6)
            }
        }
        .dynamicTypeSize(size)
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Preview of the alphabet")
    }
}
#endif
