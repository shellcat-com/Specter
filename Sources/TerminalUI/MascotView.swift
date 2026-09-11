import SwiftUI

/// A local playback clock; pausing preserves the pose without accumulating hidden time.
struct MascotPlaybackClock {
  private var elapsed: TimeInterval = 0
  private var resumedAt: TimeInterval?

  mutating func setPlaying(_ playing: Bool, at time: TimeInterval) {
    if playing, resumedAt == nil {
      resumedAt = time
    } else if !playing, let start = resumedAt {
      elapsed += max(0, time - start)
      resumedAt = nil
    }
  }

  func frame(at time: TimeInterval) -> Int {
    let duration = elapsed + (resumedAt.map { max(0, time - $0) } ?? 0)
    return Int((duration * 8).truncatingRemainder(dividingBy: 12))
  }
}

/// Precompiled pixel paths stay outside the terminal grid, renderer and PTY data path.
struct MascotView: View {
  let style: MascotStyle
  var motion: MascotMotion = .idle
  var animated = true
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.controlActiveState) private var controlActiveState
  @Environment(\.displayScale) private var displayScale
  @State private var clock = MascotPlaybackClock()

  private var isPlaying: Bool {
    animated && !reduceMotion && style != .none && controlActiveState != .inactive
  }

  var body: some View {
    TimelineView(.animation(minimumInterval: 1.0 / 8, paused: !isPlaying)) { context in
      let frame = reduceMotion ? 0 : clock.frame(at: context.date.timeIntervalSinceReferenceDate)
      Canvas { graphics, size in
        guard let sprite = MascotCatalog.available?.sprites[style],
          let paths = sprite.frames[motion]?[frame]
        else { return }
        // Whole device pixels preserve the silhouette at Retina and 1x scales.
        let unit = max(1, floor(min(size.width, size.height) * displayScale / 24)) / displayScale
        let x = floor((size.width - unit * 24) * displayScale / 2) / displayScale
        let y = floor((size.height - unit * 24) * displayScale / 2) / displayScale
        graphics.translateBy(x: x, y: y)
        graphics.scaleBy(x: unit, y: unit)
        for index in paths.indices {
          graphics.fill(
            paths[index], with: .color(sprite.colors[index]), style: FillStyle(antialiased: false))
        }
      }
    }
    .onChange(of: isPlaying, initial: true) { _, playing in
      clock.setPlaying(playing, at: Date.timeIntervalSinceReferenceDate)
    }
    .onAppear { clock.setPlaying(isPlaying, at: Date.timeIntervalSinceReferenceDate) }
    .onDisappear { clock.setPlaying(false, at: Date.timeIntervalSinceReferenceDate) }
    .accessibilityHidden(true)
  }
}
