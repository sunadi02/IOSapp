//
//  QuickActionRouterTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-25.
//

import Testing
import Foundation
@testable import ScamShield

@MainActor
struct QuickActionRouterTests {

    let router = QuickActionRouter()

    @Test(arguments: [
        (QuickAction.checkLink, AppSection.checkLink),
        (QuickAction.scanQR, AppSection.scanQR),
        (QuickAction.scanScreenshot, AppSection.scanScreenshot)
    ])
    func eachQuickActionOpensItsOwnScreen(action: QuickAction, expected: AppSection) {
        #expect(action.section == expected)
    }

    @Test func knownActionIsAcceptedAndRemembered() {
        #expect(router.handle(type: QuickAction.scanQR.rawValue))
        #expect(router.pendingSection == .scanQR)
    }

    @Test(arguments: ["", "com.scamshield.quickaction.unknown", "checkLink"])
    func unknownActionIsRefusedAndChangesNothing(type: String) {
        #expect(!router.handle(type: type))
        #expect(router.pendingSection == nil)
    }

    @Test func laterActionReplacesAnEarlierOne() {
        router.handle(type: QuickAction.checkLink.rawValue)
        router.handle(type: QuickAction.scanScreenshot.rawValue)
        #expect(router.pendingSection == .scanScreenshot)
    }

    @Test func shortcutItemsUseTheScreenNamesAndIcons() {
        for action in QuickAction.allCases {
            let item = action.shortcutItem
            #expect(item.type == action.rawValue)
            #expect(item.localizedTitle == action.section.title)
        }
    }

    @Test func everyQuickActionHasItsOwnType() {
        let types = QuickAction.allCases.map(\.rawValue)
        #expect(Set(types).count == types.count)
    }

    @Test func quickActionsOnlyOpenScanScreensThatLiveUnderHome() {
        #expect(QuickAction.allCases.allSatisfy { $0.section.compactTab == .home && $0.section != .home })
    }
}
