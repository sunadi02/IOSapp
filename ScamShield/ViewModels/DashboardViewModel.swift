//
//  DashboardViewModel.swift
//  ScamShield
//
//  Created by student2 on 2026-10-23.
//

import Foundation
import Observation

//how many scans of one verdict were made on one day
struct DayRiskCount: Identifiable, Equatable {
    let day: Date
    let level: RiskLevel
    let count: Int

    var id: String { "\(day.timeIntervalSinceReferenceDate)-\(level.rawValue)" }
}

@Observable
final class DashboardViewModel {

    static let recentLimit = 5
    static let weekLength = 7

    private(set) var scansToday = 0
    private(set) var riskyToday = 0
    private(set) var totalScans = 0
    private(set) var recentScans: [ScanResult] = []
    private(set) var weeklyBreakdown: [DayRiskCount] = []
    private(set) var loadError: String?

    private let history: HistoryStoring
    private let calendar: Calendar

    init(history: HistoryStoring = AppHistory.store, calendar: Calendar = .current) {
        self.history = history
        self.calendar = calendar
    }

    //works out today's stats from the saved history
    func load(now: Date = Date()) {
        do {
            let all = try history.fetchAll()
            let today = all.filter { calendar.isDate($0.date, inSameDayAs: now) }

            scansToday = today.count
            riskyToday = today.filter { $0.riskLevel == .risky }.count
            totalScans = all.count
            recentScans = Array(all.prefix(Self.recentLimit))
            weeklyBreakdown = Self.weeklyBreakdown(from: all, now: now, calendar: calendar)
            loadError = nil
        } catch {
            loadError = "Could not load your scan history."
        }
    }

    var weeklyTotal: Int {
        weeklyBreakdown.reduce(0) { $0 + $1.count }
    }

    //the same facts as the chart in words, read out by VoiceOver
    var weeklySummary: String {
        guard weeklyTotal > 0 else { return "No scans in the last \(Self.weekLength) days." }

        let parts = RiskLevel.allCases.map { level in
            let count = weeklyBreakdown.filter { $0.level == level }.reduce(0) { $0 + $1.count }
            return "\(count) \(level.rawValue)"
        }
        let noun = weeklyTotal == 1 ? "scan" : "scans"
        return "\(weeklyTotal) \(noun) in the last \(Self.weekLength) days: \(parts.joined(separator: ", "))."
    }

    //every one of the last seven days gets an entry for every verdict, even when it is zero, so the chart shows the whole week
    static func weeklyBreakdown(from scans: [ScanResult], now: Date, calendar: Calendar) -> [DayRiskCount] {
        let today = calendar.startOfDay(for: now)
        let days = (0..<weekLength).compactMap { offset in
            calendar.date(byAdding: .day, value: -(weekLength - 1 - offset), to: today)
        }

        return days.flatMap { day in
            RiskLevel.allCases.map { level in
                let count = scans.filter { $0.riskLevel == level && calendar.isDate($0.date, inSameDayAs: day) }.count
                return DayRiskCount(day: day, level: level, count: count)
            }
        }
    }

    func greeting(name: String?, now: Date = Date()) -> String {
        let hour = calendar.component(.hour, from: now)
        let part = switch hour {
        case 5..<12: "Good morning"
        case 12..<17: "Good afternoon"
        default: "Good evening"
        }

        guard let firstName = name?.split(separator: " ").first else { return part }
        return "\(part), \(firstName)"
    }
}
