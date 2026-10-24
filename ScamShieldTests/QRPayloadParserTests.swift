//
//  QRPayloadParserTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-24.
//

import Testing
import Foundation
@testable import ScamShield

@MainActor
struct QRPayloadParserTests {

    private func web(_ text: String) -> QRPayload {
        .url(URL(string: text)!)
    }

    @Test func httpsLinkIsAWebLink() {
        #expect(QRPayloadParser.parse("https://example.com/path?x=1") == web("https://example.com/path?x=1"))
    }

    @Test func uppercaseSchemeIsStillAWebLink() {
        #expect(QRPayloadParser.parse("HTTPS://EXAMPLE.COM") == web("HTTPS://EXAMPLE.COM"))
    }

    @Test func domainWithoutSchemeIsAWebLink() {
        #expect(QRPayloadParser.parse("example.com/offer") == web("https://example.com/offer"))
    }

    @Test func surroundingWhitespaceIsIgnored() {
        #expect(QRPayloadParser.parse("  https://example.com \n") == web("https://example.com"))
    }

    @Test(arguments: ["Table 12", "Table 12: hello world", "hello", ""])
    func ordinaryTextStaysText(_ text: String) {
        #expect(QRPayloadParser.parse(text) == .text(text))
    }

    @Test func securedWifiKeepsNetworkNameAndDropsPassword() {
        let payload = QRPayloadParser.parse("WIFI:T:WPA;S:CafeNet;P:hunter2;;")
        #expect(payload == .wifi(ssid: "CafeNet", security: "WPA"))
        #expect(!payload.displayText.contains("hunter2"))
    }

    @Test func openWifiHasNoPasswordType() {
        let payload = QRPayloadParser.parse("WIFI:S:FreeAirport;T:nopass;;")
        #expect(payload == .wifi(ssid: "FreeAirport", security: "nopass"))
    }

    @Test func wifiNameCanContainEscapedSemicolons() {
        let payload = QRPayloadParser.parse(#"WIFI:S:My\;Net;T:WPA;P:x;;"#)
        #expect(payload == .wifi(ssid: "My;Net", security: "WPA"))
    }

    @Test func wifiWithoutANameIsLabelledUnknown() {
        #expect(QRPayloadParser.parse("WIFI:T:WPA;P:x;;") == .wifi(ssid: "Unknown network", security: "WPA"))
    }

    @Test func smstoCodeHasNumberAndMessage() {
        #expect(QRPayloadParser.parse("SMSTO:+94771234567:Send OTP now") == .sms(number: "+94771234567", body: "Send OTP now"))
    }

    @Test func smstoCodeWithoutMessage() {
        #expect(QRPayloadParser.parse("smsto:+94771234567") == .sms(number: "+94771234567", body: nil))
    }

    @Test func smsLinkWithBodyParameter() {
        #expect(QRPayloadParser.parse("sms:+94771234567?body=Hello%20there") == .sms(number: "+94771234567", body: "Hello there"))
    }

    @Test func telephoneLink() {
        #expect(QRPayloadParser.parse("tel:+94112345678") == .phone("+94112345678"))
    }

    @Test func mailLinkIgnoresSubjectAndBody() {
        #expect(QRPayloadParser.parse("mailto:help@example.com?subject=Hi") == .email("help@example.com"))
    }

    @Test(arguments: ["upi://pay?pa=name@bank&am=500", "00020101021226280011lk.lankaqr"])
    func paymentCodesAreRecognised(_ text: String) {
        #expect(QRPayloadParser.parse(text) == .payment)
    }

    @Test(arguments: ["javascript:alert(1)", "data:text/html,<script>", "file:///etc/passwd", "intent://scan/#Intent;end"])
    func codesThatRunCommandsAreUnsupported(_ text: String) {
        guard case .unsupported = QRPayloadParser.parse(text) else {
            Issue.record("\(text) should be unsupported")
            return
        }
    }

    @Test func unsupportedCodeNamesItsScheme() {
        #expect(QRPayloadParser.parse("JavaScript:alert(1)") == .unsupported(scheme: "javascript"))
    }

    @Test func longTextIsShortenedForHistory() {
        let payload = QRPayloadParser.parse(String(repeating: "a", count: 500))
        #expect(payload.displayText.count == 200)
    }

    @Test func webLinksHaveNoExtraSignals() {
        #expect(QRPayloadParser.signals(for: web("https://example.com")).isEmpty)
    }

    @Test func openWifiIsWarnedMoreStronglyThanSecuredWifi() {
        let open = QRPayloadParser.signals(for: .wifi(ssid: "A", security: "nopass"))
        let missing = QRPayloadParser.signals(for: .wifi(ssid: "A", security: nil))
        let secured = QRPayloadParser.signals(for: .wifi(ssid: "A", security: "WPA"))

        #expect(open.first?.weight == 25)
        #expect(missing.first?.weight == 25)
        #expect(secured.first?.weight == 10)
    }

    @Test(arguments: [
        (QRPayload.sms(number: "1", body: nil), 30),
        (QRPayload.phone("1"), 20),
        (QRPayload.email("a@b.com"), 10),
        (QRPayload.payment, 30),
        (QRPayload.unsupported(scheme: "javascript"), 40),
        (QRPayload.text("hi"), 0)
    ])
    func everyKindOfCodeHasOneSignalWithTheRightWeight(payload: QRPayload, expected: Int) {
        let signals = QRPayloadParser.signals(for: payload)
        #expect(signals.count == 1)
        #expect(signals.first?.weight == expected)
    }

    @Test func onlyPlainTextCountsAsPlainText() {
        #expect(QRPayload.text("hi").isPlainText)
        #expect(!QRPayload.phone("1").isPlainText)
        #expect(!QRPayload.payment.isPlainText)
    }
}
