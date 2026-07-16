{
  # ─── yazi theme generator ────────────────────────────────────────
  # Produces a yazi theme.toml matching the oxocarbon palette.

  theme,
  ...
}: let
  p = theme.palette;
in ''
  # oxocarbon yazi theme
  # Generated from flake/lib/theme.nix

  [app]
  overall = { bg = "reset" }

  [mgr]
  cwd = { fg = "${p.teal}" }
  hovered = { fg = "${p.base}", bg = "${p.blue}" }
  selected = { fg = "${p.base}", bg = "${p.pink}" }
  find_keyword = { fg = "${p.yellow}", italic = true }
  find_position = { fg = "${p.mauve}", italic = true }
  symlink_target = { fg = "${p.mauve}" }
  border_style = { fg = "${p.surface1}" }

  [status]
  separator_open  = " ["
  separator_close = "] "
  separator_style = { fg = "${p.surface2}" }

  # Mode
  mode_normal = { fg = "${p.base}", bg = "${p.blue}", bold = true }
  mode_select = { fg = "${p.base}", bg = "${p.pink}", bold = true }
  mode_unset  = { fg = "${p.base}", bg = "${p.mauve}", bold = true }

  # Progress
  progress_label  = { fg = "${p.text}", bold = true }
  progress_normal = { fg = "${p.blue}", bg = "${p.surface1}" }
  progress_error  = { fg = "${p.red}", bg = "${p.surface1}" }

  # Permissions
  perm_sep   = { fg = "${p.surface2}" }
  perm_type  = { fg = "${p.blue}" }
  perm_read  = { fg = "${p.yellow}" }
  perm_write = { fg = "${p.red}" }
  perm_exec  = { fg = "${p.green}" }

  [pick]
  border   = { fg = "${p.blue}" }
  active   = { fg = "${p.pink}", bold = true }
  inactive = { }

  [input]
  border   = { fg = "${p.blue}" }
  title    = { fg = "${p.text}" }
  value    = { fg = "${p.yellow}" }
  selected = { reversed = true }

  [cmp]
  border = { fg = "${p.blue}" }
  active = { bg = "${p.surface1}" }

  [tasks]
  border  = { fg = "${p.blue}" }
  title   = { fg = "${p.text}" }
  hovered = { underline = true }

  [which]
  mask            = { bg = "${p.surface0}" }
  cand            = { fg = "${p.teal}" }
  rest            = { fg = "${p.overlay1}" }
  desc            = { fg = "${p.pink}" }
  separator       = " ➜ "
  separator_style = { fg = "${p.surface2}" }

  [help]
  on      = { fg = "${p.teal}" }
  run     = { fg = "${p.pink}" }
  hovered = { bg = "${p.surface1}" }
  footer  = { fg = "${p.surface1}", bg = "${p.text}" }

  [filetype]
  rules = [
    # Images
    { mime = "image/*", fg = "${p.teal}" },
    # Videos
    { mime = "video/*", fg = "${p.yellow}" },
    { mime = "audio/*", fg = "${p.yellow}" },
    # Archives
    { mime = "application/zip", fg = "${p.pink}" },
    { mime = "application/x-tar", fg = "${p.pink}" },
    { mime = "application/x-bzip2", fg = "${p.pink}" },
    { mime = "application/x-7z-compressed", fg = "${p.pink}" },
    { mime = "application/x-rar", fg = "${p.pink}" },
    # Documents
    { mime = "application/pdf", fg = "${p.red}" },
    # Empty files
    { mime = "inode/empty", fg = "${p.red}" },
    # Directories
    { url = "*/", fg = "${p.blue}" },
    # Fallback
    { url = "*", fg = "${p.text}" }
  ]
''
