import AppKit

/// Owns one click-through overlay window per lit display.
final class OverlayController {
    private let settings: Settings
    private var windows: [CGDirectDisplayID: NSWindow] = [:]
    private var mouseMonitors: [Any] = []
    private(set) var isOn = false

    init(settings: Settings) {
        self.settings = settings
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { [weak self] _ in self?.refresh() }
    }

    func setOn(_ on: Bool) {
        isOn = on
        refresh()
    }

    /// Re-syncs windows with the current displays and settings.
    func refresh() {
        guard isOn else {
            windows.values.forEach { $0.orderOut(nil) }
            windows.removeAll()
            stopTrackingPointer()
            return
        }

        let screens = targetScreens()
        let wanted = Set(screens.compactMap(Self.displayID))
        for (id, window) in windows where !wanted.contains(id) {
            window.orderOut(nil)
            windows[id] = nil
        }

        for screen in screens {
            guard let id = Self.displayID(screen) else { continue }
            let window = windows[id] ?? makeWindow()
            windows[id] = window
            window.setFrame(screen.frame, display: false)
            if let ring = window.contentView as? RingView {
                ring.brightness = settings.brightness
                ring.kelvin = settings.kelvin
                ring.fadeNearPointer = settings.fadeNearPointer
            }
            window.orderFrontRegardless()
        }

        if settings.fadeNearPointer {
            startTrackingPointer()
            updatePointerHole()
        } else {
            stopTrackingPointer()
        }
    }

    /// Edge Light's rule: the built-in display when there is one (that's where the camera is),
    /// otherwise the primary display.
    private func targetScreens() -> [NSScreen] {
        if settings.allDisplays { return NSScreen.screens }
        let builtIn = NSScreen.screens.first { screen in
            Self.displayID(screen).map { CGDisplayIsBuiltin($0) != 0 } ?? false
        }
        return [builtIn ?? NSScreen.screens.first].compactMap { $0 }
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        // Above normal windows and the menu bar, on every Space, including full-screen apps.
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        // Best effort: ask macOS to leave the ring out of screenshots and screen sharing.
        // FILLLIGHT_CAPTURABLE=1 keeps it visible, for taking screenshots of the app itself.
        if ProcessInfo.processInfo.environment["FILLLIGHT_CAPTURABLE"] != "1" {
            window.sharingType = .none
        }
        window.contentView = RingView(frame: .zero)
        return window
    }

    private func startTrackingPointer() {
        guard mouseMonitors.isEmpty else { return }
        let events: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged, .rightMouseDragged]
        // Mouse (not keyboard) monitoring needs no Accessibility permission.
        if let global = NSEvent.addGlobalMonitorForEvents(matching: events, handler: { [weak self] _ in
            self?.updatePointerHole()
        }) {
            mouseMonitors.append(global)
        }
        if let local = NSEvent.addLocalMonitorForEvents(matching: events, handler: { [weak self] event in
            self?.updatePointerHole()
            return event
        }) {
            mouseMonitors.append(local)
        }
    }

    private func stopTrackingPointer() {
        mouseMonitors.forEach(NSEvent.removeMonitor)
        mouseMonitors.removeAll()
    }

    private func updatePointerHole() {
        let pointer = NSEvent.mouseLocation
        for window in windows.values {
            guard let ring = window.contentView as? RingView else { continue }
            let local = CGPoint(x: pointer.x - window.frame.minX, y: pointer.y - window.frame.minY)
            ring.movePointerHole(to: local)
        }
    }

    private static func displayID(_ screen: NSScreen) -> CGDirectDisplayID? {
        (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }
}
