import SwiftUI

/// The Hadith Encyclopedia's page for one of the shelf's narrations (Abu, 2026-11-02: "bring hadith
/// explanation"), opened from the row's menu when HadithExplanations.qpk links the row to an entry
/// (HadithExplanations.swift): the entry's own text, its explanation, benefits and word meanings, as
/// the encyclopedia screen shows them (`HadeethEncHadithView`), with the encyclopedia's credit.
struct HadithExplanationSheet: View {
    let book: HadithCatalogBook
    let hadith: HadithBookData.Hadith

    @Environment(\.dismiss) private var dismiss
    @State private var entry: HadeethEncEntry?
    @State private var resolved = false

    var body: some View {
        SheetNavigationContainer {
            Group {
                if let entry {
                    HadeethEncHadithView(entry: entry, titleOverride: String(localized: "Explanation"))
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
        .hadithOpenInBook(dismiss: dismiss)
        .task {
            let slug = book.slug
            let idInBook = hadith.idInBook
            // The link is a binary search; the encyclopedia's index inflates on first use (off main).
            let found = await Task.detached(priority: .userInitiated) { () -> HadeethEncEntry? in
                guard let id = HadithExplanationStore.shared.explanationID(slug: slug, idInBook: idInBook) else { return nil }
                return HadeethEncStore.shared.library()?.entriesById[id]
            }.value
            entry = found
            resolved = true
        }
    }
}
