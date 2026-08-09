"""Stage 3: bundle per-riwayah tajweed annotations + page maps into the
raw-deflate packs the app ships (same encoding as the QiraahBeta files).

Reads  out/<key>-{annotations,pagemap,meta}.json  (stage-2 v3 output)
Writes Resources/Data/Quran/Tajweed<Name>.json.deflate

Pack shape:
{
  "v": 1,
  "legend": [{"c":"m","ar":"...","en":"..."}, ...],  # this edition's rules
  "rules": {"2": {"12": {"3": "m"}}},   # surah -> ayah -> wordIdx -> rule
  "pages": {"2": {"12": 50}},           # surah -> ayah -> page (1..604)
  "khilafMarkers": {"2": [143]}         # ayah medallions ringed magenta
}
Rule letters: r red, b blue, m magenta, c cyan, o orange, g green,
l royal blue, y olive -- meanings are PER EDITION (from each PDF's printed
legend); only colors in the edition's legend are packed, the rest is noise.
"""
import sys, os, json, zlib

BASE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(BASE, 'out')
DEST = os.path.normpath(os.path.join(BASE, '../../Resources/Data/Quran'))

NAMES = {
    'susi': 'TajweedSusi', 'duri': 'TajweedDuri', 'warsh': 'TajweedWarsh',
    'qaloon': 'TajweedQaloon', 'bazzi': 'TajweedBazzi', 'qunbul': 'TajweedQunbul',
    'shubah': 'TajweedShubah', 'hisham': 'TajweedHisham',
    'ibndhakwan': 'TajweedIbnDhakwan', 'khalaf': 'TajweedKhalaf',
    'khallad': 'TajweedKhallad', 'abuharith': 'TajweedAbuHarith',
    'durikisai': 'TajweedDuriKisai', 'ibnwardan': 'TajweedIbnWardan',
    'ibnjammaz': 'TajweedIbnJammaz', 'ruways': 'TajweedRuways',
    'rawh': 'TajweedRawh', 'ishaq': 'TajweedIshaq', 'idris': 'TajweedIdris',
}
LETTER = {'red': 'r', 'blue': 'b', 'magenta': 'm', 'cyan': 'c', 'orange': 'o',
          'green': 'g', 'royal': 'l', 'olive': 'y'}

# Rule label vocabulary (Arabic transcribed from the printed legends).
L = {
    'khilaf_harf': {'ar': 'الحرف المخالف لحفص', 'en': 'Letter differing from Ḥafṣ'},
    'khilaf_word': {'ar': 'الكلمة المخالفة لحفص', 'en': 'Word differing from Ḥafṣ'},
    'idgham': {'ar': 'الإدغام', 'en': 'Idghām (merging)'},
    'imalah': {'ar': 'الإمالة', 'en': 'Imālah (vowel inclination)'},
    'imalah_taqlil': {'ar': 'الإمالة والتقليل', 'en': 'Imālah & Taqlīl'},
    'taqlil': {'ar': 'التقليل', 'en': 'Taqlīl (slight inclination)'},
    'silah_meem': {'ar': 'صلة ميم الجمع', 'en': 'Ṣilat mīm al-jamʿ'},
    'ha_dhamir': {'ar': 'هاء الضمير المخالفة لحفص', 'en': 'Pronoun hāʾ differing from Ḥafṣ'},
    'sakt': {'ar': 'السكت', 'en': 'Sakt (brief silence)'},
    'ishmam_sad': {'ar': 'إشمام الصاد صوت الزاي', 'en': 'Ṣād blended toward zāy'},
    'ghunnah_kha_ghayn': {'ar': 'الغنة مع الخاء والغين', 'en': 'Ghunnah with khāʾ/ghayn'},
    'madd_badal': {'ar': 'مد البدل', 'en': 'Madd al-badal'},
    'madd_leen': {'ar': 'مد اللين', 'en': 'Madd al-līn'},
    'raa_muraqqaqah': {'ar': 'الراءات المرققة', 'en': 'Light (muraqqaq) rāʾ'},
    'lam_mughallazah': {'ar': 'اللامات المغلظة', 'en': 'Heavy (mughallaẓ) lām'},
}

# Per-edition legend: rule letter -> label key, in display order.
# Transcribed from each PDF's printed legend box (pair-mates share editions).
EDITION_LEGEND = {
    'shubah': [('m', 'khilaf_harf'), ('b', 'idgham')],
    # qaloon's edition prints no legend; magenta = the khilaf-word highlight
    'qaloon': [('m', 'khilaf_word')],
    'warsh': [('m', 'khilaf_harf'), ('b', 'idgham'), ('r', 'taqlil'),
              ('c', 'madd_badal'), ('g', 'raa_muraqqaqah'), ('l', 'lam_mughallazah'),
              ('o', 'silah_meem'), ('y', 'madd_leen')],
    'bazzi': [('m', 'khilaf_harf'), ('b', 'ha_dhamir'), ('r', 'silah_meem')],
    'qunbul': [('m', 'khilaf_harf'), ('b', 'ha_dhamir'), ('r', 'silah_meem')],
    'duri': [('m', 'khilaf_word'), ('b', 'idgham'), ('r', 'imalah_taqlil')],
    'susi': [('m', 'khilaf_word'), ('b', 'idgham'), ('r', 'imalah_taqlil')],
    'hisham': [('m', 'khilaf_harf'), ('b', 'idgham'), ('r', 'imalah')],
    'ibndhakwan': [('m', 'khilaf_harf'), ('b', 'idgham'), ('r', 'imalah')],
    'khalaf': [('m', 'khilaf_word'), ('b', 'idgham'), ('r', 'imalah'),
               ('c', 'sakt'), ('o', 'ishmam_sad')],
    'khallad': [('m', 'khilaf_word'), ('b', 'idgham'), ('r', 'imalah'),
                ('c', 'sakt'), ('o', 'ishmam_sad')],
    'abuharith': [('m', 'khilaf_harf'), ('b', 'idgham'), ('r', 'imalah'), ('o', 'ishmam_sad')],
    'durikisai': [('m', 'khilaf_harf'), ('b', 'idgham'), ('r', 'imalah'), ('o', 'ishmam_sad')],
    'ibnwardan': [('m', 'khilaf_harf'), ('b', 'idgham'), ('r', 'silah_meem'), ('c', 'ghunnah_kha_ghayn')],
    'ibnjammaz': [('m', 'khilaf_harf'), ('b', 'idgham'), ('r', 'silah_meem'), ('c', 'ghunnah_kha_ghayn')],
    'ruways': [('m', 'khilaf_harf'), ('b', 'idgham'), ('r', 'imalah')],
    'rawh': [('m', 'khilaf_harf'), ('b', 'idgham'), ('r', 'imalah')],
    'ishaq': [('m', 'khilaf_harf'), ('b', 'idgham'), ('r', 'imalah')],
    'idris': [('m', 'khilaf_harf'), ('b', 'idgham'), ('r', 'imalah')],
}

# ---- rule-shape validators: several rules can only sit on words of a known
# shape (silat mim al-jam' ends with mim, ishmam needs a sad, ...). A flagged
# word failing its shape is a +-1-word attribution slip -> drop it rather
# than paint the wrong word. Letter checks are on BASE letters only.
import unicodedata
def bases(word):
    return [ch for ch in word if 0x621 <= ord(ch) <= 0x64A or ch in 'ٱٰ']
def ends_with(word, letters):
    b = bases(word)
    return bool(b) and b[-1] in letters
def contains(word, letters):
    return any(ch in letters for ch in bases(word))
SHAPE = {
    'silah_meem': lambda w: ends_with(w, 'م'),
    'ha_dhamir': lambda w: ends_with(w, 'ه'),
    'ishmam_sad': lambda w: contains(w, 'ص'),
    'raa_muraqqaqah': lambda w: contains(w, 'ر'),
    'lam_mughallazah': lambda w: contains(w, 'ل'),
    'ghunnah_kha_ghayn': lambda w: contains(w, 'نًٌٍ') or 'ً' in w or 'ٌ' in w or 'ٍ' in w or contains(w, 'ن'),
    'madd_badal': lambda w: any(ch in w for ch in 'ءأإآؤئ'),
}

import tj_common as tc

total = 0
for key, name in NAMES.items():
    try:
        annos = json.load(open(f'{OUT}/{key}-annotations.json'))
        pm = json.load(open(f'{OUT}/{key}-pagemap.json'))
        meta = json.load(open(f'{OUT}/{key}-meta.json'))
    except FileNotFoundError:
        print(f'{key}: stage-2 output missing, skipped')
        continue
    label_of = {c: k for c, k in EDITION_LEGEND[key]}
    riw_texts = tc.riwayah_texts_any(key)
    words_cache = {}
    def word_at(s, a, wi):
        ck = (s, a)
        if ck not in words_cache:
            for aid, text in riw_texts.get(int(s), []):
                if aid == int(a):
                    words_cache[ck] = [w for w in text.replace('\xa0', ' ').split(' ') if w]
                    break
            else:
                words_cache[ck] = []
        ws = words_cache[ck]
        return ws[int(wi)] if int(wi) < len(ws) else ''
    rules = {}
    present = set()
    dropped = 0
    shape_dropped = 0
    for s, ay in annos.items():
        so = {}
        for a, d in ay.items():
            wo = {}
            for wi, rule in d.items():
                # rule is "red" (whole word) or ["red", baseLo, baseHi] (the
                # print's own colored-letter extent within the word)
                color = rule if isinstance(rule, str) else rule[0]
                letter = LETTER[color]
                lk = label_of.get(letter)
                if lk is None:
                    dropped += 1
                    continue
                shape = SHAPE.get(lk)
                if shape is not None and not shape(word_at(s, a, wi)):
                    shape_dropped += 1
                    continue
                wo[wi] = letter if isinstance(rule, str) else [letter, rule[1], rule[2]]
                present.add(letter)
            if wo: so[a] = wo
        if so: rules[s] = so
    legend = [{'c': c, 'k': k, 'ar': L[k]['ar'], 'en': L[k]['en']}
              for c, k in EDITION_LEGEND[key] if c in present]
    pack = {
        'v': 1,
        'legend': legend,
        'rules': rules,
        'pages': pm,
        'khilafMarkers': meta.get('khilafAyahMarkers', {}),
    }
    raw = json.dumps(pack, separators=(',', ':'), ensure_ascii=False).encode('utf-8')
    co = zlib.compressobj(9, zlib.DEFLATED, -15)
    blob = co.compress(raw) + co.flush()
    dest = os.path.join(DEST, f'{name}.json.deflate')
    open(dest, 'wb').write(blob)
    total += len(blob)
    kept = sum(len(d) for so in rules.values() for d in so.values())
    print(f'{key}: {name}.json.deflate raw={len(raw)//1024}KB deflate={len(blob)//1024}KB '
          f'legend={[e["c"] for e in legend]} words={kept} offLegend={dropped} shapeDropped={shape_dropped}')
print(f'total pack bytes: {total/1024:.0f}KB')
