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

    //the scan shown beside the list when the screen is wide enough for two panes
    var selectedScanID: UUID?

    private(set) var scans: [ScanResult] = []
    private(set) var errorMessage: String?

    private let history: HistoryStoring
    private let calendar: Calendar

    init(history: HistoryStoring = AppHistory.store, calendar: Calendar = .current) {
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

    var selectedScan: ScanResult? {
        guard let selectedScanID else { return nil }
        return scans.first { $0.id == selectedScanID }
    }

    //the last deletion, kept for a few seconds so it can be undone
    private(set) var undoableScans: [ScanResult] = []

    //changes with every deletion so an old timer cannot hide a newer undo offer
    private(set) var undoGeneration = 0

    var undoMessage: String? {
        switch undoableScans.count {
        case 0: nil
        case 1: "Scan deleted"
        default: "\(undoableScans.count) scans deleted"
        }
    }

    func load() {
        do {
            scans = try history.fetchAll()
            dropMissingSelection()
            errorMessage = nil
        } catch {
            errorMessage = "Could not load your scan history."
        }
    }

    func delete(id: UUID) {
        let removed = scans.filter { $0.id == id }

        do {
            try history.delete(id: id)
            scans.removeAll { $0.id == id }
            dropMissingSelection()
            errorMessage = nil
            offerUndo(for: removed)
        } catch {
            errorMessage = "Could not delete that scan."
        }
    }

    func deleteAll() {
        let removed = scans

        do {
            try history.deleteAll()
            scans = []
            dropMissingSelection()
            errorMessage = nil
            offerUndo(for: removed)
        } catch {
            errorMessage = "Could not clear your scan history."
        }
    }

    //saving again also puts the scans back in the cloud and in search
    func undoDelete() {
        guard !undoableScans.isEmpty else { return }

        do {
            for scan in undoableScans {
                try history.save(scan)
            }
            let restoredIDs = Set(undoableScans.map(\.id))
            scans = (scans.filter { !restoredIDs.contains($0.id) } + undoableScans).sorted { $0.date > $1.date }
            undoableScans = []
            errorMessage = nil
        } catch {
            errorMessage = "Could not bring back the deleted scan."
        }
    }

    func expireUndo(generation: Int) {
        guard generation == undoGeneration else { return }
        undoableScans = []
    }

    private func offerUndo(for removed: [ScanResult]) {
        guard !removed.isEmpty else { return }
        undoableScans = removed
        undoGeneration += 1
    }

    private func dropMissingSelection() {
        if let selectedScanID, !scans.contains(where: { $0.id == selectedScanID }) {
            self.selectedScanID = nil
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
