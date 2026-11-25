import SwiftUI

// Simple Mode (Docs/Product/Simple Mode Guide.md, agreed with Abu 2026-10-10): one switch, `Settings.simpleMode`,
// that keeps every tab to its essentials. Each site reads the switch itself; this file holds the ⋯ More
// menu that leads every tab's toolbar, and the catalog below. The pure rules (`enum SimpleMode`: the
// tracker gate, the permission dialogs' snooze) live in SettingsAdhan.swift, which the widgets also
// compile.
//
// The More menu is NOT a Simple Mode control any more (Abu, 2026-10-11: "always have the top left
// button just be a more button that contains grid and everything else"). Every tab root (Adhan, Quran,
// Hadith, Islam, Settings) leads with the one ⋯ menu in BOTH modes; it holds the tab's grid or list
// switch and whatever else used to be a toolbar button (reading mode, the planner, the prayer layout,
// the calendars) plus the doors Simple Mode takes off the screen. The gear keeps its trailing slot
// everywhere. Simple Mode still decides what is on the SCREEN below the toolbar.
//
// The rules (the guide has the reasons):
// 1. Hiding never changes what the app does. Every setting a hidden control drives keeps applying.
// 2. A control stays visible while its value is off its default (the sort row, the riwayah picker,
//    the Legend while anything is coloured): a screen must never be left unexplained.
// 3. Anything hidden from a tab stays one tap away: the tab's More menu, or Settings. Dropped outright,
//    as details rather than features: random picks other than Random Surah, Compare Today, the At a
//    Glance figures, the +/- history expanders, section count pills, the mushaf footer's meters and
//    percentages, the Prophet quote card.
// 4. Never hidden: what the user made, how scripture is shown, search, play, the gear, the Settings
//    tab, the prayer bells, and anything opened by a deliberate tap (long-press menus, sheets).
//
// The catalog of trims, each with where its function lives while hidden, is `SimpleTrim` in
// SimpleTrims.swift (Docs/Product/Simple Mode v2 Design.md); the Simple Mode page in Settings lists it live.

#if os(iOS)

/// The ⋯ menu that leads every tab's toolbar, in both modes: the tab's grid or list switch and its
/// other former toolbar buttons, plus the doors Simple Mode takes off the screen (rule 3). The gear
/// never moves into it: it keeps its own trailing slot.
///
/// Its one shortcut is a HOLD (the tab's grid or list switch). Never a double tap: a double-tap shortcut
/// makes every single tap wait out the double-tap interval before the menu opens (`ShortcutMenu`), and
/// that wait is what read as lag on the Quran and Hadith tabs beside the Adhan tab's plain menu (Abu,
/// 2026-10-26: "why so laggy?").
struct TabMoreMenu<Items: View>: View {
    /// Observed for the tint. Not `@Environment(\.appearance)`: this view lives in a toolbar, the
    /// hoisted context where environment objects have failed to arrive in this app before.
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    /// Something the menu started is still working (the Quran tab building its pages for Read as
    /// Pages): the label spins, as the reading-mode button it stands in for did.
    private let isBusy: Bool
    private let items: Items
    private let doubleTap: MenuShortcut?
    private let hold: MenuShortcut?

    init(isBusy: Bool = false, doubleTap: MenuShortcut? = nil, hold: MenuShortcut? = nil,
         @ViewBuilder items: () -> Items) {
        self.isBusy = isBusy
        self.doubleTap = doubleTap
        self.hold = hold
        self.items = items()
    }

    var body: some View {
        ShortcutMenu(doubleTap: doubleTap, hold: hold, shortcutLabelSize: 36) {
            items
        } label: {
            if isBusy {
                ProgressView()
            } else {
                Image(systemName: "ellipsis.circle")
            }
        }
        .accessibilityLabel("More")
        .accessibilityIdentifier("tabMoreMenu")
        .tint(settings.accentColor.accent1)
    }
}

/// One item of a More menu: a plain `Label`, so the menu item's title is what VoiceOver reads.
///
/// Two traps, both met on 2026-10-10. A `square.grid.2x2.fill` icon made the item read as its
/// symbol's name ("Large Grid") instead of "Topics", so no item here uses that symbol. And hiding the
/// icon from accessibility (with an explicit label on the button) emptied EVERY item's label in the
/// system menu, so neither is done.
struct TabMoreMenuItem: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    init(_ title: String, systemImage: String, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
        }
    }
}

/// One door of a tab, drawn as a capsule under the tab's summary (`TabDoorCapsules`).
struct TabDoorCapsule: Identifiable {
    let title: String
    let systemImage: String
    let action: () -> Void

    var id: String { title }

    init(_ title: String, systemImage: String, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }
}

/// A tab's doors as a row of capsules at the foot of its summary (Abu, 2026-11-24: "Instead of hiding
/// explore and history in top left put it in summary underneath the bottom as a bunch of capsule
/// buttons. Do that for all tabs so the top left ellipses has as little options as possible"). The
/// Quran tab's History, Topics and the rest, and the Hadith tab's Topics, Encyclopedia and History. The ⋯
/// menu keeps how the tab is shown (sort, grid) and the tutorial. The Adhan tab has no summary of this kind
/// and kept its two calendars in its menu (Abu: "for Adhan we should probably just keep that the top left").
///
/// ONE line (Abu, the same day: "try to fit it in one row"), centered, in the first form that fits:
/// the capsules as drawn; then names only with less padding (the Quran summary's four with the Qiraat
/// Explorer, which ran one capsule past the edge with nothing to say it was there); then, last, the full
/// line scrolling sideways (five or more, the accessibility text sizes, a long translation). Every form
/// is the same height, so `ViewThatFits` is safe in a List row here: its trap is a TALLER option being
/// measured while the shorter one draws.
///
/// `underTiles`: the row closes a summary whose tiles sit right above it, so it sits closer than the
/// List's default (Abu: "less vertical padding by a little"). He first asked for the separator above it
/// hidden, then, seeing it gone: "maybe there should be a line divider... hmmm", and after a side-by-side
/// of the two (2026-11-24): "lets do divider". So the line stays, with the tighter spacing on both sides
/// of it. A row standing alone keeps the List's own spacing.
///
/// Every capsule is a Button that raises its tab's door through the tab's own guard: never a
/// NavigationLink, since every link in one List row fires on any tap in that row (`one-link-per-list-row`).
struct TabDoorCapsules: View {
    let doors: [TabDoorCapsule]
    var underTiles: Bool = false

    private static let spacing: CGFloat = 7
    /// The List's own leading and trailing row inset here (measured: 16 pt from the card's edge to a
    /// summary tile's), restated because `listRowInsets` sets all four sides at once.
    private static let sideInset: CGFloat = 16

    var body: some View {
        // A real container round the branch, so the row's type stays one view (`OneRow`).
        OneRow {
            if #available(iOS 16.0, *) {
                ViewThatFits(in: .horizontal) {
                    line(compact: false)
                    line(compact: true)
                    scrollingLine
                }
            } else {
                // The siblings' iOS 15 floor.
                scrollingLine
            }
        }
        .frame(maxWidth: .infinity)
        .modifier(UnderTilesRow(isOn: underTiles, sideInset: Self.sideInset))
    }

    private func line(compact: Bool) -> some View {
        HStack(spacing: compact ? 6 : Self.spacing) {
            ForEach(doors) { door in TabDoorCapsuleButton(door: door, compact: compact) }
        }
    }

    /// The line in a sideways scroll that reaches the card's edges, so a capsule slides out under the
    /// card's rim rather than being cut short of it; the first one still starts at the row's inset.
    private var scrollingLine: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            line(compact: false).padding(.horizontal, Self.sideInset)
        }
        .padding(.horizontal, -Self.sideInset)
    }
}

/// The row's cell settings while it closes a summary: less air above and below than the List's default,
/// the separator above it kept, the space on its two sides about even (about 18 pt from the tiles' row
/// above it to the line, 12 from the line to the capsules). A ViewModifier with no branch, so the row
/// stays one view.
private struct UnderTilesRow: ViewModifier {
    let isOn: Bool
    let sideInset: CGFloat

    func body(content: Content) -> some View {
        content
            .listRowInsets(isOn ? EdgeInsets(top: 12, leading: sideInset, bottom: 12, trailing: sideInset) : nil)
    }
}

/// One capsule: the accent symbol and the name on the summary tiles' own surface; `compact`, the name
/// alone with less padding, for a line that would not fit otherwise.
private struct TabDoorCapsuleButton: View {
    @Environment(\.appearance) private var appearance
    let door: TabDoorCapsule
    var compact: Bool = false

    var body: some View {
        Button {
            Settings.shared.hapticFeedback()
            door.action()
        } label: {
            HStack(spacing: 6) {
                if !compact {
                    Image(systemName: door.systemImage)
                        .foregroundStyle(appearance.accent)
                }
                Text(door.title)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .font(.footnote.weight(.semibold))
            .fixedSize()
            .padding(.horizontal, compact ? 10 : 12)
            .padding(.vertical, 9)
            .contentSurface(clear: true)
            .contentShape(Capsule())
            // Named by what it says; the symbol is decoration. On the LABEL, as `DailyHubDoorLabel`
            // does: on the Button these made a second element round it, so VoiceOver (and the UI
            // tests) found two buttons for each capsule.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(door.title))
        }
        .buttonStyle(.plain)
    }
}

#endif
