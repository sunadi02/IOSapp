//
//  ScamShieldApp.swift
//  ScamShield
//
//  Created by student2 on 2026-10-21.
//

import SwiftUI
import FirebaseCore

@main
struct ScamShieldApp: App {

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
