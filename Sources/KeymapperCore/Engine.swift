import Foundation

public struct Stroke: Equatable {
    public let code: UInt16
    public let modifiers: Set<Modifier>
    public init(code: UInt16, modifiers: Set<Modifier> = []) { self.code = code; self.modifiers = modifiers }
}
public enum Output: Equatable {
    case pass, suppress
    case send(Stroke, down: Bool, repeated: Bool)
    case launch(String)
}
public final class Engine {
    public static let functionHoldDuration: TimeInterval = 0.4
    public var configuration: Configuration
    private var functionStartedAt: TimeInterval?
    private var functionCancelled = false
    private var active: [UInt16: Action] = [:]
    private var passed = Set<UInt16>()
    public init(configuration: Configuration) { self.configuration = configuration }
    public func functionKeyChanged(down: Bool, timestamp: TimeInterval) {
        if down {
            if functionStartedAt == nil { functionStartedAt = timestamp; functionCancelled = false }
        } else { functionStartedAt = nil; functionCancelled = false }
    }
    public func process(code: UInt16, down: Bool, repeated: Bool = false, modifiers: Set<Modifier> = [],
                        timestamp: TimeInterval = ProcessInfo.processInfo.systemUptime) -> Output {
        if !modifiers.contains(.fn) { functionKeyChanged(down: false, timestamp: timestamp) }
        if !down {
            passed.remove(code)
            guard let action = active.removeValue(forKey: code) else { return .pass }
            return output(action, down: false, repeated: false)
        }
        if let action = active[code] { return output(action, down: true, repeated: repeated) }
        if passed.contains(code) { return .pass }
        guard !repeated else { passed.insert(code); return .pass }
        if modifiers.contains(.fn) {
            guard let started = functionStartedAt, !functionCancelled,
                  timestamp >= started + Self.functionHoldDuration else {
                // Preserve native Fn chords until the long press has activated.
                functionCancelled = true; passed.insert(code); return .pass
            }
        }
        guard let binding = configuration.bindings.first(where: {
            Keys.codes[$0.input.key] == code && Set($0.input.modifiers) == modifiers
        }) else { passed.insert(code); return .pass }
        active[code] = binding.action
        return output(binding.action, down: true, repeated: false)
    }
    private func output(_ action: Action, down: Bool, repeated: Bool) -> Output {
        switch action.type {
        case .openApp:
            return down && !repeated ? .launch(action.bundleIdentifier!) : .suppress
        case .sendKey:
            return .send(Stroke(code: Keys.codes[action.key!]!, modifiers: Set(action.modifiers ?? [])), down: down, repeated: repeated)
        }
    }
    public func reset() -> [Stroke] {
        let releases = active.values.compactMap { action -> Stroke? in
            guard action.type == .sendKey else { return nil }
            return Stroke(code: Keys.codes[action.key!]!, modifiers: Set(action.modifiers ?? []))
        }
        active.removeAll(); passed.removeAll(); functionStartedAt = nil; functionCancelled = false
        return releases
    }
}
