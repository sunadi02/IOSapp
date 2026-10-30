import SwiftUI

extension Color {
    static let brandNavy = Color(red: 0.07, green: 0.12, blue: 0.40)
    static let brandBlue = Color(red: 0.16, green: 0.36, blue: 0.62)
    static let brandTeal = Color(red: 0.24, green: 0.55, blue: 0.68)
    static let brandCyan = Color(red: 0.36, green: 0.88, blue: 0.90)
    static let brandErrorText = Color(red: 1.0, green: 0.6, blue: 0.6)
    static let brandSuccessText = Color(red: 0.6, green: 0.95, blue: 0.75)
}

extension LinearGradient {
    static let brand = LinearGradient(
        colors: [.brandNavy, .brandBlue, .brandTeal],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct BrandBackground: View {
    var body: some View {
        ZStack {
            LinearGradient.brand
            Circle()
                .fill(Color.brandCyan.opacity(0.22))
                .frame(width: 320, height: 320)
                .blur(radius: 70)
                .offset(x: -150, y: 280)
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 280, height: 280)
                .blur(radius: 30)
                .offset(x: 170, y: -260)
        }
        .ignoresSafeArea()
    }
}

struct BrandEmblem: View {
    let systemImage: String
    var size: CGFloat = 120

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.07))
                .frame(width: size * 1.45, height: size * 1.45)
            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: size * 1.2, height: size * 1.2)
            Circle()
                .fill(LinearGradient(colors: [.brandNavy, .brandBlue], startPoint: .top, endPoint: .bottom))
                .frame(width: size, height: size)
                .overlay(Circle().stroke(Color.brandCyan.opacity(0.7), lineWidth: 2))
                .shadow(color: .brandCyan.opacity(0.5), radius: 22)
            Image(systemName: systemImage)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(Color.brandCyan)
        }
        .accessibilityHidden(true)
    }
}

struct BrandAccentBar: View {
    var body: some View {
        Capsule()
            .fill(Color.brandCyan)
            .frame(width: 44, height: 4)
            .accessibilityHidden(true)
    }
}

struct BrandIconTile: View {
    let systemImage: String
    let size: CGFloat

    var body: some View {
        Image(systemName: systemImage)
            .font(.title2)
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(LinearGradient.brand, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .accessibilityHidden(true)
    }
}

struct BrandPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.brandNavy)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.brandCyan.opacity(isEnabled ? 1 : 0.5), in: Capsule())
            .shadow(color: .brandCyan.opacity(0.35), radius: 12, y: 4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == BrandPrimaryButtonStyle {
    static var brandPrimary: BrandPrimaryButtonStyle { BrandPrimaryButtonStyle() }
}

struct AppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    private var colors: [Color] {
        colorScheme == .dark
            ? [Color(red: 0.05, green: 0.09, blue: 0.30), Color(red: 0.03, green: 0.05, blue: 0.14)]
            : [Color(red: 0.78, green: 0.88, blue: 0.99), Color(red: 0.95, green: 0.97, blue: 1.0)]
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
            Circle()
                .fill((colorScheme == .dark ? Color.brandTeal : Color.brandCyan).opacity(colorScheme == .dark ? 0.28 : 0.30))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: 150, y: -240)
        }
        .ignoresSafeArea()
    }
}

struct CardBackground: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                colorScheme == .dark ? Color.white.opacity(0.09) : Color.white,
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.12 : 0), lineWidth: 1)
            )
            .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.07), radius: 8, y: 3)
    }
}

extension View {
    func cardBackground() -> some View {
        modifier(CardBackground())
    }

    func appBackground() -> some View {
        background { AppBackground() }
    }

    func gradientList() -> some View {
        scrollContentBackground(.hidden).background { AppBackground() }
    }

    func brandField() -> some View {
        padding(14)
            .foregroundStyle(.white)
            .tint(Color.brandCyan)
            .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.22), lineWidth: 1))
    }
}
