{ config, lib, pkgs, ... }:
let
  # ── Central theme ────────────────────────────────────────────────
  theme = import ../../lib/theme.nix;

  # ── Tool-specific renderers ──────────────────────────────────────
  mkOpenCodeTheme = import ../../lib/themes/opencode.nix {
    inherit theme;
    palette = theme.palette;
  };

  mkHerdrTheme = import ../../lib/themes/herdr.nix {
    inherit theme;
  };

  mkNeovimHighlights = import ../../lib/themes/neovim.nix {
    inherit theme;
  };

  mkFootTheme = import ../../lib/themes/foot.nix {
    inherit theme lib;
  };

  mkFzfTheme = import ../../lib/themes/fzf.nix {
    inherit theme;
  };

  mkBtopTheme = import ../../lib/themes/btop.nix {
    inherit theme;
  };

  mkYaziTheme = import ../../lib/themes/yazi.nix {
    inherit theme;
  };

  mkMakoTheme = import ../../lib/themes/mako.nix {
    inherit theme;
  };

  mkHyprlockTheme = import ../../lib/themes/hyprlock.nix {
    inherit theme;
  };

  mkYouTubeMusicTheme = import ../../lib/themes/youtube-music.nix {
    inherit theme;
  };

  mkFirefoxTheme = import ../../lib/themes/firefox.nix {
    inherit theme;
  };

  mkTridactylTheme = import ../../lib/themes/tridactyl.nix {
    inherit theme;
  };

  mkTermuxTheme = import ../../lib/themes/termux.nix {
    inherit theme lib;
  };

  mkPhoneFishConfig = import ../../lib/themes/phone-fish.nix {
    inherit theme lib;
  };

  openCodeThemeJSON = builtins.toJSON (mkOpenCodeTheme // {
    "$schema" = "https://opencode.ai/theme.json";
  });
in {
  options.aliyss.theme = lib.mkOption {
    type = lib.types.attrs;
    default = theme;
    defaultText = lib.literalExpression "theme.nix";
    description = "Central oxocarbon palette + semantic tokens. Every tool derives from this.";
  };

  options.aliyss.themeGenerators = lib.mkOption {
    type = lib.types.attrs;
    default = {
      opencode = mkOpenCodeTheme;
      herdr    = mkHerdrTheme;
      neovim   = mkNeovimHighlights;
      foot     = mkFootTheme;
      fzf      = mkFzfTheme;
      btop     = mkBtopTheme;
      yazi     = mkYaziTheme;
      mako     = mkMakoTheme;
      hyprlock = mkHyprlockTheme;
      youtube-music = mkYouTubeMusicTheme;
      firefox = mkFirefoxTheme;
      tridactyl = mkTridactylTheme;
      termux = mkTermuxTheme;
    };
    internal = true;
  };

  options.aliyss.phone.enable = lib.mkEnableOption ''
    Termux phone targets (`.termux/colors.properties` + `.config/fish/config.fish`)
    written directly on the phone, derived from the same central theme.
  '';

  config = {
    # ── Generated opencode theme file ──────────────────────────────
    xdg.configFile."opencode/themes/catppuccin.json" = {
      text = openCodeThemeJSON;
    };

    # ── Termux phone targets (activated via home-manager on the phone) ──
    # Declared via home.file (home-manager builds + tracks the content) AND
    # copied to real files on activation (writePhoneFiles below). The phone's
    # /nix is proot-faked and invisible to native Termux processes, so a store
    # symlink would dangle for them; a real file copy is required.
    home.file.".termux/colors.properties" = lib.mkIf config.aliyss.phone.enable {
      text = mkTermuxTheme;
      force = true; # Termux ships / sets these by default; we own them
    };
    home.file.".config/fish/config.fish" = lib.mkIf config.aliyss.phone.enable {
      text = mkPhoneFishConfig;
      force = true;
    };

    home.activation.writePhoneFiles = lib.mkIf config.aliyss.phone.enable (lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      # Materialize the generated config as real files so native Termux
      # processes (Termux terminal, fish, opencode) can read them outside proot.
      # rm first: linkGeneration leaves store symlinks here, which native apps
      # can't follow and which are read-only (EACCES if written through).
      # opencode.jsonc + tui.json are NOT written here — they are tracked repo
      # files (the theme lives in the tracked tui.json); only the generated
      # theme file is materialized.
      mkdir -p "$HOME/.termux" "$HOME/.config/fish" "$HOME/.config/opencode/themes"
      rm -f "$HOME/.termux/colors.properties" "$HOME/.config/fish/config.fish" \
            "$HOME/.config/opencode/themes/catppuccin.json" \
            "$HOME/.hushlogin"
      cp ${pkgs.writeText "colors.properties" mkTermuxTheme} "$HOME/.termux/colors.properties"
      cp ${pkgs.writeText "fish-config.fish" mkPhoneFishConfig} "$HOME/.config/fish/config.fish"
      cp ${pkgs.writeText "opencode-theme.json" openCodeThemeJSON} "$HOME/.config/opencode/themes/catppuccin.json"
      # store files are 444; give the real copies normal perms
      chmod 644 "$HOME/.termux/colors.properties" "$HOME/.config/fish/config.fish" \
                "$HOME/.config/opencode/themes/catppuccin.json"
      : > "$HOME/.hushlogin"
    '');
  };
}