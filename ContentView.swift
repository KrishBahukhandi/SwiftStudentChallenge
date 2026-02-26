import SwiftUI

struct ContentView: View {
    @EnvironmentObject var engine: GitEngine
    @State private var selectedTab: Int = 0
    @State private var showLegend = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("isDarkMode") private var isDarkMode = true

    var body: some View {
        GeometryReader { geo in
            ZStack {
                DS.bg0.ignoresSafeArea()

                if !hasSeenOnboarding {
                    OnboardingView(
                        hasSeenOnboarding: $hasSeenOnboarding,
                        selectedTab: $selectedTab
                    )
                    .transition(.opacity)
                } else if geo.size.width > 768 {
                    // ── iPad: NavigationSplitView sidebar ────────────
                    ipadLayout
                        .transition(.opacity)
                } else {
                    // ── iPhone / compact: original bottom tab bar ────
                    mainTabView
                        .transition(.opacity)
                }
            }
            .animation(DS.springSmooth, value: hasSeenOnboarding)
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .sheet(isPresented: $showLegend) {
            LegendOverlayView { showLegend = false }
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }

    // MARK: - iPad Split Layout
    var ipadLayout: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            // ── Sidebar ───────────────────────────────────────────────
            VStack(spacing: 0) {
                // App title
                HStack(spacing: 10) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(DS.accentLit)
                    Text("GitVisualiser")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 16)

                Divider().background(DS.textMuted.opacity(0.15))
                    .padding(.bottom, 8)

                // Nav items
                VStack(spacing: 4) {
                    iPadSidebarItem(icon: "book.circle",      title: "Learn",     hint: "Interactive Git lessons",             tag: 0)
                    iPadSidebarItem(icon: "play.circle",      title: "Sandbox",   hint: "Experiment with a live Git graph",    tag: 1)
                    iPadSidebarItem(icon: "flowchart",        title: "Flows",     hint: "Real-world Git branching strategies", tag: 2)
                    iPadSidebarItem(icon: "trophy.circle",    title: "Challenge", hint: "Git puzzle challenges",               tag: 3)
                }
                .padding(.horizontal, 12)

                Spacer()

                Divider().background(DS.textMuted.opacity(0.15))
                    .padding(.bottom, 12)

                // Theme toggle at bottom of sidebar
                Button {
                    withAnimation(DS.springSnappy) { isDarkMode.toggle() }
                } label: {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(isDarkMode ? DS.accent.opacity(0.15) : Color.orange.opacity(0.15))
                                .frame(width: 34, height: 34)
                            Image(systemName: isDarkMode ? "moon.stars.fill" : "sun.max.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(isDarkMode ? DS.accentLit : .orange)
                        }
                        Text(isDarkMode ? "Dark Mode" : "Light Mode")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(DS.textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                }
                .accessibilityLabel(isDarkMode ? "Switch to light mode" : "Switch to dark mode")
                .padding(.bottom, 24)
            }
            .background(DS.bg1)
            .navigationSplitViewColumnWidth(min: 200, ideal: 230, max: 260)
        } detail: {
            // ── Detail pane ───────────────────────────────────────────
            ZStack {
                DS.bg0.ignoresSafeArea()
                switch selectedTab {
                case 0:
                    LearnView()
                        .environmentObject(engine)
                case 1:
                    SandboxView(showLegend: $showLegend)
                        .environmentObject(engine)
                case 2:
                    GitFlowsView()
                case 3:
                    ChallengeView()
                default:
                    EmptyView()
                }
            }
            .animation(DS.springSmooth, value: selectedTab)
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    func iPadSidebarItem(icon: String, title: String, hint: String, tag: Int) -> some View {
        Button {
            withAnimation(DS.springSnappy) { selectedTab = tag }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(selectedTab == tag ? DS.accent : DS.bg2)
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(selectedTab == tag ? .white : DS.textSecondary)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 14, weight: selectedTab == tag ? .bold : .medium, design: .rounded))
                        .foregroundColor(selectedTab == tag ? .primary : DS.textSecondary)
                    Text(hint)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(DS.textMuted)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: DS.radiusM, style: .continuous)
                    .fill(selectedTab == tag ? DS.accent.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(hint)
        .accessibilityAddTraits(selectedTab == tag ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - iPhone / Compact Tab View (unchanged)
    var mainTabView: some View {
        VStack(spacing: 0) {
            // ── Content area ─────────────────────────────────────
            ZStack {
                switch selectedTab {
                case 0:
                    LearnView()
                        .environmentObject(engine)
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case 1:
                    SandboxView(showLegend: $showLegend)
                        .environmentObject(engine)
                        .transition(.opacity)
                case 2:
                    GitFlowsView()
                        .transition(.opacity)
                case 3:
                    ChallengeView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                default:
                    EmptyView()
                }
            }
            .animation(DS.springSmooth, value: selectedTab)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()
                .background(Color.white.opacity(0.06))

            // ── Tab Bar ────────────────────────────────────────
            HStack(spacing: 0) {
                Button {
                    withAnimation(DS.springSnappy) { selectedTab = 0 }
                } label: {
                    TabItemLabel(icon: "book.circle", title: "Learn", isSelected: selectedTab == 0)
                }
                .accessibilityLabel("Learn")
                .accessibilityHint("Interactive Git lessons with Try it Live")
                .accessibilityAddTraits(selectedTab == 0 ? [.isButton, .isSelected] : .isButton)

                Button {
                    withAnimation(DS.springSnappy) { selectedTab = 1 }
                } label: {
                    TabItemLabel(icon: "play.circle", title: "Sandbox", isSelected: selectedTab == 1)
                }
                .accessibilityLabel("Sandbox")
                .accessibilityHint("Interactive Git graph — experiment freely")
                .accessibilityAddTraits(selectedTab == 1 ? [.isButton, .isSelected] : .isButton)

                Button {
                    withAnimation(DS.springSnappy) { selectedTab = 2 }
                } label: {
                    TabItemLabel(icon: "flowchart", title: "Flows", isSelected: selectedTab == 2)
                }
                .accessibilityLabel("Flows")
                .accessibilityHint("Real-world Git branching strategies")
                .accessibilityAddTraits(selectedTab == 2 ? [.isButton, .isSelected] : .isButton)

                Button {
                    withAnimation(DS.springSnappy) { selectedTab = 3 }
                } label: {
                    TabItemLabel(icon: "trophy.circle", title: "Challenge", isSelected: selectedTab == 3)
                }
                .accessibilityLabel("Challenge")
                .accessibilityHint("Git puzzle challenges")
                .accessibilityAddTraits(selectedTab == 3 ? [.isButton, .isSelected] : .isButton)

                // ── Theme Toggle ──────────────────────────────────
                Divider()
                    .frame(width: 1, height: 24)
                    .background(DS.textMuted.opacity(0.3))
                    .padding(.horizontal, 4)
                Button {
                    withAnimation(DS.springSnappy) { isDarkMode.toggle() }
                } label: {
                    ZStack {
                        Circle()
                            .fill(isDarkMode ? DS.accent.opacity(0.15) : Color.orange.opacity(0.15))
                            .frame(width: 34, height: 34)
                        Image(systemName: isDarkMode ? "moon.stars.fill" : "sun.max.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(isDarkMode ? DS.accentLit : .orange)
                    }
                }
                .padding(.trailing, 6)
                .accessibilityLabel(isDarkMode ? "Switch to light mode" : "Switch to dark mode")
            }
            .padding(.horizontal, 8)
            .background(DS.bg1)
        }
    }
}
