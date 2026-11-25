import Foundation
#if os(iOS)
import SwiftUI
import UIKit
import LinkPresentation
#endif

// Links to one thing in the app: an ayah, a hadith, an article, a Name of Allah, a resource.
//
// A link is one `key=value` pair, and three kinds of URL carry it:
//
//   https://<linkHost><linkPath>?quran=2:255     what people share (`AppLink.url`)
//   alislam://open?quran=2:255                   the app's own scheme (`AppLink.schemeURL`)
//   alislam://ayah/2/255                         the widgets' older form, still read
//
// The web address is a UNIVERSAL LINK: the host serves an apple-app-site-association file naming
// this app (the Website folder), so on a device with the app installed iOS opens the app directly
// and hands it the URL. Without the app the same address is an ordinary web page, which sends the
// visitor to the App Store. Nothing here needs a server: the page is static.
//
// The grammar (every value is validated on the way in, a link can carry anything):
//
//   quran=2            a surah                 quran=2:255        an ayah
//   hadith=bukhari     a book                  hadith=muslim:8a   a hadith, by the number readers cite
//   article=pillars.shahadah                   an article of Pillars & Beliefs, How-To or Proving Islam
//   sunnah=<id>  prophecy=<id>  sign=<id>  miracle=<slug>         a page of those four libraries
//   name=5             one of the 99 Names     islam=commonDuas   a resource of the Islam tab
//   tajweed=sukoon     a page of Tajweed Foundations (`TajweedTopic.linkKey`)
//   lesson=sukoon      a lesson of the Tajweed Course
//   tafsir=2:255  translations=2:255  qiraah=2:255               an ayah's tafsir or comparison sheet
//   explanation=bukhari:1   a hadith's explanation   explanation=5907   a Hadith Encyclopedia entry
//   tab=settings       a tab, nothing pushed
//
// A hadith's value is what the app prints beside it (`displayNumber`): the standard citation
// ("2950", "8a"), "intro-9" for Sahih Muslim's Introduction, "3:12" (chapter:position) for a row
// with no citation, or the row number in a book that cites nothing. `id-<n>` is the row itself, used
// only when the printed number does not lead back to the same row.
//
// The parser also reads the pair as a PATH (`.../alislam/quran/2/255`, `alislam://quran/2/255`) and
// as a fragment, so the web address can move to path form later without stranding older builds.

enum AppLink: Equatable {
    /// "adhan", "quran", "hadith", "islam", "settings", or "qibla" (the compass on the Adhan tab).
    case tab(String)
    case surah(Int)
    case ayah(surah: Int, ayah: Int)
    case hadithBook(slug: String)
    case hadith(slug: String, reference: String)
    /// `IslamArticleEntry.linkKey`: "pillars.shahadah".
    case article(String)
    case sunnah(String)
    case prophecy(String)
    case prophetMiracle(String)
    case miracle(String)
    case name(Int)
    /// A resource of the Islam tab, by its destination's raw value ("zakahCalculator").
    case resource(String)
    /// A page of Tajweed Foundations, by its `TajweedTopic.linkKey` ("hamzatul-wasl").
    case tajweed(String)
    /// A lesson of the Tajweed Course, by its id in the course pack ("sukoon").
    case lesson(String)
    /// An ayah's tafsir sheet, opened over the reader at the ayah.
    case tafsir(surah: Int, ayah: Int)
    /// An ayah's Translation Comparison, opened over the reader at the ayah.
    case translations(surah: Int, ayah: Int)
    /// An ayah's Qiraah Comparison, opened over the reader at the ayah.
    case qiraah(surah: Int, ayah: Int)
    /// The explanation of a narration on the shelf (the Hadith Encyclopedia's page linked to it), by
    /// the value a hadith link carries ("bukhari:1").
    case explanation(slug: String, reference: String)
    /// A Hadith Encyclopedia entry, by its id ("5907"): the same page, for one the shelf does not link.
    case encyclopedia(String)

    static let tabNames: Set<String> = ["adhan", "quran", "hadith", "islam", "settings", "qibla"]

    // MARK: The pair

    var key: String {
        switch self {
        case .tab: return "tab"
        case .surah, .ayah: return "quran"
        case .hadithBook, .hadith: return "hadith"
        case .article: return "article"
        case .sunnah: return "sunnah"
        case .prophecy: return "prophecy"
        case .prophetMiracle: return "sign"
        case .miracle: return "miracle"
        case .name: return "name"
        case .resource: return "islam"
        case .tajweed: return "tajweed"
        case .lesson: return "lesson"
        case .tafsir: return "tafsir"
        case .translations: return "translations"
        case .qiraah: return "qiraah"
        case .explanation, .encyclopedia: return "explanation"
        }
    }

    var value: String {
        switch self {
        case .tab(let name): return name
        case .surah(let surah): return String(surah)
        case .ayah(let surah, let ayah): return "\(surah):\(ayah)"
        case .hadithBook(let slug): return slug
        case .hadith(let slug, let reference): return "\(slug):\(reference)"
        case .article(let key): return key
        case .sunnah(let id), .prophecy(let id), .prophetMiracle(let id), .miracle(let id): return id
        case .name(let number): return String(number)
        case .resource(let raw): return raw
        case .tajweed(let key): return key
        case .lesson(let id): return id
        case .tafsir(let surah, let ayah), .translations(let surah, let ayah), .qiraah(let surah, let ayah):
            return "\(surah):\(ayah)"
        case .explanation(let slug, let reference): return "\(slug):\(reference)"
        case .encyclopedia(let id): return id
        }
    }

    /// A link from one pair. Nil for a key this build does not know or a value outside its shape:
    /// a link is outside text, so nothing past this point has to distrust it.
    init?(key: String, value rawValue: String) {
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, value.utf8.count <= 96 else { return nil }
        switch key.lowercased() {
        case "tab":
            let name = value.lowercased()
            guard Self.tabNames.contains(name) else { return nil }
            self = .tab(name)
        case "quran", "ayah", "surah":
            // "2:255", and the separators a path or a hand-typed link arrives with. "ayah" (the
            // widgets' word) names an ayah and "surah" a surah; "quran" is either.
            let parts = value.split(whereSeparator: { ":/.-".contains($0) })
            let wanted = key.lowercased() == "ayah" ? 2...2 : key.lowercased() == "surah" ? 1...1 : 1...2
            guard wanted.contains(parts.count), let surah = Self.number(parts[0]), (1...114).contains(surah) else { return nil }
            if parts.count == 2 {
                // 286 is the longest surah; the reader clamps to the surah's own count.
                guard let ayah = Self.number(parts[1]), (1...286).contains(ayah) else { return nil }
                self = .ayah(surah: surah, ayah: ayah)
            } else {
                self = .surah(surah)
            }
        case "hadith":
            let lowered = value.lowercased()
            guard let cut = lowered.firstIndex(where: { $0 == ":" || $0 == "/" }) else {
                guard Self.isIdentifier(lowered) else { return nil }
                self = .hadithBook(slug: lowered)
                return
            }
            let slug = String(lowered[..<cut])
            let reference = String(lowered[lowered.index(after: cut)...]).replacingOccurrences(of: "/", with: ":")
            guard Self.isIdentifier(slug), Self.isHadithReference(reference) else { return nil }
            self = .hadith(slug: slug, reference: reference)
        case "article":
            guard Self.isIdentifier(value) else { return nil }
            self = .article(value)
        case "sunnah":
            guard Self.isIdentifier(value) else { return nil }
            self = .sunnah(value)
        case "prophecy":
            guard Self.isIdentifier(value) else { return nil }
            self = .prophecy(value)
        case "sign":
            guard Self.isIdentifier(value) else { return nil }
            self = .prophetMiracle(value)
        case "miracle":
            guard Self.isIdentifier(value) else { return nil }
            self = .miracle(value)
        case "name":
            guard let number = Self.number(Substring(value)), (1...99).contains(number) else { return nil }
            self = .name(number)
        case "islam":
            guard Self.isIdentifier(value) else { return nil }
            self = .resource(value)
        case "tajweed":
            guard Self.isIdentifier(value) else { return nil }
            self = .tajweed(value)
        case "lesson":
            guard Self.isIdentifier(value) else { return nil }
            self = .lesson(value)
        case "tafsir", "translations", "qiraah":
            // One ayah, written the way a quran link writes it.
            let parts = value.split(whereSeparator: { ":/.-".contains($0) })
            guard parts.count == 2, let surah = Self.number(parts[0]), (1...114).contains(surah),
                  let ayah = Self.number(parts[1]), (1...286).contains(ayah) else { return nil }
            switch key.lowercased() {
            case "tafsir": self = .tafsir(surah: surah, ayah: ayah)
            case "translations": self = .translations(surah: surah, ayah: ayah)
            default: self = .qiraah(surah: surah, ayah: ayah)
            }
        case "explanation":
            // "bukhari:1" names a narration the way a hadith link does; a bare number is an entry of
            // the encyclopedia itself.
            let lowered = value.lowercased()
            if let cut = lowered.firstIndex(where: { $0 == ":" || $0 == "/" }) {
                let slug = String(lowered[..<cut])
                let reference = String(lowered[lowered.index(after: cut)...]).replacingOccurrences(of: "/", with: ":")
                guard Self.isIdentifier(slug), Self.isHadithReference(reference) else { return nil }
                self = .explanation(slug: slug, reference: reference)
            } else {
                guard value.count <= 9, value.allSatisfy({ $0.isASCII && $0.isNumber }) else { return nil }
                self = .encyclopedia(value)
            }
        default:
            return nil
        }
    }

    /// Western digits only, and few of them: `Int("٢")` is nil already, but "0000000000000000002" is not.
    private static func number(_ text: Substring) -> Int? {
        guard !text.isEmpty, text.count <= 5, text.allSatisfy({ $0.isASCII && $0.isNumber }) else { return nil }
        return Int(text)
    }

    /// An id as the app writes its own: letters, digits, and the three joiners.
    private static func isIdentifier(_ text: String) -> Bool {
        !text.isEmpty && text.utf8.count <= 80 && text.unicodeScalars.allSatisfy {
            ($0.isASCII && ($0.properties.isAlphabetic || ("0"..."9").contains(Character($0)))) || $0 == "-" || $0 == "_" || $0 == "."
        }
    }

    /// "15", "8a", "1211aa", "3:12", "intro-9", "id-3033". Western digits spelled out: `\d` would
    /// take every script's digits, and the rest of the link is plain ASCII.
    private static func isHadithReference(_ text: String) -> Bool {
        text.range(of: #"^(intro-[0-9]{1,5}[a-z]{0,2}|id-[0-9]{1,6}|[0-9]{1,5}[a-z]{0,2}|[0-9]{1,5}:[0-9]{1,5})$"#, options: .regularExpression) != nil
    }

    // MARK: URLs

    /// The address people share: it opens the app where the app is installed, and the App Store's
    /// page for it everywhere else.
    var url: URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = AppIdentifiers.linkHost
        components.path = AppIdentifiers.linkPath
        components.queryItems = [URLQueryItem(name: key, value: value)]
        // Every part is validated ASCII from `init(key:value:)`'s alphabet or the constants above.
        return components.url ?? AppIdentifiers.appStoreURL
    }

    /// The same link on the app's own scheme. It only works where the app is installed, so it is
    /// for the app's own use (the web page's "Open in Al-Islam" button builds the same string).
    var schemeURL: URL? {
        var components = URLComponents()
        components.scheme = AppIdentifiers.linkScheme
        components.host = "open"
        components.queryItems = [URLQueryItem(name: key, value: value)]
        return components.url
    }

    /// Reads any of the three URL forms. Nil for every other URL, including the app's own web
    /// address with nothing after it (which just opens the app).
    init?(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        var segments: [String]
        switch components.scheme?.lowercased() {
        case AppIdentifiers.linkScheme:
            // The host is the first word of the route here: alislam://ayah/2/255.
            segments = ([components.host ?? ""] + url.pathComponents).filter { !$0.isEmpty && $0 != "/" }
            if segments.first?.lowercased() == "open" { segments.removeFirst() }
        case "https", "http":
            guard components.host?.lowercased() == AppIdentifiers.linkHost else { return nil }
            let prefix = AppIdentifiers.linkPath.split(separator: "/").map { $0.lowercased() }
            let path = url.pathComponents.filter { $0 != "/" }
            guard path.count >= prefix.count,
                  zip(path, prefix).allSatisfy({ $0.lowercased() == $1 }) else { return nil }
            segments = Array(path.dropFirst(prefix.count)).filter { $0.lowercased() != "index.html" }
        default:
            return nil
        }

        // The pair as a query item: the shared form. Other items (a tracker's, a messenger's) are skipped.
        for item in components.queryItems ?? [] {
            if let value = item.value, let link = AppLink(key: item.name, value: value) {
                self = link
                return
            }
        }
        // As a path, or failing that a fragment: kind/value, with the value's own parts rejoined.
        if segments.isEmpty, let fragment = components.fragment {
            segments = fragment.split(separator: "/").map(String.init)
        }
        guard let kind = segments.first,
              let link = AppLink(key: kind, value: segments.dropFirst().joined(separator: ":")) else { return nil }
        self = link
    }
}

// MARK: - Article pages

extension AppLink {
    /// The link to an article page, from the id the page gives `selectableArticleList(article:)`:
    /// a catalog id ("ShahadahView"), a generated page's ("Sunnah-waking-praise"), or a Tajweed
    /// Foundations page's (`TajweedTopic.pageID`). Nil for a page with no place of its own to open (a
    /// qiraat biography).
    @MainActor
    static func articlePage(id: String) -> (link: AppLink, title: String)? {
        if let entry = IslamArticleCatalog.byID[id] {
            return (.article(entry.linkKey), entry.title)
        }
        if let topic = TajweedTopic.topic(pageID: id) {
            // The pages are translated, so the share sheet's title is the one the reader sees.
            return (.tajweed(topic.linkKey), topic.title.localizedDisplay)
        }
        if id.hasPrefix(IslamArticle.lessonPrefix) {
            let key = String(id.dropFirst(IslamArticle.lessonPrefix.count))
            let lesson = TajweedLessonsStore.shared.courseIfLoaded?.lessons.first { $0.id == key }
            return (.lesson(key), lesson?.titleEn.localizedDisplay ?? String(localized: "Tajweed Course"))
        }
        if id.hasPrefix("Sunnah-") {
            let key = String(id.dropFirst("Sunnah-".count))
            return SunnahView.entries.first { $0.id == key }.map { (.sunnah(key), $0.title) }
        }
        if id.hasPrefix("Prophecy-") {
            let key = String(id.dropFirst("Prophecy-".count))
            return PropheciesView.entries.first { $0.id == key }.map { (.prophecy(key), $0.title) }
        }
        if id.hasPrefix("ProphetMiracle-") {
            let key = String(id.dropFirst("ProphetMiracle-".count))
            return ProphetMiraclesView.entries.first { $0.id == key }.map { (.prophetMiracle(key), $0.title) }
        }
        return nil
    }
}

// MARK: - Hadith references

#if HAS_HADITH
extension AppLink {
    /// The link to one hadith. The value is the number the app prints beside it wherever that number
    /// leads back to this row, and the row itself where it does not (two rows under one citation).
    static func hadith(_ hadith: HadithBookData.Hadith, in book: HadithCatalogBook, data: HadithBookData?) -> AppLink {
        let printed: String
        if let citation = hadith.citation {
            printed = (hadith.isIntroduction ? "intro-\(citation)" : citation).lowercased()
        } else {
            printed = hadith.displayNumber.lowercased()
        }
        if isHadithReference(printed),
           data == nil || data.flatMap({ resolve(reference: printed, in: $0) })?.idInBook == hadith.idInBook {
            return .hadith(slug: book.slug, reference: printed)
        }
        return .hadith(slug: book.slug, reference: "id-\(hadith.idInBook)")
    }

    /// The hadith a link's reference names in `data`, by the rules the hadith search already reads
    /// "muslim 8a", "muslim introduction 9" and "bukhari 1:4" with.
    static func resolve(reference: String, in data: HadithBookData) -> HadithBookData.Hadith? {
        let text = reference.lowercased()
        if text.hasPrefix("id-") {
            return Int(text.dropFirst(3)).flatMap { data.hadith(numbered: $0) }
        }
        if let colon = text.firstIndex(of: ":") {
            guard let chapter = Int(text[..<colon]), let position = Int(text[text.index(after: colon)...]) else { return nil }
            return data.hadith(chapterPosition: chapter, position: position)
        }
        let introduction = text.hasPrefix("intro-")
        let cited = introduction ? text.dropFirst(6) : Substring(text)
        let digits = cited.prefix { $0.isASCII && $0.isNumber }
        let suffix = String(cited.dropFirst(digits.count))
        guard let number = Int(digits) else { return nil }
        return data.hadith(referenced: number, suffix: suffix.isEmpty ? nil : suffix, introduction: introduction)
    }
}
#endif

// MARK: - Opening a link

/// Where a link lands. Every case hands its target to `AppNavigation`, the door a notification tap
/// and a widget tap already use: the tab view switches tabs on the publish and the tab opens it.
@MainActor
enum AppLinkRouter {
    /// The last URL opened and when: SwiftUI can deliver one universal link to both `onOpenURL` and
    /// `onContinueUserActivity`, and the second delivery would push the same page again.
    private static var last: (url: URL, at: Date)?

    /// Opens what `url` points at. False for a URL that is not one of the app's links.
    @discardableResult
    static func open(_ url: URL) -> Bool {
        guard let link = AppLink(url: url) else { return false }
        if let last, last.url == url, Date().timeIntervalSince(last.at) < 1.5 { return true }
        last = (url, Date())
        open(link)
        return true
    }

    static func open(_ link: AppLink) {
        closeWhatIsOpen()
        let navigation = AppNavigation.shared
        switch link {
        case .tab(let name):
            if name == "qibla" {
                navigation.openAdhan(.qibla)
            } else {
                navigation.pendingTab = name
            }
        case .surah(let surah):
            #if HAS_QURAN
            navigation.open(.surah(surah))
            #else
            navigation.pendingTab = "islam"
            #endif
        case .ayah(let surah, let ayah):
            #if HAS_QURAN
            navigation.open(.ayah(surah, ayah))
            #else
            navigation.pendingTab = "islam"
            #endif
        case .hadithBook(let slug):
            #if HAS_HADITH
            // A book this build does not carry still lands on the shelf.
            if HadithCatalogBook.bySlug[slug] != nil {
                navigation.pendingHadithBook = slug
            } else {
                navigation.pendingTab = "hadith"
            }
            #else
            navigation.pendingTab = "islam"
            #endif
        case .hadith(let slug, let reference):
            #if HAS_HADITH
            guard let book = HadithCatalogBook.bySlug[slug] else {
                navigation.pendingTab = "hadith"
                return
            }
            if let data = HadithStore.shared.book(book), let hadith = AppLink.resolve(reference: reference, in: data) {
                navigation.openHadith(slug: slug, idInBook: hadith.idInBook)
            } else {
                // The number names nothing in this build's copy of the book: the book itself.
                navigation.pendingHadithBook = slug
            }
            #else
            navigation.pendingTab = "islam"
            #endif
        case .article(let key):
            if let entry = IslamArticleCatalog.entry(linkKey: key) {
                navigation.openIslam(.page(.article(entry.id)))
            } else {
                navigation.openIslam(.tab)
            }
        // A page this build does not carry (a later version's) opens the library it belongs to.
        case .sunnah(let id):
            navigation.openIslam(SunnahView.entries.contains { $0.id == id }
                                 ? .page(.sunnah(id)) : .resource("sunnahsOfProphet"))
        case .prophecy(let id):
            navigation.openIslam(PropheciesView.entries.contains { $0.id == id }
                                 ? .page(.prophecy(id)) : .resource("propheciesOfProphet"))
        case .prophetMiracle(let id):
            navigation.openIslam(ProphetMiraclesView.entries.contains { $0.id == id }
                                 ? .page(.prophetMiracle(id)) : .resource("miraclesOfProphets"))
        case .miracle(let slug):
            // The Miracles library parses on first use, so the Islam tab checks the slug once it has.
            navigation.openIslam(.page(.miracle(slug)))
        case .name(let number):
            navigation.openIslam(.names(number))
        case .resource(let raw):
            navigation.openIslam(.resource(raw))
        case .tajweed(let key):
            // A page this build does not carry (a later version's) opens Tajweed Foundations itself.
            navigation.openIslam(TajweedTopic(linkKey: key).map { .page(.tajweed($0.rawValue)) }
                                 ?? .resource("tajweedFoundations"))
        case .lesson(let id):
            // The course parses its pack before the push (IslamView), and a lesson it does not carry
            // shows its own "could not be loaded" line over the course.
            navigation.openIslam(.page(.lesson(id)))
        case .tafsir(let surah, let ayah), .translations(let surah, let ayah), .qiraah(let surah, let ayah):
            #if HAS_QURAN
            // The reader goes to the ayah first, so closing the sheet leaves the reader on it.
            navigation.open(.ayah(surah, ayah))
            switch link {
            case .tafsir: AppLinkSheets.shared.present(.tafsir(surah: surah, ayah: ayah))
            case .translations: AppLinkSheets.shared.present(.translations(surah: surah, ayah: ayah))
            default: AppLinkSheets.shared.present(.qiraah(surah: surah, ayah: ayah))
            }
            #else
            let _ = (surah, ayah)
            navigation.pendingTab = "islam"
            #endif
        case .explanation(let slug, let reference):
            #if HAS_HADITH
            guard let book = HadithCatalogBook.bySlug[slug] else {
                navigation.pendingTab = "hadith"
                return
            }
            if let data = HadithStore.shared.book(book), let hadith = AppLink.resolve(reference: reference, in: data) {
                // The narration in its book, its explanation over it.
                navigation.openHadith(slug: slug, idInBook: hadith.idInBook)
                AppLinkSheets.shared.present(.explanation(slug: slug, idInBook: hadith.idInBook))
            } else {
                navigation.pendingHadithBook = slug
            }
            #else
            let _ = (slug, reference)
            navigation.pendingTab = "islam"
            #endif
        case .encyclopedia(let id):
            #if HAS_HADITH
            navigation.pendingTab = "hadith"
            AppLinkSheets.shared.present(.encyclopedia(id))
            #else
            let _ = id
            navigation.pendingTab = "islam"
            #endif
        }
    }

    /// A link is opened from outside, over whatever the app was left on: a sheet still up (Settings,
    /// a share sheet, an ayah's card) would sit on top of the page the link just opened, and the
    /// tap would look like it did nothing. The fullscreen overlay is a layer, not a sheet, so it is
    /// closed by its own presenter.
    private static func closeWhatIsOpen() {
        #if os(iOS)
        FocusOverlayPresenter.shared.dismiss()
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        for window in scenes.flatMap(\.windows) where window.isKeyWindow {
            if let root = window.rootViewController, root.presentedViewController != nil {
                root.dismiss(animated: false)
            }
        }
        #endif
    }
}

// MARK: - Opening what a quote cites

extension AppLink {
    /// The row that opens a cited ayah or hadith from a quote, a source card or a citation: named by
    /// the tab it lands on.
    var openTitle: String {
        switch self {
        case .surah, .ayah, .tafsir, .translations, .qiraah: return OpenInTab.quranTitle
        case .hadith, .hadithBook, .explanation, .encyclopedia: return OpenInTab.hadithTitle
        default: return String(localized: "Open")
        }
    }

    /// The symbol of the tab it lands on (see `OpenInTab`).
    var openSystemImage: String {
        switch self {
        case .surah, .ayah, .tafsir, .translations, .qiraah: return OpenInTab.quranSymbol
        case .hadith, .hadithBook, .explanation, .encyclopedia: return OpenInTab.hadithSymbol
        default: return "arrow.up.forward.app"
        }
    }

    /// Whether this app has the tab the link lands on. Al-Quran ships no Hadith tab and Al-Adhan
    /// neither a Quran nor a Hadith tab (Abu, 2026-11-24: "Al Quran doesn't support Hadith and Al
    /// adhan doesn't support either ... if it doesn't exist it's similar to what it was before"), so
    /// a door, a linked citation or a quote's open arrow to a tab the app lacks is not drawn at all:
    /// the screen reads as it did before the doors were added. The router's own fallback (the
    /// Islam tab) stays for a link that arrives from outside.
    var opensInThisApp: Bool {
        switch self {
        case .surah, .ayah, .tafsir, .translations, .qiraah:
            #if HAS_QURAN
            return true
            #else
            return false
            #endif
        case .hadith, .hadithBook, .explanation, .encyclopedia:
            #if HAS_HADITH
            return true
            #else
            return false
            #endif
        default:
            return true
        }
    }
}

#if os(iOS)
/// "Open in Quran" / "Open in Hadith" as a button (see `OpenInTab`): the label in the accent at
/// caption weight, the look the Daily hub's and the reminders' doors already had, landing the way a
/// shared link does (`AppLinkRouter`: whatever is open closes, the tab switches, the reader opens
/// at the ayah or the book at the narration). `action` replaces the landing for a host that opens
/// the ayah in place (the Daily hub inside the Quran tab).
struct OpenInTabButton: View {
    @Environment(\.appearance) private var appearance

    let link: AppLink
    var action: (() -> Void)? = nil

    var body: some View {
        // Nothing where the app has no such tab (`opensInThisApp`), unless the host opens it itself.
        if action != nil || link.opensInThisApp {
            Button {
                Settings.shared.hapticFeedback()
                if let action { action() } else { AppLinkRouter.open(link) }
            } label: {
                Label(link.openTitle, systemImage: link.openSystemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(appearance.accent)
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}
#endif

/// The ayahs and hadiths an article's prose cites, found in its text so each opens what it cites
/// (Abu, 2026-11-24: "anywhere that mentions a Quran or Hadith would be nice for each Quran verse
/// or ayah to have an option to open it and then it opens it in the Quran or Hadith tab"). The
/// prose cites in one house style ("(Quran 2:185)", "(Sahih al-Bukhari 831)", "(Quran 2:43, 110)",
/// "(Sahih Muslim 379; Sunan Abi Dawud 499)"), so the forms are few and read here once per paragraph
/// and kept: the text of a page never changes. A book name resolves through the hadith search's own
/// reader (`HadithReferenceParser.book(named:)`), and only to a collection the app carries.
enum ScriptureCitations {
    struct Hit: Equatable {
        /// UTF-16 range in the text, the citation's words and numbers ("Quran 2:185").
        let range: NSRange
        let link: AppLink
    }

    private static let lock = NSLock()
    nonisolated(unsafe) private static var cache: [String: [Hit]] = [:]

    static func hits(in text: String) -> [Hit] {
        lock.lock()
        if let known = cache[text] { lock.unlock(); return known }
        lock.unlock()
        let found = scan(text)
        lock.lock(); cache[text] = found; lock.unlock()
        return found
    }

    /// "Quran 2:185", "Qur'an 2:185-186".
    private static let quranRegex = try? NSRegularExpression(
        pattern: #"\bQur['’]?an\s+(\d{1,3}):(\d{1,3})(?:\s*[-–]\s*\d{1,3})?"#)
    /// What may follow a Quran citation in the same breath: "; 3:18", ", 110", " and 5:3".
    private static let quranMoreRegex = try? NSRegularExpression(
        pattern: #"(?:\s*[,;]\s*(?:and\s+)?|\s+and\s+)(?:(\d{1,3}):(\d{1,3})|(\d{1,3})(?=\s*[),;]|\s+and\b|\s*$))(?:\s*[-–]\s*\d{1,3})?"#)
    /// A collection's name and a number: "Sahih al-Bukhari 831", "Jami` at-Tirmidhi 2516", "Sahih
    /// Muslim Introduction 9", "Muslim 8a". Longest names first; a bare "Ahmad" is left alone (it
    /// is also just a name).
    private static let hadithRegex = try? NSRegularExpression(
        pattern: #"\b(Sahih al-Bukhari|Sahih Bukhari|Sahih Muslim|Sunan Abi Dawud|Sunan Abu Dawud|Sunan (?:al|at)-Tirmidhi|Jami['`’ʿ]? ?(?:at|al)-Tirmidhi|Sunan Ibn Majah|Sunan (?:an|al)-Nasa['’]?i|Musnad Ahmad|Sunan al-Darimi|Muwatta Malik|Riyad as-Salihin|Bulugh al-Maram|al-Adab al-Mufrad|al-Bukhari|Bukhari|Muslim|Abu Dawud|Abi Dawud|(?:at|al)-Tirmidhi|Tirmidhi|Ibn Majah|(?:an|al)-Nasa['’]?i|Nasa['’]?i)(\s+Introduction)?\s+(\d{1,5})([a-z]{1,2})?\b"#)
    /// The same collection again: "Sahih al-Bukhari 1, 54" or "... 1 and 54".
    private static let hadithMoreRegex = try? NSRegularExpression(
        pattern: #"\s*(?:,|and|&)\s*(\d{1,5})([a-z]{1,2})?(?=\s*[),;]|\s+and\b|\s*$)"#)

    /// `hits(in:)` without the cache: the Islam search's citation index reads every passage of the
    /// corpus once (`IslamScriptureReference`), and keeping each as a cache key would only hold memory.
    static func uncachedHits(in text: String) -> [Hit] { scan(text) }

    private static func scan(_ text: String) -> [Hit] {
        guard text.contains(where: \.isNumber) else { return [] }
        let ns = text as NSString
        var hits: [Hit] = []

        func number(_ match: NSTextCheckingResult, _ group: Int) -> Int? {
            let range = match.range(at: group)
            guard range.location != NSNotFound else { return nil }
            return Int(ns.substring(with: range))
        }

        // An app without the Quran tab (Al-Adhan) leaves "(Quran 2:185)" as plain words, as the
        // hadith citations below stay words where there is no Hadith tab.
        #if HAS_QURAN
        if let quranRegex, text.range(of: "Qur", options: .caseInsensitive) != nil {
            for match in quranRegex.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
                guard let surah = number(match, 1), let ayah = number(match, 2),
                      let link = AppLink(key: "quran", value: "\(surah):\(ayah)") else { continue }
                hits.append(Hit(range: match.range, link: link))
                // The ayahs cited after it, of the same surah or another.
                var end = match.range.location + match.range.length
                while let quranMoreRegex,
                      let more = quranMoreRegex.firstMatch(in: text, options: .anchored,
                                                          range: NSRange(location: end, length: ns.length - end)) {
                    let nextSurah = number(more, 1) ?? surah
                    guard let nextAyah = number(more, 2) ?? number(more, 3),
                          let nextLink = AppLink(key: "quran", value: "\(nextSurah):\(nextAyah)") else { break }
                    // The numbers alone, not the comma before them.
                    let first = more.range(at: 1).location != NSNotFound ? more.range(at: 1) : more.range(at: 3)
                    let last = more.range.location + more.range.length
                    hits.append(Hit(range: NSRange(location: first.location, length: last - first.location), link: nextLink))
                    end = last
                }
            }
        }
        #endif

        #if HAS_HADITH
        if let hadithRegex {
            for match in hadithRegex.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
                let name = ns.substring(with: match.range(at: 1))
                let introduction = match.range(at: 2).location != NSNotFound
                guard let book = HadithReferenceParser.book(named: name), let cited = number(match, 3) else { continue }
                let suffix = match.range(at: 4).location != NSNotFound ? ns.substring(with: match.range(at: 4)).lowercased() : ""
                let reference = (introduction ? "intro-" : "") + "\(cited)\(suffix)"
                guard let link = AppLink(key: "hadith", value: "\(book.slug):\(reference)") else { continue }
                hits.append(Hit(range: match.range, link: link))
                var end = match.range.location + match.range.length
                while let hadithMoreRegex,
                      let more = hadithMoreRegex.firstMatch(in: text, options: .anchored,
                                                           range: NSRange(location: end, length: ns.length - end)),
                      let next = number(more, 1) {
                    let nextSuffix = more.range(at: 2).location != NSNotFound ? ns.substring(with: more.range(at: 2)).lowercased() : ""
                    guard let nextLink = AppLink(key: "hadith", value: "\(book.slug):\((introduction ? "intro-" : "") + "\(next)\(nextSuffix)")") else { break }
                    let first = more.range(at: 1)
                    let last = more.range.location + more.range.length
                    hits.append(Hit(range: NSRange(location: first.location, length: last - first.location), link: nextLink))
                    end = last
                }
            }
        }
        #endif

        return hits.sorted { $0.range.location < $1.range.location }
    }

    // MARK: A tafsir's references

    /// Each surah's ayah count (Hafs), the bound a tafsir's bare reference must fit inside.
    static let ayahCounts: [Int] = [
        7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128, 111, 110, 98, 135, 112, 78, 118, 64,
        77, 227, 93, 88, 69, 60, 34, 30, 73, 54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60,
        49, 62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12, 12, 30, 52, 52, 44, 28, 28, 20, 56, 40, 31, 50, 40, 46,
        42, 29, 19, 36, 25, 22, 17, 19, 26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3, 6, 3,
        5, 4, 5, 6,
    ]

    /// A reference that opens its bracket, "(41:39)", "[ 2:255]", "(see 2:43)", or follows the
    /// bracket that closes a quoted ayah, "(... the Most High) 13:9" (Ibn Kathir's other habit, 2,164
    /// times). One that follows a name is someone else's numbering ("(Genesis 1:3)", "(Al-Kubra
    /// 5:12)") and is left alone.
    private static let tafsirRegex = try? NSRegularExpression(
        pattern: #"(?:(?<=[\(\[])\s*(?:(?:see|refer to|cf\.?)\s+)?|(?<=\))\s{0,2})(\d{1,3}):(\d{1,3})\b(?:\s*[-–]\s*\d{1,3})?"#,
        options: .caseInsensitive)

    private static func ayahLink(_ surah: Int, _ ayah: Int) -> AppLink? {
        guard ayahCounts.indices.contains(surah - 1), (1...ayahCounts[surah - 1]).contains(ayah) else { return nil }
        return .ayah(surah: surah, ayah: ayah)
    }

    /// The ayahs a tafsir's prose refers to (Abu, 2026-11-24: "Would be nice to maybe add that for
    /// tafsirs and other places too?"). The editions cite an ayah by its bare numbers in brackets,
    /// 2,702 times in Ibn Kathir alone; a pair that is not a real surah and ayah (a hadith book's
    /// volume and page, "(1:554)") is no reference. Each hit's range is the numbers.
    static func tafsirHits(in text: String) -> [Hit] {
        guard let tafsirRegex, text.contains(":") else { return [] }
        let ns = text as NSString
        var hits: [Hit] = []
        func number(_ match: NSTextCheckingResult, _ group: Int) -> Int? {
            let range = match.range(at: group)
            guard range.location != NSNotFound else { return nil }
            return Int(ns.substring(with: range))
        }
        for match in tafsirRegex.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
            guard let surah = number(match, 1), let ayah = number(match, 2), let link = ayahLink(surah, ayah) else { continue }
            let start = match.range(at: 1).location
            var end = match.range.location + match.range.length
            hits.append(Hit(range: NSRange(location: start, length: end - start), link: link))
            while let quranMoreRegex,
                  let more = quranMoreRegex.firstMatch(in: text, options: .anchored,
                                                      range: NSRange(location: end, length: ns.length - end)) {
                let nextSurah = number(more, 1) ?? surah
                guard let nextAyah = number(more, 2) ?? number(more, 3), let nextLink = ayahLink(nextSurah, nextAyah) else { break }
                let first = more.range(at: 1).location != NSNotFound ? more.range(at: 1) : more.range(at: 3)
                let last = more.range.location + more.range.length
                hits.append(Hit(range: NSRange(location: first.location, length: last - first.location), link: nextLink))
                end = last
            }
        }
        return hits
    }

    /// The first citation in a quote's citation line ("Quran 2:255", "Sahih al-Bukhari 1").
    static func firstLink(in citation: String) -> AppLink? {
        hits(in: citation).first?.link
    }

    #if os(iOS)
    /// `attributed` with every citation made a link in the accent, or nil when it cites nothing.
    static func linked(_ attributed: AttributedString, accent: Color) -> AttributedString? {
        let plain = String(attributed.characters)
        let found = hits(in: plain)
        guard !found.isEmpty else { return nil }
        var out = attributed
        for hit in found {
            guard let range = Range(hit.range, in: plain), let url = hit.link.schemeURL else { continue }
            let lower = plain.distance(from: plain.startIndex, to: range.lowerBound)
            let upper = plain.distance(from: plain.startIndex, to: range.upperBound)
            let start = out.characters.index(out.startIndex, offsetBy: lower)
            let end = out.characters.index(out.startIndex, offsetBy: upper)
            out[start..<end].link = url
            out[start..<end].foregroundColor = accent
        }
        return out
    }

    /// A tap on a citation: what it cites, opened in its tab.
    @MainActor
    static func open(_ url: URL) {
        Settings.shared.hapticFeedback()
        if !AppLinkRouter.open(url) { UIApplication.shared.open(url) }
    }

    /// A long press on a citation: open it, share its link, or copy it.
    @MainActor
    static func menu(for url: URL) -> UIMenu? {
        guard let link = AppLink(url: url) else { return nil }
        return UIMenu(children: [
            UIAction(title: link.openTitle, image: UIImage(systemName: link.openSystemImage)) { _ in
                Settings.shared.hapticFeedback()
                AppLinkRouter.open(link)
            },
            UIAction(title: String(localized: "Share Link"), image: UIImage(systemName: "square.and.arrow.up")) { _ in
                AppLinkShare.share(link, title: link.citationTitle)
            },
            UIAction(title: String(localized: "Copy Link"), image: UIImage(systemName: "doc.on.doc")) { _ in
                AppLinkShare.copy(link)
            },
        ])
    }
    #endif
}

extension AppLink {
    /// A cited ayah or hadith named the way the articles cite it ("Quran 2:255", "Sahih al-Bukhari
    /// 1"), for a share sheet's title.
    var citationTitle: String {
        switch self {
        case .ayah(let surah, let ayah): return "Quran \(surah):\(ayah)"
        case .surah(let surah): return "Quran \(surah)"
        case .hadith(let slug, let reference):
            #if HAS_HADITH
            if let book = HadithCatalogBook.bySlug[slug] {
                return "\(book.englishTitle) \(reference.hasPrefix("intro-") ? "Introduction " + reference.dropFirst(6) : Substring(reference))"
            }
            #endif
            return "\(slug) \(reference)"
        default: return AppIdentifiers.displayName
        }
    }
}

// MARK: - Sheets a link opens

/// A screen that is a SHEET in the app (an ayah's tafsir and comparisons, a hadith's explanation): a
/// link to one lands on its tab and the sheet comes up over it, presented by the root
/// (`MainTabView`), which is on screen whatever tab the link lands on.
enum AppLinkSheet: Identifiable, Equatable {
    case tafsir(surah: Int, ayah: Int)
    case translations(surah: Int, ayah: Int)
    case qiraah(surah: Int, ayah: Int)
    case explanation(slug: String, idInBook: Int)
    case encyclopedia(String)

    var id: String {
        switch self {
        case .tafsir(let surah, let ayah): return "tafsir-\(surah):\(ayah)"
        case .translations(let surah, let ayah): return "translations-\(surah):\(ayah)"
        case .qiraah(let surah, let ayah): return "qiraah-\(surah):\(ayah)"
        case .explanation(let slug, let idInBook): return "explanation-\(slug):\(idInBook)"
        case .encyclopedia(let id): return "encyclopedia-\(id)"
        }
    }
}

/// Where the router leaves a sheet for the root to present.
@MainActor
final class AppLinkSheets: ObservableObject {
    static let shared = AppLinkSheets()
    private init() {}

    @Published var pending: AppLinkSheet?
    /// A second link opened before the first one's sheet came up wins.
    private var generation = 0

    /// Presents `sheet` once the app can show it: after the launch cover lifts (a cold launch from
    /// the link), once what the sheet reads has loaded (so it opens on its text, never on a
    /// spinner), and a beat after the tab switch and the push under it, which a sheet presented in
    /// the same moment would interrupt.
    func present(_ sheet: AppLinkSheet) {
        generation += 1
        let mine = generation
        Task { @MainActor in
            await AppReveal.waitUntilRevealed()
            switch sheet {
            case .tafsir, .translations, .qiraah:
                #if HAS_QURAN
                await QuranQuoteSource.waitUntilReady()
                #else
                break
                #endif
            case .explanation, .encyclopedia:
                #if HAS_HADITH
                _ = await Task.detached(priority: .userInitiated) { HadeethEncStore.shared.library() }.value
                #else
                break
                #endif
            }
            try? await Task.sleep(nanoseconds: 700_000_000)
            guard mine == generation else { return }
            pending = sheet
        }
    }
}

#if os(iOS)
/// The sheet a link opened (`AppLinkSheet`), as the screen that owns it presents it.
struct AppLinkSheetView: View {
    let sheet: AppLinkSheet

    var body: some View {
        switch sheet {
        #if HAS_QURAN
        case .tafsir(let surah, let ayah):
            ayahSheet(.tafsir, surah: surah, ayah: ayah)
        case .translations(let surah, let ayah):
            ayahSheet(.translations, surah: surah, ayah: ayah)
        case .qiraah(let surah, let ayah):
            ayahSheet(.qiraah, surah: surah, ayah: ayah)
        #else
        case .tafsir, .translations, .qiraah:
            EmptyView()
        #endif
        case .explanation(let slug, let idInBook):
            #if HAS_HADITH
            HadithExplanationSheet(slug: slug, idInBook: idInBook)
            #else
            let _ = (slug, idInBook)
            EmptyView()
            #endif
        case .encyclopedia(let id):
            #if HAS_HADITH
            HadithExplanationSheet(entryID: id)
            #else
            let _ = id
            EmptyView()
            #endif
        }
    }

    #if HAS_QURAN
    @ViewBuilder
    private func ayahSheet(_ kind: AyahSecondarySheet, surah surahID: Int, ayah ayahID: Int) -> some View {
        // An ayah past the surah's end (a hand-typed link) opens on its last one.
        if let surah = QuranData.shared.surah(surahID),
           let ayah = surah.ayahs.first(where: { $0.id == ayahID }) ?? surah.ayahs.last {
            AyahSecondarySheetContent(kind: kind, surah: surah, ayah: ayah, onDismiss: {})
                .smallMediumSheetPresentation()
        }
    }
    #endif
}
#endif

// MARK: - Sharing a link

#if os(iOS)
/// A link as the system share sheet sends it: the URL itself (so AirDrop opens it and Messages draws
/// its preview), with a title the sheet's header and a mail subject can show instead of the address.
final class AppLinkShareItem: NSObject, UIActivityItemSource {
    let url: URL
    let title: String

    init(link: AppLink, title: String) {
        url = link.url
        self.title = title
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any { url }

    func activityViewController(_ activityViewController: UIActivityViewController,
                                itemForActivityType activityType: UIActivity.ActivityType?) -> Any? { url }

    func activityViewController(_ activityViewController: UIActivityViewController,
                                subjectForActivityType activityType: UIActivity.ActivityType?) -> String { title }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.originalURL = url
        metadata.url = url
        metadata.title = "\(title) · \(AppIdentifiers.appName)"
        return metadata
    }
}

@MainActor
enum AppLinkShare {
    /// The system share sheet for a link, from anywhere (a menu row, a toolbar button, a tile).
    static func share(_ link: AppLink, title: String) {
        Settings.shared.hapticFeedback()
        presentSystemShareSheet(items: [AppLinkShareItem(link: link, title: title)])
    }

    /// The link on the pasteboard as text, which pastes into anything and is linked wherever it lands.
    static func copy(_ link: AppLink) {
        Settings.shared.hapticFeedback()
        UIPasteboard.general.string = link.url.absoluteString
    }
}

// MARK: - The share button beside a search bar

/// What a page's share button offers: the page's link (it opens the page in the app, and the App
/// Store where the app is not installed) and, on a page whose words are worth sending as they are
/// (a tafsir, a comparison), the page as text, built on the tap.
struct PageShare {
    var link: AppLink?
    /// The share sheet's title for the link.
    var title: String
    var text: (() -> String?)? = nil
    /// The text row's name ("Share Tafsir").
    var textLabel: String = String(localized: "Share as Text")
    /// A row that copies the text ("Copy Article"), for a page whose ⋯ menu the circle replaced.
    var copyLabel: String? = nil
}

/// A page's share button as a glass circle the search field's height, beside the field (Abu,
/// 2026-11-24: "top right is always ai and to the right of search bar (similar to quran filtering)
/// is share"): the Quran tab's play button and the narrations' filter button sit beside their bars
/// the same way. A page with only a link shares it on the tap; one with text too opens a menu.
struct ShareCircleButton: View {
    let share: PageShare

    var body: some View {
        if share.text == nil, let link = share.link {
            Button {
                AppLinkShare.share(link, title: share.title)
            } label: {
                label
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Share Link")
            .accessibilityHint("Shares a link that opens this page")
        } else {
            Menu {
                if let link = share.link {
                    Button {
                        AppLinkShare.share(link, title: share.title)
                    } label: {
                        Label("Share Link", systemImage: "link")
                    }
                }
                if let text = share.text {
                    Button {
                        guard let shared = text() else { return }
                        Settings.shared.hapticFeedback()
                        presentSystemShareSheet(items: [shared])
                    } label: {
                        Label(share.textLabel, systemImage: "text.quote")
                    }
                    if let copyLabel = share.copyLabel {
                        Button {
                            guard let copied = text() else { return }
                            Settings.shared.hapticFeedback()
                            UIPasteboard.general.string = copied
                            CopyConfirmation.shared.show()
                        } label: {
                            Label(copyLabel, systemImage: "doc.on.clipboard")
                        }
                    }
                }
                if let link = share.link {
                    Button {
                        AppLinkShare.copy(link)
                    } label: {
                        Label("Copy Link", systemImage: "doc.on.doc")
                    }
                }
            } label: {
                label
            }
            // Opening upward from the foot, a menu lists its rows reversed without this.
            .fixedMenuOrder()
            .accessibilityLabel("Share")
        }
    }

    private var label: some View {
        Image(systemName: "square.and.arrow.up")
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(Settings.shared.accentColor.color)
            // Nudged up a point: the glyph's arrow makes it sit low in a circle.
            .offset(y: -1.5)
            .frame(width: 50, height: 50)
            .contentShape(Rectangle())
            .conditionalGlassEffect()
    }
}

/// The app's search bar with the page's share button beside it. The button steps aside while the
/// field is being typed in, as the Quran tab's play button does, so the field and its ✕ have the
/// width.
struct SearchBarWithShare: View {
    @Binding var text: String
    var placeholder: String = String(localized: "Search")
    /// Nil draws the bare search bar.
    let share: PageShare?

    @State private var editing = false

    var body: some View {
        HStack(spacing: 8) {
            SearchBar(text: $text, placeholder: placeholder, onFocusChanged: { focused in
                withAnimation(.easeInOut(duration: 0.2)) { editing = focused }
            })

            if let share, !editing {
                ShareCircleButton(share: share)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
    }
}
#endif
