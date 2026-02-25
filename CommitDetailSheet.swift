import SwiftUI

// MARK: - Commit Detail Sheet
struct CommitDetailSheet: View {
    let commitId: String
    @ObservedObject var engine: GitEngine
    @Binding var selectedCommitId: String?
    @State private var showCherryPickConfirm = false

    private var commit: CommitNode? { engine.commits.first(where: { $0.id == commitId }) }
    private var color: Color { commit.map { engine.color(for: $0) } ?? DS.accent }
    private var branches: [Branch] { engine.branches(for: commitId) }
    private var tags: [GitTag] { engine.tags(for: commitId) }
    private var parents: [CommitNode] {
        commit?.parentIds.compactMap { pid in engine.commits.first(where: { $0.id == pid }) } ?? []
    }
    private var isHead: Bool { engine.isHead(commitId) }

    var body: some View {
        NavigationView {
            ZStack {
                DS.bg0.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(color.opacity(0.2))
                                    .frame(width: 72, height: 72)
                                Circle()
                                    .fill(color)
                                    .frame(width: 52, height: 52)
                                    .shadow(color: color.opacity(0.5), radius: 12)
                                if commit?.parentIds.count ?? 0 > 1 {
                                    Image(systemName: "arrow.triangle.merge")
                                        .foregroundColor(.white)
                                        .font(.system(size: 18, weight: .semibold))
                                } else {
                                    Image(systemName: "circle.fill")
                                        .foregroundColor(.white.opacity(0.5))
                                        .font(.system(size: 10))
                                }
                            }
                            .accessibilityHidden(true)

                            Text(commit?.message ?? "")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .accessibilityLabel("Commit message: \(commit?.message ?? "")")

                            Text(commit?.shortHash ?? "")
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundColor(DS.textMuted)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(DS.bg2))
                                .accessibilityLabel("Commit hash: \(commit?.shortHash ?? "")")
                        }
                        .padding(.top, 8)

                        // Badges
                        if isHead || !branches.isEmpty || !tags.isEmpty {
                            HStack(spacing: 8) {
                                if isHead {
                                    HStack(spacing: 4) {
                                        Image(systemName: "location.fill")
                                            .font(.system(size: 10))
                                        Text("HEAD")
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    }
                                    .foregroundColor(DS.accentLit)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Capsule().fill(DS.accent.opacity(0.2)))
                                }
                                ForEach(branches) { b in
                                    Text(b.name)
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                        .foregroundColor(b.color)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Capsule().fill(b.color.opacity(0.15)))
                                }
                                ForEach(tags) { t in
                                    HStack(spacing: 4) {
                                        Image(systemName: "tag.fill")
                                            .font(.system(size: 9))
                                        Text(t.name)
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                    .foregroundColor(DS.warning)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Capsule().fill(DS.warning.opacity(0.15)))
                                }
                            }
                        }

                        // Info card
                        VStack(spacing: 0) {
                            DetailRow(icon: "person.fill", label: "Author", value: "You")
                            Divider().background(DS.textMuted.opacity(0.2))
                            DetailRow(icon: "clock.fill", label: "Date",
                                      value: commit.map { formattedDate($0.timestamp) } ?? "")
                            Divider().background(DS.textMuted.opacity(0.2))
                            DetailRow(icon: "arrow.triangle.branch", label: "Branch",
                                      value: commit?.branchName ?? "")
                            if !parents.isEmpty {
                                Divider().background(DS.textMuted.opacity(0.2))
                                DetailRow(icon: "arrow.up.circle.fill", label: "Parents",
                                          value: parents.map { String($0.shortHash.prefix(7)) }.joined(separator: ", "))
                            }
                        }
                        .glassCard()
                        .padding(.horizontal, 16)

                        // Actions
                        VStack(spacing: 12) {
                            if !isHead {
                                Button {
                                    engine.reset(toCommitId: commitId)
                                    selectedCommitId = nil
                                } label: {
                                    HStack {
                                        Image(systemName: "arrow.uturn.backward")
                                        Text("Reset HEAD here")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(GhostButtonStyle(color: DS.warning))
                                .accessibilityLabel("Reset HEAD to this commit")
                                .accessibilityHint("Moves the current branch pointer back to \(commit?.message ?? "this commit")")

                                Button {
                                    showCherryPickConfirm = true
                                } label: {
                                    HStack {
                                        Image(systemName: "smallcircle.filled.circle")
                                        Text("Cherry-pick to current branch")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(GhostButtonStyle(color: DS.success))
                                .accessibilityLabel("Cherry-pick to \(engine.headBranchName)")
                                .accessibilityHint("Copies this commit's changes onto the current branch")
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Commit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { selectedCommitId = nil }
                        .foregroundColor(DS.accentLit)
                        .accessibilityLabel("Dismiss commit details")
                }
            }
        }
        .preferredColorScheme(.dark)
        .alert("Cherry-pick this commit?", isPresented: $showCherryPickConfirm) {
            Button("Cherry-pick") {
                engine.cherryPick(commitId: commitId)
                selectedCommitId = nil
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("A copy of '\(commit?.message ?? "")' will be applied to the current branch.")
        }
    }

    func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(DS.textMuted)
                .frame(width: 20)
                .accessibilityHidden(true)
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(DS.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }
}
