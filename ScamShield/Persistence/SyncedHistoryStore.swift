//
//  SyncedHistoryStore.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import Foundation
import FirebaseAuth

//core data first, then the change is mirrored to firestore in the background
struct SyncedHistoryStore: HistoryStoring {

    let local: HistoryStoring
    let sync: HistorySyncService

    func save(_ result: ScanResult) throws {
        try local.save(result)
        Task { await sync.push() }
    }

    func fetchAll() throws -> [ScanResult] {
        try local.fetchAll()
    }

    func fetchUnsynced() throws -> [ScanResult] {
        try local.fetchUnsynced()
    }

    func markSynced(ids: [UUID]) throws {
        try local.markSynced(ids: ids)
    }

    func delete(id: UUID) throws {
        try local.delete(id: id)
        sync.queueDeletes([id])
        Task { await sync.push() }
    }

    func deleteAll() throws {
        let ids = try local.fetchAll().map(\.id)
        try local.deleteAll()
        sync.queueDeletes(ids)
        Task { await sync.push() }
    }
}

//the one history the app screens share
enum AppHistory {

    static let sync = HistorySyncService(
        local: CoreDataHistoryRepository(),
        remote: FirestoreHistoryRemote(),
        currentUserID: { Auth.auth().currentUser?.uid }
    )

    static let store: HistoryStoring = SyncedHistoryStore(local: CoreDataHistoryRepository(), sync: sync)
}
