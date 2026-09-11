import Foundation
import SwiftUI

public enum MascotStyle: String, Codable, CaseIterable, Identifiable, Sendable {
  case wisp, moth, kettle, mimic, orbit, moss, bytebat, cinder, jelly, origami, imp, rover, none
  public var id: String { rawValue }
  var title: String { self == .none ? "Off" : rawValue.capitalized }

  static func restored(from value: String?) -> Self {
    switch value {
    case "specter": .wisp
    case "comet": .cinder
    case "sprout": .moss
    case "pixel": .rover
    default: value.flatMap(Self.init(rawValue:)) ?? .wisp
    }
  }
}

/// A decorative motion chosen by the user, never an inferred shell/process status.
public enum MascotMotion: String, Codable, CaseIterable, Identifiable, Sendable {
  case idle, working, celebrate
  public var id: String { rawValue }
  var title: String { self == .working ? "Busy" : rawValue.capitalized }
}

enum MascotCatalogError: Error {
  case missingResource
  case invalidCatalog
}

@MainActor
struct MascotCatalog {
  struct Sprite {
    let description: String
    let gesture: String
    let colors: [Color]
    let frames: [MascotMotion: [[Path]]]
  }

  private struct Source: Decodable {
    struct Sprite: Decodable {
      let id: String
      let description: String
      let gesture: String
      let colors: [String: String]
      let states: [String: [[String]]]
    }
    let version: Int
    let width: Int
    let height: Int
    let fps: Int
    let mascots: [Sprite]
  }

  static let bundled: Result<MascotCatalog, Error> = Result {
    try MascotCatalog(data: resourceData())
  }
  static var available: MascotCatalog? { try? bundled.get() }
  let sprites: [MascotStyle: Sprite]

  static func resourceData() throws -> Data {
    let bundle: Bundle
    if Bundle.main.bundleURL.pathExtension == "app" {
      guard let resources = Bundle.main.resourceURL,
        let embedded = Bundle(url: resources.appendingPathComponent("Specter_TerminalUI.bundle"))
      else { throw MascotCatalogError.missingResource }
      bundle = embedded
    } else {
      bundle = Bundle.module
    }
    guard let url = bundle.url(forResource: "Mascots", withExtension: "json") else {
      throw MascotCatalogError.missingResource
    }
    return try Data(contentsOf: url)
  }

  init(data: Data) throws {
    guard data.count <= 524_288 else { throw MascotCatalogError.invalidCatalog }
    let source = try JSONDecoder().decode(Source.self, from: data)
    guard source.version == 1, source.width == 24, source.height == 24, source.fps == 8,
      source.mascots.count == 12
    else { throw MascotCatalogError.invalidCatalog }
    var compiled: [MascotStyle: Sprite] = [:]
    let tokens: [UInt8] = [66, 65, 111]  // B, A, o
    for sprite in source.mascots {
      guard let style = MascotStyle(rawValue: sprite.id), style != .none,
        compiled[style] == nil,
        Set(sprite.states.keys) == Set(MascotMotion.allCases.map(\.rawValue)),
        sprite.description.count <= 180, sprite.gesture.count <= 40
      else { throw MascotCatalogError.invalidCatalog }
      let colors = try ["B", "A", "o"].map { token -> Color in
        guard let hex = sprite.colors[token], hex.count == 7, hex.first == "#",
          let value = UInt32(hex.dropFirst(), radix: 16)
        else { throw MascotCatalogError.invalidCatalog }
        return Color(
          red: Double((value >> 16) & 255) / 255,
          green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255)
      }
      var frames: [MascotMotion: [[Path]]] = [:]
      for motion in MascotMotion.allCases {
        guard let sourceFrames = sprite.states[motion.rawValue], sourceFrames.count == 12 else {
          throw MascotCatalogError.invalidCatalog
        }
        frames[motion] = try sourceFrames.map { rows in
          guard rows.count == 24 else { throw MascotCatalogError.invalidCatalog }
          var paths = Array(repeating: Path(), count: 3)
          for (y, row) in rows.enumerated() {
            let pixels = Array(row.utf8)
            guard pixels.count == 24 else { throw MascotCatalogError.invalidCatalog }
            for (x, pixel) in pixels.enumerated() where pixel != 46 {
              guard let index = tokens.firstIndex(of: pixel) else {
                throw MascotCatalogError.invalidCatalog
              }
              paths[index].addRect(CGRect(x: x, y: y, width: 1, height: 1))
            }
          }
          return paths
        }
      }
      compiled[style] = Sprite(
        description: sprite.description, gesture: sprite.gesture, colors: colors, frames: frames)
    }
    sprites = compiled
  }
}
