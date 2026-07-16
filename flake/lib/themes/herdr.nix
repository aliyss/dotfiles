{
  # ─── herdr theme generator ───────────────────────────────────────
  # Produces a [theme] TOML block for herdr's config.toml.
  # Uses "terminal" as base (inherits from foot's oxocarbon ANSI colors)
  # then overrides UI chrome tokens with the oxocarbon palette.

  theme,
  ...
}: let
  s = theme.semantic;
  p = theme.palette;
in ''
  [theme]
  name = "terminal"

  [theme.custom]
  panel_bg    = "${s.herdrPanelBg}"
  surface0    = "${s.herdrSurface0}"
  surface1    = "${p.surface1}"
  surface_dim = "${p.surface0}"
  overlay0    = "${p.overlay0}"
  overlay1    = "${p.overlay1}"
  text        = "${p.text}"
  subtext0    = "${p.subtext0}"
  accent      = "${s.primary}"
  mauve       = "${p.mauve}"
  green       = "${p.green}"
  yellow      = "${p.peach}"
  red         = "${p.red}"
  blue        = "${p.blue}"
  teal        = "${p.teal}"
  peach       = "${p.peach}"
''
