import SwiftUI
import AppKit

struct PlainTextView: NSViewRepresentable {
    var initialText: String
    var onTextChange: (String) -> Void

    func makeNSView(context: Context) -> NSScrollView {
        let textView = PlainTextViewSubclass()
        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.autoresizingMask = [.width, .height]

        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = NSFont.systemFont(ofSize: 14)
        textView.textContainerInset = NSSize(width: 12, height: 12)
        textView.autoresizingMask = [.width, .height]
        textView.delegate = context.coordinator

        textView.backgroundColor = NSColor.textBackgroundColor
        textView.insertionPointColor = NSColor.labelColor
        textView.textColor = NSColor.labelColor
        textView.usesFindBar = true

        textView.string = initialText

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? PlainTextViewSubclass else { return }
        if let window = textView.window,
           window.isKeyWindow,
           window.firstResponder === window {
            window.makeFirstResponder(textView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: PlainTextView

        init(_ parent: PlainTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.onTextChange(textView.string)
        }
    }
}

class PlainTextViewSubclass: NSTextView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let window = self.window {
            window.makeFirstResponder(self)
        }
    }

    override var acceptsFirstResponder: Bool { true }

    override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        if item.action == Selector(("undo:")) {
            return undoManager?.canUndo ?? false
        }
        if item.action == Selector(("redo:")) {
            return undoManager?.canRedo ?? false
        }
        return super.validateUserInterfaceItem(item)
    }
}
