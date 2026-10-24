//
//  AdaptiveMainView.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import SwiftUI
import CoreSpotlight

//picks the sidebar or the tab bar from the window width, so rotating an iPad or resizing it keeps the same section open
struct AdaptiveMainView: View {

    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(AppServices.self) private var services
    @Environment(AppLockViewModel.self) private var lock
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
        //tapping a scan in iOS search opens its result, the same way a scam alert does
        .onContinueUserActivity(CSSearchableItemActionType) { activity in
            guard let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
                  let id = UUID(uuidString: identifier) else { return }
            services.router.open(id: id)
        }
        //a result opened from outside waits until the app is unlocked, so it never shows on top of the lock screen
        .sheet(item: lock.isLocked ? .constant(nil) : $router.openedScan) { scan in
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
