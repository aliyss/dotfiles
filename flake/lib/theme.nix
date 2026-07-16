rec {
  # ─── Oxocarbon (IBM Carbon) palette ──────────────────────────────
  # Derived from nyoom-engineering/oxocarbon.nvim
  # "centered around a vibrant set of blues, combined with an industrial set of grays"

  palette = {
    # UI surfaces (dark)
    base      = "#161616";
    mantle    = "#262626";
    crust     = "#161616";
    surface0  = "#2a2a2a";
    surface1  = "#404040";
    surface2  = "#5c5c5c";
    overlay0  = "#6c6c6c";
    overlay1  = "#8a8a8a";
    overlay2  = "#a8a8a8";

    # Text
    text      = "#d0d0d0";
    subtext0  = "#d0d0d0";
    subtext1  = "#f0f0f0";

    # oxocarbon accent colors (base07-base15)
    teal      = "#08bdba";
    sky       = "#3ddbd9";
    blue      = "#78a9ff";
    sapphire  = "#33b1ff";
    red       = "#ee5396";
    pink      = "#ff7eb6";
    green     = "#42be65";
    mauve     = "#be95ff";
    peach     = "#82cfff";
    yellow    = "#82cfff";

    # Aliases for catppuccin compat (mapped to closest oxocarbon)
    maroon    = "#ee5396";
    flamingo  = "#ff7eb6";
    rosewater = "#ff7eb6";
    lavender  = "#be95ff";

    # Light variant
    base-light      = "#ffffff";
    mantle-light    = "#f0f0f0";
    crust-light     = "#e0e0e0";
    surface0-light  = "#d0d0d0";
    surface1-light  = "#c0c0c0";
    surface2-light  = "#b0b0b0";
    overlay0-light  = "#a0a0a0";
    overlay1-light  = "#909090";
    overlay2-light  = "#808080";

    text-light      = "#161616";
    subtext0-light  = "#262626";
    subtext1-light  = "#404040";

    teal-light      = "#08bdba";
    sky-light       = "#3ddbd9";
    blue-light      = "#78a9ff";
    sapphire-light  = "#33b1ff";
    red-light       = "#ee5396";
    pink-light      = "#ff7eb6";
    green-light     = "#42be65";
    mauve-light     = "#be95ff";
    peach-light     = "#82cfff";
    yellow-light    = "#82cfff";
    maroon-light    = "#ee5396";
    flamingo-light  = "#ff7eb6";
    rosewater-light = "#ff7eb6";
    lavender-light  = "#be95ff";
  };

  # ─── Semantic token mappings ─────────────────────────────────────
  # Mapped to match oxocarbon's actual usage frequency:
  #   blue #78a9ff >> cyan #3ddbd9 ≈ pink #ee5396 ≈ purple #be95ff
  #   >> teal #08bdba ≈ light blue #82cfff >> green #42be65

  semantic = rec {
    # UI
    primary   = palette.blue;     # blue is oxocarbon's dominant accent
    secondary = palette.sky;      # cyan secondary
    accent    = palette.teal;     # teal for tertiary accent

    error     = palette.red;
    warning   = palette.mauve;    # oxocarbon uses purple for warnings
    success   = palette.teal;     # oxocarbon uses teal for diffs/success
    info      = palette.blue;

    text         = palette.text;
    textMuted    = palette.overlay0;
    textSubtle   = palette.surface2;

    background         = "none";
    backgroundPanel    = "none";
    backgroundElement  = "none";
    backgroundHover    = palette.surface0;

    border       = palette.surface0;
    borderActive = palette.surface1;
    borderSubtle = palette.surface0;

    # Diff
    diffAdded             = palette.teal;     # matches oxocarbon DiffAdded = base07
    diffRemoved           = palette.red;      # matches oxocarbon DiffRemoved = base10
    diffContext           = palette.overlay0;
    diffHunkHeader        = palette.overlay1;
    diffHighlightAdded    = palette.teal;
    diffHighlightRemoved  = palette.red;
    diffAddedBg           = "none";
    diffRemovedBg         = "none";
    diffContextBg         = "none";
    diffLineNumber        = palette.surface2;
    diffAddedLineNumberBg = "none";
    diffRemovedLineNumberBg = "none";

    # Markdown
    markdownText           = palette.text;
    markdownHeading        = palette.red;      # oxocarbon: markdownH1 = base10
    markdownLink           = palette.blue;
    markdownLinkText       = palette.mauve;    # oxocarbon: markdownUrl = base14
    markdownCode           = palette.green;
    markdownBlockQuote     = palette.overlay0;
    markdownEmph           = palette.red;
    markdownStrong         = palette.text;
    markdownHorizontalRule = palette.overlay0;
    markdownListItem       = palette.sky;      # oxocarbon: markdownListMarker = base08
    markdownListEnumeration = palette.sky;
    markdownImage          = palette.blue;
    markdownImageText      = palette.mauve;
    markdownCodeBlock      = palette.text;

    # Syntax (mirroring oxocarbon's actual highlight assignments)
    syntaxComment      = palette.surface2;    # base03
    syntaxKeyword      = palette.blue;        # base09 — oxocarbon's most-used color
    syntaxFunction     = palette.pink;        # base12 — oxocarbon @function
    syntaxVariable     = palette.text;        # base04 — oxocarbon uses text color
    syntaxString       = palette.mauve;       # base14 — oxocarbon String
    syntaxNumber       = palette.peach;       # base15 — oxocarbon Number
    syntaxType         = palette.blue;        # base09
    syntaxOperator     = palette.blue;        # base09
    syntaxPunctuation  = palette.sky;         # base08

    # Neovim extras
    neovimMarkviewHeading1 = { bg = palette.surface0; fg = palette.red; };
    neovimMarkviewHeading2 = { bg = palette.surface0; fg = palette.peach; };
    neovimMarkviewHeading3 = { bg = palette.surface0; fg = palette.blue; };
    neovimMarkviewHeading4 = { bg = palette.surface0; fg = palette.teal; };
    neovimMarkviewHeading5 = { bg = palette.surface0; fg = palette.sapphire; };
    neovimMarkviewHeading6 = { bg = palette.surface0; fg = palette.mauve; };

    neovimLspInlayHint  = palette.surface2;
    neovimModesCopy     = palette.blue;
    neovimModesDelete   = palette.red;
    neovimModesInsert   = palette.teal;
    neovimModesVisual   = palette.mauve;

    herdrPanelBg  = "reset";
    herdrSurface0 = "reset";
  };

  # ─── Light variant ───────────────────────────────────────────────
  semanticLight = {
    primary   = palette.blue-light;
    secondary = palette.sky-light;
    accent    = palette.teal-light;

    error     = palette.red-light;
    warning   = palette.mauve-light;
    success   = palette.teal-light;
    info      = palette.blue-light;

    text         = palette.text-light;
    textMuted    = palette.overlay0-light;
    textSubtle   = palette.surface2-light;

    background         = palette.base-light;
    backgroundPanel    = palette.mantle-light;
    backgroundElement  = palette.crust-light;
    backgroundHover    = palette.surface0-light;

    border       = palette.surface0-light;
    borderActive = palette.surface1-light;
    borderSubtle = palette.surface0-light;

    diffAdded             = palette.teal-light;
    diffRemoved           = palette.red-light;
    diffContext           = palette.overlay0-light;
    diffHunkHeader        = palette.overlay1-light;
    diffHighlightAdded    = palette.teal-light;
    diffHighlightRemoved  = palette.red-light;
    diffAddedBg           = "none";
    diffRemovedBg         = "none";
    diffContextBg         = "none";
    diffLineNumber        = palette.surface2-light;
    diffAddedLineNumberBg = "none";
    diffRemovedLineNumberBg = "none";

    markdownText           = palette.text-light;
    markdownHeading        = palette.red-light;
    markdownLink           = palette.blue-light;
    markdownLinkText       = palette.mauve-light;
    markdownCode           = palette.green-light;
    markdownBlockQuote     = palette.overlay0-light;
    markdownEmph           = palette.red-light;
    markdownStrong         = palette.text-light;
    markdownHorizontalRule = palette.overlay0-light;
    markdownListItem       = palette.sky-light;
    markdownListEnumeration = palette.sky-light;
    markdownImage          = palette.blue-light;
    markdownImageText      = palette.mauve-light;
    markdownCodeBlock      = palette.text-light;

    syntaxComment      = palette.surface2-light;
    syntaxKeyword      = palette.blue-light;
    syntaxFunction     = palette.pink-light;
    syntaxVariable     = palette.text-light;
    syntaxString       = palette.mauve-light;
    syntaxNumber       = palette.peach-light;
    syntaxType         = palette.blue-light;
    syntaxOperator     = palette.blue-light;
    syntaxPunctuation  = palette.sky-light;
  };
}
