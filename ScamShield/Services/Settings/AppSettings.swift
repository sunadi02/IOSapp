//
//  AppSettings.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import SwiftUI

//every user defaults key in one place so a typo cannot split a setting in two
enum AppSettings {
    static let hasSeenOnboarding = "hasSeenOnboarding"
    static let appLockEnabled = "appLockEnabled"
    static let alertsEnabled = "alertsEnabled"
    static let hapticsEnabled = "hapticsEnabled"
    static let handledClipboardChange = "handledClipboardChange"
    static let appearance = "appearance"
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
