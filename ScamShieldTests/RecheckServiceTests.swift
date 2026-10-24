//
//  RecheckServiceTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-24.
//

import Testing
import Foundation
@testable import ScamShield

@MainActor
struct RecheckServiceTests {

    let history = CoreDataHistoryRepository(context: PersistenceController(inMemory: true).viewContext)
    let reputation = StubReputationChecker()
    let notifier = MockNotifier()
    let defaults = UserDefaults(suiteName: "RecheckServiceTests-\(UUID().uuidString)")!
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    private var service: RecheckService {
        RecheckService(reputation: reputation, history: history, notifications: notifier, defaults: defaults)
    }

    @discardableResult
    private func save(
        _ input: String,
        type: ScanType = .link,
        level: RiskLevel = .safe,
        daysAgo: Double = 1
    ) throws -> ScanResult {
        let scan = ScanResult(
            type: type,
            input: input,
            riskLevel: level,
            trustScore: 100,
            date: now.addingTimeInterval(-daysAgo * 86_400)
        )
        try history.save(scan)
        return scan
    }

    @Test func linkReportedLaterBecomesRiskyAndTriggersAlert() async throws {
        let scan = try save("https://bad.example.com")
        reputation.threatsByHost = ["bad.example.com": ["SOCIAL_ENGINEERING"]]

        let flagged = await service.run(now: now)
        #expect(flagged == 1)

        let saved = try history.fetchAll()
        let updated = try #require(saved.first)
        #expect(updated.id == scan.id)
        #expect(updated.riskLevel == .risky)
        #expect(updated.trustScore == 0)
        #expect(updated.signals.first?.title == RecheckService.laterReportedTitle)
        #expect(updated.signals.first?.detail.contains("phishing") == true)
        #expect(notifier.alerts.map(\.id) == [scan.id])
    }

    @Test func cleanLinksAreLeftAloneWithoutAlert() async throws {
        let scan = try save("https://fine.example.com")

        let flagged = await service.run(now: now)
        #expect(flagged == 0)
        #expect(try history.fetchAll() == [scan])
        #expect(notifier.alerts.isEmpty)
    }

    @Test func onlyTheReportedLinkIsFlagged() async throws {
        try save("https://fine.example.com")
        try save("https://bad.example.com")
        reputation.threatsByHost = ["bad.example.com": ["MALWARE"]]

        #expect(await service.run(now: now) == 1)
        #expect(notifier.alerts.map(\.input) == ["https://bad.example.com"])
    }

    @Test func alreadyRiskyScansAreNotCheckedAgain() async throws {
        try save("https://bad.example.com", level: .risky)
        reputation.threatsByHost = ["bad.example.com": ["MALWARE"]]

        #expect(await service.run(now: now) == 0)
        #expect(reputation.checkedURLs.isEmpty)
        #expect(notifier.alerts.isEmpty)
    }

    @Test func eachScanOnlyAlertsOnce() async throws {
        try save("https://bad.example.com")
        reputation.threatsByHost = ["bad.example.com": ["MALWARE"]]

        #expect(await service.run(force: true, now: now) == 1)
        #expect(await service.run(force: true, now: now) == 0)
        #expect(notifier.alerts.count == 1)
    }

    @Test func screenshotScansAreIgnored() async throws {
        try save("pretend message text", type: .screenshot)
        await service.run(now: now)
        #expect(reputation.checkedURLs.isEmpty)
    }

    @Test func qrResultsThatAreNotWebLinksAreIgnored() async throws {
        try save("Table12", type: .qr)
        try save("Wi-Fi network: Cafe", type: .qr)
        await service.run(now: now)
        #expect(reputation.checkedURLs.isEmpty)
    }

    @Test func scansOlderThanThirtyDaysAreIgnored() async throws {
        try save("https://old.example.com", daysAgo: 45)
        await service.run(now: now)
        #expect(reputation.checkedURLs.isEmpty)
    }

    @Test func secondRunWithinSixHoursIsSkipped() async throws {
        try save("https://a.example.com")

        await service.run(now: now)
        await service.run(now: now.addingTimeInterval(3_600))
        #expect(reputation.checkedURLs.count == 1)

        await service.run(now: now.addingTimeInterval(7 * 3_600))
        #expect(reputation.checkedURLs.count == 2)
    }

    @Test func forceIgnoresTheTimeLimit() async throws {
        try save("https://a.example.com")

        await service.run(now: now)
        await service.run(force: true, now: now.addingTimeInterval(60))
        #expect(reputation.checkedURLs.count == 2)
    }

    @Test func turningAlertsOffSkipsEverything() async throws {
        defaults.set(false, forKey: AppSettings.alertsEnabled)
        try save("https://bad.example.com")
        reputation.threatsByHost = ["bad.example.com": ["MALWARE"]]

        #expect(await service.run(force: true, now: now) == 0)
        #expect(reputation.checkedURLs.isEmpty)
    }

    @Test func offlineRunDoesNotStartTheWait() async throws {
        try save("https://a.example.com")
        reputation.error = URLError(.notConnectedToInternet)

        #expect(await service.run(now: now) == 0)
        #expect(defaults.object(forKey: RecheckService.lastRunKey) == nil)

        await service.run(now: now.addingTimeInterval(60))
        #expect(reputation.checkedURLs.count == 2)
    }

    @Test func flaggingKeepsOlderSignalsAndSortsByWeight() {
        let old = RiskSignal(title: "Not encrypted", detail: "Uses http", weight: 15)
        let scan = ScanResult(type: .link, input: "http://a.com", riskLevel: .unknown, trustScore: 85, signals: [old])

        let updated = RecheckService.flagged(scan, threats: ["MALWARE", "SOCIAL_ENGINEERING"])
        #expect(updated.signals.map(\.title) == [RecheckService.laterReportedTitle, "Not encrypted"])
        #expect(updated.signals.first?.detail.contains("malware and phishing") == true)
        #expect(updated.riskLevel == .risky)
        #expect(updated.date == scan.date)
    }
}
