//
//  ScanResultTests.swift
//  ScamShield
//
//  Created by student2 on 2026-10-21.
//

import Testing
import Foundation
@testable import ScamShield

@MainActor
struct ScanResultTests {

    @Test func trustScoreIsClampedAboveRange() {
        let result = ScanResult(type: .link, input: "https://example.com", riskLevel: .safe, trustScore: 150)
        #expect(result.trustScore == 100)
    }

    @Test func trustScoreIsClampedBelowRange() {
        let result = ScanResult(type: .link, input: "http://bad.test", riskLevel: .risky, trustScore: -20)
        #expect(result.trustScore == 0)
    }

    @Test(arguments: [0, 1, 50, 99, 100])
    func scoresInsideTheRangeAreKept(score: Int) {
        let result = ScanResult(type: .link, input: "x.com", riskLevel: .unknown, trustScore: score)
        #expect(result.trustScore == score)
    }

    @Test func resultSurvivesEncodingRoundTrip() throws {
        let original = ScanResult(type: .qr, input: "https://example.com", riskLevel: .unknown, trustScore: 50)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ScanResult.self, from: data)
        #expect(decoded == original)
    }

    @Test func signalsSurviveEncodingToo() throws {
        let original = ScanResult(
            type: .link,
            input: "http://example.com",
            riskLevel: .risky,
            trustScore: 30,
            signals: [
                RiskSignal(title: "Not encrypted", detail: "Uses http", weight: 15),
                RiskSignal(title: "Raw IP address", detail: "Uses numbers", weight: 30)
            ]
        )
        let decoded = try JSONDecoder().decode(ScanResult.self, from: JSONEncoder().encode(original))

        #expect(decoded.signals == original.signals)
        #expect(decoded.signals.map(\.id) == original.signals.map(\.id))
    }

    @Test func everyNewResultGetsItsOwnID() {
        let first = ScanResult(type: .link, input: "a.com", riskLevel: .safe, trustScore: 100)
        let second = ScanResult(type: .link, input: "a.com", riskLevel: .safe, trustScore: 100)
        #expect(first.id != second.id)
    }

    @Test func resultsWithTheSameIDAndContentAreEqual() {
        let id = UUID()
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let first = ScanResult(id: id, type: .link, input: "a.com", riskLevel: .safe, trustScore: 90, date: date)
        let second = ScanResult(id: id, type: .link, input: "a.com", riskLevel: .safe, trustScore: 90, date: date)

        #expect(first == second)
        #expect(Set([first, second]).count == 1)
    }

    @Test func riskLevelsAndTypesEncodeAsReadableWords() throws {
        let data = try JSONEncoder().encode(ScanResult(type: .screenshot, input: "x", riskLevel: .risky, trustScore: 1))
        let text = String(data: data, encoding: .utf8) ?? ""

        #expect(text.contains("\"screenshot\""))
        #expect(text.contains("\"risky\""))
    }
}
