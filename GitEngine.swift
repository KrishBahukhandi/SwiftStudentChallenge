import SwiftUI
import UIKit

// MARK: - Haptic Engine Helper
@MainActor
private struct HapticEngine {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let gen = UIImpactFeedbackGenerator(style: style)
        gen.prepare()
        gen.impactOccurred()
    }
    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let gen = UINotificationFeedbackGenerator()
        gen.prepare()
        gen.notificationOccurred(type)
    }
    static func error()   { notify(.error) }
    static func success() { notify(.success) }
    static func warning() { notify(.warning) }
}

// MARK: - GitEngine
@MainActor
class GitEngine: ObservableObject, @unchecked Sendable {


    // MARK: Published State
    @Published var commits: [CommitNode] = []
    @Published var branches: [Branch] = []
    @Published var tags: [GitTag] = []
    @Published var headBranchName: String = "main"
    @Published var commandHistory: [GitOperation] = []
    @Published var lastOperation: GitOperation? = nil
    @Published var errorMessage: String? = nil
    @Published var newlyAddedCommitId: String? = nil

    // MARK: Computed
    var currentBranch: Branch? { branches.first(where: { $0.name == headBranchName }) }
    var headCommit: CommitNode? {
        guard let id = currentBranch?.headCommitId else { return nil }
        return commits.first(where: { $0.id == id })
    }

    private var nextBranchColorIndex = 1 // 0 = violet reserved for main

    // MARK: - Initialise with default repo
    init() {
        resetToDefault()
    }

    // MARK: - Reset / initialise
    func resetToDefault() {
        let mainColor = Color.branchColors[0]
        let c0 = CommitNode(id: makeId(), message: "Initial commit", parentIds: [], branchName: "main", laneIndex: 0, row: 0)
        let c1 = CommitNode(id: makeId(), message: "Add README.md", parentIds: [c0.id], branchName: "main", laneIndex: 0, row: 1)
        let c2 = CommitNode(id: makeId(), message: "Setup project structure", parentIds: [c1.id], branchName: "main", laneIndex: 0, row: 2)
        commits = [c0, c1, c2]
        branches = [Branch(name: "main", headCommitId: c2.id, color: mainColor, laneIndex: 0)]
        tags = []
        headBranchName = "main"
        commandHistory = []
        lastOperation = nil
        errorMessage = nil
        newlyAddedCommitId = nil
        nextBranchColorIndex = 1
    }

    // MARK: - Commit
    func commit(message: String) {
        guard !message.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Commit message cannot be empty."
            HapticEngine.error()
            return
        }
        guard var branch = currentBranch else { return }
        let parentId = branch.headCommitId
        let maxRow = (commits.max(by: { $0.row < $1.row })?.row ?? 0) + 1
        var newCommit = CommitNode(
            id: makeId(),
            message: message,
            parentIds: [parentId],
            branchName: branch.name,
            laneIndex: branch.laneIndex,
            row: maxRow
        )
        newCommit.row = nextRow(after: parentId, onLane: branch.laneIndex)
        commits.append(newCommit)
        branch.headCommitId = newCommit.id
        updateBranch(branch)
        newlyAddedCommitId = newCommit.id
        log(.commit(message: message))
        recalculateLayout()
        HapticEngine.impact(.medium)
    }

    // MARK: - Create Branch
    func createBranch(name: String) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Branch name cannot be empty."
            HapticEngine.error()
            return
        }
        guard branches.first(where: { $0.name == name }) == nil else {
            errorMessage = "Branch '\(name)' already exists."
            HapticEngine.error()
            return
        }
        guard let current = currentBranch else { return }
        let color = Color.branchColors[nextBranchColorIndex % Color.branchColors.count]
        nextBranchColorIndex += 1
        let laneIdx = (branches.map { $0.laneIndex }.max() ?? 0) + 1
        let newBranch = Branch(name: name, headCommitId: current.headCommitId, color: color, laneIndex: laneIdx)
        branches.append(newBranch)
        log(.branch(name: name))
        HapticEngine.impact(.light)
    }

    // MARK: - Checkout
    func checkout(branchName: String) {
        guard branches.first(where: { $0.name == branchName }) != nil else {
            errorMessage = "Branch '\(branchName)' does not exist."
            HapticEngine.error()
            return
        }
        headBranchName = branchName
        log(.checkout(name: branchName))
        HapticEngine.impact(.soft)
    }

    // MARK: - Merge
    func merge(sourceBranchName: String) {
        guard sourceBranchName != headBranchName else {
            errorMessage = "Cannot merge a branch into itself."
            HapticEngine.error()
            return
        }
        guard let source = branches.first(where: { $0.name == sourceBranchName }),
              var dest = currentBranch else {
            errorMessage = "Branch '\(sourceBranchName)' not found."
            HapticEngine.error()
            return
        }
        if source.headCommitId == dest.headCommitId {
            errorMessage = "Already up-to-date."
            HapticEngine.error()
            return
        }
        let maxRow = (commits.max(by: { $0.row < $1.row })?.row ?? 0) + 1
        let mergeCommit = CommitNode(
            id: makeId(),
            message: "Merge '\(sourceBranchName)' into \(dest.name)",
            parentIds: [dest.headCommitId, source.headCommitId],
            branchName: dest.name,
            laneIndex: dest.laneIndex,
            row: maxRow
        )
        commits.append(mergeCommit)
        dest.headCommitId = mergeCommit.id
        updateBranch(dest)
        newlyAddedCommitId = mergeCommit.id
        log(.merge(name: sourceBranchName))
        recalculateLayout()
        HapticEngine.impact(.heavy)
        HapticEngine.success()
    }

    // MARK: - Rebase
    func rebase(onto targetBranchName: String) {
        guard targetBranchName != headBranchName else {
            errorMessage = "Cannot rebase onto the same branch."
            HapticEngine.error()
            return
        }
        guard let target = branches.first(where: { $0.name == targetBranchName }),
              var current = currentBranch else {
            errorMessage = "Branch '\(targetBranchName)' not found."
            HapticEngine.error()
            return
        }
        let targetCommitIds = Set(ancestorIds(of: target.headCommitId))
        let currentCommitIds = ancestorIds(of: current.headCommitId)
        let uniqueIds = currentCommitIds.filter { !targetCommitIds.contains($0) }

        guard !uniqueIds.isEmpty else {
            errorMessage = "Nothing to rebase."
            HapticEngine.error()
            return
        }

        var prevParentId = target.headCommitId
        var maxRow = (commits.max(by: { $0.row < $1.row })?.row ?? 0)
        let targetLane = target.laneIndex

        for oldId in uniqueIds.reversed() {
            guard let idx = commits.firstIndex(where: { $0.id == oldId }) else { continue }
            maxRow += 1
            commits[idx].parentIds = [prevParentId]
            commits[idx].laneIndex = targetLane
            commits[idx].row = maxRow
            commits[idx].branchName = current.name
            prevParentId = commits[idx].id
        }
        current.headCommitId = prevParentId
        current.laneIndex = targetLane
        updateBranch(current)
        log(.rebase(onto: targetBranchName))
        recalculateLayout()
        HapticEngine.impact(.rigid)
    }

    // MARK: - Reset
    func reset(toCommitId commitId: String) {
        guard var current = currentBranch else { return }
        guard commits.first(where: { $0.id == commitId }) != nil else {
            errorMessage = "Commit not found."
            HapticEngine.error()
            return
        }
        current.headCommitId = commitId
        updateBranch(current)
        log(.reset(hash: commitId))
        HapticEngine.warning()
    }

    // MARK: - Cherry Pick
    func cherryPick(commitId: String) {
        guard let source = commits.first(where: { $0.id == commitId }),
              var current = currentBranch else {
            errorMessage = "Commit not found."
            HapticEngine.error()
            return
        }
        let maxRow = (commits.max(by: { $0.row < $1.row })?.row ?? 0) + 1
        var picked = CommitNode(
            id: makeId(),
            message: source.message + " (cherry-picked)",
            parentIds: [current.headCommitId],
            branchName: current.name,
            laneIndex: current.laneIndex,
            row: maxRow
        )
        picked.row = nextRow(after: current.headCommitId, onLane: current.laneIndex)
        commits.append(picked)
        current.headCommitId = picked.id
        updateBranch(current)
        newlyAddedCommitId = picked.id
        log(.cherryPick(hash: commitId))
        recalculateLayout()
        HapticEngine.impact(.medium)
        HapticEngine.success()
    }

    // MARK: - Tag
    func addTag(name: String) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Tag name cannot be empty."
            HapticEngine.error()
            return
        }
        guard let head = headCommit else { return }
        let tag = GitTag(name: name, commitId: head.id)
        tags.append(tag)
        log(.tag(name: name))
        HapticEngine.impact(.light)
    }

    // MARK: - Delete Branch
    func deleteBranch(name: String) {
        guard name != "main" else {
            errorMessage = "Cannot delete the main branch."
            HapticEngine.error()
            return
        }
        guard name != headBranchName else {
            errorMessage = "Cannot delete the currently checked-out branch."
            HapticEngine.error()
            return
        }
        branches.removeAll(where: { $0.name == name })
        log(.deleteBranch(name: name))
        HapticEngine.warning()
    }

    // MARK: - Helpers
    private func log(_ op: GitOperation) {
        commandHistory.insert(op, at: 0)
        lastOperation = op
        errorMessage = nil
    }

    private func updateBranch(_ branch: Branch) {
        if let idx = branches.firstIndex(where: { $0.id == branch.id }) {
            branches[idx] = branch
        }
    }

    private func makeId() -> String {
        UUID().uuidString.lowercased().replacingOccurrences(of: "-", with: "").prefix(40).description
    }

    /// Returns all ancestor commit IDs (inclusive) in order from HEAD -> root
    func ancestorIds(of commitId: String) -> [String] {
        var result: [String] = []
        var queue = [commitId]
        var visited = Set<String>()
        while !queue.isEmpty {
            let current = queue.removeFirst()
            guard !visited.contains(current) else { continue }
            visited.insert(current)
            result.append(current)
            if let node = commits.first(where: { $0.id == current }) {
                queue.append(contentsOf: node.parentIds)
            }
        }
        return result
    }

    private func nextRow(after parentId: String, onLane laneIndex: Int) -> Int {
        let maxRow = commits.max(by: { $0.row < $1.row })?.row ?? 0
        return maxRow + 1
    }

    /// Recalculate row positions so graph stays consistent
    func recalculateLayout() {
        var children: [String: [String]] = [:]
        for c in commits {
            for pid in c.parentIds {
                children[pid, default: []].append(c.id)
            }
        }
        // Compute in-degree for topological BFS
        var inDeg: [String: Int] = [:]
        for c in commits { inDeg[c.id] = 0 }
        for c in commits {
            for _ in c.parentIds {
                inDeg[c.id, default: 0] += 1
            }
        }
        var queue = commits.filter { (inDeg[$0.id] ?? 0) == 0 }.map { $0.id }
        var rowCounter = 0
        var visited = Set<String>()
        while !queue.isEmpty {
            let batchSize = queue.count
            for i in 0..<batchSize {
                let nodeId = queue[i]
                guard !visited.contains(nodeId) else { continue }
                visited.insert(nodeId)
                if let idx = commits.firstIndex(where: { $0.id == nodeId }) {
                    commits[idx].row = rowCounter
                }
                for child in (children[nodeId] ?? []) {
                    inDeg[child, default: 1] -= 1
                    if inDeg[child] == 0 && !visited.contains(child) {
                        queue.append(child)
                    }
                }
            }
            queue.removeFirst(batchSize)
            rowCounter += 1
        }
    }

    // MARK: - Canvas layout helpers
    func position(for commit: CommitNode, canvasWidth: CGFloat) -> CGPoint {
        let x = DS.laneWidth * CGFloat(commit.laneIndex) + DS.laneWidth / 2 + 16
        let y = CGFloat(commit.row) * DS.rowHeight + DS.rowHeight / 2 + 16
        return CGPoint(x: x, y: y)
    }

    var graphHeight: CGFloat {
        let maxRow = commits.max(by: { $0.row < $1.row })?.row ?? 0
        return CGFloat(maxRow + 1) * DS.rowHeight + 64
    }

    var graphWidth: CGFloat {
        let maxLane = commits.max(by: { $0.laneIndex < $1.laneIndex })?.laneIndex ?? 0
        return CGFloat(maxLane + 1) * DS.laneWidth + 64
    }

    func color(for commit: CommitNode) -> Color {
        branches.first(where: { $0.name == commit.branchName })?.color ?? DS.accent
    }

    func tags(for commitId: String) -> [GitTag] {
        tags.filter { $0.commitId == commitId }
    }

    func branches(for commitId: String) -> [Branch] {
        branches.filter { $0.headCommitId == commitId }
    }

    func isHead(_ commitId: String) -> Bool {
        currentBranch?.headCommitId == commitId
    }
}
