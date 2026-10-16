import AppKit
import Carbon.HIToolbox
import FillLightCore

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let settings = Settings()
    private lazy var overlay = OverlayController(settings: settings)
    private var statusItem: NSStatusItem!
    private var hotKey: HotKey?

    private let toggleItem = NSMenuItem(title: "", action: #selector(toggleLight), keyEquivalent: "l")
    private let fadeItem = NSMenuItem(title: "Fade Near Pointer", action: #selector(toggleFade), keyEquivalent: "")
    private let allDisplaysItem = NSMenuItem(title: "Light All Displays", action: #selector(toggleAllDisplays), keyEquivalent: "")
    private let whiteItem = NSMenuItem(title: "White Light", action: #selector(useWhiteLight), keyEquivalent: "")
    private let customColorItem = NSMenuItem(title: "Custom Color…", action: #selector(chooseCustomColor), keyEquivalent: "")
    private let hdrItem = NSMenuItem(title: "HDR Boost", action: #selector(toggleHDR), keyEquivalent: "")
    private let maxBrightnessItem = NSMenuItem(title: "Max Screen Brightness While On", action: #selector(toggleMaxBrightness), keyEquivalent: "")
    private let brightnessTip = NSMenuItem(title: "Tip: turn display brightness up for more light", action: nil, keyEquivalent: "")
    private let brightnessSlider = NSSlider()
    private let warmthSlider = NSSlider()

    func applicationDidFinishLaunching(_ notification: Notification) {
        settings.onChange = { [weak self] in self?.overlay.refresh() }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.menu = buildMenu()
        updateUI()

        // ⌃⌥L toggles the light from anywhere.
        hotKey = HotKey(keyCode: kVK_ANSI_L, modifiers: controlKey | optionKey) { [weak self] in
            self?.toggleLight()
        }
    }

    // MARK: Menu

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self

        toggleItem.target = self
        toggleItem.keyEquivalentModifierMask = [.control, .option]
        menu.addItem(toggleItem)
        menu.addItem(.separator())

        brightnessSlider.minValue = 0
        brightnessSlider.maxValue = 1
        brightnessSlider.doubleValue = settings.brightness
        brightnessSlider.target = self
        brightnessSlider.action = #selector(brightnessChanged)
        brightnessSlider.isContinuous = true
        menu.addItem(sliderItem(title: "Brightness", slider: brightnessSlider))

        warmthSlider.minValue = LightMath.kelvinRange.lowerBound
        warmthSlider.maxValue = LightMath.kelvinRange.upperBound
        // Slider runs cool → warm, left to right.
        warmthSlider.doubleValue = flipKelvin(settings.kelvin)
        warmthSlider.target = self
        warmthSlider.action = #selector(warmthChanged)
        warmthSlider.isContinuous = true
        menu.addItem(sliderItem(title: "Warmth", slider: warmthSlider))

        whiteItem.target = self
        menu.addItem(whiteItem)
        customColorItem.target = self
        menu.addItem(customColorItem)

        menu.addItem(.separator())
        fadeItem.target = self
        menu.addItem(fadeItem)
        allDisplaysItem.target = self
        menu.addItem(allDisplaysItem)

        menu.addItem(.separator())
        hdrItem.target = self
        hdrItem.toolTip = "Light the ring brighter than normal white on HDR (XDR) displays. Uses more power."
        menu.addItem(hdrItem)
        maxBrightnessItem.target = self
        maxBrightnessItem.toolTip = "Turns the built-in display all the way up while the light is on, and back when it goes off."
        // Private API: hide the option if this macOS doesn't have it.
        if DisplayBrightness.isAvailable {
            menu.addItem(maxBrightnessItem)
        } else {
            brightnessTip.isEnabled = false
            menu.addItem(brightnessTip)
        }

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit FillLight", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        return menu
    }

    private func sliderItem(title: String, slider: NSSlider) -> NSMenuItem {
        let label = NSTextField(labelWithString: title)
        label.font = .menuFont(ofSize: 0)
        label.textColor = .secondaryLabelColor

        let stack = NSStackView(views: [label, slider])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        stack.edgeInsets = NSEdgeInsets(top: 4, left: 20, bottom: 6, right: 16)
        stack.frame = NSRect(x: 0, y: 0, width: 240, height: 52)
        slider.widthAnchor.constraint(equalToConstant: 204).isActive = true

        let item = NSMenuItem()
        item.view = stack
        return item
    }

    func menuWillOpen(_ menu: NSMenu) { updateUI() }

    private func updateUI() {
        let on = overlay.isOn
        toggleItem.title = on ? "Turn Light Off" : "Turn Light On"
        fadeItem.state = settings.fadeNearPointer ? .on : .off
        allDisplaysItem.state = settings.allDisplays ? .on : .off
        whiteItem.state = settings.useCustomColor ? .off : .on
        customColorItem.state = settings.useCustomColor ? .on : .off
        customColorItem.image = settings.useCustomColor ? swatch(settings.customColor) : nil
        let hdrAvailable = OverlayController.hdrAvailable
        hdrItem.title = hdrAvailable ? "HDR Boost" : "HDR Boost (needs an HDR display)"
        hdrItem.isEnabled = hdrAvailable
        hdrItem.state = hdrAvailable && settings.hdrBoost ? .on : .off
        maxBrightnessItem.state = settings.maxScreenBrightness ? .on : .off
        let symbol = on ? "lightbulb.fill" : "lightbulb"
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: "FillLight")
        image?.isTemplate = true
        statusItem.button?.image = image
    }

    /// The slider shows warm on the right, but settings store plain Kelvin.
    private func flipKelvin(_ value: Double) -> Double {
        LightMath.kelvinRange.upperBound + LightMath.kelvinRange.lowerBound - value
    }

    /// filllight://on, filllight://off, filllight://toggle — handy for Shortcuts or scripts.
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls where url.scheme == "filllight" {
            switch url.host {
            case "on": overlay.setOn(true)
            case "off": overlay.setOn(false)
            case "toggle": overlay.setOn(!overlay.isOn)
            default: continue
            }
        }
        updateUI()
    }

    // MARK: Actions

    @objc private func toggleLight() {
        overlay.setOn(!overlay.isOn)
        updateUI()
    }

    @objc private func brightnessChanged() {
        settings.brightness = brightnessSlider.doubleValue
    }

    @objc private func warmthChanged() {
        // Moving the warmth slider means "white light again".
        settings.useCustomColor = false
        settings.kelvin = flipKelvin(warmthSlider.doubleValue)
    }

    @objc private func toggleHDR() {
        settings.hdrBoost.toggle()
        updateUI()
    }

    @objc private func toggleMaxBrightness() {
        settings.maxScreenBrightness.toggle()
        updateUI()
    }

    /// Give the display its own brightness back if we turned it up.
    func applicationWillTerminate(_ notification: Notification) {
        overlay.setOn(false)
    }

    @objc private func useWhiteLight() {
        settings.useCustomColor = false
        updateUI()
    }

    @objc private func chooseCustomColor() {
        let panel = NSColorPanel.shared
        panel.showsAlpha = false
        panel.isContinuous = true
        panel.color = nsColor(settings.customColor)
        panel.setTarget(self)
        panel.setAction(#selector(colorPanelChanged(_:)))

        settings.useCustomColor = true
        // Show the color while picking it.
        if !overlay.isOn { overlay.setOn(true) }
        updateUI()

        // A menu bar app is never frontmost on its own; bring the panel forward.
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    @objc private func colorPanelChanged(_ panel: NSColorPanel) {
        guard let rgb = panel.color.usingColorSpace(.sRGB) else { return }
        settings.customColor = LightColor(red: rgb.redComponent, green: rgb.greenComponent, blue: rgb.blueComponent)
        settings.useCustomColor = true
        updateUI()
    }

    private func nsColor(_ c: LightColor) -> NSColor {
        NSColor(srgbRed: c.red, green: c.green, blue: c.blue, alpha: 1)
    }

    /// A small round swatch shown next to "Custom Color…".
    private func swatch(_ c: LightColor) -> NSImage {
        NSImage(size: NSSize(width: 12, height: 12), flipped: false) { rect in
            self.nsColor(c).setFill()
            NSBezierPath(ovalIn: rect.insetBy(dx: 0.5, dy: 0.5)).fill()
            NSColor.separatorColor.setStroke()
            NSBezierPath(ovalIn: rect.insetBy(dx: 0.5, dy: 0.5)).stroke()
            return true
        }
    }

    @objc private func toggleFade() {
        settings.fadeNearPointer.toggle()
        updateUI()
    }

    @objc private func toggleAllDisplays() {
        settings.allDisplays.toggle()
        updateUI()
    }
}
