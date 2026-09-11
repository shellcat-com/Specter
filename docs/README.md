# Specter documentation

Specter is a source-build development preview for Apple silicon. macOS 14+ is the deployment target; tested hardware, OS versions, and limitations are recorded in [compatibility](compatibility.md).

## Find an answer

| Your task | Guide |
| --- | --- |
| Download source, build, install, update, or uninstall | [Installation](install.md) |
| Learn the app or read offline | [Handbook](handbook.md); Help → Specter Handbook in the app |
| Open windows, tabs, splits, or find a session | [Sessions](handbook.md#sessions) |
| Choose themes, edit colors, or control companions | [Appearance](handbook.md#themes) |
| Set a shell, font, or starting directory | [Profiles](handbook.md#profiles) |
| Find shortcuts, copy/paste, search, or preview files | [Keyboard and text](handbook.md#shortcuts) |
| Reopen a layout and understand what is saved | [Restoration](handbook.md#restoration) |
| Connect to an SSH host | [SSH and everyday use](handbook.md#ssh) |
| Fix a problem, ask a question, or request a feature | [Troubleshooting and support](handbook.md#troubleshooting) |
| Check supported terminal sequences and known gaps | [Compatibility](compatibility.md) |
| Understand privacy or report a vulnerability privately | [Security policy](../SECURITY.md) |

## Develop and verify

Start with [Contributing](../CONTRIBUTING.md), [the engineering guide](../AGENTS.md), and [architecture](architecture.md). Read [DESIGN.md](../DESIGN.md) before changing app or website surfaces.

The handbook source is `website/guides.js`. `node scripts/export-handbook.mjs` generates `docs/handbook.md` and `Resources/Handbook.html`; edit the source and regenerate both. The website uses that same source directly. The offline edition needs no network to read, but external links require connectivity.

| Evidence | Scope |
| --- | --- |
| [Documentation review](documentation-validation.md) | Current documentation, generated editions, checks, and local runtime exercise |
| [Core validation](validation.md) | Historical engine, PTY, rendering, and benchmark evidence |
| [Design validation](design-validation.md) | Theme gallery and multi-session evidence |
| [Website refinement](website-refinement-validation.md) | Local website layout and interaction evidence |
| [Appearance and companions](companion-validation.md) | Initial appearance editor and companion implementation |
| [Pixel companions](pixel-companion-validation.md) | Twelve-character integration |
| [Independent companions](companion-sessions-validation.md) | Per-pane choices and restoration |

Evidence records describe particular revisions and environments. They are not blanket compatibility guarantees. Screenshots may show an earlier interface; use the handbook for current instructions. [Media notes](media/README.md) distinguish recordings and illustrations. [Reference review](reference-review.md) records design research, not additional app capabilities.
