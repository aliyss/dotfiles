{
  pkgs,
  config,
  lib,
  ...
}: let
  extensions = {
    "ublock-origin" = {
      permissions = [
        "dns"
        "menus"
        "privacy"
        "storage"
        "tabs"
        "alarms"
        "unlimitedStorage"
        "webNavigation"
        "webRequest"
        "webRequestBlocking"
        "<all_urls>"
        "http://*/*"
        "https://*/*"
        "file://*/*"
        "https://easylist.to/*"
        "https://*.fanboy.co.nz/*"
        "https://filterlists.com/*"
        "https://forums.lanik.us/*"
        "https://github.com/*"
        "https://*.github.io/*"
        "https://*.letsblock.it/*"
        "https://github.com/uBlockOrigin/*"
        "https://ublockorigin.github.io/*"
        "https://*.reddit.com/r/uBlockOrigin/*"
      ];
    };
    "bitwarden" = {
      permissions = [
        "tabs"
        "contextMenus"
        "storage"
        "unlimitedStorage"
        "clipboardRead"
        "clipboardWrite"
        "idle"
        "http://*/*"
        "https://*/*"
        "webRequest"
        "webRequestBlocking"
        "file:///*"
        "https://lastpass.com/export.php"
        "<all_urls>"
        "*://*/*"
        "webNavigation"
      ];
    };
    "darkreader" = {
      permissions = ["alarms" "contextMenus" "storage" "tabs" "theme" "<all_urls>"];
    };
    "tridactyl" = {
      permissions = [
        "activeTab"
        "bookmarks"
        "browsingData"
        "contextMenus"
        "contextualIdentities"
        "cookies"
        "clipboardWrite"
        "clipboardRead"
        "downloads"
        "find"
        "history"
        "search"
        "sessions"
        "storage"
        "tabHide"
        "tabs"
        "topSites"
        "management"
        "nativeMessaging"
        "webNavigation"
        "webRequest"
        "webRequestBlocking"
        "proxy"
        "<all_urls>"
      ];
    };
  };
in {
  assertions =
    lib.mapAttrsToList (k: v: let
      unaccepted =
        lib.subtractLists v.permissions
        config.nur.repos.rycee.firefox-addons.${k}.meta.mozPermissions;
    in {
      assertion = unaccepted == [];
      message = "Extension ${k} has unaccepted permissions: ${
        builtins.toJSON unaccepted
      }";
    })
    extensions;
}
