import XCTest
@testable import iPhone

/// Shared links (`AppLink`, iPhone/Helpers/System/AppLink.swift): the grammar round-trips, anything
/// outside it is refused, every hadith's link leads back to that hadith, every article has a key of
/// its own, and the website's association file and the entitlement name the host the app builds
/// links on.
@MainActor
final class AppLinkTests: XCTestCase {

    private static let samples: [AppLink] = [
        .tab("settings"), .tab("qibla"),
        .surah(1), .surah(114), .ayah(surah: 2, ayah: 255), .ayah(surah: 114, ayah: 6),
        .hadithBook(slug: "bukhari"), .hadithBook(slug: "aladab_almufrad"),
        .hadith(slug: "bukhari", reference: "1"), .hadith(slug: "muslim", reference: "8a"),
        .hadith(slug: "muslim", reference: "1211aa"), .hadith(slug: "muslim", reference: "intro-9"),
        .hadith(slug: "bulugh_almaram", reference: "3:12"), .hadith(slug: "tirmidhi", reference: "id-3033"),
        .article("pillars.shahadah"), .article("guides.evil-eye"),
        .sunnah("waking-praise"), .prophecy("byzantines"), .prophetMiracle("nuh-ark"), .miracle("big_bang_crunch"),
        .name(1), .name(99),
        .resource("zakahCalculator"),
    ]

    // MARK: The grammar

    func testEveryLinkRoundTripsThroughTheSharedAddress() throws {
        for link in Self.samples {
            let url = link.url
            XCTAssertEqual(url.scheme, "https", url.absoluteString)
            XCTAssertEqual(url.host, AppIdentifiers.linkHost, url.absoluteString)
            XCTAssertEqual(AppLink(url: url), link, url.absoluteString)
        }
    }

    func testEveryLinkRoundTripsThroughTheAppScheme() throws {
        for link in Self.samples {
            let url = try XCTUnwrap(link.schemeURL)
            XCTAssertEqual(url.scheme, AppIdentifiers.linkScheme)
            XCTAssertEqual(AppLink(url: url), link, url.absoluteString)
        }
    }

    /// The address is what a person reads in a chat: the pair stays legible, nothing percent-encoded.
    func testTheSharedAddressReadsPlainly() {
        let base = "https://\(AppIdentifiers.linkHost)\(AppIdentifiers.linkPath)"
        XCTAssertEqual(AppLink.ayah(surah: 2, ayah: 255).url.absoluteString, base + "?quran=2:255")
        XCTAssertEqual(AppLink.hadith(slug: "muslim", reference: "8a").url.absoluteString, base + "?hadith=muslim:8a")
        XCTAssertEqual(AppLink.article("pillars.shahadah").url.absoluteString, base + "?article=pillars.shahadah")
    }

    /// The ayah widgets' older form is the same grammar, read as a path.
    func testTheWidgetFormStillOpensItsAyah() {
        XCTAssertEqual(AppLink(url: URL(string: "alislam://ayah/2/255")!), .ayah(surah: 2, ayah: 255))
        XCTAssertEqual(AppLink(url: URL(string: "ALISLAM://AYAH/36/9")!), .ayah(surah: 36, ayah: 9))
        for (surah, ayah) in [(1, 1), (2, 255), (114, 6)] {
            let url = QuranDeepLink.ayah(surah: surah, ayah: ayah)!
            XCTAssertEqual(AppLink(url: url), .ayah(surah: surah, ayah: ayah))
        }
    }

    func testPathAndFragmentFormsReadTheSame() {
        let base = "https://\(AppIdentifiers.linkHost)\(AppIdentifiers.linkPath)"
        let cases: [(String, AppLink)] = [
            (base + "quran/2/255", .ayah(surah: 2, ayah: 255)),
            (base + "quran/2", .surah(2)),
            (base + "hadith/muslim/8a", .hadith(slug: "muslim", reference: "8a")),
            (base + "hadith/nasai/3:12", .hadith(slug: "nasai", reference: "3:12")),
            (base + "hadith/bukhari", .hadithBook(slug: "bukhari")),
            (base + "article/pillars.shahadah", .article("pillars.shahadah")),
            (base + "#quran/2/255", .ayah(surah: 2, ayah: 255)),
            (base + "index.html?name=5", .name(5)),
            ("alislam://quran/2/255", .ayah(surah: 2, ayah: 255)),
            ("alislam://hadith/muslim/8a", .hadith(slug: "muslim", reference: "8a")),
        ]
        for (text, expected) in cases {
            XCTAssertEqual(AppLink(url: URL(string: text)!), expected, text)
        }
    }

    /// A messenger or a tracker adds its own items; the link is the one the grammar knows.
    func testOtherQueryItemsAreSkipped() {
        let base = "https://\(AppIdentifiers.linkHost)\(AppIdentifiers.linkPath)"
        XCTAssertEqual(AppLink(url: URL(string: base + "?utm_source=chat&quran=2:255&fbclid=abc")!), .ayah(surah: 2, ayah: 255))
        XCTAssertEqual(AppLink(url: URL(string: "HTTPS://\(AppIdentifiers.linkHost.uppercased())/ALISLAM/?quran=2:255")!),
                       .ayah(surah: 2, ayah: 255))
    }

    func testAnythingOutsideTheGrammarIsRefused() {
        let base = "https://\(AppIdentifiers.linkHost)\(AppIdentifiers.linkPath)"
        let refused = [
            base, base + "?", base + "?quran=", base + "?quran=0", base + "?quran=115", base + "?quran=2:0",
            base + "?quran=2:287", base + "?quran=2:255:1", base + "?quran=two", base + "?quran=00000000000002",
            base + "?name=0", base + "?name=100", base + "?name=five",
            base + "?hadith=bukhari:", base + "?hadith=bukhari:abc", base + "?hadith=bu%20khari:1",
            base + "?hadith=bukhari:1%3Cscript%3E", base + "?article=..%2F..%2Fetc", base + "?article=a%20b",
            // Arabic-Indic digits, percent-encoded as a browser would send them: a link is Western digits.
            base + "?hadith=bukhari:%D9%A1%D9%A5", base + "?quran=%D9%A2:%D9%A2%D9%A5%D9%A5", base + "?name=%D9%A5",
            base + "?tab=admin", base + "?unknown=1", base + "?islam=" + String(repeating: "a", count: 200),
            "https://example.com/alislam/?quran=2:255",
            "https://\(AppIdentifiers.linkHost)/other/?quran=2:255",
            "https://\(AppIdentifiers.linkHost)/?quran=2:255",
            "alislam://open", "alislam://", "alislam://ayah/2", "alislam://ayah/two/255",
            "ftp://\(AppIdentifiers.linkHost)\(AppIdentifiers.linkPath)?quran=2:255",
            "othersapp://open?quran=2:255",
        ]
        for text in refused {
            guard let url = URL(string: text) else { continue }
            XCTAssertNil(AppLink(url: url), text)
        }
    }

    // MARK: Hadith

    /// Every narration in every book: the link made for it leads back to the same row. The value is
    /// the number printed beside the hadith wherever that number is its own, so the `id-` form stays
    /// the exception it is meant to be.
    func testEveryHadithLinkLeadsBackToItsHadith() throws {
        var total = 0
        var byRow = 0
        for book in HadithCatalogBook.all {
            let data = try XCTUnwrap(HadithStore.shared.book(book), book.slug)
            for hadith in data.hadiths {
                let link = AppLink.hadith(hadith, in: book, data: data)
                guard case .hadith(let slug, let reference) = link else { return XCTFail("not a hadith link") }
                total += 1
                if reference.hasPrefix("id-") { byRow += 1 }
                XCTAssertEqual(slug, book.slug)
                XCTAssertEqual(AppLink(url: link.url), link, "\(book.slug) \(reference)")
                let resolved = AppLink.resolve(reference: reference, in: data)
                if resolved?.idInBook != hadith.idInBook {
                    XCTFail("\(book.slug) \(reference) opens row \(resolved.map { String($0.idInBook) } ?? "nothing"), not \(hadith.idInBook)")
                    return
                }
            }
        }
        print("APPLINK hadith links: \(total), carrying the row number: \(byRow)")
        XCTAssertGreaterThan(total, 30_000)
        // Two rows under one citation exist, but they are rare: most links carry the printed number.
        XCTAssertLessThan(Double(byRow), Double(total) * 0.01, "\(byRow) of \(total) links fell back to the row number")
    }

    func testAHadithReferenceReadsAsTheSearchReadsIt() throws {
        let muslim = try XCTUnwrap(HadithCatalogBook.bySlug["muslim"])
        let data = try XCTUnwrap(HadithStore.shared.book(muslim))
        XCTAssertEqual(AppLink.resolve(reference: "8a", in: data)?.citation, "8a")
        XCTAssertEqual(AppLink.resolve(reference: "intro-9", in: data)?.isIntroduction, true)
        XCTAssertNil(AppLink.resolve(reference: "99999", in: data))
        XCTAssertNil(AppLink.resolve(reference: "id-999999", in: data))
    }

    // MARK: Articles and libraries

    func testEveryArticleHasALinkKeyOfItsOwn() {
        var seen: [String: String] = [:]
        for entry in IslamArticleCatalog.all {
            let key = entry.linkKey
            XCTAssertNil(seen[key.lowercased()], "\(entry.id) and \(seen[key.lowercased()] ?? "") share \(key)")
            seen[key.lowercased()] = entry.id
            XCTAssertEqual(AppLink(key: "article", value: key), .article(key), key)
            XCTAssertEqual(IslamArticleCatalog.entry(linkKey: key)?.id, entry.id, key)
            XCTAssertEqual(AppLink.articlePage(id: entry.id)?.link, .article(key), entry.id)
        }
        XCTAssertEqual(IslamArticleCatalog.entry(linkKey: "PILLARS.SHAHADAH")?.id, "ShahadahView")
        XCTAssertEqual(IslamArticleCatalog.entry(linkKey: "ShahadahView")?.id, "ShahadahView")
        XCTAssertNil(IslamArticleCatalog.entry(linkKey: "pillars.no-such-page"))
    }

    /// A library page's id goes into its link as written, so it has to be inside the link alphabet.
    func testEveryLibraryPageHasALink() {
        for entry in SunnahView.entries {
            XCTAssertEqual(AppLink(key: "sunnah", value: entry.id), .sunnah(entry.id), entry.id)
            XCTAssertEqual(AppLink.articlePage(id: "Sunnah-\(entry.id)")?.link, .sunnah(entry.id))
        }
        for entry in PropheciesView.entries {
            XCTAssertEqual(AppLink(key: "prophecy", value: entry.id), .prophecy(entry.id), entry.id)
            XCTAssertEqual(AppLink.articlePage(id: "Prophecy-\(entry.id)")?.link, .prophecy(entry.id))
        }
        for entry in ProphetMiraclesView.entries {
            XCTAssertEqual(AppLink(key: "sign", value: entry.id), .prophetMiracle(entry.id), entry.id)
            XCTAssertEqual(AppLink.articlePage(id: "ProphetMiracle-\(entry.id)")?.link, .prophetMiracle(entry.id))
        }
        let miracles = MiraclesStore.shared.library()?.articles ?? []
        XCTAssertFalse(miracles.isEmpty)
        for article in miracles {
            XCTAssertEqual(AppLink(key: "miracle", value: article.slug), .miracle(article.slug), article.slug)
        }
        XCTAssertNil(AppLink.articlePage(id: "NoSuchView"))
    }

    // MARK: The host, in the three places that must agree

    private static let repository = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()

    /// The association file's entries: one per app, each its app ids and the paths it owns.
    private static func associationEntries() throws -> [(appIDs: [String], paths: [String])] {
        let file = repository.appendingPathComponent("Website/public/.well-known/apple-app-site-association")
        guard let data = try? Data(contentsOf: file) else { throw XCTSkip("the repository is not readable from here") }
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let details = try XCTUnwrap((root["applinks"] as? [String: Any])?["details"] as? [[String: Any]])
        return details.map {
            ($0["appIDs"] as? [String] ?? [], ($0["components"] as? [[String: Any]] ?? []).compactMap { $0["/"] as? String })
        }
    }

    /// The website's association file names this app and covers the path the app builds links on.
    func testTheAssociationFileCoversTheSharedAddress() throws {
        let entries = try Self.associationEntries()
        let mine = try XCTUnwrap(entries.first { $0.appIDs.contains { $0.hasSuffix("." + AppIdentifiers.bundleIdentifier) } })
        let prefix = AppIdentifiers.linkPath.hasSuffix("/") ? String(AppIdentifiers.linkPath.dropLast()) : AppIdentifiers.linkPath
        XCTAssertTrue(mine.paths.contains(prefix), "\(mine.paths)")
        XCTAssertTrue(mine.paths.contains(prefix + "/*"), "\(mine.paths)")
    }

    /// The scheme and the site folder are derived from the app's name (Globals.swift) so that the
    /// companion apps get their own. Here they are pinned: a build that drifted would strand every
    /// link already shared, and Info-Main.plist has to register the same word.
    func testTheLinkIdentityIsThisAppsOwn() throws {
        XCTAssertEqual(AppIdentifiers.linkScheme, "alislam")
        XCTAssertEqual(AppIdentifiers.linkPath, "/alislam/")
        XCTAssertEqual(QuranDeepLink.scheme, AppIdentifiers.linkScheme)
        let file = Self.repository.appendingPathComponent("Resources/Info-Main.plist")
        guard let data = try? Data(contentsOf: file) else { throw XCTSkip("the repository is not readable from here") }
        let plist = try XCTUnwrap(PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])
        let schemes = (plist["CFBundleURLTypes"] as? [[String: Any]] ?? []).flatMap { $0["CFBundleURLSchemes"] as? [String] ?? [] }
        XCTAssertEqual(schemes, [AppIdentifiers.linkScheme])
    }

    /// One site serves the three apps. Each has a folder of its own, named by the word its build
    /// derives as `linkScheme`, and no app's paths reach into another's: an overlap would open a
    /// link in whichever of the two apps the phone happens to have.
    func testEachAppOwnsItsFolderOfTheSite() throws {
        let folders = ["Islamic-Pillars": "alislam", "Beginner-Quran": "alquran", "Prayer-Times": "aladhan"]
        let entries = try Self.associationEntries()
        XCTAssertEqual(entries.count, folders.count)
        for (suffix, folder) in folders {
            let entry = try XCTUnwrap(entries.first { $0.appIDs.contains { $0.hasSuffix(".com.Quran.Elmallah." + suffix) } }, suffix)
            XCTAssertEqual(entry.appIDs.count, 1, "\(entry.appIDs)")
            XCTAssertEqual(entry.paths, ["/\(folder)", "/\(folder)/*"])
            let page = Self.repository.appendingPathComponent("Website/public/\(folder)/index.html")
            let html = try XCTUnwrap(try? String(contentsOf: page, encoding: .utf8), folder)
            XCTAssertTrue(html.contains("data-scheme=\"\(folder)\""), folder)
            XCTAssertTrue(html.contains("https://\(AppIdentifiers.linkHost)/\(folder)/icon.jpg"), folder)
            // The page sends a visitor without the app to THAT app's store page.
            let store = try XCTUnwrap(AppIdentifiers.appStoreIDs["com.Quran.Elmallah." + suffix], suffix)
            XCTAssertTrue(html.contains("data-store=\"\(store)\""), folder)
            XCTAssertTrue(html.contains("content=\"app-id=\(store)"), folder)
        }
    }

    /// Each app opens its OWN store page for "Leave a Review", "Share" and the update dialog. The
    /// number is picked by bundle id from the three (Globals.swift), and no review link writes a
    /// number out: one written-out number in a file the companion apps receive is how Al-Quran and
    /// Al-Adhan came to send their reviews to Al-Islam.
    func testTheStoreNumberIsThisAppsOwn() throws {
        XCTAssertEqual(AppIdentifiers.appStoreID, "6449729655")
        XCTAssertEqual(AppIdentifiers.appStoreIDs[AppIdentifiers.bundleIdentifier], AppIdentifiers.appStoreID)
        XCTAssertEqual(Set(AppIdentifiers.appStoreIDs.values).count, 3)
        XCTAssertEqual(AppIdentifiers.appStoreURL.absoluteString, "https://apps.apple.com/app/id6449729655")

        let sources = Self.repository.appendingPathComponent("iPhone")
        guard let files = FileManager.default.enumerator(at: sources, includingPropertiesForKeys: nil) else {
            throw XCTSkip("the repository is not readable from here")
        }
        var read = 0
        for case let file as URL in files where file.pathExtension == "swift" {
            guard let text = try? String(contentsOf: file, encoding: .utf8) else { continue }
            read += 1
            XCTAssertNil(text.range(of: #"/app/id\d+\?action=write-review"#, options: .regularExpression),
                         "\(file.lastPathComponent) writes a store number into a review link: use AppIdentifiers.appStoreID")
        }
        if read == 0 { throw XCTSkip("the repository is not readable from here") }
    }

    func testTheEntitlementsNameTheSharedHost() throws {
        for name in ["Entitlements-Main.entitlements", "Entitlements-Main-CarPlay.entitlements"] {
            let file = Self.repository.appendingPathComponent("Resources/\(name)")
            guard let data = try? Data(contentsOf: file) else { throw XCTSkip("the repository is not readable from here") }
            let plist = try XCTUnwrap(PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])
            let domains = plist["com.apple.developer.associated-domains"] as? [String] ?? []
            XCTAssertTrue(domains.contains("applinks:\(AppIdentifiers.linkHost)"), "\(name): \(domains)")
        }
    }
}
