import Foundation

public struct ChromeProfile {
    public let directory: URL

    public init(directory: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/Google/Chrome")) {
        self.directory = directory
    }

    public var processIdentifier: Int32? {
        guard let lock = try? FileManager.default.destinationOfSymbolicLink(atPath: directory.appendingPathComponent("SingletonLock").path),
              let separator = lock.lastIndex(of: "-"), separator != lock.startIndex,
              let pid = Int32(lock[lock.index(after: separator)...]), pid > 1 else { return nil }
        return pid
    }
}
