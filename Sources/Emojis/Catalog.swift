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
    /// Nom del grup d'Unicode en anglès; es tradueix amb `Tr.group`.
    let key: String
    let icon: String
    let items: [PickerItem]
}

/// Passa a minúscules i treu accents, perquè "cafe" trobi "cafè".
func normalize(_ s: String) -> String {
    s.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
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
        let e: String, en: String, v: Double, g: String
        let t: [String]?
    }

    private struct Names: Decodable {
        let n: String
        let k: [String]
    }

    private static let groupIcons = [
        "Smileys & Emotion": "😀", "People & Body": "👋", "Animals & Nature": "🐻",
        "Food & Drink": "🍔", "Travel & Places": "✈️", "Activities": "⚽",
        "Objects": "💡", "Symbols": "🔣", "Flags": "🏁",
    ]

    private static func resource(_ name: String) -> URL {
        Bundle.main.url(forResource: name, withExtension: "json")
            ?? URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Resources/\(name).json")
    }

    private static func decode<T: Decodable>(_ type: T.Type, _ name: String) -> T? {
        try? JSONDecoder().decode(type, from: Data(contentsOf: resource(name)))
    }

    static func load(language: AppLanguage) -> Catalog {
        let records = decode([Record].self, "emojis") ?? []
        let names = decode([String: Names].self, "names-\(language.rawValue)") ?? [:]
        let maxVersion = supportedEmojiVersion(records)

        var order: [String] = []
        var grouped: [String: [PickerItem]] = [:]
        for r in records where r.v <= maxVersion {
            if grouped[r.g] == nil { order.append(r.g) }
            let local = names[r.e]
            let name = local?.n ?? r.en
            // El nom anglès també es pot cercar, sigui quin sigui l'idioma
            grouped[r.g, default: []].append(PickerItem(
                id: r.e, kind: .emoji, text: r.e, name: name, tones: r.t,
                tokens: searchTokens([name] + (local?.k ?? []) + [r.en])))
        }
        let groups = order.map { EmojiGroup(key: $0, icon: groupIcons[$0] ?? "•", items: grouped[$0]!) }

        let characters = Extras.characters.map { entry in
            let name = entry.name(language)
            return PickerItem(id: "c:" + entry.text, kind: .character, text: entry.text, name: name,
                              tokens: searchTokens([name]))
        }
        let kaomoji = Extras.kaomoji.map { entry in
            let name = entry.name(language)
            return PickerItem(id: "k:" + entry.text, kind: .kaomoji, text: entry.text, name: name,
                              tokens: searchTokens([name]))
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
    struct Entry {
        let text: String
        let ca: String, es: String, en: String
        func name(_ lang: AppLanguage) -> String { lang.pick(ca, es, en) }
    }

    private static func e(_ text: String, _ ca: String, _ es: String, _ en: String) -> Entry {
        Entry(text: text, ca: ca, es: es, en: en)
    }

    static let characters: [Entry] = [
        e("l·l", "ela geminada", "ele geminada catalán", "catalan middle dot l"),
        e("·", "punt volat", "punto medio", "middle dot"),
        e("«", "cometes baixes obertura", "comillas angulares apertura", "left guillemet quote"),
        e("»", "cometes baixes tancament", "comillas angulares cierre", "right guillemet quote"),
        e("—", "guió llarg", "raya guion largo", "em dash"),
        e("–", "guió mitjà", "guion medio", "en dash"),
        e("…", "punts suspensius", "puntos suspensivos", "ellipsis"),
        e("€", "euro", "euro", "euro"),
        e("°", "grau graus temperatura", "grado grados temperatura", "degree temperature"),
        e("ª", "ordinal femení", "ordinal femenino", "feminine ordinal"),
        e("º", "ordinal masculí", "ordinal masculino", "masculine ordinal"),
        e("✓", "fet comprovat check", "hecho comprobado check", "check mark done"),
        e("✗", "creu malament", "cruz mal", "cross wrong"),
        e("→", "fletxa dreta", "flecha derecha", "right arrow"),
        e("←", "fletxa esquerra", "flecha izquierda", "left arrow"),
        e("↑", "fletxa amunt", "flecha arriba", "up arrow"),
        e("↓", "fletxa avall", "flecha abajo", "down arrow"),
        e("↔", "fletxa doble", "flecha doble", "left right arrow"),
        e("⇒", "per tant implica", "por tanto implica", "therefore implies"),
        e("•", "pic llista", "viñeta lista", "bullet list"),
        e("×", "per multiplicar", "por multiplicar", "times multiply"),
        e("÷", "dividit", "dividido", "divide"),
        e("±", "més menys", "más menos", "plus minus"),
        e("≈", "aproximadament", "aproximadamente", "approximately"),
        e("≠", "diferent", "distinto", "not equal"),
        e("≤", "menor o igual", "menor o igual", "less or equal"),
        e("≥", "major o igual", "mayor o igual", "greater or equal"),
        e("∞", "infinit", "infinito", "infinity"),
        e("½", "mig meitat", "medio mitad", "half"),
        e("¼", "quart", "cuarto", "quarter"),
        e("¾", "tres quarts", "tres cuartos", "three quarters"),
        e("²", "al quadrat", "al cuadrado", "squared"),
        e("³", "al cub", "al cubo", "cubed"),
        e("‰", "per mil", "por mil", "per mille"),
        e("π", "pi", "pi", "pi"),
        e("µ", "micro", "micro", "micro"),
        e("©", "copyright", "copyright", "copyright"),
        e("®", "marca registrada", "marca registrada", "registered"),
        e("™", "marca comercial", "marca comercial", "trademark"),
        e("§", "secció", "sección", "section"),
        e("¶", "paràgraf", "párrafo", "paragraph"),
        e("†", "creu mort", "cruz muerte", "dagger"),
        e("★", "estrella plena", "estrella llena", "black star"),
        e("☆", "estrella buida", "estrella vacía", "white star"),
        e("♥", "cor", "corazón", "heart"),
        e("♪", "nota música", "nota música", "music note"),
        e("☐", "casella buida", "casilla vacía", "empty box"),
        e("☑", "casella marcada", "casilla marcada", "checked box"),
        e("⌘", "tecla ordre command", "tecla comando command", "command key"),
        e("⌥", "tecla opció option", "tecla opción option", "option key"),
        e("⇧", "tecla majúscules shift", "tecla mayúsculas shift", "shift key"),
        e("⌃", "tecla control", "tecla control", "control key"),
    ]

    static let kaomoji: [Entry] = [
        e("¯\\_(ツ)_/¯", "arronsar espatlles no ho sé", "encogerse de hombros no sé", "shrug dunno"),
        e("(╯°□°)╯︵ ┻━┻", "llançar taula ràbia enfadat", "tirar mesa rabia enfadado", "table flip angry rage"),
        e("┬─┬ノ( º _ ºノ)", "posar taula calma", "poner mesa calma", "put table back calm"),
        e("( ͡° ͜ʖ ͡°)", "picardia picantó", "pícaro picardía", "lenny smirk"),
        e("ಠ_ಠ", "desaprovació mirada", "desaprobación mirada", "disapproval look"),
        e("(^_^)", "content somriure", "contento sonrisa", "happy smile"),
        e("(≧▽≦)", "molt content emoció", "muy contento emoción", "very happy excited"),
        e("(◕‿◕)", "dolç somriure", "dulce sonrisa", "sweet smile"),
        e("(｡♥‿♥｡)", "enamorat amor", "enamorado amor", "in love"),
        e("(づ｡◕‿‿◕｡)づ", "abraçada", "abrazo", "hug"),
        e("\\(^o^)/", "visca celebració hurra", "viva celebración hurra", "hooray celebrate yay"),
        e("(ノ◕ヮ◕)ノ*:･ﾟ✧", "màgia celebració felicitats", "magia celebración felicidades", "magic sparkle celebrate"),
        e("(⊙_⊙)", "sorprès sorpresa", "sorprendido sorpresa", "surprised shocked"),
        e("(T_T)", "plorar trist", "llorar triste", "cry sad"),
        e("(╥﹏╥)", "plorar molt trist", "llorar muy triste", "crying very sad"),
        e("(｡•́︿•̀｡)", "pena trist", "pena triste", "sad pout"),
        e("(-_-) zzZ", "dormir son", "dormir sueño", "sleep sleepy"),
        e("(¬_¬)", "sospita desconfiança", "sospecha desconfianza", "suspicious"),
        e("(>_<)", "uf mal dolor", "uf mal dolor", "ugh pain"),
        e("( •_•)>⌐■-■", "ulleres guai", "gafas guay", "sunglasses cool deal with it"),
        e("(☞ﾟヮﾟ)☞", "tu assenyalar", "tú señalar", "you point"),
        e("ʕ•ᴥ•ʔ", "ós", "oso", "bear"),
        e("(=^･ω･^=)", "gat", "gato", "cat"),
        e("<(￣︶￣)>", "orgullós satisfet", "orgulloso satisfecho", "proud satisfied"),
        e("ᕦ(ò_óˇ)ᕤ", "fort força músculs", "fuerte fuerza músculos", "strong flex"),
        e("(っ˘ڡ˘ς)", "menjar bo deliciós", "comida rica delicioso", "yummy delicious food"),
        e("♪~ ᕕ(ᐛ)ᕗ", "ballar música alegre", "bailar música alegre", "dance music happy"),
        e("( ˘▽˘)っ♨", "cafè te calent", "café té caliente", "coffee tea hot"),
    ]
}
