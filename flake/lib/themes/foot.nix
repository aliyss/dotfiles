{
  # ─── Foot terminal theme generator ───────────────────────────────
  # Produces the [colors-dark] block for foot.ini.
  # Conventional ANSI mapping using oxocarbon palette colors.
  theme,
  lib,
  ...
}: let
  p = theme.palette;
  # oxocarbon has no yellow — use IBM Carbon's official yellow
in ''
  [colors-dark]
  alpha=0.85
  background=000000
  selection-background=${lib.removePrefix "#" p.surface1}
  selection-foreground=${lib.removePrefix "#" p.text}
  search-box-no-match=${lib.removePrefix "#" p.surface0} ${lib.removePrefix "#" p.red}
  search-box-match=${lib.removePrefix "#" p.surface0} ${lib.removePrefix "#" p.green}
  jump-labels=${lib.removePrefix "#" p.surface0} ${lib.removePrefix "#" p.peach}
  scrollback-indicator=${lib.removePrefix "#" p.surface0} ${lib.removePrefix "#" p.blue}
  urls=${lib.removePrefix "#" p.blue}
  foreground=${lib.removePrefix "#" p.text}
  regular0=${lib.removePrefix "#" p.surface0}
  regular1=${lib.removePrefix "#" p.red}
  regular2=${lib.removePrefix "#" p.green}
  regular3=${lib.removePrefix "#" p.peach}
  regular4=${lib.removePrefix "#" p.blue}
  regular5=${lib.removePrefix "#" p.mauve}
  regular6=${lib.removePrefix "#" p.teal}
  regular7=${lib.removePrefix "#" p.text}
  bright0=${lib.removePrefix "#" p.surface1}
  bright1=${lib.removePrefix "#" p.red}
  bright2=${lib.removePrefix "#" p.green}
  bright3=${lib.removePrefix "#" p.peach}
  bright4=${lib.removePrefix "#" p.blue}
  bright5=${lib.removePrefix "#" p.mauve}
  bright6=${lib.removePrefix "#" p.teal}
  bright7=ffffff
''
