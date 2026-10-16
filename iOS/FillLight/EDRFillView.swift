import SwiftUI
import UIKit

/// The light itself: a flat color that can go brighter than normal white on HDR screens.
struct EDRFillView: UIViewRepresentable {
    let color: LightColor
    /// 1 = normal white. Above 1 asks for HDR brightness.
    let headroom: Double

    final class FillView: UIView {
        override class var layerClass: AnyClass { EDRFillLayer.self }
        var fillLayer: EDRFillLayer { layer as! EDRFillLayer }

        var color = LightMath.color(kelvin: LightMath.defaultKelvin)
        var headroom = 1.0

        func refill() {
            if fillLayer.isAvailable {
                fillLayer.fill(color, headroom: headroom)
            } else {
                // No Metal: plain SDR color still works.
                backgroundColor = UIColor(red: color.red, green: color.green, blue: color.blue, alpha: 1)
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            refill()
        }
    }

    func makeUIView(context: Context) -> FillView {
        let view = FillView()
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: FillView, context: Context) {
        view.color = color
        view.headroom = headroom
        view.refill()
    }
}
