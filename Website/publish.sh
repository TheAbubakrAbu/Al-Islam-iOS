#!/bin/sh
# Copies Website/public into the folder that is the GitHub Pages repository for the shared links of
# Al-Islam, Al-Quran and Al-Adhan (the repository named after the host, served at https://<host>/).
# It only copies: committing and pushing that repository stays a separate step, done by hand.
#
#   Website/publish.sh            copies to a folder named after the host, beside the app's repository
#   Website/publish.sh <folder>   copies to another folder
#   Website/publish.sh --check    after a push: asks the live site, then Apple, for the files
set -eu

here="$(cd "$(dirname "$0")" && pwd)"
app="$(cd "$here/.." && pwd)"
source="$here/public"
association="$source/.well-known/apple-app-site-association"

# The host is written once, in the app; everything else is checked against it.
host="$(sed -n 's/.*static let linkHost = "\(.*\)".*/\1/p' "$app/iPhone/Settings/Model/Globals.swift")"
if [ -z "$host" ]; then
    echo "Could not read AppIdentifiers.linkHost from Globals.swift." >&2
    exit 1
fi

# Each app has one folder of the site, named in the association file: /alislam, /alquran, /aladhan.
# Printed one per line; the script stops if an entry is not exactly one app with one folder.
folders="$(python3 - "$association" <<'PY'
import json, sys
try:
    details = json.load(open(sys.argv[1]))["applinks"]["details"]
    for entry in details:
        paths = [component["/"] for component in entry["components"]]
        name = paths[0].strip("/")
        if not name.isalpha() or paths != ["/" + name, "/" + name + "/*"] or len(entry["appIDs"]) != 1:
            sys.exit(1)
        print(name)
except Exception:
    sys.exit(1)
PY
)" || {
    echo "The association file is not valid JSON, or an entry is not one app with one folder: $association" >&2
    exit 1
}

if [ "${1:-}" = "--check" ]; then
    failed=0
    live="$(mktemp)"
    trap 'rm -f "$live"' EXIT

    # No -L on purpose: iOS does not follow a redirect to this file, so a 301 here is a failure.
    code="$(curl -s -o "$live" -w '%{http_code}' --max-time 30 "https://$host/.well-known/apple-app-site-association" || true)"
    if [ "$code" = "200" ] && cmp -s "$live" "$association"; then
        echo "ok    https://$host/.well-known/apple-app-site-association matches this repository"
    elif [ "$code" = "200" ]; then
        echo "OLD   the live association file differs from Website/public (pushed yet?)"; failed=1
    else
        echo "FAIL  the association file answered $code (it must be 200, with no redirect)"; failed=1
    fi

    addresses="links.css links.js"
    for folder in $folders; do addresses="$addresses $folder/?quran=2:255"; done
    for address in $addresses; do
        code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 30 "https://$host/$address" || true)"
        if [ "$code" = "200" ]; then
            echo "ok    https://$host/$address"
        else
            echo "FAIL  https://$host/$address answered $code"; failed=1
        fi
    done

    # iPhones never ask the site itself: they ask Apple, which fetches the file and keeps a copy
    # (byte for byte, so the two can be compared).
    code="$(curl -s -o "$live" -w '%{http_code}' --max-time 30 "https://app-site-association.cdn-apple.com/a/v1/$host" || true)"
    if [ "$code" = "200" ] && cmp -s "$live" "$association"; then
        echo "ok    Apple has this file"
    elif [ "$code" = "200" ]; then
        echo "wait  Apple still has an earlier copy of the file. It refreshes on its own, usually within a day."
    else
        echo "wait  Apple does not have the file yet (answered $code). It can take up to a day after the first push."
    fi
    exit "$failed"
fi

target="${1:-$app/../$host}"

# Refuse to publish a site that names a different host than the app.
for file in "$app/Resources/Entitlements-Main.entitlements" "$app/Resources/Entitlements-Main-CarPlay.entitlements"; do
    if ! grep -q "applinks:$host<" "$file"; then
        echo "$(basename "$file") does not name applinks:$host" >&2
        exit 1
    fi
done
for folder in $folders; do
    page="$source/$folder/index.html"
    if ! grep -q "og:image\" content=\"https://$host/$folder/" "$page" 2>/dev/null \
        || ! grep -q "data-scheme=\"$folder\"" "$page"; then
        echo "public/$folder/index.html is missing, or it does not name $host/$folder and the scheme $folder" >&2
        exit 1
    fi
done

# --delete below removes whatever is in the target and not in public/, so the target has to be
# new, empty, or recognisably an earlier copy of this site.
if [ -d "$target" ] && [ -n "$(ls -A "$target" | grep -v '^\.git$' || true)" ] \
    && [ ! -f "$target/.well-known/apple-app-site-association" ]; then
    echo "$target has other files in it and is not a copy of this site. Nothing was copied." >&2
    exit 1
fi

mkdir -p "$target"
rsync -a --delete --exclude ".git/" --exclude ".DS_Store" "$source/" "$target/"
target="$(cd "$target" && pwd)"
echo "Copied Website/public to $target"

if [ -d "$target/.git" ]; then
    changes="$(git -C "$target" status --short)"
    if [ -z "$changes" ]; then
        echo "Nothing changed since the last commit there."
    else
        echo "Changed there, not committed:"
        echo "$changes"
    fi
else
    echo "That folder is not a git repository yet (see Website/README.md)."
fi
