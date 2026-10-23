import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("Usage: MakeIcon.swift output.png\n", stderr)
    exit(2)
}
let output = URL(fileURLWithPath: CommandLine.arguments[1])
let side = 1024
let image = NSImage(size: NSSize(width: side, height: side))
image.lockFocus()
guard let context = NSGraphicsContext.current?.cgContext else {
    fputs("Unable to create drawing context\n", stderr)
    exit(1)
}
context.setFillColor(NSColor(calibratedRed: 0.025, green: 0.075, blue: 0.14, alpha: 1).cgColor)
let bounds = CGRect(x: 0, y: 0, width: side, height: side)
context.fill(bounds)
let tile = CGRect(x: 64, y: 64, width: 896, height: 896)
let bg = CGPath(roundedRect: tile, cornerWidth: 210, cornerHeight: 210, transform: nil)
context.setFillColor(NSColor(calibratedRed: 0.035, green: 0.16, blue: 0.28, alpha: 1).cgColor)
context.addPath(bg)
context.fillPath()
context.saveGState()
context.addPath(bg)
context.clip()
let gradientColors = [NSColor(calibratedRed: 0.1, green: 0.5, blue: 0.85, alpha: 1).cgColor,
                      NSColor(calibratedRed: 0.05, green: 0.25, blue: 0.48, alpha: 1).cgColor] as CFArray
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors, locations: [0, 1])!
context.drawLinearGradient(gradient, start: CGPoint(x: 100, y: 900), end: CGPoint(x: 900, y: 100), options: [])
context.restoreGState()
context.setStrokeColor(NSColor(calibratedRed: 0.55, green: 0.88, blue: 1, alpha: 1).cgColor)
context.setLineWidth(31)
context.setLineCap(.round)
context.setLineJoin(.round)
let center = CGPoint(x: 512, y: 512)
for angle in stride(from: 0.0, to: 360.0, by: 60.0) {
    let a = angle * Double.pi / 180
    let dx = cos(a), dy = sin(a)
    let end = CGPoint(x: center.x + dx * 300, y: center.y + dy * 300)
    context.move(to: CGPoint(x: center.x - dx * 300, y: center.y - dy * 300))
    context.addLine(to: end)
    for sign in [-1.0, 1.0] {
        let p = CGPoint(x: center.x + dx * 205 * sign, y: center.y + dy * 205 * sign)
        for branchSign in [-1.0, 1.0] {
            let theta = a + Double.pi / 3 * branchSign
            context.move(to: p)
            context.addLine(to: CGPoint(x: p.x - cos(theta) * 80 * sign, y: p.y - sin(theta) * 80 * sign))
        }
    }
}
context.strokePath()
context.setFillColor(NSColor.white.cgColor)
context.fillEllipse(in: CGRect(x: 478, y: 478, width: 68, height: 68))
image.unlockFocus()
guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Unable to encode icon PNG\n", stderr)
    exit(1)
}
try png.write(to: output, options: .atomic)
print("Wrote icon to \(output.path)")
