//
//  AccessibilityTextTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-24.
//

import Testing
import Foundation
@testable import ScamShield

@MainActor
struct AccessibilityTextTests {

    @Test func linkDescriptionNamesTheTypeAddressVerdictAndScore() {
        let scan = ScanResult(type: .link, input: "https://evil.com", riskLevel: .risky, trustScore: 20)
        #expect(scan.accessibilityDescription == "Link https://evil.com, Risky, trust score 20")
    }

    @Test func qrCodeDescriptionUsesItsOwnTypeName() {
        let scan = ScanResult(type: .qr, input: "Table12", riskLevel: .safe, trustScore: 100)
        #expect(scan.accessibilityDescription == "QR Code Table12, Safe, trust score 100")
    }

    @Test func messageTextIsNeverReadOut() {
        let scan = ScanResult(type: .screenshot, input: "Share your OTP 482913 now", riskLevel: .risky, trustScore: 10)

        #expect(scan.accessibilityDescription == "Message screenshot, Risky, trust score 10")
        #expect(!scan.accessibilityDescription.contains("482913"))
    }

    @Test(arguments: [
        (RiskLevel.safe, 100, "Scan finished. Safe. Trust score 100 out of 100."),
        (RiskLevel.unknown, 65, "Scan finished. Unknown. Trust score 65 out of 100."),
        (RiskLevel.risky, 12, "Scan finished. Risky. Trust score 12 out of 100.")
    ])
    func announcementGivesTheVerdictFirst(level: RiskLevel, score: Int, expected: String) {
        let scan = ScanResult(type: .link, input: "https://example.com", riskLevel: level, trustScore: score)
        #expect(scan.completionAnnouncement == expected)
    }

    @Test func announcementNeverIncludesTheScannedText() {
        let scan = ScanResult(type: .screenshot, input: "secret message text", riskLevel: .risky, trustScore: 5)
        #expect(!scan.completionAnnouncement.contains("secret"))
    }

    @Test func identifiersAreUniqueAndFilledIn() {
        let ids = [
            AccessibilityID.authEmail,
            AccessibilityID.authPassword,
            AccessibilityID.authSubmit,
            AccessibilityID.checkLinkInput,
            AccessibilityID.checkLinkSubmit,
            AccessibilityID.signOut
        ]

        #expect(Set(ids).count == ids.count)
        #expect(ids.allSatisfy { !$0.isEmpty })
    }
}
