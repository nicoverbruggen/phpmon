//
//  Favorites.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/08/2024.
//  Copyright © 2024 Nico Verbruggen. All rights reserved.
//

import Foundation

class Favorites {
    static var shared: Favorites = Favorites()

    var items: [String]

    init() {
        if let items = UserDefaults.standard.array(forKey: PersistentAppState.userFavorites.rawValue) as? [String] {
            self.items = items
        } else {
            self.items = []
        }
    }

    public func contains(domain: String) -> Bool {
        return self.items.contains(domain)
    }

    public func toggle(domain: String) {
        if let index = items.firstIndex(of: domain) {
            items.remove(at: index)
        } else {
            items.append(domain)
        }

        UserDefaults.standard.setValue(items, forKey: PersistentAppState.userFavorites.rawValue)
        UserDefaults.standard.synchronize()
    }
}
