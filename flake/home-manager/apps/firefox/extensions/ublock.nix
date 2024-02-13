

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
            www.youtube.com###cinematics-container
            www.youtube.com##+js(nano-stb, resolve(1), *, 0.001)
            www.youtube.com##+js(set, yt.config_.EXPERIMENT_FLAGS.web_enable_ab_rsp_cl, false)
            www.youtube.com##+js(set, yt.config_.EXPERIMENT_FLAGS.ab_pl_man, false)
            ||googlevideo.com/videoplayback$xhr,3p,method=get,domain=www.youtube.com
            $removeparam=si,domain=youtu.be|youtube-nocookie.com|music.youtube.com|www.youtube.com,badfilter
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
