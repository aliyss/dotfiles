{ theme }:
let
  p = theme.palette;
in
''
  :root {
    /* Oxocarbon Colors */
    --bg: #000000;
    --currentline: ${p.surface0};
    --fg: ${p.text};
    --comment: ${p.overlay0};
    --cyan: ${p.sky};
    --green: ${p.green};
    --orange: ${p.peach};
    --pink: ${p.pink};
    --purple: ${p.mauve};
    --red: ${p.red};
    --yellow: ${p.yellow};
    --font: "JetBrains Mono";

    --tridactyl-fg: var(--fg);
    --tridactyl-bg: var(--bg);
    --tridactyl-url-fg: var(--pink);
    --tridactyl-url-bg: var(--bg);
    --tridactyl-highlight-box-bg: var(--currentline);
    --tridactyl-highlight-box-fg: var(--fg);
    --tridactyl-of-fg: var(--fg);
    --tridactyl-of-bg: var(--currentline);
    --tridactyl-cmdl-fg: var(--bg);
    --tridactyl-cmdl-font-family: var(--font);
    --tridactyl-cmplt-font-family: var(--font);
    --tridactyl-hintspan-font-family: var(--font);

    /* Hint character tags */
    --tridactyl-hintspan-fg: var(--bg) !important;
    --tridactyl-hintspan-bg: var(--green) !important;

    /* Element Highlights */
    --tridactyl-hint-active-fg: none;
    --tridactyl-hint-active-bg: none;
    --tridactyl-hint-active-outline: none;
    --tridactyl-hint-bg: none;
    --tridactyl-hint-outline: none;
  }

  #command-line-holder {
    order: 1;
    border: 2px solid var(--purple);
    background: var(--tridactyl-bg);
  }

  #tridactyl-input {
    padding: 1rem;
    color: var(--tridactyl-fg);
    width: 90%;
    font-size: 1.5rem;
    line-height: 1.5;
    background: var(--tridactyl-bg);
    padding-left: unset;
    padding: 1rem;
  }

  #completions table {
    font-size: 0.8rem;
    font-weight: 200;
    border-spacing: 0;
    table-layout: fixed;
    padding: 1rem;
    padding-top: 1rem;
    padding-bottom: 1rem;
  }

  #completions > div {
    max-height: calc(20 * var(--option-height));
    min-height: calc(10 * var(--option-height));
  }

  /* COMPLETIONS */

  #completions {
    --option-height: 1.4em;
    color: var(--tridactyl-fg);
    background: var(--tridactyl-bg);
    display: inline-block;
    font-size: unset;
    font-weight: 200;
    overflow: hidden;
    width: 100%;
    border-top: unset;
    order: 2;
  }

  /* Olie doesn't know how CSS inheritance works */
  #completions .HistoryCompletionSource {
    max-height: unset;
    min-height: unset;
  }

  #completions .HistoryCompletionSource table {
    width: 100%;
    font-size: 9pt;
    border-spacing: 0;
    table-layout: fixed;
  }

  /* redundancy 2: redundancy 2: more redundancy */
  #completions .BmarkCompletionSource {
    max-height: unset;
    min-height: unset;
  }

  #completions table tr td.prefix,
  #completions table tr td.privatewindow,
  #completions table tr td.container,
  #completions table tr td.icon {
    display: none;
  }

  #completions .BufferCompletionSource table {
    width: unset;
    font-size: unset;
    border-spacing: unset;
    table-layout: unset;
  }

  #completions table tr .title {
    width: 50%;
  }

  #completions table tr {
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  #completions .sectionHeader {
    background: unset;
    font-weight: bold;
    border-bottom: unset;
    padding: 1rem !important;
    padding-left: unset;
    padding-bottom: 0.2rem;
  }

  #cmdline_iframe {
    position: fixed !important;
    bottom: unset;
    top: 25% !important;
    left: 10% !important;
    z-index: 2147483647 !important;
    width: 80% !important;
    box-shadow: rgba(0, 0, 0, 0.5) 0px 0px 20px !important;
  }

  .TridactylStatusIndicator {
    position: fixed !important;
    bottom: 0 !important;
    background: var(--tridactyl-bg) !important;
    border: unset !important;
    border: 1px var(--purple) solid !important;
    font-size: 12pt !important;
    /*font-weight: 200 !important;*/
    padding: 0.8ex !important;
  }

  #completions .focused {
    background: var(--pink);
    color: var(--bg);
  }

  #completions .focused .url {
    background: var(--pink);
    color: var(--bg);
  }

  span.TridactylHint {
    border-radius: 0 !important;
  }

  * {
    font-family: "JetBrains Mono" !important;
  }
''
