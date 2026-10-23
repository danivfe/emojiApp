import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = Store()
    private let settingsState = SettingsState()
    private var statusItem: NSStatusItem!
    private var picker: PickerPanelController!
    private var hotKey: HotKey!
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let model = PickerModel(catalog: Catalog.load(), store: store)
        picker = PickerPanelController(model: model)
        model.onChoose = { [weak self] output, copyOnly in
            guard let self else { return }
            let target = picker.targetApp
            picker.close()
            Inserter.perform(output, target: target, paste: !copyOnly)
        }
        model.onSettings = { [weak self] tab, emoji in
            self?.picker.close()
            self?.openSettings(tab: tab, keywordEmoji: emoji)
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "face.smiling", accessibilityDescription: "Emojis")
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        hotKey = HotKey { [weak self] in self?.picker.toggle() }
        hotKey.register(HotKeyPreset.find(store.prefs.hotKey))
        store.onHotKeyChange = { [weak self] in
            guard let self else { return }
            hotKey.register(HotKeyPreset.find(store.prefs.hotKey))
        }

        // La primera vegada, demana el permís per poder enganxar sol.
        if !Inserter.hasAccessibility, !UserDefaults.standard.bool(forKey: "askedAccessibility") {
            UserDefaults.standard.set(true, forKey: "askedAccessibility")
            Inserter.requestAccessibility()
        }
    }

    @objc private func statusItemClicked() {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            statusItem.menu = makeMenu()
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            picker.toggle(below: statusItem.button)
        }
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        let open = NSMenuItem(title: "Obre el selector (\(HotKeyPreset.find(store.prefs.hotKey).label))",
                              action: #selector(openPicker), keyEquivalent: "")
        menu.addItem(open)
        menu.addItem(NSMenuItem(title: "Configuració…", action: #selector(openSettingsFromMenu), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Obre la carpeta d'imatges", action: #selector(openImagesFolder), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Surt d'Emojis", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        for item in menu.items where item.action != #selector(NSApplication.terminate(_:)) { item.target = self }
        return menu
    }

    @objc private func openPicker() { picker.show(below: statusItem.button) }
    @objc private func openSettingsFromMenu() { openSettings(tab: .general, keywordEmoji: nil) }
    @objc private func openImagesFolder() { NSWorkspace.shared.open(CustomImages.folder) }

    private func openSettings(tab: SettingsTab, keywordEmoji: String?) {
        settingsState.tab = tab
        settingsState.keywordEmoji = keywordEmoji
        if settingsWindow == nil {
            let window = NSWindow(contentViewController: NSHostingController(
                rootView: SettingsView(store: store, state: settingsState)))
            window.title = "Configuració d'Emojis"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }
        NSApp.activate()
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
}
