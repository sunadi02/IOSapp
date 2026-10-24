//
//  ContentView.swift
//  ScamShield
//
//  Created by student2 on 2026-10-21.
//

import SwiftUI

struct ContentView: View {

    @AppStorage(AppSettings.hasSeenOnboarding) private var hasSeenOnboarding = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var auth = AuthViewModel()
    @State private var lock = AppLockViewModel()

    private var isLockedOut: Bool { auth.isSignedIn && lock.isLocked }

    //blurs the app while it is not active so the app switcher shows nothing private
    private var isObscured: Bool { auth.isSignedIn && lock.isEnabled && scenePhase != .active }

    //decides the first screen: onboarding, then login, then the main app
    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView { hasSeenOnboarding = true }
            } else if auth.isSignedIn {
                AdaptiveMainView()
            } else {
                AuthView()
            }
        }
        .environment(auth)
        .environment(lock)
        .animation(.default, value: hasSeenOnboarding)
        .animation(.default, value: auth.isSignedIn)
        .blur(radius: isObscured ? 25 : 0)
        .accessibilityHidden(isLockedOut)
        .overlay {
            if isLockedOut {
                LockView(lock: lock)
                    .transition(.opacity)
            }
        }
        .animation(.default, value: isLockedOut)
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background where auth.isSignedIn:
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
    }
}

#Preview {
    ContentView()
}
