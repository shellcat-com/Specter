# Specter — a quiet place to work

> Your shell. Your colors. Your flow.

Specter pairs a native macOS terminal with an editorial website. The app puts readable text and real shells first. The website offers room to breathe, original landscape illustration, and an honest route from discovery to daily use.

## Visual direction

| Surface | Direction | Purpose |
| --- | --- | --- |
| Website | Warm paper, olive ink, landscape art, regular-weight headlines | Welcome the person before describing the machinery |
| Terminal | Native window chrome, legible monospace, selectable palette | Keep output readable and controls predictable |
| Theme Gallery | Native searchable grid, visible palette samples, favorites | Make a large collection easy to explore |
| Documentation | Persistent chapter navigation, narrow text measure, useful tables | Let people find an answer quickly |

The references are [Cursor](https://cursor.com/) for editorial proportion and [Ghostty](https://ghostty.org/) for a terminal-centered presentation. The local `design-md` skill’s Cursor reference informed the spacing/type relationships. Our live review and the user’s screenshots take precedence over a stale token catalog. Specter does not reproduce their logos, artwork, testimonials, licensed fonts, or implied endorsements.

## Website tokens

| Token | Value | Usage |
| --- | --- | --- |
| Canvas | `#F7F7F2` | Main page background |
| Ink | `#282A24` | Headlines, body emphasis, primary action |
| Body | `#67695F` | Supporting copy |
| Line | `#DDDFD5` | Quiet divisions and controls |
| Surface | `#EEEFE7` | Secondary panels |
| Accent | `#3D5E46` | Text links and interaction feedback |
| Focus | `#688675` | Visible keyboard outline |

System sans for website UI; `ui-monospace`, SF Mono and Menlo fallbacks for code. No remote font requests. Use regular-weight headings, tight display tracking, relaxed body line height. The top-level headline scales from 52 px on a phone to 78 px on a wide screen. Documentation text is 15 px with 1.8 line height and a maximum 790 px article measure.

Page content caps at 1,300 px. Desktop gutters are 48 px; compact gutters are 18–24 px. Primary actions have rounded ends. Cards use 4–10 px corners and hairline borders. Reserve deep shadow for the terminal illustration over the landscape; ordinary content uses spacing and borders.

## Composition

1. A concise native-macOS identifier and visible preview status.
2. A substantial headline paired with useful build and theme actions.
3. An original landscape framing an illustrative terminal.
4. Four concrete product facts, without invented usage statistics.
5. A twelve-session workspace illustration and its real shortcut.
6. A theme preview row that changes the hero palette.
7. A native architecture section and documentation entry points.
8. A clear build action and compact footer.

The theme browser has a selected-theme preview, static JSON download, text search, appearance filter, result count, paginated cards, and a useful empty state. Do not render 130 full interactive preview trees at once: the website shows 24 per page and SwiftUI uses a lazy grid.

## App appearance

The terminal remains AppKit/Metal, with SwiftUI used for preferences and galleries. Native traffic lights, menus, tab behavior, file panels, and keyboard focus remain native. Do not add ornamental animation to the terminal output path.

The catalog has **130 original palettes**: ten established Specter IDs plus twenty families in six treatments. Families include Alpine, Aurora, Basalt, Boreal, Canyon, Celadon, Cobalt, Copper, Fig, Glacier, Heather, Lagoon, Linen, Marigold, Moonstone, Mulberry, Petal, Saffron, Sequoia, and Wisteria. Treatments are Midnight, Nocturne, Velvet, Dawn, Daylight, and Parchment. They are coordinated variations, not 130 independently imported community designs.

`scripts/generate-themes.py` produces the app catalog, web catalog, and individual download files from the same source. Default foreground/background contrast must be at least 7:1. This requirement does not certify every ANSI color pair or a program’s arbitrary RGB output. Keep semantic ANSI colors recognizable. Imports are versioned color data, never executable configuration.

Gallery cards show only synthetic content. Selecting a card applies to the profile named in the header. Stars favorite a theme; favorites do not alter terminal colors. “Follow system appearance” restores automatic Specter Night/Day selection. Importing an unchanged built-in theme selects it; changed copies need a unique ID.

## Motion

| Interaction | Motion |
| --- | --- |
| Initial terminal reveal | 750 ms ease-out, 15 px translation |
| Button hover | 180 ms, 1 px upward movement |
| Theme preview hover | 200 ms, 3 px upward movement |
| Hero palette transition | 250 ms |
| Architecture illustration | Slow 20–28 second CSS orbit |
| Illustrative cursor | 1.4 second stepped blink |

Honor `prefers-reduced-motion` in CSS; disable transitions and decorative animation. The native app honors the macOS Reduce Motion preference for cursor blink. Animation must never delay interaction or hide important copy when scripting fails. No autoplay video, scroll hijacking, endless carousel, or heavy animation dependency.

## Illustration and provenance

`website/assets/daybreak.png` is an original generated landscape created with the built-in image-generation tool on 2026-09-10. It shows a sunrise valley with sage/olive hills, distant blue-gray mountains, mist, and wildflowers. It is website art, not terminal wallpaper and not a screenshot of the running app.

Generation prompt: “Use case: stylized-concept. Asset type: panoramic landscape illustration for the Specter native macOS terminal website. Create an original exquisitely detailed painterly landscape: rolling sage and olive grassy hills, distant blue-grey mountains under a vast pale apricot dawn sky, soft mist in valleys, little wildflowers in foreground and warm light. Quiet dreamlike, sophisticated editorial landscape oil painting with visible subtle grain, natural atmospheric depth, beautiful composition. Wide 16:9 composition, airy muted cream, sage, slate and peach palette. The center will have a terminal window overlaid in HTML, so leave its middle visually calm, concentrate expressive landscape detail at the edges. No text, no logos, no computer, no UI, no watermark. This is an original scene, do not imitate any specific existing artwork.”

The SVG mark and orbital CSS illustration are original code-native assets. User screenshots are reference material and are not redistributed in the website.

## Accessibility and honesty

Use native buttons, links, inputs, headings, landmarks, and visible focus. Give preview buttons descriptive accessible names and selected states. Hide decorative palette swatches and synthetic terminal art from accessibility. Supply a skip link. Documentation and theme searches have explicit labels, counts, and no-results feedback.

Do not claim “fastest,” universal compatibility, full Ghostty parity, measured GPU timings, broad OS testing, endorsements, or a public release without corresponding evidence. Build and theme CTAs must work. A simulated terminal on the website must be identified as an illustration; the app must use an actual PTY.

## Review before shipping

- Validate wide and 390 px layouts, keyboard focus, and the reduced-motion stylesheet.
- Exercise native theme search, favorite, apply, dismissal, and profile persistence.
- Verify app and web catalogs match, IDs are unique, and all files pass schema checks.
- Exercise more than ten simultaneous real PTYs and their lifecycle boundaries.
- Record local artifacts in `.artifacts/` and report the exact limits of evidence.
- Keep capability tables, menu shortcuts, and release status consistent with the code.
