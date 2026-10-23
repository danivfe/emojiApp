import AppKit
import CoreText

/// Qualsevol cosa que es pot triar al selector.
struct PickerItem: Identifiable, Hashable {
    enum Kind: Hashable { case emoji, character, kaomoji, combo, image }

    let id: String
    let kind: Kind
    /// El que s'enganxa (sense to de pell aplicat).
    let text: String
    let name: String
    var tones: [String]? = nil
    var imageURL: URL? = nil
    /// Paraules de cerca ja normalitzades.
    var tokens: [String] = []

    /// Cap en una casella petita (es pot desar a preferits i recents).
    var isCompact: Bool { kind == .emoji || kind == .character || kind == .image }

    func output(tone: SkinTone) -> String {
        if tone != .none, let tones { return tones[tone.rawValue - 1] }
        return text
    }
}

struct EmojiGroup {
    let name: String
    let icon: String
    let items: [PickerItem]
}

/// Passa a minúscules i treu accents, perquè "cafe" trobi "cafè".
func normalize(_ s: String) -> String {
    s.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "ca"))
        .replacingOccurrences(of: "’", with: "'")
}

func searchTokens(_ phrases: [String]) -> [String] {
    var tokens = Set<String>()
    for phrase in phrases {
        let n = normalize(phrase)
        tokens.insert(n)
        for word in n.split(whereSeparator: { !$0.isLetter && !$0.isNumber && $0 != "+" }) {
            tokens.insert(String(word))
        }
    }
    return Array(tokens)
}

struct Catalog {
    let groups: [EmojiGroup]
    let characters: [PickerItem]
    let kaomoji: [PickerItem]
    let byID: [String: PickerItem]

    private struct Record: Decodable {
        let e: String, n: String, k: [String], en: String, v: Double, g: String
        let t: [String]?
    }

    private static let groupIcons = [
        "Cares i emocions": "😀", "Persones i cos": "👋", "Animals i natura": "🐻",
        "Menjar i beure": "🍔", "Viatges i llocs": "✈️", "Activitats": "⚽",
        "Objectes": "💡", "Símbols": "🔣", "Banderes": "🏁",
    ]

    static func load() -> Catalog {
        let url = Bundle.main.url(forResource: "emojis", withExtension: "json")
            ?? URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Resources/emojis.json")
        let records = (try? JSONDecoder().decode([Record].self, from: Data(contentsOf: url))) ?? []
        let maxVersion = supportedEmojiVersion(records)

        var order: [String] = []
        var grouped: [String: [PickerItem]] = [:]
        for r in records where r.v <= maxVersion {
            if grouped[r.g] == nil { order.append(r.g) }
            grouped[r.g, default: []].append(PickerItem(
                id: r.e, kind: .emoji, text: r.e, name: r.n, tones: r.t,
                tokens: searchTokens([r.n] + r.k + [r.en])))
        }
        let groups = order.map { EmojiGroup(name: $0, icon: groupIcons[$0] ?? "•", items: grouped[$0]!) }

        let characters = Extras.characters.map {
            PickerItem(id: "c:" + $0.0, kind: .character, text: $0.0, name: $0.1, tokens: searchTokens([$0.1]))
        }
        let kaomoji = Extras.kaomoji.map {
            PickerItem(id: "k:" + $0.0, kind: .kaomoji, text: $0.0, name: $0.1, tokens: searchTokens([$0.1]))
        }

        var byID: [String: PickerItem] = [:]
        for item in groups.flatMap(\.items) + characters + kaomoji { byID[item.id] = item }
        return Catalog(groups: groups, characters: characters, kaomoji: kaomoji, byID: byID)
    }

    /// Les dades d'Unicode poden ser més noves que la font d'emojis del Mac.
    /// Amaguem les versions que el sistema encara no sap dibuixar.
    private static func supportedEmojiVersion(_ records: [Record]) -> Double {
        let font = CTFontCreateWithName("AppleColorEmoji" as CFString, 20, nil)
        let versions = Set(records.map(\.v)).sorted(by: >)
        for v in versions {
            guard let sample = records.first(where: { $0.v == v && $0.e.unicodeScalars.count == 1 }) else { continue }
            var chars = Array(sample.e.utf16)
            var glyphs = [CGGlyph](repeating: 0, count: chars.count)
            if CTFontGetGlyphsForCharacters(font, &chars, &glyphs, chars.count) { return v }
        }
        return versions.last ?? 0
    }
}

enum Extras {
    static let characters: [(String, String)] = [
        ("l·l", "ela geminada"), ("·", "punt volat"), ("«", "cometes baixes obertura"), ("»", "cometes baixes tancament"),
        ("—", "guió llarg"), ("–", "guió mitjà"), ("…", "punts suspensius"), ("€", "euro"),
        ("°", "grau graus temperatura"), ("ª", "ordinal femení"), ("º", "ordinal masculí"), ("✓", "fet comprovat check"),
        ("✗", "creu malament"), ("→", "fletxa dreta"), ("←", "fletxa esquerra"), ("↑", "fletxa amunt"),
        ("↓", "fletxa avall"), ("↔", "fletxa doble"), ("⇒", "per tant implica"), ("•", "pic llista"),
        ("×", "per multiplicar"), ("÷", "dividit"), ("±", "més menys"), ("≈", "aproximadament"),
        ("≠", "diferent"), ("≤", "menor o igual"), ("≥", "major o igual"), ("∞", "infinit"),
        ("½", "mig meitat"), ("¼", "quart"), ("¾", "tres quarts"), ("²", "al quadrat"),
        ("³", "al cub"), ("‰", "per mil"), ("π", "pi"), ("µ", "micro"),
        ("©", "copyright"), ("®", "marca registrada"), ("™", "marca comercial"), ("§", "secció"),
        ("¶", "paràgraf"), ("†", "creu mort"), ("★", "estrella plena"), ("☆", "estrella buida"),
        ("♥", "cor"), ("♪", "nota música"), ("☐", "casella buida"), ("☑", "casella marcada"),
        ("⌘", "tecla ordre command"), ("⌥", "tecla opció option"), ("⇧", "tecla majúscules shift"), ("⌃", "tecla control"),
    ]

    static let kaomoji: [(String, String)] = [
        ("¯\\_(ツ)_/¯", "arronsar espatlles no ho sé"), ("(╯°□°)╯︵ ┻━┻", "llançar taula ràbia enfadat"),
        ("┬─┬ノ( º _ ºノ)", "posar taula calma"), ("( ͡° ͜ʖ ͡°)", "picardia picantó"),
        ("ಠ_ಠ", "desaprovació mirada"), ("(^_^)", "content somriure"),
        ("(≧▽≦)", "molt content emoció"), ("(◕‿◕)", "dolç somriure"),
        ("(｡♥‿♥｡)", "enamorat amor"), ("(づ｡◕‿‿◕｡)づ", "abraçada"),
        ("\\(^o^)/", "visca celebració hurra"), ("(ノ◕ヮ◕)ノ*:･ﾟ✧", "màgia celebració felicitats"),
        ("(⊙_⊙)", "sorprès sorpresa"), ("(T_T)", "plorar trist"),
        ("(╥﹏╥)", "plorar molt trist"), ("(｡•́︿•̀｡)", "pena trist"),
        ("(-_-) zzZ", "dormir son"), ("(¬_¬)", "sospita desconfiança"),
        ("(>_<)", "uf mal dolor"), ("( •_•)>⌐■-■", "ulleres guai"),
        ("(☞ﾟヮﾟ)☞", "tu assenyalar"), ("ʕ•ᴥ•ʔ", "ós"),
        ("(=^･ω･^=)", "gat"), ("<(￣︶￣)>", "orgullós satisfet"),
        ("ᕦ(ò_óˇ)ᕤ", "fort força músculs"), ("(っ˘ڡ˘ς)", "menjar bo deliciós"),
        ("♪~ ᕕ(ᐛ)ᕗ", "ballar música alegre"), ("( ˘▽˘)っ♨", "cafè te calent"),
    ]
}
