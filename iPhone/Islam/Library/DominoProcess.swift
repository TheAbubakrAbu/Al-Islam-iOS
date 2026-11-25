import SwiftUI

// The Domino Process: Abu's dawah workshop series (Dawah/Handbook) as reading chapters.
// Written 2026-11-24 (Abu: "Add these new Islamic resources"), Sunni upon the way of the Salaf, and held
// to the app's rules: every ayah a `.ayah(` reference into the bundled Quran, every hadith a `.hadith(`
// reference into the bundled shelf graded sahih or hasan, scholars' words quoted only with their source.
// The chapters are catalog articles (`IslamArticleCatalog`, home `.domino`), drawn by
// IslamLibraryView, so search, the Ask AI corpus and each page's own search reach them.

// MARK: - domino-1

struct DominoIntroView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "DominoIntroView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Domino Process")
        .englishArticle().selectableArticleList(article: "DominoIntroView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: the Domino Process is a way of reasoning from the plain fact that something exists to the testimony that there is no god but Allah and that Muhammad is His Messenger, one step at a time and without assuming Islam at the start. Seven claims stand in a row like dominoes, and each falls only when the one before it has fallen. The method is taken from two ayat of Surah Al ‘Imran: look, think, conclude, submit. This chapter sets out the seven dominoes, the rules of honest argument the whole series keeps, and what each of its three parts is for."),
        ]),
        ArticleSection("WHY ARE YOU MUSLIM?", [
            .text("Begin with a question, and answer it honestly, even if only to yourself: why are you Muslim? Asked without warning, most people give one of a handful of answers. My parents are Muslim. The community is where I belong. It feels right. Allah answered a du‘a of mine once, or I saw a dream."),
            .longOnly(.text("None of these is worthless. A community that is kind, generous and there for its people is what one would expect if Islam were true, and an answered prayer can be real. But a Christian child has a Christian family, and a Hindu child grows up in a Hindu community that feels just as much like home. If the reasons are the same on every side, they cannot be the reason one side is right. The question this series asks is whether a Muslim is Muslim by habit or by conviction.")),
            .shortOnly(.text("The question this series asks is whether a Muslim is Muslim by habit or by conviction.")),
            .text("It is not an idle question. The Prophet Muhammad (peace and blessings be upon him) described what every person will be asked in the grave, and how two kinds of people will answer:"),
            .hadith("bukhari:86", cite: "Sahih al-Bukhari 86", arabic: 96...153, english: [151...262]),
            .longOnly(.markdown("The one who passes is **al-muqin (المُوقِن)**, the one with certainty, and he names what he followed: a Messenger who came with **clear evidences (البَيِّنَات)** and guidance. The one who fails is **al-murtab (المُرتَاب)**, the doubter, and his answer is the answer of inherited religion: he heard people say something, so he said it. The point is not that whoever holds his faith by upbringing is a hypocrite. It is that belief with no reasons behind it is fragile, and every Muslim should be able to give the first answer.")),
            .shortOnly(.text("The point is not that whoever holds his faith by upbringing is a hypocrite. It is that belief with no reasons behind it is fragile, and every Muslim should be able to give the first answer.")),
            .longOnly(.text("Dawah begins at the centre and moves outward: first to oneself, then to other Muslims, then to everyone. How can a Muslim convince anyone else when he cannot say why he is convinced himself? The Quran rebuked people who commanded righteousness while forgetting themselves, and it ended the rebuke with a question this series will keep hearing:")),
            .longOnly(.ayah("2:44", words: 9...10)),
            .longOnly(.text("The ayah was addressed to the scholars of Bani Isra’il, but its principle reaches every caller. A Muslim friend who comes one night and asks, honestly, how anyone knows any of this is true deserves better than a shrug.")),
        ]),
        ArticleSection("WHOSE EXPERIENCE WINS?", [
            .longOnly(.text("Before asking how Islam is shown to be true, it helps to look at how others defend their own faith, because a sensible person learns from his own mistakes and a wise one learns from everyone’s. ‘Abdullah ibn Mas‘ud (may Allah be pleased with him) put it in one line:")),
            .longOnly(.hadith("muslim:2645", cite: "Sahih Muslim 2645", arabic: 37...40, english: [14...27])),
            .text("Ask the average Christian why he is Christian and you will usually hear a story rather than an argument: Jesus came to him in a dream when his life had fallen apart, or he prayed in a storm and was saved. (There are Christian philosophers who make careful arguments, and Part 3 takes them seriously.) A Hindu will say that Krishna protected his family, a Buddhist that meditation showed him the truth, and people of every faith report dreams. A Muslim says that he made du‘a and Allah answered him."),
            .text("Set these side by side and a pattern appears. Every religion reports answered prayers. Every religion has prayers that went unanswered, and an explanation for them. Every religion has its dreams, and billions of people in every religion have never had such a dream at all. When every row of the table carries the same marks, the marks cannot pick the winner."),
            .longOnly(.text("Islam has its own explanation for the unanswered prayer, and a Muslim believes it. The Prophet (peace be upon him) said:")),
            .longOnly(.hadith("tirmidhi:3573", cite: "Jami` at-Tirmidhi 3573; graded hasan sahih by al-Albani", arabic: 36...59, english: [0...51])),
            .longOnly(.text("But every religion explains its unanswered prayers too, so the explanation cannot be the tiebreaker. The Quran itself says that being rescued proves nothing about one’s religion. It describes idol worshippers who called on Allah alone when the sea rose against them, were saved, and went back to their idols on reaching land:")),
            .longOnly(.ayah("29:65")),
            .longOnly(.text("Dreams are no different. The Prophet (peace be upon him) taught that they come in three kinds, and only one of them is from Allah:")),
            .longOnly(.hadith("muslim:2263", cite: "Sahih Muslim 2263", arabic: 49...64, english: [46...83])),
            .markdown("So the series draws a line between two kinds of evidence. **Private evidence** is what only its owner can see: the answered du‘a, the dream, the peace felt in prayer. It can be real, and it can strengthen iman, but it cannot settle a disagreement between two people who each have their own. **Publicly examinable evidence** is what anyone can check, whoever they are: logic, history, the universe itself, the text of a revelation, and whether a message contradicts itself. The whole series runs on the second kind. The Quran names the weakness of the first when it is all a person has:"),
            .ayah("10:36", words: 5...11),
        ]),
        ArticleSection("THE QURAN ASKS FOR PROOF", [
            .text("Asking for evidence is not an idea imported into Islam from outside. When people claimed that only their own group would enter Paradise, the Quran did not answer them with a feeling. It answered with a demand:"),
            .ayah("2:111", words: 12...17),
            .longOnly(.markdown("It puts the same demand to those who took other gods besides Allah (21:24). It asks **afala ta‘qilun (أَفَلَا تَعقِلُونَ)**, will you not reason, thirteen times. The root **ع-ق-ل**, from which the word for reason comes, occurs forty-nine times in the Quran, and every time as a verb: the noun ‘aql itself never appears. In the Quran, reasoning is something a person does.")),
            .longOnly(.ayah("21:24")),
            .text("And it condemns the opposite, holding a religion because one’s fathers held it:"),
            .ayah("2:170"),
            .shortOnly(.text("The Quran does not accept “my parents did it” as a reason, and neither does this series.")),
            .longOnly(.text("Every messenger met that answer. The Quran says it was the reply of the comfortable in every town a warner came to, and it records the question each warner asked in return:")),
            .longOnly(.ayah("43:23-24", words: 22...29)),
            .longOnly(.text("Inheritance is how most people receive their religion. The Prophet (peace be upon him) said that every child is born upon the fitrah, and then his parents make him a Jew, a Christian or a Magian (Sahih al-Bukhari 1385). The Quran does not accept “my parents did it” as a reason, and neither does this series.")),
            .longOnly(.hadith("bukhari:1385", cite: "Sahih al-Bukhari 1385", arabic: 31...49, english: [0...44])),
        ]),
        ArticleSection("LOOK, THINK, CONCLUDE, SUBMIT", [
            .text("The Domino Process takes its method from two ayat near the end of Surah Al ‘Imran, which describe the people of understanding:"),
            .ayah("3:190-191"),
            .step("1. **Observation.** They look at the creation of the heavens and the earth and the turning of night into day."),
            .step("2. **Reflection.** They give thought to what they have seen. The word is yatafakkarun, from the root of tafakkur, sustained thought."),
            .step("3. **Conclusion.** They reach a verdict: this was not created aimlessly. A made world has a purpose because it has a Maker."),
            .step("4. **Submission.** Only then do they glorify their Lord and ask Him for protection from the Fire. Their thinking ends in worship."),
            .text("Like dominoes: set each one up carefully, push the first, and each knocks down the next. The series starts from reality itself and assumes nothing about Islam until the evidence arrives there."),
            .longOnly(.text("Some worry that asking for proof is a sign of weak faith. The Quran answers with Ibrahim (peace be upon him), who asked his Lord to show him how He gives life to the dead:")),
            .longOnly(.ayah("2:260", words: 8...15)),
            .longOnly(.text("He was not doubting. He already believed, and he asked for the certainty of seeing to be added to the certainty of faith, so that his heart might be at rest. That is the aim of the dominoes too: yaqin, a heart that has looked at the evidence and is at peace with what it found.")),
            .longOnly(.callout("The dominoes are not a claim that a person must first doubt, or that reasoned proof is the first duty before faith, as some of the later theologians held. Every child is born upon the fitrah, and the Prophet (peace be upon him) told Mu‘adh (may Allah be pleased with him) to call the people of Yemen first of all to the worship of Allah (Sahih al-Bukhari 1458). The dominoes set out step by step what a sound fitrah already knows, for the one whose fitrah has been clouded, and for the believer who wants his heart at rest.", title: "A Note on Method", icon: "info.circle.fill")),
            .longOnly(.hadith("bukhari:1458", cite: "Sahih al-Bukhari 1458", arabic: 53...102, english: [0...110])),
        ]),
        ArticleSection("THE SEVEN DOMINOES", [
            .text("Seven claims carry the series. Each is argued on its own evidence, and each stands only if the one before it stands. Nobody is asked to assume Islam at the start."),
            .chain([
                ArticleChainLink("Domino 1: Reality", "Things exist that did not have to exist. Everything we observe depends on something else."),
                ArticleChainLink("Domino 2: A necessary source", "A chain of dependent things cannot explain itself, so something exists that depends on nothing."),
                ArticleChainLink("Domino 3: An intelligent Creator", "That source chose this universe over countless possible ones, so it has will and knowledge. Chance is not a cause."),
                ArticleChainLink("Domino 4: One Creator", "Two ultimate beings would either limit each other or be indistinguishable."),
                ArticleChainLink("Domino 5: Revelation", "A Creator with a purpose may be expected to speak, and claims that He has spoken exist, so they can be tested."),
                ArticleChainLink("Domino 6: Which revelation?", "Every claim is held to the same tests: its theology, its coherence, its preservation, its messenger, its reach."),
                ArticleChainLink("Domino 7: Islam", "Worship the One and follow His final Messenger: لَا إِلَهَ إِلَّا اللَّهُ مُحَمَّدٌ رَسُولُ اللَّهِ"),
            ], caption: "The seven dominoes: each falls only when the one before it has fallen"),
            .text("The first four dominoes are reached by observation and reason alone. Where the Quran is quoted along the way, it is quoted to show that it made the same argument first, not as an authority, because its authority is exactly what has not yet been shown. At the fifth and sixth dominoes the Quran is one of the claimants under examination. Only at the seventh does it speak as the word of Allah."),
            .longOnly(.text("Laid out this way, the dominoes also show where each of the world’s great answers stops:")),
            .longOnly(.bullet("**Atheism and naturalism** stop before the second domino: they deny a necessary source beyond the physical world.")),
            .longOnly(.bullet("**Most schools of Buddhism, and Jainism**, which place no Creator at the centre, stop at the same point.")),
            .longOnly(.bullet("**Polytheism** stops at the fourth: one Creator, alone.")),
            .longOnly(.bullet("**Deism** accepts one Creator but says He never spoke, so it stops at the fifth.")),
            .longOnly(.bullet("**Hindu traditions, Judaism and Christianity** hold that God has spoken in some way, so their claims are tested at the sixth.")),
            .longOnly(.text("One line runs all the way through. That is a claim, and it is put down at the start so that the reader can hold the series to it. Agnosticism is not on the chart at all, because “I don’t know” is not an answer to the question. It is a waiting room, and the series is an invitation to walk out of it.")),
        ]),
        ArticleSection("HOW WE ARGUE", [
            .text("A method meant for dawah has to survive a well-read opponent, so the series binds itself to six rules."),
            .longOnly(.step("1. **Accuracy before rhetoric.** If an argument only works when the other side is misrepresented, it is dropped.")),
            .longOnly(.step("2. **Steelman first.** Every view is described the way its own followers would describe it, and only then answered.")),
            .longOnly(.step("3. **Public evidence, not private experience.** Dreams and answered du‘a can strengthen iman, but they cannot settle a disagreement between two people.")),
            .longOnly(.step("4. **Best explanation, not impossible certainty.** Almost nothing outside mathematics is proven the way mathematics is: not that yesterday happened, not that other people have minds. Science, history and the courts ask which explanation best fits the evidence, and a jury convicts beyond reasonable doubt, not beyond every imaginable doubt. Settled conviction, yaqin, comes from the whole chain pointing one way, not from any single argument.")),
            .longOnly(.step("5. **Elimination plus positive evidence.** Islam is not true by default because others fall short. It brings its own case, and the series sets it out.")),
            .longOnly(.step("6. **Adab always.** Wisdom, good instruction and the best manner of argument, as Allah commanded, with the knowledge that guidance is His alone:")),
            .longOnly(.ayah("16:125", words: 0...10)),
            .longOnly(.ayah("28:56")),
            .longOnly(.text("Three working rules follow from these. No circular arguments: “the Quran is from God because the Quran says so” persuades only those already persuaded, exactly as “the Bible is true because the Bible says so” does. No jumping ahead: each domino is argued only once the one before it has fallen. And no claim larger than its evidence. For that reason the series leaves out some popular arguments: numerical patterns and word counts in the Quran, which depend on how one counts; the claim that DNA is a code and every code needs a writer, which opens a debate about evolution that the case does not need; and readings of the Quran that work only with a stretched translation. When a caller is honest about the limits, people trust the rest.")),
            .shortOnly(.text("Accuracy before rhetoric. Every view stated as its own followers would state it, and only then answered. Public evidence, not private experience. The best explanation, not impossible certainty: the standard of science, history and the courts. Elimination plus positive evidence, because Islam is not true by default when others fall short. And adab always, with the knowledge that guidance is Allah’s alone. Three working rules follow: no circular arguments, no jumping ahead, and no claim larger than its evidence.")),
        ]),
        ArticleSection("THREE PARTS, THREE JOBS", [
            .text("The dominoes fall in three parts. Each has one question, one job, and a question it leaves hanging for the next."),
            .markdown("**Part 1: Does God Exist?** Dominoes 1 to 4, from reality to one intelligent Creator. Its job is to make the reader think. It examines atheism and naturalism, agnosticism and deism, and ends on the question the deist cannot answer: did God speak?"),
            .door(.article("DominoRealityView")),
            .door(.article("DominoCreatorView")),
            .door(.article("DominoOneView")),
            .door(.article("DominoWorldviewsView")),
            .markdown("**Part 2: Which Religion Is True?** Dominoes 5 and 6, from a Creator to revelation. Its job is to teach the reader to investigate: it asks whether a Creator with a purpose would speak, builds a checklist for testing any claimed revelation, runs the world’s traditions through it fairly, and sets out Islam’s own case. It ends on the question it saved for last: but what about Christianity?"),
            .door(.article("DominoRevelationView")),
            .door(.article("DominoTestView")),
            .markdown("**Part 3: Why Islam?** The sixth domino for Christianity, then the seventh. Its job is to teach dawah: it describes Christianity as Christians do, tests it by the same standard, and then holds Islam to the very bar Christianity faced. It ends at the testimony of faith."),
            .door(.article("DominoChristianityView")),
            .door(.article("DominoIslamView")),
            .door(.article("DominoDawahView")),
            .longOnly(.text("Each part also closes with evidence for Islam itself, because Islam does not win by elimination: in Part 1, what the Quran says of the natural world, claimed modestly; in Part 2, prophecies recorded before they came true; in Part 3, a preserved Quran with no contradictions, and its challenge.")),
        ]),
        ArticleSection("HOW TO READ THESE CHAPTERS", only: .long, [
            .text("Read them in order the first time, because each domino leans on the ones before it. Each chapter states the argument, shows where the Quran made it first, gives the strongest objections in their strongest form, and answers them. Then practise. Each part has an exercise: in Part 1, walking a friendly sceptic from existence to one Creator in three minutes; in Part 2, running a belief system through the checklist; in Part 3, answering a Christian’s strongest verse with care. An argument a person can only read is not yet his own."),
            .text("And then teach, gently, with the goal Allah gave His Messenger:"),
            .ayah("12:108", words: 0...10),
            .markdown("**‘Ala basirah**: with insight and clear evidence, not because my parents said so. The dominoes are a means to that, never a replacement for the Quran, the Sunnah, du‘a and good character."),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .longOnly(.markdown("**Doesn’t reasoning about God put reason above revelation?**")),
            .longOnly(.text("No. Sound reason and authentic revelation never contradict each other, and Ibn Taymiyyah (may Allah have mercy on him) wrote a long work, Dar’ Ta‘arud al-‘Aql wan-Naql, to show it. The Quran itself argues: it asks where creation came from (52:35-36), why the heavens are not in ruin (21:22), and why people will not reason. Reason is the witness that brings a person to the door of revelation. Once he has seen that the message is true, he follows it, including in what reason could never have reached alone, such as the unseen and the details of worship.")),
            .longOnly(.ayah("52:35-36")),
            .longOnly(.ayah("21:22")),
            .longOnly(.markdown("**Why not begin with the Quran?**")),
            .longOnly(.text("Because a person who doubts that the Quran is from Allah will not accept an argument whose only premise is that it is. The Quran is where the series arrives, and it is brought in as evidence once its source has been shown. Even then the Quran argues from what its hearers already knew: it confronted the Makkans with their own admission that Allah created them (43:87).")),
            .longOnly(.ayah("43:87")),
            .markdown("**Must every Muslim go through all seven dominoes?**"),
            .text("No. Most Muslims hold the truth by their fitrah and by what reached them of the Quran and the Sunnah, and that is faith. The dominoes are for strengthening it, for answering a doubt when one comes, and for inviting others. They are a tool, not a condition of Islam."),
            .longOnly(.markdown("**Isn’t “beyond reasonable doubt” weaker than certainty?**")),
            .longOnly(.text("It is the standard for an argument, and the standard by which we hold almost everything we know. The doubt it leaves is the merely imaginable kind that attaches even to yesterday and to other minds. When independent lines of evidence all point the same way, the result in the heart is yaqin, and the Quran presents its own arguments as meant to produce it (52:36).")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("The Domino Process asks a Muslim to know why he is Muslim, and gives him a way to show it to others. It starts from what everyone can see, sets aside private experience as evidence for anyone else, refuses circular arguments, and moves one domino at a time: reality, a necessary source, an intelligent Creator, one Creator, revelation, which revelation, and Islam. It follows the order of 3:190-191, from looking to thinking to concluding to worship, and it keeps the manners the Quran commands: accuracy, fairness to the other side, modest claims, and the knowledge that guidance belongs to Allah alone."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Basirah", arabic: "بَصِيرَة", meaning: "**Insight**: clear sight of the heart, grounded in evidence. The Prophet’s way is to call to Allah **‘ala basirah**, upon insight, he and those who follow him (12:108)."),
            .term("Yaqin", arabic: "يَقِين", meaning: "**Settled certainty** that leaves no room for doubt. The Quran faults those who deny the Creator because they are not certain (52:36), and praises the believers who are certain of the Hereafter (2:4)."),
            .ayah("2:4"),
            .term("‘Aql", arabic: "عَقل", meaning: "**Reason**, from a root meaning to bind, as a hobble binds a camel: the faculty that holds a person back from what harms him. In the Quran the root appears only as a verb, forty-nine times."),
            .term("Tafakkur", arabic: "تَفَكُّر", meaning: "**Sustained reflection** on what one has seen. It is the second step of 3:190-191, between looking at creation and concluding that it was not made aimlessly."),
            .term("Zann", arabic: "ظَنّ", meaning: "**Assumption** or conjecture. The Quran says that assumption avails nothing against the truth (10:36), which is why the series rests on publicly examinable evidence."),
        ]),
    ]
}

struct DominoRealityView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "DominoRealityView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Dominoes 1 and 2: Something Exists, Something Is Necessary")
        .englishArticle().selectableArticleList(article: "DominoRealityView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: the first two dominoes begin with what nobody denies, that something exists, and ask what kind of thing it is. Everything we meet depends on something else and could have failed to exist. A chain of such dependent things, however long, even endless, never explains why there is anything at all, so something must exist that depends on nothing and on which everything else depends. The Quran gives the argument as a single question (52:35-36) and names both of its sides in one verse: you are the ones in need of Allah, and Allah is the Free of need (35:15)."),
        ]),
        ArticleSection("HOW DO WE KNOW ANYTHING?", [
            .longOnly(.text("Before arguing for anything, it helps to agree on how anyone knows anything at all. There are three basic ways, and everyone already relies on all of them. The senses: I see this wall. Reason: two and two make four, and nothing can exist and not exist at the same time in the same respect. And reliable testimony: most people have never been to Japan, yet nobody doubts that it exists.")),
            .longOnly(.text("The Quran names the same tools of knowledge, and then holds people responsible for how they use them:")),
            .longOnly(.ayah("16:78")),
            .longOnly(.ayah("17:36")),
            .longOnly(.text("Can the senses be wrong? Sometimes. Nearly a thousand years ago al-Ghazali (may Allah have mercy on him), describing his own search for certainty, pointed out that a star looks no bigger than a coin, and that a shadow looks as if it is standing still though it is always moving. But notice how we learned that they mislead: by reason and by more careful observation. The senses are checked, not thrown away.")),
            .shortOnly(.text("Everyone already knows things in three ways: by the senses, by reason, and by reliable testimony.")),
            .text("From these tools come three principles that everyone uses every day, long before anyone mentions God:"),
            .step("1. **Something cannot come from absolutely nothing.** Not a sound, not a car, not a universe."),
            .step("2. **Whatever does not have to exist needs an explanation for why it does.** A phone on a table is not simply there; something put it there."),
            .step("3. **Prefer the explanation that accounts for the most evidence with the fewest unsupported assumptions.** It is how a detective works and how a doctor diagnoses."),
            .longOnly(.text("A sceptic may reject one of these once the subject turns to God. It is fair to ask him to apply that rejection consistently. If a car appeared in his driveway overnight, would “there is no explanation” satisfy him? The arguments that follow apply the rules of the driveway to the biggest question there is: why is there something rather than nothing?")),
        ]),
        ArticleSection("NAME ONE THING THAT HAD TO EXIST", [
            .text("Look around any room and try to name one thing that exists by its own nature, something that simply could not have failed to exist. A person depends on parents, food and air. A chair depends on its wood and on whoever made it. The building, the earth and the sun all depend on materials, conditions and earlier causes. Every single thing we can name depends on something else."),
            .markdown("Philosophers call such a thing **contingent**: it exists, but it could have been otherwise or not been at all, and it does not explain its own existence. It borrows its existence from something else. The opposite is **necessary**: something that depends on nothing and cannot fail to exist. Muslim philosophers and theologians wrote the same pair as **mumkin al-wujud (مُمكِن الوُجُود)**, that whose existence is merely possible, and **wajib al-wujud (وَاجِب الوُجُود)**, that whose existence is necessary. This is the first domino: reality does not explain itself."),
            .longOnly(.text("Ibrahim (peace be upon him) used an argument of this shape with a people who worshipped the heavenly bodies. Each one he pointed to rose, and then set:")),
            .longOnly(.ayah("6:76-79")),
            .longOnly(.text("Ibn Kathir (may Allah have mercy on him) notes that the commentators differed over whether Ibrahim was reasoning his own way to the truth here or debating his people, and he settles it:")),
            .longOnly(.quote(text: "“The truth is that Ibrahim (peace be upon him), in this passage, was debating his people, showing them the falsehood of their worship of the heavenly bodies and the idols.” (Ibn Kathir, Tafsir al-Quran al-‘Azim, under 6:76-79).", arabic: "وَالحَقُّ أَنَّ إِبرَاهِيمَ عَلَيهِ الصَّلَاةُ وَالسَّلَامُ كَانَ فِي هَذَا المَقَامِ مُنَاظِرًا لِقَومِهِ، مُبَيِّنًا لَهُم بُطلَانَ مَا كَانُوا عَلَيهِ مِن عِبَادَةِ الهَيَاكِلِ وَالأَصنَامِ", dimmed: true)),
            .longOnly(.text("He adds that the star Ibrahim pointed to is subjected, held to a measured course from which it never turns aside, with no control over itself. That is a dependent thing, and a dependent thing cannot be the Lord. Ibn Taymiyyah (may Allah have mercy on him) observed that Ibrahim did not reject the star while it was moving across the sky, but when it set: what comes and goes, governed by something else, is not the One to whom a person turns his face.")),
        ]),
        ArticleSection("THE ARGUMENT IN FOUR LINES", [
            .text("The second domino turns the observation into an argument. It is the cosmological argument in its contingency form, and it does not depend on the Big Bang."),
            .step("1. Some things exist that could have not existed. You are one of them."),
            .step("2. A contingent thing does not explain its own existence. It depends on something else."),
            .step("3. A chain of dependent things, even an endless one, never explains why there is anything at all. Every link is borrowing."),
            .step("4. So something must exist necessarily: it depends on nothing, and everything else depends on it."),
            .text("Lines one and two are hard to dispute. Line three is where people push back: what if the chain simply goes back forever? Picture asking a friend for a book. He does not have it, but he will borrow it from someone, who will borrow it from someone else, and so on. If everyone in the chain is only borrowing, will the book ever arrive? Never, and making the chain longer, even infinitely long, does not help, because adding borrowers never adds a book. Yet the book is in your hands. So somebody in the chain actually owned it."),
            .longOnly(.text("Existence is the book. Everything we observe has its existence on loan, and since existence is plainly here, something must have it of itself and not on loan. Or picture a train of boxcars with no engine. Add a thousand more, or infinitely many: without an engine, nothing moves.")),
        ]),
        ArticleSection("THE QURAN'S THREE OPTIONS", [
            .text("The Quran makes the argument as a question, with no premise taken from scripture, and lets the listener choose:"),
            .ayah("52:35-36"),
            .longOnly(.text("For anything that has come to be, there are only three options. From nothing: impossible, because nothing has no power to produce anything. From itself: impossible, because it would have to exist before it existed. So from something other than itself. Ibn Kathir explains that the passage establishes both Allah’s lordship and His sole right to worship: they were not brought into being without a maker, and they did not make themselves; Allah created them after they were nothing. And the ayah ends on a diagnosis, that they are not certain. The Quran treats this as an argument meant to produce yaqin. When Jubayr ibn Mut‘im (may Allah be pleased with him) heard these ayat recited while he was still an idolater, he said his heart almost flew (Sahih al-Bukhari 4854).")),
            .longOnly(.hadith("bukhari:4854", cite: "Sahih al-Bukhari 4854", arabic: 22...63, english: [0...78])),
            .shortOnly(.text("For anything that has come to be, there are only three options. From nothing: impossible, because nothing has no power to produce anything. From itself: impossible, because it would have to exist before it existed. So from something other than itself. And the ayah ends on a diagnosis, that they are not certain. The Quran treats this as an argument meant to produce yaqin.")),
            .text("A second verse names both halves of the argument in two words, faqr and ghina, need and freedom from need:"),
            .ayah("35:15"),
            .longOnly(.quote(text: "“That is, they need Him in every movement and every stillness, and He, the Exalted, is free of need of them in Himself.” (Ibn Kathir, Tafsir al-Quran al-‘Azim, under 35:15).", arabic: "أَي: هُم مُحتَاجُونَ إِلَيهِ فِي جَمِيعِ الحَرَكَاتِ وَالسَّكَنَاتِ، وَهُوَ تَعَالَى الغَنِيُّ عَنهُم بِالذَّاتِ", dimmed: true)),
            .markdown("Contingent and necessary, in the Quran’s own vocabulary: we are the **fuqara’ (الفُقَرَاء)**, the ones in need, and Allah is **al-Ghani (الغَنِيّ)**, the One who needs nothing."),
        ]),
        ArticleSection("A BEGINNING, AND A BACKUP", only: .long, [
            .text("The argument works whether or not the universe had a beginning, but the evidence that it did is worth knowing. In 1927 Georges Lemaître, and in 1929 Edwin Hubble, found that the galaxies are moving apart: the universe is expanding, and run backwards it converges on a hot, dense beginning about 13.8 billion years ago. In 1965 Arno Penzias and Robert Wilson detected the cosmic microwave background, the leftover glow of that early state, arriving from every direction in the sky. The usable energy of the universe keeps running down, which sits uneasily with a universe that has existed forever. And in 2003 Arvind Borde, Alan Guth and Alexander Vilenkin showed that a universe which has, on average, been expanding cannot be extended into the infinite past."),
            .text("Fairness requires the caveat the physicists give themselves. Some propose models without an absolute beginning, and what, if anything, came before the expanding universe is debated. The series does not hang its case on any one model, because physics changes. That is why contingency comes first: even if it were shown tomorrow that the universe had always existed, the question would remain why this universe exists at all rather than nothing. An eternal chain of borrowers still never produces the book."),
            .door(.article("ProvingGodView")),
        ]),
        ArticleSection("WHAT THE SOURCE MUST BE", [
            .text("Domino 2 falls with a conclusion about what the source of everything must be, and what it cannot be. It is not another dependent thing, and not one more link inside the chain. It is not limited the way the universe is limited, and it does not need the universe. It is independent, it cannot fail to exist, it has no beginning and no end, and everything else depends on it."),
            .text("The Quran names this attribute first among four:"),
            .ayah("57:3"),
            .longOnly(.text("And the Prophet Muhammad (peace and blessings be upon him) explained these names himself, in a du‘a he taught for the moment before sleep:")),
            .longOnly(.hadith("muslim:2713", cite: "Sahih Muslim 2713", arabic: 55...75, english: [98...139])),
            .text("The First, with nothing before Him, is the necessary being of the argument, named by revelation. Everything else, however vast or ancient, began, depends, and passes:"),
            .ayah("55:26-27"),
            .longOnly(.text("Abu Ja‘far at-Tahawi (may Allah have mercy on him), whose short creed the Sunni scholars have taught for more than a thousand years, put the same truth this way:")),
            .longOnly(.quote(text: "“Eternal without a beginning, enduring without an end; He neither perishes nor comes to an end.” (Abu Ja‘far at-Tahawi, al-‘Aqidah at-Tahawiyyah).", arabic: "قَدِيمٌ بِلَا ابتِدَاءٍ، دَائِمٌ بِلَا انتِهَاءٍ، لَا يَفنَى وَلَا يَبِيدُ", dimmed: true)),
            .longOnly(.text("Ibn Abi al-‘Izz (may Allah have mercy on him), explaining the creed, noted that the Eternal, al-Qadim, is the theologians’ word and not one of the names Allah gave Himself. The name He revealed is al-Awwal, the First, which the Prophet (peace be upon him) explained as the One before whom there is nothing.")),
            .callout("There is an independent, uncaused source of everything. It is not part of the universe, it does not depend on the universe, and it needs no cause itself.", title: "Domino 2 Falls", icon: "checkmark.seal.fill"),
        ]),
        ArticleSection("AN OLD ARGUMENT, AND A CAUTION", only: .long, [
            .text("Muslims did not borrow this argument from modern Western philosophy. Ibn Sina (d. 1037 CE) built his famous proof on the distinction between the contingent and the Necessary Existent, and the best-known modern version of the argument from a beginning is called the kalam cosmological argument, after ‘ilm al-kalam, Islamic scholastic theology, because the Christian philosopher William Lane Craig built it on al-Ghazali’s formulation (The Kalam Cosmological Argument, 1979)."),
            .text("But a Muslim should know the history behind those names, because the Sunni scholars did not accept everything that came with them. Ibn Sina held that the world had always existed alongside God, that the resurrection would not be bodily, and that God knows particular things only in a general way, and al-Ghazali, in The Incoherence of the Philosophers, judged those three positions to be disbelief. Ibn Taymiyyah went further: the philosophers’ Necessary Existent, stripped of every attribute, is a being that exists only in the mind, while the Necessary Being the argument actually proves is living, knowing, powerful and acting by His will. And the long proofs of the theologians, built on bodies and their accidents, led many of them to deny attributes that Allah affirmed for Himself."),
            .text("The Domino Process therefore uses the argument in the form the Quran gives it, which is short, sound and close to the fitrah: whatever is dependent points to One who is not, and that One is not an abstraction but the First, the Living, who created by His will. The next domino shows how far reason itself can follow."),
            .door(.article("RububiyyahView")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .longOnly(.markdown("**What if the chain of causes simply goes back forever?**")),
            .longOnly(.text("Then it is an endless chain of borrowers, and the book still never arrives. The length of the chain is not the problem; its nature is. A regress of makers, each needing a maker before it, is what Ibn Taymiyyah called false by plain reason and by the agreement of the rational. If every cause needed a prior cause without end, nothing would ever have been caused at all.")),
            .markdown("**Couldn’t the universe itself be the necessary thing?**"),
            .text("The universe is its parts and their arrangement, and both are contingent. Its size, its age, its constants and its contents could all have been otherwise, and it changes, runs down, and depends at every moment on conditions within it. A pile of borrowed books is still borrowed, however high it is stacked."),
            .longOnly(.markdown("**Each thing depends, but why must the whole depend?**")),
            .longOnly(.text("Because a whole made only of dependent members has nothing in it that can supply existence to the rest. Adding members adds more dependence, never independence. Some wholes do have properties their parts lack, but needing nothing is not a property dependent parts can build: a crowd of people who each need water is a crowd that needs water.")),
            .longOnly(.markdown("**Doesn’t quantum physics show things coming from nothing?**")),
            .longOnly(.text("No. The quantum vacuum is not nothing. It is a field with energy and structure, governed by physical laws, so whatever arises from it arises from something. When the physicist Lawrence Krauss argued in A Universe from Nothing (2012) that physics can explain a universe without a creator, the philosopher of physics David Albert replied in the New York Times that the book never explains where the laws and fields themselves come from.")),
            .markdown("**Why call the necessary being God rather than simply something?**"),
            .text("So far it has only been shown to exist, to be independent, and to be the source of everything else. Whether it is a blind force or One who chooses is the question of the next domino."),
            .door(.article("DominoCreatorView")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Everything we observe is contingent: it could have been otherwise, and it borrows its existence from something else. A chain of borrowers, even an endless one, never explains why there is anything at all, so something must exist necessarily, depending on nothing while everything depends on it. The argument does not rest on any one model of physics, though the evidence that the universe began fits it well. The Quran gives it as three options of which only one survives (52:35-36), names its two sides as our need and Allah’s freedom from need (35:15), and names the Necessary Being as the First, before whom there is nothing (57:3)."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Mumkin al-Wujud", arabic: "مُمكِن الوُجُود", meaning: "The **contingent**: that whose existence is possible but not necessary, which could have not existed and depends on something else for its being."),
            .term("Wajib al-Wujud", arabic: "وَاجِب الوُجُود", meaning: "The **necessary being**: that which exists of itself, cannot fail to exist, and depends on nothing. The philosophers used the term; revelation names Him al-Awwal and al-Ghani."),
            .term("Faqr", arabic: "فَقر", meaning: "**Need**, or poverty. In 35:15 all mankind are the fuqara’, those in need of Allah in every movement and every stillness."),
            .term("Al-Ghani", arabic: "الغَنِيّ", meaning: "**The Free of need**, one of the names of Allah: He needs nothing from His creation, while everything needs Him (35:15)."),
            .term("Al-Awwal", arabic: "الأَوَّل", meaning: "**The First**, the name of Allah in 57:3, which the Prophet (peace be upon him) explained as the One before whom there is nothing (Sahih Muslim 2713)."),
        ]),
    ]
}

struct DominoCreatorView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "DominoCreatorView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Domino 3: An Intelligent Creator")
        .englishArticle().selectableArticleList(article: "DominoCreatorView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: the necessary source of everything is not a blind force. It brought about this particular universe out of countless possible ones, and selecting is what a will does; a cause that had always existed and worked automatically would always have produced its effect, yet the world began; and chance is a name for causes we cannot track, not a power that makes anything. Three observations strengthen the conclusion: a universe set for life, a universe minds can read, and the minds themselves. Reason can say that the Creator is living, knowing, willing, powerful and wise, and the Quran said it first. What reason cannot say is His names and what He wants of us."),
        ]),
        ArticleSection("A FORCE, OR ONE WHO CHOOSES?", [
            .text("Two dominoes have fallen: something exists, and it rests on something that exists necessarily and depends on nothing. Now the question is what that source is like. Is it a blind force, like gravity with no mind behind it, or does it choose?"),
            .longOnly(.text("Look at what it produced. The world does not merely exist; it is ordered, structured and readable. Its constants permit stars, chemistry and life. It contains beings who think, intend, choose and ask why, and whose minds can discover the mathematics it runs on. An intelligent source explains all of that far better than blind chaos does, and this is the very reflection 3:190-191 describes: looking at the heavens and the earth and concluding that they were not made aimlessly. No one of these observations has to carry the argument alone. They are cumulative: each makes the next explanation more reasonable.")),
            .longOnly(.ayah("3:190-191")),
            .longOnly(.text("The Arabs of the desert knew the shape of this reasoning long before anyone called it an argument. Ibn Kathir (may Allah have mercy on him) records the answer of a Bedouin who was asked for the proof that the Lord exists:")),
            .longOnly(.quote(text: "“Glory be to Allah! Camel droppings point to the camel, and footprints point to the traveller. Then a sky with its constellations, an earth with its wide paths, and seas with their waves: do they not point to the Subtle, the All-Aware?” (a Bedouin, quoted by Ibn Kathir, Tafsir al-Quran al-‘Azim, under 2:22).", arabic: "يَا سُبحَانَ اللَّهِ، إِنَّ البَعرَ لَيَدُلُّ عَلَى البَعِيرِ، وَإِنَّ أَثَرَ الأَقدَامِ لَتَدُلُّ عَلَى المَسِيرِ، فَسَمَاءٌ ذَاتُ أَبرَاجٍ، وَأَرضٌ ذَاتُ فِجَاجٍ، وَبِحَارٌ ذَاتُ أَموَاجٍ، أَلَا يَدُلُّ ذَلِكَ عَلَى وُجُودِ اللَّطِيفِ الخَبِيرِ؟", dimmed: true)),
        ]),
        ArticleSection("SELECTED, NOT AUTOMATIC", [
            .text("Two lines of reasoning show that the source has a will."),
            .markdown("The first is **particularization**, which the classical theologians called **takhsis (تَخصِيص)**, specification. Our universe is one specific way things could have been out of countless others: this size, these laws, these constants, this starting point. Each alternative was equally possible as far as the bare idea of a universe goes. Something selected this option over the others, and selecting is exactly what a will does."),
            .markdown("The second concerns **a cause that has always existed and an effect that began**. If the source of the universe were an automatic mechanism, its effect would follow automatically, and for as long as the cause existed the effect would exist too: a foot pressed into sand forever leaves a footprint forever. But the universe is contingent and, on the evidence, it began. How does a cause without a beginning produce an effect with one? The best explanation is that it acts by choice: it created when it willed."),
            .longOnly(.text("Al-Ghazali (may Allah have mercy on him) pressed this point against the philosophers in the eleventh century, and William Lane Craig uses it today. Ibn Taymiyyah (may Allah have mercy on him) made a form of it the heart of his answer to Ibn Sina: a cause that necessitates its effect from eternity, with nothing new ever arising from it, could never be the source of things that come to be one after another, as everything in the world does. The Maker of the world is therefore not a machine but One who does what He wills:")),
            .shortOnly(.text("The Maker of the world is therefore not a machine but One who does what He wills:")),
            .ayah("85:16"),
        ]),
        ArticleSection("CHANCE IS NOT A CAUSE", [
            .text("Someone will say that it is all random: chance did it. But chance is not a thing with power. It is a word for outcomes whose causes we cannot track. When a coin is tossed, chance does not flip it; the thumb, the air and gravity do, and we simply cannot follow them closely enough to predict the result. To say that chance made the universe is to say that nothing made it, and the first domino has already ruled that out: something cannot come from absolutely nothing."),
            .text("The Quran describes the opposite of chance. Allah created each thing and measured it out with precision, so that nothing in creation is unplanned:"),
            .ayah("25:2", words: 14...18),
            .longOnly(.ayah("54:49")),
            .longOnly(.text("And the Prophet Muhammad (peace and blessings be upon him) said that the measure of every created thing was written before the heavens and the earth existed:")),
            .longOnly(.hadith("muslim:2653b", cite: "Sahih Muslim 2653", arabic: 43...60, english: [7...32])),
        ]),
        ArticleSection("A UNIVERSE SET FOR LIFE", [
            .longOnly(.text("The first reinforcement is fine-tuning. Several constants of physics, and several features of the early universe, sit within narrow ranges that allow stars, chemistry and life to exist. Physicists of every worldview acknowledge the fact; they disagree about why it is so. Two examples show the kind of thing meant.")),
            .longOnly(.markdown("**The energy of empty space.** The cosmological constant, the energy carried by space itself, is smaller than simple theoretical estimates by something like 120 powers of ten. In 1987 the physicist Steven Weinberg, who did not believe in God, showed that if it were larger than a narrow limit, still tiny beside those estimates, space would have expanded too fast for galaxies, and so for stars and planets, ever to form.")),
            .longOnly(.markdown("**The making of carbon.** Every living thing is built on carbon, which stars forge from helium. In 2000 Heinz Oberhummer and his colleagues calculated, in the journal Science, that a change of more than about half a percent in the strength of the strong nuclear force would leave the stars making almost no carbon or almost no oxygen.")),
            .longOnly(.text("What could explain such settings? There are four candidates. Physical necessity: but there is no evidence that the values had to be these. Chance: but the odds are the very problem. A multiverse, in which countless universes take every value and we find ourselves in one that permits us: but no other universe has been observed, and a process that generates universes would itself need finely set laws to work. Or design. A Muslim does not rest his faith on any single number, and debates about the exact ranges continue among specialists. The point is the pattern the Quran invites its reader to test:")),
            .shortOnly(.text("The first reinforcement is fine-tuning. Several constants of physics sit within narrow ranges that allow stars, chemistry and life to exist. If the energy of empty space were larger than a narrow limit, as the physicist Steven Weinberg showed in 1987, space would have expanded too fast for galaxies, and so for stars and planets, ever to form. Physicists of every worldview acknowledge the fact; they disagree about why it is so.")),
            .shortOnly(.text("What could explain such settings? Physical necessity: but there is no evidence that the values had to be these. Chance: but the odds are the very problem. A multiverse: but no other universe has been observed, and a process that generates universes would itself need finely set laws to work. Or design. A Muslim does not rest his faith on any single number. The point is the pattern the Quran invites its reader to test:")),
            .ayah("67:3-4"),
        ]),
        ArticleSection("A UNIVERSE YOU CAN READ", [
            .longOnly(.text("The second reinforcement is intelligibility. The universe runs on laws that can be written in mathematics, and human minds can discover them. Equations worked out on a whiteboard predict how galaxies move and where a planet will be in a thousand years. Einstein wrote that the eternal mystery of the world is its comprehensibility, and the physicist Eugene Wigner ended a famous essay with this:")),
            .longOnly(.quote(text: "“The miracle of the appropriateness of the language of mathematics for the formulation of the laws of physics is a wonderful gift which we neither understand nor deserve.” (Eugene Wigner, “The Unreasonable Effectiveness of Mathematics in the Natural Sciences,” 1960).", dimmed: true)),
            .longOnly(.text("If reality comes from a Mind, a rational, readable universe is what one would expect. If it comes from nothing in particular, it is a striking surprise. The same numbers keep turning up where nobody put them. Pi, learned from circles, governs waves and the swing of a pendulum. Euler’s number e appears wherever something grows or decays in proportion to itself. Euler’s identity ties e, pi, i, one and zero together in a single line, and the seeds of a sunflower spiral in Fibonacci numbers such as 34 and 55. None of this is offered as a proof. It is an invitation to look, the way the Quran keeps telling its reader to look:")),
            .shortOnly(.text("The second reinforcement is intelligibility. The universe runs on laws that can be written in mathematics, and human minds can discover them. If reality comes from a Mind, a rational, readable universe is what one would expect. If it comes from nothing in particular, it is a striking surprise. None of this is offered as a proof. It is an invitation to look, the way the Quran keeps telling its reader to look:")),
            .ayah("41:53", words: 0...10),
        ]),
        ArticleSection("THE SIGN WITHIN", [
            .longOnly(.text("The third reinforcement is the one closest to home: consciousness. There is something it is like to be you, to see red, to feel pain, to understand this sentence, a way of putting it made famous by the philosopher Thomas Nagel in 1974. In 1995 David Chalmers named the question of why any physical process is accompanied by inner experience the hard problem of consciousness. A complete map of which neurons fire and when, valuable as it would be, would still leave that question untouched.")),
            .longOnly(.text("This is not only a believer’s point. Nagel, an atheist, argued in Mind and Cosmos (2012) that a purely materialist picture of nature cannot account for minds; the book’s subtitle calls the materialist neo-Darwinian conception of nature almost certainly false. Alvin Plantinga adds a related argument: if our thinking were only the product of unguided processes selected for survival, and survival and truth are not the same thing, why trust it to track the truth? Darwin himself confessed the worry in a letter of 1881, doubting whether the convictions of a mind developed from the minds of lower animals could be trusted at all.")),
            .shortOnly(.text("The third reinforcement is consciousness. There is something it is like to be you, to see red, to feel pain, to understand this sentence, and a complete map of which neurons fire and when would still leave untouched the question of why any physical process is accompanied by inner experience.")),
            .text("If reality is mindless at bottom, minds are a surprise. If its source is a living, knowing Creator, minds are what one would expect, and the Quran names them among His signs:"),
            .ayah("51:20-21"),
            .longOnly(.text("It also teaches humility about the soul, which is exactly where the hard problem sits:")),
            .longOnly(.ayah("17:85")),
        ]),
        ArticleSection("WHAT REASON CAN SAY OF HIM", [
            .text("With three dominoes down, the argument has not stopped at a force. It points to attributes, and each one can be reached by reason and then found named in the Quran:"),
            .bullet("**The First, depending on nothing.** The chain must end in what depends on nothing: al-Awwal (57:3) and al-Ghani (35:15)."),
            .ayah("57:3"),
            .ayah("35:15"),
            .longOnly(.bullet("**Unlike His creation.** He is the source of the universe’s matter, space and time, so He is not one more thing made of them. Revelation adds that He is distinct from His creation and above it, over His Throne (20:5), and the Prophet (peace be upon him) called Him the Manifest, above whom there is nothing (Sahih Muslim 2713).")),
            .longOnly(.ayah("20:5")),
            .longOnly(.hadith("muslim:2713", cite: "Sahih Muslim 2713", arabic: 55...75, english: [98...139])),
            .bullet("**All-Powerful.** He brought everything into existence: al-Qadir."),
            .bullet("**Willing.** He chose this universe over every alternative: the Effecter of what He intends (85:16)."),
            .bullet("**All-Knowing.** No one chooses what he does not know, and no one makes what he does not understand:"),
            .ayah("67:14"),
            .bullet("**Living.** Will, knowledge and power belong only to the living: al-Hayy, al-Qayyum."),
            .longOnly(.ayah("2:255", words: 0...6)),
            .longOnly(.text("Some of the later theologians held that reason could establish only seven attributes of this kind, and then explained away much of what else revelation affirms. Ibn Taymiyyah answered, in his al-Risalah at-Tadmuriyyah, that the same reasoning goes further: if the specification of the world shows a will, then the good He does His creatures shows His mercy, and the praiseworthy ends of what He makes and commands show His wisdom. Reason reaches more than they allowed, and nothing in revelation contradicts it. The rule for every attribute is the one the Quran gives in a single ayah, which denies any likeness while affirming that He truly hears and sees:")),
            .longOnly(.ayah("42:11", words: 13...18)),
            .text("Here honesty requires a limit. Reason can show that there is a living, knowing, willing, powerful Creator. It cannot tell us His names, what He wants from us, or how He is to be worshipped. For that He would have to tell us, and whether He has is the question of Part 2."),
            .door(.article("AsmaSifatView")),
        ]),
        ArticleSection("HOW THE QURAN SPEAKS OF HIS CREATION", only: .long, [
            .text("Part 1 closes, as every part of the series does, with evidence for Islam itself. If the Quran is from the Creator these dominoes have reached, does it speak of His creation like someone who knows it? The series keeps such claims modest, because modest claims are the ones that survive a sceptic, and it holds them to three rules:"),
            .step("1. **Fit, not prediction.** Say that a verse fits what we now know, never that it predicted modern science."),
            .step("2. **The classical reading beside the modern one.** Give the meaning the early commentators gave, and present any modern reading as one the words allow."),
            .step("3. **No stretched translations.** Leave out anything that works only if a word is forced."),
            .text("One example that meets the rules is a parable about the darkness of disbelief:"),
            .ayah("24:40", words: 0...22),
            .text("Sunlight fades with depth: most of it is gone within about two hundred metres, and below about a thousand metres the ocean is dark. There are also waves beneath the surface waves, internal waves along the boundaries between layers of water, first explained scientifically by Vagn Walfrid Ekman in 1904. The verse is a parable, not an oceanography lesson, and it came from a man of Makkah and Madinah with no report of his ever having sailed; the point is only that its imagery is accurate in ways no one then could check. The same care applies to the joined heavens and earth (21:30) and the heaven Allah expands (51:47), which the classical commentators read in more than one way. Numerical patterns, word counts and contested claims about embryology are left out altogether."),
            .ayah("21:30"),
            .ayah("51:47"),
            .door(.article("ProvingScienceView")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .longOnly(.markdown("**Couldn’t the source be an impersonal law rather than a mind?**")),
            .longOnly(.text("A law of nature describes how things behave once they exist; it does not bring anything into existence or choose between alternatives. Gravity has never made a single atom. And a law is itself one of the specific features of this universe that needs explaining, which brings the question straight back.")),
            .markdown("**Doesn’t evolution explain away design?**"),
            .text("None of the arguments in this chapter depends on biology. Particularization, the beginning of the universe, the fine-tuning of physical constants, the intelligibility of nature and the existence of consciousness all come before any account of how living things developed, and they stand whatever one concludes about it. That is one reason the series leaves the argument from DNA aside."),
            .longOnly(.markdown("**If the science changes, does the domino fall?**")),
            .longOnly(.text("Its core does not. Particularization and the point that chance is not a cause rest on reason, not on any one discovery. Fine-tuning and intelligibility are reinforcements, offered as cumulative evidence rather than as proofs on their own, and they are held as loosely as the science they lean on.")),
            .door(.article("DominoOneView")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("The necessary source of everything chose this universe over every alternative, and it brought about a world that began, so it acts by will rather than by blind necessity. Chance cannot stand in for it, because chance is only a name for causes we cannot follow. A universe set within narrow ranges for life, readable in mathematics, and home to conscious minds is what a living, knowing Creator would produce and what mindless matter struggles to explain. Reason can call Him the First, Free of need, unlike His creation, All-Powerful, Willing, All-Knowing, Living and Wise, and the Quran named Him so first. Whether He is one is the fourth domino."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Takhsis", arabic: "تَخصِيص", meaning: "**Specification**: the selecting of one possibility over others equally possible. The theologians argued that the specific character of the universe shows a will that chose it."),
            .term("Iradah", arabic: "إِرَادَة", meaning: "**Will**. Allah is the Effecter of what He intends (85:16): He creates by choice, not by blind necessity, and nothing happens that He has not willed."),
            .term("Hikmah", arabic: "حِكمَة", meaning: "**Wisdom**: putting each thing in its place for a praiseworthy end. Ibn Taymiyyah argued that the purposes visible in creation show Allah’s wisdom as clearly as its specification shows His will."),
            .term("Tafawut", arabic: "تَفَاوُت", meaning: "**Inconsistency**, things out of proportion or out of joint with one another. The Quran says no one will find any in the creation of the Most Merciful, however often he looks (67:3-4)."),
        ]),
    ]
}

struct DominoOneView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "DominoOneView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Domino 4: Only One")
        .englishArticle().selectableArticleList(article: "DominoOneView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: once reason has reached a necessary, living, willing Creator, the fourth domino asks whether there could be more than one. There cannot. Two ultimate beings would differ, so that one lacks what the other has and is not ultimate, or they would not differ, and then they are not two. Two all-powerful wills would block each other, or one would prevail and the other was never all-powerful. The Quran gives the argument in a few words (21:22, 23:91, 17:42), Surah al-Ikhlas gathers all four dominoes into four lines, and the fitrah knows Him as One. But knowing that there is one Creator is not yet Islam: the idolaters of Makkah knew it too."),
        ]),
        ArticleSection("COULD THERE BE TWO?", [
            .text("Three dominoes have fallen: something exists, it rests on a necessary source, and that source is a living Creator with will and knowledge. Could there be two such beings, or a committee of them, as many ancient religions held and some people still suggest?"),
            .text("Start with what would make them two. If there were two necessary, ultimate beings, something would have to tell them apart: one would have something the other lacks. But then the one lacking it is limited, missing something, and so it is not ultimate after all. And if nothing at all distinguishes them, no power, no knowledge, no attribute, no will, then they are not two beings. They are one, counted twice."),
            .longOnly(.text("A different answer came from Mani, the third-century founder of Manichaeism, and from other dualist teachers: two eternal principles, one of light and good and one of darkness and evil, because a single good Maker could not, they thought, be the source of a world with so much darkness in it. The same reasoning applies to them. Two ultimate principles would limit each other, and a power that can never overcome its rival is not ultimate. The Quran opens Surah al-An‘am by praising Allah who made the darkness and the light: both are His creation, and neither is a god. Why a good Creator permits suffering is a real question, and the chapter on atheism, agnosticism and deism takes it up; a second god is not the answer to it.")),
            .longOnly(.ayah("6:1")),
            .longOnly(.text("Abu Ja‘far at-Tahawi (may Allah have mercy on him) opened his creed with the conclusion the dominoes have now reached:")),
            .longOnly(.quote(text: "“Allah is One, without any partner. There is nothing like Him, nothing is beyond His power, and there is no god other than Him.” (Abu Ja‘far at-Tahawi, al-‘Aqidah at-Tahawiyyah).", arabic: "إِنَّ اللَّهَ وَاحِدٌ لَا شَرِيكَ لَهُ، وَلَا شَيءَ مِثلُهُ، وَلَا شَيءَ يُعجِزُهُ، وَلَا إِلَهَ غَيرُهُ", dimmed: true)),
        ]),
        ArticleSection("TWO WILLS", [
            .text("The second argument imagines two all-powerful creators and asks what would happen when their wills differ. Suppose one wills a thing to move and the other wills it to stay still, or one wills the universe to exist and the other wills it not to. Both cannot succeed, because the outcomes contradict each other. If neither succeeds, neither is all-powerful. If one succeeds, the other was not all-powerful, and so was never a god. And if the two can never disagree, then something constrains them, and again neither is ultimate."),
            .text("The Quran gives the argument from what everyone can see:"),
            .ayah("23:91"),
            .longOnly(.text("Ibn Kathir (may Allah have mercy on him) explains the ayah this way:")),
            .longOnly(.quote(text: "“That is, were there supposed to be several gods, each would keep to himself what he had created, and existence would not hold together. But what we see is an existence ordered and harmonious, its upper and lower worlds bound to one another in the utmost perfection.” (Ibn Kathir, Tafsir al-Quran al-‘Azim, under 23:91).", arabic: "أَي: لَو قُدِّرَ تَعَدُّدُ الآلِهَةِ لَانفَرَدَ كُلٌّ مِنهُم بِمَا خَلَقَ، فَمَا كَانَ يَنتَظِمُ الوُجُودُ، وَالمُشَاهَدُ أَنَّ الوُجُودَ مُنتَظِمٌ مُتَّسِقٌ، كُلٌّ مِنَ العَالَمِ العُلوِيِّ وَالسُّفلِيِّ مُرتَبِطٌ بَعضُهُ بِبَعضٍ فِي غَايَةِ الكَمَالِ", dimmed: true)),
            .longOnly(.markdown("He adds that the theologians stated the same meaning and called it **dalil at-tamanu‘ (دَلِيل التَّمَانُع)**, the proof from mutual hindrance: if one god willed a body to move and another willed it to rest, either neither would get his will, and both would be powerless, or one would prevail, and the defeated one would be dependent, which is not fitting for the Necessary Being. The universe bears the mark of one will, not two: the same laws hold in the farthest galaxy as in a falling apple.")),
        ]),
        ArticleSection("WHAT 21:22 ADDS", [
            .text("The best-known ayah on this subject says more still:"),
            .ayah("21:22"),
            .longOnly(.markdown("Many theologians read it simply as the proof from mutual hindrance. Ibn Taymiyyah and, after him, Ibn Abi al-‘Izz in his commentary on the Tahawi creed (may Allah have mercy on them both) pointed out that it goes further. It speaks of **alihah (آلِهَة)**, gods that are worshipped, and declares that the heavens and the earth would be ruined if anything besides Allah were worshipped in truth. So the ayah proves not only that there is one Creator but that there is only one who deserves worship, which is the whole message of the prophets. Another passage makes the point from the other side:")),
            .shortOnly(.markdown("Ibn Taymiyyah and, after him, Ibn Abi al-‘Izz (may Allah have mercy on them both) pointed out that it goes further than the argument from two wills. It speaks of **alihah (آلِهَة)**, gods that are worshipped, so the ayah proves not only that there is one Creator but that there is only one who deserves worship, which is the whole message of the prophets. Another passage makes the point from the other side:")),
            .ayah("17:42-43"),
            .longOnly(.text("The commentators read the way they would seek in two senses. Some took it as a way to contend with the Owner of the Throne for His dominion. Ibn Kathir took it as a way to draw near to Him: if there were others beside Him, they would themselves be worshipping Him and seeking nearness to Him, so worship Him alone, as they would, with no go-between. Either way, the supposed partners turn out to be rivals who would ruin the world, or servants who bow to the One.")),
        ]),
        ArticleSection("ONE IS ENOUGH", [
            .text("The third argument is simplicity. One necessary source explains everything there is. A second explains nothing the first does not, and so adds an assumption with no evidence behind it. By the rule everyone uses in the driveway and the doctor’s surgery, the explanation with fewer unsupported assumptions is preferred."),
            .longOnly(.text("Yusuf (peace be upon him) put the question to two prisoners who had known many lords:")),
            .longOnly(.ayah("12:39")),
            .longOnly(.text("And the Quran draws the human cost of the alternative in a parable. A slave owned by quarrelling partners is pulled in every direction and can never satisfy them all; a slave who belongs to one master knows exactly whom he serves:")),
            .longOnly(.ayah("39:29")),
            .callout("There is one Creator. In Arabic, Christians and Jews also say Allah for God, and the word itself means the God. What each means by it, and whether He has spoken, are the questions of Parts 2 and 3.", title: "Domino 4 Falls", icon: "checkmark.seal.fill"),
        ]),
        ArticleSection("FOUR LINES THAT SAY IT ALL", [
            .longOnly(.text("When the idolaters asked the Prophet Muhammad (peace and blessings be upon him) to give the lineage of his Lord, the answer came down as a surah of four ayat:")),
            .longOnly(.hadith("tirmidhi:3364", cite: "Jami` at-Tirmidhi 3364; graded hasan by al-Albani", arabic: 24...73, english: [0...79])),
            .shortOnly(.text("Surah al-Ikhlas gathers all four dominoes into four lines:")),
            .ayah("112:1-4"),
            .text("Set beside the four dominoes, the four lines answer each in turn:"),
            .markdown("**Qul huwa Allahu ahad.** There is exactly one ultimate being, the conclusion of the fourth domino. **Ahad** is a oneness with no division within it and no second beside it."),
            .longOnly(.markdown("**Allahu as-Samad.** Everything depends on Him and He depends on nothing, the second domino. Ibn ‘Abbas (may Allah be pleased with them both) explained as-Samad as the One to whom all creation turns in its needs and requests, and as the Master whose mastery, knowledge, wisdom and every perfection are complete. Al-Hasan al-Basri and Qatadah (may Allah have mercy on them) said: the One who remains after His creation.")),
            .shortOnly(.markdown("**Allahu as-Samad.** Everything depends on Him and He depends on nothing, the second domino.")),
            .longOnly(.markdown("**Lam yalid wa lam yulad.** He neither begets nor was born: uncaused, without beginning, and nothing came from Him as a part of Him. The narration above gives the reason: whatever is born will die, whatever dies is inherited from, and Allah neither dies nor is inherited from.")),
            .shortOnly(.markdown("**Lam yalid wa lam yulad.** He neither begets nor was born: uncaused, without beginning, and nothing came from Him as a part of Him.")),
            .markdown("**Wa lam yakun lahu kufuwan ahad.** Nothing is equal or comparable to Him: unlike anything in creation, as the third domino found."),
            .longOnly(.text("In a hadith qudsi, Allah answers the claim that He has a son in the words of this surah:")),
            .longOnly(.hadith("bukhari:4974", cite: "Sahih al-Bukhari 4974", arabic: 56...74, english: [73...112])),
            .longOnly(.text("It is no wonder that the Prophet (peace be upon him) said this short surah equals a third of the Quran (Sahih al-Bukhari 5013), or that when a Companion explained that he loved to recite it because it describes the Most Merciful, the Prophet told him that Allah loves him (Sahih al-Bukhari 7375). The first domino and the fourth meet in it: a search that began with why anything exists ends in a description of the One who exists of Himself.")),
            .longOnly(.hadith("bukhari:5013", cite: "Sahih al-Bukhari 5013", arabic: 25...65, english: [0...63])),
            .longOnly(.hadith("bukhari:7375", cite: "Sahih al-Bukhari 7375", arabic: 39...98, english: [0...99])),
        ]),
        ArticleSection("THE FITRAH KNOWS HIM AS ONE", [
            .text("Reason reaches oneness by argument, but the human heart was made to know it before any argument:"),
            .ayah("30:30"),
            .shortOnly(.text("The fitrah does not know merely that there is a Maker. It knows Him as One and turns to Him alone, which is why a crisis strips the partners away.")),
            .longOnly(.text("The Prophet (peace be upon him) said:")),
            .longOnly(.hadith("bukhari:1385", cite: "Sahih al-Bukhari 1385", arabic: 31...49, english: [4...44])),
            .longOnly(.text("The fitrah does not know merely that there is a Maker. It knows Him as One and turns to Him alone, which is why a crisis strips the partners away. The Quran describes it at sea, where idol worshippers call on Allah alone, sincerely, when the waves rise over them like canopies (31:32).")),
            .longOnly(.ayah("31:32")),
            .longOnly(.text("One man lived it. ‘Ikrimah (may Allah be pleased with him), the son of Abu Jahl, was among the few excluded from the amnesty on the day Makkah was conquered, and he fled by sea:")),
            .longOnly(.hadith("nasai:4067", cite: "Sunan an-Nasa’i 4067; graded sahih by al-Albani", arabic: 105...167, english: [115...214])),
            .longOnly(.text("The idolaters on that ship knew in the storm what they denied on land, and ‘Ikrimah drew the conclusion the dominoes draw: if only sincerity to the One can save at sea, nothing else can save on land. Ibn Taymiyyah held that knowledge of the Creator is rooted in the fitrah of every soul, and that arguments are needed only where something has been laid over it. The storm lifts what was laid over it for a moment; the dominoes try to lift it for good.")),
        ]),
        ArticleSection("ONE CREATOR IS NOT YET ISLAM", [
            .text("There is a trap at this point, and the Quran points it out. The idolaters of Makkah were not atheists. Asked who owned the earth, who was Lord of the seven heavens and of the Great Throne, and in whose hand was the realm of all things, they answered without hesitation:"),
            .ayah("23:84-89"),
            .longOnly(.markdown("They affirmed **tawhid ar-rububiyyah (تَوحِيد الرُّبُوبِيَّة)**, that Allah alone creates, owns and governs. What they refused was **tawhid al-uluhiyyah (تَوحِيد الأُلُوهِيَّة)**, that He alone is worshipped. They prayed to idols as intercessors who would bring them nearer to Him (39:3), and that was the shirk every messenger came to end. Their belief in one Creator did not make them Muslims.")),
            .longOnly(.ayah("39:3")),
            .shortOnly(.markdown("They affirmed **tawhid ar-rububiyyah (تَوحِيد الرُّبُوبِيَّة)**, that Allah alone creates, owns and governs. What they refused was **tawhid al-uluhiyyah (تَوحِيد الأُلُوهِيَّة)**, that He alone is worshipped, and that was the shirk every messenger came to end. Their belief in one Creator did not make them Muslims.")),
            .text("So the four dominoes of Part 1 reach the Creator, which is the starting point of tawhid and not the whole of it. Every messenger from Nuh to Muhammad (peace be upon them all) came with the same sentence, that there is no god but Allah, so worship Him alone (21:25), and what Allah asks of His servants can only be known if He has told them. That is where Part 1 ends and Part 2 begins."),
            .ayah("21:25"),
            .door(.article("TawhidView")),
            .door(.article("UluhiyyahView")),
        ]),
        ArticleSection("COMMON QUESTIONS", only: .long, [
            .markdown("**Couldn’t two gods simply agree forever?**"),
            .text("If they agree because they must, something beyond them makes them agree, and neither is ultimate. If they agree by choice, disagreement was possible, and the argument from mutual hindrance applies to that possibility. Either way, a second god explains nothing the first does not."),
            .markdown("**Christians say they believe in one God. Is the Trinity two or three gods?**"),
            .text("Christians affirm one God in three persons, and they should be described that way, as they describe themselves. Whether the doctrine is coherent, and whether Jesus (peace be upon him) taught it, are questions the series takes up carefully in Part 3."),
            .door(.article("DominoChristianityView")),
            .markdown("**Many Hindus speak of one ultimate reality with many forms. Isn’t that oneness?**"),
            .text("Hindu traditions are many, and many of them do hold to a supreme reality above lesser deities. They deserve to be described accurately, not caricatured. The question the series asks of them in Part 2 is not only how many ultimate beings there are, but who deserves worship."),
            .door(.article("DominoTestView")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("There can be only one ultimate being. Two would differ, making one of them limited, or not differ, making them one; two all-powerful wills would block each other or one would prevail; and a second god explains nothing the first does not. The Quran gives these arguments in 23:91, 21:22 and 17:42, and points to the ordered unity of creation as the evidence. Surah al-Ikhlas sums up all four dominoes in four lines, and the fitrah, laid bare in a storm, turns to Him alone. Yet affirming one Creator is the beginning of tawhid, not its end: the Makkans affirmed it and still worshipped others. What He asks of His creatures is the question of revelation."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Ahad", arabic: "أَحَد", meaning: "**One**, with no division in Himself and no second beside Him. The word opens Surah al-Ikhlas (112:1) and closes it, where nothing is His equal (112:4)."),
            .term("As-Samad", arabic: "الصَّمَد", meaning: "**The Eternal Refuge**: the Master to whom all creation turns in its needs, perfect in every attribute, who remains after His creation. Ibn Kathir gathers these explanations from Ibn ‘Abbas, al-Hasan and Qatadah under 112:2."),
            .term("Dalil at-Tamanu‘", arabic: "دَلِيل التَّمَانُع", meaning: "**The proof from mutual hindrance**: two all-powerful wills would block each other or one would prevail, so there cannot be two creators. Ibn Kathir names it under 23:91."),
            .term("Rububiyyah", arabic: "رُبُوبِيَّة", meaning: "**Lordship**: that Allah alone creates, owns and governs. The idolaters of Makkah affirmed it (23:84-89), which is why it is the start of tawhid and not the whole of it."),
            .term("Hanif", arabic: "حَنِيف", meaning: "One who **inclines away** from every false worship toward the One. It describes Ibrahim (6:79) and the fitrah itself (30:30)."),
            .ayah("6:79"),
        ]),
    ]
}

struct DominoWorldviewsView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "DominoWorldviewsView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Atheism, Agnosticism and Deism")
        .englishArticle().selectableArticleList(article: "DominoWorldviewsView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: Part 1 ends by examining the three places where people most often stop short of a Creator who has spoken. Atheism, usually resting on naturalism, says the physical world is all there is; agnosticism says it does not know; deism grants a Creator but says He is silent. Each is stated here as its own holders would state it, and then answered, along with the objections a sharp sceptic is most likely to raise: who created God, the multiverse, science and its gaps, suffering, and why God is not more obvious. The deist already accepts all four dominoes, which leaves the question Part 2 begins with: did God speak?"),
        ]),
        ArticleSection("THREE PLACES TO STOP", [
            .text("Four dominoes have fallen: something exists, it rests on a necessary source, that source is a living Creator with will and knowledge, and He is one. Now it is time to be fair to those who disagree. There are three common stopping points. Atheism, or naturalism: physical reality is all there is. Agnosticism: I do not know, or it cannot be known. Deism: God exists, but He never revealed anything."),
            .longOnly(.text("The goal is never to mock an objection. It is to understand it well enough to state it in a way its holder would accept, and then to answer it better than the alternatives do. That is the adab the Quran commands in every argument about faith (16:125), and it is also simply good thinking: an answer to a caricature answers nobody. The Prophet Muhammad (peace and blessings be upon him) was commanded to strive against the deniers with the Quran itself (25:52): with its arguments, recited to them.")),
            .longOnly(.ayah("16:125")),
            .longOnly(.ayah("25:52")),
            .door(.article("AtheismAnswerView")),
            .door(.article("GodPillarView")),
        ]),
        ArticleSection("ATHEISM AND NATURALISM, FAIRLY STATED", [
            .longOnly(.text("Atheism, strictly, is the absence of belief in God. Many atheists say it is not a worldview at all, just a no, and that the burden of proof lies with whoever claims that God exists. Both points are fair as far as they go, and this series has accepted the burden by giving reasons. But everyone has to explain reality somehow, and the explanation most atheists hold is naturalism: the physical world is all there is, and it needs no explanation outside itself. That is a claim too, and it needs support like any other.")),
            .shortOnly(.text("Atheism, strictly, is the absence of belief in God, and many atheists say the burden of proof lies with whoever claims that God exists. This series has accepted the burden by giving reasons. But everyone has to explain reality somehow, and the explanation most atheists hold is naturalism: the physical world is all there is, and it needs no explanation outside itself. That is a claim too, and it needs support like any other.")),
            .longOnly(.text("So the honest comparison is between two explanations, set side by side on six questions:")),
            .longOnly(.bullet("**Why does anything exist?** Naturalism: it just does, as a brute fact, or the universe is somehow necessary. Theism: a necessary Creator willed it.")),
            .longOnly(.bullet("**Why these life-permitting constants?** Naturalism: chance, or a multiverse no one has observed. Theism: they were chosen.")),
            .longOnly(.bullet("**Why can the universe be understood in mathematics?** Naturalism: no explanation is offered. Theism: it comes from a Mind.")),
            .longOnly(.bullet("**Why is there consciousness?** Naturalism: an open hard problem. Theism: minds come from a living, knowing source.")),
            .longOnly(.bullet("**Why trust our reasoning?** Naturalism: it was selected for survival, not for truth. Theism: it was given to us to track the truth (16:78).")),
            .longOnly(.ayah("16:78")),
            .longOnly(.bullet("**Why are moral duties binding?** Why is it actually wrong, not merely unpopular, to torture a child for fun? Naturalism: social evolution and preference. Theism: an objective moral order grounded in the Creator.")),
            .longOnly(.text("An honest naturalist will often reply that we don’t know yet. That is an honest thing to say. But “we don’t know” is not an explanation; it is the absence of one. When one view explains all six and the other explains none, the question is which is more reasonable. The Quran says of the ancient materialists, who held that nothing destroys us but time, that they had no knowledge of it and were only guessing (45:24).")),
            .longOnly(.ayah("45:24")),
            .shortOnly(.text("So the honest comparison is between two explanations, set side by side on six questions: why anything exists, why the constants permit life, why the universe can be understood in mathematics, why there is consciousness, why our reasoning can be trusted, and why moral duties bind. Theism answers each from a necessary, living, knowing Creator; naturalism answers with a brute fact, with chance, or not at all.")),
            .shortOnly(.text("An honest naturalist will often reply that we don’t know yet. That is an honest thing to say. But “we don’t know” is not an explanation; it is the absence of one. When one view explains all six and the other explains none, the question is which is more reasonable.")),
        ]),
        ArticleSection("WHO CREATED GOD?", [
            .text("This is the first question most sceptics ask, and it rests on a misreading. The argument never said that everything needs a cause. It said that dependent things, things that begin or could have failed to exist, need one. A necessary being depends on nothing by definition, so asking what caused it is like asking the name of a bachelor’s wife. And if the First Cause had a cause, it would not be first, and the question would only restart the endless chain of borrowers the second domino ruled out."),
            .longOnly(.text("Every worldview stops somewhere. The naturalist stops at a universe that simply is, with no explanation. The theist stops at a necessary Creator whose nature is to exist. The question is not whether one stops but which stopping point makes sense: a contingent universe that cannot explain itself, or a necessary being who explains everything else.")),
            .text("The Prophet (peace be upon him) foretold that the question would come, and taught what to do with it:"),
            .hadith("bukhari:3276", cite: "Sahih al-Bukhari 3276, Sahih Muslim 134", arabic: 31...50, english: [4...40]),
            .text("This is not a ban on thinking. It is the recognition that the chain has reached a question with no sense in it, the impossible regress of makers that reason itself rejects, and the right response is to stop following it."),
            .door(.article("ProvingGodView")),
        ]),
        ArticleSection("THE MULTIVERSE AND THE GAPS", [
            .longOnly(.text("Two objections lean on science. The first is the multiverse: perhaps there are countless universes with every possible set of constants, and we inevitably find ourselves in one that allows us. It is a serious hypothesis, held by serious physicists. But there is no observational evidence yet for any other universe; a mechanism that generates universes would itself need finely set laws, which moves the question back a step; and a multiverse, however large, is still made of dependent things, so the first domino applies to it exactly as it applies to ours.")),
            .longOnly(.text("The second is the charge of a God of the gaps: science will one day explain all this, and believers are only filling the holes in present knowledge with God. A gaps argument does say: we don’t know, so God. The dominoes say something different. We do know that dependent things need an explanation outside themselves, we do know that chance is not a cause, and we do know that minds come from minds. Those are not gaps; they are what we have learned. Science studies how things inside the universe behave, and it does that superbly. Why there is a universe at all is a different kind of question, and the more science learns about the universe’s beginning and its constants, the sharper that question becomes.")),
            .shortOnly(.text("Two objections lean on science. The multiverse is a serious hypothesis, but there is no observational evidence yet for any other universe; a mechanism that generates universes would itself need finely set laws; and a multiverse, however large, is still made of dependent things. The charge of a God of the gaps misreads the dominoes: we do know that dependent things need an explanation outside themselves, that chance is not a cause, and that minds come from minds. Those are not gaps; they are what we have learned.")),
        ]),
        ArticleSection("IF GOD EXISTS, WHY SUFFERING?", [
            .longOnly(.text("This is the most human of the objections, and it deserves its strongest form. The philosopher J. L. Mackie argued in 1955 that an all-powerful and wholly good God would eliminate evil, so the existence of evil shows there is no such God. Later philosophers, such as William Rowe in 1979, made a more modest claim: some suffering seems pointless, like a fawn dying slowly in a forest fire that no one sees, and that is evidence against God even if it is not proof.")),
            .shortOnly(.text("This is the most human of the objections, and it deserves its strongest form. An all-powerful and wholly good God, the philosopher J. L. Mackie argued, would eliminate evil; later philosophers made a more modest claim, that some suffering seems pointless, and that this is evidence against God even if it is not proof.")),
            .text("Notice first what the objection questions: God’s goodness or His purposes, not His existence. The contingency argument still stands, and so does the Creator it reaches. Notice too what the complaint assumes. To call suffering evil, something that ought not to be, is to appeal to a standard of good beyond the world. If there is no God, there is pain, but nothing that ought to be otherwise, and nobody to whom the complaint can be made."),
            .text("Islam’s answer begins with what this life is for. It is not paradise; it is a test, and the test has an end:"),
            .ayah("67:2", words: 0...7),
            .longOnly(.ayah("21:35")),
            .longOnly(.text("A test is not cruelty, and its outcome is not settled in this world. The Lord who tests has forbidden injustice to Himself:")),
            .longOnly(.hadith("muslim:2577", cite: "Sahih Muslim 2577", arabic: 49...60, english: [0...21])),
            .longOnly(.text("The same hadith ends with the promise that every deed is recorded and repaid, so that whoever finds good should praise Allah, and whoever finds otherwise should blame no one but himself. Every wrong that goes unpunished here is answered there, perfectly. And for the believer, nothing that befalls him is wasted:")),
            .longOnly(.hadith("muslim:2999", cite: "Sahih Muslim 2999", arabic: 39...64, english: [0...73])),
            .longOnly(.text("What looks pointless from inside a single life may not be pointless in fact. When al-Khidr damaged a poor family’s boat, killed a boy, and rebuilt a wall in a town that had refused them food, Musa (peace be upon him) could not bear it, until he was shown what lay behind each act:")),
            .longOnly(.ayah("18:79-82")),
            .longOnly(.text("Not every reason will be shown to us in this world, but a creature who cannot see the reasons is not entitled to conclude that there are none. The subject deserves its own long study, and the series does not pretend to settle it in a few paragraphs. The point for this domino is that suffering does not touch the argument that a Creator exists.")),
            .shortOnly(.text("A test is not cruelty, and its outcome is not settled in this world. Every deed is recorded and repaid, and every wrong that goes unpunished here is answered there, perfectly.")),
            .shortOnly(.text("Not every reason will be shown to us in this world, but a creature who cannot see the reasons is not entitled to conclude that there are none. The point for this domino is that suffering does not touch the argument that a Creator exists.")),
            .door(.article("QadarView")),
        ]),
        ArticleSection("AGNOSTICISM: THE WAITING ROOM", [
            .longOnly(.text("The biologist Thomas Henry Huxley coined the word agnostic in 1869 for a position he thought more honest than either belief or denial: I do not know. Some agnostics go further and say that God cannot be known. There is real honesty in the first form. Nobody should pretend to know what he does not.")),
            .shortOnly(.text("The biologist Thomas Henry Huxley coined the word agnostic in 1869 for the position “I do not know.” Some agnostics go further and say that God cannot be known.")),
            .text("But agnosticism is not a third explanation alongside theism and naturalism. It does not explain why anything exists, why the universe is finely set, or why anyone is conscious. It describes the person, not the universe, and the universe is still either self-explaining or not. The stronger form, that God cannot be known, is itself a large claim to knowledge: it claims to know enough about God, or about the limits of every possible kind of evidence, to rule out ever knowing Him."),
            .longOnly(.text("So the real question for an agnostic is this: having seen the evidence, which way does it lean? A person can feel uncertain while the evidence still points somewhere. A jury does not need a confession to reach a verdict; it looks at the evidence and asks which explanation fits. And it is fair to ask, gently: what would it take for you to know? The Quran’s invitation to the honest agnostic is not to believe blindly. It is to stand up sincerely, with a friend or alone, and think:")),
            .longOnly(.ayah("34:46", words: 1...11)),
            .shortOnly(.text("So the real question for an agnostic is this: having seen the evidence, which way does it lean? A jury does not need a confession to reach a verdict; it looks at the evidence and asks which explanation fits.")),
        ]),
        ArticleSection("WHY IS HE NOT MORE OBVIOUS?", [
            .longOnly(.text("A subtler objection was set out by the philosopher J. L. Schellenberg in Divine Hiddenness and Human Reason (1993). A perfectly loving God, he argued, would make a relationship with Himself available to everyone who is not resisting Him. Yet there seem to be sincere people who do not believe, through no fault of their own. So, he concluded, there is probably no such God.")),
            .longOnly(.text("Islam agrees with more of the first premise than the argument expects: Allah has not hidden Himself from anyone. He placed knowledge of Him in every soul (30:30, 7:172), set His signs in the horizons and in ourselves (41:53), and sent a warner to every nation (35:24).")),
            .longOnly(.ayah("30:30")),
            .longOnly(.ayah("7:172", words: 12...16)),
            .longOnly(.ayah("41:53")),
            .longOnly(.ayah("35:24")),
            .shortOnly(.text("A subtler objection was set out by the philosopher J. L. Schellenberg: a perfectly loving God would make a relationship with Himself available to everyone who is not resisting Him, yet there seem to be sincere people who do not believe through no fault of their own, so there is probably no such God.")),
            .shortOnly(.text("Islam agrees with more of that premise than the argument expects: Allah has not hidden Himself from anyone. He placed knowledge of Him in every soul, set His signs in the horizons and in ourselves, and sent a warner to every nation.")),
            .text("The real question is not whether He can be known, but why He does not appear so plainly that no one could deny Him. The answer is that this life is a test of faith in the unseen, and the Quran praises exactly those who believe in what they have not seen:"),
            .ayah("2:2-3", words: 7...9),
            .longOnly(.text("If the angels came down in plain sight, or the great signs of the Last Day arrived, belief would no longer be a choice, and the test would be over:")),
            .longOnly(.ayah("6:158", words: 14...32)),
            .longOnly(.text("As for the person who truly never received the message, Allah does not punish anyone before a messenger has reached him:")),
            .longOnly(.ayah("17:15", words: 15...20)),
            .longOnly(.text("The scholars of the Sunnah hold that such a person will be tested on the Day of Resurrection, and the judgment of every individual belongs to Allah, who knows what reached each heart and what that heart did with it. The sincere seeker, meanwhile, is promised guidance for his striving (29:69).")),
            .longOnly(.ayah("29:69")),
        ]),
        ArticleSection("DEISM: A MAKER WHO NEVER SPEAKS", [
            .longOnly(.text("Deism grew in Europe in the seventeenth and eighteenth centuries among thinkers who believed in a Creator but distrusted every claim to revelation. Its best-known voice, Thomas Paine, wrote in The Age of Reason (1794) that the word of God is the creation we behold: God speaks through nature alone, never through a book or a prophet. The deist’s God made the world, set its laws in motion, and stepped back, like a watchmaker who builds a perfect watch and then throws away the manual.")),
            .shortOnly(.text("Deism grew in Europe in the seventeenth and eighteenth centuries among thinkers who believed in a Creator but distrusted every claim to revelation. The deist’s God made the world, set its laws in motion, and stepped back, like a watchmaker who builds a perfect watch and then throws away the manual.")),
            .text("Here is the striking thing. A deist accepts everything in Part 1: something exists, it rests on a necessary source, that source is an intelligent Creator, and He is one. So the only question left is the biggest one. This Creator made beings who can reason, who feel the weight of moral obligation, and who lie awake asking why they are here. Would He build creatures to ask that question and never answer it? Would the One who measured out a universe for life leave that life with no idea what it is for?"),
            .longOnly(.text("Fourteen hundred years before deism had a name, the Quran gave its verdict on the claim at its heart:")),
            .longOnly(.ayah("6:91", words: 0...13)),
            .longOnly(.text("To say that God never speaks is to underestimate who God is. And the Lord the Quran describes is the opposite of absent: He is near, and He answers.")),
            .longOnly(.ayah("2:186", words: 0...10)),
            .longOnly(.hadith("bukhari:1145", cite: "Sahih al-Bukhari 1145, Sahih Muslim 758", arabic: 35...60, english: [5...68])),
            .longOnly(.text("But that is to answer the deist from the Quran, and the Quran’s authority is exactly what he does not yet accept. So Part 1 does not resolve deism; it raises it and leaves it standing, because it is the bridge to everything that follows. Does man think he will be left without purpose (75:36)? If a wise Creator made rational, moral beings who ask why they exist, would He leave them without guidance? Did God speak?")),
            .shortOnly(.text("So Part 1 does not resolve deism; it raises it and leaves it standing, because it is the bridge to everything that follows. Does man think he will be left without purpose (75:36)? If a wise Creator made rational, moral beings who ask why they exist, would He leave them without guidance? Did God speak?")),
            .ayah("75:36"),
            .door(.article("DominoRevelationView")),
        ]),
        ArticleSection("THREE MINUTES TO A CREATOR", only: .long, [
            .text("An argument becomes one’s own only when it has been used. Part 1’s exercise is done in pairs, and it takes its cue from the Quran’s invitation to stand for Allah in pairs and alone and think (34:46)."),
            .step("1. **Pair up.** One person plays a thoughtful sceptic, fair and not trolling, and opens with: “I don’t believe in God. Why should I?”"),
            .step("2. **Three minutes.** The other walks from existence to one intelligent Creator, domino by domino."),
            .step("3. **One push per domino.** The sceptic pushes back once at each step with a real objection: who created God, maybe the universe itself is the necessary thing, maybe it is all chance."),
            .step("4. **Switch.** Trade roles for another three minutes."),
            .step("5. **Debrief.** Which domino was hardest to explain? Which objection was hardest to answer? Which analogy worked? The borrowed book and the train with no engine usually land best."),
            .checklist([
                "Things exist that **did not have to** exist.",
                "Dependent things need an explanation **outside themselves**.",
                "The chain must end in something **necessary and independent**.",
                "It **chose** this universe, so it has will and knowledge.",
                "There can be **only one** ultimate.",
                "Fine-tuning and consciousness **fit this picture**; naturalism struggles with them.",
            ], title: "The Walk in Six Steps", icon: "checkmark.circle.fill"),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Atheism, agnosticism and deism are the three places people most often stop. Naturalism, the usual ground of atheism, leaves existence, fine-tuning, intelligibility, consciousness, reason and morality unexplained, and “we don’t know” is not an explanation. The question of who created God misreads an argument that only ever said dependent things need a cause. The multiverse moves the question back without answering it, and the dominoes are drawn from what science has learned, not from its gaps. Suffering questions God’s purposes, not His existence, and Islam answers it with a test that ends in perfect justice. Agnosticism describes a person, not the universe, and the hiddenness argument meets a Lord who placed knowledge of Himself in every soul and tests faith in the unseen. The deist accepts every domino so far, which leaves one question for Part 2: did God speak?"),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Ghayb", arabic: "غَيب", meaning: "**The unseen**: whatever is hidden from the senses, from the angels to the Hereafter. The Quran praises those who believe in it (2:3), and that belief is at the heart of the test."),
            .term("Ibtila’", arabic: "ابتِلَاء", meaning: "**Testing**, or trial. Allah created death and life to test which of us is best in deed (67:2), and He tests with good and with evil alike (21:35)."),
            .term("Hujjah", arabic: "حُجَّة", meaning: "**A conclusive argument** that leaves no excuse. Allah sent messengers so that mankind would have no argument against Him after them (4:165), and He does not punish before a messenger has come (17:15)."),
            .ayah("4:165"),
            .term("Dahr", arabic: "دَهر", meaning: "**Time**, endless and impersonal. The ancient materialists said that nothing destroys us but time (45:24), the oldest form of the naturalism the Quran answers."),
        ]),
    ]
}

// MARK: - domino-2

struct DominoRevelationView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "DominoRevelationView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Domino 5: Has the Creator Spoken?")
        .englishArticle().selectableArticleList(article: "DominoRevelationView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: Part 1 reached one necessary Creator with knowledge and will, and stopped at the deist’s question: has He ever spoken? He most probably has. A wise Creator who made beings that ask why they exist, feel bound by right and wrong, and long for justice is not the kind of being who stays silent. Reason can find Him, but it cannot tell us His names, His will, or what follows death, and the many rival claims to revelation are a reason to test, not a reason to give up. Revelation is a reasonable expectation, not a debt He owes; and because the claims exist, the next domino tests them."),
        ]),
        ArticleSection("THE QUESTION PART 1 LEFT OPEN", [
            .longOnly(.text("Four dominoes are down. Something exists that did not have to; so something exists that depends on nothing; that source chose this universe over countless possible ones, so it has knowledge and will; and there can be only one such being. A deist agrees with every word of that. The deist’s Creator made the world, set its laws running and stepped back, like a watchmaker who winds the watch and walks away. The view was fashionable among Enlightenment writers such as Voltaire and Thomas Paine, and people still arrive at it for understandable reasons: religions contradict each other, religious institutions have failed people, and “reason is enough” sounds modest and safe.")),
            .shortOnly(.text("Four dominoes are down: something exists that did not have to, it rests on a necessary source with knowledge and will, and there can be only one such being. A deist agrees with every word of that. His Creator made the world, set its laws running and stepped back, like a watchmaker who winds the watch and walks away.")),
            .text("So Domino 5 asks the deist’s own question in the open: did the Creator ever speak? Nothing in the first four dominoes says He is silent. A deist who says He never spoke has not found that in the evidence; he has brought it to the evidence. The question is which is more probable, given the kind of Creator Part 1 found, and it is weighed the way every domino is weighed: not by demanding a proof beyond every possible doubt, which nothing in life has, but by asking which explanation best fits what we know."),
            .longOnly(.text("Deism also has a history worth noticing. As a movement it belonged to the 1700s, and it faded within a century. It never had a scripture, a prayer, a community, or anything to hand on to its children, because a God who never speaks gives people nothing to live by. That proves nothing on its own; a true idea can be unpopular. But it hints at what the argument below shows: deism describes a Creator no one can relate to, and that is not the Creator the first four dominoes found.")),
        ]),
        ArticleSection("A CREATURE THAT ASKS WHY", [
            .text("Look at what the Creator made. Human beings reason, choose, feel bound by duties they did not invent, and ask a question no other creature on earth asks: why am I here? Nothing complex that we build is without a purpose. A Creator who set the constants of the universe within the narrow ranges that rational life needs very plausibly had a purpose for that life, and if He has a purpose for us, it is reasonable to expect Him to tell us what it is. A purpose that is never disclosed cannot be lived."),
            .text("The Quran puts the same argument as a question to reason, not as a demand for faith:"),
            .ayah("23:115"),
            .longOnly(.text("It rejects the picture of a world made for nothing in so many words, and it calls that picture an assumption, which is exactly what the deist’s silence is:")),
            .longOnly(.ayah("38:27", words: 0...10)),
            .longOnly(.text("It names the purpose plainly: the jinn and mankind were created to worship Allah (51:56), and death and life were created as a test of who is best in deed (67:2).")),
            .longOnly(.ayah("51:56")),
            .longOnly(.ayah("67:2")),
            .text("And it turns the deist’s question back on him:"),
            .ayah("75:36"),
            .longOnly(.markdown("The word there, **suda (سُدًى)**, was explained two ways by the early commentators whom Ibn Kathir (may Allah have mercy on him) cites under the ayah: left without being commanded or forbidden, the explanation of Mujahid and ash-Shafi‘i, and left without being raised again, the explanation of as-Suddi. Ibn Kathir says the ayah covers both. Together they describe the deist’s world exactly: no guidance now, and no account afterwards.")),
            .text("These ayat are not offered here as proof. Part 2 cannot use the Quran to prove the Quran, and the next domino builds a test that the Quran itself has to pass. They show something else: the book that claims to be revelation makes the argument from purpose to the listener’s reason, and invites him to judge it."),
        ]),
        ArticleSection("THE BIGGER THE GOD, THE LESS DEISM FITS", [
            .text("Deism suits a small god: limited, distant, perhaps unaware of us or occupied elsewhere. A god like that might make something and wander off. Part 1 did not find a small god. It found the necessary source of everything, who chose this universe with knowledge and will. So ask what such a Creator would have to lack in order to make us and then say nothing."),
            .bullet("**Knowledge?** He would have to be unaware that we need guidance. But the One who created knows what He created, and He is the Subtle, the Acquainted (67:14)."),
            .ayah("67:14"),
            .bullet("**Wisdom?** He would have to make creatures who ask why, and leave the question unanswered on purpose. That is not wisdom; it is waste."),
            .bullet("**Power?** He would have to be unable to speak. But speech costs the One who brought a universe into being nothing at all."),
            .bullet("**Need?** Silence would have to benefit Him somehow. But He is free of every need: He gains nothing by leaving us in the dark, and loses nothing by guiding us."),
            .longOnly(.text("Every perfection Part 1 established makes silence less likely, not more. Deism only works if God is shrunk back down to the small god it began with. The Quran names this very mistake, and it is a mistake about God before it is a mistake about revelation:")),
            .longOnly(.ayah("6:91", words: 0...13)),
            .longOnly(.text("The deist also has to explain two things in us. Every person knows that some things are really wrong, torturing a child for fun among them; wrong by whose standard, if the Creator never said anything? And oppressors die rich and comfortable every day; if no one is ever called to account, justice never arrives. A Creator who measured the universe for life with such care and then has nothing to say about how that life is lived is not a wise Creator. He is an absent one, and nothing in the first four dominoes describes Him that way.")),
            .shortOnly(.text("Every perfection Part 1 established makes silence less likely, not more. Deism only works if God is shrunk back down to the small god it began with.")),
        ]),
        ArticleSection("WHAT REASON CANNOT REACH", [
            .longOnly(.text("The deist’s strongest card is that reason is enough. Reason did a great deal in Part 1: it found that a Creator exists, that He is one, that He has knowledge, will and power, and that He depends on nothing. Muslims agree that this much lies within reach of a sound mind and of the fitrah, the natural disposition toward its Creator with which every child is born (Sahih al-Bukhari 1385).")),
            .longOnly(.hadith("bukhari:1385", cite: "Sahih al-Bukhari 1385", arabic: 31...49, english: [0...44])),
            .shortOnly(.text("The deist’s strongest card is that reason is enough. Reason did a great deal in Part 1: it found that a Creator exists, that He is one, that He has knowledge, will and power, and that He depends on nothing.")),
            .text("But reason cannot give us His names. It cannot tell us what He wants from us, how He is to be worshipped, or what happens after death and on what terms. A house tells you that an architect exists and that she is skilled; it does not tell you her name, or what she asks of the people who live in it, unless she tells you. Reason has also had twenty-five centuries of philosophers to settle these questions on its own, and they still disagree on nearly every one. If reason alone were enough, we would expect more agreement by now."),
            .longOnly(.text("The scholars of the Sunnah drew the line in the same place. Reason and the fitrah recognise the Creator, and the goodness of justice and truthfulness in general terms; the details of how He is worshipped, and the news of the unseen, come only through messengers. Ibn Taymiyyah (may Allah have mercy on him) described the need for them in the strongest terms:")),
            .longOnly(.quote(text: "“The message is a necessity for the servants; they cannot do without it, and their need of it is above their need of anything. The message is the spirit of the world, its light and its life: what good can there be in the world if it loses the spirit, the life and the light?” (Ibn Taymiyyah, Majmu‘ al-Fatawa 19/99)", arabic: "وَالرِّسَالَةُ ضَرُورِيَّةٌ لِلعِبَادِ لَا بُدَّ لَهُم مِنهَا، وَحَاجَتُهُم إِلَيهَا فَوقَ حَاجَتِهِم إِلَى كُلِّ شَيءٍ، وَالرِّسَالَةُ رُوحُ العَالَمِ وَنُورُهُ وَحَيَاتُهُ، فَأَيُّ صَلَاحٍ لِلعَالَمِ إِذَا عَدِمَ الرُّوحَ وَالحَيَاةَ وَالنُّورَ", dimmed: true)),
            .longOnly(.text("His student Ibn al-Qayyim (may Allah have mercy on him) opens Zad al-Ma‘ad on the same note: people need to know the Messenger and what he brought more than they need anything else, because there is no way to success in this world or the next except at the hands of the messengers.")),
            .longOnly(.text("This is also why the Quran ties accountability to the message rather than to reason alone. Allah does not punish a people until a messenger has come to them (17:15), and He sent the messengers so that no one would have an argument against Him afterwards:")),
            .longOnly(.ayah("4:165")),
            .longOnly(.ayah("17:15")),
            .shortOnly(.text("The scholars of the Sunnah drew the line in the same place. Reason and the fitrah recognise the Creator, and the goodness of justice and truthfulness in general terms; the details of how He is worshipped, and the news of the unseen, come only through messengers.")),
        ]),
        ArticleSection("BUT THE RELIGIONS CONTRADICT EACH OTHER", [
            .text("The deist’s second card is the disagreement of the religions. Every religion claims revelation, they contradict one another, and so, he says, none of them comes from God. The premise is true. The conclusion does not follow from it. If ten students give ten different answers to a mathematics problem, they cannot all be right, but no teacher concludes that the problem has no answer. And nobody forges a currency that does not exist; counterfeits are a sign that something real is worth copying."),
            .longOnly(.text("The Quran in fact expects the disagreement. Its account of history is that people began as one community, that Allah sent prophets with scripture to judge between them, and that those who received the scripture then disputed it among themselves, out of rivalry, after the clear proofs had come to them:")),
            .longOnly(.ayah("2:213", words: 0...31)),
            .longOnly(.text("On that account, a world crowded with conflicting claims to revelation is exactly what we should expect: one message, sent again and again, then altered, imitated or forgotten between its messengers. Whether that account is true is what the next domino tests. But the existence of rival claims cannot show that God never spoke. It shows that the claims have to be sorted, and the honest response to a crowded market is to inspect the goods, not to walk out with nothing.")),
            .shortOnly(.text("The existence of rival claims cannot show that God never spoke. It shows that the claims have to be sorted, and the honest response to a crowded market is to inspect the goods, not to walk out with nothing.")),
        ]),
        ArticleSection("HOW WOULD THE CREATOR SPEAK?", [
            .longOnly(.text("If the Creator speaks to humanity, how would He do it? The Quran describes three ways in which Allah speaks to a human being: by inspiration, from behind a veil as He spoke to Musa (peace be upon him), or by sending an angel who conveys what He wills:")),
            .longOnly(.ayah("42:51")),
            .longOnly(.text("In every case the message reaches everyone else through a human messenger, and the Quran records the objection that has always been raised against that, with its answer. A messenger to human beings has to be one of them, someone they can live beside, question and follow; had the earth been home to angels, an angel would have been sent:")),
            .longOnly(.ayah("17:94-95")),
            .longOnly(.text("This matters for the test that comes next. A message carried by a human being can be examined: his life before his claim, his motives, whether he kept his word, whether what he foretold came true. A message meant for people after him has to outlive him, so we can ask whether it was preserved. And a Creator who made every people would be expected to address every people. The Quran claims exactly that: no nation was left without a warner (35:24), and every messenger brought the same call, to worship Allah and shun every false object of worship (16:36). Each of these expectations becomes one of the tests of Domino 6.")),
            .longOnly(.ayah("35:24")),
            .longOnly(.ayah("16:36")),
            .shortOnly(.text("If the Creator speaks to humanity, His message reaches everyone else through a human messenger, and that matters for the test that comes next. A message carried by a human being can be examined: his life before his claim, his motives, whether he kept his word, whether what he foretold came true. A message meant for people after him has to outlive him, so we can ask whether it was preserved. And a Creator who made every people would be expected to address every people. Each of these expectations becomes one of the tests of Domino 6.")),
        ]),
        ArticleSection("REASONABLE, NOT OWED", [
            .longOnly(.text("One word needs care here. It is tempting to say that God must send revelation. That is a bigger leap than any other domino, and it is not what the scholars of the Sunnah say. Allah owes His creatures nothing, and a creature’s reasoning makes nothing binding on Him; that was the claim of the Mu‘tazilah, who held that reason obliges Allah to do what is best for His servants. What Allah has made binding on Himself, He bound Himself to by His own word, as when He says that your Lord has decreed mercy upon Himself (6:54).")),
            .longOnly(.ayah("6:54")),
            .longOnly(.text("In a hadith qudsi the Prophet Muhammad (peace and blessings be upon him) relates that Allah says:")),
            .longOnly(.hadith("muslim:2577a", cite: "Sahih Muslim 2577", arabic: 49...69, english: [0...45])),
            .longOnly(.text("Guidance there is a gift He invites His servants to ask for, not a debt He pays, and the same hadith goes on to say that His servants can neither harm Him nor benefit Him. The message is sent for their sake, not His.")),
            .shortOnly(.text("One word needs care here. It is tempting to say that God must send revelation, but that is not what the scholars of the Sunnah say. Allah owes His creatures nothing, and a creature’s reasoning makes nothing binding on Him; that was the claim of the Mu‘tazilah. What Allah has made binding on Himself, He bound Himself to by His own word.")),
            .text("So the claim of Domino 5 is modest, and for that reason hard to knock down. Given a Creator who is wise, who made beings with purpose, a conscience and a hunger for justice, revelation is the reasonable expectation, and a Creator who stays silent is the strange one. Nor does the expectation have to be argued in the abstract, because the world is full of claims that He did speak: through a book, through a prophet, through an inner light. The honest response is neither to accept them all nor to reject them all, but to test them."),
            .longOnly(.text("That test has to be fair to everyone, Islam included. The Quran says of itself that Allah sent it down and will guard it (15:9), but a book’s claim about itself is not evidence for itself. So the next chapter builds the test first, before any religion is named, so that everyone agrees on it before anyone knows whom it favours.")),
            .longOnly(.ayah("15:9")),
            .callout("Revelation is possible; it is what a wise Creator of creatures who ask “why?” would be expected to give; and many claim to have received it. Domino 5 falls. The next question is which claim, if any, is true.", title: "Domino 5 Falls", icon: "checkmark.seal.fill"),
            .door(.article("DominoTestView")),
        ]),
        ArticleSection("COMMON QUESTIONS", only: .long, [
            .markdown("**If revelation matters so much, why did it reach only some people?**"),
            .text("The Quran’s claim is the reverse: there was no nation without a warner (35:24), and every messenger was sent with the same call (21:25). What reached a particular people at a particular time is a separate question from whether God spoke, and the Quran answers it with justice: no one is punished before a messenger comes (17:15). Ibn Kathir, under that ayah, gathers the narrations about those whom the message never reached and favours the view that they will be tested on the Day of Resurrection, saying that it reconciles all the evidence and that al-Ash‘ari reported it from Ahl as-Sunnah. The judgement of individuals belongs to Allah alone."),
            .ayah("21:25"),
            .markdown("**Could God have spoken only through nature?**"),
            .text("Nature tells us that He is, and that He is powerful, knowing and wise; that is exactly what Part 1 drew from it. It does not tell us what He wants, which is the one question a creature with a conscience cannot avoid. The Quran uses one word, ayat, signs, both for the features of creation (3:190) and for its own verses: the first point to the Author, and the second tell us what He said."),
            .ayah("3:190"),
            .markdown("**Is it not arrogant to think the Creator would address creatures like us?**"),
            .text("It would be, if we had invented the question. We did not; He made us able to ask it. A creature that can ask its Maker why it exists is itself a sign that the Maker meant it to hear an answer. And the Quran presents the sending of messengers as a mercy, not as a compliment to human beings: the last of them was sent as a mercy to the worlds (21:107)."),
            .ayah("21:107"),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("A deist accepts the first four dominoes and denies the fifth, but his denial is an assumption, not a finding. A Creator with knowledge, wisdom and power, who made beings that ask why they exist, feel bound by right and wrong and long for justice, is far more likely to have spoken than to have stayed silent. Reason finds Him but cannot tell us His names, His will or what follows death; the disagreement of the religions shows that the claims must be sorted, not that none is true. Revelation is a reasonable expectation and a mercy, not a debt, and since the claims exist, the next step is to test them fairly."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Wahy", arabic: "وَحي", meaning: "**Revelation**: from a root meaning a swift and hidden communication. The Quran names three ways Allah speaks to a human being: by inspiration, from behind a veil, or through an angel sent with His words (42:51)."),
            .term("Risalah", arabic: "رِسَالَة", meaning: "The **message** a messenger (rasul) is sent with. The scholars of the Sunnah held that people need it above every other need, because how Allah is worshipped, and the unseen, are known only through it."),
            .term("Suda", arabic: "سُدًى", meaning: "**Left neglected** (75:36): left without command and prohibition, or without being raised again. The word answers the deist’s picture of a Creator who made man and left him to himself."),
            .term("Hujjah", arabic: "حُجَّة", meaning: "A **proof or argument** that settles a case. Allah sent messengers so that people would have no hujjah against Him afterwards (4:165): accountability follows the message."),
        ]),
    ]
}

struct DominoTestView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "DominoTestView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Domino 6: Testing Every Claim")
        .englishArticle().selectableArticleList(article: "DominoTestView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: if the Creator has spoken, a fair test should show where. The test is built before any religion is named, from what the earlier dominoes established: a true revelation describes God as reason found Him, agrees with itself, reached us intact through a credible messenger, and speaks to all humanity as final guidance. Run fairly, it removes the traditions with no Creator at the centre, the many gods, the religions of one people and the newer prophets, each described as its own followers would describe it. Islam faces the same questions and passes them on its own evidence, and one serious claimant is left: Christianity."),
        ]),
        ArticleSection("BUILD THE TEST BEFORE NAMING ANYONE", [
            .text("Before naming a single religion, ask the question that decides everything else: if God really revealed guidance to humanity, what would we expect it to look like, and what would make us suspicious? Agreeing on the answer first matters, because a test built after the verdict is known is not a test. Every item below comes from a domino already down, not from any religion’s own scripture."),
            .checklist([
                "**Theology.** Does it describe God as reason already found Him: one, necessary, independent, living, knowing, and distinct from what He made?",
                "**Coherence.** Does the message agree with itself?",
                "**History and preservation.** Can it be traced to a real messenger in history, and do we know what he actually said?",
                "**The messenger.** Is there good reason to trust the one who claimed revelation: his character, his motives, his consistency?",
                "**Universality and finality.** Does it claim to be guidance for all people and the last word, and is it actually addressed to all of them?",
                "**Reach.** Could an ordinary, sincere person meet its core and understand it, and has it lasted?",
            ], title: "Six Questions for Any Revelation", icon: "checklist"),
            .longOnly(.text("No single test decides. Preservation, for example, is necessary but not sufficient: the chanting of the Vedas kept their hymns with remarkable precision for millennia, and UNESCO lists that tradition as part of humanity’s heritage, yet a well-kept text can still fail the other tests. What we are looking for is a claimant that passes all of them.")),
            .longOnly(.text("Two rules from the start of the series govern how the test is run. Every tradition is described the way its own followers would describe it, so that one of them reading the description would nod before reaching the questions. And nothing wins by default: if every other claim failed and Islam had no evidence of its own, the honest answer would be that we do not know. Islam goes through the same questions as everyone else.")),
            .shortOnly(.text("Every tradition is described the way its own followers would describe it, and nothing wins by default: Islam goes through the same questions as everyone else.")),
        ]),
        ArticleSection("A SEVENTH-CENTURY CHECKLIST", only: .long, [
            .text("Weighing a prophetic claim with reason is not a modern idea. Near the opening of Sahih al-Bukhari stands the Byzantine emperor Heraclius, a Christian with no reason to favour the Prophet Muhammad (peace and blessings be upon him), questioning Abu Sufyan, then still one of the Prophet’s fiercest enemies and later a Companion (may Allah be pleased with him), who admitted afterwards that he would have lied had he not feared his companions exposing him. The emperor asked about the claimant’s family; whether anyone among them had made the same claim before him; whether any of his ancestors had been a king; whether the nobles or the weak followed him; whether his followers were increasing; whether any left his religion out of displeasure with it; whether he had ever been accused of lying; whether he broke his word; how the wars with him had gone; and what he commanded."),
            .text("Each question tested a motive or a pattern. Then Heraclius gave his reasoning, answer by answer:"),
            .hadith("bukhari:7", cite: "Sahih al-Bukhari 7", arabic: 285...438, english: [506...629, 748...766, 817...833]),
            .text("A man who had never lied about people would not begin by lying about God; a man with no throne in his family was not reclaiming one; the weak are the followers of the messengers in every age; and a faith that no one leaves in disappointment has entered the heart. Those are tests of the messenger, and they are the tests the Quran itself invites when it has him say that he had lived among his people a whole lifetime before the revelation came (10:16)."),
            .ayah("10:16"),
        ]),
        ArticleSection("WITH NO CREATOR AT THE CENTRE", [
            .longOnly(.text("Some of the world’s great traditions do not place a Creator at the centre at all. Most schools of Buddhism teach liberation from suffering through insight and ethical discipline, with no creator God, and some early Buddhist texts, such as the Brahmajala Sutta, treat belief in a creator as a mistaken view. Jainism teaches an eternal, uncreated universe. Taoism centres on the Tao, an impersonal way or principle behind things, and Confucianism is above all an ethic of family, virtue and social order.")),
            .longOnly(.text("Their ethics are not the issue; much in them is admirable. Their account of ultimate reality is. Buddhism’s teaching of dependent origination, that everything arises in dependence on other things, is close to Domino 1. But a beginningless chain of dependent things still needs an explanation, just as a train of a million carriages with no engine does not move, however long it is. These traditions stop at Domino 2.")),
            .longOnly(.text("Many of their own followers would add that these are ways of life more than religions in the sense being tested here: they teach how to live, not what a Creator has said. That is fair, and it settles the matter for Domino 6. Where there is no God at the centre, there is no revelation from God to test. Some Buddhist schools and religious Taoism do honour many deities, and those meet the next question instead.")),
            .shortOnly(.text("Some of the world’s great traditions do not place a Creator at the centre at all: most schools of Buddhism, Jainism, Taoism and Confucianism. Their ethics are not the issue; much in them is admirable. Their account of ultimate reality is: a beginningless chain of dependent things still needs an explanation, so these traditions stop at Domino 2. And where there is no God at the centre, there is no revelation from God to test.")),
            .door(.article("BuddhismAnswerView")),
        ]),
        ArticleSection("MANY GODS, AND THE QUESTION OF WORSHIP", [
            .longOnly(.text("The next question is whether a tradition worships one God alone, and here it helps to tell two words apart. A god with a small g is a character inside the story. Zeus was born to Kronos, who swallowed his own children; he fought his way to the top and divided the world with his brothers Poseidon and Hades. Osiris was killed and torn apart. The Norse gods expect to die at Ragnarok, Odin and Thor among them. Run such gods through Part 1: what is born began, and needs a cause; what is limited and at war with its rivals is contingent, more creation, only larger. God with a capital G is the Author of the story, the one Creator who depends on nothing, whom the Hebrew Bible calls by the name Yahweh and whom Arabic-speaking Christians, Jews and Muslims alike call Allah.")),
            .longOnly(.text("The old gods of Greece, Rome, Egypt and Scandinavia are, apart from small modern revivals, no longer living religions, and Domino 4 had already removed them. But many polytheists in history did not believe in many equal creators at all. They accepted one supreme Creator, as the Quraysh of Makkah did:")),
            .shortOnly(.text("The next question is whether a tradition worships one God alone. The gods of the old mythologies, born, limited and at war with their rivals, are more creation, only larger, and Domino 4 had already removed them. But many polytheists in history did not believe in many equal creators at all. They accepted one supreme Creator, as the Quraysh of Makkah did:")),
            .ayah("29:61"),
            .longOnly(.text("Their error lay in worship, not in naming the Creator. They directed worship to intermediaries, and defended it:")),
            .longOnly(.ayah("39:3", words: 4...15)),
            .longOnly(.markdown("So the conclusion of Part 1 is only half of the matter. Believing that there is one Creator is **tawhid ar-rububiyyah (تَوحِيدُ الرُّبُوبِيَّةِ)**, the oneness of His lordship; worshipping Him alone is **tawhid al-uluhiyyah (تَوحِيدُ الأُلُوهِيَّةِ)**, and it was the call of every messenger. The same question meets Shinto’s kami and the spirits and ancestors of many folk religions: worship given to beings other than the one Creator. If there is only one ultimate, worship belongs to Him alone.")),
            .shortOnly(.markdown("Their error lay in worship, not in naming the Creator. Believing that there is one Creator is **tawhid ar-rububiyyah**, the oneness of His lordship; worshipping Him alone is **tawhid al-uluhiyyah**, and it was the call of every messenger. If there is only one ultimate, worship belongs to Him alone.")),
            .door(.article("PaganismAnswerView")),
        ]),
        ArticleSection("HINDU TRADITIONS, DESCRIBED ACCURATELY", [
            .longOnly(.text("Hindu traditions are not one religion with one creed, and a fair account has to begin there. Their scriptures include the Vedas, the Upanishads, the great epics (the Bhagavad Gita is part of the Mahabharata) and the Puranas. Vaishnava and Shaiva devotion worships one supreme God, Vishnu (with avatars such as Rama and Krishna) or Shiva, alongside many lesser devas. Advaita Vedanta, the school of Shankara, teaches that only Brahman is ultimately real, so that the Creator and the creation are not truly distinct. And popular devotion worships through murtis, sacred images that many Hindus understand as a focus for the worship of the divine rather than as gods in themselves.")),
            .longOnly(.text("The questions that follow come from the dominoes, not from caricature. Is the Creator distinct from what He made, and unbound by space and matter, as Domino 2 requires, or does He take bodily form as avatars, or is He finally one with the world? Can He be worshipped through created images, or as one among many, when Domino 4 says there is only one ultimate? And whose message is it? The Hindu scriptures were composed over many centuries by many hands, with no single messenger whose life and message can be examined. Their preservation is real, but preservation alone, as noted above, does not make a revelation.")),
            .longOnly(.text("There is an echo here worth noticing. A famous line of the Rig Veda (1.164.46) says that what is one, the sages call by many names. Muslims are not surprised by such echoes: if every nation received a warner, traces of the one message are to be expected everywhere, overlaid by what came after.")),
            .shortOnly(.text("Hindu traditions are not one religion with one creed. Vaishnava and Shaiva devotion worships one supreme God alongside many lesser devas, Advaita Vedanta teaches that only Brahman is ultimately real, and popular devotion worships through sacred images. The questions come from the dominoes, not from caricature. Is the Creator distinct from what He made, or does He take bodily form, or is He finally one with the world? Can He be worshipped through images, or as one among many? And whose message is it, when the scriptures were composed over many centuries by many hands, with no single messenger whose life can be examined?")),
            .door(.article("HinduismAnswerView")),
        ]),
        ArticleSection("RELIGIONS OF ONE PEOPLE", [
            .text("The third question is whether a message is for everyone. Geographers sort religions into two kinds: universalising religions, addressed to all and open to anyone, and ethnic religions, the heritage or covenant of one people, into which most members are born. Domino 4 bears on the difference. One Creator made every human being, so guidance meant for humanity would be expected to be for all of it, not reserved for one bloodline."),
            .longOnly(.text("An ethnic religion, by its own account, is not claiming that role, and saying so is no insult; it is how these traditions describe themselves. Zoroastrianism today is largely the heritage of the Parsis and of Iran’s Zoroastrians, and most of its communities do not accept converts. The Druze closed their faith to newcomers almost a thousand years ago. One is born a Yazidi. Shinto is bound to the land and people of Japan.")),
            .longOnly(.text("Judaism is the closest of all to Islam on the earlier dominoes and deserves real respect: strict monotheism, one God worshipped alone, and Ibrahim, Musa and the prophets held in common. But Judaism understands itself as the covenant of one people, Israel. It does not seek converts, though it accepts them, and for the rest of humanity it teaches the seven Noahide laws rather than conversion. By its own teaching, then, it does not claim to be the path God requires of all humanity. The Quran honours the Torah as guidance and light (5:44) and presents itself as the confirmation of what came before it and the criterion over it (5:48), so the question between Judaism and Islam is not whether God is one. It is whether prophethood continued after the prophets of Israel.")),
            .longOnly(.ayah("5:44", words: 0...5)),
            .longOnly(.ayah("5:48", words: 4...11)),
            .shortOnly(.text("An ethnic religion, by its own account, is not claiming that role, and saying so is no insult: Zoroastrianism, the Druze faith, the Yazidis and Shinto each belong to one people.")),
            .shortOnly(.text("Judaism is the closest of all to Islam on the earlier dominoes and deserves real respect: strict monotheism, one God worshipped alone, and Ibrahim, Musa and the prophets held in common. But it understands itself as the covenant of one people, Israel, and for the rest of humanity it teaches the seven Noahide laws rather than conversion. So the question between Judaism and Islam is not whether God is one. It is whether prophethood continued after the prophets of Israel.")),
            .door(.article("JudaismAnswerView")),
            .door(.article("ReligionsZoroastrianismView")),
        ]),
        ArticleSection("NEWER PROPHETS AND SMALLER MOVEMENTS", [
            .longOnly(.text("Some traditions came after the Quran and make claims of their own. Sikhism began with Guru Nanak (1469–1539) in the Punjab. It teaches one formless Creator, rejects idols and caste, and gathers the hymns of its Gurus, with some by Hindu and Muslim saints, in the Guru Granth Sahib. It is a sincere monotheism, followed by around twenty-five million people. The questions it faces are those of the messenger and of finality: what sign shows that its founder was sent by God, and how does a revelation nine centuries after the Quran answer the Quran’s claim that prophethood had already ended? Its teaching of rebirth also parts from the single resurrection that the messengers taught.")),
            .longOnly(.text("The Baha’i Faith grew from Iran in the nineteenth century around Baha’u’llah (1817–1892), who taught that God sends a succession of messengers and that he was the latest of them. The Ahmadiyyah follow Mirza Ghulam Ahmad (1835–1908) of the Punjab, who claimed to be the promised Messiah and a prophet. The Nation of Islam, founded in Detroit in 1930, taught that Allah had appeared in the person of a man, W. D. Fard, and that Elijah Muhammad was His messenger; in 1975 Elijah’s son, W. D. Mohammed, led most of its members into Sunni Islam. Every one of these claims has to overrule one ayah of the Quran:")),
            .shortOnly(.text("Some traditions came after the Quran and make claims of their own: Sikhism, a sincere monotheism begun by Guru Nanak in the Punjab; the Baha’i Faith; the Ahmadiyyah; the Nation of Islam. The questions they face are those of the messenger and of finality, and every one of these claims has to overrule one ayah of the Quran:")),
            .ayah("33:40"),
            .text("The scholars of Islam are agreed that the Baha’i and Ahmadi claims place their followers outside Islam, and that God appearing in the form of a man, or a prophet after Muhammad (peace be upon him), is disbelief. That is said plainly and without hostility: the people are owed kindness, and the claims are owed an answer."),
            .longOnly(.text("Beyond these are countless smaller and newer movements, and someone always asks about the ones they have never heard of. A just God holds people to what actually reached them (17:15). That does not prove any small movement false; it means a sincere person is not required to track down every obscure claim, only to weigh honestly the serious ones that reach him. Reach is also a fair test of probability, though never a proof: if the Creator speaks in order to guide humanity, and He governs history, His guidance would be expected to reach humanity and to last. The old gods died out; deism faded within a century; Sikhs are about a third of one percent of the world. Christians and Muslims together are more than half of everyone alive.")),
            .longOnly(.ayah("17:15")),
            .door(.article("ReligionsSikhismView")),
            .door(.article("ReligionsNewProphetsView")),
        ]),
        ArticleSection("ISLAM ON THE STAND", [
            .text("Islam now goes through the same questions, with no favours."),
            .markdown("**Theology.** Its creed fits in four short lines, and they say what reason found in Part 1: one, depended on by everything, depending on nothing, uncaused, and unlike anything else. Domino 7 sets them beside Part 1 line by line."),
            .ayah("112:1-4"),
            .markdown("**Coherence.** The Quran came down over twenty-three years, through persecution, exile, war, peace, grief and government, and it invites anyone to look for its contradictions. It even tells the reader how it could be shown to be human:"),
            .ayah("4:82"),
            .markdown("**Universality and finality.** Every earlier prophet, the Prophet (peace be upon him) said, was sent to his own people, and he was sent to all mankind:"),
            .hadith("bukhari:335", cite: "Sahih al-Bukhari 335", arabic: 74...83, english: [111...128]),
            .longOnly(.text("That claim comes joined to another, which explains what the tour of the religions found. No messenger before him was sent with anything but the same call, that there is no god but Allah, so worship Him (21:25). That is why echoes of one God turn up in so many traditions, under so much that was added later. The final message is one text in a living language, with no priesthood between a person and God, and a core simple enough for a child: the testimony of faith. About a quarter of humanity holds it today, in every ethnicity on earth.")),
            .longOnly(.ayah("21:25")),
            .longOnly(.markdown("**The messenger and the record.** He lived in the full light of history, born in Makkah around 570 CE and buried in Madinah in 632, and a Syriac chronicle written around 640 already records a battle of 634 fought by “the Arabs of Muhammad.” Heraclius’s questions above are the kind his record can answer. Domino 7 examines his character, what he foretold, and the preservation of the Quran in full.")),
            .longOnly(.text("So two claimants are left that make the whole claim: one Creator, a revelation meant for everyone, a real messenger, and a message that reached the world. They are Christianity and Islam. Before they are compared, the bar should be stated, because both will face it. A true religion needs, at the very least, a preserved book with no contradictions. That is necessary, not sufficient: someone could write a short book today, keep it perfectly and never contradict himself, and prove nothing. But failing the bar rules a religion out.")),
            .shortOnly(.markdown("**The messenger and the record.** He lived in the full light of history, born in Makkah around 570 CE and buried in Madinah in 632. Domino 7 examines his character, what he foretold, and the preservation of the Quran in full.")),
            .shortOnly(.text("So two claimants are left that make the whole claim: one Creator, a revelation meant for everyone, a real messenger, and a message that reached the world. They are Christianity and Islam, and both will face the same bar: at the very least, a preserved book with no contradictions. That is necessary, not sufficient, but failing it rules a religion out.")),
            .callout("One tradition has not been touched in this chapter. It is the largest religion in the world. It believes in one Creator, in prophets, in revelation and in judgement; it is universal, and it has reached a third of humanity. And it puts one man at the centre of everything: Jesus. So who was Jesus?", title: "But What About Christianity?", icon: "questionmark.circle.fill"),
            .door(.article("DominoChristianityView")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("A fair test is built before any religion is named, from what the earlier dominoes established: a true revelation describes God as reason found Him, agrees with itself, comes through a credible messenger and a preserved record, and addresses all people as final guidance. Traditions with no Creator at the centre stop at the second domino; the many gods and the worship of intermediaries fail the fourth; Hindu traditions meet the questions of who the Creator is and whose message it is; the religions of one people do not claim to be guidance for all; and the newer prophets must overrule the Seal of the Prophets. Islam passes the same questions on its own evidence, and one serious claimant remains."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Tawhid ar-Rububiyyah", arabic: "تَوحِيدُ الرُّبُوبِيَّةِ", meaning: "Affirming that Allah alone is the **Lord**: the Creator, Owner and Disposer of all things. The Quraysh affirmed it (29:61) and were still idolaters."),
            .term("Tawhid al-Uluhiyyah", arabic: "تَوحِيدُ الأُلُوهِيَّةِ", meaning: "Directing all **worship** to Allah alone: prayer, supplication, sacrifice, reliance and love. It is the call every messenger brought (21:25)."),
            .term("Khatam an-Nabiyyin", arabic: "خَاتَمُ النَّبِيِّينَ", meaning: "The **Seal of the Prophets** (33:40): the last of them, after whom no prophet comes. The Prophet (peace be upon him) likened himself to the last brick that completes a house (Sahih al-Bukhari 3535)."),
            .hadith("bukhari:3535", cite: "Sahih al-Bukhari 3535", arabic: 34...67, english: [0...70]),
            .term("Shirk", arabic: "شِرك", meaning: "**Associating partners with Allah** in His lordship, His worship, or His names and attributes, such as worshipping intermediaries to be brought nearer to Him (39:3)."),
        ]),
    ]
}

struct DominoChristianityView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "DominoChristianityView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Christianity Tested")
        .englishArticle().selectableArticleList(article: "DominoChristianityView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: Christianity deserves to be tested as a well-read Christian would state it, not as a caricature. It confesses one God in three persons and Jesus (peace be upon him) as God incarnate, and it rests that faith on the Bible and the cross. Traced honestly, its creed was defined over centuries and contested at every step; its scripture has no single canon and no original copies; the Trinity is hard to state without contradiction and is not taught by Jesus in his own words; and the four accounts of the crucifixion disagree. The Quran’s Jesus, a messenger raised alive by Allah, fits the evidence better."),
        ]),
        ArticleSection("CHRISTIANITY AS CHRISTIANS DEFINE IT", [
            .text("If Christianity has to be misrepresented to be defeated, it has not been defeated; something Christians do not believe has. So it is stated here as the Catholic, Orthodox and most Protestant churches state it. There is one God, one divine essence, existing eternally as three distinct persons, the Father, the Son and the Holy Spirit, each fully God: not three gods, not three parts of God, and not three roles of one person. The Son took on a full human nature, so that Jesus is one person with two natures, fully God and fully human, as the Council of Chalcedon defined in 451."),
            .longOnly(.text("Christians themselves reject tritheism (three gods), modalism (one person in three roles) and partialism (each person a third of God). The water, ice and steam analogy many Muslims grew up hearing describes modalism, which the churches condemn, so it should not be used for what they believe. Jehovah’s Witnesses, Oneness Pentecostals, biblical Unitarians and Latter-day Saints reject the Nicene Trinity altogether, and a conversation with them begins elsewhere.")),
            .longOnly(.text("Muslims, for their part, often say that Christians worship three gods, that the Trinity is God, Jesus and Mary, or that Nicaea invented the divinity of Jesus. All three are wrong. The Quran commands the better way: argue with the People of the Scripture only in the best manner (29:46), and begin from a word that is equitable between us, that we worship none but Allah (3:64).")),
            .longOnly(.ayah("29:46")),
            .shortOnly(.text("The Quran commands the better way: argue with the People of the Scripture only in the best manner, and begin from a word that is equitable between us, that we worship none but Allah:")),
            .ayah("3:64"),
        ]),
        ArticleSection("THE FIRST GENERATION", [
            .longOnly(.text("Jesus began preaching around 28 to 30 CE. His first followers called their movement the Way (Acts 9:2), their opponents called them “the sect of the Nazarenes” (Acts 24:5), the source of the Arabic nasara, and the name Christians was first used at Antioch (Acts 11:26). Within a few years Paul, who had persecuted the movement, said that the risen Jesus had appeared to him, and his letters, written in the 50s, are the earliest Christian writings that survive. James, the brother of Jesus and head of the church in Jerusalem, was killed in 62 (Josephus, Antiquities 20.200), Rome destroyed the Temple in 70, and the four Gospels were written roughly between 65 and 110.")),
            .longOnly(.text("James led a church whose believers were “all zealous of the law” (Acts 21:20), and his letter says that “by works a man is justified, and not by faith only” (James 2:24, KJV). Paul, who never met Jesus during his ministry, wrote that “a man is not justified by the works of the law” (Galatians 2:16, KJV), and he “withstood” Peter “to the face” at Antioch (Galatians 2:11). Christians read the two as answering different questions, and that deserves a hearing. But Luther called the letter of James “an epistle of straw,” and thirteen of the New Testament’s twenty-seven books carry Paul’s name. Whose understanding of Jesus became Christianity: the Law-keeping church of his brother, or Paul’s?")),
            .longOnly(.text("The Ebionites, Jewish followers of Jesus known from the second century to the fourth, kept to the first. They held to one God, regarded Jesus as a human prophet and Messiah, kept the Law, and rejected Paul as an apostate from it (Irenaeus, Against Heresies 1.26.2). Care is needed: all that is known of them comes from their opponents, and they were not Muslims, for many of them denied the virgin birth that the Quran affirms (3:47). What they show is narrower: some of the earliest followers of Jesus believed him to be a human Messiah, and the church called that a heresy.")),
            .longOnly(.ayah("3:47")),
            .longOnly(.text("Muslim tradition remembers a split of the same shape. Ibn Abbas (may Allah be pleased with him) is reported, with a chain that Ibn Kathir (may Allah have mercy on him) calls sahih up to him, to have said that after Jesus was raised his followers divided three ways, saying that God, or the son of God, or the servant of Allah and His messenger had been among them; the first two joined against the third, and Islam remained effaced until Allah sent Muhammad (peace and blessings be upon him). It is a Companion’s report, not the Prophet’s, and it names the first two parties after churches of later centuries, so it is our tradition’s memory rather than a historian’s document. It fits what the Prophet (peace be upon him) said of the world before him:")),
            .longOnly(.hadith("muslim:2865a", cite: "Sahih Muslim 2865", arabic: 95...108, english: [93...125])),
            .shortOnly(.text("Jesus began preaching around 28 to 30 CE. Within a few years Paul, who had persecuted the movement and never met Jesus during his ministry, said that the risen Jesus had appeared to him, and his letters, written in the 50s, are the earliest Christian writings that survive; the four Gospels were written roughly between 65 and 110. The church in Jerusalem, led by James, the brother of Jesus, was zealous for the Law, and James taught that a man is justified by works and not by faith only; Paul taught that a man is not justified by the works of the law. Christians read the two as answering different questions, and that deserves a hearing. But whose understanding of Jesus became Christianity: the Law-keeping church of his brother, or Paul’s?")),
        ]),
        ArticleSection("COUNCILS AND SPLITS", [
            .longOnly(.text("Nicaea did not invent the belief that Jesus is God: Ignatius of Antioch calls him “our God” around 110, and the governor Pliny reports around 112 that Christians sang a hymn “to Christ, as to a god.” What the councils did was define, over centuries and amid bitter conflict, how the Son relates to the Father. Arius of Alexandria taught that the Son was created; Nicaea (325) declared the Son homoousios, of one essence with the Father, and said of the Spirit only “and in the Holy Spirit”; after decades of struggle, Constantinople (381) declared the Spirit fully God; and Chalcedon (451) defined the two natures. Definition after definition split the church: the Church of the East after Ephesus (431), the Oriental Orthodox after Chalcedon, East and West in 1054, and the Protestants from 1517.")),
            .shortOnly(.text("Nicaea did not invent the belief that Jesus is God: Christian writers call him God early in the second century. What the councils did was define, over centuries and amid bitter conflict, how the Son relates to the Father. Nicaea (325) declared the Son of one essence with the Father; Constantinople (381) declared the Spirit fully God; Chalcedon (451) defined the two natures; and definition after definition split the church.")),
            .text("Christians answer that the councils put into words what the church already believed. The follow-up: clarified from what? Arius and Athanasius, Nicaea’s great defender, read the same Gospels. Had Jesus taught the doctrine clearly, it is hard to see why defining it took three centuries, several emperors and a string of councils."),
            .door(.article("ProvingJesusView")),
        ]),
        ArticleSection("ONE BIBLE OR MANY?", [
            .longOnly(.text("The Old Testament is the Hebrew Bible, the Tanakh, named for its Torah, Prophets (Nevi’im) and Writings (Ketuvim): twenty-four books in Jewish counting, thirty-nine in a Protestant one. The New Testament has twenty-seven books in Greek, written roughly between 50 and 110, and the first surviving list of exactly those twenty-seven is the Easter letter of Athanasius in 367. Beyond that, the churches differ:")),
            .shortOnly(.text("The churches do not agree on what the Bible is:")),
            .stats([
                ArticleStat("66", "books in a Protestant Bible"),
                ArticleStat("73", "books in a Catholic Bible"),
                ArticleStat("76–79", "in Eastern Orthodox Bibles, varying by church"),
                ArticleStat("81", "in the Ethiopian Orthodox canon"),
            ]),
            .longOnly(.text("Catholics add Tobit, Judith, Wisdom, Sirach, Baruch and two books of Maccabees, the Orthodox add more again, and the Syriac Peshitta of the Church of the East keeps a New Testament of twenty-two books, without 2 Peter, 2 and 3 John, Jude and Revelation. Muslims have one Quran of 114 surahs, the same in every mosque on earth.")),
            .longOnly(.text("The Islamic view is precise. Allah gave the Tawrah to Musa, the Zabur to Dawud and the Injil to Isa (peace be upon them), guidance and light given to Jesus himself (5:46). The four Gospels are books about him, written by others, decades later, just as Deuteronomy describes the death and burial of Moses and says that no prophet like him has arisen since (Deuteronomy 34:5-10). The Muslim position is not that the Bible is worthless, but that it mixes revealed truth with human writing, editing and loss, and that the Quran confirms what came before it and stands as the criterion over it (5:48).")),
            .longOnly(.ayah("5:46", words: 12...16)),
            .longOnly(.ayah("5:48", words: 4...11)),
            .shortOnly(.text("Muslims have one Quran of 114 surahs, the same in every mosque on earth.")),
            .shortOnly(.text("The Islamic view is precise. Allah gave the Injil to Isa (peace be upon him) himself, guidance and light. The four Gospels are books about him, written by others, decades later. The Bible is not worthless, but it mixes revealed truth with human writing, editing and loss, and the Quran confirms what came before it and stands as the criterion over it.")),
        ]),
        ArticleSection("A PRESERVED BOOK?", [
            .longOnly(.text("The bar was a preserved book with no contradictions, so begin with the Gospels. Mark, the earliest, is commonly dated around 65 to 75; Matthew and Luke, around 80 to 90, both draw on Mark; John, around 90 to 110. Conservative scholars date the first three before 70. All four are formally anonymous; the traditional names appear in second-century writers such as Papias and Irenaeus, and Christians defend them while many critical scholars doubt them. Jesus preached mainly in Aramaic, a few of whose words the Gospels keep, such as “Talitha cumi” (Mark 5:41), but the Gospels are in Greek. Even the earliest gives his teaching in translation, decades later.")),
            .longOnly(.text("The editing can be watched. In Mark, Jesus answers a man who calls him good, “Why callest thou me good? there is none good but one, that is, God” (Mark 10:18, KJV); in the oldest manuscripts of Matthew, which modern translations follow, the scene reads, “Why do you ask me about what is good?” (Matthew 19:17, ESV). In Mark, “he could there do no mighty work” in his home town (Mark 6:5, KJV); in Matthew, “he did not many mighty works there” (Matthew 13:58, KJV). Many scholars read these as reverent adjustments to what Jesus could say or do.")),
            .longOnly(.text("No original of any New Testament book survives. The earliest fragment, Papyrus 52, holds a few verses of John 18, and the earliest complete New Testament, Codex Sinaiticus, is of the fourth century. Some 5,800 Greek manuscripts carry about 500,000 differences, not counting spelling, and fairness requires saying that most are trivial. A few are not: the longer ending of Mark (16:9-20) is absent from the two oldest complete manuscripts, the woman taken in adultery (John 7:53-8:11) from the earliest copies of John, and the most explicit Trinitarian verse of the King James Version from every Greek manuscript’s main text before the fourteenth century:")),
            .longOnly(.quote(text: "“For there are three that bear record in heaven, the Father, the Word, and the Holy Ghost: and these three are one.” (1 John 5:7, KJV)", dimmed: true)),
            .shortOnly(.text("The bar was a preserved book with no contradictions, so begin with the Gospels. All four are formally anonymous, and they are in Greek, though Jesus preached mainly in Aramaic: even the earliest gives his teaching in translation, decades later. No original of any New Testament book survives, and some 5,800 Greek manuscripts carry about 500,000 differences, not counting spelling. Fairness requires saying that most are trivial. A few are not: the longer ending of Mark is absent from the two oldest complete manuscripts, and the most explicit Trinitarian verse of the King James Version, “there are three that bear record in heaven,” is absent from every Greek manuscript’s main text before the fourteenth century.")),
            .text("Christians answer that the sheer number of manuscripts lets the original wording be reconstructed, and that no core doctrine rests on a disputed passage. Grant it. A perfectly reconstructed Mark is still a text written decades after Jesus, in a language other than his, by an author whose identity is debated. Reconstructing the text of Mark is not reconstructing the words of Jesus."),
        ]),
        ArticleSection("THE TRINITY AND ITS STRONGEST VERSES", [
            .text("The doctrine affirms seven statements together: the Father is God; the Son is God; the Spirit is God; the Father is not the Son; the Son is not the Spirit; the Father is not the Spirit; and there is exactly one God. If “is God” means “is identical to God,” they cannot all be true at once. Christian philosophers answer with refined theories of identity, or by saying that “is God” means “is divine,” which critics say slides toward three gods, or by appealing to mystery. Ask rather than lecture: what does “one God” mean, if three are each fully God? A mystery may be beyond reason; the question is whether this one is against it."),
            .longOnly(.text("The word Trinity first appears around 180 in Theophilus of Antioch and around 213 in Tertullian. The idea may be claimed without the word, so press on substance: where does Jesus clearly teach that he is one person of a triune God? Matthew 28:19 names the Father, the Son and the Holy Ghost together without calling them equal or one God, and in Acts the apostles baptize “in the name of Jesus Christ” (Acts 2:38). The verses Christians cite most deserve straight answers:")),
            .longOnly(.versus(ArticleVersus.Side("John 1:1", caption: "“In the beginning was the Word, and the Word was with God, and the Word was God.” The Word is eternal and divine, and became flesh (1:14)."), ArticleVersus.Side("A fair answer", caption: "These are the **Gospel writer’s words**, not Jesus’s, in the **latest** Gospel, and no third person appears. Do not lean on the “a god” translation argument; most scholars reject it."), quranic: false)),
            .longOnly(.versus(ArticleVersus.Side("John 10:30", caption: "“I and my Father are one.” His hearers took up stones, saying that he made himself God (10:33)."), ArticleVersus.Side("A fair answer", caption: "He prays that his disciples “may be one, even as we are one” (17:22): **one in purpose**. Accused, he cited Psalm 82:6, “Ye are gods,” and called his own claim “I am **the Son of God**” (10:34-36)."), quranic: false)),
            .longOnly(.versus(ArticleVersus.Side("John 8:58", caption: "“Before Abraham was, I am.” The words are heard as an echo of the divine name in Exodus 3:14."), ArticleVersus.Side("A fair answer", caption: "The Greek **ego eimi** is ordinary: the healed blind man says it of himself, “I am he” (9:9). Existing before Abraham is not being God, and **only John** records the saying."), quranic: false)),
            .longOnly(.versus(ArticleVersus.Side("John 20:28", caption: "Thomas says, “My Lord and my God,” and Jesus does not correct him."), ArticleVersus.Side("A fair answer", caption: "Days earlier he said, “I ascend unto my Father, and your Father; and to my God, and your God” (20:17). The Gospel’s stated purpose: that you believe he is “**the Christ, the Son of God**” (20:31)."), quranic: false)),
            .longOnly(.text("Beside them stand words of Jesus that a Muslim could say unchanged: “The Lord our God is one Lord” (Mark 12:29); “my Father is greater than I” (John 14:28); the Father is “the only true God” (John 17:3); and of the Hour, not even the Son knows it, “but the Father” (Mark 13:32). Christians answer that these speak of his human nature. The gentle follow-up: how do we know which nature is speaking, and if the answer is always chosen to protect the doctrine, can any verse ever count against it?")),
            .shortOnly(.text("The word Trinity first appears around 180. The idea may be claimed without the word, so press on substance: where does Jesus clearly teach that he is one person of a triune God?")),
            .shortOnly(.text("What the Gospels do give are words of Jesus that a Muslim could say unchanged: “The Lord our God is one Lord” (Mark 12:29); “my Father is greater than I” (John 14:28); the Father is “the only true God” (John 17:3); and of the Hour, not even the Son knows it, “but the Father” (Mark 13:32). Christians answer that these speak of his human nature. The gentle follow-up: how do we know which nature is speaking, and if the answer is always chosen to protect the doctrine, can any verse ever count against it?")),
        ]),
        ArticleSection("THE CROSS: WHAT THE QURAN ACTUALLY SAYS", [
            .longOnly(.text("In Christianity everything hangs on the cross: “if Christ be not risen, then is our preaching vain” (1 Corinthians 15:14, KJV). Adam sinned and sin passed to all (Romans 5:12); “without shedding of blood is no remission” (Hebrews 9:22); so God the Son became a man, died in our place and rose, and whoever believes is saved (John 3:16). Yet no council of the whole church defined how the cross saves, and its theories, from ransom (Origen) to satisfaction (Anselm) and penal substitution (the Reformers), still differ.")),
            .shortOnly(.text("In Christianity everything hangs on the cross: Adam sinned and sin passed to all, so God the Son became a man, died in our place and rose, and whoever believes is saved.")),
            .text("Most historians accept that Jesus was crucified under Pontius Pilate, citing Paul, the Gospels, Josephus and Tacitus, and Muslims should not pretend otherwise. The Muslim reason here is revelation, and it stands or falls with the case for the Quran. But every one of those sources records what people saw and believed, years afterwards, and that is exactly what the Quran speaks of:"),
            .ayah("4:157-158"),
            .longOnly(.text("The passage answers a boast, and two ayat earlier it condemns the killing of prophets (4:155), so it does not say that prophets cannot be killed; it says that this one was not.")),
            .longOnly(.ayah("4:155", words: 6...9)),
            .text("Shubbiha lahum means that it was made to appear so to them, and the bracketed “[another]” follows most commentators, who say another man was given his likeness. And Allah raised him to Himself, alive, in body and soul. Ibn Kathir puts the key phrase in a few words:"),
            .quote(text: "“That is, they saw his likeness and thought it was him.” (Ibn Kathir, Tafsir, on 4:157)", arabic: "أَي رَأَوا شَبَهَهُ فَظَنُّوهُ إِيَّاهُ", dimmed: true),
            .longOnly(.text("So the Quran does not deny that people saw a crucifixion; it denies that the man on the cross was Jesus. History can record what people saw and believed; it cannot see past what Allah caused to appear. A Christian will call that convenient, and it is fair to concede that no historian can disprove it. But it explains the evidence rather than contradicting it. Ibn Kathir records from Ibn Abbas, by the same chain, that Jesus asked which of his companions would take his likeness, be killed in his place and be with him in his rank, and one of the youngest of them volunteered. Other reports name the betrayer; they are later and not from the Prophet, and since the Quran names no one, nothing rests on who it was.")),
            .longOnly(.text("Four things are often said in the name of Islam that the Quran does not say:")),
            .longOnly(.bullet("**“Allah would never let a prophet be killed.”** The Quran says prophets were killed (2:61; 3:21; 4:155).")),
            .longOnly(.ayah("2:61", words: 44...53)),
            .longOnly(.ayah("3:21")),
            .longOnly(.bullet("**“He was put on the cross and survived.”** That swoon theory, popularised in debates by Ahmed Deedat and held by the Ahmadiyyah with their tomb in Kashmir, contradicts the Quran’s plain statement that they did not crucify him.")),
            .longOnly(.bullet("**“The Gospel of Barnabas proves it.”** Its earliest manuscripts, in Italian and Spanish, date from the late sixteenth century or after. Do not use it.")),
            .longOnly(.bullet("**“The Quran says Judas was crucified.”** The Quran names no one.")),
            .shortOnly(.text("So the Quran does not deny that people saw a crucifixion; it denies that the man on the cross was Jesus. History can record what people saw and believed; it cannot see past what Allah caused to appear. A Christian will call that convenient, and it is fair to concede that no historian can disprove it. But it explains the evidence rather than contradicting it.")),
        ]),
        ArticleSection("WEIGHING THE CROSS", [
            .text("Put the accounts to the bar. In Mark, the earliest, “they all forsook him, and fled” (Mark 14:50), Peter denied him three times, and at the cross the women watched “afar off” (Mark 15:40); only John places a disciple at its foot. The ayah’s words return: they have no knowledge of it except the following of assumption."),
            .longOnly(.text("Then set the four accounts side by side. In the first three Gospels Jesus eats the Passover meal and is crucified the next day; in John he dies before it, on “the preparation of the passover” (John 19:14). Mark has him crucified at “the third hour” (Mark 15:25); in John he is still before Pilate “about the sixth hour.” His last words are a cry of forsakenness in Mark and Matthew, “Father, into thy hands I commend my spirit” in Luke, and “It is finished” in John. Christians answer that witnesses notice different details and that some can be harmonised, and what is fair should be conceded. But the day and the hour are differences many Christian scholars recognise, and the bar was no contradictions. The Quran had already described it: those who differ over it are in doubt about it.")),
            .longOnly(.text("His own prayer points the same way. In Gethsemane he asked, “take away this cup from me” (Mark 14:36), and Hebrews says that he prayed “unto him that was able to save him from death, and was heard” (Hebrews 5:7). If God heard a prayer to be saved from death, what would being saved look like? The Quran’s answer: Allah raised him to Himself, and Allah is the best of planners (3:54).")),
            .longOnly(.ayah("3:54")),
            .longOnly(.text("And is the cross needed at all? “The son shall not bear the iniquity of the father,” and the wicked who turns “shall surely live” (Ezekiel 18:20-21). “I desired mercy, and not sacrifice” (Hosea 6:6), a line Jesus himself quoted (Matthew 9:13). Nineveh repented and was spared (Jonah 3:10), and in the parable of the prodigal son the father runs to embrace his son (Luke 15:20): no one pays, and no one bleeds. The Quran tells the beginning as Christians do and ends it differently: Adam slipped, received words from his Lord, and was forgiven (2:37); no soul bears another’s burden (6:164); and no sinner is to despair of Allah’s mercy (39:53). The Christian story needs the cross. The Islamic story never did.")),
            .shortOnly(.text("Then set the four accounts side by side. In the first three Gospels Jesus eats the Passover meal and is crucified the next day; in John he dies before it. Mark has him crucified at the third hour; in John he is still before Pilate about the sixth hour. His last words are different in Mark, in Luke and in John. Christians answer that witnesses notice different details, and what is fair should be conceded. But the day and the hour are differences many Christian scholars recognise, and the bar was no contradictions. The Quran had already described it: those who differ over it are in doubt about it.")),
            .shortOnly(.text("And is the cross needed at all? The Quran tells the beginning as Christians do and ends it differently: Adam slipped, received words from his Lord, and was forgiven, and no soul bears another’s burden. The Christian story needs the cross. The Islamic story never did.")),
            .ayah("2:37"),
            .longOnly(.ayah("6:164")),
            .longOnly(.ayah("39:53")),
        ]),
        ArticleSection("THE JESUS OF THE QURAN", [
            .longOnly(.text("Islam does not ask a Christian to give up Jesus, but to see him as the Quran does: the Messiah and a word from Allah (3:45), born of the virgin Maryam (peace be upon her), a messenger to the Children of Israel given the Injil, a worker of miracles by Allah’s permission (3:49), whose first words from the cradle were that he is the servant of Allah (19:30).")),
            .longOnly(.ayah("3:45", words: 6...13)),
            .longOnly(.ayah("3:49", words: 10...29)),
            .shortOnly(.text("Islam does not ask a Christian to give up Jesus, but to see him as the Quran does: the Messiah and a word from Allah, born of the virgin Maryam (peace be upon her), a messenger to the Children of Israel given the Injil, a worker of miracles by Allah’s permission, whose first words from the cradle were that he is the servant of Allah:")),
            .ayah("19:30"),
            .text("A birth without a father makes no one divine; Adam had neither father nor mother:"),
            .ayah("3:59"),
            .longOnly(.text("And one phrase carries the contingency argument of Part 1, for whatever needs food depends on something else:")),
            .longOnly(.ayah("5:75", words: 0...15)),
            .text("Nor is his story finished. He will return before the Hour, break the cross and judge with justice:"),
            .hadith("bukhari:3448", cite: "Sahih al-Bukhari 3448, Sahih Muslim 155", arabic: 34...50, english: [4...52]),
            .longOnly(.text("He will remain on earth forty years, then die, and the Muslims will pray over him (Sunan Abi Dawud 4324, graded sahih by al-Albani).")),
            .longOnly(.hadith("abudawud:4324", cite: "Sunan Abi Dawud 4324; graded sahih by al-Albani", arabic: 72...84, english: [83...107])),
            .door(.article("StoryIsaView")),
            .door(.article("ChristianityAnswerView")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Christianity’s creed was defined by councils over centuries and contested at each step; its scripture has several canons, no originals and later additions; the Trinity is hard to state without contradiction and is not taught by Jesus in his own words; and the accounts of the cross, written by people who were not there, disagree on the day, the hour and the last words. The Quran’s account, that he was neither killed nor crucified but raised, and will return, explains what people saw without contradicting it. Christianity does not pass the bar, and one claimant remains."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Injil", arabic: "إِنجِيل", meaning: "The **revelation Allah gave to Isa** (peace be upon him), in which was guidance and light (5:46). It is not the same as the four Gospels, which are accounts about him written by others."),
            .term("Nasara", arabic: "نَصَارَى", meaning: "The Quran’s name for **Christians**, linked by the scholars to Nazareth, and to the disciples’ answer that they were the helpers (ansar) of Allah (61:14); compare “the sect of the Nazarenes” (Acts 24:5)."),
            .ayah("61:14"),
            .term("Shubbiha lahum", arabic: "شُبِّهَ لَهُم", meaning: "**It was made to appear so to them** (4:157): the Quran’s explanation of what the onlookers saw. Most commentators explain it as another man being given the likeness of Jesus."),
            .term("Al-Masih", arabic: "المَسِيح", meaning: "**The Messiah**, the anointed one: the Quran’s title for Isa (3:45; 4:171). Muslims affirm it fully, and deny only that it makes him divine."),
            .ayah("4:171", words: 13...19),
        ]),
    ]
}

struct DominoIslamView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "DominoIslamView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Domino 7: Islam")
        .englishArticle().selectableArticleList(article: "DominoIslamView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: the last claimant faces exactly the bar Christianity faced, a preserved book with no contradictions and a messenger who can be examined, and the Quran set that bar for itself. It was memorised and written in the lifetime of the Prophet Muhammad (peace and blessings be upon him), gathered within two years of his death, and survives in manuscripts from within a generation of him, with readings he taught himself. Its challenge to produce one surah went unmet by the people best equipped to meet it, and its messenger’s character and predictions hold up. With all seven dominoes down, what remains is not another argument but a testimony: there is no god but Allah, and Muhammad is the Messenger of Allah."),
        ]),
        ArticleSection("THE SAME BAR", [
            .text("Six dominoes are down. Christianity was tested the same way as everything else, and it did not pass the bar of a preserved book with no contradictions. One claimant is left, and it gets no favours. Islam has to clear exactly the same bar, and an argument that excused it would be worthless."),
            .text("What is striking is that the Quran set this bar for itself, long before anyone ran the test. It claims to be guarded by the One who sent it down:"),
            .ayah("15:9"),
            .text("And it names the one finding that would show it to be human:"),
            .ayah("4:82"),
            .longOnly(.markdown("That ayah stands in the same surah as 4:157 on the crucifixion, and shares its root. Of those who **differ (ikhtalafu)** over the cross, the Quran says they are in doubt; of a book from other than Allah, it says people would find in it much **difference (ikhtilaf)**. The Quran does not say, trust us. It says, check. And since a claim about itself is not evidence, what follows is the checking.")),
            .longOnly(.ayah("4:157")),
            .shortOnly(.text("The Quran does not say, trust us. It says, check. And since a claim about itself is not evidence, what follows is the checking.")),
        ]),
        ArticleSection("PRESERVED: HOW WE KNOW", [
            .text("The Quran was revealed over twenty-three years and recited aloud from the first day: in the prayer, five times a day, by everyone who prayed. Many Companions memorised it whole, and today millions of people in every land memorise it through unbroken chains of teachers going back to the Prophet (peace be upon him). It was also written down in his lifetime by scribes who wrote as he dictated. Within two years of his death, after many of those who knew it by heart were killed at the Battle of Yamamah, Abu Bakr (may Allah be pleased with him) had it gathered into one copy. Zayd ibn Thabit (may Allah be pleased with him), who led the work, described how he did it:"),
            .hadith("bukhari:4986", cite: "Sahih al-Bukhari 4986", arabic: 184...191, english: [303...332]),
            .longOnly(.text("Around 650, Uthman (may Allah be pleased with him) had standard copies made from that collection and sent to the major cities (Sahih al-Bukhari 4987). The manuscripts bear this out. The parchment of the Birmingham manuscript, two leaves with parts of Surahs 18 to 20, was radiocarbon-dated in 2015 to between 568 and 645 CE with 95.4 percent probability; that dates the parchment rather than the ink, but it places the text within a generation of the Prophet (peace be upon him). A fragment held at the University of Tübingen was dated to between 649 and 675.")),
            .longOnly(.hadith("bukhari:4987", cite: "Sahih al-Bukhari 4987", arabic: 52...142, english: [72...217])),
            .shortOnly(.text("Around 650, Uthman (may Allah be pleased with him) had standard copies made from that collection and sent to the major cities. The manuscripts bear this out: the parchment of the Birmingham manuscript, with parts of Surahs 18 to 20, was radiocarbon-dated in 2015 to between 568 and 645 CE, which places the text within a generation of the Prophet (peace be upon him).")),
            .versus(ArticleVersus.Side("The Gospels", caption: "Written **decades after** Jesus, in **Greek** rather than his Aramaic, by authors who **do not name themselves**; the earliest complete New Testament is from the **fourth century**."), ArticleVersus.Side("The Quran", caption: "Recited and written **in his lifetime**, in the **language it came down in**, by the people who **heard it from him**, and memorised by millions ever since."), quranic: false),
            .door(.article("ProvingPreservationView")),
        ]),
        ArticleSection("THE READINGS, TAUGHT FIRST", [
            .longOnly(.text("Anyone who knows the subject will raise the qira’at, the canonical readings, so they should be taught before anyone raises them. The Quran is recited in several canonical readings, such as that of Hafs from Asim, the most common in the world today, and that of Warsh from Nafi‘, common in North and West Africa. Most of the differences are of vowels, dots and pronunciation; a few are word forms with complementary meanings. In al-Fatihah 1:4, one reading has Maaliki, Master of the Day of Judgement, and another has Maliki, King of the Day of Judgement: both are true of Allah, and both were taught by the Prophet (peace be upon him).")),
            .longOnly(.ayah("1:4")),
            .longOnly(.text("Umar (may Allah be pleased with him) once dragged a man before him for reciting a surah differently from the way he had learned it himself:")),
            .longOnly(.hadith("bukhari:4992", cite: "Sahih al-Bukhari 4992, Sahih Muslim 818", arabic: 134...187, english: [150...225])),
            .longOnly(.text("So Muslims do not claim that the Quran has no variation at all. They claim something more exact and more checkable: that what is recited today is what was revealed and taught, including its authorised readings, each carried by whole generations at once and each fitting the script of the Uthmani copies. The readings are part of what was preserved, not errors in it.")),
            .shortOnly(.text("Muslims do not claim that the Quran has no variation at all. It is recited in several canonical readings, such as that of Hafs from Asim and that of Warsh from Nafi‘, which differ mostly in vowels, dots and pronunciation; all were taught by the Prophet (peace be upon him), carried by whole generations at once, and fit the script of the Uthmani copies. The readings are part of what was preserved, not errors in it.")),
            .door(.article("QiraatView")),
        ]),
        ArticleSection("A CHALLENGE NO ONE MET", [
            .longOnly(.text("No contradictions is the second half of the bar. The Quran came down in pieces over twenty-three years, in answer to events, through persecution, exile, war, treaties, grief and government, and it keeps one voice and one theology throughout. Critics have compiled lists of alleged contradictions for centuries, and the classical commentators answered them case by case; most dissolve once the verses are read in context. Abrogation (naskh) is sometimes offered as a contradiction, but it is a ruling updated over time, like a law revised as circumstances change, not two opposite claims about the same thing at the same time.")),
            .shortOnly(.text("No contradictions is the second half of the bar. The Quran came down in pieces over twenty-three years, in answer to events, through persecution, exile, war and government, and it keeps one voice and one theology throughout; most alleged contradictions dissolve once the verses are read in context.")),
            .text("The Quran also made a challenge no other scripture makes. It told those in doubt to produce one surah like it, with every helper they could gather, and said in advance that they would not:"),
            .ayah("2:23-24"),
            .longOnly(.text("The challenge went to the most eloquent Arabs of the age, poets who competed in public, and to his fiercest enemies, who had every motive to meet it. They chose boycott, exile and war instead. And it came from a man who, the Quran said publicly to people who had known him for forty years, had never read a scripture or written one with his hand:")),
            .longOnly(.ayah("29:48")),
            .longOnly(.text("Its first hearers felt its force. Jubayr ibn Mut‘im (may Allah be pleased with him), not yet a Muslim, came to Madinah about the captives of Badr and heard the Prophet (peace be upon him) recite Surah at-Tur at sunset. He reached the ayah with which this whole series began in Part 1, asking whether they were created by nothing or were their own creators:")),
            .longOnly(.hadith("bukhari:4854", cite: "Sahih al-Bukhari 4854", arabic: 22...63, english: [0...78])),
            .longOnly(.text("He later said that this was when faith first settled in his heart (Sahih al-Bukhari 4023). The Quran itself records an enemy who thought it over, deliberated, frowned, and could only call it magic handed down, the word of a man (74:18-25); the commentators identify him as al-Walid ibn al-Mughirah. A specific challenge, given to the people best equipped and most motivated to meet it, went unmet. That is a different claim from saying that great literature is inimitable too: no one dared a whole people to match Shakespeare, staked a religion on their failing, and then watched them fail.")),
            .longOnly(.hadith("bukhari:4023", cite: "Sahih al-Bukhari 4023", arabic: 18...34, english: [0...23])),
            .longOnly(.ayah("74:24-25")),
            .shortOnly(.text("The challenge went to the most eloquent Arabs of the age, poets who competed in public, and to his fiercest enemies, who had every motive to meet it. They chose boycott, exile and war instead. A specific challenge, given to the people best equipped and most motivated to meet it, went unmet.")),
            .door(.article("ProvingIjazView")),
        ]),
        ArticleSection("THE MESSENGER, EXAMINED", [
            .longOnly(.text("The bar also asks about the man. Before his mission he was known among Quraysh as al-Amin, the trustworthy, and when he stood on Mount Safa and asked whether they would believe him if he warned them of an enemy cavalry in the valley, they said they had never known him to say anything but the truth (Sahih al-Bukhari 4770). As for motive, what did he gain? A’ishah (may Allah be pleased with her) said that two months could pass, three new moons, with no fire lit for cooking in his houses, and that they lived on dates and water (Sahih al-Bukhari 6459). He died with his armour pawned to a Jewish man for thirty measures of barley (Sahih al-Bukhari 2916).")),
            .shortOnly(.text("The bar also asks about the man. Before his mission he was known among Quraysh as al-Amin, the trustworthy, and when he stood on Mount Safa and asked whether they would believe him if he warned them of an enemy cavalry in the valley, they said they had never known him to say anything but the truth:")),
            .hadith("bukhari:4770", cite: "Sahih al-Bukhari 4770", arabic: 67...92, english: [49...98]),
            .longOnly(.hadith("bukhari:6459", cite: "Sahih al-Bukhari 6459, Sahih Muslim 2972", arabic: 24...80, english: [5...92])),
            .shortOnly(.text("As for motive, what did he gain? He died with his armour pawned to a Jewish man for thirty measures of barley:")),
            .hadith("bukhari:2916", cite: "Sahih al-Bukhari 2916", arabic: 20...34, english: [0...17]),
            .text("He was honest when a lie would have helped him. On the day his infant son Ibrahim died the sun was eclipsed, and people said it was for Ibrahim’s death. A false prophet would have let the miracle stand:"),
            .hadith("bukhari:1043", cite: "Sahih al-Bukhari 1043", arabic: 52...65, english: [37...63]),
            .longOnly(.text("And the revelation was not his to control. A whole surah opens by reproaching him for frowning and turning away from a blind man who came to him (80:1-2). When his wife A’ishah was slandered, he waited about a month with no revelation on the matter (Sahih al-Bukhari 4141), though a man composing scripture for his own need would have written her vindication the first night. The Quran answers the suspicion directly: had Allah willed, he would never have recited it to them, for he had lived among them a lifetime before it (10:16).")),
            .longOnly(.hadith("bukhari:4141", cite: "Sahih al-Bukhari 4141", arabic: 1078...1112, english: [1728...1768])),
            .longOnly(.ayah("80:1-2")),
            .longOnly(.ayah("10:16")),
            .door(.article("ProvingProphetView")),
        ]),
        ArticleSection("WHAT HE FORETOLD", [
            .longOnly(.text("A fulfilled prophecy is the one test a false prophet cannot fake in advance, and Jews and Christians already accept it:")),
            .longOnly(.quote(text: "“When a prophet speaketh in the name of the LORD, if the thing follow not, nor come to pass, that is the thing which the LORD hath not spoken.” (Deuteronomy 18:22, KJV)", dimmed: true)),
            .shortOnly(.text("A fulfilled prophecy is the one test a false prophet cannot fake in advance.")),
            .text("The rule for choosing prophecies matters as much as the prophecies: recorded before the event, specific, and checkable. The Quran’s were fixed in a text by about 650. When Persia had crushed Byzantium and taken Jerusalem in 614, and few would have wagered on a recovery, the Quran said that the Romans would overcome within a few years, using a word, bid‘, that the Arabs used for a number from three to nine:"),
            .ayah("30:2-4"),
            .shortOnly(.text("Heraclius began his counteroffensive in 622 and broke Persia at Nineveh in 627.")),
            .longOnly(.text("Heraclius began his counteroffensive in 622 and broke Persia at Nineveh in 627. An early Makkan surah said that Abu Lahab, the Prophet’s uncle and fiercest opponent, would burn in the Fire (111:1-3). He lived about ten more years and died a disbeliever just after Badr; a single public conversion, even a false one, would have discredited the Quran, and he never made it. After the Muslims were turned away from Makkah at al-Hudaybiyah in 628, the Quran promised that they would enter the Sacred Mosque in safety (48:27), and they did the next year.")),
            .longOnly(.ayah("111:1-3")),
            .longOnly(.ayah("48:27")),
            .longOnly(.text("Among the Prophet’s own predictions, the strongest are those with named eyewitnesses or a record far older than the event. When the roads were full of robbers, he told Adi ibn Hatim (may Allah be pleased with him) that he would live to see a woman travel alone from al-Hirah to the Ka‘bah fearing no one but Allah, and the treasures of Kisra opened. Adi lived to report both:")),
            .longOnly(.hadith("bukhari:3595", cite: "Sahih al-Bukhari 3595", arabic: 192...212, english: [312...349])),
            .longOnly(.text("In his last illness he told his daughter Fatimah (may Allah be pleased with her) that she would be the first of his family to follow him, and she died about six months after him (Sahih al-Bukhari 3623).")),
            .longOnly(.hadith("bukhari:3623", cite: "Sahih al-Bukhari 3623, Sahih Muslim 2450", arabic: 83...117, english: [99...152])),
            .longOnly(.text("And among the signs of the Hour he named barefoot, destitute shepherds competing in tall buildings:")),
            .shortOnly(.text("And among the signs of the Hour, the Prophet (peace be upon him) named barefoot, destitute shepherds competing in tall buildings:")),
            .hadith("muslim:8a", cite: "Sahih Muslim 8a", arabic: 336...345, english: [549...565]),
            .text("Imam Muslim (may Allah have mercy on him) recorded those words in the ninth century, more than a thousand years before the race to build the world’s tallest towers on the Arabian Peninsula. No one can say they were written after the fact."),
            .door(.library(.propheciesOfProphet)),
            .door(.article("ProvingProphecyView")),
        ]),
        ArticleSection("SEVEN DOMINOES, ONE CONCLUSION", [
            .text("Now the whole chain can be seen at once, every link tested in the open:"),
            .chain([
                ArticleChainLink("1. Reality", "Things exist that did not have to"),
                ArticleChainLink("2. A necessary source", "So something exists that depends on nothing"),
                ArticleChainLink("3. An intelligent Creator", "It chose this universe, so it has knowledge and will"),
                ArticleChainLink("4. Only one", "Two ultimates would limit each other or be indistinguishable"),
                ArticleChainLink("5. Revelation", "A wise Creator of beings who ask why plausibly speaks"),
                ArticleChainLink("6. Which revelation?", "Tested fairly, one claim passes: the Quran, brought by Muhammad ﷺ"),
                ArticleChainLink("7. Islam", "So worship the One, and follow His final Messenger"),
            ], caption: "The seven dominoes, all down"),
            .longOnly(.text("And the first domino meets the last. Part 1 began with the question of why anything exists at all, and reasoned, with no scripture, to one necessary, independent, uncaused Creator, unlike anything He made. Four short ayat, revealed fourteen centuries ago, say exactly that:")),
            .longOnly(.ayah("112:1-4")),
            .longOnly(.checklist([
                "**Ahad, One (112:1):** exactly one ultimate being, as Domino 4 found.",
                "**As-Samad, the Eternal Refuge (112:2):** the One on whom everything depends, depending on nothing, as Domino 2 found.",
                "**Neither begetting nor begotten (112:3):** uncaused and eternal, with nothing before Him and nothing coming from Him.",
                "**No equivalent (112:4):** unlike anything in creation, as the necessary source of all of it must be.",
            ], title: "What Reason Found, in Al-Ikhlas", icon: "equal.circle.fill")),
            .text("The case was never that each domino proves Islam by itself. It is that every line of evidence points the same way, and that once each alternative has been tested fairly, nothing else on the table passes. That is how settled conviction, yaqin, is reached: not from one argument, but from the whole chain."),
        ]),
        ArticleSection("THE SHAHADAH", [
            .longOnly(.text("The last step is not another argument. It is the one described in the passage that inspired the whole method, where people of understanding observe the creation, reflect on it, conclude that it was not made in vain, and turn to their Lord:")),
            .longOnly(.ayah("3:190-191")),
            .longOnly(.text("Observation, reflection, conclusion, submission. The submission has words, and they hold the two halves of everything above. The first half denies worship to everything but the one Creator found in Part 1; the second binds the believer to follow the Messenger whose message passed the test of Parts 2 and 3:")),
            .shortOnly(.text("The last step is not another argument. Observation, reflection and conclusion end in submission, as the people of understanding turn to their Lord, and the submission has words. The first half denies worship to everything but the one Creator found in Part 1; the second binds the believer to follow the Messenger whose message passed the test of Parts 2 and 3:")),
            .quote(text: "“There is no god worthy of worship except Allah, and Muhammad is the Messenger of Allah.”", arabic: "لَا إِلَهَ إِلَّا اللَّهُ مُحَمَّدٌ رَسُولُ اللَّهِ", dimmed: true),
            .longOnly(.text("For a Muslim who has followed the chain, the question asked at the start of the series returns: am I Muslim by habit, or by conviction? The reasons are now laid out, one domino at a time, and the Quran’s command to the believer is to hold to them until the end: fear Allah as He should be feared, and do not die except as Muslims (3:102).")),
            .longOnly(.ayah("3:102")),
            .longOnly(.text("For a reader who is not Muslim and is convinced, becoming Muslim needs no ceremony, no witness and no scholar: it is to believe these words in the heart and say them with the tongue, and nothing in a person’s past stands in the way. For a reader who is not yet convinced, the Quran asks only for honest looking, and promises that those who strive for Allah will be guided to His ways (29:69). And for the one who explains all this to others, the last word belongs to Allah: the Prophet himself could not guide whom he loved, but Allah guides whom He wills (28:56). The task is clarity; guidance is His.")),
            .longOnly(.ayah("29:69")),
            .longOnly(.ayah("28:56")),
            .shortOnly(.text("For a reader who is not Muslim and is convinced, becoming Muslim needs no ceremony, no witness and no scholar: it is to believe these words in the heart and say them with the tongue, and nothing in a person’s past stands in the way. And for the one who explains all this to others, the task is clarity; guidance is Allah’s.")),
            .door(.article("BecomeMuslimView")),
            .door(.article("ProvingClosingView")),
        ]),
        ArticleSection("COMMON QUESTIONS", only: .long, [
            .markdown("**Muhammad came six hundred years after Jesus. Why trust a later source?**"),
            .text("Recency does not decide it; reliability does. The Gospels come decades after Jesus, in a different language, from authors whose identities are debated. The Quran is a first-hand text, recorded in the lifetime of the one who brought it. And it does not claim to be a biography of Jesus; it claims to come from the God who sent him, which is the very claim the test examined."),
            .markdown("**Is Islam not simply winning by default, once everything else has fallen?**"),
            .text("It should not, and it does not. If every other claim had failed and Islam had nothing of its own, the honest answer would be that we do not know. These chapters did not only eliminate. They found a book that sets its own test and passes it, a challenge that was never met, a messenger whose life answers every question asked of it, and predictions fulfilled in public. Elimination clears the table; the evidence decides."),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Islam faces the same bar as every other claim, and the Quran set that bar for itself: guarded by Allah (15:9), and free of contradiction (4:82). It was recited and written in the Prophet’s lifetime, gathered within two years of his death, standardised around 650, and survives in manuscripts from within a generation of him, with readings he taught himself. Its challenge to produce one surah went unmet by the people best placed to meet it. Its messenger was truthful before his mission, gained nothing from it, refused a miracle that would have served him, and foretold what came true. All seven dominoes are down, and what remains is the testimony of faith."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Shahadah", arabic: "شَهَادَة", meaning: "The **testimony of faith**: that there is no god worthy of worship except Allah, and that Muhammad is the Messenger of Allah. Its first half is tawhid; its second is following the Messenger."),
            .term("Ikhtilaf", arabic: "اختِلَاف", meaning: "**Difference, contradiction.** The Quran says a book from other than Allah would hold much of it (4:82), and uses the same root of those who differ over the cross (4:157)."),
            .term("Tahaddi", arabic: "تَحَدِّي", meaning: "The **challenge** to produce a surah like the Quran (2:23; 17:88), put to its first hearers and to every generation since, and never met."),
            .ayah("17:88"),
            .term("Yaqin", arabic: "يَقِين", meaning: "**Settled certainty**: the conviction that comes when every line of evidence points the same way. The Quran uses the word in 4:157 too: they did not kill him, for certain."),
        ]),
    ]
}

struct DominoDawahView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "DominoDawahView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Say This, Not That")
        .englishArticle().selectableArticleList(article: "DominoDawahView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: an argument that only works when the other side is misrepresented, or when the evidence is overstated, loses the very people it is meant to reach. The pairs below replace easy, attackable lines with ones that survive a well-read opponent and still make the point. Then come the manner the Quran commands, with wisdom, good counsel and the best kind of argument; the honesty of saying “I do not know” and returning with an answer; the exercises that turn the method into a habit; and the reward of conveying even one ayah."),
        ]),
        ArticleSection("WHY THE WORDING MATTERS", [
            .text("Every line in this chapter comes from one conviction: only arguments that survive a well-read opponent are worth using. A weak line does double damage. It fails with the listener who knows better, and it teaches the Muslim who used it that the case for Islam is weaker than it is, when in truth the case is strong enough to need no exaggeration."),
            .text("The Quran makes accuracy a matter of justice, not of tactics. It commands the believers to stand firm for Allah as witnesses in justice, and not to let their dislike of a people push them into injustice:"),
            .ayah("5:8", words: 8...18),
            .longOnly(.text("Describing another faith falsely is an injustice to its followers; overstating the evidence for Islam is an injustice to Islam. Both are answered the same way, by saying exactly what the evidence supports, which is already more than enough. Each pair below sets an easy line beside a stronger one that still makes the point, with the reason the first one fails.")),
            .shortOnly(.text("Describing another faith falsely is an injustice to its followers; overstating the evidence for Islam is an injustice to Islam. Each pair below sets an easy line beside a stronger one that still makes the point.")),
        ]),
        ArticleSection("ON GOD AND CERTAINTY", [
            .versus(ArticleVersus.Side("Instead of", caption: "“We can’t know God is real 100%, but we’ll prove it without a shadow of a doubt.”"), ArticleVersus.Side("Say", caption: "“Almost nothing is proven like mathematics. The question is which explanation best fits the evidence, and by the end nothing else comes close.”"), quranic: false),
            .text("The first line contradicts itself in one breath. The second sets the standard that science, history and the courts all use, and asks of belief in God only what is asked of everything else."),
            .longOnly(.versus(ArticleVersus.Side("Instead of", caption: "“Codes don’t write themselves, so DNA proves a designer.”"), ArticleVersus.Side("Say", caption: "Drop it. Use **contingency**, **fine-tuning** and **consciousness** instead."), quranic: false)),
            .longOnly(.text("The DNA line opens a debate about evolution that the argument does not need and the conversation cannot finish. The other three stand whatever one thinks of biology.")),
            .versus(ArticleVersus.Side("Instead of", caption: "“God must send revelation.”"), ArticleVersus.Side("Say", caption: "“Revelation is a reasonable expectation, and the claims exist, so we test them.”"), quranic: false),
            .text("“Must” is a bigger leap than any other domino, and it is not the position of Ahl as-Sunnah: Allah owes His creatures nothing. Revelation is His mercy, and the reasonable expectation of a wise Creator."),
            .longOnly(.versus(ArticleVersus.Side("Instead of", caption: "Subjective versus objective evidence."), ArticleVersus.Side("Say", caption: "**Private** evidence versus **publicly examinable** evidence."), quranic: false)),
            .longOnly(.text("A dream or an answered prayer is real to the one who had it and can strengthen his faith, but it cannot settle a disagreement between two people who each have their own. Calling it private rather than subjective concedes nothing and is far harder to attack.")),
        ]),
        ArticleSection("ON OTHER RELIGIONS", [
            .versus(ArticleVersus.Side("Instead of", caption: "“Polytheists believe in many equal creators,” or “Hinduism is idol worship.”"), ArticleVersus.Side("Say", caption: "Describe the tradition **accurately**, then ask who deserves worship. With Hindus, speak of worship through **murtis**, which many understand as a focus for worshipping the divine."), quranic: false),
            .text("Many traditions hold a supreme being with lesser deities beneath, and a caricature loses the room before the real question, who deserves worship, can even be asked."),
            .longOnly(.versus(ArticleVersus.Side("Instead of", caption: "“If outsiders can be saved, what’s the point of that religion?”"), ArticleVersus.Side("Say", caption: "“Does it claim to be universal, final guidance for everyone?”"), quranic: false)),
            .longOnly(.text("The first does not follow logically. The second is the real test, and many religions answer it honestly themselves: they do not claim to be.")),
            .longOnly(.versus(ArticleVersus.Side("Instead of", caption: "“If a tiny religion excuses people who never heard of it, it doesn’t matter to us.”"), ArticleVersus.Side("Say", caption: "“A just God holds us to what reached us (17:15), so we test the serious claims that did.”"), quranic: false)),
            .longOnly(.ayah("17:15")),
            .longOnly(.text("The first does not show the religion to be false. The second explains why a sincere person need not investigate every claim on earth.")),
            .longOnly(.versus(ArticleVersus.Side("Instead of", caption: "“The old gods are extinct.”"), ArticleVersus.Side("Say", caption: "“Basically extinct as living religions, apart from small revivals.”"), quranic: false)),
            .longOnly(.text("Hellenic, Kemetic and Norse revival groups exist, and the one listener who belongs to one of them will stop listening.")),
        ]),
        ArticleSection("ON THE QURAN AND THE PROPHET", [
            .versus(ArticleVersus.Side("Instead of", caption: "“The Quran has no variation whatsoever.”"), ArticleVersus.Side("Say", caption: "“The Quran is preserved, including its canonical readings (qira’at), which the Prophet ﷺ himself taught.”"), quranic: false),
            .longOnly(.text("Someone will raise the readings, and the Muslim who denied that they exist will look as if he had been hiding them. Teach them first, as the Prophet Muhammad (peace and blessings be upon him) taught them (Sahih al-Bukhari 4992).")),
            .longOnly(.hadith("bukhari:4992", cite: "Sahih al-Bukhari 4992, Sahih Muslim 818", arabic: 134...187, english: [150...225])),
            .shortOnly(.text("Someone will raise the readings, and the Muslim who denied that they exist will look as if he had been hiding them. Teach them first, as the Prophet Muhammad (peace and blessings be upon him) taught them.")),
            .longOnly(.versus(ArticleVersus.Side("Instead of", caption: "“The most documented human who ever lived.”"), ArticleVersus.Side("Say", caption: "“An extraordinarily detailed record of his life, checked by a sophisticated isnad system.”"), quranic: false)),
            .longOnly(.text("The superlative is hard to defend and easy to dispute. The accurate claim is impressive enough, and it cannot be dislodged.")),
            .versus(ArticleVersus.Side("Instead of", caption: "“The Quran predicted the Big Bang.”"), ArticleVersus.Side("Say", caption: "“This fits what we now know, and here is how the classical scholars read it.”"), quranic: false),
            .text("Overclaiming loses the sceptic you most want to reach, and it ties the Quran to the present state of a science that will change. Show what the early commentators said a verse meant before any modern discovery, and let the listener weigh it."),
            .longOnly(.versus(ArticleVersus.Side("Instead of", caption: "Numerical miracles and word counts."), ArticleVersus.Side("Say", caption: "Drop them."), quranic: false)),
            .longOnly(.text("They depend on how one counts, and a critic who counts differently can make them vanish.")),
            .longOnly(.versus(ArticleVersus.Side("Instead of", caption: "Any prophecy from any hadith."), ArticleVersus.Side("Say", caption: "Lead with prophecies **recorded before** they came true, or with **named eyewitnesses**."), quranic: false)),
            .longOnly(.text("“Written after the fact” is the first objection anyone will raise. The shepherds and their towers, recorded more than a thousand years early, and Adi ibn Hatim, who lived to see his own prophecy fulfilled, cannot be answered that way.")),
        ]),
        ArticleSection("ON CHRISTIANITY", [
            .versus(ArticleVersus.Side("Instead of", caption: "“The Trinity is basically polytheism.”"), ArticleVersus.Side("Say", caption: "“Christians affirm one God. Is the doctrine coherent, and did Jesus teach it?”"), quranic: false),
            .text("Otherwise the conversation becomes twenty minutes of definitions, and the Christian leaves having heard only that Muslims do not understand his faith."),
            .versus(ArticleVersus.Side("Instead of", caption: "“Jesus never said he was God.”"), ArticleVersus.Side("Say", caption: "“Where does Jesus clearly teach the later creed, and command worship of a Trinity?”"), quranic: false),
            .text("Christians have verses they read that way, mostly in John. The better question admits it, and still points to what is missing."),
            .longOnly(.versus(ArticleVersus.Side("Instead of", caption: "“Nicaea decided Jesus was God.”"), ArticleVersus.Side("Say", caption: "“Nicaea defined how the Son relates to the Father. Belief in his divinity came earlier.”"), quranic: false)),
            .longOnly(.text("The first is historically wrong: Ignatius called Jesus God around 110. The second is right, and it makes the stronger point, that the doctrine needed centuries to define.")),
            .longOnly(.versus(ArticleVersus.Side("Instead of", caption: "“Jesus couldn’t speak Greek.”"), ArticleVersus.Side("Say", caption: "“Jesus preached mainly in Aramaic; the Gospels were written in Greek.”"), quranic: false)),
            .longOnly(.text("The first is hard to establish. The second is certain, and it is all the argument needs.")),
            .versus(ArticleVersus.Side("Instead of", caption: "“The Gospels are anonymous, so they’re worthless.”"), ArticleVersus.Side("Say", caption: "“The Gospels are formally anonymous. The names were attached later, and Christians defend them.”"), quranic: false),
            .text("Present both facts and let the listener weigh them. The same goes for the Bible as a whole: never call it completely corrupted or worthless. The Islamic position is that it mixes revealed truth with human additions, and many of the best arguments come from it."),
            .longOnly(.versus(ArticleVersus.Side("Instead of", caption: "“Allah would never let a prophet be killed,” or “Jesus survived the cross.”"), ArticleVersus.Side("Say", caption: "The Quran says other prophets **were** killed (2:61), and that Jesus was **neither killed nor crucified**, but raised (4:157-158)."), quranic: false)),
            .longOnly(.ayah("2:61", words: 44...53)),
            .longOnly(.ayah("4:157-158")),
            .longOnly(.text("Both lines contradict the Quran. The swoon theory and the Gospel of Barnabas, a text of the late sixteenth century, belong on the same list: drop them.")),
            .longOnly(.versus(ArticleVersus.Side("Instead of", caption: "“The Jews tried to stone Jesus.”"), ArticleVersus.Side("Say", caption: "“The crowd tried to stone him” (John 8:59)."), quranic: false)),
            .longOnly(.text("John calls them the Jews, but the crowd is accurate and fair, and the fairer word costs nothing.")),
        ]),
        ArticleSection("THE MANNER: WISDOM AND GENTLENESS", [
            .text("Accurate words still need the right manner, and the Quran gives it in one ayah:"),
            .ayah("16:125"),
            .longOnly(.text("Wisdom, good counsel and the best kind of argument, in that order. When Allah sent Musa and Harun (peace be upon them) to Pharaoh, a man who had claimed to be a lord, He commanded them to speak to him gently, so that perhaps he would remember or fear (20:43-44). The Quran forbids insulting what others worship, lest they insult Allah in ignorance (6:108).")),
            .shortOnly(.text("Wisdom, good counsel and the best kind of argument, in that order. When Allah sent Musa and Harun (peace be upon them) to Pharaoh, a man who had claimed to be a lord, He commanded them to speak to him gently:")),
            .ayah("20:43-44"),
            .longOnly(.ayah("6:108")),
            .longOnly(.text("Gentleness adorns everything it is in (Sahih Muslim 2594), and the Prophet (peace be upon him) gave the rule in a few words:")),
            .shortOnly(.text("And the Prophet (peace be upon him) gave the rule in a few words:")),
            .hadith("bukhari:69", cite: "Sahih al-Bukhari 69", arabic: 27...32, english: [4...32]),
            .longOnly(.hadith("muslim:2594a", cite: "Sahih Muslim 2594", arabic: 38...51, english: [0...26])),
            .longOnly(.text("Five habits follow in any conversation with a person of another faith. Start with common ground. Use their terms the way they use them. Quote their strongest verses, not their weakest. Ask more questions than you make statements. Never mock what they love. Then follow the order the Prophet (peace be upon him) gave Mu‘adh (may Allah be pleased with him) when he sent him to the People of the Scripture in Yemen: begin with the oneness of Allah, and only then with the practices that follow from it:")),
            .longOnly(.hadith("bukhari:7372", cite: "Sahih al-Bukhari 7372", arabic: 49...77, english: [12...62])),
            .longOnly(.text("Finally, remember whose work guidance is. The Prophet (peace be upon him) could not guide his own uncle Abu Talib, who died upon the religion of his people (Sahih al-Bukhari 3884), and Allah told him that he does not guide whom he loves, but Allah guides whom He wills (28:56). A Muslim’s task is clarity. The result belongs to Allah, and so does the reward, whatever the result.")),
            .longOnly(.hadith("bukhari:3884", cite: "Sahih al-Bukhari 3884, Sahih Muslim 24a", arabic: 14...74, english: [0...94])),
            .longOnly(.ayah("28:56")),
            .shortOnly(.text("Five habits follow in any conversation with a person of another faith. Start with common ground. Use their terms the way they use them. Quote their strongest verses, not their weakest. Ask more questions than you make statements. Never mock what they love. And begin, as the Prophet (peace be upon him) told Mu‘adh (may Allah be pleased with him) when he sent him to the People of the Scripture, with the oneness of Allah, and only then with the practices that follow from it.")),
            .shortOnly(.text("Finally, remember whose work guidance is: Allah guides whom He wills. A Muslim’s task is clarity. The result belongs to Allah, and so does the reward, whatever the result.")),
        ]),
        ArticleSection("WHEN YOU DO NOT KNOW", [
            .text("Sooner or later someone asks a question you cannot answer. The honest response has three steps: acknowledge, research, return. Acknowledge that you do not know, plainly and without embarrassment. Research it, by asking the people of knowledge, as the Quran commands (16:43), and by reading the scholars rather than the first video that agrees with you. Then return, to the same person, with the answer. A conversation resumed a week later with a careful answer does more good than a confident guess that falls apart."),
            .ayah("16:43"),
            .longOnly(.text("Saying “I do not know” is not a weakness in Islam; it is part of knowledge. Abdullah ibn Mas‘ud (may Allah be pleased with him) taught it to his students:")),
            .longOnly(.hadith("bukhari:4809", cite: "Sahih al-Bukhari 4809, Sahih Muslim 2798", arabic: 19...42, english: [9...51])),
            .longOnly(.text("He then recited the ayah in which the Prophet (peace be upon him) is told to say that he is not one of the pretenders (38:86). The Quran forbids pursuing what one has no knowledge of (17:36), and a guess presented as knowledge about Allah’s religion is exactly that.")),
            .longOnly(.ayah("38:86")),
            .longOnly(.ayah("17:36")),
            .longOnly(.text("The same honesty applies inward. Having a doubt does not make someone a bad Muslim. Some of the Companions came to the Prophet (peace be upon him) troubled by thoughts too terrible to speak of:")),
            .longOnly(.hadith("muslim:132a", cite: "Sahih Muslim 132", arabic: 24...48, english: [0...39])),
            .longOnly(.text("Their hatred of the thought was itself the mark of faith. But a doubt that is ignored does not go away. Another settles on top of it, and another, until one video brings the whole pile down at once. So never let it build up: take it to someone with knowledge while it is still one question. Whatever doubt a person has had, the scholars have met it before, and answered it.")),
            .longOnly(.text("And when the other person’s argument is an experience, that he felt the Holy Spirit or that his prayer was answered, the gracious reply is also the true one: I believe you felt something real. Muslims feel Allah’s nearness too, and people of other faiths report the same. That is exactly why experiences cannot settle it between us. Can we look together at what we can both examine?")),
            .shortOnly(.text("Saying “I do not know” is not a weakness in Islam; it is part of knowledge.")),
            .shortOnly(.text("The same honesty applies inward. Having a doubt does not make someone a bad Muslim, but a doubt that is ignored does not go away: take it to someone with knowledge while it is still one question. Whatever doubt a person has had, the scholars have met it before, and answered it.")),
        ]),
        ArticleSection("PRACTICE: THE EXERCISES", only: .long, [
            .text("The method becomes a habit only through practice. Each part of the Domino Process ends with an exercise that works in a study circle, a classroom, or between two friends."),
            .markdown("**Part 1, in pairs: three minutes to a Creator.** The Quran advises standing for Allah in pairs and alone, and then giving thought (34:46)."),
            .ayah("34:46"),
            .step("1. **One plays a thoughtful sceptic** and opens: “I don’t believe in God. Why should I?”"),
            .step("2. **The other has three minutes** to walk from existence to one intelligent Creator: things exist that need not; dependent things need an explanation outside themselves; the chain ends in something necessary; it chose this universe, so it has knowledge and will; and there can be only one."),
            .step("3. **The sceptic pushes back once per domino** with a real objection, fairly and without trolling."),
            .step("4. **Switch roles**, then talk it over: which domino was hardest to explain, which objection was hardest to answer, and which analogy worked."),
            .markdown("**Part 2, in groups: run it through the checklist.** Each group takes one belief system: Buddhism, Vaishnavism, Judaism, Sikhism, the Baha’i Faith, ancient Greek religion, deism, or an invented case, a religion founded online in 2019 by a man who says an angel dictated a book to him. In five minutes, answer five questions:"),
            .step("1. **What does it claim** about God, or about ultimate reality?"),
            .step("2. **Does it claim** to be universal, final guidance for everyone?"),
            .step("3. **What revelation** does it claim, and through whom?"),
            .step("4. **How would we know** that the revelation reached us unchanged from its founder?"),
            .step("5. **What would we need to investigate** further before concluding anything?"),
            .text("Then each group names one real strength and one real problem. Reward fair descriptions and push back on caricatures: the goal is the method, not the verdict, and for a tradition no one knows well, an honest answer to the fifth question is the win."),
            .markdown("**Part 3, in threes: answer their strongest point.** One plays a Christian, one a Muslim, and one observes; rotate every two minutes so that everyone plays the Muslim once."),
            .checklist([
                "“Jesus said, ‘I and my Father are one.’”",
                "“The Trinity isn’t three gods. You’re attacking a straw man.”",
                "“Jesus died for your sins. How else could God forgive you?”",
                "“If someone else was on the cross, God tricked everyone.”",
                "“Muhammad came six hundred years later. Why trust a later source?”",
                "“I’ve felt the Holy Spirit. How can you say that isn’t real?”",
            ], title: "The Prompt Cards", icon: "rectangle.stack.fill"),
            .text("The observer scores the Muslim from one to three on five things: accurate (did he describe Christian belief correctly?), respectful (tone, patience, no mockery), clear (one point at a time), curious (more questions than speeches) and honest (did he concede what is true?). The answers are in the chapter on Christianity. For the third card: Ezekiel 18, Hosea 6:6, Jonah 3:10 and the prodigal son, with Adam forgiven when he repented (2:37). For the fourth: the claim to have killed him was his enemies’ boast, and Allah protected His messenger from those who plotted against him (3:54; 5:110). For the sixth: the reply about experiences above, which is the best of all six for practising grace."),
            .ayah("2:37"),
            .ayah("3:54"),
            .ayah("5:110", words: 46...53),
        ]),
        ArticleSection("EVEN ONE AYAH", [
            .text("None of this is reserved for scholars. The Prophet (peace be upon him) asked every Muslim to pass on what he had learned, however little, and in the same breath warned against saying of him what is not true:"),
            .hadith("bukhari:3461", cite: "Sahih al-Bukhari 3461", arabic: 29...46, english: [4...55]),
            .text("The two halves of this chapter meet in that one hadith: say something, and say it truly. The reward is beyond measure. On the day of Khaybar, sending Ali (may Allah be pleased with him) to call a people to Islam, the Prophet (peace be upon him) told him:"),
            .hadith("bukhari:3009", cite: "Sahih al-Bukhari 3009, Sahih Muslim 2406", arabic: 90...117, english: [132...175]),
            .longOnly(.text("Red camels were the most prized wealth of the Arabs. And whoever calls to guidance has a reward like the rewards of all who follow it, without their rewards being reduced at all (Sahih Muslim 2674). The Quran asks who could be better in speech than one who invites to Allah, does righteous deeds and says that he is of the Muslims (41:33). That is the purpose of the whole Domino Process: dawah with basirah, with insight and evidence, the way of the Prophet and of those who follow him (12:108).")),
            .longOnly(.hadith("muslim:2674", cite: "Sahih Muslim 2674", arabic: 34...51, english: [0...29])),
            .longOnly(.ayah("41:33")),
            .shortOnly(.text("Red camels were the most prized wealth of the Arabs. That is the purpose of the whole Domino Process: dawah with basirah, with insight and evidence, the way of the Prophet and of those who follow him:")),
            .ayah("12:108"),
            .door(.article("DominoIntroView")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Say only what survives a well-read opponent: the best explanation rather than impossible certainty, a reasonable expectation rather than “must,” accurate descriptions rather than caricatures, a Quran preserved with its readings rather than “no variation,” and questions a Christian can recognise rather than slogans he cannot. Argue with wisdom, good counsel and the best manner, gently, without mocking what others love, beginning with the oneness of Allah. When you do not know, say so, find out, and come back. Practise until the method is a habit. And convey even one ayah, truthfully: guidance belongs to Allah, and the reward for calling to it is greater than the finest wealth."),
        ]),
        ArticleSection("KEY TERMS", only: .long, [
            .term("Hikmah", arabic: "حِكمَة", meaning: "**Wisdom**: putting each thing in its place, the right word to the right person at the right time. It comes first in the Quran’s instruction on calling to Allah (16:125)."),
            .term("Basirah", arabic: "بَصِيرَة", meaning: "**Insight and clear evidence.** The Prophet’s way is to invite to Allah upon basirah, he and those who follow him (12:108): knowing what one calls to, and why."),
            .term("Jidal", arabic: "جِدَال", meaning: "**Argument and debate.** Allowed, and commanded, only in the best manner (16:125; 29:46): honest, gentle, and aimed at the truth rather than at winning."),
            .ayah("29:46"),
            .term("Balagh", arabic: "بَلَاغ", meaning: "**Conveying the message** clearly. The Quran repeats that the messenger’s duty is only clear conveyance (24:54); guidance is Allah’s."),
            .ayah("24:54"),
        ]),
    ]
}
