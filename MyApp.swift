import SwiftUI

@main
struct MyApp: App {
    @StateObject private var engine = GitEngine()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(engine)
        }
    }
}
