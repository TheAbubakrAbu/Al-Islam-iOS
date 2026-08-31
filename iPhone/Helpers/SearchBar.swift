#if os(iOS)
import SwiftUI
import UIKit

/// The app's search field: the SYSTEM search field, just shorter (user rule: "keep it the exact same
/// as it was before, just smaller in height"). `UISearchTextField` is the very view UISearchBar draws
/// its field with - same background, magnifier, placeholder, clear button, fonts - but as a plain
/// UITextField subclass it can be laid out at ANY height, while UISearchBar proper refuses anything
/// under ~48pt (it keeps painting a 48pt field inside the smaller slot). So this hosts the field
/// directly at 50pt (settled after rounds at 38, 42, and 46 - Abu's final pick)
/// and adds the Cancel button UISearchBar used to own.
///
/// Same API as ever: a text binding, a focus-request token, a placeholder, the search-key callback,
/// and focus-change notifications.
struct SearchBar: View {
    @Binding var text: String

    /// Bump this to put the keyboard in the search bar. A token rather than a `Bool` so the same request can be
    /// made twice in a row (search, dismiss the keyboard, search again) and still be seen as a new one.
    var focusRequestID: Int = 0
    /// Field placeholder. Screens that search one specific thing say so ("Search tafsir"),
    /// which is what the `.searchable` prompts used to carry.
    var placeholder: String = "Search"
    var onSearchButtonClicked: (() -> Void)?
    var onFocusChanged: ((Bool) -> Void)?

    @ObservedObject private var settings = Settings.shared
    @State private var isEditing = false
    /// Bumped by Cancel: the field clears and resigns on the next update (the representable can't be
    /// reached imperatively from here).
    @State private var cancelToken = 0

    init(
        text: Binding<String>,
        focusRequestID: Int = 0,
        placeholder: String = "Search",
        onSearchButtonClicked: (() -> Void)? = nil,
        onFocusChanged: ((Bool) -> Void)? = nil
    ) {
        _text = text
        self.focusRequestID = focusRequestID
        self.placeholder = placeholder
        self.onSearchButtonClicked = onSearchButtonClicked
        self.onFocusChanged = onFocusChanged
    }

    var body: some View {
        HStack(spacing: 8) {
            SystemSearchField(
                text: $text,
                focusRequestID: focusRequestID,
                cancelToken: cancelToken,
                placeholder: placeholder,
                onSearchButtonClicked: onSearchButtonClicked,
                onFocusChanged: { focused in
                    withAnimation(.easeInOut(duration: 0.2)) { isEditing = focused }
                    onFocusChanged?(focused)
                }
            )
            .frame(height: 50)

            if isEditing {
                // The app's circle-glass ✕, not a text "Cancel" (user rule: the word read as dated
                // next to the new field) - sized to the field so the pair reads as one bar.
                Button {
                    settings.hapticFeedback()
                    text = ""
                    cancelToken += 1
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.primary)
                        .frame(width: 50, height: 50)
                        .contentShape(Circle())
                        .conditionalGlassEffect(circle: true)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cancel search")
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isEditing)
    }
}

/// `UISearchTextField`, with a trailing gap wide enough for right-to-left text.
///
/// MEASURED, not guessed: in a 296pt-wide field the stock `textRect` returns x=37.67 w=251.33, so
/// the leading side gets 37.7pt (the magnifier and its spacing) and the trailing side gets 7pt.
/// That asymmetry is invisible for Latin text, which is leading-aligned - all the spare room piles
/// up on the trailing side where nothing is drawn. Arabic aligns to the TRAILING edge, so an
/// unfocused Arabic query sat 7pt from a 14pt-radius rounded corner and read as though the word had
/// been cut off (Abu's report: "looks chopped when the searchbar is not selected and there is
/// arabic"). Focused it looked right, because the clear button pushes the text further in.
///
/// So: widen the resting gap. `textRect` is the unfocused geometry, so the editing layout - which
/// was never the problem - is left exactly as it was.
private final class PaddedSearchTextField: UISearchTextField {
    /// 7pt + 10 = 17pt. Not the full 37.7pt of the leading side: with no button drawn there, that
    /// much empty room reads as a hole rather than as padding.
    private static let extraTrailingGap: CGFloat = 10

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.textRect(forBounds: bounds)
        // Trailing, not "right": mirrored for a right-to-left INTERFACE, which is a different thing
        // from right-to-left text inside a left-to-right interface.
        let isRTL = effectiveUserInterfaceLayoutDirection == .rightToLeft
        return rect.inset(by: UIEdgeInsets(top: 0,
                                           left: isRTL ? Self.extraTrailingGap : 0,
                                           bottom: 0,
                                           right: isRTL ? 0 : Self.extraTrailingGap))
    }
}

/// The UIKit half: `UISearchTextField` with the old UISearchBar wrapper's text-sync guards intact.
private struct SystemSearchField: UIViewRepresentable {
    #if DEBUG
    /// "-searchPasteProbe": headless reproduction of paste-into-search (crash report 2026-08-18) -
    /// the simulator has no tap/key injection, and only the REAL `paste(_:)` path exercises the
    /// keyboard's inline-candidate machinery. The first field mounted claims the probe; seed the sim
    /// pasteboard with `simctl pbcopy` before launching.
    nonisolated(unsafe) private static var didSchedulePasteProbe = false
    #endif
    @Binding var text: String
    var focusRequestID: Int
    var cancelToken: Int
    var placeholder: String
    var onSearchButtonClicked: (() -> Void)?
    var onFocusChanged: ((Bool) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onSearchButtonClicked: onSearchButtonClicked, onFocusChanged: onFocusChanged)
    }

    func makeUIView(context: Context) -> UISearchTextField {
        let field = PaddedSearchTextField()
        field.placeholder = placeholder
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.spellCheckingType = .no
        if #available(iOS 17.0, *) {
            // A search field must not run the keyboard's inline predictions (UISearchBar's own field
            // never did): pasting Quranic Arabic - dagger alif, Uthmani sukoon - into this bare field
            // trapped inside UIKit's UIKeyboardInlineCandidateStorage on iOS 26 (EXC_BREAKPOINT,
            // 2026-08-18 report). Off = that machinery never engages.
            field.inlinePredictionType = .no
        }
        field.returnKeyType = .search
        field.clearButtonMode = .whileEditing
        if #unavailable(iOS 26.0) {
            // Pre-Liquid-Glass the bare field draws only its translucent gray fill, and floating over
            // list content it read as "way too transparent" (user report). The old UISearchBar layered
            // that same fill over an opaque bar; an opaque backing under the field restores that look.
            // iOS 26 draws the field as glass and needs nothing.
            field.backgroundColor = .secondarySystemBackground
            field.layer.cornerRadius = 14
            field.clipsToBounds = true
        }
        field.delegate = context.coordinator
        field.addTarget(context.coordinator, action: #selector(Coordinator.editingChanged(_:)), for: .editingChanged)
        field.addTarget(context.coordinator, action: #selector(Coordinator.editingBegan), for: .editingDidBegin)
        field.addTarget(context.coordinator, action: #selector(Coordinator.editingEnded), for: .editingDidEnd)
        // Don't let the field's intrinsic width fight the SwiftUI frame.
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        #if DEBUG
        // The payload rides in "-searchPasteText <string>" and is planted on the pasteboard IN-PROCESS:
        // a same-app paste skips the iOS cross-app paste permission dialog, which is untappable here.
        if ProcessInfo.processInfo.arguments.contains("-searchPasteProbe"), !Self.didSchedulePasteProbe {
            Self.didSchedulePasteProbe = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak field] in
                let args = ProcessInfo.processInfo.arguments
                if let i = args.firstIndex(of: "-searchPasteText"), args.indices.contains(i + 1) {
                    let payload = args[i + 1]
                    if args.contains("-searchPasteHTML") {
                        // Mimic a copy from a browser/chat: the pasteboard carries RICH flavors, and the
                        // paste converts through attributed text - a different UIKit path than plain.
                        UIPasteboard.general.items = [[
                            "public.html": "<html><body><b>\(payload)</b></body></html>",
                            "public.utf8-plain-text": payload,
                        ]]
                    } else {
                        UIPasteboard.general.string = payload
                    }
                }
                field?.becomeFirstResponder()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    field?.paste(nil)
                }
            }
        }
        #endif
        return field
    }

    func updateUIView(_ field: UISearchTextField, context: Context) {
        context.coordinator.onSearchButtonClicked = onSearchButtonClicked
        context.coordinator.onFocusChanged = onFocusChanged

        // Push SwiftUI's text into UIKit ONLY when it's a value the user didn't just type (a programmatic
        // set: the global-search handoff, a cleared query). While the field is being edited, UIKit is the
        // source of truth and SwiftUI runs a beat behind - fast typing delivered STALE values here, and
        // writing them back into the actively edited field corrupted its text system mid-composition.
        // That was the old type-delete-retype search crash; the guard carries over from the UISearchBar
        // wrapper verbatim.
        if field.text != text {
            // Also never write while a composition/candidate session is open (`markedTextRange`):
            // stomping marked text mid-session is the exact class of corruption behind both the old
            // type-delete-retype crash and the 2026-08-18 paste trap in UIKit's keyboard code.
            if (!field.isFirstResponder || !context.coordinator.recentlySentTexts.contains(text)),
               field.markedTextRange == nil {
                field.text = text
            }
        }

        // A new focus request (0 is "never asked"). Deferred: this runs inside a SwiftUI update, and taking
        // first responder synchronously from there fights the in-flight navigation that usually caused the ask.
        if focusRequestID > 0, focusRequestID != context.coordinator.lastFocusRequestID {
            context.coordinator.lastFocusRequestID = focusRequestID
            DispatchQueue.main.async {
                guard !field.isFirstResponder else { return }
                field.becomeFirstResponder()
            }
        }

        // Cancel: clear and drop the keyboard - what UISearchBar's own Cancel did.
        if cancelToken != context.coordinator.lastCancelToken {
            context.coordinator.lastCancelToken = cancelToken
            context.coordinator.rememberSentText("")
            field.text = ""
            DispatchQueue.main.async { field.resignFirstResponder() }
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String

        var onSearchButtonClicked: (() -> Void)?
        var onFocusChanged: ((Bool) -> Void)?
        /// The last focus request honoured, so a re-render can't keep re-taking first responder.
        var lastFocusRequestID = 0
        var lastCancelToken = 0
        /// The last few values `editingChanged` pushed INTO SwiftUI. When one of them comes back through
        /// `updateUIView` it's an echo of the user's own typing (possibly stale by a beat), not a
        /// programmatic set - see the guard there.
        private(set) var recentlySentTexts: [String] = []

        init(text: Binding<String>, onSearchButtonClicked: (() -> Void)?, onFocusChanged: ((Bool) -> Void)?) {
            _text = text
            self.onSearchButtonClicked = onSearchButtonClicked
            self.onFocusChanged = onFocusChanged
        }

        func rememberSentText(_ value: String) {
            recentlySentTexts.append(value)
            if recentlySentTexts.count > 8 {
                recentlySentTexts.removeFirst(recentlySentTexts.count - 8)
            }
        }

        @objc func editingChanged(_ field: UITextField) {
            let value = field.text ?? ""
            rememberSentText(value)
            text = value
        }

        @objc func editingBegan() { onFocusChanged?(true) }
        @objc func editingEnded() { onFocusChanged?(false) }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            text = textField.text ?? ""
            onSearchButtonClicked?()
            return true
        }
    }
}

#Preview {
    SearchBar(text: .constant(""))
}
#endif
