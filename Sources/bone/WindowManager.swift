import AppKit
import SwiftUI

class BoneWindow: NSWindow {
    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown {
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let isCmdOpt = modifiers == [.command, .option]

            if isCmdOpt && event.keyCode == 6 {
                // Zoom shortcut: handled by WindowManager
                // We can't call windowManager.zoom() directly here,
                // so post a notification instead
                NotificationCenter.default.post(name: .zoomWindow, object: nil)
                return
            }

            if let textView = VimTextViewSubclass.activeInstance {
                // Forward key events directly to the text view, bypassing NSHostingView
                textView.keyDown(with: event)
                return
            }
        }
        super.sendEvent(event)
    }
}

extension Notification.Name {
    static let zoomWindow = Notification.Name("zoomWindow")
}

@MainActor
final class WindowManager: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private let contentView = ContentView()
    private var isCustomZoomed = false
    private var frameBeforeZoom: NSRect = .zero

    func show() {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }

        let hostingView = NSHostingView(rootView: contentView)

        let window = BoneWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "bone"
        window.contentView = hostingView
        window.delegate = self
        window.setFrameAutosaveName("boneMainWindow")
        window.isReleasedWhenClosed = false
        window.appearance = nil // Follow system appearance automatically
        window.center()
        window.makeKeyAndOrderFront(nil)

        NSApplication.shared.activate(ignoringOtherApps: true)

        self.window = window

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleZoomNotification),
            name: .zoomWindow,
            object: nil
        )
    }

    @objc private func handleZoomNotification() {
        zoom()
    }

    func hide() {
        window?.orderOut(nil)
    }

    func toggle() {
        if let window = window, window.isVisible {
            hide()
        } else {
            show()
        }
    }

    func zoom() {
        guard let window = window else { return }
        if isCustomZoomed {
            // Restore previous frame
            window.setFrame(frameBeforeZoom, display: true, animate: true)
            isCustomZoomed = false
        } else {
            // Store current frame and zoom to 80% of screen
            frameBeforeZoom = window.frame
            if let screen = window.screen {
                let screenFrame = screen.visibleFrame
                let newWidth = screenFrame.width * 0.8
                let newHeight = screenFrame.height * 0.8
                let newX = screenFrame.midX - newWidth / 2
                let newY = screenFrame.midY - newHeight / 2
                let zoomedFrame = NSRect(x: newX, y: newY, width: newWidth, height: newHeight)
                window.setFrame(zoomedFrame, display: true, animate: true)
                isCustomZoomed = true
            }
        }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        return true
    }
}
