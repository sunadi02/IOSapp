//
//  SettingsViewModelTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-24.
//

import Testing
import Foundation
@testable import ScamShield

@MainActor
struct SettingsViewModelTests {

    let history = CoreDataHistoryRepository(context: PersistenceController(inMemory: true).viewContext)

    @Test func clearingHistoryRemovesEveryScan() throws {
        try history.save(ScanResult(type: .link, input: "a.com", riskLevel: .safe, trustScore: 90))
        try history.save(ScanResult(type: .qr, input: "b.com", riskLevel: .risky, trustScore: 10))
        let viewModel = SettingsViewModel(history: history)

        viewModel.clearHistory()
        #expect(try history.fetchAll().isEmpty)
        #expect(viewModel.statusMessage != nil)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func clearingEmptyHistoryStillSucceeds() {
        let viewModel = SettingsViewModel(history: history)
        viewModel.clearHistory()
        #expect(viewModel.statusMessage != nil)
    }

    @Test func failedClearShowsErrorOnly() {
        let viewModel = SettingsViewModel(history: FailingHistoryStore())
        viewModel.clearHistory()
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.statusMessage == nil)
    }

    @Test func versionShowsVersionAndBuild() {
        let info: [String: Any] = ["CFBundleShortVersionString": "2.1", "CFBundleVersion": "7"]
        let viewModel = SettingsViewModel(history: history, appInfo: info)
        #expect(viewModel.versionText == "2.1 (7)")
    }

    @Test func versionFallsBackWhenInfoIsMissing() {
        let viewModel = SettingsViewModel(history: history, appInfo: nil)
        #expect(viewModel.versionText == "1.0 (1)")
    }

    @Test func settingsKeysAreUnique() {
        let keys = [AppSettings.hasSeenOnboarding, AppSettings.appLockEnabled, AppSettings.alertsEnabled]
        #expect(Set(keys).count == keys.count)
    }
}
