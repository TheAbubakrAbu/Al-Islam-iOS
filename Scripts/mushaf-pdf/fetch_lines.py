import json, os, sys, time, urllib.request
out_dir = sys.argv[1]
base = "https://api.quran.com/api/v4/verses/by_page/{p}?words=true&per_page=50&word_fields=line_number,text_uthmani,char_type_name,position"
fails = []
for p in range(1, 605):
    f = os.path.join(out_dir, f"{p:03d}.json")
    if os.path.exists(f) and os.path.getsize(f) > 500: continue
    for attempt in range(4):
        try:
            req = urllib.request.Request(base.format(p=p), headers={"User-Agent": "Mozilla/5.0 (mushaf-layout fetch)"})
            data = urllib.request.urlopen(req, timeout=40).read()
            d = json.loads(data)
            assert d.get("verses"), "no verses"
            open(f, "wb").write(data); break
        except Exception as e:
            time.sleep(2 + attempt * 3)
            if attempt == 3: fails.append((p, str(e)))
    time.sleep(0.15)
print("done; failures:", fails)
