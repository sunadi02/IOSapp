//
//  AppSecretsTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-24.
//

import Testing
import Foundation
@testable import ScamShield

@MainActor
struct AppSecretsTests {

    //makes a throwaway folder that acts as an app bundle holding an optional Secrets.plist
    private func makeBundle(plist contents: Data?) throws -> (bundle: Bundle, folder: URL) {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        if let contents {
            try contents.write(to: folder.appendingPathComponent("Secrets.plist"))
        }
        return (try #require(Bundle(url: folder)), folder)
    }

    private func plistData(_ values: [String: Any]) throws -> Data {
        try PropertyListSerialization.data(fromPropertyList: values, format: .xml, options: 0)
    }

    @Test func storedKeyIsReturned() throws {
        let (bundle, folder) = try makeBundle(plist: plistData(["SafeBrowsingAPIKey": "abc123"]))
        defer { try? FileManager.default.removeItem(at: folder) }

        #expect(AppSecrets.value(for: "SafeBrowsingAPIKey", bundle: bundle) == "abc123")
    }

    @Test func missingKeyGivesNil() throws {
        let (bundle, folder) = try makeBundle(plist: plistData(["Other": "x"]))
        defer { try? FileManager.default.removeItem(at: folder) }

        #expect(AppSecrets.value(for: "SafeBrowsingAPIKey", bundle: bundle) == nil)
    }

    @Test func valueThatIsNotTextGivesNil() throws {
        let (bundle, folder) = try makeBundle(plist: plistData(["SafeBrowsingAPIKey": 42]))
        defer { try? FileManager.default.removeItem(at: folder) }

        #expect(AppSecrets.value(for: "SafeBrowsingAPIKey", bundle: bundle) == nil)
    }

    @Test func missingFileGivesNil() throws {
        let (bundle, folder) = try makeBundle(plist: nil)
        defer { try? FileManager.default.removeItem(at: folder) }

        #expect(AppSecrets.value(for: "SafeBrowsingAPIKey", bundle: bundle) == nil)
    }

    @Test func brokenFileGivesNilInsteadOfCrashing() throws {
        let (bundle, folder) = try makeBundle(plist: Data("this is not a property list".utf8))
        defer { try? FileManager.default.removeItem(at: folder) }

        #expect(AppSecrets.value(for: "SafeBrowsingAPIKey", bundle: bundle) == nil)
    }

    @Test func serviceWithoutAKeyReportsItClearly() throws {
        let (bundle, folder) = try makeBundle(plist: nil)
        defer { try? FileManager.default.removeItem(at: folder) }

        let service = SafeBrowsingService(apiKey: AppSecrets.value(for: "SafeBrowsingAPIKey", bundle: bundle))
        #expect(throws: SafeBrowsingError.missingAPIKey) {
            try service.makeRequest(for: URL(string: "https://example.com")!)
        }
    }
}
