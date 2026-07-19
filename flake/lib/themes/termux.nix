{ theme, lib, ... }: let
  p = theme.palette;
in ''
  # Termux colors generated from central theme.nix
  # background is kept at 000000 for high contrast
  background: #000000
  foreground: ${p.text}
  cursor: ${p.text}

  # Black / Gray
  color0: ${p.surface0}
  color8: ${p.surface1}

  # Red
  color1: ${p.red}
  color9: ${p.red}

  # Green
  color2: ${p.green}
  color10: ${p.green}

  # Yellow (Peach/Yellow alias)
  color3: ${p.peach}
  color11: ${p.peach}

  # Blue
  color4: ${p.blue}
  color12: ${p.blue}

  # Magenta
  color5: ${p.mauve}
  color13: ${p.mauve}

  # Cyan (Teal)
  color6: ${p.teal}
  color14: ${p.teal}

  # White
  color7: ${p.text}
  color15: #ffffff
''
