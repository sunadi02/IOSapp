//
//  IntentLinkChecker.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import Foundation

//runs a link check for Siri and Shortcuts and keeps it in the history like any other scan
struct IntentLinkChecker {

    let scanner: LinkScanner
    let history: HistoryStoring

    init(scanner: LinkScanner = IntentServices.linkScanner, history: HistoryStoring = IntentServices.history) {
        self.scanner = scanner
        self.history = history
    }

    func check(_ link: String) async throws -> ScanResult {
        let result = try await scanner.scan(link)
        //a failed save should not stop the answer being read out
        try? history.save(result)
        return result
    }
}
