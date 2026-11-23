# -*- coding: utf-8 -*-
import json, re, glob, unicodedata
cat=json.load(open('/Users/theabubakrabu/Downloads/Islam/Al-Islam-iOS/Resources/Localizable.xcstrings',encoding='utf-8'))['strings']
def v(k,l):
    e=cat.get(k,{}).get('localizations',{}).get(l)
    if not e: return None
    return e.get('stringUnit',{}).get('value') or (e.get('variations',{}).get('plural',{}).get('other',{}).get('stringUnit',{}).get('value'))
langs={'Hindi':'hi','German':'de','Spanish':'es'}
files=glob.glob('/Users/theabubakrabu/Downloads/Islam/Al-Islam-iOS/Docs/App Store/*Listing.md')+glob.glob('/Users/theabubakrabu/Downloads/Islam/sibling-staging/*/Docs/*Listing.md')
for f in sorted(files):
    name=f.split('/')[-1].split(' ')[0]
    if name not in langs: continue
    l=langs[name]; app=f.split('/')[-3] if 'sibling' in f else 'Al-Islam'
    bad=[]
    for line in open(f,encoding='utf-8'):
        m=re.match(r'^\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*$', line)
        if not m or m.group(1) in ('English','---') or set(m.group(1))<=set('-: '): continue
        en=[x.strip() for x in re.split(r',\s*|\s/\s', m.group(1))]
        tr=[re.sub(r'[†*]','',x).strip() for x in re.split(r',\s*|\s/\s', m.group(2))]
        if len(en)!=len(tr): continue
        for a,b in zip(en,tr):
            a2=re.sub(r'\s*\(.*\)$','',a)
            cv=v(a2,l)
            if cv is None: continue
            if unicodedata.normalize('NFC',cv).lower()!=unicodedata.normalize('NFC',b).lower():
                bad.append((a2,b,cv))
    print(app,name,len(bad)); [print('   ',x) for x in bad[:12]]
