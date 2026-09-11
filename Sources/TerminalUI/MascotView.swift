import SwiftUI

/// Original vector companions. Decorative drawing never touches the terminal grid or PTY.
public enum MascotStyle: String, Codable, CaseIterable, Identifiable {
  case specter, comet, sprout, pixel, none
  public var id: String { rawValue }
  var title: String { rawValue == "none" ? "Off" : rawValue.capitalized }
}

struct MascotView: View {
  let style: MascotStyle
  var animated = true
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    TimelineView(
      .animation(minimumInterval: 1.0 / 24, paused: !animated || reduceMotion || style == .none)
    ) {
      context in
      let time = animated && !reduceMotion ? context.date.timeIntervalSinceReferenceDate : 0
      Canvas { graphics, size in
        guard style != .none else { return }
        let scale = min(size.width, size.height) / 64
        graphics.scaleBy(x: scale, y: scale)
        graphics.translateBy(x: 0, y: sin(time * 2) * 2)
        let ink = Color(red: 0.12, green: 0.15, blue: 0.24)
        let tint: Color =
          switch style {
          case .specter: .init(red: 0.69, green: 0.73, blue: 1)
          case .comet: .init(red: 1, green: 0.76, blue: 0.46)
          case .sprout: .init(red: 0.57, green: 0.85, blue: 0.66)
          case .pixel: .init(red: 0.87, green: 0.65, blue: 0.87)
          case .none: .clear
          }
        graphics.fill(
          Path(ellipseIn: CGRect(x: 16, y: 56, width: 32, height: 3)),
          with: .color(tint.opacity(0.2)))
        var body = Path()
        switch style {
        case .specter:
          body.move(to: CGPoint(x: 12, y: 49))
          body.addLine(to: CGPoint(x: 12, y: 29))
          body.addCurve(
            to: CGPoint(x: 52, y: 29), control1: CGPoint(x: 12, y: 3),
            control2: CGPoint(x: 52, y: 3))
          body.addLine(to: CGPoint(x: 52, y: 49))
          for x in stride(from: 52, through: 12, by: -10) {
            body.addLine(to: CGPoint(x: x, y: x % 20 == 12 ? 49 : 54))
          }
          body.closeSubpath()
        case .comet:
          for i in 0..<10 {
            let angle = Double(i) * .pi / 5 - .pi / 2
            let radius: Double = i.isMultiple(of: 2) ? 25 : 18
            let point = CGPoint(x: 32 + cos(angle) * radius, y: 32 + sin(angle) * radius)
            if i == 0 { body.move(to: point) } else { body.addLine(to: point) }
          }
          body.closeSubpath()
        case .sprout:
          body = Path(roundedRect: CGRect(x: 13, y: 23, width: 38, height: 30), cornerRadius: 14)
          graphics.fill(
            Path(ellipseIn: CGRect(x: 18, y: 9, width: 15, height: 10)), with: .color(tint))
          graphics.fill(
            Path(ellipseIn: CGRect(x: 33, y: 6, width: 17, height: 12)), with: .color(tint))
          graphics.fill(Path(CGRect(x: 31, y: 13, width: 3, height: 14)), with: .color(tint))
        case .pixel:
          body = Path(roundedRect: CGRect(x: 10, y: 18, width: 44, height: 34), cornerRadius: 7)
          graphics.fill(Path(CGRect(x: 30, y: 10, width: 4, height: 9)), with: .color(tint))
          graphics.fill(
            Path(ellipseIn: CGRect(x: 28, y: 6, width: 8, height: 8)), with: .color(tint))
        case .none: break
        }
        graphics.fill(
          body,
          with: .linearGradient(
            Gradient(colors: [tint, tint.opacity(0.75)]), startPoint: CGPoint(x: 15, y: 10),
            endPoint: CGPoint(x: 50, y: 54)))
        let blink = time > 0 && time.truncatingRemainder(dividingBy: 4.7) < 0.15
        for x in [23.0, 38.0] {
          graphics.fill(
            Path(
              roundedRect: CGRect(x: x, y: 31, width: 4, height: blink ? 2 : 7), cornerRadius: 2),
            with: .color(ink))
        }
        var smile = Path()
        smile.move(to: CGPoint(x: 29, y: 42))
        smile.addQuadCurve(to: CGPoint(x: 36, y: 42), control: CGPoint(x: 32.5, y: 46))
        graphics.stroke(
          smile, with: .color(ink), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
      }
    }.accessibilityHidden(true)
  }
}
