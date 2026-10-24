//
//  ResultMotion.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import Foundation

//how the result screen moves, kept apart from the views so the rules can be tested
enum ResultMotion {

    //with Reduce Motion on the ring is already full, so nothing sweeps across the screen
    static func startingScore(for score: Int, reduceMotion: Bool) -> Int {
        reduceMotion ? score : 0
    }

    //a higher score takes a little longer to fill, between half a second and 1.1 seconds
    static func duration(forScore score: Int) -> Double {
        0.5 + 0.6 * Double(min(max(score, 0), 100)) / 100
    }
}

//a different feel for each verdict so it can be read without looking
enum ResultHaptic: Hashable {
    case success
    case warning
    case error
}

extension RiskLevel {

    var haptic: ResultHaptic {
        switch self {
        case .safe: .success
        case .unknown: .warning
        case .risky: .error
        }
    }
}
