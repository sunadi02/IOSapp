//
//  HistoryViewModelTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-24.
//

import Testing
import Foundation
@testable import ScamShield

//deletes like the real store but cannot save, to test a failed undo
struct SaveFailingStore: HistoryStoring {
    struct SaveError: Error {}
    let base: HistoryStoring

    func save(_ result: ScanResult) throws { throw SaveError() }
    func fetchAll() throws -> [ScanResult] { try base.fetchAll() }
    func fetchUnsynced() throws -> [ScanResult] { try base.fetchUnsynced() }
    func markSynced(ids: [UUID]) throws { try base.markSynced(ids: ids) }
    func delete(id: UUID) throws { try base.delete(id: id) }
    func deleteAll() throws { try base.deleteAll() }
}

@MainActor
struct HistoryViewModelTests {

    let history = CoreDataHistoryRepository(context: PersistenceController(inMemory: true).viewContext)
    let viewModel: HistoryViewModel

    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Colombo")!
        return calendar
    }()
    let now: Date

    init() {
        now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 23, hour: 10))!
        viewModel = HistoryViewModel(history: history, calendar: calendar)
    }

    @discardableResult
    private func save(
        _ input: String,
        type: ScanType = .link,
        level: RiskLevel = .safe,
        hoursAgo: Double = 0
    ) throws -> ScanResult {
        let scan = ScanResult(
            type: type,
            input: input,
            riskLevel: level,
            trustScore: 50,
            date: now.addingTimeInterval(-hoursAgo * 3600)
        )
        try history.save(scan)
        return scan
    }

    @Test func loadShowsNewestFirst() throws {
        try save("old.com", hoursAgo: 5)
        try save("new.com", hoursAgo: 1)
        viewModel.load()
        #expect(viewModel.scans.map(\.input) == ["new.com", "old.com"])
    }

    @Test func emptyHistoryHasNoGroupsAndIsNotFiltering() {
        viewModel.load()
        #expect(viewModel.groups.isEmpty)
        #expect(!viewModel.isFiltering)
    }

    @Test func searchIgnoresCase() throws {
        try save("https://PayPal-login.xyz")
        try save("https://apple.com")
        viewModel.load()

        viewModel.searchText = "paypal"
        #expect(viewModel.filteredScans.map(\.input) == ["https://PayPal-login.xyz"])
    }

    @Test(arguments: ["", "   "])
    func blankSearchShowsEverything(_ text: String) throws {
        try save("a.com")
        try save("b.com")
        viewModel.load()

        viewModel.searchText = text
        #expect(viewModel.filteredScans.count == 2)
        #expect(!viewModel.isFiltering)
    }

    @Test func typeFilterKeepsOnlyThatType() throws {
        try save("a.com", type: .link)
        try save("b.com", type: .qr)
        viewModel.load()

        viewModel.typeFilter = .qr
        #expect(viewModel.filteredScans.map(\.input) == ["b.com"])
    }

    @Test func riskFilterKeepsOnlyThatLevel() throws {
        try save("a.com", level: .safe)
        try save("b.com", level: .risky)
        viewModel.load()

        viewModel.riskFilter = .risky
        #expect(viewModel.filteredScans.map(\.input) == ["b.com"])
    }

    @Test func filtersCombine() throws {
        try save("a.com", type: .link, level: .risky)
        try save("b.com", type: .qr, level: .risky)
        try save("c.com", type: .link, level: .safe)
        viewModel.load()

        viewModel.typeFilter = .link
        viewModel.riskFilter = .risky
        #expect(viewModel.filteredScans.map(\.input) == ["a.com"])
        #expect(viewModel.isFiltering)
    }

    @Test func clearFiltersResetsEverything() throws {
        try save("a.com")
        viewModel.load()
        viewModel.searchText = "zzz"
        viewModel.typeFilter = .qr
        viewModel.riskFilter = .risky

        viewModel.clearFilters()
        #expect(!viewModel.isFiltering)
        #expect(viewModel.filteredScans.count == 1)
    }

    @Test func scansAreGroupedByDayNewestDayFirst() throws {
        try save("today1.com", hoursAgo: 1)
        try save("today2.com", hoursAgo: 2)
        try save("yesterday.com", hoursAgo: 30)
        try save("older.com", hoursAgo: 80)
        viewModel.load()

        let groups = viewModel.groups
        #expect(groups.count == 3)
        #expect(groups[0].scans.map(\.input) == ["today1.com", "today2.com"])
        #expect(groups[1].scans.map(\.input) == ["yesterday.com"])
        #expect(groups[2].scans.map(\.input) == ["older.com"])
    }

    @Test func groupsOnlyContainFilteredScans() throws {
        try save("a.com", level: .risky, hoursAgo: 1)
        try save("b.com", level: .safe, hoursAgo: 30)
        viewModel.load()

        viewModel.riskFilter = .safe
        #expect(viewModel.groups.count == 1)
        #expect(viewModel.groups[0].scans.map(\.input) == ["b.com"])
    }

    @Test func recentDaysGetFriendlyTitles() {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let older = calendar.date(byAdding: .day, value: -5, to: now)!

        #expect(viewModel.title(for: calendar.startOfDay(for: now), now: now) == "Today")
        #expect(viewModel.title(for: calendar.startOfDay(for: yesterday), now: now) == "Yesterday")
        let olderTitle = viewModel.title(for: calendar.startOfDay(for: older), now: now)
        #expect(olderTitle != "Today" && olderTitle != "Yesterday")
    }

    @Test func deleteRemovesFromListAndStore() throws {
        let first = try save("a.com", hoursAgo: 1)
        let second = try save("b.com", hoursAgo: 2)
        viewModel.load()

        viewModel.delete(id: first.id)
        #expect(viewModel.scans.map(\.id) == [second.id])
        #expect(try history.fetchAll().map(\.id) == [second.id])
    }

    @Test func deleteAllEmptiesListAndStore() throws {
        try save("a.com")
        try save("b.com")
        viewModel.load()

        viewModel.deleteAll()
        #expect(viewModel.scans.isEmpty)
        #expect(try history.fetchAll().isEmpty)
    }

    @Test func nothingIsSelectedAtFirst() throws {
        try save("a.com")
        viewModel.load()
        #expect(viewModel.selectedScan == nil)
    }

    @Test func selectedScanIsFoundInTheLoadedList() throws {
        let scan = try save("a.com", hoursAgo: 1)
        try save("b.com", hoursAgo: 2)
        viewModel.load()

        viewModel.selectedScanID = scan.id
        #expect(viewModel.selectedScan?.id == scan.id)
    }

    @Test func deletingTheSelectedScanClearsTheSelection() throws {
        let scan = try save("a.com")
        viewModel.load()
        viewModel.selectedScanID = scan.id

        viewModel.delete(id: scan.id)
        #expect(viewModel.selectedScanID == nil)
    }

    @Test func deletingAnotherScanKeepsTheSelection() throws {
        let kept = try save("a.com", hoursAgo: 1)
        let other = try save("b.com", hoursAgo: 2)
        viewModel.load()
        viewModel.selectedScanID = kept.id

        viewModel.delete(id: other.id)
        #expect(viewModel.selectedScanID == kept.id)
    }

    @Test func clearingEverythingClearsTheSelection() throws {
        let scan = try save("a.com")
        viewModel.load()
        viewModel.selectedScanID = scan.id

        viewModel.deleteAll()
        #expect(viewModel.selectedScanID == nil)
    }

    @Test func reloadingAfterTheScanVanishedClearsTheSelection() throws {
        let scan = try save("a.com")
        viewModel.load()
        viewModel.selectedScanID = scan.id

        try history.delete(id: scan.id)
        viewModel.load()
        #expect(viewModel.selectedScanID == nil)
    }

    @Test func filteringDoesNotLoseTheSelection() throws {
        let scan = try save("a.com")
        viewModel.load()
        viewModel.selectedScanID = scan.id

        viewModel.searchText = "no match anywhere"
        #expect(viewModel.selectedScan?.id == scan.id)
    }

    @Test func nothingCanBeUndoneAtFirst() throws {
        try save("a.com")
        viewModel.load()
        #expect(viewModel.undoMessage == nil)
    }

    @Test func deletingAScanOffersUndo() throws {
        let scan = try save("a.com")
        viewModel.load()

        viewModel.delete(id: scan.id)
        #expect(viewModel.undoMessage == "Scan deleted")
    }

    @Test func undoPutsTheScanBackInTheListAndTheStore() throws {
        let kept = try save("a.com", hoursAgo: 1)
        let doomed = try save("b.com", hoursAgo: 2)
        viewModel.load()
        viewModel.delete(id: doomed.id)

        viewModel.undoDelete()
        #expect(viewModel.scans.map(\.id) == [kept.id, doomed.id])
        #expect(try history.fetchAll().map(\.id) == [kept.id, doomed.id])
        #expect(viewModel.undoMessage == nil)
    }

    @Test func clearingEverythingCanBeUndoneInOneGo() throws {
        try save("a.com", hoursAgo: 1)
        try save("b.com", hoursAgo: 2)
        try save("c.com", hoursAgo: 3)
        viewModel.load()

        viewModel.deleteAll()
        #expect(viewModel.undoMessage == "3 scans deleted")

        viewModel.undoDelete()
        #expect(viewModel.scans.count == 3)
        #expect(try history.fetchAll().count == 3)
    }

    @Test func theOfferGoesAwayWhenItsTimeIsUp() throws {
        let scan = try save("a.com")
        viewModel.load()
        viewModel.delete(id: scan.id)

        viewModel.expireUndo(generation: viewModel.undoGeneration)
        #expect(viewModel.undoMessage == nil)
    }

    @Test func anOldTimerCannotHideANewerOffer() throws {
        let first = try save("a.com", hoursAgo: 1)
        let second = try save("b.com", hoursAgo: 2)
        viewModel.load()

        viewModel.delete(id: first.id)
        let oldGeneration = viewModel.undoGeneration
        viewModel.delete(id: second.id)

        viewModel.expireUndo(generation: oldGeneration)
        #expect(viewModel.undoableScans.map(\.id) == [second.id])
    }

    @Test func onlyTheLatestDeletionIsUndone() throws {
        let first = try save("a.com", hoursAgo: 1)
        let second = try save("b.com", hoursAgo: 2)
        viewModel.load()
        viewModel.delete(id: first.id)
        viewModel.delete(id: second.id)

        viewModel.undoDelete()
        #expect(viewModel.scans.map(\.id) == [second.id])
    }

    @Test func undoWithNothingDeletedChangesNothing() throws {
        try save("a.com")
        viewModel.load()

        viewModel.undoDelete()
        #expect(viewModel.scans.count == 1)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func scanThatCameBackAnotherWayIsNotDoubled() throws {
        let scan = try save("a.com")
        viewModel.load()
        viewModel.delete(id: scan.id)

        try history.save(scan)
        viewModel.load()
        viewModel.undoDelete()

        #expect(viewModel.scans.count == 1)
        #expect(try history.fetchAll().count == 1)
    }

    @Test func failedUndoSaysSoAndKeepsTheOffer() throws {
        let scan = try save("a.com")
        let failing = HistoryViewModel(history: SaveFailingStore(base: history), calendar: calendar)
        failing.load()
        failing.delete(id: scan.id)

        failing.undoDelete()
        #expect(failing.errorMessage != nil)
        #expect(failing.undoMessage == "Scan deleted")
    }

    @Test func failedDeleteOffersNoUndo() {
        let failing = HistoryViewModel(history: FailingHistoryStore(), calendar: calendar)
        failing.delete(id: UUID())
        #expect(failing.undoMessage == nil)
    }

    @Test func failedLoadShowsError() {
        let failing = HistoryViewModel(history: FailingHistoryStore(), calendar: calendar)
        failing.load()
        #expect(failing.errorMessage != nil)
        #expect(failing.scans.isEmpty)
    }

    @Test func failedDeleteShowsError() {
        let failing = HistoryViewModel(history: FailingHistoryStore(), calendar: calendar)
        failing.delete(id: UUID())
        #expect(failing.errorMessage != nil)
    }

    @Test func failedDeleteAllShowsError() {
        let failing = HistoryViewModel(history: FailingHistoryStore(), calendar: calendar)
        failing.deleteAll()
        #expect(failing.errorMessage != nil)
    }
}
