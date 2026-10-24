//
//  SMSFilterDecisionTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-24.
//

import Testing
import Foundation
@testable import ScamShield

@MainActor
struct SMSFilterDecisionTests {

    private func titles(_ body: String, sender: String? = nil) -> [String] {
        SMSFilterDecision.signals(for: body, sender: sender).map(\.title)
    }

    @Test(arguments: [
        ("Dear customer, your Commercial Bank account is suspended. Verify your details immediately: http://combank-secure.xyz", "+94771234567"),
        ("URGENT: your account will be suspended. Share your OTP now", ""),
        ("Your parcel is held at customs. Pay a clearance fee of Rs. 350 to release it: http://srilanka-post-fee.top", ""),
        ("Congratulations! You have won Rs. 5,000,000 in the Dialog lucky draw. Claim your prize now: http://dialog-winner.top", ""),
        ("Your SIM will be blocked in 24 hours. Update your KYC details now: http://dialog-kyc.top", "+94771234567"),
        ("http://paypal-login-verify.xyz", "")
    ])
    func scamTextsAreMovedToJunk(body: String, sender: String) {
        let action = SMSFilterDecision.action(for: body, sender: sender.isEmpty ? nil : sender)
        #expect(action == .junk)
    }

    @Test(arguments: [
        ("Your OTP for the Commercial Bank transaction is 482913. Do not share it with anyone.", "COMBANK"),
        ("Never share your PIN or OTP with anyone. The bank will never ask for it.", "+94112345678"),
        ("Rs. 2,500.00 was debited from your account ending 4821 at Keells Super.", "BOC"),
        ("Hi, are we still meeting for lunch tomorrow?", "0771234567"),
        ("Your Dialog bill of Rs. 1,250 is due on 5 November. Pay via the MyDialog app.", "+94771234567"),
        ("Your parcel was delivered to the front desk at 2.15 pm.", ""),
        ("Your Commercial Bank statement is available at https://www.combank.lk", "COMBANK"),
        ("Join the meeting: https://meet.google.com/abc-defg-hij", ""),
        ("Your one time password is 904221. Use it to complete your payment. If you did not request this, ignore this message.", "COMBANK"),
        ("Congratulations on your new job! So proud of you.", "")
    ])
    func ordinaryAndGenuineTextsAreLeftAlone(body: String, sender: String) {
        let action = SMSFilterDecision.action(for: body, sender: sender.isEmpty ? nil : sender)
        #expect(action == .none)
    }

    @Test(arguments: [nil, "", "   \n "])
    func emptyTextIsLeftAlone(body: String?) {
        #expect(SMSFilterDecision.action(for: body, sender: "+94771234567") == .none)
    }

    @Test func oneMildSignalIsNotEnoughToJunkAText() {
        #expect(SMSFilterDecision.action(for: "URGENT: please call me back", sender: nil) == .none)
    }

    @Test func aRiskyLinkAloneCanBeEnough() {
        #expect(SMSFilterDecision.action(for: "Check this http://paypal-login-verify.xyz", sender: nil) == .junk)
    }

    @Test func onlyTheRiskiestLinkAddsItsSignals() throws {
        let body = "https://www.apple.com and http://paypal-login-verify.xyz"
        let total = SMSFilterDecision.signals(for: body, sender: nil).reduce(0) { $0 + $1.weight }

        let worst = try #require(URL(string: "http://paypal-login-verify.xyz"))
        let expected = URLAnalyzer().analyze(worst).reduce(0) { $0 + $1.weight }
        #expect(total == expected)
    }

    @Test(arguments: [
        "Please do not share your OTP with anyone",
        "Never send your password to anyone",
        "Don't give your PIN to anybody"
    ])
    func warningsNotToShareASecretAreNotRequests(body: String) {
        #expect(!titles(body).contains("Asks for your OTP, PIN or password"))
    }

    @Test(arguments: ["Please send your OTP to confirm", "Reply with your password today", "Kindly share your PIN"])
    func requestsForASecretAreCaught(body: String) {
        #expect(titles(body).contains("Asks for your OTP, PIN or password"))
    }

    @Test func requestToVerifyDetailsIsCaught() {
        #expect(titles("Kindly verify your account details").contains("Asks you to verify your details"))
    }

    @Test func deliveryNeedsBothAParcelWordAndAFeeWord() {
        #expect(titles("Your package needs a handling fee").contains("Delivery fee request"))
        #expect(!titles("Your package arrived").contains("Delivery fee request"))
        #expect(!titles("Pay your bill by Friday").contains("Delivery fee request"))
    }

    @Test func bankMessageFromAPersonalNumberIsFlagged() throws {
        let signals = SMSFilterDecision.signals(for: "Your Sampath account needs attention", sender: "+94771234567")
        let signal = try #require(signals.first { $0.title == "Bank message from a personal number" })
        #expect(signal.weight == 20)
    }

    @Test(arguments: ["SAMPATH", "12345", ""])
    func bankMessageFromABankNameIsNotFlagged(sender: String) {
        #expect(!titles("Your Sampath account needs attention", sender: sender).contains("Bank message from a personal number"))
    }

    @Test func bankMessageWithoutAnySenderIsNotFlagged() {
        #expect(!titles("Your Sampath account needs attention", sender: nil).contains("Bank message from a personal number"))
    }

    @Test func personalNumberAloneIsNotAWarning() {
        #expect(titles("See you at lunch", sender: "+94771234567").isEmpty)
    }

    @Test(arguments: [
        ("0771234567", true),
        ("+94771234567", true),
        ("+94 77 123 4567", true),
        ("077-123-4567", true),
        ("12345", false),
        ("COMBANK", false),
        ("BOC-LK", false),
        ("+9477abc4567", false),
        ("", false)
    ])
    func personalNumbersAreToldApartFromSenderNames(sender: String, expected: Bool) {
        #expect(SMSFilterDecision.isPersonalNumber(sender) == expected)
    }
}
