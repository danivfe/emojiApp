import AppKit
import Observation

struct PickerSection: Identifiable {
    let id: String
    let title: String
    let icon: String
    let columns: Int
    let items: [PickerItem]
}

struct GridRow: Identifiable {
    let id: String
    let section: Int
    let items: [PickerItem]
}

struct ScrollRequest: Equatable {
    let id: String
    let toTop: Bool
    let serial: Int
}

enum Output {
    case text(String)
    case image(URL)
}

@MainActor @Observable
final class PickerModel {
    static let compactColumns = 9

    let catalog: Catalog
    let store: Store

    var query = "" {
        didSet {
            guard query != oldValue else { return }
            rebuild()
            select(row: 0, col: 0, scroll: true)
        }
    }

    private(set) var sections: [PickerSection] = []
    private(set) var rows: [GridRow] = []
    private(set) var sectionRows: [Range<Int>] = []
    private(set) var selRow = 0
    private(set) var selCol = 0
    private(set) var scrollRequest: ScrollRequest?
    /// Canvia cada cop que s'obre el panell, perquè el cercador agafi el focus.
    private(set) var focusToken = 0

    @ObservationIgnored var onChoose: ((Output, Bool) -> Void)?
    @ObservationIgnored var onSettings: ((SettingsTab, String?) -> Void)?
    @ObservationIgnored private var images: [PickerItem] = []
    @ObservationIgnored private var thumbnails: [URL: NSImage] = [:]
    @ObservationIgnored private var scrollSerial = 0
    @ObservationIgnored private var mouseAtLastKey = NSPoint.zero

    init(catalog: Catalog, store: Store) {
        self.catalog = catalog
        self.store = store
        rebuild()
    }

    var tone: SkinTone { store.tone }

    var selected: PickerItem? {
        guard rows.indices.contains(selRow), rows[selRow].items.indices.contains(selCol) else { return nil }
        return rows[selRow].items[selCol]
    }

    var selectedSection: Int? { rows.indices.contains(selRow) ? rows[selRow].section : nil }

    func isSelected(row: Int, col: Int) -> Bool { row == selRow && col == selCol }

    // MARK: - Obrir

    func prepare() {
        images = CustomImages.scan()
        thumbnails.removeAll()
        if query.isEmpty { rebuild() } else { query = "" }
        select(row: 0, col: 0, scroll: false)
        scrollRequest = sections.first.map { ScrollRequest(id: "h:" + $0.id, toTop: true, serial: nextSerial()) }
        focusToken += 1
    }

    // MARK: - Seccions

    func rebuild() {
        var result: [PickerSection] = []
        let q = normalize(query.trimmingCharacters(in: .whitespaces))
        if q.isEmpty {
            let favorites = resolve(store.prefs.favorites)
            if !favorites.isEmpty { result.append(compact("fav", "Preferits", "⭐️", favorites)) }
            let recents = resolve(store.prefs.recents)
            if !recents.isEmpty { result.append(compact("rec", "Recents", "🕘", recents)) }
            result.append(PickerSection(id: "combo", title: "Combinacions", icon: "✨", columns: 2, items: combos))
            if !images.isEmpty { result.append(compact("mine", "Els meus", "🖼️", images)) }
            for g in catalog.groups { result.append(compact("g:" + g.name, g.name, g.icon, g.items)) }
            result.append(compact("chars", "Caràcters", "§", catalog.characters))
            result.append(PickerSection(id: "kao", title: "Kaomojis", icon: "ツ", columns: 3, items: catalog.kaomoji))
        } else {
            let words = q.split(separator: " ").map(String.init)
            let extra = store.keywordsByEmoji
            let found = search(catalog.groups.flatMap(\.items) + catalog.characters, q, words, extra)
            if !found.isEmpty { result.append(compact("res", "Resultats", "🔎", Array(found.prefix(180)))) }
            let mine = search(images, q, words, extra)
            if !mine.isEmpty { result.append(compact("mine", "Els meus", "🖼️", mine)) }
            let combosFound = search(combos, q, words, extra)
            if !combosFound.isEmpty {
                result.append(PickerSection(id: "combo", title: "Combinacions", icon: "✨", columns: 2, items: combosFound))
            }
            let kao = search(catalog.kaomoji, q, words, extra)
            if !kao.isEmpty { result.append(PickerSection(id: "kao", title: "Kaomojis", icon: "ツ", columns: 3, items: kao)) }
        }

        sections = result
        rows = []
        sectionRows = []
        for (si, section) in result.enumerated() {
            let start = rows.count
            for (ri, chunk) in stride(from: 0, to: section.items.count, by: section.columns).enumerated() {
                let items = Array(section.items[chunk..<min(chunk + section.columns, section.items.count)])
                rows.append(GridRow(id: "\(section.id)#\(ri)", section: si, items: items))
            }
            sectionRows.append(start..<rows.count)
        }
        clampSelection()
    }

    private var combos: [PickerItem] {
        store.prefs.combos.filter { !$0.text.isEmpty }.map {
            PickerItem(id: "combo:\($0.id)", kind: .combo, text: $0.text, name: $0.name, tokens: searchTokens([$0.name]))
        }
    }

    private func compact(_ id: String, _ title: String, _ icon: String, _ items: [PickerItem]) -> PickerSection {
        PickerSection(id: id, title: title, icon: icon, columns: Self.compactColumns, items: items)
    }

    private func resolve(_ ids: [String]) -> [PickerItem] {
        ids.compactMap { id in catalog.byID[id] ?? images.first { $0.id == id } }
    }

    /// Cada paraula de la cerca ha de coincidir amb alguna paraula de l'element.
    /// Menys punts = millor resultat.
    private func search(_ items: [PickerItem], _ phrase: String, _ words: [String],
                        _ extra: [String: [String]]) -> [PickerItem] {
        var scored: [(score: Int, index: Int, item: PickerItem, inside: Bool)] = []
        for (index, item) in items.enumerated() {
            let own = extra[item.text] ?? []
            if own.contains(phrase) {
                scored.append((-100, index, item, false))
                continue
            }
            let tokens = item.tokens + own
            var total = 0
            var inside = false
            var matched = true
            for word in words {
                var best: Int?
                for t in tokens {
                    let s = t == word ? 0 : t.hasPrefix(word) ? 1 : (word.count >= 3 && t.contains(word)) ? 4 : nil
                    if let s, s < (best ?? .max) { best = s }
                    if best == 0 { break }
                }
                guard let best else { matched = false; break }
                total += best
                inside = inside || best == 4
            }
            guard matched else { continue }
            if normalize(item.name).hasPrefix(phrase) { total -= 3 }
            if own.contains(where: { $0.hasPrefix(phrase) }) { total -= 10 }
            scored.append((total, index, item, inside))
        }
        // Coincidències a mitja paraula ("escriure" per "riure") només si n'hi ha poques de bones
        if scored.filter({ !$0.inside }).count >= 8 { scored.removeAll { $0.inside } }
        return scored.sorted { ($0.score, $0.index) < ($1.score, $1.index) }.map(\.item)
    }

    // MARK: - Selecció i teclat

    func move(dx: Int, dy: Int) {
        guard !rows.isEmpty else { return }
        var r = selRow, c = selCol
        if dx != 0 {
            c += dx
            if c < 0 {
                if r > 0 { r -= 1; c = rows[r].items.count - 1 } else { c = 0 }
            } else if c >= rows[r].items.count {
                if r < rows.count - 1 { r += 1; c = 0 } else { c = rows[r].items.count - 1 }
            }
        } else {
            r = min(max(selRow + dy, 0), rows.count - 1)
            guard r != selRow else { return }
            let oldCols = sections[rows[selRow].section].columns
            let newCols = sections[rows[r].section].columns
            c = oldCols == newCols ? selCol : selCol * newCols / oldCols
            c = min(c, rows[r].items.count - 1)
        }
        mouseAtLastKey = NSEvent.mouseLocation
        select(row: r, col: c, scroll: true)
    }

    func jump(toSection index: Int) {
        guard sectionRows.indices.contains(index), !sectionRows[index].isEmpty else { return }
        mouseAtLastKey = NSEvent.mouseLocation
        select(row: sectionRows[index].lowerBound, col: 0, scroll: false)
        scrollRequest = ScrollRequest(id: "h:" + sections[index].id, toTop: true, serial: nextSerial())
    }

    func jumpSection(by delta: Int) {
        guard let current = selectedSection, !sections.isEmpty else { return }
        jump(toSection: (current + delta + sections.count) % sections.count)
    }

    /// El ratolí només canvia la selecció si s'ha mogut de veritat
    /// (si no, el desplaçament amb el teclat la "robaria").
    func hover(row: Int, col: Int) {
        guard NSEvent.mouseLocation != mouseAtLastKey else { return }
        select(row: row, col: col, scroll: false)
    }

    private func select(row: Int, col: Int, scroll: Bool) {
        selRow = row
        selCol = col
        clampSelection()
        if scroll, rows.indices.contains(selRow) {
            scrollRequest = ScrollRequest(id: rows[selRow].id, toTop: false, serial: nextSerial())
        }
    }

    private func clampSelection() {
        guard !rows.isEmpty else { selRow = 0; selCol = 0; return }
        selRow = min(max(selRow, 0), rows.count - 1)
        selCol = min(max(selCol, 0), rows[selRow].items.count - 1)
    }

    private func nextSerial() -> Int {
        scrollSerial += 1
        return scrollSerial
    }

    // MARK: - Accions

    func chooseSelected(copyOnly: Bool) {
        if let selected { choose(selected, copyOnly: copyOnly) }
    }

    func choose(_ item: PickerItem, variant: String? = nil, copyOnly: Bool = false) {
        if item.isCompact { store.addRecent(item.id) }
        if let url = item.imageURL {
            onChoose?(.image(url), copyOnly)
        } else {
            onChoose?(.text(variant ?? item.output(tone: tone)), copyOnly)
        }
    }

    func toggleFavorite(_ item: PickerItem) {
        guard item.isCompact else { return }
        store.toggleFavorite(item.id)
        if query.isEmpty { rebuild() }
    }

    func toggleFavoriteSelected() {
        if let selected { toggleFavorite(selected) }
    }

    func setTone(_ tone: SkinTone) {
        store.tone = tone
    }

    func thumbnail(_ url: URL) -> NSImage? {
        if let cached = thumbnails[url] { return cached }
        let image = NSImage(contentsOf: url)
        thumbnails[url] = image
        return image
    }
}
