#if os(iOS)
import SwiftUI
import Compression

// Similar Ayahs: pick an ayah, see the other places the Quran says something like it.
//
// The data is `Resources/Data/Quran/SimilarAyahs.json.xz`, built by
// Scripts/build_similar_ayahs.py and gated by Scripts/verify_similar_ayahs.py. Two kinds of
// rows, merged and RANKED AT BUILD TIME so nothing here scores or sorts:
//   * verified - qurani.ai's similar-ayah corpus (the classical mutashabihat), shown first;
//   * generated - phrase-overlap matches from the Tilawa app's generator, with reason labels.
//
// Ported from Tilawa (by Jamil Hammoudeh), with permission - see CreditsView.

// MARK: - Store

/// One match row, in display order. `phrase` is the shared wording (may be empty), `labels`
/// the generated matcher's reasons (empty for verified rows).
struct SimilarAyahMatch: Identifiable {
    let surah: Int
    let ayah: Int
    let phrase: String
    let verified: Bool
    let labels: [String]

    var id: String { "\(surah):\(ayah)" }
}

/// Same load pattern as `WordByWordStore`: lazy, lock-guarded, ~4.5 MB of JSON parsed off the
/// hot path on first use, dropped wholesale on `unload()`.
final class SimilarAyahsStore: @unchecked Sendable {
    static let shared = SimilarAyahsStore()
    private init() {}

    private let lock = NSLock()
    private var table: [String: [SimilarAyahMatch]]?
    private var loadFailed = false

    static let isBundled: Bool = packURL() != nil

    /// Matches for one ayah in display order, or [] when it has none (most short ayahs).
    func matches(surah: Int, ayah: Int) -> [SimilarAyahMatch] {
        loadedTable()?["\(surah):\(ayah)"] ?? []
    }

    /// Whether the sheet is worth offering for this ayah - a dictionary hit, no text decode.
    func hasMatches(surah: Int, ayah: Int) -> Bool {
        !matches(surah: surah, ayah: ayah).isEmpty
    }

    func unload() {
        lock.lock(); defer { lock.unlock() }
        table = nil
        loadFailed = false
    }

    private func loadedTable() -> [String: [SimilarAyahMatch]]? {
        lock.lock()
        if let table { lock.unlock(); return table }
        if loadFailed { lock.unlock(); return nil }
        lock.unlock()

        guard let parsed = Self.load() else {
            lock.lock(); loadFailed = true; lock.unlock()
            return nil
        }
        lock.lock(); defer { lock.unlock() }
        if let table { return table }
        table = parsed
        return parsed
    }

    private static func packURL() -> URL? {
        Bundle.main.url(forResource: "SimilarAyahs", withExtension: "json.xz", subdirectory: "Data/Quran")
            ?? Bundle.main.url(forResource: "SimilarAyahs", withExtension: "json.xz", subdirectory: "Quran")
            ?? Bundle.main.url(forResource: "SimilarAyahs", withExtension: "json.xz")
    }

    private static func load() -> [String: [SimilarAyahMatch]]? {
        guard let url = packURL(),
              let blob = try? Data(contentsOf: url),
              let json = inflate(blob),
              let raw = try? JSONSerialization.jsonObject(with: json) as? [String: [[Any]]] else { return nil }

        var out: [String: [SimilarAyahMatch]] = [:]
        out.reserveCapacity(raw.count)
        for (key, rows) in raw {
            var matches: [SimilarAyahMatch] = []
            matches.reserveCapacity(rows.count)
            for row in rows {
                // row = [surah, ayah, phrase, verifiedFlag, labels?] - see the build script.
                guard row.count >= 4,
                      let surah = row[0] as? Int,
                      let ayah = row[1] as? Int,
                      let phrase = row[2] as? String,
                      let flag = row[3] as? Int else { continue }
                let labels = row.count > 4 ? (row[4] as? [String] ?? []) : []
                matches.append(SimilarAyahMatch(
                    surah: surah, ayah: ayah, phrase: phrase, verified: flag == 1, labels: labels
                ))
            }
            if !matches.isEmpty { out[key] = matches }
        }
        return out.isEmpty ? nil : out
    }

    /// The payload is an xz stream; `COMPRESSION_LZMA` reads that container directly.
    private static func inflate(_ data: Data) -> Data? {
        SolidPack.xzDecompress(data)
    }
}

// MARK: - Sheet

/// The related verses for one ayah, readable in place: reference, why it matched (verified
/// badge or the matcher's reasons), the shared wording, then the full Arabic and English.
struct SimilarAyahsSheet: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranData = QuranData.shared

    let surahNumber: Int
    let ayahNumber: Int

    /// nil while the pack is still parsing. The first open pays a ~4.5 MB JSON parse, so it
    /// happens off the main thread behind a spinner instead of freezing the sheet's slide-up;
    /// every later open is a dictionary hit and resolves before the spinner can appear.
    @State private var matches: [SimilarAyahMatch]?

    private var sheetTitle: String {
        let name = quranData.surah(surahNumber)?.nameTransliteration ?? "Surah \(surahNumber)"
        return "Similar to \(name) \(surahNumber):\(ayahNumber)"
    }

    var body: some View {
        NavigationView {
            Group {
                if let matches {
                    List {
                        if matches.isEmpty {
                            Text("No similar ayahs are recorded for this ayah.")
                                .font(.body)
                                .foregroundColor(.secondary)
                        } else {
                            Section(footer: sourcesFootnote) {
                                ForEach(matches) { match in
                                    matchRow(match)
                                }
                            }
                        }
                    }
                    .applyConditionalListStyle(disableNowPlayingInset: true)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(sheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
        }
        .navigationViewStyle(.stack)
        .smallMediumSheetPresentation()
        .task {
            let surah = surahNumber, ayah = ayahNumber
            // The store is lock-guarded, so the parse is safe off the main actor.
            let loaded = await Task.detached(priority: .userInitiated) {
                SimilarAyahsStore.shared.matches(surah: surah, ayah: ayah)
            }.value
            matches = loaded
        }
    }

    private var sourcesFootnote: some View {
        Text("Verified matches come from qurani.ai's similar-ayah corpus; the rest are phrase-overlap matches.")
            .font(.caption2)
    }

    @ViewBuilder
    private func matchRow(_ match: SimilarAyahMatch) -> some View {
        if let surah = quranData.surah(match.surah),
           let ayah = surah.ayahs.first(where: { $0.id == match.ayah }) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text("\(surah.nameTransliteration) \(match.surah):\(match.ayah)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(settings.accentColor.color)

                    if match.verified {
                        Text("Verified")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(settings.accentColor.color.opacity(0.15)))
                            .foregroundColor(settings.accentColor.color)
                    }

                    Spacer()

                    // The one action a row needs: hear this ayah where it lives.
                    Button {
                        settings.hapticFeedback()
                        QuranPlayer.shared.playAyah(surahNumber: match.surah, ayahNumber: match.ayah)
                    } label: {
                        Image(systemName: "play.circle")
                            .font(.body)
                            .foregroundColor(settings.accentColor.color)
                    }
                    .buttonStyle(.plain)
                }

                if !match.labels.isEmpty {
                    Text(match.labels.joined(separator: " · "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(ayah.displayArabicText(surahId: surah.id, clean: settings.cleanArabicText, qiraahOverride: ""))
                    .font(.custom(settings.quranArabicFontName(for: nil), size: CGFloat(settings.fontArabicSize) - 4))
                    .arabicFontDesign(custom: true)
                    .multilineTextAlignment(.trailing)
                    // Same fix as the theme topic rows: without an explicit "take the height you need",
                    // a long ayah in the bundled Uthmani face stops at two lines and ellipsizes mid-word.
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                if settings.showEnglishSaheeh || !settings.showEnglishMustafa {
                    Text(ayah.textEnglishSaheeh)
                        .font(.system(size: CGFloat(settings.englishFontSize)))
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(ayah.textEnglishMustafa)
                        .font(.system(size: CGFloat(settings.englishFontSize)))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.vertical, 6)
            // Brings these rows in line with `AyahRow`, which has had selection all along - the same
            // ayah shouldn't be copyable in the reader and inert in the similar-ayahs list.
            .textSelection(.enabled)
        }
    }
}
#endif
