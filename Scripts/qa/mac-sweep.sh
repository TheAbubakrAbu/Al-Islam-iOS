#!/bin/zsh
# mac-sweep.sh <tag> [screens.txt]: the crash sweep on "My Mac (Designed for iPad)", where `open` and
# `simctl` cannot launch the app. One `xcodebuild test-without-building` per screen: the app is the
# UnitTests bundle's test host, so each run is a real launch of the app on the Mac with that screen's
# launch arguments (written into a private scheme, xcuserdata/.../QA-Mac.xcscheme, which git ignores),
# and `HostSmokeTests` keeps it running for the screen's seconds, then keeps a picture of its window.
# A crash fails the run. Per screen: ok, CRASH (a new iPhone-*.ips in DiagnosticReports) or FAILED.
#
# Needs QA_OUT. Builds once into $QA_OUT/dd-mac. Run it from Terminal or Xcode's own context: when a
# launch waits in `_dyld_start` on AppleSystemPolicy (a spindump in the result bundle says so), macOS's
# Gatekeeper is holding the new executable, not the app; 2026-09-29 it never let go until a restart.
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
HERE=${0:A:h}; ROOT=${HERE:h:h}
TAG="${1:?tag}"; LIST="${2:-$HERE/screens.txt}"
OUT="${QA_OUT:?set QA_OUT to a scratch folder}"; mkdir -p "$OUT/mac/$TAG" "$OUT/logs"
DD="$OUT/dd-mac"; DEST='platform=macOS,arch=arm64,variant=Designed for iPad'
SCHEME_DIR="$ROOT/Al-Islam.xcodeproj/xcuserdata/$USER.xcuserdatad/xcschemes"; mkdir -p "$SCHEME_DIR"
SUMMARY="$OUT/mac/$TAG/summary.txt"; : > "$SUMMARY"
CRASHDIR="$HOME/Library/Logs/DiagnosticReports"

write_scheme() {
  python3 - "$ROOT" "$SCHEME_DIR/QA-Mac.xcscheme" "$1" <<'PY'
import sys, html
root, dst, args = sys.argv[1], sys.argv[2], sys.argv[3]
t = open(f'{root}/Al-Islam.xcodeproj/xcshareddata/xcschemes/iPhone.xcscheme').read()
block = ('      <CommandLineArguments>\n         <CommandLineArgument\n            argument = "%s"\n'
         '            isEnabled = "YES">\n         </CommandLineArgument>\n      </CommandLineArguments>\n') % html.escape(args, quote=True)
i = t.index('   </LaunchAction>')
open(dst, 'w').write(t[:i] + block + t[i:])
PY
}

write_scheme "-skipNotificationPrompt -seedBool THEfirstLaunch=0"
xcodebuild build-for-testing -project "$ROOT/Al-Islam.xcodeproj" -scheme QA-Mac -destination "$DEST" \
  -derivedDataPath "$DD" -allowProvisioningUpdates > "$OUT/logs/mac-build-$TAG.log" 2>&1
grep -q "TEST BUILD SUCCEEDED" "$OUT/logs/mac-build-$TAG.log" || { echo "build failed: $OUT/logs/mac-build-$TAG.log"; exit 1; }

while IFS='|' read -r name secs args; do
  [[ -z "$name" || "$name" == \#* || "$name" == \!* ]] && continue
  write_scheme "-skipNotificationPrompt -seedBool THEfirstLaunch=0 $args"
  before=$(ls "$CRASHDIR" | grep -c '^iPhone-')
  result="$OUT/mac/$TAG/$name.xcresult"; rm -rf "$result"
  TEST_RUNNER_QA_SMOKE_SECONDS=$(( ${secs:-8} + 8 )) TEST_RUNNER_QA_SMOKE_NAME="$name" \
    xcodebuild test-without-building -project "$ROOT/Al-Islam.xcodeproj" -scheme QA-Mac -destination "$DEST" \
    -derivedDataPath "$DD" -only-testing:UnitTests/HostSmokeTests -resultBundlePath "$result" \
    > "$OUT/mac/$TAG/$name.log" 2>&1
  after=$(ls "$CRASHDIR" | grep -c '^iPhone-')
  st="ok"
  grep -q "TEST EXECUTE SUCCEEDED\|TEST SUCCEEDED" "$OUT/mac/$TAG/$name.log" || st="FAILED ($(grep -m1 -o 'encountered an error ([^)]*)\|crashed' "$OUT/mac/$TAG/$name.log"))"
  (( after > before )) && st="CRASH(+$((after - before))) $st"
  xcrun xcresulttool export attachments --path "$result" --output-path "$OUT/mac/$TAG/$name-shots" >/dev/null 2>&1
  echo "$name: $st" | tee -a "$SUMMARY"
done < "$LIST"
