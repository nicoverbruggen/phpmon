# Release Procedure

1. Merge into `main`
2. Create tag
3. Add changes to changelog
4. Archive
5. Notarize and prepare for own distribution
6. After notarization, export .app
7. Create zipped version
8. Calculate SHA256: `openssl dgst -sha256 phpmon-2.x.zip`
9. Upload to GitHub
10. Update Cask
11. Check new version can be installed via Cask
