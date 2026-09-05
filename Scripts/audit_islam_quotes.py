# -*- coding: utf-8 -*-
"""Audit every ScriptureQuote in the Pillars & Beliefs / How-to article files against the app's OWN packs.

    python3 Scripts/audit_islam_quotes.py > /tmp/quote_audit.txt

For each quote it checks: a Quran citation's Arabic is the Hafs text (or a contiguous slice) and its
English is a verbatim slice of Saheeh International or the Clear Quran; a hadith citation exists in
the hpk, its Arabic is a slice of that row's matn, its English is a slice of the pack's translation,
and no grader marks it da'if (split grades are listed so the citation can name al-Albani). Sections:
QURAN_EN_MISMATCH, QURAN_AR_MISMATCH, HADITH_NOTFOUND, HADITH_WEAK, HADITH_AR_MISMATCH,
HADITH_EN_NOTVERBATIM (ellipsis joins and Saheeh's stray spaces show up here and are benign),
OTHER (citations outside the packs: scholars' books, Musnad Ahmad numbers the partial pack lacks).
"""
import re, io, json, sys, collections, difflib
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from islam_packs import Hadith, quran_ayah, strip_marks, is_weak, _quran

ROOT=os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),'iPhone','Islam')+'/'
FILES=['PillarViews','BeliefsViews','HowToGuides','AqeedahViews','SalafiyyahViews','AnswersViews','ScholarsViews']
SLUG={'sahih al-bukhari':'bukhari','sahih bukhari':'bukhari','sahih muslim':'muslim','muqaddimah of sahih muslim':'muslim',
      'sunan abi dawud':'abudawud','sunan abu dawud':'abudawud','sunan al-tirmidhi':'tirmidhi','jami at-tirmidhi':'tirmidhi',
      'sunan ibn majah':'ibnmajah',"sunan an-nasa'i":'nasai','sunan al-darimi':'darimi','musnad ahmad':'ahmed'}

def unswift(s): return s.replace('\\"','"').replace('\\n','\n').replace('\\\\','\\')
def bare(s):
    s=strip_marks(s)
    s=re.sub(r'[\u06d6-\u06ed\u0670\u0640\u200f\u200e\u06de\u06e9\u061f]','',s)
    s=s.replace('ٱ','ا').replace('أ','ا').replace('إ','ا').replace('آ','ا').replace('ٱ','ا')
    s=re.sub(r'[^\u0600-\u06ff]+',' ',s)
    return re.sub(r'\s+',' ',s).strip()
def norm_en(s):
    s=s.replace('’',"'").replace('‘',"'").replace('“','"').replace('”','"').replace('–','-').replace('—','-')
    s=re.sub(r'\s+',' ',s)
    return s.strip().lower()
def en_pieces(s):
    s=s.strip().strip('"').strip()
    parts=[p.strip(' ."\',;:') for p in re.split(r'…|\.\.\.',s)]
    return [p for p in parts if p]
def contains(hay,needle):
    hay=norm_en(hay); n=norm_en(needle)
    if n in hay: return True
    # tolerate bracket removal and punctuation
    h2=re.sub(r'[\[\]]','',hay); n2=re.sub(r'[\[\]]','',n)
    if n2 in h2: return True
    h3=re.sub(r'[^a-z0-9 ]','',h2); n3=re.sub(r'[^a-z0-9 ]','',n2)
    return n3 in h3

quotes=[]
for f in FILES:
    src=io.open(ROOT+f+'.swift',encoding='utf-8').read()
    for m in re.finditer(r'(?:ScriptureQuote|\.quote)\(text:\s*"((?:[^"\\]|\\.)*)"(?:,\s*arabic:\s*"((?:[^"\\]|\\.)*)")?(?:,\s*dimmed:\s*(true|false))?\)',src):
        line=src.count('\n',0,m.start())+1
        t=unswift(m.group(1)); ar=unswift(m.group(2) or '')
        cm=re.search(r'\(([^()]*(?:\([^()]*\)[^()]*)*)\)\.?\s*$',t)
        cit=cm.group(1) if cm else ''
        en=t[:cm.start()].strip() if cm else t
        quotes.append(dict(file=f,line=line,text=t,en=en,ar=ar,cit=cit,dimmed=m.group(3)))
print(len(quotes),'quotes')

packs={}
def pack(slug):
    if slug not in packs: packs[slug]=Hadith(slug)
    return packs[slug]

report=collections.defaultdict(list)
Q=_quran()
def ayah(s,a): return Q[s-1]['ayahs'][a-1]
for q in quotes:
    cit=q['cit']; first=cit.split(';')[0].strip()
    if first.startswith('Quran'):
        mm=re.match(r'Quran\s+(\d+):(\d+)(?:[-–](\d+))?(?:,\s*(\d+)(?:[-–](\d+))?)*',first)
        if not mm: report['QURAN_BADCIT'].append((q,first)); continue
        s=int(mm.group(1)); a=int(mm.group(2)); b=int(mm.group(3) or a)
        # also collect comma-separated extra ayahs
        extra=re.findall(r',\s*(\d+)(?:[-–](\d+))?',first)
        rng=list(range(a,b+1))
        for x,y in extra: rng+=list(range(int(x),int(y or x)+1))
        try:
            ars=[ayah(s,i)['textArabic'] for i in rng]
        except Exception as e:
            report['QURAN_NOAYAH'].append((q,first)); continue
        full_ar=' '.join(ars)
        qa=bare(q['ar']); fa=bare(full_ar)
        if qa!=fa:
            if qa in fa: report['QURAN_AR_SLICE'].append((q,first))
            else:
                # maybe per-ayah pieces (ellipsis in Arabic?)
                report['QURAN_AR_MISMATCH'].append((q,first,full_ar))
        # marks-level exactness when bare matches fully
        elif re.sub(r'[\s\u200f]','',q['ar'].replace('۝',''))!=re.sub(r'[\s\u200f]','',full_ar):
            report['QURAN_AR_MARKS'].append((q,first,full_ar))
        sah=' '.join(ayah(s,i)['textEnglishSaheeh'] for i in rng)
        mus=' '.join(ayah(s,i)['textEnglishMustafa'] for i in rng)
        pieces=en_pieces(q['en'])
        ok_s=all(contains(sah,p) for p in pieces); ok_m=all(contains(mus,p) for p in pieces)
        if not (ok_s or ok_m):
            report['QURAN_EN_MISMATCH'].append((q,first,sah,mus))
        else:
            q['tr']='saheeh' if ok_s else 'mustafa'
            if norm_en(' '.join(pieces))!=norm_en(sah.strip().rstrip('.')) and len(pieces)==1 and ok_s and norm_en(pieces[0])!=norm_en(sah.rstrip('.').strip()):
                report['QURAN_EN_PARTIAL'].append((q,first))
        continue
    mm=re.match(r"(Sahih al-Bukhari|Sahih Bukhari|Sahih Muslim|Muqaddimah of Sahih Muslim|Sunan Abi Dawud|Sunan Abu Dawud|Sunan al-Tirmidhi|Sunan Ibn Majah|Sunan an-Nasa'i|Sunan al-Darimi|Musnad Ahmad)\s+(\d+)([a-z])?",first)
    if mm:
        slug=SLUG[mm.group(1).lower()]; num=mm.group(2); let=mm.group(3)
        h=pack(slug); items=h.find(num)
        if let: items=[i for i in items if i.citation==num+let] or items
        if not items: report['HADITH_NOTFOUND'].append((q,first)); continue
        qa=bare(q['ar'])
        hit=None
        for it in items:
            if qa and qa in bare(it.arabic): hit=it; break
        if not hit:
            # try token-level: all words present in order? fallback ratio
            best=max(items,key=lambda it: difflib.SequenceMatcher(None,qa,bare(it.arabic)).ratio())
            report['HADITH_AR_MISMATCH'].append((q,first,best))
            hit=best
        weak=[g for it in items for g in it.grades]
        q['grades']=hit.grades
        if is_weak(hit.grades): report['HADITH_WEAK'].append((q,first,hit.grades))
        # english closeness
        pieces=en_pieces(q['en'])
        ratio=difflib.SequenceMatcher(None,norm_en(' '.join(pieces)),norm_en(hit.text)).find_longest_match(0,len(norm_en(' '.join(pieces))),0,len(norm_en(hit.text))).size/max(1,len(norm_en(' '.join(pieces))))
        exact=all(contains(hit.text,p) for p in pieces)
        q['en_exact']=exact
        if not exact: report['HADITH_EN_NOTVERBATIM'].append((q,first,hit))
        # secondary citations in the same quote
        for other in cit.split(';')[1:]:
            om=re.match(r"\s*(Sahih al-Bukhari|Sahih Muslim|Sunan Abi Dawud|Sunan al-Tirmidhi|Sunan Ibn Majah|Sunan an-Nasa'i|Sunan al-Darimi|Musnad Ahmad)\s+(\d+)",other)
            if om:
                oi=pack(SLUG[om.group(1).lower()]).find(om.group(2))
                if not oi: report['HADITH_SECONDARY_NOTFOUND'].append((q,other.strip()))
                elif any(is_weak(i.grades) for i in oi): report['HADITH_SECONDARY_WEAK'].append((q,other.strip(),[i.grades for i in oi]))
        continue
    report['OTHER'].append((q,first))

for k,v in report.items():
    print('\n=====',k,len(v))
    for row in v:
        q=row[0]
        print(f"\n[{q['file']}:{q['line']}] {row[1]}")
        if k in('QURAN_AR_MISMATCH','QURAN_AR_MARKS'):
            print('  APP :',q['ar']); print('  PACK:',row[2])
        elif k=='QURAN_EN_MISMATCH':
            print('  APP   :',q['en']); print('  SAHEEH:',row[2]); print('  CLEAR :',row[3])
        elif k=='HADITH_AR_MISMATCH':
            print('  APP :',q['ar']); print('  PACK:',row[2].arabic[:600])
        elif k=='HADITH_EN_NOTVERBATIM':
            print('  APP :',q['en'][:400]); print('  PACK:',row[2].text[:600])
        elif k in('HADITH_WEAK','HADITH_SECONDARY_WEAK'):
            print('  GRADES:',row[2])
        elif k=='OTHER':
            print('  EN:',q['en'][:200]); print('  AR:',q['ar'][:200])
