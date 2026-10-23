//
//  URLAnalyzer.swift
//  ScamShield
//
//  Created by student2 on 2026-10-23.
//

import Foundation

//checks a link on device for common phishing tricks before any network call
struct URLAnalyzer {

    static let shortenerHosts: Set<String> = [
        "bit.ly", "tinyurl.com", "t.co", "goo.gl", "is.gd", "ow.ly",
        "cutt.ly", "rb.gy", "shorturl.at", "tiny.cc", "s.id"
    ]

    static let suspiciousTLDs: Set<String> = [
        "zip", "mov", "xyz", "top", "click", "link", "live", "icu",
        "buzz", "rest", "cam", "sbs", "cfd", "gq", "tk", "ml", "cf", "ga"
    ]

    static let sensitiveWords = ["login", "verify", "update", "secure", "account", "banking", "otp", "wallet", "confirm"]

    //brand name mapped to the only domains that brand really uses
    static let officialDomains: [String: Set<String>] = [
        "paypal": ["paypal.com"],
        "apple": ["apple.com", "icloud.com"],
        "google": ["google.com", "google.lk"],
        "amazon": ["amazon.com"],
        "microsoft": ["microsoft.com", "live.com", "outlook.com"],
        "netflix": ["netflix.com"],
        "whatsapp": ["whatsapp.com"],
        "boc": ["boc.lk"],
        "peoplesbank": ["peoplesbank.lk"],
        "sampath": ["sampath.lk"],
        "combank": ["combank.lk", "combank.com.lk"],
        "hnb": ["hnb.lk", "hnb.net"],
        "dialog": ["dialog.lk"],
        "mobitel": ["mobitel.lk"]
    ]

    //second level parts that belong to the tld like com.lk or co.uk
    private static let compoundSuffixes: Set<String> = ["com", "co", "gov", "ac", "org", "net", "edu"]

    //turns user input into a url and adds https when no scheme was typed
    static func normalize(_ raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.contains(" ") else { return nil }

        let withScheme = trimmed.contains("://") ? trimmed : "https://" + trimmed
        guard let url = URL(string: withScheme),
              let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme),
              let host = url.host(), host.contains(".") else {
            return nil
        }
        return url
    }

    //returns the part of the host a person actually registers
    static func registeredDomain(of host: String) -> String {
        let labels = host.lowercased().split(separator: ".").map(String.init)
        guard labels.count > 2 else { return labels.joined(separator: ".") }

        let secondLast = labels[labels.count - 2]
        let keep = compoundSuffixes.contains(secondLast) && labels.last!.count == 2 ? 3 : 2
        return labels.suffix(keep).joined(separator: ".")
    }

    func analyze(_ url: URL) -> [RiskSignal] {
        var signals: [RiskSignal] = []
        let host = (url.host() ?? "").lowercased()
        let domain = Self.registeredDomain(of: host)
        let fullText = url.absoluteString.lowercased()

        if url.scheme?.lowercased() != "https" {
            signals.append(RiskSignal(title: "Not encrypted", detail: "The link uses http so data you enter can be read by others.", weight: 15))
        }

        if isIPAddress(host) {
            signals.append(RiskSignal(title: "Raw IP address", detail: "Real companies use a domain name, not a number address.", weight: 30))
        }

        if host.contains("xn--") {
            signals.append(RiskSignal(title: "Lookalike characters", detail: "The address uses special letters that can imitate a real website.", weight: 30))
        }

        if url.user != nil {
            signals.append(RiskSignal(title: "Hidden destination", detail: "Text before an @ sign hides the real website you will open.", weight: 25))
        }

        if Self.shortenerHosts.contains(host) {
            signals.append(RiskSignal(title: "Shortened link", detail: "Short links hide where they really go.", weight: 15))
        }

        if let tld = host.split(separator: ".").last, Self.suspiciousTLDs.contains(String(tld)) {
            signals.append(RiskSignal(title: "Unusual domain ending", detail: "The .\(tld) ending is often used by scam websites.", weight: 15))
        }

        if host.split(separator: ".").count > 4 {
            signals.append(RiskSignal(title: "Too many subdomains", detail: "Long chains of subdomains are used to look like a trusted site.", weight: 10))
        }

        if domain.filter({ $0 == "-" }).count >= 2 {
            signals.append(RiskSignal(title: "Many hyphens", detail: "Domains with many hyphens are common in phishing.", weight: 10))
        }

        //a brand name in the host that is not on that brand's real domain
        if let brand = Self.officialDomains.first(where: { host.contains($0.key) && !$0.value.contains(domain) }) {
            signals.append(RiskSignal(title: "Brand impersonation", detail: "Mentions \(brand.key) but is not on an official \(brand.key) website.", weight: 35))
        }

        if let word = Self.sensitiveWords.first(where: { fullText.contains($0) }) {
            signals.append(RiskSignal(title: "Sensitive wording", detail: "The link contains \"\(word)\", which scams use to ask for details.", weight: 10))
        }

        if fullText.count > 100 {
            signals.append(RiskSignal(title: "Very long link", detail: "Very long links can hide the real address.", weight: 5))
        }

        return signals
    }

    private func isIPAddress(_ host: String) -> Bool {
        let parts = host.split(separator: ".")
        return parts.count == 4 && parts.allSatisfy { UInt8($0) != nil }
    }
}
