//
//  VersionPopoverView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 08/06/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct VersionPopoverView: View {

    @State var site: ValetSite

    @State var validPhpVersions: [VersionNumber]

    @State var prefersIsolationSuggestions: Bool

    @State var parent: NSPopover!

    let rows = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(getTitleText())
                .fontWeight(.bold)
                .fixedSize(horizontal: false, vertical: true)
            Text(getSourceText())
                .fixedSize(horizontal: false, vertical: true)
                .font(.subheadline)
            if !validPhpVersions.isEmpty {
                // Suggestions for alternative PHP versions
                VStack(alignment: .leading, spacing: 10) {
                    DisclaimerView(
                        iconName: "info.circle.fill",
                        message: "alert.php_suggestions".localized,
                        color: Color("AppColor")
                    )
                    if prefersIsolationSuggestions {
                        LazyVGrid(columns: self.rows, alignment: .leading, spacing: 5, content: {
                            ForEach(validPhpVersions, id: \.self) { version in
                                Button("site_link.isolate_php".localized(version.short), action: {
                                    Task {
                                        // Applies isolation
                                        App.shared.domainListWindowController?.contentVC.setUIBusy()
                                        try? await site.isolate(version: version.short)
                                        App.shared.domainListWindowController?.pressedReload(nil)
                                        App.shared.domainListWindowController?.contentVC.setUINotBusy()
                                    }
                                    parent?.close()
                                }).padding(EdgeInsets(top: 3, leading: 0, bottom: 3, trailing: 0))
                            }
                        }).padding(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 0))
                    } else {
                        LazyVGrid(columns: self.rows, alignment: .leading, spacing: 5, content: {
                            ForEach(validPhpVersions, id: \.self) { version in
                                Button("site_link.switch_to_php".localized(version.short), action: {
                                    // Uses the global switcher
                                    MainMenu.shared.switchToPhpVersion(version.short)
                                    parent?.close()
                                }).padding(EdgeInsets(top: 3, leading: 0, bottom: 3, trailing: 0))
                            }
                        }).padding(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 0))
                    }

                }
            } else {
                if site.preferredPhpVersionSource == .unknown {
                    // We don't know which PHP version is required
                    DisclaimerView(
                        iconName: "questionmark.circle.fill",
                        message: "alert.unable_to_determine_is_fine".localized
                    )
                } else {
                    if site.isCompatibleWithPreferredPhpVersion {
                        DisclaimerView(
                            iconName: "checkmark.circle.fill",
                            message: "alert.php_version_ideal".localized,
                            color: Color("IconColorGreen")
                        )
                    } else {
                        DisclaimerView(
                            iconName: "exclamationmark.circle.fill",
                            message: "alert.php_version_incorrect".localized,
                            color: Color("IconColorRed")
                        )
                    }
                }
            }
        }.frame(width: 400, height: nil, alignment: .center)
            .padding(20)
            .background(
                Color(NSColor.windowBackgroundColor)
                    .padding(-80)
            )
    }

    func getTitleText() -> String {
        if site.preferredPhpVersionSource == .unknown {
            return "alert.composer_php_requirement.unable_to_determine".localized
        }

        let suffix = {
            if isRunningTests || isRunningSwiftUIPreview {
                return "test"
            }

            return Valet.shared.config.tld
        }()

        return "alert.composer_php_requirement.title".localized(
            "\(site.name).\(suffix)",
            site.preferredPhpVersion
        )
    }

    func getSourceText() -> String {
        var information = ""

        if site.isolatedPhpVersion != nil {
            information += "alert.composer_php_isolated.desc".localized(
                site.isolatedPhpVersion!.versionNumber.short,
                PhpEnvironments.phpInstall?.version.short ?? "???"
            )
            information += "\n\n"
        }

        information += "alert.composer_php_requirement.type.\(site.preferredPhpVersionSource.rawValue)"
            .localized

        return information
    }
}

struct DisclaimerView: View {
    @State var iconName: String
    @State var message: String
    @State var color: Color = Color.secondary

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Image(systemName: iconName)
                .renderingMode(.template)
                .foregroundColor(color)
            Text(message)
                .font(.subheadline)
                .foregroundColor(color)
        }.padding(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 0))
    }
}

#Preview("Unknown Requirement") {
    VersionPopoverView(
        site: FakeValetSite(
            fakeWithName: "amazingwebsite",
            tld: "test",
            secure: true,
            path: "/path/to/site",
            linked: true,
            constraint: ""
        ),
        validPhpVersions: [],
        prefersIsolationSuggestions: false,
        parent: nil
    )
}

#Preview("Requirement Matches") {
    VersionPopoverView(
        site: FakeValetSite(
            fakeWithName: "amazingwebsite",
            tld: "test",
            secure: true,
            path: "/path/to/site",
            linked: true,
            constraint: "^8.1"
        ),
        validPhpVersions: [],
        prefersIsolationSuggestions: false,
        parent: nil
    )
}

#Preview("Isolated") {
    VersionPopoverView(
        site: FakeValetSite(
            fakeWithName: "anothersite",
            tld: "test",
            secure: true,
            path: "/path/to/site",
            linked: true,
            constraint: "^8.0",
            isolated: "8.0"
        ),
        validPhpVersions: [],
        prefersIsolationSuggestions: false,
        parent: nil
    )
}

#Preview("Isolated Mismatch") {
    VersionPopoverView(
        site: FakeValetSite(
            fakeWithName: "anothersite",
            tld: "test",
            secure: true,
            path: "/path/to/site",
            linked: true,
            constraint: "^8.0",
            isolated: "7.4"
        ),
        validPhpVersions: [],
        prefersIsolationSuggestions: false,
        parent: nil
    )
}

#Preview("Recommend Alternatives") {
    VersionPopoverView(
        site: FakeValetSite(
            fakeWithName: "anothersite",
            tld: "test",
            secure: true,
            path: "/path/to/site",
            linked: true,
            constraint: "^8.0"
        ),
        validPhpVersions: [
            VersionNumber(major: 8, minor: 0, patch: 0),
            VersionNumber(major: 8, minor: 1, patch: 0),
            VersionNumber(major: 8, minor: 2, patch: 0),
            VersionNumber(major: 8, minor: 3, patch: 0),
            VersionNumber(major: 8, minor: 4, patch: 0)
        ],
        prefersIsolationSuggestions: true,
        parent: nil
    )
}
