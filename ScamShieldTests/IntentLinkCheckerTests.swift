//
//  IntentLinkCheckerTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-24.
//

import Testing
import Foundation
@testable import ScamShield

@MainActor
struct IntentLinkCheckerTests {

    let history = CoreDataHistoryRepository(context: PersistenceController(inMemory: true).viewContext)

    private func makeChecker(threats: [String] = [], history: HistoryStoring? = nil) -> IntentLinkChecker {
        let scanner = LinkScanner(reputation: MockReputationChecker(foundThreats: threats))
        return IntentLinkChecker(scanner: scanner, history: history ?? self.history)
    }

    @Test func checkedLinkIsReturnedAndSavedToHistory() async throws {
        let result = try await makeChecker().check("https://www.apple.com")

        #expect(result.riskLevel == .safe)
        #expect(try history.fetchAll().map(\.id) == [result.id])
    }

    @Test func reportedLinkComesBackRisky() async throws {
        let result = try await makeChecker(threats: ["SOCIAL_ENGINEERING"]).check("https://www.example.com")
        #expect(result.riskLevel == .risky)
    }

    @Test func linkTypedWithoutHttpIsAccepted() async throws {
        let result = try await makeChecker().check("apple.com")
        #expect(result.input == "https://apple.com")
    }

    @Test func notALinkThrowsAndSavesNothing() async throws {
        await #expect(throws: LinkScanError.self) {
            try await makeChecker().check("hello there")
        }
        #expect(try history.fetchAll().isEmpty)
    }

    @Test func failedSaveStillGivesTheAnswer() async throws {
        let result = try await makeChecker(history: FailingHistoryStore()).check("https://www.apple.com")
        #expect(result.riskLevel == .safe)
    }

    @Test func errorShownToTheUserIsReadable() {
        let message = String(localized: CheckLinkIntentError.invalidLink.localizedStringResource)
        #expect(message.contains("web link"))
    }
}
