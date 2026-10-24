//
//  SidebarMainView.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import SwiftUI

//the regular width layout used on iPad: a sidebar with every section and the chosen one beside it
struct SidebarMainView: View {

    @Binding var selection: AppSection

    private var sidebarSelection: Binding<AppSection?> {
        Binding(get: { selection }, set: { newValue in
            if let newValue { selection = newValue }
        })
    }

    var body: some View {
        NavigationSplitView {
            List(selection: sidebarSelection) {
                Section {
                    row(.home)
                    row(.checkLink)
                    row(.scanQR)
                    row(.scanScreenshot)
                }

                Section("Library") {
                    row(.history)
                    row(.community)
                }

                Section {
                    row(.settings)
                }
            }
            .navigationTitle("ScamShield")
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } detail: {
            //a fresh stack for every section so nothing pushed in one section follows you to the next
            NavigationStack {
                detail
            }
            .id(selection)
        }
        .handlesQuickActions(selection: $selection)
    }

    private func row(_ section: AppSection) -> some View {
        Label(section.title, systemImage: section.systemImage)
            .tag(section)
    }

    @ViewBuilder
    private var detail: some View {
        switch selection {
        case .home: DashboardView()
        case .checkLink: CheckLinkView()
        case .scanQR: QRScannerView()
        case .scanScreenshot: ScreenshotScanView()
        case .history: HistoryView()
        case .community: CommunityView()
        case .settings: SettingsView()
        }
    }
}

#Preview {
    SidebarMainView(selection: .constant(.home))
        .environment(AuthViewModel(service: PreviewAuthService()))
        .environment(AppLockViewModel())
        .environment(AppServices())
}
