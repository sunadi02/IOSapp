//
//  ContentView.swift
//  ScamShield
//
//  Created by student2 on 2026-10-21.
//

import SwiftUI

struct ContentView: View {

    @AppStorage(AppSettings.hasSeenOnboarding) private var hasSeenOnboarding = false
    @AppStorage(AppSettings.appearance) private var appearance = AppearanceMode.system
    @Environment(\.scenePhase) private var scenePhase
    @State private var auth = AuthViewModel()
    @State private var lock = AppLockViewModel()

    private var isLockedOut: Bool { auth.isSignedIn && lock.isLocked }

    private var interfaceStyle: UIUserInterfaceStyle {
        let showsBrandScreen = !hasSeenOnboarding || !auth.isSignedIn || isLockedOut
        return showsBrandScreen ? .dark : appearance.interfaceStyle
    }

    //covers the app while it is not active so the app switcher shows nothing private
    private var isObscured: Bool { auth.isSignedIn && scenePhase != .active }

    //decides the first screen: onboarding, then login, then the main app
    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView { hasSeenOnboarding = true }
            } else if auth.isSignedIn {
                AdaptiveMainView()
                    .id(auth.user?.id)
            } else {
                AuthView()
            }
        }
        .environment(auth)
        .environment(lock)
        .animation(.default, value: hasSeenOnboarding)
        .animation(.default, value: auth.isSignedIn)
        .accessibilityHidden(isLockedOut)
        .overlay {
            if isLockedOut {
                LockView(lock: lock)
                    .transition(.opacity)
            }
        }
        .overlay {
            if isObscured {
                PrivacyCover()
            }
        }
        .animation(.default, value: isLockedOut)
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .inactive where auth.isSignedIn, .background where auth.isSignedIn:
                lock.lockIfNeeded()
            case .active where auth.isSignedIn:
                Task { await lock.promptIfNeeded() }
            default:
                break
            }
        }
        .task(id: auth.isSignedIn) {
            if auth.isSignedIn { await lock.promptIfNeeded() }
        }
        .onChange(of: interfaceStyle, initial: true) { _, style in
            applyInterfaceStyle(style)
        }
        .onChange(of: auth.isSignedIn) { wasSignedIn, isSignedIn in
            if wasSignedIn && !isSignedIn {
                hasSeenOnboarding = false
            }
        }
    }

    private func applyInterfaceStyle(_ style: UIUserInterfaceStyle) {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        for window in scenes.flatMap(\.windows) {
            window.overrideUserInterfaceStyle = style
        }
    }
}

#Preview {
    ContentView()
}
