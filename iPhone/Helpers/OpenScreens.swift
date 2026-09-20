import SwiftUI

// The app is full of cross-links: the Hijri Converter offers the Hijri Calendar, the Calendar offers
// the Converter, a Qiraah imam's page lists its two riwayat and each riwayah's page links back to the
// imam it narrates. Each link is right on its own, and together they make a corridor you can walk
// forever: Converter -> Calendar -> Converter -> Calendar (Abu, 2026-09-19: "I don't want an infinite
// chain anywhere in the app").
//
// The fix is NOT to delete the links. Abu was explicit: "well it does have it just disable it". A row
// that vanishes when you arrive by one route and appears by another is worse than a dead one, because
// the screen's shape stops being predictable. So the row stays exactly where it is, greyed and
// unfocusable, saying you are already there.
//
// How it works: every screen that can be cross-linked TO announces itself with
// `.openScreen(.hijriCalendar)`. The announcement accumulates down the environment, so a screen sees
// every screen between it and the navigation root. `OpenScreenLink` then renders a plain disabled row
// instead of a NavigationLink when its destination is already on the stack. One mechanism, and adding
// a screen to it is one case plus one modifier.
//
// It is deliberately about the CURRENT STACK, not about history: going Calendar -> Converter -> back
// -> Converter is not a chain, and popping must re-enable what it re-opens. The environment does that
// for free, since a popped view's value goes with it.

/// A screen that other screens link to, and that must not be re-entered from inside itself.
///
/// Only screens that are BOTH a link target and a link source belong here: a leaf nobody links out of
/// cannot start a corridor.
enum OpenScreen: String, Hashable, CaseIterable {
    // The Hijri trio, all three of which offer each other.
    case hijriCalendar
    case hijriConverter
    case hijriArticle

    // The qiraat guide: the imam lists its riwayat, and each riwayah names the imam it narrates.
    case qiraatArticle
    case qiraahMaster
    case riwayahNarrator
    case qiraatExplorer
    case qiraatIsnadIndex

    // The Tajweed pair: the "What is Tajweed?" article offers Foundations, and Foundations' LEARN
    // MORE section offers the article straight back.
    case tajweedArticle
    case tajweedFoundations

    // HadeethEnc: a topic lists its hadiths, and a hadith lists its topics - including, almost
    // always, the topic you arrived from.
    case hadeethEncCategory
    case hadeethEncHadith

    // Miracles of the Quran: a category lists its articles, and an article's prose can carry a link
    // back to a category.
    case miracleCategory

    /// What a disabled row says in place of its caption, when the row itself does not supply one.
    var alreadyHereCaption: String {
        switch self {
        case .hijriCalendar:    return "You are in the Hijri Calendar"
        case .hijriConverter:   return "You are in the Hijri Converter"
        case .hijriArticle:     return "You are reading this article"
        case .qiraatArticle:    return "You are reading this article"
        case .qiraahMaster:     return "You are on this reading's page"
        case .riwayahNarrator:  return "You are on this riwayah's page"
        case .qiraatExplorer:   return "You are in the Qiraat Explorer"
        case .qiraatIsnadIndex: return "You are in the chains index"
        case .tajweedArticle:      return "You are reading this article"
        case .tajweedFoundations:  return "You are in Tajweed Foundations"
        case .hadeethEncCategory:  return "You are in this topic"
        case .hadeethEncHadith:    return "You are reading this hadith"
        case .miracleCategory:     return "You are in this category"
        }
    }
}

private struct OpenScreensKey: EnvironmentKey {
    static let defaultValue: Set<OpenScreen> = []
}

extension EnvironmentValues {
    /// Every cross-linkable screen between here and the navigation root, innermost included.
    var openScreens: Set<OpenScreen> {
        get { self[OpenScreensKey.self] }
        set { self[OpenScreensKey.self] = newValue }
    }
}

/// One open screen plus WHICH one it is showing, for screens that repeat with different data.
///
/// A HadeethEnc topic lists its hadiths and each hadith lists its topics, which is a corridor - but
/// only back to the SAME topic. Another topic on that hadith is a perfectly good place to go, and
/// disabling it because "a topic is open" would gut the feature. So these carry an id and a row is
/// disabled only when its id matches one already on the stack.
struct OpenScreenInstance: Hashable {
    let screen: OpenScreen
    let id: String
}

private struct OpenScreenInstancesKey: EnvironmentKey {
    static let defaultValue: Set<OpenScreenInstance> = []
}

extension EnvironmentValues {
    var openScreenInstances: Set<OpenScreenInstance> {
        get { self[OpenScreenInstancesKey.self] }
        set { self[OpenScreenInstancesKey.self] = newValue }
    }
}

extension View {
    /// Declares that this view IS the given screen, for everything inside it.
    ///
    /// `transformEnvironment`, not a plain `.environment`: the set must ACCUMULATE, so a riwayah page
    /// pushed from an imam's page still sees the imam. Writing the value outright would erase it and
    /// the second lap of the corridor would look like the first.
    func openScreen(_ screen: OpenScreen) -> some View {
        transformEnvironment(\.openScreens) { $0.insert(screen) }
    }

    /// Declares that this view is the given screen SHOWING a particular thing. Use on a screen that
    /// repeats with different data, and link to it with `OpenScreenLink(screen:id:)`.
    func openScreen(_ screen: OpenScreen, id: String) -> some View {
        transformEnvironment(\.openScreenInstances) { $0.insert(OpenScreenInstance(screen: screen, id: id)) }
    }

    /// Declares this view a navigation ROOT: the stack starts empty here.
    ///
    /// A sheet, or a tab, is a fresh stack even though its SwiftUI environment descends from whatever
    /// presented it. Without this, opening the Converter in a sheet from inside the Calendar would
    /// find the Calendar "open" and disable a link that leads somewhere perfectly reachable.
    func openScreenRoot() -> some View {
        environment(\.openScreens, []).environment(\.openScreenInstances, [])
    }
}

#if os(iOS)
/// A cross-link row: a `NavigationLink` when the destination is elsewhere, and the same row greyed out
/// and inert when you are already inside it.
///
/// The disabled form keeps the row's exact layout - only the chevron goes, since a chevron that leads
/// nowhere is a lie - and swaps the caption for "You are already here", so the screen answers the
/// question the row was going to raise.
struct OpenScreenLink<Destination: View, Label: View>: View {
    @Environment(\.openScreens) private var openScreens
    @Environment(\.openScreenInstances) private var openScreenInstances
    @Environment(\.appearance) private var appearance

    /// The screen this row leads to. The row disables itself when this is already on the stack.
    let screen: OpenScreen
    /// WHICH instance of that screen this row leads to, for screens that repeat with different data.
    /// Given, the row disables only when that exact one is open; omitted, any instance disables it.
    var id: String? = nil
    /// Overrides `screen.alreadyHereCaption` where a row can say something more exact (the imam's
    /// name rather than "this reading").
    var alreadyHereCaption: String? = nil
    /// Drops the caption entirely, leaving just the greyed label. For places with no room for a line
    /// of explanation: a toolbar glyph, a chip.
    var captionless: Bool = false
    @ViewBuilder let destination: () -> Destination
    @ViewBuilder let label: () -> Label

    private var isHere: Bool {
        if let id { return openScreenInstances.contains(OpenScreenInstance(screen: screen, id: id)) }
        return openScreens.contains(screen)
    }

    var body: some View {
        if isHere {
            VStack(alignment: .leading, spacing: 4) {
                label()

                if !captionless {
                    Text(alreadyHereCaption ?? screen.alreadyHereCaption)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            // Greyed, unfocusable, and announced as unavailable rather than silently inert.
            .foregroundStyle(.secondary)
            .opacity(0.55)
            .allowsHitTesting(false)
            .accessibilityElement(children: .combine)
            .accessibilityHint(alreadyHereCaption ?? screen.alreadyHereCaption)
        } else {
            NavigationLink(destination: LazyDestination(build: destination)) {
                label()
            }
        }
    }
}
#endif
