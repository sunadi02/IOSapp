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

    static let onlineCheckUnavailableTitle = "Online check unavailable"

    //a slow or offline community lookup must never hold up the answer, so it is given a few seconds at most
    static let communityTimeout = 4.0

    let analyzer = URLAnalyzer()
    let reputation: LinkReputationChecking
    let community: CommunityReporting?
    let communityTimeout: Double

    //community lookups are off unless asked for so tests never reach firestore
    init(
        reputation: LinkReputationChecking = SafeBrowsingService(),
        community: CommunityReporting? = nil,
        communityTimeout: Double = LinkScanner.communityTimeout
    ) {
        self.reputation = reputation
        self.community = community
        self.communityTimeout = communityTimeout
    }

    static var live: LinkScanner {
        LinkScanner(community: FirestoreCommunityService())
    }

    func scan(_ raw: String, as type: ScanType = .link) async throws -> ScanResult {
        guard let url = URLAnalyzer.normalize(raw) else { throw LinkScanError.invalidLink }

        async let communityReport = communityReports(for: url)
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
            signals.append(RiskSignal(title: Self.onlineCheckUnavailableTitle, detail: "Could not reach Google Safe Browsing, so this result only uses on-device checks.", weight: 0))
        }

        if let report = await communityReport, report.count > 0 {
            let users = report.count == 1 ? "1 ScamShield user has" : "\(report.count) ScamShield users have"
            signals.append(RiskSignal(
                title: "Reported by the community",
                detail: "\(users) reported \(report.domain) as a scam.",
                weight: Self.communityWeight(for: report.count)
            ))
        }

        return RiskScorer.makeResult(type: type, input: url.absoluteString, signals: signals, verified: verified)
    }

    //one report is a warning, five from different people is enough to call a link risky
    static func communityWeight(for count: Int) -> Int {
        switch count {
        case ..<2: 25
        case 2..<5: 40
        default: 55
        }
    }

    private func communityReports(for url: URL) async -> (domain: String, count: Int)? {
        guard let community, let domain = CommunityDomain.name(for: url) else { return nil }

        let count = await Timeout.run(after: communityTimeout) {
            try? await community.reportCount(forDomain: domain)
        }
        guard let count else { return nil }
        return (domain: domain, count: count)
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
