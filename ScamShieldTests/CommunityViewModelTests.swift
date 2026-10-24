//
//  CommunityViewModelTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-24.
//

import Testing
import Foundation
@testable import ScamShield

@MainActor
struct CommunityViewModelTests {

    let service = MockCommunityService()
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func report(_ domain: String, category: ScamCategory = .other, daysAgo: Double = 0) -> ScamReport {
        ScamReport(
            id: UUID().uuidString,
            domain: domain,
            type: .link,
            category: category,
            createdAt: now.addingTimeInterval(-daysAgo * 86_400)
        )
    }

    private func makeViewModel() -> CommunityViewModel {
        CommunityViewModel(service: service)
    }

    @Test func listeningLoadsTheFeed() async {
        service.feed = [report("a.com"), report("b.com")]
        let viewModel = makeViewModel()
        #expect(viewModel.isLoading)

        await viewModel.listen()
        #expect(viewModel.reports.count == 2)
        #expect(!viewModel.isLoading)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func failedFeedShowsErrorAndStopsLoading() async {
        service.feedError = URLError(.notConnectedToInternet)
        let viewModel = makeViewModel()

        await viewModel.listen()
        #expect(viewModel.errorMessage != nil)
        #expect(!viewModel.isLoading)
        #expect(viewModel.reports.isEmpty)
    }

    @Test func categoryFilterKeepsOnlyThatCategory() async {
        service.feed = [report("a.com", category: .deliveryFee), report("b.com", category: .jobOffer)]
        let viewModel = makeViewModel()
        await viewModel.listen()

        viewModel.selectedCategory = .jobOffer
        #expect(viewModel.filteredReports.map(\.domain) == ["b.com"])

        viewModel.selectedCategory = nil
        #expect(viewModel.filteredReports.count == 2)
    }

    @Test func trendingCountsOnlyTheLastSevenDays() async {
        service.feed = [
            report("hot.com"), report("hot.com", daysAgo: 1), report("hot.com", daysAgo: 3),
            report("warm.com", daysAgo: 2),
            report("old.com", daysAgo: 10), report("old.com", daysAgo: 12)
        ]
        let viewModel = makeViewModel()
        await viewModel.listen()

        let trending = viewModel.trending(now: now)
        #expect(trending.map(\.domain) == ["hot.com", "warm.com"])
        #expect(trending.map(\.count) == [3, 1])
    }

    @Test func tiesAreBrokenByDomainName() async {
        service.feed = [report("zeta.com"), report("alpha.com")]
        let viewModel = makeViewModel()
        await viewModel.listen()

        #expect(viewModel.trending(now: now).map(\.domain) == ["alpha.com", "zeta.com"])
    }

    @Test func trendingShowsAtMostFiveDomains() async {
        service.feed = (1...8).map { report("site\($0).com") }
        let viewModel = makeViewModel()
        await viewModel.listen()

        #expect(viewModel.trending(now: now).count == CommunityViewModel.trendingLimit)
    }

    @Test func noReportsMeansNothingTrending() {
        #expect(makeViewModel().trending(now: now).isEmpty)
    }
}
