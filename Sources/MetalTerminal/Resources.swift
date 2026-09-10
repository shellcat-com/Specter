import Foundation

/// Resolves embedded resources before SwiftPM's development checkout fallback.
public enum TerminalResources {
  public static let bundle: Bundle = {
    if let resources = Bundle.main.resourceURL {
      let embedded = resources.appendingPathComponent("Specter_MetalTerminal.bundle")
      if let bundle = Bundle(url: embedded) { return bundle }
    }
    return Bundle.module
  }()
}
