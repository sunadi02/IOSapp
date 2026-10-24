//
//  TimeoutTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-25.
//

import Testing
import Foundation
@testable import ScamShield

@MainActor
struct TimeoutTests {

    @Test func workThatFinishesInTimeGivesItsAnswer() async {
        let answer = await Timeout.run(after: 5) { 42 }
        #expect(answer == 42)
    }

    @Test func workThatNeverFinishesGivesNilAfterTheLimit() async {
        let started = Date()
        let answer: Int? = await Timeout.run(after: 0.05) {
            try? await Task.sleep(for: .seconds(3))
            return 7
        }

        #expect(answer == nil)
        #expect(Date().timeIntervalSince(started) < 2)
    }

    @Test func workThatAnswersNothingGivesNilStraightAway() async {
        let started = Date()
        let answer: Int? = await Timeout.run(after: 5) { nil }

        #expect(answer == nil)
        #expect(Date().timeIntervalSince(started) < 2)
    }

    @Test func aLateAnswerAfterTheLimitIsIgnoredSafely() async throws {
        let answer: Int? = await Timeout.run(after: 0.02) {
            try? await Task.sleep(for: .milliseconds(100))
            return 9
        }
        #expect(answer == nil)

        //the slow work finishes now, and must not resume anything a second time
        try await Task.sleep(for: .milliseconds(250))
    }

    @Test func gateOnlyWakesTheCallerOnce() async {
        let value = await withCheckedContinuation { (continuation: CheckedContinuation<Int, Never>) in
            let gate = OneShot(continuation)
            gate.resume(returning: 1)
            gate.resume(returning: 2)
        }
        #expect(value == 1)
    }
}
