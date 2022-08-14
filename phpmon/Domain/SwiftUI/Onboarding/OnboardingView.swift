//
//  OnboardingView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 08/07/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct OnboardingTextItem: View {
    @State var icon: String
    @State var title: String
    @State var description: String

    var body: some View {
        HStack(alignment: .top, spacing: 5) {
            Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundColor(Color.appPrimary)
                .padding(.trailing, 10)
            VStack(alignment: .leading, spacing: 4) {
                Text(title.localizedForSwiftUI)
                    .font(.system(size: 14))
                    .lineLimit(3)
                Text(description.localizedForSwiftUI)
                    .foregroundColor(Color.secondary)
                    .font(.system(size: 13))
                    .lineLimit(6)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .overlay(RoundedRectangle(cornerRadius: 5)
        .stroke(Color.gray.opacity(0.3), lineWidth: 1))
    }
}

struct OnboardingView: View {
    var body: some View {
        VStack(spacing: 10) {
            VStack(alignment: .center) {
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
                        Text("onboarding.explore".localized)
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
                            description: "onboarding.tour.services"
                        )
                        OnboardingTextItem(
                            icon: "list.bullet.circle.fill",
                            title: "onboarding.tour.domains.title",
                            description: "onboarding.tour.domains"
                        )
                        OnboardingTextItem(
                            icon: "pin.circle.fill",
                            title: "onboarding.tour.isolation.title",
                            description: "onboarding.tour.isolation"
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
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.top, 5)
                            .padding(.bottom, 5)
                            .lineLimit(5)
                        Button("onboarding.tour.close".localized) {
                            App.shared.onboardingWindowController?.close()
                        }
                    }
                }.padding()
            }
        }
        .padding(.top, 8)
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            OnboardingView()
            OnboardingView().preferredColorScheme(.dark)
        }
    }
}
