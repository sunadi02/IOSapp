//
//  ScanResult.swift
//  ScamShield
//
//  Created by student2 on 2026-10-21.
//

import Foundation

//full outcome of one scan and uses for history
struct ScanResult: Codable, Hashable, Identifiable {
    let id: UUID
    let type: ScanType
    let input: String
    let riskLevel: RiskLevel
    let trustScore: Int
    let signals: [RiskSignal]
    let date: Date

    init(
        id: UUID = UUID(),
        type: ScanType,
        input: String,
        riskLevel: RiskLevel,
        trustScore: Int,
        signals: [RiskSignal] = [],
        date: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.input = input
        self.riskLevel = riskLevel
        self.trustScore = min(max(trustScore, 0), 100)
        self.signals = signals
        self.date = date
    }
}
