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

    @Test func longChainOfSubdomainsIsFlagged() {
        #expect(titles(for: "https://a.b.c.d.example.com").contains("Too many subdomains"))
    }

    @Test func fewSubdomainsAreFine() {
        #expect(!titles(for: "https://shop.example.com").contains("Too many subdomains"))
    }

    @Test func domainFullOfHyphensIsFlagged() {
        #expect(titles(for: "https://my-safe-bank-login.com").contains("Many hyphens"))
    }

    @Test func singleHyphenIsFine() {
        #expect(!titles(for: "https://my-shop.com").contains("Many hyphens"))
    }

    @Test(arguments: ["https://prize.xyz", "https://free-gift.top", "https://claim.click"])
    func unusualDomainEndingIsFlagged(address: String) {
        #expect(titles(for: address).contains("Unusual domain ending"))
    }

    @Test func commonDomainEndingIsFine() {
        #expect(!titles(for: "https://example.com").contains("Unusual domain ending"))
    }

    @Test func sensitiveWordInThePathIsFlagged() {
        #expect(titles(for: "https://example.com/login").contains("Sensitive wording"))
    }

    @Test func veryLongLinkIsFlagged() {
        let address = "https://example.com/" + String(repeating: "a", count: 100)
        #expect(titles(for: address).contains("Very long link"))
    }

    @Test func shortLinkIsNotCalledLong() {
        #expect(!titles(for: "https://example.com/page").contains("Very long link"))
    }

    @Test func uppercaseSchemeAndHostAreStillRecognised() {
        #expect(titles(for: "HTTP://EXAMPLE.COM").contains("Not encrypted"))
    }

    @Test func numbersThatAreNotAnIPAddressAreNotFlaggedAsOne() {
        #expect(!titles(for: "https://999.1.1.1/pay").contains("Raw IP address"))
    }

    @Test func normalizeTrimsSpacesAndNewlines() {
        #expect(URLAnalyzer.normalize("  example.com \n")?.absoluteString == "https://example.com")
    }

    @Test func normalizeKeepsAnExistingScheme() {
        #expect(URLAnalyzer.normalize("http://example.com/a")?.absoluteString == "http://example.com/a")
    }

    @Test(arguments: ["http://", "https://exa mple.com", "https://nodots"])
    func normalizeRejectsBrokenAddresses(_ raw: String) {
        #expect(URLAnalyzer.normalize(raw) == nil)
    }

    @Test func officialSiteWithAPathStillHasNoStrongWarnings() throws {
        let url = try #require(URLAnalyzer.normalize("https://www.paypal.com/signin"))
        let strongWarnings = analyzer.analyze(url).filter { $0.weight >= 25 }
        #expect(strongWarnings.isEmpty)
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
