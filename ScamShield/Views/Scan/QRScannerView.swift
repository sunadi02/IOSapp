//
//  QRScannerView.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import SwiftUI
import PhotosUI

struct QRScannerView: View {

    @State private var viewModel = QRScannerViewModel()
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            cameraLayer
            VStack {
                Spacer()
                controls
            }
        }
        .navigationTitle("Scan QR Code")
        .navigationBarTitleDisplayMode(.inline)
        .announceWhenSet(viewModel.errorMessage)
        .toolbar {
            if viewModel.cameraState == .scanning {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.toggleTorch()
                    } label: {
                        Image(systemName: viewModel.isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                    }
                    .accessibilityLabel(viewModel.isTorchOn ? "Turn torch off" : "Turn torch on")
                }
            }
        }
        .navigationDestination(item: $viewModel.result) { scan in
            ResultView(result: scan, isNewScan: true)
        }
        .sensoryFeedback(.impact(flexibility: .rigid), trigger: viewModel.result) { _, newValue in newValue != nil }
        .onAppear {
            viewModel.prepareToScan()
            Task { await viewModel.startCamera() }
        }
        .onDisappear { viewModel.stopCamera() }
        .onChange(of: selectedPhoto) { _, item in
            loadPhoto(item)
        }
        .dropDestination(for: DroppedImage.self) { images, _ in
            guard let image = images.first else { return false }
            Task { await viewModel.scan(photoData: image.data) }
            return true
        }
    }

    @ViewBuilder
    private var cameraLayer: some View {
        switch viewModel.cameraState {
        case .starting, .scanning:
            CameraPreview(session: viewModel.session)
                .ignoresSafeArea()
                .overlay { viewfinder }
                .accessibilityLabel("Camera viewfinder")
                .accessibilityHint("Point the camera at a QR code to check it")
        case .denied:
            ContentUnavailableView {
                Label("Camera Access Needed", systemImage: "camera.fill")
            } description: {
                Text("Allow camera access in iOS Settings to scan QR codes, or choose a photo instead.")
            } actions: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    Link("Open iOS Settings", destination: url)
                }
            }
        case .unavailable:
            ContentUnavailableView(
                "No Camera Available",
                systemImage: "camera.slash",
                description: Text("Choose a photo of a QR code instead.")
            )
        case .idle:
            EmptyView()
        }
    }

    private var viewfinder: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 24)
                .stroke(.white, lineWidth: 4)
                .frame(width: 250, height: 250)
                .shadow(radius: 4)

            Text("Point your camera at a QR code")
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.regularMaterial, in: Capsule())
        }
        .accessibilityHidden(true)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            if let message = viewModel.errorMessage {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(12)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }

            if viewModel.isAnalysing {
                ProgressView("Checking")
                    .padding(12)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label("Scan from Photo", systemImage: "photo")
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.regularMaterial, in: Capsule())
            }
        }
        .padding()
    }

    private func loadPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }

        Task {
            defer { selectedPhoto = nil }
            let data = (try? await item.loadTransferable(type: Data.self)) ?? Data()
            await viewModel.scan(photoData: data)
        }
    }
}

#Preview {
    NavigationStack {
        QRScannerView()
    }
}
