{
  theme,
  ...
}: let
  p = theme.palette;
  s = theme.semantic;
in {
  "$schema" = "https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json";
  name = "oxocarbon";
  vars = {
    # oxocarbon palette → pi vars
    cyan = p.sky; # #3ddbd9 (oxocarbon cyan)
    blue = p.blue; # #78a9ff
    green = p.green; # #42be65
    red = p.red; # #ee5396
    yellow = p.peach; # #82cfff (oxocarbon has no yellow, peach is closest)
    text = p.text; # #d0d0d0
    gray = p.overlay0; # #6c6c6c
    dimGray = p.surface1; # #404040
    darkGray = p.surface0; # #2a2a2a
    accent = p.teal; # #08bdba
    selectedBg = p.surface0; # #2a2a2a
    userMsgBg = p.mantle; # #262626
    toolPendingBg = p.surface0;
    toolSuccessBg = p.surface0;
    toolErrorBg = p.surface0;
    customMsgBg = p.surface0;
  };
  colors = {
    accent = "accent";
    border = "blue";
    borderAccent = "cyan";
    borderMuted = "darkGray";
    success = "green";
    error = "red";
    warning = "yellow";
    muted = "gray";
    dim = "dimGray";
    text = "text";
    thinkingText = "gray";

    selectedBg = "selectedBg";
    userMessageBg = "userMsgBg";
    userMessageText = "text";
    customMessageBg = "customMsgBg";
    customMessageText = "text";
    customMessageLabel = p.mauve; # #be95ff

    toolPendingBg = "toolPendingBg";
    toolSuccessBg = "toolSuccessBg";
    toolErrorBg = "toolErrorBg";
    toolTitle = "text";
    toolOutput = "gray";

    mdHeading = p.red; # like opencode
    mdLink = p.blue;
    mdLinkUrl = "dimGray";
    mdCode = "accent";
    mdCodeBlock = "green";
    mdCodeBlockBorder = "gray";
    mdQuote = "gray";
    mdQuoteBorder = "gray";
    mdHr = "gray";
    mdListBullet = "accent";

    toolDiffAdded = "green";
    toolDiffRemoved = "red";
    toolDiffContext = "gray";

    syntaxComment = p.surface2; # #5c5c5c
    syntaxKeyword = p.blue;
    syntaxFunction = p.pink; # #ff7eb6
    syntaxVariable = p.text;
    syntaxString = p.mauve; # #be95ff
    syntaxNumber = p.peach; # #82cfff
    syntaxType = p.blue;
    syntaxOperator = p.blue;
    syntaxPunctuation = p.sky;

    thinkingOff = "darkGray";
    thinkingMinimal = p.surface2;
    thinkingLow = p.sapphire; # #33b1ff
    thinkingMedium = p.blue;
    thinkingHigh = p.mauve;
    thinkingXhigh = p.pink;

    bashMode = "green";
  };
  export = {
    pageBg = p.base; # #161616
    cardBg = p.mantle;
    infoBg = p.surface0;
  };
}
