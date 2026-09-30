#!/bin/zsh
# build.sh <tag> [Debug|Release]: builds the iPhone scheme for the QA simulator into $QA_OUT/dd (or
# $QA_OUT/dd-release), installs a Debug build, and prints errors, Swift warnings and the result.
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
HERE=${0:A:h}; ROOT=${HERE:h:h}
OUT="${QA_OUT:?set QA_OUT to a scratch folder}"; mkdir -p "$OUT/logs"
UDID=$($HERE/device.sh); CONF=${2:-Debug}
DD="$OUT/dd"; [[ $CONF == Release ]] && DD="$OUT/dd-release"
LOG="$OUT/logs/build-$1.log"
xcodebuild -project "$ROOT/Al-Islam.xcodeproj" -scheme iPhone -configuration $CONF \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$DD" build > "$LOG" 2>&1
echo "exit=$?"
grep -E "error:" "$LOG" | sort -u | head -40
grep -E "\.swift:[0-9]+:[0-9]+: warning:" "$LOG" | sort -u | head -40
grep -E "BUILD (SUCCEEDED|FAILED)" "$LOG"
if [[ $CONF == Debug ]] && grep -q "BUILD SUCCEEDED" "$LOG"; then
  xcrun simctl install "$UDID" "$DD/Build/Products/Debug-iphonesimulator/iPhone.app" && echo "installed on $UDID"
fi
