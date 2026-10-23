//
//  RiskStyle.swift
//  ScamShield
//
//  Created by student2 on 2026-10-23.
//

import SwiftUI

extension RiskLevel {

    var title: String {
        switch self {
        case .safe: "Safe"
        case .risky: "Risky"
        case .unknown: "Unknown"
        }
    }

    var systemImage: String {
        switch self {
        case .safe: "checkmark.shield.fill"
        case .risky: "xmark.shield.fill"
        case .unknown: "exclamationmark.shield.fill"
        }
    }

    var color: Color {
        switch self {
        case .safe: .green
        case .risky: .red
        case .unknown: .orange
        }
    }

    var advice: String {
        switch self {
        case .safe: "No known threats were found. Still be careful before sharing personal details."
        case .risky: "Do not open this or reply. Never share OTPs, PINs or passwords with anyone."
        case .unknown: "We could not confirm this is safe. Only continue if you fully trust the sender."
        }
    }
}

extension ScanType {

    var title: String {
        switch self {
        case .link: "Link"
        case .qr: "QR Code"
        case .screenshot: "Screenshot"
        }
    }

    var systemImage: String {
        switch self {
        case .link: "link"
        case .qr: "qrcode"
        case .screenshot: "text.viewfinder"
        }
    }
}

extension ScanResult {
    var shareText: String {
        "ScamShield checked \(input)\nResult: \(riskLevel.title) (trust score \(trustScore)/100)"
    }
}

//icon and text together so the level is not shown by colour alone
struct RiskBadge: View {
    let level: RiskLevel

    var body: some View {
        Label(level.title, systemImage: level.systemImage)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(level.color)
            .background(level.color.opacity(0.15), in: Capsule())
            .accessibilityLabel("Risk level \(level.title)")
    }
}

struct TrustScoreRing: View {
    let score: Int
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 10)
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.title.bold())
                Text("/ 100")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 96, height: 96)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Trust score \(score) out of 100")
    }
}
