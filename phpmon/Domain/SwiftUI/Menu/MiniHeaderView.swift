//
//  MiniHeaderView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 10/06/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct MiniHeaderView: View {
    @State var text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11))
            .fontWeight(.medium)
            .foregroundColor(.secondary)
    }
}
