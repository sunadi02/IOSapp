//
//  LinkScannerCommunityTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-24.
//

import Testing
import Foundation
@testable import ScamShield

@MainActor
struct LinkScannerCommunityTests {

    let community = MockCommunityService()

    private var scanner: LinkScanner {
        LinkScanner(reputation: MockReputationChecker(), community: community)
    }

    @Test func reportedWebsiteGetsACommunitySignal() async throws {
        community.counts["example.com"] = 3
        let result = try await scanner.scan("https://example.com")

        let signal = try #require(result.signals.first { $0.title == "Reported by the community" })
        #expect(signal.weight == 40)
        #expect(signal.detail.contains("3 ScamShield users have"))
        #expect(result.trustScore == 60)
    }

    @Test func singleReportIsWorded() async throws {
        community.counts["example.com"] = 1
        let result = try await scanner.scan("https://example.com")
        #expect(result.signals.first?.detail.contains("1 ScamShield user has") == true)
    }

    @Test func aSingleReportIsEnoughToStopASafeVerdict() async throws {
        community.counts["example.com"] = 1
        let result = try await scanner.scan("https://example.com")
        #expect(result.riskLevel == .unknown)
    }

    @Test func fiveReportsMakeTheLinkRisky() async throws {
        community.counts["example.com"] = 5
        let result = try await scanner.scan("https://example.com")
        #expect(result.riskLevel == .risky)
    }

    @Test func unreportedWebsiteHasNoCommunitySignal() async throws {
        let result = try await scanner.scan("https://example.com")
        #expect(!result.signals.contains { $0.title == "Reported by the community" })
        #expect(result.riskLevel == .safe)
    }

    @Test func failedCommunityLookupIsIgnored() async throws {
        community.countError = URLError(.notConnectedToInternet)
        let result = try await scanner.scan("https://example.com")
        #expect(result.riskLevel == .safe)
    }

    @Test func subdomainsLookUpTheRegisteredDomain() async throws {
        _ = try await scanner.scan("https://login.secure.evil.com/path?token=1")
        #expect(community.queriedDomains == ["evil.com"])
    }

    @Test func scannerWithoutCommunityNeverLooksAnythingUp() async throws {
        let plain = LinkScanner(reputation: MockReputationChecker())
        let result = try await plain.scan("https://example.com")
        #expect(result.trustScore == 100)
    }

    @Test(arguments: [(1, 25), (2, 40), (4, 40), (5, 55), (50, 55)])
    func weightGrowsWithTheNumberOfReports(count: Int, expected: Int) {
        #expect(LinkScanner.communityWeight(for: count) == expected)
    }
}
