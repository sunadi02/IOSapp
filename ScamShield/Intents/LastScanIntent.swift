//
//  LastScanIntent.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import AppIntents

//answers "how did my last scan go" from the saved history
struct LastScanIntent: AppIntent {

    static let title: LocalizedStringResource = "Last Scan Result"
    static let description = IntentDescription(
        "Tells you how your most recent scan turned out.",
        categoryName: "Safety"
    )

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        guard let latest = (try? IntentServices.history.fetchAll())?.first else {
            return .result(value: "None", dialog: "You have not scanned anything yet.")
        }

        let sentence = LinkVerdictSummary.lastScanSentence(for: latest)
        return .result(value: latest.riskLevel.title, dialog: "\(sentence)")
    }
}
