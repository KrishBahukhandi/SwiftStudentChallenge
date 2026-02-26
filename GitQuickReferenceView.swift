import SwiftUI

// MARK: - Git Quick Reference
// A cheat sheet of all Git commands covered in the app.
struct GitQuickReferenceView: View {
    let onDismiss: () -> Void

    private let sections: [RefSection] = [
        RefSection(title: "Snapshots", icon: "circle.fill", color: Color(hex: "#7C3AED"), commands: [
            RefCmd("git commit -m \"msg\"",  "Save a snapshot of staged changes"),
            RefCmd("git commit --amend",     "Edit the last commit message / add files to it"),
            RefCmd("git log --oneline",      "Show condensed history of commits"),
            RefCmd("git diff",               "Show unstaged changes in the working tree"),
            RefCmd("git status",             "View current branch state and changed files"),
        ]),
        RefSection(title: "Branches", icon: "arrow.triangle.branch", color: Color(hex: "#2563EB"), commands: [
            RefCmd("git branch <name>",      "Create a new branch from current HEAD"),
            RefCmd("git checkout <branch>",  "Switch to an existing branch"),
            RefCmd("git checkout -b <name>", "Create AND switch to a new branch in one step"),
            RefCmd("git branch -d <name>",   "Delete a merged branch"),
            RefCmd("git branch -D <name>",   "Force-delete an unmerged branch"),
        ]),
        RefSection(title: "Merging", icon: "arrow.triangle.merge", color: Color(hex: "#059669"), commands: [
            RefCmd("git merge <branch>",     "Merge branch into current, creating a merge commit"),
            RefCmd("git merge --squash",     "Squash all branch commits into a single staged diff"),
            RefCmd("git merge --abort",      "Cancel a merge that has conflicts"),
        ]),
        RefSection(title: "Rebasing", icon: "arrow.up.arrow.down", color: Color(hex: "#D97706"), commands: [
            RefCmd("git rebase <branch>",    "Re-apply commits on top of another branch"),
            RefCmd("git rebase -i HEAD~3",   "Interactive rebase — squash, reword, or drop commits"),
            RefCmd("git rebase --abort",     "Cancel an in-progress rebase"),
            RefCmd("git rebase --continue",  "Continue rebase after resolving conflicts"),
        ]),
        RefSection(title: "Undoing", icon: "arrow.uturn.backward", color: Color(hex: "#DC2626"), commands: [
            RefCmd("git reset --soft HEAD~1","Undo last commit, keep changes staged"),
            RefCmd("git reset --mixed HEAD~1","Undo last commit, keep changes unstaged"),
            RefCmd("git reset --hard HEAD~1","Undo last commit and discard all changes"),
            RefCmd("git revert <hash>",      "Create a new commit that undoes a previous commit"),
        ]),
        RefSection(title: "Cherry-pick", icon: "smallcircle.filled.circle", color: Color(hex: "#059669"), commands: [
            RefCmd("git cherry-pick <hash>", "Apply a single commit's changes to current branch"),
            RefCmd("git cherry-pick --no-commit","Stage cherry-pick changes without committing"),
        ]),
        RefSection(title: "Stash", icon: "archivebox.fill", color: Color(hex: "#3B82F6"), commands: [
            RefCmd("git stash",              "Shelve current uncommitted changes"),
            RefCmd("git stash pop",          "Restore the most recent stash as a new commit"),
            RefCmd("git stash list",         "Show all saved stash entries"),
            RefCmd("git stash drop",         "Delete a stash entry without restoring it"),
        ]),
        RefSection(title: "Tags", icon: "tag.fill", color: Color(hex: "#EC4899"), commands: [
            RefCmd("git tag v1.0.0",         "Create a lightweight tag at current HEAD"),
            RefCmd("git tag -a v1.0.0 -m \"\"","Create an annotated tag (preferred for releases)"),
            RefCmd("git push origin v1.0.0", "Push a tag to the remote repository"),
        ]),
    ]

    var body: some View {
        ZStack {
            DS.bg0.ignoresSafeArea()
            RadialGradient(
                colors: [DS.info.opacity(0.12), DS.bg0],
                center: .top, startRadius: 0, endRadius: 400
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Git Cheat Sheet")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("Quick reference for every command in the app")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(DS.textMuted)
                    }
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(DS.textSecondary)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(DS.bg2))
                    }
                    .accessibilityLabel("Close cheat sheet")
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 14)

                Divider().background(DS.textMuted.opacity(0.12))

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        ForEach(sections) { section in
                            RefSectionView(section: section)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                    .padding(.bottom, 24)
                }
            }
        }
    }
}

// MARK: - Section View
private struct RefSectionView: View {
    let section: RefSection

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: section.icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(section.color)
                    .accessibilityHidden(true)
                Text(section.title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(section.color)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(section.color.opacity(0.08))
            .overlay(alignment: .bottom) {
                Divider().background(section.color.opacity(0.15))
            }

            // Commands
            ForEach(Array(section.commands.enumerated()), id: \.offset) { i, cmd in
                VStack(alignment: .leading, spacing: 4) {
                    Text(cmd.command)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(.primary)
                    Text(cmd.description)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(DS.textMuted)
                        .lineSpacing(2)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(i % 2 == 0 ? DS.bg1 : DS.bg0)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(cmd.command): \(cmd.description)")
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: DS.radiusM, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.radiusM, style: .continuous)
                .strokeBorder(section.color.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Data Models
private struct RefSection: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let commands: [RefCmd]
}

private struct RefCmd {
    let command: String
    let description: String
    init(_ cmd: String, _ desc: String) {
        command = cmd; description = desc
    }
}
