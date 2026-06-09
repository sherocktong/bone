import AppKit
import SwiftUI

@main
class BoneApp: NSApplication, NSApplicationDelegate {
    private var windowManager: WindowManager!

    override init() {
        super.init()
        self.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func main() {
        let app = BoneApp.shared
        app.setActivationPolicy(.regular)
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        windowManager = WindowManager()

        setupMainMenu()

        // Show window on first launch
        windowManager.show()
    }

    private func setupMainMenu() {
        let mainMenu = NSMenu()

        // MARK: — bone App Menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About bone", action: #selector(orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit bone", action: #selector(terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // MARK: — Edit Menu
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenu.addItem(NSMenuItem.separator())

        // Find submenu
        let findMenu = NSMenu(title: "Find")
        let findItem = NSMenuItem(title: "Find...", action: #selector(NSResponder.performTextFinderAction(_:)), keyEquivalent: "f")
        findItem.tag = NSTextFinder.Action.showFindInterface.rawValue
        findMenu.addItem(findItem)

        let findNextItem = NSMenuItem(title: "Find Next", action: #selector(NSResponder.performTextFinderAction(_:)), keyEquivalent: "g")
        findNextItem.tag = NSTextFinder.Action.nextMatch.rawValue
        findMenu.addItem(findNextItem)

        let findPreviousItem = NSMenuItem(title: "Find Previous", action: #selector(NSResponder.performTextFinderAction(_:)), keyEquivalent: "G")
        findPreviousItem.tag = NSTextFinder.Action.previousMatch.rawValue
        findMenu.addItem(findPreviousItem)

        let useSelectionItem = NSMenuItem(title: "Use Selection for Find", action: #selector(NSResponder.performTextFinderAction(_:)), keyEquivalent: "e")
        useSelectionItem.tag = NSTextFinder.Action.setSearchString.rawValue
        findMenu.addItem(useSelectionItem)

        findMenu.addItem(withTitle: "Jump to Selection", action: #selector(NSTextView.centerSelectionInVisibleArea(_:)), keyEquivalent: "j")
        let findMenuItem = NSMenuItem(title: "Find", action: nil, keyEquivalent: "")
        findMenuItem.submenu = findMenu
        editMenu.addItem(findMenuItem)

        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        // MARK: — Buffers Menu with ⌘1–⌘7
        let bufferMenuItem = NSMenuItem()
        let bufferMenu = NSMenu(title: "Buffers")
        for i in 0..<7 {
            let item = NSMenuItem(
                title: "Buffer \(i + 1): \(Buffer.defaultTitles[i])",
                action: #selector(selectBufferFromMenu(_:)),
                keyEquivalent: "\(i + 1)"
            )
            item.target = self
            item.tag = i
            bufferMenu.addItem(item)
        }
        bufferMenuItem.submenu = bufferMenu
        mainMenu.addItem(bufferMenuItem)

        // MARK: — Window Menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        let zoomItem = NSMenuItem(title: "Zoom", action: nil, keyEquivalent: "")
        zoomItem.isEnabled = false // Handled by local monitor
        windowMenu.addItem(zoomItem)
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        self.mainMenu = mainMenu
    }

    @objc private func selectBufferFromMenu(_ sender: NSMenuItem) {
        windowManager.show()
        NotificationCenter.default.post(name: .selectBuffer, object: sender.tag)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Buffers are saved on every keystroke — nothing extra needed
    }
}
