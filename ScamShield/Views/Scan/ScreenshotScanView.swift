//
//  ScreenshotScanView.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import SwiftUI
import PhotosUI

struct ScreenshotScanView: View {

    @State private var viewModel = ScreenshotScanViewModel()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var previewImage: UIImage?
    @FocusState private var isTextFocused: Bool

    var body: some View {
        Form {
            screenshotSection
            messageSection

            if !viewModel.detectedLinks.isEmpty {
                Section("Links found") {
                    ForEach(viewModel.detectedLinks, id: \.self) { link in
                        Label(link.absoluteString, systemImage: "link")
                            .font(.callout.monospaced())
                    }
                }
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
                                .accessibilityLabel("Checking message")
                        } else {
                            Text("Check Message").bold()
                        }
                        Spacer()
                    }
                }
                .disabled(!viewModel.canCheck)
            }
        }
        .navigationTitle("Scan a Screenshot")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $viewModel.result) { scan in
            ResultView(result: scan)
        }
        .onChange(of: selectedPhoto) { _, item in
            loadPhoto(item)
        }
    }

    private var screenshotSection: some View {
        Section {
            if let previewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("Selected screenshot")
            }

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label(previewImage == nil ? "Choose Screenshot" : "Choose a Different Screenshot", systemImage: "photo.on.rectangle")
            }

            if viewModel.isRecognising {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Reading the text on your device")
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            }
        } header: {
            Text("Screenshot")
        } footer: {
            Text("The text is read on your device and the screenshot is never uploaded. Only links found in it are checked online.")
        }
    }

    private var messageSection: some View {
        Section {
            TextEditor(text: $viewModel.text)
                .frame(minHeight: 160)
                .focused($isTextFocused)
                .accessibilityLabel("Message text")

            PasteButton(payloadType: String.self) { strings in
                viewModel.text = strings.first ?? ""
            }
        } header: {
            Text("Message")
        } footer: {
            Text("Fix any mistakes in the text, or paste a message instead of choosing a screenshot.")
        }
    }

    private func runCheck() {
        isTextFocused = false
        Task { await viewModel.check() }
    }

    private func loadPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }

        Task {
            defer { selectedPhoto = nil }
            let data = (try? await item.loadTransferable(type: Data.self)) ?? Data()
            previewImage = UIImage(data: data)
            await viewModel.recognize(imageData: data)
        }
    }
}

#Preview {
    NavigationStack {
        ScreenshotScanView()
    }
}
