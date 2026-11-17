# MonaspiceRn Nerd Font Mono patched for Rex, which has neither underline
# settings nor font features: a thicker, lower underline (kitty's
# underline_thickness 250% / underline_position 2 at font_size 19, 2000
# units/em) and the code ligatures of ss01-ss10 always on (kitty's
# font_features). Installed as its own family ("MonaspiceRn Nerd Font Mono
# Rex") so kitty and every other app keep the stock font.
{pkgs}:
pkgs.runCommand "monaspice-rn-rex" {
  nativeBuildInputs = [(pkgs.python3.withPackages (p: [p.fonttools]))];
} ''
  dir=$out/share/fonts/opentype/MonaspiceRex
  mkdir -p $dir
  for f in ${pkgs.nerd-fonts.monaspace}/share/fonts/opentype/NerdFonts/Monaspice/MonaspiceRnNerdFontMono-*.otf; do
    name=$(basename "$f")
    python3 ${./patch-font.py} "$f" "$dir/''${name/NerdFontMono/NerdFontMonoRex}" Rex 2.5 105 \
      ss01,ss02,ss03,ss04,ss05,ss06,ss07,ss08,ss09,ss10
  done
''
