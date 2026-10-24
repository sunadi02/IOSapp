//
//  AppLockViewModelTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-24.
//

import Testing
import Foundation
import LocalAuthentication
@testable import ScamShield

//fake face id so tests never show a real prompt
@MainActor
final class MockBiometricAuthenticator: BiometricAuthenticating {
    var kind: BiometricKind = .faceID
    var result: Result<Void, BiometricError> = .success(())
    private(set) var attempts = 0

    func authenticate(reason: String) async throws {
        attempts += 1
        try result.get()
    }
}

@MainActor
struct AppLockViewModelTests {

    let authenticator = MockBiometricAuthenticator()
    let defaults = UserDefaults(suiteName: "AppLockViewModelTests-\(UUID().uuidString)")!

    private func makeViewModel(enabled: Bool) -> AppLockViewModel {
        defaults.set(enabled, forKey: AppLockViewModel.enabledKey)
        return AppLockViewModel(authenticator: authenticator, defaults: defaults)
    }

    @Test func startsUnlockedWhenDisabled() {
        let lock = makeViewModel(enabled: false)
        #expect(!lock.isEnabled)
        #expect(!lock.isLocked)
    }

    @Test func startsLockedWhenEnabled() {
        let lock = makeViewModel(enabled: true)
        #expect(lock.isEnabled)
        #expect(lock.isLocked)
    }

    @Test func leavingTheAppDoesNotLockWhenDisabled() {
        let lock = makeViewModel(enabled: false)
        lock.lockIfNeeded()
        #expect(!lock.isLocked)
    }

    @Test func leavingTheAppLocksAgainAfterUnlocking() async {
        let lock = makeViewModel(enabled: true)
        await lock.unlock()
        #expect(!lock.isLocked)

        lock.lockIfNeeded()
        #expect(lock.isLocked)
    }

    @Test func successfulUnlockOpensTheApp() async {
        let lock = makeViewModel(enabled: true)
        await lock.unlock()

        #expect(!lock.isLocked)
        #expect(lock.errorMessage == nil)
        #expect(authenticator.attempts == 1)
    }

    @Test func failedUnlockStaysLockedWithMessage() async {
        authenticator.result = .failure(.failed)
        let lock = makeViewModel(enabled: true)
        await lock.unlock()

        #expect(lock.isLocked)
        #expect(lock.errorMessage == BiometricError.failed.errorDescription)
    }

    @Test func cancelledUnlockStaysLockedWithoutMessage() async {
        authenticator.result = .failure(.cancelled)
        let lock = makeViewModel(enabled: true)
        await lock.unlock()

        #expect(lock.isLocked)
        #expect(lock.errorMessage == nil)
    }

    @Test func unlockingWhenNotLockedDoesNotPrompt() async {
        let lock = makeViewModel(enabled: false)
        await lock.unlock()
        #expect(authenticator.attempts == 0)
    }

    @Test func automaticPromptHappensOncePerLock() async {
        authenticator.result = .failure(.cancelled)
        let lock = makeViewModel(enabled: true)

        await lock.promptIfNeeded()
        await lock.promptIfNeeded()
        #expect(authenticator.attempts == 1)

        lock.lockIfNeeded()
        await lock.promptIfNeeded()
        #expect(authenticator.attempts == 2)
    }

    @Test func enablingNeedsAuthenticationAndIsSaved() async {
        let lock = makeViewModel(enabled: false)
        await lock.setEnabled(true)

        #expect(lock.isEnabled)
        #expect(!lock.isLocked)
        #expect(defaults.bool(forKey: AppLockViewModel.enabledKey))
        #expect(authenticator.attempts == 1)
    }

    @Test func failedAuthenticationKeepsLockOff() async {
        authenticator.result = .failure(.failed)
        let lock = makeViewModel(enabled: false)
        await lock.setEnabled(true)

        #expect(!lock.isEnabled)
        #expect(!defaults.bool(forKey: AppLockViewModel.enabledKey))
        #expect(lock.errorMessage != nil)
    }

    @Test func enablingIsRefusedWhenDeviceHasNoSecurity() async {
        authenticator.kind = .unavailable
        let lock = makeViewModel(enabled: false)
        await lock.setEnabled(true)

        #expect(!lock.isEnabled)
        #expect(!lock.isAvailable)
        #expect(lock.errorMessage == BiometricError.unavailable.errorDescription)
        #expect(authenticator.attempts == 0)
    }

    @Test func disablingNeedsNoPromptAndUnlocks() async {
        let lock = makeViewModel(enabled: true)
        await lock.setEnabled(false)

        #expect(!lock.isEnabled)
        #expect(!lock.isLocked)
        #expect(!defaults.bool(forKey: AppLockViewModel.enabledKey))
        #expect(authenticator.attempts == 0)
    }

    @Test func settingTheSameValueDoesNothing() async {
        let lock = makeViewModel(enabled: false)
        await lock.setEnabled(false)
        #expect(authenticator.attempts == 0)
    }

    @Test func lockTurnsItselfOffWhenDeviceSecurityIsRemoved() async {
        authenticator.result = .failure(.unavailable)
        let lock = makeViewModel(enabled: true)
        await lock.unlock()

        #expect(!lock.isEnabled)
        #expect(!lock.isLocked)
        #expect(!defaults.bool(forKey: AppLockViewModel.enabledKey))
    }
}

struct BiometricErrorTests {

    @Test(arguments: [
        (LAError.Code.userCancel, BiometricError.cancelled),
        (LAError.Code.systemCancel, BiometricError.cancelled),
        (LAError.Code.appCancel, BiometricError.cancelled),
        (LAError.Code.passcodeNotSet, BiometricError.unavailable),
        (LAError.Code.biometryNotAvailable, BiometricError.unavailable),
        (LAError.Code.biometryNotEnrolled, BiometricError.unavailable),
        (LAError.Code.authenticationFailed, BiometricError.failed),
        (LAError.Code.biometryLockout, BiometricError.failed)
    ])
    func localAuthenticationErrorsMapToFriendlyCases(code: LAError.Code, expected: BiometricError) {
        #expect(BiometricError(LAError(code)) == expected)
    }

    @Test func unknownErrorsCountAsFailed() {
        #expect(BiometricError(URLError(.badURL)) == .failed)
    }

    @Test func ownErrorsPassThroughUnchanged() {
        #expect(BiometricError(BiometricError.cancelled) == .cancelled)
    }

    @Test(arguments: [
        (BiometricKind.faceID, "Face ID"),
        (BiometricKind.touchID, "Touch ID"),
        (BiometricKind.opticID, "Optic ID"),
        (BiometricKind.passcodeOnly, "Passcode"),
        (BiometricKind.unavailable, "Face ID")
    ])
    func methodNameMatchesBiometryType(kind: BiometricKind, expected: String) {
        #expect(kind.title == expected)
    }
}
