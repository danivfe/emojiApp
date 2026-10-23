import ServiceManagement
import SwiftUI

enum SettingsTab: Hashable {
    case general, combos, keywords, images
}

@MainActor @Observable
final class SettingsState {
    var tab = SettingsTab.general
    /// Emoji triat des del menú contextual per afegir-li una paraula clau.
    var keywordEmoji: String?
}

struct SettingsView: View {
    @Bindable var store: Store
    @Bindable var state: SettingsState
    let updater: Updater

    var body: some View {
        TabView(selection: $state.tab) {
            GeneralTab(store: store, updater: updater)
                .tabItem { Label(Tr.general.text, systemImage: "gearshape") }
                .tag(SettingsTab.general)
            CombosTab(store: store)
                .tabItem { Label(Tr.combos.text, systemImage: "sparkles") }
                .tag(SettingsTab.combos)
            KeywordsTab(store: store, state: state)
                .tabItem { Label(Tr.keywords.text, systemImage: "text.magnifyingglass") }
                .tag(SettingsTab.keywords)
            ImagesTab()
                .tabItem { Label(Tr.myEmojis.text, systemImage: "photo") }
                .tag(SettingsTab.images)
        }
        .padding(20)
        .frame(width: 560, height: 540)
    }
}

private struct GeneralTab: View {
    @Bindable var store: Store
    let updater: Updater
    @State private var autoUpdate = true
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var trusted = Inserter.hasAccessibility
    private let timer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    var body: some View {
        Form {
            Picker(Tr.language.text, selection: $store.prefs.language) {
                Text(Tr.languageAutomatic.text).tag(String?.none)
                Divider()
                ForEach(AppLanguage.allCases) { Text($0.nativeName).tag(Optional($0.rawValue)) }
            }
            Picker(Tr.shortcut.text, selection: $store.prefs.hotKey) {
                ForEach(HotKeyPreset.all) { Text($0.label).tag($0.id) }
            }
            Picker(Tr.skinTone.text, selection: Binding(get: { store.tone }, set: { store.tone = $0 })) {
                ForEach(SkinTone.allCases) { Text("\($0.sample)  \($0.label)").tag($0) }
            }
            Toggle(Tr.launchAtLogin.text, isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, enabled in
                    try? enabled ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
                    launchAtLogin = SMAppService.mainApp.status == .enabled
                }

            Section(Tr.autoPaste.text) {
                if trusted {
                    Label(Tr.accessibilityOn.text, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Label(Tr.accessibilityOff.text, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Button(Tr.openAccessibility.text) { Inserter.openAccessibilitySettings() }
                }
            }

            Section(Tr.updates.text) {
                Toggle(Tr.autoUpdate.text, isOn: $autoUpdate)
                    .onChange(of: autoUpdate) { _, on in updater.automatic = on }
                HStack {
                    Text(Tr.versionLabel.format(Updater.currentVersion)).foregroundStyle(.secondary)
                    Spacer()
                    switch updater.status {
                    case .checking: Text(Tr.checking.text).foregroundStyle(.secondary)
                    case .downloading: Text(Tr.downloading.text).foregroundStyle(.secondary)
                    default: EmptyView()
                    }
                    Button(Tr.checkNow.text) { Task { await updater.check(userInitiated: true) } }
                        .disabled(updater.status == .checking || updater.status == .downloading)
                }
            }

            Section(Tr.history.text) {
                Button(Tr.clearRecents.text) { store.prefs.recents = [] }
                    .disabled(store.prefs.recents.isEmpty)
            }
        }
        .formStyle(.grouped)
        .onAppear { autoUpdate = updater.automatic }
        .onReceive(timer) { _ in trusted = Inserter.hasAccessibility }
    }
}

private struct CombosTab: View {
    @Bindable var store: Store

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Tr.combosHelp.text)
                .foregroundStyle(.secondary)
            List {
                ForEach($store.prefs.combos) { $combo in
                    HStack {
                        TextField(Tr.name.text, text: $combo.name).frame(width: 150)
                        TextField(Tr.emojisOrText.text, text: $combo.text)
                        Button(role: .destructive) {
                            store.prefs.combos.removeAll { $0.id == combo.id }
                        } label: { Image(systemName: "trash") }
                            .buttonStyle(.borderless)
                    }
                }
                .onMove { store.prefs.combos.move(fromOffsets: $0, toOffset: $1) }
            }
            Button(Tr.addCombo.text, systemImage: "plus") {
                store.prefs.combos.append(Combo(name: Tr.newCombo.text, text: ""))
            }
        }
    }
}

private struct KeywordsTab: View {
    @Bindable var store: Store
    @Bindable var state: SettingsState
    @State private var newWord = ""
    @State private var newEmoji = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Tr.keywordsHelp.text)
                .foregroundStyle(.secondary)
            HStack {
                TextField(Tr.wordExample.text, text: $newWord)
                TextField(Tr.emoji.text, text: $newEmoji).frame(width: 80)
                Button(Tr.add.text) {
                    store.prefs.keywords.insert(
                        CustomKeyword(word: newWord.trimmingCharacters(in: .whitespaces),
                                      emoji: newEmoji.trimmingCharacters(in: .whitespaces)), at: 0)
                    newWord = ""
                    newEmoji = ""
                }
                .disabled(newWord.trimmingCharacters(in: .whitespaces).isEmpty || newEmoji.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            List {
                ForEach($store.prefs.keywords) { $keyword in
                    HStack {
                        TextField(Tr.word.text, text: $keyword.word)
                        TextField(Tr.emoji.text, text: $keyword.emoji).frame(width: 80)
                        Button(role: .destructive) {
                            store.prefs.keywords.removeAll { $0.id == keyword.id }
                        } label: { Image(systemName: "trash") }
                            .buttonStyle(.borderless)
                    }
                }
            }
        }
        .onAppear(perform: takeDraft)
        .onChange(of: state.keywordEmoji) { takeDraft() }
    }

    private func takeDraft() {
        guard let emoji = state.keywordEmoji else { return }
        newEmoji = emoji
        newWord = ""
        state.keywordEmoji = nil
    }
}

private struct ImagesTab: View {
    @State private var images = CustomImages.scan()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Tr.imagesHelp.text)
                .foregroundStyle(.secondary)
            HStack {
                Button(Tr.addImages.text, systemImage: "plus") {
                    CustomImages.importWithPanel()
                    images = CustomImages.scan()
                }
                Button(Tr.openFolder.text, systemImage: "folder") {
                    NSWorkspace.shared.open(CustomImages.folder)
                }
                Spacer()
                Button(Tr.refresh.text, systemImage: "arrow.clockwise") { images = CustomImages.scan() }
            }
            if images.isEmpty {
                ContentUnavailableView(Tr.noImages.text, systemImage: "photo.on.rectangle",
                                       description: Text(Tr.noImagesHelp.text))
            } else {
                List(images) { item in
                    HStack {
                        if let url = item.imageURL, let image = NSImage(contentsOf: url) {
                            Image(nsImage: image).resizable().scaledToFit().frame(width: 32, height: 32)
                        }
                        Text(item.name)
                        Spacer()
                        Button {
                            if let url = item.imageURL { try? FileManager.default.trashItem(at: url, resultingItemURL: nil) }
                            images = CustomImages.scan()
                        } label: { Image(systemName: "trash") }
                            .buttonStyle(.borderless)
                            .help(Tr.moveToTrash.text)
                    }
                }
            }
        }
    }
}
