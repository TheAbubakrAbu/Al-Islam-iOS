#if os(iOS)
import SwiftUI

// MARK: - Fullscreen focus overlay

/// One thing shown as large as the screen allows: an Arabic letter, a surah name, or one of the 99 Names.
/// `arabic` is the hero — everything else is supporting text under it.
struct FocusItem: Identifiable, Equatable {
    let id: String
    let arabic: String
    let title: String
    let subtitle: String?
    let footnote: String?
    /// Extra Arabic shown small beneath the hero (a letter's three forms, a surah's number, …).
    let secondaryArabic: String?
    let shareLabel: String
    let shareText: String
    /// Letters from non-Arabic scripts (پ, چ, ژ …) aren't in the Quranic font, so they must fall back.
    let allowsQuranicFont: Bool

    init(
        id: String,
        arabic: String,
        title: String,
        subtitle: String? = nil,
        footnote: String? = nil,
        secondaryArabic: String? = nil,
        shareLabel: String,
        shareText: String,
        allowsQuranicFont: Bool = true
    ) {
        self.id = id
        self.arabic = arabic
        self.title = title
        self.subtitle = subtitle
        self.footnote = footnote
        self.secondaryArabic = secondaryArabic
        self.shareLabel = shareLabel
        self.shareText = shareText
        self.allowsQuranicFont = allowsQuranicFont
    }
}

/// Drives the app-wide focus overlay. A singleton rather than an `EnvironmentObject` because the rows that
/// present it (letter rows, name rows, surah context menus) live deep inside lists across three tabs, and
/// threading a binding down to each of them would touch far more code than it's worth.
@MainActor
final class FocusOverlayPresenter: ObservableObject {
    static let shared = FocusOverlayPresenter()
    private init() {}

    @Published var item: FocusItem?

    func present(_ item: FocusItem) {
        withAnimation(.easeInOut(duration: 0.22)) {
            self.item = item
        }
    }

    func dismiss() {
        withAnimation(.easeInOut(duration: 0.2)) {
            item = nil
        }
    }
}

/// Sits at the top of the app's root `ZStack` — not a sheet, so it can cover the tab bar and animate as a
/// plain cross-fade instead of the system's slide-up.
struct FocusOverlayHost: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var presenter = FocusOverlayPresenter.shared

    @State private var showingActivityView = false

    private var useQuranicFont: Bool {
        settings.useFontArabic && (presenter.item?.allowsQuranicFont ?? false)
    }

    var body: some View {
        if let item = presenter.item {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .onTapGesture { presenter.dismiss() }

                VStack(spacing: 0) {
                    closeRow

                    Spacer(minLength: 0)

                    hero(item)

                    Spacer(minLength: 0)

                    caption(item)

                    actions(item)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .transition(.opacity)
            // The hero is already at the largest size the screen fits; letting Dynamic Type scale it again
            // just overflows and clips the glyph.
            .dynamicTypeSize(.large)
            .sheet(isPresented: $showingActivityView) {
                ActivityView(activityItems: [item.shareText])
            }
        }
    }

    private var closeRow: some View {
        HStack {
            Spacer()

            Button {
                settings.hapticFeedback()
                presenter.dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(settings.accentColor.color)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
                    .conditionalGlassEffect(circle: true)
            }
        }
        .padding(.top, 12)
    }

    @ViewBuilder
    private func hero(_ item: FocusItem) -> some View {
        VStack(spacing: 20) {
            Text(item.arabic)
                .font(useQuranicFont ? .custom(settings.fontArabic, size: 130) : .system(size: 110))
                .foregroundStyle(settings.accentColor.color)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.15)
                .lineLimit(3)
                .textSelection(.enabled)

            if let secondaryArabic = item.secondaryArabic {
                Text(secondaryArabic)
                    .font(useQuranicFont ? .custom(settings.fontArabic, size: 34) : .system(size: 30))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 16)
        .conditionalGlassEffect(rectangle: true, useColor: 0.12)
    }

    @ViewBuilder
    private func caption(_ item: FocusItem) -> some View {
        VStack(spacing: 6) {
            Text(item.title)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)

            if let subtitle = item.subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let footnote = item.footnote {
                Text(footnote)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 24)
        .padding(.bottom, 20)
    }

    private func actions(_ item: FocusItem) -> some View {
        HStack(spacing: 12) {
            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = item.arabic
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
                    .conditionalGlassEffect()
            }

            Button {
                settings.hapticFeedback()
                showingActivityView = true
            } label: {
                Label(item.shareLabel, systemImage: "square.and.arrow.up")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
                    .conditionalGlassEffect(useColor: 0.25)
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(settings.accentColor.color)
    }
}

// MARK: - Sharing

/// Wraps `UIActivityViewController` for use from a `.sheet`.
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        vc.modalPresentationStyle = .formSheet
        return vc
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

/// Shares from a context-menu button. A `.sheet` can't be used there — the menu's host row is gone by the
/// time the action runs — so present the activity controller on the topmost view controller instead.
@MainActor
func presentSystemShareSheet(items: [Any]) {
    let scene = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first { $0.activationState == .foregroundActive }

    guard let window = scene?.windows.first(where: \.isKeyWindow) ?? scene?.windows.first,
          var top = window.rootViewController else { return }

    while let presented = top.presentedViewController { top = presented }

    let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
    // iPad requires an anchor or the popover asserts on presentation.
    controller.popoverPresentationController?.sourceView = top.view
    controller.popoverPresentationController?.sourceRect = CGRect(
        x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0
    )
    controller.popoverPresentationController?.permittedArrowDirections = []
    top.present(controller, animated: true)
}

// MARK: - Focus items for each kind of content
//
// Only the kinds this file can build on its own. Content types that live outside Helpers — a Quran `Surah`,
// say — declare their own `FocusItem` factory next to the model, so this file drops into an app that has no
// Quran (Al-Adhan) without dragging the Quran folder along.

extension FocusItem {
    static func letter(_ data: LetterData) -> FocusItem {
        FocusItem(
            id: "letter-\(data.id)",
            arabic: data.letter,
            title: data.transliteration,
            subtitle: data.name,
            footnote: data.weightRule,
            secondaryArabic: data.forms.prefix(3).joined(separator: "   "),
            shareLabel: "Share Letter",
            shareText: """
            \(data.letter) — \(data.transliteration)
            Name: \(data.name)
            Forms: \(data.forms.prefix(3).joined(separator: " "))
            """,
            allowsQuranicFont: !data.isNonArabicScriptLetter
        )
    }

    static func name(_ name: NameOfAllah) -> FocusItem {
        FocusItem(
            id: "name-\(name.number)",
            arabic: name.displayArabicName,
            title: name.transliteration,
            subtitle: name.meaning,
            footnote: "First found: \(name.firstFoundShort)",
            secondaryArabic: name.numberArabic,
            shareLabel: "Share Name",
            shareText: """
            \(name.name.removeDiacriticsFromLastLetter()) — \(name.transliteration)
            Meaning: \(name.meaning)
            First Found: \(name.firstFoundShort)

            \(name.desc)
            """
        )
    }
}
#endif
