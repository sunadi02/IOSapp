//
//  HistoryView.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import SwiftUI

struct HistoryView: View {

    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var viewModel = HistoryViewModel()
    @State private var isConfirmingClear = false

    //a wide window shows the list and the chosen result side by side instead of pushing a new screen
    private var showsTwoPanes: Bool {
        sizeClass == .regular
    }

    var body: some View {
        content
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
    }

    @ViewBuilder
    private var content: some View {
        if showsTwoPanes {
            HStack(spacing: 0) {
                scanList
                    .frame(width: 360)
                Divider()
                detailPane
                    .frame(maxWidth: .infinity)
            }
        } else {
            scanList
        }
    }

    private var scanList: some View {
        List(selection: $viewModel.selectedScanID) {
            if let error = viewModel.errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Button("Try Again") { viewModel.load() }
                        .buttonStyle(.bordered)
                }
            }

            ForEach(viewModel.groups) { group in
                Section(viewModel.title(for: group.day)) {
                    ForEach(group.scans) { scan in
                        row(for: scan)
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
        .refreshable { viewModel.load() }
    }

    @ViewBuilder
    private func row(for scan: ScanResult) -> some View {
        if showsTwoPanes {
            ScanRow(scan: scan)
                .tag(scan.id)
        } else {
            NavigationLink(value: scan) {
                ScanRow(scan: scan)
            }
        }
    }

    @ViewBuilder
    private var detailPane: some View {
        if let scan = viewModel.selectedScan {
            NavigationStack {
                ResultView(result: scan)
            }
            .id(scan.id)
        } else {
            ContentUnavailableView(
                "Select a Scan",
                systemImage: "doc.text.magnifyingglass",
                description: Text("Choose a scan from the list to see why it was rated this way.")
            )
        }
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
