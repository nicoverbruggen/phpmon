# DEVELOPER README

## ✅ Linting

This project uses the [SwiftLint](https://github.com/realm/SwiftLint) linter. You must install it and can run it like so:

```
swiftlint
```

It also automatically runs when you try to build the project. You'll get a warning if `swiftlint` is not installed, though. You can attempt to automatically fix issues:

```
swiftlint --fix
```

## 📦 Swift Packages

Starting from PHP Monitor 7.1, the app now uses various first-party package dependencies.

The following package dependencies are in use:

* [`NVAppUpdater`](https://github.com/nicoverbruggen/NVAppUpdater)
* [`NVAlert`](https://github.com/nicoverbruggen/NVAlert)

You may need an internet connection to download these dependencies, or you can also clone the dependencies and include them manually.

## ⚙️ Preferences

You can find the persisted configuration file in `~/Library/Preferences/com.nicoverbruggen.phpmon.plist`

These values are cached by the OS. You can clear this cache by running:

```
defaults delete com.nicoverbruggen.phpmon && killall cfprefsd
```

## 🔧 Build instructions

<img src="./docs/build.png" width="404px" alt="build button in Xcode"/>

### PHP Monitor

If you'd like to build PHP Monitor yourself, you need:

* Xcode (usually the latest version)

Once you have downloaded this repository, open `PHP Monitor.xcodeproj`, and you should be able to build the app for your system by pressing Cmd-R. This will create a debug build. (If Xcode complains about code signing, you can turn it off.)

**Important**: The updater now gets automatically built and included as part of the main target.

If you'd like to create a production build, choose "Any Mac" as the target and select Product > Archive.

## ✅ Testing

In order to properly test everything, you will want to use the _PHP Monitor DEV_ target. There are unit and UI tests both.

You may sporadically see failures in UI tests due to the following error: `Invalid parameter not satisfying: point.x != INFINITY && point.y != INFINITY`. This seems to be an issue with Xcode that Apple may need to resolve? You can retry the tests in question and they should eventually pass.

## 🚀 Release procedure

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

## 🍱 Marketing Mode

You can enable marketing mode by setting the `PHPMON_MARKETING_MODE` environment variable. It preloads a list of (fake) domains in the domain window list for screenshot & marketing purposes.

    launchctl setenv PHPMON_MARKETING_MODE true

## 🐛 Symbolication of crashes

The easiest way to symbolicate crashes is to simply rename the file to `.crash`, and drag it into Xcode. 

Starting with PHP Monitor 25.10, opt-in automatic crash reporting is now included with `PLCrashReporter` and a custom API endpoint. These crash logs can also be symbolicated in exactly the same way.

If you have an archived build of the app and exported the DSYM, it is possible to manually symbolicate `.ips` crash logs.

For example, given the following crash (from an .ips file):

```
Thread 2 Crashed::  Dispatch queue: com.apple.root.user-initiated-qos
0   libswiftDispatch.dylib        	    0x7ff82aa3ab8c static OS_dispatch_source.makeProcessSource(identifier:eventMask:queue:) + 28
1   PHP Monitor                   	       0x1096907d8 0x10965e000 + 206808
                                                |            |
                                             address      load address
2   PHP Monitor                   	       0x1096903ac 0x10965e000 + 205740
3   PHP Monitor                   	       0x10968f88b 0x10965e000 + 202891
```

You must use the correct order for the the address and load address in the command below:

```
$ atos -arch x86_64 -o '/path/to/PHP Monitor.app.dSYM/Contents/Resources/DWARF/PHP Monitor' -l 0x10965e000 0x1096907d8
             |                                           |                                       |              |
             architecture                                path to DSYM                         load address    address
```

This will return the relevant information, for example:

```
FSWatcher.startMonitoring(_:behaviour:) (in PHP Monitor) (PhpConfigWatcher.swift:95)
```

For more information, see [Apple's documentation](https://developer.apple.com/documentation/xcode/adding-identifiable-symbol-names-to-a-crash-report).
