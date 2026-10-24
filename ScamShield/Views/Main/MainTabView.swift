//
//  MainTabView.swift
//  ScamShield
//
//  Created by student2 on 2026-10-23.
//

import SwiftUI

//the compact layout used on iPhone and narrow iPad windows
struct MainTabView: View {

    @Binding var selection: AppSection

    //lets a scan screen be opened from outside, such as a home screen quick action
    @State private var homePath = NavigationPath()

    //the scan screens live inside Home on a phone, so they select the Home tab
    private var tabSelection: Binding<AppSection> {
        Binding(get: { selection.compactTab }, set: { selection = $0 })
    }

    var body: some View {
        //each tab has its own navigation stack so going back stays inside that tab
        TabView(selection: tabSelection) {
            NavigationStack(path: $homePath) {
                DashboardView()
                    .navigationDestination(for: AppSection.self) { section in
                        scanScreen(for: section)
                    }
            }
            .tabItem { label(for: .home) }
            .tag(AppSection.home)

            NavigationStack {
                HistoryView()
            }
            .tabItem { label(for: .history) }
            .tag(AppSection.history)

            NavigationStack {
                CommunityView()
            }
            .tabItem { label(for: .community) }
            .tag(AppSection.community)

            NavigationStack {
                SettingsView()
            }
            .tabItem { label(for: .settings) }
            .tag(AppSection.settings)
        }
        .handlesQuickActions(selection: $selection)
        .onChange(of: selection, initial: true) { _, section in
            openFromHome(section)
        }
        //once the scan screen is closed the selection goes back to Home, so the same quick action works again
        .onChange(of: homePath) { _, path in
            if path.isEmpty && selection != selection.compactTab {
                selection = selection.compactTab
            }
        }
    }

    private func openFromHome(_ section: AppSection) {
        guard section.compactTab == .home, section != .home else { return }

        var path = NavigationPath()
        path.append(section)
        homePath = path
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

    private func label(for section: AppSection) -> some View {
        Label(section.title, systemImage: section.systemImage)
    }
}

#Preview {
    MainTabView(selection: .constant(.home))
        .environment(AuthViewModel(service: PreviewAuthService()))
        .environment(AppLockViewModel())
        .environment(AppServices())
}
