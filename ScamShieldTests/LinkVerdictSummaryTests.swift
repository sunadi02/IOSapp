//
//  LinkVerdictSummaryTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-24.
//

import Testing
import Foundation
@testable import ScamShield

@MainActor
struct LinkVerdictSummaryTests {

    private func result(
        level: RiskLevel,
        score: Int,
        type: ScanType = .link,
        input: String = "https://evil.example.com/login",
        signals: [RiskSignal] = []
    ) -> ScanResult {
        ScanResult(type: type, input: input, riskLevel: level, trustScore: score, signals: signals)
    }

    @Test func safeLinkIsReportedAsSafeWithItsScore() {
        let sentence = LinkVerdictSummary.checkSentence(for: result(level: .safe, score: 100))
        #expect(sentence.contains("looks safe"))
        #expect(sentence.contains("Trust score 100 out of 100"))
    }

    @Test func riskyLinkSaysWhyAndTellsYouNotToOpenIt() {
        let signals = [
            RiskSignal(title: "Unusual domain ending", detail: "x", weight: 15),
            RiskSignal(title: "Brand impersonation", detail: "x", weight: 35)
        ]
        let sentence = LinkVerdictSummary.checkSentence(for: result(level: .risky, score: 50, signals: signals))

        #expect(sentence.contains("looks risky"))
        #expect(sentence.contains("The main reason is Brand impersonation."))
        #expect(sentence.contains("Do not open it"))
    }

    @Test func unknownLinkDoesNotClaimToBeSafe() {
        let sentence = LinkVerdictSummary.checkSentence(for: result(level: .unknown, score: 85))
        #expect(sentence.contains("could not confirm"))
        #expect(!sentence.contains("looks safe"))
    }

    @Test func noReasonIsMentionedWhenThereAreNoWarnings() {
        let sentence = LinkVerdictSummary.checkSentence(for: result(level: .unknown, score: 100))
        #expect(!sentence.contains("main reason"))
    }

    @Test func notesWithNoWeightAreNotGivenAsTheReason() {
        let note = RiskSignal(title: "Online check unavailable", detail: "x", weight: 0)
        let sentence = LinkVerdictSummary.checkSentence(for: result(level: .unknown, score: 100, signals: [note]))
        #expect(!sentence.contains("main reason"))
    }

    @Test(arguments: [
        (RiskLevel.safe, "safe"),
        (RiskLevel.risky, "risky"),
        (RiskLevel.unknown, "unconfirmed")
    ])
    func lastScanSentenceUsesPlainWords(level: RiskLevel, word: String) {
        let sentence = LinkVerdictSummary.lastScanSentence(for: result(level: level, score: 40))
        #expect(sentence == "Your last scan was evil.example.com and it looks \(word). Trust score 40 out of 100.")
    }

    @Test func linkSubjectIsJustTheWebsite() {
        #expect(LinkVerdictSummary.subject(for: result(level: .safe, score: 100)) == "evil.example.com")
    }

    @Test func messageTextIsNeverReadOut() {
        let scan = result(level: .risky, score: 10, type: .screenshot, input: "Share your OTP 482913 now")
        let sentence = LinkVerdictSummary.lastScanSentence(for: scan)

        #expect(LinkVerdictSummary.subject(for: scan) == "a message")
        #expect(!sentence.contains("482913"))
    }

    @Test func qrCodeThatIsNotALinkIsShortened() {
        let text = "Wi-Fi network: " + String(repeating: "x", count: 80)
        let scan = result(level: .unknown, score: 90, type: .qr, input: text)
        #expect(LinkVerdictSummary.subject(for: scan).count == 40)
    }
}
