import Foundation

public enum Modifier: String, Codable, Hashable { case shift, control, option, command, fn }
public struct Chord: Codable, Equatable {
    public var key: String
    public var modifiers: [Modifier]
    public init(key: String, modifiers: [Modifier] = []) { self.key = key; self.modifiers = modifiers }
}
public struct Action: Codable, Equatable {
    public enum Kind: String, Codable { case sendKey, openApp }
    public var type: Kind
    public var key: String?
    public var modifiers: [Modifier]?
    public var bundleIdentifier: String?
    public init(type: Kind, key: String? = nil, modifiers: [Modifier]? = nil, bundleIdentifier: String? = nil) {
        self.type = type; self.key = key; self.modifiers = modifiers; self.bundleIdentifier = bundleIdentifier
    }
}
public struct Binding: Codable, Equatable {
    public var input: Chord
    public var action: Action
    public init(input: Chord, action: Action) { self.input = input; self.action = action }
}
public struct Configuration: Codable, Equatable {
    public var version: Int
    public var bindings: [Binding]
    public init(version: Int = 1, bindings: [Binding]) { self.version = version; self.bindings = bindings }
    public func validate() throws {
        guard version == 1 else { throw ConfigError("Unsupported configuration version \(version); expected 1.") }
        var seen = Set<String>()
        for (index, binding) in bindings.enumerated() {
            let label = "Binding \(index + 1)"
            guard Keys.codes[binding.input.key] != nil else { throw ConfigError("\(label): unknown or reserved input key '\(binding.input.key)'.") }
            guard Set(binding.input.modifiers).count == binding.input.modifiers.count else { throw ConfigError("\(label): repeated input modifier.") }
            let signature = binding.input.key + ":" + binding.input.modifiers.map(\.rawValue).sorted().joined(separator: "+")
            guard seen.insert(signature).inserted else { throw ConfigError("\(label): duplicate shortcut.") }
            switch binding.action.type {
            case .sendKey:
                guard let key = binding.action.key, Keys.codes[key] != nil else { throw ConfigError("\(label): sendKey requires a valid key.") }
                let modifiers = binding.action.modifiers ?? []
                guard !modifiers.contains(.fn), Set(modifiers).count == modifiers.count, binding.action.bundleIdentifier == nil else {
                    throw ConfigError("\(label): sendKey permits only standard, non-repeated output modifiers and no bundleIdentifier.")
                }
            case .openApp:
                guard let identifier = binding.action.bundleIdentifier, !identifier.isEmpty,
                      identifier.contains("."), !identifier.contains(where: { $0.isWhitespace }),
                      binding.action.key == nil, binding.action.modifiers == nil else {
                    throw ConfigError("\(label): openApp requires a bundleIdentifier and no output key/modifiers.")
                }
            }
        }
    }
    public static func decode(_ data: Data) throws -> Configuration {
        let config = try JSONDecoder().decode(Configuration.self, from: data)
        try config.validate()
        return config
    }
    public static let initial = Configuration(bindings: [
        Binding(input: Chord(key: "space", modifiers: [.shift]), action: Action(type: .sendKey, key: "backspace")),
        Binding(input: Chord(key: "c", modifiers: [.fn]), action: Action(type: .openApp, bundleIdentifier: "com.openai.codex")),
        Binding(input: Chord(key: "b", modifiers: [.fn]), action: Action(type: .openApp, bundleIdentifier: "com.google.Chrome")),
        Binding(input: Chord(key: "l", modifiers: [.fn]), action: Action(type: .openApp, bundleIdentifier: "com.linear")),
        Binding(input: Chord(key: "o", modifiers: [.fn]), action: Action(type: .openApp, bundleIdentifier: "md.obsidian")),
        Binding(input: Chord(key: "g", modifiers: [.fn]), action: Action(type: .openApp, bundleIdentifier: "com.mitchellh.ghostty")),
        Binding(input: Chord(key: "s", modifiers: [.fn]), action: Action(type: .openApp, bundleIdentifier: "com.tinyspeck.slackmacgap")),
        Binding(input: Chord(key: "n", modifiers: [.fn]), action: Action(type: .openApp, bundleIdentifier: "notion.id"))
    ])
}
public struct ConfigError: LocalizedError {
    public let message: String
    public init(_ message: String) { self.message = message }
    public var errorDescription: String? { message }
}
public enum Keys {
    // macOS virtual key codes: letter names refer to physical US keyboard positions.
    public static let function: UInt16 = 63
    public static let codes: [String: UInt16] = [
        "a":0,"s":1,"d":2,"f":3,"h":4,"g":5,"z":6,"x":7,"c":8,"v":9,"b":11,
        "q":12,"w":13,"e":14,"r":15,"y":16,"t":17,"1":18,"2":19,"3":20,"4":21,
        "6":22,"5":23,"equal":24,"9":25,"7":26,"minus":27,"8":28,"0":29,
        "right_bracket":30,"o":31,"u":32,"left_bracket":33,"i":34,"p":35,"return":36,
        "l":37,"j":38,"quote":39,"k":40,"semicolon":41,"backslash":42,"comma":43,
        "slash":44,"n":45,"m":46,"period":47,"tab":48,"space":49,"grave":50,
        "backspace":51,"escape":53,"f17":64,"f18":79,"f5":96,"f6":97,"f7":98,"f3":99,
        "f8":100,"f9":101,"f11":103,"f13":105,"f16":106,"f14":107,"f10":109,
        "f12":111,"f15":113,"home":115,"page_up":116,"forward_delete":117,
        "f4":118,"end":119,"f2":120,"page_down":121,"f1":122,
        "left":123,"right":124,"down":125,"up":126
    ]
}
