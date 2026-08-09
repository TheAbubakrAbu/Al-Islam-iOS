#!/bin/bash
# Stage-1 box extraction for every non-Hafs riwayah PDF -> boxes/<key>/pNNN.json
# Standard islamweb editions: x80-1160, y140-1560 (bottom junk under the text
# block -- floating legend box, footer -- is cut in stage 2 by signature).
# Star-border editions need x inside the star columns and y below the
# title/logo band: measured per pair.
cd "$(dirname "$0")"
M="/Users/theabubakrabu/Downloads/Islam/Al-Islam-iOS/Resources/Mushaf PDFs"
run() { # key pdf X0 X1 Y0 Y1
  [ -f "boxes/$1/p604.json" ] && { echo "skip $1 (done)"; return; }
  echo "=== $1 ==="
  python3 tj_stage1.py "$M/$2.pdf" "boxes/$1" 1 604 "$3" "$4" "$5" "$6" || echo "FAILED $1"
}
# standard editions
for job in "shubah:01-asim-shubah" "qaloon:02-nafi-qalun" "warsh:02-nafi-warsh" \
  "bazzi:03-ibn-kathir-al-bazzi" "qunbul:03-ibn-kathir-qunbul" \
  "duri:04-abu-amr-ad-duri" "susi:04-abu-amr-as-susi" \
  "hisham:05-ibn-amir-hisham" "ibndhakwan:05-ibn-amir-ibn-dhakwan" \
  "khalaf:06-hamzah-khalaf" "khallad:06-hamzah-khallad" \
  "abuharith:07-al-kisai-abu-al-harith" "durikisai:07-al-kisai-ad-duri"; do
  run "${job%%:*}" "${job##*:}" 80 1160 140 1560
done
# star-border editions
run ibnwardan 08-abu-jafar-ibn-wardan 100 1140 200 1500
run ibnjammaz 08-abu-jafar-ibn-jammaz 100 1140 200 1500
run ruways 09-yaqub-ruways 100 1140 225 1500
run rawh 09-yaqub-rawh 100 1140 225 1500
run ishaq 10-khalaf-al-ashir-ishaq 100 1140 227 1500
run idris 10-khalaf-al-ashir-idris 100 1140 227 1500
echo ALL-DONE
