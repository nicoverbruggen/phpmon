I have added the following translations:

```
PASTE
```

These were added to @phpmon/en.lproj/Localizable.strings. I want the other files to be updated with localized versions of this.

You do not need to read out the entire other localizable files, you merely need to identify where to inject the new translations, which is below the following key: `PASTE`.

To accomplish your task, you must:

- Identify all of the Localizable languages via the Xcode project file
- Translate the strings for each language identified
- Insert the translation below the appropriate key using `sed` (You should be able to do this by matching the key. Unlike the source English file, localization files do not have newlines or comments, so avoid adding those!)
- Validate all translations are OK via @scripts/verify_tl.sh
- Never read out the full translation file, it will be too long! Ask me if you somehow would need to read out the file