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

    var body: some View {
        TabView(selection: $state.tab) {
            GeneralTab(store: store)
                .tabItem { Label("General", systemImage: "gearshape") }
                .tag(SettingsTab.general)
            CombosTab(store: store)
                .tabItem { Label("Combinacions", systemImage: "sparkles") }
                .tag(SettingsTab.combos)
            KeywordsTab(store: store, state: state)
                .tabItem { Label("Paraules clau", systemImage: "text.magnifyingglass") }
                .tag(SettingsTab.keywords)
            ImagesTab()
                .tabItem { Label("Els meus emojis", systemImage: "photo") }
                .tag(SettingsTab.images)
        }
        .padding(20)
        .frame(width: 560, height: 440)
    }
}

private struct GeneralTab: View {
    @Bindable var store: Store
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var trusted = Inserter.hasAccessibility
    private let timer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    var body: some View {
        Form {
            Picker("Drecera per obrir el selector", selection: $store.prefs.hotKey) {
                ForEach(HotKeyPreset.all) { Text($0.label).tag($0.id) }
            }
            Picker("To de pell", selection: Binding(get: { store.tone }, set: { store.tone = $0 })) {
                ForEach(SkinTone.allCases) { Text("\($0.sample)  \($0.label)").tag($0) }
            }
            Toggle("Obre Emojis en iniciar la sessió", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, enabled in
                    try? enabled ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
                    launchAtLogin = SMAppService.mainApp.status == .enabled
                }

            Section("Enganxar automàticament") {
                if trusted {
                    Label("Permís d'Accessibilitat activat", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Label("Sense el permís d'Accessibilitat, l'emoji només es copia (l'has d'enganxar amb ⌘V).",
                          systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Button("Obre Configuració del Sistema › Accessibilitat") { Inserter.openAccessibilitySettings() }
                }
            }

            Section("Historial") {
                Button("Esborra els recents") { store.prefs.recents = [] }
                    .disabled(store.prefs.recents.isEmpty)
            }
        }
        .formStyle(.grouped)
        .onReceive(timer) { _ in trusted = Inserter.hasAccessibility }
    }
}

private struct CombosTab: View {
    @Bindable var store: Store

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Grups d'emojis o frases que s'enganxen d'un sol cop. Surten a la secció ✨ i es poden cercar pel nom.")
                .foregroundStyle(.secondary)
            List {
                ForEach($store.prefs.combos) { $combo in
                    HStack {
                        TextField("Nom", text: $combo.name).frame(width: 150)
                        TextField("Emojis o text", text: $combo.text)
                        Button(role: .destructive) {
                            store.prefs.combos.removeAll { $0.id == combo.id }
                        } label: { Image(systemName: "trash") }
                            .buttonStyle(.borderless)
                    }
                }
                .onMove { store.prefs.combos.move(fromOffsets: $0, toOffset: $1) }
            }
            Button("Afegeix una combinació", systemImage: "plus") {
                store.prefs.combos.append(Combo(name: "Nova", text: ""))
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
            Text("Paraules teves per trobar un emoji més de pressa. Si escrius la paraula al cercador, aquest emoji surt el primer.")
                .foregroundStyle(.secondary)
            HStack {
                TextField("Paraula (p. ex. visca)", text: $newWord)
                TextField("Emoji", text: $newEmoji).frame(width: 80)
                Button("Afegeix") {
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
                        TextField("Paraula", text: $keyword.word)
                        TextField("Emoji", text: $keyword.emoji).frame(width: 80)
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
            Text("Imatges teves (PNG, JPG, GIF…) que pots enganxar com si fossin emojis a Missatges, WhatsApp, Mail, etc. Es cerquen pel nom del fitxer.")
                .foregroundStyle(.secondary)
            HStack {
                Button("Afegeix imatges…", systemImage: "plus") {
                    CustomImages.importWithPanel()
                    images = CustomImages.scan()
                }
                Button("Obre la carpeta", systemImage: "folder") {
                    NSWorkspace.shared.open(CustomImages.folder)
                }
                Spacer()
                Button("Actualitza", systemImage: "arrow.clockwise") { images = CustomImages.scan() }
            }
            if images.isEmpty {
                ContentUnavailableView("Encara no n'hi ha cap", systemImage: "photo.on.rectangle",
                                       description: Text("Afegeix-hi imatges per veure-les a la secció 🖼️ del selector."))
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
                            .help("Mou a la paperera")
                    }
                }
            }
        }
    }
}
