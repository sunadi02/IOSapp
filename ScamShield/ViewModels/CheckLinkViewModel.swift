//
//  CheckLinkViewModel.swift
//  ScamShield
//
//  Created by student2 on 2026-10-23.
//

import Foundation
import Observation

@Observable
final class CheckLinkViewModel {

    var input = ""
    var errorMessage: String?
    var result: ScanResult?
    private(set) var isChecking = false

    private let scanner: LinkScanner
    private let history: HistoryStoring

    init(scanner: LinkScanner = LinkScanner(), history: HistoryStoring = AppHistory.store) {
        self.scanner = scanner
        self.history = history
    }

    var canCheck: Bool {
        !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isChecking
    }

    func check() async {
        guard canCheck else { return }
        errorMessage = nil
        isChecking = true
        defer { isChecking = false }

        do {
            let scan = try await scanner.scan(input)
            //a failed save should not hide the result from the user
            try? history.save(scan)
            result = scan
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
