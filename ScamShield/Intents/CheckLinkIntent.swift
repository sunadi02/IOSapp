//
//  CheckLinkIntent.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import AppIntents
import SwiftUI

enum CheckLinkIntentError: Error, CustomLocalizedStringResourceConvertible {
    case invalidLink

    var localizedStringResource: LocalizedStringResource {
        "That does not look like a web link. Try something like example.com."
    }
}

//lets Siri and the Shortcuts app check a link without opening ScamShield
struct CheckLinkIntent: AppIntent {

    static let title: LocalizedStringResource = "Check a Link"
    static let description = IntentDescription(
        "Checks a link for scams and tells you whether it looks safe.",
        categoryName: "Safety"
    )

    @Parameter(title: "Link", requestValueDialog: "Which link should I check?")
    var link: String

    static var parameterSummary: some ParameterSummary {
        Summary("Check \(\.$link) for scams")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog & ShowsSnippetView {
        let result: ScanResult

        do {
            result = try await IntentLinkChecker().check(link)
        } catch LinkScanError.invalidLink {
            throw CheckLinkIntentError.invalidLink
        }

        let sentence = LinkVerdictSummary.checkSentence(for: result)
        return .result(value: result.riskLevel.title, dialog: "\(sentence)", view: VerdictSnippet(result: result))
    }
}

//the small card shown with Siri's answer
struct VerdictSnippet: View {

    let result: ScanResult

    private var mainReason: String? {
        guard let top = result.signals.max(by: { $0.weight < $1.weight }), top.weight > 0 else { return nil }
        return top.title
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: result.riskLevel.systemImage)
                .font(.largeTitle)
                .foregroundStyle(result.riskLevel.color)

            VStack(alignment: .leading, spacing: 2) {
                Text(result.riskLevel.title)
                    .font(.headline)
                Text("Trust score \(result.trustScore) of 100")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let mainReason {
                    Text(mainReason)
                        .font(.caption)
                }
            }

            Spacer()
        }
        .padding()
    }
}
