//
//  MainTabView.swift
//  ScamShield
//
//  Created by student2 on 2026-10-23.
//

import SwiftUI

struct MainTabView: View {

    enum Tab: Hashable {
        case home, history, community, settings
    }

    @State private var selection: Tab = .home

    var body: some View {
        //each tab has its own navigation stack so going back stays inside that tab
        TabView(selection: $selection) {
            NavigationStack {
                DashboardView()
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(Tab.home)

            NavigationStack {
                ContentUnavailableView("History", systemImage: "clock", description: Text("Your full scan history will appear here."))
                    .navigationTitle("History")
            }
            .tabItem { Label("History", systemImage: "clock.fill") }
            .tag(Tab.history)

            NavigationStack {
                ContentUnavailableView("Community", systemImage: "person.3", description: Text("Scam reports from other users will appear here."))
                    .navigationTitle("Community")
            }
            .tabItem { Label("Community", systemImage: "person.3.fill") }
            .tag(Tab.community)

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            .tag(Tab.settings)
        }
    }
}

#Preview {
    MainTabView()
        .environment(AuthViewModel(service: PreviewAuthService()))
        .environment(AppLockViewModel())
}
