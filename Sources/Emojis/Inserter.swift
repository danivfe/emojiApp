import AppKit
import ApplicationServices
import Carbon.HIToolbox

/// Posa l'emoji al porta-retalls i simula ⌘V a l'app de davant.
/// Després torna a deixar el porta-retalls com estava.
@MainActor
enum Inserter {
    static var hasAccessibility: Bool { AXIsProcessTrusted() }

    static func requestAccessibility() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    static func perform(_ output: Output, target: NSRunningApplication?, paste: Bool) {
        let pasteboard = NSPasteboard.general
        let saved = paste ? snapshot(pasteboard) : nil

        pasteboard.clearContents()
        switch output {
        case .text(let text):
            pasteboard.setString(text, forType: .string)
        case .image(let url):
            if let image = NSImage(contentsOf: url) { pasteboard.writeObjects([image]) }
        }

        // Sense permís d'Accessibilitat només queda copiat: es pot enganxar amb ⌘V.
        guard paste else { return }
        guard hasAccessibility else {
            requestAccessibility()
            return
        }

        let changeCount = pasteboard.changeCount
        target?.activate()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            postCommandV()
            let delay: Double = if case .image = output { 1.5 } else { 0.7 }
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if let saved, pasteboard.changeCount == changeCount { restore(saved, to: pasteboard) }
            }
        }
    }

    private static func postCommandV() {
        let source = CGEventSource(stateID: .combinedSessionState)
        for down in [true, false] {
            let event = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: down)
            event?.flags = .maskCommand
            event?.post(tap: .cghidEventTap)
        }
    }

    private static func snapshot(_ pasteboard: NSPasteboard) -> [[(NSPasteboard.PasteboardType, Data)]] {
        (pasteboard.pasteboardItems ?? []).map { item in
            item.types.compactMap { type in item.data(forType: type).map { (type, $0) } }
        }
    }

    private static func restore(_ saved: [[(NSPasteboard.PasteboardType, Data)]], to pasteboard: NSPasteboard) {
        pasteboard.clearContents()
        guard !saved.isEmpty else { return }
        let items = saved.map { pairs in
            let item = NSPasteboardItem()
            for (type, data) in pairs { item.setData(data, forType: type) }
            return item
        }
        pasteboard.writeObjects(items)
    }
}
