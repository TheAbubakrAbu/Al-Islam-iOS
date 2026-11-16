#!/bin/bash
# scroll.sh <udid> [screens file] [runs]: the scroll stopwatch over a list of screens.
#
# One cold launch per line of the screens file (default scroll-screens.txt, `name|launch arguments`),
# each with `-scrollProbe`, which scrolls the frontmost list for six seconds and reports one
# SCROLLPROBE line (see ScrollProbe in iPhone/Helpers/System/StressWalker.swift for the fields).
# The lines go to $QA_OUT/scroll-<tag>.txt (QA_TAG, default "run") and to the terminal.
#
#   QA_OUT=/tmp/al-islam-qa Scripts/qa/scroll.sh <udid>                    # every screen once
#   QA_ONLY='hadith-' Scripts/qa/scroll.sh <udid> "" 3                      # matching names, 3 runs each
#
# Compare `main` (main-thread ms per second scrolled) between two builds, never `hitch` alone: a fast
# Mac hides the frames a phone would drop. Keep the Mac quiet while it runs; a build beside it doubles
# every number.
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
here="$(cd "$(dirname "$0")" && pwd)"
udid="${1:?usage: scroll.sh <udid> [screens file] [runs]}"
screens="${2:-$here/scroll-screens.txt}"
[ -z "$screens" ] && screens="$here/scroll-screens.txt"
runs="${3:-1}"
bid="${QA_BUNDLE_ID:-com.Quran.Elmallah.Islamic-Pillars}"
out="${QA_OUT:-/tmp/al-islam-qa}"
tag="${QA_TAG:-run}"
seconds="${QA_SCROLL_SECONDS:-6}"
mkdir -p "$out"
report="$out/scroll-$tag.txt"
: > "$report"

container="$(xcrun simctl get_app_container "$udid" "$bid" data 2>/dev/null)"
[ -z "$container" ] && { echo "the app is not installed on $udid"; exit 1; }
result="$container/tmp/scrollprobe.txt"

while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in ''|\#*) continue ;; esac
    name="${line%%|*}"
    args="${line#*|}"
    [ -n "$QA_ONLY" ] && ! echo "$name" | grep -qE "$QA_ONLY" && continue
    for run in $(seq 1 "$runs"); do
        xcrun simctl terminate "$udid" "$bid" >/dev/null 2>&1
        rm -f "$result"
        sleep 1
        # eval: the screens file quotes arguments that hold spaces
        eval "xcrun simctl launch \"$udid\" \"$bid\" -skipNotificationPrompt -travelingMode 0 $args $QA_EXTRA_ARGS -scrollProbe $seconds -scrollProbeLabel \"$name\" -scrollProbeExit" >/dev/null 2>&1
        waited=0
        while [ ! -s "$result" ] && [ "$waited" -lt "${QA_SCROLL_TIMEOUT:-150}" ]; do sleep 1; waited=$((waited + 1)); done
        if [ -s "$result" ]; then
            tee -a "$report" < "$result"
        else
            echo "SCROLLPROBE label=$name view=TIMEOUT after ${waited}s" | tee -a "$report"
        fi
    done
done < "$screens"
xcrun simctl terminate "$udid" "$bid" >/dev/null 2>&1
echo "report: $report"
