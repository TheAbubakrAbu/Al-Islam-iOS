#!/bin/zsh
# launch.sh <udid> <runs>: cold launches with -launchTiming per start screen; prints each milestone's median ms.
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
UDID="$1"; RUNS="${2:-5}"; BID=com.Quran.Elmallah.Islamic-Pillars
SCR="${QA_OUT:?set QA_OUT to a scratch folder}"
mkdir -p $SCR/logs/launch
while IFS='|' read -r name args; do
  [[ -z "$name" ]] && continue
  : > $SCR/logs/launch/$name.txt
  for i in $(seq 1 $RUNS); do
    xcrun simctl terminate $UDID $BID >/dev/null 2>&1; sleep 2
    out=$SCR/logs/launch/$name-$i.log
    xcrun simctl spawn $UDID log stream --style compact --predicate 'process == "iPhone" AND eventMessage CONTAINS "LAUNCH TIMING"' > $out 2>&1 &
    lp=$!; sleep 1
    eval xcrun simctl launch $UDID $BID -skipNotificationPrompt -launchTiming $args >/dev/null 2>&1
    sleep 9
    kill $lp 2>/dev/null; wait $lp 2>/dev/null
    grep -oE "LAUNCH TIMING .* \+[0-9]+ ms" $out >> $SCR/logs/launch/$name.txt
  done
  echo "== $name ($RUNS runs)"
  python3 - $SCR/logs/launch/$name.txt <<'PY'
import sys, re, collections, statistics
d = collections.defaultdict(list); order = []
for line in open(sys.argv[1]):
    m = re.match(r'LAUNCH TIMING (.*) \+(\d+) ms', line.strip())
    if not m: continue
    k = m.group(1)
    if k not in d: order.append(k)
    d[k].append(int(m.group(2)))
for k in order:
    v = d[k]; print(f"   {k:40s} median {int(statistics.median(v)):6d} ms  (n={len(v)}, min {min(v)}, max {max(v)})")
PY
done <<'LIST'
adhan|
quran-list|-launchTabQuran -quranListMode -lastRead 2:255
quran-page|-launchTabQuran -quranPageMode -mushafPageLanguage arabic -lastRead 2:255
LIST
xcrun simctl terminate $UDID $BID >/dev/null 2>&1
echo LAUNCH DONE
