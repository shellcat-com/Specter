// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "Specter",
  platforms: [.macOS(.v14)],
  products: [
    .executable(name: "Specter", targets: ["SpecterApp"]),
    .executable(name: "SpecterPTY", targets: ["PTYLauncher"]),
    .executable(name: "SpecterBench", targets: ["SpecterBench"]),
    .library(name: "TerminalUI", targets: ["TerminalUI"]),
  ],
  targets: [
    .target(name: "TerminalCore"),
    .target(name: "PTYBridge"),
    .executableTarget(name: "PTYLauncher"),
    .target(name: "PTYSession", dependencies: ["PTYBridge", "TerminalCore"]),
    .target(name: "TextLayout", dependencies: ["TerminalCore"]),
    .target(
      name: "MetalTerminal", dependencies: ["TextLayout", "TerminalCore"],
      resources: [.copy("Shaders.metal"), .copy("Themes")]),
    .target(
      name: "TerminalUI",
      dependencies: ["TerminalCore", "PTYSession", "MetalTerminal", "TextLayout"],
      resources: [.copy("Resources/Mascots.json")]),
    .executableTarget(name: "SpecterApp", dependencies: ["TerminalUI"]),
    .executableTarget(name: "SpecterBench", dependencies: ["TerminalCore"]),
    .testTarget(
      name: "TerminalCoreTests", dependencies: ["TerminalCore"], resources: [.copy("Fixtures")]),
    .testTarget(name: "TerminalUITests", dependencies: ["TerminalUI"]),
    .testTarget(name: "PTYSessionTests", dependencies: ["PTYSession", "PTYBridge"]),
    .testTarget(
      name: "RenderingTests", dependencies: ["MetalTerminal", "TextLayout", "TerminalCore"]),
  ]
)
