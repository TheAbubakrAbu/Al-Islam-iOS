#!/bin/bash
# stress-screens.sh <sim|mac> <udid|-> <tag> <steps> [exclude-regex]
# "Start deep, then walk": one stress walk per line of Scripts/qa/screens.txt, launched with that screen's own
# arguments (the walk begins where they land), one result line per screen, then (mac) the restore pass.
# Needs QA_OUT; GAP= sets the seconds between steps (0.3). On the Mac the lines whose arguments WRITE
# defaults (-seed*, -lastRead, page or list mode, riwayah, traveling mode, the probes) are skipped: the walk's
# snapshot is taken after launch, so those seeds would be "restored" into the installed app's container.
# Outputs: sim $QA_OUT/stress/<tag>-<screen>.txt, mac $QA_OUT/mac/<tag>-<screen>-run.txt.
MODE="$1"; UDID="$2"; TAG="$3"; STEPS="$4"; EXCL="${5:-}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${QA_OUT:?set QA_OUT to a scratch folder}"; mkdir -p "$OUT/mac" "$OUT/stress"
LIST="$HERE/screens.txt"
if [[ "$MODE" != "sim" && "$MODE" != "mac" || -z "$TAG" || -z "$STEPS" ]]; then
  echo "usage: stress-screens.sh <sim|mac> <udid|-> <tag> <steps> [exclude-regex]"; exit 2
fi
[[ "$MODE" == "mac" && -z "$EXCL" ]] && EXCL='-seed|-lastRead|-quranPageMode|-quranListMode|-displayQiraah|-travelingMode|-mushafPageLanguage|-askAI|CatchUpProbe|RolloverProbe|-widgetGallery|-showCloudOffer|cloudBackup'
n=0
while IFS='|' read -r name secs args; do
  [[ -z "$name" || "$name" == \#* || "$name" == \!* ]] && continue
  [[ -n "$EXCL" && "$args" =~ $EXCL ]] && continue
  n=$((n+1)); seed=$((1000 + n))
  if [[ "$MODE" == "sim" ]]; then
    eval GAP="${GAP:-0.3}" "$HERE/stress-sim.sh" "$UDID" "$TAG-$name" "$STEPS" "$seed" $args > "$OUT/stress/$TAG-$name.txt" 2>&1
    line=$(grep -E "=== result" "$OUT/stress/$TAG-$name.txt" | sed "s/=== result //")
    extra=$(grep -E "NEW REPORT|HANG markers: [1-9]|STILL ALIVE" "$OUT/stress/$TAG-$name.txt" | tr '\n' ' ')
  else
    eval GAP="${GAP:-0.3}" "$HERE/stress-mac.sh" "$TAG-$name" "$STEPS" "$seed" $args > "$OUT/mac/$TAG-$name-run.txt" 2>&1
    line=$(grep -E "=== result" "$OUT/mac/$TAG-$name-run.txt" | sed "s/=== result //")
    extra=$(grep -E "NEW REPORT|HANG markers: [1-9]|STILL ALIVE|no Mac process|status: failed" "$OUT/mac/$TAG-$name-run.txt" | tr '\n' ' ')
  fi
  echo "$name (seed $seed): ${line:-NO RESULT} $extra"
done < "$LIST"
if [[ "$MODE" == "mac" ]]; then
  "$HERE/stress-mac.sh" restore restore 0 > "$OUT/mac/$TAG-restore.txt" 2>&1
  grep -E "restore pass" "$OUT/mac/$TAG-restore.txt" | tail -1 || echo "restore pass: NO LINE (read $OUT/mac/$TAG-restore.txt)"
fi
echo "=== $TAG done: $n screens"
