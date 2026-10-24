//
//  ClipboardLinkViewModelTests.swift
//  ScamShieldTests
//
//  Created by student2 on 2026-10-25.
//

import Testing
import Foundation
@testable import ScamShield

//a clipboard whose contents a test decides, and which counts how often it was looked at
@MainActor
final class MockPasteboard: PasteboardInspecting {
    var changeCount = 1
    var hasLink = true
    private(set) var inspections = 0

    func hasProbableWebLink() async -> Bool {
        inspections += 1
        return hasLink
    }
}

@MainActor
struct ClipboardLinkViewModelTests {

    let pasteboard = MockPasteboard()
    let defaults = UserDefaults(suiteName: "ClipboardLinkViewModelTests-\(UUID().uuidString)")!

    private func makeViewModel() -> ClipboardLinkViewModel {
        ClipboardLinkViewModel(pasteboard: pasteboard, defaults: defaults)
    }

    @Test func cardIsHiddenUntilTheClipboardIsLookedAt() {
        #expect(!makeViewModel().showsCard)
    }

    @Test func copiedLinkShowsTheCard() async {
        let viewModel = makeViewModel()
        await viewModel.refresh()
        #expect(viewModel.showsCard)
    }

    @Test func copiedTextThatIsNotALinkShowsNothing() async {
        pasteboard.hasLink = false
        let viewModel = makeViewModel()

        await viewModel.refresh()
        #expect(!viewModel.showsCard)
    }

    @Test func handlingTheLinkHidesTheCard() async {
        let viewModel = makeViewModel()
        await viewModel.refresh()

        viewModel.markHandled()
        #expect(!viewModel.showsCard)
    }

    @Test func aHandledLinkIsNotOfferedAgainOrEvenLookedAt() async {
        let viewModel = makeViewModel()
        await viewModel.refresh()
        viewModel.markHandled()

        await viewModel.refresh()
        #expect(!viewModel.showsCard)
        #expect(pasteboard.inspections == 1)
    }

    @Test func somethingNewlyCopiedIsOfferedAgain() async {
        let viewModel = makeViewModel()
        await viewModel.refresh()
        viewModel.markHandled()

        pasteboard.changeCount += 1
        await viewModel.refresh()
        #expect(viewModel.showsCard)
    }

    @Test func aHandledLinkStaysHandledOnTheNextVisit() async {
        let first = makeViewModel()
        await first.refresh()
        first.markHandled()

        let next = makeViewModel()
        await next.refresh()
        #expect(!next.showsCard)
    }

    @Test func clearingTheClipboardHidesAnEarlierCard() async {
        let viewModel = makeViewModel()
        await viewModel.refresh()

        pasteboard.changeCount += 1
        pasteboard.hasLink = false
        await viewModel.refresh()
        #expect(!viewModel.showsCard)
    }
}
