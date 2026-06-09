#!/usr/bin/env python3
"""Sync Localizable.strings across locales, using en.lproj as the source of truth.

For every non-English locale this will:
  - remove STALE keys (present in the locale but no longer in en.lproj)
  - insert MISSING keys (present in en.lproj but absent in the locale), taking the
    translation from a JSON payload, placed at the position that mirrors en.lproj
    (right after the nearest preceding key that the locale already has)

Insertion points are derived from en.lproj automatically, so there are no
hand-maintained anchors. Existing keys are never touched, so it is safe to re-run.

Payload format (JSON): { "<key>": { "<locale>": "<translation>", ... }, ... }
Use "\\n" in payload strings to emit a literal \\n into the .strings file.

Usage:
  python3 scripts/sync_translations.py [payload.json] [--keep-stale] [--dry-run]

Defaults to scripts/translations.json. Run scripts/verify_tl.sh afterwards.
"""
import json
import os
import sys

ROOT = os.path.join(os.path.dirname(__file__), "..", "phpmon")
EN = os.path.join(ROOT, "en.lproj", "Localizable.strings")


def key_of(line):
    s = line.lstrip()
    if not s.startswith('"'):
        return None
    end = s.find('"', 1)
    return s[1:end] if end != -1 else None


def ordered_keys(path):
    """Return keys in file order, ignoring comments/blank lines."""
    with open(path, encoding="utf-8") as f:
        return [k for k in (key_of(ln) for ln in f) if k is not None]


def find_index(lines, key):
    for i, ln in enumerate(lines):
        if key_of(ln) == key:
            return i
    return None


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    flags = {a for a in sys.argv[1:] if a.startswith("--")}
    payload_path = args[0] if args else os.path.join(os.path.dirname(__file__), "translations.json")
    keep_stale = "--keep-stale" in flags
    dry_run = "--dry-run" in flags

    with open(payload_path, encoding="utf-8") as f:
        payload = json.load(f)

    en_order = ordered_keys(EN)
    en_set = set(en_order)

    locales = sorted(
        d[:-6] for d in os.listdir(ROOT)
        if d.endswith(".lproj") and d != "en.lproj"
    )

    total_added = total_removed = 0
    untranslated = {}

    for loc in locales:
        path = os.path.join(ROOT, loc + ".lproj", "Localizable.strings")
        with open(path, encoding="utf-8") as f:
            lines = f.read().split("\n")

        # Remove stale keys (in locale, not in en).
        removed = []
        if not keep_stale:
            kept = []
            for ln in lines:
                k = key_of(ln)
                if k is not None and k not in en_set:
                    removed.append(k)
                else:
                    kept.append(ln)
            lines = kept

        present = {key_of(ln) for ln in lines if key_of(ln)}

        # Insert missing keys in en order, so consecutive inserts keep en ordering.
        added = []
        missing_no_tr = []
        for k in en_order:
            if k in present:
                continue
            translation = payload.get(k, {}).get(loc)
            if translation is None:
                missing_no_tr.append(k)
                continue

            # Anchor = nearest preceding en key that the locale currently has.
            anchor_idx = None
            ei = en_order.index(k)
            for j in range(ei - 1, -1, -1):
                anchor_idx = find_index(lines, en_order[j])
                if anchor_idx is not None:
                    break

            new_line = '"%s" = "%s";' % (k, translation)
            insert_at = (anchor_idx + 1) if anchor_idx is not None else 0
            lines.insert(insert_at, new_line)
            present.add(k)
            added.append(k)

        if missing_no_tr:
            untranslated[loc] = missing_no_tr

        if not dry_run and (added or removed):
            with open(path, "w", encoding="utf-8") as f:
                f.write("\n".join(lines))

        total_added += len(added)
        total_removed += len(removed)
        print("%-10s +%d  -%d%s" % (
            loc, len(added), len(removed),
            "  (%d still untranslated)" % len(missing_no_tr) if missing_no_tr else ""
        ))

    print("\nTotal: +%d added, -%d stale removed%s" % (
        total_added, total_removed, "  [dry-run]" if dry_run else ""
    ))
    if untranslated:
        keys = sorted({k for ks in untranslated.values() for k in ks})
        print("\nKeys in en.lproj with no translation in the payload (%d):" % len(keys))
        for k in keys:
            print("  - " + k)


if __name__ == "__main__":
    main()
