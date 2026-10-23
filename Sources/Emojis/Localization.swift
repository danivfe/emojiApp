import Foundation
import Observation

/// Idiomes de l'app. Per afegir-ne un: un cas nou aquí, una columna a `Tr`,
/// els noms a `Extras` i un names-<codi>.json (scripts/generate_emojis.py).
enum AppLanguage: String, CaseIterable, Identifiable {
    case ca, es, en

    var id: String { rawValue }

    /// El nom de cada idioma en el seu propi idioma.
    var nativeName: String {
        switch self {
        case .ca: "Català"
        case .es: "Español"
        case .en: "English"
        }
    }

    /// El primer idioma preferit del sistema que tinguem, o l'anglès.
    static var system: AppLanguage {
        for code in Locale.preferredLanguages {
            if let lang = AppLanguage(rawValue: String(code.prefix(2))) { return lang }
        }
        return .en
    }

    func pick(_ ca: String, _ es: String, _ en: String) -> String {
        switch self {
        case .ca: ca
        case .es: es
        case .en: en
        }
    }
}

/// Idioma actiu. És observable perquè les vistes es redibuixin quan canvia.
@MainActor @Observable
final class LanguageState {
    static let shared = LanguageState()
    var current = AppLanguage.system
}

/// Textos de la interfície. Cada cas té els tres idiomes, així el compilador
/// avisa si en falta algun.
enum Tr {
    // Selector
    case searchPlaceholder, skinTone, settingsHelp, noResults
    case favorites, recents, combos, mine, results, characters, kaomoji
    case paste, copyOnly, pasteOtherTone, addFavorite, removeFavorite, addKeyword
    case footerHint
    // Barra de menús
    case openPicker, settingsMenu, openImagesFolder, quit
    // Configuració
    case settingsTitle, general, keywords, myEmojis
    case language, languageAutomatic, shortcut, launchAtLogin
    case autoPaste, accessibilityOn, accessibilityOff, openAccessibility
    case history, clearRecents
    case combosHelp, name, emojisOrText, addCombo, newCombo
    case keywordsHelp, wordExample, word, emoji, add
    case imagesHelp, addImages, openFolder, refresh, noImages, noImagesHelp, moveToTrash, chooseImages
    case space
    // Actualitzacions
    case updates, autoUpdate, checkNow, checking, checkForUpdatesMenu, versionLabel
    case updateAvailable, updateInfo, updateNow, updateLater, updateSkip, upToDate
    case updateFailed, updateManual, updateInvalid, openReleasePage, downloading

    @MainActor var text: String {
        let lang = LanguageState.shared.current
        switch self {
        case .searchPlaceholder: return lang.pick("Cerca un emoji…", "Busca un emoji…", "Search emoji…")
        case .skinTone: return lang.pick("To de pell", "Tono de piel", "Skin tone")
        case .settingsHelp: return lang.pick("Configuració (⌘,)", "Ajustes (⌘,)", "Settings (⌘,)")
        case .noResults: return lang.pick("Cap resultat per «%@»", "Ningún resultado para «%@»", "No results for “%@”")
        case .favorites: return lang.pick("Preferits", "Favoritos", "Favorites")
        case .recents: return lang.pick("Recents", "Recientes", "Recent")
        case .combos: return lang.pick("Combinacions", "Combinaciones", "Combos")
        case .mine: return lang.pick("Els meus", "Los míos", "Mine")
        case .results: return lang.pick("Resultats", "Resultados", "Results")
        case .characters: return lang.pick("Caràcters", "Caracteres", "Characters")
        case .kaomoji: return lang.pick("Kaomojis", "Kaomojis", "Kaomoji")
        case .paste: return lang.pick("Enganxa", "Pegar", "Paste")
        case .copyOnly: return lang.pick("Només copia", "Solo copiar", "Copy only")
        case .pasteOtherTone: return lang.pick("Enganxa amb un altre to", "Pegar con otro tono", "Paste with another skin tone")
        case .addFavorite: return lang.pick("Afegeix a preferits", "Añadir a favoritos", "Add to favorites")
        case .removeFavorite: return lang.pick("Treu de preferits", "Quitar de favoritos", "Remove from favorites")
        case .addKeyword: return lang.pick("Afegeix una paraula clau…", "Añadir una palabra clave…", "Add a keyword…")
        case .footerHint:
            return lang.pick("↩ enganxa   ⌘↩ copia   ⌘D preferit   ⇥ secció",
                             "↩ pegar   ⌘↩ copiar   ⌘D favorito   ⇥ sección",
                             "↩ paste   ⌘↩ copy   ⌘D favorite   ⇥ section")
        case .openPicker: return lang.pick("Obre el selector (%@)", "Abrir el selector (%@)", "Open picker (%@)")
        case .settingsMenu: return lang.pick("Configuració…", "Ajustes…", "Settings…")
        case .openImagesFolder: return lang.pick("Obre la carpeta d'imatges", "Abrir la carpeta de imágenes", "Open images folder")
        case .quit: return lang.pick("Surt d'Emojis", "Salir de Emojis", "Quit Emojis")
        case .settingsTitle: return lang.pick("Configuració d'Emojis", "Ajustes de Emojis", "Emojis Settings")
        case .general: return lang.pick("General", "General", "General")
        case .keywords: return lang.pick("Paraules clau", "Palabras clave", "Keywords")
        case .myEmojis: return lang.pick("Els meus emojis", "Mis emojis", "My emoji")
        case .language: return lang.pick("Idioma", "Idioma", "Language")
        case .languageAutomatic: return lang.pick("Automàtic (el del sistema)", "Automático (el del sistema)", "Automatic (system)")
        case .shortcut: return lang.pick("Drecera per obrir el selector", "Atajo para abrir el selector", "Shortcut to open the picker")
        case .launchAtLogin: return lang.pick("Obre Emojis en iniciar la sessió", "Abrir Emojis al iniciar sesión", "Open Emojis at login")
        case .autoPaste: return lang.pick("Enganxar automàticament", "Pegar automáticamente", "Automatic pasting")
        case .accessibilityOn:
            return lang.pick("Permís d'Accessibilitat activat", "Permiso de Accesibilidad activado", "Accessibility permission granted")
        case .accessibilityOff:
            return lang.pick("Sense el permís d'Accessibilitat, l'emoji només es copia (l'has d'enganxar amb ⌘V).",
                             "Sin el permiso de Accesibilidad, el emoji solo se copia (tienes que pegarlo con ⌘V).",
                             "Without Accessibility permission the emoji is only copied (paste it with ⌘V).")
        case .openAccessibility:
            return lang.pick("Obre Configuració del Sistema › Accessibilitat", "Abrir Ajustes del Sistema › Accesibilidad",
                             "Open System Settings › Accessibility")
        case .history: return lang.pick("Historial", "Historial", "History")
        case .clearRecents: return lang.pick("Esborra els recents", "Borrar los recientes", "Clear recent emoji")
        case .combosHelp:
            return lang.pick("Grups d'emojis o frases que s'enganxen d'un sol cop. Surten a la secció ✨ i es poden cercar pel nom.",
                             "Grupos de emojis o frases que se pegan de una vez. Salen en la sección ✨ y se pueden buscar por el nombre.",
                             "Groups of emoji or phrases pasted in one go. They appear in the ✨ section and can be searched by name.")
        case .name: return lang.pick("Nom", "Nombre", "Name")
        case .emojisOrText: return lang.pick("Emojis o text", "Emojis o texto", "Emoji or text")
        case .addCombo: return lang.pick("Afegeix una combinació", "Añadir una combinación", "Add a combo")
        case .newCombo: return lang.pick("Nova", "Nueva", "New")
        case .keywordsHelp:
            return lang.pick("Paraules teves per trobar un emoji més de pressa. Si escrius la paraula al cercador, aquest emoji surt el primer.",
                             "Palabras tuyas para encontrar un emoji más rápido. Si escribes la palabra en el buscador, ese emoji sale el primero.",
                             "Your own words to find an emoji faster. Type the word in the search field and that emoji comes first.")
        case .wordExample: return lang.pick("Paraula (p. ex. visca)", "Palabra (p. ej. olé)", "Word (e.g. yay)")
        case .word: return lang.pick("Paraula", "Palabra", "Word")
        case .emoji: return lang.pick("Emoji", "Emoji", "Emoji")
        case .add: return lang.pick("Afegeix", "Añadir", "Add")
        case .imagesHelp:
            return lang.pick("Imatges teves (PNG, JPG, GIF…) que pots enganxar com si fossin emojis a Missatges, WhatsApp, Mail, etc. Es cerquen pel nom del fitxer.",
                             "Imágenes tuyas (PNG, JPG, GIF…) que puedes pegar como si fueran emojis en Mensajes, WhatsApp, Mail, etc. Se buscan por el nombre del archivo.",
                             "Your own images (PNG, JPG, GIF…) to paste like emoji in Messages, WhatsApp, Mail, etc. Search them by file name.")
        case .addImages: return lang.pick("Afegeix imatges…", "Añadir imágenes…", "Add images…")
        case .openFolder: return lang.pick("Obre la carpeta", "Abrir la carpeta", "Open folder")
        case .refresh: return lang.pick("Actualitza", "Actualizar", "Refresh")
        case .noImages: return lang.pick("Encara no n'hi ha cap", "Todavía no hay ninguna", "No images yet")
        case .noImagesHelp:
            return lang.pick("Afegeix-hi imatges per veure-les a la secció 🖼️ del selector.",
                             "Añade imágenes para verlas en la sección 🖼️ del selector.",
                             "Add images to see them in the 🖼️ section of the picker.")
        case .moveToTrash: return lang.pick("Mou a la paperera", "Mover a la papelera", "Move to Trash")
        case .chooseImages:
            return lang.pick("Tria les imatges que vols fer servir com a emojis", "Elige las imágenes que quieres usar como emojis",
                             "Choose the images you want to use as emoji")
        case .space: return lang.pick("Espai", "Espacio", "Space")
        case .updates: return lang.pick("Actualitzacions", "Actualizaciones", "Updates")
        case .autoUpdate:
            return lang.pick("Comprova si hi ha versions noves cada dia", "Buscar versiones nuevas cada día",
                             "Check for new versions every day")
        case .checkNow: return lang.pick("Comprova-ho ara", "Comprobar ahora", "Check now")
        case .checking: return lang.pick("Comprovant…", "Comprobando…", "Checking…")
        case .checkForUpdatesMenu:
            return lang.pick("Comprova si hi ha actualitzacions…", "Buscar actualizaciones…", "Check for Updates…")
        case .versionLabel: return lang.pick("Versió %@", "Versión %@", "Version %@")
        case .updateAvailable:
            return lang.pick("Hi ha una versió nova d'Emojis: %@", "Hay una versión nueva de Emojis: %@",
                             "A new version of Emojis is available: %@")
        case .updateInfo:
            return lang.pick("Ara tens la %@. Vols instal·lar la nova? L'app es tornarà a obrir sola. Potser hauràs de tornar a activar el permís d'Accessibilitat.",
                             "Ahora tienes la %@. ¿Quieres instalar la nueva? La app se volverá a abrir sola. Puede que tengas que volver a activar el permiso de Accesibilidad.",
                             "You have %@. Install the new version? The app will reopen by itself. You may need to enable the Accessibility permission again.")
        case .updateNow: return lang.pick("Actualitza", "Actualizar", "Update")
        case .updateLater: return lang.pick("Més tard", "Más tarde", "Later")
        case .updateSkip: return lang.pick("Omet aquesta versió", "Omitir esta versión", "Skip This Version")
        case .upToDate: return lang.pick("Ja tens l'última versió", "Ya tienes la última versión", "You're up to date")
        case .updateFailed: return lang.pick("No s'ha pogut actualitzar", "No se ha podido actualizar", "The update failed")
        case .updateManual:
            return lang.pick("La pots descarregar a mà des de GitHub.", "Puedes descargarla a mano desde GitHub.",
                             "You can download it manually from GitHub.")
        case .updateInvalid:
            return lang.pick("El fitxer de la versió nova no és vàlid.", "El archivo de la versión nueva no es válido.",
                             "The new version's file isn't valid.")
        case .openReleasePage: return lang.pick("Obre GitHub", "Abrir GitHub", "Open GitHub")
        case .downloading: return lang.pick("Descarregant…", "Descargando…", "Downloading…")
        }
    }

    @MainActor func format(_ args: CVarArg...) -> String {
        String(format: text, arguments: args)
    }

    /// Nom d'un grup d'Unicode (ve en anglès a emojis.json).
    @MainActor static func group(_ english: String) -> String {
        let lang = LanguageState.shared.current
        switch english {
        case "Smileys & Emotion": return lang.pick("Cares i emocions", "Caras y emociones", "Smileys & Emotion")
        case "People & Body": return lang.pick("Persones i cos", "Personas y cuerpo", "People & Body")
        case "Animals & Nature": return lang.pick("Animals i natura", "Animales y naturaleza", "Animals & Nature")
        case "Food & Drink": return lang.pick("Menjar i beure", "Comida y bebida", "Food & Drink")
        case "Travel & Places": return lang.pick("Viatges i llocs", "Viajes y lugares", "Travel & Places")
        case "Activities": return lang.pick("Activitats", "Actividades", "Activities")
        case "Objects": return lang.pick("Objectes", "Objetos", "Objects")
        case "Symbols": return lang.pick("Símbols", "Símbolos", "Symbols")
        case "Flags": return lang.pick("Banderes", "Banderas", "Flags")
        default: return english
        }
    }
}
