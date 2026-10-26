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

    @Environment(\.appearance) private var appearance
    /// The size while the thumb is down; nil otherwise.
    @State private var dragging: Double? = nil

    init(_ title: String, value: Binding<Double>, in range: ClosedRange<Double>, sample: String?,
         fontName: String? = nil, glyph: String = "A",
         label: @escaping (Double) -> String = { String(localized: "\(Int($0.rounded())) pt") },
         onLiveChange: ((Double) -> Void)? = nil,
         sampleTypeSize: ((Double) -> DynamicTypeSize)? = nil) {
        self.title = title
        self._value = value
        self.range = range
        self.sample = sample
        self.fontName = fontName
        self.glyph = glyph
        self.label = label
        self.onLiveChange = onLiveChange
        self.sampleTypeSize = sampleTypeSize
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
            HStack {
                Text(title)
                Spacer()
                Text(label(shown))
                    .foregroundColor(.secondary)
                    .monospacedDigit()
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
    /// What the size sliders draw at the live size. Short on purpose: the Quran's Arabic runs to
    /// 75 pt, where even the Basmalah alone takes two lines of a phone.
    static let arabicSizeSample = "بِسْمِ ٱللَّهِ"
    static let englishSizeSample = "In the name of Allah, the Entirely Merciful, the Especially Merciful."
    static let hadithArabicSizeSample = "قَالَ رَسُولُ اللَّهِ"
    static let hadithEnglishSizeSample = "The Messenger of Allah (ﷺ) said:"
}
