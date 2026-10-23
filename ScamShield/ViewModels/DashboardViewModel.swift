//
//  DashboardViewModel.swift
//  ScamShield
//
//  Created by student2 on 2026-10-23.
//

import Foundation
import Observation

@Observable
final class DashboardViewModel {

    static let recentLimit = 5

    private(set) var scansToday = 0
    private(set) var riskyToday = 0
    private(set) var totalScans = 0
    private(set) var recentScans: [ScanResult] = []
    private(set) var loadError: String?

    private let history: HistoryStoring
    private let calendar: Calendar

    init(history: HistoryStoring = CoreDataHistoryRepository(), calendar: Calendar = .current) {
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
            loadError = nil
        } catch {
            loadError = "Could not load your scan history."
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
