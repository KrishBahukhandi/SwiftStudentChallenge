import SwiftUI

// MARK: - Command Panel
struct CommandPanelView: View {
    @ObservedObject var engine: GitEngine
    @State private var selectedTab: CommandTab = .commit
    @State private var commitMessage: String = ""
    @State private var branchName: String = ""
    @State private var tagName: String = ""
    @State private var selectedTargetBranch: String = ""
    @State private var showHistory = false

    enum CommandTab: String, CaseIterable {
        case commit  = "Commit"
        case branch  = "Branch"
        case merge   = "Merge"
        case rebase  = "Rebase"
        case stash   = "Stash"
        case tag     = "Tag"
        case remote  = "Remote"

        var icon: String {
            switch self {
            case .commit:  return "circle.fill"
            case .branch:  return "arrow.triangle.branch"
            case .merge:   return "arrow.triangle.merge"
            case .rebase:  return "arrow.up.arrow.down"
            case .stash:   return "archivebox.fill"
            case .tag:     return "tag.fill"
            case .remote:  return "icloud"
            }
        }
        var color: Color {
            switch self {
            case .commit:  return DS.accent
            case .branch:  return DS.info
            case .merge:   return DS.success
            case .rebase:  return DS.warning
            case .stash:   return DS.info
            case .tag:     return Color(hex: "#EC4899")
            case .remote:  return Color(hex: "#0891B2")
            }
        }
    }

    var otherBranches: [Branch] {
        engine.branches.filter { $0.name != engine.headBranchName }
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ───────────────────────────────────────────────
            HStack(spacing: 10) {
                // Branch indicator
                HStack(spacing: 5) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(DS.accentLit)
                        .accessibilityHidden(true)
                    Text(engine.headBranchName)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(DS.accentLit)
                        .lineLimit(1)
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Capsule().fill(DS.accent.opacity(0.12)).overlay(Capsule().strokeBorder(DS.accent.opacity(0.25), lineWidth: 1)))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Current branch: \(engine.headBranchName)")

                VStack(alignment: .leading, spacing: 1) {
                    Text("\(engine.commits.count) commits · \(engine.branches.count) branches")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(DS.textMuted)
                }
                Spacer()
                Button {
                    withAnimation(DS.springSnappy) { showHistory.toggle() }
                } label: {
                    Image(systemName: showHistory ? "clock.fill" : "clock.arrow.trianglehead.counterclockwise.rotate.90")
                        .font(.system(size: 15))
                        .foregroundColor(showHistory ? DS.accentLit : DS.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(showHistory ? DS.accent.opacity(0.15) : DS.bg3))
                }
                .accessibilityLabel(showHistory ? "Hide command history" : "Show command history")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(DS.bg2)

            // Error message
            if let err = engine.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(DS.danger)
                        .font(.system(size: 12))
                        .accessibilityHidden(true)
                    Text(err)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(DS.danger)
                    Spacer()
                    Button { engine.errorMessage = nil } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DS.danger.opacity(0.7))
                            .font(.system(size: 14))
                    }
                    .accessibilityLabel("Dismiss error")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(DS.danger.opacity(0.1))
                .transition(.move(edge: .top).combined(with: .opacity))
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Error: \(err)")
            }

            if showHistory {
                CommandHistoryView(engine: engine)
                    .transition(.move(edge: .top).combined(with: .opacity))
            } else {

                // ── Tab selector (2-row grid for compact width) ──────
                let allTabs = CommandTab.allCases
                let half = Int(ceil(Double(allTabs.count) / 2.0))
                let row1 = Array(allTabs.prefix(half))
                let row2 = Array(allTabs.suffix(allTabs.count - half))

                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        ForEach(row1, id: \.self) { tab in
                            CommandTabButton(tab: tab, isSelected: selectedTab == tab) {
                                withAnimation(DS.springSnappy) { selectedTab = tab }
                            }
                        }
                    }
                    HStack(spacing: 6) {
                        ForEach(row2, id: \.self) { tab in
                            CommandTabButton(tab: tab, isSelected: selectedTab == tab) {
                                withAnimation(DS.springSnappy) { selectedTab = tab }
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

                Divider().background(DS.textMuted.opacity(0.15))

                // Panel content — wrapped in ScrollView so tall panels (e.g. Remote) are accessible
                ScrollView(showsIndicators: false) {
                    Group {
                        switch selectedTab {
                        case .commit:  commitPanel
                        case .branch:  branchPanel
                        case .merge:   mergePanel
                        case .rebase:  rebasePanel
                        case .stash:   stashPanel
                        case .tag:     tagPanel
                        case .remote:  remotePanel
                        }
                    }
                    .padding(16)
                    .transition(.opacity)
                    .animation(DS.springSnappy, value: selectedTab)
                }
            }
        }
        .glassCard(cornerRadius: DS.radiusL)
    }

    // MARK: - Commit Panel
    var commitPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            CommandLabel(text: "git commit -m \"...\"", color: DS.accent)
                .accessibilityHidden(true)
            TextField("Commit message", text: $commitMessage)
                .gitTextField()
                .accessibilityLabel("Commit message")
                .accessibilityHint("Enter a message, then tap Commit")
            HStack {
                Spacer()
                Button("Commit") {
                    engine.commit(message: commitMessage)
                    if engine.errorMessage == nil { commitMessage = "" }
                }
                .buttonStyle(AccentButtonStyle(color: DS.accent))
                .disabled(commitMessage.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityLabel("Commit")
                .accessibilityHint("Creates a new commit on the current branch with your message")
            }
        }
    }

    // MARK: - Branch Panel
    var branchPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            CommandLabel(text: "git branch <name>  |  git checkout <branch>", color: DS.info)
            HStack(spacing: 8) {
                TextField("New branch name", text: $branchName)
                    .gitTextField()
                    .accessibilityLabel("New branch name")
                    .accessibilityHint("Type a name then tap Create")
                Button("Create") {
                    engine.createBranch(name: branchName)
                    if engine.errorMessage == nil { branchName = "" }
                }
                .buttonStyle(AccentButtonStyle(color: DS.info))
                .disabled(branchName.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityLabel("Create branch")
                .accessibilityHint("Creates a new branch with the typed name from the current HEAD")
            }
            Divider().background(DS.textMuted.opacity(0.2))
            Text("Switch to branch:")
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(DS.textMuted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(engine.branches) { b in
                        Button {
                            engine.checkout(branchName: b.name)
                        } label: {
                            HStack(spacing: 4) {
                                if b.name == engine.headBranchName {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 9))
                                        .accessibilityHidden(true)
                                }
                                Text(b.name)
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            }
                            .foregroundColor(b.name == engine.headBranchName ? b.color : DS.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(b.color.opacity(b.name == engine.headBranchName ? 0.2 : 0.08)))
                            .overlay(Capsule().strokeBorder(b.color.opacity(b.name == engine.headBranchName ? 0.5 : 0.15), lineWidth: 1))
                        }
                        .accessibilityLabel(b.name == engine.headBranchName ? "\(b.name), current branch" : "Switch to \(b.name)")
                        .accessibilityAddTraits(b.name == engine.headBranchName ? [.isButton, .isSelected] : .isButton)
                    }
                }
            }
            if otherBranches.count > 0 {
                Divider().background(DS.textMuted.opacity(0.2))
                HStack {
                    Text("Delete branch:")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(DS.textMuted)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(otherBranches) { b in
                                Button {
                                    engine.deleteBranch(name: b.name)
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 9))
                                            .accessibilityHidden(true)
                                        Text(b.name)
                                            .font(.system(size: 11, design: .monospaced))
                                    }
                                    .foregroundColor(DS.danger.opacity(0.8))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(DS.danger.opacity(0.08)))
                                }
                                .accessibilityLabel("Delete branch \(b.name)")
                                .accessibilityHint("Permanently removes the \(b.name) branch")
                                .accessibilityAddTraits(.isButton)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Merge Panel
    var mergePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            CommandLabel(text: "git merge <branch>", color: DS.success)
            if otherBranches.isEmpty {
                Text("Create another branch first to merge.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(DS.textMuted)
                    .padding(.vertical, 8)
            } else {
                Text("Merge into \(engine.headBranchName):")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(DS.textMuted)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(otherBranches) { b in
                            Button {
                                engine.merge(sourceBranchName: b.name)
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "arrow.triangle.merge")
                                        .font(.system(size: 10))
                                        .accessibilityHidden(true)
                                    Text(b.name)
                                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                }
                                .foregroundColor(b.color)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Capsule().fill(b.color.opacity(0.15)))
                                .overlay(Capsule().strokeBorder(b.color.opacity(0.35), lineWidth: 1))
                            }
                            .accessibilityLabel("Merge \(b.name) into \(engine.headBranchName)")
                            .accessibilityHint("Creates a merge commit combining both branch histories")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Rebase Panel
    var rebasePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            CommandLabel(text: "git rebase <branch>", color: DS.warning)
            if otherBranches.isEmpty {
                Text("Create another branch first to rebase onto.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(DS.textMuted)
                    .padding(.vertical, 8)
            } else {
                Text("Rebase \(engine.headBranchName) onto:")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(DS.textMuted)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(otherBranches) { b in
                            Button {
                                engine.rebase(onto: b.name)
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "arrow.up.arrow.down")
                                        .font(.system(size: 10))
                                        .accessibilityHidden(true)
                                    Text(b.name)
                                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                }
                                .foregroundColor(DS.warning)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Capsule().fill(DS.warning.opacity(0.12)))
                                .overlay(Capsule().strokeBorder(DS.warning.opacity(0.35), lineWidth: 1))
                            }
                            .accessibilityLabel("Rebase \(engine.headBranchName) onto \(b.name)")
                            .accessibilityHint("Re-applies your commits on top of \(b.name), creating a linear history")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Stash Panel
    var stashPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            CommandLabel(text: "git stash  /  git stash pop", color: DS.info)

            if let saved = engine.stashedWork {
                // Show stash entry + pop button
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "archivebox.fill")
                            .font(.system(size: 13))
                            .foregroundColor(DS.info)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("stash@{0}")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(DS.info)
                            Text(saved)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(DS.textMuted)
                                .lineLimit(1)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: DS.radiusS).fill(DS.info.opacity(0.08)))
                    .overlay(RoundedRectangle(cornerRadius: DS.radiusS).strokeBorder(DS.info.opacity(0.2), lineWidth: 1))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Stash entry: \(saved)")

                    HStack {
                        Spacer()
                        Button {
                            engine.stashPop()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "archivebox.circle.fill")
                                    .font(.system(size: 13))
                                Text("git stash pop")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                            }
                        }
                        .buttonStyle(AccentButtonStyle(color: DS.info))
                        .accessibilityLabel("git stash pop — restore stashed work")
                    }
                }
            } else {
                // No stash — show stash button
                Text("No stash entries. Stash shelves your current WIP so you can switch context.")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(DS.textMuted)
                    .lineSpacing(3)

                HStack {
                    Spacer()
                    Button {
                        engine.stash()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "archivebox.fill")
                                .font(.system(size: 13))
                            Text("git stash")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                    }
                    .buttonStyle(AccentButtonStyle(color: DS.info))
                    .accessibilityLabel("git stash — shelve working copy changes")
                }
            }
        }
    }

    // MARK: - Tag Panel
    var tagPanel: some View {
        let tagColor = Color(hex: "#EC4899")
        return VStack(alignment: .leading, spacing: 12) {
            CommandLabel(text: "git tag <name>", color: tagColor)
                .accessibilityHidden(true)
            HStack(spacing: 8) {
                TextField("Tag name (e.g. v1.0.0)", text: $tagName)
                    .gitTextField()
                    .accessibilityLabel("Tag name")
                    .accessibilityHint("Enter a tag name like v1.0.0, then tap Tag")
                Button("Tag") {
                    engine.addTag(name: tagName)
                    if engine.errorMessage == nil { tagName = "" }
                }
                .buttonStyle(AccentButtonStyle(color: tagColor))
                .disabled(tagName.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityLabel("Create tag")
                .accessibilityHint("Tags the current HEAD commit with your tag name")
            }
        }
    }

    // MARK: - Remote Panel
    var remotePanel: some View {
        let remoteColor = Color(hex: "#0891B2")
        let ahead = engine.computeAhead()
        let behind = engine.remoteBehind
        let branch = engine.headBranchName
        let remote = engine.remoteName

        return VStack(alignment: .leading, spacing: 14) {
            CommandLabel(text: "git fetch / push / pull", color: remoteColor)

            // ── Remote status banner ──────────────────────────────────
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "icloud")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(remoteColor)
                        .accessibilityHidden(true)
                    Text("\(remote)/\(branch)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(remoteColor)
                    Spacer()
                    if !engine.hasFetched {
                        Text("Run git fetch first")
                            .font(.system(size: 10, design: .rounded))
                            .foregroundColor(DS.textMuted)
                    }
                }

                HStack(spacing: 12) {
                    // Ahead pill
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 9, weight: .bold))
                        Text("\(ahead) ahead")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(ahead > 0 ? DS.warning : DS.textMuted)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill((ahead > 0 ? DS.warning : DS.textMuted).opacity(0.1)))
                    .accessibilityLabel("\(ahead) commits ahead of remote")

                    // Behind pill
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 9, weight: .bold))
                        Text("\(behind) behind")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(behind > 0 ? DS.info : DS.textMuted)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill((behind > 0 ? DS.info : DS.textMuted).opacity(0.1)))
                    .accessibilityLabel("\(behind) commits behind remote")
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: DS.radiusM).fill(remoteColor.opacity(0.07)))
            .overlay(RoundedRectangle(cornerRadius: DS.radiusM).strokeBorder(remoteColor.opacity(0.2), lineWidth: 1))

            // ── Action buttons ────────────────────────────────────────
            VStack(spacing: 8) {
                // git fetch
                Button {
                    engine.fetch()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.to.line")
                            .font(.system(size: 13))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("git fetch \(remote)")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                            Text("Download remote history without merging")
                                .font(.system(size: 10, design: .rounded))
                                .opacity(0.7)
                        }
                        Spacer()
                    }
                }
                .buttonStyle(RemoteActionButtonStyle(color: remoteColor))
                .accessibilityLabel("git fetch — download remote changes")

                // git push
                Button {
                    engine.push()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "icloud.and.arrow.up")
                            .font(.system(size: 13))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("git push \(remote) \(branch)")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                            Text("Upload local commits to the remote")
                                .font(.system(size: 10, design: .rounded))
                                .opacity(0.7)
                        }
                        Spacer()
                        if ahead > 0 {
                            Text("\(ahead)↑")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(DS.warning)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Capsule().fill(DS.warning.opacity(0.15)))
                        }
                    }
                }
                .buttonStyle(RemoteActionButtonStyle(color: DS.success))
                .accessibilityLabel("git push — upload local commits to remote")
                .accessibilityHint("\(ahead) commits will be pushed")

                // git pull
                Button {
                    engine.pull()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "icloud.and.arrow.down")
                            .font(.system(size: 13))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("git pull \(remote) \(branch)")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                            Text("Fetch + merge remote changes into HEAD")
                                .font(.system(size: 10, design: .rounded))
                                .opacity(0.7)
                        }
                        Spacer()
                        if behind > 0 {
                            Text("\(behind)↓")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(DS.info)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Capsule().fill(DS.info.opacity(0.15)))
                        }
                    }
                }
                .buttonStyle(RemoteActionButtonStyle(color: DS.info))
                .accessibilityLabel("git pull — download and merge remote commits")
                .accessibilityHint("\(behind) remote commits will be merged in")
            }
        }
    }
}

// MARK: - Command Tab Button
private struct CommandTabButton: View {
    let tab: CommandPanelView.CommandTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(tab.rawValue)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .lineLimit(1)
            }
            .foregroundColor(isSelected ? .white : DS.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DS.radiusS, style: .continuous)
                    .fill(isSelected ? tab.color : DS.bg3)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.radiusS, style: .continuous)
                            .strokeBorder(isSelected ? tab.color.opacity(0.0) : DS.textMuted.opacity(0.12), lineWidth: 1)
                    )
            )
        }
        .accessibilityLabel(tab.rawValue)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Remote Action Button Style
struct RemoteActionButtonStyle: ButtonStyle {
    let color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? color.opacity(0.7) : color)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DS.radiusM, style: .continuous)
                    .fill(color.opacity(configuration.isPressed ? 0.18 : 0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.radiusM, style: .continuous)
                    .strokeBorder(color.opacity(0.25), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Command Label
struct CommandLabel: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 5).fill(color.opacity(0.1)))
    }
}

// MARK: - Command History
struct CommandHistoryView: View {
    @ObservedObject var engine: GitEngine
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Command History")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(DS.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            ScrollView {
                VStack(spacing: 4) {
                    ForEach(Array(engine.commandHistory.enumerated()), id: \.offset) { i, op in
                        HStack(spacing: 8) {
                            Image(systemName: op.icon)
                                .font(.system(size: 10))
                                .foregroundColor(i == 0 ? DS.accentLit : DS.textMuted)
                                .frame(width: 14)
                                .accessibilityHidden(true)
                            Text(op.description)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(i == 0 ? .primary : DS.textSecondary)
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(i == 0 ? DS.accent.opacity(0.08) : Color.clear)
                        .cornerRadius(DS.radiusS)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(i == 0 ? "Most recent: \(op.description)" : op.description)
                    }
                }
                .padding(.horizontal, 8)
            }
            .frame(maxHeight: 180)
            .padding(.bottom, 8)
        }
    }
}

// MARK: - TextField Modifier
extension View {
    func gitTextField() -> some View {
        self
            .font(.system(size: 14, design: .monospaced))
            .foregroundColor(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: DS.radiusS, style: .continuous)
                    .fill(DS.bg3)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.radiusS, style: .continuous)
                            .strokeBorder(DS.accent.opacity(0.35), lineWidth: 1)
                    )
            )
    }
}
