//
//  QRPayloadParser.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import Foundation

enum QRPayload: Equatable {
    case url(URL)
    case wifi(ssid: String, security: String?)
    case sms(number: String, body: String?)
    case phone(String)
    case email(String)
    case payment
    case unsupported(scheme: String)
    case text(String)

    //what is saved in history, a wi-fi password is never kept
    var displayText: String {
        switch self {
        case .url(let url): url.absoluteString
        case .wifi(let ssid, _): "Wi-Fi network: \(ssid)"
        case .sms(let number, let body): body.map { "Text to \(number): \($0)" } ?? "Text to \(number)"
        case .phone(let number): "Call \(number)"
        case .email(let address): "Email to \(address)"
        case .payment: "Payment request"
        case .unsupported(let scheme): "Unsupported code (\(scheme):)"
        case .text(let text): String(text.prefix(200))
        }
    }

    var isPlainText: Bool {
        if case .text = self { return true }
        return false
    }
}

//works out what a scanned code would make the phone do before anything is opened
enum QRPayloadParser {

    static let dangerousSchemes: Set<String> = ["javascript", "data", "file", "intent", "vbscript"]

    static func parse(_ raw: String) -> QRPayload {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = text.lowercased()

        if lower.hasPrefix("wifi:") { return parseWifi(text) }
        if lower.hasPrefix("smsto:") || lower.hasPrefix("sms:") { return parseSMS(text) }
        if lower.hasPrefix("tel:") { return .phone(path(of: text, dropping: 4)) }
        if lower.hasPrefix("mailto:") { return .email(path(of: text, dropping: 7)) }
        if lower.hasPrefix("upi:") || lower.hasPrefix("000201") { return .payment }

        if lower.hasPrefix("http://") || lower.hasPrefix("https://") {
            if let url = URL(string: text), url.host() != nil { return .url(url) }
            return .text(text)
        }

        if let scheme = scheme(of: lower), dangerousSchemes.contains(scheme) {
            return .unsupported(scheme: scheme)
        }
        if let url = URLAnalyzer.normalize(text) { return .url(url) }
        return .text(text)
    }

    static func signals(for payload: QRPayload) -> [RiskSignal] {
        switch payload {
        case .url:
            return []
        case .wifi(_, let security):
            let isOpen = security == nil || security?.lowercased() == "nopass"
            if isOpen {
                return [RiskSignal(title: "Open Wi-Fi network", detail: "Anyone nearby can read what you send on a network without a password.", weight: 25)]
            }
            return [RiskSignal(title: "Joins a Wi-Fi network", detail: "Scanning would connect your phone to this network. Only join networks you recognise.", weight: 10)]
        case .sms:
            return [RiskSignal(title: "Pre-filled text message", detail: "This code prepares a text to a number you did not choose. Scams use this to sign you up for paid services.", weight: 30)]
        case .phone:
            return [RiskSignal(title: "Starts a phone call", detail: "Calling an unknown number can cost money or put you in touch with a scammer.", weight: 20)]
        case .email:
            return [RiskSignal(title: "Starts an email", detail: "Only write to addresses you trust.", weight: 10)]
        case .payment:
            return [RiskSignal(title: "Payment request", detail: "Check the receiver name and the amount before you pay. You never need to pay to receive money.", weight: 30)]
        case .unsupported(let scheme):
            return [RiskSignal(title: "Unusual code", detail: "This code uses \(scheme): which can run commands on your phone. Do not open it.", weight: 40)]
        case .text:
            return [RiskSignal(title: "Plain text", detail: "This code only contains text and cannot open anything.", weight: 0)]
        }
    }

    private static func parseWifi(_ text: String) -> QRPayload {
        var ssid = ""
        var security: String?

        for field in splitFields(String(text.dropFirst("WIFI:".count))) {
            guard let colon = field.firstIndex(of: ":") else { continue }
            let key = field[..<colon].uppercased()
            let value = String(field[field.index(after: colon)...])

            switch key {
            case "S": ssid = value
            case "T": security = value
            default: break
            }
        }
        return .wifi(ssid: ssid.isEmpty ? "Unknown network" : ssid, security: security)
    }

    private static func parseSMS(_ text: String) -> QRPayload {
        if text.lowercased().hasPrefix("smsto:") {
            let parts = text.dropFirst(6).split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            let number = parts.first.map(String.init) ?? ""
            let body = parts.count > 1 ? String(parts[1]) : ""
            return .sms(number: number, body: body.isEmpty ? nil : body)
        }

        let components = URLComponents(string: text)
        let number = components?.path ?? String(text.dropFirst(4))
        let body = components?.queryItems?.first { $0.name.lowercased() == "body" }?.value
        return .sms(number: number, body: body?.isEmpty == false ? body : nil)
    }

    private static func path(of text: String, dropping prefixLength: Int) -> String {
        URLComponents(string: text)?.path ?? String(text.dropFirst(prefixLength))
    }

    //fields end at a semicolon unless it is escaped with a backslash
    private static func splitFields(_ body: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var isEscaped = false

        for character in body {
            if isEscaped {
                current.append(character)
                isEscaped = false
            } else if character == "\\" {
                isEscaped = true
            } else if character == ";" {
                fields.append(current)
                current = ""
            } else {
                current.append(character)
            }
        }
        if !current.isEmpty { fields.append(current) }
        return fields
    }

    private static func scheme(of text: String) -> String? {
        guard let colon = text.firstIndex(of: ":") else { return nil }
        let candidate = text[..<colon]
        let isScheme = !candidate.isEmpty && candidate.allSatisfy { $0.isLetter || $0.isNumber || "+-.".contains($0) }
        return isScheme ? String(candidate) : nil
    }
}
