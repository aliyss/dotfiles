{
  # ─── fzf theme generator ─────────────────────────────────────────
  # Returns an attribute set for programs.fzf.colors.

  theme,
  ...
}: let
  p = theme.palette;
in {
  fg = "${p.text}";
  bg = "-1";
  hl = "${p.blue}";
  "fg+" = "${p.text}";
  "bg+" = "${p.surface0}";
  "hl+" = "${p.blue}";
  info = "${p.mauve}";
  prompt = "${p.teal}";
  pointer = "${p.pink}";
  marker = "${p.pink}";
  spinner = "${p.teal}";
  header = "${p.blue}";
}
