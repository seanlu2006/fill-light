// Renders the 1024×1024 app icon: a warm ring of light on a dark background.
// Usage: swift scripts/make-icon.swift <output.png>
import AppKit

let size = 1024.0
let out = CommandLine.arguments.dropFirst().first ?? "icon.png"
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0,
                    space: cs, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!

let bg = CGGradient(colorsSpace: cs, colors: [CGColor(srgbRed: 0.10, green: 0.09, blue: 0.13, alpha: 1),
                                              CGColor(srgbRed: 0.02, green: 0.02, blue: 0.04, alpha: 1)] as CFArray,
                    locations: [0, 1])!
ctx.drawLinearGradient(bg, start: CGPoint(x: 0, y: size), end: CGPoint(x: 0, y: 0), options: [])

let center = CGPoint(x: size / 2, y: size / 2)
let warm = CGColor(srgbRed: 1.0, green: 0.86, blue: 0.62, alpha: 1)
ctx.setShadow(offset: .zero, blur: 90, color: warm)
ctx.setStrokeColor(warm)
ctx.setLineWidth(120)
ctx.strokeEllipse(in: CGRect(x: center.x - 300, y: center.y - 300, width: 600, height: 600))
ctx.setShadow(offset: .zero, blur: 0, color: nil)
ctx.setStrokeColor(CGColor(srgbRed: 1, green: 0.97, blue: 0.90, alpha: 1))
ctx.setLineWidth(44)
ctx.strokeEllipse(in: CGRect(x: center.x - 300, y: center.y - 300, width: 600, height: 600))

let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
