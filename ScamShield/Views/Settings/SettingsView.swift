//
//  SettingsView.swift
//  ScamShield
//
//  Created by student2 on 2026-10-23.
//

import SwiftUI

struct SettingsView: View {

    @Environment(AuthViewModel.self) private var auth
    @Environment(AppLockViewModel.self) private var lock
    @State private var isConfirmingSignOut = false
    @State private var isLockOn = false

    private var lockFooter: String {
        if let error = lock.errorMessage { return error }
        if !lock.isAvailable { return BiometricError.unavailable.localizedDescription }
        return "Locks ScamShield when you leave the app so your scan history stays private."
    }

    var body: some View {
        Form {
            Section("Account") {
                LabeledContent("Name", value: auth.user?.displayName ?? "Not set")
                LabeledContent("Email", value: auth.user?.email ?? "")
            }

            Section {
                Toggle(isOn: $isLockOn) {
                    Label("Require \(lock.methodName)", systemImage: "lock.fill")
                }
                .disabled(!lock.isAvailable)
            } header: {
                Text("Security")
            } footer: {
                Text(lockFooter)
            }

            Section {
                Button("Sign Out", role: .destructive) {
                    isConfirmingSignOut = true
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear { isLockOn = lock.isEnabled }
        .onChange(of: isLockOn) { _, newValue in
            Task {
                await lock.setEnabled(newValue)
                isLockOn = lock.isEnabled
            }
        }
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
    .environment(AppLockViewModel())
}
