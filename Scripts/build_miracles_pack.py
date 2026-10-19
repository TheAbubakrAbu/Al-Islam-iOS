#!/usr/bin/env python3
"""Build Resources/Data/Islam/Miracles.json.xz from Tilawa's Miracles of the Quran capture.

    ./Scripts/build_miracles_pack.py [/path/to/Tilawa]

Tilawa (Jamil Hammoudeh, with permission) captured miracles-of-quran.com's 202 articles into
src/data/generated/miraclesEn.ts: the site waives copyright on its own prose, third-party excerpts
are trimmed to attributed quotes at import, Quran verses are references (drawn from our own text at
render time), and the images stay on Tilawa's CDN (https://miracles.tilawaai.app/). This script
lifts the English capture into the app's pack format unchanged: one object per article with its
slug, title, category, level and blocks.
"""
import json, lzma, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TILAWA = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT.parent / "Tilawa"
SRC = TILAWA / "src/data/generated/miraclesEn.ts"
OUT = ROOT / "Resources/Data/Islam/Miracles.json.xz"

CATEGORIES = [
    ("history", "simple"), ("egyptology", "simple"), ("zoology", "simple"),
    ("botany", "simple"), ("mathematics", "simple"),
    ("biology", "intermediate"), ("physiology", "intermediate"),
    ("geology", "intermediate"), ("hydrology", "intermediate"), ("meteorology", "intermediate"),
    ("embryology", "advanced"), ("chemistry", "advanced"),
    ("physics", "advanced"), ("astronomy", "advanced"), ("cosmology", "advanced"),
]


# Articles left out of the pack (2026-10-18 review, Abu: "make sure everything we have is islamically
# correct from a Sunni salafi angle"). Each was read against the ayah it cites, the app's own Saheeh
# International and Clear Quran text, and the tafsir of the Salaf (Ibn Kathir first). Withheld when
# the argument rests on numerology or letter/verse counting (abjad, "Code 19"), turns an ayah about
# the Day of Resurrection, a parable or a prophet's miracle into present-day natural science against
# the tafsir of the Salaf, describes the unseen (the heavens, angels, the Throne) in physical terms,
# or misstates the science or the history it leans on. slug -> (reason category, reason). Delete an
# entry to bring an article back; the build reports how many were withheld.
WITHHELD = {
    'abjad_numerals': ('numerology', 'Rests entirely on abjad (hisab al-jummal) letter values summed over Surah al-Masad: a gematria code with no basis in the Quran or Sunnah.'),
    'acid_rain': ('tafsir-twist', "Reads the hail-bearing 'mountains' in the sky (24:43) as meteors and the Smoke of 44:10-11 as the dinosaur-killing impact; the Smoke is the famine haze Quraysh saw (Ibn Mas'ud) or a sign before the Hour."),
    'aftershocks': ('tafsir-twist', "79:6-7 describes the first and second blasts of the Horn (the app's own Saheeh: 'the blast [of the Horn]'), not earthquake aftershocks."),
    'age_of_universe': ('aqeedah', "Speculates about the mass and clock rate of Allah's Throne and of Paradise and Hell, calls the Throne a mere 'reference', and gets a 1/3 ratio by misreading the days of 41:9-12: speculation about the unseen dressed as physics."),
    'amd': ('tafsir-twist', "50:22 says the denier's sight on that Day is sharp (hadid); the article reverses it into iron causing blurred vision in old age."),
    'amniotic_fluid': ('tafsir-twist', "'A fluid, ejected' (86:6) is the sperm-drop in every tafsir, not amniotic fluid; the 'three darknesses' point from 39:6 at the end is sound but does not save the article's main claim."),
    'antioxidants': ('overclaim', '55:68 names dates and pomegranates among the fruits of Paradise; it says nothing of antioxidants or heart attacks, and the claim that nobody knew dates had benefits is false.'),
    'armor_piercing': ('tafsir-twist', "55:35 is the flame and smoke (nuhas) sent upon jinn and men in the Hereafter; turning it into anti-tank shaped charges and a 'WW3' Muslim victory is invented prophecy."),
    'asthenosphere': ('pseudo-science', "Arsaha (79:32) means He set them firmly, not that they float, and the asthenosphere is solid rock that flows slowly, not the 'liquid' of the closer."),
    'atoms': ('tafsir-twist', 'Reads nawa (date stones, 6:95) as atomic nuclei and fatil and naqir (the thread and the speck of a date stone, 4:49 and 4:124) as vibrating strings; string theory is also unconfirmed.'),
    'axial_tilt': ('tafsir-twist', 'Defines the prostration of the sun, moon and earth (22:18) as axial tilt, which is takyif of an unseen act of worship.'),
    'bacteria': ('tafsir-twist', 'Musa was told to remove his sandals out of reverence for the sacred valley (Ibn Kathir), and the Prophet ﷺ prayed in his sandals, so the command is not about microbes.'),
    'base-19': ('numerology', "Rashad Khalifa's Code 19: converts the verse count to base 19 and ties it to the muqatta'at letters, while the 'nineteen' of 74:30 are the keepers of Hell, not a code."),
    'big_crunch': ('tafsir-twist', "Rereads 'it lays heavily upon the heavens and the earth' (7:187, the weight of the Hour and its hidden knowledge) as gravity, and presents a tentative 2024 DESI hint as having 'ruled out' the other endings of the universe."),
    'bioluminescence': ('tafsir-twist', "'He to whom Allah has not granted light' in 24:40 is the light of guidance in a parable of the disbeliever's deeds, not animal bioluminescence."),
    'calendar': ('overclaim', "18:25 gives the sleepers' stay in solar and lunar reckoning (300 solar years are about 309 lunar, as Ibn Kathir notes); it says nothing about which calendar was invented first, and that archaeology is contested."),
    'celsius': ('numerology', "Counts the verses between two occurrences of 'the silver' to produce 962, the melting point of silver in Celsius: a verse-counting code."),
    'chlorophyll': ('tafsir-twist', "In the parable of 18:45 the plants turn to dry stalks scattered by the wind; the article has the water itself becoming 'old plant' and evaporating, which the ayah does not say."),
    'cholesterol': ('tafsir-twist', "The ran upon hearts (83:14) is the stain of sins and the 'locks' of 47:24 are spiritual; the article turns both into oxidized cholesterol in arteries."),
    'cold_plasma': ('tafsir-twist', "Ibrahim's rescue (21:69) was a miracle in which Allah commanded a real fire to be cool and safe; reducing it to non-thermal plasma (which does not 'freeze things') naturalizes a prophet's sign."),
    'colors': ('tafsir-twist', "The white and black threads of 2:187 are the whiteness of dawn and the darkness of night, as the Prophet ﷺ explained to 'Adi ibn Hatim, not rod-cell colour vision."),
    'dark_energy': ('pseudo-science', "Says dark energy 'brought everything out of the cosmic singularity' and that the universe would otherwise have collapsed long ago (both wrong), then identifies it with the unseen pillars of 13:2 and with Allah's holding of the heavens in 35:41."),
    'day': ('tafsir-twist', "Yatlubuhu hathitha (7:54) means the night pursues the day swiftly (the app's Saheeh: 'chasing it rapidly'), not that days are getting longer."),
    'dead_sea': ('overclaim', "Adna al-ard (30:3) is 'the nearest land' to Arabia in the tafsir, and the Salaf placed the defeat at Adhri'at and Busra, not the Dead Sea; the real sign, the foretold Roman victory, does not need the 'lowest point' claim."),
    'dew': ('tafsir-twist', 'The same parable (2:265) turned into a rule that land without rain always gets dew, extended to the Atacama; the ayah speaks of one fertile garden on a hill.'),
    'digital_books': ('tafsir-twist', "Kitabun marqum (83:20) is a written, inscribed register, and 'witnessed by those brought near' refers to the angels; it is not a digitized book watched like a film."),
    'distance': ('numerology', "Makes verse and letter counts equal metres, kilometres, miles and 'centi light-years': counting coincidences in arbitrary units."),
    'dried_rivers': ('history-error', "'These rivers flowing beneath me' (43:51) is the boast of Musa's Pharaoh (the Nile and its canals), many centuries after the Old Kingdom pyramids and their long-dry Nile branch; the ayah does not mention pyramids."),
    'eardrum': ('tafsir-twist', "Waqr in 6:25 means heaviness, deafness (the app's Saheeh: 'in their ears deafness'), not a tear or crack, and it is deafness to guidance."),
    'earth': ('tafsir-twist', "Its proofs are false: kullun yajri does not imply three bodies, aqtar (55:33) are regions not diameters, and the spreading of 50:7 is made into planetary accretion; the earth's roundness is affirmed by the scholars, but not on these arguments."),
    'encoding': ('numerology', 'Equates letter counts in Surah an-Naml with its surah and verse numbers and reads 27:93 as foretelling the code: a letter-counting code.'),
    'equivalence_principle': ('tafsir-twist', "The mizan of 55:7 is the balance of justice Allah set, and raising the sky is not an 'accelerating frame': invented physics on a misread word."),
    'euler': ('numerology', "Derives Euler's number from '19 angels over 7 gates' (a Code 19 echo) and calls resurrection as 'impossible' as the square root of -1, which misstates the creed: resurrection is easy for Allah (30:27)."),
    'evolution': ('aqeedah', "Teaches that Adam came down to succeed earlier non-human 'Homo sapiens' who shed blood (misreading 2:30), reads 56:61 and 6:133 as evolution, and cites a creationist ICR piece on chromosome fusion: contrary to Adam's direct creation from clay, and unreliable science either way."),
    'exoplanets': ('tafsir-twist', "Reads 'and of the earth, the like of them' (65:12) as Earth-like planets in each heaven, while the sahih hadith speaks of seven earths beneath us."),
    'exoskeleton': ('tafsir-twist', "Hatm (27:18, 'crushed') is used of crushing anything; the crystal armour was found in a Central American leaf-cutter ant, not the ants of Sulayman's valley."),
    'fetal_development': ('tafsir-twist', "Reads 'then We produced him as another creation' (23:14), which Ibn Abbas and the Salaf explain as the breathing in of the soul, as facial features, and claims the face forms after bone and muscle, the reverse of embryology (the face takes shape from about week five, ossification begins around week seven)."),
    'fig': ('tafsir-twist', 'The oaths of 95:1-3 (the fig, the olive, Mount Sinai, this secure city of Makkah) are not a chronology of domestication or geology.'),
    'flash_flood': ('tafsir-twist', "'What they heat in the fire' (13:17) is metal smelted for ornaments and tools, which throws up scum like the flood's foam, not floating wood; and flash floods (sayl) were common in Arabia's wadis."),
    'flight': ('tafsir-twist', "29:22 says no one can escape Allah on earth or in the heaven, and 'stage after stage' (84:19) is a person's passage through life, death and resurrection (Ibn Abbas: state after state); neither foretells aircraft."),
    'fluorescence': ('tafsir-twist', "Reads the parable of Allah's light (24:35) as chlorophyll fluorescence of olive oil and 'light upon light' as the invisible spectrum; the parable is of guidance in the believer's heart."),
    'fossils': ('tafsir-twist', '37:143-144 is a counterfactual (he would have stayed in its belly until resurrection had he not been one who glorified Allah); it does not describe fossilized stomach contents.'),
    'frost_weathering': ('tafsir-twist', '2:74 describes rocks that split and let water out (springs), not water freezing and cracking rock; the frost mechanism is read in.'),
    'full_moon': ('pseudo-science', 'Reads an oath (84:16-18) as a claim that the full moon is seen only at night, which is false (it is often visible near sunrise or sunset), and argues against a flat-earth caricature of the Bible.'),
    'gravitational_waves': ('tafsir-twist', "52:9 describes the sky heaving on the Day of Judgment, and 'swimming' in 21:33 is reread as emitting gravitational waves."),
    'gravity': ('tafsir-twist', "Same reading as 'Big Crunch': thaqulat (7:187) made into gravity, the folding of the heaven (21:104) made into wormholes and spacetime curvature, and 'NASA ruled out the Big Rip' overstated."),
    'honey_bees': ('numerology', "Opens with a chromosome-count link to surah 16, likens drone bees (no father) to 'Jesus', and claims butuniha means 'several stomachs of one female bee', which is false (it is the ordinary pronoun for the bees' bellies)."),
    'human_senses': ('overclaim', "Its premise that the Quran 'always' puts hearing before sight is false (32:12 'we have seen and heard'; 18:26 'How Seeing is He and how Hearing'), and the eye and ear begin forming at about the same time."),
    'hydrogen': ('numerology', "Equates the Latin chemical symbol H with the Arabic letter ha' that ends the verses of Surah ash-Shams: a coincidence across two alphabets, not anything the Quran states."),
    'hydrogen_peroxide': ('tafsir-twist', "'My head has filled with white' (19:4) uses ishta'ala as a metaphor for spreading grey hair; it does not point to a flammable chemical."),
    'hydrothermal': ('tafsir-twist', "81:6 ('when the seas are filled with flame') is an event of the Day of Resurrection, not present-day hydrothermal vents."),
    'hypersonic': ('tafsir-twist', "In 27:39-40 the ifrit only offered; the throne was brought by 'one who had knowledge from the Scripture' before the glance returned; the article credits the jinn and invents an 8.3-minute sunlight delay to get Mach 26."),
    'hypoxia': ('tafsir-twist', 'Explains the blue eyes, entwined legs, blindness and choking of the Hereafter (20:102, 75:29, 20:124, 14:16-17, 88:6) as hypoxia; 75:29 is about the death throes, and the punishments of the Hereafter are not lab symptoms.'),
    'inner_ear': ('tafsir-twist', "'We cast [a cover of sleep] over their ears' (18:11) is the idiom for putting them to sleep, not blows that knocked them out."),
    'internal_mountains': ('tafsir-twist', "Fi al-ard (21:31) does not mean 'inside' the earth: 41:10 says Allah placed the mountains 'over its surface' (min fawqiha), and topography on the 660 km boundary is not what keeps the earth from shifting."),
    'iron': ('numerology', "Built on abjad values (hadid = 26 = iron's atomic number, al-hadid = 57 = the surah number) and a verse count of 5100 equated with kilometres to the core; Proving Islam's 'Iron Sent Down' section already makes the sound point carefully."),
    'islam_life_other_planets': ('aqeedah', "Claims Gog and Magog are trapped on another planet behind a 'wormhole', that the Isra' and Mi'raj used a wormhole, and that the creatures 'in the heavens' (42:29) are land animals, against the sahih hadith and the Salaf."),
    'isotropy': ('tafsir-twist', "'Neither of the east nor of the west' describes the olive tree of the parable in 24:35 (in the sun all day, per Ibn Abbas), not the isotropy of space."),
    'kelvin': ('numerology', "Equates the number of verses between the first and last mention of the sun with the sun's surface temperature in kelvin: a verse-counting code."),
    'keraunoparalysis': ('tafsir-twist', "Thamud were destroyed by the thunderbolt (51:44-45; 11:67 'they became within their homes corpses fallen prone'), not temporarily paralysed."),
    'light': ('tafsir-twist', "69:38-39 swears by 'what you see and what you do not see' (all things seen and unseen); the word light is not in the ayah."),
    'mass': ('tafsir-twist', 'Repeats the fatil-and-naqir-as-strings reading (4:49, 4:124: the thread and the speck of a date stone) to claim the Quran defines mass by string vibration.'),
    'meiosis': ('tafsir-twist', "The 'eight mates' of 39:6 are the four pairs of livestock (6:143-144), a clause separate from 'He creates you in the wombs'; the article fuses them into 'eight phases of meiosis'."),
    'meteorites': ('tafsir-twist', "52:44 describes the disbelievers' denial (they would call a falling fragment of the sky 'clouds heaped up'), not the ash of burning meteors."),
    'microburst': ('tafsir-twist', "22:31 is a parable of the one who commits shirk ('as though he had fallen from the sky... or the wind carried him down into a remote place'), not a downdraft hazard to aviation."),
    'milk': ('numerology', "Its second half is a letter-count code (88 letters between 'water' and 'milk' in 16:65-66 = cow's milk is 88% water); the first half on 16:66 is sound and could come back if that block is cut."),
    'mistranslations': ('tafsir-twist', "Its grammar is wrong (hatta is used with places, as in 18:90 and 27:18, and many place nouns are feminine), it dismisses the classical explanation that Dhul-Qarnayn saw the sun as if setting in a dark spring, and it says translators 'were translating the Hadeeth, not the original Quran'."),
    'moses': ('tafsir-twist', "Walidan in 26:18 simply means 'as a child' (the app's Saheeh); the Quran does not present it as the Egyptian meaning of Musa's name."),
    'mosquito': ('tafsir-twist', "'A mosquito or what is above it' (2:26) means something larger or smaller (the app's Saheeh: 'or what is smaller than it'), not a parasite riding on it, and the ta' of ba'udah marks a single mosquito, not a female."),
    'multi_star_system': ('tafsir-twist', "77:30-31 is the three-columned smoke of Hell, and the 'risings and settings' of 70:40 are the sun's daily points through the year; neither describes a triple-star system."),
    'mummy': ('overclaim', "Asserts that Pharaoh's body was 'found inland mummified', an identification no one has established (the app's own Proving Islam chapter says so), and misstates the Bible, which itself says the Egyptians were seen dead on the shore (Exodus 14:30)."),
    'neurons': ('tafsir-twist', "The skins' testimony (41:19-21) is speech Allah gives them ('Allah, who has made everything speak, made us speak'), not cellular 'memory' in the skin."),
    'noah': ('tafsir-twist', "Says the Flood was local and disbelievers elsewhere survived, against 71:26 ('do not leave upon the earth any disbeliever') and 37:77 ('his descendants the survivors'), misreads 11:48, and cites a 'fossilized ark found on Mount Judi in Yemen'."),
    'north': ('tafsir-twist', "18:17 describes the sun inclining away from the sleepers' cave on the right and passing them on the left; it says nothing about facing north or map conventions."),
    'orographic_effect': ('tafsir-twist', '2:265 is a parable of a garden on high ground that yields with a downpour or even a drizzle; it does not say high ground gets more rain or that other ground gets dew.'),
    'paper_money': ('tafsir-twist', "Wariq (18:19) is minted silver (the app's Saheeh: 'this silver coin of yours'), not paper money."),
    'petra': ('history-error', "Al-Hijr of 15:80 is the land of Thamud that the Prophet ﷺ passed on the way to Tabuk (Hegra, Mada'in Salih), not Petra in Jordan, a later Nabataean city; a stele bearing 'Allah' does not show they were 'warned'."),
    'pi': ('numerology', "Equates the abjad value of al-ruj'a (96:8) with pi in 'centiradians': gematria."),
    'planetary_orbits': ('tafsir-twist', "Claims kullun yajri (39:5) must mean three or more bodies, which is false (kull covers two, and the ayah names the sun and moon), and reads raj' in 86:11, the returning rain, as orbits."),
    'planets': ('tafsir-twist', "82:2 ('when the stars fall, scattering') is an event of the Day of Resurrection, not rogue planets roaming today."),
    'pompeii': ('tafsir-twist', '36:67 warns that Allah could have deformed them in their places in this world; the article moves it to Hell and pairs it with the victims of Pompeii.'),
    'prime_numbers': ('numerology', "Treats word and letter totals (2699 occurrences of 'Allah', 326159 letters) as a primality code proving preservation; the totals depend on counting conventions and the method is the rejected numerical-miracle genre."),
    'prostrations': ('tafsir-twist', '17:107 praises the learned among the People of the Book who fall on their faces (li-l-adhqan) in prostration; linking it to pagan Egyptian priests rests only on an unsourced image.'),
    'pulsar_navigation': ('tafsir-twist', '16:16 states that people guide themselves by the stars, as the Arabs did; reading it as X-ray pulsar navigation, and claiming stars give no fixed direction, is false.'),
    'pulsars_black_holes': ('tafsir-twist', "An-najm ath-thaqib (86:3) is the star that pierces the darkness with its light (Ibn Abbas, Mujahid), not a pulsar 'making a hole in spacetime'."),
    'pumice': ('tafsir-twist', "Sijjil (105:4, 15:74) is baked clay (the app's Saheeh: 'stones of hard clay'); the article turns the stones into pumice and the punishment of Lut's people into a volcano, naturalizing a sign from Allah."),
    'pupil': ('tafsir-twist', "'That which deceives the eyes' (40:19) is the stealthy glance that Allah sees (Ibn Abbas), not pupil dilation, which is not a reliable sign of lying anyway."),
    'pyramids': ('pseudo-science', "Rests on the fringe 'cast limestone' theory of the pyramids, which Egyptologists and geologists reject, and applies Pharaoh's baked-brick tower (28:38) to Old Kingdom pyramids built about a thousand years earlier."),
    'pyritized_fossils': ('tafsir-twist', '17:50 is a challenge (be stone or iron, Allah will still raise you), not a description of pyritized fossils; pyrite is iron sulphide, not iron.'),
    'raptors': ('tafsir-twist', 'Same parable of shirk (22:31) read as a lesson on how raptors seize prey; falconers in Arabia knew raptors seize with their talons, so the premise is false too.'),
    'rayleigh_scattering': ('tafsir-twist', "70:8 describes the sky on the Day of Judgment 'like murky oil'; it says nothing about the sky's true colour now."),
    'reading': ('tafsir-twist', "96:1-5 says Allah taught by the pen what man did not know; it says nothing of brains 'prewired' to read before birth."),
    'red_giant': ('tafsir-twist', '75:9 (sun and moon joined) is a sign of the Day of Resurrection, which comes suddenly; tying it to a red giant five billion years away misreads it and implies a date for the Hour.'),
    'redshifting': ('tafsir-twist', "55:37 (the heaven split open, rose-red like oil) is the Day of Resurrection, read here as today's cosmic expansion and redshift."),
    'rust': ('tafsir-twist', "Qitr in 18:96 is molten copper (the app's Saheeh), not tar; the rust-prevention claim rests on the mistranslation."),
    'sea_breeze': ('tafsir-twist', "'By the dawn when it breathes' (81:18) is a metaphor for daybreak, not the reversal of sea and land breezes."),
    'seven_heavens': ('aqeedah', "Makes the seven heavens six extra string-theory dimensions holding dark matter, puts 'the angels on your shoulders in the seventh heaven', gives the jinn detectable 'weight', and redefines futur (67:3) as 'creation out of nothing': speculation about the unseen and false lexicon."),
    'shape_of_universe': ('tafsir-twist', "Aqtar (55:33) are regions (the app's Saheeh: 'the regions of the heavens and the earth'), not diameters, and 79:28 and 86:11 are bent the same way into a closed spherical universe."),
    'shorelines': ('tafsir-twist', "'Reducing it from its borders' (13:41) is explained by the Salaf as lands being conquered or the passing of their people and scholars, not sea-level rise from global warming."),
    'singularity': ('aqeedah', "Ties Allah's name al-Ahad to the singularity of a black hole and says the 'positions of the stars carry His name': likening a divine Name to a point where physics breaks down is a grave error in the Names and Attributes."),
    'sirius': ('numerology', "Equates a letter count in Surah an-Najm with Sirius's distance in 'centi light-years' and the ratio of two surah numbers with its radius: a counting code."),
    'skydiving': ('tafsir-twist', 'Same parable of shirk (22:31) read as a forecast of skydiving.'),
    'solar_energy': ('tafsir-twist', "Taqriduhum (18:17) means the sun 'passes away from them' (qarada: to turn aside from), not that it lends them a loan; the conservation-of-energy reading rests on the wrong sense."),
    'solar_flare': ('tafsir-twist', "77:32-33 describes the sparks of Hell 'like yellow camels', not coronal mass ejections from the sun."),
    'sound_waves': ('tafsir-twist', "The answer of the heavens and earth, 'We have come willingly' (41:11), is their obedience to Allah's command, real speech Allah gave them; it is not the acoustic waves of the early universe."),
    'spacetime': ('tafsir-twist', 'The prostration of the stars and trees (55:6) is real worship whose manner Allah knows; defining it as spacetime curvature is takyif of the unseen.'),
    'speed_of_light': ('aqeedah', "Says the angels take their orders from a Preserved Tablet 'somewhere in outer space, and not from God's Throne', turning 'then it will ascend to Him' (32:5) away from Allah, and derives the speed of light from a lunar-orbit conversion."),
    'sperm': ('tafsir-twist', "Amshaj (76:2) is the mixture of the man's and the woman's fluids (Ibn Abbas), not 'non-unique sperm', and the claim that each egg carries the same set of chromosomes is false (eggs also recombine in meiosis)."),
    'starlight': ('tafsir-twist', "77:8 ('when the stars are obliterated') is the Day of Judgment, not stellar evolution into faint remnants."),
    'stars_wobble': ('tafsir-twist', "'The sun runs to its resting place' (36:38) says nothing about barycentric wobble; the 'vertical component of running' is invented, and the Prophet ﷺ explained the sun's course with its prostration beneath the Throne."),
    'steam_explosions': ('tafsir-twist', "82:3 ('when the seas are erupted') is the Day of Resurrection, not lava meeting the sea."),
    'string_theory': ('aqeedah', "Repeats the 'Seven Heavens' dark-matter and extra-dimension reading of the heavens, angels and jinn, and the fatil/naqir-as-strings reading of 4:49 and 4:124 (the thread and speck of a date stone)."),
    'subduction': ('tafsir-twist', "'Some of them fall down for fear of Allah' (2:74) is stones falling in real fear of Allah, not plates subducting 400 km into the mantle."),
    'sunlight': ('tafsir-twist', "81:1 ('when the sun is wrapped up [in darkness]') describes the end, yet is read as the sun's formation, and 'We erased the sign of the night' (17:12, the dark face of the moon per Ibn Abbas) as a sunless early solar system."),
    'superionic_water': ('tafsir-twist', '18:29 describes the drink of the people of Hell; explaining it as high-pressure superionic ice naturalizes a punishment of the Hereafter.'),
    'tectonics': ('tafsir-twist', "27:88 follows 'the Day the Horn will be blown' (27:87): the mountains passing like clouds is on the Day of Resurrection, not plate tectonics."),
    'terminal_velocity': ('tafsir-twist', 'Same parable of shirk (22:31) read as falcons overtaking skydivers at terminal velocity.'),
    'tidal_locking': ('pseudo-science', '25:45 says Allah could have made the shadow still had He willed, a statement of His power, not a forecast; and the claim that Earth will tidally lock to the sun ignores that the sun will change long before.'),
    'time_dilation': ('aqeedah', "Pictures angels crossing wormholes 'flapping their wings in slow motion, reddish in color and very dim': takyif of the unseen, while the Salaf explain the fifty-thousand-year Day of 70:4 as the Day of Resurrection."),
    'ubar': ('history-error', "Confuses Ubar (in Oman, the city linked to 'Ad) with Saba's Ma'rib dam in Yemen, which is what 34:15-16 describes; the 'excavated city' the strongest list promises is not in the article."),
    'vagus_nerve': ('aqeedah', "Turns 'We are closer to him than his jugular vein' (50:16) into the vagus nerve; the Salaf explain the nearness as that of Allah's angels (and His knowledge), and the ayah concerns Allah, not anatomy."),
    'venus': ('tafsir-twist', "Kawkab in Quranic Arabic is a star or shining heavenly body (12:4, 37:6), not 'planet' in the modern sense, and 6:76 does not name Venus."),
    'viscosity': ('overclaim', 'Reads the rivers of Paradise (47:15) as a viscosity ranking, though Paradise shares only names with this world (Ibn Abbas), and the order claimed is not even right (milk is usually thicker than wine).'),
    'vision': ('tafsir-twist', "15:14-15 says the stubborn would call even an ascent through a gate of heaven sorcery ('our eyes have been dazzled'); it is not about astronauts' eyesight, and the 'wormhole' is invented."),
    'volcano': ('tafsir-twist', '99:1-2 is the final earthquake of the Hour and the earth casting out its burdens (its dead), not volcanoes erupting after tremors.'),
    'water': ('numerology', "Reads 'rain settled in the earth' (23:18) and the hail-bearing 'mountains' of 24:43 as comets, then closes with a word-count ratio (sea 32 times, land 13 times = 71% of the surface)."),
    'weathering_erosion': ('tafsir-twist', 'In the parable of 2:264 the downpour leaves the smooth stone bare by washing off its dust (the charity voided by reminders); it does not describe rain polishing rock.'),
    'wind': ('tafsir-twist', "In 69:7 it is the people of 'Ad who lie fallen 'as if they were hollow trunks of palm trees' (the app's Saheeh); the article misreads the simile as wind snapping trees."),
    'work': ('tafsir-twist', "99:7-8 is about the weighing of deeds; reading 'amal as physical work (weight times displacement) is a pun, not a meaning."),
    'wormholes': ('aqeedah', "Declares the ma'arij of 70:3 to be wormholes, the Mi'raj a wormhole trip and the way to Paradise a wormhole, presented as what 'Muslims know': speculation about the unseen."),
}

# Kept articles with one sentence or block that does not hold (same review): (slug, text found in the
# block, replacement for that text, or None to drop the whole block).
BLOCK_EDITS = [
    ("gender", "The verse number 46 is the same number of total chromosomes humans have; 23 chromosomes from the father and 23 chromosomes from the mother = 46 chromosomes in total.", ""),
    ("pharaoh", "In Quran 12:54: 12 + 54 = 66.", None),
    ("expanding_universe", "Einstein gave the Bible the benefit of the doubt", None),
    ("plant_stress", "growweedeasy", None),
]

# The capture glued each excerpt's own page/section heading onto the front of the quote with no
# separator, so the reader saw "PetraPetra is believed to have been settled..." and, on 98 quotes,
# a word repeated or a stray heading run into the first sentence (Abu, 2026-09-19).
#
# The heading is a Title Case run at position 0 butted directly against the next capital letter.
# 88 of the 98 name something the `sourceLabel` already says ("Camels" under "Wikipedia, Camel"),
# so those are simply dropped. The other 10 name a SUBSECTION the label does not ("Abstract" under
# an Oxford Academic paper, "Work by gravity" under "Work (physics)") - those are kept and folded
# into the label as "<label> - <heading>", so nothing is lost and nothing reads as a typo.
GLUED_HEADING = re.compile(r"^((?:[A-Z][a-z'\u2019]+)(?:[ \-][A-Z]?[a-z'\u2019]+){0,3})(?=[A-Z])")


def unglue_quote_headings(articles):
    """Split a run-on heading off the front of every quote. Returns how many were repaired."""
    repaired = 0
    for article in articles:
        for block in article.get("blocks", []):
            if block.get("kind") != "quote":
                continue
            match = GLUED_HEADING.match(block.get("text", ""))
            if not match:
                continue
            heading = match.group(1)
            label = block.get("sourceLabel", "")
            block["text"] = block["text"][len(heading):].lstrip()
            if heading.lower() not in label.lower():
                block["sourceLabel"] = f"{label} - {heading}" if label else heading
            repaired += 1
    return repaired


def apply_review(articles):
    """Drop WITHHELD articles, apply BLOCK_EDITS, and unlink kept articles' links to withheld ones."""
    missing = [slug for slug in WITHHELD if slug not in {a["slug"] for a in articles}]
    assert not missing, f"WITHHELD names articles the capture no longer has: {missing}"
    kept = [a for a in articles if a["slug"] not in WITHHELD]
    edited = 0
    for slug, needle, replacement in BLOCK_EDITS:
        article = next(a for a in kept if a["slug"] == slug)
        hits = [b for b in article["blocks"]
                if needle.lower() in (b.get("text", "") + " " + b.get("sourceUrl", "") + " " + b.get("sourceLabel", "")).lower()]
        assert len(hits) == 1, f"BLOCK_EDITS {slug!r}: {needle[:40]!r} matches {len(hits)} blocks"
        if replacement is None:
            article["blocks"].remove(hits[0])
        else:
            text = hits[0]["text"]
            assert text.count(needle) == 1, f"BLOCK_EDITS {slug!r}: text not found exactly once"
            hits[0]["text"] = re.sub(r"\n{3,}", "\n\n", text.replace(needle, replacement)).strip()
        edited += 1
    unlinked = 0
    for article in kept:
        for block in article["blocks"]:
            links = block.get("links")
            if links:
                block["links"] = [l for l in links if l.get("slug") not in WITHHELD]
                unlinked += len(links) - len(block["links"])
                if not block["links"]:
                    del block["links"]
    return kept, len(articles) - len(kept), edited, unlinked


def main():
    text = SRC.read_text(encoding="utf-8")
    start = text.index("= [", text.index("MIRACLES_EN")) + 2
    end = text.rindex("];") + 1
    articles = json.loads(text[start:end])
    assert all(a["category"] in dict(CATEGORIES) for a in articles), "unknown category"
    unglued = unglue_quote_headings(articles)
    articles, withheld, edited, unlinked = apply_review(articles)
    media = sum(1 for a in articles for b in a["blocks"] if b["kind"] == "image")
    quotes = sum(1 for a in articles for b in a["blocks"] if b["kind"] == "quote")
    ayahs = sum(1 for a in articles for b in a["blocks"] if b["kind"] == "ayah")
    pack = {
        "version": 1,
        "source": "miracles-of-quran.com, captured 2026-09-06 by Tilawa (scripts/miracles-import.mjs)",
        "imageBase": "https://miracles.tilawaai.app/",
        "categories": [{"id": c, "level": l} for c, l in CATEGORIES],
        "articles": articles,
    }
    raw = json.dumps(pack, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_bytes(lzma.compress(raw, format=lzma.FORMAT_XZ, preset=9 | lzma.PRESET_EXTREME))
    print(f"unglued {unglued} run-on quote headings; withheld {withheld} articles, edited {edited} blocks, "
          f"unlinked {unlinked} links to withheld articles")
    print(f"{len(articles)} articles, {ayahs} ayah blocks, {quotes} quotes, {media} images; "
          f"{len(raw):,} bytes raw -> {OUT.stat().st_size:,} bytes xz -> {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
