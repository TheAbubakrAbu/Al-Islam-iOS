#!/bin/zsh
# device.sh: prints the UDID of the iPhone 17 Pro simulator the QA runs use: a booted one on the newest
# iOS runtime if there is one, otherwise the last one listed on that runtime. `QA_UDID=<udid>` overrides it.
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
if [[ -n "$QA_UDID" ]]; then echo "$QA_UDID"; exit 0; fi
newest=$(xcrun simctl list devices available | awk '/^-- iOS /{rt=$0} /iPhone 17 Pro \(/{print rt}' | tail -1)
lines=$(xcrun simctl list devices available | awk -v rt="$newest" '/^-- /{on=($0==rt)} on && /iPhone 17 Pro \(/')
pick=$(echo "$lines" | grep "(Booted)" | head -1); [[ -z "$pick" ]] && pick=$(echo "$lines" | tail -1)
echo "$pick" | grep -oE '[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}' | head -1
