import Foundation
@testable import KeymapperCore

final class MappingTests {
    let other = HIDMapping(source: 0x700000004, destination: 0x700000005)
    let prior = HIDMapping(source: MappingPolicy.caps, destination: 0x700000029)
    func testRestorePreservesUnrelatedMappings() throws {
        let installed = [other, MappingPolicy.owned]
        expectEqual(installed, [other, MappingPolicy.owned])
        let newlyAdded = HIDMapping(source: 0x700000006, destination: 0x700000007)
        expectEqual(MappingPolicy.restore(in: installed + [newlyAdded], originalCaps: [prior]), [other, newlyAdded, prior])
    }
    func testRecoveryRemovesOnlyOwnedMappingWithoutOriginalCaps() throws {
        expectEqual(MappingPolicy.restore(in: [other, MappingPolicy.owned], originalCaps: []), [other])
    }
    func testExternalCapsChangeAndRebootArePreserved() {
        let external = HIDMapping(source: MappingPolicy.caps, destination: 0x70000002A)
        expectEqual(MappingPolicy.restore(in: [other, external], originalCaps: [prior]), [other, external])
        expectEqual(MappingPolicy.restore(in: [], originalCaps: [prior]), [])
    }
    func testParseHidutilOutput() throws {
        expectEqual(try MappingPolicy.parse("(null)\n"), [])
        expectEqual(try MappingPolicy.parse("(\n { HIDKeyboardModifierMappingSrc = 30064771129; HIDKeyboardModifierMappingDst = 30064771181; }\n)"), [MappingPolicy.owned])
        expectEqual(try MappingPolicy.parse("(\n { HIDKeyboardModifierMappingSrc = 0x700000039; HIDKeyboardModifierMappingDst = 0x70000006D; }\n)"), [MappingPolicy.owned])
        expectEqual(try MappingPolicy.parse(String(decoding: JSONEncoder().encode([other]), as: UTF8.self)), [other])
        expectThrows(try MappingPolicy.parse("unexpected"))
        expectThrows(try MappingPolicy.parse("({ HIDKeyboardModifierMappingSrc = bad; })"))
    }
}
