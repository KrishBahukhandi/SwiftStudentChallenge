import SwiftUI

struct ContentView: View {
    @EnvironmentObject var engine: GitEngine
    @State private var selectedTab: Int = 0
    @State private var showLegend = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        ZStack {
            DS.bg0.ignoresSafeArea()

            if !hasSeenOnboarding {
                OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
                    .transition(.opacity)
            } else {
                mainTabView
                    .transition(.opacity)
            }
        }
        .animation(DS.springSmooth, value: hasSeenOnboarding)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showLegend) {
            LegendOverlayView { showLegend = false }
                .preferredColorScheme(.dark)
        }
    }

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
            }
            .padding(.horizontal, 8)
            .background(DS.bg1)
        }
    }
}
