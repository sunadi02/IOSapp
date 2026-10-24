//
//  Mocks.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-24.
//

import Foundation
@testable import ScamShield

//records alerts instead of showing real notifications
@MainActor
final class MockNotifier: NotificationScheduling {
    var permissionGranted = true
    private(set) var permissionRequests = 0
    private(set) var alerts: [ScanResult] = []

    func requestPermission() async -> Bool {
        permissionRequests += 1
        return permissionGranted
    }

    func sendScamAlert(for scan: ScanResult) async {
        alerts.append(scan)
    }
}

//answers by host so one link can be flagged while the rest stay clean
@MainActor
final class StubReputationChecker: LinkReputationChecking {
    var threatsByHost: [String: [String]] = [:]
    var error: Error?
    private(set) var checkedURLs: [URL] = []

    func threats(for url: URL) async throws -> [String] {
        checkedURLs.append(url)
        if let error { throw error }
        return threatsByHost[url.host() ?? ""] ?? []
    }
}

//in memory stand in for firestore with separate switches for each kind of failure
@MainActor
final class MockRemoteHistory: RemoteHistoryStoring {
    var stored: [ScanResult] = []
    var fetchError: Error?
    var uploadError: Error?
    var deleteError: Error?
    private(set) var deletedIDs: [UUID] = []

    func fetchAll(userID: String) async throws -> [ScanResult] {
        if let fetchError { throw fetchError }
        return stored
    }

    func upsert(_ results: [ScanResult], userID: String) async throws {
        if let uploadError { throw uploadError }
        for result in results {
            stored.removeAll { $0.id == result.id }
            stored.append(result)
        }
    }

    func delete(ids: [UUID], userID: String) async throws {
        if let deleteError { throw deleteError }
        deletedIDs.append(contentsOf: ids)
        stored.removeAll { ids.contains($0.id) }
    }
}

//lets a test sign the user in and out after the service was created
@MainActor
final class SessionBox {
    var userID: String? = "user-1"
}
