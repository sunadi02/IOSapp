//
//  ScanResultTests.swift
//  ScamShield
//
//  Created by student2 on 2026-10-21.
//

import Testing
import Foundation
@testable import ScamShield

struct ScanResultTests {

    @Test func trustScoreIsClampedAboveRange() {
        let result = ScanResult(type: .link, input: "https://example.com", riskLevel: .safe, trustScore: 150)
        #expect(result.trustScore == 100)
    }

    @Test func trustScoreIsClampedBelowRange() {
        let result = ScanResult(type: .link, input: "http://bad.test", riskLevel: .risky, trustScore: -20)
        #expect(result.trustScore == 0)
    }

    @Test func resultSurvivesEncodingRoundTrip() throws {
        let original = ScanResult(type: .qr, input: "https://example.com", riskLevel: .unknown, trustScore: 50)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ScanResult.self, from: data)
        #expect(decoded == original)
    }
}
