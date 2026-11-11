import Foundation
import KeymapperCore

final class CLICommandTests {
    func testParsesCommandsAndRejectsInvalidInput() throws {
        expectEqual(try CLICommand.parse([]), .start)
        expectEqual(try CLICommand.parse(["--help"]), .help)
        expectEqual(try CLICommand.parse(["status"]), .status)
        expectEqual(try CLICommand.parse(["bind", "Z", "us.zoom.xos"]), .bind(key: "z", bundleIdentifier: "us.zoom.xos"))
        expectEqual(try CLICommand.parse(["unbind", "Z"]), .unbind(key: "z"))
        for arguments in [["start", "extra"], ["bind", "z"], ["bind", "fn", "us.zoom.xos"],
                          ["bind", "z", "bad"], ["bind", "z", "us.zoom. xos"], ["unbind"], ["unbind", "caps_lock"], ["unknown"]] {
            expectThrows(try CLICommand.parse(arguments))
        }
    }

    func testBindPreservesOtherShortcutsAndAppliesWithSelectedSuperKey() throws {
        let custom = Binding(input: Chord(key: "z", modifiers: [.command]), action: Action(type: .sendKey, key: "space"))
        let oldLauncher = Binding(input: Chord(key: "z", modifiers: [.control, .option]),
                                  action: Action(type: .openApp, bundleIdentifier: "com.example.old"))
        let original = Configuration(bindings: [Configuration.initial.bindings[0], custom, oldLauncher], superKey: .controlOption)
        let command = try CLICommand.parse(["bind", "z", "us.zoom.xos"])
        let updated = try command.applying(to: original)
        expectEqual(updated.superKey, .controlOption)
        expectEqual(updated.bindings.count, 3)
        expectEqual(updated.bindings[0], original.bindings[0])
        expectEqual(updated.bindings[1], custom)
        expectEqual(try command.applying(to: updated), updated)
        let engine = Engine(configuration: updated)
        expectEqual(engine.process(code: 6, down: true, modifiers: [.control, .option]), .launch("us.zoom.xos"))
        expectEqual(engine.process(code: 6, down: false), .suppress)
        expectEqual(engine.process(code: 6, down: true, modifiers: [.command]), .send(Stroke(code: 49), down: true, repeated: false))
    }

    func testUnbindPreservesOtherActionsAndIsIdempotent() throws {
        let original = Configuration(bindings: Configuration.initial.bindings, superKey: .controlOption)
        let command = try CLICommand.parse(["unbind", "z"])
        let updated = try command.applying(to: original)
        expectEqual(updated.bindings, original.bindings.filter { $0.input.key != "z" })
        expectEqual(updated.superKey, .controlOption)
        expectEqual(try command.applying(to: updated), updated)
        let engine = Engine(configuration: updated)
        expectEqual(engine.process(code: 6, down: true, modifiers: [.control, .option]), .pass)
        expectEqual(engine.process(code: 49, down: true, modifiers: [.shift]), .send(Stroke(code: 51), down: true, repeated: false))
    }

    func testDefaultZoomShortcutWithFnAndControlOption() {
        for superKey: SuperKey in [.fn, .controlOption] {
            let engine = Engine(configuration: Configuration(bindings: Configuration.initial.bindings, superKey: superKey))
            engine.launcherKeyChanged(down: true, timestamp: 0)
            expectEqual(engine.process(code: 6, down: true, modifiers: superKey.modifiers, timestamp: 0.5), .launch("us.zoom.xos"))
        }
    }

    func testUnbindDoesNotDeleteAKeyRemapOnTheSameChord() throws {
        let original = Configuration(bindings: Configuration.initial.bindings, superKey: .shift)
        let updated = try CLICommand.parse(["unbind", "space"]).applying(to: original)
        expectEqual(updated, original)
        let engine = Engine(configuration: updated)
        expectEqual(engine.process(code: 49, down: true, modifiers: [.shift]), .send(Stroke(code: 51), down: true, repeated: false))
    }
}
