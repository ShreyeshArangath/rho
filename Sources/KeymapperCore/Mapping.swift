import Foundation

public struct HIDMapping: Codable, Equatable {
    public let source: UInt64
    public let destination: UInt64
    public init(source: UInt64, destination: UInt64) { self.source = source; self.destination = destination }
    enum CodingKeys: String, CodingKey {
        case source = "HIDKeyboardModifierMappingSrc"
        case destination = "HIDKeyboardModifierMappingDst"
    }
}
public enum MappingPolicy {
    public static let caps: UInt64 = 0x700000039
    public static let f18: UInt64 = 0x70000006D
    public static let owned = HIDMapping(source: caps, destination: f18)
    public static func restore(in current: [HIDMapping], originalCaps: [HIDMapping]) -> [HIDMapping] {
        // Only undo our own mapping; preserve changes made by other software.
        guard current.filter({ $0.source == caps }) == [owned] else { return current }
        return current.filter { $0.source != caps } + originalCaps
    }
    public static func parse(_ text: String) throws -> [HIDMapping] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed == "(null)" { return [] }
        // hidutil prints an OpenStep property list; support JSON fixtures as well.
        if let data = trimmed.data(using: .utf8), let decoded = try? JSONDecoder().decode([HIDMapping].self, from: data) { return decoded }
        guard let start = trimmed.firstIndex(of: "("), let end = trimmed.lastIndex(of: ")"), start <= end else {
            throw ConfigError("Could not read hidutil keyboard mappings; no mappings were changed.")
        }
        let data = Data(trimmed[start...end].utf8)
        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        guard let rows = plist as? [[String: Any]] else { throw ConfigError("Unexpected hidutil mapping format.") }
        return try rows.map { row in
            func number(_ name: String) throws -> UInt64 {
                if let value = row[name] as? NSNumber { return value.uint64Value }
                if let value = row[name] as? String {
                    if value.hasPrefix("0x"), let result = UInt64(value.dropFirst(2), radix: 16) { return result }
                    if let result = UInt64(value) { return result }
                }
                throw ConfigError("Invalid hidutil mapping value for \(name).")
            }
            return try HIDMapping(source: number("HIDKeyboardModifierMappingSrc"), destination: number("HIDKeyboardModifierMappingDst"))
        }
    }
}
