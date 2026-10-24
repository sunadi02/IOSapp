//
//  LinkExtractorTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-24.
//

import Testing
import Foundation
@testable import ScamShield

@MainActor
struct LinkExtractorTests {

    private func addresses(in text: String) -> [String] {
        LinkExtractor.links(in: text).map(\.absoluteString)
    }

    @Test func findsAFullLinkAndDropsTrailingPunctuation() {
        #expect(addresses(in: "Visit https://example.com/path now.") == ["https://example.com/path"])
    }

    @Test func bareDomainIsCheckedOverHttps() {
        #expect(addresses(in: "go to bit.ly/3abcXYZ today") == ["https://bit.ly/3abcXYZ"])
    }

    @Test func insecureLinkKeepsItsScheme() {
        #expect(addresses(in: "open http://example.com/login") == ["http://example.com/login"])
    }

    @Test func linksComeBackInOrderWithoutRepeats() {
        let text = "https://b.com then https://a.com and again https://b.com"
        #expect(addresses(in: text) == ["https://b.com", "https://a.com"])
    }

    @Test func emailAddressesAreNotLinks() {
        #expect(addresses(in: "write to help@example.com").isEmpty)
    }

    @Test func textWithoutLinksGivesNothing() {
        #expect(addresses(in: "Hi, see you at lunch tomorrow").isEmpty)
        #expect(addresses(in: "").isEmpty)
    }

    @Test func atMostFiveLinksAreReturned() {
        let text = (1...8).map { "https://site\($0).com" }.joined(separator: " ")
        #expect(addresses(in: text).count == LinkExtractor.maxLinks)
    }

    @Test func rangesPointAtTheLinkText() {
        let text = "Open https://example.com/a now"
        let found = LinkExtractor.ranges(in: text).map { String(text[$0]) }
        #expect(found == ["https://example.com/a"])
    }
}
