import SwiftUI

// The Proving Islam library's chapters (Abu, 2026-09-29: "incorporate Proving Islam in the app ... actually
// use a lot of their stuff"). Adapted from provingislam.net's "The Complete Case" and provingislam.com's
// proofs, in this app's own words, and held to its rules: every ayah a `.ayah(` reference, every hadith a
// `.hadith(` reference into the bundled shelf graded sahih or hasan, the Bible quoted in the KJV, and every
// academic or historical claim checked. Where "The Complete Case" leans on a weak narration or an
// overclaim, the chapter drops or qualifies it, as that document's own closing note asks. The index is
// ProvingIslamView; the chapters are catalog articles (`IslamArticleCatalog.provingGroups`, home
// `.proving`), so search, the Ask AI corpus and each page's own search reach them.

struct ProvingCaseView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "ProvingCaseView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("How the Case Works")
        .selectableArticleList(article: "ProvingCaseView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: no single argument in this library is asked to carry the whole weight of Islam. Each chapter examines one line of evidence, and the case is that one explanation, the one the Quran gives for itself, accounts for all of them together with fewer assumptions than any rival. This chapter explains that method, sets fair ground rules for both sides, and maps the library."),
        ]),
        ArticleSection("ONE CASE, MANY STRANDS", [
            .markdown("Proving Islam, whose long study **The Complete Case** this library adapts, begins with its method before it offers a single proof. The case, in its words, is **cumulative and converging**. No one argument is presented as decisive on its own. A critic can call one prophecy luck, one historical detail borrowing, one scientific statement coincidence, one ethical teaching moral genius and one literary feature talent, and each answer, taken alone, may sound reasonable."),
            .text("But each answer is a separate explanation, and none of them comes free. The more kinds of evidence that need their own independent excuse, the less economical the whole account becomes. So the question is not “can you explain this one point?” It is this: what single explanation, with the fewest assumptions, accounts for all of it at once? The Quran’s language, its fulfilled predictions, its knowledge of earlier scripture, its moral force, the steadiness of its voice, its preservation and the character of the man who brought it all need explaining together."),
            .callout("A human author leaves human fingerprints. The Quran resists the ordinary marks of human authorship in many independent ways at once, and that **convergence**, not any single strand, is the argument.", title: "The Key Idea", icon: "lightbulb.fill"),
            .markdown("Muslim scholarship already knows this kind of reasoning. The hadith scholars call a report **mutawatir (مُتَوَاتِر)** when it reaches us through so many independent narrators that their agreeing on a falsehood is impossible: no single narrator gives certainty, but together they do. A court weighs circumstantial evidence the same way. Strands that are weak alone become strong when they are independent and all point in one direction."),
            .text("One of the earliest recorded uses of this method on the Prophet (peace and blessings be upon him) came from a Christian emperor. Heraclius questioned Abu Sufyan ibn Harb, who was then the Prophet’s enemy and later a Companion (may Allah be pleased with him), along a series of independent lines, and then explained what each answer had ruled in or out:"),
            .hadith("bukhari:7", cite: "Sahih al-Bukhari 7", arabic: 285...355, english: [506...629]),
            .text("Each question tested a rival explanation: a man imitating an earlier claimant, a man reclaiming his ancestors’ throne, a man in the habit of lying. Heraclius went on to ask about his followers, his faithfulness to agreements and what he commanded, and he drew his conclusion from the answers taken together. Abu Sufyan, who told the story, later accepted Islam himself."),
        ]),
        ArticleSection("OCCAM'S RAZOR APPLIED TO THE WHOLE", [
            .text("A thoughtful sceptic will reply that a natural explanation always needs fewer assumptions than a revelation. The principle he appeals to, Occam’s razor, is sound: do not multiply assumptions beyond need. But Proving Islam makes the right correction. The razor applies to the whole explanation, not to one side of it."),
            .text("Suppose we already agree that God exists; the next section explains why that is the right place to begin. Then “He spoke to a man” adds one assumption, and that one assumption covers every kind of evidence at once. The natural account has to add a new assumption for each kind: a teacher or a library that no one in Makkah ever saw, holding writings in Hebrew, Syriac or Greek, for a man who could not read at all; luck for each named prediction; an untrained genius who outdid the poets of the most poetic people of his age; a voice that held steady through twenty-three years of persecution, grief and war; a man who denied authorship of the finest work in his language and suffered for it; and a text that was then kept word for word."),
            .text("Each of those assumptions is modest on its own. Together they are not, because the probabilities of independent coincidences multiply. If five independent explanations were each as likely as a coin landing heads, all five together would have about one chance in thirty-two; ten would have about one in a thousand. In Proving Islam’s words, the rival theory “requires one new assumption per category of evidence.”"),
            .text("The Quran asked its first hearers to do exactly this kind of thinking, honestly, and away from the pressure of the crowd:"),
            .ayah("34:46", words: 1...11),
            .text("Two honest limits apply. Parsimony is a guide to judgment, not a proof on its own. And the strands are not all equally strong: the chapters of this library say which evidence is decisive and which rests on a reading of the text, so that each reader can weigh them for himself."),
        ]),
        ArticleSection("AGREE THE STANDARD FIRST", [
            .text("Before any evidence is weighed, two questions should be settled, because every later argument depends on them."),
            .step("1. **Does God exist, and could He speak to mankind through a chosen man?** If not, no evidence of prophethood could ever count, and the honest place to begin is that prior question. Jews and Christians who hold to their scriptures already say yes, and so the objection that miracles are impossible is not open to them."),
            .step("2. **What would count, for you, as evidence of a prophet?** Name the standard before looking at the evidence, then apply it evenly: to Muhammad (peace and blessings be upon him), and to the prophets you already accept."),
            .door(.article("ProvingGodView")),
            .text("Proving Islam presents this as a way to stop an opponent from moving the goalposts. It is better understood as fairness to both sides. A standard agreed in advance stops the Muslim from claiming every coincidence as a miracle, and it stops the sceptic from raising the bar each time it is met. It is also how the Prophet himself began his public call: he first asked his people to confirm what they already knew of him, and only then delivered his message:"),
            .hadith("bukhari:4971", cite: "Sahih al-Bukhari 4971", arabic: 56...82, english: [43...88]),
            .text("The same fairness binds the believer. The Quran asks those who make claims to bring evidence, and it forbids its own followers to claim what they do not know:"),
            .ayah("2:111", words: 12...17),
            .ayah("17:36"),
            .text("Muslim scholars have argued with other faiths in this spirit. When a Christian treatise reached Ibn Taymiyyah (may Allah have mercy on him) from Cyprus, he answered it in al-Jawab as-Sahih by setting out its arguments section by section and replying to each: the other side’s case first, then the answer."),
        ]),
        ArticleSection("THE QURAN INVITES THE TEST", [
            .text("The Quran does not ask to be accepted without examination. It asks to be read closely, names the result a reader should expect if it were a human work, and issues challenges that could have been met. Allah (Glorified and Exalted be He) says:"),
            .ayah("4:82"),
            .ayah("10:38"),
            .ayah("41:53"),
            .text("These verses carry risk. A book that says a careful reader will find no contradiction in it can be refuted by a careful reader. A book that invites its enemies to produce a single surah like it can be refuted by a single surah. A book that promises signs in the horizons and within ourselves stakes itself on what later generations would find. The chapters that follow take these tests one at a time."),
        ]),
        ArticleSection("A MAP OF THE LIBRARY", [
            .text("The library follows the evidence in five groups. Each chapter stands on its own, but the argument lies in their agreement."),
            .markdown("**The Messenger.** Who he was before the revelation and how he lived under it, where he stands in the line of prophets, and the passages of the Bible that Muslim scholars read as pointing ahead to him."),
            .door(.article("ProvingProphetView")),
            .door(.article("ProvingContinuationView")),
            .door(.article("ProvingBibleView")),
            .markdown("**The Book.** The marks a human author would have left, the challenge no one met, the distance between the Quran’s voice and the everyday speech of the man who recited it, and how the text was kept."),
            .door(.article("ProvingFingerprintView")),
            .door(.article("ProvingIjazView")),
            .door(.article("ProvingStylometryView")),
            .door(.article("ProvingPreservationView")),
            .markdown("**What he could not have known.** Predictions that came true, the errors of its age that the Quran did not make, and what it knows of earlier scripture and where it departs from it."),
            .door(.article("ProvingProphecyView")),
            .door(.article("ProvingScienceView")),
            .door(.article("ProvingSourcesView")),
            .door(.article("ProvingScriptureView")),
            .markdown("**The message.** A justice that reaches past the tribe, Jesus (peace be upon him) as the Gospels remember him, and the question of God that comes before all the others."),
            .door(.article("ProvingEthicsView")),
            .door(.article("ProvingJesusView")),
            .door(.article("ProvingGodView")),
            .markdown("**The verdict.** The hardest questions the evidence puts to the alternative, and the case taken as a whole."),
            .door(.article("ProvingQuestionsView")),
            .door(.article("ProvingClosingView")),
        ]),
        ArticleSection("A NOTE ON HONESTY", [
            .markdown("Proving Islam closes its document with a **note on intellectual honesty**, and this library adopts it as a rule. The goal is truth, not rhetorical victory, and “a weaker argument presented honestly is stronger than an overclaim that collapses under scrutiny.” In practice that means four things in every chapter:"),
            .step("1. **Sound sources only.** A hadith is quoted only when it is graded sahih or hasan. Well-known stories with weak chains are left out, however vivid they are."),
            .step("2. **Readings marked as readings.** Where an argument rests on one meaning of a word that can carry others, the chapter says so."),
            .step("3. **Objections at their strongest.** Where a critic has a serious reply, it is stated before it is answered."),
            .step("4. **Acknowledge, research, return.** An objection not answered here is a reason to study further, never a reason to pretend it does not exist."),
            .text("The Companions (may Allah be pleased with them) held themselves to this standard whenever they spoke about the Prophet (peace and blessings be upon him). Anas ibn Malik (may Allah be pleased with him) explained what held him back from narrating more:"),
            .hadith("bukhari:108", cite: "Sahih al-Bukhari 108", arabic: 12...34, english: [0...35]),
            .text("And the Quran commands justice even toward people one dislikes:"),
            .ayah("5:8", words: 0...18),
            .text("The cumulative case does not depend on every argument surviving every challenge. It depends on the whole of the evidence, which, as Proving Islam observes, no rival account has yet explained with a single coherent and economical theory."),
            .door(.link("https://provingislam.net/", title: "The Complete Case", subtitle: "Proving Islam, the document this library adapts")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**Isn’t a cumulative case just many weak arguments piled together?**"),
            .text("If every strand were worthless, adding them up would give nothing. But the strands here carry weight of their own and, more importantly, they are independent: an explanation of how the Quran was preserved says nothing about Abu Lahab’s silence, and neither explains the Quran’s Arabic. Independence is what makes agreement meaningful. It is why a mutawatir report gives certainty although no single narrator could, and why a court can convict on converging evidence without a confession. Some strands, such as the challenge no one has met, are strong even on their own."),
            .markdown("**Doesn’t “God did it” explain anything, and so explain nothing?**"),
            .text("An explanation that fits every possible outcome explains nothing, but this one does not fit every outcome. A revelation from the Knower of the unseen should contain no failed prediction, no contradiction and no copied error, and the Quran staked itself on exactly those tests. It even said in advance that its challenge would never be met:"),
            .ayah("2:23-24", words: 20...24),
            .text("A claim that one surah, one failed prediction or one clear contradiction could have refuted is not a catch-all. It is a claim that has stood open to refutation for fourteen centuries."),
            .markdown("**Why should I grant that God exists?**"),
            .text("You need not grant it on trust. The Quran argues for it from the plain fact that we began, in verses that Jubayr ibn Mut‘im (may Allah be pleased with him), hearing them while still a pagan, said nearly made his heart fly (Sahih al-Bukhari 4854):"),
            .ayah("52:35-36"),
            .text("The chapter “God: The Prior Question” sets out the argument in full. The order matters: if God is ruled out before the evidence is heard, no evidence of prophethood could ever be admitted."),
            .markdown("**What happens if one of these arguments turns out to be wrong?**"),
            .text("Then it should be dropped, and the case is weaker by exactly that much and no more. This library has already set aside several popular arguments for that reason: stories whose chains are weak, and numerical patterns such as comparing how often “land” and “sea” occur in the Quran, which prove little because a determined counter can find some pattern in any long text. What remains is meant to survive scrutiny, and where it does not, the honest course is the one Proving Islam names: acknowledge it, research it, and return to it."),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("The case for Islam in this library is cumulative: many independent lines of evidence, each examined honestly, all pointing in one direction. Its question is not whether each point can be explained away alone, but which single explanation accounts for all of them with the fewest assumptions. It asks for fairness on both sides, a standard agreed before the evidence is heard, and honesty about what each argument can bear, and the Quran asks no less when it invites its readers to reflect and to bring their proof."),
        ]),
        ArticleSection("KEY TERMS", [
            .term("Burhan", arabic: "بُرهَان", meaning: "A **decisive proof** that makes the truth plain. It is the Quran’s word when it tells those who make claims without evidence to produce their proof (2:111), and when it tells all mankind that a conclusive proof has come to them from their Lord (4:174)."),
            .term("Mutawatir", arabic: "مُتَوَاتِر", meaning: "From the root **و-ت-ر**, in its sense of things coming one after another: a report carried by so many independent narrators at every stage that their agreeing on a lie is impossible. It gives certain knowledge, though no single narrator could."),
            .term("Tadabbur", arabic: "تَدَبُّر", meaning: "From the root **د-ب-ر**, the back or end of a thing: to think a matter through to where it leads. It is the reflection that 4:82 asks of every reader of the Quran."),
            .term("Dala’il an-Nubuwwah", arabic: "دَلَائِل النُّبُوَّة", meaning: "The **signs of prophethood**: every kind of evidence that a man is truly a prophet, from his character and his message to what he foretold. Al-Bayhaqi and Abu Nu‘aym al-Asbahani each wrote a classical book under this title."),
        ]),
    ]
}

struct ProvingFingerprintView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "ProvingFingerprintView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Human Fingerprint Test")
        .selectableArticleList(article: "ProvingFingerprintView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: every great human mind leaves the fingerprints of its age in its work, errors that no one now defends. The Quran came through one man over twenty-three years of persecution, grief, war and government, and the marks such a life should leave in a book are missing. Proving Islam calls this the human fingerprint test. This chapter sets it out, and states plainly what it claims and what it does not."),
        ]),
        ArticleSection("THE UNIVERSAL PATTERN", [
            .text("Every human intellectual tradition eventually shows its human origin. This is not because people are foolish; it is because they are limited. Each of us inherits the assumptions of an age, corrects some of them, and unknowingly keeps others. The greatest minds in history are no exception, and their mistakes were the mistakes of their times:"),
            .bullet("**Aristotle** founded formal logic and much of biology, yet he taught that heavier bodies fall faster in proportion to their weight, and that the heavens are made of an unchanging fifth element. His physics shaped learned thought for close to two thousand years."),
            .bullet("**Galen**, the physician of the second century, taught that blood is made continuously in the liver and seeps from the right side of the heart to the left through invisible pores. The Muslim physician Ibn al-Nafis rejected the pores in 1242, and William Harvey demonstrated the circulation of the blood in 1628."),
            .bullet("**Ptolemy** built the most sophisticated astronomy of the ancient world around a motionless Earth at the centre. His Almagest remained the standard work in the Muslim world and in Europe for some fourteen centuries, until Copernicus."),
            .bullet("**Galileo** championed the motion of the Earth, yet he argued that this motion causes the tides, and dismissed Kepler’s view that the Moon is responsible as a belief in occult influences. He never accepted Kepler’s elliptical orbits either."),
            .bullet("**Newton** founded classical mechanics, yet he left about a million words of manuscripts on alchemy, and his particle theory of light gave way to the wave theory in the nineteenth century."),
            .bullet("**Darwin** proposed in 1868 that tiny “gemmules” shed by every part of the body gather in the reproductive organs and carry heredity. Francis Galton’s blood transfusions between rabbits found no trace of them, and the theory was abandoned."),
            .text("None of this makes them small; it makes them human. Each of them was brilliant, and each was held by the limits of his century, often in exactly the places where he was surest he had escaped them."),
        ]),
        ArticleSection("23 YEARS THAT SHOULD HAVE LEFT MARKS", [
            .text("The Quran was not written in one calm sitting. It came to the Prophet (peace and blessings be upon him) in portions over about twenty-three years, from around his fortieth year until his death, and those years held almost everything that shakes a human voice."),
            .text("There was mockery and a boycott in Makkah, and the year in which he lost both his wife Khadijah (may Allah be pleased with her) and his uncle Abu Talib. There was exile, war, victory at Badr and defeat at Uhud. He lost children. A slander against his wife Aishah (may Allah be pleased with her) spread for a month. There was hypocrisy inside his own community, there were legal questions and challenges from Jews, Christians and pagans, and at the end came the burden of governing a growing state."),
            .text("It also came piece by piece, often in answer to events, and each portion was recited in public as it arrived. The Quran records the objection this raised, and its answer:"),
            .ayah("25:32"),
            .text("A human author writing under those conditions would be expected to leave the ordinary marks of human production: predictions that failed, the science and myths of his time stated as fact, the morality of his tribe, his own ego, a style that breaks under grief or swells with victory, borrowings that carry their sources’ mistakes, and a text that drifts as it is copied. Proving Islam’s question is simply: where are they?"),
            .checklist([
                "**Failed prophecies?** It named outcomes in advance, among them the Romans’ recovery within a few years (30:2-4) and Abu Lahab’s end (111:1-3), and none is on record as having failed. (Foretold, and Fulfilled)",
                "**The cosmology of its age?** It speaks of the sun and the moon in words any observer can check, each gliding in an orbit (21:33), and it does not teach the system of spheres that its own later commentators took for granted. (The Errors It Did Not Make)",
                "**Tribal morality?** It commands justice against oneself, one’s parents and relatives (4:135), and toward a hated people (5:8), in a society built on loyalty to blood. (Justice Beyond the Tribe)",
                "**The author’s ego?** It rebukes the man who recited it (80:1-10), has him say that he does not know what will be done with him (46:9), and keeps a verse he would most have wished to hide (33:37). (The Prophet’s Character)",
                "**Stylistic collapse?** Its style develops across twenty-three years, but smoothly and as one voice: a stylometric study of the whole text found its markers of style changing gradually and concluded that it has one author. (Two Voices: Quran and Hadith)",
                "**Textual corruption?** It is recited today as it was taught, carried by memorisers in every generation and by manuscripts whose oldest leaves are written on parchment dated to a span that includes the Prophet’s lifetime. (Preserved as Promised)",
            ], title: "Where Are the Fingerprints?", icon: "questionmark.circle.fill"),
            .door(.article("ProvingProphecyView")),
            .door(.article("ProvingScienceView")),
            .door(.article("ProvingEthicsView")),
            .door(.article("ProvingProphetView")),
            .door(.article("ProvingStylometryView")),
            .door(.article("ProvingPreservationView")),
        ]),
        ArticleSection("THE TEST THE QURAN SETS ITSELF", [
            .text("The fingerprint test is not an outside standard imposed on the Quran. The Quran set it first, and named the result a careful reader should expect if the book were a human work. Allah (Glorified and Exalted be He) says:"),
            .ayah("4:82", words: 9...12),
            .text("Ibn Kathir (may Allah have mercy on him) explained the verse this way:"),
            .quote(text: "“Allah the Exalted commands His servants here to reflect on the Quran, and forbids them to turn away from it or from understanding its precise meanings and eloquent words. He tells them that there is no contradiction in it and no disorder, no opposition and no conflict, because it is a revelation from One who is Wise and Praiseworthy: it is truth from the Truth.” (Ibn Kathir, Tafsir al-Quran al-Azim, on 4:82)", arabic: "يقول تعالى آمرا عباده بتدبر القرآن، وناهيا لهم عن الإعراض عنه، وعن تفهم معانيه المحكمة وألفاظه البليغة، ومخبرا لهم أنه لا اختلاف فيه ولا اضطراب، ولا تضاد ولا تعارض؛ لأنه تنزيل من حكيم حميد، فهو حق من حق", dimmed: true),
            .text("Much contradiction is the natural mark of a long human work: claims that do not fit together, quality that rises and falls, a mind that changes about what matters. The Quran describes itself instead as a book whose parts resemble one another:"),
            .ayah("39:23", words: 0...6),
            .text("And it says of the man who recited it that his words, in conveying it, were not his own:"),
            .ayah("53:3-4"),
        ]),
        ArticleSection("THE AUTHOR WHO STEPS ASIDE", [
            .text("The clearest fingerprint of a human author is the author himself. Writers protect their image, settle their scores, and give themselves the last word. The Quran does the opposite with the man who recited it. One surah opens by reproving the Prophet (peace and blessings be upon him) for turning away from a blind man who came asking to be guided:"),
            .ayah("80:1-10"),
            .hadith("tirmidhi:3331", cite: "Jami` at-Tirmidhi 3331; its chain graded sahih by al-Albani", arabic: 22...79, english: [0...83]),
            .text("Elsewhere it asks him why he excused the hypocrites from an expedition (9:43), rebukes the taking of captives at Badr (8:67-68), and tells him after Uhud that the decision was not his (3:128). It has him declare that he does not know what will be done with him, and that he only follows what is revealed:"),
            .ayah("46:9"),
            .text("And it keeps words he would most have wanted to hide. Aishah said of a verse about his own marriage:"),
            .hadith("muslim:177b", cite: "Sahih Muslim 177", arabic: 17...57, english: [3...76]),
            .text("Nor could he produce a verse when he needed one. When his wife was slandered, the gravest personal crisis of his life, a month passed with nothing revealed about her:"),
            .hadith("bukhari:4750", cite: "Sahih al-Bukhari 4750", arabic: 987...994, english: [1539...1551]),
            .text("The same man refused a flattering myth on one of the worst days of his life. The sun was eclipsed on the day his infant son Ibrahim died, and his people drew the conclusion their age expected:"),
            .hadith("bukhari:1060", cite: "Sahih al-Bukhari 1060", arabic: 17...48, english: [0...54]),
            .text("An author can always write the next page, and a grieving father is tempted to accept an omen that honours his son. A man who waits a month under public humiliation, corrects the omen, and says of the book that it is not his to change (10:15) is behaving as someone who receives, not someone who composes."),
        ]),
        ArticleSection("AN HONEST CAVEAT", [
            .text("The test makes a narrow claim, and it should be stated exactly. Critics do allege errors in the Quran: about the setting of the sun, the stages of the embryo, the heart as the seat of understanding, and more. The claim here is not that no one has ever alleged a mistake. It is that after fourteen centuries of close and often hostile reading, no one has produced from the Quran a clear error that all sides now accept, of the kind that Galen’s pores and Darwin’s gemmules are: errors that no one, friend or critic, still defends."),
            .text("An alleged error is a contested reading, and each deserves its own answer. The best known concerns Dhul-Qarnayn, who travelled west until he found the sun setting in a spring of dark mud (18:86). The classical commentators read this as a description of what he saw, not a claim about where the sun goes. Ibn Kathir wrote:"),
            .quote(text: "“He saw the sun, as it appeared to him, setting in the surrounding ocean. This is how it is for everyone who reaches its shore: he sees it as if it were setting into it, while it does not leave the fourth sphere in which it is fixed.” (Ibn Kathir, Tafsir al-Quran al-Azim, on 18:86)", arabic: "رأى الشمس في منظره تغرب في البحر المحيط، وهذا شأن كل من انتهى إلى ساحله، يراها كأنها تغرب فيه، وهي لا تفارق الفلك الرابع الذي هي مثبتة فيه لا تفارقه", dimmed: true),
            .text("Notice where the fingerprint lies. The fourth sphere is Ptolemy’s astronomy, which set the sun in the fourth sphere out from the Earth; it belongs to Ibn Kathir’s century and appears in his commentary. The verse itself says nothing of spheres. Human explanations of the Quran carry the marks of their age, as every human work does. The test asks whether the Quran carries them."),
            .door(.article("ProvingScienceView")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**Isn’t this an argument from silence?**"),
            .text("Only in the way that a missing alibi is. Silence counts as evidence where evidence would be expected, and the test is built on exactly that: it looks for marks in the places where a life like this one leaves them. It also does not stand alone. It is one strand of a cumulative case, and each chapter it points to brings positive evidence of its own."),
            .markdown("**Did the Prophet never make a mistake?**"),
            .text("In his personal opinion on worldly matters he could, and he said so himself. When a passing remark of his about pollinating date palms did not work out, the Prophet (peace and blessings be upon him) told the farmers:"),
            .hadith("muslim:2362", cite: "Sahih Muslim 2362", arabic: 80...97, english: [52...93]),
            .text("The Quran, as we saw, also corrected his judgment in places. Scholars of the Sunnah therefore distinguish between what he conveyed from Allah (Glorified and Exalted be He), which is protected from error, and his own opinion on worldly craft. That distinction is the point of this chapter: where a human fingerprint could be expected in his opinions, he labelled it himself. The Quran carries no such label, because it never presents itself as his opinion."),
            .markdown("**Doesn’t abrogation show the text being revised?**"),
            .text("Abrogation (naskh) is announced by the Quran itself:"),
            .ayah("2:106"),
            .text("It concerns rulings, not facts: a law given in stages to a community that was changing, as wine was forbidden in stages. Most scholars of usul al-fiqh hold that pure reports, of what happened or what will happen, cannot be abrogated at all, since a report that was withdrawn would simply be a report that was false. No prediction, no story of the past and no statement about creation is ever taken back."),
            .markdown("**Couldn’t a careful author simply avoid claims that might fail?**"),
            .text("He could, and the book would look very different. The Quran does the opposite. It names outcomes in advance, challenges its hearers to match it (2:23-24), legislates in detail, tells the histories of earlier nations, and speaks often of the sky, the earth, the sea and the body. A cautious forger keeps to safe generalities; the Quran repeatedly places itself where it can be checked."),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Great human minds leave the errors of their age in their work, and no one now defends Galen’s pores or Darwin’s gemmules. The Quran came through one man across twenty-three years that should have left every kind of human mark, and it invites the search itself (4:82). Critics allege errors, and each allegation deserves its answer, but no clear error accepted by all sides has been produced, while the book rebukes the man who recited it and he, in turn, refused the myth his own people offered him. That absence is not a proof on its own. It is one strand, and a strong one, of a cumulative case."),
        ]),
        ArticleSection("KEY TERMS", [
            .term("Ikhtilaf", arabic: "اِختِلَاف", meaning: "From the root **خ-ل-ف**: difference, inconsistency, parts at odds with one another. It is the word of 4:82, which says that a book from other than Allah (Glorified and Exalted be He) would contain much of it."),
            .term("Wahy", arabic: "وَحي", meaning: "**Revelation.** In the language, a swift and hidden communication; in the Quran, what Allah conveys to His messengers. The Quran says of what the Prophet (peace and blessings be upon him) conveyed that it is “not but a revelation revealed” (53:4)."),
            .term("Naskh", arabic: "نَسخ", meaning: "**Abrogation**: the replacement of one ruling by a later one, announced in 2:106. It concerns commands and rulings, not reports of fact."),
            .term("Ummi", arabic: "أُمِّيّ", meaning: "**Unlettered**: the Quran’s description of the Prophet (7:157), who neither recited a scripture nor wrote one before the revelation came (29:48)."),
        ]),
    ]
}

struct ProvingProphetView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "ProvingProphetView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Prophet’s Character")
        .selectableArticleList(article: "ProvingProphetView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: a claim to speak for God is also a claim about the man who makes it. The people who knew Muhammad (peace and blessings be upon him) best, his wife, his townsmen, and his fiercest enemy, all testified that he did not lie; every motive a fraud could have (money, power, praise, pleasure, revenge, an easy life) fails against the sound record of his life; and the book he recited corrected him in public."),
        ]),
        ArticleSection("EXAMINE THE CLAIMANT", [
            .text("When a man says that God has spoken to him, there are only a few possibilities: he is telling the truth, he is lying, or he is deceived. So Proving Islam turns from the book to the man: we do not only weigh the claim, we weigh the claimant. People lie for reasons, among them money, status, power, pleasure, revenge, the advantage of their tribe, or a troubled mind, and a claim kept up for twenty-three years, in public and among enemies, leaves a long trail. This page follows that trail using the sound reports only: what his wife, his townsmen, and his enemies said of him, and what his life shows about each motive."),
            .text("The Quran makes the same argument itself. When his opponents demanded a different scripture, Allah (Glorified and Exalted be He) told the Prophet (peace and blessings be upon him) to answer with two facts: the revelation was not his to change, and they had known him for a lifetime before it:"),
            .ayah("10:15-16", words: 49...56),
            .text("That lifetime was forty years. Ibn ‘Abbas (may Allah be pleased with him) summed up the whole span of the mission in one sentence (Sahih al-Bukhari 3902), and any account of the man has to explain both parts of it: the forty years before the claim and the twenty-three after it."),
            .stats([
                ArticleStat("40", "his age when the revelation began"),
                ArticleStat("13 years", "of preaching in Makkah"),
                ArticleStat("10 years", "in Madinah after the Hijrah"),
                ArticleStat("63", "his age at his death"),
            ]),
            .door(.article("ProphetPillarView")),
        ]),
        ArticleSection("FORTY YEARS WITHOUT A LIE", [
            .markdown("Before the revelation he was not known as a poet, an orator, or a preacher. The biographers report that Makkah called him **al-Amin (الأَمِين)**, the Trustworthy, and a nickname is a verdict that other people give. The sound hadith preserve the same verdict in his townsmen’s own words. When the command came to warn his nearest kin (Quran 26:214), the Prophet (peace and blessings be upon him) climbed the hill of as-Safa and called the clans of Quraysh until they gathered:"),
            .hadith("bukhari:4971", cite: "Sahih al-Bukhari 4971", arabic: 56...82, english: [43...88]),
            .text("Proving Islam calls this testimony against interest. Before making the claim they would reject, he had the assembly confirm in public that he had never been caught in a lie, and no one in the crowd offered a counter-example, not even his uncle Abu Lahab, who answered with a curse. The men who would soon call him a liar had just certified his honesty."),
            .text("Their later rejection kept the same strange shape, and the Quran names it. What they refused was the message, not the man’s truthfulness:"),
            .ayah("6:33"),
        ]),
        ArticleSection("THE WITNESS WHO KNEW HIM BEST", [
            .text("The first revelation came to the Prophet (peace and blessings be upon him) alone, in the cave of Hira, and he did not come home triumphant. He came home trembling, asking to be wrapped up, afraid for himself. Khadijah (may Allah be pleased with her), his wife of some fifteen years, answered his fear with evidence, the evidence of how he had lived:"),
            .hadith("bukhari:3", cite: "Sahih al-Bukhari 3", arabic: 179...204, english: [304...346]),
            .text("Proving Islam draws the right lesson: this is not loyalty, it is testimony. The one person who had watched him at home, with money, with guests, with the poor, and in private, reasoned from his character to her conclusion: Allah (Glorified and Exalted be He) would never disgrace such a man. The scene also records something no forger would invent about himself: an impostor does not open his career by fearing for his own mind and being steadied by his wife."),
            .text("She then took him to her cousin Waraqa ibn Nawfal, an old man who had become a Christian and knew the earlier scriptures. In the same hadith Waraqa recognised the angel as the one sent to Musa (peace be upon him), and warned that the Prophet’s people would drive him out, because no one had ever brought such a message without meeting hostility. The next chapter follows that thread."),
            .door(.article("ProvingContinuationView")),
        ]),
        ArticleSection("THE ENEMY ON THE WITNESS STAND", [
            .text("Years later, during the truce of al-Hudaybiyah, the Byzantine emperor Heraclius summoned a caravan of Qurayshi merchants trading in greater Syria and questioned its leader, Abu Sufyan ibn Harb, then the chief opponent of the Prophet (peace and blessings be upon him). Abu Sufyan accepted Islam years later (may Allah be pleased with him), but on that day he was an enemy. Heraclius placed Abu Sufyan’s companions behind him and told them to contradict him if he lied. Abu Sufyan admitted afterwards:"),
            .hadith("bukhari:7", cite: "Sahih al-Bukhari 7", arabic: 115...124, english: [175...198]),
            .text("So the questions were answered by an enemy who wanted to lie and could not. Heraclius asked about the Prophet’s lineage; whether anyone among them had made the same claim before him; whether any of his ancestors had been a king; whether the nobles or the weak followed him; whether his followers were growing; whether anyone left his religion out of dislike for it; whether he broke his word; and what he commanded. The answers came back: a noble lineage, no precedent to imitate, no lost throne to reclaim, the weak, growing, no one, never, and the worship of Allah (Glorified and Exalted be He) alone with prayer, truthfulness, chastity, and ties of kinship. Then Heraclius drew the conclusion that matters here:"),
            .hadith("bukhari:7", cite: "Sahih al-Bukhari 7", arabic: 331...355, english: [585...629]),
            .text("Historians give special weight to the testimony of a hostile witness, and this is hostile testimony under cross-examination. The only insinuation Abu Sufyan managed was that Quraysh did not yet know what the Prophet would do during the truce. The treaty answered him: when Abu Basir, a new Muslim from Quraysh, escaped to Madinah and Quraysh sent two men to claim him under its terms, the Prophet handed him over to them (Sahih al-Bukhari 2731)."),
        ]),
        ArticleSection("EVERY MOTIVE TESTED", [
            .text("Proving Islam’s next step is to take each motive a fraud could have and test it against the record. Here is that record, one line for each motive, from the Quran and the sound reports:"),
            .checklist([
                "**Wealth:** he died with his armour pledged for barley, left no dinar or dirham, and his heirs inherited nothing (Sahih al-Bukhari 2916, 2739, 6727).",
                "**Power:** as head of state he slept on a palm-leaf mat, and he told a trembling visitor that he was no king (Sahih al-Bukhari 4913; Sunan Ibn Majah 3312, graded sahih by al-Albani).",
                "**Status:** honoured before the call, he was mocked, boycotted with his whole clan, and plotted against after it (Sahih al-Bukhari 1590; Quran 8:30).",
                "**Praise:** when people linked an eclipse to his son’s death, he denied it on the spot (Sahih al-Bukhari 1043).",
                "**Pleasure:** the call came at forty, and until he was about fifty his only wife was Khadijah (Sahih al-Bukhari 3902; Sahih Muslim 2436).",
                "**Revenge:** offered the destruction of a people who had just rejected him, he hoped instead that their descendants would come to worship their Lord alone (Sahih al-Bukhari 3231).",
                "**Compromise:** asked to bring a different Quran or to change it, he said it was not his to change (Quran 10:15; 68:9).",
                "**Convenience:** the revelation corrected him in public, and he recited every correction himself (Quran 80:1-10; 9:43; 66:1; 33:37).",
            ], title: "What Could He Have Wanted?", icon: "questionmark.circle.fill"),
            .text("Some of these are worth seeing through the eyes of those who saw them. ‘Umar ibn al-Khattab (may Allah be pleased with him) once entered the upper room where the Prophet (peace and blessings be upon him) had withdrawn, at a time when he already governed Madinah and much of Arabia:"),
            .hadith("bukhari:4913", cite: "Sahih al-Bukhari 4913", arabic: 425...488, english: [657...776]),
            .text("When the sun was eclipsed on the day his infant son Ibrahim died, the people handed him a ready-made sign of heaven’s grief. A man hungry for status would have let the eclipse speak for him; he corrected it in public, in his mourning:"),
            .hadith("bukhari:1043", cite: "Sahih al-Bukhari 1043", arabic: 24...65, english: [0...63]),
            .text("His poverty was not a pose for visitors either. ‘A’ishah (may Allah be pleased with her) told her nephew that two months could pass without a cooking fire lit in the Prophet’s houses, when they lived on dates and water (Sahih al-Bukhari 6459), and he died with his armour still pledged for a debt of barley:"),
            .hadith("bukhari:2916", cite: "Sahih al-Bukhari 2916", arabic: 20...34, english: [0...17]),
            .text("Nor could pressure move him. The well-known words about the sun in his right hand and the moon in his left come through a weak chain, so this page leaves them aside, but a sound report of a similar scene exists. When Quraysh complained about him to his uncle Abu Talib, the Prophet pointed to the sun and said that he was no more able to give up his mission than they were able to light a flame from it (reported by Abu Ya‘la and al-Hakim from ‘Aqil ibn Abi Talib; al-Albani graded its chain hasan, as-Silsilah as-Sahihah 92)."),
        ]),
        ArticleSection("A BOOK THAT CORRECTS ITS MESSENGER", [
            .text("Proving Islam states the next test sharply: a false prophet protects his ego, and the Quran does not behave like a man protecting himself. Surah ‘Abasa opens by reproaching the Prophet (peace and blessings be upon him) for frowning and turning away from a blind man, Ibn Umm Maktum, who had come asking to be guided while the Prophet was trying to win over a leader of the idolaters (Jami` at-Tirmidhi 3331; its chain graded sahih by al-Albani):"),
            .ayah("80:1-10"),
            .text("He recited these verses to the people himself, and they have been recited in prayer ever since. The same pattern runs through the Quran. After Badr, the ransom he accepted for the captives was reproached (Quran 8:67-68), and Sahih Muslim (1763) records that he and Abu Bakr (may Allah be pleased with him) wept over it. When he excused the hypocrites from the expedition to Tabuk, the rebuke began with a pardon:"),
            .ayah("9:43"),
            .text("When he forbade himself something lawful to please his wives, a surah opened by asking him why (Quran 66:1). And the verse he had most reason to hide concerns his own marriage. Zayd ibn Harithah (may Allah be pleased with him), his freed slave and adopted son, was unhappy with his wife Zaynab. Allah (Glorified and Exalted be He) had told the Prophet that she would become his wife after Zayd divorced her, a marriage meant to end the Arabs’ taboo on marrying the former wife of an adopted son, and the Prophet, fearing what people would say, kept this to himself and told Zayd to keep his wife. That is how al-Qurtubi explains what he concealed, calling it the best interpretation of the verse, as ‘Ali ibn al-Husayn and az-Zuhri explained it before him:"),
            .ayah("33:37", words: 13...24),
            .text("A man editing his own scripture would have deleted this verse first. ‘A’ishah (may Allah be pleased with her) said exactly that:"),
            .hadith("bukhari:7420", cite: "Sahih al-Bukhari 7420", arabic: 17...49, english: [0...46]),
        ]),
        ArticleSection("THE SAME MAN TO THE END", [
            .text("Frauds tend to change when the danger is over and the rewards arrive. The Prophet (peace and blessings be upon him) entered Makkah as its conqueror and ended his life as the ruler of most of Arabia, yet he died as he had lived. His brother-in-law described the estate he left:"),
            .hadith("bukhari:2739", cite: "Sahih al-Bukhari 2739", arabic: 33...58, english: [12...52]),
            .text("His family received none of it, because he had taught that the prophets leave no inheritance and that what they leave is charity (Sahih al-Bukhari 6727). In his final illness his worry was not his memory but his community’s worship: he warned them against taking the graves of prophets as places of prayer, and ‘A’ishah (may Allah be pleased with her) said that this fear is why his own grave was not made prominent (Sahih al-Bukhari 1330). His last counsel was for the prayer, and for the slaves in their care:"),
            .hadith("abudawud:5156", cite: "Sunan Abi Dawud 5156; graded sahih by al-Albani", arabic: 23...40, english: [0...21]),
            .door(.article("SeerahView")),
        ]),
        ArticleSection("HE DOES NOT SPEAK FROM DESIRE", [
            .text("The Quran’s own description of the speech of the Prophet (peace and blessings be upon him) is brief:"),
            .ayah("53:3-4"),
            .text("Proving Islam’s point is that the argument does not rest on the Quran saying so. It rests on twenty-three years of conduct that fit it. A man who composes his revelation can edit it; a man who receives it cannot. The public corrections, the refusal to trade the message for peace or power, the mat and the pledged armour, and his care to separate his own opinion from what was revealed (see the first question below) are what we would expect of someone who believed he was carrying a message, not writing one. The Quran even names the penalty for the forgery it is accused of:"),
            .ayah("69:44-47"),
            .callout("Proving Islam sets the profile out side by side. A fraud optimises; a politician negotiates; a poet seeks praise; a king seeks wealth; a liar avoids claims that can be checked. Muhammad (peace and blessings be upon him) refused wealth, refused compromise, accepted humiliation, made predictions that could be checked, denied authorship of the most admired text in the Arabic language, and submitted to a revelation that restrained and corrected him. Whatever model of the man a critic proposes has to survive contact with that record.", title: "The Profile Contradiction", icon: "scalemass.fill"),
            .door(.article("ProvingProphecyView")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**Could he have been sincere but deluded?**"),
            .text("Delusion does not usually come with this kind of judgement. The Prophet (peace and blessings be upon him) planned, negotiated treaties, weighed advice, and, most tellingly, kept his own opinion apart from revelation. When a passing remark of his about pollinating date palms reduced the harvest in Madinah, he said:"),
            .hadith("muslim:2362", cite: "Sahih Muslim 2362", arabic: 51...97, english: [0...93]),
            .text("A deluded man takes everything in his head for a voice from heaven. This man drew the line himself and told people exactly where it ran."),
            .markdown("**Aren’t these reports from his own followers?**"),
            .text("Many are, and the hadith scholars tested their chains with a severity few ancient records ever received. But look at what they preserve: his fear at Hira, his frown at a blind man, his mistaken advice on the palms, his poverty, and the admission of an enemy that he would have lied if he could. Propaganda does not keep such things. And the corrections themselves are in the Quran, which his followers recite aloud in prayer every day."),
            .door(.article("HadithSciencesView")),
            .markdown("**He did gain power in Madinah. Doesn’t that reveal the motive?**"),
            .text("Power came only after thirteen years in which the message had cost him everything, so it cannot have been the bait. The real test is what he did with it, and the record is the mat, the pledged armour, and an estate of a mule, some weapons, and land already given away. Nor did he found a dynasty: his heirs inherited nothing, and when two young men of his own clan asked to be made collectors of the charity, a paid post, he refused, saying that charity was not fitting for the family of Muhammad (Sahih Muslim 1072)."),
            .markdown("**Why would a true prophet need to be corrected?**"),
            .markdown("Ahl as-Sunnah hold that the prophets are **protected (مَعصُوم)** in conveying the message: they do not lie about Allah (Glorified and Exalted be He), hide what they were told to deliver, or add to it. Where a prophet judged a matter by his own reasoning before revelation came, he could choose the less perfect course, and when that happened revelation corrected him and he was never left upon it. The corrections do not weaken the case; they are part of it, because they show a revelation that stood over the man instead of serving him."),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("His townsmen, his wife, and his enemy all testified that he did not lie. Every motive a fraud could have fails against the sound record: he lived poor, ruled without a crown, refused credit he had not earned, forgave those who rejected him, and died owning almost nothing. The book he brought corrected him in public, and he recited the corrections himself. The simplest explanation of such a man is the one he gave: he did not speak from desire; it was revelation revealed."),
        ]),
        ArticleSection("KEY TERMS", [
            .term("al-Amin", arabic: "الأَمِين", meaning: "From the root **أ-م-ن**, safety and trust: the one who can be trusted with whatever is placed in his keeping. The biographers report it as Makkah’s name for the Prophet (peace and blessings be upon him) before his mission."),
            .term("Wahy", arabic: "وَحي", meaning: "From the root **و-ح-ي**, a swift and hidden communication: the revelation Allah (Glorified and Exalted be He) sends to His prophets. The Quran describes the Prophet’s speech as nothing but revelation revealed (Quran 53:4)."),
            .term("Hawa", arabic: "هَوَى", meaning: "From the root **ه-و-ي**, to fall or incline: personal inclination and desire. The Quran says the Prophet does not speak from it (Quran 53:3)."),
            .term("‘Ismah", arabic: "عِصمَة", meaning: "From the root **ع-ص-م**, to hold back and protect: the protection of the prophets in conveying the message, so that they neither lie about Allah nor conceal what they were sent with."),
        ]),
    ]
}

struct ProvingContinuationView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "ProvingContinuationView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("One Message, Many Messengers")
        .selectableArticleList(article: "ProvingContinuationView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: Islam does not claim that a new religion began in seventh-century Arabia. It claims that one message, to worship Allah (Glorified and Exalted be He) alone, was carried by a long line of messengers from Adam (peace be upon him) to Muhammad (peace and blessings be upon him), each confirming those before him and each opposed in the same way, and that the last of them brought a book kept safe so that no further messenger would be needed."),
        ]),
        ArticleSection("NOT A NEW RELIGION", [
            .text("Critics often describe Islam as a religion that Muhammad (peace and blessings be upon him) founded. Islam’s own claim is the reverse, and Proving Islam rightly treats it as the frame of the whole case: one message, to worship God alone, submit to Him, and live with justice and mercy, was sent through a long line of prophets; it was forgotten or altered after them; and it was restored and completed with the last. The Quran tells him to say so in so many words:"),
            .ayah("46:9"),
            .text("No people was left without that message. Allah (Glorified and Exalted be He) says:"),
            .ayah("16:36", words: 0...10),
            .text("The Quran names twenty-five prophets and says there were others whose stories it did not tell (Quran 4:164). Its attention to them surprises many first-time readers. By a count of its Arabic text, it names Musa (peace be upon him) more often than any other person, and it names Muhammad himself only four times:"),
            .stats([
                ArticleStat("136", "times Musa is named, more than anyone"),
                ArticleStat("69", "times Ibrahim is named"),
                ArticleStat("25", "times ‘Isa is named"),
                ArticleStat("4", "times Muhammad ﷺ is named (and once as Ahmad)"),
            ]),
            .text("A book composed to glorify its author would not look like this. It reads like what it says it is: the latest chapter of a very old story."),
        ]),
        ArticleSection("THE SAME WORDS IN EVERY MOUTH", [
            .text("The clearest mark of one message is one sentence. Surah al-A‘raf tells the stories of several prophets in turn, and each of them opens his mission with the same words. Nuh (peace be upon him) to his people:"),
            .ayah("7:59", words: 6...13),
            .text("Hud (peace be upon him) to the people of ‘Ad:"),
            .ayah("7:65", words: 6...13),
            .text("Salih and Shu‘ayb (peace be upon them) say it to Thamud and to Madyan, word for word (Quran 7:73, 7:85). Proving Islam draws the conclusion the Quran itself states: the message never changed, and the corruption came after the prophets, not from them. Allah (Glorified and Exalted be He) says:"),
            .ayah("21:25"),
            .text("The same confession survives in the Bible. The Torah’s central creed, which Jews call the Shema, appears in the Gospel of Mark on the lips of Jesus (peace be upon him) as the first of all the commandments:"),
            .quote(text: "“And Jesus answered him, The first of all the commandments is, Hear, O Israel; The Lord our God is one Lord” (Mark 12:29, King James Version, quoting Deuteronomy 6:4)", dimmed: true),
            .text("Muslims read this as the call every prophet made, still standing in the scriptures of those who came before. The Quran reports ‘Isa saying it to the Children of Israel in his own words: worship Allah, my Lord and your Lord (Quran 5:72)."),
            .door(.article("ProphetIsaView")),
        ]),
        ArticleSection("ONE RELIGION AND MANY LAWS", [
            .text("One message does not mean identical rulings. The prophets shared one religion: belief in Allah (Glorified and Exalted be He) alone and submission to Him. The laws given to each people differed in their details, for the Quran says that to each it gave a law and a way (Quran 5:48). It names the great messengers as sharers in one ordinance:"),
            .ayah("42:13", words: 1...23),
            .text("The Prophet (peace and blessings be upon him) put the relationship in an image from family life:"),
            .hadith("bukhari:3443", cite: "Sahih al-Bukhari 3443", arabic: 31...46, english: [4...39]),
            .text("Brothers of one father and different mothers: one religion, with different laws and ages. That is why a Muslim’s faith is incomplete without all of them. To reject one messenger is to reject the One who sent them all, and the believers are taught to say:"),
            .ayah("3:84"),
        ]),
        ArticleSection("THE RELIGION OF IBRAHIM", [
            .text("The word islam means submission to Allah (Glorified and Exalted be He), and the Quran uses it of the prophets and their followers long before the seventh century. Ibrahim (peace be upon him), claimed by Jews, Christians, and Muslims alike, is its clearest example:"),
            .ayah("3:67"),
            .ayah("3:95"),
            .checklist([
                "**Nuh:** told his people that he was commanded to be one of the Muslims (Quran 10:72).",
                "**Ibrahim and Isma‘il:** prayed, as they raised the House, to be made Muslims and to have a Muslim nation after them (Quran 2:128).",
                "**Yusuf:** asked his Lord to let him die a Muslim (Quran 12:101).",
                "**Musa:** told his people to rely on Allah if they were Muslims (Quran 10:84).",
                "**The disciples of ‘Isa:** asked him to bear witness that they were Muslims (Quran 3:52).",
            ], title: "Every Prophet a Muslim", icon: "checkmark.seal.fill"),
            .text("So islam, in the Quran’s sense, is not the name of a new sect but the name of what every messenger taught. When the Prophet (peace and blessings be upon him) wrote to the Byzantine emperor, he invited him to exactly this common ground, quoting the verse that calls the People of the Scripture to a word shared between them: that we worship none but Allah (Quran 3:64; Sahih al-Bukhari 7)."),
            .door(.article("ProphetIbrahimView")),
        ]),
        ArticleSection("THE LINE OF MESSENGERS", [
            .text("The hadith of intercession names the great messengers in their order. On the Day of Resurrection, the Prophet (peace and blessings be upon him) said, people will go from one to the next asking for intercession, addressing each by the honour Allah (Glorified and Exalted be He) gave him, and each will send them on until they reach the last. To Nuh (peace be upon him) they will say:"),
            .hadith("bukhari:4712", cite: "Sahih al-Bukhari 4712", arabic: 168...181, english: [291...313]),
            .chain([
                ArticleChainLink("Adam", "Father of mankind, created by Allah’s hand; he received words from his Lord"),
                ArticleChainLink("Nuh", "The first messenger to the people of the earth"),
                ArticleChainLink("Ibrahim", "The Khalil, the intimate friend of Allah"),
                ArticleChainLink("Musa", "Spoken to by Allah directly; given the Torah"),
                ArticleChainLink("‘Isa", "The Word Allah sent to Maryam, and a spirit from Him; given the Injil"),
                ArticleChainLink("Muhammad ﷺ", "The Messenger of Allah and the Seal of the Prophets"),
            ], caption: "The great messengers in the order the hadith of intercession names them (Sahih al-Bukhari 4712)"),
            .text("Between them came many more: Hud, Salih, Lut, Isma‘il, Ishaq, Ya‘qub, Yusuf, Shu‘ayb, Harun, Dawud, Sulayman, Yunus, Zakariya, and Yahya (peace be upon them all), and others whose names Allah did not tell us (Quran 4:163-164). Belief in every one of them is part of a Muslim’s faith."),
            .door(.article("ProphetsView")),
            .door(.article("ProphetMusaView")),
        ]),
        ArticleSection("THE SAME WELCOME FOR EVERY MESSENGER", [
            .text("If one message ran through the prophets, so did one reaction to it. The Quran observes that every messenger met the same accusations:"),
            .ayah("51:52-53"),
            .text("Proving Islam presses the point: if Muhammad (peace and blessings be upon him) had invented a new religion, why would his scripture insist that every earlier prophet taught the same core message and met the same charges of madness, sorcery, and lying? The pattern is too consistent across too many centuries to be an accident. The first person to see it in his life was an old Christian scholar. When Khadijah (may Allah be pleased with her) brought her husband to her cousin Waraqa ibn Nawfal after the first revelation, Waraqa said:"),
            .hadith("bukhari:3", cite: "Sahih al-Bukhari 3", arabic: 278...321, english: [436...505]),
            .text("Waraqa recognised the angel as the one sent to Musa (peace be upon him) and foresaw the Prophet’s exile before he had preached a single public sermon. Thirteen years later his people drove him out (Quran 8:30; Sahih al-Bukhari 3902)."),
        ]),
        ArticleSection("THE LAST BRICK", [
            .text("Where does the line end? The Prophet (peace and blessings be upon him) described his place in it with a parable:"),
            .hadith("bukhari:3535", cite: "Sahih al-Bukhari 3535", arabic: 34...67, english: [4...70]),
            .text("This is the language of completion, not abolition. The house was built by the prophets before him; he is the brick that finishes it. The Quran states the same fact without a parable:"),
            .ayah("33:40"),
            .text("His place at the end of the line was decreed before the line began. Asked when prophethood was established for him, he answered:"),
            .hadith("tirmidhi:3609", cite: "Jami` at-Tirmidhi 3609; graded sahih by al-Albani", arabic: 27...41, english: [0...23]),
            .text("Ibn Taymiyyah explained that Allah (Glorified and Exalted be He) wrote his prophethood and made it known while Adam (peace be upon him) was still between spirit and body. The hadith speaks of Allah’s decree and knowledge, not of the Prophet’s person existing before his birth, and he rejected the popular wording “between water and clay” as false. The Prophet was born of a father and a mother in Makkah and received the revelation at forty, and he never claimed to have existed before his birth."),
        ]),
        ArticleSection("WHY THE LAST MESSAGE WAS KEPT", [
            .text("The logic of the line requires an end. Each earlier messenger was sent to his own people for his own time, to confirm what came before and to correct what later hands had changed; the last was sent to all people (Quran 34:28; Sahih al-Bukhari 335). A final message for everyone until the end of time needs what the earlier ones were not promised: preservation. The Quran draws this line itself. Of the Torah it says that the rabbis and scholars judged by what they had been entrusted to guard of Allah’s Book (Quran 5:44), and elsewhere that some distorted its words and forgot part of what they had been reminded of (Quran 5:13). Of the Quran, Allah (Glorified and Exalted be He) takes the guarding on Himself:"),
            .ayah("15:9"),
            .text("So the claim of finality and the claim of preservation stand or fall together. A final prophet with a lost book would leave humanity without guidance, and a preserved book is what makes a further prophet unnecessary. Proving Islam puts it as a question: if God sends prophets, and earlier revelations were altered, what would a final, preserved revelation look like? Whether the Quran fits that description is the subject of its own chapter."),
            .door(.article("ProvingPreservationView")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**If every prophet taught the same thing, why follow Muhammad rather than Musa or ‘Isa?**"),
            .text("Because following them now means following the one they were bound to accept. The Quran says that Allah (Glorified and Exalted be He) took a covenant from the prophets: if a messenger came to them confirming what they had, they would believe in him and support him (Quran 3:81). Each earlier messenger was sent to his own people, while the last was sent to all (Sahih al-Bukhari 335), and his book is the one that has reached us as it was revealed. Following Muhammad (peace and blessings be upon him) is not leaving Musa and ‘Isa (peace be upon them): a Muslim believes in both, and the Prophet called himself the nearest of all people to ‘Isa (Sahih al-Bukhari 3443, quoted above)."),
            .markdown("**Doesn’t the resemblance show that the Quran borrowed from the Bible?**"),
            .text("Resemblance is what one message predicts. Borrowing predicts something more specific: copied details and copied mistakes. Where the Quran retells the same events it tells them in its own way, and at some points it departs from the biblical account in ways that later chapters examine. That question is weighed in full on its own page."),
            .door(.article("ProvingSourcesView")),
            .markdown("**Did Islam begin in 610, or with Adam?**"),
            .text("Both, in different senses. As submission to Allah alone, Islam is the religion of every prophet from Adam onward, which is why the Quran can say that the religion with Allah is Islam (Quran 3:19). As a particular law and community, it began when the revelation came to Muhammad (peace and blessings be upon him) in about 610 CE. The first is the message; the second is its final form."),
            .markdown("**Why did so many prophets need to be sent?**"),
            .text("Because the message was forgotten or altered after each messenger passed, and because each people needed a messenger who spoke its own language (Quran 14:4). The line ends because the last message was guarded, not left to its keepers."),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Islam presents itself not as something new but as the oldest message there is: worship Allah (Glorified and Exalted be He) alone. Nuh, Hud, Salih, and Shu‘ayb (peace be upon them) opened their missions with the same sentence; Ibrahim, Musa, and ‘Isa taught the same creed under different laws; every one of them met the same accusations; and a Christian scholar recognised the pattern on the first day. Muhammad (peace and blessings be upon him) is the last brick of that house, and the Quran, guarded as the earlier books were not, is why the line could end with him."),
        ]),
        ArticleSection("KEY TERMS", [
            .term("Nabi", arabic: "نَبِيّ", meaning: "From the root **ن-ب-أ**, to bring news: a prophet, one who receives revelation from Allah (Glorified and Exalted be He)."),
            .term("Rasul", arabic: "رَسُول", meaning: "From the root **ر-س-ل**, to send: a messenger, sent with a message to a people. Every messenger is a prophet, but not every prophet is a messenger."),
            .term("Khatam an-Nabiyyin", arabic: "خَاتَم النَّبِيِّين", meaning: "From the root **خ-ت-م**, to seal or complete: the Seal of the Prophets, the title the Quran gives Muhammad (peace and blessings be upon him) in Quran 33:40."),
            .term("Hanif", arabic: "حَنِيف", meaning: "From the root **ح-ن-ف**, to incline: one who turns from every false worship to the worship of Allah alone, as Ibrahim did (Quran 3:67)."),
            .term("Din", arabic: "دِين", meaning: "From the root **د-ي-ن**, obedience and requital: religion at its core, the belief and submission all the prophets shared, as distinct from the **shir‘ah (شِرعَة)**, the law, which differed between them (Quran 5:48)."),
        ]),
    ]
}

struct ProvingStylometryView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "ProvingStylometryView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Two Voices: Quran and Hadith")
        .selectableArticleList(article: "ProvingStylometryView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: the Quran and the sayings of the Prophet (peace and blessings be upon him) came from the same man, in the same language, over the same twenty-three years, yet they do not read like the work of one author. Classical scholars heard the difference, and two modern studies have measured it: the Quran speaks with one consistent voice from beginning to end, and that voice is not the voice of his own speech. Style alone cannot prove where the Quran came from, but it closes off the simplest explanation of it."),
        ]),
        ArticleSection("ONE MAN AND TWO KINDS OF SPEECH", [
            .text("The Quran and the sayings of the Prophet (peace and blessings be upon him) reached the world through one mouth. The same man recited both, in the same Arabic, to the same community, over the same twenty-three years. If he had composed the Quran himself, the two would be one author’s work in two moods. They do not read that way, and Proving Islam calls this the two-author problem."),
            .text("His own sayings are the speech of a man among his people. He answers the question in front of him, explains, warns and consoles, and usually speaks to the listener before him about the matter at hand. The Quran speaks in the voice of the Lord of the worlds. It addresses all mankind, it moves in measured verses that close on matching sounds, it compresses a whole scene into a few words, and it speaks about the Prophet and to him. When it gives him words to speak, it usually introduces them with a command: Say."),
            .text("This is not a contrast between plain speech and fine speech. His own words were famous for their eloquence, and he said of himself:"),
            .hadith("muslim:523a", cite: "Sahih Muslim 523", arabic: 35...41, english: [0...23]),
            .text("‘Aisha (may Allah be pleased with her) described the way he spoke:"),
            .hadith("bukhari:3567", cite: "Sahih al-Bukhari 3567", arabic: 23...29, english: [0...22]),
            .text("So the difference is between two kinds of excellence, and it is easiest to hear when both speak about the same thing. Here is one subject, people on the Day of Resurrection too taken up with themselves to look at one another, in each voice:"),
            .versus(ArticleVersus.Side("His own words", caption: "**Sahih al-Bukhari 6527.** A question from ‘Aisha and his answer to her: one plain sentence, spoken in conversation."), ArticleVersus.Side("The Quran", caption: "**Surah ‘Abasa 80:34–37.** The same scene in four short verses that all close on one sound, spoken to every human being.")),
            .hadith("bukhari:6527", cite: "Sahih al-Bukhari 6527", arabic: 34...67, english: [0...43]),
            .ayah("80:34-37"),
            .text("In another narration a woman asked him the same question, and that time his answer was the last of those verses, 80:37, word for word (Jami` at-Tirmidhi 3332; graded hasan sahih by al-Albani). The same question drew an answer in each voice, and he kept the two apart himself:"),
            .hadith("muslim:3004", cite: "Sahih Muslim 3004", arabic: 29...37, english: [0...21]),
            .text("The scholars explain that this was an early instruction, meant to keep anything else from being written alongside the Quran; later he allowed his sayings to be written down, and had one of his sermons written out for a man from Yemen who asked for it (Sahih al-Bukhari 2434). From the first day, the community treated the Quran as a text apart."),
        ]),
        ArticleSection("HEARD LONG BEFORE IT WAS MEASURED", [
            .text("Muslim scholars pointed to this gap nearly a thousand years before anyone counted words by computer. The judge Abu Bakr al-Baqillani (d. 403 AH), in his book on the inimitability of the Quran, copied out sermons and letters of the Prophet (peace and blessings be upon him) so that readers could set them beside the Quran for themselves, and he concluded:"),
            .quote(text: "“When we weigh his sermons, his letters and his prose speech against the composition of the Quran, the distance between them appears as the distance between the speech of Allah and the speech of people.” (al-Baqillani, I'jaz al-Quran, the chapter on the speech of the Prophet)", arabic: "إذا وازنا بين خطبه ورسائله وكلامه المنثور، وبين نظم القرآن، تبين من البون بينهما مثل ما بين كلام الله عز وجل وبين كلام الناس"),
            .text("His reasoning was simple. If the Quran were the Prophet’s own composition, the distance between it and his other speech would be the distance between two sermons by one man, and his opponents, masters of the same language, would have matched it. The Quran makes a related argument from the life he had lived among them before it began:"),
            .ayah("10:16", words: 10...15),
            .ayah("29:48"),
            .text("Forty years among his people had given them a full measure of how he spoke. Nothing in that measure prepared them for what he began to recite, and the verse invites them to draw the conclusion. What al-Baqillani did by ear, modern stylometry tries to do by count."),
            .door(.article("ProvingSourcesView")),
        ]),
        ArticleSection("WHAT THE COMPUTER FOUND", [
            .markdown("**Stylometry** measures the habits of a writer that he does not choose on purpose: how often he uses the small connecting words, how long his words and sentences run, which sounds his lines end on. It is used to settle disputed authorship, and in 2012 **Halim Sayoud**, a professor of electronics and computer science at the University of Science and Technology Houari Boumediene in Algiers, applied it to the Quran and the hadith in the peer-reviewed journal Literary and Linguistic Computing (volume 27, issue 4)."),
            .text("He took the whole Quran, about 87,000 words, and a sample of about 23,000 words of hadith from Sahih al-Bukhari, and ran three series of experiments on them: nine on each text taken whole, five on four segments cut from each, and two in which classification programs had to sort unlabelled segments by author."),
            .stats([ArticleStat("62%", "of the distinct words in the hadith sample never occur in the Quran"), ArticleStat("83%", "of the Quran’s distinct words never occur in the hadith sample"), ArticleStat("2.52 vs 0.46", "average rhyme between neighbouring sentences, Quran vs hadith"), ArticleStat("100%", "sorting accuracy with almost every feature and classifier tried")]),
            .text("The vocabulary figures need one caution, which Sayoud gave himself: the Quran is nearly four times the size of the hadith sample, and a larger text will always hold more words that a smaller one lacks. That is why he also cut both books into segments of about ten pages each and compared like with like. The segments of each book resembled one another clearly more than they resembled any segment of the other, and when programs were given one segment of each book as a reference and asked to assign the rest, almost every method sorted every segment correctly."),
            .text("His rhyme measure tells the story most simply. He scored each sentence by how closely its ending matched the endings of its neighbours. The Quran averaged about 2.5 and the hadith under 0.5, and the figure stayed almost the same in every segment of each. The Quran rhymes from beginning to end; the everyday speech of the Prophet (peace and blessings be upon him), however eloquent, does not."),
            .quote(text: "“We can statistically state that the two investigated books have two different authors or at least two different styles.” (Halim Sayoud, ‘Author discrimination between the Holy Quran and Prophet’s statements,’ Literary and Linguistic Computing 27:4, 2012)"),
            .text("In his discussion Sayoud went further and concluded that the Quran was not written by the Prophet and that it has a single author of its own. The careful wording in the quotation above, two authors or at least two styles, is the part the numbers themselves establish."),
            .markdown("**A note on the sources.** Sayoud later expanded this work into a book, Investigation on the Author’s Style and the Authenticity of the Holy Quran, and self-published its third edition (2025) on the open repository Zenodo. That book has not been through peer review, although the Proving Islam page describes it as peer-reviewed, so the figures on this page are taken only from the 2012 journal article."),
        ]),
        ArticleSection("ONE VOICE FROM MAKKAH TO MADINAH", [
            .markdown("The second study asks a different question: does the Quran itself come from one author? **Behnam Sadeghi**, then an assistant professor of religious studies at Stanford University, published a ninety-page stylometric analysis of the entire Quran in the journal Arabica in 2011 (“The Chronology of the Qurʾān: A Stylometric Research Program,” volume 58, pages 210–299)."),
            .text("He divided the text into passages and asked whether a proposed order of those passages could be confirmed by style alone, using four independent markers: average verse length, the frequencies of the 28 most common morphemes, a profile of 114 other common morphemes, and a list of 3,693 relatively uncommon ones. If all four change smoothly and together across a sequence of phases, the sequence is probably the order in which the passages came. He calls this the criterion of concurrent smoothness, and he found seven phases that pass it. He deliberately used none of the historical reports about when passages were revealed."),
            .quote(text: "“In addition to establishing a relative chronology in seven phases, this essay demonstrates the stylistic unity of many large passages. It also shows that the Qurʾān has one author.” (Behnam Sadeghi, Arabica 58, 2011, from the abstract)"),
            .text("His reasoning is worth following. If two authors had written the Quran, the style of the first would have had to drift steadily toward the style of the second on every marker at once; with three or more, each would have to fall neatly between the others. “It is much easier,” he writes, “to imagine a single author.” He also found that many long and medium passages are stylistically whole. The Scottish scholar Richard Bell had treated even Surah Yusuf as a patchwork of small fragments from several periods; against that view Sadeghi writes plainly, “The traditional understanding is correct.” And his style-based order fits the Makkan and Madinan periods of the life of the Prophet (peace and blessings be upon him) as the biographies record them."),
            .text("Sadeghi writes as an academic historian and makes no theological claim. His “one author” is a finding about style: a single, continuous voice behind the whole text. It rules out the idea that the Quran grew from many hands over generations, and it fits the Muslim account of a book delivered by one messenger over twenty-three years. Whose voice that is, his method does not say."),
            .text("Proving Islam draws out one more point. Those twenty-three years held persecution, boycott and hunger, exile and war, the deaths of Khadijah and Abu Talib, and the burial of his children. The Prophet’s own words carry his grief openly. At the deathbed of his infant son Ibrahim:"),
            .hadith("bukhari:1303", cite: "Sahih al-Bukhari 1303", arabic: 98...122, english: [86...120]),
            .text("The Quran never mourns Ibrahim, and it never so much as names Khadijah. When it speaks of the Prophet’s sorrow, it speaks to him, from outside it:"),
            .ayah("6:33"),
            .ayah("93:3"),
            .text("Style does change across the Quran: Makkan verses tend to be shorter and Madinan verses longer, and Sadeghi charts that change precisely. But it changes as one line develops, gradually and on every measure together, and the voice never becomes the voice of a grieving father or a victorious leader, though the man who delivered it was both. Proving Islam argues that a man composing under such pressures would leave their marks on his style. That is its inference rather than Sadeghi’s, and the reader can weigh it against the contrast above."),
        ]),
        ArticleSection("WHAT STYLE CAN AND CANNOT PROVE", [
            .callout("Stylometry supports two conclusions: the Quran and the recorded sayings of the Prophet (peace and blessings be upon him) come from **two different sources of style**, and the Quran itself comes from **one consistent author**. It cannot, by itself, name that author. That question is answered by the rest of the case: what the Quran says about itself, what it foretold, and whether anyone has matched it.", title: "What the Studies Show", icon: "scalemass.fill"),
            .text("Honesty requires three cautions. First, a person can speak in more than one register; a poet does not talk to his family in verse, and Sayoud’s own phrase, two authors or at least two styles, leaves room for that. Second, the hadith scholars allowed a narrator who knew Arabic well to convey a saying by its meaning, so part of the wording of some narrations belongs to those who transmitted them. Third, Sayoud’s samples were unequal and his test segments few, and other specialists have debated how much Sadeghi’s criterion can bear."),
            .text("What remains after those cautions is still striking. In twenty-three years of daily speech, public and private, the Quran never slips into the Prophet’s conversational voice. It addresses him, corrects him and describes him in the third person, which the chapter on his character examines. Its opponents accused him of inventing it, yet the names they reached for were poetry, magic and soothsaying, the names for extraordinary speech, never the way he ordinarily talked. And the Quran gives its own account of why the two differ:"),
            .ayah("53:3-4"),
            .door(.article("ProvingProphetView")),
            .door(.article("ProvingIjazView")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**Could he not simply have used a special style for the Quran?**"),
            .text("People do change register, and style by itself cannot rule that out, which is why this chapter does not rest the case on it. But the register would have had to be one no Arab had heard before, sustained without a slip for twenty-three years, kept apart from his daily speech in every setting, and beyond the reach of the finest poets of his people when the Quran challenged them to match it. The chapter on the unmatched Quran takes up that last point."),
            .markdown("**Aren’t the hadith partly the words of their narrators?**"),
            .text("Some are. Narrators who knew Arabic well were allowed to convey a saying by its meaning, and the Companions (may Allah be pleased with them) sometimes did, while many short sayings and supplications were kept word for word. So Sayoud’s figures describe the hadith as transmitted, not the exact wording of every line. That limit does not touch al-Baqillani’s comparison with the sermons and letters of the Prophet (peace and blessings be upon him), or the narrations in which he answered the same question once in his own words and once with a verse."),
            .markdown("**Is Sayoud’s study peer-reviewed?**"),
            .text("His 2012 article is. It appeared in Literary and Linguistic Computing, a journal published by Oxford University Press, and the paper thanks its anonymous reviewers. The longer book he self-published on Zenodo in 2025 as a third edition is not, and its further claims should be read as his own. This page reports only the journal article’s figures."),
            .markdown("**Does Sadeghi believe the Quran is from God?**"),
            .text("He does not say, and his article does not ask. He treats the Prophet as the one who delivered the Quran to his community, as any historian would, and draws conclusions only about style: one author, stylistically unified passages, and a gradual development in seven phases. A Muslim reads that result alongside the Quran’s own statement that it is revelation; a secular historian reads it within his own assumptions about revelation. The numbers alone do not decide between them."),
            .markdown("**Doesn’t the Quran’s style change between Makkah and Madinah?**"),
            .text("It does, and scholars of the Quran have always said so: Makkan passages tend to be short and urgent, Madinan ones longer and more detailed, as their subjects require. Sadeghi’s contribution was to show that the change is smooth and orderly on several independent measures at once, which is what one author developing over time looks like. One voice is not the same as an unchanging voice."),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("The same man delivered the Quran and his own sayings, yet the two do not sound like one author. Al-Baqillani heard the distance a millennium ago; Sayoud measured it through rhyme, vocabulary and classification programs; Sadeghi showed that the Quran on its own is one author’s work, developing smoothly across twenty-three years that marked the man who delivered it in every other way. Style cannot name that author, but it makes the simplest explanation, that he composed the Quran as he composed his own speech, much harder to hold."),
        ]),
        ArticleSection("KEY TERMS", [
            .term("Nazm", arabic: "نَظم", meaning: "From the root **ن-ظ-م**, to string pearls in order: the composition of the Quran, the way its words are chosen, arranged and joined. For al-Baqillani and the scholars after him, the Quran’s nazm is the heart of its inimitability."),
            .term("Fasilah", arabic: "فَاصِلَة", meaning: "The closing word of an ayah, plural **fawasil**. The Quran’s fawasil often share one sound across a run of verses, as in 80:34–37, and many scholars kept the word to set them apart from the rhymes of poetry and of the soothsayers."),
            .term("Jawami' al-kalim", arabic: "جَوَامِعُ الكَلِم", meaning: "“Comprehensive words”: short sayings that carry wide meanings. The Prophet (peace and blessings be upon him) counted them among the things he was favoured with (Sahih Muslim 523); they mark his own eloquence, which is not the Quran’s."),
            .term("Riwayah bil-ma'na", arabic: "الرِّوَايَةُ بِالمَعنَى", meaning: "Narrating by meaning: conveying a saying in one’s own words while keeping its sense exactly. Hadith scholars permitted it to a narrator who knew Arabic and what changes a meaning. The Quran is never transmitted this way."),
            .term("Makki and Madani", arabic: "مَكِّيّ وَمَدَنِيّ", meaning: "The division of the Quran into what came down before the Hijrah (Makkan) and after it (Madinan). Sadeghi’s stylometry, using no historical reports, found the same broad division in the style itself."),
        ]),
    ]
}

struct ProvingPreservationView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "ProvingPreservationView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Preserved as Promised")
        .selectableArticleList(article: "ProvingPreservationView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: the Quran was never left to a single fragile copy. It is kept at once in memory, in daily prayer, in chains of teachers, in the copies sent out by 'Uthman (may Allah be pleased with him), and by communities that correct one another, and the oldest manuscripts agree with the text recited today. Allah (Glorified and Exalted be He) promised this while the Muslims were a persecuted few, and the promise has held for fourteen centuries."),
        ]),
        ArticleSection("THE ALPHABET TEST", [
            .text("Proving Islam begins with a simple picture. A child recites the alphabet and says “A, B, C, G,” and everyone in the room corrects him at once. No one runs to check a manuscript. The sequence is safe because millions of people carry it, and an error has nowhere to hide."),
            .text("The Quran is kept the same way, at the scale of a civilisation. When an imam slips in a long recitation, someone in the rows behind him corrects him before the next verse, and this began in the lifetime of the Prophet (peace and blessings be upon him), who expected to be corrected:"),
            .hadith("abudawud:907", cite: "Sunan Abi Dawud 907; graded hasan by al-Albani", arabic: 35...70, english: [14...27, 29...71]),
            .text("Allah (Glorified and Exalted be He) described the Quran to His Prophet as a book that does not depend on ink:"),
            .hadith("muslim:2865a", cite: "Sahih Muslim 2865", arabic: 115...123, english: [151...178]),
            .ayah("29:49", words: 0...8),
            .text("A book that lives in memory cannot be washed away, burned or quietly edited, because every written copy of it is checked against people who know it by heart."),
        ]),
        ArticleSection("MANY SYSTEMS AND ONE TEXT", [
            .text("No single mechanism keeps the Quran, so no single failure could lose it. Each of the following goes back to the Prophet (peace and blessings be upon him) and his Companions (may Allah be pleased with them), and each checks the others:"),
            .checklist([
                "**Memorisation.** In every generation and every Muslim land, great numbers learn the whole Quran by heart, many of them as children.",
                "**Daily prayer.** Every Muslim recites from it in each of the seventeen obligatory units of prayer a day, and the imam recites aloud at dawn, sunset and night.",
                "**Ramadan.** The angel Jibril reviewed the Quran with the Prophet every Ramadan, and mosques across the world still complete it in the month’s night prayers.",
                "**Chains of teachers.** Reciters receive the text from a teacher who received it from a teacher, in chains that name each link back to the Prophet; a reciter who completes the course is granted an **ijazah**.",
                "**The 'Uthmanic copies.** A standard written text, sent to the provinces in the caliphate of 'Uthman (may Allah be pleased with him) and copied from ever since.",
                "**Communal correction.** A slip in public recitation is corrected on the spot, and a misprinted copy is caught by those who know the text.",
                "**The ten readings.** Specialists in the canonical qira'at preserve the recognised ways of reciting it, down to the letter.",
            ], title: "How the Quran Is Kept", icon: "checkmark.seal.fill"),
            .text("The annual review with Jibril is recorded by Abu Hurayrah (may Allah be pleased with him):"),
            .hadith("bukhari:4998", cite: "Sahih al-Bukhari 4998", arabic: 17...35, english: [0...27]),
            .text("And the Prophet made keeping it a constant duty, because memory that is not refreshed fades:"),
            .hadith("bukhari:5033", cite: "Sahih al-Bukhari 5033", arabic: 24...35, english: [0...31]),
            .text("When the Muslims had spread from Arabia to Armenia and began to dispute over how to recite, 'Uthman had the collection made under Abu Bakr (may Allah be pleased with him) copied into standard copies:"),
            .hadith("bukhari:4987", cite: "Sahih al-Bukhari 4987", arabic: 124...142, english: [187...217]),
            .text("The written copies were never the only safeguard. They were read aloud to people who knew the text by heart, and the memorised text was checked in turn against the copies."),
            .door(.article("CompileView")),
        ]),
        ArticleSection("A PROMISE MADE BY THE PERSECUTED", [
            .text("Surah al-Hijr is Makkan. When its ninth verse came down, the Muslims had no state and no army, the Quran was not yet complete, and it lived in the memories of a small community and on whatever could be written on, in a city ruled by its enemies. Into that situation Allah (Glorified and Exalted be He) said:"),
            .ayah("15:9"),
            .text("The promise is specific, and it could have failed. Proving Islam puts the point plainly: a man inventing a religion does not stake it on a promise that history could so easily break. The Quran also assured the Prophet (peace and blessings be upon him), while it was still being revealed, that its gathering and recitation were in Allah’s hands, and it describes itself as beyond the reach of falsehood:"),
            .ayah("75:16-19"),
            .ayah("41:42"),
            .door(.prophecy("quran-preserved")),
        ]),
        ArticleSection("ENTRUSTED TO OTHERS", [
            .text("The Quran draws the contrast itself. Of the Torah, Allah (Glorified and Exalted be He) says that its prophets, rabbis and scholars judged by it, with a telling phrase:"),
            .ayah("5:44", words: 13...22),
            .text("The keeping of the earlier scripture was entrusted to people; the keeping of the Quran Allah took upon Himself. The classical commentators read the two verses side by side:"),
            .quote(text: "“He, glorified be He, took its keeping upon Himself, so it has never ceased to be kept; and of the others He said ‘with that which they were entrusted,’ leaving their keeping to them, and they altered and changed.” (al-Qurtubi, al-Jami' li-Ahkam al-Quran, on 15:9)", arabic: "فتولى سبحانه حفظه فلم يزل محفوظا، وقال في غيره: بما استحفظوا، فوكل حفظه إليهم فبدلوا وغيروا"),
            .text("Muslims believe in the Torah and the Injil as Allah revealed them. What the Quran describes is a difference in how they were entrusted, not in where they came from, and the manuscript history of the Bible, set out later in this chapter, is what Muslims would expect of a scripture left in human keeping."),
        ]),
        ArticleSection("WHAT THE OLDEST MANUSCRIPTS SHOW", [
            .text("In 2015 the University of Birmingham announced the radiocarbon dating of two leaves in its Mingana Collection, written in the early Hijazi script and holding parts of Surahs 18 to 20. The test, carried out at the University of Oxford, placed the parchment between 568 and 645 CE with a probability of 95.4 percent, a span that includes the lifetime of the Prophet (peace and blessings be upon him)."),
            .stats([ArticleStat("568–645 CE", "radiocarbon range for the Birmingham leaves"), ArticleStat("95.4%", "probability of that range"), ArticleStat("Surahs 18–20", "the parts the two leaves hold")]),
            .quote(text: "“These portions must have been in a form that is very close to the form of the Qur’an read today, supporting the view that the text has undergone little or no alteration.” (Professor David Thomas, University of Birmingham, 2015)"),
            .text("Radiocarbon dates the animal whose skin became the parchment, not the ink, so the writing may be somewhat later, though scholars generally assume parchment was not left long before it was used. What matters most is that the words on the leaves follow the text recited today."),
            .text("The most discussed early manuscript is the Sana'a palimpsest, found in 1972 with thousands of other fragments in the Great Mosque of San'a in Yemen. A palimpsest is a parchment that was washed and written over, and here the erased lower layer is a Quran that does not belong to the 'Uthmanic line of copies, so far the only such manuscript known. Behnam Sadeghi and Mohsen Goudarzi, who edited its folios, report that radiocarbon places its parchment before 671 CE with 99 percent probability, and before 646 CE with 75 percent."),
            .text("Its differences from the standard text are real, and they are of a particular kind: a word added or missing, a pronoun, preposition or verb form changed, a phrase transposed, and occasionally two very short verses in the reverse order. In one place a whole verse is missing, which the editors attribute to a copyist’s eye skipping between two verses that end alike. The surahs hold the same passages, though they come in a different sequence. The editors found these differences to be of the same kinds that Muslim scholars recorded for the personal copies of Companions such as Ibn Mas'ud and Ubayy ibn Ka'b (may Allah be pleased with them) before 'Uthman (may Allah be pleased with him) unified the text, and they concluded that the surahs had already taken their shape before the lines of transmission branched:"),
            .quote(text: "“Some other early reports however indicate that this was done already by the Prophet himself. This last view is now found to be better supported.” (Behnam Sadeghi and Mohsen Goudarzi, Der Islam 87, 2012, on who joined the verses into surahs)"),
            .text("They also observed that where the traditions part ways, the 'Uthmanic text is usually on the side of the majority, and they note that if the traditions descend independently from the Prophet’s own recitation, this makes it the better reproduction of their common source. And the upper text, written over the erased one, is the standard Quran. The palimpsest does not reveal a different Quran. It preserves a Companion’s copy of the kind the early sources had always described, and a later hand wrote the standard text over it."),
        ]),
        ArticleSection("THE READINGS ARE NOT RIVAL TEXTS", [
            .text("Readers who learn that the Quran is recited in ten canonical readings sometimes suspect a crack in this picture. The opposite is true. The Prophet (peace and blessings be upon him) himself taught the Quran in more than one way. Two Companions, 'Umar and Hisham ibn Hakim (may Allah be pleased with them), once recited Surah al-Furqan differently, and 'Umar brought Hisham to the Prophet, who had each of them recite, approved both, and said:"),
            .hadith("bukhari:4992", cite: "Sahih al-Bukhari 4992", arabic: 177...187, english: [204...237]),
            .text("The ten readings are the ways of recitation that reached later generations through mass transmission, each fitting the consonantal outline of the 'Uthmanic copies and traced through named chains of teachers to the Prophet. Their differences lie in pronunciation and in word forms the outline allows, such as maliki and maaliki in al-Fatihah, and they never contradict one another. They are part of what was preserved, recorded letter by letter, not evidence that the text drifted. Readings outside that outline, like some of those in the Companions’ personal copies, are classed as irregular and are not recited as Quran."),
            .door(.article("QiraatView")),
        ]),
        ArticleSection("THE BIBLE AND ITS OWN SCHOLARS", [
            .text("The contrast with the Bible is drawn here with care, from what Christian and secular textual scholars themselves publish. The Bible is a library of books written over many centuries in Hebrew, Aramaic and Greek. No original manuscript of any of its books survives, and the New Testament was carried by copied manuscripts rather than by a community reciting the whole of it from memory, so its scholars reconstruct the text by comparing thousands of copies that differ in many small readings and some large ones. A few of the best known:"),
            .bullet("**The ending of Mark.** The last twelve verses of Mark (16:9–20) are absent from the two oldest complete manuscripts of that Gospel, Codex Sinaiticus and Codex Vaticanus, both from the fourth century. Modern Bibles print them in brackets or with a note."),
            .bullet("**The woman taken in adultery.** John 7:53–8:11 is absent from the earliest papyri of John, from around 200 CE, and from the same two codices. Most New Testament scholars, evangelical ones included, regard it as a later addition."),
            .bullet("**The Johannine Comma.** The one verse that states the Trinity outright appears in the King James Version, but in the text of no Greek manuscript earlier than the fourteenth century, and in only eight Greek manuscripts in all, several of them only in the margin in a later hand. It is first found in Latin in the fourth century, entered the printed Greek text through Erasmus in 1522, and modern translations leave it out:"),
            .quote(text: "“For there are three that bear record in heaven, the Father, the Word, and the Holy Ghost: and these three are one.” (1 John 5:7, King James Version)"),
            .bullet("**The canon itself.** Protestant Bibles hold 66 books, Catholic Bibles 73, and the Ethiopian Orthodox canon 81."),
            .versus(ArticleVersus.Side("The Bible", caption: "A library of books in Hebrew, Aramaic and Greek, **carried by manuscripts**, the originals lost, and the **canon differs** between churches."), ArticleVersus.Side("The Quran", caption: "One book in the Arabic it came down in, **carried by memory and by copies checked against memory**, the same 114 surahs for every Muslim.")),
            .text("None of this is said to belittle Christians, whose own scholars have documented it openly and whose Bibles often mark these passages themselves. It is the difference the Quran names: a scripture entrusted to its guardians, and a scripture whose keeping Allah (Glorified and Exalted be He) took upon Himself."),
            .door(.article("ProvingScriptureView")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**If the other copies were burned, how do we know nothing was lost?**"),
            .text("Because the standard copies were checked against what the Companions (may Allah be pleased with them) knew by heart. 'Uthman (may Allah be pleased with him) did not compose a text: he had the collection already made under Abu Bakr (may Allah be pleased with him) copied, and sent the copies out to be read aloud before people who would have noticed a missing verse, let alone a missing surah. Nor is it unknown what the retired copies held. Later scholars recorded the readings of the copies of Ibn Mas'ud and Ubayy ibn Ka'b (may Allah be pleased with them) in detail, and the Sana'a palimpsest is a surviving example. Almost all of their differences are of wording within verses, and most do not change the meaning."),
            .markdown("**Does the Sana'a palimpsest prove the Quran was changed?**"),
            .text("It confirms what the Muslim sources always said: that before the copies were unified, some Companions’ personal copies differed from one another in small ways. The surahs it preserves hold the same passages, its differences are of the kinds reported for those copies, and the scholars who edited it concluded that the surahs were already fixed in the lifetime of the Prophet (peace and blessings be upon him). The text written over it is the standard Quran."),
            .markdown("**Are the ten readings ten different Qurans?**"),
            .text("No. They are ways of reciting one text, all taught by the Prophet and all fitting the same written outline. A Muslim reciting in the reading of Hafs and one reciting in the reading of Warsh recite the same surahs, verses and teachings, with differences of pronunciation and wording that the scholars recorded down to the letter. The chapter on the qira'at explains them in full."),
            .markdown("**Isn’t the Quran’s preservation simply the result of Muslims being careful?**"),
            .text("Muslims were careful, and that care is part of how the promise was kept, not a rival explanation of it. What needs explaining is the order of events: the promise came first, from a persecuted minority with no state, no institutions and no assurance that its book would outlast its enemies, and only afterwards did every one of these means of keeping it arise and hold for fourteen centuries."),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("The Quran is preserved the way the alphabet is: not in one manuscript that could be lost, but in the memories, prayers, teachers and copies of a whole civilisation, each checking the others. Allah (Glorified and Exalted be He) promised to guard it when its followers were few and hunted, while the earlier scriptures were left in human keeping, and the oldest Quran manuscripts, including the one erased and written over in Sana'a, show surahs that had taken their shape in the lifetime of the Prophet (peace and blessings be upon him) and a standard text that is the one recited today."),
        ]),
        ArticleSection("KEY TERMS", [
            .term("Hafiz", arabic: "حَافِظ", meaning: "From the root **ح-ف-ظ**, to guard and to keep: one who has memorised the whole Quran, plural **huffaz**. The same root gives **hafizun**, guardians, the word Allah (Glorified and Exalted be He) uses of Himself in 15:9."),
            .term("Mushaf", arabic: "مُصحَف", meaning: "A written copy of the Quran bound between two covers, from **suhuf**, sheets. The standard copies sent out in the caliphate of 'Uthman (may Allah be pleased with him) are called the 'Uthmanic mushafs."),
            .term("Rasm", arabic: "رَسم", meaning: "The written outline of the Quran’s words as spelled in the 'Uthmanic copies, before dots and vowel signs were added. Every canonical reading fits it."),
            .term("Ijazah", arabic: "إِجَازَة", meaning: "A teacher’s certification that a student has recited the whole Quran to him correctly, with the chain of teachers back to the Prophet (peace and blessings be upon him)."),
            .term("Shadhdh", arabic: "شَاذّ", meaning: "“Irregular”: a reported reading that does not meet the conditions of the canonical readings, usually because it departs from the 'Uthmanic outline or lacks mass transmission. It may help explain a verse, but it is not recited as Quran."),
            .term("Palimpsest", arabic: "طِرس", meaning: "A parchment whose first writing was washed or scraped away so it could be written on again. The Arabic lexicographers define **tirs** as a sheet that was erased and then written on. The Sana'a palimpsest’s erased layer is its famous lower text."),
        ]),
    ]
}

struct ProvingIjazView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "ProvingIjazView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Unmatched Quran")
        .selectableArticleList(article: "ProvingIjazView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: the Quran challenged the most eloquent people of its time to produce even one surah like it, told them in advance that they never would, and they never did, though they opposed it for some twenty years with boycott, exile and war. Its enemies’ own verdicts, the prostration at the end of Surah an-Najm, and the people who wept on hearing it are the witnesses of this chapter, and the challenge is still open."),
        ]),
        ArticleSection("A MIRACLE THAT STAYED OPEN", [
            .text("The signs given to earlier prophets were events: they had to be seen, and they ended with the generation that saw them. The Prophet (peace and blessings be upon him) pointed to a different kind of sign:"),
            .hadith("bukhari:4981", cite: "Sahih al-Bukhari 4981", arabic: 24...42, english: [0...28]),
            .text("Proving Islam notes why this argument differs from most others in the case. It does not ask the reader to research a prophecy or check a scientific detail. It rests on something that happened in public, before hostile witnesses who were the acknowledged masters of the very art in question, and on a challenge that anyone can still take up."),
            .text("When the Quraysh said that he had made the Quran up, Allah (Glorified and Exalted be He) answered them with that challenge, and as the scholars of the Quran describe it, the challenge narrowed each time it was repeated:"),
            .checklist([
                "**A discourse like it**, if they were truthful (52:33–34)",
                "**Ten surahs like it**, calling on anyone they could besides Allah for help (11:13)",
                "**One surah like it** (10:38)",
                "**One surah, again, in Madinah**, with the prediction that they would never do it (2:23–24)",
                "**The verdict:** all mankind and the jinn together could not produce its like (17:88)",
            ], title: "The Stages of the Challenge", icon: "book.closed.fill"),
            .text("This is the order as-Suyuti gives in al-Itqan fi Ulum al-Quran: a discourse like it, then ten surahs, then one, repeated in al-Baqarah, and when they failed, the declaration that mankind and jinn together could not do it. Scholars differ over exactly when each verse came down, but the smallest thing asked for is plain. It is one surah, and the shortest surah in the Quran, al-Kawthar, is three short verses."),
            .ayah("17:88"),
            .ayah("2:23-24", words: 20...24),
            .quote(text: "“He challenged them with this in Makkah and in Madinah many times, with all their enmity toward him and their hatred of his religion, and even so they were unable to do it.” (Ibn Kathir, Tafsir al-Quran al-Azim, on 2:23)", arabic: "وقد تحداهم بهذا في مكة والمدينة مرات عديدة، مع شدة عداوتهم له وبغضهم لدينه، ومع هذا عجزوا عن ذلك"),
            .door(.prophecy("challenge-never-met")),
            .door(.prophetMiracle("quran")),
        ]),
        ArticleSection("THE PEOPLE IT WAS SPOKEN TO", [
            .text("The challenge was not put to people indifferent to language. For the Arabs before Islam, poetry was art, archive and weapon at once: it recorded a tribe’s history, carried its boasts and its insults, and made or unmade reputations. Seasonal fairs such as 'Ukaz, Majannah and Dhul-Majaz drew the tribes together (Sahih al-Bukhari 2050), and 'Ukaz in particular was remembered for the poets who recited there. The long odes later gathered as the Mu'allaqat were counted the summit of the art."),
            .text("The Prophet (peace and blessings be upon him) knew the power of eloquence himself:"),
            .hadith("bukhari:5146", cite: "Sahih al-Bukhari 5146", arabic: 13...29, english: [0...21]),
            .text("And he praised a true line of poetry when he heard one:"),
            .hadith("bukhari:3841", cite: "Sahih al-Bukhari 3841", arabic: 28...40, english: [0...24]),
            .text("So the Quran’s first judges were connoisseurs, and most of them were its enemies. If it had been ordinary eloquence, they were the people best placed to say so."),
        ]),
        ArticleSection("NOT POETRY AND NOT SOOTHSAYING", [
            .text("The Arabs had a name for every kind of speech: poetry (shi'r), with its fixed metres and single rhyme; the rhymed prose of the soothsayers (saj' al-kuhhan), in short and cryptic oracles; and the oratory of the sermon and the council (khatabah). When they heard the Quran they reached for the nearest labels, poet and soothsayer among them, and the Quran rejected each:"),
            .ayah("69:40-43"),
            .ayah("36:69"),
            .text("Their labels kept changing, which is itself a sign that none of them fitted. The Quran records them calling it confused dreams, an invention and poetry, all in one breath:"),
            .ayah("21:5", words: 0...8),
            .text("As-Suyuti observed the same pattern: sometimes they said magic, sometimes poetry, sometimes tales of the ancients, all of it from bewilderment. Al-Baqillani devoted whole chapters of his I'jaz al-Quran to showing that it is neither poetry nor saj'. It has rhythm and it often rhymes, but it keeps to no metre, and it moves from short, urgent verses to long legal ones without leaving its own voice."),
        ]),
        ArticleSection("AN ENEMY'S VERDICT", [
            .text("The most telling judgement came from one of the Quran’s bitterest opponents. Al-Walid ibn al-Mughirah, an elder of Quraysh known for his wealth and his knowledge of poetry, went to the Prophet (peace and blessings be upon him), heard him recite, and seemed moved. Abu Jahl came to him and pressed him to say something against it that would reach his people. He answered:"),
            .quote(text: "“By Allah, there is no man among you who knows poetry better than I do, nor its rajaz, nor its odes, nor even the poetry of the jinn. By Allah, what he says resembles none of it. By Allah, what he says has a sweetness, and there is a grace upon it; its top bears fruit and its root is richly watered; it rises high and nothing rises above it, and it crushes what is beneath it.” (al-Walid ibn al-Mughirah, reported by al-Hakim in al-Mustadrak, who graded its chain sahih by the standard of al-Bukhari, with adh-Dhahabi agreeing)", arabic: "فوالله ما فيكم رجل أعلم بالأشعار مني، ولا أعلم برجز ولا بقصيدة مني ولا بأشعار الجن، والله ما يشبه الذي يقول شيئا من هذا، ووالله إن لقوله الذي يقول حلاوة، وإن عليه لطلاوة، وإنه لمثمر أعلاه مغدق أسفله، وإنه ليعلو وما يعلى وإنه ليحطم ما تحته"),
            .text("Abu Jahl told him his people would not be satisfied until he condemned it. He asked for time to think, and then he said: this is magic, handed down from others. The Quran describes that very scene, the thinking, the frown, and the verdict he forced out:"),
            .ayah("74:18-25"),
            .text("The man who knew Arabic poetry better than anyone in Makkah could find no literary fault in the Quran. The worst he could say was that it was magic: a warning to keep people away from it, not a critique of it. Some later researchers have questioned one narrator in the chain of this report, but al-Hakim and adh-Dhahabi accepted it, and the commentators identify the man in these verses as al-Walid."),
        ]),
        ArticleSection("ENEMIES WHO LISTENED", [
            .text("Jubayr ibn Mut'im (may Allah be pleased with him), a nobleman of Quraysh, came to Madinah about the captives taken at Badr while he was still an idolater (Sahih al-Bukhari 3050). He heard the Prophet (peace and blessings be upon him) leading the sunset prayer:"),
            .hadith("bukhari:4854", cite: "Sahih al-Bukhari 4854", arabic: 22...63, english: [0...78]),
            .hadith("bukhari:4023", cite: "Sahih al-Bukhari 4023", arabic: 18...34, english: [0...23]),
            .text("It was Jubayr, the son, who heard this. His father, al-Mut'im ibn 'Adi, had already died, as the full text of the second narration shows."),
            .text("Even in the years of persecution in Makkah, the leaders of Quraysh feared the Quran’s effect on their own households. When Abu Bakr (may Allah be pleased with him) began praying and reciting in a small mosque in his courtyard, ‘Aisha (may Allah be pleased with her) relates:"),
            .hadith("bukhari:3905", cite: "Sahih al-Bukhari 3905", arabic: 215...291, english: [350...421, 488...500]),
            .text("And once, at the end of Surah an-Najm, a whole gathering fell into prostration with the Prophet, believers and idolaters alike:"),
            .hadith("bukhari:4862", cite: "Sahih al-Bukhari 4862", arabic: 19...31, english: [0...25]),
            .ayah("53:62"),
            .text("Ibn Mas'ud (may Allah be pleased with him), who was there, adds that only one man did not prostrate, lifting a handful of dust to his forehead instead: Umayyah ibn Khalaf, who was later killed as a disbeliever (Sahih al-Bukhari 1067, 4863). Idolaters who mocked the Quran bowed alongside those who believed in it."),
        ]),
        ArticleSection("THE JINN AND THOSE WHO WEPT", [
            .text("The Quran records that its hearers were not only human. A company of jinn listened to the Prophet (peace and blessings be upon him) reciting, and this is what they said:"),
            .ayah("72:1-2"),
            .text("Among people, the commonest response was tears. The Quran describes those who recognised it:"),
            .ayah("5:83"),
            .text("Ibn Kathir relates that the early commentators connected this verse with Christians of Abyssinia: some said the Negus and his companions, others a delegation he sent, who wept and believed when the Prophet recited to them. At-Tabari held that it describes everyone of that kind, wherever they came from."),
            .text("The Prophet himself wept at it. He once asked Ibn Mas'ud (may Allah be pleased with him) to recite to him:"),
            .hadith("bukhari:5050", cite: "Sahih al-Bukhari 5050", arabic: 18...70, english: [0...89]),
            .text("And his Companions (may Allah be pleased with them) held on to it even in pain. On a night watch during a campaign, a man of the Ansar kept praying while an enemy shot arrows into him:"),
            .hadith("abudawud:198", cite: "Sunan Abi Dawud 198; graded hasan by al-Albani", arabic: 90...155, english: [102...173, 203...255]),
        ]),
        ArticleSection("THE ONE WHO TRIED", [
            .text("There was one notable attempt in the lifetime of the Prophet (peace and blessings be upon him). Musaylimah of al-Yamamah claimed prophethood and demanded to be named the Prophet’s successor; the Prophet refused him even a palm stalk and told him he took him to be one of the two liars he had been shown in a dream (Sahih al-Bukhari 3620). Musaylimah recited rhymed lines as revelation, and historians such as at-Tabari preserved some of them, in reports of uneven strength. They are remembered today mainly as a byword for failed imitation, and they did not outlive him: after he was killed at al-Yamamah, no one recited them as scripture."),
            .text("The poets of the Quran’s own people took the opposite course. Labid ibn Rabi'ah (may Allah be pleased with him), whose ode is counted among the Mu'allaqat, came to the Prophet with his tribe’s delegation and accepted Islam. Ibn 'Abd al-Barr records in al-Isti'ab that most of the historians said Labid composed no poetry after that, though some allow him a single line, and that when 'Umar (may Allah be pleased with him) asked him to recite some of his verse, he answered:"),
            .quote(text: "“I would not say poetry after Allah has taught me al-Baqarah and Al 'Imran.” (Labid ibn Rabi'ah to 'Umar, a historical report recorded by Ibn 'Abd al-Barr in al-Isti'ab)", arabic: "ما كنت لأقول شعرا بعد أن علمني الله البقرة وآل عمران"),
        ]),
        ArticleSection("WHY THE SILENCE IS EVIDENCE", [
            .callout("A challenge that goes unanswered proves little when no one cares to answer it. This one was put to the people **most able and most eager** to answer it: masters of the language, fighting its messenger for twenty years at the cost of their wealth and their lives. One convincing surah would have ended the argument. They chose boycott, exile and war instead, and their culture, which preserved a great deal of its poetry, preserved **no rival text** that anyone accepted.", title: "Why the Silence Is Evidence", icon: "lightbulb.fill"),
            .text("As-Suyuti put the argument in its classical form:"),
            .quote(text: "“They were more eager than anyone to put out its light and bury its cause. Had opposing it been within their power, they would have turned to that to cut the argument short; yet it is not reported of a single one of them that he so much as considered it or attempted it.” (as-Suyuti, al-Itqan fi Ulum al-Quran, on the inimitability of the Quran)", arabic: "وقد كانوا أحرص شيء على إطفاء نوره وإخفاء أمره، فلو كان في مقدرتهم معارضته لعدلوا إليها قطعا للحجة، ولم ينقل عن أحد منهم أنه حدث نفسه بشيء من ذلك ولا رامه"),
            .text("Proving Islam adds the point about memory. Arabic literary culture kept the poetry of the pre-Islamic age, the rival odes of later poets, and the stories of their contests. Had anyone produced a surah that his hearers judged equal to the Quran, it would have been remembered, if only by the Quran’s enemies. What survives instead is Musaylimah’s example and the silence of everyone else."),
            .text("The challenge did not expire with Quraysh. It has stood for fourteen centuries, open to anyone, anywhere, who believes the Quran is a human work, and every generation of doubters has had the same simple way to settle the matter."),
            .door(.article("QuranPillarView")),
            .door(.article("ProvingStylometryView")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**Isn’t “no one can match it” just a matter of taste?**"),
            .text("Taste varies, which is exactly why the first judges matter. They were native masters of the language, hostile to the Quran, and they had every reason to find it ordinary; the best of them could not, as al-Walid’s verdict shows. The claim is not that everyone must feel moved by the Quran, but that no one produced a text its hearers, friend or foe, were willing to set beside it, though producing one was the obvious way to defeat it."),
            .markdown("**What would count as meeting the challenge?**"),
            .text("A surah like it: comparable in the composition of its words, their eloquence and their meaning, not merely a passage that copies its rhymes. The classical scholars made this point directly. As-Suyuti quotes al-Rummani that changing the rhyming words at the ends of a short surah is no more an answer to it than changing the rhyme words of a famous poem makes someone a poet. The judges are those who know Arabic best, and no attempt has won them over."),
            .markdown("**Didn’t the idolaters prostrate at an-Najm because of the story of the “satanic verses”?**"),
            .text("That story, in which the Prophet (peace and blessings be upon him) is said to have praised the idols in his recitation, is not in the sound reports of the prostration, which give no cause for it beyond the recitation itself. Ibn Kathir, after listing its reports, wrote that all of its routes are mursal, broken before reaching a Companion, and that he had not seen it with a sound connected chain, and al-Albani devoted a treatise to refuting it. Ibn Hajar thought its many broken routes pointed to some origin, while affirming that the Prophet was protected from error; many other scholars rejected it outright."),
            .markdown("**Has anyone met the challenge since?**"),
            .text("Attempts have been made in every age, from Musaylimah to modern imitations. None has won acceptance among those who know Arabic best, and none has come to be recited, memorised and lived by as the Quran is. The challenge remains what it was: an open invitation, and a prediction that it will not be met."),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("The Quran made its own inimitability a public test: produce one surah like it. The people it addressed were the finest judges of Arabic there have been, and its fiercest enemies; they called it magic, poetry and dreams, fought it for twenty years, and never answered it. Al-Walid ibn al-Mughirah could find no fault in it, idolaters prostrated with the believers at the end of an-Najm, a poet of the Mu'allaqat gave up his poetry for al-Baqarah, and the challenge, with its prediction that it would never be met, still stands."),
        ]),
        ArticleSection("KEY TERMS", [
            .term("I'jaz", arabic: "إِعجَاز", meaning: "From the root **ع-ج-ز**, to be unable: the quality of the Quran that leaves others unable to produce its like. A miracle is called a **mu'jizah** for the same reason."),
            .term("Tahaddi", arabic: "تَحَدِّي", meaning: "The challenge: the Quran’s call to those who denied it to produce a discourse, ten surahs, or a single surah like it."),
            .term("Shi'r", arabic: "شِعر", meaning: "Poetry, bound by metre and a single rhyme. The Quran denies that it is poetry and that its messenger was taught poetry (69:41, 36:69)."),
            .term("Saj'", arabic: "سَجع", meaning: "Rhymed prose, especially the short, obscure oracles of the pre-Islamic soothsayers. Many scholars, al-Baqillani among them, refused to call the Quran’s rhymes saj' and named them **fawasil** instead."),
            .term("Kahin", arabic: "كَاهِن", meaning: "A soothsayer who claimed knowledge of the unseen through the jinn and spoke in saj'. The Quran rejects the label (69:42)."),
            .term("Mu'allaqat", arabic: "المُعَلَّقَات", meaning: "“The suspended ones”: the celebrated long odes of pre-Islamic poets, Labid ibn Rabi'ah (may Allah be pleased with him) among them. A later story said they were hung on the Ka'bah; the grammarian an-Nahhas denied it, and many scholars since have doubted it."),
        ]),
    ]
}

struct ProvingScienceView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "ProvingScienceView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Errors It Did Not Make")
        .selectableArticleList(article: "ProvingScienceView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: the Quran is not a science textbook, and this chapter does not read it as one. The argument is narrower. A book composed in seventh-century Arabia should carry the mistaken science of its age, and across the heavens, living things, the weather and the womb, the Quran does not. In a few places its words also sit well with what was found much later; there the chapter sets the classical meanings beside the modern reading, so that the reader can see what is text and what is interpretation."),
        ]),
        ArticleSection("WHAT A HUMAN AUTHOR WOULD HAVE WRITTEN", [
            .text("Every book carries the knowledge of its time, mistakes included. The learned world of the seventh century took its science from the Greeks: Ptolemy's heavens, spheres turning forever around a motionless earth; Aristotle's natural history, in which bees were ruled by kings and honey fell from the air; Galen's medicine. A man in Makkah who wished to sound learned would have borrowed from these, and one who did not would have repeated the folk beliefs of his people. Either way his book would bear the marks of its century."),
            .text("The Quran speaks often of the sky, the rain, animals and the growth of a child in the womb, and it invites the test that follows:"),
            .ayah("4:82"),
            .text("It also shows what it is for. When the Companions (may Allah be pleased with them) asked the Prophet (peace and blessings be upon him) about the new moons, the answer given was their use, not their mechanism:"),
            .ayah("2:189", words: 1...8),
            .text("Proving Islam frames the argument in two tiers, and this chapter keeps its caution. The first claim, and the stronger, is that the Quran avoids the errors of its age across many unrelated subjects. The second is that some of its wording fits discoveries made long after. The second is always a reading, and the early commentators did not usually read these verses that way. They were careful men. Explaining the falak in which the sun and moon move, al-Tabari listed what earlier scholars had said and then declined to choose: in Arabic a falak is anything that turns, no text settled which kind was meant, and so one says what Allah (Glorified and Exalted be He) said and keeps silent about what is not known."),
            .callout("**It claims** that across the heavens, living things, the weather and the womb, the Quran's statements do not commit it to the mistaken science of the seventh century, and that some of its words fit later discoveries strikingly well. **It does not claim** that the Quran teaches modern science, that the early commentators understood these verses as a modern scientist would, or that any single verse proves the case by itself. Where a reading is modern, this chapter says so, and where the evidence is thin, it says that too.", title: "What This Argument Does and Does Not Claim", icon: "scalemass.fill"),
        ]),
        ArticleSection("THE HEAVENS AND THEIR COURSES", [
            .text("Greek astronomy, which ruled learned opinion for fourteen centuries, taught that the heavens were eternal and unchanging. Of the heaven, Allah (Glorified and Exalted be He) says:"),
            .ayah("51:47", words: 3...4),
            .markdown("The word is **musi'un (مُوسِعُون)**, from the root **و-س-ع**, width and capacity, and the classical commentators read it more than one way. Al-Tabari took it as “We are possessors of vastness and power,” comparing “the one of means” (al-musi') in Quran 2:236; Ibn Zayd, whom he quotes, said “He made it vast”; Ibn Kathir wrote that Allah made the heaven vast and raised it without pillars. None of them read it as an expansion still under way, and it can be translated, as Proving Islam itself concedes, simply as “We are the vast in power.”"),
            .text("Still, until the 1920s astronomers assumed that the universe as a whole was static. In 1927 Georges Lemaître, and in 1929 Edwin Hubble, showed that the galaxies are moving apart: the universe is expanding. The Quran's word is an active participle, which Arabic uses for what is ongoing as well as for a standing quality, so the modern reading is open to it. Whether the verse points to expansion or only to vastness, it does not say what a writer of its time would have said, that the heavens were fixed forever."),
            .text("Of the sun and the moon it says:"),
            .ayah("21:33"),
            .ayah("36:38-40", words: 26...29),
            .text("Ibn 'Abbas (may Allah be pleased with him) explained that they revolve like a spinning wheel, in a circle, and al-Hasan al-Basri compared the falak to the whorl of a spindle. Honesty needs a caution that apologists often skip: Ptolemy also gave the sun and the moon each its own sphere, so these verses were never at odds with the old astronomy either. What they avoid is any commitment to a fixed earth at the centre of everything, and their picture of each body swimming in its own course suits what is now known. The moon circles the earth, the earth circles the sun, and the sun itself travels around the centre of the galaxy, one circuit taking over two hundred million years."),
            .door(.miracle("expanding_universe", title: "Expanding Universe")),
            .door(.miracle("planetary_orbits", title: "Planetary Orbits")),
        ]),
        ArticleSection("EVERY LIVING THING FROM WATER", [
            .ayah("21:30", words: 10...15),
            .ayah("24:45", words: 0...5),
            .text("This one was not unknown before Islam. Thales of Miletus, the first of the Greek philosophers, taught that water is the origin of all things, and in Genesis the waters bring forth living creatures. So the point is not that the verse told the Arabs something new; it is that, among the answers on offer, it chose one that has held. The early commentators read it two ways. Qatadah said every living thing was created from water; al-Tabari explained it as Allah (Glorified and Exalted be He) giving life to everything by the water He sends down. Biology has found both: living cells are mostly water, all known life chemistry takes place in water, and nothing known to live can do without it."),
        ]),
        ArticleSection("THE BEE AND ITS HONEY", [
            .ayah("16:68-69", words: 22...27),
            .markdown("The early commentators explained the bee's inspiration, **awha (أَوحَى)**, as guidance that Allah (Glorified and Exalted be He) placed in it: Mujahid called it ilham, an inspired instinct, and Ibn Kathir called it guidance. The verbs addressed to the bee are feminine (**ittakhidhi**, take; **kuli**, eat; **fasluki**, follow), and the drink comes **min butuniha**, “from their bellies.”"),
            .text("Two things here stand against the science of the day. The first is where honey comes from. Aristotle's History of Animals, the most authoritative work on animals the ancient world produced, says that the bee does not make honey at all:"),
            .versus(ArticleVersus.Side("Aristotle, History of Animals", caption: "Honey “is distilled from dew”; the bee “merely gathers what is deposited out of the atmosphere.”"), ArticleVersus.Side("Quran 16:69", arabic: "يَخۡرُجُ مِنۢ بُطُونِهَا شَرَابٞ", caption: "“There emerges from their bellies a drink.”"), quranic: true),
            .text("The verse puts the source inside the bees' own bodies, and that is what was found. A forager carries nectar in its honey stomach, a crop in its abdomen, where enzymes begin to turn it into honey, and brings it up into the comb to ripen."),
            .text("The second is who does the work. Aristotle wrote of the hive's leaders as kings, and European writers still spoke of a king bee in the seventeenth century, until naturalists showed that the “king” is a female who lays the colony's eggs. The bees that forage and make honey are all female; the males, the drones, do none of it. Honesty needs a caveat here too. The feminine verbs are ordinary Arabic: an-nahl, the bee, is a collective noun that may be treated as masculine or feminine, and ar-Razi noted that the people of the Hijaz make it feminine, which is why the Quran does. The grammar proves nothing by itself. What can be said is that the Quran's Arabic spoke of the bee in the gender that turned out to be right, while the Greek science of its age spoke of kings."),
            .door(.miracle("honey_bees", title: "Honey Bees")),
        ]),
        ArticleSection("IRON SENT DOWN", [
            .ayah("57:25", words: 11...17),
            .text("Aristotle's Meteorology taught that metals, iron among them, are born inside the earth, from a vapour imprisoned in its stones, and a seventh-century writer would naturally have said that Allah (Glorified and Exalted be He) created iron in the earth. The verse says “sent down,” anzalna. Proving Islam keeps an honest hedge here, and so does this chapter: the same verb is used of livestock (Quran 39:6) and of clothing (Quran 7:26), where Saheeh International renders it “produced” and “bestowed.” It can mean that Allah provided iron as a gift from above rather than that iron fell from the sky, and the early commentators mostly explained the verse by what iron does: weapons for war, and tools for everything else."),
            .text("The modern reading adds this. Iron is not made in the earth. It is forged in the cores of massive stars and in their explosions, a star the size of our sun never makes it, and the earth's iron was made before the solar system existed. That is true of nearly every element heavier than helium, so the verse does not single out a property unique to iron. What it does is choose, for the metal of war, a word the Quran uses for gifts that come from above, and nothing in that word conflicts with what is known."),
            .door(.miracle("iron", title: "Iron")),
        ]),
        ArticleSection("RAIN CLOUDS AND HAIL", [
            .ayah("24:43"),
            .text("The verse describes a sequence: clouds driven along, brought together, piled into a mass, rain coming out from within it, and hail sent down from “mountains” in the sky. The classical commentators held two views of those mountains, that there are mountains of hail in the sky or that the clouds themselves are called mountains, and Ibn Kathir gave both without deciding between them."),
            .text("Meteorology now describes the thunderstorm cloud, the cumulonimbus, in much the same steps. Smaller clouds are carried together and merge, and the mass builds upward into a tower that can rise more than ten kilometres. Rain falls from within it, and hail forms in its cold upper reaches, where strong updrafts hold the stones aloft until they are heavy enough to fall. Aristotle, the ancient authority on weather, argued the opposite: that hailstones freeze close to the earth, and not because a cloud is thrust up into the cold upper air. The Quran also calls rain clouds heavy (Quran 13:12), and a single cumulus cloud is now estimated to hold hundreds of tonnes of water. Much of this a careful observer can see, so it is offered as description without error, not as a secret disclosed."),
            .door(.miracle("clouds_weight", title: "Weight Of Clouds")),
        ]),
        ArticleSection("THE CHILD IN THE WOMB", [
            .ayah("23:12-14", words: 9...25),
            .markdown("The stages are named with concrete words: **nutfah (نُطفَة)**, a small quantity of fluid; **'alaqah (عَلَقَة)**, from a root meaning to cling or hang, which also gives the words for a leech and for clotted blood; **mudghah (مُضغَة)**, a morsel that has been chewed; then bones, then flesh clothing the bones."),
            .text("On this subject claims most often run ahead of the evidence, so it needs the most care. The classical commentators understood 'alaqah as a clot of blood; Ibn Kathir describes a red, elongated clot. The reading “that which clings” is within the word's meaning, and fits an embryo that has buried itself in the wall of the womb in its first weeks, but it is a modern emphasis. Nor was the idea of stages new: Galen, the great physician of the second century, described the embryo passing through four, from seed to an unformed growth to the shaping of its main organs to a complete body."),
            .text("So the argument here is modest. The Quran's sequence follows the order in which the embryo's visible form develops. At about four weeks it is a curved body marked by a row of bead-like segments, the somites, which modern writers have compared to the marks of teeth in a chewed morsel. Bone and muscle then form from the same tissue at nearly the same time, the skeleton laid down in cartilage and the muscles gathering around it in the second month; whether the verse's “then” marks a strict sequence or the order in which the body takes its shape is a matter of reading. What the verse plainly avoids is the leading theory of the ancient world. Aristotle taught that the embryo is made from the mother's menstrual blood, set by the father's seed as rennet sets milk. The Quran says nothing of the kind."),
            .door(.miracle("human_embryo", title: "Human Embryo")),
        ]),
        ArticleSection("PHARAOH'S BODY AND THE WEEPING SKY", [
            .text("Two verses about the Pharaoh of Moses belong here, though they concern history more than nature. The first was said to Pharaoh as he drowned:"),
            .ayah("10:92", words: 0...6),
            .text("The early commentators, reporting from Ibn 'Abbas and others, explained that some of the Children of Israel doubted Pharaoh was dead, so the sea cast his body up onto a rise of land where they could see it: a sign for those who came after him. Some modern writers go further and identify the verse with a royal mummy. That is not established. The mummies most often proposed, those of Ramesses II and his son Merneptah, were found in 1881 and 1898, but historians disagree over which Pharaoh was the Pharaoh of the Exodus, and no mummy has been shown to be his. The verse stands on the classical reading without needing either identification."),
            .text("The second closes the account of Pharaoh's people:"),
            .ayah("44:29", words: 0...4),
            .text("The Arabs had a saying for the death of a great man, that the heaven and the earth wept for him, as az-Zamakhshari notes in his commentary, and the early commentators explained the verse by its opposite: the place where a believer prayed, and the gate through which his deeds rose, weep for him when he dies. There is a further fit that no one in the seventh century could have seen. The royal funerary texts of Egypt, carved inside the pyramids of Saqqara nearly three thousand years before Islam, made this very claim for their kings:"),
            .quote(text: "“The sky weeps for thee, the earth trembles for thee.” (Pyramid Texts §1365, as translated by James Henry Breasted, Development of Religion and Thought in Ancient Egypt, 1912)", dimmed: true),
            .text("The ability to read hieroglyphs was lost in late antiquity and recovered only with Champollion's decipherment in 1822, and these texts were first recorded in 1880–81. The Quran denies, of the one Pharaoh it describes, what Egypt's priests had claimed for their kings. Since the idiom was also Arab, it is a fit rather than a proof, but a precise one."),
            .text("The Prophet (peace and blessings be upon him) held to the same truth in his own grief. On the day his infant son Ibrahim died, the sun was eclipsed:"),
            .hadith("bukhari:1060", cite: "Sahih al-Bukhari 1060", arabic: 17...55, english: [0...68]),
            .text("A man building a legend around himself had every reason to let that omen stand. He corrected it the same day."),
            .door(.miracle("mummy", title: "Pharaoh's Mummy")),
            .door(.miracle("mourning_pharaoh", title: "Mourning of Pharaoh")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**Isn't this reading science into the text after the fact?**"),
            .text("Sometimes it is, and that is the danger this chapter tries to avoid. A verse can be stretched to fit almost any discovery once the discovery is known. Two safeguards help. The first is to put the weight on what the Quran does not say, which cannot be read in after the fact. The second is to give the classical meanings beside the modern one, as each section above does, so the reader can judge how far a reading goes beyond the words. The Andalusian jurist al-Shatibi (d. 790 AH) warned long ago against those who claimed every science of the ancients and the moderns for the Quran, and pointed out that the Companions, who knew it best, made no such claims."),
            .markdown("**Didn't earlier peoples already know some of this?**"),
            .text("Some of it, yes: Thales on water, Galen on the stages of the embryo. So the argument is not that every statement was new, but that the Quran kept taking the account that holds, in an age whose learned books mixed truth and error on those very subjects. A writer drawing on those books would have taken their errors along with their truths."),
            .markdown("**What about verses critics call errors, such as the sun setting in a muddy spring?**"),
            .ayah("18:86", words: 0...9),
            .text("The verse describes what Dhul-Qarnayn found, wajadaha: what he saw. Ibn Kathir explained that he saw the sun as if it were setting in the ocean, as anyone on a coast sees it, while the sun never leaves its course; Saheeh International's “[as if]” carries the same sense. Leading classical scholars also held the earth to be round: Ibn Hazm wrote that no imam deserving the name had denied it, and Ibn Taymiyyah reported the scholars' agreement that the earth, land and sea together, is like a ball. Objections like this are best answered one by one, from the Arabic and the early commentary."),
            .door(.article("ProvingFingerprintView")),
            .markdown("**If science changes, does the argument fall?**"),
            .text("Not its stronger half, because that half rests on the past, which does not change: Ptolemy's eternal spheres and honey from the dew are not coming back. The modern readings are another matter. They are human interpretations, to be held as loosely as the science they lean on, and a Muslim's faith rests on the Quran itself, not on any reading of it that a later discovery might overturn."),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("A seventh-century book that speaks as often as the Quran does of the sky, the rain, animals and the womb should carry the science of its age, errors and all. The Quran does not. Where its words also fit later discoveries, the fit is offered as a reading and held with care; the stronger half of the argument needs no reading at all. It is the list of mistakes that are not there."),
            .checklist([
                "Heavens fixed forever around a motionless earth (Aristotle, Ptolemy)",
                "Honey falling from the air as dew (Aristotle)",
                "Bees ruled by a king (Aristotle, and Europe until the seventeenth century)",
                "Hail frozen close to the ground (Aristotle)",
                "Metals born from a vapour trapped inside the earth (Aristotle)",
                "The child set from menstrual blood, as rennet sets milk (Aristotle)",
                "The sun eclipsed for a great man's death (the belief the Prophet ﷺ corrected, Sahih al-Bukhari 1060)",
            ], title: "Errors of the Age It Does Not Repeat", icon: "xmark.circle.fill"),
            .door(.library(.miraclesOfQuran)),
            .door(.article("ProvingProphecyView")),
        ]),
        ArticleSection("KEY TERMS", [
            .term("Ayah", arabic: "آيَة", meaning: "A sign. The Quran uses the same word for its own verses and for the things of nature, the rain, the bee, the turning of night and day, as signs that point to their Maker (Quran 16:69, quoted above)."),
            .term("Falak", arabic: "فَلَك", meaning: "From the root **ف-ل-ك**, roundness and turning: anything that revolves. The whorl of a spindle is a falkah, and the Quran uses falak for the courses of the sun and the moon."),
            .term("'Alaqah", arabic: "عَلَقَة", meaning: "From **ع-ل-ق**, to cling or hang: the second stage of the embryo in Quran 23:14. The classical commentators read it as a clot of blood; the root also gives 'alaq, leeches, and modern readers stress the sense of clinging."),
            .term("At-Tafsir al-'Ilmi", arabic: "التَّفسِير العِلمِيّ", meaning: "Scientific exegesis: reading verses in the light of modern science. Scholars have debated its limits since al-Shatibi warned against loading the Quran with sciences its first hearers did not know; this chapter uses it only with the classical meanings beside it."),
        ]),
    ]
}

struct ProvingProphecyView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "ProvingProphecyView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Foretold, and Fulfilled")
        .selectableArticleList(article: "ProvingProphecyView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: a man inventing a religion keeps his forecasts vague, so that no failure can be pinned on him. The Prophet (peace and blessings be upon him) did the opposite. He named people, empires and places, gave spans of years, and said it in public, often when his community was at its weakest, and the predictions that can be checked came true. This chapter sets the ones that can carry an argument apart from the ones that only add weight."),
        ]),
        ArticleSection("WHY A PREDICTION IS A TEST", [
            .text("Anyone can foretell wars, earthquakes and hard times. Such forecasts cost nothing, because nothing can show them false. A prediction becomes evidence only when it could have failed, and a man who is inventing his message, and knows it, has every reason to avoid that kind. One clear failure, in front of enemies who were waiting for it, would have finished him. Proving Islam puts the principle in a line: a rational fraud minimises falsifiable claims."),
            .text("The Bible states the same test, in the chapter of Deuteronomy where Moses promises a prophet like himself (18:18):"),
            .quote(text: "“And if thou say in thine heart, How shall we know the word which the LORD hath not spoken? When a prophet speaketh in the name of the LORD, if the thing follow not, nor come to pass, that is the thing which the LORD hath not spoken, but the prophet hath spoken it presumptuously: thou shalt not be afraid of him.” (Deuteronomy 18:21–22, King James Version)", dimmed: true),
            .text("The Quran never presents the Prophet (peace and blessings be upon him) as a man who could see the future by himself. It has him say plainly that he does not know the unseen:"),
            .ayah("7:188", words: 11...20),
            .text("What he told of the future, the Quran says, was what Allah (Glorified and Exalted be He) chose to disclose to a messenger:"),
            .ayah("72:26-27"),
            .checklist([
                "**Specific:** it names a person, a people, a place or a number.",
                "**Public:** it was said before witnesses, many of them hostile, and passed on in writing.",
                "**Bounded:** it gives a span of years, or concerns people who would live or die within a lifetime.",
                "**Out of his hands:** nothing he could do would make it come true.",
                "**Recorded first:** the text that holds it is older than the event.",
            ], title: "What Makes a Prediction Count", icon: "checkmark.seal.fill"),
            .text("Proving Islam sorts the evidence into two tiers, and the distinction is worth keeping. Tier 1 is the predictions that meet these tests: named, dated or bounded, and checkable against the historical record, in several cases against records kept by people with no stake in Islam. Tier 2 is the signs of the Hour, descriptions of how the world would change, with no date and no place. The next five sections are Tier 1. The last is Tier 2, with the reason it weighs less."),
        ]),
        ArticleSection("THE ROMANS WILL WIN", [
            .text("In the second decade of the seventh century Persia was tearing apart the Byzantine empire, which the Arabs called Rum, Rome. Antioch and Damascus fell in 613, Jerusalem in 614, and Alexandria around 619. Persian armies reached the shore facing Constantinople, and the emperor Heraclius thought of moving his government to Carthage. In those years, in Makkah, these verses were revealed to the Prophet (peace and blessings be upon him):"),
            .ayah("30:2-5"),
            .markdown("The span given is **bid' sinin**, a small number of years: the Arabs used bid' for three to nine. The pagans of Makkah, who sided with Persia, took it as a public claim and bet against it. Ibn 'Abbas (may Allah be pleased with him) describes the wager Abu Bakr (may Allah be pleased with him) made over it:"),
            .hadith("tirmidhi:3193", cite: "Jami` at-Tirmidhi 3193; graded sahih by Ahmad Shakir and Darussalam", arabic: 69...144, english: [72...173, 188...193]),
            .text("Edward Gibbon, the historian of Rome's decline, did not accept the verse as prophecy; in a footnote he calls it a “conjecture, guess, wager.” Yet in his text he described the odds against it plainly:"),
            .quote(text: "“At the time when this prediction is said to have been delivered, no prophecy could be more distant from its accomplishment, since the first twelve years of Heraclius announced the approaching dissolution of the empire.” (Edward Gibbon, The History of the Decline and Fall of the Roman Empire, chapter 46)", dimmed: true),
            .text("Then the war turned. Heraclius took the field in 622, the year of the Hijrah. In 624, the year of Badr, he was inside Persia, destroying the great fire temple at Ganzak. The joint Persian and Avar siege of Constantinople failed in 626; late in 627 he broke the Persian army near Nineveh, and in February 628 Khosrow II was deposed and put to death by his own son, who made peace and gave back the Roman lands. The reports differ over which victory fulfilled the verses; Sufyan ath-Thawri, a narrator of the report above, heard that it came on the day of Badr. By the account of those who narrated the wager, the verses had been recited openly, a stake had been laid against them, and the Romans prevailed before the span ran out."),
            .door(.prophecy("byzantines")),
        ]),
        ArticleSection("ABU LAHAB", [
            .text("Abu Lahab was an uncle of the Prophet (peace and blessings be upon him) and one of his loudest enemies. Around 613, when the Prophet was commanded to warn his nearest kin, he climbed the hill of as-Safa in Makkah and called the clans of Quraysh together:"),
            .hadith("bukhari:4770", cite: "Sahih al-Bukhari 4770", arabic: 67...111, english: [49...135]),
            .text("The surah revealed in answer names him:"),
            .ayah("111:1-3"),
            .text("The surah says of a living man that he would end in the Fire, which is to say that he would die without believing. It was recited in Makkah for about ten years while he was alive to hear it. He died in 624, about a week after the news of Badr reached Makkah, still an idolater. To refute it he needed only to declare himself a Muslim in public, even without meaning it. Many of the Prophet's fiercest opponents did later accept Islam, Abu Sufyan and 'Ikrimah ibn Abi Jahl (may Allah be pleased with them) among them. The one man the Quran had named in advance never did."),
            .callout("A critic can say the Prophet knew his uncle's stubbornness well enough to risk it. Proving Islam answers that the objection concedes more than it saves: it credits him with certainty about another man's heart across a decade, when that man had every motive to prove him wrong and one sentence would have done it. A forger does not stake his whole mission on an enemy's choice.", title: "The Strongest Objection", icon: "scalemass.fill"),
            .door(.prophecy("abu-lahab")),
        ]),
        ArticleSection("TWO EMPIRES NAMED IN ADVANCE", [
            .text("Persia and Byzantium had divided the known world between them for centuries. The Prophet (peace and blessings be upon him) named both, more than once, as powers whose lands his followers would take, and he did so when those followers could barely defend their own town."),
            .text("In 5 AH (627 CE) an alliance of Quraysh and the tribes besieged Madinah, and the Muslims dug a trench across its open side. A rock blocked the digging, and he struck it three times. Salman al-Farisi (may Allah be pleased with him) asked about the flashes of light he had seen, and he answered:"),
            .hadith("nasai:3176", cite: "Sunan an-Nasa'i 3176; graded hasan by Darussalam", arabic: 193...254, english: [254...359]),
            .text("The Quran records what the hypocrites inside the besieged town were saying in those same weeks: that Allah (Glorified and Exalted be He) and His Messenger had promised them nothing but delusion (Quran 33:12). About a decade later Damascus had fallen (14 AH) and so had Ctesiphon, the Persian capital (16 AH)."),
            .text("When the Chosroes of the day tore up the Prophet's letter inviting him to Islam, the Prophet prayed that the Persians be torn apart in turn; so al-Zuhri, who narrated the story, understood from Sa'id ibn al-Musayyab (Sahih al-Bukhari 7264). The empire that had just humbled Rome fell into civil war: Khosrow II was deposed and killed by his own son in 628, and in the four years that followed the throne passed through many hands. The Prophet also said that each empire would have a last ruler:"),
            .hadith("bukhari:3618", cite: "Sahih al-Bukhari 3618", arabic: 29...49, english: [4...46]),
            .text("Yazdegerd III, the last Sasanian king, died in 651, and no Chosroes came after him. The half about Caesar needs care, since the Byzantine empire lasted until 1453. Al-Nawawi recorded that ash-Shafi'i and the other scholars read it as: no Chosroes would rule Iraq and no Caesar Syria, as they did in his day. Heraclius lost Syria for good after Yarmuk in 636. Jabir ibn Samurah (may Allah be pleased with him) even heard him name the building whose treasure a band of Muslims would take, the White Palace of Chosroes (Sahih Muslim 2919). The army of Sa'd ibn Abi Waqqas (may Allah be pleased with him) entered it in 16 AH."),
            .door(.prophecy("trench-rock")),
            .door(.prophecy("chosroes-torn")),
            .door(.prophecy("end-of-empires")),
            .door(.prophecy("white-palace")),
        ]),
        ArticleSection("A PEOPLE FROM THE STEPPES", [
            .text("Among the events before the Hour, the Prophet (peace and blessings be upon him) described one people closely:"),
            .hadith("bukhari:2928", cite: "Sahih al-Bukhari 2928", arabic: 30...53, english: [4...50]),
            .text("The Turks were known by name in his lifetime: a Turkic khaganate on Persia's northern frontier fought alongside Heraclius against Persia in 627. What the hadith foretold was war between them and his followers, who were then confined to Arabia, and war fierce enough to be counted among the signs of the Hour. Within a century the Muslims were fighting Turkic peoples in Central Asia. The greatest storm came later. Al-Bukhari died in 256 AH (870 CE), and his book had been copied and taught for three and a half centuries when the armies of Genghis Khan crossed into the Muslim east in 616 AH (1219 CE). In 656 AH (1258 CE) his grandson Hulagu sacked Baghdad and put the 'Abbasid caliph to death. Al-Nawawi, who lived through those years, wrote in his commentary on Sahih Muslim that a people with every one of these features had appeared, and that the Muslims had fought them more than once and were fighting them still."),
            .text("A second narration adds a river and a city. Abu Bakrah (may Allah be pleased with him) heard him describe a Muslim city by the Tigris with a bridge over it, and what would come to it at the end of time:"),
            .hadith("abudawud:4306", cite: "Sunan Abi Dawud 4306; graded hasan by al-Albani", arabic: 36...86, english: [6...47, 68...92]),
            .text("The hadith names al-Basrah, and neither Basra nor Baghdad existed when he said it. A commentator quoted in 'Awn al-Ma'bud, the well-known commentary on Sunan Abi Dawud, applied it to Baghdad, the capital of the caliphs built on the Tigris, whose bridge stood in its middle and which had a quarter by its gate called Bab al-Basrah. On that reading, which many share, it describes the Mongol siege of 1258. It is a reading, and it is offered here as one; the invaders' broad faces and small eyes are the same features al-Bukhari recorded."),
            .door(.prophecy("turks-mongols")),
            .door(.prophecy("basrah-qantura")),
        ]),
        ArticleSection("DEATHS HE FORETOLD", [
            .text("Some of the most exact predictions concern the people closest to the Prophet (peace and blessings be upon him): who would die, how, and in what order. Each could have been undone by one ordinary death in bed."),
            .text("He once climbed Mount Uhud with Abu Bakr, 'Umar and 'Uthman (may Allah be pleased with them), and the mountain shook beneath them:"),
            .hadith("bukhari:3699", cite: "Sahih al-Bukhari 3699", arabic: 17...46, english: [0...59]),
            .text("Abu Bakr died of illness in 13 AH. 'Umar was stabbed while leading the dawn prayer in 23 AH, and 'Uthman was killed in his own house by rebels in 35 AH. Neither died in battle, where a martyr's death would be looked for."),
            .text("While the Companions were building the mosque in Madinah, he said of 'Ammar ibn Yasir (may Allah be pleased with him):"),
            .hadith("bukhari:2812", cite: "Sahih al-Bukhari 2812", arabic: 39...68, english: [62...121]),
            .text("There was no civil war among the Muslims then, and there would be none until a quarter of a century after his death. 'Ammar, over ninety by most reports, was killed at Siffin in 37 AH, fighting in the army of 'Ali (may Allah be pleased with him). Ahl as-Sunnah take the hadith as one of their proofs that 'Ali was in the right, while holding that the Companions on the other side were believers who erred in their judgment."),
            .text("In his last illness he spoke privately to his daughter Fatimah (may Allah be pleased with her), and she wept, then laughed. She later explained why:"),
            .hadith("bukhari:3715", cite: "Sahih al-Bukhari 3715", arabic: 40...68, english: [35...100]),
            .text("He died of that illness, and she died about six months later, the first of his household to follow him, though she was young and his wives, his uncle al-'Abbas (may Allah be pleased with him) and her husband 'Ali all outlived her. A related case is Mu'tah, in 8 AH, far to the north in what is now Jordan: he announced in Madinah the deaths of its three commanders, one after another, before the news of their deaths had reached the city (Sahih al-Bukhari 4262). Strictly that is knowledge of a distant event rather than a prediction, and it is listed with its kind in the library."),
            .door(.prophecy("uhud-martyrs")),
            .door(.prophecy("ammar-killed")),
            .door(.prophecy("fatimah-first")),
            .door(.prophecy("mutah-martyrs")),
        ]),
        ArticleSection("THE SIGNS OF THE HOUR (TIER 2)", [
            .text("When Jibril, in the form of a man, asked the Prophet (peace and blessings be upon him) about the Hour, he gave no date, only signs:"),
            .hadith("muslim:8a", cite: "Sahih Muslim 8", arabic: 310...346, english: [490...565]),
            .text("Signs like these matter to believers, and several are now plain to see. As arguments, though, they are weaker than Tier 1, and it is better to say so than to lean on them. They carry no date, so the time to wait for them never runs out. Many describe human behaviour that has appeared in some form in other ages, so a reader who looks hard enough can find them anywhere. Whether a particular event is the fulfilment is a judgment, and careful people differ. What they add is weight, not proof: a number of things that sounded strange when he said them and are familiar now."),
            .checklist([
                "**Barefoot shepherds and tall buildings** (Sahih Muslim 8): the destitute herders of the desert vying to build higher. The tallest building in the world now stands on the Arabian coast, at Dubai.",
                "**Arabia returning to meadows and rivers** (Sahih Muslim 157): geologists have found the beds of ancient lakes and rivers under its sand, and irrigation has made parts of its desert green again.",
                "**Knowledge taken away** (Sahih al-Bukhari 100): not snatched from people's hearts but taken with the deaths of scholars, leaving the ignorant to give rulings, in an age when every book is a search away.",
                "**Diseases the forebears never knew** (Sunan Ibn Majah 4019, graded hasan by al-Albani): spreading where immorality is done openly. Medicine has described one new disease after another in living memory, some of them sexually transmitted.",
                "**A fire out of the Hijaz** (Sahih al-Bukhari 7118) lighting the necks of camels at Busra: in 654 AH (1256 CE) a volcano erupted beside Madinah, and al-Nawawi, who lived through that year, recorded it. This is the most concrete of the signs.",
                "**The idol of Dhul-Khalasa** (Sahih al-Bukhari 7116), destroyed in the Prophet's lifetime, would be circled by the women of Daws again. In recent centuries tribes of the region returned to venerating the site, until it was pulled down in 1344 AH (1925 CE).",
            ], title: "Signs Now Seen", icon: "hourglass"),
            .door(.prophecy("shepherds-buildings")),
            .door(.prophecy("arabia-meadows")),
            .door(.prophecy("knowledge-taken")),
            .door(.prophecy("unknown-diseases")),
            .door(.prophecy("fire-hijaz")),
            .door(.prophecy("dhul-khalasa")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**Couldn't the hadith prophecies have been written down after the events?**"),
            .text("For events in the Companions' own lifetimes that is the natural objection, and it is why the Quranic predictions come first here: the verses about the Romans and about Abu Lahab were recited in public before the events, to opponents who were listening for a mistake. For the rest, the dates of the books answer it. Al-Bukhari died in 256 AH, Muslim in 261 AH and Abu Dawud in 275 AH. The Mongol invasions began in 616 AH, the fire near Madinah came in 654 AH, and the towers of Arabia went up in living memory. A report cannot have been invented to fit an event that came centuries after its book was finished."),
            .markdown("**Wasn't the Roman victory a lucky guess?**"),
            .text("Gibbon thought it a guess, and still judged it the least likely guess a man could have made at that moment. It picked the losing side, set a span of years, and was put to a wager by people who thought it absurd. Nor does the case rest on one guess. The Quran preserves the charges the opponents of the Prophet (peace and blessings be upon him) made against him: poet, soothsayer, madman, sorcerer, forger, a man taught by a foreigner. A failed prediction is not among them, though it would have been the easiest charge of all to make."),
            .markdown("**Did he say the world would end within his own generation?**"),
            .text("Critics cite this narration from 'A'ishah (may Allah be pleased with her):"),
            .hadith("bukhari:6511", cite: "Sahih al-Bukhari 6511", arabic: 11...46, english: [0...58]),
            .text("The word he used was “your Hour,” the end of the lives of the people in front of him, as Hisham, who narrated it, explained. The Hour itself he always refused to date, as the Quran commands him to:"),
            .ayah("7:187", words: 0...14),
            .markdown("**Why leave out prophecies that other books and websites list?**"),
            .text("Because a case built on weak material is only as strong as its weakest piece. Some favourites do not meet the standard this app keeps. The hadith praising the leader and the army who would take Constantinople was graded weak by al-Albani. The saying that the dust of usury would reach everyone has a broken chain. The promise that Suraqah (may Allah be pleased with him) would wear the bracelets of Chosroes is not in the Sahih collections; it is reported without a connected chain, although Suraqah's pursuit of the Prophet during the Hijrah is authentic (Sahih al-Bukhari 3906). And the Prophet's curse on men who imitate women (Sahih al-Bukhari 5885) is a prohibition, not a prediction. Leaving these out costs the argument nothing."),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("A forger avoids deadlines, names and public stakes. The Prophet (peace and blessings be upon him) gave all three: Rome's recovery within a few years, his uncle's death in disbelief, the fall of Persia and of Caesar's Syria, a people from the steppes, the deaths of his closest Companions and of his daughter. The ones that could be checked were checked, by friends and enemies, and they held. The signs of the Hour add weight but are not the proof. Taken together, the record is not what a false prophet leaves behind."),
            .door(.library(.propheciesOfProphet)),
            .door(.link("https://provingislam.com/proofs", title: "Proofs of Islam", subtitle: "Proving Islam: prophecies and historical accuracies")),
            .door(.link("https://www.amazon.com/dp/B0DQHB6VQ9", title: "101 Fulfilled Islamic Prophecies", subtitle: "Mohammad Baqer: the Proving Islam book, using the Quran and authentic hadith")),
            .door(.article("ProvingSourcesView")),
        ]),
        ArticleSection("KEY TERMS", [
            .term("Al-Ghayb", arabic: "الغَيب", meaning: "From the root **غ-ي-ب**, to be absent or hidden: whatever lies beyond the senses, the future among it. The Quran says its keys are with Allah (Glorified and Exalted be He) alone (Quran 6:59), and that He discloses part of it to the messengers He chooses (Quran 72:26-27)."),
            .term("Bid'", arabic: "بِضع", meaning: "A small, unspecified number, which the Arabs used for three to nine. The Quran's span for the Roman recovery, **bid' sinin**, is “a few years” in this sense."),
            .term("Ashrat as-Sa'ah", arabic: "أَشرَاط السَّاعَة", meaning: "The signs of the Hour: events the Prophet (peace and blessings be upon him) described as coming before the Last Day. The Quran says some had already come in his time (Quran 47:18). They mark the Hour's approach without dating it."),
            .term("Dala'il an-Nubuwwah", arabic: "دَلَائِل النُّبُوَّة", meaning: "The proofs of prophethood, and the name of a genre of books that gather them, fulfilled prophecies among them; al-Bayhaqi and Abu Nu'aym each wrote one."),
        ]),
    ]
}

struct ProvingSourcesView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "ProvingSourcesView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Where Could He Have Learned It?")
        .selectableArticleList(article: "ProvingSourcesView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: from the day the Quran was first recited, its opponents said that someone must be teaching the Prophet (peace and blessings be upon him). The Quran records the charge and answers it, historians find no written Arabic Bible from before Islam, and where the Quran’s accounts of the prophets differ from the older ones, they differ exactly where those accounts contain an anachronism or lay a grave sin at a prophet’s door. That is not how borrowing behaves."),
        ]),
        ArticleSection("THE QUESTION ITSELF", [
            .text("Every argument that the Quran came from Allah (Glorified and Exalted be He) meets the same reply sooner or later: perhaps the Prophet (peace and blessings be upon him) simply heard these stories from the people around him. Jews and Christians lived in Arabia, caravans crossed it, and the stories of Nuh, Ibrahim, Yusuf and Musa were ancient long before him. It is a fair question, and the Quran was the first to record it."),
            .text("But the theory must explain more than how a story reached him; it must explain what he did with it. Accounts taken from the people around him should carry what those people carried, difficulties included. Instead the Quran parts company with the older accounts again and again, and not at random: where the older text holds an anachronism that no one could detect for over a thousand years, and where it lays a grave sin at a prophet’s door."),
            .callout("A borrower keeps what his sources give him, mistakes included. To produce the Quran’s accounts from hearsay, a man who could not read would have had to learn the stories, spot exactly which details were anachronisms or sins attributed to prophets, correct those and no others, and then tell his own people that neither he nor they had known these stories before. **Proving Islam** calls this the selective borrowing problem: “At some point ‘borrowing’ becomes less economical than revelation.”", title: "The Selective Borrowing Problem", icon: "questionmark.circle.fill"),
            .text("The same test, applied to the science of the age rather than its scriptures, has a chapter of its own:"),
            .door(.article("ProvingFingerprintView")),
        ]),
        ArticleSection("WHAT THE QURAN SAYS ABOUT ITS SOURCE", [
            .text("The accusation is as old as the Quran, which quotes it in several forms, in surahs recited in Makkah before hostile audiences, and answers each one. Allah (Glorified and Exalted be He) records the first, that others were supplying him with old tales:"),
            .ayah("25:4-5", words: 17...24),
            .text("The Quran calls this an injustice and a lie, and names the true source in the next verse: the One who knows every secret in the heavens and the earth (Quran 25:6). Notice what the charge requires: helpers, written material and daily dictation, kept up for years in a small town where everyone knew everyone."),
            .text("When his opponents tried to name a teacher, a single verse answered them:"),
            .ayah("16:103", words: 7...15),
            .text("Ibn Kathir explains that they meant a non-Arab man who served some of the clans of Quraysh and sold goods near as-Safa. The Prophet (peace and blessings be upon him) may have sat with him a little, but the man knew only enough Arabic to answer simple questions. He spoke a foreign tongue; the Quran is clear Arabic."),
            .markdown("A third form was that he had **studied (دَرَسْتَ)**:"),
            .ayah("6:105", words: 3...4),
            .text("Ibn Kathir explains this as the charge that he had studied with the People of the Book and learned from them, as Ibn ‘Abbas (may Allah be pleased with him), Mujahid, Sa‘id ibn Jubayr and ad-Dahhak also said."),
            .text("Against all of these the Quran sets a fact known to everyone who had grown up with him:"),
            .ayah("29:48", words: 0...9),
            .text("He had read no scripture and did not write, and the verse draws the conclusion itself: had he done so, those who wanted to dismiss the Quran would have had grounds for doubt. The revelation began with this very admission, in the cave of Hira:"),
            .hadith("bukhari:3", cite: "Sahih al-Bukhari 3", arabic: 84...92, english: [103...123]),
            .text("Finally, the Quran makes a claim about the stories themselves, addressed to the very people who could have contradicted it. After the story of Nuh it says:"),
            .ayah("11:49", words: 6...14),
            .text("“Neither you nor your people” is a public claim about a whole city, recited to that city. Had the Quraysh known the story, the easy reply was “We knew that already.” Instead they said that someone was dictating it to him (Quran 25:5). The Quran says the same of the story of Yusuf:"),
            .ayah("12:3", words: 10...15),
            .text("The Quran never claims that no one on earth had heard of these prophets. It claims that he and his people had not known their stories, and that was a claim his own city was in a position to test."),
        ]),
        ArticleSection("WAS THERE AN ARABIC BIBLE?", [
            .text("Had the stories reached him from a book, it would have had to be in Arabic, the only language he spoke, and read aloud to him, since he did not read. So historians ask a precise question: was any part of the Bible translated into Arabic before Islam?"),
            .markdown("The fullest modern study is **The Bible in Arabic** (Princeton University Press, 2013) by Sidney H. Griffith, for many years a professor at the Catholic University of America and a leading historian of Arabic and Syriac Christianity, who writes as a historian, not as an advocate for Islam. He grants that an early Arabic Gospel is possible, as Irfan Shahid and others argued, but finds that no conclusive documentary or clear textual evidence of a written Arabic Bible from before Islam has come to light. Of the Jewish side he writes:"),
            .quote(text: "“As in the Christian instance, there is no compelling evidence that Arabic-speaking Jews translated any portion of the Hebrew Bible into Arabic in pre-Islamic times.” (Sidney H. Griffith, The Bible in Arabic, p. 52)", dimmed: true),
            .text("His conclusion runs against expectation:"),
            .quote(text: "“…the somewhat counterintuitive conclusion emerges that the Arabic Qurʾān, in the form in which it was collected and published in writing in the seventh century, is after all the first scripture written in Arabic.” (Sidney H. Griffith, The Bible in Arabic, p. 53)", dimmed: true),
            .text("The first written Arabic translations of parts of the Bible, he judges, came after the Arab conquests, and the written Quran may well have prompted them."),
            .markdown("Honesty requires the other half of his argument too. Griffith does not say the Arabs knew nothing of the Bible. He argues that biblical stories **circulated orally** in Arabic, mainly in the worship of Arabic-speaking Christians, translated on the spot from Syriac, and that the Quran’s audience knew that lore. So the real question is whether hearsay explains the particular shape of the Quran’s accounts: a scripture in which, as Griffith puts it, the Bible is “at the same time everywhere and nowhere,” with “but one or two instances of actual quotation” (p. 2), and which departs from the older accounts at the points examined next."),
        ]),
        ArticleSection("KING OR PHARAOH?", [
            .markdown("The story of **Yusuf (peace be upon him)** is told at length in Genesis and in the Quran, both set in Egypt. Genesis calls the ruler who raised Yusuf to power **Pharaoh** throughout; “king of Egypt” appears only a few times, once joined to it:"),
            .quote(text: "“And Joseph was thirty years old when he stood before Pharaoh king of Egypt. And Joseph went out from the presence of Pharaoh, and went throughout all the land of Egypt.” (Genesis 41:46, KJV)"),
            .text("The Quran tells the story in a surah of its own and never once calls this ruler Pharaoh. He is always al-malik, “the king”: the king who dreamed of the seven cows, who took Yusuf into his service, whose measure went missing and whose law governed the land (Quran 12:43, 12:50, 12:54, 12:72, 12:76)."),
            .ayah("12:43", words: 0...1),
            .versus(ArticleVersus.Side("Genesis 41:46", caption: "“Pharaoh king of Egypt”: Genesis calls Yusuf’s ruler Pharaoh all through chapters 39 to 50."), ArticleVersus.Side("Quran 12:43", arabic: "وَقَالَ ٱلۡمَلِكُ", caption: "“And the king said…”: Surah Yusuf never once calls him Fir‘awn."), quranic: true),
            .stats([ArticleStat("87", "“Pharaoh” in Genesis 39–50 (KJV)"), ArticleStat("5", "“the king” in Surah Yusuf"), ArticleStat("0", "“Pharaoh” in Surah Yusuf"), ArticleStat("74", "“Fir‘awn” in the Quran, always the ruler of Musa’s time")]),
            .text("The ruler Musa (peace be upon him) confronted is another matter. The Quran calls him Fir‘awn, Pharaoh, again and again:"),
            .ayah("20:24"),
            .markdown("Why does it matter? The word comes, by way of Hebrew and Greek, from the Egyptian **per-aa**, “the Great House”, which for over a thousand years named the royal palace, not the man who lived in it. Egyptologists date its use for the king himself to the New Kingdom, from the Eighteenth Dynasty onward: Sir Alan Gardiner’s Egyptian Grammar, as Islamic Awareness cites it, gives the earliest clear example under Amenhotep IV (Akhenaten) in the fourteenth century BC, with possible earlier cases under Thutmose III. Toby Wilkinson’s dictionary of ancient Egypt puts it plainly:"),
            .quote(text: "“Originally applied to the royal residence, it was used from the 18th Dynasty to refer to the king himself. Hence, the use of ‘pharaoh’ for Egyptian rulers before the New Kingdom is strictly anachronistic and best avoided.” (Toby Wilkinson, The Thames & Hudson Dictionary of Ancient Egypt, p. 186, as quoted by Islamic Awareness)", dimmed: true),
            .text("Yusuf’s story carries no date that can be pinned to an Egyptian record, so this is an argument about fit, not a proof on its own. But those who treat the story as history generally place him before the New Kingdom, most often, as the Jewish Encyclopedia notes, under the Hyksos kings; and Musa’s story, on the dates most often proposed for it, falls within the New Kingdom. On that chronology the Quran’s usage matches the evidence: a king in Yusuf’s day, a Pharaoh in Musa’s."),
            .text("Christian writers reply that a later narrator naturally used the title of his own day, as a modern historian might use a modern place name for an ancient site. That may explain Genesis; it does not explain the Quran. A retelling of Genesis, or of stories told from it, would have inherited a word that runs through the whole of Yusuf’s story. The Quran keeps it for Musa’s ruler alone. No belief is served by that difference, and in the seventh century no one could check it: the hieroglyphs could not be read again until the nineteenth century."),
            .text("Proving Islam presents this point in its article “King or Pharaoh?”, crediting the research of Islamic Awareness. The Miracles of the Quran library has its own page on it:"),
            .door(.miracle("pharaoh", title: "King or Pharaoh?")),
        ]),
        ArticleSection("WHERE THE ACCOUNTS PART WAYS", [
            .markdown("The second kind of difference concerns the prophets themselves. Muslims believe that Allah (Glorified and Exalted be He) protected His prophets (peace be upon them) from the gravest sins and from anything that would corrupt their message, a belief called **‘ismah (عِصْمَة)**. It does not make them flawless: the Quran shows Adam, Musa, Dawud and Yunus repenting (Quran 7:23, 28:16, 38:24, 21:87). It never shows a prophet worshipping an idol or leading his people into it. Ibn Taymiyyah states where the scholars stand:"),
            .quote(text: "“The view that the Prophets are infallible and protected against committing major sins, as opposed to minor sins, is the view of the majority of Muslim scholars and of all groups.” (Ibn Taymiyyah, Majmu‘ al-Fatawa 4/319)", dimmed: true),
            .text("A lesser slip, he adds, was never left uncorrected (Majmu‘ al-Fatawa 4/320). With that in view, compare two accounts."),
            .markdown("The first is the golden calf. In Exodus, **Harun (Aaron)** himself makes it and builds an altar before it:"),
            .quote(text: "“And he received them at their hand, and fashioned it with a graving tool, after he had made it a molten calf: and they said, These be thy gods, O Israel, which brought thee up out of the land of Egypt. And when Aaron saw it, he built an altar before it; and Aaron made proclamation, and said, To morrow is a feast to the LORD.” (Exodus 32:4-5, KJV)"),
            .text("In the Quran the calf has a different maker. Allah tells Musa who led his people astray in his absence:"),
            .ayah("20:85", words: 7...8),
            .text("The people explain that they threw the ornaments they carried into the fire, and that the Samiri threw likewise and brought out a lowing calf:"),
            .ayah("20:87-88", words: 12...20),
            .text("Harun, far from making it, warned them against it:"),
            .ayah("20:90"),
            .text("When Musa returned in anger and seized his brother, Harun explained that the people had overpowered him and nearly killed him, and that he feared being blamed for dividing the Children of Israel (Quran 7:150, 20:94). Musa then questioned the Samiri, who confessed (Quran 20:95-97), and prayed for forgiveness for himself and his brother (Quran 7:151). The Quran does not hide that Harun was blamed; it shows why the blame was lifted."),
            .markdown("The second is **Sulayman (Solomon)**. The First Book of Kings says that in his old age his wives turned his heart to other gods:"),
            .quote(text: "“For it came to pass, when Solomon was old, that his wives turned away his heart after other gods: and his heart was not perfect with the LORD his God, as was the heart of David his father.” (1 Kings 11:4, KJV)"),
            .text("The Quran tells no such story. Answering those who claimed that his power came from sorcery, as Ibn Kathir explains, it clears him in general terms:"),
            .ayah("2:102", words: 7...12),
            .text("And in a Makkan surah Allah praises him alongside his father Dawud:"),
            .ayah("38:30"),
            .text("Jewish and Christian readers have their own long traditions of reading these passages, and this chapter does not argue them. Its point is narrower, and Proving Islam puts it in one line: a copyist does not correct his source. Each item below is in the older text, and none of it is in the Quran:"),
            .checklist([
                "**Pharaoh** as the title of Yusuf’s ruler, all through Genesis 39 to 50",
                "**Harun** making the calf and building an altar before it (Exodus 32:4-5)",
                "**Sulayman’s** heart turned after other gods in his old age (1 Kings 11:4)",
                "**Nuh** drunk and uncovered in his tent (Genesis 9:21)",
                "**Lut** and his daughters in the cave (Genesis 19:30-36)",
                "**Dawud**, Bathsheba and Uriah the Hittite (2 Samuel 11)",
            ], title: "What a Copyist Would Have Kept", icon: "book.closed.fill"),
            .text("The Quran’s accounts lack every one of them. The first is a matter of history; the rest all fall in one direction, that of a single belief about the prophets."),
            .door(.article("ProphetsView")),
        ]),
        ArticleSection("REVEALED IN MAKKAH", [
            .text("A popular form of the theory says that the Prophet (peace and blessings be upon him) learned these stories from the Jews of Madinah. The order of revelation makes that hard to sustain. He received revelation in Makkah for thirteen years before the Hijrah (Sahih al-Bukhari 3902), and the Jewish tribes of the Hijaz lived in Madinah, Khaybar and the oases to the north, not in Makkah."),
            .markdown("Yet the surahs that carry most of the stories of the prophets are **Makkan**: Yusuf, Maryam, Ta-Ha, al-A‘raf, al-Qasas, Hud, ash-Shu‘ara’ and others. Some classifications mark a few individual verses in them as Madinan, but not the passages on Yusuf’s king or on Harun and the calf quoted above. Madinan surahs such as al-Baqarah return to some of the stories, often briefly and in address to the People of the Book, but the detailed narratives came first, in Makkah."),
            .text("‘Abdullah ibn Mas‘ud (may Allah be pleased with him), one of the earliest Muslims of Makkah, counted several of the great narrative surahs among the first he learned:"),
            .hadith("bukhari:4739", cite: "Sahih al-Bukhari 4739", arabic: 21...33, english: [0...26]),
            .text("Griffith makes the same observation as a historian: the Quran’s evocation of biblical history and biblical figures is found “mostly but certainly not exclusively in Meccan sūrahs” (The Bible in Arabic, pp. 24-25). By the time the Prophet reached Madinah these accounts had long been recited, and when some of the learned men of the Jews there met him, they came to question him, not to teach him."),
        ]),
        ArticleSection("THE TEST OF ABDULLAH IBN SALAM", [
            .markdown("Among the Jews of Madinah was **‘Abdullah ibn Salam (may Allah be pleased with him)**, whom his own community called its most learned. When the Prophet (peace and blessings be upon him) arrived, he came with a test: three questions that, he said, only a prophet could answer. Anas (may Allah be pleased with him) narrates:"),
            .hadith("bukhari:3329", cite: "Sahih al-Bukhari 3329", arabic: 16...74, english: [0...81]),
            .text("The Prophet answered all three, and ‘Abdullah ibn Salam testified on the spot to his prophethood. Knowing his people, he asked the Prophet to question them about him before they heard of his Islam. Their answer is the verdict of those who knew him best:"),
            .hadith("bukhari:3329", cite: "Sahih al-Bukhari 3329", arabic: 162...184, english: [246...283]),
            .text("When he then declared his faith before them, the same men called him the worst of them (Sahih al-Bukhari 3329). The story is told three times in Sahih al-Bukhari (3329, 3938 and 4480), each through Anas, and Sa‘d ibn Abi Waqqas (may Allah be pleased with him) reports that the Prophet spoke of ‘Abdullah ibn Salam as one of the people of Paradise (Sahih al-Bukhari 3812)."),
            .text("The story does not prove, by itself, where any passage of the Quran came from. It shows how the most learned man among the Jews of Madinah judged the Prophet when he met him: he came as an examiner, not as a teacher, and he left as a follower."),
            .door(.article("JudaismAnswerView")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**Couldn’t he have heard the stories from travellers?**"),
            .text("Makkah was a trading town, and the Sirah records that the Prophet (peace and blessings be upon him) travelled to Syria as a boy with his uncle Abu Talib and as a young man with the goods of Khadijah (may Allah be pleased with her). But what travels with traders is a story’s familiar outline, not a version that departs from its source exactly where the source is problematic. A traveller retelling Yusuf’s story from what Jews and Christians said would have spoken of Pharaoh, as Genesis does throughout. And the Quran’s claim that neither he nor his people had known these stories (Quran 11:49) was made to a city whose own merchants travelled the same roads."),
            .markdown("**What about Waraqa ibn Nawfal?**"),
            .text("Waraqa, Khadijah’s cousin, was a man of Makkah known for his learning in the earlier scriptures. Khadijah took the Prophet to him after the first revelation:"),
            .hadith("bukhari:3", cite: "Sahih al-Bukhari 3", arabic: 205...245, english: [347...404]),
            .text("Other narrations in Sahih al-Bukhari say that he wrote from the Gospel in Arabic (Sahih al-Bukhari 4953). Griffith notes such reports and adds that “nothing suggests that these, if they even existed, were more than personal notes or aides de memoires” (The Bible in Arabic, p. 22). In any case Waraqa was old and blind, met the Prophet at the very beginning, and did not live to see what followed:"),
            .hadith("bukhari:3", cite: "Sahih al-Bukhari 3", arabic: 328...335, english: [527...543]),
            .text("His recorded words were a confirmation that this was the angel Allah (Glorified and Exalted be He) had sent to Musa, and a warning that the Prophet’s people would drive him out. The stories of Yusuf, of the calf and of the other prophets came in the years after his death."),
            .markdown("**Don’t historians say he reshaped the stories to fit his theology?**"),
            .text("Some do. Griffith writes that the Quran “recalls only such biblical stories as fit the paradigm of its prophetology, and it edits the narratives where necessary to fit the pattern” (The Bible in Arabic, p. 3). Muslims agree that the accounts are shaped by one consistent understanding of prophethood; the disagreement is over whose understanding it is. Three things weigh against a human editor. Editing at the right points requires knowing the stories well, and this editor had no Arabic Bible, could not read, and faced opponents who could point to no teacher but a foreign servant. Some differences, like king and Pharaoh, serve no belief at all, yet match evidence that no one could read for twelve centuries. And he told his own city, in public, that neither he nor they had known these stories."),
            .markdown("**Doesn’t the Quran share some details with later Jewish and Christian writings?**"),
            .text("It does: some details appear not in the Bible but in later Jewish commentary or in Christian writings outside it, and critics read this as borrowing. The Quran describes itself as confirming the scripture before it and as a criterion over it (Quran 5:48), so Muslims expect it to affirm some of what those communities preserved and to reject the rest. The parallels have a chapter of their own:"),
            .door(.article("ProvingScriptureView")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("The question “where could he have learned it?” is as old as the Quran, and the Quran answered it in public: the only teacher his opponents could name spoke a foreign tongue, the Prophet (peace and blessings be upon him) had read no scripture and written no line, and neither he nor his people had known these stories. History adds that there was no written Arabic Bible, that the stories came in Makkah before he lived beside any Jewish community, and that the most learned man among the Jews of Madinah came to examine him and stayed to follow him. Above all, the accounts differ as borrowing would not: a king for Yusuf and a Pharaoh for Musa, and Harun and Sulayman cleared of what the older texts lay at their door. A borrower keeps what he is given; these accounts read like the work of One who knew what had really happened."),
        ]),
        ArticleSection("KEY TERMS", [
            .term("Ummi", arabic: "أُمِّيّ", meaning: "Unlettered. The Quran calls the Prophet (peace and blessings be upon him) **an-nabiyy al-ummi**, the unlettered prophet (Quran 7:157), and says he recited no scripture and wrote none before the revelation (Quran 29:48)."),
            .term("Asatir al-Awwalin", arabic: "أَسَاطِيرُ ٱلْأَوَّلِين", meaning: "“Legends of the former peoples”: the opponents’ name for the Quran’s accounts, which they claimed were written out and dictated to him (Quran 25:5)."),
            .term("‘Ismah", arabic: "عِصْمَة", meaning: "From the root **ع-ص-م**, to protect: the protection Allah (Glorified and Exalted be He) gave His prophets from major sins and from anything that would corrupt the message. A lesser slip was never left uncorrected."),
            .term("Makki and Madani", arabic: "مَكِّيّ وَمَدَنِيّ", meaning: "**Makki**: revealed before the Hijrah. **Madani**: revealed after it, wherever the verse itself came down."),
            .term("Fir‘awn", arabic: "فِرْعَوْن", meaning: "Pharaoh, the Quran’s name for the ruler Musa confronted; ultimately from the Egyptian **per-aa**, “the Great House”, a word for the palace that came to mean the king only in the New Kingdom."),
        ]),
    ]
}

struct ProvingBibleView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "ProvingBibleView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Bible Points Ahead")
        .selectableArticleList(article: "ProvingBibleView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: the Quran told the Jews and Christians of its day that they would find the Prophet (peace and blessings be upon him) described in their own books. Classical scholars such as Ibn Taymiyyah and Ibn al-Qayyim, and Proving Islam today, read five passages of the Bible as pointing to him; this page gives each reading, the reading Christians and Jews give instead, and the reasons the Muslim reading is argued."),
        ]),
        ArticleSection("WHAT THE QURAN CLAIMS", [
            .text("The claim that the Prophet (peace and blessings be upon him) was foretold did not begin with Muslims searching the Bible. It is the Quran’s own claim, made in public to communities that owned the earlier books and could check them. Allah (Glorified and Exalted be He) describes the believers as those who follow a messenger they find written in their scriptures:"),
            .ayah("7:157", words: 0...11),
            .text("He records the glad tidings that ‘Isa (peace be upon him), the son of Maryam, gave to the Children of Israel:"),
            .ayah("61:6", words: 11...23),
            .text("And He points to the learned men of the Children of Israel, who recognised it, as a sign:"),
            .ayah("26:196-197"),
            .markdown("Ibn Taymiyyah (may Allah have mercy on him) drew an argument from the claim itself. The Prophet repeated it again and again, to his followers and to his enemies, and called the People of the Book to witness it. **A man who wants to be believed does not appeal to witnesses he knows will deny him**, so the claim was safe to make only if it was true:"),
            .quote(text: "“If he had not known that he was written in what they had, and still more had he known that he was not, he could never have told of it time after time, called on it as a witness, and declared it to those who agreed with him and those who opposed him.” (Ibn Taymiyyah, al-Jawab as-Sahih)", arabic: "فلو لم يعلم أنه مكتوب عندهم، بل علم انتفاء ذلك، لامتنع أن يخبر بذلك مرة بعد مرة، ويستشهد به ويظهر ذلك لموافقيه ومخالفيه", dimmed: true),
            .text("Some of those who knew the books did recognise him. ‘Abdullah ibn Salam (may Allah be pleased with him), a rabbi of Madinah, questioned him and accepted Islam (Sahih al-Bukhari 3329), and the Quran speaks of a witness from the Children of Israel who testified and believed (Quran 46:10). Most did not, though the Quran says that those given the Scripture knew him as they knew their own sons (Quran 2:146)."),
        ]),
        ArticleSection("HOW THESE PASSAGES ARE READ", [
            .text("Muslims do not hold the Bible to be the Torah and the Gospel exactly as they were revealed. The Quran says that a portion was forgotten and that words were moved from their places (Quran 5:13), and the books that survive were written, edited and translated by many hands. So a Muslim does not expect a clean prophecy with a name and a date. He expects what the Quran describes: remnants of a true description, surviving inside texts that others read in other ways."),
            .text("That is also how Christians read the Hebrew scriptures. They find Jesus in passages of the Torah and the Prophets that Jewish scholars read differently, and they argue from how well the details fit. Ibn Taymiyyah made exactly this point:"),
            .quote(text: "“These glad tidings in these books are of the same kind as the glad tidings of the Messiah.” (Ibn Taymiyyah, al-Jawab as-Sahih)", arabic: "وهذه البشارات في هذه الكتب من جنس البشارات بالمسيح", dimmed: true),
            .text("The Jews, he went on, accept the words of the passages that Christians apply to the Messiah and dispute only their meaning. That dispute does not cancel the glad tidings of the Messiah, and the same dispute over the glad tidings of Muhammad (peace and blessings be upon him) does not cancel them either. The scholars who gathered these passages, Ibn Taymiyyah in al-Jawab as-Sahih and his student Ibn al-Qayyim in Hidayat al-Hayara, argued them text by text."),
            .callout("Ibn Taymiyyah counted the glad tidings of the earlier prophets as an **independent proof** of prophethood and one of its great signs. This page takes them as seriously, and with care, because the texts have passed through many hands. So each passage below is set out the same way: what Muslim scholars read it as, what Christians and Jews read it as instead, and why the Muslim reading is argued.", title: "A Reading, Not a Proof Text", icon: "scalemass.fill"),
            .door(.article("ChristianityAnswerView")),
            .door(.article("BooksView")),
        ]),
        ArticleSection("THE PROMISE TO ISMA'IL", [
            .text("Ibrahim (peace be upon him) had two sons, Isma‘il (Ishmael) and Ishaq (Isaac), and Genesis records promises for both. Of Isma‘il, God tells Ibrahim:"),
            .quote(text: "“And as for Ishmael, I have heard thee: Behold, I have blessed him, and will make him fruitful, and will multiply him exceedingly; twelve princes shall he beget, and I will make him a great nation.” (Genesis 17:20, KJV)", dimmed: true),
            .text("When Hagar and the boy were sent away, the promise was given twice more:"),
            .quote(text: "“And also of the son of the bondwoman will I make a nation, because he is thy seed.” … “Arise, lift up the lad, and hold him in thine hand; for I will make him a great nation.” (Genesis 21:13, 18, KJV)", dimmed: true),
            .text("Genesis then says that Isma‘il grew up in the wilderness of Paran (Genesis 21:21), and it names his sons. The second is Kedar, a name the Bible itself pairs with Arabia (Isaiah 21:13–16; Ezekiel 27:21):"),
            .quote(text: "“And these are the names of the sons of Ishmael, by their names, according to their generations: the firstborn of Ishmael, Nebajoth; and Kedar, and Adbeel, and Mibsam” (Genesis 25:13, KJV)", dimmed: true),
            .markdown("**Muslim scholars read this as** a promise that reached its fullness in the Prophet (peace and blessings be upon him), who is from the children of Isma‘il (Sahih Muslim 2276). Ibn Taymiyyah argued from the words “a great nation”: a nation of idol worshippers is not what God would call great in a promise of blessing, and a man is not honoured merely by having many descendants. The greatness came, he said, when faith and prophethood came to Isma‘il’s line:"),
            .quote(text: "“This surpassing honour, by which the children of Isma‘il came to stand above other peoples, appeared only with the prophethood of Muhammad; and that shows that his prophethood is true, and was foretold.” (Ibn Taymiyyah, al-Jawab as-Sahih)", arabic: "فهذا التعظيم المبالغ فيه، الذي صار به ولد إسماعيل فوق الناس، لم يظهر إلا بنبوة محمد، فدل ذلك على أنها حق ومبشر به", dimmed: true),
            .text("Ibrahim and Isma‘il, the Quran records, prayed for exactly this as they raised the Ka‘bah: a messenger from among their own descendants."),
            .ayah("2:129", words: 0...11),
            .markdown("**Christians and Jews read it instead** as a promise kept in the twelve princes and the Arab tribes descended from Ishmael (Genesis 25:13–16), while the covenant itself, God says in the very next verse, would be established with Isaac (Genesis 17:21)."),
            .markdown("**Why the Muslim reading is argued:** Muslims do not deny the covenant with Ishaq. The prophets of the Children of Israel came through it, and the Quran honours every one of them. The question is what the promise to Isma‘il amounted to. After Isma‘il himself, no prophet came from his line until the Prophet, and when the Prophet was born his people were worshipping idols around the House their father had built; the Quran calls them a people whose forefathers had not been warned (Quran 36:6). Then, within one lifetime, a man from that line brought a scripture, and around it grew a nation that has worshipped the God of Ibrahim for fourteen centuries. If “a great nation” from Isma‘il means more than a count of descendants, it is hard to find its fulfilment anywhere else. The Prophet himself described his coming as “the prayer of my father Ibrahim, and the glad tidings of ‘Isa”, in a narration reported by al-Hakim, who graded it sahih, with adh-Dhahabi agreeing."),
        ]),
        ArticleSection("A PROPHET LIKE UNTO MOSES", [
            .text("In Deuteronomy, God tells Musa (Moses, peace be upon him):"),
            .quote(text: "“I will raise them up a Prophet from among their brethren, like unto thee, and will put my words in his mouth; and he shall speak unto them all that I shall command him.” (Deuteronomy 18:18, KJV)", dimmed: true),
            .markdown("**Muslim scholars read this as** the Prophet (peace and blessings be upon him): the brethren of Israel are the children of Isma‘il, and the prophet like Musa is the one who, like him, brought a law, led a people, and was given God’s own words to speak. Ibn al-Qayyim relates a debate in the Maghrib in which a Jew said the promised prophet was Joshua, and a Muslim scholar answered:"),
            .quote(text: "“This is impossible, for several reasons. The first: it says in your own Torah, at its end, that no prophet like Moses will arise among the Children of Israel.” (A Muslim scholar of the Maghrib, as related by Ibn al-Qayyim in Hidayat al-Hayara)", arabic: "هذا محال من وجوه: أحدها: أنه قال عندك في آخر التوراة: أنه لا يقوم في بني إسرائيل نبي مثل موسى", dimmed: true),
            .text("He meant the closing chapter of Deuteronomy, written after the death of Musa:"),
            .quote(text: "“And there arose not a prophet since in Israel like unto Moses, whom the LORD knew face to face” (Deuteronomy 34:10, KJV)", dimmed: true),
            .text("His second reason was the word “brethren”. The brothers of Israel, he said, are the descendants of Isma‘il and of Esau, and no prophet came from Esau’s line after Musa, so the promise points to the children of Isma‘il. The Torah uses the word this way itself, calling the Edomites “your brethren the children of Esau” (Deuteronomy 2:4). And the Quran describes the Prophet’s mission in the very terms of the comparison:"),
            .ayah("73:15"),
            .markdown("**Christians and Jews read it instead** in two ways: Christians of Jesus, as Peter applies it in Acts 3:22, and Jews, following Rashi, of the line of Israelite prophets who followed Moses one after another, noting that the same book uses “from among thy brethren” of an Israelite king (Deuteronomy 17:15)."),
            .markdown("**Why the Muslim reading is argued:** the verse promises one prophet like Musa, and the Torah’s own last chapter says none like him had arisen in Israel. In the Gospel of John, the priests ask John the Baptist whether he is the Christ, or Elias, or “that prophet” (John 1:19–21), so the Jews of that time awaited the prophet like Moses as someone other than the Messiah. Muslims agree that Jesus was the Messiah, and find the prophet like Moses in the one who came after him. The likeness is close:"),
            .checklist([
                "**A law from God:** Musa brought the Torah and its commandments; the Prophet brought the Quran and a complete law (Quran 5:48).",
                "**A people formed around the message:** each called a people to God, led them, and judged between them.",
                "**An emigration:** Musa led his people out of Egypt; the Prophet left Makkah for Madinah with his Companions.",
                "**The tyrant overthrown:** Pharaoh drowned in the sea; the chiefs of Quraysh who fought the Prophet were defeated, and Makkah opened to him in his lifetime.",
                "**Family and a natural death:** both married, had children, died, and were buried.",
            ], title: "Like Unto Moses", icon: "person.2.fill"),
            .text("The last words of the promise, that God would put His words in the prophet’s mouth, describe how the Quran came. The Prophet did not compose it; he was told not to hurry his tongue with it, but to follow it as it was recited to him:"),
            .ayah("75:16-19"),
            .door(.article("JudaismAnswerView")),
        ]),
        ArticleSection("THE SERVANT OF ISAIAH 42", [
            .text("Isaiah 42 opens with God presenting His servant:"),
            .quote(text: "“Behold my servant, whom I uphold; mine elect, in whom my soul delighteth; I have put my spirit upon him: he shall bring forth judgment to the Gentiles. He shall not cry, nor lift up, nor cause his voice to be heard in the street. A bruised reed shall he not break, and the smoking flax shall he not quench: he shall bring forth judgment unto truth. He shall not fail nor be discouraged, till he have set judgment in the earth: and the isles shall wait for his law.” (Isaiah 42:1–4, KJV)", dimmed: true),
            .markdown("**Muslim scholars read this as** the Prophet (peace and blessings be upon him), and the description it contains was known to the Companions. ‘Ata’ ibn Yasar asked ‘Abdullah ibn ‘Amr ibn al-‘As (may Allah be pleased with them) how the Prophet was described in the Torah, and he answered that he is described there with some of his description in the Quran:"),
            .hadith("bukhari:2125", cite: "Sahih al-Bukhari 2125", arabic: 58...99, english: [84...175]),
            .text("Ibn Taymiyyah noted that the copies of the Torah he had seen did not contain these words, that “Torah” in such reports can mean the earlier scriptures as a whole, and that the description is found in the prophecy of Isaiah. He quoted the passage from an Arabic translation and concluded:"),
            .quote(text: "“These are descriptions that fit Muhammad and his nation, and they are among the most sublime of the glad tidings of him given by the earlier prophets.” (Ibn Taymiyyah, al-Jawab as-Sahih)", arabic: "وهذه صفات منطبقة على محمد ﷺ وأمته، وهي من أجل بشارات الأنبياء المتقدمين به", dimmed: true),
            .versus(ArticleVersus.Side("Isaiah 42:2 (KJV)", caption: "“He shall not cry, nor lift up, nor cause his voice to be heard in the street.”"), ArticleVersus.Side("Sahih al-Bukhari 2125", arabic: "وَلاَ سَخَّابٍ فِي الأَسْوَاقِ", caption: "“Nor a noisemaker in the markets”"), quranic: false),
            .text("Later in the same chapter, the prophet calls the whole earth, and then the desert and its villages, to sing:"),
            .quote(text: "“Sing unto the LORD a new song, and his praise from the end of the earth, ye that go down to the sea, and all that is therein; the isles, and the inhabitants thereof. Let the wilderness and the cities thereof lift up their voice, the villages that Kedar doth inhabit: let the inhabitants of the rock sing, let them shout from the top of the mountains.” (Isaiah 42:10–11, KJV)", dimmed: true),
            .text("Kedar is the son of Isma‘il named in Genesis 25:13. Among the glad tidings that Ibn Taymiyyah gathers in al-Jawab as-Sahih, these lines appear in an Arabic rendering, followed by a question: to which nation do the deserts belong, if not the nation of Muhammad, and who is Kedar, if not the son of Isma‘il?"),
            .markdown("**Christians and Jews read it instead** as Jesus, to whom Matthew applies Isaiah 42:1–4 (Matthew 12:17–21), or, in the Jewish reading Rashi gives, as Israel, whom Isaiah elsewhere calls “my servant” (Isaiah 41:8); the ancient Aramaic Targum reads the servant as the Messiah."),
            .markdown("**Why the Muslim reading is argued:** the servant brings judgment and law to the Gentiles, to far coasts that wait for it; he does not fail until he has set judgment in the earth; and the song that follows rises from the villages of Kedar, the Arabian desert. The Prophet was sent to all people (Quran 34:28), brought a law, and did not die until the religion was complete (Quran 5:3), as the hadith says: Allah (Glorified and Exalted be He) would not take him until the crooked had been made straight through him. Proving Islam puts it as a challenge to the reader: go through Isaiah 42 verse by verse, and find the verse that does not fit him."),
        ]),
        ArticleSection("THE COMFORTER WHO SPEAKS WHAT HE HEARS", [
            .text("In the Gospel of John, at his last meal with his disciples, Jesus promises another who will come after him:"),
            .quote(text: "“And I will pray the Father, and he shall give you another Comforter, that he may abide with you for ever” … “Nevertheless I tell you the truth; It is expedient for you that I go away: for if I go not away, the Comforter will not come unto you; but if I depart, I will send him unto you.” (John 14:16, 16:7, KJV)", dimmed: true),
            .quote(text: "“Howbeit when he, the Spirit of truth, is come, he will guide you into all truth: for he shall not speak of himself; but whatsoever he shall hear, that shall he speak: and he will shew you things to come.” (John 16:13, KJV)", dimmed: true),
            .markdown("**Muslim scholars read this as** the Prophet (peace and blessings be upon him), in the light of the Quran’s report that ‘Isa (peace be upon him) gave glad tidings of a messenger to come after him whose name is Ahmad (Quran 61:6, quoted above). Ibn Taymiyyah discussed the passage at length, and argued from what the Comforter would do:"),
            .quote(text: "“These attributes and descriptions, which they received from the Messiah, do not fit something in the hearts of some people that no one sees and whose words no one hears; they fit only one whom people see and whose words they hear.” (Ibn Taymiyyah, al-Jawab as-Sahih)", arabic: "فهذه الصفات والنعوت التي تلقوها عن المسيح لا تنطبق على شيء في قلب بعض الناس، لا يراه أحد، ولا يسمع كلامه؛ وإنما تنطبق على من يراه الناس، ويسمعون كلامه", dimmed: true),
            .markdown("**Christians read it instead** as the Holy Spirit, whom John 14:26 names as the Comforter, and who, they hold, came upon the disciples at Pentecost (Acts 2)."),
            .markdown("**Why the Muslim reading is argued:** the Comforter is “another” one, a second like the first, and Jesus had been the first to his disciples. He will not come unless Jesus goes. He will abide “for ever”, which Ibn Taymiyyah took to mean a message and a law that remain. He “will reprove the world of sin” (John 16:8), a public mission, and “will shew you things to come”. And he “shall not speak of himself; but whatsoever he shall hear, that shall he speak”, which is how the Quran describes the Prophet:"),
            .versus(ArticleVersus.Side("John 16:13 (KJV)", caption: "“for he shall not speak of himself; but whatsoever he shall hear, that shall he speak”"), ArticleVersus.Side("Quran 53:3–4", arabic: "وَمَا يَنطِقُ عَنِ ٱلۡهَوَىٰٓ", caption: "“Nor does he speak from [his own] inclination. It is not but a revelation revealed”"), quranic: true),
            .callout("Some modern Muslim writers, such as David Benjamin Keldani in 1928, suggested that John’s Greek word was not **parakletos** but **periklytos**, “the praised one”, which would be close in meaning to Ahmad. No known Greek manuscript of John reads periklytos; all of them read parakletos. The suggestion has no support in the manuscripts, and this page does not rest on it. Ibn Taymiyyah did not rest on the word either: he noted that its meaning was disputed, and argued from the description. Proving Islam’s own rule applies here: “A weaker argument presented honestly is stronger than an overclaim that collapses under scrutiny.”", title: "Why Not Rest on the Greek Word", icon: "exclamationmark.triangle.fill"),
            .door(.article("ProvingJesusView")),
        ]),
        ArticleSection("THE STONE THE BUILDERS REJECTED", [
            .text("A psalm speaks of a stone that the builders threw aside:"),
            .quote(text: "“The stone which the builders refused is become the head stone of the corner. This is the LORD’s doing; it is marvellous in our eyes.” (Psalm 118:22–23, KJV)", dimmed: true),
            .text("In Matthew, Jesus quotes it at the end of a parable about tenants who beat and kill the servants sent to a vineyard, and then kill its owner’s son, and he adds a warning:"),
            .quote(text: "“Jesus saith unto them, Did ye never read in the scriptures, The stone which the builders rejected, the same is become the head of the corner: this is the Lord’s doing, and it is marvellous in our eyes? Therefore say I unto you, The kingdom of God shall be taken from you, and given to a nation bringing forth the fruits thereof.” (Matthew 21:42–43, KJV)", dimmed: true),
            .markdown("**Muslim writers read this as** the passing of the covenant from the Children of Israel to another nation: the rejected stone is the Prophet (peace and blessings be upon him), from the line of Isma‘il that the builders passed over, and the nation bearing the fruits is his community. The nineteenth-century scholar Rahmatullah al-Kairanawi argued this in Izhar al-Haqq, and Proving Islam sets it beside the Prophet’s own description of himself:"),
            .hadith("bukhari:3535", cite: "Sahih al-Bukhari 3535", arabic: 34...67, english: [4...70]),
            .markdown("**Christians and Jews read it instead** in their own ways: Christians as Jesus himself, the son of the parable, rejected by the leaders and raised up (Acts 4:11; 1 Peter 2:7), with the church as the new nation; Jews as Israel, humbled among the nations and then exalted, as Rashi explains the psalm, or as David, as the Aramaic Targum renders it."),
            .markdown("**Why the Muslim reading is argued:** one of al-Kairanawi’s points was the word “marvellous”. A cornerstone from the royal line of David, he argued, would be no marvel in Jewish eyes; a cornerstone from the despised children of Isma‘il would be. The Prophet’s parable has the same shape: a building almost finished, people walking around it and wondering at it, and one stone missing from its corner, which he said he was. This is the lightest of the five readings on this page, a meeting of images and a transfer of the kingdom rather than a prediction with names and places, and it is offered as exactly that."),
            .door(.article("ProvingContinuationView")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**If Muslims say the Bible was changed, why quote it?**"),
            .text("Because the Quran says it was changed, not that it was lost: a portion was forgotten and words were moved from their places (Quran 5:13), so true remnants remain beside what men added. The passages are also quoted to people who hold these books as scripture, on their own terms. And the case for the Prophet does not rest on them alone: they are one line of evidence beside the Quran itself, its preservation, and the prophecies that came true."),
            .markdown("**Doesn’t the New Testament apply these passages to Jesus?**"),
            .text("Some of them, yes: Acts applies Deuteronomy 18 to him (Acts 3:22), Matthew applies Isaiah 42 (Matthew 12:17–21), and Jesus applies the psalm of the stone (Matthew 21:42). Muslims honour Jesus as the Messiah and a messenger of Allah (Glorified and Exalted be He), so the question is not whether he was a true prophet but which figure the details describe. The Gospel of John itself keeps the Messiah and “that prophet” apart (John 1:19–21), and the last chapter of Deuteronomy says that no prophet like Musa arose in Israel."),
            .markdown("**Why doesn’t the Bible name Muhammad (peace and blessings be upon him)?**"),
            .text("Biblical prophecy usually describes rather than names; Christians read Isaiah 53 as a prophecy of Jesus, though his name is not in it. The Quran does not claim that the name Ahmad survives in the Gospel of John. It reports what ‘Isa said (Quran 61:6), and it says the Prophet is found written in what they have, which is a matter of description (Quran 7:157). Ahmad is one of the Prophet’s own names:"),
            .hadith("bukhari:3532", cite: "Sahih al-Bukhari 3532", arabic: 35...56, english: [4...51]),
            .markdown("**Isn’t this reading Islam back into the Bible?**"),
            .text("Every reader of prophecy reads it in the light of what he believes fulfilled it, and Christians do so with the Hebrew scriptures. The fair test is whether the details fit without strain. Some of these readings are strong, such as Deuteronomy 18 beside its closing chapter, and Isaiah 42 beside the hadith of ‘Abdullah ibn ‘Amr; others, like the rejected stone, are lighter. Together, and set beside the Quran’s open claim to the People of the Book, they show that the Muslim reading is not forced onto these texts."),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("The Quran told the Jews and Christians of its day that the Prophet (peace and blessings be upon him) was written in their books, and it called their scholars to witness. Classical Muslim scholars answered the claim text by text: the great nation promised to Isma‘il, the prophet like Musa from among Israel’s brethren, the servant of Isaiah 42 whose description a Companion knew from the earlier scripture, the Comforter who speaks only what he hears, and the stone the builders rejected. Each is a reading, and Christians and Jews read these passages otherwise. What Muslims point to is that the details fit him without strain, across the Torah, the Prophets and the Gospel, as the Quran said they would."),
        ]),
        ArticleSection("KEY TERMS", [
            .term("Bisharah", arabic: "بِشَارَة", meaning: "Glad tidings: the name Muslim scholars gave, in the plural **bisharat**, to the passages of earlier scripture that foretell the Prophet (peace and blessings be upon him). The Quran uses the same root when it describes ‘Isa as bringing good tidings of a messenger to come after him (Quran 61:6)."),
            .term("Faraqlit", arabic: "الفارقليط", meaning: "The Arabic form of the Greek **parakletos**, the “Comforter” of John 14 to 16, as Ibn Taymiyyah and other classical scholars wrote it. Its meaning was disputed, so the Muslim scholars argued from what the Comforter was said to do."),
            .term("Ahmad", arabic: "أَحْمَد", meaning: "From the root **ح-م-د**, praise: the most praiseworthy, or the one who praises most. It is the name in the glad tidings of ‘Isa (Quran 61:6), and one of the Prophet’s own names beside Muhammad, from the same root (Sahih al-Bukhari 3532)."),
            .term("Kedar", arabic: "قيدار", meaning: "A son of Isma‘il (Genesis 25:13), called Qaydar in Arabic. The Bible pairs his name with Arabia (Ezekiel 27:21), and Isaiah 42:10–11 calls the villages that Kedar inhabits to join a new song to God."),
        ]),
    ]
}

struct ProvingScriptureView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "ProvingScriptureView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Quran and Earlier Scripture")
        .selectableArticleList(article: "ProvingScriptureView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: the Quran calls itself a confirmation of the scriptures before it and a guardian over them, and it says those scriptures were changed by human hands. So where it tells stories that Jews and Christians also tell, it shares much with their accounts and differs at telling points: it confirms what remained true and judges between the versions, as six examples show."),
        ]),
        ArticleSection("CONFIRMER AND GUARDIAN", [
            .text("Allah (Glorified and Exalted be He) says of the Book He revealed to the Prophet (peace and blessings be upon him):"),
            .ayah("5:48", words: 0...11),
            .markdown("The word rendered above as “a criterion over it” is **muhaymin (مُهَيْمِن)**. Ibn Kathir gathers what was reported from Ibn ‘Abbas (may Allah be pleased with them) and the early scholars: trustworthy over every book before it, a witness over them, and a judge over them. He concluded that the word holds all three, so that the Quran is trustworthy, a witness, and a judge over every scripture that came before it. The early Makkan scholar Ibn Jurayj put the rule in one sentence:"),
            .quote(text: "“The Quran is trustworthy over the earlier books: whatever in them agrees with it is true, and whatever contradicts it is false.” (Ibn Jurayj, reported by Ibn Kathir in his tafsir of 5:48)", arabic: "القرآن أمين على الكتب المتقدمة، فما وافقه منها فهو حق، وما خالفه منها فهو باطل", dimmed: true),
            .text("The Quran also says what it does with the disputes of those who kept the earlier books. It does not simply repeat one side:"),
            .ayah("27:76"),
            .text("Ibn Kathir gives the clearest example, their disagreement over ‘Isa (peace be upon him):"),
            .quote(text: "“The Jews slandered him and the Christians went to excess, and the Quran came with the balanced, true and just word: that he is one of the servants of Allah, and of His prophets and noble messengers.” (Ibn Kathir, in his tafsir of 27:76)", arabic: "فاليهود افتروا، والنصارى غلوا، فجاء القرآن بالقول الوسط الحق العدل: أنه عبد من عباد الله وأنبيائه ورسله الكرام", dimmed: true),
            .door(.article("BooksView")),
        ]),
        ArticleSection("WHAT THE QURAN SAYS WAS CHANGED", [
            .text("The Quran is specific about what happened to the earlier books. Some people wrote scripture with their own hands and called it revelation:"),
            .ayah("2:79", words: 0...14),
            .text("And of those who broke the covenant, it says that they moved words from their places and forgot part of what they had been reminded of:"),
            .ayah("5:13", words: 7...15),
            .markdown("The scholars call this **tahrif (تَحرِيف)**, and they explained that it reaches both the wording and the meaning: changing a text, and bending a text that remains so that it says what it does not. Yet the same Quran says the Torah still held the judgment of Allah (Glorified and Exalted be He) in the Prophet’s own day (Quran 5:43), and it counts the Torah and the Injil among His revelations (Quran 3:3). So the earlier books, and the memory of the communities that kept them, hold truth and error side by side. The Prophet (peace and blessings be upon him) taught his Companions how to treat what they heard from them:"),
            .hadith("bukhari:4485", cite: "Sahih al-Bukhari 4485", arabic: 29...58, english: [0...52]),
            .checklist([
                "**Confirmed:** what the Quran and Sunnah testify to is true, whichever book it is found in.",
                "**Rejected:** what they contradict is false.",
                "**Left alone:** what they are silent about is neither believed nor denied; it may be told, but it is not taken as religion.",
            ], title: "Three Kinds of Report", icon: "books.vertical.fill"),
            .text("Ibn Kathir set out these three kinds in the introduction to his tafsir, following his teacher Ibn Taymiyyah, and added that such reports are cited to support a point, never to establish one. The sections below take six places where the Quran and Jewish or Christian writings tell the same story, and show what the Quran confirms and what it decides."),
            .callout("Critics read a shared detail as borrowing. But some of the writings below were compiled around the time of the Quran or after it, and their dates are given where they matter, so that the reader can weigh the direction of any influence. The point is not that no parallel should exist, since the Quran says it confirms what came before it. It is that in each case the Quran **takes a side**, where a borrower would simply copy.", title: "A Note on Dates", icon: "hourglass"),
        ]),
        ArticleSection("THE RAVEN AND THE FIRST BURIAL", [
            .text("Allah (Glorified and Exalted be He) commands the Prophet (peace and blessings be upon him) to tell the true story of Adam’s two sons (Quran 5:27). After the killing, the Quran tells of a ghurab, a crow or raven:"),
            .ayah("5:31"),
            .markdown("Genesis 4 tells of Cain and Abel, and of the voice of Abel’s blood crying from the ground, but it says nothing of a bird, or of any burial. **A raven does appear in later Jewish writings.** Pirkei de-Rabbi Eliezer (chapter 21) says that Adam and Eve sat weeping over Abel, not knowing what to do with him, until a raven buried a dead companion before their eyes, and Adam did the same. The Midrash Tanhuma (Bereshit 10) has two birds instead, one killing the other and burying it, and there it is Cain who learns."),
            .markdown("**What the Quran confirms and what it decides:** a bird did show the first burial. But in the Quran the bird is sent by Allah to the killer himself, and the lesson is his own shame at being outdone by a crow, which leaves him full of regret. The dates matter here. Pirkei de-Rabbi Eliezer was compiled in the eighth century, after the Quran, and it even gives the wives of Isma‘il the names ‘A’ishah and Fatimah; the date of the Tanhuma is uncertain. Neither can be shown to be the Quran’s source, and the two Jewish tellings do not agree with each other about who learned from the bird."),
        ]),
        ArticleSection("WE HEAR AND WE DISOBEY", [
            .text("At Sinai the Children of Israel asked Musa (peace be upon him) to hear God’s words on their behalf, and promised to obey them. Deuteronomy records what they said:"),
            .quote(text: "“Go thou near, and hear all that the LORD our God shall say: and speak thou unto us all that the LORD our God shall speak unto thee; and we will hear it, and do it.” (Deuteronomy 5:27, KJV)", dimmed: true),
            .text("Allah (Glorified and Exalted be He) recalls the same covenant in the Quran, and what they said:"),
            .ayah("2:93", words: 0...13),
            .markdown("In Hebrew (Deuteronomy 5:24 in the Hebrew numbering) the covenant words are **ve-shama‘nu ve-‘asinu**, “and we will hear and we will do”. The Quran’s **sami‘na wa-‘asayna**, “we hear and we disobey”, keeps their sound almost exactly and reverses their meaning. The orientalist Hartwig Hirschfeld was the first Western scholar to point this out, in 1902, and Reuven Firestone argued in 1997 that the play on words was made by some of the Jews of Madinah themselves. The Quran says as much in another place, where it describes some of them saying sami‘na wa-‘asayna with a twist of the tongue:"),
            .ayah("4:46", words: 0...15),
            .markdown("**What the Quran confirms and what it decides:** the covenant is confirmed, with its command to hold firmly to the revelation and to listen; what the Quran adds is the verdict on what followed, and in the same verse it names the calf. The Torah carries that verdict too. Right after the promise, God says of the people, “O that there were such an heart in them, that they would fear me, and keep all my commandments always” (Deuteronomy 5:29), and Moses later tells them, “Ye have been rebellious against the LORD from the day that I knew you” (Deuteronomy 9:24). The Quran confirms what their own book records."),
        ]),
        ArticleSection("THE MOUNTAIN RAISED ABOVE THEM", [
            .text("The Quran says, in Surat al-A‘raf below and twice in Surat al-Baqarah (Quran 2:63, 2:93), that when the covenant was taken, the mountain was raised over the Children of Israel:"),
            .ayah("7:171", words: 1...10),
            .text("Exodus describes the people at Sinai this way:"),
            .quote(text: "“And Moses brought forth the people out of the camp to meet with God; and they stood at the nether part of the mount.” (Exodus 19:17, KJV)", dimmed: true),
            .markdown("The Hebrew behind “at the nether part of the mount” can also be read “beneath the mountain”, and the Babylonian Talmud reads it that way. In **Shabbat 88a**, Rav Avdimi bar Hama bar Hasa says the verse teaches that God held the mountain over them like an upturned tub, and told them that if they accepted the Torah, well and good, and if not, there would be their burial. The Talmud then records the objection that an agreement made under such pressure would not bind, and answers that the people accepted the Torah again, willingly, in the days of Ahasuerus."),
            .markdown("**What the Quran confirms and what it decides:** the raised mountain is confirmed, and Ibn Kathir reports from Ibn ‘Abbas (may Allah be pleased with them) that it was raised when they refused to obey. The Talmud, compiled in the centuries before Islam, is a natural place for such a memory to survive. But the Quran does not treat the covenant as weakened by the mountain. It came with a command to hold firmly to what they had been given and to remember what was in it, and their turning away afterwards is counted against them (Quran 2:64)."),
        ]),
        ArticleSection("WHOEVER KILLS A SOUL", [
            .text("Right after the story of Adam’s two sons, the Quran says:"),
            .ayah("5:32", words: 0...26),
            .markdown("The Quran itself says this was **decreed for the Children of Israel**, so it is no surprise that their tradition keeps it. The Mishnah, the code of Jewish law compiled around 200 CE, has it in **Sanhedrin 4:5**, in the warning given to witnesses in a trial for life. It too ties the teaching to Cain: God said to him “the voice of thy brother’s blood” (Genesis 4:10), and the Hebrew word for blood there is plural, which the Mishnah takes to mean Abel’s blood and the blood of all the descendants he would have had. Then it states the principle: Adam was created alone to teach that whoever destroys a single soul is counted as though he had destroyed a whole world, and whoever sustains a single soul as though he had sustained a whole world."),
            .markdown("**What the Quran confirms and what it decides:** both texts set the teaching beside the first murder, and the Quran names its origin itself, as a decree given to the Children of Israel. The copies of the Mishnah differ on its scope: the text printed with the Jerusalem Talmud speaks of a single soul, while the standard printed text says a single soul “of Israel”. The Quran’s wording is universal, a soul and all mankind, and it states the limits of justice: a life taken in lawful retribution, or as the penalty for spreading corruption in the land, is not what it condemns."),
        ]),
        ArticleSection("MARYAM AND THE CHILD IN THE CRADLE", [
            .text("Luke’s Gospel and Surat Maryam tell the annunciation in the same order. An angel comes to Maryam (peace be upon her); she is troubled; he announces a son; she asks how this can be, when no man has touched her; he answers that it is God’s doing. Luke names the angel Gabriel. In the Quran, Allah (Glorified and Exalted be He) calls him ruhana, Our Spirit, which the translation below renders as Our Angel, and the commentators identify him as Jibril:"),
            .ayah("19:16-21"),
            .quote(text: "“And the angel said unto her, Fear not, Mary: for thou hast found favour with God. And, behold, thou shalt conceive in thy womb, and bring forth a son, and shalt call his name JESUS.” … “Then said Mary unto the angel, How shall this be, seeing I know not a man?” (Luke 1:30–31, 34, KJV)", dimmed: true),
            .markdown("**What the Quran confirms:** the virgin birth, the angel’s visit, Maryam’s question, and the answer that nothing is hard for God. Muslims and Christians share all of this, and the Quran honours Maryam above the women of the worlds (Quran 3:42)."),
            .markdown("**What it decides:** in Luke the angel goes on to say that the child “shall be called the Son of the Highest” and “the Son of God” (Luke 1:32, 35). The Quran calls him a sign and a mercy (Quran 19:21), and a few verses later denies that Allah takes a son (Quran 19:35). The four Gospels say nothing of the infant ‘Isa (peace be upon him) speaking, but a later Christian infancy gospel, known today in Arabic and thought to go back to a Syriac original of perhaps the fifth or sixth century, has him speak from the cradle. The Quran also has him speak, and the two give him opposite words:"),
            .versus(ArticleVersus.Side("Arabic Infancy Gospel 1", caption: "“I am Jesus, the Son of God, the Logos, whom thou hast brought forth”"), ArticleVersus.Side("Quran 19:30", arabic: "إِنِّي عَبۡدُ ٱللَّهِ", caption: "“Indeed, I am the servant of Allah.”"), quranic: true),
            .ayah("19:29-30"),
            .text("This is what Ibn Kathir meant by the Quran’s balanced word about ‘Isa. The scene that Christians remember is kept, and the child’s first words tell the truth about him."),
            .door(.article("ProvingJesusView")),
        ]),
        ArticleSection("THE GUESTS WHO DID NOT EAT", [
            .text("Genesis and the Quran both tell of the guests who came to Ibrahim (peace be upon him) with news of a son, and of the calf he prepared for them. Genesis says the meal was eaten:"),
            .quote(text: "“And he took butter, and milk, and the calf which he had dressed, and set it before them; and he stood by them under the tree, and they did eat.” (Genesis 18:8, KJV)", dimmed: true),
            .text("The Quran tells it otherwise:"),
            .ayah("11:69-70"),
            .versus(ArticleVersus.Side("Genesis 18:8 (KJV)", caption: "“and he stood by them under the tree, and they did eat”"), ArticleVersus.Side("Quran 11:70", arabic: "أَيۡدِيَهُمۡ لَا تَصِلُ إِلَيۡهِ", caption: "“their hands not reaching for it”"), quranic: true),
            .markdown("**Jewish tradition** found the plain words of Genesis hard to accept. The Babylonian Talmud (**Bava Metzia 86b**) asks whether it can enter the mind that angels really ate, and answers that they only appeared to eat and drink; the midrash Genesis Rabbah (48:14) says the same, adding that the morsels disappeared one by one. Elsewhere the Bible itself has an angel refuse a meal: “Though thou detain me, I will not eat of thy bread” (Judges 13:16)."),
            .markdown("**What the Quran confirms and what it decides:** the guests were angels, and angels do not eat, as the rabbis also concluded. But the Quran does not say they seemed to eat. It says their hands never went to the food, and that this is what alarmed Ibrahim, until they told him not to fear and gave him the good news. In Surat adh-Dhariyat he sets the calf near them and asks why they do not eat (Quran 51:26–28). The Quran agrees with the rabbis’ conclusion, not with their way of reconciling it with Genesis."),
            .door(.article("AngelsView")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**Doesn’t a shared detail show borrowing?**"),
            .text("Not by itself. The Quran says it confirms what came before it, so shared material is what it leads us to expect: the Children of Israel kept true memories beside their additions, and the Quran confirms the first. What borrowing would show is a text that copies its sources, errors included. In each case above the Quran takes a side: the bird is sent to the killer, the covenant under the mountain stays binding, the saying about one soul is universal, the child in the cradle calls himself a servant, and the angels’ hands never touch the food. The opponents of the Prophet (peace and blessings be upon him) in Makkah, who wanted to find him a human teacher, could only point to a man whose tongue was not Arabic (Quran 16:103)."),
            .door(.article("ProvingSourcesView")),
            .markdown("**Some of these writings are later than the Quran. Doesn’t that cut both ways?**"),
            .text("It does, and it should be said plainly. The Mishnah (around 200 CE) and the Babylonian Talmud, compiled in the centuries before Islam, are older than the Quran; Pirkei de-Rabbi Eliezer is later; and the dates of the Tanhuma and of the Arabic infancy gospel are uncertain. So the argument is not that no Jewish or Christian writing shares anything with the Quran. It is that where they overlap, the Quran is not a copy: it agrees with the older sources where they kept something true, and parts from them where they did not."),
            .markdown("**Does the Quran say the whole Bible is corrupted?**"),
            .text("No. It names particular kinds of change: writing by hand and calling it scripture, moving words from their places, and forgetting a portion (Quran 2:79, 5:13). It still calls the Torah and the Injil revelation from Allah (Glorified and Exalted be He), says the Torah held His judgment (Quran 5:43), and tells Muslims to believe in what was revealed before (Quran 2:136). A Muslim therefore expects to find truth in the Bible and in the traditions of the Jews and Christians, and uses the Quran to tell it apart from what was added."),
            .markdown("**Why would the Quran confirm a detail found in the Talmud?**"),
            .text("Because the Talmud and the midrash, though they are not revelation, preserve memories of the Children of Israel, and some of those memories are true. The Prophet allowed the stories of the Children of Israel to be told (Sahih al-Bukhari 3461), and forbade believing or denying them blindly (Sahih al-Bukhari 4485, quoted above). When the Quran includes such a detail, it is the Quran that confirms the detail, not the Talmud that confirms the Quran."),
            .door(.article("ProvingBibleView")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("The Quran presents itself as the confirmer of earlier scripture and its guardian, the book that settles most of what the Children of Israel differed over, and its retellings bear that out. It shares the raven, the covenant words, the raised mountain, the saying about one soul, the annunciation to Maryam and the angels at Ibrahim’s table with Jewish and Christian writings, and at each point it keeps what is true and parts from what is not: the lesson goes to the killer, the covenant stays binding, the saying about one soul reaches all mankind, the child in the cradle calls himself a servant and not a son, and the angels leave the food untouched. That is how a guardian over scripture behaves, not how a borrower does."),
        ]),
        ArticleSection("KEY TERMS", [
            .term("Muhaymin", arabic: "مُهَيْمِن", meaning: "Guardian: the Quran’s word for its place over earlier scripture (Quran 5:48). The early scholars explained it as trustworthy over the earlier books, a witness over them and a judge over them, and Ibn Kathir said it holds all three. **Al-Muhaymin** is also one of the names of Allah (Quran 59:23)."),
            .term("Tahrif", arabic: "تَحْرِيف", meaning: "From the root **ح-ر-ف**, to turn something aside: moving words from their places (Quran 5:13), whether by changing a text or by bending its meaning."),
            .term("Isra’iliyyat", arabic: "الإِسرَائِيلِيَّات", meaning: "Reports taken from Jewish and Christian sources into the books of tafsir and history. The scholars sorted them into three kinds: confirmed by the Quran and Sunnah, contradicted by them, or neither, to be told but neither believed nor denied."),
            .term("Talmud", arabic: "التَّلمُود", meaning: "The Mishnah, the code of Jewish oral law compiled around 200 CE, with the rabbis’ long discussion of it; the Babylonian Talmud was compiled in the centuries before Islam. **Midrash** is the rabbis’ interpretation of scripture, gathered in collections such as Genesis Rabbah. For Muslims these are the words of scholars, not revelation."),
        ]),
    ]
}

struct ProvingEthicsView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "ProvingEthicsView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Justice Beyond the Tribe")
        .selectableArticleList(article: "ProvingEthicsView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: a tribal leader of seventh-century Arabia would be expected to leave tribal ethics behind him: loyalty to kin whether right or wrong, blood feuds, and one law for the strong and another for the weak. The Quran and the sound Sunnah command the opposite: testimony against yourself and your family, justice to people you hate, no inherited guilt, one law for the noble and the poor, and a mercy that reaches even animals."),
        ]),
        ArticleSection("THE EXPECTED FINGERPRINT", [
            .text("Proving Islam applies its human fingerprint test to ethics. If Muhammad (peace and blessings be upon him) were only a seventh-century tribal leader building his own power, we would expect the moral code of his world: loyalty to family and clan above truth, revenge as a duty of honour, protection for the strong, and justice measured by blood. Arabia before Islam had a proverb for it: help your brother, whether he does wrong or is wronged. Ibn Hajar records, from al-Mufaddal’s al-Fakhir, that the first man to say it, Jundub ibn al-‘Anbar, meant it literally, as the tribal loyalty the Arabs lived by. The Prophet repeated the old proverb and turned it inside out:"),
            .hadith("bukhari:2444", cite: "Sahih al-Bukhari 2444", arabic: 22...42, english: [4...55]),
            .text("The words of the tribe stayed and their meaning changed: loyalty to your brother now means stopping him from doing wrong. The Prophet also warned that whoever fights under a blind banner, angry for his clan, calling to his clan, or supporting his clan, and is killed, dies the death of the age of ignorance (Sahih Muslim 1848). The rest of this page follows the same reversal through the Quran and the sound Sunnah."),
            .door(.article("ProvingFingerprintView")),
        ]),
        ArticleSection("AGAINST YOURSELF AND YOUR KIN", [
            .text("The first loyalty of a tribal code is to your own blood. The Quran commands the believers to stand firm for justice and to testify for Allah (Glorified and Exalted be He) even when the truth falls against themselves, their parents, and their relatives:"),
            .ayah("4:135", words: 1...14),
            .text("It repeats the command among the commandments of Surah al-An‘am, beside honest weights and measures:"),
            .ayah("6:152", words: 20...26),
            .callout("In 2012 Harvard Law School opened an exhibit called Words of Justice on the walls outside Milstein East in its Wasserstein Hall. Faculty, staff, and students submitted about 350 quotations on law and justice, and 33 were chosen and set on the walls, spanning from 600 BCE to the present; the Magna Carta, Blackstone, and Nelson Mandela are among them. Quran 4:135 is one of them too, in Yusuf Ali’s translation. Harvard did not rank the Quran as the best book on justice, as viral posts claim, and the verse is not on the university’s main gate. What is true is plainer and still striking: a law school community, gathering words on justice from twenty-five centuries, included this verse.", title: "Words of Justice at Harvard", icon: "building.columns.fill"),
            .text("The Prophet (peace and blessings be upon him) held his own household to the rule. A woman of Makhzum, one of the noblest clans of Quraysh, had stolen, and her people, unwilling to see her punished, persuaded Usamah ibn Zayd (may Allah be pleased with him), whom the Prophet loved, to intercede for her. The Prophet rebuked him for interceding in one of the limits set by Allah, then stood and addressed the people:"),
            .hadith("bukhari:3475", cite: "Sahih al-Bukhari 3475", arabic: 67...100, english: [74...131]),
            .text("He named his own daughter, the person dearest to him, as the test case. The rule reached his own judgement too. When a household of Madinah, Banu Ubayriq, broke into a neighbour’s storeroom and took his food and weapons, and its spokesmen persuaded the Prophet that the accusation against them was unproven, verses came down exposing the thieves, telling the Prophet not to plead for the treacherous and to seek Allah’s forgiveness for what he had said to their accuser (Jami` at-Tirmidhi 3036, graded hasan by al-Albani):"),
            .ayah("4:105"),
        ]),
        ArticleSection("JUSTICE TO THOSE YOU HATE", [
            .text("Proving Islam calls the next command arguably stronger than the first. It is one thing to testify against your family and another to be just to people you hate and who hate you:"),
            .ayah("5:8", words: 8...18),
            .text("The hatred in view was not abstract. A few verses earlier the same surah names the people who had barred the believers from the Sacred Mosque, and forbids hatred of them from leading the believers into transgression (Quran 5:2). Justice is owed even to them. To people of other faiths who do not fight the Muslims or drive them from their homes, more than justice is owed:"),
            .ayah("60:8"),
            .text("The Prophet (peace and blessings be upon him) put the same protection into law: whoever kills a person living under a treaty with the Muslims will not smell the fragrance of Paradise (Sahih al-Bukhari 3166). In his own affairs he dealt with the Jews of Madinah as ordinary partners in trade, and he died with his armour pledged to a Jewish man for barley (Sahih al-Bukhari 2916)."),
        ]),
        ArticleSection("NO FEUDS AND NO INHERITED GUILT", [
            .text("Blood feuds were the backbone of tribal Arabia: a killing was owed to the victim’s clan, and any man of the killer’s clan could be made to pay for it. At the Farewell Pilgrimage the Prophet (peace and blessings be upon him) dismantled that system, and he began with the claims of his own family:"),
            .hadith("muslim:1218a", cite: "Sahih Muslim 1218", arabic: 783...841, english: [1277...1359, 1369...1388]),
            .text("The first blood claim he cancelled was owed for a child of his own house, the son of his cousin Rabi‘ah ibn al-Harith (may Allah be pleased with him), and the first interest he cancelled was owed to his own uncle, al-‘Abbas (may Allah be pleased with him); the whole of the pre-Islamic interest was cancelled with it. In the same pilgrimage he laid down the principle that ends collective punishment:"),
            .hadith("tirmidhi:2159", cite: "Jami` at-Tirmidhi 2159; graded sahih by al-Albani", arabic: 55...71, english: [46...79]),
            .text("The Quran had already made it law: no bearer of burdens bears the burden of another (Quran 6:164; 17:15). Pride of lineage, the other pillar of tribal honour, was cancelled in the same way:"),
            .hadith("abudawud:5116", cite: "Sunan Abi Dawud 5116; graded hasan by al-Albani", arabic: 44...64, english: [4...41]),
            .ayah("49:13"),
            .text("Musnad Ahmad (23489) reports from a Companion who heard the Prophet in the middle of the days of Tashriq, during that pilgrimage, that he told the people their Lord is one and their father is one, and that no Arab is better than a non-Arab, nor a non-Arab than an Arab, nor a red (light-skinned) man than a black man, nor a black man than a red one, except by taqwa. Shu‘ayb al-Arna’ut graded its chain sahih."),
            .door(.article("FarewellView")),
        ]),
        ArticleSection("A COURT WITH PRINCIPLES", [
            .text("Tribal justice favoured whoever had the larger clan behind him. The law the Prophet (peace and blessings be upon him) taught begins from the other end, with rules that shield the weaker party in a dispute and bind the powerful. Several of them are familiar from modern legal systems:"),
            .checklist([
                "**The claimant must prove:** a claim alone takes no one’s property or life, and the one who denies it takes an oath (Sahih Muslim 1711; Jami` at-Tirmidhi 1341).",
                "**Guilt is personal:** no one is punished for a relative’s crime (Quran 6:164; Jami` at-Tirmidhi 2159).",
                "**No retroactive guilt:** what was done before a prohibition came down is not held against the doer (Quran 2:275; 4:22).",
                "**One law for all:** the noble and the weak face the same penalty (Sahih al-Bukhari 3475).",
                "**Agreements bind:** the believers are commanded to fulfil their contracts (Quran 5:1).",
                "**Harm is forbidden:** neither harming nor answering harm with harm (Sunan Ibn Majah 2340).",
            ], title: "Principles of the Court", icon: "scalemass.fill"),
            .hadith("muslim:1711a", cite: "Sahih Muslim 1711", arabic: 30...43, english: [0...27]),
            .text("The fuller wording, that proof is on the claimant and the oath on the one who denies, is narrated by al-Bayhaqi, and an-Nawawi graded it hasan and placed it in his Forty (no. 33); at-Tirmidhi recorded that the scholars among the Companions and those after them acted on it (Jami` at-Tirmidhi 1342). It would overstate the case to say that Islam invented these ideas: Roman law also placed the burden of proof on the one who asserts, not on the one who denies (Digest 22.3.2). The point is narrower and stronger. An unlettered man, among a people with no written law, laid down rules that shield the weak party in a dispute from the strong one, and he applied them to his own family first."),
        ]),
        ArticleSection("NO HARM AND NO RETURNING HARM", [
            .text("One ruling of the Prophet (peace and blessings be upon him) became a foundation stone of Islamic law:"),
            .hadith("ibnmajah:2340", cite: "Sunan Ibn Majah 2340; graded sahih by al-Albani", arabic: 37...40, english: [0...7]),
            .text("Each of its chains has some weakness, but they strengthen one another: an-Nawawi graded it hasan in his Forty (no. 32), and Shu‘ayb al-Arna’ut graded it sahih through its supporting routes. The jurists built a body of law on it. As-Suyuti counted “harm is to be removed” among the five great maxims to which the questions of fiqh return, and the jurists applied it to questions of neighbours, property, trade, and public space."),
            .text("Proving Islam compares this hadith with the harm principle of John Stuart Mill, published in On Liberty in 1859:"),
            .quote(text: "“The only purpose for which power can be rightfully exercised over any member of a civilised community, against his will, is to prevent harm to others. His own good, either physical or moral, is not a sufficient warrant.” (John Stuart Mill, On Liberty, 1859)", dimmed: true),
            .callout("The comparison needs care, because the two are not the same claim. Mill’s principle limits what society may do to a person: it may restrain him only to protect others, never for his own good. The hadith forbids causing harm and answering harm with more harm, and it obliges the removal of harm; it does not say that preventing harm is the only thing law may do. Islamic law also forbids things for a person’s own good, wine among them, which Mill’s principle would not allow. What the two share is the recognition that harm to others is a central measure of wrongdoing and a first concern of law, and the Prophet’s ruling made that a working rule of law some twelve centuries before Mill wrote.", title: "Two Different Claims", icon: "exclamationmark.triangle.fill"),
            .door(.article("MadhabView")),
        ]),
        ArticleSection("THE CONSTITUTION OF MADINAH", [
            .text("When the Prophet (peace and blessings be upon him) arrived in Madinah, the city was divided between two Arab tribes, al-Aws and al-Khazraj, with a long history of war between them, and several Jewish tribes lived alongside them. From this period the sirah preserves a written agreement, known in English as the Constitution (or Charter) of Madinah; its own text calls itself a kitab, a document. It survives in the biography of Ibn Ishaq (d. 767 CE) and, in a second version, in the Kitab al-Amwal of Abu ‘Ubayd (d. 838 CE)."),
            .text("It should be presented the way historians present it. As a complete text it has no single sound chain of narrators, and scholars debate its form: R. B. Serjeant argued that it joins eight separate documents from different years, while others read it as one, and Ovamir Anjum notes that its first half, the pact among the believers, is better attested than the later clauses on the Jewish tribes. Most historians nonetheless accept that it preserves genuine agreements from the Prophet’s first years in Madinah, and some of its provisions are confirmed by sound hadith: Sahih Muslim (1507) reports that the Prophet wrote down for every clan its share of blood money, as the document does."),
            .text("Read with that caution, its provisions are remarkable for their time and place. It made the believers of every tribe, the emigrants and the helpers, one community, and bound them to stand together against any of their own who did wrong, even the son of one of them. It named the Jewish clans a community alongside the believers, the Jews with their religion and the Muslims with theirs, sharing the costs of defence. And it referred disputes to Allah (Glorified and Exalted be He) and to Muhammad rather than to the sword. Muhammad Hamidullah called it the first written constitution in the world; other historians find the word misleading for what was really a covenant. Proving Islam describes it as one of the earliest known written documents governing a political community of more than one religion, while noting that scholars debate its exact form."),
        ]),
        ArticleSection("MERCY THAT REACHES ANIMALS", [
            .text("A tribal code has no reason to care about a stray animal. The Prophet (peace and blessings be upon him) taught that cruelty to a cat could take a person to the Fire:"),
            .hadith("bukhari:3318", cite: "Sahih al-Bukhari 3318", arabic: 31...44, english: [4...33]),
            .text("And he taught that kindness to a thirsty dog could earn the forgiveness of Allah (Glorified and Exalted be He):"),
            .hadith("bukhari:2363", cite: "Sahih al-Bukhari 2363", arabic: 29...87, english: [4...116]),
            .text("The Quran gives the reason: animals are communities like ours, known to their Lord:"),
            .ayah("6:38"),
            .text("Here too the claim is not that no one before Islam was ever kind to an animal. It is that the moral horizon of this revelation reaches past the tribe, and past humanity itself, in the words of a man whose people measured right and wrong by blood."),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**Doesn’t a law with fixed punishments contradict this picture of justice?**"),
            .text("This page’s point is equality before the law, and the woman of Makhzum shows it: the penalty applied to the noble exactly as to the weak. The fixed penalties themselves came with strict conditions. The hand is not cut for theft of less than a quarter of a dinar (Sahih al-Bukhari 6789), and when a man came to confess a crime that carried a fixed penalty, the Prophet (peace and blessings be upon him) turned his face away until the man had repeated it four times, and then asked him whether he was mad (Sahih al-Bukhari 6815). A law that makes the judge reluctant and the proof demanding is not the law of a tribe settling scores."),
            .markdown("**Did the Prophet favour his own family in anything?**"),
            .text("The record runs the other way. He barred his own clan from the charity he collected (Sahih Muslim 1072), cancelled his own family’s blood claims and interest first, and named his daughter when he set the law on theft. At the very start of his mission he told his closest relatives that their kinship to him would not save them:"),
            .hadith("bukhari:4771", cite: "Sahih al-Bukhari 4771", arabic: 62...98, english: [54...112]),
            .markdown("**Didn’t Islam simply replace the old tribes with a bigger one?**"),
            .text("A bigger tribe would keep the tribal rule, loyalty to our side right or wrong. The Quran refuses it. When a household counted among the Muslims stole and blamed another man, the revelation exposed them (Quran 4:105); a Muslim who oppresses is to be stopped by his own brothers (Sahih al-Bukhari 2444); justice is owed to enemies (Quran 5:8); and the blood of a non-Muslim under treaty is protected by the warning that his killer will not smell the fragrance of Paradise (Sahih al-Bukhari 3166). The believers are bound by a law above them, not merely to one another."),
            .markdown("**Haven’t Muslims often fallen short of these ideals?**"),
            .text("They have, and the Quran and Sunnah are the first to condemn it; the warning about dying for tribal zeal was addressed to Muslims (Sahih Muslim 1848). The argument of this chapter is about the source, not the record of every follower: a moral code this far above the tribal instincts of its time and place is hard to explain as the invention of a tribal leader."),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("A seventh-century tribal leader inventing a moral code would have written tribal ethics. The Quran commands testimony against yourself and your parents, justice to people you hate, and fairness to those of other faiths; the Prophet (peace and blessings be upon him) cancelled his own family’s blood claims first, named his own daughter before the law, ended inherited guilt and pride of lineage, placed the burden of proof on the claimant, forbade harm, and taught mercy even to animals. Honest comparison with Roman law, with Mill, and with the debated Constitution of Madinah does not shrink the point. It sharpens it: the fingerprint of the tribe is missing where we would most expect to find it."),
        ]),
        ArticleSection("KEY TERMS", [
            .term("‘Adl", arabic: "عَدل", meaning: "From the root **ع-د-ل**, to make level and balanced: justice, giving each person what is due, even to those one hates (Quran 5:8)."),
            .term("Qist", arabic: "قِسط", meaning: "From the root **ق-س-ط**, a fair share: equity and fair dealing, the word used in Quran 4:135 for the justice the believers must stand firm upon."),
            .term("‘Asabiyyah", arabic: "عَصَبِيَّة", meaning: "From the root **ع-ص-ب**, to bind tightly: blind partisanship for one’s clan, right or wrong, which the Prophet (peace and blessings be upon him) condemned (Sahih Muslim 1848)."),
            .term("Darar", arabic: "ضَرَر", meaning: "From the root **ض-ر-ر**, harm and loss: the harm forbidden in the hadith of la darar wa la dirar, and the root of the jurists’ maxim that harm is to be removed."),
            .term("Bayyinah", arabic: "بَيِّنَة", meaning: "From the root **ب-ي-ن**, to be clear: clear proof, which Islamic law places on the one who makes a claim."),
        ]),
    ]
}

struct ProvingJesusView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "ProvingJesusView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Jesus in the Gospels")
        .selectableArticleList(article: "ProvingJesusView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: Islam does not lower Jesus (peace be upon him). It honours him as the Messiah, a word from Allah (Glorified and Exalted be He), born of a virgin and given great signs, and it denies only that he is God. Read on their own terms, the Gospels describe the same man: he prays to God, knows what God tells him, acts by an authority he was given, is hailed as a prophet by those who saw his miracles, and names as the first commandment “The Lord our God is one Lord”."),
        ]),
        ArticleSection("WHAT MUSLIMS BELIEVE ABOUT JESUS", [
            .markdown("Proving Islam puts the Muslim position in two short sentences: Islam does not diminish Jesus; it restores him. No one is a Muslim without believing in **Isa ibn Maryam (عِيسَى ابنُ مَريَم)**, Jesus son of Mary (peace be upon him), and in what Allah (Glorified and Exalted be He) says of him, which honours him more fully than many Christians expect."),
            .checklist([
                "**The Messiah.** The Quran gives him the title al-Masih, the anointed one (Quran 3:45, 4:171).",
                "**A word from Allah and a spirit from Him.** He was brought into being by Allah’s command “Be,” without a father (Quran 3:47, 4:171).",
                "**Born of a virgin.** Surah Maryam, named after his mother, tells of the annunciation and the birth (Quran 19:16-22).",
                "**He spoke in the cradle,** a sign the four Gospels do not record, and his first words named him Allah’s servant and prophet (Quran 19:30).",
                "**Miracles by Allah’s permission.** A bird shaped from clay, the blind and the leper healed, the dead brought forth (Quran 3:49, 5:110).",
                "**His mother chosen** and purified above the women of the worlds (Quran 3:42).",
                "**Raised alive, and returning** before the Hour to judge with justice (Quran 4:157-158; Sahih Muslim 155).",
            ], title: "What the Quran Affirms of Jesus", icon: "checkmark.seal.fill"),
            .ayah("3:45", words: 7...13),
            .text("His birth is told as a sign in itself, with Maryam’s astonishment and the angel’s answer that it is easy for Allah:"),
            .ayah("19:16-22", words: 38...63),
            .text("And the Quran credits every one of his miracles to the One who gave it. On the Day of Judgement Allah (Glorified and Exalted be He) will remind him of what He did through him, repeating after each sign that it was by His permission:"),
            .ayah("5:110", words: 26...45),
            .text("Nor is his story finished. The Prophet (peace and blessings be upon him) said:"),
            .hadith("muslim:155a", cite: "Sahih Muslim 155", arabic: 33...53, english: [0...30]),
            .text("When he comes, he will come as one of this Ummah, not as its lord. He will even decline to lead its prayer:"),
            .hadith("muslim:156", cite: "Sahih Muslim 156", arabic: 57...83, english: [30...73]),
            .text("So the question between Muslims and Christians has never been whether to love Jesus. It is what he was, and on that the Gospels themselves have a great deal to say."),
            .text("Muslims do not take the four Gospels to be the Injil, the revelation Allah gave to Jesus. They are accounts about him, written in Greek by later hands: Mark, which most scholars hold to be the earliest, around 70 CE, and John in the 90s. But they are the testimony Christians accept. Ibn Taymiyyah (may Allah have mercy on him) argued from their own wording throughout al-Jawab as-Sahih li man Baddala Din al-Masih, and so does this chapter, quoting each verse exactly in the King James Version and saying so where Muslims and Christians read a verse differently."),
            .door(.article("ProphetIsaView")),
        ]),
        ArticleSection("HE PRAYED TO GOD", [
            .text("The first pattern is the plainest. Jesus (peace be upon him) prays, and he prays to Someone other than himself: he “continued all night in prayer to God” (Luke 6:12). On the night of his arrest, Matthew says, he fell on his face and prayed:"),
            .quote(text: "“O my Father, if it be possible, let this cup pass from me: nevertheless not as I will, but as thou wilt.” (Matthew 26:39, KJV)", dimmed: true),
            .text("Two wills are named in that sentence, his and God’s, and he yields his own to God’s. That is the very meaning of islam: a servant’s will surrendered to his Lord. In the longest prayer the Gospels give him, he says what eternal life is:"),
            .quote(text: "“And this is life eternal, that they might know thee the only true God, and Jesus Christ, whom thou hast sent.” (John 17:3, KJV)", dimmed: true),
            .text("The only true God is the one he is speaking to; he himself is the one who was sent. Muslims hear in the verse the shape of their own testimony of faith: one true God, and a messenger He sent. Ibn Taymiyyah quotes it in al-Jawab as-Sahih as the Gospel’s own witness, and a Muslim could say it without changing a word."),
        ]),
        ArticleSection("WHAT HE DID NOT KNOW", [
            .text("The second pattern is knowledge. Speaking of the Last Day, Jesus (peace be upon him) drew a line between himself and God:"),
            .quote(text: "“But of that day and that hour knoweth no man, no, not the angels which are in heaven, neither the Son, but the Father.” (Mark 13:32, KJV)", dimmed: true),
            .checklist([
                "**“Who touched my clothes?”** When a woman was healed by touching his garment, he turned in the crowd, asked, and “looked round about to see her that had done this thing” (Mark 5:30-32).",
                "**A tree with nothing but leaves.** Hungry, he went to a fig tree “if haply he might find any thing thereon” and found “nothing but leaves; for the time of figs was not yet” (Mark 11:13).",
                "**Growing in wisdom.** “Jesus increased in wisdom and stature, and in favour with God and man” (Luke 2:52). Only a creature grows in knowledge.",
            ], title: "What the Gospels Say He Did Not Know", icon: "questionmark.circle.fill"),
            .text("The saying about the Hour troubled later copyists. In Matthew’s version of it (Matthew 24:36), the words “neither the Son” stand in the oldest surviving manuscripts of the verse, Codex Sinaiticus and Codex Vaticanus, and in modern critical editions, but they are missing from the later Byzantine copies behind the King James Version. The textual scholar Bruce Metzger judged it more likely that scribes dropped the words because of their doctrinal difficulty than that anyone added them."),
            .text("Christians answer these verses with the doctrine of two natures: as God, Jesus knew all things; as a man, he did not. That formula was defined at the Council of Chalcedon in 451 CE, four centuries after him, and no Gospel puts it in his mouth. Read without it, the verses mean what they say. The Quran records the same confession from Jesus himself: on the Day of Judgement he will say that Allah (Glorified and Exalted be He) knows what is within him, while he does not know what is within Allah (Quran 5:116, quoted below)."),
        ]),
        ArticleSection("AUTHORITY HE WAS GIVEN", [
            .text("The third pattern is authority. Again and again, Jesus (peace be upon him) describes his power as something he received:"),
            .quote(text: "“I can of mine own self do nothing: as I hear, I judge: and my judgment is just; because I seek not mine own will, but the will of the Father which hath sent me.” (John 5:30, KJV)", dimmed: true),
            .text("“The Son can do nothing of himself, but what he seeth the Father do” (John 5:19). He says that “the Father which sent me, he gave me a commandment, what I should say, and what I should speak” (John 12:49). “All power is given unto me in heaven and in earth” (Matthew 28:18), and power that is given has a Giver. He even calls himself “a man that hath told you the truth, which I have heard of God” (John 8:40). Peter’s sermon in the second chapter of Acts describes him the same way:"),
            .quote(text: "“Jesus of Nazareth, a man approved of God among you by miracles and wonders and signs, which God did by him in the midst of you” (Acts 2:22, KJV)", dimmed: true),
            .text("The words “which God did by him” are the New Testament’s own way of saying what the Quran says of the same miracles in 5:110, quoted above: each one was by the permission of Allah (Glorified and Exalted be He). A messenger speaks what he is given and performs what he is permitted. That is how the Quran describes every prophet, Muhammad (peace and blessings be upon him) among them."),
        ]),
        ArticleSection("WHAT THE WITNESSES CALLED HIM", [
            .text("The fourth pattern is what people said when they saw the miracles of Jesus (peace be upon him). Proving Islam presses this point, and it holds: the reaction the Gospels record again and again is not the worship of a God who has come down, but the recognition of a prophet who has been sent."),
            .checklist([
                "**A widow’s son raised at Nain:** “they glorified God, saying, That a great prophet is risen up among us; and, That God hath visited his people” (Luke 7:16).",
                "**Five thousand fed:** “This is of a truth that prophet that should come into the world” (John 6:14).",
                "**His entry into Jerusalem:** “This is Jesus the prophet of Nazareth of Galilee” (Matthew 21:11).",
                "**Two disciples on the road to Emmaus:** he “was a prophet mighty in deed and word before God and all the people” (Luke 24:19).",
            ], title: "After His Miracles, What Did They Say?", icon: "person.3.fill"),
            .text("Luke 7:16 keeps the two apart in a single sentence: the people glorified God, who had “visited his people”, and they called Jesus a great prophet. Jesus used the same word of himself: “A prophet is not without honour, but in his own country” (Mark 6:4), and “it cannot be that a prophet perish out of Jerusalem” (Luke 13:33). In the Quran, his very first words, spoken from the cradle, say the same:"),
            .ayah("19:29-33", words: 10...17),
            .text("Other titles appear in the Gospels too, and a fair reader should say so: Christ, Lord, Son of God. Muslims affirm the first, since the Quran calls him the Messiah; they read “Lord” as the respect due to a master, and “son of God” as the Bible uses it of Israel, of David and of the peacemakers. What the crowds never say after a miracle is “this man is God.” The verses that come closest are taken up in the questions below."),
        ]),
        ArticleSection("THE FIRST COMMANDMENT", [
            .text("If Jesus (peace be upon him) had wished to teach that he was God, one moment in the Gospels was made for it. A scribe asked him which commandment was the first of all, and he answered with the creed of Moses:"),
            .quote(text: "“The first of all the commandments is, Hear, O Israel; The Lord our God is one Lord: And thou shalt love the Lord thy God with all thy heart, and with all thy soul, and with all thy mind, and with all thy strength: this is the first commandment.” (Mark 12:29-30, KJV)", dimmed: true),
            .text("The scribe agreed that “there is one God; and there is none other but he”, and Jesus told him, “Thou art not far from the kingdom of God” (Mark 12:32-34). The words Jesus chose are the Shema of Deuteronomy 6:4, which Jews recite morning and evening to this day. He did not add himself to them."),
            .versus(ArticleVersus.Side("Mark 12:29, KJV", caption: "“Hear, O Israel; The Lord our God is one Lord”"), ArticleVersus.Side("Quran 112:1", arabic: "قُلۡ هُوَ ٱللَّهُ أَحَدٌ", caption: "Say, “He is Allah, [who is] One”"), quranic: true),
            .text("When a man ran up and called him “Good Master,” he declined even that: “Why callest thou me good? there is none good but one, that is, God” (Mark 10:18). Christians often read the question as a prompt for the man to think about who Jesus was; Muslims read it as it stands, a man turning aside a praise he reserved for God. And in the scene John sets at the empty tomb, after all that Christians believe happened at the cross, he speaks of God exactly as before:"),
            .versus(ArticleVersus.Side("John 20:17, KJV", caption: "“I ascend unto my Father, and your Father; and to my God, and your God.”"), ArticleVersus.Side("Quran 5:72", arabic: "ٱعۡبُدُواْ ٱللَّهَ رَبِّي وَرَبَّكُمۡ", caption: "“O Children of Israel, worship Allah, my Lord and your Lord.”"), quranic: true),
            .text("His Father is their Father, and his God is their God. Ibn Taymiyyah drew the conclusion from this verse:"),
            .quote(text: "“So he called Him the Father of them all. The Messiah was not singled out among them by the name ‘son’; the word ‘son’ is found among them only as a name for the chosen and honoured one, not as a name for any of the attributes of Allah.” (Ibn Taymiyyah, al-Jawab as-Sahih li man Baddala Din al-Masih)", arabic: "فَسَمَّاهُ أَبًا لِلْجَمِيعِ لَمْ يَكُنِ الْمَسِيحُ مَخْصُوصًا عِنْدَهُمْ بِاسْمِ الِابْنِ وَلَا يُوجَدُ عِنْدَهُمْ لَفْظُ الِابْنِ إِلَّا اسْمًا لِلْمُصْطَفَى الْمُكَرَّمِ لَا اسْمًا لِشَيْءٍ مِنْ صِفَاتِ اللَّهِ", dimmed: true),
        ]),
        ArticleSection("HOW THE TRINITY WAS DEFINED", [
            .stats([
                ArticleStat("0", "times the word “Trinity” appears in the Bible"),
                ArticleStat("325 CE", "Nicaea: the Son declared “of one substance” with the Father"),
                ArticleStat("381 CE", "Constantinople: the Holy Spirit given his article in the creed"),
                ArticleStat("451 CE", "Chalcedon: Christ defined as one person in two natures"),
            ]),
            .text("The word “Trinity” is not in the Bible. The Catholic Encyclopedia itself says that in Scripture “there is as yet no single term by which the Three Divine Persons are denoted together”, and the Stanford Encyclopedia of Philosophy says more plainly still: “The New Testament contains no explicit trinitarian doctrine.” Christian theologians answer that the doctrine can be inferred from what the New Testament teaches; the point here is only that it is not stated there. The Greek word trias first appears around 180 CE, in Theophilus of Antioch, and its Latin form trinitas in Tertullian after him."),
            .text("The doctrine was then settled by councils. In 325 CE the Emperor Constantine called the bishops to Nicaea over the teaching of Arius, a priest of Alexandria, that the Son was created and had a beginning. The council declared the Son homoousios, “of one substance” with the Father, and its creed ended with a bare “And in the Holy Spirit.” The decision at Nicaea itself was not close: most bishops signed, under the emperor’s threat of exile, and Arius and a few others refused and were exiled. The contest came afterwards. Within three years the leading Arians were back in Constantine’s favour, the emperors Constantius II and Valens later backed their party, and after the Council of Ariminum in 359 CE Jerome could write:"),
            .quote(text: "“The whole world groaned, and was astonished to find itself Arian.” (Jerome, Dialogue Against the Luciferians 19)", dimmed: true),
            .text("In 381 CE the Emperor Theodosius called the Council of Constantinople, which confirmed Nicaea and added the article on the Holy Spirit, “the Lord, the Giver of Life,” worshipped and glorified with the Father and the Son. With that, the doctrine of the Trinity took the form the major churches have confessed ever since. Seventy years later the Council of Chalcedon defined Christ as one person in two natures, divine and human, the formula Christians use to answer the verses above."),
            .text("None of this proves by itself that the doctrine is false; Christians hold that the councils only put into words what the Church already believed. But it shows that those words were chosen three and four centuries after Jesus (peace be upon him), by bishops and emperors, through a long dispute, while the words he chose were “The Lord our God is one Lord”. The Muslim reading is that he never taught more than that."),
        ]),
        ArticleSection("WHAT THE QURAN SAYS", [
            .text("The Quran does not leave the matter to history. It records the answer Jesus (peace be upon him) will give when Allah (Glorified and Exalted be He) asks him, before all creation, whether he told people to worship him and his mother:"),
            .ayah("5:116-117", words: 44...55),
            .text("It says plainly what happened at the cross, and what did not:"),
            .ayah("4:157-158", words: 9...15),
            .text("It speaks to the People of the Scripture directly, affirming that Jesus is a messenger of Allah, His word and a soul from Him, and forbidding them in the same breath to say “three”:"),
            .ayah("4:171", words: 12...37),
            .text("It gives the simplest argument of all: the Messiah was a messenger like those before him, he and his mother ate food, and whoever needs food is not God:"),
            .ayah("5:72-75", words: 66...81),
            .text("And it states in four short verses the belief every prophet taught, Jesus among them:"),
            .ayah("112:1-4"),
            .text("Yet the Quran addresses Christians as People of the Scripture and commands that they be argued with only in the best manner (Quran 29:46). Its last word on the subject is an invitation, not a verdict:"),
            .ayah("3:64"),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**What about “I and my Father are one” (John 10:30)?**"),
            .text("Read in its chapter, the verse closes a passage about his followers, whom no one can pluck out of his hand or his Father’s (John 10:27-29). When his hearers accused him of making himself God, he answered from their own scripture: “Is it not written in your law, I said, Ye are gods?” (John 10:34), a psalm spoken, he pointed out, of those “unto whom the word of God came” (John 10:35). Later he prays that his disciples “may be one, even as we are one” (John 17:22). A oneness he asks God to give his disciples is a oneness of purpose and obedience, not of being."),
            .markdown("**Did Thomas not call him “My Lord and my God” (John 20:28)?**"),
            .text("He did, and it is the verse Christians cite most, so it deserves a straight answer. It is a disciple’s exclamation, not the teaching of Jesus (peace be upon him) about himself; it is found only in John, the latest of the four Gospels; and eleven verses earlier in the same chapter, Jesus himself calls the Father “my God, and your God” (John 20:17). Christians read Thomas’s words as a confession of Jesus’ divinity. Muslims weigh them against the teacher’s own words about God, which are clearer and come first."),
            .markdown("**What about “Before Abraham was, I am” (John 8:58)?**"),
            .text("Christians hear in “I am” an echo of the name God gave Moses at the burning bush. Muslims read the verse as a statement about Jesus’ place in the plan of Allah (Glorified and Exalted be He), settled before Abraham was born, and revelation speaks of prophets this way. The Prophet (peace and blessings be upon him) was asked when his own prophethood was established:"),
            .hadith("tirmidhi:3609", cite: "Jami` at-Tirmidhi 3609; graded sahih by al-Albani", arabic: 38...41, english: [0...23]),
            .text("Ibn Taymiyyah explains that after Adam’s body was formed, and before the soul was breathed into it, Allah wrote and made known the prophethood of Muhammad, as He writes each person’s provision and term before the soul enters the body; knowing, writing and announcing a thing, he adds, is not the thing existing (Majmu‘ al-Fatawa, vol. 18). A prophet’s station can be decreed long before his birth without the prophet being God."),
            .markdown("**The Gospels say people “worshipped” him. Does that not settle it?**"),
            .text("The Greek word behind “worshipped” is proskuneo, which means to bow down before someone, and the Gospels use it of men as well. In one of Jesus’ own parables, a servant who owes his king a fortune “fell down, and worshipped him” (Matthew 18:26), and no reader takes the king for God. The same word describes the disciples bowing to Jesus in the boat (Matthew 14:33). What Jesus taught about worship in its full sense leaves no room for doubt: “Thou shalt worship the Lord thy God, and him only shalt thou serve” (Matthew 4:10)."),
            .door(.article("ChristianityAnswerView")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Islam honours Jesus (peace be upon him) as the Messiah, a word from Allah (Glorified and Exalted be He), born of a virgin, raised alive and returning before the Hour. The Gospels, read on their own terms, show a man who prayed to God, did not know the Hour, spoke only what he was given, was hailed as a prophet, and named the oneness of God as the first commandment. The doctrine of the Trinity was defined by councils three and four centuries later. The Quran calls the People of the Scripture back to what Jesus taught: to worship Allah, his Lord and theirs, alone."),
        ]),
        ArticleSection("KEY TERMS", [
            .term("Nabi", arabic: "نَبِيّ", meaning: "A prophet: from **ن-ب-أ**, news, one to whom Allah (Glorified and Exalted be He) gives news of the unseen (some lexicographers derive it from nabwah, a raised place, for the prophet’s high rank). The Hebrew navi, the Bible’s word for a prophet, is its cognate. It is the word the crowds used of Jesus (peace be upon him) after his miracles, and the word he used of himself (Mark 6:4, Luke 13:33)."),
            .term("Rasul", arabic: "رَسُول", meaning: "A messenger: from **ر-س-ل**, to send, one sent with a message from Allah. In his prayer Jesus calls himself the one “whom thou hast sent” (John 17:3), and the Letter to the Hebrews calls him “the Apostle” (Hebrews 3:1), from the Greek apostolos, one who is sent: the very meaning of rasul."),
            .term("‘Abd", arabic: "عَبد", meaning: "A servant of Allah, the most honoured title a human being can carry. Jesus’ first words in the cradle were that he is Allah’s servant (Quran 19:30), and the Quran says he would never disdain to be one (Quran 4:172). In Acts 3:13 and 4:27 the Greek word pais, which the King James Version renders “Son” and “child”, is rendered “servant” in most modern translations, among them the NIV, the ESV and the NASB."),
            .term("Ghuluw", arabic: "غُلُوّ", meaning: "Excess: going beyond the bounds in religion, above all in praising the righteous. The Quran opens its verse on Jesus by forbidding the People of the Scripture this excess (Quran 4:171), and the Prophet (peace and blessings be upon him) warned his own followers not to praise him as the Christians praised the son of Mary (Sahih al-Bukhari 3445)."),
        ]),
    ]
}

struct ProvingGodView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "ProvingGodView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("God: The Prior Question")
        .selectableArticleList(article: "ProvingGodView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: before asking which revelation is true, one has to ask whether anyone is there to reveal it. The Quran answers with a question that leaves a single door open (Quran 52:35-36): the universe did not come from nothing, did not make itself, and cannot hang on an endless chain of borrowed existence, so it rests on One who was never made. Reason can say a little about Him, a universe measured for life and a mind born inclined to its Maker point the same way, and the rest of this library asks whether He has spoken."),
        ]),
        ArticleSection("WHY THIS QUESTION COMES FIRST", [
            .text("Most of the Proving Islam library speaks to people who already believe in God and asks which claim to revelation holds up. This chapter speaks to those who do not. Proving Islam calls it the prior question, and the name is right: an argument that the Quran is the word of God assumes a God to speak it."),
            .text("The Quran itself spends less time here than a modern reader might expect, and for a reason. The people it first addressed already believed in a Creator. Their error was in worship, not in existence, and Allah (Glorified and Exalted be He) put their own answer back to them:"),
            .ayah("43:87"),
            .text("Yet the Quran does give the argument, because some did deny and because a believer should know why he believes. It gives it as the first step of a road, not the end of it: knowing that there is a Maker saves no one until it becomes the worship of Him alone."),
            .callout("The argument never says that everything has a cause. It says that whatever **begins**, or **depends** on something else for its existence, has a cause. What never began and depends on nothing needs no cause, and that is exactly what Muslims mean by Allah. Most objections to the argument dissolve once this is kept in view.", title: "The Key Distinction", icon: "lightbulb.fill"),
            .door(.article("GodPillarView")),
            .door(.article("TawhidView")),
        ]),
        ArticleSection("THE QURAN'S QUESTION", [
            .text("Jubayr ibn Mut‘im (may Allah be pleased with him) came to Madinah as an idolater, on the matter of the captives of Badr, and heard the Prophet (peace and blessings be upon him) recite Surat at-Tur in the sunset prayer (Sahih al-Bukhari 3050). When the recitation reached these verses, he said, his heart almost flew, and he called it the first time faith settled in his heart (Sahih al-Bukhari 4854, 4023):"),
            .ayah("52:35-36"),
            .text("The verses do not argue from scripture. They set out the possibilities for anything that has come into being and ask the listener to choose. Proving Islam draws the list out into five, and each deserves a look, because an argument is only as strong as its weakest step:"),
            .checklist([
                "**From nothing?** Nothing has no energy, no laws and no power. It cannot produce anything, because there is nothing there to do the producing.",
                "**Self-made?** To make itself, a thing would have to exist before it existed. That is not a mystery; it is a contradiction.",
                "**An endless chain of causes?** Every link borrows its existence from the one before. Make the chain as long as you like, even endless: a line of borrowers never contains a lender.",
                "**Made by something that was itself made?** Another universe, a multiverse, an alien engineer: each moves the question back one step and leaves it standing.",
                "**Made by One who was never made?** This is the only option that ends the question instead of postponing it.",
            ], title: "Five Ways a Universe Could Exist", icon: "questionmark.circle.fill"),
            .text("“I don’t know” is not a sixth option. It may be an honest answer about the details, but it does not make the first four any less impossible. Nor does the argument need to understand the First Cause completely; it needs only to see that there must be one."),
        ]),
        ArticleSection("THE DOORS THAT STAY CLOSED", [
            .text("Only the second door, a thing making itself, is closed by the meaning of the words alone. The others deserve a closer look, because serious people have tried to walk through them."),
            .markdown("**A universe from nothing?** The physicist Lawrence Krauss titled a book A Universe from Nothing (2012), arguing that physics can explain how a universe arises without a creator. But the “nothing” he describes is empty space, or at its furthest the absence of space, still governed by the laws of quantum physics. Reviewing the book in the New York Times, the philosopher of physics David Albert pointed out that it never asks where those laws and fields come from. A nothing with laws in it is something."),
            .markdown("**A universe that always existed?** Modern cosmology points the other way. The universe is expanding, and in 2003 the physicists Arvind Borde, Alan Guth and Alexander Vilenkin proved that a universe which has been expanding on average cannot be extended into the infinite past: its history has a boundary. The theorem treats space and time classically, and some physicists hope that a quantum theory of gravity will find a way around it. Vilenkin sums up where things stand:"),
            .quote(text: "“The answer to the question, ‘Did the universe have a beginning?’ is, ‘It probably did.’ We have no viable models of an eternal universe.” (Alexander Vilenkin, “The Beginning of the Universe,” Inference: International Review of Science, 2015)", dimmed: true),
            .text("Vilenkin adds, fairly, that in his view the theorem tells us nothing about God, and that the laws of physics which would describe the universe’s birth seem to have “some independent existence” that no one can yet explain. The Muslim argument does not ask physics to prove God. It takes only what physics already grants, that the universe very probably began, and asks what a beginning requires. And even a universe with no beginning would still be made of dependent things, each held in being by others; a chain does not stop needing a hook because it is long."),
            .markdown("**Made by another made thing?** Other universes, parent universes and alien designers may or may not exist, and the argument need not deny them. Each of them, if it began or depends on something else, stands in the same line and raises the same question. Adding links does not tell you what holds the chain up:"),
            .chain([
                ArticleChainLink("You", "given existence through your parents"),
                ArticleChainLink("Your parents", "and theirs, back through every generation"),
                ArticleChainLink("The earth and the sun", "formed from the dust of older stars"),
                ArticleChainLink("The universe", "which began, and runs on laws it did not write"),
                ArticleChainLink("Allah, the First", "with nothing before Him (Quran 57:3)"),
            ], caption: "Each link receives its existence from the one below it. Only the last receives nothing: it gives."),
        ]),
        ArticleSection("WHAT REASON CAN SAY OF HIM", [
            .text("If the chain rests on One who was never made, reason can say a little about Him before any scripture is opened. Proving Islam lists the qualities such a First Cause must have. Put carefully, in the way the Quran and the Sunnah describe Allah (Glorified and Exalted be He), they are these:"),
            .checklist([
                "**Not part of the universe.** He made its space, time and matter, so He is not one more thing within them. He is distinct from His creation, and nothing in it contains Him.",
                "**Without beginning.** Whatever began needs a cause; the First did not begin.",
                "**Unlike anything made.** The universe’s matter is part of what began and depends, so its Maker is not built of it.",
                "**Of immense power.** He brought all of it into being.",
                "**Acting by will.** A blind mechanism that had always existed would always have produced its effect; a universe that began points to a Maker who chose to act.",
                "**One.** Two independent first causes would limit each other, and a second explains nothing the first does not.",
            ], title: "What a First Cause Must Be", icon: "checkmark.seal.fill"),
            .text("The Quran says all of this, and more, in a few words:"),
            .ayah("112:1-4"),
            .ayah("42:11", words: 13...18),
            .text("He is as-Samad, the One on whom everything depends while He depends on nothing. He neither begets nor was born, since whatever is born began. Nothing is like Him, and yet He hears and sees: the verse denies any likeness to creation without denying the attributes Allah affirms for Himself. When men from Yemen came to the Prophet (peace and blessings be upon him) to learn the religion and asked him how all of this began, he answered:"),
            .hadith("bukhari:7418", cite: "Sahih al-Bukhari 7418", arabic: 77...95, english: [96...125]),
            .text("For His oneness the Quran gives the argument itself: rival gods would each take away what they had made and strive against one another, and the heavens and the earth show no such division."),
            .ayah("23:91", words: 5...19),
            .text("Here reason reaches its limit, and honesty requires saying so. Reason can show that there is a First Cause and something of what He must be. It cannot tell you His names, whether He forgives, what He wants of you, or what comes after death. For that, He would have to speak."),
        ]),
        ArticleSection("A UNIVERSE MEASURED FOR LIFE", [
            .text("The second line of evidence is not that the universe exists but how it is made. Physicists have found that several numbers built into the laws of nature, and into the universe’s first conditions, fall within narrow ranges that allow stars, chemistry and life. The finding is discussed openly by physicists of every belief. The Astronomer Royal Martin Rees sets out six such numbers in Just Six Numbers (1999), among them:"),
            .stats([
                ArticleStat("0.007", "ε, how firmly atomic nuclei bind; at 0.006 or 0.008, Rees writes, “we could not exist”"),
                ArticleStat("10³⁶", "N, the electrical force holding atoms together over gravity; “a few less zeros” and no creature larger than an insect"),
                ArticleStat("1/100,000", "Q, the ripples in the early universe that seeded galaxies; smaller, an inert universe; much larger, one ruled by vast black holes"),
                ArticleStat("3", "D, the dimensions of space; life “couldn’t exist if D were two or four”"),
            ]),
            .text("The best-known case came in 1953. The astronomer Fred Hoyle reasoned from the amount of carbon in the universe that the carbon nucleus must have an energy level at one particular value, or the stars could never have made carbon in quantity. Physicists at Caltech looked for it and found it within months. Hoyle, who had declared himself an atheist, drew his own conclusion:"),
            .quote(text: "“A common sense interpretation of the facts suggests that a superintellect has monkeyed with physics, as well as with chemistry and biology, and that there are no blind forces worth speaking about in nature.” (Fred Hoyle, “The Universe: Past and Present Reflections,” Engineering and Science, November 1981)", dimmed: true),
            .text("The Quran describes a creation measured out with precision:"),
            .ayah("25:2", words: 14...18),
            .markdown("**“We are here, so of course the numbers allow us.”** This is the anthropic objection, and it is half right: we could not observe a universe that did not allow observers. But it does not explain why a universe that allows observers exists. The philosopher John Leslie gave the classic reply: a prisoner stands before a firing squad, every marksman fires, and he finds himself alive. He is right to ask whether they meant to miss, even though he could not be asking if they had not."),
            .markdown("**“There are countless universes, and we are in a lucky one.”** This is Rees’s own view. Asking whether the tuning is a coincidence or the providence of a Creator, he answers that it is neither: an infinity of other universes “may well exist” with different numbers. It is a serious hypothesis, but no other universe has been observed, and defenders of the argument point out that a process which makes universes would itself need laws, finely set, in order to work. It moves the question back a step rather than answering it."),
            .markdown("**“Perhaps the tuning is less fine than claimed.”** Some physicists, such as Victor Stenger and Fred Adams, argue that the ranges that permit life are wider than popular accounts suggest, and the debate among specialists continues. A Muslim does not rest his faith on any one number. The point is the pattern the Quran describes: a creation ordered, measured and intelligible, in which whoever looks finds no flaw (Quran 67:3)."),
        ]),
        ArticleSection("THE FITRAH", [
            .text("The third line of evidence is within us. Allah (Glorified and Exalted be He) says that He created people upon a natural disposition, the fitrah, which turns to Him before anyone teaches it:"),
            .ayah("30:30", words: 4...9),
            .text("The Prophet (peace and blessings be upon him) explained it with an image from the flock: an animal is born whole, with nothing cut or missing."),
            .hadith("muslim:2658b", cite: "Sahih Muslim 2658", arabic: 30...50, english: [0...43]),
            .text("In a hadith qudsi, Allah says:"),
            .hadith("muslim:2865a", cite: "Sahih Muslim 2865", arabic: 70...80, english: [38...65]),
            .text("Modern research has approached the same question from outside religion. A three-year project at the University of Oxford, the Cognition, Religion and Theology Project, directed by the psychologist Justin Barrett and the philosopher Roger Trigg, involved 57 researchers in more than forty studies across twenty countries, traditionally religious and atheist societies among them. It concluded that humans are “predisposed to believe in gods and an afterlife,” and that both theology and atheism are “reasoned responses to what is a basic impulse of the human mind.” Among its findings: three-year-olds assume that both their mother and God know what is inside a closed box; by four they understand that their mother can be wrong, but may go on believing that God knows. In Deborah Kelemen’s studies, children reach naturally for purpose, explaining that rocks are pointed “so the birds could sit on them.”"),
            .text("Barrett was careful to add: “Just because we find it easier to think in a particular way does not mean that it is true in fact.” Researchers also disagree about why the mind works this way; some see a by-product of evolution. A Muslim need not claim that the research proves the fitrah. It is enough that it finds what the hadith would lead one to expect: belief in a Maker comes naturally to the human mind, and whoever denies Him has to argue against his own first instinct."),
        ]),
        ArticleSection("FROM A CREATOR TO A MESSAGE", [
            .text("Suppose all of this is granted: a First Cause exists, without beginning, powerful, willing and one. Many stop there and ask, reasonably, why that should lead to Islam. Proving Islam answers with a question of its own. Would a Maker who made beings able to know Him, to ask why they exist and to feel the weight of right and wrong, leave them without a word? A Creator who makes creatures capable of seeking Him and then stays silent is harder to believe in than one who speaks. The Quran puts the same question to its reader:"),
            .ayah("23:115"),
            .text("And it gives the reason messengers were sent at all:"),
            .ayah("4:165"),
            .text("This is not an argument that Islam is true because God exists. It is an argument that the question of revelation is worth asking, and that a book which claims to be His word deserves to be tested. The rest of this library does the testing: it asks whether the Quran behaves like a human book, and sets out the evidence that it does not. Two places to begin:"),
            .door(.article("ProvingCaseView")),
            .door(.article("ProvingIjazView")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**Who created God?**"),
            .text("No one, and the question misreads the argument. The argument never said that everything needs a cause, only that whatever begins or depends does. A First Cause that needed a cause would not be first, and the question simply asks for the endless regress the argument has already ruled out. The Prophet (peace and blessings be upon him) foretold that people would ask it, and taught what to do when it comes:"),
            .hadith("muslim:134a", cite: "Sahih Muslim 134", arabic: 31...51, english: [0...35]),
            .text("Ibn Taymiyyah (may Allah have mercy on him) explained that this is the very regress which reason itself rejects:"),
            .quote(text: "“The word ‘regress’ is used of a regress in causes: that what comes to be has a maker, and the maker has a maker. This is false by plain reason and by the agreement of the rational, and it is the regress from which the Prophet (peace and blessings be upon him) commanded that refuge be sought in Allah, and which he commanded us to stop at.” (Ibn Taymiyyah, Dar’ Ta‘arud al-‘Aql wan-Naql)", arabic: "وَلَفظُ التَّسَلسُلِ يُرَادُ بِهِ التَّسَلسُلُ فِي المُؤَثِّرَاتِ، وَهُوَ أَن يَكُونَ لِلحَادِثِ فَاعِلٌ وَلِلفَاعِلِ فَاعِلٌ، وَهَذَا بَاطِلٌ بِصَرِيحِ العَقلِ وَاتِّفَاقِ العُقَلَاءِ، وَهَذَا هُوَ التَّسَلسُلُ الَّذِي أَمَرَ النَّبِيُّ صَلَّى اللَّهُ عَلَيهِ وَسَلَّمَ بِأَن يُستَعَاذَ بِاللَّهِ مِنهُ، وَأَمَرَ بِالِانتِهَاءِ عَنهُ", dimmed: true),
            .markdown("**Isn’t this a “God of the gaps” argument?**"),
            .text("A God-of-the-gaps argument points to something science has not yet explained and says “God did it,” so that every discovery shrinks God. These arguments work the other way. They start not from what physics cannot explain but from what physics itself describes: a universe that began, laws that hold, and constants that fall in narrow ranges. The more science learns about these, the sharper the question becomes. The Quran commands exactly this kind of looking, at the signs in the horizons and within ourselves (Quran 3:190-191, 41:53)."),
            .markdown("**Why must the cause be God, and not simply “something”?**"),
            .text("Because of what the cause must be to do the job. Whatever brought all of space, time and matter into being cannot be one more piece of space, time and matter. It must be without beginning, dependent on nothing, powerful enough to bring everything into being, and able to act by choice. A “something” with all of those qualities is what every monotheist means by God. The name matters less than the description, and the description reason reaches is one the Quran gave first, and then completed with what reason alone could never know."),
            .markdown("**Why one God, and not several?**"),
            .text("Two independent gods would either be able to overrule each other or not. If one can overrule the other, the other is not a god; if neither can, neither is all-powerful. The Quran states the argument from what we see: rival lords would tear their creation apart, and ours is one ordered whole (Quran 21:22, 23:91). Simplicity points the same way: a second First Cause explains nothing the first does not."),
            .door(.article("AtheismAnswerView")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("The universe did not come from nothing, did not make itself, and cannot rest on an endless chain of borrowed existence; it rests on One who was never made. Reason can say that He is without beginning, distinct from what He made, powerful, willing and one, and a universe measured for life and a mind born inclined to its Maker point the same way. What reason cannot say is who He is and what He asks of us. That is the question the rest of Proving Islam takes up: whether He has spoken, and whether the Quran is His word."),
        ]),
        ArticleSection("KEY TERMS", [
            .term("Fitrah", arabic: "فِطرَة", meaning: "From **ف-ط-ر**, to originate or to split open: the natural disposition on which Allah (Glorified and Exalted be He) creates every human being, which recognises its Maker before any teaching (Quran 30:30; Sahih Muslim 2658)."),
            .term("Rububiyyah", arabic: "رُبُوبِيَّة", meaning: "Lordship, from **ر-ب-ب**: that Allah alone creates, owns and governs all things. It is what reason and the fitrah reach, and the idolaters of Makkah affirmed it (Quran 43:87); tawhid is complete only when worship is given to Him alone."),
            .term("Tasalsul", arabic: "تَسَلسُل", meaning: "From **سِلسِلَة**, a chain: an infinite regress, each link depending on one before it without end. A regress of makers is impossible, and Ibn Taymiyyah identified it with the question the Prophet (peace and blessings be upon him) told believers to cut off (Sahih Muslim 134)."),
            .term("Taqdir", arabic: "تَقدِير", meaning: "From **ق-د-ر**, measure and decree: the exact measuring-out of each created thing. Allah created everything and measured it precisely (Quran 25:2, 54:49), a fitting word for the order physicists describe when they speak of a finely tuned universe."),
            .term("Burhan", arabic: "بُرهَان", meaning: "A decisive proof. After asking who begins creation and provides for it, the Quran turns to those who worship others besides Allah and challenges them to bring theirs (Quran 27:64)."),
        ]),
    ]
}

struct ProvingQuestionsView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "ProvingQuestionsView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("Six Hard Questions")
        .selectableArticleList(article: "ProvingQuestionsView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: six questions that the evidence puts to anyone who holds that the Quran was one man’s work. What was his motive? Why did he never copy his sources’ mistakes? Why did Abu Lahab stay silent? Where is the other Quran? How many coincidences does the alternative need? And why do the Quran and the everyday words of the man who recited it sound like two different speakers? They are meant to be thought through, not thrown."),
        ]),
        ArticleSection("QUESTIONS WORTH THINKING THROUGH", [
            .text("Proving Islam calls these the hardest corners of its case, and is careful to add that they are not rhetorical attacks. They are the places where a purely human explanation has to pay for itself. The Quran put questions of this kind to its own first audience and left them to answer honestly. Allah (Glorified and Exalted be He) says:"),
            .ayah("23:68-70"),
            .text("Each question below comes with the evidence behind it, the strongest reply a sceptic can give, and the chapter that develops it at length."),
        ]),
        ArticleSection("WHAT WAS THE MOTIVE?", [
            .markdown("**The question:** if the Prophet (peace and blessings be upon him) composed the Quran himself, why did he do it? Is there one motive that survives contact with his documented life?"),
            .text("Money is the obvious candidate, and it fails first. The Quran told him to say that he asked no payment for it:"),
            .ayah("38:86"),
            .text("He went on to lead a state, and he died poor. Aishah (may Allah be pleased with her) reported that two months could pass without a cooking fire being lit in his houses (Sahih al-Bukhari 2567), and that at his death his armour was held as security for barley:"),
            .hadith("bukhari:2916", cite: "Sahih al-Bukhari 2916", arabic: 20...34, english: [0...17]),
            .text("Power fares no better. His opponents wanted a compromise, and the Quran records both their wish and his refusal, and even warns him against the smallest leaning toward them:"),
            .ayah("68:9"),
            .ayah("17:73-75"),
            .text("Status he already had. Before the revelation his people trusted him, and the message cost him that standing through some thirteen years of mockery, boycott and exile before it brought him any power at all."),
            .text("The honest sceptic’s best reply is not fraud but sincerity: perhaps he believed an inner voice that was really his own. That is a serious proposal, and it abandons the idea of a deliberate impostor. It then has to explain why that inner voice rebuked him in public, fell silent when he most needed it, knew what he could not have known, and spoke in a style unlike his own. The remaining questions, and the chapters behind them, take up exactly those points."),
            .door(.article("ProvingProphetView")),
        ]),
        ArticleSection("WHY DID HE NOT COPY THEIR MISTAKES?", [
            .markdown("**The question:** if the Quran borrowed its stories from Jewish and Christian sources, why does it differ from them precisely where those sources are most open to criticism?"),
            .text("Two examples show the pattern. In the Book of Exodus, the golden calf is made by Aaron, the brother of Moses and the first high priest of Israel:"),
            .quote(text: "“And he received them at their hand, and fashioned it with a graving tool, after he had made it a molten calf: and they said, These be thy gods, O Israel, which brought thee up out of the land of Egypt.” (Exodus 32:4, King James Version)", dimmed: true),
            .text("The Quran tells the same story with a different culprit, a man it calls the Samiri (20:85), and has Harun (peace be upon him), as it names Aaron, warn the people against the calf before Musa (peace be upon him) returns:"),
            .ayah("20:90"),
            .text("The second example concerns a single word. The Bible calls the ruler of Egypt “Pharaoh” in the days of Abraham and Joseph (Genesis 12 and 41) as well as in the days of Moses. The Quran calls Joseph’s ruler “the king”, and keeps “Pharaoh” for the ruler whom Moses faced:"),
            .versus(ArticleVersus.Side("Genesis 41:46", caption: "“…when he stood before **Pharaoh** king of Egypt”"), ArticleVersus.Side("Quran 12:43", caption: "“And [subsequently] the **king** said…”"), quranic: true),
            .text("Egyptologists find that the word pharaoh, which first meant “great house”, the palace, came to be used for the king himself only in the New Kingdom, around the fifteenth and fourteenth centuries BCE, after the age in which those who take the Joseph story as history usually place him. The honest caveat: no Egyptian record fixes Joseph’s date, and Genesis may simply use the title of its own writers’ day. So this is a reading rather than a proof. But it is a striking one, because a copyist would simply have kept his source’s word."),
            .text("The Quran does share stories with earlier scripture, and Muslims expect it to, since it claims the same Source: it describes itself as confirming what came before it and standing as a criterion over it (5:48). The question is not whether it shares but how it differs, and its differences run consistently in one direction, toward prophets who are upright and a God who is one. The Quran also answered, in its own time, the charge that a human teacher lay behind it:"),
            .ayah("16:103"),
            .door(.article("ProvingSourcesView")),
            .door(.article("ProvingScriptureView")),
            .door(.miracle("pharaoh", title: "Pharaoh, a New Kingdom Title")),
        ]),
        ArticleSection("WHY DID ABU LAHAB STAY SILENT?", [
            .markdown("**The question:** a surah said of a living enemy, by name, that he would end in the Fire. One public profession of Islam, even a false one, would have refuted it. Why did he never make it?"),
            .text("Abu Lahab was an uncle of the Prophet (peace and blessings be upon him) and one of his loudest opponents. When the Prophet first called Quraysh together in public to warn them, it was this uncle who answered:"),
            .hadith("bukhari:4972", cite: "Sahih al-Bukhari 4972", arabic: 65...79, english: [68...93]),
            .ayah("111:1-3"),
            .text("He lived for years after this, and died in Makkah shortly after the Battle of Badr in 2 AH, still an idolater: roughly a decade, if the surah came at that first public call as the hadith describes. In those years many of the Prophet’s fiercest enemies accepted Islam. The one man the Quran had named never did."),
            .text("A sceptic can reply that the surah is a curse, not a prediction, or that Abu Lahab was simply too proud to play along. The first does not remove the risk: the surah states his end, and in Islam that end belongs only to one who dies refusing faith, so a profession of Islam from him would have contradicted it in front of everyone. The second only moves the question: the man who recited the surah staked his message on another man’s pride for about ten years. Either he knew, or he took a gamble that no forger needed to take."),
            .door(.prophecy("abu-lahab")),
        ]),
        ArticleSection("WHERE IS THE OTHER QURAN?", [
            .markdown("**The question:** if the Quran was substantially changed after the Prophet (peace and blessings be upon him), where is the evidence: the manuscript, the variant text, the chain of transmission?"),
            .text("The Quran promised its own keeping while it was still the recitation of a persecuted few in Makkah:"),
            .ayah("15:9"),
            .text("Its preservation has never rested on a single copy. It was written down in the Prophet’s lifetime, gathered into one volume under Abu Bakr (may Allah be pleased with him), copied into standard copies under ‘Uthman (may Allah be pleased with him), and memorised whole in every generation since, so that a slip in public recitation is corrected by the people praying behind. The physical record agrees. In 2015 the University of Birmingham announced that two leaves in its collection, holding parts of Surahs 18 to 20, are written on parchment that radiocarbon dating placed between 568 and 645 CE, a span that includes the Prophet’s lifetime."),
            .stats([ArticleStat("568–645 CE", "the radiocarbon date of the Birmingham leaves’ parchment"), ArticleStat("95.4%", "the confidence given for that range")]),
            .text("The strongest material critics cite is the Sana’a palimpsest, whose erased lower text is a copy from outside the ‘Uthmanic tradition. It differs in wording within verses and in the order of surahs, and its variants resemble in kind those that early Muslim scholars recorded from the codices of Companions such as Ibn Mas‘ud (may Allah be pleased with him). Behnam Sadeghi and Uwe Bergmann, who studied it closely, concluded from the parts they examined that the ‘Uthmanic tradition preserves the Prophet’s recitation better than this lower text does. Variation of that kind is something Muslim scholarship has always documented. A different Quran is something no manuscript has shown."),
            .door(.article("ProvingPreservationView")),
            .door(.prophecy("quran-preserved")),
        ]),
        ArticleSection("HOW MANY COINCIDENCES?", [
            .markdown("**The question:** count what the alternative needs to be true at the same time. Is all of it together simpler than the one explanation the Quran gives for itself?"),
            .text("The opponents of the Prophet (peace and blessings be upon him) could never settle on one explanation themselves. The Quran records them moving from one theory to the next:"),
            .ayah("21:5"),
            .text("A modern alternative faces the same difficulty. Without revelation, all of the following have to be true together:"),
            .step("1. **A hidden teacher or library** in Makkah, holding Jewish and Christian writings in Hebrew, Aramaic, Syriac or Greek, which no enemy ever exposed, for a man who could not read at all."),
            .step("2. **Luck, again and again:** each named, public prediction happening to come true, and none failing."),
            .step("3. **An untrained genius** who outdid the poets of the most poetic people of his age, and whose challenge no one met."),
            .step("4. **One steady voice** held through twenty-three years of persecution, grief and war, and kept distinct from his own everyday speech."),
            .step("5. **A man who denied authorship** of the finest work in his language, and suffered for it rather than profiting."),
            .step("6. **A text kept word for word** by a community that could easily have let it drift."),
            .text("Each of these needs an assumption of its own, while revelation needs one. Proving Islam puts the choice starkly: all of that at once, or that God communicated. The Quran’s own answer is short:"),
            .ayah("26:192-195"),
            .door(.article("ProvingCaseView")),
        ]),
        ArticleSection("WHY TWO VOICES?", [
            .markdown("**The question:** the Quran and the hadith came from the same man, in the same language, over the same years, to the same people. Why do they sound like two different speakers?"),
            .text("Readers of Arabic have always noticed the difference. The hadith is the speech of a man: direct, practical and conversational. The Quran is something else: compressed, rhythmic, and addressed from above. The Prophet (peace and blessings be upon him) treated the two differently himself. Asked a question, he usually answered in his own words; sometimes he fell silent and waited, and what came then was recited as Quran:"),
            .hadith("bukhari:4721", cite: "Sahih al-Bukhari 4721", arabic: 59...95, english: [71...143]),
            .text("The difference has also been measured. In a peer-reviewed study in Literary and Linguistic Computing (2012), the computer scientist Halim Sayoud of USTHB University in Algiers compared the whole Quran with the narrations of Sahih al-Bukhari in three series of experiments, and reported that all of his results showed the two books should have two different authors. Separately, Behnam Sadeghi’s stylometric study in the journal Arabica (2011) found the Quran’s style changing smoothly across seven phases, and concluded that the Quran has one author."),
            .text("Two cautions keep this honest. Sadeghi works in a secular framework and makes no theological claim: his finding concerns the unity of the text, not its source. And stylometry measures style, not origin; one person can speak in two registers, as a preacher’s sermon differs from his conversation. The question then becomes whether one man could keep one register so distinct from the other, never letting them mix, for twenty-three years, and why he would attribute the finer one to God. Sayoud’s later book on the subject (third edition, 2025), which draws stronger conclusions, is self-published in an open repository rather than peer-reviewed; the point here rests on the 2012 study."),
            .door(.article("ProvingStylometryView")),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**Aren’t these questions just debating traps?**"),
            .text("They can be used that way, and Proving Islam itself warns against it: the goal, in its words, is “not to win an argument aggressively but to expose the explanatory cost of the alternative position.” A fair reader takes the questions one at a time, gives the sceptic’s best reply its full weight, and then asks whether the replies, taken together, are still simpler than the explanation they are meant to replace."),
            .markdown("**What if a critic answers one of them well?**"),
            .text("Then that strand is weaker, and the others stand as they were. The case is cumulative and was never built on any single question. But the answers have to be counted together, because each one is a separate assumption, which is the whole point of the fifth question."),
            .markdown("**Do these questions apply to Jews and Christians too?**"),
            .text("Yes, and they can be put gently. Anyone who accepts Moses or Jesus (peace be upon them) as a prophet already accepts that God speaks through chosen men, and has reasons for believing them. The same reasons can fairly be put to Muhammad (peace and blessings be upon him), and the Quran asks that the conversation with the People of the Scripture be held in the best manner, on the common ground of one God:"),
            .ayah("29:46"),
            .door(.article("ProvingBibleView")),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("Six questions, six places where a purely human explanation has to pay its way: a motive that fits his life, a copyist who improved on his sources, an enemy who never took the one step that would have refuted the Quran, a rival text that has never appeared, a pile of coincidences, and two voices from one mouth. A critic may answer any one of them. The case asks whether one account answers all six at once, and whether any account is simpler than the one the Quran gives for itself."),
        ]),
        ArticleSection("KEY TERMS", [
            .term("Tahaddi", arabic: "تَحَدِّي", meaning: "The **challenge**: the Quran’s call to its opponents to produce a surah like it (2:23, 10:38), with the prediction that they never would (2:24)."),
            .term("Rasm", arabic: "رَسم", meaning: "The **written skeleton** of the Quran’s text: its letters as copied in the ‘Uthmanic codices, without the dots that tell similar letters apart and without vowel signs. Early manuscripts such as the Birmingham leaves are compared with the standard text through it."),
            .term("Mushaf", arabic: "مُصحَف", meaning: "A written **copy of the Quran**, bound as one book; from the root **ص-ح-ف**, sheets. The Quran was first gathered into a single mushaf under Abu Bakr, and ‘Uthman had standard copies made from it."),
            .term("Ghayb", arabic: "غَيب", meaning: "The **unseen**: whatever is hidden from human senses and knowledge, the future included. The Quran has the Prophet (peace and blessings be upon him) say that he does not know it and only follows what is revealed to him (6:50), which is why a fulfilled prediction points beyond him."),
        ]),
    ]
}

struct ProvingClosingView: View {
    var body: some View {
        List {
            Group {
                ArticleSectionsView(sections: Self.sections)

                ArticleSourcesSection(article: "ProvingClosingView")
            }
            .themedListRowBackground()
        }
        .navigationTitle("The Converging Case")
        .selectableArticleList(article: "ProvingClosingView")
    }

    static let sections: [ArticleSection] = [
        ArticleSection("SUMMARY", [
            .text("In short: each chapter of this library tested one mark that a human origin would have left, and the Quran lacks them all at once. A critic can explain any single strand; the question is which one explanation accounts for all of them, and the simplest remains the one the Quran gives for itself, a revelation from the Lord of the worlds. What follows from that is an invitation, and the Quran makes it gently."),
        ]),
        ArticleSection("THE PILLARS OF THE CASE", [
            .text("Proving Islam ends its long argument by setting its pillars side by side, and the shape of the case is easiest to see that way. A human origin would have left recognisable marks, each of a different kind, and each is tested in its own chapter:"),
            .checklist([
                "**A human author leaves human fingerprints:** the errors of his age. No clear error in the Quran that all sides accept has been produced in fourteen centuries. (The Human Fingerprint Test)",
                "**A fraud leaves psychological fingerprints:** a motive, a price, a retreat under pressure. The Prophet (peace and blessings be upon him) refused compromise, died poor, and recited a book that corrects him. (The Prophet’s Character)",
                "**A borrowed text leaves source fingerprints:** its sources’ mistakes, copied. The Quran departs from earlier accounts just where they are most open to criticism. (Where Could He Have Learned It?)",
                "**An ancient text leaves scientific fingerprints:** the textbook errors of its century. The Quran speaks often of nature without teaching them as fact. (The Errors It Did Not Make)",
                "**A political founder leaves power fingerprints:** laws that favour himself, his family and his tribe. The Quran commands justice against oneself and toward enemies. (Justice Beyond the Tribe)",
                "**A developing author leaves stylistic drift:** a voice that breaks or wanders with the years. The Quran’s style develops smoothly as one voice, and stays distinct from his own speech. (Two Voices: Quran and Hadith)",
                "**A fragile scripture leaves preservation scars:** lost passages and rival editions. The Quran is recited today as it was taught, and no manuscript shows a different one. (Preserved as Promised)",
            ], title: "What a Human Origin Would Leave Behind", icon: "touchid"),
            .markdown("In Proving Islam’s words: **“The Qur’an resists these expectations simultaneously. That is the cumulative case.”**"),
            .text("Beyond those seven missing marks, the library brings positive evidence of its own:"),
            .bullet("**Foretold, and fulfilled.** Named, public predictions, among them the Romans’ recovery (30:2-4) and Abu Lahab’s end (111:1-3), came true, and none is on record as having failed."),
            .bullet("**The unmatched Quran.** The most eloquent people of their age were challenged to produce a single surah like it, with every reason to succeed, and did not."),
            .bullet("**One message, many messengers.** The Prophet brought no new religion but the one every prophet taught, the worship of Allah (Glorified and Exalted be He) alone, and Muslim scholars read passages of the earlier scriptures as pointing ahead to him."),
            .bullet("**Jesus in the Gospels.** In the Gospels Jesus (peace be upon him) prays to God, speaks of himself as a prophet, and names the oneness of God as the first commandment; Islam honours him as the Messiah and a messenger of Allah."),
            .bullet("**God, the prior question.** Whatever begins to exist needs a cause beyond itself. The universe began, and its cause is the First, with nothing before Him (57:3)."),
            .door(.article("ProvingCaseView")),
        ]),
        ArticleSection("THE CLOSING ARGUMENT", [
            .text("No single argument here has to carry the whole weight of Islam. If the Quran were merely human, we should expect the ordinary marks of human production: failed predictions, inherited myths, errors of science, tribal ethics, the author’s ego, a style that drifts out of control, a text that decays, and a visible dependence on its sources."),
            .text("What we find instead is a book revealed over twenty-three years, through about the most unstable circumstances a life can hold, that keeps its voice, corrects rather than copies, legislates against its own messenger’s interest, predicts without retreating into vagueness, and has been kept by a living community ever since."),
            .text("Anyone can invent an explanation for any one of these. The question is whether a single explanation accounts for all of them at once, and here the arithmetic of the first chapter returns: every separate excuse is a separate assumption, and independent coincidences multiply. The simplest explanation remains the one the Quran gives for itself. Allah (Glorified and Exalted be He) says:"),
            .ayah("10:37"),
            .ayah("41:42"),
            .callout("If the Quran were a human work, its human marks should be there, in many independent places at once. They are not. The explanation that needs one assumption, rather than a new one for each kind of evidence, is the one the Quran gives: **it is revelation from the Lord of the worlds.**", title: "The Closing Question", icon: "arrow.triangle.merge"),
            .text("The case does not depend on every argument surviving every challenge, and this library has tried to mark its weaker strands honestly. It depends on the whole, and on the fact that no rival account, in fourteen centuries of trying, has explained all of it with one coherent and economical theory."),
        ]),
        ArticleSection("THE INVITATION", [
            .text("If the case is sound, it asks something of the reader, and the Quran is careful about how that request is made. It forbids compulsion, because the right course has already been made clear:"),
            .ayah("2:256", words: 0...8),
            .text("It tells those who call to it to do so with wisdom and good instruction:"),
            .ayah("16:125"),
            .text("And to the People of the Scripture, Jews and Christians, it offers common ground before anything else:"),
            .ayah("3:64"),
            .text("The Prophet (peace and blessings be upon him) promised a double reward to the one among them who believes in his own prophet and then in him:"),
            .hadith("muslim:154a", cite: "Sahih Muslim 154", arabic: 63...84, english: [58...113]),
            .text("Nothing in a person’s past is a barrier. Allah (Glorified and Exalted be He) says:"),
            .ayah("39:53"),
            .text("When ‘Amr ibn al-‘As (may Allah be pleased with him), once among the fiercest enemies of Islam, came to give his pledge and first asked to be forgiven, the Prophet told him:"),
            .hadith("muslim:121", cite: "Sahih Muslim 121", arabic: 189...208, english: [244...276]),
            .text("Becoming Muslim needs no ceremony, witness or scholar. It is to bear witness, believing it in the heart, that there is no deity except Allah and that Muhammad is the Messenger of Allah. The two pages below explain what that testimony means and how to make it."),
            .door(.article("BecomeMuslimView")),
            .door(.article("ShahadahView")),
        ]),
        ArticleSection("FOR THE ONE STILL SEARCHING", [
            .text("Not everyone who reads a case like this is ready to decide, and the Quran does not ask anyone to pretend. It asks for honest looking, and it points to itself as the sign that is always within reach. Allah (Glorified and Exalted be He) says:"),
            .ayah("29:51"),
            .text("Many who accepted Islam in the time of the Prophet (peace and blessings be upon him) were first moved by a single passage heard with an open heart. Jubayr ibn Mut‘im (may Allah be pleased with him) came to Madinah about the captives of Badr while still a pagan, and heard the Prophet recite Surah at-Tur in the sunset prayer:"),
            .hadith("bukhari:4023", cite: "Sahih al-Bukhari 4023", arabic: 18...34, english: [0...23]),
            .text("The Prophet himself, the most certain of men, opened his night prayer by asking to be guided through the very questions over which people differ:"),
            .hadith("muslim:770", cite: "Sahih Muslim 770", arabic: 65...97, english: [45...104]),
            .text("For the one still searching, the way forward is simple to state:"),
            .step("1. **Read the Quran itself**, in a translation you trust and, if you can, with someone who reads the Arabic."),
            .step("2. **Take one objection at a time**, at its strongest, and follow it to its answer, as the note on honesty in the first chapter asks."),
            .step("3. **Ask Allah sincerely for guidance**, in your own words or in the words of the Prophet above."),
            .step("4. **When you are convinced, do not delay** the testimony you already believe."),
        ]),
        ArticleSection("COMMON QUESTIONS", [
            .markdown("**Can I be certain without seeing a miracle myself?**"),
            .text("Yes. Most of what anyone knows for certain, the existence of countries never visited and of people never met, rests on converging testimony rather than on personal sight; that is the certainty of the mutawatir report. The Companions (may Allah be pleased with them) who saw the miracles of the Prophet (peace and blessings be upon him) were a single generation. The Quran is the sign that everyone after them can still examine, and it is the sign the Quran itself points to (29:51, above). The evidence in this library is of that kind: public, open to checking, and convergent."),
            .markdown("**Does accepting Islam mean rejecting Moses and Jesus?**"),
            .text("No. A Muslim believes in every prophet whom Allah (Glorified and Exalted be He) sent, and makes no distinction between them in faith:"),
            .ayah("2:136"),
            .text("For a Jew or a Christian, becoming Muslim is not abandoning Moses or Jesus (peace be upon them) but following the messenger who came after them, and the Prophet promised such a person a double reward (Sahih Muslim 154, above)."),
            .door(.article("ProvingContinuationView")),
            .door(.article("ProvingJesusView")),
            .markdown("**What if I am convinced but still have doubts?**"),
            .text("A passing doubt is not disbelief. Companions came to the Prophet troubled by thoughts they found too grave to speak of, and he told them that this was clear faith (Sahih Muslim 132). Doubts are answered by knowledge, by asking those who know, and by supplication. There is no need to wait for every question to be settled before accepting what you already believe to be true; learning continues for a lifetime."),
        ]),
        ArticleSection("IN SUMMARY", [
            .text("A human origin would have left its marks: errors of its age, a motive, copied mistakes, tribal law, a drifting voice, a damaged text. The Quran shows none of them, and it shows instead fulfilled predictions, an unmet challenge and a message continuous with every prophet before it. Any one strand can be argued over; together they point to the explanation the Quran gives for itself, that it is revelation from the Lord of the worlds. The invitation that follows is made without compulsion: look honestly, ask sincerely, and when the truth is clear, bear witness to it."),
        ]),
        ArticleSection("KEY TERMS", [
            .term("Shahadah", arabic: "شَهَادَة", meaning: "The **testimony of faith**: bearing witness that there is no deity except Allah (Glorified and Exalted be He) and that Muhammad is the Messenger of Allah. From the root **ش-ه-د**, to be present and to witness."),
            .term("Islam", arabic: "إِسلَام", meaning: "**Submission** to Allah alone; from the root **س-ل-م**, soundness and peace. The Quran names it the religion in the sight of Allah (3:19), and uses the same word of Noah and of Abraham (10:72, 2:128)."),
            .term("Da‘wah", arabic: "دَعوَة", meaning: "The **invitation** to Allah; from the root **د-ع-و**, to call. The Quran commands that it be made with wisdom and good instruction (16:125), and without compulsion (2:256)."),
            .term("Hidayah", arabic: "هِدَايَة", meaning: "**Guidance**: being shown the way and helped to walk it. It is what the Prophet (peace and blessings be upon him) asked for in his night prayer (Sahih Muslim 770), and what every reader of the Quran asks for in al-Fatihah (1:6)."),
        ]),
    ]
}
