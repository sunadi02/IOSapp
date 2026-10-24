//
//  SMSFilterDecision.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import Foundation

//decides what the SMS filter extension does with a text
//it uses plain text matching only, no NaturalLanguage or Core ML, so it stays small and fast inside the extension
enum SMSFilterDecision {

    enum Action: Equatable {
        case none
        case junk
    }

    private struct Rule {
        let title: String
        let detail: String
        let weight: Int
        let pattern: NSRegularExpression

        init(title: String, detail: String, weight: Int, phrases: [String]) {
            self.title = title
            self.detail = detail
            self.weight = weight
            pattern = SMSFilterDecision.makeRegex(phrases)
        }
    }

    private static let wordingRules: [Rule] = [
        Rule(title: "Pressure to act fast", detail: "Scams rush you so you do not stop to think.", weight: 15, phrases: [
            "immediately", "urgent", "urgently", "act now", "within 24 hours", "final notice", "last warning",
            "expires today", "limited time"
        ]),
        Rule(title: "Prize or refund offer", detail: "Unexpected prizes and refunds are a common way to steal your details.", weight: 20, phrases: [
            "you have won", "you've won", "you’ve won", "winner", "lottery", "prize", "congratulations",
            "claim your", "refund", "cashback", "jackpot"
        ]),
        Rule(title: "Threat of losing access", detail: "Scammers threaten to block or close accounts to scare you into acting.", weight: 20, phrases: [
            "suspended", "will be blocked", "has been blocked", "is blocked", "deactivated", "terminated",
            "legal action", "arrest", "will be closed", "frozen", "disconnected"
        ])
    ]

    private static let deliveryWords = makeRegex(["parcel", "package", "courier", "shipment", "customs", "delivery"])
    private static let feeWords = makeRegex(["fee", "fees", "charge", "charges", "pay", "payment", "redelivery"])

    private static let secretRequest = try! NSRegularExpression(
        pattern: #"\b(?:share|send|reply|provide|give|enter|tell|forward|disclose)\b[^.!?\n]{0,30}\b(?:otp|pin|password|passcode|cvv)\b"#,
        options: .caseInsensitive
    )

    private static let verifyRequest = try! NSRegularExpression(
        pattern: #"\b(?:verify|confirm|update|validate)\b[^.!?\n]{0,25}\b(?:account|details|information|identity|kyc|card|profile)\b"#,
        options: .caseInsensitive
    )

    private static let negations = ["not ", "never ", "n't ", "n’t "]

    //banks and phone companies write from their own name, not from an ordinary phone number
    private static let brandWords = makeRegex([
        "commercial bank", "combank", "bank of ceylon", "boc", "people's bank", "peoples bank", "sampath",
        "hnb", "hatton national bank", "nsb", "seylan", "ndb", "dfcc", "dialog", "mobitel", "paypal"
    ])

    //a message is only moved to Junk when it would be called Risky in the app
    static func action(for messageBody: String?, sender: String?) -> Action {
        let body = (messageBody ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return .none }

        let trust = RiskScorer.trustScore(for: signals(for: body, sender: sender))
        return trust < RiskScorer.riskyBelow ? .junk : .none
    }

    static func signals(for body: String, sender: String?) -> [RiskSignal] {
        var signals: [RiskSignal] = []

        for rule in wordingRules where hasMatch(rule.pattern, in: body) {
            signals.append(RiskSignal(title: rule.title, detail: rule.detail, weight: rule.weight))
        }

        if hasMatch(deliveryWords, in: body), hasMatch(feeWords, in: body) {
            signals.append(RiskSignal(title: "Delivery fee request", detail: "Real couriers do not ask for fees by text or link.", weight: 20))
        }
        if hasRequest(secretRequest, in: body) {
            signals.append(RiskSignal(title: "Asks for your OTP, PIN or password", detail: "Banks never ask for these by message or call.", weight: 30))
        }
        if hasRequest(verifyRequest, in: body) {
            signals.append(RiskSignal(title: "Asks you to verify your details", detail: "Banks do not ask you to verify or update account details through a message.", weight: 25))
        }
        if let sender, isPersonalNumber(sender), hasMatch(brandWords, in: body) {
            signals.append(RiskSignal(title: "Bank message from a personal number", detail: "Banks and phone companies send messages from their own name, not from a normal phone number.", weight: 20))
        }

        return signals + worstLinkSignals(in: body)
    }

    static func isPersonalNumber(_ sender: String) -> Bool {
        let trimmed = sender.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed.allSatisfy({ $0.isNumber || "+-() ".contains($0) }) else { return false }
        return trimmed.filter(\.isNumber).count >= 9
    }

    //only the riskiest link counts so a message with several links is not punished several times
    private static func worstLinkSignals(in text: String) -> [RiskSignal] {
        let analyzer = URLAnalyzer()
        let results = LinkExtractor.links(in: text).map { analyzer.analyze($0) }
        return results.max { totalWeight($0) < totalWeight($1) } ?? []
    }

    private static func totalWeight(_ signals: [RiskSignal]) -> Int {
        signals.reduce(0) { $0 + $1.weight }
    }

    private static func makeRegex(_ phrases: [String]) -> NSRegularExpression {
        let alternatives = phrases.map { NSRegularExpression.escapedPattern(for: $0) }.joined(separator: "|")
        return try! NSRegularExpression(pattern: "\\b(?:\(alternatives))\\b", options: .caseInsensitive)
    }

    private static func hasMatch(_ regex: NSRegularExpression, in text: String) -> Bool {
        regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
    }

    //a request such as "share your OTP" counts, a warning such as "do not share your OTP" does not
    private static func hasRequest(_ regex: NSRegularExpression, in text: String) -> Bool {
        let nsText = text as NSString

        return regex.matches(in: text, range: NSRange(location: 0, length: nsText.length)).contains { match in
            let start = max(0, match.range.location - 15)
            let before = nsText.substring(with: NSRange(location: start, length: match.range.location - start)).lowercased()
            return !negations.contains { before.contains($0) }
        }
    }
}
