//
//  StartupAlertHeaderView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct StartupAlertHeaderView: View {
    let titleText: String
    let subtitleText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(titleText)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .textSelection(.enabled)
                .padding(.bottom, 2)

            MarkdownTextView(subtitleText, fontSize: 12)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    StartupAlertHeaderView(
        titleText: "startup.errors.php_binary.title".localized,
        subtitleText: "startup.errors.php_binary.subtitle".localized
    )
    .frame(width: 460)
}
