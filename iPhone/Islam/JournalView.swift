#if os(iOS)
import SwiftUI

// The Journal: a shelf of notebooks for what you learn, not a feelings log.
//
// Entries come in kinds (a note, lecture notes, a khutbah, a class, a study session, a reflection,
// a dua), carry tags, can be pinned, and hold attachments carried in from the rest of the app (an
// ayah, a bookmarked hadith, a dua) as snapshots, so an entry still reads whole years later. The
// notes left on bookmarked ayahs and hadiths appear in the same timeline, since they are journal
// entries the reader wrote in the margin. A daily prompt gives the pen something to start on.
// Ported from Tilawa's journal (Jamil Hammoudeh, with permission).

// MARK: - Model

enum JournalKind: String, Codable, CaseIterable, Identifiable {
    case note, lecture, khutbah, classNotes = "class", study, reflection, dua

    var id: String { rawValue }

    var title: String {
        switch self {
        case .note: return "Note"
        case .lecture: return "Lecture"
        case .khutbah: return "Khutbah"
        case .classNotes: return "Class"
        case .study: return "Study"
        case .reflection: return "Reflection"
        case .dua: return "Dua"
        }
    }

    var symbol: String {
        switch self {
        case .note: return "note.text"
        case .lecture: return "person.wave.2"
        case .khutbah: return "building.columns"
        case .classNotes: return "graduationcap"
        case .study: return "book"
        case .reflection: return "sparkles"
        case .dua: return "hands.and.sparkles"
        }
    }

    var placeholder: String {
        switch self {
        case .note: return "Write it down before it slips away..."
        case .lecture: return "What was said, and what you want to keep from it..."
        case .khutbah: return "What the khutbah argued, and what to act on..."
        case .classNotes: return "What was taught, the evidences, your questions..."
        case .study: return "What you studied today, and what it opened up..."
        case .reflection: return "What stayed with you, and why..."
        case .dua: return "What you are asking Allah for..."
        }
    }

    /// The kinds that record who spoke and where.
    var isTalk: Bool { self == .lecture || self == .khutbah || self == .classNotes }

    /// Starter headings for a fresh entry of this kind; scaffolding, never counted as writing.
    var template: String? {
        switch self {
        case .khutbah:
            return "## First khutbah\n\n## Second khutbah\n\n## Action points\n- "
        case .lecture, .classNotes:
            return "## Key points\n- \n\n## Evidences\n\n## Questions\n- "
        case .study:
            return "## Passage\n\n## Benefits\n- "
        default:
            return nil
        }
    }
}

enum JournalAttachmentKind: String, Codable {
    case ayah, hadith, dua, name
}

/// A snapshot of something carried in from the rest of the app: enough to read the entry whole
/// without the source, plus the reference to open it.
struct JournalAttachment: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    let kind: JournalAttachmentKind
    /// "2:255", "bukhari:1", a dua id, a name number.
    let refID: String
    let title: String
    var subtitle: String = ""
    var arabic: String = ""
    var body: String = ""
    var source: String = ""
}

struct JournalEntry: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var kind: JournalKind = .note
    var title: String = ""
    var text: String = ""
    var tags: [String] = []
    var speaker: String = ""
    var place: String = ""
    var attachments: [JournalAttachment] = []
    var pinned: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    /// Nothing written and nothing attached: a template's headings alone do not count.
    var isEmpty: Bool {
        let body = text
        let template = kind.template ?? ""
        return title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || body.trimmingCharacters(in: .whitespacesAndNewlines) == template.trimmingCharacters(in: .whitespacesAndNewlines))
            && attachments.isEmpty
    }

    /// The first line of the writing, for rows without a title.
    var headline: String {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTitle.isEmpty { return trimmedTitle }
        let firstLine = text.split(whereSeparator: { $0.isNewline })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first { !$0.isEmpty && !$0.hasPrefix("## ") && $0 != "-" }
        if let firstLine { return String(firstLine.prefix(80)) }
        if let attachment = attachments.first { return attachment.title }
        return "Untitled \(kind.title.lowercased())"
    }

    var searchKey: String {
        IslamArticles.fold(([title, text, speaker, place] + tags + attachments.flatMap { [$0.title, $0.body, $0.subtitle] }).joined(separator: " "))
    }
}

/// A tag as the user typed it, folded the way they are compared ("#Fiqh " and "fiqh" are one tag).
func journalNormalizeTag(_ raw: String) -> String {
    raw.trimmingCharacters(in: .whitespacesAndNewlines)
        .trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        .lowercased()
        .replacingOccurrences(of: #"\s+"#, with: "-", options: .regularExpression)
}

// MARK: - Store

/// The entries, kept as one JSON file in Documents (a journal must survive an app update and a
/// backup, and Documents is what a backup carries).
@MainActor
final class JournalStore: ObservableObject {
    static let shared = JournalStore()

    @Published private(set) var entries: [JournalEntry] = []

    private static var fileURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return documents.appendingPathComponent("journal.json")
    }

    private init() {
        load()
        #if DEBUG
        // "-journalSeed": two sample entries when the journal is empty, for screenshots.
        if entries.isEmpty, ProcessInfo.processInfo.arguments.contains("-journalSeed") {
            seedSamples()
        }
        #endif
    }

    /// Newest first; pinned entries first of all.
    var ordered: [JournalEntry] {
        entries.sorted { a, b in
            if a.pinned != b.pinned { return a.pinned }
            return a.createdAt > b.createdAt
        }
    }

    var tags: [String] {
        var counts: [String: Int] = [:]
        for entry in entries { for tag in entry.tags { counts[tag, default: 0] += 1 } }
        return counts.sorted { a, b in a.value != b.value ? a.value > b.value : a.key < b.key }.map(\.key)
    }

    var speakers: [String] {
        Array(Set(entries.map(\.speaker).filter { !$0.isEmpty })).sorted()
    }

    func entry(id: String) -> JournalEntry? {
        entries.first { $0.id == id }
    }

    /// Adds or replaces; an emptied entry is dropped rather than kept as a blank row.
    func save(_ entry: JournalEntry) {
        var entry = entry
        entry.updatedAt = Date()
        entry.tags = Array(NSOrderedSet(array: entry.tags.map(journalNormalizeTag).filter { !$0.isEmpty })) as? [String] ?? []
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            if entry.isEmpty {
                entries.remove(at: index)
            } else {
                entries[index] = entry
            }
        } else if !entry.isEmpty {
            entries.append(entry)
        }
        persist()
    }

    func remove(id: String) {
        entries.removeAll { $0.id == id }
        persist()
    }

    func togglePin(id: String) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[index].pinned.toggle()
        persist()
    }

    /// The whole journal as one text, for sharing or keeping outside the app.
    func exportText() -> String {
        var out = "# Journal\n\n"
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        for entry in ordered {
            out += "## \(entry.headline)\n"
            out += "\(entry.kind.title) · \(formatter.string(from: entry.createdAt))"
            if !entry.speaker.isEmpty { out += " · \(entry.speaker)" }
            if !entry.place.isEmpty { out += " · \(entry.place)" }
            if !entry.tags.isEmpty { out += " · " + entry.tags.map { "#" + $0 }.joined(separator: " ") }
            out += "\n\n"
            if !entry.text.isEmpty { out += entry.text + "\n\n" }
            for attachment in entry.attachments {
                out += "> \(attachment.title)"
                if !attachment.arabic.isEmpty { out += "\n> \(attachment.arabic)" }
                if !attachment.body.isEmpty { out += "\n> \(attachment.body)" }
                if !attachment.source.isEmpty { out += "\n> (\(attachment.source))" }
                out += "\n\n"
            }
        }
        return out
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(entries)
            try data.write(to: Self.fileURL, options: .atomic)
        } catch {
            NSLog("Journal save failed: %@", "\(error)")
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: Self.fileURL),
              let saved = try? JSONDecoder().decode([JournalEntry].self, from: data) else { return }
        entries = saved
    }

    #if DEBUG
    private func seedSamples() {
        var khutbah = JournalEntry(kind: .khutbah, title: "Gratitude in hardship")
        khutbah.text = "## First khutbah\nThe khatib built the whole khutbah on 14:7: gratitude is not a reaction to ease but the cause of increase.\n\n## Second khutbah\nThree practical ways to thank Allah with the limbs, not only the tongue.\n\n## Action points\n- Say alhamdulillah out loud after every prayer this week\n- Write down three blessings before sleeping"
        khutbah.tags = ["gratitude", "khutbah"]
        khutbah.speaker = "Sh. Yasir"
        khutbah.place = "Masjid an-Nur"
        khutbah.attachments = [JournalAttachment(kind: .ayah, refID: "14:7", title: "Ibrahim 14:7",
                                                 arabic: "وَإِذْ تَأَذَّنَ رَبُّكُمْ لَئِن شَكَرْتُمْ لَأَزِيدَنَّكُمْ",
                                                 body: "And [remember] when your Lord proclaimed, 'If you are grateful, I will surely increase you [in favor]'",
                                                 source: "Saheeh International")]
        khutbah.pinned = true
        khutbah.createdAt = Date().addingTimeInterval(-86_400 * 2)
        var study = JournalEntry(kind: .study, title: "Ayat al-Kursi word by word")
        study.text = "## Passage\nAl-Baqarah 2:255, with the morphology cards.\n\n## Benefits\n- Al-Hayy al-Qayyum: the two names every other name returns to\n- 'La ta'khudhuhu sinatun wa la nawm': the order matters, drowsiness before sleep"
        study.tags = ["quran", "names-of-allah"]
        study.createdAt = Date().addingTimeInterval(-3_600 * 5)
        entries = [khutbah, study]
        persist()
    }
    #endif
}

// MARK: - Prompts

enum JournalPrompts {
    static let all: [String] = [
        "What is one benefit from this week's khutbah worth keeping?",
        "Which ayah did you sit with today, and what did it open?",
        "What did you learn recently that you do not want to forget?",
        "Write down one evidence you heard, and where it is from.",
        "What would you teach someone else from your last class?",
        "Which word in the Quran surprised you this week?",
        "What are you asking Allah for today?",
        "What is one question you want to ask a person of knowledge?",
        "Which name of Allah did you lean on today?",
        "What did a hadith you read this week ask of you?",
    ]

    /// The day's prompt (rotates daily); `step` moves to the next one.
    static func prompt(step: Int = 0) -> String {
        let day = Int(Date().timeIntervalSince1970 / 86_400)
        let index = ((day + step) % all.count + all.count) % all.count
        return all[index]
    }
}

// MARK: - The margin notes (ayah and hadith bookmark notes) in the timeline

/// A note the reader left on a bookmarked ayah or hadith, read straight from the bookmark records.
struct JournalMarginNote: Identifiable {
    enum Source { case ayah(surah: Int, ayah: Int), hadith(slug: String, idInBook: Int) }
    let id: String
    let source: Source
    let title: String
    let text: String
    let preview: String
}

// MARK: - Screens

struct JournalView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var store = JournalStore.shared
    @ObservedObject private var quranData = QuranData.shared

    enum Filter: Hashable {
        case all, pinned, kind(JournalKind), tag(String), marginNotes
    }

    @State private var searchText = ""
    @State private var filter: Filter = .all
    @State private var promptStep = 0
    @State private var editing: JournalEntry?
    @State private var showExport = false
    @State private var confirmDelete: JournalEntry?

    private var accent: Color { settings.accentColor.color }

    private var marginNotes: [JournalMarginNote] {
        var notes: [JournalMarginNote] = []
        for bookmark in settings.bookmarkedAyahs {
            guard let note = bookmark.note?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty else { continue }
            let name = quranData.surah(bookmark.surah)?.nameTransliteration ?? "Surah \(bookmark.surah)"
            let preview = quranData.ayah(surah: bookmark.surah, ayah: bookmark.ayah)?.textEnglishSaheeh ?? ""
            notes.append(JournalMarginNote(id: "ayah-\(bookmark.surah)-\(bookmark.ayah)",
                                           source: .ayah(surah: bookmark.surah, ayah: bookmark.ayah),
                                           title: "\(name) \(bookmark.surah):\(bookmark.ayah)", text: note, preview: preview))
        }
        for bookmark in HadithUserData.shared.bookmarks {
            guard let note = bookmark.note?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty else { continue }
            notes.append(JournalMarginNote(id: "hadith-\(bookmark.slug)-\(bookmark.idInBook)",
                                           source: .hadith(slug: bookmark.slug, idInBook: bookmark.idInBook),
                                           title: bookmark.reference, text: note,
                                           preview: bookmark.englishPreview ?? bookmark.preview))
        }
        return notes
    }

    private var query: String { IslamArticles.fold(searchText.trimmingCharacters(in: .whitespacesAndNewlines)) }

    private var shownEntries: [JournalEntry] {
        var list = store.ordered
        switch filter {
        case .all, .marginNotes: break
        case .pinned: list = list.filter(\.pinned)
        case .kind(let kind): list = list.filter { $0.kind == kind }
        case .tag(let tag): list = list.filter { $0.tags.contains(tag) }
        }
        if filter == .marginNotes { list = [] }
        guard !query.isEmpty else { return list }
        let terms = query.split(separator: " ").map(String.init)
        return list.filter { entry in
            let key = entry.searchKey
            return terms.allSatisfy { key.contains($0) }
        }
    }

    private var shownMarginNotes: [JournalMarginNote] {
        guard filter == .all || filter == .marginNotes else { return [] }
        let notes = marginNotes
        guard !query.isEmpty else { return notes }
        let terms = query.split(separator: " ").map(String.init)
        return notes.filter { note in
            let key = IslamArticles.fold(note.title + " " + note.text + " " + note.preview)
            return terms.allSatisfy { key.contains($0) }
        }
    }

    /// Entries grouped by calendar day, newest day first; pinned entries sit in their own group.
    private var dayGroups: [(title: String, entries: [JournalEntry])] {
        let entries = shownEntries
        let pinned = entries.filter(\.pinned)
        let rest = entries.filter { !$0.pinned }
        var groups: [(String, [JournalEntry])] = []
        if !pinned.isEmpty, filter != .pinned { groups.append(("PINNED", pinned)) }
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM yyyy"
        var byDay: [(Date, [JournalEntry])] = []
        for entry in (filter == .pinned ? entries : rest) {
            let day = calendar.startOfDay(for: entry.createdAt)
            if let index = byDay.firstIndex(where: { $0.0 == day }) {
                byDay[index].1.append(entry)
            } else {
                byDay.append((day, [entry]))
            }
        }
        for (day, list) in byDay {
            let title: String
            if calendar.isDateInToday(day) { title = "TODAY" }
            else if calendar.isDateInYesterday(day) { title = "YESTERDAY" }
            else { title = formatter.string(from: day).uppercased() }
            groups.append((title, list))
        }
        return groups
    }

    var body: some View {
        List {
            Group {
                if query.isEmpty {
                    writeSection
                }

                filterSection

                let groups = dayGroups
                ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                    Section(header: Text(group.title)) {
                        ForEach(group.entries) { entry in
                            NavigationLink(destination: LazyDestination { JournalEntryView(entryID: entry.id) }) {
                                entryRow(entry)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) { confirmDelete = entry } label: { Label("Delete", systemImage: "trash") }
                                Button { store.togglePin(id: entry.id) } label: {
                                    Label(entry.pinned ? "Unpin" : "Pin", systemImage: entry.pinned ? "pin.slash" : "pin")
                                }
                                .tint(accent)
                            }
                        }
                    }
                }

                let notes = shownMarginNotes
                if !notes.isEmpty {
                    Section(header: SectionPillHeader(title: "NOTES ON AYAHS AND HADITHS", count: notes.count)) {
                        ForEach(notes) { note in
                            marginNoteRow(note)
                        }
                    }
                }

                if groups.isEmpty, notes.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(query.isEmpty ? "Nothing written yet" : "Nothing here matches that yet.")
                                .font(.subheadline.weight(.semibold))
                            Text(query.isEmpty
                                 ? "Write what you learn: a khutbah, a class, an ayah you sat with. Notes you leave on bookmarked ayahs and hadiths show up here too."
                                 : "Try another word, or clear the filter.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 4)
                    }
                }

                if query.isEmpty, !store.entries.isEmpty {
                    Section(footer:
                        Text("Your journal stays on this device (it is in the app's Documents, so an iCloud or iTunes backup carries it). Export it as text any time from the menu.")
                            .font(.caption2)
                    ) { EmptyView() }
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle(disableNowPlayingInset: true)
        .compactListSectionSpacing()
        .adaptiveSafeArea(edge: .bottom) {
            SearchBar(text: AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut), placeholder: "Search your journal")
                .padding(.horizontal, 24)
                .padding(.bottom, BottomBarCushion.standard)
                .background(Color.white.opacity(0.00001))
        }
        .navigationTitle("Journal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        settings.hapticFeedback()
                        editing = JournalEntry()
                    } label: { Label("New Entry", systemImage: "square.and.pencil") }
                    if !store.entries.isEmpty {
                        Button {
                            settings.hapticFeedback()
                            presentSystemShareSheet(items: [store.exportText()])
                        } label: { Label("Export as Text", systemImage: "square.and.arrow.up") }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .fixedMenuOrder()
                .tint(accent)
            }
        }
        .sheet(item: $editing) { entry in
            JournalEditorSheet(entry: entry)
        }
        .confirmationDialog("Delete this entry?", isPresented: Binding(get: { confirmDelete != nil }, set: { if !$0 { confirmDelete = nil } }), titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let entry = confirmDelete { store.remove(id: entry.id) }
                confirmDelete = nil
            }
            Button("Cancel", role: .cancel) { confirmDelete = nil }
        }
        .onAppear {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-journalNew"), editing == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { editing = JournalEntry() }
            }
            #endif
        }
    }

    // MARK: Sections

    private var writeSection: some View {
        Section {
            Button {
                settings.hapticFeedback()
                editing = JournalEntry()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "square.and.pencil")
                        .font(.title3)
                        .foregroundColor(accent)
                        .frame(width: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Write an entry")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                        Text("A note, a khutbah, a class, an ayah you sat with")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // The day's prompt: the whole row seeds the editor with it; the small arrow turns the page.
            HStack(alignment: .top, spacing: 10) {
                Button {
                    settings.hapticFeedback()
                    var entry = JournalEntry(kind: .reflection)
                    entry.text = JournalPrompts.prompt(step: promptStep) + "\n\n"
                    editing = entry
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TODAY'S PROMPT")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(accent)
                        Text(JournalPrompts.prompt(step: promptStep))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) { promptStep += 1 }
                } label: {
                    Image(systemName: "arrow.2.circlepath")
                        .font(.body)
                        .foregroundColor(accent)
                        .frame(width: 32, height: 32)
                        .conditionalGlassEffect(circle: true, flat: true)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Another prompt")
            }
            .padding(.vertical, 2)
        }
    }

    @ViewBuilder
    private var filterSection: some View {
        let kinds = JournalKind.allCases.filter { kind in store.entries.contains { $0.kind == kind } }
        let tags = Array(store.tags.prefix(12))
        let pinnedCount = store.entries.filter(\.pinned).count
        let notesCount = marginNotes.count
        if !store.entries.isEmpty || notesCount > 0 {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip("All", count: store.entries.count + notesCount, .all)
                        if pinnedCount > 0 { filterChip("Pinned", count: pinnedCount, .pinned) }
                        ForEach(kinds) { kind in
                            filterChip(kind.title, count: store.entries.filter { $0.kind == kind }.count, .kind(kind))
                        }
                        if notesCount > 0 { filterChip("Margin notes", count: notesCount, .marginNotes) }
                        ForEach(tags, id: \.self) { tag in
                            filterChip("#" + tag, count: store.entries.filter { $0.tags.contains(tag) }.count, .tag(tag))
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
                }
                .listRowInsets(EdgeInsets(top: 2, leading: 12, bottom: 2, trailing: 12))
                .listRowBackground(Color.clear)
            }
        }
    }

    private func filterChip(_ title: String, count: Int, _ value: Filter) -> some View {
        let selected = filter == value
        return Button {
            settings.hapticFeedback()
            withAnimation(.easeInOut) { filter = value }
        } label: {
            HStack(spacing: 5) {
                Text(title)
                Text("\(count)")
                    .foregroundColor(selected ? .white.opacity(0.85) : .secondary)
            }
            .font(.caption.weight(.semibold))
            .foregroundColor(selected ? .white : .primary)
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(Capsule().fill(selected ? accent : Color.primary.opacity(0.08)))
        }
        .buttonStyle(.plain)
    }

    private func entryRow(_ entry: JournalEntry) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Image(systemName: entry.kind.symbol)
                    .font(.caption)
                    .foregroundColor(accent)
                Text(entry.kind.title.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundColor(accent)
                if entry.pinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(entry.createdAt, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Text(entry.headline)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
            let excerpt = Self.excerpt(entry)
            if !excerpt.isEmpty {
                Text(excerpt)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            if !entry.attachments.isEmpty || !entry.tags.isEmpty || !entry.speaker.isEmpty {
                HStack(spacing: 6) {
                    if !entry.attachments.isEmpty {
                        Label("\(entry.attachments.count)", systemImage: "paperclip")
                    }
                    if !entry.speaker.isEmpty {
                        Label(entry.speaker, systemImage: "person")
                    }
                    ForEach(entry.tags.prefix(3), id: \.self) { tag in
                        Text("#" + tag)
                    }
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
            }
        }
        .padding(.vertical, 3)
    }

    /// The writing after the headline, headings and empty bullets dropped.
    private static func excerpt(_ entry: JournalEntry) -> String {
        let lines = entry.text.split(whereSeparator: { $0.isNewline })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("## ") && $0 != "-" }
        let body = entry.title.isEmpty ? Array(lines.dropFirst()) : lines
        return body.joined(separator: " ")
    }

    private func marginNoteRow(_ note: JournalMarginNote) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                switch note.source {
                case .ayah: Image(systemName: "book.closed").font(.caption).foregroundColor(accent)
                case .hadith: Image(systemName: "text.book.closed").font(.caption).foregroundColor(accent)
                }
                Text(note.title)
                    .font(.caption2.weight(.bold))
                    .foregroundColor(accent)
            }
            Text(note.text)
                .font(.subheadline)
                .lineLimit(3)
            if !note.preview.isEmpty {
                Text(note.preview)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 3)
        .textSelection(.enabled)
    }
}

// MARK: - Entry

struct JournalEntryView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var store = JournalStore.shared
    @Environment(\.dismiss) private var dismiss

    let entryID: String
    @State private var editing: JournalEntry?
    @State private var confirmDelete = false

    private var accent: Color { settings.accentColor.color }
    private var entry: JournalEntry? { store.entry(id: entryID) }

    var body: some View {
        List {
            if let entry {
                Group {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: entry.kind.symbol)
                                Text(entry.kind.title.uppercased())
                                if entry.pinned { Image(systemName: "pin.fill") }
                                Spacer()
                                Text(entry.createdAt, style: .date)
                            }
                            .font(.caption2.weight(.bold))
                            .foregroundColor(accent)

                            Text(entry.headline)
                                .font(.title3.weight(.semibold))
                                .fixedSize(horizontal: false, vertical: true)

                            if !entry.speaker.isEmpty || !entry.place.isEmpty {
                                Text([entry.speaker, entry.place].filter { !$0.isEmpty }.joined(separator: " · "))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            if !entry.tags.isEmpty {
                                FlowLayoutView(spacing: 6) {
                                    ForEach(entry.tags, id: \.self) { tag in
                                        Text("#" + tag)
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Capsule().fill(Color.primary.opacity(0.08)))
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    if !entry.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Section {
                            JournalTextBody(text: entry.text)
                                .padding(.vertical, 4)
                        }
                    }

                    if !entry.attachments.isEmpty {
                        Section(header: SectionPillHeader(title: "ATTACHED", count: entry.attachments.count)) {
                            ForEach(entry.attachments) { attachment in
                                JournalAttachmentCard(attachment: attachment)
                            }
                        }
                    }
                }
                .themedListRowBackground()
            } else {
                Text("This entry is gone.")
                    .foregroundStyle(.secondary)
            }
        }
        .applyConditionalListStyle(disableNowPlayingInset: true)
        .compactListSectionSpacing()
        .navigationTitle(entry?.kind.title ?? "Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if let entry {
                    Menu {
                        Button {
                            settings.hapticFeedback()
                            editing = entry
                        } label: { Label("Edit", systemImage: "pencil") }
                        Button {
                            settings.hapticFeedback()
                            store.togglePin(id: entry.id)
                        } label: { Label(entry.pinned ? "Unpin" : "Pin", systemImage: entry.pinned ? "pin.slash" : "pin") }
                        Button {
                            settings.hapticFeedback()
                            UIPasteboard.general.string = Self.shareText(entry)
                        } label: { Label("Copy", systemImage: "doc.on.doc") }
                        Button {
                            settings.hapticFeedback()
                            presentSystemShareSheet(items: [Self.shareText(entry)])
                        } label: { Label("Share", systemImage: "square.and.arrow.up") }
                        Divider()
                        Button(role: .destructive) { confirmDelete = true } label: { Label("Delete", systemImage: "trash") }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .fixedMenuOrder()
                    .tint(accent)
                }
            }
        }
        .sheet(item: $editing) { entry in
            JournalEditorSheet(entry: entry)
        }
        .confirmationDialog("Delete this entry?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                store.remove(id: entryID)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    static func shareText(_ entry: JournalEntry) -> String {
        var out = entry.headline + "\n"
        if !entry.text.isEmpty { out += "\n" + entry.text + "\n" }
        for attachment in entry.attachments {
            out += "\n" + attachment.title
            if !attachment.arabic.isEmpty { out += "\n" + attachment.arabic }
            if !attachment.body.isEmpty { out += "\n" + attachment.body }
            if !attachment.source.isEmpty { out += "\n(" + attachment.source + ")" }
            out += "\n"
        }
        return out
    }
}

/// The writing, with "## " lines as headings and "- " lines as bullets.
struct JournalTextBody: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(text.split(separator: "\n", omittingEmptySubsequences: false).enumerated()), id: \.offset) { _, rawLine in
                let line = String(rawLine)
                if line.hasPrefix("## ") {
                    Text(line.dropFirst(3))
                        .font(.subheadline.weight(.bold))
                        .padding(.top, 6)
                } else if line.hasPrefix("- ") {
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                        Text(line.dropFirst(2))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .font(.body)
                } else if line.trimmingCharacters(in: .whitespaces).isEmpty {
                    Spacer().frame(height: 2)
                } else {
                    Text(line)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .textSelection(.enabled)
    }
}

struct JournalAttachmentCard: View {
    @ObservedObject private var settings = Settings.shared
    let attachment: JournalAttachment

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.caption)
                Text(attachment.title)
                    .font(.caption.weight(.bold))
                Spacer()
                if !attachment.subtitle.isEmpty {
                    Text(attachment.subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundColor(settings.accentColor.color)

            if !attachment.arabic.isEmpty {
                Text(attachment.arabic)
                    .font(.custom(attachment.kind == .ayah ? settings.quranArabicFontName(for: nil) : settings.nonQuranArabicFontName, size: 22))
                    .arabicFontDesign(custom: true)
                    .multilineTextAlignment(.trailing)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !attachment.body.isEmpty {
                Text(attachment.body)
                    .font(.footnote)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !attachment.source.isEmpty {
                Text(attachment.source)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .textSelection(.enabled)
    }

    private var symbol: String {
        switch attachment.kind {
        case .ayah: return "book.closed"
        case .hadith: return "text.book.closed"
        case .dua: return "hands.and.sparkles"
        case .name: return "star.circle"
        }
    }
}

// MARK: - Editor

struct JournalEditorSheet: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var store = JournalStore.shared
    @ObservedObject private var quranData = QuranData.shared
    @Environment(\.dismiss) private var dismiss

    @State private var entry: JournalEntry
    @State private var tagsText: String
    @State private var showAttach = false
    @State private var showRespectAlert = false

    init(entry: JournalEntry) {
        _entry = State(initialValue: entry)
        _tagsText = State(initialValue: entry.tags.map { "#" + $0 }.joined(separator: " "))
    }

    private var accent: Color { settings.accentColor.color }
    private var isNew: Bool { store.entry(id: entry.id) == nil }

    var body: some View {
        SheetNavigationContainer {
            List {
                Group {
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(JournalKind.allCases) { kind in
                                    let selected = entry.kind == kind
                                    Button {
                                        settings.hapticFeedback()
                                        withAnimation(.easeInOut) { choose(kind) }
                                    } label: {
                                        HStack(spacing: 5) {
                                            Image(systemName: kind.symbol)
                                            Text(kind.title)
                                        }
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(selected ? .white : .primary)
                                        .padding(.horizontal, 11)
                                        .padding(.vertical, 6)
                                        .background(Capsule().fill(selected ? accent : Color.primary.opacity(0.08)))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 4)
                        }
                        .listRowInsets(EdgeInsets(top: 2, leading: 12, bottom: 2, trailing: 12))
                        .listRowBackground(Color.clear)
                    }

                    Section {
                        TextField("Title (optional)", text: $entry.title)
                            .font(.headline)
                        if entry.kind.isTalk {
                            TextField("Speaker", text: $entry.speaker)
                            TextField("Place", text: $entry.place)
                        }
                    }

                    Section(header: Text("WRITING"), footer: Text("Start a line with ## for a heading and - for a bullet.").font(.caption2)) {
                        ZStack(alignment: .topLeading) {
                            if entry.text.isEmpty {
                                Text(entry.kind.placeholder)
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                            }
                            TextEditor(text: $entry.text)
                                .frame(minHeight: 180)
                        }
                    }

                    Section(header: Text("TAGS")) {
                        TextField("#fiqh #ramadan", text: $tagsText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        if !store.tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(store.tags.prefix(12), id: \.self) { tag in
                                        Button {
                                            settings.hapticFeedback()
                                            if !tagsText.contains("#" + tag) {
                                                tagsText = (tagsText + " #" + tag).trimmingCharacters(in: .whitespaces)
                                            }
                                        } label: {
                                            Text("#" + tag)
                                                .font(.caption2.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Capsule().fill(Color.primary.opacity(0.08)))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }

                    Section(header: HStack {
                        Text("ATTACHED")
                        Spacer()
                        Button {
                            settings.hapticFeedback()
                            showAttach = true
                        } label: {
                            Label("Attach", systemImage: "paperclip")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundColor(accent)
                    }) {
                        if entry.attachments.isEmpty {
                            Text("An ayah, a bookmarked hadith or a dua, kept with the entry.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        ForEach(entry.attachments) { attachment in
                            JournalAttachmentCard(attachment: attachment)
                        }
                        .onDelete { offsets in entry.attachments.remove(atOffsets: offsets) }
                    }
                }
                .themedListRowBackground()
            }
            .applyConditionalListStyle(disableNowPlayingInset: true)
            .compactListSectionSpacing()
            .navigationTitle(isNew ? "New Entry" : "Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar(onConfirm: {
                guard !textContainsProfanity(entry.text), !textContainsProfanity(entry.title) else {
                    showRespectAlert = true
                    return false
                }
                entry.tags = tagsText.split(whereSeparator: { $0.isWhitespace || $0 == "," }).map { journalNormalizeTag(String($0)) }.filter { !$0.isEmpty }
                store.save(entry)
                return true
            })
            .accentWashedBackground()
            .sheet(isPresented: $showAttach) {
                JournalAttachSheet { attachment in
                    entry.attachments.append(attachment)
                }
            }
            .confirmationDialog("Entry not saved", isPresented: $showRespectAlert, titleVisibility: .visible) {
                Button("OK") {}
            } message: {
                Text("Please keep the journal Islamic and respectful.")
            }
        }
        .smallMediumSheetPresentation(startLarge: true)
    }

    /// Picking a kind on an untouched entry lays out its template; typed writing is never replaced.
    private func choose(_ kind: JournalKind) {
        let current = entry.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let untouched = current.isEmpty || current == (entry.kind.template ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        entry.kind = kind
        if untouched { entry.text = kind.template ?? "" }
    }
}

// MARK: - Attach

/// Carry something in: an ayah by reference, a bookmarked hadith, or a dua from the app's collections.
struct JournalAttachSheet: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranData = QuranData.shared
    @Environment(\.dismiss) private var dismiss

    let onPick: (JournalAttachment) -> Void

    @State private var reference = ""
    @State private var duaQuery = ""

    private var accent: Color { settings.accentColor.color }

    private var resolvedAyah: (surah: Surah, ayah: Ayah)? {
        let parts = reference.replacingOccurrences(of: " ", with: "").split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2, let surah = quranData.surah(parts[0]),
              let ayah = quranData.ayah(surah: parts[0], ayah: parts[1]) else { return nil }
        return (surah, ayah)
    }

    private var duaMatches: [DuaItem] {
        let query = duaQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        guard query.count >= 2 else { return [] }
        return Array(DuaView.allDuaItems.filter { $0.searchBlob.contains(query) }.prefix(12))
    }

    var body: some View {
        SheetNavigationContainer {
            List {
                Group {
                    Section(header: Text("AN AYAH"), footer: Text("Type the reference, surah:ayah.").font(.caption2)) {
                        TextField("2:255", text: $reference)
                            .keyboardType(.numbersAndPunctuation)
                        if let resolved = resolvedAyah {
                            Button {
                                settings.hapticFeedback()
                                onPick(JournalAttachment(
                                    kind: .ayah, refID: "\(resolved.surah.id):\(resolved.ayah.id)",
                                    title: "\(resolved.surah.nameTransliteration) \(resolved.surah.id):\(resolved.ayah.id)",
                                    arabic: resolved.ayah.displayArabicText(surahId: resolved.surah.id, clean: false, qiraahOverride: ""),
                                    body: resolved.ayah.textEnglishSaheeh, source: "Saheeh International"))
                                dismiss()
                            } label: {
                                VStack(alignment: .trailing, spacing: 6) {
                                    Text(resolved.ayah.displayArabicText(surahId: resolved.surah.id, clean: false, qiraahOverride: ""))
                                        .font(.custom(settings.quranArabicFontName(for: nil), size: 22))
                                        .arabicFontDesign(custom: true)
                                        .multilineTextAlignment(.trailing)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                    Text(resolved.ayah.textEnglishSaheeh)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Label("Attach this ayah", systemImage: "paperclip")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(accent)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    let bookmarks = HadithUserData.shared.bookmarks
                    if !bookmarks.isEmpty {
                        Section(header: SectionPillHeader(title: "BOOKMARKED HADITHS", count: bookmarks.count)) {
                            ForEach(bookmarks.prefix(40)) { bookmark in
                                Button {
                                    settings.hapticFeedback()
                                    onPick(JournalAttachment(
                                        kind: .hadith, refID: "\(bookmark.slug):\(bookmark.idInBook)",
                                        title: bookmark.reference, subtitle: bookmark.displayNumber,
                                        arabic: bookmark.arabicPreview ?? "",
                                        body: bookmark.englishPreview ?? bookmark.preview))
                                    dismiss()
                                } label: {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(bookmark.reference)
                                            .font(.caption.weight(.semibold))
                                            .foregroundColor(accent)
                                        Text(bookmark.englishPreview ?? bookmark.preview)
                                            .font(.footnote)
                                            .foregroundColor(.primary)
                                            .lineLimit(3)
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Section(header: Text("A DUA"), footer: Text("Search the app's dua collections.").font(.caption2)) {
                        TextField("Search duas", text: $duaQuery)
                        ForEach(duaMatches) { dua in
                            Button {
                                settings.hapticFeedback()
                                onPick(JournalAttachment(kind: .dua, refID: dua.id, title: "Dua",
                                                         arabic: dua.arabicText, body: dua.translation, source: dua.reference ?? ""))
                                dismiss()
                            } label: {
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(dua.arabicText)
                                        .font(.custom(settings.nonQuranArabicFontName, size: 20))
                                        .arabicFontDesign(custom: true)
                                        .multilineTextAlignment(.trailing)
                                        .lineLimit(2)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                    Text(dua.translation)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .themedListRowBackground()
            }
            .applyConditionalListStyle(disableNowPlayingInset: true)
            .compactListSectionSpacing()
            .navigationTitle("Attach")
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
            .accentWashedBackground()
        }
        .smallMediumSheetPresentation(startLarge: true)
    }
}
#endif
