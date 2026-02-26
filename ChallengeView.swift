import SwiftUI

// MARK: - Challenge View (root — manages state for list vs active)
struct ChallengeView: View {
    @StateObject private var engine = ChallengeEngine()
    @State private var activeChallengeId: String? = nil

    var body: some View {
        Group {
            if let cid = activeChallengeId,
               let challenge = engine.challenges.first(where: { $0.id == cid }) {
                ActiveChallengeView(
                    challenge: challenge,
                    engine: engine,
                    activeChallengeId: $activeChallengeId
                )
            } else {
                ChallengeListView(engine: engine, activeChallengeId: $activeChallengeId)
            }
        }
        .animation(DS.springSmooth, value: activeChallengeId)
    }
}

// MARK: - Challenge List View
struct ChallengeListView: View {
    @ObservedObject var engine: ChallengeEngine
    @Binding var activeChallengeId: String?

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            DS.bg0.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Header
                    HStack(spacing: 10) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "#F59E0B"), Color(hex: "#FBBF24")],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .accessibilityHidden(true)
                        Text("Challenges")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    Text("Solve Git puzzles to master the concepts")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(DS.textMuted)
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                        .padding(.bottom, 16)

                    // Progress bar
                    let done  = engine.completedChallengeIds.count
                    let total = engine.challenges.count
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(done) of \(total) completed")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(DS.bg2).frame(height: 6)
                                Capsule()
                                    .fill(LinearGradient(colors: [DS.accent, DS.accentLit],
                                                         startPoint: .leading, endPoint: .trailing))
                                    .frame(
                                        width: total > 0
                                            ? geo.size.width * CGFloat(done) / CGFloat(total)
                                            : 0,
                                        height: 6
                                    )
                                    .animation(DS.springSmooth, value: done)
                            }
                        }
                        .frame(height: 6)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)

                    // Grid
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(engine.challenges) { challenge in
                            let unlocked  = engine.isUnlocked(challenge)
                            let completed = engine.completedChallengeIds.contains(challenge.id)
                            ChallengeCard(challenge: challenge, isUnlocked: unlocked, isCompleted: completed)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    guard unlocked else { return }
                                    engine.start(challenge)
                                    activeChallengeId = challenge.id
                                }
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel(
                                    "\(challenge.title). \(challenge.difficulty.badge). " +
                                    (completed ? "Completed." : unlocked ? "Available." : "Locked.")
                                )
                                .accessibilityHint(unlocked && !completed ? "Double tap to start" : "")
                                .accessibilityAddTraits(unlocked ? AccessibilityTraits.isButton : AccessibilityTraits())
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 32)
                }
            }
        }
    }
}

// MARK: - Challenge Card
struct ChallengeCard: View {
    let challenge: GitChallenge
    let isUnlocked: Bool
    let isCompleted: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // ── Card content (always visible) ──────────────────
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(challenge.difficulty.badge)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(challenge.difficulty.color)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(challenge.difficulty.color.opacity(0.15)))
                    Spacer()
                    // Checkmark only shown when unlocked+complete
                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(DS.success).font(.system(size: 16))
                    }
                }

                Text(challenge.title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Text(challenge.description)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(DS.textMuted)
                    .lineLimit(3)

                if let op = challenge.operations.first {
                    Text(op)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(DS.accent.opacity(isUnlocked ? 0.9 : 0.4))
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(Capsule().fill(DS.accent.opacity(isUnlocked ? 0.12 : 0.06)))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 155, alignment: .topLeading)

            // ── Frosted lock overlay (locked only) ─────────────
            if !isUnlocked {
                RoundedRectangle(cornerRadius: DS.radiusL, style: .continuous)
                    .fill(DS.bg0.opacity(0.55))
                    .overlay(
                        VStack(spacing: 6) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(DS.textMuted)
                            Text("Complete previous\nchallenge to unlock")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(DS.textMuted)
                                .multilineTextAlignment(.center)
                        }
                    )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: DS.radiusL, style: .continuous)
                .fill(isCompleted ? DS.success.opacity(0.08) : DS.bg1)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.radiusL, style: .continuous)
                        .strokeBorder(
                            isCompleted ? DS.success.opacity(0.4) :
                            isUnlocked  ? DS.accent.opacity(0.2)  : DS.textMuted.opacity(0.08),
                            lineWidth: 1
                        )
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.radiusL, style: .continuous))
    }
}

// MARK: - Active Challenge View
struct ActiveChallengeView: View {
    let challenge: GitChallenge
    @ObservedObject var engine: ChallengeEngine
    @Binding var activeChallengeId: String?

    /// The challenge that comes after this one (nil if this is the last)
    private var nextChallenge: GitChallenge? {
        guard let idx = engine.challenges.firstIndex(where: { $0.id == challenge.id }),
              idx + 1 < engine.challenges.count
        else { return nil }
        return engine.challenges[idx + 1]
    }

    @State private var selectedCommitId: String? = nil
    @State private var showHints = false
    @State private var showSheet  = false

    var body: some View {
        ZStack {
            DS.bg0.ignoresSafeArea()

            VStack(spacing: 0) {
                // Nav bar
                HStack(spacing: 12) {
                    Button {
                        engine.reset()
                        activeChallengeId = nil
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(DS.textSecondary)
                    }
                    .accessibilityLabel("Back to challenges")

                    VStack(alignment: .leading, spacing: 2) {
                        Text(challenge.title)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text(challenge.difficulty.badge)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(challenge.difficulty.color)
                    }
                    Spacer()

                    Button {
                        withAnimation(DS.springSnappy) { showHints.toggle() }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#F59E0B"))
                            Text("Hints")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(hex: "#F59E0B"))
                        }
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Capsule().fill(Color(hex: "#F59E0B").opacity(0.15)))
                    }
                    .accessibilityLabel("Hints. \(engine.hintsRevealed) of \(challenge.hints.count) revealed.")
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(DS.bg1)

                // Goal banner
                ChallengeGoalBanner(goal: challenge.goal, isComplete: engine.isComplete)
                    .padding(.horizontal, 12).padding(.vertical, 8)

                if showHints {
                    ChallengeHintPanel(challenge: challenge, engine: engine)
                        .padding(.horizontal, 12).padding(.bottom, 6)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                Divider().background(DS.textMuted.opacity(0.15))

                // Graph + commands
                GeometryReader { geo in
                    if geo.size.width > 600 {
                        HStack(spacing: 0) {
                            GraphView(engine: engine.engine, selectedCommitId: $selectedCommitId)
                            Divider().background(DS.textMuted.opacity(0.2))
                            CommandPanelView(engine: engine.engine)
                                .frame(width: 300).padding(10).background(DS.bg1)
                        }
                    } else {
                        ZStack(alignment: .bottom) {
                            GraphView(engine: engine.engine, selectedCommitId: $selectedCommitId)
                                .padding(.bottom, 310)
                            CommandPanelView(engine: engine.engine)
                                .frame(maxHeight: 310)
                                .padding(.horizontal, 8).padding(.bottom, 8)
                        }
                    }
                }
            }

            if engine.isComplete {
                ChallengeSuccessOverlay(
                    challenge: challenge,
                    nextChallenge: nextChallenge,
                    onBack: {
                        engine.reset()
                        activeChallengeId = nil
                    },
                    onNextChallenge: { next in
                        engine.reset()
                        engine.start(next)
                        activeChallengeId = next.id
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .animation(DS.springBouncy, value: engine.isComplete)
        .animation(DS.springSnappy, value: showHints)
        .onChange(of: selectedCommitId, perform: { newId in
            showSheet = (newId != nil)
        })
        .sheet(isPresented: $showSheet, onDismiss: { selectedCommitId = nil }) {
            if let cid = selectedCommitId {
                CommitDetailSheet(commitId: cid, engine: engine.engine, selectedCommitId: $selectedCommitId)
            }
        }
        .onReceive(engine.engine.$commandHistory) { _ in engine.checkGoal() }
        .onReceive(engine.engine.$commits)        { _ in engine.checkGoal() }
        .onReceive(engine.engine.$branches)       { _ in engine.checkGoal() }
        .onReceive(engine.engine.$tags)           { _ in engine.checkGoal() }
    }
}

// MARK: - Goal Banner
struct ChallengeGoalBanner: View {
    let goal: ChallengeGoal
    let isComplete: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "target")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isComplete ? DS.success : DS.accentLit)

            VStack(alignment: .leading, spacing: 1) {
                Text("Goal")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(DS.textMuted)
                Text(goal.description)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(isComplete ? DS.success : .primary)
            }
            Spacer()
            if isComplete {
                Text("Done!")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(DS.success)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill(DS.success.opacity(0.15)))
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: DS.radiusM, style: .continuous)
                .fill(isComplete ? DS.success.opacity(0.08) : DS.bg1)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.radiusM, style: .continuous)
                        .strokeBorder(
                            isComplete ? DS.success.opacity(0.4) : DS.accent.opacity(0.25),
                            lineWidth: 1
                        )
                )
        )
        .animation(DS.springSnappy, value: isComplete)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Goal: \(goal.description). \(isComplete ? "Completed!" : "In progress.")")
    }
}

// MARK: - Hint Panel
struct ChallengeHintPanel: View {
    let challenge: GitChallenge
    @ObservedObject var engine: ChallengeEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(Color(hex: "#F59E0B")).font(.system(size: 13))
                Text("Hints")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Spacer()
                if engine.hintsRevealed < challenge.hints.count {
                    Button("Reveal next") { engine.revealNextHint() }
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "#F59E0B"))
                        .accessibilityLabel("Reveal next hint")
                }
            }

            let revealed = Array(challenge.hints.prefix(engine.hintsRevealed).enumerated())
            ForEach(revealed, id: \.offset) { i, hint in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(i + 1)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "#F59E0B"))
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(Color(hex: "#F59E0B").opacity(0.15)))
                    Text(hint)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(DS.textSecondary)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Hint \(i + 1): \(hint)")
            }

            if engine.hintsRevealed == 0 {
                Text("Tap 'Reveal next' to get your first hint.")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(DS.textMuted)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: DS.radiusM, style: .continuous)
                .fill(DS.bg1)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.radiusM, style: .continuous)
                        .strokeBorder(Color(hex: "#F59E0B").opacity(0.25), lineWidth: 1)
                )
        )
        .animation(DS.springSnappy, value: engine.hintsRevealed)
    }
}

// MARK: - Success Overlay
struct ChallengeSuccessOverlay: View {
    let challenge: GitChallenge
    let nextChallenge: GitChallenge?
    let onBack: () -> Void
    let onNextChallenge: (GitChallenge) -> Void

    @State private var scaleIn: CGFloat = 0.5
    @State private var opacityIn: Double = 0
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()

            VStack(spacing: 24) {
                // Trophy icon
                Image(systemName: "trophy.fill")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#F59E0B"), Color(hex: "#FBBF24")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color(hex: "#F59E0B").opacity(0.5), radius: 20)

                // Challenge info
                VStack(spacing: 8) {
                    Text("Challenge Complete!")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(challenge.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(DS.textSecondary)
                    HStack(spacing: 8) {
                        Text(challenge.difficulty.badge)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(challenge.difficulty.color)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Capsule().fill(challenge.difficulty.color.opacity(0.15)))
                        Text("✓ Solved")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(DS.success)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Capsule().fill(DS.success.opacity(0.15)))
                    }
                }

                // Action buttons
                VStack(spacing: 10) {
                    // Primary: Next challenge (if available)
                    if let next = nextChallenge {
                        Button {
                            onNextChallenge(next)
                        } label: {
                            HStack(spacing: 8) {
                                Text("Next: \(next.title)")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: 260)
                        }
                        .buttonStyle(AccentButtonStyle(color: DS.accent))
                        .accessibilityLabel("Next challenge: \(next.title)")
                    }

                    // Secondary: Back to list
                    Button(action: onBack) {
                        HStack(spacing: 8) {
                            Image(systemName: "list.bullet").accessibilityHidden(true)
                            Text(nextChallenge != nil ? "Back to Challenges" : "All Done! Back to List")
                        }
                        .font(.system(size: nextChallenge != nil ? 14 : 16,
                                      weight: nextChallenge != nil ? .medium : .semibold,
                                      design: .rounded))
                        .foregroundColor(nextChallenge != nil ? DS.textSecondary : .white)
                        .frame(maxWidth: 260)
                    }
                    .buttonStyle(AccentButtonStyle(
                        color: nextChallenge != nil ? DS.textMuted : DS.success
                    ))
                    .accessibilityLabel("Back to challenges list")
                }
            }
            .padding(36)
            .background(
                RoundedRectangle(cornerRadius: DS.radiusL + 4, style: .continuous)
                    .fill(DS.bg1)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.radiusL + 4, style: .continuous)
                            .strokeBorder(DS.success.opacity(0.35), lineWidth: 1.5)
                    )
            )
            .padding(.horizontal, 28)
            .scaleEffect(scaleIn)
            .opacity(opacityIn)
            // Confetti burst
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            withAnimation(DS.springBouncy) {
                scaleIn = 1.0
                opacityIn = 1.0
            }
            // Trigger confetti after card finishes animating in
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                showConfetti = true
            }
        }
        .accessibilityElement(children: .contain)
    }
}
