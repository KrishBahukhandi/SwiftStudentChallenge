import SwiftUI

// MARK: - About View
struct AboutView: View {
    let onDismiss: () -> Void

    @State private var glowPhase: CGFloat = 0

    var body: some View {
        ZStack {
            DS.bg0.ignoresSafeArea()

            // Ambient background glow
            RadialGradient(
                colors: [DS.accent.opacity(0.18), DS.bg0],
                center: .top,
                startRadius: 0,
                endRadius: 500
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {

                    // ── App identity ─────────────────────────────────────
                    VStack(spacing: 16) {
                        // Animated commit-graph logo
                        AboutGraphLogo()
                            .frame(width: 80, height: 80)
                            .accessibilityHidden(true)

                        VStack(spacing: 6) {
                            Text("Git, Visualised.")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.primary, DS.accentLit],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                            Text("Every developer uses Git without ever seeing it.\nThis changes that.")
                                .font(.system(size: 15, design: .rounded))
                                .foregroundColor(DS.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }

                        // SSC badge
                        HStack(spacing: 7) {
                            Image(systemName: "swift")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.orange)
                                .accessibilityHidden(true)
                            Text("Apple Swift Student Challenge 2025")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(Color.orange.opacity(0.12))
                                .overlay(Capsule().strokeBorder(Color.orange.opacity(0.3), lineWidth: 1))
                        )
                    }
                    .padding(.top, 8)

                    // ── What's inside ─────────────────────────────────────
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "What's inside", icon: "square.grid.2x2")

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            AboutFeatureCard(
                                icon: "book.circle.fill",
                                title: "Learn",
                                description: "6 interactive lessons on commits, branches, merge, rebase, reset & cherry-pick — each with a live Try it Live playground.",
                                color: DS.info
                            )
                            AboutFeatureCard(
                                icon: "play.circle.fill",
                                title: "Sandbox",
                                description: "Freeplay Git graph. Run any command, watch the graph evolve in real-time with animations and a live terminal log.",
                                color: DS.accent
                            )
                            AboutFeatureCard(
                                icon: "flowchart.fill",
                                title: "Flows",
                                description: "GitHub Flow, GitFlow, Trunk-Based & Feature Branch — animated diagrams with pros, cons and real-world usage.",
                                color: DS.success
                            )
                            AboutFeatureCard(
                                icon: "trophy.circle.fill",
                                title: "Challenges",
                                description: "9 progressive Git puzzles from First Commit to Rebase & Linearise. Hints available. Progress saved across sessions.",
                                color: DS.warning
                            )
                        }
                    }

                    // ── Why I built this ────────────────────────────────────
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Why I built this", icon: "lightbulb.fill")

                        VStack(alignment: .leading, spacing: 12) {
                            Text("""
                            When I first learned Git, I could run the commands — but I had no mental model of what was actually happening to the repository. I memorised `git merge` without understanding what a merge commit *is*.

                            Git Visualised solves that. Every command you type instantly transforms the graph you can see. You stop memorising and start *understanding*.
                            """)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(DS.textSecondary)
                            .lineSpacing(5)
                        }
                        .padding(16)
                        .glassCard(cornerRadius: DS.radiusL)
                    }

                    // ── Technical highlights ─────────────────────────────────
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Under the hood", icon: "cpu")

                        VStack(spacing: 8) {
                            TechRow(icon: "paintbrush",        text: "Canvas-based DAG renderer — edges drawn with cubic Bézier curves")
                            TechRow(icon: "arrow.triangle.branch", text: "Full Git engine: commit, branch, merge, rebase, reset, cherry-pick, tag")
                            TechRow(icon: "waveform.path",     text: "Haptic feedback on every Git operation — crash, warning, success")
                            TechRow(icon: "figure.wave",       text: "Full VoiceOver support — every node, branch, and control labelled")
                            TechRow(icon: "ipad.and.iphone",   text: "Adaptive layout — works on iPhone and iPad, portrait and landscape")
                        }
                        .padding(14)
                        .glassCard(cornerRadius: DS.radiusL)
                    }

                    // ── Creator ──────────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Created by", icon: "person.fill")

                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(DS.accent.opacity(0.2))
                                    .frame(width: 56, height: 56)
                                Text("K")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(DS.accentLit)
                            }
                            .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Krish Bahukhandi")
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                Text("iOS Developer · Swift enthusiast")
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundColor(DS.textMuted)
                            }
                            Spacer()
                        }
                        .padding(16)
                        .glassCard(cornerRadius: DS.radiusL)
                    }

                    // ── Version ──────────────────────────────────────────────
                    Text("Version 1.0 · Built with SwiftUI")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(DS.textMuted)
                        .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }

            // Close button (top-right)
            VStack {
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(DS.textSecondary)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(DS.bg2))
                    }
                    .accessibilityLabel("Close About")
                    .padding(.top, 16)
                    .padding(.trailing, 20)
                }
                Spacer()
            }
        }
    }
}

// MARK: - About Graph Logo (decorative mini-graph)
private struct AboutGraphLogo: View {
    @State private var pulse: CGFloat = 1.0

    var body: some View {
        Canvas { ctx, size in
            let cx = size.width / 2
            let nodeR: CGFloat = 8

            // Draw edges
            let edges: [(CGPoint, CGPoint)] = [
                (CGPoint(x: cx, y: size.height - 8), CGPoint(x: cx, y: size.height / 2)),
                (CGPoint(x: cx, y: size.height / 2), CGPoint(x: cx - 18, y: 12)),
                (CGPoint(x: cx, y: size.height / 2), CGPoint(x: cx + 18, y: 12)),
            ]
            for (a, b) in edges {
                var p = Path(); p.move(to: a); p.addLine(to: b)
                ctx.stroke(p, with: .color(.white.opacity(0.2)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }
            // Nodes
            let nodes: [(CGPoint, Color)] = [
                (CGPoint(x: cx, y: size.height - 8),  Color.branchColors[0]),
                (CGPoint(x: cx, y: size.height / 2),  Color.branchColors[0]),
                (CGPoint(x: cx - 18, y: 12),           Color.branchColors[0]),
                (CGPoint(x: cx + 18, y: 12),           Color.branchColors[1]),
            ]
            for (pt, color) in nodes {
                let r = CGRect(x: pt.x - nodeR, y: pt.y - nodeR, width: nodeR * 2, height: nodeR * 2)
                ctx.fill(Path(ellipseIn: r), with: .color(color))
                ctx.stroke(Path(ellipseIn: r), with: .color(.white.opacity(0.3)), lineWidth: 1.5)
            }
        }
        .scaleEffect(pulse)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                pulse = 1.06
            }
        }
    }
}

// MARK: - About Feature Card
private struct AboutFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(color)
                .accessibilityHidden(true)
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            Text(description)
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(DS.textMuted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .glassCard(cornerRadius: DS.radiusM)
        .overlay(
            RoundedRectangle(cornerRadius: DS.radiusM, style: .continuous)
                .strokeBorder(color.opacity(0.18), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(description)")
    }
}

// MARK: - Section Header
private struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(DS.accentLit)
                .accessibilityHidden(true)
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(DS.textMuted)
        }
    }
}

// MARK: - Tech Row
private struct TechRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(DS.accent.opacity(0.8))
                .frame(width: 18)
                .accessibilityHidden(true)
            Text(text)
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(DS.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }
}
