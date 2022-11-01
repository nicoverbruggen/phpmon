//
//  AddSiteVC.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 24/01/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa

class AddSiteVC: NSViewController, NSTextFieldDelegate {

    // MARK: - Outlets

    @IBOutlet weak var textFieldTitle: NSTextField!

    @IBOutlet weak var pathControl: NSPathControl!
    @IBOutlet weak var inputDomainName: NSTextField!

    @IBOutlet weak var previewText: NSTextField!

    @IBOutlet weak var buttonSecure: NSButton!
    @IBOutlet weak var buttonCreateLink: NSButton!
    @IBOutlet weak var buttonCancel: NSButton!

    @IBOutlet weak var textFieldSecure: NSTextField!
    @IBOutlet weak var textFieldError: NSTextField!

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        loadStaticLocalisedStrings()
    }

    private func dismissView(outcome: NSApplication.ModalResponse) {
        guard let window = self.view.window, let parent = window.sheetParent else { return }
        parent.endSheet(window, returnCode: outcome)
    }

    // MARK: - Localisation

    func loadStaticLocalisedStrings() {
        textFieldTitle.stringValue = "domain_list.add.link_folder".localized
        inputDomainName.placeholderString = "domain_list.add.domain_name_placeholder".localized
        textFieldSecure.stringValue = "domain_list.add.secure_description".localized
        buttonCancel.title = "domain_list.add.cancel".localized
        buttonCreateLink.title = "domain_list.add.create_link".localized
    }

    // MARK: - Outlet Interactions

    func createLink() async {
        let path = pathControl.url!.path
        let name = inputDomainName.stringValue

        if !FileSystem.anyExists(path) {
            Alert.confirm(
                onWindow: view.window!,
                messageText: "domain_list.alert.folder_missing.title".localized,
                informativeText: "domain_list.alert.folder_missing.desc".localized,
                buttonTitle: "domain_list.alert.folder_missing.cancel".localized,
                secondButtonTitle: "domain_list.alert.folder_missing.return".localized,
                onFirstButtonPressed: { [self] in
                    dismissView(outcome: .cancel)
                }
            )
            return
        }

        // Adding `valet links` is a workaround for Valet malforming the config.json file
        // TODO: I will have to investigate and report this behaviour if possible
        Task { await Shell.quiet("cd '\(path)' && \(Paths.valet) link '\(name)' && valet links") }

        dismissView(outcome: .OK)

        // Reset search
        App.shared.domainListWindowController?
            .searchToolbarItem
            .searchField.stringValue = ""

        // Add the new item and scrolls to it
        await App.shared.domainListWindowController?
            .contentVC
            .addedNewSite(
                name: name,
                secure: buttonSecure.state == .on
            )
    }

    @IBAction func pressedCreateLink(_ sender: Any) {
        Task { await createLink() }
    }

    @IBAction func pressedCancel(_ sender: Any) {
        dismissView(outcome: .cancel)
    }

    @IBAction func pressedSecure(_ sender: Any) {
        updatePreview()
    }

    // MARK: - Text Field Delegate

    func controlTextDidChange(_ obj: Notification) {
        updateTextField()
    }

    // MARK: - Helper Methods

    private func isValidLinkName(_ name: String) -> Bool {
        if name.isEmpty {
            textFieldError.isHidden = false
            textFieldError.stringValue = "domain_list.add.errors.empty".localized
            return false
        }

        if Valet.shared.sites.contains(where: { $0.name == name }) {
            textFieldError.isHidden = false
            textFieldError.stringValue = "domain_list.add.errors.already_exists".localized
            return false
        }

        textFieldError.isHidden = true
        return true
    }

    func updateTextField() {
        inputDomainName.stringValue = inputDomainName.stringValue
            .replacingOccurrences(of: " ", with: "-")

        buttonCreateLink.isEnabled = isValidLinkName(inputDomainName.stringValue)
        updatePreview()
    }

    func updatePreview() {
        buttonSecure.title = "domain_list.add.secure_after_creation"
            .localized(
                inputDomainName.stringValue,
                Valet.shared.config.tld
            )

        if inputDomainName.stringValue.isEmpty {
            previewText.stringValue = "domain_list.add.empty_fields".localized
            return
        }

        previewText.stringValue = "domain_list.add.folder_available"
            .localized(
                buttonSecure.state == .on ? "https" : "http",
                inputDomainName.stringValue,
                Valet.shared.config.tld
            )
    }
}
