import SwiftUI

// MARK: - Graph View (Canvas-based DAG renderer)
struct GraphView: View {
    @ObservedObject var engine: GitEngine
    @Binding var selectedCommitId: String?
    var showAllBranchLabels: Bool = true



    var body: some View {
        GeometryReader { geo in
            let canvasW = max(engine.graphWidth + 80, geo.size.width)
            let canvasH = max(engine.graphHeight + 80, geo.size.height)

            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    // Canvas layer - edges (decorative, hidden from VoiceOver)
                    Canvas { ctx, size in
                        drawEdges(ctx: ctx, size: size)
                    }
                    .frame(width: canvasW, height: canvasH)
                    .accessibilityHidden(true)

                    // Nodes layer (SwiftUI views for tap targets + animations)
                    ForEach(engine.commits) { commit in
                        let pos = engine.position(for: commit, canvasWidth: canvasW)
                        let isHead = engine.isHead(commit.id)
                        let branchesOnCommit = engine.branches(for: commit.id)
                        let tagsOnCommit = engine.tags(for: commit.id)
                        CommitNodeView(
                            commit: commit,
                            engine: engine,
                            isSelected: selectedCommitId == commit.id,
                            isNew: engine.newlyAddedCommitId == commit.id
                        )
                        .position(pos)
                        .onTapGesture {
                            withAnimation(DS.springSnappy) {
                                selectedCommitId = (selectedCommitId == commit.id) ? nil : commit.id
                            }
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(accessibilityLabel(for: commit, isHead: isHead, branches: branchesOnCommit, tags: tagsOnCommit))
                        .accessibilityHint("Double tap to view commit details")
                        .accessibilityAddTraits(.isButton)
                    }

                    // Branch labels
                    ForEach(engine.branches) { branch in
                        if let headCommit = engine.commits.first(where: { $0.id == branch.headCommitId }) {
                            let pos = engine.position(for: headCommit, canvasWidth: canvasW)
                            let isActive = branch.name == engine.headBranchName
                            BranchLabel(branch: branch, isActive: isActive)
                                .position(x: pos.x + DS.laneWidth * 0.5 + 50, y: pos.y)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.6).combined(with: .opacity),
                                    removal: .opacity
                                ))
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel(isActive ? "Current branch: \(branch.name)" : "Branch: \(branch.name)")
                                .accessibilityHidden(!isActive) // only surface active branch to reduce noise
                        }
                    }

                    // Remote-tracking labels (origin/<branch>)
                    ForEach(engine.branches) { branch in
                        if let remoteCommitId = engine.remoteBranches[branch.name],
                           let remoteCommit = engine.commits.first(where: { $0.id == remoteCommitId }) {
                            let pos = engine.position(for: remoteCommit, canvasWidth: canvasW)
                            RemoteTrackingLabel(remoteName: engine.remoteName, branchName: branch.name, color: branch.color)
                                .position(x: pos.x + DS.laneWidth * 0.5 + 50,
                                          y: pos.y + (engine.branches(for: remoteCommitId).isEmpty ? 0 : 24))
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.6).combined(with: .opacity),
                                    removal: .opacity
                                ))
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel("Remote tracking: \(engine.remoteName)/\(branch.name)")
                        }
                    }

                    // Tag labels
                    ForEach(engine.tags) { tag in
                        if let taggedCommit = engine.commits.first(where: { $0.id == tag.commitId }) {
                            let pos = engine.position(for: taggedCommit, canvasWidth: canvasW)
                            TagLabel(tag: tag)
                                .position(x: pos.x, y: pos.y - DS.nodeSize - 14)
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel("Tag: \(tag.name)")
                        }
                    }
                }
                .frame(width: canvasW, height: canvasH)
                .animation(DS.springBouncy, value: engine.commits.count)
                .animation(DS.springBouncy, value: engine.branches.count)
            }
            .accessibilityLabel("Git commit graph. \(engine.commits.count) commits across \(engine.branches.count) branches.")
            .background(DS.bg0)
        }
    }

    // MARK: - Accessibility label builder
    func accessibilityLabel(for commit: CommitNode, isHead: Bool, branches: [Branch], tags: [GitTag]) -> String {
        var parts: [String] = []
        if isHead { parts.append("HEAD") }
        if !branches.isEmpty {
            parts.append("Branch pointer: \(branches.map { $0.name }.joined(separator: ", "))")
        }
        parts.append("Commit: \(commit.message)")
        parts.append("Hash: \(commit.shortHash.prefix(7))")
        if commit.parentIds.count > 1 { parts.append("Merge commit with \(commit.parentIds.count) parents") }
        if !tags.isEmpty { parts.append("Tagged: \(tags.map { $0.name }.joined(separator: ", "))") }
        return parts.joined(separator: ". ")
    }

    // MARK: - Edge Drawing
    func drawEdges(ctx: GraphicsContext, size: CGSize) {
        let canvasW = size.width

        for commit in engine.commits {
            let to = engine.position(for: commit, canvasWidth: canvasW)

            for parentId in commit.parentIds {
                guard let parent = engine.commits.first(where: { $0.id == parentId }) else { continue }
                let from = engine.position(for: parent, canvasWidth: canvasW)

                let isMerge = commit.parentIds.count > 1
                let color = isMerge ? DS.textMuted.opacity(0.5) : engine.color(for: parent).opacity(0.55)

                var path = Path()
                path.move(to: from)

                if from.x == to.x {
                    // Same lane — straight line
                    path.addLine(to: to)
                } else {
                    // Different lane — cubic bezier
                    let cp1 = CGPoint(x: from.x, y: (from.y + to.y) * 0.6)
                    let cp2 = CGPoint(x: to.x,   y: (from.y + to.y) * 0.4)
                    path.addCurve(to: to, control1: cp1, control2: cp2)
                }

                ctx.stroke(
                    path,
                    with: .color(color),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
            }
        }
    }
}

// MARK: - Commit Node View
struct CommitNodeView: View {
    let commit: CommitNode
    @ObservedObject var engine: GitEngine
    let isSelected: Bool
    let isNew: Bool

    @State private var appeared = false
    @State private var pulseScale: CGFloat = 1.0

    private var color: Color { engine.color(for: commit) }
    private var isHead: Bool { engine.isHead(commit.id) }

    var body: some View {
        ZStack {
            // Glow ring for HEAD
            if isHead {
                Circle()
                    .fill(color.opacity(0.25))
                    .frame(width: DS.nodeSize * 2.4, height: DS.nodeSize * 2.4)
                    .scaleEffect(pulseScale)
                    .animation(
                        .easeInOut(duration: 1.4).repeatForever(autoreverses: true),
                        value: pulseScale
                    )
            }

            // Selection ring
            if isSelected {
                Circle()
                    .strokeBorder(Color.white.opacity(0.6), lineWidth: 2)
                    .frame(width: DS.nodeSize * 2 + 8, height: DS.nodeSize * 2 + 8)
            }

            // Merge indicator (two parents)
            if commit.parentIds.count > 1 {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [color.opacity(0.9), color.opacity(0.5)],
                            center: .center,
                            startRadius: 0,
                            endRadius: DS.nodeSize
                        )
                    )
                    .frame(width: DS.nodeSize * 2, height: DS.nodeSize * 2)
                    .overlay(
                        Image(systemName: "arrow.triangle.merge")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .overlay(Circle().strokeBorder(.white.opacity(0.25), lineWidth: 1.5))
            } else {
                // Regular commit
                Circle()
                    .fill(color)
                    .frame(width: DS.nodeSize * 2, height: DS.nodeSize * 2)
                    .overlay(
                        Circle()
                            .fill(.white.opacity(isHead ? 0.25 : 0.10))
                    )
                    .overlay(Circle().strokeBorder(.white.opacity(0.25), lineWidth: 1.5))
            }

            // Hash label below
            Text(commit.shortHash.prefix(5))
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.55))
                .offset(y: DS.nodeSize + 12)
        }
        .scaleEffect(appeared ? 1 : 0.1)
        .opacity(appeared ? 1 : 0)
        .shadow(color: color.opacity(0.5), radius: isHead ? 12 : 4)
        .onAppear {
            withAnimation(DS.springBouncy) {
                appeared = true
            }
            if isHead {
                pulseScale = 1.25
            }
        }
        .onChange(of: isHead, perform: { newVal in
            if newVal { pulseScale = 1.25 }
        })
    }
}

// MARK: - Branch Label
struct BranchLabel: View {
    let branch: Branch
    let isActive: Bool

    var body: some View {
        HStack(spacing: 5) {
            if isActive {
                Image(systemName: "location.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(branch.color)
            }
            Text(branch.name)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(isActive ? .white : DS.textSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(isActive ? branch.color.opacity(0.25) : DS.bg2)
                .overlay(
                    Capsule()
                        .strokeBorder(isActive ? branch.color.opacity(0.6) : DS.textMuted.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Tag Label
struct TagLabel: View {
    let tag: GitTag

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "tag.fill")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(DS.warning)
            Text(tag.name)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(DS.warning)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(DS.warning.opacity(0.15))
                .overlay(
                    Capsule()
                        .strokeBorder(DS.warning.opacity(0.4), lineWidth: 1)
                )
        )
    }
}

// MARK: - Remote Tracking Label
struct RemoteTrackingLabel: View {
    let remoteName: String
    let branchName: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "icloud")
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(Color(hex: "#0891B2"))
            Text("\(remoteName)/\(branchName)")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(Color(hex: "#0891B2"))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color(hex: "#0891B2").opacity(0.12))
                .overlay(
                    Capsule()
                        .strokeBorder(
                            Color(hex: "#0891B2").opacity(0.45),
                            style: StrokeStyle(lineWidth: 1, dash: [3, 2])
                        )
                )
        )
    }
}
