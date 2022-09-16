//
//  NoDomainResults.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 15/08/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct NoDomainResults: View {
    @State var searching: Bool = false

    var body: some View {
        VStack(alignment: .center, spacing: 15) {
            Image(systemName: searching ? "magnifyingglass.circle.fill" : "questionmark.circle.fill")
                .resizable()
                .renderingMode(.template)
                .frame(width: 24, height: 24)
            VStack(alignment: .center) {
                Text(
                    searching
                    ? "domain_list.no_domains_for_search_query".localizedForSwiftUI
                    : "domain_list.no_domains".localizedForSwiftUI
                )
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .padding(25)
    }
}

struct NoDomainResults_Previews: PreviewProvider {
    static var previews: some View {
        NoDomainResults()
    }
}
