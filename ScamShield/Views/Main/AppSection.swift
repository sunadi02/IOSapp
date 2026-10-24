//
//  AppSection.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import SwiftUI

//every place the user can be, shared by the iPhone tab bar and the iPad sidebar
enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case home
    case checkLink
    case scanQR
    case scanScreenshot
    case history
    case community
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .checkLink: "Check a Link"
        case .scanQR: "Scan QR Code"
        case .scanScreenshot: "Scan a Screenshot"
        case .history: "History"
        case .community: "Community"
        case .settings: "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house.fill"
        case .checkLink: "link"
        case .scanQR: "qrcode.viewfinder"
        case .scanScreenshot: "text.viewfinder"
        case .history: "clock.fill"
        case .community: "person.3.fill"
        case .settings: "gearshape.fill"
        }
    }

    //on a phone the three scan screens open from Home, so they share its tab
    var compactTab: AppSection {
        switch self {
        case .checkLink, .scanQR, .scanScreenshot: .home
        default: self
        }
    }
}

//lets the menu shortcuts reach the section the focused window is showing
struct AppSectionFocusKey: FocusedValueKey {
    typealias Value = Binding<AppSection>
}

extension FocusedValues {
    var appSection: Binding<AppSection>? {
        get { self[AppSectionFocusKey.self] }
        set { self[AppSectionFocusKey.self] = newValue }
    }
}
