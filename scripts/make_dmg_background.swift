// Dibuixa el fons de la finestra del .dmg: una fletxa de l'app cap a Aplicacions.
// Ús: swift make_dmg_background.swift sortida.tiff
import AppKit

let width = 600, height = 400
let out = URL(fileURLWithPath: CommandLine.arguments[1])
// L'instal·lador és un de sol per a tothom, per això els textos són en anglès
let t = (title: "Drag Emojis to the Applications folder",
         line1: "First time: System Settings › Privacy & Security › “Open Anyway”.",
         line2: "Then enable Emojis in Privacy & Security › Accessibility to paste automatically.")

func render(scale: Int) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width * scale, pixelsHigh: height * scale,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: width, height: height)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let bounds = NSRect(x: 0, y: 0, width: width, height: height)
    NSGradient(starting: NSColor(red: 1.0, green: 0.97, blue: 0.9, alpha: 1),
               ending: NSColor(red: 1.0, green: 0.9, blue: 0.88, alpha: 1))!.draw(in: bounds, angle: -90)

    func text(_ s: String, size: CGFloat, weight: NSFont.Weight, color: NSColor, y: CGFloat) {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        NSAttributedString(string: s, attributes: [
            .font: NSFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: color, .paragraphStyle: style,
        ]).draw(in: NSRect(x: 0, y: y, width: CGFloat(width), height: size * 1.5))
    }
    // Coordenades amb l'origen a baix: les icones del Finder queden a y = 190 (des de dalt)
    text(t.title, size: 20, weight: .semibold,
         color: NSColor(white: 0.2, alpha: 1), y: 318)

    let arrow = NSBezierPath()
    arrow.move(to: NSPoint(x: 240, y: 210))
    arrow.line(to: NSPoint(x: 350, y: 210))
    arrow.lineWidth = 6
    arrow.lineCapStyle = .round
    let head = NSBezierPath()
    head.move(to: NSPoint(x: 340, y: 228))
    head.line(to: NSPoint(x: 362, y: 210))
    head.line(to: NSPoint(x: 340, y: 192))
    head.lineWidth = 6
    head.lineCapStyle = .round
    head.lineJoinStyle = .round
    NSColor(red: 0.95, green: 0.45, blue: 0.4, alpha: 1).setStroke()
    arrow.stroke()
    head.stroke()

    text(t.line1,
         size: 12, weight: .regular, color: NSColor(white: 0.35, alpha: 1), y: 52)
    text(t.line2,
         size: 12, weight: .regular, color: NSColor(white: 0.35, alpha: 1), y: 32)

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

// Una sola imatge TIFF amb les dues resolucions, perquè es vegi nítida a pantalles Retina
let tiff = NSBitmapImageRep.tiffRepresentationOfImageReps(in: [render(scale: 1), render(scale: 2)], using: .lzw, factor: 0)!
try! tiff.write(to: out)
