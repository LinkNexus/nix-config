# MonaspiceRn Nerd Font Mono with a thicker, lower underline, for Rex, which
# has no underline settings and draws the font's own metrics. Installed as
# its own family ("MonaspiceRn Nerd Font Mono Rex") so kitty and every other
# app keep the stock font. Values mirror kitty's underline_thickness 250%
# and underline_position 2 at font_size 19 (2000 units/em).
{pkgs}:
pkgs.runCommand "monaspice-rn-rex" {
  nativeBuildInputs = [(pkgs.python3.withPackages (p: [p.fonttools]))];
} ''
  dir=$out/share/fonts/opentype/MonaspiceRex
  mkdir -p $dir
  for f in ${pkgs.nerd-fonts.monaspace}/share/fonts/opentype/NerdFonts/Monaspice/MonaspiceRnNerdFontMono-*.otf; do
    name=$(basename "$f")
    python3 ${./patch-underline.py} "$f" "$dir/''${name/NerdFontMono/NerdFontMonoRex}" Rex 2.5 105
  done
''
