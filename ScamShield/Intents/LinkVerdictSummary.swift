//
//  LinkVerdictSummary.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import Foundation

//the sentences Siri speaks, kept short and free of anything private
enum LinkVerdictSummary {

    static func checkSentence(for result: ScanResult) -> String {
        let score = "Trust score \(result.trustScore) out of 100."

        switch result.riskLevel {
        case .safe:
            return "That link looks safe. \(score) Still be careful before sharing personal details."
        case .risky:
            return "Be careful, that link looks risky. \(score) \(reasonSentence(for: result))Do not open it or reply."
        case .unknown:
            return "I could not confirm that link is safe. \(score) \(reasonSentence(for: result))Only continue if you fully trust the sender."
        }
    }

    static func lastScanSentence(for result: ScanResult) -> String {
        let verdict = switch result.riskLevel {
        case .safe: "safe"
        case .risky: "risky"
        case .unknown: "unconfirmed"
        }
        return "Your last scan was \(subject(for: result)) and it looks \(verdict). Trust score \(result.trustScore) out of 100."
    }

    //a scanned message is never read out loud
    static func subject(for result: ScanResult) -> String {
        switch result.type {
        case .screenshot:
            return "a message"
        case .link, .qr:
            return URL(string: result.input)?.host() ?? String(result.input.prefix(40))
        }
    }

    private static func reasonSentence(for result: ScanResult) -> String {
        guard let top = result.signals.max(by: { $0.weight < $1.weight }), top.weight > 0 else { return "" }
        return "The main reason is \(top.title). "
    }
}
