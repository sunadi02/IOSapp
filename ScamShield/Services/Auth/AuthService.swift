//
//  AuthService.swift
//  ScamShield
//
//  Created by student2 on 2026-10-23.
//

import Foundation
import FirebaseAuth

struct AppUser: Equatable {
    let id: String
    let email: String
    let displayName: String?
}

//protocol so the auth view model can be tested without firebase
protocol AuthServicing {
    var currentUser: AppUser? { get }
    func signIn(email: String, password: String) async throws -> AppUser
    func signUp(name: String, email: String, password: String) async throws -> AppUser
    func sendPasswordReset(email: String) async throws
    func updateDisplayName(_ name: String) async throws -> AppUser
    func signOut() throws
}

enum AuthError: LocalizedError, Equatable {
    case wrongCredentials
    case emailInUse
    case weakPassword
    case invalidEmail
    case emptyName
    case network
    case tooManyAttempts
    case unknown

    //turns firebase error codes into messages a user can understand
    init(_ error: Error) {
        let nsError = error as NSError
        guard nsError.domain == AuthErrors.domain else {
            self = .unknown
            return
        }

        switch AuthErrorCode(rawValue: nsError.code) {
        case .wrongPassword, .invalidCredential, .userNotFound: self = .wrongCredentials
        case .emailAlreadyInUse: self = .emailInUse
        case .weakPassword: self = .weakPassword
        case .invalidEmail, .missingEmail: self = .invalidEmail
        case .networkError: self = .network
        case .tooManyRequests: self = .tooManyAttempts
        default: self = .unknown
        }
    }

    var errorDescription: String? {
        switch self {
        case .wrongCredentials: "Email or password is incorrect."
        case .emailInUse: "An account with this email already exists."
        case .weakPassword: "Password must be at least 6 characters."
        case .invalidEmail: "Please enter a valid email address."
        case .emptyName: "Please enter your name."
        case .network: "No internet connection. Please try again."
        case .tooManyAttempts: "Too many attempts. Please wait a moment and try again."
        case .unknown: "Something went wrong. Please try again."
        }
    }
}

struct FirebaseAuthService: AuthServicing {

    //read when needed so firebase is already configured by the app
    private var auth: Auth { Auth.auth() }

    var currentUser: AppUser? {
        auth.currentUser.map(Self.makeUser)
    }

    func signIn(email: String, password: String) async throws -> AppUser {
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            return Self.makeUser(result.user)
        } catch {
            throw AuthError(error)
        }
    }

    func signUp(name: String, email: String, password: String) async throws -> AppUser {
        do {
            let result = try await auth.createUser(withEmail: email, password: password)

            //firebase creates the account first then the name is saved on the profile
            let change = result.user.createProfileChangeRequest()
            change.displayName = name
            try await change.commitChanges()

            return AppUser(id: result.user.uid, email: email, displayName: name)
        } catch {
            throw AuthError(error)
        }
    }

    func sendPasswordReset(email: String) async throws {
        do {
            try await auth.sendPasswordReset(withEmail: email)
        } catch {
            throw AuthError(error)
        }
    }

    func updateDisplayName(_ name: String) async throws -> AppUser {
        guard let user = auth.currentUser else { throw AuthError.unknown }

        do {
            let change = user.createProfileChangeRequest()
            change.displayName = name
            try await change.commitChanges()
            return AppUser(id: user.uid, email: user.email ?? "", displayName: name)
        } catch {
            throw AuthError(error)
        }
    }

    func signOut() throws {
        try auth.signOut()
    }

    private static func makeUser(_ user: User) -> AppUser {
        AppUser(id: user.uid, email: user.email ?? "", displayName: user.displayName)
    }
}

#if DEBUG
//fake service so swiftui previews work without firebase
struct PreviewAuthService: AuthServicing {
    var currentUser: AppUser? = AppUser(id: "preview", email: "sunadi@example.com", displayName: "Sunadi")
    func signIn(email: String, password: String) async throws -> AppUser { currentUser! }
    func signUp(name: String, email: String, password: String) async throws -> AppUser { currentUser! }
    func sendPasswordReset(email: String) async throws {}
    func updateDisplayName(_ name: String) async throws -> AppUser { currentUser! }
    func signOut() throws {}
}
#endif
