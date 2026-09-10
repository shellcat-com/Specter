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
    version == 1 && !id.isEmpty && id.count <= 100 && !name.isEmpty && name.count <= 100
      && palette.count == 16
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
    guard
      let url = TerminalResources.bundle.url(
        forResource: "catalog", withExtension: "json", subdirectory: "Themes"),
      let data = try? Data(contentsOf: url),
      let themes = try? JSONDecoder().decode([Theme].self, from: data),
      themes.count >= 100, themes.allSatisfy({ $0.validate() }),
      Set(themes.map(\.id)).count == themes.count
    else { preconditionFailure("The bundled Specter theme catalog is missing or invalid.") }
    return themes
  }()
}
