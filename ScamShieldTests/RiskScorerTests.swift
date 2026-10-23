//
//  RiskScorerTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-23.
//

import Testing
import Foundation
@testable import ScamShield

@MainActor
struct RiskScorerTests {

    private func signal(_ weight: Int) -> RiskSignal {
        RiskSignal(title: "Test", detail: "Test signal", weight: weight)
    }

    @Test func noSignalsGivesFullScore() {
        #expect(RiskScorer.trustScore(for: []) == 100)
    }

    @Test func scoreNeverGoesBelowZero() {
        #expect(RiskScorer.trustScore(for: [signal(80), signal(80)]) == 0)
    }

    @Test func lowScoreIsRisky() {
        #expect(RiskScorer.riskLevel(for: 30, verified: true) == .risky)
    }

    @Test func highScoreIsSafeOnlyWhenVerified() {
        #expect(RiskScorer.riskLevel(for: 95, verified: true) == .safe)
        #expect(RiskScorer.riskLevel(for: 95, verified: false) == .unknown)
    }

    @Test func middleScoreIsUnknown() {
        #expect(RiskScorer.riskLevel(for: 65, verified: true) == .unknown)
    }

    @Test func resultListsStrongestSignalFirst() {
        let result = RiskScorer.makeResult(type: .link, input: "x", signals: [signal(5), signal(30), signal(10)], verified: true)
        #expect(result.signals.map(\.weight) == [30, 10, 5])
        #expect(result.trustScore == 55)
    }
}
