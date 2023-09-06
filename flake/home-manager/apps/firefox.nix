{ pkgs, config, tridactyl-native-messenger, ... }:

{
  home.file.".mozilla/native-messaging-hosts/tridactyl.json".text = let
    tridactyl = with pkgs.nimPackages;
      buildNimPackage {
        pname = "tridactyl_native";
        version = "dev";
        nimBinOnly = true;
        src = tridactyl-native-messenger;
        buildInputs = [ tempfile regex unicodedb ];
      };
  in builtins.toJSON {
    name = "tridactyl";
    description = "Tridactyl native command handler";
    path = "${tridactyl}/bin/native_main";
    type = "stdio";

    allowed_extensions = [
      "tridactyl.vim@cmcaine.co.uk"
      "tridactyl.vim.betas@cmcaine.co.uk"
      "tridactyl.vim.betas.nonewtab@cmcaine.co.uk"
    ];
  };

  xdg.configFile."tridactyl/tridactylrc".text = ''
    colourscheme --url https://raw.githubusercontent.com/aliyss/dotfiles/master/tridactyl/aliyss.css aliyss

    set newtab www.google.com
    set smoothscroll true
    set editorcmd emacsclient -a \"\" -c -e '(progn (find-file "%f") (forward-line (1- %l)) (forward-char %c))'

    unbind b
    bind bb tabprev
    bind bn tabnext
    bind bc tabclose
    bind be fillcmdline tabclose
    bind bj fillcmdline taball

    unbind --mode=normal t
    bind tt back
    bind tn forward
    bind be fillcmdline tabclose
    bind bj fillcmdline taball

    bind e fillcmdline open
  '';

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
