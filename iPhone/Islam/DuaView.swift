import SwiftUI

private struct DuaItem: Identifiable {
    let arabicText: String
    let transliteration: String
    let translation: String
    let reference: String?
    let displayTranslation: String
    let searchBlob: String

    init(arabicText: String, transliteration: String, translation: String, reference: String? = nil) {
        self.arabicText = arabicText
        self.transliteration = transliteration
        self.translation = translation
        self.reference = reference
        self.displayTranslation = reference.map { "\(translation)\n- \($0) -" } ?? translation
        self.searchBlob = [arabicText, transliteration, self.displayTranslation]
            .joined(separator: " ")
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    var id: String { "\(reference ?? transliteration)-\(arabicText)" }
}

private struct DuaCollection: Identifiable {
    let title: String
    let subtitle: String
    let systemImage: String
    let introductionTitle: String
    let introduction: String
    let items: [DuaItem]

    var id: String { title }
}

struct DuaView: View {
    @EnvironmentObject var settings: Settings

    private static let collections: [DuaCollection] = [
        DuaCollections.common,
        DuaCollections.rabbana
    ]
    
    var body: some View {
        List {
            Group {
            Section(header: Text("SUPPLICATIONS TO ALLAH")) {
                Text("Short, daily supplications that keep your heart connected to Allah in every situation. \"Call upon Me; I will respond to you.\" (Quran 40:60)")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding(.vertical, 8)

                Section {
                    ForEach(Self.collections) { collection in
                        NavigationLink {
                            DuaCollectionView(collection: collection)
                        } label: {
                            Label {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(collection.title)
                                        .foregroundStyle(.primary)

                                    Text(collection.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: collection.systemImage)
                                    .foregroundStyle(settings.accentColor.color)
                            }
                        }
                    }
                } header: {
                    Text("DUA COLLECTIONS")
                }
            }

            Section(header: Text("ETYMOLOGY")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Arabic root: د ع و (d-ʿ-w)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(settings.accentColor.color)

                    Text("Core meaning: to call, to invite, to summon")
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    Text("Dua literally means calling out, especially calling upon Allah. In Islam it is not just asking for things; it is an act of worship, turning to Him with need, hope, fear, and love.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.secondary.opacity(0.1))
                )
                .padding(-4)
            }

            Section(header: Text("VIRTUES OF DUA")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dua is an act of worship and a direct connection with Allah. No sincere call is lost: it is answered now, delayed for wisdom, or stored as reward.")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }

                DuaReflectionCard(
                    title: "Quranic Promise",
                    lines: [
                        "And your Lord says, \"Call upon Me; I will respond to you.\" (Quran 40:60)",
                        "And when My servants ask you concerning Me, indeed I am near. I respond to the invocation of the supplicant when he calls upon Me. (Quran 2:186)",
                        "Is He not best who responds to the desperate one when he calls upon Him and removes evil and makes you inheritors of the earth? (Quran 27:62)"
                    ],
                    accent: settings.accentColor.color
                )

                DuaReflectionCard(
                    title: "Prophetic Guidance",
                    lines: [
                        "Dua is worship.",
                        "A sincere dua is never wasted: immediate answer, deferred reward, or harm removed."
                    ],
                    accent: settings.accentColor.color
                )
            }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Dua & Supplications")
    }
}

private struct DuaCollectionView: View {
    @EnvironmentObject var settings: Settings
    @State private var searchText = ""

    let collection: DuaCollection

    var body: some View {
        List {
            Group {
            introductionSection
            duaRows
            }
            .themedListRowBackground()
        }
        #if os(iOS)
        .adaptiveSafeArea(edge: .bottom) {
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                Picker("Arabic Font", selection: $settings.useFontArabic.animation(.easeInOut)) {
                    Text("Quranic Font").tag(true)
                    Text("Basic Font").tag(false)
                }
                .pickerStyle(.segmented)
                // Non-interactive glass: interactive Liquid Glass steals per-segment taps on real iOS 26 hardware.
                .conditionalGlassEffect(interactive: false)
                .onChange(of: settings.useFontArabic) { _ in settings.hapticFeedback() }

                SearchBar(text: $searchText.animation(.easeInOut))
                    .padding([.horizontal, .top], -8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
            .background(Color.white.opacity(0.00001))
        }
        #else
        .searchable(text: $searchText.animation(.easeInOut))
        #endif
        .applyConditionalListStyle()
        .compactListSectionSpacing()
        .navigationTitle(collection.title)
    }

    private func matchesSearch(_ item: DuaItem) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }

        let normalizedQuery = query.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        return item.searchBlob.contains(normalizedQuery)
    }

    @ViewBuilder
    private func filteredDuaRow(_ item: DuaItem, alignArabicTrailing: Bool = true) -> some View {
        if matchesSearch(item) {
            AdhkarRow(
                arabicText: item.arabicText,
                transliteration: item.transliteration,
                translation: item.displayTranslation,
                alignArabicTrailing: alignArabicTrailing,
                useQuranicFont: settings.useFontArabic,
                searchQuery: searchText
            )
        }
    }

    private var introductionSection: some View {
        Section(header: Text(collection.introductionTitle.uppercased())) {
            Text(collection.introduction)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }

    private var etymologySection: some View {
        Section(header: Text("ETYMOLOGY")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Arabic root: د ع و (d-ʿ-w)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(settings.accentColor.color)

                Text("Core meaning: to call, to invite, to summon")
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Text("Dua literally means calling out, especially calling upon Allah. In Islam it is not just asking for things; it is an act of worship, turning to Him with need, hope, fear, and love.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.secondary.opacity(0.1))
            )
            .padding(-4)
        }
    }

    @ViewBuilder
    private var duaRows: some View {
        ForEach(collection.items) { item in
            filteredDuaRow(item)
        }
    }

    private var virtuesSection: some View {
        Section(header: Text("VIRTUES OF DUA")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Dua is an act of worship and a direct connection with Allah. No sincere call is lost: it is answered now, delayed for wisdom, or stored as reward.")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            DuaReflectionCard(
                title: "Quranic Promise",
                lines: [
                    "And your Lord says, \"Call upon Me; I will respond to you.\" Indeed, those who disdain My worship will enter Hell rendered contemptible. (Quran 40:60)",
                    "And when My servants ask you concerning Me, indeed I am near. I respond to the invocation of the supplicant when he calls upon Me. So let them respond to Me and believe in Me that they may be rightly guided. (Quran 2:186)",
                    "Is He not best who responds to the desperate one when he calls upon Him and removes evil and makes you inheritors of the earth? Is there a deity with Allah? Little do you remember. (Quran 27:62)"
                ],
                accent: settings.accentColor.color
            )

            DuaReflectionCard(
                title: "Prophetic Guidance",
                lines: [
                    "Dua is worship.",
                    "There is nothing more noble to Allah than dua.",
                    "A sincere dua is never wasted: immediate answer, deferred reward, or harm removed."
                ],
                accent: settings.accentColor.color
            )

            Text("Keep making dua in ease and hardship, in private and public, with certainty and patience. The One you call is always near.")
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

private enum DuaCollections {
    static let common = DuaCollection(
        title: "Common Duas",
        subtitle: "Daily supplications for protection, ease, and blessing",
        systemImage: "text.book.closed",
        introductionTitle: "Supplications to Allah",
        introduction: "Short, daily supplications that keep your heart connected to Allah in every situation. \"Call upon Me; I will respond to you.\" (Quran 40:60)",
        items: [
            DuaItem(arabicText: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِن زَوَالِ نِعمَتِكَ وَتَحَوُّلِ عَافِيَتِكَ وَفُجَاءَةِ نِقمَتِكَ وَجَمِيعِ سَخَطِكَ", transliteration: "Allahumma inni a'udhu bika min zawali ni'matika wa tahawwuli 'afiyatika wa fuja'ati niqmatika wa jamee' sakhatika", translation: "O Allah, I seek refuge in You from the removal of Your blessings, changing of Your protection, sudden wrath, and all of Your displeasure"),
            DuaItem(arabicText: "اللَّهُمَّ إِنِّي أَسأَلُكَ العَفوَ وَالعَافِيَةَ فِي الدُّنيَا وَالآخِرَةِ", transliteration: "Allahumma inni as'aluka al-'afwa wal-'afiyah fi ad-dunya wal-akhirah", translation: "O Allah, I ask You for forgiveness and well-being in this life and the hereafter"),
            DuaItem(arabicText: "اللَّهُمَّ إِنِّي أَسأَلُكَ الهُدَى وَالتُّقَى وَالعَفَافَ وَالغِنَى", transliteration: "Allahumma inni as'aluka al-huda wa at-tuqaa wal-'afaafa wal-ghina", translation: "O Allah, I ask You for guidance, righteousness, chastity, and sufficiency"),
            DuaItem(arabicText: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الكُفرِ وَالفَقرِ وَأَعُوذُ بِكَ مِن عَذَابِ القَبرِ", transliteration: "Allahumma inni a'udhu bika min al-kufr wal-faqr wa a'udhu bika min 'adhab al-qabr", translation: "O Allah, I seek refuge in You from disbelief, poverty, and the punishment of the grave"),
            DuaItem(arabicText: "اللَّهُمَّ مَا أَصبَحَ بِي مِن نِعمَةٍ أَو بِأَحَدٍ مِن خَلقِكَ فَمِنكَ وَحدَكَ لَا شَرِيكَ لَكَ فَلَكَ الحَمدُ وَلَكَ الشُّكرُ", transliteration: "Allahumma ma asbaha bi min ni'matin, aw bi ahadin min khalqika, faminka wahdaka la sharika laka, falaka alhamdu wa laka ash-shukr", translation: "O Allah, whatever blessings I or any of Your creatures rose up with, is from You alone, without partner, so for You is all praise and unto You all thanks."),
            DuaItem(arabicText: "رَبِّ اشرَح لِي صَدرِي وَيَسِّر لِي أَمرِي", transliteration: "Rabbi ishrah li sadri wa yassir li amri", translation: "O my Lord, expand for me my chest, and ease for me my task."),
            DuaItem(arabicText: "اللَّهُمَّ أَعِنِّي عَلَى ذِكرِكَ وَشُكرِكَ وَحُسنِ عِبَادَتِكَ", transliteration: "Allahumma a'innee ala dhikrika wa shukrika wa husni ibadatika", translation: "O Allah, assist me in remembering You, in thanking You, and in worshipping You in the best manner."),
            DuaItem(arabicText: "رَبَّنَا آتِنَا فِي الدُّنيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ", transliteration: "Rabbanaa atinaa fid-dunya hasanatan wa fil aakhirati hasanatan wa qinaa 'adhaaban-naar", translation: "Our Lord, give us in this world [that which is] good and in the Hereafter [that which is] good and protect us from the punishment of the Fire."),
            DuaItem(arabicText: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِن عَجزِ وَالكَسَلِ وَالجُبنِ وَالهَرَمِ وَالبُخلِ وَأَعُوذُ بِكَ مِن عَذَابِ القَبرِ وَمِن فِتنَةِ المَحيَا وَالمَمَاتِ", transliteration: "Allahumma inni a'udhu bika min al-'ajzi wal-kasali wal-jubni wal-harami wal-bukhli, wa a'udhu bika min 'adhab al-qabr, wa min fitnat al-mahya wal-mamat", translation: "O Allah, I seek refuge in You from weakness and laziness, miserliness and cowardice, the burden of debts and from being overpowered by men. I seek refuge in You from the punishment of the grave and from the trials and tribulations of life and death."),
            DuaItem(arabicText: "اللَّهُمَّ إِنِّي أَسأَلُكَ عِلمًا نَافِعًا وَرِزقًا طَيِّبًا وَعَمَلًا مُتَقَبَّلًا", transliteration: "Allahumma inni as'aluka 'ilman nafi'an, wa rizqan tayyiban, wa 'amalan mutaqabbalan", translation: "O Allah, I ask You for knowledge that is of benefit, a good provision, and deeds that will be accepted."),
            DuaItem(arabicText: "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الحَيُّ القَيُّومُ ۚ لَا تَأخُذُهُ سِنَةٌ وَلَا نَومٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الأَرضِ ۗ مَن ذَا الَّذِي يَشفَعُ عِندَهُ إِلَّا بِإِذنِهِ ۚ يَعلَمُ مَا بَينَ أَيدِيهِم وَمَا خَلفَهُم ۖ وَلَا يُحِيطُونَ بِشَيءٍ مِّن عِلمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرسِيُّهُ السَّمَاوَاتِ وَالأَرضَ ۖ وَلَا يَئُودُهُ حِفظُهُمَا ۚ وَهُوَ العَلِيُّ العَظِيمُ", transliteration: "Allahu la ilaha illa Huwa, Al-Hayyul-Qayyum. La ta'khudhuhu sinatun wa la nawm. Lahu ma fi as-samawati wa ma fi al-ard. Man dha allathee yashfa'u 'indahu illa bi-idhnihi? Ya'lamu ma bayna aydihim wa ma khalfahum, wa la yuhituna bishay'in min 'ilmihi illa bima sha'. Wasi'a kursiyyuhu as-samawati wal-ard, wa la ya'uduhu hifzuhuma, wa Huwal 'Aliyyul-'Azim.", translation: "Allah! There is no deity except Him, the Ever-Living, the Sustainer of existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. His Kursi extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High, the Most Great.", reference: "2:255")
        ]
    )

    static let rabbana = DuaCollection(
        title: "40 Rabbana Duas",
        subtitle: "Quranic duas beginning with Rabbana",
        systemImage: "40.circle",
        introductionTitle: "40 Rabbana Duas",
        introduction: "رَبَّنَا (Rabbanaa) means \"Our Lord.\" These Quranic supplications begin by calling on Allah with that intimate address, then ask for forgiveness, guidance, mercy, patience, protection, victory, provision, and success in this life and the Hereafter.",
        items: [
            DuaItem(arabicText: "وَإِذۡ يَرۡفَعُ إِبۡرَٰهِـۧمُ ٱلۡقَوَاعِدَ مِنَ ٱلۡبَيۡتِ وَإِسۡمَٰعِيلُ رَبَّنَا تَقَبَّلۡ مِنَّآۖ إِنَّكَ أَنتَ ٱلسَّمِيعُ ٱلۡعَلِيمُ", transliteration: "Rabbana taqabbal minnaa innaka Antas Samee'ul Aleem", translation: "Our Lord, accept this from us. Indeed, You are the Hearing, the Knowing.", reference: "2:127"),
            DuaItem(arabicText: "رَبَّنَا وَٱجۡعَلۡنَا مُسۡلِمَيۡنِ لَكَ وَمِن ذُرِّيَّتِنَآ أُمَّةٗ مُّسۡلِمَةٗ لَّكَ وَأَرِنَا مَنَاسِكَنَا وَتُبۡ عَلَيۡنَآۖ إِنَّكَ أَنتَ ٱلتَّوَّابُ ٱلرَّحِيمُ", transliteration: "Rabbana waj'alnaa muslimaini laka wa min zurriyyatinaaa ummatam muslimatal laka wa arinaa manaasikanaa wa tub 'alainaa innaka antat Tawwaabur Raheem", translation: "Our Lord, make us Muslims in submission to You and from our descendants a Muslim nation in submission to You. Show us our rites and accept our repentance. Indeed, You are the Accepting of Repentance, the Merciful.", reference: "2:128"),
            DuaItem(arabicText: "وَمِنۡهُم مَّن يَقُولُ رَبَّنَآ ءَاتِنَا فِي ٱلدُّنۡيَا حَسَنَةٗ وَفِي ٱلۡأٓخِرَةِ حَسَنَةٗ وَقِنَا عَذَابَ ٱلنَّارِ", transliteration: "Rabbana atina fid dunyaa hasanatanw wa fil aakhirati hasanatanw wa qinaa azaaban Naar", translation: "Our Lord, give us in this world good and in the Hereafter good and protect us from the punishment of the Fire.", reference: "2:201"),
            DuaItem(arabicText: "وَلَمَّا بَرَزُواْ لِجَالُوتَ وَجُنُودِهِۦ قَالُواْ رَبَّنَآ أَفۡرِغۡ عَلَيۡنَا صَبۡرٗا وَثَبِّتۡ أَقۡدَامَنَا وَٱنصُرۡنَا عَلَى ٱلۡقَوۡمِ ٱلۡكَٰفِرِينَ", transliteration: "Rabbana afrigh 'alainaa sabranw wa sabbit aqdaamanaa wansurnaa 'alal qawmil kaafireen", translation: "Our Lord, pour upon us patience, plant firmly our feet, and give us victory over the disbelieving people.", reference: "2:250"),
            DuaItem(arabicText: "لَا يُكَلِّفُ ٱللَّهُ نَفۡسٗا إِلَّا وُسۡعَهَاۚ لَهَا مَا كَسَبَتۡ وَعَلَيۡهَا مَا ٱكۡتَسَبَتۡۗ رَبَّنَا لَا تُؤَاخِذۡنَآ إِن نَّسِينَآ أَوۡ أَخۡطَأۡنَاۚ رَبَّنَا وَلَا تَحۡمِلۡ عَلَيۡنَآ إِصۡرٗا كَمَا حَمَلۡتَهُۥ عَلَى ٱلَّذِينَ مِن قَبۡلِنَاۚ رَبَّنَا وَلَا تُحَمِّلۡنَا مَا لَا طَاقَةَ لَنَا بِهِۦۖ وَٱعۡفُ عَنَّا وَٱغۡفِرۡ لَنَا وَٱرۡحَمۡنَآۚ أَنتَ مَوۡلَىٰنَا فَٱنصُرۡنَا عَلَى ٱلۡقَوۡمِ ٱلۡكَٰفِرِينَ", transliteration: "Rabbana laa tu'aakhiznaaa in naseenaaa aw akhtaanaa", translation: "Our Lord, do not impose blame upon us if we have forgotten or erred.", reference: "2:286"),
            DuaItem(arabicText: "لَا يُكَلِّفُ ٱللَّهُ نَفۡسٗا إِلَّا وُسۡعَهَاۚ لَهَا مَا كَسَبَتۡ وَعَلَيۡهَا مَا ٱكۡتَسَبَتۡۗ رَبَّنَا لَا تُؤَاخِذۡنَآ إِن نَّسِينَآ أَوۡ أَخۡطَأۡنَاۚ رَبَّنَا وَلَا تَحۡمِلۡ عَلَيۡنَآ إِصۡرٗا كَمَا حَمَلۡتَهُۥ عَلَى ٱلَّذِينَ مِن قَبۡلِنَاۚ رَبَّنَا وَلَا تُحَمِّلۡنَا مَا لَا طَاقَةَ لَنَا بِهِۦۖ وَٱعۡفُ عَنَّا وَٱغۡفِرۡ لَنَا وَٱرۡحَمۡنَآۚ أَنتَ مَوۡلَىٰنَا فَٱنصُرۡنَا عَلَى ٱلۡقَوۡمِ ٱلۡكَٰفِرِينَ", transliteration: "Rabbana wa laa tahmil-'alainaaa isran kamaa hamaltahoo 'alal-lazeena min qablinaa", translation: "Our Lord, lay not upon us a burden like that which You laid upon those before us.", reference: "2:286"),
            DuaItem(arabicText: "لَا يُكَلِّفُ ٱللَّهُ نَفۡسٗا إِلَّا وُسۡعَهَاۚ لَهَا مَا كَسَبَتۡ وَعَلَيۡهَا مَا ٱكۡتَسَبَتۡۗ رَبَّنَا لَا تُؤَاخِذۡنَآ إِن نَّسِينَآ أَوۡ أَخۡطَأۡنَاۚ رَبَّنَا وَلَا تَحۡمِلۡ عَلَيۡنَآ إِصۡرٗا كَمَا حَمَلۡتَهُۥ عَلَى ٱلَّذِينَ مِنۡ قَبۡلِنَاۚ رَبَّنَا وَلَا تُحَمِّلۡنَا مَا لَا طَاقَةَ لَنَا بِهِۦۖ وَٱعۡفُ عَنَّا وَٱغۡفِرۡ لَنَا وَٱرۡحَمۡنَآۚ أَنتَ مَوۡلَىٰنَا فَٱنصُرۡنَا عَلَى ٱلۡقَوۡمِ ٱلۡكَٰفِرِينَ", transliteration: "Rabbana wa laa tuhammilnaa maa laa taaqata lanaa bih; wa'fu 'annaa waghfir lanaa warhamnaa; Anta mawlaanaa fansurnaa 'alal qawmil kaafireen", translation: "Our Lord, burden us not with what we have no ability to bear. Pardon us, forgive us, and have mercy upon us. You are our protector, so give us victory over the disbelieving people.", reference: "2:286"),
            DuaItem(arabicText: "لَا يُكَلِّفُ ٱللَّهُ نَفۡسٗا إِلَّا وُسۡعَهَاۚ لَهَا مَا كَسَبَتۡ وَعَلَيۡهَا مَا ٱكۡتَسَبَتۡۗ رَبَّنَا لَا تُؤَاخِذۡنَآ إِن نَّسِينَآ أَوۡ أَخۡطَأۡنَاۚ رَبَّنَا وَلَا تَحۡمِلۡ عَلَيۡنَآ إِصۡرٗا كَمَا حَمَلۡتَهُۥ عَلَى ٱلَّذِينَ مِنۡ قَبۡلِنَاۚ رَبَّنَا وَلَا تُحَمِّلۡنَا مَا لَا طَاقَةَ لَنَا بِهِۦۖ وَٱعۡفُ عَنَّا وَٱغۡفِرۡ لَنَا وَٱرۡحَمۡنَآۚ أَنتَ مَوۡلَىٰنَا فَٱنصُرۡنَا عَلَى ٱلۡقَوۡمِ ٱلۡكَٰفِرِينَ", transliteration: "Rabbana laa tuhammilnaa maa laa taaqata lanaa bih; wa'fu 'annaa waghfir lanaa warhamnaa; Anta mawlaanaa fansurnaa 'alal qawmil kaafireen", translation: "Our Lord, burden us not with what we have no ability to bear. Pardon us, forgive us, and have mercy upon us. You are our protector, so give us victory over the disbelieving people.", reference: "2:286"),
            DuaItem(arabicText: "رَبَّنَا لَا تُزِغۡ قُلُوبَنَا بَعۡدَ إِذۡ هَدَيۡتَنَا وَهَبۡ لَنَا مِن لَّدُنكَ رَحۡمَةًۚ إِنَّكَ أَنتَ ٱلۡوَهَّابُ", transliteration: "Rabbana laa tuzigh quloobanaa ba'da iz hadaitanaa wa hab lanaa mil ladunka rahmah; innaka antal Wahhaab", translation: "Our Lord, let not our hearts deviate after You have guided us and grant us mercy from Yourself. Indeed, You are the Bestower.", reference: "3:8"),
            DuaItem(arabicText: "رَبَّنَآ إِنَّكَ جَامِعُ ٱلنَّاسِ لِيَوۡمٖ لَّا رَيۡبَ فِيهِۚ إِنَّ ٱللَّهَ لَا يُخۡلِفُ ٱلۡمِيعَادَ", transliteration: "Rabbanaaa innaka jaami 'un-naasil Yawmil laa raibafeeh; innal laaha laa yukhliful mee'aad", translation: "Our Lord, surely You will gather the people for a Day about which there is no doubt. Indeed, Allah does not fail in His promise.", reference: "3:9"),
            DuaItem(arabicText: "ٱلَّذِينَ يَقُولُونَ رَبَّنَآ إِنَّنَآ ءَامَنَّا فَٱغۡفِرۡ لَنَا ذُنُوبَنَا وَقِنَا عَذَابَ ٱلنَّارِ", transliteration: "Rabbanaaa innanaaa aamannaa faghfir lanaa zunoobanaa wa qinaa 'azaaban Naar", translation: "Our Lord, indeed we have believed, so forgive us our sins and protect us from the punishment of the Fire.", reference: "3:16"),
            DuaItem(arabicText: "رَبَّنَآ ءَامَنَّا بِمَآ أَنزَلۡتَ وَٱتَّبَعۡنَا ٱلرَّسُولَ فَٱكۡتُبۡنَا مَعَ ٱلشَّٰهِدِينَ", transliteration: "Rabbanaaa aamannaa bimaaa anzalta wattaba'nar Rasoola faktubnaa ma'ash shaahideen", translation: "Our Lord, we have believed in what You revealed and have followed the messenger, so register us among the witnesses to truth.", reference: "3:53"),
            DuaItem(arabicText: "وَمَا كَانَ قَوۡلَهُمۡ إِلَّآ أَن قَالُواْ رَبَّنَا ٱغۡفِرۡ لَنَا ذُنُوبَنَا وَإِسۡرَافَنَا فِيٓ أَمۡرِنَا وَثَبِّتۡ أَقۡدَامَنَا وَٱنصُرۡنَا عَلَى ٱلۡقَوۡمِ ٱلۡكَٰفِرِينَ", transliteration: "Rabbanagh fir lanaa zunoobanaa wa israafanaa feee amrinaa wa sabbit aqdaamanaa wansurnaa 'alal qawmil kaafireen", translation: "Our Lord, forgive us our sins and the excess committed in our affairs, plant firmly our feet, and give us victory over the disbelieving people.", reference: "3:147"),
            DuaItem(arabicText: "ٱلَّذِينَ يَذۡكُرُونَ ٱللَّهَ قِيَٰمٗا وَقُعُودٗا وَعَلَىٰ جُنُوبِهِمۡ وَيَتَفَكَّرُونَ فِي خَلۡقِ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضِ رَبَّنَا مَا خَلَقۡتَ هَٰذَا بَٰطِلٗا سُبۡحَٰنَكَ فَقِنَا عَذَابَ ٱلنَّارِ", transliteration: "Rabbanaa maa khalaqta haaza baatilan Subhaanaka faqinaa 'azaaban Naar", translation: "Our Lord, You did not create this aimlessly; exalted are You, so protect us from the punishment of the Fire.", reference: "3:191"),
            DuaItem(arabicText: "رَبَّنَآ إِنَّكَ مَن تُدۡخِلِ ٱلنَّارَ فَقَدۡ أَخۡزَيۡتَهُۥۖ وَمَا لِلظَّٰلِمِينَ مِنۡ أَنصَارٖ", transliteration: "Rabbanaaa innaka man tudkhilin Naara faqad akhzai tahoo wa maa lizzaalimeena min ansaar", translation: "Our Lord, indeed whoever You admit to the Fire, You have disgraced him, and for the wrongdoers there are no helpers.", reference: "3:192"),
            DuaItem(arabicText: "رَّبَّنَآ إِنَّنَا سَمِعۡنَا مُنَادِيٗا يُنَادِي لِلۡإِيمَٰنِ أَنۡ ءَامِنُواْ بِرَبِّكُمۡ فَـَٔامَنَّاۚ رَبَّنَا فَٱغۡفِرۡ لَنَا ذُنُوبَنَا وَكَفِّرۡ عَنَّا سَيِّـَٔاتِنَا وَتَوَفَّنَا مَعَ ٱلۡأَبۡرَارِ", transliteration: "Rabbanaaa innanaa sami'naa munaadiyai yunaadee lil eemaani an aaminoo bi Rabbikum fa aamannaa", translation: "Our Lord, indeed we heard a caller calling to faith, saying, Believe in your Lord, and we have believed.", reference: "3:193"),
            DuaItem(arabicText: "رَّبَّنَآ إِنَّنَا سَمِعۡنَا مُنَادِيٗا يُنَادِي لِلۡإِيمَٰنِ أَنۡ ءَامِنُواْ بِرَبِّكُمۡ فَـَٔامَنَّاۚ رَبَّنَا فَٱغۡفِرۡ لَنَا ذُنُوبَنَا وَكَفِّرۡ عَنَّا سَيِّـَٔاتِنَا وَتَوَفَّنَا مَعَ ٱلۡأَبۡرَارِ", transliteration: "Rabbanaa faghfir lanaa zunoobanaa wa kaffir 'annaa saiyi aatina wa tawaffanaa ma'al abraar", translation: "Our Lord, forgive us our sins, remove from us our misdeeds, and cause us to die among the righteous.", reference: "3:193"),
            DuaItem(arabicText: "رَبَّنَا وَءَاتِنَا مَا وَعَدتَّنَا عَلَىٰ رُسُلِكَ وَلَا تُخۡزِنَا يَوۡمَ ٱلۡقِيَٰمَةِۖ إِنَّكَ لَا تُخۡلِفُ ٱلۡمِيعَادَ", transliteration: "Rabbanaa wa aatinaa maa wa'attanaa 'alaa Rusulika wa laa tukhzinaa Yawmal Qiyaamah; innaka laa tukhliful mee'aad", translation: "Our Lord, grant us what You promised through Your messengers and do not disgrace us on the Day of Resurrection. Indeed, You do not fail in promise.", reference: "3:194"),
            DuaItem(arabicText: "وَإِذَا سَمِعُواْ مَآ أُنزِلَ إِلَى ٱلرَّسُولِ تَرَىٰٓ أَعۡيُنَهُمۡ تَفِيضُ مِنَ ٱلدَّمۡعِ مِمَّا عَرَفُواْ مِنَ ٱلۡحَقِّۖ يَقُولُونَ رَبَّنَآ ءَامَنَّا فَٱكۡتُبۡنَا مَعَ ٱلشَّٰهِدِينَ", transliteration: "Rabbanaaa aamannaa faktubnaa ma'ash shaahideen", translation: "Our Lord, we have believed, so register us among the witnesses.", reference: "5:83"),
            DuaItem(arabicText: "قَالَ عِيسَى ٱبۡنُ مَرۡيَمَ ٱللَّهُمَّ رَبَّنَآ أَنزِلۡ عَلَيۡنَا مَآئِدَةٗ مِّنَ ٱلسَّمَآءِ تَكُونُ لَنَا عِيدٗا لِّأَوَّلِنَا وَءَاخِرِنَا وَءَايَةٗ مِّنكَۖ وَٱرۡزُقۡنَا وَأَنتَ خَيۡرُ ٱلرَّٰزِقِينَ", transliteration: "Rabbanaaa anzil 'alainaa maaa'idatam minas samaaa'i takoonu lanaa 'eedal li awwalinaa wa aakhirinaa wa Aayatam minka warzuqnaa wa Anta khairur raaziqeen", translation: "O Allah, our Lord, send down to us a table from heaven to be a festival and a sign from You. Provide for us, and You are the best of providers.", reference: "5:114"),
            DuaItem(arabicText: "قَالَا رَبَّنَا ظَلَمۡنَآ أَنفُسَنَا وَإِن لَّمۡ تَغۡفِرۡ لَنَا وَتَرۡحَمۡنَا لَنَكُونَنَّ مِنَ ٱلۡخَٰسِرِينَ", transliteration: "Rabbanaa zalamnaaa anfusanaa wa illam taghfir lanaa wa tarhamnaa lanakoonanna minal khaasireen", translation: "Our Lord, we have wronged ourselves, and if You do not forgive us and have mercy upon us, we will surely be among the losers.", reference: "7:23"),
            DuaItem(arabicText: "۞ وَإِذَا صُرِفَتۡ أَبۡصَٰرُهُمۡ تِلۡقَآءَ أَصۡحَٰبِ ٱلنَّارِ قَالُواْ رَبَّنَا لَا تَجۡعَلۡنَا مَعَ ٱلۡقَوۡمِ ٱلظَّٰلِمِينَ", transliteration: "Rabbanaa laa taj'alnaa ma'al qawmiz zaalimeen", translation: "Our Lord, do not place us with the wrongdoing people.", reference: "7:47"),
            DuaItem(arabicText: "قَدِ ٱفۡتَرَيۡنَا عَلَى ٱللَّهِ كَذِبًا إِنۡ عُدۡنَا فِي مِلَّتِكُم بَعۡدَ إِذۡ نَجَّىٰنَا ٱللَّهُ مِنۡهَاۚ وَمَا يَكُونُ لَنَآ أَن نَّعُودَ فِيهَآ إِلَّآ أَن يَشَآءَ ٱللَّهُ رَبُّنَاۚ وَسِعَ رَبُّنَا كُلَّ شَيۡءٍ عِلۡمًاۚ عَلَى ٱللَّهِ تَوَكَّلۡنَاۚ رَبَّنَا ٱفۡتَحۡ بَيۡنَنَا وَبَيۡنَ قَوۡمِنَا بِٱلۡحَقِّ وَأَنتَ خَيۡرُ ٱلۡفَٰتِحِينَ", transliteration: "Rabbanaf-tah bainana wa baina qawmina bil haqqi wa anta Khairul Fatiheen", translation: "Our Lord, decide between us and our people in truth, and You are the best of those who give decision.", reference: "7:89"),
            DuaItem(arabicText: "وَمَا تَنقِمُ مِنَّآ إِلَّآ أَنۡ ءَامَنَّا بِـَٔايَٰتِ رَبِّنَا لَمَّا جَآءَتۡنَاۚ رَبَّنَآ أَفۡرِغۡ عَلَيۡنَا صَبۡرٗا وَتَوَفَّنَا مُسۡلِمِينَ", transliteration: "Rabbanaaa afrigh 'alainaa sabranw wa tawaffanaa muslimeen", translation: "Our Lord, pour upon us patience and let us die as Muslims in submission to You.", reference: "7:126"),
            DuaItem(arabicText: "فَقَالُواْ عَلَى ٱللَّهِ تَوَكَّلۡنَا رَبَّنَا لَا تَجۡعَلۡنَا فِتۡنَةٗ لِّلۡقَوۡمِ ٱلظَّٰلِمِينَ وَنَجِّنَا بِرَحۡمَتِكَ مِنَ ٱلۡقَوۡمِ ٱلۡكَٰفِرِينَ", transliteration: "Rabbana la taj'alna fitnatal lil-qawmidh-Dhalimeen; wa najjina bi-Rahmatika minal qawmil kafireen", translation: "Our Lord, make us not objects of trial for the wrongdoing people, and save us by Your mercy from the disbelieving people.", reference: "10:85-86"),
            DuaItem(arabicText: "رَبَّنَآ إِنَّكَ تَعۡلَمُ مَا نُخۡفِي وَمَا نُعۡلِنُۗ وَمَا يَخۡفَىٰ عَلَى ٱللَّهِ مِن شَيۡءٖ فِي ٱلۡأَرۡضِ وَلَا فِي ٱلسَّمَآءِ", transliteration: "Rabbanaaa innaka ta'lamu maa nukhfee wa maa nu'lin; wa maa yakhfaa 'alal laahi min shai'in fil ardi wa laa fis samaaa", translation: "Our Lord, indeed You know what we conceal and what we declare, and nothing is hidden from Allah on the earth or in the heaven.", reference: "14:38"),
            DuaItem(arabicText: "رَبِّ ٱجۡعَلۡنِي مُقِيمَ ٱلصَّلَوٰةِ وَمِن ذُرِّيَّتِيۚ رَبَّنَا وَتَقَبَّلۡ دُعَآءِ", transliteration: "Rabbij 'alnee muqeemas Salaati wa min zurriyyatee Rabbanaa wa taqabbal du'aaa", translation: "My Lord, make me an establisher of prayer, and many from my descendants. Our Lord, accept my supplication.", reference: "14:40"),
            DuaItem(arabicText: "رَبَّنَا ٱغۡفِرۡ لِي وَلِوَٰلِدَيَّ وَلِلۡمُؤۡمِنِينَ يَوۡمَ يَقُومُ ٱلۡحِسَابُ", transliteration: "Rabbanagh fir lee wa liwaalidaiya wa lilmu'mineena Yawma yaqoomul hisaab", translation: "Our Lord, forgive me and my parents and the believers the Day the account is established.", reference: "14:41"),
            DuaItem(arabicText: "إِذۡ أَوَى ٱلۡفِتۡيَةُ إِلَى ٱلۡكَهۡفِ فَقَالُواْ رَبَّنَآ ءَاتِنَا مِن لَّدُنكَ رَحۡمَةٗ وَهَيِّئۡ لَنَا مِنۡ أَمۡرِنَا رَشَدٗا", transliteration: "Rabbanaaa aatinaa mil ladunka rahmatanw wa haiyi' lanaa min amrinaa rashadaa", translation: "Our Lord, grant us mercy from Yourself and prepare for us right guidance in our affair.", reference: "18:10"),
            DuaItem(arabicText: "قَالَا رَبَّنَآ إِنَّنَا نَخَافُ أَن يَفۡرُطَ عَلَيۡنَآ أَوۡ أَن يَطۡغَىٰ", transliteration: "Rabbanaaa innanaa nakhaafu ai yafruta 'alainaaa aw ai yatghaa", translation: "Our Lord, indeed we are afraid that he will hasten punishment against us or that he will transgress.", reference: "20:45"),
            DuaItem(arabicText: "إِنَّهُۥ كَانَ فَرِيقٞ مِّنۡ عِبَادِي يَقُولُونَ رَبَّنَآ ءَامَنَّا فَٱغۡفِرۡ لَنَا وَٱرۡحَمۡنَا وَأَنتَ خَيۡرُ ٱلرَّٰحِمِينَ", transliteration: "Rabbanaaa aamannaa faghfir lanaa warhamnaa wa Anta khairur raahimeen", translation: "Our Lord, we have believed, so forgive us and have mercy upon us, and You are the best of the merciful.", reference: "23:109"),
            DuaItem(arabicText: "وَٱلَّذِينَ يَقُولُونَ رَبَّنَا ٱصۡرِفۡ عَنَّا عَذَابَ جَهَنَّمَۖ إِنَّ عَذَابَهَا كَانَ غَرَامًا إِنَّهَا سَآءَتۡ مُسۡتَقَرّٗا وَمُقَامٗا", transliteration: "Rabbanas rif 'annnaa 'azaaba Jahannama inn 'azaabahaa kaana gharaamaa; innahaa saaa'at mustaqarranw wa muqaamaa", translation: "Our Lord, avert from us the punishment of Hell. Indeed, its punishment is ever adhering; indeed, it is evil as a settlement and residence.", reference: "25:65-66"),
            DuaItem(arabicText: "وَٱلَّذِينَ يَقُولُونَ رَبَّنَا هَبۡ لَنَا مِنۡ أَزۡوَٰجِنَا وَذُرِّيَّٰتِنَا قُرَّةَ أَعۡيُنٖ وَٱجۡعَلۡنَا لِلۡمُتَّقِينَ إِمَامًا", transliteration: "Rabbanaa hab lanaa min azwaajinaa wa zurriyaatinaa qurrata a'yuninw waj'alnaa lilmuttaqeena Imaamaa", translation: "Our Lord, grant us from among our spouses and offspring comfort to our eyes and make us an example for the righteous.", reference: "25:74"),
            DuaItem(arabicText: "وَقَالُواْ ٱلۡحَمۡدُ لِلَّهِ ٱلَّذِيٓ أَذۡهَبَ عَنَّا ٱلۡحَزَنَۖ إِنَّ رَبَّنَا لَغَفُورٞ شَكُورٌ", transliteration: "Rabbana la Ghafurun shakur", translation: "Our Lord is Forgiving and Appreciative.", reference: "35:34"),
            DuaItem(arabicText: "ٱلَّذِينَ يَحۡمِلُونَ ٱلۡعَرۡشَ وَمَنۡ حَوۡلَهُۥ يُسَبِّحُونَ بِحَمۡدِ رَبِّهِمۡ وَيُؤۡمِنُونَ بِهِۦ وَيَسۡتَغۡفِرُونَ لِلَّذِينَ ءَامَنُواْۖ رَبَّنَا وَسِعۡتَ كُلَّ شَيۡءٖ رَّحۡمَةٗ وَعِلۡمٗا فَٱغۡفِرۡ لِلَّذِينَ تَابُواْ وَٱتَّبَعُواْ سَبِيلَكَ وَقِهِمۡ عَذَابَ ٱلۡجَحِيمِ", transliteration: "Rabbanaa wasi'ta kulla shai'ir rahmatanw wa 'ilman faghfir lillazeena taaboo wattaba'oo sabeelaka wa qihim 'azaabal Jaheem", translation: "Our Lord, You have encompassed all things in mercy and knowledge, so forgive those who repent and follow Your way, and protect them from the punishment of Hellfire.", reference: "40:7"),
            DuaItem(arabicText: "رَبَّنَا وَأَدۡخِلۡهُمۡ جَنَّٰتِ عَدۡنٍ ٱلَّتِي وَعَدتَّهُمۡ وَمَن صَلَحَ مِنۡ ءَابَآئِهِمۡ وَأَزۡوَٰجِهِمۡ وَذُرِّيَّٰتِهِمۡۚ إِنَّكَ أَنتَ ٱلۡعَزِيزُ ٱلۡحَكِيمُ وَقِهِمُ ٱلسَّيِّـَٔاتِۚ وَمَن تَقِ ٱلسَّيِّـَٔاتِ يَوۡمَئِذٖ فَقَدۡ رَحِمۡتَهُۥۚ وَذَٰلِكَ هُوَ ٱلۡفَوۡزُ ٱلۡعَظِيمُ", transliteration: "Rabbana wa adhkhilhum Jannati 'adninil-lati wa'attahum wa man salaha min aba'ihim wa azwajihim wa dhuriyyatihim innaka antal 'Azizul-Hakim, waqihimus saiyi'at", translation: "Our Lord, admit them to gardens of perpetual residence which You promised them, and whoever was righteous among their forefathers, spouses, and offspring. Indeed, You are the Exalted in Might, the Wise. Protect them from evil consequences.", reference: "40:8-9"),
            DuaItem(arabicText: "وَٱلَّذِينَ جَآءُو مِنۢ بَعۡدِهِمۡ يَقُولُونَ رَبَّنَا ٱغۡفِرۡ لَنَا وَلِإِخۡوَٰنِنَا ٱلَّذِينَ سَبَقُونَا بِٱلۡإِيمَٰنِ وَلَا تَجۡعَلۡ فِي قُلُوبِنَا غِلّٗا لِّلَّذِينَ ءَامَنُواْ رَبَّنَآ إِنَّكَ رَءُوفٞ رَّحِيمٌ", transliteration: "Rabbanagh fir lanaa wa li ikhwaani nal lazeena sabqoonaa bil eemaani wa laa taj'al fee quloobinaa ghillalil lazeena aamanoo", translation: "Our Lord, forgive us and our brothers who preceded us in faith, and put not in our hearts resentment toward those who have believed.", reference: "59:10"),
            DuaItem(arabicText: "وَٱلَّذِينَ جَآءُو مِنۢ بَعۡدِهِمۡ يَقُولُونَ رَبَّنَا ٱغۡفِرۡ لَنَا وَلِإِخۡوَٰنِنَا ٱلَّذِينَ سَبَقُونَا بِٱلۡإِيمَٰنِ وَلَا تَجۡعَلۡ فِي قُلُوبِنَا غِلّٗا لِّلَّذِينَ ءَامَنُواْ رَبَّنَآ إِنَّكَ رَءُوفٞ رَّحِيمٌ", transliteration: "Rabbannaaa innaka Ra'oofur Raheem", translation: "Our Lord, indeed You are Kind and Merciful.", reference: "59:10"),
            DuaItem(arabicText: "قَدۡ كَانَتۡ لَكُمۡ أُسۡوَةٌ حَسَنَةٞ فِيٓ إِبۡرَٰهِيمَ وَٱلَّذِينَ مَعَهُۥٓ إِذۡ قَالُواْ لِقَوۡمِهِمۡ إِنَّا بُرَءَآءُ مِنكُمۡ وَمِمَّا تَعۡبُدُونَ مِن دُونِ ٱللَّهِ كَفَرۡنَا بِكُمۡ وَبَدَا بَيۡنَنَا وَبَيۡنَكُمُ ٱلۡعَدَٰوَةُ وَٱلۡبَغۡضَآءُ أَبَدًا حَتَّىٰ تُؤۡمِنُواْ بِٱللَّهِ وَحۡدَهُۥٓ إِلَّا قَوۡلَ إِبۡرَٰهِيمَ لِأَبِيهِ لَأَسۡتَغۡفِرَنَّ لَكَ وَمَآ أَمۡلِكُ لَكَ مِنَ ٱللَّهِ مِن شَيۡءٖۖ رَّبَّنَا عَلَيۡكَ تَوَكَّلۡنَا وَإِلَيۡكَ أَنَبۡنَا وَإِلَيۡكَ ٱلۡمَصِيرُ", transliteration: "Rabbanaa 'alaika tawakkalnaa wa ilaika anabnaa wa ilaikal maseer", translation: "Our Lord, upon You we have relied, to You we have returned, and to You is the destination.", reference: "60:4"),
            DuaItem(arabicText: "رَبَّنَا لَا تَجۡعَلۡنَا فِتۡنَةٗ لِّلَّذِينَ كَفَرُواْ وَٱغۡفِرۡ لَنَا رَبَّنَآۖ إِنَّكَ أَنتَ ٱلۡعَزِيزُ ٱلۡحَكِيمُ", transliteration: "Rabbana laa taj'alnaa fitnatal lillazeena kafaroo waghfir lanaa rabbanaaa innaka antal azeezul hakeem", translation: "Our Lord, make us not objects of trial for those who disbelieve and forgive us, our Lord. Indeed, You are the Exalted in Might, the Wise.", reference: "60:5"),
            DuaItem(arabicText: "يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُواْ تُوبُوٓاْ إِلَى ٱللَّهِ تَوۡبَةٗ نَّصُوحًا عَسَىٰ رَبُّكُمۡ أَن يُكَفِّرَ عَنكُمۡ سَيِّـَٔاتِكُمۡ وَيُدۡخِلَكُمۡ جَنَّٰتٖ تَجۡرِي مِن تَحۡتِهَا ٱلۡأَنۡهَٰرُ يَوۡمَ لَا يُخۡزِي ٱللَّهُ ٱلنَّبِيَّ وَٱلَّذِينَ ءَامَنُواْ مَعَهُۥۖ نُورُهُمۡ يَسۡعَىٰ بَيۡنَ أَيۡدِيهِمۡ وَبِأَيۡمَٰنِهِمۡ يَقُولُونَ رَبَّنَآ أَتۡمِمۡ لَنَا نُورَنَا وَٱغۡفِرۡ لَنَآۖ إِنَّكَ عَلَىٰ كُلِّ شَيۡءٖ قَدِيرٞ", transliteration: "Rabbanaaa atmim lanaa nooranaa waghfir lana innaka 'alaa kulli shai'in qadeer", translation: "Our Lord, perfect for us our light and forgive us. Indeed, You are over all things competent.", reference: "66:8")
        ]
    )
}

private struct DuaReflectionCard: View {
    let title: String
    let lines: [String]
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(accent)

            ForEach(lines, id: \.self) { line in
                Text("• \(line)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.secondary.opacity(0.1))
        )
        .padding(-4)
    }
}

#Preview {
    AlIslamPreviewContainer {
        DuaView()
    }
}
