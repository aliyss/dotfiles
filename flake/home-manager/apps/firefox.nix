{ pkgs, config, lib, tridactyl-native-messenger, ... }:

let
  buildFirefoxXpiAddon =
    config.nur.repos.rycee.firefox-addons.buildFirefoxXpiAddon;
in {

  imports = [ ./firefox/extensions/tridactyl ./firefox/extensions/ublock ];

  programs.firefox = {
    enable = true;
    package = pkgs.firefox-wayland.override {
      cfg = {
        enableGnomeExtensions = true;
        enableTridactylNative = true;
      };
      extraPolicies = {
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableTelemetry = true;
        FirefoxHome = {
          Pocket = false;
          Snippets = false;
        };
        UserMessaging = {
          ExtensionRecommendations = false;
          SkipOnboarding = true;
        };
        OfferToSaveLoginsDefault = false;
      };
    };
    profiles = {
      default = {
        isDefault = true;
        settings = {
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "svg.context-properties.content.enabled" = true;
          "layers.acceleration.force-enabled" = true;
          "gfx.webrender.all" = true;
          "gfx.webrender.enabled" = true;
          "layout.css.backdrop-filter.enabled" = true;
          "layout.css.has-selector.enabled" = true;
          "browser.startup.page" = 3;
          "general.smoothScroll" = true;
          "devtools.chrome.enabled" = true;
          "devtools.debugger.remote-enabled" = true;
          "findbar.highlightAll" = true;
        };
        extensions = with config.nur.repos.rycee.firefox-addons; [
          ublock-origin
          bitwarden
          darkreader
          tridactyl
          (buildFirefoxXpiAddon {
            pname = "mal-sync";
            version = "0.9.5";
            addonId = "{c84d89d9-a826-4015-957b-affebd9eb603}";
            url =
              "https://addons.mozilla.org/firefox/downloads/file/4132587/mal_sync-0.9.5.xpi";
            sha256 = "L/2PR7qI3g4Vx+10hV14ZpIYtIQtCgK6OU9IFJEI+ng=";
            meta = with lib; {
              homepage = "https://github.com/MALSync/MALSync";
              description =
                "Integrates MyAnimeList/AniList/Kitsu/Simkl into various sites, with auto episode tracking.";
              license = licenses.gpl3;
              platforms = platforms.all;
            };
          })
        ];
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
            "NixOS Wiki" = {
              urls = [{
                template = "https://nixos.wiki/index.php?search={searchTerms}";
              }];
              iconUpdateURL = "https://nixos.wiki/favicon.png";
              updateInterval = 24 * 60 * 60 * 1000;
              definedAliases = [ "@nw" ];
            };
            "Wikipedia (en)".metaData.alias = "@wiki";
            "DuckDuckGo".metaData.hidden = true;
            "Amazon.com".metaData.hidden = true;
            "Bing".metaData.hidden = true;
            "eBay".metaData.hidden = true;
          };
        };
        # userChrome = ''
        #   window, #main-window, #toolbar-menubar, #TabsToolbar, #PersonalToolbar, #navigator-toolbox, #sidebar-box {
        #     background-color: transparent !important;
        #     -moz-appearance: none !important;
        #     background-image: none !important;
        #   }

        #   #navigator-toolbox-background {
        #     background-color: transparent !important;
        #     -moz-appearance: none !important;
        #   }

        #   #TabsToolbar {
        #     visibility: collapse;
        #   }

        #   window, #nav-bar {
        #     background-color: transparent !important;
        #     -moz-appearance: none !important;
        #     background-image: none !important;
        #   }

        #   .tab-background[selected="true"] {
        #     background: transparent !important;
        #     -moz-appearance: none !important;
        #     background-image: none !important;
        #   }

        #   #customization-container {
        #     background: rgba(33,37,41,0.3) !important;
        #     -moz-appearance: none !important;
        #   }

        #   #tabbrowser-tabpanels {
        #     background-color: rgb(0,0,0,0) !important;
        #     -moz-appearance: none !important;
        #   }

        #   .browserSidebarContainer {
        #     background-color: rgb(0,0,0,0) !important;
        #     -moz-appearance: none !important;
        #   }

        #   .browserStack {
        #     background-color: rgb(0,0,0,0) !important;
        #     -moz-appearance: none !important;
        #   }

        #   #tabbrowser-tabpanels browser[type=content] {
        #     background-color: rgb(0,0,0,0) !important;
        #     -moz-appearance: none !important;
        #     color-scheme: unset !important;
        #   }

        #   :root {
        #     --tabpanel-background-color: rgb(0,0,0,0) !important;
        #     -moz-appearance: none !important;
        #   }

        #    #sidebar-box > #browser, #webextpanels-window { background: transparent !important }

        # '';
        userChrome = ''
          @namespace url("http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul");

          #TabsToolbar {
            visibility: collapse;
          }

          #nav-bar {
            /* customize this value. */
            --navbar-margin: -44px;

            margin-top: var(--navbar-margin);
            margin-bottom: 0;
            z-index: -100;
            transition: all 0.3s ease !important;
            opacity: 0;
            background-color: rgba(0,0,0,1) !important;
          }

          #navigator-toolbox:focus-within > #nav-bar,
          #navigator-toolbox:hover > #nav-bar
          {
            margin-top: 0;
            margin-bottom: var(--navbar-margin);
            z-index: 100;
            opacity: 1;
          }

          #TabsToolbar {
            visibility: collapse;
          }

          #titlebar {
            display: none;
          }

          #sidebar-header {
            display: none;
          }
        '';
        userContent = ''
          @-moz-document url(about:home), url(about:newtab) {
              body {
                --newtab-background-color: black !important;
              }
          }
        '';
      };
    };
  };
}
