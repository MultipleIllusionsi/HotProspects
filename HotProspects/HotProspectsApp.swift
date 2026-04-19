//
//  HotProspectsApp.swift
//  HotProspects
//
//  Created by Сергей Захаров on 17.04.2026.
//

import SwiftData
import SwiftUI

@main
struct HotProspectsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Prospect.self)
    }
}
