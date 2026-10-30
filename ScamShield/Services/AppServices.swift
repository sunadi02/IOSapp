//
//  AppServices.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import Foundation
import Observation
import FirebaseAuth
import UserNotifications

//long lived services created once and shared through the environment
@Observable
final class AppServices {

    let notifications: NotificationScheduling
    let recheck: RecheckService
    let sync: HistorySyncService
    let router: NotificationRouter
    let network: NetworkMonitor
    let searchIndex: SearchIndexing

    private let history: HistoryStoring
    private let notificationDelegate = NotificationDelegate()
    @ObservationIgnored private var authListener: NSObjectProtocol?

    init(
        notifications: NotificationScheduling = NotificationService(),
        history: HistoryStoring = AppHistory.store,
        sync: HistorySyncService = AppHistory.sync,
        network: NetworkMonitor = NetworkMonitor(),
        searchIndex: SearchIndexing = SpotlightIndexer()
    ) {
        self.notifications = notifications
        self.history = history
        self.sync = sync
        self.network = network
        self.searchIndex = searchIndex
        recheck = RecheckService(history: history, notifications: notifications)
        router = NotificationRouter(history: history)

        notificationDelegate.onOpenScan = { [router] id in router.open(id: id) }
        UNUserNotificationCenter.current().delegate = notificationDelegate

        //anything saved or deleted while offline is caught up as soon as the connection returns
        network.onReconnect = { [sync, recheck] in
            Task {
                await sync.sync()
                await recheck.run()
            }
        }
    }

    //starts after firebase is configured, signing in pulls the cloud history and signing out clears this device
    func start() {
        network.start()
        guard authListener == nil else { return }

        authListener = Auth.auth().addStateDidChangeListener { [sync, searchIndex] _, user in
            Task { @MainActor in
                if user == nil {
                    sync.didSignOut()
                    //the next person to sign in on this device must not find the last one's scans in search
                    searchIndex.removeAll()
                } else if let user {
                    await FirestoreUserProfile.save(user)
                    await sync.sync()
                }
            }
        }
    }

    func appBecameActive() async {
        await sync.sync()
        await recheck.run()

        //scans pulled from other devices are added to search here
        if let scans = try? history.fetchAll() {
            searchIndex.replaceAll(with: scans)
        }
    }
}
