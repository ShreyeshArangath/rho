import AppKit
import Carbon
import KeymapperCore

final class EventTap {
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private let marker: Int64 = 0x504B4D415050
    let engine: Engine
    var onLaunch: ((String) -> Void)?
    var onFailure: ((String) -> Void)?
    init(configuration: Configuration) { engine = Engine(configuration: configuration) }
    func start() throws {
        guard AXIsProcessTrusted() else { throw ConfigError("Inactive — Accessibility permission is required.") }
        let mask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        guard let created = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap,
                                             options: .defaultTap, eventsOfInterest: CGEventMask(mask),
                                             callback: { _, type, event, context in
            guard let context else { return Unmanaged.passUnretained(event) }
            return Unmanaged<EventTap>.fromOpaque(context).takeUnretainedValue().handle(type, event)
        }, userInfo: Unmanaged.passUnretained(self).toOpaque()) else {
            throw ConfigError("Inactive — macOS denied the keyboard event tap. Check Accessibility and workplace restrictions.")
        }
        tap = created
        guard let runSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, created, 0) else {
            CFMachPortInvalidate(created); tap = nil
            throw ConfigError("Could not create the keyboard event source.")
        }
        source = runSource
        CFRunLoopAddSource(CFRunLoopGetMain(), runSource, .commonModes)
        CGEvent.tapEnable(tap: created, enable: true)
    }
    func releaseKeys() { for stroke in engine.reset() { post(stroke, down: false) } }
    func stop() {
        releaseKeys()
        if let tap { CGEvent.tapEnable(tap: tap, enable: false); CFMachPortInvalidate(tap) }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        source = nil; tap = nil
    }
    private func handle(_ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            DispatchQueue.main.async { [weak self] in self?.onFailure?("Keyboard interception was interrupted; remapping is paused.") }
            return Unmanaged.passUnretained(event)
        }
        if event.getIntegerValueField(.eventSourceUserData) == marker { return Unmanaged.passUnretained(event) }
        // Secure Input does not promise delivery to taps. Never remap events observed while it is active.
        if IsSecureEventInputEnabled() { return Unmanaged.passUnretained(event) }
        let flags = event.flags
        let code = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let timestamp = TimeInterval(event.timestamp) / 1_000_000_000
        var modifiers = Set<Modifier>()
        if flags.contains(.maskShift) { modifiers.insert(.shift) }
        if flags.contains(.maskControl) { modifiers.insert(.control) }
        if flags.contains(.maskAlternate) { modifiers.insert(.option) }
        if flags.contains(.maskCommand) { modifiers.insert(.command) }
        if flags.contains(.maskSecondaryFn) { modifiers.insert(.fn) }
        if type == .flagsChanged {
            engine.launcherKeyChanged(down: engine.configuration.launcher.modifiers.isSubset(of: modifiers), timestamp: timestamp)
            return Unmanaged.passUnretained(event)
        }
        let output = engine.process(code: code,
                                    down: type == .keyDown,
                                    repeated: event.getIntegerValueField(.keyboardEventAutorepeat) != 0,
                                    modifiers: modifiers,
                                    timestamp: timestamp)
        switch output {
        case .pass: return Unmanaged.passUnretained(event)
        case .suppress: return nil
        case .launch(let identifier):
            DispatchQueue.main.async { [weak self] in self?.onLaunch?(identifier) }
            return nil
        case .send(let stroke, _, let repeated):
            // Rewrite in place: the downstream app gets exactly one event and its matching key-up.
            event.setIntegerValueField(.keyboardEventKeycode, value: Int64(stroke.code))
            event.setIntegerValueField(.keyboardEventAutorepeat, value: repeated ? 1 : 0)
            event.flags = flagsFor(stroke.modifiers)
            event.setIntegerValueField(.eventSourceUserData, value: marker)
            // Remove Unicode payload from the original key (e.g. space -> backspace).
            event.keyboardSetUnicodeString(stringLength: 0, unicodeString: nil)
            return Unmanaged.passUnretained(event)
        }
    }
    private func flagsFor(_ modifiers: Set<Modifier>) -> CGEventFlags {
        var flags = CGEventFlags()
        if modifiers.contains(.shift) { flags.insert(.maskShift) }
        if modifiers.contains(.control) { flags.insert(.maskControl) }
        if modifiers.contains(.option) { flags.insert(.maskAlternate) }
        if modifiers.contains(.command) { flags.insert(.maskCommand) }
        return flags
    }
    private func post(_ stroke: Stroke, down: Bool) {
        guard let event = CGEvent(keyboardEventSource: CGEventSource(stateID: .privateState), virtualKey: stroke.code, keyDown: down) else { return }
        event.flags = flagsFor(stroke.modifiers)
        event.setIntegerValueField(.eventSourceUserData, value: marker)
        event.post(tap: .cgSessionEventTap)
    }
}
