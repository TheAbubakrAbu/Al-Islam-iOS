import XCTest
@testable import iPhone

/// The narrators and the groups of equal chains (HadithNarrators.swift): the shipped pack reads back
/// exactly what Scripts/build_hadith_chains.py counted (its generated `HadithNarratorSamples`), the
/// chain codes name narrators the pack holds, and every narration a profile lists is on the shelf.
final class HadithNarratorsTests: XCTestCase {
    private func book(_ slug: String) throws -> HadithBookData {
        let url = try XCTUnwrap(HadithPack.bundledURL(slug), slug)
        return HadithBookData(pack: try XCTUnwrap(HadithPack(slug: slug, url: url), slug))
    }

    private func pack() throws -> HadithNarratorsPack {
        let url = try XCTUnwrap(HadithNarratorsPack.bundledURL(), "HadithNarrators.qpk is not bundled")
        return try XCTUnwrap(HadithNarratorsPack(url: url), "HadithNarrators.qpk does not open")
    }

    func testThePackOpensAsTheScriptWroteIt() throws {
        let pack = try pack()
        XCTAssertEqual(pack.slugs, HadithNarratorSamples.books)
        XCTAssertEqual(pack.narratorCount, HadithNarratorSamples.narratorCount)
        XCTAssertEqual(pack.groupCount, HadithNarratorSamples.groupCount)
        XCTAssertGreaterThan(pack.narratorCount, 5_000)
        XCTAssertGreaterThan(pack.groupCount, 1_000)
        XCTAssertNil(pack.profile(id: 0))
        XCTAssertNil(pack.profile(id: pack.narratorCount + 1))
        XCTAssertTrue(pack.refs(id: 0).isEmpty)
        XCTAssertTrue(pack.members(group: 0).isEmpty)
        XCTAssertTrue(pack.members(group: pack.groupCount + 1).isEmpty)
    }

    /// Every sample narrator's profile and list are what the script counted, and the counts agree
    /// with the list: by grade and by book they add up to the narrations, the list is in the shelf's
    /// order, and every narration listed exists.
    func testTheSampleNarratorsReadBack() throws {
        let pack = try pack()
        var books: [String: HadithBookData] = [:]
        for sample in HadithNarratorSamples.narrators {
            let profile = try XCTUnwrap(pack.profile(id: sample.id), "narrator \(sample.id)")
            XCTAssertEqual(profile.name, sample.name)
            XCTAssertEqual(profile.english, sample.english)
            XCTAssertEqual(profile.generation, sample.depth)
            XCTAssertEqual(profile.forms.map { "\($0.name)=\($0.count)" }, sample.forms.map { "\($0.name)=\($0.count)" }, sample.name)
            XCTAssertFalse(profile.english.isEmpty, sample.name)
            XCTAssertEqual(profile.narrations, sample.narrations)
            XCTAssertEqual(profile.fromProphet, sample.fromProphet)
            XCTAssertEqual(profile.teacher, sample.teacher)
            XCTAssertEqual(profile.grades, sample.grades)
            XCTAssertEqual(profile.grades.reduce(0, +), sample.narrations, sample.name)
            let byBook = Dictionary(uniqueKeysWithValues: profile.books.map { ($0.slug, $0.count) })
            XCTAssertEqual(byBook, Dictionary(uniqueKeysWithValues: zip(HadithNarratorSamples.books, sample.books).filter { $0.1 > 0 }), sample.name)
            XCTAssertEqual(profile.books.map(\.count).reduce(0, +), sample.narrations, sample.name)

            let refs = pack.refs(id: sample.id)
            XCTAssertEqual(refs.count, sample.narrations, sample.name)
            XCTAssertEqual(refs.prefix(5).map { "\($0.slug):\($0.idInBook):\($0.role.rawValue):\($0.grade.rawValue)" },
                           sample.firstRefs.map { "\($0.slug):\($0.idInBook):\($0.role):\($0.grade)" }, sample.name)
            let order = refs.map { (HadithNarratorSamples.books.firstIndex(of: $0.slug) ?? 99, $0.idInBook) }
            XCTAssertEqual(order.map { "\($0.0):\($0.1)" }, order.sorted { $0 < $1 }.map { "\($0.0):\($0.1)" }, sample.name)
            XCTAssertEqual(refs.filter { $0.role == .teacher }.count, sample.teacher, sample.name)
            // The top of a chain that names the Prophet ﷺ, and the top of one that does not: two
            // places, and the profile counts each.
            XCTAssertEqual(refs.filter { $0.role == .top }.count, sample.fromProphet, sample.name)
            XCTAssertEqual(refs.filter { $0.role == .end }.count, sample.ends, sample.name)
            XCTAssertEqual(profile.ends, sample.ends, sample.name)
            for ref in refs {
                let data = try books[ref.slug] ?? book(ref.slug)
                books[ref.slug] = data
                XCTAssertNotNil(data.hadith(numbered: ref.idInBook), "\(sample.name): \(ref.slug) \(ref.idInBook) is not on the shelf")
                // A narration listed under a narrator carries a chain that names him.
                let code = HadithChainStore.shared.pack?.code(slug: ref.slug, idInBook: ref.idInBook)
                XCTAssertTrue(code?.contains("@\(sample.id)") == true, "\(sample.name): \(ref.slug) \(ref.idInBook) does not name him")
            }
        }
    }

    /// The sample groups read back, every member's chain code carries the group, and the chains are
    /// drawn from the same narrators.
    func testTheSampleGroupsReadBack() throws {
        let pack = try pack()
        let chains = try XCTUnwrap(HadithChainStore.shared.pack)
        var books: [String: HadithBookData] = [:]
        for sample in HadithNarratorSamples.groups {
            let members = pack.members(group: sample.id)
            XCTAssertEqual(members.map { "\($0.slug):\($0.idInBook)" }, sample.members.map { "\($0.slug):\($0.idInBook)" }, "group \(sample.id)")
            XCTAssertGreaterThan(members.count, 1)
            var narrators: Set<[Int]> = []
            for member in members {
                let code = try XCTUnwrap(chains.code(slug: member.slug, idInBook: member.idInBook), "\(member.slug) \(member.idInBook)")
                XCTAssertTrue(code.hasSuffix("~\(sample.id)"), "\(member.slug) \(member.idInBook): \(code)")
                XCTAssertEqual(HadithChainStore.shared.chainGroup(slug: member.slug, idInBook: member.idInBook), sample.id)
                let parsed = try XCTUnwrap(HadithChainDecoder.parse(code))
                XCTAssertEqual(parsed.group, sample.id)
                let data = try books[member.slug] ?? book(member.slug)
                books[member.slug] = data
                let ids = (parsed.shared + parsed.branches.flatMap(\.layers)).map { layer in layer.compactMap(\.narrator).sorted() }.flatMap { $0 }
                narrators.insert(ids)
            }
            XCTAssertEqual(narrators.count, 1, "group \(sample.id): its chains name different narrators")
        }
    }

    /// The two names Abu checked by hand (2026-10-31): Ibn Mas'ud is one page with "ابن مسعود" and
    /// the bare "عبد الله" of his students joined into it, Aishah's title form is hers, and the whole
    /// index reads back in one walk with every generation a Companion's or below.
    func testTheJoinedIdentitiesAndTheIndex() throws {
        let pack = try pack()
        let all = pack.allProfiles()
        XCTAssertEqual(all.count, pack.narratorCount)
        XCTAssertEqual(all.map(\.id), Array(1...pack.narratorCount), "the index is by id")
        let ibnMasud = try XCTUnwrap(all.first { $0.key == "عبد الله بن مسعود" }, "Ibn Mas'ud has a page")
        XCTAssertEqual(ibnMasud.english, "Abdullah ibn Mas'ud")
        XCTAssertEqual(ibnMasud.generation, 1, "a Companion")
        XCTAssertGreaterThan(ibnMasud.narrations, 400, "his students' bare عبد الله is his")
        XCTAssertTrue(ibnMasud.forms.contains { HadithIsnadEnglish.fold($0.name) == "ابن مسعود" }, "\(ibnMasud.forms)")
        XCTAssertNil(all.first { $0.key == "ابن مسعود" }, "no second page for the short form")
        let aishah = try XCTUnwrap(all.first { $0.key == "عائشه" })
        XCTAssertGreaterThan(aishah.narrations, 2_180)
        XCTAssertEqual(aishah.generation, 1)
        XCTAssertNil(all.first { $0.key.contains("المؤمنين") && $0.key.contains("عائشه") }, "the title is set aside")
        XCTAssertTrue(all.allSatisfy { $0.generation <= 12 })
        XCTAssertGreaterThan(all.filter { $0.generation == 1 }.count, 400, "the Companions")
        XCTAssertGreaterThan(all.filter { $0.generation == 2 }.count, 1_000, "the Successors")
        // Jabir stays two: ibn Abdullah and ibn Samurah both narrate from the Prophet ﷺ.
        XCTAssertNotNil(all.first { $0.key == "جابر" }, "the bare Jabir is left apart")
        XCTAssertNotNil(all.first { $0.key == "جابر بن عبد الله" })
    }

    /// Abu, 2026-11-22: "who is li?? Also for Ali it says just Ali ... instead of his full name Ali ibn
    /// Abi Talib. Fix for all". The one spoken to in "قال لي رسول الله ﷺ" is no narrator, nor is any
    /// word no name begins with; Ali's page carries his full name and none of the "حدثنا علي" at the
    /// foot of a chain (Ali ibn al-Madini, on a page of his own bare name); a Companion's page never
    /// says he taught a compiler through a name folded into his.
    func testNoWordOfTheReportIsANarratorAndAliCarriesHisName() throws {
        let pack = try pack()
        let all = pack.allProfiles()
        let notNames: Set<String> = ["لي", "لنا", "عند", "او", "لم", "كان", "سمعه", "اصحاب", "ازواج", "شهد", "غير", "احد", "اباه", "جدي"]
        let stray = all.filter { notNames.contains($0.key) || $0.key.hasPrefix("لي ") || $0.key.hasPrefix("لنا ") }
        XCTAssertTrue(stray.isEmpty, "not narrators: \(stray.map(\.key))")
        XCTAssertNil(all.first { $0.english == "Li" || $0.english.hasPrefix("Li ") })

        let ali = try XCTUnwrap(all.first { $0.key == "علي بن ابي طالب" }, "Ali ibn Abi Talib has a page")
        XCTAssertEqual(ali.english, "Ali ibn Abi Talib")
        XCTAssertEqual(HadithIsnadEnglish.fold(ali.name), "علي بن ابي طالب", ali.name)
        XCTAssertEqual(ali.generation, 1, "a Companion")
        XCTAssertGreaterThan(ali.fromProphet, 500)
        XCTAssertEqual(ali.teacher, 0, "he taught no compiler")
        XCTAssertTrue(ali.forms.contains { HadithIsnadEnglish.fold($0.name) == "علي" }, "the bare name of the top is his: \(ali.forms)")
        let bare = try XCTUnwrap(all.first { $0.key == "علي" }, "the bare علي at the foot of a chain is left apart")
        XCTAssertEqual(bare.fromProphet, 0)
        XCTAssertGreaterThan(bare.teacher, 50, "al-Bukhari's own teacher")

        // The same for every Companion a shorter name was folded into: Umar, Anas, Abu Sa'id al-Khudri.
        for key in ["عمر بن خطاب", "انس بن مالك", "ابو هريره"] {
            let profile = try XCTUnwrap(all.first { $0.key == key }, key)
            XCTAssertEqual(profile.teacher, 0, key)
        }
        let khudri = try XCTUnwrap(all.first { $0.english == "Abu Sa'id al-Khudri" })
        XCTAssertEqual(khudri.teacher, 0)
        XCTAssertGreaterThan(khudri.fromProphet, 1_000)

        // "قال قال لي رسول الله ﷺ" (Ibn Majah 4218): the chain ends at Abdullah, who narrates from him.
        let hadith = try XCTUnwrap(try book("ibnmajah").hadith(numbered: 4218))
        let chain = try XCTUnwrap(HadithChainStore.shared.chain(slug: "ibnmajah", idInBook: 4218, arabic: hadith.arabic,
                                                                 bookTitle: "Sunan Ibn Majah"))
        let top = chain.top.flatMap(\.nodes)
        XCTAssertEqual(top.first?.role, .prophet, "the chain reaches the Prophet ﷺ")
        XCTAssertEqual(top.dropFirst().first.map { HadithIsnadEnglish.fold($0.arabic) }, "عبد الله", "\(top.map(\.arabic))")
        XCTAssertFalse(top.contains { HadithIsnadEnglish.fold($0.arabic) == "لي" }, "\(top.map(\.arabic))")

        // A relation and someone left unnamed have no page, and still read in English.
        let english = HadithIsnadEnglish(slug: "bukhari")
        XCTAssertEqual(english.narrator(arabic: "أَخِي", id: nil), "my brother")
        XCTAssertEqual(english.narrator(arabic: "أَبَاهُ", id: nil), "his father")
        XCTAssertEqual(english.narrator(arabic: "غَيْرِ، وَاحِدٍ", id: nil), "more than one")
        XCTAssertEqual(english.transmission("سَمِعَهُ"), "heard it")
    }

    /// Abu, 2026-11-22: "when it says no grade reported if it's sahih Bukhari or Muslim that means
    /// sahih". The lists' Grade sort and grouping file a row of the two Sahihs under "Sahih"; the row
    /// still prints no grade line, and a graded row is filed under its own verdicts.
    @MainActor
    func testTheTwoSahihsAreFiledUnderSahih() throws {
        let entries = HadithListEntry.make([
            HadithListEntry.Request(slug: "bukhari", idInBook: 1),
            HadithListEntry.Request(slug: "muslim", idInBook: 8),
            HadithListEntry.Request(slug: "abudawud", idInBook: 1),
        ])
        for slug in ["bukhari", "muslim"] {
            let entry = try XCTUnwrap(entries.first { $0.book.slug == slug }, slug)
            XCTAssertTrue(entry.gradeLine.isEmpty, "\(slug) prints no grade line")
            XCTAssertEqual(entry.gradeGroup, String(localized: "Sahih"), slug)
        }
        let graded = try XCTUnwrap(entries.first { $0.book.slug == "abudawud" })
        XCTAssertFalse(graded.gradeLine.isEmpty)
        XCTAssertEqual(graded.gradeGroup, graded.gradeLine, "a graded row is filed under its own verdicts")
    }

    /// The chain of al-Bukhari 1 in English: every narrator chip carries his English name, the Prophet
    /// ﷺ and the collector theirs, and the words of transmission their meaning.
    func testTheFirstHadithOfAlBukhariReadsInEnglish() throws {
        let hadith = try XCTUnwrap(try book("bukhari").hadith(numbered: 1))
        let chain = try XCTUnwrap(HadithChainStore.shared.chain(slug: "bukhari", idInBook: 1, arabic: hadith.arabic,
                                                                bookTitle: "Sahih al-Bukhari", english: true))
        let nodes = chain.top.flatMap(\.nodes)
        XCTAssertEqual(nodes.first?.name, HadithIsnadEnglish.prophet)
        for node in nodes.dropFirst() {
            XCTAssertFalse(node.name.isEmpty, node.arabic)
        }
        XCTAssertEqual(nodes.dropFirst().first?.name, "Umar ibn al-Khattab")
        XCTAssertEqual(chain.bottom.first?.nodes.first?.name, "al-Bukhari")
        let subtitles = (chain.top + chain.bottom).compactMap(\.subtitle)
        XCTAssertTrue(subtitles.contains("narrated to us"), "\(subtitles)")
        XCTAssertTrue(subtitles.contains("I heard"), "\(subtitles)")
        let plain = try XCTUnwrap(HadithChainStore.shared.chain(slug: "bukhari", idInBook: 1, arabic: hadith.arabic, bookTitle: "Sahih al-Bukhari"))
        XCTAssertTrue(plain.top.flatMap(\.nodes).allSatisfy { $0.name.isEmpty }, "without the switch, Arabic alone")
    }

    /// The first hadith of al-Bukhari: every narrator chip opens a profile that lists it, 'Umar at
    /// the top, al-Humaydi as the compiler's teacher, and the collector's chip opens nothing.
    func testTheFirstHadithOfAlBukhariNamesItsNarrators() throws {
        let hadith = try XCTUnwrap(try book("bukhari").hadith(numbered: 1))
        let chain = try XCTUnwrap(HadithChainStore.shared.chain(slug: "bukhari", idInBook: 1, arabic: hadith.arabic, bookTitle: "Sahih al-Bukhari"))
        let nodes = chain.top.flatMap(\.nodes)
        XCTAssertNil(nodes.first?.narratorID, "the Prophet ﷺ is no narrator's page")
        XCTAssertNil(chain.bottom.first?.nodes.first?.narratorID, "the collector is no narrator's page")
        let narrators = nodes.dropFirst().compactMap(\.narratorID)
        XCTAssertEqual(narrators.count, 6)
        for (index, id) in narrators.enumerated() {
            let profile = try XCTUnwrap(HadithNarratorStore.shared.profile(id: id))
            XCTAssertGreaterThan(profile.narrations, 0)
            let ref = try XCTUnwrap(HadithNarratorStore.shared.refs(id: id).first { $0.slug == "bukhari" && $0.idInBook == 1 },
                                    "\(profile.name) does not list bukhari 1")
            XCTAssertEqual(ref.grade, .sahih)
            XCTAssertEqual(ref.role, index == 0 ? .top : (index == narrators.count - 1 ? .teacher : .link), profile.name)
        }
        let umar = try XCTUnwrap(HadithNarratorStore.shared.profile(id: narrators[0]))
        // Scalars, not Characters: a String `contains` would not find "ر" inside the grapheme "رَ".
        XCTAssertTrue(umar.name.unicodeScalars.starts(with: "عُمَرَ".unicodeScalars), umar.name)
        XCTAssertGreaterThan(umar.fromProphet, 100)
        // A memory warning empties the cache; the next question inflates the block again.
        HadithNarratorStore.shared.purge()
        XCTAssertEqual(HadithNarratorStore.shared.profile(id: narrators[0])?.name, umar.name)
    }

    // MARK: The pages (2026-11-22)

    /// Abu, 2026-11-22: "when I click on a narrator one theres a progress view that loads". A
    /// narrator's page is whole when it is made: his profile, and a row for every narration naming
    /// him, none of whose text has been read. And "better filtering": his counts are what narrow
    /// the list, so each count is exactly how many rows its filter leaves.
    @MainActor
    func testANarratorsPageIsWholeWhenMadeAndHisCountsNarrowIt() throws {
        let ali = try XCTUnwrap(HadithNarratorStore.shared.allProfiles().first { $0.key == "علي بن ابي طالب" })
        let started = CFAbsoluteTimeGetCurrent()
        let page = HadithNarratorPage(narratorID: ali.id)
        print("NARRATOR PAGE ali: \(Int((CFAbsoluteTimeGetCurrent() - started) * 1000)) ms")
        let profile = try XCTUnwrap(page.profile)
        let list = page.list
        XCTAssertEqual(list.entries.count, profile.narrations)
        XCTAssertEqual(list.shown, profile.narrations)
        XCTAssertFalse(list.isNarrowed)
        XCTAssertTrue(list.narrator)

        // By book to begin with: a section a book, each as long as the profile counted.
        XCTAssertEqual(Dictionary(uniqueKeysWithValues: list.sections.map { ($0.id, $0.rows.count) }),
                       Dictionary(uniqueKeysWithValues: profile.books.map { ("book-\($0.slug)", $0.count) }))
        XCTAssertEqual(list.books.map(\.count).reduce(0, +), profile.narrations)

        list.role = .top
        XCTAssertEqual(list.shown, profile.fromProphet)
        XCTAssertTrue(list.isNarrowed)
        // "From the Prophet ﷺ" is said only of a chain that names him: the narrations whose chain
        // stops at 'Ali are their own place, and their rows say so.
        XCTAssertTrue(list.sections.flatMap(\.rows).allSatisfy { $0.secondaryBadge == String(localized: "From the Prophet ﷺ") })
        list.role = .end
        XCTAssertEqual(list.shown, profile.ends)
        XCTAssertGreaterThan(profile.ends, 100)
        XCTAssertTrue(list.sections.flatMap(\.rows).allSatisfy { $0.secondaryBadge == String(localized: "Top of the Chain") })
        list.role = .teacher
        XCTAssertEqual(list.shown, profile.teacher)
        list.role = .link
        XCTAssertEqual(list.shown, profile.narrations - profile.fromProphet - profile.ends - profile.teacher)
        list.role = nil
        for category in HadithGradeCategory.allCases {
            list.grade = category
            XCTAssertEqual(list.shown, profile.count(category), category.title)
        }
        list.grade = .sahih
        list.role = .top
        let both = list.sections.flatMap(\.rows)
        XCTAssertFalse(both.isEmpty)
        XCTAssertTrue(both.allSatisfy { $0.role == .top && $0.category == .sahih })

        list.reset()
        XCTAssertFalse(list.isNarrowed)
        XCTAssertEqual(list.shown, profile.narrations)

        // Grouped by his place in the chain, from the Prophet ﷺ down; by grade, the pack's counts.
        list.grouping = .place
        XCTAssertEqual(list.sections.first?.rows.count, profile.fromProphet)
        XCTAssertEqual(list.sections.map(\.rows.count).reduce(0, +), profile.narrations)
        list.grouping = .grade
        XCTAssertEqual(list.sections.first?.title, HadithGradeCategory.sahih.title)
        XCTAssertEqual(list.sections.first?.rows.count, profile.count(.sahih))

        // One book alone, as a tap on its chip leaves it.
        let bukhari = try XCTUnwrap(list.books.first { $0.book.slug == "bukhari" })
        list.hiddenBooks = Set(list.books.map(\.book.slug)).subtracting(["bukhari"])
        XCTAssertEqual(list.shown, bukhari.count)

        // The longest list on the shelf is made the same way, in the time of a frame or two.
        let most = try XCTUnwrap(HadithNarratorStore.shared.allProfiles().max { $0.narrations < $1.narrations })
        let begun = CFAbsoluteTimeGetCurrent()
        let longest = HadithNarratorPage(narratorID: most.id)
        print("NARRATOR PAGE \(most.english) (\(most.narrations)): \(Int((CFAbsoluteTimeGetCurrent() - begun) * 1000)) ms")
        XCTAssertEqual(longest.list.entries.count, most.narrations)
    }

    /// The search field of a list looks for the typed words in the rows' own text, Arabic or
    /// English, and an emptied field shows the list whole again.
    @MainActor
    func testAListIsSearchedByItsNarrationsOwnWords() async throws {
        let ali = try XCTUnwrap(HadithNarratorStore.shared.allProfiles().first { $0.key == "علي بن ابي طالب" })
        let list = HadithNarratorPage(narratorID: ali.id).list

        func settled() async throws {
            for _ in 0..<400 where list.searching { try await Task.sleep(nanoseconds: 25_000_000) }
            XCTAssertFalse(list.searching, "the search never finished")
        }

        // "لا تكذبوا علي" (Sahih al-Bukhari 106) is his, and far from all of his.
        list.query = "تكذبوا"
        XCTAssertTrue(list.searching)
        try await settled()
        XCTAssertTrue(list.isNarrowed)
        XCTAssertGreaterThan(list.shown, 0)
        XCTAssertLessThan(list.shown, list.entries.count / 4)
        let arabic = HadithFold.query("تكذبوا")
        let rows = list.sections.flatMap(\.rows)
        XCTAssertTrue(rows.allSatisfy { $0.hadith.matches(arabic) })
        XCTAssertTrue(rows.contains { $0.book.slug == "bukhari" && $0.hadith.idInBook == 106 })
        XCTAssertEqual(list.matchedQuery, "تكذبوا")

        // Every word, in any order, in the English.
        list.query = "lie against me"
        try await settled()
        XCTAssertGreaterThan(list.shown, 0)
        let words = ["lie", "against", "me"].map { HadithFold.query($0) }
        XCTAssertTrue(list.sections.flatMap(\.rows).allSatisfy { row in words.allSatisfy { row.hadith.matches($0) } })

        // A number alone finds the narration of that number.
        list.query = "106"
        try await settled()
        XCTAssertTrue(list.sections.flatMap(\.rows).contains { $0.book.slug == "bukhari" && $0.hadith.idInBook == 106 })

        list.query = ""
        XCTAssertFalse(list.searching)
        XCTAssertFalse(list.isNarrowed)
        XCTAssertEqual(list.shown, list.entries.count)
    }

    /// The index of narrators: found by a name in either script, held to a generation or to a place
    /// in the chain, where a row counts the narrations of that place.
    @MainActor
    func testTheIndexIsSearchedAndHeldToAGenerationAndAPlace() throws {
        let model = HadithNarratorsIndexModel()
        XCTAssertEqual(model.shown, model.profiles.count)
        XCTAssertFalse(model.isNarrowed)
        XCTAssertEqual(model.generations.first?.generation, 1, "the Companions lead")
        XCTAssertEqual(model.generations.map(\.count).reduce(0, +), model.profiles.count)

        model.query = "aishah"
        XCTAssertTrue(model.isNarrowed)
        XCTAssertTrue(model.buckets.flatMap(\.rows).contains { $0.english == "A'ishah" })
        XCTAssertLessThan(model.shown, 100)
        model.query = "عائشة"
        XCTAssertTrue(model.buckets.flatMap(\.rows).contains { $0.english == "A'ishah" })
        model.query = ""
        XCTAssertEqual(model.shown, model.profiles.count)

        model.generation = 1
        XCTAssertEqual(model.buckets.count, 1)
        XCTAssertEqual(model.shown, model.generations.first?.count)
        XCTAssertTrue(model.buckets.flatMap(\.rows).allSatisfy { $0.generation == 1 })

        model.reset()
        model.place = .first
        let first = model.buckets.flatMap(\.rows)
        XCTAssertTrue(first.allSatisfy { $0.fromProphet > 0 })
        let companions = try XCTUnwrap(model.buckets.first { $0.id == 1 })
        XCTAssertEqual(companions.rows.map(\.fromProphet), companions.rows.map(\.fromProphet).sorted(by: >),
                       "held to a place, the most narrations of THAT place lead")
        model.reset()
        XCTAssertEqual(model.shown, model.profiles.count)
    }

    /// The chain sheet and the similar sheet are whole when made, as the narrator's page is.
    @MainActor
    func testTheStudySheetsAreWholeWhenMade() throws {
        let data = try XCTUnwrap(HadithStore.shared.book(try XCTUnwrap(HadithCatalogBook.bySlug["bukhari"])))
        let catalog = try XCTUnwrap(HadithCatalogBook.bySlug["bukhari"])
        let hadith = try XCTUnwrap(data.hadith(numbered: 1))

        let chain = HadithChainPage(book: catalog, hadith: hadith)
        XCTAssertNotNil(chain.chain)
        XCTAssertNotNil(chain.tree, "the hadith of intentions has a tree of narrators")

        let similar = SimilarHadithsPage(slug: "bukhari", idInBook: 1)
        let matches = SimilarHadithsStore.shared.matches(slug: "bukhari", idInBook: 1)
        XCTAssertFalse(matches.isEmpty)
        XCTAssertEqual(similar.list.entries.count, matches.count)
        XCTAssertTrue(similar.list.tiered)
        XCTAssertEqual(similar.list.sort, .match)
        XCTAssertEqual(similar.list.shown, matches.count)
    }
}
