//
//  TextRecognizerTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-24.
//

import Testing
import UIKit
@testable import ScamShield

@MainActor
struct TextRecognizerTests {

    private func line(_ text: String, x: Double, y: Double) -> (text: String, box: CGRect) {
        (text, CGRect(x: x, y: y, width: 0.3, height: 0.05))
    }

    @Test func higherLinesAreReadFirst() {
        let lines = [line("second", x: 0.1, y: 0.5), line("first", x: 0.1, y: 0.8)]
        #expect(TextRecognizer.readingOrder(lines) == "first\nsecond")
    }

    @Test func piecesOnTheSameRowReadLeftToRight() {
        let lines = [line("B", x: 0.6, y: 0.5), line("A", x: 0.1, y: 0.5)]
        #expect(TextRecognizer.readingOrder(lines) == "A B")
    }

    @Test func slightlyUnevenRowsAreStillOneRow() {
        let lines = [line("right", x: 0.6, y: 0.502), line("left", x: 0.1, y: 0.5)]
        #expect(TextRecognizer.readingOrder(lines) == "left right")
    }

    @Test func noLinesGiveEmptyText() {
        #expect(TextRecognizer.readingOrder([]).isEmpty)
    }

    //these run the real vision request on an image drawn inside the test
    private func imageData(of text: String) throws -> Data {
        let size = CGSize(width: 1000, height: 220)
        let image = UIGraphicsImageRenderer(size: size).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            (text as NSString).draw(
                at: CGPoint(x: 30, y: 70),
                withAttributes: [.font: UIFont.systemFont(ofSize: 64), .foregroundColor: UIColor.black]
            )
        }
        return try #require(image.pngData())
    }

    @Test func readsTextDrawnInAnImage() throws {
        let data = try imageData(of: "Verify your account now")
        let text = try TextRecognizer().recognizeText(inImageData: data).lowercased()

        #expect(text.contains("verify"))
        #expect(text.contains("account"))
    }

    @Test func blankImageGivesNoText() throws {
        let size = CGSize(width: 400, height: 200)
        let blank = UIGraphicsImageRenderer(size: size).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        let data = try #require(blank.pngData())

        #expect(try TextRecognizer().recognizeText(inImageData: data).isEmpty)
    }

    @Test func dataThatIsNotAnImageThrows() {
        #expect(throws: (any Error).self) {
            try TextRecognizer().recognizeText(inImageData: Data([1, 2, 3, 4]))
        }
    }
}
