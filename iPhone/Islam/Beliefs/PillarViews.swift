import SwiftUI

struct GodPillarView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: the existence of God is the foundation of all meaning, morality, and purpose. Reason, evidence, and the natural disposition every person is born with all point to one Creator.")
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    ArticleParagraph(verbatim: "The question of God's existence is the most important inquiry a person can make. It is the foundation of all meaning, morality, purpose, and accountability. If God exists, then life has objective direction and responsibility. If He does not, then everything (good and evil, justice and injustice, purpose and identity) becomes subjective and ultimately meaningless. Therefore, it is essential to examine this question through reason, evidence, and rational thought.")
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("THE DOMINO EFFECT FRAMEWORK")) {
                        ArticleParagraph(verbatim: "Every person is born knowing his Creator: the Prophet (peace and blessings be upon him) said every child is born upon the fitrah (Saheeh al-Bukhaari 1385), and the Quran's own argument is that creation could not have made itself (Quran 52:35).")
                        ScriptureQuote(hadith: "bukhari:1385", cite: "Saheeh al-Bukhaari 1385, Saheeh Muslim 2658", arabic: 31...49, english: 4...44)
                        ScriptureQuote(quran: "52:35")
                        ArticleParagraph(verbatim: "For the one whose fitrah has been clouded, a step-by-step method helps, what can be called the Domino Effect. Each answer leads logically to the next, and no step may be skipped. Does a higher power exist beyond the universe? Is it intelligent rather than blind, and powerful rather than weak? An intelligent, powerful, necessary cause is what is meant by God. Then the questions follow in order: is He still involved with creation, did He send revelation, and is the one true religion monotheistic and meant for all people?")
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("THE DOMINO EFFECT FRAMEWORK")) {
                        ArticleParagraph(verbatim: "Every person is born knowing his Creator: the Prophet (peace and blessings be upon him) said every child is born upon the fitrah (Saheeh al-Bukhaari 1385), and the Quran's own argument is that creation could not have made itself (Quran 52:35).")
                        ScriptureQuote(hadith: "bukhari:1385", cite: "Saheeh al-Bukhaari 1385, Saheeh Muslim 2658", arabic: 31...49, english: 4...44)
                        ScriptureQuote(quran: "52:35")
                        VStack(alignment: .leading, spacing: 6) {
                            ArticleParagraph(verbatim: "For the one whose fitrah has been clouded, a step-by-step method helps, what can be called the Domino Effect. Each answer leads logically to the next, and no step may be skipped:")
                            Group {
                                ArticleBullet(verbatim: "• Does a higher power exist at all: something beyond the universe that brought it into being? This comes first. To ask whether God exists is already to assume a great deal about what that power is like.")
                                ArticleBullet(verbatim: "• If a higher power exists, is it intelligent, or is it blind and random? A random, unthinking cause cannot account for order, information, or purpose.")
                                ArticleBullet(verbatim: "• If it is intelligent, is it powerful or weak? A weak cause cannot sustain a universe it did not have the power to make.")
                                ArticleBullet(verbatim: "• An intelligent, powerful, necessary cause is what is meant by God. Only now is the word earned.")
                                ArticleBullet(verbatim: "• If God exists, is He still involved with creation (theism), or did He create and withdraw (deism)?")
                                ArticleBullet(verbatim: "• If He is involved, did He send revelation to guide humanity?")
                                ArticleBullet(verbatim: "• If revelation exists, then one religion must be objectively true.")
                                ArticleBullet(verbatim: "• If there is one true religion, is it monotheistic or polytheistic?")
                                ArticleBullet(verbatim: "• If monotheistic, is it exclusive to a specific ethnicity, or universal for all people?")
                                ArticleBullet(verbatim: "• If universal and monotheistic, the serious contenders are Islam and Christianity.")
                            }
                            .font(.body)
                        }
                    }

                    Section(header: ArticleHeader("CHRISTIANITY VS. ISLAM")) {
                        VStack(alignment: .leading, spacing: 6) {
                            ArticleParagraph(verbatim: "While Christianity asserts universality, it contains internal contradictions and historical issues:")
                            Group {
                                ArticleBullet(verbatim: "• The Trinity violates pure monotheism by making God three persons in one essence, an idea that even many Christian scholars admit is a mystery, not a rational doctrine.")
                                ArticleBullet(verbatim: "• The Bible is not preserved in its original language or form. It is a compilation of human writings over centuries with known alterations.")
                                ArticleBullet(verbatim: "• Christianity does not offer a consistent position on salvation, works, and belief.")
                            }
                            ArticleParagraph(verbatim: "Islam, on the other hand:")
                            Group {
                                ArticleBullet("• Affirms absolute monotheism, **Tawheed (تَوحِيد)**, with no partners, no intermediaries, and no confusion.")
                                ArticleBullet(verbatim: "• Preserves the Quran exactly as it was revealed: verbatim, letter for letter, sound for sound, in its original Arabic.")
                                ArticleBullet(verbatim: "• Welcomes all of humanity, regardless of ethnicity, race, gender, or background.")
                                ArticleBullet(verbatim: "• Is the only universal, unambiguous, monotheistic religion with an intellectually sound and preserved foundation.")
                            }
                        }
                    }
                }

                Section(header: ArticleHeader("THE COSMOLOGICAL ARGUMENT")) {
                    ArticleParagraph(verbatim: "Every effect has a cause. The universe began to exist, so it must have had a cause. Modern cosmology also points to a beginning, but where did the energy come from? What caused it to expand? Who set the laws of physics in motion? The Quran speaks of the heavens and the earth as once joined and then separated, and of a heaven that Allah continues to expand. The early commentators (Ibn Abbaas, Mujaahid, and Qataadah, as at-Tabari and Ibn Katheer record) read these verses in their own terms, and some contemporary scholars see in them an allusion to what cosmology later found. Either way, the verses point to a Creator who began the universe and sustains it:")
                    ScriptureQuote(quran: "21:30")
                    ScriptureQuote(quran: "51:47")
                    ArticleParagraph(verbatim: "The existence of anything (matter, time, space) requires an uncaused, necessary being beyond the system: Allah (Glorified and Exalted be He).")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("ABIOGENESIS: LIFE FROM NON-LIFE?")) {
                        VStack(alignment: .leading, spacing: 6) {
                            ArticleParagraph(verbatim: "Modern science teaches that the first life (a prokaryotic cell) emerged from non-living chemicals. But this raises serious questions:")
                            Group {
                                ArticleBullet(verbatim: "• How did non-living matter suddenly become alive?")
                                ArticleBullet(verbatim: "• How did a cell, containing instructions (DNA), copy itself?")
                                ArticleBullet(verbatim: "• DNA is a dense, coded information system: a single cell carries a precisely ordered set of instructions comparable to hundreds of megabytes of text. Where did this information come from?")
                            }
                            ArticleParagraph(verbatim: "Scientists admit: “We don’t know.” But nothing in our experience tells us that complex, coded systems arise without a mind. The most rational explanation is that life was created intentionally, not randomly.")
                        }
                    }

                    Section(header: ArticleHeader("HUMAN INTELLIGENCE: BEYOND EVOLUTION")) {
                        ArticleParagraph(articleMarkdown: "Human beings are orders of magnitude more intelligent than any other creature. Humans build cities, fly planes, write poetry, and explore the universe. They possess self-awareness, language, morality, free will, and the capacity for worship. If evolution alone explains the human brain, why don't other species come close? Why the quantum leap in ability? Human exceptionalism points to a Creator who endowed humanity with reason, **Aql (عَقل)**, a faculty Allah (Glorified and Exalted be He) gave to humans (and to the jinn, who are likewise accountable) and not to the animals.")
                        ScriptureQuote(quran: "95:4")
                    }
                }

                Section(header: ArticleHeader("THE FINE-TUNING OF THE UNIVERSE")) {
                    ArticleParagraph(verbatim: "Gravity, electromagnetism, the strong and weak nuclear forces: all must be precisely balanced. If any were off by even a tiny fraction, life could not exist. This is not randomness. It is deliberate fine-tuning. Even atheists like Stephen Hawking acknowledge this astonishing precision. The question is: Who fine-tuned it?")
                }

                Section(header: ArticleHeader("THE MORAL ARGUMENT")) {
                    ArticleParagraph(verbatim: "Every human being knows certain things are wrong: murder, rape, lying, oppression. But if humans are just chemical accidents, who decides what's right or wrong? Evolution can explain instincts, not moral obligations. The existence of objective morality points to a Moral Lawgiver, someone who defines justice, goodness, and evil: Allah (Glorified and Exalted be He).")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("ARGUMENT FROM BEAUTY, ORDER, AND DESIGN")) {
                        ArticleParagraph(verbatim: "Look at the trees, stars, animals, oceans. Look at the symmetry of flowers and the precision of ecosystems. Human creation (skyscrapers, smartphones, aircraft) demonstrates purposeful design. Just as buildings imply builders, the cosmos implies a Creator.")
                        ScriptureQuote(quran: "52:35-36")
                    }

                    Section(header: ArticleHeader("WHAT MAKES A RELIGION TRUE?")) {
                        VStack(alignment: .leading, spacing: 6) {
                            ArticleParagraph(verbatim: "When choosing a religion, one must not follow emotions, culture, or dreams. The correct belief system should be based on logic, objective evidence, and sound reasoning.")
                            Group {
                                ArticleBullet(verbatim: "• Subjective experiences (such as dreams, visions, or personal feelings) may be meaningful, but they are not reliable indicators of truth.")
                                ArticleBullet(verbatim: "• Anyone from any religion can claim such experiences.")
                                ArticleBullet(verbatim: "• Truth must be verifiable, logical, and universally applicable.")
                            }
                            ArticleParagraph(verbatim: "Islam aligns with these criteria.")
                        }
                        ScriptureQuote(quran: "45:23", words: 0...4)
                    }

                    Section(header: ArticleHeader("FINAL REFLECTION")) {
                        ArticleParagraph(articleMarkdown: "Belief in God is not blind faith; it is the most rational and coherent explanation for existence, morality, consciousness, and design. Every human is born upon the **Fitrah (فِطرَة)**, the natural disposition to believe in one Creator. However, ego, society, and culture often obscure this truth. Islam calls humanity back to this original clarity.")
                        ScriptureQuote(quran: "17:36")
                    }

                    Section(header: ArticleHeader("ADVICE TO THE SINCERE SEEKER")) {
                        VStack(alignment: .leading, spacing: 6) {
                            ArticleParagraph(verbatim: "Seek truth with sincerity. Study deeply. Question critically. Do not follow inherited beliefs without examination.")
                            Group {

                                ArticleBullet(verbatim: "• The Quran criticizes blind following of ancestors without knowledge (Quran 43:23).")
                                ScriptureQuote(quran: "43:23", words: 12...20)
                                ArticleBullet(verbatim: "• Instead, use the God-given faculty of reason (aql) and return to the Fitrah.")
                                ArticleBullet(verbatim: "• Islam stands as the only worldview that fully harmonizes with reason, morality, and objective reality.")
                            }
                        }
                    }
                }


                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Belief in God is not blind faith but the most rational explanation for existence, morality, consciousness, and design. Islam simply calls humanity back to the pure monotheism the soul was created upon.")
                }

                // Where the same question is argued at length (Proving Islam, 2026-09-29).
                Section(header: ArticleHeader("GO DEEPER")) {
                    ArticleDoorRow(door: .article("ProvingGodView"))
                    ArticleDoorRow(door: .provingIslam)
                }

                ArticleSourcesSection(article: "GodPillarView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "GodPillarView")
        .navigationTitle("Does God Exist?")
    }
}

struct IslamPillarView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: Islam is the submission of the heart and life to Allah alone. It rests on five pillars of practice and six pillars of faith, and it is the one message of every prophet from Aadam to Muhammad (peace be upon them).")
                }


                ArticleOnly(.long) {
                    Section(header: ArticleHeader("OVERVIEW")) {
                        ArticleParagraph(articleMarkdown: "**Islam (إِسلَام)** comes from the Arabic root **s-l-m (س ل م)**, meaning “submission,” “safety,” and “peace”: it is a complete way of life built on the worship of Allah (Glorified and Exalted be He) alone. The Quran, revealed to Prophet Muhammad (peace and blessings be upon him) over 23 years through the angel **Jibreel (جِبرِيل)** (Gabriel), is the divine word of Allah: a comprehensive guide to belief, morality, and law.")

                        ArticleParagraph(articleMarkdown: "The essence of Islam is **Tawheed (تَوحِيد)**, absolute monotheism: there is no deity worthy of worship except Allah. Allah says in the Quran:")
                        ScriptureQuote(quran: "2:163")

                        ArticleParagraph(verbatim: "Prophet Muhammad (peace and blessings be upon him) is the final and last messenger of Allah, sent as a mercy to all of creation. Allah says in the Quran:")
                        ScriptureQuote(quran: "21:107")

                        ArticleParagraph(verbatim: "Islam has been the way of life for humanity since the creation of Aadam (peace be upon him), who was the first prophet and the first Muslim. Every nation that correctly followed the teachings of its prophet was considered Muslim in submission to Allah (Glorified and Exalted be He). For example, the Israelites who followed Moses (peace be upon him) and the disciples who followed Jesus (peace be upon him) were considered Muslims of their time.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("OVERVIEW")) {
                        ArticleParagraph(articleMarkdown: "**Islam (إِسلَام)** comes from the Arabic root **s-l-m (س ل م)**, meaning “submission,” “safety,” and “peace”: it is a complete way of life built on the worship of Allah (Glorified and Exalted be He) alone. Its essence is **Tawheed (تَوحِيد)**, absolute monotheism: there is no deity worthy of worship except Allah. Allah says in the Quran:")
                        ScriptureQuote(quran: "2:163")

                        ArticleParagraph(verbatim: "Islam has been the way of life for humanity since Aadam (peace be upon him), the first prophet and the first Muslim, and Prophet Muhammad (peace and blessings be upon him) is its final messenger, sent as a mercy to all of creation. Allah says in the Quran:")
                        ScriptureQuote(quran: "21:107")
                    }
                }

                Section(header: ArticleHeader("THE FIVE PILLARS")) {
                    ArticleParagraph(verbatim: "Islam is built on five pillars, which are the fundamental acts of worship for every Muslim. The Prophet Muhammad (peace and blessings be upon him) said:")
                    ScriptureQuote(hadith: "muslim:16d", cite: "Saheeh Muslim 16d", arabic: 35...53, english: 8...38)

                    ArticleParagraph(verbatim: "The Five Pillars are:")
                    ArticleStep("1. **Shahaadah (شَهَادَة)**, from the root **sh-h-d (ش ه د)**, to witness or testify: the testimony of faith, “There is no god but Allah, and Muhammad is His Messenger.” You are not reporting an opinion; you are bearing witness. It is the foundation of a Muslim's faith.")
                    ArticleStep("2. **Salaah (صَلَاة)**, from the root **s-l-w (ص ل و)**, to supplicate and to draw near: praying five times a day at prescribed times, a direct link between the believer and Allah.")
                    ArticleStep("3. **Zakaah (زَكَاة)**, from the root **z-k-w (ز ك و)**, to purify and to grow: giving a portion of wealth to the needy (typically 2.5% of yearly savings). The word carries both meanings at once: wealth is purified by giving it away, and it grows by being purified.")
                    ArticleStep("4. **Sawm (صَوم)**, from the root **s-w-m (ص و م)**, to abstain or hold back: fasting the month of **Ramadan (رَمَضَان)**, abstaining from food, drink, and marital relations from dawn to sunset while guarding against sin, as spiritual reflection and self-discipline.")
                    ArticleStep("5. **Hajj (حَجّ)**, from the root **h-j-j (ح ج ج)**, to set out with purpose toward something: pilgrimage to Makkah, a once-in-a-lifetime obligation for those physically and financially able, symbolizing unity and submission to Allah.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("THE SIX PILLARS OF EEMAAN")) {
                        ArticleParagraph(articleMarkdown: "The Six Pillars of **Eemaan (إِيمَان)**, from the root **a-m-n (أ م ن)**, meaning faith, trust, and security, are the core beliefs every Muslim must hold. These are based on the Quran and the teachings of Prophet Muhammad (peace and blessings be upon him). Allah says in the Quran:")
                        ScriptureQuote(quran: "2:285")

                        ArticleParagraph(verbatim: "The Prophet Muhammad (peace and blessings be upon him) explained the pillars of Eemaan when he said:")
                        ScriptureQuote(hadith: "muslim:8a", cite: "Saheeh Muslim 8a", arabic: 273...284, english: 409...442)

                        ArticleParagraph(verbatim: "The Six Pillars of Eemaan are:")
                        ArticleStep("1. **Belief in Allah**, **Tawheed (تَوحِيد)** from the root **w-h-d (و ح د)**, to make one: the oneness of Allah, who has no partners or equals.")
                        ArticleStep("2. **Belief in the Angels**, **Malaaikah (مَلَائِكَة)** from the root **l-a-k (ل أ ك)**, to send with a message: created beings of light who serve Allah and carry out His commands, such as Jibreel (Gabriel).")
                        ArticleStep("3. **Belief in the Books**, **Kutub (كُتُب)** from the root **k-t-b (ك ت ب)**, to write or prescribe: the divine scriptures revealed by Allah, including the Torah, Gospel, Psalms, and the Quran, which is the final and unaltered revelation.")
                        ArticleStep("4. **Belief in the Messengers**, **Rusul (رُسُل)** from the root **r-s-l (ر س ل)**, to send: prophets sent to guide humanity, ending with Prophet Muhammad (peace and blessings be upon him).")
                        ArticleStep("5. **Belief in the Last Day**, **Yawm al-Qiyaamah (يَوم القِيَامَة)** from the root **q-w-m (ق و م)**, to stand: the Day of Judgment, when all people will stand before Allah and be held accountable for their deeds.")
                        ArticleStep("6. **Belief in Divine Decree, Qadar (القَدَر)**, from the root **q-d-r (ق د ر)**, to measure out or determine: that everything, good and bad, happens by Allah’s will and wisdom, measured out precisely.")
                    }

                    Section(header: ArticleHeader("PROPHETHOOD")) {
                        ArticleParagraph(verbatim: "Allah sent prophets to every nation to guide them to worship Him alone. These prophets include Aadam, Noah, Abraham, Moses, David, Solomon, Jesus, and many others (peace be upon them all). Allah says in the Quran:")
                        ScriptureQuote(quran: "2:285", words: 14...19)

                        ArticleParagraph(verbatim: "However, all previous prophets were sent for their specific people and times. Prophet Muhammad (peace and blessings be upon him) is unique as the final and universal messenger, sent for all of humanity until the end of time. Allah says in the Quran:")
                        ScriptureQuote(quran: "33:40")

                        ArticleParagraph(verbatim: "Regarding Prophet Abraham (peace be upon him), Allah clarifies in the Quran:")
                        ScriptureQuote(quran: "3:67")
                    }

                    Section(header: ArticleHeader("PREVIOUS SCRIPTURES")) {
                        ArticleParagraph(verbatim: "Islam acknowledges earlier divine scriptures such as the Torah given to Moses (peace be upon him) and the Gospel given to Jesus (peace be upon him). However, these scriptures were altered over time, and the current versions of the Bible and Torah are not the original revelations. Allah says in the Quran:")
                        ScriptureQuote(quran: "2:79")

                        ArticleParagraph(verbatim: "The Quran is the final, complete, and preserved revelation sent to all of mankind for all time. Allah says in the Quran:")
                        ScriptureQuote(quran: "15:9")

                        ArticleParagraph(verbatim: "Prophet Muhammad (peace and blessings be upon him) said about the Quran:")
                        ScriptureQuote(hadith: "bukhari:5027", cite: "Saheeh al-Bukhaari 5027", arabic: 36...40, english: 4...17)
                    }

                    Section(header: ArticleHeader("ISLAMIC VALUES")) {
                        ArticleParagraph(articleMarkdown: "Islam emphasizes high moral conduct, urging Muslims to embody honesty, justice, compassion, and humility. It teaches that good character and kindness towards others are integral to faith. The concept of the **Ummah (أُمَّة)**, the global Muslim community, fosters unity among believers regardless of ethnicity or background.")

                        ArticleParagraph(verbatim: "Allah commands Muslims to act justly and to do good:")
                        ScriptureQuote(quran: "16:90")

                        ArticleParagraph(verbatim: "True righteousness is not limited to mere belief or rituals but includes good deeds and moral conduct. Allah says in the Quran:")
                        ScriptureQuote(quran: "2:177")

                        ArticleParagraph(verbatim: "The Prophet Muhammad (peace and blessings be upon him) highlighted the importance of good manners and character. He said:")
                        ScriptureQuote(hadith: "bukhari:6029", cite: "Saheeh al-Bukhaari 6029", arabic: 67...71, english: 25...37)

                        ArticleParagraph(verbatim: "He also said:")
                        ScriptureQuote(text: "“The most beloved of people to Allah are those most beneficial to people, and the most beloved of deeds to Allah is joy you bring to a Muslim, or a hardship you remove from him, or a debt you pay off for him, or hunger you drive away from him” (al-Mu‘jam al-Awsat of at-Tabaraani 6026; graded hasan by al-Albaani, as-Silsilah as-Saheehah 906).", arabic: "أَحَبُّ النَّاسِ إِلَى اللَّهِ أَنفَعُهُم لِلنَّاسِ، وَأَحَبُّ الأَعمَالِ إِلَى اللَّهِ سُرُورٌ تُدخِلُهُ عَلَى مُسلِمٍ، أَو تَكشِفُ عَنهُ كُربَةً، أَو تَقضِي عَنهُ دَينًا، أَو تَطرُدُ عَنهُ جُوعًا", dimmed: true)

                        ArticleParagraph(verbatim: "These teachings show that Islam is not only about fulfilling religious obligations but also about treating others with respect, kindness, and fairness. Upholding good character is considered a sign of true faith and devotion to Allah (Glorified and Exalted be He).")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("THE SIX PILLARS OF EEMAAN")) {
                        ArticleParagraph(articleMarkdown: "The Six Pillars of **Eemaan (إِيمَان)**, from the root **a-m-n (أ م ن)**, meaning faith, trust, and security, are the core beliefs every Muslim must hold. The Prophet Muhammad (peace and blessings be upon him) explained them when he said:")
                        ScriptureQuote(hadith: "muslim:8a", cite: "Saheeh Muslim 8a", arabic: 273...284, english: 409...442)

                        ArticleParagraph(verbatim: "Allah sent prophets to every nation to call them to worship Him alone. The Quran is the last of His books and the one He has preserved, and Muhammad (peace and blessings be upon him) is the last of His messengers, sent to all of humanity until the end of time.")
                    }

                    Section(header: ArticleHeader("ISLAMIC VALUES")) {
                        ArticleParagraph(verbatim: "Islam emphasizes high moral conduct, urging Muslims to embody honesty, justice, compassion, and humility, and it teaches that good character and kindness towards others are integral to faith. Allah commands Muslims to act justly and to do good:")
                        ScriptureQuote(quran: "16:90")

                        ArticleParagraph(verbatim: "The Prophet Muhammad (peace and blessings be upon him) highlighted the importance of good manners and character. He said:")
                        ScriptureQuote(hadith: "bukhari:6029", cite: "Saheeh al-Bukhaari 6029", arabic: 67...71, english: 25...37)
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Islam is a complete way of life that joins correct belief, sincere worship, and excellent character. It is Allah's final guidance and a mercy for all people until the end of time.")
                }

                ArticleSourcesSection(article: "IslamPillarView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "IslamPillarView")
        .navigationTitle("What is Islam?")
    }
}

struct MuslimPillarView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: a Muslim is one who submits to Allah alone, following the Quran and the Sunnah of Prophet Muhammad (peace and blessings be upon him) as understood by his Companions, his family, and the first righteous generations.")
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    ArticleParagraph(articleMarkdown: "A **Muslim (مُسلِم)** is “one who submits.” The word shares the root **s-l-m (س ل م)** with **Islam (إِسلَام)**, a root carrying the meanings of submission, safety, and peace. A Muslim is therefore someone who surrenders to Allah rather than to his own desires or the passing things of this world, turning instead to the One who created him and knows him best.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("ALLAH KNOWS US BEST")) {
                        ArticleParagraph(verbatim: "Before He calls us to worship Him, Allah reminds us that He created us and knows even what our souls whisper. The scholars of tafseer explain the nearness in this verse as that of His angels, who record every word, or of His knowledge (Ibn Katheer, at this verse), while Allah Himself is above His Throne:")
                        ScriptureQuote(quran: "50:16")
                        ArticleParagraph(verbatim: "Submission, then, is not to a stranger; it is to the Lord who made us and knows us better than we know ourselves.")
                    }

                    Section(header: ArticleHeader("SUBMISSION TO ALLAH ALONE")) {
                        ArticleParagraph(verbatim: "To be a Muslim is to answer Allah's call as Ibraaheem (Abraham, peace be upon him) did:")
                        ScriptureQuote(quran: "2:131")
                        ArticleParagraph(verbatim: "Ibraaheem was neither a Jew nor a Christian, but a Muslim in the truest sense, devoted to the worship of the one God:")
                        ScriptureQuote(quran: "3:67")
                    }
                }

                Section(header: ArticleHeader("FOLLOWING THE QURAN AND SUNNAH")) {
                    ArticleParagraph(articleMarkdown: "A Muslim follows the **Quran (قُرءان)**, the word of Allah, and the guidance of His Messenger Muhammad (peace and blessings be upon him), preserved in his **Sunnah (سُنَّة)** through authentic **Hadith (حَدِيث)**. Love of Allah is shown by following His Messenger:")
                    ScriptureQuote(quran: "3:31", words: 0...10)
                }

                Section(header: ArticleHeader("AS THE FIRST GENERATIONS UNDERSTOOD IT")) {
                    ArticleParagraph(articleMarkdown: "The Quran and Sunnah are understood as the first believers understood them: the Companions, **the Sahaabah (صَحَابَة)**; the Prophet's household, **the Ahl al-Bayt (أَهل البَيت)**, which includes his wives; and the righteous first three generations, **the Salaf (السَّلَف)**.")
                    ScriptureQuote(quran: "9:100", words: 0...12)
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("WHAT IS A MU’MIN (BELIEVER)?")) {
                        ArticleParagraph(articleMarkdown: "A **Mu’min (مُؤمِن)**, a true believer, is one whose faith lives in the heart and shows in action. Allah describes them:")
                        ScriptureQuote(quran: "8:2")
                    }

                    Section(header: ArticleHeader("THE BELIEVERS ARE ONE")) {
                        ArticleParagraph(verbatim: "Muslims are a single brotherhood, united in faith across every race and land:")
                        ScriptureQuote(quran: "49:10")
                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "muslim:2586a", cite: "Saheeh Muslim 2586", arabic: 27...44, english: 0...30)
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("A Muslim submits to Allah alone, the One who created and knows us best, by holding to the Quran and the Sunnah upon the understanding of the Companions, the Prophet's family, and the Salaf, joined with all the believers as one brotherhood.")
                }

                ArticleSourcesSection(article: "MuslimPillarView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "MuslimPillarView")
        .navigationTitle("What is a Muslim?")
    }
}

struct AllahPillarView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: Allah is the one true God: the sole Creator and Sustainer of all that exists, without partner or equal, known by His Most Beautiful Names and perfect attributes.")
                }


                Section(header: ArticleHeader("OVERVIEW")) {
                    ArticleParagraph(articleMarkdown: "**Allah (اللَّه)** is the name of the one true God. It comes from **Al-Ilaah (الإِلَٰه)**, “The God.” In Islam He (Glorified and Exalted be He) is the unique Creator, Sustainer, and Maintainer of all that exists, without partner, associate, or equal, and absolutely One.")

                    ArticleParagraph(articleMarkdown: "Allah has the Most Beautiful Names, **Al-Asma al-Husna (الأَسمَاء الحُسنَى)**, such as the Most Gracious, the Most Merciful, the All-Knowing, and the King. They describe His perfect qualities, and He is far above any need, limitation, or resemblance to His creation. Allah says:")
                    ScriptureQuote(quran: "7:180")

                    ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) said:")
                    ScriptureQuote(hadith: "bukhari:2736", cite: "Saheeh al-Bukhaari 2736, Saheeh Muslim 2677", arabic: 28...39, english: 4...19)

                    ArticleParagraph(verbatim: "Ahl as-Sunnah affirm these Names and Attributes exactly as Allah and His Messenger affirmed them: without denying their meanings, without asking how, and without likening Him to His creation. Allah says: “There is nothing like unto Him, and He is the Hearing, the Seeing” (Quran 42:11).")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("ALLAH IN PRE-ISLAMIC TIMES")) {
                        ArticleParagraph(verbatim: "Before Islam, the Arabs acknowledged a supreme God named Allah but associated partners with Him by worshipping idols and other deities. When Prophet Muhammad (peace and blessings be upon him) brought Islam, he reaffirmed the Oneness of Allah, rejecting all forms of idolatry and polytheism. Allah says in the Quran:")
                        ScriptureQuote(quran: "98:5")
                    }
                }

                Section(header: ArticleHeader("QURANIC REFERENCES")) {
                    ArticleParagraph(verbatim: "Allah describes Himself in the Quran as the One and Only God, the source of all mercy and compassion. Allah says:")
                    ScriptureQuote(quran: "2:163")

                    ArticleParagraph(verbatim: "He also says:")
                    ScriptureQuote(quran: "42:11", words: 13...18)
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("ESSENCE OF WORSHIP")) {
                        ArticleParagraph(verbatim: "The primary purpose of life is to worship Allah (Glorified and Exalted be He). This worship is not limited to rituals but encompasses every sincere action done to seek Allah's pleasure. Allah says in the Quran:")
                        ScriptureQuote(quran: "51:56")

                        ArticleParagraph(verbatim: "Worshiping Allah includes prayer, supplication, charity, good conduct, and obedience to His commands as revealed in the Quran and the teachings of Prophet Muhammad (peace and blessings be upon him).")

                        ArticleParagraph(verbatim: "This life is also a test from Allah to determine who among His servants will strive to fulfill their purpose with sincerity and patience. Allah says in the Quran:")
                        ScriptureQuote(quran: "18:7")

                        ArticleParagraph(verbatim: "Allah further reminds us:")
                        ScriptureQuote(quran: "21:35", words: 4...9)

                        ArticleParagraph(verbatim: "Through these tests, believers have the opportunity to demonstrate their devotion, patience, and trust in Allah. Success lies in worshiping Him sincerely and following the straight path outlined in the Quran and Sunnah.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("ESSENCE OF WORSHIP")) {
                        ArticleParagraph(verbatim: "The primary purpose of life is to worship Allah (Glorified and Exalted be He). This worship is not limited to rituals but encompasses every sincere action done to seek Allah's pleasure. Allah says in the Quran:")
                        ScriptureQuote(quran: "51:56")

                        ArticleParagraph(verbatim: "This life is a test of who will fulfill that purpose with sincerity and patience, and success lies in worshiping Him sincerely and following the straight path outlined in the Quran and Sunnah.")
                    }
                }

                Section(header: ArticleHeader("SURAH AL-IKHLAAS")) {
                    ScriptureQuote(quran: "112:1-4")

                    ArticleParagraph(articleMarkdown: "This short yet powerful chapter, **Surah Al-Ikhlaas (الإِخلَاص)**, perfectly encapsulates the core of Islamic monotheism, affirming that Allah is eternal, without offspring or equal, and incomparable to any of His creation.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("AAYAT AL-KURSI")) {
                        ScriptureQuote(quran: "2:255")

                        ArticleParagraph(articleMarkdown: "**Aayat al-Kursi (آيَة الكُرسِي)**, the Throne Verse, emphasizes Allah's supreme power, unmatched knowledge, and sovereignty over the universe. It is the greatest verse in the Quran, as the Prophet (peace and blessings be upon him) told Ubayy ibn Ka‘b (Saheeh Muslim 810).")
                        ScriptureQuote(hadith: "muslim:810", cite: "Saheeh Muslim 810", arabic: 36...90, english: 0...83)
                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) also confirmed the words of the one who told Abu Hurayrah (may Allah be pleased with him):")
                        ScriptureQuote(hadith: "bukhari:2311", cite: "Saheeh al-Bukhaari 2311", arabic: 206...234, english: 327...370)
                    }
                }


                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Allah is absolutely One and unlike anything in His creation. The whole purpose of life is to worship, obey, and come to know Him with sincerity.")
                }

                ArticleSourcesSection(article: "AllahPillarView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "AllahPillarView")
        .navigationTitle("Who is Allah?")
    }
}

/// The 99 Names as an ARTICLE (Abu, 2026-09-19). The Islam tab already has the names themselves as a
/// browsable library; this is the other half, the one Pillars & Beliefs was missing: what the Most
/// Beautiful Names are, what the hadith actually says, why the familiar numbered list is not part of
/// the authentic narration, and how Ahl as-Sunnah affirm them. It sits in THE BASICS beside "Who is
/// Allah?", whose Names paragraph it expands.
///
/// Every quote is our own pack's text, checked word by word before it was written: Bukhari 2736 and
/// Muslim 2677a for the count, 7:180 / 17:110 / 20:8 / 59:22-24 for the Quranic basis. The enumerated
/// list in Tirmidhi 3507 is graded Daif by Shakir, al-Albani and Zubair Ali Zai alike, and the article
/// says so rather than quoting it as if it were the Prophet's own listing.
struct NamesOfAllahPillarView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: Allah has the Most Beautiful Names, and the Prophet (peace and blessings be upon him) said whoever encompasses ninety-nine of them will enter Paradise. To encompass them is to learn them, understand what they mean, and call upon Allah by them.")
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    ArticleParagraph(articleMarkdown: "**Al-Asma al-Husna (الأَسمَاء الحُسنَى)**, the Most Beautiful Names, are the names Allah (Glorified and Exalted be He) has given Himself in the Quran and through His Messenger (peace and blessings be upon him). They are not titles people invented for Him: a name of Allah is only what He or His Messenger affirmed. Each one names a perfection that belongs to Him alone and completely.")

                    ArticleParagraph(verbatim: "Allah commands us to use them when we call on Him:")
                    ScriptureQuote(quran: "7:180")

                    ArticleParagraph(verbatim: "And whichever of them you call Him by, you are calling the same One:")
                    ScriptureQuote(quran: "17:110")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("THE NINETY-NINE")) {
                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "bukhari:2736", cite: "Saheeh al-Bukhaari 2736", arabic: 28...39, english: 4...19)

                        ArticleParagraph(verbatim: "And in the narration of Muslim:")
                        ScriptureQuote(hadith: "muslim:2677a", cite: "Saheeh Muslim 2677", arabic: 36...48, english: 0...33)

                        ArticleParagraph(articleMarkdown: "The word in the hadith is **ahsaaha (أَحصَاهَا)**, to encompass or take account of. The scholars explain it as more than memorizing the words: it is to learn them, to understand what each one means, to worship Allah by what they require, and to call upon Him with them. A name learned and not acted upon has not been encompassed.")

                        // Deliberately NOT quoting the famous "or kept to Yourself in the hidden place of
                        // the unseen" dua here: our only copy of it is Mishkat 2452, transmitted by Razin,
                        // which does not meet the app's sahih/hasan-only rule for a quoted proof. The point
                        // stands on the wording of the authentic hadith itself, which states a count that
                        // carries a promise and never says the names stop there.
                        ArticleParagraph(verbatim: "Note what the hadith does and does not say. It says that ninety-nine of His names carry this promise. It does not say that Allah has only ninety-nine: the scholars are agreed that His names are not limited to any list we hold.")
                    }

                    Section(header: ArticleHeader("WHY THE LIST IS NOT IN THE HADITH")) {
                        ArticleParagraph(verbatim: "The familiar numbered list of ninety-nine names, the one printed on posters and recited in songs, does not come from the narration in Bukhaari and Muslim. Those two authentic reports state the count and the promise, and stop there.")

                        ArticleParagraph(articleMarkdown: "The enumerated list appears in **Jaami‘ at-Tirmidhi 3507**, and scholars of hadith grade that addition **da‘eef (ضَعِيف)**, weak: Ahmad Shaakir, al-Albaani and Zubayr Ali Zai all grade it so. At-Tirmidhi himself called the narration ghareeb and noted that the other routes of the hadith do not mention the names, and later scholars such as Ibn Taymiyyah and Ibn Hajar held the enumeration to be the work of a narrator who gathered names from the Quran, not words the Prophet (peace and blessings be upon him) listed himself.")

                        ArticleParagraph(verbatim: "This is why different scholars' lists of the ninety-nine do not perfectly agree, and why some names on the common list are not found as names in the Quran at all. None of this touches the hadith itself, which is authentic. It only means that the exact roll of ninety-nine is a scholarly compilation, and is treated as one.")
                    }

                    Section(header: ArticleHeader("THE NAMES IN THE QURAN")) {
                        ArticleParagraph(verbatim: "The Quran gathers many of the names together in the closing aayaat of Surah al-Hashr:")
                        ScriptureQuote(quran: "59:22")
                        ScriptureQuote(quran: "59:23")
                        ScriptureQuote(quran: "59:24")

                        ArticleParagraph(verbatim: "And it names them as belonging to Him alone:")
                        ScriptureQuote(quran: "20:8")
                    }

                    Section(header: ArticleHeader("HOW THEY ARE AFFIRMED")) {
                        ArticleParagraph(verbatim: "Ahl as-Sunnah affirm the Names and Attributes exactly as Allah and His Messenger (peace and blessings be upon him) affirmed them: without denying their meanings, without asking how, without changing them into something else, and without likening Allah to His creation. Allah says: \u{201C}There is nothing like unto Him, and He is the Hearing, the Seeing\u{201D} (Quran 42:11).")
                        ScriptureQuote(quran: "42:11", words: 13...18)

                        ArticleParagraph(articleMarkdown: "Allah also warns against **ilhaad (إِلحَاد)** in His names, the deviation named in 7:180 above: denying a name He affirmed, giving Him a name He never gave Himself, or twisting a name away from its meaning. The safe path is the one the Companions walked, affirming what was revealed and saying no more than it says.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("THE NINETY-NINE")) {
                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "bukhari:2736", cite: "Saheeh al-Bukhaari 2736", arabic: 28...39, english: 4...19)

                        ArticleParagraph(articleMarkdown: "The word in the hadith is **ahsaaha (أَحصَاهَا)**, to encompass or take account of. The scholars explain it as more than memorizing the words: it is to learn them, to understand what each one means, to worship Allah by what they require, and to call upon Him with them. Nor does the hadith say that Allah has only ninety-nine: the scholars are agreed that His names are not limited to any list we hold.")
                    }

                    Section(header: ArticleHeader("WHY THE LIST IS NOT IN THE HADITH")) {
                        ArticleParagraph(articleMarkdown: "The familiar numbered list of ninety-nine names does not come from the narration in Bukhaari and Muslim, which states the count and the promise and stops there. The list appears in **Jaami‘ at-Tirmidhi 3507**, an addition the scholars of hadith grade **da‘eef (ضَعِيف)**, weak, held to be the work of a narrator who gathered names from the Quran. So the exact roll of ninety-nine is a scholarly compilation, and is treated as one.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("The Most Beautiful Names are how Allah has made Himself known. Learn them, understand them, and call on Him by them: that is what the promise in the hadith asks for.")
                }

                ArticleSourcesSection(article: "NamesOfAllahPillarView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "NamesOfAllahPillarView")
        .navigationTitle("The 99 Names of Allah")
    }
}

struct QuranPillarView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: the Quran is the literal, final word of Allah, revealed to Prophet Muhammad (peace and blessings be upon him) over 23 years. It is miraculous in its language and perfectly preserved.")
                }


                Section(header: ArticleHeader("OVERVIEW")) {
                    ArticleParagraph(articleMarkdown: "The **Quran (قُرءان)** takes its name from the Arabic root **q-r-a (ق ر أ)**, meaning “to read” or “to recite.” It is the holy book of Islam. It is the literal word of Allah (Glorified and Exalted be He), revealed to Prophet Muhammad (peace and blessings be upon him) through the angel **Jibreel (جِبرِيل)** (Gabriel) over 23 years. It is the ultimate source of guidance for humanity.")

                    ArticleParagraph(verbatim: "Unlike previous scriptures sent to specific nations and later altered, the Quran is a universal message for all people and all times. Allah says in the Quran:")
                    ScriptureQuote(quran: "21:107")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("ELOQUENCE AND MIRACULOUS NATURE")) {
                        ArticleParagraph(verbatim: "One of the most remarkable aspects of the Quran is its unmatched eloquence and literary beauty. It stands as the pinnacle of the Arabic language, setting the standard for vocabulary, syntax, and grammar. The Quran fixed the standard of Classical Arabic, and formal Arabic today still measures itself against it.")

                        ArticleParagraph(verbatim: "The Quran challenged the greatest poets and linguists of its time, many of whom were astounded by its profound imagery, rhythmic flow, and clarity. Allah says in the Quran:")
                        ScriptureQuote(quran: "17:88")

                        ArticleParagraph(articleMarkdown: "What makes the challenge sharper is who it came through. Prophet Muhammad (peace and blessings be upon him) was **ummi (أُمِّيّ)**, unlettered: he could neither read nor write, and had never studied poetry, scripture, or the sciences of language. Allah says:")
                        ScriptureQuote(quran: "29:48")

                        ArticleParagraph(verbatim: "The Arabs of that era were masters of the spoken word. Poetry was their pride, and their finest odes were memorised and celebrated across Arabia. Yet when the Quran was recited to them, they could not place it. It was not poetry, not rhymed prose, not the speech of a soothsayer, and none of their categories fit. They accused him of magic and of madness precisely because they had no literary answer to give. The challenge to produce even a single surah like it (Quran 2:23) was made openly to the very people best equipped to meet it, and it was never met.")
                        ScriptureQuote(quran: "2:23")

                        ArticleParagraph(verbatim: "A man who could not write produced, over 23 years, a book their greatest poets could not imitate. That is the argument the Quran makes about itself.")

                        ArticleParagraph(verbatim: "Despite its eloquence and poetic nature, the Quran remains simple and easy to understand, allowing millions of Muslims to memorize it entirely. This combination of literary perfection and accessibility is one of the Quran's miracles.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("ELOQUENCE AND MIRACULOUS NATURE")) {
                        ArticleParagraph(verbatim: "One of the most remarkable aspects of the Quran is its unmatched eloquence. It stands as the pinnacle of the Arabic language, and it challenged the greatest poets and linguists of its time to produce even a single surah like it:")
                        ScriptureQuote(quran: "2:23")

                        ArticleParagraph(articleMarkdown: "What makes the challenge sharper is who it came through. Prophet Muhammad (peace and blessings be upon him) was **ummi (أُمِّيّ)**, unlettered: he could neither read nor write, and had never studied poetry, scripture, or the sciences of language. A man who could not write produced, over 23 years, a book their greatest poets could not imitate, and the challenge was never met.")
                    }
                }

                Section(header: ArticleHeader("PRESERVATION")) {
                    ArticleParagraph(verbatim: "The Quran is unique among religious scriptures in that it has been perfectly preserved word for word and letter for letter since its revelation. This preservation is due to its widespread memorization by Muslims and its meticulous recording in written form.")

                    ArticleParagraph(verbatim: "Allah promises in the Quran:")
                    ScriptureQuote(quran: "15:9")

                    ArticleParagraph(verbatim: "Millions of Muslims, from children to scholars, continue to memorize the Quran in its entirety, ensuring its unaltered transmission across generations. The Quran's preservation is a testament to its divine origin.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("GUIDANCE AND MESSAGE")) {
                        ArticleParagraph(verbatim: "The Quran is not merely a book of laws or stories; it provides a comprehensive guide for personal, spiritual, and social life. Allah says in the Quran:")
                        ScriptureQuote(quran: "2:2")

                        ArticleParagraph(verbatim: "It addresses themes such as the oneness of Allah, the purpose of life, moral conduct, and preparation for the Hereafter. The Quran calls for justice, compassion, and humility while offering hope and solace to those who reflect on its verses.")
                    }

                    Section(header: ArticleHeader("UNIVERSAL MESSAGE")) {
                        ArticleParagraph(verbatim: "Unlike previous scriptures, which were sent to specific nations and for specific times, the Quran is meant for all of humanity, regardless of race, language, or geography. Allah says in the Quran:")
                        ScriptureQuote(quran: "25:1")

                        ArticleParagraph(verbatim: "The Quran’s universality and timeless guidance make it relevant to every generation, providing solutions to contemporary issues and inspiring billions of people worldwide.")
                    }
                }


                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Unmatched in eloquence yet easy to memorize and understand, the Quran is Allah's protected, universal guidance, relevant to every people and every age.")
                }

                // Where the same question is argued at length (Proving Islam, 2026-09-29).
                Section(header: ArticleHeader("GO DEEPER")) {
                    ArticleDoorRow(door: .article("ProvingPreservationView"))
                    ArticleDoorRow(door: .article("ProvingIjazView"))
                    ArticleDoorRow(door: .article("ProvingStylometryView"))
                }

                ArticleSourcesSection(article: "QuranPillarView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "QuranPillarView")
        .navigationTitle("What is the Quran?")
    }
}

/// How we know the Quran came from Allah to the Prophet (peace be upon him): first from the Quran alone,
/// then from the Sunnah (Abu, 2026-11-24: "How do we know the prophet was given the Quran or that Allah gave
/// it to the prophet? Prove just using the Quran then later u can use Hadith. From Sunni Salafi").
struct QuranRevealedPillarView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "QuranRevealedPillarView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Revealed by Allah")
        .englishArticle().selectableArticleList(article: "QuranRevealedPillarView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: the Quran says who sent it, who brought it down, and to whom: Allah, through the angel Jibreel, to the heart of Muhammad (peace be upon him). Then it gives proofs anyone can check: it came from a man who could not read or write and who had lived forty years among his people without reciting a line of it; it challenges the world to produce one surah like it; it has no contradiction; it reports the unseen; it corrects the very man who recites it; and it was fulfilled in what it foretold. The Sunnah then shows, through those who were there, how the revelation came to him."),
        ]),
        ArticleSection("THE CLAIM THE QURAN MAKES", [
            .text("Most books say nothing about how they came to be. The Quran says it again and again, and it says the same three things every time: it is from Allah, it was brought down by an angel, and it was given to Muhammad (peace be upon him)."),
            .longOnly(.ayah("39:1")),
            .ayah("26:192-195"),
            .longOnly(.text("The Trustworthy Spirit is Jibreel, whom Allah names in another ayah as the one who brought it down upon the Prophet’s heart:")),
            .longOnly(.ayah("2:97", words: 1...10)),
            .longOnly(.text("And Allah describes him, and then the Prophet, so that no one can mistake who brought it or who received it:")),
            .longOnly(.ayah("81:19-24")),
            .longOnly(.ayah("53:2-5")),
            .shortOnly(.text("The Trustworthy Spirit is Jibreel, the angel who brought it down upon the Prophet’s heart.")),
            .markdown("So the Quran is not a book **about** revelation, written by a man. It presents itself, line after line, as the very speech of Allah, delivered to the Prophet word for word, and the Prophet only as the one who conveyed it. The rest of this page asks whether that claim holds: first from the Quran alone, then from the Sunnah."),
            .callout("The Quran’s proofs are not “believe it because it says so.” Each one points to something outside the page that anyone can test: the man’s own life, a challenge that is still open, events that came true, and a text that can be searched for contradiction.", title: "Not a circle", icon: "arrow.triangle.2.circlepath"),
        ]),
        ArticleSection("PART ONE: FROM THE QURAN", [
            .text("Allah answered every explanation the Prophet’s people offered for the Quran, and in answering them He gave the proofs. Nine of them follow, each in the Quran’s own words."),
        ]),
        ArticleSection("1. HE COULD NOT READ OR WRITE", [
            .ayah("29:48"),
            .markdown("The Prophet (peace be upon him) is **an-nabi al-ummi (النَّبِيّ الأُمِّيّ)**, the unlettered prophet. He read no earlier scripture and wrote nothing with his own hand. Had he been a reader of books, the ayah says, his enemies would have had a reason to doubt. They knew him from childhood, and they never claimed he could read."),
            .longOnly(.ayah("7:157", words: 0...11)),
            .longOnly(.text("Yet the book he recited carries the stories of the prophets with details that differ from the versions in the Torah and the Gospel, laws of inheritance, worship and trade, and an Arabic that the masters of the language could not match. An unlettered man reciting it from nowhere is the very thing that needs explaining.")),
        ]),
        ArticleSection("2. FORTY YEARS WITHOUT A LINE OF IT", [
            .text("He lived among Quraysh for forty years before the revelation began, known to them as truthful and trustworthy, and in all that time he recited nothing like it. Allah told him to point to that:"),
            .ayah("10:16"),
            .longOnly(.text("And Allah says he did not even know, before it came, what a scripture was, and was not expecting one:")),
            .longOnly(.ayah("42:52", words: 0...12)),
            .longOnly(.ayah("28:86", words: 0...10)),
            .longOnly(.text("A poet sharpens his gift from youth, and an orator is known for his speeches long before his best one. Here a man of forty, with no record of poetry or speeches, began to recite a book that silenced the poets.")),
        ]),
        ArticleSection("3. THE CHALLENGE NO ONE HAS MET", [
            .longOnly(.text("His people said he had made it up. Allah answered that if a man made it up, other men can make one like it, and the challenge narrows as it goes: a whole Quran like it, then ten surahs, then a single surah:")),
            .longOnly(.ayah("17:88")),
            .longOnly(.ayah("52:33-34")),
            .longOnly(.ayah("11:13")),
            .shortOnly(.text("His people said he had made it up. Allah answered that if a man made it up, other men can make one like it, and challenged them to produce a single surah:")),
            .ayah("2:23-24"),
            .text("Quraysh were the masters of Arabic eloquence, and they were desperate to stop him. They fought him, boycotted him, and drove him out of his city, at the cost of their own lives and wealth. Composing a short surah would have ended his call at no cost at all. They never did it, and the challenge is still open."),
            .door(.article("ProvingIjazView")),
        ]),
        ArticleSection("4. NO CONTRADICTION IN IT", [
            .ayah("4:82"),
            .text("The Quran came down over twenty-three years, in Makkah and Madinah, in peace and in war, in times of grief and of victory, much of it answering events as they happened. A man’s words over such a span change with his moods and his circumstances, and he forgets what he said years before. The Quran agrees with itself from its first surah to its last, and it invites anyone to look for a contradiction."),
            .longOnly(.ayah("41:42")),
            .longOnly(.ayah("18:1")),
        ]),
        ArticleSection("5. NEWS OF THE UNSEEN", [
            .text("Again and again the Quran tells the story of a past people and then reminds the Prophet that he was not there and could not have known it:"),
            .ayah("11:49"),
            .longOnly(.ayah("3:44")),
            .longOnly(.ayah("28:44-46")),
            .text("And it told of the future in ways that could have been proven false. It said the Byzantines, freshly defeated by the Persians, would win within a few years, and they did:"),
            .ayah("30:2-4", words: 0...12),
            .longOnly(.text("And it said that his uncle Abu Lahab, his bitterest enemy, would burn in the Fire. Abu Lahab lived for years after that surah came down, and he could have refuted it with a single sentence, by declaring that he was a Muslim, even falsely. He died a disbeliever, as the surah said.")),
            .longOnly(.ayah("111:1-3")),
            .door(.provingIslam),
        ]),
        ArticleSection("6. IT CORRECTS THE MAN WHO RECITES IT", [
            .longOnly(.text("A man who writes his own book does not fill it with rebukes of himself and then read them aloud to his followers and his enemies. The Quran corrects the Prophet (peace be upon him) by name, and he recited every word of it. When he turned from a blind man who came asking to be taught, toward a leader of the idolaters he hoped to win over, Allah revealed:")),
            .longOnly(.ayah("80:1-10")),
            .longOnly(.hadith("tirmidhi:3331", cite: "Jaami‘ at-Tirmidhi 3331; graded saheeh by al-Albaani", arabic: 25...32, english: [0...13])),
            .longOnly(.text("When he gave the hypocrites permission to stay behind from an expedition:")),
            .shortOnly(.text("A man who writes his own book does not fill it with rebukes of himself and then read them aloud to his followers and his enemies. The Quran corrects the Prophet (peace be upon him) by name, and he recited every word of it. When he gave the hypocrites permission to stay behind from an expedition, Allah revealed:")),
            .ayah("9:43"),
            .longOnly(.text("When he forbade himself something lawful to please his wives:")),
            .longOnly(.ayah("66:1")),
            .longOnly(.text("And Allah disclosed what he had kept within himself, and told him that Allah had more right to be feared than the people:")),
            .longOnly(.ayah("33:37", words: 13...24)),
            .longOnly(.text("Aa’ishah’s comment on that ayah is quoted in Part Two below.")),
        ]),
        ArticleSection("7. HE IS WARNED AGAINST CHANGING IT", [
            .text("His people asked him to bring a different Quran, or to soften this one. Allah commanded him to answer that it was not his to change:"),
            .ayah("10:15", words: 16...30),
            .text("And Allah warned that if he had invented one word and attributed it to Him, He would have seized him:"),
            .ayah("69:43-47"),
            .longOnly(.ayah("17:73-75")),
            .longOnly(.text("A man inventing a religion writes himself as safe and honoured. The Quran describes its own messenger as a servant who would be destroyed for changing a single line, and commands him to convey all of it:")),
            .longOnly(.ayah("5:67", words: 1...14)),
            .shortOnly(.text("A man inventing a religion writes himself as safe and honoured. The Quran describes its own messenger as a servant who would be destroyed for changing a single line.")),
        ]),
        ArticleSection("8. HE WAITED FOR IT", [
            .text("When revelation came, he would hurry to repeat it for fear of losing a word. Allah told him not to, because keeping it was Allah’s work, not his:"),
            .ayah("75:16-19"),
            .longOnly(.ayah("20:114", words: 4...12)),
            .longOnly(.ayah("87:6")),
            .longOnly(.text("And it came down in stages over twenty-three years, often in answer to a question or an event, rather than all at once. His enemies objected to that, and Allah answered them:")),
            .longOnly(.ayah("25:32-33")),
            .longOnly(.ayah("17:106")),
            .text("So the Prophet could not bring an answer when he wished. He had to wait for it, as the Sunnah below shows in a case where the wait was a whole month and the matter was his own family."),
        ]),
        ArticleSection("9. ALLAH IS THE WITNESS", [
            .text("Above all of these, Allah Himself bears witness to what He sent down, and the angels with Him:"),
            .ayah("4:166"),
            .longOnly(.ayah("6:19", words: 0...17)),
            .longOnly(.text("And He says that those who knew the earlier scripture recognised it as sent down from Him in truth:")),
            .longOnly(.ayah("6:114", words: 10...18)),
            .longOnly(.ayah("13:43")),
        ]),
        ArticleSection("PART TWO: FROM THE SUNNAH", [
            .text("The Quran gives the proof; the Sunnah gives the witnesses. The Companions who lived with the Prophet (peace be upon him) described what they saw when the revelation came to him, and they told it in narrations as sound as any report can be."),
        ]),
        ArticleSection("HOW IT BEGAN", [
            .longOnly(.text("Aa’ishah (may Allah be pleased with her) narrated how the revelation began, in the cave of Hira, as the Prophet described it:")),
            .longOnly(.hadith("bukhari:3", cite: "Saheeh al-Bukhaari 3, Saheeh Muslim 160", arabic: 84...144, english: [103...253])),
            .shortOnly(.text("Aa’ishah (may Allah be pleased with her) narrated how the revelation began: the angel came to the Prophet in the cave of Hira and asked him to read.")),
            .text("He came home trembling and asked to be covered, fearing for himself. He did not come down from the mountain announcing a new religion. Khadeejah took him to her cousin Waraqah ibn Nawfal, an old man who knew the earlier scriptures, and Waraqah recognised what he had met:"),
            .hadith("bukhari:3", cite: "Saheeh al-Bukhaari 3", arabic: 278...284, english: [438...454]),
            .longOnly(.text("Then the revelation paused. When it returned, the Prophet saw the same angel again:")),
            .longOnly(.hadith("bukhari:4", cite: "Saheeh al-Bukhaari 4, Saheeh Muslim 161", arabic: 27...68, english: [0...99])),
        ]),
        ArticleSection("WHAT THE COMPANIONS SAW", [
            .text("Al-Haarith ibn Hishaam asked him how the revelation came, and Aa’ishah added what she herself saw:"),
            .hadith("bukhari:2", cite: "Saheeh al-Bukhaari 2, Saheeh Muslim 2333", arabic: 55...101, english: [29...109]),
            .longOnly(.text("Zayd ibn Thaabit (may Allah be pleased with him), the scribe of the revelation, felt its weight in his own body. An ayah came down while the Prophet’s thigh was resting on his:")),
            .longOnly(.hadith("bukhari:2832", cite: "Saheeh al-Bukhaari 2832", arabic: 81...110, english: [109...138])),
            .longOnly(.markdown("This is the “heavy word” Allah told him He would cast upon him (Quran 73:5). Sweat on a freezing day and a weight that could crush a man’s thigh are not the signs of someone composing verses at his leisure.")),
            .shortOnly(.text("This is the “heavy word” Allah told him He would cast upon him (Quran 73:5). Sweat on a freezing day is not the sign of someone composing verses at his leisure.")),
            .ayah("73:5"),
        ]),
        ArticleSection("HE COULD NOT HURRY IT, AND HE HAD TO WAIT FOR IT", [
            .longOnly(.text("Ibn Abbaas (may Allah be pleased with them both) explained the ayah about not moving the tongue, and showed how the Prophet’s lips used to move as he received it:")),
            .longOnly(.hadith("bukhari:5", cite: "Saheeh al-Bukhaari 5, Saheeh Muslim 448", arabic: 32...46, english: [23...43])),
            .longOnly(.text("Then the aayaat of Surah al-Qiyaamah came down, and Ibn Abbaas described what changed:")),
            .longOnly(.hadith("bukhari:5", cite: "Saheeh al-Bukhaari 5", arabic: 111...134, english: [213...238])),
            .longOnly(.text("And when the hypocrites slandered Aa’ishah, his own wife, the matter that touched him most closely of all, he could not settle it himself. Aa’ishah said:")),
            .shortOnly(.text("When the hypocrites slandered Aa’ishah, his own wife, the matter that touched him most closely of all, he could not settle it himself. Aa’ishah said:")),
            .hadith("bukhari:4141", cite: "Saheeh al-Bukhaari 4141, Saheeh Muslim 2770", arabic: 1104...1112, english: [1755...1768]),
            .text("A whole month of grief, rumour, and questions, and no verse. Then Allah revealed her innocence in Surah an-Noor (Quran 24:11-20). A man who wrote his own revelation would not have left himself and his family in that pain for a month when a few sentences would have ended it."),
            .ayah("24:11"),
        ]),
        ArticleSection("HE HID NOTHING OF IT", only: .long, [
            .text("Some of what came down was hard on him, and he conveyed it anyway, exactly as it came. Of the ayah in Surah al-Ahzaab quoted in Part One, Aa’ishah (may Allah be pleased with her) said:"),
            .hadith("muslim:177b", cite: "Saheeh Muslim 177; and Saheeh al-Bukhaari 7420", arabic: 17...57, english: [3...76]),
        ]),
        ArticleSection("JIBREEL REVIEWED IT WITH HIM", only: .long, [
            .text("Every Ramadan the angel who brought it went over it with him, and in his final year twice:"),
            .hadith("bukhari:4998", cite: "Saheeh al-Bukhaari 4998", arabic: 17...35, english: [0...27]),
            .markdown("This is **al-‘ardah al-aakhirah (العَرضَة الأَخِيرَة)**, the final review: the Quran as it stood when the revelation was complete, the text the Companions then gathered into the Mushaf."),
            .door(.article("CompileView")),
        ]),
        ArticleSection("HIS OWN WORDS ABOUT IT", [
            .text("He named the Quran as the sign he had been given, the way earlier prophets had been given their miracles:"),
            .hadith("bukhari:4981", cite: "Saheeh al-Bukhaari 4981, Saheeh Muslim 152", arabic: 24...49, english: [4...47]),
            .text("The staff of Moosa and the healing of Eesa were seen by the people of their time and then ended. The sign given to Muhammad (peace be upon him) is still here, and can still be examined by anyone who reads it."),
        ]),
        ArticleSection("WHAT HIS PEOPLE KNEW OF HIM", only: .long, [
            .text("When he first called his people openly, from the hill of as-Safa, he asked them whether they would believe him if he told them an army was behind the hill. Their answer is the testimony of his enemies:"),
            .hadith("bukhari:4971", cite: "Saheeh al-Bukhaari 4971, Saheeh Muslim 208", arabic: 56...73, english: [43...73]),
            .longOnly(.text("Years later the Byzantine emperor Heraclius questioned Abu Sufyaan, then still the Prophet’s enemy, and drew the conclusion that follows from it:")),
            .longOnly(.hadith("bukhari:7", cite: "Saheeh al-Bukhaari 7, Saheeh Muslim 1773", arabic: 331...355, english: [585...629])),
            .text("A man who would not lie about the smallest thing to his own people for forty years did not begin, at forty, to lie about Allah."),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .longOnly(.markdown("**Is it circular to prove the Quran from the Quran?**")),
            .longOnly(.text("No. A circular argument says “it is true because it says it is true.” The Quran says something different: here is a man you know, here is a challenge you can try, here are events that will come true, here is a book you can search for contradiction. Each of those is checked outside the page, against history, language, and the reader’s own reason. That is why Allah asks, “Then do they not reflect upon the Quran?” (Quran 4:82) and not simply “believe it.”")),
            .markdown("**Could he have learned it from Jews or Christians?**"),
            .text("His enemies said so, and Allah answered them in the same breath: the man they meant did not even speak Arabic, and this is a Quran in clear Arabic."),
            .ayah("16:103"),
            .longOnly(.text("They also said scribes were dictating old legends to him morning and evening, which the Quran answers by pointing to the One who knows every secret:")),
            .longOnly(.ayah("25:4-6")),
            .door(.article("ProvingSourcesView")),
            .longOnly(.markdown("**Could it have been his own genius, or poetry?**")),
            .longOnly(.text("The Arabs knew poetry better than any people, and Allah said it is not poetry, and that poetry was not even befitting for him:")),
            .longOnly(.ayah("36:69")),
            .longOnly(.text("His own words survive too, in thousands of authentic hadiths, and they read in a plainly different voice from the Quran: a man’s speech beside a revelation he conveyed.")),
            .longOnly(.door(.article("ProvingStylometryView"))),
            .longOnly(.markdown("**Could a jinn or a devil have brought it?**")),
            .longOnly(.text("The Quran denies it outright, and its content denies it too: a book that commands seeking refuge in Allah from Shaytaan (Quran 16:98), calls him an open enemy (Quran 35:6), and calls to the worship of Allah alone is the last thing a devil would bring.")),
            .longOnly(.ayah("26:210-212")),
            .longOnly(.ayah("81:25")),
            .longOnly(.ayah("16:98")),
            .longOnly(.ayah("35:6", words: 0...5)),
            .longOnly(.markdown("**Why did it come down in stages and not all at once?**")),
            .longOnly(.text("To strengthen his heart, to answer events as they happened, and so that it could be recited to the people slowly, learnt, and lived, as the aayaat of Surah al-Furqaan and Surah al-Isra quoted in Part One say. That also made the challenge harder: a forger revising a text in private can make it consistent, but a text spoken aloud piece by piece over twenty-three years cannot be revised.")),
            .longOnly(.markdown("**How do we know the Quran we have is the Quran he was given?**")),
            .longOnly(.text("Allah promised to guard it, the Companions memorised it from his mouth and wrote it in his lifetime, Jibreel reviewed it with him in his final year, and the Companions gathered it into one Mushaf from what was written and memorised. That history has its own page.")),
            .longOnly(.ayah("15:9")),
            .longOnly(.door(.article("CompileView"))),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("The Quran says it is the speech of Allah, brought down by Jibreel to the heart of Muhammad (peace be upon him), and it proves the claim with what anyone can check: an unlettered man, forty silent years, a challenge never met, no contradiction, the unseen told and the future fulfilled, and a messenger corrected and warned in his own book. The Sunnah adds the witnesses who saw the revelation come down on him and heard him convey it, unchanged and unhidden."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .markdown("**Wahy (وَحي)**: from **و-ح-ي**, a swift and hidden communication. In the Sharee‘ah it is Allah’s making known His speech to a prophet, as in “It is not but a revelation revealed” (Quran 53:4)."),
            .markdown("**Tanzeel (تَنزِيل)**: from **ن-ز-ل**, to come down: the sending down of the Quran from Allah. The Quran calls itself “a revelation (tanzeel) from the Lord of the worlds” (Quran 26:192), which tells the reader where it comes from: from above, not from the man."),
            .markdown("**Ar-Rooh al-Ameen (الرُّوح الأَمِين)**: “the Trustworthy Spirit,” and **Rooh al-Qudus (رُوح القُدُس)**, “the Pure Spirit”: names of Jibreel, the angel who brought the Quran down (Quran 26:193, 16:102, 2:97)."),
            .ayah("16:102"),
            .markdown("**An-Nabi al-Ummi (النَّبِيّ الأُمِّيّ)**: the unlettered prophet, from **umm**, mother: one who remains, in reading and writing, as his mother bore him. It is a sign of his prophethood, not a flaw, because it closes the door to the claim that he copied his book (Quran 7:157, 29:48)."),
            .markdown("**At-Tahaddi (التَّحَدِّي)**: the challenge: Allah’s demand that the deniers produce a book, then ten surahs, then one surah like the Quran (Quran 52:34, 11:13, 2:23)."),
            .markdown("**I‘jaaz (إِعجَاز)**: from **ع-ج-ز**, to be unable: the Quran’s rendering every opponent unable to meet that challenge. What does this to people is called a **mu‘jizah (مُعجِزَة)**, a miracle."),
            .markdown("**Al-Ardah al-Aakhirah (العَرضَة الأَخِيرَة)**: the final review, from **‘arada**, to present: Jibreel and the Prophet going over the whole Quran together twice in his last Ramadan (Saheeh al-Bukhaari 4998)."),
        ]),
    ]
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
        MuqattaatRow(number: 23, surah: "ash-Shoora", order: 42, letters: "Ha Mim; Ain Sin Qaf", arabic: "حمٓ عٓسٓقٓ", completeAyah: "Yes, 2 ayahs"),
        MuqattaatRow(number: 1, surah: "al-Baqarah", order: 2, letters: "Alif Lam Mim", arabic: "الٓمٓ", completeAyah: "Yes"),
        MuqattaatRow(number: 2, surah: "Al Imraan", order: 3, letters: "Alif Lam Mim", arabic: "الٓمٓ", completeAyah: "Yes"),
        MuqattaatRow(number: 3, surah: "al-A‘raaf", order: 7, letters: "Alif Lam Mim Sad", arabic: "الٓمٓصٓ", completeAyah: "Yes"),
        MuqattaatRow(number: 10, surah: "Maryam", order: 19, letters: "Kaf Ha Ya Ain Sad", arabic: "كٓهيعٓصٓ", completeAyah: "Yes"),
        MuqattaatRow(number: 11, surah: "Ta Ha", order: 20, letters: "Ta Ha", arabic: "طه", completeAyah: "Yes"),
        MuqattaatRow(number: 12, surah: "ash-Shu‘ara", order: 26, letters: "Ta Sin Mim", arabic: "طسٓمٓ", completeAyah: "Yes"),
        MuqattaatRow(number: 14, surah: "al-Qasas", order: 28, letters: "Ta Sin Mim", arabic: "طسٓمٓ", completeAyah: "Yes"),
        MuqattaatRow(number: 15, surah: "al-Ankaboot", order: 29, letters: "Alif Lam Mim", arabic: "الٓمٓ", completeAyah: "Yes"),
        MuqattaatRow(number: 16, surah: "ar-Room", order: 30, letters: "Alif Lam Mim", arabic: "الٓمٓ", completeAyah: "Yes"),
        MuqattaatRow(number: 17, surah: "Luqmaan", order: 31, letters: "Alif Lam Mim", arabic: "الٓمٓ", completeAyah: "Yes"),
        MuqattaatRow(number: 18, surah: "as-Sajdah", order: 32, letters: "Alif Lam Mim", arabic: "الٓمٓ", completeAyah: "Yes"),
        MuqattaatRow(number: 19, surah: "Ya Sin", order: 36, letters: "Ya Sin", arabic: "يسٓ", completeAyah: "Yes"),
        MuqattaatRow(number: 21, surah: "Ghaafir", order: 40, letters: "Ha Mim", arabic: "حمٓ", completeAyah: "Yes"),
        MuqattaatRow(number: 22, surah: "Fussilat", order: 41, letters: "Ha Mim", arabic: "حمٓ", completeAyah: "Yes"),
        MuqattaatRow(number: 24, surah: "az-Zukhruf", order: 43, letters: "Ha Mim", arabic: "حمٓ", completeAyah: "Yes"),
        MuqattaatRow(number: 25, surah: "ad-Dukhaan", order: 44, letters: "Ha Mim", arabic: "حمٓ", completeAyah: "Yes"),
        MuqattaatRow(number: 26, surah: "al-Jaathiyah", order: 45, letters: "Ha Mim", arabic: "حمٓ", completeAyah: "Yes"),
        MuqattaatRow(number: 27, surah: "al-Ahqaaf", order: 46, letters: "Ha Mim", arabic: "حمٓ", completeAyah: "Yes"),
        MuqattaatRow(number: 4, surah: "Yoonus", order: 10, letters: "Alif Lam Ra", arabic: "الٓر", completeAyah: "No"),
        MuqattaatRow(number: 5, surah: "Hood", order: 11, letters: "Alif Lam Ra", arabic: "الٓر", completeAyah: "No"),
        MuqattaatRow(number: 6, surah: "Yoosuf", order: 12, letters: "Alif Lam Ra", arabic: "الٓر", completeAyah: "No"),
        MuqattaatRow(number: 7, surah: "ar-Ra‘d", order: 13, letters: "Alif Lam Mim Ra", arabic: "الٓمٓر", completeAyah: "No"),
        MuqattaatRow(number: 8, surah: "Ibraaheem", order: 14, letters: "Alif Lam Ra", arabic: "الٓر", completeAyah: "No"),
        MuqattaatRow(number: 9, surah: "al-Hijr", order: 15, letters: "Alif Lam Ra", arabic: "الٓر", completeAyah: "No"),
        MuqattaatRow(number: 13, surah: "an-Naml", order: 27, letters: "Ta Sin", arabic: "طسٓ", completeAyah: "No"),
        MuqattaatRow(number: 20, surah: "Sad", order: 38, letters: "Sad", arabic: "صٓ", completeAyah: "No"),
        MuqattaatRow(number: 28, surah: "Qaaf", order: 50, letters: "Qaf", arabic: "قٓ", completeAyah: "No"),
        MuqattaatRow(number: 29, surah: "al-Qalam", order: 68, letters: "Nun", arabic: "نٓ", completeAyah: "No"),
    ]

    private var arabicFont: Font {
        Font.arabic(appearance.quranArabicFontName, size: UIFont.preferredFont(forTextStyle: .title2).pointSize)
    }

    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: the Muqatta‘aat are the disconnected letters (like Alif-Lam-Meem) that open twenty-nine surahs, recited letter by letter.")
                }

                Section(header: ArticleHeader("WATCH")) {
                    ArticleVideoLink(title: "The separated letters, and how to recite them", url: "https://www.youtube.com/watch?v=6_gKg6PByOI")
                }

                Section(header: ArticleHeader("MUQATTA‘AAT")) {
                    ArticleParagraph(articleMarkdown: "**Muqatta‘aat (مُقَطَّعَات)**, from the root **q-t-a (ق ط ع)** meaning to cut or sever, are the disconnected opening letters that appear at the beginning of 29 surahs, after the Basmalah where the Basmalah is recited.")

                    ArticleParagraph(verbatim: "They are also called fawaatih, meaning openers, because they open their surahs. Their exact meaning is known to Allah; Muslims recite them as revealed without claiming a hidden meaning with certainty.")

                    Text(verbatim: "Four surahs are named directly for these letters: Ta Ha, Ya Sin, Sad, and Qaaf. Some also include Noon because Surah al-Qalam opens with Noon.")
                        .font(.body)
                        .foregroundColor(appearance.accent)
                }

                Section(header: ArticleHeader("PATTERNS")) {
                    ArticleParagraph(verbatim: "There are 14 distinct combinations. The most frequent are Alif Lam Meem and Ha Meem, each appearing six times.")

                    ArticleParagraph(verbatim: "The letters used are half of the Arabic alphabet: ا هـ ح ط ي ك ل م ن س ع ص ق ر.")

                    ArticleParagraph(verbatim: "Most combinations begin with either Alif Lam or Ha Meem. In most of these surahs, the opening letters are followed very soon by mention of the Quran, the Book, revelation, or signs.")
                }

                Section(header: ArticleHeader("RECITATION NOTE")) {
                    ArticleParagraph(verbatim: "In the app's tajweed coloring, complete muqatta‘aat ayahs are treated as opening-letter recitation. Bare letters stay normal unless they are heavy letters, while letters with maddah are treated as madd laazim.")

                    ArticleParagraph(verbatim: "If the muqatta‘aat are not the whole ayah, only the first word receives that special opening-letter handling; the rest of the ayah uses normal tajweed rules. For ash-Shoora, this handling applies to both of the first two ayahs.")
                }

                Section(header: ArticleHeader("TABLE")) {
                    ForEach(rows) { row in
                        muqattaatRow(row)
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Their precise meaning is known to Allah; the believer recites them as revealed, and they testify to the Quran's inimitable nature.")
                }

                ArticleSourcesSection(article: "MuqattaatPillarView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Muqatta‘aat Letters")
        .englishArticle().selectableArticleList(article: "MuqattaatPillarView")
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
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: Prophet Muhammad (peace and blessings be upon him) is the final messenger of Allah, sent as a mercy to all creation. He conveyed the Quran and embodied it in his character.")
                }


                ArticleOnly(.long) {
                    Section(header: ArticleHeader("OVERVIEW")) {
                        ArticleParagraph(articleMarkdown: "Prophet **Muhammad (مُحَمَّد)**, “the Praised One,” was born in **Makkah (مَكَّة)** (in present-day Saudi Arabia) around 570 CE, into the noble tribe of Quraysh. Orphaned young, he became known as **Al-Ameen (الأَمِين)**, “the Trustworthy,” for his honesty and upright character.")

                        ArticleParagraph(articleMarkdown: "At the age of 40, while worshipping in the cave of **Hira (حِرَاء)**, he received his first revelation from Allah (Glorified and Exalted be He) through the angel **Jibreel (جِبرِيل)** (Gabriel). This marked the beginning of his prophethood and the revelation of the Quran, the final divine guidance for humanity.")

                        ArticleParagraph(articleMarkdown: "In Islamic tradition he is called both a **Rasool (رَسُول)**, “Messenger,” and a **Nabi (نَبِيّ)**, “Prophet.” One common explanation is that a Rasool is sent with a message to a people, while a Nabi receives revelation and reinforces an existing law; the scholars differ on the exact distinction, and the Quran calls Haaroon and Ismaa‘eel messengers as well (Quran 20:47, 19:54).")
                        ScriptureQuote(quran: "20:47", words: 2...4)
                        ScriptureQuote(quran: "19:54", words: 8...10)

                        ArticleParagraph(verbatim: "He called people to worship Allah alone, rejecting idolatry and emphasizing justice, compassion, and respect for the marginalized. His teachings addressed all facets of life, including spiritual, social, economic, and political matters, as well as personal conduct and morality.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("OVERVIEW")) {
                        ArticleParagraph(articleMarkdown: "Prophet **Muhammad (مُحَمَّد)**, “the Praised One,” was born in **Makkah (مَكَّة)** (in present-day Saudi Arabia) around 570 CE, into the noble tribe of Quraysh. Orphaned young, he became known as **Al-Ameen (الأَمِين)**, “the Trustworthy,” for his honesty and upright character.")

                        ArticleParagraph(articleMarkdown: "At the age of 40, while worshipping in the cave of **Hira (حِرَاء)**, he received his first revelation from Allah (Glorified and Exalted be He) through the angel **Jibreel (جِبرِيل)** (Gabriel). This marked the beginning of his prophethood and the revelation of the Quran, the final divine guidance for humanity.")

                        ArticleParagraph(verbatim: "He called people to worship Allah alone, rejecting idolatry and emphasizing justice, compassion, and respect for the marginalized. His teachings addressed all facets of life, including spiritual, social, economic, and political matters, as well as personal conduct and morality.")
                    }
                }

                Section(header: ArticleHeader("FINAL PROPHET")) {
                    ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:")
                    ScriptureQuote(quran: "33:40")

                    ArticleParagraph(verbatim: "Prophet Muhammad (peace and blessings be upon him) is the last and final prophet, completing the chain of messengers that began with Aadam (peace be upon him). He delivered the final revelation, the Quran, and exemplified its teachings as the ultimate role model.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("HIS CHARACTER")) {
                        ArticleParagraph(verbatim: "Prophet Muhammad (peace and blessings be upon him) is described in the Quran as a man of exemplary character. Allah says in the Quran:")
                        ScriptureQuote(quran: "68:4")

                        ArticleParagraph(verbatim: "He was known for his compassion, humility, and justice. Even toward his enemies, he demonstrated forgiveness and kindness. Aa’ishah (may Allah be pleased with her), his wife, described him by saying:")
                        ScriptureQuote(hadith: "muslim:746a", cite: "Saheeh Muslim 746", arabic: 232...241, english: 293...303)

                        ArticleParagraph(verbatim: "Allah also says in the Quran:")
                        ScriptureQuote(quran: "33:21")

                        ArticleParagraph(verbatim: "Obedience to the Prophet (peace and blessings be upon him) is also linked to obedience to Allah. Allah says in the Quran:")
                        ScriptureQuote(quran: "4:80")

                        ArticleParagraph(verbatim: "His humility is evident in many of his interactions. When a companion's voice trembled as he talked to the prophet, the prophet (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "ibnmajah:3312", cite: "Sunan Ibn Maajah 3312; graded saheeh by al-Albaani", arabic: 39...49, english: 24...44)

                        ArticleParagraph(verbatim: "He also said:")
                        ScriptureQuote(text: "“I eat as the servant eats, and I sit as the servant sits, for I am only a servant” (as-Silsilah as-Saheehah 544; authenticated by al-Albaani).", arabic: "آكُلُ كَمَا يَأكُلُ العَبدُ، وَأَجلِسُ كَمَا يَجلِسُ العَبدُ، فَإِنَّمَا أَنَا عَبدٌ", dimmed: true)

                        ArticleParagraph(verbatim: "Similarly, the Prophet (peace and blessings be upon him) warned against excessive praise, saying:")
                        ScriptureQuote(hadith: "bukhari:3445", cite: "Saheeh al-Bukhaari 3445", arabic: 36...49, english: 6...35)
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("HIS CHARACTER")) {
                        ArticleParagraph(verbatim: "Prophet Muhammad (peace and blessings be upon him) is described in the Quran as a man of exemplary character. Allah says in the Quran:")
                        ScriptureQuote(quran: "68:4")

                        ArticleParagraph(verbatim: "He was known for his compassion, humility, and justice. Even toward his enemies, he demonstrated forgiveness and kindness. Aa’ishah (may Allah be pleased with her), his wife, described him by saying:")
                        ScriptureQuote(hadith: "muslim:746a", cite: "Saheeh Muslim 746", arabic: 232...241, english: 293...303)

                        ArticleParagraph(verbatim: "Allah also says in the Quran:")
                        ScriptureQuote(quran: "33:21")
                    }
                }

                Section(header: ArticleHeader("HIS TEACHINGS")) {
                    ArticleParagraph(articleMarkdown: "The teachings and practices of Prophet Muhammad (peace and blessings be upon him) are called the **Sunnah (سُنَّة)**, which serve as a guide for Muslims to live a righteous and balanced life. He perfectly demonstrated how to implement the Quran in daily life.")

                    ArticleParagraph(verbatim: "While Muslims deeply love and revere him, worship is reserved for Allah (Glorified and Exalted be He) alone. He is honored as the finest example of humanity, yet never viewed as divine.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("HIS IMPACT")) {
                        ArticleParagraph(verbatim: "Prophet Muhammad (peace and blessings be upon him) is considered one of the most influential figures in history. Historian Michael H. Hart ranked him as the most influential person of all time, citing his unparalleled success both religiously and politically. With the will of Allah, he unified Arabia under Islam and established a faith that continues to inspire billions.")

                        ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:")
                        ScriptureQuote(quran: "21:107")
                    }

                    Section(header: ArticleHeader("HIS LEGACY")) {
                        ArticleParagraph(verbatim: "Prophet Muhammad (peace and blessings be upon him) passed away at the age of 63 in Madinah, leaving behind the Quran and Sunnah as guidance for humanity. In his Farewell Sermon, he emphasized the equality of all people, adherence to the Book of Allah (Saheeh Muslim 1218), and the importance of justice and righteousness.")
                        ScriptureQuote(hadith: "muslim:1218a", cite: "Saheeh Muslim 1218", arabic: 875...886, english: 1470...1490)

                        ArticleParagraph(verbatim: "He said:")
                        ScriptureQuote(text: "“O people, your Lord is one and your father is one. There is no superiority of an Arab over a non-Arab, nor of a non-Arab over an Arab, nor of a red (light-skinned) person over a black person, nor of a black person over a red person, except by taqwa” (Musnad Ahmad 23489; graded saheeh by al-Albaani, as-Silsilah as-Saheehah 2700, and by Shu‘ayb al-Arnaa’oot).", arabic: "يَا أَيُّهَا النَّاسُ، أَلَا إِنَّ رَبَّكُم وَاحِدٌ، وَإِنَّ أَبَاكُم وَاحِدٌ، أَلَا لَا فَضلَ لِعَرَبِيٍّ عَلَى عَجَمِيٍّ، وَلَا لِعَجَمِيٍّ عَلَى عَرَبِيٍّ، وَلَا أَحمَرَ عَلَى أَسوَدَ، وَلَا أَسوَدَ عَلَى أَحمَرَ، إِلَّا بِالتَّقوَى", dimmed: true)

                        ArticleParagraph(verbatim: "This is the Quran's own standard:")
                        ScriptureQuote(quran: "49:13", words: 11...15)
                    }
                }


                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("As the seal of the prophets and the finest example for humanity, he is deeply loved and followed, yet he is never worshipped, for worship belongs to Allah alone.")
                }

                // Where the same question is argued at length (Proving Islam, 2026-09-29).
                Section(header: ArticleHeader("GO DEEPER")) {
                    ArticleDoorRow(door: .article("ProvingProphetView"))
                    ArticleDoorRow(door: .article("ProvingProphecyView"))
                    ArticleDoorRow(door: .provingIslam)
                }

                ArticleSourcesSection(article: "ProphetPillarView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "ProphetPillarView")
        .navigationTitle("Who is the Prophet?")
    }
}

struct SunnahPillarView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: the Sunnah is the way of Prophet Muhammad (peace and blessings be upon him): his words, actions, and approvals. It explains the Quran and is the second source of Islam.")
                }


                Section(header: ArticleHeader("OVERVIEW")) {
                    ArticleParagraph(articleMarkdown: "The **Sunnah (سُنَّة)**, an Arabic word meaning “way,” “path,” or “tradition,” is the teachings, actions, and approvals of Prophet Muhammad (peace and blessings be upon him): his habits, moral conduct, and guidance on worship and dealings. It explains and complements the Quran and is the second source of Islamic knowledge.")

                    ArticleParagraph(verbatim: "Allah says in the Quran:")
                    ScriptureQuote(quran: "59:7", words: 23...36)
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("IMPORTANCE")) {
                        ArticleParagraph(verbatim: "The Sunnah provides practical guidance on how to live according to the Quran. It clarifies general commands in the Quran and gives specific instructions. For instance, the Quran commands Muslims to pray, and the Sunnah demonstrates how to perform the prayer.")

                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "bukhari:631", cite: "Saheeh al-Bukhaari 631", arabic: 73...76, english: 98...104)

                        ArticleParagraph(verbatim: "The Sunnah also serves as an example for personal conduct and social interactions. Allah says in the Quran:")
                        ScriptureQuote(quran: "33:21")

                        ArticleParagraph(verbatim: "Obedience to the Sunnah is considered obedience to Allah. Allah says in the Quran:")
                        ScriptureQuote(quran: "4:80")
                    }

                    Section(header: ArticleHeader("HADITH LITERATURE")) {
                        ArticleParagraph(articleMarkdown: "The Sunnah is preserved through **Hadith (حَدِيث)**, compilations of the recorded sayings, actions, and approvals of the Prophet Muhammad (peace and blessings be upon him). These narrations were meticulously verified by scholars to ensure their authenticity.")

                        ArticleParagraph(verbatim: "Major Hadith collections include:")
                        ArticleStep(verbatim: "1. Saheeh al-Bukhaari")
                        ArticleStep(verbatim: "2. Saheeh Muslim")
                        ArticleStep(verbatim: "3. Sunan Abu Daawood")
                        ArticleStep(verbatim: "4. Jaami‘ at-Tirmidhi")
                        ArticleStep(verbatim: "5. Sunan an-Nasaa’i")
                        ArticleStep(verbatim: "6. Sunan Ibn Maajah")

                        ArticleParagraph(verbatim: "These collections provide invaluable insights into the life and teachings of the Prophet (peace and blessings be upon him) and serve as a foundation for understanding and implementing the Sunnah.")
                    }

                    Section(header: ArticleHeader("EXAMPLES OF SUNNAH")) {
                        ArticleParagraph(verbatim: "Examples of Sunnah practices include:")
                        ArticleStep("1. Greeting others with **As-Salaamu Alaikum (السَّلَام عَلَيكُم)** (peace be upon you).")
                        ArticleStep("2. Saying **Bismillah (بِسم اللَّه)** (in the name of Allah) before eating (Saheeh al-Bukhaari 5376).")
                        ScriptureQuote(hadith: "bukhari:5376", cite: "Saheeh al-Bukhaari 5376, Saheeh Muslim 2022", arabic: 24...57, english: 0...53)
                        ArticleStep(verbatim: "3. Performing acts of charity, such as smiling at others, which the Prophet (peace and blessings be upon him) called charity (Jaami‘ at-Tirmidhi 1956; graded saheeh by al-Albaani).")
                        ScriptureQuote(hadith: "tirmidhi:1956", cite: "Jaami‘ at-Tirmidhi 1956; graded saheeh by al-Albaani", arabic: 38...56, english: 0...30)
                        ArticleStep(verbatim: "4. Maintaining cleanliness and grooming, such as trimming the nails, which the Prophet (peace and blessings be upon him) counted among the acts of the fitrah (Saheeh al-Bukhaari 5889).")
                        ScriptureQuote(hadith: "bukhari:5889", cite: "Saheeh al-Bukhaari 5889, Saheeh Muslim 257", arabic: 17...32, english: 0...23)
                        ArticleStep(verbatim: "5. Showing kindness and mercy to others, including animals.")
                        ArticleStep(verbatim: "6. Praying certain optional prayers.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("IMPORTANCE")) {
                        ArticleParagraph(verbatim: "The Sunnah provides practical guidance on how to live according to the Quran. It clarifies general commands in the Quran and gives specific instructions. For instance, the Quran commands Muslims to pray, and the Sunnah demonstrates how to perform the prayer.")

                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "bukhari:631", cite: "Saheeh al-Bukhaari 631", arabic: 73...76, english: 98...104)

                        ArticleParagraph(verbatim: "Obedience to the Sunnah is considered obedience to Allah. Allah says in the Quran:")
                        ScriptureQuote(quran: "4:80")
                    }
                }

                Section(header: ArticleHeader("RESOURCES")) {
                    // His daily practice, one sunnah to a page (2026-10-26): the library this
                    // article's examples come from.
                    ArticleDoorRow(door: .library(.sunnahsOfProphet))
                    Text(verbatim: "You can view Hadith collections here: https://sunnah.com/")
                        .font(.caption)
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Preserved through authentic Hadith, the Sunnah shows a Muslim how to live the Quran in daily life, and holding to it is part of obeying Allah.")
                }

                ArticleSourcesSection(article: "SunnahPillarView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "SunnahPillarView")
        .navigationTitle(AppLanguage.article("What is the Sunnah?"))
    }
}

struct HadithPillarView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: a Hadith is a recorded saying, action, or approval of Prophet Muhammad (peace and blessings be upon him). Hadiths preserve the Sunnah and clarify how to act on the Quran.")
                }

                Section(header: ArticleHeader("WATCH")) {
                    ArticleVideoLink(title: "Hadith Nabawi, Hadith Qudsi and the Quran: the difference", url: "https://www.youtube.com/watch?v=F7vfmGC-o-A")
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    ArticleParagraph(articleMarkdown: "A **Hadith (حَدِيث)**, an Arabic word meaning “speech,” “narration,” or “report,” is a recorded saying, action, or approval of Prophet Muhammad (peace and blessings be upon him). Hadiths preserve the Sunnah and are an essential source of Islamic knowledge, and scholars verified them meticulously to ensure their authenticity.")

                    ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) commands in the Quran:")
                    ScriptureQuote(quran: "59:7", words: 23...36)

                    ArticleParagraph(verbatim: "Hadiths are indispensable for understanding and implementing the Quran’s teachings, as they provide practical examples of how Prophet Muhammad (peace and blessings be upon him) lived according to Allah’s commands.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("RELATIONSHIP WITH THE QURAN")) {
                        ArticleParagraph(verbatim: "Hadiths are essential for interpreting and contextualizing the Quran. Allah says in the Quran:")
                        ScriptureQuote(quran: "16:44")

                        ArticleParagraph(articleMarkdown: "While the Quran provides general principles, the Hadith clarifies how to implement these teachings. For example, the Quran commands Muslims to pray, and the Hadith describes how the Prophet (peace and blessings be upon him) performed **Salaah (صَلَاة)**. He said:")
                        ScriptureQuote(hadith: "bukhari:631", cite: "Saheeh al-Bukhaari 631", arabic: 73...76, english: 98...104)
                    }

                    Section(header: ArticleHeader("TYPES OF HADITHS")) {
                        ArticleParagraph(verbatim: "There are two main types of Hadiths:")

                        ArticleStep("1. **Hadith Qudsi (حَدِيث قُدسِي), the Sacred Hadith:** These are sayings where the Prophet (peace and blessings be upon him) conveys meanings from Allah (Glorified and Exalted be He), but the wording is his own. Unlike the Quran, which is the exact verbatim word of Allah, Hadith Qudsi reflects divine inspiration shared through the Prophet’s speech. For example, the Prophet said:")
                        ScriptureQuote(hadith: "bukhari:7405", cite: "Saheeh al-Bukhaari 7405", arabic: 28...39, english: 4...39)
                        ArticleParagraph(verbatim: "While the Quran was revealed through the Angel Jibreel (Gabriel) and recited exactly as revealed, Hadith Qudsi might have been conveyed to the Prophet through a dream or inspiration. It holds a special status but is not part of the Quran.")

                        ArticleStep("2. **Hadith Nabawi (حَدِيث نَبَوِي), the Prophetic Hadith:** These include the Prophet’s own words, actions, and approvals, reflecting his teachings and practices. For instance, he said:")
                        ScriptureQuote(hadith: "bukhari:5027", cite: "Saheeh al-Bukhaari 5027", arabic: 36...40, english: 4...17)
                    }

                    Section(header: ArticleHeader("AUTHENTICITY AND CLASSIFICATION")) {
                        ArticleParagraph(verbatim: "Hadiths were meticulously preserved and classified by scholars based on their authenticity to ensure the teachings of Prophet Muhammad (peace and blessings be upon him) were transmitted accurately. A hadith consists of two critical components:")
                        ArticleStep("1. **Isnaad (إِسنَاد), the Chain of Transmission:** The sequence of narrators who transmitted the hadith. This ensures a direct link back to the Prophet (peace and blessings be upon him).")
                        ArticleStep("2. **Matn (مَتن), the Text:** The content of the hadith itself, which is examined for consistency with established Islamic teachings and linguistic accuracy.")

                        ArticleParagraph(verbatim: "Here is a real isnaad: the first hadith of Saheeh al-Bukhaari, “actions are by intentions,” which Imam Muslim also narrates by another road that meets al-Bukhaari’s at the same narrator:")
                        ArticleIsnadCard("Saheeh al-Bukhaari 1 and Saheeh Muslim 1907: from the Prophet ﷺ through Umar ibn al-Khattaab, Alqamah ibn Waqqaas and Muhammad ibn Ibraaheem at-Taymi to Yahya ibn Sa‘eed al-Ansaari, where the chain divides into al-Bukhaari’s road (Sufyaan ibn Uyaynah, al-Humaydi) and Muslim’s (Maalik, al-Qa‘nabi).", isnad: .bukhariFirst)

                        ArticleParagraph(verbatim: "The rigorous analysis of isnaad and matn is crucial because some individuals attempted to fabricate sayings of the Prophet (peace and blessings be upon him). To safeguard against such corruption, scholars developed a meticulous science of hadith authentication. The Prophet (peace and blessings be upon him) warned:")
                        ScriptureQuote(hadith: "bukhari:108", cite: "Saheeh al-Bukhaari 108", arabic: 27...34, english: 20...35)

                        ArticleParagraph(verbatim: "This rigorous methodology prevented the kind of corruption and fabrications found in other scriptures, such as the Bible, where authors are often anonymous, and transmission chains are unknown. In Islam, every accepted hadith is traced back to the Prophet (peace and blessings be upon him) through a chain whose narrators were individually examined; reports that fail that test are rejected.")

                        ArticleParagraph(verbatim: "Scholars classified Hadiths into categories based on their reliability and authenticity. Two questions are asked of every report: how strong is its chain, and how many carried it?")

                        // The grades as a scale rather than four bullets (Abu, 2026-09-29: "big text, fancy
                        // design showing sahih, da'if"). Its words are `HadithGrade.all`, which the corpus
                        // builder reads too.
                        HadithGradeLadder()

                        // The second question, how many carried it, as its own card (2026-11-22).
                        HadithCountLadder()

                        ArticleParagraph(articleMarkdown: "The highest rank of authentic hadith is known as **Muttafaqun Alayh (مُتَّفَق عَلَيه)**, meaning “agreed upon.” These are hadiths narrated by both Imam Bukhaari and Imam Muslim in their Saheeh collections, indicating the highest level of authenticity.")

                        ArticleParagraph(verbatim: "This detailed grading system ensures that Muslims can confidently rely on the Hadiths as a source of guidance without the risk of fabricated or unreliable narrations.")
                    }

                    Section(header: ArticleHeader("IMPORTANCE OF HADITHS")) {
                        ArticleParagraph(verbatim: "The Hadiths are indispensable for:")
                        ArticleStep("1. **Clarifying the Quran:** They explain Quranic commands, such as how to perform Salaah and fast during **Ramadan (رَمَضَان)**.")
                        ArticleStep("2. **Guiding Daily Life:** Hadiths provide moral and ethical lessons, teaching Muslims how to interact with others and live righteously.")
                        ArticleStep("3. **Strengthening Faith:** They contain spiritual guidance and wisdom that deepen a Muslim’s connection to Allah (Glorified and Exalted be He).")

                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "muslim:1218a", cite: "Saheeh Muslim 1218", arabic: 875...886, english: 1470...1490)

                        ArticleParagraph(verbatim: "And he commanded holding to his Sunnah:")
                        ScriptureQuote(hadith: "abudawud:4607", cite: "Sunan Abi Daawood 4607; graded saheeh by al-Albaani", arabic: 112...132, english: 159...192)
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("AUTHENTICITY AND CLASSIFICATION")) {
                        ArticleParagraph(verbatim: "Hadiths were meticulously preserved and classified by scholars based on their authenticity to ensure the teachings of Prophet Muhammad (peace and blessings be upon him) were transmitted accurately. A hadith consists of two critical components:")
                        ArticleStep("1. **Isnaad (إِسنَاد), the Chain of Transmission:** The sequence of narrators who transmitted the hadith. This ensures a direct link back to the Prophet (peace and blessings be upon him).")
                        ArticleStep("2. **Matn (مَتن), the Text:** The content of the hadith itself, which is examined for consistency with established Islamic teachings and linguistic accuracy.")

                        ArticleParagraph(verbatim: "The rigorous analysis of isnaad and matn is crucial because some individuals attempted to fabricate sayings of the Prophet (peace and blessings be upon him), and he warned:")
                        ScriptureQuote(hadith: "bukhari:108", cite: "Saheeh al-Bukhaari 108", arabic: 27...34, english: 20...35)

                        ArticleParagraph(verbatim: "So every accepted hadith is traced back to the Prophet (peace and blessings be upon him) through a chain whose narrators were individually examined, and reports that fail that test are rejected. By the strength of its chain, every report is graded:")

                        HadithGradeLadder()
                    }
                }

                Section(header: ArticleHeader("THE SCIENCES OF HADITH")) {
                    ArticleParagraph(verbatim: "How a narration is weighed, how the chains were kept, and how to answer those who reject the Sunnah each have a page of their own:")

                    ArticleDoorRow(door: .article("HadithSciencesView"))
                    ArticleDoorRow(door: .article("HadithPreservationView"))
                    ArticleDoorRow(door: .article("HadithRejectorsView"))
                }

                Section(header: ArticleHeader("RESOURCES")) {
                    Text(verbatim: "You can view Hadith collections here: https://sunnah.com/")
                        .font(.caption)
                }


                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Through a rigorous science of chain (Isnaad) and text (Matn), scholars carefully graded Hadiths, so Muslims can rely on authentic prophetic guidance with confidence.")
                }

                ArticleSourcesSection(article: "HadithPillarView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "HadithPillarView")
        .navigationTitle(AppLanguage.article("What are Hadiths?"))
    }
}

import SwiftUI

struct ShahadahView: View {
    @Environment(\.appearance) private var appearance

    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: the Shahaadah is the testimony that there is no god but Allah and that Muhammad is His Messenger. It is the doorway into Islam and the foundation of all faith.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("OVERVIEW")) {
                        ArticleParagraph(articleMarkdown: "The **Shahaadah (شَهَادَة)**, from the root **sh-h-d (ش ه د)** meaning “to witness” or “to testify,” is the first and most fundamental pillar of Islam. By declaring it with sincerity, a person affirms the Oneness of Allah (Glorified and Exalted be He) and accepts Muhammad (peace and blessings be upon him) as His final Prophet.")

                        ArticleParagraph(verbatim: "This simple yet profound statement encapsulates the essence of Islam: the worship of Allah alone and adherence to the teachings of His messenger. Allah (Glorified and Exalted be He) says in the Quran:")
                        ScriptureQuote(quran: "21:25")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("OVERVIEW")) {
                        ArticleParagraph(articleMarkdown: "The **Shahaadah (شَهَادَة)**, from the root **sh-h-d (ش ه د)** meaning “to witness” or “to testify,” is the first and most fundamental pillar of Islam. By declaring it with sincerity, a person affirms the Oneness of Allah (Glorified and Exalted be He) and accepts Muhammad (peace and blessings be upon him) as His final Prophet.")

                        ArticleParagraph(verbatim: "This simple yet profound statement encapsulates the essence of Islam: the worship of Allah alone and adherence to the teachings of His messenger.")
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("VERSIONS")) {
                        ArticleParagraph(verbatim: "There are two common versions of the Shahaadah, both from the Sunnah. The first is the wording of the adhan and the iqaamah (Saheeh Muslim 379; Sunan Abi Daawood 499, graded hasan saheeh by al-Albaani); the second is the wording of the tashahhud in every prayer (Saheeh al-Bukhaari 831) and of the testimony after wudu (Saheeh Muslim 234). The second names the Prophet (peace and blessings be upon him) as Allah's slave before naming him as His Messenger, so that he is never viewed as divine.")
                        ScriptureQuote(hadith: "muslim:379", cite: "Saheeh Muslim 379", arabic: 50...113, english: 0...94)
                        ScriptureQuote(hadith: "abudawud:499", cite: "Sunan Abi Daawood 499; graded hasan saheeh by al-Albaani", arabic: 145...190, english: 154...228)
                        ScriptureQuote(hadith: "muslim:402a", cite: "Saheeh Muslim 402, Saheeh al-Bukhaari 831", arabic: 94...104, english: 106...124)
                        ScriptureQuote(hadith: "muslim:234a", cite: "Saheeh Muslim 234", arabic: 111...144, english: 116...171)
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("VERSIONS")) {
                        ArticleParagraph(verbatim: "There are two common versions of the Shahaadah, both from the Sunnah: the wording of the adhan and the iqaamah, and the wording of the tashahhud in every prayer and of the testimony after wudu. The second names the Prophet (peace and blessings be upon him) as Allah's slave before naming him as His Messenger, so that he is never viewed as divine.")
                    }
                }

                Section(header: ArticleHeader("FIRST VERSION")) {
                    VStack(alignment: .leading) {
                        ArticleArabic(verbatim: "أَشهَدُ أَن لَا إِلٰهَ إِلَّا ٱللّٰهُ وَأَشهَدُ أَنَّ مُحَمَّدًا رَسُولُ ٱللّٰهِ")

                        Text(verbatim: "Ashhadu an la ilaaha illallah, wa ashhadu anna Muhammad rasool Allah.")
                            .font(.body)
                            .padding(.vertical, 2)

                        Text(verbatim: "“I bear witness that there is no deity but Allah, and I bear witness that Muhammad is the messenger of Allah.”")
                            .font(.body)
                            .padding(.vertical, 2)
                    }

                    ArticleCallout("Said aloud, the noon of “an” melts into the laam after it (idghaam): “an la ilaaha” is “allaa ilaaha”, and “illa Allah” runs together as “illallah”. Ashhadu allaa ilaaha illallah, wa ashhadu anna Muhammadan rasoolullah.", title: "How it is said", systemImage: "waveform")
                }

                Section(header: ArticleHeader("SECOND VERSION")) {
                    VStack(alignment: .leading) {
                        ArticleArabic(verbatim: "أَشهَدُ أَن لَا إِلٰهَ إِلَّا ٱللّٰهُ وَأَشهَدُ أَنَّ مُحَمَّدًا عَبدُهُ وَرَسُولُهُ")

                        Text(verbatim: "Ashhadu an la ilaaha illallah, wa ashhadu anna Muhammad abduhu wa rasooluhu.")
                            .font(.body)
                            .padding(.vertical, 2)

                        Text(verbatim: "“I bear witness that there is no deity but Allah, and I bear witness that Muhammad is His servant and messenger.”")
                            .font(.body)
                            .padding(.vertical, 2)
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("SIGNIFICANCE")) {
                        ArticleParagraph(verbatim: "Pronouncing the Shahaadah with sincere faith confirms Tawheed (absolute monotheism) and the acceptance of Muhammad (peace and blessings be upon him) as the final Prophet. Allah (Glorified and Exalted be He) says in the Quran:")
                        ScriptureQuote(quran: "47:19", words: 0...5)

                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "muslim:26a", cite: "Saheeh Muslim 26a", arabic: 43...53, english: 15...29)

                        ArticleParagraph(verbatim: "The Shahaadah is a lifelong declaration of faith and is recited during the daily prayers, serving as a constant reminder of a Muslim's commitment to Allah and His messenger.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("SIGNIFICANCE")) {
                        ArticleParagraph(verbatim: "Pronouncing the Shahaadah with sincere faith confirms Tawheed (absolute monotheism) and the acceptance of Muhammad (peace and blessings be upon him) as the final Prophet. The Prophet (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "muslim:26a", cite: "Saheeh Muslim 26a", arabic: 43...53, english: 15...29)
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Said with sincere conviction and lived by, the Shahaadah affirms pure monotheism and acceptance of the Prophet's guidance, renewed in every prayer a Muslim offers.")
                }

                ArticleSourcesSection(article: "ShahadahView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "ShahadahView")
        .navigationTitle("Shahaadah")
    }
}

struct SalahView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: Salaah is the five daily prayers: a direct connection between the servant and Allah, and the first deed a person will be asked about on the Day of Judgment.")
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    ArticleParagraph(articleMarkdown: "**Salaah (صَلَاة)**, from the root **s-l-w (ص ل و)** carrying the sense of prayer, supplication, and connection, is the second pillar of Islam. It is an act of worship that links a Muslim directly to Allah (Glorified and Exalted be He), performed five times daily at prescribed times as a constant reminder of submission and gratitude.")

                    ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:")
                    ScriptureQuote(quran: "20:14")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("TIMINGS")) {
                        ArticleParagraph(verbatim: "The five daily prayers are:")
                        ArticleStep("1. **Fajr (Dawn):** Performed before sunrise.")
                        ArticleStep("2. **Dhuhr (Noon):** Performed after the sun passes its zenith.")
                        ArticleStep("3. **Asr (Afternoon):** Performed in the late afternoon.")
                        ArticleStep("4. **Maghrib (Evening):** Performed just after sunset.")
                        ArticleStep("5. **Isha (Night):** Performed in the late evening.")

                        ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:")
                        ScriptureQuote(quran: "4:103", words: 13...19)
                    }

                    Section(header: ArticleHeader("NUMBER OF UNITS (RAK‘AH)")) {
                        ArticleParagraph(articleMarkdown: "Each prayer is made up of units called **rak‘ah (رَكعَة)**:")
                        ArticleBullet("• **Fajr**: 2 rak‘ah")
                        ArticleBullet("• **Dhuhr**: 4 rak‘ah")
                        ArticleBullet("• **Asr**: 4 rak‘ah")
                        ArticleBullet("• **Maghrib**: 3 rak‘ah")
                        ArticleBullet("• **Isha**: 4 rak‘ah")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("TIMINGS")) {
                        ArticleParagraph(articleMarkdown: "The five daily prayers, each made up of units called **rak‘ah (رَكعَة)**, are:")
                        ArticleStep("1. **Fajr (Dawn):** before sunrise, 2 rak‘ah.")
                        ArticleStep("2. **Dhuhr (Noon):** after the sun passes its zenith, 4 rak‘ah.")
                        ArticleStep("3. **Asr (Afternoon):** in the late afternoon, 4 rak‘ah.")
                        ArticleStep("4. **Maghrib (Evening):** just after sunset, 3 rak‘ah.")
                        ArticleStep("5. **Isha (Night):** in the late evening, 4 rak‘ah.")
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("HOW TO PRAY")) {
                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) instructed:")
                        ScriptureQuote(hadith: "bukhari:631", cite: "Saheeh al-Bukhaari 631", arabic: 73...76, english: 98...104)
                        ArticleParagraph(articleMarkdown: "Facing the Qiblah, with the **Niyyah (نِيَّة)**, the intention, settled in the heart, the prayer proceeds as follows (the opening takbeer with the hands raised and the opening supplication belong to the first rak‘ah only; every later rak‘ah begins from the recitation):")
                        ArticleStep("1. **Takbeer (تَكبِير)**: raise the hands and say “Allahu Akbar” (Allah is the Greatest), then place the right hand over the left upon the chest.")
                        ArticleStep("2. **Recitation**: in the first rak‘ah recite the opening supplication (Saheeh al-Bukhaari 744), then Surah **Al-Faatihah (الفَاتِحَة)**, obligatory in every rak‘ah, followed by another passage of the Quran in the first two rak‘ah.")
                        ScriptureQuote(hadith: "bukhari:744", cite: "Saheeh al-Bukhaari 744, Saheeh Muslim 598", arabic: 58...84, english: 54...133)
                        ArticleStep("3. **Ruku (رُكُوع)**: say “Allahu Akbar” and bow with a straight back, hands on the knees, saying “Subhaana Rabbi al-Azeem” (Glory to my Lord the Most Great) three times.")
                        ArticleStep("4. **Rising (I‘tidaal)**: rise saying “Sami‘a Allahu liman hamidah” (Allah hears whoever praises Him), then, standing, “Rabbana wa laka al-hamd” (Our Lord, to You is all praise).")
                        ArticleStep("5. **Sujood (سُجُود)**: say “Allahu Akbar” and prostrate on seven parts (the forehead and nose, both palms, both knees, and the toes of both feet), saying “Subhaana Rabbi al-A‘la” (Glory to my Lord the Most High) three times.")
                        ArticleStep("6. **Sitting**: say “Allahu Akbar,” sit, and say “Rabbi ighfir li” (My Lord, forgive me); then perform a second Sujood in the same way. This completes one rak‘ah.")
                        ArticleStep("7. **Tashahhud (تَشَهُّد)**: after each two rak‘ah, sit and recite the tashahhud (“At-tahiyyaatu lillah…”). In the final sitting, add the prayers upon the Prophet (peace and blessings be upon him) and supplication.")
                        ArticleStep("8. **Tasleem (تَسلِيم)**: end the prayer by turning the face to the right and then to the left, saying each time “As-salaamu alaykum wa rahmatullah” (peace and the mercy of Allah be upon you).")
                    }

                    Section(header: ArticleHeader("BENEFITS")) {
                        ArticleParagraph(verbatim: "Salaah purifies the soul, instills discipline, and strengthens a Muslim's relationship with Allah (Glorified and Exalted be He). It keeps one mindful of their Creator throughout the day, offering spiritual peace and balance.")

                        ArticleParagraph(verbatim: "Salaah also serves as a means of expiation for minor sins. The Prophet Muhammad (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "muslim:233c", cite: "Saheeh Muslim 233c", arabic: 37...50, english: 7...41)
                    }

                    Section(header: ArticleHeader("IMPORTANCE OF SALAAH")) {
                        ArticleParagraph(verbatim: "Salaah is the first deed for which a person will be held accountable on the Day of Judgment. The Prophet Muhammad (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "tirmidhi:413", cite: "Jaami‘ at-Tirmidhi 413; graded saheeh by al-Albaani", arabic: 71...117, english: 68...156)

                        ArticleParagraph(verbatim: "It is also a key to success in this life and the Hereafter. Allah (Glorified and Exalted be He) says:")
                        ScriptureQuote(quran: "23:1-2")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("HOW TO PRAY")) {
                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) instructed:")
                        ScriptureQuote(hadith: "bukhari:631", cite: "Saheeh al-Bukhaari 631", arabic: 73...76, english: 98...104)
                        ArticleParagraph(articleMarkdown: "Facing the Qiblah, with the **Niyyah (نِيَّة)**, the intention, settled in the heart, the prayer proceeds as follows (the opening takbeer belongs to the first rak‘ah only; every later rak‘ah begins from the recitation):")
                        ArticleStep("1. **Takbeer (تَكبِير)**: raise the hands and say “Allahu Akbar” (Allah is the Greatest).")
                        ArticleStep("2. **Recitation**: recite Surah **Al-Faatihah (الفَاتِحَة)**, obligatory in every rak‘ah, followed by another passage of the Quran in the first two rak‘ah.")
                        ArticleStep("3. **Ruku (رُكُوع)**: say “Allahu Akbar” and bow with a straight back, saying “Subhaana Rabbi al-Azeem” (Glory to my Lord the Most Great).")
                        ArticleStep("4. **Rising (I‘tidaal)**: rise saying “Sami‘a Allahu liman hamidah,” then “Rabbana wa laka al-hamd.”")
                        ArticleStep("5. **Sujood (سُجُود)**: prostrate on seven parts, saying “Subhaana Rabbi al-A‘la” (Glory to my Lord the Most High); sit, then prostrate a second time. This completes one rak‘ah.")
                        ArticleStep("6. **Tashahhud (تَشَهُّد)**: after each two rak‘ah, sit and recite the tashahhud; in the final sitting, add the prayers upon the Prophet (peace and blessings be upon him).")
                        ArticleStep("7. **Tasleem (تَسلِيم)**: end the prayer by turning the face to the right and then to the left, saying “As-salaamu alaykum wa rahmatullah.”")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Prayed as the Prophet prayed, Salaah purifies the soul, restrains from wrongdoing, and keeps a Muslim mindful of Allah throughout the day.")
                }

                ArticleSourcesSection(article: "SalahView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "SalahView")
        .navigationTitle("Salaah")
    }
}

struct SawmView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: Sawm is fasting from dawn to sunset, especially in Ramadan, abstaining from food, drink, and desires to draw nearer to Allah and attain God-consciousness.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("OVERVIEW")) {
                        ArticleParagraph(articleMarkdown: "**Sawm (صَوم)**, from the root **s-w-m (ص و م)** meaning “to abstain” or “to refrain,” is the fourth pillar of Islam. It is fasting: abstaining from food, drink, and marital relations from dawn (Fajr) until sunset (Maghrib) with the intention of seeking Allah’s pleasure.")

                        ArticleParagraph(verbatim: "Fasting during the sacred month of Ramadan is obligatory for all adult Muslims who are physically and mentally capable. Allah (Glorified and Exalted be He) says in the Quran:")
                        ScriptureQuote(quran: "2:185", words: 0...11)
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("OVERVIEW")) {
                        ArticleParagraph(articleMarkdown: "**Sawm (صَوم)**, from the root **s-w-m (ص و م)** meaning “to abstain” or “to refrain,” is the fourth pillar of Islam. It is fasting: abstaining from food, drink, and marital relations from dawn (Fajr) until sunset (Maghrib) with the intention of seeking Allah’s pleasure.")

                        ArticleParagraph(verbatim: "Fasting during the sacred month of Ramadan is obligatory for all adult Muslims who are physically and mentally capable.")
                    }
                }

                Section(header: ArticleHeader("PURPOSE")) {
                    ArticleParagraph(articleMarkdown: "Fasting is not merely abstaining from physical needs but also involves refraining from sinful speech, actions, and thoughts. Its purpose is to develop **Taqwa (تَقوَى)**, God-consciousness, and purify the soul.")

                    ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:")
                    ScriptureQuote(quran: "2:183")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("METHOD")) {
                        ArticleParagraph(articleMarkdown: "The fasting day begins before dawn with a recommended Sunnah meal called **Suhoor** (سُحُور) and ends at sunset with **Iftaar** (إِفطَار), traditionally breaking the fast with dates and water as Prophet Muhammad did (peace and blessings be upon him) (Sunan Abi Daawood 2356; graded hasan saheeh by al-Albaani).")
                        ScriptureQuote(hadith: "abudawud:2356", cite: "Sunan Abi Daawood 2356; graded hasan saheeh by al-Albaani", arabic: 20...45, english: 0...41)

                        ArticleParagraph(verbatim: "During the fasting hours, Muslims engage in acts of worship such as prayer, Quran recitation, and charity.")
                    }

                    Section(header: ArticleHeader("EXEMPTIONS")) {
                        ArticleParagraph(verbatim: "Fasting is mandatory for all capable Muslims, but there are exemptions for:")
                        ArticleStep(verbatim: "1. The sick.")
                        ArticleStep(verbatim: "2. Travelers.")
                        ArticleStep(verbatim: "3. Pregnant or nursing women.")
                        ArticleStep(verbatim: "4. Women during menstruation.")
                        ArticleParagraph(articleMarkdown: "Those who miss days for a passing reason make them up later; a woman in menstruation or postnatal bleeding must not fast, and makes the days up afterward. Someone who can never fast, such as the very elderly or the chronically ill with no hope of recovery, instead feeds a poor person for each day missed: the **fidya (فِديَة)**, compensation (Quran 2:184).")
                        ScriptureQuote(quran: "2:184", words: 13...18)
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("EXEMPTIONS")) {
                        ArticleParagraph(verbatim: "Fasting is mandatory for all capable Muslims, but the sick, travelers, and pregnant or nursing women are exempted, and a woman in menstruation or postnatal bleeding must not fast. Those who miss days for a passing reason make them up later; someone who can never fast, such as the very elderly or the chronically ill with no hope of recovery, instead feeds a poor person for each day missed.")
                    }
                }

                Section(header: ArticleHeader("SPIRITUAL BENEFITS")) {
                    ArticleParagraph(verbatim: "Sawm is a means of spiritual growth and self-discipline. It helps Muslims focus on worship, gratitude, and reliance on Allah (Glorified and Exalted be He). It also fosters empathy for the less fortunate and strengthens the sense of community. Prophet Muhammad (peace and blessings be upon him) said: ")

                    ScriptureQuote(hadith: "bukhari:5927", cite: "Saheeh al-Bukhaari 5927", arabic: 43...51, english: 30...48)
                }

                Section(header: ArticleHeader("REWARDS OF FASTING")) {
                    ArticleParagraph(verbatim: "The Prophet Muhammad (peace and blessings be upon him) also said:")
                    ScriptureQuote(hadith: "bukhari:38", cite: "Saheeh al-Bukhaari 38", arabic: 29...39, english: 4...29)

                    ArticleParagraph(verbatim: "Fasting is an act of worship that purifies the heart and brings immense spiritual rewards from Allah.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("SIGNIFICANCE OF RAMADAN")) {
                        ArticleParagraph(articleMarkdown: "Ramadan is not only the month of fasting but also the month in which the Quran was revealed. It is a time of intense worship and reflection, culminating in **Laylat al-Qadr (لَيلَة القَدر)**, the Night of Decree, which is better than a thousand months.")

                        ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:")
                        ScriptureQuote(quran: "97:1-3")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("More than hunger, fasting trains the soul, deepens gratitude and empathy for the poor, and earns great reward and the forgiveness of past sins.")
                }

                ArticleSourcesSection(article: "SawmView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "SawmView")
        .navigationTitle("Sawm")
    }
}

struct ZakahView: View {
    var body: some View {
        List {
            Group {
                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: Zakaah is an obligatory charity (2.5% of qualifying wealth held for a lunar year) that purifies wealth and supports those in need.")
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    ArticleParagraph(articleMarkdown: "**Zakaah (زَكَاة)**, from the root **z-k-w (ز ك و)** meaning “purification” and “growth,” is the third pillar of Islam. It is an obligatory charity that purifies wealth, acknowledges Allah’s blessings, and helps build a just and compassionate society.")

                    ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:")
                    ScriptureQuote(quran: "9:103")
                }

                Section(header: ArticleHeader("PURPOSE")) {
                    ArticleParagraph(verbatim: "The purpose of Zakaah is threefold:")
                    ArticleStep("1. **Spiritual Purification**: Cleanses the soul from greed and materialism, fostering gratitude to Allah (Glorified and Exalted be He).")
                    ArticleStep("2. **Economic Justice**: Redistributes wealth to support those in need, reducing poverty and inequality.")
                    ArticleStep("3. **Community Strengthening**: Strengthens ties within the Muslim community by helping the less fortunate.")
                }

                Section(header: ArticleHeader("OBLIGATIONS AND ELIGIBILITY")) {
                    ArticleParagraph(articleMarkdown: "Zakaah is obligatory for every Muslim who possesses wealth above the **Nisaab (نِصَاب)** (minimum threshold of wealth) for a full lunar year. The Nisaab is calculated based on the value of 85 grams of gold or 595 grams of silver.")

                    ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) specifies eight categories of Zakaah recipients in the Quran:")
                    ScriptureQuote(quran: "9:60", words: 1...16)
                }

                Section(header: ArticleHeader("CALCULATION")) {
                    ArticleParagraph(articleMarkdown: "Zakaah is calculated at a standard rate of **2.5%** of one’s total savings and assets that meet the Nisaab threshold. This includes cash, gold, silver, investments, and business assets.")
                    ArticleParagraph(verbatim: "Zakaah falls due when a full lunar year has passed on the wealth, and it must not be delayed once due. It may be paid early, and many choose to bring it forward to Ramadan for the extra reward.")
                }

                Section(header: ArticleHeader("REWARDS OF ZAKAAH")) {
                    ArticleParagraph(verbatim: "The Prophet Muhammad (peace and blessings be upon him) said:")
                    ScriptureQuote(hadith: "muslim:2588", cite: "Saheeh Muslim 2588", arabic: 32...50, english: 0...30)

                    ArticleParagraph(verbatim: "He also said:")
                    ScriptureQuote(hadith: "bukhari:1417", cite: "Saheeh al-Bukhaari 1417", arabic: 36...40, english: 0...11)

                    ArticleParagraph(verbatim: "Fulfilling the obligation of Zakaah not only earns Allah’s pleasure but also protects one’s soul and wealth from harm.")
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("By giving what is due, a Muslim cleanses wealth of greed, strengthens the community, and earns Allah's blessing and increase.")
                }

                ArticleSourcesSection(article: "ZakahView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "ZakahView")
        .navigationTitle("Zakaah")
    }
}

struct HajjView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: Hajj is the pilgrimage to the Ka‘bah in Makkah, obligatory once in a lifetime for those able: a journey of submission, forgiveness, and unity.")
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    ArticleParagraph(articleMarkdown: "**Hajj (حَجّ)**, from the root **h-j-j (ح ج ج)** meaning “to intend” or “to set out for” a great destination, is the fifth and final pillar of Islam. It is the pilgrimage to the **Ka‘bah (الكَعبَة)** in Makkah (the **Qiblah (قِبلَة)**, the direction of prayer, for Muslims worldwide), performed annually in the month of **Dhul-Hijjah (ذُو الحِجَّة)** as a profound act of worship and submission to Allah (Glorified and Exalted be He).")

                    ArticleParagraph(verbatim: "Hajj is a journey of spiritual renewal, forgiveness, and unity among Muslims, symbolizing submission to Allah and the equality of all believers.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("OBLIGATION")) {
                        ArticleParagraph(verbatim: "Hajj is mandatory for every Muslim who is physically and financially capable at least once in their lifetime. Allah (Glorified and Exalted be He) says in the Quran:")
                        ScriptureQuote(quran: "3:97", words: 9...24)

                        ArticleParagraph(verbatim: "Hajj is both a personal and communal act of worship, emphasizing the importance of fulfilling one's obligations to Allah and the global Muslim community.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("OBLIGATION")) {
                        ArticleParagraph(verbatim: "Hajj is mandatory for every Muslim who is physically and financially capable at least once in their lifetime. Allah (Glorified and Exalted be He) says in the Quran:")
                        ScriptureQuote(quran: "3:97", words: 9...24)
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("HISTORICAL ROOTS")) {
                        ArticleParagraph(verbatim: "Hajj commemorates the unwavering faith and sacrifices of Prophet Ibraaheem (Abraham, peace be upon him), his wife Haajar (may Allah be pleased with her), and their son Prophet Ismaa‘eel (Ishmael, peace be upon him).")

                        ArticleParagraph(verbatim: "Prophet Ibraaheem (peace be upon him) and Prophet Ismaa‘eel (peace be upon him) were commanded by Allah to build the Ka‘bah, the sacred House of Allah. Allah says in the Quran:")
                        ScriptureQuote(quran: "2:127")

                        ArticleParagraph(verbatim: "The rituals of Hajj also commemorate Haajar's (may Allah be pleased with her) trust in Allah as she searched for water for her infant son, Ismaa‘eel. Her desperate search between the hills of Safa and Marwah is reenacted during Hajj as the Sa‘i.")
                    }

                    Section(header: ArticleHeader("RITUALS OF HAJJ")) {
                        ArticleParagraph(verbatim: "The key rituals of Hajj include:")
                        ArticleStep("1. **Ihraam (إِحرَام)**: making the intention to enter the rites of Hajj, the sacred state in which certain things become forbidden, with men wearing two unstitched garments.")
                        ArticleStep("2. **Tawaaf (طَوَاف)**: circling the Ka‘bah seven times in reverence.")
                        ArticleStep("3. **Sa‘i (سَعي)**: walking between the hills of Safa and Marwah, commemorating Haajar’s (may Allah be pleased with her) search for water.")
                        ArticleStep("4. **Arafaat (عَرَفَات)**: standing in prayer and supplication at the Plain of Arafaat, seeking Allah’s forgiveness.")
                        ArticleStep("5. **Ramy al-Jamaraat (رَمي الجَمَرَات)**: throwing pebbles at the pillars in Mina, symbolizing rejection of the devil’s temptations.")
                        ArticleStep("6. **Hady (هَدي)**: sacrificing an animal, owed by the pilgrim performing tamattu' or qiraan (Quran 2:196), recalling Prophet Ibraaheem’s (peace be upon him) willingness to sacrifice his son for Allah’s command.")
                        ScriptureQuote(quran: "2:196", words: 33...43)
                        ArticleStep("7. **Tawaaf al-Ifaadah (طَوَاف الإِفَاضَة)**: the obligatory circumambulation of the Ka‘bah after the Day of Arafah, a pillar of Hajj. Before leaving Makkah the pilgrim also performs **Tawaaf al-Wadaa' (طَوَاف الوَدَاع)**, the farewell tawaaf.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("RITUALS OF HAJJ")) {
                        ArticleParagraph(verbatim: "The key rituals of Hajj include:")
                        ArticleStep("1. **Ihraam (إِحرَام)**: entering the sacred state of Hajj with the intention.")
                        ArticleStep("2. **Tawaaf (طَوَاف)**: circling the Ka‘bah seven times.")
                        ArticleStep("3. **Sa‘i (سَعي)**: walking between Safa and Marwah, as Haajar (may Allah be pleased with her) did in her search for water.")
                        ArticleStep("4. **Arafaat (عَرَفَات)**: standing in supplication at Arafaat.")
                        ArticleStep("5. **Ramy al-Jamaraat (رَمي الجَمَرَات)**: throwing pebbles at the pillars in Mina.")
                        ArticleStep("6. **Hady (هَدي)**: the sacrifice owed by the pilgrim performing tamattu' or qiraan, recalling Ibraaheem’s (peace be upon him) willingness to sacrifice his son.")
                        ArticleStep("7. **Tawaaf al-Ifaadah (طَوَاف الإِفَاضَة)**: the obligatory circling of the Ka‘bah after Arafah.")
                    }
                }

                Section(header: ArticleHeader("SPIRITUAL PURPOSE")) {
                    ArticleParagraph(verbatim: "Hajj represents submission to Allah and a renewal of faith. It unites Muslims from diverse backgrounds in worship, showcasing the universal brotherhood of Islam.")

                    ArticleParagraph(verbatim: "The Prophet Muhammad (peace and blessings be upon him) said:")
                    ScriptureQuote(hadith: "bukhari:1521", cite: "Saheeh al-Bukhaari 1521", arabic: 31...41, english: 4...41)
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("CONCLUSION")) {
                        ArticleParagraph(verbatim: "Hajj is a profound spiritual journey that strengthens a Muslim’s connection with Allah (Glorified and Exalted be He). By performing Hajj, Muslims fulfill one of the greatest acts of worship, seeking Allah’s mercy, forgiveness, and eternal reward.")

                        ArticleParagraph(verbatim: "Allah says in the Quran:")
                        ScriptureQuote(quran: "22:27")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Retracing the legacy of Ibraaheem and his family, Hajj gathers Muslims of every background as equals before Allah, returning the sincere pilgrim cleansed of sin.")
                }

                ArticleSourcesSection(article: "HajjView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "HajjView")
        .navigationTitle("Hajj")
    }
}

import SwiftUI

struct GodView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: the first pillar of faith is to believe in Allah alone: His Lordship, His sole right to worship, and His perfect Names and attributes.")
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    ArticleParagraph(articleMarkdown: "Belief in Allah (Glorified and Exalted be He), the One and Only God, is the core of Islamic faith, **Eemaan (إِيمَان)**. He is the Creator and Sustainer of the entire universe. He is eternal, self-sustaining, and has no equal. Allah (Glorified and Exalted be He) says in the Quran:")
                    ScriptureQuote(quran: "112:1-4")

                    ArticleParagraph(articleMarkdown: "This chapter, **Surah Al-Ikhlaas (الإِخلَاص)**, summarizes Allah’s Oneness and clarifies that He does not share His divine attributes with any of His creation. Muslims affirm that He is All-Knowing, All-Merciful, and above all limitations.")
                }

                Section(header: ArticleHeader("MEANING OF BELIEF IN ALLAH")) {
                    ArticleParagraph(articleMarkdown: "Belief in Allah, **al-Eemaan billah (الإِيمَان بِاللَّه)**, involves affirming His Oneness, **Tawheed (تَوحِيد)**, and understanding His divine attributes. It consists of three core aspects, the three pillars of tawheed. Each is set out in its own section below, and each has a page of its own under THE 3 PILLARS OF TAWHEED:")
                    ArticleStep("1. **Tawheed ar-Ruboobiyyah (تَوحِيد الرُّبُوبِيَّة)**, Oneness of Lordship: Believing that Allah alone is the Creator, Sustainer, and Manager of all that exists.")
                    ArticleStep("2. **Tawheed al-Uloohiyyah (تَوحِيد الأُلُوهِيَّة)**, Oneness of Worship: Worshiping Allah alone without associating partners with Him.")
                    ArticleStep("3. **Tawheed al-Asma wa as-Sifaat (تَوحِيد الأَسمَاء وَالصِّفَات)**, Oneness of Names and Attributes: Affirming Allah’s names and attributes as mentioned in the Quran and Sunnah, without distorting their meanings, denying them, asking how, or likening Him to His creation.")
                }

                // The three categories in full (Abu, 2026-11-24: "Three pillars of tawheed"; the index
                // had them as three lines). Tawhid: The Oneness of Allah, under Salafiyyah, carries the
                // word la ilaha illa Allah, its conditions, and shirk; this page carries the three.
                ArticleOnly(.long) {
                    Section(header: ArticleHeader("1. TAWHEED AR-RUBOOBIYYAH: HIS LORDSHIP")) {
                        ArticleParagraph(articleMarkdown: "**Tawheed ar-ruboobiyyah (تَوحِيد الرُّبُوبِيَّة)**, from **Rabb (رَبّ)**, Lord: to single Allah out in His actions. He alone **creates**, He alone **owns**, and He alone **governs** all that exists: He gives life and death, sends the rain, provides, and decrees. The scholars sum it up in those three words, creation, dominion, and command, and Allah joins them in one ayah:")
                        ScriptureQuote(quran: "7:54", words: 24...31)
                        ScriptureQuote(quran: "35:13", words: 15...27)

                        ArticleParagraph(verbatim: "Reason confirms it. A thing either made itself, came from nothing, or was made by a maker, and the Quran puts the first two to every denier:")
                        ScriptureQuote(quran: "52:35-36")
                        ArticleParagraph(verbatim: "And two lords could not share one creation without one overcoming the other, so the order of the heavens and the earth is itself a witness that there is only one:")
                        ScriptureQuote(quran: "23:91")

                        ArticleParagraph(verbatim: "This knowledge is in every soul from birth. The Prophet (peace be upon him) said:")
                        ScriptureQuote(hadith: "bukhari:1385", cite: "Saheeh al-Bukhaari 1385, Saheeh Muslim 2658", arabic: 31...49, english: 4...44)

                        ArticleParagraph(articleMarkdown: "**What breaks it**: denying the Creator altogether, or giving any share of His creating, providing, or controlling to another: believing a saint runs the affairs of the world, that the stars send the rain, or that a charm can turn the decree. Of the people who said the rain came from a star, Allah said:")
                        ScriptureQuote(hadith: "bukhari:846", cite: "Saheeh al-Bukhaari 846, Saheeh Muslim 71", arabic: 64...92, english: 49...109)

                        ArticleParagraph(articleMarkdown: "**Why it is not enough on its own**: the idolaters of Makkah affirmed all of this. Asked who owns the earth and who is Lord of the seven heavens, they answered “Allah,” and Allah still called them people who associate partners with Him:")
                        ScriptureQuote(quran: "23:84-89")
                        ScriptureQuote(quran: "12:106")
                        ArticleParagraph(verbatim: "So the first category is the foundation, and it is the argument for the second, but a person who stops at it has not yet entered Islam. Its proofs, those who denied it, and what breaks it today are on its own page:")
                        ArticleDoorRow(door: .article("RububiyyahView"))
                    }

                    Section(header: ArticleHeader("2. TAWHEED AL-ULOOHIYYAH: HIS RIGHT TO WORSHIP")) {
                        ArticleParagraph(articleMarkdown: "**Tawheed al-uloohiyyah (تَوحِيد الأُلُوهِيَّة)**, from **ilaah (إِلَٰه)**, the one who is worshipped: to single Allah out with the servants’ actions, so that every act of worship is for Him alone. It is also called **tawheed al-‘ibaadah**, the tawheed of worship. This is the category the messengers were sent for, the meaning of la ilaaha illallah, and the one the nations rejected.")

                        ArticleParagraph(verbatim: "Allah argues from the first category to this one. The One who created you and sends down your provision is the only One who deserves to be worshipped:")
                        ScriptureQuote(quran: "2:21-22")
                        ScriptureQuote(quran: "6:102")

                        ArticleParagraph(verbatim: "Worship is wider than the prayer. Ibn Taymiyyah (may Allah have mercy on him) defined it:")
                        ScriptureQuote(text: "“Worship is a comprehensive term for everything Allah loves and is pleased with, of words and deeds, inward and outward” (Ibn Taymiyyah, al-Uboodiyyah).", arabic: "العِبَادَةُ هِيَ اسمٌ جَامِعٌ لِكُلِّ مَا يُحِبُّهُ اللَّهُ وَيَرضَاهُ مِنَ الأَقوَالِ وَالأَعمَالِ البَاطِنَةِ وَالظَّاهِرَةِ", dimmed: true)
                        ArticleParagraph(verbatim: "So prayer, fasting, and pilgrimage are worship, and so are supplication, sacrifice, vows, seeking refuge, reliance, fear, hope, and love. Supplication above all:")
                        ScriptureQuote(hadith: "abudawud:1479", cite: "Sunan Abi Daawood 1479; graded saheeh by al-Albaani", arabic: 25...33, english: 4...23)
                        ScriptureQuote(quran: "6:162-163")
                        ScriptureQuote(quran: "108:2")

                        ArticleParagraph(articleMarkdown: "Worship rests on **love, fear, and hope** together, and Allah praises those who call on Him with all three: those whom others invoke are themselves seeking a way to their Lord, “and they hope for His mercy and fear His punishment.” Love alone, without fear, leads to carelessness; fear alone leads to despair; and the believer joins them:")
                        ScriptureQuote(quran: "17:57", words: 0...12)
                        ScriptureQuote(quran: "2:165", words: 0...15)

                        ArticleParagraph(articleMarkdown: "**What breaks it**: directing any act of worship to other than Allah: calling on the dead or the absent for what only Allah can give, sacrificing or making vows to a saint or a jinn, or loving another as one should love Allah. The Prophet (peace be upon him) said:")
                        ScriptureQuote(hadith: "muslim:1978a", cite: "Saheeh Muslim 1978", arabic: 84...89, english: 77...85)
                        ArticleParagraph(verbatim: "Showing off in worship is the lesser form of the same fault, which the Prophet feared for his Companions. Both are set out on the page on shirk.")
                        ArticleDoorRow(door: .article("ShirkView"))
                        ArticleParagraph(verbatim: "The kinds of worship, the two conditions of every deed, and how the Sunnah guards this pillar are on its own page:")
                        ArticleDoorRow(door: .article("UluhiyyahView"))
                    }

                    Section(header: ArticleHeader("3. TAWHEED AL-ASMA WAS-SIFAAT: HIS NAMES AND ATTRIBUTES")) {
                        ArticleParagraph(articleMarkdown: "**Tawheed al-asmaa’ was-sifaat (تَوحِيد الأَسمَاء وَالصِّفَات)**: to single Allah out in His names and attributes, by affirming every name and attribute He affirmed for Himself in His Book or His Messenger affirmed for Him, and denying what they denied of Him, with no likeness to His creation. Ibn Taymiyyah (may Allah have mercy on him) put the creed of Ahl as-Sunnah in one sentence:")
                        ScriptureQuote(text: "“Part of faith in Allah is faith in what He has described Himself with in His Book and in what His Messenger Muhammad (peace be upon him) has described Him with, without distortion (tahreef) or denial (ta‘teel), and without asking how (takyeef) or likening (tamtheel)” (Ibn Taymiyyah, al-Aqeedah al-Waasitiyyah).", arabic: "وَمِنَ الإِيمَانِ بِاللَّهِ: الإِيمَانُ بِمَا وَصَفَ بِهِ نَفسَهُ فِي كِتَابِهِ، وَبِمَا وَصَفَهُ بِهِ رَسُولُهُ مُحَمَّدٌ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ، مِن غَيرِ تَحرِيفٍ وَلَا تَعطِيلٍ، وَمِن غَيرِ تَكيِيفٍ وَلَا تَمثِيلٍ", dimmed: true)

                        ArticleParagraph(verbatim: "One ayah holds the whole rule. Its first half denies any likeness, and its second affirms real attributes:")
                        ScriptureQuote(quran: "42:11", words: 13...18)
                        ArticleParagraph(verbatim: "Allah hears and sees in truth, and His hearing and seeing are not like ours. And no one can picture how He is, because no one encompasses Him in knowledge:")
                        ScriptureQuote(quran: "20:110", words: 6...9)
                        ScriptureQuote(quran: "7:180", words: 0...4)

                        ArticleParagraph(verbatim: "So Ahl as-Sunnah affirm what the texts say, as they say it: that Allah rose over His Throne (Quran 20:5), that He has two Hands with which He created Aadam (Quran 38:75), that He has a Face that remains (Quran 55:27), that He descends to the lowest heaven in the last third of every night, and that the believers will see Him:")
                        ScriptureQuote(quran: "20:5")
                        ScriptureQuote(quran: "38:75", words: 6...8)
                        ScriptureQuote(quran: "55:27")
                        ScriptureQuote(hadith: "bukhari:1145", cite: "Saheeh al-Bukhaari 1145, Saheeh Muslim 758", arabic: 35...60, english: 5...68)
                        ScriptureQuote(hadith: "bukhari:554", cite: "Saheeh al-Bukhaari 554, Saheeh Muslim 633", arabic: 32...42, english: 15...34)

                        ArticleParagraph(verbatim: "When a man asked Imam Maalik (may Allah have mercy on him) how Allah rose over the Throne, he gave the answer that has stood ever since as the rule for every attribute:")
                        ScriptureQuote(text: "“The rising is not unknown, the ‘how’ is not comprehensible, believing in it is obligatory, and asking about it is an innovation” (al-Bayhaqi, al-Asmaa’ was-Sifaat 867; al-Laalakaa’i 664).", arabic: "الِاستِوَاءُ غَيرُ مَجهُولٍ، وَالكَيفُ غَيرُ مَعقُولٍ، وَالإِيمَانُ بِهِ وَاجِبٌ، وَالسُّؤَالُ عَنهُ بِدعَةٌ", dimmed: true)
                        ArticleParagraph(articleMarkdown: "Each clause answers an error. **“Not unknown”**: the meaning is known Arabic, rising over, so it is not emptied of meaning. **“The how is not comprehensible”**: its manner is beyond us, so it is not pictured. **“Believing in it is obligatory”**: because Allah said it of Himself. **“Asking about it is an innovation”**: because the Companions, who knew the religion best, never asked how, and the one who asks it seeks what Allah did not give.")

                        ArticleParagraph(articleMarkdown: "**What breaks it** is the four errors that the sentence of al-Waasitiyyah names: **tahreef**, twisting the meaning (reading “rose over” as “conquered”); **ta‘teel**, denying the attribute; **takyeef**, describing how it is; and **tamtheel**, likening it to creation. The schools that fell into them, and the Salaf’s answer to each, have their own page:")
                        ArticleDoorRow(door: .article("AqeedahMadhabView"))
                        ArticleParagraph(verbatim: "The rules the Salaf walked by, Allah’s being above His creation, and the seeing of Allah in the Hereafter are on this pillar’s own page:")
                        ArticleDoorRow(door: .article("AsmaSifatView"))
                    }

                    Section(header: ArticleHeader("HOW THE THREE FIT TOGETHER")) {
                        ArticleParagraph(verbatim: "The three are not three gods or three beliefs; they are three sides of knowing one Lord. The first is the proof of the second: He alone creates and provides, so He alone is worshipped. The third is the light of both: the more a servant knows of Allah’s names, the Merciful, the Forgiving, the All-Hearing, the All-Knowing, the more he loves, fears, and hopes in Him alone. Ibraaheem (peace be upon him) argued from the attributes against his father’s idols:")
                        ScriptureQuote(quran: "19:42")
                        ArticleParagraph(verbatim: "And one ayah carries all three at once:")
                        ScriptureQuote(quran: "19:65")
                        ArticleParagraph(verbatim: "“Lord of the heavens and the earth” is His lordship, “so worship Him” is His right to worship, and “Do you know of any similarity to Him?” is His names and attributes. The headings are a description of what the Quran contains, gathered by the scholars from its aayaat, as “the five pillars” describes a hadith. Tawheed as the message of every messenger, the meaning of la ilaaha illallah, and its conditions have their own page:")
                        ArticleDoorRow(door: .article("TawhidView"))
                    }

                    Section(header: ArticleHeader("QURANIC EVIDENCE")) {
                        ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) repeatedly emphasizes His Oneness and supremacy in the Quran. He says:")
                        ScriptureQuote(quran: "2:255", words: 0...18)

                        ScriptureQuote(quran: "2:163")
                    }

                    Section(header: ArticleHeader("HADITH ON BELIEF IN ALLAH")) {
                        ArticleParagraph(verbatim: "The Prophet Muhammad (peace and blessings be upon him) explained the essence of belief in Allah. He said:")
                        ScriptureQuote(hadith: "muslim:8a", cite: "Saheeh Muslim 8a", arabic: 273...284, english: 399...442)
                    }

                    Section(header: ArticleHeader("IMPORTANCE OF BELIEF IN ALLAH")) {
                        ArticleParagraph(verbatim: "Belief in Allah is the foundation of a Muslim’s faith and actions. It shapes a person’s worldview, guiding them to trust Allah, obey His commands, and rely on His mercy and justice.")

                        ArticleParagraph(articleMarkdown: "This belief inspires **Taqwa (تَقوَى)**, God-consciousness, motivating Muslims to live righteously and strive for Allah’s pleasure in every aspect of their lives.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("1. TAWHEED AR-RUBOOBIYYAH: HIS LORDSHIP")) {
                        ArticleParagraph(articleMarkdown: "**Tawheed ar-ruboobiyyah (تَوحِيد الرُّبُوبِيَّة)**, from **Rabb (رَبّ)**, Lord: to single Allah out in His actions. He alone **creates**, He alone **owns**, and He alone **governs** all that exists: He gives life and death, sends the rain, provides, and decrees. The scholars sum it up in those three words, creation, dominion, and command, and Allah joins them in one ayah:")
                        ScriptureQuote(quran: "7:54", words: 24...31)

                        ArticleParagraph(verbatim: "Yet the idolaters of Makkah affirmed all of this, and Allah still called them people who associate partners with Him:")
                        ScriptureQuote(quran: "12:106")
                        ArticleParagraph(verbatim: "So the first category is the foundation, and it is the argument for the second, but a person who stops at it has not yet entered Islam. Its proofs, those who denied it, and what breaks it today are on its own page:")
                        ArticleDoorRow(door: .article("RububiyyahView"))
                    }

                    Section(header: ArticleHeader("2. TAWHEED AL-ULOOHIYYAH: HIS RIGHT TO WORSHIP")) {
                        ArticleParagraph(articleMarkdown: "**Tawheed al-uloohiyyah (تَوحِيد الأُلُوهِيَّة)**, from **ilaah (إِلَٰه)**, the one who is worshipped: to single Allah out with the servants’ actions, so that every act of worship is for Him alone. It is also called **tawheed al-‘ibaadah**, the tawheed of worship. This is the category the messengers were sent for, the meaning of la ilaaha illallah, and the one the nations rejected.")

                        ArticleParagraph(verbatim: "Allah argues from the first category to this one. The One who created you and sends down your provision is the only One who deserves to be worshipped:")
                        ScriptureQuote(quran: "6:102")

                        ArticleParagraph(verbatim: "Worship is wider than the prayer: supplication, sacrifice, vows, seeking refuge, reliance, fear, hope, and love are all worship. Directing any of it to other than Allah, such as calling on the dead or the absent for what only Allah can give, breaks this pillar. The kinds of worship, the two conditions of every deed, and how the Sunnah guards this pillar are on its own page:")
                        ArticleDoorRow(door: .article("UluhiyyahView"))
                    }

                    Section(header: ArticleHeader("3. TAWHEED AL-ASMA WAS-SIFAAT: HIS NAMES AND ATTRIBUTES")) {
                        ArticleParagraph(articleMarkdown: "**Tawheed al-asmaa’ was-sifaat (تَوحِيد الأَسمَاء وَالصِّفَات)**: to single Allah out in His names and attributes, by affirming every name and attribute He affirmed for Himself in His Book or His Messenger affirmed for Him, and denying what they denied of Him, with no likeness to His creation. One ayah holds the whole rule. Its first half denies any likeness, and its second affirms real attributes:")
                        ScriptureQuote(quran: "42:11", words: 13...18)

                        ArticleParagraph(verbatim: "When a man asked Imam Maalik (may Allah have mercy on him) how Allah rose over the Throne, he gave the answer that has stood ever since as the rule for every attribute:")
                        ScriptureQuote(text: "“The rising is not unknown, the ‘how’ is not comprehensible, believing in it is obligatory, and asking about it is an innovation” (al-Bayhaqi, al-Asmaa’ was-Sifaat 867; al-Laalakaa’i 664).", arabic: "الِاستِوَاءُ غَيرُ مَجهُولٍ، وَالكَيفُ غَيرُ مَعقُولٍ، وَالإِيمَانُ بِهِ وَاجِبٌ، وَالسُّؤَالُ عَنهُ بِدعَةٌ", dimmed: true)
                        ArticleParagraph(verbatim: "The rules the Salaf walked by, Allah’s being above His creation, and the seeing of Allah in the Hereafter are on this pillar’s own page:")
                        ArticleDoorRow(door: .article("AsmaSifatView"))
                    }

                    Section(header: ArticleHeader("HOW THE THREE FIT TOGETHER")) {
                        ArticleParagraph(verbatim: "The three are not three gods or three beliefs; they are three sides of knowing one Lord. The first is the proof of the second: He alone creates and provides, so He alone is worshipped. The third is the light of both: the more a servant knows of Allah’s names, the more he loves, fears, and hopes in Him alone. One ayah carries all three at once:")
                        ScriptureQuote(quran: "19:65")
                        ArticleParagraph(verbatim: "“Lord of the heavens and the earth” is His lordship, “so worship Him” is His right to worship, and “Do you know of any similarity to Him?” is His names and attributes. Tawheed as the message of every messenger, the meaning of la ilaaha illallah, and its conditions have their own page:")
                        ArticleDoorRow(door: .article("TawhidView"))
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Belief in Allah anchors a Muslim's whole life: to trust Him, obey Him, and worship Him alone without any partner.")
                }

                ArticleSourcesSection(article: "GodView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "GodView")
        .navigationTitle("Belief in Allah")
    }
}

struct AngelsView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: the angels are unseen beings created from light who never disobey Allah and carry out His commands throughout creation.")
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    ArticleParagraph(articleMarkdown: "Belief in the angels, **Malaaikah (مَلَائِكَة)**, is a fundamental pillar of Islamic faith, **Eemaan (إِيمَان)**. Angels are unseen beings created by Allah (Glorified and Exalted be He) from light. They are sinless, do not have free will, and continuously obey Allah’s commands. Their roles include delivering revelations, recording deeds, and carrying out Allah’s orders in the universe. Allah, however, does not need angels or anything else, as He is completely self-sufficient, **Al-Ghaniyy (الغَنِيّ)**, and sustains all existence, **Al-Qayyoom (القَيُّوم)**. The creation of angels reflects Allah’s wisdom and His divine plan.")

                    ArticleParagraph(verbatim: "The Prophet Muhammad (peace and blessings be upon him) said:")
                    ScriptureQuote(hadith: "muslim:2996", cite: "Saheeh Muslim 2996; English from Riyaad as-Saaliheen 1846", arabic: 34...48, text: "“Angels were created from light, jinns were created from a smokeless flame of fire, and Aadam was created from that which you have been told.”")
                }

                Section(header: ArticleHeader("CHARACTERISTICS OF ANGELS")) {
                    ArticleParagraph(verbatim: "Angels possess unique attributes that set them apart from other creations:")

                    ArticleStep("1. **Created from Light**: Unlike humans and jinn, angels are made of light.")
                    ArticleStep("2. **Infallible Obedience**: They never disobey Allah and do exactly as commanded. Allah says in the Quran:")
                    ScriptureQuote(quran: "66:6", words: 14...21)
                    ArticleStep("3. **Invisible to Humans**: Although normally unseen, they can appear in human form, as Angel Jibreel (Gabriel) did when he visited the Prophet Muhammad (peace and blessings be upon him).")
                    ArticleStep("4. **Lack of Free Will**: Angels exist solely to serve Allah and cannot deviate from their roles.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("ROLES AND RESPONSIBILITIES")) {
                        ArticleParagraph(verbatim: "Angels have distinct duties, demonstrating Allah’s meticulous organization of creation:")

                        ArticleStep("1. **Jibreel (Gabriel)**: The angel of revelation who conveyed Allah’s messages to the prophets, including the Quran to Prophet Muhammad (peace and blessings be upon him). Allah says:")
                        ScriptureQuote(quran: "2:97", words: 0...10)

                        ArticleStep("2. **Meekaaeel (مِيكَائِيل)**, Michael: Responsible for provisions, including rain and sustenance.")

                        ArticleStep("3. **The Bearer of the Horn (صَاحِب الصُّور)**: the angel entrusted with the Trumpet, who will blow it to end the world and again for the resurrection (Jaami‘ at-Tirmidhi 2431; graded saheeh by al-Albaani). That he is Israafeel is the well-known position, on which al-Haleemi reported agreement (Ibn Hajar, Fath al-Baari, Book of ar-Riqaaq), though the reports that name Israafeel as the one who blows are not sound. Israafeel himself is named in the night-prayer supplication of the Prophet (peace and blessings be upon him): “O Allah, Lord of Gabriel, and Michael, and Israafeel” (Saheeh Muslim 770).")
                        ScriptureQuote(hadith: "tirmidhi:2431", cite: "Jaami‘ at-Tirmidhi 2431; graded saheeh by al-Albaani", arabic: 23...35, english: 0...37)
                        ScriptureQuote(hadith: "muslim:770", cite: "Saheeh Muslim 770", arabic: 65...83, english: 45...76)

                        ArticleStep("4. **Maalik (مَالِك)**: The guardian of Hellfire. Allah says:")
                        ScriptureQuote(quran: "43:77")

                        ArticleStep("5. **Kiraaman Kaatibeen (كِرَامًا كَاتِبِين)**: Angels who record every deed:")
                        ScriptureQuote(quran: "50:18")

                        ArticleStep("6. **Munkar and Nakeer (مُنكَر وَنَكِير)**: Angels who question the deceased in their graves about their faith. The Prophet (peace and blessings be upon him) named them in the hadith of the questioning in the grave (Jaami‘ at-Tirmidhi 1071; graded hasan by al-Albaani).")
                        ScriptureQuote(hadith: "tirmidhi:1071", cite: "Jaami‘ at-Tirmidhi 1071; graded hasan by al-Albaani", arabic: 34...56, english: 0...48)

                        ArticleStep("7. **The Keeper of Paradise (خَازِن الجَنَّة)**: an angel appointed over its gates. The authentic hadith calls him only “the keeper”; the name “Ridwaan” is widely known among later scholars but is not established in the Quran or the authentic Sunnah. The Prophet (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "muslim:197", cite: "Saheeh Muslim 197", arabic: 31...50, english: 6...57)
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("ROLES AND RESPONSIBILITIES")) {
                        ArticleParagraph(verbatim: "Angels have distinct duties, demonstrating Allah’s meticulous organization of creation:")
                        ArticleStep("1. **Jibreel (Gabriel)**: The angel of revelation who conveyed Allah’s messages to the prophets, including the Quran to Prophet Muhammad (peace and blessings be upon him).")
                        ArticleStep("2. **Meekaaeel (مِيكَائِيل)**, Michael: Responsible for provisions, including rain and sustenance.")
                        ArticleStep("3. **The Bearer of the Horn (صَاحِب الصُّور)**: the angel entrusted with the Trumpet, who will blow it to end the world and again for the resurrection. That he is Israafeel is the well-known position.")
                        ArticleStep("4. **Maalik (مَالِك)**: The guardian of Hellfire.")
                        ArticleStep("5. **Kiraaman Kaatibeen (كِرَامًا كَاتِبِين)**: Angels who record every deed:")
                        ScriptureQuote(quran: "50:18")
                        ArticleStep("6. **Munkar and Nakeer (مُنكَر وَنَكِير)**: Angels who question the deceased in their graves about their faith.")
                        ArticleStep("7. **The Keeper of Paradise (خَازِن الجَنَّة)**: an angel appointed over its gates.")
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("IMPORTANCE OF BELIEF IN ANGELS")) {
                        ArticleParagraph(verbatim: "Belief in angels is the second pillar of Eemaan and is crucial for a complete understanding of Islam. It has profound implications for a Muslim’s faith:")

                        ArticleStep("1. **Strengthens Taqwa**: Awareness of recording angels motivates Muslims to be mindful of their actions.")
                        ArticleStep("2. **Demonstrates Allah’s Sovereignty**: Angels fulfill Allah’s commands, showcasing His power and control over creation.")
                        ArticleStep("3. **Connection to Revelation**: Through Angel Jibreel, Allah’s guidance was conveyed to humanity.")
                    }

                    Section(header: ArticleHeader("HADITH ON ANGELS")) {
                        ArticleParagraph(verbatim: "The Prophet Muhammad (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "bukhari:7485", cite: "Saheeh al-Bukhaari 7485", arabic: 39...75, english: 4...69)
                    }

                    Section(header: ArticleHeader("CONCLUSION")) {
                        ArticleParagraph(verbatim: "Angels are integral to the Islamic understanding of the unseen world. Their obedience, dedication, and specific roles serve as a reminder of Allah’s omnipotence and meticulous care in organizing creation. Belief in angels strengthens a Muslim’s faith, instilling awe of Allah and the awareness that He sees every deed and His angels record it.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Belief in the angels deepens awe of Allah's dominion and the awareness that our words and deeds are seen and recorded.")
                }

                ArticleSourcesSection(article: "AngelsView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "AngelsView")
        .navigationTitle("Belief in the Angels")
    }
}

struct BooksView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: Allah revealed scriptures to His prophets (including the Torah, Psalms, and Gospel), culminating in the Quran, the final and preserved revelation.")
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) revealed divine scriptures to various prophets. These scriptures were sent to guide humanity to righteousness and worship of Allah alone. They include the Scrolls of Ibraaheem (Abraham, peace be upon him), the Torah given to Moosa (Moses, peace be upon him), the Psalms given to Daawood (David, peace be upon him), the Gospel given to Eesa (Jesus, peace be upon him), and the Quran given to Muhammad (peace and blessings be upon him).")

                    ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:")
                    ScriptureQuote(quran: "5:44", words: 0...5)

                    ArticleParagraph(verbatim: "Each scripture served as a guide for its respective nation and time, culminating in the Quran, which is the final and universal revelation.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("THE QURAN")) {
                        ArticleParagraph(articleMarkdown: "The **Quran (القُرآن)**, meaning “the Recitation,” is the final and complete revelation from Allah, sent to all of humanity through the Prophet Muhammad (peace and blessings be upon him). It is preserved word for word, as Allah has promised:")
                        ScriptureQuote(quran: "15:9")

                        ArticleParagraph(verbatim: "The Quran confirms and corrects previous scriptures while providing comprehensive guidance for all aspects of life. It remains unchanged since its revelation and is recited, memorized, and revered by Muslims worldwide.")
                    }

                    Section(header: ArticleHeader("PREVIOUS SCRIPTURES")) {
                        ArticleStep("1. **Tawraah (التَّورَاة)**, the Torah: Revealed to Moosa (Moses, peace be upon him), it contained laws and guidance for the Children of Israel. Over time, the original text was altered, and its authenticity was compromised.")

                        ArticleStep("2. **Zaboor (الزَّبُور)**, the Psalms: Revealed to Daawood (David, peace be upon him), it was a collection of hymns and praises dedicated to Allah.")

                        ArticleStep("3. **Injeel (الإِنجِيل)**, the Gospel: Revealed to Eesa (Jesus, peace be upon him), it confirmed the Torah and brought new guidance. However, the original Gospel has been lost, and what exists today are interpretations and altered accounts.")

                        ArticleStep("4. **Suhuf (صُحُف)**, the Scrolls: Revealed to Ibraaheem (Abraham, peace be upon him) and Moosa (Moses, peace be upon him), these contained foundational teachings and guidance. They are mentioned in the Quran but no longer exist.")

                        ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) says:")
                        ScriptureQuote(quran: "87:18-19")
                    }

                    Section(header: ArticleHeader("IMPORTANCE OF BELIEVING IN THE BOOKS")) {
                        ArticleParagraph(verbatim: "Belief in Allah’s books is a fundamental pillar of Eemaan (faith). The Prophet Muhammad (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "muslim:8a", cite: "Saheeh Muslim 8a", arabic: 273...284, english: 399...442)

                        ArticleParagraph(articleMarkdown: "Each scripture taught monotheism, **Tawheed (تَوحِيد)**, and righteousness, serving as a guide for the people of its time. The Quran, as the final revelation, is universal and timeless, applicable to all of humanity until the Day of Judgment.")
                    }
                }

                Section(header: ArticleHeader("DIFFERENCES BETWEEN SCRIPTURES")) {
                    ArticleStep("1. **Preservation:** Unlike earlier scriptures, which were altered or lost, the Quran has been perfectly preserved as promised by Allah.")

                    ArticleStep("2. **Universality:** Previous scriptures were meant for specific nations and times, while the Quran is for all of humanity and all time.")

                    ArticleStep("3. **Completeness:** The Quran encompasses all necessary guidance, confirming and completing previous revelations.")
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Earlier scriptures guided their nations but were altered or lost; the Quran alone remains perfectly preserved as Allah's guidance for all time.")
                }

                ArticleSourcesSection(article: "BooksView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "BooksView")
        .navigationTitle("Belief in the Books")
    }
}

struct ProphetsView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: Allah sent prophets to call people to worship Him alone, from Aadam to the final Messenger, Muhammad.")
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    ArticleParagraph(verbatim: "Allah sent prophets to every nation, and a Muslim believes in every one of them. Prophets were chosen by Allah to guide their communities to monotheism and righteous living. The Quran mentions 25 prophets by name.")

                    ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:")
                    ScriptureQuote(quran: "6:84-85")

                    ArticleParagraph(verbatim: "Each prophet conveyed Allah’s guidance and served as role models for their people. While all prophets were sent to specific nations and times, Prophet Muhammad was sent as the final messenger for all of humanity. Allah (Glorified and Exalted be He) says in the Quran:")
                    ScriptureQuote(quran: "33:40", words: 0...11)
                }

                Section(header: ArticleHeader("THE 25 PROPHETS NAMED IN THE QURAN")) {
                    NavigationLink(destination: LazyDestination { ProphetAdamView() }) {
                        ProphetLinkRow(name: "Aadam", arabic: "آدَم", sentTo: "The first man, and the first prophet")
                    }
                    NavigationLink(destination: LazyDestination { ProphetIdrisView() }) {
                        ProphetLinkRow(name: "Idrees", arabic: "إِدرِيس", sentTo: "Raised by Allah to a high station")
                    }
                    NavigationLink(destination: LazyDestination { ProphetNuhView() }) {
                        ProphetLinkRow(name: "Nooh", arabic: "نُوح", sentTo: "Sent to his people for 950 years")
                    }
                    NavigationLink(destination: LazyDestination { ProphetHudView() }) {
                        ProphetLinkRow(name: "Hood", arabic: "هُود", sentTo: "Sent to ‘Ad, of the sand dunes")
                    }
                    NavigationLink(destination: LazyDestination { ProphetSalihView() }) {
                        ProphetLinkRow(name: "Saalih", arabic: "صَالِح", sentTo: "Sent to Thamood, of al-Hijr")
                    }
                    NavigationLink(destination: LazyDestination { ProphetIbrahimView() }) {
                        ProphetLinkRow(name: "Ibraaheem", arabic: "إِبرَاهِيم", sentTo: "The friend of Allah, father of the prophets")
                    }
                    NavigationLink(destination: LazyDestination { ProphetLutView() }) {
                        ProphetLinkRow(name: "Loot", arabic: "لُوط", sentTo: "Sent to the cities of the plain")
                    }
                    NavigationLink(destination: LazyDestination { ProphetIsmailView() }) {
                        ProphetLinkRow(name: "Ismaa‘eel", arabic: "إِسمَاعِيل", sentTo: "True to his promise; built the Ka‘bah")
                    }
                    NavigationLink(destination: LazyDestination { ProphetIshaqView() }) {
                        ProphetLinkRow(name: "Ishaaq", arabic: "إِسحَاق", sentTo: "The glad tidings given to Ibraaheem")
                    }
                    NavigationLink(destination: LazyDestination { ProphetYaqubView() }) {
                        ProphetLinkRow(name: "Ya‘qoob", arabic: "يَعقُوب", sentTo: "Israa’eel, father of the twelve tribes")
                    }
                    NavigationLink(destination: LazyDestination { ProphetYusufView() }) {
                        ProphetLinkRow(name: "Yoosuf", arabic: "يُوسُف", sentTo: "The best of stories, told in full")
                    }
                    NavigationLink(destination: LazyDestination { ProphetAyyubView() }) {
                        ProphetLinkRow(name: "Ayyoob", arabic: "أَيُّوب", sentTo: "An excellent servant, patient in loss")
                    }
                    NavigationLink(destination: LazyDestination { ProphetShuaybView() }) {
                        ProphetLinkRow(name: "Shu‘ayb", arabic: "شُعَيب", sentTo: "Sent to Madyan, on honest trade")
                    }
                    NavigationLink(destination: LazyDestination { ProphetMusaView() }) {
                        ProphetLinkRow(name: "Moosa", arabic: "مُوسَى", sentTo: "Spoken to by Allah; given the Torah")
                    }
                    NavigationLink(destination: LazyDestination { ProphetHarunView() }) {
                        ProphetLinkRow(name: "Haaroon", arabic: "هَارُون", sentTo: "Given to Moosa as an answered prayer")
                    }
                    NavigationLink(destination: LazyDestination { ProphetDhulKiflView() }) {
                        ProphetLinkRow(name: "Dhul-Kifl", arabic: "ذُو الكِفل", sentTo: "Named among the patient and excellent")
                    }
                    NavigationLink(destination: LazyDestination { ProphetDawudView() }) {
                        ProphetLinkRow(name: "Daawood", arabic: "دَاوُود", sentTo: "Prophet and king; given the Zaboor")
                    }
                    NavigationLink(destination: LazyDestination { ProphetSulaymanView() }) {
                        ProphetLinkRow(name: "Sulaymaan", arabic: "سُلَيمَان", sentTo: "Given a kingdom like no one after him")
                    }
                    NavigationLink(destination: LazyDestination { ProphetIlyasView() }) {
                        ProphetLinkRow(name: "Ilyaas", arabic: "إِليَاس", sentTo: "Sent to a people who worshipped Ba‘l")
                    }
                    NavigationLink(destination: LazyDestination { ProphetAlyasaView() }) {
                        ProphetLinkRow(name: "Alyasa", arabic: "اليَسَع", sentTo: "Chosen by Allah above the worlds")
                    }
                    NavigationLink(destination: LazyDestination { ProphetYunusView() }) {
                        ProphetLinkRow(name: "Yoonus", arabic: "يُونُس", sentTo: "Dhun-Noon, of the whale")
                    }
                    NavigationLink(destination: LazyDestination { ProphetZakariyaView() }) {
                        ProphetLinkRow(name: "Zakariya", arabic: "زَكَرِيَّا", sentTo: "Answered in old age with Yahya")
                    }
                    NavigationLink(destination: LazyDestination { ProphetYahyaView() }) {
                        ProphetLinkRow(name: "Yahya", arabic: "يَحيَى", sentTo: "Given wisdom while still a child")
                    }
                    NavigationLink(destination: LazyDestination { ProphetIsaView() }) {
                        ProphetLinkRow(name: "Eesa", arabic: "عِيسَى", sentTo: "Son of Maryam; given the Injeel")
                    }
                    NavigationLink(destination: LazyDestination { ProphetMuhammadView() }) {
                        ProphetLinkRow(name: "Muhammad", arabic: "مُحَمَّد", sentTo: "The seal of the prophets ﷺ")
                    }
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("PROPHETS AND MESSENGERS")) {
                        ArticleParagraph(articleMarkdown: "There is a distinction between a prophet, **Nabi (نَبِيّ)**, and a messenger, **Rasool (رَسُول)**:")

                        ArticleStep("1. **Prophet, Nabi (نَبِيّ):** From the root **n-b-a (ن ب أ)**, to bring news. A prophet receives revelation from Allah. One common explanation is that he upholds and reinforces the law of a previous messenger; the scholars differ on the exact distinction between the two terms.")
                        ArticleParagraph(verbatim: "Every messenger is also a prophet, but not every prophet is a messenger. The Quran uses both titles for some, calling Haaroon (هَارُون), Aaron, a messenger alongside Moosa (مُوسَى), Moses (Quran 20:47), while the prophets sent to Bani Israa’eel after Moosa judged by the Torah already revealed.")
                        ScriptureQuote(quran: "20:47", words: 2...4)

                        ArticleStep("2. **Messenger, Rasool (رَسُول):** From the root **r-s-l (ر س ل)**, to send. A messenger is sent with a message to a people, often with a new scripture or divine law.")
                        ArticleParagraph(verbatim: "Example: Muhammad (مُحَمَّد) was a messenger who brought the Quran, the final revelation.")

                        ArticleParagraph(verbatim: "Every messenger is a prophet, but not every prophet is a messenger. Belief in them is not selective: to reject one prophet is to reject them all, because the One who sent them is One.")
                    }

                    Section(header: ArticleHeader("THE CHILDREN OF ISRAEL")) {
                        ArticleParagraph(articleMarkdown: "More prophets were sent to the **Children of Israel, Bani Israa’eel (بَنِي إِسرَائِيل)**, than to any other people. Allah favoured them openly, and the Quran says so:")
                        ScriptureQuote(quran: "2:47")

                        ArticleParagraph(articleMarkdown: "That favour came with a **covenant, Meethaaq (مِيثَاق)**: to worship Allah alone, to uphold the Torah, and to obey the prophets sent to them. The favour was never a birthright. It was a trust, and a trust can be broken.")

                        ArticleParagraph(verbatim: "They broke it repeatedly. They worshipped the calf while Moosa (peace be upon him) was away, they demanded to see Allah openly, they refused to enter the land they were commanded to enter, and they twisted the words of the scripture from their places. Worst of all, when the prophets came to them with what they did not want to hear, they rejected them, and they killed them. Allah says:")
                        ScriptureQuote(quran: "2:61", words: 36...58)

                        ArticleParagraph(verbatim: "Historical reports mention Zakariya and Yahya (peace be upon them) among the prophets who were killed, and the Quran records their plot against Eesa (peace be upon him), though Allah raised him to Himself and saved him from them.")

                        ArticleParagraph(verbatim: "So the covenant was withdrawn from them and the message was carried on through the line of Ismaa‘eel (إِسمَاعِيل), in Prophet Muhammad (peace and blessings be upon him). This is the crucial point: the covenant was never about lineage. It was about obedience. It was taken from them because of what they did, and it can be lost by anyone who does the same.")

                        ArticleParagraph(verbatim: "This is a warning to the Muslims before it is a criticism of anyone else. Allah does not favour a people for their ancestry. He favours them for their taqwa, and He removes His favour when they abandon it.")
                    }

                    Section(header: ArticleHeader("IMPORTANCE OF BELIEF IN PROPHETS")) {
                        ArticleParagraph(articleMarkdown: "Belief in the prophets is a pillar of **Eemaan (إِيمَان)**, faith. The Prophet Muhammad said:")
                        ScriptureQuote(hadith: "muslim:8a", cite: "Saheeh Muslim 8a", arabic: 273...284, english: 399...442)

                        ArticleParagraph(verbatim: "Muslims believe in every prophet without distinction, rejecting none of them, since they all conveyed the same message: to worship Allah alone. This does not make them equal in rank: Allah raised some above others (Quran 2:253), and Muhammad (peace and blessings be upon him) is the best of them. Allah (Glorified and Exalted be He) says:")
                        ScriptureQuote(quran: "2:253", words: 1...6)
                        ScriptureQuote(quran: "2:285", words: 0...13)
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("PROPHETS AND MESSENGERS")) {
                        ArticleParagraph(articleMarkdown: "There is a distinction between a prophet, **Nabi (نَبِيّ)**, from the root **n-b-a (ن ب أ)**, to bring news, and a messenger, **Rasool (رَسُول)**, from the root **r-s-l (ر س ل)**, to send. A prophet receives revelation from Allah; a messenger is sent with a message to a people, often with a new scripture or divine law. The scholars differ on the exact distinction between the two terms.")

                        ArticleParagraph(verbatim: "Every messenger is a prophet, but not every prophet is a messenger. Belief in them is not selective: to reject one prophet is to reject them all, because the One who sent them is One.")
                    }

                    Section(header: ArticleHeader("IMPORTANCE OF BELIEF IN PROPHETS")) {
                        ArticleParagraph(articleMarkdown: "Belief in the prophets is a pillar of **Eemaan (إِيمَان)**, faith. The Prophet Muhammad said:")
                        ScriptureQuote(hadith: "muslim:8a", cite: "Saheeh Muslim 8a", arabic: 273...284, english: 399...442)

                        ArticleParagraph(verbatim: "Muslims believe in every prophet without distinction, rejecting none of them, since they all conveyed the same message: to worship Allah alone. Allah (Glorified and Exalted be He) says:")
                        ScriptureQuote(quran: "2:285", words: 0...13)

                        ArticleParagraph(verbatim: "This does not make them equal in rank: Allah raised some above others, and Muhammad (peace and blessings be upon him) is the best of them.")
                    }
                }

                Section(header: ArticleHeader("LEGACY OF PROPHETS")) {
                    ArticleParagraph(verbatim: "Prophets were sent to guide humanity and exemplify righteousness. Their lives demonstrate the highest moral and spiritual qualities. The Quran recounts their stories as lessons and reminders for believers.")

                    ArticleParagraph(verbatim: "The final prophet, Muhammad, delivered the Quran and established a comprehensive way of life, leaving an eternal legacy of guidance for all humanity.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("VISUAL GUIDE")) {
                        ArticleParagraph(verbatim: "The order of the 25 prophets named in the Quran, from Aadam to Muhammad (peace be upon them all). Tap to open it full screen.")

                        Image("ProphetsChart1")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .focusableImage("ProphetsChart1", title: "The Prophets in Islam",
                                            subtitle: "The 25 prophets named in the Quran, in order")
                            .padding(.vertical, 4)

                        ArticleParagraph(verbatim: "A fuller family tree, showing how the prophets are related and which people each was sent to. It is dense: open it full screen and zoom in.")

                        Image("ProphetsChart2")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .focusableImage("ProphetsChart2", title: "Islamic Prophets Family Tree",
                                            subtitle: "Lineage, the people each was sent to, and Quranic mentions")
                            .padding(.vertical, 4)
                    }

                    Section(header: ArticleHeader("ABOUT THE CHARTS")) {
                        ArticleParagraph(verbatim: "The lineage in the second chart is a reconstruction. The Quran and the authentic Sunnah name the prophets and state some of the relationships between them (Ismaa‘eel and Ishaaq as sons of Ibraaheem, Ya‘qoob as the son of Ishaaq, Yoosuf as the son of Ya‘qoob, Haaroon as the brother of Moosa, Yahya as the son of Zakariya), but most of the intermediate generations, and the identifications of Idrees with Enoch and Dhul-Kifl with Ezekiel, come from the reports of the People of the Scripture. Those are neither affirmed nor denied: take the chart as a guide to the names, not as established creed.")
                    }

                    Section(header: ArticleHeader("IMAGE CREDITS")) {
                        Text(verbatim: "The first chart is shared with credit to its creator, @path_to_jannah.")
                            .font(.caption)

                        Link(destination: URL(string: "https://www.usefulcharts.com/products/islamic-prophets-family-tree")!) {
                            Label("Islamic Prophets Family Tree by UsefulCharts (CC BY-SA 3.0)", systemImage: "link")
                        }
                        .font(.caption)

                        Text(verbatim: "The second chart is \u{00A9} 2021 UsefulCharts Publishing, designed by Matt Baker, used under the Creative Commons Attribution-ShareAlike 3.0 licence. Prophet calligraphy by Syawish Reyman.")
                            .font(.caption)
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("The prophets all brought one message (worship of Allah alone), and Muhammad sealed and completed that guidance for all humanity.")
                }

                ArticleSourcesSection(article: "ProphetsView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "ProphetsView")
        .navigationTitle("Belief in the Prophets")
    }
}

struct DayView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: on the Last Day, Allah will resurrect all people and judge them for their deeds with perfect justice.")
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    ArticleParagraph(articleMarkdown: "Belief in the Last Day, **Yawm al-Qiyaamah (يَوم القِيَامَة)**, the Day of Resurrection, is a cornerstone of Islam and the fifth pillar of **Eemaan (إِيمَان)**, faith. It is the day when Allah (Glorified and Exalted be He) will resurrect all of creation to hold them accountable for their deeds. This belief is essential for understanding the purpose of life and the consequences of human actions.")

                    ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:")
                    ScriptureQuote(quran: "99:7-8")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("EVENTS OF THE DAY")) {
                        ArticleParagraph(verbatim: "The Day of Judgment will unfold in stages, including:")

                        ArticleStep("1. **The Blowing of the Trumpet**: The angel entrusted with the Horn will blow the trumpet twice: first to end all life and then to resurrect everyone. Allah says:")
                        ScriptureQuote(quran: "39:68")

                        ArticleStep("2. **Resurrection**: All people will rise from their graves to face their Lord. Allah says:")
                        ScriptureQuote(quran: "36:51")

                        ArticleStep("3. **The Reckoning, **Hisaab (حِسَاب)**,**: Every individual’s deeds will be reviewed, and their record of actions will be presented to them. Those who receive their record in their right hand will rejoice, while those who receive it in their left will despair.")

                        ArticleStep("4. **The Scale, **Meezaan (مِيزَان)**,**: Deeds will be weighed on a divine scale. Good deeds that outweigh bad deeds will lead to Paradise. Allah says:")
                        ScriptureQuote(quran: "7:8")

                        ArticleStep("5. **The Bridge, **As-Siraat (الصِّرَاط)**,**: A bridge over Hellfire that all people must cross. The righteous will cross safely, while others will fall.")
                    }

                    Section(header: ArticleHeader("IMPORTANCE OF BELIEF IN THE DAY OF JUDGMENT")) {
                        ArticleStep("1. **Accountability**: Believing in the Day of Judgment instills a sense of accountability. Every action, no matter how small, will be rewarded or punished accordingly.")

                        ArticleStep("2. **Moral Uprightness**: Encourages Muslims to lead righteous lives, avoid sin, and fulfill their obligations to Allah and others.")

                        ArticleStep("3. **Justice and Fairness**: The Day of Judgment is the ultimate manifestation of Allah’s justice. Every wrong will be rectified, and no one will be wronged. Allah says:")
                        ScriptureQuote(quran: "10:44")

                        ArticleStep("4. **Hope and Fear**: Belief in the Day of Judgment inspires hope in Allah’s mercy and fear of His punishment, creating a balance in a Muslim’s spiritual life.")
                    }

                    Section(header: ArticleHeader("QURANIC EMPHASIS")) {
                        ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) repeatedly emphasizes the Day of Judgment in the Quran as a reminder of the ultimate return to Him. He says:")
                        ScriptureQuote(quran: "40:16")

                        ArticleParagraph(verbatim: "In Surah Al-Qaariah, Allah vividly describes the weighing of deeds:")
                        ScriptureQuote(quran: "101:6-9")

                        ArticleParagraph(verbatim: "The Prophet Muhammad (peace and blessings be upon him) said about the Day of Judgment:")
                        ScriptureQuote(hadith: "muslim:2582", cite: "Saheeh Muslim 2582", arabic: 32...44, english: 0...29)

                        ArticleParagraph(verbatim: "This highlights Allah’s perfect justice, where no soul will be wronged, not even among animals.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("EVENTS OF THE DAY")) {
                        ArticleParagraph(verbatim: "The Day of Judgment will unfold in stages, including:")
                        ArticleStep("1. **The Blowing of the Trumpet**: The angel entrusted with the Horn will blow the trumpet twice: first to end all life and then to resurrect everyone.")
                        ArticleStep("2. **Resurrection**: All people will rise from their graves to face their Lord.")
                        ArticleStep("3. **The Reckoning, Hisaab (حِسَاب)**: Every individual’s deeds will be reviewed, and their record of actions will be given to them in the right hand or in the left.")
                        ArticleStep("4. **The Scale, Meezaan (مِيزَان)**: Deeds will be weighed on a divine scale, and good deeds that outweigh bad deeds will lead to Paradise.")
                        ArticleStep("5. **The Bridge, As-Siraat (الصِّرَاط)**: A bridge over Hellfire that all people must cross. The righteous will cross safely, while others will fall.")
                    }

                    Section(header: ArticleHeader("IMPORTANCE OF BELIEF IN THE DAY OF JUDGMENT")) {
                        ArticleParagraph(verbatim: "Believing in the Day of Judgment instills a sense of accountability, since every action, no matter how small, will be rewarded or punished. It is the ultimate manifestation of Allah’s justice, where no one will be wronged, and it balances hope in His mercy with fear of His punishment.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Certainty in the Last Day gives life meaning and accountability, balancing hope in Allah's mercy with fear of His justice.")
                }

                ArticleSourcesSection(article: "DayView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "DayView")
        .navigationTitle("Belief in the Last Day")
    }
}

struct QadarView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: Al-Qadar means everything happens by Allah's knowledge, writing, will, and creation, while people still choose and are accountable.")
                }

                Section(header: ArticleHeader("OVERVIEW")) {
                    ArticleParagraph(articleMarkdown: "Belief in **Qadar (قَدَر)** (from the root **q-d-r (ق د ر)**, to measure out or decree), or divine decree, is the sixth pillar of **Eemaan (إِيمَان)**, faith. It is the belief that everything occurs by the will, knowledge, and command of Allah (Glorified and Exalted be He). This includes both the good and the bad, as Allah’s wisdom is perfect, and His plans are flawless.")

                    ArticleParagraph(verbatim: "Allah (Glorified and Exalted be He) says in the Quran:")
                    ScriptureQuote(quran: "57:22")

                    ArticleParagraph(verbatim: "This belief fosters patience during trials, gratitude in blessings, and complete trust in Allah’s wisdom. It also reminds Muslims that Allah’s knowledge encompasses all things and that nothing happens outside of His will.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("COMPONENTS OF QADR")) {
                        ArticleParagraph(verbatim: "Scholars identify four essential components of Qadar:")

                        ArticleStep("1. **Allah’s Knowledge, Ilm (عِلم)**: Allah’s knowledge is infinite and perfect. He knows everything that has happened, is happening, and will happen. Allah says:")
                        ScriptureQuote(quran: "6:59", words: 1...18)

                        ArticleStep("2. **Allah’s Writing, Kitaabah (كِتَابَة)**: All things are written in **Al-Lawh Al-Mahfooz (اللَّوح المَحفُوظ)**, the Preserved Tablet, where every event, action, and outcome is recorded. Allah says:")
                        ScriptureQuote(quran: "22:70")

                        ArticleStep("3. **Allah’s Will, Mashiah (مَشِيئَة)**: Whatever Allah wills happens, and whatever He does not will does not happen. Allah says:")
                        ScriptureQuote(quran: "81:29")

                        ArticleStep("4. **Allah’s Creation, Khalq (خَلق)**: Allah is the Creator of all things, including actions, circumstances, and outcomes. Allah says:")
                        ScriptureQuote(quran: "39:62")
                    }

                    Section(header: ArticleHeader("BALANCE BETWEEN FREE WILL AND QADR")) {
                        ArticleParagraph(verbatim: "Islam teaches a balance between divine decree and human free will. While Allah knows and decrees all things, humans are given the freedom to make choices and are held accountable for them. This accountability ensures justice and moral responsibility.")

                        ArticleParagraph(verbatim: "The Prophet Muhammad (peace and blessings be upon him) said:")
                        ScriptureQuote(hadith: "muslim:2664", cite: "Saheeh Muslim 2664", arabic: 51...82, english: 22...87)
                    }

                    Section(header: ArticleHeader("PATIENT AND GRATEFUL")) {
                        ArticleParagraph(verbatim: "Belief in Qadar teaches Muslims to face life’s trials and blessings with patience and gratitude. Allah says in the Quran:")
                        ScriptureQuote(quran: "2:155-156")

                        ArticleParagraph(verbatim: "Through this belief, Muslims trust that every hardship is a test and every blessing is a favor from Allah, leading them closer to Him.")
                    }

                    Section(header: ArticleHeader("CONCLUSION")) {
                        ArticleParagraph(verbatim: "Belief in Qadar is a profound reminder of Allah’s ultimate authority, wisdom, and justice. It brings peace to the hearts of believers, knowing that everything happens for a reason, and Allah’s plans are always for the best. It encourages trust, patience, and gratitude in every aspect of life.")
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("COMPONENTS OF QADR")) {
                        ArticleParagraph(verbatim: "Scholars identify four essential components of Qadar:")
                        ArticleStep("1. **Allah’s Knowledge, Ilm (عِلم)**: He knows everything that has happened, is happening, and will happen.")
                        ArticleStep("2. **Allah’s Writing, Kitaabah (كِتَابَة)**: All things are written in **Al-Lawh Al-Mahfooz (اللَّوح المَحفُوظ)**, the Preserved Tablet.")
                        ArticleStep("3. **Allah’s Will, Mashiah (مَشِيئَة)**: Whatever Allah wills happens, and whatever He does not will does not happen. Allah says:")
                        ScriptureQuote(quran: "81:29")
                        ArticleStep("4. **Allah’s Creation, Khalq (خَلق)**: Allah is the Creator of all things, including actions, circumstances, and outcomes.")
                    }

                    Section(header: ArticleHeader("BALANCE BETWEEN FREE WILL AND QADR")) {
                        ArticleParagraph(verbatim: "Islam teaches a balance between divine decree and human free will. While Allah knows and decrees all things, humans are given the freedom to make choices and are held accountable for them. This accountability ensures justice and moral responsibility.")
                    }
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Belief in the divine decree brings patience in hardship and gratitude in ease, trusting that Allah's wisdom is always perfect.")
                }

                ArticleSourcesSection(article: "QadarView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "QadarView")
        .navigationTitle("Belief in Al-Qadar")
    }
}

/// The first of the three pillars of tawhid: Allah alone creates, owns and governs (Abu, 2026-11-24: "add a
/// section called three pillars of tawheed", beside the five pillars of Islam and the six of iman).
struct RububiyyahView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "RububiyyahView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Tawheed ar-Ruboobiyyah")
        .englishArticle().selectableArticleList(article: "RububiyyahView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: tawheed ar-ruboobiyyah is to single Allah out in His actions. He alone creates, He alone owns, and He alone governs everything that exists. Every soul is born knowing it, reason proves it, and the Quran argues from it. It is the first of the three pillars of tawheed, not the whole of it: the idolaters of Makkah affirmed it and were still idolaters, because they would not worship the Lord they affirmed."),
        ]),
        ArticleSection("WHAT IT MEANS", [
            .markdown("**Ruboobiyyah (رُبُوبِيَّة)** comes from **Rabb (رَبّ)**, from the root **ر-ب-ب**. In Arabic the rabb of a thing is its owner and master, the one who looks after it and raises it stage by stage until it is complete. Allah is **Rabb al-Aalameen**, the Lord of all the worlds, and these are the first words of praise in the Quran:"),
            .ayah("1:2"),
            .markdown("**Tawheed ar-ruboobiyyah (تَوحِيد الرُّبُوبِيَّة)** is to single Allah out in His actions. Ibn al-Uthaymeen (may Allah have mercy on him) defined it in three words:"),
            .quote(text: "“Singling out Allah, Glorified and Exalted is He, in creating, in dominion, and in disposing of affairs” (Ibn al-Uthaymeen, Sharh Thalaathat al-Usool; Majmoo‘ Fataawa wa Rasaa’il 6/34).", arabic: "إِفرَادُ اللَّهِ سُبحَانَهُ وَتَعَالَى بِالخَلقِ، وَالمُلكِ، وَالتَّدبِيرِ", dimmed: true),
            .text("Each of the three is in the Quran in so many words."),
            .markdown("**1. Creation (al-khalq).** Nothing exists that He did not create, and no one creates besides Him:"),
            .ayah("39:62"),
            .longOnly(.ayah("35:3", words: 6...14)),
            .longOnly(.markdown("**2. Dominion (al-mulk).** Everything belongs to Him, and those called upon besides Him do not own the thin skin over a date seed:")),
            .shortOnly(.markdown("**2. Dominion (al-mulk).** Everything belongs to Him:")),
            .ayah("3:189"),
            .longOnly(.ayah("35:13", words: 20...27)),
            .markdown("**3. Command (at-tadbeer).** He runs the affairs of the heavens and the earth, and nothing moves except by His decree:"),
            .ayah("32:5", words: 0...5),
            .longOnly(.text("And He joins creation and command in one short sentence:")),
            .longOnly(.ayah("7:54", words: 24...31)),
            .markdown("His command is of two kinds: the **cosmic command (al-amr al-kawni)**, by which He runs creation, “Be,” and it is; and the **legislative command (al-amr ash-shar‘i)**, by which He makes things lawful and unlawful. Both are His alone, and both come up again below."),
        ]),
        ArticleSection("HOW IT IS KNOWN", [
            .text("The Quran does not treat the Creator as a hidden matter to be guessed at. It treats Him as the plainest truth there is, and it calls four witnesses to it."),
            .longOnly(.markdown("**The fitrah.** Every person is born knowing his Lord. Allah took that witness from the children of Aadam before they came into the world:")),
            .longOnly(.ayah("7:172")),
            .longOnly(.ayah("30:30", words: 0...9)),
            .shortOnly(.markdown("**The fitrah.** Every person is born knowing his Lord.")),
            .text("The Prophet (peace be upon him) said that every child is born upon the fitrah, and it is his parents who make him otherwise (Saheeh al-Bukhaari 1385, Saheeh Muslim 2658)."),
            .hadith("bukhari:1385", cite: "Saheeh al-Bukhaari 1385, Saheeh Muslim 2658", arabic: 31...49, english: [4...44]),
            .markdown("**Distress.** The knowledge comes to the surface when every other hope is gone. Allah describes people at sea who call on Him alone when the waves rise, and go back to their partners once they reach land:"),
            .ayah("29:65"),
            .longOnly(.ayah("27:62", words: 0...6)),
            .markdown("**Reason.** A thing that began did not make itself, and it did not come from nothing, so it has a maker:"),
            .ayah("52:35-36"),
            .longOnly(.text("And the order of the heavens and the earth is itself a witness that there is one Lord, because two would have pulled creation apart:")),
            .longOnly(.ayah("21:22")),
            .longOnly(.ayah("67:3", words: 5...11)),
            .markdown("**The messengers.** The prophets argued from it, and no one could answer them. Moosa (peace be upon him) answered Pharaoh with this pillar:"),
            .ayah("20:49-50"),
            .longOnly(.text("And Ibraaheem (peace be upon him) silenced the king who claimed to give life and death by asking him to bring the sun up from the west:")),
            .longOnly(.ayah("2:258", words: 12...37)),
        ]),
        ArticleSection("WHO DENIED IT", only: .long, [
            .text("Few have ever denied the Creator outright, and those who did argued against what they knew. Pharaoh proclaimed himself the most high lord:"),
            .ayah("79:24"),
            .text("Yet Allah says of him and his people that they rejected the signs while their own souls were certain of them:"),
            .ayah("27:14", words: 0...3),
            .text("And Moosa told him to his face that he knew who had sent them:"),
            .ayah("17:102", words: 0...10),
            .text("Others denied the Resurrection and put their death down to time alone, and Allah answered that they speak without knowledge:"),
            .ayah("45:24"),
            .text("And no people ever held that the world has two equal makers. Ibn Taymiyyah (may Allah have mercy on him) said:"),
            .quote(text: "“Indeed, no one among mankind even claimed that the world has two makers equal in attributes and actions, and no one among the children of Aadam affirmed a god equal to Allah in all His attributes” (Ibn Taymiyyah, at-Tadmuriyyah; Majmoo‘ al-Fataawa 3/96).", arabic: "بَل وَلَا زَعَمَ أَحَدٌ مِنَ النَّاسِ أَنَّ العَالَمَ لَهُ صَانِعَانِ مُتَكَافِئَانِ فِي الصِّفَاتِ وَالأَفعَالِ، بَل وَلَا أَثبَتَ أَحَدٌ مِن بَنِي آدَمَ إِلَهًا مُسَاوِيًا لِلَّهِ فِي جَمِيعِ صِفَاتِهِ", dimmed: true),
            .text("Even the dualists who spoke of light and darkness did not make the two equal, as he goes on to say. So the dispute between the messengers and their peoples was almost never over who created the world. It was over who deserves to be worshipped."),
        ]),
        ArticleSection("THE IDOLATERS AFFIRMED IT", [
            .text("This is the point that decides everything else. The Arabs to whom the Prophet (peace be upon him) was sent believed in Allah as Creator, Provider and Disposer. Allah puts the question to them again and again, and reports their own answer:"),
            .ayah("29:61"),
            .longOnly(.ayah("31:25")),
            .longOnly(.ayah("43:87")),
            .longOnly(.text("They said it even on pilgrimage. Their talbiyah, the call of the pilgrims, affirmed that Allah owns the partners they gave Him:")),
            .longOnly(.hadith("muslim:1185", cite: "Saheeh Muslim 1185", arabic: 33...67, english: [0...52])),
            .longOnly(.text("“Enough, enough,” the Prophet said: stop at “You have no partner.” They would not stop, and the rest of their sentence is the whole of the problem: a partner who is owned, given a share of the worship that belongs to the One who owns him.")),
            .longOnly(.text("Muhammad ibn Abd al-Wahhaab (may Allah have mercy on him) made this the first of his Four Principles, and gave its proof:")),
            .longOnly(.quote(text: "“The first principle: that you know that the disbelievers whom the Messenger of Allah (peace be upon him) fought affirmed that Allah the Exalted is the Creator and the Disposer of affairs, and that this did not enter them into Islam” (Muhammad ibn Abd al-Wahhaab, al-Qawaa‘id al-Arba'; Mu’allafaat ash-Shaykh 1/200).", arabic: "القَاعِدَةُ الأُولَى: أَن تَعلَمَ أَنَّ الكُفَّارَ الَّذِينَ قَاتَلَهُم رَسُولُ اللَّهِ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ مُقِرُّونَ بِأَنَّ اللَّهَ تَعَالَى هُوَ الخَالِقُ المُدَبِّرُ، وَأَنَّ ذَلِكَ لَم يُدخِلهُم فِي الإِسلَامِ", dimmed: true)),
            .longOnly(.ayah("10:31")),
        ]),
        ArticleSection("WHAT BREAKS IT", [
            .text("This pillar is broken in two ways: by denying any part of His lordship, or by giving any share of it to another."),
            .longOnly(.markdown("**Denying the Creator**, which is atheism, or denying part of what He does. The Qadariyyah denied that Allah decrees and creates the deeds of His servants, and the Prophet (peace be upon him) called them the Magians of this nation, because like the Magians they set up a second creator:")),
            .longOnly(.hadith("abudawud:4691", cite: "Sunan Abi Daawood 4691; graded hasan by al-Albaani", arabic: 27...38, english: [4...32])),
            .longOnly(.ayah("37:96")),
            .shortOnly(.markdown("**Denying the Creator**, which is atheism, or denying part of what He does, as the Qadariyyah denied that Allah decrees and creates the deeds of His servants.")),
            .markdown("**Giving His control to another**: believing that saints, the “poles” and “helpers” of some Sufi orders, run the affairs of the world; that the stars send the rain or set a person’s fate; or that a charm turns away the decree. The Prophet (peace be upon him) said:"),
            .hadith("abudawud:3883", cite: "Sunan Abi Daawood 3883; graded saheeh by al-Albaani", arabic: 42...46, english: [19...24]),
            .text("The spells meant are the incantations of the Jaahiliyyah, with their appeals to the jinn. Ruqyah with the Quran and with dua that contains no shirk he approved: “There is no harm in ruqyah as long as it contains no shirk” (Saheeh Muslim 2200)."),
            .hadith("muslim:2200", cite: "Saheeh Muslim 2200", arabic: 41...48, english: [17...32]),
            .longOnly(.markdown("**Claiming His knowledge of the unseen.** Fortune-tellers, diviners and astrologers claim a knowledge Allah kept for Himself:")),
            .longOnly(.ayah("27:65", words: 0...9)),
            .longOnly(.hadith("muslim:2230", cite: "Saheeh Muslim 2230", arabic: 36...47, english: [0...20])),
            .markdown("**Claiming His right to legislate.** The legislative command is His, so whoever makes lawful what He forbade, or forbids what He made lawful, and is obeyed in it as a lawgiver, has been taken as a lord. Allah said of the People of the Book:"),
            .ayah("9:31", words: 0...6),
            .longOnly(.ayah("42:21", words: 0...11)),
            .longOnly(.text("The Companions explained the first ayah, in the reports at-Tabari and Ibn Katheer collect under it: the People of the Book did not pray to their rabbis and monks; they obeyed them in making the lawful unlawful and the unlawful lawful, and Allah called that taking them as lords.")),
            .shortOnly(.text("The Companions explained this ayah, in the reports at-Tabari and Ibn Katheer collect under it: the People of the Book did not pray to their rabbis and monks; they obeyed them in making the lawful unlawful and the unlawful lawful, and Allah called that taking them as lords.")),
        ]),
        ArticleSection("WHY IT IS NOT ENOUGH", [
            .text("Iblees himself affirmed his Lord. He called Him “my Lord,” swore by His might, and asked Him for respite, and he is the leader of every disbeliever:"),
            .ayah("15:36"),
            .longOnly(.ayah("38:82")),
            .text("So this pillar is necessary and not sufficient. It is the proof Allah gives for the second pillar, and the Quran rarely mentions His lordship without drawing that conclusion from it:"),
            .longOnly(.ayah("16:17")),
            .longOnly(.ayah("7:191")),
            .ayah("22:73"),
            .text("What creates nothing, owns nothing, and cannot take back what a fly has stolen from it cannot be worshipped. The second pillar, worship, has its own page:"),
            .door(.article("UluhiyyahView")),
        ]),
        ArticleSection("WHAT IT GIVES THE BELIEVER", only: .long, [
            .text("A heart that knows Allah alone creates, provides and decrees is freed from fearing creatures and from hanging its hopes on them. The Prophet (peace be upon him) taught it to Ibn Abbaas when he was a boy:"),
            .hadith("tirmidhi:2516", cite: "Jaami‘ at-Tirmidhi 2516; graded saheeh by al-Albaani", arabic: 65...114, english: [18...112]),
            .markdown("It brings **tawakkul**, reliance on Allah while taking the means He made:"),
            .ayah("65:3", words: 5...10),
            .text("And it brings contentment with what He decrees, so that a believer who loses something does not tear himself apart with “if only”:"),
            .hadith("muslim:2664", cite: "Saheeh Muslim 2664", arabic: 51...82, english: [22...87]),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**Is believing in God enough to make someone a Muslim?**"),
            .text("No. Belief in a Creator is where tawheed starts, not where it ends. Allah says of most people that they do not believe in Him except while associating others with Him (Quran 12:106): they affirm Him as Lord and worship others beside Him. Islam is to affirm Him as Lord and then worship Him alone."),
            .ayah("12:106"),
            .longOnly(.markdown("**Is taking medicine a breach of this tawheed?**")),
            .longOnly(.text("No. Allah made causes and commanded us to take them, and the Prophet (peace be upon him) said:")),
            .longOnly(.hadith("muslim:2204", cite: "Saheeh Muslim 2204", arabic: 41...52, english: [0...27])),
            .longOnly(.text("The breach is to believe that a cause acts by itself, without Allah, or to treat as a cause what Allah never made one: an amulet, a lucky number, a star.")),
            .longOnly(.markdown("**What about the miracles of the righteous?**")),
            .longOnly(.text("Ahl as-Sunnah affirm the karaamaat Allah grants His friends, but a karaamah is Allah’s act, not the saint’s power. The saint cannot summon it, and he runs nothing in the world, alive or dead. Allah commanded even His Messenger to say:")),
            .longOnly(.ayah("7:188", words: 0...10)),
            .longOnly(.markdown("**Is reading horoscopes harmless?**")),
            .longOnly(.text("Believing that the stars decide events is shirk in this pillar, because it gives the stars a share of His governing. And going to an astrologer to ask about the future is going to a diviner, which the hadith above forbids. Mu‘aawiyah ibn al-Hakam told the Prophet that some of his people went to soothsayers, and he said, “Do not go to them” (Saheeh Muslim 537).")),
            .longOnly(.hadith("muslim:537a", cite: "Saheeh Muslim 537", arabic: 145...162, english: [160...190])),
            .longOnly(.markdown("**Does the Quran argue for the existence of God at all?**")),
            .longOnly(.text("Yes, and in a single line: “Can there be doubt about Allah, Creator of the heavens and the earth?” (Quran 14:10).")),
            .longOnly(.ayah("14:10", words: 3...8)),
            .longOnly(.text("The arguments of reason and the fitrah are set out at length in their own page:")),
            .longOnly(.door(.article("GodPillarView"))),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Tawheed ar-ruboobiyyah is to single Allah out in creating, owning and governing, by His cosmic command and His legislative command. The fitrah knows it, reason proves it, and the messengers argued from it, but none of them stopped at it: the Makkans affirmed it and were still told to leave their idols. It is the foundation of the other two pillars and the proof of them, and whoever truly holds it will worship none but the Lord who made him."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .markdown("**Rabb (رَبّ)**: from **ر-ب-ب**, to own, look after, and raise to completion. The rabb of a thing is its owner and master. Allah is Rabb al-Aalameen; a person may be called rabb of a house or a camel only in the limited sense of owning it."),
            .markdown("**Al-khalq, al-mulk, at-tadbeer (الخَلق، المُلك، التَّدبِير)**: creation, dominion, and governing, the three things this pillar gives to Allah alone."),
            .markdown("**Al-amr al-kawni and al-amr ash-shar‘i (الأَمر الكَونِي، الأَمر الشَّرعِي)**: the cosmic command, by which everything happens (“Be,” and it is), and the legislative command, by which He makes things lawful and unlawful."),
            .markdown("**Fitrah (فِطرَة)**: from **ف-ط-ر**, to bring something new into being. The disposition every human is created upon, which knows its Lord before it is taught (Quran 30:30)."),
            .markdown("**Dahriyyah (الدَّهرِيَّة)**: from **dahr**, time. Those who said nothing destroys us except time (Quran 45:24): the old name for those who deny the Creator and the Resurrection."),
            .markdown("**Qadariyyah (القَدَرِيَّة)**: the sect that denied the decree, saying that Allah did not know or will the deeds of His servants until they did them, and that the servants create their own deeds. Ibn Umar disowned them (Saheeh Muslim 8)."),
            .hadith("muslim:8a", cite: "Saheeh Muslim 8a", arabic: 132...162, english: [132...223]),
            .markdown("**Tameemah (تَمِيمَة)**: an amulet hung on a person or an animal to ward off harm or the evil eye. Relying on it gives a share of Allah’s governing to a thread or a bead."),
            .markdown("**Tawakkul (تَوَكُّل)**: from **و-ك-ل**, to entrust. Relying on Allah with the heart while taking the means He made."),
        ]),
    ]
}

/// The second of the three pillars of tawhid: Allah alone is worshipped (Abu, 2026-11-24: "add a section
/// called three pillars of tawheed").
struct UluhiyyahView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "UluhiyyahView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Tawheed al-Uloohiyyah")
        .englishArticle().selectableArticleList(article: "UluhiyyahView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: tawheed al-uloohiyyah is to single Allah out with worship, so that every act of worship, of the heart, the tongue and the body, is for Him alone. It is the meaning of la ilaaha illallah, the message of every messenger, and the pillar the nations fought over. And a deed is worship that Allah accepts only when it is sincere for Him and done the way His Messenger taught."),
        ]),
        ArticleSection("WHAT IT MEANS", [
            .markdown("**Uloohiyyah (أُلُوهِيَّة)** comes from **ilaah (إِلَٰه)**, from the root **أ-ل-ه**: the one hearts turn to in love, awe, hope and need. An ilaah is not simply a powerful being; it is the one who is worshipped. So “there is no ilaah except Allah” means there is nothing rightly worshipped except Him."),
            .markdown("**Tawheed al-uloohiyyah (تَوحِيد الأُلُوهِيَّة)** is to single Allah out with the servants’ worship. Ibn al-Uthaymeen (may Allah have mercy on him) defined it:"),
            .quote(text: "“Singling out Allah, Glorified and Exalted is He, in worship: that a person does not take, along with Allah, anyone whom he worships and seeks to draw near to, as he worships Allah the Exalted and seeks to draw near to Him” (Ibn al-Uthaymeen, Sharh Thalaathat al-Usool; Majmoo‘ Fataawa wa Rasaa’il 6/34).", arabic: "إِفرَادُ اللَّهِ سُبحَانَهُ وَتَعَالَى بِالعِبَادَةِ، بِأَن لَا يَتَّخِذَ الإِنسَانُ مَعَ اللَّهِ أَحَدًا يَعبُدُهُ وَيَتَقَرَّبُ إِلَيهِ كَمَا يَعبُدُ اللَّهَ تَعَالَى وَيَتَقَرَّبُ إِلَيهِ", dimmed: true),
            .longOnly(.markdown("Seen from the servant’s side it is also called **tawheed al-‘ibaadah (تَوحِيد العِبَادَة)**, the tawheed of worship. Ibn al-Qayyim (may Allah have mercy on him) divided the tawheed the messengers called to into two kinds:")),
            .longOnly(.quote(text: "“It is of two kinds: tawheed in knowledge and affirmation, and tawheed in seeking and intention” (Ibn al-Qayyim, Madaarij as-Saalikeen 3/417).", arabic: "وَهُوَ نَوعَانِ: تَوحِيدٌ فِي المَعرِفَةِ وَالإِثبَاتِ، وَتَوحِيدٌ فِي المَطلَبِ وَالقَصدِ", dimmed: true)),
            .longOnly(.text("The first kind is knowing Allah as He told us of Himself, His names, His attributes and His actions: the first and third pillars. The second is seeking Him alone with every act of worship: this pillar. He explained that the Quran is either news about Allah, which is the first kind, or a call to worship Him alone and cast off everything worshipped besides Him, which is the second.")),
        ]),
        ArticleSection("WHY WE WERE CREATED", [
            .text("Allah (Glorified and Exalted be He) gave the purpose of the jinn and mankind in one ayah:"),
            .ayah("51:56"),
            .text("And every messenger opened his call with the same words. Allah reports them of Nooh, then of Hood, Saalih and Shu‘ayb (peace be upon them), each to his own people:"),
            .ayah("7:59", words: 5...13),
            .longOnly(.ayah("21:25")),
            .longOnly(.text("The messengers differed in their laws. They never differed in this. It is the first thing the Prophet (peace be upon him) told Mu‘aadh to call the people of Yemen to, before prayer and before zakaah (Saheeh al-Bukhaari 7372).")),
            .longOnly(.hadith("bukhari:7372", cite: "Saheeh al-Bukhaari 7372, Saheeh Muslim 19a", arabic: 49...93, english: [12...94])),
        ]),
        ArticleSection("WHAT WORSHIP IS", [
            .text("Worship is far wider than the prayer. Ibn Taymiyyah (may Allah have mercy on him) gave the definition the scholars use:"),
            .quote(text: "“Worship is a comprehensive term for everything Allah loves and is pleased with, of words and deeds, inward and outward” (Ibn Taymiyyah, al-Uboodiyyah).", arabic: "العِبَادَةُ هِيَ اسمٌ جَامِعٌ لِكُلِّ مَا يُحِبُّهُ اللَّهُ وَيَرضَاهُ مِنَ الأَقوَالِ وَالأَعمَالِ البَاطِنَةِ وَالظَّاهِرَةِ", dimmed: true),
            .longOnly(.text("Muhammad ibn Abd al-Wahhaab (may Allah have mercy on him) listed its kinds in al-Usool ath-Thalaathah, the short creed that children learn by heart:")),
            .longOnly(.quote(text: "“The kinds of worship that Allah commanded, such as Islam, eemaan and ihsaan, and among them supplication, fear, hope, reliance, eager desire, dread, humility, awe, turning back to Him, seeking help, seeking refuge, calling for rescue, sacrifice, vows, and the other kinds of worship that Allah commanded: all of them are for Allah the Exalted” (Muhammad ibn Abd al-Wahhaab, al-Usool ath-Thalaathah).", arabic: "وَأَنوَاعُ العِبَادَةِ الَّتِي أَمَرَ اللَّهُ بِهَا مِثلُ: الإِسلَامِ، وَالإِيمَانِ، وَالإِحسَانِ، وَمِنهُ: الدُّعَاءُ، وَالخَوفُ، وَالرَّجَاءُ، وَالتَّوَكُّلُ، وَالرَّغبَةُ، وَالرَّهبَةُ، وَالخُشُوعُ، وَالخَشيَةُ، وَالإِنَابَةُ، وَالِاستِعَانَةُ، وَالِاستِعَاذَةُ، وَالِاستِغَاثَةُ، وَالذَّبحُ، وَالنَّذرُ، وَغَيرُ ذَلِكَ مِن أَنوَاعِ العِبَادَةِ الَّتِي أَمَرَ اللَّهُ بِهَا، كُلُّهَا لِلَّهِ تَعَالَى", dimmed: true)),
            .longOnly(.text("He gave as its proof the ayah, “And the mosques are for Allah, so do not invoke with Allah anyone” (Quran 72:18), and said that whoever directs any of it to other than Allah is a mushrik and a disbeliever, citing Quran 23:117.")),
            .longOnly(.ayah("72:18")),
            .longOnly(.ayah("23:117")),
            .longOnly(.text("Every item in that list has its proof in the Quran or the Sunnah. A few of them:")),
            .shortOnly(.text("Its kinds include supplication, fear, hope, reliance, seeking help, seeking refuge, sacrifice, vows and love, and every one of them has its proof in the Quran or the Sunnah. A few of them:")),
            .markdown("**Supplication (du‘aa’)**, which the Prophet (peace be upon him) called worship itself:"),
            .hadith("abudawud:1479", cite: "Sunan Abi Daawood 1479; graded saheeh by al-Albaani", arabic: 25...33, english: [4...9]),
            .longOnly(.ayah("40:60")),
            .longOnly(.markdown("**Fear (khawf)** of the kind that belongs to Allah, the fear that keeps a person from sin:")),
            .longOnly(.ayah("3:175", words: 5...10)),
            .longOnly(.markdown("**Hope and dread (raghbah, rahbah)**, which Allah praised in His prophets:")),
            .longOnly(.ayah("21:90", words: 8...18)),
            .longOnly(.markdown("**Reliance (tawakkul)**, made a condition of faith:")),
            .longOnly(.ayah("5:23", words: 15...20)),
            .markdown("**Seeking help (isti‘aanah)**, said in every rak‘ah:"),
            .ayah("1:5"),
            .markdown("**Sacrifice and vows (dhabh, nadhr)**:"),
            .ayah("108:2"),
            .ayah("76:7"),
            .longOnly(.markdown("**Love (mahabbah)** of the kind owed to Allah alone:")),
            .longOnly(.ayah("2:165", words: 0...15)),
            .text("So a heart that fears a saint as it fears Allah, or a tongue that calls on the dead to rescue it, has given worship away as surely as a forehead that bows to an idol."),
        ]),
        ArticleSection("THE TWO CONDITIONS OF EVERY DEED", [
            .text("Worship is accepted on two conditions, and one ayah holds both:"),
            .ayah("18:110", words: 11...23),
            .markdown("“Righteous work” is work done the way the Messenger taught, which is **mutaaba‘ah (مُتَابَعَة)**, following. “And not associate in the worship of his Lord anyone” is **ikhlaas (إِخلَاص)**, sincerity. The Prophet (peace be upon him) gave each condition its own hadith:"),
            .hadith("bukhari:1", cite: "Saheeh al-Bukhaari 1, Saheeh Muslim 1907", arabic: 58...65, english: [6...26]),
            .hadith("muslim:1718b", cite: "Saheeh Muslim 1718", arabic: 64...71, english: [51...69]),
            .longOnly(.text("Al-Fudayl ibn Iyaad (may Allah have mercy on him) explained “that He might test you as to which of you is best in deed” (Quran 67:2) by these two:")),
            .longOnly(.quote(text: "“The most sincere of it and the most correct of it. If a deed is sincere but not correct, it is not accepted; and if it is correct but not sincere, it is not accepted, until it is both sincere and correct. Sincere is when it is for Allah, and correct is when it is upon the Sunnah” (Ibn Abi ad-Dunya, al-Ikhlaas wan-Niyyah 22; Abu Nu‘aym, Hilyat al-Awliyaa’ 8/95).", arabic: "أَخلَصُهُ وَأَصوَبُهُ. إِنَّ العَمَلَ إِذَا كَانَ خَالِصًا وَلَم يَكُن صَوَابًا لَم يُقبَل، وَإِذَا كَانَ صَوَابًا وَلَم يَكُن خَالِصًا لَم يُقبَل، حَتَّى يَكُونَ خَالِصًا صَوَابًا؛ وَالخَالِصُ: إِذَا كَانَ لِلَّهِ، وَالصَّوَابُ: إِذَا كَانَ عَلَى السُّنَّةِ", dimmed: true)),
            .longOnly(.ayah("67:2", words: 4...7)),
            .text("So tawheed and the Sunnah are two halves of one thing. Shirk spoils the first condition and bid‘ah spoils the second, which is why the scholars who wrote on tawheed wrote on bid‘ah beside it:"),
            .door(.article("BidahView")),
        ]),
        ArticleSection("WHAT THE MESSENGERS WERE OPPOSED OVER", [
            .text("The Makkans affirmed that Allah creates and provides; that is the first pillar. What they refused was this one. When the Prophet (peace be upon him) asked them to say la ilaaha illallah, they understood exactly what it asked of them:"),
            .ayah("38:5"),
            .text("And their defence of their idols was not that the idols created anything. It was intercession:"),
            .ayah("10:18"),
            .longOnly(.text("How did a people who knew Allah come to this? Ibn Abbaas (may Allah be pleased with them both) explained how the first idols began, among the people of Nooh:")),
            .longOnly(.hadith("bukhari:4920", cite: "Saheeh al-Bukhaari 4920", arabic: 60...91, english: [76...152])),
            .longOnly(.text("It began with love for righteous men, then images of them where they used to sit, and then, once knowledge faded, worship. That is why the Sunnah guards this pillar at its doors.")),
        ]),
        ArticleSection("HOW THE PROPHET GUARDED IT", only: .long, [
            .text("He forbade taking graves as places of worship, five days before he died:"),
            .hadith("muslim:532", cite: "Saheeh Muslim 532", arabic: 91...110, english: [65...100]),
            .text("He forbade praising him beyond his rank:"),
            .hadith("bukhari:3445", cite: "Saheeh al-Bukhaari 3445", arabic: 36...49, english: [6...35]),
            .text("And he sent Ali (may Allah be pleased with him) to efface images and level raised graves, and Ali later sent Abu al-Hayyaaj al-Asadi out with the same charge:"),
            .hadith("muslim:969a", cite: "Saheeh Muslim 969", arabic: 40...62, english: [0...29]),
            .text("None of this forbids visiting graves. The Prophet (peace be upon him) commanded it, to remember death and to pray for the dead (Saheeh Muslim 977, 976). What is forbidden is calling on the dead, taking their graves as places of prayer, and building over them."),
            .hadith("muslim:977a", cite: "Saheeh Muslim 977", arabic: 55...59, english: [0...11]),
            .hadith("muslim:976b", cite: "Saheeh Muslim 976", arabic: 56...60, english: [55...65]),
        ]),
        ArticleSection("INTERCESSION AND SEEKING A MEANS", [
            .text("Intercession is real, and the Prophet (peace be upon him) will intercede on the Day of Judgement. But it belongs to Allah, it comes only with His permission, and only for those He is pleased with:"),
            .ayah("39:44", words: 0...3),
            .longOnly(.ayah("2:255", words: 19...25)),
            .ayah("21:28", words: 6...10),
            .longOnly(.markdown("So it is asked **of Allah**: “O Allah, make Your Prophet an intercessor for me,” not called out to a grave. In the same way **tawassul (تَوَسُّل)**, seeking a means of nearness to Allah, has a lawful kind and an unlawful kind. The lawful kind is by Allah’s names, by one’s own faith and righteous deeds, as the three men trapped in the cave each called on Allah by a deed done for His sake (Saheeh al-Bukhaari 2272).")),
            .longOnly(.hadith("bukhari:2272", cite: "Saheeh al-Bukhaari 2272, Saheeh Muslim 2743", arabic: 32...63, english: [6...72])),
            .longOnly(.text("The lawful kind is also by the dua of a living righteous person:")),
            .longOnly(.hadith("bukhari:1010", cite: "Saheeh al-Bukhaari 1010", arabic: 36...59, english: [0...53])),
            .longOnly(.text("Umar did not go to the Prophet’s grave, a few steps away, and ask him. He asked the living al-Abbaas to pray. Calling on the dead or the absent for help is shirk; asking Allah “by the status” of a creature, which no Companion did, is an innovation.")),
            .shortOnly(.markdown("So it is asked **of Allah**: “O Allah, make Your Prophet an intercessor for me,” not called out to a grave. In the same way **tawassul (تَوَسُّل)**, seeking a means of nearness to Allah, is lawful by His names, by one’s own faith and righteous deeds, and by the dua of a living righteous person; calling on the dead or the absent for help is shirk.")),
        ]),
        ArticleSection("WHAT BREAKS IT", [
            .markdown("**Major shirk** takes a person out of Islam: calling on other than Allah for what only Allah can give, sacrificing or vowing to other than Him, bowing to or circling a grave in worship, or loving, fearing or relying on a creature as one should on Allah. Whoever meets Allah upon it:"),
            .hadith("muslim:93b", cite: "Saheeh Muslim 93", arabic: 38...52, english: [8...29]),
            .markdown("**Minor shirk** does not take a person out of Islam, but it ruins the deed it enters. Its commonest form is **riyaa’ (رِيَاء)**, worship done to be seen:"),
            .hadith("muslim:2985", cite: "Saheeh Muslim 2985", arabic: 34...51, english: [0...36]),
            .text("Its forms, old and new, and their cure, are on the page on shirk:"),
            .door(.article("ShirkView")),
        ]),
        ArticleSection("WHAT IT GIVES THE BELIEVER", only: .long, [
            .text("Safety and guidance, promised to faith that is not mixed with shirk:"),
            .ayah("6:82"),
            .text("And freedom. Allah gives the example of a slave owned by quarrelling partners, each pulling him a different way, and a slave who belongs to one master:"),
            .ayah("39:29"),
            .text("The one who worships Allah alone serves one Master, whose pleasure is known from His Book. The one who worships many is pulled apart by them, and none of them can answer him."),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**Is asking a living person for help shirk?**"),
            .text("No, when it is something he is able to do. Allah relates that a man of Moosa’s people “called to him for help” against his enemy, and Moosa helped him (Quran 28:15). It becomes shirk when a creature is asked for what only Allah can do, or when the dead or the absent are called upon."),
            .ayah("28:15", words: 17...24),
            .longOnly(.markdown("**Is loving the Prophet too much a kind of shirk?**")),
            .longOnly(.text("Loving him more than one’s parents, one’s children and all people is part of faith (Saheeh al-Bukhaari 15). What is forbidden is giving him what belongs to Allah: calling on him for rescue, vowing to him, or claiming he knows the unseen. He himself forbade being praised as the Christians praised the son of Mary, as quoted above.")),
            .longOnly(.hadith("bukhari:15", cite: "Saheeh al-Bukhaari 15, Saheeh Muslim 44a", arabic: 40...51, english: [4...22])),
            .longOnly(.markdown("**Does worshipping for Paradise, or out of fear of the Fire, spoil sincerity?**")),
            .longOnly(.text("No. Allah praised the prophets for calling on Him “in hope and in dread” (Quran 21:90, quoted above), and promised Paradise and warned of the Fire throughout His Book. Seeking His reward and fleeing His punishment is worshipping Him; the fault is seeking the praise of people.")),
            .longOnly(.markdown("**Isn’t the Prophet’s grave inside his mosque?**")),
            .longOnly(.text("He was buried in Aa’ishah’s room, beside the mosque, not in it. The room was brought inside the mosque decades later, in an expansion under the Umayyad caliph al-Waleed ibn Abd al-Malik, after most of the Companions of Madinah had passed. An act done after them cannot set aside his own words, said in his last days, forbidding graves to be taken as places of worship.")),
            .longOnly(.markdown("**Where is this taught at length?**")),
            .longOnly(.text("In Kitaab at-Tawheed of Muhammad ibn Abd al-Wahhaab, whose sixty-six chapters are almost all about this pillar, and in Ibn al-Uthaymeen’s explanation of it, al-Qawl al-Mufeed. The meaning of the testimony and its conditions are on the page on tawheed:")),
            .longOnly(.door(.article("TawhidView"))),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Tawheed al-uloohiyyah is to single Allah out with worship, inward and outward: dua, fear, hope, reliance, love, sacrifice, vows and every other act He loves. It is what every messenger was sent with and what the nations refused, while they affirmed Allah as their Lord. A deed is accepted when it is sincere for Allah and follows His Messenger, and the Sunnah closes every door that leads from loving the righteous to worshipping them."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .markdown("**Ilaah (إِلَٰه)**: from **أ-ل-ه**, to turn to in love and need. The one worshipped. From it **uloohiyyah**, the right to be worshipped."),
            .markdown("**Ibaadah (عِبَادَة)**: from **ع-ب-د**, to humble oneself and submit. Everything Allah loves and is pleased with, of words and deeds, inward and outward."),
            .markdown("**Ikhlaas (إِخلَاص)**: from **خ-ل-ص**, to be pure and unmixed. Intending Allah alone by a deed. The first condition of its acceptance."),
            .markdown("**Mutaaba‘ah (مُتَابَعَة)**: from **ت-ب-ع**, to follow. Doing the deed the way the Messenger (peace be upon him) did it. The second condition."),
            .markdown("**Riyaa’ (رِيَاء)**: from **ر-أ-ي**, to see. Doing worship so that people will see it. Minor shirk."),
            .markdown("**Shafaa‘ah (شَفَاعَة)**: from **ش-ف-ع**, to make a pair, to add oneself to another. Intercession: asking good for another before Allah. It belongs to Allah and comes only by His permission."),
            .markdown("**Tawassul (تَوَسُّل)**: from **و-س-ل**, to seek a way to something. Seeking nearness to Allah by a means He legislated: His names, one’s faith and deeds, or the dua of a living righteous person."),
            .markdown("**Istighaathah (اِستِغَاثَة)**: from **غ-و-ث**, to call for rescue. Lawful when asked of a living person present and able; shirk when asked of the dead, the absent, or anyone for what only Allah can do."),
            .markdown("**Nadhr (نَذر)**: a vow, binding oneself to an act of worship. It is worship, so a vow to other than Allah is shirk."),
        ]),
    ]
}

/// The third of the three pillars of tawhid: Allah's names and attributes, affirmed as they came, without
/// twisting, denying, asking how or likening (Abu, 2026-11-24: "add a section called three pillars of
/// tawheed"; Imam Malik's istiwa rule is the heart of it).
struct AsmaSifatView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "AsmaSifatView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Names and Attributes")
        .englishArticle().selectableArticleList(article: "AsmaSifatView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: tawheed al-asmaa’ was-sifaat is to affirm for Allah every name and attribute He affirmed for Himself or His Messenger affirmed for Him, and to deny what they denied of Him, without twisting the meaning, emptying it, asking how, or likening Him to His creation. The Salaf knew the meanings and left the how to Allah, as Imam Maalik put it: the rising is not unknown, and the how is beyond reason."),
        ]),
        ArticleSection("WHAT IT MEANS", [
            .markdown("A **name (ism, اِسم)** is what Allah is called: ar-Rahman, al-Ghafoor, as-Samee‘. An **attribute (sifah, صِفَة)** is what He is described with: mercy, forgiveness, hearing, His Face, His Hands, His rising over the Throne. **Tawheed al-asmaa’ was-sifaat (تَوحِيد الأَسمَاء وَالصِّفَات)** is to single Allah out in them. Ibn al-Uthaymeen (may Allah have mercy on him) defined it:"),
            .quote(text: "“Singling out Allah, Glorified and Exalted is He, in what He named Himself and described Himself with in His Book or on the tongue of His Messenger (peace be upon him): by affirming what He affirmed and negating what He negated, without distortion or denial, and without asking how or likening” (Ibn al-Uthaymeen, Sharh Thalaathat al-Usool; Majmoo‘ Fataawa wa Rasaa’il 6/34).", arabic: "إِفرَادُ اللَّهِ سُبحَانَهُ وَتَعَالَى بِمَا سَمَّى بِهِ نَفسَهُ، وَوَصَفَ بِهِ نَفسَهُ فِي كِتَابِهِ، أَو عَلَى لِسَانِ رَسُولِهِ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ، وَذَلِكَ بِإِثبَاتِ مَا أَثبَتَهُ، وَنَفيِ مَا نَفَاهُ، مِن غَيرِ تَحرِيفٍ، وَلَا تَعطِيلٍ، وَمِن غَيرِ تَكيِيفٍ، وَلَا تَمثِيلٍ", dimmed: true),
            .longOnly(.text("Ibn Taymiyyah (may Allah have mercy on him) put the creed of Ahl as-Sunnah in the same words at the opening of al-Aqeedah al-Waasitiyyah:")),
            .longOnly(.quote(text: "“Part of faith in Allah is faith in what He has described Himself with in His Book and in what His Messenger Muhammad (peace be upon him) has described Him with, without distortion (tahreef) or denial (ta‘teel), and without asking how (takyeef) or likening (tamtheel)” (Ibn Taymiyyah, al-Aqeedah al-Waasitiyyah).", arabic: "وَمِنَ الإِيمَانِ بِاللَّهِ: الإِيمَانُ بِمَا وَصَفَ بِهِ نَفسَهُ فِي كِتَابِهِ وَبِمَا وَصَفَهُ بِهِ رَسُولُهُ مُحَمَّدٌ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ مِن غَيرِ تَحرِيفٍ وَلَا تَعطِيلٍ وَمِن غَيرِ تَكيِيفٍ وَلَا تَمثِيلٍ", dimmed: true)),
        ]),
        ArticleSection("THE RULE IN ONE AYAH", [
            .ayah("42:11", words: 13...18),
            .text("Its first half denies any likeness: nothing is like Him, not in His essence, His attributes, or His actions. Its second half affirms real attributes: He hears and He sees. Whoever denies the attributes to keep the first half has contradicted the second, and whoever likens them to creation to keep the second has contradicted the first. Ahl as-Sunnah hold both halves together, and that is the whole of this pillar."),
            .longOnly(.text("And the knowledge of how He is lies beyond every creature:")),
            .longOnly(.ayah("20:110", words: 6...9)),
        ]),
        ArticleSection("WHERE THE NAMES COME FROM", [
            .longOnly(.text("No one has seen Allah, and nothing is like Him, so nothing can be said of Him by analogy or guesswork. What He is called and described with comes from the Quran and the authentic Sunnah, and nowhere else. Speaking about Him without knowledge is placed beside shirk itself:")),
            .longOnly(.ayah("7:33", words: 22...28)),
            .shortOnly(.text("No one has seen Allah, and nothing is like Him, so nothing can be said of Him by analogy or guesswork. What He is called and described with comes from the Quran and the authentic Sunnah, and nowhere else.")),
            .longOnly(.ayah("17:36", words: 0...6)),
            .longOnly(.text("Imam Ahmad (may Allah have mercy on him) said, in the words his cousin and student Hanbal ibn Ishaaq heard from him:")),
            .longOnly(.quote(text: "“We worship Allah with His attributes as He described Himself; He has stated the attribute for Himself. We do not go beyond the Quran and the hadith: we say as He said and describe Him as He described Himself, and we do not go beyond that” (Ahmad ibn Hanbal, reported by Hanbal ibn Ishaaq: Ibn Battah, al-Ibaanah 7/326).", arabic: "نَعبُدُ اللَّهَ بِصِفَاتِهِ كَمَا وَصَفَ بِهِ نَفسَهُ، قَد أَجمَلَ الصِّفَةَ لِنَفسِهِ، وَلَا نَتَعَدَّى القُرآنَ وَالحَدِيثَ، فَنَقُولُ كَمَا قَالَ، وَنَصِفُهُ كَمَا وَصَفَ نَفسَهُ، وَلَا نَتَعَدَّى ذَلِكَ", dimmed: true)),
            .markdown("So the names are **tawqeefiyyah (تَوقِيفِيَّة)**: fixed by the texts. Allah is not named “the Architect” or “the First Cause” because a philosopher found the word apt, and He is not denied a name He gave Himself because a theologian found it awkward."),
        ]),
        ArticleSection("THE FOUR ERRORS", [
            .longOnly(.text("Every deviation in this pillar is one of four, and the sentence of al-Waasitiyyah names them all.")),
            .shortOnly(.text("Every deviation in this pillar is one of four, and the definition above names them all.")),
            .longOnly(.markdown("**1. Tahreef (تَحرِيف), twisting.** Changing a word or turning it from its meaning: reading “He rose over the Throne” as “He conquered it,” or “His Hand” as “His power.” Allah condemned it in those before us:")),
            .longOnly(.ayah("4:46", words: 0...6)),
            .shortOnly(.markdown("**1. Tahreef (تَحرِيف), twisting.** Changing a word or turning it from its meaning: reading “He rose over the Throne” as “He conquered it,” or “His Hand” as “His power.”")),
            .longOnly(.text("Allah told Iblees, “What prevented you from prostrating to that which I created with My two Hands?” If the Hands were His power, Aadam would have no honour over Iblees, for Iblees too was created by His power; and power is not spoken of in pairs.")),
            .longOnly(.ayah("38:75", words: 0...13)),
            .markdown("**2. Ta‘teel (تَعطِيل), emptying.** Denying an attribute altogether, or emptying it of any meaning. The Jahmiyyah denied every attribute, the Mu‘tazilah kept the names and denied the attributes, and later schools affirmed some and denied others."),
            .markdown("**3. Takyeef (تَكيِيف), asking how.** Describing the manner of an attribute, or asking for it. The how is not given in the texts, so it is not known."),
            .markdown("**4. Tamtheel (تَمثِيل), likening.** Making His attributes like the attributes of creation: “His Hand is like our hands.”"),
            .longOnly(.ayah("16:74")),
            .text("Tahreef and ta‘teel are the errors of those who fled likening into denial. Takyeef and tamtheel are the errors of those who fled denial into likening. The way of the Salaf is the middle between them, as it is in everything."),
        ]),
        ArticleSection("THE RULES THE SALAF WALKED BY", [
            .longOnly(.text("Ibn Taymiyyah set these out in at-Tadmuriyyah, and Ibn al-Uthaymeen gathered them in al-Qawaa‘id al-Muthla. Six of them carry most of the subject.")),
            .shortOnly(.text("Ibn Taymiyyah set these out in at-Tadmuriyyah, and Ibn al-Uthaymeen gathered them in al-Qawaa‘id al-Muthla. Among them:")),
            .markdown("**1. Every name is beautiful, and every name carries an attribute.** Allah’s names are not empty labels. Al-Ghafoor is the Forgiving because He has forgiveness, and as-Samee‘ is the All-Hearing because He hears:"),
            .ayah("7:180", words: 0...4),
            .longOnly(.markdown("**2. What He denies of Himself is to affirm the perfection of its opposite.** He is not touched by drowsiness or sleep, because His life and His sustaining of creation are perfect; He wrongs no one, because His justice is perfect; no weariness touched Him in creating the heavens, because His power is perfect:")),
            .longOnly(.ayah("2:255", words: 7...11)),
            .longOnly(.ayah("18:49", words: 23...26)),
            .longOnly(.ayah("50:38")),
            .shortOnly(.markdown("**2. What He denies of Himself is to affirm the perfection of its opposite.** He is not touched by drowsiness or sleep, because His life and His sustaining of creation are perfect; He wrongs no one, because His justice is perfect; no weariness touched Him in creating the heavens, because His power is perfect.")),
            .longOnly(.markdown("**3. Speaking about the attributes is like speaking about the essence.** Allah has a real essence unlike every other essence, and no Muslim asks how His essence is. So He has real attributes unlike every other attribute, and no one asks how they are either. Ibn Taymiyyah put it:")),
            .longOnly(.quote(text: "“What is said about the attributes is like what is said about the essence. For nothing is like Allah, not in His essence, nor in His attributes, nor in His actions. So if He has a real essence that is not like other essences, that essence is described by real attributes that are not like the attributes of other essences” (Ibn Taymiyyah, at-Tadmuriyyah p. 43; Majmoo‘ al-Fataawa 3/25).", arabic: "القَولُ فِي الصِّفَاتِ كَالقَولِ فِي الذَّاتِ، فَإِنَّ اللَّهَ لَيسَ كَمِثلِهِ شَيءٌ، لَا فِي ذَاتِهِ، وَلَا فِي صِفَاتِهِ، وَلَا فِي أَفعَالِهِ، فَإِذَا كَانَ لَهُ ذَاتٌ حَقِيقَةً لَا تُمَاثِلُ الذَّوَاتِ، فَالذَّاتُ مُتَّصِفَةٌ بِصِفَاتٍ حَقِيقَةً لَا تُمَاثِلُ صِفَاتِ سَائِرِ الذَّوَاتِ", dimmed: true)),
            .shortOnly(.markdown("**3. Speaking about the attributes is like speaking about the essence.** Allah has a real essence unlike every other essence, and no Muslim asks how His essence is. So He has real attributes unlike every other attribute, and no one asks how they are either.")),
            .markdown("**4. Speaking about some attributes is like speaking about others.** Whoever affirms that Allah hears and sees, without likening His hearing to ours, has no ground to deny that He rises over His Throne, descends, or is pleased and angry, without likening those either. What is said of one is said of all."),
            .markdown("**5. The meaning is known; the how is not.** When a man asked Imam Maalik (may Allah have mercy on him) how Allah rose over the Throne, he gave the answer that became the rule for every attribute:"),
            .quote(text: "“The rising is not unknown, the ‘how’ is not comprehensible, believing in it is obligatory, and asking about it is an innovation” (al-Bayhaqi, al-Asmaa’ was-Sifaat 867; al-Laalakaa’i 664).", arabic: "الِاستِوَاءُ غَيرُ مَجهُولٍ، وَالكَيفُ غَيرُ مَعقُولٍ، وَالإِيمَانُ بِهِ وَاجِبٌ، وَالسُّؤَالُ عَنهُ بِدعَةٌ", dimmed: true),
            .markdown("His four clauses answer all four errors. **“Not unknown”**: the word is Arabic and its meaning, rising over, is known, so it is not emptied or twisted. **“The how is not comprehensible”**: the manner is beyond us, so it is not described or likened. **“Believing in it is obligatory”**: Allah said it of Himself, seven times in His Book. **“Asking about it is an innovation”**: the Companions, who knew Allah best, never asked how, and Maalik had the questioner sent out of his circle. What Maalik said of the rising is said of every attribute: of the Hands, the Face, the descent, the pleasure and the anger."),
            .longOnly(.markdown("**6. Some attributes are of His essence, and some are of His action.** Attributes of the essence never leave Him: life, knowledge, power, hearing, sight, His Face and His Hands. Attributes of action are tied to His will, and He does them when He wills: His rising over the Throne, His descent, His coming on the Day of Judgement, His speaking, His pleasure and His anger:")),
            .longOnly(.ayah("89:22")),
            .longOnly(.ayah("5:119", words: 16...20)),
        ]),
        ArticleSection("ALLAH IS ABOVE HIS CREATION", [
            .markdown("The attribute over which the Salaf and the later schools parted most plainly is **al-‘uluw (العُلُوّ)**, Allah’s being above His creation, over His Throne. The texts on it are so many that they cannot be read away:"),
            .ayah("20:5"),
            .longOnly(.ayah("67:16")),
            .longOnly(.ayah("35:10", words: 7...13)),
            .longOnly(.ayah("16:50")),
            .text("The Prophet (peace be upon him) tested a slave girl’s faith with one question:"),
            .hadith("muslim:537a", cite: "Saheeh Muslim 537", arabic: 266...289, english: [354...386]),
            .longOnly(.hadith("bukhari:7422", cite: "Saheeh al-Bukhaari 7422", arabic: 22...34, text: "“When Allah decreed the creation, He wrote with Him, above His Throne: ‘My mercy has preceded My anger.’”")),
            .longOnly(.text("And He is with His creation by His knowledge, hearing and sight, wherever they are, without mixing with them. The same ayah that says He rose over the Throne says He is with us:")),
            .longOnly(.ayah("57:4", words: 8...35)),
            .shortOnly(.text("And He is with His creation by His knowledge, hearing and sight, wherever they are, without mixing with them.")),
            .text("So His being above and His being with us do not conflict. Ibn Taymiyyah gives the example of the moon in al-Aqeedah al-Waasitiyyah: it is in the sky, one of the smallest of Allah’s creations, and it is with the traveller wherever he goes. How much more so the Creator, who is above everything and encompasses everything."),
            .door(.article("AqeedahMadhabView")),
        ]),
        ArticleSection("SEEING ALLAH IN THE HEREAFTER", [
            .text("The believers will see their Lord with their own eyes in Paradise, and it will be the greatest of its delights:"),
            .ayah("75:22-23"),
            .longOnly(.ayah("10:26", words: 1...4)),
            .longOnly(.text("The Prophet (peace be upon him) explained the “more” in that ayah:")),
            .longOnly(.hadith("muslim:181a", cite: "Saheeh Muslim 181", arabic: 37...77, english: [0...77])),
            .longOnly(.text("In the narration after it he recited the ayah, “For those who have done good is the best reward and extra” (Saheeh Muslim 181b). And of the disbelievers Allah says that on that Day they will be partitioned from their Lord (Quran 83:15), which the scholars took as proof that the believers will not be.")),
            .longOnly(.ayah("83:15")),
        ]),
        ArticleSection("WHAT THE SALAF SAID", only: .long, [
            .text("They said the same thing in every city. Al-Awzaa‘i (d. 157 AH), the imam of Syria, said:"),
            .quote(text: "“We used to say, while the Successors were still many: Allah, exalted be His mention, is above His Throne; and we believe in the attributes of His that the Sunnah has brought, Majestic and Exalted is He” (al-Bayhaqi, al-Asmaa’ was-Sifaat 865; Ibn Taymiyyah called its chain saheeh, Majmoo‘ al-Fataawa 5/39).", arabic: "كُنَّا، وَالتَّابِعُونَ مُتَوَافِرُونَ، نَقُولُ: إِنَّ اللَّهَ تَعَالَى ذِكرُهُ فَوقَ عَرشِهِ، وَنُؤمِنُ بِمَا وَرَدَتِ السُّنَّةُ بِهِ مِن صِفَاتِهِ جَلَّ وَعَلَا", dimmed: true),
            .text("Al-Waleed ibn Muslim put the question to four imams of that generation, al-Awzaa‘i, Sufyaan ath-Thawri, Maalik and al-Layth ibn Sa‘d, asking them about the hadiths that contain the attributes:"),
            .quote(text: "“Every one of them said: Pass them on as they came, without tafseer” (al-Aajurri, ash-Sharee‘ah 720; al-Albaani graded the report saheeh, Mukhtasar al-Uluw p. 142).", arabic: "فَكُلُّهُم قَالَ: أَمِرُّوهَا كَمَا جَاءَت بِلَا تَفسِيرٍ", dimmed: true),
            .text("“Without tafseer” means without the explanations that turn the words from their meaning, and without asking how. In another narration of the same report they said “without how” (al-Laalakaa’i 875). As Ibn Taymiyyah explained in al-Hamawiyyah, “pass them on as they came” answers those who empty the attributes, since a text passed on as it came keeps its meaning, and “without how” answers those who liken them."),
            .text("Maalik’s own teacher, Rabee‘ah ar-Ra’y, was asked the same question about the rising before him, and answered:"),
            .quote(text: "“The rising is not unknown, and the how is not comprehensible. From Allah comes the message, on the Messenger is the conveying, and on us is believing it” (al-Laalakaa’i 665; graded saheeh by al-Albaani, Mukhtasar al-Uluw p. 132).", arabic: "الِاستِوَاءُ غَيرُ مَجهُولٍ، وَالكَيفُ غَيرُ مَعقُولٍ، وَمِنَ اللَّهِ الرِّسَالَةُ، وَعَلَى الرَّسُولِ البَلَاغُ، وَعَلَينَا التَّصدِيقُ", dimmed: true),
            .text("Nu‘aym ibn Hammaad (d. 228 AH), one of al-Bukhaari’s teachers, named both errors in one sentence:"),
            .quote(text: "“Whoever likens Allah to His creation has disbelieved. Whoever denies what He described Himself with has disbelieved. And what Allah described Himself with, and what His Messenger described Him with, is not likening” (adh-Dhahabi, al-Uluw 464; al-Albaani graded its chain saheeh, Mukhtasar al-Uluw p. 184).", arabic: "مَن شَبَّهَ اللَّهَ بِخَلقِهِ فَقَد كَفَرَ، وَمَن أَنكَرَ مَا وَصَفَ بِهِ نَفسَهُ فَقَد كَفَرَ، وَلَيسَ مَا وَصَفَ اللَّهُ بِهِ نَفسَهُ وَلَا رَسُولُهُ تَشبِيهًا", dimmed: true),
            .text("And at-Tahaawi (d. 321 AH), writing down the creed of Abu Haneefah and his two companions, said:"),
            .quote(text: "“Imaginations do not reach Him, understandings do not grasp Him, and He does not resemble the creatures” (at-Tahaawi, al-Aqeedah at-Tahaawiyyah).", arabic: "لَا تَبلُغُهُ الأَوهَامُ، وَلَا تُدرِكُهُ الأَفهَامُ، وَلَا يُشبِهُ الأَنَامَ", dimmed: true),
            .text("Madinah, Syria, Koofah and Egypt, and one creed: affirm what came, ask no how, and liken nothing."),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**Doesn’t affirming a Hand for Allah liken Him to creation?**"),
            .text("No. Sharing a word is not sharing a reality. Allah calls Himself the All-Hearing, the All-Seeing, and He called man “hearing and seeing” too (Quran 76:2); no one thinks the two are alike. Even among creatures, the hand of a man, the leg of an ant and the “hand” of a door share a word and differ in everything. The Creator differs from all of them more than they differ from each other."),
            .ayah("76:2", words: 7...9),
            .longOnly(.markdown("**Didn’t the Salaf leave the meanings unknown?**")),
            .longOnly(.text("No. That claim is called tafweed, and Maalik’s own words refute it: “the rising is not unknown.” The Salaf left the how to Allah, not the meaning. A text whose meaning no one knows would teach nothing, and Allah described His Book as a clear Arabic Quran revealed to be understood. Ibn Taymiyyah counted the saying of those who claim the Salaf consigned the meanings among the worst sayings of the people of innovation (Daar' Ta‘aarud al-Aql wan-Naql 1/205).")),
            .markdown("**Is it correct to say Allah is everywhere?**"),
            .text("No. He is above His creation, over His Throne, and with His creation by His knowledge, hearing, sight and power. “Everywhere” would place Him inside His creation, in places unworthy of Him, which is what the Jahmiyyah said and the Salaf rejected."),
            .longOnly(.markdown("**Is it wrong to ask “Where is Allah?”**")),
            .longOnly(.text("The Prophet (peace be upon him) asked it himself, and accepted “in the heaven” as the answer of a believer (Saheeh Muslim 537, quoted above). “In the heaven” means above, over the heavens, not inside a created sky that contains Him.")),
            .longOnly(.markdown("**How many names does Allah have?**")),
            .longOnly(.text("More than ninety-nine. The Prophet (peace be upon him) said that Allah has ninety-nine names and whoever learns them and lives by them enters Paradise (Saheeh al-Bukhaari 2736); that is a promise about ninety-nine of them, not a limit on how many there are.")),
            .longOnly(.hadith("bukhari:2736", cite: "Saheeh al-Bukhaari 2736, Saheeh Muslim 2677", arabic: 28...39, english: [4...19])),
            .longOnly(.text("The names, with their meanings and their proofs, have their own page:")),
            .longOnly(.door(.article("NamesOfAllahPillarView"))),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Tawheed al-asmaa’ was-sifaat is to call Allah by the names He gave Himself and describe Him with what He and His Messenger described Him with, affirming the meaning and leaving the how to Him, with nothing like Him in any of it. The Salaf walked between those who twisted and denied and those who pictured and likened, and Imam Maalik gave their rule in one sentence: the rising is not unknown, the how is beyond reason, believing in it is obligatory, and asking about it is an innovation."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .markdown("**Ism and sifah (اِسم، صِفَة)**: a name and an attribute. Every name of Allah carries an attribute; not every attribute gives a name. He is described with rising, and is not named “the Riser.”"),
            .markdown("**Tahreef (تَحرِيف)**: from **ح-ر-ف**, an edge; to turn a word from its place or its meaning."),
            .markdown("**Ta‘teel (تَعطِيل)**: from **ع-ط-ل**, to leave empty or idle; to deny an attribute or strip it of meaning."),
            .markdown("**Takyeef (تَكيِيف)**: from **kayf**, how; to describe or ask after the manner of an attribute."),
            .markdown("**Tamtheel and tashbeeh (تَمثِيل، تَشبِيه)**: likening Allah’s attributes to those of His creation."),
            .markdown("**Tafweed (تَفوِيض)**: consigning. The Salaf consigned the how to Allah; the later claim that they consigned the meaning too, and read the texts as words without meaning, is not their way."),
            .markdown("**Ta’weel (تَأوِيل)**: in the Quran and the speech of the Salaf, the explanation of a text or the reality it points to. In the later schools, turning a word from its apparent meaning to another without proof, which in the attributes is tahreef."),
            .markdown("**Istiwaa’ (اِستِوَاء)**: from **س-و-ي**; istawa ‘ala means rose over and settled above. Allah says it of Himself and His Throne in seven places."),
            .markdown("**Uluw (عُلُوّ)**: being high and above. Allah is above His creation in His essence, His rank and His dominion."),
            .markdown("**Ma‘iyyah (مَعِيَّة)**: being with. Allah is with all creation by His knowledge and power, and with the believers by His help and support (Quran 16:128), while being above His Throne."),
            .ayah("16:128"),
            .markdown("**Tawqeefi (تَوقِيفِي)**: fixed by the texts. The names and attributes are taken from the Quran and the Sunnah alone."),
        ]),
    ]
}

import SwiftUI

/// "The Words of the Quran" (QURAN & TAFSIR, 2026-11-16): how many words the Quran has, how few
/// dictionary words carry most of it, and why understanding them matters. Its figures come from
/// Resources/Data/Quran/QuranVocabulary.json.xz (Scripts/build_quran_vocabulary.py); its door opens
/// the Quran Words study page in Arabic Alphabet.
struct QuranWordsPillarView: View {
    var body: some View {
        List {
            Group {
                ArticleLengthSection()

                Section(header: ArticleHeader("SUMMARY")) {
                    ArticleLead("In short: the Quran has 77,430 words, but they are built from only about 4,800 dictionary words, and a few hundred of those carry most of the text. Understanding what you recite is closer than it looks, and your recitation is rewarded the whole time you are learning.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("THE NUMBERS")) {
                        ArticleParagraph(articleMarkdown: "Count every word of the Quran in the Hafs mushaf and you reach 77,430. Most of them are the same words coming back in different forms. Take each one back to the form you would look up in a dictionary, its **lemma**, and the whole Quran comes down to about 4,800 dictionary words, which grow out of 1,642 **roots (جُذُور)**.")

                        ArticleStatGrid([
                            ArticleStat("77,430", "words in the Hafs mushaf"),
                            ArticleStat("About 4,800", "dictionary words (lemmas)"),
                            ArticleStat("1,642", "roots"),
                            ArticleStat("About 1,950", "dictionary words that occur only once"),
                        ])

                        ArticleParagraph(verbatim: "A dictionary word is not the same as a spelling. قَالَ (he said), قَالُوٓاْ (they said) and يَقُولُ (he says) are three written forms of one dictionary word. Counted by spelling, the Quran has about 19,500 different written forms with their vowel marks, or about 14,900 without them. That is why different lists give such different totals: they are counting different things.")
                    }

                    Section(header: ArticleHeader("A FEW WORDS CARRY MOST OF IT")) {
                        ArticleParagraph(verbatim: "The words of the Quran are not spread evenly. A small set comes back on almost every page, while the rest come and go. رَبّ (Lord) occurs 975 times in all its forms, and قَالَ (to say) 1,618 times. Counting the small pronoun words as words too, such as هُمۡ (they) and لَهُمۡ (for them), this is how much of the Quran the most common words make up:")

                        ArticleStatGrid([
                            ArticleStat("About 25%", "of all the words are the 10 most common"),
                            ArticleStat("About 58%", "are the 100 most common"),
                            ArticleStat("About 74%", "are the 300 most common"),
                            ArticleStat("About 81%", "are the 500 most common"),
                        ])

                        ArticleParagraph(verbatim: "Put plainly: know the 100 most common words well and more than half of every page you recite is already familiar. Know 500 and it is about four words in every five. At the other end, about 1,950 dictionary words occur only once in the whole Quran. They matter as much as any other word of Allah, but they are not where a learner begins.")

                        ArticleCallout("Knowing the words is the first step, not the last. Grammar ties them together, and the explanation of the scholars of tafseer tells you what an ayah means and how the Prophet (peace and blessings be upon him) and his Companions understood it. A word list never replaces a trusted tafseer; it turns the tafseer into an explanation of words you already recognise.", title: "Words, then meaning", systemImage: "text.book.closed")
                    }

                    Section(header: ArticleHeader("WHY UNDERSTANDING MATTERS")) {
                        ArticleParagraph(verbatim: "Allah tells us why He sent the Quran down in Arabic:")
                        ScriptureQuote(quran: "12:2")

                        ArticleParagraph(verbatim: "He says the same in Surah az-Zukhruf (Quran 43:3), and that the trustworthy Spirit brought it down “In a clear Arabic language” (Quran 26:195).")
                        ScriptureQuote(quran: "43:3")
                        ScriptureQuote(quran: "26:193-195")
                        ArticleParagraph(verbatim: "He sent it to be reflected upon, not only recited:")
                        ScriptureQuote(quran: "38:29")

                        ArticleParagraph(verbatim: "And He asks, of those who turn away from that reflection:")
                        ScriptureQuote(quran: "47:24")

                        ArticleParagraph(verbatim: "Four times in Surah al-Qamar the same ayah returns (Quran 54:17, 22, 32 and 40), a promise that the way in is open to everyone who tries:")
                        ScriptureQuote(quran: "54:17")

                        ArticleParagraph(verbatim: "The Prophet (peace and blessings be upon him) made learning the Quran and passing it on the mark of the best of this Ummah:")
                        ScriptureQuote(hadith: "bukhari:5027", cite: "Saheeh al-Bukhaari 5027", arabic: 36...40, english: 4...17)
                    }

                    Section(header: ArticleHeader("WHAT THE SCHOLARS SAID")) {
                        ArticleParagraph(articleMarkdown: "**Shaykh al-Islam Ibn Taymiyyah** (d. 728 AH) explained why learning Arabic is part of the religion itself, in a passage of Iqtidaa’ as-Siraat al-Mustaqeem:")
                        ScriptureQuote(text: "“The Arabic language itself is part of the religion, and knowing it is an obligation, because understanding the Book and the Sunnah is an obligation, and they cannot be understood except by understanding the Arabic language; and whatever an obligation cannot be fulfilled without is itself an obligation. Then some of it is obligatory on every individual, and some of it is obligatory on the community” (Ibn Taymiyyah, Iqtidaa’ as-Siraat al-Mustaqeem 1/527).", arabic: "فَإِنَّ نَفسَ اللُّغَةِ العَرَبِيَّةِ مِنَ الدِّينِ، وَمَعرِفَتَهَا فَرضٌ وَاجِبٌ، فَإِنَّ فَهمَ الكِتَابِ وَالسُّنَّةِ فَرضٌ، وَلَا يُفهَمُ إِلَّا بِفَهمِ اللُّغَةِ العَرَبِيَّةِ، وَمَا لَا يَتِمُّ الوَاجِبُ إِلَّا بِهِ فَهُوَ وَاجِبٌ. ثُمَّ مِنهَا مَا هُوَ وَاجِبٌ عَلَى الأَعيَانِ، وَمِنهَا مَا هُوَ وَاجِبٌ عَلَى الكِفَايَةِ", dimmed: true)

                        ArticleParagraph(articleMarkdown: "Notice the last sentence. The duty is real, but it is measured. Some of it falls on **every individual (fard ‘ayn)**: what your own worship needs, such as reciting al-Faatihah in the prayer. The Quran in the prayer is recited only in Arabic; Ibn Taymiyyah called that the view of the majority and the correct one beyond doubt (Iqtidaa’ as-Siraat al-Mustaqeem 1/518–519). The rest is a **communal obligation (fard kifaayah)**: the Ummah must always have people who know the language deeply enough to explain the Book and the Sunnah. Everything between the two is a virtue each Muslim takes as far as he can.")
                    }

                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**Is my recitation rewarded if I do not understand it?** Yes. The Prophet (peace and blessings be upon him) promised the reward for every letter recited, and did not make it depend on understanding:")
                        ScriptureQuote(hadith: "tirmidhi:2910", cite: "Jaami‘ at-Tirmidhi 2910; graded saheeh by al-Albaani", arabic: 40...62, english: 12...59)

                        ArticleParagraph(verbatim: "And the one for whom the recitation itself is hard is not left behind. He has a reward for reciting and a reward for the struggle:")
                        ScriptureQuote(hadith: "muslim:798a", cite: "Saheeh Muslim 798, Saheeh al-Bukhaari 4937", arabic: 42...57, english: 0...30)

                        ArticleParagraph(verbatim: "So never stop reciting while you learn. Reciting is worship from the first day; understanding adds reflection, and reflection is what the Quran was sent down for. The two grow together.")

                        ArticleParagraph(articleMarkdown: "**Do I have to learn Arabic to be a Muslim?** No. A person enters Islam by the testimony of faith, believed in the heart and said with the tongue, and most Muslims today are not Arabs. What every Muslim does need is the Arabic his worship depends on, above all al-Faatihah for the prayer. Beyond that, a trustworthy translation of the meanings and a tafseer in your own language teach you what the Quran says while your Arabic grows.")

                        ArticleParagraph(articleMarkdown: "**Where do I start?** With the words you already say every day: al-Faatihah, the short surahs you pray with, and the words of the prayer. Then the most common words of the Quran, in order, a few at a time. The steps below set it out.")

                        ArticleParagraph(articleMarkdown: "**Why do some lists say 77,429 words?** The Quranic Arabic Corpus counts that way because it joins or splits a handful of words differently from the mushaf: it writes بَعۡدَ مَا as one word in three places and joins إِلۡ يَاسِينَ at 37:130, while it splits لَّوۡمَا and مَالِيَ into two. The words of the Quran are the same; only the counting differs.")
                        ScriptureQuote(quran: "37:130", words: 2...3)
                    }
                }

                ArticleOnly(.short) {
                    Section(header: ArticleHeader("THE NUMBERS")) {
                        ArticleParagraph(articleMarkdown: "Count every word of the Quran in the Hafs mushaf and you reach 77,430. Most of them are the same words coming back in different forms. Take each one back to the form you would look up in a dictionary, its **lemma**, and the whole Quran comes down to about 4,800 dictionary words, which grow out of 1,642 **roots (جُذُور)**.")
                    }

                    Section(header: ArticleHeader("A FEW WORDS CARRY MOST OF IT")) {
                        ArticleParagraph(verbatim: "The words of the Quran are not spread evenly. A small set comes back on almost every page, while the rest come and go. Counting the small pronoun words as words too, this is how much of the Quran the most common words make up:")

                        ArticleStatGrid([
                            ArticleStat("About 25%", "of all the words are the 10 most common"),
                            ArticleStat("About 58%", "are the 100 most common"),
                            ArticleStat("About 74%", "are the 300 most common"),
                            ArticleStat("About 81%", "are the 500 most common"),
                        ])

                        ArticleParagraph(verbatim: "Put plainly: know the 100 most common words well and more than half of every page you recite is already familiar. Know 500 and it is about four words in every five.")
                    }

                    Section(header: ArticleHeader("WHY UNDERSTANDING MATTERS")) {
                        ArticleParagraph(verbatim: "Allah tells us why He sent the Quran down in Arabic:")
                        ScriptureQuote(quran: "12:2")

                        ArticleParagraph(verbatim: "He sent it to be reflected upon, not only recited:")
                        ScriptureQuote(quran: "38:29")

                        ArticleParagraph(verbatim: "And four times in Surah al-Qamar the same ayah returns, a promise that the way in is open to everyone who tries:")
                        ScriptureQuote(quran: "54:17")
                    }

                    Section(header: ArticleHeader("COMMON QUESTIONS")) {
                        ArticleParagraph(articleMarkdown: "**Is my recitation rewarded if I do not understand it?** Yes. The Prophet (peace and blessings be upon him) promised the reward for every letter recited, and did not make it depend on understanding:")
                        ScriptureQuote(hadith: "tirmidhi:2910", cite: "Jaami‘ at-Tirmidhi 2910; graded saheeh by al-Albaani", arabic: 40...62, english: 12...59)
                    }
                }

                Section(header: ArticleHeader("HOW TO START")) {
                    ArticleStep("1. **Start with what you already recite.** Learn the meaning of al-Faatihah word by word, then the short surahs you pray with. Every prayer becomes a revision lesson.")
                    ArticleStep("2. **Learn the most common words first**, a handful each day, and listen for them when you recite and when the imam recites aloud.")
                    ArticleStep("3. **Notice the roots.** قَالَ, قَالُوٓاْ and يَقُولُ share one root; once you know it, dozens of forms open at once.")
                    ArticleStep("4. **Read a trusted translation and tafseer beside the Arabic**, such as Tafseer as-Sa‘di or Tafseer Ibn Katheer. The words tell you what is said; tafseer tells you what it means.")
                    ArticleStep("5. **Keep reciting every day**, whatever you understand so far. The reward does not wait for your vocabulary.")

                    // The study page links back here, so the pair is a corridor; the row greys out when
                    // the page is already open. The page is the phone's.
                    #if os(iOS) && HAS_QURAN
                    OpenScreenLink(screen: .quranWords) {
                        QuranWordsView()
                    } label: {
                        TajweedLinkLabel(systemImage: "character.book.closed.fill", title: "Quran Words",
                                         caption: "The 500 most common words, a hundred at a time, with a test for each hundred")
                    }
                    #endif
                }

                Section(header: ArticleHeader("IN SUMMARY")) {
                    ArticleClosing("Allah sent the Quran down in clear Arabic so that it would be understood and reflected upon, and He made it easy to remember. Its 77,430 words rest on about 4,800 dictionary words, and the 500 most common of them make up about four words in five. Begin with the words you already pray with, keep reciting every day, and every word you learn brings the meaning a little closer.")
                }

                ArticleOnly(.long) {
                    Section(header: ArticleHeader("KEY TERMS")) {
                        ArticleTermCard("Kalimah", arabic: "كَلِمَة", meaning: "A word. In counting the Quran, each word as it is written in the mushaf, with its attached letters and pronouns: لَهُمۡ is one kalimah.")
                        ArticleTermCard("Lemma (dictionary word)", arabic: "المَدْخَل المُعْجَمِيّ", meaning: "The form of a word you look up in a dictionary. قَالَ, قَالُوٓاْ and يَقُولُ are three kalimat of one lemma. The Quran has about 4,800.")
                        ArticleTermCard("Jidhr (root)", arabic: "جِذْر", meaning: "The core letters, usually three, that a family of words is built on, such as ق و ل for saying. The Quran's words grow out of 1,642 roots.")
                        ArticleTermCard("Tadabbur", arabic: "تَدَبُّر", meaning: "Reflecting on the aayaat to understand them and act on them, the purpose Allah names in Quran 38:29 and 47:24.")
                    }
                }

                ArticleSourcesSection(article: "QuranWordsPillarView")
            }
            .themedListRowBackground()
        }
        .englishArticle().selectableArticleList(article: "QuranWordsPillarView")
        .navigationTitle("The Words of the Quran")
    }
}

// MARK: - Overviews of the numbered sets

// Abu, 2026-11-26: "For every section in pillars and beliefs and other places that is all consistent like five
// pillars of Islam and six pillars of iman and three pillars of tawheed add an overview introduction
// navigation link only if consistent". One page heads each group that is a single counted set (the five, the
// six, the three of tawhid, the three mosques): what the set is, where its count comes from, each member in a
// line with a door to its page, and how they hang together. A group of mixed pages (THE BASICS, the
// histories, the scholars) has no overview, since there is no one thing to introduce. Every quote here is one
// the member pages already carry, with the same ranges.

/// The overview that opens THE 5 PILLARS OF ISLAM.
struct FivePillarsOverviewView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "FivePillarsOverviewView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The 5 Pillars of Islam")
        .englishArticle().selectableArticleList(article: "FivePillarsOverviewView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: Islam is built on five pillars: the testimony that none is worshipped but Allah and that Muhammad is His Messenger, the prayer, the zakaah, the fast of Ramadan, and the pilgrimage to the House. They are the outward frame of the religion, owed by every Muslim who is able, and each has a page of its own after this one."),
        ]),
        ArticleSection("WHERE THE FIVE COME FROM", [
            .text("The Prophet (peace be upon him) described Islam as a building and named the five pillars it stands on:"),
            .hadith("bukhari:8", cite: "Saheeh al-Bukhaari 8, Saheeh Muslim 16", arabic: 33...53, english: [4...64]),
            .text("When Jibreel came in the form of a man and asked him what Islam is, he answered with the same five:"),
            .hadith("muslim:8a", cite: "Saheeh Muslim 8a", arabic: 232...255, english: [315...363]),
        ]),
        ArticleSection("THE FIVE, ONE BY ONE", [
            .step("1. **Shahaadah (شَهَادَة)**, the testimony of faith: that there is no god worthy of worship but Allah, and that Muhammad is His Messenger. It is the door into Islam, and no other deed is accepted without it."),
            .door(.article("ShahadahView")),
            .step("2. **Salaah (صَلَاة)**, the prayer: five times every day and night, each at its appointed time, facing the Ka‘bah."),
            .door(.article("SalahView")),
            .step("3. **Zakaah (زَكَاة)**, the obligatory charity: a set share of certain kinds of wealth once they reach a minimum (the nisaab), given to the eight kinds of people Allah named (Quran 9:60)."),
            .door(.article("ZakahView")),
            .step("4. **Sawm (صَوم)**, the fast of Ramadan: leaving food, drink and marital relations from dawn until sunset for the whole month, for the sake of Allah."),
            .door(.article("SawmView")),
            .step("5. **Hajj (حَجّ)**, the pilgrimage to the Ka‘bah in Makkah in the month of Dhul-Hijjah: once in a lifetime, for whoever is able to make the journey."),
            .door(.article("HajjView")),
        ]),
        ArticleSection("HOW THEY STAND TOGETHER", [
            .text("A building needs all of its pillars, but they do not carry the same weight. The testimony is the foundation: with it a person enters Islam, and without it nothing else is accepted. The prayer comes next, and the Prophet (peace be upon him) made it the line between a person and disbelief:"),
            .hadith("muslim:82a", cite: "Saheeh Muslim 82a", arabic: 34...41, english: [21...33]),
            .text("Zakaah and the fast are owed by everyone they fall on, and the pilgrimage once in a lifetime by whoever is able:"),
            .ayah("3:97", words: 9...24),
        ]),
        ArticleSection("THE FIVE AND THE REST OF THE RELIGION", [
            .text("The five are the pillars, not the whole building. In the same conversation Jibreel went on to ask about eemaan and ihsaan, and the Prophet (peace be upon him) answered each, then said that Jibreel had come to teach them their religion. The six pillars of eemaan are the beliefs the five rest on, and they are the next group in this index:"),
            .door(.article("SixPillarsOverviewView")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Islam stands on five: the testimony, the prayer, the zakaah, the fast of Ramadan and the pilgrimage. The testimony is the foundation, the prayer is the line between faith and disbelief, and the rest are owed by everyone able to carry them. Each pillar's conditions, rulings and virtues are on its own page."),
        ]),
    ]
}

/// The overview that opens THE 6 PILLARS OF IMAN (FAITH).
struct SixPillarsOverviewView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "SixPillarsOverviewView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The 6 Pillars of Eemaan")
        .englishArticle().selectableArticleList(article: "SixPillarsOverviewView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: eemaan, faith, rests on six pillars: belief in Allah, His angels, His books, His messengers, the Last Day, and the decree, its good and its bad. The Prophet (peace be upon him) named all six when Jibreel asked him what eemaan is, and the Quran names them as well. Each has a page of its own after this one."),
        ]),
        ArticleSection("WHERE THE SIX COME FROM", [
            .text("After asking about Islam, Jibreel asked the Prophet (peace be upon him) about eemaan, and the answer named the six:"),
            .hadith("muslim:8a", cite: "Saheeh Muslim 8a", arabic: 267...284, english: [399...442]),
            .text("The Quran names the first five together, and calls disbelief in them straying far:"),
            .ayah("4:136"),
            .text("And the sixth, the decree, in a single line:"),
            .ayah("54:49"),
            .text("Ibn Umar (may Allah be pleased with him) narrated the hadith of Jibreel when he was told of men who had begun to deny the decree, and before narrating it he said of them:"),
            .hadith("muslim:8a", cite: "Saheeh Muslim 8a", arabic: 132...162, english: [132...223]),
        ]),
        ArticleSection("THE SIX, ONE BY ONE", [
            .step("1. **Belief in Allah**: that He exists, that He alone is Lord, that He alone deserves worship, and that His names and attributes are as He described them. These are the three pillars of tawheed, the group after this one."),
            .door(.article("GodView")),
            .step("2. **Belief in the angels**: that they are a creation of Allah who never disobey Him and do what they are commanded (Quran 66:6), and in the ones He named, such as Jibreel, who brought the revelation."),
            .door(.article("AngelsView")),
            .step("3. **Belief in the books**: that Allah revealed books to His messengers, among them the Tawraah, the Zaboor, the Injeel and the Quran, and that the Quran is the last of them and the judge over what came before it (Quran 5:48)."),
            .door(.article("BooksView")),
            .step("4. **Belief in the messengers**: that Allah sent a messenger to every nation, calling them to worship Him alone (Quran 16:36), and that Muhammad (peace be upon him) is the seal of the prophets (Quran 33:40)."),
            .door(.article("ProphetsView")),
            .step("5. **Belief in the Last Day**: in the death that comes to every soul, the life of the grave, the resurrection, the reckoning and the scale, and Paradise and the Fire."),
            .door(.article("DayView")),
            .step("6. **Belief in al-Qadar**, the decree: that Allah knows all things, wrote them, willed them and created them, so that nothing happens in His dominion except by His decree, while the servant still chooses and answers for his choice."),
            .door(.article("QadarView")),
        ]),
        ArticleSection("WHAT EEMAAN IS", [
            .text("Eemaan, for Ahl as-Sunnah, is belief in the heart, words on the tongue and deeds of the limbs, and it rises and falls: it increases with obedience and decreases with sin. Allah says of the believers:"),
            .ayah("8:2"),
            .text("And the Prophet (peace be upon him) counted its branches:"),
            .hadith("bukhari:9", cite: "Saheeh al-Bukhaari 9", arabic: 40...47, english: [4...45]),
        ]),
        ArticleSection("THE SIX AND THE FIVE", [
            .text("The six pillars of eemaan are what a Muslim believes, and the five pillars of Islam are what he does. Said apart, each word takes in the other; said together, as Jibreel asked them, Islam is the outward deeds and eemaan the inward belief. Above both is ihsaan: to worship Allah as though you see Him. The five have their own overview:"),
            .door(.article("FivePillarsOverviewView")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Eemaan rests on six: Allah, His angels, His books, His messengers, the Last Day, and the decree, its good and its bad. The Prophet (peace be upon him) named them when Jibreel asked him, and the Quran names them as well. Eemaan is belief, word and deed, and it grows with obedience and wanes with sin."),
        ]),
    ]
}

/// The overview that opens THE 3 PILLARS OF TAWHID.
struct ThreePillarsOverviewView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "ThreePillarsOverviewView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The 3 Pillars of Tawheed")
        .englishArticle().selectableArticleList(article: "ThreePillarsOverviewView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: tawheed, singling Allah out, stands on three pillars. Tawheed ar-ruboobiyyah: Allah alone creates, owns and governs. Tawheed al-uloohiyyah: Allah alone is worshipped. Tawheed al-asmaa’ was-sifaat: Allah is described only as He described Himself and as His Messenger described Him, with nothing like Him. A person needs all three, and the second is the one every messenger was sent to call to."),
        ]),
        ArticleSection("THE THREE, ONE BY ONE", [
            .step("1. **Tawheed ar-Ruboobiyyah (تَوحِيد الرُّبُوبِيَّة)**, His Lordship: to single Allah out in His actions. He alone creates, owns and governs all that exists:"),
            .ayah("7:54", words: 24...31),
            .door(.article("RububiyyahView")),
            .step("2. **Tawheed al-Uloohiyyah (تَوحِيد الأُلُوهِيَّة)**, His right to worship: to single Allah out with the servant's actions, so that every act of worship, the prayer, supplication, sacrifice, vows, reliance, fear and hope, is for Him alone. It is the meaning of la ilaaha illallah:"),
            .ayah("21:25"),
            .door(.article("UluhiyyahView")),
            .step("3. **Tawheed al-Asmaa’ was-Sifaat (تَوحِيد الأَسمَاء وَالصِّفَات)**, His names and attributes: to affirm every name and attribute Allah affirmed for Himself or His Messenger affirmed for Him, without twisting their meaning, denying them, asking how they are, or likening them to the creation:"),
            .ayah("42:11", words: 13...18),
            .door(.article("AsmaSifatView")),
        ]),
        ArticleSection("ONE AYAH HOLDS ALL THREE", [
            .text("The three were not revealed as a list. They name what the Quran itself contains, gathered from its verses, the way “the five pillars” names what a hadith contains. One ayah carries all three at once:"),
            .ayah("19:65"),
            .text("“Lord of the heavens and the earth” is ruboobiyyah; “so worship Him” is uloohiyyah; “Do you know of any similarity to Him?” is the names and attributes. Surat al-Faatihah opens the same way: “Lord of the worlds” is the first, “It is You we worship” is the second, and “the Entirely Merciful, the Especially Merciful” is the third."),
        ]),
        ArticleSection("WHY THE FIRST IS NOT ENOUGH", [
            .text("The idolaters of Makkah affirmed the first pillar. Asked who created them, they answered “Allah,” and still worshipped others beside Him, so Allah called them people who associate partners with Him:"),
            .ayah("43:87"),
            .ayah("12:106"),
            .text("So a person who affirms the Creator but calls on another, sacrifices to another or makes vows to another has not yet come to tawheed. The first pillar is the proof of the second: the One who alone creates and provides is the only One who deserves to be worshipped. Tawheed as a whole, the word la ilaaha illallah, its conditions and what breaks it, has its own page:"),
            .door(.article("TawhidView")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Tawheed has three pillars: Allah alone is Lord, Allah alone is worshipped, and Allah alone has the names and attributes He gave Himself, with nothing like Him. The scholars gathered them from the Quran, one ayah holds all three, and the idolaters who stopped at the first show why all three are needed."),
        ]),
    ]
}

/// The overview that opens THE THREE HOLY MOSQUES.
struct HolyMosquesOverviewView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "HolyMosquesOverviewView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Three Holy Mosques")
        .englishArticle().selectableArticleList(article: "HolyMosquesOverviewView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: three mosques stand above all others: Masjid al-Haraam in Makkah, the Prophet's Mosque in Madinah, and Masjid al-Aqsa in Jerusalem. They are the only mosques the Prophet (peace be upon him) allowed a journey to be made to for their own sake, and a prayer in the first two is worth many times a prayer anywhere else. Each has a page of its own after this one."),
        ]),
        ArticleSection("WHY THESE THREE", [
            .text("The Prophet (peace be upon him) named the three and set them apart from every other place of worship:"),
            .hadith("bukhari:1189", cite: "Saheeh al-Bukhaari 1189, Saheeh Muslim 1397", arabic: 25...41, english: [4...30]),
            .text("So no other place is a destination of worship in itself. The first and the third were also the first two mosques built on earth, forty years apart:"),
            .hadith("bukhari:3366", cite: "Saheeh al-Bukhaari 3366, Saheeh Muslim 520", arabic: 28...55, english: [6...52]),
        ]),
        ArticleSection("THE THREE, ONE BY ONE", [
            .step("1. **Masjid al-Haraam (المَسجِد الحَرَام)**, the Sacred Mosque in Makkah, around the Ka‘bah: the first house of worship set up for mankind, the Qiblah every Muslim faces, and the place of Hajj and Umrah."),
            .ayah("3:96"),
            .door(.article("HaramView")),
            .step("2. **Masjid an-Nabawi (المَسجِد النَّبَوِي)**, the Prophet's Mosque in Madinah: built by the Prophet (peace be upon him) himself after the Hijrah, beside the room where he is buried."),
            .door(.article("NabawiView")),
            .step("3. **Masjid al-Aqsa (المَسجِد الأَقصَى)**, the Farthest Mosque in Jerusalem: the first Qiblah, in the land Allah blessed around it, and the place the Prophet (peace be upon him) was taken to by night."),
            .ayah("17:1"),
            .door(.article("AqsaView")),
        ]),
        ArticleSection("THE PRAYER IN THEM", [
            .text("A prayer in the Prophet's Mosque is better than a thousand elsewhere, and a prayer in Masjid al-Haraam better than a hundred thousand:"),
            .hadith("ibnmajah:1406", cite: "Sunan Ibn Maajah 1406; graded saheeh by al-Albaani", arabic: 32...54, english: [0...30]),
            .text("The figure often repeated for Masjid al-Aqsa, fifty thousand, comes from a report with a weak chain (Sunan Ibn Maajah 1413), so it is not relied on; its page explains why."),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("The three holy mosques are Masjid al-Haraam, the Prophet's Mosque and Masjid al-Aqsa: the only mosques a journey is made to for their own sake. Masjid al-Haraam and Masjid al-Aqsa were the first two mosques built on earth, and a prayer in Masjid al-Haraam and the Prophet's Mosque is worth a hundred thousand and a thousand prayers elsewhere."),
        ]),
    ]
}
