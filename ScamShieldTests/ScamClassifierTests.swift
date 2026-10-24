//
//  ScamClassifierTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-24.
//

import Testing
import Foundation
@testable import ScamShield

//the real model tests only run once ScamTextClassifier.mlmodel has been added to the app
private let modelIsInstalled = Bundle.main.url(forResource: "ScamTextClassifier", withExtension: "mlmodelc") != nil

@MainActor
struct ScamClassifierTests {

    @Test(arguments: [(1.0, 30), (0.95, 30), (0.9, 30), (0.89, 15), (0.8, 15), (0.75, 15)])
    func strongerScoresGetHeavierSignals(probability: Double, expectedWeight: Int) {
        #expect(ScamClassifier.signal(for: probability)?.weight == expectedWeight)
    }

    @Test(arguments: [0.74, 0.5, 0.1, 0.0])
    func weakScoresGiveNoSignal(probability: Double) {
        #expect(ScamClassifier.signal(for: probability) == nil)
    }

    @Test func signalShowsTheScoreAsAPercentage() {
        let signal = ScamClassifier.signal(for: 0.923)
        #expect(signal?.detail.contains("92%") == true)
    }

    @Test func classifierWithoutAModelSaysItIsUnavailable() throws {
        let emptyBundle = try #require(Bundle(path: NSTemporaryDirectory()))
        let classifier = ScamClassifier(bundle: emptyBundle)

        #expect(!classifier.isAvailable)
        #expect(classifier.scamProbability(for: "Share your OTP now") == nil)
    }

    @Test(.enabled(if: modelIsInstalled))
    func installedModelIsLoaded() {
        #expect(ScamClassifier.shared.isAvailable)
    }

    @Test(.enabled(if: modelIsInstalled))
    func installedModelDistrustsAnObviousBankScam() throws {
        let text = "Dear customer, your account is suspended. Verify your details now at http://bank-verify.xyz and share your OTP"
        let probability = try #require(ScamClassifier.shared.scamProbability(for: text))
        #expect(probability > 0.6)
    }

    @Test(.enabled(if: modelIsInstalled))
    func installedModelLeavesOrdinaryChatAlone() throws {
        let probability = try #require(ScamClassifier.shared.scamProbability(for: "Are we still meeting for lunch tomorrow?"))
        #expect(probability < 0.4)
    }

    @Test(.enabled(if: modelIsInstalled))
    func installedModelDoesNotPunishAGenuineOTPMessage() throws {
        let text = "Your OTP is 482913. Do not share it with anyone."
        let probability = try #require(ScamClassifier.shared.scamProbability(for: text))
        #expect(probability < 0.5)
    }

    @Test(.enabled(if: modelIsInstalled))
    func scoresStayBetweenZeroAndOne() throws {
        let probability = try #require(ScamClassifier.shared.scamProbability(for: "Congratulations you won a prize"))
        #expect((0...1).contains(probability))
    }
}
