//
//  OfflineBanner.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import SwiftUI

struct OfflineBanner: View {

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.title3)
                .foregroundStyle(.orange)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("You are offline")
                    .font(.subheadline.bold())
                Text("Links are checked with on-device rules only. Your history syncs when you are back online.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.85))
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.white)
        .background(Color.brandNavy.opacity(0.85))
        .background(.thinMaterial)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(height: 0.5)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    OfflineBanner()
}
