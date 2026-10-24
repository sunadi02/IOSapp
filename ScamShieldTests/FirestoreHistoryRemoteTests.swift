//
//  FirestoreHistoryRemoteTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-24.
//

import Testing
import Foundation
@testable import ScamShield

@MainActor
struct FirestoreHistoryRemoteTests {

    let sample = ScanResult(
        type: .qr,
        input: "https://paypal-login.xyz",
        riskLevel: .risky,
        trustScore: 20,
        signals: [
            RiskSignal(title: "Brand impersonation", detail: "Mentions paypal", weight: 35),
            RiskSignal(title: "Unusual domain ending", detail: "The .xyz ending", weight: 15)
        ],
        date: Date(timeIntervalSince1970: 1_800_000_000)
    )

    @Test func scanSurvivesAFirestoreRoundTrip() {
        let data = FirestoreHistoryRemote.data(for: sample)
        let restored = FirestoreHistoryRemote.result(id: sample.id.uuidString, data: data)
        #expect(restored == sample)
    }

    @Test func scanWithoutSignalsSurvivesToo() {
        let plain = ScanResult(type: .link, input: "https://apple.com", riskLevel: .safe, trustScore: 100)
        let data = FirestoreHistoryRemote.data(for: plain)
        #expect(FirestoreHistoryRemote.result(id: plain.id.uuidString, data: data)?.signals == [])
    }

    @Test(arguments: ["type", "input", "riskLevel", "trustScore", "date"])
    func documentMissingARequiredFieldIsSkipped(key: String) {
        var data = FirestoreHistoryRemote.data(for: sample)
        data[key] = nil
        #expect(FirestoreHistoryRemote.result(id: sample.id.uuidString, data: data) == nil)
    }

    @Test func documentWithUnknownTypeIsSkipped() {
        var data = FirestoreHistoryRemote.data(for: sample)
        data["type"] = "hologram"
        #expect(FirestoreHistoryRemote.result(id: sample.id.uuidString, data: data) == nil)
    }

    @Test func documentWithBadIDIsSkipped() {
        let data = FirestoreHistoryRemote.data(for: sample)
        #expect(FirestoreHistoryRemote.result(id: "not-a-uuid", data: data) == nil)
    }

    @Test func brokenSignalsAreDroppedButTheScanIsKept() {
        var data = FirestoreHistoryRemote.data(for: sample)
        data["signals"] = [["title": "Only a title"]]

        let restored = FirestoreHistoryRemote.result(id: sample.id.uuidString, data: data)
        #expect(restored?.signals.isEmpty == true)
        #expect(restored?.input == sample.input)
    }
}
