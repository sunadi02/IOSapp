//
//  SafeBrowsingService.swift
//  ScamShield
//
//  Created by student2 on 2026-10-23.
//

import Foundation

//protocol so the scanner can be tested with a fake checker
protocol LinkReputationChecking {
    func threats(for url: URL) async throws -> [String]
}

enum SafeBrowsingError: Error, Equatable {
    case missingAPIKey
    case badStatus(Int)
}

//checks links against google safe browsing lookup api v4
struct SafeBrowsingService: LinkReputationChecking {

    static let endpoint = URL(string: "https://safebrowsing.googleapis.com/v4/threatMatches:find")!
    static let threatTypes = ["MALWARE", "SOCIAL_ENGINEERING", "UNWANTED_SOFTWARE", "POTENTIALLY_HARMFUL_APPLICATION"]

    let apiKey: String?
    let session: URLSession

    init(apiKey: String? = AppSecrets.value(for: "SafeBrowsingAPIKey"), session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    //returns the threat types google found, empty means no known threat
    func threats(for url: URL) async throws -> [String] {
        let request = try makeRequest(for: url)
        let (data, response) = try await session.data(for: request)

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw SafeBrowsingError.badStatus(http.statusCode)
        }
        return try Self.parseThreats(from: data)
    }

    func makeRequest(for url: URL) throws -> URLRequest {
        guard let apiKey, !apiKey.isEmpty else { throw SafeBrowsingError.missingAPIKey }

        var components = URLComponents(url: Self.endpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]

        let body = LookupRequest(
            client: .init(clientId: "scamshield", clientVersion: "1.0"),
            threatInfo: .init(
                threatTypes: Self.threatTypes,
                platformTypes: ["ANY_PLATFORM"],
                threatEntryTypes: ["URL"],
                threatEntries: [.init(url: url.absoluteString)]
            )
        )

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        request.timeoutInterval = 10
        return request
    }

    //google sends an empty object when the link is clean
    static func parseThreats(from data: Data) throws -> [String] {
        let response = try JSONDecoder().decode(LookupResponse.self, from: data)
        let types = (response.matches ?? []).map(\.threatType)
        return Array(Set(types)).sorted()
    }
}

//request and response shapes from the api docs
private struct LookupRequest: Encodable {
    struct Client: Encodable { let clientId: String; let clientVersion: String }
    struct Entry: Encodable { let url: String }
    struct ThreatInfo: Encodable {
        let threatTypes: [String]
        let platformTypes: [String]
        let threatEntryTypes: [String]
        let threatEntries: [Entry]
    }
    let client: Client
    let threatInfo: ThreatInfo
}

private struct LookupResponse: Decodable {
    struct Match: Decodable { let threatType: String }
    let matches: [Match]?
}
