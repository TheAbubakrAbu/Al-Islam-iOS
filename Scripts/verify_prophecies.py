#!/usr/bin/env python3
"""Verify every hadith citation in the Prophecies / Miracles of the Prophets source lists against
THIS APP'S OWN hadith corpus, before any of it is written into an article.

    python3 Scripts/verify_prophecies.py            # check the candidate list
    python3 Scripts/verify_prophecies.py --grades   # also print every grade line found

Why this exists: the four source sites cite the same hadith in four different numbering schemes
(Yaqeen's "Ṣaḥīḥ al-Bukhārī 4:197, no. 3595" is a volume:page plus number; Proving Islam's "Vol. 9,
Book 88, Hadith 203" is the old USC/MSA scheme; islamreligion often gives no number at all). Our
`.hpk` packs are keyed on the modern single-number citation that sunnah.com uses. So every claim has
to be resolved to a row in OUR packs and read there - the app's rule is that Arabic and English come
from our own corpus, never retyped from a website (see Scripts/islam_packs.py).

The policy this enforces (Abu's standing rule, see the islamic-content-standards memory):
  * sahih or hasan only - anything our packs grade da'if/munkar/mawdu' is DROPPED, not softened;
  * a citation we cannot locate in our corpus is DROPPED unless it is in one of the two Sahihs,
    where a missing row means our pack's numbering differs, not that the hadith is unsound;
  * Bukhari and Muslim rows carry no grade line in our packs (they are sahih by the collections'
    own criterion), so an empty grade list there is a PASS, not an unknown.
"""
import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from islam_packs import Hadith, is_weak  # noqa: E402

SOUND = re.compile(r"sahih|hasan|صحيح|حسن", re.I)


def verdict(grades):
    """sahih/hasan, weak, or unknown - by the WEIGHT of the grade lines, not by any single one.

    Our packs carry up to five graders per row and they disagree: "holding to one's religion like a
    burning coal" (Tirmidhi 2260) is Sahih to Ahmad Shakir and al-Albani, Hasan to Darussalam, and
    Da'if only to Zubair Ali Zai. A rule of "any weak grade drops it" would have thrown out a hadith
    the majority of graders authenticate; a rule of "any sound grade keeps it" would keep genuinely
    weak ones that a single lenient grader passed. So: sound when the sound graders are a MAJORITY,
    weak when they are not, unknown when nobody graded it.

    The two Sahihs are the exception - their rows carry no grade lines at all, because inclusion in
    Bukhari or Muslim IS the grade. An empty list there is a pass.
    """
    if not grades:
        return "sahih-by-collection"
    sound = sum(1 for g in grades if SOUND.search(g[1]) and not is_weak([g]))
    weak = sum(1 for g in grades if is_weak([g]))
    if sound == 0 and weak == 0:
        return "unknown"
    return "sound" if sound > weak else "weak"

# (key, book slug, citation as OUR packs number it, what the prophecy/miracle is)
# Citations were cross-walked by hand from the four sources' own schemes to sunnah.com numbering,
# then every one of them is read back out of our packs below.
PROPHECIES = [
    # --- Conquests and the shape of the early state
    ("security-hira", "bukhari", "3595", "A woman would travel alone from al-Hira to the Kaaba fearing none but Allah; the treasures of Chosroes would be opened"),
    ("six-signs", "bukhari", "3176", "Six signs before the Hour: his death, Jerusalem's conquest, a plague, surplus wealth, a tribulation, a broken truce"),
    ("end-of-empires", "bukhari", "3618", "When Chosroes and Caesar perish, there will be no Chosroes or Caesar after them"),
    ("persia-treasures", "muslim", "2918", "The treasures of Chosroes' white palace would be opened to the Muslims"),
    ("egypt-conquest", "muslim", "2543", "You will conquer Egypt; be good to its people, for they have kinship and protection"),
    ("badr-places", "muslim", "1779", "He marked the ground where each Meccan leader would fall at Badr; none fell elsewhere"),
    ("mutah-martyrs", "bukhari", "1246", "He announced the deaths of Zayd, Ja'far and Ibn Rawahah at Mu'tah, 600 miles away, as they happened"),
    ("tabuk-wind", "bukhari", "1481", "A violent wind would strike that night at Tabuk; a man who stood was carried off"),
    ("umm-haram-sea", "bukhari", "2924", "Umm Haram would ride the first naval expedition, but not the campaign against Constantinople"),
    ("uhud-martyrs", "bukhari", "3675", "Uhud, on which stood a prophet, a truthful one and two martyrs ('Umar and 'Uthman)"),
    ("uthman-shirt", "tirmidhi", "3705", "'Uthman would be asked to take off the shirt Allah clothed him with, and must not"),
    ("hasan-reconciles", "bukhari", "3629", "This son of mine is a chief; Allah will reconcile two great parties of Muslims through him"),
    ("ammar-killed", "bukhari", "447", "'Ammar would be killed by the transgressing party"),
    ("khawarij", "bukhari", "3610", "A people would recite the Quran without it passing their throats and leave the religion as an arrow leaves the prey"),
    ("umaya-badr", "bukhari", "3632", "Umayyah ibn Khalaf would be killed despite his precautions"),
    ("uwais", "muslim", "2542", "Uwais al-Qarani would come with the reinforcements of Yemen; ask him to seek forgiveness for you"),
    ("thaqif-liar", "muslim", "2545", "From Thaqif will come a great liar and a great destroyer"),
    ("hatib-letter", "bukhari", "3007", "A woman would be carrying a letter at Rawdah Khakh; she was found with it"),
    ("khaybar-jews", "bukhari", "2338", "The Jews of Khaybar would remain only as long as Allah kept them there"),
    ("false-prophets", "bukhari", "7121", "Thirty liars would arise, each claiming to be a prophet"),
    ("hudaybiyah-dream", "bukhari", "2731", "He would enter the Sacred Mosque in safety, heads shaved"),
    ("caliphate-thirty", "abudawud", "4646", "The caliphate of prophethood would last thirty years, then kingship"),
    # --- Later history and the end times
    ("fire-hijaz", "bukhari", "7118", "A fire would come out of the land of Hijaz, lighting the necks of camels at Busra"),
    ("arabia-meadows", "muslim", "157", "The Hour will not come until the land of the Arabs is again meadows and rivers"),
    ("shepherds-buildings", "muslim", "8", "Barefoot, naked shepherds would compete in raising tall buildings"),
    ("charity-refused", "bukhari", "1424", "A man will go about with charity and find no one to accept it"),
    ("knowledge-taken", "bukhari", "100", "Knowledge would be taken by the death of the scholars, and ignorant leaders would give verdicts"),
    ("clothed-naked", "muslim", "2128", "Women clothed yet naked, their heads like the humps of camels"),
    ("nations-dish", "abudawud", "4297", "Nations would call one another to devour you as diners call one another to a dish"),
    ("mosques-adorned", "abudawud", "449", "People would boast to one another about their mosques"),
    ("time-shortens", "bukhari", "1036", "Time would pass quickly, knowledge would be taken, and killing would increase"),
    ("killing-increase", "bukhari", "7061", "The Hour will not come until killing increases, the killer not knowing why he killed"),
    ("quran-only", "tirmidhi", "2663", "A man reclining on his couch would say: follow only what is in the Quran"),
    ("victorious-group", "bukhari", "3641", "A group of my nation would remain victorious upon the truth"),
    ("holding-coal", "tirmidhi", "2260", "A time would come when holding to one's religion is like holding a burning coal"),
    ("wish-grave", "bukhari", "7115", "A man would pass by a grave and wish he were in the place of its occupant"),
    ("unknown-diseases", "ibnmajah", "4019", "Sexual immorality never appears among a people until plagues appear that were not known to their predecessors"),
    ("obesity", "bukhari", "2651", "Then there would come a people who grow fat and love fatness"),
    ("unqualified-authority", "bukhari", "59", "When authority is given to those unfit for it, expect the Hour"),
    ("twelve-caliphs", "muslim", "1821", "This affair will not end until twelve caliphs have passed, all of them from Quraysh"),
    ("dajjal-sermon", "muslim", "2891", "He stood and told them of everything that would happen until the Hour; those who remembered it recognised it as it came"),
    ("ali-khawarij", "muslim", "1066", "A people would come out at a time of division among the Muslims, and the nearer of the two parties to the truth would kill them"),
    ("sun-west", "bukhari", "4636", "The Hour will not be established until the sun rises from the west"),
]

# Miracles of the Prophet Muhammad: the physical signs, for the second library.
MIRACLES = [
    ("moon-split", "bukhari", "3636", "The moon split in two at Mina before the Quraysh"),
    ("water-fingers", "bukhari", "3576", "Water flowed from between his fingers until the whole company had drunk and made wudu"),
    ("weeping-trunk", "bukhari", "3584", "The date-palm trunk he used to lean on wept aloud when he moved to the new pulpit"),
    ("food-trench", "bukhari", "4102", "A little barley and a lamb fed the whole army at the Trench"),
    ("food-multiply", "bukhari", "3578", "A small amount of food fed eighty men and was left over"),
    ("pebbles-tasbih", "bukhari", "3579", "Provision and water multiplied in his hands"),
    ("rain-dua", "bukhari", "1013", "He prayed for rain and it came before he left the pulpit, and stopped at his word"),
    ("night-journey", "bukhari", "3887", "The night journey to Jerusalem and the ascension"),
    ("isra-described", "bukhari", "4710", "He described Jerusalem to the Quraysh as they questioned him"),
    ("abu-hurayra-mother", "muslim", "2491", "He prayed for Abu Hurayrah's mother and she accepted Islam that hour"),
    ("ibn-abbas-dua", "bukhari", "143", "He prayed that Ibn 'Abbas be given understanding of the Book"),
    ("anas-dua", "bukhari", "6334", "He prayed for Anas to be given abundant wealth and children"),
]


def check(rows, label, show_grades=False):
    print(f"\n{'=' * 78}\n{label}\n{'=' * 78}")
    ok, missing, weak = [], [], []
    for key, slug, citation, what in rows:
        try:
            items = Hadith(slug).find(citation)
        except Exception as exc:  # pack missing entirely
            missing.append((key, slug, citation, f"pack error: {exc}"))
            continue
        if not items:
            missing.append((key, slug, citation, "no row with that citation"))
            continue
        item = items[0]
        call = verdict(item.grades)
        bad = call in ("weak", "unknown")
        status = "WEAK" if call == "weak" else ("?" if call == "unknown" else "ok")
        if bad:
            weak.append((key, slug, citation, item.grades or call))
        else:
            ok.append((key, slug, citation))
        english = " ".join(item.text.split())[:90]
        print(f"[{status:4}] {slug} {citation:6} {key}")
        print(f"         {english}...")
        if show_grades and item.grades:
            for g in item.grades:
                print(f"         grade: {g}")
    print(f"\n  {len(ok)} usable, {len(weak)} weak (DROP), {len(missing)} not found (re-cite or DROP)")
    for key, slug, citation, why in missing:
        print(f"    MISSING  {slug} {citation:8} {key}: {why}")
    for key, slug, citation, bad in weak:
        print(f"    WEAK     {slug} {citation:8} {key}: {bad}")
    return ok, weak, missing


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--grades", action="store_true")
    args = parser.parse_args()
    check(PROPHECIES, "PROPHECIES", args.grades)
    check(MIRACLES, "MIRACLES OF THE PROPHET", args.grades)


if __name__ == "__main__":
    main()
