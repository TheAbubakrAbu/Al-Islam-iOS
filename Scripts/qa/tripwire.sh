#!/bin/zsh
# tripwire.sh <udid>: launch paused for the debugger, attach lldb with a breakpoint on AppearanceDefaultTripwire.note,
# print the backtrace of the first hit, detach.
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
UDID="$1"; BID=com.Quran.Elmallah.Islamic-Pillars
SCR="${QA_OUT:?set QA_OUT to a scratch folder}"
xcrun simctl terminate $UDID $BID >/dev/null 2>&1; sleep 1
pid=$(xcrun simctl launch --wait-for-debugger $UDID $BID -skipNotificationPrompt | awk -F': ' '{print $2}')
echo "pid=$pid"
xcrun lldb -p $pid -s "${0:A:h}/tripwire.lldb" > $SCR/logs/tripwire.txt 2>&1 &
lp=$!
for i in $(seq 1 60); do sleep 1; grep -q "frame #1" $SCR/logs/tripwire.txt && break; done
sleep 3
kill $lp 2>/dev/null
xcrun simctl terminate $UDID $BID >/dev/null 2>&1
grep -E "frame #" $SCR/logs/tripwire.txt | grep -vE "libswift|SwiftUICore|SwiftUI\`|AttributeGraph|UIKitCore|CoreFoundation|libdispatch|GraphicsServices|dyld|libsystem" | head -25 | cut -c1-220
echo "--- raw head"; grep -E "frame #[0-9]+:" $SCR/logs/tripwire.txt | head -45 | cut -c1-200
