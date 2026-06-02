import SwiftUI
import AppKit
import Combine

enum VimMode: String {
    case normal = "NORMAL"
    case insert = "INSERT"
    case visual = "VISUAL"
}

@MainActor
final class VimEngine: ObservableObject {
    @Published var mode: VimMode = .normal {
        willSet { objectWillChange.send() }
    }
    @Published var commandBuffer: String = ""

    private var visualStartLocation: Int?
    weak var textView: VimTextViewSubclass?

    func handleKeyEvent(_ event: NSEvent, in textView: NSTextView) -> Bool {
        guard event.type == .keyDown else { return false }

        let chars = event.charactersIgnoringModifiers ?? ""
        let modifiers = event.modifierFlags

        if event.keyCode == 53 { // Escape
            if mode == .visual {
                mode = .normal
                visualStartLocation = nil
                textView.setSelectedRange(NSRange(location: textView.selectedRange().location, length: 0))
            } else {
                mode = .normal
                textView.setSelectedRange(NSRange(location: textView.selectedRange().location, length: 0))
            }
            commandBuffer = ""
            return true
        }

        switch mode {
        case .insert:
            return false // Let NSTextView handle it
        case .visual:
            return handleVisualMode(char: chars, modifiers: modifiers, textView: textView)
        case .normal:
            return handleNormalMode(char: chars, modifiers: modifiers, textView: textView)
        }
    }

    private func handleNormalMode(char: String, modifiers: NSEvent.ModifierFlags, textView: NSTextView) -> Bool {
        let string = textView.string
        let range = textView.selectedRange()
        let location = range.location

        if modifiers.contains(.command) {
            return false // Allow cmd shortcuts
        }

        // Command buffer for multi-char commands
        if !commandBuffer.isEmpty {
            let combined = commandBuffer + char
            commandBuffer = ""
            return executeCommand(combined, textView: textView, string: string, location: location)
        }

        switch char {
        case "i":
            mode = .insert
            return true
        case "a":
            mode = .insert
            if location < string.count {
                textView.setSelectedRange(NSRange(location: location + 1, length: 0))
            }
            return true
        case "o":
            mode = .insert
            insertNewlineAfterCurrentLine(textView: textView, string: string, location: location)
            return true
        case "O":
            mode = .insert
            insertNewlineBeforeCurrentLine(textView: textView, string: string, location: location)
            return true
        case "v":
            mode = .visual
            visualStartLocation = location
            return true
        case "h":
            moveLeft(textView: textView, location: location)
            return true
        case "j":
            moveDown(textView: textView, location: location)
            return true
        case "k":
            moveUp(textView: textView, location: location)
            return true
        case "l":
            moveRight(textView: textView, string: string, location: location)
            return true
        case "0":
            moveToLineStart(textView: textView, string: string, location: location)
            return true
        case "$":
            moveToLineEnd(textView: textView, string: string, location: location)
            return true
        case "w":
            moveToNextWord(textView: textView, string: string, location: location)
            return true
        case "b":
            moveToPreviousWord(textView: textView, string: string, location: location)
            return true
        case "x":
            deleteCharacter(textView: textView, string: string, location: location)
            return true
        case "d":
            commandBuffer = "d"
            return true
        case "y":
            commandBuffer = "y"
            return true
        case "p":
            paste(textView: textView)
            return true
        case "u":
            textView.undoManager?.undo()
            return true
        case "U":
            textView.undoManager?.redo()
            return true
        case "g":
            commandBuffer = "g"
            return true
        case "G":
            moveToEndOfFile(textView: textView, string: string)
            return true
        case ":":
            return true // Placeholder for command palette
        default:
            return true // Swallow unmapped keys in normal mode
        }
    }

    private func handleVisualMode(char: String, modifiers: NSEvent.ModifierFlags, textView: NSTextView) -> Bool {
        let string = textView.string
        let range = textView.selectedRange()
        _ = range.location + range.length

        if modifiers.contains(.command) {
            return false
        }

        switch char {
        case "h":
            extendSelectionLeft(textView: textView)
            return true
        case "j":
            extendSelectionDown(textView: textView)
            return true
        case "k":
            extendSelectionUp(textView: textView)
            return true
        case "l":
            extendSelectionRight(textView: textView, string: string)
            return true
        case "d", "x":
            deleteSelection(textView: textView)
            mode = .normal
            return true
        case "y":
            copySelection(textView: textView)
            mode = .normal
            return true
        default:
            return true
        }
    }

    // MARK: - Movement

    private func moveLeft(textView: NSTextView, location: Int) {
        guard location > 0 else { return }
        textView.setSelectedRange(NSRange(location: location - 1, length: 0))
    }

    private func moveRight(textView: NSTextView, string: String, location: Int) {
        guard location < string.count else { return }
        textView.setSelectedRange(NSRange(location: location + 1, length: 0))
    }

    private func moveUp(textView: NSTextView, location: Int) {
        guard let currentLineRange = lineRange(for: location, in: textView.string),
              let previousLineRange = previousLine(from: currentLineRange, in: textView.string) else { return }
        let column = location - currentLineRange.location
        let newLocation = min(previousLineRange.location + column, previousLineRange.upperBound - 1)
        textView.setSelectedRange(NSRange(location: max(newLocation, previousLineRange.location), length: 0))
    }

    private func moveDown(textView: NSTextView, location: Int) {
        guard let currentLineRange = lineRange(for: location, in: textView.string),
              let nextLineRange = nextLine(from: currentLineRange, in: textView.string) else { return }
        let column = location - currentLineRange.location
        let newLocation = min(nextLineRange.location + column, nextLineRange.upperBound - 1)
        textView.setSelectedRange(NSRange(location: max(newLocation, nextLineRange.location), length: 0))
    }

    private func moveToLineStart(textView: NSTextView, string: String, location: Int) {
        guard let lineRange = lineRange(for: location, in: string) else { return }
        textView.setSelectedRange(NSRange(location: lineRange.location, length: 0))
    }

    private func moveToLineEnd(textView: NSTextView, string: String, location: Int) {
        guard let lineRange = lineRange(for: location, in: string) else { return }
        let end = max(lineRange.upperBound - 1, lineRange.location)
        textView.setSelectedRange(NSRange(location: end, length: 0))
    }

    private func moveToNextWord(textView: NSTextView, string: String, location: Int) {
        guard location < string.count else { return }
        let start = string.index(string.startIndex, offsetBy: location)
        var current = start

        // Skip current word characters
        while current < string.endIndex && !isWordBoundary(char: string[current]) {
            current = string.index(after: current)
        }
        // Skip whitespace/punctuation
        while current < string.endIndex && isWordBoundary(char: string[current]) {
            current = string.index(after: current)
        }

        let newLocation = string.distance(from: string.startIndex, to: current)
        textView.setSelectedRange(NSRange(location: newLocation, length: 0))
    }

    private func moveToPreviousWord(textView: NSTextView, string: String, location: Int) {
        guard location > 0 else { return }
        let start = string.index(string.startIndex, offsetBy: location - 1)
        var current = start

        // Skip whitespace/punctuation going backward
        while current > string.startIndex && isWordBoundary(char: string[current]) {
            current = string.index(before: current)
        }
        // Skip word characters
        while current > string.startIndex && !isWordBoundary(char: string[string.index(before: current)]) {
            current = string.index(before: current)
        }

        let newLocation = string.distance(from: string.startIndex, to: current)
        textView.setSelectedRange(NSRange(location: newLocation, length: 0))
    }

    private func moveToEndOfFile(textView: NSTextView, string: String) {
        let location = string.count
        textView.setSelectedRange(NSRange(location: location, length: 0))
    }

    private func moveToTopOfFile(textView: NSTextView) {
        textView.setSelectedRange(NSRange(location: 0, length: 0))
    }

    // MARK: - Editing

    private func deleteCharacter(textView: NSTextView, string: String, location: Int) {
        guard location < string.count else { return }
        let range = NSRange(location: location, length: 1)
        textView.insertText("", replacementRange: range)
    }

    private func deleteLine(textView: NSTextView, string: String, location: Int) {
        guard let lineRange = lineRange(for: location, in: string) else { return }
        var rangeToDelete = lineRange
        // Include newline if not the last line
        if lineRange.upperBound < string.count {
            rangeToDelete = NSRange(location: lineRange.location, length: lineRange.length + 1)
        }
        textView.insertText("", replacementRange: rangeToDelete)
    }

    private func yankLine(textView: NSTextView, string: String, location: Int) {
        guard let lineRange = lineRange(for: location, in: string) else { return }
        let line = (string as NSString).substring(with: lineRange)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(line, forType: .string)
    }

    private func paste(textView: NSTextView) {
        guard let pasteboardString = NSPasteboard.general.string(forType: .string) else { return }
        textView.insertText(pasteboardString, replacementRange: textView.selectedRange())
    }

    private func insertNewlineAfterCurrentLine(textView: NSTextView, string: String, location: Int) {
        guard let lineRange = lineRange(for: location, in: string) else { return }
        let insertLocation = lineRange.upperBound
        textView.setSelectedRange(NSRange(location: insertLocation, length: 0))
        textView.insertNewline(nil)
    }

    private func insertNewlineBeforeCurrentLine(textView: NSTextView, string: String, location: Int) {
        guard let lineRange = lineRange(for: location, in: string) else { return }
        textView.setSelectedRange(NSRange(location: lineRange.location, length: 0))
        textView.insertNewline(nil)
        textView.setSelectedRange(NSRange(location: lineRange.location, length: 0))
    }

    // MARK: - Visual Mode Selection

    private func extendSelectionLeft(textView: NSTextView) {
        let range = textView.selectedRange()
        guard range.location > 0 else { return }
        textView.setSelectedRange(NSRange(location: range.location - 1, length: range.length + 1))
    }

    private func extendSelectionRight(textView: NSTextView, string: String) {
        let range = textView.selectedRange()
        guard range.location + range.length < string.count else { return }
        textView.setSelectedRange(NSRange(location: range.location, length: range.length + 1))
    }

    private func extendSelectionUp(textView: NSTextView) {
        // Simplified: move start up by one line
        let range = textView.selectedRange()
        guard let currentLineRange = lineRange(for: range.location, in: textView.string),
              let previousLineRange = previousLine(from: currentLineRange, in: textView.string) else { return }
        let column = range.location - currentLineRange.location
        let newStart = min(previousLineRange.location + column, previousLineRange.upperBound - 1)
        let newStartLocation = max(newStart, previousLineRange.location)
        let newLength = range.length + (range.location - newStartLocation)
        textView.setSelectedRange(NSRange(location: newStartLocation, length: newLength))
    }

    private func extendSelectionDown(textView: NSTextView) {
        let range = textView.selectedRange()
        guard let currentLineRange = lineRange(for: range.location + range.length, in: textView.string),
              let nextLineRange = nextLine(from: currentLineRange, in: textView.string) else { return }
        let column = (range.location + range.length) - currentLineRange.location
        let newEnd = min(nextLineRange.location + column, nextLineRange.upperBound - 1)
        let newEndLocation = max(newEnd, nextLineRange.location)
        let newLength = newEndLocation - range.location + 1
        textView.setSelectedRange(NSRange(location: range.location, length: newLength))
    }

    private func deleteSelection(textView: NSTextView) {
        textView.insertText("", replacementRange: textView.selectedRange())
    }

    private func copySelection(textView: NSTextView) {
        let selected = textView.string
        let range = textView.selectedRange()
        guard range.length > 0 else { return }
        let substring = (selected as NSString).substring(with: range)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(substring, forType: .string)
    }

    // MARK: - Commands

    private func executeCommand(_ command: String, textView: NSTextView, string: String, location: Int) -> Bool {
        switch command {
        case "dd":
            deleteLine(textView: textView, string: string, location: location)
            return true
        case "yy":
            yankLine(textView: textView, string: string, location: location)
            return true
        case "gg":
            moveToTopOfFile(textView: textView)
            return true
        default:
            return true // Swallow unknown commands
        }
    }

    // MARK: - Helpers

    private func lineRange(for location: Int, in string: String) -> NSRange? {
        guard location <= string.count else { return nil }
        return (string as NSString).lineRange(for: NSRange(location: location, length: 0))
    }

    private func previousLine(from currentLine: NSRange, in string: String) -> NSRange? {
        guard currentLine.location > 0 else { return nil }
        return lineRange(for: currentLine.location - 1, in: string)
    }

    private func nextLine(from currentLine: NSRange, in string: String) -> NSRange? {
        let nextLocation = currentLine.upperBound
        guard nextLocation < string.count else { return nil }
        return lineRange(for: nextLocation, in: string)
    }

    private func isWordBoundary(char: Character) -> Bool {
        return char.isWhitespace || char.isPunctuation
    }
}

// MARK: - VimTextView SwiftUI Wrapper

struct VimTextView: NSViewRepresentable {
    var initialText: String
    var onTextChange: (String) -> Void
    @ObservedObject var engine: VimEngine

    func makeNSView(context: Context) -> NSScrollView {
        let textView = VimTextViewSubclass()
        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.autoresizingMask = [.width, .height]

        textView.isRichText = false
        textView.font = NSFont.systemFont(ofSize: 14)
        textView.textContainerInset = NSSize(width: 12, height: 12)
        textView.autoresizingMask = [.width, .height]
        textView.delegate = context.coordinator
        textView.engine = engine
        engine.textView = textView
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.insertionPointColor = NSColor.labelColor
        textView.textColor = NSColor.labelColor
        textView.onTextChange = onTextChange

        textView.string = initialText

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        // Ensure the text view is the first responder so it receives key events
        guard let textView = nsView.documentView as? VimTextViewSubclass else { return }
        if let window = textView.window, window.isKeyWindow {
            window.makeFirstResponder(textView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: VimTextView

        init(_ parent: VimTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            // Intentionally empty — didChangeText handles the callback directly
        }
    }
}

// MARK: - Custom NSTextView Subclass

class VimTextViewSubclass: NSTextView {
    weak var engine: VimEngine?
    var onTextChange: ((String) -> Void)?
    static weak var activeInstance: VimTextViewSubclass?
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let window = self.window {
            window.makeFirstResponder(self)
        }
    }

    override func becomeFirstResponder() -> Bool {
        VimTextViewSubclass.activeInstance = self
        return super.becomeFirstResponder()
    }

    override func keyDown(with event: NSEvent) {
        // Let Command-modified keys propagate to the menu system
        if event.modifierFlags.contains(.command) {
            super.keyDown(with: event)
            return
        }

        guard let engine else {
            super.keyDown(with: event)
            return
        }

        let handled = engine.handleKeyEvent(event, in: self)
        if !handled {
            super.keyDown(with: event)
        }
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        // Allow performKeyEquivalent to handle menu shortcuts before keyDown
        return super.performKeyEquivalent(with: event)
    }

    override func insertNewline(_ sender: Any?) {
        // Allow newline insertion in insert mode
        super.insertNewline(sender)
    }

    override func insertText(_ insertString: Any, replacementRange: NSRange) {
        super.insertText(insertString, replacementRange: replacementRange)
        onTextChange?(self.string)
    }

    override var acceptsFirstResponder: Bool { true }
}
