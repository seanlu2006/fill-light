import SwiftUI
import UIKit

/// The system color picker, wrapped so LightView knows when it is open
/// (the controls must not auto-hide underneath it).
struct ColorPickerSheet: UIViewControllerRepresentable {
    @Binding var color: LightColor
    let onFinish: () -> Void

    func makeUIViewController(context: Context) -> UIColorPickerViewController {
        let picker = UIColorPickerViewController()
        picker.supportsAlpha = false
        picker.selectedColor = UIColor(red: color.red, green: color.green, blue: color.blue, alpha: 1)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ picker: UIColorPickerViewController, context: Context) {
        context.coordinator.parent = self
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, UIColorPickerViewControllerDelegate {
        var parent: ColorPickerSheet

        init(parent: ColorPickerSheet) { self.parent = parent }

        func colorPickerViewController(_ picker: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            // Wide-gamut picks can fall outside 0...1; LightColor clamps them.
            guard color.getRed(&r, green: &g, blue: &b, alpha: &a) else { return }
            parent.color = LightColor(red: r, green: g, blue: b)
        }

        func colorPickerViewControllerDidFinish(_ picker: UIColorPickerViewController) {
            parent.onFinish()
        }
    }
}
