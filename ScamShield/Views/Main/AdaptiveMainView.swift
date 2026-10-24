//
//  AdaptiveMainView.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import SwiftUI

//picks the sidebar or the tab bar from the window width, so rotating an iPad or resizing it keeps the same section open
struct AdaptiveMainView: View {

    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(AppServices.self) private var services
    @AppStorage(AppSettings.alertsEnabled) private var alertsEnabled = true
    @State private var selection: AppSection = .home

    private var usesSidebar: Bool {
        sizeClass == .regular
    }

    var body: some View {
        @Bindable var router = services.router

        Group {
            if usesSidebar {
                SidebarMainView(selection: $selection)
            } else {
                MainTabView(selection: $selection)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if !services.network.isOnline {
                OfflineBanner()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? nil : .default, value: services.network.isOnline)
        .onChange(of: services.network.isOnline) { _, isOnline in
            AccessibilityNotification.Announcement(isOnline ? "Back online" : "You are offline").post()
        }
        .focusedSceneValue(\.appSection, usesSidebar ? $selection : nil)
        .task {
            if alertsEnabled { _ = await services.notifications.requestPermission() }
        }
        .sheet(item: $router.openedScan) { scan in
            NavigationStack {
                ResultView(result: scan)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { router.openedScan = nil }
                        }
                    }
            }
        }
    }
}

#Preview {
    AdaptiveMainView()
        .environment(AuthViewModel(service: PreviewAuthService()))
        .environment(AppLockViewModel())
        .environment(AppServices())
}
