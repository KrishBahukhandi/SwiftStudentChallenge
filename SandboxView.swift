import SwiftUI

// MARK: - Sandbox View
struct SandboxView: View {
    @EnvironmentObject var engine: GitEngine
    @Binding var showLegend: Bool
    @State private var selectedCommitId: String? = nil
    @State private var showCommitSheet = false
    @State private var showResetConfirm = false
    @State private var showPanel = true
    @State private var showLog      = false
    @State private var showQuickRef = false
    @State private var showTour     = false
    @AppStorage("hasSeenSandboxTour") private var hasSeenSandboxTour = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                DS.bg0.ignoresSafeArea()

                VStack(spacing: 0) {
                    // ── Top bar ──────────────────────────────────
                    VStack(spacing: 10) {
                        HStack(alignment: .center, spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sandbox")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                Text("Freeplay — experiment freely")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(DS.textMuted)
                            }
                            .layoutPriority(1)

                            Spacer()

                            // Icon action buttons group
                            HStack(spacing: 6) {
                                // Legend button
                                TopBarIconButton(icon: "questionmark.circle", isActive: false, activeColor: DS.info) {
                                    showLegend = true
                                }
                                .accessibilityLabel("Show graph legend")

                                // Log button
                                TopBarIconButton(icon: "clock.arrow.2.circlepath", isActive: showLog, activeColor: DS.info) {
                                    withAnimation(DS.springSnappy) { showLog.toggle() }
                                }
                                .accessibilityLabel(showLog ? "Hide terminal log" : "Show terminal log")

                                // Quick reference
                                TopBarIconButton(icon: "book.pages", isActive: false, activeColor: DS.accent) {
                                    showQuickRef = true
                                }
                                .accessibilityLabel("Git cheat sheet")

                                // Toggle command panel
                                TopBarIconButton(icon: "terminal", isActive: showPanel, activeColor: DS.accent) {
                                    withAnimation(DS.springSnappy) { showPanel.toggle() }
                                }
                                .accessibilityLabel(showPanel ? "Hide command panel" : "Show command panel")

                                // Reset button
                                Button { showResetConfirm = true } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.counterclockwise")
                                            .font(.system(size: 10, weight: .bold))
                                            .accessibilityHidden(true)
                                        Text("Reset")
                                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    }
                                    .foregroundColor(DS.danger)
                                    .padding(.horizontal, 11).padding(.vertical, 7)
                                    .background(
                                        Capsule()
                                            .fill(DS.danger.opacity(0.10))
                                            .overlay(Capsule().strokeBorder(DS.danger.opacity(0.35), lineWidth: 1))
                                    )
                                }
                                .accessibilityLabel("Reset repository")
                            }
                        }

                        // ── Stats bar ────────────────────────────────
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                StatBadge(icon: "circle.fill",           value: engine.commits.count,        label: "Commits",  color: DS.accent)
                                StatBadge(icon: "arrow.triangle.branch", value: engine.branches.count,       label: "Branches", color: DS.info)
                                StatBadge(icon: "tag.fill",              value: engine.tags.count,           label: "Tags",     color: DS.warning)
                                StatBadge(icon: "clock",                 value: engine.commandHistory.count, label: "Ops",      color: DS.success)
                                if engine.stashedWork != nil {
                                    StatBadge(icon: "archivebox.fill", value: 1, label: "Stashed", color: DS.info)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .animation(DS.springSnappy, value: engine.stashedWork != nil)
                        }
                    }
                    .padding(.horizontal, 18).padding(.top, 14).padding(.bottom, 10)

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

                // ── Terminal log overlay ──────────────────────────────
                if showLog {
                    TerminalLogPanel(history: engine.commandHistory) {
                        withAnimation(DS.springSnappy) { showLog = false }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // ── First-run guided tour ────────────────────────
                if showTour {
                    TourOverlay(isVisible: $showTour)
                        .transition(.opacity)
                        .zIndex(999)
                }
            }
        }
        .onAppear {
            if !hasSeenSandboxTour {
                // Brief delay so the graph has time to render before the overlay appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(DS.springSmooth) { showTour = true }
                }
                hasSeenSandboxTour = true
            }
        }
        .onChange(of: selectedCommitId, perform: { newId in
            showCommitSheet = (newId != nil)
        })
        .sheet(isPresented: $showCommitSheet, onDismiss: { selectedCommitId = nil }) {
            if let cid = selectedCommitId {
                CommitDetailSheet(commitId: cid, engine: engine, selectedCommitId: $selectedCommitId)
            }
        }
        .sheet(isPresented: $showQuickRef) {
            GitQuickReferenceView { showQuickRef = false }
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

// MARK: - Top Bar Icon Button
private struct TopBarIconButton: View {
    let icon: String
    let isActive: Bool
    let activeColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isActive ? activeColor : DS.textSecondary)
                .frame(width: 34, height: 34)
                .background(
                    Circle()
                        .fill(isActive ? activeColor.opacity(0.15) : DS.bg2)
                        .overlay(Circle().strokeBorder(isActive ? activeColor.opacity(0.3) : Color.clear, lineWidth: 1))
                )
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
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(color)
                .accessibilityHidden(true)
            Text("\(value)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(DS.textMuted)
        }
        .padding(.horizontal, 11).padding(.vertical, 6)
        .background(
            Capsule()
                .fill(DS.bg1)
                .overlay(Capsule().strokeBorder(color.opacity(0.25), lineWidth: 1))
        )
        .animation(DS.springSnappy, value: value)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(label)")
    }
}

// MARK: - Terminal Log Panel
struct TerminalLogPanel: View {
    let history: [GitOperation]
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Handle / header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "terminal.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(DS.info)
                        .accessibilityHidden(true)
                    Text("Terminal Log")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    if !history.isEmpty {
                        Text("\(history.count)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(DS.info)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(DS.info.opacity(0.15)))
                    }
                }
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(DS.textMuted)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(DS.bg2))
                }
                .accessibilityLabel("Close log")
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider().background(DS.textMuted.opacity(0.12))

            if history.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "terminal")
                        .font(.system(size: 28))
                        .foregroundColor(DS.textMuted.opacity(0.4))
                        .accessibilityHidden(true)
                    Text("No commands yet. Run something!")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(DS.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(history.enumerated()), id: \.offset) { idx, op in
                            TerminalLogRow(op: op, index: history.count - idx)
                            if idx < history.count - 1 {
                                Divider().background(DS.textMuted.opacity(0.08))
                            }
                        }
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: DS.radiusL, style: .continuous)
                .fill(DS.bg1)
                .shadow(color: .black.opacity(0.4), radius: 20, y: -4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.radiusL, style: .continuous)
                .strokeBorder(DS.info.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
        .frame(maxHeight: 280)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Single Log Row
private struct TerminalLogRow: View {
    let op: GitOperation
    let index: Int

    private var opColor: Color {
        switch op {
        case .commit:      return DS.accent
        case .branch:      return DS.info
        case .checkout:    return DS.textSecondary
        case .merge:       return DS.success
        case .rebase:      return DS.warning
        case .reset:       return DS.danger
        case .cherryPick:  return DS.success
        case .tag:         return DS.warning
        case .deleteBranch:return DS.danger
        case .stash:       return DS.info
        case .stashPop:    return DS.info
        case .fetch:       return Color(hex: "#0891B2")
        case .push:        return DS.success
        case .pull:        return Color(hex: "#0891B2")
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            // Line number
            Text(String(format: "%02d", index))
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(DS.textMuted.opacity(0.5))
                .frame(width: 22, alignment: .trailing)
                .accessibilityHidden(true)

            // Op icon
            Image(systemName: op.icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(opColor)
                .frame(width: 16)
                .accessibilityHidden(true)

            // Command
            Text(op.description)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.primary.opacity(0.85))
                .lineLimit(1)

            Spacer()

            // Coloured dot
            Circle()
                .fill(opColor.opacity(0.6))
                .frame(width: 5, height: 5)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(op.description)
    }
}

