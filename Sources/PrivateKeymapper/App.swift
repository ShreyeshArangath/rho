import AppKit
import Carbon
import ServiceManagement
import KeymapperCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let hid = HIDController()
    private var eventTap: EventTap?
    private var item: NSStatusItem!
    private var statusItem: NSMenuItem!
    private var toggleItem: NSMenuItem!
    private var loginItem: NSMenuItem!
    private var superKeyItems: [NSMenuItem] = []
    private var timer: Timer?
    private var observers: [NSObjectProtocol] = []
    private var desiredRunning = true
    private var sleeping = false
    private var running = false
    private var configReady = false
    private var status = "Starting…"

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        buildMenu()
        do {
            try hid.recover()
            let config = try Storage.loadConfiguration()
            eventTap = EventTap(configuration: config)
            eventTap?.onLaunch = { [weak self] in self?.launch($0) }
            eventTap?.onFailure = { [weak self] message in
                self?.desiredRunning = false; self?.stop(reason: message)
            }
            configReady = true
            updateSuperKeyMenu()
            reconcile()
        } catch { desiredRunning = false; setStatus(error.localizedDescription) }
        enableLaunchAtLogin()
        fputs("rho startup: \(status); login item state: \(SMAppService.mainApp.status.rawValue)\n", stderr)
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in self?.tick() }
        let center = NSWorkspace.shared.notificationCenter
        observers.append(center.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
            self?.sleeping = true; self?.stop(reason: "Suspended while sleeping")
        })
        observers.append(center.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.sleeping = false; self?.reconcile()
        })
    }
    private func buildMenu() {
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let logo = Bundle.main.url(forResource: "RhoMenu", withExtension: "png").flatMap { NSImage(contentsOf: $0) }
        logo?.size = NSSize(width: 22, height: 22)
        logo?.isTemplate = true
        item.button?.image = logo ?? NSImage(systemSymbolName: "keyboard", accessibilityDescription: "rho")
        item.button?.imagePosition = .imageOnly
        let menu = NSMenu()
        statusItem = NSMenuItem(title: status, action: nil, keyEquivalent: ""); menu.addItem(statusItem)
        menu.addItem(.separator())
        toggleItem = add("Pause", #selector(toggle), to: menu)
        _ = add("Grant Accessibility Permission…", #selector(grantPermission), to: menu)
        let superKeyMenu = NSMenu()
        for (title, modifier) in [("Fn / Globe", Modifier.fn), ("Shift ⇧", .shift), ("Control ⌃", .control), ("Option ⌥", .option), ("Command ⌘", .command)] {
            let choice = add(title, #selector(selectSuperKey(_:)), to: superKeyMenu)
            choice.representedObject = modifier.rawValue
            superKeyItems.append(choice)
        }
        let superKeyItem = NSMenuItem(title: "Super Key (hold 400 ms)", action: nil, keyEquivalent: "")
        superKeyItem.submenu = superKeyMenu
        menu.addItem(superKeyItem)
        _ = add("Open Configuration", #selector(openConfig), to: menu)
        _ = add("Reload Configuration", #selector(reloadConfig), to: menu)
        loginItem = add("Launch at Login", #selector(toggleLogin), to: menu)
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(.separator())
        _ = add("Quit rho", #selector(quit), to: menu)
        item.menu = menu
    }
    private func add(_ title: String, _ selector: Selector, to menu: NSMenu) -> NSMenuItem {
        let entry = NSMenuItem(title: title, action: selector, keyEquivalent: "")
        entry.target = self; menu.addItem(entry); return entry
    }
    private func setStatus(_ text: String) {
        status = text; statusItem?.title = text
        item?.button?.toolTip = "rho: \(text)"
        toggleItem?.title = desiredRunning ? "Pause" : "Resume"
        item?.button?.appearsDisabled = !running
    }
    private func reconcile() {
        guard desiredRunning, configReady else { return }
        if sleeping { return }
        if IsSecureEventInputEnabled() {
            if running { stop(reason: "Suspended — Secure Input is active") }
            else { setStatus("Suspended — Secure Input is active") }
            return
        }
        guard AXIsProcessTrusted() else {
            if running { stop(reason: "Inactive — grant Accessibility permission") }
            else { setStatus("Inactive — grant Accessibility permission") }
            return
        }
        guard !running else { return }
        do {
            try eventTap?.start()
            running = true; setStatus("Active")
        } catch {
            eventTap?.stop()
            setStatus(error.localizedDescription)
            desiredRunning = false; toggleItem.title = "Resume"
        }
    }
    private func stop(reason: String) {
        eventTap?.stop(); running = false
        setStatus(reason)
    }
    private func tick() {
        reconcile()
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }
    private func launch(_ identifier: String) {
        guard running else { return }
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: identifier) else {
            setStatus("App unavailable: \(identifier)"); return
        }
        let config = NSWorkspace.OpenConfiguration(); config.activates = true
        NSWorkspace.shared.openApplication(at: url, configuration: config) { [weak self] _, error in
            if let error { DispatchQueue.main.async { self?.setStatus("Could not open app: \(error.localizedDescription)") } }
        }
    }
    @objc private func toggle() {
        desiredRunning.toggle()
        if desiredRunning { reconcile() } else { stop(reason: "Paused") }
    }
    @objc private func grantPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") { NSWorkspace.shared.open(url) }
        desiredRunning = true; reconcile()
    }
    @objc private func openConfig() {
        do {
            if !FileManager.default.fileExists(atPath: Storage.config.path) { _ = try Storage.loadConfiguration() }
            // Open in TextEdit explicitly rather than executing an editor/shell from configuration.
            let editor = URL(fileURLWithPath: "/System/Applications/TextEdit.app")
            NSWorkspace.shared.open([Storage.config], withApplicationAt: editor, configuration: NSWorkspace.OpenConfiguration())
        } catch { setStatus(error.localizedDescription) }
    }
    private func updateSuperKeyMenu() {
        for entry in superKeyItems {
            entry.state = (entry.representedObject as? String) == eventTap?.engine.configuration.launcherModifier.rawValue ? .on : .off
        }
    }
    @objc private func selectSuperKey(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let modifier = Modifier(rawValue: raw) else { return }
        do {
            // Read the saved file so a menu change cannot overwrite edits made in an editor.
            var config = try Storage.loadConfiguration()
            config.superKey = modifier
            try config.validate()
            try Storage.save(config, at: Storage.config)
            applyConfiguration(config)
        } catch { setStatus("Super key unchanged: \(error.localizedDescription)") }
    }
    private func applyConfiguration(_ config: Configuration) {
        if let eventTap { eventTap.releaseKeys(); eventTap.engine.configuration = config }
        else {
            eventTap = EventTap(configuration: config)
            eventTap?.onLaunch = { [weak self] in self?.launch($0) }
            eventTap?.onFailure = { [weak self] message in self?.desiredRunning = false; self?.stop(reason: message) }
        }
        configReady = true
        updateSuperKeyMenu()
        setStatus(running ? "Active — configuration updated" : "Configuration loaded")
        reconcile()
    }
    @objc private func reloadConfig() {
        do {
            let config = try Storage.loadConfiguration()
            applyConfiguration(config)
        } catch { setStatus("Configuration unchanged: \(error.localizedDescription)") }
    }
    private func enableLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .notRegistered || SMAppService.mainApp.status == .notFound {
                try SMAppService.mainApp.register()
            }
            loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
            if SMAppService.mainApp.status == .requiresApproval {
                setStatus("Approve Launch at Login in System Settings")
                SMAppService.openSystemSettingsLoginItems()
            }
        } catch { setStatus("Launch at Login: \(error.localizedDescription)") }
    }
    @objc private func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() }
            else { try SMAppService.mainApp.register() }
            loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
            if SMAppService.mainApp.status == .requiresApproval {
                setStatus("Approve Launch at Login in System Settings")
                SMAppService.openSystemSettingsLoginItems()
            }
        } catch { setStatus("Launch at Login: \(error.localizedDescription)") }
    }
    @objc private func quit() { NSApp.terminate(nil) }
    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
        for observer in observers { NSWorkspace.shared.notificationCenter.removeObserver(observer) }
        stop(reason: "Stopped")
        if status.hasPrefix("Recovery needed:") { fputs("\(status)\n", stderr) }
    }
}
