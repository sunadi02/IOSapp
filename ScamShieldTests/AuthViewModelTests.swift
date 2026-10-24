//
//  AuthViewModelTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-23.
//

import Testing
import Foundation
@testable import ScamShield

//fake auth service that records calls and can be told to fail
final class MockAuthService: AuthServicing {
    var currentUser: AppUser?
    var errorToThrow: Error?
    private(set) var signInCalls = 0
    private(set) var resetEmails: [String] = []
    private(set) var updatedNames: [String] = []

    func signIn(email: String, password: String) async throws -> AppUser {
        signInCalls += 1
        if let errorToThrow { throw errorToThrow }
        return AppUser(id: "1", email: email, displayName: nil)
    }

    func signUp(name: String, email: String, password: String) async throws -> AppUser {
        if let errorToThrow { throw errorToThrow }
        return AppUser(id: "1", email: email, displayName: name)
    }

    func sendPasswordReset(email: String) async throws {
        if let errorToThrow { throw errorToThrow }
        resetEmails.append(email)
    }

    func updateDisplayName(_ name: String) async throws -> AppUser {
        if let errorToThrow { throw errorToThrow }
        updatedNames.append(name)
        return AppUser(id: "1", email: "user@example.com", displayName: name)
    }

    func signOut() throws {
        if let errorToThrow { throw errorToThrow }
    }
}

@MainActor
struct AuthViewModelTests {

    let service = MockAuthService()

    private func makeViewModel(email: String = "user@example.com", password: String = "secret123") -> AuthViewModel {
        let viewModel = AuthViewModel(service: service)
        viewModel.email = email
        viewModel.password = password
        return viewModel
    }

    @Test func existingSessionStartsSignedIn() {
        service.currentUser = AppUser(id: "1", email: "a@b.com", displayName: nil)
        #expect(AuthViewModel(service: service).isSignedIn)
    }

    @Test(arguments: ["", "plainaddress", "a@b", "a b@c.com"])
    func invalidEmailIsRejected(_ email: String) {
        #expect(!AuthViewModel.isValidEmail(email))
    }

    @Test func validEmailIsAccepted() {
        #expect(AuthViewModel.isValidEmail("sunadi@nibm.lk"))
    }

    @Test func shortPasswordStopsBeforeCallingFirebase() async {
        let viewModel = makeViewModel(password: "123")
        await viewModel.submit()
        #expect(viewModel.errorMessage == "Password must be at least 6 characters.")
        #expect(service.signInCalls == 0)
    }

    @Test func signUpNeedsName() {
        let viewModel = makeViewModel()
        viewModel.mode = .signUp
        #expect(viewModel.validationError == "Please enter your name.")
    }

    @Test func successfulSignInSetsUserAndClearsPassword() async {
        let viewModel = makeViewModel(email: "  user@example.com ")
        await viewModel.submit()
        #expect(viewModel.user?.email == "user@example.com")
        #expect(viewModel.password.isEmpty)
        #expect(!viewModel.isLoading)
    }

    @Test func failedSignInShowsFriendlyMessage() async {
        service.errorToThrow = AuthError.wrongCredentials
        let viewModel = makeViewModel()
        await viewModel.submit()
        #expect(!viewModel.isSignedIn)
        #expect(viewModel.errorMessage == "Email or password is incorrect.")
    }

    @Test func passwordResetNeedsEmail() async {
        let viewModel = makeViewModel(email: "")
        await viewModel.resetPassword()
        #expect(viewModel.errorMessage != nil)
        #expect(service.resetEmails.isEmpty)
    }

    @Test func passwordResetSendsEmail() async {
        let viewModel = makeViewModel()
        await viewModel.resetPassword()
        #expect(service.resetEmails == ["user@example.com"])
        #expect(viewModel.infoMessage != nil)
    }

    @Test func signOutClearsUser() async {
        let viewModel = makeViewModel()
        await viewModel.submit()
        viewModel.signOut()
        #expect(!viewModel.isSignedIn)
    }

    @Test func updatingNameSavesTrimmedNameAndUpdatesUser() async throws {
        let viewModel = makeViewModel()
        await viewModel.submit()

        try await viewModel.updateName("  Sunadi Amarasinghe \n")
        #expect(service.updatedNames == ["Sunadi Amarasinghe"])
        #expect(viewModel.user?.displayName == "Sunadi Amarasinghe")
    }

    @Test(arguments: ["", "   ", "\n"])
    func blankNameIsRejectedBeforeCallingFirebase(_ name: String) async {
        let viewModel = makeViewModel()
        await viewModel.submit()

        await #expect(throws: AuthError.emptyName) {
            try await viewModel.updateName(name)
        }
        #expect(service.updatedNames.isEmpty)
    }

    @Test func failedNameUpdateKeepsOldNameAndThrows() async {
        let viewModel = makeViewModel()
        await viewModel.submit()
        service.errorToThrow = AuthError.network

        await #expect(throws: AuthError.network) {
            try await viewModel.updateName("New Name")
        }
        #expect(viewModel.user?.displayName == nil)
    }

    @Test func nonFirebaseErrorMapsToUnknown() {
        #expect(AuthError(URLError(.badURL)) == .unknown)
    }
}
