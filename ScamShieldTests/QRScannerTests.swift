//
//  QRScannerTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-24.
//

import Testing
import Foundation
@testable import ScamShield

@MainActor
struct QRScannerTests {

    private func makeScanner(threats: [String] = []) -> QRScanner {
        QRScanner(linkScanner: LinkScanner(reputation: MockReputationChecker(foundThreats: threats)))
    }

    @Test func webLinkGoesThroughTheFullLinkCheckAsAQRScan() async throws {
        let result = try await makeScanner().scan(payload: "https://www.apple.com")
        #expect(result.type == .qr)
        #expect(result.input == "https://www.apple.com")
        #expect(result.riskLevel == .safe)
    }

    @Test func reportedLinkInsideACodeIsRisky() async throws {
        let result = try await makeScanner(threats: ["SOCIAL_ENGINEERING"]).scan(payload: "https://www.example.com")
        #expect(result.riskLevel == .risky)
        #expect(result.type == .qr)
    }

    @Test func scamLookingLinkInsideACodeIsCaughtOnDevice() async throws {
        let result = try await makeScanner().scan(payload: "http://paypal-login-verify.xyz")
        #expect(result.riskLevel == .risky)
    }

    @Test func plainTextCodeIsSafe() async throws {
        let result = try await makeScanner().scan(payload: "Table 12")
        #expect(result.type == .qr)
        #expect(result.riskLevel == .safe)
        #expect(result.trustScore == 100)
        #expect(result.input == "Table 12")
    }

    @Test func wifiCodeIsNeverCalledSafeAndHidesThePassword() async throws {
        let result = try await makeScanner().scan(payload: "WIFI:T:WPA;S:CafeNet;P:hunter2;;")
        #expect(result.riskLevel == .unknown)
        #expect(result.input == "Wi-Fi network: CafeNet")
        #expect(!result.input.contains("hunter2"))
    }

    @Test func textMessageCodeLowersTrust() async throws {
        let result = try await makeScanner().scan(payload: "SMSTO:+94771234567:Send OTP")
        #expect(result.trustScore == 70)
        #expect(result.riskLevel == .unknown)
        #expect(result.signals.first?.title == "Pre-filled text message")
    }

    @Test func codeThatRunsCommandsIsHighRisk() async throws {
        let result = try await makeScanner().scan(payload: "javascript:alert(1)")
        #expect(result.trustScore == 60)
        #expect(result.signals.first?.weight == 40)
    }

    @Test func paymentCodeIsWarnedAbout() async throws {
        let result = try await makeScanner().scan(payload: "upi://pay?pa=name@bank")
        #expect(result.signals.first?.title == "Payment request")
        #expect(result.riskLevel == .unknown)
    }
}
