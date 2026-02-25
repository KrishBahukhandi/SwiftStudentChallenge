import SwiftUI

// MARK: - Legend / About Overlay
struct LegendOverlayView: View {
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            DS.bg0.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Header ──────────────────────────────────
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Understanding the Graph")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("What every element means")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(DS.textMuted)
                        }
                        Spacer()
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(DS.textSecondary)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(DS.bg2))
                        }
                        .accessibilityLabel("Close legend")
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 20)

                    // ── Legend Items ─────────────────────────────
                    VStack(alignment: .leading, spacing: 2) {
                        LegendRow(
                            icon: "circle.fill",
                            iconColor: DS.accent,
                            title: "Commit (node)",
                            detail: "Each filled circle is a commit — a saved snapshot of your project at that moment in time. The short hash (e.g. a3b1c4f) uniquely identifies it."
                        )
                        LegendDivider()
                        LegendRow(
                            icon: "line.diagonal",
                            iconColor: DS.textMuted,
                            title: "Edge (line between nodes)",
                            detail: "A line from commit B to commit A means B is a child of A — A is B's parent. This forms the commit chain (history)."
                        )
                        LegendDivider()
                        LegendRow(
                            icon: "tag.fill",
                            iconColor: Color(hex: "#F59E0B"),
                            title: "Branch label (pill)",
                            detail: "A coloured pill (e.g. 'main', 'feature') is a branch pointer. It shows which commit that branch currently points to. Branches move forward as you commit."
                        )
                        LegendDivider()
                        LegendRow(
                            icon: "triangle.fill",
                            iconColor: DS.accentLit,
                            title: "HEAD",
                            detail: "HEAD is a special label that marks YOUR current position — the branch or commit you have checked out. New commits are added on top of HEAD."
                        )
                        LegendDivider()
                        LegendRow(
                            icon: "arrow.triangle.merge",
                            iconColor: DS.success,
                            title: "Merge commit",
                            detail: "A commit with two incoming edges (two parents) is a merge commit. It combines the histories of two branches into one."
                        )
                        LegendDivider()
                        LegendRow(
                            icon: "bookmark.fill",
                            iconColor: Color(hex: "#F59E0B"),
                            title: "Tag",
                            detail: "Tags mark specific commits with a name (e.g. 'v1.0'). Unlike branches, tags don't move — they're permanent labels on a specific commit."
                        )
                    }
                    .background(
                        RoundedRectangle(cornerRadius: DS.radiusL, style: .continuous)
                            .fill(DS.bg1)
                    )
                    .padding(.horizontal, 16)

                    // ── Colour coding ────────────────────────────
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Colour coding")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(DS.textMuted)
                            .padding(.horizontal, 4)

                        HStack(spacing: 12) {
                            ForEach(Array(Color.branchColors.prefix(5).enumerated()), id: \.offset) { i, color in
                                VStack(spacing: 6) {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 28, height: 28)
                                    Text(i == 0 ? "main" : "branch \(i)")
                                        .font(.system(size: 9, weight: .medium, design: .rounded))
                                        .foregroundColor(DS.textMuted)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 4)

                        Text("Each branch gets its own colour automatically. Commits inherit the colour of the branch they were made on.")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(DS.textMuted)
                            .padding(.horizontal, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 8)

                    // ── Quick tip ────────────────────────────────
                    HStack(spacing: 12) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 18))
                            .foregroundColor(DS.accentLit)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Tip")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(DS.accentLit)
                            Text("Tap any commit node in the graph to inspect its full details — message, hash, parent commits, and branches.")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(DS.textSecondary)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: DS.radiusL, style: .continuous)
                            .fill(DS.accent.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.radiusL, style: .continuous)
                                    .strokeBorder(DS.accent.opacity(0.25), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Legend Row
private struct LegendRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(Circle().fill(iconColor.opacity(0.12)))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text(detail)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(DS.textMuted)
                    .lineSpacing(3)
            }
            .padding(.vertical, 14)
        }
        .padding(.horizontal, 16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(detail)")
    }
}

private struct LegendDivider: View {
    var body: some View {
        Rectangle()
            .fill(DS.textMuted.opacity(0.1))
            .frame(height: 1)
            .padding(.leading, 62)
    }
}
