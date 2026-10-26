#if DEBUG
import AppKit
import SwiftUI

/// Només per provar: `swift run Emojis --snapshot sortida.png "cerca"`
/// dibuixa el selector en una imatge i mostra els primers resultats.
@MainActor
enum DebugSnapshot {
    static func runIfRequested() -> Bool {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "--snapshot"), args.count > i + 1 else { return false }
        let store = Store()
        if let l = args.firstIndex(of: "--lang"), args.count > l + 1 {
            LanguageState.shared.current = AppLanguage(rawValue: args[l + 1]) ?? .ca
        }
        let model = PickerModel(catalog: Catalog.load(language: LanguageState.shared.current), store: store)
        model.prepare()
        if args.count > i + 2 { model.query = args[i + 2] }
        print("Seccions:", model.sections.map { "\($0.title) (\($0.items.count))" }.joined(separator: ", "))
        if let first = model.sections.first {
            print("Primers:", first.items.prefix(12).map { $0.kind == .image ? $0.name : $0.text }.joined(separator: " "))
        }
        model.move(dx: 1, dy: 0)

        let view = NSHostingView(rootView: PickerView(model: model).background(Color(nsColor: .windowBackgroundColor)))
        view.frame = NSRect(origin: .zero, size: PickerView.size)
        let window = NSWindow(contentRect: view.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = view
        view.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.5))
        // --sequence "o,oj,": escriu cerques seguides sobre la mateixa vista, com en l'app real
        if let s = args.firstIndex(of: "--sequence"), args.count > s + 1 {
            for query in args[s + 1].split(separator: ",", omittingEmptySubsequences: false) {
                model.query = String(query)
                view.layoutSubtreeIfNeeded()
                view.display()
                RunLoop.main.run(until: Date().addingTimeInterval(0.2))
                print("«\(query)»: \(model.rows.count) files")
            }
        }
        if let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
            view.cacheDisplay(in: view.bounds, to: rep)
            try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: args[i + 1]))
        }
        return true
    }
}
#endif
