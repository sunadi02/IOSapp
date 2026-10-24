//
//  CheckLinkView.swift
//  ScamShield
//
//  Created by student2 on 2026-10-23.
//

import SwiftUI

struct CheckLinkView: View {

    //a link handed over from elsewhere, such as the copied link card, is checked straight away
    private let startingLink: String?

    @State private var viewModel = CheckLinkViewModel()
    @FocusState private var isInputFocused: Bool

    init(startingLink: String? = nil) {
        self.startingLink = startingLink
    }

    var body: some View {
        Form {
            Section {
                TextField("example.com", text: $viewModel.input)
                    .keyboardType(.URL)
                    .textContentType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.go)
                    .focused($isInputFocused)
                    .onSubmit(runCheck)
                    .accessibilityLabel("Link to check")
                    .accessibilityIdentifier(AccessibilityID.checkLinkInput)

                PasteButton(payloadType: String.self) { strings in
                    viewModel.input = strings.first ?? ""
                }
            } header: {
                Text("Link")
            } footer: {
                Text("Paste a link from a message, email or website.")
            }

            if let error = viewModel.errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button(action: runCheck) {
                    HStack {
                        Spacer()
                        if viewModel.isChecking {
                            ProgressView()
                                .accessibilityLabel("Checking link")
                        } else {
                            Text("Check Link").bold()
                        }
                        Spacer()
                    }
                }
                .disabled(!viewModel.canCheck)
                .accessibilityIdentifier(AccessibilityID.checkLinkSubmit)
            }

            Section("What ScamShield checks") {
                Label("Google's list of known phishing and malware sites", systemImage: "globe")
                Label("Fake brand names and lookalike letters", systemImage: "theatermasks")
                Label("Short links and hidden destinations", systemImage: "eye.slash")
                Label("Unencrypted http connections", systemImage: "lock.open")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .navigationTitle("Check a Link")
        .announceWhenSet(viewModel.errorMessage)
        .navigationDestination(item: $viewModel.result) { result in
            ResultView(result: result, isNewScan: true)
        }
        .task {
            //only the first time, so coming back from the result does not check it again
            guard let startingLink, viewModel.input.isEmpty else { return }
            viewModel.input = startingLink
            await viewModel.check()
        }
    }

    private func runCheck() {
        isInputFocused = false
        Task { await viewModel.check() }
    }
}

#Preview {
    NavigationStack {
        CheckLinkView()
    }
}
