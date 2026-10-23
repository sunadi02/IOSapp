//
//  AuthView.swift
//  ScamShield
//
//  Created by student2 on 2026-10-23.
//

import SwiftUI

struct AuthView: View {

    @Environment(AuthViewModel.self) private var auth

    private enum Field {
        case name, email, password
    }

    @FocusState private var focusedField: Field?

    var body: some View {
        @Bindable var auth = auth

        ScrollView {
            VStack(spacing: 24) {
                header

                Picker("Mode", selection: $auth.mode) {
                    Text("Sign In").tag(AuthViewModel.Mode.signIn)
                    Text("Create Account").tag(AuthViewModel.Mode.signUp)
                }
                .pickerStyle(.segmented)

                VStack(spacing: 12) {
                    if auth.mode == .signUp {
                        TextField("Full name", text: $auth.name)
                            .textContentType(.name)
                            .focused($focusedField, equals: .name)
                            .submitLabel(.next)
                    }

                    TextField("Email", text: $auth.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)

                    SecureField("Password", text: $auth.password)
                        .textContentType(auth.mode == .signUp ? .newPassword : .password)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.go)
                }
                .textFieldStyle(.roundedBorder)
                .onSubmit(moveToNextField)

                messages

                Button {
                    focusedField = nil
                    Task { await auth.submit() }
                } label: {
                    Group {
                        if auth.isLoading {
                            ProgressView()
                        } else {
                            Text(auth.mode == .signIn ? "Sign In" : "Create Account")
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(auth.isLoading)

                if auth.mode == .signIn {
                    Button("Forgot password?") {
                        Task { await auth.resetPassword() }
                    }
                    .font(.subheadline)
                    .disabled(auth.isLoading)
                }
            }
            .padding(24)
            .frame(maxWidth: 500)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .animation(.default, value: auth.mode)
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            Text("ScamShield")
                .font(.largeTitle.bold())
            Text(auth.mode == .signIn ? "Welcome back" : "Create an account to sync your scan history")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 32)
    }

    @ViewBuilder
    private var messages: some View {
        if let error = auth.errorMessage {
            Label(error, systemImage: "exclamationmark.triangle.fill")
                .font(.footnote)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        if let info = auth.infoMessage {
            Label(info, systemImage: "envelope.fill")
                .font(.footnote)
                .foregroundStyle(.green)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func moveToNextField() {
        switch focusedField {
        case .name: focusedField = .email
        case .email: focusedField = .password
        default:
            focusedField = nil
            Task { await auth.submit() }
        }
    }
}

#Preview {
    AuthView()
        .environment(AuthViewModel(service: PreviewAuthService(currentUser: nil)))
}
