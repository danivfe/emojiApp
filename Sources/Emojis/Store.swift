import AppKit
import Carbon.HIToolbox
import Observation

enum SkinTone: Int, CaseIterable, Identifiable {
    case none, light, mediumLight, medium, mediumDark, dark

    var id: Int { rawValue }
    var sample: String { ["👋", "👋🏻", "👋🏼", "👋🏽", "👋🏾", "👋🏿"][rawValue] }
    var label: String { ["Groc (per defecte)", "Clar", "Mitjà clar", "Mitjà", "Mitjà fosc", "Fosc"][rawValue] }
}

struct Combo: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var text: String
}

struct CustomKeyword: Codable, Identifiable, Hashable {
    var id = UUID()
    var word: String
    var emoji: String
}

struct HotKeyPreset: Identifiable {
    let id: String
    let label: String
    let keyCode: UInt32
    let modifiers: UInt32

    static let all = [
        HotKeyPreset(id: "ctrl-opt-e", label: "⌃⌥E", keyCode: UInt32(kVK_ANSI_E), modifiers: UInt32(controlKey | optionKey)),
        HotKeyPreset(id: "opt-cmd-e", label: "⌥⌘E", keyCode: UInt32(kVK_ANSI_E), modifiers: UInt32(optionKey | cmdKey)),
        HotKeyPreset(id: "ctrl-shift-space", label: "⌃⇧Espai", keyCode: UInt32(kVK_Space), modifiers: UInt32(controlKey | shiftKey)),
        HotKeyPreset(id: "ctrl-opt-cmd-e", label: "⌃⌥⌘E", keyCode: UInt32(kVK_ANSI_E), modifiers: UInt32(controlKey | optionKey | cmdKey)),
    ]
    static func find(_ id: String) -> HotKeyPreset { all.first { $0.id == id } ?? all[0] }
}

struct Prefs: Codable {
    var favorites: [String] = []
    var recents: [String] = []
    var skinTone = 0
    var hotKey = HotKeyPreset.all[0].id
    var combos: [Combo] = [
        Combo(name: "Aniversari", text: "🎂🎉🥳"),
        Combo(name: "Felicitats", text: "🎉👏🥂"),
        Combo(name: "Bon dia", text: "Bon dia ☀️☕"),
        Combo(name: "Bona nit", text: "Bona nit 🌙😴"),
        Combo(name: "Gràcies", text: "Gràcies 🙏😊"),
        Combo(name: "Sant Jordi", text: "🌹📚🐉"),
        Combo(name: "Pa amb tomàquet", text: "🍅🥖🫒"),
    ]
    var keywords: [CustomKeyword] = [
        CustomKeyword(word: "visca", emoji: "🎉"),
        CustomKeyword(word: "sant jordi", emoji: "🌹"),
        CustomKeyword(word: "caganer", emoji: "💩"),
        CustomKeyword(word: "calçots", emoji: "🧅"),
        CustomKeyword(word: "ostres", emoji: "😮"),
    ]

    init() {}

    // Llegeix cada camp per separat perquè afegir-ne de nous no esborri la resta.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Prefs()
        favorites = try c.decodeIfPresent([String].self, forKey: .favorites) ?? d.favorites
        recents = try c.decodeIfPresent([String].self, forKey: .recents) ?? d.recents
        skinTone = try c.decodeIfPresent(Int.self, forKey: .skinTone) ?? d.skinTone
        hotKey = try c.decodeIfPresent(String.self, forKey: .hotKey) ?? d.hotKey
        combos = try c.decodeIfPresent([Combo].self, forKey: .combos) ?? d.combos
        keywords = try c.decodeIfPresent([CustomKeyword].self, forKey: .keywords) ?? d.keywords
    }
}

@MainActor @Observable
final class Store {
    var prefs: Prefs {
        didSet {
            save()
            if prefs.hotKey != oldValue.hotKey { onHotKeyChange?() }
        }
    }

    @ObservationIgnored var onHotKeyChange: (() -> Void)?
    private static let key = "prefs"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let saved = try? JSONDecoder().decode(Prefs.self, from: data) {
            prefs = saved
        } else {
            prefs = Prefs()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(prefs) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }

    var tone: SkinTone {
        get { SkinTone(rawValue: prefs.skinTone) ?? .none }
        set { prefs.skinTone = newValue.rawValue }
    }

    func isFavorite(_ id: String) -> Bool { prefs.favorites.contains(id) }

    func toggleFavorite(_ id: String) {
        if let i = prefs.favorites.firstIndex(of: id) {
            prefs.favorites.remove(at: i)
        } else {
            prefs.favorites.append(id)
        }
    }

    func addRecent(_ id: String) {
        var recents = prefs.recents.filter { $0 != id }
        recents.insert(id, at: 0)
        prefs.recents = Array(recents.prefix(18))
    }

    /// Paraules clau pròpies, normalitzades, agrupades per emoji.
    var keywordsByEmoji: [String: [String]] {
        var result: [String: [String]] = [:]
        for k in prefs.keywords where !k.word.isEmpty && !k.emoji.isEmpty {
            result[k.emoji, default: []].append(normalize(k.word.trimmingCharacters(in: .whitespaces)))
        }
        return result
    }
}
