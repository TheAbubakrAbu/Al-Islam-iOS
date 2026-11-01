import SwiftUI

/// One narration's chain of narrators (HadithChains.swift), opened from the row's menu or a tap on its
/// grade: the isnad as the narration writes it, in Arabic, from the Prophet ﷺ down to the collector,
/// with the word each narrator received it by, each name and word in English under it when the
/// toolbar's switch is on (Abu, 2026-10-31), and the way to share it as an image. A tap on a
/// narrator opens his page (HadithNarratorViews.swift), and above the chain (Abu: "put tree at the
/// top rather than the bottom") the doors to the other narrations carried by exactly this chain and
/// to the tree of every chain of this narration (HadithIsnadTreeView.swift).
struct HadithChainSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appearance) private var appearance
    /// The English under each name and word, remembered; the tree page reads the same switch.
    @AppStorage(HadithChainSheet.englishKey) private var showsEnglish = true
    static let englishKey = "hadithChainShowsEnglish"

    let book: HadithCatalogBook
    let hadith: HadithBookData.Hadith

    @State private var chain: IsnadChain?
    @State private var resolved = false
    /// The group of chains this one is the same as, with how many other narrations it carries.
    @State private var sameChain: (group: Int, others: Int)?
    /// The tree of every chain of this narration and its similar ones, when the pack built one.
    @State private var tree: HadithIsnadTreesPack.Summary?
    @State private var pushedNarrator: Int?
    @State private var pushSameChain = false
    @State private var pushTree = false

    /// "Sahih al-Bukhari 1", as the reader sees it.
    private var reference: String { book.displayReference(hadith.displayNumber) }

    var body: some View {
        SheetNavigationContainer {
            List {
                Group {
                    if let chain {
                        // The doors first: a chain can run ten generations, and the tree is what a
                        // reader comes back for.
                        if sameChain != nil || tree != nil {
                            Section {
                                if let tree {
                                    HadithIsnadTreeDoor(summary: tree) { pushTree = true }
                                }
                                if let sameChain {
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
                                                 salt: showsEnglish ? "en" : "")
                                    // The image takes the direction its button sits in: the diagram's.
                                    .environment(\.layoutDirection, .rightToLeft)
                            }
                        } header: {
                            Text("Chain of Narrators")
                        } footer: {
                            Text(showsEnglish
                                 ? "Read from this narration's own Arabic: each narrator as it names him, and above him the word by which he received it from the one above (حدثنا، أخبرنا، عن، سمعت). The English under each name is a transliteration made ahead of time, and under each word its meaning. Where the collector gives it by more than one road, the roads are drawn side by side below the narrator where they meet. Tap a narrator to see every narration that names him."
                                 : "Read from this narration's own Arabic: each narrator as it names him, and above him the word by which he received it from the one above (حدثنا، أخبرنا، عن، سمعت). Where the collector gives it by more than one road, the roads are drawn side by side below the narrator where they meet. Tap a narrator to see every narration that names him.")
                        }
                    } else if resolved {
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
                if let sameChain {
                    HadithSameChainView(group: sameChain.group, book: book, hadith: hadith)
                }
            }
            .pushDestination(isPresented: $pushTree) {
                if let tree {
                    HadithIsnadTreeView(book: book, hadith: hadith, summary: tree)
                }
            }
            #if DEBUG
            // "-openNarrator 1" / "-openSameChain" / "-openIsnadTree" (with -openHadithChain): the
            // narrator's page, the same-chain list or the tree, pushed once the chain is drawn.
            // Headless verification only.
            .onChange(of: resolved) { _ in
                let arguments = ProcessInfo.processInfo.arguments
                if let index = arguments.firstIndex(of: "-openNarrator"), arguments.indices.contains(index + 1),
                   let id = Int(arguments[index + 1]) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { pushedNarrator = id }
                } else if arguments.contains("-openSameChain"), sameChain != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { pushSameChain = true }
                } else if arguments.contains("-openIsnadTree"), tree != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { pushTree = true }
                }
            }
            #endif
            .navigationTitle(reference)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Settings.shared.hapticFeedback()
                        showsEnglish.toggle()
                    } label: {
                        Image(systemName: showsEnglish ? "character.book.closed.fill" : "character.book.closed")
                    }
                    .tint(appearance.accent)
                    .accessibilityLabel(showsEnglish ? "Hide the English" : "Show the English")
                }
            }
            .sheetDismissToolbar()
        }
        .hadithOpenInBook(dismiss: dismiss)
        // Decoded again when the English is switched: the names come from the narrator index then.
        .task(id: showsEnglish) {
            let arabic = hadith.arabic
            let slug = book.slug
            let idInBook = hadith.idInBook
            let title = book.displayTitle
            let english = showsEnglish
            let found = await Task.detached(priority: .userInitiated) { () -> (IsnadChain?, (Int, Int)?, HadithIsnadTreesPack.Summary?) in
                let chain = HadithChainStore.shared.chain(slug: slug, idInBook: idInBook, arabic: arabic, bookTitle: title, english: english)
                let tree = chain == nil ? nil : HadithIsnadTreeStore.shared.summary(slug: slug, idInBook: idInBook)
                guard chain != nil, let group = HadithChainStore.shared.chainGroup(slug: slug, idInBook: idInBook) else { return (chain, nil, tree) }
                let others = HadithNarratorStore.shared.members(group: group).filter { $0.slug != slug || $0.idInBook != idInBook }
                return (chain, others.isEmpty ? nil : (group, others.count), tree)
            }.value
            chain = found.0
            sameChain = found.1.map { (group: $0.0, others: $0.1) }
            tree = found.2
            resolved = true
        }
    }
}
