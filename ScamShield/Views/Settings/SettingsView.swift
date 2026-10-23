//
//  SettingsView.swift
//  ScamShield
//
//  Created by student2 on 2026-10-23.
//

import SwiftUI

struct SettingsView: View {

    @Environment(AuthViewModel.self) private var auth
    @State private var isConfirmingSignOut = false

    var body: some View {
        Form {
            Section("Account") {
                LabeledContent("Name", value: auth.user?.displayName ?? "Not set")
                LabeledContent("Email", value: auth.user?.email ?? "")
            }

            Section {
                Button("Sign Out", role: .destructive) {
                    isConfirmingSignOut = true
                }
            }
        }
        .navigationTitle("Settings")
        .confirmationDialog("Sign out of ScamShield?", isPresented: $isConfirmingSignOut, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                auth.signOut()
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(AuthViewModel(service: PreviewAuthService()))
}
