# Specter demo recording

`specter-demo.mp4` is a 33-second screen-capture demo of the actual native Specter app. It replaces the static repository banner in the main README.

The recording shows synthetic shell output, ANSI colors, combining characters/CJK/emoji, scrollback search, independent split-pane PTYs, the 130-theme gallery, applying a theme, native tabs, and session navigation. No existing user session, private commands, clipboard contents, or credentials are included.

Captured on an Apple M3 Mac running macOS 26.3.1 using the validated native design build from commit `5e9a475`. Window images were sampled through the computer-use capture API, assembled in chronological order with idle gaps between sections removed, and encoded as H.264/yuv420p MP4 at 960 × 720, 15 fps. Frames are padded to a common canvas; the terminal interface and output are not simulated. This is a feature demonstration, not a frame-rate or latency benchmark. There is no audio.

## Text description

1. A real shell prints live lines, colors, Unicode and its PTY device/grid size.
2. Find highlights “Unicode” in scrollback.
3. A split opens another shell with a distinct PTY and its own dimensions.
4. The native gallery filters 130 themes to the Alpine family and applies Alpine Midnight.
5. A new native tab starts a third PTY.
6. Session Overview lists the three sessions and navigates back to the first pane.
