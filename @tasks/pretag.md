Before a release is tagged, you want to make sure that the latest known stable release is known.

First, identify what has changed between this tagged version and the current HEAD of the branch you wish to merge into `main` as the stable build.

Tagged releases follow the `vX.Y.Z` naming system, where X is the year, Y is the month version and Z is the patch (usually unspecified unless a patch was released).

Look for the latest tag on the `main` branch first.

Make sure all unit tests and UI tests pass prior to finalizing a build. The developer will need to manually check this and report if the tests pass or fail.

Once this has been confirmed and test pass, a sanity check needs to be done by checking if all of the changes made in the commits since the last release are:

- Bugfixes for a given issue, without any potential side effects
- New features which should have new associated tests
- Quality of life improvements that do not require new tests

If any changes seem incomplete or there's a chance that some functionality may still break despite tests passing (due to some oversight), then no release should be made and those issues should be listed first.

(These sanity checks can be done manually or assisted by an LLM.)

---

- [ ] Do all tests pass? Ask.
- [ ] Determine latest tag
- [ ] Identify diff between latest tag and HEAD
- [ ] Go through commits and sanity check based on instructions
- [ ] Determine if ready for a new release
- [ ] If ready, generate a short changelog (instructions in ./@changelog.md)

