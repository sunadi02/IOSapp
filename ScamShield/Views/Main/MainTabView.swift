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

    //the scan screens live inside Home on a phone, so they select the Home tab
    private var tabSelection: Binding<AppSection> {
        Binding(get: { selection.compactTab }, set: { selection = $0 })
    }

    var body: some View {
        //each tab has its own navigation stack so going back stays inside that tab
        TabView(selection: tabSelection) {
            NavigationStack {
                DashboardView()
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
