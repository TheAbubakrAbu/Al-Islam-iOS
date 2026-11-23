import SwiftUI

/// What the chain sheet shows, read as the sheet is made (2026-11-22; it used to open empty and fill
/// a moment later): the chain decoded with its English (the names come from the narrator index), the
/// group of chains it is the same as, and the tree of every chain of this narration. A decode of one
/// row's own words and three lookups, all in blocks the book's page already inflated.
@MainActor
final class HadithChainPage: ObservableObject {
    let chain: IsnadChain?
    /// The group of chains this one is the same as, with how many other narrations it carries.
    let sameChain: (group: Int, others: Int)?
    /// The tree of every chain of this narration and its similar ones, when the pack built one.
    let tree: HadithIsnadTreesPack.Summary?

    init(book: HadithCatalogBook, hadith: HadithBookData.Hadith) {
        let slug = book.slug
        let idInBook = hadith.idInBook
        let chain = HadithChainStore.shared.chain(slug: slug, idInBook: idInBook, arabic: hadith.arabic,
                                                  bookTitle: book.displayTitle, english: true)
        self.chain = chain
        tree = chain == nil ? nil : HadithIsnadTreeStore.shared.summary(slug: slug, idInBook: idInBook)
        if chain != nil, let group = HadithChainStore.shared.chainGroup(slug: slug, idInBook: idInBook) {
            let others = HadithNarratorStore.shared.members(group: group).filter { $0.slug != slug || $0.idInBook != idInBook }
            sameChain = others.isEmpty ? nil : (group, others.count)
        } else {
            sameChain = nil
        }
    }
}

/// One narration's chain of narrators (HadithChains.swift), opened from the row's menu or a tap on its
/// grade: the isnad as the narration writes it, in Arabic, from the Prophet ﷺ down to the collector,
/// with the word each narrator received it by, each name and word in English under it, always
/// (Abu, 2026-11-15: "Don't have a button for chain of narrators to be English just always have it";
/// a toolbar switch from 2026-10-31 until then), and the way to share it as an image. A tap on a
/// narrator opens his page (HadithNarratorViews.swift), and above the chain (Abu: "put tree at the
/// top rather than the bottom") the doors to the other narrations carried by exactly this chain and
/// to the tree of every chain of this narration (HadithIsnadTreeView.swift).
struct HadithChainSheet: View {
    @Environment(\.dismiss) private var dismiss

    let book: HadithCatalogBook
    let hadith: HadithBookData.Hadith

    @StateObject private var page: HadithChainPage
    @State private var pushedNarrator: Int?
    @State private var pushSameChain = false
    @State private var pushTree = false
    #if DEBUG
    /// The launch arguments below act once, not each time the sheet comes back from a push.
    @State private var ranDebugArguments = false
    #endif

    init(book: HadithCatalogBook, hadith: HadithBookData.Hadith) {
        self.book = book
        self.hadith = hadith
        _page = StateObject(wrappedValue: HadithChainPage(book: book, hadith: hadith))
    }

    /// "Sahih al-Bukhari 1", as the reader sees it.
    private var reference: String { book.displayReference(hadith.displayNumber) }

    /// The narrators the chain names, the collector among them. The Prophet ﷺ is the chain's
    /// source, not one of its narrators.
    private static func narratorCount(_ chain: IsnadChain) -> Int {
        let layers = chain.top + chain.branches.flatMap(\.layers) + chain.bottom
        return layers.reduce(0) { $0 + $1.nodes.filter { $0.role != .prophet }.count }
    }

    var body: some View {
        SheetNavigationContainer {
            List {
                Group {
                    if let chain = page.chain {
                        // The doors first: a chain can run ten generations, and the tree is what a
                        // reader comes back for.
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

                        Section {
                            IsnadDiagram(chain: chain, onNarratorTap: { pushedNarrator = $0 }, hadith: true)
                                .padding(.vertical, 4)
                                // The chain reads right to left in every interface: the first road is
                                // the first one the narration gives.
                                .environment(\.layoutDirection, .rightToLeft)

                            if #available(iOS 16.0, *) {
                                IsnadShareButton(label: String(localized: "Share the Chain as an Image"),
                                                 title: reference, subtitle: "سَنَدُ الحَدِيثِ", chain: chain, hadith: true,
                                                 salt: "en")
                                    // The image takes the direction its button sits in: the diagram's.
                                    .environment(\.layoutDirection, .rightToLeft)
                            }
                        } header: {
                            // The app's section header, the count being the narrators it names.
                            SectionPillHeader(title: String(localized: "Chain of Narrators").localizedUppercase,
                                              count: Self.narratorCount(chain))
                        } footer: {
                            Text("Read from this narration's own Arabic: each narrator as it names him, and above him the word by which he received it from the one above (حدثنا، أخبرنا، عن، سمعت). The English under each name is a transliteration made ahead of time, and under each word its meaning. Where the collector gives it by more than one road, the roads are drawn side by side below the narrator where they meet. Tap a narrator to see every narration that names him.")
                        }
                    } else {
                        Section {
                            Text("This narration's chain could not be drawn.")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .themedListRowBackground()
            }
            .applyConditionalListStyle()
            .pushDestination(item: $pushedNarrator) { narratorID in
                HadithNarratorView(narratorID: narratorID)
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
            #if DEBUG
            // "-openNarrator 1" / "-openSameChain" / "-openIsnadTree" (with -openHadithChain): the
            // narrator's page, the same-chain list or the tree, pushed once the chain is drawn.
            // Headless verification only.
            .onAppear {
                guard !ranDebugArguments else { return }
                ranDebugArguments = true
                let arguments = ProcessInfo.processInfo.arguments
                if let index = arguments.firstIndex(of: "-openNarrator"), arguments.indices.contains(index + 1),
                   let id = Int(arguments[index + 1]) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { pushedNarrator = id }
                } else if arguments.contains("-openSameChain"), page.sameChain != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { pushSameChain = true }
                } else if arguments.contains("-openIsnadTree"), page.tree != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { pushTree = true }
                }
            }
            #endif
            .navigationTitle(reference)
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
        }
        // A sheet's screens end ABOVE their bottom bars (`AdaptiveSafeArea`): a narrator's page
        // pushed here carries a search bar, and without this its rows ran under the field.
        .environment(\.nowPlayingInSheet, true)
        .hadithOpenInBook(dismiss: dismiss)
    }
}
