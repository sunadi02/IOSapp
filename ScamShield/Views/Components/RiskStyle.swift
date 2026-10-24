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
    //a message is private so sharing a result only mentions that a message was checked
    var shareText: String {
        let subject = type == .screenshot ? "a message" : input
        return "ScamShield checked \(subject)\nResult: \(riskLevel.title) (trust score \(trustScore)/100)"
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

extension ResultHaptic {

    var feedback: SensoryFeedback {
        switch self {
        case .success: .success
        case .warning: .warning
        case .error: .error
        }
    }
}

//fills up and counts to the score when it appears, VoiceOver always hears the final score
struct TrustScoreRing: View {
    let score: Int
    let color: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shownScore: Int?

    private var displayedScore: Int {
        shownScore ?? ResultMotion.startingScore(for: score, reduceMotion: reduceMotion)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 10)
            Circle()
                .trim(from: 0, to: CGFloat(displayedScore) / 100)
                .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(displayedScore)")
                    .font(.title.bold())
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(displayedScore)))
                Text("/ 100")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 96, height: 96)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Trust score \(score) out of 100")
        .onAppear { reveal(score) }
        .onChange(of: score) { _, newScore in reveal(newScore) }
    }

    private func reveal(_ target: Int) {
        if reduceMotion {
            shownScore = target
        } else {
            withAnimation(.easeOut(duration: ResultMotion.duration(forScore: target))) {
                shownScore = target
            }
        }
    }
}
