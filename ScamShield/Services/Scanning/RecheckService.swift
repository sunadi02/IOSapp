//
//  RecheckService.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import Foundation

//checks saved links again later and alerts the user if one has since been reported
struct RecheckService {

    static let minimumInterval: TimeInterval = 6 * 60 * 60
    static let lookback: TimeInterval = 30 * 24 * 60 * 60
    static let maxChecksPerRun = 20
    static let lastRunKey = "lastRecheckDate"
    static let laterReportedTitle = "Later reported by Google Safe Browsing"

    let reputation: LinkReputationChecking
    let history: HistoryStoring
    let notifications: NotificationScheduling
    let defaults: UserDefaults

    init(
        reputation: LinkReputationChecking = SafeBrowsingService(),
        history: HistoryStoring = AppHistory.store,
        notifications: NotificationScheduling = NotificationService(),
        defaults: UserDefaults = .standard
    ) {
        self.reputation = reputation
        self.history = history
        self.notifications = notifications
        self.defaults = defaults
    }

    //returns how many saved links were newly flagged, force skips the time limit only
    @discardableResult
    func run(force: Bool = false, now: Date = Date()) async -> Int {
        let alertsEnabled = defaults.object(forKey: AppSettings.alertsEnabled) as? Bool ?? true
        guard alertsEnabled else { return 0 }

        if !force, let last = defaults.object(forKey: Self.lastRunKey) as? Date,
           now.timeIntervalSince(last) < Self.minimumInterval {
            return 0
        }

        let cutoff = now.addingTimeInterval(-Self.lookback)
        let candidates = ((try? history.fetchAll()) ?? [])
            .filter { $0.type != .screenshot && $0.riskLevel != .risky && $0.date >= cutoff }
            .prefix(Self.maxChecksPerRun)

        var checked = 0
        var flagged = 0

        for scan in candidates {
            guard let url = URL(string: scan.input),
                  let threats = try? await reputation.threats(for: url) else { continue }

            checked += 1
            guard !threats.isEmpty else { continue }

            let updated = Self.flagged(scan, threats: threats)
            try? history.save(updated)
            await notifications.sendScamAlert(for: updated)
            flagged += 1
        }

        //an offline run does not start the wait so the next launch tries again
        if checked > 0 || candidates.isEmpty {
            defaults.set(now, forKey: Self.lastRunKey)
        }
        return flagged
    }

    static func flagged(_ scan: ScanResult, threats: [String]) -> ScanResult {
        let names = threats.map(LinkScanner.friendlyName).joined(separator: " and ")
        let signal = RiskSignal(
            title: laterReportedTitle,
            detail: "Google reported this link as \(names) after you checked it.",
            weight: 100
        )
        let signals = (scan.signals + [signal]).sorted { $0.weight > $1.weight }

        return ScanResult(
            id: scan.id,
            type: scan.type,
            input: scan.input,
            riskLevel: .risky,
            trustScore: RiskScorer.trustScore(for: signals),
            signals: signals,
            date: scan.date
        )
    }
}
