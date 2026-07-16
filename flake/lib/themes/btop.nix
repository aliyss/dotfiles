{
  # ─── btop theme generator ────────────────────────────────────────
  # Produces a btop .theme file matching the oxocarbon palette.

  theme,
  ...
}: let
  p = theme.palette;
in ''
  # oxocarbon btop theme
  # Generated from flake/lib/theme.nix

  theme[main_bg]=""
  theme[main_fg]="${p.text}"
  theme[title]="${p.text}"
  theme[hi_fg]="${p.blue}"
  theme[selected_bg]="${p.surface1}"
  theme[selected_fg]="${p.text}"
  theme[inactive_fg]="${p.surface2}"
  theme[graph_text]="${p.text}"
  theme[meter_bg]="${p.surface1}"
  theme[proc_misc]="${p.mauve}"
  theme[cpu_box]="${p.blue}"
  theme[mem_box]="${p.green}"
  theme[net_box]="${p.red}"
  theme[proc_box]="${p.sky}"
  theme[div_line]="${p.surface1}"

  theme[temp_start]="${p.blue}"
  theme[temp_mid]="${p.mauve}"
  theme[temp_end]="${p.red}"

  theme[cpu_start]="${p.blue}"
  theme[cpu_mid]="${p.sky}"
  theme[cpu_end]="${p.teal}"

  theme[free_start]="${p.pink}"
  theme[free_mid]="${p.mauve}"
  theme[free_end]="${p.red}"

  theme[cached_start]="${p.sky}"
  theme[cached_mid]="${p.blue}"
  theme[cached_end]="${p.mauve}"

  theme[available_start]="${p.peach}"
  theme[available_mid]="${p.yellow}"
  theme[available_end]="${p.pink}"

  theme[used_start]="${p.teal}"
  theme[used_mid]="${p.green}"
  theme[used_end]="${p.sky}"

  theme[download_start]="${p.blue}"
  theme[download_mid]="${p.green}"
  theme[download_end]="${p.sky}"

  theme[upload_start]="${p.mauve}"
  theme[upload_mid]="${p.pink}"
  theme[upload_end]="${p.red}"

  theme[process_start]="${p.teal}"
  theme[process_mid]="${p.blue}"
  theme[process_end]="${p.mauve}"
''
