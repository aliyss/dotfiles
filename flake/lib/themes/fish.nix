{
  # ─── Fish shell theme generator ──────────────────────────────────
  # Produces a fish .theme file matching the oxocarbon palette.

  theme,
  ...
}: let
  p = theme.palette;
  s = theme.semantic;
in ''
  # oxocarbon
  # Generated from flake/lib/theme.nix
  fish_color_normal        ${p.text}
  fish_color_command       ${p.blue}
  fish_color_param         ${p.text}
  fish_color_error         ${p.red}
  fish_color_end           ${p.text}
  fish_color_option        ${p.blue}
  fish_color_operator      ${p.blue}
  fish_color_quote         ${p.mauve}
  fish_color_redirection   ${p.teal}
  fish_color_escape        ${p.peach}
  fish_color_selection     --background=${p.surface1}
  fish_color_search_match  --background=${p.surface0}
  fish_color_history_current ${p.teal}
  fish_color_autosuggestion ${p.surface2}
  fish_color_cancel        ${p.red}
  fish_color_valid_path    --underline
  fish_color_keyword       ${p.blue}
  fish_color_comment       ${p.surface2}
  fish_color_cwd           ${p.teal}
  fish_color_cwd_root      ${p.red}
  fish_color_user          ${p.peach}
  fish_color_host          ${p.blue}
  fish_color_host_remote   ${p.mauve}
  fish_color_status        ${p.red}
  fish_color_private_mode  ${p.mauve}
  fish_pager_color_progress ${p.blue}
  fish_pager_color_prefix  ${p.teal}
  fish_pager_color_completion ${p.text}
  fish_pager_color_description ${p.surface2}
  fish_pager_color_selected_background --background=${p.surface1}
''
