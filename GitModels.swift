import SwiftUI

// MARK: - Commit Node
struct CommitNode: Identifiable, Equatable {
    let id: String
    var message: String
    var shortHash: String
    var parentIds: [String]
    var branchName: String
    var timestamp: Date
    var laneIndex: Int
    var row: Int

    init(
        id: String = UUID().uuidString,
        message: String,
        parentIds: [String] = [],
        branchName: String,
        timestamp: Date = Date(),
        laneIndex: Int = 0,
        row: Int = 0
    ) {
        self.id = id
        self.message = message
        self.shortHash = String(id.prefix(7))
        self.parentIds = parentIds
        self.branchName = branchName
        self.timestamp = timestamp
        self.laneIndex = laneIndex
        self.row = row
    }

    static func == (lhs: CommitNode, rhs: CommitNode) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Branch
struct Branch: Identifiable, Equatable {
    let id: String
    var name: String
    var headCommitId: String
    var color: Color
    var laneIndex: Int
    var isRemote: Bool = false

    init(
        id: String = UUID().uuidString,
        name: String,
        headCommitId: String,
        color: Color,
        laneIndex: Int,
        isRemote: Bool = false
    ) {
        self.id = id
        self.name = name
        self.headCommitId = headCommitId
        self.color = color
        self.laneIndex = laneIndex
        self.isRemote = isRemote
    }

    static func == (lhs: Branch, rhs: Branch) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Tag
struct GitTag: Identifiable, Equatable {
    let id: String
    var name: String
    var commitId: String

    init(id: String = UUID().uuidString, name: String, commitId: String) {
        self.id = id
        self.name = name
        self.commitId = commitId
    }
}

// MARK: - Git Operation (for history log)
enum GitOperation: CustomStringConvertible {
    case commit(message: String)
    case branch(name: String)
    case checkout(name: String)
    case merge(name: String)
    case rebase(onto: String)
    case reset(hash: String)
    case cherryPick(hash: String)
    case tag(name: String)
    case deleteBranch(name: String)

    var description: String {
        switch self {
        case .commit(let msg):    return "git commit -m \"\(msg)\""
        case .branch(let name):   return "git branch \(name)"
        case .checkout(let name): return "git checkout \(name)"
        case .merge(let name):    return "git merge \(name)"
        case .rebase(let onto):   return "git rebase \(onto)"
        case .reset(let hash):    return "git reset --hard \(String(hash.prefix(7)))"
        case .cherryPick(let h):  return "git cherry-pick \(String(h.prefix(7)))"
        case .tag(let name):      return "git tag \(name)"
        case .deleteBranch(let n):return "git branch -d \(n)"
        }
    }

    var icon: String {
        switch self {
        case .commit:      return "circle.fill"
        case .branch:      return "arrow.triangle.branch"
        case .checkout:    return "arrow.left.arrow.right"
        case .merge:       return "arrow.triangle.merge"
        case .rebase:      return "arrow.up.arrow.down"
        case .reset:       return "arrow.uturn.backward"
        case .cherryPick:  return "smallcircle.filled.circle"
        case .tag:         return "tag.fill"
        case .deleteBranch:return "trash"
        }
    }
}

// MARK: - Lesson
struct GitLesson: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let explanation: String
    let steps: [LessonStep]
    let operation: GitOperation?
}

struct LessonStep: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
}

// MARK: - Lane Layout Helper
struct LaneLayout {
    static let nodeRadius: CGFloat = 18
    static let laneWidth: CGFloat = 60
    static let rowHeight: CGFloat = 72
    static let horizontalPadding: CGFloat = 32
    static let verticalPadding: CGFloat = 32

    static func position(for node: CommitNode, in size: CGSize) -> CGPoint {
        let x = horizontalPadding + LaneLayout.laneWidth * CGFloat(node.laneIndex) + LaneLayout.nodeRadius
        let y = verticalPadding + LaneLayout.rowHeight * CGFloat(node.row)
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Branch Colors
extension Color {
    static let branchColors: [Color] = [
        Color(hex: "#7C3AED"), // violet (main)
        Color(hex: "#2563EB"), // blue
        Color(hex: "#059669"), // green
        Color(hex: "#D97706"), // amber
        Color(hex: "#DC2626"), // red
        Color(hex: "#DB2777"), // pink
        Color(hex: "#0891B2"), // cyan
        Color(hex: "#7C3AED"), // violet again (cycle)
    ]

    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")))
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
