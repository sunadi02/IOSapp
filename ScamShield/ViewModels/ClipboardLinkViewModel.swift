//
//  ClipboardLinkViewModel.swift
//  ScamShield
//
//  Created by student2 on 2026-10-25.
//

import Foundation
import Observation
import UIKit

//protocol so the copied link card can be tested without the real clipboard
protocol PasteboardInspecting {
    var changeCount: Int { get }
    func hasProbableWebLink() async -> Bool
}

//asks what kind of thing was copied without reading it, so iOS does not show its paste prompt
struct SystemPasteboard: PasteboardInspecting {

    var changeCount: Int {
        UIPasteboard.general.changeCount
    }

    func hasProbableWebLink() async -> Bool {
        guard UIPasteboard.general.hasStrings || UIPasteboard.general.hasURLs else { return false }

        return await withCheckedContinuation { continuation in
            UIPasteboard.general.detectPatterns(for: [.probableWebURL]) { result in
                let found = (try? result.get())?.contains(.probableWebURL) ?? false
                continuation.resume(returning: found)
            }
        }
    }
}

//offers to check a link the user has just copied, for example from a text message
@Observable
final class ClipboardLinkViewModel {

    private(set) var showsCard = false

    private let pasteboard: PasteboardInspecting
    private let defaults: UserDefaults

    init(pasteboard: PasteboardInspecting = SystemPasteboard(), defaults: UserDefaults = .standard) {
        self.pasteboard = pasteboard
        self.defaults = defaults
    }

    //the clipboard as it was when the user checked or dismissed it, so the same link is not offered twice
    private var handledChangeCount: Int? {
        defaults.object(forKey: AppSettings.handledClipboardChange) as? Int
    }

    func refresh() async {
        guard pasteboard.changeCount != handledChangeCount else {
            showsCard = false
            return
        }

        let hasLink = await pasteboard.hasProbableWebLink()
        //the user may have dismissed the card while the clipboard was being looked at
        showsCard = hasLink && pasteboard.changeCount != handledChangeCount
    }

    func markHandled() {
        defaults.set(pasteboard.changeCount, forKey: AppSettings.handledClipboardChange)
        showsCard = false
    }
}
