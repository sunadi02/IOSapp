//
//  HistoryViewModel.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import Foundation
import Observation

@Observable
final class HistoryViewModel {

    struct DayGroup: Identifiable, Equatable {
        let day: Date
        let scans: [ScanResult]
        var id: Date { day }
    }

    var searchText = ""
    var typeFilter: ScanType?
    var riskFilter: RiskLevel?

    private(set) var scans: [ScanResult] = []
    private(set) var errorMessage: String?

    private let history: HistoryStoring
    private let calendar: Calendar

    init(history: HistoryStoring = CoreDataHistoryRepository(), calendar: Calendar = .current) {
        self.history = history
        self.calendar = calendar
    }

    private var trimmedSearch: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isFiltering: Bool {
        !trimmedSearch.isEmpty || typeFilter != nil || riskFilter != nil
    }

    var filteredScans: [ScanResult] {
        scans.filter { scan in
            (typeFilter == nil || scan.type == typeFilter)
                && (riskFilter == nil || scan.riskLevel == riskFilter)
                && (trimmedSearch.isEmpty || scan.input.localizedCaseInsensitiveContains(trimmedSearch))
        }
    }

    var groups: [DayGroup] {
        Dictionary(grouping: filteredScans) { calendar.startOfDay(for: $0.date) }
            .map { DayGroup(day: $0.key, scans: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.day > $1.day }
    }

    func load() {
        do {
            scans = try history.fetchAll()
            errorMessage = nil
        } catch {
            errorMessage = "Could not load your scan history."
        }
    }

    func delete(id: UUID) {
        do {
            try history.delete(id: id)
            scans.removeAll { $0.id == id }
            errorMessage = nil
        } catch {
            errorMessage = "Could not delete that scan."
        }
    }

    func deleteAll() {
        do {
            try history.deleteAll()
            scans = []
            errorMessage = nil
        } catch {
            errorMessage = "Could not clear your scan history."
        }
    }

    func clearFilters() {
        searchText = ""
        typeFilter = nil
        riskFilter = nil
    }

    func title(for day: Date, now: Date = Date()) -> String {
        if calendar.isDate(day, inSameDayAs: now) { return "Today" }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(day, inSameDayAs: yesterday) {
            return "Yesterday"
        }
        return day.formatted(date: .abbreviated, time: .omitted)
    }
}
