{
  # ─── hyprlock theme generator ────────────────────────────────────
  # Produces a fancy hyprlock.conf matching the oxocarbon palette.

  theme,
  ...
}: let
  p = theme.palette;
  # Helper to strip # for hyprlock colors if needed, but hyprlock supports hex
in ''
  general {
      hide_cursor = true
      immediate_render = true
  }

  background {
      monitor =
      path = screenshot
      color = rgba(0, 0, 0, 1.0)
      blur_passes = 2
      blur_size = 4
      noise = 0.0117
      contrast = 0.8916
      brightness = 0.7
      vibrancy = 0.1696
      # Fix for black screen race condition in some versions
      no_fade_in = true
      no_fade_out = true
  }

  # TIME
  label {
      monitor =
      text = $TIME
      color = ${p.text}
      font_size = 80
      font_family = JetBrainsMono Nerd Font Thin
      position = 0, 120
      halign = center
      valign = center
  }

  # DATE
  label {
      monitor =
      text = cmd[update:43200000] echo "$(date +"%A, %d %B")"
      color = ${p.blue}
      font_size = 14
      font_family = JetBrainsMono Nerd Font
      position = 0, 60
      halign = center
      valign = center
  }

  # USER INFO PILL (Modern, high contrast)
  label {
      monitor =
      text =   $USER  |  󰍛  $CPU  |  󰑭  $MEM
      color = rgb(${builtins.substring 1 6 p.text})
      font_size = 11
      font_family = JetBrainsMono Nerd Font Bold
      position = 0, -20
      halign = center
      valign = center
      background_color = rgba(255, 255, 255, 0.1)
      padding = 10
  }

  # INPUT FIELD (Squared, high contrast)
  input-field {
      monitor =
      size = 400, 45
      outline_thickness = 2
      dots_size = 0.2
      dots_spacing = 0.2
      dots_center = true
      outer_color = rgb(${builtins.substring 1 6 p.blue})
      inner_color = rgba(255, 255, 255, 0.1)
      font_color = rgb(${builtins.substring 1 6 p.text})
      fade_on_empty = true
      placeholder_text = <span foreground="##${builtins.substring 1 6 p.text}">ENTER PASSWORD</span>
      hide_input = false
      check_color = rgb(${builtins.substring 1 6 p.teal})
      fail_color = rgb(${builtins.substring 1 6 p.red})
      capslock_color = rgb(${builtins.substring 1 6 p.yellow})
      rounding = 0
      position = 0, -80
      halign = center
      valign = center
  }
''
