import Foundation
import Darwin

// Dependency-free test runner: Apple Command Line Tools do not include XCTest.
var failures = 0
func fail(_ message: String, file: StaticString, line: UInt) {
    failures += 1
    print("FAIL \(file):\(line): \(message)")
}
func expectEqual<T: Equatable>(_ actual: @autoclosure () throws -> T, _ expected: @autoclosure () throws -> T,
                               file: StaticString = #filePath, line: UInt = #line) {
    do {
        let lhs = try actual(), rhs = try expected()
        if lhs != rhs { fail("Expected \(rhs), got \(lhs)", file: file, line: line) }
    } catch { fail("Unexpected error: \(error)", file: file, line: line) }
}
func expectThrows<T>(_ expression: @autoclosure () throws -> T, file: StaticString = #filePath, line: UInt = #line) {
    do { _ = try expression(); fail("Expected an error", file: file, line: line) } catch {}
}

var tests: [(String, () throws -> Void)] = []
let configurationTests = ConfigurationTests()
tests.append(("ConfigurationTests.testDefaultsRoundTrip", configurationTests.testDefaultsRoundTrip))
tests.append(("ConfigurationTests.testDuplicateRegardlessOfModifierOrder", configurationTests.testDuplicateRegardlessOfModifierOrder))
tests.append(("ConfigurationTests.testRejectInvalidVersionsKeysAndActions", configurationTests.testRejectInvalidVersionsKeysAndActions))
tests.append(("ConfigurationTests.testMalformedJSONAndDuplicateModifiers", configurationTests.testMalformedJSONAndDuplicateModifiers))
let engineTests = EngineTests()
tests.append(("EngineTests.testQuickEscapeThenTypingDoesNotLaunch", engineTests.testQuickEscapeThenTypingDoesNotLaunch))
tests.append(("EngineTests.testEscapeMustStayHeld", engineTests.testEscapeMustStayHeld))
tests.append(("EngineTests.testAllSevenDefaultLaunchersAfterLongPress", engineTests.testAllSevenDefaultLaunchersAfterLongPress))
tests.append(("EngineTests.testPhysicalEscapeTapAndCapsLockPassThrough", engineTests.testPhysicalEscapeTapAndCapsLockPassThrough))
tests.append(("EngineTests.testShiftSpaceRepeatsAndReleasesEvenAfterShiftReleased", engineTests.testShiftSpaceRepeatsAndReleasesEvenAfterShiftReleased))
tests.append(("EngineTests.testExtraModifiersAndFnAreNotMatched", engineTests.testExtraModifiersAndFnAreNotMatched))
tests.append(("EngineTests.testPassThroughPressDoesNotBecomeMappedDuringRepeat", engineTests.testPassThroughPressDoesNotBecomeMappedDuringRepeat))
tests.append(("EngineTests.testModifiedEscapePassesThrough", engineTests.testModifiedEscapePassesThrough))
tests.append(("EngineTests.testEscapeLaunchOccursOnceAndConsumesLetterUpAfterEscapeRelease", engineTests.testEscapeLaunchOccursOnceAndConsumesLetterUpAfterEscapeRelease))
tests.append(("EngineTests.testUnknownEscapeChordPassesThroughWithoutEscape", engineTests.testUnknownEscapeChordPassesThroughWithoutEscape))
tests.append(("EngineTests.testEscapeModifierCombinationDoesNotTapEscape", engineTests.testEscapeModifierCombinationDoesNotTapEscape))
tests.append(("EngineTests.testEscapePressedWhileAnotherKeyIsHeldIsNotAlone", engineTests.testEscapePressedWhileAnotherKeyIsHeldIsNotAlone))
tests.append(("EngineTests.testResetReleasesSyntheticKeysAndClearsEscape", engineTests.testResetReleasesSyntheticKeysAndClearsEscape))
tests.append(("EngineTests.testCustomOutputModifiers", engineTests.testCustomOutputModifiers))
let mappingTests = MappingTests()
tests.append(("MappingTests.testRestorePreservesUnrelatedMappings", mappingTests.testRestorePreservesUnrelatedMappings))
tests.append(("MappingTests.testRecoveryRemovesOnlyOwnedMappingWithoutOriginalCaps", mappingTests.testRecoveryRemovesOnlyOwnedMappingWithoutOriginalCaps))
tests.append(("MappingTests.testExternalCapsChangeAndRebootArePreserved", mappingTests.testExternalCapsChangeAndRebootArePreserved))
tests.append(("MappingTests.testParseHidutilOutput", mappingTests.testParseHidutilOutput))
for (name, test) in tests {
    let previous = failures
    do { try test() } catch { failures += 1; print("FAIL \(name): \(error)") }
    if previous == failures { print("PASS \(name)") }
}
print("\(tests.count) tests, \(failures) failures")
exit(failures == 0 ? 0 : 1)
