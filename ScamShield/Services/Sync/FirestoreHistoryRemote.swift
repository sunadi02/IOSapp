//
//  FirestoreHistoryRemote.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import Foundation
import FirebaseFirestore

//stores each user's scans at users/{uid}/scans/{scanId}
struct FirestoreHistoryRemote: RemoteHistoryStoring {

    static let batchLimit = 400

    private func scans(for userID: String) -> CollectionReference {
        Firestore.firestore().collection("users").document(userID).collection("scans")
    }

    //server source so a stale offline cache is never mistaken for a deleted scan
    func fetchAll(userID: String) async throws -> [ScanResult] {
        let snapshot = try await scans(for: userID).getDocuments(source: .server)
        return snapshot.documents.compactMap { Self.result(id: $0.documentID, data: $0.data()) }
    }

    func upsert(_ results: [ScanResult], userID: String) async throws {
        let collection = scans(for: userID)

        for start in stride(from: 0, to: results.count, by: Self.batchLimit) {
            let batch = Firestore.firestore().batch()
            for result in results[start..<min(start + Self.batchLimit, results.count)] {
                batch.setData(Self.data(for: result), forDocument: collection.document(result.id.uuidString))
            }
            try await batch.commit()
        }
    }

    func delete(ids: [UUID], userID: String) async throws {
        let collection = scans(for: userID)

        for start in stride(from: 0, to: ids.count, by: Self.batchLimit) {
            let batch = Firestore.firestore().batch()
            for id in ids[start..<min(start + Self.batchLimit, ids.count)] {
                batch.deleteDocument(collection.document(id.uuidString))
            }
            try await batch.commit()
        }
    }

    static func data(for result: ScanResult) -> [String: Any] {
        [
            "type": result.type.rawValue,
            "input": result.input,
            "riskLevel": result.riskLevel.rawValue,
            "trustScore": result.trustScore,
            "signals": result.signals.map { signal -> [String: Any] in
                ["id": signal.id.uuidString, "title": signal.title, "detail": signal.detail, "weight": signal.weight]
            },
            "date": result.date
        ]
    }

    //returns nil for documents that are missing fields so one bad record cannot break a pull
    static func result(id: String, data: [String: Any]) -> ScanResult? {
        guard let uuid = UUID(uuidString: id),
              let type = (data["type"] as? String).flatMap(ScanType.init(rawValue:)),
              let input = data["input"] as? String,
              let riskLevel = (data["riskLevel"] as? String).flatMap(RiskLevel.init(rawValue:)),
              let trustScore = data["trustScore"] as? Int,
              let date = date(from: data["date"]) else {
            return nil
        }

        let signals = (data["signals"] as? [[String: Any]] ?? []).compactMap { raw -> RiskSignal? in
            guard let title = raw["title"] as? String,
                  let detail = raw["detail"] as? String,
                  let weight = raw["weight"] as? Int else {
                return nil
            }
            let signalID = (raw["id"] as? String).flatMap(UUID.init(uuidString:)) ?? UUID()
            return RiskSignal(id: signalID, title: title, detail: detail, weight: weight)
        }

        return ScanResult(id: uuid, type: type, input: input, riskLevel: riskLevel, trustScore: trustScore, signals: signals, date: date)
    }

    static func date(from value: Any?) -> Date? {
        if let timestamp = value as? Timestamp { return timestamp.dateValue() }
        return value as? Date
    }
}
