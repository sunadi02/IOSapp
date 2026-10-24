//
//  HighlightedMessage.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import SwiftUI

//shows a scanned message with the suspicious wording in red and underlined
struct HighlightedMessage: View {

    let text: String

    private var attributed: AttributedString {
        var result = AttributedString(text)

        for range in MessageAnalyzer().analyze(text).highlights {
            guard let target = Range(range, in: result) else { continue }
            result[target].foregroundColor = .red
            result[target].underlineStyle = .single
        }
        return result
    }

    var body: some View {
        Text(attributed)
            .textSelection(.enabled)
            .accessibilityHint("Suspicious wording is underlined")
    }
}

#Preview {
    List {
        HighlightedMessage(text: "Your account is suspended. Verify your details immediately at http://combank-secure.xyz")
    }
}
