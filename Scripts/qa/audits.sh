#!/bin/zsh
# audits.sh <udid>: run each in-app DEBUG audit with a console pty capture, wait for its "done" marker or a time cap.
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
UDID="$1"; BID=com.Quran.Elmallah.Islamic-Pillars
SCR="${QA_OUT:?set QA_OUT to a scratch folder}"
mkdir -p $SCR/logs/audits
run() {  # name cap marker args...
  local name=$1 cap=$2 marker=$3; shift 3
  xcrun simctl terminate $UDID $BID >/dev/null 2>&1; sleep 1
  local out=$SCR/logs/audits/$name.log
  xcrun simctl launch --console-pty $UDID $BID -skipNotificationPrompt "$@" > $out 2>&1 &
  local lp=$!
  local t=0
  while (( t < cap )); do
    sleep 2; t=$((t+2))
    [[ -n "$marker" ]] && grep -q "$marker" $out && break
  done
  sleep 1
  xcrun simctl terminate $UDID $BID >/dev/null 2>&1
  kill $lp 2>/dev/null; wait $lp 2>/dev/null
  echo "$name: ${t}s, $(wc -l < $out | tr -d ' ') lines, marker $( [[ -n "$marker" ]] && (grep -q "$marker" $out && echo seen || echo MISSING) || echo n/a)"
}
run alignment         300 "ALIGNMENT AUDIT: done"    -launchTabQuran -quranListMode -auditQiraahAlignment
run semantic          120 "SEMANTIC PACK hadith"     -launchTabQuran -quranListMode -auditSemanticPacks
run packs             300 "PACK AUDIT DONE"          -auditPacks
run cloudkeys          40 ""                         -cloudKeyAudit
run rollover           25 ""                         -dailyRolloverProbe
echo AUDITS DONE
