import AppKit
import Observation

/// Actualitzacions automàtiques des de les Releases de GitHub.
///
/// Cada release ha de tenir l'etiqueta vX.Y (p. ex. v1.2) i un fitxer Emojis.zip
/// amb l'app a dins (el genera scripts/release.sh).
@MainActor @Observable
final class Updater {
    static let repository = "danivfe/emojiApp"
    private static let assetName = "Emojis.zip"
    private static let checkInterval: TimeInterval = 24 * 60 * 60

    enum Status: Equatable {
        case idle, checking, upToDate, available(String), downloading, failed(String)
    }

    private(set) var status = Status.idle
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var latest: Release?

    private struct Release: Decodable {
        struct Asset: Decodable {
            let name: String
            let browser_download_url: URL
        }
        let tag_name: String
        let body: String?
        let html_url: URL
        let assets: [Asset]

        var version: String { tag_name.trimmingCharacters(in: CharacterSet(charactersIn: "vV")) }
    }

    static var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    var automatic: Bool {
        get { UserDefaults.standard.object(forKey: "autoUpdate") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "autoUpdate") }
    }

    /// Comprova en obrir l'app i després un cop al dia.
    func start() {
        Task { await checkIfDue() }
        timer = Timer.scheduledTimer(withTimeInterval: 60 * 60, repeats: true) { _ in
            Task { @MainActor [weak self] in await self?.checkIfDue() }
        }
    }

    private func checkIfDue() async {
        guard automatic else { return }
        let last = UserDefaults.standard.double(forKey: "lastUpdateCheck")
        guard Date().timeIntervalSince1970 - last > Self.checkInterval else { return }
        await check(userInitiated: false)
    }

    /// `userInitiated`: també avisa si ja està al dia o si hi ha hagut un error.
    func check(userInitiated: Bool) async {
        guard status != .checking, status != .downloading else { return }
        status = .checking
        do {
            var request = URLRequest(url: URL(string: "https://api.github.com/repos/\(Self.repository)/releases/latest")!)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.setValue("Emojis/\(Self.currentVersion)", forHTTPHeaderField: "User-Agent")
            let (data, response) = try await URLSession.shared.data(for: request)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastUpdateCheck")
            if (response as? HTTPURLResponse)?.statusCode == 404 {
                // Encara no s'ha publicat cap release
                status = .upToDate
                if userInitiated { showUpToDate() }
                return
            }
            let release = try JSONDecoder().decode(Release.self, from: data)
            latest = release
            guard Self.isNewer(release.version, than: Self.currentVersion) else {
                status = .upToDate
                if userInitiated { showUpToDate() }
                return
            }
            status = .available(release.version)
            let skipped = UserDefaults.standard.string(forKey: "skippedVersion")
            if userInitiated || skipped != release.version { offer(release) }
        } catch {
            status = .failed(error.localizedDescription)
            if userInitiated { showError(error.localizedDescription) }
        }
    }

    static func isNewer(_ a: String, than b: String) -> Bool {
        let pa = a.split(separator: ".").map { Int($0) ?? 0 }
        let pb = b.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(pa.count, pb.count) {
            let x = i < pa.count ? pa[i] : 0, y = i < pb.count ? pb[i] : 0
            if x != y { return x > y }
        }
        return false
    }

    // MARK: - Avisos

    private func offer(_ release: Release) {
        NSApp.activate()
        let alert = NSAlert()
        alert.messageText = Tr.updateAvailable.format(release.version)
        var info = Tr.updateInfo.format(Self.currentVersion)
        if let notes = release.body?.trimmingCharacters(in: .whitespacesAndNewlines), !notes.isEmpty {
            info += "\n\n" + String(notes.prefix(600))
        }
        alert.informativeText = info
        alert.addButton(withTitle: Tr.updateNow.text)
        alert.addButton(withTitle: Tr.updateLater.text)
        alert.addButton(withTitle: Tr.updateSkip.text)
        switch alert.runModal() {
        case .alertFirstButtonReturn:
            Task { await install(release) }
        case .alertThirdButtonReturn:
            UserDefaults.standard.set(release.version, forKey: "skippedVersion")
        default:
            break
        }
    }

    private func showUpToDate() {
        NSApp.activate()
        let alert = NSAlert()
        alert.messageText = Tr.upToDate.text
        alert.informativeText = Tr.versionLabel.format(Self.currentVersion)
        alert.runModal()
    }

    private func showError(_ message: String) {
        NSApp.activate()
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = Tr.updateFailed.text
        alert.informativeText = message
        alert.runModal()
    }

    // MARK: - Instal·lació

    private struct UpdateError: LocalizedError {
        let errorDescription: String?
    }

    private func install(_ release: Release) async {
        status = .downloading
        do {
            let installed = Bundle.main.bundleURL
            guard installed.pathExtension == "app" else {
                throw UpdateError(errorDescription: Tr.updateInvalid.text)
            }
            guard let asset = release.assets.first(where: { $0.name == Self.assetName }) else {
                throw UpdateError(errorDescription: Tr.updateInvalid.text)
            }

            let work = FileManager.default.temporaryDirectory.appendingPathComponent("EmojisUpdate-\(UUID().uuidString)")
            try FileManager.default.createDirectory(at: work, withIntermediateDirectories: true)
            let (download, _) = try await URLSession.shared.download(from: asset.browser_download_url)
            let zip = work.appendingPathComponent(Self.assetName)
            try FileManager.default.moveItem(at: download, to: zip)

            let extracted = work.appendingPathComponent("extracted")
            try run("/usr/bin/ditto", ["-x", "-k", zip.path, extracted.path])
            let newApp = extracted.appendingPathComponent("Emojis.app")

            // Comprova que és la nostra app, la versió anunciada i que el paquet no està malmès
            let info = Bundle(url: newApp)?.infoDictionary
            guard info?["CFBundleIdentifier"] as? String == Bundle.main.bundleIdentifier,
                  info?["CFBundleShortVersionString"] as? String == release.version else {
                throw UpdateError(errorDescription: Tr.updateInvalid.text)
            }
            try run("/usr/bin/codesign", ["--verify", "--deep", "--strict", newApp.path])

            _ = try FileManager.default.replaceItemAt(installed, withItemAt: newApp)
            try? FileManager.default.removeItem(at: work)
            relaunch(installed)
        } catch {
            status = .failed(error.localizedDescription)
            NSApp.activate()
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = Tr.updateFailed.text
            alert.informativeText = error.localizedDescription + "\n\n" + Tr.updateManual.text
            alert.addButton(withTitle: Tr.openReleasePage.text)
            alert.addButton(withTitle: "OK")
            if alert.runModal() == .alertFirstButtonReturn {
                NSWorkspace.shared.open(release.html_url)
            }
        }
    }

    private func run(_ tool: String, _ arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: tool)
        process.arguments = arguments
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw UpdateError(errorDescription: "\(URL(fileURLWithPath: tool).lastPathComponent): \(process.terminationStatus)")
        }
    }

    /// Obre la versió nova un moment després de tancar aquesta.
    private func relaunch(_ app: URL) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", "sleep 1; /usr/bin/open \"$0\"", app.path]
        try? process.run()
        NSApp.terminate(nil)
    }
}
