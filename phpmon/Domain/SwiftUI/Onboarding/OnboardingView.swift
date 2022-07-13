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
        VStack(alignment: .center) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 90, height: 90)
            Text("onboarding.welcome".localized)
                .font(.title)
                .bold()
                .padding(.bottom, 5)
            Text("onboarding.explore".localized)
                .padding(.bottom)
            TabView {
                VStack {
                    Image("Tour.MenuBar")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.top)
                    Text("onboarding.tour.menu_bar".localized)
                        .padding(.init(top: 5, leading: 20, bottom: 20, trailing: 20))
                }.tabItem { Label("onboarding.tour.menu_bar.title".localized, systemImage: "") }
                VStack {
                    Image("Tour.Domains")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.top)
                    Text("onboarding.tour.domains".localized)
                        .padding(.init(top: 5, leading: 20, bottom: 20, trailing: 20))
                }.tabItem { Label("onboarding.tour.domains.title".localized, systemImage: "") }
                VStack {
                    Image("Tour.Isolation")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.top)
                    Text("onboarding.tour.isolation".localized)
                        .padding(.init(top: 5, leading: 20, bottom: 20, trailing: 20))
                }.tabItem { Label("onboarding.tour.isolation.title".localized, systemImage: "") }
            }
            Text("onboarding.tour.once".localized)
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.top, 5)
            Button("Close Tour") {

            }
        }
        .frame(maxWidth: .infinity)
        .padding()
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
