import Foundation

/// Fins a la 1.2 l'identificador de l'app era local.dani.Emojis. Si la configuració
/// d'aquell identificador existeix, la copia a l'actual el primer cop que s'obre.
enum Migration {
    private static let oldIdentifier = "local.dani.Emojis"
    private static let keys = ["prefs", "autoUpdate", "skippedVersion"]

    static func run() {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: "prefs") == nil,
              Bundle.main.bundleIdentifier != oldIdentifier,
              let old = UserDefaults(suiteName: oldIdentifier) else { return }
        for key in keys {
            if let value = old.object(forKey: key) { defaults.set(value, forKey: key) }
        }
    }
}
