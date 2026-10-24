//
//  AuthViewModel.swift
//  ScamShield
//
//  Created by student2 on 2026-10-23.
//

import Foundation
import Observation

@Observable
final class AuthViewModel {

    enum Mode {
        case signIn
        case signUp
    }

    var mode: Mode = .signIn
    var name = ""
    var email = ""
    var password = ""

    private(set) var user: AppUser?
    private(set) var isLoading = false
    var errorMessage: String?
    var infoMessage: String?

    private let service: AuthServicing

    init(service: AuthServicing = FirebaseAuthService()) {
        self.service = service
        //firebase keeps the session so a returning user skips the login screen
        self.user = service.currentUser
    }

    var isSignedIn: Bool { user != nil }

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    //checks the form on device before calling firebase
    var validationError: String? {
        if mode == .signUp && name.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Please enter your name."
        }
        if !Self.isValidEmail(trimmedEmail) {
            return "Please enter a valid email address."
        }
        if password.count < 6 {
            return "Password must be at least 6 characters."
        }
        return nil
    }

    static func isValidEmail(_ email: String) -> Bool {
        email.range(of: #"^[^@\s]+@[^@\s]+\.[A-Za-z]{2,}$"#, options: .regularExpression) != nil
    }

    func submit() async {
        errorMessage = nil
        infoMessage = nil

        if let validationError {
            errorMessage = validationError
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            switch mode {
            case .signIn:
                user = try await service.signIn(email: trimmedEmail, password: password)
            case .signUp:
                let cleanName = name.trimmingCharacters(in: .whitespaces)
                user = try await service.signUp(name: cleanName, email: trimmedEmail, password: password)
            }
            password = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetPassword() async {
        errorMessage = nil
        infoMessage = nil

        guard Self.isValidEmail(trimmedEmail) else {
            errorMessage = "Enter your email above to reset your password."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await service.sendPasswordReset(email: trimmedEmail)
            infoMessage = "Password reset email sent to \(trimmedEmail)."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateName(_ rawName: String) async throws {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw AuthError.emptyName }
        user = try await service.updateDisplayName(name)
    }

    func signOut() {
        do {
            try service.signOut()
            user = nil
            mode = .signIn
        } catch {
            errorMessage = "Could not sign out. Please try again."
        }
    }
}
