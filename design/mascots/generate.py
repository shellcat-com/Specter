#!/usr/bin/env python3
"""Original Specter sprite studies. No imported art or executable catalog data."""
import json
from html import escape
from pathlib import Path

HERE = Path(__file__).resolve().parent
SIZE = 24
# B = body, o = dark eye, A = secondary detail. Dots are transparent.
# Deliberately different silhouettes; each has a hand-placed moving feature.
STUDIES = [
    ("wisp", "Wisp", "A little ghost with an oversized hood and a restless ribbon tail.",
     "Tail flick", "#BCB4FA", "#EEE7FF", "tail", """
......BBBBBB
....BBBBBBBBBB
...BBBBBBBBBBBB
..BBBBBBBBBBBBBB
..BBBooBBBBooBBB
..BBBooBBBBooBBB
..BBBBBBBBBBBBBB
..BBBBBBaaBBBBBB
...BBBBBBBBBBBB
...BBB.BBBB.BBB
....BB..BB..BB
"""),
    ("moth", "Moth", "A moon moth with enormous folded wings and tiny boots.",
     "Wing flutter", "#D8BEF0", "#F7E3AA", "wings", """
......A....A
.......A..A
.BBB...BBBB...BBB
BBBBB.BoBBoB.BBBBB
BBBBBBBoBBoBBBBBBB
.BBABBBBBBBBBBABB
..BBBBBBBBBBBBBB
...BBBBBBBBBBBB
..BBBB..BB..BBBB
...BB...BB...BB
........AA
"""),
    ("kettle", "Kettle", "A pocket tea spirit. Steam curls while the little lid taps.",
     "Steam & lid", "#F0C38E", "#FFF0CD", "steam", """
......AAAAAA
.....BBBBBBBB
....BBBBBBBBBB
..BBBBBBBBBBBBBB.BB
BBBBBooBBBBooBBBB.B
.BBBBooBBBBooBBBB.B
..BBBBBBBBBBBBBB.BB
...BBBBBaaBBBBBB
....BBBBBBBBBB
......BB..BB
"""),
    ("mimic", "Mimic", "A shy shell creature peeking out of a chunky prompt box.",
     "Lid chomp", "#9ACDC0", "#DDF9EA", "lid", """
..AAAAAAAAAAAAAA
.ABBBBBBBBBBBBBBA
.ABBBBBBBBBBBBBBA
..AAAAAAAAAAAAAA
..BAAAAAAAAAAAAB
..BAAooAAAAooAAB
..BAAooAAAAooAAB
.ABBBBBBBBBBBBBBA
.ABBBBBAABBBBBBBA
..AAAAAAAAAAAAAA
...BB........BB
"""),
    ("orbit", "Orbit", "A satellite with a single curious lens and a wandering moon.",
     "Moon orbit", "#9CBFF3", "#F5DEAA", "orbit", """
......BBBBBB
....BBBBBBBBBB
...BBBBBBBBBBBB
..BBBBooooooBBBB
..BBBooAAooooBBB
..BBBooAAooooBBB
..BBBBooooooBBBB
...BBBBBBBBBBBB
....BBBBBBBBBB
......BBBBBB
"""),
    ("moss", "Moss", "A walking mushroom with a broad speckled cap and short steps.",
     "Cap wobble", "#A9C9A1", "#F3E8BC", "cap", """
......BBBBBB
....BBBBBBBBBB
...BBAABBBBAABB
..BBBAABBBBBBBBB
.BBBBBBBBBBBBBBBB
BBBBBBAABBBBAABBBB
.BBBBBBBBBBBBBBBB
.....AAAAAAAA
.....AAoAAoAA
.....AAoAAoAA
......AAAAAA
......AA..AA
"""),
    ("bytebat", "Bytebat", "An alert cave bat with tall ears and a scalloped cape.",
     "Cape flap", "#B5ABDE", "#E1D7FF", "wings", """
.....BB....BB
.....BBB..BBB
.....BBBBBBBB
BB...BooBBooB...BB
BBB..BooBBooB..BBB
BBBBBBBBBBBBBBBBBB
.BBBBBBBaaBBBBBBB
..BB.BBBBBBBB.BB
......BBBBBB
.......A..A
"""),
    ("cinder", "Cinder", "An ember with a lopsided flame and heavy charcoal boots.",
     "Flame dance", "#F2AB86", "#FFE1A0", "flame", """
........BB
.......BBB
....B..BBBB
....BBBBBBBB
...BBBBBBBBBB
..BBBBBBBBBBBB
..BBBooBBooBBB
..BBBooBBooBBB
...BBBBBBBBBB
....BBAAAABB
.....AAAAAA
.....AA..AA
"""),
    ("jelly", "Jelly", "A translucent bell with sleepy eyes and four trailing tentacles.",
     "Tentacle ripple", "#93D0D7", "#DFFBFA", "tentacles", """
.....BBBBBBBB
...BBBBBBBBBBBB
..BBBBAABBBBBBBB
..BBBAABBBBBBBBB
.BBBBBBBBBBBBBBBB
.BBBooBBBBBBooBBB
.BBBBBBBBBBBBBBBB
..AAAAAAAAAAAAAA
....AA.AA.AA.AA
....AA.AA.AA.AA
....AA.AA.AA.AA
"""),
    ("origami", "Origami", "A folded paper fox with sharp ears and an enormous brush tail.",
     "Brush swish", "#E6B4A1", "#FFF0DE", "tail", """
...BB......BB
...BBB....BBB
...BBBB..BBBB
...BBBBBBBBBB
...BAoBBBBoAB
...BAoBBBBoAB
....BAABBAAB
.....BAAAAB
......BooB
.....BBBBBB
.....BB..BB
"""),
    ("imp", "Imp", "A mischievous horned gremlin with a crooked, oversized grin.",
     "Ear twitch", "#D8ABD0", "#FFE0F5", "ears", """
...BB........BB
...BBB......BBB
....BBBBBBBBBB
...BBBBBBBBBBBB
..BBooBBBBBBooBB
..BBooBBBBBBooBB
..BBBBBBBBBBBBBB
...BBBAAAAABBBB
....BBBBBBBBBB
.....BBBBBBBB
.....BBB..BBB
"""),
    ("rover", "Rover", "A round-eyed lunar robot on caterpillar tracks. Always rolling.",
     "Track crawl", "#A9C5DD", "#E6EEF7", "tracks", """
........AA
........BB
...BBBBBBBBBBBB
..BBAAAABBAAAABB
..BBAooABBAooABB
..BBAooABBAooABB
..BBAAAABBAAAABB
...BBBBBBBBBBBB
......BBBBBB
..AAAAAAAAAAAAAA
.AAooAAooAAooAAoo
..AAAAAAAAAAAAAA
"""),
]


def frame(study, state, tick):
    ident, _, _, _, _, _, motion, art = study
    rows = art.strip().replace("a", "A").splitlines()
    grid = [["." for _ in range(SIZE)] for _ in range(SIZE)]
    beat = [0, 0, 1, 1, 0, 0, -1, -1, 0, 0, 0, 0][tick]
    lift = [0, 0, -1, -2, -2, -1, 0, 0, 0, -1, 0, 0][tick] if state == "celebrate" else 0
    x0, y0 = 3, 6 + lift

    def put(x, y, value):
        if 0 <= x < SIZE and 0 <= y < SIZE:
            grid[y][x] = value

    for y, row in enumerate(rows):
        for x, value in enumerate(row):
            if value == ".":
                continue
            dx = beat if motion in ("cap", "ears") and y < 4 else 0
            dy = beat if motion == "wings" and (x < 4 or x > 13) else 0
            if motion == "lid" and y < 4:
                dy = -max(0, beat)
            if motion == "tentacles" and y > 7:
                dx = beat if (x // 3) % 2 else -beat
            if motion == "flame" and y < 5:
                dx = beat
            # One brief blink, followed by a clean return to the base pose.
            if value == "o" and state == "idle" and tick == 9 and y > 0 and x < len(rows[y - 1]) and rows[y - 1][x] == "o":
                value = "B"
            if motion == "tracks" and y == 10 and state != "idle":
                value = "o" if (x + tick) % 4 < 2 else "A"
            put(x0 + x + dx, y0 + y + dy, value)
    if motion == "tail":
        start_x, start_y, length = (14, 9, 7) if ident == "origami" else (17, 8, 5)
        for i in range(length):
            put(start_x + i, y0 + start_y - i // 2 + (beat if i > 1 else 0), "B")
            put(start_x + i, y0 + start_y + 1 - i // 2 + (beat if i > 1 else 0), "A")
    if motion == "steam":
        for i in range(3):
            put(10 + i * 3 + beat, 2 + (i + tick // 2) % 3, "A")
    if motion == "orbit":
        moon = [(20, 8), (21, 10), (21, 13), (19, 17), (15, 19), (10, 20), (5, 18), (2, 14), (2, 10), (4, 6), (10, 3), (16, 4)][tick]
        for dx, dy in [(0, 0), (1, 0), (0, 1), (1, 1)]:
            put(moon[0] + dx, moon[1] + dy, "A")
    if state == "working":
        # Small activity track is deliberately separate from the face.
        for i in range(5):
            put(8 + i * 2, 22, "A" if i == (tick // 2) % 5 else "B")
    if state == "celebrate":
        for x, y in [(2, 3), (20, 2), (1, 15), (21, 18)]:
            put(x, y + tick % 3, "A")
            if tick % 4 < 2:
                put(x + 1, y + tick % 3, "A")
    return ["".join(row) for row in grid]


def main():
    catalog = {"version": 1, "width": SIZE, "height": SIZE, "fps": 8, "mascots": []}
    for study in STUDIES:
        ident, name, description, gesture, body, accent, _, _ = study
        catalog["mascots"].append({
            "id": ident, "name": name, "description": description, "gesture": gesture,
            "colors": {"B": body, "A": accent, "o": "#25232D"},
            "states": {state: [frame(study, state, t) for t in range(12)]
                       for state in ("idle", "working", "celebrate")},
        })
    encoded = json.dumps(catalog, separators=(",", ":")) + "\n"
    (HERE / "catalog.json").write_text(encoded)
    resource = HERE.parents[1] / "Sources/TerminalUI/Resources/Mascots.json"
    resource.parent.mkdir(parents=True, exist_ok=True)
    resource.write_text(encoded)
    (HERE.parents[1] / "website/mascots.json").write_text(encoded)
    # Static, accessible GitHub catalog illustration; animation stays in the app and live previews.
    svg = ['<svg xmlns="http://www.w3.org/2000/svg" width="960" height="588" viewBox="0 0 960 588" role="img" aria-labelledby="title desc">',
           '<title id="title">Twelve Specter companions</title>',
           '<desc id="desc">Original pixel character catalog, arranged in three rows. Static illustration, not an app screenshot.</desc>',
           '<rect width="960" height="588" rx="16" fill="#191D25"/>',
           '<g font-family="system-ui,sans-serif" fill="#EFEFF6"><text x="32" y="44" font-size="22">A little company. Twelve ways.</text>',
           '<text x="32" y="71" font-size="13" fill="#B2B5C2">Choose independently in each terminal · Companions… or ⇧⌘M</text></g>']
    for index, mascot in enumerate(catalog['mascots']):
        x0, y0 = 24 + (index % 4) * 234, 94 + (index // 4) * 158
        svg.append(f'<rect x="{x0}" y="{y0}" width="210" height="142" rx="8" fill="#242935"/>')
        for y, row in enumerate(mascot['states']['idle'][0]):
            for x, token in enumerate(row):
                if token != '.':
                    svg.append(f'<rect x="{x0+57+x*4}" y="{y0+5+y*4}" width="4" height="4" fill="{mascot["colors"][token]}"/>')
        svg.append(f'<text x="{x0+105}" y="{y0+126}" text-anchor="middle" font-family="system-ui,sans-serif" font-size="14" fill="#EFEFF6">{escape(mascot["name"])}</text>')
    svg.append('</svg>')
    (HERE.parents[1] / 'docs/images/companions.svg').write_text('\n'.join(svg) + '\n')


if __name__ == "__main__":
    main()
