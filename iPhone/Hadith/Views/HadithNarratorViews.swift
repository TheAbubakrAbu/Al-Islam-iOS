#if os(iOS)
import SwiftUI

// A narrator's page and the narrations carried by one chain (HadithNarrators.swift), reached from a
// chain of narrators (Abu, 2026-10-27: "click on each person in the chain and see where else they
// are mentioned and see how many they are in, how many sahih, daif, etc and how many Hadiths they
// narrated and show all of them"; "all chains that are the exact same"). Both pages read what the
// pack shipped and list the rows through `HadithResolvedList`, so they sort, group, narrow, bookmark
// and open in the book like the similar narrations do.

/// One narrator: his name as the shelf most often writes it, his counts, then every narration naming him.
struct HadithNarratorView: View {
    @Environment(\.appearance) private var appearance

    let narratorID: Int

    @State private var profile: HadithNarratorProfile?
    @State private var entries: [HadithListEntry]?
    @State private var missing = false

    var body: some View {
        Group {
            if let profile, let entries {
                HadithResolvedList(
                    entries: entries,
                    emptyText: String(localized: "No narration naming this narrator could be read."),
                    footnote: String(localized: "Counted ahead of time from the chains the app can read, about two thirds of the narrations in the eleven books that carry them. A narrator is matched by his name as each narration writes it, so one man cited two ways has two pages. A grade is the strongest word of each grader's verdict; Sahih al-Bukhari and Sahih Muslim carry no grade line and count as sahih, as the collections are.")
                ) {
                    header(profile)
                }
            } else if missing {
                Text("This narrator's page could not be opened.")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(profile?.name ?? String(localized: "Narrator"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    /// The name, the three counts, and the grades: what the page says before its list.
    private func header(_ profile: HadithNarratorProfile) -> some View {
        Section {
            VStack(spacing: 12) {
                Text(profile.name)
                    .font(appearance.islamArabicFont(base: 28, relativeTo: .title))
                    .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                HStack(spacing: 8) {
                    stat(profile.narrations, String(localized: "Narrations"))
                    stat(profile.fromProphet, String(localized: "From the Prophet ﷺ"))
                    stat(profile.teacher, String(localized: "Taught the compiler"))
                }

                let grades = HadithGradeCategory.allCases.filter { profile.count($0) > 0 }
                if !grades.isEmpty {
                    HadithChipRows(items: grades.map { ($0.title, profile.count($0)) })
                }

                Text(String(localized: "\(profile.books.count) books"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 6)
        }
    }

    private func stat(_ count: Int, _ title: String) -> some View {
        VStack(spacing: 3) {
            Text(count.formatted())
                .font(.title3.monospacedDigit().weight(.semibold))
                .foregroundColor(appearance.accent)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(appearance.accent.opacity(0.08)))
    }

    /// The profile and its list, read off the main thread: a binary search each, then the rows
    /// resolved from their books.
    private func load() async {
        let id = narratorID
        let (profile, refs) = await Task.detached(priority: .userInitiated) {
            (HadithNarratorStore.shared.profile(id: id), HadithNarratorStore.shared.refs(id: id))
        }.value
        guard let profile else {
            missing = true
            return
        }
        self.profile = profile
        let requests = refs.map { ref -> HadithListEntry.Request in
            let role: String?
            switch ref.role {
            case .top: role = String(localized: "From the Prophet ﷺ")
            case .teacher: role = String(localized: "Taught the compiler")
            case .link: role = nil
            }
            return HadithListEntry.Request(slug: ref.slug, idInBook: ref.idInBook, secondaryBadge: role)
        }
        entries = await HadithListEntry.resolve(requests)
    }
}

/// Small labelled counts, two to a row, never lazy (a lazy grid in a List row can answer a different
/// height on each self-sizing pass).
struct HadithChipRows: View {
    @Environment(\.appearance) private var appearance

    let items: [(title: String, count: Int)]

    var body: some View {
        VStack(spacing: 6) {
            ForEach(Array(stride(from: 0, to: items.count, by: 2)), id: \.self) { start in
                HStack(spacing: 6) {
                    ForEach(start..<min(start + 2, items.count), id: \.self) { index in
                        chip(items[index])
                    }
                    if start + 1 >= items.count {
                        Spacer(minLength: 0)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func chip(_ item: (title: String, count: Int)) -> some View {
        HStack(spacing: 6) {
            Text(item.count.formatted())
                .font(.footnote.monospacedDigit().weight(.semibold))
                .foregroundColor(appearance.accent)
            Text(item.title)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(Capsule().fill(appearance.accent.opacity(0.1)))
    }
}

/// The narrations carried by exactly one chain of narrators, the one of the narration this page was
/// opened from left out.
struct HadithSameChainView: View {
    let group: Int
    let book: HadithCatalogBook
    let hadith: HadithBookData.Hadith

    @State private var entries: [HadithListEntry]?
    /// The tree of every chain of this narration (HadithIsnadTreeView.swift), when the pack built one.
    @State private var tree: HadithIsnadTreesPack.Summary?
    @State private var pushTree = false

    var body: some View {
        Group {
            if let entries {
                HadithResolvedList(
                    entries: entries,
                    emptyText: String(localized: "No other narration is carried by this chain."),
                    footnote: String(localized: "Found ahead of time: narrations whose chain names the same narrators, generation by generation, as this one's, among the chains the app can read.")
                ) {
                    Section {
                        Text(String(localized: "Narrated through the same chain as \(book.displayReference(hadith.displayNumber)), narrator for narrator."))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        if let tree {
                            HadithIsnadTreeDoor(summary: tree) { pushTree = true }
                        }
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
        .navigationTitle(String(localized: "Same Chain"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func load() async {
        let group = group
        let slug = book.slug
        let idInBook = hadith.idInBook
        let (members, summary) = await Task.detached(priority: .userInitiated) {
            (HadithNarratorStore.shared.members(group: group).filter { $0.slug != slug || $0.idInBook != idInBook },
             HadithIsnadTreeStore.shared.summary(slug: slug, idInBook: idInBook))
        }.value
        tree = summary
        entries = await HadithListEntry.resolve(members.map { HadithListEntry.Request(slug: $0.slug, idInBook: $0.idInBook) })
    }
}
#endif
