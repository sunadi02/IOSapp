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

    @Test func greetingUsesFirstName() {
        #expect(viewModel.greeting(name: "Sunadi Amarasinghe", now: now) == "Good morning, Sunadi")
    }
}
