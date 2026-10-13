import Foundation
@testable import KeymapperCore

final class EngineTests {
    func testQuickEscapeThenTypingDoesNotLaunch() {
        let engine = Engine(configuration: .initial)
        _ = engine.process(code: 53, down: true, timestamp: 0)
        expectEqual(engine.process(code: 8, down: true, timestamp: 0.399), .tapAndPass(Stroke(code: 53)))
        expectEqual(engine.process(code: 8, down: false), .pass)
        expectEqual(engine.process(code: 1, down: true, timestamp: 0.8), .pass)
        expectEqual(engine.process(code: 53, down: false, timestamp: 1), .suppress)
    }
    func testEscapeMustStayHeld() {
        let engine = Engine(configuration: .initial)
        _ = engine.process(code: 53, down: true, timestamp: 0)
        expectEqual(engine.process(code: 53, down: false, timestamp: 0.5), .tap(Stroke(code: 53)))
        expectEqual(engine.process(code: 8, down: true, timestamp: 0.6), .pass)
    }
    func testAllSevenDefaultLaunchersAfterLongPress() {
        for binding in Configuration.initial.bindings where binding.action.type == .openApp {
            let engine = Engine(configuration: .initial)
            _ = engine.process(code: 53, down: true, timestamp: 0)
            expectEqual(engine.process(code: Keys.codes[binding.input.key]!, down: true, timestamp: 0.5), .launch(binding.action.bundleIdentifier!))
        }
    }
    func testPhysicalEscapeTapAndCapsLockPassThrough() {
        let engine = Engine(configuration: .initial)
        expectEqual(engine.process(code: 53, down: true), .suppress)
        expectEqual(engine.process(code: 53, down: false), .tap(Stroke(code: 53)))
        expectEqual(engine.process(code: 57, down: true), .pass)
        expectEqual(engine.process(code: 79, down: true), .pass)
    }
    func testShiftSpaceRepeatsAndReleasesEvenAfterShiftReleased() {
        let engine = Engine(configuration: .initial)
        let backspace = Stroke(code: 51)
        expectEqual(engine.process(code: 49, down: true, modifiers: [.shift]), .send(backspace, down: true, repeated: false))
        expectEqual(engine.process(code: 49, down: true, repeated: true), .send(backspace, down: true, repeated: true))
        expectEqual(engine.process(code: 49, down: false), .send(backspace, down: false, repeated: false))
        expectEqual(engine.process(code: 49, down: true), .pass)
    }
    func testExtraModifiersAndFnAreNotMatched() {
        for modifier in [Modifier.command, .option, .control] {
            let engine = Engine(configuration: .initial)
            expectEqual(engine.process(code: 49, down: true, modifiers: [.shift, modifier]), .pass)
        }
        let engine = Engine(configuration: .initial)
        expectEqual(engine.process(code: 49, down: true, modifiers: [.shift], eligible: false), .pass)
    }
    func testPassThroughPressDoesNotBecomeMappedDuringRepeat() {
        let engine = Engine(configuration: .initial)
        expectEqual(engine.process(code: 49, down: true), .pass)
        expectEqual(engine.process(code: 49, down: true, repeated: true, modifiers: [.shift]), .pass)
        expectEqual(engine.process(code: 49, down: false, modifiers: [.shift]), .pass)
    }
    func testModifiedEscapePassesThrough() {
        let engine = Engine(configuration: .initial)
        expectEqual(engine.process(code: 53, down: true, modifiers: [.command]), .pass)
        expectEqual(engine.process(code: 53, down: true, repeated: true, modifiers: [.command]), .pass)
        expectEqual(engine.process(code: 53, down: false), .pass)
    }
    func testEscapeLaunchOccursOnceAndConsumesLetterUpAfterEscapeRelease() {
        let engine = Engine(configuration: .initial)
        _ = engine.process(code: Keys.escape, down: true, timestamp: 0)
        expectEqual(engine.process(code: 8, down: true, timestamp: 0.4), .launch("com.openai.codex"))
        expectEqual(engine.process(code: 8, down: true, repeated: true, timestamp: 0.5), .suppress)
        expectEqual(engine.process(code: Keys.escape, down: false), .suppress)
        expectEqual(engine.process(code: 8, down: false), .suppress)
    }
    func testUnknownEscapeChordPassesThroughWithoutEscape() {
        let engine = Engine(configuration: .initial)
        _ = engine.process(code: Keys.escape, down: true, timestamp: 0)
        expectEqual(engine.process(code: 0, down: true, timestamp: 0.5), .pass)
        expectEqual(engine.process(code: 0, down: false), .pass)
        expectEqual(engine.process(code: Keys.escape, down: false), .suppress)
    }
    func testEscapeModifierCombinationDoesNotTapEscape() {
        let engine = Engine(configuration: .initial)
        _ = engine.process(code: Keys.escape, down: true, timestamp: 0)
        engine.modifiersChanged()
        expectEqual(engine.process(code: Keys.escape, down: false), .suppress)
        expectEqual(engine.process(code: Keys.escape, down: true, modifiers: [.command]), .pass)
        expectEqual(engine.process(code: Keys.escape, down: false), .pass)
    }
    func testEscapePressedWhileAnotherKeyIsHeldIsNotAlone() {
        let engine = Engine(configuration: .initial)
        _ = engine.process(code: 0, down: true)
        _ = engine.process(code: Keys.escape, down: true, timestamp: 0)
        expectEqual(engine.process(code: Keys.escape, down: false), .suppress)
    }
    func testResetReleasesSyntheticKeysAndClearsEscape() {
        let engine = Engine(configuration: .initial)
        _ = engine.process(code: 49, down: true, modifiers: [.shift])
        _ = engine.process(code: Keys.escape, down: true, timestamp: 0)
        expectEqual(engine.reset(), [Stroke(code: 51)])
        expectEqual(engine.process(code: Keys.escape, down: false), .pass)
        expectEqual(engine.process(code: 49, down: false), .pass)
    }
    func testCustomOutputModifiers() throws {
        let config = Configuration(bindings: [Binding(input: Chord(key: "a", modifiers: [.escape]), action: Action(type: .sendKey, key: "left", modifiers: [.command, .shift]))])
        try config.validate()
        let engine = Engine(configuration: config)
        _ = engine.process(code: Keys.escape, down: true, timestamp: 0)
        let target = Stroke(code: 123, modifiers: [.command, .shift])
        expectEqual(engine.process(code: 0, down: true, timestamp: 0.5), .send(target, down: true, repeated: false))
        expectEqual(engine.process(code: 0, down: false), .send(target, down: false, repeated: false))
    }
}
