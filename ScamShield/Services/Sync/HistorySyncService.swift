//
//  HistorySyncService.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import Foundation

//protocol so syncing can be tested without firestore
protocol RemoteHistoryStoring {
    func fetchAll(userID: String) async throws -> [ScanResult]
    func upsert(_ results: [ScanResult], userID: String) async throws
    func delete(ids: [UUID], userID: String) async throws
}

//keeps core data and firestore in step: sends deletes, uploads new scans, then merges what other devices saved
final class HistorySyncService {

    struct MergePlan: Equatable {
        let upserts: [ScanResult]
        let localDeletes: [UUID]
    }

    static let pendingDeletesKey = "pendingRemoteDeletes"

    private let local: HistoryStoring
    private let remote: RemoteHistoryStoring
    private let currentUserID: () -> String?
    private let defaults: UserDefaults

    private var isRunning = false
    private var wantsPush = false
    private var wantsPull = false

    init(
        local: HistoryStoring,
        remote: RemoteHistoryStoring,
        currentUserID: @escaping () -> String?,
        defaults: UserDefaults = .standard
    ) {
        self.local = local
        self.remote = remote
        self.currentUserID = currentUserID
        self.defaults = defaults
    }

    var pendingDeletes: Set<UUID> {
        Set((defaults.stringArray(forKey: Self.pendingDeletesKey) ?? []).compactMap(UUID.init(uuidString:)))
    }

    //deletes are remembered until firestore confirms them so a pull cannot bring the scan back
    func queueDeletes(_ ids: [UUID]) {
        storePending(pendingDeletes.union(ids))
    }

    func push() async {
        wantsPush = true
        await drain()
    }

    func sync() async {
        wantsPush = true
        wantsPull = true
        await drain()
    }

    //the cloud keeps the history so the next account on this device starts clean
    func didSignOut() {
        try? local.deleteAll()
        defaults.removeObject(forKey: Self.pendingDeletesKey)
    }

    static func mergePlan(
        remote: [ScanResult],
        local: [ScanResult],
        unsyncedIDs: Set<UUID>,
        pendingDeletes: Set<UUID>
    ) -> MergePlan {
        let localByID = Dictionary(local.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let remoteIDs = Set(remote.map(\.id))

        let upserts = remote.filter { scan in
            guard !pendingDeletes.contains(scan.id) else { return false }
            guard let existing = localByID[scan.id] else { return true }
            return !unsyncedIDs.contains(scan.id) && scan.riskLevel == .risky && existing.riskLevel != .risky
        }

        //synced here but gone from the cloud means another device deleted it
        let localDeletes = local.map(\.id).filter { !remoteIDs.contains($0) && !unsyncedIDs.contains($0) }
        return MergePlan(upserts: upserts, localDeletes: localDeletes)
    }

    //calls made while a run is active are folded into one more pass
    private func drain() async {
        guard !isRunning else { return }
        isRunning = true
        defer { isRunning = false }

        while wantsPush || wantsPull {
            let shouldPull = wantsPull
            wantsPush = false
            wantsPull = false

            guard let userID = currentUserID() else { continue }
            await flushDeletes(userID: userID)
            await uploadUnsynced(userID: userID)
            if shouldPull { await pullRemote(userID: userID) }
        }
    }

    private func flushDeletes(userID: String) async {
        let pending = pendingDeletes
        guard !pending.isEmpty else { return }

        do {
            try await remote.delete(ids: Array(pending), userID: userID)
            storePending(pendingDeletes.subtracting(pending))
        } catch {
            return
        }
    }

    private func uploadUnsynced(userID: String) async {
        guard let unsynced = try? local.fetchUnsynced() else { return }

        //message text from screenshots stays on this device and is never uploaded
        let shareable = unsynced.filter { $0.type != .screenshot }
        guard !shareable.isEmpty else { return }

        do {
            try await remote.upsert(shareable, userID: userID)
            try local.markSynced(ids: shareable.map(\.id))
        } catch {
            return
        }
    }

    private func pullRemote(userID: String) async {
        guard let remoteScans = try? await remote.fetchAll(userID: userID),
              let localScans = try? local.fetchAll(),
              let unsynced = try? local.fetchUnsynced() else { return }

        let plan = Self.mergePlan(
            remote: remoteScans,
            local: localScans,
            unsyncedIDs: Set(unsynced.map(\.id)),
            pendingDeletes: pendingDeletes
        )

        for scan in plan.upserts { try? local.save(scan) }
        try? local.markSynced(ids: plan.upserts.map(\.id))
        for id in plan.localDeletes { try? local.delete(id: id) }
    }

    private func storePending(_ ids: Set<UUID>) {
        defaults.set(ids.map(\.uuidString), forKey: Self.pendingDeletesKey)
    }
}
