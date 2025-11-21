//
//  AddSiteVC.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 24/01/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa

class AddProxyVC: NSViewController, NSTextFieldDelegate {

    // MARK: - Outlets

    @IBOutlet weak var textFieldTitle: NSTextField!
    @IBOutlet weak var textFieldProxySubject: NSTextField!
    @IBOutlet weak var textFieldDomainName: NSTextField!

    @IBOutlet weak var inputProxySubject: NSTextField!
    @IBOutlet weak var inputDomainName: NSTextField!

    @IBOutlet weak var previewText: NSTextField!

    @IBOutlet weak var buttonSecure: NSButton!
    @IBOutlet weak var buttonCreateProxy: NSButton!
    @IBOutlet weak var buttonCancel: NSButton!

    @IBOutlet weak var textFieldSecure: NSTextField!
    @IBOutlet weak var textFieldError: NSTextField!

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        loadStaticLocalisedStrings()

        buttonCreateProxy.isEnabled = false
        updatePreview()
        validate()
    }

    private func dismissView(outcome: NSApplication.ModalResponse) {
        guard let window = view.window, let parent = window.sheetParent else { return }
        parent.endSheet(window, returnCode: outcome)
    }

    // MARK: - Localisation

    func loadStaticLocalisedStrings() {
        textFieldTitle.stringValue = "domain_list.add.set_up_proxy".localized
        textFieldProxySubject.stringValue = "domain_list.add.proxy_subject".localized
        textFieldDomainName.stringValue = "domain_list.add.domain_name".localized
        textFieldSecure.stringValue = "domain_list.add.secure_description".localized
        buttonCancel.title = "domain_list.add.cancel".localized
        buttonCreateProxy.title = "domain_list.add.create_proxy".localized
    }

    // MARK: - Outlet Interactions

    @IBAction func pressedSecure(_ sender: Any) {
        updatePreview()
    }

    @IBAction func pressedCreateProxy(_ sender: Any) {
        let domain = self.inputDomainName.stringValue
        let proxyName = self.inputProxySubject.stringValue
        let secure = (self.buttonSecure.state == .on)

        dismissView(outcome: .OK)

        App.shared.domainListWindowController?.contentVC.setUIBusy()

        Task { // Ensure we proxy the site asynchronously and reload UI on main thread again
            try? await ValetInteractor.shared.proxy(
                domain: domain,
                proxy: proxyName,
                secure: secure
            )

            Task { @MainActor in
                App.shared.domainListWindowController?.contentVC.setUINotBusy()
                App.shared.domainListWindowController?.pressedReload(nil)
            }
        }
    }

    @IBAction func pressedCancel(_ sender: Any) {
        dismissView(outcome: .cancel)
    }

    // MARK: - Text Field Delegate

    func controlTextDidChange(_ obj: Notification) {
        updateTextField()
    }

    // MARK: - Helper Methods

    private func validate() {
        _ = validate(
            domain: inputDomainName.stringValue,
            proxy: inputProxySubject.stringValue
        )
    }

    private func validate(domain: String, proxy: String) -> Bool {
        if proxy.isEmpty {
            textFieldError.isHidden = false
            textFieldError.stringValue = "domain_list.add.errors.empty_proxy".localized
            return false
        }

        if proxy.range(of: #"(http:\/\/|https:\/\/)(.+)(:)(\d+)$"#, options: .regularExpression) == nil {
            textFieldError.isHidden = false
            textFieldError.stringValue = "domain_list.add.errors.subject_invalid".localized
            return false
        }

        if domain.isEmpty {
            textFieldError.isHidden = false
            textFieldError.stringValue = "domain_list.add.errors.empty".localized
            return false
        }

        if Valet.shared.sites.contains(where: { $0.name == domain }) {
            textFieldError.isHidden = false
            textFieldError.stringValue = "domain_list.add.errors.already_exists".localized
            return false
        }

        textFieldError.isHidden = true
        return true
    }

    func updateTextField() {
        inputDomainName.stringValue = inputDomainName.stringValue
            .replacing(" ", with: "-")

        inputProxySubject.stringValue = inputProxySubject.stringValue
            .replacing(" ", with: "-")

        buttonCreateProxy.isEnabled = validate(
            domain: inputDomainName.stringValue,
            proxy: inputProxySubject.stringValue
        )

        updatePreview()
    }

    func updatePreview() {
        buttonSecure.title = "domain_list.add.secure_after_creation"
            .localized(
                inputDomainName.stringValue,
                Valet.shared.config.tld
            )

        if inputProxySubject.stringValue.isEmpty || inputDomainName.stringValue.isEmpty {
            previewText.stringValue = "domain_list.add.empty_fields".localized
            return
        }

        var translationKey = "domain_list.add.proxy_available"

        if inputProxySubject.stringValue.starts(with: "https://") {
            translationKey = "domain_list.add.proxy_https_warning"
        }

        previewText.stringValue =
            translationKey.localized(
                inputProxySubject.stringValue,
                buttonSecure.state == .on ? "https" : "http",
                inputDomainName.stringValue,
                Valet.shared.config.tld
            )
    }

}
