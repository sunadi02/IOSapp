//
//  ScreenshotScanViewModel.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import Foundation
import Observation

@Observable
final class ScreenshotScanViewModel {

    var text = ""
    var result: ScanResult?
    var errorMessage: String?

    private(set) var isRecognising = false
    private(set) var isChecking = false

    private let recognizer: TextRecognizing
    private let scanner: MessageScanner
    private let history: HistoryStoring

    init(
        recognizer: TextRecognizing = TextRecognizer(),
        scanner: MessageScanner = MessageScanner(),
        history: HistoryStoring = AppHistory.store
    ) {
        self.recognizer = recognizer
        self.scanner = scanner
        self.history = history
    }

    var canCheck: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isChecking && !isRecognising
    }

    var detectedLinks: [URL] {
        LinkExtractor.links(in: text)
    }

    func recognize(imageData: Data) async {
        guard !isRecognising else { return }
        errorMessage = nil
        isRecognising = true
        defer { isRecognising = false }

        let recognizer = recognizer
        let recognised = await Task.detached { try? recognizer.recognizeText(inImageData: imageData) }.value

        guard let recognised, !recognised.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "No text was found in that screenshot. Try a clearer picture, or paste the message instead."
            return
        }
        text = recognised
    }

    func check() async {
        guard canCheck else { return }
        errorMessage = nil
        isChecking = true
        defer { isChecking = false }

        do {
            let scan = try await scanner.scan(text)
            try? history.save(scan)
            result = scan
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
