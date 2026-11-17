# Rewrites a font's underline metrics, turns optional OpenType features on
# for good, and renames its family, so the patched copy installs alongside
# the original instead of shadowing it.
#
#   patch-font.py IN OUT SUFFIX THICKNESS_SCALE POSITION_SHIFT [FEATURES]
#
# SUFFIX is appended to the family ("MonaspiceRn NFM" -> "MonaspiceRn NFM
# Rex") and, without spaces, to the PostScript name. POSITION_SHIFT is in
# font units; positive moves the underline down, like kitty's
# underline_position. FEATURES is a comma-separated list such as
# "ss01,ss02", for apps that can't enable features themselves.

import re
import sys

from fontTools.ttLib import TTFont

src, dst, suffix, scale, shift = sys.argv[1:6]
features = set(sys.argv[6].split(",")) if len(sys.argv) > 6 else set()
font = TTFont(src)

post = font["post"]
post.underlineThickness = round(post.underlineThickness * float(scale))
post.underlinePosition -= int(shift)

# Fold each wanted feature's lookups into calt, which shapers always apply.
# Lookups run in lookup-list order whatever feature holds them, so this
# behaves exactly as if the app had switched the features on.
if features and "GSUB" in font:
    gsub = font["GSUB"].table
    records = gsub.FeatureList.FeatureRecord
    for script in gsub.ScriptList.ScriptRecord:
        langs = [script.Script.DefaultLangSys] + [l.LangSys for l in script.Script.LangSysRecord]
        for lang in filter(None, langs):
            wanted = {
                lookup
                for i in lang.FeatureIndex
                if records[i].FeatureTag in features
                for lookup in records[i].Feature.LookupListIndex
            }
            for i in lang.FeatureIndex:
                if records[i].FeatureTag == "calt":
                    feature = records[i].Feature
                    feature.LookupListIndex = sorted(set(feature.LookupListIndex) | wanted)
                    feature.LookupCount = len(feature.LookupListIndex)

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
