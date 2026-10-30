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
                    .font(.body.weight(.semibold))
                    .foregroundStyle(scan.riskLevel.color)
                    .frame(width: 36, height: 36)
                    .background(scan.riskLevel.color.opacity(0.15), in: Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(scan.input)
                        .font(scan.isDeviceOnly ? .subheadline : .subheadline.monospaced().weight(.semibold))
                        .lineLimit(isLargeText ? 3 : 1)
                        .truncationMode(.middle)
                    Text(scan.date, style: .relative)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if scan.isDeviceOnly {
                        DeviceOnlyLabel()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            RiskBadge(level: scan.riskLevel)
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        let base = "\(scan.accessibilityDescription), \(scan.date.formatted(.relative(presentation: .numeric, unitsStyle: .wide)))"
        return scan.isDeviceOnly ? "\(base), \(DeviceOnlyLabel.text)" : base
    }
}

struct DeviceOnlyLabel: View {
    static let text = "Saved on this device only"

    var body: some View {
        Label(Self.text, systemImage: "iphone")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}

extension ScanResult {
    var isDeviceOnly: Bool {
        type == .screenshot
    }
}
