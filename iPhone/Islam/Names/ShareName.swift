#if os(iOS)
import SwiftUI

/// Drives the Share Name sheet from anywhere. A singleton for the same reason
/// `FocusOverlayPresenter` is one: the menu that opens it (`nameContextItems`) is a free function
/// shared by a List row's `contextMenu` AND by a grid tile's `GridTileMenu`, and many tiles sit in
/// ONE List row - so the sheet cannot live on the row (two presenters, one Bool: see
/// `sheet-on-section-double-bridge`) and the menu itself cannot hold state at all.
@MainActor
final class NameSharePresenter: ObservableObject {
    static let shared = NameSharePresenter()
    private init() {}

    @Published var name: NameOfAllah?

    func present(_ name: NameOfAllah) { self.name = name }
}

/// Hosts the Share Name sheet once, at the root of the 99 Names screen. Attach it to the List, not
/// to a row: a lazy row's own sheet does not exist until the row is on screen.
struct NameShareHost: ViewModifier {
    @ObservedObject private var presenter = NameSharePresenter.shared

    func body(content: Content) -> some View {
        content.sheet(item: $presenter.name) { name in
            NameShareSheet(name: name)
        }
    }
}

extension View {
    func nameShareHost() -> some View { modifier(NameShareHost()) }
}

/// "Share Name" for one of the 99 Names - the Share Ayah / Share Hadith sheet, for a Name
/// (Abu, 2026-09-23: "instead of having a million copy x on context menu 99 names of Allah add a
/// similar thing to share ayah/share hadith").
///
/// The name's context menu used to carry SIX copy items (Copy All, Arabic, Transliteration,
/// Translation, First Found, Description). They are all one question - "which parts do you want?" -
/// and a menu is the wrong shape for it: you cannot see what you are about to get, and picking two
/// parts means copying twice. This sheet asks the question once, with a live preview, and its Copy
/// button replaces every one of them.
///
/// Built on `HadithShareSheet`'s shape, which is itself `ShareAyahSheet`'s: preview on top, the
/// include toggles under it, the Image/Text picker, then Copy and Share. The three surfaces are
/// deliberately identical, so knowing one is knowing all three.
struct NameShareSheet: View {
    @ObservedObject private var settings = Settings.shared
    @Environment(\.presentationMode) private var presentationMode

    let name: NameOfAllah

    // What travels with the share - persisted, so the sheet reopens the way it was left, and read
    // back by `composedText` so any other caller composes exactly what this sheet previews.
    @AppStorage("shareNameArabic") private var includeArabic = true
    @AppStorage("shareNameTransliteration") private var includeTransliteration = true
    @AppStorage("shareNameTranslation") private var includeTranslation = true
    @AppStorage("shareNameOtherNames") private var includeOtherNames = false
    @AppStorage("shareNameFirstFound") private var includeFirstFound = false
    @AppStorage("shareNameDescription") private var includeDescription = false
    /// The share's Arabic face, image mode only - the face is a property of the drawn card, not of
    /// the text, exactly as in `HadithShareSheet`.
    @AppStorage("shareNameFontFace") private var shareFontFaceRaw = ""
    /// ShareAyah's `shareAyahLastActionMode`, for names: the sheet reopens in the mode last used.
    @AppStorage("shareNameLastActionMode") private var storedActionModeRaw: String = ActionMode.image.rawValue

    @State private var actionMode: ActionMode = .image
    @State private var generatedImage: UIImage?
    @State private var activityItems: [Any] = []
    @State private var showingActivityView = false
    /// Whether the last system share actually completed (vs. cancelled) - gates the auto-dismiss.
    @State private var didCompleteShare = false
    @State private var didInit = false
    @State private var didFinishInitialSetup = false
    @State private var isGeneratingImage = false
    @State private var isSharing = false
    /// ShareAyah's generation guard: rapid toggle flips overlap renders, and without this the LAST
    /// render to FINISH won - a stale frame could land over the current options' image.
    @State private var imageGenerationID = 0
    private static let shareImageQueue = DispatchQueue(label: "app.shareName.imageGeneration", qos: .userInitiated)

    private var shareFace: Settings.IslamArabicFace {
        Settings.IslamArabicFace(rawValue: shareFontFaceRaw) ?? settings.islamArabicFace
    }

    private var shareFaceBinding: Binding<Settings.IslamArabicFace> {
        Binding(get: { shareFace }, set: { shareFontFaceRaw = $0.rawValue })
    }

    private var composed: String { Self.composedText(name) }

    private var composedAttributedText: AttributedString {
        ShareAyahSheet.allahHighlightedSwiftUIText(
            composed,
            baseColor: .white,
            enabled: settings.highlightAllahNamesIslam
        )
    }

    /// The unified composition, honoring the persisted include toggles. Static and defaults-driven
    /// for the same reason `HadithShareSheet.composedText` is: anything else that wants "the name as
    /// the reader has chosen to share it" gets the identical string without building the sheet.
    static func composedText(_ name: NameOfAllah) -> String {
        let defaults = UserDefaults.standard
        /// An absent key means "never touched", which takes the sheet's own default - so the two
        /// can never disagree about what a fresh install shares.
        func flag(_ key: String, default fallback: Bool) -> Bool {
            defaults.object(forKey: key) == nil ? fallback : defaults.bool(forKey: key)
        }

        var parts: [String] = []
        if flag("shareNameArabic", default: true) {
            parts.append(name.name.removeDiacriticsFromLastLetter())
        }
        if flag("shareNameTransliteration", default: true) {
            parts.append(name.transliteration)
        }
        if flag("shareNameTranslation", default: true) {
            parts.append(name.meaning)
        }
        if flag("shareNameOtherNames", default: false), !name.otherNames.isEmpty {
            parts.append("Other Names: \(name.otherNames.joined(separator: ", "))")
        }
        // The First Found entries are Quran references; apps without the Quran have none.
        #if HAS_QURAN
        if flag("shareNameFirstFound", default: false) {
            parts.append("First Found: \(name.firstFoundShort)")
        }
        #endif
        if flag("shareNameDescription", default: false) {
            parts.append(name.desc)
        }
        return parts.joined(separator: "\n\n")
    }

    /// How many parts are on - the last one standing can't be turned off (an empty share is nothing).
    private var enabledPartCount: Int {
        var flags = [includeArabic, includeTransliteration, includeTranslation,
                     includeOtherNames && !name.otherNames.isEmpty,
                     includeDescription]
        #if HAS_QURAN
        flags.append(includeFirstFound)
        #endif
        return flags.filter { $0 }.count
    }

    var body: some View {
        NavigationView {
            VStack {
                Spacer()

                preview

                Spacer()

                ScrollView {
                    VStack(spacing: 2) {
                        toggle("Arabic", $includeArabic, disabled: includeArabic && enabledPartCount == 1)
                        toggle("Transliteration", $includeTransliteration, disabled: includeTransliteration && enabledPartCount == 1)
                        toggle("Translation", $includeTranslation, disabled: includeTranslation && enabledPartCount == 1)

                        if !name.otherNames.isEmpty {
                            toggle("Other Names", $includeOtherNames, disabled: includeOtherNames && enabledPartCount == 1)
                        }

                        #if HAS_QURAN
                        toggle("First Found", $includeFirstFound, disabled: includeFirstFound && enabledPartCount == 1)
                        #endif

                        toggle("Description", $includeDescription, disabled: includeDescription && enabledPartCount == 1)

                        // Image mode only: the face is a property of the drawn card, not of the text.
                        if includeArabic, actionMode == .image {
                            Picker("Arabic Font", selection: shareFaceBinding) {
                                Text("Uthmani").tag(Settings.IslamArabicFace.uthmani)
                                Text("IndoPak").tag(Settings.IslamArabicFace.indopak)
                                Text("Hijazi").tag(Settings.IslamArabicFace.hijazi)
                                Text("Kufi").tag(Settings.IslamArabicFace.kufi)
                                Text("Basic").tag(Settings.IslamArabicFace.basic)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 2)
                        }
                    }
                }
                .frame(maxHeight: 200)

                Picker("Action Mode", selection: $actionMode) {
                    Text("Image").tag(ActionMode.image)
                    Text("Text").tag(ActionMode.text)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 4)

                HStack(spacing: 12) {
                    actionButton("Copy") { performCopyOrGenerate() }
                    actionButton("Share", isAnimating: isSharing) { performShareOrGenerate() }
                }
                .padding(.horizontal, 16)
                .padding(.bottom)
                .sheet(isPresented: $showingActivityView) {
                    if #available(iOS 16.0, *) {
                        ActivityView(activityItems: activityItems, onComplete: { didCompleteShare = $0 })
                            .presentationDetents([.medium])
                    } else {
                        ActivityView(activityItems: activityItems, onComplete: { didCompleteShare = $0 })
                    }
                }
            }
            .navigationTitle(name.transliteration)
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accentWashedBackground()
        }
        .navigationViewStyle(.stack)
        .accentColor(settings.accentColor.color)
        .onAppear {
            guard !didInit else { return }
            didInit = true

            withAnimation {
                actionMode = ActionMode(rawValue: storedActionModeRaw) ?? .image
                generatePreviewImage()
            }

            DispatchQueue.main.async { didFinishInitialSetup = true }
        }
        // Every trigger gated on didFinishInitialSetup, the ayah sheet's rule: onAppear already
        // renders once, and the state seeding used to echo through as a second, discarded render.
        .onChange(of: includeArabic) { _ in regenerate() }
        .onChange(of: includeTransliteration) { _ in regenerate() }
        .onChange(of: includeTranslation) { _ in regenerate() }
        .onChange(of: includeOtherNames) { _ in regenerate() }
        .onChange(of: includeFirstFound) { _ in regenerate() }
        .onChange(of: includeDescription) { _ in regenerate() }
        .onChange(of: shareFontFaceRaw) { _ in regenerate() }
        .onChange(of: actionMode) { newValue in
            if didFinishInitialSetup { settings.hapticFeedback() }
            storedActionModeRaw = newValue.rawValue
            if newValue == .image && generatedImage == nil { generatePreviewImage() }
        }
        .onChange(of: showingActivityView) { open in
            // Close the whole sheet only after a COMPLETED share. On cancel, stay put with the
            // configured preview intact.
            if !open && didCompleteShare {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }

    @ViewBuilder
    private var preview: some View {
        ZStack {
            if actionMode == .image {
                if let img = generatedImage {
                    // The PREVIOUS image stays on screen while a regeneration runs, dimmed slightly
                    // so the swap reads as an update, not a teardown - the ayah sheet's fix for the
                    // jump-and-reflow on every toggle.
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(24)
                        .padding(.horizontal, 16)
                        .contextMenu { copyMenu(image: img) }
                        .opacity(isGeneratingImage ? 0.6 : 1)
                        .animation(.easeInOut(duration: 0.15), value: isGeneratingImage)
                        .transition(.opacity)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                }
            } else {
                // The ayah sheet's dark text card. It SCROLLS like the hadith one: a name's
                // description runs well past an ayah's length.
                ScrollView {
                    Text(composedAttributedText)
                        .font(.body)
                        .textSelection(.enabled)
                        .lineLimit(nil)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .background(Color.black)
                .cornerRadius(24)
                .padding(.horizontal, 16)
                .contextMenu { copyMenu(image: generatedImage) }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .scaleEffect(isSharing ? 0.98 : 1)
        .animation(.easeInOut, value: actionMode)
        .animation(.easeInOut, value: isSharing)
    }

    private func regenerate() {
        guard didFinishInitialSetup else { return }
        settings.hapticFeedback()
        generatePreviewImage()
    }

    @ViewBuilder
    private func toggle(_ title: LocalizedStringKey, _ binding: Binding<Bool>, disabled: Bool) -> some View {
        Toggle(isOn: binding.animation(.easeInOut)) {
            Text(title).foregroundColor(.primary)
        }
        .tint(settings.accentColor.color)
        .disabled(disabled)
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
    }

    private func actionButton(_ title: String, isAnimating: Bool = false, action: @escaping () -> Void) -> some View {
        Button {
            settings.hapticFeedback()
            action()
        } label: {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.primary)
                .scaleEffect(isAnimating ? 0.96 : 1)
        }
        .conditionalGlassEffect(useColor: 0.25)
    }

    private func copyMenu(image: UIImage?) -> some View {
        Group {
            Text("Copy")
                .foregroundStyle(.secondary)

            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = composed
            } label: { Label("Copy Text", systemImage: "doc.on.doc") }

            if let image {
                Button {
                    settings.hapticFeedback()
                    UIPasteboard.general.image = image
                } label: { Label("Copy Image", systemImage: "doc.on.doc.fill") }
            }
        }
    }

    private func animateShare(completion: @escaping () -> Void) {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) { isSharing = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            completion()
            withAnimation(.easeOut(duration: 0.18)) { isSharing = false }
        }
    }

    private func presentShareSheet(with items: [Any]) {
        animateShare {
            didCompleteShare = false
            activityItems = items
            showingActivityView = true
        }
    }

    private func performCopyOrGenerate() {
        switch actionMode {
        case .text:
            UIPasteboard.general.string = composed
            presentationMode.wrappedValue.dismiss()
        case .image:
            if let img = generatedImage {
                UIPasteboard.general.image = img
                presentationMode.wrappedValue.dismiss()
            } else {
                generatePreviewImage { img in
                    UIPasteboard.general.image = img
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }

    private func performShareOrGenerate() {
        switch actionMode {
        case .text:
            presentShareSheet(with: [composed])
        case .image:
            if let img = generatedImage {
                presentShareSheet(with: [img])
            } else {
                generatePreviewImage { img in presentShareSheet(with: [img]) }
            }
        }
    }

    // MARK: Card rendering

    /// Everything the card is drawn from, captured on the main actor before the render hops queues -
    /// the ayah sheet's rule: the render queue must never read view state a later toggle could be
    /// rewriting (and `UIScreen.main` is main-thread-only).
    private struct RenderInput {
        var arabic: String
        var transliteration: String
        var translation: String
        var otherNames: String
        var firstFound: String
        var desc: String
        var arabicFontName: String
        var accent: UIColor
        var highlightAllahNames: Bool
        var screenWidth: CGFloat
    }

    private func renderInput() -> RenderInput {
        let arabicText = includeArabic ? name.name.removeDiacriticsFromLastLetter() : ""
        // "Basic" is a sentinel with no real UIFont and lands on the rounded-system fallback in
        // `drawImage`, the hadith card's rule.
        let usesCustomFace = shareFace != .basic
        var firstFound = ""
        #if HAS_QURAN
        if includeFirstFound { firstFound = name.firstFoundShort }
        #endif
        return RenderInput(
            arabic: arabicText,
            transliteration: includeTransliteration ? name.transliteration : "",
            translation: includeTranslation ? name.meaning : "",
            otherNames: includeOtherNames && !name.otherNames.isEmpty
                ? name.otherNames.joined(separator: ", ") : "",
            firstFound: firstFound,
            desc: includeDescription ? name.desc : "",
            arabicFontName: usesCustomFace ? shareFace.fontName : Settings.systemArabicFontName,
            accent: settings.accentColor.color.uiColor,
            highlightAllahNames: settings.highlightAllahNamesIslam,
            // Clamped to a phone-like measure, exactly like the ayah card: on iPad/Mac the SCREEN is
            // 800-1400pt wide even when the window is narrow, and a card that wide reads terribly.
            screenWidth: min(UIScreen.main.bounds.width, ShareAyahRender.maxImageWidth)
        )
    }

    /// Renders off the main thread on a serial queue, ShareAyah's way, so toggling never hitches.
    private func generatePreviewImage(completion: @escaping (UIImage) -> Void = { _ in }) {
        let input = renderInput()
        let generationID = imageGenerationID + 1
        imageGenerationID = generationID
        // The previous image deliberately STAYS visible (dimmed via isGeneratingImage) while this
        // render runs - nilling it here would collapse the preview and make the sheet jump.
        isGeneratingImage = true
        Self.shareImageQueue.async {
            // Superseded before we started drawing? Skip the render rather than draw and discard.
            // main.sync is deadlock-free here: nothing on the main thread blocks on this queue.
            let stillCurrent = DispatchQueue.main.sync { self.imageGenerationID == generationID }
            guard stillCurrent else { return }

            let img: UIImage = autoreleasepool { Self.drawImage(input) }
            DispatchQueue.main.async {
                guard self.imageGenerationID == generationID else { return }
                // Scoped to the image swap only - an unscoped withAnimation animates the whole
                // sheet's layout and amplifies the jump.
                withAnimation(.easeInOut(duration: 0.15)) {
                    self.generatedImage = img
                    self.isGeneratingImage = false
                }
                if self.actionMode == .image { self.activityItems = [img] }
                completion(img)
            }
        }
    }

    /// The share card, drawn with `HadithShareSheet.drawImage`'s layout: one attributed string
    /// composed block by block, measured against a screen-derived canvas, drawn on a black card at
    /// corner radius 20 with the logo + app-name watermark centered at the foot.
    ///
    /// The Name's own grammar, unlike the ayah and hadith cards: the Arabic is the HERO, centered
    /// and large rather than right-aligned body text, because a Name is one or two words and reads
    /// as a title. Everything under it is supporting text, the way the fullscreen focus overlay
    /// already presents a Name.
    private static func drawImage(_ input: RenderInput) -> UIImage {
        // Rounded, to match the app's system-font design (the `fontDesign` environment does not
        // reach this UIKit-drawn image, so the design is asked for explicitly).
        let bodyFont = UIFont.roundedSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize)
        // The hero: far larger than the ayah card's 1.15x, because it is a title, not a passage.
        let heroSize = bodyFont.pointSize * 2.6
        let heroFont = UIFont(name: input.arabicFontName, size: heroSize)
            ?? UIFont.roundedSystemFont(ofSize: heroSize)
        let titleFont = UIFont.roundedSystemFont(ofSize: bodyFont.pointSize * 1.25, weight: .semibold)
        let captionFont = UIFont.roundedSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .caption2).pointSize)

        let textColor = UIColor.white
        // The ayah card's secondary caption color, RESOLVED for a dark card: this runs off the main
        // thread, where `UITraitCollection.current` is unspecified, and an unresolved secondaryLabel
        // can come back as near-black on the black card.
        let secondaryColor = UIColor.secondaryLabel.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        let accent = input.accent

        // --- Layout constants (ShareAyah's, unchanged)
        let padding: CGFloat = 20, spacing: CGFloat = 8, extraSpacing: CGFloat = 30
        let iPhoneCanvasCap: CGFloat = 500
        let deviceWidth = input.screenWidth - 50
        let maxWidth = min(deviceWidth, iPhoneCanvasCap)

        let cent = NSMutableParagraphStyle(); cent.alignment = .center
        let left = NSMutableParagraphStyle(); left.alignment = .left

        let heroAttr  = [NSAttributedString.Key.font: heroFont, .foregroundColor: accent, .paragraphStyle: cent] as [NSAttributedString.Key: Any]
        let titleAttr = [NSAttributedString.Key.font: titleFont, .foregroundColor: textColor, .paragraphStyle: cent] as [NSAttributedString.Key: Any]
        let subAttr   = [NSAttributedString.Key.font: bodyFont, .foregroundColor: secondaryColor, .paragraphStyle: cent] as [NSAttributedString.Key: Any]
        let bodyAttr  = [NSAttributedString.Key.font: bodyFont, .foregroundColor: textColor, .paragraphStyle: left] as [NSAttributedString.Key: Any]
        let capAttr   = [NSAttributedString.Key.font: captionFont, .foregroundColor: secondaryColor, .paragraphStyle: left] as [NSAttributedString.Key: Any]
        let capAccent = [NSAttributedString.Key.font: captionFont, .foregroundColor: accent, .paragraphStyle: left] as [NSAttributedString.Key: Any]
        let centAccent = [NSAttributedString.Key.font: bodyFont, .foregroundColor: accent, .paragraphStyle: cent] as [NSAttributedString.Key: Any]

        let text = NSMutableAttributedString()
        func append(_ str: String, _ attrs: [NSAttributedString.Key: Any], highlightAllah: Bool = true) {
            let piece = NSMutableAttributedString(string: str, attributes: attrs)
            // The Share Ayah card's Allah-name reddening - the live rows highlight the names, so the
            // shared image must too.
            ShareAyahSheet.applyAllahHighlight(
                to: piece,
                source: str,
                enabled: highlightAllah && input.highlightAllahNames
            )
            text.append(piece)
        }
        func sepIfNeeded(_ gap: String = "\n\n") {
            if text.length > 0 { append(gap, bodyAttr, highlightAllah: false) }
        }

        if !input.arabic.isEmpty {
            append(input.arabic, heroAttr)
        }
        if !input.transliteration.isEmpty {
            // A single break under the hero: the transliteration names the glyph above it.
            sepIfNeeded("\n")
            append(input.transliteration, titleAttr, highlightAllah: false)
        }
        if !input.translation.isEmpty {
            sepIfNeeded("\n")
            append(input.translation, subAttr)
        }
        if !input.otherNames.isEmpty {
            sepIfNeeded()
            append("Other Names: ", capAccent, highlightAllah: false)
            append(input.otherNames, capAttr)
        }
        if !input.firstFound.isEmpty {
            sepIfNeeded(input.otherNames.isEmpty ? "\n\n" : "\n")
            append("First Found: ", capAccent, highlightAllah: false)
            append(input.firstFound, capAttr, highlightAllah: false)
        }
        if !input.desc.isEmpty {
            sepIfNeeded()
            append(input.desc, bodyAttr)
        }

        guard text.length > 0 else { return UIImage() }

        // --- Watermark (the ayah card's, unchanged): the app logo beside the full app name, accent.
        let wmText = NSAttributedString(string: AppIdentifiers.appFullName, attributes: centAccent)
        var logo = UIImage(named: AppIdentifiers.appName)

        var wmTextSize = wmText.size()
        var logoSize = CGSize(width: wmTextSize.height, height: wmTextSize.height)
        let availWidth = maxWidth - 2*padding
        let desiredWmW = logoSize.width + spacing + wmTextSize.width

        if desiredWmW > availWidth {
            let scale = availWidth / desiredWmW
            wmTextSize = CGSize(width: wmTextSize.width*scale, height: wmTextSize.height*scale)
            logoSize = CGSize(width: logoSize.width*scale, height: logoSize.height*scale)
            if let img = logo {
                let r = UIGraphicsImageRenderer(size: logoSize)
                logo = r.image { _ in img.draw(in: CGRect(origin: .zero, size: logoSize)) }
            }
        }

        let constraint = CGSize(width: availWidth, height: .greatestFiniteMagnitude)
        var textRect = text.boundingRect(with: constraint, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).integral
        textRect.size.width  += 2*padding
        textRect.size.height += logoSize.height + extraSpacing + 25

        let canvas = CGRect(origin: .zero, size: CGSize(width: maxWidth, height: textRect.height))

        let r1 = UIGraphicsImageRenderer(size: canvas.size)
        let blackCard = r1.image { ctx in
            UIColor.black.setFill(); ctx.fill(canvas)
            text.draw(in: CGRect(x: padding, y: padding, width: canvas.width - 2*padding, height: canvas.height))

            let wmY = canvas.height - logoSize.height - extraSpacing/2
            let wmX = (canvas.width - (logoSize.width + spacing + wmTextSize.width)) / 2
            if let logo = logo {
                let rect = CGRect(origin: CGPoint(x: wmX, y: wmY), size: logoSize)
                ctx.cgContext.addPath(UIBezierPath(roundedRect: rect, cornerRadius: logoSize.height*0.25).cgPath)
                ctx.cgContext.clip(); logo.draw(in: rect); ctx.cgContext.resetClip()
            }
            wmText.draw(in: CGRect(x: wmX + logoSize.width + spacing, y: wmY, width: wmTextSize.width, height: wmTextSize.height))
        }
        return UIGraphicsImageRenderer(size: canvas.size).image { _ in
            UIBezierPath(roundedRect: canvas, cornerRadius: 20).addClip()
            blackCard.draw(at: .zero)
        }
    }
}
#endif
