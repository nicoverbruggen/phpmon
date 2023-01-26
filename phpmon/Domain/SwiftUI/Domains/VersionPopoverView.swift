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

    @State var parent: NSPopover!

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
                    HStack {
                        ForEach(validPhpVersions, id: \.self) { version in
                            Button("site_link.switch_to_php".localized(version.short), action: {
                                MainMenu.shared.switchToPhpVersion(version.short)
                                parent?.close()
                            })
                        }
                    }.padding(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
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
                PhpEnv.phpInstall?.version.short ?? "???"
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

struct VersionPopoverView_Previews: PreviewProvider {
    static var previews: some View {
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
            parent: nil
        )
        .previewDisplayName("Unknown Requirement")

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
            parent: nil
        )
        .previewDisplayName("Requirement Matches")
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
            parent: nil
        )
        .previewDisplayName("Isolated")
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
            parent: nil
        )
        .previewDisplayName("Isolated Mismatch")
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
                VersionNumber(major: 8, minor: 1, patch: 0)
            ],
            parent: nil
        )
        .previewDisplayName("Recommend Alternatives")
    }
}
