import Foundation
@testable import KeymapperCore

final class ConfigurationTests {
    func testDefaultsRoundTrip() throws {
        let config = try Configuration.decode(JSONEncoder().encode(Configuration.initial))
        expectEqual(config, .initial)
    }
    func testDuplicateRegardlessOfModifierOrder() {
        let action = Action(type: .sendKey, key: "backspace")
        let config = Configuration(bindings: [
            Binding(input: Chord(key: "space", modifiers: [.shift, .control]), action: action),
            Binding(input: Chord(key: "space", modifiers: [.control, .shift]), action: action)
        ])
        expectThrows(try config.validate())
    }
    func testRejectInvalidVersionsKeysAndActions() {
        expectThrows(try Configuration(version: 2, bindings: []).validate())
        for key in ["unknown", "caps_lock", "fn"] {
            expectThrows(try Configuration(bindings: [Binding(input: Chord(key: key), action: Action(type: .sendKey, key: "space"))]).validate())
        }
        let invalid = [
            Action(type: .sendKey, key: "unknown"),
            Action(type: .sendKey, key: "space", modifiers: [.fn]),
            Action(type: .sendKey, key: "space", modifiers: [.shift, .shift]),
            Action(type: .sendKey, key: "space", bundleIdentifier: "com.example.app"),
            Action(type: .openApp, bundleIdentifier: ""),
            Action(type: .openApp, key: "space", bundleIdentifier: "com.example.app")
        ]
        for action in invalid {
            expectThrows(try Configuration(bindings: [Binding(input: Chord(key: "a"), action: action)]).validate())
        }
    }
    func testMalformedJSONAndDuplicateModifiers() {
        expectThrows(try Configuration.decode(Data("bad json".utf8)))
        expectThrows(try Configuration(bindings: [Binding(input: Chord(key: "a", modifiers: [.shift, .shift]), action: Action(type: .sendKey, key: "space"))]).validate())
    }
}
