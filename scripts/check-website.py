#!/usr/bin/env python3
"""Check static routes, theme parity and content constraints without a browser dependency."""
import json
import pathlib
import re
from html.parser import HTMLParser
from urllib.parse import urlsplit, parse_qs

ROOT = pathlib.Path(__file__).resolve().parents[1]
SITE = ROOT / 'website'
class Page(HTMLParser):
    def __init__(self, text):
        super().__init__()
        self.links, self.ids, self.headings, self.resources = [], set(), [], []
        self.feed(text)
    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if 'id' in a:
            assert a['id'] not in self.ids, f'Duplicate id: {a["id"]}'
            self.ids.add(a['id'])
        if tag == 'h1': self.headings.append(tag)
        if tag == 'a' and 'href' in a: self.links.append(a['href'])
        if tag in ('img', 'script') and 'src' in a: self.resources.append(a['src'])
        if tag == 'img': assert 'alt' in a, 'Image missing alt'
        if tag == 'link' and a.get('rel') in ('stylesheet', 'icon'): self.resources.append(a['href'])

pages = {p.name: Page(p.read_text()) for p in SITE.glob('*.html')}
guides = (SITE / 'guides.js').read_text()
chapters = set(re.findall(r"id:'([^']+)'", guides))
assert len(chapters) == 13
for name, page in pages.items():
    assert len(page.headings) == 1, f'{name}: exactly one h1 required'
    assert 'main' in page.ids, f'{name}: skip target missing'
    for href in page.links + page.resources:
        parts = urlsplit(href)
        if parts.scheme or parts.netloc:
            assert href not in page.resources, 'Unexpected third-party resource'
            continue
        target = parts.path or name
        assert (SITE / target).is_file(), f'{name}: missing {target}'
        if parts.fragment and target in pages:
            assert parts.fragment in pages[target].ids, f'Missing anchor {href}'
        if 'guide' in parse_qs(parts.query):
            assert parse_qs(parts.query)['guide'][0] in chapters, f'Unknown guide: {href}'
for match in re.findall(r'href="([^"]+)"', guides):
    if match.startswith('docs.html?guide='):
        assert match.split('=')[-1] in chapters, match

catalog = json.loads((SITE / 'themes.json').read_text())
assert catalog == json.loads((ROOT / 'Sources/MetalTerminal/Themes/catalog.json').read_text())
assert len(catalog) == len({t['id'] for t in catalog}) == 130
assert len({json.dumps([t['background'],t['foreground'],t['palette']]) for t in catalog}) == 130

def luminance(color):
    values = [int(color[n:n+2],16)/255 for n in (1,3,5)]
    values = [v/12.92 if v <= .04045 else ((v+.055)/1.055)**2.4 for v in values]
    return sum(a*b for a,b in zip(values,[.2126,.7152,.0722]))
ratios = []
for theme in catalog:
    assert theme['version'] == 1 and len(theme['palette']) == 16
    assert re.fullmatch(r'[a-z0-9-]+', theme['id'])
    for color in [theme[k] for k in ('background','foreground','cursor','selection')] + theme['palette']:
        assert re.fullmatch(r'#[0-9A-F]{6}', color)
    a,b = sorted([luminance(theme['background']),luminance(theme['foreground'])])
    ratios.append((b+.05)/(a+.05))
    assert ratios[-1] >= 7, theme['name']
    download = SITE / 'themes' / (theme['id']+'.json')
    assert download.stat().st_size <= 65536
    assert json.loads(download.read_text()) == theme
offline = Page((ROOT/'Resources/Handbook.html').read_text())
assert len(offline.headings) == 1
assert chapters.issubset(offline.ids)
assert not offline.resources, 'Offline handbook must be self-contained'
for link in offline.links:
    if link.startswith('#'): assert link[1:] in offline.ids
css = (SITE/'styles.css').read_text()
assert 'prefers-reduced-motion:reduce' in css
assert ':focus-visible' in css
print(f'PASS: {len(pages)} pages, {len(chapters)} chapters, static links/resources, 130 matching app/web/download themes.')
print(f'PASS: 130 unique palettes, schema and size bounds, default text contrast minimum {min(ratios):.2f}:1.')
print('Browser layout, download behavior, keyboard access, and native runtime require separate exercise.')
