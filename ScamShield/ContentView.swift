//
//  ContentView.swift
//  ScamShield
//
//  Created by student2 on 2026-10-21.
//

import SwiftUI

struct ContentView: View {

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboardi    
    @Enviro    
    @State private var auth = AuthViewModel()

    //decides the first screen: onboarding, then login, then the main app
    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView { hasSeenOnboarding = true }
            } else if auth.isSignedIn {
                MainTabView()
            } else {
                AuthView()
            }
        }
        .environment(auth)
        .animation(.default, value: hasSeenOnboarding)
        .animation(.default, value: auth.isSignedIn)
    }
}

#Preview {
    ContentView()
}
