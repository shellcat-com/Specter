#!/usr/bin/env python3
"""Bundle the shared catalog into an offline, self-contained comparison."""
from pathlib import Path

here = Path(__file__).resolve().parent
template = (here / "gallery.template.html").read_text()
catalog = (here / "catalog.json").read_text().strip()
(here / "gallery.html").write_text(template.replace("__CATALOG__", catalog))
