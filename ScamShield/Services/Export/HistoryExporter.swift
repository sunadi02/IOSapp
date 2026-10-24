//
//  HistoryExporter.swift
//  ScamShield
//
//  Created by student2 on 2026-10-25.
//

import Foundation
import CoreTransferable
import UniformTypeIdentifiers

//turns the scan history into a spreadsheet that opens in Numbers, Excel or Google Sheets
enum HistoryExporter {

    static let header = ["Date", "Type", "Checked", "Result", "Trust score", "Main reason"]
    static let fileName = "ScamShield History.csv"

    static func csv(for scans: [ScanResult]) -> String {
        let rows = [header] + scans.map(row(for:))
        return rows
            .map { $0.map(escape).joined(separator: ",") }
            .joined(separator: "\r\n") + "\r\n"
    }

    //a scanned message stays private, so only the fact that one was checked is written
    static func row(for scan: ScanResult) -> [String] {
        [
            scan.date.ISO8601Format(),
            scan.type.title,
            scan.type == .screenshot ? "Message screenshot" : scan.input,
            scan.riskLevel.title,
            String(scan.trustScore),
            mainReason(for: scan)
        ]
    }

    //a QR code can hold text such as =HYPERLINK(...), so a cell that would start a formula is made plain text first
    static func escape(_ field: String) -> String {
        var value = field
        if let first = value.unicodeScalars.first, "=+-@\t\r".unicodeScalars.contains(first) {
            value = "'" + value
        }

        let needsQuotes = value.unicodeScalars.contains { ",\"\n\r".unicodeScalars.contains($0) }
        guard needsQuotes else { return value }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private static func mainReason(for scan: ScanResult) -> String {
        guard let top = scan.signals.max(by: { $0.weight < $1.weight }), top.weight > 0 else { return "" }
        return top.title
    }
}

//the finished spreadsheet as a file for the share sheet
nonisolated struct HistoryExportFile: Transferable {

    let text: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { file in
            Data(file.text.utf8)
        }
        .suggestedFileName("ScamShield History.csv")
    }
}
