# Contributing to Specter

Specter targets macOS 14+ on Apple silicon with Swift 6. Start with the [installation guide](docs/install.md), [engineering rules](AGENTS.md), and [architecture](docs/architecture.md). The [documentation index](docs/README.md) covers user workflows and local evidence.

## Set up a change

Use full Xcode with the macOS SDK, Metal tools, and `swift-format`. The complete checks also require Node.js for the handbook exporter and Python 3 for documentation and website validation (validated with Node.js 25.8.1 and Python 3.14.6). No npm packages are needed. XcodeGen is needed only when regenerating the checked-in Xcode project from `project.yml`.

For independent work, create an isolated worktree from an existing commit, using an unused directory and a `codex/` branch:

```sh
git worktree add -b codex/my-change ../Specter-my-change HEAD
cd ../Specter-my-change
```

Keep parser and screen changes independent of UI and GPU code. Use deterministic fixtures for new escape sequences and modes, including fragmented and malformed input. Add a failing regression before fixing a discovered code bug. Read [DESIGN.md](DESIGN.md) before changing user-facing surfaces.

## Documentation and website changes

Edit `website/guides.js` for handbook content, then regenerate both committed editions:

```sh
node scripts/export-handbook.mjs
node scripts/export-handbook.mjs --check
python3 scripts/check-docs.py
python3 scripts/check-website.py
scripts/serve-website.sh
```

Open `http://127.0.0.1:4173/docs.html`. Check chapter search, links, narrow and wide layouts, keyboard navigation, and the offline edition in `Resources/Handbook.html`. The server binds only to localhost; stop it with Control-C. Use a different port, such as `scripts/serve-website.sh 4174`, if needed. No publication is part of local preview.

Keep menu names, shortcuts, profile scope, and limitations aligned with source behavior. Use `scripts/generate-themes.py` for shared palettes. Generated Markdown and offline HTML must not be edited independently. Historical evidence should retain its original context; record new results separately.

## Required checks

From the worktree root:

```sh
scripts/check.sh
swift run SpecterBench
swift run SpecterBench --fuzz 600
```

`check.sh` verifies generated documentation, local documentation links, website routes and theme parity, Swift formatting and tests, C static analysis, and a release app build. `scripts/build-app.sh` can also build the app on its own without the documentation tools. For performance measurements, use `swift run -c release SpecterBench` and record the build configuration; compare only on the same hardware under similar load.

Exercise the actual app where applicable with synthetic content. A build is not a runtime test; offscreen rendering tests are not screenshots of a working app. Record the command, toolchain, revision, expected behavior, actual result, and remaining limitations. Keep raw artifacts in `.artifacts/` and commit only reviewed public-safe evidence. Do not record existing personal terminal sessions.

Review the staged diff and finish each coherent milestone with one conventional commit, for example `docs: clarify profile and restoration behavior`. Pushes, publication, releases, notarization, distribution signing, and evidence uploads require explicit approval. Local ad-hoc signing is the development default. Do not install or run Greptile workflows.

## Report a problem

Follow the [support checklist](docs/handbook.md#troubleshooting) for bugs, questions, and feature requests. Report suspected vulnerabilities privately as described in [SECURITY.md](SECURITY.md).

Avoid new dependencies unless an architecture decision justifies their behavior, maintenance cost, and license. Do not copy proprietary visual designs or unlicensed theme palettes. Unicode data retains its [license](docs/Unicode-LICENSE.txt).
