import Carbon.HIToolbox

/// Drecera de teclat global. RegisterEventHotKey no necessita cap permís especial.
@MainActor
final class HotKey {
    private var ref: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private static var action: (() -> Void)?

    init(action: @escaping () -> Void) {
        Self.action = action
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
            DispatchQueue.main.async { MainActor.assumeIsolated { HotKey.action?() } }
            return noErr
        }, 1, &spec, nil, &handler)
    }

    func register(_ preset: HotKeyPreset) {
        if let ref { UnregisterEventHotKey(ref) }
        ref = nil
        let id = EventHotKeyID(signature: OSType(0x454D_4F4A), id: 1) // 'EMOJ'
        RegisterEventHotKey(preset.keyCode, preset.modifiers, id, GetApplicationEventTarget(), 0, &ref)
    }
}
