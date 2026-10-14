import Foundation
@testable import KeymapperCore

final class EngineTests {
    func testControlOptionLaunchesImmediatelyAndOnlyWithBothModifiers() {
        for binding in Configuration.initial.bindings where binding.action.type == .openApp {
            let engine = Engine(configuration: Configuration(bindings: Configuration.initial.bindings, superKey: .controlOption))
            let code = Keys.codes[binding.input.key]!
            expectEqual(engine.process(code: code, down: true, modifiers: [.control, .option], timestamp: 0), .launch(binding.action.bundleIdentifier!))
            expectEqual(engine.process(code: code, down: true, repeated: true, modifiers: [.control, .option], timestamp: 0.01), .suppress)
            expectEqual(engine.process(code: code, down: false), .suppress)
            for modifiers: Set<Modifier> in [[], [.control], [.option], [.fn], [.control, .option, .shift], [.control, .option, .command]] {
                expectEqual(engine.process(code: code, down: true, modifiers: modifiers, timestamp: 0.02), .pass)
                _ = engine.process(code: code, down: false, modifiers: modifiers)
            }
        }
        let engine = Engine(configuration: Configuration(bindings: Configuration.initial.bindings, superKey: .controlOption))
        expectEqual(engine.process(code: 0, down: true, modifiers: [.control, .option]), .pass)
        expectEqual(engine.process(code: 49, down: true, modifiers: [.shift]), .send(Stroke(code: 51), down: true, repeated: false))
        _ = engine.reset()
        expectEqual(engine.process(code: 5, down: true, modifiers: [.control]), .pass)
        expectEqual(engine.process(code: 5, down: true, repeated: true, modifiers: [.control, .option]), .pass)
    }
    func testEverySuperKeyWithNativeShortcutsAndRelease() {
        for modifier in [Modifier.fn, .shift, .control, .option, .command] {
            let engine = Engine(configuration: Configuration(bindings: Configuration.initial.bindings, superKey: SuperKey(rawValue: modifier.rawValue)))
            engine.launcherKeyChanged(down: true, timestamp: 0)
            expectEqual(engine.process(code: 5, down: true, modifiers: [modifier], timestamp: 0.399), .pass)
            _ = engine.process(code: 5, down: false, modifiers: [modifier], timestamp: 0.4)
            expectEqual(engine.process(code: 8, down: true, modifiers: [modifier], timestamp: 1), .pass)
            engine.launcherKeyChanged(down: false, timestamp: 1.1)
            engine.launcherKeyChanged(down: true, timestamp: 2)
            expectEqual(engine.process(code: 5, down: true, modifiers: [modifier], timestamp: 2.4), .launch("com.mitchellh.ghostty"))
            expectEqual(engine.process(code: 5, down: true, repeated: true, modifiers: [modifier], timestamp: 2.5), .suppress)
            engine.launcherKeyChanged(down: false, timestamp: 2.6)
            expectEqual(engine.process(code: 5, down: false), .suppress)
            expectEqual(engine.process(code: 49, down: true, modifiers: [.shift], timestamp: 3), .send(Stroke(code: 51), down: true, repeated: false))
            _ = engine.reset()
            engine.launcherKeyChanged(down: true, timestamp: 4)
            let extra: Modifier = modifier == .command ? .control : .command
            expectEqual(engine.process(code: 5, down: true, modifiers: [modifier, extra], timestamp: 4.5), .pass)
        }
    }
    func testChangingSuperKeyClearsHoldAndKeepsActions() {
        let engine = Engine(configuration: .initial)
        engine.launcherKeyChanged(down: true, timestamp: 0)
        _ = engine.reset()
        engine.configuration.superKey = .option
        expectEqual(engine.process(code: 5, down: true, modifiers: [.option], timestamp: 1), .pass)
        _ = engine.reset()
        engine.launcherKeyChanged(down: true, timestamp: 2)
        expectEqual(engine.process(code: 5, down: true, modifiers: [.option], timestamp: 2.5), .launch("com.mitchellh.ghostty"))
    }
    func testFunctionThresholdAndQuickChordCancellation() {
        let engine = Engine(configuration: .initial)
        engine.launcherKeyChanged(down: true, timestamp: 0)
        expectEqual(engine.process(code: 5, down: true, modifiers: [.fn], timestamp: 0.399), .pass)
        _ = engine.process(code: 5, down: false, modifiers: [.fn], timestamp: 0.4)
        expectEqual(engine.process(code: 8, down: true, modifiers: [.fn], timestamp: 1), .pass)
        engine.launcherKeyChanged(down: false, timestamp: 1.1)
        engine.launcherKeyChanged(down: true, timestamp: 2)
        expectEqual(engine.process(code: 5, down: true, modifiers: [.fn], timestamp: 2.4), .launch("com.mitchellh.ghostty"))
    }
    func testFunctionMustStayHeld() {
        let engine = Engine(configuration: .initial)
        engine.launcherKeyChanged(down: true, timestamp: 0)
        engine.launcherKeyChanged(down: false, timestamp: 0.5)
        expectEqual(engine.process(code: 5, down: true, timestamp: 0.6), .pass)
    }
    func testFunctionFlagWithoutPressDoesNotLaunch() {
        let engine = Engine(configuration: .initial)
        expectEqual(engine.process(code: 5, down: true, modifiers: [.fn], timestamp: 1), .pass)
    }
    func testAllSevenDefaultLaunchersAfterLongPress() {
        for binding in Configuration.initial.bindings where binding.action.type == .openApp {
            let engine = Engine(configuration: .initial)
            engine.launcherKeyChanged(down: true, timestamp: 0)
            expectEqual(engine.process(code: Keys.codes[binding.input.key]!, down: true, modifiers: [.fn], timestamp: 0.5), .launch(binding.action.bundleIdentifier!))
        }
    }
    func testEscapeAndCapsLockPassThrough() {
        let engine = Engine(configuration: .initial)
        expectEqual(engine.process(code: 53, down: true), .pass)
        expectEqual(engine.process(code: 53, down: false), .pass)
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
    func testExtraModifiersAreNotMatched() {
        for modifier in [Modifier.command, .option, .control, .fn] {
            let engine = Engine(configuration: .initial)
            expectEqual(engine.process(code: 49, down: true, modifiers: [.shift, modifier]), .pass)
        }
    }
    func testPassThroughPressDoesNotBecomeMappedDuringRepeat() {
        let engine = Engine(configuration: .initial)
        expectEqual(engine.process(code: 49, down: true), .pass)
        expectEqual(engine.process(code: 49, down: true, repeated: true, modifiers: [.shift]), .pass)
        expectEqual(engine.process(code: 49, down: false, modifiers: [.shift]), .pass)
    }
    func testLaunchOnceAndConsumesLetterUpAfterFunctionRelease() {
        let engine = Engine(configuration: .initial)
        engine.launcherKeyChanged(down: true, timestamp: 0)
        expectEqual(engine.process(code: 8, down: true, modifiers: [.fn], timestamp: 0.4), .launch("com.openai.codex"))
        expectEqual(engine.process(code: 8, down: true, repeated: true, modifiers: [.fn], timestamp: 0.5), .suppress)
        engine.launcherKeyChanged(down: false, timestamp: 0.6)
        expectEqual(engine.process(code: 8, down: false), .suppress)
    }
    func testUnknownFunctionChordPassesThrough() {
        let engine = Engine(configuration: .initial)
        engine.launcherKeyChanged(down: true, timestamp: 0)
        expectEqual(engine.process(code: 0, down: true, modifiers: [.fn], timestamp: 0.5), .pass)
        expectEqual(engine.process(code: 0, down: false, modifiers: [.fn]), .pass)
    }
    func testAdditionalModifiersDoNotLaunch() {
        let engine = Engine(configuration: .initial)
        engine.launcherKeyChanged(down: true, timestamp: 0)
        expectEqual(engine.process(code: 8, down: true, modifiers: [.fn, .command], timestamp: 0.5), .pass)
    }
    func testMissingReleaseFlagsClearFunctionHold() {
        let engine = Engine(configuration: .initial)
        engine.launcherKeyChanged(down: true, timestamp: 0)
        expectEqual(engine.process(code: 0, down: true, timestamp: 0.5), .pass)
        expectEqual(engine.process(code: 5, down: true, modifiers: [.fn], timestamp: 1), .pass)
    }
    func testResetReleasesSyntheticKeysAndClearsFunction() {
        let engine = Engine(configuration: .initial)
        _ = engine.process(code: 49, down: true, modifiers: [.shift])
        engine.launcherKeyChanged(down: true, timestamp: 0)
        expectEqual(engine.reset(), [Stroke(code: 51)])
        expectEqual(engine.process(code: 49, down: false), .pass)
        expectEqual(engine.process(code: 5, down: true, modifiers: [.fn], timestamp: 1), .pass)
    }
    func testCustomOutputModifiers() throws {
        let config = Configuration(bindings: [Binding(input: Chord(key: "a", modifiers: [.fn]), action: Action(type: .sendKey, key: "left", modifiers: [.command, .shift]))])
        try config.validate()
        let engine = Engine(configuration: config)
        engine.launcherKeyChanged(down: true, timestamp: 0)
        let target = Stroke(code: 123, modifiers: [.command, .shift])
        expectEqual(engine.process(code: 0, down: true, modifiers: [.fn], timestamp: 0.5), .send(target, down: true, repeated: false))
        expectEqual(engine.process(code: 0, down: false), .send(target, down: false, repeated: false))
    }
}
