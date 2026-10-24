//
//  AccessibilityText.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import SwiftUI

extension ScanResult {

    //what VoiceOver reads for a scan, the text of a message is never read out
    var accessibilityDescription: String {
        let subject = type == .screenshot ? "Message screenshot" : "\(type.title) \(input)"
        return "\(subject), \(riskLevel.title), trust score \(trustScore)"
    }

    var completionAnnouncement: String {
        "Scan finished. \(riskLevel.title). Trust score \(trustScore) out of 100."
    }
}

//names for the main controls so UI tests and accessibility audits can find them
enum AccessibilityID {
    static let authEmail = "auth.email"
    static let authPassword = "auth.password"
    static let authSubmit = "auth.submit"
    static let checkLinkInput = "checkLink.input"
    static let checkLinkSubmit = "checkLink.submit"
    static let signOut = "settings.signOut"
}

extension View {

    //reads a new message out loud so people using VoiceOver do not miss an error that appears silently
    func announceWhenSet(_ message: String?) -> some View {
        onChange(of: message) { _, newValue in
            if let newValue, !newValue.isEmpty {
                AccessibilityNotification.Announcement(newValue).post()
            }
        }
    }
}
