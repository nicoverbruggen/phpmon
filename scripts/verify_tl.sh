#!/bin/bash

# Verify all Localizable.strings files using plutil.
# Returns exit code 0 if all files are valid, 1 if any fail.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PHPMON_DIR="$SCRIPT_DIR/../phpmon"

FAILED=0
CHECKED=0

for FILE in "$PHPMON_DIR"/*.lproj/Localizable.strings; do
    if [ ! -f "$FILE" ]; then
        continue
    fi

    LANG_DIR=$(basename "$(dirname "$FILE")")
    CHECKED=$((CHECKED + 1))

    if plutil -lint "$FILE" > /dev/null 2>&1; then
        echo "  OK  $LANG_DIR"
    else
        echo "FAIL  $LANG_DIR"
        plutil -lint "$FILE" 2>&1 | sed 's/^/      /'
        FAILED=$((FAILED + 1))
    fi
done

echo ""
echo "Checked $CHECKED file(s), $FAILED failure(s)."

if [ "$FAILED" -gt 0 ]; then
    exit 1
fi

exit 0
