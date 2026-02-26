import SwiftUI
import UIKit

// MARK: - Challenge Goal
enum ChallengeGoal: Sendable {
    case makeCommit
    case hasBranch(name: String)
    case headOnBranch(name: String)
    case commitCount(atLeast: Int)
    case branchCount(atLeast: Int)
    case mergedBranch(source: String, intoTarget: String)
    case hasTag(name: String)
    case hasTagContaining(String)
    case cherryPickedCommit
    case rebasedBranch

    var description: String {
        switch self {
        case .makeCommit:               return "Make at least one new commit"
        case .hasBranch(let n):         return "Create a branch named '\(n)'"
        case .headOnBranch(let n):      return "Checkout the '\(n)' branch"
        case .commitCount(let n):       return "Have at least \(n) commits in the repo"
        case .branchCount(let n):       return "Have at least \(n) branches"
        case .mergedBranch(let s, let t): return "Merge '\(s)' into '\(t)'"
        case .hasTag(let n):            return "Create a tag named '\(n)'"
        case .hasTagContaining(let s):  return "Create a tag containing '\(s)'"
        case .cherryPickedCommit:       return "Cherry-pick a commit onto the current branch"
        case .rebasedBranch:            return "Rebase any branch onto another"
        }
    }
}

// MARK: - Challenge Difficulty
enum ChallengeDifficulty: String, Sendable {
    case easy   = "Easy"
    case medium = "Medium"
    case hard   = "Hard"

    var color: Color {
        switch self {
        case .easy:   return Color(hex: "#059669")
        case .medium: return Color(hex: "#D97706")
        case .hard:   return Color(hex: "#DC2626")
        }
    }
    var badge: String { rawValue }
}

// MARK: - Challenge
struct GitChallenge: Identifiable, Sendable {
    let id: String
    let title: String
    let description: String
    let difficulty: ChallengeDifficulty
    let goal: ChallengeGoal
    let hints: [String]
    let operations: [String]

    init(
        id: String = UUID().uuidString,
        title: String,
        description: String,
        difficulty: ChallengeDifficulty,
        goal: ChallengeGoal,
        hints: [String],
        operations: [String] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.difficulty = difficulty
        self.goal = goal
        self.hints = hints
        self.operations = operations
    }
}

// MARK: - Challenge Engine
@MainActor
final class ChallengeEngine: ObservableObject, @unchecked Sendable {
    @Published var currentChallenge: GitChallenge? = nil
    @Published var isComplete: Bool = false
    @Published var hintsRevealed: Int = 0
    @Published var completedChallengeIds: Set<String> = []

    /// A dedicated GitEngine used only inside challenges
    let engine = GitEngine()

    let challenges = GitChallengeData.all

    // MARK: - Persistence
    private let persistenceKey = "completedChallengeIds_v1"

    init() {
        // Load saved progress from UserDefaults
        if let saved = UserDefaults.standard.array(forKey: persistenceKey) as? [String] {
            completedChallengeIds = Set(saved)
        }
    }

    private func saveProgress() {
        UserDefaults.standard.set(Array(completedChallengeIds), forKey: persistenceKey)
    }

    // MARK: - Goal Evaluation

    func isSatisfied(_ goal: ChallengeGoal) -> Bool {
        switch goal {
        case .makeCommit:
            return engine.commits.count >= 4  // default starts with 3

        case .hasBranch(let name):
            return engine.branches.contains(where: { $0.name == name })

        case .headOnBranch(let name):
            return engine.headBranchName == name

        case .commitCount(let min):
            return engine.commits.count >= min

        case .branchCount(let min):
            return engine.branches.count >= min

        case .mergedBranch(let src, _):
            // Any merge commit (2 parents) whose message references the source branch
            return engine.commits.contains { $0.parentIds.count > 1 && $0.message.contains(src) }

        case .hasTag(let name):
            return engine.tags.contains(where: { $0.name == name })

        case .hasTagContaining(let s):
            return engine.tags.contains(where: { $0.name.contains(s) })

        case .cherryPickedCommit:
            return engine.commits.contains(where: { $0.message.contains("cherry-picked") })

        case .rebasedBranch:
            return engine.commandHistory.contains {
                if case .rebase = $0 { return true }
                return false
            }
        }
    }

    // MARK: - Challenge Control

    func start(_ challenge: GitChallenge) {
        engine.resetToDefault()
        applySetup(for: challenge)
        currentChallenge = challenge
        isComplete = false
        hintsRevealed = 0
    }

    /// Apply the per-challenge starting state
    private func applySetup(for challenge: GitChallenge) {
        switch challenge.id {
        case "ch6":
            engine.createBranch(name: "hotfix")
            engine.checkout(branchName: "hotfix")
            engine.commit(message: "Critical fix")
            engine.checkout(branchName: "main")
        case "ch8":
            engine.createBranch(name: "release")
            engine.checkout(branchName: "release")
            engine.commit(message: "Release candidate 1")
            engine.commit(message: "Release candidate 2")
            engine.checkout(branchName: "main")
        case "ch9":
            // Set up: dev branches off main, gets one commit;
            // then main advances one commit so a rebase is meaningful.
            engine.createBranch(name: "dev")
            engine.checkout(branchName: "dev")
            engine.commit(message: "Dev: new feature")
            engine.checkout(branchName: "main")
            engine.commit(message: "Main: hotfix patch")
            engine.checkout(branchName: "dev")
        default:
            break  // challenges 1-5, 7 start with the default state
        }
    }

    func checkGoal() {
        guard let ch = currentChallenge, !isComplete else { return }
        if isSatisfied(ch.goal) {
            isComplete = true
            completedChallengeIds.insert(ch.id)
            saveProgress()
            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.success)
        }
    }

    func revealNextHint() {
        guard let ch = currentChallenge, hintsRevealed < ch.hints.count else { return }
        hintsRevealed += 1
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()
    }

    func isUnlocked(_ challenge: GitChallenge) -> Bool {
        guard let idx = challenges.firstIndex(where: { $0.id == challenge.id }) else { return false }
        if idx == 0 { return true }
        return completedChallengeIds.contains(challenges[idx - 1].id)
    }

    func reset() {
        currentChallenge = nil
        isComplete = false
        hintsRevealed = 0
        engine.resetToDefault()
    }
}

// MARK: - All Challenges
struct GitChallengeData {
    static let all: [GitChallenge] = [

        GitChallenge(
            id: "ch1",
            title: "First Commit",
            description: "The repo has 3 commits already. Make one more to reach 4 total.",
            difficulty: .easy,
            goal: .commitCount(atLeast: 4),
            hints: [
                "Head to the Commit tab in the command panel.",
                "Type any message in the 'Commit message' field.",
                "Tap the 'Commit' button. Watch the graph grow!"
            ],
            operations: ["git commit -m \"...\""]
        ),

        GitChallenge(
            id: "ch2",
            title: "Branch Out",
            description: "Create a new branch called 'feature' from the current HEAD.",
            difficulty: .easy,
            goal: .hasBranch(name: "feature"),
            hints: [
                "Open the Branch tab in the command panel.",
                "Type 'feature' in the branch name field.",
                "Tap 'Create' to create the branch."
            ],
            operations: ["git branch feature"]
        ),

        GitChallenge(
            id: "ch3",
            title: "Tag a Release",
            description: "Mark the current HEAD commit as version 'v1.0.0' with a tag.",
            difficulty: .easy,
            goal: .hasTagContaining("v1"),
            hints: [
                "Open the Tag tab in the command panel.",
                "Type 'v1.0.0' in the tag name field.",
                "Tap 'Tag' to create the tag on HEAD."
            ],
            operations: ["git tag v1.0.0"]
        ),

        GitChallenge(
            id: "ch4",
            title: "Switch & Commit",
            description: "Create a branch called 'dev', switch to it.",
            difficulty: .medium,
            goal: .headOnBranch(name: "dev"),
            hints: [
                "First create the 'dev' branch in the Branch tab.",
                "Tap the 'dev' chip under 'Switch to branch' to check it out.",
                "You should now be on 'dev' — check the header!"
            ],
            operations: ["git branch dev", "git checkout dev"]
        ),

        GitChallenge(
            id: "ch5",
            title: "Merge It",
            description: "Create a 'feature' branch, commit on it, then merge it back into 'main'.",
            difficulty: .medium,
            goal: .mergedBranch(source: "feature", intoTarget: "main"),
            hints: [
                "Create a 'feature' branch from the Branch tab.",
                "Checkout 'feature' and make at least one commit on it.",
                "Switch back to 'main', then use the Merge tab to merge 'feature'."
            ],
            operations: ["git branch feature", "git checkout feature", "git commit", "git merge feature"]
        ),

        GitChallenge(
            id: "ch6",
            title: "Cherry-pick",
            description: "A 'hotfix' branch is pre-configured with a commit. Cherry-pick that commit onto 'main'.",
            difficulty: .medium,
            goal: .cherryPickedCommit,
            hints: [
                "Tap the 'Critical fix' commit node on the hotfix branch.",
                "The detail sheet will open — scroll down to find the Cherry-pick button.",
                "Tap 'Cherry-pick to main' to copy the commit."
            ],
            operations: ["git cherry-pick <hash>"]
        ),

        GitChallenge(
            id: "ch7",
            title: "Team Setup",
            description: "Set up a team repo: have at least 3 branches simultaneously.",
            difficulty: .hard,
            goal: .branchCount(atLeast: 3),
            hints: [
                "Create multiple branches from the Branch tab.",
                "You don't have to commit on them — just create them.",
                "You currently have 'main'. Create 2 more to reach 3."
            ],
            operations: ["git branch", "git checkout", "git commit"]
        ),

        GitChallenge(
            id: "ch8",
            title: "Full Release",
            description: "A 'release' branch is pre-set up. Merge it into 'main', then tag HEAD as 'v2.0.0'.",
            difficulty: .hard,
            goal: .hasTagContaining("v2"),
            hints: [
                "Open the Merge tab — merge 'release' into 'main'.",
                "After merging, open the Tag tab.",
                "Create a tag called 'v2.0.0' to mark the release."
            ],
            operations: ["git merge", "git tag v2.0.0"]
        ),

        GitChallenge(
            id: "ch9",
            title: "Rebase & Linearise",
            description: "A 'dev' branch diverged from 'main'. Rebase 'dev' onto 'main' to create a clean, linear history.",
            difficulty: .hard,
            goal: .rebasedBranch,
            hints: [
                "You are currently on 'dev'. Open the Rebase tab in the command panel.",
                "Select 'main' as the target to rebase onto.",
                "After rebasing, the graph will show 'dev' sitting linearly on top of 'main'."
            ],
            operations: ["git rebase main"]
        ),
    ]
}
