import AppKit
import Carbon.HIToolbox
import Observation

enum SkinTone: Int, CaseIterable, Identifiable {
    case none, light, mediumLight, medium, mediumDark, dark

    var id: Int { rawValue }
    var sample: String { ["👋", "👋🏻", "👋🏼", "👋🏽", "👋🏾", "👋🏿"][rawValue] }
    @MainActor var label: String {
        let lang = LanguageState.shared.current
        switch self {
        case .none: return lang.pick("Groc (per defecte)", "Amarillo (predeterminado)", "Yellow (default)")
        case .light: return lang.pick("Clar", "Claro", "Light")
        case .mediumLight: return lang.pick("Mitjà clar", "Medio claro", "Medium light")
        case .medium: return lang.pick("Mitjà", "Medio", "Medium")
        case .mediumDark: return lang.pick("Mitjà fosc", "Medio oscuro", "Medium dark")
        case .dark: return lang.pick("Fosc", "Oscuro", "Dark")
        }
    }
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
    private let symbols: String
    let keyCode: UInt32
    let modifiers: UInt32

    @MainActor var label: String { symbols.replacingOccurrences(of: "Space", with: Tr.space.text) }

    static let all = [
        HotKeyPreset(id: "ctrl-opt-e", symbols: "⌃⌥E", keyCode: UInt32(kVK_ANSI_E), modifiers: UInt32(controlKey | optionKey)),
        HotKeyPreset(id: "opt-cmd-e", symbols: "⌥⌘E", keyCode: UInt32(kVK_ANSI_E), modifiers: UInt32(optionKey | cmdKey)),
        HotKeyPreset(id: "ctrl-shift-space", symbols: "⌃⇧Space", keyCode: UInt32(kVK_Space), modifiers: UInt32(controlKey | shiftKey)),
        HotKeyPreset(id: "ctrl-opt-cmd-e", symbols: "⌃⌥⌘E", keyCode: UInt32(kVK_ANSI_E), modifiers: UInt32(controlKey | optionKey | cmdKey)),
    ]
    static func find(_ id: String) -> HotKeyPreset { all.first { $0.id == id } ?? all[0] }
}

struct Prefs: Codable {
    var favorites: [String] = []
    var recents: [String] = []
    var skinTone = 0
    var hotKey = HotKeyPreset.all[0].id
    /// nil = el mateix idioma que el sistema.
    var language: String?
    // Les combinacions i paraules d'exemple surten en l'idioma del sistema el primer cop
    var combos = Self.defaultCombos(.system)
    var keywords = Self.defaultKeywords(.system)

    init() {}

    static func defaultCombos(_ lang: AppLanguage) -> [Combo] {
        switch lang {
        case .ca: [
            Combo(name: "Aniversari", text: "🎂🎉🥳"),
            Combo(name: "Felicitats", text: "🎉👏🥂"),
            Combo(name: "Bon dia", text: "Bon dia ☀️☕"),
            Combo(name: "Bona nit", text: "Bona nit 🌙😴"),
            Combo(name: "Gràcies", text: "Gràcies 🙏😊"),
            Combo(name: "Sant Jordi", text: "🌹📚🐉"),
            Combo(name: "Pa amb tomàquet", text: "🍅🥖🫒"),
        ]
        case .es: [
            Combo(name: "Cumpleaños", text: "🎂🎉🥳"),
            Combo(name: "Felicidades", text: "🎉👏🥂"),
            Combo(name: "Buenos días", text: "Buenos días ☀️☕"),
            Combo(name: "Buenas noches", text: "Buenas noches 🌙😴"),
            Combo(name: "Gracias", text: "Gracias 🙏😊"),
            Combo(name: "Fiesta", text: "💃🕺🎶"),
        ]
        case .en: [
            Combo(name: "Birthday", text: "🎂🎉🥳"),
            Combo(name: "Congrats", text: "🎉👏🥂"),
            Combo(name: "Good morning", text: "Good morning ☀️☕"),
            Combo(name: "Good night", text: "Good night 🌙😴"),
            Combo(name: "Thanks", text: "Thanks 🙏😊"),
            Combo(name: "Party", text: "💃🕺🎶"),
        ]
        }
    }

    static func defaultKeywords(_ lang: AppLanguage) -> [CustomKeyword] {
        let pairs: [(String, String)] = switch lang {
        case .ca: [("visca", "🎉"), ("sant jordi", "🌹"), ("caganer", "💩"), ("calçots", "🧅"), ("ostres", "😮")]
        case .es: [("olé", "💃"), ("guay", "😎"), ("vale", "👌"), ("jaja", "😂")]
        case .en: [("yay", "🎉"), ("lol", "😂"), ("omg", "😱"), ("ty", "🙏")]
        }
        return pairs.map { CustomKeyword(word: $0.0, emoji: $0.1) }
    }

    // Llegeix cada camp per separat perquè afegir-ne de nous no esborri la resta.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Prefs()
        favorites = try c.decodeIfPresent([String].self, forKey: .favorites) ?? d.favorites
        recents = try c.decodeIfPresent([String].self, forKey: .recents) ?? d.recents
        skinTone = try c.decodeIfPresent(Int.self, forKey: .skinTone) ?? d.skinTone
        hotKey = try c.decodeIfPresent(String.self, forKey: .hotKey) ?? d.hotKey
        language = try c.decodeIfPresent(String.self, forKey: .language)
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
            if prefs.language != oldValue.language {
                LanguageState.shared.current = language
                onLanguageChange?()
            }
        }
    }

    @ObservationIgnored var onHotKeyChange: (() -> Void)?
    @ObservationIgnored var onLanguageChange: (() -> Void)?
    private static let key = "prefs"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let saved = try? JSONDecoder().decode(Prefs.self, from: data) {
            prefs = saved
        } else {
            prefs = Prefs()
        }
        LanguageState.shared.current = language
    }

    /// L'idioma triat, o el del sistema si és automàtic.
    var language: AppLanguage {
        prefs.language.flatMap(AppLanguage.init(rawValue:)) ?? .system
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
