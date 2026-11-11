import Foundation
import KeymapperCore

final class ChromeProfileTests {
    func testReadsOnlyTheSelectedProfileLock() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let normal = root.appendingPathComponent("normal")
        let isolated = root.appendingPathComponent("isolated")
        for directory in [normal, isolated] {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        try FileManager.default.createSymbolicLink(atPath: normal.appendingPathComponent("SingletonLock").path, withDestinationPath: "my-mac-26369")
        try FileManager.default.createSymbolicLink(atPath: isolated.appendingPathComponent("SingletonLock").path, withDestinationPath: "my-mac-5225")
        expectEqual(ChromeProfile(directory: normal).processIdentifier, 26369)
        expectEqual(ChromeProfile(directory: isolated).processIdentifier, 5225)
        expectEqual(ChromeProfile(directory: root).processIdentifier, nil)
    }

    func testRejectsMalformedProfileLocks() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let lock = directory.appendingPathComponent("SingletonLock")
        for destination in ["hostname", "hostname-no-pid", "hostname-0", "hostname-1", "-26369", "hostname-999999999999"] {
            try FileManager.default.createSymbolicLink(atPath: lock.path, withDestinationPath: destination)
            expectEqual(ChromeProfile(directory: directory).processIdentifier, nil)
            try FileManager.default.removeItem(at: lock)
        }
    }
}
