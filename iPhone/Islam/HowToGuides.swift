import SwiftUI

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
            Text("Every ruling above traces back to the Quran and the authentic Sunnah. These links open the sources themselves. Read them, and ask a qualified scholar about anything specific to your situation.")
        }
    }
}

struct HowToPrayView: View {
    @ObservedObject var settings = Settings.shared

    var body: some View {
        List {
            Group {
                Section(header: Text("SUMMARY")) {
                    Text("In short: prayer (**Salah, صَلَاة**) is performed facing the Qibla after purifying yourself, moving through standing, bowing, and prostrating while reciting the Quran and remembering Allah, praying as the Prophet (peace and blessings be upon him) prayed.")
                        .font(.body)
                }

                Section(header: Text("BEFORE YOU PRAY")) {
                    Text("1. **Purity (Taharah, طَهَارَة)**: have valid **Wudhu (وُضُوء)**, or Ghusl if required, with a clean body, clothes, and place of prayer.").font(.body)
                    Text("2. **Cover the Awrah (عَورَة)**: men from the navel to the knee at least; women cover everything except the face and hands.").font(.body)
                    Text("3. **Face the Qibla (قِبلَة)**: the direction of the Kaaba in Makkah.").font(.body)
                    Text("4. **Correct time**: each prayer has its own window: Fajr, Dhuhr, Asr, Maghrib, and Isha.").font(.body)
                    Text("5. **Intention (Niyyah, نِيَّة)**: intend the specific prayer in the heart; it is not spoken aloud.").font(.body)
                }

                Section(header: Text("NUMBER OF UNITS (RAKAH)")) {
                    Text("The obligatory **rak'ah (رَكعَة)** are: **Fajr** 2 · **Dhuhr** 4 · **Asr** 4 · **Maghrib** 3 · **Isha** 4.")
                        .font(.body)
                }

                Section(header: Text("STEP BY STEP")) {
                    Text("The Prophet (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“Pray as you have seen me praying” (Sahih al-Bukhari 631).", dimmed: true)
                    Text("1. **Takbir (تَكبِير)**: raise the hands and say “Allahu Akbar,” then place the right hand over the left upon the chest.").font(.body)
                    Text("2. **Recitation**: say the opening supplication, then recite Surah **Al-Fatiha (الفَاتِحَة)**, required in every rak'ah, followed by another passage of the Quran in the first two rak'ah.").font(.body)
                    Text("3. **Ruku (رُكُوع)**: bow with a straight back, hands on the knees, saying “Subhana Rabbi al-Adheem” three times.").font(.body)
                    Text("4. **Rising (I'tidal)**: rise saying “Sami'a Allahu liman hamidah,” then, standing, “Rabbana wa laka al-hamd.”").font(.body)
                    Text("5. **Sujud (سُجُود)**: prostrate on seven parts (the forehead and nose, both palms, both knees, and the toes), saying “Subhana Rabbi al-A'la” three times.").font(.body)
                    Text("6. **Sit** and say “Rabbi ighfir li,” then make a second **Sujud** the same way. This completes one rak'ah; stand for the next.").font(.body)
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
                    Text("Purify yourself, face the Qibla, and pray with presence of heart (Takbir, Fatiha, Ruku, Sujud, Tashahhud, and Taslim), exactly as the Prophet (peace and blessings be upon him) taught.")
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
                    Text("In short: to fast (**Sawm, صَوم**) is to abstain from food, drink, and intimacy from dawn (**Fajr**) to sunset (**Maghrib**) with the intention of seeking Allah's pleasure, especially in Ramadan.")
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
                    Text("Break the fast (**Iftar, إِفطَار**) as soon as the sun sets, hastening it as the Sunnah, traditionally with fresh or dried dates and water, then supplicate, for the fasting person's dua at Iftar is answered.")
                        .font(.body)
                }

                Section(header: Text("WHAT INVALIDATES THE FAST")) {
                    Text("Deliberately eating or drinking, intentional intimacy, and the onset of menstruation or postpartum bleeding break the fast. Eating or drinking by genuine forgetfulness does not; one simply continues fasting.")
                        .font(.body)
                }

                Section(header: Text("WHO IS EXCUSED")) {
                    Text("The sick, travelers, pregnant and nursing women, and the elderly who cannot fast are excused; missed fasts are made up later, or a **Fidyah (فِديَة)** (feeding a needy person per day) is given by those unable to fast at all.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Intend the fast, take Suhoor, abstain from dawn to sunset while guarding your character, then hasten to break the fast at Maghrib, turning the whole day into worship and gratitude.")
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
                    Text("Zakah is due on a Muslim whose zakatable wealth reaches the **Nisab (نِصَاب)**, the minimum threshold (equal to about **85 grams of gold** or **595 grams of silver**), and has been held for one full lunar (Hijri) year (**Hawl, حَول**).")
                        .font(.body)
                }

                Section(header: Text("2. TOTAL YOUR ZAKATABLE WEALTH")) {
                    Text("Include cash and savings, gold and silver, money owed to you that you expect back, business merchandise, and investments held for gain. Personal items (your home, car, and everyday belongings) are not counted.")
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
                    Text("Once your wealth reaches the Nisab and a lunar year passes, give 2.5% of it to the deserving, purifying your wealth, helping the needy, and fulfilling a pillar of Islam.")
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
                    Text("In short: **Hajj (حَجّ)** is the pilgrimage to Makkah performed once in a lifetime by those able, over the days of **Dhul-Hijjah**: entering Ihram, standing at Arafah, and completing the rites the Prophet (peace and blessings be upon him) taught.")
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

                Section(header: Text("2. DAY 8: MINA")) {
                    Text("Travel to **Mina (مِنَى)** and pray Dhuhr, Asr, Maghrib, Isha, and Fajr there, each at its time (the four-unit prayers shortened to two).")
                        .font(.body)
                }

                Section(header: Text("3. DAY 9: ARAFAH")) {
                    Text("After sunrise proceed to **Arafah (عَرَفَة)** and stand there in supplication until sunset; this standing (**Wuquf**) is the essence of Hajj. Dhuhr and Asr are combined and shortened. The Prophet (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“Hajj is Arafah” (Sunan al-Tirmidhi 889).", dimmed: true)
                    Text("After sunset, move to **Muzdalifah (مُزدَلِفَة)**, combine Maghrib and Isha, rest for the night, and gather pebbles.").font(.body)
                }

                Section(header: Text("4. DAY 10: EID (YAWM AN-NAHR)")) {
                    Text("Stone the large pillar (**Jamrat al-Aqabah**) with seven pebbles, offer the sacrifice (**Hady/Qurbani, قُربَان**), shave or trim the hair, then perform **Tawaf al-Ifadah** around the Kaaba and **Sa'i (سَعي)** between Safa and Marwah. With this the pilgrim exits Ihram.")
                        .font(.body)
                }

                Section(header: Text("5. DAYS 11–13: TASHREEQ")) {
                    Text("Stay in Mina and stone the three pillars (**Jamarat**) each afternoon. A pilgrim may leave after the 12th if he departs before sunset, otherwise he completes the 13th.")
                        .font(.body)
                }

                Section(header: Text("6. FAREWELL TAWAF")) {
                    Text("Before leaving Makkah, perform the farewell circumambulation (**Tawaf al-Wada, طَوَاف الوَدَاع**) so the last act at the Sacred House is Tawaf.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Enter Ihram at the Miqat, stand at Arafah, spend the night at Muzdalifah, then on Eid stone, sacrifice, shave, and perform Tawaf and Sa'i, completing the days of Mina and a farewell Tawaf, returning cleansed of sin.")
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
                    Text("In short: **Umrah (عُمرَة)**, the “lesser pilgrimage,” which may be done at any time of year, is Ihram, Tawaf around the Kaaba, Sa'i between Safa and Marwah, and shaving or trimming the hair.")
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
                    Text("Walk seven times between the hills of **Safa (الصَّفَا)** and **Marwah (المَروَة)** (**Sa'i, سَعي**), starting at Safa and ending at Marwah, remembering Allah and supplicating, as **Hajar** (may Allah be pleased with her) once searched there for water.")
                        .font(.body)
                }

                Section(header: Text("4. SHAVE OR TRIM")) {
                    Text("Men shave the head (**Halq, حَلق**) or trim it; women trim a fingertip's length (**Taqsir, تَقصِير**). With this the Umrah is complete and the pilgrim leaves the state of Ihram.")
                        .font(.body)
                }

                Section(header: Text("IN SUMMARY")) {
                    Text("Enter Ihram at the Miqat, perform Tawaf around the Kaaba, make Sa'i between Safa and Marwah, and shave or trim, a complete Umrah that may be done any time of the year.")
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
