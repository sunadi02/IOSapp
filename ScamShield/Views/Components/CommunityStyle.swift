//
//  CommunityStyle.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import Foundation

extension ScamCategory {

    var title: String {
        switch self {
        case .bankImpersonation: "Fake bank"
        case .otpRequest: "OTP request"
        case .prizeOrLottery: "Prize or lottery"
        case .deliveryFee: "Delivery fee"
        case .jobOffer: "Job offer"
        case .other: "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .bankImpersonation: "building.columns.fill"
        case .otpRequest: "number.square.fill"
        case .prizeOrLottery: "gift.fill"
        case .deliveryFee: "shippingbox.fill"
        case .jobOffer: "briefcase.fill"
        case .other: "questionmark.circle.fill"
        }
    }
}
