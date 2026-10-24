//
//  TextRecognizer.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import Foundation
import CoreGraphics
import Vision

//protocol so the screenshot screen can be tested without real images
nonisolated protocol TextRecognizing: Sendable {
    func recognizeText(inImageData data: Data) throws -> String
}

//reads the text in an image on the device, nothing is uploaded
nonisolated struct TextRecognizer: TextRecognizing {

    func recognizeText(inImageData data: Data) throws -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        try VNImageRequestHandler(data: data, options: [:]).perform([request])

        let lines = (request.results ?? []).compactMap { observation -> (text: String, box: CGRect)? in
            guard let text = observation.topCandidates(1).first?.string else { return nil }
            return (text, observation.boundingBox)
        }
        return Self.readingOrder(lines)
    }

    //vision boxes start at the bottom left, so higher means earlier, and pieces on one row read left to right
    static func readingOrder(_ lines: [(text: String, box: CGRect)]) -> String {
        var rows: [[(text: String, box: CGRect)]] = []

        for line in lines.sorted(by: { $0.box.midY > $1.box.midY }) {
            if let first = rows.last?.first,
               abs(first.box.midY - line.box.midY) < min(first.box.height, line.box.height) * 0.5 {
                rows[rows.count - 1].append(line)
            } else {
                rows.append([line])
            }
        }

        return rows
            .map { row in row.sorted { $0.box.minX < $1.box.minX }.map(\.text).joined(separator: " ") }
            .joined(separator: "\n")
    }
}
