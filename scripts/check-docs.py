#!/usr/bin/env python3
"""Validate local Markdown links and fragments; never request external URLs.

Handles the repository's inline Markdown links and explicit HTML anchors.
Code fences are excluded so example links are not treated as documentation routes.
"""
from pathlib import Path
import re
import sys
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]


def prose(path):
    return re.sub(r'^```[^\n]*\n.*?^```\s*$', '', path.read_text(), flags=re.M | re.S)


def anchors(path):
    text = prose(path)
    result = set(re.findall(r'\bid=["\']([^"\']+)["\']', text))
    counts = {}
    if path.suffix == '.md':
        for title in re.findall(r'^#{1,6}\s+(.+?)\s*#*$', text, re.M):
            slug = re.sub(r'[^\w\- ]', '', title.lower()).replace(' ', '-')
            count = counts.get(slug, 0)
            counts[slug] = count + 1
            result.add(f'{slug}-{count}' if count else slug)
    return result


def main():
    files = sorted(set(ROOT.glob('*.md')) | set((ROOT / 'docs').rglob('*.md')))
    errors, checked = [], 0
    for source in files:
        for href in re.findall(r'!?\[[^\]\n]*\]\(([^\s)]+)\)', prose(source)):
            parts = urlsplit(href.strip('<>'))
            if parts.scheme or parts.netloc:
                continue
            target = (source.parent / unquote(parts.path)).resolve() if parts.path else source
            checked += 1
            if not target.is_file():
                errors.append(f'{source.relative_to(ROOT)}: missing file {href}')
            elif parts.fragment and target.suffix in ('.md', '.html'):
                if unquote(parts.fragment) not in anchors(target):
                    errors.append(f'{source.relative_to(ROOT)}: missing anchor {href}')
    if errors:
        print('\n'.join(errors), file=sys.stderr)
        return 1
    print(f'PASS: {checked} local links in {len(files)} Markdown documents; files and fragments resolve.')
    print('External URLs are not fetched; availability and permissions are not verified.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
