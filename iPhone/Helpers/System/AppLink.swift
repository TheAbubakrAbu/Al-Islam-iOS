import Foundation
#if os(iOS)
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
    /// a catalog id ("ShahadahView") or a generated page's ("Sunnah-waking-praise"). Nil for a page
    /// with no place of its own to open (a tajweed topic, a qiraat biography).
    @MainActor
    static func articlePage(id: String) -> (link: AppLink, title: String)? {
        if let entry = IslamArticleCatalog.byID[id] {
            return (.article(entry.linkKey), entry.title)
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
#endif
