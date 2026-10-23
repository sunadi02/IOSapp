//
//  RiskScorer.swift
//  ScamShield
//
//  Created by student2 on 2026-10-23.
//

import Foundation

//turns a list of signals into a trust score and a risk level
enum RiskScorer {

    static let riskyBelow = 50
    static let safeFrom = 80

    static func trustScore(for signals: [RiskSignal]) -> Int {
        let penalty = signals.reduce(0) { $0 + $1.weight }
        return min(max(100 - penalty, 0), 100)
    }

    //verified is false when the main check could not finish so the result stays unknown
    static func riskLevel(for score: Int, verified: Bool) -> RiskLevel {
        if score < riskyBelow { return .risky }
        if score >= safeFrom && verified { return .safe }
        return .unknown
    }

    static func makeResult(type: ScanType, input: String, signals: [RiskSignal], verified: Bool) -> ScanResult {
        let score = trustScore(for: signals)
        let sorted = signals.sorted { $0.weight > $1.weight }
        return ScanResult(
            type: type,
            input: input,
            riskLevel: riskLevel(for: score, verified: verified),
            trustScore: score,
            signals: sorted
        )
    }
}
