import SwiftUI

struct PillarsView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            #if DEBUG
            DebugArticleLink(articles: [
                "god": AnyView(GodPillarView()), "islam": AnyView(IslamPillarView()), "muslim": AnyView(MuslimPillarView()),
                "allah": AnyView(AllahPillarView()), "quran": AnyView(QuranPillarView()), "prophet": AnyView(ProphetPillarView()),
                "sunnah": AnyView(SunnahPillarView()), "hadith": AnyView(HadithPillarView()),
                "shahadah": AnyView(ShahadahView()), "salah": AnyView(SalahView()), "sawm": AnyView(SawmView()),
                "zakah": AnyView(ZakahView()), "hajj": AnyView(HajjView()),
                "belief-allah": AnyView(GodView()), "angels": AnyView(AngelsView()), "books": AnyView(BooksView()),
                "prophets": AnyView(ProphetsView()), "lastday": AnyView(DayView()), "qadar": AnyView(QadarView()),
                "haram": AnyView(HaramView()), "nabawi": AnyView(NabawiView()), "aqsa": AnyView(AqsaView()),
                "compile": AnyView(CompileView()), "tafsir": AnyView(TafsirView()), "ahruf": AnyView(AhrufView()),
                "qiraat": AnyView(QiraatView()), "hijri": AnyView(HijriCalendarView()),
                "seerah": AnyView(SeerahView()), "farewell": AnyView(FarewellView()), "ahlulbayt": AnyView(AhlulBaytView()),
                "wives": AnyView(WivesView()), "sahabah": AnyView(SahabahView()), "caliphates": AnyView(CaliphatesView()),
                "madhab": AnyView(MadhabView()), "ahlussunnah": AnyView(AhlusSunnahView()), "manhaj": AnyView(FiqhAqeedahManhajView()),
                "aqeedah": AnyView(AqeedahMadhabView()),
                "sahabah-scholars": AnyView(SahabahScholarsView()), "salaf": AnyView(SalafScholarsView()), "tabari": AnyView(TabariView()),
                "ibntaymiyyah": AnyView(IbnTaymiyyahView()), "ibnqayyim": AnyView(IbnQayyimView()), "dhahabi": AnyView(DhahabiView()),
                "ibnkathir": AnyView(IbnKathirView()), "later": AnyView(LaterScholarsView()),
                "salafiyyah": AnyView(SalafiyyahView()), "quransunnah": AnyView(QuranSunnahView()), "shirk": AnyView(ShirkView()),
                "kufr": AnyView(KufrView()), "bidah": AnyView(BidahView()), "mawlid": AnyView(MawlidView()),
                "sufism": AnyView(SufismAnswerView()), "shia": AnyView(ShiaAnswerView()), "christianity": AnyView(ChristianityAnswerView()),
                "judaism": AnyView(JudaismAnswerView()), "hinduism": AnyView(HinduismAnswerView()), "paganism": AnyView(PaganismAnswerView()),
                "buddhism": AnyView(BuddhismAnswerView()), "atheism": AnyView(AtheismAnswerView()),
            ])
            #endif

            Group {
                Section(header: Text("THE BASICS")) {
                    NavigationLink(destination: LazyDestination { GodPillarView() }) {
                        Text("Does God Exist?")
                            .foregroundColor(settings.accentColor.color)
                            .font(.headline)
                    }
                    .padding(.vertical, 4)

                    NavigationLink(destination: LazyDestination { IslamPillarView() }) {
                        Text("What is Islam?")
                            .foregroundColor(settings.accentColor.color)
                            .font(.headline)
                    }
                    .padding(.vertical, 4)

                    NavigationLink(destination: LazyDestination { MuslimPillarView() }) {
                        Text("What is a Muslim?")
                            .foregroundColor(settings.accentColor.color)
                            .font(.headline)
                    }
                    .padding(.vertical, 4)

                    NavigationLink(destination: LazyDestination { AllahPillarView() }) {
                        Text("Who is Allah ﷻ‎?")
                            .foregroundColor(settings.accentColor.color)
                            .font(.headline)
                    }
                    .padding(.vertical, 4)

                    NavigationLink(destination: LazyDestination { QuranPillarView() }) {
                        Text("What is the Quran?")
                            .foregroundColor(settings.accentColor.color)
                            .font(.headline)
                    }
                    .padding(.vertical, 4)

                    NavigationLink(destination: LazyDestination { ProphetPillarView() }) {
                        Text("Who is Prophet Muhammad ﷺ?")
                            .foregroundColor(settings.accentColor.color)
                            .font(.headline)
                    }
                    .padding(.vertical, 4)

                    NavigationLink(destination: LazyDestination { SunnahPillarView() }) {
                        Text("What is the Sunnah?")
                            .foregroundColor(settings.accentColor.color)
                            .font(.headline)
                    }
                    .padding(.vertical, 4)

                    NavigationLink(destination: LazyDestination { HadithPillarView() }) {
                        Text("What are Hadiths?")
                            .foregroundColor(settings.accentColor.color)
                            .font(.headline)
                    }
                    .padding(.vertical, 4)
                }

                IslamicPillarsView()

                ImanPillarsView()

                MosquesView()

                BeliefsQuranView()

                BeliefsHistoricalView()

                ScholarsSectionView()

                SalafiyyahSectionView()
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Pillars & Beliefs")
    }
}

#if DEBUG
/// DEBUG launch argument `-pillarsArticle <key>` (and `-guidesArticle <key>` in the How-to guides): pushes
/// one article as its list appears, the only headless route into these pages for screenshot checks.
/// Renders nothing on its own: an invisible `NavigationLink` that is active from the first frame.
struct DebugArticleLink: View {
    let articles: [String: AnyView]
    var argument: String = "-pillarsArticle"
    @State private var isActive = false

    private var requested: AnyView? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let idx = arguments.firstIndex(of: argument), arguments.indices.contains(idx + 1) else { return nil }
        return articles[arguments[idx + 1]]
    }

    var body: some View {
        if let requested {
            NavigationLink(destination: requested, isActive: $isActive) { EmptyView() }
                .hidden()
                .frame(height: 0)
                .listRowInsets(EdgeInsets())
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { isActive = true }
                }
        }
    }
}
#endif

/// A quoted ayah or hadith in the Pillars, Beliefs and How-to guides: the original Arabic above its
/// English, in the accent colour, as one reusable view with a context menu that copies both, source
/// included (the citation is part of the English itself, e.g. "(Quran 2:43)" or "(Sahih al-Bukhari 631)").
///
/// The Arabic is the app's own text, not retyped: ayat are the Uthmani text of the bundled mushaf and
/// hadith are the matn as printed in the bundled collection, so what the reader sees here is what they
/// find when they open the same reference in the Quran or Hadith tabs.
struct ScriptureQuote: View {
    @ObservedObject private var settings = Settings.shared

    /// The English rendering with its citation.
    let text: String
    /// The Arabic original: the ayah, or the hadith's matn (the Prophet's words, or the Companion's
    /// report), without the chain of narrators.
    var arabic: String? = nil
    /// Hadith and the words of the Companions render slightly softened (0.85 opacity) so ayat keep
    /// the fullest accent, and their Arabic is set in the Islam tab's face rather than the mushaf face.
    var dimmed: Bool = false

    private var accent: Color { settings.accentColor.color.opacity(dimmed ? 0.85 : 1) }

    /// Ayat follow the Quran font picker (they ARE Quran, with its pause marks and Uthmani spelling);
    /// everything else follows the Islam tab's Arabic face, the same one the duas and adhkar use.
    private var arabicFont: Font {
        dimmed
            ? settings.scalableIslamArabicFont(base: 22, relativeTo: .title2)
            : Font.arabic(settings.fontArabic, size: 24, relativeTo: .title2)
    }

    private var arabicUsesCustomFace: Bool {
        dimmed ? settings.islamUsesCustomArabicFace : settings.quranUsesCustomArabicFace
    }

    private var copyText: String {
        if let arabic, !arabic.isEmpty { return arabic + "\n\n" + text }
        return text
    }

    var body: some View {
        let quote = VStack(alignment: .leading, spacing: 10) {
            if let arabic, !arabic.isEmpty {
                Text(arabic.decomposingAlefMadda)
                    .font(arabicFont)
                    .arabicFontDesign(custom: arabicUsesCustomFace)
                    .lineSpacing(6)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .foregroundColor(accent)
            }

            Text(text)
                .font(.title3)
                .foregroundColor(accent)
        }
        .padding(.vertical, 2)
        #if os(iOS)
        // Kept as `Text`s rather than a `SelectableProse`: the context menu below already covers
        // "copy the whole quote, citation included", which is what a quote is normally wanted for,
        // and swapping in a text view per quote would put a UITextView in every article row to
        // duplicate a path that already works.
        quote
            .textSelection(.enabled)
            .contextMenu {
                Text("Copy")
                    .foregroundStyle(.secondary)

                Button {
                    settings.hapticFeedback()
                    UIPasteboard.general.string = copyText
                } label: {
                    Label("Copy Quote", systemImage: "doc.on.doc")
                }
            }
        #else
        quote
        #endif
    }
}
