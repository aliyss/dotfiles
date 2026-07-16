{
  # ─── Foot terminal theme generator ───────────────────────────────
  # Produces the [colors-dark] block for foot.ini.
  # Conventional ANSI mapping using oxocarbon palette colors.

  theme,
  ...
}: let
  p = theme.palette;
  # oxocarbon has no yellow — use IBM Carbon's official yellow
  carbonYellow = "#f1c21b";
in ''
  [colors-dark]
  alpha=0.85
  background=000000
  selection-background=${p.surface2}
  selection-foreground=${p.text}
  search-box-no-match=${p.surface0} ${p.red}
  search-box-match=${p.surface0} ${p.green}
  jump-labels=${p.surface0} ${carbonYellow}
  scrollback-indicator=${p.surface0} ${p.blue}
  urls=${p.blue}
  foreground=${p.text}
  regular0=${p.surface0}
  regular1=${p.red}
  regular2=${p.green}
  regular3=${carbonYellow}
  regular4=${p.blue}
  regular5=${p.mauve}
  regular6=${p.sky}
  regular7=${p.text}
  bright0=${p.surface2}
  bright1=${p.red}
  bright2=${p.green}
  bright3=${carbonYellow}
  bright4=${p.blue}
  bright5=${p.mauve}
  bright6=${p.teal}
  bright7=#ffffff
''
