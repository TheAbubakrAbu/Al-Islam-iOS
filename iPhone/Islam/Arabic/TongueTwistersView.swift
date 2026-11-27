#if os(iOS)
import SwiftUI

// MARK: - Tongue twisters

// Abu, 2026-11-17, sharing a reel of لَقَدۡ شَقۡشَقَ ٱلشَّوۡقُ شَوۡقِي: "could be a fun exercise to put in
// tajweed or arabic and also if u could come up with other ones too (add tashkeel and everything)".
//
// Four groups: the two lines the books of eloquence cite for letters that clash (tanaafur), two
// well-known ones (the reel's, and khaytu Hareerin), one written for this page per Sound-Alikes pair,
// and four Quran phrases known for being hard on the tongue, cut by token from the app's own Hafs text.
//
// The Arabic is written the way every teaching example in the app is (Islamic content standards): the
// Uthmani sukoon ۡ, ٱ on the article, the sun letters' lam bare, a noon of ikhfaa left bare, and the
// Hafs madd and alif maqSoorah spellings (ىٰ, ىٰٓ before a hamza, ٓ on a madd before a hamza). Full
// case endings throughout, except the reel's lines, which pause (لَكۡ، شَوۡقِكۡ) as it is said.

/// One tongue twister: its lines of Arabic, how it is read, what it means, and the letters it drills.
struct TongueTwister: Identifiable {
    enum Group: CaseIterable {
        case classical, wellKnown, letterPairs
    }

    let id: String
    let group: Group
    /// The lines as they are said, right to left, one `Text` each.
    let lines: [String]
    /// The app's reading convention: capitals for the heavy letters and Haa (S D T Dh H), doubled long
    /// vowels, ' for 'ayn and ’ for a hamza inside a word.
    let reading: String
    let meaning: String
    /// The letters it puts side by side, shown as chips.
    let letters: [String]
    var note: String? = nil

    /// What the voice reads: the lines, each its own breath.
    var spoken: String { lines.joined(separator: "\n") }
}

enum TongueTwisters {
    static let all: [TongueTwister] = [
        // The books of balagha, for letters that clash.
        TongueTwister(
            id: "qabruHarb", group: .classical,
            lines: ["وَقَبۡرُ حَرۡبٍ بِمَكَانٍ قَفۡرٍ", "وَلَيۡسَ قُرۡبَ قَبۡرِ حَرۡبٍ قَبۡرُ"],
            reading: "wa qabru Harbin bimakaanin qafrin, wa laysa qurba qabri Harbin qabru",
            meaning: String(localized: "Harb’s grave is in a barren place, and there is no grave near Harb’s grave."),
            letters: ["ق", "ب", "ر"],
            note: String(localized: "Al-Jaahiz quotes this line in al-Bayaan wat-Tabyeen as words whose letters clash: hardly anyone can say it three times in a row without stumbling. The books of balagha still use it to teach tanaafur.")),
        TongueTwister(
            id: "amdaHhu", group: .classical,
            lines: ["كَرِيمٌ مَتَىٰٓ أَمۡدَحۡهُ أَمۡدَحۡهُ وَٱلۡوَرَىٰ", "مَعِي، وَإِذَا مَا لُمۡتُهُ لُمۡتُهُ وَحۡدِي"],
            reading: "kareemun mataa amdaHhu amdaHhu wal-waraa ma'ee, wa idhaa maa lumtuhu lumtuhu waHdee",
            meaning: String(localized: "A generous man: whenever I praise him, all people praise him with me, and whenever I blame him, I blame him alone."),
            letters: ["ح", "ه"],
            note: String(localized: "A line of Abu Tammaam’s. The books of balagha cite it because amdaHhu amdaHhu puts Haa against haa twice, two throat letters back to back.")),

        // Well known.
        TongueTwister(
            id: "shawq", group: .wellKnown,
            lines: [
                "لَقَدۡ شَقۡشَقَ ٱلشَّوۡقُ شَوۡقِي فَشَاقَ شَوۡقِي لَكۡ",
                "فَهَلۡ شَقۡشَقَ ٱلشَّوۡقُ شَوۡقَكۡ، كَشَوۡقِ شَوۡقِي لِشَوۡقِكۡ؟",
                "وَإِن شَقۡشَقَ ٱلشَّوۡقُ شَوۡقَكَ كَشَوۡقِي",
                "فَشَوۡقِيٓ أَشَقُّ شَوۡقًا مِن شَوۡقِكۡ!",
            ],
            reading: "laqad shaqshaqash-shawqu shawqee fashaaqa shawqee lak, fahal shaqshaqash-shawqu shawqak, kashawqi shawqee lishawqik? wa in shaqshaqash-shawqu shawqaka kashawqee, fashawqee ashaqqu shawqan min shawqik!",
            meaning: String(localized: "Longing has stirred my longing, so my longing longs for you. Has longing stirred your longing the way my longing longs for yours? And if longing has stirred your longing as it stirred mine, my longing is still the stronger longing!"),
            letters: ["ش", "ق"],
            note: String(localized: "Shaqshaqa is the roar of a camel that has been stirred up; here, longing stirring longing. Sheen and qaaf in almost every word.")),
        TongueTwister(
            id: "khayTHareer", group: .wellKnown,
            lines: ["خَيۡطُ حَرِيرٍ عَلَىٰ حَآئِطِ خَلِيلٍ"],
            reading: "khayTu Hareerin 'alaa Haa’iTi khaleelin",
            meaning: String(localized: "A silk thread on Khaleel’s wall."),
            letters: ["خ", "ح", "ط"],
            note: String(localized: "Usually said in its spoken form, with حيط for wall. Khaa and Haa take turns all the way through.")),

        // One per Sound-Alikes pair, written for this page.
        TongueTwister(
            id: "seenSaad", group: .letterPairs,
            lines: ["سَامِرٌ صَادَ سَمَكَةً صَغِيرَةً، وَصَالِحٌ صَادَ سَمَكَتَيۡنِ سَمِينَتَيۡنِ"],
            reading: "saamirun Saada samakatan Sagheeratan, wa SaaliHun Saada samakatayni sameenatayni",
            meaning: String(localized: "Saamir caught a small fish, and Saalih caught two fat fish."),
            letters: ["س", "ص"],
            note: String(localized: "Seen is light and Saad is heavy: for Saad, raise the back of the tongue toward the roof of the mouth so the sound fills it.")),
        TongueTwister(
            id: "taaTaa", group: .letterPairs,
            lines: ["تُوتُ طَارِقٍ طَرِيٌّ، وَتُوتُ تَامِرٍ طَيِّبٌ"],
            reading: "tootu Taariqin Tariyyun, wa tootu taamirin Tayyibun",
            meaning: String(localized: "Taariq’s mulberries are fresh, and Taamir’s mulberries are good."),
            letters: ["ت", "ط"],
            note: String(localized: "The same spot behind the teeth for both: ت is light, ط fills the mouth.")),
        TongueTwister(
            id: "daalDaad", group: .letterPairs,
            lines: ["ضَلَّ ضَبُّ دُرَيۡدٍ، فَدَلَّ ضِيَآءٌ ضَبَّ دُرَيۡدٍ"],
            reading: "Dalla Dabbu duraydin, fadalla Diyaa’un Dabba duraydin",
            meaning: String(localized: "Durayd’s lizard got lost, so Diyaa showed Durayd’s lizard the way."),
            letters: ["د", "ض"],
            note: String(localized: "ضَلَّ is to get lost and دَلَّ to show the way: one letter apart. د taps the tip of the tongue behind the teeth; ض presses the side of the tongue against the upper molars.")),
        TongueTwister(
            id: "dhaalDhaaZaay", group: .letterPairs,
            lines: ["ظَنَّ زَيۡدٌ أَنَّ ٱلذِّئۡبَ ظَبۡيٌ، فَذَهَبَ زَيۡدٌ يَزُورُ ٱلذِّئۡبَ"],
            reading: "Dhanna zaydun annadh-dhi’ba Dhabyun, fadhahaba zaydun yazoorudh-dhi’ba",
            meaning: String(localized: "Zayd thought the wolf was a gazelle, so Zayd went to visit the wolf."),
            letters: ["ذ", "ظ", "ز"],
            note: String(localized: "ذ and ظ put the tip of the tongue on the edge of the upper teeth, ظ heavy and ذ light; ز hisses just behind them.")),
        TongueTwister(
            id: "DaadDhaa", group: .letterPairs,
            lines: ["ظَلَّ ضَيۡفُ ظَافِرٍ ضَاحِكًا ظُهۡرًا، وَظَلَّ ظَافِرٌ ضَجِرًا"],
            reading: "Dhalla Dayfu Dhaafirin DaaHikan Dhuhran, wa Dhalla Dhaafirun Dajiran",
            meaning: String(localized: "Dhaafir’s guest kept laughing at noon, and Dhaafir stayed annoyed."),
            letters: ["ض", "ظ"],
            note: String(localized: "Both are heavy, and many people say them as one sound. ض is the side of the tongue on the molars, ظ the tip of the tongue on the edge of the teeth.")),
        TongueTwister(
            id: "qaafKaaf", group: .letterPairs,
            lines: ["قَلۡبُ كَلۡبِ قَاسِمٍ كَقَلۡبِ كَلۡبِ كَامِلٍ"],
            reading: "qalbu kalbi qaasimin kaqalbi kalbi kaamilin",
            meaning: String(localized: "The heart of Qaasim’s dog is like the heart of Kaamil’s dog."),
            letters: ["ق", "ك"],
            note: String(localized: "قَلۡب and كَلۡب are the same letters with one swapped. ق is made at the very back of the tongue, ك a little further forward.")),
        TongueTwister(
            id: "thaaSeen", group: .letterPairs,
            lines: ["شَرِبَ ثَامِرٌ ثُلُثَ ٱلشَّايِ، وَشَرِبَ سَامِرٌ ثُلُثَيۡهِ"],
            reading: "shariba thaamirun thuluthash-shaayi, wa shariba saamirun thuluthayhi",
            meaning: String(localized: "Thaamir drank a third of the tea, and Saamir drank two thirds of it."),
            letters: ["ث", "س", "ش"],
            note: String(localized: "ث puts the tongue between the teeth; س and ش hiss and hush behind them. A ث said as a س changes the word.")),
        TongueTwister(
            id: "throat", group: .letterPairs,
            lines: ["عَهِدَ أَحۡمَدُ إِلَىٰ حَامِدٍ عَهۡدًا، فَحَفِظَ حَامِدٌ عَهۡدَ أَحۡمَدَ"],
            reading: "'ahida aHmadu ilaa Haamidin 'ahdan, faHafiDha Haamidun 'ahda aHmada",
            meaning: String(localized: "Ahmad entrusted Haamid with a pledge, and Haamid kept Ahmad’s pledge."),
            letters: ["ع", "ح", "ه"],
            note: String(localized: "All three come from the throat: ه from its deepest part, ع and ح from the middle. Give each its own sound.")),
        TongueTwister(
            id: "khaaGhayn", group: .letterPairs,
            lines: ["غَرَسَ خَالِدٌ خَوۡخًا، وَغَرَسَ غَانِمٌ خَرُّوبًا"],
            reading: "gharasa khaalidun khawkhan, wa gharasa ghaanimun kharrooban",
            meaning: String(localized: "Khaalid planted peaches, and Ghaanim planted carob."),
            letters: ["خ", "غ"],
            note: String(localized: "Both come from the top of the throat: خ is the breathy scrape, غ the voiced gargle.")),
        TongueTwister(
            id: "hamzaAyn", group: .letterPairs,
            lines: ["أَعۡطَىٰ عَلِيٌّ أَمِينًا عَسَلًا، وَأَعۡطَىٰٓ أَمِينٌ عَلِيًّا أَرُزًّا"],
            reading: "a'Taa 'aliyyun ameenan 'asalan, wa a'Taa ameenun 'aliyyan aruzzan",
            meaning: String(localized: "Ali gave Ameen honey, and Ameen gave Ali rice."),
            letters: ["ء", "ع"],
            note: String(localized: "A hamza is a clean catch in the throat; an ’ayn is a squeeze. Do not let the ’ayn fade into a hamza.")),
    ]

    static func twisters(in group: TongueTwister.Group) -> [TongueTwister] {
        all.filter { $0.group == group }
    }
}

#if HAS_QURAN
/// A Quran phrase that is hard on the tongue, cut by TOKEN from the app's own Hafs text (never typed
/// here), so it is the mushaf's spelling exactly.
struct QuranTongueTwister: Identifiable {
    let id: String
    let surah: Int
    let ayah: Int
    /// Token indices in the ayah's Hafs text.
    let words: ClosedRange<Int>
    let reading: String
    let meaning: String
    let note: String

    /// The words, waqf signs trimmed off the end; nil before the Quran has loaded.
    var arabic: String? {
        guard let ayah = QuranData.shared.ayah(surah: surah, ayah: ayah) else { return nil }
        let tokens = WordTokens.tokens(in: ayah.rawArabicText(surahId: surah, qiraahOverride: Settings.Riwayah.hafsTag))
        guard tokens.indices.contains(words.lowerBound), tokens.indices.contains(words.upperBound) else { return nil }
        let phrase = tokens[words].joined(separator: " ")
        return phrase.trimmingCharacters(in: Self.pauseMarks.union(.whitespaces))
    }

    /// The small waqf signs printed over a word's end (ۖ through ۜ).
    private static let pauseMarks = CharacterSet(charactersIn: "\u{06D6}\u{06D7}\u{06D8}\u{06D9}\u{06DA}\u{06DB}\u{06DC}")

    static let all: [QuranTongueTwister] = [
        QuranTongueTwister(
            id: "hud48", surah: 11, ayah: 48, words: 7...10,
            reading: "wa 'alaa umamim mimmam ma'ak",
            meaning: String(localized: "and on nations from among those with you"),
            note: String(localized: "Eight meem sounds in a row: the tanween and both noons merge into the meem after them, each with ghunnah.")),
        QuranTongueTwister(
            id: "hijr22", surah: 15, ayah: 22, words: 7...7,
            reading: "fa-asqaynaakumoohu",
            meaning: String(localized: "and We gave it to you to drink"),
            note: String(localized: "A whole sentence in one word: fa (and), asqaynaa (We gave to drink), kum (you), hu (it). Give every syllable its full length.")),
        QuranTongueTwister(
            id: "hud28", surah: 11, ayah: 28, words: 15...15,
            reading: "anulzimukumoohaa",
            meaning: String(localized: "should we force it upon you"),
            note: String(localized: "A question, a verb and two pronouns in one word. Keep the laam’s sukoon clean and do not rush the end.")),
        QuranTongueTwister(
            id: "baqarah137", surah: 2, ayah: 137, words: 14...15,
            reading: "fasayakfeekahumullaah",
            meaning: String(localized: "Allah will be enough for you against them"),
            note: String(localized: "Kaaf after kaaf, then haa: the letters of a long word crowd together before the name of Allah.")),
    ]
}
#endif

// MARK: - The page

struct TongueTwistersView: View {
    @Environment(\.appearance) private var appearance
    @ObservedObject private var islamSettings = IslamSettings.shared
    @State private var barsCollapsed = false

    /// The link row's specimen.
    static let specimen = "شَقۡشَقَ"

    var body: some View {
        List {
            Group {
                Section {
                    ArticleLead(String(localized: "Say each one slowly, then faster, then three times in a row without a slip. Every line packs letters that sit close together in the mouth, so where you stumble shows you which pair needs work."), eyebrow: String(localized: "IN SHORT"))
                } footer: {
                    Text("Tap Slow to hear it first, then Fast to hear the speed to aim for.")
                }

                twisterSection(.classical, header: String(localized: "FROM THE BOOKS OF BALAAGHA"),
                               footer: String(localized: "Balaagha, the study of eloquence, names it tanaafur when letters clash. These are its two classic examples."))
                twisterSection(.wellKnown, header: String(localized: "WELL KNOWN"), footer: nil)
                twisterSection(.letterPairs, header: String(localized: "LETTER PAIRS"),
                               footer: String(localized: "Written for this page, one for each pair on Sound-Alikes."), linksSoundAlikes: true)

                #if HAS_QURAN
                quranSection
                #endif
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Tongue Twisters")
        .onDisappear { ArabicSpeech.shared.stop() }
        // The Arabic follows the alphabet's size slider, like every page of the Arabic Alphabet.
        .collapseBarsOnScroll($barsCollapsed)
        .adaptiveSafeArea(edge: .bottom) {
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                ArabicSizeSlider()
            }
            .minimizedBarStyle(barsCollapsed)
            .padding(.horizontal, 24)
            .padding(.bottom, BottomBarCushion.standard)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HideEnglishToolbarButton()
            }
        }
    }

    private func twisterSection(_ group: TongueTwister.Group, header: String, footer: String?, linksSoundAlikes: Bool = false) -> some View {
        Section {
            ForEach(TongueTwisters.twisters(in: group)) { twister in
                TongueTwisterRow(
                    lines: twister.lines,
                    face: .islam,
                    reading: twister.reading,
                    meaning: twister.meaning,
                    letters: twister.letters,
                    note: twister.note,
                    spoken: twister.spoken,
                    letterSizeSteps: islamSettings.arabicLetterSizeIndex,
                    hideReading: islamSettings.hideEnglishInArabicLetters
                )
            }

            if linksSoundAlikes {
                NavigationLink(destination: LazyDestination { SoundAlikeLettersView() }) {
                    ArabicTopicLinkLabel(specimen: ArabicTopicCatalog.soundAlikes.specimen,
                                         title: ArabicTopicCatalog.soundAlikes.title,
                                         caption: ArabicTopicCatalog.soundAlikes.caption)
                }
                .tint(appearance.accent)
            }
        } header: {
            Text(header)
        } footer: {
            if let footer { Text(footer) }
        }
    }

    #if HAS_QURAN
    private var quranSection: some View {
        Section {
            // The phrase's text is found HERE, not by an `if let` in the row: a row that may be
            // nothing is one the List has to build to count (see `OneRow`).
            let found = QuranTongueTwister.all.compactMap { phrase in
                phrase.arabic.map { (phrase: phrase, arabic: $0) }
            }
            ForEach(found, id: \.phrase.id) { match in
                let phrase = match.phrase
                TongueTwisterRow(
                    lines: [match.arabic],
                    face: .quran,
                    reading: phrase.reading,
                    meaning: phrase.meaning,
                    letters: [],
                    reference: "\(QuranData.shared.surah(phrase.surah)?.displayName ?? "") \(phrase.surah):\(phrase.ayah)".localizedDigits,
                    note: phrase.note,
                    spoken: match.arabic,
                    letterSizeSteps: islamSettings.arabicLetterSizeIndex,
                    hideReading: islamSettings.hideEnglishInArabicLetters
                )
            }
        } header: {
            Text("FROM THE QURAN")
        } footer: {
            Text("Phrases known for being hard on the tongue, in the mushaf’s own spelling. Recite them with their tajweed, not at speed.")
        }
    }
    #endif
}

/// One twister: the letters it drills and its listen chips, the Arabic, how it is read, what it
/// means, and a note.
private struct TongueTwisterRow: View {
    @Environment(\.appearance) private var appearance

    enum Face { case islam, quran }

    let lines: [String]
    let face: Face
    let reading: String
    let meaning: String
    let letters: [String]
    /// "Hud 11:48", for a Quran phrase.
    var reference: String? = nil
    let note: String?
    let spoken: String
    let letterSizeSteps: Int
    let hideReading: Bool

    private var arabicFont: Font {
        switch face {
        case .islam:
            return appearance.useFontArabic ? appearance.islamArabicFont(base: 24, relativeTo: .title2) : .title2
        case .quran:
            return appearance.quranArabicFont(size: 28, relativeTo: .title2)
        }
    }

    private var customFace: Bool {
        switch face {
        case .islam: return appearance.useFontArabic && appearance.islamUsesCustomArabicFace
        case .quran: return appearance.quranUsesCustomArabicFace
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                if let reference {
                    Text(reference)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(appearance.accent)
                }
                ForEach(letters, id: \.self) { letter in
                    // The plain system face for a lone letter, as on Vowel Letters: the mushaf faces'
                    // tall line box sat the letter low in its chip.
                    Text(letter)
                        .font(.body.weight(.semibold))
                        .foregroundColor(appearance.accent)
                        .frame(minWidth: 30, minHeight: 28)
                        .background(Capsule().fill(appearance.accent.opacity(0.12)))
                        .accessibilityHidden(true)
                }

                Spacer(minLength: 8)

                TwisterListenButtons(text: spoken)
            }

            VStack(alignment: .trailing, spacing: 6) {
                ForEach(lines, id: \.self) { line in
                    Text(line)
                        .font(arabicFont)
                        .arabicFontDesign(custom: customFace)
                        .arabicLetterTypeFloor(steps: letterSizeSteps)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            // Arabic keeps the right edge: in the Arabic interface `.trailing` is the left.
            .environment(\.layoutDirection, .leftToRight)
            .textSelection(.enabled)

            VStack(alignment: .leading, spacing: 4) {
                if !hideReading {
                    Text(reading)
                        .font(.footnote.italic())
                        .foregroundColor(.secondary)
                        .leftToRightContent(true)
                }
                Text(meaning)
                    .font(.subheadline)
                if let note {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .contain)
    }
}

/// Slow and Fast: the twister read at a learner's pace, then at the pace to aim for. The chip that is
/// playing turns into Stop. Nothing at all without an Arabic voice.
private struct TwisterListenButtons: View {
    @ObservedObject private var speech = ArabicSpeech.shared
    let text: String
    @State private var playing: Speed?

    enum Speed: CaseIterable {
        case slow, fast

        var rate: Float { self == .slow ? 0.3 : 0.55 }
        var symbol: String { self == .slow ? "tortoise.fill" : "hare.fill" }
        var title: String { self == .slow ? String(localized: "Slow") : String(localized: "Fast") }
    }

    var body: some View {
        ArabicVoiceGate {
            HStack(spacing: 6) {
                ForEach(Speed.allCases, id: \.self) { speed in
                    let isPlaying = playing == speed && speech.currentText == text
                    Button {
                        Settings.shared.hapticFeedback()
                        if isPlaying {
                            speech.stop()
                            playing = nil
                        } else {
                            playing = speed
                            speech.speak(text, rate: speed.rate)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isPlaying ? "stop.fill" : speed.symbol)
                            Text(isPlaying ? String(localized: "Stop") : speed.title)
                        }
                    }
                    .accessibilityLabel(isPlaying ? String(localized: "Stop") : speed.title)
                    .buttonStyle(.accentChip(filled: isPlaying))
                }
            }
            // The chips are controls, not text: never mirrored in the Arabic interface.
            .environment(\.layoutDirection, .leftToRight)
        }
    }
}
#endif
