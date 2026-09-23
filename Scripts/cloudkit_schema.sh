#!/usr/bin/env bash
# The CloudKit schema for iCloud Backup, from the terminal (docs/iCloud Sync Guide.md, section 2).
#
# CloudKit has two environments. A build run from Xcode talks to DEVELOPMENT, where a record type
# is created the first time a record of it is saved. A TestFlight or App Store build (Xcode Cloud's
# included) talks to PRODUCTION, where nothing is ever created on the fly: every save fails with
# "Cannot create new type Profile in production schema" until the schema is deployed there.
#
#   Scripts/cloudkit_schema.sh token          save a CloudKit management token, once per Mac: copy
#                                             it in the Console, then run this line on its own
#   Scripts/cloudkit_schema.sh status         is Profile in development? in production? complete?
#   Scripts/cloudkit_schema.sh import         add Profile to DEVELOPMENT (validated first)
#   Scripts/cloudkit_schema.sh deploy         checks both environments and prints the CloudKit
#                                             Console clicks that deploy Profile to PRODUCTION
#   Scripts/cloudkit_schema.sh validate       check the file `import` would send
#   Scripts/cloudkit_schema.sh export ENV     print an environment's schema (development|production)
#
# The token: CloudKit Console (https://icloud.developer.apple.com), click your NAME at the top
# right (not the three-line menu beside it), Settings, Tokens, Create Management Token, for the
# team that owns the container. Copy it right away: it is shown once. `token` reads it from the
# clipboard (or `token <token>`, or a hidden prompt), checks it with CloudKit, and keeps it in the
# login keychain, never in the repo. A copy that picked up text after the token (it happened:
# "...asked") is cut back to the token only when CloudKit accepts the shorter form. The app never
# uses the token: when it expires, only this script stops working.
#
# import never sends Resources/CloudKit/Profile.ckdb on its own. Schema files are declarative, so
# a file holding Profile alone could drop every other record type there. It exports the live
# development schema, swaps Profile's block from the .ckdb into it (replacing an older Profile
# block, if any), and sends that. Nothing else in the schema changes.
#
# Production cannot be written from here: cktool's schema endpoints answer "endpoint not
# applicable in the environment 'production'" (tried 2026-09-23). Production only ever receives
# a deploy of development, from the CloudKit Console's "Deploy Schema Changes..." button.
#
# A sibling app: CONTAINER_ID=iCloud.Its.Container Scripts/cloudkit_schema.sh import (same team).

set -euo pipefail

TEAM_ID="${TEAM_ID:-8HQMC4MQ59}"
CONTAINER_ID="${CONTAINER_ID:-iCloud.Elmallah.IslamicPillars}"
RECORD_TYPE="${RECORD_TYPE:-Profile}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCHEMA="${SCHEMA:-$ROOT/Resources/CloudKit/$RECORD_TYPE.ckdb}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# xcode-select on this machine points at the Command Line Tools; cktool wants Xcode's.
if [ -z "${DEVELOPER_DIR:-}" ] && [ -d /Applications/Xcode.app/Contents/Developer ]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

cktool() { xcrun cktool "$@"; }
ids() { echo --team-id "$TEAM_ID" --container-id "$CONTAINER_ID"; }

usage() {
    awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

# Checks a pasted token with CloudKit, then keeps it in the keychain. Management tokens are HS512
# JWTs, whose signature is 86 characters; when the whole string is refused and its signature is
# longer, the 86-character form is tried, and kept only if CloudKit accepts it.
save_token() {
    local tok sig trimmed
    tok="$(printf %s "$1" | tr -d '[:space:]')"
    if [[ "$tok" != eyJ*.*.* ]]; then
        echo "That is not a CloudKit token: they start with eyJ and have two dots. Nothing was saved." >&2
        echo "Copy the token in the CloudKit Console, then run: Scripts/cloudkit_schema.sh token" >&2
        exit 2
    fi
    if ! cktool get-teams --token "$tok" >/dev/null 2>&1; then
        sig="${tok##*.}"
        trimmed="${tok%.*}.${sig:0:86}"
        if [ ${#sig} -gt 86 ] && cktool get-teams --token "$trimmed" >/dev/null 2>&1; then
            echo "Removed $(( ${#sig} - 86 )) stray characters after the token (\"${sig:86}\"), picked up by the copy."
            tok="$trimmed"
        else
            echo "CloudKit refused that token: expired, revoked, or not copied whole. Nothing was saved." >&2
            exit 2
        fi
    fi
    cktool save-token "$tok" --type management --method keychain --force >/dev/null
    echo "Saved in the keychain. The teams this token can reach:"
    cktool get-teams
    echo "Team $TEAM_ID owns $CONTAINER_ID and must be in that list."
}

need_token() {
    if ! cktool get-teams >/dev/null 2>&1; then
        echo "No working CloudKit management token on this Mac: none was saved, or it expired." >&2
        echo "An expired token breaks only this script. The app and the deployed schema are unaffected." >&2
        echo "Create one in the CloudKit Console: your name at the top right, Settings, Tokens, Create Management Token." >&2
        echo "Copy it, then run: Scripts/cloudkit_schema.sh token" >&2
        exit 2
    fi
}

need_schema() {
    if [ ! -f "$SCHEMA" ]; then
        echo "Schema file not found: $SCHEMA" >&2
        exit 2
    fi
}

# The custom fields of the record type in a schema text on stdin: "name TYPE" per line, sorted.
fields_in() {
    awk -v type="$RECORD_TYPE" '
        $0 ~ "RECORD TYPE " type " *\\(" { inside = 1; next }
        inside && /^[[:space:]]*\);/ { inside = 0 }
        inside && $1 != "GRANT" && /^[[:space:]]*[A-Za-z][A-Za-z0-9]*[[:space:]]+[A-Z]/ { print $1, $2 }
    ' | tr -d ',' | sort
}

has_type() { grep -q "RECORD TYPE $RECORD_TYPE *(" "$1"; }

# What the .ckdb declares that a live schema file lacks ("name TYPE" lines; empty when complete).
missing_in() { comm -13 <(fields_in <"$1") <(fields_in <"$SCHEMA") || true; }

is_complete() { has_type "$1" && [ -z "$(missing_in "$1")" ]; }

# Profile's block in the .ckdb: from "RECORD TYPE Profile (" through its closing ");".
profile_block() {
    awk -v type="$RECORD_TYPE" '
        $0 ~ "RECORD TYPE " type " *\\(" { inside = 1 }
        inside { print }
        inside && /^[[:space:]]*\);/ { exit }
    ' "$SCHEMA"
}

# An environment's live schema, into a file. Exits when it cannot be read.
export_to() {
    cktool export-schema $(ids) --environment "$1" --output-file "$2" >/dev/null
    if ! grep -q "DEFINE SCHEMA" "$2"; then
        echo "The $1 schema came back empty or unreadable:" >&2
        head -5 "$2" >&2
        exit 1
    fi
}

# LIVE with its Profile block (if any) replaced by the .ckdb's, everything else verbatim, into OUT.
merge_into() {
    {
        awk -v type="$RECORD_TYPE" '
            $0 ~ "RECORD TYPE " type " *\\(" { skip = 1 }
            !skip { print }
            skip && /^[[:space:]]*\);/ { skip = 0 }
        ' "$1"
        echo
        profile_block
    } >"$2"
}

status_of() {
    local env="$1" live="$WORK/$1-status.ckdb"
    if ! cktool export-schema $(ids) --environment "$env" --output-file "$live" >"$WORK/err" 2>&1 \
        || ! grep -q "DEFINE SCHEMA" "$live"; then
        echo "$env: could not read the schema ($(tail -1 "$WORK/err"))"
        return
    fi
    if ! has_type "$live"; then
        echo "$env: no $RECORD_TYPE record type. Every save from a build on this environment fails."
    elif is_complete "$live"; then
        echo "$env: $RECORD_TYPE with every field in $(basename "$SCHEMA") ($(fields_in <"$SCHEMA" | grep -c .) fields)."
    else
        echo "$env: $RECORD_TYPE is there but misses:"
        missing_in "$live" | sed 's/^/    /'
    fi
}

console_deploy_steps() {
    cat <<MSG
Deploy it from the CloudKit Console (cktool cannot write to production):
  1. Open https://icloud.developer.apple.com and choose CloudKit Database.
  2. In the picker at the top, choose the container $CONTAINER_ID,
     and make sure the environment beside it says Development.
  3. At the very bottom of the left sidebar, click "Deploy Schema Changes...".
  4. The sheet lists what goes to production: record type $RECORD_TYPE and its fields. Click Deploy.
Then check with: Scripts/cloudkit_schema.sh status
MSG
}

case "${1:-}" in
    eyJ*)
        # The token typed where a command goes: saved all the same.
        save_token "$1"
        ;;
    token)
        tok="${2:-}"
        if [ -z "$tok" ]; then
            clip="$(${CLIPBOARD_CMD:-pbpaste} 2>/dev/null | tr -d '[:space:]' || true)"
            if [[ "$clip" == eyJ*.*.* ]]; then
                echo "Using the token on the clipboard."
                tok="$clip"
            else
                printf "Paste the management token and press Return (it will not show): " >&2
                IFS= read -rs tok || true
                echo >&2
            fi
        fi
        save_token "$tok"
        ;;
    validate)
        need_schema; need_token
        export_to development "$WORK/development-live.ckdb"
        merge_into "$WORK/development-live.ckdb" "$WORK/development-merged.ckdb"
        cktool validate-schema $(ids) --environment development --file "$WORK/development-merged.ckdb"
        echo "OK: development's schema plus $RECORD_TYPE is valid for $CONTAINER_ID."
        ;;
    import)
        need_schema; need_token
        export_to development "$WORK/development-live.ckdb"
        if is_complete "$WORK/development-live.ckdb"; then
            echo "DEVELOPMENT already has $RECORD_TYPE with every field. Nothing to import."
        else
            merge_into "$WORK/development-live.ckdb" "$WORK/development-merged.ckdb"
            cktool import-schema --validate $(ids) --environment development --file "$WORK/development-merged.ckdb"
            echo "Imported $RECORD_TYPE into DEVELOPMENT. A build run from Xcode can save now."
        fi
        echo "TestFlight and App Store builds need production: Scripts/cloudkit_schema.sh deploy"
        ;;
    deploy)
        need_schema; need_token
        export_to production "$WORK/production-live.ckdb"
        if is_complete "$WORK/production-live.ckdb"; then
            echo "PRODUCTION already has $RECORD_TYPE with every field. TestFlight and App Store builds can save."
            exit 0
        fi
        export_to development "$WORK/development-live.ckdb"
        if ! is_complete "$WORK/development-live.ckdb"; then
            echo "DEVELOPMENT does not have the complete $RECORD_TYPE yet, so the Console has nothing to deploy."
            echo "First run: Scripts/cloudkit_schema.sh import"
            exit 1
        fi
        echo "DEVELOPMENT has $RECORD_TYPE with every field; PRODUCTION does not yet."
        console_deploy_steps
        exit 1
        ;;
    status)
        need_schema; need_token
        echo "Container $CONTAINER_ID, team $TEAM_ID, record type $RECORD_TYPE"
        status_of development
        status_of production
        ;;
    export)
        need_token
        export_to "${2:-development}" "$WORK/export.ckdb"
        cat "$WORK/export.ckdb"
        ;;
    *)
        usage
        exit 2
        ;;
esac
