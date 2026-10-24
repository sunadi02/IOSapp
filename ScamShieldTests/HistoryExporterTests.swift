//
//  HistoryExporterTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-25.
//

import Testing
import Foundation
@testable import ScamShield

@MainActor
struct HistoryExporterTests {

    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private func scan(
        _ type: ScanType = .link,
        input: String = "https://evil.example.com/login",
        signals: [RiskSignal] = []
    ) -> ScanResult {
        ScanResult(type: type, input: input, riskLevel: .risky, trustScore: 20, signals: signals, date: date)
    }

    private func lines(_ csv: String) -> [String] {
        csv.components(separatedBy: "\r\n").filter { !$0.isEmpty }
    }

    @Test func firstLineNamesTheColumns() {
        let first = lines(HistoryExporter.csv(for: [scan()])).first
        #expect(first == "Date,Type,Checked,Result,Trust score,Main reason")
    }

    @Test func eachScanIsOneRow() {
        let csv = HistoryExporter.csv(for: [scan(), scan(.qr, input: "https://shop.example.com")])
        #expect(lines(csv).count == 3)
    }

    @Test func emptyHistoryGivesJustTheHeader() {
        #expect(lines(HistoryExporter.csv(for: [])).count == 1)
    }

    @Test func rowsEndWithTheStandardLineBreak() {
        #expect(HistoryExporter.csv(for: [scan()]).hasSuffix("\r\n"))
    }

    @Test func rowHoldsTheDateTypeLinkResultScoreAndReason() {
        let signals = [
            RiskSignal(title: "Unusual domain ending", detail: "x", weight: 15),
            RiskSignal(title: "Brand impersonation", detail: "x", weight: 35)
        ]
        let row = HistoryExporter.row(for: scan(signals: signals))

        #expect(row == [date.ISO8601Format(), "Link", "https://evil.example.com/login", "Risky", "20", "Brand impersonation"])
    }

    @Test func noWarningsMeansAnEmptyReason() {
        let note = RiskSignal(title: "Online check unavailable", detail: "x", weight: 0)
        #expect(HistoryExporter.row(for: scan(signals: [note])).last == "")
    }

    @Test func messageTextIsNeverWritten() {
        let message = scan(.screenshot, input: "Share your OTP 482913 with us")
        let csv = HistoryExporter.csv(for: [message])

        #expect(HistoryExporter.row(for: message)[2] == "Message screenshot")
        #expect(!csv.contains("482913"))
    }

    @Test(arguments: [
        ("plain text", "plain text"),
        ("a,b", "\"a,b\""),
        ("say \"hi\"", "\"say \"\"hi\"\"\""),
        ("two\nlines", "\"two\nlines\"")
    ])
    func fieldsAreQuotedOnlyWhenTheyNeedIt(field: String, expected: String) {
        #expect(HistoryExporter.escape(field) == expected)
    }

    @Test(arguments: [
        ("=1+1", "'=1+1"),
        ("+94 77 123 4567", "'+94 77 123 4567"),
        ("-run", "'-run"),
        ("@everyone", "'@everyone")
    ])
    func cellsThatWouldRunAsAFormulaBecomePlainText(field: String, expected: String) {
        #expect(HistoryExporter.escape(field) == expected)
    }

    @Test func formulaWithACommaIsBothProtectedAndQuoted() {
        #expect(HistoryExporter.escape("=HYPERLINK(\"http://evil.com\",\"Click\")") == "\"'=HYPERLINK(\"\"http://evil.com\"\",\"\"Click\"\")\"")
    }

    @Test func maliciousQRTextCannotBreakTheSpreadsheet() {
        let qr = scan(.qr, input: "=cmd|' /C calc'!A0")
        let row = lines(HistoryExporter.csv(for: [qr]))[1]
        #expect(row.contains(",'=cmd|"))
    }
}
