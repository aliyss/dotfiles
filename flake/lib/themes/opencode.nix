{
  # ─── opencode theme generator ────────────────────────────────────
  # Produces an attrset matching the opencode theme schema.

  theme,
  palette,
}: let
  # Build a { dark = "..."; light = "..."; } pair from a name or hex string.
  token = name: let
    dark =
      if palette ? ${name} then palette.${name}
      else if theme.semantic ? ${name} then theme.semantic.${name}
      else name;
    lightName = "${name}-light";
    light =
      if palette ? ${lightName} then palette.${lightName}
      else if theme.semanticLight ? ${name} then theme.semanticLight.${name}
      else name;
  in {
    dark = dark;
    light = light;
  };

  # Token that has no light variant (returns the same for both).
  mono = name: let
    v =
      if palette ? ${name} then palette.${name}
      else if theme.semantic ? ${name} then theme.semantic.${name}
      else name;
  in v;

  defs = builtins.mapAttrs (k: v: v) palette;
in {
  inherit defs;

  theme = {
    primary       = token "primary";
    secondary     = token "secondary";
    accent        = token "accent";
    error         = token "error";
    warning       = token "warning";
    success       = token "success";
    info          = token "info";
    text          = token "text";
    textMuted     = token "textMuted";
    background    = mono "background";
    backgroundPanel   = mono "backgroundPanel";
    backgroundElement = mono "backgroundElement";
    border        = token "border";
    borderActive  = token "borderActive";
    borderSubtle  = token "borderSubtle";

    diffAdded            = token "diffAdded";
    diffRemoved          = token "diffRemoved";
    diffContext          = token "diffContext";
    diffHunkHeader       = token "diffHunkHeader";
    diffHighlightAdded   = token "diffHighlightAdded";
    diffHighlightRemoved = token "diffHighlightRemoved";
    diffAddedBg          = mono "diffAddedBg";
    diffRemovedBg        = mono "diffRemovedBg";
    diffContextBg        = mono "diffContextBg";
    diffLineNumber       = token "diffLineNumber";
    diffAddedLineNumberBg = mono "diffAddedLineNumberBg";
    diffRemovedLineNumberBg = mono "diffRemovedLineNumberBg";

    markdownText           = token "markdownText";
    markdownHeading        = token "markdownHeading";
    markdownLink           = token "markdownLink";
    markdownLinkText       = token "markdownLinkText";
    markdownCode           = token "markdownCode";
    markdownBlockQuote     = token "markdownBlockQuote";
    markdownEmph           = token "markdownEmph";
    markdownStrong         = token "markdownStrong";
    markdownHorizontalRule = token "markdownHorizontalRule";
    markdownListItem       = token "markdownListItem";
    markdownListEnumeration = token "markdownListEnumeration";
    markdownImage          = token "markdownImage";
    markdownImageText      = token "markdownImageText";
    markdownCodeBlock      = token "markdownCodeBlock";

    syntaxComment     = token "syntaxComment";
    syntaxKeyword     = token "syntaxKeyword";
    syntaxFunction    = token "syntaxFunction";
    syntaxVariable    = token "syntaxVariable";
    syntaxString      = token "syntaxString";
    syntaxNumber      = token "syntaxNumber";
    syntaxType        = token "syntaxType";
    syntaxOperator    = token "syntaxOperator";
    syntaxPunctuation = token "syntaxPunctuation";
  };
}
