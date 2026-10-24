//
//  AppCommands.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import SwiftUI

//keyboard shortcuts for iPad, they appear when the command key is held down
struct AppCommands: Commands {

    @FocusedBinding(\.appSection) private var section

    var body: some Commands {
        CommandMenu("Go") {
            shortcut("Home", to: .home, key: "1")
            shortcut("Check a Link", to: .checkLink, key: "l")
            shortcut("Scan QR Code", to: .scanQR, key: "q", modifiers: [.command, .shift])
            shortcut("Scan a Screenshot", to: .scanScreenshot, key: "s", modifiers: [.command, .shift])

            Divider()

            shortcut("History", to: .history, key: "2")
            shortcut("Find in History", to: .history, key: "f")
            shortcut("Community", to: .community, key: "3")
            shortcut("Settings", to: .settings, key: ",")
        }
    }

    private func shortcut(
        _ title: String,
        to target: AppSection,
        key: KeyEquivalent,
        modifiers: EventModifiers = .command
    ) -> some View {
        Button(title) { section = target }
            .keyboardShortcut(key, modifiers: modifiers)
            .disabled(section == nil)
    }
}
