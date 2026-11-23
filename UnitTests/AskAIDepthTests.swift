import XCTest
@testable import iPhone

/// Ask AI's depth (AskAIDepth.swift): what a verse or a hadith is read WITH, how the notes reach the
/// prompt and the policing, and what gives way when the window is short. And its History
/// (`AskAIConversation.filing`): the conversations a new visit sets aside.
@MainActor
final class AskAIDepthTests: XCTestCase {
    private func question(_ text: String) -> AskAIQuestion {
        AskAIQuestion.analyze(text, previousTopic: nil, hasHistory: false)
    }

    private func note(_ kind: AskAISourceNote.Kind, title: String = "Ibn Kathir", characters: Int = 300) -> AskAISourceNote {
        AskAISourceNote(kind: kind, title: title, text: String(repeating: "y", count: characters))
    }

    // MARK: The prompt

    func testANoteIsSetUnderItsSourceAndCitedByItsNumber() {
        var source = AskAISource(kind: .ayah(surah: 2, ayah: 153), reference: "2:153", title: "Al-Baqarah 2:153",
                                 text: "O you who have believed, seek help through patience and prayer.")
        source.notes = [
            AskAISourceNote(kind: .translation, title: "Clear Quran (Mustafa Khattab)", text: "O believers! Seek comfort in patience and prayer."),
            AskAISourceNote(kind: .tafsir, title: "Ibn Kathir", text: "Allah commanded patience after gratitude."),
        ]
        let lines = source.promptLine(number: 3, characters: 500).components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 3)
        XCTAssertTrue(lines[0].hasPrefix("[3] 2:153"))
        // The other translation is wording, in quotation marks; the tafsir is prose.
        XCTAssertTrue(lines[1].contains("With [3], another translation of this verse, Clear Quran (Mustafa Khattab): \u{201C}O believers!"))
        // A commentary says whose words it is not.
        XCTAssertTrue(lines[2].contains("With [3], the tafsir Ibn Kathir on this verse (the commentator's words, not the Quran's): Allah commanded"))
        XCTAssertFalse(lines[2].contains("\u{201C}"))
    }

    func testTheInstructionsSayWhatTheNoteLinesAre() {
        let instructions = AskAIPrompt.instructions
        XCTAssertTrue(instructions.contains("begin with the word With"))
        XCTAssertTrue(instructions.contains("Cite them by that source's number"))
        XCTAssertTrue(instructions.contains("never the words of Allah or of the Prophet"))
    }

    // MARK: The readings follow "Show Riwayah / Qiraah"

    /// Abu, 2026-11-22: "only analyze qiraat if show qiraat is on". Off, nothing the model is
    /// given names the readings: not the rules, not the task.
    func testTheRulesNameTheReadingsOnlyWhileTheyAreShown() {
        let shown = AskAIPrompt.instructions(readsQiraat: true)
        XCTAssertEqual(shown, AskAIPrompt.instructions)
        XCTAssertTrue(shown.contains("a tafsir, how the readings (qiraat) differ in it, an explanation of the hadith"))
        XCTAssertTrue(shown.contains("between translations or readings only where"))

        let hidden = AskAIPrompt.instructions(readsQiraat: false)
        XCTAssertFalse(hidden.localizedCaseInsensitiveContains("qiraat"))
        XCTAssertFalse(hidden.localizedCaseInsensitiveContains("readings"))
        XCTAssertTrue(hidden.contains("another translation, a tafsir, an explanation of the hadith, or where else it is recorded"))
        XCTAssertTrue(hidden.contains("Bring up a difference between translations only where it adds to what was asked."))
        // The readings are the only difference between the two.
        XCTAssertEqual(hidden, shown.replacingOccurrences(of: "how the readings (qiraat) differ in it, ", with: "")
            .replacingOccurrences(of: " or readings only", with: " only"))
    }

    func testTheTaskAsksForTheReadingsOnlyOfAVerseThatCarriesThem() {
        var verse = AskAISource(kind: .ayah(surah: 1, ayah: 4), reference: "1:4", title: "Al-Fatihah 1:4",
                                text: "Sovereign of the Day of Recompense.")
        verse.isSubject = true
        verse.notes = [AskAISourceNote(kind: .translation, title: AskAIDepth.otherTranslationTitle, text: "Master of the Day of Judgment.")]
        let ask = question("What does 1:4 mean?")
        let without = AskAIPrompt.build(question: ask, sources: [verse], history: [], profile: .onDevice)
        XCTAssertTrue(without.contains("The question names a verse"))
        XCTAssertFalse(without.localizedCaseInsensitiveContains("qiraat"))
        XCTAssertTrue(without.contains("say where each point comes from. If a line gives another translation"))

        verse.notes.append(AskAISourceNote(kind: .readings, title: "", text: "Asim reads maliki, meaning Owner."))
        let with = AskAIPrompt.build(question: ask, sources: [verse], history: [], profile: .onDevice)
        XCTAssertTrue(with.contains("If a line beneath the verse says how the readings (qiraat) differ in it, give that its own short paragraph"))
        XCTAssertTrue(with.contains("With [1], how the readings (qiraat) of this verse differ: Asim reads"))
    }

    // MARK: What gives way

    private func noted(_ source: AskAISource) -> AskAISource {
        var copy = source
        copy.notes = [note(.tafsir, characters: 400), note(.translation, title: "Clear Quran (Mustafa Khattab)", characters: 220)]
        return copy
    }

    func testANoteNeverCostsASourceTheQuestionDidNotName() {
        // Eight full sources fit the on-device estimate bare (AskAIPromptTests). With 2,000 characters
        // of notes on the first three they do not: the notes give way, the lowest-ranked source's
        // last one first, and all eight sources stay.
        var sources = (0..<8).map { AskAISource.fixture(reference: "2:\($0 + 1)", characters: 500) }
        for index in 0..<3 { sources[index] = noted(sources[index]) }
        let kept = AskAIPrompt.fit(question: question("What is the nisab for zakat?"), sources: sources, history: [], profile: .onDevice)
        XCTAssertEqual(kept.count, 8)
        XCTAssertEqual(kept[0].notes.count, 2)
        XCTAssertLessThan(kept[2].notes.count, 2)
        XCTAssertTrue(kept.dropFirst(3).allSatisfy { $0.notes.isEmpty })
    }

    func testAShortVerseIsChargedItsOwnLength() {
        // Eight verses of sixty characters leave the window room for every note: nothing is dropped.
        var sources = (0..<8).map { AskAISource.fixture(reference: "2:\($0 + 1)", characters: 60) }
        for index in 0..<3 { sources[index] = noted(sources[index]) }
        let kept = AskAIPrompt.fit(question: question("What is the nisab for zakat?"), sources: sources, history: [], profile: .onDevice)
        XCTAssertEqual(kept.count, 8)
        XCTAssertEqual(kept.prefix(3).map(\.notes.count), [2, 2, 2])
    }

    func testTheSubjectsNotesAreWorthTheWeakestSourcesAndNoMore() async throws {
        guard #available(iOS 26.0, *) else { throw XCTSkip("FoundationModels needs iOS 26") }
        let subject = noted(AskAISource(kind: .ayah(surah: 2, ayah: 255), reference: "2:255", title: "Al-Baqarah 2:255",
                                        text: String(repeating: "x", count: 500), isSubject: true))
        let sources = [subject] + (0..<7).map { AskAISource.fixture(reference: "3:\($0 + 1)", characters: 500) }
        let floor = AskAIPrompt.noteFloor(for: .onDevice)
        XCTAssertEqual(floor, 5)
        let ask = question("What is the nisab for zakat?")
        let reserved = AskAIEngine.instructionTokens + min(ask.intent.maxResponseTokens, AskAIProfile.onDevice.responseTokenCap) + 64
        let window = AskAIProfile.onDevice.contextTokens
        /// A tokenizer under which a prompt of `characters` (and forty more, less than any note) just fits.
        func tokenizer(fitting characters: Int) -> (String) async -> Int? {
            let perCharacter = Double(window - reserved) / Double(characters + 40)
            return { Int((Double($0.count) * perCharacter).rounded(.up)) }
        }
        var bare = Array(sources.prefix(floor))
        let withNotes = AskAIPrompt.build(question: ask, sources: bare, history: [], profile: .onDevice).count
        bare[0].notes = []
        let withoutNotes = AskAIPrompt.build(question: ask, sources: bare, history: [], profile: .onDevice).count

        // Room for five sources and the subject's notes: the three weakest sources go, the notes stay.
        let roomy = await AskAIPrompt.fit(question: ask, sources: sources, history: [], profile: .onDevice, measure: tokenizer(fitting: withNotes))
        XCTAssertEqual(roomy.count, floor)
        XCTAssertEqual(roomy[0].notes.count, 2)
        // Room for five bare sources only: at the floor the notes go, and the five sources stay.
        let tight = await AskAIPrompt.fit(question: ask, sources: sources, history: [], profile: .onDevice, measure: tokenizer(fitting: withoutNotes))
        XCTAssertEqual(tight.count, floor)
        XCTAssertTrue(tight.allSatisfy { $0.notes.isEmpty })
    }

    func testCommentaryIsReadOnlyWhereItSpeaksToTheQuestion() {
        let terms = question("What does the Quran say about backbiting?").searchTerms
        XCTAssertTrue(AskAIDepth.speaksToQuestion("Allah forbade backbiting, and likened it to eating the flesh of a dead brother.", terms: terms))
        XCTAssertFalse(AskAIDepth.speaksToQuestion("Mankind was one community, then Allah sent the Prophets as bringers of good tidings.", terms: terms))
        // A question with no words of its own gates nothing.
        XCTAssertTrue(AskAIDepth.speaksToQuestion("Mankind was one community.", terms: []))
    }

    // MARK: Policing

    func testAQuotationFromANoteIsVerified() {
        var source = AskAISource.fixture(reference: "2:153", characters: 40)
        source.notes = [AskAISourceNote(kind: .translation, title: "Clear Quran (Mustafa Khattab)",
                                        text: "O believers! Seek comfort in patience and prayer. Allah is truly with those who are patient.")]
        let answer = "Another translation reads \u{201C}Seek comfort in patience and prayer\u{201D} [1]."
        XCTAssertEqual(AskAIText.policeQuotations(answer, sources: [source]).flagged, 0)
        let invented = "It says \u{201C}patience is the key to every locked door\u{201D} [1]."
        XCTAssertEqual(AskAIText.policeQuotations(invented, sources: [source]).flagged, 1)
    }

    func testAQuotedCommentarySaysWhereItIsFrom() {
        // The replay of 2026-11-22: the Hadith Encyclopedia's explanation of Sahih Muslim 2564a came back
        // in quotation marks after "He also explained this as". The quotation now names its origin.
        var source = AskAISource(kind: .hadith(slug: "muslim", idInBook: 6541), reference: "Sahih Muslim 2564a", title: "Sahih Muslim 2564a",
                                 text: "Do not nurse grudge, and be as fellow-brothers and servants of Allah.")
        source.notes = [AskAISourceNote(kind: .explanation, title: "Hadith Encyclopedia",
                                        text: "Be like brothers, by abandoning the aforementioned prohibitions and showing cordiality, kindness and compassion.")]
        let answer = "He also explained this as: \u{201C}Be like brothers, by abandoning the aforementioned prohibitions\u{201D} [1]."
        let policed = AskAIText.policeQuotations(answer, sources: [source])
        XCTAssertEqual(policed.flagged, 0)
        XCTAssertEqual(policed.text, "He also explained this as: \u{201C}Be like brothers, by abandoning the aforementioned prohibitions\u{201D} (from the Hadith Encyclopedia\u{2019}s explanation, not the hadith itself) [1].")
        // The hadith's own words are left as they are.
        let own = "The Prophet said \u{201C}be as fellow-brothers and servants of Allah\u{201D} [1]."
        XCTAssertEqual(AskAIText.policeQuotations(own, sources: [source]).text, own)
        // A tafsir quoted is the commentator's, not the verse's.
        var verse = AskAISource.fixture(reference: "2:153", characters: 40)
        verse.notes = [AskAISourceNote(kind: .tafsir, title: "Ibn Kathir", text: "Allah mentioned patience after He commanded gratitude to Him.")]
        let quoted = AskAIText.policeQuotations("Allah says \u{201C}patience after He commanded gratitude to Him\u{201D} [1].", sources: [verse])
        XCTAssertTrue(quoted.text.contains("(from the tafsir Ibn Kathir, not the verse itself)"))
    }

    func testAReferenceANoteNamesIsNotARecalledOne() {
        var source = AskAISource(kind: .hadith(slug: "bukhari", idInBook: 1), reference: "Sahih al-Bukhari 1", title: "Sahih al-Bukhari 1",
                                 text: "Actions are by intentions.")
        source.notes = [AskAISourceNote(kind: .narrations, title: "", text: "The same wording is also recorded in Sahih Muslim 1907.",
                                        references: ["Sahih Muslim 1907"])]
        let answer = "Deeds are judged by intentions [1], a report Muslim records as well (Sahih Muslim 1907)."
        XCTAssertEqual(AskAIText.policeCitations(answer, sources: [source]).removed, 0)
        let recalled = "Deeds are judged by intentions [1] (Sahih Muslim 2564)."
        XCTAssertEqual(AskAIText.policeCitations(recalled, sources: [source]).removed, 1)
    }

    func testACopiedNoteLineIsDropped() {
        var source = AskAISource.fixture(reference: "2:153", characters: 40)
        source.notes = [AskAISourceNote(kind: .tafsir, title: "Ibn Kathir", text: "Allah commanded patience after gratitude.")]
        let answer = "Patience and prayer are the believer's help [1].\n" + source.notes[0].promptLine(number: 1)
        let cleaned = AskAIText.droppingSourceEchoes(answer, sources: [source])
        XCTAssertEqual(cleaned, "Patience and prayer are the believer's help [1].")
        // A sentence that merely opens with the word is the model's own.
        let own = "With [1], the verse ties patience to prayer."
        XCTAssertEqual(AskAIText.droppingSourceEchoes(own, sources: [source]), own)
    }

    func testAVerseShapedBracketBecomesItsSourcesMarker() {
        // "What does the Quran say about being kind to parents?", replayed 2026-11-22: the answer cited
        // "[2:83]", "[3:14]" and "[1:233]" for sources 2 (2:83), 3 (31:14) and 1 (2:233).
        let sources = [
            AskAISource(kind: .ayah(surah: 2, ayah: 233), reference: "2:233", title: "Al-Baqarah 2:233", text: "No mother should be harmed through her child."),
            AskAISource(kind: .ayah(surah: 2, ayah: 83), reference: "2:83", title: "Al-Baqarah 2:83", text: "And to parents do good."),
            AskAISource(kind: .ayah(surah: 31, ayah: 14), reference: "31:14", title: "Luqman 31:14", text: "Be grateful to Me and to your parents."),
        ]
        let answer = "Do good to parents [2:83], be grateful to them [3:14], harm neither [1:233], and more [9:99]. Luqman says so too [31:14]."
        let result = AskAIText.normalizeMarkers(answer, sourceCount: sources.count, sources: sources)
        XCTAssertEqual(result.text, "Do good to parents [2], be grateful to them [3], harm neither [1], and more. Luqman says so too [3].")
        XCTAssertEqual(result.removed, 1)
        // Without the sources (a caller that only counts) the text is left as the model wrote it.
        XCTAssertEqual(AskAIText.normalizeMarkers("Parents [2:83].", sourceCount: 3).text, "Parents [2:83].")
    }

    func testNotesSurviveTheSavedTranscript() throws {
        var source = AskAISource.fixture(reference: "2:153", characters: 4_000)
        source.notes = [note(.tafsir), note(.readings, title: "")]
        let clipped = source.clippingText(to: 2_400)
        XCTAssertLessThanOrEqual(clipped.text.count, 2_401)
        XCTAssertEqual(clipped.notes, source.notes)
        let decoded = try JSONDecoder().decode(AskAISource.self, from: JSONEncoder().encode(clipped))
        XCTAssertEqual(decoded.notes, source.notes)
        // A transcript saved before notes existed still reads.
        let old = #"{"kind":{"ayah":{"surah":2,"ayah":153}},"reference":"2:153","title":"Al-Baqarah 2:153","text":"Seek help."}"#
        XCTAssertTrue(try JSONDecoder().decode(AskAISource.self, from: Data(old.utf8)).notes.isEmpty)
    }

    // MARK: The readings, as prose

    func testReadingsProseNamesEachReadingItsMeaningAndItsReaders() throws {
        typealias Reading = QiraatVariantsStore.Reading
        let owner = Reading(id: 0, text: "مَالِكِ", transliteration: "māliki yawmi d-dīni", english: "\u{201C}Owner of the Day of Judgement\u{201D}",
                            explanation: "This denotes ownership.", grammaticalForm: "", rootLetters: "", readers: [5], transmitters: [])
        let king = Reading(id: 1, text: "مَلِكِ", transliteration: "maliki yawmi d-dīni", english: "\u{201C}King of the Day of Judgement\u{201D}",
                           explanation: "This describes sovereignty.", grammaticalForm: "", rootLetters: "", readers: [1], transmitters: [])
        let sense = QiraatVariantsStore.Juncture(id: 0, text: "مَـٰلِكِ", category: "A", segments: [], readings: [king, owner],
                                                 note: "These readings provide complementary meanings.")
        let form = QiraatVariantsStore.Juncture(id: 1, text: "x", category: "B", segments: [], readings: [king, owner], note: "")
        func text(everyJuncture: Bool) -> String? {
            AskAIDepth.readingsText(junctures: [sense, form], everyJuncture: everyJuncture, limit: 2_000,
                                    attribution: { $0.id == 0 ? "\u{02BF}\u{0100}\u{1E63}im" : "N\u{0101}fi\u{02BF}" }, hafsReading: { _ in 0 })
        }
        let plain = try XCTUnwrap(text(everyJuncture: false))
        // One sentence a reading, who first; Hafs's leads and is marked as the one the verse is quoted in.
        XCTAssertEqual(plain, "Asim read māliki yawmi d-dīni, meaning \u{201C}Owner of the Day of Judgement\u{201D} (the reading quoted above). "
                       + "Nafi read maliki yawmi d-dīni, meaning \u{201C}King of the Day of Judgement\u{201D}. "
                       + "These readings provide complementary meanings.")
        // Only the place where the sense differs, and no per-reading explanation, unless the verse is the subject.
        XCTAssertFalse(plain.contains("denotes ownership"))
        XCTAssertEqual(plain.components(separatedBy: "(the reading quoted above)").count, 2)
        let whole = try XCTUnwrap(text(everyJuncture: true))
        XCTAssertTrue(whole.contains("This denotes ownership"))
        XCTAssertEqual(whole.components(separatedBy: "(the reading quoted above)").count, 3)
        // A place every reader reads to one meaning says nothing to a question that is not about the verse.
        let same = QiraatVariantsStore.Juncture(id: 0, text: "x", category: "A", segments: [], readings: [
            owner, Reading(id: 1, text: "y", transliteration: "maaliki", english: "Owner of the Day of Judgement", explanation: "", grammaticalForm: "", rootLetters: "", readers: [2], transmitters: []),
        ], note: "")
        XCTAssertNil(AskAIDepth.readingsText(junctures: [same], everyJuncture: false, limit: 2_000, attribution: { _ in "" }, hafsReading: { _ in nil }))
    }

    // MARK: The app's own data

    #if HAS_QURAN
    func testAVerseOnTheQuestionIsReadWithItsTafsirAndItsOtherTranslation() async throws {
        let quranData = QuranData.shared
        await quranData.waitUntilCoreLoaded()
        let fatihah = try XCTUnwrap(AskAISourceFactory.ayah(surah: 1, ayah: 4, quranData: quranData))
        let patience = try XCTUnwrap(AskAISourceFactory.ayah(surah: 2, ayah: 153, quranData: quranData))
        let budget = AskAIProfile.onDevice.retrievalBudget
        let sources = await AskAIDepth.attach(to: [fatihah, patience], question: question("What does the Quran say about patience?"), budget: budget)
        XCTAssertEqual(sources.count, 2)
        // 2:153 is about patience, and its tafsir says so: read first, then the other translation.
        XCTAssertEqual(sources[1].notes.first?.kind, .tafsir)
        XCTAssertEqual(sources[1].notes.first?.title, TafsirAuthor.ibnKathir.rawValue)
        let other = try XCTUnwrap(sources[1].notes.first { $0.kind == .translation })
        XCTAssertEqual(other.title, AskAIDepth.otherTranslationTitle)
        XCTAssertNotEqual(other.text, patience.text)
        // 1:4 says nothing of patience: a retrieved verse off the question is read alone.
        XCTAssertTrue(sources[0].notes.isEmpty)
        // Within the turn's budget, and every note within sight of its cap.
        XCTAssertLessThanOrEqual(sources.reduce(0) { $0 + $1.notesCost }, budget.noteCharacters)
        XCTAssertTrue(sources.flatMap(\.notes).allSatisfy { $0.text.count <= 460 })
    }

    func testTheVerseTheQuestionNamesIsReadWithItsReadings() async throws {
        let quranData = QuranData.shared
        await quranData.waitUntilCoreLoaded()
        let fatihah = try XCTUnwrap(AskAISourceFactory.ayah(surah: 1, ayah: 4, quranData: quranData, isSubject: true))
        let sources = await AskAIDepth.attach(to: [fatihah], question: question("What does 1:4 mean?"),
                                              budget: AskAIProfile.onDevice.retrievalBudget, readings: true)
        // 1:4 is the best-known difference in sense among the readings: Owner, or King.
        let readings = try XCTUnwrap(sources[0].notes.first { $0.kind == .readings })
        XCTAssertTrue(readings.text.contains("King"))
        XCTAssertTrue(readings.text.contains("Owner"))
        XCTAssertTrue(readings.text.contains("(the reading quoted above)"))
        XCTAssertTrue(sources[0].notes.contains { $0.kind == .translation })
        // With no Ibn Kathir source beside it, the subject carries his tafsir itself.
        XCTAssertEqual(sources[0].notes.first?.title, TafsirAuthor.ibnKathir.rawValue)
    }

    /// "Show Riwayah / Qiraah" off: the same verse is read with its tafsir and its other
    /// translation, and without its readings.
    func testAVerseIsReadWithoutItsReadingsWhileTheyAreNotShown() async throws {
        let quranData = QuranData.shared
        await quranData.waitUntilCoreLoaded()
        let fatihah = try XCTUnwrap(AskAISourceFactory.ayah(surah: 1, ayah: 4, quranData: quranData, isSubject: true))
        let sources = await AskAIDepth.attach(to: [fatihah], question: question("What does 1:4 mean?"),
                                              budget: AskAIProfile.onDevice.retrievalBudget, readings: false)
        XCTAssertFalse(sources[0].notes.contains { $0.kind == .readings })
        XCTAssertTrue(sources[0].notes.contains { $0.kind == .translation })
        XCTAssertEqual(sources[0].notes.first?.title, TafsirAuthor.ibnKathir.rawValue)
        XCTAssertFalse(sources[0].promptLine(number: 1, characters: 500).localizedCaseInsensitiveContains("qiraat"))
    }

    /// Left to itself, a turn follows the setting.
    func testATurnFollowsTheSetting() async throws {
        let quranData = QuranData.shared
        await quranData.waitUntilCoreLoaded()
        XCTAssertEqual(AskAIDepth.readsQiraat, Settings.shared.showQiraahDetails)
        let fatihah = try XCTUnwrap(AskAISourceFactory.ayah(surah: 1, ayah: 4, quranData: quranData, isSubject: true))
        let sources = await AskAIDepth.attach(to: [fatihah], question: question("What does 1:4 mean?"), budget: AskAIProfile.onDevice.retrievalBudget)
        XCTAssertEqual(sources[0].notes.contains { $0.kind == .readings }, Settings.shared.showQiraahDetails)
    }

    func testTheSubjectsTafsirSourceIsNotRepeatedAsANote() async throws {
        let quranData = QuranData.shared
        await quranData.waitUntilCoreLoaded()
        let verse = try XCTUnwrap(AskAISourceFactory.ayah(surah: 2, ayah: 255, quranData: quranData, isSubject: true))
        let tafsir = try XCTUnwrap(AskAISourceFactory.tafsir(surah: 2, ayah: 255, quranData: quranData))
        let sources = await AskAIDepth.attach(to: [verse, tafsir], question: question("Explain 2:255"), budget: AskAIProfile.onDevice.retrievalBudget)
        XCTAssertFalse(sources[0].notes.contains { $0.kind == .tafsir && $0.title == TafsirAuthor.ibnKathir.rawValue })
        XCTAssertTrue(sources[0].notes.contains { $0.kind == .translation })
        // The subject is read with a second tafsir even on the small window.
        XCTAssertTrue(sources[0].notes.contains { $0.kind == .tafsir && $0.title == TafsirAuthor.maarifUlQuran.rawValue })
        XCTAssertTrue(sources[1].notes.isEmpty)
    }
    #endif

    #if HAS_HADITH
    func testAHadithNamedInsideASentenceIsTheSubject() {
        // The parser reads a whole search field; a question wraps the reference in words.
        let bukhari = AskAIRetriever.hadithReference(in: "Explain Bukhari 1")
        XCTAssertEqual(bukhari?.book.slug, "bukhari")
        XCTAssertEqual(bukhari?.hadith, 1)
        let muslim = AskAIRetriever.hadithReference(in: "What does Sahih Muslim 2564a mean?")
        XCTAssertEqual(muslim?.book.slug, "muslim")
        XCTAssertEqual(muslim?.hadith, 2564)
        XCTAssertEqual(muslim?.suffix, "a")
        XCTAssertEqual(AskAIRetriever.hadithReference(in: "bukhari 6114")?.hadith, 6114)
        XCTAssertEqual(AskAIRetriever.hadithReference(in: "Tell me about Abu Dawud 2201, please")?.book.slug, "abudawud")
        // And the question is then a reference: the task and the lane weights of a named source.
        XCTAssertEqual(question("Explain Bukhari 1").intent, .reference)
        XCTAssertEqual(question("What does Sahih Muslim 2564a mean?").intent, .reference)
        XCTAssertNotEqual(question("Should a Muslim pray 5 times a day?").intent, .reference)
        // The words right before a number must name exactly one collection.
        for ordinary in ["Should a Muslim pray 5 times a day?", "Explain 2:255", "How many rakahs is Fajr, 2 or 4?",
                         "What happened in 622 after the hijrah?", "Is fasting 6 days of Shawwal sunnah?",
                         "Can a Muslim marry 4 wives?", "What are the 40 hadith of Nawawi?"] {
            XCTAssertNil(AskAIRetriever.hadithReference(in: ordinary), ordinary)
        }
    }

    func testAHadithIsReadWithItsExplanationAndItsOtherNarrations() async throws {
        let book = try XCTUnwrap(HadithCatalogBook.bySlug["bukhari"])
        let data = try XCTUnwrap(HadithStore.shared.book(book))
        let first = try XCTUnwrap(data.hadith(referenced: 1))
        await AskAIRetriever.prewarmHadithText([(data, first.row)])
        let source = try XCTUnwrap(AskAISourceFactory.hadith(book: book, data: data, hadith: first, isSubject: true))
        let sources = await AskAIDepth.attach(to: [source], question: question("Explain the hadith of intentions"), budget: AskAIProfile.onDevice.retrievalBudget)
        let notes = sources[0].notes
        let explanation = try XCTUnwrap(notes.first { $0.kind == .explanation })
        XCTAssertEqual(explanation.title, "Hadith Encyclopedia")
        XCTAssertGreaterThan(explanation.text.count, 100)
        // "Actions are by intentions" is in the Sunan too (Abu Dawud 2201, an-Nasa'i 75), and the note
        // names each as a reference an answer may write. Never the hadith's own collection.
        let narrations = try XCTUnwrap(notes.first { $0.kind == .narrations })
        XCTAssertFalse(narrations.references.isEmpty, narrations.text)
        XCTAssertTrue(narrations.references.contains("Sunan Abi Dawud 2201"), narrations.text)
        XCTAssertTrue(narrations.references.allSatisfy { narrations.text.contains($0) && !$0.hasPrefix("Sahih al-Bukhari") })
    }
    #endif

    // MARK: History

    private typealias Chat = AskAIConversation.SavedChat
    private func chat(_ question: String?) -> Chat {
        var messages: [AskAIConversation.Message] = []
        if let question {
            messages = [.init(role: .user, text: question), .init(role: .assistant, text: "An answer.")]
        }
        return Chat(messages: messages, topic: question, updated: Date())
    }

    func testHistoryKeepsTheLastTwoNewestFirst() {
        var recents: [Chat] = []
        for name in ["first", "second", "third"] {
            recents = AskAIConversation.filing(chat(name), into: recents)
        }
        XCTAssertEqual(recents.map(\.title), ["third", "second"])
    }

    func testAnEmptyConversationIsNotFiledAndAReopenedOneIsNotListedTwice() {
        let kept = chat("zakat")
        var recents = AskAIConversation.filing(kept, into: [])
        recents = AskAIConversation.filing(chat(nil), into: recents)
        XCTAssertEqual(recents.map(\.title), ["zakat"])
        // Reopened (the same identity), added to, and set aside again: one row, its newer form.
        var grown = kept
        grown.messages.append(.init(role: .user, text: "how much is it?"))
        recents = AskAIConversation.filing(chat("wudu"), into: recents)
        recents = AskAIConversation.filing(grown, into: recents)
        XCTAssertEqual(recents.map(\.title), ["zakat", "wudu"])
        XCTAssertEqual(recents[0].messages.count, 3)
    }

    func testASavedHistoryReadsBackAndAnOlderTranscriptStillOpens() throws {
        let saved = chat("What is sabr?")
        let decoded = try JSONDecoder().decode(Chat.self, from: JSONEncoder().encode(saved))
        XCTAssertEqual(decoded.id, saved.id)
        XCTAssertEqual(decoded.title, "What is sabr?")
        XCTAssertEqual(decoded.messages.count, 2)
        // One broken message drops alone.
        let damaged = #"{"messages":[{"role":"user","text":"What is sabr?"},{"role":"nobody"}],"topic":"sabr"}"#
        let read = try JSONDecoder().decode(Chat.self, from: Data(damaged.utf8))
        XCTAssertEqual(read.messages.count, 1)
        XCTAssertEqual(read.topic, "sabr")
    }
}
