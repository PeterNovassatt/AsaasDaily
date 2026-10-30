// Gera o ícone do app (AppIcon.appiconset): a roda da daily — oito pessoas em círculo, a de cima
// destacada por um anel (quem está falando) — com o "A" do Asaas no centro. O "A" vem de
// design/asaas-logo.png e é usado como máscara, então a forma é a do logo, sem redesenho.
// Uso: swift scripts/make-icon.swift
import AppKit

let root = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().deletingLastPathComponent()
let iconSet = root.appendingPathComponent("AsaasDaily/Assets.xcassets/AppIcon.appiconset")
let space = CGColorSpace(name: CGColorSpace.sRGB)!

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}
// Azul do Atlas e o navy dos outros apps da família.
let brand = rgb(0x0038E5), brandLit = rgb(0x2E6BFF), navyDeep = rgb(0x001750), white = rgb(0xFFFFFF)

func gradient(_ colors: [CGColor]) -> CGGradient {
    CGGradient(colorsSpace: space, colors: colors as CFArray, locations: nil)!
}

func roundedPath(_ r: CGRect, _ radius: CGFloat) -> CGPath {
    CGPath(roundedRect: r, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

/// Máscara do "A": tons de cinza a partir do alfa do PNG, recortada no conteúdo.
func logoMask() -> CGImage {
    let url = root.appendingPathComponent("design/asaas-logo.png")
    guard let rep = NSBitmapImageRep(data: try! Data(contentsOf: url)) else {
        fatalError("design/asaas-logo.png não encontrado")
    }
    let (w, h) = (rep.pixelsWide, rep.pixelsHigh)
    var bytes = [UInt8](repeating: 0, count: w * h)
    var (minX, minY, maxX, maxY) = (w, h, 0, 0)
    for y in 0..<h {
        for x in 0..<w {
            let c = rep.colorAt(x: x, y: y)!.usingColorSpace(.sRGB)!
            // O logo é claro sobre transparente: o alfa já descreve a forma.
            let v = UInt8(max(0, min(255, c.alphaComponent * 255)))
            bytes[y * w + x] = v
            if v > 128 { minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y) }
        }
    }
    let mask = CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: w,
                       space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: 0),
                       provider: CGDataProvider(data: Data(bytes) as CFData)!, decode: nil,
                       shouldInterpolate: true, intent: .defaultIntent)!
    return mask.cropping(to: CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1))!
}
let logo = logoMask()

// MARK: - Desenho

func background(_ c: CGContext) {
    // Grade de ícones do macOS: a forma ocupa 824 de 1024, com cantos de raio ~185.
    let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
    c.saveGState()
    c.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: rgb(0x000000, 0.35))
    c.addPath(roundedPath(tile, 185)); c.setFillColor(navyDeep); c.fillPath()
    c.restoreGState()

    c.saveGState()
    c.addPath(roundedPath(tile, 185)); c.clip()
    c.drawLinearGradient(gradient([brandLit, navyDeep]),
                         start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])
    c.drawRadialGradient(gradient([rgb(0x0038E5, 0.9), rgb(0x0038E5, 0)]),
                         startCenter: CGPoint(x: 300, y: 820), startRadius: 0,
                         endCenter: CGPoint(x: 300, y: 820), endRadius: 520, options: [])
    c.restoreGState()

    c.addPath(roundedPath(tile.insetBy(dx: 2, dy: 2), 183))
    c.setStrokeColor(rgb(0xFFFFFF, 0.10)); c.setLineWidth(4); c.strokePath()
}

/// A roda: oito pessoas em volta, a de cima falando — anel em torno dela.
func wheel(_ c: CGContext) {
    let center = CGPoint(x: 512, y: 512), radius: CGFloat = 292

    for index in 1..<8 {
        let angle = CGFloat(index) * .pi / 4
        let point = CGPoint(x: center.x + radius * sin(angle), y: center.y + radius * cos(angle))
        c.setFillColor(rgb(0xFFFFFF, 0.45))
        c.fillEllipse(in: CGRect(x: point.x - 20, y: point.y - 20, width: 40, height: 40))
    }

    let head = CGPoint(x: center.x, y: center.y + radius)
    c.setFillColor(white)
    c.fillEllipse(in: CGRect(x: head.x - 26, y: head.y - 26, width: 52, height: 52))
    c.setStrokeColor(white); c.setLineWidth(13)
    c.strokeEllipse(in: CGRect(x: head.x - 54, y: head.y - 54, width: 108, height: 108))
}

/// O "A" do Asaas, em branco, no centro da roda.
func asaasA(_ c: CGContext) {
    let width: CGFloat = 250
    let height = width * CGFloat(logo.height) / CGFloat(logo.width)
    let r = CGRect(x: 512 - width / 2, y: 496 - height / 2, width: width, height: height)
    c.saveGState()
    c.setShadow(offset: CGSize(width: 0, height: -8), blur: 24, color: rgb(0x001750, 0.5))
    c.beginTransparencyLayer(auxiliaryInfo: nil)
    c.clip(to: r, mask: logo)
    c.setFillColor(white); c.fill(r)
    c.endTransparencyLayer()
    c.restoreGState()
}

func render(size: Int) -> Data {
    let c = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                      space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    c.scaleBy(x: CGFloat(size) / 1024, y: CGFloat(size) / 1024)
    background(c); wheel(c); asaasA(c)
    let rep = NSBitmapImageRep(cgImage: c.makeImage()!)
    return rep.representation(using: .png, properties: [:])!
}

// MARK: - AppIcon.appiconset

try! FileManager.default.createDirectory(at: iconSet, withIntermediateDirectories: true)

let entries: [(points: Int, scale: Int)] = [(16, 1), (16, 2), (32, 1), (32, 2), (128, 1), (128, 2),
                                            (256, 1), (256, 2), (512, 1), (512, 2)]
var images: [[String: String]] = []
for entry in entries {
    let file = "icon_\(entry.points)x\(entry.points)\(entry.scale == 2 ? "@2x" : "").png"
    try! render(size: entry.points * entry.scale).write(to: iconSet.appendingPathComponent(file))
    images.append(["idiom": "mac", "scale": "\(entry.scale)x",
                   "size": "\(entry.points)x\(entry.points)", "filename": file])
}
let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
try! JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    .write(to: iconSet.appendingPathComponent("Contents.json"))
print("ícone gerado em \(iconSet.path)")
