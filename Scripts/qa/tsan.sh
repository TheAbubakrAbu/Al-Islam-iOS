#!/bin/zsh
# tsan.sh <udid>: install the TSan build, run flows with console capture, count ThreadSanitizer reports, reinstall Debug.
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
UDID="$1"; BID=com.Quran.Elmallah.Islamic-Pillars
SCR="${QA_OUT:?set QA_OUT to a scratch folder}"
mkdir -p $SCR/logs/tsan
xcrun simctl terminate $UDID $BID >/dev/null 2>&1
xcrun simctl install $UDID $SCR/dd-tsan/Build/Products/Debug-iphonesimulator/iPhone.app || { echo INSTALL FAILED; exit 1; }
run() { # name secs args...
  local name=$1 secs=$2; shift 2
  xcrun simctl terminate $UDID $BID >/dev/null 2>&1; sleep 1
  local out=$SCR/logs/tsan/$name.log
  xcrun simctl launch --console-pty $UDID $BID -skipNotificationPrompt "$@" > $out 2>&1 &
  local lp=$!
  sleep $secs
  xcrun simctl terminate $UDID $BID >/dev/null 2>&1
  kill $lp 2>/dev/null; wait $lp 2>/dev/null
  echo "$name: $(grep -c 'WARNING: ThreadSanitizer' $out) TSan reports, $(wc -l < $out | tr -d ' ') lines"
}
run launch-adhan       40
run hadith-search      50 -launchTabHadith -hadithSearch "patience"
run hadith-book        40 -launchTabHadith -launchHadithOpen bukhari:1
run islam-duas         40 -launchTabIslam -islamDestination commonDuas
run quran-word-card    50 -launchTabQuran -quranListMode -lastRead 2:1 -openRowSheet word -wordIndex 1
run quran-page         45 -launchTabQuran -quranPageMode -mushafPageLanguage arabic -lastRead 18:1
run askai              90 -launchTabIslam -islamDestination askAI -askAIReset -askAI "What does the Quran say about patience?||who narrated that hadith?"
xcrun simctl terminate $UDID $BID >/dev/null 2>&1
xcrun simctl install $UDID $SCR/dd/Build/Products/Debug-iphonesimulator/iPhone.app && echo "REINSTALLED DEBUG"
echo TSAN DONE
