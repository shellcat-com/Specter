# Specter — a quiet place to work

> Your shell. Your colors. Your flow.

Specter pairs a native macOS terminal with an editorial website. The app puts readable text and real shells first. The website offers room to breathe, an abstract studio illustration, and an honest route from discovery to daily use.

## Visual direction

| Surface | Direction | Purpose |
| --- | --- | --- |
| Website | Warm stone, charcoal ink, soft blue studio art, regular-weight headlines | Welcome the person before describing the machinery |
| Terminal | Native window chrome, legible monospace, selectable palette | Keep output readable and controls predictable |
| Theme Gallery | Native searchable grid, visible palette samples, favorites | Make a large collection easy to explore |
| Documentation | Persistent chapter navigation, narrow text measure, useful tables | Let people find an answer quickly |

The references are [Cursor](https://cursor.com/) for editorial proportion and [Ghostty](https://ghostty.org/) for a terminal-centered presentation. The local `design-md` skill’s Cursor reference informed the spacing/type relationships. Our live review and the user’s screenshots take precedence over a stale token catalog. Specter does not reproduce their logos, artwork, testimonials, licensed fonts, or implied endorsements.

## Website tokens

| Token | Value | Usage |
| --- | --- | --- |
| Canvas | `#F8F7F5` | Main page background |
| Ink | `#26262A` | Headlines, body emphasis, primary action |
| Body | `#68686F` | Supporting copy |
| Line | `#DEDDE1` | Quiet divisions and controls |
| Surface | `#EEEDF0` | Secondary panels |
| Accent | `#4D51A8` | Text links and interaction feedback |
| Focus | `#6468BA` | Visible keyboard outline |

System sans for website UI; `ui-monospace`, SF Mono and Menlo fallbacks for code. No remote font requests. Use regular-weight headings, tight display tracking, relaxed body line height. The top-level headline scales from 52 px on a phone to 78 px on a wide screen. Documentation text is 15 px with 1.8 line height and a maximum 790 px article measure.

Page content caps at 1,300 px. Desktop gutters are 48 px; compact gutters are 18–24 px. Primary actions have rounded ends. Cards use 4–10 px corners and hairline borders. Reserve deep shadow for the terminal illustration over the studio backdrop; ordinary content uses spacing and borders.

## Composition

1. A concise native-macOS identifier and visible preview status, a direct GitHub link, and Download leading to the repository installation guide.
2. A substantial headline paired with useful build and theme actions.
3. A neutral studio backdrop framing an illustrative terminal.
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

`website/assets/daybreak.png` is an original generated landscape created with the built-in image-generation tool on 2026-09-10. It shows a sunrise valley with sage/olive hills, distant blue-gray mountains, mist, and wildflowers. This earlier website artwork is archived; it is no longer displayed. It is not terminal wallpaper or a screenshot of the running app.

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

## Website refinement — September 10, 2026

Website chrome uses stone, charcoal, and restrained blue accents. Green panels, code blocks, focus rings, and workspace illustrations have been replaced. The original Daybreak artwork is retained as a source asset with the provenance above but is no longer displayed on the website. The hero uses an original CSS studio backdrop with concentric light and a neutral Inkstone terminal preview. Theme catalog previews preserve the real palette data so downloads remain accurate.

Every page exposes GitHub and Download in the header, including compact layouts. Download opens `https://github.com/shellcat-com/Specter/blob/main/docs/install.md`; the source-build status is explicit rather than promising an available installer.

## Companions and appearance menus — September 10, 2026

Four original code-drawn companions occupy a 60-point native strip above the terminal: Specter (lavender ghost), Comet (warm star), Sprout (green seedling), and Pixel (mauve robot). The strip belongs to the window/tab and follows the focused pane’s profile. It never occupies terminal cells, intercepts terminal output, or delays shell startup. A 24 Hz SwiftUI timeline handles subtle floating and blinking; inactive/occluded windows pause it, as do Reduce Motion and the animation toggle. Off removes the strip. The Settings sample is a separate small preview.

The Apple Terminal screenshots inform native profile/window/tab menus. TerminalColors (https://terminalcolors.com/, reviewed September 10, 2026) informs categorized theme discovery, previews, and All/Dark/Light filtering. These are design references only; no external palettes, site assets, screenshot content, or Apple profile files were imported. The existing 130 original Specter palettes exceed the requested 40 choices and retain stable IDs.

The gallery’s visual color editor works on an isolated draft with Cancel and Save & Apply. It displays default text contrast, accepts native color pickers and explicit hex colors, and saves a uniquely identified custom palette. Shell menus expose Basic (system), Dark, Light, and saved profiles. Native macOS window chrome is retained; Windows-style chrome, translucent wallpaper, Apple Terminal configuration import, and process inspectors are not introduced by this milestone.

## Pixel companions — September 10, 2026

The approved twelve-character study replaces the four original vector companions. Wisp is the default; Moth, Kettle, Mimic, Orbit, Moss, Bytebat, Cinder, Jelly, Origami, Imp, and Rover are equally available. The native companion gallery uses static grid thumbnails and one animated selected preview. Quick pickers remain in the strip and Settings. The initial integration saved Idle/Busy/Celebrate and character choices per profile; the independent-terminal update below replaces that selection scope. Legacy Specter/Comet/Sprout/Pixel IDs migrate to Wisp/Cinder/Moss/Rover; Off remains Off.

`design/mascots/generate.py` produces identical passive frame data for the native app, comparison gallery, and explicitly launched ANSI demo. The original Claude Code block-art reference and original sprite provenance are recorded in `design/mascots/README.md`. No reference artwork or source was imported.

The native renderer validates the bounded resource once and caches three colored paths per frame. It draws crisp whole-device-pixel geometry on an eight-Hz SwiftUI timeline, separate from the terminal output path. Pause freezes the pose; inactive/hidden views do not accumulate animation time. Reduce Motion shows frame zero. Decorative motion is chosen by the user, never inferred by inspecting terminal contents or running processes. The strip remains 60 points tall and its gallery stays attached to the destination captured when opened.

## Independent terminal companions — September 11, 2026

Each TerminalView owns its companion choice, seeded from its profile on creation. The strip follows the focused pane; opening its gallery captures that terminal, including when Off collapses the strip. A labeled Companions… button and Specter → Companions… (⇧⌘M) provide direct discovery and recovery from Off. Settings now labels companion values as defaults for new terminals. Optional layout restoration includes each pane’s independent selection; no terminal contents are saved.

The website shows three independently selectable character illustrations using the same generated frame catalog. Playback pauses when offscreen, hidden, manually paused, or reduced motion is requested. These previews do not change the native app or execute commands. No remote assets or animation libraries are used.

## Source installation — September 11, 2026

The landing page includes a selectable GitHub source-install command and a native copy button with an accessible success/failure status. Requirements sit directly above it: developer preview, Apple silicon, macOS 14+ deployment target, full Xcode and Metal tools. The command builds locally and installs in the user’s Applications folder; it does not promise a prebuilt or notarized download. The web and offline installation guides describe the same installer, explicit replacement, backup, and rollback behavior. Publish these instructions only alongside the installer on GitHub main; the local branch alone does not make the command publicly available.
