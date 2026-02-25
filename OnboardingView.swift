import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool

    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var subtitleOpacity: Double = 0
    @State private var graphOpacity: Double = 0
    @State private var graphScale: CGFloat = 0.85
    @State private var buttonsOpacity: Double = 0
    @State private var buttonsOffset: CGFloat = 24
    @State private var drawProgress: CGFloat = 0

    var body: some View {
        ZStack {
            // Background
            DS.bg0
                .ignoresSafeArea()

            // Radial glow
            RadialGradient(
                colors: [DS.accent.opacity(0.25), DS.bg0],
                center: .center,
                startRadius: 0,
                endRadius: 420
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Title
                VStack(spacing: 10) {
                    Text("Git, Visualised.")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, DS.accentLit],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(titleOpacity)
                        .offset(y: titleOffset)

                    Text("Learn how Git works through\nbeautiful, animated commit graphs.")
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .foregroundColor(DS.textSecondary)
                        .multilineTextAlignment(.center)
                        .opacity(subtitleOpacity)
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 48)

                // Animated mini-graph
                OnboardingGraphAnimation(drawProgress: $drawProgress)
                    .frame(width: 280, height: 220)
                    .opacity(graphOpacity)
                    .scaleEffect(graphScale)

                Spacer()

                // Feature pills
                HStack(spacing: 12) {
                    FeaturePill(icon: "book.fill", text: "Learn", color: DS.info)
                    FeaturePill(icon: "circle.hexagongrid.fill", text: "Visualise", color: DS.accent)
                    FeaturePill(icon: "play.circle.fill", text: "Sandbox", color: DS.success)
                }
                .opacity(buttonsOpacity)
                .offset(y: buttonsOffset)

                Spacer().frame(height: 36)

                // CTA Buttons
                VStack(spacing: 12) {
                    Button("Start Learning") {
                        withAnimation(DS.springBouncy) {
                            hasSeenOnboarding = true
                        }
                    }
                    .buttonStyle(AccentButtonStyle())
                    .frame(maxWidth: 280)
                    .padding(.vertical, 4)
                    .accessibilityLabel("Start Learning")
                    .accessibilityHint("Opens the guided Git lessons")

                    Button("Go to Sandbox") {
                        withAnimation(DS.springBouncy) {
                            hasSeenOnboarding = true
                        }
                    }
                    .buttonStyle(GhostButtonStyle())
                    .frame(maxWidth: 280)
                    .accessibilityLabel("Go to Sandbox")
                    .accessibilityHint("Opens freeplay mode to experiment with Git commands")
                }
                .opacity(buttonsOpacity)
                .offset(y: buttonsOffset)

                Spacer().frame(height: 48)
            }
        }
        .onAppear {
            animate()
        }
    }

    func animate() {
        withAnimation(.easeOut(duration: 0.7)) {
            titleOpacity = 1; titleOffset = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.6)) {
                subtitleOpacity = 1
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(DS.springBouncy) {
                graphOpacity = 1; graphScale = 1
            }
            withAnimation(.linear(duration: 1.4).delay(0.3)) {
                drawProgress = 1
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(DS.springSnappy) {
                buttonsOpacity = 1; buttonsOffset = 0
            }
        }
    }
}

// MARK: - Mini Graph Animation (decorative - hidden from VoiceOver)
struct OnboardingGraphAnimation: View {
    @Binding var drawProgress: CGFloat

    let nodes: [(CGPoint, Color, String)] = [
        (CGPoint(x: 60, y: 190), Color.branchColors[0], "init"),
        (CGPoint(x: 60, y: 130), Color.branchColors[0], "feat"),
        (CGPoint(x: 60, y: 70),  Color.branchColors[0], "fix"),
        (CGPoint(x: 130, y: 130), Color.branchColors[1], "dev"),
        (CGPoint(x: 130, y: 70),  Color.branchColors[1], "api"),
        (CGPoint(x: 60, y: 14),   Color.branchColors[0], "merge"),
    ]

    let edges: [(Int, Int)] = [(0,1),(1,2),(1,3),(3,4),(2,5),(4,5)]

    var body: some View {
        Canvas { ctx, size in
            drawGraph(ctx: ctx, size: size)
        }
        .accessibilityHidden(true)
    }

    func drawGraph(ctx: GraphicsContext, size: CGSize) {
        // Draw edges
        for (i, edge) in edges.enumerated() {
            let fraction = min(1, max(0, drawProgress * 2 - CGFloat(i) * 0.25))
            guard fraction > 0 else { continue }
            let from = nodes[edge.0].0
            let to   = nodes[edge.1].0
            var path = Path()
            path.move(to: from)
            let mid = CGPoint(x: (from.x + to.x) / 2, y: (from.y + to.y) / 2)
            path.addCurve(to: to,
                          control1: CGPoint(x: from.x, y: mid.y),
                          control2: CGPoint(x: to.x,   y: mid.y))
            ctx.stroke(path.trimmedPath(from: 0, to: fraction),
                       with: .color(.white.opacity(0.22)),
                       style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        // Draw nodes
        for (i, node) in nodes.enumerated() {
            let fraction = min(1, max(0, drawProgress * 2 - CGFloat(i) * 0.3))
            guard fraction > 0 else { continue }
            let r: CGFloat = 14 * fraction
            let rect = CGRect(x: node.0.x - r, y: node.0.y - r, width: r*2, height: r*2)
            ctx.fill(Path(ellipseIn: rect), with: .color(node.1))
            ctx.stroke(Path(ellipseIn: rect), with: .color(.white.opacity(0.3)), lineWidth: 1.5)
        }
    }
}

// MARK: - Feature Pill
struct FeaturePill: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(DS.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .glassCard(cornerRadius: DS.radiusL)
    }
}
