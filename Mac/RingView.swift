import AppKit
import FillLightCore

/// A soft-edged light ring around the edge of its bounds.
///
/// Layers, bottom to top in effect:
/// - `fill`: one flat color, HDR-capable (EDRFillLayer)
/// - `ringMask` on `fill`: the ring shape, with a glow fading into the middle
/// - `pointerMask` on the view's layer: a soft hole around the mouse pointer
///
/// The ring shape is re-rendered only when size or brightness changes; color and
/// HDR changes just refill the Metal layer, and following the pointer just moves a mask.
final class RingView: NSView {
    var brightness: Double = 0.5 { didSet { if brightness != oldValue { needsRingMask = true; needsLayout = true } } }
    var color = LightMath.color(kelvin: LightMath.defaultKelvin) { didSet { refill() } }
    /// 1 = normal white. Above 1 lights the ring brighter than SDR white on HDR displays.
    var headroom: Double = 1 { didSet { refill() } }

    var fadeNearPointer = true {
        didSet { layer?.mask = fadeNearPointer ? pointerMask : nil }
    }

    private let fill = EDRFillLayer()
    private let ringMask = CALayer()
    private let pointerMask = CAGradientLayer()
    private let pointerHoleRadius: CGFloat = 110
    private var needsRingMask = true
    private var lastPointer = CGPoint(x: -10_000, y: -10_000)

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        guard let root = layer else { return }

        fill.mask = ringMask
        root.addSublayer(fill)

        // A huge radial gradient: clear in the middle, opaque beyond the hole radius.
        // Outside its last stop it keeps the final color, so the rest of the ring stays visible.
        pointerMask.type = .radial
        pointerMask.startPoint = CGPoint(x: 0.5, y: 0.5)
        pointerMask.endPoint = CGPoint(x: 1, y: 1)
        root.mask = pointerMask
        movePointerHole(to: lastPointer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        if fill.frame != bounds {
            fill.frame = bounds
            ringMask.frame = bounds
            needsRingMask = true
        }
        if needsRingMask {
            ringMask.contents = renderRingMask()
            needsRingMask = false
        }
        CATransaction.commit()
        movePointerHole(to: lastPointer)
        refill()
    }

    private func refill() {
        guard fill.isAvailable else {
            // No Metal: plain SDR color still works.
            fill.backgroundColor = CGColor(srgbRed: color.red, green: color.green, blue: color.blue, alpha: 1)
            return
        }
        fill.fill(color, headroom: headroom)
    }

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

    /// The ring as an alpha mask. Rendered at 1× scale: the edge is a soft glow anyway,
    /// and this keeps the image small on large displays.
    private func renderRingMask() -> CGImage? {
        let width = Int(bounds.width.rounded()), height = Int(bounds.height.rounded())
        guard width > 0, height > 0,
              let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }

        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        let shortSide = Double(min(width, height))
        let thickness = CGFloat(LightMath.ringThickness(brightness: brightness, shortSide: shortSide))
        let feather = thickness * 0.6
        let opaque = CGColor(red: 1, green: 1, blue: 1, alpha: 1)

        // Solid band: everything outside a rounded rectangle inset by `thickness`,
        // plus a glow (shadow) that fades into the middle of the screen.
        let inner = rect.insetBy(dx: thickness, dy: thickness)
        guard inner.width > 0, inner.height > 0 else {
            ctx.setFillColor(opaque)
            ctx.fill(rect)
            return ctx.makeImage()
        }
        let cornerRadius = min(thickness * 1.2, min(inner.width, inner.height) / 2)
        let band = CGMutablePath()
        band.addRect(rect.insetBy(dx: -feather * 3, dy: -feather * 3))
        band.addPath(CGPath(roundedRect: inner, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil))

        ctx.setShadow(offset: .zero, blur: feather, color: opaque)
        ctx.setFillColor(opaque)
        ctx.addPath(band)
        ctx.fillPath(using: .evenOdd)
        return ctx.makeImage()
    }
}
