import SwiftUI

struct CommonDhikr: Identifiable {
    let arabicText: String
    let transliteration: String
    let translation: String
    /// Where the words come from, in the dua rows' house style ("Bukhari 6405; Muslim 2691", "Tirmidhi
    /// 3383, hasan"): sahih or hasan only, with the grading named outside the two Sahihs.
    let source: String?
    let searchBlob: String

    var id: String { transliteration }

    init(arabicText: String, transliteration: String, translation: String, source: String? = nil) {
        self.arabicText = arabicText
        self.transliteration = transliteration
        self.translation = translation
        self.source = source
        self.searchBlob = Self.searchBlob(arabicText: arabicText, transliteration: transliteration, translation: translation,
                                          source: source)
    }

    private static func searchBlob(arabicText: String, transliteration: String, translation: String, source: String?) -> String {
        [arabicText, transliteration, translation, source ?? ""]
            .joined(separator: " ")
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}

/// The remembrances, in a FIXED order: the Tasbih Counter keeps each preset's count by its index in
/// this list (`TasbihCounters`), so a new dhikr is only ever appended, never inserted or reordered.
/// The second group (Abu, 2026-11-24: "More dhikr") is the Sunnah's best-known remembrances, each
/// from a sahih or hasan narration, spelled in the same style as the first nine.
let commonDhikrItems: [CommonDhikr] = [
    CommonDhikr(arabicText: "سُبحَانَ اللَّهِ", transliteration: "SubhaanAllah", translation: "Glory be to Allah",
                source: "Muslim 2698"),
    CommonDhikr(arabicText: "ٱلحَمدُ لِلَّهِ", transliteration: "Alhamdulillah", translation: "Praise be to Allah",
                source: "Muslim 223"),
    CommonDhikr(arabicText: "اللَّهُ أَكبَرُ", transliteration: "Allahu Akbar", translation: "Allah is the Greatest",
                source: "Muslim 597"),
    CommonDhikr(arabicText: "لَا إِلَٰهَ إِلَّا اللَّهُ", transliteration: "La ilaaha illallah", translation: "There is no deity worthy of worship except Allah",
                source: "Tirmidhi 3383, hasan"),
    CommonDhikr(arabicText: "أَستَغفِرُ اللَّهَ", transliteration: "Astaghfirullah", translation: "I seek forgiveness from Allah",
                source: "Muslim 591"),
    CommonDhikr(arabicText: "لَا حَولَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ", transliteration: "La hawla wala quwwata illa billah", translation: "There is no power or might except with Allah",
                source: "Bukhaari 6384; Muslim 2704"),
    CommonDhikr(arabicText: "سُبحَانَ اللَّهِ وَبِحَمدِهِ سُبحَانَ اللَّهِ العَظِيمِ", transliteration: "SubhaanAllahi wa bihamdihi, SubhaanAllahil-‘Azeem", translation: "Glory be to Allah and praise be to Him; Glory be to Allah, the Most Great",
                source: "Bukhaari 6682; Muslim 2694"),
    CommonDhikr(arabicText: "اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ", transliteration: "Allahumma salli ‘ala Muhammad wa ‘ala aali Muhammad", translation: "O Allah, send blessings upon Muhammad and his family",
                source: "Bukhaari 3370"),
    CommonDhikr(arabicText: "لَا إِلَٰهَ إِلَّا اللَّهُ وَحدَهُ لَا شَرِيكَ لَهُ لَهُ ٱلمُلكُ وَلَهُ ٱلحَمدُ وَهُوَ عَلَىٰ كُلِّ شَيءٍ قَدِيرٌ", transliteration: "La ilaaha illallah wahdahu la shareeka lah, lahul-mulk wa lahul-hamd, wa huwa ‘ala kulli shay’in qadeer", translation: "There is no deity worthy of worship except Allah, alone, without any partner. His is the sovereignty and His is the praise, and He is capable of all things",
                source: "Bukhaari 6403; Muslim 2691"),
    // 2026-11-24: appended (the order above is the Tasbih Counter's key).
    CommonDhikr(arabicText: "سُبحَانَ اللَّهِ وَبِحَمدِهِ", transliteration: "SubhaanAllahi wa bihamdihi", translation: "Glory be to Allah and praise be to Him",
                source: "Bukhaari 6405; Muslim 2691"),
    CommonDhikr(arabicText: "سُبحَانَ اللَّهِ، وَالحَمدُ لِلَّهِ، وَلَا إِلَٰهَ إِلَّا اللَّهُ، وَاللَّهُ أَكبَرُ", transliteration: "SubhaanAllah, walhamdulillah, wa la ilaaha illallah, wallahu akbar", translation: "Glory be to Allah, praise be to Allah, there is no deity worthy of worship except Allah, and Allah is the Greatest",
                source: "Muslim 2137"),
    CommonDhikr(arabicText: "سُبحَانَ اللَّهِ وَبِحَمدِهِ، عَدَدَ خَلقِهِ، وَرِضَا نَفسِهِ، وَزِنَةَ عَرشِهِ، وَمِدَادَ كَلِمَاتِهِ", transliteration: "SubhaanAllahi wa bihamdihi, ‘adada khalqihi, wa rida nafsihi, wa zinata ‘arshihi, wa midaada kalimaatihi", translation: "Glory be to Allah and praise be to Him, as many times as the number of His creation, as much as pleases Him, as much as the weight of His Throne, and as much as the ink of His words",
                source: "Muslim 2726"),
    CommonDhikr(arabicText: "أَستَغفِرُ اللَّهَ وَأَتُوبُ إِلَيهِ", transliteration: "Astaghfirullaha wa atoobu ilayh", translation: "I seek the forgiveness of Allah and turn to Him in repentance",
                source: "Bukhaari 6307"),
    CommonDhikr(arabicText: "سُبحَانَ اللَّهِ وَبِحَمدِهِ، أَستَغفِرُ اللَّهَ وَأَتُوبُ إِلَيهِ", transliteration: "SubhaanAllahi wa bihamdihi, astaghfirullaha wa atoobu ilayh", translation: "Glory be to Allah and praise be to Him; I seek the forgiveness of Allah and turn to Him in repentance",
                source: "Muslim 484"),
    CommonDhikr(arabicText: "رَبِّ اغفِر لِي وَتُب عَلَيَّ، إِنَّكَ أَنتَ التَّوَّابُ الرَّحِيمُ", transliteration: "Rabbighfir li wa tub ‘alayya, innaka antat-Tawwaabur-Raheem", translation: "My Lord, forgive me and accept my repentance; indeed, You are the Accepter of repentance, the Most Merciful",
                source: "Abu Daawood 1516, saheeh"),
    CommonDhikr(arabicText: "لَا إِلَٰهَ إِلَّا أَنتَ سُبحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ", transliteration: "La ilaaha illa anta subhaanaka inni kuntu minaz-zaalimeen", translation: "There is no deity except You; glory be to You. Indeed, I have been of the wrongdoers",
                source: "Quran 21:87; Tirmidhi 3505, saheeh"),
    CommonDhikr(arabicText: "حَسبُنَا اللَّهُ وَنِعمَ الوَكِيلُ", transliteration: "Hasbunallahu wa ni‘mal-wakeel", translation: "Allah is sufficient for us, and He is the best Disposer of affairs",
                source: "Quran 3:173; Bukhaari 4563"),
    CommonDhikr(arabicText: "رَضِيتُ بِاللَّهِ رَبًّا، وَبِالإِسلَامِ دِينًا، وَبِمُحَمَّدٍ رَسُولًا", transliteration: "Radeetu billahi rabban, wa bil-Islaami deenan, wa bi-Muhammadin rasoola", translation: "I am pleased with Allah as my Lord, with Islam as my religion, and with Muhammad as Messenger",
                source: "Abu Daawood 1529, saheeh; Muslim 1884"),
    CommonDhikr(arabicText: "سُبحَانَ اللَّهِ العَظِيمِ وَبِحَمدِهِ", transliteration: "SubhaanAllahil-‘Azeemi wa bihamdihi", translation: "Glory be to Allah, the Most Great, and praise be to Him",
                source: "Tirmidhi 3464, saheeh"),
    CommonDhikr(arabicText: "الحَمدُ لِلَّهِ حَمدًا كَثِيرًا طَيِّبًا مُبَارَكًا فِيهِ", transliteration: "Alhamdulillahi hamdan katheeran tayyiban mubaarakan feeh", translation: "Praise be to Allah, abundant, good and blessed praise",
                source: "Bukhaari 799"),
    CommonDhikr(arabicText: "اللَّهُ أَكبَرُ كَبِيرًا، وَالحَمدُ لِلَّهِ كَثِيرًا، وَسُبحَانَ اللَّهِ بُكرَةً وَأَصِيلًا", transliteration: "Allahu akbaru kabeera, walhamdulillahi katheera, wa subhaanallahi bukratan wa aseela", translation: "Allah is the Greatest, truly great; abundant praise be to Allah; and glory be to Allah, morning and evening",
                source: "Muslim 601"),
    CommonDhikr(arabicText: "سُبحَانَ المَلِكِ القُدُّوسِ", transliteration: "Subhaanal-Malikil-Quddoos", translation: "Glory be to the King, the Most Holy",
                source: "Abu Daawood 1430, saheeh"),
    CommonDhikr(arabicText: "سُبحَانَكَ اللَّهُمَّ وَبِحَمدِكَ، أَشهَدُ أَن لَا إِلَٰهَ إِلَّا أَنتَ، أَستَغفِرُكَ وَأَتُوبُ إِلَيكَ", transliteration: "Subhaanakallahumma wa bihamdika, ashhadu an la ilaaha illa anta, astaghfiruka wa atoobu ilayk", translation: "Glory be to You, O Allah, and praise be to You. I bear witness that there is no deity worthy of worship except You. I seek Your forgiveness and turn to You in repentance",
                source: "Tirmidhi 3433, saheeh"),
    CommonDhikr(arabicText: "اللَّهُمَّ أَعِنِّي عَلَىٰ ذِكرِكَ وَشُكرِكَ وَحُسنِ عِبَادَتِكَ", transliteration: "Allahumma a‘inni ‘ala dhikrika wa shukrika wa husni ‘ibaadatik", translation: "O Allah, help me to remember You, to thank You, and to worship You well",
                source: "Abu Daawood 1522, saheeh"),
    CommonDhikr(arabicText: "بِسمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسمِهِ شَيءٌ فِي الأَرضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ العَلِيمُ", transliteration: "Bismillahil-ladhi la yadurru ma‘asmihi shay’un fil-ardi wa la fis-samaa’i, wa huwas-Samee‘ul-‘Aleem", translation: "In the name of Allah, with whose name nothing on earth or in the heavens can cause harm, and He is the All-Hearing, the All-Knowing",
                source: "Abu Daawood 5088; Tirmidhi 3388, hasan saheeh"),
    CommonDhikr(arabicText: "أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِن شَرِّ مَا خَلَقَ", transliteration: "A‘oodhu bikalimaatillahit-taammaati min sharri ma khalaq", translation: "I seek refuge in the perfect words of Allah from the evil of what He has created",
                source: "Muslim 2708"),
]

/// Measured height of the Arabic block, so a dhikr can decide for itself how to sit on the row.
private struct ArabicBlockHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

/// Height of ONE line in the same font, for comparison.
private struct ArabicLineHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

/// The soft accent wash behind the row being read aloud. Its OWN view because it is the only per-row
/// piece that tracks the speech queue: when AdhkarRow itself observed `ArabicSpeech`, every queue
/// advance during Listen All re-ran every row's body (re-folding all its highlight fields). Now a
/// queue advance re-renders just these washes and the Listen buttons.
///
/// On the phone it is the row's whole cell, the `rowWash` fill (Abu, 2026-10-09: every highlight
/// takes up the full row); the watch keeps its band behind the text.
private struct SpokenRowWash: View {
    @ObservedObject private var speech = ArabicSpeech.shared
    let text: String
    let color: Color

    var body: some View {
        let active = speech.currentText == text
        #if os(iOS)
        RowWashBackground(wash: active ? color.opacity(0.12) : nil, fade: 0.25)
        #else
        RoundedRectangle(cornerRadius: 12)
            .fill(active ? color.opacity(0.12) : .clear)
            .padding(.horizontal, -10)
            .padding(.vertical, -2)
            .animation(.easeInOut(duration: 0.25), value: active)
        #endif
    }
}

extension View {
    /// The phone's spoken-row wash: the row being read aloud wears the accent over its whole cell
    /// (`SpokenRowWash`). Apply it where the List holds the row, after `.equatable()`: from inside
    /// `AdhkarRow`'s body a cell background never reaches the List.
    func spokenRowWash(_ arabicText: String) -> some View {
        modifier(SpokenRowWashModifier(text: arabicText))
    }
}

/// See `spokenRowWash`.
private struct SpokenRowWashModifier: ViewModifier {
    @Environment(\.appearance) private var appearance

    let text: String

    func body(content: Content) -> some View {
        #if os(iOS)
        content.listRowBackground(SpokenRowWash(text: text, color: appearance.accent))
        #else
        content
        #endif
    }
}

/// The Listen/Stop control - the other speech-reactive piece, split out for the same reason. Drawn
/// as a `ListenChipLabel`, the section header's Listen All pill's twin.
private struct AdhkarListenButton: View {
    private let settings = Settings.shared
    @ObservedObject private var speech = ArabicSpeech.shared
    let text: String

    var body: some View {
        let isBeingSpoken = speech.currentText == text
        Button {
            settings.hapticFeedback()
            if isBeingSpoken {
                speech.stop()
            } else {
                // speak() cuts off whatever else was playing - one voice at a time.
                speech.speak(text, rate: 0.4)
            }
        } label: {
            ListenChipLabel(title: isBeingSpoken ? String(localized: "Stop") : String(localized: "Listen"),
                            systemImage: isBeingSpoken ? "stop.fill" : "speaker.wave.2.fill",
                            active: isBeingSpoken)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isBeingSpoken ? String(localized: "Stop the recitation") : String(localized: "Hear the Arabic read aloud"))
    }
}

extension Settings {
    /// Every Settings field `AdhkarRow`'s body reads, folded into one compared input - the Islam-tab
    /// counterpart of `ayahRenderSettingsSignature`/`hadithRenderSettingsSignature`.
    var adhkarRenderSettingsSignature: String {
        [
            nonQuranArabicFontName,
            islamUsesCustomArabicFace ? "1" : "0",
            highlightAllahNamesIslam ? "1" : "0",
            accentColor.rawValue,
            customAccentColorHex
        ].joined(separator: "|")
    }
}

struct AdhkarRow: View, Equatable {
    @Environment(\.appearance) private var appearance
    /// The row's own direction, not the interface's: an article lays its rows out left to right.
    @Environment(\.layoutDirection) private var layoutDirection
    let arabicText: String
    let transliteration: String
    let translation: String
    var useQuranicFont: Bool = false
    var searchQuery: String = ""
    /// Duas are always trailing-aligned, even a one-liner: a dua is a quoted passage of Quran, and a Quranic
    /// line reads as Arabic prose, not as a UI label. A dhikr is a short phrase in a list of short phrases, so
    /// it stays leading until it actually wraps (which is what `arabicWraps` decides).
    var alwaysTrailing: Bool = false
    /// Shows a small "hear it" button that reads the Arabic aloud with the system's Arabic voice. There are
    /// no recordings for adhkar and duas, so this is synthesized - the same best-effort TTS the alphabet
    /// screens use; the button only appears when the device actually has an Arabic voice.
    var speechEnabled: Bool = false
    /// The citation ("Bukhari 6306", "Quran 3:8") shown on the bottom row, leading side - with the Listen
    /// button trailing on the same row.
    var source: String? = nil
    /// Captured at construction; see `Settings.adhkarRenderSettingsSignature`.
    var renderSettingsSignature: String = Settings.shared.adhkarRenderSettingsSignature
    /// The row's id in its list, so "Scroll To" can land on it. Nil on rows that are not scroll
    /// targets (the AI matches).
    var rowID: String? = nil
    /// "Scroll To ...": clears the search and scrolls the list to this row's home - its own place in
    /// the list, or its collection on the Duas root. Excluded from `==` (a closure; the row's CONTENT
    /// decides a redraw). Nil where the screen has nowhere to scroll to.
    var onScrollTo: (() -> Void)? = nil
    var scrollLabel: String = String(localized: "Scroll To Dhikr")

    /// The body lays out a full dhikr/dua (Arabic + transliteration + translation) and re-measures the
    /// Arabic's wrap - the expensive rows of the Adhkar and Dua screens, whose parents re-render on every
    /// Settings publish. The spoken-row wash and Listen button are child structs with their OWN speech
    /// subscriptions, so they keep updating during playback even while this body is skipped; the measured
    /// wrap heights are `@State`, which also bypasses `==`.
    static func == (l: Self, r: Self) -> Bool {
        l.arabicText == r.arabicText &&
        l.transliteration == r.transliteration &&
        l.translation == r.translation &&
        l.useQuranicFont == r.useQuranicFont &&
        l.searchQuery == r.searchQuery &&
        l.alwaysTrailing == r.alwaysTrailing &&
        l.speechEnabled == r.speechEnabled &&
        l.source == r.source &&
        l.renderSettingsSignature == r.renderSettingsSignature
    }

    /// The rendered height of the Arabic, and the height of a single line of it. A short dhikr ("سُبحَانَ اللَّهِ")
    /// is one line and reads best leading, like every other row on the screen; a long one wraps, and a wrapped
    /// Arabic paragraph has to be trailing-aligned or its ragged edge lands on the wrong side. So this is
    /// measured rather than declared per-screen - the same dhikr wraps or doesn't depending on the font size,
    /// the device, and Dynamic Type, and no hardcoded flag can know that.
    @State private var arabicHeight: CGFloat = 0
    @State private var arabicLineHeight: CGFloat = 0

    /// True once the Arabic has wrapped at all, i.e. it occupies more than one line.
    private var arabicWraps: Bool {
        guard arabicLineHeight > 0 else { return false }
        // A hair over one line's worth, so a single line doesn't flip on a rounding error.
        return arabicHeight > arabicLineHeight * 1.4
    }

    private var arabicFont: Font {
        useQuranicFont ? Font.arabic(appearance.islamArabicFontName, size: 30) : .title2
    }

    /// Whether `arabicFont` resolves to a bundled face, and so must opt out of the app-wide rounded design.
    private var usesCustomArabicFace: Bool {
        useQuranicFont && appearance.islamUsesCustomArabicFace
    }

    var body: some View {
        Section {
            rowContent
        }
    }

    /// Folded copies of the row fields, cached by source string. `matches` used to fold each FULL field
    /// (a dua can be a paragraph) on every body pass while a search was active - four fresh folds per
    /// visible row per keystroke. The fields are immutable content, so the fold is computed once ever.
    private static let foldedFieldCache = NSCache<NSString, NSString>()

    private static func folded(_ field: String) -> String {
        if let cached = foldedFieldCache.object(forKey: field as NSString) { return cached as String }
        let folded = field.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        foldedFieldCache.setObject(folded as NSString, forKey: field as NSString)
        return folded
    }

    private var rowContent: some View {
        // Guarantee a highlight only on the field(s) that actually contain the query (folded the same way the
        // dhikr search itself matches), so a match in one field doesn't force-color the other two.
        let normalizedQuery = searchQuery
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        func matches(_ field: String) -> Bool {
            guard !normalizedQuery.isEmpty else { return false }
            return Self.folded(field).contains(normalizedQuery)
        }
        // In a right-to-left interface the leading edge is already the right, where Arabic prose
        // sits wrapped or not; `.trailing` there would push it to the left.
        let trailing = (alwaysTrailing || arabicWraps) && layoutDirection == .leftToRight
        return VStack(alignment: .leading, spacing: 10) {
            HighlightedSnippet(
                source: arabicText,
                term: searchQuery,
                font: arabicFont,
                accent: appearance.accent,
                fg: appearance.accent,
                highlightAllahNames: appearance.highlightAllahIslam,
                guaranteeMatch: matches(arabicText)
            )
                .arabicFontDesign(custom: usesCustomArabicFace)
                // Only a block that actually wraps gets the trailing treatment; a one-liner stays leading, with
                // no multiline alignment at all (there's nothing to align).
                .multilineTextAlignment(trailing ? .trailing : .leading)
                .frame(maxWidth: .infinity, alignment: trailing ? .trailing : .leading)
                .padding(.vertical, useQuranicFont ? -8 : 0)
                // The two measurements exist to decide `arabicWraps`; a row that is trailing regardless
                // (every dua screen) never reads it, so it skips the two GeometryReaders, the yardstick and
                // the extra body pass their preferences cost (Phase 10.8).
                .background {
                    if !alwaysTrailing {
                        GeometryReader { geo in
                            Color.clear.preference(key: ArabicBlockHeightKey.self, value: geo.size.height)
                        }
                    }
                }
                // An invisible single line in the same face - the yardstick the block is measured against.
                .background {
                    if !alwaysTrailing {
                        Text("ب")
                            .font(arabicFont)
                            .arabicFontDesign(custom: usesCustomArabicFace)
                            .hidden()
                            .fixedSize()
                            .background(
                                GeometryReader { geo in
                                    Color.clear.preference(key: ArabicLineHeightKey.self, value: geo.size.height)
                                }
                            )
                    }
                }
                .onPreferenceChange(ArabicBlockHeightKey.self) { arabicHeight = $0 }
                .onPreferenceChange(ArabicLineHeightKey.self) { arabicLineHeight = $0 }

            HighlightedSnippet(
                source: transliteration,
                term: searchQuery,
                font: .subheadline,
                accent: appearance.accent,
                fg: .primary,
                guaranteeMatch: matches(transliteration)
            )
            .fixedSize(horizontal: false, vertical: true)
            .leftToRightContent()

            HighlightedSnippet(
                source: translation,
                term: searchQuery,
                font: .subheadline,
                accent: appearance.accent,
                fg: .secondary,
                highlightAllahNames: appearance.highlightAllahIslam,
                guaranteeMatch: matches(translation)
            )
            .fixedSize(horizontal: false, vertical: true)
            .leftToRightContent()

            // The bottom row: the citation sits leading, the Listen button trailing - one row, not two.
            // The button waits on the voice through `ArabicVoiceGate`: this row does not observe the
            // speech engine, and the voice resolves after the first rows draw, so a plain check here
            // left those rows with no Listen button. Without a citation, the gate holds the whole row,
            // so a device with no Arabic voice still spends no space on it.
            if let source = source.map(QuranSurahNames.naming) {
                HStack(spacing: 8) {
                    // A verse names its surah: "Quran Al-Anbya 21:87" (`QuranSurahNames.naming`).
                    HighlightedSnippet(
                        source: source,
                        term: searchQuery,
                        font: .caption.weight(.semibold),
                        accent: appearance.accent,
                        fg: .secondary,
                        guaranteeMatch: matches(source)
                    )
                    // An English citation keeps its own direction; one shown in Arabic
                    // (`DuaItem.displayReference`) takes the interface's.
                    .leftToRightContent(!source.isMostlyArabicScript)

                    Spacer(minLength: 8)

                    if speechEnabled {
                        ArabicVoiceGate { AdhkarListenButton(text: arabicText) }
                    }
                }
            } else if speechEnabled {
                ArabicVoiceGate {
                    HStack(spacing: 8) {
                        Spacer(minLength: 8)

                        AdhkarListenButton(text: arabicText)
                    }
                }
            }
        }
        // Without this the List is free to hand these rows a height that truncates the long duas to a single
        // ellipsized line; it lets each block claim the height its text actually needs.
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, 4)
        #if os(iOS)
        // The line between two rows spans the row. Left to the List, it started at the row's first
        // plain `Text`, the Listen button's word, and drew a short dash under each button.
        .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
        #endif
        // The row being read aloud carries a soft accent wash; during Listen All it walks down the
        // section one row at a time as the queue advances. (Its own observing view - see SpokenRowWash.)
        // On the phone it is the row's whole cell, applied where the List holds the row (`spokenRowWash`).
        #if os(watchOS)
        .background(SpokenRowWash(text: arabicText, color: appearance.accent))
        #endif
        #if os(iOS)
        .contextMenu {
            Text("Copy")
                .foregroundStyle(.secondary)

            Button {
                Settings.shared.hapticFeedback()
                UIPasteboard.general.string = arabicText
            } label: {
                Label("Copy Arabic", systemImage: "doc.on.doc")
            }

            Button {
                Settings.shared.hapticFeedback()
                UIPasteboard.general.string = transliteration
            } label: {
                Label("Copy Transliteration", systemImage: "doc.on.doc")
            }

            Button {
                Settings.shared.hapticFeedback()
                UIPasteboard.general.string = translation
            } label: {
                Label("Copy Translation", systemImage: "doc.on.doc")
            }

            if let onScrollTo {
                Divider()

                Button {
                    Settings.shared.hapticFeedback()
                    onScrollTo()
                } label: {
                    Label(scrollLabel, systemImage: "arrow.down.circle")
                }
            }
        }
        // The Quran list's trailing swipe: the arrow clears the search and scrolls to the row's home.
        .swipeActions(edge: .trailing) {
            if let onScrollTo {
                Button {
                    Settings.shared.hapticFeedback()
                    onScrollTo()
                } label: {
                    Image(systemName: "arrow.down.circle")
                }
                .tint(.secondary)
            }
        }
        #endif
        .modifier(OptionalRowID(id: rowID))
    }
}

/// `.id(_:)` only when the row has one: a shared placeholder id on every row would make them all "the
/// same" row to the scroll proxy.
private struct OptionalRowID: ViewModifier {
    let id: String?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let id {
            content.id(id)
        } else {
            content
        }
    }
}

struct AdhkarView: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var islamSettings = IslamSettings.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @State private var searchText = ""
    #if os(iOS)
    /// The "About" card's single open door (one @State + one destination on the List:
    /// every chip lives in the SAME List row, and two links in one row both fire).
    @State private var aboutDoor: SignsAboutDoor?
    #endif
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false
    /// The dhikr a result asked to scroll to ("Scroll To Dhikr"), consumed once the search clears.
    @State private var scrollTarget: String?

    #if os(iOS)
    // AI (semantic) dhikr search - the hadith book search's exact grammar, over the remembrances:
    // on-device meaning matching over the English translations, shown automatically above the
    // keyword matches. No mode to enter; the section appears (with one-time build progress the
    // first time) whenever it can help.
    @ObservedObject private var semanticEngine = SemanticSearchEngine.shared
    @State private var aiHits: [CommonDhikr] = []
    @State private var aiSearchTask: Task<Void, Never>?

    private static let semanticCorpusID = "adhkar-en"

    /// True when the live query is one the semantic engine can answer (English text, long enough).
    private var aiQueryEligible: Bool {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return SemanticSearchEngine.isSupported
            && trimmed.count >= 3
            && !trimmed.containsArabicScript
    }

    private func prepareSemanticCorpus() {
        guard SemanticSearchEngine.isSupported, !semanticEngine.isReady(Self.semanticCorpusID) else { return }
        // The transliterated "title" plus the English text; the Arabic embeds to nothing anyway.
        let texts = commonDhikrItems.map { "\($0.transliteration) \($0.translation)" }
        // Keyed by the dhikr's own id, so index -> dhikr resolution survives any reorder of the source.
        let keys = commonDhikrItems.map(\.id)
        // v3 (2026-11-26): the transliterations were respelled to the house style, long vowels doubled
        // (Scripts/transliteration.py), so an earlier build in Caches holds stale texts and keys.
        semanticEngine.prepare(corpusID: Self.semanticCorpusID, version: "v3-\(texts.count)", texts: texts, keys: keys)
    }

    private func runAISearch(query: String) {
        aiSearchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard SemanticSearchEngine.isSupported, trimmed.count >= 3, !trimmed.containsArabicScript else {
            if !aiHits.isEmpty { aiHits = [] }
            return
        }
        prepareSemanticCorpus()

        aiSearchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            let results = await semanticEngine.search(corpusID: Self.semanticCorpusID, query: trimmed, limit: 10)
            guard !Task.isCancelled else { return }
            // Resolve through the corpus KEYS (the dhikr's id), falling back to position only for
            // a corpus persisted before keys existed.
            let keys = await MainActor.run { semanticEngine.corpus(Self.semanticCorpusID)?.itemKeys }
            await MainActor.run {
                guard trimmed == searchText.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
                // Plain apply: an animated section insert racing another async apply is the
                // collection-view assertion crash the Quran search hit.
                aiHits = results.compactMap { result in
                    if let keys, keys.indices.contains(result.index) {
                        let key = keys[result.index]
                        return commonDhikrItems.first(where: { $0.id == key })
                    }
                    return commonDhikrItems.indices.contains(result.index) ? commonDhikrItems[result.index] : nil
                }
            }
        }
    }

    // Ask AI: the on-device chat (`AskAIChatView`), opened from the ASK AI row above the matches
    // with the typed query as its first question - the Quran search's rule. Exists only on Apple
    // Intelligence devices (`OnDeviceAsk.isAvailable`).
    @State private var showAskAI = false
    /// The AI-vs-keyword segmented switch, shown only when BOTH result kinds exist. Reset to the
    /// AI list on every new query.
    @State private var showKeywordResults = false

    /// "ASK AI" with the sparkles glyph in the header gray, as the Quran search's `askAIHeader` draws it.
    private var askAIHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
            Text("ASK AI")

            Spacer()
        }
    }

    private var askPromptRow: some View {
        Button {
            settings.hapticFeedback()
            showAskAI = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.caption)

                Text("Ask AI about \u{201C}\(searchText.trimmingCharacters(in: .whitespacesAndNewlines))\u{201D}")
                    .font(.caption.weight(.semibold))

                Spacer()

                Image(systemName: "chevron.forward")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .foregroundColor(settings.accentColor.color)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .contentSurface(clear: true, rectangle: true)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// The ASK AI section: the one-tap row that opens the chat with the query as its first question.
    @ViewBuilder
    private func askAISection(hasResults: Bool) -> some View {
        if OnDeviceAsk.isAvailable {
            Section(header: askAIHeader) { askPromptRow }
        }
    }

    private var resultsPickerSection: some View {
        Section {
            Picker("Results", selection: $showKeywordResults) {
                Text("AI Results").tag(false)
                Text("Keyword Results").tag(true)
            }
            .pickerStyle(.segmented)
        }
    }

    /// The AI (semantic) matches for the live query, shown automatically: build progress the first
    /// time, then the ranked matches - the same rows the keyword matches use. Deliberately SILENT
    /// otherwise (Arabic query, build failed, no semantic matches): an automatic section must
    /// never nag.
    @ViewBuilder
    private var aiMatchesSection: some View {
        if aiQueryEligible {
            if semanticEngine.isReady(Self.semanticCorpusID) {
                if !aiHits.isEmpty {
                    Section {
                        ForEach(aiHits, id: \.id) { dhikr in
                            AdhkarRow(
                                arabicText: dhikr.arabicText,
                                transliteration: dhikr.transliteration,
                                translation: dhikr.translation,
                                useQuranicFont: settings.useFontArabic,
                                searchQuery: searchText,
                                speechEnabled: true,
                                source: dhikr.source
                            )
                            .equatable()
                            .spokenRowWash(dhikr.arabicText)
                        }
                    } header: {
                        SectionPillHeader(title: String(localized: "AI MATCHES"), count: aiHits.count, icon: "sparkles")
                    }
                }
            } else if !semanticEngine.failedCorpora.contains(Self.semanticCorpusID) {
                Section { AISearchStatusRow(corpusID: Self.semanticCorpusID, failed: false) }
            }
        }
    }
    #endif

    var body: some View {
        // Both result kinds landed: ONE segmented switch decides which list fills the page (the
        // hadith book search's rule). With only one kind present, no picker - it just shows.
        #if os(iOS)
        let searchActive = !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let keywordMatchesExist = searchActive && commonDhikrItems.contains(where: { matchesSearch($0) })
        let showResultsPicker = !aiHits.isEmpty && keywordMatchesExist
        let keywordVisible = !showResultsPicker || showKeywordResults
        #else
        let keywordVisible = true
        #endif

        return ScrollViewReader { proxy in
        List {
            Group {
                #if os(iOS)
                if !searchActive {
                    ResourceHeroSection(ResourceHero(
                        eyebrow: String(localized: "REMEMBRANCE OF ALLAH"),
                        systemImage: "book.closed.fill",
                        headline: String(localized: "Unquestionably, by the remembrance of Allah hearts are assured."),
                        source: String(localized: "Quran 13:28"),
                        message: String(localized: "Words of praise, thanks and glorification from the Quran and the Sunnah, each in Arabic with its transliteration and meaning, to keep on your tongue through the day.")
                    ) {
                        DhikrFourWordsArt()
                    })
                }
                #endif
                introductionSection
                #if os(iOS)
                if searchActive {
                    askAISection(hasResults: !aiHits.isEmpty || keywordMatchesExist)
                    if showResultsPicker { resultsPickerSection }
                    // AI matches appear AUTOMATICALLY above the keyword results - no mode to enter.
                    if !showResultsPicker || !showKeywordResults { aiMatchesSection }
                }
                #endif
                if keywordVisible {
                    adhkarRows
                }
                etymologySection
                virtuesSection

                Section {
                    SpeechQualityHint()
                }
                #if os(iOS)
                AboutSignsSection(heading: String(localized: "About Dhikr & Remembrance"),
                                  systemImage: "book.closed",
                                  doors: [.allah, .tawhid, .makeDua],
                                  openDoor: $aboutDoor)
                #endif
            }
            .themedListRowBackground()
        }
        #if os(iOS)
        // Apple Music-style: the bottom bar minimizes while scrolling down, restores on scroll-up.
        .collapseBarsOnScroll($barsCollapsed)
        // Applied BEFORE the bottom bar below it: bottom safe-area insets stack outward, so the inset
        // added first sits nearest the content and later ones go underneath it. With the bar first, the
        // Now Playing player landed UNDER it (Abu, 2026-10-07). The Quran tab's order is the same.
        .applyConditionalListStyle()
        .adaptiveSafeArea(edge: .bottom) {
            // The Arabic face picker used to float here, above the search bar. It was the same control
            // on six screens writing one `settings.islamArabicFace`, which is a SETTING, not a reading
            // control - it now lives once, in Settings -> Islam Settings -> Arabic Text
            // (Abu, 2026-09-19). The bar is just the search bar again.
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                SearchBar(text: (AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut)))
                    .minimizedBarStyle(barsCollapsed)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: barsCollapsed)
            .padding(.horizontal, 24)
            .padding(.bottom, BottomBarCushion.standard)
            .background(Color.white.opacity(0.00001))
        }
        #elseif os(watchOS)
        .searchable(text: (AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut)))
        #endif
        #if os(watchOS)
        // The watch has no floating bottom bar to order against, so it is styled here.
        .applyConditionalListStyle()
        #endif
        .compactListSectionSpacing()
        #if os(iOS)
        .aboutSignsDestination($aboutDoor)
        #endif
        .navigationTitle("Dhikr & Remembrances")
        #if os(iOS)
        .onChange(of: searchText) { text in
            // A new query starts back on the AI list.
            showKeywordResults = false
            runAISearch(query: text)
        }
        .sheet(isPresented: $showAskAI) {
            if #available(iOS 16.0, *) {
                AskAIChatSheet(initialQuestion: searchText)
            }
        }
        // The one-time vector build finishing mid-query: surface the results without another keystroke.
        .onChange(of: semanticEngine.readyCorpora) { ready in
            guard ready.contains(Self.semanticCorpusID) else { return }
            runAISearch(query: searchText)
        }
        #endif
        // A running "Listen All" queue must not follow the user out of this screen (it kept speaking -
        // and kept the ducking audio session alive - after navigating away).
        .onDisappear { ArabicSpeech.shared.stop() }
        .onChange(of: scrollTarget) { target in
            guard let target else { return }
            // The search rows are still animating out; scroll once the full list is back.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation { proxy.scrollTo(target, anchor: .top) }
            }
        }
        }
    }

    private func matchesSearch(_ dhikr: CommonDhikr) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }

        let normalizedQuery = query.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        return dhikr.searchBlob.contains(normalizedQuery)
    }

    /// One remembrance's row. The search filters the DATA (`adhkarRows`), not the row: a row that is
    /// an `if` is not one view by its type, and the List then deletes and re-inserts the section's
    /// off-screen rows when this page's body runs again after a scroll (measured 2026-11-17; see
    /// `SummaryTileGrid.body`).
    private func adhkarRow(_ dhikr: CommonDhikr) -> some View {
        let searching = !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return AdhkarRow(
            arabicText: dhikr.arabicText,
            transliteration: dhikr.transliteration,
            translation: dhikr.translation,
            useQuranicFont: settings.useFontArabic,
            searchQuery: searchText,
            speechEnabled: true,
            source: dhikr.source,
            rowID: dhikr.id,
            // Only while searching: with the full list showing, the row is already where it lives.
            onScrollTo: searching ? {
                withAnimation { searchText = "" }
                scrollTarget = dhikr.id
            } : nil
        )
        .equatable()
        .spokenRowWash(dhikr.arabicText)
    }

    private var introductionSection: some View {
        Section(header: SectionHeaderLine(String(localized: "REMEMBRANCES OF ALLAH")) {
            // Count pill first (the SectionPillHeader rule); the pill plays every dhikr below, in order.
            CountPill(count: commonDhikrItems.count)

            ListenAllPill(texts: commonDhikrItems.map(\.arabicText))
        }) {
             ArticleLead(String(localized: "Short remembrances to keep your heart connected to Allah throughout the day."),
                         eyebrow: String(localized: "IN SHORT"))

             // The phone's hero quotes this ayah above the section (`ResourceHero`); the watch has no hero.
             #if os(watchOS)
             Text(String(localized: "\"Unquestionably, by the remembrance of Allah hearts are assured.\" (Quran 13:28)").localizedDigits)
                 .font(.caption)
                 .foregroundColor(.secondary)
             #endif
        }
    }

    /// The article kit's etymology card (Abu, 2026-10-03: "make it pretty like pillars and beliefs").
    private var etymologySection: some View {
        Section(header: Text("ETYMOLOGY")) {
            ArticleEtymologyCard("Dhikr", arabic: "ذِكْر", root: "ذ ك ر", rootLatin: "dh-k-r",
                                 coreMeaning: String(localized: "to remember, to mention, to be mindful"),
                                 text: String(localized: "Dhikr literally means remembrance or mentioning. It includes saying SubhaanAllah, Alhamdulillah, Allahu Akbar, reciting the Quran, and keeping Allah always present in the heart and tongue."))
        }
    }

    @ViewBuilder
    private var adhkarRows: some View {
        ForEach(commonDhikrItems.filter { matchesSearch($0) }) { dhikr in
            adhkarRow(dhikr)
        }

        // The rows above vanish one by one as the query narrows; when they've ALL gone, say so
        // instead of leaving a silent gap.
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           !commonDhikrItems.contains(where: { matchesSearch($0) }) {
            #if os(iOS)
            Text(aiHits.isEmpty
                 ? String(localized: "No remembrances match your search.")
                 : String(localized: "No keyword matches; see the AI results above."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            #else
            Text("No remembrances match your search.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            #endif
        }
    }

    private var virtuesSection: some View {
        // A lead, the two quoted callouts, and a closing card: the Pillars & Beliefs page grammar.
        Section(header: Text("VIRTUES OF DHIKR")) {
            ArticleLead(String(localized: "Dhikr is a continuous awareness of Allah. It revives the heart, protects the soul, and keeps a believer steady in trials."),
                        eyebrow: String(localized: "IN SHORT"))

            ArticleCallout(
                bullets: [
                    String(localized: "So remember Me; I will remember you. And be grateful to Me and do not deny Me. (Quran 2:152)"),
                    String(localized: "Unquestionably, by the remembrance of Allah hearts are assured. (Quran 13:28)"),
                    String(localized: "O you who have believed, remember Allah with much remembrance. (Quran 33:41)"),
                    String(localized: "Indeed, the Muslim men and Muslim women, the believing men and believing women, the obedient men and obedient women, the truthful men and truthful women, the patient men and patient women, the humble men and humble women, the charitable men and charitable women, the fasting men and fasting women, the men who guard their private parts and the women who do so, and the men who remember Allah often and the women who do so: for them Allah has prepared forgiveness and a great reward. (Quran 33:35)")
                ],
                title: String(localized: "Quranic Reminders"),
                systemImage: "book.closed.fill"
            )
            .articleCardRow()

            ArticleCallout(
                bullets: [
                    String(localized: "The best of your deeds, and the purest with your Master, is the remembrance of Allah. (Tirmidhi 3377, saheeh)"),
                    String(localized: "Two words are light on the tongue, heavy on the Scale, and beloved to the Most Merciful: SubhaanAllahi wa bihamdihi, SubhaanAllahil Azeem. (Bukhaari 6682; Muslim 2694)"),
                    String(localized: "Keep your tongue moist with the remembrance of Allah. (Tirmidhi 3375, hasan)")
                ],
                title: String(localized: "Prophetic Encouragement"),
                systemImage: "quote.bubble.fill"
            )
            .articleCardRow()

            ArticleClosing(String(localized: "Make dhikr a daily rhythm: morning, evening, after salaah, before sleep, and during ordinary moments. A heart that remembers Allah does not stay empty."))
                .articleCardRow()
        }
    }
}

#Preview {
    AlIslamPreviewContainer {
        AdhkarView()
    }
}
