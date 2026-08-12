import SwiftUI

extension String {
    /// Beginner mode's letter-spaced Arabic: one space between every grapheme cluster.
    /// THE single producer of beginner-spaced text - every surface that renders it and
    /// every consumer that reasons about it must agree on the same construction:
    /// `TajweedStore.tajweedProjection` promises byte-identity with this join, and
    /// `QiraahTajweedStore.tokenSpans` recovers word boundaries from the fact that an
    /// original word gap comes out as a run of 2+ spaces while the inserted letter gaps
    /// are single. Change the spacing here and those two must change with it.
    var beginnerSpaced: String {
        map { String($0) }.joined(separator: " ")
    }
}

struct Juz: Codable, Identifiable, Equatable {
    let id: Int
    let nameArabic: String
    let nameTransliteration: String
    let startSurah: Int
    let startAyah: Int
    let endSurah: Int
    let endAyah: Int
}

struct BookmarkedAyah: Codable, Identifiable, Equatable, Hashable {
    var id: String { "\(surah)-\(ayah)" }

    var surah: Int
    var ayah: Int
    var note: String? = nil

    var hasNote: Bool {
        !(note?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }
}

struct VerseIndexEntry: Identifiable, Hashable, Codable {
    let id: String
    let surah: Int
    let ayah: Int
    let arabicTashkeelBlob: String
    let englishExactBlob: String
    let arabicBlob: String
    let silentArabicBlob: String
    /// The hamza-preserving twin of `arabicBlob`, consulted ONLY when the query carries a bare ء (see
    /// `Settings.HamzaPrecisionFilter`). Nil for an ayah with no hamza at all - which can never satisfy
    /// such a query, so there is nothing worth storing.
    let hamzaArabicBlob: String?
    let englishBlob: String
    let arabicTokens: [String]
    let silentArabicTokens: [String]
    let englishTokens: [String]
}

enum BoundaryDividerStyle: Codable, Equatable {
    case allGreen
    case allSecondary
    case pageAccentJuzSecondary
    case allAccent
}

struct BoundaryDividerModel: Codable, Equatable {
    let text: String
    let pageSegment: String
    let juzSegment: String?
    let style: BoundaryDividerStyle

    /// Where this page falls WITHIN the surah, and how many pages the surah spans - the "(3/10)" already shown
    /// inside `pageSegment`, kept as numbers so the floating overlay can draw a progress bar from them instead
    /// of parsing them back out of the label. `nil` when the boundary is a juz with no page.
    var pageInSurah: Int? = nil
    var surahPageCount: Int? = nil
}

extension Surah {
    /// Absolute mushaf page where this surah begins (falls back to the smallest ayah page).
    var resolvedPageStart: Int? {
        pageStart ?? ayahs.compactMap(\.page).min()
    }

    /// 1-based page number *within* this surah for an absolute mushaf `page`
    /// (e.g. a surah starting on page 100 returns 3 for page 102). `nil` when
    /// the surah's start page is unknown or `page` falls before it.
    func pageWithinSurah(_ page: Int) -> Int? {
        guard let start = resolvedPageStart else { return nil }
        let relative = page - start + 1
        return relative >= 1 ? relative : nil
    }
}

/// "Page 102 (3/6)" - the absolute mushaf page annotated with its position within `surah`, out of how many
/// pages that surah spans, when that can be determined; otherwise just "Page 102". The total is what makes the
/// relative number mean anything - "(3)" alone doesn't say whether you're near the end. Pass `nil` for
/// cross-surah boundaries (the relative number would belong to a different surah).
func mushafPageLabel(forAbsolutePage page: Int, in surah: Surah?) -> String {
    if let surah, let relative = surah.pageWithinSurah(page) {
        return "Page \(page) (\(relative)/\(max(surah.pageCount, relative)))"
    }
    return "Page \(page)"
}

struct SurahBoundaryModel: Codable, Equatable {
    let startDivider: BoundaryDividerModel?
    let startDividerHighlighted: Bool
    let dividerBeforeAyah: [Int: BoundaryDividerModel]
    let endOfSurahDivider: BoundaryDividerModel?
    let endDivider: BoundaryDividerModel?
    let endDividerHighlighted: Bool
}

extension Surah {
    var normalizedSearchNames: [String] {
        let baseNames = [
            nameTransliteration,
            nameEnglish,
            nameArabic.removingArabicMarks()
        ].map { $0.normalizedForSurahQuery }

        return Array(Set(baseNames + transliterationSearchAliases)).sorted()
    }

    var transliterationSearchAliases: [String] {
        nameTransliteration.transliterationSearchAliases
    }
}

extension String {
    func removingArabicMarks() -> String {
        let filtered = unicodeScalars.filter {
            $0.value != 0x0640 &&
            !(0x0610...0x061A).contains($0.value) &&
            !(0x064B...0x065F).contains($0.value) &&
            !(0x06D6...0x06ED).contains($0.value)
        }
        return String(String.UnicodeScalarView(filtered))
    }

    func arabicDigitsToWestern() -> String {
        let digitMap: [Character: Character] = [
            "٠":"0","١":"1","٢":"2","٣":"3","٤":"4",
            "٥":"5","٦":"6","٧":"7","٨":"8","٩":"9",
            "۰":"0","۱":"1","۲":"2","۳":"3","۴":"4",
            "۵":"5","۶":"6","۷":"7","۸":"8","۹":"9"
        ]
        return String(map { digitMap[$0] ?? $0 })
    }

    var normalizedForSurahQuery: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .removingArabicMarks()
            .arabicDigitsToWestern()
            .lowercased()
    }

    var transliterationSearchAliases: [String] {
        let normalized = normalizedForSurahQuery
        guard !normalized.isEmpty else { return [] }

        var aliases = Set<String>()

        func insert(_ value: String) {
            let cleaned = value.normalizedForSurahQuery
            if !cleaned.isEmpty {
                aliases.insert(cleaned)
            }
        }

        insert(normalized)
        insert(normalized.replacingOccurrences(of: "-", with: " "))
        insert(normalized.replacingOccurrences(of: "-", with: ""))
        insert(normalized.replacingOccurrences(of: " ", with: ""))

        let articlePrefixes = ["al", "ar", "an", "ad", "adh", "as", "at", "ath", "az", "ash"]
        for prefix in articlePrefixes {
            let hyphenPrefix = "\(prefix)-"
            let spacePrefix = "\(prefix) "

            if normalized.hasPrefix(hyphenPrefix) {
                let stripped = String(normalized.dropFirst(hyphenPrefix.count))
                insert(stripped)
                insert(stripped.replacingOccurrences(of: "-", with: " "))
                insert(stripped.replacingOccurrences(of: " ", with: ""))
            }

            if normalized.hasPrefix(spacePrefix) {
                let stripped = String(normalized.dropFirst(spacePrefix.count))
                insert(stripped)
                insert(stripped.replacingOccurrences(of: "-", with: " "))
                insert(stripped.replacingOccurrences(of: " ", with: ""))
            }
        }

        return Array(aliases)
    }

    var normalizedSurahIntentQuery: String {
        normalizedForSurahQuery.replacingOccurrences(
            of: #"^\s*(surah|surat|sura|chapter|سورة|سوره)\s+"#,
            with: "",
            options: .regularExpression
        )
    }
}

struct LastListenedSurah: Identifiable, Codable {
    var id = UUID()
    let surahNumber: Int
    let surahName: String
    let reciter: Reciter
    let currentDuration: Double
    let fullDuration: Double
    /// When this position was recorded, shown on the summary tile ("Today 5:30 PM"). Optional so
    /// entries saved by older builds still decode (they show no timestamp).
    var savedAt: Date? = nil
}

/// One bundled "About this Surah" write-up (e.g. Maududi, Ibn Ashur). `contents` is lightweight markdown
/// (## headings + paragraphs) pre-converted from the source HTML so it renders without runtime HTML parsing.
struct SurahInfoSource: Codable, Identifiable, Equatable {
    let name: String
    let contents: String

    var id: String { name }
}

/// The last individual ayah (single ayah or custom-range playback) the user listened to. Full-surah
/// playback is tracked separately by `LastListenedSurah`.
struct LastListenedAyah: Identifiable, Codable {
    var id = UUID()
    let surahNumber: Int
    let surahName: String
    let ayahNumber: Int
    let reciter: Reciter
    /// See `LastListenedSurah.savedAt`.
    var savedAt: Date? = nil
}

struct ListeningHistoryItem: Identifiable, Codable {
    var id = UUID()
    let surahNumber: Int
    let surahName: String
    let reciter: Reciter
    /// Where playback stood when this entry was displaced from Last Listened - powers the history row's
    /// "resume from here". Optional so entries saved by older builds still decode (they show no position).
    var currentDuration: Double? = nil
    var fullDuration: Double? = nil
    var timestamp: Date = Date()
}

struct ReadingHistoryItem: Identifiable, Codable {
    var id = UUID()
    let surahNumber: Int
    let surahName: String
    let ayahNumber: Int
    var timestamp: Date = Date()
}

/// A previously listened individual ayah (single ayah / custom range), shown under the Last Listened Ayah row.
struct AyahListeningHistoryItem: Identifiable, Codable {
    var id = UUID()
    let surahNumber: Int
    let surahName: String
    let ayahNumber: Int
    let reciter: Reciter
    var timestamp: Date = Date()
}

struct ShareSettings: Equatable {
    var arabic = false
    var transliteration = false
    var englishSaheeh = false
    var englishMustafa = false
    var includeQiraah = false
    var shareArabicFont = ""
    var cleanArabic = false
    var hideArabicDots = false
    var showTajweed = false
}

struct Reciter: Identifiable, Comparable, Codable, Hashable {
    var id: String { "\(name)|\(qiraah ?? "Hafs")|\(surahLink)" }

    let name: String
    let ayahIdentifier: String
    let ayahBitrate: String
    let surahLink: String
    var qiraah: String?

    /// When set, per-ayah audio is sourced from everyayah.com's `{surah}{ayah}.mp3` scheme in this folder
    /// instead of cdn.islamic.network's global-ayah-id scheme. Used for editions whose islamic.network feed is
    /// unreliable - notably Minshawi Mujawwad, whose `ar.minshawimujawwad` files are the *Murattal* recording
    /// for ~1 in 5 ayahs (verified by identical md5), which made playback audibly drop to Murattal mid-surah.
    var everyayahFolder: String? = nil

    /// For a Mujawwad/Muallim reciter that has no true per-ayah recording in that style anywhere, this names
    /// the Murattal that individual ayahs actually play instead (e.g. "Maher Al-Muaiqly (Murattal)"). Drives a
    /// heads-up confirmation on selection and the now-playing label during ayah/range playback. nil when the
    /// ayah audio matches the reciter's advertised style.
    var ayahMurattalStyleNote: String? = nil

    /// Surahs this reciter's mp3quran feed does NOT carry (some mushafs are partial - Islam Sobhi's covers
    /// 109 of 114). Optional so `Reciter` values persisted before the field existed still decode. Downloads
    /// skip these instead of dying on a 404, and playback explains instead of throwing a network error.
    var missingSurahs: Set<Int>? = nil

    /// The reciter's id in the QDC audio API (api.qurancdn.com - the service behind quran.com and QUL),
    /// which serves per-surah AYAH TIMESTAMPS. When set, downloaded surahs also fetch their timing table,
    /// and - once the timings are validated against the local file's duration - ayah and custom-range
    /// playback is cut from the downloaded surah file itself: the reciter's own voice, fully offline.
    /// nil = no timing source; every existing behavior is untouched.
    var qdcReciterID: Int? = nil

    func carriesSurah(_ surahNumber: Int) -> Bool {
        !(missingSurahs?.contains(surahNumber) ?? false)
    }

    /// How many surahs this reciter actually offers. THE completion denominator: comparing download
    /// counts against a flat 114 made a fully-downloaded partial-mushaf reciter (Islam Sobhi carries
    /// 109) read as forever-incomplete - and the incomplete-download purge then DELETED the finished
    /// download every time the reciter list appeared.
    var carriedSurahCount: Int {
        114 - (missingSurahs?.count ?? 0)
    }

    /// Settings / lists: append English riwayah when this row is a non-Hafs surah feed.
    var displayNameWithEnglishQiraah: String {
        if let q = qiraah, !q.isEmpty { return "\(name) (\(q))" }
        return name
    }

    /// Lock screen and now playing: show the selected reciter name, plus riwayah for qiraat surah feeds.
    var displayNameForNowPlaying: String {
        let base = name
        if let q = qiraah, !q.isEmpty { return "\(base) (\(q))" }
        return base
    }

    /// Display name used for the Minshawi ayah fallback feed.
    static let minshawiAyahFallbackName = "Muhammad Al-Minshawi (Murattal)"

    /// True when this reciter has no ayah-by-ayah feed of its own and falls back to Minshawi (Murattal) for
    /// individual ayah audio. A reciter with its own `everyayahFolder` is NOT a fallback - it plays its own
    /// voice from everyayah.com, so it must be excluded here (otherwise it would still show the Minshawi
    /// confirmation/label even though its ayahs are genuinely its own).
    var defaultToMinshawi: Bool {
        everyayahFolder == nil && ayahIdentifier.contains("minshawi") && !name.contains("Minshawi")
    }

    /// True when a downloaded surah can also be played ayah-by-ayah OFFLINE, by cutting each ayah out of the
    /// full-surah file using this reciter's QDC timing table (the reciter's own voice, no network). Backed by
    /// `qdcReciterID`.
    var supportsAyahSegments: Bool { qdcReciterID != nil }

    /// True when this reciter has NO per-ayah recitation of its own to stream - individual ayahs otherwise
    /// play in a substitute Murattal (`defaultToMinshawi` or a named `ayahMurattalStyleNote`). Combined with
    /// `supportsAyahSegments`, this is the "must load the whole surah to hear an ayah in this voice" case.
    var lacksOwnStreamedAyahs: Bool { defaultToMinshawi || ayahMurattalStyleNote != nil }

    static func < (lhs: Reciter, rhs: Reciter) -> Bool {
        lhs.name < rhs.name
    }

    static func == (lhs: Reciter, rhs: Reciter) -> Bool {
        lhs.id == rhs.id
    }
}

/// Hosting quirks for surah audio feeds. mp3quran hosts serve plain per-surah "NNN.mp3" files with
/// no strings attached. islamweb's audio library (audio.islamweb.net) serves the same per-surah
/// "NNN.mp3" layout from its Azure Front Door CDN, but that CDN rejects any request that does not
/// carry an islamweb Referer header (it 307s to the islamweb homepage instead). Every player /
/// downloader request for those files must therefore attach the header via these helpers.
enum ReciterAudioHosting {
    /// audio.islamweb.net's CDN host - the origin behind the islamweb riwayah audio library.
    static let islamwebCDNHost = "quran-fjamfcbbeybteyat.z01.azurefd.net"
    private static let islamwebReferer = "https://audio.islamweb.net/"

    /// Extra HTTP headers this URL's host requires; nil for hosts (mp3quran, everyayah,
    /// islamic.network) that need none.
    static func httpHeaders(for url: URL) -> [String: String]? {
        guard url.host == islamwebCDNHost else { return nil }
        return ["Referer": islamwebReferer]
    }

    /// `AVURLAsset` options carrying any required headers. Apple does not expose
    /// "AVURLAssetHTTPHeaderFieldsKey" as a Swift constant, hence the literal key.
    static func assetOptions(for url: URL) -> [String: Any] {
        guard let headers = httpHeaders(for: url) else { return [:] }
        return ["AVURLAssetHTTPHeaderFieldsKey": headers]
    }

    /// A URLRequest for fetching `url`, with any required headers attached.
    static func request(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        httpHeaders(for: url)?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        return request
    }
}

let reciters: [Reciter] = {
    let all =
        recitersMinshawi +
        recitersMurattal +
        recitersMujawwad +
        recitersMuallim +

        recitersShubah +
        recitersWarsh +
        recitersBuzzi +
        recitersQunbul +
        recitersQaloon +
        recitersDuri +
        recitersSusi +
        recitersKhalaf +
        recitersHisham +
        recitersIbnDhakwan +
        recitersKhallad +
        recitersAbuHarith +
        recitersDuriKisai +
        recitersIbnWardan +
        recitersIbnJammaz +
        recitersRuways +
        recitersRawh +
        recitersIshaq +
        recitersIdris
    // The Minshawi variants intentionally appear in both `recitersMinshawi` and their style list, so the
    // combined lookup/random list must drop the duplicate ids (else `randomElement()` is biased and any
    // ForEach over `reciters` hits duplicate ids).
    var seen = Set<String>()
    return all.filter { seen.insert($0.id).inserted }.sorted()
}()

let recitersMinshawi = [
    Reciter(name: "Muhammad Al-Minshawi (Murattal)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/minsh/", qdcReciterID: 9),
    Reciter(name: "Muhammad Al-Minshawi (Mujawwad)", ayahIdentifier: "ar.minshawimujawwad", ayahBitrate: "64", surahLink: "https://server10.mp3quran.net/minsh/Almusshaf-Al-Mojawwad/", everyayahFolder: "Minshawy_Mujawwad_192kbps"),
    Reciter(name: "Muhammad Al-Minshawi (Muallim)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/minsh/Almusshaf-Al-Mo-lim/", ayahMurattalStyleNote: "Muhammad Al-Minshawi (Murattal)")
].sorted()

let recitersMurattal = [
    Reciter(name: "Abdul Basit (Murattal)", ayahIdentifier: "ar.abdulbasitmurattal", ayahBitrate: "192", surahLink: "https://server7.mp3quran.net/basit/", qdcReciterID: 2),
    Reciter(name: "Abdul Rahman Al-Sudais", ayahIdentifier: "ar.abdurrahmaansudais", ayahBitrate: "192", surahLink: "https://server11.mp3quran.net/sds/", qdcReciterID: 3),
    Reciter(name: "Abu Bakr Al-Shatri", ayahIdentifier: "ar.shaatree", ayahBitrate: "128", surahLink: "https://server11.mp3quran.net/shatri/", qdcReciterID: 4),
    Reciter(name: "Ahmad Deban", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/deban/Rewayat-Hafs-A-n-Assem/"),
    Reciter(name: "Mahmoud Al-Hussary (Murattal)", ayahIdentifier: "ar.husary", ayahBitrate: "128", surahLink: "https://server13.mp3quran.net/husr/", qdcReciterID: 6),
    Reciter(name: "Maher Al-Muaiqly (Murattal)", ayahIdentifier: "ar.mahermuaiqly", ayahBitrate: "128", surahLink: "https://server12.mp3quran.net/maher/"),
    Reciter(name: "Mishary Alafasy", ayahIdentifier: "ar.alafasy", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/afs/", qdcReciterID: 7),
    Reciter(name: "Abdullah Al-Juhany", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server13.mp3quran.net/jhn/", everyayahFolder: "Abdullaah_3awwaad_Al-Juhaynee_128kbps"),
    Reciter(name: "Abdurrasheed Sufi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/soufi/Rewayat-Hafs-A-n-Assem/"),
    Reciter(name: "Bandar Baleela", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server6.mp3quran.net/balilah/"),
    Reciter(name: "Badr Al-Turki", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/bader/Rewayat-Hafs-A-n-Assem/"),
    Reciter(name: "Muhammad Al-Luhaidan", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/lhdan/"),
    Reciter(name: "Abdullah Al Qarafi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/a_alqrafi/Rewayat-Hafs-A-n-Assem/"),
    Reciter(name: "Muhammad Al-Minshawi (Murattal)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/minsh/", qdcReciterID: 9),
    Reciter(name: "Muhammad Jibreel", ayahIdentifier: "ar.muhammadjibreel", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/jbrl/"),
    Reciter(name: "Mustafa Ismail (Murattal)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/mustafa/"),
    Reciter(name: "Mahmoud Ali Al-Banna (Murattal)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/bna/", everyayahFolder: "mahmoud_ali_al_banna_32kbps"),
    Reciter(name: "Saud Al-Shuraim", ayahIdentifier: "ar.saoodshuraym", ayahBitrate: "64", surahLink: "https://server7.mp3quran.net/shur/", qdcReciterID: 10),
    Reciter(name: "Hani Al-Rifai", ayahIdentifier: "ar.hanirifai", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/hani/", qdcReciterID: 5),
    Reciter(name: "Ahmad Al-Ajmy", ayahIdentifier: "ar.ahmedajamy", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/ajm/"),
    Reciter(name: "Muhammad Ayyub", ayahIdentifier: "ar.muhammadayyoub", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/ayyub/"),
    Reciter(name: "Muhammad Ayyub (Special)", ayahIdentifier: "ar.muhammadayyoub", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/ayyoub2/Rewayat-Hafs-A-n-Assem/"),
    Reciter(name: "Abdulrahman Aloosi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server6.mp3quran.net/aloosi/"),
    Reciter(name: "Hazza Al-Balushi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server11.mp3quran.net/hazza/"),
    Reciter(name: "Ali Jaber", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server11.mp3quran.net/a_jbr/", everyayahFolder: "Ali_Jaber_64kbps"),
    Reciter(name: "Saad Al-Ghamdi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server7.mp3quran.net/s_gmd/", everyayahFolder: "Ghamadi_40kbps"),
    Reciter(name: "Yasser Al-Dosari", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server11.mp3quran.net/yasser/", everyayahFolder: "Yasser_Ad-Dussary_128kbps", qdcReciterID: 97),
    Reciter(name: "Abdullah Al-Mattrod", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/mtrod/", everyayahFolder: "Abdullah_Matroud_128kbps"),
    Reciter(name: "Ahmad Al-Nufais", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/nufais/Rewayat-Hafs-A-n-Assem/"),
    // mp3quran carries 109 of 114 surahs for this mushaf (their API's surah_list omits these five).
    Reciter(name: "Islam Sobhi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server14.mp3quran.net/islam/Rewayat-Hafs-A-n-Assem/", missingSurahs: [37, 39, 40, 45, 65]),
    Reciter(name: "Mohamed Al-Tablawi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server12.mp3quran.net/tblawi/", everyayahFolder: "Mohammad_al_Tablaway_128kbps"),
    Reciter(name: "Khalifa Al-Tunaiji", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server12.mp3quran.net/tnjy/", everyayahFolder: "khalefa_al_tunaiji_64kbps", qdcReciterID: 161)
].sorted()

let recitersMujawwad = [
    Reciter(name: "Abdul Basit (Mujawwad)", ayahIdentifier: "ar.abdulsamad", ayahBitrate: "64", surahLink: "https://server7.mp3quran.net/basit/Almusshaf-Al-Mojawwad/", qdcReciterID: 1),
    Reciter(name: "Mahmoud Al-Hussary (Mujawwad)", ayahIdentifier: "ar.husarymujawwad", ayahBitrate: "128", surahLink: "https://server13.mp3quran.net/husr/Almusshaf-Al-Mojawwad/"),
    Reciter(name: "Maher Al-Muaiqly (Mujawwad)", ayahIdentifier: "ar.mahermuaiqly", ayahBitrate: "128", surahLink: "https://server12.mp3quran.net/maher/Almusshaf-Al-Mojawwad/", ayahMurattalStyleNote: "Maher Al-Muaiqly (Murattal)"),
    Reciter(name: "Muhammad Al-Minshawi (Mujawwad)", ayahIdentifier: "ar.minshawimujawwad", ayahBitrate: "64", surahLink: "https://server10.mp3quran.net/minsh/Almusshaf-Al-Mojawwad/", everyayahFolder: "Minshawy_Mujawwad_192kbps"),
    Reciter(name: "Mustafa Ismail (Mujawwad)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/mustafa/Almusshaf-Al-Mojawwad/"),
    Reciter(name: "Mahmoud Ali Al-Banna (Mujawwad)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/bna/Almusshaf-Al-Mojawwad/", everyayahFolder: "mahmoud_ali_al_banna_32kbps")
].sorted()

let recitersMuallim = [
    Reciter(name: "Maher Al-Muaiqly (Muallim)", ayahIdentifier: "ar.mahermuaiqly", ayahBitrate: "128", surahLink: "https://server12.mp3quran.net/maher/Almusshaf-Al-Mo-lim/", ayahMurattalStyleNote: "Maher Al-Muaiqly (Murattal)"),
    Reciter(name: "Muhammad Al-Minshawi (Muallim)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/minsh/Almusshaf-Al-Mo-lim/", ayahMurattalStyleNote: "Muhammad Al-Minshawi (Murattal)")
].sorted()

let recitersShubah = [
    // Trailing "/" only: QuranPlayer appends "NNN.mp3" itself - the old link ended in "001.mp3",
    // so every surah request became ".../001.mp3001.mp3" and 404'd.
    Reciter(name: "Ahmad Deban", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/deban/Rewayat-Sho-bah-A-n-Asim/", qiraah: Settings.Riwayah.shubah),
].sorted()

let recitersKhalaf = [
    Reciter(name: "Abdurrasheed Sufi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/soufi/Rewayat-Khalaf-A-n-Hamzah/", qiraah: Settings.Riwayah.khalaf)
].sorted()

let recitersWarsh = [
    Reciter(name: "Ahmad Deban", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/deban/Rewayat-Warsh-A-n-Nafi-Men-Tariq-Alazraq/", qiraah: Settings.Riwayah.warsh),
    Reciter(name: "Abdul Basit", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server7.mp3quran.net/basit/Rewayat-Warsh-A-n-Nafi/", qiraah: Settings.Riwayah.warsh),
    Reciter(name: "Mahmoud Al-Hussary", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server13.mp3quran.net/husr/Rewayat-Warsh-A-n-Nafi/", qiraah: Settings.Riwayah.warsh),
    Reciter(name: "Al-Qari Yassin", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server11.mp3quran.net/qari/", qiraah: Settings.Riwayah.warsh),
    Reciter(name: "Al-Uyoun Al-Koshi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server11.mp3quran.net/koshi/", qiraah: Settings.Riwayah.warsh),
    Reciter(name: "Hisham Al Haraz", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/H-Lharraz/Rewayat-Warsh-A-n-Nafi/", qiraah: Settings.Riwayah.warsh),
    Reciter(name: "Ibrahim Al-Dossary", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/ibrahim_dosri/Rewayat-Warsh-A-n-Nafi/", qiraah: Settings.Riwayah.warsh),
    Reciter(name: "Muhammad Sayed", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/m_sayed/Rewayat-Warsh-A-n-Nafi/", qiraah: Settings.Riwayah.warsh),
    Reciter(name: "Omar Al-Qazabri", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server9.mp3quran.net/omar_warsh/", qiraah: Settings.Riwayah.warsh),
    Reciter(name: "Rachid Belalya", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server6.mp3quran.net/bl3/Rewayat-Warsh-A-n-Nafi/", qiraah: Settings.Riwayah.warsh),
    Reciter(name: "Rachid Ifrad", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server12.mp3quran.net/ifrad/", qiraah: Settings.Riwayah.warsh),
    Reciter(name: "Younes Souilass", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/souilass/Rewayat-Warsh-A-n-Nafi/", qiraah: Settings.Riwayah.warsh)
].sorted()

let recitersBuzzi = [
    Reciter(name: "Ahmad Deban", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/deban/Rewayat-Albizi-A-n-Ibn-Katheer/", qiraah: Settings.Riwayah.buzzi),
    Reciter(name: "Okasha Kameny", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/okasha/Rewayat-Albizi-A-n-Ibn-Katheer/", qiraah: Settings.Riwayah.buzzi)
].sorted()

let recitersQunbul = [
    Reciter(name: "Ahmad Deban", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/deban/Rewayat-Qunbol-A-n-Ibn-Katheer/", qiraah: Settings.Riwayah.qunbul)
].sorted()

let recitersQaloon = [
    Reciter(name: "Ahmad Deban", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/deban/Rewayat-Qalon-A-n-Nafi/", qiraah: Settings.Riwayah.qaloon),
    Reciter(name: "Mahmoud Al-Hussary", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server13.mp3quran.net/husr/Rewayat-Qalon-A-n-Nafi/", qiraah: Settings.Riwayah.qaloon),
    Reciter(name: "Ahmed Al-Trabulsi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/trablsi/", qiraah: Settings.Riwayah.qaloon),
    Reciter(name: "Ibrahim Qushaydan", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/i_kshidan/Rewayat-Qalon-A-n-Nafi/", qiraah: Settings.Riwayah.qaloon),
    Reciter(name: "Tareq Daawob", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/tareq/", qiraah: Settings.Riwayah.qaloon)
].sorted()

let recitersDuri = [
    Reciter(name: "Noreen Mohammad Siddiq", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/nourin_siddig/Rewayat-Aldori-A-n-Abi-Amr/", qiraah: Settings.Riwayah.duri),
    Reciter(name: "Mahmoud Al-Hussary", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server13.mp3quran.net/husr/Rewayat-Aldori-A-n-Abi-Amr/", qiraah: Settings.Riwayah.duri),
    Reciter(name: "Ahmad Deban", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/deban/Rewayat-Aldori-A-n-Abi-Amr/", qiraah: Settings.Riwayah.duri)
].sorted()

let recitersSusi = [
    Reciter(name: "Abdurrasheed Sufi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/soufi/Rewayat-Assosi-A-n-Abi-Amr/", qiraah: Settings.Riwayah.susi)
].sorted()

// MARK: The ten remaining riwayat - one complete reciter each, so EVERY riwayah the app can
// display also has full-surah audio. mp3quran's API carries complete mushafs for Ibn Dhakwan and
// ad-Duri al-Kisai; the other eight stream from islamweb's audio library (audio.islamweb.net),
// whose per-surah files use the same "NNN.mp3" naming but sit behind a Referer-checking CDN -
// `ReciterAudioHosting` attaches the required header. Each URL pattern below was verified
// complete: all 114 surah files return HTTP 200/206 with an audio/mpeg content type.

let recitersHisham = [
    // islamweb: "Meftah Mohammed Alstunai", the same reciter mp3quran anglicizes as Muftah Alsaltany.
    Reciter(name: "Muftah Alsaltany", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://quran-fjamfcbbeybteyat.z01.azurefd.net/Audio3/quran/MeftahAlstunai/HishamIbnAmer/", qiraah: Settings.Riwayah.hisham)
].sorted()

let recitersIbnDhakwan = [
    // NOTE the underscore after "Rewayat" - that is how mp3quran's API spells this mushaf's path.
    Reciter(name: "Muftah Alsaltany", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server14.mp3quran.net/muftah_sultany/Rewayat_Ibn-Thakwan-A-n-Ibn-Amer/", qiraah: Settings.Riwayah.ibnDhakwan)
].sorted()

let recitersKhallad = [
    Reciter(name: "Karim Rajeh", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://quran-fjamfcbbeybteyat.z01.azurefd.net/Audio3/quran/KarimRajeh/khalad_hamzah/", qiraah: Settings.Riwayah.khallad)
].sorted()

let recitersAbuHarith = [
    Reciter(name: "Karim Rajeh", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://quran-fjamfcbbeybteyat.z01.azurefd.net/Audio3/quran/KarimRajeh/AbuHarith-Alexaii/", qiraah: Settings.Riwayah.abuHarith)
].sorted()

let recitersDuriKisai = [
    Reciter(name: "Mohammad Al-Abdullah", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server9.mp3quran.net/abdullah/Rewayat-AlDorai-A-n-Al-Kisa-ai/", qiraah: Settings.Riwayah.duriKisai)
].sorted()

let recitersIbnWardan = [
    Reciter(name: "Muftah Alsaltany", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://quran-fjamfcbbeybteyat.z01.azurefd.net/Audio3/quran/MeftahAlstunai/ibnwerdan_abujaafar/", qiraah: Settings.Riwayah.ibnWardan)
].sorted()

let recitersIbnJammaz = [
    Reciter(name: "Muftah Alsaltany", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://quran-fjamfcbbeybteyat.z01.azurefd.net/Audio3/quran/MeftahAlstunai/ibnjumaz_abujaafar/", qiraah: Settings.Riwayah.ibnJammaz)
].sorted()

let recitersRuways = [
    Reciter(name: "Muftah Alsaltany", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://quran-fjamfcbbeybteyat.z01.azurefd.net/Audio3/quran/MeftahAlstunai/rowais_yaqoob/", qiraah: Settings.Riwayah.ruways)
].sorted()

let recitersRawh = [
    Reciter(name: "Abdullah Mohammed Hamid", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://quran-fjamfcbbeybteyat.z01.azurefd.net/Audio3/quran/AbdullahMohammedHamid/rawh_yaqoob/", qiraah: Settings.Riwayah.rawh)
].sorted()

let recitersIshaq = [
    // islamweb's set is missing surah 4 (An-Nisa) - its 004.mp3 is a genuine 404 on their CDN.
    Reciter(name: "Muftah Alsaltany", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://quran-fjamfcbbeybteyat.z01.azurefd.net/Audio3/quran/MeftahAlstunai/eshaq_khalaf/", qiraah: Settings.Riwayah.ishaq, missingSurahs: [4])
].sorted()

let recitersIdris = [
    Reciter(name: "Muftah Alsaltany", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://quran-fjamfcbbeybteyat.z01.azurefd.net/Audio3/quran/MeftahAlstunai/edris_khalaf/", qiraah: Settings.Riwayah.idris)
].sorted()
