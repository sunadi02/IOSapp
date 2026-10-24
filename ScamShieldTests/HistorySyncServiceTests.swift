//
//  HistorySyncServiceTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-24.
//

import Testing
import Foundation
@testable import ScamShield

@MainActor
struct HistorySyncServiceTests {

    let local = CoreDataHistoryRepository(context: PersistenceController(inMemory: true).viewContext)
    let remote = MockRemoteHistory()
    let session = SessionBox()
    let defaults = UserDefaults(suiteName: "HistorySyncServiceTests-\(UUID().uuidString)")!
    let service: HistorySyncService

    init() {
        service = HistorySyncService(local: local, remote: remote, currentUserID: { [session] in session.userID }, defaults: defaults)
    }

    private func scan(_ input: String, level: RiskLevel = .safe) -> ScanResult {
        ScanResult(type: .link, input: input, riskLevel: level, trustScore: 80, date: Date(timeIntervalSince1970: 1_800_000_000))
    }

    private func saveSynced(_ scan: ScanResult) throws {
        try local.save(scan)
        try local.markSynced(ids: [scan.id])
    }

    @Test func pushUploadsNewScansAndMarksThemSynced() async throws {
        let first = scan("a.com")
        let second = scan("b.com")
        try local.save(first)
        try local.save(second)

        await service.push()
        #expect(Set(remote.stored.map(\.id)) == [first.id, second.id])
        #expect(try local.fetchUnsynced().isEmpty)
    }

    @Test func pushDoesNothingWhenSignedOut() async throws {
        session.userID = nil
        try local.save(scan("a.com"))

        await service.push()
        #expect(remote.stored.isEmpty)
        #expect(try local.fetchUnsynced().count == 1)
    }

    @Test func failedUploadKeepsScansUnsyncedForNextTime() async throws {
        remote.uploadError = URLError(.notConnectedToInternet)
        try local.save(scan("a.com"))

        await service.push()
        #expect(try local.fetchUnsynced().count == 1)

        remote.uploadError = nil
        await service.push()
        #expect(try local.fetchUnsynced().isEmpty)
        #expect(remote.stored.count == 1)
    }

    @Test func screenshotScansAreNeverUploaded() async throws {
        let message = ScanResult(type: .screenshot, input: "private message text", riskLevel: .risky, trustScore: 10)
        let link = scan("a.com")
        try local.save(message)
        try local.save(link)

        await service.push()
        #expect(remote.stored.map(\.id) == [link.id])
        #expect(try local.fetchUnsynced().map(\.id) == [message.id])
    }

    @Test func screenshotScansSurviveASync() async throws {
        let message = ScanResult(type: .screenshot, input: "private message text", riskLevel: .risky, trustScore: 10)
        try local.save(message)
        remote.stored = []

        await service.sync()
        #expect(try local.fetchAll().map(\.id) == [message.id])
    }

    @Test func changedScanIsUploadedAgain() async throws {
        let original = scan("a.com")
        try local.save(original)
        await service.push()

        let flagged = ScanResult(id: original.id, type: .link, input: "a.com", riskLevel: .risky, trustScore: 0, date: original.date)
        try local.save(flagged)
        await service.push()

        #expect(remote.stored.count == 1)
        #expect(remote.stored.first?.riskLevel == .risky)
    }

    @Test func pullAddsScansFromOtherDevicesAsSynced() async throws {
        remote.stored = [scan("a.com"), scan("b.com")]

        await service.sync()
        #expect(try local.fetchAll().count == 2)
        #expect(try local.fetchUnsynced().isEmpty)
    }

    @Test func pullDoesNotDuplicateExistingScans() async throws {
        let existing = scan("a.com")
        try saveSynced(existing)
        remote.stored = [existing]

        await service.sync()
        #expect(try local.fetchAll().count == 1)
    }

    @Test func pullRemovesScansDeletedOnAnotherDevice() async throws {
        try saveSynced(scan("a.com"))
        remote.stored = []

        await service.sync()
        #expect(try local.fetchAll().isEmpty)
    }

    @Test func pullTakesTheRiskyVersionFromAnotherDevice() async throws {
        let original = scan("a.com")
        try saveSynced(original)
        remote.stored = [ScanResult(id: original.id, type: .link, input: "a.com", riskLevel: .risky, trustScore: 0, date: original.date)]

        await service.sync()
        #expect(try local.fetchAll().first?.riskLevel == .risky)
        #expect(try local.fetchUnsynced().isEmpty)
    }

    @Test func failedPullChangesNothing() async throws {
        try saveSynced(scan("a.com"))
        remote.fetchError = URLError(.notConnectedToInternet)

        await service.sync()
        #expect(try local.fetchAll().count == 1)
    }

    @Test func deletedScanReachesTheCloudAndStaysDeleted() async throws {
        let doomed = scan("a.com")
        try saveSynced(doomed)
        remote.stored = [doomed]

        try local.delete(id: doomed.id)
        service.queueDeletes([doomed.id])
        await service.sync()

        #expect(remote.stored.isEmpty)
        #expect(try local.fetchAll().isEmpty)
        #expect(service.pendingDeletes.isEmpty)
    }

    @Test func deleteStaysQueuedWhileCloudCannotBeReached() async throws {
        let doomed = scan("a.com")
        remote.stored = [doomed]
        remote.deleteError = URLError(.notConnectedToInternet)
        service.queueDeletes([doomed.id])

        await service.sync()
        #expect(service.pendingDeletes == [doomed.id])
        #expect(try local.fetchAll().isEmpty)

        remote.deleteError = nil
        await service.sync()
        #expect(service.pendingDeletes.isEmpty)
        #expect(remote.stored.isEmpty)
    }

    @Test func signingOutClearsThisDeviceOnly() throws {
        try saveSynced(scan("a.com"))
        service.queueDeletes([UUID()])

        service.didSignOut()
        #expect(try local.fetchAll().isEmpty)
        #expect(service.pendingDeletes.isEmpty)
    }

    @Test func syncedStoreQueuesRemoteDeleteForOneScan() throws {
        let store = SyncedHistoryStore(local: local, sync: service)
        let doomed = scan("a.com")
        try local.save(doomed)

        try store.delete(id: doomed.id)
        #expect(try local.fetchAll().isEmpty)
        #expect(service.pendingDeletes == [doomed.id])
    }

    @Test func syncedStoreQueuesRemoteDeleteForEveryScan() throws {
        let store = SyncedHistoryStore(local: local, sync: service)
        let first = scan("a.com")
        let second = scan("b.com")
        try local.save(first)
        try local.save(second)

        try store.deleteAll()
        #expect(try local.fetchAll().isEmpty)
        #expect(service.pendingDeletes == [first.id, second.id])
    }

    @Test func mergeKeepsUnsyncedLocalScans() {
        let mine = scan("a.com")
        let plan = HistorySyncService.mergePlan(remote: [], local: [mine], unsyncedIDs: [mine.id], pendingDeletes: [])
        #expect(plan.localDeletes.isEmpty)
    }

    @Test func mergeSkipsScansWaitingToBeDeleted() {
        let gone = scan("a.com")
        let plan = HistorySyncService.mergePlan(remote: [gone], local: [], unsyncedIDs: [], pendingDeletes: [gone.id])
        #expect(plan.upserts.isEmpty)
    }

    @Test func mergeDoesNotOverwriteUnsyncedLocalChanges() {
        let original = scan("a.com")
        let remoteRisky = ScanResult(id: original.id, type: .link, input: "a.com", riskLevel: .risky, trustScore: 0, date: original.date)
        let plan = HistorySyncService.mergePlan(remote: [remoteRisky], local: [original], unsyncedIDs: [original.id], pendingDeletes: [])
        #expect(plan.upserts.isEmpty)
    }

    @Test func mergeIgnoresSafeRemoteVersionOfExistingScan() {
        let existing = scan("a.com", level: .risky)
        let remoteCopy = ScanResult(id: existing.id, type: .link, input: "a.com", riskLevel: .safe, trustScore: 90, date: existing.date)
        let plan = HistorySyncService.mergePlan(remote: [remoteCopy], local: [existing], unsyncedIDs: [], pendingDeletes: [])
        #expect(plan.upserts.isEmpty)
    }
}
