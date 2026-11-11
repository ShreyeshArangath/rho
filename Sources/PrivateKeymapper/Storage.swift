import Foundation
import Darwin
import KeymapperCore

/// Hold this descriptor for the process lifetime. Recovery cannot race a running app.
final class InstanceLock {
    private let descriptor: Int32
    init() throws {
        try Storage.prepare()
        descriptor = Darwin.open(Storage.directory.appendingPathComponent("instance.lock").path, O_CREAT | O_RDWR, 0o600)
        guard descriptor >= 0 else { throw ConfigError("Cannot open the application lock.") }
        guard flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
            Darwin.close(descriptor)
            throw ConfigError("rho is already running. Quit it before recovery or starting another copy.")
        }
    }
    deinit { flock(descriptor, LOCK_UN); Darwin.close(descriptor) }
}

struct Recovery: Codable {
    let version: Int
    let originalCaps: [HIDMapping]
}
final class HIDController {
    private let lock = NSLock()
    private func run(_ arguments: [String]) throws -> String {
        let process = Process(); let stdout = Pipe(); let stderr = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/hidutil")
        process.arguments = arguments; process.standardOutput = stdout; process.standardError = stderr
        try process.run()
        let timeout = DispatchWorkItem { if process.isRunning { process.terminate() } }
        DispatchQueue.global().asyncAfter(deadline: .now() + 3, execute: timeout)
        let result = stdout.fileHandleForReading.readDataToEndOfFile()
        let error = stderr.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit(); timeout.cancel()
        guard process.terminationStatus == 0 else {
            throw ConfigError("hidutil failed: \(String(decoding: error, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines))")
        }
        return String(decoding: result, as: UTF8.self)
    }
    private func read() throws -> [HIDMapping] { try MappingPolicy.parse(run(["property", "--get", "UserKeyMapping"])) }
    private func write(_ mappings: [HIDMapping]) throws {
        let payload = try JSONEncoder().encode(["UserKeyMapping": mappings])
        _ = try run(["property", "--set", String(decoding: payload, as: UTF8.self)])
        guard try read() == mappings else { throw ConfigError("macOS did not apply the keyboard mapping. Recovery information has been kept.") }
    }
    func recover() throws {
        lock.lock(); defer { lock.unlock() }
        try recoverLocked()
    }
    private func recoverLocked() throws {
        guard FileManager.default.fileExists(atPath: Storage.recovery.path) else { return }
        let saved = try JSONDecoder().decode(Recovery.self, from: Data(contentsOf: Storage.recovery))
        guard saved.version == 1 else { throw ConfigError("Unsupported recovery file version; kept for manual recovery.") }
        let current = try read()
        let restored = MappingPolicy.restore(in: current, originalCaps: saved.originalCaps)
        if restored != current { try write(restored) }
        try FileManager.default.removeItem(at: Storage.recovery)
    }
}
