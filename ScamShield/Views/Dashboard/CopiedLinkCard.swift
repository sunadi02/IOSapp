//
//  CopiedLinkCard.swift
//  ScamShield
//
//  Created by student2 on 2026-10-25.
//

import SwiftUI

//the system paste button reads the clipboard only when tapped, so no permission prompt is shown
struct CopiedLinkCard: View {

    let onPaste: (String) -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("You copied a link", systemImage: "doc.on.clipboard")
                .font(.headline)

            Text("Check it before you open it. ScamShield only reads it when you tap Paste.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                PasteButton(payloadType: String.self) { strings in
                    let link = (strings.first ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !link.isEmpty else { return }
                    onPaste(link)
                }
                .labelStyle(.titleAndIcon)
                .buttonBorderShape(.capsule)

                Spacer()

                Button("Not Now", action: onDismiss)
                    .font(.subheadline)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    CopiedLinkCard(onPaste: { _ in }, onDismiss: {})
        .padding()
}
