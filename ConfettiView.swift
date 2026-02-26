import SwiftUI

// MARK: - Confetti View
// Deterministic particle burst — no randomness, so view recreations are stable.
struct ConfettiView: View {
    @State private var animate = false
    private let count = 48

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<count, id: \.self) { i in
                    ConfettiBit(index: i, parentSize: geo.size, animate: animate)
                }
            }
        }
        .allowsHitTesting(false)
        .task {
            try? await Task.sleep(for: .milliseconds(180))
            withAnimation { animate = true }
        }
    }
}

// MARK: - Single Confetti Piece
private struct ConfettiBit: View {
    let index: Int
    let parentSize: CGSize
    let animate: Bool

    // All values are deterministic from index — no UUID, no random
    private var angle: Double {
        // golden-angle distribution for even spread
        Double(index) * 137.508 * (.pi / 180.0)
    }
    private var distance: CGFloat {
        // tier spread: 80 / 110 / 145 / 180 / 210
        let tiers: [CGFloat] = [80, 110, 145, 180, 210]
        return tiers[index % tiers.count] + CGFloat((index * 7) % 20)
    }
    private var duration: Double { 0.75 + Double(index % 5) * 0.11 }
    private var delay: Double    { Double(index % 9) * 0.022 }
    private var isRect: Bool     { index % 3 != 0 }
    private var pieceW: CGFloat  { isRect ? 6  : 9 }
    private var pieceH: CGFloat  { isRect ? 11 : 9 }
    private var spinDeg: Double  { Double((index * 23) % 360) }
    private var gravityExtra: CGFloat { CGFloat((index * 11) % 30) }

    private var color: Color {
        let palette: [Color] = [
            Color(hex: "#7C3AED"), Color(hex: "#A855F7"),
            Color(hex: "#10B981"), Color(hex: "#F59E0B"),
            Color(hex: "#3B82F6"), Color(hex: "#EC4899"),
            Color(hex: "#06B6D4"), Color(hex: "#EF4444"),
        ]
        return palette[index % palette.count]
    }

    // Origin — slightly above center so burst feels upward-biased
    private var ox: CGFloat { parentSize.width  / 2 }
    private var oy: CGFloat { parentSize.height * 0.42 }

    var body: some View {
        RoundedRectangle(cornerRadius: isRect ? 2 : 4.5)
            .fill(color)
            .frame(width: pieceW, height: pieceH)
            .rotationEffect(.degrees(animate ? spinDeg : 0))
            .position(
                x: animate ? ox + cos(angle) * distance       : ox,
                y: animate ? oy + sin(angle) * distance + gravityExtra : oy
            )
            .opacity(animate ? 0 : 0.95)
            .animation(.easeOut(duration: duration).delay(delay), value: animate)
    }
}
