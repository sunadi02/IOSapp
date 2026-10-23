//
//  URLAnalyzerTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-23.
//

import Testing
import Foundation
@testable import ScamShield

@MainActor
struct URLAnalyzerTests {

    let analyzer = URLAnalyzer()

    private func titles(for raw: String) -> [String] {
        guard let url = URLAnalyzer.normalize(raw) else { return [] }
        return analyzer.analyze(url).map(\.title)
    }

    @Test func normalizeAddsHttpsWhenMissing() {
        #expect(URLAnalyzer.normalize("example.com")?.absoluteString == "https://example.com")
    }

    @Test(arguments: ["", "   ", "not a link", "ftp://files.example.com", "localhost"])
    func normalizeRejectsInvalidInput(_ raw: String) {
        #expect(URLAnalyzer.normalize(raw) == nil)
    }

    @Test func officialSiteHasNoSignals() {
        #expect(titles(for: "https://www.apple.com").isEmpty)
    }

    @Test func plainHttpIsFlagged() {
        #expect(titles(for: "http://example.com").contains("Not encrypted"))
    }

    @Test func ipAddressIsFlagged() {
        #expect(titles(for: "https://192.168.10.4/pay").contains("Raw IP address"))
    }

    @Test func brandOnWrongDomainIsFlagged() {
        #expect(titles(for: "https://paypal-secure-check.xyz").contains("Brand impersonation"))
    }

    @Test func brandOnCountryDomainIsNotFlagged() {
        #expect(!titles(for: "https://www.boc.lk").contains("Brand impersonation"))
        #expect(!titles(for: "https://www.combank.com.lk").contains("Brand impersonation"))
    }

    @Test func shortenerIsFlagged() {
        #expect(titles(for: "https://bit.ly/abc123").contains("Shortened link"))
    }

    @Test func userInfoTrickIsFlagged() {
        #expect(titles(for: "https://www.boc.lk@evil.example.com").contains("Hidden destination"))
    }

    @Test func punycodeIsFlagged() {
        #expect(titles(for: "https://xn--pple-43d.com").contains("Lookalike characters"))
    }

    @Test(arguments: [
        ("www.sampath.lk", "sampath.lk"),
        ("online.combank.com.lk", "combank.com.lk"),
        ("a.b.example.co.uk", "example.co.uk"),
        ("example.com", "example.com")
    ])
    func registeredDomainHandlesCompoundEndings(host: String, expected: String) {
        #expect(URLAnalyzer.registeredDomain(of: host) == expected)
    }
}
