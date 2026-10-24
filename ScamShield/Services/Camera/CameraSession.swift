//
//  CameraSession.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import AVFoundation

enum CameraSetupResult: Equatable {
    case ready
    case denied
    case unavailable
}

//protocol so the scanner screen can be tested without a real camera
nonisolated protocol CameraControlling: AnyObject {
    var session: AVCaptureSession { get }
    func configure() async -> CameraSetupResult
    func start(onCode: @escaping @Sendable (String) -> Void)
    func stop()
    func setTorch(_ isOn: Bool)
}

//streams back camera frames to vision a few times a second and reports the first qr code it reads
//all mutable state is only touched on the private queue
nonisolated final class CameraSession: NSObject, CameraControlling, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {

    static let analysisInterval: TimeInterval = 0.25

    let session = AVCaptureSession()

    private let output = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "com.scamshield.camera")
    private let detector: BarcodeDetecting
    private var device: AVCaptureDevice?
    private var onCode: (@Sendable (String) -> Void)?
    private var lastAnalysis = Date.distantPast
    private var hasFoundCode = false

    init(detector: BarcodeDetecting = BarcodeDetector()) {
        self.detector = detector
        super.init()
    }

    func configure() async -> CameraSetupResult {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            guard await AVCaptureDevice.requestAccess(for: .video) else { return .denied }
        default:
            return .denied
        }

        return await withCheckedContinuation { continuation in
            queue.async { continuation.resume(returning: self.buildSession()) }
        }
    }

    func start(onCode: @escaping @Sendable (String) -> Void) {
        queue.async {
            self.onCode = onCode
            self.hasFoundCode = false
            if !self.session.isRunning { self.session.startRunning() }
        }
    }

    func stop() {
        queue.async {
            if self.session.isRunning { self.session.stopRunning() }
        }
    }

    func setTorch(_ isOn: Bool) {
        queue.async {
            guard let device = self.device, device.hasTorch else { return }
            do {
                try device.lockForConfiguration()
            } catch {
                return
            }
            device.torchMode = isOn ? .on : .off
            device.unlockForConfiguration()
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard !hasFoundCode,
              Date().timeIntervalSince(lastAnalysis) >= Self.analysisInterval,
              let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        lastAnalysis = Date()
        guard let code = (try? detector.payloads(in: buffer))?.first else { return }

        hasFoundCode = true
        onCode?(code)
    }

    private func buildSession() -> CameraSetupResult {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input),
              session.canAddOutput(output) else {
            return .unavailable
        }

        session.beginConfiguration()
        session.sessionPreset = .hd1280x720
        session.addInput(input)
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: queue)
        session.addOutput(output)
        session.commitConfiguration()

        self.device = device
        return .ready
    }
}
