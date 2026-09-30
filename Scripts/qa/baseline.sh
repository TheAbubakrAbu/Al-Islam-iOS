#!/bin/zsh
# baseline.sh [tag]: the full baseline in the order the Quality Guide gives (Appendix A): a Debug build and
# install, the sweep over screens.txt, analyze.py, the in-app audits, the idle counters and the launch
# stopwatch. About 35 minutes on the iPhone 17 Pro simulator. Everything lands in $QA_OUT.
# The sanitizer runs (tsan.sh, which needs a TSan build in $QA_OUT/dd-tsan) and the tripwire backtrace
# (tripwire.sh) are separate: run them by hand when an item asks for them.
HERE=${0:A:h}; TAG=${1:-base}
: "${QA_OUT:?set QA_OUT to a scratch folder}"
UDID=$($HERE/device.sh) || { echo "no iPhone 17 Pro simulator"; exit 1; }
echo "== device $UDID, output $QA_OUT"
$HERE/build.sh "$TAG" Debug | tail -3
$HERE/sweep.sh "$UDID" "$HERE/screens.txt" "$TAG" > "$QA_OUT/logs/sweep-$TAG.out" 2>&1; tail -3 "$QA_OUT/logs/sweep-$TAG.out"
python3 $HERE/analyze.py "$TAG" | tee "$QA_OUT/logs/analyze-$TAG.txt" | tail -30
$HERE/audits.sh "$UDID" | tail -20
$HERE/idle.sh "$UDID"
$HERE/launch.sh "$UDID" 5
