import AppKit
import Darwin

var instanceLock: InstanceLock?
do {
    instanceLock = try InstanceLock()
    if CommandLine.arguments.contains("--recover") {
        try HIDController().recover()
        print("Recovery complete. Existing unrelated mappings were preserved.")
        exit(0)
    }
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    withExtendedLifetime(delegate) { app.run() }
} catch {
    fputs("rho: \(error.localizedDescription)\n", stderr)
    exit(1)
}
