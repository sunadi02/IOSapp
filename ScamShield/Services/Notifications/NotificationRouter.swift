//
//  NotificationRouter.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import Foundation
import Observation
import UserNotifications

//holds the scan a tapped alert points to so the main screen can show it
@Observable
final class NotificationRouter {

    var openedScan: ScanResult?

    private let history: HistoryStoring

    init(history: HistoryStoring = AppHistory.store) {
        self.history = history
    }

    func open(id: UUID) {
        openedScan = (try? history.fetchAll())?.first { $0.id == id }
    }
}

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    var onOpenScan: ((UUID) -> Void)?

    //alerts still show as a banner while the app is open
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard let text = userInfo[NotificationKey.scanID] as? String,
              let id = UUID(uuidString: text) else { return }

        await MainActor.run { onOpenScan?(id) }
    }
}
