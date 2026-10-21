//
//  RiskSignal.swift
//  ScamShield
//
//  Created by student2 on 2026-10-21.
//

import Foundation

struct RiskSignal: Codable, Hashable, Identifiable {
    let id: UUID
    let title: String
    let detail: String
    let weight: Int

    init(id: UUID = UUID(), title: String, detail: String, weight: Int) {
        self.id = id
        self.title = title
        self.detail = detail
        self.weight = weight
    }
}
