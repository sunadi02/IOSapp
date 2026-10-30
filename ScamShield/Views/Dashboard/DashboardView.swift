//
//  DashboardView.swift
//  ScamShield
//
//  Created by student2 on 2026-10-23.
//

import SwiftUI

struct DashboardView: View {

    @Environment(AuthViewModel.self) private var auth
    @Environment(AppServices.self) private var services
    @Environment(AppLockViewModel.self) private var lock
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel = DashboardViewModel()
    @State private var clipboard = ClipboardLinkViewModel()
    @State private var copiedLink: String?
    @State private var isShowingScanMenu = false
    @State private var chosenScan: AppSection?
    @State private var openedScan: AppSection?

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

                scanArea

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
        .sheet(isPresented: $isShowingScanMenu, onDismiss: openChosenScan) {
            ScanMenuSheet { section in
                chosenScan = section
                isShowingScanMenu = false
            }
            .presentationDetents([.height(260), .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(32)
            .presentationBackground(.regularMaterial)
        }
        .navigationDestination(item: $openedScan) { section in
            scanScreen(for: section)
        }
        .appBackground()
        .navigationTitle("ScamShield")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
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

    private func openChosenScan() {
        openedScan = chosenScan
        chosenScan = nil
    }

    @ViewBuilder
    private func scanScreen(for section: AppSection) -> some View {
        switch section {
        case .checkLink: CheckLinkView()
        case .scanQR: QRScannerView()
        case .scanScreenshot: ScreenshotScanView()
        default: EmptyView()
        }
    }

    private var scanArea: some View {
        VStack(spacing: 24) {
            ScanRingButton { isShowingScanMenu = true }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) { statTiles }
                VStack(spacing: 10) { statTiles }
            }
        }
    }

    @ViewBuilder
    private var statTiles: some View {
        StatTile(title: "Scans today", value: viewModel.scansToday, color: .accentColor)
        StatTile(title: "Risky today", value: viewModel.riskyToday, color: .red)
        StatTile(title: "Total scans", value: viewModel.totalScans, color: .primary)
    }

    private var heroSubtitle: String {
        if viewModel.scansToday == 0 {
            return "Check a link, QR code or message before you act on it."
        }
        return "\(viewModel.scansToday) checked today, \(viewModel.riskyToday) risky."
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    BrandAccentBar()
                    Text(viewModel.greeting(name: auth.user?.displayName))
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .accessibilityAddTraits(.isHeader)
                    Text(heroSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                BrandEmblem(systemImage: BrandEmblem.appLogo, size: 40)
            }

            protectionChips
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient.brand, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
        )
    }

    private var protectionChips: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { chips }
            VStack(alignment: .leading, spacing: 8) { chips }
        }
    }

    @ViewBuilder
    private var chips: some View {
        let isOnline = services.network.isOnline
        let hasModel = ScamClassifier.shared.isAvailable
        ProtectionChip(title: isOnline ? "Online check" : "Offline", systemImage: isOnline ? "globe" : "wifi.slash", isActive: isOnline)
        ProtectionChip(title: hasModel ? "On-device AI" : "AI not installed", systemImage: "cpu", isActive: hasModel)
        ProtectionChip(title: lock.isEnabled ? "App lock on" : "App lock off", systemImage: lock.isEnabled ? "lock.fill" : "lock.open", isActive: lock.isEnabled)
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            BrandSectionHeader(title: "Quick actions")

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
            BrandSectionHeader(title: "Recent scans")

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
                            Divider().padding(.leading, 64)
                        }
                    }
                }
                .cardBackground()
            }
        }
    }
}

struct StatTile: View {
    let title: String
    let value: Int
    let color: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(value)")
                .font(.title.bold())
                .foregroundStyle(color)
                .contentTransition(.numericText(value: Double(value)))
                .animation(reduceMotion ? nil : .default, value: value)
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .cardBackground()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)")
    }
}

struct QuickActionRow: View {
    let title: String
    let subtitle: String
    let systemImage: String

    @ScaledMetric(relativeTo: .headline) private var iconSize = 36

    var body: some View {
        HStack(spacing: 16) {
            BrandIconCircle(systemImage: systemImage, size: iconSize)
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

struct ProtectionChip: View {
    let title: String
    let systemImage: String
    let isActive: Bool

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(isActive ? 0.18 : 0.08), in: Capsule())
            .overlay(Capsule().stroke(isActive ? Color.brandCyan.opacity(0.6) : Color.white.opacity(0.2), lineWidth: 0.5))
            .accessibilityLabel(title)
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
    .environment(AuthViewModel(service: PreviewAuthService()))
    .environment(AppServices())
    .environment(AppLockViewModel())
}
