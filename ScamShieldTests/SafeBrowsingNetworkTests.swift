//
//  SafeBrowsingNetworkTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-24.
//

import Testing
import Foundation
@testable import ScamShield

//these send real requests through URLSession, but a stub answers them instead of Google
@MainActor
struct SafeBrowsingNetworkTests {

    private let link = URL(string: "https://example.com/offer")!

    private func makeService(apiKey: String? = UUID().uuidString, handler: @escaping StubURLProtocol.Handler) -> SafeBrowsingService {
        if let apiKey {
            StubURLProtocol.register(id: apiKey, handler: handler)
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return SafeBrowsingService(apiKey: apiKey, session: URLSession(configuration: configuration))
    }

    @Test func cleanLinkGivesNoThreats() async throws {
        let service = makeService { _ in (200, stubJSON("{}")) }
        #expect(try await service.threats(for: link).isEmpty)
    }

    @Test func reportedLinkGivesItsThreatTypes() async throws {
        let body = stubJSON(#"{"matches":[{"threatType":"SOCIAL_ENGINEERING"},{"threatType":"MALWARE"}]}"#)
        let service = makeService { _ in (200, body) }

        #expect(try await service.threats(for: link) == ["MALWARE", "SOCIAL_ENGINEERING"])
    }

    @Test(arguments: [400, 403, 429, 500])
    func errorStatusIsReportedWithItsCode(status: Int) async {
        let service = makeService { _ in (status, stubJSON("{}")) }

        await #expect(throws: SafeBrowsingError.badStatus(status)) {
            try await service.threats(for: link)
        }
    }

    @Test func networkFailureIsPassedOn() async {
        let service = makeService { _ in throw URLError(.notConnectedToInternet) }

        await #expect(throws: URLError.self) {
            try await service.threats(for: link)
        }
    }

    @Test func answerThatIsNotJSONIsAnError() async {
        let service = makeService { _ in (200, stubJSON("<html>oops</html>")) }

        await #expect(throws: (any Error).self) {
            try await service.threats(for: link)
        }
    }

    @Test func requestSendsThePostWithTheLinkInTheBody() async throws {
        let seen = RequestBox()
        let service = makeService { request in
            seen.request = request
            return (200, stubJSON("{}"))
        }

        _ = try await service.threats(for: link)

        let request = try #require(seen.request)
        let body = String(data: try #require(request.readBody()), encoding: .utf8) ?? ""
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(body.contains("example.com"))
        #expect(body.contains("offer"))
        #expect(body.contains("\"URL\""))
    }

    @Test func withoutAKeyNothingIsSentAtAll() async {
        let seen = RequestBox()
        let service = makeService(apiKey: nil) { request in
            seen.request = request
            return (200, stubJSON("{}"))
        }

        await #expect(throws: SafeBrowsingError.missingAPIKey) {
            try await service.threats(for: link)
        }
        #expect(seen.request == nil)
    }

    @Test func reportedLinkMakesTheScannerCallItRisky() async throws {
        let body = stubJSON(#"{"matches":[{"threatType":"SOCIAL_ENGINEERING"}]}"#)
        let service = makeService { _ in (200, body) }

        let result = try await LinkScanner(reputation: service).scan("https://example.com/offer")
        #expect(result.riskLevel == .risky)
        #expect(result.signals.first?.title == "Reported by Google Safe Browsing")
    }

    @Test func serverErrorLeavesTheScannerUnsureInsteadOfSafe() async throws {
        let service = makeService { _ in (500, stubJSON("{}")) }

        let result = try await LinkScanner(reputation: service).scan("https://www.apple.com")
        #expect(result.riskLevel == .unknown)
        #expect(result.signals.map(\.title).contains(LinkScanner.onlineCheckUnavailableTitle))
    }
}

private func stubJSON(_ text: String) -> Data {
    Data(text.utf8)
}

//holds the request a stub saw so a test can look at it afterwards
final class RequestBox: @unchecked Sendable {
    var request: URLRequest?
}
