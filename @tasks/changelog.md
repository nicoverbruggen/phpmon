Instructions for the changelog:

Generate two lists; one containing "What's New" (additions) and one "What's Changed" (bug fixes, modifications). 

Also briefly describe the release in general, e.g. "PHP Monitor X.X is a minor update containing mostly bugfixes." or "PHP Monitor X.X contains a bunch of new features, including X, Y and Z."

Make sure the changelog does not contain too many references to internal code structure unless necessary, make it understandable to the end user of the application.

The changelog should be formatted using Markdown like the example, and should be copied to the clipboard.

---

Structure:

```
**PHP Monitor X.X** comes with features X, Y, X (brief blurb).

## What's New in vX.X

- List item, descriptive.
- List item, descriptive.

## What's Changed

- List item, descriptive.
- List item, descriptive.

```

---

- [ ] Determine latest tag
- [ ] Identify diff between latest tag and HEAD
- [ ] Go through commits to generate changelog