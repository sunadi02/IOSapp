//
//  MessageAnalyzer.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import Foundation
import NaturalLanguage

struct MessageAnalysis {
    let signals: [RiskSignal]
    let highlights: [Range<String.Index>]
    let isSupportedLanguage: Bool
}

//reads a message on the device with NaturalLanguage, matching the meaning of words so "verifying" counts as "verify"
struct MessageAnalyzer {

    private struct Token {
        let surface: String
        let lemma: String
        let range: Range<String.Index>

        func matches(_ word: String) -> Bool {
            surface == word || lemma == word
        }

        func isAny(of words: Set<String>) -> Bool {
            words.contains(surface) || words.contains(lemma)
        }
    }

    private struct Finding {
        let signal: RiskSignal
        let ranges: [Range<String.Index>]
    }

    private struct Rule {
        let title: String
        let detail: String
        let weight: Int
        let phrases: [[String]]
    }

    private struct Mention {
        let brand: String
        let range: Range<String.Index>
    }

    private static let rules: [Rule] = [
        Rule(title: "Pressure to act fast", detail: "Scams rush you so you do not stop to think.", weight: 15, phrases: [
            ["immediately"], ["urgent"], ["urgently"], ["asap"], ["act", "now"], ["final", "notice"], ["last", "warning"],
            ["within", "24", "hours"], ["within", "24", "hour"], ["expire"], ["expires"], ["expired"], ["limited", "time"]
        ]),
        Rule(title: "Prize or refund offer", detail: "Unexpected prizes and refunds are a common way to steal your details.", weight: 20, phrases: [
            ["win"], ["won"], ["winner"], ["prize"], ["lottery"], ["jackpot"], ["congratulation"], ["congratulations"],
            ["reward"], ["cashback"], ["refund"], ["voucher"], ["claim"]
        ]),
        Rule(title: "Threat of losing access", detail: "Scammers threaten to block or close accounts to scare you into acting.", weight: 20, phrases: [
            ["suspend"], ["suspended"], ["suspension"], ["block"], ["blocked"], ["deactivate"], ["deactivated"],
            ["terminate"], ["terminated"], ["freeze"], ["frozen"], ["locked"], ["legal", "action"], ["arrest"],
            ["unusual", "activity"], ["suspicious", "activity"], ["unauthorized"], ["unauthorised"]
        ])
    ]

    private static let deliveryWords: Set<String> = ["parcel", "package", "delivery", "delivered", "courier", "shipment", "customs"]
    private static let feeWords: Set<String> = ["fee", "charge", "pay", "paid", "payment", "redelivery"]

    private static let secretWords: Set<String> = ["otp", "pin", "password", "passcode", "cvv", "cvc"]
    private static let requestVerbs: Set<String> = [
        "share", "shared", "sharing", "send", "sent", "sending", "provide", "give", "enter", "reply", "tell",
        "confirm", "verify", "update", "submit", "forward", "disclose"
    ]
    private static let negations: Set<String> = ["not", "never", "no", "don't", "don’t", "don", "dont", "cannot"]

    private static let verifyVerbs: Set<String> = ["verify", "confirm", "update", "validate", "reactivate"]
    private static let verifyObjects: Set<String> = ["account", "detail", "details", "information", "identity", "kyc", "card", "profile"]

    //what people write mapped to the key used in URLAnalyzer.officialDomains
    private static let brandAliases: [String: String] = [
        "paypal": "paypal", "apple": "apple", "icloud": "apple", "google": "google", "amazon": "amazon",
        "microsoft": "microsoft", "netflix": "netflix", "whatsapp": "whatsapp",
        "boc": "boc", "bank of ceylon": "boc",
        "people's bank": "peoplesbank", "peoples bank": "peoplesbank",
        "sampath": "sampath", "sampath bank": "sampath",
        "commercial bank": "combank", "combank": "combank",
        "hnb": "hnb", "hatton national bank": "hnb",
        "dialog": "dialog", "mobitel": "mobitel"
    ]

    private static let unsupportedLanguageSignal = RiskSignal(
        title: "Message not fully checked",
        detail: "ScamShield can only read the wording of English messages for now, so only the links in this message were checked.",
        weight: 0
    )

    func analyze(_ text: String, links: [URL] = []) -> MessageAnalysis {
        guard Self.isEnglishOrUnknown(text) else {
            return MessageAnalysis(signals: [Self.unsupportedLanguageSignal], highlights: [], isSupportedLanguage: false)
        }

        let tokens = Self.tokens(in: text, skipping: LinkExtractor.ranges(in: text))
        var findings: [Finding] = []

        for rule in Self.rules {
            let ranges = Self.phraseRanges(rule.phrases, in: tokens)
            if !ranges.isEmpty {
                findings.append(Self.finding(rule.title, rule.detail, rule.weight, ranges, in: text))
            }
        }

        findings += Self.deliveryFeeFindings(tokens: tokens, text: text)
        findings += Self.secretRequestFindings(tokens: tokens, text: text)
        findings += Self.verificationFindings(tokens: tokens, text: text)
        findings += Self.brandFindings(tokens: tokens, text: text, links: links)

        return MessageAnalysis(
            signals: findings.map(\.signal),
            highlights: Self.merged(findings.flatMap(\.ranges)),
            isSupportedLanguage: true
        )
    }

    //splits the message into words with their base form, so inflected words still match
    private static func tokens(in text: String, skipping linkRanges: [Range<String.Index>]) -> [Token] {
        let tagger = NLTagger(tagSchemes: [.lemma])
        tagger.string = text
        tagger.setLanguage(.english, range: text.startIndex..<text.endIndex)

        var tokens: [Token] = []
        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .lemma,
            options: [.omitWhitespace, .omitPunctuation]
        ) { tag, range in
            guard !linkRanges.contains(where: { $0.overlaps(range) }) else { return true }
            let surface = text[range].lowercased()
            tokens.append(Token(surface: surface, lemma: tag?.rawValue.lowercased() ?? surface, range: range))
            return true
        }
        return tokens
    }

    private static func isEnglishOrUnknown(_ text: String) -> Bool {
        guard text.filter(\.isLetter).count >= 20 else { return true }

        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        guard let best = recognizer.languageHypotheses(withMaximum: 1).first else { return true }
        return best.key == .english || best.value < 0.6
    }

    private static func phraseRanges(_ phrases: [[String]], in tokens: [Token]) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []

        for start in tokens.indices {
            for phrase in phrases where start + phrase.count <= tokens.count {
                let isMatch = zip(phrase, tokens[start...]).allSatisfy { word, token in token.matches(word) }
                if isMatch {
                    ranges.append(tokens[start].range.lowerBound..<tokens[start + phrase.count - 1].range.upperBound)
                }
            }
        }
        return ranges
    }

    //a delivery word together with a fee word is the pattern, either one alone is normal
    private static func deliveryFeeFindings(tokens: [Token], text: String) -> [Finding] {
        let delivery = tokens.filter { $0.isAny(of: deliveryWords) }
        let fees = tokens.filter { $0.isAny(of: feeWords) }
        guard !delivery.isEmpty, !fees.isEmpty else { return [] }

        let ranges = (delivery + fees).map(\.range)
        return [finding("Delivery fee request", "Real couriers do not ask for fees by text or link.", 20, ranges, in: text)]
    }

    //asking you to share an OTP or PIN is a scam, telling you not to share it is a normal bank warning
    private static func secretRequestFindings(tokens: [Token], text: String) -> [Finding] {
        var ranges: [Range<String.Index>] = []

        for (index, token) in tokens.enumerated() where token.isAny(of: secretWords) {
            let before = tokens[max(0, index - 5)..<index]
            let isNegated = tokens[max(0, index - 6)..<index].contains { $0.isAny(of: negations) }

            if !isNegated, let verb = before.lastIndex(where: { $0.isAny(of: requestVerbs) }) {
                ranges.append(tokens[verb].range.lowerBound..<token.range.upperBound)
            }
        }

        guard !ranges.isEmpty else { return [] }
        return [finding("Asks for your OTP, PIN or password", "Banks never ask for these by message or call.", 30, ranges, in: text)]
    }

    private static func verificationFindings(tokens: [Token], text: String) -> [Finding] {
        var ranges: [Range<String.Index>] = []

        for (index, token) in tokens.enumerated() where token.isAny(of: verifyVerbs) {
            let isNegated = tokens[max(0, index - 3)..<index].contains { $0.isAny(of: negations) }
            let after = tokens[(index + 1)..<min(tokens.count, index + 5)]

            if !isNegated, let object = after.firstIndex(where: { $0.isAny(of: verifyObjects) }) {
                ranges.append(token.range.lowerBound..<tokens[object].range.upperBound)
            }
        }

        guard !ranges.isEmpty else { return [] }
        return [finding("Asks you to verify your details", "Banks do not ask you to verify or update account details through a message.", 25, ranges, in: text)]
    }

    //a known brand in the text with links that are not on that brand's own website
    private static func brandFindings(tokens: [Token], text: String, links: [URL]) -> [Finding] {
        let linkDomains = links.compactMap { CommunityDomain.name(for: $0) }
        guard let shownDomain = linkDomains.first else { return [] }

        for mention in brandMentions(tokens: tokens, text: text) {
            guard let official = URLAnalyzer.officialDomains[mention.brand],
                  !linkDomains.contains(where: official.contains) else { continue }

            let name = String(text[mention.range])
            let signal = RiskSignal(
                title: "Brand name with an unofficial link",
                detail: "The message mentions \(name) but links to \(shownDomain), which is not an official \(name) website.",
                weight: 35
            )
            return [Finding(signal: signal, ranges: [mention.range])]
        }
        return []
    }

    private static func brandMentions(tokens: [Token], text: String) -> [Mention] {
        var mentions: [Mention] = []

        for start in tokens.indices {
            for (alias, brand) in brandAliases {
                let words = alias.split(separator: " ").map(String.init)
                guard start + words.count <= tokens.count else { continue }

                if zip(words, tokens[start...]).allSatisfy({ word, token in token.surface == word }) {
                    mentions.append(Mention(brand: brand, range: tokens[start].range.lowerBound..<tokens[start + words.count - 1].range.upperBound))
                }
            }
        }

        let linkRanges = LinkExtractor.ranges(in: text)
        for (name, range) in organisationNames(in: text) where !linkRanges.contains(where: { $0.overlaps(range) }) {
            if let brand = brandAliases[name.lowercased()] {
                mentions.append(Mention(brand: brand, range: range))
            }
        }
        return mentions.sorted { $0.range.lowerBound < $1.range.lowerBound }
    }

    private static func organisationNames(in text: String) -> [(name: String, range: Range<String.Index>)] {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text

        var names: [(name: String, range: Range<String.Index>)] = []
        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .nameType,
            options: [.omitWhitespace, .omitPunctuation, .joinNames]
        ) { tag, range in
            if tag == .organizationName { names.append((String(text[range]), range)) }
            return true
        }
        return names
    }

    //the matched words are quoted so the reason can be checked against the message
    private static func finding(
        _ title: String,
        _ detail: String,
        _ weight: Int,
        _ ranges: [Range<String.Index>],
        in text: String
    ) -> Finding {
        var seen = Set<String>()
        var quotes: [String] = []

        for range in ranges {
            let quote = String(text[range])
            if seen.insert(quote.lowercased()).inserted { quotes.append(quote) }
        }

        let shown = quotes.prefix(3).map { "\"\($0)\"" }.joined(separator: ", ")
        return Finding(signal: RiskSignal(title: title, detail: "\(detail) Found: \(shown).", weight: weight), ranges: ranges)
    }

    private static func merged(_ ranges: [Range<String.Index>]) -> [Range<String.Index>] {
        var result: [Range<String.Index>] = []

        for range in ranges.sorted(by: { $0.lowerBound < $1.lowerBound }) {
            if let last = result.last, range.lowerBound <= last.upperBound {
                result[result.count - 1] = last.lowerBound..<max(last.upperBound, range.upperBound)
            } else {
                result.append(range)
            }
        }
        return result
    }
}
