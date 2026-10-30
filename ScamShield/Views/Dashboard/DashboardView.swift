//
//  DashboardView.swift
//  ScamShield
//
//  Created by student2 on 2026-10-23.
//

import SwiftUI

struct DashboardView: View {

    @Environment(AuthViewModel.self) private var auth
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel = DashboardViewModel()
    @State private var clipboard = ClipboardLinkViewModel()
    @State private var copiedLink: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                hero

                if clipboard.showsCard {
                    CopiedLinkCard { link in
                        clipboard.markHandled()
                        copiedLink = link
                    } onDismiss: {
                        clipboard.markHandled()
                    }
                    .transition(.opacity)
                }

                stats

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
            .animation(reduceMotion ? nil : .default, value: clipboard.showsCard)
        }
        .appBackground()
        .navigationTitle("ScamShield")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: ScanResult.self) { scan in
            ResultView(result: scan)
        }
        .navigationDestination(item: $copiedLink) { link in
            CheckLinkView(startingLink: link)
        }
        .onAppear { viewModel.load() }
        .refreshable { viewModel.load() }
        .task { await clipboard.refresh() }
        //a link copied in another app is only visible once ScamShield is active again
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await clipboard.refresh() }
            }
        }
    }

    private var stats: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { statCards }
            VStack(spacing: 12) { statCards }
        }
    }

    @ViewBuilder
    private var statCards: some View {
        StatCard(title: "Scans today", value: viewModel.scansToday, systemImage: "magnifyingglass", color: .blue)
        StatCard(title: "Risky today", value: viewModel.riskyToday, systemImage: "xmark.shield.fill", color: .red)
        StatCard(title: "Total scans", value: viewModel.totalScans, systemImage: "clock.fill", color: .indigo)
    }

    private var heroSubtitle: String {
        if viewModel.scansToday == 0 {
            return "Check a link, QR code or message before you act on it."
        }
        return "\(viewModel.scansToday) checked today, \(viewModel.riskyToday) risky."
    }

    private var hero: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                BrandAccentBar()
                Text(viewModel.greeting(name: auth.user?.displayName))
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .accessibilityAddTraits(.isHeader)
                Text(heroSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }
            Spacer(minLength: 0)
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.brandCyan)
                .shadow(color: .brandCyan.opacity(0.6), radius: 14)
                .accessibilityHidden(true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                LinearGradient.brand
                Circle()
                    .fill(Color.brandCyan.opacity(0.2))
                    .frame(width: 180, height: 180)
                    .blur(radius: 40)
                    .offset(x: 120, y: 60)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .shadow(color: .brandBlue.opacity(0.35), radius: 14, y: 6)
        .accessibilityElement(children: .combine)
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
                VStack(alignment: .leading, spacing: 8) {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Button("Try Again") { viewModel.load() }
                        .buttonStyle(.bordered)
                }
            } else if viewModel.recentScans.isEmpty {
                ContentUnavailableView(
                    "No scans yet",
                    systemImage: "shield",
                    description: Text("Check a link to see your results here.")
                )
                .cardBackground()
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
                .cardBackground()
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
                .frame(width: 40, height: 40)
                .background(color.opacity(0.15), in: Circle())
                .accessibilityHidden(true)
            Text("\(value)")
                .font(.title.bold())
                .contentTransition(.numericText(value: Double(value)))
                .animation(reduceMotion ? nil : .default, value: value)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, minHeight: 0, alignment: .leading)
        .padding(14)
        .cardBackground()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

struct QuickActionRow: View {
    let title: String
    let subtitle: String
    let systemImage: String

    @ScaledMetric(relativeTo: .title2) private var iconSize = 48

    var body: some View {
        HStack(spacing: 16) {
            BrandIconTile(systemImage: systemImage, size: iconSize)
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
        .cardBackground()
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
