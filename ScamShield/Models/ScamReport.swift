//
//  ScamReport.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import Foundation

enum ScamCategory: String, Codable, CaseIterable, Identifiable {
    case bankImpersonation
    case otpRequest
    case prizeOrLottery
    case deliveryFee
    case jobOffer
    case other

    var id: String { rawValue }
}

//what other users see in the feed, only the website and never who reported it
struct ScamReport: Identifiable, Equatable {
    let id: String
    let domain: String
    let type: ScanType
    let category: ScamCategory
    let createdAt: Date
}
