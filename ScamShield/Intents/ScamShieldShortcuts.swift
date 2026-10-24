//
//  ScamShieldShortcuts.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import AppIntents

//the phrases that work with Siri straight after install, with no setup in the Shortcuts app
struct ScamShieldShortcuts: AppShortcutsProvider {

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CheckLinkIntent(),
            phrases: [
                "Check a link with \(.applicationName)",
                "Is this link safe in \(.applicationName)",
                "Scan a link with \(.applicationName)"
            ],
            shortTitle: "Check a Link",
            systemImageName: "link"
        )

        AppShortcut(
            intent: LastScanIntent(),
            phrases: [
                "What was my last scan in \(.applicationName)",
                "Show my last result in \(.applicationName)"
            ],
            shortTitle: "Last Scan",
            systemImageName: "clock"
        )
    }
}
