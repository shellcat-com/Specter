# Contributing to Specter

Read AGENTS.md and docs/architecture.md first. Keep parser and screen changes independent of UI and GPU code. Add deterministic fixtures for each new escape sequence or terminal mode, including fragmented and malformed input. Add a failing regression before fixing a discovered bug.

Use a codex/ branch or an isolated worktree. Make one conventional commit per coherent capability. Run `scripts/check.sh`, exercise the real application, and record exact commands and results. Use `swift run -c release SpecterBench --fuzz 600` for parser changes. Reproduce performance measurements with a documented workload; compare on the same hardware under similar load.

Capture real screenshots with synthetic content. Raw captures and logs belong in `.artifacts/`. Never upload evidence, publish, push, notarize or sign for distribution without explicit approval. Local ad-hoc signing is the development default.

Avoid new dependencies unless a documented architecture decision justifies their behavior, maintenance cost and license. Do not copy Ghostty code, proprietary visual designs or unlicensed theme palettes. Unicode data carries its own notice in docs/Unicode-LICENSE.txt.
