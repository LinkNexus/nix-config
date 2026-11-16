# Rewrites a font's underline metrics and renames its family, so the patched
# copy installs alongside the original instead of shadowing it.
#
#   patch-underline.py IN OUT SUFFIX THICKNESS_SCALE POSITION_SHIFT
#
# SUFFIX is appended to the family ("MonaspiceRn NFM" -> "MonaspiceRn NFM
# Rex") and, without spaces, to the PostScript name. POSITION_SHIFT is in
# font units; positive moves the underline down, like kitty's
# underline_position.

import re
import sys

from fontTools.ttLib import TTFont

src, dst, suffix, scale, shift = sys.argv[1:6]
font = TTFont(src)

post = font["post"]
post.underlineThickness = round(post.underlineThickness * float(scale))
post.underlinePosition -= int(shift)

# Family names come in a long ("Nerd Font Mono") and a short ("NFM") form,
# with spaces in the name table and without in PostScript names.
families = re.compile(r"(\w+ Nerd Font Mono|\w+ NFM|\w+NFM)(?=$|[ -])")


def rename(name):
    return families.sub(
        lambda m: m.group(1) + (suffix if " " not in m.group(1) else " " + suffix),
        name,
        count=1,
    )


for record in font["name"].names:
    if record.nameID in (1, 3, 4, 6, 16, 21):
        record.string = rename(record.toUnicode())

if "CFF " in font:
    cff = font["CFF "].cff
    cff.fontNames = [rename(n) for n in cff.fontNames]
    top = cff.topDictIndex[0]
    for key in ("FullName", "FamilyName"):
        if hasattr(top, key):
            setattr(top, key, rename(getattr(top, key)))

font.save(dst)
