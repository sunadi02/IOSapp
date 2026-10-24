//
//  Mocks.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-24.
//

import AVFoundation
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

//stands in for the community collection and remembers what the app asked it
@MainActor
final class MockCommunityService: CommunityReporting {
    var counts: [String: Int] = [:]
    var countError: Error?
    var submitError: Error?
    var feed: [ScamReport] = []
    var feedError: Error?
    private(set) var queriedDomains: [String] = []
    private(set) var submissions: [(url: String, category: ScamCategory, type: ScanType)] = []

    func submit(url: String, category: ScamCategory, type: ScanType) async throws {
        if let submitError { throw submitError }
        submissions.append((url, category, type))
    }

    func reportCount(forDomain domain: String) async throws -> Int {
        queriedDomains.append(domain)
        if let countError { throw countError }
        return counts[domain] ?? 0
    }

    func reports(limit: Int) -> AsyncThrowingStream<[ScamReport], Error> {
        let feed = feed
        let feedError = feedError

        return AsyncThrowingStream { continuation in
            if let feedError {
                continuation.finish(throwing: feedError)
            } else {
                continuation.yield(feed)
                continuation.finish()
            }
        }
    }
}

//camera that only counts what it was asked to do
final class MockCamera: CameraControlling {
    let session = AVCaptureSession()
    var setupResult: CameraSetupResult = .ready
    private(set) var startCount = 0
    private(set) var stopCount = 0
    private(set) var torchStates: [Bool] = []

    func configure() async -> CameraSetupResult { setupResult }
    func start(onCode: @escaping @Sendable (String) -> Void) { startCount += 1 }
    func stop() { stopCount += 1 }
    func setTorch(_ isOn: Bool) { torchStates.append(isOn) }
}

//returns the codes it was given so no real image is needed
struct MockBarcodeDetector: BarcodeDetecting {
    var found: [String] = []
    var shouldFail = false

    func payloads(inImageData data: Data) throws -> [String] {
        if shouldFail { throw URLError(.cannotDecodeContentData) }
        return found
    }

    func payloads(in pixelBuffer: CVPixelBuffer) throws -> [String] { found }
}

//lets a test sign the user in and out after the service was created
@MainActor
final class SessionBox {
    var userID: String? = "user-1"
}
