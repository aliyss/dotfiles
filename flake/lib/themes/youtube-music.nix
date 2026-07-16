{ theme }:
let
  p = theme.palette;
in
''
html:not(.style-scope)
{
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

  /* Catppuccin mapping to Oxocarbon */
  --ctp-rosewater: var(--oxocarbon-pink);
  --ctp-flamingo: var(--oxocarbon-pink);
  --ctp-pink: var(--oxocarbon-pink);
  --ctp-mauve: var(--oxocarbon-purple);
  --ctp-red: var(--oxocarbon-red);
  --ctp-maroon: var(--oxocarbon-red);
  --ctp-peach: var(--oxocarbon-teal);
  --ctp-yellow: ${p.yellow};
  --ctp-green: var(--oxocarbon-green);
  --ctp-teal: var(--oxocarbon-teal);
  --ctp-sky: var(--oxocarbon-blue);
  --ctp-sapphire: var(--oxocarbon-blue);
  --ctp-blue: var(--oxocarbon-blue);
  --ctp-lavender: var(--oxocarbon-purple);
  
  --ctp-text: var(--oxocarbon-fg);
  --ctp-subtext1: ${p.overlay2};
  --ctp-subtext0: ${p.overlay1};
  --ctp-overlay2: ${p.overlay2};
  --ctp-overlay1: ${p.overlay1};
  --ctp-overlay0: ${p.overlay0};
  --ctp-surface2: ${p.surface2};
  --ctp-surface1: ${p.surface1};
  --ctp-surface0: ${p.surface0};
  --ctp-base: var(--oxocarbon-bg);
  --ctp-mantle: #000000;
  --ctp-crust: #000000;

  --ctp-accent: var(--oxocarbon-blue);

  /* YouTube Specific Mappings */
  --yt-spec-text-primary: var(--ctp-text) !important;
  --yt-spec-text-secondary: var(--ctp-subtext1) !important;
  --yt-spec-static-brand-red: var(--ctp-red) !important;
  --yt-spec-static-brand-white: var(--ctp-text) !important;
  --yt-spec-general-background-a: var(--ctp-base) !important;
  --yt-spec-general-background-b: var(--ctp-base) !important;
  --yt-spec-general-background-c: var(--ctp-base) !important;
  --yt-spec-error-indicator: var(--ctp-red) !important;
  --yt-spec-themed-blue: var(--oxocarbon-blue) !important;
  --yt-spec-themed-green: var(--oxocarbon-green) !important;
  --yt-spec-ad-indicator: var(--oxocarbon-teal) !important;
  --yt-spec-button-chip-background-hover: var(--ctp-surface1) !important;
  --yt-spec-touch-response: var(--ctp-surface2) !important;
  --yt-spec-paper-tab-ink: var(--oxocarbon-purple) !important;
  --yt-spec-filled-button-focus-outline: var(--oxocarbon-purple) !important;
  --yt-spec-call-to-action: var(--oxocarbon-blue) !important;
  --yt-spec-brand-background-solid: var(--ctp-base) !important;
  --yt-spec-brand-background-primary: var(--ctp-base) !important;
  --yt-spec-brand-background-secondary: var(--ctp-base) !important;
  --yt-spec-badge-chip-background: var(--ctp-surface0) !important;
  --yt-spec-verified-check-color: var(--oxocarbon-blue) !important;
}

/* GLOBAL OVERRIDES */
* :not(.material-icons)
{
  font-family: 'JetBrains Mono', monospace !important;
  scrollbar-width: none !important;
  border-radius: 0 !important;
}

yt-formatted-string, span, div, a, p {
    color: inherit;
}

body
{
  background: var(--ctp-base) !important;
  color: var(--ctp-text) !important;
}

/* Color Diversity in Icons */
yt-icon, .yt-icon, iron-icon {
    color: var(--ctp-subtext1) !important;
    fill: var(--ctp-subtext1) !important;
}

/* Home icon Blue */
ytmusic-guide-entry-renderer[active] yt-icon {
    color: var(--oxocarbon-blue) !important;
    fill: var(--oxocarbon-blue) !important;
}

/* Play/Pause Button Purple */
#play-pause-button yt-icon,
.play-pause-button yt-icon,
.ytmusic-play-button-renderer yt-icon {
    color: var(--oxocarbon-purple) !important;
    fill: var(--oxocarbon-purple) !important;
}

/* Like Button Red */
ytmusic-like-button-renderer[like-status="LIKE"] yt-icon,
.like-button[aria-pressed="true"] yt-icon,
tp-yt-paper-icon-button.ytmusic-like-button-renderer[aria-pressed="true"] {
    color: var(--oxocarbon-red) !important;
    fill: var(--oxocarbon-red) !important;
}

/* Navigation & Player Bar */
ytmusic-nav-bar, ytmusic-player-bar, #player-bar-background {
  background: var(--ctp-mantle) !important;
  border-top: 1px solid var(--oxocarbon-gray) !important;
  border-bottom: 1px solid var(--oxocarbon-gray) !important;
}

/* Progress Bar - Purple */
#progress-bar.ytmusic-player-bar {
  --paper-slider-active-color: var(--oxocarbon-purple) !important;
  --paper-slider-container-color: var(--oxocarbon-gray) !important;
  --paper-slider-knob-color: var(--oxocarbon-purple) !important;
}

/* Volume Bar - Green */
#volume-slider.paper-slider,
.volume-slider.ytmusic-player-bar {
  --paper-slider-active-color: var(--oxocarbon-green) !important;
  --paper-slider-knob-color: var(--oxocarbon-green) !important;
}

/* Search Box - Teal Focus */
ytmusic-search-box {
    --ytmusic-search-background: var(--ctp-surface0) !important;
    background-color: var(--ctp-surface0) !important;
}

ytmusic-search-box[opened] {
    border: 1px solid var(--oxocarbon-teal) !important;
}

/* Image styling */
img, .image, yt-img-shadow {
  filter: grayscale(100%) brightness(0.6) !important;
  transition: filter 0.3s ease;
}

img:hover, .image:hover, yt-img-shadow:hover {
  filter: none !important;
}

/* Hierarchy fixes */
.title, h1, h2, h3 {
    color: var(--ctp-text) !important;
}

.subtitle, .byline, .description, .time-info {
    color: var(--ctp-subtext1) !important;
}

/* Specific colorful accents */
a.yt-simple-endpoint.yt-formatted-string:hover,
.byline a:hover,
.subtitle a:hover {
    color: var(--oxocarbon-teal) !important;
    text-decoration: underline !important;
}

/* Selected Tab Underline - Purple */
#selectionBar.tp-yt-paper-tabs {
    border-bottom: 2px solid var(--oxocarbon-purple) !important;
}

/* Chips/Badges - Diverse Colors */
ytmusic-chip-cloud-chip-renderer[is-selected] a {
    background-color: var(--oxocarbon-blue) !important;
    color: var(--oxocarbon-bg) !important;
}

/* Artists in lists - Pink */
.byline.ytmusic-player-bar a {
    color: var(--oxocarbon-pink) !important;
}

/* Buttons in Menus */
ytmusic-menu-navigation-item-renderer:hover yt-icon {
    color: var(--oxocarbon-purple) !important;
}

/* Subscribe Button - Red */
ytmusic-subscribe-button-renderer {
    --ytmusic-subscribe-button-color: var(--oxocarbon-red) !important;
}

/* Mood/Genre chips - use variety */
ytmusic-chip-cloud-chip-renderer:nth-child(3n) a { border-left: 4px solid var(--oxocarbon-green) !important; }
ytmusic-chip-cloud-chip-renderer:nth-child(3n+1) a { border-left: 4px solid var(--oxocarbon-purple) !important; }
ytmusic-chip-cloud-chip-renderer:nth-child(3n+2) a { border-left: 4px solid var(--oxocarbon-blue) !important; }
''
