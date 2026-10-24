//
//  FirestoreCommunityServiceTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-24.
//

import Testing
import Foundation
@testable import ScamShield

@MainActor
struct FirestoreCommunityServiceTests {

    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private func data(domain: String = "evil.com", extra: [String: Any] = [:]) -> [String: Any] {
        var data: [String: Any] = ["domain": domain, "type": "qr", "category": "deliveryFee", "createdAt": date]
        data.merge(extra) { _, new in new }
        return data
    }

    @Test func documentBecomesAReport() {
        let report = FirestoreCommunityService.report(id: "abc", data: data())
        #expect(report == ScamReport(id: "abc", domain: "evil.com", type: .qr, category: .deliveryFee, createdAt: date))
    }

    @Test func unknownCategoryAndTypeFallBackToDefaults() {
        let report = FirestoreCommunityService.report(id: "abc", data: data(extra: ["category": "alien", "type": "hologram"]))
        #expect(report?.category == .other)
        #expect(report?.type == .link)
    }

    @Test func documentWithoutADomainIsSkipped() {
        #expect(FirestoreCommunityService.report(id: "abc", data: data(domain: "")) == nil)
    }

    @Test func documentWithoutADateIsSkipped() {
        var broken = data()
        broken["createdAt"] = nil
        #expect(FirestoreCommunityService.report(id: "abc", data: broken) == nil)
    }

    @Test(arguments: [
        ("https://login.evil.com/x?y=1", "evil.com"),
        ("https://shop.example.co.uk", "example.co.uk"),
        ("https://EVIL.com", "evil.com"),
        ("http://192.168.1.10/pay", "192.168.1.10")
    ])
    func domainIsTheRegisteredPartOfTheHost(address: String, expected: String) throws {
        let url = try #require(URL(string: address))
        #expect(CommunityDomain.name(for: url) == expected)
    }

    @Test func addressWithoutAHostHasNoDomain() throws {
        let url = try #require(URL(string: "mailto:someone@example.com"))
        #expect(CommunityDomain.name(for: url) == nil)
    }

    @Test func shareableLinkDropsQueryFragmentAndLogin() throws {
        let url = try #require(URL(string: "https://user:pw@evil.com/path?token=abc#frag"))
        #expect(CommunityDomain.shareableURL(url) == "https://evil.com/path")
    }

    @Test func plainLinkIsSharedAsItIs() throws {
        let url = try #require(URL(string: "https://evil.com/path"))
        #expect(CommunityDomain.shareableURL(url) == "https://evil.com/path")
    }
}
