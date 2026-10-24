//
//  LockView.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import SwiftUI

struct LockView: View {

    let lock: AppLockViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)

                Text("ScamShield is locked")
                    .font(.title2.bold())

                Text("Unlock to see your scan history.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let error = lock.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task { await lock.unlock() }
                } label: {
                    Label("Unlock with \(lock.methodName)", systemImage: lock.kind.systemImage)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(lock.isAuthenticating)
            }
            .multilineTextAlignment(.center)
            .padding(32)
            .padding(.top, 64)
            .frame(maxWidth: 420)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemBackground))
        .accessibilityAddTraits(.isModal)
    }
}

private extension BiometricKind {

    var systemImage: String {
        switch self {
        case .faceID, .unavailable: "faceid"
        case .touchID: "touchid"
        case .opticID: "opticid"
        case .passcodeOnly: "lock.open.fill"
        }
    }
}

#Preview {
    LockView(lock: AppLockViewModel())
}
