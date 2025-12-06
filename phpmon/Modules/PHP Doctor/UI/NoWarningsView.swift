//
//  NoWarningsView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 15/08/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct NoWarningsView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 15) {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .renderingMode(.template)
                .foregroundColor(Color.green)
                .frame(width: 24, height: 24)
            VStack(alignment: .center) {
                Text("warnings.none".localizedForSwiftUI)
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .padding(25)
    }
}

#Preview {
    NoWarningsView().padding()
}
