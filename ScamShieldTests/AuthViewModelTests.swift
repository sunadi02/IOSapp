//
//  AuthViewModelTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-23.
//

import Testing
import Foundation
@testable import ScamShield

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

    @Test func signUpCreatesTheAccountWithATrimmedName() async {
        let viewModel = makeViewModel()
        viewModel.mode = .signUp
        viewModel.name = "  Sunadi Amarasinghe "
        await viewModel.submit()

        #expect(viewModel.user?.displayName == "Sunadi Amarasinghe")
        #expect(viewModel.isSignedIn)
    }

    @Test func signUpWithABadEmailStopsBeforeCallingFirebase() async {
        let viewModel = makeViewModel(email: "not an email")
        viewModel.mode = .signUp
        viewModel.name = "Sunadi"
        await viewModel.submit()

        #expect(viewModel.errorMessage == "Please enter a valid email address.")
        #expect(!viewModel.isSignedIn)
    }

    @Test func passwordResetFailureShowsAFriendlyMessage() async {
        service.errorToThrow = AuthError.network
        let viewModel = makeViewModel()
        await viewModel.resetPassword()

        #expect(viewModel.errorMessage == "No internet connection. Please try again.")
        #expect(viewModel.infoMessage == nil)
    }

    @Test func signOutFailureKeepsYouSignedInAndSaysSo() async {
        let viewModel = makeViewModel()
        await viewModel.submit()
        service.errorToThrow = AuthError.unknown

        viewModel.signOut()
        #expect(viewModel.isSignedIn)
        #expect(viewModel.errorMessage == "Could not sign out. Please try again.")
    }

    @Test func signingOutReturnsTheFormToSignIn() async {
        let viewModel = makeViewModel()
        await viewModel.submit()
        viewModel.mode = .signUp

        viewModel.signOut()
        #expect(viewModel.mode == .signIn)
    }

    @Test func fixingAMistakeClearsTheOldMessage() async {
        let viewModel = makeViewModel(password: "123")
        await viewModel.submit()
        #expect(viewModel.errorMessage != nil)

        viewModel.password = "secret123"
        await viewModel.submit()
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isSignedIn)
    }

    @Test func signedOutStateHasNoUser() {
        #expect(AuthViewModel(service: service).user == nil)
        #expect(!AuthViewModel(service: service).isSignedIn)
    }

    @Test func nonFirebaseErrorMapsToUnknown() {
        #expect(AuthError(URLError(.badURL)) == .unknown)
    }
}
