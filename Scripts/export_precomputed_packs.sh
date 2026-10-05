#!/bin/zsh
# export_precomputed_packs.sh: regenerate the two precomputed packs the app ships
# (Performance Guide 10.14-10.17) from the app's OWN code, then copy them into Resources:
#
#   Resources/Data/Quran/quran-search.qsp        the Hafs ayah search index, the ranked search's
#                                                corpus lanes and the daily card's flags
#   Resources/Data/Quran/CrossLanguageLexicon.bin the cross-language highlight's lexicon
#
# Both are pure functions of quran.qpk, WordByWord.json.xz and the fold rules compiled into the app,
# so the export is a unit test (UnitTests/PrecomputedPackTests.testExportWhenAsked) run on the
# iPhone 17 Pro simulator with PRECOMPUTED_EXPORT_DIR set. Re-run after ANY change to quran.qpk,
# WordByWord.json.xz, Settings.cleanSearch / the silent and hamza folds, QuranRankedSearch's stems,
# skeletons or outlines, the daily-card blocked words, or CrossLanguageWordHighlight's lexicon rules;
# the rest of PrecomputedPackTests fails until you do.
#
#   ./Scripts/export_precomputed_packs.sh [derived-data-path]
set -e
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
ROOT=${0:A:h:h}
UDID=${UDID:-$(xcrun simctl list devices available | grep "iPhone 17 Pro (" | head -1 | grep -oE '[0-9A-F-]{36}')}
[[ -n $UDID ]] || { echo "no iPhone 17 Pro simulator"; exit 1 }
DDARGS=()
[[ -n ${1:-} ]] && DDARGS=(-derivedDataPath "${1:A}")
OUT=$(mktemp -d /tmp/precomputed-XXXXXX)
BID=com.Quran.Elmallah.Islamic-Pillars

# A "-displayQiraah <tag>" launch persists that riwayah into the simulator's defaults, and the packs
# are Hafs: reset it when the app is installed (harmless when it is not).
xcrun simctl boot "$UDID" >/dev/null 2>&1 || true
if xcrun simctl launch "$UDID" $BID -displayQiraah "" >/dev/null 2>&1; then
  sleep 3; xcrun simctl terminate "$UDID" $BID >/dev/null 2>&1 || true
fi

echo "exporting into $OUT"
TEST_RUNNER_PRECOMPUTED_EXPORT_DIR="$OUT" xcodebuild test -project "$ROOT/Al-Islam.xcodeproj" -scheme iPhone \
  -destination "platform=iOS Simulator,id=$UDID" "${DDARGS[@]}" \
  -only-testing:UnitTests/PrecomputedPackTests/testExportWhenAsked 2>&1 \
  | grep -E "Test Case .* (passed|failed)|error:|PRECOMPUTED EXPORT|\*\* TEST" || true

for f in quran-search.qsp CrossLanguageLexicon.bin; do
  [[ -s "$OUT/$f" ]] || { echo "export did not produce $f"; exit 1 }
  cp "$OUT/$f" "$ROOT/Resources/Data/Quran/$f"
done
ls -la "$ROOT/Resources/Data/Quran/quran-search.qsp" "$ROOT/Resources/Data/Quran/CrossLanguageLexicon.bin"
echo "copied; now rebuild and run the UnitTests target so PrecomputedPackTests confirms the files"
