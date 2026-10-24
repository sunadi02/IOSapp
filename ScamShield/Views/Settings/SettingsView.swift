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
    @Environment(AppServices.self) private var services
    @AppStorage(AppSettings.alertsEnabled) private var alertsEnabled = true
    @State private var viewModel = SettingsViewModel()
    @State private var isEditingName = false
    @State private var isConfirmingClear = false
    @State private var isConfirmingSignOut = false
    @State private var isLockOn = false
    @State private var recheckMessage: String?

    private var lockFooter: String {
        if let error = lock.errorMessage { return error }
        if !lock.isAvailable { return BiometricError.unavailable.localizedDescription }
        return "Locks ScamShield when you leave the app so your scan history stays private."
    }

    private var dataFooter: String {
        viewModel.errorMessage ?? viewModel.statusMessage ?? "Removes every saved scan from this device and your account."
    }

    var body: some View {
        Form {
            Section("Account") {
                LabeledContent("Name", value: auth.user?.displayName ?? "Not set")
                LabeledContent("Email", value: auth.user?.email ?? "")
                Button("Edit Name", systemImage: "pencil") {
                    isEditingName = true
                }
            }

            Section {
                Toggle("Scam alerts", isOn: $alertsEnabled)
                if viewModel.alertsMessage != nil, let url = URL(string: UIApplication.openSettingsURLString) {
                    Link("Open iOS Settings", destination: url)
                }
            } header: {
                Text("Notifications")
            } footer: {
                Text(viewModel.alertsMessage ?? "Get notified if a link you checked earlier is later reported as a scam.")
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
                Button("Clear Scan History", systemImage: "trash", role: .destructive) {
                    isConfirmingClear = true
                }
            } header: {
                Text("Data")
            } footer: {
                Text(dataFooter)
            }

            Section {
                LabeledContent("Version", value: viewModel.versionText)
            } header: {
                Text("About")
            } footer: {
                Text("Links are checked on your device first. Only the link address is sent to Google Safe Browsing. Your link and QR history is stored in your private ScamShield account so it syncs across your devices. Screenshots and message text never leave this device.")
            }

            #if DEBUG
            Section {
                Button("Run re-check now") {
                    Task {
                        let flagged = await services.recheck.run(force: true)
                        recheckMessage = "Re-check finished, \(flagged) link(s) newly flagged."
                    }
                }
            } header: {
                Text("Developer")
            } footer: {
                if let recheckMessage { Text(recheckMessage) }
            }
            #endif

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
        .onChange(of: alertsEnabled) { _, isOn in
            guard isOn else { return }
            Task { alertsEnabled = await viewModel.setAlerts(true) }
        }
        .sheet(isPresented: $isEditingName) {
            EditNameView(currentName: auth.user?.displayName ?? "")
                .presentationDetents([.medium])
        }
        .confirmationDialog("Delete all scan history?", isPresented: $isConfirmingClear, titleVisibility: .visible) {
            Button("Delete All", role: .destructive) {
                viewModel.clearHistory()
            }
        } message: {
            Text("This cannot be undone.")
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
    .environment(AppServices())
}
