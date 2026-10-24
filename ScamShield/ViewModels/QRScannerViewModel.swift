//
//  QRScannerViewModel.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import AVFoundation
import Foundation
import Observation

@Observable
final class QRScannerViewModel {

    enum CameraState: Equatable {
        case idle
        case starting
        case scanning
        case denied
        case unavailable
    }

    var result: ScanResult?
    var errorMessage: String?

    private(set) var cameraState: CameraState = .idle
    private(set) var isAnalysing = false
    private(set) var isTorchOn = false

    private let camera: CameraControlling
    private let detector: BarcodeDetecting
    private let scanner: QRScanner
    private let history: HistoryStoring

    init(
        camera: CameraControlling = CameraSession(),
        detector: BarcodeDetecting = BarcodeDetector(),
        scanner: QRScanner = QRScanner(),
        history: HistoryStoring = AppHistory.store
    ) {
        self.camera = camera
        self.detector = detector
        self.scanner = scanner
        self.history = history
    }

    var session: AVCaptureSession { camera.session }

    //the screen appearing always means ready for a new code, including coming back from a result
    func prepareToScan() {
        result = nil
        errorMessage = nil
        isAnalysing = false
    }

    func startCamera() async {
        guard cameraState != .starting, cameraState != .scanning else { return }
        cameraState = .starting

        switch await camera.configure() {
        case .ready:
            camera.start { [weak self] code in
                Task { @MainActor in await self?.handle(code: code) }
            }
            cameraState = .scanning
        case .denied:
            cameraState = .denied
        case .unavailable:
            cameraState = .unavailable
        }
    }

    func stopCamera() {
        camera.stop()
        if isTorchOn {
            camera.setTorch(false)
            isTorchOn = false
        }
        if cameraState == .scanning || cameraState == .starting { cameraState = .idle }
    }

    func toggleTorch() {
        isTorchOn.toggle()
        camera.setTorch(isTorchOn)
    }

    func handle(code: String) async {
        guard !isAnalysing, result == nil else { return }
        isAnalysing = true
        defer { isAnalysing = false }
        stopCamera()

        do {
            let scan = try await scanner.scan(payload: code)
            try? history.save(scan)
            result = scan
        } catch {
            errorMessage = error.localizedDescription
            await startCamera()
        }
    }

    func scan(photoData: Data) async {
        guard !isAnalysing else { return }
        errorMessage = nil

        let detector = detector
        let code = await Task.detached { (try? detector.payloads(inImageData: photoData))?.first }.value

        guard let code else {
            errorMessage = "No QR code was found in that photo. Try a clearer, closer picture."
            return
        }
        await handle(code: code)
    }
}
