#!/bin/zsh
# sweep.sh <udid> <screens.txt> <tag>: one cold launch per line "name|seconds|args" ("!cmd" lines run a shell
# command with the app terminated). Per screen: the full app log, a screenshot, alive and crash-report status.
# Needs QA_OUT (a scratch folder). zsh: never name a variable `status` (read-only).
# Another session on this Mac shuts every simulator down now and then: the device is booted again
# before each screen, and a screen that ran on a device that went down is retried once ("RETRIED").
# QA_START_AT=<name> resumes a list at that screen. QA_EXTRA_ARGS is appended to every launch
# (e.g. "-landscape" for an iPad pass in landscape).
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
UDID="$1"; LIST="$2"; TAG="$3"; BID=com.Quran.Elmallah.Islamic-Pillars
OUT="${QA_OUT:?set QA_OUT to a scratch folder}"; mkdir -p "$OUT/logs/sweep" "$OUT/shots"
SUMMARY="$OUT/logs/sweep/$TAG-summary.txt"; [[ -z "$QA_START_AT" ]] && : > "$SUMMARY"
CRASHDIR="$HOME/Library/Logs/DiagnosticReports"
ensure_booted() {
  if ! xcrun simctl list devices | grep "$UDID" | grep -q "(Booted)"; then
    xcrun simctl boot "$UDID" >/dev/null 2>&1; xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1; sleep 5
  fi
}
started=$([[ -z "$QA_START_AT" ]] && echo 1 || echo 0)
while IFS='|' read -r name secs args; do
  [[ -z "$name" || "$name" == \#* ]] && continue
  [[ "$started" == 0 && "$name" == "$QA_START_AT" ]] && started=1
  [[ "$started" == 0 ]] && continue
  if [[ "$name" == \!* ]]; then
    xcrun simctl terminate "$UDID" "$BID" >/dev/null 2>&1; sleep 1; eval "${name#!}"; continue
  fi
  for attempt in 1 2; do
    ensure_booted
    before=$(ls "$CRASHDIR" | grep -c '^iPhone-')
    xcrun simctl terminate "$UDID" "$BID" >/dev/null 2>&1; sleep 1
    LOG="$OUT/logs/sweep/$TAG-$name.log"
    xcrun simctl spawn "$UDID" log stream --style compact --predicate 'process == "iPhone"' > "$LOG" 2>&1 &
    LP=$!; sleep 1.5
    eval xcrun simctl launch "$UDID" "$BID" -skipNotificationPrompt $args $QA_EXTRA_ARGS >/dev/null 2>&1
    sleep "$secs"
    xcrun simctl io "$UDID" screenshot "$OUT/shots/$TAG-$name.png" >/dev/null 2>&1
    kill "$LP" 2>/dev/null; wait "$LP" 2>/dev/null
    after=$(ls "$CRASHDIR" | grep -c '^iPhone-')
    alive=$(xcrun simctl spawn "$UDID" launchctl list 2>/dev/null | grep -c "UIKitApplication:$BID")
    st="ok"; (( after > before )) && st="CRASH(+$((after - before)))"; [[ "$alive" == 0 ]] && st="$st DEAD"
    # A device that went down under the screen says nothing about the app: once more, from a fresh boot.
    if [[ "$attempt" == 1 && "$alive" == 0 && "$st" != CRASH* ]] && \
       { grep -q "not booted\|Bad or unknown session\|Killed" "$LOG" || ! xcrun simctl list devices | grep "$UDID" | grep -q "(Booted)"; }; then
      st="RETRIED"; continue
    fi
    break
  done
  [[ "$attempt" == 2 ]] && st="$st (retried after the device went down)"
  echo "$name: $st" | tee -a "$SUMMARY"
done < "$LIST"
xcrun simctl terminate "$UDID" "$BID" >/dev/null 2>&1
