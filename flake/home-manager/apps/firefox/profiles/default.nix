{ pkgs, config, lib, ... }@args:

let customExtensions = import ../extensions/custom.nix args;
in {
  isDefault = true;
  settings = {
    "trailhead.firstrun.didSeeAboutWelcome" = true;

    "app.update.auto" = false;

    "browser.aboutConfig.showWarning" = false;
    "browser.warnOnQuit" = true;
    "browser.toolbars.bookmarks.visibility" = false;
    "browser.startup.page" = 3;

    "devtools.chrome.enabled" = true;
    "devtools.debugger.remote-enabled" = true;

    "gfx.webrender.all" = true;
    "gfx.webrender.enabled" = true;

    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
    "svg.context-properties.content.enabled" = true;
    "layers.acceleration.force-enabled" = true;
    "layout.css.backdrop-filter.enabled" = true;
    "layout.css.has-selector.enabled" = true;
    "layout.css.moz-document.content.enabled" = true;
    "layout.css.moz-document.url-prefix-hack.enabled" = true;
    "layout.css.color-mix.enabled" = true;

    "extensions.pocket.enabled" = false;

    "general.smoothScroll" = true;
    "findbar.highlightAll" = true;

    "dom.forms.autocomplete.formautofill" = false;
    "extensions.formautofill.creditCards.enabled" = false;
    "dom.payments.defaults.saveAddress" = false;

    "media.ffmpeg.vaapi.enabled" = true;

    "cookiebanners.ui.desktop.enabled" = true;
  };
  extensions = with config.nur.repos.rycee.firefox-addons;
    [ ublock-origin bitwarden darkreader tridactyl ] ++ customExtensions;
  search = {
    force = true;
    default = "Google";
    engines = {
      "Nix Packages" = {
        urls = [{
          template = "https://search.nixos.org/packages";
          params = [
            {
              name = "type";
              value = "packages";
            }
            {
              name = "query";
              value = "{searchTerms}";
            }
          ];
        }];
        icon =
          "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        definedAliases = [ "@np" ];
      };
      "Wikipedia (en)".metaData.hidden = true;
      "DuckDuckGo".metaData.hidden = true;
      "Amazon.com".metaData.hidden = true;
      "Bing".metaData.hidden = true;
      "eBay".metaData.hidden = true;
    };
  };
  userChrome = (builtins.readFile ./userChrome.css);
  userContent = (builtins.readFile ./userContent.css);
}
