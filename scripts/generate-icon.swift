import AppKit
import CoreText

let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

func drawRho(in context: CGContext, canvas: CGFloat, fontSize: CGFloat, color: CGColor) {
    let font = CTFontCreateWithName("Georgia-Italic" as CFString, fontSize, nil)
    let text = NSAttributedString(string: "ρ", attributes: [
        NSAttributedString.Key(kCTFontAttributeName as String): font,
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): color
    ])
    let line = CTLineCreateWithAttributedString(text)
    let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
    context.textPosition = CGPoint(x: (canvas - bounds.width) / 2 - bounds.minX,
                                   y: (canvas - bounds.height) / 2 - bounds.minY)
    CTLineDraw(line, context)
}

func render(size: Int, menu: Bool = false) throws -> Data {
    guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                                        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                        isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
          let graphics = NSGraphicsContext(bitmapImageRep: bitmap) else { fatalError("Could not create icon bitmap") }
    let context = graphics.cgContext
    let canvas: CGFloat = menu ? 44 : 1024
    context.scaleBy(x: CGFloat(size) / canvas, y: CGFloat(size) / canvas)
    if menu {
        drawRho(in: context, canvas: canvas, fontSize: 43, color: NSColor.black.cgColor)
    } else {
        let rect = CGRect(x: 64, y: 64, width: 896, height: 896)
        let path = CGPath(roundedRect: rect, cornerWidth: 210, cornerHeight: 210, transform: nil)
        context.addPath(path); context.clip()
        let colors = [NSColor(calibratedRed: 0.035, green: 0.19, blue: 0.19, alpha: 1).cgColor,
                      NSColor(calibratedRed: 0.10, green: 0.57, blue: 0.47, alpha: 1).cgColor]
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1])!
        context.drawLinearGradient(gradient, start: CGPoint(x: 880, y: 100), end: CGPoint(x: 150, y: 950), options: [])
        context.addPath(CGPath(roundedRect: rect.insetBy(dx: 3, dy: 3), cornerWidth: 207, cornerHeight: 207, transform: nil))
        context.setStrokeColor(NSColor(calibratedRed: 0.73, green: 0.94, blue: 0.84, alpha: 0.25).cgColor)
        context.setLineWidth(3); context.strokePath()
        context.setShadow(offset: CGSize(width: 0, height: -14), blur: 30,
                          color: NSColor(calibratedWhite: 0, alpha: 0.25).cgColor)
        drawRho(in: context, canvas: canvas, fontSize: 780,
                color: NSColor(calibratedRed: 0.98, green: 0.94, blue: 0.82, alpha: 1).cgColor)
    }
    guard let data = bitmap.representation(using: .png, properties: [:]) else { fatalError("Could not encode icon") }
    return data
}

let iconset = output.appendingPathComponent("rho.iconset", isDirectory: true)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let suffix = scale == 2 ? "@2x" : ""
        try render(size: points * scale).write(to: iconset.appendingPathComponent("icon_\(points)x\(points)\(suffix).png"))
    }
}
try render(size: 1024).write(to: output.appendingPathComponent("rho.png"))
try render(size: 44, menu: true).write(to: output.appendingPathComponent("RhoMenu.png"))
