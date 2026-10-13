#!/bin/bash
# stress-mac.sh <tag> <steps|restore> <seed> [extra launch args...]
# A stress walk of the app on "My Mac (Designed for iPad)", launched BY XCODE (AppleScript): Xcode's
# launcher is the only one on this Mac that is not held at _dyld_start by the system policy daemon
# (xcodebuild's test host, `open` on a wrapper: all parked, 2026-10-12). The private QA-Mac scheme
# (xcuserdata, git-ignored) carries the launch arguments and launches WITHOUT the debugger, so a crash
# writes an .ips report. WeatherKit is taken out of the entitlements for the build (the local profile
# lacks it) and the file is restored once the app is up (or the run gave up).
# Needs QA_OUT and a shell that may launch GUI apps (not a sandboxed one). Reports: new Mac crash reports,
# .hang files, the STRESS trail from the unified log (the container is unreadable from outside), HANG
# markers; a walk that reports a hang is sampled at once (the deadlock's stacks) and killed.
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
TAG="$1"; STEPS="$2"; SEED="$3"; shift 3
HERE="$(cd "$(dirname "$0")" && pwd)"; ROOT="$(dirname "$(dirname "$HERE")")"
OUT="${QA_OUT:?set QA_OUT to a scratch folder}"
ENT="$ROOT/Resources/Entitlements-Main.entitlements"
PROJ="$ROOT/Al-Islam.xcodeproj"
mkdir -p "$OUT/mac/$TAG"
GAP="${GAP:-0.35}"
if [[ "$STEPS" == "restore" ]]; then
  ARGS="-skipNotificationPrompt -stressTag $TAG -stressRestore -stressExit"; CAP=240
else
  ARGS="-skipNotificationPrompt -stressTag $TAG -stressWalk $STEPS -stressSeed $SEED -stressGap $GAP -stressExit $*"; CAP=$(( STEPS * 2 + 240 ))
fi
python3 "$HERE/write_mac_scheme.py" "$ARGS" > /dev/null
sleep "${SCHEME_SETTLE:-20}"   # Xcode re-reads a changed scheme file on its own, given a moment
cp "$ENT" "$OUT/mac/entitlements.orig"
python3 - "$ENT" <<'PY'
import sys,plistlib
p=sys.argv[1]; d=plistlib.load(open(p,'rb')); d.pop('com.apple.developer.weatherkit',None); plistlib.dump(d,open(p,'wb'))
PY
restore_ent() { cp "$OUT/mac/entitlements.orig" "$ENT"; }
trap restore_ent EXIT
CRASHDIR="$HOME/Library/Logs/DiagnosticReports"; HANGDIR="/Library/Logs/DiagnosticReports"
SINCE=$(date +%s); hbefore=$(ls "$HANGDIR" 2>/dev/null | grep -c '^iPhone.*\.hang')
# Any leftover Mac instance would be re-activated instead of launched.
for p in $(pgrep -x iPhone); do ps -o args= -p $p | grep -q CoreSimulator || kill -9 $p; done
START=$(date "+%Y-%m-%d %H:%M:%S")
echo "=== $TAG: $ARGS (cap ${CAP}s)"
# Wait for the app (the build runs first). Xcode re-reads the changed scheme file on its own but not
# always within the settle time: the launched process must carry this run's token, or it is a stale
# launch and the run is repeated (Xcode has read the file by then).
launch_once() {
  : > "$OUT/mac/$TAG/xcode.log"
  perl -e 'alarm 1800; exec @ARGV' osascript "$HERE/xcode-run-mac.scpt" "$PROJ" "$OUT/mac/$TAG/xcode.log" > "$OUT/mac/$TAG/osascript.out" 2>&1 &
  AS=$!
}
# Xcode's run goes on once the AppleScript has issued it, whether or not that script is still alive;
# so the wait is for the PROCESS, for up to five minutes, and the script is started again only when
# it died before it could issue the run (no "status:" line in its log).
pid=""; t=0; scripts=0
launch_once; scripts=1
while (( t < 300 )); do
  sleep 3; t=$((t+3))
  pid=$(pgrep -x iPhone | while read x; do ps -o args= -p "$x" | grep -v CoreSimulator >/dev/null && echo "$x"; done | head -1)
  if [[ -n "$pid" ]]; then
    if ps -o args= -p "$pid" | grep -q -- "-stressTag $TAG "; then break; fi
    # A process without this run's token is a stale launch (Xcode had not re-read the scheme): kill it,
    # and let the loop go on (a new script run below if the old one is gone).
    echo "stale launch ($(ps -o args= -p "$pid" | grep -oE -- '-stressTag [^ ]+')) killed at ${t}s"; kill -9 "$pid"; pid=""
  fi
  if ! kill -0 $AS 2>/dev/null && ! grep -q "status:" "$OUT/mac/$TAG/xcode.log" && (( scripts < 4 )); then
    echo "the AppleScript ended before issuing the run (attempt $scripts); starting it again"
    sleep 5; launch_once; scripts=$((scripts+1))
  fi
  if grep -q "status: failed" "$OUT/mac/$TAG/xcode.log"; then break; fi
done
restore_ent
if [[ -z "$pid" ]]; then
  echo "no Mac process after ${t}s; Xcode said:"; cat "$OUT/mac/$TAG/xcode.log"; tail -3 "$OUT/mac/$TAG/osascript.out"; exit 1
fi
echo "app pid $pid after ${t}s: $(ps -o args= -p $pid | cut -c1-200)"
sleep 6
sample "$pid" 1 -file "$OUT/mac/$TAG/sample-start.txt" >/dev/null 2>&1
echo "+6s: rss=$(ps -o rss= -p $pid 2>/dev/null) frame: $(sed -n '/^Call graph/,/^$/p' "$OUT/mac/$TAG/sample-start.txt" | sed -n '3p' | cut -c1-100)"
# Wait for the walk to end (the process exits with -stressExit). The walk's own watchdog logs
# "STRESS n HANG" after 12 s of main-thread silence: the moment it does, the process is sampled (the
# deadlock's stacks) and killed, so a frozen walk costs seconds, not the cap.
t=0; hung=0
while (( t < CAP )); do
  sleep 5; t=$((t+5))
  kill -0 "$pid" 2>/dev/null || break
  if (( t % 10 == 0 )) && /usr/bin/log show --last 15s --style compact --predicate "processID == $pid AND eventMessage CONTAINS \"STRESS\" AND eventMessage CONTAINS \"HANG\"" 2>/dev/null | grep -q HANG; then
    hung=1; echo "HANG reported at ${t}s - sampling"
    sample "$pid" 3 -file "$OUT/mac/$TAG/sample-hang.txt" >/dev/null 2>&1
    spindump "$pid" 3 -file "$OUT/mac/$TAG/spindump-hang.txt" >/dev/null 2>&1
    sleep 20
    if kill -0 "$pid" 2>/dev/null; then sample "$pid" 2 -file "$OUT/mac/$TAG/sample-hang2.txt" >/dev/null 2>&1; kill -9 "$pid"; echo "killed the hung process"; fi
    break
  fi
done
alive=0
if kill -0 "$pid" 2>/dev/null; then
  alive=1; echo "STILL ALIVE after ${t}s (hang?) - sampling and killing"
  sample "$pid" 3 -file "$OUT/mac/$TAG/sample-hang.txt" >/dev/null 2>&1
  kill -9 "$pid"
fi
sleep 3
NEWREPORTS=$(python3 "$HERE/ipsmatch.py" mac "$SINCE"); after=$(echo "$NEWREPORTS" | grep -c .); hafter=$(ls "$HANGDIR" 2>/dev/null | grep -c '^iPhone.*\.hang')
/usr/bin/log show --start "$START" --style compact --predicate 'process == "iPhone" AND (eventMessage CONTAINS "STRESS" OR eventMessage CONTAINS "Fatal error")' 2>/dev/null | grep -v "^Timestamp" > "$OUT/mac/$TAG/trail.log"
echo "=== result $TAG: ran ${t}s alive=$alive hung=$hung crashes=$after hangs=$((hafter - hbefore)) trail=$(wc -l < "$OUT/mac/$TAG/trail.log") lines"
echo "$NEWREPORTS" | grep . | sed 's/^/  NEW REPORT: /'
grep -c "HANG" "$OUT/mac/$TAG/trail.log" | sed 's/^/  HANG markers: /'
echo "--- xcode"; cat "$OUT/mac/$TAG/xcode.log" | tail -6
echo "--- trail tail"; tail -5 "$OUT/mac/$TAG/trail.log" | cut -c1-240
kill $AS 2>/dev/null
