import SwiftUI

// MARK: - Tour Overlay
// A 5-step animated coach mark walkthrough shown the first time the user opens the Sandbox.
// Uses SwiftUI compositingGroup + destinationOut for a reliable spotlight cutout.

struct TourOverlay: View {
    @Binding var isVisible: Bool
    @State private var step = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var cardOffset: CGFloat = 60
    @State private var cardOpacity: Double = 0

    private let steps: [TourStep] = [
        TourStep(
            title: "Welcome to Git Visualised! 🎉",
            body: "This is your live Git commit graph. Every command you run instantly updates it — commits become nodes, branches become labels, and history becomes visible.",
            icon: "circle.hexagongrid.fill",
            spotFraction: CGPoint(x: 0.5, y: 0.42),
            spotRadius: 90
        ),
        TourStep(
            title: "Run Git Commands",
            body: "The command panel shows Commit, Branch, Merge, Rebase, Stash and more. Tap any tab to switch. Your changes appear in the graph instantly.",
            icon: "terminal.fill",
            spotFraction: CGPoint(x: 0.5, y: 0.82),
            spotRadius: 90
        ),
        TourStep(
            title: "Track Every Operation",
            body: "Tap the 🕐 clock button at the top right to open the Terminal Log — a live history of every git command you've run, newest first.",
            icon: "clock.arrow.2.circlepath",
            spotFraction: CGPoint(x: 0.76, y: 0.09),
            spotRadius: 34
        ),
        TourStep(
            title: "Tap Any Commit",
            body: "Tap any commit node in the graph to inspect it — see the hash, parent, branches and tags, and perform actions like cherry-pick or reset.",
            icon: "circle.fill",
            spotFraction: CGPoint(x: 0.15, y: 0.40),
            spotRadius: 38
        ),
        TourStep(
            title: "Explore All 4 Sections",
            body: "Use the tab bar: Learn interactive lessons, use Sandbox freely, study Git Flows strategies, and tackle Challenges to test your knowledge.",
            icon: "square.grid.2x2.fill",
            spotFraction: CGPoint(x: 0.5, y: 0.96),
            spotRadius: 80
        ),
    ]

    private var current: TourStep { steps[min(step, steps.count - 1)] }
    private var isLast: Bool { step == steps.count - 1 }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // ── Spotlight overlay ─────────────────────────────
                SpotlightView(
                    spotCenter: CGPoint(
                        x: current.spotFraction.x * geo.size.width,
                        y: current.spotFraction.y * geo.size.height
                    ),
                    spotRadius: current.spotRadius
                )
                .ignoresSafeArea()
                .animation(DS.springSmooth, value: step)
                .onTapGesture { advance() }

                // ── Pulsing ring ──────────────────────────────────
                Circle()
                    .strokeBorder(DS.accentLit.opacity(0.65), lineWidth: 2)
                    .frame(
                        width:  current.spotRadius * 2 * pulseScale,
                        height: current.spotRadius * 2 * pulseScale
                    )
                    .position(
                        x: current.spotFraction.x * geo.size.width,
                        y: current.spotFraction.y * geo.size.height
                    )
                    .opacity(2.2 - Double(pulseScale) * 1.2)
                    .allowsHitTesting(false)
                    .animation(DS.springSmooth, value: step)

                // ── Coach mark card ───────────────────────────────
                VStack(spacing: 0) {
                    Spacer()
                    TourCard(
                        step: current,
                        stepIndex: step,
                        totalSteps: steps.count,
                        isLast: isLast,
                        onNext: advance,
                        onSkip: dismiss
                    )
                    .offset(y: cardOffset)
                    .opacity(cardOpacity)
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .onAppear { animateIn() }
        .onChange(of: step) { _ in animateStepChange() }
    }

    private func animateIn() {
        withAnimation(DS.springBouncy.delay(0.2)) {
            cardOffset = 0; cardOpacity = 1
        }
        startPulse()
    }

    private func animateStepChange() {
        withAnimation(.easeIn(duration: 0.12)) {
            cardOffset = 24; cardOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(DS.springBouncy) {
                cardOffset = 0; cardOpacity = 1
            }
        }
        pulseScale = 1.0
        startPulse()
    }

    private func startPulse() {
        withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
            pulseScale = 1.28
        }
    }

    private func advance() {
        if isLast { dismiss() } else {
            withAnimation(DS.springSnappy) { step += 1 }
        }
    }

    private func dismiss() {
        withAnimation(DS.springSmooth) { isVisible = false }
    }
}

// MARK: - Spotlight View (reliable compositingGroup approach)
private struct SpotlightView: View {
    let spotCenter: CGPoint
    let spotRadius: CGFloat

    var body: some View {
        // The mask determines opacity of the black overlay.
        // Within the compositingGroup:
        //   - Rectangle fills entire area WHITE (= mask is opaque everywhere)
        //   - Circle with .destinationOut removes pixels (= mask is transparent in the hole)
        // Effect: black overlay has a circular see-through hole.
        Color.black.opacity(0.72)
            .mask {
                ZStack {
                    Rectangle()  // fully white = overlay is opaque
                    Circle()
                        .frame(width: spotRadius * 2, height: spotRadius * 2)
                        .position(spotCenter)
                        .blendMode(.destinationOut)  // punch transparent hole
                }
                .compositingGroup()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
    }
}

// MARK: - Tour Card
private struct TourCard: View {
    let step: TourStep
    let stepIndex: Int
    let totalSteps: Int
    let isLast: Bool
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Progress dots + Skip
            HStack(spacing: 6) {
                ForEach(0..<totalSteps, id: \.self) { i in
                    Capsule()
                        .fill(i == stepIndex ? DS.accentLit : DS.bg3)
                        .frame(width: i == stepIndex ? 20 : 6, height: 6)
                        .animation(DS.springSnappy, value: stepIndex)
                }
                Spacer()
                Button("Skip", action: onSkip)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(DS.textMuted)
                    .accessibilityLabel("Skip tour")
            }

            // Icon + title
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(DS.accent.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: step.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(DS.accentLit)
                }
                .accessibilityHidden(true)
                Text(step.title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Body
            Text(step.body)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(DS.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            // CTA
            Button(action: onNext) {
                Text(isLast ? "Let's Go! 🚀" : "Next  →")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(AccentButtonStyle(color: DS.accent))
            .accessibilityLabel(isLast ? "Finish tour" : "Next step")
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: DS.radiusXL, style: .continuous)
                .fill(Color(hex: "#111124"))
                .shadow(color: .black.opacity(0.55), radius: 32, y: -10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.radiusXL, style: .continuous)
                .strokeBorder(DS.accent.opacity(0.28), lineWidth: 1)
        )
        .padding(.horizontal, 14)
        .padding(.bottom, 28)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Tour Step Data
struct TourStep {
    let title: String
    let body: String
    let icon: String
    let spotFraction: CGPoint   // 0–1 fractions of screen width/height
    let spotRadius: CGFloat
}
