import SwiftUI

struct PickerView: View {
    static let size = CGSize(width: 420, height: 500)
    private static let gridWidth: CGFloat = 396

    @Bindable var model: PickerModel
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()
            if model.query.isEmpty {
                tabBar
                Divider()
            }
            grid
            Divider()
            footer
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .onAppear { searchFocused = true }
        .onChange(of: model.focusToken) { searchFocused = true }
    }

    // MARK: - Cercador

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Cerca un emoji…", text: $model.query)
                .textFieldStyle(.plain)
                .font(.title3)
                .focused($searchFocused)
            Menu {
                ForEach(SkinTone.allCases) { tone in
                    Button {
                        model.setTone(tone)
                    } label: {
                        Text("\(tone.sample)  \(tone.label)\(tone == model.tone ? "  ✓" : "")")
                    }
                }
            } label: {
                Text(model.tone.sample).font(.title3)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("To de pell")
            Button {
                model.onSettings?(.general, nil)
            } label: {
                Image(systemName: "gearshape").foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Configuració (⌘,)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Array(model.sections.enumerated()), id: \.element.id) { index, section in
                Button {
                    model.jump(toSection: index)
                } label: {
                    Text(section.icon)
                        .font(.system(size: 15))
                        .frame(maxWidth: .infinity, minHeight: 26)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(model.selectedSection == index ? Color.primary.opacity(0.12) : .clear))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(section.title)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    // MARK: - Graella

    private var grid: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(model.sections.enumerated()), id: \.element.id) { si, section in
                        Text(section.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.top, 10)
                            .padding(.bottom, 4)
                            .padding(.leading, 4)
                            .id("h:" + section.id)
                        ForEach(model.sectionRows[si], id: \.self) { ri in
                            row(ri, columns: section.columns)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 8)
            }
            .overlay {
                if model.sections.isEmpty {
                    Text("Cap resultat per «\(model.query)»").foregroundStyle(.secondary)
                }
            }
            .onChange(of: model.scrollRequest) { _, request in
                guard let request else { return }
                proxy.scrollTo(request.id, anchor: request.toTop ? .top : nil)
            }
        }
    }

    private func row(_ ri: Int, columns: Int) -> some View {
        let row = model.rows[ri]
        let width = Self.gridWidth / CGFloat(columns)
        return HStack(spacing: 0) {
            ForEach(Array(row.items.enumerated()), id: \.element.id) { ci, item in
                ItemCell(item: item, tone: model.tone, selected: model.isSelected(row: ri, col: ci),
                         image: item.imageURL.flatMap(model.thumbnail))
                    .frame(width: width, height: item.kind == .combo ? 46 : 40)
                    .contentShape(Rectangle())
                    .onHover { if $0 { model.hover(row: ri, col: ci) } }
                    .onTapGesture { model.choose(item) }
                    .contextMenu { contextMenu(for: item) }
            }
        }
        .id(row.id)
    }

    @ViewBuilder
    private func contextMenu(for item: PickerItem) -> some View {
        Button("Enganxa") { model.choose(item) }
        Button("Només copia") { model.choose(item, copyOnly: true) }
        if let tones = item.tones {
            Menu("Enganxa amb un altre to") {
                Button(item.text) { model.choose(item, variant: item.text) }
                ForEach(tones, id: \.self) { variant in
                    Button(variant) { model.choose(item, variant: variant) }
                }
            }
        }
        if item.isCompact {
            Divider()
            Button(model.store.isFavorite(item.id) ? "Treu de preferits" : "Afegeix a preferits") {
                model.toggleFavorite(item)
            }
        }
        if item.kind == .emoji || item.kind == .character {
            Button("Afegeix una paraula clau…") { model.onSettings?(.keywords, item.text) }
        }
    }

    // MARK: - Peu

    private var footer: some View {
        HStack(spacing: 10) {
            if let item = model.selected {
                Group {
                    if let url = item.imageURL, let image = model.thumbnail(url) {
                        Image(nsImage: image).resizable().scaledToFit()
                    } else if item.isCompact {
                        Text(item.output(tone: model.tone)).font(.system(size: 30))
                    } else {
                        Image(systemName: item.kind == .combo ? "sparkles" : "face.smiling")
                            .font(.title2).foregroundStyle(.secondary)
                    }
                }
                .frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(item.name.prefix(1).uppercased() + item.name.dropFirst())
                            .font(.callout.weight(.medium)).lineLimit(1)
                        if model.store.isFavorite(item.id) {
                            Image(systemName: "star.fill").font(.caption2).foregroundStyle(.yellow)
                        }
                    }
                    Text("↩ enganxa   ⌘↩ copia   ⌘D preferit   ⇥ secció")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(height: 56)
    }
}

private struct ItemCell: View {
    let item: PickerItem
    let tone: SkinTone
    let selected: Bool
    let image: NSImage?

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(selected ? Color.accentColor.opacity(0.32) : .clear)
                    .padding(1))
    }

    @ViewBuilder
    private var content: some View {
        switch item.kind {
        case .emoji:
            Text(item.output(tone: tone)).font(.system(size: 26))
        case .character:
            Text(item.text).font(.system(size: 19))
        case .kaomoji:
            Text(item.text).font(.system(size: 13)).lineLimit(1).minimumScaleFactor(0.6).padding(.horizontal, 4)
        case .combo:
            VStack(spacing: 1) {
                Text(item.text).font(.system(size: 16)).lineLimit(1)
                if !item.text.hasPrefix(item.name) {
                    Text(item.name).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            .padding(.horizontal, 6)
        case .image:
            if let image {
                Image(nsImage: image).resizable().scaledToFit().padding(5)
            }
        }
    }
}
