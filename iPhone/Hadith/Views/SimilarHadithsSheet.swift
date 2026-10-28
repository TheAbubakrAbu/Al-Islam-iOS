#if os(iOS)
import SwiftUI

/// The other narrations on the shelf that carry this one's text, or nearly (SimilarHadiths.swift),
/// opened from the row's menu (Abu, 2026-10-27): the exact matches first, same text and chain, then
/// the same text under another chain, then similar wording by score, each readable in place with the
/// words it shares with this narration tinted as the pack shipped them. Above them, when another
/// narration is carried by exactly this one's chain, the door to those, and the door to the tree of
/// every chain of these narrations (HadithIsnadTreeView.swift). The toolbar menu sorts and groups the
/// rows by match, book or grade, and narrows them to chosen books.
struct SimilarHadithsSheet: View {
    @Environment(\.dismiss) private var dismiss

    let book: HadithCatalogBook
    let hadith: HadithBookData.Hadith

    /// nil while the matches resolve (the books they live in open off the main thread).
    @State private var entries: [HadithListEntry]?
    /// The group of chains this narration's is the same as, with how many other narrations it carries.
    @State private var sameChain: (group: Int, others: Int)?
    /// The tree of every chain of this narration and its similar ones, when the pack built one.
    @State private var tree: HadithIsnadTreesPack.Summary?
    @State private var pushSameChain = false
    @State private var pushTree = false

    /// "Sahih al-Bukhari 1", as the reader sees it.
    private var displayReference: String { book.displayReference(hadith.displayNumber) }

    var body: some View {
        SheetNavigationContainer {
            Group {
                if let entries {
                    HadithResolvedList(
                        entries: entries,
                        tiered: true,
                        emptyText: String(localized: "No similar narrations are recorded for this hadith."),
                        footnote: String(localized: "Found ahead of time across every book on the shelf: the Arabic compared with its vowel marks and punctuation set aside and the chain of narrators separated from the text, then the wording compared by the phrases two narrations share. A narration's English is noted when it is the same translation.")
                    ) {
                        if sameChain != nil || tree != nil {
                            Section {
                                if let sameChain {
                                    HadithSameChainDoor(others: sameChain.others) { pushSameChain = true }
                                }
                                if let tree {
                                    HadithIsnadTreeDoor(summary: tree) { pushTree = true }
                                }
                            }
                        }
                    }
                    .pushDestination(isPresented: $pushSameChain) {
                        if let sameChain {
                            HadithSameChainView(group: sameChain.group, book: book, hadith: hadith)
                        }
                    }
                    .pushDestination(isPresented: $pushTree) {
                        if let tree {
                            HadithIsnadTreeView(book: book, hadith: hadith, summary: tree)
                        }
                    }
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(String(localized: "Similar to \(displayReference)"))
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
        }
        .hadithOpenInBook(dismiss: dismiss)
        .task { await load() }
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

    /// The pack's list for this narration, each match resolved to its row in its book, with the runs
    /// to tint as the pack shipped them; and the same-chain group, when the chains pack names one.
    private func load() async {
        let slug = book.slug
        let idInBook = hadith.idInBook
        let (matches, group, summary) = await Task.detached(priority: .userInitiated) { () -> ([SimilarHadithMatch], (Int, Int)?, HadithIsnadTreesPack.Summary?) in
            let matches = SimilarHadithsStore.shared.matches(slug: slug, idInBook: idInBook)
            let tree = HadithIsnadTreeStore.shared.summary(slug: slug, idInBook: idInBook)
            guard let group = HadithChainStore.shared.chainGroup(slug: slug, idInBook: idInBook) else { return (matches, nil, tree) }
            let others = HadithNarratorStore.shared.members(group: group).filter { $0.slug != slug || $0.idInBook != idInBook }
            return (matches, others.isEmpty ? nil : (group, others.count), tree)
        }.value
        sameChain = group.map { (group: $0.0, others: $0.1) }
        tree = summary
        let requests = matches.map { match in
            HadithListEntry.Request(slug: match.slug, idInBook: match.idInBook, tier: match.tier, score: match.score,
                                    badge: Self.badge(for: match),
                                    secondaryBadge: match.sameEnglish ? String(localized: "Same English") : nil,
                                    sharedRanges: match.sharedRanges)
        }
        entries = await HadithListEntry.resolve(requests)
        #if DEBUG
        // "-openIsnadTree" (with -openSimilarHadiths): the tree, pushed. Headless verification only.
        if ProcessInfo.processInfo.arguments.contains("-openIsnadTree"), tree != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { pushTree = true }
        }
        // "-openInBookFirst" (with -openSimilarHadiths): the first row's Open in Book, headlessly.
        if ProcessInfo.processInfo.arguments.contains("-openInBookFirst"), let first = entries?.first {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    AppNavigation.shared.openHadith(slug: first.book.slug, idInBook: first.hadith.idInBook)
                }
            }
        }
        #endif
    }
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
            HStack {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Same Chain of Narrators")
                            .foregroundColor(.primary)
                        Text(String(localized: "\(others) other narrations"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "point.3.filled.connected.trianglepath.dotted")
                        .foregroundColor(settings.accentColor.color)
                }
                Spacer()
                Image(systemName: "chevron.forward")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
#endif
