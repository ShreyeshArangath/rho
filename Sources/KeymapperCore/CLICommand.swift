import Foundation

public enum CLICommand: Equatable {
    case start, stop, restart, status, shortcuts, config, help
    case bind(key: String, bundleIdentifier: String)
    case unbind(key: String)

    public static let usage = """
    Usage: rho [command]

      start                         Start the menu-bar app (default)
      stop                          Stop the app
      restart                       Restart the app and reload saved shortcuts
      status                        Show whether keyboard remapping is active
      shortcuts                     List configured shortcuts
      bind <key> <bundle-id>        Assign a super-key launcher, e.g. bind z us.zoom.xos
      unbind <key>                  Remove a super-key launcher
      config                        Print the configuration file path
      help                          Show this help

    Binding changes preserve other shortcuts and restart the app if it is running.
    """

    public static func parse(_ arguments: [String]) throws -> CLICommand {
        guard let name = arguments.first else { return .start }
        let commands: [String: CLICommand] = ["start": .start, "stop": .stop, "restart": .restart,
            "status": .status, "shortcuts": .shortcuts, "config": .config, "help": .help,
            "--help": .help, "-h": .help]
        if let command = commands[name], arguments.count == 1 { return command }
        if name == "bind", arguments.count == 3 {
            let key = arguments[1].lowercased(), identifier = arguments[2]
            guard Keys.codes[key] != nil else { throw ConfigError("Unknown launcher key '\(key)'.") }
            let probe = Configuration(bindings: [Binding(input: Chord(key: key, modifiers: [.fn]),
                action: Action(type: .openApp, bundleIdentifier: identifier))])
            try probe.validate()
            return .bind(key: key, bundleIdentifier: identifier)
        }
        if name == "unbind", arguments.count == 2 {
            let key = arguments[1].lowercased()
            guard Keys.codes[key] != nil else { throw ConfigError("Unknown launcher key '\(key)'.") }
            return .unbind(key: key)
        }
        throw ConfigError("Invalid command or arguments. Run 'rho help'.")
    }

    public func applying(to configuration: Configuration) throws -> Configuration {
        var updated = configuration
        let key: String
        switch self {
        case .bind(let input, _), .unbind(let input): key = input
        default: return updated
        }
        updated.bindings.removeAll {
            let matches = $0.input.key == key && configuration.physicalModifiers(for: $0.input) == configuration.launcher.modifiers
            if case .unbind = self { return matches && $0.action.type == .openApp }
            return matches
        }
        if case .bind(_, let identifier) = self {
            updated.bindings.append(Binding(input: Chord(key: key, modifiers: [.fn]),
                action: Action(type: .openApp, bundleIdentifier: identifier)))
        }
        try updated.validate()
        return updated
    }
}
