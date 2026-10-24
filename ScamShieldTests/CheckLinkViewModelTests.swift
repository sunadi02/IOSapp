//
//  CheckLinkViewModelTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-23.
//

import Testing
import Foundation
@testable import ScamShield

@MainActor
struct CheckLinkViewModelTests {

    let history = CoreDataHistoryRepository(context: PersistenceController(inMemory: true).viewContext)

    private func makeViewModel(threats: [String] = []) -> CheckLinkViewModel {
        let scanner = LinkScanner(reputation: MockReputationChecker(foundThreats: threats))
        return CheckLinkViewModel(scanner: scanner, history: history)
    }

    @Test(arguments: ["", "   ", "\n"])
    func cannotCheckEmptyInput(_ input: String) {
        let viewModel = makeViewModel()
        viewModel.input = input
        #expect(!viewModel.canCheck)
    }

    @Test func successfulCheckShowsResultAndSavesIt() async throws {
        let viewModel = makeViewModel(threats: ["MALWARE"])
        viewModel.input = "example.com"
        await viewModel.check()

        let result = try #require(viewModel.result)
        #expect(result.riskLevel == .risky)
        #expect(try history.fetchAll().map(\.id) == [result.id])
        #expect(!viewModel.isChecking)
    }

    @Test func invalidLinkShowsErrorAndSavesNothing() async throws {
        let viewModel = makeViewModel()
        viewModel.input = "hello there"
        await viewModel.check()

        #expect(viewModel.result == nil)
        #expect(viewModel.errorMessage != nil)
        #expect(try history.fetchAll().isEmpty)
    }

    @Test func offlineCheckStillShowsAndSavesAnUnsureResult() async throws {
        let scanner = LinkScanner(reputation: MockReputationChecker(error: URLError(.notConnectedToInternet)))
        let viewModel = CheckLinkViewModel(scanner: scanner, history: history)
        viewModel.input = "www.apple.com"
        await viewModel.check()

        let result = try #require(viewModel.result)
        #expect(result.riskLevel == .unknown)
        #expect(try history.fetchAll().map(\.id) == [result.id])
    }

    @Test func nextSuccessfulCheckClearsTheOldError() async {
        let viewModel = makeViewModel()
        viewModel.input = "hello there"
        await viewModel.check()
        #expect(viewModel.errorMessage != nil)

        viewModel.input = "apple.com"
        await viewModel.check()
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.result != nil)
    }

    @Test func eachCheckGivesANewResult() async throws {
        let viewModel = makeViewModel()
        viewModel.input = "apple.com"
        await viewModel.check()
        let first = try #require(viewModel.result)

        await viewModel.check()
        let second = try #require(viewModel.result)

        #expect(first.id != second.id)
        #expect(try history.fetchAll().count == 2)
    }

    @Test func inputWithSurroundingSpacesCanBeChecked() {
        let viewModel = makeViewModel()
        viewModel.input = "  apple.com  "
        #expect(viewModel.canCheck)
    }

    @Test func shareTextIncludesLevelAndScore() async throws {
        let viewModel = makeViewModel()
        viewModel.input = "apple.com"
        await viewModel.check()

        let text = try #require(viewModel.result).shareText
        #expect(text.contains("Safe"))
        #expect(text.contains("100/100"))
    }
}
