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
let bounds = CGRect(x: 0, y: 0, width: side, height: side)
context.setFillColor(NSColor(calibratedRed: 0.015, green: 0.24, blue: 0.64, alpha: 1).cgColor)
context.fill(bounds)
// Pixel-art, six-way snowflake inspired by the supplied bright-blue reference.
let unit: CGFloat = 32
let center = CGPoint(x: 512, y: 512)
let cyan = NSColor(calibratedRed: 0.12, green: 0.62, blue: 0.94, alpha: 1)
let pale = NSColor(calibratedRed: 0.20, green: 0.72, blue: 1.0, alpha: 1)
func pixel(_ x: Int, _ y: Int, _ color: NSColor = cyan) {
    context.setFillColor(color.cgColor)
    context.fill(CGRect(x: CGFloat(x) * unit, y: CGFloat(y) * unit, width: unit, height: unit))
}
let cx = 16, cy = 16
for step in -14...14 {
    let x = cx + step
    pixel(x, cy, abs(step) % 3 == 0 ? pale : cyan)
    let y = cy + step
    pixel(cx, y, abs(step) % 3 == 0 ? pale : cyan)
}
// Diagonal arms and blocky branchlets make the snowflake silhouette.
for signX in [-1, 1] {
    for signY in [-1, 1] {
        for step in 2...12 {
            pixel(cx + signX * step, cy + signY * step, step % 3 == 0 ? pale : cyan)
        }
        for step in [5, 8, 11] {
            for branch in 1...3 {
                pixel(cx + signX * step, cy + signY * (step - branch), pale)
                pixel(cx + signX * (step - branch), cy + signY * step, cyan)
            }
        }
    }
}
// Add pixelated tips to the vertical and horizontal arms.
for d in 10...14 {
    for off in -2...2 {
        pixel(cx + off, cy + d, d % 2 == 0 ? pale : cyan)
        pixel(cx + off, cy - d, d % 2 == 0 ? pale : cyan)
        pixel(cx + d, cy + off, d % 2 == 0 ? pale : cyan)
        pixel(cx - d, cy + off, d % 2 == 0 ? pale : cyan)
    }
}
image.unlockFocus()
guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Unable to encode icon PNG\n", stderr)
    exit(1)
}
try png.write(to: output, options: .atomic)
print("Wrote pixel snowflake icon to \(output.path)")
