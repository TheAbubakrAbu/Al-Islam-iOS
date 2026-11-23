#if os(iOS)
import SwiftUI

/// What the similar sheet shows, read as the sheet is made (2026-11-22; it opened on a spinner while
/// every match's text was read): the pack's list for the narration, each match a row by its key with
/// the runs to tint as the pack shipped them; the group of chains its own chain is the same as; and
/// the tree of every chain of these narrations. Four lookups in blocks the book's page already
/// inflated (`prewarm`), and no text.
@MainActor
final class SimilarHadithsPage: ObservableObject {
    let list: HadithListModel
    /// The group of chains this narration's is the same as, with how many other narrations it carries.
    let sameChain: (group: Int, others: Int)?
    /// The tree of every chain of this narration and its similar ones, when the pack built one.
    let tree: HadithIsnadTreesPack.Summary?

    init(slug: String, idInBook: Int) {
        let matches = SimilarHadithsStore.shared.matches(slug: slug, idInBook: idInBook)
        list = HadithListModel(requests: matches.map { match in
            HadithListEntry.Request(slug: match.slug, idInBook: match.idInBook, tier: match.tier, score: match.score,
                                    badge: SimilarHadithsSheet.badge(for: match),
                                    secondaryBadge: match.sameEnglish ? String(localized: "Same English") : nil,
                                    sharedRanges: match.sharedRanges)
        }, tiered: true)
        tree = HadithIsnadTreeStore.shared.summary(slug: slug, idInBook: idInBook)
        if let group = HadithChainStore.shared.chainGroup(slug: slug, idInBook: idInBook) {
            let others = HadithNarratorStore.shared.members(group: group).filter { $0.slug != slug || $0.idInBook != idInBook }
            sameChain = others.isEmpty ? nil : (group, others.count)
        } else {
            sameChain = nil
        }
    }
}

/// The other narrations on the shelf that carry this one's text, or nearly (SimilarHadiths.swift),
/// opened from the row's menu (Abu, 2026-10-27): the exact matches first, same text and chain, then
/// the same text under another chain, then similar wording by score, each readable in place with the
/// words it shares with this narration tinted as the pack shipped them. Above them, when another
/// narration is carried by exactly this one's chain, the door to those, and the door to the tree of
/// every chain of these narrations (HadithIsnadTreeView.swift). The bar at the foot searches the
/// matches' own words, and the menu beside it sorts and groups them by match, book or grade and
/// narrows them to chosen books.
struct SimilarHadithsSheet: View {
    @Environment(\.dismiss) private var dismiss

    let book: HadithCatalogBook
    let hadith: HadithBookData.Hadith

    @StateObject private var page: SimilarHadithsPage
    @State private var pushSameChain = false
    @State private var pushTree = false
    #if DEBUG
    /// The launch arguments below act once, not each time the sheet comes back from a push.
    @State private var ranDebugArguments = false
    #endif

    init(book: HadithCatalogBook, hadith: HadithBookData.Hadith) {
        self.book = book
        self.hadith = hadith
        _page = StateObject(wrappedValue: SimilarHadithsPage(slug: book.slug, idInBook: hadith.idInBook))
    }

    /// "Sahih al-Bukhari 1", as the reader sees it.
    private var displayReference: String { book.displayReference(hadith.displayNumber) }

    var body: some View {
        SheetNavigationContainer {
            HadithResolvedList(
                model: page.list,
                emptyText: String(localized: "No similar narrations are recorded for this hadith."),
                footnote: String(localized: "Found ahead of time across every book on the shelf: the Arabic compared with its vowel marks and punctuation set aside and the chain of narrators separated from the text, then the wording compared by the phrases two narrations share. A narration's English is noted when it is the same translation.")
            ) {
                if page.sameChain != nil || page.tree != nil {
                    Section {
                        if let tree = page.tree {
                            HadithIsnadTreeDoor(summary: tree) { pushTree = true }
                        }
                        if let sameChain = page.sameChain {
                            HadithSameChainDoor(others: sameChain.others) { pushSameChain = true }
                        }
                    }
                }
            }
            .pushDestination(isPresented: $pushSameChain) {
                if let sameChain = page.sameChain {
                    HadithSameChainView(group: sameChain.group, book: book, hadith: hadith)
                }
            }
            .pushDestination(isPresented: $pushTree) {
                if let tree = page.tree {
                    HadithIsnadTreeView(book: book, hadith: hadith, summary: tree)
                }
            }
            .navigationTitle(String(localized: "Similar to \(displayReference)"))
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
        }
        // A sheet's screens end ABOVE their bottom bars (`AdaptiveSafeArea`): without this the
        // matches ran under the search field.
        .environment(\.nowPlayingInSheet, true)
        .hadithOpenInBook(dismiss: dismiss)
        #if DEBUG
        .onAppear { runDebugArguments() }
        #endif
    }

    /// The row's badge: the tier, with the score for similar wording ("87% similar"), or "Quoted whole"
    /// when one narration sits whole inside the other.
    static func badge(for match: SimilarHadithMatch) -> String {
        switch match.tier {
        case .sameTextAndChain: return String(localized: "Same text and chain")
        case .sameText: return String(localized: "Same text")
        case .similar:
            if match.score >= 100 { return String(localized: "Quoted whole") }
            let percent = (Double(match.score) / 100).formatted(.percent.precision(.fractionLength(0)))
            return String(localized: "\(percent) similar")
        }
    }

    #if DEBUG
    /// Headless verification only: "-openIsnadTree" (with -openSimilarHadiths) pushes the tree,
    /// "-openInBookFirst" opens the first row in its book.
    private func runDebugArguments() {
        guard !ranDebugArguments else { return }
        ranDebugArguments = true
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-openIsnadTree"), page.tree != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { pushTree = true }
        }
        if arguments.contains("-openInBookFirst"), let first = page.list.entries.first {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    AppNavigation.shared.openHadith(slug: first.book.slug, idInBook: first.hadith.idInBook)
                }
            }
        }
    }
    #endif
}

/// The door to the narrations carried by the same chain, the one row the similar sheet and the chain
/// sheet share: a button through a push door (`pushDestination`), drawn like a link.
struct HadithSameChainDoor: View {
    private let settings = Settings.shared

    let others: Int
    let open: () -> Void

    var body: some View {
        Button {
            settings.hapticFeedback()
            open()
        } label: {
            // The app's door row (`SettingsRowLabel`), as the tree's door beside it.
            SettingsRowLabel(title: String(localized: "Same Chain of Narrators"),
                             systemImage: "point.3.filled.connected.trianglepath.dotted",
                             subtitle: others == 1 ? String(localized: "1 other narration") : String(localized: "\(others) other narrations"),
                             showsChevron: true)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
#endif
