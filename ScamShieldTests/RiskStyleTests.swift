//
//  RiskStyleTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-24.
//

import Testing
import Foundation
@testable import ScamShield

@MainActor
struct RiskStyleTests {

    @Test func everyVerdictHasItsOwnWordIconAndAdvice() {
        let levels = RiskLevel.allCases

        #expect(Set(levels.map(\.title)).count == levels.count)
        #expect(Set(levels.map(\.systemImage)).count == levels.count)
        #expect(Set(levels.map(\.advice)).count == levels.count)
        #expect(levels.allSatisfy { !$0.title.isEmpty && !$0.advice.isEmpty })
    }

    @Test func riskyAdviceTellsPeopleNotToShareSecrets() {
        #expect(RiskLevel.risky.advice.contains("OTP"))
    }

    @Test func unknownAdviceDoesNotClaimSafety() {
        #expect(!RiskLevel.unknown.advice.lowercased().contains("no known threats"))
    }

    @Test(arguments: [
        (ScanType.link, "Link"),
        (ScanType.qr, "QR Code"),
        (ScanType.screenshot, "Screenshot")
    ])
    func scanTypesHaveReadableNames(type: ScanType, expected: String) {
        #expect(type.title == expected)
    }

    @Test func scanTypesHaveDifferentIcons() {
        let icons = ScanType.allCases.map(\.systemImage)
        #expect(Set(icons).count == icons.count)
    }

    @Test func sharingALinkResultNamesTheLinkAndScore() {
        let scan = ScanResult(type: .link, input: "https://example.com", riskLevel: .risky, trustScore: 25)

        #expect(scan.shareText.contains("https://example.com"))
        #expect(scan.shareText.contains("Risky"))
        #expect(scan.shareText.contains("25/100"))
    }

    @Test func sharingAQRResultNamesTheAddressToo() {
        let scan = ScanResult(type: .qr, input: "https://example.com", riskLevel: .safe, trustScore: 100)
        #expect(scan.shareText.contains("https://example.com"))
    }

    @Test func sharingAMessageResultKeepsTheMessagePrivate() {
        let scan = ScanResult(type: .screenshot, input: "my private message", riskLevel: .risky, trustScore: 5)

        #expect(!scan.shareText.contains("private"))
        #expect(scan.shareText.contains("a message"))
    }
}
