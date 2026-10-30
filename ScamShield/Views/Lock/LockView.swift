//
//  LockView.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import SwiftUI

struct LockView: View {

    let lock: AppLockViewModel

    @ScaledMetric(relativeTo: .largeTitle) private var iconSize = 96

    var body: some View {
        ZStack {
            BrandBackground()

            ScrollView {
                VStack(spacing: 20) {
                    BrandEmblem(systemImage: "lock.shield.fill", size: iconSize)
                        .padding(.bottom, 24)

                    Text("ScamShield is locked")
                        .font(.title.bold())
                        .foregroundStyle(.white)

                    Text("Unlock to see your scan history.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))

                    if let error = lock.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(Color.brandErrorText)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        Task { await lock.unlock() }
                    } label: {
                        Label("Unlock with \(lock.methodName)", systemImage: lock.kind.systemImage)
                    }
                    .buttonStyle(.brandPrimary)
                    .disabled(lock.isAuthenticating)
                    .padding(.top, 8)

                    if lock.kind != .passcodeOnly {
                        Text("If \(lock.methodName) doesn't work, you can enter your iPhone passcode instead.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
                .multilineTextAlignment(.center)
                .padding(32)
                .padding(.top, 64)
                .frame(maxWidth: 420)
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityAddTraits(.isModal)
    }
}

struct PrivacyCover: View {
    var body: some View {
        ZStack {
            BrandBackground()
            BrandEmblem(systemImage: BrandEmblem.appLogo, size: 96)
        }
        .accessibilityHidden(true)
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
