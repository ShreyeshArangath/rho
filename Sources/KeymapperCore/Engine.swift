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
    public var configuration: Configuration
    private var launcherStartedAt: TimeInterval?
    private var launcherCancelled = false
    private var active: [UInt16: Action] = [:]
    private var passed = Set<UInt16>()
    public init(configuration: Configuration) { self.configuration = configuration }
    public func launcherKeyChanged(down: Bool, timestamp: TimeInterval) {
        if down {
            if launcherStartedAt == nil { launcherStartedAt = timestamp; launcherCancelled = false }
        } else { launcherStartedAt = nil; launcherCancelled = false }
    }
    public func process(code: UInt16, down: Bool, repeated: Bool = false, modifiers: Set<Modifier> = [],
                        timestamp: TimeInterval = ProcessInfo.processInfo.systemUptime) -> Output {
        if !configuration.launcher.modifiers.isSubset(of: modifiers) { launcherKeyChanged(down: false, timestamp: timestamp) }
        if !down {
            passed.remove(code)
            guard let action = active.removeValue(forKey: code) else { return .pass }
            return output(action, down: false, repeated: false)
        }
        if let action = active[code] { return output(action, down: true, repeated: repeated) }
        if passed.contains(code) { return .pass }
        guard !repeated else { passed.insert(code); return .pass }
        let launcherReady = configuration.launcher.holdDuration == 0 || (launcherStartedAt.map { timestamp >= $0 + configuration.launcher.holdDuration } == true && !launcherCancelled)
        if configuration.launcher.modifiers.isSubset(of: modifiers), !launcherReady { launcherCancelled = true }
        guard let binding = configuration.bindings.first(where: {
            Keys.codes[$0.input.key] == code && configuration.physicalModifiers(for: $0.input) == modifiers
        }) else { passed.insert(code); return .pass }
        if binding.input.modifiers.contains(.fn), !launcherReady {
            passed.insert(code); return .pass
        }
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
        active.removeAll(); passed.removeAll(); launcherStartedAt = nil; launcherCancelled = false
        return releases
    }
}
