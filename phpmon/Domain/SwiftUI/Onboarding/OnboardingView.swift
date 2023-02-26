//
//  OnboardingView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 08/07/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct OnboardingTextItem: View {
    @State var icon: String
    @State var title: String
    @State var description: String
    @State var unavailable: Bool = false

    var body: some View {
        ZStack {
            HStack(alignment: .top, spacing: 5) {
                Image(systemName: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundColor(unavailable ? .gray : Color.appPrimary)
                    .padding(.trailing, 10)
                    .opacity(self.unavailable ? 0.2 : 1)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title.localizedForSwiftUI)
                        .font(.system(size: 14))
                        .lineLimit(3)
                        .opacity(self.unavailable ? 0.5 : 1)
                    Text(description.localizedForSwiftUI)
                        .foregroundColor(Color.secondary)
                        .font(.system(size: 13))
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(minWidth: 0, maxWidth: 800, alignment: .leading)
                        .opacity(self.unavailable ? 0.5 : 1)
                }
            }
            .padding()
            .overlay(RoundedRectangle(cornerRadius: 5)
            .stroke(Color.gray.opacity(self.unavailable ? 0.1 : 0.3), lineWidth: 1))
        }
    }
}

struct OnboardingView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 5) {
            HStack {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 80, height: 80)
                    .padding(.bottom, 5)
                    .padding(.trailing, 25)
                VStack(alignment: .leading, spacing: 0) {
                    Text("onboarding.welcome".localized)
                        .font(.title)
                        .bold()
                        .padding(.bottom, 5)
                        .padding(.top, 8)
                        .foregroundColor(Color.appPrimary)
                    Text(
                        Valet.installed
                         ? "onboarding.explore".localizedForSwiftUI
                         : "onboarding.explore.lite".localizedForSwiftUI
                    )
                    .padding(.bottom)
                    .padding(.trailing)
                }
                .padding(.top, 10)
            }
            .padding(.leading)
            .padding(.trailing)

            VStack {
                VStack(alignment: .leading, spacing: 10) {
                    OnboardingTextItem(
                        icon: "bolt.circle.fill",
                        title: "onboarding.tour.menu_bar.title",
                        description: "onboarding.tour.menu_bar"
                    )
                    OnboardingTextItem(
                        icon: "checkmark.circle.fill",
                        title: "onboarding.tour.services.title",
                        description: "onboarding.tour.services",
                        unavailable: !Valet.installed
                    )
                    OnboardingTextItem(
                        icon: "list.bullet.circle.fill",
                        title: "onboarding.tour.domains.title",
                        description: "onboarding.tour.domains",
                        unavailable: !Valet.installed
                    )
                    OnboardingTextItem(
                        icon: "pin.circle.fill",
                        title: "onboarding.tour.isolation.title",
                        description: "onboarding.tour.isolation",
                        unavailable: !Valet.installed
                    )
                }
            }.padding()

            VStack(spacing: 20) {
                HStack {
                    Image(systemName: "questionmark.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(Color.appSecondary)
                        .padding(.trailing, 10)
                    HStack {
                        Text("onboarding.tour.faq_hint".localizedForSwiftUI)
                            .lineLimit(5)
                    }.fixedSize(horizontal: false, vertical: true)
                }
                VStack {
                    Text("onboarding.tour.once".localized)
                        .fixedSize(horizontal: false, vertical: true)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.top, 5)
                        .padding(.bottom, 5)
                        .lineLimit(3)
                        .frame(height: 35)
                    Button("onboarding.tour.close".localized) {
                        App.shared.onboardingWindowController?.close()
                    }
                    .padding(.bottom, 5)
                    .padding(.top, 10)
                }
            }
            .padding(.leading)
            .padding(.trailing)
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            OnboardingView()
        }
    }
}
