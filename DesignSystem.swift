import SwiftUI
import UIKit

// MARK: - Design Tokens
enum DS {
    // ── Background layers (dark / light adaptive) ──────────────
    static var bg0: Color {
        Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(Color(hex: "#0A0A14"))
                : UIColor(Color(hex: "#F2F0FF"))
        })
    }
    static var bg1: Color {
        Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(Color(hex: "#111124"))
                : UIColor(Color(hex: "#FFFFFF"))
        })
    }
    static var bg2: Color {
        Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(Color(hex: "#1A1A30"))
                : UIColor(Color(hex: "#E8E6FA"))
        })
    }
    static var bg3: Color {
        Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(Color(hex: "#242440"))
                : UIColor(Color(hex: "#DDDAF5"))
        })
    }

    // ── Accent (same in both modes — vivid purple reads on both) ─
    static let accent     = Color(hex: "#7C3AED")
    static let accentLit  = Color(hex: "#A855F7")
    static let accentGlow = Color(hex: "#7C3AED").opacity(0.35)

    // ── Text (adaptive) ─────────────────────────────────────────
    /// Primary text — auto-adapts: white in dark, near-black in light
    static var textPrimary: Color { Color.primary }
    static var textSecondary: Color {
        Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(Color(hex: "#A1A1CC"))
                : UIColor(Color(hex: "#3D3B6B"))
        })
    }
    static var textMuted: Color {
        Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(Color(hex: "#545480"))
                : UIColor(Color(hex: "#7070A0"))
        })
    }

    // ── Status (vivid — work on both backgrounds) ───────────────
    static let success = Color(hex: "#10B981")
    static let warning = Color(hex: "#F59E0B")
    static let danger  = Color(hex: "#EF4444")
    static let info    = Color(hex: "#3B82F6")

    // ── Graph ────────────────────────────────────────────────────
    static var edgeColor: Color {
        Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(white: 1, alpha: 0.15)
                : UIColor(white: 0, alpha: 0.12)
        })
    }
    static var nodeStroke: Color {
        Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(white: 1, alpha: 0.20)
                : UIColor(white: 0, alpha: 0.15)
        })
    }
    static let headGlow   = Color(hex: "#A855F7")
    static let nodeSize: CGFloat  = 20
    static let laneWidth: CGFloat = 56
    static let rowHeight: CGFloat = 76

    // ── Radii ────────────────────────────────────────────────────
    static let radiusS: CGFloat  = 8
    static let radiusM: CGFloat  = 14
    static let radiusL: CGFloat  = 20
    static let radiusXL: CGFloat = 28

    // ── Animations ───────────────────────────────────────────────
    static let springSnappy = Animation.spring(response: 0.35, dampingFraction: 0.72)
    static let springBouncy = Animation.spring(response: 0.45, dampingFraction: 0.60)
    static let springSmooth = Animation.spring(response: 0.6,  dampingFraction: 0.85)
    static let easeSmooth   = Animation.easeInOut(duration: 0.4)
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
    var namespace: Namespace.ID? = nil

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .bottom) {
                Image(systemName: isSelected ? icon.replacingOccurrences(of: ".circle", with: ".circle.fill") : icon)
                    .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? DS.accentLit : DS.textMuted)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(DS.springSnappy, value: isSelected)
                    .shadow(color: isSelected ? DS.accentLit.opacity(0.5) : .clear, radius: 6)
            }
            Text(title)
                .font(.system(size: 10, weight: isSelected ? .semibold : .medium, design: .rounded))
                .foregroundColor(isSelected ? DS.accentLit : DS.textMuted)

            // Active indicator pill
            Capsule()
                .fill(isSelected ? DS.accentLit : Color.clear)
                .frame(width: isSelected ? 24 : 0, height: 3)
                .shadow(color: isSelected ? DS.accentLit.opacity(0.7) : .clear, radius: 4)
                .animation(DS.springSnappy, value: isSelected)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }
}
