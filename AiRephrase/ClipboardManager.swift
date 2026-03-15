import AppKit
import Carbon.HIToolbox

@MainActor
enum ClipboardManager {

    // MARK: - Copy selected text (simulates ⌘C)

    static func copySelectedText() async -> String? {
        // Deactivate our app so the previous app gets focus back
        NSApp.hide(nil)

        // Wait for focus to return to the previous app
        try? await Task.sleep(for: .milliseconds(350))

        // Clear clipboard first so we can detect new content
        NSPasteboard.general.clearContents()

        // Simulate ⌘C
        simulateKeyPress(keyCode: UInt16(kVK_ANSI_C), flags: .maskCommand)

        // Wait for the copy to complete
        try? await Task.sleep(for: .milliseconds(350))

        // Read clipboard on main thread
        return NSPasteboard.general.string(forType: .string)
    }

    // MARK: - Paste from clipboard (simulates ⌘V)

    static func pasteFromClipboard() async {
        // Make sure we're not focused
        NSApp.hide(nil)
        try? await Task.sleep(for: .milliseconds(200))

        simulateKeyPress(keyCode: UInt16(kVK_ANSI_V), flags: .maskCommand)
    }

    // MARK: - Set clipboard content

    static func setClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    // MARK: - Simulate key press

    nonisolated private static func simulateKeyPress(keyCode: UInt16, flags: CGEventFlags) {
        let source = CGEventSource(stateID: .hidSystemState)

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        keyDown?.flags = flags
        keyDown?.post(tap: .cghidEventTap)

        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        keyUp?.flags = flags
        keyUp?.post(tap: .cghidEventTap)
    }
}
