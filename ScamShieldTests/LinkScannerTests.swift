//
//  LinkScannerTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-23.
//

import Testing
import Foundation
@testable import ScamShield

@MainActor
struct LinkScannerTests {

    @Test func invalidInputThrows() async {
        let scanner = LinkScanner(reputation: MockReputationChecker())
        await #expect(throws: LinkScanError.self) {
            try await scanner.scan("not a link")
        }
    }

    @Test func cleanLinkIsSafe() async throws {
        let scanner = LinkScanner(reputation: MockReputationChecker())
        let result = try await scanner.scan("https://www.apple.com")
        #expect(result.riskLevel == .safe)
        #expect(result.trustScore == 100)
    }

    @Test func googleThreatMakesLinkRisky() async throws {
        let scanner = LinkScanner(reputation: MockReputationChecker(foundThreats: ["SOCIAL_ENGINEERING"]))
        let result = try await scanner.scan("https://www.example.com")
        #expect(result.riskLevel == .risky)
        #expect(result.signals.first?.title == "Reported by Google Safe Browsing")
        #expect(result.signals.first?.detail.contains("phishing") == true)
    }

    @Test func offlineCleanLinkIsUnknownNotSafe() async throws {
        let scanner = LinkScanner(reputation: MockReputationChecker(error: URLError(.notConnectedToInternet)))
        let result = try await scanner.scan("https://www.apple.com")
        #expect(result.riskLevel == .unknown)
        #expect(result.signals.map(\.title).contains("Online check unavailable"))
    }

    @Test func offlineScanStillCatchesObviousScams() async throws {
        let scanner = LinkScanner(reputation: MockReputationChecker(error: URLError(.timedOut)))
        let result = try await scanner.scan("http://paypal-login-verify.xyz")
        #expect(result.riskLevel == .risky)
    }

    @Test func inputIsSavedAsNormalizedLink() async throws {
        let scanner = LinkScanner(reputation: MockReputationChecker())
        let result = try await scanner.scan("  example.com  ")
        #expect(result.input == "https://example.com")
    }

    @Test(arguments: [
        ("SOCIAL_ENGINEERING", "phishing"),
        ("MALWARE", "malware"),
        ("NEW_THREAT_TYPE", "new threat type")
    ])
    func threatNamesAreReadable(code: String, expected: String) {
        #expect(LinkScanner.friendlyName(for: code) == expected)
    }
}
