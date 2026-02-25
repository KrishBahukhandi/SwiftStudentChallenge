import SwiftUI

// MARK: - Git Flows View
// Shows famous real-world Git branching strategies as animated interactive diagrams.
// Each flow has a Canvas-drawn animated graph + description cards.
struct GitFlowsView: View {
    @State private var selectedFlow = 0

    let flows: [GitFlow] = GitFlow.all

    var body: some View {
        ZStack {
            DS.bg0.ignoresSafeArea()
            VStack(spacing: 0) {
                // ── Header ──────────────────────────────────────
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Git Flows")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Real-world branching strategies")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(DS.textMuted)
                    }
                    Spacer()
                    Image(systemName: "flowchart.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [DS.accent, DS.accentLit],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 14)

                // ── Flow Selector Pills ─────────────────────────
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(flows.enumerated()), id: \.offset) { i, flow in
                            Button {
                                withAnimation(DS.springSnappy) { selectedFlow = i }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: flow.icon)
                                        .font(.system(size: 12, weight: .semibold))
                                    Text(flow.name)
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(selectedFlow == i ? .white : DS.textSecondary)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(selectedFlow == i ? flow.accentColor : DS.bg2)
                                )
                            }
                            .accessibilityLabel(flow.name)
                            .accessibilityAddTraits(selectedFlow == i ? [.isButton, .isSelected] : .isButton)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)
                }

                Divider().background(DS.textMuted.opacity(0.12))

                // ── Flow Detail ─────────────────────────────────
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        GitFlowDetailView(flow: flows[selectedFlow])
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
        }
    }
}

// MARK: - Flow Detail
struct GitFlowDetailView: View {
    let flow: GitFlow
    @State private var animPhase: CGFloat = 0
    @State private var highlightedStep: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Description
            Text(flow.description)
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(DS.textSecondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            // Animated diagram
            FlowDiagramCanvas(flow: flow, animPhase: animPhase, highlighted: highlightedStep)
                .frame(height: 200)
                .glassCard(cornerRadius: DS.radiusL)
                .clipped()
                .accessibilityLabel("\(flow.name) diagram")
                .accessibilityHint("Visual representation of the \(flow.name) branching strategy")
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        animPhase = 1
                    }
                }

            // Used by section
            HStack(spacing: 8) {
                Image(systemName: "building.2")
                    .font(.system(size: 11))
                    .foregroundColor(flow.accentColor)
                    .accessibilityHidden(true)
                Text("Used by: \(flow.usedBy)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(DS.textMuted)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: DS.radiusS).fill(flow.accentColor.opacity(0.08)))

            // Step-by-step cards
            VStack(alignment: .leading, spacing: 4) {
                Text("How it works")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(DS.textMuted)
                    .padding(.bottom, 4)

                ForEach(Array(flow.steps.enumerated()), id: \.offset) { i, step in
                    Button {
                        withAnimation(DS.springSnappy) {
                            highlightedStep = highlightedStep == i ? nil : i
                        }
                    } label: {
                        HStack(alignment: .top, spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(highlightedStep == i ? flow.accentColor : flow.accentColor.opacity(0.15))
                                    .frame(width: 30, height: 30)
                                Text("\(i + 1)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(highlightedStep == i ? .white : flow.accentColor)
                            }
                            .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(step.title)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                Text(step.detail)
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(DS.textMuted)
                                    .multilineTextAlignment(.leading)
                                    .lineSpacing(3)
                                    .fixedSize(horizontal: false, vertical: true)
                                if let cmd = step.command {
                                    HStack(spacing: 5) {
                                        Image(systemName: "terminal.fill")
                                            .font(.system(size: 9))
                                            .foregroundColor(flow.accentColor)
                                            .accessibilityHidden(true)
                                        Text(cmd)
                                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                                            .foregroundColor(flow.accentColor)
                                    }
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(RoundedRectangle(cornerRadius: 5).fill(flow.accentColor.opacity(0.10)))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: DS.radiusM, style: .continuous)
                                .fill(highlightedStep == i ? flow.accentColor.opacity(0.08) : DS.bg1)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DS.radiusM, style: .continuous)
                                        .strokeBorder(
                                            highlightedStep == i ? flow.accentColor.opacity(0.3) : Color.clear,
                                            lineWidth: 1
                                        )
                                )
                        )
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Step \(i + 1): \(step.title). \(step.detail)")
                    .accessibilityHint("Double-tap to highlight in diagram")
                }
            }

            // Pros & Cons
            HStack(alignment: .top, spacing: 12) {
                // Pros
                VStack(alignment: .leading, spacing: 8) {
                    Label("Pros", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(DS.success)
                    ForEach(flow.pros, id: \.self) { pro in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(DS.success)
                                .padding(.top, 3)
                                .accessibilityHidden(true)
                            Text(pro)
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(DS.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: DS.radiusM).fill(DS.success.opacity(0.06)))

                // Cons
                VStack(alignment: .leading, spacing: 8) {
                    Label("Cons", systemImage: "xmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(DS.danger)
                    ForEach(flow.cons, id: \.self) { con in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "minus")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(DS.danger)
                                .padding(.top, 3)
                                .accessibilityHidden(true)
                            Text(con)
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(DS.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: DS.radiusM).fill(DS.danger.opacity(0.06)))
            }
        }
    }
}

// MARK: - Flow Diagram Canvas
struct FlowDiagramCanvas: View {
    let flow: GitFlow
    let animPhase: CGFloat
    let highlighted: Int?

    var body: some View {
        Canvas { ctx, size in
            switch flow.id {
            case "github":   drawGitHubFlow(ctx: ctx, size: size, phase: animPhase)
            case "gitflow":  drawGitFlow(ctx: ctx, size: size, phase: animPhase)
            case "trunk":    drawTrunkFlow(ctx: ctx, size: size, phase: animPhase)
            case "feature":  drawFeatureFlow(ctx: ctx, size: size, phase: animPhase)
            default:         break
            }
        }
    }

    // ── GitHub Flow ──────────────────────────────────────────────
    // main ──●──────────────────────●── merge ──●
    //         ╲── feature ──●──●──●╱
    func drawGitHubFlow(ctx: GraphicsContext, size: CGSize, phase: CGFloat) {
        let W = size.width, H = size.height
        let mainY  = H * 0.35
        let featY  = H * 0.70
        let cols: [CGFloat] = [0.08, 0.22, 0.40, 0.55, 0.68, 0.82, 0.93].map { $0 * W }

        let main1  = CGPoint(x: cols[0], y: mainY)
        let branch = CGPoint(x: cols[1], y: mainY)
        let feat1  = CGPoint(x: cols[2], y: featY)
        let feat2  = CGPoint(x: cols[3], y: featY)
        let feat3  = CGPoint(x: cols[4], y: featY)
        let merge  = CGPoint(x: cols[5], y: mainY)
        let main2  = CGPoint(x: cols[6], y: mainY)

        let c0 = Color.branchColors[0], c1 = Color.branchColors[1]

        // Lines
        line(ctx, from: main1, to: branch, color: c0)
        line(ctx, from: branch, to: merge,  color: c0)
        line(ctx, from: merge,  to: main2,  color: c0)
        curve(ctx, from: branch, to: feat1, color: c1)
        line(ctx, from: feat1,  to: feat2,  color: c1)
        line(ctx, from: feat2,  to: feat3,  color: c1)
        curve(ctx, from: feat3, to: merge,  color: c1.opacity(0.6 + phase * 0.4))

        // Nodes
        node(ctx, at: main1, color: c0, r: 9, label: "")
        node(ctx, at: branch, color: c0, r: 9, label: "")
        node(ctx, at: feat1,  color: c1, r: 9, label: "")
        node(ctx, at: feat2,  color: c1, r: 9, label: "")
        node(ctx, at: feat3,  color: c1, r: 9, label: "")
        node(ctx, at: merge,  color: DS.success, r: 11, label: "M")
        node(ctx, at: main2,  color: c0, r: 9, label: "")

        // Labels
        label(ctx, text: "main",    at: CGPoint(x: cols[3], y: mainY - 22), color: c0)
        label(ctx, text: "feature", at: CGPoint(x: cols[3], y: featY + 22), color: c1)
    }

    // ── GitFlow ─────────────────────────────────────────────────
    // main ──●────────────────────────────────────●── tag ──●
    // develop ──●──●──────────────────────●──●──●
    //             ╲── feature ──●──●──●──╱
    func drawGitFlow(ctx: GraphicsContext, size: CGSize, phase: CGFloat) {
        let W = size.width, H = size.height
        let mainY  = H * 0.20
        let devY   = H * 0.50
        let featY  = H * 0.80
        let xs: [CGFloat] = [0.06, 0.18, 0.30, 0.44, 0.58, 0.70, 0.82, 0.93].map { $0 * W }

        let c0 = Color.branchColors[0]  // main
        let c1 = Color.branchColors[2]  // develop
        let c2 = Color.branchColors[1]  // feature

        // horizontal rails
        line(ctx, from: CGPoint(x: xs[0], y: mainY), to: CGPoint(x: xs[6], y: mainY), color: c0)
        line(ctx, from: CGPoint(x: xs[1], y: devY), to: CGPoint(x: xs[5], y: devY),   color: c1)
        // feature branch
        line(ctx, from: CGPoint(x: xs[2], y: featY), to: CGPoint(x: xs[4], y: featY), color: c2)
        curve(ctx, from: CGPoint(x: xs[1], y: devY), to: CGPoint(x: xs[2], y: featY), color: c2)
        curve(ctx, from: CGPoint(x: xs[4], y: featY), to: CGPoint(x: xs[5], y: devY), color: c2.opacity(0.5 + phase * 0.5))
        // release merge
        curve(ctx, from: CGPoint(x: xs[5], y: devY), to: CGPoint(x: xs[6], y: mainY), color: c1.opacity(0.5 + phase * 0.5))

        // Main nodes
        node(ctx, at: CGPoint(x: xs[0], y: mainY), color: c0, r: 9, label: "")
        node(ctx, at: CGPoint(x: xs[6], y: mainY), color: DS.success, r: 11, label: "v1")
        node(ctx, at: CGPoint(x: xs[7], y: mainY), color: c0, r: 9, label: "")
        // Dev nodes
        for xi in [xs[1], xs[3], xs[5]] {
            node(ctx, at: CGPoint(x: xi, y: devY), color: c1, r: 9, label: "")
        }
        // Feature nodes
        for xi in [xs[2], xs[3], xs[4]] {
            node(ctx, at: CGPoint(x: xi, y: featY), color: c2, r: 9, label: "")
        }

        label(ctx, text: "main",    at: CGPoint(x: xs[3], y: mainY - 20), color: c0)
        label(ctx, text: "develop", at: CGPoint(x: xs[3], y: devY   - 20), color: c1)
        label(ctx, text: "feature", at: CGPoint(x: xs[3], y: featY  + 22), color: c2)
    }

    // ── Trunk-Based Dev ─────────────────────────────────────────
    // trunk ──●──●──●──●──●──●──●──●   (lots of small commits, short-lived branches)
    //              ╲─╱   ╲─╱   ╲─╱
    func drawTrunkFlow(ctx: GraphicsContext, size: CGSize, phase: CGFloat) {
        let W = size.width, H = size.height
        let trunkY = H * 0.40
        let shortY = H * 0.72
        let xs: [CGFloat] = stride(from: 0.07, through: 0.95, by: 0.12).map { $0 * W }
        let c0 = Color.branchColors[0]
        let c1 = Color.branchColors[1]

        // Trunk
        for i in 0..<(xs.count - 1) {
            line(ctx, from: CGPoint(x: xs[i], y: trunkY), to: CGPoint(x: xs[i+1], y: trunkY), color: c0)
        }
        // Short-lived branches at indices 1, 3, 5
        for i in stride(from: 1, to: xs.count - 1, by: 2) {
            let mid = CGPoint(x: (xs[i] + xs[i+1]) / 2, y: shortY)
            curve(ctx, from: CGPoint(x: xs[i], y: trunkY), to: mid, color: c1)
            curve(ctx, from: mid, to: CGPoint(x: xs[i+1], y: trunkY),
                  color: c1.opacity(0.4 + phase * 0.6))
            node(ctx, at: mid, color: c1, r: 7, label: "")
        }
        // Trunk nodes
        for (i, x) in xs.enumerated() {
            let isRelease = (i == xs.count - 1)
            node(ctx, at: CGPoint(x: x, y: trunkY),
                 color: isRelease ? DS.success : c0, r: isRelease ? 11 : 8, label: isRelease ? "▶" : "")
        }
        label(ctx, text: "trunk (main)",      at: CGPoint(x: W * 0.5, y: trunkY - 22), color: c0)
        label(ctx, text: "short-lived branch", at: CGPoint(x: W * 0.5, y: shortY + 22), color: c1)
    }

    // ── Feature Branch Flow ─────────────────────────────────────
    func drawFeatureFlow(ctx: GraphicsContext, size: CGSize, phase: CGFloat) {
        let W = size.width, H = size.height
        let mainY = H * 0.30
        let f1Y   = H * 0.60
        let f2Y   = H * 0.85
        let xs: [CGFloat] = [0.07, 0.20, 0.38, 0.53, 0.67, 0.80, 0.93].map { $0 * W }

        let c0 = Color.branchColors[0]
        let c1 = Color.branchColors[1]
        let c2 = Color.branchColors[2]

        line(ctx, from: CGPoint(x: xs[0], y: mainY), to: CGPoint(x: xs[6], y: mainY), color: c0)

        // Feature A
        curve(ctx, from: CGPoint(x: xs[1], y: mainY), to: CGPoint(x: xs[2], y: f1Y), color: c1)
        line(ctx,  from: CGPoint(x: xs[2], y: f1Y),   to: CGPoint(x: xs[3], y: f1Y), color: c1)
        curve(ctx, from: CGPoint(x: xs[3], y: f1Y),   to: CGPoint(x: xs[4], y: mainY), color: c1.opacity(0.5 + phase * 0.5))

        // Feature B (longer)
        curve(ctx, from: CGPoint(x: xs[2], y: mainY), to: CGPoint(x: xs[3], y: f2Y), color: c2)
        line(ctx,  from: CGPoint(x: xs[3], y: f2Y),   to: CGPoint(x: xs[4], y: f2Y), color: c2)
        curve(ctx, from: CGPoint(x: xs[4], y: f2Y),   to: CGPoint(x: xs[5], y: mainY), color: c2.opacity(0.5 + phase * 0.5))

        // Nodes
        for xi in [xs[0], xs[1], xs[2], xs[4], xs[5], xs[6]] {
            node(ctx, at: CGPoint(x: xi, y: mainY), color: c0, r: 8, label: "")
        }
        node(ctx, at: CGPoint(x: xs[4], y: mainY), color: DS.success, r: 10, label: "")
        node(ctx, at: CGPoint(x: xs[5], y: mainY), color: DS.success, r: 10, label: "")
        for xi in [xs[2], xs[3]] { node(ctx, at: CGPoint(x: xi, y: f1Y), color: c1, r: 8, label: "") }
        for xi in [xs[3], xs[4]] { node(ctx, at: CGPoint(x: xi, y: f2Y), color: c2, r: 8, label: "") }

        label(ctx, text: "main",      at: CGPoint(x: xs[3], y: mainY - 20), color: c0)
        label(ctx, text: "feature-A", at: CGPoint(x: xs[3], y: f1Y   + 22), color: c1)
        label(ctx, text: "feature-B", at: CGPoint(x: xs[4], y: f2Y   + 22), color: c2)
    }

    // ── Drawing helpers ─────────────────────────────────────────
    private func line(_ ctx: GraphicsContext, from a: CGPoint, to b: CGPoint, color: Color) {
        var p = Path(); p.move(to: a); p.addLine(to: b)
        ctx.stroke(p, with: .color(color.opacity(0.55)), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
    }
    private func curve(_ ctx: GraphicsContext, from a: CGPoint, to b: CGPoint, color: Color) {
        var p = Path()
        p.move(to: a)
        let cp1 = CGPoint(x: a.x, y: (a.y + b.y) / 2)
        let cp2 = CGPoint(x: b.x, y: (a.y + b.y) / 2)
        p.addCurve(to: b, control1: cp1, control2: cp2)
        ctx.stroke(p, with: .color(color.opacity(0.55)), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
    }
    private func node(_ ctx: GraphicsContext, at pt: CGPoint, color: Color, r: CGFloat, label: String) {
        let rect = CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)
        ctx.fill(Path(ellipseIn: rect), with: .color(color))
        ctx.stroke(Path(ellipseIn: rect), with: .color(.white.opacity(0.25)), lineWidth: 1.5)
    }
    private func label(_ ctx: GraphicsContext, text: String, at pt: CGPoint, color: Color) {
        ctx.draw(
            Text(text)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(color),
            at: pt
        )
    }
}

// MARK: - Data Models

struct GitFlow: Identifiable {
    let id: String
    let name: String
    let icon: String
    let accentColor: Color
    let description: String
    let usedBy: String
    let steps: [FlowStep]
    let pros: [String]
    let cons: [String]

    struct FlowStep {
        let title: String
        let detail: String
        let command: String?
    }

    static let all: [GitFlow] = [githubFlow, gitFlow, trunkFlow, featureFlow]

    // ── GitHub Flow ──────────────────────────────────────────────
    static let githubFlow = GitFlow(
        id: "github",
        name: "GitHub Flow",
        icon: "arrow.triangle.branch",
        accentColor: DS.accent,
        description: "A lightweight, branch-based workflow built around regular deployments. Simple enough for small teams shipping fast — the most popular flow for web apps and SaaS products.",
        usedBy: "GitHub, Shopify, smaller teams",
        steps: [
            FlowStep(title: "Create a branch", detail: "Branch off main for every feature, fix, or experiment.", command: "git checkout -b feature/login"),
            FlowStep(title: "Add commits", detail: "Make small, focused commits as you build the feature.", command: "git commit -m \"Add login form\""),
            FlowStep(title: "Open a Pull Request", detail: "Push your branch and open a PR to start discussion.", command: "git push origin feature/login"),
            FlowStep(title: "Review & discuss", detail: "Team members review code, suggest changes, leave comments.", command: nil),
            FlowStep(title: "Deploy & test", detail: "Deploy the PR branch to staging for testing before merge.", command: nil),
            FlowStep(title: "Merge to main", detail: "Once approved, merge into main and deploy to production.", command: "git merge feature/login"),
        ],
        pros: ["Very simple", "Fast iteration", "CI/CD friendly"],
        cons: ["Not ideal for complex release schedules", "Requires good test coverage"]
    )

    // ── GitFlow ──────────────────────────────────────────────────
    static let gitFlow = GitFlow(
        id: "gitflow",
        name: "GitFlow",
        icon: "arrow.triangle.merge",
        accentColor: DS.warning,
        description: "A strict branching model with dedicated branches for features, releases, and hotfixes. Built for projects with scheduled release cycles — common in mobile apps and enterprise software.",
        usedBy: "Enterprise software, mobile apps, libraries",
        steps: [
            FlowStep(title: "main & develop", detail: "'main' holds production code. 'develop' is the integration branch for new features.", command: nil),
            FlowStep(title: "Feature branches", detail: "New features are built on branches from 'develop'.", command: "git checkout -b feature/search develop"),
            FlowStep(title: "Merge to develop", detail: "Completed features are merged back into 'develop'.", command: "git merge --no-ff feature/search"),
            FlowStep(title: "Release branch", detail: "When ready, cut a release branch from 'develop' for final testing.", command: "git checkout -b release/1.0 develop"),
            FlowStep(title: "Merge to main & tag", detail: "Finished release merges to 'main' and gets a version tag.", command: "git tag -a v1.0"),
            FlowStep(title: "Hotfixes", detail: "Critical bugs are fixed on branches from 'main', then merged back to both 'main' and 'develop'.", command: "git checkout -b hotfix/crash main"),
        ],
        pros: ["Structured", "Good for versioned releases", "Clear hotfix path"],
        cons: ["Complex", "Overhead for simple projects", "Slows CI/CD"]
    )

    // ── Trunk-Based ──────────────────────────────────────────────
    static let trunkFlow = GitFlow(
        id: "trunk",
        name: "Trunk-Based Dev",
        icon: "arrow.up.to.line",
        accentColor: DS.success,
        description: "Developers commit small changes directly to 'trunk' (main) multiple times per day. Feature flags hide incomplete work. Maximises integration speed and is the foundation of true continuous delivery.",
        usedBy: "Google, Meta, Spotify, high-velocity teams",
        steps: [
            FlowStep(title: "Commit to trunk daily", detail: "All developers push small commits to main at least once a day.", command: "git commit -m \"Add validation\""),
            FlowStep(title: "Short-lived branches only", detail: "Branches (if any) live for hours, not days. Merged before end of day.", command: "git checkout -b fix/typo"),
            FlowStep(title: "Feature flags", detail: "Incomplete features are behind flags so you can ship code without exposing features.", command: nil),
            FlowStep(title: "CI runs on every commit", detail: "Automated tests run immediately on every push. Build must stay green.", command: nil),
            FlowStep(title: "Release from trunk", detail: "Any commit on trunk can be released. Releases are just tags, not branches.", command: "git tag v2.3.1"),
        ],
        pros: ["Maximum integration speed", "Avoids merge hell", "True CI/CD"],
        cons: ["Requires strong test suite", "Feature flags overhead", "Needs discipline"]
    )

    // ── Feature Branch ───────────────────────────────────────────
    static let featureFlow = GitFlow(
        id: "feature",
        name: "Feature Branch",
        icon: "arrow.triangle.branch",
        accentColor: DS.info,
        description: "The simplest multi-developer pattern: every feature lives on its own branch until it's complete, then gets merged to main via a pull request. The basis of most team workflows.",
        usedBy: "Most teams, open-source projects",
        steps: [
            FlowStep(title: "Branch per feature", detail: "Each task or feature gets its own isolated branch from main.", command: "git checkout -b feat/dark-mode"),
            FlowStep(title: "Develop in isolation", detail: "Work freely without affecting main or other developers.", command: "git commit -m \"Implement dark mode\""),
            FlowStep(title: "Keep updated", detail: "Regularly pull latest main into your branch to avoid drift.", command: "git rebase main"),
            FlowStep(title: "Pull Request", detail: "Open a PR when ready for review. Automated tests run.", command: "git push origin feat/dark-mode"),
            FlowStep(title: "Code review", detail: "Team reviews the diff, requests changes, approves.", command: nil),
            FlowStep(title: "Merge & delete", detail: "Merge approved PR into main. Delete the feature branch.", command: "git branch -d feat/dark-mode"),
        ],
        pros: ["Clean isolation", "Easy to review", "Flexible parallelism"],
        cons: ["Long-lived branches cause merge conflicts", "Slower than trunk-based"]
    )
}
