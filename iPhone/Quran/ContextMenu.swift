import SwiftUI

/// The one format every ayah sheet titles itself with: "Surah Name S:A" (or "Surah Name S:A-B" for a sheet
/// that covers a range, e.g. a tafsir that groups several ayahs). Kept in a single helper so the sheets can
/// never drift apart again ("Preview", "Qiraah Comparison", ... all used to invent their own).
func ayahSheetTitle(surahNumber: Int, ayahNumber: Int, endAyah: Int? = nil) -> String {
    let name = QuranData.shared.surah(surahNumber)?.nameTransliteration ?? "Surah"
    if let endAyah, endAyah > ayahNumber {
        return "\(name) \(surahNumber):\(ayahNumber)-\(endAyah)"
    }
    return "\(name) \(surahNumber):\(ayahNumber)"
}

/// The English translation currently being shown, by name - so ayah sheets can mention it consistently.
/// Mirrors the reader's own precedence (Saheeh unless only Mustafa is enabled).
func currentTranslationDisplayName() -> String {
    let settings = Settings.shared
    return (settings.showEnglishSaheeh || !settings.showEnglishMustafa)
        ? "Saheeh International"
        : "Clear Quran (Mustafa Khattab)"
}

/// The ayah's text in the currently-shown English translation (same precedence as the name above), or nil
/// when translations don't apply (non-Hafs display) or the text is empty. This is what ayah sheets show
/// under the reference - the actual translation, not just its name.
func currentTranslationText(for ayah: Ayah) -> String? {
    let settings = Settings.shared
    guard settings.isHafsDisplay else { return nil }
    let text = (settings.showEnglishSaheeh || !settings.showEnglishMustafa)
        ? ayah.textEnglishSaheeh
        : ayah.textEnglishMustafa
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
}

struct SurahContextMenu: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject var quranData = QuranData.shared
    @ObservedObject var quranPlayer = QuranPlayer.shared

    let surahID: Int
    let surahName: String

    let favoriteSurahs: Set<Int>

    @Binding var searchText: String
    @Binding var scrollToSurahID: Int

    var lastListened: Bool?

    private var isFavorite: Bool {
        favoriteSurahs.contains(surahID)
    }

    private var canAddToQueue: Bool {
        quranPlayer.isPlaying || quranPlayer.isPaused
    }

    var body: some View {
        #if os(iOS)
        if let surah = quranData.surah(surahID) {
            Button {
                settings.hapticFeedback()
                FocusOverlayPresenter.shared.present(.surah(surah))
            } label: {
                Label("View Fullscreen", systemImage: "arrow.up.left.and.arrow.down.right")
            }

            Button {
                settings.hapticFeedback()
                presentSystemShareSheet(items: [FocusItem.surah(surah).shareText])
            } label: {
                Label("Share Surah", systemImage: "square.and.arrow.up")
            }

            Divider()
        }
        #endif

        Button(role: isFavorite ? .destructive : .cancel) {
            settings.hapticFeedback()
            withAnimation(.easeInOut) {
                settings.toggleSurahFavorite(surah: surahID)
            }
        } label: {
            Label(
                isFavorite ? "Unfavorite Surah" : "Favorite Surah",
                systemImage: isFavorite ? "star.fill" : "star"
            )
        }

        Button {
            settings.hapticFeedback()

            if let surah = quranData.surah(surahID) {
                if let randomAyah = surah.ayahs.randomElement() {
                    quranPlayer.playAyah(
                        surahNumber: surahID,
                        ayahNumber: randomAyah.id,
                        continueRecitation: true
                    )
                }
            }
        } label: {
            Label("Play Random Ayah", systemImage: "shuffle.circle")
        }

        if lastListened == nil {
            Button {
                settings.hapticFeedback()

                quranPlayer.playSurah(surahNumber: surahID, surahName: surahName)
            } label: {
                Label("Play Surah", systemImage: "play.fill")
            }
        }

        if canAddToQueue {
            Button {
                settings.hapticFeedback()
                quranPlayer.addSurahToQueue(surahNumber: surahID, surahName: surahName)
            } label: {
                Label("Add to Queue", systemImage: "text.line.last.and.arrowtriangle.forward")
            }
        }

        Button {
            settings.hapticFeedback()

            withAnimation {
                searchText = ""
                scrollToSurahID = surahID
                self.endEditing()
            }
        } label: {
            Text("Scroll To Surah")
            Image(systemName: "arrow.down.circle")
        }
    }
}

#if os(iOS)
private enum TafsirAuthor: String, CaseIterable, Identifiable {
    // English (quranapi.pages.dev - all three arrive in one response).
    case ibnKathir = "Ibn Kathir"
    case maarifUlQuran = "Maarif Ul Quran"
    case tazkirulQuran = "Tazkirul Quran"
    // Arabic (spa5k/tafsir_api via the jsDelivr CDN - one file per ayah per edition).
    case ibnKathirArabic = "Tafsir Ibn Kathir (Arabic)"
    case tabariArabic = "Tafsir al-Tabari (Arabic)"
    case saadiArabic = "Tafsir as-Sa'di (Arabic)"

    var id: String { rawValue }

    /// The spa5k edition slug for Arabic tafsirs; nil for the English bundle.
    var arabicSlug: String? {
        switch self {
        case .ibnKathirArabic: return "ar-tafsir-ibn-kathir"
        case .tabariArabic:    return "ar-tafsir-al-tabari"
        case .saadiArabic:     return "ar-tafsir-as-saadi"
        default:               return nil
        }
    }

    var isArabic: Bool { arabicSlug != nil }

    static var englishCases: [TafsirAuthor] { allCases.filter { !$0.isArabic } }
    static var arabicCases: [TafsirAuthor] { allCases.filter { $0.isArabic } }

    var shortTitle: String {
        switch self {
        case .ibnKathir:       return "Ibn Kathir"
        case .maarifUlQuran:   return "Maarif"
        case .tazkirulQuran:   return "Tazkirul"
        case .ibnKathirArabic: return "ابن كثير"
        case .tabariArabic:    return "الطبري"
        case .saadiArabic:     return "السعدي"
        }
    }

    /// The heading shown above the tafsir body.
    var displayTitle: String {
        switch self {
        case .ibnKathirArabic: return "تفسير ابن كثير"
        case .tabariArabic:    return "تفسير الطبري"
        case .saadiArabic:     return "تفسير السعدي"
        default:               return rawValue
        }
    }

    func matches(_ author: String) -> Bool {
        normalized(author) == normalized(rawValue)
    }

    private func normalized(_ text: String) -> String {
        text
            .lowercased()
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: " ", with: "")
    }
}

/// The standard "this content comes from the Internet" card, shared by the tafsir sheet and the online
/// translation comparison so online-backed sheets all disclose it the same way.
struct OnlineNoticeCard: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Loaded from the Internet", systemImage: "icloud.and.arrow.down")
                .font(.subheadline.weight(.semibold))

            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.1))
        )
    }
}

private struct AyahTafsirResponse: Decodable {
    let surahName: String
    let surahNo: Int
    let ayahNo: Int
    let tafsirs: [AyahTafsirEntry]
}

private struct AyahTafsirEntry: Decodable, Identifiable {
    let author: String
    let groupVerse: String?
    let content: String

    var id: String { author }
}

/// One spa5k per-ayah file: `tafsir/{slug}/{surah}/{ayah}.json` -> `{"text": "..."}` (plain text with
/// blank-line paragraph breaks, which the markdown block renderer already handles).
private struct SpaTafsirAyahResponse: Decodable {
    let text: String
}

/// The tafsir data layer: a disk + memory cache over quranapi.pages.dev, shared by every tafsir sheet, plus
/// the "Download All Tafsirs" sweep.
///
/// Before this existed, each sheet presentation owned its own StateObject and re-fetched from the network on
/// every open - THAT was the "why is it redownloading?!" refresh. Fetched responses now persist in
/// Application Support (excluded from iCloud backup - it's re-downloadable content), so an ayah's tafsir is
/// fetched from the network exactly once, ever.
@MainActor
final class TafsirStore: ObservableObject {
    static let shared = TafsirStore()
    private init() {}

    // Download progress, published for the settings rows. One sweep runs at a time; a sweep may cover
    // several targets in sequence (e.g. "Download Everything").
    @Published private(set) var isDownloading = false
    @Published private(set) var downloadingTargetName = ""
    @Published private(set) var downloadCompleted = 0
    @Published private(set) var downloadTotal = 0
    @Published private(set) var downloadBytes: Int64 = 0
    @Published var downloadError: String?
    /// Per-target disk usage (files, bytes), keyed by `TafsirDownloadTarget.rawValue`. Refreshed by
    /// `refreshDiskUsage()`.
    @Published private(set) var diskUsage: [String: (files: Int, bytes: Int64)] = [:]

    private let memory: NSCache<NSString, NSData> = {
        let cache = NSCache<NSString, NSData>()
        cache.countLimit = 48
        return cache
    }()
    private var downloadTask: Task<Void, Never>?

    private nonisolated static let directory: URL = {
        let base = (try? FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        )) ?? FileManager.default.temporaryDirectory
        var dir = base.appendingPathComponent("TafsirCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? dir.setResourceValues(values)
        return dir
    }()

    /// English bundle responses live flat in the cache root (the original layout); each Arabic edition gets
    /// its own subfolder so it can be sized and deleted independently.
    private nonisolated static func fileURL(editionSlug: String?, surah: Int, ayah: Int) -> URL {
        guard let slug = editionSlug else {
            return directory.appendingPathComponent("\(surah)_\(ayah).json")
        }
        let dir = directory.appendingPathComponent(slug, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("\(surah)_\(ayah).json")
    }

    private nonisolated static func endpoint(editionSlug: String?, surah: Int, ayah: Int) -> URL? {
        if let slug = editionSlug {
            return URL(string: "https://cdn.jsdelivr.net/gh/spa5k/tafsir_api@main/tafsir/\(slug)/\(surah)/\(ayah).json")
        }
        return URL(string: "https://quranapi.pages.dev/api/tafsir/\(surah)_\(ayah).json")
    }

    /// Cache-first: memory, then disk, then network (writing back to both). Only the network branch can throw.
    /// `editionSlug` nil = the English bundle; a spa5k slug = that Arabic edition's per-ayah file.
    func data(editionSlug: String? = nil, surah: Int, ayah: Int) async throws -> Data {
        let key = "\(editionSlug ?? "en")_\(surah)_\(ayah)" as NSString
        if let hit = memory.object(forKey: key) {
            return hit as Data
        }

        let file = Self.fileURL(editionSlug: editionSlug, surah: surah, ayah: ayah)
        if let disk = await Task.detached(priority: .userInitiated, operation: { try? Data(contentsOf: file) }).value {
            memory.setObject(disk as NSData, forKey: key)
            return disk
        }

        guard let remote = Self.endpoint(editionSlug: editionSlug, surah: surah, ayah: ayah) else { throw URLError(.badURL) }
        let (data, response) = try await URLSession.shared.data(from: remote)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        memory.setObject(data as NSData, forKey: key)
        Task.detached(priority: .utility) {
            try? data.write(to: file, options: .atomic)
        }
        return data
    }

    /// Sweep the given targets' every-ayah files into the disk cache, one target after another. Skips files
    /// already downloaded, fetches the rest with bounded concurrency, and is cancellable. Individual failures
    /// are skipped (rerun to fill gaps).
    func startDownload(targets: [TafsirDownloadTarget]) {
        guard !isDownloading, !targets.isEmpty else { return }
        let pairs = QuranData.shared.quran.flatMap { surah in
            surah.ayahs.map { (surah: surah.id, ayah: $0.id) }
        }
        guard !pairs.isEmpty else { return }

        isDownloading = true
        downloadError = nil
        downloadTask = Task { [weak self] in
            var totalFailures = 0

            for target in targets {
                if Task.isCancelled { break }
                guard let self else { return }

                self.downloadingTargetName = target.displayName
                self.downloadTotal = pairs.count
                self.downloadCompleted = 0
                self.downloadBytes = 0
                let slug = target.editionSlug

                // Inventory pass, off-main: what's already on disk counts as done.
                let missing = await Task.detached(priority: .userInitiated) { () -> [(surah: Int, ayah: Int)] in
                    var missing: [(surah: Int, ayah: Int)] = []
                    var have = 0
                    var bytes: Int64 = 0
                    for pair in pairs {
                        let file = Self.fileURL(editionSlug: slug, surah: pair.surah, ayah: pair.ayah)
                        if let size = (try? file.resourceValues(forKeys: [.fileSizeKey]))?.fileSize {
                            have += 1
                            bytes += Int64(size)
                        } else {
                            missing.append(pair)
                        }
                    }
                    let doneHave = have
                    let doneBytes = bytes
                    await MainActor.run {
                        self.downloadCompleted = doneHave
                        self.downloadBytes = doneBytes
                    }
                    return missing
                }.value

                // A modest window: fast enough to finish in minutes, polite enough not to hammer the CDN.
                let windowSize = 6
                var index = 0
                while index < missing.count, !Task.isCancelled {
                    let window = Array(missing[index..<min(index + windowSize, missing.count)])
                    index += window.count

                    await withTaskGroup(of: Int64?.self) { group in
                        for pair in window {
                            group.addTask {
                                guard !Task.isCancelled,
                                      let url = Self.endpoint(editionSlug: slug, surah: pair.surah, ayah: pair.ayah) else { return nil }
                                guard let (data, response) = try? await URLSession.shared.data(from: url),
                                      let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                                    return nil
                                }
                                try? data.write(to: Self.fileURL(editionSlug: slug, surah: pair.surah, ayah: pair.ayah), options: .atomic)
                                return Int64(data.count)
                            }
                        }
                        for await bytes in group {
                            if let bytes {
                                self.downloadCompleted += 1
                                self.downloadBytes += bytes
                            } else {
                                totalFailures += 1
                            }
                        }
                    }
                }
            }

            guard let self else { return }
            if totalFailures > 0, !Task.isCancelled {
                self.downloadError = "\(totalFailures) ayahs failed to download. Run the download again to retry them."
            }
            self.isDownloading = false
            self.downloadingTargetName = ""
            self.refreshDiskUsage()
        }
    }

    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        isDownloading = false
        downloadingTargetName = ""
    }

    /// Delete one target's saved files (or all of them when `target` is nil).
    func deleteDownloads(target: TafsirDownloadTarget? = nil) {
        if target == nil { cancelDownload() }
        memory.removeAllObjects()
        Task.detached(priority: .utility) { [weak self] in
            let fm = FileManager.default
            if let target {
                if let slug = target.editionSlug {
                    try? fm.removeItem(at: Self.directory.appendingPathComponent(slug, isDirectory: true))
                } else {
                    // English bundle = the flat .json files in the cache root.
                    let contents = (try? fm.contentsOfDirectory(at: Self.directory, includingPropertiesForKeys: [.isDirectoryKey])) ?? []
                    for file in contents where (try? file.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory != true {
                        try? fm.removeItem(at: file)
                    }
                }
            } else {
                let contents = (try? fm.contentsOfDirectory(at: Self.directory, includingPropertiesForKeys: nil)) ?? []
                for file in contents {
                    try? fm.removeItem(at: file)
                }
            }
            await self?.refreshDiskUsage()
        }
    }

    func refreshDiskUsage() {
        Task.detached(priority: .utility) { [weak self] in
            func usage(of dir: URL, filesOnly: Bool) -> (files: Int, bytes: Int64) {
                let contents = (try? FileManager.default.contentsOfDirectory(
                    at: dir, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey]
                )) ?? []
                var files = 0
                var bytes: Int64 = 0
                for url in contents {
                    let values = try? url.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
                    if values?.isDirectory == true { continue }
                    files += 1
                    bytes += Int64(values?.fileSize ?? 0)
                }
                return (files, bytes)
            }

            var result: [String: (files: Int, bytes: Int64)] = [:]
            for target in TafsirDownloadTarget.allCases {
                if let slug = target.editionSlug {
                    result[target.rawValue] = usage(of: Self.directory.appendingPathComponent(slug, isDirectory: true), filesOnly: true)
                } else {
                    result[target.rawValue] = usage(of: Self.directory, filesOnly: true)
                }
            }
            let finalResult = result
            await MainActor.run { [weak self] in
                self?.diskUsage = finalResult
            }
        }
    }
}

/// One downloadable tafsir package: the English bundle (all 3 authors arrive together from quranapi) or a
/// single Arabic edition (spa5k, one file per ayah).
enum TafsirDownloadTarget: String, CaseIterable, Identifiable {
    case english
    case ibnKathirArabic
    case tabariArabic
    case saadiArabic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english:         return "English (Ibn Kathir, Maarif, Tazkirul)"
        case .ibnKathirArabic: return "Tafsir Ibn Kathir (Arabic)"
        case .tabariArabic:    return "Tafsir al-Tabari (Arabic)"
        case .saadiArabic:     return "Tafsir as-Sa'di (Arabic)"
        }
    }

    /// nil = the English bundle endpoint; otherwise the spa5k edition slug.
    var editionSlug: String? {
        switch self {
        case .english:         return nil
        case .ibnKathirArabic: return "ar-tafsir-ibn-kathir"
        case .tabariArabic:    return "ar-tafsir-al-tabari"
        case .saadiArabic:     return "ar-tafsir-as-saadi"
        }
    }

    var isArabic: Bool { editionSlug != nil }

    /// Measured against the live sources (uncompressed on disk).
    var estimatedMegabytes: Int {
        switch self {
        case .english:         return 135
        case .ibnKathirArabic: return 90
        case .tabariArabic:    return 105
        case .saadiArabic:     return 15
        }
    }

    static var englishTargets: [TafsirDownloadTarget] { allCases.filter { !$0.isArabic } }
    static var arabicTargets: [TafsirDownloadTarget] { allCases.filter { $0.isArabic } }

    static func estimatedTotal(_ targets: [TafsirDownloadTarget]) -> Int {
        targets.reduce(0) { $0 + $1.estimatedMegabytes }
    }
}

@MainActor
private final class AyahTafsirViewModel: ObservableObject {
    @Published private(set) var tafsirs: [AyahTafsirEntry] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    /// Arabic editions load one at a time, on selection - separate flags so an Arabic fetch never swaps the
    /// whole sheet into the loading skeleton.
    @Published private(set) var isLoadingArabic = false
    @Published var arabicErrorMessage: String?

    private let surah: Int
    private let ayah: Int
    private var loadedKey: String?
    private var loadedArabicSlugs: Set<String> = []

    init(surah: Int, ayah: Int) {
        self.surah = surah
        self.ayah = ayah
    }

    func loadIfNeeded() async {
        await load(surah: surah, ayah: ayah)
    }

    func hasEntry(for author: TafsirAuthor) -> Bool {
        tafsirs.contains { author.matches($0.author) }
    }

    /// Fetch one Arabic edition's tafsir for this ayah (cache-first via TafsirStore) and append it to
    /// `tafsirs` under the author's rawValue, so the existing selection/matching machinery just works.
    func loadArabicIfNeeded(_ author: TafsirAuthor) async {
        guard let slug = author.arabicSlug,
              !loadedArabicSlugs.contains(slug),
              !isLoadingArabic else { return }

        isLoadingArabic = true
        arabicErrorMessage = nil

        do {
            // Unstructured Task: the page reader rebuilds its hosting view mid-flight, which cancels the
            // sheet's `.task` - without this wrapper that cancellation reached into URLSession and every
            // page-mode tafsir died with "Cancelled". The fetch now survives the view churn.
            let surah = self.surah, ayah = self.ayah
            let data = try await Task { try await TafsirStore.shared.data(editionSlug: slug, surah: surah, ayah: ayah) }.value
            let decoded = try JSONDecoder().decode(SpaTafsirAyahResponse.self, from: data)
            let text = decoded.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                tafsirs.append(AyahTafsirEntry(author: author.rawValue, groupVerse: nil, content: text))
            }
            loadedArabicSlugs.insert(slug)
        } catch {
            // Cancellation is view-lifecycle noise, not a failure - the next `.task` run retries silently.
            if !Self.isCancellation(error) {
                arabicErrorMessage = error.localizedDescription
            }
        }

        isLoadingArabic = false
    }

    /// True for the errors a torn-down SwiftUI task produces - never worth showing to the reader.
    static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        if let urlError = error as? URLError, urlError.code == .cancelled { return true }
        return (error as NSError).code == NSURLErrorCancelled
    }

    func load(surah: Int, ayah: Int) async {
        let key = "\(surah)-\(ayah)"
        if loadedKey == key, !tafsirs.isEmpty { return }
        if isLoading { return }

        isLoading = true
        errorMessage = nil

        do {
            // Cache-first through the shared store: an ayah whose tafsir was ever fetched (or bulk-downloaded)
            // loads instantly and offline; only a true first look hits the network. The unstructured Task
            // insulates the fetch from the page reader cancelling the sheet's `.task` mid-flight.
            let data = try await Task { try await TafsirStore.shared.data(surah: surah, ayah: ayah) }.value
            let decoded = try JSONDecoder().decode(AyahTafsirResponse.self, from: data)
            tafsirs = decoded.tafsirs
            loadedKey = key
        } catch {
            if !Self.isCancellation(error) {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }
}

struct AyahTafsirSheet: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject var quranData = QuranData.shared
    @Environment(\.dismiss) private var dismiss

    let surahName: String
    let surahNumber: Int
    let ayahNumber: Int

    @StateObject private var viewModel: AyahTafsirViewModel
    @State private var searchText = ""
    @State private var searchMatches: [(block: Int, occurrence: Int)] = []
    @State private var currentMatchIndex = 0
    @AppStorage("quran.tafsir.author") private var selectedAuthorRawValue = TafsirAuthor.ibnKathir.rawValue

    init(surahName: String, surahNumber: Int, ayahNumber: Int) {
        self.surahName = surahName
        self.surahNumber = surahNumber
        self.ayahNumber = ayahNumber
        _viewModel = StateObject(wrappedValue: AyahTafsirViewModel(surah: surahNumber, ayah: ayahNumber))
    }

    private var selectedAuthor: TafsirAuthor {
        get { TafsirAuthor(rawValue: selectedAuthorRawValue) ?? .ibnKathir }
        nonmutating set { selectedAuthorRawValue = newValue.rawValue }
    }

    private var selectedAuthorBinding: Binding<TafsirAuthor> {
        Binding(
            get: { selectedAuthor },
            set: { selectedAuthor = $0 }
        )
    }

    /// Language toggle backing: flipping languages jumps to the counterpart author (Ibn Kathir stays Ibn
    /// Kathir across the flip; the others land on their language's first author).
    private var languageBinding: Binding<Bool> {
        Binding(
            get: { selectedAuthor.isArabic },
            set: { wantsArabic in
                guard wantsArabic != selectedAuthor.isArabic else { return }
                if wantsArabic {
                    selectedAuthor = selectedAuthor == .ibnKathir ? .ibnKathirArabic : (TafsirAuthor.arabicCases.first ?? .ibnKathirArabic)
                } else {
                    selectedAuthor = selectedAuthor == .ibnKathirArabic ? .ibnKathir : (TafsirAuthor.englishCases.first ?? .ibnKathir)
                }
            }
        )
    }

    private var loadKey: String {
        "\(surahNumber):\(ayahNumber)"
    }

    private var selectedTafsirEntry: AyahTafsirEntry? {
        if let match = viewModel.tafsirs.first(where: { selectedAuthor.matches($0.author) }) {
            return match
        }
        // An Arabic edition that hasn't loaded yet shows its own loading row - falling back to an English
        // entry here would flash the wrong tafsir under an Arabic heading.
        return selectedAuthor.isArabic ? nil : viewModel.tafsirs.first
    }

    private var selectedTafsirText: String? {
        selectedTafsirEntry?.content
    }

    private var hasActiveSearch: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var currentMatch: (block: Int, occurrence: Int)? {
        searchMatches.indices.contains(currentMatchIndex) ? searchMatches[currentMatchIndex] : nil
    }

    private func recomputeMatches(scrollProxy: ScrollViewProxy?) {
        searchMatches = TafsirMarkdownView.searchMatches(markdown: selectedTafsirText ?? "", query: searchText)
        currentMatchIndex = 0
        if let scrollProxy, let first = searchMatches.first {
            scrollToMatch(first, proxy: scrollProxy)
        }
    }

    private func goToMatch(_ delta: Int, proxy: ScrollViewProxy) {
        guard !searchMatches.isEmpty else { return }
        currentMatchIndex = (currentMatchIndex + delta + searchMatches.count) % searchMatches.count
        scrollToMatch(searchMatches[currentMatchIndex], proxy: proxy)
    }

    private func scrollToMatch(_ match: (block: Int, occurrence: Int), proxy: ScrollViewProxy) {
        withAnimation { proxy.scrollTo(tafsirBlockScrollID(match.block), anchor: .center) }
    }

    /// The reader's display text for one of the card's ayahs: clean/no-dots per settings, beginner
    /// letter spacing when on - the same string an AyahRow would show.
    private func tafsirArabicDisplay(_ ayah: Ayah) -> String {
        let text = ayah.displayArabicText(surahId: surahNumber, clean: settings.cleanArabicText, qiraahOverride: settings.displayQiraahForArabic)
        return settings.beginnerMode ? text.map { String($0) }.joined(separator: " ") : text
    }

    /// Tajweed-colored attributed text for the card, when tajweed is on and the display is Hafs.
    private func tafsirTajweedText(_ ayah: Ayah) -> AttributedString? {
        guard settings.showTajweedColors, settings.showArabicText, settings.isHafsDisplay else { return nil }
        let text = ayah.displayArabicText(surahId: surahNumber, clean: false)
        let displayText = settings.cleanArabicText ? ayah.displayArabicText(surahId: surahNumber, clean: true) : text
        let rendered = settings.beginnerMode ? displayText.map { String($0) }.joined(separator: " ") : displayText
        return TajweedStore.shared.attributedText(
            surah: surahNumber,
            ayah: ayah.id,
            text: text,
            displayText: rendered,
            cleanDisplayText: settings.cleanArabicText,
            beginnerSpacing: settings.beginnerMode
        )
    }

    private var tafsirAyahRange: ClosedRange<Int> {
        parsedAyahRange(from: selectedTafsirEntry?.groupVerse) ?? ayahNumber...ayahNumber
    }

    private var tafsirArabicAyahs: [Ayah] {
        quranData.surah(surahNumber)?.ayahs.filter {
            tafsirAyahRange.contains($0.id) && $0.existsInQiraah(settings.displayQiraahForArabic)
        } ?? []
    }

    private var tafsirRangeTitle: String {
        // Same reference format as every other ayah sheet (e.g. "Al-Baqarah 1:1-5"), so the tafsir card's
        // heading matches the page actions sheet and the rest.
        ayahSheetTitle(surahNumber: surahNumber, ayahNumber: tafsirAyahRange.lowerBound,
                       endAyah: tafsirAyahRange.upperBound == tafsirAyahRange.lowerBound ? nil : tafsirAyahRange.upperBound)
    }

    private func parsedAyahRange(from groupVerse: String?) -> ClosedRange<Int>? {
        guard let groupVerse else { return nil }
        let trimmed = groupVerse.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // The API sends a full SENTENCE: "You are reading a tafsir for the group of verses 27:15 to
        // 27:19". The old parse split on ":" and took the LAST piece - just "19" - which collapsed a
        // five-ayah group to one and mistitled the card ("27:19" for a tap on 16). Pull every
        // surah:ayah pair instead and span their AYAH numbers.
        var ayahNumbers: [Int] = []
        if let regex = try? NSRegularExpression(pattern: #"(\d{1,3})\s*:\s*(\d{1,3})"#) {
            let matches = regex.matches(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed))
            for match in matches {
                if let range = Range(match.range(at: 2), in: trimmed), let ayah = Int(trimmed[range]) {
                    ayahNumbers.append(ayah)
                }
            }
        }
        // No S:A pairs at all (some editions send bare numbers): fall back to every number present.
        if ayahNumbers.isEmpty {
            ayahNumbers = trimmed
                .components(separatedBy: CharacterSet.decimalDigits.inverted)
                .compactMap { Int($0) }
                .filter { $0 != surahNumber }   // a stray surah number isn't an ayah bound
        }
        guard var lower = ayahNumbers.min(), var upper = ayahNumbers.max() else { return nil }

        // The tapped ayah is, by definition, part of this tafsir's group - the shown range must
        // always contain it, whatever the sentence said.
        lower = min(lower, ayahNumber)
        upper = max(upper, ayahNumber)

        let maxAyah = quranData.surah(surahNumber)?.numberOfAyahs(for: settings.displayQiraahForArabic) ?? upper
        let clampedLower = min(max(lower, 1), maxAyah)
        let clampedUpper = min(max(upper, clampedLower), maxAyah)
        return clampedLower...clampedUpper
    }

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading && viewModel.tafsirs.isEmpty {
                    tafsirLoadingView
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else {
                    ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            noticeCard
                            arabicAyahsCard

                            // Two-level author choice: language first, then the three authors of that
                            // language - six segments in one control were unreadably cramped.
                            Picker("Language", selection: languageBinding.animation(.easeInOut)) {
                                Text("English").tag(false)
                                Text("العربية").tag(true)
                            }
                            .pickerStyle(.segmented)

                            Picker("Tafsir", selection: selectedAuthorBinding.animation(.easeInOut)) {
                                ForEach(selectedAuthor.isArabic ? TafsirAuthor.arabicCases : TafsirAuthor.englishCases) { author in
                                    Text(author.shortTitle).tag(author)
                                }
                            }
                            .pickerStyle(.segmented)
                            .animation(.easeInOut, value: selectedAuthor)
                            .onChange(of: selectedAuthor) { _ in settings.hapticFeedback() }

                            if let tafsirText = selectedTafsirText {
                                VStack(alignment: selectedAuthor.isArabic ? .trailing : .leading, spacing: 12) {
                                    Text(selectedAuthor.displayTitle)
                                        .font(.headline)
                                        .frame(maxWidth: .infinity, alignment: selectedAuthor.isArabic ? .trailing : .leading)

                                    tafsirContentView(for: tafsirText)
                                        .frame(maxWidth: .infinity, alignment: selectedAuthor.isArabic ? .trailing : .leading)
                                }
                                .frame(maxWidth: .infinity, alignment: selectedAuthor.isArabic ? .trailing : .leading)
                                .environment(\.layoutDirection, selectedAuthor.isArabic ? .rightToLeft : .leftToRight)
                                .id(selectedAuthor.rawValue)
                                .textSelection(.enabled)
                            } else if selectedAuthor.isArabic, viewModel.isLoadingArabic {
                                ProgressView("Loading tafsir...")
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 12)
                            } else if selectedAuthor.isArabic, let arabicError = viewModel.arabicErrorMessage {
                                tafsirPlaceholder(
                                    title: "Couldn't Load Tafsir",
                                    systemImage: "wifi.exclamationmark",
                                    message: arabicError
                                )
                            } else if let errorMessage = viewModel.errorMessage, !selectedAuthor.isArabic {
                                tafsirPlaceholder(
                                    title: "Couldn't Load Tafsir",
                                    systemImage: "wifi.exclamationmark",
                                    message: errorMessage
                                )
                            } else {
                                tafsirPlaceholder(
                                    title: "No Tafsir Found",
                                    systemImage: "text.book.closed",
                                    message: "No tafsir was returned for this ayah."
                                )
                            }
                        }
                        .padding()
                    }
                    .safeAreaInset(edge: .bottom) {
                        if hasActiveSearch {
                            TafsirFindBar(
                                current: currentMatchIndex,
                                total: searchMatches.count,
                                onPrevious: { goToMatch(-1, proxy: proxy) },
                                onNext: { goToMatch(1, proxy: proxy) }
                            )
                        }
                    }
                    .onChange(of: searchText) { _ in recomputeMatches(scrollProxy: proxy) }
                    .onChange(of: selectedTafsirText) { _ in recomputeMatches(scrollProxy: nil) }
                    }
                }
            }
            // Title reflects the tafsir's FULL range: when the selected tafsir groups several ayahs (Ibn
            // Kathir often does) it reads e.g. "Al-Baqarah 1:1-5", not just the tapped ayah.
            .navigationTitle(ayahSheetTitle(surahNumber: surahNumber, ayahNumber: tafsirAyahRange.lowerBound, endAyah: tafsirAyahRange.upperBound))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText.animation(.easeInOut), prompt: "Search tafsir")
            .dismissKeyboardOnScroll()
            .sheetDismissToolbar()
        }
        .task(id: loadKey) {
            await viewModel.loadIfNeeded()
        }
        // The Arabic editions load one at a time, when selected (each is its own per-ayah file on the CDN).
        .task(id: "\(loadKey)|\(selectedAuthorRawValue)") {
            if selectedAuthor.isArabic {
                await viewModel.loadArabicIfNeeded(selectedAuthor)
            }
        }
    }

    private var noticeCard: some View {
        OnlineNoticeCard(text: "Tafsir is fetched online for the selected ayah or grouped ayahs, then saved on this device - an ayah you've opened before loads instantly and offline. English tafsirs load together; Arabic tafsirs (Ibn Kathir, al-Tabari, as-Sa'di) load per selection.")
    }

    // The same ayah-card format as the page actions sheet: Arabic first, then the "Name S:A" reference
    // caption, then the ayah's ACTUAL text in the active translation - not just the translation's name.
    private var arabicAyahsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if tafsirArabicAyahs.isEmpty {
                Text("Arabic ayah unavailable.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .trailing, spacing: 10) {
                    // Rendered exactly like the reader's own rows: the QURAN face, tajweed colors when
                    // on, clean-text / no-dots choices, and beginner letter spacing.
                    ForEach(tafsirArabicAyahs) { ayah in
                        HighlightedSnippet(
                            source: tafsirArabicDisplay(ayah),
                            term: "",
                            font: Font.arabic(settings.quranDisplayFontName, size: UIFont.preferredFont(forTextStyle: .title3).pointSize),
                            accent: settings.accentColor.color,
                            fg: .primary,
                            preStyledSource: tafsirTajweedText(ayah),
                            beginnerMode: settings.beginnerMode
                        )
                        .arabicFontDesign(custom: settings.quranDisplayUsesCustomArabicFace)
                        .multilineTextAlignment(.trailing)
                        .lineSpacing(6)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .environment(\.layoutDirection, .rightToLeft)
                    }
                }
            }

            VStack(alignment: .center, spacing: 3) {
                Text(tafsirRangeTitle)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                // The translation of every ayah the tafsir covers, numbered when it spans a range.
                let translations = tafsirArabicAyahs.compactMap { ayah -> String? in
                    guard let text = currentTranslationText(for: ayah) else { return nil }
                    return tafsirArabicAyahs.count > 1 ? "\(ayah.id). \(text)" : text
                }
                if !translations.isEmpty {
                    Text(translations.joined(separator: "\n"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .conditionalGlassEffect(rectangle: true, useColor: 0.08)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(settings.accentColor.color.opacity(0.18), lineWidth: 1)
        )
        .textSelection(.enabled)
        .animation(.easeInOut, value: tafsirRangeTitle)
    }

    @ViewBuilder
    private func tafsirContentView(for content: String) -> some View {
        TafsirMarkdownView(
            markdown: content,
            searchText: searchText,
            accent: settings.accentColor.color,
            textAlignment: selectedAuthor.isArabic ? .trailing : .leading,
            currentMatch: currentMatch
        )
    }

    private var tafsirLoadingView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                noticeCard

                ProgressView("Loading tafsir...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)

                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.18))
                    .frame(height: 32)
                    .overlay {
                        HStack(spacing: 8) {
                            Capsule().fill(Color.secondary.opacity(0.18))
                            Capsule().fill(Color.secondary.opacity(0.12))
                            Capsule().fill(Color.secondary.opacity(0.1))
                        }
                        .padding(4)
                    }

                ForEach(0..<4, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 10) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.16))
                            .frame(width: index == 0 ? 180 : 240, height: index == 0 ? 24 : 16)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.12))
                            .frame(height: 16)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.12))
                            .frame(height: 16)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.09))
                            .frame(width: index.isMultiple(of: 2) ? 260 : 220, height: 16)
                    }
                    .redacted(reason: .placeholder)
                }
            }
            .padding()
        }
    }

    private func tafsirPlaceholder(title: String, systemImage: String, message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

/// "About this Surah" sheet - bundled surah background, mirroring the Tafsir sheet: a source picker
/// (Maududi / Ibn Ashur), searchable content, and the same accent-foreground search match (no highlight box).
struct SurahInfoSheet: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject var quranData = QuranData.shared
    @Environment(\.dismiss) private var dismiss

    let surahName: String
    let surahNumber: Int

    @State private var searchText = ""
    @State private var searchMatches: [(block: Int, occurrence: Int)] = []
    @State private var currentMatchIndex = 0
    @AppStorage("quran.surahInfo.source") private var selectedSourceName = ""

    private var sources: [SurahInfoSource] {
        quranData.surahInfoSources(for: surahNumber)
    }

    private var selectedSource: SurahInfoSource? {
        sources.first(where: { $0.name == selectedSourceName }) ?? sources.first
    }

    private var selectedSourceBinding: Binding<String> {
        Binding(
            get: { selectedSource?.name ?? "" },
            set: { selectedSourceName = $0 }
        )
    }

    /// True when the text is mostly Arabic script, so the sheet can lay it out right-to-left.
    private static func isArabic(_ text: String) -> Bool {
        var arabic = 0, latin = 0
        for scalar in text.unicodeScalars {
            let v = scalar.value
            if (0x0600...0x06FF).contains(v) || (0x0750...0x077F).contains(v) || (0x08A0...0x08FF).contains(v) {
                arabic += 1
            } else if (0x41...0x5A).contains(v) || (0x61...0x7A).contains(v) {
                latin += 1
            }
        }
        return arabic > latin
    }

    private var hasActiveSearch: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var currentMatch: (block: Int, occurrence: Int)? {
        searchMatches.indices.contains(currentMatchIndex) ? searchMatches[currentMatchIndex] : nil
    }

    private func recomputeMatches(scrollProxy: ScrollViewProxy?) {
        searchMatches = TafsirMarkdownView.searchMatches(markdown: selectedSource?.contents ?? "", query: searchText)
        currentMatchIndex = 0
        if let scrollProxy, let first = searchMatches.first {
            scrollToMatch(first, proxy: scrollProxy)
        }
    }

    private func goToMatch(_ delta: Int, proxy: ScrollViewProxy) {
        guard !searchMatches.isEmpty else { return }
        currentMatchIndex = (currentMatchIndex + delta + searchMatches.count) % searchMatches.count
        scrollToMatch(searchMatches[currentMatchIndex], proxy: proxy)
    }

    private func scrollToMatch(_ match: (block: Int, occurrence: Int), proxy: ScrollViewProxy) {
        withAnimation { proxy.scrollTo(tafsirBlockScrollID(match.block), anchor: .center) }
    }

    var body: some View {
        NavigationView {
            Group {
                if sources.isEmpty {
                    infoPlaceholder
                } else {
                    ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            noticeCard
                            surahHeaderCard

                            if sources.count > 1 {
                                Picker("Source", selection: selectedSourceBinding.animation(.easeInOut)) {
                                    ForEach(sources) { source in
                                        Text(source.name).tag(source.name)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .animation(.easeInOut, value: selectedSource)
                                .onChange(of: selectedSourceName) { _ in settings.hapticFeedback() }
                            }

                            if let source = selectedSource {
                                let arabic = Self.isArabic(source.contents)
                                VStack(alignment: arabic ? .trailing : .leading, spacing: 12) {
                                    Text(source.name)
                                        .font(.headline)
                                        .frame(maxWidth: .infinity, alignment: arabic ? .trailing : .leading)

                                    TafsirMarkdownView(
                                        markdown: source.contents,
                                        searchText: searchText,
                                        accent: settings.accentColor.color,
                                        textAlignment: arabic ? .trailing : .leading,
                                        currentMatch: currentMatch
                                    )
                                    .frame(maxWidth: .infinity, alignment: arabic ? .trailing : .leading)
                                }
                                .frame(maxWidth: .infinity, alignment: arabic ? .trailing : .leading)
                                .id(source.name)
                                .textSelection(.enabled)
                            }
                        }
                        .padding()
                    }
                    .safeAreaInset(edge: .bottom) {
                        if hasActiveSearch {
                            TafsirFindBar(
                                current: currentMatchIndex,
                                total: searchMatches.count,
                                onPrevious: { goToMatch(-1, proxy: proxy) },
                                onNext: { goToMatch(1, proxy: proxy) }
                            )
                        }
                    }
                    .onChange(of: searchText) { _ in recomputeMatches(scrollProxy: proxy) }
                    .onChange(of: selectedSourceName) { _ in recomputeMatches(scrollProxy: nil) }
                    }
                }
            }
            .navigationTitle("Surah \(surahNumber): \(surahName)")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText.animation(.easeInOut), prompt: "Search info")
            .dismissKeyboardOnScroll()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                    }
                }
            }
        }
        .modifier(SheetPresentationModifier())
    }

    private var noticeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("About this Surah", systemImage: "book.closed")
                .font(.subheadline.weight(.semibold))

            Text("Background on this surah - its name, period of revelation, and themes. Switch between sources with the picker.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.1))
        )
    }

    @ViewBuilder
    private var surahHeaderCard: some View {
        if let surah = quranData.surah(surahNumber) {
            VStack(alignment: .leading, spacing: 10) {
                // Always show the full surah row details.
                SurahRow(surah: surah, hideInfo: false).equatable()

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Label("Revelation Info", systemImage: "book.closed")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(settings.accentColor.color)

                    Text("Revelation order: #\(surah.revelationOrder.map(String.init) ?? "Unknown")")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let exceptions = surah.revelationExceptions?.trimmingCharacters(in: .whitespacesAndNewlines),
                       !exceptions.isEmpty {
                        Text("Exceptions: \(exceptions)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Label("Your Stats", systemImage: "chart.bar")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(settings.accentColor.color)

                    Text("Opened: \(settings.surahOpenCount(surahNumber)) time\(settings.surahOpenCount(surahNumber) == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Played: \(settings.surahPlayCount(surahNumber)) time\(settings.surahPlayCount(surahNumber) == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .conditionalGlassEffect(rectangle: true, useColor: 0.08)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(settings.accentColor.color.opacity(0.18), lineWidth: 1)
            )
            .textSelection(.enabled)
        }
    }

    private var infoPlaceholder: some View {
        VStack(spacing: 10) {
            Image(systemName: "text.book.closed")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("No Info Found")
                .font(.headline)

            Text("No background information is available for this surah.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

/// Stable scroll id for the Nth render block of a `TafsirMarkdownView` (used by find-in-page navigation).
private func tafsirBlockScrollID(_ offset: Int) -> String { "tafsir-block-\(offset)" }

private struct TafsirMarkdownView: View {
    let markdown: String
    let searchText: String
    let accent: Color
    /// Text/line alignment for the rendered blocks. Pass `.trailing` for Arabic so it reads right-to-left.
    var textAlignment: TextAlignment = .leading
    /// The find-in-page "current" match as (render-block offset, occurrence index within that block); the
    /// matching occurrence gets a background box so the user can see which hit they're on.
    var currentMatch: (block: Int, occurrence: Int)? = nil

    private var frameAlignment: Alignment {
        switch textAlignment {
        case .leading:  return .leading
        case .center:   return .center
        case .trailing: return .trailing
        }
    }

    private var stackAlignment: HorizontalAlignment {
        switch textAlignment {
        case .leading:  return .leading
        case .center:   return .center
        case .trailing: return .trailing
        }
    }

    private var blocks: [TafsirMarkdownBlock] { Self.blocks(from: markdown) }

    static func normalizedMarkdown(_ markdown: String) -> String {
        markdown
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(
                of: #"(?m)^\\-\s+"#,
                with: "- ",
                options: .regularExpression
            )
    }

    /// Parsed blocks per tafsir text. `blocks` is read from `body` (and from search recomputes), which
    /// SwiftUI re-evaluates on every keystroke of the find bar - without this cache each evaluation re-ran a
    /// whole-document regex plus a split/trim/parse of every block, which is exactly the tafsir-sheet lag.
    private static let blocksCache: NSCache<NSString, TafsirBlocksBox> = {
        let cache = NSCache<NSString, TafsirBlocksBox>()
        cache.countLimit = 12
        return cache
    }()

    static func blocks(from markdown: String) -> [TafsirMarkdownBlock] {
        let key = markdown as NSString
        if let hit = blocksCache.object(forKey: key) {
            return hit.value
        }
        let parsed = normalizedMarkdown(markdown)
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map(TafsirMarkdownBlock.init(raw:))
        blocksCache.setObject(TafsirBlocksBox(parsed), forKey: key)
        return parsed
    }

    /// Document-order list of search matches, each as (render-block offset, occurrence index within block).
    /// Counting on the same `displayText` the highlighter searches keeps the count and the highlights in sync.
    static func searchMatches(markdown: String, query: String) -> [(block: Int, occurrence: Int)] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var matches: [(block: Int, occurrence: Int)] = []
        for (offset, block) in blocks(from: markdown).enumerated() {
            let text = block.displayText
            var start = text.startIndex
            var occurrence = 0
            while start < text.endIndex,
                  let found = text.range(
                    of: trimmed,
                    options: [.caseInsensitive, .diacriticInsensitive],
                    range: start..<text.endIndex
                  ) {
                matches.append((offset, occurrence))
                occurrence += 1
                start = found.upperBound
            }
        }
        return matches
    }

    var body: some View {
        VStack(alignment: stackAlignment, spacing: 14) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { item in
                let offset = item.offset
                let block = item.element
                let currentOccurrence = currentMatch?.block == offset ? currentMatch?.occurrence : nil

                Group {
                    switch block.kind {
                    case .heading:
                        Text(block.highlightedDisplayText(searchText: searchText, accent: accent, currentOccurrence: currentOccurrence))
                            .font(.title3.bold())
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: frameAlignment)
                    case .body:
                        if let attributed = block.attributedText(searchText: searchText, accent: accent, currentOccurrence: currentOccurrence) {
                            Text(attributed)
                                .frame(maxWidth: .infinity, alignment: frameAlignment)
                                .textSelection(.enabled)
                                .lineSpacing(5)
                        } else {
                            Text(block.displayText)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: frameAlignment)
                                .textSelection(.enabled)
                                .lineSpacing(5)
                        }
                    }
                }
                .id(tafsirBlockScrollID(offset))
            }
        }
        .frame(maxWidth: .infinity, alignment: frameAlignment)
        .multilineTextAlignment(textAlignment)
        .textSelection(.enabled)
    }
}

/// Class boxes so parsed value-type results can live in an NSCache.
private final class TafsirBlocksBox {
    let value: [TafsirMarkdownBlock]
    init(_ value: [TafsirMarkdownBlock]) { self.value = value }
}

private final class TafsirAttributedBox {
    let value: AttributedString
    init(_ value: AttributedString) { self.value = value }
}

private struct TafsirMarkdownBlock {
    enum Kind {
        case heading
        case body
    }

    let kind: Kind
    let rawText: String
    /// Computed once at init - this used to be a computed var running a regex on EVERY access, and it is
    /// accessed several times per block per render.
    let displayText: String

    init(raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.hasPrefix("## ") {
            kind = .heading
            rawText = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
        } else if trimmed.hasPrefix("# ") {
            kind = .heading
            rawText = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            kind = .body
            rawText = trimmed
        }
        displayText = rawText.replacingOccurrences(of: #"\\-"#, with: "-", options: .regularExpression)
    }

    /// The markdown parse is the expensive part (AttributedString(markdown:) on every block of a long Ibn
    /// Kathir entry), and it doesn't depend on the search state - so parse each block once, cache it, and
    /// apply the (cheap) search highlight to a value-copy per render.
    private static let baseParseCache: NSCache<NSString, TafsirAttributedBox> = {
        let cache = NSCache<NSString, TafsirAttributedBox>()
        cache.countLimit = 400
        return cache
    }()

    private func baseAttributed() -> AttributedString? {
        guard kind == .body else { return nil }
        let key = displayText as NSString
        if let hit = Self.baseParseCache.object(forKey: key) {
            return hit.value
        }
        guard var attributed = try? AttributedString(markdown: displayText) else { return nil }
        for run in attributed.runs {
            if let intent = run.inlinePresentationIntent, intent.contains(.code) {
                attributed[run.range].inlinePresentationIntent = nil
            }
        }
        Self.baseParseCache.setObject(TafsirAttributedBox(attributed), forKey: key)
        return attributed
    }

    func attributedText(searchText: String, accent: Color, currentOccurrence: Int? = nil) -> AttributedString? {
        guard var attributed = baseAttributed() else { return nil }
        applySearchHighlight(to: &attributed, searchText: searchText, accent: accent, currentOccurrence: currentOccurrence)
        return attributed
    }

    func highlightedDisplayText(searchText: String, accent: Color, currentOccurrence: Int? = nil) -> AttributedString {
        var attributed = AttributedString(displayText)
        applySearchHighlight(to: &attributed, searchText: searchText, accent: accent, currentOccurrence: currentOccurrence)
        return attributed
    }

    private func applySearchHighlight(to attributed: inout AttributedString, searchText: String, accent: Color, currentOccurrence: Int?) {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var searchStart = displayText.startIndex
        var occurrence = 0
        while searchStart < displayText.endIndex,
              let found = displayText.range(
                of: trimmed,
                options: [.caseInsensitive, .diacriticInsensitive],
                range: searchStart..<displayText.endIndex
              ) {
            if let lower = AttributedString.Index(found.lowerBound, within: attributed),
               let upper = AttributedString.Index(found.upperBound, within: attributed) {
                // Tint every match with the accent foreground; the find-in-page "current" match also gets a
                // soft background box so the user can see which hit the up/down arrows landed on.
                attributed[lower..<upper].foregroundColor = accent
                if occurrence == currentOccurrence {
                    attributed[lower..<upper].backgroundColor = accent.opacity(0.25)
                }
            }
            occurrence += 1
            searchStart = found.upperBound
        }
    }
}

/// Find-in-page control bar: "current/total" plus up/down arrows, styled to match the app. Shown over the
/// Tafsir / Surah Info sheets while a search query is active.
private struct TafsirFindBar: View {
    @ObservedObject var settings = Settings.shared

    let current: Int   // 0-based index of the active match
    let total: Int
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: 18) {
            Text(total == 0 ? "0/0" : "\(current + 1)/\(total)")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(total == 0 ? .secondary : .primary)

            Button {
                settings.hapticFeedback()
                onPrevious()
            } label: {
                Image(systemName: "chevron.up")
                    .font(.body.weight(.semibold))
            }
            .disabled(total == 0)

            Button {
                settings.hapticFeedback()
                onNext()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.body.weight(.semibold))
            }
            .disabled(total == 0)
        }
        .foregroundStyle(settings.accentColor.color)
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .conditionalGlassEffect(rectangle: true)
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct AyahQiraahComparisonSheet: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject var quranData = QuranData.shared
    @Environment(\.dismiss) private var dismiss

    let surahNumber: Int
    let ayahNumber: Int
    @State private var searchText = ""
    // Comparing scripts is exactly when you want the text bigger; the slider only affects this sheet.
    @State private var arabicFontSize: Double = Double(UIFont.preferredFont(forTextStyle: .title3).pointSize)

    private struct QiraahDisplay: Identifiable {
        let label: String
        let tag: String
        let arabicCaption: String
        let teacher: String
        let teacherArabic: String
        let order: Int

        var id: String { tag.isEmpty ? "Hafs" : tag }
    }

    private var options: [QiraahDisplay] {
        Settings.Riwayah.options.map {
            QiraahDisplay(
                label: $0.label,
                tag: $0.tag,
                arabicCaption: $0.arabic,
                teacher: $0.teacher,
                teacherArabic: $0.teacherArabic,
                order: $0.order
            )
        }
    }

    private var favoriteOptions: [QiraahDisplay] {
        filteredOptions.filter { settings.isQiraahFavorite(tag: $0.tag) }
            .sorted { $0.order < $1.order }
    }

    private var groupedOptions: [(teacher: String, teacherArabic: String, options: [QiraahDisplay])] {
        Settings.Riwayah.groups.compactMap { group in
            let rows = filteredOptions
                .filter { $0.teacher == group.teacher && !settings.isQiraahFavorite(tag: $0.tag) }
                .sorted { $0.order < $1.order }
            guard !rows.isEmpty else { return nil }
            return (group.teacher, group.teacherArabic, rows)
        }
    }

    private var filteredOptions: [QiraahDisplay] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return options }
        return options.filter { option in
            option.label.localizedCaseInsensitiveContains(query) ||
            option.arabicCaption.localizedCaseInsensitiveContains(query) ||
            option.teacher.localizedCaseInsensitiveContains(query) ||
            option.teacherArabic.localizedCaseInsensitiveContains(query) ||
            (qiraahText(for: option)?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    // The riwayah the reader is currently displaying - pinned above the list so every row can be compared
    // against it without scrolling back up.
    private var currentOption: QiraahDisplay? {
        let tag = Settings.normalizeLegacyRiwayahTag(settings.displayQiraah)
        return options.first { $0.tag == tag }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let currentOption {
                    currentQiraahHeader(currentOption)

                    Divider()
                }

                List {
                    Group {
                        Section {
                            Text("Compare this ayah across the Arabic riwayat available in the app. Some riwayat merge or omit Hafs ayah numbers, so unavailable rows are dimmed. No ayah is ever missing - the same words may simply be joined or numbered differently.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        if !favoriteOptions.isEmpty {
                            Section(header: Text("FAVORITES")) {
                                ForEach(favoriteOptions) { option in
                                    qiraahRow(option)
                                }
                            }
                        }

                        ForEach(groupedOptions, id: \.teacher) { group in
                            Section(header: Text("\(group.teacher.uppercased()) - \(group.teacherArabic)")) {
                                ForEach(group.options) { option in
                                    qiraahRow(option)
                                }
                            }
                        }

                        if filteredOptions.isEmpty {
                            Section {
                                Text("No riwayat found.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .themedListRowBackground()
                }
                .applyConditionalListStyle()
                .compactListSectionSpacing()
                .searchable(text: $searchText.animation(.easeInOut), prompt: "Search riwayat")
            }
            .navigationTitle(ayahSheetTitle(surahNumber: surahNumber, ayahNumber: ayahNumber))
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
        }
    }

    private func currentQiraahHeader(_ option: QiraahDisplay) -> some View {
        let text = qiraahText(for: option)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(option.label)
                    .font(.subheadline.weight(.semibold))

                Text(option.arabicCaption)
                    .font(.caption)
                    .foregroundColor(settings.accentColor.color)

                Spacer()

                Text("CURRENT")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(text ?? "This ayah is not separate in this riwayah.")
                .font(.custom(comparisonArabicFontName(for: option), size: arabicFontSize))
                .arabicFontDesign(custom: settings.quranDisplayUsesCustomArabicFace)
                .foregroundColor(text == nil ? .secondary : .primary)
                .multilineTextAlignment(.trailing)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .textSelection(.enabled)

            HStack(spacing: 12) {
                Image(systemName: "textformat.size.smaller")
                    .foregroundStyle(.secondary)

                Slider(value: $arabicFontSize, in: 15...45, step: 1)
                    .accessibilityLabel("Arabic font size")

                Image(systemName: "textformat.size.larger")
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private func qiraahText(for option: QiraahDisplay) -> String? {
        guard let ayah = quranData.ayah(surah: surahNumber, ayah: ayahNumber),
              ayah.existsInQiraah(option.tag) else {
            return nil
        }
        return ayah.displayArabicText(surahId: surahNumber, clean: settings.cleanArabicText, qiraahOverride: option.tag)
    }

    private func comparisonArabicFontName(for option: QiraahDisplay) -> String {
        settings.quranArabicFontName(for: option.tag)
    }

    private func qiraahRow(_ option: QiraahDisplay) -> some View {
        let text = qiraahText(for: option)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                HStack {
                    HighlightedSnippet(
                        source: option.label,
                        term: searchText,
                        font: .subheadline.weight(.semibold),
                        accent: settings.accentColor.color,
                        fg: .primary
                    )

                    HighlightedSnippet(
                        source: option.arabicCaption,
                        term: searchText,
                        font: .caption,
                        accent: settings.accentColor.color,
                        fg: settings.accentColor.color
                    )
                }

                Spacer()

                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) {
                        settings.toggleQiraahFavorite(tag: option.tag)
                    }
                } label: {
                    Image(systemName: settings.isQiraahFavorite(tag: option.tag) ? "star.fill" : "star")
                        .foregroundStyle(settings.accentColor.color)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(settings.isQiraahFavorite(tag: option.tag) ? "Unfavorite Riwayah" : "Favorite Riwayah")

                if text == nil {
                    Text("Unavailable")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            HighlightedSnippet(
                source: text ?? "This ayah is not separate in this riwayah.",
                term: searchText,
                font: .custom(
                    comparisonArabicFontName(for: option),
                    size: arabicFontSize
                ),
                accent: settings.accentColor.color,
                fg: text == nil ? .secondary : .primary
            )
                .arabicFontDesign(custom: settings.quranDisplayUsesCustomArabicFace)
                .multilineTextAlignment(.trailing)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 4)
        .opacity(text == nil ? 0.55 : 1)
        .textSelection(.enabled)
    }
}

private struct EnglishEdition: Identifiable {
    let id: String
    let name: String
}

private let inAppEnglishComparisonEditions: [EnglishEdition] = [
    EnglishEdition(id: "inapp.saheeh", name: "Saheeh International"),
    EnglishEdition(id: "inapp.mustafa", name: "Clear Quran (Mustafa Khattab)")
]

private let englishComparisonEditions: [EnglishEdition] = [
    EnglishEdition(id: "en.ahmedali", name: "Ahmed Ali"),
    EnglishEdition(id: "en.ahmedraza", name: "Ahmed Raza Khan"),
    EnglishEdition(id: "en.arberry", name: "A. J. Arberry"),
    EnglishEdition(id: "en.asad", name: "Muhammad Asad"),
    EnglishEdition(id: "en.daryabadi", name: "Abdul Majid Daryabadi"),
    EnglishEdition(id: "en.hilali", name: "Hilali & Khan"),
    EnglishEdition(id: "en.pickthall", name: "Pickthall"),
    EnglishEdition(id: "en.qaribullah", name: "Qaribullah & Darwish"),
    EnglishEdition(id: "en.sarwar", name: "Muhammad Sarwar"),
    EnglishEdition(id: "en.yusufali", name: "Yusuf Ali"),
    EnglishEdition(id: "en.maududi", name: "Abul Ala Maududi"),
    EnglishEdition(id: "en.shakir", name: "Shakir"),
    EnglishEdition(id: "en.itani", name: "Clear Quran (Talal Itani)"),
    EnglishEdition(id: "en.mubarakpuri", name: "Mubarakpuri"),
    EnglishEdition(id: "en.qarai", name: "Qarai"),
    EnglishEdition(id: "en.wahiduddin", name: "Wahiduddin Khan")
]

private struct AyahEditionResponse: Decodable {
    let data: [AyahEditionData]
}

private struct AyahEditionData: Decodable {
    let text: String
    let edition: AyahEditionMetadata
}

private struct AyahEditionMetadata: Decodable {
    let identifier: String
    let englishName: String?
}

@MainActor
private final class EnglishComparisonViewModel: ObservableObject {
    @Published private(set) var translations: [String: String] = [:]
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let surah: Int
    private let ayah: Int
    private var loadedReference: String?

    init(surah: Int, ayah: Int) {
        self.surah = surah
        self.ayah = ayah
    }

    func loadIfNeeded() async {
        await load(surah: surah, ayah: ayah)
    }

    func load(surah: Int, ayah: Int) async {
        let reference = "\(surah):\(ayah)"
        guard loadedReference != reference || translations.isEmpty else { return }
        if isLoading { return }

        isLoading = true
        errorMessage = nil

        do {
            let editions = englishComparisonEditions.map(\.id).joined(separator: ",")
            guard let url = URL(string: "https://api.alquran.cloud/v1/ayah/\(reference)/editions/\(editions)") else {
                throw URLError(.badURL)
            }

            // Same insulation as the tafsir sheet: the page reader tears down its hosting view mid-flight,
            // and without the wrapper the resulting task cancellation killed the fetch with "Cancelled".
            let (data, response) = try await Task { try await URLSession.shared.data(from: url) }.value
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                throw URLError(.badServerResponse)
            }

            let decoded = try JSONDecoder().decode(AyahEditionResponse.self, from: data)
            translations = Dictionary(uniqueKeysWithValues: decoded.data.map { ($0.edition.identifier, $0.text) })
            loadedReference = reference
        } catch {
            if !AyahTafsirViewModel.isCancellation(error) {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }
}

struct AyahEnglishComparisonSheet: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject var quranData = QuranData.shared
    @Environment(\.dismiss) private var dismiss

    let surahNumber: Int
    let ayahNumber: Int

    @StateObject private var viewModel: EnglishComparisonViewModel
    @State private var searchText = ""

    init(surahNumber: Int, ayahNumber: Int) {
        self.surahNumber = surahNumber
        self.ayahNumber = ayahNumber
        _viewModel = StateObject(wrappedValue: EnglishComparisonViewModel(surah: surahNumber, ayah: ayahNumber))
    }

    private var loadKey: String {
        "\(surahNumber):\(ayahNumber)"
    }

    private var filteredEditions: [EnglishEdition] {
        filteredOnlineEditions
    }

    private var filteredInAppEditions: [EnglishEdition] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let sorted = inAppEnglishComparisonEditions.sorted { lhs, rhs in
            let lhsFavorite = settings.isEnglishTranslationFavorite(id: lhs.id)
            let rhsFavorite = settings.isEnglishTranslationFavorite(id: rhs.id)
            if lhsFavorite != rhsFavorite { return lhsFavorite }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
        guard !query.isEmpty else { return sorted }

        return sorted.filter { edition in
            edition.name.localizedCaseInsensitiveContains(query) ||
            inAppTranslationText(for: edition.id).localizedCaseInsensitiveContains(query)
        }
    }

    private var filteredOnlineEditions: [EnglishEdition] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let sorted = englishComparisonEditions.sorted { lhs, rhs in
            let lhsFavorite = settings.isEnglishTranslationFavorite(id: lhs.id)
            let rhsFavorite = settings.isEnglishTranslationFavorite(id: rhs.id)
            if lhsFavorite != rhsFavorite { return lhsFavorite }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
        guard !query.isEmpty else { return sorted }

        return sorted.filter { edition in
            edition.name.localizedCaseInsensitiveContains(query) ||
            (viewModel.translations[edition.id]?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    private var shouldShowQuranText: Bool {
        guard quranData.ayah(surah: surahNumber, ayah: ayahNumber) != nil else {
            return false
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }

        guard let ayah = quranData.ayah(surah: surahNumber, ayah: ayahNumber) else { return false }
        let arabic = ayah.displayArabicText(surahId: surahNumber, clean: settings.cleanArabicText)
        return "Transliteration".localizedCaseInsensitiveContains(query) ||
            arabic.localizedCaseInsensitiveContains(query) ||
            ayah.textTransliteration.localizedCaseInsensitiveContains(query)
    }

    // The translation the reader is currently displaying - pinned above the list so every row can be
    // compared against it without scrolling back up. When both in-app translations are shown in the
    // reader, Saheeh International stands in as "current".
    private var currentTranslationName: String {
        (settings.showEnglishSaheeh || !settings.showEnglishMustafa) ? "Saheeh International" : "Clear Quran (Mustafa Khattab)"
    }

    private var currentTranslationText: String? {
        guard let ayah = quranData.ayah(surah: surahNumber, ayah: ayahNumber) else { return nil }
        return (settings.showEnglishSaheeh || !settings.showEnglishMustafa) ? ayah.textEnglishSaheeh : ayah.textEnglishMustafa
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let currentTranslationText {
                    currentTranslationHeader(text: currentTranslationText)

                    Divider()
                }

                comparisonList
            }
            .navigationTitle(ayahSheetTitle(surahNumber: surahNumber, ayahNumber: ayahNumber))
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
            .task(id: loadKey) {
                await viewModel.loadIfNeeded()
            }
        }
    }

    private func currentTranslationHeader(text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(currentTranslationName)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Text("CURRENT")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private var comparisonList: some View {
        List {
            Group {
                // The same prominent "online" card the tafsir sheet uses, so every online-backed sheet
                // discloses its source identically.
                Section {
                    OnlineNoticeCard(text: "Compare this ayah across several English Qur'an translations. The online translations are fetched from alquran.cloud; the downloaded ones are built into the app.")
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                if shouldShowQuranText,
                   let ayah = quranData.ayah(surah: surahNumber, ayah: ayahNumber) {
                    Section(header: Text("QURAN TEXT")) {
                        comparisonRow(
                            title: nil,
                            text: ayah.displayArabicText(surahId: surahNumber, clean: settings.cleanArabicText),
                            isArabic: true
                        )

                        if settings.showTransliteration {
                            comparisonRow(title: "Transliteration", text: ayah.textTransliteration)
                        }
                    }
                }

                Section(header: Text("DOWNLOADED TRANSLATIONS")) {
                    if let ayah = quranData.ayah(surah: surahNumber, ayah: ayahNumber) {
                        ForEach(filteredInAppEditions) { edition in
                            comparisonRow(
                                title: edition.name,
                                text: inAppTranslationText(for: edition.id, ayah: ayah),
                                editionID: edition.id,
                                isDownloaded: true
                            )
                        }

                        if filteredInAppEditions.isEmpty {
                            Text("No downloaded translations found.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section(header: Text("ONLINE TRANSLATIONS")) {
                    if viewModel.isLoading && viewModel.translations.isEmpty {
                        HStack {
                            ProgressView()
                            Text("Loading translations...")
                                .foregroundStyle(.secondary)
                        }
                    } else if let errorMessage = viewModel.errorMessage, viewModel.translations.isEmpty {
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                        ForEach(filteredOnlineEditions) { edition in
                            comparisonRow(
                                title: edition.name,
                                text: viewModel.translations[edition.id] ?? "Unavailable",
                                editionID: edition.id
                            )
                            .opacity(viewModel.translations[edition.id] == nil ? 0.55 : 1)
                        }

                        if filteredOnlineEditions.isEmpty {
                            Text("No translations found.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .compactListSectionSpacing()
        .searchable(text: $searchText.animation(.easeInOut), prompt: "Search translations")
    }

    private func inAppTranslationText(for editionID: String, ayah: Ayah? = nil) -> String {
        let resolvedAyah = ayah ?? quranData.ayah(surah: surahNumber, ayah: ayahNumber)
        guard let resolvedAyah else { return "" }
        switch editionID {
        case "inapp.saheeh":
            return resolvedAyah.textEnglishSaheeh
        case "inapp.mustafa":
            return resolvedAyah.textEnglishMustafa
        default:
            return ""
        }
    }

    private func comparisonRow(title: String?, text: String, editionID: String? = nil, isArabic: Bool = false, isDownloaded: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title, !title.isEmpty {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    HighlightedSnippet(
                        source: title,
                        term: searchText,
                        font: .subheadline.weight(.semibold),
                        accent: settings.accentColor.color,
                        fg: .primary
                    )

                    Spacer()

                    if let editionID, !isDownloaded {
                        Button {
                            settings.hapticFeedback()
                            withAnimation(.easeInOut) {
                                settings.toggleEnglishTranslationFavorite(id: editionID)
                            }
                        } label: {
                            Image(systemName: settings.isEnglishTranslationFavorite(id: editionID) ? "star.fill" : "star")
                                .foregroundStyle(settings.accentColor.color)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(settings.isEnglishTranslationFavorite(id: editionID) ? "Unfavorite Translation" : "Favorite Translation")
                    }
                }
            }

            HighlightedSnippet(
                source: text,
                term: searchText,
                font: isArabic
                    ? Font.arabic(settings.quranDisplayFontName, size: UIFont.preferredFont(forTextStyle: .title3).pointSize)
                    : .subheadline,
                accent: settings.accentColor.color,
                fg: .primary
            )
                .arabicFontDesign(custom: isArabic && settings.quranUsesCustomArabicFace)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(isArabic ? .trailing : .leading)
                .frame(maxWidth: .infinity, alignment: isArabic ? .trailing : .leading)
        }
        .padding(.vertical, 4)
        .textSelection(.enabled)
    }
}
#endif

struct AyahContextMenuModifier: ViewModifier {
    @ObservedObject var settings = Settings.shared
    @ObservedObject var quranData = QuranData.shared
    @ObservedObject var quranPlayer = QuranPlayer.shared

    let surah: Int
    let ayah: Int

    let favoriteSurahs: Set<Int>
    let bookmarkedAyahs: Set<String>

    @Binding var searchText: String
    @Binding var scrollToSurahID: Int

    let lastRead: Bool
    /// When true, the menu leads with "Hide for Today" + "Delete Forever" (the Ayah of the Day card).
    var ayahOfTheDay: Bool = false

    @State var showAyahSheet = false

    @State private var showingNoteSheet = false
    @State private var draftNote: String = ""
    @State private var showRespectAlert = false
    @State private var showCustomRangeSheet = false
    @State private var showTafsirSheet = false
    @State private var showQiraahComparisonSheet = false
    @State private var showEnglishComparisonSheet = false

    private var isBookmarked: Bool {
        bookmarkedAyahs.contains("\(surah)-\(ayah)")
    }

    func containsProfanity(_ text: String) -> Bool {
        textContainsProfanity(text)
    }

    private func isNoteAllowed(_ text: String) -> Bool {
        !containsProfanity(text)
    }

    private var bookmarkIndex: Int? {
        settings.bookmarkIndex(surah: surah, ayah: ayah)
    }

    private var bookmark: BookmarkedAyah? {
        settings.bookmarkedAyah(surah: surah, ayah: ayah)
    }

    private var isBookmarkedHere: Bool { bookmarkIndex != nil }
    private var currentNote: String {
        settings.bookmarkNoteText(surah: surah, ayah: ayah)
    }

    private var canCompareEnglishText: Bool {
        settings.isHafsDisplay
    }

    #if os(iOS)
    @ViewBuilder
    private var comparisonMenuBlock: some View {
        if settings.showQiraahDetails && canCompareEnglishText {
            Menu {
                Button {
                    settings.hapticFeedback()
                    showQiraahComparisonSheet = true
                } label: {
                    Label("Qiraah Comparison", systemImage: "character.book.closed.fill.ar")
                }

                Button {
                    settings.hapticFeedback()
                    showEnglishComparisonSheet = true
                } label: {
                    Label("Translation Comparison", systemImage: "character.book.closed")
                }
            } label: {
                Label("Compare Ayah", systemImage: "rectangle.split.2x1")
            }
        } else if settings.showQiraahDetails {
            Button {
                settings.hapticFeedback()
                showQiraahComparisonSheet = true
            } label: {
                Label("Qiraah Comparison", systemImage: "character.book.closed.fill.ar")
            }
        } else if canCompareEnglishText {
            Button {
                settings.hapticFeedback()
                showEnglishComparisonSheet = true
            } label: {
                Label("Translation Comparison", systemImage: "character.book.closed")
            }
        }
    }
    #endif

    private func setNote(_ text: String?) {
        settings.setBookmarkNote(surah: surah, ayah: ayah, note: text)
    }

    private func removeNote() {
        settings.removeBookmarkNote(surah: surah, ayah: ayah)
    }

    @State private var confirmRemoveNote = false
    @State private var confirmDeleteForever = false

    private func toggleBookmarkWithNoteGuard() {
        if !settings.toggleBookmarkIfNoNoteLoss(surah: surah, ayah: ayah) {
            confirmRemoveNote = true
        }
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        // O(1) dictionary lookup, not an O(114) linear scan. This `body` re-evaluates whenever `settings`/
        // `quranPlayer` publish (constant during playback), and the modifier sits on every history/bookmark/
        // favorite row - the linear scan added up across all visible rows.
        let surahObj = quranData.surah(surah)

        #if os(iOS)
        content
            .contextMenu {
                if ayahOfTheDay {
                    Button(role: .destructive) {
                        settings.hapticFeedback()
                        withAnimation {
                            settings.ayahOfTheDayHiddenDate = Settings.dayKey()
                        }
                    } label: { Label("Hide for Today", systemImage: "eye.slash") }

                    Button(role: .destructive) {
                        settings.hapticFeedback()
                        confirmDeleteForever = true
                    } label: { Label("Delete Forever", systemImage: "trash") }

                    Divider()
                } else if lastRead {
                    Button(role: .destructive) {
                        settings.hapticFeedback()
                        withAnimation {
                            settings.lastReadSurah = 0
                            settings.lastReadAyah = 0
                        }
                    } label: { Label("Remove", systemImage: "minus.circle") }

                    Button(role: .destructive) {
                        settings.hapticFeedback()
                        confirmDeleteForever = true
                    } label: { Label("Delete Forever", systemImage: "trash") }

                    Divider()
                }

                Button(role: isBookmarked ? .destructive : .cancel) {
                    settings.hapticFeedback()
                    toggleBookmarkWithNoteGuard()
                } label: {
                    Label(
                        isBookmarked ? "Unbookmark Ayah" : "Bookmark Ayah",
                        systemImage: isBookmarked ? "bookmark.fill" : "bookmark"
                    )
                }

                Button {
                    settings.hapticFeedback()
                    if !isBookmarked {
                        settings.ensureBookmarkExists(surah: surah, ayah: ayah)
                    }
                    draftNote = currentNote
                    showingNoteSheet = true
                } label: {
                    Label(currentNote.isEmpty ? "Add Note" : "Edit Note", systemImage: "note.text")
                }

                if !currentNote.isEmpty {
                    Button(role: .destructive) {
                        settings.hapticFeedback()
                        withAnimation(.easeInOut) {
                            removeNote()
                        }
                    } label: {
                        Label("Remove Note", systemImage: "minus.circle")
                    }
                }

                if settings.isHafsDisplay {
                    Button {
                        settings.hapticFeedback()
                        showTafsirSheet = true
                    } label: {
                        Label("See Tafsir", systemImage: "text.book.closed")
                    }
                }

                comparisonMenuBlock

                if settings.isHafsDisplay {
                    Menu {
                        Button {
                            settings.hapticFeedback()
                            quranPlayer.playAyah(surahNumber: surah, ayahNumber: ayah)
                        } label: {
                            Label("Play This Ayah", systemImage: "play.circle")
                        }
                        Button {
                            settings.hapticFeedback()
                            quranPlayer.playAyah(
                                surahNumber: surah,
                                ayahNumber: ayah,
                                continueRecitation: true
                            )
                        } label: {
                            Label("Play From Ayah", systemImage: "play.circle.fill")
                        }
                        Button {
                            settings.hapticFeedback()
                            showCustomRangeSheet = true
                        } label: {
                            Label("Play Custom Range", systemImage: "slider.horizontal.3")
                        }
                    } label: {
                        Label("Play Ayah", systemImage: "play.circle")
                    }
                }

                Button {
                    settings.hapticFeedback()
                    ShareAyahSheet.copyAyahToPasteboard(surahNumber: surah, ayahNumber: ayah, settings: settings, quranData: quranData)
                } label: {
                    Label("Copy Ayah", systemImage: "doc.on.doc")
                }

                Button {
                    settings.hapticFeedback()
                    showAyahSheet = true
                } label: {
                    Label("Share Ayah", systemImage: "square.and.arrow.up")
                }

                Divider()

                if let surah = surahObj {
                    SurahContextMenu(
                        surahID: surah.id,
                        surahName: surah.nameTransliteration,
                        favoriteSurahs: favoriteSurahs,
                        searchText: $searchText,
                        scrollToSurahID: $scrollToSurahID
                    )
                }
            }
            .sheet(isPresented: $showAyahSheet) {
                ShareAyahSheet(
                    surahNumber: surah,
                    ayahNumber: ayah
                )
                .smallMediumSheetPresentation()
            }
            .sheet(isPresented: $showTafsirSheet) {
                if let surahObj = surahObj {
                    AyahTafsirSheet(
                        surahName: surahObj.nameTransliteration,
                        surahNumber: surahObj.id,
                        ayahNumber: ayah
                    )
                    .smallMediumSheetPresentation()
                }
            }
            .sheet(isPresented: $showCustomRangeSheet) {
                if let surahObj = surahObj {
                    PlayCustomRangeSheet(
                        surah: surahObj,
                        initialStartAyah: ayah,
                        initialEndAyah: PlayCustomRangeSheet.defaultEndAyah(
                            startAyah: ayah,
                            surah: surahObj,
                            displayQiraah: settings.displayQiraahForArabic
                        ),
                        onPlay: { start, end, repAyah, repSec in
                            quranPlayer.playCustomRange(
                                surahNumber: surahObj.id,
                                surahName: surahObj.nameTransliteration,
                                startAyah: start,
                                endAyah: end,
                                repeatPerAyah: repAyah,
                                repeatSection: repSec
                            )
                        },
                        onCancel: { showCustomRangeSheet = false }
                    )
                    .environmentObject(settings)
                    .smallMediumSheetPresentation()
                }
            }
            .sheet(isPresented: $showQiraahComparisonSheet) {
                AyahQiraahComparisonSheet(surahNumber: surah, ayahNumber: ayah)
                    .smallMediumSheetPresentation()
                    .environmentObject(settings)
                    .environmentObject(quranData)
            }
            .sheet(isPresented: $showEnglishComparisonSheet) {
                AyahEnglishComparisonSheet(surahNumber: surah, ayahNumber: ayah)
                    .smallMediumSheetPresentation()
                    .environmentObject(settings)
                    .environmentObject(quranData)
            }
            .sheet(isPresented: $showingNoteSheet) {
                if let surah = surahObj {
                    NoteEditorSheet(
                        title: "Note for \(surah.nameTransliteration) \(surah.id):\(ayah)",
                        text: $draftNote,
                        onAttemptSave: { text in
                            if isNoteAllowed(text) {
                                setNote(text)
                                return true
                            } else {
                                showRespectAlert = true
                                return false
                            }
                        },
                        onCancel: {},
                        onSave: { setNote(draftNote) }
                    )
                    .smallMediumSheetPresentation()
                }
            }
            .confirmationDialog("Note not saved", isPresented: $showRespectAlert, titleVisibility: .visible) {
                Button("OK") { }
            } message: {
                Text("Please keep notes Islamic and respectful.")
            }
            .confirmationDialog(Settings.bookmarkNoteRemovalDialogTitle, isPresented: $confirmRemoveNote, titleVisibility: .visible) {
                Button("Remove", role: .destructive) {
                    settings.hapticFeedback()
                    settings.toggleBookmark(surah: surah, ayah: ayah)
                }
                Button("Cancel") {}
            } message: {
                Text(Settings.bookmarkNoteRemovalDialogMessage)
            }
            .confirmationDialog("Are you sure?", isPresented: $confirmDeleteForever, titleVisibility: .visible) {
                Button("Remove Permanently", role: .destructive) {
                    settings.hapticFeedback()
                    withAnimation {
                        if ayahOfTheDay {
                            settings.showAyahOfTheDay = false
                        } else {
                            settings.lastReadSurah = 0
                            settings.lastReadAyah = 0
                            settings.saveLastReadAyah = false
                        }
                    }
                }
                Button("Cancel") {}
            } message: {
                Text(ayahOfTheDay
                     ? "You can re-enable Ayah of the Day later in Quran Settings."
                     : "You can re-enable Last Read Ayah later in Quran Settings.")
            }
        #else
        content
        #endif
    }
}

extension View {
    func ayahContextMenuModifier(
        surah: Int,
        ayah: Int,
        favoriteSurahs: Set<Int>,
        bookmarkedAyahs: Set<String>,
        searchText: Binding<String>,
        scrollToSurahID: Binding<Int>,
        lastRead: Bool = false,
        ayahOfTheDay: Bool = false
    ) -> some View {
        self.modifier(AyahContextMenuModifier(
            surah: surah,
            ayah: ayah,
            favoriteSurahs: favoriteSurahs,
            bookmarkedAyahs: bookmarkedAyahs,
            searchText: searchText,
            scrollToSurahID: scrollToSurahID,
            lastRead: lastRead,
            ayahOfTheDay: ayahOfTheDay
        ))
    }
}

struct LeftSwipeActions: ViewModifier {
    @ObservedObject private var settings = Settings.shared

    let surah: Int
    let favoriteSurahs: Set<Int>
    let bookmarkedAyahs: Set<String>?
    let bookmarkedSurah: Int?
    let bookmarkedAyah: Int?

    private var isFavorite: Bool {
        favoriteSurahs.contains(surah)
    }

    private var isBookmarked: Bool {
        if let bookmarkedAyahs, let s = bookmarkedSurah, let a = bookmarkedAyah {
            return bookmarkedAyahs.contains("\(s)-\(a)")
        }
        return false
    }

    private var bookmarkIndex: Int? {
        let surah = bookmarkedSurah ?? 1
        let ayah = bookmarkedAyah ?? 1

        return settings.bookmarkIndex(surah: surah, ayah: ayah)
    }

    private var bookmark: BookmarkedAyah? {
        settings.bookmarkedAyah(surah: bookmarkedSurah ?? 1, ayah: bookmarkedAyah ?? 1)
    }

    private var isBookmarkedHere: Bool { bookmarkIndex != nil }

    private var currentNote: String {
        settings.bookmarkNoteText(surah: bookmarkedSurah ?? 1, ayah: bookmarkedAyah ?? 1)
    }

    @State private var confirmRemoveNote = false

    private func toggleBookmarkWithNoteGuard(_ surah: Int, _ ayah: Int) {
        if !settings.toggleBookmarkIfNoNoteLoss(surah: surah, ayah: ayah) {
            confirmRemoveNote = true
        }
    }

    func body(content: Content) -> some View {
        content
            #if os(iOS)
            .swipeActions(edge: .leading) {
                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) {
                        settings.toggleSurahFavorite(surah: surah)
                    }
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                }
                .tint(settings.accentColor.color)

                if let s = bookmarkedSurah, let a = bookmarkedAyah {
                    Button {
                        settings.hapticFeedback()
                        toggleBookmarkWithNoteGuard(s, a)
                    } label: {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    }
                    .tint(settings.accentColor.color)
                }
            }
            #endif
            .confirmationDialog(Settings.bookmarkNoteRemovalDialogTitle, isPresented: $confirmRemoveNote, titleVisibility: .visible) {
                Button("Remove", role: .destructive) {
                    settings.hapticFeedback()
                    settings.toggleBookmark(surah: bookmarkedSurah ?? 1, ayah: bookmarkedAyah ?? 1)
                }
                Button("Cancel") {}
            } message: {
                Text(Settings.bookmarkNoteRemovalDialogMessage)
            }
    }
}

public extension View {
    func leftSwipeActions(
        surah: Int,
        favoriteSurahs: Set<Int>,
        bookmarkedAyahs: Set<String>? = nil,
        bookmarkedSurah: Int? = nil,
        bookmarkedAyah: Int? = nil
    ) -> some View {
        modifier(LeftSwipeActions(
            surah: surah,
            favoriteSurahs: favoriteSurahs,
            bookmarkedAyahs: bookmarkedAyahs,
            bookmarkedSurah: bookmarkedSurah,
            bookmarkedAyah: bookmarkedAyah
        ))
    }
}

struct RightSwipeActions: ViewModifier {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranPlayer = QuranPlayer.shared

    let surahID: Int
    let surahName: String
    let ayahID: Int?
    let certainReciter: Bool

    @Binding var searchText: String
    @Binding var scrollToSurahID: Int

    private func endEditing() {
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }

    func body(content: Content) -> some View {
        content
            #if os(iOS)
            .swipeActions(edge: .trailing) {
                Button {
                    settings.hapticFeedback()
                    quranPlayer.playSurah(
                        surahNumber: surahID,
                        surahName: surahName,
                        certainReciter: certainReciter
                    )
                } label: {
                    Image(systemName: "play.fill")
                }
                .tint(settings.accentColor.color)

                if let ayah = ayahID {
                    Button {
                        settings.hapticFeedback()
                        quranPlayer.playAyah(surahNumber: surahID, ayahNumber: ayah)
                    } label: {
                        Image(systemName: "play.circle")
                    }
                }

                Button {
                    settings.hapticFeedback()
                    withAnimation {
                        searchText = ""
                        scrollToSurahID = surahID
                        endEditing()
                    }
                } label: {
                    Image(systemName: "arrow.down.circle")
                }
                .tint(.secondary)
            }
            #endif
    }
}

public extension View {
    func rightSwipeActions(
        surahID: Int,
        surahName: String,
        ayahID: Int? = nil,
        certainReciter: Bool = false,
        searchText: Binding<String>,
        scrollToSurahID: Binding<Int>
    ) -> some View {
        modifier(RightSwipeActions(
            surahID: surahID,
            surahName: surahName,
            ayahID: ayahID,
            certainReciter: certainReciter,
            searchText: searchText,
            scrollToSurahID: scrollToSurahID
        ))
    }
}

#if os(iOS)
import SwiftUI

struct NoteEditorSheet: View {
    @ObservedObject var settings = Settings.shared

    let title: String
    @Binding var text: String
    var onAttemptSave: (String) -> Bool
    var onCancel: () -> Void
    var onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    private let maxChars: Int = 300

    private var characterCount: Int { text.count }
    private var remaining: Int { max(0, maxChars - characterCount) }
    private var isEmpty: Bool { text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                let cardFill   = Color(UIColor.secondarySystemBackground)
                let cardStroke = Color.primary.opacity(0.12)

                TextEditor(text: $text)
                    .padding(12)
                    .background(Color.clear)
                    .frame(minHeight: 220)
                    .modifier(HideEditorScrollBackground())
                    .textInputAutocapitalization(.sentences)
                    .disableAutocorrection(false)
                    .onChange(of: text) { newValue in
                        if newValue.count > maxChars {
                            text = String(newValue.prefix(maxChars))
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(cardFill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(cardStroke, lineWidth: 1)
                    )

                Text("\(remaining) characters left")
                    .font(.footnote)
                    .monospacedDigit()
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Character limit")
                    .accessibilityValue("\(maxChars) limit, \(remaining) remaining")

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "hands.sparkles")
                            .imageScale(.large)
                        Text("A respectful reminder")
                            .font(.headline)
                    }
                    .foregroundColor(.accentColor)

                    Text("Your note will appear next to the Quran, the Words of Allah ﷻ. Please keep it dignified and beneficial.")
                        .font(.subheadline)

                    VStack(alignment: .leading, spacing: 6) {
                        Label("Avoid profanity or insults", systemImage: "checkmark.seal")
                        Label("No mockery, slurs, or indecency", systemImage: "checkmark.seal")
                        Label("Keep remarks relevant and respectful", systemImage: "checkmark.seal")
                    }
                    .font(.footnote)
                    .foregroundColor(.secondary)

                    Text("May Allah ﷻ reward you, protect you, and keep us all firm upon the truth.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding()
                .accessibilityElement(children: .combine)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(cardFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(cardStroke, lineWidth: 1)
                )
            }
            .padding(.horizontal)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        settings.hapticFeedback()
                        onCancel()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                    }
                    .tint(settings.accentColor.color)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        settings.hapticFeedback()
                        if onAttemptSave(text) {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.body.weight(.semibold))
                    }
                    .tint(settings.accentColor.color)
                    .disabled(isEmpty)
                }
            }
        }
    }
}

private struct HideEditorScrollBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.scrollContentBackground(.hidden)
        } else {
            content
                .onAppear {
                    UITextView.appearance().backgroundColor = .clear
                }
        }
    }
}

private struct SurahContextMenuPreviewContent: View {
    @State private var searchText = ""
    @State private var scrollToSurahID = 0

    var body: some View {
        Menu("Open Surah Actions") {
            SurahContextMenu(
                surahID: AlIslamPreviewData.surah.id,
                surahName: AlIslamPreviewData.surah.nameTransliteration,
                favoriteSurahs: [],
                searchText: $searchText,
                scrollToSurahID: $scrollToSurahID
            )
        }
        .padding()
    }
}

// The generic focus overlay lives in Helpers and knows nothing about the Quran; a surah teaches it how to
// render itself here, so the overlay stays usable in an app that ships without a Quran.
extension FocusItem {
    static func surah(_ surah: Surah) -> FocusItem {
        FocusItem(
            id: "surah-\(surah.id)",
            arabic: surah.nameArabic,
            title: "\(surah.id) · \(surah.nameTransliteration)",
            subtitle: surah.nameEnglish,
            footnote: "\(surah.type.capitalized) · \(surah.numberOfAyahs) ayahs",
            secondaryArabic: surah.idArabic,
            shareLabel: "Share Surah",
            shareText: """
            Surah \(surah.id) - \(surah.nameTransliteration) (\(surah.nameArabic))
            \(surah.nameEnglish)
            \(surah.type.capitalized) · \(surah.numberOfAyahs) ayahs
            """
        )
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        SurahContextMenuPreviewContent()
    }
}

/// Lets you pull text out of an ayah by hand: drag over any part of the Arabic, the transliteration, or a
/// translation and copy exactly that.
///
/// The reader already has "Copy Ayah", but that copies the whole thing in a fixed format. Selecting inside a row in
/// the surah list is fussy at best, because the row is competing for the same drag with the list's scroll. Lifting
/// the text into a sheet of its own gives the selection somewhere to live, and each block also gets a one-tap copy
/// for when the whole block is what you wanted.
struct SelectAyahTextSheet: View {
    @ObservedObject var settings = Settings.shared
    @Environment(\.dismiss) private var dismiss

    let surah: Surah
    let ayah: Ayah

    @State private var copiedLabel: String?
    // The sheet's own riwayah, seeded from the reading view's, so switching here never disturbs the reader.
    @State private var selectedQiraah: String = Settings.normalizeLegacyRiwayahTag(Settings.shared.displayQiraah)

    private var usesCustomArabicFace: Bool {
        !settings.removeArabicDots && settings.quranUsesCustomArabicFace
    }

    private var ayahExistsInSelectedQiraah: Bool {
        ayah.existsInQiraah(selectedQiraah)
    }

    private var arabicText: String {
        ayah.displayArabicText(
            surahId: surah.id,
            clean: settings.cleanArabicText,
            qiraahOverride: selectedQiraah
        )
    }

    private var arabicFontName: String {
        usesCustomArabicFace ? settings.quranArabicFontName(for: selectedQiraah) : settings.fontArabic
    }

    var body: some View {
        NavigationView {
            List {
                Group {
                    if settings.showQiraahDetails {
                        Section {
                            ArabicTextRiwayahPicker(selection: $selectedQiraah.animation(.easeInOut), useSimpleIOSPicker: true)
                        } footer: {
                            Text("Switching the riwayah changes the Arabic text only. Ayah numbering can differ between riwayat - no ayah is ever missing, but some are joined or split differently (for example, \"Alif Lam Meem\" and \"Dhalika al-Kitab...\" form a single ayah in most qiraat), so this ayah may appear under a different number or merged with its neighbor.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if ayahExistsInSelectedQiraah {
                        selectableBlock(
                            title: "ARABIC",
                            text: arabicText,
                            font: usesCustomArabicFace
                                ? .custom(arabicFontName, size: settings.fontArabicSize)
                                : .system(size: settings.fontArabicSize, design: .rounded),
                            isArabic: true
                        )
                    } else {
                        Section(header: Text("ARABIC")) {
                            Text("This ayah is not separate in this riwayah - its words are part of a neighboring ayah.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    if !ayah.textTransliteration.isEmpty {
                        selectableBlock(
                            title: "TRANSLITERATION",
                            text: ayah.textTransliteration,
                            font: .system(size: settings.englishFontSize),
                            isArabic: false
                        )
                    }

                    if !ayah.textEnglishSaheeh.isEmpty {
                        selectableBlock(
                            title: "SAHEEH INTERNATIONAL",
                            text: ayah.textEnglishSaheeh,
                            font: .system(size: settings.englishFontSize),
                            isArabic: false
                        )
                    }

                    if !ayah.textEnglishMustafa.isEmpty {
                        selectableBlock(
                            title: "CLEAR QURAN (MUSTAFA KHATTAB)",
                            text: ayah.textEnglishMustafa,
                            font: .system(size: settings.englishFontSize),
                            isArabic: false
                        )
                    }

                    Section {
                        Text("Press and drag over any part of the text above to select it, then copy. The button on each block copies that whole block.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .themedListRowBackground()
            }
            .applyConditionalListStyle()
            .navigationTitle(ayahSheetTitle(surahNumber: surah.id, ayahNumber: ayah.id))
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
        }
    }

    @ViewBuilder
    private func selectableBlock(title: String, text: String, font: Font, isArabic: Bool) -> some View {
        Section {
            // A real (read-only) UITextView, not `Text(...).textSelection(.enabled)`. Inside a List row, that
            // modifier loses the press-and-drag to the list's own scroll gesture, so all you ever get is a
            // whole-block "Copy" on long press - never the partial highlight this sheet exists to provide.
            SelectableTextView(
                text: text,
                font: resolvedUIFont(font, isArabic: isArabic),
                isArabic: isArabic,
                lineSpacing: isArabic ? 8 : 2
            )
            .padding(.vertical, 4)
        } header: {
            HStack {
                Text(title)

                Spacer()

                Button {
                    settings.hapticFeedback()
                    UIPasteboard.general.string = text
                    withAnimation(.easeInOut) { copiedLabel = title }
                    // Long enough to read, short enough that it doesn't linger into the next copy.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.easeInOut) {
                            if copiedLabel == title { copiedLabel = nil }
                        }
                    }
                } label: {
                    Label(
                        copiedLabel == title ? "Copied" : "Copy",
                        systemImage: copiedLabel == title ? "checkmark" : "doc.on.doc"
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundColor(settings.accentColor.color)
                }
                .buttonStyle(.plain)
                .textCase(nil)
            }
        }
    }

    /// The sheet's fonts are declared as SwiftUI `Font`s; the text view needs `UIFont`s. Resolved here rather
    /// than plumbed through, so the call sites keep reading the way the rest of the app's Arabic sites do.
    private func resolvedUIFont(_ font: Font, isArabic: Bool) -> UIFont {
        if isArabic {
            let size = CGFloat(settings.fontArabicSize)
            if usesCustomArabicFace, let custom = UIFont(name: arabicFontName, size: size) {
                return custom
            }
            return .roundedSystemFont(ofSize: size)
        }
        return .roundedSystemFont(ofSize: CGFloat(settings.englishFontSize))
    }
}

/// Read-only, selectable text. `isEditable = false` with `isSelectable = true` gives exactly what is wanted
/// here: you can drag to highlight any part of the passage and copy it, but you cannot alter a word of it.
private struct SelectableTextView: UIViewRepresentable {
    let text: String
    let font: UIFont
    let isArabic: Bool
    let lineSpacing: CGFloat

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.isEditable = false
        tv.isSelectable = true
        tv.isScrollEnabled = false            // let it size itself; the List scrolls
        tv.backgroundColor = .clear
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.adjustsFontForContentSizeCategory = false
        // Without this the text view reports a huge intrinsic width and the row stops wrapping.
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tv.setContentHuggingPriority(.required, for: .vertical)
        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = isArabic ? .right : .natural
        paragraph.baseWritingDirection = isArabic ? .rightToLeft : .natural
        paragraph.lineSpacing = lineSpacing

        tv.attributedText = NSAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: UIColor.label,
            .paragraphStyle: paragraph,
        ])
    }
}
#endif
