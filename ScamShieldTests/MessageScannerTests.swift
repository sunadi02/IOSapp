//
//  MessageScannerTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-24.
//

import Testing
import Foundation
@testable import ScamShield

@MainActor
struct MessageScannerTests {

    private func makeScanner(threats: [String] = [], error: Error? = nil) -> MessageScanner {
        let reputation = MockReputationChecker(foundThreats: threats, error: error)
        return MessageScanner(linkScanner: LinkScanner(reputation: reputation))
    }

    @Test(arguments: ["", "   \n  "])
    func emptyMessageThrows(_ text: String) async {
        await #expect(throws: MessageScanError.self) {
            try await makeScanner().scan(text)
        }
    }

    @Test func scamMessageWithAFakeLinkIsRisky() async throws {
        let text = "Dear customer, your Commercial Bank account is suspended. Verify your details immediately: http://combank-secure.xyz"
        let result = try await makeScanner().scan(text)

        #expect(result.type == .screenshot)
        #expect(result.riskLevel == .risky)
        #expect(result.input == text)
        #expect(result.signals.map(\.title).contains("Threat of losing access"))
        #expect(result.signals.map(\.title).contains("Brand name with an unofficial link"))
    }

    @Test func wordingAloneCanStillMakeAMessageRisky() async throws {
        let result = try await makeScanner().scan("URGENT: your account will be suspended. Share your OTP now")
        #expect(result.riskLevel == .risky)
    }

    @Test func googleReportedLinkInsideAMessageDecidesTheResult() async throws {
        let result = try await makeScanner(threats: ["SOCIAL_ENGINEERING"]).scan("Have a look at https://www.example.com")
        #expect(result.riskLevel == .risky)
        #expect(result.signals.contains { $0.detail.hasPrefix("In www.example.com:") })
    }

    @Test func plainMessageWithACheckedSafeLinkIsSafe() async throws {
        let result = try await makeScanner().scan("Here is the receipt https://www.apple.com/receipt")
        #expect(result.riskLevel == .safe)
        #expect(result.trustScore == 100)
    }

    @Test func messageWithoutLinksIsNeverCalledSafe() async throws {
        let result = try await makeScanner().scan("See you at lunch")
        #expect(result.riskLevel == .unknown)
        #expect(result.trustScore == 100)
    }

    @Test func linkThatCouldNotBeCheckedOnlineKeepsTheMessageUnknown() async throws {
        let result = try await makeScanner(error: URLError(.notConnectedToInternet)).scan("Read this https://www.apple.com")
        #expect(result.riskLevel == .unknown)
    }

    @Test func onlyTheRiskiestLinkAddsItsSignals() async throws {
        let result = try await makeScanner().scan("https://www.apple.com and http://paypal-login-verify.xyz")

        #expect(result.riskLevel == .risky)
        #expect(!result.signals.contains { $0.detail.hasPrefix("In www.apple.com") })
        #expect(result.signals.contains { $0.detail.hasPrefix("In paypal-login-verify.xyz") })
    }

    @Test func longMessageIsShortenedBeforeItIsKept() async throws {
        let result = try await makeScanner().scan(String(repeating: "word ", count: 600))
        #expect(result.input.count == MessageScanner.maxStoredLength)
    }

    @Test func sharingAResultDoesNotRevealTheMessage() async throws {
        let result = try await makeScanner().scan("My secret message about my account")
        #expect(!result.shareText.contains("secret"))
        #expect(result.shareText.contains("a message"))
    }

    @Test func englishLimitationIsExplainedInTheResult() async throws {
        let sinhala = String(repeating: "ඔබගේ ගිණුම අත්හිටුවා ඇත. කරුණාකර ඔබගේ විස්තර තහවුරු කරන්න. ", count: 3)
        let result = try await makeScanner().scan(sinhala)

        #expect(result.riskLevel == .unknown)
        #expect(result.signals.map(\.title).contains("Message not fully checked"))
    }
}
