import SwiftUI

// MARK: - Learn View
struct LearnView: View {
    @EnvironmentObject var engine: GitEngine
    @State private var currentPage = 0

    let lessons = GitLessonData.all

    var body: some View {
        ZStack {
            DS.bg0.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Learn Git")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Interactive visual lessons")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(DS.textMuted)
                    }
                    Spacer()
                    // Progress
                    ZStack {
                        Circle()
                            .stroke(DS.bg3, lineWidth: 3)
                        Circle()
                            .trim(from: 0, to: CGFloat(currentPage + 1) / CGFloat(lessons.count))
                            .stroke(DS.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text("\(currentPage + 1)/\(lessons.count)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .frame(width: 48, height: 48)
                    .animation(DS.springSmooth, value: currentPage)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Lesson \(currentPage + 1) of \(lessons.count)")
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // Lesson cards pager
                TabView(selection: $currentPage) {
                    ForEach(Array(lessons.enumerated()), id: \.offset) { i, lesson in
                        LessonCard(lesson: lesson, engine: engine)
                            .tag(i)
                            .padding(.horizontal, 16)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(DS.springSmooth, value: currentPage)

                // Dot indicators + navigation
                HStack(spacing: 0) {
                    Button {
                        withAnimation(DS.springSmooth) {
                            if currentPage > 0 { currentPage -= 1 }
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(currentPage > 0 ? DS.accentLit : DS.textMuted)
                    }
                    .disabled(currentPage == 0)
                    .accessibilityLabel("Previous lesson")
                    .accessibilityHint(currentPage > 0 ? "Go to lesson \(currentPage)" : "Already on the first lesson")

                    Spacer()

                    HStack(spacing: 6) {
                        ForEach(0..<lessons.count, id: \.self) { i in
                            Circle()
                                .fill(i == currentPage ? DS.accentLit : DS.textMuted.opacity(0.4))
                                .frame(width: i == currentPage ? 10 : 6, height: i == currentPage ? 10 : 6)
                                .animation(DS.springSnappy, value: currentPage)
                                .accessibilityHidden(true)
                        }
                    }

                    Spacer()

                    Button {
                        withAnimation(DS.springSmooth) {
                            if currentPage < lessons.count - 1 { currentPage += 1 }
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(currentPage < lessons.count - 1 ? DS.accentLit : DS.textMuted)
                    }
                    .disabled(currentPage == lessons.count - 1)
                    .accessibilityLabel("Next lesson")
                    .accessibilityHint(currentPage < lessons.count - 1 ? "Go to lesson \(currentPage + 2): \(lessons[currentPage + 1].title)" : "Already on the last lesson")
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 20)
                .padding(.top, 8)
            }
        }
    }
}

// MARK: - Lesson Card
struct LessonCard: View {
    let lesson: GitLesson
    @ObservedObject var engine: GitEngine
    @State private var stepIndex = 0
    @State private var expanded = false
    @State private var showPlayground = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: DS.radiusM, style: .continuous)
                            .fill(lesson.color.opacity(0.2))
                            .frame(width: 56, height: 56)
                        Image(systemName: lesson.icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(lesson.color)
                    }
                    .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(lesson.title)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text(lesson.subtitle)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(DS.textMuted)
                    }
                    Spacer()
                }

                // Mini graph preview
                LessonMiniGraph(lesson: lesson)
                    .frame(height: 140)
                    .glassCard(cornerRadius: DS.radiusL)
                    .clipped()
                    .accessibilityHidden(true)

                // Explanation
                Text(lesson.explanation)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(DS.textSecondary)
                    .lineSpacing(5)

                // Step-by-step
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Step by step")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(DS.textMuted)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                    .padding(.bottom, 6)

                    ForEach(Array(lesson.steps.enumerated()), id: \.element.id) { i, step in
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(i <= stepIndex ? lesson.color : DS.bg3)
                                    .frame(width: 26, height: 26)
                                Text("\(i + 1)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(i <= stepIndex ? .white : DS.textMuted)
                            }
                            .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(step.title)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(i <= stepIndex ? .white : DS.textSecondary)
                                if i <= stepIndex {
                                    Text(step.detail)
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundColor(DS.textMuted)
                                        .transition(.move(edge: .top).combined(with: .opacity))
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(DS.springSnappy) {
                                stepIndex = i
                            }
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Step \(i + 1): \(step.title). \(step.detail)")
                        .accessibilityHint(i == stepIndex ? "Current step" : "Double tap to view this step")
                        .accessibilityAddTraits(.isButton)
                        if i < lesson.steps.count - 1 {
                            Rectangle()
                                .fill(DS.textMuted.opacity(0.15))
                                .frame(width: 1, height: 16)
                                .padding(.leading, 24)
                                .accessibilityHidden(true)
                        }
                    }
                    .padding(.bottom, 10)
                }
                .glassCard(cornerRadius: DS.radiusL)

                // Command display
                if let op = lesson.operation {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Command")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(DS.textMuted)
                        HStack(spacing: 10) {
                            Image(systemName: "terminal")
                                .foregroundColor(lesson.color)
                                .font(.system(size: 14))
                                .accessibilityHidden(true)
                            Text(op.description)
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: DS.radiusS).fill(DS.bg3))
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Git command: \(op.description)")
                    }
                }

                Spacer(minLength: 24)

                // ── Try it Live button ──────────────────────
                Button {
                    showPlayground = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 16))
                        Text("Try it Live")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: DS.radiusM, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [lesson.color.opacity(0.8), lesson.color],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .shadow(color: lesson.color.opacity(0.4), radius: 8, y: 4)
                    )
                }
                .accessibilityLabel("Try \(lesson.title) interactively")
                .accessibilityHint("Opens a live Git graph where you can practice this concept")

                Spacer(minLength: 40)
            }
            .padding(.vertical, 16)
        }
        .sheet(isPresented: $showPlayground) {
            LessonPlaygroundView(lesson: lesson) {
                showPlayground = false
            }
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Lesson Mini Graph
struct LessonMiniGraph: View {
    let lesson: GitLesson
    @State private var animPhase: CGFloat = 0

    var body: some View {
        Canvas { ctx, size in
            drawForLesson(ctx: ctx, size: size, phase: animPhase)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animPhase = 1
            }
        }
    }

    func drawForLesson(ctx: GraphicsContext, size: CGSize, phase: CGFloat) {
        let cx = size.width / 2
        let cy = size.height / 2
        let r: CGFloat = 11

        switch lesson.title {
        case "What is a Commit?":
            let pts: [CGPoint] = [
                CGPoint(x: cx, y: size.height - 20),
                CGPoint(x: cx, y: cy),
                CGPoint(x: cx, y: 20)
            ]
            drawChain(ctx: ctx, pts: pts, color: Color.branchColors[0], r: r, phase: phase)

        case "Branches":
            let root = CGPoint(x: cx, y: size.height - 20)
            let main1 = CGPoint(x: cx, y: cy + 20)
            let main2 = CGPoint(x: cx - 50, y: 20)
            let dev1  = CGPoint(x: cx + 50, y: 20)
            drawLine(ctx: ctx, from: root, to: main1, color: Color.branchColors[0])
            drawLine(ctx: ctx, from: main1, to: main2, color: Color.branchColors[0])
            drawLine(ctx: ctx, from: main1, to: dev1, color: Color.branchColors[1])
            drawNode(ctx: ctx, at: root,  color: Color.branchColors[0], r: r, label: "c1")
            drawNode(ctx: ctx, at: main1, color: Color.branchColors[0], r: r, label: "c2")
            drawNode(ctx: ctx, at: main2, color: Color.branchColors[0], r: r, label: "c3")
            drawNode(ctx: ctx, at: dev1,  color: Color.branchColors[1], r: r, label: "c4")

        case "Merging":
            let c1 = CGPoint(x: cx, y: size.height - 16)
            let c2 = CGPoint(x: cx - 44, y: cy)
            let c3 = CGPoint(x: cx + 44, y: cy)
            let merge = CGPoint(x: cx, y: 20)
            drawLine(ctx: ctx, from: c1, to: c2, color: Color.branchColors[0])
            drawLine(ctx: ctx, from: c1, to: c3, color: Color.branchColors[1])
            drawCurve(ctx: ctx, from: c2, to: merge, color: Color.branchColors[0])
            drawCurve(ctx: ctx, from: c3, to: merge, color: Color.branchColors[1])
            [c1, c2, c3].forEach { drawNode(ctx: ctx, at: $0, color: Color.branchColors[0], r: r, label: "") }
            drawNode(ctx: ctx, at: merge, color: DS.success, r: r, label: "M")

        case "Rebasing":
            let c1 = CGPoint(x: cx - 40, y: size.height - 16)
            let c2 = CGPoint(x: cx - 40, y: cy)
            let c3 = CGPoint(x: cx + 40, y: cy)
            let c4 = CGPoint(x: cx + 40, y: 20)
            drawLine(ctx: ctx, from: c1, to: c2, color: Color.branchColors[0])
            drawLine(ctx: ctx, from: c1, to: c3, color: Color.branchColors[1])
            drawLine(ctx: ctx, from: c3, to: c4, color: Color.branchColors[1].opacity(0.4 + phase * 0.6))
            [c1,c2,c3,c4].forEach { pt in
                drawNode(ctx: ctx, at: pt, color: pt == c4 ? Color.branchColors[1] : Color.branchColors[0], r: r, label: "")
            }

        case "Reset & Revert":
            let pts = [CGPoint(x: cx, y: size.height - 20), CGPoint(x: cx, y: cy + 20), CGPoint(x: cx, y: 25)]
            drawChain(ctx: ctx, pts: pts, color: Color.branchColors[0], r: r, phase: 1)
            // Arrow back
            var arrow = Path()
            arrow.move(to: pts[2])
            arrow.addLine(to: pts[0])
            ctx.stroke(arrow, with: .color(DS.danger.opacity(0.5 + phase * 0.3)),
                       style: StrokeStyle(lineWidth: 1.5, dash: [4]))

        case "Cherry-pick":
            let c1 = CGPoint(x: cx - 44, y: size.height - 16)
            let c2 = CGPoint(x: cx - 44, y: cy)
            let c3 = CGPoint(x: cx + 44, y: cy)
            let c4 = CGPoint(x: cx + 44, y: 20)
            drawLine(ctx: ctx, from: c1, to: c2, color: Color.branchColors[0])
            drawLine(ctx: ctx, from: c1, to: c3, color: Color.branchColors[1])
            // dashed pick arrow
            var pick = Path()
            pick.move(to: c2)
            pick.addLine(to: c4)
            ctx.stroke(pick, with: .color(DS.success.opacity(0.6 + phase * 0.4)),
                       style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [4]))
            [c1,c2,c3].forEach { drawNode(ctx: ctx, at: $0, color: Color.branchColors[0], r: r, label: "") }
            drawNode(ctx: ctx, at: c4, color: DS.success, r: r, label: "✦")

        default:
            let pts = [CGPoint(x: cx, y: size.height-20), CGPoint(x: cx, y: cy), CGPoint(x: cx, y: 20)]
            drawChain(ctx: ctx, pts: pts, color: DS.accent, r: r, phase: phase)
        }
    }

    func drawChain(ctx: GraphicsContext, pts: [CGPoint], color: Color, r: CGFloat, phase: CGFloat) {
        for i in 0..<pts.count - 1 { drawLine(ctx: ctx, from: pts[i], to: pts[i+1], color: color) }
        for (i, pt) in pts.enumerated() { drawNode(ctx: ctx, at: pt, color: color, r: r, label: "c\(i+1)") }
    }

    func drawLine(ctx: GraphicsContext, from: CGPoint, to: CGPoint, color: Color) {
        var p = Path(); p.move(to: from); p.addLine(to: to)
        ctx.stroke(p, with: .color(color.opacity(0.5)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
    }

    func drawCurve(ctx: GraphicsContext, from: CGPoint, to: CGPoint, color: Color) {
        var p = Path()
        p.move(to: from)
        let cp1 = CGPoint(x: from.x, y: (from.y + to.y) / 2)
        let cp2 = CGPoint(x: to.x, y: (from.y + to.y) / 2)
        p.addCurve(to: to, control1: cp1, control2: cp2)
        ctx.stroke(p, with: .color(color.opacity(0.5)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
    }

    func drawNode(ctx: GraphicsContext, at pt: CGPoint, color: Color, r: CGFloat, label: String) {
        let rect = CGRect(x: pt.x - r, y: pt.y - r, width: r*2, height: r*2)
        ctx.fill(Path(ellipseIn: rect), with: .color(color))
        ctx.stroke(Path(ellipseIn: rect), with: .color(.white.opacity(0.25)), lineWidth: 1.5)
    }
}

// MARK: - Lesson Data
struct GitLessonData {
    static let all: [GitLesson] = [
        GitLesson(
            id: "commit",
            title: "What is a Commit?",
            subtitle: "The building block of Git",
            icon: "circle.fill",
            color: Color.branchColors[0],
            explanation: "A commit is a snapshot of your project at a specific point in time. Each commit stores what changed, who changed it, when, and a reference to its parent commit — forming a chain of history.",
            steps: [
                LessonStep(title: "Make changes", detail: "Edit files in your working directory."),
                LessonStep(title: "Stage changes", detail: "Run git add to stage the files you want to include."),
                LessonStep(title: "Commit", detail: "Run git commit -m \"message\" to save the snapshot."),
                LessonStep(title: "History grows", detail: "Your commit is linked to the previous one, building a chain."),
            ],
            operation: .commit(message: "Add feature")
        ),
        GitLesson(
            id: "branch",
            title: "Branches",
            subtitle: "Parallel lines of work",
            icon: "arrow.triangle.branch",
            color: Color.branchColors[1],
            explanation: "A branch is simply a lightweight pointer to a specific commit. Creating a branch lets you work on a feature or fix in isolation without affecting the main codebase. HEAD points to the currently checked-out branch.",
            steps: [
                LessonStep(title: "Start from a commit", detail: "Your current HEAD commit is the branching point."),
                LessonStep(title: "Create a branch", detail: "git branch feature — this creates a pointer."),
                LessonStep(title: "Switch to it", detail: "git checkout feature moves HEAD to the new branch."),
                LessonStep(title: "Work independently", detail: "New commits advance the feature branch, not main."),
            ],
            operation: .branch(name: "feature")
        ),
        GitLesson(
            id: "merge",
            title: "Merging",
            subtitle: "Joining branches together",
            icon: "arrow.triangle.merge",
            color: DS.success,
            explanation: "Merging integrates changes from one branch into another. Git creates a special merge commit that has two parents — one from each branch — preserving the full history of both lines of work.",
            steps: [
                LessonStep(title: "Checkout the target", detail: "Switch to the branch you want to merge INTO."),
                LessonStep(title: "Run git merge", detail: "git merge feature — Git finds the common ancestor."),
                LessonStep(title: "Merge commit", detail: "A new commit is created with two parents, joining both histories."),
                LessonStep(title: "Fast-forward?", detail: "If there's no divergence, Git just moves the pointer forward."),
            ],
            operation: .merge(name: "feature")
        ),
        GitLesson(
            id: "rebase",
            title: "Rebasing",
            subtitle: "Rewriting history cleanly",
            icon: "arrow.up.arrow.down",
            color: DS.warning,
            explanation: "Rebase re-applies your branch's commits on top of another branch, creating a linear history. It's like saying: 'replay my changes as if I had started from this point.' This avoids the merge commit and produces a cleaner log.",
            steps: [
                LessonStep(title: "Checkout your branch", detail: "You want to rebase THIS branch onto main."),
                LessonStep(title: "Run git rebase", detail: "git rebase main — Git finds the common ancestor."),
                LessonStep(title: "Commits are replayed", detail: "Each of your commits is re-applied on top of main."),
                LessonStep(title: "Linear history", detail: "The branch now appears to have started from the tip of main."),
            ],
            operation: .rebase(onto: "main")
        ),
        GitLesson(
            id: "reset",
            title: "Reset & Revert",
            subtitle: "Undoing mistakes",
            icon: "arrow.uturn.backward",
            color: DS.danger,
            explanation: "git reset moves the HEAD (and the branch) backward to a previous commit, effectively erasing commits from the tip. Use --soft to keep changes staged, --mixed to keep them unstaged, or --hard to discard all changes.",
            steps: [
                LessonStep(title: "Identify the target", detail: "Find the commit hash you want to reset to."),
                LessonStep(title: "Run git reset", detail: "git reset --hard <hash> moves HEAD and discards changes."),
                LessonStep(title: "History is rewritten", detail: "Commits after the target are gone from the branch."),
                LessonStep(title: "Caution!", detail: "Never reset commits that have been pushed to a shared remote."),
            ],
            operation: .reset(hash: "abc1234")
        ),
        GitLesson(
            id: "cherry-pick",
            title: "Cherry-pick",
            subtitle: "Picking specific commits",
            icon: "smallcircle.filled.circle",
            color: DS.success,
            explanation: "Cherry-pick lets you apply any single commit from any branch onto your current branch. This is useful when you want just one specific fix or feature without merging the whole branch.",
            steps: [
                LessonStep(title: "Find the commit", detail: "Identify the commit hash you want to copy."),
                LessonStep(title: "Checkout your branch", detail: "Make sure you're on the target branch."),
                LessonStep(title: "Run cherry-pick", detail: "git cherry-pick <hash> — a new commit is created."),
                LessonStep(title: "New hash, same changes", detail: "The new commit has a different hash but the same diff."),
            ],
            operation: .cherryPick(hash: "abc1234")
        ),
    ]
}
