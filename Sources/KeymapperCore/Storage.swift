import Foundation

public struct Storage {
    public static let directory = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/PrivateKeymapper", isDirectory: true)
    public static let config = directory.appendingPathComponent("config.json")
    public static let recovery = directory.appendingPathComponent("caps-recovery.json")
    public static func prepare() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
                                                attributes: [.posixPermissions: 0o700])
    }
    public static func save<T: Encodable>(_ value: T, at url: URL) throws {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(value).write(to: url, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }
    public static func loadConfiguration() throws -> Configuration {
        if !FileManager.default.fileExists(atPath: config.path) { try save(Configuration.initial, at: config) }
        return try Configuration.decode(Data(contentsOf: config))
    }
}
