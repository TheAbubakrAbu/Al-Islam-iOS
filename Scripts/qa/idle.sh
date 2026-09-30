#!/bin/zsh
# idle.sh <udid>: per screen, launch with -publishCounter -renderCounter, let it settle 14 s, then record 20 s of
# "PUBLISH COUNT" / "RENDER COUNT" / "WIDGET RELOAD" lines. Zero lines while idle is the Performance Guide's bar.
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
UDID="$1"; BID=com.Quran.Elmallah.Islamic-Pillars
SCR="${QA_OUT:?set QA_OUT to a scratch folder}"
mkdir -p $SCR/logs/idle
while IFS='|' read -r name args; do
  [[ -z "$name" || "$name" == \#* ]] && continue
  xcrun simctl terminate $UDID $BID >/dev/null 2>&1; sleep 1
  eval xcrun simctl launch $UDID $BID -skipNotificationPrompt -publishCounter -renderCounter $args >/dev/null 2>&1
  sleep 14
  out=$SCR/logs/idle/$name.log
  xcrun simctl spawn $UDID log stream --style compact --predicate 'process == "iPhone" AND (eventMessage CONTAINS "COUNT" OR eventMessage CONTAINS "WIDGET RELOAD")' > $out 2>&1 &
  lp=$!
  sleep 20
  kill $lp 2>/dev/null; wait $lp 2>/dev/null
  p=$(grep -c "PUBLISH COUNT" $out); r=$(grep -c "RENDER COUNT" $out); w=$(grep -c "WIDGET RELOAD" $out)
  echo "$name: publish-lines=$p render-lines=$r widget-reloads=$w"
  grep -E "PUBLISH COUNT|RENDER COUNT|WIDGET RELOAD" $out | sed -E 's/^.*\(Foundation\) //' | sort | uniq -c | sort -rn | head -5 | sed 's/^/    /'
done <<'LIST'
adhan|
adhan-sky-off|-seedBool showSkyView=0
adhan-sky-on|-seedBool showSkyView=1
quran-list-reader|-launchTabQuran -quranListMode -lastRead 2:255
quran-page-reader|-launchTabQuran -quranPageMode -mushafPageLanguage arabic -lastRead 2:255
quran-root|-launchTabQuran -quranListMode -noAutoOpenMushaf
hadith|-launchTabHadith
islam|-launchTabIslam
settings|-launchTabSettings
LIST
xcrun simctl terminate $UDID $BID >/dev/null 2>&1
echo IDLE DONE
