//
//  OnboardingView.swift
//  ScamShield
//
//  Created by student2 on 2026-10-23.
//

import SwiftUI

struct OnboardingPage: Identifiable {
    let id: Int
    let systemImage: String
    let title: String
    let message: String
}

struct OnboardingView: View {

    var onFinish: () -> Void

    @State private var currentPage = 0
    @ScaledMetric(relativeTo: .largeTitle) private var iconSize = 80

    static let pages = [
        OnboardingPage(id: 0, systemImage: "link.badge.plus", title: "Check any link",
                       message: "Paste a link from a message or email and see if it is safe before you open it."),
        OnboardingPage(id: 1, systemImage: "qrcode.viewfinder", title: "Scan QR codes safely",
                       message: "Find out where a QR code really goes before your phone opens it."),
        OnboardingPage(id: 2, systemImage: "text.viewfinder", title: "Spot scam messages",
                       message: "Scan a screenshot of a message and ScamShield explains what looks suspicious."),
        OnboardingPage(id: 3, systemImage: "lock.shield", title: "Private by design",
                       message: "Messages and screenshots are analysed on your device and never sent to an AI service.")
    ]

    private var isLastPage: Bool { currentPage == Self.pages.count - 1 }

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Spacer()
                Button("Skip", action: onFinish)
                    .opacity(isLastPage ? 0 : 1)
                    .disabled(isLastPage)
                    .accessibilityHidden(isLastPage)
            }
            .padding(.horizontal)

            TabView(selection: $currentPage) {
                ForEach(Self.pages) { page in
                    pageView(page).tag(page.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button {
                if isLastPage {
                    onFinish()
                } else {
                    withAnimation { currentPage += 1 }
                }
            } label: {
                Text(isLastPage ? "Get Started" : "Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(maxWidth: 600)
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: page.systemImage)
                .font(.system(size: iconSize))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            Text(page.title)
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Text(page.message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
