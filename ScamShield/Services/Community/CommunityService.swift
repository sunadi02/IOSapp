//
//  CommunityService.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import os

enum CommunityError: LocalizedError, Equatable {
    case notSignedIn
    case invalidLink
    case alreadyReported
    case unavailable

    var errorDescription: String? {
        switch self {
        case .notSignedIn: "Sign in to report a scam."
        case .invalidLink: "Only website links can be reported."
        case .alreadyReported: "You have already reported this website. Thank you."
        case .unavailable: "Could not reach the community right now. Please try again."
        }
    }
}

//protocol so screens and the scanner can be tested without firestore
protocol CommunityReporting {
    func submit(url: String, category: ScamCategory, type: ScanType) async throws
    func reportCount(forDomain domain: String) async throws -> Int
    func reports(limit: Int) -> AsyncThrowingStream<[ScamReport], Error>
}

enum CommunityDomain {

    //the part of the address a person registers, a numeric address is kept whole
    static func name(for url: URL) -> String? {
        guard let host = url.host()?.lowercased(), !host.isEmpty else { return nil }

        let parts = host.split(separator: ".")
        if parts.count == 4, parts.allSatisfy({ UInt8($0) != nil }) { return host }
        return URLAnalyzer.registeredDomain(of: host)
    }

    //the query and fragment can hold personal tokens so they are never shared
    static func shareableURL(_ url: URL) -> String {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url.absoluteString
        }
        components.query = nil
        components.fragment = nil
        components.user = nil
        components.password = nil
        return components.string ?? url.absoluteString
    }
}

//reports live in one shared collection, the document id is user and website so each person counts once
struct FirestoreCommunityService: CommunityReporting {

    static let log = Logger(subsystem: "sunadi.ScamShield", category: "Community")

    private var collection: CollectionReference {
        Firestore.firestore().collection("reports")
    }

    func submit(url: String, category: ScamCategory, type: ScanType) async throws {
        guard let userID = Auth.auth().currentUser?.uid else { throw CommunityError.notSignedIn }
        guard let parsed = URLAnalyzer.normalize(url), let domain = CommunityDomain.name(for: parsed) else {
            throw CommunityError.invalidLink
        }

        let document = collection.document("\(userID)_\(domain)")

        do {
            if try await document.getDocument(source: .server).exists {
                throw CommunityError.alreadyReported
            }
            try await document.setData([
                "domain": domain,
                "url": CommunityDomain.shareableURL(parsed),
                "type": type.rawValue,
                "category": category.rawValue,
                "reporterId": userID,
                "createdAt": FieldValue.serverTimestamp()
            ])
        } catch let error as CommunityError {
            throw error
        } catch {
            Self.log.error("Reporting \(domain, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
            throw CommunityError.unavailable
        }
    }

    func reportCount(forDomain domain: String) async throws -> Int {
        let query = collection.whereField("domain", isEqualTo: domain)
        let snapshot = try await query.count.getAggregation(source: .server)
        return snapshot.count.intValue
    }

    //live feed, the listener is removed when the stream ends or the screen goes away
    func reports(limit: Int) -> AsyncThrowingStream<[ScamReport], Error> {
        AsyncThrowingStream { continuation in
            let listener = collection
                .order(by: "createdAt", descending: true)
                .limit(to: limit)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: error)
                        return
                    }
                    guard let snapshot else { return }
                    let latest = snapshot.documents.compactMap {
                        Self.report(id: $0.documentID, data: $0.data(with: .estimate))
                    }
                    continuation.yield(latest)
                }

            continuation.onTermination = { _ in listener.remove() }
        }
    }

    static func report(id: String, data: [String: Any]) -> ScamReport? {
        guard let domain = data["domain"] as? String, !domain.isEmpty,
              let createdAt = FirestoreHistoryRemote.date(from: data["createdAt"]) else {
            return nil
        }

        return ScamReport(
            id: id,
            domain: domain,
            type: (data["type"] as? String).flatMap(ScanType.init(rawValue:)) ?? .link,
            category: (data["category"] as? String).flatMap(ScamCategory.init(rawValue:)) ?? .other,
            createdAt: createdAt
        )
    }
}
