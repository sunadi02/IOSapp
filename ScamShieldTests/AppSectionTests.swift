//
//  AppSectionTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-24.
//

import Testing
import Foundation
@testable import ScamShield

@MainActor
struct AppSectionTests {

    @Test func everySectionHasItsOwnTitleAndIcon() {
        let sections = AppSection.allCases

        #expect(Set(sections.map(\.title)).count == sections.count)
        #expect(Set(sections.map(\.systemImage)).count == sections.count)
        #expect(sections.allSatisfy { !$0.title.isEmpty && !$0.systemImage.isEmpty })
    }

    @Test func idsAreUnique() {
        let ids = AppSection.allCases.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test(arguments: [
        (AppSection.home, AppSection.home),
        (AppSection.checkLink, AppSection.home),
        (AppSection.scanQR, AppSection.home),
        (AppSection.scanScreenshot, AppSection.home),
        (AppSection.history, AppSection.history),
        (AppSection.community, AppSection.community),
        (AppSection.settings, AppSection.settings)
    ])
    func scanScreensShareTheHomeTabOnAPhone(section: AppSection, expected: AppSection) {
        #expect(section.compactTab == expected)
    }

    @Test func aPhoneHasExactlyFourTabs() {
        let tabs = Set(AppSection.allCases.map(\.compactTab))
        #expect(tabs == [.home, .history, .community, .settings])
    }

    @Test func tabSectionsMapToThemselves() {
        for section in [AppSection.home, .history, .community, .settings] {
            #expect(section.compactTab == section)
        }
    }
}
