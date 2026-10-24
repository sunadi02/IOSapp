//
//  HistoryView.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import SwiftUI

struct HistoryView: View {

    @State private var viewModel = HistoryViewModel()
    @State private var isConfirmingClear = false

    var body: some View {
        List {
            if let error = viewModel.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }

            ForEach(viewModel.groups) { group in
                Section(viewModel.title(for: group.day)) {
                    ForEach(group.scans) { scan in
                        NavigationLink(value: scan) {
                            ScanRow(scan: scan)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                viewModel.delete(id: scan.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .overlay { emptyState }
        .navigationTitle("History")
        .navigationDestination(for: ScanResult.self) { scan in
            ResultView(result: scan)
        }
        .searchable(text: $viewModel.searchText, prompt: "Search links")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { optionsMenu }
        }
        .confirmationDialog("Delete all scan history?", isPresented: $isConfirmingClear, titleVisibility: .visible) {
            Button("Delete All", role: .destructive) {
                viewModel.deleteAll()
            }
        } message: {
            Text("This cannot be undone.")
        }
        .onAppear { viewModel.load() }
        .refreshable { viewModel.load() }
    }

    private var optionsMenu: some View {
        Menu {
            Picker("Type", selection: $viewModel.typeFilter) {
                Text("All types").tag(ScanType?.none)
                ForEach(ScanType.allCases, id: \.self) { type in
                    Label(type.title, systemImage: type.systemImage).tag(ScanType?.some(type))
                }
            }

            Picker("Result", selection: $viewModel.riskFilter) {
                Text("All results").tag(RiskLevel?.none)
                ForEach(RiskLevel.allCases, id: \.self) { level in
                    Label(level.title, systemImage: level.systemImage).tag(RiskLevel?.some(level))
                }
            }

            Divider()

            Button("Delete All History", systemImage: "trash", role: .destructive) {
                isConfirmingClear = true
            }
            .disabled(viewModel.scans.isEmpty)
        } label: {
            Image(systemName: viewModel.isFiltering
                  ? "line.3.horizontal.decrease.circle.fill"
                  : "line.3.horizontal.decrease.circle")
        }
        .accessibilityLabel("Filters and options")
    }

    @ViewBuilder
    private var emptyState: some View {
        if viewModel.scans.isEmpty && viewModel.errorMessage == nil {
            ContentUnavailableView(
                "No scans yet",
                systemImage: "clock",
                description: Text("Links you check will be saved here.")
            )
        } else if viewModel.groups.isEmpty && viewModel.isFiltering {
            ContentUnavailableView {
                Label("No matching scans", systemImage: "magnifyingglass")
            } description: {
                Text("Try a different search or filter.")
            } actions: {
                Button("Clear Filters") { viewModel.clearFilters() }
            }
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
}
