//
//  SafeBrowsingServiceTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-23.
//

import Testing
import Foundation
@testable import ScamShield

@MainActor
struct SafeBrowsingServiceTests {

    let link = URL(string: "https://example.com")!

    @Test func requestFailsWithoutKey() {
        let service = SafeBrowsingService(apiKey: nil)
        #expect(throws: SafeBrowsingError.missingAPIKey) {
            try service.makeRequest(for: link)
        }
    }

    @Test func requestIsPostWithKeyAndLink() throws {
        let request = try SafeBrowsingService(apiKey: "abc").makeRequest(for: link)
        let body = String(data: try #require(request.httpBody), encoding: .utf8) ?? ""

        #expect(request.httpMethod == "POST")
        #expect(request.url?.query == "key=abc")
        #expect(body.contains("SOCIAL_ENGINEERING"))
        #expect(body.contains("example.com"))
    }

    @Test func emptyResponseMeansNoThreats() throws {
        #expect(try SafeBrowsingService.parseThreats(from: Data("{}".utf8)).isEmpty)
    }

    @Test func matchesAreReturnedWithoutDuplicates() throws {
        let json = """
        {"matches":[
          {"threatType":"SOCIAL_ENGINEERING","platformType":"ANY_PLATFORM","threat":{"url":"a"}},
          {"threatType":"MALWARE","platformType":"ANY_PLATFORM","threat":{"url":"a"}},
          {"threatType":"MALWARE","platformType":"WINDOWS","threat":{"url":"a"}}
        ]}
        """
        #expect(try SafeBrowsingService.parseThreats(from: Data(json.utf8)) == ["MALWARE", "SOCIAL_ENGINEERING"])
    }

    @Test func brokenJSONThrows() {
        #expect(throws: (any Error).self) {
            try SafeBrowsingService.parseThreats(from: Data("not json".utf8))
        }
    }
}
