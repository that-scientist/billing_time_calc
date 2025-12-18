import SwiftUI

@main
struct BillingTimeCalcApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.automatic)
        .defaultSize(width: 600, height: 600)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

