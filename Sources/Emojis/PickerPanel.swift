import AppKit
import Carbon.HIToolbox
import SwiftUI

/// Panell flotant que pot rebre el teclat sense activar l'app,
/// així l'app on escrivies continua sent la de davant (com Spotlight).
private final class KeyPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class PickerPanelController: NSObject, NSWindowDelegate {
    let model: PickerModel
    /// L'app on s'enganxarà l'emoji.
    private(set) var targetApp: NSRunningApplication?
    private let panel: KeyPanel
    private var keyMonitor: Any?

    init(model: PickerModel) {
        self.model = model
        panel = KeyPanel(contentRect: NSRect(origin: .zero, size: PickerView.size),
                         styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
                         backing: .buffered, defer: true)
        super.init()

        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        for button in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
            panel.standardWindowButton(button)?.isHidden = true
        }
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.delegate = self

        let background = NSVisualEffectView()
        background.material = .popover
        background.blendingMode = .behindWindow
        background.state = .active
        let host = NSHostingView(rootView: PickerView(model: model))
        host.translatesAutoresizingMaskIntoConstraints = false
        background.addSubview(host)
        NSLayoutConstraint.activate([
            host.leadingAnchor.constraint(equalTo: background.leadingAnchor),
            host.trailingAnchor.constraint(equalTo: background.trailingAnchor),
            host.topAnchor.constraint(equalTo: background.topAnchor),
            host.bottomAnchor.constraint(equalTo: background.bottomAnchor),
        ])
        panel.contentView = background
    }

    var isVisible: Bool { panel.isVisible }

    func toggle(below anchor: NSView? = nil) {
        if panel.isVisible { close() } else { show(below: anchor) }
    }

    func show(below anchor: NSView? = nil) {
        let front = NSWorkspace.shared.frontmostApplication
        targetApp = front?.processIdentifier == ProcessInfo.processInfo.processIdentifier ? nil : front
        model.prepare()
        position(below: anchor)
        panel.makeKeyAndOrderFront(nil)
        installKeyMonitor()
    }

    func close() {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        keyMonitor = nil
        panel.orderOut(nil)
    }

    func windowDidResignKey(_ notification: Notification) {
        close()
    }

    private func position(below anchor: NSView?) {
        let size = panel.frame.size
        if let window = anchor?.window, let screen = window.screen {
            let visible = screen.visibleFrame
            let x = min(max(window.frame.midX - size.width / 2, visible.minX + 8), visible.maxX - size.width - 8)
            panel.setFrameTopLeftPoint(NSPoint(x: x, y: window.frame.minY - 4))
        } else {
            let mouse = NSEvent.mouseLocation
            let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
            guard let visible = screen?.visibleFrame else { return panel.center() }
            panel.setFrameTopLeftPoint(NSPoint(x: visible.midX - size.width / 2,
                                               y: visible.maxY - visible.height * 0.18))
        }
    }

    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, event.window === self.panel else { return event }
            return self.handle(event) ? nil : event
        }
    }

    /// Retorna true si la tecla l'ha fet servir el selector.
    private func handle(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let command = flags.contains(.command)
        switch Int(event.keyCode) {
        case kVK_Escape:
            if model.query.isEmpty { close() } else { model.query = "" }
        case kVK_Return, kVK_ANSI_KeypadEnter:
            model.chooseSelected(copyOnly: command)
        case kVK_LeftArrow: model.move(dx: -1, dy: 0)
        case kVK_RightArrow: model.move(dx: 1, dy: 0)
        case kVK_UpArrow: model.move(dx: 0, dy: -1)
        case kVK_DownArrow: model.move(dx: 0, dy: 1)
        case kVK_Tab:
            model.jumpSection(by: flags.contains(.shift) ? -1 : 1)
        default:
            guard command else { return false }
            switch event.charactersIgnoringModifiers?.lowercased() {
            case "d": model.toggleFavoriteSelected()
            case "w": close()
            case ",": model.onSettings?(.general, nil)
            default: return false
            }
        }
        return true
    }
}
