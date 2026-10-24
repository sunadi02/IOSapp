//
//  AppSettings.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import Foundation

//every user defaults key in one place so a typo cannot split a setting in two
enum AppSettings {
    static let hasSeenOnboarding = "hasSeenOnboarding"
    static let appLockEnabled = "appLockEnabled"
    static let alertsEnabled = "alertsEnabled"
}
