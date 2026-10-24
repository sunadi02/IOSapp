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
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("You are offline")
                    .font(.subheadline.bold())
                Text("Links are checked with on-device rules only. Your history syncs when you are back online.")
                    .font(.caption)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.22))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    OfflineBanner()
}
