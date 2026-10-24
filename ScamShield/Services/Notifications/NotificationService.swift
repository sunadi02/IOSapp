//
//  NotificationService.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import Foundation
import UserNotifications

enum NotificationKey {
    nonisolated static let scanID = "scanID"
}

//protocol so alerts can be tested without the real notification center
protocol NotificationScheduling {
    func requestPermission() async -> Bool
    func sendScamAlert(for scan: ScanResult) async
}

struct NotificationService: NotificationScheduling {

    private let center = UNUserNotificationCenter.current()

    //asks only the first time, later calls just report the saved choice
    func requestPermission() async -> Bool {
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        default:
            return false
        }
    }

    func sendScamAlert(for scan: ScanResult) async {
        let content = UNMutableNotificationContent()
        content.title = "Scam alert"
        content.body = "A link you checked was reported as a scam: \(scan.input). Do not open it."
        content.sound = .default
        content.userInfo = [NotificationKey.scanID: scan.id.uuidString]

        let request = UNNotificationRequest(identifier: "scam-alert-\(scan.id.uuidString)", content: content, trigger: nil)
        try? await center.add(request)
    }
}
