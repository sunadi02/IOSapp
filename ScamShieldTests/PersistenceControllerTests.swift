//
//  PersistenceControllerTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-24.
//

import Testing
import Foundation
import CoreData
@testable import ScamShield

@MainActor
struct PersistenceControllerTests {

    @Test func inMemoryStoreLoadsWithoutAnError() {
        #expect(PersistenceController(inMemory: true).loadError == nil)
    }

    @Test func modelDescribesAScanRecordWithAllItsFields() throws {
        let entity = try #require(PersistenceController.model.entitiesByName["ScanRecord"])
        let fields = Set(entity.attributesByName.keys)

        #expect(fields == ["id", "type", "input", "riskLevel", "trustScore", "signalsData", "date", "isSynced"])
    }

    @Test func storeMergesTwoRecordsThatShareAnID() throws {
        let context = PersistenceController(inMemory: true).viewContext
        let id = UUID()

        for input in ["a.com", "b.com"] {
            let record = ScanRecord(context: context)
            record.id = id
            record.type = "link"
            record.input = input
            record.riskLevel = "safe"
            record.trustScore = 50
            record.date = Date()
            record.isSynced = false
        }
        try context.save()

        #expect(try context.count(for: ScanRecord.fetchRequest()) == 1)
    }

    @Test func viewContextPicksUpChangesFromBackgroundWork() {
        let controller = PersistenceController(inMemory: true)
        #expect(controller.viewContext.automaticallyMergesChangesFromParent)
    }

    @Test func twoInMemoryStoresDoNotShareScans() throws {
        let first = CoreDataHistoryRepository(context: PersistenceController(inMemory: true).viewContext)
        let second = CoreDataHistoryRepository(context: PersistenceController(inMemory: true).viewContext)

        try first.save(ScanResult(type: .link, input: "a.com", riskLevel: .safe, trustScore: 90))

        #expect(try first.fetchAll().count == 1)
        #expect(try second.fetchAll().isEmpty)
    }

    @Test func signalsSurviveBeingStoredAndReadBack() throws {
        let repository = CoreDataHistoryRepository(context: PersistenceController(inMemory: true).viewContext)
        let result = ScanResult(
            type: .qr,
            input: "https://example.com",
            riskLevel: .unknown,
            trustScore: 70,
            signals: [
                RiskSignal(title: "Not encrypted", detail: "Uses http", weight: 15),
                RiskSignal(title: "Shortened link", detail: "Hides the destination", weight: 15)
            ]
        )

        try repository.save(result)
        #expect(try repository.fetchAll() == [result])
    }
}
