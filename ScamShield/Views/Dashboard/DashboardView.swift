//
//  DashboardView.swift
//  ScamShield
//
//  Created by student2 on 2026-10-23.
//

import SwiftUI

struct DashboardView: View {

    @Environment(AuthViewModel.self) private var auth
    @State private var viewModel = DashboardViewModel()

    //cards wrap onto more rows when text is large or the screen is narrow
    private let statColumns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(viewModel.greeting(name: auth.user?.displayName))
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)

                LazyVGrid(columns: statColumns, spacing: 12) {
                    StatCard(title: "Scans today", value: viewModel.scansToday, systemImage: "magnifyingglass", color: .blue)
                    StatCard(title: "Risky today", value: viewModel.riskyToday, systemImage: "xmark.shield.fill", color: .red)
                    StatCard(title: "Total scans", value: viewModel.totalScans, systemImage: "clock.fill", color: .purple)
                }

                WeeklyChartCard(
                    breakdown: viewModel.weeklyBreakdown,
                    total: viewModel.weeklyTotal,
                    summary: viewModel.weeklySummary
                )

                quickActions
                recentScans
            }
            .padding()
            .frame(maxWidth: 800)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("ScamShield")
        .navigationDestination(for: ScanResult.self) { scan in
            ResultView(result: scan)
        }
        .onAppear { viewModel.load() }
        .refreshable { viewModel.load() }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick actions")
                .font(.title3.bold())
                .accessibilityAddTraits(.isHeader)

            NavigationLink {
                CheckLinkView()
            } label: {
                QuickActionRow(title: "Check a link", subtitle: "Paste a link from a message", systemImage: "link")
            }

            NavigationLink {
                QRScannerView()
            } label: {
                QuickActionRow(title: "Scan a QR code", subtitle: "Check a code before you open it", systemImage: "qrcode.viewfinder")
            }

            NavigationLink {
                ScreenshotScanView()
            } label: {
                QuickActionRow(title: "Scan a screenshot", subtitle: "Check a suspicious message", systemImage: "text.viewfinder")
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var recentScans: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent scans")
                .font(.title3.bold())
                .accessibilityAddTraits(.isHeader)

            if let error = viewModel.loadError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            } else if viewModel.recentScans.isEmpty {
                ContentUnavailableView(
                    "No scans yet",
                    systemImage: "shield",
                    description: Text("Check a link to see your results here.")
                )
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.recentScans) { scan in
                        NavigationLink(value: scan) {
                            ScanRow(scan: scan)
                                .padding()
                        }
                        .buttonStyle(.plain)
                        .hoverEffect(.highlight)

                        if scan.id != viewModel.recentScans.last?.id {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: Int
    let systemImage: String
    let color: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(color)
                .font(.title3)
                .accessibilityHidden(true)
            Text("\(value)")
                .font(.title.bold())
                .contentTransition(.numericText(value: Double(value)))
                .animation(reduceMotion ? nil : .default, value: value)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

struct QuickActionRow: View {
    let title: String
    let subtitle: String
    let systemImage: String

    //the coloured square grows with the text size so large text does not squash the icon
    @ScaledMetric(relativeTo: .title2) private var iconSize = 48

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: iconSize, height: iconSize)
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .hoverEffect(.lift)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
    .environment(AuthViewModel(service: PreviewAuthService()))
}
