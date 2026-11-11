import AppKit
import KeymapperCore

struct RhoCLI {
    private let appURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications/rho.app")

    private var application: NSRunningApplication? {
        NSRunningApplication.runningApplications(withBundleIdentifier: "local.privatekeymapper.app")
            .first { $0.bundleURL?.standardizedFileURL == appURL.standardizedFileURL }
    }

    private func start() throws {
        guard FileManager.default.isExecutableFile(atPath: appURL.appendingPathComponent("Contents/MacOS/PrivateKeymapper").path) else {
            throw ConfigError("rho.app is not installed at \(appURL.path). Run scripts/install.sh from the rho repository.")
        }
        if application != nil { print("rho is already running."); return }
        if NSRunningApplication.runningApplications(withBundleIdentifier: "local.privatekeymapper.app").contains(where: { !$0.isTerminated }) {
            throw ConfigError("Another copy of rho is running. Quit it before starting the installed app.")
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-g", appURL.path]
        try process.run(); process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw ConfigError("Could not start rho.app.") }
        let deadline = Date().addingTimeInterval(5)
        while application == nil && Date() < deadline { RunLoop.current.run(until: Date().addingTimeInterval(0.05)) }
        guard application != nil else { throw ConfigError("rho.app did not stay running. Check its Accessibility permission and configuration.") }
        print("Started rho.")
    }

    private func stop() throws {
        guard let app = application else { print("rho is stopped."); return }
        guard app.terminate() else { throw ConfigError("rho refused to quit.") }
        let deadline = Date().addingTimeInterval(5)
        while !app.isTerminated && Date() < deadline { RunLoop.current.run(until: Date().addingTimeInterval(0.05)) }
        guard app.isTerminated else { throw ConfigError("rho did not quit. No process was force-killed.") }
        print("Stopped rho.")
    }

    private func status() throws -> Int32 {
        guard let app = application else { print("rho: stopped"); return 1 }
        var count: UInt32 = 0
        guard CGGetEventTapList(0, nil, &count) == .success else { throw ConfigError("Could not inspect keyboard interception.") }
        let capacity = max(1, Int(count))
        let taps = UnsafeMutablePointer<CGEventTapInformation>.allocate(capacity: capacity)
        defer { taps.deallocate() }
        guard CGGetEventTapList(UInt32(capacity), taps, &count) == .success, count <= capacity else {
            throw ConfigError("Could not inspect keyboard interception. Run 'rho status' again.")
        }
        let active = (0..<Int(count)).contains { taps[$0].tappingProcess == app.processIdentifier && taps[$0].enabled }
        print(active ? "rho: active (PID \(app.processIdentifier))" : "rho: running, remapping inactive (check Pause, Accessibility, or Secure Input)")
        return active ? 0 : 1
    }

    func run(_ command: CLICommand) throws -> Int32 {
        switch command {
        case .help: print(CLICommand.usage)
        case .start: try start()
        case .stop: try stop()
        case .restart: try stop(); try start()
        case .status: return try status()
        case .config: print(Storage.config.path)
        case .shortcuts:
            try Storage.prepare()
            let configuration = try Storage.loadConfiguration()
            for binding in configuration.bindings {
                let modifiers = configuration.physicalModifiers(for: binding.input).map(\.rawValue).sorted()
                let chord = (modifiers + [binding.input.key]).joined(separator: "+")
                let action: String
                if binding.action.type == .openApp { action = binding.action.bundleIdentifier! }
                else { action = ((binding.action.modifiers ?? []).map(\.rawValue) + [binding.action.key!]).joined(separator: "+") }
                print("\(chord) -> \(action)")
            }
        case .bind, .unbind:
            if case .bind(_, let identifier) = command,
               NSWorkspace.shared.urlForApplication(withBundleIdentifier: identifier) == nil {
                throw ConfigError("App is not installed: \(identifier)")
            }
            try Storage.prepare()
            let previous = try Storage.loadConfiguration()
            let updated = try command.applying(to: previous)
            if updated == previous { print("Shortcuts unchanged."); return 0 }
            try Storage.save(updated, at: Storage.config)
            print("Saved shortcuts.")
            if application != nil { try stop(); try start() }
        }
        return 0
    }
}

do {
    exit(try RhoCLI().run(CLICommand.parse(Array(CommandLine.arguments.dropFirst()))))
} catch {
    fputs("rho: \(error.localizedDescription)\n", stderr)
    exit(1)
}
