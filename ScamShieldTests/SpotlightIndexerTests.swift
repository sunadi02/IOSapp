//
//  SpotlightIndexerTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-25.
//

import Testing
import Foundation
@testable import ScamShield

//records what would have been put into iOS search
@MainActor
final class MockSearchIndex: SearchIndexing {
    private(set) var indexed: [UUID] = []
    private(set) var removed: [UUID] = []
    private(set) var removeAllCount = 0
    private(set) var replacedWith: [UUID]?

    func index(_ scans: [ScanResult]) { indexed += scans.map(\.id) }
    func remove(ids: [UUID]) { removed += ids }
    func removeAll() { removeAllCount += 1 }
    func replaceAll(with scans: [ScanResult]) { replacedWith = scans.map(\.id) }
}

@MainActor
struct SpotlightIndexerTests {

    private func scan(_ type: ScanType = .link, input: String = "https://evil.example.com/login", level: RiskLevel = .risky) -> ScanResult {
        ScanResult(type: type, input: input, riskLevel: level, trustScore: 20, date: Date(timeIntervalSince1970: 1_800_000_000))
    }

    @Test func checkedLinkIsTitledWithItsWebsiteAndVerdict() throws {
        let attributes = try #require(SpotlightIndexer.attributes(for: scan()))
        #expect(attributes.title == "evil.example.com: Risky")
    }

    @Test func descriptionGivesTheTrustScore() throws {
        let attributes = try #require(SpotlightIndexer.attributes(for: scan()))
        #expect(attributes.contentDescription?.contains("Trust score 20 out of 100") == true)
    }

    @Test func keywordsLetPeopleSearchByWebsiteOrVerdict() throws {
        let attributes = try #require(SpotlightIndexer.attributes(for: scan(level: .safe)))
        let keywords = attributes.keywords ?? []

        #expect(keywords.contains("evil.example.com"))
        #expect(keywords.contains("Safe"))
        #expect(keywords.contains("ScamShield"))
    }

    @Test func qrCodeIsIndexedToo() throws {
        let attributes = try #require(SpotlightIndexer.attributes(for: scan(.qr, input: "https://shop.example.com")))
        #expect(attributes.title == "shop.example.com: Risky")
    }

    @Test func messageScreenshotsAreNeverIndexed() {
        let message = scan(.screenshot, input: "Share your OTP 482913 now")
        #expect(SpotlightIndexer.attributes(for: message) == nil)
        #expect(SpotlightIndexer.item(for: message) == nil)
    }

    @Test func searchItemUsesTheScanIDSoItCanBeOpened() throws {
        let result = scan()
        let item = try #require(SpotlightIndexer.item(for: result))

        #expect(item.uniqueIdentifier == result.id.uuidString)
        #expect(item.domainIdentifier == SpotlightIndexer.domain)
    }

    @Test func savingAScanAddsItToSearch() throws {
        let (store, index, _) = makeStore()
        let result = scan()

        try store.save(result)
        #expect(index.indexed == [result.id])
    }

    @Test func deletingAScanTakesItOutOfSearch() throws {
        let (store, index, _) = makeStore()
        let result = scan()
        try store.save(result)

        try store.delete(id: result.id)
        #expect(index.removed == [result.id])
    }

    @Test func clearingHistoryEmptiesSearch() throws {
        let (store, index, _) = makeStore()
        try store.save(scan())

        try store.deleteAll()
        #expect(index.removeAllCount == 1)
    }

    @Test func storeWithoutASearchIndexStillWorks() throws {
        let (_, _, local) = makeStore()
        let plain = SyncedHistoryStore(local: local, sync: makeSync(local: local))

        try plain.save(scan())
        #expect(try plain.fetchAll().count == 1)
    }

    private func makeSync(local: HistoryStoring) -> HistorySyncService {
        HistorySyncService(
            local: local,
            remote: MockRemoteHistory(),
            currentUserID: { nil },
            defaults: UserDefaults(suiteName: "SpotlightIndexerTests-\(UUID().uuidString)")!
        )
    }

    private func makeStore() -> (store: SyncedHistoryStore, index: MockSearchIndex, local: CoreDataHistoryRepository) {
        let local = CoreDataHistoryRepository(context: PersistenceController(inMemory: true).viewContext)
        let index = MockSearchIndex()
        let store = SyncedHistoryStore(local: local, sync: makeSync(local: local), searchIndex: index)
        return (store, index, local)
    }
}
