#!/bin/bash
# stress-mac-seeds.sh <steps> <seed...>: consecutive Mac walks (stress-mac.sh, one per seed), one result line
# each, then the restore pass. Needs QA_OUT; GAP= sets the seconds between steps (0.3). Per seed the driver's
# full output is $QA_OUT/mac/w<steps>-<seed>-run.txt and the run's files are in $QA_OUT/mac/w<steps>-<seed>/.
# Run it in the background (20 seeds of 400 steps take about an hour) and read the -run.txt files as they land.
# Needs a shell that may launch GUI apps (the harness sandbox off): see docs/Mac Crash Sweep Guide.md.
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${QA_OUT:?set QA_OUT to a scratch folder}"; mkdir -p "$OUT/mac"
STEPS="$1"; shift
[[ -z "$STEPS" || -z "$1" ]] && { echo "usage: stress-mac-seeds.sh <steps> <seed...>"; exit 2; }
for s in "$@"; do
  tag="w$STEPS-$s"
  GAP="${GAP:-0.3}" "$HERE/stress-mac.sh" "$tag" "$STEPS" "$s" > "$OUT/mac/$tag-run.txt" 2>&1
  grep -E "=== result|NEW REPORT|HANG markers: [1-9]|STILL ALIVE|no Mac process|status: failed" "$OUT/mac/$tag-run.txt" \
    || echo "$tag: NO RESULT LINE (read $OUT/mac/$tag-run.txt)"
done
"$HERE/stress-mac.sh" restore restore 0 > "$OUT/mac/restore-run.txt" 2>&1
grep -E "restore pass" "$OUT/mac/restore-run.txt" | tail -1 || echo "restore pass: NO LINE (read $OUT/mac/restore-run.txt)"
echo "=== seeds done: $*"
