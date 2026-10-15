import AppKit
import FillLightCore

/// Draws a soft-edged light ring around the edge of its bounds.
/// The ring itself is drawn only when settings change; following the pointer
/// just moves a mask layer, so it stays cheap on large displays.
final class RingView: NSView {
    var brightness: Double = 0.5 { didSet { needsDisplay = true } }
    var kelvin: Double = LightMath.defaultKelvin { didSet { needsDisplay = true } }

    var fadeNearPointer = true {
        didSet {
            pointerMask.isHidden = !fadeNearPointer
            layer?.mask = fadeNearPointer ? pointerMask : nil
        }
    }

    private let pointerMask = CAGradientLayer()
    private let pointerHoleRadius: CGFloat = 110

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layerContentsRedrawPolicy = .onSetNeedsDisplay

        // A huge radial gradient: clear in the middle, opaque beyond the hole radius.
        // Outside its last stop it keeps the final color, so the rest of the ring stays visible.
        pointerMask.type = .radial
        pointerMask.startPoint = CGPoint(x: 0.5, y: 0.5)
        pointerMask.endPoint = CGPoint(x: 1, y: 1)
        layer?.mask = pointerMask
        movePointerHole(to: CGPoint(x: -10_000, y: -10_000))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override var isFlipped: Bool { false }

    override func layout() {
        super.layout()
        movePointerHole(to: lastPointer)
    }

    private var lastPointer = CGPoint(x: -10_000, y: -10_000)

    /// `point` is in this view's coordinates.
    func movePointerHole(to point: CGPoint) {
        lastPointer = point
        let side = max(bounds.width, bounds.height) * 4 + pointerHoleRadius * 4
        let halfSide = side / 2
        let solidFrom = pointerHoleRadius / halfSide
        let clearUntil = (pointerHoleRadius * 0.45) / halfSide

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        pointerMask.frame = CGRect(x: point.x - halfSide, y: point.y - halfSide, width: side, height: side)
        pointerMask.colors = [NSColor.clear.cgColor, NSColor.clear.cgColor, NSColor.black.cgColor]
        pointerMask.locations = [0, NSNumber(value: Double(clearUntil)), NSNumber(value: Double(solidFrom))]
        CATransaction.commit()
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.clear(bounds)

        let shortSide = Double(min(bounds.width, bounds.height))
        let thickness = CGFloat(LightMath.ringThickness(brightness: brightness, shortSide: shortSide))
        let feather = thickness * 0.6
        let c = LightMath.color(kelvin: kelvin)
        let color = CGColor(srgbRed: c.red, green: c.green, blue: c.blue, alpha: 1)

        // Solid band: everything outside a rounded rectangle inset by `thickness`,
        // plus a glow (shadow) that fades into the middle of the screen.
        let inner = bounds.insetBy(dx: thickness, dy: thickness)
        guard inner.width > 0, inner.height > 0 else {
            ctx.setFillColor(color)
            ctx.fill(bounds)
            return
        }
        let cornerRadius = min(thickness * 1.2, min(inner.width, inner.height) / 2)
        let band = CGMutablePath()
        band.addRect(bounds.insetBy(dx: -feather * 3, dy: -feather * 3))
        band.addPath(CGPath(roundedRect: inner, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil))

        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: feather, color: color)
        ctx.setFillColor(color)
        ctx.addPath(band)
        ctx.fillPath(using: .evenOdd)
        ctx.restoreGState()
    }
}
