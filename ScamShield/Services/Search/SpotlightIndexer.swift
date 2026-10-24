//
//  SpotlightIndexer.swift
//  ScamShield
//
//  Created by student2 on 2026-10-25.
//

import CoreSpotlight
import Foundation
import UniformTypeIdentifiers

//protocol so the history store can be tested without touching the real search index
protocol SearchIndexing {
    func index(_ scans: [ScanResult])
    func remove(ids: [UUID])
    func removeAll()
    func replaceAll(with scans: [ScanResult])
}

//puts checked links and QR codes into iOS search on this device, messages are never indexed because they are private
struct SpotlightIndexer: SearchIndexing {

    static let domain = "com.scamshield.scans"

    private var searchIndex: CSSearchableIndex {
        .default()
    }

    func index(_ scans: [ScanResult]) {
        let items = scans.compactMap(Self.item(for:))
        guard !items.isEmpty else { return }
        searchIndex.indexSearchableItems(items, completionHandler: nil)
    }

    func remove(ids: [UUID]) {
        guard !ids.isEmpty else { return }
        searchIndex.deleteSearchableItems(withIdentifiers: ids.map(\.uuidString), completionHandler: nil)
    }

    func removeAll() {
        searchIndex.deleteSearchableItems(withDomainIdentifiers: [Self.domain], completionHandler: nil)
    }

    //clears first and adds after, so scans deleted on another device also disappear from search
    func replaceAll(with scans: [ScanResult]) {
        let items = scans.compactMap(Self.item(for:))
        let searchIndex = searchIndex

        searchIndex.deleteSearchableItems(withDomainIdentifiers: [Self.domain]) { _ in
            guard !items.isEmpty else { return }
            searchIndex.indexSearchableItems(items, completionHandler: nil)
        }
    }

    static func item(for scan: ScanResult) -> CSSearchableItem? {
        guard let attributes = attributes(for: scan) else { return nil }
        return CSSearchableItem(uniqueIdentifier: scan.id.uuidString, domainIdentifier: domain, attributeSet: attributes)
    }

    static func attributes(for scan: ScanResult) -> CSSearchableItemAttributeSet? {
        guard scan.type != .screenshot else { return nil }

        let subject = LinkVerdictSummary.subject(for: scan)
        let attributes = CSSearchableItemAttributeSet(contentType: .text)
        attributes.title = "\(subject): \(scan.riskLevel.title)"
        attributes.contentDescription = "Trust score \(scan.trustScore) out of 100. Checked \(scan.date.formatted(date: .abbreviated, time: .omitted)) with ScamShield."
        attributes.keywords = [subject, scan.riskLevel.title, scan.type.title, "ScamShield", "scam"]
        attributes.contentCreationDate = scan.date
        return attributes
    }
}
