import SwiftUI

// MARK: - Design Tokens
enum DS {
    // Background layers
    static let bg0       = Color(hex: "#0A0A14")   // deepest background
    static let bg1       = Color(hex: "#111124")   // card/panel background
    static let bg2       = Color(hex: "#1A1A30")   // elevated surface
    static let bg3       = Color(hex: "#242440")   // highest surface

    // Accent
    static let accent    = Color(hex: "#7C3AED")
    static let accentLit = Color(hex: "#A855F7")
    static let accentGlow = Color(hex: "#7C3AED").opacity(0.35)

    // Text
    static let textPrimary   = Color.white
    static let textSecondary = Color(hex: "#A1A1CC")
    static let textMuted     = Color(hex: "#545480")

    // Status
    static let success = Color(hex: "#10B981")
    static let warning = Color(hex: "#F59E0B")
    static let danger  = Color(hex: "#EF4444")
    static let info    = Color(hex: "#3B82F6")

    // Graph
    static let edgeColor     = Color.white.opacity(0.15)
    static let nodeStroke    = Color.white.opacity(0.2)
    static let headGlow      = Color(hex: "#A855F7")
    static let nodeSize: CGFloat = 20
    static let laneWidth: CGFloat = 56
    static let rowHeight: CGFloat = 76

    // Radii
    static let radiusS: CGFloat = 8
    static let radiusM: CGFloat = 14
    static let radiusL: CGFloat = 20
    static let radiusXL: CGFloat = 28

    // Animations
    static let springSnappy  = Animation.spring(response: 0.35, dampingFraction: 0.72)
    static let springBouncy  = Animation.spring(response: 0.45, dampingFraction: 0.60)
    static let springSmooth  = Animation.spring(response: 0.6,  dampingFraction: 0.85)
    static let easeSmooth    = Animation.easeInOut(duration: 0.4)
}

// MARK: - Glass Card Modifier
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = DS.radiusM
    var opacity: Double = 0.55

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(DS.bg1.opacity(opacity))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = DS.radiusM, opacity: Double = 0.55) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius, opacity: opacity))
    }
}

// MARK: - Glow Modifier
struct GlowEffect: ViewModifier {
    var color: Color = DS.accent
    var radius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.6), radius: radius / 2)
            .shadow(color: color.opacity(0.3), radius: radius)
    }
}

extension View {
    func glowEffect(color: Color = DS.accent, radius: CGFloat = 12) -> some View {
        modifier(GlowEffect(color: color, radius: radius))
    }
}

// MARK: - Accent Button Style
struct AccentButtonStyle: ButtonStyle {
    var color: Color = DS.accent
    var isDestructive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: DS.radiusS, style: .continuous)
                    .fill(isDestructive ? DS.danger : color)
                    .opacity(configuration.isPressed ? 0.75 : 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(DS.springSnappy, value: configuration.isPressed)
    }
}

// MARK: - Ghost Button Style
struct GhostButtonStyle: ButtonStyle {
    var color: Color = DS.accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundColor(color)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: DS.radiusS, style: .continuous)
                    .strokeBorder(color.opacity(0.5), lineWidth: 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: DS.radiusS, style: .continuous)
                            .fill(color.opacity(configuration.isPressed ? 0.12 : 0.06))
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(DS.springSnappy, value: configuration.isPressed)
    }
}

// MARK: - Shimmer effect
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .white.opacity(0.15), location: 0.45),
                            .init(color: .white.opacity(0.3), location: 0.5),
                            .init(color: .white.opacity(0.15), location: 0.55),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .init(x: phase - 0.5, y: 0),
                        endPoint: .init(x: phase + 0.5, y: 0)
                    )
                    .blendMode(.plusLighter)
                }
            )
            .onAppear {
                withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
            .clipped()
    }
}

// MARK: - Tab Item
struct TabItemLabel: View {
    let icon: String
    let title: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: isSelected ? icon.replacingOccurrences(of: ".circle", with: ".circle.fill") : icon)
                .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? DS.accentLit : DS.textMuted)
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(DS.springSnappy, value: isSelected)
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(isSelected ? DS.accentLit : DS.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
