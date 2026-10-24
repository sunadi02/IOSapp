//
//  ScanRow.swift
//  ScamShield
//
//  Created by student2 on 2026-10-23.
//

import SwiftUI

struct ScanRow: View {
    let scan: ScanResult

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var isLargeText: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    //at the biggest text sizes the badge drops under the text instead of squeezing it
    private var layout: AnyLayout {
        isLargeText
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 12))
    }

    var body: some View {
        layout {
            HStack(spacing: 12) {
                Image(systemName: scan.type.systemImage)
                    .font(.title3)
                    .foregroundStyle(.tint)
                    .frame(width: 32)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(scan.input)
                        .font(.subheadline)
                        .lineLimit(isLargeText ? 3 : 1)
                        .truncationMode(.middle)
                    Text(scan.date, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            RiskBadge(level: scan.riskLevel)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(scan.accessibilityDescription), \(scan.date.formatted(.relative(presentation: .numeric, unitsStyle: .wide)))")
    }
}
