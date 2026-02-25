import SwiftUI

// MARK: - Sandbox View
struct SandboxView: View {
    @EnvironmentObject var engine: GitEngine
    @Binding var showLegend: Bool
    @State private var selectedCommitId: String? = nil
    @State private var showCommitSheet = false
    @State private var showResetConfirm = false
    @State private var showPanel = true

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                DS.bg0.ignoresSafeArea()

                VStack(spacing: 0) {
                    // ── Top bar ──────────────────────────────────
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sandbox")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("Freeplay — experiment freely")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(DS.textMuted)
                        }
                        Spacer()

                        // Legend button
                        Button {
                            showLegend = true
                        } label: {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 18))
                                .foregroundColor(DS.textSecondary)
                                .padding(10)
                                .background(Circle().fill(DS.bg2))
                        }
                        .accessibilityLabel("Show graph legend")
                        .accessibilityHint("Explains what commits, branches, HEAD, and edges mean")

                        // Reset button
                        Button { showResetConfirm = true } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 12, weight: .semibold))
                                    .accessibilityHidden(true)
                                Text("Reset")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(DS.danger)
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(Capsule().fill(DS.danger.opacity(0.12)))
                            .overlay(Capsule().strokeBorder(DS.danger.opacity(0.3), lineWidth: 1))
                        }
                        .accessibilityLabel("Reset repository")
                        .accessibilityHint("Clears all commits, branches, and tags")

                        // Toggle panel
                        Button { withAnimation(DS.springSnappy) { showPanel.toggle() } } label: {
                            Image(systemName: "terminal")
                                .font(.system(size: 16))
                                .foregroundColor(showPanel ? DS.accentLit : DS.textSecondary)
                                .padding(10)
                                .background(Circle().fill(showPanel ? DS.accent.opacity(0.2) : DS.bg2))
                        }
                        .accessibilityLabel(showPanel ? "Hide command panel" : "Show command panel")
                    }
                    .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 8)

                    // ── Stats bar ────────────────────────────────
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            StatBadge(icon: "circle.fill",          value: engine.commits.count,        label: "Commits",  color: DS.accent)
                            StatBadge(icon: "arrow.triangle.branch", value: engine.branches.count,       label: "Branches", color: DS.info)
                            StatBadge(icon: "tag.fill",              value: engine.tags.count,           label: "Tags",     color: DS.warning)
                            StatBadge(icon: "clock",                 value: engine.commandHistory.count, label: "Ops",      color: DS.success)
                        }
                        .padding(.horizontal, 20).padding(.bottom, 10)
                    }

                    Divider().background(DS.textMuted.opacity(0.15))

                    // ── Graph + Panel (adaptive) ─────────────────
                    if geo.size.width > 600 {
                        HStack(spacing: 0) {
                            GraphView(engine: engine, selectedCommitId: $selectedCommitId)
                            if showPanel {
                                Divider().background(DS.textMuted.opacity(0.2))
                                VStack(spacing: 0) {
                                    CommandPanelView(engine: engine)
                                    Spacer()
                                }
                                .frame(width: 320).padding(12).background(DS.bg1)
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                            }
                        }
                    } else {
                        ZStack(alignment: .bottom) {
                            GraphView(engine: engine, selectedCommitId: $selectedCommitId)
                                .padding(.bottom, showPanel ? 320 : 0)
                                .animation(DS.springSmooth, value: showPanel)
                            if showPanel {
                                CommandPanelView(engine: engine)
                                    .frame(maxHeight: 320)
                                    .padding(.horizontal, 8).padding(.bottom, 8)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                    }
                }
                .animation(DS.springSmooth, value: showPanel)
            }
        }
        .onChange(of: selectedCommitId, perform: { newId in
            showCommitSheet = (newId != nil)
        })
        .sheet(isPresented: $showCommitSheet, onDismiss: { selectedCommitId = nil }) {
            if let cid = selectedCommitId {
                CommitDetailSheet(commitId: cid, engine: engine, selectedCommitId: $selectedCommitId)
                    .preferredColorScheme(.dark)
            }
        }
        .alert("Reset Repository?", isPresented: $showResetConfirm) {
            Button("Reset", role: .destructive) {
                withAnimation(DS.springBouncy) { engine.resetToDefault() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will clear all commits, branches, and tags and start fresh.")
        }
    }
}

// MARK: - Stat Badge
struct StatBadge: View {
    let icon: String
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(color)
                .accessibilityHidden(true)
            Text("\(value)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(DS.textMuted)
        }
        .padding(.horizontal, 12).padding(.vertical, 7)
        .glassCard(cornerRadius: DS.radiusM)
        .animation(DS.springSnappy, value: value)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(label)")
    }
}
