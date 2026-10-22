#!/bin/zsh
# settings_actions.sh <udid> <tag>: what one settings write costs, per screen (Performance Guide,
# section 18). Each scenario launches on a screen with -publishCounter -renderCounter and a
# -settingsProbe step that flips ONE setting 20 s in (the only headless way to change a setting in a
# running app; 20 s so the launch tail, the deferred verse index for one, is over), records the log
# for the 8 s around it, and prints the Settings publishes, the slice publishes (OBJECT PUBLISH) and
# the body evaluations per label that the flip caused. The bar after the refactor: one publish on one
# slice, and body counts only for views that show the flipped field.
#
# The probe toggles a value, so the simulator's stored setting moves; every scenario flips it back
# with a second step 3 s later, which is inside the window and doubles the counts (two writes).
# Read the numbers per write: halve them.
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
UDID="$1"; TAG="${2:-run}"; BID=com.Quran.Elmallah.Islamic-Pillars
SCR="${QA_OUT:?set QA_OUT to a scratch folder}"
mkdir -p "$SCR/logs/settings-actions-$TAG"
while IFS='|' read -r name probe args; do
  [[ -z "$name" || "$name" == \#* ]] && continue
  xcrun simctl terminate $UDID $BID >/dev/null 2>&1; sleep 1
  eval xcrun simctl launch $UDID $BID -skipNotificationPrompt -publishCounter -renderCounter -settingsProbe "\"$probe\"" $args >/dev/null 2>&1
  sleep 18
  out="$SCR/logs/settings-actions-$TAG/$name.log"
  xcrun simctl spawn $UDID log stream --style compact --predicate 'process == "iPhone" AND (eventMessage CONTAINS "COUNT" OR eventMessage CONTAINS "PUBLISH KEY" OR eventMessage CONTAINS "OBJECT PUBLISH")' > "$out" 2>&1 &
  lp=$!
  sleep 8
  kill $lp 2>/dev/null; wait $lp 2>/dev/null
  slices=$(grep -oE "OBJECT PUBLISH .*" "$out" | sed -E 's/OBJECT PUBLISH //' | tr ',' '\n' | sed -E 's/^ +//' \
    | awk '{c[$1]+=$2} END {for (k in c) printf "%s %d, ", k, c[k]}' | sed -E 's/, $//')
  publishes=$(grep -oE "PUBLISH COUNT [0-9]+" "$out" | awk '{s+=$3} END {print s+0}')
  # Sum every label's body evaluations across the window's RENDER COUNT lines.
  bodies=$(grep -oE "RENDER COUNT .*" "$out" | sed -E 's/RENDER COUNT //' | tr ',' '\n' | sed -E 's/^ +//' \
    | awk '{c[$1]+=$2} END {for (k in c) printf "%s %d, ", k, c[k]}' | sed -E 's/, $//')
  echo "$name: settings=$publishes slices: ${slices:-none} | bodies: ${bodies:-none}"
done <<'LIST'
# name|probe (key=value@seconds,key=value@seconds)|launch args
adhan-duha|showDuha=1@20,showDuha=0@23|
adhan-font-size|fontArabicSize=36@20,fontArabicSize=27@23|
quran-list-font-size|fontArabicSize=36@20,fontArabicSize=27@23|-launchTabQuran -quranListMode -lastRead 2:255
quran-list-tajweed|showTajweedColors=0@20,showTajweedColors=1@23|-launchTabQuran -quranListMode -lastRead 2:255
quran-list-duha|showDuha=1@20,showDuha=0@23|-launchTabQuran -quranListMode -lastRead 2:255
quran-page-font-size|fontArabicSize=36@20,fontArabicSize=27@23|-launchTabQuran -quranPageMode -mushafPageLanguage arabic -lastRead 2:255
quran-page-duha|showDuha=1@20,showDuha=0@23|-launchTabQuran -quranPageMode -mushafPageLanguage arabic -lastRead 2:255
quran-root-duha|showDuha=1@20,showDuha=0@23|-launchTabQuran -quranListMode -noAutoOpenMushaf
hadith-duha|showDuha=1@20,showDuha=0@23|-launchTabHadith
hadith-font-size|hadithArabicFontSize=30@20,hadithArabicFontSize=24@23|-launchTabHadith
islam-duha|showDuha=1@20,showDuha=0@23|-launchTabIslam
islam-letter-size|arabicLetterSizeIndex=3@20,arabicLetterSizeIndex=2@23|-launchTabIslam
settings-duha|showDuha=1@20,showDuha=0@23|-launchTabSettings
LIST
xcrun simctl terminate $UDID $BID >/dev/null 2>&1
echo SETTINGS ACTIONS DONE
