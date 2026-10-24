//
//  CommunityViewModel.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import Foundation
import Observation

@Observable
final class CommunityViewModel {

    struct TrendingDomain: Identifiable, Equatable {
        let domain: String
        let count: Int
        var id: String { domain }
    }

    static let feedLimit = 100
    static let trendingLimit = 5

    var selectedCategory: ScamCategory?

    private(set) var reports: [ScamReport] = []
    private(set) var isLoading = true
    private(set) var errorMessage: String?

    private let service: CommunityReporting
    private let calendar: Calendar

    init(service: CommunityReporting = FirestoreCommunityService(), calendar: Calendar = .current) {
        self.service = service
        self.calendar = calendar
    }

    var filteredReports: [ScamReport] {
        guard let selectedCategory else { return reports }
        return reports.filter { $0.category == selectedCategory }
    }

    //runs until the screen goes away, which cancels the task and removes the firestore listener
    func listen() async {
        isLoading = true
        errorMessage = nil

        do {
            for try await latest in service.reports(limit: Self.feedLimit) {
                reports = latest
                isLoading = false
            }
        } catch {
            errorMessage = "Could not load community reports."
        }
        isLoading = false
    }

    func trending(now: Date = Date()) -> [TrendingDomain] {
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now.addingTimeInterval(-7 * 86_400)
        let recent = reports.filter { $0.createdAt >= weekAgo }
        let counts = Dictionary(grouping: recent, by: \.domain).mapValues(\.count)

        return counts
            .map { TrendingDomain(domain: $0.key, count: $0.value) }
            .sorted { $0.count != $1.count ? $0.count > $1.count : $0.domain < $1.domain }
            .prefix(Self.trendingLimit)
            .map { $0 }
    }
}
