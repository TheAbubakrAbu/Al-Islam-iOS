#if os(iOS)
import SwiftUI
import UIKit

/// The app's search field: the SYSTEM search field, just shorter (user rule: "keep it the exact same
/// as it was before, just smaller in height"). `UISearchTextField` is the very view UISearchBar draws
/// its field with - same background, magnifier, placeholder, clear button, fonts - but as a plain
/// UITextField subclass it can be laid out at ANY height, while UISearchBar proper refuses anything
/// under ~48pt (it keeps painting a 48pt field inside the smaller slot). So this hosts the field
/// directly at 42pt and adds the Cancel button UISearchBar used to own.
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
            .frame(height: 42)

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
                        .frame(width: 42, height: 42)
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

/// The UIKit half: `UISearchTextField` with the old UISearchBar wrapper's text-sync guards intact.
private struct SystemSearchField: UIViewRepresentable {
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
        let field = UISearchTextField()
        field.placeholder = placeholder
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.returnKeyType = .search
        field.clearButtonMode = .whileEditing
        field.delegate = context.coordinator
        field.addTarget(context.coordinator, action: #selector(Coordinator.editingChanged(_:)), for: .editingChanged)
        field.addTarget(context.coordinator, action: #selector(Coordinator.editingBegan), for: .editingDidBegin)
        field.addTarget(context.coordinator, action: #selector(Coordinator.editingEnded), for: .editingDidEnd)
        // Don't let the field's intrinsic width fight the SwiftUI frame.
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
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
            if !field.isFirstResponder || !context.coordinator.recentlySentTexts.contains(text) {
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
