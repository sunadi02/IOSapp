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

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @State private var services = AppServices()

    //firebase must be configured once before any auth or firestore call
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(services)
                .task {
                    services.start()
                    await services.appBecameActive()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        Task { await services.appBecameActive() }
                    }
                }
        }
        .commands {
            AppCommands()
        }
    }
}
