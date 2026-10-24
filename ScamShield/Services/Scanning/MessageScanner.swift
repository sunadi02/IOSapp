//
//  MessageScanner.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import Foundation

enum MessageScanError: LocalizedError {
    case emptyMessage

    var errorDescription: String? {
        "There is no message text to check."
    }
}

//combines what the wording says with what each link in the message turns out to be
struct MessageScanner {

    static let maxStoredLength = 2000

    let analyzer: MessageAnalyzer
    let linkScanner: LinkScanner

    init(analyzer: MessageAnalyzer = MessageAnalyzer(), linkScanner: LinkScanner = .live) {
        self.analyzer = analyzer
        self.linkScanner = linkScanner
    }

    func scan(_ rawText: String) async throws -> ScanResult {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw MessageScanError.emptyMessage }

        let text = String(trimmed.prefix(Self.maxStoredLength))
        let links = LinkExtractor.links(in: text)
        let analysis = analyzer.analyze(text, links: links)

        var linkResults: [ScanResult] = []
        for link in links {
            if let result = try? await linkScanner.scan(link.absoluteString) {
                linkResults.append(result)
            }
        }

        //only the riskiest link counts so a message with several links is not punished several times
        var signals = analysis.signals
        if let worst = linkResults.min(by: { $0.trustScore < $1.trustScore }) {
            let host = URL(string: worst.input)?.host() ?? worst.input
            signals += worst.signals.map {
                RiskSignal(title: $0.title, detail: "In \(host): \($0.detail)", weight: $0.weight)
            }
        }

        //wording alone cannot prove a message is safe, a clean verdict needs links that were checked online
        let allChecked = !linkResults.isEmpty && !linkResults.contains { result in
            result.signals.contains { $0.title == LinkScanner.onlineCheckUnavailableTitle }
        }

        return RiskScorer.makeResult(
            type: .screenshot,
            input: text,
            signals: signals,
            verified: allChecked && analysis.isSupportedLanguage
        )
    }
}
