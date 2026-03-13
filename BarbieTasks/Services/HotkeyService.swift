import Carbon

/// Global hotkey service using Carbon's RegisterEventHotKey API.
/// Registers Ctrl+Space as a system-wide hotkey that works even when the app is not focused.
final class HotkeyService {
    static let shared = HotkeyService()

    private var hotKeyRef: EventHotKeyRef?
    private var onTrigger: (() -> Void)?
    private var eventHandler: EventHandlerRef?

    private init() {}

    /// Registers Ctrl+Space as a global hotkey.
    /// - Parameter onTrigger: Closure invoked on the main thread when the hotkey is pressed.
    func register(onTrigger: @escaping () -> Void) {
        // Unregister any existing hotkey first to avoid duplicates
        unregister()

        self.onTrigger = onTrigger

        var hotKeyID = EventHotKeyID(signature: 0x4254, id: 1) // "BT" = Barbie Tasks
        var eventType = EventTypeSpec(
            eventClass: UInt32(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData else { return OSStatus(eventNotHandledErr) }
                let service = Unmanaged<HotkeyService>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async { service.onTrigger?() }
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandler
        )

        RegisterEventHotKey(
            UInt32(49),          // keyCode 49 = Space
            UInt32(controlKey),  // Ctrl modifier
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    /// Unregisters the global hotkey and removes the event handler.
    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
        onTrigger = nil
    }
}
