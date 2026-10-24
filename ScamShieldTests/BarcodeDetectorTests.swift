//
//  BarcodeDetectorTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-24.
//

import Testing
import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
@testable import ScamShield

//these run the real vision request on images drawn inside the test
@MainActor
struct BarcodeDetectorTests {

    private let detector = BarcodeDetector()

    //draws a qr code on a white background with a quiet border like a printed one
    private func qrImage(_ text: String) throws -> Data {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)

        let code = try #require(filter.outputImage).transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        let background = CIImage(color: .white).cropped(to: code.extent.insetBy(dx: -60, dy: -60))
        let image = code.composited(over: background)

        return try #require(CIContext().pngRepresentation(of: image, format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB()))
    }

    private func blankImage() throws -> Data {
        let image = CIImage(color: .white).cropped(to: CGRect(x: 0, y: 0, width: 300, height: 300))
        return try #require(CIContext().pngRepresentation(of: image, format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB()))
    }

    @Test func readsALinkFromAQRImage() throws {
        let data = try qrImage("https://example.com/offer")
        #expect(try detector.payloads(inImageData: data) == ["https://example.com/offer"])
    }

    @Test func readsPlainTextFromAQRImage() throws {
        let data = try qrImage("Table 12")
        #expect(try detector.payloads(inImageData: data) == ["Table 12"])
    }

    @Test func imageWithoutACodeGivesNothing() throws {
        #expect(try detector.payloads(inImageData: blankImage()).isEmpty)
    }

    @Test func dataThatIsNotAnImageThrows() {
        #expect(throws: (any Error).self) {
            try detector.payloads(inImageData: Data([1, 2, 3, 4]))
        }
    }

    @Test func decodedLinkGoesStraightIntoTheScanner() async throws {
        let data = try qrImage("http://paypal-login-verify.xyz")
        let code = try #require(try detector.payloads(inImageData: data).first)

        let scanner = QRScanner(linkScanner: LinkScanner(reputation: MockReputationChecker()))
        let result = try await scanner.scan(payload: code)
        #expect(result.type == .qr)
        #expect(result.riskLevel == .risky)
    }
}
