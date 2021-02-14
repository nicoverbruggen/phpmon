# Release Procedure

1. Merge into `main`
2. Create tag
3. Add changes to changelog + update security document
4. Archive
5. Notarize and prepare for own distribution
6. After notarization, export .app
7. Create zipped version
8. Calculate SHA256: `openssl dgst -sha256 phpmon.zip`
9. Upload to GitHub and add to tagged release
10. Update Cask with new version + hash
11. Check new version can be installed via Cask
