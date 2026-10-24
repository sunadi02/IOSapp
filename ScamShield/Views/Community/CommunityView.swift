//
//  CommunityView.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import SwiftUI

struct CommunityView: View {

    @State private var viewModel = CommunityViewModel()

    var body: some View {
        List {
            Section {
                categoryChips
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            let trending = viewModel.trending()
            if !trending.isEmpty {
                Section("Most reported this week") {
                    ForEach(trending) { item in
                        TrendingRow(item: item)
                    }
                }
            }

            Section("Recent reports") {
                ForEach(viewModel.filteredReports) { report in
                    ReportRow(report: report)
                }
            }
        }
        .overlay { stateOverlay }
        .navigationTitle("Community")
        .task { await viewModel.listen() }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("All", isSelected: viewModel.selectedCategory == nil) {
                    viewModel.selectedCategory = nil
                }
                ForEach(ScamCategory.allCases) { category in
                    chip(category.title, isSelected: viewModel.selectedCategory == category) {
                        viewModel.selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private func chip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .background(isSelected ? Color.accentColor : Color(.secondarySystemFill), in: Capsule())
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var stateOverlay: some View {
        if viewModel.reports.isEmpty {
            if viewModel.isLoading {
                ProgressView("Loading reports")
            } else if viewModel.errorMessage != nil {
                ContentUnavailableView {
                    Label("Could not load reports", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(viewModel.errorMessage ?? "")
                } actions: {
                    Button("Try Again") { Task { await viewModel.listen() } }
                }
            } else {
                ContentUnavailableView(
                    "No reports yet",
                    systemImage: "person.3",
                    description: Text("Check a link and tap Report as Scam to warn other people.")
                )
            }
        } else if viewModel.filteredReports.isEmpty {
            ContentUnavailableView(
                "Nothing in this category",
                systemImage: "line.3.horizontal.decrease.circle",
                description: Text("Try another category.")
            )
        }
    }
}

struct TrendingRow: View {
    let item: CommunityViewModel.TrendingDomain

    var body: some View {
        HStack {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            Text(item.domain)
                .font(.headline)
            Spacer()
            Text(item.count == 1 ? "1 report" : "\(item.count) reports")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

struct ReportRow: View {
    let report: ScamReport

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: report.category.systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(report.domain)
                    .font(.headline)
                Text(report.category.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(report.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        CommunityView()
    }
}
