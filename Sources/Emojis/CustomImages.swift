import AppKit
import UniformTypeIdentifiers

/// Els teus "emojis" propis: imatges d'una carpeta que s'enganxen com a imatge.
enum CustomImages {
    static var folder: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let url = base.appendingPathComponent("Emojis/Images", isDirectory: true)
        // La primera versió feia servir un nom en català; el canviem a un de neutre
        let old = base.appendingPathComponent("Emojis/Els meus", isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path), FileManager.default.fileExists(atPath: old.path) {
            try? FileManager.default.moveItem(at: old, to: url)
        }
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static func scan() -> [PickerItem] {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: folder, includingPropertiesForKeys: [.contentTypeKey], options: [.skipsHiddenFiles])) ?? []
        return files
            .filter { (try? $0.resourceValues(forKeys: [.contentTypeKey]).contentType?.conforms(to: .image)) == true }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
            .map { url in
                let name = url.deletingPathExtension().lastPathComponent
                    .replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: "-", with: " ")
                return PickerItem(id: "img:" + url.lastPathComponent, kind: .image, text: "", name: name,
                                  imageURL: url, tokens: searchTokens([name]))
            }
    }

    /// Copia les imatges triades a la carpeta. Retorna quantes s'han afegit.
    @MainActor @discardableResult
    static func importWithPanel() -> Int {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = true
        panel.message = Tr.chooseImages.text
        guard panel.runModal() == .OK else { return 0 }
        var added = 0
        for url in panel.urls {
            var dest = folder.appendingPathComponent(url.lastPathComponent)
            var n = 2
            while FileManager.default.fileExists(atPath: dest.path) {
                dest = folder.appendingPathComponent("\(url.deletingPathExtension().lastPathComponent) \(n).\(url.pathExtension)")
                n += 1
            }
            if (try? FileManager.default.copyItem(at: url, to: dest)) != nil { added += 1 }
        }
        return added
    }
}
