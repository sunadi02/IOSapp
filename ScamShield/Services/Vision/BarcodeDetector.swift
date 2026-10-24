//
//  BarcodeDetector.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import Foundation
import ImageIO
import CoreVideo
import Vision

//protocol so the scanner can be tested without a camera or real images
nonisolated protocol BarcodeDetecting: Sendable {
    func payloads(inImageData data: Data) throws -> [String]
    func payloads(in pixelBuffer: CVPixelBuffer) throws -> [String]
}

//finds qr codes with vision and returns the text each one holds
nonisolated struct BarcodeDetector: BarcodeDetecting {

    func payloads(inImageData data: Data) throws -> [String] {
        try payloads(using: VNImageRequestHandler(data: data, options: [:]))
    }

    //camera frames arrive sideways so vision is told the phone is held upright
    func payloads(in pixelBuffer: CVPixelBuffer) throws -> [String] {
        try payloads(using: VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:]))
    }

    private func payloads(using handler: VNImageRequestHandler) throws -> [String] {
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr]
        try handler.perform([request])
        return (request.results ?? []).compactMap(\.payloadStringValue)
    }
}
