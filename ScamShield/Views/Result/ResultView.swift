//
//  ResultView.swift
//  ScamShield
//
//  Created by student2 on 2026-10-23.
//

import SwiftUI

struct ResultView: View {

    let result: ScanResult

    //only a scan that has just finished vibrates, opening an old one from history stays quiet
    var isNewScan = false

    @AppStorage(AppSettings.hapticsEnabled) private var hapticsEnabled = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isReporting = false
    @State private var feedbackTrigger = 0
    @State private var iconBounce = 0

    private var canReport: Bool {
        result.type != .screenshot && URLAnalyzer.normalize(result.input) != nil
    }

    var body: some View {
        List {
            Section {
                summary
            }

            Section(result.type == .screenshot ? "Message" : "Checked") {
                if result.type == .screenshot {
                    HighlightedMessage(text: result.input)
                } else {
                    Text(result.input)
                        .font(.callout.monospaced())
                        .textSelection(.enabled)
                }
                LabeledContent("Type", value: result.type.title)
                LabeledContent("Date", value: result.date.formatted(date: .abbreviated, time: .shortened))
            }

            Section("Why") {
                if result.signals.isEmpty {
                    Label("No warning signs found", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    ForEach(result.signals) { signal in
                        SignalRow(signal: signal)
                    }
                }
            }

            Section {
                ShareLink(item: result.shareText) {
                    Label("Share Result", systemImage: "square.and.arrow.up")
                }
                Button {
                    UIPasteboard.general.string = result.input
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                if canReport {
                    Button {
                        isReporting = true
                    } label: {
                        Label("Report as Scam", systemImage: "exclamationmark.bubble")
                    }
                }
            }
        }
        .navigationTitle("Result")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isReporting) {
            ReportSheet(scan: result)
        }
        .sensoryFeedback(result.riskLevel.haptic.feedback, trigger: feedbackTrigger)
        .onAppear {
            if isNewScan && hapticsEnabled { feedbackTrigger += 1 }
            if !reduceMotion { iconBounce += 1 }
        }
    }

    private var summary: some View {
        VStack(spacing: 12) {
            TrustScoreRing(score: result.trustScore, color: result.riskLevel.color)

            Label(result.riskLevel.title, systemImage: result.riskLevel.systemImage)
                .font(.title2.bold())
                .foregroundStyle(result.riskLevel.color)
                .symbolEffect(.bounce, value: iconBounce)

            Text(result.riskLevel.advice)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }
}

struct SignalRow: View {
    let signal: RiskSignal

    //stronger signals get a stronger icon and colour
    private var style: (icon: String, color: Color, label: String) {
        switch signal.weight {
        case 25...: ("exclamationmark.octagon.fill", .red, "High risk")
        case 1..<25: ("exclamationmark.triangle.fill", .orange, "Warning")
        default: ("info.circle.fill", .secondary, "Note")
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: style.icon)
                .foregroundStyle(style.color)
                .font(.title3)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(signal.title)
                    .font(.headline)
                Text(signal.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(style.label): \(signal.title). \(signal.detail)")
    }
}

#Preview {
    NavigationStack {
        ResultView(result: ScanResult(
            type: .link,
            input: "https://paypal-secure-check.xyz/login",
            riskLevel: .risky,
            trustScore: 25,
            signals: [
                RiskSignal(title: "Brand impersonation", detail: "Mentions paypal but is not on an official paypal website.", weight: 35),
                RiskSignal(title: "Unusual domain ending", detail: "The .xyz ending is often used by scam websites.", weight: 15)
            ]
        ))
    }
}
