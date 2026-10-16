import Metal
import QuartzCore

/// A layer filled with one flat color that can go brighter than normal white
/// on HDR (EDR) displays, such as XDR MacBook Pros and recent iPhones and iPads.
///
/// It only ever clears its drawable to a color, so no shaders are needed, and the
/// drawable can stay tiny: the layer stretches it to fill its bounds.
public final class EDRFillLayer: CAMetalLayer {
    private var queue: MTLCommandQueue?

    public override init() {
        super.init()
        device = MTLCreateSystemDefaultDevice()
        queue = device?.makeCommandQueue()
        pixelFormat = .rgba16Float
        // Linear, extended range: 1.0 is normal white, above 1.0 is HDR.
        colorspace = CGColorSpace(name: CGColorSpace.extendedLinearSRGB)
        drawableSize = CGSize(width: 8, height: 8)
        isOpaque = true
        needsDisplayOnBoundsChange = false
    }

    public override init(layer: Any) {
        super.init(layer: layer)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    /// Whether Metal is usable at all. If not, callers should fall back to a plain color.
    public var isAvailable: Bool { queue != nil }

    /// `headroom` 1 means normal SDR white. Values above 1 ask the display for HDR
    /// brightness; the system clamps to whatever headroom the display has right now.
    public func fill(_ color: LightColor, headroom: Double) {
        let boost = max(headroom, 1)
        wantsExtendedDynamicRangeContent = boost > 1
        guard let queue, let drawable = nextDrawable() else { return }

        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = drawable.texture
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].storeAction = .store
        pass.colorAttachments[0].clearColor = MTLClearColor(
            red: LightMath.linear(color.red) * boost,
            green: LightMath.linear(color.green) * boost,
            blue: LightMath.linear(color.blue) * boost,
            alpha: 1
        )

        guard let buffer = queue.makeCommandBuffer(),
              let encoder = buffer.makeRenderCommandEncoder(descriptor: pass) else { return }
        encoder.endEncoding()
        buffer.present(drawable)
        buffer.commit()
    }
}
