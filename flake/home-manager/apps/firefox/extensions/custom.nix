{
  pkgs,
  config,
  lib,
  ...
}: let
  buildFirefoxXpiAddon =
    config.nur.repos.rycee.firefox-addons.buildFirefoxXpiAddon;
in [
  (buildFirefoxXpiAddon {
    pname = "mal-sync";
    version = "0.9.5";
    addonId = "{c84d89d9-a826-4015-957b-affebd9eb603}";
    url = "https://addons.mozilla.org/firefox/downloads/file/4132587/mal_sync-0.9.5.xpi";
    sha256 = "L/2PR7qI3g4Vx+10hV14ZpIYtIQtCgK6OU9IFJEI+ng=";
    meta = with lib; {
      homepage = "https://github.com/MALSync/MALSync";
      description = "Integrates MyAnimeList/AniList/Kitsu/Simkl into various sites, with auto episode tracking.";
      license = licenses.gpl3;
      platforms = platforms.all;
    };
  })
  (buildFirefoxXpiAddon {
    pname = "amoled-black";
    version = "1.0";
    addonId = "{bc16b6e3-4935-42b3-bff7-b65b49434857}";
    url = "https://addons.mozilla.org/firefox/downloads/file/2114250/amoled_black-1.0.xpi";
    sha256 = "toSWV87bj8IfdNOCdjGbIF5s2WIMHyyz4y4ojMsnsJg=";
    meta = with lib; {};
  })
  (buildFirefoxXpiAddon {
    pname = "user-agent-string-switcher";
    version = "0.5.0";
    addonId = "{a6c4a591-f1b2-4f03-b3ff-767e5bedf4e7}";
    url = "https://addons.mozilla.org/firefox/downloads/file/4098688/user_agent_string_switcher-0.5.0.xpi";
    sha256 = "ncjaPIxG1PBNEv14nGNQH6ai9QL4WbKGk5oJDbY+rjM=";
    meta = with lib; {
      homepage = "https://github.com/ray-lothian/UserAgent-Switcher";
      description = "Easily override the browser's User-Agent string.";
      license = licenses.mpl20;
      platforms = platforms.all;
    };
  })
]
