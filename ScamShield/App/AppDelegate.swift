//
//  AppDelegate.swift
//  ScamShield
//
//  Created by student2 on 2026-10-25.
//

import UIKit

//only here for the home screen quick actions, SwiftUI has no direct way to receive them
final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        application.shortcutItems = QuickAction.allCases.map(\.shortcutItem)
        return true
    }

    //a quick action that launches the app arrives here, one that wakes a running app goes to the scene delegate
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        if let shortcutItem = options.shortcutItem {
            QuickActionRouter.shared.handle(type: shortcutItem.type)
        }

        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = QuickActionSceneDelegate.self
        return configuration
    }
}

final class QuickActionSceneDelegate: NSObject, UIWindowSceneDelegate {

    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(QuickActionRouter.shared.handle(type: shortcutItem.type))
    }
}
