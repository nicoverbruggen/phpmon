#!/bin/bash

# Report localization coverage for every Localizable.strings file, using the
# English (`en.lproj`) file as the source of truth.
#
# For each locale it lists:
#   - MISSING keys: present in en.lproj but absent in the locale
#   - STALE keys:   present in the locale but no longer in en.lproj
#
# Keys are extracted via `plutil -convert json` so quoting/escaping is handled
# correctly (rather than fragile text parsing).
#
# Usage:
#   scripts/find_missing_tl.sh            # human-readable report
#   scripts/find_missing_tl.sh --keys     # also print every missing/stale key

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PHPMON_DIR="$SCRIPT_DIR/../phpmon"
EN_FILE="$PHPMON_DIR/en.lproj/Localizable.strings"

SHOW_KEYS=0
[ "$1" = "--keys" ] && SHOW_KEYS=1

keys_of() {
    plutil -convert json -o - "$1" | jq -r 'keys[]' | sort
}

EN_KEYS="$(keys_of "$EN_FILE")"
EN_COUNT="$(echo "$EN_KEYS" | grep -c .)"
echo "Reference: en.lproj ($EN_COUNT keys)"
echo ""

TOTAL_MISSING=0

for FILE in "$PHPMON_DIR"/*.lproj/Localizable.strings; do
    LANG_DIR=$(basename "$(dirname "$FILE")")
    [ "$LANG_DIR" = "en.lproj" ] && continue

    LOCALE_KEYS="$(keys_of "$FILE")"

    # In en but not in this locale.
    MISSING="$(comm -23 <(echo "$EN_KEYS") <(echo "$LOCALE_KEYS"))"
    # In this locale but not in en.
    STALE="$(comm -13 <(echo "$EN_KEYS") <(echo "$LOCALE_KEYS"))"

    MISSING_COUNT="$(echo "$MISSING" | grep -c .)"
    STALE_COUNT="$(echo "$STALE" | grep -c .)"
    TOTAL_MISSING=$((TOTAL_MISSING + MISSING_COUNT))

    printf '%-14s missing: %-3s stale: %-3s\n' "$LANG_DIR" "$MISSING_COUNT" "$STALE_COUNT"

    if [ "$SHOW_KEYS" -eq 1 ]; then
        [ "$MISSING_COUNT" -gt 0 ] && echo "$MISSING" | sed 's/^/    - missing: /'
        [ "$STALE_COUNT" -gt 0 ] && echo "$STALE" | sed 's/^/    - stale:   /'
    fi
done

echo ""
echo "Total missing translations across locales: $TOTAL_MISSING"
