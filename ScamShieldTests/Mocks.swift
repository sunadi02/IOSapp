//
//  Mocks.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-24.
//

import AVFoundation
import Foundation
@testable import ScamShield

//every fake used by more than one test file lives here, so a test only needs to name what it fakes

//fake safe browsing checker so tests never call the real api
struct MockReputationChecker: LinkReputationChecking {
    var foundThreats: [String] = []
    var error: Error?

    func threats(for url: URL) async throws -> [String] {
        if let error { throw error }
        return foundThreats
    }
}

//fake auth service that records calls and can be told to fail
final class MockAuthService: AuthServicing {
    var currentUser: AppUser?
    var errorToThrow: Error?
    private(set) var signInCalls = 0
    private(set) var resetEmails: [String] = []
    private(set) var updatedNames: [String] = []

    func signIn(email: String, password: String) async throws -> AppUser {
        signInCalls += 1
        if let errorToThrow { throw errorToThrow }
        return AppUser(id: "1", email: email, displayName: nil)
    }

    func signUp(name: String, email: String, password: String) async throws -> AppUser {
        if let errorToThrow { throw errorToThrow }
        return AppUser(id: "1", email: email, displayName: name)
    }

    func sendPasswordReset(email: String) async throws {
        if let errorToThrow { throw errorToThrow }
        resetEmails.append(email)
    }

    func updateDisplayName(_ name: String) async throws -> AppUser {
        if let errorToThrow { throw errorToThrow }
        updatedNames.append(name)
        return AppUser(id: "1", email: "user@example.com", displayName: name)
    }

    func signOut() throws {
        if let errorToThrow { throw errorToThrow }
    }
}

//store that always fails so error handling can be tested
struct FailingHistoryStore: HistoryStoring {
    struct StoreError: Error {}

    func save(_ result: ScanResult) throws { throw StoreError() }
    func fetchAll() throws -> [ScanResult] { throw StoreError() }
    func fetchUnsynced() throws -> [ScanResult] { throw StoreError() }
    func markSynced(ids: [UUID]) throws { throw StoreError() }
    func delete(id: UUID) throws { throw StoreError() }
    func deleteAll() throws { throw StoreError() }
}

//fake face id so tests never show a real prompt
@MainActor
final class MockBiometricAuthenticator: BiometricAuthenticating {
    var kind: BiometricKind = .faceID
    var result: Result<Void, BiometricError> = .success(())
    private(set) var attempts = 0

    func authenticate(reason: String) async throws {
        attempts += 1
        try result.get()
    }
}

//answers web requests from a closure so the networking code can be tested without the internet
//each test registers its own id, which the service sends as its api key, so tests running side by side never meet
final class StubURLProtocol: URLProtocol {

    typealias Handler = (URLRequest) throws -> (status: Int, body: Data)

    private static let lock = NSLock()
    nonisolated(unsafe) private static var handlers: [String: Handler] = [:]

    static func register(id: String, handler: @escaping Handler) {
        lock.lock()
        defer { lock.unlock() }
        handlers[id] = handler
    }

    private static func handler(for id: String) -> Handler? {
        lock.lock()
        defer { lock.unlock() }
        return handlers[id]
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url,
              let id = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "key" })?.value,
              let handler = Self.handler(for: id) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        do {
            let answer = try handler(request)
            let response = HTTPURLResponse(url: url, statusCode: answer.status, httpVersion: nil, headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: answer.body)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

extension URLRequest {

    //url loading turns a request body into a stream, so it has to be read back out
    func readBody() -> Data? {
        if let httpBody { return httpBody }
        guard let stream = httpBodyStream else { return nil }

        stream.open()
        defer { stream.close() }

        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count <= 0 { break }
            data.append(buffer, count: count)
        }
        return data
    }
}

//records alerts instead of showing real notifications
@MainActor
final class MockNotifier: NotificationScheduling {
    var permissionGranted = true
    private(set) var permissionRequests = 0
    private(set) var alerts: [ScanResult] = []

    func requestPermission() async -> Bool {
        permissionRequests += 1
        return permissionGranted
    }

    func sendScamAlert(for scan: ScanResult) async {
        alerts.append(scan)
    }
}

//answers by host so one link can be flagged while the rest stay clean
@MainActor
final class StubReputationChecker: LinkReputationChecking {
    var threatsByHost: [String: [String]] = [:]
    var error: Error?
    private(set) var checkedURLs: [URL] = []

    func threats(for url: URL) async throws -> [String] {
        checkedURLs.append(url)
        if let error { throw error }
        return threatsByHost[url.host() ?? ""] ?? []
    }
}

//in memory stand in for firestore with separate switches for each kind of failure
@MainActor
final class MockRemoteHistory: RemoteHistoryStoring {
    var stored: [ScanResult] = []
    var fetchError: Error?
    var uploadError: Error?
    var deleteError: Error?
    private(set) var deletedIDs: [UUID] = []

    func fetchAll(userID: String) async throws -> [ScanResult] {
        if let fetchError { throw fetchError }
        return stored
    }

    func upsert(_ results: [ScanResult], userID: String) async throws {
        if let uploadError { throw uploadError }
        for result in results {
            stored.removeAll { $0.id == result.id }
            stored.append(result)
        }
    }

    func delete(ids: [UUID], userID: String) async throws {
        if let deleteError { throw deleteError }
        deletedIDs.append(contentsOf: ids)
        stored.removeAll { ids.contains($0.id) }
    }
}

//stands in for the community collection and remembers what the app asked it
@MainActor
final class MockCommunityService: CommunityReporting {
    var counts: [String: Int] = [:]
    var countError: Error?
    var countDelay: Duration?
    var submitError: Error?
    var feed: [ScamReport] = []
    var feedError: Error?
    private(set) var queriedDomains: [String] = []
    private(set) var submissions: [(url: String, category: ScamCategory, type: ScanType)] = []

    func submit(url: String, category: ScamCategory, type: ScanType) async throws {
        if let submitError { throw submitError }
        submissions.append((url, category, type))
    }

    func reportCount(forDomain domain: String) async throws -> Int {
        queriedDomains.append(domain)
        if let countDelay { try? await Task.sleep(for: countDelay) }
        if let countError { throw countError }
        return counts[domain] ?? 0
    }

    func reports(limit: Int) -> AsyncThrowingStream<[ScamReport], Error> {
        let feed = feed
        let feedError = feedError

        return AsyncThrowingStream { continuation in
            if let feedError {
                continuation.finish(throwing: feedError)
            } else {
                continuation.yield(feed)
                continuation.finish()
            }
        }
    }
}

//camera that only counts what it was asked to do
final class MockCamera: CameraControlling {
    let session = AVCaptureSession()
    var setupResult: CameraSetupResult = .ready
    private(set) var startCount = 0
    private(set) var stopCount = 0
    private(set) var torchStates: [Bool] = []

    func configure() async -> CameraSetupResult { setupResult }
    func start(onCode: @escaping @Sendable (String) -> Void) { startCount += 1 }
    func stop() { stopCount += 1 }
    func setTorch(_ isOn: Bool) { torchStates.append(isOn) }
}

//returns the codes it was given so no real image is needed
struct MockBarcodeDetector: BarcodeDetecting {
    var found: [String] = []
    var shouldFail = false

    func payloads(inImageData data: Data) throws -> [String] {
        if shouldFail { throw URLError(.cannotDecodeContentData) }
        return found
    }

    func payloads(in pixelBuffer: CVPixelBuffer) throws -> [String] { found }
}

//gives a fixed answer and remembers what it was asked, nil means the model is not installed
@MainActor
final class MockScamClassifier: ScamClassifying {
    var probability: Double?
    private(set) var checkedTexts: [String] = []

    init(probability: Double? = nil) {
        self.probability = probability
    }

    func scamProbability(for text: String) -> Double? {
        checkedTexts.append(text)
        return probability
    }
}

//hands back fixed text so no real screenshot is needed
struct MockTextRecognizer: TextRecognizing {
    var text = ""
    var shouldFail = false

    func recognizeText(inImageData data: Data) throws -> String {
        if shouldFail { throw URLError(.cannotDecodeContentData) }
        return text
    }
}

//lets a test sign the user in and out after the service was created
@MainActor
final class SessionBox {
    var userID: String? = "user-1"
}
