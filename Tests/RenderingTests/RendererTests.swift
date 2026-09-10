import AppKit
import Foundation
import MetalKit
import TerminalCore
import Testing
import TextLayout

@testable import MetalTerminal

struct RendererTests {
  @Test @MainActor func metalSnapshot() throws {
    let device = try #require(MTLCreateSystemDefaultDevice())
    let renderer = try Renderer(device: device, scale: 1)
    let terminal = Terminal(columns: 40, rows: 8)
    terminal.feed("Specter\r\n\u{1B}[31mRed\u{1B}[0m  中  é  👩🏽‍💻\r\n\u{1B}[4mUnderline\u{1B}[0m".utf8)
    renderer.snapshot = terminal.snapshot()
    renderer.cursorVisible = false
    let image = try #require(renderer.renderImage(size: CGSize(width: 480, height: 180)))
    #expect(image.width == 480 && image.height == 180)
    let bytes = try #require(image.dataProvider?.data)
    let pixels = CFDataGetBytePtr(bytes)!
    let bg = Theme.rgba(renderer.theme.background)
    let background = [UInt8(bg.z * 255), UInt8(bg.y * 255), UInt8(bg.x * 255)]
    var changed = 0
    for offset in stride(from: 0, to: CFDataGetLength(bytes), by: 4) {
      if abs(Int(pixels[offset]) - Int(background[0])) > 2
        || abs(Int(pixels[offset + 1]) - Int(background[1])) > 2
        || abs(Int(pixels[offset + 2]) - Int(background[2])) > 2
      {
        changed += 1
      }
    }
    #expect(changed > 200)
    let directory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
      .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent(".artifacts")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!
    try png.write(to: directory.appendingPathComponent("render-snapshot.png"))
    #expect(renderer.atlasMisses > 0)
    _ = renderer.renderImage(size: CGSize(width: 480, height: 180))
    #expect(renderer.atlasHits > 0)
  }
  @Test func originalThemesValidate() {
    #expect(Theme.builtins.count == 130)
    #expect(Set(Theme.builtins.map(\.id)).count == 130)
    #expect(Set(Theme.builtins.map { [$0.background, $0.foreground] + $0.palette }).count == 130)
    for theme in Theme.builtins {
      func luminance(_ hex: String) -> Double {
        let rgb = Theme.rgba(hex)
        func linear(_ c: Float) -> Double {
          let v = Double(c)
          return v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(rgb.x) + 0.7152 * linear(rgb.y) + 0.0722 * linear(rgb.z)
      }
      let a = luminance(theme.background)
      let b = luminance(theme.foreground)
      #expect((max(a, b) + 0.05) / (min(a, b) + 0.05) >= 7, "\(theme.name) text contrast")
    }
    #expect(Theme.builtins.allSatisfy { $0.validate() })
  }
  @Test func malformedThemeDataIsRejected() {
    var theme = Theme.builtins[0]
    theme.palette.removeLast()
    #expect(!theme.validate())
    theme = Theme.builtins[0]
    theme.background = "#GG0000"
    #expect(!theme.validate())
    theme = Theme.builtins[0]
    theme.version = 2
    #expect(!theme.validate())
    theme = Theme.builtins[0]
    theme.name = ""
    #expect(!theme.validate())
  }
  @Test @MainActor func onlyDamagedRowsAreRedrawn() throws {
    let renderer = try Renderer(device: #require(MTLCreateSystemDefaultDevice()), scale: 1)
    let terminal = Terminal(columns: 20, rows: 4)
    terminal.feed("first\r\nsecond".utf8)
    renderer.snapshot = terminal.snapshot()
    renderer.cursorVisible = false
    _ = renderer.renderImage(size: CGSize(width: 240, height: 100))
    let before = renderer.rowsRedrawn
    _ = renderer.renderImage(size: CGSize(width: 240, height: 100))
    #expect(renderer.rowsRedrawn == before)
    terminal.feed("!".utf8)
    renderer.snapshot = terminal.snapshot()
    _ = renderer.renderImage(size: CGSize(width: 240, height: 100))
    #expect(renderer.rowsRedrawn - before == 1)
  }

}
