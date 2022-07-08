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
        HStack(alignment: .top) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .padding()
                .frame(width: 120, height: 120)
            VStack(alignment: .leading) {
                Text("Welcome to PHP Monitor!")
                    .font(.title)
                    .bold()
                    .padding(.bottom, 5)
                Text("If you're seeing this message, then the app has successfully started without any issues. That's honestly the hardest part — from now on I hope it's smooth sailing for you.")
                    .padding(.bottom)
                VStack(alignment: .leading) {
                    Text("Switch PHP versions").font(.headline)
                    Text("Manage your domains").font(.headline)
                    Text("Domain-specific PHP version isolation").font(.headline)
                    Text("Find your configuration files").font(.headline)
                }
                Text("I hope you find the app as useful as I do. Enjoy, and if you can, please consider supporting the app. Thank you!")
                    .padding(.top)
                    .padding(.bottom)
                VStack(alignment: .leading) {
                    Button("Get Started") {
                        //
                    }
                }
            }.frame(maxWidth: .infinity)
        }.padding(20)
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView().frame(
            width: 600
        )
    }
}
