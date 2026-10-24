//
//  BiometricAuthService.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import Foundation
import LocalAuthentication

enum BiometricKind: Equatable {
    case faceID
    case touchID
    case opticID
    case passcodeOnly
    case unavailable

    var title: String {
        switch self {
        case .faceID, .unavailable: "Face ID"
        case .touchID: "Touch ID"
        case .opticID: "Optic ID"
        case .passcodeOnly: "Passcode"
        }
    }
}

enum BiometricError: LocalizedError, Equatable {
    case unavailable
    case cancelled
    case failed

    init(_ error: Error) {
        if let known = error as? BiometricError {
            self = known
            return
        }

        switch (error as? LAError)?.code {
        case .userCancel, .systemCancel, .appCancel: self = .cancelled
        case .passcodeNotSet, .biometryNotAvailable, .biometryNotEnrolled: self = .unavailable
        default: self = .failed
        }
    }

    var errorDescription: String? {
        switch self {
        case .unavailable: "Set up Face ID or a passcode in iOS Settings to use app lock."
        case .cancelled: "Authentication was cancelled."
        case .failed: "Could not verify it is you. Please try again."
        }
    }
}

//protocol so the lock view model can be tested without face id
protocol BiometricAuthenticating {
    var kind: BiometricKind { get }
    func authenticate(reason: String) async throws
}

//device owner policy lets the passcode step in when face id fails
struct LocalAuthService: BiometricAuthenticating {

    var kind: BiometricKind {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return .unavailable
        }

        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        case .opticID: return .opticID
        default: return .passcodeOnly
        }
    }

    func authenticate(reason: String) async throws {
        do {
            let success = try await LAContext().evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            if !success { throw BiometricError.failed }
        } catch {
            throw BiometricError(error)
        }
    }
}
