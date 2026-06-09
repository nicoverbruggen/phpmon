# Scripts

Helper scripts for PHP Monitor development. Run them from the repository root
(e.g. `./scripts/translations/verify.sh`).

## Localization

The localization scripts live in `scripts/translations/`.

PHP Monitor ships a `Localizable.strings` file per locale under `phpmon/*.lproj/`.
**`en.lproj` is the source of truth** — it defines which keys exist and in what
order. At runtime, any key missing from a locale falls back to English (see
`String.localized` in `StringExtension.swift`), but we still want every locale
filled in.

Three scripts manage these files. A typical workflow when you add new UI strings:

1. Add the new keys (with English values) to `phpmon/en.lproj/Localizable.strings`.
2. Run `translations/find-missing.sh` to see what each locale is now missing.
3. Add the translations to `scripts/translations/payload.json` (a transient,
   gitignored working file — see below).
4. Run `translations/sync.py` to insert them and drop any stale keys.
5. Run `translations/verify.sh` to confirm every file still parses.
6. Delete `scripts/translations/payload.json` — it must not be committed. Only the
   `*.lproj/Localizable.strings` changes are committed.

### `translations/find-missing.sh` — coverage report

Reports, per locale, how many keys are **missing** (in `en` but not the locale)
and **stale** (in the locale but no longer in `en`).

```bash
./scripts/translations/find-missing.sh          # summary counts
./scripts/translations/find-missing.sh --keys   # also list every missing/stale key
```

Requires `jq` (uses `plutil -convert json` for robust key extraction).

### `translations/sync.py` — backfill + cleanup

Brings every non-English locale in line with `en.lproj`:

- **inserts** missing keys, taking the text from a JSON payload, placing each one
  at the position that mirrors `en.lproj` (right after the nearest preceding key
  the locale already has — no hand-maintained anchors)
- **removes** stale keys (unless `--keep-stale` is passed)

It never touches `en.lproj` and never edits existing keys, so it is safe to re-run.

```bash
python3 scripts/translations/sync.py                 # uses scripts/translations/payload.json
python3 scripts/translations/sync.py path/to.json    # custom payload
python3 scripts/translations/sync.py --dry-run       # preview, write nothing
python3 scripts/translations/sync.py --keep-stale    # don't remove stale keys
```

If a key is missing from a locale but absent from the payload, it is reported as
"still untranslated" and left alone.

#### Payload format (`payload.json`)

A flat map of key → { locale → translation }:

```json
{
  "warnings.required_taps_missing.title": {
    "de": "Erforderliche Homebrew-Taps fehlen",
    "fr": "Des taps Homebrew requis sont manquants"
  }
}
```

Notes:
- `payload.json` is a **transient working file**: create it for a batch, run the
  sync, then delete it. It is gitignored and must never be committed — only the
  resulting `*.lproj/Localizable.strings` changes are.
- Use `\\n` in a JSON string to emit a literal `\n` escape into the `.strings`
  file (which the app renders as a line break). Keep `%@` placeholders intact.
- You only need to include keys you're adding; existing keys are ignored.
- Locales are discovered automatically from the `*.lproj` directories.

### `translations/verify.sh` — syntax validation

Lints every `Localizable.strings` file with `plutil -lint`. Returns a non-zero
exit code if any file fails to parse. Run this after any manual or scripted edit.

```bash
./scripts/translations/verify.sh
```

## Valet certificates

### `generate-expired-valet-cert.sh`

Generates an expired Valet certificate for a domain, useful for testing the
certificate-expiry warning flow.

Prerequisite:

```bash
brew install libfaketime
```

Usage (e.g. `myapp.test`):

```bash
./scripts/generate-expired-valet-cert.sh domain.test
```
