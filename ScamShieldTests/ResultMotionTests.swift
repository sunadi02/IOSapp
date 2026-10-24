//
//  ResultMotionTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-24.
//

import Testing
import Foundation
@testable import ScamShield

@MainActor
struct ResultMotionTests {

    @Test(arguments: [
        (72, true, 72),
        (72, false, 0),
        (0, true, 0),
        (100, false, 0)
    ])
    func ringOnlyStartsFullWhenMotionIsReduced(score: Int, reduceMotion: Bool, expected: Int) {
        #expect(ResultMotion.startingScore(for: score, reduceMotion: reduceMotion) == expected)
    }

    @Test(arguments: [
        (0, 0.5),
        (50, 0.8),
        (100, 1.1),
        (150, 1.1),
        (-20, 0.5)
    ])
    func fillingTakesLongerForHigherScores(score: Int, expected: Double) {
        #expect(abs(ResultMotion.duration(forScore: score) - expected) < 0.0001)
    }

    @Test func fillingNeverTakesLongerThanAboutOneSecond() {
        let longest = (0...100).map { ResultMotion.duration(forScore: $0) }.max() ?? 0
        #expect(longest <= 1.1 + 0.0001)
    }

    @Test(arguments: [
        (RiskLevel.safe, ResultHaptic.success),
        (RiskLevel.unknown, ResultHaptic.warning),
        (RiskLevel.risky, ResultHaptic.error)
    ])
    func eachVerdictHasItsOwnHaptic(level: RiskLevel, expected: ResultHaptic) {
        #expect(level.haptic == expected)
    }

    @Test func noTwoVerdictsFeelTheSame() {
        let haptics = Set(RiskLevel.allCases.map(\.haptic))
        #expect(haptics.count == RiskLevel.allCases.count)
    }
}
