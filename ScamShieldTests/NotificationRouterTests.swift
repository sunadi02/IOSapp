//
//  NotificationRouterTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-24.
//

import Testing
import Foundation
@testable import ScamShield

@MainActor
struct NotificationRouterTests {

    let history = CoreDataHistoryRepository(context: PersistenceController(inMemory: true).viewContext)

    @Test func tappedAlertOpensTheMatchingScan() throws {
        let scan = ScanResult(type: .link, input: "https://bad.example.com", riskLevel: .risky, trustScore: 0)
        try history.save(scan)
        let router = NotificationRouter(history: history)

        router.open(id: scan.id)
        #expect(router.openedScan?.id == scan.id)
    }

    @Test func unknownScanOpensNothing() {
        let router = NotificationRouter(history: history)
        router.open(id: UUID())
        #expect(router.openedScan == nil)
    }

    @Test func scanThatCannotBeLoadedOpensNothing() {
        let router = NotificationRouter(history: FailingHistoryStore())
        router.open(id: UUID())
        #expect(router.openedScan == nil)
    }
}
