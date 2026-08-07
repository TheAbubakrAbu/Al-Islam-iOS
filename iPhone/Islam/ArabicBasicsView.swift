import SwiftUI

/// Recognition-level Arabic grammar for someone who has just learned the letters: the feminine ة, the dual,
/// the three plural shapes, and the three case endings - a few worked examples each, not a grammar course.
/// Every row is the `ArabicExampleRow` shape the taa marbuuTah page uses: Arabic large in the app's Arabic
/// face, transliteration and a one-line English note beside it, tap to hear it.
///
/// Sun and moon letters (the definite article ال) are deliberately NOT here: the Tajweed screens already
/// teach Shamsiyyah and Qamariyyah in full.
struct ArabicBasicsView: View {
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false
    @ObservedObject private var settings = Settings.shared

    var body: some View {
        List {
            Group {
                genderSection
                dualSection
                pluralsSection
                casesSection
            }
            .themedListRowBackground()

        }
        .applyConditionalListStyle()
        .navigationTitle("Basic Grammar")
        .onDisappear {
            ArabicSpeech.shared.stop()
            ArabicPracticeSelection.shared.clear()
        }
        #if os(iOS)
        // Apple Music-style: the bottom bar minimizes while scrolling down, restores on scroll-up.
        .collapseBarsOnScroll($barsCollapsed)
        .adaptiveSafeArea(edge: .bottom) {
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                ArabicSizeSlider()

                // The same Islam-tab face choice the alphabet and Tashkeel screens carry.
                IslamArabicFontPicker()
            }
            .minimizedBarStyle(barsCollapsed)
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HideEnglishToolbarButton()
            }
        }
        #endif
    }

    private var genderSection: some View {
        Section {
            ArabicExampleRow(
                arabic: "مُسْلِم",
                transliteration: "muslim",
                note: "A Muslim man - no ة"
            )
            ArabicExampleRow(
                arabic: "مُسْلِمَة",
                transliteration: "muslimah",
                note: "A Muslim woman - the ة marks the feminine"
            )
            ArabicExampleRow(
                arabic: "مُعَلِّم \u{2190} مُعَلِّمَة",
                transliteration: "mu'allim \u{2192} mu'allimah",
                note: "A teacher, male \u{2192} female"
            )
        } header: {
            Text("GENDER: THE FEMININE ة")
        } footer: {
            Text("Adding taa marbuuTah (ة) to the end of a noun is the usual way Arabic marks it as feminine.")
        }
    }

    private var dualSection: some View {
        Section {
            ArabicExampleRow(
                arabic: "كِتَاب",
                transliteration: "kitaab",
                note: "One book"
            )
            ArabicExampleRow(
                arabic: "كِتَابَانِ",
                transliteration: "kitaabaan(i)",
                note: "Two books - subject form (raf'): add ـَانِ"
            )
            ArabicExampleRow(
                arabic: "كِتَابَيْنِ",
                transliteration: "kitaabayn(i)",
                note: "Two books - object or after-preposition form (nasb/jarr): add ـَيْنِ"
            )
        } header: {
            Text("THE DUAL: EXACTLY TWO")
        } footer: {
            Text("Arabic has a special ending for exactly two of something, and it changes with the word's role in the sentence.")
        }
    }

    private var pluralsSection: some View {
        Section {
            ArabicExampleRow(
                arabic: "مُسْلِمُونَ",
                transliteration: "muslimuun(a)",
                note: "Sound masculine plural, subject form: add ـُونَ"
            )
            ArabicExampleRow(
                arabic: "مُسْلِمِينَ",
                transliteration: "muslimiin(a)",
                note: "Sound masculine plural, object or after-preposition form: add ـِينَ"
            )
            ArabicExampleRow(
                arabic: "مُسْلِمَات",
                transliteration: "muslimaat",
                note: "Sound feminine plural: the ة opens into ـَات"
            )
            ArabicExampleRow(
                arabic: "كِتَاب \u{2190} كُتُب",
                transliteration: "kitaab \u{2192} kutub",
                note: "Book \u{2192} books (broken plural)"
            )
            ArabicExampleRow(
                arabic: "رَجُل \u{2190} رِجَال",
                transliteration: "rajul \u{2192} rijaal",
                note: "Man \u{2192} men (broken plural)"
            )
            ArabicExampleRow(
                arabic: "بَيْت \u{2190} بُيُوت",
                transliteration: "bayt \u{2192} buyuut",
                note: "House \u{2192} houses (broken plural)"
            )
        } header: {
            Text("PLURALS")
        } footer: {
            Text("Sound plurals add an ending and leave the word alone. Broken plurals reshape the inside of the word and follow no single rule - each one is memorized with its noun.")
        }
    }

    private var casesSection: some View {
        Section {
            ArabicExampleRow(
                arabic: "جَاءَ الرَّجُلُ",
                transliteration: "jaa'a r-rajulu",
                note: "Raf' (marfuu'): damma - the subject. \"The man came.\""
            )
            ArabicExampleRow(
                arabic: "رَأَيْتُ الرَّجُلَ",
                transliteration: "ra'aytu r-rajula",
                note: "Nasb (mansuub): fatha - the object. \"I saw the man.\""
            )
            ArabicExampleRow(
                arabic: "فِي البَيْتِ",
                transliteration: "fi l-bayti",
                note: "Jarr (majruur): kasra - after a preposition or in idafah. \"In the house.\""
            )
        } header: {
            Text("THE THREE CASES (I'RAAB)")
        } footer: {
            Text("Recognition level only: the noun's final vowel changes with its job in the sentence. You will see these endings everywhere; you do not need to produce them yet.")
        }
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: true) {
        ArabicBasicsView()
    }
}
