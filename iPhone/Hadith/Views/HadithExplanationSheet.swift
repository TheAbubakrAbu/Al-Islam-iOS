import SwiftUI

/// The Hadith Encyclopedia's page for one of the shelf's narrations (Abu, 2026-11-02: "bring hadith
/// explanation"), opened from the row's menu when HadithExplanations.qpk links the row to an entry
/// (HadithExplanations.swift): the entry's own text, its explanation, benefits and word meanings, as
/// the encyclopedia screen shows them (`HadeethEncHadithView`), with the encyclopedia's credit.
///
/// A shared link opens the same sheet (AppLink.swift, `explanation=`): by the narration it explains,
/// or by the encyclopedia entry itself for one the shelf does not link.
struct HadithExplanationSheet: View {
    private enum Target {
        case hadith(slug: String, idInBook: Int)
        case entry(String)
    }

    private let target: Target

    @Environment(\.dismiss) private var dismiss
    @State private var entry: HadeethEncEntry?
    @State private var resolved = false

    init(book: HadithCatalogBook, hadith: HadithBookData.Hadith) {
        target = .hadith(slug: book.slug, idInBook: hadith.idInBook)
    }

    init(slug: String, idInBook: Int) {
        target = .hadith(slug: slug, idInBook: idInBook)
    }

    init(entryID: String) {
        target = .entry(entryID)
    }

    /// The narration this sheet explains, for its share link; nil for an encyclopedia entry.
    private var shelfHadith: (slug: String, idInBook: Int)? {
        if case .hadith(let slug, let idInBook) = target { return (slug, idInBook) }
        return nil
    }

    var body: some View {
        SheetNavigationContainer {
            Group {
                if let entry {
                    HadeethEncHadithView(entry: entry, titleOverride: String(localized: "Explanation"),
                                         shelfHadith: shelfHadith)
                } else if resolved {
                    List {
                        Section {
                            Text("The Hadith Encyclopedia has no page for this narration.")
                                .foregroundStyle(.secondary)
                        }
                        .themedListRowBackground()
                    }
                    .applyConditionalListStyle()
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(Text("Explanation"))
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
        }
        // A sheet's screens end ABOVE their bottom bars (`AdaptiveSafeArea`): the page's search bar
        // (2026-11-24) otherwise floated over the explanation, its text in full ink under the field.
        .environment(\.nowPlayingInSheet, true)
        .hadithOpenInBook(dismiss: dismiss)
        .task {
            let target = self.target
            // The link is a binary search; the encyclopedia's index inflates on first use (off main).
            let found = await Task.detached(priority: .userInitiated) { () -> HadeethEncEntry? in
                let id: String
                switch target {
                case .hadith(let slug, let idInBook):
                    guard let linked = HadithExplanationStore.shared.explanationID(slug: slug, idInBook: idInBook) else { return nil }
                    id = linked
                case .entry(let entryID):
                    id = entryID
                }
                return HadeethEncStore.shared.library()?.entriesById[id]
            }.value
            entry = found
            resolved = true
        }
    }
}
