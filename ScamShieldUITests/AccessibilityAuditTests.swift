//
//  AccessibilityAuditTests.swift
//  ScamShieldUITests
//
//  Created by student2 on 2026-10-24.
//

import XCTest

//Apple's built in accessibility audit checks labels, text clipping, touch target sizes, contrast and Dynamic Type on the screen that is showing
final class AccessibilityAuditTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testOnboardingPassesTheAccessibilityAudit() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-hasSeenOnboarding", "NO"]
        app.launch()

        try app.performAccessibilityAudit()
    }

    //shows the sign in screen when signed out and the dashboard when a session already exists
    @MainActor
    func testFirstScreenAfterOnboardingPassesTheAccessibilityAudit() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-hasSeenOnboarding", "YES"]
        app.launch()

        try app.performAccessibilityAudit()
    }

    @MainActor
    func testOnboardingStillWorksAtTheLargestAccessibilityTextSize() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-hasSeenOnboarding", "NO",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ]
        app.launch()

        XCTAssertTrue(app.buttons["Next"].waitForExistence(timeout: 5))
    }
}
