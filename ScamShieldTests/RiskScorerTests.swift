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

    @Test(arguments: [
        (0, true, RiskLevel.risky),
        (49, true, RiskLevel.risky),
        (50, true, RiskLevel.unknown),
        (79, true, RiskLevel.unknown),
        (80, true, RiskLevel.safe),
        (100, true, RiskLevel.safe),
        (80, false, RiskLevel.unknown),
        (100, false, RiskLevel.unknown),
        (10, false, RiskLevel.risky)
    ])
    func levelChangesAtTheBoundaries(score: Int, verified: Bool, expected: RiskLevel) {
        #expect(RiskScorer.riskLevel(for: score, verified: verified) == expected)
    }

    @Test func signalsWithNoWeightDoNotLowerTheScore() {
        #expect(RiskScorer.trustScore(for: [signal(0), signal(0)]) == 100)
    }

    @Test func weightsAddUp() {
        #expect(RiskScorer.trustScore(for: [signal(10), signal(15), signal(5)]) == 70)
    }

    @Test func unverifiedCleanResultIsOnlyUnknown() {
        let result = RiskScorer.makeResult(type: .qr, input: "Table 12", signals: [], verified: false)
        #expect(result.riskLevel == .unknown)
        #expect(result.trustScore == 100)
    }

    @Test func resultKeepsTheTypeAndInputItWasGiven() {
        let result = RiskScorer.makeResult(type: .screenshot, input: "some text", signals: [], verified: true)
        #expect(result.type == .screenshot)
        #expect(result.input == "some text")
    }

    @Test func everyResultGetsItsOwnID() {
        let first = RiskScorer.makeResult(type: .link, input: "a", signals: [], verified: true)
        let second = RiskScorer.makeResult(type: .link, input: "a", signals: [], verified: true)
        #expect(first.id != second.id)
    }

    @Test func resultListsStrongestSignalFirst() {
        let result = RiskScorer.makeResult(type: .link, input: "x", signals: [signal(5), signal(30), signal(10)], verified: true)
        #expect(result.signals.map(\.weight) == [30, 10, 5])
        #expect(result.trustScore == 55)
    }
}
