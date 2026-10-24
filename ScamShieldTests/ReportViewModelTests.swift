//
//  ReportViewModelTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-24.
//

import Testing
import Foundation
@testable import ScamShield

@MainActor
struct ReportViewModelTests {

    let service = MockCommunityService()
    let scan = ScanResult(type: .qr, input: "https://paypal-login.xyz/verify", riskLevel: .risky, trustScore: 10)

    private func makeViewModel() -> ReportViewModel {
        ReportViewModel(scan: scan, service: service)
    }

    @Test func startsReadyToSend() {
        let viewModel = makeViewModel()
        #expect(viewModel.state == .idle)
        #expect(viewModel.canSend)
        #expect(viewModel.category == .other)
    }

    @Test func sendingSubmitsTheChosenCategoryAndScanDetails() async throws {
        let viewModel = makeViewModel()
        viewModel.category = .bankImpersonation
        await viewModel.send()

        #expect(viewModel.state == .sent)
        let submission = try #require(service.submissions.first)
        #expect(submission.url == scan.input)
        #expect(submission.category == .bankImpersonation)
        #expect(submission.type == .qr)
    }

    @Test func reportCannotBeSentTwice() async {
        let viewModel = makeViewModel()
        await viewModel.send()
        await viewModel.send()

        #expect(!viewModel.canSend)
        #expect(service.submissions.count == 1)
    }

    @Test func alreadyReportedShowsThatMessage() async {
        service.submitError = CommunityError.alreadyReported
        let viewModel = makeViewModel()
        await viewModel.send()

        #expect(viewModel.state == .failed(CommunityError.alreadyReported.localizedDescription))
    }

    @Test func unknownErrorsShowTheGenericMessage() async {
        service.submitError = URLError(.timedOut)
        let viewModel = makeViewModel()
        await viewModel.send()

        #expect(viewModel.state == .failed(CommunityError.unavailable.localizedDescription))
    }

    @Test func failedReportCanBeRetried() async {
        service.submitError = CommunityError.unavailable
        let viewModel = makeViewModel()
        await viewModel.send()
        #expect(viewModel.canSend)

        service.submitError = nil
        await viewModel.send()
        #expect(viewModel.state == .sent)
    }
}
