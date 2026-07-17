{theme}: let
  p = theme.palette;
in {
  chrome = ''
    @namespace html url("http://www.w3.org/1999/xhtml");

    #TabsToolbar {
      visibility: collapse;
    }

    /* transparency */
    :root,
    #main-window,
    #browser,
    #tabbrowser-tabpanels,
    #tabbrowser-tabpanels-container,
    toolbox,
    .browserStack,
    browser[type="content-primary"],
    browser,
    #nav-bar,
    #PersonalToolbar,
    #navigator-toolbox {
      background-color: transparent !important;
      background: transparent !important;
      -moz-appearance: none !important;
    }

    *:not(
      i,
      span,
      [class*="icon"],
      [class*="fa-"],
      .material-icons
    ) {
      font-family: 'JetBrains Mono' !important;
    }

    :root {
      --tabpanel-background-color: transparent !important;
      --toolbar-bgcolor: transparent !important;
      --chrome-content-separator-color: transparent !important;
      --toolbar-field-focus-background-color: rgba(0, 0, 0, 0.5) !important;
      --arrowpanel-background: rgba(0, 0, 0, 0.9) !important;
      --lwt-accent-color: transparent !important;
      --lwt-selected-tab-background-color: transparent !important;
      --toolbar-field-background-color: rgba(0, 0, 0, 0.3) !important;
      --urlbar-box-background-color: rgba(0, 0, 0, 0.3) !important;
      --urlbar-icon-fill-opacity: 0.72 !important;
    }

    html|body {
      background-color: rgba(0, 0, 0, 0.9) !important;
      font-family: "JetBrains Mono" !important;
    }

    .urlbar-background, #searchbar {
      background-color: black !important;
      border-radius: 0 !important;
    }

    #main-window {
      /* Oxocarbon Palette */
      --oxocarbon-bg: #000000;
      --oxocarbon-fg: ${p.text};
      --oxocarbon-blue: ${p.blue};
      --oxocarbon-purple: ${p.mauve};
      --oxocarbon-green: ${p.green};
      --oxocarbon-gray: ${p.surface2};
      --oxocarbon-surface: ${p.surface0};
      --oxocarbon-red: ${p.red};
      --oxocarbon-pink: ${p.pink};
      --oxocarbon-teal: ${p.teal};
      --oxocarbon-orange: ${p.peach};

      /* Transparent & Oxocarbon Overrides */
      --background-color-box: transparent !important;
      --background-color-canvas: transparent !important;
      --panel-background-color: rgba(0, 0, 0, 0.8) !important;
      --toolbar-background-color: transparent !important;
      --toolbox-background-color: transparent !important;
      --sidebar-background-color: transparent !important;
      --tabpanel-background-color: transparent !important;
      --text-color: var(--oxocarbon-fg) !important;
      --toolbar-text-color: var(--oxocarbon-fg) !important;
      --panel-text-color: var(--oxocarbon-fg) !important;
      --sidebar-text-color: var(--oxocarbon-fg) !important;
      --color-accent-primary: var(--oxocarbon-blue) !important;
      --button-background-color-primary: var(--oxocarbon-blue) !important;
      --border-color: rgba(255, 255, 255, 0.1) !important;

      /* Button Overrides */
      --button-background-color: rgba(255, 255, 255, 0.05) !important;
      --button-background-color-hover: rgba(255, 255, 255, 0.1) !important;
      --button-background-color-active: rgba(255, 255, 255, 0.15) !important;
      --button-text-color: var(--oxocarbon-fg) !important;
      --button-text-color-hover: var(--oxocarbon-fg) !important;
      --button-text-color-active: var(--oxocarbon-fg) !important;
      --button-border-color: rgba(255, 255, 255, 0.1) !important;
      --button-background-color-ghost-hover: rgba(255, 255, 255, 0.08) !important;
      --button-background-color-ghost-active: rgba(255, 255, 255, 0.12) !important;

      /* Panel Overrides */
      --panel-background-color: rgba(0, 0, 0, 0.85) !important;
      --panel-text-color: var(--oxocarbon-fg) !important;
      --panel-border-color: rgba(255, 255, 255, 0.1) !important;
      --panel-header-info-icon-bgcolor: var(--oxocarbon-blue) !important;
      --panel-banner-item-hover-bgcolor: rgba(255, 255, 255, 0.1) !important;
      --panel-menuitem-hover-background-color: rgba(255, 255, 255, 0.1) !important;

      /* Sidebar Overrides */
      --sidebar-background-color: transparent !important;
      --sidebar-text-color: var(--oxocarbon-fg) !important;
      --sidebar-border-color: rgba(255, 255, 255, 0.1) !important;

      /* Tab Overrides */
      --tab-background-color-hover: rgba(255, 255, 255, 0.05) !important;
      --tab-background-color-selected: rgba(255, 255, 255, 0.1) !important;
      --tab-selected-textcolor: var(--oxocarbon-blue) !important;
      --tab-group-color-blue: var(--oxocarbon-blue) !important;
      --tab-group-color-red: var(--oxocarbon-red) !important;
      --tab-group-color-green: var(--oxocarbon-green) !important;
      --tab-group-color-orange: var(--oxocarbon-orange) !important;
      --tab-group-color-purple: var(--oxocarbon-purple) !important;

      /* Other Color Overrides */
      --badge-background-color: var(--oxocarbon-surface) !important;
      --checkbox-checked-background-color: var(--oxocarbon-blue) !important;
      --checkbox-checked-border-color: var(--oxocarbon-blue) !important;
      --download-progress-fill-color: var(--oxocarbon-blue) !important;
      --focus-outline-color: var(--oxocarbon-blue) !important;
      --icon-color: var(--oxocarbon-fg) !important;
      --input-bgcolor: rgba(255, 255, 255, 0.05) !important;
      --input-color: var(--oxocarbon-fg) !important;
      --link-color: var(--oxocarbon-blue) !important;
      --toolbarbutton-icon-fill: var(--oxocarbon-fg) !important;
      --toolbar-field-background-color: rgba(0, 0, 0, 0.3) !important;
      --toolbar-field-text-color: var(--oxocarbon-fg) !important;
      --urlbar-box-background-color: rgba(0, 0, 0, 0.3) !important;

      /* Card Overrides */
      --card-background-color: rgba(255, 255, 255, 0.03) !important;
      --card-border-color: rgba(255, 255, 255, 0.1) !important;

      /* Functional Color Mappings */
      --background-color-box-info: rgba(120, 169, 255, 0.1) !important;
      --background-color-critical: rgba(238, 83, 150, 0.1) !important;
      --background-color-information: rgba(120, 169, 255, 0.1) !important;
      --background-color-success: rgba(66, 190, 101, 0.1) !important;
      --background-color-warning: rgba(130, 207, 255, 0.1) !important;
      --background-color-list-item-hover: rgba(255, 255, 255, 0.1) !important;
      --background-color-overlay: rgba(0, 0, 0, 0.5) !important;

      --badge-background-color-filled: var(--oxocarbon-blue) !important;
      --badge-text-color-filled: var(--oxocarbon-bg) !important;

      --border-color-error: var(--oxocarbon-red) !important;
      --border-color-selected: var(--oxocarbon-blue) !important;

      --button-background-color: rgba(255, 255, 255, 0.05) !important;
      --button-background-color-hover: rgba(255, 255, 255, 0.1) !important;
      --button-background-color-active: rgba(255, 255, 255, 0.15) !important;
      --button-background-color-destructive: var(--oxocarbon-red) !important;

      --input-bgcolor: rgba(255, 255, 255, 0.05) !important;
      --input-color: var(--oxocarbon-fg) !important;
      --input-border-color: rgba(255, 255, 255, 0.1) !important;

      --link-color: var(--oxocarbon-blue) !important;
      --link-color-active: var(--oxocarbon-purple) !important;
      --link-color-hover: var(--oxocarbon-teal) !important;

      --panel-background-color-dimmed: rgba(255, 255, 255, 0.05) !important;
      --panel-separator-color: rgba(255, 255, 255, 0.1) !important;

      --tab-background-color-hover: rgba(255, 255, 255, 0.05) !important;
      --tab-background-color-selected: rgba(255, 255, 255, 0.1) !important;
      --tab-selected-textcolor: var(--oxocarbon-blue) !important;

      --toolbarbutton-background-color-hover: rgba(255, 255, 255, 0.05) !important;
      --toolbarbutton-background-color-active: rgba(255, 255, 255, 0.1) !important;
      --toolbarbutton-icon-fill: var(--oxocarbon-fg) !important;

      --urlbar-box-background-color: rgba(0, 0, 0, 0.3) !important;
      --urlbarview-background-color-hover: rgba(255, 255, 255, 0.05) !important;
      --urlbarview-background-color-selected: rgba(255, 255, 255, 0.1) !important;

      --panel-separator-zap-gradient: linear-gradient(90deg, ${p.mauve}, ${p.pink}, ${p.peach}) !important;

      /* Literal Color Definitions */
      --color-blue-0: var(--oxocarbon-blue) !important;
      --color-blue-10: var(--oxocarbon-blue) !important;
      --color-blue-20: var(--oxocarbon-blue) !important;
      --color-blue-30: var(--oxocarbon-blue) !important;
      --color-blue-40: var(--oxocarbon-blue) !important;
      --color-blue-50: var(--oxocarbon-blue) !important;
      --color-blue-60: var(--oxocarbon-blue) !important;
      --color-blue-70: var(--oxocarbon-blue) !important;
      --color-blue-80: var(--oxocarbon-blue) !important;
      --color-blue-90: var(--oxocarbon-blue) !important;
      --color-blue-100: var(--oxocarbon-blue) !important;
      --color-blue-110: var(--oxocarbon-blue) !important;

      --color-red-0: var(--oxocarbon-red) !important;
      --color-red-10: var(--oxocarbon-red) !important;
      --color-red-20: var(--oxocarbon-red) !important;
      --color-red-30: var(--oxocarbon-red) !important;
      --color-red-40: var(--oxocarbon-red) !important;
      --color-red-50: var(--oxocarbon-red) !important;
      --color-red-60: var(--oxocarbon-red) !important;
      --color-red-70: var(--oxocarbon-red) !important;
      --color-red-80: var(--oxocarbon-red) !important;
      --color-red-90: var(--oxocarbon-red) !important;
      --color-red-100: var(--oxocarbon-red) !important;
      --color-red-110: var(--oxocarbon-red) !important;

      --color-green-0: var(--oxocarbon-green) !important;
      --color-green-10: var(--oxocarbon-green) !important;
      --color-green-20: var(--oxocarbon-green) !important;
      --color-green-30: var(--oxocarbon-green) !important;
      --color-green-40: var(--oxocarbon-green) !important;
      --color-green-50: var(--oxocarbon-green) !important;
      --color-green-60: var(--oxocarbon-green) !important;
      --color-green-70: var(--oxocarbon-green) !important;
      --color-green-80: var(--oxocarbon-green) !important;
      --color-green-90: var(--oxocarbon-green) !important;
      --color-green-100: var(--oxocarbon-green) !important;
      --color-green-110: var(--oxocarbon-green) !important;

      --color-orange-0: var(--oxocarbon-orange) !important;
      --color-orange-10: var(--oxocarbon-orange) !important;
      --color-orange-20: var(--oxocarbon-orange) !important;
      --color-orange-30: var(--oxocarbon-orange) !important;
      --color-orange-40: var(--oxocarbon-orange) !important;
      --color-orange-50: var(--oxocarbon-orange) !important;
      --color-orange-60: var(--oxocarbon-orange) !important;
      --color-orange-70: var(--oxocarbon-orange) !important;
      --color-orange-80: var(--oxocarbon-orange) !important;
      --color-orange-90: var(--oxocarbon-orange) !important;
      --color-orange-100: var(--oxocarbon-orange) !important;
      --color-orange-110: var(--oxocarbon-orange) !important;

      --color-purple-0: var(--oxocarbon-purple) !important;
      --color-purple-10: var(--oxocarbon-purple) !important;
      --color-purple-20: var(--oxocarbon-purple) !important;
      --color-purple-30: var(--oxocarbon-purple) !important;
      --color-purple-40: var(--oxocarbon-purple) !important;
      --color-purple-50: var(--oxocarbon-purple) !important;
      --color-purple-60: var(--oxocarbon-purple) !important;
      --color-purple-70: var(--oxocarbon-purple) !important;
      --color-purple-80: var(--oxocarbon-purple) !important;
      --color-purple-90: var(--oxocarbon-purple) !important;
      --color-purple-100: var(--oxocarbon-purple) !important;
      --color-purple-110: var(--oxocarbon-purple) !important;

      --color-gray-05: var(--oxocarbon-fg) !important;
      --color-gray-10: var(--oxocarbon-fg) !important;
      --color-gray-20: var(--oxocarbon-gray) !important;
      --color-gray-30: var(--oxocarbon-gray) !important;
      --color-gray-40: var(--oxocarbon-gray) !important;
      --color-gray-50: var(--oxocarbon-gray) !important;
      --color-gray-60: var(--oxocarbon-gray) !important;
      --color-gray-70: var(--oxocarbon-gray) !important;
      --color-gray-80: var(--oxocarbon-surface) !important;
      --color-gray-90: var(--oxocarbon-bg) !important;
      --color-gray-100: var(--oxocarbon-bg) !important;
    }

  '';

  content = ''

    @-moz-document url-prefix(about:home), url-prefix(about:newtab), url-prefix(about:blank), url-prefix(about:config) {
      #root,
      body,
      html {
        background: transparent !important;
        background-color: transparent !important;
        font-family: "JetBrains Mono" !important;
      }
    }

    html,
    body {
      background: transparent !important;
      background-color: transparent !important;
    }

    *:not(
      i,
      span,
      [class*="icon"],
      [class*="fa-"],
      .material-icons
    ) {
      font-family: 'JetBrains Mono' !important;
    }


    :root {
      --newtab-background-color: transparent !important;
      --background-color-canvas: transparent !important;
      --color-gray-80: transparent !important;

      /* Oxocarbon Palette */
      --oxocarbon-bg: #000000;
      --oxocarbon-fg: ${p.text};
      --oxocarbon-blue: ${p.blue};
      --oxocarbon-purple: ${p.mauve};
      --oxocarbon-green: ${p.green};
      --oxocarbon-gray: ${p.surface2};
      --oxocarbon-surface: ${p.surface0};
      --oxocarbon-red: ${p.red};
      --oxocarbon-pink: ${p.pink};
      --oxocarbon-teal: ${p.teal};
      --oxocarbon-orange: ${p.peach};

      /* Transparent & Oxocarbon Overrides */
      --background-color-box: transparent !important;
      --background-color-canvas: transparent !important;
      --panel-background-color: rgba(0, 0, 0, 0.8) !important;
      --text-color: var(--oxocarbon-fg) !important;
      --color-accent-primary: var(--oxocarbon-blue) !important;
      --button-background-color-primary: var(--oxocarbon-blue) !important;
      --border-color: rgba(255, 255, 255, 0.1) !important;

      /* Functional Color Mappings */
      --link-color: var(--oxocarbon-blue) !important;
      --link-color-active: var(--oxocarbon-purple) !important;
      --link-color-hover: var(--oxocarbon-teal) !important;
    }

  '';
}
