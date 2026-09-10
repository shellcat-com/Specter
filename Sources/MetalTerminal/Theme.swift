import Foundation
import TerminalCore

public struct Theme: Codable, Equatable, Sendable, Identifiable {
  public var version = 1
  public var id: String
  public var name: String
  public var background: String
  public var foreground: String
  public var cursor: String
  public var selection: String
  public var palette: [String]
  public var isDark: Bool
  public func validate() -> Bool {
    version == 1 && !id.isEmpty && id.count <= 100 && name.count <= 100 && palette.count == 16
      && ([background, foreground, cursor, selection] + palette).allSatisfy {
        $0.count == 7 && $0.first == "#" && UInt32($0.dropFirst(), radix: 16) != nil
      }
  }
  public static func rgba(_ hex: String, alpha: Float = 1) -> SIMD4<Float> {
    let number = UInt32(hex.dropFirst(), radix: 16) ?? 0
    return SIMD4(
      Float((number >> 16) & 255) / 255, Float((number >> 8) & 255) / 255,
      Float(number & 255) / 255, alpha)
  }
  public func color(_ value: TerminalColor) -> SIMD4<Float> {
    switch value {
    case .foreground: return Self.rgba(foreground)
    case .background: return Self.rgba(background)
    case .rgb(let r, let g, let b): return SIMD4(Float(r) / 255, Float(g) / 255, Float(b) / 255, 1)
    case .indexed(let n):
      if n < 16 { return Self.rgba(palette[max(0, n)]) }
      if n < 232 {
        let v = n - 16
        let levels: [Float] = [0, 95, 135, 175, 215, 255]
        return SIMD4(levels[v / 36] / 255, levels[(v / 6) % 6] / 255, levels[v % 6] / 255, 1)
      }
      let gray = Float(8 + 10 * (min(255, n) - 232)) / 255
      return SIMD4(gray, gray, gray, 1)
    }
  }
  public static let builtins: [Theme] = {
    let dark = [
      "#25303A", "#EC8796", "#8ECB9B", "#E2C184", "#92B7EF", "#C3A0E3", "#7DC8CC", "#D6DCE4",
      "#75808D", "#F5A0AC", "#A5DEAF", "#F1D39A", "#ACCAFA", "#D8B6F5", "#98DFDF", "#F1F3F7",
    ]
    let light = [
      "#27333F", "#AF334B", "#277344", "#82600C", "#315EA7", "#7D489E", "#166B78", "#D2D8DE",
      "#657280", "#BC4056", "#347E4E", "#906A16", "#3A6BB7", "#8B53AD", "#227C88", "#F7F9FC",
    ]
    let specs: [(String, String, String, String, Bool)] = [
      ("specter-night", "Specter Night", "#171B22", "#DCE2EC", true),
      ("specter-day", "Specter Day", "#F6F7FA", "#26313F", false),
      ("deep-tide", "Deep Tide", "#122128", "#D2E4E7", true),
      ("inkstone", "Inkstone", "#202024", "#E6E2DE", true),
      ("orchard", "Orchard", "#19231E", "#D8E4D8", true),
      ("ember", "Ember", "#28201E", "#EBDCD1", true),
      ("dusk", "Dusk", "#211D2C", "#E1DAEE", true),
      ("paper", "Paper", "#F5F0E6", "#39342E", false),
      ("mist", "Mist", "#EAF2F1", "#263A3A", false),
      ("porcelain", "Porcelain", "#F9F3F6", "#402F3B", false),
    ]
    return specs.map { id, name, bg, fg, isDark in
      Theme(
        id: id, name: name, background: bg, foreground: fg, cursor: isDark ? "#A9C7FA" : "#365FA1",
        selection: isDark ? "#35465C" : "#CEDDF0", palette: isDark ? dark : light, isDark: isDark)
    }
  }()
}
