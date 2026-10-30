//
//  AppLockViewModel.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import Foundation
import Observation
import os

@Observable
final class AppLockViewModel {

    static let enabledKey = AppSettings.appLockEnabled

    private(set) var isEnabled: Bool
    private(set) var isLocked: Bool
    private(set) var isAuthenticating = false
    private(set) var errorMessage: String?

    private var needsAutoPrompt: Bool
    private let authenticator: BiometricAuthenticating
    private let defaults: UserDefaults

    init(authenticator: BiometricAuthenticating = LocalAuthService(), defaults: UserDefaults = .standard) {
        self.authenticator = authenticator
        self.defaults = defaults

        let enabled = defaults.bool(forKey: Self.enabledKey)
        isEnabled = enabled
        isLocked = enabled
        needsAutoPrompt = enabled
    }

    var kind: BiometricKind { authenticator.kind }
    var methodName: String { kind.title }
    var isAvailable: Bool { kind != .unavailable }

    func lockIfNeeded() {
        Logger(subsystem: "sunadi.ScamShield", category: "AppLock")
            .info("Leaving app, lock enabled: \(self.isEnabled, privacy: .public), authenticating: \(self.isAuthenticating, privacy: .public)")
        guard isEnabled, !isAuthenticating else { return }
        isLocked = true
        needsAutoPrompt = true
    }

    //prompts once per lock so cancelling does not loop when the app becomes active again
    func promptIfNeeded() async {
        guard isLocked, needsAutoPrompt else { return }
        needsAutoPrompt = false
        await unlock()
    }

    func unlock() async {
        guard isLocked, !isAuthenticating else { return }
        if await verify(reason: "Unlock ScamShield to see your scan history") {
            isLocked = false
        }
    }

    //turning the lock on needs a successful check so it cannot be enabled by someone else
    func setEnabled(_ enabled: Bool) async {
        guard enabled != isEnabled, !isAuthenticating else { return }
        errorMessage = nil

        guard enabled else {
            save(enabled: false)
            isLocked = false
            return
        }

        guard isAvailable else {
            errorMessage = BiometricError.unavailable.errorDescription
            return
        }

        if await verify(reason: "Confirm it is you to turn on app lock") {
            save(enabled: true)
        }
    }

    private func verify(reason: String) async -> Bool {
        isAuthenticating = true
        defer { isAuthenticating = false }

        do {
            try await authenticator.authenticate(reason: reason)
            errorMessage = nil
            return true
        } catch {
            handle(BiometricError(error))
            return false
        }
    }

    private func handle(_ error: BiometricError) {
        switch error {
        case .cancelled:
            errorMessage = nil
        case .unavailable:
            //nothing is left to unlock with so the lock turns itself off
            if isEnabled {
                save(enabled: false)
                isLocked = false
            }
            errorMessage = error.errorDescription
        case .failed:
            errorMessage = error.errorDescription
        }
    }

    private func save(enabled: Bool) {
        isEnabled = enabled
        defaults.set(enabled, forKey: Self.enabledKey)
    }
}
