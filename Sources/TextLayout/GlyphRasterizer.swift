import AppKit
import CoreText
import TerminalCore

public struct GlyphKey: Hashable {
  public var text: String
  public var bold: Bool
  public var italic: Bool
  public var width: Int
  public var ligatures: Bool
  public init(cell: Cell, ligatures: Bool = false) {
    text = cell.text
    bold = cell.attributes.bold
    italic = cell.attributes.italic
    width = cell.width
    self.ligatures = ligatures
  }
}

public final class GlyphRasterizer {
  public let font: CTFont
  public let pointSize: CGFloat
  public let scale: CGFloat
  public let cellWidth: CGFloat
  public let cellHeight: CGFloat
  public let ascent: CGFloat
  public let descent: CGFloat
  public init(fontName: String = "Menlo", size: CGFloat = 14, scale: CGFloat = 2) {
    pointSize = max(8, min(40, size))
    self.scale = max(1, scale)
    font = CTFontCreateWithName(fontName as CFString, pointSize, nil)
    var glyph = CTFontGetGlyphWithName(font, "M" as CFString)
    var advance = CGSize.zero
    CTFontGetAdvancesForGlyphs(font, .horizontal, &glyph, &advance, 1)
    cellWidth = ceil(max(advance.width, pointSize * 0.5) * self.scale) / self.scale
    ascent = CTFontGetAscent(font)
    descent = CTFontGetDescent(font)
    cellHeight = ceil((ascent + descent + CTFontGetLeading(font) + 3) * self.scale) / self.scale
  }
  public func rasterize(_ key: GlyphKey) -> CGImage? {
    let width = max(1, Int(ceil(cellWidth * CGFloat(max(1, key.width)) * scale)))
    let height = max(1, Int(ceil(cellHeight * scale)))
    guard
      let context = CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else { return nil }
    context.scaleBy(x: scale, y: scale)
    var traits: CTFontSymbolicTraits = []
    if key.bold { traits.insert(.boldTrait) }
    if key.italic { traits.insert(.italicTrait) }
    let styled = CTFontCreateCopyWithSymbolicTraits(font, pointSize, nil, traits, traits) ?? font
    let attributes: [NSAttributedString.Key: Any] = [
      .font: styled, .foregroundColor: NSColor.white, .ligature: key.ligatures ? 1 : 0,
    ]
    let string = NSAttributedString(string: key.text, attributes: attributes)
    let line = CTLineCreateWithAttributedString(string)
    let advance = CTLineGetTypographicBounds(line, nil, nil, nil)
    let allowed = cellWidth * CGFloat(max(1, key.width))
    if advance > allowed + 0.5 { context.scaleBy(x: allowed / advance, y: 1) }
    context.textPosition = CGPoint(x: 0, y: descent + 1)
    CTLineDraw(line, context)
    return context.makeImage()
  }
}
