#!/bin/zsh
# settings_probeshots.sh <udid> <tag>: does a setting change still reach the screen? Per scenario,
# launch on a screen, screenshot at 9 s, flip ONE setting in-process at 10 s (-settingsProbe), screenshot
# at 13 s, and flip it back at 14 s so the simulator's stored setting is unchanged. A pair of identical
# screenshots for a setting the screen shows means a stale view (Performance Guide, section 18: a view
# that reads a field without observing the slice that owns it). Compare the pairs by eye or by `cmp`.
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
UDID="$1"; TAG="${2:-run}"; BID=com.Quran.Elmallah.Islamic-Pillars
SCR="${QA_OUT:?set QA_OUT to a scratch folder}/shots/probes-$TAG"; mkdir -p "$SCR"
while IFS='|' read -r name probe args; do
  [[ -z "$name" || "$name" == \#* ]] && continue
  xcrun simctl terminate $UDID $BID >/dev/null 2>&1; sleep 1
  eval xcrun simctl launch $UDID $BID -skipNotificationPrompt -settingsProbe "\"$probe\"" $args >/dev/null 2>&1
  sleep 9
  xcrun simctl io $UDID screenshot "$SCR/$name-before.png" >/dev/null 2>&1
  sleep 4
  xcrun simctl io $UDID screenshot "$SCR/$name-after.png" >/dev/null 2>&1
  # The restore step fires at 14 s of APP time (a slow launch lands it later): give it room before
  # the terminate, or the simulator keeps the flipped value for the next run.
  sleep 7
  if cmp -s "$SCR/$name-before.png" "$SCR/$name-after.png"; then echo "$name: IDENTICAL (stale?)"; else echo "$name: changed"; fi
done <<'LIST'
# name|probe|launch args
adhan-duha|showDuha=1@10,showDuha=0@14|
adhan-accent|accentColor=red@10,accentColor=green@14|
quran-list-size|fontArabicSize=40@10,fontArabicSize=27@14|-launchTabQuran -quranListMode -lastRead 2:255
quran-list-tajweed|showTajweedColors=0@10,showTajweedColors=1@14|-launchTabQuran -quranListMode -lastRead 2:255
quran-list-english|showEnglishSaheeh=0@10,showEnglishSaheeh=1@14|-launchTabQuran -quranListMode -lastRead 2:255
# Fit Page is on by default, so the Arabic size never moves a fitted page: probe tajweed there instead.
quran-page-tajweed|showTajweedColors=0@10,showTajweedColors=1@14|-launchTabQuran -quranPageMode -mushafPageLanguage arabic -lastRead 2:255
quran-root-accent|accentColor=red@10,accentColor=green@14|-launchTabQuran -quranListMode -noAutoOpenMushaf
hadith-size|hadithArabicFontSize=34@10,hadithArabicFontSize=24@14|-launchTabHadith
islam-face|islamArabicFace=kufi@10,islamArabicFace=uthmani@14|-launchTabIslam
# The letter size lives on a letter's page: open one (the Arabic Alphabet resource, then the letter ب).
islam-letter-size|arabicLetterSizeIndex=4@10,arabicLetterSizeIndex=2@14|-launchTabIslam -islamDestination arabicAlphabet -islamOpenLetter ب
settings-accent|accentColor=red@10,accentColor=green@14|-launchTabSettings
LIST
xcrun simctl terminate $UDID $BID >/dev/null 2>&1
echo PROBE SHOTS DONE
