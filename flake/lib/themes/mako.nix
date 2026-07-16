{
  # ─── mako theme generator ────────────────────────────────────────
  # Produces a mako config snippet matching the oxocarbon palette.

  theme,
  ...
}: let
  p = theme.palette;
in ''
  background-color=${p.base}
  text-color=${p.text}
  border-color=${p.blue}
  progress-color=over ${p.surface1}
  
  [urgency=low]
  border-color=${p.surface1}

  [urgency=high]
  border-color=${p.red}
  text-color=${p.red}
''
