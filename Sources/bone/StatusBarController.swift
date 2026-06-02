import AppKit
import SwiftUI

@MainActor
final class StatusBarController {
    private var statusItem: NSStatusItem
    private var windowManager: WindowManager

    init(windowManager: WindowManager) {
        self.windowManager = windowManager
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            if let resourcePath = Bundle.main.resourcePath {
                let imagePath = "\(resourcePath)/StatusBarIcon.imageset/StatusBarIcon_18.png"
                if let customImage = NSImage(contentsOfFile: imagePath) {
                    button.image = customImage
                    button.image?.size = NSSize(width: 18, height: 18)
                    button.image?.isTemplate = true
                } else {
                    button.image = NSImage(systemSymbolName: "note.text", accessibilityDescription: "bone")
                    button.image?.size = NSSize(width: 18, height: 18)
                    button.image?.isTemplate = true
                }
            } else {
                button.image = NSImage(systemSymbolName: "note.text", accessibilityDescription: "bone")
                button.image?.size = NSSize(width: 18, height: 18)
                button.image?.isTemplate = true
            }
        }

        setupMenu()
    }

    private func setupMenu() {
        let menu = NSMenu()

        let showItem = NSMenuItem(title: "Show bone", action: #selector(showWindow), keyEquivalent: "")
        showItem.target = self
        menu.addItem(showItem)

        menu.addItem(NSMenuItem.separator())

        for i in 0..<7 {
            let item = NSMenuItem(
                title: "Buffer \(i + 1): \(Buffer.defaultTitles[i])",
                action: #selector(selectBuffer(_:)),
                keyEquivalent: "\(i + 1)"
            )
            item.target = self
            item.tag = i
            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit bone", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func showWindow() {
        windowManager.show()
    }

    @objc private func selectBuffer(_ sender: NSMenuItem) {
        windowManager.show()
        NotificationCenter.default.post(name: .selectBuffer, object: sender.tag)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

extension Notification.Name {
    static let selectBuffer = Notification.Name("selectBuffer")
}
