#!/bin/zsh
# run.sh <questions.txt> <out.txt> [extra launch args]
#
# Replays one question per line of <questions.txt> through the real app's Ask AI on the iPhone 17 Pro
# (iOS 27) simulator and copies the -askAILog file to <out.txt>. Score it with score.py.
#
# Needs a Debug build at $APP (default: build/DerivedData/Build/Products/Debug-iphonesimulator/iPhone.app,
# the output of `xcodebuild build-for-testing -scheme iPhone -derivedDataPath build/DerivedData`).
# Set UDID to pick a simulator; otherwise the first available "iPhone 17 Pro" on the iOS 27 runtime is used.
# Extra arguments are passed to the app (for example -askAILogPrompt, which also copies askai-prompt.txt).
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
set -u
HERE=${0:A:h}; ROOT=${HERE:h:h:h}
QUESTIONS="${1:?usage: run.sh <questions.txt> <out.txt> [extra launch args]}"
OUT="${2:?usage: run.sh <questions.txt> <out.txt> [extra launch args]}"
shift 2
BID=com.Quran.Elmallah.Islamic-Pillars
APP="${APP:-$ROOT/build/DerivedData/Build/Products/Debug-iphonesimulator/iPhone.app}"
TIMEOUT="${TIMEOUT:-1200}"

if [[ -z "${UDID:-}" ]]; then
  UDID=$(xcrun simctl list devices available | awk '/-- iOS 27/{f=1;next} /^-- /{f=0} f && /iPhone 17 Pro \(/{match($0,/[0-9A-F-]{36}/); print substr($0,RSTART,RLENGTH); exit}')
fi
[[ -n "$UDID" ]] || { echo "no iPhone 17 Pro on the iOS 27 runtime; create one or set UDID" >&2; exit 1; }
[[ -d "$APP" ]] || { echo "no app at $APP; build first" >&2; exit 1; }

# One question per line; blank lines and # comments skipped; joined with || for the -askAI queue.
QUEUE=$(grep -v '^[[:space:]]*#' "$QUESTIONS" | grep -v '^[[:space:]]*$' | awk 'NR > 1 { printf "||" } { printf "%s", $0 }')
COUNT=$(grep -v '^[[:space:]]*#' "$QUESTIONS" | grep -vc '^[[:space:]]*$')
[[ $COUNT -gt 0 ]] || { echo "no questions in $QUESTIONS" >&2; exit 1; }

xcrun simctl boot "$UDID" >/dev/null 2>&1; xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1
xcrun simctl terminate "$UDID" $BID >/dev/null 2>&1
xcrun simctl install "$UDID" "$APP" || exit 1
CONTAINER=$(xcrun simctl get_app_container "$UDID" $BID data) || exit 1
LOG="$CONTAINER/Documents/askai-log.txt"
PROMPT="$CONTAINER/Documents/askai-prompt.txt"
rm -f "$LOG" "$PROMPT"

echo "run.sh: $COUNT questions on $UDID"
# THEfirstLaunch=0 skips the welcome walk on a fresh simulator. Run the harness on a simulator of
# its own: running the unit tests reinstalls the app and kills a replay in progress.
xcrun simctl launch "$UDID" $BID -launchTabIslam -islamDestination askAI -askAILog -askAIReset \
  -skipNotificationPrompt -travelingMode 0 -seedBool THEfirstLaunch=0 "$@" -askAI "$QUEUE" >/dev/null || exit 1

start=$(date +%s)
while true; do
  done_count=0
  [[ -f "$LOG" ]] && done_count=$(grep -c '^===== Q:' "$LOG")
  if [[ $done_count -ge $COUNT ]]; then
    # The last block is appended whole, but give the writer a moment to close it.
    sleep 2
    break
  fi
  if (( $(date +%s) - start > TIMEOUT )); then
    echo "run.sh: timed out with $done_count of $COUNT turns logged" >&2
    break
  fi
  sleep 3
done
xcrun simctl terminate "$UDID" $BID >/dev/null 2>&1
if [[ -f "$LOG" ]]; then
  cp "$LOG" "$OUT"
  [[ -f "$PROMPT" ]] && cp "$PROMPT" "${OUT%.txt}-prompt.txt"
  echo "run.sh: $(grep -c '^===== Q:' "$OUT") turns -> $OUT"
else
  echo "run.sh: no log written" >&2
  exit 1
fi
