//
//  HistoryRepositoryTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-23.
//

import Testing
import Foundation
@testable import ScamShield

@MainActor
struct HistoryRepositoryTests {

    //each test gets its own empty in memory store
    let repository = CoreDataHistoryRepository(context: PersistenceController(inMemory: true).viewContext)

    private func makeResult(input: String = "https://example.com", date: Date = Date()) -> ScanResult {
        ScanResult(
            type: .link,
            input: input,
            riskLevel: .risky,
            trustScore: 40,
            signals: [RiskSignal(title: "Not encrypted", detail: "Uses http", weight: 15)],
            date: date
        )
    }

    @Test func storeStartsEmpty() throws {
        #expect(try repository.fetchAll().isEmpty)
    }

    @Test func savedResultComesBackUnchanged() throws {
        let result = makeResult()
        try repository.save(result)
        #expect(try repository.fetchAll() == [result])
    }

    @Test func newestScanIsFirst() throws {
        let older = makeResult(input: "old.com", date: Date(timeIntervalSinceNow: -3600))
        let newer = makeResult(input: "new.com")
        try repository.save(older)
        try repository.save(newer)
        #expect(try repository.fetchAll().map(\.input) == ["new.com", "old.com"])
    }

    @Test func savingSameScanTwiceDoesNotDuplicate() throws {
        let result = makeResult()
        try repository.save(result)
        try repository.save(result)
        #expect(try repository.fetchAll().count == 1)
    }

    @Test func deleteRemovesOnlyThatScan() throws {
        let first = makeResult(input: "a.com")
        let second = makeResult(input: "b.com")
        try repository.save(first)
        try repository.save(second)

        try repository.delete(id: first.id)
        #expect(try repository.fetchAll().map(\.id) == [second.id])
    }

    @Test func deletingUnknownIdDoesNothing() throws {
        try repository.save(makeResult())
        try repository.delete(id: UUID())
        #expect(try repository.fetchAll().count == 1)
    }

    @Test func newScansStartUnsynced() throws {
        let result = makeResult()
        try repository.save(result)
        #expect(try repository.fetchUnsynced() == [result])
    }

    @Test func markingSyncedTakesThemOffTheUnsyncedList() throws {
        let result = makeResult()
        try repository.save(result)

        try repository.markSynced(ids: [result.id])
        #expect(try repository.fetchUnsynced().isEmpty)
        #expect(try repository.fetchAll() == [result])
    }

    @Test func markingOneScanLeavesTheOthersUnsynced() throws {
        let first = makeResult(input: "a.com")
        let second = makeResult(input: "b.com")
        try repository.save(first)
        try repository.save(second)

        try repository.markSynced(ids: [first.id])
        #expect(try repository.fetchUnsynced().map(\.id) == [second.id])
    }

    @Test func savingASyncedScanAgainMakesItUnsyncedAgain() throws {
        let result = makeResult()
        try repository.save(result)
        try repository.markSynced(ids: [result.id])

        try repository.save(result)
        #expect(try repository.fetchUnsynced().count == 1)
    }

    @Test func unsyncedScansComeOldestFirst() throws {
        let older = makeResult(input: "old.com", date: Date(timeIntervalSinceNow: -3600))
        let newer = makeResult(input: "new.com")
        try repository.save(newer)
        try repository.save(older)

        #expect(try repository.fetchUnsynced().map(\.input) == ["old.com", "new.com"])
    }

    @Test func markingNothingOrUnknownScansChangesNothing() throws {
        let result = makeResult()
        try repository.save(result)

        try repository.markSynced(ids: [])
        try repository.markSynced(ids: [UUID()])
        #expect(try repository.fetchUnsynced().count == 1)
    }

    @Test func deleteAllClearsHistory() throws {
        try repository.save(makeResult(input: "a.com"))
        try repository.save(makeResult(input: "b.com"))
        try repository.deleteAll()
        #expect(try repository.fetchAll().isEmpty)
    }
}
