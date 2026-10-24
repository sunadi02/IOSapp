//
//  EditNameView.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import SwiftUI

struct EditNameView: View {

    @Environment(AuthViewModel.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var isSaving = false
    @State private var errorMessage: String?
    @FocusState private var isNameFocused: Bool

    init(currentName: String) {
        _name = State(initialValue: currentName)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaving
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Full name", text: $name)
                        .textContentType(.name)
                        .submitLabel(.done)
                        .focused($isNameFocused)
                        .onSubmit(save)
                } footer: {
                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Edit Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                            .accessibilityLabel("Saving")
                    } else {
                        Button("Save", action: save)
                            .disabled(!canSave)
                    }
                }
            }
            .interactiveDismissDisabled(isSaving)
            .onAppear { isNameFocused = true }
        }
    }

    private func save() {
        guard canSave else { return }
        errorMessage = nil
        isSaving = true

        Task {
            defer { isSaving = false }
            do {
                try await auth.updateName(name)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    EditNameView(currentName: "Sunadi")
        .environment(AuthViewModel(service: PreviewAuthService()))
}
