//
//  ReportSheet.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import SwiftUI

struct ReportSheet: View {

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ReportViewModel

    init(scan: ScanResult) {
        _viewModel = State(initialValue: ReportViewModel(scan: scan))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Reporting") {
                    Text(viewModel.scan.input)
                        .font(.callout.monospaced())
                        .lineLimit(3)
                        .truncationMode(.middle)
                }

                Section("What kind of scam is it?") {
                    Picker("Category", selection: $viewModel.category) {
                        ForEach(ScamCategory.allCases) { category in
                            Label(category.title, systemImage: category.systemImage).tag(category)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                    .disabled(!viewModel.canSend)
                }

                statusSection

                Section {
                    Button(action: send) {
                        HStack {
                            Spacer()
                            if viewModel.state == .sending {
                                ProgressView()
                                    .accessibilityLabel("Sending report")
                            } else {
                                Text("Send Report").bold()
                            }
                            Spacer()
                        }
                    }
                    .disabled(!viewModel.canSend)
                } footer: {
                    Text("Only the website address is shared, without anything after a question mark. Your name and email are never shown to other people.")
                }
            }
            .navigationTitle("Report Scam")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(viewModel.state == .sent ? "Done" : "Cancel") { dismiss() }
                }
            }
            .interactiveDismissDisabled(viewModel.state == .sending)
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        switch viewModel.state {
        case .sent:
            Section {
                Label("Thanks, your report helps protect others.", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        case .failed(let message):
            Section {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }
        case .idle, .sending:
            EmptyView()
        }
    }

    private func send() {
        Task { await viewModel.send() }
    }
}

#Preview {
    ReportSheet(scan: ScanResult(type: .link, input: "https://paypal-login.xyz/verify", riskLevel: .risky, trustScore: 20))
}
