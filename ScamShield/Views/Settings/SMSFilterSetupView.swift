//
//  SMSFilterSetupView.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import SwiftUI

struct SMSFilterSetupView: View {

    @State private var sampleText = ""
    @State private var sampleSender = ""

    private var sample: (action: SMSFilterDecision.Action, signals: [RiskSignal])? {
        let text = sampleText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        let sender = sampleSender.trimmingCharacters(in: .whitespaces)
        let senderOrNil = sender.isEmpty ? nil : sender
        return (
            SMSFilterDecision.action(for: text, sender: senderOrNil),
            SMSFilterDecision.signals(for: text, sender: senderOrNil)
        )
    }

    var body: some View {
        List {
            Section {
                Text("ScamShield can move suspicious texts from people who are not in your contacts to Junk, before you see them.")
            }

            Section("Turn it on") {
                Label("Open the Settings app", systemImage: "1.circle.fill")
                Label("Tap Messages, then Unknown & Spam", systemImage: "2.circle.fill")
                Label("Turn on Filter Unknown Senders", systemImage: "3.circle.fill")
                Label("Under SMS Filtering, choose ScamShield", systemImage: "4.circle.fill")

                if let url = URL(string: UIApplication.openSettingsURLString) {
                    Link("Open iOS Settings", destination: url)
                }
            }

            Section {
                Label("Texts are checked on your phone and are never sent to ScamShield or anyone else.", systemImage: "lock.shield.fill")
                Label("Only senders who are not in your contacts are checked.", systemImage: "person.crop.circle.badge.questionmark")
                Label("Nothing is deleted. Junk texts wait in Messages under Unknown & Spam.", systemImage: "tray.full.fill")
            } header: {
                Text("Your privacy")
            } footer: {
                Text("iOS filters plain text messages only. iMessages are not checked.")
            }

            Section {
                TextField("Paste a message to test", text: $sampleText, axis: .vertical)
                    .lineLimit(3...8)
                TextField("Sender (optional), for example +94771234567", text: $sampleSender)
                    .keyboardType(.numbersAndPunctuation)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                if let sample {
                    Label(
                        sample.action == .junk ? "Would be moved to Junk" : "Would be left alone",
                        systemImage: sample.action == .junk ? "trash.fill" : "checkmark.circle.fill"
                    )
                    .font(.headline)
                    .foregroundStyle(sample.action == .junk ? Color.red : Color.green)

                    ForEach(sample.signals) { signal in
                        SignalRow(signal: signal)
                    }
                }
            } header: {
                Text("Try it")
            } footer: {
                Text("This runs the same rules the filter uses. Nothing you type here leaves your phone.")
            }
        }
        .gradientList()
        .navigationTitle("SMS Scam Filter")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SMSFilterSetupView()
    }
}
