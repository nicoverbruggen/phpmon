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
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                Text(description.localizedForSwiftUI)
                    .foregroundColor(Color.secondary)
                    .font(.system(size: 13))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
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
                    }
                    .padding(.top, 10)
                }
                VStack {
                    VStack(alignment: .leading, spacing: 10) {
                        OnboardingTextItem(
                            icon: "bolt.circle.fill",
                            title: "onboarding.tour.menu_bar.title",
                            description: "onboarding.tour.menu_bar"
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
                        Text("onboarding.tour.faq_hint".localizedForSwiftUI)
                    }
                    VStack {
                        Text("onboarding.tour.once".localized)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.top, 5)
                            .padding(.bottom, 5)
                        Button("onboarding.tour.close".localized) {
                            App.shared.onboardingWindowController?.close()
                        }
                    }
                }.padding()
            }
            .frame(maxWidth: .infinity)
            .frame(maxHeight: 580)
        }
        .padding(.top, 8)
        .padding(.leading)
        .padding(.trailing)
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
