//
//  DashboardViewModelTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-23.
//

import Testing
import Foundation
@testable import ScamShield

@MainActor
struct DashboardViewModelTests {

    let history = CoreDataHistoryRepository(context: PersistenceController(inMemory: true).viewContext)
    let viewModel: DashboardViewModel

    //fixed calendar and time so results do not depend on when the test runs
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Colombo")!
        return calendar
    }()
    let now: Date

    init() {
        now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 23, hour: 10))!
        viewModel = DashboardViewModel(history: history, calendar: calendar)
    }

    private func save(_ level: RiskLevel, hoursAgo: Double) throws {
        try history.save(ScanResult(type: .link, input: "x.com", riskLevel: level, trustScore: 50, date: now.addingTimeInterval(-hoursAgo * 3600)))
    }

    @Test func emptyHistoryShowsZeros() {
        viewModel.load(now: now)
        #expect(viewModel.scansToday == 0)
        #expect(viewModel.totalScans == 0)
        #expect(viewModel.recentScans.isEmpty)
    }

    @Test func onlyTodaysScansCountAsToday() throws {
        try save(.safe, hoursAgo: 1)
        try save(.risky, hoursAgo: 2)
        try save(.risky, hoursAgo: 30)
        viewModel.load(now: now)

        #expect(viewModel.scansToday == 2)
        #expect(viewModel.riskyToday == 1)
        #expect(viewModel.totalScans == 3)
    }

    @Test func recentScansAreLimitedAndNewestFirst() throws {
        for hour in 1...8 {
            try save(.safe, hoursAgo: Double(hour))
        }
        viewModel.load(now: now)

        #expect(viewModel.recentScans.count == DashboardViewModel.recentLimit)
        #expect(viewModel.recentScans.first?.date == now.addingTimeInterval(-3600))
    }

    @Test(arguments: [(8, "Good morning"), (14, "Good afternoon"), (21, "Good evening"), (2, "Good evening")])
    func greetingDependsOnTime(hour: Int, expected: String) {
        let time = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: now)!
        #expect(viewModel.greeting(name: nil, now: time) == expected)
    }

    private func count(_ level: RiskLevel, daysAgo: Int) -> Int? {
        guard let day = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { return nil }
        return viewModel.weeklyBreakdown
            .first { $0.level == level && calendar.isDate($0.day, inSameDayAs: day) }?
            .count
    }

    @Test func weekHasAnEntryForEveryDayAndVerdict() {
        viewModel.load(now: now)
        #expect(viewModel.weeklyBreakdown.count == DashboardViewModel.weekLength * RiskLevel.allCases.count)
    }

    @Test func weekRunsOldestDayFirstAndEndsToday() throws {
        viewModel.load(now: now)
        let days = viewModel.weeklyBreakdown.map(\.day)

        let first = try #require(days.first)
        let last = try #require(days.last)
        let sixDaysAgo = try #require(calendar.date(byAdding: .day, value: -6, to: now))

        #expect(days == days.sorted())
        #expect(calendar.isDate(last, inSameDayAs: now))
        #expect(calendar.isDate(first, inSameDayAs: sixDaysAgo))
    }

    @Test func emptyHistoryGivesAFlatWeek() {
        viewModel.load(now: now)
        #expect(viewModel.weeklyTotal == 0)
        #expect(viewModel.weeklyBreakdown.allSatisfy { $0.count == 0 })
    }

    @Test func scansLandOnTheirOwnDayAndVerdict() throws {
        try save(.safe, hoursAgo: 1)
        try save(.safe, hoursAgo: 2)
        try save(.risky, hoursAgo: 3)
        try save(.unknown, hoursAgo: 30)
        try save(.risky, hoursAgo: 72)
        viewModel.load(now: now)

        #expect(count(.safe, daysAgo: 0) == 2)
        #expect(count(.risky, daysAgo: 0) == 1)
        #expect(count(.unknown, daysAgo: 1) == 1)
        #expect(count(.risky, daysAgo: 3) == 1)
        #expect(count(.safe, daysAgo: 1) == 0)
        #expect(viewModel.weeklyTotal == 5)
    }

    @Test func scansOlderThanTheWeekAreLeftOut() throws {
        try save(.safe, hoursAgo: 24 * 6)
        try save(.safe, hoursAgo: 24 * 7)
        viewModel.load(now: now)

        #expect(viewModel.weeklyTotal == 1)
        #expect(count(.safe, daysAgo: 6) == 1)
    }

    @Test func summaryDescribesTheWeekInWords() throws {
        try save(.safe, hoursAgo: 1)
        try save(.safe, hoursAgo: 2)
        try save(.risky, hoursAgo: 3)
        viewModel.load(now: now)

        #expect(viewModel.weeklySummary == "3 scans in the last 7 days: 2 safe, 1 risky, 0 unknown.")
    }

    @Test func summaryUsesTheSingularForOneScan() throws {
        try save(.safe, hoursAgo: 1)
        viewModel.load(now: now)

        #expect(viewModel.weeklySummary == "1 scan in the last 7 days: 1 safe, 0 risky, 0 unknown.")
    }

    @Test func summaryForAnEmptyWeekSaysSo() {
        viewModel.load(now: now)
        #expect(viewModel.weeklySummary == "No scans in the last 7 days.")
    }

    @Test func eachChartEntryHasItsOwnID() {
        viewModel.load(now: now)
        let ids = viewModel.weeklyBreakdown.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func greetingUsesFirstName() {
        #expect(viewModel.greeting(name: "Sunadi Amarasinghe", now: now) == "Good morning, Sunadi")
    }
}
