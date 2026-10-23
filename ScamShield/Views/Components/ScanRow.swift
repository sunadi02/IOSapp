//
//  ScanRow.swift
//  ScamShield
//
//  Created by student2 on 2026-10-23.
//

import SwiftUI

struct ScanRow: View {
    let scan: ScanResult

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: scan.type.systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(scan.input)
                    .font(.subheadline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(scan.date, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)
            RiskBadge(level: scan.riskLevel)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(scan.type.title) \(scan.input), \(scan.riskLevel.title)")
    }
}
