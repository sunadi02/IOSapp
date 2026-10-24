//
//  SettingsViewModel.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import Foundation
import Observation

@Observable
final class SettingsViewModel {

    private(set) var statusMessage: String?
    private(set) var errorMessage: String?
    private(set) var alertsMessage: String?

    private let history: HistoryStoring
    private let notifications: NotificationScheduling
    private let appInfo: [String: Any]

    init(
        history: HistoryStoring = AppHistory.store,
        notifications: NotificationScheduling = NotificationService(),
        appInfo: [String: Any]? = Bundle.main.infoDictionary
    ) {
        self.history = history
        self.notifications = notifications
        self.appInfo = appInfo ?? [:]
    }

    var versionText: String {
        let version = appInfo["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = appInfo["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    func clearHistory() {
        do {
            try history.deleteAll()
            statusMessage = "Scan history cleared."
            errorMessage = nil
        } catch {
            statusMessage = nil
            errorMessage = "Could not clear your scan history."
        }
    }

    //returns the value the alerts toggle should show once permission is known
    func setAlerts(_ enabled: Bool) async -> Bool {
        guard enabled else { return false }

        let granted = await notifications.requestPermission()
        alertsMessage = granted ? nil : "Notifications are turned off for ScamShield. Turn them on in iOS Settings to get scam alerts."
        return granted
    }
}
