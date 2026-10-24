//
//  QRScanner.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import Foundation

//web links get the full link check, other codes are explained from what they would do
struct QRScanner {

    let linkScanner: LinkScanner

    init(linkScanner: LinkScanner = .live) {
        self.linkScanner = linkScanner
    }

    func scan(payload raw: String) async throws -> ScanResult {
        let payload = QRPayloadParser.parse(raw)

        if case .url(let url) = payload {
            return try await linkScanner.scan(url.absoluteString, as: .qr)
        }

        return RiskScorer.makeResult(
            type: .qr,
            input: payload.displayText,
            signals: QRPayloadParser.signals(for: payload),
            verified: payload.isPlainText
        )
    }
}
