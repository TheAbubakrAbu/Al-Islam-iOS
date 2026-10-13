#!/bin/bash
# stress-sim.sh <udid> <tag> <steps> <seed> [extra launch args...]
# One in-process stress walk (StressWalker.swift, "-stressWalk") on a simulator: terminates the app, streams
# its STRESS lines, launches it with -stressWalk ... -stressExit, waits until the process is gone (or a cap),
# then reports crash reports that appeared, HANG markers and the last trail lines. Needs QA_OUT; GAP= sets
# the seconds between steps (0.3). The installed build must carry the walker (a Debug build).
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
UDID="$1"; TAG="$2"; STEPS="$3"; SEED="$4"; shift 4
BID=com.Quran.Elmallah.Islamic-Pillars
OUT="${QA_OUT:?set QA_OUT to a scratch folder}"; mkdir -p "$OUT/stress/$TAG"
CRASHDIR="$HOME/Library/Logs/DiagnosticReports"
SINCE=$(date +%s)
xcrun simctl terminate "$UDID" "$BID" >/dev/null 2>&1; sleep 1
LOG="$OUT/stress/$TAG/log.txt"
xcrun simctl spawn "$UDID" log stream --style compact --predicate 'process == "iPhone" AND (eventMessage CONTAINS "STRESS" OR messageType == fault OR eventMessage CONTAINS "Fatal error")' > "$LOG" 2>&1 &
LP=$!; sleep 1.5
GAP="${GAP:-0.3}"
xcrun simctl launch "$UDID" "$BID" -skipNotificationPrompt -stressWalk "$STEPS" -stressSeed "$SEED" -stressGap "$GAP" -stressExit "$@" > "$OUT/stress/$TAG/launch.txt" 2>&1
echo "launched: -stressWalk $STEPS -stressSeed $SEED -stressGap $GAP $*"
CAP=$(( STEPS * 2 + 90 )); t=0; hung=0
while (( t < CAP )); do
  sleep 5; t=$((t+5))
  xcrun simctl spawn "$UDID" launchctl list 2>/dev/null | grep -q "UIKitApplication:$BID" || break
  # The walk's watchdog logs "STRESS n HANG" after 12 s of main-thread silence: sample the process at once
  # (a deadlock's stacks, or whatever holds the main thread), then let the walk go on.
  if grep -q "HANG main thread" "$LOG" 2>/dev/null && (( hung == 0 )); then
    hung=1; echo "HANG reported at ${t}s - sampling"
    hp=$(xcrun simctl spawn "$UDID" launchctl list | grep "UIKitApplication:$BID" | awk '{print $1}' | head -1)
    sample "$hp" 3 -file "$OUT/stress/$TAG/sample-hang.txt" >/dev/null 2>&1
  fi
done
alive=$(xcrun simctl spawn "$UDID" launchctl list 2>/dev/null | grep -c "UIKitApplication:$BID")
if (( alive > 0 )); then
  echo "STILL ALIVE after ${t}s (hang?) - sampling"
  pid=$(xcrun simctl spawn "$UDID" launchctl list | grep "UIKitApplication:$BID" | awk '{print $1}' | head -1)
  sample "$pid" 3 -file "$OUT/stress/$TAG/sample.txt" >/dev/null 2>&1
  xcrun simctl io "$UDID" screenshot "$OUT/stress/$TAG/hang.png" >/dev/null 2>&1
  xcrun simctl terminate "$UDID" "$BID" >/dev/null 2>&1
fi
sleep 2; kill "$LP" 2>/dev/null; wait "$LP" 2>/dev/null
NEWREPORTS=$(python3 "$(dirname "$0")/ipsmatch.py" "$UDID" "$SINCE"); after=$(echo "$NEWREPORTS" | grep -c .)
C=$(xcrun simctl get_app_container "$UDID" "$BID" data 2>/dev/null)
cp "$C/Library/stress/trail-$SEED.log" "$OUT/stress/$TAG/trail.log" 2>/dev/null
echo "=== result $TAG: seconds=$t alive=$alive hung=$hung crashes=$after trail=$(wc -l < "$OUT/stress/$TAG/trail.log" 2>/dev/null) lines"
echo "$NEWREPORTS" | grep . | sed 's/^/  NEW REPORT: /'
grep -c "HANG" "$OUT/stress/$TAG/trail.log" 2>/dev/null | sed 's/^/  HANG markers: /'
tail -4 "$OUT/stress/$TAG/trail.log" 2>/dev/null | cut -c1-200
