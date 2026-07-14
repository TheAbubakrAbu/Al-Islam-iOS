#if os(iOS)
import SwiftUI

struct SearchBar: View {
    @Binding var text: String

    /// Bump this to put the keyboard in the search bar. A token rather than a `Bool` so the same request can be
    /// made twice in a row (search, dismiss the keyboard, search again) and still be seen as a new one.
    var focusRequestID: Int = 0
    var onSearchButtonClicked: (() -> Void)?
    var onFocusChanged: ((Bool) -> Void)?

    init(
        text: Binding<String>,
        focusRequestID: Int = 0,
        onSearchButtonClicked: (() -> Void)? = nil,
        onFocusChanged: ((Bool) -> Void)? = nil
    ) {
        _text = text
        self.focusRequestID = focusRequestID
        self.onSearchButtonClicked = onSearchButtonClicked
        self.onFocusChanged = onFocusChanged
    }

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                SearchBarUIKit(
                    text: $text,
                    focusRequestID: focusRequestID,
                    onSearchButtonClicked: onSearchButtonClicked,
                    onFocusChanged: onFocusChanged
                )
            } else {
                SearchBarUIKit(
                    text: $text,
                    focusRequestID: focusRequestID,
                    onSearchButtonClicked: onSearchButtonClicked,
                    onFocusChanged: onFocusChanged
                )
                .background {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 3)
                }
                .padding(.horizontal, 5)
            }
        }
    }
}

struct SearchBarUIKit: UIViewRepresentable {
    @Binding var text: String

    var focusRequestID: Int = 0
    var onSearchButtonClicked: (() -> Void)?
    var onFocusChanged: ((Bool) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(
            text: $text,
            onSearchButtonClicked: onSearchButtonClicked,
            onFocusChanged: onFocusChanged
        )
    }

    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        searchBar.placeholder = "Search"
        searchBar.autocorrectionType = .no
        searchBar.autocapitalizationType = .none
        searchBar.returnKeyType = .search
        searchBar.searchBarStyle = .minimal

        configure(searchTextField: searchBar.searchTextField, coordinator: context.coordinator)
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }

        uiView.searchTextField.rightViewMode = .always
        ClearButtonContainer.updateVisibility(
            in: uiView.searchTextField.rightView,
            isVisible: !text.isEmpty
        )
        context.coordinator.onSearchButtonClicked = onSearchButtonClicked
        context.coordinator.onFocusChanged = onFocusChanged

        // A new focus request (0 is "never asked"). Deferred: this runs inside a SwiftUI update, and taking
        // first responder synchronously from there fights the in-flight navigation that usually caused the ask.
        if focusRequestID > 0, focusRequestID != context.coordinator.lastFocusRequestID {
            context.coordinator.lastFocusRequestID = focusRequestID
            DispatchQueue.main.async {
                guard !uiView.isFirstResponder else { return }
                uiView.becomeFirstResponder()
            }
        }
    }

    private func configure(searchTextField: UITextField, coordinator: Coordinator) {
        searchTextField.backgroundColor = .clear
        searchTextField.layer.cornerRadius = 24
        searchTextField.layer.masksToBounds = true
        searchTextField.font = .systemFont(ofSize: 16)
        searchTextField.clearButtonMode = .never
        searchTextField.rightView = ClearButtonContainer.make(for: coordinator)
        searchTextField.rightViewMode = .always
        ClearButtonContainer.updateVisibility(in: searchTextField.rightView, isVisible: false)
    }

    final class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String

        var onSearchButtonClicked: (() -> Void)?
        var onFocusChanged: ((Bool) -> Void)?
        /// The last focus request honoured, so a re-render can't keep re-taking first responder.
        var lastFocusRequestID = 0

        init(
            text: Binding<String>,
            onSearchButtonClicked: (() -> Void)?,
            onFocusChanged: ((Bool) -> Void)?
        ) {
            _text = text
            self.onSearchButtonClicked = onSearchButtonClicked
            self.onFocusChanged = onFocusChanged
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }

        func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
            searchBar.showsCancelButton = true
            onFocusChanged?(true)
        }

        func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
            searchBar.showsCancelButton = false
            onFocusChanged?(false)
        }

        func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            searchBar.showsCancelButton = false
            searchBar.text = ""
            searchBar.resignFirstResponder()

            text = ""
            onFocusChanged?(false)
        }

        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
            text = searchBar.text ?? ""
            onSearchButtonClicked?()
        }

        @objc func clearSearchText(_ sender: UIButton) {
            guard let textField = resolvedTextField(from: sender) else {
                text = ""
                return
            }

            textField.text = ""
            text = ""
            textField.sendActions(for: .editingChanged)
        }

        private func resolvedTextField(from sender: UIButton) -> UITextField? {
            sender.superview?.superview as? UITextField ?? sender.superview as? UITextField
        }
    }
    
    private enum ClearButtonContainer {
        static func make(for coordinator: SearchBarUIKit.Coordinator) -> UIView {
            let leadingInset: CGFloat = 4
            let container = UIView(frame: CGRect(x: 0, y: 0, width: 24 + leadingInset, height: 20))

            let button = UIButton(type: .system)
            button.frame = CGRect(x: leadingInset, y: 0, width: 20, height: 20)
            button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            button.tintColor = .secondaryLabel
            button.addTarget(coordinator, action: #selector(SearchBarUIKit.Coordinator.clearSearchText(_:)), for: .touchUpInside)
            button.tag = 999

            container.addSubview(button)
            return container
        }

        static func updateVisibility(in rightView: UIView?, isVisible: Bool) {
            guard let button = rightView?.viewWithTag(999) as? UIButton else { return }
            button.isHidden = !isVisible
            button.isUserInteractionEnabled = isVisible
        }
    }
}

#Preview {
    SearchBar(text: .constant(""))
}
#endif
