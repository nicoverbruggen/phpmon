//
//  WelcomeTourView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 08/07/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct WelcomeTourTextItem: View {
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
                        .font(.system(size: 12))
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

struct WelcomeTourView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 5) {
            HStack {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 100, height: 100)
                    .padding(.bottom, 5)
                    .padding(.trailing, 25)
                VStack(alignment: .leading, spacing: 0) {
                    Text("welcome_tour.welcome".localized)
                        .font(.title)
                        .bold()
                        .padding(.bottom, 5)
                        .padding(.top, 8)
                        .foregroundColor(Color.appPrimary)
                    Text(
                        Valet.installed
                         ? "welcome_tour.explore".localizedForSwiftUI
                         : "welcome_tour.explore.lite".localizedForSwiftUI
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
                    WelcomeTourTextItem(
                        icon: "bolt.circle.fill",
                        title: "welcome_tour.tour.menu_bar.title",
                        description: "welcome_tour.tour.menu_bar"
                    )
                    WelcomeTourTextItem(
                        icon: "checkmark.circle.fill",
                        title: "welcome_tour.tour.services.title",
                        description: "welcome_tour.tour.services",
                        unavailable: !Valet.installed
                    )
                    WelcomeTourTextItem(
                        icon: "list.bullet.circle.fill",
                        title: "welcome_tour.tour.domains.title",
                        description: "welcome_tour.tour.domains",
                        unavailable: !Valet.installed
                    )
                    WelcomeTourTextItem(
                        icon: "pin.circle.fill",
                        title: "welcome_tour.tour.isolation.title",
                        description: "welcome_tour.tour.isolation",
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
                        Text("welcome_tour.tour.faq_hint".localizedForSwiftUI)
                            .lineLimit(5)
                    }.fixedSize(horizontal: false, vertical: true)
                }
                VStack {
                    Text("welcome_tour.tour.once".localized)
                        .fixedSize(horizontal: false, vertical: true)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.top, 5)
                        .padding(.bottom, 5)
                        .lineLimit(3)
                        .frame(height: 35)
                    Button("welcome_tour.tour.close".localized) {
                        WindowManager.close(WelcomeTourWC.self)
                    }
                    .padding(.bottom, 15)
                    .padding(.top, 10)
                }
            }
            .padding(.leading)
            .padding(.trailing)
            .padding(.bottom, 0)
        }
        .frame(width: 600)
        .fixedSize(horizontal: true, vertical: false)
    }
}

#Preview {
    WelcomeTourView()
}
