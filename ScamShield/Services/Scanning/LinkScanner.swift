//
//  LinkScanner.swift
//  ScamShield
//
//  Created by student2 on 2026-10-23.
//

import Foundation

enum LinkScanError: LocalizedError {
    case invalidLink

    var errorDescription: String? {
        "That does not look like a web link. Try something like example.com."
    }
}

//runs the on device checks and the google safe browsing check for one link
struct LinkScanner {

    let analyzer = URLAnalyzer()
    let reputation: LinkReputationChecking

    init(reputation: LinkReputationChecking = SafeBrowsingService()) {
        self.reputation = reputation
    }

    func scan(_ raw: String, as type: ScanType = .link) async throws -> ScanResult {
        guard let url = URLAnalyzer.normalize(raw) else { throw LinkScanError.invalidLink }

        var signals = analyzer.analyze(url)
        var verified = false

        do {
            let threats = try await reputation.threats(for: url)
            verified = true
            if !threats.isEmpty {
                let names = threats.map(Self.friendlyName).joined(separator: " and ")
                signals.append(RiskSignal(title: "Reported by Google Safe Browsing", detail: "This link is on Google's list of known \(names) sites.", weight: 100))
            }
        } catch {
            //still give an on device result when the api cannot be reached
            signals.append(RiskSignal(title: "Online check unavailable", detail: "Could not reach Google Safe Browsing, so this result only uses on-device checks.", weight: 0))
        }

        return RiskScorer.makeResult(type: type, input: url.absoluteString, signals: signals, verified: verified)
    }

    static func friendlyName(for threat: String) -> String {
        switch threat {
        case "SOCIAL_ENGINEERING": "phishing"
        case "MALWARE": "malware"
        case "UNWANTED_SOFTWARE": "unwanted software"
        case "POTENTIALLY_HARMFUL_APPLICATION": "harmful app"
        default: threat.lowercased().replacingOccurrences(of: "_", with: " ")
        }
    }
}
