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
    inherit theme;
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
    };
    internal = true;
  };

  config = {
    # ── Generated opencode theme file ──────────────────────────────
    xdg.configFile."opencode/themes/catppuccin.json" = {
      text = openCodeThemeJSON;
    };
  };
}
