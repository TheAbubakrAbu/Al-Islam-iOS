import SwiftUI

struct GodPillarView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: the existence of God is the foundation of all meaning, morality, and purpose. Reason, evidence, and the natural disposition every person is born with all point to one Creator.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(verbatim: "The question of God's existence is the most important inquiry a person can make. It is the foundation of all meaning, morality, purpose, and accountability. If God exists, then life has objective direction and responsibility. If He does not, then everything (good and evil, justice and injustice, purpose and identity) becomes subjective and ultimately meaningless. Therefore, it is essential to examine this question through reason, evidence, and rational thought.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE DOMINO EFFECT FRAMEWORK")) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(verbatim: "The most honest way to approach truth is through a step-by-step method, what can be called the Domino Effect. Each answer leads logically to the next, and no step may be skipped:")
                            .font(.body)
                        Group {
                            Text(verbatim: "• Does a higher power exist at all: something beyond the universe that brought it into being? This comes first. To ask whether God exists is already to assume a great deal about what that power is like.")
                            Text(verbatim: "• If a higher power exists, is it intelligent, or is it blind and random? A random, unthinking cause cannot account for order, information, or purpose.")
                            Text(verbatim: "• If it is intelligent, is it powerful or weak? A weak cause cannot sustain a universe it did not have the power to make.")
                            Text(verbatim: "• An intelligent, powerful, necessary cause is what is meant by God. Only now is the word earned.")
                            Text(verbatim: "• If God exists, is He still involved with creation (theism), or did He create and withdraw (deism)?")
                            Text(verbatim: "• If He is involved, did He send revelation to guide humanity?")
                            Text(verbatim: "• If revelation exists, then one religion must be objectively true.")
                            Text(verbatim: "• If there is one true religion, is it monotheistic or polytheistic?")
                            Text(verbatim: "• If monotheistic, is it exclusive to a specific ethnicity, or universal for all people?")
                            Text(verbatim: "• If universal and monotheistic, the serious contenders are Islam and Christianity.")
                        }
                        .font(.body)
                    }
                }

                Section(header: ArticleHeader("CHRISTIANITY VS. ISLAM")) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(verbatim: "While Christianity asserts universality, it contains internal contradictions and historical issues:")
                            .font(.body)
                        Group {
                            Text(verbatim: "• The Trinity violates pure monotheism by making God three persons in one essence, an idea that even many Christian scholars admit is a mystery, not a rational doctrine.")
                            Text(verbatim: "• The Bible is not preserved in its original language or form. It is a compilation of human writings over centuries with known alterations.")
                            Text(verbatim: "• Christianity does not offer a consistent position on salvation, works, and belief.")
                        }
                        Text(verbatim: "Islam, on the other hand:")
                            .font(.body)
                        Group {
                            Text(articleMarkdown: "• Affirms absolute monotheism, **Tawhid (تَوحِيد)**, with no partners, no intermediaries, and no confusion.")
                            Text(verbatim: "• Preserves the Quran exactly as it was revealed: verbatim, letter for letter, sound for sound, in its original Arabic.")
                            Text(verbatim: "• Welcomes all of humanity, regardless of ethnicity, race, gender, or background.")
                            Text(verbatim: "• Is the only universal, unambiguous, monotheistic religion with an intellectually sound and preserved foundation.")
                        }
                    }
                }

                Section(header: ArticleHeader("THE COSMOLOGICAL ARGUMENT")) {
                    Text(verbatim: "Every effect has a cause. The universe began to exist, so it must have had a cause. Modern cosmology also points to a beginning, but where did the energy come from? What caused it to expand? Who set the laws of physics in motion? The Quran speaks of the heavens and the earth as once joined and then separated, and of a heaven that Allah continues to expand. The early commentators (Ibn Abbas, Mujahid, and Qatadah, as at-Tabari and Ibn Kathir record) read these verses in their own terms, and some contemporary scholars see in them an allusion to what cosmology later found. Either way, the verses point to a Creator who began the universe and sustains it:")
                        .font(.body)
                    ScriptureQuote(text: "“Have those who disbelieved not considered that the heavens and the earth were a joined entity, and We separated them and made from water every living thing? Then will they not believe?” (Quran 21:30)", arabic: "أَوَلَمۡ يَرَ ٱلَّذِينَ كَفَرُوٓاْ أَنَّ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضَ كَانَتَا رَتۡقٗا فَفَتَقۡنَٰهُمَاۖ وَجَعَلۡنَا مِنَ ٱلۡمَآءِ كُلَّ شَيۡءٍ حَيٍّۚ أَفَلَا يُؤۡمِنُونَ")
                    ScriptureQuote(text: "“And the heaven We constructed with strength, and indeed, We are its expander” (Quran 51:47).", arabic: "وَٱلسَّمَآءَ بَنَيۡنَٰهَا بِأَيۡيْدٖ وَإِنَّا لَمُوسِعُونَ")
                    Text(verbatim: "The existence of anything (matter, time, space) requires an uncaused, necessary being beyond the system: Allah (Glorified and Exalted be He).")
                        .font(.body)
                }

                Section(header: ArticleHeader("ABIOGENESIS: LIFE FROM NON-LIFE?")) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(verbatim: "Modern science teaches that the first life (a prokaryotic cell) emerged from non-living chemicals. But this raises serious questions:")
                            .font(.body)
                        Group {
                            Text(verbatim: "• How did non-living matter suddenly become alive?")
                            Text(verbatim: "• How did a cell, containing instructions (DNA), copy itself?")
                            Text(verbatim: "• DNA is a dense, coded information system: a single cell carries a precisely ordered set of instructions comparable to hundreds of megabytes of text. Where did this information come from?")
                        }
                        Text(verbatim: "Scientists admit: “We don’t know.” But nothing in our experience tells us that complex, coded systems arise without a mind. The most rational explanation is that life was created intentionally, not randomly.")
                            .font(.body)
                    }
                }

                Section(header: ArticleHeader("HUMAN INTELLIGENCE: BEYOND EVOLUTION")) {
                    Text(articleMarkdown: "Human beings are orders of magnitude more intelligent than any other creature. Humans build cities, fly planes, write poetry, and explore the universe. They possess self-awareness, language, morality, free will, and the capacity for worship. If evolution alone explains the human brain, why don't other species come close? Why the quantum leap in ability? Human exceptionalism points to a Creator who endowed humanity with reason, **Aql (عَقل)**, a faculty Allah (Glorified and Exalted be He) gave to humans (and to the jinn, who are likewise accountable) and not to the animals.")
                        .font(.body)
                    ScriptureQuote(text: "“We have certainly created man in the best of stature” (Quran 95:4).", arabic: "لَقَدۡ خَلَقۡنَا ٱلۡإِنسَٰنَ فِيٓ أَحۡسَنِ تَقۡوِيمٖ")
                }

                Section(header: ArticleHeader("THE FINE-TUNING OF THE UNIVERSE")) {
                    Text(verbatim: "Gravity, electromagnetism, the strong and weak nuclear forces: all must be precisely balanced. If any were off by even a tiny fraction, life could not exist. This is not randomness. It is deliberate fine-tuning. Even atheists like Stephen Hawking acknowledge this astonishing precision. The question is: Who fine-tuned it?")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE MORAL ARGUMENT")) {
                    Text(verbatim: "Every human being knows certain things are wrong: murder, rape, lying, oppression. But if humans are just chemical accidents, who decides what's right or wrong? Evolution can explain instincts, not moral obligations. The existence of objective morality points to a Moral Lawgiver, someone who defines justice, goodness, and evil: Allah (Glorified and Exalted be He).")
                        .font(.body)
                }

                Section(header: ArticleHeader("ARGUMENT FROM BEAUTY, ORDER, AND DESIGN")) {
                    Text(verbatim: "Look at the trees, stars, animals, oceans. Look at the symmetry of flowers and the precision of ecosystems. Human creation (skyscrapers, smartphones, aircraft) demonstrates purposeful design. Just as buildings imply builders, the cosmos implies a Creator.")
                        .font(.body)
                    ScriptureQuote(text: "“Or were they created by nothing, or were they the creators of themselves? Or did they create the heavens and the earth? Rather, they are not certain” (Quran 52:35-36).", arabic: "أَمۡ خُلِقُواْ مِنۡ غَيۡرِ شَيۡءٍ أَمۡ هُمُ ٱلۡخَٰلِقُونَ ۝ أَمۡ خَلَقُواْ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضَۚ بَل لَّا يُوقِنُونَ")
                }

                Section(header: ArticleHeader("WHAT MAKES A RELIGION TRUE?")) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(verbatim: "When choosing a religion, one must not follow emotions, culture, or dreams. The correct belief system should be based on logic, objective evidence, and sound reasoning.")
                            .font(.body)
                        Group {
                            Text(verbatim: "• Subjective experiences (such as dreams, visions, or personal feelings) may be meaningful, but they are not reliable indicators of truth.")
                            Text(verbatim: "• Anyone from any religion can claim such experiences.")
                            Text(verbatim: "• Truth must be verifiable, logical, and universally applicable.")
                        }
                        Text(verbatim: "Islam aligns with these criteria.")
                            .font(.body)
                    }
                    ScriptureQuote(text: "“Have you seen he who has taken as his god his [own] desire…?” (Quran 45:23)", arabic: "أَفَرَءَيۡتَ مَنِ ٱتَّخَذَ إِلَٰهَهُۥ هَوَىٰهُ")
                }

                Section(header: ArticleHeader("FINAL REFLECTION")) {
                    Text(articleMarkdown: "Belief in God is not blind faith; it is the most rational and coherent explanation for existence, morality, consciousness, and design. Every human is born upon the **Fitrah (فِطرَة)**, the natural disposition to believe in one Creator. However, ego, society, and culture often obscure this truth. Islam calls humanity back to this original clarity.")
                        .font(.body)
                    ScriptureQuote(text: "“And do not pursue that of which you have no knowledge. Indeed, the hearing, the sight and the heart - about all those [one] will be questioned” (Quran 17:36).", arabic: "وَلَا تَقۡفُ مَا لَيۡسَ لَكَ بِهِۦ عِلۡمٌۚ إِنَّ ٱلسَّمۡعَ وَٱلۡبَصَرَ وَٱلۡفُؤَادَ كُلُّ أُوْلَٰٓئِكَ كَانَ عَنۡهُ مَسۡـُٔولٗا")
                }

                Section(header: ArticleHeader("ADVICE TO THE SINCERE SEEKER")) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(verbatim: "Seek truth with sincerity. Study deeply. Question critically. Do not follow inherited beliefs without examination.")
                            .font(.body)
                        Group {

                            Text(verbatim: "• The Quran criticizes blind following of ancestors without knowledge (Quran 43:23).")
                            Text(verbatim: "• Instead, use the God-given faculty of reason (aql) and return to the Fitrah.")
                            Text(verbatim: "• Islam stands as the only worldview that fully harmonizes with reason, morality, and objective reality.")
                        }
                    }
                }


                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Belief in God is not blind faith but the most rational explanation for existence, morality, consciousness, and design. Islam simply calls humanity back to the pure monotheism the soul was created upon.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "GodPillarView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("Does God Exist?")
    }
}

struct IslamPillarView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Islam is the submission of the heart and life to Allah alone. It rests on five pillars of practice and six pillars of faith, and it is the one message of every prophet from Adam to Muhammad (peace be upon them).")
                        .font(.body)
                }


                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "**Islam (إِسلَام)** comes from the Arabic root **s-l-m (س ل م)**, meaning “submission,” “safety,” and “peace”: it is a complete way of life built on the worship of Allah (Glorified and Exalted be He) alone. The Quran, revealed to Prophet Muhammad (peace and blessings be upon him) over 23 years through the angel **Jibril (جِبرِيل)** (Gabriel), is the divine word of Allah: a comprehensive guide to belief, morality, and law.")
                        .font(.body)

                    Text(articleMarkdown: "The essence of Islam is **Tawhid (تَوحِيد)**, absolute monotheism: there is no deity worthy of worship except Allah. Allah says in the Quran:").font(.body)
                    ScriptureQuote(text: "“And your god is one God. There is no deity [worthy of worship] except Him, the Entirely Merciful, the Especially Merciful” (Quran 2:163).", arabic: "وَإِلَٰهُكُمۡ إِلَٰهٞ وَٰحِدٞۖ لَّآ إِلَٰهَ إِلَّا هُوَ ٱلرَّحۡمَٰنُ ٱلرَّحِيمُ")

                    Text(verbatim: "Prophet Muhammad (peace and blessings be upon him) is the final and last messenger of Allah, sent as a mercy to all of creation. Allah says in the Quran:").font(.body)
                    ScriptureQuote(text: "“And We have not sent you, [O Muhammad], except as a mercy to the worlds” (Quran 21:107).", arabic: "وَمَآ أَرۡسَلۡنَٰكَ إِلَّا رَحۡمَةٗ لِّلۡعَٰلَمِينَ")

                    Text(verbatim: "Islam has been the way of life for humanity since the creation of Adam (peace be upon him), who was the first prophet and the first Muslim. Every nation that correctly followed the teachings of its prophet was considered Muslim in submission to Allah (Glorified and Exalted be He). For example, the Israelites who followed Moses (peace be upon him) and the disciples who followed Jesus (peace be upon him) were considered Muslims of their time.")
                            .font(.body)
                }

                Section(header: ArticleHeader("THE FIVE PILLARS")) {
                    Text(verbatim: "Islam is built on five pillars, which are the fundamental acts of worship for every Muslim. The Prophet Muhammad (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“Verily, al-Islam is founded on five (pillars): testifying the fact that there is no god but Allah, establishment of prayer, payment of Zakat, fast of Ramadan and Pilgrimage to the House” (Sahih Muslim 16d).", arabic: "إِنَّ الإِسْلاَمَ بُنِيَ عَلَى خَمْسٍ شَهَادَةِ أَنْ لاَ إِلَهَ إِلاَّ اللَّهُ وَإِقَامِ الصَّلاَةِ وَإِيتَاءِ الزَّكَاةِ وَصِيَامِ رَمَضَانَ وَحَجِّ الْبَيْتِ", dimmed: true)

                    Text(verbatim: "The Five Pillars are:").font(.body)
                    Text(articleMarkdown: "1. **Shahadah (شَهَادَة)**, from the root **sh-h-d (ش ه د)**, to witness or testify: the testimony of faith, “There is no god but Allah, and Muhammad is His Messenger.” You are not reporting an opinion; you are bearing witness. It is the foundation of a Muslim's faith.")
                    Text(articleMarkdown: "2. **Salah (صَلَاة)**, from the root **s-l-w (ص ل و)**, to supplicate and to draw near: praying five times a day at prescribed times, a direct link between the believer and Allah.")
                    Text(articleMarkdown: "3. **Zakah (زَكَاة)**, from the root **z-k-w (ز ك و)**, to purify and to grow: giving a portion of wealth to the needy (typically 2.5% of yearly savings). The word carries both meanings at once: wealth is purified by giving it away, and it grows by being purified.")
                    Text(articleMarkdown: "4. **Sawm (صَوم)**, from the root **s-w-m (ص و م)**, to abstain or hold back: fasting the month of **Ramadan (رَمَضَان)**, abstaining from food, drink, and sinful behavior from dawn to sunset, as spiritual reflection and self-discipline.")
                    Text(articleMarkdown: "5. **Hajj (حَجّ)**, from the root **h-j-j (ح ج ج)**, to set out with purpose toward something: pilgrimage to Makkah, a once-in-a-lifetime obligation for those physically and financially able, symbolizing unity and submission to Allah.")
                }

                Section(header: ArticleHeader("THE SIX PILLARS OF IMAN")) {
                    Text(articleMarkdown: "The Six Pillars of **Iman (إِيمَان)**, from the root **a-m-n (أ م ن)**, meaning faith, trust, and security, are the core beliefs every Muslim must hold. These are based on the Quran and the teachings of Prophet Muhammad (peace and blessings be upon him). Allah says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“The Messenger has believed in what was revealed to him from his Lord, and [so have] the believers. All of them have believed in Allah and His angels and His books and His messengers, [saying], ‘We make no distinction between any of His messengers.’ And they say, ‘We hear and we obey. [We seek] Your forgiveness, our Lord, and to You is the [final] destination.’” (Quran 2:285)", arabic: "ءَامَنَ ٱلرَّسُولُ بِمَآ أُنزِلَ إِلَيۡهِ مِن رَّبِّهِۦ وَٱلۡمُؤۡمِنُونَۚ كُلٌّ ءَامَنَ بِٱللَّهِ وَمَلَٰٓئِكَتِهِۦ وَكُتُبِهِۦ وَرُسُلِهِۦ لَا نُفَرِّقُ بَيۡنَ أَحَدٖ مِّن رُّسُلِهِۦۚ وَقَالُواْ سَمِعۡنَا وَأَطَعۡنَاۖ غُفۡرَانَكَ رَبَّنَا وَإِلَيۡكَ ٱلۡمَصِيرُ")

                    Text(verbatim: "The Prophet Muhammad (peace and blessings be upon him) explained the pillars of Iman when he said:").font(.body)
                    ScriptureQuote(text: "“That you affirm your faith in Allah, in His angels, in His Books, in His Apostles, in the Day of Judgment, and you affirm your faith in the Divine Decree about good and evil” (Sahih Muslim 8a).", arabic: "أَنْ تُؤْمِنَ بِاللَّهِ وَمَلاَئِكَتِهِ وَكُتُبِهِ وَرُسُلِهِ وَالْيَوْمِ الآخِرِ وَتُؤْمِنَ بِالْقَدَرِ خَيْرِهِ وَشَرِّهِ", dimmed: true)

                    Text(verbatim: "The Six Pillars of Iman are:").font(.body)
                    Text(articleMarkdown: "1. **Belief in Allah**, **Tawhid (تَوحِيد)** from the root **w-h-d (و ح د)**, to make one: the oneness of Allah, who has no partners or equals.")
                    Text(articleMarkdown: "2. **Belief in the Angels**, **Malaikah (مَلَائِكَة)** from the root **l-a-k (ل أ ك)**, to send with a message: created beings of light who serve Allah and carry out His commands, such as Jibril (Gabriel).")
                    Text(articleMarkdown: "3. **Belief in the Books**, **Kutub (كُتُب)** from the root **k-t-b (ك ت ب)**, to write or prescribe: the divine scriptures revealed by Allah, including the Torah, Gospel, Psalms, and the Quran, which is the final and unaltered revelation.")
                    Text(articleMarkdown: "4. **Belief in the Messengers**, **Rusul (رُسُل)** from the root **r-s-l (ر س ل)**, to send: prophets sent to guide humanity, ending with Prophet Muhammad (peace and blessings be upon him).")
                    Text(articleMarkdown: "5. **Belief in the Last Day**, **Yawm al-Qiyamah (يَوم القِيَامَة)** from the root **q-w-m (ق و م)**, to stand: the Day of Judgment, when all people will stand before Allah and be held accountable for their deeds.")
                    Text(articleMarkdown: "6. **Belief in Divine Decree, Qadar (القَدَر)**, from the root **q-d-r (ق د ر)**, to measure out or determine: that everything, good and bad, happens by Allah’s will and wisdom, measured out precisely.")
                }

                Section(header: ArticleHeader("PROPHETHOOD")) {
                    Text(verbatim: "Allah sent prophets to every nation to guide them to worship Him alone. These prophets include Adam, Noah, Abraham, Moses, David, Solomon, Jesus, and many others (peace be upon them all). Allah says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“We make no distinction between any of His messengers” (Quran 2:285).", arabic: "لَا نُفَرِّقُ بَيۡنَ أَحَدٖ مِّن رُّسُلِهِۦۚ")

                    Text(verbatim: "However, all previous prophets were sent for their specific people and times. Prophet Muhammad (peace and blessings be upon him) is unique as the final and universal messenger, sent for all of humanity until the end of time. Allah says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“Muhammad is not the father of [any] one of your men, but [he is] the Messenger of Allah and last of the prophets. And ever is Allah, of all things, Knowing” (Quran 33:40).", arabic: "مَّا كَانَ مُحَمَّدٌ أَبَآ أَحَدٖ مِّن رِّجَالِكُمۡ وَلَٰكِن رَّسُولَ ٱللَّهِ وَخَاتَمَ ٱلنَّبِيِّـۧنَۗ وَكَانَ ٱللَّهُ بِكُلِّ شَيۡءٍ عَلِيمٗا")

                    Text(verbatim: "Regarding Prophet Abraham (peace be upon him), Allah clarifies in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“Abraham was neither a Jew nor a Christian, but he was one inclining toward truth, a Muslim [submitting to Allah]. And he was not of the polytheists” (Quran 3:67).", arabic: "مَا كَانَ إِبۡرَٰهِيمُ يَهُودِيّٗا وَلَا نَصۡرَانِيّٗا وَلَٰكِن كَانَ حَنِيفٗا مُّسۡلِمٗا وَمَا كَانَ مِنَ ٱلۡمُشۡرِكِينَ")
                }

                Section(header: ArticleHeader("PREVIOUS SCRIPTURES")) {
                    Text(verbatim: "Islam acknowledges earlier divine scriptures such as the Torah given to Moses (peace be upon him) and the Gospel given to Jesus (peace be upon him). However, these scriptures were altered over time, and the current versions of the Bible and Torah are not the original revelations. Allah says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“So woe to those who write the ‘scripture’ with their own hands, then say, ‘This is from Allah,’ in order to exchange it for a small price. Woe to them for what their hands have written and woe to them for what they earn” (Quran 2:79).", arabic: "فَوَيۡلٞ لِّلَّذِينَ يَكۡتُبُونَ ٱلۡكِتَٰبَ بِأَيۡدِيهِمۡ ثُمَّ يَقُولُونَ هَٰذَا مِنۡ عِندِ ٱللَّهِ لِيَشۡتَرُواْ بِهِۦ ثَمَنٗا قَلِيلٗاۖ فَوَيۡلٞ لَّهُم مِّمَّا كَتَبَتۡ أَيۡدِيهِمۡ وَوَيۡلٞ لَّهُم مِّمَّا يَكۡسِبُونَ")

                    Text(verbatim: "The Quran is the final, complete, and preserved revelation sent to all of mankind for all time. Allah says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“Indeed, it is We who sent down the Quran and indeed, We will be its guardian” (Quran 15:9).", arabic: "إِنَّا نَحۡنُ نَزَّلۡنَا ٱلذِّكۡرَ وَإِنَّا لَهُۥ لَحَٰفِظُونَ")

                    Text(verbatim: "Prophet Muhammad (peace and blessings be upon him) said about the Quran:").font(.body)
                    ScriptureQuote(text: "“The best among you (Muslims) are those who learn the Quran and teach it” (Sahih al-Bukhari 5027).", arabic: "خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ", dimmed: true)
                }

                Section(header: ArticleHeader("ISLAMIC VALUES")) {
                    Text(articleMarkdown: "Islam emphasizes high moral conduct, urging Muslims to embody honesty, justice, compassion, and humility. It teaches that good character and kindness towards others are integral to faith. The concept of the **Ummah (أُمَّة)**, the global Muslim community, fosters unity among believers regardless of ethnicity or background.")
                        .font(.body)

                    Text(verbatim: "Allah commands Muslims to act justly and to do good:").font(.body)
                    ScriptureQuote(text: "“Indeed, Allah orders justice and good conduct and giving to relatives and forbids immorality and bad conduct and oppression. He admonishes you that perhaps you will be reminded” (Quran 16:90).", arabic: "إِنَّ ٱللَّهَ يَأۡمُرُ بِٱلۡعَدۡلِ وَٱلۡإِحۡسَٰنِ وَإِيتَآيِٕ ذِي ٱلۡقُرۡبَىٰ وَيَنۡهَىٰ عَنِ ٱلۡفَحۡشَآءِ وَٱلۡمُنكَرِ وَٱلۡبَغۡيِۚ يَعِظُكُمۡ لَعَلَّكُمۡ تَذَكَّرُونَ")

                    Text(verbatim: "True righteousness is not limited to mere belief or rituals but includes good deeds and moral conduct. Allah says in the Quran:").font(.body)
                    ScriptureQuote(text: "“Righteousness is not that you turn your faces toward the east or the west, but [true] righteousness is [in] one who believes in Allah, the Last Day, the angels, the Book, and the prophets and gives wealth, in spite of love for it, to relatives, orphans, the needy, the traveler, those who ask [for help], and for freeing slaves; [and who] establishes prayer and gives zakah; [those who] fulfill their promise when they promise; and [those who] are patient in poverty and hardship and during battle. Those are the ones who have been true, and it is those who are the righteous” (Quran 2:177).", arabic: "لَّيۡسَ ٱلۡبِرَّ أَن تُوَلُّواْ وُجُوهَكُمۡ قِبَلَ ٱلۡمَشۡرِقِ وَٱلۡمَغۡرِبِ وَلَٰكِنَّ ٱلۡبِرَّ مَنۡ ءَامَنَ بِٱللَّهِ وَٱلۡيَوۡمِ ٱلۡأٓخِرِ وَٱلۡمَلَٰٓئِكَةِ وَٱلۡكِتَٰبِ وَٱلنَّبِيِّـۧنَ وَءَاتَى ٱلۡمَالَ عَلَىٰ حُبِّهِۦ ذَوِي ٱلۡقُرۡبَىٰ وَٱلۡيَتَٰمَىٰ وَٱلۡمَسَٰكِينَ وَٱبۡنَ ٱلسَّبِيلِ وَٱلسَّآئِلِينَ وَفِي ٱلرِّقَابِ وَأَقَامَ ٱلصَّلَوٰةَ وَءَاتَى ٱلزَّكَوٰةَ وَٱلۡمُوفُونَ بِعَهۡدِهِمۡ إِذَا عَٰهَدُواْۖ وَٱلصَّٰبِرِينَ فِي ٱلۡبَأۡسَآءِ وَٱلضَّرَّآءِ وَحِينَ ٱلۡبَأۡسِۗ أُوْلَٰٓئِكَ ٱلَّذِينَ صَدَقُواْۖ وَأُوْلَٰٓئِكَ هُمُ ٱلۡمُتَّقُونَ")

                    Text(verbatim: "The Prophet Muhammad (peace and blessings be upon him) highlighted the importance of good manners and character. He said:").font(.body)
                    ScriptureQuote(text: "“The best among you are those who have the best manners and character” (Sahih al-Bukhari 6029)", arabic: "إِنَّ مِنْ أَخْيَرِكُمْ أَحْسَنَكُمْ خُلُقًا", dimmed: true)

                    Text(verbatim: "He also said:").font(.body)
                    ScriptureQuote(text: "“The most beloved of people to Allah are those most beneficial to people, and the most beloved of deeds to Allah is joy you bring to a Muslim, or a hardship you remove from him, or a debt you pay off for him, or hunger you drive away from him” (al-Mu'jam al-Awsat of at-Tabarani 6026; graded hasan by al-Albani, as-Silsilah as-Sahihah 906).", arabic: "أَحَبُّ النَّاسِ إِلَى اللَّهِ أَنْفَعُهُمْ لِلنَّاسِ، وَأَحَبُّ الْأَعْمَالِ إِلَى اللَّهِ سُرُورٌ تُدْخِلُهُ عَلَى مُسْلِمٍ، أَوْ تَكْشِفُ عَنْهُ كُرْبَةً، أَوْ تَقْضِي عَنْهُ دَيْنًا، أَوْ تَطْرُدُ عَنْهُ جُوعًا", dimmed: true)

                    Text(verbatim: "These teachings show that Islam is not only about fulfilling religious obligations but also about treating others with respect, kindness, and fairness. Upholding good character is considered a sign of true faith and devotion to Allah (Glorified and Exalted be He).")
                        .font(.body)
                }


                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Islam is a complete way of life that joins correct belief, sincere worship, and excellent character. It is Allah's final guidance and a mercy for all people until the end of time.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "IslamPillarView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("What is Islam?")
    }
}

struct MuslimPillarView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: a Muslim is one who submits to Allah alone, following the Quran and the Sunnah of Prophet Muhammad (peace and blessings be upon him) as understood by his Companions, his family, and the first righteous generations.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "A **Muslim (مُسلِم)** is “one who submits.” The word shares the root **s-l-m (س ل م)** with **Islam (إِسلَام)**, a root carrying the meanings of submission, safety, and peace. A Muslim is therefore someone who surrenders to Allah rather than to his own desires or the passing things of this world, turning instead to the One who created him and knows him best.")
                        .font(.body)
                }

                Section(header: ArticleHeader("ALLAH KNOWS US BEST")) {
                    Text(verbatim: "Before He calls us to worship Him, Allah reminds us that He created us, knows us completely, and is nearer to us than we imagine:")
                        .font(.body)
                    ScriptureQuote(text: "“And We have already created man and know what his soul whispers to him, and We are closer to him than his jugular vein” (Quran 50:16).", arabic: "وَلَقَدۡ خَلَقۡنَا ٱلۡإِنسَٰنَ وَنَعۡلَمُ مَا تُوَسۡوِسُ بِهِۦ نَفۡسُهُۥۖ وَنَحۡنُ أَقۡرَبُ إِلَيۡهِ مِنۡ حَبۡلِ ٱلۡوَرِيدِ")
                    Text(verbatim: "Submission, then, is not to a stranger; it is to the Lord who made us and knows us better than we know ourselves.")
                        .font(.body)
                }

                Section(header: ArticleHeader("SUBMISSION TO ALLAH ALONE")) {
                    Text(verbatim: "To be a Muslim is to answer Allah's call as Ibrahim (Abraham, peace be upon him) did:")
                        .font(.body)
                    ScriptureQuote(text: "“When his Lord said to him, ‘Submit,’ he said, ‘I have submitted [in Islam] to the Lord of the worlds’” (Quran 2:131).", arabic: "إِذۡ قَالَ لَهُۥ رَبُّهُۥٓ أَسۡلِمۡۖ قَالَ أَسۡلَمۡتُ لِرَبِّ ٱلۡعَٰلَمِينَ")
                    Text(verbatim: "Ibrahim was neither a Jew nor a Christian, but a Muslim in the truest sense, devoted to the worship of the one God:")
                        .font(.body)
                    ScriptureQuote(text: "“Abraham was neither a Jew nor a Christian, but he was one inclining toward truth, a Muslim [submitting to Allah]. And he was not of the polytheists” (Quran 3:67).", arabic: "مَا كَانَ إِبۡرَٰهِيمُ يَهُودِيّٗا وَلَا نَصۡرَانِيّٗا وَلَٰكِن كَانَ حَنِيفٗا مُّسۡلِمٗا وَمَا كَانَ مِنَ ٱلۡمُشۡرِكِينَ")
                }

                Section(header: ArticleHeader("FOLLOWING THE QURAN AND SUNNAH")) {
                    Text(articleMarkdown: "A Muslim follows the **Quran (قُرءان)**, the word of Allah, and the guidance of His Messenger Muhammad (peace and blessings be upon him), preserved in his **Sunnah (سُنَّة)** through authentic **Hadith (حَدِيث)**. Love of Allah is shown by following His Messenger:")
                        .font(.body)
                    ScriptureQuote(text: "“Say, [O Muhammad], ‘If you should love Allah, then follow me, [so] Allah will love you and forgive you your sins’” (Quran 3:31).", arabic: "قُلۡ إِن كُنتُمۡ تُحِبُّونَ ٱللَّهَ فَٱتَّبِعُونِي يُحۡبِبۡكُمُ ٱللَّهُ وَيَغۡفِرۡ لَكُمۡ ذُنُوبَكُمۡۚ")
                }

                Section(header: ArticleHeader("AS THE FIRST GENERATIONS UNDERSTOOD IT")) {
                    Text(articleMarkdown: "The Quran and Sunnah are understood as the first believers understood them: the Companions, **the Sahabah (صَحَابَة)**; the Prophet's household, **the Ahl al-Bayt (أَهل البَيت)**, which includes his wives; and the righteous first three generations, **the Salaf (السَّلَف)**.")
                        .font(.body)
                    ScriptureQuote(text: "“And the first forerunners [in the faith] among the Muhajireen and the Ansar and those who followed them with good conduct - Allah is pleased with them and they are pleased with Him” (Quran 9:100).", arabic: "وَٱلسَّٰبِقُونَ ٱلۡأَوَّلُونَ مِنَ ٱلۡمُهَٰجِرِينَ وَٱلۡأَنصَارِ وَٱلَّذِينَ ٱتَّبَعُوهُم بِإِحۡسَٰنٖ رَّضِيَ ٱللَّهُ عَنۡهُمۡ وَرَضُواْ عَنۡهُ")
                }

                Section(header: ArticleHeader("WHAT IS A MU'MIN (BELIEVER)?")) {
                    Text(articleMarkdown: "A **Mu'min (مُؤمِن)**, a true believer, is one whose faith lives in the heart and shows in action. Allah describes them:")
                        .font(.body)
                    ScriptureQuote(text: "“The believers are only those who, when Allah is mentioned, their hearts become fearful, and when His verses are recited to them, it increases them in faith; and upon their Lord they rely” (Quran 8:2).", arabic: "إِنَّمَا ٱلۡمُؤۡمِنُونَ ٱلَّذِينَ إِذَا ذُكِرَ ٱللَّهُ وَجِلَتۡ قُلُوبُهُمۡ وَإِذَا تُلِيَتۡ عَلَيۡهِمۡ ءَايَٰتُهُۥ زَادَتۡهُمۡ إِيمَٰنٗا وَعَلَىٰ رَبِّهِمۡ يَتَوَكَّلُونَ")
                }

                Section(header: ArticleHeader("THE BELIEVERS ARE ONE")) {
                    Text(verbatim: "Muslims are a single brotherhood, united in faith across every race and land:")
                        .font(.body)
                    ScriptureQuote(text: "“The believers are but brothers, so make settlement between your brothers. And fear Allah that you may receive mercy” (Quran 49:10).", arabic: "إِنَّمَا ٱلۡمُؤۡمِنُونَ إِخۡوَةٞ فَأَصۡلِحُواْ بَيۡنَ أَخَوَيۡكُمۡۚ وَٱتَّقُواْ ٱللَّهَ لَعَلَّكُمۡ تُرۡحَمُونَ")
                    Text(verbatim: "The Prophet (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“The similitude of believers in regard to mutual love, affection, fellow-feeling is that of one body; when any limb of it aches, the whole body aches, because of sleeplessness and fever” (Sahih Muslim 2586).", arabic: "مَثَلُ الْمُؤْمِنِينَ فِي تَوَادِّهِمْ وَتَرَاحُمِهِمْ وَتَعَاطُفِهِمْ مَثَلُ الْجَسَدِ إِذَا اشْتَكَى مِنْهُ عُضْوٌ تَدَاعَى لَهُ سَائِرُ الْجَسَدِ بِالسَّهَرِ وَالْحُمَّى", dimmed: true)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "A Muslim submits to Allah alone, the One who created and knows us best, by holding to the Quran and the Sunnah upon the understanding of the Companions, the Prophet's family, and the Salaf, joined with all the believers as one brotherhood.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "MuslimPillarView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("What is a Muslim?")
    }
}

struct AllahPillarView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Allah is the one true God: the sole Creator and Sustainer of all that exists, without partner or equal, known by His Most Beautiful Names and perfect attributes.")
                        .font(.body)
                }


                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "**Allah (اللَّه)** is the name of the one true God. It comes from **Al-Ilah (الإِلَٰه)**, “The God.” In Islam He (Glorified and Exalted be He) is the unique Creator, Sustainer, and Maintainer of all that exists, without partner, associate, or equal, and absolutely One.")
                        .font(.body)

                    Text(articleMarkdown: "Allah has the Most Beautiful Names, **Al-Asma al-Husna (الأَسمَاء الحُسنَى)**, such as the Most Gracious, the Most Merciful, the All-Knowing, and the King. They describe His perfect qualities, and He is far above any need, limitation, or resemblance to His creation. Allah says:")
                        .font(.body)
                    ScriptureQuote(text: "“And to Allah belong the best names, so invoke Him by them. And leave [the company of] those who practice deviation concerning His names. They will be recompensed for what they have been doing” (Quran 7:180).", arabic: "وَلِلَّهِ ٱلۡأَسۡمَآءُ ٱلۡحُسۡنَىٰ فَٱدۡعُوهُ بِهَاۖ وَذَرُواْ ٱلَّذِينَ يُلۡحِدُونَ فِيٓ أَسۡمَٰٓئِهِۦۚ سَيُجۡزَوۡنَ مَا كَانُواْ يَعۡمَلُونَ")

                    Text(verbatim: "The Prophet (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“Allah has ninety-nine names, i.e. one-hundred minus one, and whoever knows them will go to Paradise” (Sahih al-Bukhari 2736, Sahih Muslim 2677).", arabic: "إِنَّ لِلَّهِ تِسْعَةً وَتِسْعِينَ اسْمَا مِائَةً إِلاَّ وَاحِدًا مَنْ أَحْصَاهَا دَخَلَ الْجَنَّةَ", dimmed: true)

                    Text(verbatim: "Ahl as-Sunnah affirm these Names and Attributes exactly as Allah and His Messenger affirmed them: without denying their meanings, without asking how, and without likening Him to His creation. Allah says: “There is nothing like unto Him, and He is the Hearing, the Seeing” (Quran 42:11).")
                        .font(.body)
                }

                Section(header: ArticleHeader("ALLAH IN PRE-ISLAMIC TIMES")) {
                    Text(verbatim: "Before Islam, the Arabs acknowledged a supreme God named Allah but associated partners with Him by worshipping idols and other deities. When Prophet Muhammad (peace and blessings be upon him) brought Islam, he reaffirmed the Oneness of Allah, rejecting all forms of idolatry and polytheism. Allah says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“And they were not commanded except to worship Allah, [being] sincere to Him in religion, inclining to truth, and to establish prayer and to give zakah. And that is the correct religion” (Quran 98:5).", arabic: "وَمَآ أُمِرُوٓاْ إِلَّا لِيَعۡبُدُواْ ٱللَّهَ مُخۡلِصِينَ لَهُ ٱلدِّينَ حُنَفَآءَ وَيُقِيمُواْ ٱلصَّلَوٰةَ وَيُؤۡتُواْ ٱلزَّكَوٰةَۚ وَذَٰلِكَ دِينُ ٱلۡقَيِّمَةِ")
                }

                Section(header: ArticleHeader("QURANIC REFERENCES")) {
                    Text(verbatim: "Allah describes Himself in the Quran as the One and Only God, the source of all mercy and compassion. Allah says:")
                        .font(.body)
                    ScriptureQuote(text: "“And your god is one God. There is no deity [worthy of worship] except Him, the Entirely Merciful, the Especially Merciful” (Quran 2:163).", arabic: "وَإِلَٰهُكُمۡ إِلَٰهٞ وَٰحِدٞۖ لَّآ إِلَٰهَ إِلَّا هُوَ ٱلرَّحۡمَٰنُ ٱلرَّحِيمُ")

                    Text(verbatim: "He also says:").font(.body)
                    ScriptureQuote(text: "“There is nothing like unto Him, and He is the Hearing, the Seeing” (Quran 42:11).", arabic: "لَيۡسَ كَمِثۡلِهِۦ شَيۡءٞۖ وَهُوَ ٱلسَّمِيعُ ٱلۡبَصِيرُ")
                }

                Section(header: ArticleHeader("ESSENCE OF WORSHIP")) {
                    Text(verbatim: "The primary purpose of life is to worship Allah (Glorified and Exalted be He). This worship is not limited to rituals but encompasses every sincere action done to seek Allah's pleasure. Allah says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“And I did not create the jinn and mankind except to worship Me” (Quran 51:56).", arabic: "وَمَا خَلَقۡتُ ٱلۡجِنَّ وَٱلۡإِنسَ إِلَّا لِيَعۡبُدُونِ")

                    Text(verbatim: "Worshiping Allah includes prayer, supplication, charity, good conduct, and obedience to His commands as revealed in the Quran and the teachings of Prophet Muhammad (peace and blessings be upon him).").font(.body)

                    Text(verbatim: "This life is also a test from Allah to determine who among His servants will strive to fulfill their purpose with sincerity and patience. Allah says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“Indeed, We have made that which is on the earth adornment for it that We may test them [as to] which of them is best in deed” (Quran 18:7).", arabic: "إِنَّا جَعَلۡنَا مَا عَلَى ٱلۡأَرۡضِ زِينَةٗ لَّهَا لِنَبۡلُوَهُمۡ أَيُّهُمۡ أَحۡسَنُ عَمَلٗا")

                    Text(verbatim: "Allah further reminds us:").font(.body)
                    ScriptureQuote(text: "“And We test you with evil and with good as trial; and to Us you will be returned” (Quran 21:35).", arabic: "وَنَبۡلُوكُم بِٱلشَّرِّ وَٱلۡخَيۡرِ فِتۡنَةٗۖ وَإِلَيۡنَا تُرۡجَعُونَ")

                    Text(verbatim: "Through these tests, believers have the opportunity to demonstrate their devotion, patience, and trust in Allah. Success lies in worshiping Him sincerely and following the straight path outlined in the Quran and Sunnah.")
                        .font(.body)
                }

                Section(header: ArticleHeader("SURAH AL-IKHLAS")) {
                    ScriptureQuote(text: "“Say, ‘He is Allah, [who is] One, Allah, the Eternal Refuge. He neither begets nor is born, nor is there to Him any equivalent.’” (Quran 112:1-4)", arabic: "قُلۡ هُوَ ٱللَّهُ أَحَدٌ ۝ ٱللَّهُ ٱلصَّمَدُ ۝ لَمۡ يَلِدۡ وَلَمۡ يُولَدۡ ۝ وَلَمۡ يَكُن لَّهُۥ كُفُوًا أَحَدُۢ")

                    Text(articleMarkdown: "This short yet powerful chapter, **Surah Al-Ikhlas (الإِخلَاص)**, perfectly encapsulates the core of Islamic monotheism, affirming that Allah is eternal, without offspring or equal, and incomparable to any of His creation.")
                        .font(.body)
                }

                Section(header: ArticleHeader("AYAT AL-KURSI")) {
                    ScriptureQuote(text: "“Allah - there is no deity except Him, the Ever-Living, the Sustainer of [all] existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is [presently] before them and what will be after them, and they encompass not a thing of His knowledge except for what He wills. His Kursi extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High, the Most Great” (Quran 2:255)", arabic: "ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ ٱلۡحَيُّ ٱلۡقَيُّومُۚ لَا تَأۡخُذُهُۥ سِنَةٞ وَلَا نَوۡمٞۚ لَّهُۥ مَا فِي ٱلسَّمَٰوَٰتِ وَمَا فِي ٱلۡأَرۡضِۗ مَن ذَا ٱلَّذِي يَشۡفَعُ عِندَهُۥٓ إِلَّا بِإِذۡنِهِۦۚ يَعۡلَمُ مَا بَيۡنَ أَيۡدِيهِمۡ وَمَا خَلۡفَهُمۡۖ وَلَا يُحِيطُونَ بِشَيۡءٖ مِّنۡ عِلۡمِهِۦٓ إِلَّا بِمَا شَآءَۚ وَسِعَ كُرۡسِيُّهُ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضَۖ وَلَا يَـُٔودُهُۥ حِفۡظُهُمَاۚ وَهُوَ ٱلۡعَلِيُّ ٱلۡعَظِيمُ")

                    Text(articleMarkdown: "**Ayat al-Kursi (آيَة الكُرسِي)**, the Throne Verse, emphasizes Allah's supreme power, unmatched knowledge, and sovereignty over the universe. It is the greatest verse in the Quran, as the Prophet (peace and blessings be upon him) told Ubayy ibn Ka'b (Sahih Muslim 810), and the Prophet (peace and blessings be upon him) confirmed the words of the one who told Abu Hurayrah (may Allah be pleased with him):")
                        .font(.body)
                    ScriptureQuote(text: "“Whenever you go to bed, recite ‘Ayat-al-Kursi’-- 'Allahu la ilaha illa huwa-l-Haiy-ul Qaiyum' till you finish the whole verse. (If you do so), Allah will appoint a guard for you who will stay with you and no satan will come near you till morning” (Sahih al-Bukhari 2311).", arabic: "إِذَا أَوَيْتَ إِلَى فِرَاشِكَ فَاقْرَأْ آيَةَ الْكُرْسِيِّ اللَّهُ لاَ إِلَهَ إِلاَّ هُوَ الْحَىُّ الْقَيُّومُ حَتَّى تَخْتِمَ الآيَةَ، فَإِنَّكَ لَنْ يَزَالَ عَلَيْكَ مِنَ اللَّهِ حَافِظٌ وَلاَ يَقْرَبَنَّكَ شَيْطَانٌ حَتَّى تُصْبِحَ", dimmed: true)
                }


                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Allah is absolutely One and unlike anything in His creation. The whole purpose of life is to worship, obey, and come to know Him with sincerity.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "AllahPillarView")

                ArticleSourcesSection(article: "QuranPillarView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("Who is Allah?")
    }
}

struct QuranPillarView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: the Quran is the literal, final word of Allah, revealed to Prophet Muhammad (peace and blessings be upon him) over 23 years. It is miraculous in its language and perfectly preserved.")
                        .font(.body)
                }


                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "The **Quran (قُرءان)** takes its name from the Arabic root **q-r-a (ق ر أ)**, meaning “to read” or “to recite.” It is the holy book of Islam. It is the literal word of Allah (Glorified and Exalted be He), revealed to Prophet Muhammad (peace and blessings be upon him) through the angel **Jibril (جِبرِيل)** (Gabriel) over 23 years. It is the ultimate source of guidance for humanity.")
                        .font(.body)

                    Text(verbatim: "Unlike previous scriptures sent to specific nations and later altered, the Quran is a universal message for all people and all times. Allah says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“And We have not sent you [O Muhammad] except as a mercy to the worlds” (Quran 21:107).", arabic: "وَمَآ أَرۡسَلۡنَٰكَ إِلَّا رَحۡمَةٗ لِّلۡعَٰلَمِينَ")
                }

                Section(header: ArticleHeader("ELOQUENCE AND MIRACULOUS NATURE")) {
                    Text(verbatim: "One of the most remarkable aspects of the Quran is its unmatched eloquence and literary beauty. It stands as the pinnacle of the Arabic language, setting the standard for vocabulary, syntax, and grammar. The Quran fixed the standard of Classical Arabic, and formal Arabic today still measures itself against it.")
                        .font(.body)

                    Text(verbatim: "The Quran challenged the greatest poets and linguists of its time, many of whom were astounded by its profound imagery, rhythmic flow, and clarity. Allah says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“Say, ‘If mankind and the jinn gathered in order to produce the like of this Qur'an, they could not produce the like of it, even if they were to each other assistants.’” (Quran 17:88).", arabic: "قُل لَّئِنِ ٱجۡتَمَعَتِ ٱلۡإِنسُ وَٱلۡجِنُّ عَلَىٰٓ أَن يَأۡتُواْ بِمِثۡلِ هَٰذَا ٱلۡقُرۡءَانِ لَا يَأۡتُونَ بِمِثۡلِهِۦ وَلَوۡ كَانَ بَعۡضُهُمۡ لِبَعۡضٖ ظَهِيرٗا")

                    Text(articleMarkdown: "What makes the challenge sharper is who it came through. Prophet Muhammad (peace and blessings be upon him) was **ummi (أُمِّيّ)**, unlettered: he could neither read nor write, and had never studied poetry, scripture, or the sciences of language. Allah says:")
                        .font(.body)
                    ScriptureQuote(text: "“And you did not recite before it any scripture, nor did you inscribe one with your right hand. Otherwise the falsifiers would have had [cause for] doubt” (Quran 29:48).", arabic: "وَمَا كُنتَ تَتۡلُواْ مِن قَبۡلِهِۦ مِن كِتَٰبٖ وَلَا تَخُطُّهُۥ بِيَمِينِكَۖ إِذٗا لَّٱرۡتَابَ ٱلۡمُبۡطِلُونَ")

                    Text(verbatim: "The Arabs of that era were masters of the spoken word. Poetry was their pride, and their finest odes were memorised and celebrated across Arabia. Yet when the Quran was recited to them, they could not place it. It was not poetry, not rhymed prose, not the speech of a soothsayer, and none of their categories fit. They accused him of magic and of madness precisely because they had no literary answer to give. The challenge to produce even a single surah like it (Quran 2:23) was made openly to the very people best equipped to meet it, and it was never met.")
                        .font(.body)

                    Text(verbatim: "A man who could not write produced, over 23 years, a book their greatest poets could not imitate. That is the argument the Quran makes about itself.")
                        .font(.body)

                    Text(verbatim: "Despite its eloquence and poetic nature, the Quran remains simple and easy to understand, allowing millions of Muslims to memorize it entirely. This combination of literary perfection and accessibility is one of the Quran's miracles.")
                        .font(.body)
                }

                Section(header: ArticleHeader("PRESERVATION")) {
                    Text(verbatim: "The Quran is unique among religious scriptures in that it has been perfectly preserved word for word and letter for letter since its revelation. This preservation is due to its widespread memorization by Muslims and its meticulous recording in written form.")
                        .font(.body)

                    Text(verbatim: "Allah promises in the Quran:").font(.body)
                    ScriptureQuote(text: "“Indeed, it is We who sent down the Quran and indeed, We will be its guardian” (Quran 15:9).", arabic: "إِنَّا نَحۡنُ نَزَّلۡنَا ٱلذِّكۡرَ وَإِنَّا لَهُۥ لَحَٰفِظُونَ")

                    Text(verbatim: "Millions of Muslims, from children to scholars, continue to memorize the Quran in its entirety, ensuring its unaltered transmission across generations. The Quran's preservation is a testament to its divine origin.")
                        .font(.body)
                }

                Section(header: ArticleHeader("GUIDANCE AND MESSAGE")) {
                    Text(verbatim: "The Quran is not merely a book of laws or stories; it provides a comprehensive guide for personal, spiritual, and social life. Allah says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“This is the Book about which there is no doubt, a guidance for those conscious of Allah” (Quran 2:2).", arabic: "ذَٰلِكَ ٱلۡكِتَٰبُ لَا رَيۡبَۛ فِيهِۛ هُدٗى لِّلۡمُتَّقِينَ")

                    Text(verbatim: "It addresses themes such as the oneness of Allah, the purpose of life, moral conduct, and preparation for the Hereafter. The Quran calls for justice, compassion, and humility while offering hope and solace to those who reflect on its verses.")
                        .font(.body)
                }

                Section(header: ArticleHeader("UNIVERSAL MESSAGE")) {
                    Text(verbatim: "Unlike previous scriptures, which were sent to specific nations and for specific times, the Quran is meant for all of humanity, regardless of race, language, or geography. Allah says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“And We have certainly made the Quran easy for remembrance, so is there any who will remember?” (Quran 54:17)", arabic: "وَلَقَدۡ يَسَّرۡنَا ٱلۡقُرۡءَانَ لِلذِّكۡرِ فَهَلۡ مِن مُّدَّكِرٖ")

                    Text(verbatim: "The Quran’s universality and timeless guidance make it relevant to every generation, providing solutions to contemporary issues and inspiring billions of people worldwide.")
                        .font(.body)
                }


                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Unmatched in eloquence yet easy to memorize and understand, the Quran is Allah's protected, universal guidance, relevant to every people and every age.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "MuqattaatPillarView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("What is the Quran?")
    }
}

struct MuqattaatPillarView: View {
    @Environment(\.appearance) private var appearance

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
        Font.arabic(appearance.quranArabicFontName, size: UIFont.preferredFont(forTextStyle: .title2).pointSize)
    }

    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: the Muqatta'at are the disconnected letters (like Alif-Lam-Mim) that open twenty-nine surahs, recited letter by letter.")
                        .font(.body)
                }

                Section(header: ArticleHeader("MUQATTA'AT")) {
                    Text(articleMarkdown: "**Muqatta'at (مُقَطَّعَات)**, from the root **q-t-a (ق ط ع)** meaning to cut or sever, are the disconnected opening letters that appear at the beginning of 29 surahs, after the Basmalah where the Basmalah is recited.")
                        .font(.body)

                    Text(verbatim: "They are also called fawatih, meaning openers, because they open their surahs. Their exact meaning is known to Allah; Muslims recite them as revealed without claiming a hidden meaning with certainty.")
                        .font(.body)

                    Text(verbatim: "Four surahs are named directly for these letters: Ta Ha, Ya Sin, Sad, and Qaf. Some also include Nun because Surah al-Qalam opens with Nun.")
                        .font(.body)
                        .foregroundColor(appearance.accent)
                }

                Section(header: ArticleHeader("PATTERNS")) {
                    Text(verbatim: "There are 14 distinct combinations. The most frequent are Alif Lam Mim and Ha Mim, each appearing six times.")
                        .font(.body)

                    Text(verbatim: "The letters used are half of the Arabic alphabet: ا هـ ح ط ي ك ل م ن س ع ص ق ر.")
                        .font(.body)

                    Text(verbatim: "Most combinations begin with either Alif Lam or Ha Mim. In most of these surahs, the opening letters are followed very soon by mention of the Quran, the Book, revelation, or signs.")
                        .font(.body)
                }

                Section(header: ArticleHeader("RECITATION NOTE")) {
                    Text(verbatim: "In the app's tajweed coloring, complete muqatta'at ayahs are treated as opening-letter recitation. Bare letters stay normal unless they are heavy letters, while letters with maddah are treated as madd lazim.")
                        .font(.body)

                    Text(verbatim: "If the muqatta'at are not the whole ayah, only the first word receives that special opening-letter handling; the rest of the ayah uses normal tajweed rules. For ash-Shura, this handling applies to both of the first two ayahs.")
                        .font(.body)
                }

                Section(header: ArticleHeader("TABLE")) {
                    ForEach(rows) { row in
                        muqattaatRow(row)
                    }
                }

                Section(header: ArticleHeader("LEARN MORE")) {
                    Text(articleMarkdown: "How the muqatta'at are recited: https://www.youtube.com/watch?v=6_gKg6PByOI")
                        .font(.caption)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Their precise meaning is known to Allah; the believer recites them as revealed, and they testify to the Quran's inimitable nature.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .navigationTitle("Muqatta'at Letters")
        .selectableArticleList()
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
                .arabicFontDesign(custom: appearance.quranUsesCustomArabicFace)
                .frame(maxWidth: .infinity, alignment: .trailing)

            Text(row.letters)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Complete ayah: \(row.completeAyah)")
                .font(.caption.weight(.semibold))
                .foregroundColor(row.completeAyah.hasPrefix("Yes") ? appearance.accent : .secondary)
        }
        .padding(.vertical, 4)
    }
}

struct ProphetPillarView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Prophet Muhammad (peace and blessings be upon him) is the final messenger of Allah, sent as a mercy to all creation. He conveyed the Quran and embodied it in his character.")
                        .font(.body)
                }


                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "Prophet **Muhammad (مُحَمَّد)**, “the Praised One,” was born in **Makkah (مَكَّة)** (in present-day Saudi Arabia) around 570 CE, into the noble tribe of Quraysh. Orphaned young, he became known as **Al-Amin (الأَمِين)**, “the Trustworthy,” for his honesty and upright character.")
                        .font(.body)

                    Text(articleMarkdown: "At the age of 40, while worshipping in the cave of **Hira (حِرَاء)**, he received his first revelation from Allah (Glorified and Exalted be He) through the angel **Jibril (جِبرِيل)** (Gabriel). This marked the beginning of his prophethood and the revelation of the Quran, the final divine guidance for humanity.")
                        .font(.body)

                    Text(articleMarkdown: "In Islamic tradition he is called both a **Rasul (رَسُول)**, “Messenger,” and a **Nabi (نَبِيّ)**, “Prophet.” One common explanation is that a Rasul is sent with a message to a people, while a Nabi receives revelation and reinforces an existing law; the scholars differ on the exact distinction, and the Quran calls Harun and Ismail messengers as well (Quran 20:47, 19:54).")
                        .font(.body)

                    Text(verbatim: "He called people to worship Allah alone, rejecting idolatry and emphasizing justice, compassion, and respect for the marginalized. His teachings addressed all facets of life, including spiritual, social, economic, and political matters, as well as personal conduct and morality.")
                        .font(.body)
                }

                Section(header: ArticleHeader("FINAL PROPHET")) {
                    Text(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                    ScriptureQuote(text: "“Muhammad is not the father of [any] one of your men, but [he is] the Messenger of Allah and last of the prophets. And ever is Allah, of all things, Knowing” (Quran 33:40).", arabic: "مَّا كَانَ مُحَمَّدٌ أَبَآ أَحَدٖ مِّن رِّجَالِكُمۡ وَلَٰكِن رَّسُولَ ٱللَّهِ وَخَاتَمَ ٱلنَّبِيِّـۧنَۗ وَكَانَ ٱللَّهُ بِكُلِّ شَيۡءٍ عَلِيمٗا")

                    Text(verbatim: "Prophet Muhammad (peace and blessings be upon him) is the last and final prophet, completing the chain of messengers that began with Adam (peace be upon him). He delivered the final revelation, the Quran, and exemplified its teachings as the ultimate role model.")
                        .font(.body)
                }

                Section(header: ArticleHeader("HIS CHARACTER")) {
                    Text(verbatim: "Prophet Muhammad (peace and blessings be upon him) is described in the Quran as a man of exemplary character. Allah says in the Quran:").font(.body)
                    ScriptureQuote(text: "“And indeed, you are of a great moral character” (Quran 68:4).", arabic: "وَإِنَّكَ لَعَلَىٰ خُلُقٍ عَظِيمٖ")

                    Text(verbatim: "He was known for his compassion, humility, and justice. Even toward his enemies, he demonstrated forgiveness and kindness. Aisha (may Allah be pleased with her), his wife, described him by saying:").font(.body)
                    ScriptureQuote(text: "“The character of the Messenger of Allah (ﷺ) was the Qur'an” (Sahih Muslim 746).", arabic: "فَإِنَّ خُلُقَ نَبِيِّ اللَّهِ صلى الله عليه وسلم كَانَ الْقُرْآنَ", dimmed: true)

                    Text(verbatim: "Allah also says in the Quran:").font(.body)
                    ScriptureQuote(text: "“There has certainly been for you in the Messenger of Allah an excellent pattern for anyone whose hope is in Allah and the Last Day and [who] remembers Allah often” (Quran 33:21).", arabic: "لَّقَدۡ كَانَ لَكُمۡ فِي رَسُولِ ٱللَّهِ أُسۡوَةٌ حَسَنَةٞ لِّمَن كَانَ يَرۡجُواْ ٱللَّهَ وَٱلۡيَوۡمَ ٱلۡأٓخِرَ وَذَكَرَ ٱللَّهَ كَثِيرٗا")

                    Text(verbatim: "Obedience to the Prophet (peace and blessings be upon him) is also linked to obedience to Allah. Allah says in the Quran:").font(.body)
                    ScriptureQuote(text: "“He who obeys the Messenger has obeyed Allah; but those who turn away - We have not sent you over them as a guardian” (Quran 4:80).", arabic: "مَّن يُطِعِ ٱلرَّسُولَ فَقَدۡ أَطَاعَ ٱللَّهَۖ وَمَن تَوَلَّىٰ فَمَآ أَرۡسَلۡنَٰكَ عَلَيۡهِمۡ حَفِيظٗا")

                    Text(verbatim: "His humility is evident in many of his interactions. When a companion's voice trembled as he talked to the prophet, the prophet (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“Be calm, for I am not a king. Verily, I am only the son of a woman who ate dried meat” (Sunan Ibn Majah 3312; graded sahih by al-Albani).", arabic: "هَوِّنْ عَلَيْكَ فَإِنِّي لَسْتُ بِمَلِكٍ إِنَّمَا أَنَا ابْنُ امْرَأَةٍ تَأْكُلُ الْقَدِيدَ", dimmed: true)

                    Text(verbatim: "He also said:").font(.body)
                    ScriptureQuote(text: "“I eat as the servant eats, and I sit as the servant sits, for I am only a servant” (as-Silsilah as-Sahihah 544; authenticated by al-Albani).", arabic: "آكُلُ كَمَا يَأْكُلُ الْعَبْدُ، وَأَجْلِسُ كَمَا يَجْلِسُ الْعَبْدُ، فَإِنَّمَا أَنَا عَبْدٌ", dimmed: true)

                    Text(verbatim: "Similarly, the Prophet (peace and blessings be upon him) warned against excessive praise, saying:").font(.body)
                    ScriptureQuote(text: "“Do not exaggerate in praising me as the Christians praised the son of Mary, for I am only a Slave. So, call me the Slave of Allah and His Apostle” (Sahih al-Bukhari 3445).", arabic: "لاَ تُطْرُونِي كَمَا أَطْرَتِ النَّصَارَى ابْنَ مَرْيَمَ، فَإِنَّمَا أَنَا عَبْدُهُ، فَقُولُوا عَبْدُ اللَّهِ وَرَسُولُهُ", dimmed: true)
                }

                Section(header: ArticleHeader("HIS TEACHINGS")) {
                    Text(articleMarkdown: "The teachings and practices of Prophet Muhammad (peace and blessings be upon him) are called the **Sunnah (سُنَّة)**, which serve as a guide for Muslims to live a righteous and balanced life. He perfectly demonstrated how to implement the Quran in daily life.")
                        .font(.body)

                    Text(verbatim: "While Muslims deeply love and revere him, worship is reserved for Allah (Glorified and Exalted be He) alone. He is honored as the finest example of humanity, yet never viewed as divine.")
                        .font(.body)
                }

                Section(header: ArticleHeader("HIS IMPACT")) {
                    Text(verbatim: "Prophet Muhammad (peace and blessings be upon him) is considered one of the most influential figures in history. Historian Michael H. Hart ranked him as the most influential person of all time, citing his unparalleled success both religiously and politically. With the will of Allah, he unified Arabia under Islam and established a faith that continues to inspire billions.")
                        .font(.body)

                    Text(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                    ScriptureQuote(text: "“And We have not sent you, [O Muhammad], except as a mercy to the worlds” (Quran 21:107).", arabic: "وَمَآ أَرۡسَلۡنَٰكَ إِلَّا رَحۡمَةٗ لِّلۡعَٰلَمِينَ")
                }

                Section(header: ArticleHeader("HIS LEGACY")) {
                    Text(verbatim: "Prophet Muhammad (peace and blessings be upon him) passed away at the age of 63 in Madinah, leaving behind the Quran and Sunnah as guidance for humanity. In his Farewell Sermon, he emphasized the equality of all people, adherence to the Book of Allah (Sahih Muslim 1218), and the importance of justice and righteousness.")
                        .font(.body)

                    Text(verbatim: "He said:").font(.body)
                    ScriptureQuote(text: "“O people, your Lord is one and your father is one. There is no superiority of an Arab over a non-Arab, nor of a non-Arab over an Arab, nor of a red (light-skinned) person over a black person, nor of a black person over a red person, except by taqwa” (Musnad Ahmad 23489; graded sahih by al-Albani, as-Silsilah as-Sahihah 2700, and by Shu'ayb al-Arna'ut).", arabic: "يَا أَيُّهَا النَّاسُ، أَلَا إِنَّ رَبَّكُمْ وَاحِدٌ، وَإِنَّ أَبَاكُمْ وَاحِدٌ، أَلَا لَا فَضْلَ لِعَرَبِيٍّ عَلَى عَجَمِيٍّ، وَلَا لِعَجَمِيٍّ عَلَى عَرَبِيٍّ، وَلَا أَحْمَرَ عَلَى أَسْوَدَ، وَلَا أَسْوَدَ عَلَى أَحْمَرَ، إِلَّا بِالتَّقْوَى", dimmed: true)

                    Text(verbatim: "This is the Quran's own standard:").font(.body)
                    ScriptureQuote(text: "“Indeed, the most noble of you in the sight of Allah is the most righteous of you” (Quran 49:13).", arabic: "إِنَّ أَكۡرَمَكُمۡ عِندَ ٱللَّهِ أَتۡقَىٰكُمۡۚ")
                }


                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "As the seal of the prophets and the finest example for humanity, he is deeply loved and followed, yet he is never worshipped, for worship belongs to Allah alone.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "ProphetPillarView")

                ArticleSourcesSection(article: "SunnahPillarView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("Who is the Prophet?")
    }
}

struct SunnahPillarView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: the Sunnah is the way of Prophet Muhammad (peace and blessings be upon him): his words, actions, and approvals. It explains the Quran and is the second source of Islam.")
                        .font(.body)
                }


                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "The **Sunnah (سُنَّة)**, an Arabic word meaning “way,” “path,” or “tradition,” is the teachings, actions, and approvals of Prophet Muhammad (peace and blessings be upon him): his habits, moral conduct, and guidance on worship and dealings. It explains and complements the Quran and is the second source of Islamic knowledge.")
                        .font(.body)

                    Text(verbatim: "Allah says in the Quran:").font(.body)
                    ScriptureQuote(text: "“And whatever the Messenger has given you – take; and what he has forbidden you – refrain from. And fear Allah; indeed, Allah is severe in penalty” (Quran 59:7).", arabic: "وَمَآ ءَاتَىٰكُمُ ٱلرَّسُولُ فَخُذُوهُ وَمَا نَهَىٰكُمۡ عَنۡهُ فَٱنتَهُواْۚ وَٱتَّقُواْ ٱللَّهَۖ إِنَّ ٱللَّهَ شَدِيدُ ٱلۡعِقَابِ")
                }

                Section(header: ArticleHeader("IMPORTANCE")) {
                    Text(verbatim: "The Sunnah provides practical guidance on how to live according to the Quran. It clarifies general commands in the Quran and gives specific instructions. For instance, the Quran commands Muslims to pray, and the Sunnah demonstrates how to perform the prayer.")
                        .font(.body)

                    Text(verbatim: "The Prophet (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“Pray as you have seen me praying” (Sahih al-Bukhari 631).", arabic: "وَصَلُّوا كَمَا رَأَيْتُمُونِي أُصَلِّي", dimmed: true)

                    Text(verbatim: "The Sunnah also serves as an example for personal conduct and social interactions. Allah says in the Quran:").font(.body)
                    ScriptureQuote(text: "“There has certainly been for you in the Messenger of Allah an excellent pattern for anyone whose hope is in Allah and the Last Day and [who] remembers Allah often” (Quran 33:21).", arabic: "لَّقَدۡ كَانَ لَكُمۡ فِي رَسُولِ ٱللَّهِ أُسۡوَةٌ حَسَنَةٞ لِّمَن كَانَ يَرۡجُواْ ٱللَّهَ وَٱلۡيَوۡمَ ٱلۡأٓخِرَ وَذَكَرَ ٱللَّهَ كَثِيرٗا")

                    Text(verbatim: "Obedience to the Sunnah is considered obedience to Allah. Allah says in the Quran:").font(.body)
                    ScriptureQuote(text: "“He who obeys the Messenger has obeyed Allah; but those who turn away - We have not sent you over them as a guardian” (Quran 4:80).", arabic: "مَّن يُطِعِ ٱلرَّسُولَ فَقَدۡ أَطَاعَ ٱللَّهَۖ وَمَن تَوَلَّىٰ فَمَآ أَرۡسَلۡنَٰكَ عَلَيۡهِمۡ حَفِيظٗا")
                }

                Section(header: ArticleHeader("HADITH LITERATURE")) {
                    Text(articleMarkdown: "The Sunnah is preserved through **Hadith (حَدِيث)**, compilations of the recorded sayings, actions, and approvals of the Prophet Muhammad (peace and blessings be upon him). These narrations were meticulously verified by scholars to ensure their authenticity.")
                        .font(.body)

                    Text(verbatim: "Major Hadith collections include:").font(.body)
                    Text(verbatim: "1. Sahih al-Bukhari").font(.body)
                    Text(verbatim: "2. Sahih Muslim").font(.body)
                    Text(verbatim: "3. Sunan Abu Dawood").font(.body)
                    Text(verbatim: "4. Jami' at-Tirmidhi").font(.body)
                    Text(verbatim: "5. Sunan an-Nasa'i").font(.body)
                    Text(verbatim: "6. Sunan Ibn Majah").font(.body)

                    Text(verbatim: "These collections provide invaluable insights into the life and teachings of the Prophet (peace and blessings be upon him) and serve as a foundation for understanding and implementing the Sunnah.")
                        .font(.body)
                }

                Section(header: ArticleHeader("EXAMPLES OF SUNNAH")) {
                    Text(verbatim: "Examples of Sunnah practices include:").font(.body)
                    Text(articleMarkdown: "1. Greeting others with **As-Salamu Alaikum (السَّلَام عَلَيكُم)** (peace be upon you).").font(.body)
                    Text(articleMarkdown: "2. Saying **Bismillah (بِسم اللَّه)** (in the name of Allah) before eating (Sahih al-Bukhari 5376).").font(.body)
                    Text(verbatim: "3. Performing acts of charity, such as smiling at others, which the Prophet (peace and blessings be upon him) called charity (Sunan al-Tirmidhi 1956; graded sahih by al-Albani).").font(.body)
                    Text(verbatim: "4. Maintaining cleanliness and grooming, such as trimming the nails, which the Prophet (peace and blessings be upon him) counted among the acts of the fitrah (Sahih al-Bukhari 5889).").font(.body)
                    Text(verbatim: "5. Showing kindness and mercy to others, including animals.").font(.body)
                    Text(verbatim: "6. Praying certain optional prayers.").font(.body)
                }

                Section(header: ArticleHeader("RESOURCES")) {
                    Text(verbatim: "You can view Hadith collections here: https://sunnah.com/")
                        .font(.caption)
                }


                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Preserved through authentic Hadith, the Sunnah shows a Muslim how to live the Quran in daily life, and holding to it is part of obeying Allah.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "HadithPillarView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("What is the Sunnah?")
    }
}

struct HadithPillarView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: a Hadith is a recorded saying, action, or approval of Prophet Muhammad (peace and blessings be upon him). Hadiths preserve the Sunnah and clarify how to act on the Quran.")
                        .font(.body)
                }


                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "A **Hadith (حَدِيث)**, an Arabic word meaning “speech,” “narration,” or “report,” is a recorded saying, action, or approval of Prophet Muhammad (peace and blessings be upon him). Hadiths preserve the Sunnah and are an essential source of Islamic knowledge, and scholars verified them meticulously to ensure their authenticity.")
                        .font(.body)

                    Text(verbatim: "Allah (Glorified and Exalted be He) commands in the Quran:").font(.body)
                    ScriptureQuote(text: "“And whatever the Messenger has given you – take; and what he has forbidden you – refrain from. And fear Allah; indeed, Allah is severe in penalty” (Quran 59:7).", arabic: "وَمَآ ءَاتَىٰكُمُ ٱلرَّسُولُ فَخُذُوهُ وَمَا نَهَىٰكُمۡ عَنۡهُ فَٱنتَهُواْۚ وَٱتَّقُواْ ٱللَّهَۖ إِنَّ ٱللَّهَ شَدِيدُ ٱلۡعِقَابِ")

                    Text(verbatim: "Hadiths are indispensable for understanding and implementing the Quran’s teachings, as they provide practical examples of how Prophet Muhammad (peace and blessings be upon him) lived according to Allah’s commands.")
                        .font(.body)
                }

                Section(header: ArticleHeader("RELATIONSHIP WITH THE QURAN")) {
                    Text(verbatim: "Hadiths are essential for interpreting and contextualizing the Quran. Allah says in the Quran:").font(.body)
                    ScriptureQuote(text: "“It is He who has sent down to you, [O Muhammad], the Book; in it are verses [that are] precise... and others unspecific” (Quran 3:7).", arabic: "هُوَ ٱلَّذِيٓ أَنزَلَ عَلَيۡكَ ٱلۡكِتَٰبَ مِنۡهُ ءَايَٰتٞ مُّحۡكَمَٰتٌ هُنَّ أُمُّ ٱلۡكِتَٰبِ وَأُخَرُ مُتَشَٰبِهَٰتٞۖ")

                    Text(articleMarkdown: "While the Quran provides general principles, the Hadith clarifies how to implement these teachings. For example, the Quran commands Muslims to pray, and the Hadith describes how the Prophet (peace and blessings be upon him) performed **Salah (صَلَاة)**. He said:").font(.body)
                    ScriptureQuote(text: "“Pray as you have seen me praying” (Sahih al-Bukhari 631).", arabic: "وَصَلُّوا كَمَا رَأَيْتُمُونِي أُصَلِّي", dimmed: true)
                }

                Section(header: ArticleHeader("TYPES OF HADITHS")) {
                    Text(verbatim: "There are two main types of Hadiths:").font(.body)

                    Text(articleMarkdown: "1. **Hadith Qudsi (حَدِيث قُدسِي), the Sacred Hadith:** These are sayings where the Prophet (peace and blessings be upon him) conveys meanings from Allah (Glorified and Exalted be He), but the wording is his own. Unlike the Quran, which is the exact verbatim word of Allah, Hadith Qudsi reflects divine inspiration shared through the Prophet’s speech. For example, the Prophet said:").font(.body)
                    ScriptureQuote(text: "“Allah says: 'I am just as My slave thinks I am, (i.e. I am able to do for him what he thinks I can do for him) and I am with him if He remembers Me” (Sahih al-Bukhari 7405)", arabic: "يَقُولُ اللَّهُ تَعَالَى أَنَا عِنْدَ ظَنِّ عَبْدِي بِي، وَأَنَا مَعَهُ إِذَا ذَكَرَنِي", dimmed: true)
                    Text(verbatim: "While the Quran was revealed through the Angel Jibril (Gabriel) and recited exactly as revealed, Hadith Qudsi might have been conveyed to the Prophet through a dream or inspiration. It holds a special status but is not part of the Quran.")
                        .font(.body)

                    Text(articleMarkdown: "2. **Hadith Nabawi (حَدِيث نَبَوِي), the Prophetic Hadith:** These include the Prophet’s own words, actions, and approvals, reflecting his teachings and practices. For instance, he said:").font(.body)
                    ScriptureQuote(text: "“The best among you (Muslims) are those who learn the Quran and teach it” (Sahih al-Bukhari 5027).", arabic: "خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ", dimmed: true)

                    Text(verbatim: "Learn the difference here: https://www.youtube.com/watch?v=F7vfmGC-o-A")
                        .font(.caption)
                }

                Section(header: ArticleHeader("AUTHENTICITY AND CLASSIFICATION")) {
                    Text(verbatim: "Hadiths were meticulously preserved and classified by scholars based on their authenticity to ensure the teachings of Prophet Muhammad (peace and blessings be upon him) were transmitted accurately. A hadith consists of two critical components:").font(.body)
                    Text(articleMarkdown: "1. **Isnad (إِسنَاد), the Chain of Transmission:** The sequence of narrators who transmitted the hadith. This ensures a direct link back to the Prophet (peace and blessings be upon him).").font(.body)
                    Text(articleMarkdown: "2. **Matn (مَتن), the Text:** The content of the hadith itself, which is examined for consistency with established Islamic teachings and linguistic accuracy.").font(.body)

                    Text(verbatim: "The rigorous analysis of isnad and matn is crucial because some individuals attempted to fabricate sayings of the Prophet (peace and blessings be upon him). To safeguard against such corruption, scholars developed a meticulous science of hadith authentication. The Prophet (peace and blessings be upon him) warned:").font(.body)
                    ScriptureQuote(text: "“Whoever tells a lie against me intentionally, then (surely) let him occupy his seat in Hell-fire” (Sahih al-Bukhari 108).", arabic: "مَنْ تَعَمَّدَ عَلَىَّ كَذِبًا فَلْيَتَبَوَّأْ مَقْعَدَهُ مِنَ النَّارِ", dimmed: true)

                    Text(verbatim: "This rigorous methodology prevented the kind of corruption and fabrications found in other scriptures, such as the Bible, where authors are often anonymous, and transmission chains are unknown. In Islam, every accepted hadith is traced back to the Prophet (peace and blessings be upon him) through a chain whose narrators were individually examined; reports that fail that test are rejected.").font(.body)

                    Text(verbatim: "Scholars classified Hadiths into categories based on their reliability and authenticity:").font(.body)
                    Text(articleMarkdown: "- **Mutawatir (مُتَوَاتِر), Mass-Transmitted:** Narrated by a large number of trustworthy narrators, ensuring its authenticity without any doubt.").font(.body)
                    Text(articleMarkdown: "- **Sahih (صَحِيح), Authentic:** Reliable chain and text, meeting strict criteria of authenticity.").font(.body)
                    Text(articleMarkdown: "- **Hasan (حَسَن), Good:** Slightly weaker chain than Sahih but still reliable and acceptable for use in rulings.").font(.body)
                    Text(articleMarkdown: "- **Da'if (ضَعِيف), Weak:** Questionable reliability due to issues in the chain or content, generally avoided for rulings.").font(.body)

                    Text(articleMarkdown: "The highest rank of authentic hadith is known as **Muttafaqun Alayh (مُتَّفَق عَلَيه)**, meaning “agreed upon.“ These are hadiths narrated by both Imam Bukhari and Imam Muslim in their Sahih collections, indicating the highest level of authenticity.").font(.body)

                    Text(verbatim: "This detailed grading system ensures that Muslims can confidently rely on the Hadiths as a source of guidance without the risk of fabricated or unreliable narrations.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IMPORTANCE OF HADITHS")) {
                    Text(verbatim: "The Hadiths are indispensable for:").font(.body)
                    Text(articleMarkdown: "1. **Clarifying the Quran:** They explain Quranic commands, such as how to perform Salah and fast during **Ramadan (رَمَضَان)**.").font(.body)
                    Text(articleMarkdown: "2. **Guiding Daily Life:** Hadiths provide moral and ethical lessons, teaching Muslims how to interact with others and live righteously.").font(.body)
                    Text(articleMarkdown: "3. **Strengthening Faith:** They contain spiritual guidance and wisdom that deepen a Muslim’s connection to Allah (Glorified and Exalted be He).").font(.body)

                    Text(verbatim: "The Prophet (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“I have left among you the Book of Allah, and if you hold fast to it, you would never go astray” (Sahih Muslim 1218).", arabic: "وَقَدْ تَرَكْتُ فِيكُمْ مَا لَنْ تَضِلُّوا بَعْدَهُ إِنِ اعْتَصَمْتُمْ بِهِ كِتَابَ اللَّهِ", dimmed: true)

                    Text(verbatim: "And he commanded holding to his Sunnah:").font(.body)
                    ScriptureQuote(text: "“You must then follow my sunnah and that of the rightly-guided caliphs. Hold to it and stick fast to it. Avoid novelties, for every novelty is an innovation, and every innovation is an error” (Sunan Abi Dawud 4607; graded sahih by al-Albani).", arabic: "فَعَلَيْكُمْ بِسُنَّتِي وَسُنَّةِ الْخُلَفَاءِ الْمَهْدِيِّينَ الرَّاشِدِينَ تَمَسَّكُوا بِهَا وَعَضُّوا عَلَيْهَا بِالنَّوَاجِذِ وَإِيَّاكُمْ وَمُحْدَثَاتِ الأُمُورِ فَإِنَّ كُلَّ مُحْدَثَةٍ بِدْعَةٌ وَكُلَّ بِدْعَةٍ ضَلاَلَةٌ", dimmed: true)
                }

                Section(header: ArticleHeader("RESOURCES")) {
                    Text(verbatim: "You can view Hadith collections here: https://sunnah.com/")
                        .font(.caption)
                }


                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Through a rigorous science of chain (Isnad) and text (Matn), scholars carefully graded Hadiths, so Muslims can rely on authentic prophetic guidance with confidence.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "ShahadahView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("What are Hadiths?")
    }
}

import SwiftUI

struct ShahadahView: View {
    @Environment(\.appearance) private var appearance

    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: the Shahadah is the testimony that there is no god but Allah and that Muhammad is His Messenger. It is the doorway into Islam and the foundation of all faith.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "The **Shahadah (شَهَادَة)**, from the root **sh-h-d (ش ه د)** meaning “to witness” or “to testify,” is the first and most fundamental pillar of Islam. By declaring it with sincerity, a person affirms the Oneness of Allah (Glorified and Exalted be He) and accepts Muhammad (peace and blessings be upon him) as His final Prophet.")
                        .font(.body)

                    Text(verbatim: "This simple yet profound statement encapsulates the essence of Islam: the worship of Allah alone and adherence to the teachings of His messenger. Allah (Glorified and Exalted be He) says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“And We sent not before you any messenger except that We revealed to him that, ‘There is no deity except Me, so worship Me’” (Quran 21:25).", arabic: "وَمَآ أَرۡسَلۡنَا مِن قَبۡلِكَ مِن رَّسُولٍ إِلَّا نُوحِيٓ إِلَيۡهِ أَنَّهُۥ لَآ إِلَٰهَ إِلَّآ أَنَا۠ فَٱعۡبُدُونِ")
                }

                Section(header: ArticleHeader("VERSIONS")) {
                    Text(verbatim: "There are two common versions of the Shahadah, both from the Sunnah. The first is the wording of the adhan and the iqamah (Sahih Muslim 379; Sunan Abi Dawud 499, graded hasan sahih by al-Albani); the second is the wording of the tashahhud in every prayer (Sahih al-Bukhari 831) and of the testimony after wudhu (Sahih Muslim 234). The second names the Prophet (peace and blessings be upon him) as Allah's slave before naming him as His Messenger, so that he is never viewed as divine.")
                        .font(.body)
                }

                Section(header: ArticleHeader("FIRST VERSION")) {
                    VStack(alignment: .leading) {
                        Text(verbatim: "أَشهَدُ أَن لَا إِلٰهَ إِلَّا ٱللّٰهُ وَأَشهَدُ أَنَّ مُحَمَّدًا رَسُولُ ٱللّٰهِ")
                            .font(.body)
                            .foregroundColor(appearance.accent)
                            .multilineTextAlignment(.trailing)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 2)

                        Text(verbatim: "Ashhadu an la ilaha illa Allah, wa ashhadu anna Muhammad rasul Allah.")
                            .font(.body)
                            .padding(.vertical, 2)

                        Text(verbatim: "“I bear witness that there is no deity but Allah, and I bear witness that Muhammad is the messenger of Allah.”")
                            .font(.body)
                            .padding(.vertical, 2)
                    }
                }

                Section(header: ArticleHeader("SECOND VERSION")) {
                    VStack(alignment: .leading) {
                        Text(verbatim: "أَشهَدُ أَن لَا إِلٰهَ إِلَّا ٱللّٰهُ وَأَشهَدُ أَنَّ مُحَمَّدًا عَبدُهُ وَرَسُولُهُ")
                            .font(.body)
                            .foregroundColor(appearance.accent)
                            .multilineTextAlignment(.trailing)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 2)

                        Text(verbatim: "Ashhadu an la ilaha illa Allah, wa ashhadu anna Muhammad abduhu wa rasuluhu.")
                            .font(.body)
                            .padding(.vertical, 2)

                        Text(verbatim: "“I bear witness that there is no deity but Allah, and I bear witness that Muhammad is His servant and messenger.”")
                            .font(.body)
                            .padding(.vertical, 2)
                    }
                }

                Section(header: ArticleHeader("SIGNIFICANCE")) {
                    Text(verbatim: "Pronouncing the Shahadah with sincere faith confirms Tawhid (absolute monotheism) and the acceptance of Muhammad (peace and blessings be upon him) as the final Prophet. Allah (Glorified and Exalted be He) says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“So know [O Muhammad], that there is no deity except Allah” (Quran 47:19).", arabic: "فَٱعۡلَمۡ أَنَّهُۥ لَآ إِلَٰهَ إِلَّا ٱللَّهُ")

                    Text(verbatim: "The Prophet (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“He who died knowing (fully well) that there is no god but Allah entered Paradise” (Sahih Muslim 26).", arabic: "مَنْ مَاتَ وَهُوَ يَعْلَمُ أَنَّهُ لاَ إِلَهَ إِلاَّ اللَّهُ دَخَلَ الْجَنَّةَ", dimmed: true)

                    Text(verbatim: "The Shahadah is a lifelong declaration of faith and is recited during the daily prayers, serving as a constant reminder of a Muslim's commitment to Allah and His messenger.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Said with sincere conviction and lived by, the Shahadah affirms pure monotheism and acceptance of the Prophet's guidance, renewed in every prayer a Muslim offers.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "SalahView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("Shahadah")
    }
}

struct SalahView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Salah is the five daily prayers: a direct connection between the servant and Allah, and the first deed a person will be asked about on the Day of Judgment.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "**Salah (صَلَاة)**, from the root **s-l-w (ص ل و)** carrying the sense of prayer, supplication, and connection, is the second pillar of Islam. It is an act of worship that links a Muslim directly to Allah (Glorified and Exalted be He), performed five times daily at prescribed times as a constant reminder of submission and gratitude.")
                        .font(.body)

                    Text(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                    ScriptureQuote(text: "“Indeed, I am Allah. There is no deity except Me, so worship Me and establish prayer for My remembrance” (Quran 20:14).", arabic: "إِنَّنِيٓ أَنَا ٱللَّهُ لَآ إِلَٰهَ إِلَّآ أَنَا۠ فَٱعۡبُدۡنِي وَأَقِمِ ٱلصَّلَوٰةَ لِذِكۡرِيٓ")
                }

                Section(header: ArticleHeader("TIMINGS")) {
                    Text(verbatim: "The five daily prayers are:").font(.body)
                    Text(articleMarkdown: "1. **Fajr (Dawn):** Performed before sunrise.").font(.body)
                    Text(articleMarkdown: "2. **Dhuhr (Noon):** Performed after the sun passes its zenith.").font(.body)
                    Text(articleMarkdown: "3. **Asr (Afternoon):** Performed in the late afternoon.").font(.body)
                    Text(articleMarkdown: "4. **Maghrib (Evening):** Performed just after sunset.").font(.body)
                    Text(articleMarkdown: "5. **Isha (Night):** Performed in the late evening.").font(.body)

                    Text(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                    ScriptureQuote(text: "“Indeed, prayer has been decreed upon the believers a decree of specified times” (Quran 4:103).", arabic: "إِنَّ ٱلصَّلَوٰةَ كَانَتۡ عَلَى ٱلۡمُؤۡمِنِينَ كِتَٰبٗا مَّوۡقُوتٗا")
                }

                Section(header: ArticleHeader("NUMBER OF UNITS (RAKAH)")) {
                    Text(articleMarkdown: "Each prayer is made up of units called **rak'ah (رَكعَة)**:").font(.body)
                    Text(articleMarkdown: "• **Fajr**: 2 rak'ah").font(.body)
                    Text(articleMarkdown: "• **Dhuhr**: 4 rak'ah").font(.body)
                    Text(articleMarkdown: "• **Asr**: 4 rak'ah").font(.body)
                    Text(articleMarkdown: "• **Maghrib**: 3 rak'ah").font(.body)
                    Text(articleMarkdown: "• **Isha**: 4 rak'ah").font(.body)
                }

                Section(header: ArticleHeader("HOW TO PRAY")) {
                    Text(verbatim: "The Prophet (peace and blessings be upon him) instructed:").font(.body)
                    ScriptureQuote(text: "“Pray as you have seen me praying” (Sahih al-Bukhari 631).", arabic: "وَصَلُّوا كَمَا رَأَيْتُمُونِي أُصَلِّي", dimmed: true)
                    Text(articleMarkdown: "Facing the Qibla, with the **Niyyah (نِيَّة)**, the intention, settled in the heart, the prayer proceeds as follows (the opening takbir with the hands raised and the opening supplication belong to the first rak'ah only; every later rak'ah begins from the recitation):").font(.body)
                    Text(articleMarkdown: "1. **Takbir (تَكبِير)**: raise the hands and say “Allahu Akbar” (Allah is the Greatest), then place the right hand over the left upon the chest.").font(.body)
                    Text(articleMarkdown: "2. **Recitation**: in the first rak'ah recite the opening supplication (Sahih al-Bukhari 744), then Surah **Al-Fatiha (الفَاتِحَة)**, obligatory in every rak'ah, followed by another passage of the Quran in the first two rak'ah.").font(.body)
                    Text(articleMarkdown: "3. **Ruku (رُكُوع)**: say “Allahu Akbar” and bow with a straight back, hands on the knees, saying “Subhana Rabbi al-Adheem” (Glory to my Lord the Most Great) three times.").font(.body)
                    Text(articleMarkdown: "4. **Rising (I'tidal)**: rise saying “Sami'a Allahu liman hamidah” (Allah hears whoever praises Him), then, standing, “Rabbana wa laka al-hamd” (Our Lord, to You is all praise).").font(.body)
                    Text(articleMarkdown: "5. **Sujud (سُجُود)**: say “Allahu Akbar” and prostrate on seven parts (the forehead and nose, both palms, both knees, and the toes of both feet), saying “Subhana Rabbi al-A'la” (Glory to my Lord the Most High) three times.").font(.body)
                    Text(articleMarkdown: "6. **Sitting**: say “Allahu Akbar,” sit, and say “Rabbi ighfir li” (My Lord, forgive me); then perform a second Sujud in the same way. This completes one rak'ah.").font(.body)
                    Text(articleMarkdown: "7. **Tashahhud (تَشَهُّد)**: after each two rak'ah, sit and recite the tashahhud (“At-tahiyyatu lillah…”). In the final sitting, add the prayers upon the Prophet (peace and blessings be upon him) and supplication.").font(.body)
                    Text(articleMarkdown: "8. **Taslim (تَسلِيم)**: end the prayer by turning the face to the right and then to the left, saying each time “As-salamu alaykum wa rahmatullah” (peace and the mercy of Allah be upon you).").font(.body)
                }

                Section(header: ArticleHeader("BENEFITS")) {
                    Text(verbatim: "Salah purifies the soul, instills discipline, and strengthens a Muslim's relationship with Allah (Glorified and Exalted be He). It keeps one mindful of their Creator throughout the day, offering spiritual peace and balance.")
                        .font(.body)

                    Text(verbatim: "Salah also serves as a means of expiation for minor sins. The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“The five (daily) prayers and from one Friday prayer to the (next) Friday prayer, and from Ramadhan to Ramadhan are expiations for the (sins) committed in between (their intervals) provided one shuns the major sins” (Sahih Muslim 233c).", arabic: "الصَّلَوَاتُ الْخَمْسُ وَالْجُمُعَةُ إِلَى الْجُمُعَةِ وَرَمَضَانُ إِلَى رَمَضَانَ مُكَفِّرَاتٌ مَا بَيْنَهُنَّ إِذَا اجْتَنَبَ الْكَبَائِرَ", dimmed: true)
                }

                Section(header: ArticleHeader("IMPORTANCE OF SALAH")) {
                    Text(verbatim: "Salah is the first deed for which a person will be held accountable on the Day of Judgment. The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“Indeed the first deed by which a servant will be called to account on the Day of Resurrection is his Salat. If it is complete, he is successful and saved, but if it is defective, he has failed and lost. So if something is deficient in his obligatory (prayers) then the Lord, Mighty and Sublime says: 'Look! Are there any voluntary (prayers) for my worshipper?' So with them, what was deficient in his obligatory (prayers) will be completed. Then the rest of his deeds will be treated like that” (Sunan al-Tirmidhi 413; graded sahih by al-Albani).", arabic: "إِنَّ أَوَّلَ مَا يُحَاسَبُ بِهِ الْعَبْدُ يَوْمَ الْقِيَامَةِ مِنْ عَمَلِهِ صَلاَتُهُ فَإِنْ صَلُحَتْ فَقَدْ أَفْلَحَ وَأَنْجَحَ وَإِنْ فَسَدَتْ فَقَدْ خَابَ وَخَسِرَ فَإِنِ انْتَقَصَ مِنْ فَرِيضَتِهِ شَيْءٌ قَالَ الرَّبُّ عَزَّ وَجَلَّ انْظُرُوا هَلْ لِعَبْدِي مِنْ تَطَوُّعٍ فَيُكَمَّلَ بِهَا مَا انْتَقَصَ مِنَ الْفَرِيضَةِ ثُمَّ يَكُونُ سَائِرُ عَمَلِهِ عَلَى ذَلِكَ", dimmed: true)

                    Text(verbatim: "It is also a key to success in this life and the Hereafter. Allah (Glorified and Exalted be He) says:").font(.body)
                    ScriptureQuote(text: "“Certainly will the believers have succeeded: They who are during their prayer humbly submissive” (Quran 23:1-2).", arabic: "قَدۡ أَفۡلَحَ ٱلۡمُؤۡمِنُونَ ۝ ٱلَّذِينَ هُمۡ فِي صَلَاتِهِمۡ خَٰشِعُونَ")
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Prayed as the Prophet prayed, Salah purifies the soul, restrains from wrongdoing, and keeps a Muslim mindful of Allah throughout the day.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "SawmView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("Salah")
    }
}

struct SawmView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Sawm is fasting from dawn to sunset, especially in Ramadan, abstaining from food, drink, and desires to draw nearer to Allah and attain God-consciousness.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "**Sawm (صَوم)**, from the root **s-w-m (ص و م)** meaning “to abstain” or “to refrain,” is the fourth pillar of Islam. It is fasting: abstaining from food, drink, and marital relations from dawn (Fajr) until sunset (Maghrib) with the intention of seeking Allah’s pleasure.")
                        .font(.body)

                    Text(verbatim: "Fasting during the sacred month of Ramadan is obligatory for all adult Muslims who are physically and mentally capable. Allah (Glorified and Exalted be He) says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“The month of Ramadhan [is that] in which was revealed the Qur'an, a guidance for the people and clear proofs of guidance and criterion” (Quran 2:185).", arabic: "شَهۡرُ رَمَضَانَ ٱلَّذِيٓ أُنزِلَ فِيهِ ٱلۡقُرۡءَانُ هُدٗى لِّلنَّاسِ وَبَيِّنَٰتٖ مِّنَ ٱلۡهُدَىٰ وَٱلۡفُرۡقَانِۚ")
                }

                Section(header: ArticleHeader("PURPOSE")) {
                    Text(articleMarkdown: "Fasting is not merely abstaining from physical needs but also involves refraining from sinful speech, actions, and thoughts. Its purpose is to develop **Taqwa (تَقوَى)**, God-consciousness, and purify the soul.")
                        .font(.body)

                    Text(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                    ScriptureQuote(text: "“O you who have believed, decreed upon you is fasting as it was decreed upon those before you that you may become righteous” (Quran 2:183).", arabic: "يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُواْ كُتِبَ عَلَيۡكُمُ ٱلصِّيَامُ كَمَا كُتِبَ عَلَى ٱلَّذِينَ مِن قَبۡلِكُمۡ لَعَلَّكُمۡ تَتَّقُونَ")
                }

                Section(header: ArticleHeader("METHOD")) {
                    Text(articleMarkdown: "The fasting day begins before dawn with a recommended Sunnah meal called **Suhoor** (سُحُور) and ends at sunset with **Iftar** (إِفطَار), traditionally breaking the fast with dates and water as Prophet Muhammad did (peace and blessings be upon him) (Sunan Abi Dawud 2356; graded hasan sahih by al-Albani).")
                        .font(.body)

                    Text(verbatim: "During the fasting hours, Muslims engage in acts of worship such as prayer, Quran recitation, and charity.").font(.body)
                }

                Section(header: ArticleHeader("EXEMPTIONS")) {
                    Text(verbatim: "Fasting is mandatory for all capable Muslims, but there are exemptions for:")
                        .font(.body)
                    Text(verbatim: "1. The sick.").font(.body)
                    Text(verbatim: "2. Travelers.").font(.body)
                    Text(verbatim: "3. Pregnant or nursing women.").font(.body)
                    Text(verbatim: "4. Women during menstruation.").font(.body)
                    Text(articleMarkdown: "Those exempted are required to make up the missed fasts later or pay **fidya (فِديَة)**, compensation, if they cannot fast.")
                        .font(.body)
                }

                Section(header: ArticleHeader("SPIRITUAL BENEFITS")) {
                    Text(verbatim: "Sawm is a means of spiritual growth and self-discipline. It helps Muslims focus on worship, gratitude, and reliance on Allah (Glorified and Exalted be He). It also fosters empathy for the less fortunate and strengthens the sense of community. Prophet Muhammad (peace and blessings be upon him) said: ")
                        .font(.body)

                    ScriptureQuote(text: "“Verily, the smell of the mouth of a fasting person is better to Allah than the smell of musk” (Sahih al-Bukhari 5927)", arabic: "وَلَخَلُوفُ فَمِ الصَّائِمِ أَطْيَبُ عِنْدَ اللَّهِ مِنْ رِيحِ الْمِسْكِ", dimmed: true)
                }

                Section(header: ArticleHeader("REWARDS OF FASTING")) {
                    Text(verbatim: "The Prophet Muhammad (peace and blessings be upon him) also said:").font(.body)
                    ScriptureQuote(text: "“Whoever observes fasts during the month of Ramadan out of sincere faith, and hoping to attain Allah's rewards, then all his past sins will be forgiven” (Sahih al-Bukhari 38).", arabic: "مَنْ صَامَ رَمَضَانَ إِيمَانًا وَاحْتِسَابًا غُفِرَ لَهُ مَا تَقَدَّمَ مِنْ ذَنْبِهِ", dimmed: true)

                    Text(verbatim: "Fasting is an act of worship that purifies the heart and brings immense spiritual rewards from Allah.")
                        .font(.body)
                }

                Section(header: ArticleHeader("SIGNIFICANCE OF RAMADAN")) {
                    Text(articleMarkdown: "Ramadan is not only the month of fasting but also the month in which the Quran was revealed. It is a time of intense worship and reflection, culminating in **Laylat al-Qadr (لَيلَة القَدر)**, the Night of Decree, which is better than a thousand months.")
                        .font(.body)

                    Text(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                    ScriptureQuote(text: "“Indeed, We sent the Quran down during the Night of Decree. And what can make you know what is the Night of Decree? The Night of Decree is better than a thousand months” (Quran 97:1-3).", arabic: "إِنَّآ أَنزَلۡنَٰهُ فِي لَيۡلَةِ ٱلۡقَدۡرِ ۝ وَمَآ أَدۡرَىٰكَ مَا لَيۡلَةُ ٱلۡقَدۡرِ ۝ لَيۡلَةُ ٱلۡقَدۡرِ خَيۡرٞ مِّنۡ أَلۡفِ شَهۡرٖ")
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "More than hunger, fasting trains the soul, deepens gratitude and empathy for the poor, and earns great reward and the forgiveness of past sins.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "ZakahView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("Sawm")
    }
}

struct ZakahView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Zakah is an obligatory charity (2.5% of qualifying wealth held for a lunar year) that purifies wealth and supports those in need.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "**Zakah (زَكَاة)**, from the root **z-k-w (ز ك و)** meaning “purification” and “growth,” is the third pillar of Islam. It is an obligatory charity that purifies wealth, acknowledges Allah’s blessings, and helps build a just and compassionate society.")
                        .font(.body)

                    Text(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                    ScriptureQuote(text: "“Take, [O, Muhammad], from their wealth a charity by which you purify them and cause them increase, and invoke [Allah 's blessings] upon them. Indeed, your invocations are reassurance for them. And Allah is Hearing and Knowing” (Quran 9:103).", arabic: "خُذۡ مِنۡ أَمۡوَٰلِهِمۡ صَدَقَةٗ تُطَهِّرُهُمۡ وَتُزَكِّيهِم بِهَا وَصَلِّ عَلَيۡهِمۡۖ إِنَّ صَلَوٰتَكَ سَكَنٞ لَّهُمۡۗ وَٱللَّهُ سَمِيعٌ عَلِيمٌ")
                }

                Section(header: ArticleHeader("PURPOSE")) {
                    Text(verbatim: "The purpose of Zakah is threefold:").font(.body)
                    Text(articleMarkdown: "1. **Spiritual Purification**: Cleanses the soul from greed and materialism, fostering gratitude to Allah (Glorified and Exalted be He).").font(.body)
                    Text(articleMarkdown: "2. **Economic Justice**: Redistributes wealth to support those in need, reducing poverty and inequality.").font(.body)
                    Text(articleMarkdown: "3. **Community Strengthening**: Strengthens ties within the Muslim community by helping the less fortunate.").font(.body)
                }

                Section(header: ArticleHeader("OBLIGATIONS AND ELIGIBILITY")) {
                    Text(articleMarkdown: "Zakah is obligatory for every Muslim who possesses wealth above the **Nisab (نِصَاب)** (minimum threshold of wealth) for a full lunar year. The Nisab is calculated based on the value of 85 grams of gold or 595 grams of silver.")
                        .font(.body)

                    Text(verbatim: "Allah (Glorified and Exalted be He) specifies eight categories of Zakah recipients in the Quran:").font(.body)
                    ScriptureQuote(text: "“Zakah expenditures are only for the poor and for the needy and for those employed to collect [zakah] and for bringing hearts together [for Islam] and for freeing captives [or slaves] and for those in debt and for the cause of Allah and for the [stranded] traveler” (Quran 9:60).", arabic: "إِنَّمَا ٱلصَّدَقَٰتُ لِلۡفُقَرَآءِ وَٱلۡمَسَٰكِينِ وَٱلۡعَٰمِلِينَ عَلَيۡهَا وَٱلۡمُؤَلَّفَةِ قُلُوبُهُمۡ وَفِي ٱلرِّقَابِ وَٱلۡغَٰرِمِينَ وَفِي سَبِيلِ ٱللَّهِ وَٱبۡنِ ٱلسَّبِيلِۖ")
                }

                Section(header: ArticleHeader("CALCULATION")) {
                    Text(articleMarkdown: "Zakah is calculated at a standard rate of **2.5%** of one’s total savings and assets that meet the Nisab threshold. This includes cash, gold, silver, investments, and business assets.")
                        .font(.body)
                    Text(verbatim: "Zakah falls due when a full lunar year has passed on the wealth, and it must not be delayed once due. It may be paid early, and many choose to bring it forward to Ramadan for the extra reward.")
                        .font(.body)
                }

                Section(header: ArticleHeader("REWARDS OF ZAKAH")) {
                    Text(verbatim: "The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“Charity does not decrease wealth, no one forgives another except that Allah increases his honor, and no one humbles himself for the sake of Allah except that Allah raises his status” (Sahih Muslim 2588).", arabic: "مَا نَقَصَتْ صَدَقَةٌ مِنْ مَالٍ وَمَا زَادَ اللَّهُ عَبْدًا بِعَفْوٍ إِلاَّ عِزًّا وَمَا تَوَاضَعَ أَحَدٌ لِلَّهِ إِلاَّ رَفَعَهُ اللَّهُ", dimmed: true)

                    Text(verbatim: "He also said:").font(.body)
                    ScriptureQuote(text: "“Save yourself from Hell-fire even by giving half a date-fruit in charity” (Sahih al-Bukhari 1417).", arabic: "اتَّقُوا النَّارَ وَلَوْ بِشِقِّ تَمْرَةٍ", dimmed: true)

                    Text(verbatim: "Fulfilling the obligation of Zakah not only earns Allah’s pleasure but also protects one’s soul and wealth from harm.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "By giving what is due, a Muslim cleanses wealth of greed, strengthens the community, and earns Allah's blessing and increase.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "HajjView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("Zakah")
    }
}

struct HajjView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Hajj is the pilgrimage to the Kaaba in Makkah, obligatory once in a lifetime for those able: a journey of submission, forgiveness, and unity.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "**Hajj (حَجّ)**, from the root **h-j-j (ح ج ج)** meaning “to intend” or “to set out for” a great destination, is the fifth and final pillar of Islam. It is the pilgrimage to the **Kaaba (الكَعبَة)** in Makkah (the **Qibla (قِبلَة)**, the direction of prayer, for Muslims worldwide), performed annually in the month of **Dhul-Hijjah (ذُو الحِجَّة)** as a profound act of worship and submission to Allah (Glorified and Exalted be He).")
                        .font(.body)

                    Text(verbatim: "Hajj is a journey of spiritual renewal, forgiveness, and unity among Muslims, symbolizing submission to Allah and the equality of all believers.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OBLIGATION")) {
                    Text(verbatim: "Hajj is mandatory for every Muslim who is physically and financially capable at least once in their lifetime. Allah (Glorified and Exalted be He) says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“And [due] to Allah from the people is a pilgrimage to the House – for whoever is able to find thereto a way. But whoever disbelieves – then indeed, Allah is free from need of the worlds” (Quran 3:97).", arabic: "وَلِلَّهِ عَلَى ٱلنَّاسِ حِجُّ ٱلۡبَيۡتِ مَنِ ٱسۡتَطَاعَ إِلَيۡهِ سَبِيلٗاۚ وَمَن كَفَرَ فَإِنَّ ٱللَّهَ غَنِيٌّ عَنِ ٱلۡعَٰلَمِينَ")

                    Text(verbatim: "Hajj is both a personal and communal act of worship, emphasizing the importance of fulfilling one's obligations to Allah and the global Muslim community.")
                        .font(.body)
                }

                Section(header: ArticleHeader("HISTORICAL ROOTS")) {
                    Text(verbatim: "Hajj commemorates the unwavering faith and sacrifices of Prophet Ibrahim (Abraham, peace be upon him), his wife Hajar (may Allah be pleased with her), and their son Prophet Ismail (Ishmael, peace be upon him).")
                        .font(.body)

                    Text(verbatim: "Prophet Ibrahim (peace be upon him) and Prophet Ismail (peace be upon him) were commanded by Allah to build the Kaaba, the sacred House of Allah. Allah says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“And [mention] when Abraham was raising the foundations of the House and [with him] Ishmael, [saying], ‘Our Lord, accept [this] from us. Indeed You are the Hearing, the Knowing.’” (Quran 2:127).", arabic: "وَإِذۡ يَرۡفَعُ إِبۡرَٰهِـۧمُ ٱلۡقَوَاعِدَ مِنَ ٱلۡبَيۡتِ وَإِسۡمَٰعِيلُ رَبَّنَا تَقَبَّلۡ مِنَّآۖ إِنَّكَ أَنتَ ٱلسَّمِيعُ ٱلۡعَلِيمُ")

                    Text(verbatim: "The rituals of Hajj also commemorate Hajar's (may Allah be pleased with her) trust in Allah as she searched for water for her infant son, Ismail. Her desperate search between the hills of Safa and Marwah is reenacted during Hajj as the Sa’i.")
                        .font(.body)
                }

                Section(header: ArticleHeader("RITUALS OF HAJJ")) {
                    Text(verbatim: "The key rituals of Hajj include:").font(.body)
                    Text(articleMarkdown: "1. **Ihram (إِحرَام)**: entering a state of purity and wearing special garments.").font(.body)
                    Text(articleMarkdown: "2. **Tawaf (طَوَاف)**: circling the Kaaba seven times in reverence.").font(.body)
                    Text(articleMarkdown: "3. **Sa'i (سَعي)**: walking between the hills of Safa and Marwah, commemorating Hajar’s (may Allah be pleased with her) search for water.").font(.body)
                    Text(articleMarkdown: "4. **Arafat (عَرَفَات)**: standing in prayer and supplication at the Plain of Arafat, seeking Allah’s forgiveness.").font(.body)
                    Text(articleMarkdown: "5. **Ramy al-Jamarat (رَمي الجَمَرَات)**: throwing pebbles at the pillars in Mina, symbolizing rejection of the devil’s temptations.").font(.body)
                    Text(articleMarkdown: "6. **Qurbani (قُربَان)**: sacrificing an animal to commemorate Prophet Ibrahim’s (peace be upon him) willingness to sacrifice his son for Allah’s command.").font(.body)
                    Text(articleMarkdown: "7. **Tawaf al-Ifadah (طَوَاف الإِفَاضَة)**: the obligatory circumambulation of the Kaaba after the Day of Arafah, a pillar of Hajj. Before leaving Makkah the pilgrim also performs **Tawaf al-Wada' (طَوَاف الوَدَاع)**, the farewell tawaf.").font(.body)
                }

                Section(header: ArticleHeader("SPIRITUAL PURPOSE")) {
                    Text(verbatim: "Hajj represents submission to Allah and a renewal of faith. It unites Muslims from diverse backgrounds in worship, showcasing the universal brotherhood of Islam.")
                        .font(.body)

                    Text(verbatim: "The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“Whoever performs Hajj for Allah's pleasure and does not have sexual relations with his wife, and does not do evil or sins then he will return (after Hajj free from all sins) as if he were born anew” (Sahih al-Bukhari 1521).", arabic: "مَنْ حَجَّ لِلَّهِ فَلَمْ يَرْفُثْ وَلَمْ يَفْسُقْ رَجَعَ كَيَوْمِ وَلَدَتْهُ أُمُّهُ", dimmed: true)
                }

                Section(header: ArticleHeader("CONCLUSION")) {
                    Text(verbatim: "Hajj is a profound spiritual journey that strengthens a Muslim’s connection with Allah (Glorified and Exalted be He). By performing Hajj, Muslims fulfill one of the greatest acts of worship, seeking Allah’s mercy, forgiveness, and eternal reward.")
                        .font(.body)

                    Text(verbatim: "Allah says in the Quran:").font(.body)
                    ScriptureQuote(text: "“And proclaim to the people the Hajj [pilgrimage]; they will come to you on foot and on every lean camel; they will come from every distant pass” (Quran 22:27).", arabic: "وَأَذِّن فِي ٱلنَّاسِ بِٱلۡحَجِّ يَأۡتُوكَ رِجَالٗا وَعَلَىٰ كُلِّ ضَامِرٖ يَأۡتِينَ مِن كُلِّ فَجٍّ عَمِيقٖ")
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Retracing the legacy of Ibrahim and his family, Hajj gathers Muslims of every background as equals before Allah, returning the sincere pilgrim cleansed of sin.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "GodView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("Hajj")
    }
}

import SwiftUI

struct GodView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: the first pillar of faith is to believe in Allah alone: His Lordship, His sole right to worship, and His perfect Names and attributes.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "Belief in Allah (Glorified and Exalted be He), the One and Only God, is the core of Islamic faith, **Iman (إِيمَان)**. He is the Creator and Sustainer of the entire universe. He is eternal, self-sustaining, and has no equal. Allah (Glorified and Exalted be He) says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“Say, ‘He is Allah, [who is] One, Allah, the Eternal Refuge. He neither begets nor is born, nor is there to Him any equivalent.’” (Quran 112:1-4)", arabic: "قُلۡ هُوَ ٱللَّهُ أَحَدٌ ۝ ٱللَّهُ ٱلصَّمَدُ ۝ لَمۡ يَلِدۡ وَلَمۡ يُولَدۡ ۝ وَلَمۡ يَكُن لَّهُۥ كُفُوًا أَحَدُۢ")

                    Text(articleMarkdown: "This chapter, **Surah Al-Ikhlas (الإِخلَاص)**, summarizes Allah’s Oneness and clarifies that He does not share His divine attributes with any of His creation. Muslims affirm that He is All-Knowing, All-Merciful, and above all limitations.")
                        .font(.body)
                }

                Section(header: ArticleHeader("MEANING OF BELIEF IN ALLAH")) {
                    Text(articleMarkdown: "Belief in Allah, **al-Iman billah (الإِيمَان بِاللَّه)**, involves affirming His Oneness, **Tawhid (تَوحِيد)**, and understanding His divine attributes. It consists of three core aspects:")
                        .font(.body)
                    Text(articleMarkdown: "1. **Tawhid al-Rububiyyah (تَوحِيد الرُّبُوبِيَّة)**, Oneness of Lordship: Believing that Allah alone is the Creator, Sustainer, and Manager of all that exists.")
                        .font(.body)
                    Text(articleMarkdown: "2. **Tawhid al-Uluhiyyah (تَوحِيد الأُلُوهِيَّة)**, Oneness of Worship: Worshiping Allah alone without associating partners with Him.")
                        .font(.body)
                    Text(articleMarkdown: "3. **Tawhid al-Asma wa al-Sifat (تَوحِيد الأَسمَاء وَالصِّفَات)**, Oneness of Names and Attributes: Affirming Allah’s names and attributes as mentioned in the Quran and Sunnah, without distortion or anthropomorphism.")
                        .font(.body)
                }

                Section(header: ArticleHeader("QURANIC EVIDENCE")) {
                    Text(verbatim: "Allah (Glorified and Exalted be He) repeatedly emphasizes His Oneness and supremacy in the Quran. He says:")
                        .font(.body)
                    ScriptureQuote(text: "“Allah - there is no deity except Him, the Ever-Living, the Sustainer of [all] existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth” (Quran 2:255, Ayat al-Kursi).", arabic: "ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ ٱلۡحَيُّ ٱلۡقَيُّومُۚ لَا تَأۡخُذُهُۥ سِنَةٞ وَلَا نَوۡمٞۚ لَّهُۥ مَا فِي ٱلسَّمَٰوَٰتِ وَمَا فِي ٱلۡأَرۡضِۗ")

                    ScriptureQuote(text: "“And your god is one God. There is no deity [worthy of worship] except Him, the Entirely Merciful, the Especially Merciful” (Quran 2:163).", arabic: "وَإِلَٰهُكُمۡ إِلَٰهٞ وَٰحِدٞۖ لَّآ إِلَٰهَ إِلَّا هُوَ ٱلرَّحۡمَٰنُ ٱلرَّحِيمُ")
                }

                Section(header: ArticleHeader("HADITH ON BELIEF IN ALLAH")) {
                    Text(verbatim: "The Prophet Muhammad (peace and blessings be upon him) explained the essence of belief in Allah. He said:")
                        .font(.body)
                    ScriptureQuote(text: "“Inform me about Iman (faith). He (the Holy Prophet) replied: That you affirm your faith in Allah, in His angels, in His Books, in His Apostles, in the Day of Judgment, and you affirm your faith in the Divine Decree about good and evil” (Sahih Muslim 8a).", arabic: "أَنْ تُؤْمِنَ بِاللَّهِ وَمَلاَئِكَتِهِ وَكُتُبِهِ وَرُسُلِهِ وَالْيَوْمِ الآخِرِ وَتُؤْمِنَ بِالْقَدَرِ خَيْرِهِ وَشَرِّهِ", dimmed: true)
                }

                Section(header: ArticleHeader("IMPORTANCE OF BELIEF IN ALLAH")) {
                    Text(verbatim: "Belief in Allah is the foundation of a Muslim’s faith and actions. It shapes a person’s worldview, guiding them to trust Allah, obey His commands, and rely on His mercy and justice.")
                        .font(.body)

                    Text(articleMarkdown: "This belief inspires **Taqwa (تَقوَى)**, God-consciousness, motivating Muslims to live righteously and strive for Allah’s pleasure in every aspect of their lives.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Belief in Allah anchors a Muslim's whole life: to trust Him, obey Him, and worship Him alone without any partner.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "AngelsView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("Belief in Allah")
    }
}

struct AngelsView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: the angels are unseen beings created from light who never disobey Allah and carry out His commands throughout creation.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "Belief in the angels, **Malaikah (مَلَائِكَة)**, is a fundamental pillar of Islamic faith, **Iman (إِيمَان)**. Angels are unseen beings created by Allah (Glorified and Exalted be He) from light. They are sinless, do not have free will, and continuously obey Allah’s commands. Their roles include delivering revelations, recording deeds, and carrying out Allah’s orders in the universe. Allah, however, does not need angels or anything else, as He is completely self-sufficient, **Al-Ghaniyy (الغَنِيّ)**, and sustains all existence, **Al-Qayyum (القَيُّوم)**. The creation of angels reflects Allah’s wisdom and His divine plan.")
                        .font(.body)

                    Text(verbatim: "The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“The Angels were born out of light” (Sahih Muslim 2996).", arabic: "خُلِقَتِ الْمَلاَئِكَةُ مِنْ نُورٍ وَخُلِقَ الْجَانُّ مِنْ مَارِجٍ مِنْ نَارٍ وَخُلِقَ آدَمُ مِمَّا وُصِفَ لَكُمْ", dimmed: true)
                }

                Section(header: ArticleHeader("CHARACTERISTICS OF ANGELS")) {
                    Text(verbatim: "Angels possess unique attributes that set them apart from other creations:")
                        .font(.body)

                    Text(articleMarkdown: "1. **Created from Light**: Unlike humans and jinn, angels are made of light.")
                        .font(.body)
                    Text(articleMarkdown: "2. **Infallible Obedience**: They never disobey Allah and do exactly as commanded. Allah says in the Quran:")
                        .font(.body)
                    ScriptureQuote(text: "“They do not disobey Allah in what He commands them but do what they are commanded” (Quran 66:6).", arabic: "لَّا يَعۡصُونَ ٱللَّهَ مَآ أَمَرَهُمۡ وَيَفۡعَلُونَ مَا يُؤۡمَرُونَ")
                    Text(articleMarkdown: "3. **Invisible to Humans**: Although normally unseen, they can appear in human form, as Angel Jibril (Gabriel) did when he visited the Prophet Muhammad (peace and blessings be upon him).")
                        .font(.body)
                    Text(articleMarkdown: "4. **Lack of Free Will**: Angels exist solely to serve Allah and cannot deviate from their roles.")
                        .font(.body)
                }

                Section(header: ArticleHeader("ROLES AND RESPONSIBILITIES")) {
                    Text(verbatim: "Angels have distinct duties, demonstrating Allah’s meticulous organization of creation:")
                        .font(.body)

                    Text(articleMarkdown: "1. **Jibril (Gabriel)**: The angel of revelation who conveyed Allah’s messages to the prophets, including the Quran to Prophet Muhammad (peace and blessings be upon him). Allah says:")
                        .font(.body)
                    ScriptureQuote(text: "“Say, ‘Whoever is an enemy to Gabriel - it is [none but] he who has brought the Qur'an down upon your heart, [O Muhammad], by permission of Allah, confirming that which was before it and as guidance and good tidings for the believers.’” (Quran 2:97)", arabic: "قُلۡ مَن كَانَ عَدُوّٗا لِّـجِبۡرِيلَ فَإِنَّهُۥ نَزَّلَهُۥ عَلَىٰ قَلۡبِكَ بِإِذۡنِ ٱللَّهِ")

                    Text(articleMarkdown: "2. **Mikail (مِيكَائِيل)**, Michael: Responsible for provisions, including rain and sustenance.")
                        .font(.body)

                    Text(articleMarkdown: "3. **The Bearer of the Horn (صَاحِب الصُّور)**: the angel entrusted with the Trumpet, who will blow it to end the world and again for the resurrection (Sunan al-Tirmidhi 2431; graded sahih by al-Albani). The name “Israfil” is common in later works but is not established in the Quran or the authentic Sunnah.")
                        .font(.body)

                    Text(articleMarkdown: "4. **Malik (مَالِك)**: The guardian of Hellfire. Allah says:")
                        .font(.body)
                    ScriptureQuote(text: "“And they will call, ‘O Malik, let your Lord put an end to us!’ He will say, ‘Indeed, you will remain.’” (Quran 43:77)", arabic: "وَنَادَوۡاْ يَٰمَٰلِكُ لِيَقۡضِ عَلَيۡنَا رَبُّكَۖ قَالَ إِنَّكُم مَّٰكِثُونَ")

                    Text(articleMarkdown: "5. **Kiraman Katibin (كِرَامًا كَاتِبِين)**: Angels who record every deed:")
                        .font(.body)
                    ScriptureQuote(text: "“Man does not utter any word except that with him is an observer prepared [to record]” (Quran 50:18).", arabic: "مَّا يَلۡفِظُ مِن قَوۡلٍ إِلَّا لَدَيۡهِ رَقِيبٌ عَتِيدٞ")

                    Text(articleMarkdown: "6. **Munkar and Nakir (مُنكَر وَنَكِير)**: Angels who question the deceased in their graves about their faith. The Prophet (peace and blessings be upon him) named them in the hadith of the questioning in the grave (Jami' at-Tirmidhi 1071; graded hasan by al-Albani).")
                        .font(.body)

                    Text(articleMarkdown: "7. **The Keeper of Paradise (خَازِن الجَنَّة)**: an angel appointed over its gates. The authentic hadith calls him only “the keeper”; the name “Ridwan” is widely known among later scholars but is not established in the Quran or the authentic Sunnah. The Prophet (peace and blessings be upon him) said:")
                        .font(.body)
                    ScriptureQuote(text: "“I will come to the gate of Paradise on the Day of Resurrection. and would seek its opening. and the keeper would say: Who art thou? I would say: Muhammad. He would then say: It is for thee that I have been ordered, and not to open it for anyone before thee” (Sahih Muslim 197).", arabic: "آتِي بَابَ الْجَنَّةِ يَوْمَ الْقِيَامَةِ فَأَسْتَفْتِحُ فَيَقُولُ الْخَازِنُ مَنْ أَنْتَ فَأَقُولُ مُحَمَّدٌ. فَيَقُولُ بِكَ أُمِرْتُ لاَ أَفْتَحُ لأَحَدٍ قَبْلَكَ", dimmed: true)
                }

                Section(header: ArticleHeader("IMPORTANCE OF BELIEF IN ANGELS")) {
                    Text(verbatim: "Belief in angels is the second pillar of Iman and is crucial for a complete understanding of Islam. It has profound implications for a Muslim’s faith:")
                        .font(.body)

                    Text(articleMarkdown: "1. **Strengthens Taqwa**: Awareness of recording angels motivates Muslims to be mindful of their actions.")
                        .font(.body)
                    Text(articleMarkdown: "2. **Demonstrates Allah’s Sovereignty**: Angels fulfill Allah’s commands, showcasing His power and control over creation.")
                        .font(.body)
                    Text(articleMarkdown: "3. **Connection to Revelation**: Through Angel Jibril, Allah’s guidance was conveyed to humanity.")
                        .font(.body)
                }

                Section(header: ArticleHeader("HADITH ON ANGELS")) {
                    Text(verbatim: "The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“If Allah loves a person, He calls Gabriel, saying, 'Allah loves so and so, O Gabriel love him' So Gabriel would love him and then would make an announcement in the Heavens: 'Allah has loved so and-so therefore you should love him also.' So all the dwellers of the Heavens would love him, and then he is granted the pleasure of the people on the earth” (Sahih al-Bukhari 7485).", arabic: "إِنَّ اللَّهَ تَبَارَكَ وَتَعَالَى إِذَا أَحَبَّ عَبْدًا نَادَى جِبْرِيلَ إِنَّ اللَّهَ قَدْ أَحَبَّ فُلاَنًا فَأَحِبَّهُ فَيُحِبُّهُ جِبْرِيلُ، ثُمَّ يُنَادِي جِبْرِيلُ فِي السَّمَاءِ إِنَّ اللَّهَ قَدْ أَحَبَّ فُلاَنًا فَأَحِبُّوهُ، فَيُحِبُّهُ أَهْلُ السَّمَاءِ وَيُوضَعُ لَهُ الْقَبُولُ فِي أَهْلِ الأَرْضِ", dimmed: true)
                }

                Section(header: ArticleHeader("CONCLUSION")) {
                    Text(verbatim: "Angels are integral to the Islamic understanding of the unseen world. Their obedience, dedication, and specific roles serve as a reminder of Allah’s omnipotence and meticulous care in organizing creation. Belief in angels strengthens a Muslim’s faith, instilling awe and awareness of the divine presence in all aspects of life.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Belief in the angels deepens awe of Allah's dominion and the awareness that our words and deeds are seen and recorded.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "BooksView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("Belief in the Angels")
    }
}

struct BooksView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Allah revealed scriptures to His prophets (including the Torah, Psalms, and Gospel), culminating in the Quran, the final and preserved revelation.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(verbatim: "Allah (Glorified and Exalted be He) revealed divine scriptures to various prophets. These scriptures were sent to guide humanity to righteousness and worship of Allah alone. They include the Scrolls of Ibrahim (Abraham, peace be upon him), the Torah given to Musa (Moses, peace be upon him), the Psalms given to Dawud (David, peace be upon him), the Gospel given to Isa (Jesus, peace be upon him), and the Quran given to Muhammad (peace and blessings be upon him).")
                        .font(.body)

                    Text(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                    ScriptureQuote(text: "“Indeed, We sent down the Torah, in which was guidance and light” (Quran 5:44).", arabic: "إِنَّآ أَنزَلۡنَا ٱلتَّوۡرَىٰةَ فِيهَا هُدٗى وَنُورٞۚ")

                    Text(verbatim: "Each scripture served as a guide for its respective nation and time, culminating in the Quran, which is the final and universal revelation.")
                        .font(.body)
                }

                Section(header: ArticleHeader("THE QURAN")) {
                    Text(articleMarkdown: "The **Quran (القُرآن)**, meaning “the Recitation,” is the final and complete revelation from Allah, sent to all of humanity through the Prophet Muhammad (peace and blessings be upon him). It is preserved word for word, as Allah has promised:")
                        .font(.body)
                    ScriptureQuote(text: "“Indeed, it is We who sent down the Quran and indeed, We will be its guardian” (Quran 15:9).", arabic: "إِنَّا نَحۡنُ نَزَّلۡنَا ٱلذِّكۡرَ وَإِنَّا لَهُۥ لَحَٰفِظُونَ")

                    Text(verbatim: "The Quran confirms and corrects previous scriptures while providing comprehensive guidance for all aspects of life. It remains unchanged since its revelation and is recited, memorized, and revered by Muslims worldwide.")
                        .font(.body)
                }

                Section(header: ArticleHeader("PREVIOUS SCRIPTURES")) {
                    Text(articleMarkdown: "1. **Tawrah (التَّورَاة)**, the Torah: Revealed to Musa (Moses, peace be upon him), it contained laws and guidance for the Children of Israel. Over time, the original text was altered, and its authenticity was compromised.")
                        .font(.body)

                    Text(articleMarkdown: "2. **Zabur (الزَّبُور)**, the Psalms: Revealed to Dawud (David, peace be upon him), it was a collection of hymns and praises dedicated to Allah.")
                        .font(.body)

                    Text(articleMarkdown: "3. **Injil (الإِنجِيل)**, the Gospel: Revealed to Isa (Jesus, peace be upon him), it confirmed the Torah and brought new guidance. However, the original Gospel has been lost, and what exists today are interpretations and altered accounts.")
                        .font(.body)

                    Text(articleMarkdown: "4. **Suhuf (صُحُف)**, the Scrolls: Revealed to Ibrahim (Abraham, peace be upon him) and Musa (Moses, peace be upon him), these contained foundational teachings and guidance. They are mentioned in the Quran but no longer exist.")
                        .font(.body)

                    Text(verbatim: "Allah (Glorified and Exalted be He) says:").font(.body)
                    ScriptureQuote(text: "“Indeed, this is in the former scriptures, the scriptures of Abraham and Moses” (Quran 87:18-19).", arabic: "إِنَّ هَٰذَا لَفِي ٱلصُّحُفِ ٱلۡأُولَىٰ ۝ صُحُفِ إِبۡرَٰهِيمَ وَمُوسَىٰ")
                }

                Section(header: ArticleHeader("IMPORTANCE OF BELIEVING IN THE BOOKS")) {
                    Text(verbatim: "Belief in Allah’s books is a fundamental pillar of Iman (faith). The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“Inform me about Iman (faith). He (the Holy Prophet) replied: That you affirm your faith in Allah, in His angels, in His Books, in His Apostles, in the Day of Judgment, and you affirm your faith in the Divine Decree about good and evil” (Sahih Muslim 8a).", arabic: "أَنْ تُؤْمِنَ بِاللَّهِ وَمَلاَئِكَتِهِ وَكُتُبِهِ وَرُسُلِهِ وَالْيَوْمِ الآخِرِ وَتُؤْمِنَ بِالْقَدَرِ خَيْرِهِ وَشَرِّهِ", dimmed: true)

                    Text(articleMarkdown: "Each scripture taught monotheism, **Tawhid (تَوحِيد)**, and righteousness, serving as a guide for the people of its time. The Quran, as the final revelation, is universal and timeless, applicable to all of humanity until the Day of Judgment.")
                        .font(.body)
                }

                Section(header: ArticleHeader("DIFFERENCES BETWEEN SCRIPTURES")) {
                    Text(articleMarkdown: "1. **Preservation:** Unlike earlier scriptures, which were altered or lost, the Quran has been perfectly preserved as promised by Allah.")
                        .font(.body)

                    Text(articleMarkdown: "2. **Universality:** Previous scriptures were meant for specific nations and times, while the Quran is for all of humanity and all time.")
                        .font(.body)

                    Text(articleMarkdown: "3. **Completeness:** The Quran encompasses all necessary guidance, confirming and completing previous revelations.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Earlier scriptures guided their nations but were altered or lost; the Quran alone remains perfectly preserved as Allah's guidance for all time.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "ProphetsView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("Belief in the Books")
    }
}

struct ProphetsView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Allah sent prophets to call people to worship Him alone, from Adam to the final Messenger, Muhammad.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(verbatim: """
                    Allah sent prophets to every nation, and a Muslim believes in every one of them. Prophets were chosen by Allah to guide their communities to monotheism and righteous living. The Quran mentions 25 prophets by name:
                    - Adam: آدَم
                    - Idris (often identified with Enoch): إِدرِيس
                    - Nuh (Noah): نُوح
                    - Hud: هُود
                    - Saleh: صَالِح
                    - Lut (Lot): لُوط
                    - Ibrahim (Abraham): إِبرَاهِيم
                    - Ismail (Ishmael): إِسمَاعِيل
                    - Ishaq (Isaac): إِسحَاق
                    - Yaqub (Jacob): يَعقُوب
                    - Yusuf (Joseph): يُوسُف
                    - Shu’aib (sometimes identified with Jethro): شُعَيب
                    - Ayyub (Job): أَيُّوب
                    - Dhul-Kifl: ذُو الكِفل
                    - Musa (Moses): مُوسَى
                    - Harun (Aaron): هَارُون
                    - Dawud (David): دَاوُود
                    - Sulayman (Solomon): سُلَيمَان
                    - Ilyas (Elias): إِليَاس
                    - Alyasa (Elisha): اليَسَع
                    - Yunus (Jonah): يُونُس
                    - Zakariya (Zachariah): زَكَرِيَّا
                    - Yahya (John the Baptist): يَحيَى
                    - Isa (Jesus): عِيسَى
                    - Muhammad: مُحَمَّد
                    """)
                    .font(.body)

                    Text(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                    ScriptureQuote(text: "“And We gave to Abraham, Isaac and Jacob - all [of them] We guided. And Noah We guided before; and among his descendants, David and Solomon and Job and Joseph and Moses and Aaron. Thus do We reward the doers of good. And Zechariah and John and Jesus and Elias - and all were of the righteous” (Quran 6:84-85).", arabic: "وَوَهَبۡنَا لَهُۥٓ إِسۡحَٰقَ وَيَعۡقُوبَۚ كُلًّا هَدَيۡنَاۚ وَنُوحًا هَدَيۡنَا مِن قَبۡلُۖ وَمِن ذُرِّيَّتِهِۦ دَاوُۥدَ وَسُلَيۡمَٰنَ وَأَيُّوبَ وَيُوسُفَ وَمُوسَىٰ وَهَٰرُونَۚ وَكَذَٰلِكَ نَجۡزِي ٱلۡمُحۡسِنِينَ ۝ وَزَكَرِيَّا وَيَحۡيَىٰ وَعِيسَىٰ وَإِلۡيَاسَۖ كُلّٞ مِّنَ ٱلصَّٰلِحِينَ")

                    Text(verbatim: "Each prophet conveyed Allah’s guidance and served as role models for their people. While all prophets were sent to specific nations and times, Prophet Muhammad was sent as the final messenger for all of humanity. Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                    ScriptureQuote(text: "“Muhammad is not the father of [any] one of your men, but [he is] the Messenger of Allah and last of the prophets” (Quran 33:40).", arabic: "مَّا كَانَ مُحَمَّدٌ أَبَآ أَحَدٖ مِّن رِّجَالِكُمۡ وَلَٰكِن رَّسُولَ ٱللَّهِ وَخَاتَمَ ٱلنَّبِيِّـۧنَۗ")
                }

                Section(header: ArticleHeader("PROPHETS AND MESSENGERS")) {
                    Text(articleMarkdown: "There is a distinction between a prophet, **Nabi (نَبِيّ)**, and a messenger, **Rasul (رَسُول)**:").font(.body)

                    Text(articleMarkdown: "1. **Prophet, Nabi (نَبِيّ):** From the root **n-b-a (ن ب أ)**, to bring news. A prophet receives revelation from Allah. One common explanation is that he upholds and reinforces the law of a previous messenger; the scholars differ on the exact distinction between the two terms.").font(.body)
                    Text(verbatim: "Every messenger is also a prophet, but not every prophet is a messenger. The Quran uses both titles for some, calling Harun (هَارُون), Aaron, a messenger alongside Musa (مُوسَى), Moses (Quran 20:47), while the prophets sent to Bani Isra'il after Musa judged by the Torah already revealed.").font(.body)

                    Text(articleMarkdown: "2. **Messenger, Rasul (رَسُول):** From the root **r-s-l (ر س ل)**, to send. A messenger is sent with a message to a people, often with a new scripture or divine law.").font(.body)
                    Text(verbatim: "Example: Muhammad (مُحَمَّد) was a messenger who brought the Quran, the final revelation.").font(.body)

                    Text(verbatim: "Every messenger is a prophet, but not every prophet is a messenger. Belief in them is not selective: to reject one prophet is to reject them all, because the One who sent them is One.").font(.body)
                }

                Section(header: ArticleHeader("THE CHILDREN OF ISRAEL")) {
                    Text(articleMarkdown: "More prophets were sent to the **Children of Israel, Bani Israil (بَنِي إِسرَائِيل)**, than to any other people. Allah favoured them openly, and the Quran says so:")
                        .font(.body)
                    ScriptureQuote(text: "“O Children of Israel, remember My favor that I have bestowed upon you and that I preferred you over the worlds” (Quran 2:47).", arabic: "يَٰبَنِيٓ إِسۡرَٰٓءِيلَ ٱذۡكُرُواْ نِعۡمَتِيَ ٱلَّتِيٓ أَنۡعَمۡتُ عَلَيۡكُمۡ وَأَنِّي فَضَّلۡتُكُمۡ عَلَى ٱلۡعَٰلَمِينَ")

                    Text(articleMarkdown: "That favour came with a **covenant, Mithaq (مِيثَاق)**: to worship Allah alone, to uphold the Torah, and to obey the prophets sent to them. The favour was never a birthright. It was a trust, and a trust can be broken.")
                        .font(.body)

                    Text(verbatim: "They broke it repeatedly. They worshipped the calf while Musa (peace be upon him) was away, they demanded to see Allah openly, they refused to enter the land they were commanded to enter, and they twisted the words of the scripture from their places. Worst of all, when the prophets came to them with what they did not want to hear, they rejected them, and they killed them. Allah says:")
                        .font(.body)
                    ScriptureQuote(text: "“And they were covered with humiliation and poverty and returned with anger from Allah [upon them]. That was because they [repeatedly] disbelieved in the signs of Allah and killed the prophets without right. That was because they disobeyed and were [habitually] transgressing” (Quran 2:61).", arabic: "وَضُرِبَتۡ عَلَيۡهِمُ ٱلذِّلَّةُ وَٱلۡمَسۡكَنَةُ وَبَآءُو بِغَضَبٖ مِّنَ ٱللَّهِۚ ذَٰلِكَ بِأَنَّهُمۡ كَانُواْ يَكۡفُرُونَ بِـَٔايَٰتِ ٱللَّهِ وَيَقۡتُلُونَ ٱلنَّبِيِّـۧنَ بِغَيۡرِ ٱلۡحَقِّۚ ذَٰلِكَ بِمَا عَصَواْ وَّكَانُواْ يَعۡتَدُونَ")

                    Text(verbatim: "Historical reports mention Zakariya and Yahya (peace be upon them) among the prophets who were killed, and the Quran records their plot against Isa (peace be upon him), though Allah raised him to Himself and saved him from them.")
                        .font(.body)

                    Text(verbatim: "So the covenant was withdrawn from them and the message was carried on through the line of Ismail (إِسمَاعِيل), in Prophet Muhammad (peace and blessings be upon him). This is the crucial point: the covenant was never about lineage. It was about obedience. It was taken from them because of what they did, and it can be lost by anyone who does the same.")
                        .font(.body)

                    Text(verbatim: "This is a warning to the Muslims before it is a criticism of anyone else. Allah does not favour a people for their ancestry. He favours them for their taqwa, and He removes His favour when they abandon it.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IMPORTANCE OF BELIEF IN PROPHETS")) {
                    Text(articleMarkdown: "Belief in the prophets is a pillar of **Iman (إِيمَان)**, faith. The Prophet Muhammad said:").font(.body)
                    ScriptureQuote(text: "“Inform me about Iman (faith). He (the Holy Prophet) replied: That you affirm your faith in Allah, in His angels, in His Books, in His Apostles, in the Day of Judgment, and you affirm your faith in the Divine Decree about good and evil” (Sahih Muslim 8a).", arabic: "أَنْ تُؤْمِنَ بِاللَّهِ وَمَلاَئِكَتِهِ وَكُتُبِهِ وَرُسُلِهِ وَالْيَوْمِ الآخِرِ وَتُؤْمِنَ بِالْقَدَرِ خَيْرِهِ وَشَرِّهِ", dimmed: true)

                    Text(verbatim: "Muslims respect and honor all prophets equally, as they all conveyed the same message: to worship Allah alone. Allah (Glorified and Exalted be He) says:").font(.body)
                    ScriptureQuote(text: "“The Messenger has believed in what was revealed to him from his Lord, and [so have] the believers. All of them have believed in Allah and His angels and His books and His messengers” (Quran 2:285).", arabic: "ءَامَنَ ٱلرَّسُولُ بِمَآ أُنزِلَ إِلَيۡهِ مِن رَّبِّهِۦ وَٱلۡمُؤۡمِنُونَۚ كُلٌّ ءَامَنَ بِٱللَّهِ وَمَلَٰٓئِكَتِهِۦ وَكُتُبِهِۦ وَرُسُلِهِۦ")
                }

                Section(header: ArticleHeader("LEGACY OF PROPHETS")) {
                    Text(verbatim: "Prophets were sent to guide humanity and exemplify righteousness. Their lives demonstrate the highest moral and spiritual qualities. The Quran recounts their stories as lessons and reminders for believers.")
                        .font(.body)

                    Text(verbatim: "The final prophet, Muhammad, delivered the Quran and established a comprehensive way of life, leaving an eternal legacy of guidance for all humanity.")
                        .font(.body)
                }

                Section(header: ArticleHeader("RESOURCE")) {
                    Text(verbatim: "For a detailed family tree of the prophets: https://madinahmedia.com/family-tree-of-prophets-in-islam/")
                        .font(.caption)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "The prophets all brought one message (worship of Allah alone), and Muhammad sealed and completed that guidance for all humanity.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "DayView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("Belief in the Prophets")
    }
}

struct DayView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: on the Last Day, Allah will resurrect all people and judge them for their deeds with perfect justice.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "Belief in the Last Day, **Yawm al-Qiyamah (يَوم القِيَامَة)**, the Day of Resurrection, is a cornerstone of Islam and the fifth pillar of **Iman (إِيمَان)**, faith. It is the day when Allah (Glorified and Exalted be He) will resurrect all of creation to hold them accountable for their deeds. This belief is essential for understanding the purpose of life and the consequences of human actions.")
                        .font(.body)

                    Text(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                    ScriptureQuote(text: "“So whoever does an atom’s weight of good will see it, And whoever does an atom’s weight of evil will see it” (Quran 99:7-8).", arabic: "فَمَن يَعۡمَلۡ مِثۡقَالَ ذَرَّةٍ خَيۡرٗا يَرَهُۥ ۝ وَمَن يَعۡمَلۡ مِثۡقَالَ ذَرَّةٖ شَرّٗا يَرَهُۥ")
                }

                Section(header: ArticleHeader("EVENTS OF THE DAY")) {
                    Text(verbatim: "The Day of Judgment will unfold in stages, including:").font(.body)

                    Text(articleMarkdown: "1. **The Blowing of the Trumpet**: The angel entrusted with the Horn will blow the trumpet twice: first to end all life and then to resurrect everyone. Allah says:").font(.body)
                    ScriptureQuote(text: "“And the Horn will be blown, and whoever is in the heavens and whoever is on the earth will fall dead except whom Allah wills. Then it will be blown again, and at once they will be standing, looking on” (Quran 39:68).", arabic: "وَنُفِخَ فِي ٱلصُّورِ فَصَعِقَ مَن فِي ٱلسَّمَٰوَٰتِ وَمَن فِي ٱلۡأَرۡضِ إِلَّا مَن شَآءَ ٱللَّهُۖ ثُمَّ نُفِخَ فِيهِ أُخۡرَىٰ فَإِذَا هُمۡ قِيَامٞ يَنظُرُونَ")

                    Text(articleMarkdown: "2. **Resurrection**: All people will rise from their graves to face their Lord. Allah says:").font(.body)
                    ScriptureQuote(text: "“And the Horn will be blown, and at once from the graves to their Lord they will hasten” (Quran 36:51).", arabic: "وَنُفِخَ فِي ٱلصُّورِ فَإِذَا هُم مِّنَ ٱلۡأَجۡدَاثِ إِلَىٰ رَبِّهِمۡ يَنسِلُونَ")

                    Text(articleMarkdown: "3. **The Reckoning, **Hisab (حِسَاب)**,**: Every individual’s deeds will be reviewed, and their record of actions will be presented to them. Those who receive their record in their right hand will rejoice, while those who receive it in their left will despair.").font(.body)

                    Text(articleMarkdown: "4. **The Scale, **Mizan (مِيزَان)**,**: Deeds will be weighed on a divine scale. Good deeds that outweigh bad deeds will lead to Paradise. Allah says:").font(.body)
                    ScriptureQuote(text: "“And the weighing [of deeds] that Day will be the truth. So those whose scales are heavy - it is they who will be the successful” (Quran 7:8).", arabic: "وَٱلۡوَزۡنُ يَوۡمَئِذٍ ٱلۡحَقُّۚ فَمَن ثَقُلَتۡ مَوَٰزِينُهُۥ فَأُوْلَٰٓئِكَ هُمُ ٱلۡمُفۡلِحُونَ")

                    Text(articleMarkdown: "5. **The Bridge, **As-Sirat (الصِّرَاط)**,**: A bridge over Hellfire that all people must cross. The righteous will cross safely, while others will fall.").font(.body)
                }

                Section(header: ArticleHeader("IMPORTANCE OF BELIEF IN THE DAY OF JUDGMENT")) {
                    Text(articleMarkdown: "1. **Accountability**: Believing in the Day of Judgment instills a sense of accountability. Every action, no matter how small, will be rewarded or punished accordingly.").font(.body)

                    Text(articleMarkdown: "2. **Moral Uprightness**: Encourages Muslims to lead righteous lives, avoid sin, and fulfill their obligations to Allah and others.").font(.body)

                    Text(articleMarkdown: "3. **Justice and Fairness**: The Day of Judgment is the ultimate manifestation of Allah’s justice. Every wrong will be rectified, and no one will be wronged. Allah says:").font(.body)
                    ScriptureQuote(text: "“Indeed, Allah does not wrong the people at all, but it is the people who are wronging themselves” (Quran 10:44).", arabic: "إِنَّ ٱللَّهَ لَا يَظۡلِمُ ٱلنَّاسَ شَيۡـٔٗا وَلَٰكِنَّ ٱلنَّاسَ أَنفُسَهُمۡ يَظۡلِمُونَ")

                    Text(articleMarkdown: "4. **Hope and Fear**: Belief in the Day of Judgment inspires hope in Allah’s mercy and fear of His punishment, creating a balance in a Muslim’s spiritual life.").font(.body)
                }

                Section(header: ArticleHeader("QURANIC EMPHASIS")) {
                    Text(verbatim: "Allah (Glorified and Exalted be He) repeatedly emphasizes the Day of Judgment in the Quran as a reminder of the ultimate return to Him. He says:")
                        .font(.body)
                    ScriptureQuote(text: "“The Day they come forth, nothing concerning them will be concealed from Allah. To whom belongs [all] sovereignty this Day? To Allah, the One, the Prevailing” (Quran 40:16).", arabic: "يَوۡمَ هُم بَٰرِزُونَۖ لَا يَخۡفَىٰ عَلَى ٱللَّهِ مِنۡهُمۡ شَيۡءٞۚ لِّمَنِ ٱلۡمُلۡكُ ٱلۡيَوۡمَۖ لِلَّهِ ٱلۡوَٰحِدِ ٱلۡقَهَّارِ")

                    Text(verbatim: "In Surah Al-Qariah, Allah vividly describes the weighing of deeds:").font(.body)
                    ScriptureQuote(text: "“Then as for one whose scales are heavy [with good deeds], he will be in a pleasant life. But as for one whose scales are light, his refuge will be an abyss” (Quran 101:6-9).", arabic: "فَأَمَّا مَن ثَقُلَتۡ مَوَٰزِينُهُۥ ۝ فَهُوَ فِي عِيشَةٖ رَّاضِيَةٖ ۝ وَأَمَّا مَنۡ خَفَّتۡ مَوَٰزِينُهُۥ ۝ فَأُمُّهُۥ هَاوِيَةٞ")

                    Text(verbatim: "The Prophet Muhammad (peace and blessings be upon him) said about the Day of Judgment:").font(.body)
                    ScriptureQuote(text: "“Rights will certainly be restored to those entitled to them on the Day of Resurrection, (to the point that) even the hornless sheep will lay claim upon the horned one” (Sahih Muslim 2582).", arabic: "لَتُؤَدُّنَّ الْحُقُوقَ إِلَى أَهْلِهَا يَوْمَ الْقِيَامَةِ حَتَّى يُقَادَ لِلشَّاةِ الْجَلْحَاءِ مِنَ الشَّاةِ الْقَرْنَاءِ", dimmed: true)

                    Text(verbatim: "This highlights Allah’s perfect justice, where no soul will be wronged, not even among animals.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Certainty in the Last Day gives life meaning and accountability, balancing hope in Allah's mercy with fear of His justice.")
                        .font(.body)
                }

                ArticleSourcesSection(article: "QadarView")
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("Belief in the Last Day")
    }
}

struct QadarView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    Text(verbatim: "In short: Al-Qadar means everything happens by Allah's knowledge, writing, will, and creation, while people still choose and are accountable.")
                        .font(.body)
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    Text(articleMarkdown: "Belief in **Qadar (قَدَر)** (from the root **q-d-r (ق د ر)**, to measure out or decree), or divine decree, is the sixth pillar of **Iman (إِيمَان)**, faith. It is the belief that everything occurs by the will, knowledge, and command of Allah (Glorified and Exalted be He). This includes both the good and the bad, as Allah’s wisdom is perfect, and His plans are flawless.")
                        .font(.body)

                    Text(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:").font(.body)
                    ScriptureQuote(text: "“No disaster strikes upon the earth or among yourselves except that it is in a register before We bring it into being - indeed that, for Allah, is easy” (Quran 57:22).", arabic: "مَآ أَصَابَ مِن مُّصِيبَةٖ فِي ٱلۡأَرۡضِ وَلَا فِيٓ أَنفُسِكُمۡ إِلَّا فِي كِتَٰبٖ مِّن قَبۡلِ أَن نَّبۡرَأَهَآۚ إِنَّ ذَٰلِكَ عَلَى ٱللَّهِ يَسِيرٞ")

                    Text(verbatim: "This belief fosters patience during trials, gratitude in blessings, and complete trust in Allah’s wisdom. It also reminds Muslims that Allah’s knowledge encompasses all things and that nothing happens outside of His will.")
                        .font(.body)
                }

                Section(header: ArticleHeader("COMPONENTS OF QADR")) {
                    Text(verbatim: "Scholars identify four essential components of Qadar:").font(.body)

                    Text(articleMarkdown: "1. **Allah’s Knowledge, Ilm (عِلم)**: Allah’s knowledge is infinite and perfect. He knows everything that has happened, is happening, and will happen. Allah says:").font(.body)
                    ScriptureQuote(text: "“And with Him are the keys of the unseen; none knows them except Him. And He knows what is on the land and in the sea. Not a leaf falls but that He knows it” (Quran 6:59).", arabic: "وَعِندَهُۥ مَفَاتِحُ ٱلۡغَيۡبِ لَا يَعۡلَمُهَآ إِلَّا هُوَۚ وَيَعۡلَمُ مَا فِي ٱلۡبَرِّ وَٱلۡبَحۡرِۚ وَمَا تَسۡقُطُ مِن وَرَقَةٍ إِلَّا يَعۡلَمُهَا")

                    Text(articleMarkdown: "2. **Allah’s Writing, Kitabah (كِتَابَة)**: All things are written in **Al-Lawh Al-Mahfuz (اللَّوح المَحفُوظ)**, the Preserved Tablet, where every event, action, and outcome is recorded. Allah says:").font(.body)
                    ScriptureQuote(text: "“Do you not know that Allah knows what is in the heaven and earth? Indeed, that is in a Record. Indeed that, for Allah, is easy” (Quran 22:70).", arabic: "أَلَمۡ تَعۡلَمۡ أَنَّ ٱللَّهَ يَعۡلَمُ مَا فِي ٱلسَّمَآءِ وَٱلۡأَرۡضِۚ إِنَّ ذَٰلِكَ فِي كِتَٰبٍۚ إِنَّ ذَٰلِكَ عَلَى ٱللَّهِ يَسِيرٞ")

                    Text(articleMarkdown: "3. **Allah’s Will, Mashiah (مَشِيئَة)**: Whatever Allah wills happens, and whatever He does not will does not happen. Allah says:").font(.body)
                    ScriptureQuote(text: "“And the disbelievers planned, but Allah planned. And Allah is the best of planners” (Quran 3:54).", arabic: "وَمَكَرُواْ وَمَكَرَ ٱللَّهُۖ وَٱللَّهُ خَيۡرُ ٱلۡمَٰكِرِينَ")

                    Text(articleMarkdown: "4. **Allah’s Creation, Khalq (خَلق)**: Allah is the Creator of all things, including actions, circumstances, and outcomes. Allah says:").font(.body)
                    ScriptureQuote(text: "“Allah is the Creator of all things, and He is, over all things, Disposer of affairs” (Quran 39:62).", arabic: "ٱللَّهُ خَٰلِقُ كُلِّ شَيۡءٖۖ وَهُوَ عَلَىٰ كُلِّ شَيۡءٖ وَكِيلٞ")
                }

                Section(header: ArticleHeader("BALANCE BETWEEN FREE WILL AND QADR")) {
                    Text(verbatim: "Islam teaches a balance between divine decree and human free will. While Allah knows and decrees all things, humans are given the freedom to make choices and are held accountable for them. This accountability ensures justice and moral responsibility.")
                        .font(.body)

                    Text(verbatim: "The Prophet Muhammad (peace and blessings be upon him) said:").font(.body)
                    ScriptureQuote(text: "“cherish that which gives you benefit (in the Hereafter) and seek help from Allah and do not lose heart, and if anything (in the form of trouble) comes to you, don't say: If I had not done that, it would not have happened so and so, but say: Allah did that what He had ordained to do and your‘ if’ opens the (gate) for the Satan” (Sahih Muslim 2664).", arabic: "احْرِصْ عَلَى مَا يَنْفَعُكَ وَاسْتَعِنْ بِاللَّهِ وَلاَ تَعْجِزْ وَإِنْ أَصَابَكَ شَىْءٌ فَلاَ تَقُلْ لَوْ أَنِّي فَعَلْتُ كَانَ كَذَا وَكَذَا. وَلَكِنْ قُلْ قَدَرُ اللَّهِ وَمَا شَاءَ فَعَلَ فَإِنَّ لَوْ تَفْتَحُ عَمَلَ الشَّيْطَانِ", dimmed: true)
                }

                Section(header: ArticleHeader("PATIENT AND GRATEFUL")) {
                    Text(verbatim: "Belief in Qadar teaches Muslims to face life’s trials and blessings with patience and gratitude. Allah says in the Quran:").font(.body)
                    ScriptureQuote(text: "“And We will surely test you with something of fear and hunger and a loss of wealth and lives and fruits, but give good tidings to the patient, Who, when disaster strikes them, say, ‘Indeed we belong to Allah, and indeed to Him we will return.’” (Quran 2:155-156)", arabic: "وَلَنَبۡلُوَنَّكُم بِشَيۡءٖ مِّنَ ٱلۡخَوۡفِ وَٱلۡجُوعِ وَنَقۡصٖ مِّنَ ٱلۡأَمۡوَٰلِ وَٱلۡأَنفُسِ وَٱلثَّمَرَٰتِۗ وَبَشِّرِ ٱلصَّٰبِرِينَ ۝ ٱلَّذِينَ إِذَآ أَصَٰبَتۡهُم مُّصِيبَةٞ قَالُوٓاْ إِنَّا لِلَّهِ وَإِنَّآ إِلَيۡهِ رَٰجِعُونَ")

                    Text(verbatim: "Through this belief, Muslims trust that every hardship is a test and every blessing is a favor from Allah, leading them closer to Him.")
                        .font(.body)
                }

                Section(header: ArticleHeader("CONCLUSION")) {
                    Text(verbatim: "Belief in Qadar is a profound reminder of Allah’s ultimate authority, wisdom, and justice. It brings peace to the hearts of believers, knowing that everything happens for a reason, and Allah’s plans are always for the best. It encourages trust, patience, and gratitude in every aspect of life.")
                        .font(.body)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    Text(verbatim: "Belief in the divine decree brings patience in hardship and gratitude in ease, trusting that Allah's wisdom is always perfect.")
                        .font(.body)
                }
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("Belief in Al-Qadar")
    }
}

import SwiftUI
