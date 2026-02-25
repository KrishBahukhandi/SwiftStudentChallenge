import SwiftUI

// MARK: - Lesson Playground  (Try it Live)
// Presented as a .sheet from LessonCard.
// Shows: goal banner → mini GraphView → one focused command widget.
struct LessonPlaygroundView: View {
    let lesson: GitLesson
    let onDismiss: @MainActor () -> Void

    @StateObject private var playEngine = GitEngine()
    @State private var selectedCommitId: String? = nil
    @State private var showCommitSheet   = false
    @State private var completed         = false

    // ── Body ─────────────────────────────────────────────────────
    var body: some View {
        ZStack {
            DS.bg0.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                goalBanner
                Divider().background(DS.textMuted.opacity(0.12))

                GeometryReader { geo in
                    if geo.size.width > 600 {
                        // iPad: graph left, command right
                        HStack(spacing: 0) {
                            graphArea
                            Divider().background(DS.textMuted.opacity(0.15))
                            focusedCommandPane
                                .frame(width: 300)
                                .background(DS.bg1)
                        }
                    } else {
                        // iPhone: graph top ~55%, command bottom ~45%
                        VStack(spacing: 0) {
                            graphArea
                                .frame(maxHeight: geo.size.height * 0.52)
                            Divider().background(DS.textMuted.opacity(0.12))
                            focusedCommandPane
                                .frame(maxHeight: geo.size.height * 0.48)
                        }
                    }
                }
            }
        }
        .onAppear { setupEngine() }
        .onChange(of: selectedCommitId, perform: { id in showCommitSheet = (id != nil) })
        .sheet(isPresented: $showCommitSheet, onDismiss: { selectedCommitId = nil }) {
            if let cid = selectedCommitId {
                CommitDetailSheet(commitId: cid, engine: playEngine, selectedCommitId: $selectedCommitId)
                    .preferredColorScheme(.dark)
            }
        }
        // Watch engine state to detect when goal is met
        .onReceive(playEngine.$commandHistory) { _ in checkCompletion() }
        .onReceive(playEngine.$commits)        { _ in checkCompletion() }
        .onReceive(playEngine.$branches)       { _ in checkCompletion() }
    }

    // MARK: - Header bar
    private var headerBar: some View {
        HStack(spacing: 12) {
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(DS.textSecondary)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(DS.bg2))
            }
            .accessibilityLabel("Close")

            VStack(alignment: .leading, spacing: 1) {
                Text("Try it Live")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(DS.textMuted)
                Text(lesson.title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            Spacer()

            // Reset
            Button {
                completed = false
                setupEngine()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Reset")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .foregroundColor(DS.danger)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Capsule().fill(DS.danger.opacity(0.10)))
                .overlay(Capsule().strokeBorder(DS.danger.opacity(0.25), lineWidth: 1))
            }
            .accessibilityLabel("Reset to initial state")
        }
        .padding(.horizontal, 16).padding(.vertical, 11)
        .background(DS.bg1)
    }

    // MARK: - Goal banner
    private var goalBanner: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(completed ? DS.success.opacity(0.15) : lesson.color.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: completed ? "checkmark.circle.fill" : "target")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(completed ? DS.success : lesson.color)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(completed ? "Goal complete! 🎉" : "Your goal")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(completed ? DS.success : DS.textMuted)
                Text(goalHint)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(completed ? DS.success : .white)
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(completed ? DS.success.opacity(0.07) : DS.bg2)
        .animation(DS.springSnappy, value: completed)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Goal: \(goalHint). Status: \(completed ? "Complete" : "Not yet done")")
    }

    // MARK: - Mini graph
    private var graphArea: some View {
        ZStack {
            DS.bg0
            GraphView(engine: playEngine, selectedCommitId: $selectedCommitId)
        }
    }

    // MARK: - Focused command pane (one action only)
    private var focusedCommandPane: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Current branch indicator
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(DS.accentLit)
                        .accessibilityHidden(true)
                    Text(playEngine.headBranchName)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(DS.accentLit)
                    Spacer()
                    Text("\(playEngine.commits.count) commits")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(DS.textMuted)
                }
                .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 10)

                // Error toast
                if let err = playEngine.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(DS.danger)
                            .accessibilityHidden(true)
                        Text(err)
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(DS.danger)
                        Spacer()
                        Button { playEngine.errorMessage = nil } label: {
                            Image(systemName: "xmark").font(.system(size: 11)).foregroundColor(DS.danger.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(DS.danger.opacity(0.08))
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Error: \(err)")
                }

                Divider().background(DS.textMuted.opacity(0.12)).padding(.bottom, 4)

                // The single focused command widget for this lesson
                FocusedCommandWidget(lesson: lesson, engine: playEngine)
                    .padding(.horizontal, 16).padding(.vertical, 14)
            }
        }
        .background(DS.bg1)
        .animation(DS.springSnappy, value: playEngine.errorMessage)
    }

    // MARK: - Goal text
    var goalHint: String {
        switch lesson.id {
        case "commit":      return "Make 2 commits on main"
        case "branch":      return "Create a new branch"
        case "merge":       return "Merge 'feature' into 'main'"
        case "rebase":      return "Rebase 'feature' onto 'main'"
        case "reset":       return "Reset HEAD to an earlier commit"
        case "cherry-pick": return "Cherry-pick a commit from 'feature'"
        default:            return "Try any command below"
        }
    }

    // MARK: - Goal tracking
    func checkCompletion() {
        guard !completed else { return }
        switch lesson.id {
        case "commit":
            let made = playEngine.commandHistory.filter { if case .commit = $0 { return true }; return false }.count
            completed = made >= 2
        case "branch":
            completed = playEngine.branches.count >= 2
        case "merge":
            completed = playEngine.commits.contains { $0.parentIds.count == 2 }
        case "rebase":
            completed = playEngine.commandHistory.contains { if case .rebase = $0 { return true }; return false }
        case "reset":
            completed = playEngine.commandHistory.contains { if case .reset = $0 { return true }; return false }
        case "cherry-pick":
            completed = playEngine.commandHistory.contains { if case .cherryPick = $0 { return true }; return false }
        default: break
        }
    }

    // MARK: - Pre-configure engine per lesson
    func setupEngine() {
        playEngine.resetToDefault()      // main with 3 commits
        switch lesson.id {
        case "merge":
            playEngine.createBranch(name: "feature")
            playEngine.checkout(branchName: "feature")
            playEngine.commit(message: "Add feature work")
            playEngine.checkout(branchName: "main")
        case "rebase":
            playEngine.createBranch(name: "feature")
            playEngine.checkout(branchName: "feature")
            playEngine.commit(message: "Feature: first step")
            playEngine.checkout(branchName: "main")
            playEngine.commit(message: "Main: hotfix")
            playEngine.checkout(branchName: "feature")
        case "reset":
            playEngine.commit(message: "Add logging")
            playEngine.commit(message: "Experimental change")
        case "cherry-pick":
            playEngine.createBranch(name: "feature")
            playEngine.checkout(branchName: "feature")
            playEngine.commit(message: "Bugfix A")
            playEngine.commit(message: "Bugfix B")
            playEngine.checkout(branchName: "main")
        default: break
        }
        playEngine.commandHistory = []
        playEngine.errorMessage   = nil
    }
}

// MARK: - Focused Command Widget
// One clean command widget per lesson — no tab picker, no clutter.
private struct FocusedCommandWidget: View {
    let lesson: GitLesson
    @ObservedObject var engine: GitEngine

    @State private var commitMsg    = ""
    @State private var branchName   = ""
    @State private var tagName      = ""

    private var otherBranches: [Branch] { engine.branches.filter { $0.name != engine.headBranchName } }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            switch lesson.id {

            // ── Commit ──────────────────────────────────────────
            case "commit":
                commandLabel("git commit -m \"...\"", color: DS.accent)
                TextField("Commit message", text: $commitMsg)
                    .gitTextField()
                    .accessibilityLabel("Commit message")
                    .accessibilityHint("Type a message then tap Commit")
                actionRow {
                    Button("Commit") {
                        engine.commit(message: commitMsg)
                        if engine.errorMessage == nil { commitMsg = "" }
                    }
                    .buttonStyle(AccentButtonStyle(color: DS.accent))
                    .disabled(commitMsg.trimmingCharacters(in: .whitespaces).isEmpty)
                    .accessibilityLabel("Commit")
                    .accessibilityHint("Saves a new snapshot on the current branch")
                }

            // ── Branch ──────────────────────────────────────────
            case "branch":
                commandLabel("git branch <name>", color: DS.info)
                HStack(spacing: 8) {
                    TextField("New branch name", text: $branchName)
                        .gitTextField()
                        .accessibilityLabel("Branch name")
                        .accessibilityHint("Type a name then tap Create")
                    Button("Create") {
                        engine.createBranch(name: branchName)
                        if engine.errorMessage == nil { branchName = "" }
                    }
                    .buttonStyle(AccentButtonStyle(color: DS.info))
                    .disabled(branchName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .accessibilityLabel("Create branch")
                }
                if engine.branches.count > 1 {
                    switchBranchRow
                }

            // ── Merge ───────────────────────────────────────────
            case "merge":
                commandLabel("git merge <branch>", color: DS.success)
                branchHint("Switch to main first, then merge feature into it.")
                if engine.headBranchName != "main" {
                    checkoutPill(name: "main", color: Color.branchColors[0])
                } else if otherBranches.isEmpty {
                    infoText("No other branches to merge.")
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Merge into \(engine.headBranchName):")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(DS.textMuted)
                        branchActionPills(color: DS.success) { b in
                            engine.merge(sourceBranchName: b.name)
                        }
                    }
                }

            // ── Rebase ──────────────────────────────────────────
            case "rebase":
                commandLabel("git rebase <target>", color: DS.warning)
                branchHint("You're on 'feature'. Rebase it onto 'main'.")
                if otherBranches.isEmpty {
                    infoText("No other branches to rebase onto.")
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rebase \(engine.headBranchName) onto:")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(DS.textMuted)
                        branchActionPills(color: DS.warning) { b in
                            engine.rebase(onto: b.name)
                        }
                    }
                }

            // ── Reset ───────────────────────────────────────────
            case "reset":
                commandLabel("git reset --hard <commit>", color: DS.danger)
                branchHint("Tap any earlier commit in the graph above to select it, then reset.")
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reset HEAD to:")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(DS.textMuted)
                    // Show last 4 commits as pill targets
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            let allCommits = engine.commits.sorted { $0.row > $1.row }.dropFirst()
                            ForEach(Array(allCommits.prefix(4))) { c in
                                Button {
                                    engine.reset(toCommitId: c.id)
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(c.shortHash)
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .foregroundColor(DS.danger)
                                        Text(c.message)
                                            .font(.system(size: 10, design: .rounded))
                                            .foregroundColor(DS.textMuted)
                                            .lineLimit(1)
                                    }
                                    .padding(.horizontal, 10).padding(.vertical, 7)
                                    .background(RoundedRectangle(cornerRadius: DS.radiusS).fill(DS.danger.opacity(0.08)))
                                    .overlay(RoundedRectangle(cornerRadius: DS.radiusS).strokeBorder(DS.danger.opacity(0.25), lineWidth: 1))
                                }
                                .accessibilityLabel("Reset to \(c.message)")
                            }
                        }
                    }
                }

            // ── Cherry-pick ─────────────────────────────────────
            case "cherry-pick":
                commandLabel("git cherry-pick <hash>", color: DS.success)
                branchHint("You're on 'main'. Pick a commit from 'feature'.")
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pick a commit from 'feature':")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(DS.textMuted)
                    let featureCommits = engine.commits.filter {
                        $0.branchName == "feature" && !$0.message.contains("cherry-picked")
                    }
                    if featureCommits.isEmpty {
                        infoText("No commits on 'feature' to pick.")
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(featureCommits) { c in
                                    Button {
                                        engine.cherryPick(commitId: c.id)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(c.shortHash)
                                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                                .foregroundColor(DS.success)
                                            Text(c.message)
                                                .font(.system(size: 10, design: .rounded))
                                                .foregroundColor(DS.textMuted)
                                                .lineLimit(1)
                                        }
                                        .padding(.horizontal, 10).padding(.vertical, 7)
                                        .background(RoundedRectangle(cornerRadius: DS.radiusS).fill(DS.success.opacity(0.08)))
                                        .overlay(RoundedRectangle(cornerRadius: DS.radiusS).strokeBorder(DS.success.opacity(0.25), lineWidth: 1))
                                    }
                                    .accessibilityLabel("Cherry-pick \(c.message)")
                                }
                            }
                        }
                    }
                }

            default:
                infoText("Experiment freely using the graph above.")
            }
        }
    }

    // MARK: - Helpers
    @ViewBuilder
    private func commandLabel(_ text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "terminal.fill")
                .font(.system(size: 10))
                .foregroundColor(color)
                .accessibilityHidden(true)
            Text(text)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(color)
        }
        .padding(.horizontal, 8).padding(.vertical, 5)
        .background(RoundedRectangle(cornerRadius: 5).fill(color.opacity(0.10)))
    }

    @ViewBuilder
    private func branchHint(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, design: .rounded))
            .foregroundColor(DS.textMuted)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private func infoText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, design: .rounded))
            .foregroundColor(DS.textMuted)
            .padding(.vertical, 8)
    }

    @ViewBuilder
    private func actionRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack { Spacer(); content() }
    }

    @ViewBuilder
    private func checkoutPill(name: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Text("Switch to \(name) first:")
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(DS.textMuted)
            Button {
                engine.checkout(branchName: name)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right").font(.system(size: 9))
                    Text(name).font(.system(size: 12, weight: .semibold, design: .monospaced))
                }
                .foregroundColor(color)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Capsule().fill(color.opacity(0.12)))
                .overlay(Capsule().strokeBorder(color.opacity(0.3), lineWidth: 1))
            }
            .accessibilityLabel("Switch to \(name)")
        }
    }

    @ViewBuilder
    private func branchActionPills(color: Color, action: @escaping (Branch) -> Void) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(otherBranches) { b in
                    Button { action(b) } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.triangle.merge").font(.system(size: 10)).accessibilityHidden(true)
                            Text(b.name).font(.system(size: 12, weight: .semibold, design: .monospaced))
                        }
                        .foregroundColor(color)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Capsule().fill(color.opacity(0.12)))
                        .overlay(Capsule().strokeBorder(color.opacity(0.3), lineWidth: 1))
                    }
                    .accessibilityLabel(b.name)
                }
            }
        }
    }

    @ViewBuilder
    private var switchBranchRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Switch branch:")
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(DS.textMuted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(engine.branches) { b in
                        Button { engine.checkout(branchName: b.name) } label: {
                            HStack(spacing: 4) {
                                if b.name == engine.headBranchName {
                                    Image(systemName: "location.fill").font(.system(size: 9)).accessibilityHidden(true)
                                }
                                Text(b.name).font(.system(size: 11, weight: .semibold, design: .monospaced))
                            }
                            .foregroundColor(b.name == engine.headBranchName ? b.color : DS.textSecondary)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Capsule().fill(b.color.opacity(b.name == engine.headBranchName ? 0.2 : 0.06)))
                            .overlay(Capsule().strokeBorder(b.color.opacity(b.name == engine.headBranchName ? 0.5 : 0.15), lineWidth: 1))
                        }
                        .accessibilityLabel(b.name == engine.headBranchName ? "\(b.name), current" : "Switch to \(b.name)")
                    }
                }
            }
        }
    }
}
