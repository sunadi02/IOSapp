//
//  ScreenshotScanViewModelTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-24.
//

import Testing
import Foundation
@testable import ScamShield

@MainActor
struct ScreenshotScanViewModelTests {

    let history = CoreDataHistoryRepository(context: PersistenceController(inMemory: true).viewContext)

    private func makeViewModel(recognizer: MockTextRecognizer = MockTextRecognizer(), threats: [String] = []) -> ScreenshotScanViewModel {
        let linkScanner = LinkScanner(reputation: MockReputationChecker(foundThreats: threats))
        let scanner = MessageScanner(classifier: MockScamClassifier(), linkScanner: linkScanner)
        return ScreenshotScanViewModel(recognizer: recognizer, scanner: scanner, history: history)
    }

    @Test func recognisedTextFillsTheEditor() async {
        let viewModel = makeViewModel(recognizer: MockTextRecognizer(text: "Your account is blocked"))
        await viewModel.recognize(imageData: Data([1]))

        #expect(viewModel.text == "Your account is blocked")
        #expect(viewModel.errorMessage == nil)
        #expect(!viewModel.isRecognising)
    }

    @Test func screenshotWithoutTextShowsAMessage() async {
        let viewModel = makeViewModel(recognizer: MockTextRecognizer(text: "  \n "))
        await viewModel.recognize(imageData: Data([1]))

        #expect(viewModel.text.isEmpty)
        #expect(viewModel.errorMessage != nil)
    }

    @Test func unreadableScreenshotShowsTheSameMessage() async {
        let viewModel = makeViewModel(recognizer: MockTextRecognizer(shouldFail: true))
        await viewModel.recognize(imageData: Data())

        #expect(viewModel.errorMessage != nil)
    }

    @Test func newScreenshotClearsTheOldError() async {
        let viewModel = makeViewModel(recognizer: MockTextRecognizer(shouldFail: true))
        await viewModel.recognize(imageData: Data())
        #expect(viewModel.errorMessage != nil)

        let better = makeViewModel(recognizer: MockTextRecognizer(text: "hello there"))
        better.errorMessage = "old"
        await better.recognize(imageData: Data([1]))
        #expect(better.errorMessage == nil)
    }

    @Test(arguments: ["", "   ", "\n\n"])
    func blankTextCannotBeChecked(_ text: String) {
        let viewModel = makeViewModel()
        viewModel.text = text
        #expect(!viewModel.canCheck)
    }

    @Test func checkingSavesAScreenshotResult() async throws {
        let viewModel = makeViewModel()
        viewModel.text = "URGENT: your account is suspended, share your OTP"
        await viewModel.check()

        let result = try #require(viewModel.result)
        #expect(result.type == .screenshot)
        #expect(result.riskLevel == .risky)
        #expect(try history.fetchAll().map(\.id) == [result.id])
        #expect(!viewModel.isChecking)
    }

    @Test func editedTextIsWhatGetsChecked() async throws {
        let viewModel = makeViewModel(recognizer: MockTextRecognizer(text: "Verfy yuor acount"))
        await viewModel.recognize(imageData: Data([1]))
        viewModel.text = "See you at lunch"
        await viewModel.check()

        #expect(viewModel.result?.input == "See you at lunch")
    }

    @Test func linksFollowTheEditedText() {
        let viewModel = makeViewModel()
        viewModel.text = "Open https://example.com/pay"
        #expect(viewModel.detectedLinks.map(\.absoluteString) == ["https://example.com/pay"])

        viewModel.text = "No link here"
        #expect(viewModel.detectedLinks.isEmpty)
    }

    @Test func checkingWithoutTextDoesNothing() async throws {
        let viewModel = makeViewModel()
        await viewModel.check()

        #expect(viewModel.result == nil)
        #expect(try history.fetchAll().isEmpty)
    }
}
