//
//  QRScannerViewModelTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-24.
//

import Testing
import Foundation
@testable import ScamShield

@MainActor
struct QRScannerViewModelTests {

    let camera = MockCamera()
    let history = CoreDataHistoryRepository(context: PersistenceController(inMemory: true).viewContext)

    private func makeViewModel(detector: MockBarcodeDetector = MockBarcodeDetector(), threats: [String] = []) -> QRScannerViewModel {
        let linkScanner = LinkScanner(reputation: MockReputationChecker(foundThreats: threats))
        return QRScannerViewModel(camera: camera, detector: detector, scanner: QRScanner(linkScanner: linkScanner), history: history)
    }

    @Test func grantedCameraStartsScanning() async {
        let viewModel = makeViewModel()
        await viewModel.startCamera()

        #expect(viewModel.cameraState == .scanning)
        #expect(camera.startCount == 1)
    }

    @Test func deniedCameraShowsDeniedState() async {
        camera.setupResult = .denied
        let viewModel = makeViewModel()
        await viewModel.startCamera()

        #expect(viewModel.cameraState == .denied)
        #expect(camera.startCount == 0)
    }

    @Test func missingCameraShowsUnavailableState() async {
        camera.setupResult = .unavailable
        let viewModel = makeViewModel()
        await viewModel.startCamera()

        #expect(viewModel.cameraState == .unavailable)
    }

    @Test func startingTwiceOnlyStartsTheCameraOnce() async {
        let viewModel = makeViewModel()
        await viewModel.startCamera()
        await viewModel.startCamera()
        #expect(camera.startCount == 1)
    }

    @Test func scannedCodeStopsTheCameraAndSavesTheResult() async throws {
        let viewModel = makeViewModel()
        await viewModel.startCamera()
        await viewModel.handle(code: "https://www.apple.com")

        let result = try #require(viewModel.result)
        #expect(result.type == .qr)
        #expect(camera.stopCount == 1)
        #expect(viewModel.cameraState == .idle)
        #expect(!viewModel.isAnalysing)
        #expect(try history.fetchAll().map(\.id) == [result.id])
    }

    @Test func riskyCodeIsSavedAsRisky() async throws {
        let viewModel = makeViewModel(threats: ["MALWARE"])
        await viewModel.handle(code: "https://www.example.com")
        #expect(viewModel.result?.riskLevel == .risky)
    }

    @Test func secondCodeIsIgnoredWhileAResultIsShown() async throws {
        let viewModel = makeViewModel()
        await viewModel.handle(code: "https://www.apple.com")
        let first = viewModel.result

        await viewModel.handle(code: "Table 12")
        #expect(viewModel.result == first)
        #expect(try history.fetchAll().count == 1)
    }

    @Test func returningToTheScreenAllowsAnotherScan() async {
        let viewModel = makeViewModel()
        await viewModel.startCamera()
        await viewModel.handle(code: "https://www.apple.com")

        viewModel.prepareToScan()
        await viewModel.startCamera()
        #expect(viewModel.result == nil)
        #expect(camera.startCount == 2)
        #expect(viewModel.cameraState == .scanning)
    }

    @Test func photoWithACodeIsChecked() async throws {
        let viewModel = makeViewModel(detector: MockBarcodeDetector(found: ["https://www.apple.com"]))
        await viewModel.scan(photoData: Data([1, 2, 3]))

        let result = try #require(viewModel.result)
        #expect(result.input == "https://www.apple.com")
        #expect(viewModel.errorMessage == nil)
    }

    @Test func photoWithoutACodeShowsAMessage() async throws {
        let viewModel = makeViewModel(detector: MockBarcodeDetector(found: []))
        await viewModel.scan(photoData: Data([1, 2, 3]))

        #expect(viewModel.result == nil)
        #expect(viewModel.errorMessage != nil)
        #expect(try history.fetchAll().isEmpty)
    }

    @Test func unreadablePhotoShowsTheSameMessage() async {
        let viewModel = makeViewModel(detector: MockBarcodeDetector(shouldFail: true))
        await viewModel.scan(photoData: Data())

        #expect(viewModel.result == nil)
        #expect(viewModel.errorMessage != nil)
    }

    @Test func preparingToScanClearsOldMessages() async {
        let viewModel = makeViewModel(detector: MockBarcodeDetector(found: []))
        await viewModel.scan(photoData: Data())

        viewModel.prepareToScan()
        #expect(viewModel.errorMessage == nil)
    }

    @Test func torchFollowsTheToggleAndTurnsOffWhenStopping() async {
        let viewModel = makeViewModel()
        await viewModel.startCamera()

        viewModel.toggleTorch()
        #expect(viewModel.isTorchOn)
        #expect(camera.torchStates == [true])

        viewModel.stopCamera()
        #expect(!viewModel.isTorchOn)
        #expect(camera.torchStates == [true, false])
    }
}
