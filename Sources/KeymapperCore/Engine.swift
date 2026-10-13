import Foundation

public struct Stroke: Equatable {
    public let code: UInt16
    public let modifiers: Set<Modifier>
    public init(code: UInt16, modifiers: Set<Modifier> = []) { self.code = code; self.modifiers = modifiers }
}
public enum Output: Equatable {
    case pass, suppress
    case send(Stroke, down: Bool, repeated: Bool)
    case tap(Stroke)
    case tapAndPass(Stroke)
    case launch(String)
}
public final class Engine {
    public static let escapeHoldDuration: TimeInterval = 0.4
    public var configuration: Configuration
    private var escapeStartedAt: TimeInterval?
    private var escapeUsed = false
    private var escapeCancelled = false
    private var active: [UInt16: Action] = [:]
    private var passed = Set<UInt16>()
    public init(configuration: Configuration) { self.configuration = configuration }
    public func modifiersChanged() { if escapeStartedAt != nil { escapeUsed = true } }
    public func process(code: UInt16, down: Bool, repeated: Bool = false, modifiers: Set<Modifier> = [],
                        eligible: Bool = true, timestamp: TimeInterval = ProcessInfo.processInfo.systemUptime) -> Output {
        if code == Keys.escape {
            if down {
                if escapeStartedAt != nil { return .suppress }
                guard !passed.contains(code), !repeated, modifiers.isEmpty, eligible else {
                    passed.insert(code); return .pass
                }
                escapeStartedAt = timestamp
                escapeUsed = !passed.isEmpty || !active.isEmpty
                escapeCancelled = false
                return .suppress
            }
            passed.remove(code)
            guard escapeStartedAt != nil else { return .pass }
            let tap = !escapeUsed
            escapeStartedAt = nil; escapeUsed = false; escapeCancelled = false
            return tap ? .tap(Stroke(code: Keys.escape)) : .suppress
        }
        if !down {
            passed.remove(code)
            guard let action = active.removeValue(forKey: code) else { return .pass }
            return output(action, down: false, repeated: false)
        }
        if let action = active[code] { return output(action, down: true, repeated: repeated) }
        if let started = escapeStartedAt {
            escapeUsed = true
            if !escapeCancelled && timestamp - started < Self.escapeHoldDuration {
                // A quick Escape followed by typing still delivers Escape before the letter.
                escapeCancelled = true; passed.insert(code)
                return .tapAndPass(Stroke(code: Keys.escape))
            }
        }
        if passed.contains(code) { return .pass }
        guard !repeated, eligible else { passed.insert(code); return .pass }
        var inputModifiers = modifiers
        if escapeStartedAt != nil && !escapeCancelled { inputModifiers.insert(.escape) }
        guard let binding = configuration.bindings.first(where: {
            Keys.codes[$0.input.key] == code && Set($0.input.modifiers) == inputModifiers
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
        active.removeAll(); passed.removeAll(); escapeStartedAt = nil; escapeUsed = false; escapeCancelled = false
        return releases
    }
}
