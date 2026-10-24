//
//  QuickActionRouter.swift
//  ScamShield
//
//  Created by student2 on 2026-10-25.
//

import SwiftUI
import UIKit

//the shortcuts shown when the app icon is pressed and held
enum QuickAction: String, CaseIterable {
    case checkLink = "com.scamshield.quickaction.checkLink"
    case scanQR = "com.scamshield.quickaction.scanQR"
    case scanScreenshot = "com.scamshield.quickaction.scanScreenshot"

    var section: AppSection {
        switch self {
        case .checkLink: .checkLink
        case .scanQR: .scanQR
        case .scanScreenshot: .scanScreenshot
        }
    }

    var shortcutItem: UIApplicationShortcutItem {
        UIApplicationShortcutItem(
            type: rawValue,
            localizedTitle: section.title,
            localizedSubtitle: nil,
            icon: UIApplicationShortcutIcon(systemImageName: section.systemImage),
            userInfo: nil
        )
    }
}

//holds the section a quick action asked for until the main screen is ready to show it
//it is shared because the app delegate receives the action before any SwiftUI view exists
@Observable
final class QuickActionRouter {

    static let shared = QuickActionRouter()

    var pendingSection: AppSection?

    @discardableResult
    func handle(type: String) -> Bool {
        guard let action = QuickAction(rawValue: type) else { return false }
        pendingSection = action.section
        return true
    }
}

//moves the main screen to a section asked for by a quick action, used by both the tab bar and the sidebar
struct QuickActionHandler: ViewModifier {

    @Binding var selection: AppSection
    var router = QuickActionRouter.shared

    func body(content: Content) -> some View {
        content
            .onChange(of: router.pendingSection, initial: true) { _, section in
                guard let section else { return }
                selection = section
                router.pendingSection = nil
            }
    }
}

extension View {

    func handlesQuickActions(selection: Binding<AppSection>) -> some View {
        modifier(QuickActionHandler(selection: selection))
    }
}
