#!/usr/bin/env python3
"""Generate Specter's original, coordinated theme collection for the app and website."""
import colorsys
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[1]

def hexcolor(hue, saturation, lightness):
    return '#' + ''.join(f'{round(c * 255):02X}' for c in colorsys.hls_to_rgb(hue / 360, lightness, saturation))

def theme(name, background, foreground, dark, hue=215, saturation=.48):
    chromatic = [5, 135, 45, 220, 285, 180]
    normal = [hexcolor((h + (hue-215)*.07) % 360, saturation, .70 if dark else .31) for h in chromatic]
    bright = [hexcolor((h + (hue-215)*.07) % 360, saturation+.06, .79 if dark else .36) for h in chromatic]
    return dict(version=1, id=name.lower().replace(' ', '-'), name=name,
                background=background, foreground=foreground, isDark=dark,
                cursor=hexcolor(hue, .55, .78 if dark else .31),
                selection=hexcolor(hue, .22, .27 if dark else .80),
                palette=['#29313B', *normal, '#D5DBE3', '#77828F', *bright, '#F4F6FA'])

# Retain the original ten IDs so saved profiles continue to resolve.
originals = [
    ('Specter Night','#171B22','#DCE2EC',True), ('Specter Day','#F6F7FA','#26313F',False),
    ('Deep Tide','#122128','#D2E4E7',True), ('Inkstone','#202024','#E6E2DE',True),
    ('Orchard','#19231E','#D8E4D8',True), ('Ember','#28201E','#EBDCD1',True),
    ('Dusk','#211D2C','#E1DAEE',True), ('Paper','#F5F0E6','#39342E',False),
    ('Mist','#EAF2F1','#263A3A',False), ('Porcelain','#F9F3F6','#402F3B',False)]
catalog = [theme(*item) for item in originals]
# Twenty art-directed color families, each with six explicitly named light/dark treatments.
families = [('Alpine',155),('Aurora',170),('Basalt',225),('Boreal',140),('Canyon',20),
            ('Celadon',100),('Cobalt',218),('Copper',28),('Fig',285),('Glacier',195),
            ('Heather',265),('Lagoon',182),('Linen',42),('Marigold',48),('Moonstone',240),
            ('Mulberry',318),('Petal',345),('Saffron',36),('Sequoia',120),('Wisteria',275)]
treatments = [('Midnight',True,.075,.22,.45),('Nocturne',True,.115,.25,.52),
              ('Velvet',True,.155,.20,.38),('Dawn',False,.94,.30,.48),
              ('Daylight',False,.975,.22,.55),('Parchment',False,.90,.24,.40)]
for family,hue in families:
    for treatment,dark,level,tint,sat in treatments:
        catalog.append(theme(f'{family} {treatment}', hexcolor(hue,tint,level),
                             hexcolor(hue,.16,.89 if dark else .16),dark,hue,sat))
assert len(catalog) == len({t['id'] for t in catalog}) == 130
encoded=json.dumps(catalog,indent=2)+'\n'
for relative in ['Sources/MetalTerminal/Themes/catalog.json','website/themes.json']:
    path=ROOT/relative
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(encoded)
downloads = ROOT / 'website' / 'themes'
downloads.mkdir(exist_ok=True)
for item in catalog:
    (downloads / (item['id'] + '.json')).write_text(json.dumps(item, indent=2) + '\n')
print(f'Generated {len(catalog)} original themes for app and website.')
