import SwiftUI

@main
struct BillingTimeCalcApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.automatic)
        .defaultSize(width: 900, height: 900)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

