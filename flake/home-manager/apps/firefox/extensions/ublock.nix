

{
  home.file.".mozilla/managed-storage/uBlock0@raymondhill.net.json".text =
    builtins.toJSON {
      name = "uBlock0@raymondhill.net";
      description = "_";
      type = "storage";
      data = {
        adminSettings = {
          userFilters = ''
            www.youtube.com###cinematics > div > canvas
          '';
        };
        userSettings = [
          [ "advancedUserEnabled" "true" ]
          [ "autoUpdate" "true" ]
          [ "colorBlindFriendly" "true" ]
          [ "contextMenuEnabled" "true" ]
          [ "dynamicFilteringEnabled" "false" ]
        ];
        toOverwrite = {
          filterLists = [
            "user-filters"
            "ublock-filters"
            "ublock-badware"
            "ublock-privacy"
            "ublock-quick-fixes"
            "ublock-abuse"
            "ublock-unbreak"
            "easylist"
            "easyprivacy"
            "urlhaus-1"
            "plowe-0"
            "adguard-cookiemonster"
            "ublock-cookies-adguard"
            "fanboy-cookiemonster"
            "ublock-cookies-easylist"
            "https://raw.githubusercontent.com/liamengland1/miscfilters/master/antipaywall.txt"
            "https://gitlab.com/magnolia1234/bypass-paywalls-clean-filters/-/raw/main/bpc-paywall-filter.txt"
            "https://raw.githubusercontent.com/gijsdev/ublock-hide-yt-shorts/master/list.txt"
          ];
        };
      };
    };
}
