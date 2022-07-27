//
//  OnboardingView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 08/07/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct OnboardingView: View {
    var body: some View {
        VStack {
        VStack(alignment: .leading) {
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
                }.padding(.top, 10)
            }

            TabView {
                VStack {
                    Image("Tour.MenuBar")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.top)
                    Text("onboarding.tour.menu_bar".localizedForSwiftUI)
                        .padding(.init(top: 5, leading: 20, bottom: 20, trailing: 20))
                }.tabItem { Label("onboarding.tour.menu_bar.title".localized,
                                  systemImage: "info.circle.fill") }
                VStack {
                    Image("Tour.Domains")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.top)
                    Text("onboarding.tour.domains".localized)
                        .padding(.init(top: 5, leading: 20, bottom: 20, trailing: 20))
                }.tabItem { Label("onboarding.tour.domains.title".localized,
                                  systemImage: "info.circle.fill") }
                VStack {
                    Image("Tour.Isolation")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.top)
                    Text("onboarding.tour.isolation".localized)
                        .padding(.init(top: 5, leading: 20, bottom: 20, trailing: 20))
                }.tabItem { Label("onboarding.tour.isolation.title".localized,
                                  systemImage: "info.circle.fill") }
            }
        }
        .frame(maxWidth: .infinity)

        VStack(alignment: .center) {
            HStack {
                Image(systemName: "person.fill.questionmark")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.accentColor)
                    .padding(.trailing, 10)
                Text("onboarding.tour.faq_hint".localizedForSwiftUI)
            }.padding()
            Text("onboarding.tour.once".localized)
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.top, 5)
                .padding(.bottom, 5)
            Button("Close Tour") {
                App.shared.onboardingWindowController?.close()
            }
        }
        .frame(maxWidth: .infinity)
        }
        .padding(.top, 8)
        .padding(.leading)
        .padding(.trailing)
        .padding(.bottom)
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            OnboardingView().frame(
                width: 600,
                height: 600
            )
            OnboardingView().preferredColorScheme(.dark).frame(
                width: 600,
                height: 600
            )
        }
    }
}
