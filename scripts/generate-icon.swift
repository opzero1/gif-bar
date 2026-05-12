import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assetsURL = root.appendingPathComponent("assets", isDirectory: true)
let iconsetURL = assetsURL.appendingPathComponent("GifBar.iconset", isDirectory: true)
let pngURL = assetsURL.appendingPathComponent("GifBar-1024.png")

try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    NSColor.clear.setFill()
    rect.fill()

    let radius = size * 0.225
    let background = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.035, dy: size * 0.035), xRadius: radius, yRadius: radius)
    let gradient = NSGradient(colors: [
        NSColor(calibratedWhite: 0.02, alpha: 1),
        NSColor(calibratedWhite: 0.22, alpha: 1)
    ])
    gradient?.draw(in: background, angle: 135)

    NSColor.white.withAlphaComponent(0.22).setStroke()
    background.lineWidth = max(2, size * 0.008)
    background.stroke()

    let frameRect = NSRect(x: size * 0.205, y: size * 0.255, width: size * 0.59, height: size * 0.49)
    let frame = NSBezierPath(roundedRect: frameRect, xRadius: size * 0.065, yRadius: size * 0.065)
    NSColor.white.setStroke()
    frame.lineWidth = size * 0.055
    frame.stroke()

    let notchCount = 4
    for index in 0..<notchCount {
        let notchWidth = size * 0.055
        let notchHeight = size * 0.052
        let x = frameRect.minX + size * 0.105 + CGFloat(index) * size * 0.125

        let topNotch = NSBezierPath(roundedRect: NSRect(x: x, y: frameRect.maxY - size * 0.018, width: notchWidth, height: notchHeight), xRadius: size * 0.012, yRadius: size * 0.012)
        topNotch.fill()

        let bottomNotch = NSBezierPath(roundedRect: NSRect(x: x, y: frameRect.minY - notchHeight + size * 0.018, width: notchWidth, height: notchHeight), xRadius: size * 0.012, yRadius: size * 0.012)
        bottomNotch.fill()
    }

    let triangle = NSBezierPath()
    triangle.move(to: NSPoint(x: size * 0.43, y: size * 0.365))
    triangle.line(to: NSPoint(x: size * 0.43, y: size * 0.635))
    triangle.line(to: NSPoint(x: size * 0.64, y: size * 0.5))
    triangle.close()
    NSColor.white.setFill()
    triangle.fill()

    let shine = NSBezierPath()
    shine.move(to: NSPoint(x: size * 0.24, y: size * 0.77))
    shine.curve(
        to: NSPoint(x: size * 0.76, y: size * 0.83),
        controlPoint1: NSPoint(x: size * 0.39, y: size * 0.88),
        controlPoint2: NSPoint(x: size * 0.58, y: size * 0.89)
    )
    NSColor.white.withAlphaComponent(0.18).setStroke()
    shine.lineWidth = size * 0.028
    shine.lineCapStyle = .round
    shine.stroke()

    image.unlockFocus()
    return image
}

func writePNG(_ image: NSImage, to url: URL) throws {
    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let png = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "GifBarIcon", code: 1)
    }

    try png.write(to: url)
}

let iconSizes: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, size) in iconSizes {
    try writePNG(drawIcon(size: size), to: iconsetURL.appendingPathComponent(name))
}

try writePNG(drawIcon(size: 1024), to: pngURL)
