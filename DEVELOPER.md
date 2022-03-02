# DEVELOPER README

## 🔧 Build instructions

<img src="./docs/build.png" width="404px" alt="build button in Xcode"/>

If you'd like to build PHP Monitor yourself, you need:

* Xcode (usually the latest version)
* The contents of this repository

Once you have downloaded this repository, open `PHP Monitor.xcodeproj`, and you should be able to immediately build the app for your system by pressing Cmd-R. This will create a debug build. (If Xcode complains about code signing, you can turn it off.)

If you'd like to create a production build, choose "Any Mac" as the target and select Product > Archive.

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

## 🐛 Symbolication of crashes

If you have an archived build of the app and exported the DSYM, it is possible to symbolicate .ips crash logs.

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
