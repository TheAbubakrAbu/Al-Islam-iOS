import SwiftUI

struct PillarsView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
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
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Pillars & Beliefs")
    }
}

/// The practical "how-to" companion to `PillarsView`: step-by-step guides to the acts of worship.
/// A quoted ayah or hadith in the Beliefs and How-to guides: the larger accented text every guide uses,
/// now one reusable view with a context menu to copy the full quote - source included (the citation is
/// part of the text itself, e.g. "(Quran 2:43)" or "(Sahih al-Bukhari 631)").
struct ScriptureQuote: View {
    @ObservedObject private var settings = Settings.shared

    let text: String
    /// Hadith quotes render slightly softened (0.85 opacity) so ayat keep the fullest accent.
    var dimmed: Bool = false

    var body: some View {
        let quote = Text(text)
            .font(.title3)
            .foregroundColor(settings.accentColor.color.opacity(dimmed ? 0.85 : 1))
        #if os(iOS)
        quote
            .contextMenu {
                Text("Copy")
                    .foregroundStyle(.secondary)

                Button {
                    settings.hapticFeedback()
                    UIPasteboard.general.string = text
                } label: {
                    Label("Copy Quote", systemImage: "doc.on.doc")
                }
            }
        #else
        quote
        #endif
    }
}

struct GuidesView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("HOW TO WORSHIP")) {
                    guideLink("How to Pray (Salah)", destination: HowToPrayView())
                    guideLink("How to Fast (Sawm)", destination: HowToFastView())
                    guideLink("How to Give Zakah", destination: HowToZakahView())
                    guideLink("How to Perform Hajj", destination: HowToHajjView())
                    guideLink("How to Perform Umrah", destination: HowToUmrahView())
                }

                Section(header: Text("PURIFICATION & PRAYER")) {
                    guideLink("How to Make Wudhu", destination: WudhuView())
                    guideLink("How to Make Ghusl", destination: GhuslView())
                    guideLink("How to Pray Jumuah", destination: JumuahView())
                    guideLink("How to Give the Adhan", destination: AdhanOtherView())
                    guideLink("How to Give the Iqamah", destination: IqamahView())
                }

                Section(header: Text("EID")) {
                    guideLink("How to Pray Eid", destination: TakbiratView())
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("How-To Guides")
    }

    // @autoclosure so call sites keep reading naturally while the destination struct is only ever
    // constructed when the row is actually pushed (see LazyDestination).
    private func guideLink<Destination: View>(_ title: String, destination: @autoclosure @escaping () -> Destination) -> some View {
        NavigationLink(destination: LazyDestination(build: destination)) {
            Text(title)
                .font(.subheadline)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - How-to guides (practical, step-by-step)

/// Further practical reading for a guide - links that actually explain HOW to perform the act (IslamQA
/// answers and the like). Deliberately NOT a bibliography: the Quran verses and hadiths that ground a guide
/// are quoted inside the guide's own text, where the reader is, not stashed behind reference links.
struct GuideSourcesSection: View {
    @ObservedObject private var settings = Settings.shared

    let sources: [(title: String, subtitle: String, url: String)]

    var body: some View {
        Section {
            ForEach(sources, id: \.url) { source in
                if let url = URL(string: source.url) {
                    Link(destination: url) {
                        HStack(spacing: 10) {
                            Image(systemName: "book.closed")
                                .font(.footnote)
                                .foregroundColor(settings.accentColor.color)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(source.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.primary)

                                Text(source.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer(minLength: 4)

                            Image(systemName: "arrow.up.right")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        } header: {
            Text("SOURCES & FURTHER READING")
        } footer: {
            Text("Every ruling above traces back to the Quran and the authentic Sunnah. These links open the sources themselves - read them, and ask a qualified scholar about anything specific to your situation.")
        }
    }
}

struct HowToPrayView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: prayer (**Salah, صَلَاة**) is performed facing the Qibla after purifying yourself, moving through standing, bowing, and prostrating while reciting the Quran and remembering Allah - praying as the Prophet (peace and blessings be upon him) prayed.")
                        .font(.body)
                }

                Section(header: Text("BEFORE YOU PRAY")) {
                    Text("1. **Purity (Taharah, طَهَارَة)**: have valid **Wudhu (وُضُوء)** - or Ghusl if required - with a clean body, clothes, and place of prayer.").font(.body)
                    Text("2. **Cover the Awrah (عَورَة)**: men from the navel to the knee at least; women cover everything except the face and hands.").font(.body)
                    Text("3. **Face the Qibla (قِبلَة)**: the direction of the Kaaba in Makkah.").font(.body)
                    Text("4. **Correct time**: each prayer has its own window - Fajr, Dhuhr, Asr, Maghrib, and Isha.").font(.body)
                    Text("5. **Intention (Niyyah, نِيَّة)**: intend the specific prayer in the heart - it is not spoken aloud.").font(.body)
                }

                Section(header: Text("NUMBER OF UNITS (RAKAH)")) {
                    Text("The obligatory **rak'ah (رَكعَة)** are: **Fajr** 2 · **Dhuhr** 4 · **Asr** 4 · **Maghrib** 3 · **Isha** 4.")
                        .font(.body)
                }

                Section(header: Text("STEP BY STEP")) {
                    Text("The Prophet (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“Pray as you have seen me praying” (Sahih al-Bukhari 631).", dimmed: true)
                    Text("1. **Takbir (تَكبِير)**: raise the hands and say “Allahu Akbar,” then place the right hand over the left upon the chest.").font(.body)
                    Text("2. **Recitation**: say the opening supplication, then recite Surah **Al-Fatiha (الفَاتِحَة)** - required in every rak'ah - followed by another passage of the Quran in the first two rak'ah.").font(.body)
                    Text("3. **Ruku (رُكُوع)**: bow with a straight back, hands on the knees, saying “Subhana Rabbi al-Adheem” three times.").font(.body)
                    Text("4. **Rising (I'tidal)**: rise saying “Sami'a Allahu liman hamidah,” then, standing, “Rabbana wa laka al-hamd.”").font(.body)
                    Text("5. **Sujud (سُجُود)**: prostrate on seven parts - the forehead and nose, both palms, both knees, and the toes - saying “Subhana Rabbi al-A'la” three times.").font(.body)
                    Text("6. **Sit** and say “Rabbi ighfir li,” then make a second **Sujud** the same way. This completes one rak'ah - stand for the next.").font(.body)
                    Text("7. **Tashahhud (تَشَهُّد)**: after every two rak'ah, sit and recite the tashahhud; in the final sitting add the prayers upon the Prophet (peace and blessings be upon him) and supplication.").font(.body)
                    Text("8. **Taslim (تَسلِيم)**: end the prayer by turning the face to the right, then the left, saying each time “As-salamu alaykum wa rahmatullah.”").font(.body)
                }

                Section(header: Text("THE COMMAND TO PRAY")) {
                    Text("Allah (Glorified and Exalted be He) says:")
                        .font(.body)
                    ScriptureQuote(text: "“And establish prayer and give zakah and bow with those who bow” (Quran 2:43).")

                    ScriptureQuote(text: "“Indeed, prayer has been decreed upon the believers a decree of specified times” (Quran 4:103).")

                    ScriptureQuote(text: "“Maintain with care the [obligatory] prayers and [in particular] the middle prayer and stand before Allah, devoutly obedient” (Quran 2:238).")

                    ScriptureQuote(text: "“Indeed, prayer prohibits immorality and wrongdoing, and the remembrance of Allah is greater” (Quran 29:45).")
                }

                Section(header: Text("ITS PLACE AND ITS WEIGHT")) {
                    Text("The prayer is the first thing a person will be asked about. The Prophet (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“The first thing for which a person will be brought to account on the Day of Resurrection is his prayer. If it is sound, he will have prospered and succeeded; and if it is unsound, he will have failed and lost” (Sunan al-Tirmidhi 413).", dimmed: true)

                    Text("It is the line between belief and disbelief:")
                        .font(.body)
                    ScriptureQuote(text: "“Between a man and shirk and kufr is the abandonment of prayer” (Sahih Muslim 82).", dimmed: true)

                    Text("And it washes a person clean:")
                        .font(.body)
                    ScriptureQuote(text: "“If there was a river at the door of any of you, and he bathed in it five times a day, would any dirt remain on him? They said: No dirt would remain on him. He said: That is the example of the five daily prayers; by them Allah wipes away sins” (Sahih al-Bukhari 528, Sahih Muslim 667).", dimmed: true)

                    Text("Praying in congregation multiplies it further:")
                        .font(.body)
                    ScriptureQuote(text: "“Prayer in congregation is twenty-seven times superior to the prayer offered by a person alone” (Sahih al-Bukhari 645, Sahih Muslim 650).", dimmed: true)

                    Text("And its calm is a mercy. The Prophet (peace and blessings be upon him) would say to Bilal: “Call the prayer, O Bilal, and give us comfort by it” (Sunan Abi Dawud 4985).")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Purify yourself, face the Qibla, and pray with presence of heart - Takbir, Fatiha, Ruku, Sujud, Tashahhud, and Taslim - exactly as the Prophet (peace and blessings be upon him) taught.")
                        .font(.body)
                }

                GuideSourcesSection(sources: [
                    (title: "How to Pray: Description of the Prophet's Prayer", subtitle: "Step-by-step guide, IslamQA", url: "https://islamqa.info/en/answers/13340"),
                ])
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("How to Pray")
    }
}

struct HowToFastView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: to fast (**Sawm, صَوم**) is to abstain from food, drink, and intimacy from dawn (**Fajr**) to sunset (**Maghrib**) with the intention of seeking Allah's pleasure - especially in Ramadan.")
                        .font(.body)
                }

                Section(header: Text("1. MAKE THE INTENTION")) {
                    Text("Form the **Niyyah (نِيَّة)** to fast in the heart before **Fajr**. For an obligatory Ramadan fast, intend it the night before.")
                        .font(.body)
                }

                Section(header: Text("2. EAT SUHOOR")) {
                    Text("Take the pre-dawn meal, **Suhoor (سُحُور)**, which is a blessed Sunnah, and stop eating and drinking at the entry of **Fajr**.").font(.body)
                    Text("The Prophet (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“Take Suhoor, for in Suhoor there is a blessing” (Sahih al-Bukhari 1923).", dimmed: true)
                }

                Section(header: Text("3. FAST THROUGH THE DAY")) {
                    Text("From Fajr to Maghrib, abstain from food, drink, and intimacy. The fast is also of the limbs and tongue: guard against lying, backbiting, and anger.").font(.body)
                    Text("The Prophet (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“Whoever does not give up false speech and acting upon it, Allah has no need of his giving up his food and drink” (Sahih al-Bukhari 1903).", dimmed: true)
                }

                Section(header: Text("4. BREAK THE FAST AT MAGHRIB")) {
                    Text("Break the fast (**Iftar, إِفطَار**) as soon as the sun sets, hastening it as the Sunnah - traditionally with fresh or dried dates and water, then supplicate, for the fasting person's dua at Iftar is answered.")
                        .font(.body)
                }

                Section(header: Text("WHAT INVALIDATES THE FAST")) {
                    Text("Deliberately eating or drinking, intentional intimacy, and the onset of menstruation or postpartum bleeding break the fast. Eating or drinking by genuine forgetfulness does not - one simply continues fasting.")
                        .font(.body)
                }

                Section(header: Text("WHO IS EXCUSED")) {
                    Text("The sick, travelers, pregnant and nursing women, and the elderly who cannot fast are excused; missed fasts are made up later, or a **Fidyah (فِديَة)** (feeding a needy person per day) is given by those unable to fast at all.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Intend the fast, take Suhoor, abstain from dawn to sunset while guarding your character, then hasten to break the fast at Maghrib - turning the whole day into worship and gratitude.")
                        .font(.body)
                }

                Section(header: Text("WHY WE FAST")) {
                    Text("Allah (Glorified and Exalted be He) says:")
                        .font(.body)
                    ScriptureQuote(text: "“O you who have believed, decreed upon you is fasting as it was decreed upon those before you, that you may become righteous” (Quran 2:183).")
                    ScriptureQuote(text: "“The month of Ramadan [is that] in which was revealed the Quran, a guidance for the people and clear proofs of guidance and criterion” (Quran 2:185).")
                    Text("The Prophet (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Allah said: Every deed of the son of Adam is for him, except fasting; it is for Me, and I shall reward for it” (Sahih al-Bukhari 1904, Sahih Muslim 1151).", dimmed: true)
                    ScriptureQuote(text: "“Whoever fasts Ramadan out of faith and seeking reward, his previous sins will be forgiven” (Sahih al-Bukhari 38, Sahih Muslim 760).", dimmed: true)
                    ScriptureQuote(text: "“There is a gate in Paradise called Ar-Rayyan, through which those who fast will enter on the Day of Resurrection, and no one but they will enter it” (Sahih al-Bukhari 1896).", dimmed: true)
                    Text("And fasting is not of the stomach alone. He said: “Whoever does not give up false speech and acting upon it, Allah has no need of him giving up his food and drink” (Sahih al-Bukhari 1903).")
                        .font(.body)
                }

                GuideSourcesSection(sources: [
                    (title: "Rulings on Fasting", subtitle: "How to fast, and what breaks it, IslamQA", url: "https://islamqa.info/en/categories/topics/78/fasting"),
                ])
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("How to Fast")
    }
}

struct HowToZakahView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: **Zakah (زَكَاة)** is the obligatory annual charity of **2.5%** on wealth that reaches the **Nisab (نِصَاب)** and is held for a full lunar year, given to those Allah named as its recipients.")
                        .font(.body)
                }

                Section(header: Text("1. CHECK IF YOU MUST PAY")) {
                    Text("Zakah is due on a Muslim whose zakatable wealth reaches the **Nisab (نِصَاب)** - the minimum threshold, equal to about **85 grams of gold** or **595 grams of silver** - and has been held for one full lunar (Hijri) year (**Hawl, حَول**).")
                        .font(.body)
                }

                Section(header: Text("2. TOTAL YOUR ZAKATABLE WEALTH")) {
                    Text("Include cash and savings, gold and silver, money owed to you that you expect back, business merchandise, and investments held for gain. Personal items - your home, car, and everyday belongings - are not counted.")
                        .font(.body)
                }

                Section(header: Text("3. CALCULATE 2.5%")) {
                    Text("If your total is at or above the Nisab after the year has passed, give **2.5%** (one fortieth) of it. Many choose to pay in Ramadan for the extra reward, though it may be paid whenever the year completes.")
                        .font(.body)
                }

                Section(header: Text("4. GIVE IT TO THOSE ENTITLED")) {
                    Text("Allah (Glorified and Exalted be He) named eight categories of recipients:").font(.body)
                    ScriptureQuote(text: "“Zakah expenditures are only for the poor and for the needy and for those employed to collect [it] and for bringing hearts together [for Islam] and for freeing captives [or slaves] and for those in debt and for the cause of Allah and for the [stranded] traveler” (Quran 9:60).")
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Once your wealth reaches the Nisab and a lunar year passes, give 2.5% of it to the deserving - purifying your wealth, helping the needy, and fulfilling a pillar of Islam.")
                        .font(.body)
                }

                Section(header: Text("WHY WE GIVE ZAKAH")) {
                    Text("Allah (Glorified and Exalted be He) says:")
                        .font(.body)
                    ScriptureQuote(text: "“Take from their wealth a charity by which you purify them and cause them increase, and invoke [Allah's blessings] upon them” (Quran 9:103).")
                    ScriptureQuote(text: "“And establish prayer and give zakah, and whatever good you put forward for yourselves, you will find it with Allah” (Quran 2:110).")
                    Text("It is not a favour to the poor. It is their right in your wealth, and withholding it is a warning:")
                        .font(.body)
                    ScriptureQuote(text: "“And let not those who [greedily] withhold what Allah has given them of His bounty ever think that it is better for them. Rather, it is worse for them. Their necks will be encircled by what they withheld on the Day of Resurrection” (Quran 3:180).")
                    Text("When the Prophet (peace and blessings be upon him) sent Mu'adh to Yemen, he told him:")
                        .font(.body)
                    ScriptureQuote(text: "“Teach them that Allah has enjoined upon them a charity to be taken from their rich and given to their poor” (Sahih al-Bukhari 1395, Sahih Muslim 19).", dimmed: true)
                    Text("And He named exactly who may receive it: “Zakah expenditures are only for the poor and for the needy and for those employed to collect [zakah] and for bringing hearts together [for Islam] and for freeing captives [or slaves] and for those in debt and for the cause of Allah and for the [stranded] traveler” (Quran 9:60).")
                        .font(.body)
                }

                GuideSourcesSection(sources: [
                    (title: "How to Calculate and Give Zakah", subtitle: "Nisab, rates, and recipients, IslamQA", url: "https://islamqa.info/en/categories/topics/79/zakah"),
                ])
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("How to Give Zakah")
    }
}

struct HowToHajjView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: **Hajj (حَجّ)** is the pilgrimage to Makkah performed once in a lifetime by those able, over the days of **Dhul-Hijjah** - entering Ihram, standing at Arafah, and completing the rites the Prophet (peace and blessings be upon him) taught.")
                        .font(.body)
                }

                Section(header: Text("BEFORE YOU GO")) {
                    Text("Hajj is obligatory once for every Muslim who is physically and financially able. Repent sincerely, settle debts, seek lawful provision, and learn the rites. Hajj takes place from the 8th to the 13th of **Dhul-Hijjah (ذُو الحِجَّة)**.")
                        .font(.body)
                }

                Section(header: Text("1. ENTER IHRAM")) {
                    Text("At the appointed boundary (**Miqat, مِيقَات**), bathe, wear the Ihram garments (two unstitched cloths for men; ordinary modest dress for women), make the intention for Hajj, and begin the **Talbiyah (تَلبِيَة)**: “Labbayk Allahumma labbayk…”")
                        .font(.body)
                }

                Section(header: Text("2. DAY 8 - MINA")) {
                    Text("Travel to **Mina (مِنَى)** and pray Dhuhr, Asr, Maghrib, Isha, and Fajr there, each at its time (the four-unit prayers shortened to two).")
                        .font(.body)
                }

                Section(header: Text("3. DAY 9 - ARAFAH")) {
                    Text("After sunrise proceed to **Arafah (عَرَفَة)** and stand there in supplication until sunset - this standing (**Wuquf**) is the essence of Hajj. Dhuhr and Asr are combined and shortened. The Prophet (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“Hajj is Arafah” (Sunan al-Tirmidhi 889).", dimmed: true)
                    Text("After sunset, move to **Muzdalifah (مُزدَلِفَة)**, combine Maghrib and Isha, rest for the night, and gather pebbles.").font(.body)
                }

                Section(header: Text("4. DAY 10 - EID (YAWM AN-NAHR)")) {
                    Text("Stone the large pillar (**Jamrat al-Aqabah**) with seven pebbles, offer the sacrifice (**Hady/Qurbani, قُربَان**), shave or trim the hair, then perform **Tawaf al-Ifadah** around the Kaaba and **Sa'i (سَعي)** between Safa and Marwah. With this the pilgrim exits Ihram.")
                        .font(.body)
                }

                Section(header: Text("5. DAYS 11–13 - TASHREEQ")) {
                    Text("Stay in Mina and stone the three pillars (**Jamarat**) each afternoon. A pilgrim may leave after the 12th if he departs before sunset, otherwise he completes the 13th.")
                        .font(.body)
                }

                Section(header: Text("6. FAREWELL TAWAF")) {
                    Text("Before leaving Makkah, perform the farewell circumambulation (**Tawaf al-Wada, طَوَاف الوَدَاع**) so the last act at the Sacred House is Tawaf.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Enter Ihram at the Miqat, stand at Arafah, spend the night at Muzdalifah, then on Eid stone, sacrifice, shave, and perform Tawaf and Sa'i - completing the days of Mina and a farewell Tawaf, returning cleansed of sin.")
                        .font(.body)
                }

                GuideSourcesSection(sources: [
                    (title: "How to Perform Hajj: Description of Hajj", subtitle: "Every rite in order, IslamQA", url: "https://islamqa.info/en/answers/31822/description-of-hajj"),
                ])
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("How to Perform Hajj")
    }
}

struct HowToUmrahView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: **Umrah (عُمرَة)** - the “lesser pilgrimage,” which may be done at any time of year - is Ihram, Tawaf around the Kaaba, Sa'i between Safa and Marwah, and shaving or trimming the hair.")
                        .font(.body)
                }

                Section(header: Text("1. ENTER IHRAM")) {
                    Text("At the **Miqat (مِيقَات)**, bathe, wear the Ihram (two unstitched cloths for men; modest dress for women), make the intention for Umrah, and recite the **Talbiyah (تَلبِيَة)**: “Labbayk Allahumma bi-Umrah.” In Ihram, avoid perfume, cutting hair or nails, and marital relations.")
                        .font(.body)
                }

                Section(header: Text("2. TAWAF")) {
                    Text("At the Sacred Mosque, circle the **Kaaba (الكَعبَة)** seven times (**Tawaf, طَوَاف**), beginning and ending at the Black Stone. Then pray two rak'ah behind the **Maqam Ibrahim (مَقَام إِبرَاهِيم)** if able, and drink **Zamzam (زَمزَم)**.")
                        .font(.body)
                }

                Section(header: Text("3. SA'I")) {
                    Text("Walk seven times between the hills of **Safa (الصَّفَا)** and **Marwah (المَروَة)** (**Sa'i, سَعي**), starting at Safa and ending at Marwah, remembering Allah and supplicating - as **Hajar** (may Allah be pleased with her) once searched there for water.")
                        .font(.body)
                }

                Section(header: Text("4. SHAVE OR TRIM")) {
                    Text("Men shave the head (**Halq, حَلق**) or trim it; women trim a fingertip's length (**Taqsir, تَقصِير**). With this the Umrah is complete and the pilgrim leaves the state of Ihram.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Enter Ihram at the Miqat, perform Tawaf around the Kaaba, make Sa'i between Safa and Marwah, and shave or trim - a complete Umrah that may be done any time of the year.")
                        .font(.body)
                }

                Section(header: Text("THE VIRTUE OF UMRAH")) {
                    Text("Allah (Glorified and Exalted be He) says:")
                        .font(.body)
                    ScriptureQuote(text: "“And complete the Hajj and Umrah for Allah” (Quran 2:196).")
                    Text("The Prophet (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Umrah to Umrah is an expiation for whatever comes between them, and the accepted Hajj has no reward but Paradise” (Sahih al-Bukhari 1773, Sahih Muslim 1349).", dimmed: true)
                    ScriptureQuote(text: "“Umrah in Ramadan is equivalent to Hajj” (Sahih al-Bukhari 1782, Sahih Muslim 1256).", dimmed: true)
                    Text("And of the journey itself he said: “Perform Hajj and Umrah consecutively, for they remove poverty and sin as the bellows removes impurity from iron, gold and silver” (Sunan al-Tirmidhi 810).")
                        .font(.body)
                }

                GuideSourcesSection(sources: [
                    (title: "How to Perform Umrah", subtitle: "Ihram, tawaf, sa'i, and cutting the hair, IslamQA", url: "https://islamqa.info/en/answers/154979"),
                ])
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("How to Perform Umrah")
    }
}

import SwiftUI

struct GodPillarView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the existence of God is the foundation of all meaning, morality, and purpose. Reason, evidence, and the natural disposition every person is born with all point to one Creator.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("The question of God's existence is the most important inquiry a person can make. It is the foundation of all meaning, morality, purpose, and accountability. If God exists, then life has objective direction and responsibility. If He does not, then everything - good and evil, justice and injustice, purpose and identity - becomes subjective and ultimately meaningless. Therefore, it is essential to examine this question through reason, evidence, and rational thought.")
                        .font(.body)
                }

                Section(header: Text("THE DOMINO EFFECT FRAMEWORK")) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("The most honest way to approach truth is through a step-by-step method - what can be called the Domino Effect. Each answer leads logically to the next, and no step may be skipped:")
                            .font(.body)
                        Group {
                            Text("• Does a higher power exist at all: something beyond the universe that brought it into being? This comes first. To ask whether God exists is already to assume a great deal about what that power is like.")
                            Text("• If a higher power exists, is it intelligent, or is it blind and random? A random, unthinking cause cannot account for order, information, or purpose.")
                            Text("• If it is intelligent, is it powerful or weak? A weak cause cannot sustain a universe it did not have the power to make.")
                            Text("• An intelligent, powerful, necessary cause is what is meant by God. Only now is the word earned.")
                            Text("• If God exists, is He still involved with creation (theism), or did He create and withdraw (deism)?")
                            Text("• If He is involved, did He send revelation to guide humanity?")
                            Text("• If revelation exists, then one religion must be objectively true.")
                            Text("• If there is one true religion, is it monotheistic or polytheistic?")
                            Text("• If monotheistic, is it exclusive to a specific ethnicity, or universal for all people?")
                            Text("• If universal and monotheistic, only Islam and Christianity remain as candidates.")
                        }
                        .font(.body)
                    }
                }

                Section(header: Text("CHRISTIANITY VS. ISLAM")) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("While Christianity asserts universality, it contains internal contradictions and historical issues:")
                            .font(.body)
                        Group {
                            Text("• The Trinity violates pure monotheism by making God three persons in one essence - an idea that even many Christian scholars admit is a mystery, not a rational doctrine.")
                            Text("• The Bible is not preserved in its original language or form. It is a compilation of human writings over centuries with known alterations.")
                            Text("• Christianity does not offer a consistent position on salvation, works, and belief.")
                        }
                        Text("Islam, on the other hand:")
                            .font(.body)
                        Group {
                            Text("• Affirms absolute monotheism, **Tawhid (تَوحِيد)**, with no partners, no intermediaries, and no confusion.")
                            Text("• Preserves the Quran exactly as it was revealed - verbatim, letter for letter, sound for sound, in its original Arabic.")
                            Text("• Welcomes all of humanity, regardless of ethnicity, race, gender, or background.")
                            Text("• Is the only universal, unambiguous, monotheistic religion with an intellectually sound and preserved foundation.")
                        }
                    }
                }

                Section(header: Text("THE COSMOLOGICAL ARGUMENT")) {
                    Text("Every effect has a cause. The universe began to exist, so it must have had a cause. The Big Bang Theory itself confirms this beginning, but where did the energy come from? What caused it to expand? Who set the laws of physics in motion? The Quran said long ago:")
                        .font(.body)
                    Text("“Have those who disbelieved not considered that the heavens and the earth were a joined entity, and We separated them and made from water every living thing? Then will they not believe?” (Quran 21:30)")
                        .foregroundColor(settings.accentColor.color)
                        .font(.title3)
                    Text("“And the heaven We constructed with strength, and indeed, We are its expander” (Quran 51:47).")
                        .foregroundColor(settings.accentColor.color)
                        .font(.title3)
                    Text("The existence of anything - matter, time, space - requires an uncaused, necessary being beyond the system: Allah (Glorified and Exalted be He).")
                        .font(.body)
                }

                Section(header: Text("ABIOGENESIS – LIFE FROM NON-LIFE?")) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Modern science teaches that the first life (a prokaryotic cell) emerged from non-living chemicals. But this raises serious questions:")
                            .font(.body)
                        Group {
                            Text("• How did non-living matter suddenly become alive?")
                            Text("• How did a cell, containing instructions (DNA), copy itself?")
                            Text("• A single strand of DNA contains more information than any supercomputer - where did this information come from?")
                        }
                        Text("Scientists admit: “We don’t know.” But nothing in our experience tells us that complex, coded systems arise without a mind. The most rational explanation is that life was created intentionally, not randomly.")
                            .font(.body)
                    }
                }

                Section(header: Text("HUMAN INTELLIGENCE – BEYOND EVOLUTION")) {
                    Text("Human beings are orders of magnitude more intelligent than any other creature. Humans build cities, fly planes, write poetry, and explore the universe. They possess self-awareness, language, morality, free will, and the capacity for worship. If evolution alone explains the human brain, why don't other species come close? Why the quantum leap in ability? Human exceptionalism points to a Creator who endowed humanity with reason, **Aql (عَقل)**, a faculty Allah (Glorified and Exalted be He) gave only to humans.")
                        .font(.body)
                    Text("“We have certainly created man in the best of stature” (Quran 95:4).")
                        .foregroundColor(settings.accentColor.color)
                        .font(.title3)
                }

                Section(header: Text("THE FINE-TUNING OF THE UNIVERSE")) {
                    Text("Gravity, electromagnetism, the strong and weak nuclear forces - all must be precisely balanced. If any were off by even a tiny fraction, life could not exist. This is not randomness. It is deliberate fine-tuning. Even atheists like Stephen Hawking acknowledge this astonishing precision. The question is: Who fine-tuned it?")
                        .font(.body)
                }

                Section(header: Text("THE MORAL ARGUMENT")) {
                    Text("Every human being knows certain things are wrong - murder, rape, lying, oppression. But if humans are just chemical accidents, who decides what's right or wrong? Evolution can explain instincts, not moral obligations. The existence of objective morality points to a Moral Lawgiver - someone who defines justice, goodness, and evil: Allah (Glorified and Exalted be He).")
                        .font(.body)
                }

                Section(header: Text("ARGUMENT FROM BEAUTY, ORDER, AND DESIGN")) {
                    Text("Look at the trees, stars, animals, oceans. Look at the symmetry of flowers and the precision of ecosystems. Human creation - skyscrapers, smartphones, aircraft - demonstrates purposeful design. Just as buildings imply builders, the cosmos implies a Creator.")
                        .font(.body)
                    Text("“Or were they created by nothing, or were they the creators of themselves? Or did they create the heavens and the earth? Rather, they are not certain” (Quran 52:35–36).")
                        .foregroundColor(settings.accentColor.color)
                        .font(.title3)
                }

                Section(header: Text("WHAT MAKES A RELIGION TRUE?")) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("When choosing a religion, one must not follow emotions, culture, or dreams. The correct belief system should be based on logic, objective evidence, and sound reasoning.")
                            .font(.body)
                        Group {
                            Text("• Subjective experiences - such as dreams, visions, or personal feelings - may be meaningful, but they are not reliable indicators of truth.")
                            Text("• Anyone from any religion can claim such experiences.")
                            Text("• Truth must be verifiable, logical, and universally applicable.")
                        }
                        Text("Islam aligns with these criteria.")
                            .font(.body)
                    }
                    Text("“Have you seen he who has taken as his god his [own] desire…?” (Quran 45:23)")
                        .foregroundColor(settings.accentColor.color)
                        .font(.title3)
                }

                Section(header: Text("FINAL REFLECTION")) {
                    Text("Belief in God is not blind faith - it is the most rational and coherent explanation for existence, morality, consciousness, and design. Every human is born upon the **Fitrah (فِطرَة)** - the natural disposition to believe in one Creator. However, ego, society, and culture often obscure this truth. Islam calls humanity back to this original clarity.")
                        .font(.body)
                    Text("“And do not pursue that of which you have no knowledge. Indeed, the hearing, the sight and the heart - about all those [one] will be questioned” (Quran 17:36).")
                        .foregroundColor(settings.accentColor.color)
                        .font(.title3)
                }

                Section(header: Text("ADVICE TO THE SINCERE SEEKER")) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Seek truth with sincerity. Study deeply. Question critically. Do not follow inherited beliefs without examination.")
                            .font(.body)
                        Group {

                            Text("• The Quran criticizes blind following of ancestors without knowledge (Quran 43:23).")
                            Text("• Instead, use the God-given faculty of reason (aql) and return to the Fitrah.")
                            Text("• Islam stands as the only worldview that fully harmonizes with reason, morality, and objective reality.")
                        }
                    }
                }


                Section(header: Text("IN SUMMARY")) {
                    Text("Belief in God is not blind faith but the most rational explanation for existence, morality, consciousness, and design. Islam simply calls humanity back to the pure monotheism the soul was created upon.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Does God Exist?")
    }
}

struct IslamPillarView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Islam is the submission of the heart and life to Allah alone. It rests on five pillars of practice and six pillars of faith, and it is the one message of every prophet from Adam to Muhammad (peace be upon them).")
                        .font(.body)
                }


                Section(header: Text("OVERVIEW")) {
                    Text("**Islam (إِسلَام)** comes from the Arabic root **s-l-m (س ل م)**, meaning “submission,” “safety,” and “peace”: it is a complete way of life built on the worship of Allah (Glorified and Exalted be He) alone. The Quran, revealed to Prophet Muhammad (peace and blessings be upon him) over 23 years through the angel **Jibril (جِبرِيل)** (Gabriel), is the divine word of Allah - a comprehensive guide to belief, morality, and law.")
                        .font(.body)

                    Text("The essence of Islam is **Tawhid (تَوحِيد)**, absolute monotheism: there is no deity worthy of worship except Allah. Allah says in the Quran:").font(.body)
                    ScriptureQuote(text: "“And your god is one God. There is no deity [worthy of worship] except Him, the Entirely Merciful, the Especially Merciful” (Quran 2:163).")

                    Text("Prophet Muhammad (peace and blessings be upon him) is the final and last messenger of Allah, sent as a mercy to all of creation. Allah says in the Quran:").font(.body)
                    ScriptureQuote(text: "“And We have not sent you, [O Muhammad], except as a mercy to the worlds” (Quran 21:107).")

                    Text("Islam has been the way of life for humanity since the creation of Adam (peace be upon him), who was the first prophet and the first Muslim. Every nation that correctly followed the teachings of its prophet was considered Muslim in submission to Allah (Glorified and Exalted be He). For example, the Israelites who followed Moses (peace be upon him) and the disciples who followed Jesus (peace be upon him) were considered Muslims of their time.")
                            .font(.body)
                }

                Section(header: Text("THE FIVE PILLARS")) {
                    Text("Islam is built on five pillars, which are the fundamental acts of worship for every Muslim. The Prophet Muhammad (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Verily, Islam is founded on five (pillars): testifying the fact that there is no god but Allah (Shahadah), establishment of prayer (Salah), payment of charity (Zakah), fast of Ramadan, and Pilgrimage to the House (Hajj)” (Sahih Muslim 16d).", dimmed: true)

                    Text("The Five Pillars are:").font(.body)
                    Text("1. **Shahadah (شَهَادَة)**, from the root **sh-h-d (ش ه د)**, to witness or testify: the testimony of faith - “There is no god but Allah, and Muhammad is His Messenger.” You are not reporting an opinion; you are bearing witness. It is the foundation of a Muslim's faith.")
                    Text("2. **Salah (صَلَاة)**, from the root **s-l-w (ص ل و)**, to supplicate and to draw near: praying five times a day at prescribed times, a direct link between the believer and Allah.")
                    Text("3. **Zakah (زَكَاة)**, from the root **z-k-w (ز ك و)**, to purify and to grow: giving a portion of wealth to the needy (typically 2.5% of yearly savings). The word carries both meanings at once - wealth is purified by giving it away, and it grows by being purified.")
                    Text("4. **Sawm (صَوم)**, from the root **s-w-m (ص و م)**, to abstain or hold back: fasting the month of **Ramadan (رَمَضَان)**, abstaining from food, drink, and sinful behavior from dawn to sunset, as spiritual reflection and self-discipline.")
                    Text("5. **Hajj (حَجّ)**, from the root **h-j-j (ح ج ج)**, to set out with purpose toward something: pilgrimage to Makkah, a once-in-a-lifetime obligation for those physically and financially able, symbolizing unity and submission to Allah.")
                }

                Section(header: Text("THE SIX PILLARS OF IMAN")) {
                    Text("The Six Pillars of **Iman (إِيمَان)** - from the root **a-m-n (أ م ن)**, meaning faith, trust, and security - are the core beliefs every Muslim must hold. These are based on the Quran and the teachings of Prophet Muhammad (peace and blessings be upon him). Allah says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“The Messenger has believed in what was revealed to him from his Lord, and [so have] the believers. All of them have believed in Allah, His angels, His books, His messengers, and the Last Day. And they say, ‘We hear and we obey. [We seek] Your forgiveness, our Lord, and to You is the [final] destination.’” (Quran 2:285)")

                    Text("The Prophet Muhammad (peace and blessings be upon him) explained the pillars of Iman when he said:").font(.body)
                    ScriptureQuote(text: "“[It is] that you affirm your faith in Allah, in His angels, in His Books, in His Messengers, in the Day of Judgment, and you affirm your faith in the Divine Decree (Qadar) about good and evil” (Sahih Muslim 8a).", dimmed: true)

                    Text("The Six Pillars of Iman are:").font(.body)
                    Text("1. **Belief in Allah**, **Tawhid (تَوحِيد)** from the root **w-h-d (و ح د)**, to make one: the oneness of Allah, who has no partners or equals.")
                    Text("2. **Belief in the Angels**, **Malaikah (مَلَائِكَة)** from the root **l-a-k (ل أ ك)**, to send with a message: created beings of light who serve Allah and carry out His commands, such as Jibril (Gabriel).")
                    Text("3. **Belief in the Books**, **Kutub (كُتُب)** from the root **k-t-b (ك ت ب)**, to write or prescribe: the divine scriptures revealed by Allah, including the Torah, Gospel, Psalms, and the Quran, which is the final and unaltered revelation.")
                    Text("4. **Belief in the Messengers**, **Rusul (رُسُل)** from the root **r-s-l (ر س ل)**, to send: prophets sent to guide humanity, ending with Prophet Muhammad (peace and blessings be upon him).")
                    Text("5. **Belief in the Last Day**, **Yawm al-Qiyamah (يَوم القِيَامَة)** from the root **q-w-m (ق و م)**, to stand: the Day of Judgment, when all people will stand before Allah and be held accountable for their deeds.")
                    Text("6. **Belief in Divine Decree, Qadar (القَدَر)**, from the root **q-d-r (ق د ر)**, to measure out or determine: that everything, good and bad, happens by Allah’s will and wisdom, measured out precisely.")
                }

                Section(header: Text("PROPHETHOOD")) {
                    Text("Allah sent prophets to every nation to guide them to worship Him alone. These prophets include Adam, Noah, Abraham, Moses, David, Solomon, Jesus, and many others (peace be upon them all). Allah says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“We make no distinction between any of His messengers” (Quran 2:285).")

                    Text("However, all previous prophets were sent for their specific people and times. Prophet Muhammad (peace and blessings be upon him) is unique as the final and universal messenger, sent for all of humanity until the end of time. Allah says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“Muhammad is not the father of [any] one of your men, but [he is] the Messenger of Allah and last of the prophets. And ever is Allah, of all things, Knowing” (Quran 33:40).")

                    Text("Regarding Prophet Abraham (peace be upon him), Allah clarifies in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“Abraham was neither a Jew nor a Christian, but he was one inclining toward truth, a Muslim [submitting to Allah]. And he was not of the polytheists” (Quran 3:67).")
                }

                Section(header: Text("PREVIOUS SCRIPTURES")) {
                    Text("Islam acknowledges earlier divine scriptures such as the Torah given to Moses (peace be upon him) and the Gospel given to Jesus (peace be upon him). However, these scriptures were altered over time, and the current versions of the Bible and Torah are not the original revelations. Allah says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“So woe to those who write the Book with their own hands, then say, ‘This is from Allah,’ to exchange it for a small price. Woe to them for what their hands have written and woe to them for what they earn” (Quran 2:79).")

                    Text("The Quran is the final, complete, and preserved revelation sent to all of mankind for all time. Allah says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“Indeed, it is We who sent down the Quran and indeed, We will be its guardian” (Quran 15:9).")

                    Text("Prophet Muhammad (peace and blessings be upon him) said about the Quran:").font(.body)
                    ScriptureQuote(text: "“The best among you (Muslims) are those who learn the Quran and teach it” (Sahih al-Bukhari 5027).", dimmed: true)
                }

                Section(header: Text("ISLAMIC VALUES")) {
                    Text("Islam emphasizes high moral conduct, urging Muslims to embody honesty, justice, compassion, and humility. It teaches that good character and kindness towards others are integral to faith. The concept of the **Ummah (أُمَّة)**, the global Muslim community, fosters unity among believers regardless of ethnicity or background.")
                        .font(.body)

                    Text("Allah commands Muslims to act justly and to do good:").font(.body)
                    ScriptureQuote(text: "“Indeed, Allah orders justice and good conduct and giving [help] to relatives and forbids immorality and bad conduct and oppression. He admonishes you that perhaps you will be reminded” (Quran 16:90).")

                    Text("True righteousness is not limited to mere belief or rituals but includes good deeds and moral conduct. Allah says in the Quran:").font(.body)
                    ScriptureQuote(text: "“Righteousness is not that you turn your faces toward the east or the west, but [true] righteousness is in one who believes in Allah, the Last Day, the angels, the Book, and the prophets and gives wealth, in spite of love for it, to relatives, orphans, the needy, the traveler, those who ask [for help], and for freeing slaves; [and who] establishes prayer and gives zakah; [those who] fulfill their promise when they promise; and [those who] are patient in poverty and hardship and during battle. Those are the ones who have been true, and it is they who are the righteous” (Quran 2:177).")

                    Text("The Prophet Muhammad (peace and blessings be upon him) highlighted the importance of good manners and character. He said:").font(.body)
                    ScriptureQuote(text: "“The best among you are those who have the best manners and character” (Sahih al-Bukhari 6029)", dimmed: true)

                    Text("He also said:").font(.body)
                    ScriptureQuote(text: "“The most beloved people to Allah are those who are most beneficial to people. The most beloved deed to Allah is to make a Muslim happy, or remove one of his troubles, or forgive his debt, or feed his hunger” (al-Mu'jam al Awsat lil-Tabarani 6026).", dimmed: true)

                    Text("These teachings show that Islam is not only about fulfilling religious obligations but also about treating others with respect, kindness, and fairness. Upholding good character is considered a sign of true faith and devotion to Allah (Glorified and Exalted be He).")
                        .font(.body)
                }


                Section(header: Text("IN SUMMARY")) {
                    Text("Islam is a complete way of life that joins correct belief, sincere worship, and excellent character. It is Allah's final guidance and a mercy for all people until the end of time.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("What is Islam?")
    }
}

struct MuslimPillarView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: a Muslim is one who submits to Allah alone - following the Quran and the Sunnah of Prophet Muhammad (peace and blessings be upon him) as understood by his Companions, his family, and the first righteous generations.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("A **Muslim (مُسلِم)** is “one who submits.” The word shares the root **s-l-m (س ل م)** with **Islam (إِسلَام)** - a root carrying the meanings of submission, safety, and peace. A Muslim is therefore someone who surrenders to Allah rather than to his own desires or the passing things of this world, turning instead to the One who created him and knows him best.")
                        .font(.body)
                }

                Section(header: Text("ALLAH KNOWS US BEST")) {
                    Text("Before He calls us to worship Him, Allah reminds us that He created us, knows us completely, and is nearer to us than we imagine:")
                        .font(.body)
                    ScriptureQuote(text: "“And We have already created man and know what his soul whispers to him, and We are closer to him than his jugular vein” (Quran 50:16).")
                    Text("Submission, then, is not to a stranger - it is to the Lord who made us and knows us better than we know ourselves.")
                        .font(.body)
                }

                Section(header: Text("SUBMISSION TO ALLAH ALONE")) {
                    Text("To be a Muslim is to answer Allah's call as Ibrahim (Abraham, peace be upon him) did:")
                        .font(.body)
                    ScriptureQuote(text: "“When his Lord said to him, ‘Submit,’ he said, ‘I have submitted [in Islam] to the Lord of the worlds’” (Quran 2:131).")
                    Text("Ibrahim was neither a Jew nor a Christian, but a Muslim in the truest sense - devoted to the worship of the one God:")
                        .font(.body)
                    ScriptureQuote(text: "“Abraham was neither a Jew nor a Christian, but he was one inclining toward truth, a Muslim [submitting to Allah]. And he was not of the polytheists” (Quran 3:67).")
                }

                Section(header: Text("FOLLOWING THE QURAN AND SUNNAH")) {
                    Text("A Muslim follows the **Quran (قُرءان)**, the word of Allah, and the guidance of His Messenger Muhammad (peace and blessings be upon him), preserved in his **Sunnah (سُنَّة)** through authentic **Hadith (حَدِيث)**. Love of Allah is shown by following His Messenger:")
                        .font(.body)
                    ScriptureQuote(text: "“Say, [O Muhammad], ‘If you should love Allah, then follow me, [so] Allah will love you and forgive you your sins’” (Quran 3:31).")
                }

                Section(header: Text("AS THE FIRST GENERATIONS UNDERSTOOD IT")) {
                    Text("The Quran and Sunnah are understood as the first believers understood them: the Companions, **the Sahabah (صَحَابَة)**; the Prophet's household, **the Ahl al-Bayt (أَهل البَيت)**, which includes his wives; and the righteous first three generations, **the Salaf (السَّلَف)**.")
                        .font(.body)
                    ScriptureQuote(text: "“And the first forerunners among the Muhajireen and the Ansar and those who followed them with good conduct - Allah is pleased with them and they are pleased with Him” (Quran 9:100).")
                }

                Section(header: Text("WHAT IS A MU'MIN (BELIEVER)?")) {
                    Text("A **Mu'min (مُؤمِن)**, a true believer, is one whose faith lives in the heart and shows in action. Allah describes them:")
                        .font(.body)
                    ScriptureQuote(text: "“The believers are only those who, when Allah is mentioned, their hearts become fearful, and when His verses are recited to them, it increases them in faith; and upon their Lord they rely” (Quran 8:2).")
                }

                Section(header: Text("THE BELIEVERS ARE ONE")) {
                    Text("Muslims are a single brotherhood, united in faith across every race and land:")
                        .font(.body)
                    ScriptureQuote(text: "“The believers are but brothers, so make settlement between your brothers. And fear Allah that you may receive mercy” (Quran 49:10).")
                    Text("The Prophet (peace and blessings be upon him) said: “The believers, in their mutual love, mercy, and compassion, are like one body: when one limb suffers, the whole body responds to it with wakefulness and fever” (Sahih Muslim 2586).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color.opacity(0.85))
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("A Muslim submits to Allah alone - the One who created and knows us best - by holding to the Quran and the Sunnah upon the understanding of the Companions, the Prophet's family, and the Salaf, joined with all the believers as one brotherhood.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("What is a Muslim?")
    }
}

struct AllahPillarView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Allah is the one true God - the sole Creator and Sustainer of all that exists, without partner or equal, known by His Most Beautiful Names and perfect attributes.")
                        .font(.body)
                }


                Section(header: Text("OVERVIEW")) {
                    Text("**Allah (اللَّه)** is the name of the one true God. It comes from **Al-Ilah (الإِلَٰه)**, “The God.” In Islam He (Glorified and Exalted be He) is the unique Creator, Sustainer, and Maintainer of all that exists - without partner, associate, or equal, and absolutely One.")
                        .font(.body)

                    Text("The Quran mentions Allah's 99 Names, **Al-Asma al-Husna (الأَسمَاء الحُسنَى)**, the Most Beautiful Names, such as the Most Gracious, the Most Merciful, the All-Knowing, and the King. These Names describe His perfect qualities and emphasize His absolute transcendence. Allah is beyond human comprehension and far above any need, limitation, or resemblance to His creation.")
                        .font(.body)
                }

                Section(header: Text("ALLAH IN PRE-ISLAMIC TIMES")) {
                    Text("Before Islam, the Arabs acknowledged a supreme God named Allah but associated partners with Him by worshipping idols and other deities. When Prophet Muhammad (peace and blessings be upon him) brought Islam, he reaffirmed the Oneness of Allah, rejecting all forms of idolatry and polytheism. Allah says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“And they were not commanded except to worship Allah, [being] sincere to Him in religion, inclining to truth, and to establish prayer and to give zakah. And that is the correct religion” (Quran 98:5).")
                }

                Section(header: Text("QURANIC REFERENCES")) {
                    Text("Allah describes Himself in the Quran as the One and Only God, the source of all mercy and compassion. Allah says:")
                        .font(.body)
                    ScriptureQuote(text: "“And your god is one God. There is no deity [worthy of worship] except Him, the Entirely Merciful, the Especially Merciful” (Quran 2:163).")

                    Text("He also says: “There is nothing like unto Him, and He is the All-Hearing, the All-Seeing” (Quran 42:11).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color)
                }

                Section(header: Text("ESSENCE OF WORSHIP")) {
                    Text("The primary purpose of life is to worship Allah (Glorified and Exalted be He). This worship is not limited to rituals but encompasses every sincere action done to seek Allah's pleasure. Allah says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“And I did not create the jinn and mankind except to worship Me” (Quran 51:56).")

                    Text("Worshiping Allah includes prayer, supplication, charity, good conduct, and obedience to His commands as revealed in the Quran and the teachings of Prophet Muhammad (peace and blessings be upon him).").font(.body)

                    Text("This life is also a test from Allah to determine who among His servants will strive to fulfill their purpose with sincerity and patience. Allah says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“Indeed, We have made that which is on the earth adornment for it that We may test them [as to] which of them is best in deed” (Quran 18:7).")

                    Text("Allah further reminds us:").font(.body)
                    ScriptureQuote(text: "“And We test you with evil and with good as trial; and to Us you will be returned” (Quran 21:35).")

                    Text("Through these tests, believers have the opportunity to demonstrate their devotion, patience, and trust in Allah. Success lies in worshiping Him sincerely and following the straight path outlined in the Quran and Sunnah.")
                        .font(.body)
                }

                Section(header: Text("SURAH AL-IKHLAS")) {
                    Text("""
                    “Say, ‘He is Allah, [who is] One,
                    Allah, the Eternal Refuge.
                    He neither begets nor is born,
                    Nor is there to Him any equivalent.’”
                    (Quran 112:1-4)
                    """)
                    .font(.title3)
                    .foregroundColor(settings.accentColor.color)

                    Text("This short yet powerful chapter, **Surah Al-Ikhlas (الإِخلَاص)**, perfectly encapsulates the core of Islamic monotheism, affirming that Allah is eternal, without offspring or equal, and incomparable to any of His creation.")
                        .font(.body)
                }

                Section(header: Text("AYAT AL-KURSI")) {
                    Text("""
                    “Allah! There is no deity except Him, the Ever-Living, the Sustainer of [all] existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is [presently] before them and what will be after them, and they encompass not a thing of His knowledge except for what He wills. His Kursi extends over the heavens and the earth, and their preservation does not tire Him. And He is the Most High, the Most Great.”
                    (Quran 2:255)
                    """)
                    .font(.title3)
                    .foregroundColor(settings.accentColor.color)

                    Text("**Ayat al-Kursi (آيَة الكُرسِي)**, the Throne Verse, emphasizes Allah's supreme power, unmatched knowledge, and sovereignty over the universe. It is one of the most significant verses in the Quran and is often recited for protection and blessings.")
                        .font(.body)
                }


                Section(header: Text("IN SUMMARY")) {
                    Text("Allah is absolutely One and unlike anything in His creation. The whole purpose of life is to worship, obey, and come to know Him with sincerity.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Who is Allah?")
    }
}

struct QuranPillarView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the Quran is the literal, final word of Allah, revealed to Prophet Muhammad (peace and blessings be upon him) over 23 years. It is miraculous in its language and perfectly preserved.")
                        .font(.body)
                }


                Section(header: Text("OVERVIEW")) {
                    Text("The **Quran (قُرءان)** takes its name from the Arabic root **q-r-a (ق ر أ)**, meaning “to read” or “to recite.” It is the holy book of Islam. It is the literal word of Allah (Glorified and Exalted be He), revealed to Prophet Muhammad (peace and blessings be upon him) through the angel **Jibril (جِبرِيل)** (Gabriel) over 23 years. It is the ultimate source of guidance for humanity.")
                        .font(.body)

                    Text("Unlike previous scriptures sent to specific nations and later altered, the Quran is a universal message for all people and all times. Allah says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“And We have not sent you [O Muhammad] except as a mercy to the worlds” (Quran 21:107).")
                }

                Section(header: Text("ELOQUENCE AND MIRACULOUS NATURE")) {
                    Text("One of the most remarkable aspects of the Quran is its unmatched eloquence and literary beauty. It stands as the pinnacle of the Arabic language, setting the standard for vocabulary, syntax, and grammar. Formal Arabic today is even referred to as “Quranic Arabic“ due to the Quran's immense influence.")
                        .font(.body)

                    Text("The Quran challenged the greatest poets and linguists of its time, many of whom were astounded by its profound imagery, rhythmic flow, and clarity. Allah says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“Say, 'If mankind and the jinn gathered in order to produce the like of this Quran, they could not produce the like of it, even if they were to each assist the other'” (Quran 17:88).")

                    Text("What makes the challenge sharper is who it came through. Prophet Muhammad (peace and blessings be upon him) was **ummi (أُمِّيّ)**, unlettered: he could neither read nor write, and had never studied poetry, scripture, or the sciences of language. Allah says:")
                        .font(.body)
                    ScriptureQuote(text: "“And you did not recite before it any scripture, nor did you inscribe one with your right hand. Otherwise the falsifiers would have had [cause for] doubt” (Quran 29:48).")

                    Text("The Arabs of that era were masters of the spoken word. Poetry was their pride, and their finest verses were hung for all to see. Yet when the Quran was recited to them, they could not place it. It was not poetry, not rhymed prose, not the speech of a soothsayer, and none of their categories fit. They accused him of magic and of madness precisely because they had no literary answer to give. The challenge to produce even a single surah like it (Quran 2:23) was made openly to the very people best equipped to meet it, and it was never met.")
                        .font(.body)

                    Text("A man who could not write produced, over 23 years, a book their greatest poets could not imitate. That is the argument the Quran makes about itself.")
                        .font(.body)

                    Text("Despite its eloquence and poetic nature, the Quran remains simple and easy to understand, allowing millions of Muslims to memorize it entirely. This combination of literary perfection and accessibility is one of the Quran's miracles.")
                        .font(.body)
                }

                Section(header: Text("PRESERVATION")) {
                    Text("The Quran is unique among religious scriptures in that it has been perfectly preserved word for word and letter for letter since its revelation. This preservation is due to its widespread memorization by Muslims and its meticulous recording in written form.")
                        .font(.body)

                    Text("Allah promises in the Quran:").font(.body)
                    ScriptureQuote(text: "“Indeed, it is We who sent down the Quran and indeed, We will be its guardian” (Quran 15:9).")

                    Text("Millions of Muslims, from children to scholars, continue to memorize the Quran in its entirety, ensuring its unaltered transmission across generations. The Quran's preservation is a testament to its divine origin.")
                        .font(.body)
                }

                Section(header: Text("GUIDANCE AND MESSAGE")) {
                    Text("The Quran is not merely a book of laws or stories; it provides a comprehensive guide for personal, spiritual, and social life. Allah says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“This is the Book about which there is no doubt, a guidance for those conscious of Allah” (Quran 2:2).")

                    Text("It addresses themes such as the oneness of Allah, the purpose of life, moral conduct, and preparation for the Hereafter. The Quran calls for justice, compassion, and humility while offering hope and solace to those who reflect on its verses.")
                        .font(.body)
                }

                Section(header: Text("UNIVERSAL MESSAGE")) {
                    Text("Unlike previous scriptures, which were sent to specific nations and for specific times, the Quran is meant for all of humanity, regardless of race, language, or geography. Allah says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“And We have certainly made the Quran easy for remembrance, so is there any who will remember?” (Quran 54:17)")

                    Text("The Quran’s universality and timeless guidance make it relevant to every generation, providing solutions to contemporary issues and inspiring billions of people worldwide.")
                        .font(.body)
                }

                Section(header: Text("LEARN MORE")) {
                    Text("To explore the miracles of the Quran in more detail, visit: http://www.miracles-of-quran.com")
                        .font(.caption)
                }


                Section(header: Text("IN SUMMARY")) {
                    Text("Unmatched in eloquence yet easy to memorize and understand, the Quran is Allah's protected, universal guidance - relevant to every people and every age.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("What is the Quran?")
    }
}

struct MuqattaatPillarView: View {
    @ObservedObject var settings = Settings.shared

    private struct MuqattaatRow: Identifiable {
        let number: Int
        let surah: String
        let order: Int
        let letters: String
        let arabic: String
        let completeAyah: String

        var id: Int { number }
    }

    private let rows: [MuqattaatRow] = [
        MuqattaatRow(number: 23, surah: "ash-Shura", order: 42, letters: "Ha Mim; Ain Sin Qaf", arabic: "حمٓ عٓسٓقٓ", completeAyah: "Yes, 2 ayahs"),
        MuqattaatRow(number: 1, surah: "al-Baqarah", order: 2, letters: "Alif Lam Mim", arabic: "الٓمٓ", completeAyah: "Yes"),
        MuqattaatRow(number: 2, surah: "Al Imran", order: 3, letters: "Alif Lam Mim", arabic: "الٓمٓ", completeAyah: "Yes"),
        MuqattaatRow(number: 3, surah: "al-A'raf", order: 7, letters: "Alif Lam Mim Sad", arabic: "الٓمٓصٓ", completeAyah: "Yes"),
        MuqattaatRow(number: 10, surah: "Maryam", order: 19, letters: "Kaf Ha Ya Ain Sad", arabic: "كٓهيعٓصٓ", completeAyah: "Yes"),
        MuqattaatRow(number: 11, surah: "Ta Ha", order: 20, letters: "Ta Ha", arabic: "طه", completeAyah: "Yes"),
        MuqattaatRow(number: 12, surah: "ash-Shu'ara", order: 26, letters: "Ta Sin Mim", arabic: "طسٓمٓ", completeAyah: "Yes"),
        MuqattaatRow(number: 14, surah: "al-Qasas", order: 28, letters: "Ta Sin Mim", arabic: "طسٓمٓ", completeAyah: "Yes"),
        MuqattaatRow(number: 15, surah: "al-Ankabut", order: 29, letters: "Alif Lam Mim", arabic: "الٓمٓ", completeAyah: "Yes"),
        MuqattaatRow(number: 16, surah: "ar-Rum", order: 30, letters: "Alif Lam Mim", arabic: "الٓمٓ", completeAyah: "Yes"),
        MuqattaatRow(number: 17, surah: "Luqman", order: 31, letters: "Alif Lam Mim", arabic: "الٓمٓ", completeAyah: "Yes"),
        MuqattaatRow(number: 18, surah: "as-Sajdah", order: 32, letters: "Alif Lam Mim", arabic: "الٓمٓ", completeAyah: "Yes"),
        MuqattaatRow(number: 19, surah: "Ya Sin", order: 36, letters: "Ya Sin", arabic: "يسٓ", completeAyah: "Yes"),
        MuqattaatRow(number: 21, surah: "Ghafir", order: 40, letters: "Ha Mim", arabic: "حمٓ", completeAyah: "Yes"),
        MuqattaatRow(number: 22, surah: "Fussilat", order: 41, letters: "Ha Mim", arabic: "حمٓ", completeAyah: "Yes"),
        MuqattaatRow(number: 24, surah: "az-Zukhruf", order: 43, letters: "Ha Mim", arabic: "حمٓ", completeAyah: "Yes"),
        MuqattaatRow(number: 25, surah: "ad-Dukhan", order: 44, letters: "Ha Mim", arabic: "حمٓ", completeAyah: "Yes"),
        MuqattaatRow(number: 26, surah: "al-Jathiyah", order: 45, letters: "Ha Mim", arabic: "حمٓ", completeAyah: "Yes"),
        MuqattaatRow(number: 27, surah: "al-Ahqaf", order: 46, letters: "Ha Mim", arabic: "حمٓ", completeAyah: "Yes"),
        MuqattaatRow(number: 4, surah: "Yunus", order: 10, letters: "Alif Lam Ra", arabic: "الٓر", completeAyah: "No"),
        MuqattaatRow(number: 5, surah: "Hud", order: 11, letters: "Alif Lam Ra", arabic: "الٓر", completeAyah: "No"),
        MuqattaatRow(number: 6, surah: "Yusuf", order: 12, letters: "Alif Lam Ra", arabic: "الٓر", completeAyah: "No"),
        MuqattaatRow(number: 7, surah: "ar-Ra'd", order: 13, letters: "Alif Lam Mim Ra", arabic: "الٓمٓر", completeAyah: "No"),
        MuqattaatRow(number: 8, surah: "Ibrahim", order: 14, letters: "Alif Lam Ra", arabic: "الٓر", completeAyah: "No"),
        MuqattaatRow(number: 9, surah: "al-Hijr", order: 15, letters: "Alif Lam Ra", arabic: "الٓر", completeAyah: "No"),
        MuqattaatRow(number: 13, surah: "an-Naml", order: 27, letters: "Ta Sin", arabic: "طسٓ", completeAyah: "No"),
        MuqattaatRow(number: 20, surah: "Sad", order: 38, letters: "Sad", arabic: "صٓ", completeAyah: "No"),
        MuqattaatRow(number: 28, surah: "Qaf", order: 50, letters: "Qaf", arabic: "قٓ", completeAyah: "No"),
        MuqattaatRow(number: 29, surah: "al-Qalam", order: 68, letters: "Nun", arabic: "نٓ", completeAyah: "No"),
    ]

    private var arabicFont: Font {
        Font.arabic(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title2).pointSize)
    }

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the Muqatta'at are the disconnected letters (like Alif-Lam-Mim) that open twenty-nine surahs - recited letter by letter.")
                        .font(.body)
                }

                Section(header: Text("MUQATTA'AT")) {
                    Text("**Muqatta'at (مُقَطَّعَات)**, from the root **q-t-a (ق ط ع)** meaning to cut or sever, are the disconnected opening letters that appear at the beginning of 29 surahs, after the Basmalah where the Basmalah is recited.")
                        .font(.body)

                    Text("They are also called fawatih, meaning openers, because they open their surahs. Their exact meaning is known to Allah; Muslims recite them as revealed without claiming a hidden meaning with certainty.")
                        .font(.body)

                    Text("Four surahs are named directly for these letters: Ta Ha, Ya Sin, Sad, and Qaf. Some also include Nun because Surah al-Qalam opens with Nun.")
                        .font(.body)
                        .foregroundColor(settings.accentColor.color)
                }

                Section(header: Text("PATTERNS")) {
                    Text("There are 14 distinct combinations. The most frequent are Alif Lam Mim and Ha Mim, each appearing six times.")
                        .font(.body)

                    Text("The letters used are half of the Arabic alphabet: ا هـ ح ط ي ك ل م ن س ع ص ق ر.")
                        .font(.body)

                    Text("Most combinations begin with either Alif Lam or Ha Mim. In most of these surahs, the opening letters are followed very soon by mention of the Quran, the Book, revelation, or signs.")
                        .font(.body)
                }

                Section(header: Text("RECITATION NOTE")) {
                    Text("In the app's tajweed coloring, complete muqatta'at ayahs are treated as opening-letter recitation. Bare letters stay normal unless they are heavy letters, while letters with maddah are treated as madd lazim.")
                        .font(.body)

                    Text("If the muqatta'at are not the whole ayah, only the first word receives that special opening-letter handling; the rest of the ayah uses normal tajweed rules. For ash-Shura, this handling applies to both of the first two ayahs.")
                        .font(.body)
                }

                Section(header: Text("TABLE")) {
                    ForEach(rows) { row in
                        muqattaatRow(row)
                    }
                }

                Section(header: Text("LEARN MORE")) {
                    Text("How the muqatta'at are recited: https://www.youtube.com/watch?v=6_gKg6PByOI")
                        .font(.caption)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Their precise meaning is known to Allah; the believer recites them as revealed, and they testify to the Quran's inimitable nature.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Muqatta'at Letters")
        .applyConditionalListStyle()
    }

    private func muqattaatRow(_ row: MuqattaatRow) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(row.number). \(row.surah)")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("Surah \(row.order)")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }

            Text(row.arabic)
                .font(arabicFont)
                .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                .frame(maxWidth: .infinity, alignment: .trailing)

            Text(row.letters)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Complete ayah: \(row.completeAyah)")
                .font(.caption.weight(.semibold))
                .foregroundColor(row.completeAyah.hasPrefix("Yes") ? settings.accentColor.color : .secondary)
        }
        .padding(.vertical, 4)
    }
}

struct ProphetPillarView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Prophet Muhammad (peace and blessings be upon him) is the final messenger of Allah, sent as a mercy to all creation. He conveyed the Quran and embodied it in his character.")
                        .font(.body)
                }


                Section(header: Text("OVERVIEW")) {
                    Text("Prophet **Muhammad (مُحَمَّد)**, “the Praised One,” was born in **Makkah (مَكَّة)** (in present-day Saudi Arabia) around 570 CE, into the noble tribe of Quraysh. Orphaned young, he became known as **Al-Amin (الأَمِين)**, “the Trustworthy,” for his honesty and upright character.")
                        .font(.body)

                    Text("At the age of 40, while worshipping in the cave of **Hira (حِرَاء)**, he received his first revelation from Allah (Glorified and Exalted be He) through the angel **Jibril (جِبرِيل)** (Gabriel). This marked the beginning of his prophethood and the revelation of the Quran, the final divine guidance for humanity.")
                        .font(.body)

                    Text("In Islamic tradition he is called both a **Rasul (رَسُول)**, “Messenger,” and a **Nabi (نَبِيّ)**, “Prophet.” A Rasul is a prophet who brings a new scripture or law, while a Nabi upholds the teachings of a previous messenger.")
                        .font(.body)

                    Text("He called people to worship Allah alone, rejecting idolatry and emphasizing justice, compassion, and respect for the marginalized. His teachings addressed all facets of life, including spiritual, social, economic, and political matters, as well as personal conduct and morality.")
                        .font(.body)
                }

                Section(header: Text("FINAL PROPHET")) {
                    Text("Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                    ScriptureQuote(text: "“Muhammad is not the father of [any] one of your men, but [he is] the Messenger of Allah and the seal of the prophets. And ever is Allah, of all things, Knowing” (Quran 33:40).")

                    Text("Prophet Muhammad (peace and blessings be upon him) is the last and final prophet, completing the chain of messengers that began with Adam (peace be upon him). He delivered the final revelation, the Quran, and exemplified its teachings as the ultimate role model.")
                        .font(.body)
                }

                Section(header: Text("HIS CHARACTER")) {
                    Text("Prophet Muhammad (peace and blessings be upon him) is described in the Quran as a man of exemplary character. Allah says in the Quran:").font(.body)
                    ScriptureQuote(text: "“And indeed, you are of a great moral character” (Quran 68:4).")

                    Text("He was known for his compassion, humility, and justice. Even toward his enemies, he demonstrated forgiveness and kindness. Aisha (may Allah be pleased with her), his wife, described him by saying:").font(.body)
                    ScriptureQuote(text: "“Verily, the character of the Prophet of Allah was the Quran” (Sahih Muslim 746).", dimmed: true)

                    Text("Allah also says in the Quran:").font(.body)
                    ScriptureQuote(text: "“There has certainly been for you in the Messenger of Allah an excellent example for anyone whose hope is in Allah and the Last Day and [who] remembers Allah often” (Quran 33:21).")

                    Text("Obedience to the Prophet (peace and blessings be upon him) is also linked to obedience to Allah. Allah says in the Quran:").font(.body)
                    ScriptureQuote(text: "“Whoever obeys the Messenger has obeyed Allah; but those who turn away – We have not sent you over them as a guardian” (Quran 4:80).")

                    Text("His humility is evident in many of his interactions. When a companion's voice trembled as he talked to the prophet, the prophet (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“Be calm, for I am not a king. Verily, I am only the son of a woman who ate dried meat” (Sunan Ibn Majah 3312).", dimmed: true)

                    Text("He also said:").font(.body)
                    ScriptureQuote(text: "“I am only a servant. I eat as the servant eats, and I sit as the servant sits” (as-Silsilah as-Sahihah 544 - graded hasan).", dimmed: true)

                    Text("Similarly, the Prophet (peace and blessings be upon him) warned against excessive praise, saying:").font(.body)
                    ScriptureQuote(text: "“Do not exaggerate in praising me as the Christians praised the son of Mary (Jesus), for I am only a Slave. So, call me the Slave of Allah and His Messenger” (Sahih al-Bukhari 3445).", dimmed: true)
                }

                Section(header: Text("HIS TEACHINGS")) {
                    Text("The teachings and practices of Prophet Muhammad (peace and blessings be upon him) are called the **Sunnah (سُنَّة)**, which serve as a guide for Muslims to live a righteous and balanced life. He perfectly demonstrated how to implement the Quran in daily life.")
                        .font(.body)

                    Text("While Muslims deeply love and revere him, worship is reserved for Allah (Glorified and Exalted be He) alone. He is honored as the finest example of humanity, yet never viewed as divine.")
                        .font(.body)
                }

                Section(header: Text("HIS IMPACT")) {
                    Text("Prophet Muhammad (peace and blessings be upon him) is considered one of the most influential figures in history. Historian Michael H. Hart ranked him as the most influential person of all time, citing his unparalleled success both religiously and politically. With the will of Allah, he unified Arabia under Islam and established a faith that continues to inspire billions.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                    ScriptureQuote(text: "“And We have not sent you, [O Muhammad], except as a mercy to the worlds” (Quran 21:107).")
                }

                Section(header: Text("HIS LEGACY")) {
                    Text("Prophet Muhammad (peace and blessings be upon him) passed away at the age of 63 in Madinah, leaving behind the Quran and Sunnah as guidance for humanity. In his Farewell Sermon, he emphasized the equality of all people, adherence to the Quran and Sunnah, and the importance of justice and righteousness.")
                        .font(.body)

                    Text("He said:").font(.body)
                    ScriptureQuote(text: "“O People, there is no superiority of an Arab over a non-Arab, or of a non-Arab over an Arab; nor of a white person over a black person, or of a black person over a white person - except by piety and good action” (Musnad Ahmad 23489).", dimmed: true)
                }

                Section(header: Text("LEARN MORE")) {
                    Text("Famous quotes and Hadiths of Prophet Muhammad (peace be upon him): https://www.awakenthegreatnesswithin.com/35-inspirational-prophet-muhammad-pbuh-quotes/")
                        .font(.caption)
                }


                Section(header: Text("IN SUMMARY")) {
                    Text("As the seal of the prophets and the finest example for humanity, he is deeply loved and followed - yet he is never worshipped, for worship belongs to Allah alone.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Who is the Prophet?")
    }
}

struct SunnahPillarView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the Sunnah is the way of Prophet Muhammad (peace and blessings be upon him) - his words, actions, and approvals. It explains the Quran and is the second source of Islam.")
                        .font(.body)
                }


                Section(header: Text("OVERVIEW")) {
                    Text("The **Sunnah (سُنَّة)** - an Arabic word meaning “way,” “path,” or “tradition” - is the teachings, actions, and approvals of Prophet Muhammad (peace and blessings be upon him): his habits, moral conduct, and guidance on worship and dealings. It explains and complements the Quran and is the second source of Islamic knowledge.")
                        .font(.body)

                    Text("Allah says in the Quran:").font(.body)
                    ScriptureQuote(text: "“And whatever the Messenger has given you – take; and what he has forbidden you – refrain from. And fear Allah; indeed, Allah is severe in penalty” (Quran 59:7).")
                }

                Section(header: Text("IMPORTANCE")) {
                    Text("The Sunnah provides practical guidance on how to live according to the Quran. It clarifies general commands in the Quran and gives specific instructions. For instance, the Quran commands Muslims to pray, and the Sunnah demonstrates how to perform the prayer.")
                        .font(.body)

                    Text("The Prophet (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“Pray as you have seen me praying” (Sahih al-Bukhari 631).", dimmed: true)

                    Text("The Sunnah also serves as an example for personal conduct and social interactions. Allah says in the Quran:").font(.body)
                    ScriptureQuote(text: "“There has certainly been for you in the Messenger of Allah an excellent example for anyone whose hope is in Allah and the Last Day and [who] remembers Allah often” (Quran 33:21).")

                    Text("Obedience to the Sunnah is considered obedience to Allah. Allah says in the Quran:").font(.body)
                    ScriptureQuote(text: "“Whoever obeys the Messenger has obeyed Allah; but those who turn away – We have not sent you over them as a guardian” (Quran 4:80).")
                }

                Section(header: Text("HADITH LITERATURE")) {
                    Text("The Sunnah is preserved through **Hadith (حَدِيث)**, compilations of the recorded sayings, actions, and approvals of the Prophet Muhammad (peace and blessings be upon him). These narrations were meticulously verified by scholars to ensure their authenticity.")
                        .font(.body)

                    Text("Major Hadith collections include:").font(.body)
                    Text("1. Sahih al-Bukhari").font(.body)
                    Text("2. Sahih Muslim").font(.body)
                    Text("3. Sunan Abu Dawood").font(.body)
                    Text("4. Jami' at-Tirmidhi").font(.body)
                    Text("5. Sunan an-Nasa'i").font(.body)
                    Text("6. Sunan Ibn Majah").font(.body)

                    Text("These collections provide invaluable insights into the life and teachings of the Prophet (peace and blessings be upon him) and serve as a foundation for understanding and implementing the Sunnah.")
                        .font(.body)
                }

                Section(header: Text("EXAMPLES OF SUNNAH")) {
                    Text("Examples of Sunnah practices include:").font(.body)
                    Text("1. Greeting others with **As-Salamu Alaikum (السَّلَام عَلَيكُم)** (peace be upon you).").font(.body)
                    Text("2. Saying **Bismillah (بِسم اللَّه)** (in the name of Allah) before eating.").font(.body)
                    Text("3. Performing acts of charity, such as smiling at others, which is considered a form of charity.").font(.body)
                    Text("4. Maintaining cleanliness and grooming, such as trimming nails and keeping oneself tidy.").font(.body)
                    Text("5. Showing kindness and mercy to others, including animals.").font(.body)
                    Text("6. Praying certain optional prayers.").font(.body)
                }

                Section(header: Text("RESOURCES")) {
                    Text("You can view Hadith collections here: https://sunnah.com/")
                        .font(.caption)
                }


                Section(header: Text("IN SUMMARY")) {
                    Text("Preserved through authentic Hadith, the Sunnah shows a Muslim how to live the Quran in daily life, and holding to it is part of obeying Allah.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("What is the Sunnah?")
    }
}

struct HadithPillarView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: a Hadith is a recorded saying, action, or approval of Prophet Muhammad (peace and blessings be upon him). Hadiths preserve the Sunnah and clarify how to act on the Quran.")
                        .font(.body)
                }


                Section(header: Text("OVERVIEW")) {
                    Text("A **Hadith (حَدِيث)** - an Arabic word meaning “speech,” “narration,” or “report” - is a recorded saying, action, or approval of Prophet Muhammad (peace and blessings be upon him). Hadiths preserve the Sunnah and are an essential source of Islamic knowledge, and scholars verified them meticulously to ensure their authenticity.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) commands in the Quran:").font(.body)
                    ScriptureQuote(text: "“And whatever the Messenger has given you – take; and what he has forbidden you – refrain from. And fear Allah; indeed, Allah is severe in penalty” (Quran 59:7).")

                    Text("Hadiths are indispensable for understanding and implementing the Quran’s teachings, as they provide practical examples of how Prophet Muhammad (peace and blessings be upon him) lived according to Allah’s commands.")
                        .font(.body)
                }

                Section(header: Text("RELATIONSHIP WITH THE QURAN")) {
                    Text("Hadiths are essential for interpreting and contextualizing the Quran. Allah says in the Quran:").font(.body)
                    ScriptureQuote(text: "“It is He who has sent down to you, [O Muhammad], the Book; in it are verses [that are] precise... and others unspecific” (Quran 3:7).")

                    Text("While the Quran provides general principles, the Hadith clarifies how to implement these teachings. For example, the Quran commands Muslims to pray, and the Hadith describes how the Prophet (peace and blessings be upon him) performed **Salah (صَلَاة)**. He said:").font(.body)
                    ScriptureQuote(text: "“Pray as you have seen me praying” (Sahih al-Bukhari 631).", dimmed: true)
                }

                Section(header: Text("TYPES OF HADITHS")) {
                    Text("There are two main types of Hadiths:").font(.body)

                    Text("1. **Hadith Qudsi (حَدِيث قُدسِي), the Sacred Hadith:** These are sayings where the Prophet (peace and blessings be upon him) conveys meanings from Allah (Glorified and Exalted be He), but the wording is his own. Unlike the Quran, which is the exact verbatim word of Allah, Hadith Qudsi reflects divine inspiration shared through the Prophet’s speech. For example, the Prophet said:").font(.body)
                    ScriptureQuote(text: "“Allah the Almighty said: ‘I am as My servant thinks I am. I am with him when he remembers Me.’” (Sahih al-Bukhari 7405)", dimmed: true)
                    Text("While the Quran was revealed through the Angel Jibril (Gabriel) and recited exactly as revealed, Hadith Qudsi might have been conveyed to the Prophet through a dream or inspiration. It holds a special status but is not part of the Quran.")
                        .font(.body)

                    Text("2. **Hadith Nabawi (حَدِيث نَبَوِي), the Prophetic Hadith:** These include the Prophet’s own words, actions, and approvals, reflecting his teachings and practices. For instance, he said:").font(.body)
                    ScriptureQuote(text: "“The best among you (Muslims) are those who learn the Quran and teach it” (Sahih al-Bukhari 5027).", dimmed: true)

                    Text("Learn the difference here: https://www.youtube.com/watch?v=F7vfmGC-o-A")
                        .font(.caption)
                }

                Section(header: Text("AUTHENTICITY AND CLASSIFICATION")) {
                    Text("Hadiths were meticulously preserved and classified by scholars based on their authenticity to ensure the teachings of Prophet Muhammad (peace and blessings be upon him) were transmitted accurately. A hadith consists of two critical components:").font(.body)
                    Text("1. **Isnad (إِسنَاد), the Chain of Transmission:** The sequence of narrators who transmitted the hadith. This ensures a direct link back to the Prophet (peace and blessings be upon him).").font(.body)
                    Text("2. **Matn (مَتن), the Text:** The content of the hadith itself, which is examined for consistency with established Islamic teachings and linguistic accuracy.").font(.body)

                    Text("The rigorous analysis of isnad and matn is crucial because some individuals attempted to fabricate sayings of the Prophet (peace and blessings be upon him). To safeguard against such corruption, scholars developed a meticulous science of hadith authentication. The Prophet (peace and blessings be upon him) warned:").font(.body)
                    ScriptureQuote(text: "“Whoever tells a lie against me intentionally, then (surely) let him occupy his seat in Hell-fire” (Sahih al-Bukhari 108).", dimmed: true)

                    Text("This rigorous methodology prevented the kind of corruption and fabrications found in other scriptures, such as the Bible, where authors are often anonymous, and transmission chains are unknown. In Islam, every hadith is traced back through a reliable chain of narrators to the Prophet (peace and blessings be upon him).").font(.body)

                    Text("Scholars classified Hadiths into categories based on their reliability and authenticity:").font(.body)
                    Text("- **Mutawatir (مُتَوَاتِر), Mass-Transmitted:** Narrated by a large number of trustworthy narrators, ensuring its authenticity without any doubt.").font(.body)
                    Text("- **Sahih (صَحِيح), Authentic:** Reliable chain and text, meeting strict criteria of authenticity.").font(.body)
                    Text("- **Hasan (حَسَن), Good:** Slightly weaker chain than Sahih but still reliable and acceptable for use in rulings.").font(.body)
                    Text("- **Da'if (ضَعِيف), Weak:** Questionable reliability due to issues in the chain or content, generally avoided for rulings.").font(.body)

                    Text("The highest rank of authentic hadith is known as **Muttafaqun Alayh (مُتَّفَق عَلَيه)**, meaning “agreed upon.“ These are hadiths narrated by both Imam Bukhari and Imam Muslim in their Sahih collections, indicating the highest level of authenticity.").font(.body)

                    Text("This detailed grading system ensures that Muslims can confidently rely on the Hadiths as a source of guidance without the risk of fabricated or unreliable narrations.")
                        .font(.body)
                }

                Section(header: Text("IMPORTANCE OF HADITHS")) {
                    Text("The Hadiths are indispensable for:").font(.body)
                    Text("1. **Clarifying the Quran:** They explain Quranic commands, such as how to perform Salah and fast during **Ramadan (رَمَضَان)**.").font(.body)
                    Text("2. **Guiding Daily Life:** Hadiths provide moral and ethical lessons, teaching Muslims how to interact with others and live righteously.").font(.body)
                    Text("3. **Strengthening Faith:** They contain spiritual guidance and wisdom that deepen a Muslim’s connection to Allah (Glorified and Exalted be He).").font(.body)

                    Text("The Prophet (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“I have left you with two matters which will never lead you astray, as long as you hold to them: the Book of Allah and the Sunnah of his Prophet” (al-Muwatta' 1661).", dimmed: true)
                }

                Section(header: Text("RESOURCES")) {
                    Text("You can view Hadith collections here: https://sunnah.com/")
                        .font(.caption)
                }


                Section(header: Text("IN SUMMARY")) {
                    Text("Through a rigorous science of chain (Isnad) and text (Matn), scholars carefully graded Hadiths, so Muslims can rely on authentic prophetic guidance with confidence.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("What are Hadiths?")
    }
}

import SwiftUI

struct IslamicPillarsView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        Section(header: Text("THE 5 PILLARS OF ISLAM")) {
            NavigationLink(destination: LazyDestination { ShahadahView() }) {
                Text("Shahadah (Testimony of Faith)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { SalahView() }) {
                Text("Salah (Five Daily Prayers)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { SawmView() }) {
                Text("Sawm (Fasting in Ramadan)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { ZakahView() }) {
                Text("Zakah (Annual Charity)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { HajjView() }) {
                Text("Hajj (Pilgrimage to Makkah)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
        }
    }
}

struct ShahadahView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the Shahadah is the testimony that there is no god but Allah and that Muhammad is His Messenger. It is the doorway into Islam and the foundation of all faith.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("The **Shahadah (شَهَادَة)**, from the root **sh-h-d (ش ه د)** meaning “to witness” or “to testify,” is the first and most fundamental pillar of Islam. By declaring it with sincerity, a person affirms the Oneness of Allah (Glorified and Exalted be He) and accepts Muhammad (peace and blessings be upon him) as His final Prophet.")
                        .font(.body)

                    Text("This simple yet profound statement encapsulates the essence of Islam: the worship of Allah alone and adherence to the teachings of His messenger. Allah (Glorified and Exalted be He) says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“And We sent not before you any messenger except that We revealed to him that, “There is no deity except Me, so worship Me“” (Quran 21:25).")
                }

                Section(header: Text("VERSIONS")) {
                    Text("There are two common versions of the Shahadah. Both affirm the fundamental tenets of Islam, but the second version emphasizes the servanthood of Prophet Muhammad (peace and blessings be upon him) to ensure that he is not viewed as divine.")
                        .font(.body)
                }

                Section(header: Text("FIRST VERSION")) {
                    VStack(alignment: .leading) {
                        Text("أَشهَدُ أَن لَا إِلٰهَ إِلَّا ٱللّٰهُ وَأَشهَدُ أَنَّ مُحَمَّدًا رَسُولُ ٱللّٰهِ")
                            .font(.body)
                            .foregroundColor(settings.accentColor.color)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 2)

                        Text("Ashhadu an la ilaha illa Allah, wa ashhadu anna Muhammad rasul Allah.")
                            .font(.body)
                            .padding(.vertical, 2)

                        Text("“I bear witness that there is no deity but Allah, and I bear witness that Muhammad is the messenger of Allah.”")
                            .font(.body)
                            .padding(.vertical, 2)
                    }
                }

                Section(header: Text("SECOND VERSION")) {
                    VStack(alignment: .leading) {
                        Text("أَشهَدُ أَن لَا إِلٰهَ إِلَّا ٱللّٰهُ وَأَشهَدُ أَنَّ مُحَمَّدًا عَبدُهُ وَرَسُولُهُ")
                            .font(.body)
                            .foregroundColor(settings.accentColor.color)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 2)

                        Text("Ashhadu an la ilaha illa Allah, wa ashhadu anna Muhammad abduhu wa rasuluhu.")
                            .font(.body)
                            .padding(.vertical, 2)

                        Text("“I bear witness that there is no deity but Allah, and I bear witness that Muhammad is His servant and messenger.”")
                            .font(.body)
                            .padding(.vertical, 2)
                    }
                }

                Section(header: Text("SIGNIFICANCE")) {
                    Text("Pronouncing the Shahadah with sincere faith confirms Tawhid (absolute monotheism) and the acceptance of Muhammad (peace and blessings be upon him) as the final Prophet. Allah (Glorified and Exalted be He) says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“So know [O Muhammad], that there is no deity except Allah” (Quran 47:19).")

                    Text("The Shahadah is a lifelong declaration of faith and is recited during the daily prayers, serving as a constant reminder of a Muslim's commitment to Allah and His messenger.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Said with sincere conviction and lived by, the Shahadah affirms pure monotheism and acceptance of the Prophet's guidance - renewed in every prayer a Muslim offers.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Shahadah")
    }
}

struct SalahView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Salah is the five daily prayers - a direct connection between the servant and Allah, and the first deed a person will be asked about on the Day of Judgment.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("**Salah (صَلَاة)**, from the root **s-l-w (ص ل و)** carrying the sense of prayer, supplication, and connection, is the second pillar of Islam. It is an act of worship that links a Muslim directly to Allah (Glorified and Exalted be He), performed five times daily at prescribed times as a constant reminder of submission and gratitude.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                    ScriptureQuote(text: "“Indeed, I am Allah. There is no deity except Me, so worship Me and establish prayer for My remembrance” (Quran 20:14).")
                }

                Section(header: Text("TIMINGS")) {
                    Text("The five daily prayers are:").font(.body)
                    Text("1. **Fajr (Dawn):** Performed before sunrise.").font(.body)
                    Text("2. **Dhuhr (Noon):** Performed after the sun passes its zenith.").font(.body)
                    Text("3. **Asr (Afternoon):** Performed in the late afternoon.").font(.body)
                    Text("4. **Maghrib (Evening):** Performed just after sunset.").font(.body)
                    Text("5. **Isha (Night):** Performed in the late evening.").font(.body)

                    Text("Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                    ScriptureQuote(text: "“Indeed, prayer has been decreed upon the believers a decree of specified times” (Quran 4:103).")
                }

                Section(header: Text("NUMBER OF UNITS (RAKAH)")) {
                    Text("Each prayer is made up of units called **rak'ah (رَكعَة)**:").font(.body)
                    Text("• **Fajr**: 2 rak'ah").font(.body)
                    Text("• **Dhuhr**: 4 rak'ah").font(.body)
                    Text("• **Asr**: 4 rak'ah").font(.body)
                    Text("• **Maghrib**: 3 rak'ah").font(.body)
                    Text("• **Isha**: 4 rak'ah").font(.body)
                }

                Section(header: Text("HOW TO PRAY")) {
                    Text("The Prophet (peace and blessings be upon him) instructed:").font(.body)
                    ScriptureQuote(text: "“Pray as you have seen me praying” (Sahih al-Bukhari 631).", dimmed: true)
                    Text("Facing the Qibla, with the **Niyyah (نِيَّة)** - the intention - settled in the heart, each rak'ah proceeds as follows:").font(.body)
                    Text("1. **Takbir (تَكبِير)**: raise the hands and say “Allahu Akbar” (Allah is the Greatest), then place the right hand over the left upon the chest.").font(.body)
                    Text("2. **Recitation**: recite the opening supplication, then Surah **Al-Fatiha (الفَاتِحَة)** - obligatory in every rak'ah - followed by another passage of the Quran in the first two rak'ah.").font(.body)
                    Text("3. **Ruku (رُكُوع)**: say “Allahu Akbar” and bow with a straight back, hands on the knees, saying “Subhana Rabbi al-Adheem” (Glory to my Lord the Most Great) three times.").font(.body)
                    Text("4. **Rising (I'tidal)**: rise saying “Sami'a Allahu liman hamidah” (Allah hears whoever praises Him), then, standing, “Rabbana wa laka al-hamd” (Our Lord, to You is all praise).").font(.body)
                    Text("5. **Sujud (سُجُود)**: say “Allahu Akbar” and prostrate on seven parts - the forehead and nose, both palms, both knees, and the toes of both feet - saying “Subhana Rabbi al-A'la” (Glory to my Lord the Most High) three times.").font(.body)
                    Text("6. **Sitting**: say “Allahu Akbar,” sit, and say “Rabbi ighfir li” (My Lord, forgive me); then perform a second Sujud in the same way. This completes one rak'ah.").font(.body)
                    Text("7. **Tashahhud (تَشَهُّد)**: after each two rak'ah, sit and recite the tashahhud (“At-tahiyyatu lillah…”). In the final sitting, add the prayers upon the Prophet (peace and blessings be upon him) and supplication.").font(.body)
                    Text("8. **Taslim (تَسلِيم)**: end the prayer by turning the face to the right and then to the left, saying each time “As-salamu alaykum wa rahmatullah” (peace and the mercy of Allah be upon you).").font(.body)
                }

                Section(header: Text("BENEFITS")) {
                    Text("Salah purifies the soul, instills discipline, and strengthens a Muslim's relationship with Allah (Glorified and Exalted be He). It keeps one mindful of their Creator throughout the day, offering spiritual peace and balance.")
                        .font(.body)

                    Text("Salah also serves as a means of expiation for minor sins. The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“The five daily prayers and Friday to Friday are an expiation for what is between them, so long as major sins are avoided” (Sahih Muslim 233c).", dimmed: true)
                }

                Section(header: Text("IMPORTANCE OF SALAH")) {
                    Text("Salah is the first deed for which a person will be held accountable on the Day of Judgment. The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“The first action for which a servant of Allah will be held accountable on the Day of Resurrection will be his prayers. If they are in order, he will have prospered and succeeded. If they are lacking, he will have failed and lost. If there is something defective in his obligatory prayers, then the Almighty Lord will say: See if My servant has any voluntary prayers that can complete what is insufficient in his obligatory prayers. The rest of his deeds will be judged the same way” (Sunan al-Tirmidhi 413).", dimmed: true)

                    Text("It is also a key to success in this life and the Hereafter. Allah (Glorified and Exalted be He) says:").font(.body)
                    ScriptureQuote(text: "“Certainly will the believers have succeeded: They who are during their prayer humbly intent” (Quran 23:1-2).")
                }

                Section(header: Text("LEARN MORE")) {
                    Text("Learn how to perform Salah and its detailed steps here: https://learnsalah.com/")
                        .font(.caption)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Prayed as the Prophet prayed, Salah purifies the soul, restrains from wrongdoing, and keeps a Muslim mindful of Allah throughout the day.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Salah")
    }
}

struct SawmView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Sawm is fasting from dawn to sunset - especially in Ramadan - abstaining from food, drink, and desires to draw nearer to Allah and attain God-consciousness.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("**Sawm (صَوم)**, from the root **s-w-m (ص و م)** meaning “to abstain” or “to refrain,” is the fourth pillar of Islam. It is fasting: abstaining from food, drink, and marital relations from dawn (Fajr) until sunset (Maghrib) with the intention of seeking Allah’s pleasure.")
                        .font(.body)

                    Text("Fasting during the sacred month of Ramadan is obligatory for all adult Muslims who are physically and mentally capable. Allah (Glorified and Exalted be He) says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“The month of Ramadan [is that] in which was revealed the Quran, a guidance for the people and clear proofs of guidance and criterion” (Quran 2:185).")
                }

                Section(header: Text("PURPOSE")) {
                    Text("Fasting is not merely abstaining from physical needs but also involves refraining from sinful speech, actions, and thoughts. Its purpose is to develop **Taqwa (تَقوَى)**, God-consciousness, and purify the soul.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                    ScriptureQuote(text: "“O you who have believed, decreed upon you is fasting as it was decreed upon those before you that you may become righteous” (Quran 2:183).")
                }

                Section(header: Text("METHOD")) {
                    Text("The fasting day begins before dawn with a recommended Sunnah meal called **Suhoor** (سُحُور) and ends at sunset with **Iftar** (إِفطَار), traditionally breaking the fast with dates and water as Prophet Muhammad did (peace and blessings be upon him).")
                        .font(.body)

                    Text("During the fasting hours, Muslims engage in acts of worship such as prayer, Quran recitation, and charity.").font(.body)
                }

                Section(header: Text("EXEMPTIONS")) {
                    Text("Fasting is mandatory for all capable Muslims, but there are exemptions for:")
                        .font(.body)
                    Text("1. The sick.").font(.body)
                    Text("2. Travelers.").font(.body)
                    Text("3. Pregnant or nursing women.").font(.body)
                    Text("4. Women during menstruation.").font(.body)
                    Text("Those exempted are required to make up the missed fasts later or pay **fidya (فِديَة)**, compensation, if they cannot fast.")
                        .font(.body)
                }

                Section(header: Text("SPIRITUAL BENEFITS")) {
                    Text("Sawm is a means of spiritual growth and self-discipline. It helps Muslims focus on worship, gratitude, and reliance on Allah (Glorified and Exalted be He). It also fosters empathy for the less fortunate and strengthens the sense of community. Prophet Muhammad (peace and blessings be upon him) said: ")
                        .font(.body)

                    ScriptureQuote(text: "“Verily, the smell of the mouth of a fasting person is better to Allah than the smell of musk.“ (Sahih al-Bukhari 5927)", dimmed: true)
                }

                Section(header: Text("REWARDS OF FASTING")) {
                    Text("The Prophet Muhammad (peace and blessings be upon him) also said:").font(.body)
                    ScriptureQuote(text: "“Whoever observes fasts during the month of Ramadan out of sincere faith, and hoping to attain Allah's rewards, then all his past sins will be forgiven” (Sahih al-Bukhari 38).", dimmed: true)

                    Text("Fasting is an act of worship that purifies the heart and brings immense spiritual rewards from Allah.")
                        .font(.body)
                }

                Section(header: Text("SIGNIFICANCE OF RAMADAN")) {
                    Text("Ramadan is not only the month of fasting but also the month in which the Quran was revealed. It is a time of intense worship and reflection, culminating in **Laylat al-Qadr (لَيلَة القَدر)**, the Night of Decree, which is better than a thousand months.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                    ScriptureQuote(text: "“Indeed, We sent the Quran down during the Night of Decree. And what can make you know what is the Night of Decree? The Night of Decree is better than a thousand months” (Quran 97:1-3).")
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("More than hunger, fasting trains the soul, deepens gratitude and empathy for the poor, and earns great reward and the forgiveness of past sins.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Sawm")
    }
}

struct ZakahView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Zakah is an obligatory charity - 2.5% of qualifying wealth held for a lunar year - that purifies wealth and supports those in need.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("**Zakah (زَكَاة)**, from the root **z-k-w (ز ك و)** meaning “purification” and “growth,” is the third pillar of Islam. It is an obligatory charity that purifies wealth, acknowledges Allah’s blessings, and helps build a just and compassionate society.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                    ScriptureQuote(text: "“Take, [O Muhammad], from their wealth a charity by which you purify them and cause them to increase, and invoke [Allah’s blessings] upon them. Indeed, your invocations are reassurance for them. And Allah is Hearing and Knowing” (Quran 9:103).")
                }

                Section(header: Text("PURPOSE")) {
                    Text("The purpose of Zakah is threefold:").font(.body)
                    Text("1. **Spiritual Purification**: Cleanses the soul from greed and materialism, fostering gratitude to Allah (Glorified and Exalted be He).").font(.body)
                    Text("2. **Economic Justice**: Redistributes wealth to support those in need, reducing poverty and inequality.").font(.body)
                    Text("3. **Community Strengthening**: Strengthens ties within the Muslim community by helping the less fortunate.").font(.body)
                }

                Section(header: Text("OBLIGATIONS AND ELIGIBILITY")) {
                    Text("Zakah is obligatory for every Muslim who possesses wealth above the **Nisab (نِصَاب)** (minimum threshold of wealth) for a full lunar year. The Nisab is calculated based on the value of 85 grams of gold or 595 grams of silver.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) specifies eight categories of Zakah recipients in the Quran:").font(.body)
                    ScriptureQuote(text: "“Zakah expenditures are only for the poor, the needy, those employed to collect it, for bringing hearts together, for freeing captives [or slaves], for those in debt, for the cause of Allah, and for the traveler [in need]” (Quran 9:60).")
                }

                Section(header: Text("CALCULATION")) {
                    Text("Zakah is calculated at a standard rate of **2.5%** of one’s total savings and assets that meet the Nisab threshold. This includes cash, gold, silver, investments, and business assets.")
                        .font(.body)
                    Text("Muslims are encouraged to calculate and distribute their Zakah during Ramadan, although it can be paid at any time of the year.")
                        .font(.body)
                }

                Section(header: Text("REWARDS OF ZAKAH")) {
                    Text("The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“Charity does not decrease wealth, no one forgives another except that Allah increases his honor, and no one humbles himself for the sake of Allah except that Allah raises his status” (Sahih Muslim 2588).", dimmed: true)

                    Text("He also said:").font(.body)
                    ScriptureQuote(text: "“Protect yourself from Hellfire even with half a date [in charity]” (Sahih al-Bukhari 1417).", dimmed: true)

                    Text("Fulfilling the obligation of Zakah not only earns Allah’s pleasure but also protects one’s soul and wealth from harm.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("By giving what is due, a Muslim cleanses wealth of greed, strengthens the community, and earns Allah's blessing and increase.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Zakah")
    }
}

struct HajjView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Hajj is the pilgrimage to the Kaaba in Makkah, obligatory once in a lifetime for those able - a journey of submission, forgiveness, and unity.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("**Hajj (حَجّ)**, from the root **h-j-j (ح ج ج)** meaning “to intend” or “to set out for” a great destination, is the fifth and final pillar of Islam. It is the pilgrimage to the **Kaaba (الكَعبَة)** in Makkah - the **Qibla (قِبلَة)**, the direction of prayer, for Muslims worldwide - performed annually in the month of **Dhul-Hijjah (ذُو الحِجَّة)** as a profound act of worship and submission to Allah (Glorified and Exalted be He).")
                        .font(.body)

                    Text("Hajj is a journey of spiritual renewal, forgiveness, and unity among Muslims, symbolizing submission to Allah and the equality of all believers.")
                        .font(.body)
                }

                Section(header: Text("OBLIGATION")) {
                    Text("Hajj is mandatory for every Muslim who is physically and financially capable at least once in their lifetime. Allah (Glorified and Exalted be He) says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“And [due] to Allah from the people is a pilgrimage to the House – for whoever is able to find thereto a way. But whoever disbelieves – then indeed, Allah is free from need of the worlds” (Quran 3:97).")

                    Text("Hajj is both a personal and communal act of worship, emphasizing the importance of fulfilling one's obligations to Allah and the global Muslim community.")
                        .font(.body)
                }

                Section(header: Text("HISTORICAL ROOTS")) {
                    Text("Hajj commemorates the unwavering faith and sacrifices of Prophet Ibrahim (Abraham, peace be upon him), his wife Hajar (may Allah be pleased with her), and their son Prophet Ismail (Ishmael, peace be upon him).")
                        .font(.body)

                    Text("Prophet Ibrahim (peace be upon him) and Prophet Ismail (peace be upon him) were commanded by Allah to build the Kaaba, the sacred House of Allah. Allah says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“And [mention] when Ibrahim was raising the foundations of the House and [with him] Ismail, [saying], 'Our Lord, accept [this] from us. Indeed You are the Hearing, the Knowing'” (Quran 2:127).")

                    Text("The rituals of Hajj also commemorate Hajar's (may Allah be pleased with her) trust in Allah as she searched for water for her infant son, Ismail. Her desperate search between the hills of Safa and Marwah is reenacted during Hajj as the Sa’i.")
                        .font(.body)
                }

                Section(header: Text("RITUALS OF HAJJ")) {
                    Text("The key rituals of Hajj include:").font(.body)
                    Text("1. **Ihram (إِحرَام)**: entering a state of purity and wearing special garments.").font(.body)
                    Text("2. **Tawaf (طَوَاف)**: circling the Kaaba seven times in reverence.").font(.body)
                    Text("3. **Sa'i (سَعي)**: walking between the hills of Safa and Marwah, commemorating Hajar’s (may Allah be pleased with her) search for water.").font(.body)
                    Text("4. **Arafat (عَرَفَات)**: standing in prayer and supplication at the Plain of Arafat, seeking Allah’s forgiveness.").font(.body)
                    Text("5. **Ramy al-Jamarat (رَمي الجَمَرَات)**: throwing pebbles at the pillars in Mina, symbolizing rejection of the devil’s temptations.").font(.body)
                    Text("6. **Qurbani (قُربَان)**: sacrificing an animal to commemorate Prophet Ibrahim’s (peace be upon him) willingness to sacrifice his son for Allah’s command.").font(.body)
                    Text("7. **Tawaf al-Ifadah (طَوَاف الإِفَاضَة)**: a final circumambulation of the Kaaba to complete the pilgrimage.").font(.body)
                }

                Section(header: Text("SPIRITUAL PURPOSE")) {
                    Text("Hajj represents submission to Allah and a renewal of faith. It unites Muslims from diverse backgrounds in worship, showcasing the universal brotherhood of Islam.")
                        .font(.body)

                    Text("The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“Whoever performs Hajj (pilgrimage) and does not have sexual relations (with his wife), nor commits sin, nor disputes unjustly (during Hajj), then he returns from Hajj as pure and free from sins as on the day on which his mother gave birth to him” (Riyad as-Salihin 1274).", dimmed: true)
                }

                Section(header: Text("CONCLUSION")) {
                    Text("Hajj is a profound spiritual journey that strengthens a Muslim’s connection with Allah (Glorified and Exalted be He). By performing Hajj, Muslims fulfill one of the greatest acts of worship, seeking Allah’s mercy, forgiveness, and eternal reward.")
                        .font(.body)

                    Text("Allah says in the Quran:").font(.body)
                    ScriptureQuote(text: "“And proclaim to the people the Hajj [pilgrimage]; they will come to you on foot and on every lean camel; they will come from every distant pass” (Quran 22:27).")
                }

                Section(header: Text("LEARN MORE")) {
                    Text("Learn how to perform Hajj here: https://www.islamic-relief.ie/hajj-guide/")
                        .font(.caption)

                    Text("Malcolm X's letter about Hajj: https://www.icit-digital.org/articles/malcolm-x-s-letter-from-makkah-april-20-1964")
                        .font(.caption)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Retracing the legacy of Ibrahim and his family, Hajj gathers Muslims of every background as equals before Allah, returning the sincere pilgrim cleansed of sin.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Hajj")
    }
}

import SwiftUI

struct ImanPillarsView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        Section(header: Text("THE 6 PILLARS OF IMAN (FAITH)")) {
            NavigationLink(destination: LazyDestination { GodView() }) {
                Text("Belief in Allah")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { AngelsView() }) {
                Text("Belief in the Angels")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { BooksView() }) {
                Text("Belief in the Books")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { ProphetsView() }) {
                Text("Belief in the Prophets")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { DayView() }) {
                Text("Belief in the Last Day")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { QadarView() }) {
                Text("Belief in Al-Qadar")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
        }
    }
}

struct GodView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the first pillar of faith is to believe in Allah alone - His Lordship, His sole right to worship, and His perfect Names and attributes.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("Belief in Allah (Glorified and Exalted be He), the One and Only God, is the core of Islamic faith, **Iman (إِيمَان)**. He is the Creator and Sustainer of the entire universe. He is eternal, self-sustaining, and has no equal. Allah (Glorified and Exalted be He) says in the Quran:")
                        .font(.body)
                    Text("“Say, ‘He is Allah, [who is] One, Allah, the Eternal Refuge. He neither begets nor is born, Nor is there to Him any equivalent.’” (Quran 112:1-4)")
                        .foregroundColor(settings.accentColor.color)
                        .font(.title3)

                    Text("This chapter, **Surah Al-Ikhlas (الإِخلَاص)**, summarizes Allah’s Oneness and clarifies that He does not share His divine attributes with any of His creation. Muslims affirm that He is All-Knowing, All-Merciful, and above all limitations.")
                        .font(.body)
                }

                Section(header: Text("MEANING OF BELIEF IN ALLAH")) {
                    Text("Belief in Allah, **al-Iman billah (الإِيمَان بِاللَّه)**, involves affirming His Oneness, **Tawhid (تَوحِيد)**, and understanding His divine attributes. It consists of three core aspects:")
                        .font(.body)
                    Text("1. **Tawhid al-Rububiyyah (تَوحِيد الرُّبُوبِيَّة)** - Oneness of Lordship: Believing that Allah alone is the Creator, Sustainer, and Manager of all that exists.")
                        .font(.body)
                    Text("2. **Tawhid al-Uluhiyyah (تَوحِيد الأُلُوهِيَّة)** - Oneness of Worship: Worshiping Allah alone without associating partners with Him.")
                        .font(.body)
                    Text("3. **Tawhid al-Asma wa al-Sifat (تَوحِيد الأَسمَاء وَالصِّفَات)** - Oneness of Names and Attributes: Affirming Allah’s names and attributes as mentioned in the Quran and Sunnah, without distortion or anthropomorphism.")
                        .font(.body)
                }

                Section(header: Text("QURANIC EVIDENCE")) {
                    Text("Allah (Glorified and Exalted be He) repeatedly emphasizes His Oneness and supremacy in the Quran. He says:")
                        .font(.body)
                    Text("“Allah – there is no deity except Him, the Ever-Living, the Sustainer of [all] existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth” (Quran 2:255, Ayat al-Kursi).")
                        .foregroundColor(settings.accentColor.color)
                        .font(.title3)

                    Text("“And your god is one God. There is no deity [worthy of worship] except Him, the Entirely Merciful, the Especially Merciful” (Quran 2:163).")
                        .foregroundColor(settings.accentColor.color)
                        .font(.title3)
                }

                Section(header: Text("HADITH ON BELIEF IN ALLAH")) {
                    Text("The Prophet Muhammad (peace and blessings be upon him) explained the essence of belief in Allah. He said:")
                        .font(.body)
                    Text("“[Iman is] that you affirm your faith in Allah, in His angels, in His Books, in His Messengers, in the Day of Judgment, and you affirm your faith in the Divine Decree (Qadar) about good and evil” (Sahih Muslim 8a).")
                        .foregroundColor(settings.accentColor.color.opacity(0.85))
                        .font(.title3)
                }

                Section(header: Text("IMPORTANCE OF BELIEF IN ALLAH")) {
                    Text("Belief in Allah is the foundation of a Muslim’s faith and actions. It shapes a person’s worldview, guiding them to trust Allah, obey His commands, and rely on His mercy and justice.")
                        .font(.body)

                    Text("This belief inspires **Taqwa (تَقوَى)**, God-consciousness,, motivating Muslims to live righteously and strive for Allah’s pleasure in every aspect of their lives.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Belief in Allah anchors a Muslim's whole life: to trust Him, obey Him, and worship Him alone without any partner.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Belief in Allah")
    }
}

struct AngelsView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the angels are unseen beings created from light who never disobey Allah and carry out His commands throughout creation.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("Belief in the angels - **Malaikah (مَلَائِكَة)** - is a fundamental pillar of Islamic faith, **Iman (إِيمَان)**. Angels are unseen beings created by Allah (Glorified and Exalted be He) from light. They are sinless, do not have free will, and continuously obey Allah’s commands. Their roles include delivering revelations, recording deeds, and carrying out Allah’s orders in the universe. Allah, however, does not need angels or anything else, as He is completely self-sufficient, **Al-Ghaniyy (الغَنِيّ)**, and sustains all existence, **Al-Qayyum (القَيُّوم)**. The creation of angels reflects Allah’s wisdom and His divine plan.")
                        .font(.body)

                    Text("The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“The angels were created from light” (Sahih Muslim 2996).", dimmed: true)
                }

                Section(header: Text("CHARACTERISTICS OF ANGELS")) {
                    Text("Angels possess unique attributes that set them apart from other creations:")
                        .font(.body)

                    Text("1. **Created from Light**: Unlike humans and jinn, angels are made of light.")
                        .font(.body)
                    Text("2. **Infallible Obedience**: They never disobey Allah and do exactly as commanded. Allah says in the Quran:")
                        .font(.body)
                    Text("“They do not disobey Allah in what He commands them but do whatever they are commanded” (Quran 66:6).")
                        .foregroundColor(settings.accentColor.color)
                        .font(.title3)
                    Text("3. **Invisible to Humans**: Although normally unseen, they can appear in human form, as Angel Jibril (Gabriel) did when he visited the Prophet Muhammad (peace and blessings be upon him).")
                        .font(.body)
                    Text("4. **Lack of Free Will**: Angels exist solely to serve Allah and cannot deviate from their roles.")
                        .font(.body)
                }

                Section(header: Text("ROLES AND RESPONSIBILITIES")) {
                    Text("Angels have distinct duties, demonstrating Allah’s meticulous organization of creation:")
                        .font(.body)

                    Text("1. **Jibril (Gabriel)**: The angel of revelation who conveyed Allah’s messages to the prophets, including the Quran to Prophet Muhammad (peace and blessings be upon him). Allah says:")
                        .font(.body)
                    Text("“Say, [O Muhammad], ‘Whoever is an enemy to Gabriel – it is he who has brought it [the Quran] down upon your heart by permission of Allah.’” (Quran 2:97)")
                        .foregroundColor(settings.accentColor.color)
                        .font(.title3)

                    Text("2. **Mikail (مِيكَائِيل)** - Michael: Responsible for provisions, including rain and sustenance.")
                        .font(.body)

                    Text("3. **Israfil (إِسرَافِيل)**: The angel who will blow the trumpet to signal the Day of Judgment.")
                        .font(.body)

                    Text("4. **Malik (مَالِك)**: The guardian of Hellfire. Allah says:")
                        .font(.body)
                    Text("“And they will call, ‘O Malik, let your Lord put an end to us!’ He will say, ‘Indeed, you will remain.’” (Quran 43:77)")
                        .foregroundColor(settings.accentColor.color)
                        .font(.title3)

                    Text("5. **Kiraman Katibin (كِرَامًا كَاتِبِين)**: Angels who record every deed:")
                        .font(.body)
                    Text("“Man does not utter any word except that with him is an observer prepared [to record]” (Quran 50:18).")
                        .foregroundColor(settings.accentColor.color)
                        .font(.title3)

                    Text("6. **Munkar and Nakir (مُنكَر وَنَكِير)**: Angels who question the deceased in their graves about their faith.")
                        .font(.body)

                    Text("7. **The Keeper of Paradise (خَازِن الجَنَّة)**: an angel appointed over its gates. The authentic hadith calls him only “the keeper” (Sahih Muslim 197); the name “Ridwan” is widely known among later scholars but is not established in the Quran or the authentic Sunnah.")
                        .font(.body)
                }

                Section(header: Text("IMPORTANCE OF BELIEF IN ANGELS")) {
                    Text("Belief in angels is the second pillar of Iman and is crucial for a complete understanding of Islam. It has profound implications for a Muslim’s faith:")
                        .font(.body)

                    Text("1. **Strengthens Taqwa**: Awareness of recording angels motivates Muslims to be mindful of their actions.")
                        .font(.body)
                    Text("2. **Demonstrates Allah’s Sovereignty**: Angels fulfill Allah’s commands, showcasing His power and control over creation.")
                        .font(.body)
                    Text("3. **Connection to Revelation**: Through Angel Jibril, Allah’s guidance was conveyed to humanity.")
                        .font(.body)
                }

                Section(header: Text("HADITH ON ANGELS")) {
                    Text("The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“When Allah loves a servant, He calls Jibril and says: ‘I love so-and-so; therefore, love him.’ So Jibril loves him. Then Jibril announces to the inhabitants of the heavens: ‘Allah loves so-and-so; therefore, love him.’ So the inhabitants of the heavens love him. Then he is granted acceptance among the people of the earth” (Sahih al-Bukhari 7485).", dimmed: true)
                }

                Section(header: Text("CONCLUSION")) {
                    Text("Angels are integral to the Islamic understanding of the unseen world. Their obedience, dedication, and specific roles serve as a reminder of Allah’s omnipotence and meticulous care in organizing creation. Belief in angels strengthens a Muslim’s faith, instilling awe and awareness of the divine presence in all aspects of life.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Belief in the angels deepens awe of Allah's dominion and the awareness that our words and deeds are seen and recorded.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Belief in the Angels")
    }
}

struct BooksView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Allah revealed scriptures to His prophets - including the Torah, Psalms, and Gospel - culminating in the Quran, the final and preserved revelation.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("Allah (Glorified and Exalted be He) revealed divine scriptures to various prophets. These scriptures were sent to guide humanity to righteousness and worship of Allah alone. They include the Scrolls of Ibrahim (Abraham, peace be upon him), the Torah given to Musa (Moses, peace be upon him), the Psalms given to Dawud (David, peace be upon him), the Gospel given to Isa (Jesus, peace be upon him), and the Quran given to Muhammad (peace and blessings be upon him).")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                    ScriptureQuote(text: "“Indeed, We sent down the Torah, in which was guidance and light” (Quran 5:44).")

                    Text("Each scripture served as a guide for its respective nation and time, culminating in the Quran, which is the final and universal revelation.")
                        .font(.body)
                }

                Section(header: Text("THE QURAN")) {
                    Text("The **Quran (القُرآن)**, meaning “the Recitation,” is the final and complete revelation from Allah, sent to all of humanity through the Prophet Muhammad (peace and blessings be upon him). It is preserved word for word, as Allah has promised:")
                        .font(.body)
                    ScriptureQuote(text: "“Indeed, it is We who sent down the Quran and indeed, We will be its guardian” (Quran 15:9).")

                    Text("The Quran confirms and corrects previous scriptures while providing comprehensive guidance for all aspects of life. It remains unchanged since its revelation and is recited, memorized, and revered by Muslims worldwide.")
                        .font(.body)
                }

                Section(header: Text("PREVIOUS SCRIPTURES")) {
                    Text("1. **Tawrah (التَّورَاة)** - the Torah: Revealed to Musa (Moses, peace be upon him), it contained laws and guidance for the Children of Israel. Over time, the original text was altered, and its authenticity was compromised.")
                        .font(.body)

                    Text("2. **Zabur (الزَّبُور)** - the Psalms: Revealed to Dawud (David, peace be upon him), it was a collection of hymns and praises dedicated to Allah.")
                        .font(.body)

                    Text("3. **Injil (الإِنجِيل)** - the Gospel: Revealed to Isa (Jesus, peace be upon him), it confirmed the Torah and brought new guidance. However, the original Gospel has been lost, and what exists today are interpretations and altered accounts.")
                        .font(.body)

                    Text("4. **Suhuf (صُحُف)** - the Scrolls: Revealed to Ibrahim (Abraham, peace be upon him) and Musa (Moses, peace be upon him), these contained foundational teachings and guidance. They are mentioned in the Quran but no longer exist.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) says:").font(.body)
                    ScriptureQuote(text: "“Indeed, this is in the former scriptures, the scriptures of Abraham and Moses” (Quran 87:18-19).")
                }

                Section(header: Text("IMPORTANCE OF BELIEVING IN THE BOOKS")) {
                    Text("Belief in Allah’s books is a fundamental pillar of Iman (faith). The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“[Iman is] that you affirm your faith in Allah, in His angels, in His Books, in His Messengers, in the Day of Judgment, and you affirm your faith in the Divine Decree (Qadar) about good and evil” (Sahih Muslim 8a).", dimmed: true)

                    Text("Each scripture taught monotheism, **Tawhid (تَوحِيد)**, and righteousness, serving as a guide for the people of its time. The Quran, as the final revelation, is universal and timeless, applicable to all of humanity until the Day of Judgment.")
                        .font(.body)
                }

                Section(header: Text("DIFFERENCES BETWEEN SCRIPTURES")) {
                    Text("1. **Preservation:** Unlike earlier scriptures, which were altered or lost, the Quran has been perfectly preserved as promised by Allah.")
                        .font(.body)

                    Text("2. **Universality:** Previous scriptures were meant for specific nations and times, while the Quran is for all of humanity and all time.")
                        .font(.body)

                    Text("3. **Completeness:** The Quran encompasses all necessary guidance, confirming and completing previous revelations.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Earlier scriptures guided their nations but were altered or lost; the Quran alone remains perfectly preserved as Allah's guidance for all time.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Belief in the Books")
    }
}

struct ProphetsView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Allah sent prophets to call people to worship Him alone, from Adam to the final Messenger, Muhammad.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("""
                    Allah sent prophets to every nation, and a Muslim believes in every one of them. Prophets were chosen by Allah to guide their communities to monotheism and righteous living. The Quran mentions 25 prophets by name:
                    - Adam - آدَم
                    - Idris (Enoch) - إِدرِيس
                    - Nuh (Noah) - نُوح
                    - Hud (Heber) - هُود
                    - Saleh - صَالِح
                    - Lut (Lot) - لُوط
                    - Ibrahim (Abraham) - إِبرَاهِيم
                    - Ismail (Ishmael) - إِسمَاعِيل
                    - Ishaq (Isaac) - إِسحَاق
                    - Yaqub (Jacob) - يَعقُوب
                    - Yusuf (Joseph) - يُوسُف
                    - Shu’aib (Jethro) - شُعَيب
                    - Ayyub (Job) - أَيُّوب
                    - Dhul-Kifl - ذُو الكِفل
                    - Musa (Moses) - مُوسَى
                    - Harun (Aaron) - هَارُون
                    - Dawud (David) - دَاوُود
                    - Sulayman (Solomon) - سُلَيمَان
                    - Ilyas (Elias) - إِليَاس
                    - Alyasa (Elisha) - اليَسَع
                    - Yunus (Jonah) - يُونُس
                    - Zakariya (Zachariah) - زَكَرِيَّا
                    - Yahya (John the Baptist) - يَحيَى
                    - Isa (Jesus) - عِيسَى
                    - Muhammad - مُحَمَّد
                    """)
                    .font(.body)

                    Text("Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                    ScriptureQuote(text: "“And We gave to Abraham, Isaac and Jacob - all [of them] We guided. And Noah We guided before; and among his descendants, David and Solomon and Job and Joseph and Moses and Aaron. Thus do We reward the doers of good. And Zechariah and John and Jesus and Elias - and all were of the righteous” (Quran 6:84-85).")

                    Text("Each prophet conveyed Allah’s guidance and served as role models for their people. While all prophets were sent to specific nations and times, Prophet Muhammad was sent as the final messenger for all of humanity. Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                    ScriptureQuote(text: "“Muhammad is not the father of [any] one of your men, but [he is] the Messenger of Allah and the seal of the prophets” (Quran 33:40).")
                }

                Section(header: Text("PROPHETS AND MESSENGERS")) {
                    Text("There is a distinction between a prophet, **Nabi (نَبِيّ)**, and a messenger, **Rasul (رَسُول)**:").font(.body)

                    Text("1. **Prophet, Nabi (نَبِيّ):** From the root **n-b-a (ن ب أ)**, to bring news. A prophet receives revelation from Allah and upholds and reinforces the law of a previous messenger.").font(.body)
                    Text("Example: Harun (هَارُون), Aaron, was a prophet who supported Musa (مُوسَى), Moses, in spreading the Torah's teachings.").font(.body)

                    Text("2. **Messenger, Rasul (رَسُول):** From the root **r-s-l (ر س ل)**, to send. A messenger is sent with a new scripture or divine law for their people.").font(.body)
                    Text("Example: Muhammad (مُحَمَّد) was a messenger who brought the Quran, the final revelation.").font(.body)

                    Text("Every messenger is a prophet, but not every prophet is a messenger. Belief in them is not selective: to reject one prophet is to reject them all, because the One who sent them is One.").font(.body)
                }

                Section(header: Text("THE CHILDREN OF ISRAEL")) {
                    Text("More prophets were sent to the **Children of Israel, Bani Israil (بَنِي إِسرَائِيل)**, than to any other people. Allah favoured them openly, and the Quran says so:")
                        .font(.body)
                    ScriptureQuote(text: "“O Children of Israel, remember My favor which I have bestowed upon you and that I preferred you over the worlds” (Quran 2:47).")

                    Text("That favour came with a **covenant, Mithaq (مِيثَاق)**: to worship Allah alone, to uphold the Torah, and to obey the prophets sent to them. The favour was never a birthright. It was a trust, and a trust can be broken.")
                        .font(.body)

                    Text("They broke it repeatedly. They worshipped the calf while Musa (peace be upon him) was away, they demanded to see Allah openly, they refused to enter the land they were commanded to enter, and they twisted the words of the scripture from their places. Worst of all, when the prophets came to them with what they did not want to hear, they rejected them, and they killed them. Allah says:")
                        .font(.body)
                    ScriptureQuote(text: "“And they were covered with humiliation and poverty and returned with anger from Allah. That was because they [repeatedly] disbelieved in the signs of Allah and killed the prophets without right. That was because they disobeyed and were [habitually] transgressing” (Quran 2:61).")

                    Text("Among those they sought to kill were Zakariya and Yahya (peace be upon them), and they plotted against Isa (peace be upon him), though Allah raised him to Himself and saved him from them.")
                        .font(.body)

                    Text("So the covenant was withdrawn from them and the message was carried on through the line of Ismail (إِسمَاعِيل), in Prophet Muhammad (peace and blessings be upon him). This is the crucial point: the covenant was never about lineage. It was about obedience. It was taken from them because of what they did, and it can be lost by anyone who does the same.")
                        .font(.body)

                    Text("This is a warning to the Muslims before it is a criticism of anyone else. Allah does not favour a people for their ancestry. He favours them for their taqwa, and He removes His favour when they abandon it.")
                        .font(.body)
                }

                Section(header: Text("IMPORTANCE OF BELIEF IN PROPHETS")) {
                    Text("Belief in the prophets is a pillar of **Iman (إِيمَان)**, faith. The Prophet Muhammad said:").font(.body)
                    ScriptureQuote(text: "“[Iman is] that you affirm your faith in Allah, in His angels, in His Books, in His Messengers, in the Day of Judgment, and you affirm your faith in the Divine Decree (Qadar) about good and evil” (Sahih Muslim 8a).", dimmed: true)

                    Text("Muslims respect and honor all prophets equally, as they all conveyed the same message: to worship Allah alone. Allah (Glorified and Exalted be He) says:").font(.body)
                    ScriptureQuote(text: "“The Messenger has believed in what was revealed to him from his Lord, and [so have] the believers. All of them have believed in Allah, His angels, His books, His messengers” (Quran 2:285).")
                }

                Section(header: Text("LEGACY OF PROPHETS")) {
                    Text("Prophets were sent to guide humanity and exemplify righteousness. Their lives demonstrate the highest moral and spiritual qualities. The Quran recounts their stories as lessons and reminders for believers.")
                        .font(.body)

                    Text("The final prophet, Muhammad, delivered the Quran and established a comprehensive way of life, leaving an eternal legacy of guidance for all humanity.")
                        .font(.body)
                }

                Section(header: Text("RESOURCE")) {
                    Text("For a detailed family tree of the prophets: https://madinahmedia.com/family-tree-of-prophets-in-islam/")
                        .font(.caption)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("The prophets all brought one message - worship of Allah alone - and Muhammad sealed and completed that guidance for all humanity.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Belief in the Prophets")
    }
}

struct DayView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: on the Last Day, Allah will resurrect all people and judge them for their deeds with perfect justice.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("Belief in the Last Day - **Yawm al-Qiyamah (يَوم القِيَامَة)**, the Day of Resurrection - is a cornerstone of Islam and the fifth pillar of **Iman (إِيمَان)**, faith. It is the day when Allah (Glorified and Exalted be He) will resurrect all of creation to hold them accountable for their deeds. This belief is essential for understanding the purpose of life and the consequences of human actions.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                    ScriptureQuote(text: "“So whoever does an atom’s weight of good will see it, And whoever does an atom’s weight of evil will see it” (Quran 99:7-8).")
                }

                Section(header: Text("EVENTS OF THE DAY")) {
                    Text("The Day of Judgment will unfold in stages, including:").font(.body)

                    Text("1. **The Blowing of the Trumpet**: The angel Israfil will blow the trumpet twice - first to end all life and then to resurrect everyone. Allah says:").font(.body)
                    ScriptureQuote(text: "“And the Horn will be blown, and whoever is in the heavens and whoever is on the earth will fall dead except whom Allah wills. Then it will be blown again, and at once they will be standing, looking on” (Quran 39:68).")

                    Text("2. **Resurrection**: All people will rise from their graves to face their Lord. Allah says:").font(.body)
                    ScriptureQuote(text: "“And the Horn will be blown, and at once from the graves to their Lord they will hasten” (Quran 36:51).")

                    Text("3. **The Reckoning, **Hisab (حِسَاب)**,**: Every individual’s deeds will be reviewed, and their record of actions will be presented to them. Those who receive their record in their right hand will rejoice, while those who receive it in their left will despair.").font(.body)

                    Text("4. **The Scale, **Mizan (مِيزَان)**,**: Deeds will be weighed on a divine scale. Good deeds that outweigh bad deeds will lead to Paradise. Allah says:").font(.body)
                    ScriptureQuote(text: "“And the weighing [of deeds] that Day will be the truth. So those whose scales are heavy - it is they who will be successful” (Quran 7:8).")

                    Text("5. **The Bridge, **As-Sirat (الصِّرَاط)**,**: A bridge over Hellfire that all people must cross. The righteous will cross safely, while others will fall.").font(.body)
                }

                Section(header: Text("IMPORTANCE OF BELIEF IN THE DAY OF JUDGMENT")) {
                    Text("1. **Accountability**: Believing in the Day of Judgment instills a sense of accountability. Every action, no matter how small, will be rewarded or punished accordingly.").font(.body)

                    Text("2. **Moral Uprightness**: Encourages Muslims to lead righteous lives, avoid sin, and fulfill their obligations to Allah and others.").font(.body)

                    Text("3. **Justice and Fairness**: The Day of Judgment is the ultimate manifestation of Allah’s justice. Every wrong will be rectified, and no one will be wronged. Allah says:").font(.body)
                    ScriptureQuote(text: "“Indeed, Allah does not wrong the people at all, but it is the people who are wronging themselves” (Quran 10:44).")

                    Text("4. **Hope and Fear**: Belief in the Day of Judgment inspires hope in Allah’s mercy and fear of His punishment, creating a balance in a Muslim’s spiritual life.").font(.body)
                }

                Section(header: Text("QURANIC EMPHASIS")) {
                    Text("Allah (Glorified and Exalted be He) repeatedly emphasizes the Day of Judgment in the Quran as a reminder of the ultimate return to Him. He says:")
                        .font(.body)
                    ScriptureQuote(text: "“The Day they come forth, nothing concerning them will be concealed from Allah. To whom belongs [all] sovereignty this Day? To Allah, the One, the Prevailing” (Quran 40:16).")

                    Text("In Surah Al-Qariah, Allah vividly describes the weighing of deeds:").font(.body)
                    ScriptureQuote(text: "“Then as for one whose scales are heavy [with good deeds], he will be in a pleasant life. But as for one whose scales are light, his refuge will be an abyss” (Quran 101:6-9).")

                    Text("The Prophet Muhammad (peace and blessings be upon him) said about the Day of Judgment:").font(.body)
                    ScriptureQuote(text: "“The rights of justice will surely be restored to their people on the Day of Resurrection, even the hornless sheep will lay claim to the horned sheep” (Sahih Muslim 2582).", dimmed: true)

                    Text("This highlights Allah’s perfect justice, where no soul will be wronged, not even among animals.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Certainty in the Last Day gives life meaning and accountability, balancing hope in Allah's mercy with fear of His justice.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Belief in the Last Day")
    }
}

struct QadarView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Al-Qadar means everything happens by Allah's knowledge, writing, will, and creation - while people still choose and are accountable.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("Belief in **Qadar (قَدَر)** - from the root **q-d-r (ق د ر)**, to measure out or decree - or divine decree, is the sixth pillar of **Iman (إِيمَان)**, faith. It is the belief that everything occurs by the will, knowledge, and command of Allah (Glorified and Exalted be He). This includes both the good and the bad, as Allah’s wisdom is perfect, and His plans are flawless.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                    ScriptureQuote(text: "“No disaster strikes upon the earth or among yourselves except that it is in a register before We bring it into being - indeed that, for Allah, is easy” (Quran 57:22).")

                    Text("This belief fosters patience during trials, gratitude in blessings, and complete trust in Allah’s wisdom. It also reminds Muslims that Allah’s knowledge encompasses all things and that nothing happens outside of His will.")
                        .font(.body)
                }

                Section(header: Text("COMPONENTS OF QADR")) {
                    Text("Scholars identify four essential components of Qadar:").font(.body)

                    Text("1. **Allah’s Knowledge - Ilm (عِلم)**: Allah’s knowledge is infinite and perfect. He knows everything that has happened, is happening, and will happen. Allah says:").font(.body)
                    ScriptureQuote(text: "“And with Him are the keys of the unseen; none knows them except Him. And He knows what is on the land and in the sea. Not a leaf falls but that He knows it” (Quran 6:59).")

                    Text("2. **Allah’s Writing - Kitabah (كِتَابَة)**: All things are written in **Al-Lawh Al-Mahfuz (اللَّوح المَحفُوظ)**, the Preserved Tablet,, where every event, action, and outcome is recorded. Allah says:").font(.body)
                    ScriptureQuote(text: "“Do you not know that Allah knows what is in the heaven and earth? Indeed, it is all in a record. Indeed that, for Allah, is easy” (Quran 22:70).")

                    Text("3. **Allah’s Will - Mashiah (مَشِيئَة)**: Whatever Allah wills happens, and whatever He does not will does not happen. Allah says:").font(.body)
                    ScriptureQuote(text: "“And they [i.e., the disbelievers] planned, but Allah planned. And Allah is the best of planners” (Quran 3:54).")

                    Text("4. **Allah’s Creation - Khalq (خَلق)**: Allah is the Creator of all things, including actions, circumstances, and outcomes. Allah says:").font(.body)
                    ScriptureQuote(text: "“Allah is the Creator of all things, and He is, over all things, Disposer of affairs” (Quran 39:62).")
                }

                Section(header: Text("BALANCE BETWEEN FREE WILL AND QADR")) {
                    Text("Islam teaches a balance between divine decree and human free will. While Allah knows and decrees all things, humans are given the freedom to make choices and are held accountable for them. This accountability ensures justice and moral responsibility.")
                        .font(.body)

                    Text("The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“Strive for that which will benefit you, seek help from Allah, and do not give up. If something befalls you, do not say, ‘If only I had done such and such,’ but say, ‘Allah decreed it, and what He willed has happened.’ For saying ‘if’ opens the door to **Shaytan (شَيطَان)**’s (Satan’s) work” (Sunan Ibn Majah 79).", dimmed: true)
                }

                Section(header: Text("PATIENT AND GRATEFUL")) {
                    Text("Belief in Qadar teaches Muslims to face life’s trials and blessings with patience and gratitude. Allah says in the Quran:").font(.body)
                    ScriptureQuote(text: "“And We will surely test you with something of fear and hunger and a loss of wealth and lives and fruits, but give good tidings to the patient - those who, when disaster strikes them, say, ‘Indeed we belong to Allah, and indeed to Him we will return.’” (Quran 2:155-156)")

                    Text("Through this belief, Muslims trust that every hardship is a test and every blessing is a favor from Allah, leading them closer to Him.")
                        .font(.body)
                }

                Section(header: Text("CONCLUSION")) {
                    Text("Belief in Qadar is a profound reminder of Allah’s ultimate authority, wisdom, and justice. It brings peace to the hearts of believers, knowing that everything happens for a reason, and Allah’s plans are always for the best. It encourages trust, patience, and gratitude in every aspect of life.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Belief in the divine decree brings patience in hardship and gratitude in ease, trusting that Allah's wisdom is always perfect.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Belief in Al-Qadar")
    }
}

import SwiftUI

struct MosquesView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        Section(header: Text("THE THREE HOLY MOSQUES")) {
            NavigationLink(destination: LazyDestination { HaramView() }) {
                Text("Masjid Al-Haram (The Holy Mosque)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { NabawiView() }) {
                Text("Masjid An-Nabawi (The Prophet’s Mosque)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { AqsaView() }) {
                Text("Masjid Al-Aqsa (The Farthest Mosque)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
        }
    }
}

struct HaramView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Masjid al-Haram in Makkah is the holiest mosque in Islam. It surrounds the Kaaba - the House of Allah and the Qiblah toward which all Muslims pray.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("Masjid Al-Haram (ٱلمَسجِدُ ٱلحَرَام), or “The Sacred Mosque,“ is located in **Makkah (مَكَّة)**, Saudi Arabia. It is the largest mosque in the world and surrounds the **Ka'bah** (ٱلكَعبَة), the holiest site in Islam. The Ka'bah is also known as “The House of Allah“ (بَيتُ ٱللَّه).")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                    ScriptureQuote(text: "“And [mention] when We made the House (the Ka'bah) a place of return for the people and [a place of] security” (Quran 2:125).")

                    Text("Masjid Al-Haram is the destination for **Hajj (حَجّ)** and **Umrah (عُمرَة)**, two pivotal acts of worship in Islam. The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“One prayer in the Sacred Mosque is better than one hundred thousand prayers elsewhere” (Sunan Ibn Majah 1406).", dimmed: true)
                }

                Section(header: Text("SIGNIFICANCE OF THE KA'BAH")) {
                    Text("The **Ka'bah** (ٱلكَعبَة), meaning “The Cube,“ is the symbolic House of Allah. It serves as the **Qiblah** (قِبلَةٌ) (direction of prayer) for Muslims worldwide. Every prayer offered by a Muslim is directed toward the Ka'bah.")
                        .font(.body)

                    Text("The Ka'bah was built by **Prophet Ibrahim** (Abraham, peace be upon him) and his son **Prophet Isma'il** (Ishmael, peace be upon him) as a place of monotheistic worship. Allah says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“And [mention] when Ibrahim was raising the foundations of the House and [with him] Isma'il, [saying], ‘Our Lord, accept [this] from us. Indeed, You are the Hearing, the Knowing.’” (Quran 2:127)")

                    Text("The **Black Stone** (ٱلحَجَرُ ٱلأَسوَد, Hajar Al-Aswad), embedded in one corner of the Ka'bah, is a sacred relic dating back to the time of Prophet Ibrahim (peace be upon him). Touching or kissing it during **Tawaf** is a Sunnah, but not obligatory.")
                        .font(.body)
                }

                Section(header: Text("THE WELL OF ZAMZAM")) {
                    Text("The **Well of Zamzam** (بِئرُ زَمزَم) is located within Masjid Al-Haram. This miraculous water source was provided by Allah for **Hajar** (may Allah be pleased with her) and her son **Isma'il** (peace be upon him) when they were left in the barren desert. The well continues to flow abundantly to this day.")
                        .font(.body)

                    Text("Drinking Zamzam water is an act of worship and holds immense spiritual blessings.").font(.body)
                }

                Section(header: Text("SPIRITUAL REWARDS AND IMPORTANCE")) {
                    Text("1. **Multiplied Rewards**: Praying in Masjid Al-Haram is rewarded 100,000 times more than praying elsewhere.")
                        .font(.body)
                    Text("2. **Forgiveness of Sins**: Performing Hajj or Umrah with sincerity cleanses one’s sins. The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“Whoever performs Hajj (pilgrimage) and does not have sexual relations (with his wife), nor commits sin, nor disputes unjustly (during Hajj), then he returns from Hajj as pure and free from sins as on the day on which his mother gave birth to him” (Riyad as-Salihin 1274).", dimmed: true)
                    Text("3. **Unity of the Ummah**: Millions of Muslims from diverse cultures and backgrounds gather in Masjid Al-Haram, symbolizing the unity and equality of the Muslim Ummah under the worship of Allah.")
                        .font(.body)
                }

                Section(header: Text("QURANIC VERSES ABOUT MAKKAH")) {
                    Text("Allah mentions the sanctity of Makkah and Masjid Al-Haram in several verses:").font(.body)
                    ScriptureQuote(text: "“Indeed, the first House [of worship] established for mankind was that at Makkah - blessed and a guidance for the worlds” (Quran 3:96).")
                    ScriptureQuote(text: "“And [mention] when We made the House (the Ka'bah) a place of return for the people and [a place of] security” (Quran 2:125).")
                }

                Section(header: Text("MASJID AL-HARAM")) {
                    Image("Al-Islam")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(24)
                            #if os(iOS)
                            .focusableImage("Al-Islam", title: "Masjid al-Haram")
                            #endif
                            #if os(iOS)
                            .contextMenu {
                                Text("Image Actions")
                                    .foregroundStyle(.secondary)

                                Button {
                                    settings.hapticFeedback()
                                    UIPasteboard.general.image = UIImage(named: "Al Haram")
                                } label: {
                                    Text("Copy Image")
                                    Image(systemName: "photo")
                                }
                            }
                            #endif
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("A single prayer here equals a hundred thousand elsewhere. It is the heart of Hajj and Umrah, where the whole Ummah gathers as equals before Allah.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Masjid Al-Haram")
    }
}

struct NabawiView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Masjid an-Nabawi in Madinah is the Prophet's own mosque and the second holiest in Islam, home to the Rawdah and his resting place.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("Masjid An-Nabawi (ٱلمَسجِد ٱلنَّبَوِي), or “The Prophet’s Mosque,“ is located in Madinah, Saudi Arabia. Originally known as Yathrib, the city was later renamed **Madinah Al-Nabi (مَدِينَة ٱلنَّبِي)**, meaning “The City of the Prophet,“ or **Madinah Al-Munawwara (ٱلمَدِينَة ٱلمُنَوَّرَة)**, “The Enlightened City,“ after the migration (Hijrah) of Prophet Muhammad (peace and blessings be upon him).")
                        .font(.body)

                    Text("This mosque, built by the Prophet (peace and blessings be upon him) in 622 CE, is the second holiest site in Islam after Masjid Al-Haram. The Prophet (peace and blessings be upon him) made it a center of worship, governance, and community life.")
                        .font(.body)

                    Text("The Prophet (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“One prayer in my mosque is better than a thousand prayers in any other mosque except Al-Masjid Al-Haram” (Sahih Bukhari 1190).", dimmed: true)
                }

                Section(header: Text("SIGNIFICANCE")) {
                    Text("Masjid An-Nabawi is home to the **Rawdah (ٱلرَّوضَة)**, an area between the Prophet's pulpit and his house, which he described as a garden from the gardens of Paradise. The Prophet (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Between my house and my pulpit there is a garden of the gardens of Paradise” (Sahih al-Bukhari 1196).", dimmed: true)

                    Text("The mosque also contains the grave of the Prophet Muhammad (peace and blessings be upon him) and his companions Abu Bakr As-Siddiq and Umar ibn Al-Khattab (may Allah be pleased with them). It is from the Sunnah to send salaam upon him when you are there.")
                        .font(.body)
                }

                Section(header: Text("A WARNING AGAINST SHIRK")) {
                    Text("This must be clear, because it is where people fall. You do **not** pray to the Prophet (peace and blessings be upon him). You do **not** pray facing his grave. You do not ask him for anything, you do not seek help or intercession from him, and you do not circle or touch the grave seeking blessing. All of that is **shirk (شِرك)**, associating partners with Allah, and it is the one sin Allah does not forgive if a person dies upon it.")
                        .font(.body)

                    Text("Duaa is worship, and worship belongs to Allah alone:")
                        .font(.body)
                    ScriptureQuote(text: "“And the mosques are for Allah, so do not invoke with Allah anyone” (Quran 72:18).")

                    Text("When you pray in Masjid An-Nabawi, you face the Qiblah, towards the Kaaba in Makkah, exactly as you would anywhere else on earth. The grave happens to lie in that direction from parts of the mosque; that is a fact of geography, not a thing to be prayed towards.")
                        .font(.body)

                    Text("The Prophet (peace and blessings be upon him) himself warned against precisely this, in his final illness:")
                        .font(.body)
                    ScriptureQuote(text: "“May Allah curse the Jews and the Christians, for they took the graves of their prophets as places of worship” (Sahih al-Bukhari 435, Sahih Muslim 531).", dimmed: true)

                    Text("He also said: “Do not make my grave a place of festivity, and send blessings upon me, for your blessings reach me wherever you are” (Sunan Abi Dawud 2042).")
                        .font(.body)

                    Text("So love him, follow him, and send salaah and salaam upon him abundantly. But direct every act of worship to Allah alone. That is what he taught, and honouring him means obeying him.")
                        .font(.body)
                }

                Section(header: Text("SPIRITUAL BENEFITS")) {
                    Text("1. **Multiplied Rewards**: Prayers in Masjid An-Nabawi are rewarded 1,000 times more than prayers in other mosques (except Masjid Al-Haram).")
                        .font(.body)
                    Text("2. **Connection to the Prophet**: Standing in a place where the Prophet Muhammad (peace and blessings be upon him) worshipped and led his companions strengthens one’s faith and love for him.")
                        .font(.body)
                    Text("3. **Rawdah Visit**: Visiting the Rawdah and praying there is considered highly virtuous.")
                        .font(.body)
                }

                Section(header: Text("QURANIC VERSES ABOUT THE MOSQUE")) {
                    Text("Allah emphasizes the sanctity of mosques, particularly those established on righteousness. He says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“A mosque founded on righteousness from the first day is more worthy for you to stand in” (Quran 9:108).")
                }

                Section(header: Text("MASJID AN-NABAWI")) {
                    Image("Al-Quran")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(24)
                        #if os(iOS)
                        .focusableImage("Al-Quran", title: "Masjid an-Nabawi")
                        #endif
                        #if os(iOS)
                        .contextMenu {
                            Text("Image Actions")
                                .foregroundStyle(.secondary)

                            Button {
                                settings.hapticFeedback()
                                UIPasteboard.general.image = UIImage(named: "An Nabawi")
                            } label: {
                                Text("Copy Image")
                                Image(systemName: "photo")
                            }
                        }
                        #endif
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("A prayer here equals a thousand elsewhere. It was the Prophet's center of worship and community, and visiting it deepens a believer's love for him.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Masjid An-Nabawi")
    }
}

struct AqsaView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Masjid al-Aqsa in Jerusalem is the third holiest mosque, the first Qiblah, and the destination of the Prophet's Night Journey (Isra and Mi'raj).")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("Masjid Al-Aqsa (ٱلمَسجِد ٱلأَقصَىٰ), meaning “The Farthest Mosque,“ is located in Jerusalem, Palestine, within a compound known as **Al-Haram Ash-Sharif (ٱلحَرَم ٱلشَّرِيف)**, or “The Noble Sanctuary.“ It is the third holiest mosque in Islam after Masjid Al-Haram in Makkah and Masjid An-Nabawi in Madinah.")
                        .font(.body)

                    Text("Masjid Al-Aqsa holds immense historical and spiritual significance in Islam. Allah (Glorified and Exalted be He) mentions it in the Quran:").font(.body)
                    ScriptureQuote(text: "“Exalted is He who took His Servant by night from Al-Masjid Al-Haram to Al-Masjid Al-Aqsa, whose surroundings We have blessed, to show him of Our signs. Indeed, He is the Hearing, the Seeing” (Quran 17:1).")

                    Text("It was the first Qiblah (direction of prayer) for Muslims before it was changed to the Ka'bah in Makkah, and it was the destination of the Prophet Muhammad’s (peace and blessings be upon him) Night Journey, **Isra (الإِسرَاء)**, before his Ascension, **Mi'raj (المِعرَاج)**.")
                        .font(.body)
                }

                Section(header: Text("SPIRITUAL SIGNIFICANCE")) {
                    Text("1. **First Qiblah**: Muslims initially faced Masjid Al-Aqsa during their prayers, highlighting its significance from the earliest days of Islam.").font(.body)
                    Text("2. **Al-Isra wa al-Mi'raj (الإِسرَاء وَالمِعرَاج)**: It was the destination of the miraculous Night Journey of the Prophet Muhammad (peace and blessings be upon him), during which he led all prophets in prayer before ascending to the heavens.").font(.body)
                    Text("3. **Land of Blessings**: The Quran describes the surroundings of Masjid Al-Aqsa as a blessed land. Allah says:").font(.body)
                    ScriptureQuote(text: "“And We delivered him and Lot to the land which We had blessed for all people” (Quran 21:71).")
                }

                Section(header: Text("HISTORICAL AND RELIGIOUS IMPORTANCE")) {
                    Text("Masjid Al-Aqsa is a place of worship for many prophets, including Ibrahim (Abraham), Dawud (David), and Sulaiman (Solomon) (peace be upon them). It is believed that Prophet Muhammad (peace and blessings be upon him) led all the prophets in prayer here during the Night Journey.")
                        .font(.body)

                    Text("The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“Do not undertake a journey to visit any mosque but three: Al-Masjid Al-Haram, Al-Masjid An-Nabawi, and Al-Masjid Al-Aqsa” (Sahih al-Bukhari 1189).", dimmed: true)
                }

                Section(header: Text("REWARDS OF PRAYING IN MASJID AL-AQSA")) {
                    Text("Prayer in the three sacred mosques carries immense reward. What is established is the authentic narration in which the Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“A prayer in this mosque of mine is better than a thousand prayers elsewhere, except for Al-Masjid Al-Haram” (Sahih al-Bukhari 1190).", dimmed: true)

                    Text("A report giving a specific figure for Masjid Al-Aqsa (fifty thousand prayers) is narrated in Sunan Ibn Majah 1413, but its chain is weak (da'if) - and its figure for Masjid An-Nabawi contradicts the authentic hadith above - so it is not relied upon.").font(.body)
                }

                Section(header: Text("STRUCTURE AND FEATURES")) {
                    Text("Masjid Al-Aqsa is part of a larger compound that includes the **Dome of the Rock (قُبَّة ٱلصَّخرَة)**, the oldest Islamic architectural monument. The entire compound is considered sacred by Muslims, and the name Masjid Al-Aqsa often refers to the entire Noble Sanctuary.")
                        .font(.body)

                    Text("The mosque’s architecture and location reflect centuries of Islamic devotion and heritage.")
                        .font(.body)
                }

                Section(header: Text("MASJID AL-AQSA")) {
                    Image("Al-Adhan")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(24)
                        #if os(iOS)
                        .focusableImage("Al-Adhan", title: "Masjid al-Aqsa")
                        #endif
                        #if os(iOS)
                        .contextMenu {
                            Text("Image Actions")
                                .foregroundStyle(.secondary)

                            Button {
                                settings.hapticFeedback()
                                UIPasteboard.general.image = UIImage(named: "Al Aqsa")
                            } label: {
                                Text("Copy Image")
                                Image(systemName: "photo")
                            }
                        }
                        #endif
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Blessed by Allah and honored by the prophets, Masjid al-Aqsa remains one of the three mosques to which travel for worship is specially encouraged.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Masjid Al-Aqsa")
    }
}

import SwiftUI

/// Quran sciences and the Islamic calendar - knowledge sections shown under "Pillars & Beliefs".
struct BeliefsQuranView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        Section(header: Text("QURAN & TAFSIR")) {
            NavigationLink(destination: LazyDestination { CompileView() }) {
                Text("Compilation of the Quran")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { TafsirView() }) {
                Text("Tafsir (Exegesis)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { TajweedView() }) {
                Text("Tajweed")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { MuqattaatPillarView() }) {
                Text("Muqatta'at Letters")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { JuzView() }) {
                Text("The 30 Juz (Parts)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { AhrufView() }) {
                Text("The 7 Ahruf (Modes)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { QiraatView() }) {
                Text("The 10 Qiraat (Recitations)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
        }

        Section(header: Text("THE ISLAMIC CALENDAR")) {
            NavigationLink(destination: LazyDestination { HijriCalendarView() }) {
                Text("Hijri Calendar")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
        }
    }
}

/// The history & creed section, shown under "Pillars & Beliefs".
struct BeliefsHistoricalView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        Section(header: Text("HISTORICAL & BIOGRAPHICAL")) {
            NavigationLink(destination: LazyDestination { SeerahView() }) {
                Text("The Seerah (Biography)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { FarewellView() }) {
                Text("The Farewell (Final) Sermon")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { AhlulBaytView() }) {
                Text("The Ahlul Bayt (People of the House)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { WivesView() }) {
                Text("The Wives of the Prophet")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { SahabahView() }) {
                Text("The Sahabah (Companions)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { CaliphatesView() }) {
                Text("The Caliphates")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { MadhabView() }) {
                Text("The 4 Madhaahib (Schools of Thought)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { AhlusSunnahView() }) {
                Text("Ahl As-Sunnah Wal Jama'ah")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { FiqhAqeedahManhajView() }) {
                Text("Fiqh, Aqeedah, and Manhaj")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
        }
    }
}

struct WudhuView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Wudhu is the minor ablution. It is a condition for the validity of the prayer, and it wipes away sins as it is performed.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("**Wudhu (وُضُوء)**, from the root **w-d-a (و ض أ)**, meaning cleanliness and radiance, is the purification performed before **Salah (صَلَاة)**, before touching the Quran, and before **Tawaf (طَوَاف)** around the Kaaba.")
                        .font(.body)
                    Text("Without it, the prayer is not accepted. The Prophet (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Allah does not accept the prayer of any of you if he breaks his wudhu until he performs wudhu again” (Sahih al-Bukhari 135, Sahih Muslim 225).", dimmed: true)
                }

                Section(header: Text("THE COMMAND IN THE QURAN")) {
                    Text("Allah (Glorified and Exalted be He) says:")
                        .font(.body)
                    ScriptureQuote(text: "“O you who have believed, when you rise to [perform] prayer, wash your faces and your forearms to the elbows and wipe over your heads and [wash] your feet to the ankles” (Quran 5:6).")
                    Text("This one verse names the four obligatory parts: the face, the arms to the elbows, wiping the head, and the feet to the ankles. Everything else in the description below is Sunnah, following the way the Prophet (peace and blessings be upon him) actually did it.")
                        .font(.body)
                }

                Section(header: Text("HOW TO MAKE WUDHU")) {
                    Text("1. Make the **niyyah (نِيَّة)**, the intention, in the heart. It is not said aloud.")
                        .font(.body)
                    Text("2. Say **“Bismillah“ (بِسمِ اللهِ)**.")
                        .font(.body)
                    Text("3. Wash both **hands** up to the wrists, three times.")
                        .font(.body)
                    Text("4. **Rinse the mouth** and **sniff water into the nose** and blow it out, three times. Use the right hand to take the water and the left to blow the nose.")
                        .font(.body)
                    Text("5. Wash the **face** three times, from the hairline to under the chin and from ear to ear. If you have a thick beard, run wet fingers through it.")
                        .font(.body)
                    Text("6. Wash the **right arm** to and including the elbow, three times. Then the **left arm**, three times.")
                        .font(.body)
                    Text("7. **Wipe the head once**, not three times: pass wet hands from the front of the head to the back and return them to the front. Then, with the same water, **wipe the ears**, index fingers inside and thumbs behind.")
                        .font(.body)
                    Text("8. Wash the **right foot** to and including the ankle, three times, running the fingers between the toes. Then the **left foot**, three times.")
                        .font(.body)
                    Text("9. Then say: **“Ash-hadu an la ilaha illa Allah, wahdahu la sharika lah, wa ash-hadu anna Muhammadan abduhu wa rasuluh.“**")
                        .font(.body)

                    Text("The Prophet (peace and blessings be upon him) said about that closing testimony:")
                        .font(.body)
                    ScriptureQuote(text: "“There is no one among you who performs wudhu and does it well, then says: I bear witness that there is no god but Allah alone with no partner, and that Muhammad is His slave and Messenger, but the eight gates of Paradise will be opened for him, and he may enter through whichever of them he wishes” (Sahih Muslim 234).", dimmed: true)

                    Text("Do not be wasteful with water, even at a flowing river. That was the Prophet's instruction (Sunan Ibn Majah 425).")
                        .font(.body)
                }

                Section(header: Text("WHAT BREAKS WUDHU")) {
                    Text("• Anything that exits from the front or back passage: urine, stool, or wind.")
                        .font(.body)
                    Text("• Deep sleep, in which a person loses awareness.")
                        .font(.body)
                    Text("• Loss of consciousness, whether from fainting, intoxication, or illness.")
                        .font(.body)
                    Text("• Touching the private parts directly with the hand, without a barrier.")
                        .font(.body)
                    Text("• Eating camel meat.")
                        .font(.body)
                    Text("Doubt alone does not break it. If you are certain you had wudhu and merely suspect you lost it, you still have it.")
                        .font(.body)
                }

                Section(header: Text("THE REWARD")) {
                    Text("The Prophet Muhammad (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“When a Muslim or a believer washes his face (in wudhu), every sin he contemplated with his eyes will be washed away from his face along with the water, or with the last drop of water; when he washes his hands, every sin they wrought will be effaced from his hands with the water, or with the last drop of water; and when he washes his feet, every sin towards which his feet have walked will be washed away with the water or with the last drop of water, with the result that he comes out pure from all sins” (Sahih Muslim 244).", dimmed: true)

                    Text("He also said:")
                        .font(.body)
                    ScriptureQuote(text: "“Shall I not tell you of that by which Allah erases sins and raises ranks? Performing wudhu properly even when it is difficult, taking many steps to the mosque, and waiting for the next prayer after the previous one” (Sahih Muslim 251).", dimmed: true)

                    Text("And he said that his nation will be called on the Day of Resurrection with radiant faces, hands, and feet, from the traces of wudhu (Sahih al-Bukhari 136).")
                        .font(.body)

                    Text("It is also from the Sunnah to make wudhu before sleeping.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Purity is a condition of prayer and a means of erasing sins. Performed with intention and in the way the Prophet performed it, wudhu is an act of worship in itself.")
                        .font(.body)

                    NavigationLink(destination: LazyDestination { GhuslView() }) {
                        Label("Next: How to Make Ghusl", systemImage: "drop.fill")
                            .font(.body)
                            .foregroundColor(settings.accentColor.color)
                    }
                }

                GuideSourcesSection(sources: [
                    (title: "How to Perform Wudhu", subtitle: "Step-by-step guide, IslamQA", url: "https://islamqa.info/en/categories/topics/13/wudoo"),
                ])
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("How to Make Wudhu")
    }
}

struct GhuslView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Ghusl is the full-body wash that lifts major ritual impurity. Until it is performed, the prayer cannot be prayed.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("**Ghusl (غُسل)**, from the root **gh-s-l (غ س ل)**, to wash, is a complete washing of the body with the intention of lifting major ritual impurity, **Janabah (جَنَابَة)**.")
                        .font(.body)
                    Text("Where wudhu washes specific limbs, ghusl reaches the whole body. Ghusl also removes the need for a separate wudhu, so long as nothing has broken it during the wash.")
                        .font(.body)
                }

                Section(header: Text("WHEN GHUSL IS OBLIGATORY")) {
                    Text("• After marital relations, whether or not there is emission.")
                        .font(.body)
                    Text("• After the emission of maniy (sexual fluid) with desire, whether awake or from a wet dream.")
                        .font(.body)
                    Text("• At the end of **menstruation (حَيض)**.")
                        .font(.body)
                    Text("• At the end of **postpartum bleeding (نِفَاس)**.")
                        .font(.body)
                    Text("• Upon accepting Islam.")
                        .font(.body)
                    Text("• Upon death, the deceased is washed by the living.")
                        .font(.body)
                }

                Section(header: Text("WHEN GHUSL IS RECOMMENDED")) {
                    Text("• Before the **Jumuah (جُمُعَة)** prayer.")
                        .font(.body)
                    Text("• Before the two **Eid** prayers.")
                        .font(.body)
                    Text("• Before entering **Ihram (إِحرَام)** for Hajj or Umrah.")
                        .font(.body)
                    Text("• After washing a deceased person.")
                        .font(.body)
                }

                Section(header: Text("THE COMMAND IN THE QURAN")) {
                    Text("Allah (Glorified and Exalted be He) says:")
                        .font(.body)
                    ScriptureQuote(text: "“And if you are in a state of janabah, then purify yourselves” (Quran 5:6).")
                    Text("And He says:")
                        .font(.body)
                    ScriptureQuote(text: "“And do not approach prayer while you are intoxicated until you know what you are saying, or in a state of janabah, except those passing through [a place of prayer], until you have washed [your whole body]” (Quran 4:43).")
                }

                Section(header: Text("HOW TO MAKE GHUSL")) {
                    Text("This is the way described by Aisha and Maymunah (may Allah be pleased with them), who saw the Prophet (peace and blessings be upon him) perform it (Sahih al-Bukhari 248, 249, 257).")
                        .font(.body)

                    Text("1. Make the **niyyah (نِيَّة)** in the heart to lift the state of janabah.")
                        .font(.body)
                    Text("2. Say **“Bismillah“**, and wash both **hands** three times.")
                        .font(.body)
                    Text("3. Wash the **private parts** and any impurity from the body with the left hand, then wash the hand.")
                        .font(.body)
                    Text("4. Perform a **complete wudhu**, as you would for prayer.")
                        .font(.body)
                    Text("5. Pour water over the **head three times**, working the fingers through the hair so the water reaches the roots of every hair.")
                        .font(.body)
                    Text("6. Pour water over the **right side** of the body, then the **left side**, ensuring the water reaches every part: under the arms, inside the navel, behind the ears, between the toes.")
                        .font(.body)
                    Text("7. Move from your place and **wash the feet**, if you did not wash them during the wudhu.")
                        .font(.body)

                    Text("**The obligation is only two things:** the intention, and that water reaches every part of the body including the mouth and nose. The order and the repetition above are Sunnah. If a person simply immerses fully in water with the intention, the ghusl is valid.")
                        .font(.body)

                    Text("Women do **not** need to undo braided hair for the ghusl of janabah, so long as the water reaches the roots. Umm Salamah (may Allah be pleased with her) asked about this, and the Prophet (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“No, it is enough for you to pour three handfuls of water over your head, then pour water over yourself, and you will be purified” (Sahih Muslim 330).", dimmed: true)
                }

                Section(header: Text("IF THERE IS NO WATER: TAYAMMUM")) {
                    Text("If water cannot be found, or using it would cause harm or illness, then **Tayammum (تَيَمُّم)**, dry purification, takes its place for both wudhu and ghusl. Allah says in the same verse:")
                        .font(.body)
                    ScriptureQuote(text: "“And if you do not find water, then seek clean earth and wipe over your faces and your hands [with it]” (Quran 5:6).")
                    Text("Strike clean earth once with both palms, then wipe the face, then wipe the hands. That is all.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Ghusl lifts major impurity and returns a person to the state in which they may pray. Its obligation is simple: intend it, and let the water reach all of you.")
                        .font(.body)
                }

                GuideSourcesSection(sources: [
                    (title: "How to Perform Ghusl", subtitle: "Step-by-step guide, IslamQA", url: "https://islamqa.info/en/answers/83057"),
                ])
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("How to Make Ghusl")
    }
}

struct JumuahView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Jumuah is the Friday congregational prayer that replaces Dhuhr - a sermon followed by two rak'ah, obligatory on Muslim men who are able.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("Jumuah (جُمُعَة) comes from the root **j-m-a (ج م ع)**, meaning to gather or congregate. It refers to the Friday congregational prayer that replaces Dhuhr.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) says in the Quran:")
                        .font(.body)

                    ScriptureQuote(text: "“O you who have believed, when [the adhan] is called for the prayer on the day of Jumu’ah [Friday], then proceed to the remembrance of Allah and leave trade. That is better for you, if you only knew” (Quran 62:9).")

                    Text("Jumuah prayer consists of a sermon (**Khutbah - خُطبَة**) followed by a two-rak’ah Salah led by the Imam. It is obligatory for Muslim men who can attend, though it is not obligatory for women.")
                        .font(.body)

                    Text("If Jumuah is missed at the mosque, one performs the full Dhuhr prayer (4 rak’ahs).")
                        .font(.body)
                }

                Section(header: Text("IMPORTANCE")) {
                    Text("The Prophet Muhammad (peace and blessings be upon him) said:")
                        .font(.body)

                    ScriptureQuote(text: "“The best day on which the sun has risen is Friday; on it Adam was created, on it he was admitted to Paradise, and on it he was expelled therefrom” (Sahih Muslim 854).", dimmed: true)

                    Text("Friday is considered the best day of the week in Islam. It unites the community, strengthens social bonds, and serves as a weekly reminder of our responsibilities toward Allah (Glorified and Exalted be He) and humanity.")
                        .font(.body)
                }

                Section(header: Text("RECOMMENDED PRACTICES")) {
                    Text("Muslims are encouraged to engage in specific acts of worship on Jumuah:")
                        .font(.body)

                    Text("1. **Reciting Surah Al-Kahf (سُورَة ٱلكَهف):** The Prophet Muhammad (peace and blessings be upon him) said:")
                        .font(.body)

                    Text("“Whoever reads Surah Al-Kahf on Friday will have a light between this Friday and the next” (Mishkat al-Masabih 2175).")
                        .font(.body)
                        .foregroundColor(settings.accentColor.color)

                    Text("2. **Sending Salawat on the Prophet (peace and blessings be upon him):**")
                        .font(.body)

                    ScriptureQuote(text: "“Increase your supplications for me on the day and night of Friday. Whoever blesses me once, Allah will bless him ten times” (al-Sunan al-Kubra lil-Bayhaqi 5994).", dimmed: true)

                    Text("3. **Making Dua (Supplication)**: There is a special hour on Friday during which all supplications are accepted. The Prophet Muhammad (peace and blessings be upon him) said:")
                        .font(.body)

                    ScriptureQuote(text: "“Friday is twelve hours in which there is no Muslim slave who asks Allah for something but He will give it to him, so seek it in the last hour after Asr” (Sunan an-Nasa'i 1389).", dimmed: true)
                }

                Section(header: Text("ETIQUETTE")) {
                    Text("Observing proper etiquette during Jumuah is essential:")
                        .font(.body)

                    Text("1. Arrive early to the mosque and sit attentively during the Khutbah.")
                        .font(.body)

                    Text("2. Wear clean and modest clothing as Friday is a day of significance.")
                        .font(.body)

                    Text("3. Avoid distractions, such as using phones, during the sermon.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Friday is the best day of the week: a weekly gathering for remembrance, with special reward in reciting Surah al-Kahf and sending salawat upon the Prophet.")
                        .font(.body)
                }

                GuideSourcesSection(sources: [
                    (title: "How to Pray Jumuah", subtitle: "The Friday prayer and its khutbah, IslamQA", url: "https://islamqa.info/en/categories/topics/85/jumuah-prayer"),
                ])
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Jumuah")
    }
}

struct AdhanOtherView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the Adhan is the melodious call announcing each of the five daily prayers, first given in Madinah and famously called by Bilal ibn Rabah.")
                        .font(.body)
                }

                Section(header: Text("HISTORY")) {
                    Text("The Adhan (أَذَان) is the Islamic call to prayer, from the root **a-dh-n (أ ذ ن)** meaning to announce or proclaim.")
                        .font(.body)

                    Text("It is recited in Arabic to announce the time for each of the five daily prayers.")
                        .font(.body)

                    Text("The Adhan originated during the time of Prophet Muhammad (peace and blessings be upon him) in Madinah.")
                        .font(.body)

                    Text("The method of calling to prayer was revealed through the dream of Abdullah ibn Zaid (may Allah be pleased with him), and the Prophet (peace and blessings be upon him) chose Bilal ibn Rabah (may Allah be pleased with him) to deliver it because of his melodious and powerful voice.")
                        .font(.body)
                }

                Section(header: Text("WORDS OF THE ADHAN")) {
                    Text("""
                    اللَّهُ أَكبَرُ، اللَّهُ أَكبَرُ
                    اللَّهُ أَكبَرُ، اللَّهُ أَكبَرُ

                    أَشهَدُ أَن لَا إِلَٰهَ إِلَّا اللَّهُ
                    أَشهَدُ أَن لَا إِلَٰهَ إِلَّا اللَّهُ

                    أَشهَدُ أَنَّ مُحَمَّدًا رَسُولُ اللَّهِ
                    أَشهَدُ أَنَّ مُحَمَّدًا رَسُولُ اللَّهِ

                    حَيَّ عَلَى الصَّلَاةِ، حَيَّ عَلَى الصَّلَاةِ
                    حَيَّ عَلَى الفَلَاحِ، حَيَّ عَلَى الفَلَاحِ

                    اللَّهُ أَكبَرُ، اللَّهُ أَكبَرُ
                    لَا إِلَٰهَ إِلَّا اللَّهُ
                    """)
                    .font(.body)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(settings.accentColor.color)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                    Text("""
                    Allahu Akbar, Allahu Akbar
                    Allahu Akbar, Allahu Akbar

                    Ashhadu an la ilaha illa Allah
                    Ashhadu an la ilaha illa Allah

                    Ashhadu anna Muhammadan rasool Allah
                    Ashhadu anna Muhammadan rasool Allah

                    Hayya 'ala as-salah, Hayya 'ala as-salah
                    Hayya 'ala al-falah, Hayya 'ala al-falah

                    Allahu Akbar, Allahu Akbar
                    La ilaha illa Allah
                    """)
                    .font(.body)

                    Text("""
                    Allah is the greatest, Allah is the greatest
                    Allah is the greatest, Allah is the greatest

                    I bear witness that there is no deity but Allah
                    I bear witness that there is no deity but Allah

                    I bear witness that Muhammad is the Messenger of Allah
                    I bear witness that Muhammad is the Messenger of Allah

                    Come to prayer, Come to prayer
                    Come to success, Come to success

                    Allah is the greatest, Allah is the greatest
                    There is no deity but Allah
                    """)
                    .font(.body)
                }

                Section(header: Text("ONLY FOR FAJR")) {
                    Text("**ONLY FOR FAJR:** the following line is added, and it is said in no other Adhan. It comes after “Hayya ala al-falah“ and before the closing takbir.")
                        .font(.body)

                    Text("**ONLY FOR FAJR:**")
                        .font(.body)
                        .foregroundColor(settings.accentColor.color)

                    Text("الصَّلَاةُ خَيرٌ مِنَ النَّومِ")
                        .font(.body)
                        .foregroundColor(settings.accentColor.color)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    Text("As-salatu khayrun mina-nawm\n(Prayer is better than sleep)")
                        .font(.body)

                    Text("This line is said twice, and only in the Adhan for Fajr. It is never said in the Adhan for Dhuhr, Asr, Maghrib, or Isha, and it is never said in the Iqamah.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Its words proclaim the greatness and oneness of Allah and the messengership of Muhammad, calling the believers to prayer and to success.")
                        .font(.body)
                }

                Section(header: Text("THE VIRTUE OF THE ADHAN")) {
                    Text("Allah (Glorified and Exalted be He) says:")
                        .font(.body)
                    ScriptureQuote(text: "“O you who have believed, when [the adhan] is called for the prayer on the day of Jumuah, then proceed to the remembrance of Allah and leave trade” (Quran 62:9).")
                    Text("The Prophet (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“If the people knew what there is in the call to prayer and the first row, and they could find no other way than to draw lots, they would draw lots for it” (Sahih al-Bukhari 615).", dimmed: true)
                    ScriptureQuote(text: "“When the call to prayer is made, Satan takes to his heels and passes wind with noise so as not to hear the call” (Sahih al-Bukhari 608).", dimmed: true)
                    Text("Answer the muadhin. He said: “When you hear the muadhin, say the like of what he says” (Sahih Muslim 383). Except at “Hayya ala as-salah“ and “Hayya ala al-falah,“ where you say “La hawla wa la quwwata illa billah“ (Sahih Muslim 385).")
                        .font(.body)
                    Text("Then send blessings on the Prophet (peace and blessings be upon him), and say:")
                        .font(.body)
                    ScriptureQuote(text: "“Allahumma Rabba hadhihi ad-dawati at-tammah, was-salatil-qa'imah, ati Muhammadan al-wasilata wal-fadilah, wab'ath-hu maqaman mahmudan alladhi wa'adtah“ - whoever says this after the adhan, my intercession will be permitted for him on the Day of Resurrection (Sahih al-Bukhari 614).", dimmed: true)
                }

                GuideSourcesSection(sources: [
                    (title: "How to Give the Adhan and Iqamah", subtitle: "The wording and its rulings, IslamQA", url: "https://islamqa.info/en/categories/topics/70/adhan-and-iqamah"),
                ])
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Adhan")
    }
}

struct IqamahView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the Iqamah is the second, shorter call given just before the congregation stands, signaling that the prayer is about to begin.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("The Iqamah (إِقَامَة) - from the root **q-w-m (ق و م)**, to stand or establish - is the second call to prayer, given right before the congregational Salah begins.")
                        .font(.body)

                    Text("It is generally shorter than the Adhan and serves as a prompt for the congregation to stand and line up for prayer.")
                        .font(.body)

                    Text("Often, the same **Mu'adhin (مُؤَذِّن)** (caller) who delivered the Adhan will also deliver the Iqamah, but it can be done by someone else.")
                        .font(.body)
                }

                Section(header: Text("WORDS OF THE IQAMAH")) {
                    Text("""
                    اللَّهُ أَكبَرُ، اللَّهُ أَكبَرُ

                    أَشهَدُ أَن لَا إِلَٰهَ إِلَّا اللَّهُ

                    أَشهَدُ أَنَّ مُحَمَّدًا رَسُولُ اللَّهِ

                    حَيَّ عَلَى الصَّلَاةِ، حَيَّ عَلَى الفَلَاحِ

                    قَد قَامَتِ الصَّلَاةُ
                    قَد قَامَتِ الصَّلَاةُ

                    اللَّهُ أَكبَرُ، اللَّهُ أَكبَرُ

                    لَا إِلَٰهَ إِلَّا اللَّهُ
                    """)
                    .font(.body)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(settings.accentColor.color)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                    Text("""
                    Allahu Akbar, Allahu Akbar

                    Ashhadu an la ilaha illa Allah

                    Ashhadu anna Muhammadan rasool Allah

                    Hayya 'ala as-salah, Hayya 'ala al-falah

                    Qad qamatis-Salah
                    Qad qamatis-Salah

                    Allahu Akbar, Allahu Akbar

                    La ilaha illa Allah
                    """)
                    .font(.body)

                    Text("""
                    Allah is the greatest, Allah is the greatest

                    I bear witness that there is no deity but Allah

                    I bear witness that Muhammad is the Messenger of Allah

                    Come to prayer, Come to success

                    Prayer has begun
                    Prayer has begun

                    Allah is the greatest, Allah is the greatest

                    There is no deity but Allah
                    """)
                    .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Where the Adhan calls the community to gather, the Iqamah announces that the prayer has been established and the rows are to be formed.")
                        .font(.body)
                }

                Section(header: Text("AFTER THE IQAMAH")) {
                    Text("The Iqamah is said in single phrases, unlike the Adhan, which is said in pairs. Anas (may Allah be pleased with him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Bilal was ordered to say the words of the adhan twice and the words of the iqamah once” (Sahih al-Bukhari 605, Sahih Muslim 378).", dimmed: true)
                    Text("Once the Iqamah is called, no other prayer is begun. The Prophet (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“When the iqamah for the prayer has been called, then there is no prayer except the obligatory one” (Sahih Muslim 710).", dimmed: true)
                    Text("And straighten the rows before the imam begins:")
                        .font(.body)
                    ScriptureQuote(text: "“Straighten your rows, for straightening the rows is part of the perfection of the prayer” (Sahih al-Bukhari 723, Sahih Muslim 433).", dimmed: true)
                    Text("Walk to the prayer calmly. He said: “When the iqamah is called, do not come to it running. Come to it walking, with tranquillity. Whatever you catch, pray, and whatever you miss, complete it” (Sahih al-Bukhari 636, Sahih Muslim 602).")
                        .font(.body)
                }

                GuideSourcesSection(sources: [
                    (title: "How to Give the Iqamah", subtitle: "Its wording and its rulings, IslamQA", url: "https://islamqa.info/en/categories/topics/70/adhan-and-iqamah"),
                ])
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Iqamah")
    }
}

struct TakbiratView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the Eid prayer is two rak'ah with extra takbirs, prayed in congregation after sunrise with no Adhan and no Iqamah, followed by the khutbah.")
                        .font(.body)
                }

                Section(header: Text("BEFORE YOU GO")) {
                    Text("1. Perform **ghusl (غُسل)**, wear your best clothes, and apply perfume (for men).")
                        .font(.body)
                    Text("2. For **Eid al-Fitr**, eat an odd number of dates before leaving. For **Eid al-Adha**, do not eat until after the prayer, so that the first thing you eat is from the sacrifice.")
                        .font(.body)
                    Text("3. Pay **Zakat al-Fitr** before the prayer (Eid al-Fitr only). If it is paid after the prayer, it counts as ordinary charity, not as Zakat al-Fitr.")
                        .font(.body)
                    Text("4. Say the Takbir on the way, out loud (see below).")
                        .font(.body)
                    Text("5. Go out to the **musalla (مُصَلَّى)**, the open prayer ground, which is the Sunnah, and take the women and children with you. Go by one route and return by another, as the Prophet (peace and blessings be upon him) did (Sahih al-Bukhari 986).")
                        .font(.body)
                }

                Section(header: Text("THE TIME OF THE PRAYER")) {
                    Text("The Eid prayer begins after the sun has fully risen, roughly 15 to 20 minutes after sunrise, and its time lasts until just before the sun reaches its zenith (before Dhuhr).")
                        .font(.body)
                    Text("**Eid al-Adha** is prayed early, so people can go and sacrifice. **Eid al-Fitr** is prayed a little later, so people have time to give Zakat al-Fitr.")
                        .font(.body)
                }

                Section(header: Text("HOW TO PRAY EID")) {
                    Text("There is **no Adhan and no Iqamah** for the Eid prayer, and no call of any kind. It is simply begun.")
                        .font(.body)

                    Text("It is **two rak'ah**, prayed in congregation behind the imam, and the recitation is out loud.")
                        .font(.body)

                    Text("**First rak'ah:**")
                        .font(.body)
                    Text("1. Make the intention in the heart, then the opening takbir, **Takbirat al-Ihram (تَكبِيرَة الإِحرَام)**, raising the hands.")
                        .font(.body)
                    Text("2. Say the opening supplication (**du'a al-istiftah**).")
                        .font(.body)
                    Text("3. Say **seven takbirs** in total in this rak'ah before the recitation, raising the hands with each. (Scholars differ over whether the opening takbir is counted as one of the seven; both are practised and the prayer is valid either way. Do not argue over it.)")
                        .font(.body)
                    Text("4. Then say the ta'awwudh and recite **al-Fatihah**, followed by a surah. From the Sunnah: **Surah al-A'la (87)** in the first rak'ah and **al-Ghashiyah (88)** in the second, or **Qaf (50)** and **al-Qamar (54)**.")
                        .font(.body)
                    Text("5. Then complete the rak'ah as normal: ruku', standing, and two prostrations.")
                        .font(.body)

                    Text("**Second rak'ah:**")
                        .font(.body)
                    Text("6. Stand, and before reciting, say **five takbirs**, raising the hands with each. These are apart from the takbir you said when standing up from prostration.")
                        .font(.body)
                    Text("7. Recite al-Fatihah and a surah, then complete the rak'ah, sit for the tashahhud, and give the salaam.")
                        .font(.body)

                    Text("There is **no nafl prayer** before or after the Eid prayer at the musalla.")
                        .font(.body)

                    Text("The Prophet (peace and blessings be upon him) is reported to have said:")
                        .font(.body)
                    ScriptureQuote(text: "“The takbir in Fitr and Adha is seven in the first rak'ah and five in the second, apart from the two takbirs of ruku'” (Sunan Abi Dawud 1151).", dimmed: true)

                    Text("If you miss a takbir, or the imam has already begun, join him where he is and do not try to make up the extra takbirs. They are a Sunnah, not a pillar, and forgetting them does not invalidate the prayer or require the prostration of forgetfulness.")
                        .font(.body)
                }

                Section(header: Text("AFTER THE PRAYER: THE KHUTBAH")) {
                    Text("The khutbah comes **after** the Eid prayer, unlike Jumuah, where it comes before.")
                        .font(.body)
                    Text("Staying for it is strongly recommended, though it is not obligatory, and one who leaves has not sinned.")
                        .font(.body)
                    Text("If you missed the congregation entirely, you may pray two rak'ah on your own.")
                        .font(.body)
                    Text("Greet one another with **“Taqabbal Allahu minna wa minkum“ (تَقَبَّلَ اللهُ مِنَّا وَمِنكُم)**, “May Allah accept it from us and from you.“ This was the greeting of the Companions.")
                        .font(.body)
                }

                Section(header: Text("EID OCCASIONS")) {
                    Text("In Islam, there are two major annual celebrations known as Eid:")
                        .font(.body)

                    Text("1. **Eid al-Fitr (عيد الفطر):** Celebrated at the end of Ramadan (the month of fasting). It is a time of joy, gratitude to Allah (Glorified and Exalted be He), and giving to the needy (Zakat al-Fitr).")
                        .font(.body)

                    Text("2. **Eid al-Adha (عيد الأضحى):** Celebrated on the 10th day of Dhu al-Hijjah. It commemorates the willingness of Prophet Ibrahim (peace be upon him) to sacrifice his son Isma'il (peace be upon him). Muslims who are able to do so perform the sacrifice (Qurbani) and distribute the meat to the poor. This Eid coincides with Hajj, the annual pilgrimage to Makkah.")
                        .font(.body)
                }

                Section(header: Text("TAKBIRAT AL-EID")) {
                    Text("The Takbirat al-Eid is a special proclamation of Allah’s greatness, recited during the days of Eid.")
                        .font(.body)

                    Text("For Eid al-Fitr, it begins after the new moon confirming the end of Ramadan and continues until the Eid prayer. For Eid al-Adha, it begins after Arafah Day (9th of Dhu al-Hijjah) and continues until the Eid prayer.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) says in the Quran:")
                        .font(.body)

                    ScriptureQuote(text: "“And [He wants] for you to complete the period and to glorify Allah for that [to] which He has guided you; and perhaps you will be grateful” (Quran 2:185).")
                }

                Section(header: Text("SHORT TAKBIRAT")) {
                    Text("This is the short version of the Takbir:")
                        .font(.body)

                    Text("الله أكبر الله أكبر لا إله إلا الله، والله أكبر الله أكبر ولله الحمد")
                        .font(.body)
                        .foregroundColor(settings.accentColor.color)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    Text("Allahu Akbar, Allahu Akbar, La Ilaha Illa Allah, Allahu Akbar, Allahu Akbar, wa lillahil hamd")
                        .font(.body)

                    Text("Allah is the Greatest, Allah is the Greatest. There is no deity but Allah. Allah is the Greatest, Allah is the Greatest, and to Allah belongs all praise.")
                        .font(.body)
                }

                Section(header: Text("LONGER TAKBIRAT")) {
                    Text("""
                    اللَّهُ أَكبَرُ، اللَّهُ أَكبَرُ، اللَّهُ أَكبَرُ، لَا إِلَهَ إِلَّا اللَّهُ

                    اللَّهُ أَكبَرُ، اللَّهُ أَكبَرُ، وَلِلَّهِ الحَمدُ

                    اللَّهُ أَكبَرُ كَبِيرًا، وَالحَمدُ لِلَّهِ كَثِيرًا، وَسُبحَانَ اللَّهِ بُكرَةً وَأَصِيلًا

                    لَا إِلَهَ إِلَّا اللَّهُ وَحدَهُ، صَدَقَ وَعدَهُ، وَنَصَرَ عَبدَهُ، وَأَعَزَّ جُندَهُ، وَهَزَمَ الأَحزَابَ وَحدَهُ

                    لَا إِلَهَ إِلَّا اللَّهُ، وَلَا نَعبُدُ إِلَّا إِيَّاهُ، مُخلِصِينَ لَهُ الدِّينَ وَلَو كَرِهَ الكَافِرُونَ

                    اللَّهُمَّ صَلِّ عَلَى سَيِّدِنَا مُحَمَّدٍ، وَعَلَى آلِ سَيِّدِنَا مُحَمَّدٍ، وَعَلَى أَصحَابِ سَيِّدِنَا مُحَمَّدٍ، وَعَلَى أَنصَارِ سَيِّدِنَا مُحَمَّدٍ، وَعَلَى أَزوَاجِ سَيِّدِنَا مُحَمَّدٍ، وَعَلَى ذُرِّيَّةِ سَيِّدِنَا مُحَمَّدٍ، وَسَلِّم تَسلِيمًا كَثِيرًا
                    """)
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                    Text("""
                    Allahu Akbar, Allahu Akbar, Allahu Akbar, La ilaha illa Allah

                    Allahu Akbar, Allahu Akbar, wa Lillahil Hamd

                    Allahu Akbar Kabira, wal Hamdu Lillahi Kathira, wa Subhan Allahi bukratan wa asila

                    La ilaha illa Allahu Wahdah, sadaqa wa’dah, wa nasara abdah, wa a’azza jundahu wa hazama al-Ahzaba wahdah

                    La ilaha illa Allah, wa la na’budu illa iyyah, mukhliseena lahud-deen, walaw karihal kafirun

                    Allahumma salli ‘ala Sayyidina Muhammad, wa ‘ala ali Sayyidina Muhammad, wa ‘ala ashabi Sayyidina Muhammad, wa ‘ala ansari Sayyidina Muhammad, wa ‘ala azwaji Sayyidina Muhammad, wa ‘ala dhurriyyati Sayyidina Muhammad, wa sallim tasliman kathira
                    """)
                    .font(.body)

                    Text("""
                    “Allah is the Greatest, Allah is the Greatest, Allah is the Greatest; There is no deity but Allah.
                    Allah is the Greatest, Allah is the Greatest, and to Allah belongs all praise.

                    Allah is the Greatest in greatness; much praise be to Allah; and Glory be to Allah in the morning and evening.
                    There is no deity but Allah alone. He fulfilled His promise, granted victory to His servant, and honored His army, and He alone defeated the confederates.

                    There is no deity but Allah; we do not worship anyone but Him, being sincere in faith and devotion to Him, even if the disbelievers dislike it.
                    O Allah, send Your blessings on our master Muhammad, and on the family of our master Muhammad, on the companions of our master Muhammad, on the supporters of our master Muhammad, on the wives of our master Muhammad, and on the descendants of our master Muhammad, and bestow upon them abundant peace.”
                    """)
                    .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("By glorifying Allah on the days of Eid, Muslims complete their worship with gratitude - after Ramadan for Eid al-Fitr, and around the days of Hajj for Eid al-Adha.")
                        .font(.body)
                }

                GuideSourcesSection(sources: [
                    (title: "How to Pray Eid", subtitle: "The Eid prayer and its takbirs, IslamQA", url: "https://islamqa.info/en/answers/48983"),
                    (title: "The Eid Takbir", subtitle: "Its wording and when it is said, IslamQA", url: "https://islamqa.info/en/answers/36491"),
                ])
            }
            .themedListRowBackground()
        }
        .navigationTitle("How to Pray Eid")
        .applyConditionalListStyle()
    }
}

struct HijriCalendarView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the Hijri calendar is the Islamic lunar calendar of twelve months, dated from the Prophet's migration (Hijrah) to Madinah in 622 CE.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("The Hijri calendar, also known as the Islamic or Lunar Hijri calendar, consists of 12 lunar months in a year of 354 or 355 days.")
                        .font(.body)

                    Text("It is used to determine key Islamic dates such as Ramadan, Hajj, and the two Eid festivals. The reference point (epoch) of the calendar is the Hijrah - the migration of Prophet Muhammad (peace and blessings be upon him) from Makkah to Madinah in 622 CE.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) says in the Quran:")
                        .font(.body)

                    ScriptureQuote(text: "“Indeed, the number of months with Allah is twelve [lunar] months in the register of Allah [from] the day He created the heavens and the earth; of these, four are sacred” (Quran 9:36).")
                }

                Section(header: Text("DETAILS")) {
                    Text("""
                         Each Hijri month begins with the sighting of the new moon. The 12 months are as follows:
                         1. **Muharram (مُحَرَّم)** – One of the sacred months
                         2. **Safar (صَفَر)** 
                         3. **Rabi al-Awwal (رَبِيع ٱلأَوَّل)**
                         4. **Rabi al-Thani (رَبِيع ٱلثَّانِي)** 
                         5. **Jumada al-Awwal (جُمَادَىٰ ٱلأَوَّل)** 
                         6. **Jumada al-Thani (جُمَادَىٰ ٱلثَّانِي)** 
                         7. **Rajab (رَجَب)** – A sacred month
                         8. **Shaaban (شَعبَان)** – The month preceding Ramadan
                         9. **Ramadan (رَمَضَان)** – The month of fasting
                         10. **Shawwal (شَوَّال)** – The month following Ramadan
                         11. **Dhul-Qadah (ذُو ٱلقَعدَة)** – A sacred month
                         12. **Dhul-Hijjah (ذُو ٱلحِجَّة)** – A sacred month, the month of Hajj and Eid al-Adha
                         """)
                    .font(.body)

                    Text("A Hijri year is approximately 11 days shorter than a Gregorian year, causing Islamic events to shift earlier each Gregorian year. Muslims worldwide use this calendar for religious observances, including fasting in Ramadan, undertaking Hajj, and celebrating Eid al-Fitr and Eid al-Adha.")
                        .font(.body)
                }

                Section(header: Text("SACRED MONTHS")) {
                    Text("Four of the Hijri months are considered sacred: **Muharram**, **Rajab**, **Dhul-Qadah**, and **Dhul-Hijjah**.")
                        .font(.body)

                    Text("These months are distinguished by their sanctity and prohibition of warfare, emphasizing peace and reflection.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) says in the Quran:")
                        .font(.body)

                    ScriptureQuote(text: "“Indeed, the number of months with Allah is twelve... of these, four are sacred. That is the correct religion, so do not wrong yourselves during them” (Quran 9:36).")
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("About eleven days shorter than the solar year, it sets the timing of Ramadan, Hajj, and the two Eids, and marks the four sacred months.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Hijri Calendar")
        .applyConditionalListStyle()
    }
}

struct CompileView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the Quran was preserved from the start by mass memorization and careful writing, gathered into one volume under Abu Bakr, and standardized under Uthman.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("From the first revelation, the Quran was preserved by the Companions through precise memorization (hifdh) and careful writing on parchments, leather, bones, and leaves. Prophet Muhammad (peace and blessings be upon him) had official scribes (including Zayd ibn Thabit) who wrote verses as they were revealed.")
                        .font(.body)

                    Text("Every year in Ramadan, Jibril (Gabriel) reviewed the Quran with Prophet Muhammad (peace and blessings be upon him); in the final year this review occurred twice (al-Ardah al-Akhirah). Prophet Muhammad (peace and blessings be upon him) taught the Companions the exact wording, pronunciation, and the order in which the surahs and ayat should be recited.")
                        .font(.body)
                }

                Section(header: Text("ALLAH’S PROMISE OF PRESERVATION")) {
                    ScriptureQuote(text: "“Indeed, it is We who sent down the Qur'an and indeed, We will be its guardian.” (Quran 15:9)")

                    ScriptureQuote(text: "“Move not your tongue with it to hasten it. Indeed, upon Us is its collection and its recitation. So when We have recited it, then follow its recitation. Then upon Us is its clarification.” (Quran 75:16–19)")

                    ScriptureQuote(text: "“And recite the Quran with measured recitation.” (Quran 73:4)")

                    ScriptureQuote(text: "“And [it is] a Qur'an which We have separated [by intervals] that you might recite it to the people over a prolonged period. And We have sent it down progressively.” (Quran 17:106)")
                }

                Section(header: Text("DURING THE PROPHET’S LIFETIME ﷺ")) {
                    Text("• Memorization first: Many Companions memorized the Quran word-for-word and reviewed it with Prophet Muhammad (peace and blessings be upon him) in prayer and lessons.")
                        .font(.body)
                    Text("• Official scribes: Verses were dictated to scribes such as Zayd ibn Thabit, Ubayy ibn Ka‘b, and others, and kept as written fragments verified by Prophet Muhammad (peace and blessings be upon him).")
                        .font(.body)
                    Text("• Annual review: Jibril reviewed the entire Quran with Prophet Muhammad (peace and blessings be upon him) yearly in Ramadan; in the final year, the review occurred twice, confirming wording and order.")
                        .font(.body)
                }

                Section(header: Text("FIRST COMPILATION UNDER ABU BAKR")) {
                    Text("After the Battle of Yamamah, many memorizers were martyred. About one year after the Prophet’s death (12 AH), at the counsel of Umar ibn al-Khattab, Caliph Abu Bakr commissioned Zayd ibn Thabit to collect the Quran into one compiled manuscript.")
                        .font(.body)

                    Text("Zayd gathered the Quran from written materials and from those who had memorized it, accepting verses only when corroborated by multiple reliable witnesses and his own memorization, all according to what had been reviewed with Prophet Muhammad (peace and blessings be upon him).")
                        .font(.body)

                    Text("This compiled mushaf was kept with Abu Bakr, then with Umar, and after Umar with Hafsah bint Umar (may Allah be pleased with them).")
                        .font(.body)
                }

                Section(header: Text("STANDARDIZATION UNDER UTHMAN")) {
                    Text("As Islam spread, differences in regional reading threatened dispute. Caliph Uthman ibn Affan formed a committee led by Zayd ibn Thabit with senior Qurayshi scholars to produce standardized copies based on the Abu Bakr compilation and the established Uthmanic rasm (consonantal skeleton) that could accommodate the revealed modes.")
                        .font(.body)

                    Text("Uthman sent official copies to major centers (e.g., Kufa, Basra, Sham) and asked that non-verified personal materials be retired to prevent confusion between private notes/duas and the Quranic text. The Companions agreed with this measure, preserving unity upon the authenticated text.")
                        .font(.body)

                    Text("This standardization did not remove revelation; rather, it unified the community upon the verified mushaf that preserved what remained from the seven Ahruf in the Uthmanic rasm and ensured consistent public recitation.")
                        .font(.body)
                }

                Section(header: Text("CONSENSUS OF THE COMPANIONS")) {
                    Text("The Companions - foremost memorizers and teachers - were unanimous in accepting the compilation and the Uthmanic copies. It is widely reported that Abu Bakr, Umar, Uthman, and Ali were among the foremost memorizers and teachers of the Quran, and none objected to the standardized mushaf.")
                        .font(.body)

                    Text("Zayd ibn Thabit led the technical work in both Abu Bakr’s and Uthman’s projects, bringing rigorous verification. Senior scholars, including Quraysh experts, reviewed and approved the copies.")
                        .font(.body)
                }

                Section(header: Text("THE FOUR MASTERS & LEADING TRANSMITTERS")) {
                    Text("Prophet Muhammad (peace and blessings be upon him) said: “Take the Quran from four: Abdullah ibn Masud, Salim (the freed slave of Abu Hudhayfah), Ubayy ibn Ka‘b, and Mu‘adh ibn Jabal.” (Sahih al-Bukhari)")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color.opacity(0.85))

                    Text("These masters, together with others like Zayd ibn Thabit, were key references for wording, recitation, and teaching, anchoring transmission among the Companions and their students.")
                        .font(.body)
                }

                Section(header: Text("AHRUF, QIRAAT, AND THE UTHMANIC RASM")) {
                    Text("Prophet Muhammad (peace and blessings be upon him) taught that the Quran was revealed in seven Ahruf (modes) for ease. The Quran was first compiled into one manuscript under Abu Bakr (may Allah be pleased with him), around one year after the Prophet’s death. Later, the Uthmanic rasm allowed what remained of those modes to be read and transmitted through canonical Qiraat verified by chains. The 10 Qiraat (with their 20 Riwayaat) are mutawatir and reflect how the prophetic recitation was preserved in writing and oral teaching.")
                        .font(.body)

                    Text("Thus, standardization did not limit revelation; it safeguarded it - preventing private notes and unverified materials from being mistaken for the Quran - while preserving the legitimate readings taught by Prophet Muhammad (peace and blessings be upon him).")
                        .font(.body)
                }

                Section(header: Text("KEY REPORTS (BRIEF)")) {
                    Text("• 7 Ahruf: “The Quran was revealed in seven Ahruf, so recite whichever is easiest for you.” (Sahih al-Bukhari; Sahih Muslim)")
                        .font(.body)
                    Text("• Double review in final Ramadan (al-Ardah al-Akhirah): reported in authentic narrations.")
                        .font(.body)
                    Text("• Abu Bakr’s compilation via Zayd after Yamamah: authentic reports in Sahih collections.")
                        .font(.body)
                    Text("• Uthman’s committee (with Zayd) and distribution of official copies: authentic reports in Sahih collections.")
                        .font(.body)
                }

                Section(header: Text("MANUSCRIPT EVIDENCE (HISTORICAL NOTES)")) {
                    Text("Early Quranic manuscripts discovered in different regions (e.g., Hijaz, Yemen, Syria, North Africa, Anatolia) reflect the early Uthmanic rasm and align with the text recited today.")
                        .font(.body)

                    Text("Examples often cited by historians include: the Birmingham fragments (radiocarbon dated to the earliest period of Islam), folios from Sana’a (including palimpsests showing early layers of writing), and early codices associated with major centers and later libraries (e.g., Topkapi).")
                        .font(.body)

                    Text("While scholarly studies analyze paleography, orthography, and dating techniques, the consonantal text aligns with the standardized Uthmanic tradition, and the Quran remains read globally in the same wording preserved by the Ummah.")
                        .font(.body)
                }

                Section(header: Text("WHY WERE PRIVATE MATERIALS RETIRED?")) {
                    Text("Some Companions wrote personal notes - duas, explanations, or hadith - near Quranic passages. To prevent confusion between private annotations and the Quran, and to avoid unchecked variants, Uthman ordered that only the verified official copies be used for public recitation and that other materials be retired.")
                        .font(.body)

                    Text("No Companion rejected the standardized mushaf. The community recited, taught, and transmitted the same Quran by memorization and writing through every generation.")
                        .font(.body)
                }

                Section(header: Text("CONTINUITY UNTIL TODAY")) {
                    Text("The Quran we hold today is the same revelation taught by Prophet Muhammad (peace and blessings be upon him), preserved through the consensus of the Companions, the Uthmanic rasm, the living tradition of memorization, and the mutawatir Qiraat. Around the world, millions memorize the entire Quran - letter for letter - continuing an unbroken chain of transmission.")
                        .font(.body)

                    Text("Public recitation, prayer, and education remain bound to the verified text. The Ummah’s practice fulfills Allah's (Glorified and Exalted be He) promise: its preservation is both textual and living.")
                        .font(.body)
                }

                Section(header: Text("SELECT VERSES & REMINDERS")) {
                    ScriptureQuote(text: "“And when the Quran is recited, then listen to it and pay attention that you may receive mercy.” (Quran 7:204)")

                    ScriptureQuote(text: "“Do they not reflect upon the Quran? If it had been from other than Allah (Glorified and Exalted be He), they would have found within it much contradiction.” (Quran 4:82)")

                    ScriptureQuote(text: "“Falsehood cannot approach it from before it or from behind it; [it is] a revelation from One All-Wise, Praiseworthy.” (Quran 41:42)")
                }

                Section(header: Text("USEFUL LINKS")) {
                    Text("Learn More about the Compilation of the Quran: https://www.youtube.com/watch?v=n281Zyywyn4&t=343s")
                        .font(.caption)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Through unbroken memorization and a verified written text, the Quran remains today exactly as it was revealed - fulfilling Allah's promise to preserve it.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Compilation of the Quran")
        .applyConditionalListStyle()
    }
}

struct TajweedView: View {
    @ObservedObject var settings = Settings.shared
    @State private var showTajweedLegend = false

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Tajweed is the science of reciting the Quran correctly - giving each letter its proper articulation and every rule its due.")
                        .font(.body)
                }

                Section(header: Text("TAJWEED LEGEND")) {
                    #if os(iOS)
                    Button {
                        settings.hapticFeedback()
                        showTajweedLegend = true
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Quick Reference Guide")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(settings.accentColor.color)

                            Text("Simple way to view basic Hafs an Asim Tajweed rules with colors")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    #endif
                }

                Section(header: Text("OVERVIEW")) {
                    Text("Tajweed (تَجوِيد) means “to make well, beautify, or improve,” from the root **j-w-d (ج و د)**. In the context of the Quran, it refers to the set of rules for proper pronunciation during Quran recitation, ensuring each letter is articulated with precision.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) says in the Quran:")
                        .font(.body)

                    ScriptureQuote(text: "“And recite the Quran with measured recitation” (Quran 73:4).")
                }

                Section(header: Text("IMPORTANCE")) {
                    Text("Tajweed ensures the Quran is recited in the most accurate and beautiful way possible, exactly as it was revealed to the Prophet ﷺ. Reciting with Tajweed is not just about making recitation sound pleasant - it is about preserving the integrity of the Quran itself.")
                        .font(.body)

                    Text("The Quran was revealed in Arabic, and every word, letter, and sound has a specific meaning and weight. A slight mispronunciation could change the meaning of a verse. Tajweed helps safeguard against these errors and honors the sacred text with the care and precision it deserves.")
                        .font(.body)

                    Text("Many Muslims find that reciting the Quran with Tajweed enhances their spiritual experience. The attention to detail required for proper recitation encourages mindfulness and deeper reflection on the meaning of the verses, making the recitation feel more immersive and meaningful.")
                        .font(.body)
                }

                Section(header: Text("WHY LEARN TAJWEED?")) {
                    Text("Honoring the Quran: The Quran is the final revelation from Allah. Reciting it with care and precision is a form of respect and reverence for the sacred text.")
                        .font(.body)

                    Text("Preventing Misunderstandings: By applying Tajweed rules, you avoid mistakes that may alter the meaning of verses. Even changing a single sound can result in an entirely different meaning.")
                        .font(.body)

                    Text("Enhancing Spiritual Connection: Proper recitation encourages mindfulness and deeper reflection on the meaning of the verses, making your connection with the Quran more meaningful.")
                        .font(.body)

                    Text("Following the Sunnah: The Prophet Muhammad ﷺ emphasized the importance of reciting the Quran correctly. By learning Tajweed, you follow his example and teachings.")
                        .font(.body)
                }

                Section(header: Text("GETTING STARTED")) {
                    Text("Learning Tajweed might seem intimidating at first, but understanding its importance can make the journey more meaningful. The best way to start is with a qualified teacher who can guide you through the articulation points and characteristics of each letter. Today, there are also online platforms, videos, and books that provide step-by-step lessons.")
                        .font(.body)

                    Text("Focus on mastering the basic rules first, then gradually build your skills over time. Practicing consistently and recording your recitation can help you catch mistakes and improve pronunciation.")
                        .font(.body)
                }

                Section(header: Text("FOR MORE DETAILS")) {
                    NavigationLink(destination: LazyDestination { TajweedFoundationsView() }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tajweed Foundations")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(settings.accentColor.color)
                            Text("Comprehensive guide with rules, topics, and detailed explanations")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section(header: Text("RESOURCES")) {
                    Text("Watch Learn Arabic 101: https://www.youtube.com/@Arabic101")
                        .font(.caption)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Reciting with Tajweed preserves the Quran's pronunciation as it was received from the Prophet, and beautifies and safeguards its meaning.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Tajweed")
        .applyConditionalListStyle()
        #if os(iOS)
        .sheet(isPresented: $showTajweedLegend) {
            NavigationView {
                TajweedLegendView()
            }
            .smallMediumSheetPresentation()
        }
        #endif
    }
}

struct JuzView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the Quran is divided into thirty roughly equal parts called Juz, making it easy to read over a month - especially in Ramadan.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("The Quran is divided into 114 Surahs (chapters), but it is also split into thirty roughly equal parts, called Juz (plural: Ajza).")
                        .font(.body)

                    Text("This division helps Muslims complete the Quran’s recitation systematically, often one Juz per day, especially during Ramadan.")
                        .font(.body)
                }

                Section(header: Text("PURPOSE")) {
                    Text("The division into Juz is primarily for convenience rather than thematic arrangement. It enables systematic daily recitation.")
                        .font(.body)

                    Text("Many Muslims strive to complete the Quran in Ramadan, reciting one Juz per night in Taraweeh prayers. Each Juz is further divided into two Hizbs, making a total of 60 Hizbs.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) says in the Quran:")
                        .font(.body)

                    ScriptureQuote(text: "“So when the Quran is recited, then listen to it and pay attention that you may receive mercy” (Quran 7:204).")
                }

                Section(header: Text("HISTORICAL NOTES")) {
                    Text("While the Quran's content remained unchanged since its revelation, the formal division into 30 Juz was standardized later to facilitate ease of recitation.")
                        .font(.body)

                    Text("This structure fosters a daily relationship with the Quran and encourages reflection on its meanings.")
                        .font(.body)

                    Text("Prophet Muhammad (peace and blessings be upon him) emphasized balanced recitation, saying:")
                        .font(.body)

                    ScriptureQuote(text: "“He who recites the Quran in less than three days does not grasp its meaning” (Sunan Abu Dawud 1394).", dimmed: true)
                }

                // Each Juz is named for the word it opens with, and that name is Arabic. Listing them by number
                // alone (which is all this screen used to do) leaves out the thing they are actually called.
                Section(header: Text("THE THIRTY JUZ")) {
                    ForEach(QuranData.juzList) { juz in
                        HStack(spacing: 12) {
                            Text("\(juz.id)")
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .foregroundColor(settings.accentColor.color)
                                .frame(width: 28, height: 28)
                                .background(
                                    Circle().fill(settings.accentColor.color.opacity(0.15))
                                )

                            Text(juz.nameTransliteration)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)

                            Spacer(minLength: 8)

                            Text(juz.nameArabic)
                                .font(
                                    settings.islamUsesCustomArabicFace
                                        ? Font.arabic(settings.fontArabic, size: 20, relativeTo: .subheadline)
                                        : .title3
                                )
                                .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                                .foregroundColor(settings.accentColor.color)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                        .padding(.vertical, 2)
                    }
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("The thirty Juz are a practical division for reading and memorization, not part of the revelation's meaning, helping Muslims complete the Quran regularly.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Thirty Juz")
        .applyConditionalListStyle()
    }
}

struct AhrufView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the Quran was revealed in seven ahruf - modes of recitation - as a mercy easing its recitation for the different Arab tribes.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("The Quran was revealed by Allah (Glorified and Exalted be He) in seven Ahruf (أَحرُف) - the plural of Harf (حَرف). The word Harf comes from the Arabic root H–r–f (ح ر ف), meaning “edge, border, side, or angle,” referring to a particular “way” or “mode.” Islamically and Quranically, Ahruf refers to the divinely revealed modes of recitation.")
                        .font(.body)

                    Text("A Harf (حَرف) - literally meaning “edge/side/aspect,” and in this context “a mode/way of reciting” - refers to a divinely revealed manner of recitation that includes slight differences in pronunciation, vowel patterns, pausing/connection, or permitted word-forms, while preserving the exact same meaning and guidance.")
                        .font(.body)

                    Text("All seven Ahruf are revelation from Allah (Glorified and Exalted be He). They are not scholarly opinions nor later inventions - they are part of the Quran that Allah (Glorified and Exalted be He) sent down to Prophet Muhammad (peace and blessings be upon him).")
                        .font(.body)
                }

                Section(header: Text("WHY SEVEN AHRUF?")) {
                    Text("The Arabs at the time of revelation had many dialects (Quraysh, Hudhayl, Tamim, Hawazin, etc.). Allah (Glorified and Exalted be He), in His mercy, revealed the Quran in seven modes so that every tribe could recite the Quran easily without difficulty or burden.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) did not reveal seven different Qurans - rather, one Quran with divinely allowed flexibility, making memorization and recitation easier.")
                        .font(.body)
                }

                Section(header: Text("PROPHETIC HADITH ON THE SEVEN AHRUF")) {
                    Text("Prophet Muhammad (peace and blessings be upon him) said:")
                        .font(.body)

                    ScriptureQuote(text: "“The Quran was revealed in seven Ahruf, so recite whichever is easiest for you.”\n- Sahih al-Bukhari • Sahih Muslim", dimmed: true)

                    Text("Another narration explains how Jibril kept requesting ease for the Ummah:")
                        .font(.body)

                    ScriptureQuote(text: "“Jibril recited to me in one harf. I asked him to increase it… until he ended with seven Ahruf.”\n- Sahih Muslim", dimmed: true)

                    Text("In the famous incident of Umar and Hisham ibn Hakim - both of them recited differently, and Prophet Muhammad (peace and blessings be upon him) said that both were revealed, proving that the variations are not mistakes but revelation.")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color.opacity(0.85))
                }

                Section(header: Text("DO THE AHRUF AFFECT PRESERVATION?")) {
                    Text("No. The Quran remains perfectly preserved - letter for letter, word for word, in every revealed mode. The Ahruf are part of that preservation, not a contradiction to it.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) promised:")
                        .font(.body)

                    ScriptureQuote(text: "“Indeed, it is We who sent down the Qur'an and indeed, We will be its guardian.” (Quran 15:9)")

                    Text("The variations in Ahruf do not alter meanings, beliefs, or rulings. Rather, they highlight precision and perfection - the Ummah memorized and transmitted every letter exactly as revealed.")
                        .font(.body)

                    Text("Each harf is revealed, preserved, and protected by Allah (Glorified and Exalted be He). Muslims do not choose or invent a harf - we only recite what Allah (Glorified and Exalted be He) revealed through His Messenger, Prophet Muhammad (peace and blessings be upon him).")
                        .font(.body)
                }

                Section(header: Text("HOW AHRUF WERE PRESERVED")) {
                    Text("• Prophet Muhammad (peace and blessings be upon him) taught the Companions each harf personally.\n• Jibril reviewed the Quran with Prophet Muhammad (peace and blessings be upon him) every year in Ramadan.\n• In the year Prophet Muhammad (peace and blessings be upon him) passed away, Jibril reviewed it twice (al-Ardah al-Akhirah).")
                        .font(.body)

                    Text("About one year after the Prophet’s passing, Abu Bakr (may Allah be pleased with him) commissioned the first complete compilation of the Quran into one manuscript. During the caliphate of Uthman (may Allah be pleased with him), the Ummah was then unified upon official copies from that preserved compilation, written in the Uthmanic rasm, which preserved what the Ummah recited - containing what remained from the seven Ahruf in the rasm.")
                        .font(.body)

                    Text("The Ahruf are preserved through oral transmission, ijazahs, and chains of narration (isnad).")
                        .font(.body)
                }

                Section(header: Text("WHAT ABOUT THE 10 QIRAAT?")) {
                    Text("The 10 Qiraat are the mass-transmitted (mutawatir) methods that show how the Ahruf were preserved through the Uthmanic mushaf and teaching traditions.")
                        .font(.body)

                    Text("Each Qiraah has an unbroken chain (isnad) from the reciter → to his teacher → back to Prophet Muhammad (peace and blessings be upon him).")
                        .font(.body)

                    Text("Learn more in the next section: 10 Qiraat (Canonical Recitations).")
                        .font(.body)
                        .foregroundColor(settings.accentColor.color)
                }

                Section(header: Text("USEFUL LINKS")) {
                    Text("Learn More about Ahruf and Qiraat: https://www.youtube.com/watch?v=8hj7u0F3yEg&t=34s")
                        .font(.caption)
                }


                Section(header: Text("IN SUMMARY")) {
                    Text("The seven ahruf are all from Allah; the surviving canonical recitations preserve what remained after the Uthmanic standardization of the text.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("7 Ahruf (Modes)")
        .applyConditionalListStyle()
    }
}

struct QiraatView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the ten Qiraat are the authentic, mass-transmitted ways of reciting the Quran, each traced through a continuous chain to the Prophet.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("The 10 Qiraat (قِرَاءَات) - from the root q–r–a (قرأ) meaning “to read/recite” - literally means “readings/recitations.” Islamically and Quranically, a Qiraah (قِرَاءَة) is a specific, verified method of reciting the Quran. The 10 Qiraat are the preserved, mass-transmitted (mutawatir - مُتَوَاتِر) recitations of the Quran - each a precise method taught by Prophet Muhammad (peace and blessings be upon him) and transmitted through authentic chains of narrators (isnad إِسنَاد). They do not represent different Qurans, but different prophetic ways of reciting the same revelation.")
                        .font(.body)

                    Text("As covered in the previous section, the Quran was revealed by Allah (Glorified and Exalted be He) in seven Ahruf (أَحرُف) - modes of recitation for ease. Jibril (Gabriel) brought these modes to Prophet Muhammad (peace and blessings be upon him), who taught them to the Ummah. Around one year after the Prophet’s passing, Abu Bakr (may Allah be pleased with him) commissioned the first complete compilation of the Quran into one manuscript, and later Uthman (may Allah be pleased with him) unified public recitation upon official copies from that preserved text. The Qiraat show how those Ahruf were preserved in practice through the Uthmanic rasm (الرَّسم العُثمَانِي) - the consonantal skeleton of the mushaf (مُصحَف).")
                        .font(.body)
                }

                Section(header: Text("WHAT IS A QIRAAH?")) {
                    Text("A Qiraah (قراءة) is a canonical, authenticated way of reciting the Quran that meets three criteria: (1) agreement with the Uthmanic rasm (الرسم العثماني), (2) sound Arabic language, and (3) authentic, widespread transmission (tawatur تواتر).")
                        .font(.body)

                    Text("All 10 Qiraat return to Prophet Muhammad (peace and blessings be upon him). Every reciter has an unbroken chain of students → teachers → Companions → Prophet Muhammad (peace and blessings be upon him).")
                        .font(.body)
                        .foregroundColor(settings.accentColor.color)

                    Text("Most differences are within established rules of tajwid (تجويد), allowable word-forms and vowels, elongation (madd مد), assimilation (idgham إدغام), imalah (إمالة), and stopping/continuation - while preserving the same meanings and guidance.")
                        .font(.body)

                    Text("Important: The Qiraat are not arbitrary. They reflect how the seven Ahruf were preserved through both writing and oral transmission - essentially a “mix and preserve” of the revealed modes into rigorously taught, verifiable recitational methods.")
                        .font(.body)
                }

                Section(header: Text("QIRAAH (قراءة) VS RIWAYAH (رواية)")) {
                    Text("• Qiraah: the recitation method attributed to an Imam of recitation (e.g., Nafi, Asim).")
                        .font(.body)
                    Text("• Riwayah: the narration/transmission of that Qiraah by a primary rawi (narrator). Each Qiraah has two principal riwayaat (plural of riwayah).")
                        .font(.body)

                    Text("Example: “Hafs an Asim” means the riwayah (narration) of Hafs (حفص) from the Qiraah (recitation) of Asim (عاصم). “Warsh an Nafi” means the riwayah of Warsh (ورش) from the Qiraah of Nafi (نافع).")
                        .font(.body)

                    Text("Hafs an Asim is the most widespread globally today; that does not mean it is the only right one. All 10 Qiraat (and their 20 Riwayaat) are valid, mutawatir, and from Prophet Muhammad (peace and blessings be upon him).")
                        .font(.body)
                        .foregroundColor(settings.accentColor.color)
                }

                Section(header: Text("COMMON CLARIFICATIONS")) {
                    Text("Many people hear about 7 and 10 together. Both references are used by scholars: the famous seven canonical recitations (al-Sab'ah) and the full ten canonical Qiraat (7 + 3), all preserved through reliable transmission.")
                        .font(.body)

                    Text("The original seven were famously codified by Imam Abu Bakr Ibn Mujahid. Their Imams are: Nafi (Madinah), Ibn Kathir (Makkah), Abu Amr (Basra), Ibn Amir (Damascus), Asim (Kufa), Hamzah (Kufa), and al-Kisai (Kufa).")
                        .font(.body)

                    Text("Hafs is a riwayah from Asim, and Warsh is a riwayah from Nafi. So when people say Hafs or Warsh, they are naming a narration path within the canonical recitation tradition.")
                        .font(.body)

                    Text("Today, Hafs an Asim is the most widely recited globally (often estimated around 90%+), while other canonical recitations such as Warsh an Nafi remain authentic and practiced.")
                        .font(.body)
                        .foregroundColor(settings.accentColor.color)
                }

                Section(header: Text("AUTHENTICITY & PRESERVATION")) {
                    Text("The 10 Qiraat are mutawatir - mass attested by many independent chains. They are part of the precise preservation Allah (Glorified and Exalted be He) promised for His Book.")
                        .font(.body)

                    ScriptureQuote(text: "“Indeed, it is We who sent down the Qur'an and indeed, We will be its guardian.” (Quran 15:9)")

                    Text("They do not affect preservation; rather, they manifest it: letter for letter, word for word - in all the ways Prophet Muhammad (peace and blessings be upon him) taught.")
                        .font(.body)
                }

                Section(header: Text("THE FOUR MASTERS OF THE QURAN")) {
                    Text("Prophet Muhammad (peace and blessings be upon him) said: “Take the Quran from four: Abdullah ibn Masud, Salim (the freed slave of Abu Hudhayfah), Ubayy ibn Ka‘b, and Mu‘adh ibn Jabal.” (Sahih al-Bukhari)")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color.opacity(0.85))

                    Text("These four masters were among the foremost teachers of the Quran among the Companions, and their recitation and teaching shaped subsequent generations of transmitters.")
                        .font(.body)
                }

                Section(header: Text("THE 10 QIRAAT (القراءات)")) {
                    Text("The 10 Qiraat are the canonical recitation methods of the Quran. Each is named after its primary teacher (the Imam of that recitation).")
                        .font(.body)

                    Group {
                        Text("• Abu Jafar (أَبُو جَعفَر)")
                        Text("• Abu Amr (أَبُو عَمرٍو)")
                        Text("• al-Kisai (الكِسَائِي)")
                        Text("• Asim (عَاصِم)")
                        Text("• Hamzah (حَمزَة)")
                        Text("• Ibn Amir (ابنُ عَامِر)")
                        Text("• Ibn Kathir (ابنِ كَثِير)")
                        Text("• Khalaf al-Ashir (خَلَف العَاشِر)")
                        Text("• Nafi (نَافِع)")
                        Text("• Yaqoub (يَعقُوب)")
                    }
                    .font(.body)
                }

                Section(header: Text("THE 20 RIWAYAAT (روايات)")) {
                    Text("Each Qiraah (recitation method) has two primary riwayaat (narrations). These are the 20 canonical transmissions used in teaching and ijazah (chain certification).")
                        .font(.body)

                    Group {
                        // Abu Jafar
                        Text("• Ibn Wardan an Abi Jafar (ابنُ وَردَان عَن أَبِي جَعفَر)")
                        Text("• Ibn Jammaz an Abi Jafar (ابنُ جَمَّاز عَن أَبِي جَعفَر)")

                        // Abu Amr
                        Text("• ad-Duri an Abi Amr (الدُّورِي عَن أَبِي عَمرٍو)")
                        Text("• as-Susi an Abi Amr (السُّوسِي عَن أَبِي عَمرٍو)")

                        // al-Kisai
                        Text("• Abu al-Harith an al-Kisai (أَبُو الحَارِث عَن الكِسَائِي)")
                        Text("• ad-Duri an al-Kisai (الدُّورِي عَن الكِسَائِي)")

                        // Asim
                        Text("• Shubah an Asim (شُعبَة عَن عَاصِم)")
                        Text("• Hafs an Asim (حَفص عَن عَاصِم)")

                        // Hamzah
                        Text("• Khalaf an Hamzah (خَلَف عَن حَمزَة)")
                        Text("• Khallad an Hamzah (خَلَّاد عَن حَمزَة)")

                        // Ibn Amir
                        Text("• Hisham an Ibn Amir (هِشَام عَن ابنِ عَامِر)")
                        Text("• Ibn Dhakwan an Ibn Amir (ابنُ ذَكوَان عَن ابنِ عَامِر)")

                        // Ibn Kathir
                        Text("• al-Bazzi an Ibn Kathir (البَزِّي عَن ابنِ كَثِير)")
                        Text("• Qunbul an Ibn Kathir (قُنبُل عَن ابنِ كَثِير)")

                        // Khalaf al-Ashir
                        Text("• Ishaq an Khalaf al-Ashir (إِسحَاق عَن خَلَف العَاشِر)")
                        Text("• Idris an Khalaf al-Ashir (إِدرِيس عَن خَلَف العَاشِر)")

                        // Nafi
                        Text("• Warsh an Nafi (وَرش عَن نَافِع)")
                        Text("• Qalun an Nafi (قَالُون عَن نَافِع)")

                        // Yaqoub
                        Text("• Ruways an Yaqoub (رُوَيس عَن يَعقُوب)")
                        Text("• Rawh an Yaqoub (رَوح عَن يَعقُوب)")
                    }
                    .font(.body)
                }

                Section(header: Text("THE COMPANIONS BEHIND EACH QIRAAH")) {
                    Text("Every Qiraah traces back through its Imam and narrators to the Companions (may Allah be pleased with them) who learned the Quran directly from Prophet Muhammad (peace and blessings be upon him). The chains below show which Companions each reading is transmitted from.")
                        .font(.body)

                    Group {
                        Text("**Nafi (Qari of Madinah)** - narrated by Warsh and Qalun. Transmitted from Umar ibn al-Khattab, Zayd ibn Thabit, Ubayy ibn Ka‘b, Abdullah ibn Abbas, Abdullah ibn Ayyash, and Abu Hurayrah (may Allah be pleased with them).")

                        Text("**Ibn Kathir (Qari of Makkah)** - narrated by al-Bazzi and Qunbul. Transmitted from Umar ibn al-Khattab, Zayd ibn Thabit, Ubayy ibn Ka‘b, Abdullah ibn Abbas, and Abdullah ibn as-Sa’ib (may Allah be pleased with them).")

                        Text("**Abu Amr al-Basri (Qari of Basrah)** - narrated by ad-Duri and as-Susi. Transmitted from Umar ibn al-Khattab, Uthman ibn Affan, Ali ibn Abi Talib, Abdullah ibn Mas‘ud, Abu Musa al-Ash‘ari, Abdullah ibn Abbas, Abdullah ibn Ayyash, Abdullah ibn as-Sa’ib, Ubayy ibn Ka‘b, Zayd ibn Thabit, and Abu Hurayrah (may Allah be pleased with them).")

                        Text("**Ibn Amir (Qari of Sham)** - narrated by Hisham and Ibn Dhakwan. Transmitted from Uthman ibn Affan and Abu ad-Darda (may Allah be pleased with them).")

                        Text("**Asim ibn Abi an-Najud (Qari of Kufah)** - narrated by Shu‘bah and Hafs. Most Muslims today recite via Hafs from Asim. Transmitted from Uthman ibn Affan, Ali ibn Abi Talib, Abdullah ibn Mas‘ud, Zayd ibn Thabit, and Ubayy ibn Ka‘b (may Allah be pleased with them).")

                        Text("**Hamzah az-Zayyat** - narrated by Khalaf and Khallad. Transmitted from Uthman ibn Affan, Ali ibn Abi Talib, Ubayy ibn Ka‘b, Zayd ibn Thabit, Abdullah ibn Mas‘ud, and Husayn ibn Ali ibn Abi Talib (may Allah be pleased with them).")

                        Text("**Ali ibn Hamzah al-Kisai** - narrated by Abu al-Harith and ad-Duri. Transmitted from Umar ibn al-Khattab, Uthman ibn Affan, Ali ibn Abi Talib, Ubayy ibn Ka‘b, Zayd ibn Thabit, Abdullah ibn Mas‘ud, Abdullah ibn Abbas, Abdullah ibn Ayyash, Abu Hurayrah, and Husayn ibn Ali ibn Abi Talib (may Allah be pleased with them).")

                        Text("**Ya‘qub al-Hadrami** - narrated by Ruways and Rawh. Transmitted from Umar ibn al-Khattab, Uthman ibn Affan, Ali ibn Abi Talib, Ubayy ibn Ka‘b, Zayd ibn Thabit, Abdullah ibn Mas‘ud, Abu Musa al-Ash‘ari, Abdullah ibn Abbas, Abdullah ibn Ayyash, Abdullah ibn as-Sa’ib, and Abu Hurayrah (may Allah be pleased with them).")

                        Text("**Khalaf al-Bazzar** - narrated by Idris and Ishaq. Transmitted from Uthman ibn Affan, Ali ibn Abi Talib, Abdullah ibn Mas‘ud, Zayd ibn Thabit, Ubayy ibn Ka‘b, and Husayn ibn Ali ibn Abi Talib (may Allah be pleased with them).")

                        Text("**Abu Ja‘far al-Madani** - narrated by Ibn Wardan and Ibn Jammaz. Transmitted from Zayd ibn Thabit, Ubayy ibn Ka‘b, Abdullah ibn Abbas, Abdullah ibn Ayyash, and Abu Hurayrah (may Allah be pleased with them).")
                    }
                    .font(.body)
                }

                Section(header: Text("WHAT THIS CHAIN SHOWS")) {
                    Text("We begin with what Prophet Muhammad (peace and blessings be upon him) began with: the Book of Allah (Glorified and Exalted be He). It is well established that the Quran has reached us by mass transmission (tawatur) through the chains of Ahl as-Sunnah wal-Jama‘ah.")
                        .font(.body)

                    Text("Every one of these narrators of the noble Quran received it, through the chains above, from the Messenger of Allah (peace and blessings be upon him) by way of his Companions (may Allah be pleased with them) - the first to learn, gather, preserve, and transmit it.")
                        .font(.body)

                    Text("Not a single Ithna Ashari (Twelver) Shia is found among these transmitters. This is part of the Quran’s preservation: Allah (Glorified and Exalted be He) did not place in the transmission of His Book anyone who slanders the Companions of His Prophet (peace and blessings be upon him).")
                        .font(.body)
                        .foregroundColor(settings.accentColor.color)

                    Link(destination: URL(string: "https://mahajjah.com/the-manner-in-which-the-ahlus-sunnah-and-shia-act-upon-this-hadith/")!) {
                        Label("Source: Mahajjah - Ahlus Sunnah and Shia on this hadith", systemImage: "link")
                    }
                    .font(.caption)
                }

                Section(header: Text("OTHER REPORTED QIRAAT")) {
                    Text("There are other reported qiraat besides these Ten. Unlike the 10 Qiraat, which are mutawatir and mass attested, those others do not reach mutawatir status. That does not automatically make them inauthentic - some have isnad to Prophet Muhammad (peace and blessings be upon him) - but because they are not mass attested, we avoid them in public recitation and worship.")
                        .font(.body)

                    Text("We recite what is known with certainty (yaqin يقين) to be from Prophet Muhammad (peace and blessings be upon him) - the 10 Qiraat and their 20 Riwayaat. This unites the Ummah upon what is rigorously established.")
                        .font(.body)
                }

                Section(header: Text("PRACTICAL STUDY & ADVICE")) {
                    Text("• Learn with a qualified teacher who has ijazah (إجازة) and isnad (إسناد). Do not self-invent pronunciations or rely only on apps without verification.")
                        .font(.body)
                    Text("• Begin with one riwayah (commonly Hafs an Asim), then explore others (e.g., Warsh an Nafi) as you progress.")
                        .font(.body)
                    Text("• Remember: differences are a mercy, not a contradiction. They illuminate the Quran’s depth and precision.")
                        .font(.body)
                }

                Section(header: Text("IN-APP AUDIO")) {
                    Text("In this app, you can listen to multiple Qiraat/riwayaat (not all twenty are available). Availability varies by full-surah vs. ayah-by-ayah playback.")
                        .font(.body)
                }

                Section(header: Text("RECAP")) {
                    Text("“The 10 Qiraat are the preserved, mass-transmitted (mutawatir) recitations taught by Prophet Muhammad (peace and blessings be upon him), passed down through authentic chains. Each Qiraah is a specific, verified method of reciting the Quran - not a different text. They reflect how the Ahruf were preserved in writing and oral transmission. All 10 Qiraat (and their 20 Riwayaat) return to Prophet Muhammad (peace and blessings be upon him).”")
                        .font(.body)
                        .foregroundColor(settings.accentColor.color)
                }

                Section(header: Text("VISUAL GUIDE")) {
                    VStack(spacing: 12) {
                        Image("Qiraat1")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .focusableImage("Qiraat1", title: "The Ten Qiraat")

                        Image("Qiraat2")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .focusableImage("Qiraat2", title: "The Ten Qiraat")
                    }
                    .padding(.vertical, 4)

                    Link(destination: URL(string: "https://www.instagram.com/p/DZhwEM4Es0b/")!) {
                        Label("View the original post on Instagram", systemImage: "link")
                    }
                    .font(.caption)
                }

                Section(header: Text("IMAGE CREDITS")) {
                    Text("The two infographics above are shared with credit to the original creators on Instagram. Please follow and support their work:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Group {
                        qiraatCreditLink(handle: "orthodox__muslim_badr_deen")
                        qiraatCreditLink(handle: "abdul_quddus_khan_")
                        qiraatCreditLink(handle: "lets.think.deeply")
                        qiraatCreditLink(handle: "khan_ayaan_2008")
                        qiraatCreditLink(handle: "imaanxlogy")
                        qiraatCreditLink(handle: "truth_seeker_of_god")
                    }
                    .font(.caption)
                }

                Section(header: Text("USEFUL LINKS")) {
                    Text("Learn More about Ahruf and Qiraat: https://www.youtube.com/watch?v=8hj7u0F3yEg&t=34s")
                        .font(.caption)

                    Text("Learn about the other Qiraat: https://www.youtube.com/watch?v=CeV6w0rCilQ&t=80s")
                        .font(.caption)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("The differences among the Qiraat are all revelation and add richness of meaning - none contradicts another, and all are recited today.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("10 Qiraat (Recitations)")
        .applyConditionalListStyle()
    }

    /// A tappable Instagram handle that opens the creator's profile, used for the infographic credits.
    private func qiraatCreditLink(handle: String) -> some View {
        Link(destination: URL(string: "https://www.instagram.com/\(handle)/")!) {
            Label("@\(handle)", systemImage: "at")
        }
    }
}

struct FarewellView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the Farewell Sermon was the Prophet's final address to the Ummah at Arafat, summarizing the core teachings of Islam for all time.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("""
                         The Farewell Sermon (خُطبَةُ ٱلوَدَاعِ), delivered by Prophet Muhammad (peace be upon him), took place on the 9th of Dhu al-Hijjah in the 10th year of Hijrah (632 CE) in the Uranah Valley near Mount Arafat. This sermon is one of the most significant moments in Islamic history, as it encapsulates key teachings and guidance for Muslims.
                         """)
                    .font(.body)

                    Text("""
                         During this momentous occasion, Allah (Glorified and Exalted be He) revealed:
                         “This day I have perfected for you your religion and completed My favor upon you and have approved for you Islam as religion” (Quran 5:3).
                         """)
                    .font(.title3)
                    .foregroundColor(settings.accentColor.color)
                }

                Section(header: Text("FINAL DAYS OF THE PROPHET")) {
                    Text("""
                         After delivering this sermon, the Prophet (peace be upon him) continued to guide the Muslim Ummah until his passing on 12th Rabi’ al-Awwal, 11 AH (632 CE). His final words were, “O Allah, with the highest companions,” expressing his longing to meet Allah. He passed away in the home of Aisha (may Allah be pleased with her), leaving behind a legacy of faith and compassion.
                         """)
                    .font(.body)
                }

                Section(header: Text("TEXT OF THE SERMON")) {
                    Text("""
                         O People,

                         Listen attentively, for I do not know whether I will be with you again after this year. Convey my words to those who are absent. Just as you regard this day, this month, and this city as sacred, so regard the life and property of every Muslim as a sacred trust. Return goods entrusted to you to their rightful owners. Do not harm one another, for you will meet your Lord, and He will hold you accountable.

                         Allah has forbidden interest; all interest obligations are canceled, starting with those owed to my uncle, Abbas ibn Abd al-Muttalib. Beware of Satan, for he has lost hope of leading you astray in big matters but will try in small ones.

                         O People,

                         You have rights over your women, and they have rights over you. Treat them with kindness, for they are your partners. Provide for them with goodness. Worship Allah, pray your five daily prayers, fast during Ramadan, give Zakat, and perform Hajj if able. 

                         All mankind is from Adam and Eve. No Arab is superior to a non-Arab, nor is a non-Arab superior to an Arab; no white is superior to a black, nor is a black superior to a white - except in piety and good deeds. Every Muslim is a brother to every other Muslim. Do not commit injustices.

                         After me, no prophet will come, and no new religion will be born. I leave behind the Quran and the Sunnah; if you adhere to them, you will never go astray. Be my witness, O Allah, that I have conveyed Your message.
                         """)
                    .font(.body)
                }

                Section(header: Text("KEY MESSAGES OF THE SERMON")) {
                    Text("""
                         - Sanctity of life, property, and trust.
                         - Abolition of interest (Riba) and unfair practices.
                         - Rights and responsibilities within marriage.
                         - Unity and equality of all humans.
                         - Adherence to the Quran and Sunnah as guidance.
                         """)
                    .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("In it the Prophet affirmed the sanctity of life and property, the equality of all people, the rights of women, and clinging to the Quran and Sunnah - delivered as his religion was perfected.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Farewell Sermon")
        .applyConditionalListStyle()
    }
}

struct SahabahView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the Sahabah are the Companions who accompanied the Prophet, believed in him, and carried Islam to the world - the best generation of this Ummah.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("The **Sahabah (الصَّحَابَة)** - from the root **s-h-b (ص ح ب)**, companionship - are the companions of Prophet Muhammad (peace be upon him).")
                        .font(.body)

                    Text("They supported him in his mission, witnessed the revelation of the Quran, and preserved the teachings of Islam through word and action.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) praised them in the Quran: “And the first forerunners [in the faith] among the Muhajireen and the Ansar and those who followed them with good conduct – Allah is pleased with them and they are pleased with Him” (Quran 9:100).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color)
                }

                Section(header: Text("ABU BAKR AS-SIDDIQ")) {
                    Text("Abu Bakr (may Allah be pleased with him) was the Prophet’s (peace be upon him) closest friend and the first adult male to embrace Islam.")
                        .font(.body)

                    Text("The Prophet (peace be upon him) said: “If I were to take a Khalil (close friend) other than my Lord, I would take Abu Bakr” (Sahih al-Bukhari 3656).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color.opacity(0.85))

                    Text("He was known as As-Siddiq (the Truthful) for immediately affirming the Prophet’s Night Journey (Isra’ and Mi’raj). He was chosen as the first Caliph after the Prophet’s death and led the Muslim Ummah with wisdom and justice.")
                        .font(.body)

                    Text("About one year after the Prophet’s passing, he commissioned Zayd ibn Thabit to compile the Quran into a single manuscript, preserving the revelation in written form alongside mass memorization.")
                        .font(.body)
                }

                Section(header: Text("UMAR IBN AL-KHATTAB")) {
                    Text("Umar (may Allah be pleased with him) was known for his strength, justice, and piety. He was the second Caliph and expanded the Islamic state significantly.")
                        .font(.body)

                    Text("The Prophet (peace be upon him) said: “If there were to be a Prophet after me, it would be Umar ibn Al-Khattab” (Sunan al-Tirmidhi 3686).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color.opacity(0.85))

                    Text("Allah (Glorified and Exalted be He) revealed verses confirming Umar’s opinions, including the ruling of hijab and the prohibition of alcohol.")
                        .font(.body)
                }

                Section(header: Text("UTHMAN IBN AFFAN")) {
                    Text("Uthman (may Allah be pleased with him) was known for his generosity, modesty, and devotion. He unified the Ummah upon official copies of the already compiled Quran, based on the manuscript first compiled under Abu Bakr.")
                        .font(.body)

                    Text("The Prophet (peace be upon him) climbed Mount Uhud with Abu Bakr, Umar, and Uthman and said: “Be firm, O Uhud! For on you there is none but a Prophet, a Siddiq, and two martyrs” (Sahih al-Bukhari 3675).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color.opacity(0.85))

                    Text("He funded the expansion of Al-Masjid an-Nabawi and financed the army during the Battle of Tabuk. His contributions earned him repeated praise from the Prophet (peace be upon him).")
                        .font(.body)
                }

                Section(header: Text("ALI IBN ABI TALIB")) {
                    Text("Ali (may Allah be pleased with him) was the cousin and son-in-law of the Prophet (peace be upon him). He was a scholar, warrior, and deeply spiritual leader.")
                        .font(.body)

                    Text("The Prophet (peace be upon him) said: “You are to me what Harun was to Musa, except there is no prophet after me” (Sahih Muslim 2404).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color.opacity(0.85))

                    Text("He was among the most learned of the Companions, and many later scholars traced their knowledge back to him. He was known for his eloquence, bravery, and deep understanding of Islam.")
                        .font(.body)
                }

                Section(header: Text("MUHAJIREEN & ANSAR")) {
                    Text("The Muhajireen were those who emigrated with the Prophet (peace be upon him) from Makkah to Madinah, leaving behind their wealth and homes for the sake of Allah.")
                        .font(.body)

                    Text("The Ansar were the residents of Madinah who welcomed the Prophet (peace be upon him) and his followers with open hearts and supported them in every way.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) praised them both: “And [also for] those who were settled in al-Madinah and [adopted] the faith before them. They love those who emigrated to them and find not any want in their breasts of what the emigrants were given but give [them] preference over themselves...” (Quran 59:9).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color)
                }

                Section(header: Text("LEGACY")) {
                    Text("The Sahabah preserved the Quran and Hadith, established justice and governance, and exemplified the moral and ethical teachings of Islam.")
                        .font(.body)

                    Text("Their legacy continues to inspire faith, sacrifice, knowledge, and courage in Muslims to this day.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Allah praised the Companions and was pleased with them. Through them the Quran and Sunnah were preserved and conveyed, and honoring them is part of the faith.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Sahabah")
        .applyConditionalListStyle()
    }
}

struct WivesView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the wives of the Prophet are the “Mothers of the Believers,” honored for their faith, and several became key teachers of Islam.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("The wives of Prophet Muhammad (peace be upon him) are honored in Islam as the “Mothers of the Believers” (أُمَّهَاتُ المُؤمِنِين).")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) says in the Quran:")
                        .font(.body)

                    ScriptureQuote(text: "“The Prophet is more worthy of the believers than themselves, and his wives are [in the position of] their mothers” (Quran 33:6).")

                    Text("Prophet Muhammad (peace be upon him) married a total of **11 women** throughout his lifetime. At one time, he was married to a maximum of **9 wives** simultaneously - an exception granted to him as a Prophet. This exception was not unique to him; it was also granted to previous prophets due to their elevated responsibilities and status. For example, Prophet Solomon (peace be upon him) is known to have had a large number of wives, traditionally said to be 100 or more.")
                        .font(.body)
                }

                Section(header: Text("SUPPORT & CONTRIBUTION")) {
                    Text("These women supported the Prophet (peace be upon him) in his mission.")
                        .font(.body)

                    Text("They played vital roles in educating the Muslim community, transmitting Hadith, and exemplifying piety and devotion.")
                        .font(.body)

                    Text("Most of his wives were **widows or divorcees**, many of whom were around his age or older. These marriages were not driven by desire but by **wisdom, compassion, and community building**.")
                        .font(.body)

                    Text("His marriage to **Khadijah bint Khuwaylid** (may Allah be pleased with her) was monogamous and lasted about 25 years, until her death. She was about 15 years older than him, and he took no other wife during her lifetime.")
                        .font(.body)
                }

                Section(header: Text("KHADIJAH")) {
                    Text("Khadijah bint Khuwaylid (may Allah be pleased with her) was the first person to believe in Prophet Muhammad (peace be upon him) and thus the **first Muslim**. After his first revelation in the cave of Hira, she comforted him, wrapped him in a cloak, and reassured him with her deep insight and love.")
                        .font(.body)

                    Text("She said: “Never! By Allah, Allah will never disgrace you. You maintain family ties, speak the truth, support the needy, host guests, and assist those afflicted by calamity” (Sahih al-Bukhari 3).")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) affirmed the beginning of the Prophet’s (peace be upon him) mission in **Surah Al-Muzzammil (73:1)** and **Surah Al-Muddaththir (74:1)** - moments when Khadijah (may Allah be pleased with her) lovingly wrapped and comforted him.")
                        .font(.body)
                        .foregroundColor(settings.accentColor.color)

                    Text("The Prophet (peace be upon him) said of her: “She believed in me when the people disbelieved, she affirmed my truthfulness when the people belied me, she supported me with her wealth when the people deprived me, and Allah granted me children by her and not by any other woman” (Musnad Ahmad 24864). Aisha (may Allah be pleased with her) reported that he said, “I was given her love” (Sahih Muslim 2435).")
                        .font(.body)
                }

                Section(header: Text("AISHA")) {
                    Text("Aisha bint Abi Bakr (may Allah be pleased with her) was the daughter of Abu Bakr as-Siddiq (may Allah be pleased with him), the closest companion of the Prophet (peace be upon him). She was the most knowledgeable among the people, especially in Hadith and Islamic jurisprudence.")
                        .font(.body)

                    Text("She was falsely accused in the incident of al-Ifk, but Allah (Glorified and Exalted be He) revealed her innocence in **Surah An-Nur (24:11–26)**, establishing her purity and honor for all time.")
                        .font(.body)
                        .foregroundColor(settings.accentColor.color)

                    Text("The Prophet (peace be upon him) was once asked, “Who do you love the most?” He replied, “Aisha.” They asked, “And among men?” He answered, “Her father” (Sahih al-Bukhari 3662).")
                        .font(.body)

                    Text("He also said, “The superiority of Aisha to other women is like the superiority of Tharid to other foods” (Sahih Muslim 2446).")
                        .font(.body)

                    Text("After the Prophet’s (peace be upon him) death, she became one of the greatest scholars of Islam. She taught both men and women and was a source of religious rulings and interpretations.")
                        .font(.body)

                    Text("She narrated **2,210 hadiths**, making her the **fourth-highest hadith narrator** of all time. Most of these relate to the Prophet’s private life, which only she had access to. Without Aisha (may Allah be pleased with her), much of the Prophet’s (peace be upon him) household life, worship, and character would not be known today.")
                        .font(.body)
                }

                Section(header: Text("HOW HE TREATED HIS WIVES")) {
                    Text("The Prophet (peace be upon him) was the best example of kindness, patience, and love toward his wives. These hadiths reflect his character:")
                        .font(.body)

                    Text("• “The best of you are those who are best to their wives, and I am the best of you to my wives” (Sunan al-Tirmidhi 3895).")
                        .font(.body)

                    Text("• Aisha (may Allah be pleased with her) said: “The Messenger of Allah (peace be upon him) never struck anything with his hand, not a woman nor a servant” (Sahih Muslim 2328).")
                        .font(.body)

                    Text("• “A believing man should not hate a believing woman. If he dislikes one of her characteristics, he will be pleased with another” (Sahih Muslim 1469).")
                        .font(.body)

                    Text("• Aisha (may Allah be pleased with her) said: “He used to serve his family, and when the time for prayer came, he would go out to pray” (Sahih al-Bukhari 6039).")
                        .font(.body)
                }

                Section(header: Text("THE ELEVEN WIVES")) {
                    Group {
                        Text("• Khadijah bint Khuwaylid (may Allah be pleased with her)")
                        Text("• Sawdah bint Zam’ah (may Allah be pleased with her)")
                        Text("• Aisha bint Abi Bakr (may Allah be pleased with her)")
                        Text("• Hafsah bint Umar (may Allah be pleased with her)")
                        Text("• Zaynab bint Khuzaymah (may Allah be pleased with her)")
                        Text("• Umm Salamah (Hind bint Abi Umayyah) (may Allah be pleased with her)")
                        Text("• Zaynab bint Jahsh (may Allah be pleased with her)")
                        Text("• Juwayriyah bint al-Harith (may Allah be pleased with her)")
                        Text("• Umm Habibah (Ramlah bint Abi Sufyan) (may Allah be pleased with her)")
                        Text("• Safiyyah bint Huyayy (may Allah be pleased with her)")
                        Text("• Maymunah bint al-Harith (may Allah be pleased with her)")
                    }
                    .font(.body)
                }

                Section(header: Text("WHY SO MANY MARRIAGES?")) {
                    Text("These marriages fulfilled many noble purposes:")
                        .font(.body)

                    Text("• **Supporting widows** who lost husbands in early battles.")
                        .font(.body)

                    Text("• **Forming alliances** with key tribes to strengthen the Muslim community.")
                        .font(.body)

                    Text("• **Spreading Islamic knowledge**, as many of his wives became teachers and Hadith narrators.")
                        .font(.body)

                    Text("• **Setting legal and social precedents** for Muslim family law and ethics.")
                        .font(.body)
                }

                Section(header: Text("LEGACY")) {
                    Text("The lives of the Prophet’s (peace be upon him) wives highlight the essential role of women in Islamic scholarship and community-building.")
                        .font(.body)

                    Text("They are role models for Muslims, inspiring faith, resilience, and devotion.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Through the Prophet's wives - especially Aisha - much of the Sunnah of the home and worship reached the Ummah; loving and respecting them is part of the religion.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Wives")
        .applyConditionalListStyle()
    }
}

struct CaliphatesView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the Caliphate is the leadership that continued the Prophet's mission, beginning with the Rightly Guided Caliphs Abu Bakr, Umar, Uthman, and Ali.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("The **Caliphate (الخِلَافَة)** - from the root **kh-l-f (خ ل ف)**, meaning succession - refers to the divinely guided system of governance established after the death of Prophet Muhammad (peace be upon him). It aimed to continue his mission of upholding justice, spreading Islam, and preserving the unity of the Ummah.")
                        .font(.body)

                    Text("The Caliph (خَلِيفَة), literally “successor“ - was entrusted with political, military, judicial, and spiritual leadership, guided by the Quran and Sunnah. The first four caliphs, known as the **Rightly Guided Caliphs (ٱلخُلَفَاء ٱلرَّاشِدُون)**, are regarded as models of righteous rule.")
                        .font(.body)

                    Text("The Prophet (peace be upon him) said: “The Caliphate will remain among you for thirty years, then Allah will give the kingdom to whomever He wills” (Sunan Abi Dawud 4646).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color.opacity(0.85))

                    Text("These thirty years - known as the **Rashidun Caliphate** - represented the ideal Islamic system. The caliphs were chosen by **consultation (شُورَىٰ)** and the pledge of allegiance (**bay'ah, بَيعَة**) of the community: Abu Bakr at Saqifah and then in the mosque, and Uthman after Abd al-Rahman ibn Awf canvassed the people of Madinah house by house - men and women alike - for three nights (Sahih al-Bukhari 7207). This model emphasized justice, humility, accountability, and service to the people.")
                        .font(.body)
                }

                Section(header: Text("ABU BAKR AS-SIDDIQ (632–634 CE)")) {
                    Text("Abu Bakr (may Allah be pleased with him), the Prophet’s closest companion and the first adult male to accept Islam, was chosen as the **first caliph** immediately after the Prophet’s passing. He was selected through consensus at Saqifah.")
                        .font(.body)

                    Text("He led decisively during a time of crisis, launching the **Riddah Wars** to bring back apostate tribes and false prophets. About one year after the Prophet’s death (12 AH), he initiated the first complete compilation of the Quran into a single manuscript.")
                        .font(.body)

                    Text("The Prophet (peace be upon him) said: “There is no one who has helped me more with his wealth and companionship than Abu Bakr” (Sahih al-Bukhari 3661).")
                        .foregroundColor(settings.accentColor.color.opacity(0.85))
                        .font(.title3)

                    Text("His caliphate lasted just over two years but laid the foundation for unity and stability in the Ummah.")
                        .font(.body)
                }

                Section(header: Text("UMAR IBN AL-KHATTAB (634–644 CE)")) {
                    Text("Umar (may Allah be pleased with him) was appointed by Abu Bakr before his death and accepted by the Muslims as the second caliph. He was renowned for justice, strength, and fear of Allah (Glorified and Exalted be He).")
                        .font(.body)

                    Text("His 10-year reign witnessed the rapid expansion of Islam into the **Byzantine and Persian Empires**, including Jerusalem and Egypt. He established **public registers**, **courts**, **salaries for soldiers**, and the **Islamic calendar**.")
                        .font(.body)

                    Text("The Prophet (peace be upon him) said: “Indeed, Allah has placed the truth upon Umar’s tongue and heart” (Sunan al-Tirmidhi 3682).")
                        .foregroundColor(settings.accentColor.color.opacity(0.85))
                        .font(.title3)

                    Text("He was assassinated while praying in the masjid and is buried beside the Prophet Muhammad (peace be upon him).")
                        .font(.body)
                }

                Section(header: Text("UTHMAN IBN AFFAN (644–656 CE)")) {
                    Text("Uthman (may Allah be pleased with him) was chosen through a **council of six** appointed by Umar. Known for his generosity and modesty, he married two daughters of the Prophet Muhammad (peace be upon him) and was called **Dhu al-Nurayn** (ذُو ٱلنُّورَين – the Possessor of Two Lights).")
                        .font(.body)

                    Text("He **standardized official copies of the Quran** from the already compiled manuscript preserved from Abu Bakr’s time, unifying public recitation and preventing disputes over unverified personal materials. He sent official copies to major cities and retired non-verified personal codices used outside official transmission.")
                        .font(.body)

                    Text("The Prophet (peace be upon him) said: “Should I not feel shy of the one whom the angels are shy of?” (Sahih Muslim 2401).")
                        .foregroundColor(settings.accentColor.color.opacity(0.85))
                        .font(.title3)

                    Text("Due to political unrest and false accusations, he was unjustly besieged and martyred while reciting the Quran.")
                        .font(.body)
                }

                Section(header: Text("ALI IBN ABI TALIB (656–661 CE)")) {
                    Text("Ali (may Allah be pleased with him), the cousin and son-in-law of the Prophet Muhammad (peace be upon him), was chosen as the fourth caliph after Uthman’s martyrdom.")
                        .font(.body)

                    Text("His caliphate was challenged by internal strife, including the **Battle of the Camel** and **Battle of Siffin**. Despite the trials, he remained committed to justice and truth.")
                        .font(.body)

                    Text("The Prophet (peace be upon him) said to him: “You are to me like Harun was to Musa, except that there is no prophet after me” (Sahih Muslim 2404).")
                        .foregroundColor(settings.accentColor.color.opacity(0.85))
                        .font(.title3)

                    Text("Ali was assassinated in Kufah while leading the Fajr prayer. His legacy lives on in scholarship, courage, and moral leadership.")
                        .font(.body)
                }

                Section(header: Text("LEGACY OF THE RASHIDUN")) {
                    Text("The Rashidun Caliphs (632–661 CE) ruled with unmatched integrity, transparency, and adherence to prophetic tradition. Their rule was guided by **shura (شُورَىٰ)**, justice, and humility.")
                        .font(.body)

                    Text("Though later caliphates transitioned into **hereditary monarchy**, the Prophet Muhammad (peace be upon him) had foretold this change.")
                        .font(.body)

                    Text("He said: “The Caliphate after me will last thirty years; then there will be kingship” (Sunan Abi Dawud 4646).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color.opacity(0.85))

                    Text("Despite this shift, many later caliphs still contributed greatly to Islamic knowledge, architecture, and global influence.")
                        .font(.body)
                }

                Section(header: Text("THE UMAYYAD CALIPHATE (661–750 CE)")) {
                    Text("The Umayyads, beginning with Mu'awiyah ibn Abi Sufyan (may Allah be pleased with him), transitioned the caliphate into a **dynastic monarchy**. Their capital was **Damascus (دِمَشق)**.")
                        .font(.body)

                    Text("They expanded Islam into **al-Andalus (Spain)**, **North Africa**, and **Central Asia**, and made **Arabic** the official administrative language.")
                        .font(.body)

                    Text("Though less spiritually exemplary than the Rashidun, the Umayyads left a profound legacy in governance, culture, and infrastructure.")
                        .font(.body)
                }

                Section(header: Text("THE ABBASID CALIPHATE (750–1258 CE)")) {
                    Text("The Abbasids overthrew the Umayyads and moved the capital to **Baghdad (بَغدَاد)**, initiating the **Golden Age of Islam**.")
                        .font(.body)

                    Text("They supported **translation**, **science**, **mathematics**, **medicine**, and **philosophy**, and established the renowned **Bayt al-Hikmah (بَيت ٱلحِكمَة – House of Wisdom)**.")
                        .font(.body)

                    Text("Although internal divisions weakened the state, their intellectual contributions influenced both the Muslim world and Europe. The empire fell to the Mongols in 1258 CE.")
                        .font(.body)
                }

                Section(header: Text("THE OTTOMAN CALIPHATE (1517–1924 CE)")) {
                    Text("The Ottomans, a Turkish dynasty, were the **first non-Arabs** to assume the Islamic Caliphate. After the fall of the Abbasids in Egypt, the caliphate passed to the Ottomans, whose capital was **Istanbul (إِسطَنبُول)**.")
                        .font(.body)

                    Text("They ruled a vast empire across **Europe**, **Asia**, and **Africa**, preserved **Islamic law (ٱلشَّرِيعَة)**, and defended the **Two Holy Mosques** in **Makkah (مَكَّة)** and **Madinah (ٱلمَدِينَة)**.")
                        .font(.body)

                    Text("The Ottoman Caliphate was officially **abolished in 1924 CE** by Mustafa Kemal Atatürk, ending more than 1,300 years of continuous Islamic political leadership.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("The Rightly Guided Caliphs are the model of just Islamic governance - preserving the Quran, spreading the faith, and upholding the unity of the Ummah.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Caliphates")
        .applyConditionalListStyle()
    }
}

struct MadhabView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the four madhahib - Hanafi, Maliki, Shafi'i, and Hanbali - are the accepted schools of Islamic jurisprudence, differing in fiqh but united in creed.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("A **madhhab (مَذهَب)** is a school of Islamic jurisprudence that provides structured guidance on how to derive and apply rulings from the Quran and Sunnah. The plural is **madhahib (مَذَاهِب)**.")
                        .font(.body)

                    Text("Madhahib developed as scholars preserved and codified fiqh (فِقه), or Islamic legal reasoning/jurisprudence, to help Muslims navigate daily life, worship, transactions, and society with clarity and consistency.")
                        .font(.body)

                    Text("Following a madhhab ensures one is following a valid, peer-reviewed methodology developed by righteous scholars deeply rooted in the Quran, Sunnah, consensus (إِجمَاع), and analogy (قِيَاس). It is not blind following - it is trust in generations of qualified scholarship.")
                        .font(.body)

                    Text("The Prophet Muhammad (peace be upon him) said: “Scholars are the inheritors of the prophets” (Sunan Abi Dawud 3641).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color.opacity(0.85))
                }

                Section(header: Text("WHY FOLLOW A MADHHAB?")) {
                    Text("Islamic rulings are not always black and white. Scholars developed principles to interpret revelation when texts appeared to conflict or were not explicit.")
                        .font(.body)

                    Text("For example, rulings on prayer times, purification, zakah calculation, marriage, and contracts all require detailed interpretation. Madhahib systematize this process based on authentic sources and established rules.")
                        .font(.body)

                    Text("Instead of picking rulings randomly or following desire, a madhhab offers **structured, principled, and scholarly guidance**. It helps prevent inconsistency and distortion in religious practice.")
                        .font(.body)
                }

                Section(header: Text("THE FOUR SUNNI MADHAHIB")) {
                    imamEntry(
                        number: 1,
                        name: "Imam Abu Hanifa (may Allah have mercy on him)",
                        arabic: "أَبُو حَنِيفَة",
                        meta: "Hanafi (الحَنَفِي) · Kufa, Iraq (الكُوفَة، العِرَاق) · 80–150 AH / 699–767 CE",
                        description: "The Imam of Kufa and founder of the Hanafi school. Known for his mastery of fiqh, ijtihad, and qiyas (analogical reasoning) and for his rigorous legal methodology. It is the most followed madhhab today, especially in South Asia, Turkey, Central Asia, and the Balkans."
                    )

                    imamEntry(
                        number: 2,
                        name: "Imam Malik ibn Anas (may Allah have mercy on him)",
                        arabic: "مَالِك بن أَنَس",
                        meta: "Maliki (المَالِكِي) · Madinah (المَدِينَة) · 93–179 AH / 715–795 CE",
                        description: "The Imam of Madinah and compiler of Al-Muwatta (المُوَطَّأ), renowned for preserving the Sunnah and the practice of the people of Madinah (عَمَل أَهل المَدِينَة). His school is dominant across North and West Africa."
                    )

                    imamEntry(
                        number: 3,
                        name: "Imam Muhammad ibn Idris al-Shafi‘i (may Allah have mercy on him)",
                        arabic: "الشَّافِعِي",
                        meta: "Shafi‘i (الشَّافِعِي) · Egypt (مِصر) · 150–204 AH / 767–820 CE",
                        description: "The Imam who systematized the principles of Islamic jurisprudence, usul al-fiqh (أُصُول الفِقه). Born in Gaza, he studied in Makkah and Madinah and later in Iraq, and shaped his final madhhab in Egypt, where it took its lasting form. Popular in East Africa, Indonesia, Malaysia, and parts of Egypt and Yemen."
                    )

                    imamEntry(
                        number: 4,
                        name: "Imam Ahmad ibn Hanbal (may Allah have mercy on him)",
                        arabic: "أَحمَد بن حَنبَل",
                        meta: "Hanbali (الحَنبَلِي) · Baghdad (بَغدَاد) · 164–241 AH / 780–855 CE",
                        description: "The Imam of Ahl al-Hadith (أَهل الحَدِيث), renowned for his steadfastness during the Mihna (المِحنَة, the Inquisition) and his firm adherence to the Quran and Sunnah, using analogy only when necessary. Mainly followed in Saudi Arabia and the Gulf."
                    )
                }

                Section(header: Text("WHEN THE MADHAHIB TOOK SHAPE")) {
                    Text("None of the four imams formally founded an institution. Each taught a methodology that his students preserved and systematized into a school over the generations, so historians distinguish between the life of the imam and the emergence of the madhhab.")
                        .font(.body)

                    Text("The Hanafi school began in Kufa during Abu Hanifa’s lifetime and was firmly established by his students Abu Yusuf (d. 182 AH) and Muhammad al-Shaybani (d. 189 AH). The Maliki school developed in Madinah through Imam Malik’s teaching circle and Al-Muwatta. The Shafi‘i school crystallized in Egypt in Imam al-Shafi‘i’s final years - his “new” madhhab - and spread after him through students like al-Muzani and al-Buwayti. The Hanbali school was collected and systematized after Imam Ahmad’s death by his sons and students such as al-Khallal.")
                        .font(.body)

                    Text("The four imams form an unbroken chain of teacher and student: Imam Malik taught al-Shafi‘i, who in turn taught Ahmad ibn Hanbal. Imam Malik was also a contemporary of Abu Hanifa, and al-Shafi‘i was born in the very year Abu Hanifa passed away (150 AH).")
                        .font(.body)
                }

                Section(header: Text("UNITY THROUGH DIVERSITY")) {
                    Text("All four madhahib are valid and respected paths within Ahl al-Sunnah wa al-Jama‘ah (أَهل السُّنَّة وَالجَمَاعَة). Though they may differ in legal rulings, they are united in the same ‘aqeedah (عَقِيدَة) - the core beliefs regarding Allah, His names and attributes, prophethood, the Quran, the unseen, and the Afterlife.")
                        .font(.body)

                    Text("This shared creed is why they are all considered part of Ahl al-Sunnah wa al-Jama‘ah. The differences among them are in jurisprudence (fiqh), not faith (‘aqeedah), and reflect the depth and mercy of Islamic legal tradition.")
                        .font(.body)

                    Text("No single school is “more Islamic“ - each preserved knowledge and served the Ummah according to its time and place. Following any of them keeps one on the path of the Prophet (peace be upon him) and his companions.")
                        .font(.body)

                    Text("Imam Malik ibn Anas (may Allah have mercy on him) said: “Everyone's statement may be taken from or rejected, except the one in this grave” - pointing to the grave of the Prophet (peace be upon him).")
                        .font(.body)
                }

                Section(header: Text("CONCLUSION")) {
                    Text("Following a madhhab gives structure to religious life and connects Muslims to a legacy of knowledge, discipline, and unity. While it is not obligatory to follow one, it is highly encouraged, especially for those without deep training in Islamic law.")
                        .font(.body)

                    Text("If one is unsure which madhhab to follow, they may follow the trusted local scholars in their community, and Allah (Glorified and Exalted be He) will reward sincerity and effort.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Following a qualified school connects a Muslim to generations of disciplined scholarship; their differences are a mercy, and all are within Ahl as-Sunnah.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("The 4 Madhahib")
        .applyConditionalListStyle()
    }

    /// One imam's entry: a bold name (with the Arabic name), a secondary line of school / region / dates, and a
    /// short description.
    private func imamEntry(number: Int, name: String, arabic: String, meta: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("**\(number). \(name)** - \(arabic)")
                .font(.body)

            Text(meta)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(description)
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AhlulBaytView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the Ahlul Bayt are the family of the Prophet - loving, honoring, and upholding their rights is part of the religion.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("The **Ahlul Bayt (أَهلُ البَيت)** - literally “the People of the House“ - are the family of Prophet Muhammad (peace be upon him). Loving them, honoring them, and upholding their rights is part of the religion, and hating them or belittling them is a grave sin.")
                        .font(.body)

                    Text("The Quran uses the term directly when addressing the Prophet’s household:")
                        .font(.body)

                    ScriptureQuote(text: "“Allah only intends to remove from you the impurity [of sin], O people of the household, and to purify you with [extensive] purification” (Quran 33:33).")

                    Text("This is one continuous passage. It is essential to read the verses immediately before and after it to see who is being addressed.")
                        .font(.body)
                }

                Section(header: Text("THE WIVES ARE PART OF THE AHLUL BAYT")) {
                    Text("The verse of purification (33:33) sits in the middle of a passage directed to the Prophet’s wives (may Allah be pleased with them). The address begins:")
                        .font(.body)

                    ScriptureQuote(text: "“O wives of the Prophet, you are not like anyone among women. If you fear Allah, then do not be soft in speech…” (Quran 33:32).")

                    ScriptureQuote(text: "“And abide in your houses and do not display yourselves as [was] the display of the former times of ignorance. And establish prayer and give zakah and obey Allah and His Messenger. Allah only intends to remove from you the impurity, O people of the household, and to purify you with [extensive] purification” (Quran 33:33).")

                    ScriptureQuote(text: "“And remember what is recited in your houses of the verses of Allah and wisdom. Indeed, Allah is ever Subtle and Acquainted [with all things]” (Quran 33:34).")

                    Text("The phrase “O people of the household“ is therefore addressed, first and foremost, to the wives of the Prophet (peace be upon him) - the **Mothers of the Believers (أُمَّهَاتُ المُؤمِنِين)**, whom Allah placed in the position of mothers to every believer (Quran 33:6).")
                        .font(.body)

                    Text("Allah also called the wife of Ibrahim (peace be upon him) part of the “people of the house“ using the very same expression:")
                        .font(.body)

                    ScriptureQuote(text: "“They said, ‘Are you amazed at the decree of Allah? May the mercy of Allah and His blessings be upon you, people of the house. Indeed, He is Praiseworthy and Honorable’” (Quran 11:73).")

                    Text("So a prophet’s wives being included in “Ahl al-Bayt“ is the established Quranic usage, not an exception.")
                        .font(.body)
                }

                Section(header: Text("THE FAMILY OF THE CLOAK")) {
                    Text("The Ahlul Bayt also includes the Prophet’s daughter **Fatimah**, his cousin and son-in-law **Ali**, and their sons **al-Hasan** and **al-Husayn** (may Allah be pleased with them all).")
                        .font(.body)

                    Text("Aisha (may Allah be pleased with her) narrated: “The Prophet (peace be upon him) went out one morning wearing a cloak of black camel hair. Al-Hasan ibn Ali came and he took him in, then al-Husayn came in with him, then Fatimah, then Ali. Then he said: ‘Allah only intends to remove from you the impurity, O people of the household, and to purify you with [extensive] purification’” (Sahih Muslim 2424).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color.opacity(0.85))

                    Text("Including these four does not exclude the wives - the Prophet (peace be upon him) was gathering additional members of his household under the cloak, within a passage whose context is already addressing his wives. The two are complementary, not contradictory.")
                        .font(.body)

                    Text("The Prophet (peace be upon him) said of his grandsons: “Al-Hasan and al-Husayn are the two masters of the youth of Paradise” (Sunan al-Tirmidhi 3768).")
                        .font(.body)

                    Text("And of Fatimah (may Allah be pleased with her) he said: “Fatimah is a part of me. Whoever angers her angers me” (Sahih al-Bukhari 3714).")
                        .font(.body)
                }

                Section(header: Text("THE BANU HASHIM AND THE PROPHET’S KIN")) {
                    Text("The Ahlul Bayt further includes the relatives of the Prophet (peace be upon him) upon whom charity (sadaqah) is forbidden: the family of Ali, the family of Ja‘far, the family of Aqil, and the family of al-Abbas (may Allah be pleased with them).")
                        .font(.body)

                    Text("The Prophet (peace be upon him) said: “Charity is not permissible for Muhammad or the family of Muhammad; it is only the people’s impurities” (Sahih Muslim 1072).")
                        .font(.body)

                    Text("Zayd ibn Arqam (may Allah be pleased with him) was asked, “Who are the people of his household? Are not his wives among the people of his household?” He said: “His wives are among the people of his household, but the people of his household are those for whom charity is forbidden after him” (Sahih Muslim 2408).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color.opacity(0.85))
                }

                Section(header: Text("THE COMMAND TO LOVE THEM")) {
                    Text("Allah (Glorified and Exalted be He) says:")
                        .font(.body)

                    ScriptureQuote(text: "“Say, [O Muhammad], ‘I do not ask you for it any payment [but] only good will through kinship’” (Quran 42:23).")

                    Text("In his farewell address the Prophet (peace be upon him) said: “I am leaving among you two weighty things: the first is the Book of Allah, in which there is guidance and light… hold fast to the Book of Allah.” Then he said: “And the people of my household. I remind you of Allah concerning the people of my household. I remind you of Allah concerning the people of my household” (Sahih Muslim 2408).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color.opacity(0.85))

                    Text("Every believer sends blessings upon them in each prayer: “O Allah, send prayers upon Muhammad and upon the family of Muhammad, as You sent prayers upon Ibrahim and upon the family of Ibrahim” (Sahih al-Bukhari 3370).")
                        .font(.body)

                    Text("Loving the Ahlul Bayt is a sign of faith. It is never in tension with loving the Companions (may Allah be pleased with them) - Ali, al-Hasan, al-Husayn, and the Prophet’s wives were themselves among the Companions.")
                        .font(.body)
                }

                Section(header: Text("THE BALANCED POSITION")) {
                    Text("There are two errors regarding the Ahlul Bayt. Some **neglect their rights** and fail to honor them as Allah and His Messenger commanded. Others **exaggerate beyond bounds**, elevating them past the station Allah gave them, or using love of them as a pretext to curse and slander the Companions.")
                        .font(.body)

                    Text("The straight path is between the two: love and honor them without exaggeration, and love all the Companions of the Prophet (peace be upon him) alongside them.")
                        .font(.body)

                    ScriptureQuote(text: "“And [there is a share for] those who came after them, saying, ‘Our Lord, forgive us and our brothers who preceded us in faith and put not in our hearts [any] resentment toward those who have believed. Our Lord, indeed You are Kind and Merciful’” (Quran 59:10).")

                    Text("Ali, al-Hasan, and al-Husayn (may Allah be pleased with them) themselves loved, prayed behind, married into, and named their children after Abu Bakr, Umar, and Uthman (may Allah be pleased with them). Their example is the proof of this unity.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Balanced love for the Prophet's household, without exaggeration or neglect, is the way of the believers - joined with love for all his Companions.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("The People of the House")
        .applyConditionalListStyle()
    }
}

struct AhlusSunnahView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Ahl as-Sunnah wal-Jama'ah are those who hold to the Sunnah of the Prophet upon the understanding of his Companions, united in creed.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("**Ahl as-Sunnah wal-Jama‘ah (أَهلُ السُّنَّةِ وَالجَمَاعَة)** means “the People of the Sunnah and the Community.“ They are those who hold to the Sunnah of the Prophet Muhammad (peace be upon him) and remain united upon the understanding of his Companions (may Allah be pleased with them).")
                        .font(.body)

                    Text("**Sunnah** here means the Prophet’s way - his beliefs, statements, actions, and approvals. **Jama‘ah** means the united body of the believers, and specifically the way of the Companions and those who followed them in goodness.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) says:")
                        .font(.body)

                    ScriptureQuote(text: "“And whoever opposes the Messenger after guidance has become clear to him and follows other than the way of the believers - We will give him what he has taken and drive him into Hell, and evil it is as a destination” (Quran 4:115).")

                    Text("“The way of the believers“ in this verse is the way of the first believers: the Companions.")
                        .font(.body)
                }

                Section(header: Text("THE THREE FOUNDATIONS")) {
                    Text("**1. The Quran** - taken as it is, without distortion, denial, or asking “how.“")
                        .font(.body)

                    Text("**2. The authentic Sunnah** - accepted as binding revelation alongside the Quran, whether the report is mutawatir or an authentic single narration (ahad).")
                        .font(.body)

                    Text("**3. The understanding of the Salaf** - the Quran and Sunnah are understood the way the first three generations understood them, not according to later opinions or personal reasoning that contradicts them.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) says: “And the first forerunners among the Muhajireen and the Ansar and those who followed them with good conduct - Allah is pleased with them and they are pleased with Him” (Quran 9:100).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color)

                    Text("The Prophet (peace be upon him) said: “The best of people are my generation, then those who follow them, then those who follow them” (Sahih al-Bukhari 2652).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color.opacity(0.85))
                }

                Section(header: Text("THEIR CREED (AQEEDAH)")) {
                    Text("• **Tawhid**: Allah alone is worshipped, and He alone is the Lord, and He is called by His beautiful Names and described by His perfect Attributes.")
                        .font(.body)

                    Text("• **Names and Attributes**: affirmed as Allah affirmed them for Himself, without likening Him to creation (tashbih) and without stripping the meanings away (ta‘til).")
                        .font(.body)

                    ScriptureQuote(text: "“There is nothing like unto Him, and He is the Hearing, the Seeing” (Quran 42:11).")

                    Text("• **Iman** consists of belief in the heart, statement of the tongue, and action of the limbs. It increases with obedience and decreases with disobedience.")
                        .font(.body)

                    Text("• **Qadar**: everything occurs by Allah’s knowledge, writing, will, and creation, while the servant has real choice and responsibility.")
                        .font(.body)

                    Text("• **No takfir** of a Muslim for a major sin, so long as he does not deem it lawful. The sinner remains a believer, deficient in faith.")
                        .font(.body)

                    Text("• Love for **all the Companions** (may Allah be pleased with them) and the **Ahlul Bayt**, without exaggeration in either direction.")
                        .font(.body)
                }

                Section(header: Text("THE SAVED GROUP")) {
                    Text("The Prophet (peace be upon him) said: “The Jews split into seventy-one sects, the Christians into seventy-two, and my nation will split into seventy-three sects, all of them in the Fire except one.“ They asked, “Who are they, O Messenger of Allah?“ He said: “Those who are upon what I and my Companions are upon today” (Sunan al-Tirmidhi 2641).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color.opacity(0.85))

                    Text("The defining measure in this hadith is not a name or a label, but a **standard**: what the Prophet (peace be upon him) and his Companions were upon. Ahl as-Sunnah wal-Jama‘ah is simply the name for those who hold to that standard.")
                        .font(.body)

                    Text("He (peace be upon him) also said: “Hold fast to my Sunnah and the Sunnah of the rightly guided caliphs after me. Cling to it with your molar teeth, and beware of newly invented matters, for every innovation is misguidance” (Sunan Abi Dawud 4607).")
                        .font(.body)
                }

                Section(header: Text("UNITY, NOT SECTARIANISM")) {
                    Text("Allah (Glorified and Exalted be He) commands unity upon the truth:")
                        .font(.body)

                    ScriptureQuote(text: "“And hold firmly to the rope of Allah all together and do not become divided” (Quran 3:103).")

                    ScriptureQuote(text: "“Indeed, those who have divided their religion and become sects - you are not associated with them in anything” (Quran 6:159).")

                    Text("Ahl as-Sunnah wal-Jama‘ah is therefore not a sect among sects. It is the original, undivided Islam of the Prophet (peace be upon him) and his Companions. Its adherents differ in fiqh across the four madhahib, yet stand united in creed.")
                        .font(.body)

                    Text("They are known for mercy toward the believers, honesty toward opponents, obedience to Muslim authority in what is good, and refusal to declare the general body of Muslims outside of Islam.")
                        .font(.body)
                }

                Section(header: Text("CONCLUSION")) {
                    Text("To be from Ahl as-Sunnah wal-Jama‘ah is to take the Quran and the authentic Sunnah as they came, to understand them as the Companions understood them, to love the Prophet’s family and his Companions together, and to hold to the community of the Muslims.")
                        .font(.body)

                    ScriptureQuote(text: "“So if they believe in the same as you believe in, then they have been rightly guided” (Quran 2:137).")
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Not a sect but the original, undivided Islam - taking the Quran and Sunnah as the Companions did, and loving the Prophet's family and Companions together.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Ahl As-Sunnah")
        .applyConditionalListStyle()
    }
}

struct SeerahView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: the Seerah is the life story of Prophet Muhammad - his character, mission, and example - drawn from the Quran and authentic reports.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("The **Seerah (سِيرَة)** is the biography of the Prophet Muhammad (peace be upon him): the account of his life, character, and mission, drawn from the Quran and authentic reports.")
                        .font(.body)

                    Text("Studying it is not merely history - it shows how revelation was lived, and it is a means of knowing, loving, and following him.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) says: “There has certainly been for you in the Messenger of Allah an excellent pattern for anyone whose hope is in Allah and the Last Day and [who] remembers Allah often” (Quran 33:21).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color)
                }

                Section(header: Text("BEFORE PROPHETHOOD")) {
                    Text("He was born in the year 570 CE in **Makkah (مَكَّة)**, among the tribe of Quraysh. His father Abdullah died before his birth and his mother Aminah when he was six, so he was raised by his grandfather Abd al-Muttalib and then his uncle Abu Talib.")
                        .font(.body)

                    Text("Even before revelation his people called him **Al-Amin (الأَمِين)**, “the Trustworthy,” for his honesty and noble character. At about twenty-five he married **Khadijah (خَدِيجَة)** (may Allah be pleased with her).")
                        .font(.body)
                }

                Section(header: Text("THE FIRST REVELATION")) {
                    Text("At the age of forty, while worshipping alone in the cave of **Hira (حِرَاء)** near Makkah, the angel **Jibril (جِبرِيل)** brought him the first revelation: “**Iqra (اِقرَأ)**” - “Read in the name of your Lord who created” (Quran 96:1).")
                        .font(.body)

                    Text("This began twenty-three years of the revelation of the Quran, which continued until shortly before his death.")
                        .font(.body)
                }

                Section(header: Text("THE MAKKAN PERIOD")) {
                    Text("For about thirteen years in Makkah he called people to **Tawhid (تَوحِيد)** - the worship of Allah alone - through his **Dawah (دَعوَة)**, his call to Islam. He and the early believers met mockery, boycott, and severe persecution, yet remained patient.")
                        .font(.body)

                    Text("In this period he was honoured with the **Isra and Mi'raj (الإِسرَاء وَالمِعرَاج)**, the night journey to Jerusalem and the ascension through the heavens, during which the five daily prayers were made obligatory.")
                        .font(.body)
                }

                Section(header: Text("THE HIJRAH")) {
                    Text("In 622 CE, by Allah’s command, the Prophet (peace be upon him) made the **Hijrah (هِجرَة)** - the migration from Makkah to **Madinah (المَدِينَة)**. This event was so pivotal that the Islamic (Hijri) calendar begins from it.")
                        .font(.body)
                }

                Section(header: Text("THE MADINAN PERIOD")) {
                    Text("In Madinah he established the first Muslim community: building the mosque, joining the emigrants (Muhajirun) and the helpers (Ansar) in brotherhood, and governing by revelation.")
                        .font(.body)

                    Text("The community was tested and defended in major events such as **Badr (بَدر)**, **Uhud (أُحُد)**, and the Battle of the Trench, **Al-Khandaq (الخَندَق)**. The **Treaty of Hudaybiyyah (الحُدَيبِيَة)** opened the way for peace, and in 630 CE Makkah was entered peacefully and cleansed of idols.")
                        .font(.body)
                }

                Section(header: Text("THE FAREWELL AND HIS PASSING")) {
                    Text("In 10 AH he performed the Farewell Pilgrimage, **Hajjat al-Wada (حَجَّة الوَدَاع)**, and delivered his Farewell Sermon before a great gathering of believers.")
                        .font(.body)

                    Text("He passed away in Madinah in 11 AH / 632 CE, at the age of sixty-three, and is buried there. He left behind the Quran and his Sunnah as guidance for all who came after.")
                        .font(.body)
                }

                Section(header: Text("HIS CHARACTER")) {
                    Text("He was sent as a mercy to all creation, **Rahmatan lil-Alamin (رَحمَة لِلعَالَمِين)**.")
                        .font(.body)

                    ScriptureQuote(text: "“And We have not sent you except as a mercy to the worlds” (Quran 21:107).")

                    Text("When Aishah (may Allah be pleased with her) was asked about his character, she said that his character was the Quran - he embodied its teachings in the most complete way.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Studying the Seerah shows how revelation was lived and deepens a Muslim's love and following of the Prophet, the best example for all people.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Seerah")
        .applyConditionalListStyle()
    }
}

struct TafsirView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: Tafsir is the explanation of the Quran's meanings - soundest when the Quran is explained by the Quran, the Sunnah, and the understanding of the early generations.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("**Tafsir (تَفسِير)** is the explanation and clarification of the meanings of the Quran: its words, rulings, and wisdoms. Its scholar is called a **Mufassir (مُفَسِّر)**.")
                        .font(.body)

                    Text("Its blameworthy counterpart is **Tafsir bir-Ra'y (تَفسِير بِالرَّأي)** in the censured sense - interpreting the Quran by mere opinion, away from its established meaning and the understanding of the Salaf.")
                        .font(.body)

                    Text("Allah (Glorified and Exalted be He) says: “This is a blessed Book which We have revealed to you that they might reflect upon its verses” (Quran 38:29).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color)
                }

                Section(header: Text("HOW THE QURAN IS EXPLAINED")) {
                    Text("The soundest tafsir is **bil-ma'thur (بِالمَأثُور)**, by transmission, and it proceeds in order:")
                        .font(.body)

                    Text("**1. The Quran by the Quran** - a matter left general in one place is often clarified in another.")
                        .font(.body)

                    Text("**2. The Quran by the Sunnah** - the Prophet (peace be upon him) explained what was revealed to him. “And We revealed to you the message that you may make clear to the people what was sent down to them” (Quran 16:44).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color)

                    Text("**3. The statements of the Companions (Sahabah)** - they witnessed the revelation and knew its context best.")
                        .font(.body)

                    Text("**4. The statements of the Successors (Tabi'un)** - the students of the Companions, followed by explanation through the Arabic language.")
                        .font(.body)
                }

                Section(header: Text("KEY TERMS")) {
                    Text("**Asbab al-Nuzul (أَسبَاب النُّزُول)** - the reasons or occasions of revelation, i.e. the events a verse was revealed about.")
                        .font(.body)

                    Text("**Muhkam (مُحكَم)** - verses clear and decisive in meaning; **Mutashabih (مُتَشَابِه)** - verses whose full meaning is not entirely apparent, referred back to the clear ones.")
                        .font(.body)

                    Text("**An-Nasikh wal-Mansukh (النَّاسِخ وَالمَنسُوخ)** - the abrogating and abrogated; a later ruling that replaces an earlier one within the revelation.")
                        .font(.body)
                }

                Section(header: Text("CONDITIONS OF THE MUFASSIR")) {
                    Text("Explaining the Quran is not by desire or guesswork. It requires sound belief, knowledge of the Arabic language, the Sunnah, the sayings of the early scholars, and the sciences of the Quran.")
                        .font(.body)

                    Text("The Prophet (peace be upon him) warned: “Whoever speaks about the Quran without knowledge, let him take his seat in the Fire” (Sunan al-Tirmidhi 2950).")
                        .font(.title3)
                        .foregroundColor(settings.accentColor.color.opacity(0.85))
                }

                Section(header: Text("WELL-KNOWN WORKS")) {
                    Text("Among the most trusted classical works of tafsir are those of **al-Tabari (الطَّبَرِي)**, **Ibn Kathir (اِبن كَثِير)**, and **al-Baghawi (البَغَوِي)**, and among later concise works, that of **al-Sa'di (السَّعدِي)**. They are prized for explaining the Quran by the Quran, the Sunnah, and the understanding of the early generations.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("True Tafsir rests on knowledge, not opinion; through it the guidance of the Quran becomes clear and livable for every generation.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Tafsir")
        .applyConditionalListStyle()
    }
}

struct FiqhAqeedahManhajView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: aqeedah is what you believe, fiqh is what you do, and manhaj is how you understand and derive both from revelation.")
                        .font(.body)
                }

                Section(header: Text("OVERVIEW")) {
                    Text("Three words describe how a Muslim believes, acts, and understands the religion: **Aqeedah (عَقِيدَة)**, **Fiqh (فِقه)**, and **Manhaj (مَنهَج)**.")
                        .font(.body)

                    Text("In short: aqeedah is what you believe, fiqh is what you do, and manhaj is how you understand and derive both.")
                        .font(.body)
                }

                Section(header: Text("AQEEDAH (BELIEF)")) {
                    Text("**Aqeedah (عَقِيدَة)** is creed - the beliefs the heart is bound to with certainty. Its core is **Tawhid (تَوحِيد)**, singling out Allah alone in worship, lordship, and His names and attributes.")
                        .font(.body)

                    Text("It includes the six pillars of faith: belief in Allah, His angels, His books, His messengers, the Last Day, and **Al-Qadar (القَدَر)**, the divine decree. Aqeedah does not change with time or place and is one for all the believers.")
                        .font(.body)

                    ScriptureQuote(text: "“The Messenger has believed in what was revealed to him from his Lord, and so have the believers. All of them have believed in Allah and His angels and His books and His messengers” (Quran 2:285).")
                }

                Section(header: Text("FIQH (JURISPRUDENCE)")) {
                    Text("**Fiqh (فِقه)** is the understanding of the practical rulings of Islam derived from the Quran and Sunnah - the “how“ of worship, **Ibadah (عِبَادَة)**, and of dealings, **Muamalat (مُعَامَلَات)**, such as prayer, fasting, trade, and marriage.")
                        .font(.body)

                    Text("Because deriving detailed rulings involves **Ijtihad (اِجتِهَاد)**, qualified scholarly effort, sincere scholars sometimes differ. This is the source of the accepted schools of fiqh, and such differences are a mercy, not division in the religion.")
                        .font(.body)
                }

                Section(header: Text("MANHAJ (METHODOLOGY)")) {
                    Text("**Manhaj (مَنهَج)** is methodology - the path by which one understands, prioritizes, and applies the religion, and deals with knowledge and people.")
                        .font(.body)

                    Text("The sound manhaj is to take the Quran and the authentic Sunnah upon the understanding of the **Salaf (السَّلَف)**, the first righteous generations, rather than by later opinions that contradict them.")
                        .font(.body)

                    ScriptureQuote(text: "“And the first forerunners among the Muhajireen and the Ansar and those who followed them with good conduct - Allah is pleased with them and they are pleased with Him” (Quran 9:100).")
                }

                Section(header: Text("HOW THEY RELATE")) {
                    Text("Aqeedah is the foundation, fiqh is the practice built upon it, and manhaj is the method that keeps both tied to revelation as it was first understood.")
                        .font(.body)

                    Text("The believers may differ in points of fiqh while remaining one in aqeedah and united upon a sound manhaj.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("United in creed, allowing valid differences in jurisprudence, and following the method of the first generations - this is the balance a Muslim strives for.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Fiqh, Aqeedah, Manhaj")
        .applyConditionalListStyle()
    }
}

#Preview {
    AlIslamPreviewContainer {
        PillarsView()
    }
}
