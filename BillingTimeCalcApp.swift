import SwiftUI
import AppKit

@main
struct BillingTimeCalcApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
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
        // Use a delay to ensure window is fully initialized and content is laid out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
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
        
        // Minimum window size to accommodate content (850px width, 850px height)
        let minWindowWidth: CGFloat = 850
        let minWindowHeight: CGFloat = 850
        
        // Calculate window size: 1/3 of screen width, but at least minimum size
        // If 1/3 of screen is less than minimum, use minimum (ensures content fits)
        let calculatedWidth = screenWidth / 3.0
        let windowWidth = max(calculatedWidth, minWindowWidth)
        
        // Use 90% of screen height, but at least minimum height
        let calculatedHeight = screenHeight * 0.9
        let windowHeight = max(calculatedHeight, minWindowHeight)
        
        // Ensure window doesn't exceed screen bounds (with small margin for safety)
        let margin: CGFloat = 10
        let maxWidth = screenWidth - margin
        let maxHeight = screenHeight - margin
        let finalWidth = min(windowWidth, maxWidth)
        let finalHeight = min(windowHeight, maxHeight)
        
        // Calculate position: right side of screen, centered vertically
        // Ensure window doesn't go off-screen
        let xPosition = max(
            screenFrame.origin.x + margin,
            screenFrame.origin.x + screenWidth - finalWidth
        )
        let yPosition = max(
            screenFrame.origin.y + margin,
            screenFrame.origin.y + (screenHeight - finalHeight) / 2.0
        )
        
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
                width: finalWidth,
                height: finalHeight
            )
            window.setFrame(newFrame, display: true, animate: false)
            // Force layout update to ensure content is properly displayed
            window.contentView?.needsLayout = true
            window.contentView?.layoutSubtreeIfNeeded()
        }
    }
}

