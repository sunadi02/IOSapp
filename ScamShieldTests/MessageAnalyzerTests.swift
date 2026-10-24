//
//  MessageAnalyzerTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-24.
//

import Testing
import Foundation
@testable import ScamShield

@MainActor
struct MessageAnalyzerTests {

    let analyzer = MessageAnalyzer()

    private func titles(_ text: String, links: [URL] = []) -> [String] {
        analyzer.analyze(text, links: links).signals.map(\.title)
    }

    @Test(arguments: [
        ("URGENT: reply today", "Pressure to act fast"),
        ("Congratulations, you won a prize", "Prize or refund offer"),
        ("Your card has been blocked", "Threat of losing access"),
        ("Pay the redelivery fee for your parcel", "Delivery fee request"),
        ("Please share your OTP", "Asks for your OTP, PIN or password"),
        ("Kindly verify your account details", "Asks you to verify your details")
    ])
    func scamWordingRaisesTheMatchingSignal(text: String, expected: String) {
        #expect(titles(text).contains(expected))
    }

    @Test func inflectedWordsStillMatchTheirBaseForm() {
        #expect(titles("We are verifying your account").contains("Asks you to verify your details"))
    }

    @Test(arguments: [
        "Your OTP is 482913. Do not share it with anyone.",
        "Never share your PIN or OTP with anyone.",
        "Do not send your password to anyone, even bank staff.",
        "Don't give your OTP to anybody."
    ])
    func warningsNotToShareASecretAreNotScams(text: String) {
        #expect(!titles(text).contains("Asks for your OTP, PIN or password"))
    }

    @Test(arguments: [
        "Hi, are we still meeting for lunch at 1pm tomorrow?",
        "Your Dialog bill for March is Rs. 1,250.",
        "Your OTP is 482913. Do not share it with anyone.",
        "Your parcel was delivered to the front desk.",
        "Please pay your electricity bill by Friday."
    ])
    func ordinaryMessagesRaiseNothing(text: String) {
        #expect(analyzer.analyze(text).signals.isEmpty)
    }

    @Test func emptyTextRaisesNothing() {
        #expect(analyzer.analyze("").signals.isEmpty)
    }

    @Test func reasonQuotesTheWordsThatMatched() throws {
        let signal = try #require(analyzer.analyze("Reply immediately").signals.first)
        #expect(signal.detail.contains("\"immediately\""))
    }

    @Test func eachCategoryGivesOneSignalWhateverTheNumberOfMatches() {
        let text = "URGENT! Act now, reply immediately"
        #expect(titles(text).filter { $0 == "Pressure to act fast" }.count == 1)
    }

    @Test func suspiciousWordsAreHighlighted() {
        let text = "Please verify your details immediately"
        let highlighted = analyzer.analyze(text).highlights.map { String(text[$0]) }
        #expect(highlighted == ["verify your details", "immediately"])
    }

    @Test func overlappingMatchesAreMergedIntoOneHighlight() {
        let text = "Please send your OTP and PIN now"
        let highlighted = analyzer.analyze(text).highlights.map { String(text[$0]) }
        #expect(highlighted == ["send your OTP and PIN"])
    }

    @Test func wordsInsideALinkAreNotTreatedAsWording() {
        let text = "See http://win-prize-refund.xyz for details"
        #expect(analyzer.analyze(text).signals.isEmpty)
    }

    @Test func brandWithAnUnofficialLinkIsFlagged() throws {
        let link = try #require(URL(string: "http://paypal-help.xyz/login"))
        let analysis = analyzer.analyze("Your PayPal account is limited. Log in now.", links: [link])

        let signal = try #require(analysis.signals.first { $0.title == "Brand name with an unofficial link" })
        #expect(signal.weight == 35)
        #expect(signal.detail.contains("paypal-help.xyz"))
    }

    @Test func bankNameMadeOfTwoWordsIsRecognised() throws {
        let link = try #require(URL(string: "https://combank-login.xyz"))
        #expect(titles("Commercial Bank needs you to log in", links: [link]).contains("Brand name with an unofficial link"))
    }

    @Test(arguments: ["https://www.paypal.com/receipt", "https://paypal.com"])
    func brandWithItsOwnLinkIsFine(address: String) throws {
        let link = try #require(URL(string: address))
        #expect(!titles("Your PayPal receipt is ready", links: [link]).contains("Brand name with an unofficial link"))
    }

    @Test func subdomainOfTheOfficialSiteIsFine() throws {
        let link = try #require(URL(string: "https://selfcare.dialog.lk/bill"))
        #expect(!titles("Your Dialog bill is ready", links: [link]).contains("Brand name with an unofficial link"))
    }

    @Test func brandWithoutAnyLinkIsNotFlagged() {
        #expect(!titles("Your PayPal account is limited").contains("Brand name with an unofficial link"))
    }

    @Test func nonEnglishMessageIsReportedAsNotFullyChecked() {
        let sinhala = String(repeating: "ඔබගේ ගිණුම අත්හිටුවා ඇත. කරුණාකර ඔබගේ විස්තර තහවුරු කරන්න. ", count: 3)
        let analysis = analyzer.analyze(sinhala)

        #expect(!analysis.isSupportedLanguage)
        #expect(analysis.signals.map(\.title) == ["Message not fully checked"])
        #expect(analysis.signals.first?.weight == 0)
    }

    @Test func englishMessageIsSupported() {
        let text = "Please remember to bring your documents to the office tomorrow morning."
        #expect(analyzer.analyze(text).isSupportedLanguage)
    }

    @Test func veryShortTextIsAlwaysAnalysed() {
        #expect(analyzer.analyze("ok").isSupportedLanguage)
    }
}
