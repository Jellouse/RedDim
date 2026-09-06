import AppKit

@MainActor
final class StatusItemController: NSObject {
    private let statusItem: NSStatusItem
    private let toggleItem = NSMenuItem(title: "On", action: #selector(toggleEnabled(_:)), keyEquivalent: "")
    private let autoItem = NSMenuItem(title: "Auto sunset", action: #selector(toggleAuto(_:)), keyEquivalent: "")
    private let slider = NSSlider(value: 70, minValue: 0, maxValue: 100, target: nil, action: nil)
    private let appliedItem = NSMenuItem(title: "Applied: —", action: nil, keyEquivalent: "")
    private let engine = ColorFilterEngine.shared
    private let auto = AutoSunController.shared

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        if let button = statusItem.button {
            let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .regular)
            let image = NSImage(systemSymbolName: "circle.lefthalf.filled", accessibilityDescription: "RedDim")
            button.image = image?.withSymbolConfiguration(config)
            button.imagePosition = .imageOnly
        }

        slider.target = self
        slider.action = #selector(intensityChanged(_:))
        slider.isContinuous = true
        slider.controlSize = .small
        slider.frame = NSRect(x: 0, y: 0, width: 160, height: 20)

        let sliderItem = NSMenuItem()
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 180, height: 28))
        slider.frame.origin = NSPoint(x: 10, y: 4)
        container.addSubview(slider)
        sliderItem.view = container

        appliedItem.isEnabled = false

        let menu = NSMenu()
        toggleItem.target = self
        autoItem.target = self
        menu.addItem(toggleItem)
        menu.addItem(autoItem)
        menu.addItem(sliderItem)
        menu.addItem(appliedItem)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit", action: #selector(quitApp(_:)), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        statusItem.menu = menu

        auto.onAppliedIntensityChange = { [weak self] value in
            self?.appliedItem.title = String(format: "Applied: %.0f%%", value)
        }

        refreshMenuState()
        syncEngine()
    }

    private func refreshMenuState() {
        let enabled = Preferences.isEnabled
        toggleItem.title = enabled ? "On" : "Off"
        toggleItem.state = enabled ? .on : .off
        autoItem.state = Preferences.autoSun ? .on : .off
        slider.doubleValue = Preferences.intensity
    }

    private func syncEngine() {
        if Preferences.isEnabled {
            auto.start()
            auto.tick()
        } else {
            auto.stop()
            Task { await engine.setEnabled(false) }
            appliedItem.title = "Applied: off"
        }
    }

    @objc private func toggleEnabled(_ sender: NSMenuItem) {
        Preferences.isEnabled = !Preferences.isEnabled
        refreshMenuState()
        syncEngine()
    }

    @objc private func toggleAuto(_ sender: NSMenuItem) {
        Preferences.autoSun = !Preferences.autoSun
        refreshMenuState()
        if Preferences.isEnabled {
            auto.tick()
        }
    }

    @objc private func intensityChanged(_ sender: NSSlider) {
        Preferences.intensity = sender.doubleValue
        if Preferences.isEnabled {
            auto.tick()
        } else {
            engine.setIntensity(sender.doubleValue)
        }
    }

    @objc private func quitApp(_ sender: Any?) {
        auto.stop()
        Task {
            await engine.setEnabled(false)
            NSApp.terminate(nil)
        }
    }
}
