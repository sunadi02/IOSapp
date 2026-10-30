import SwiftUI

struct ScanRingButton: View {
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var scaledSize = 200

    private var size: CGFloat { min(scaledSize, 280) }
    private var lineWidth: CGFloat { size * 0.08 }

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(colors: [.brandBlue, .brandTeal], startPoint: .top, endPoint: .bottom),
                        lineWidth: lineWidth
                    )
                TimelineView(.animation(paused: reduceMotion)) { context in
                    let turns = context.date.timeIntervalSinceReferenceDate / 3
                    Circle()
                        .trim(from: 0, to: 0.3)
                        .stroke(
                            AngularGradient(
                                colors: [Color.brandCyan.opacity(0), .brandCyan, .white],
                                center: .center,
                                startAngle: .degrees(0),
                                endAngle: .degrees(108)
                            ),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )
                        .rotationEffect(.degrees(reduceMotion ? -90 : turns.truncatingRemainder(dividingBy: 1) * 360))
                        .shadow(color: .brandCyan.opacity(0.8), radius: lineWidth * 0.6)
                }
                Circle()
                    .fill(LinearGradient.brand)
                    .padding(lineWidth * 1.5)
                    .shadow(color: .brandCyan.opacity(0.35), radius: 16, y: 6)
                Text("Scan")
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(lineWidth * 2.5)
            }
            .frame(width: size, height: size)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .floating(distance: 3, duration: 3)
        .accessibilityLabel("Scan")
        .accessibilityHint("Shows ways to check a link, QR code or screenshot")
    }
}

struct ScanMenuSheet: View {
    let onSelect: (AppSection) -> Void

    private let options: [AppSection] = [.checkLink, .scanQR, .scanScreenshot]

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                BrandAccentBar()
                Text("What do you want to check?")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
            }

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 16) { buttons }
                VStack(spacing: 16) { buttons }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var buttons: some View {
        ForEach(options) { section in
            ScanOptionButton(section: section) { onSelect(section) }
        }
    }
}

struct ScanOptionButton: View {
    let section: AppSection
    let action: () -> Void

    @ScaledMetric(relativeTo: .title2) private var size = 64

    private var shortTitle: String {
        switch section {
        case .checkLink: "Link"
        case .scanQR: "QR Code"
        case .scanScreenshot: "Screenshot"
        default: section.title
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: section.systemImage)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: size, height: size)
                    .background(LinearGradient.brand, in: Circle())
                    .overlay(Circle().stroke(Color.brandCyan.opacity(0.6), lineWidth: 1.5))
                Text(shortTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(section.title)
    }
}
