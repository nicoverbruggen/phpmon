//
//  DomainListPhpControlsTest.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import AppKit
import Testing

struct DomainListPhpControlsTest {
    private func makeSite(isolated: Bool = false) -> ValetSite {
        let container = Container.fake(shell: [
            "/opt/homebrew/opt/php@8.4/bin/php --ini | grep -E -o '(/[^ ]+\\.ini)'": .instant("")
        ])
        container.valet.features = [.isolatedSites]
        container.phpEnvs.availablePhpVersions = ["8.4", "8.3"]
        let site = ValetSite(container, name: "example", tld: "test", absolutePath: "/sites/example",
                             makeDeterminations: false)
        if isolated {
            site.isolatedPhpVersion = PhpInstallation(container, "8.4", probe: .init(container, "8.4"))
        }
        return site
    }

    @Test func isolation_menu_lists_installed_versions_and_marks_the_isolated_version() throws {
        let site = makeSite(isolated: true)
        let controller = DomainListVC()
        let menu = controller.isolationMenu(for: site)
        let versions = menu.items.compactMap { $0 as? PhpMenuItem }

        #expect(versions.map(\.version) == ["8.3", "8.4"])
        #expect(versions[0].isEnabled)
        #expect(versions[0].state == .off)
        #expect(!versions[1].isEnabled)
        #expect(versions[1].state == .on)
        #expect(versions[1].action == nil)

        let remove = try #require(menu.items.last)
        #expect(remove.action == #selector(DomainListVC.removeIsolatedSiteViaMenuItem(sender:)))
        #expect(remove.isEnabled)
    }

    @Test func menu_actions_keep_their_site_when_another_menu_is_built() throws {
        let controller = DomainListVC()
        let first = makeSite(isolated: true)
        let second = makeSite()
        second.name = "another"
        let firstMenu = controller.isolationMenu(for: first)
        let secondMenu = controller.isolationMenu(for: second)

        for menu in [firstMenu, secondMenu] {
            let expectedSite = menu === firstMenu ? first : second
            for item in menu.items where !item.isSeparatorItem {
                #expect(item.target === controller)
                #expect((item.representedObject as? ValetSite) === expectedSite)
            }
        }
        #expect(try #require(secondMenu.items.last).action !=
                #selector(DomainListVC.removeIsolatedSiteViaMenuItem(sender:)))
    }

    @Test func unavailable_isolation_disables_the_pill_but_keeps_requirement_details() {
        let site = makeSite()
        site.container.valet.features = []
        let phpCell = DomainListPhpCell.makeCell(identifier: "php")
        let typeCell = DomainListTypeCell.makeCell(identifier: "type")
        phpCell.populateCell(with: site)
        typeCell.populateCell(with: site)

        #expect(DomainListVC().isolationMenu(for: site).items.isEmpty)
        #expect(!phpCell.buttonPhpVersion.isEnabled)
        #expect(phpCell.buttonPhpVersion.image == nil)
        #expect(!typeCell.buttonPhpInfo.isHidden)
        #expect(typeCell.buttonPhpInfo.action == #selector(DomainListTypeCell.showPhpDetails(_:)))
    }

    @Test func removal_remains_available_when_no_php_versions_are_installed() {
        let site = makeSite(isolated: true)
        site.container.phpEnvs.availablePhpVersions = []
        let cell = DomainListPhpCell.makeCell(identifier: "php")
        cell.populateCell(with: site)
        let menu = DomainListVC().isolationMenu(for: site)

        #expect(cell.buttonPhpVersion.isEnabled)
        #expect(menu.items.count == 1)
        #expect(menu.items.first?.action == #selector(DomainListVC.removeIsolatedSiteViaMenuItem(sender:)))

        site.isolatedPhpVersion = nil
        cell.populateCell(with: site)
        #expect(!cell.buttonPhpVersion.isEnabled)
        #expect(DomainListVC().isolationMenu(for: site).items.isEmpty)
    }

    @Test func reused_proxy_cells_hide_php_actions_and_restore_them_for_sites() {
        let site = makeSite()
        let proxy = ValetProxy(site.container, domain: "proxy", target: "http://localhost:3000",
                               secure: false, tld: "test")
        let phpCell = DomainListPhpCell.makeCell(identifier: "php")
        let typeCell = DomainListTypeCell.makeCell(identifier: "type")
        phpCell.populateCell(with: site)
        typeCell.populateCell(with: site)
        phpCell.populateCell(with: proxy)
        typeCell.populateCell(with: proxy)
        #expect(phpCell.buttonPhpVersion.isHidden)
        #expect(typeCell.buttonPhpInfo.isHidden)

        phpCell.populateCell(with: site)
        typeCell.populateCell(with: site)
        #expect(!phpCell.buttonPhpVersion.isHidden)
        #expect(phpCell.buttonPhpVersion.isEnabled)
        #expect(phpCell.buttonPhpVersion.image != nil)
        #expect(!typeCell.buttonPhpInfo.isHidden)
    }

    @Test(arguments: [true, false])
    func compatibility_moves_to_the_details_button_and_the_pin_stays_neutral(compatible: Bool) {
        let site = makeSite(isolated: true)
        site.preferredPhpVersionSource = .platform
        site.preferredPhpVersion = "8.4"
        site.isCompatibleWithPreferredPhpVersion = compatible
        let phpCell = DomainListPhpCell.makeCell(identifier: "php")
        let typeCell = DomainListTypeCell.makeCell(identifier: "type")
        phpCell.populateCell(with: site)
        typeCell.populateCell(with: site)

        let status = (compatible ? "alert.php_version_ideal" : "alert.php_version_incorrect").localized
        #expect(typeCell.buttonPhpInfo.accessibilityLabel()?.contains(status) == true)
        #expect(typeCell.buttonPhpInfo.isBordered)
        #expect(!phpCell.imageViewIsolation.isHidden)
        #expect(phpCell.imageViewIsolation.contentTintColor == .secondaryLabelColor)

        site.isolatedPhpVersion = nil
        phpCell.populateCell(with: site)
        #expect(!phpCell.imageViewIsolation.isHidden)
        #expect(phpCell.imageViewIsolation.image != nil)
        #expect(phpCell.imageViewIsolation.contentTintColor == .secondaryLabelColor)
        #expect(phpCell.imageViewIsolation.toolTip == "domain_list.sidebar.global".localized)

        site.preferredPhpVersionSource = .unknown
        typeCell.populateCell(with: site)
        #expect(typeCell.buttonPhpInfo.accessibilityLabel()?.contains("alert.unable_to_determine_is_fine".localized) == true)
    }
}
