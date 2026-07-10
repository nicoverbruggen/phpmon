//
//  AppMenu.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 27/06/2024.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa

class AppMenu {

    // MARK: - Main Menu

    static var appMenu: NSMenu? {
        return NSApplication.shared.mainMenu?.items[0].submenu
    }

    static var sitesMenuItem: NSMenuItem? {
        return NSApplication.shared.mainMenu?.items[1]
    }

    static var sitesMenu: NSMenu? {
        return NSApplication.shared.mainMenu?.items[1].submenu
    }

    static var editMenu: NSMenu? {
        return NSApplication.shared.mainMenu?.items[2].submenu
    }

    static var windowMenu: NSMenu? {
        return NSApplication.shared.mainMenu?.items[3].submenu
    }

    static var helpMenu: NSMenu? {
        return NSApplication.shared.mainMenu?.items[4].submenu
    }

    // MARK: - Submenu

    static var actionsMenu: NSMenuItem? {
        return sitesMenu?.items.last
    }

    // MARK: - Menu Construction

    /**
     Builds the app's main menu bar, transcribed from the old `Main.storyboard`
     Application scene. AppKit augments the result at runtime exactly like it
     did the storyboard's menu (Writing Tools, AutoFill, dictation and emoji
     entries in Edit; "Close All" in Window).

     - Note: This menu is only displayed when the app is NOT running in
     accessory mode. See the ActivationPolicy-related extension.
     */
    static func build(actionsTarget delegate: AppDelegate) -> NSMenu {
        let mainMenu = NSMenu(title: "Main Menu")

        mainMenu.addItem(submenu: buildAppMenu(), title: "PHP Monitor")
        mainMenu.addItem(submenu: buildSitesMenu(delegate), title: "Sites")
        mainMenu.addItem(submenu: buildEditMenu(), title: "Edit")
        mainMenu.addItem(submenu: buildWindowMenu(), title: "Window")

        // The Help item has no submenu (matching the storyboard).
        let help = NSMenuItem(title: "Help", action: nil, keyEquivalent: "")
        help.keyEquivalentModifierMask = []
        mainMenu.addItem(help)

        return mainMenu
    }

    private static func buildAppMenu() -> NSMenu {
        let menu = NSMenu(title: "PHP Monitor")

        menu.addItem(
            title: "About PHP Monitor",
            action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
            keyEquivalent: "", modifiers: []
        )
        menu.addItem(.separator())
        menu.addItem(
            title: "Quit PHP Monitor",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )

        return menu
    }

    private static func buildSitesMenu(_ delegate: AppDelegate) -> NSMenu {
        let menu = NSMenu(title: "Sites")

        menu.addItem(
            title: "mm_add_folder_as_link".localized,
            action: #selector(AppDelegate.addSiteLinkPressed(_:)),
            keyEquivalent: "n", target: delegate
        )
        menu.addItem(
            title: "mm_reload_domain_list".localized,
            action: #selector(AppDelegate.reloadDomainListPressed(_:)),
            keyEquivalent: "r", target: delegate
        )
        menu.addItem(.separator())
        menu.addItem(
            title: "mm_find_in_domain_list".localized,
            action: #selector(AppDelegate.focusSearchField(_:)),
            keyEquivalent: "f", target: delegate
        )
        menu.addItem(.separator())

        // The "Actions" item starts out disabled and without a submenu; the
        // domain list fills it in based on the current selection.
        let actions = NSMenuItem(title: "mm_actions".localized, action: nil, keyEquivalent: "")
        actions.keyEquivalentModifierMask = []
        actions.isEnabled = false
        menu.addItem(actions)

        return menu
    }

    // A declarative transcription of the storyboard's (large) Edit menu.
    // swiftlint:disable:next function_body_length
    private static func buildEditMenu() -> NSMenu {
        let menu = NSMenu(title: "Edit")

        // Initially disabled, like in the old storyboard; the menu's
        // auto-enabling re-evaluates them against the responder chain.
        menu.addItem(title: "Undo", action: Selector(("undo:")), keyEquivalent: "z").isEnabled = false
        menu.addItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "Z").isEnabled = false
        menu.addItem(.separator())
        menu.addItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        menu.addItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        menu.addItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        menu.addItem(
            title: "Paste and Match Style",
            action: #selector(NSTextView.pasteAsPlainText(_:)),
            keyEquivalent: "V", modifiers: [.option, .command]
        )
        menu.addItem(
            title: "Delete",
            action: #selector(NSText.delete(_:)),
            keyEquivalent: "", modifiers: []
        )
        menu.addItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        menu.addItem(.separator())

        let find = NSMenu(title: "Find")
        let findAction = #selector(NSTextView.performFindPanelAction(_:))
        find.addItem(title: "Find…", action: findAction, keyEquivalent: "f", tag: 1)
        find.addItem(
            title: "Find and Replace…", action: findAction,
            keyEquivalent: "f", modifiers: [.option, .command], tag: 12
        )
        find.addItem(title: "Find Next", action: findAction, keyEquivalent: "g", tag: 2)
        find.addItem(title: "Find Previous", action: findAction, keyEquivalent: "G", tag: 3)
        find.addItem(title: "Use Selection for Find", action: findAction, keyEquivalent: "e", tag: 7)
        find.addItem(
            title: "Jump to Selection",
            action: #selector(NSResponder.centerSelectionInVisibleArea(_:)),
            keyEquivalent: "j"
        )
        menu.addItem(submenu: find, title: "Find")

        let spelling = NSMenu(title: "Spelling")
        spelling.addItem(
            title: "Show Spelling and Grammar",
            action: #selector(NSText.showGuessPanel(_:)), keyEquivalent: ":"
        )
        spelling.addItem(
            title: "Check Document Now",
            action: #selector(NSText.checkSpelling(_:)), keyEquivalent: ";"
        )
        spelling.addItem(.separator())
        spelling.addItem(
            title: "Check Spelling While Typing",
            action: #selector(NSTextView.toggleContinuousSpellChecking(_:)),
            keyEquivalent: "", modifiers: []
        )
        spelling.addItem(
            title: "Check Grammar With Spelling",
            action: #selector(NSTextView.toggleGrammarChecking(_:)),
            keyEquivalent: "", modifiers: []
        )
        spelling.addItem(
            title: "Correct Spelling Automatically",
            action: #selector(NSTextView.toggleAutomaticSpellingCorrection(_:)),
            keyEquivalent: "", modifiers: []
        )
        menu.addItem(submenu: spelling, title: "Spelling and Grammar")

        let substitutions = NSMenu(title: "Substitutions")
        substitutions.addItem(
            title: "Show Substitutions",
            action: #selector(NSTextView.orderFrontSubstitutionsPanel(_:)),
            keyEquivalent: "", modifiers: []
        )
        substitutions.addItem(.separator())
        let substitutionItems: [(String, Selector)] = [
            ("Smart Copy/Paste", #selector(NSTextView.toggleSmartInsertDelete(_:))),
            ("Smart Quotes", #selector(NSTextView.toggleAutomaticQuoteSubstitution(_:))),
            ("Smart Dashes", #selector(NSTextView.toggleAutomaticDashSubstitution(_:))),
            ("Smart Links", #selector(NSTextView.toggleAutomaticLinkDetection(_:))),
            ("Data Detectors", #selector(NSTextView.toggleAutomaticDataDetection(_:))),
            ("Text Replacement", #selector(NSTextView.toggleAutomaticTextReplacement(_:)))
        ]
        for (title, action) in substitutionItems {
            substitutions.addItem(title: title, action: action, keyEquivalent: "", modifiers: [])
        }
        menu.addItem(submenu: substitutions, title: "Substitutions")

        let transformations = NSMenu(title: "Transformations")
        let transformationItems: [(String, Selector)] = [
            ("Make Upper Case", #selector(NSResponder.uppercaseWord(_:))),
            ("Make Lower Case", #selector(NSResponder.lowercaseWord(_:))),
            ("Capitalize", #selector(NSResponder.capitalizeWord(_:)))
        ]
        for (title, action) in transformationItems {
            transformations.addItem(title: title, action: action, keyEquivalent: "", modifiers: [])
        }
        menu.addItem(submenu: transformations, title: "Transformations")

        let speech = NSMenu(title: "Speech")
        speech.addItem(
            title: "Start Speaking",
            action: #selector(NSTextView.startSpeaking(_:)), keyEquivalent: "", modifiers: []
        )
        speech.addItem(
            title: "Stop Speaking",
            action: #selector(NSTextView.stopSpeaking(_:)), keyEquivalent: "", modifiers: []
        )
        menu.addItem(submenu: speech, title: "Speech")

        return menu
    }

    private static func buildWindowMenu() -> NSMenu {
        let menu = NSMenu(title: "Window")

        menu.addItem(title: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")

        return menu
    }
}

// MARK: - Construction Helpers

private extension NSMenu {
    /**
     Adds an item with the given attributes. Modifiers default to `.command`
     (the same default the storyboard used when no explicit mask was set);
     targets default to nil (the responder chain).
     */
    @discardableResult
    func addItem(
        title: String,
        action: Selector?,
        keyEquivalent: String,
        modifiers: NSEvent.ModifierFlags = .command,
        target: AnyObject? = nil,
        tag: Int = 0
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.keyEquivalentModifierMask = modifiers
        item.target = target
        item.tag = tag
        addItem(item)
        return item
    }

    /** Adds an item that holds the given submenu. */
    @discardableResult
    func addItem(submenu: NSMenu, title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.keyEquivalentModifierMask = []
        item.submenu = submenu
        addItem(item)
        return item
    }
}
