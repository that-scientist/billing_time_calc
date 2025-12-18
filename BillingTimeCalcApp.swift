import SwiftUI
import AppKit

@main
struct BillingTimeCalcApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 600, minHeight: 600)
                .background(WindowPositionHelper())
        }
        .windowStyle(.automatic)
        .defaultSize(width: 900, height: 900)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

/// Helper view to position the window on the right third of the screen
private struct WindowPositionHelper: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        // Use a small delay to ensure window is fully initialized
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            setupWindowPosition()
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    private func setupWindowPosition() {
        // Get the main screen dimensions
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let screenWidth = screenFrame.width
        let screenHeight = screenFrame.height
        
        // Calculate window size: 1/3 of screen width, 90% of screen height (or max 900)
        let windowWidth = screenWidth / 3.0
        let windowHeight = min(screenHeight * 0.9, 900)
        
        // Calculate position: right side of screen, centered vertically
        let xPosition = screenFrame.origin.x + screenWidth - windowWidth
        let yPosition = screenFrame.origin.y + (screenHeight - windowHeight) / 2.0
        
        // Find the window - try multiple approaches
        var window: NSWindow?
        
        // First, try to find the main window
        if let mainWindow = NSApplication.shared.mainWindow {
            window = mainWindow
        } else if let keyWindow = NSApplication.shared.keyWindow {
            window = keyWindow
        } else if let visibleWindow = NSApplication.shared.windows.first(where: { $0.isVisible }) {
            window = visibleWindow
        }
        
        if let window = window {
            let newFrame = NSRect(
                x: xPosition,
                y: yPosition,
                width: windowWidth,
                height: windowHeight
            )
            window.setFrame(newFrame, display: true, animate: false)
        }
    }
}

