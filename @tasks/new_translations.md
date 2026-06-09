# Updating translations

PHP Monitor keeps a `Localizable.strings` file per locale under `phpmon/*.lproj/`.
`en.lproj` is the source of truth. When new English keys are added (or old ones
removed), the other locales need to be brought back in sync.

You no longer need to be told which strings changed — discover it programmatically
with the localization scripts. See `scripts/README.md` for full details.

## Steps

1. **Find what's out of sync.** Run the coverage report:

   ```bash
   ./scripts/find_missing_tl.sh --keys
   ```

   This lists, per locale, every key that is **missing** (in `en.lproj` but not the
   locale) and **stale** (in the locale but no longer in `en.lproj`). The missing
   keys are the same set across locales, so you only need to read each English
   source string once.

2. **Read the English source** for each missing key (and only those keys — never
   read an entire `.strings` file, they are too long):

   ```bash
   grep -n '^"<key>"' phpmon/en.lproj/Localizable.strings
   ```

3. **Translate** each missing key into every locale and add them to the payload
   `scripts/translations.json`, as `key → { locale → translation }`. This file is a
   transient working file — it is gitignored and **must not be committed**; it is
   deleted again in the final step:

   ```json
   {
     "warnings.required_taps_missing.title": {
       "de": "Erforderliche Homebrew-Taps fehlen",
       "fr": "Des taps Homebrew requis sont manquants"
     }
   }
   ```

   - Keep product names as-is: `PHP Monitor`, `Homebrew`, `Valet`, `PHP Doctor`, `PHP`,
     `macOS`, `Xdebug`. Keep CLI commands literal (e.g. `` `brew tap` ``).
   - Preserve `%@` placeholders exactly.
   - Use `\\n` in a JSON string to emit a literal `\n` line break into the `.strings`
     file.
   - Discover the locales to translate into from the `*.lproj` directories — do not
     hardcode the list.

4. **Sync.** Insert the translations and remove stale keys:

   ```bash
   python3 scripts/sync_translations.py --dry-run   # preview first
   python3 scripts/sync_translations.py             # apply
   ```

   The script places each new key at the position that mirrors `en.lproj`
   automatically (no manual anchor needed), never edits existing keys, never touches
   `en.lproj`, and is safe to re-run.

5. **Validate** every file still parses:

   ```bash
   ./scripts/verify_tl.sh
   ```

6. **Confirm coverage is clean** — re-run the report; it should show `missing: 0`
   and `stale: 0` for every locale:

   ```bash
   ./scripts/find_missing_tl.sh
   ```

7. **Remove the payload.** Once the translations are applied and verified, delete
   the transient payload so it is never committed:

   ```bash
   rm -f scripts/translations.json
   ```

   Only the changes to the `*.lproj/Localizable.strings` files should be committed.

## Notes

- `sync_translations.py` reports any missing key that has no entry in the payload as
  "still untranslated" — add it to `scripts/translations.json` and re-run.
- New `.strings` lines must contain no comments and no blank lines (one `"key" = "value";`
  per line); the script already emits them in that form.
- Other locales fall back to English at runtime for any key they lack (see
  `String.localized`), so a partial sync is never fatal — but aim for full coverage.
