final: prev: let
  version = "21.1";
  resolveHash = "sha256-+3SB32EHpH9/0hM3h8CrO6f7V4ZAmxUFh3P8m6QDeO0=";
  product = "DaVinci Resolve";
  davinci = final.stdenv.mkDerivation rec {
    pname = "davinci-resolve";
    inherit version;
    nativeBuildInputs = with final; [
      appimageTools.appimage-exec
      addDriverRunpath
      copyDesktopItems
      unzip
    ];
    buildInputs = with final; [ libGLU libxxf86vm ];
    src = final.runCommandLocal "${pname}-src.zip" {
      outputHashMode = "recursive";
      outputHashAlgo = "sha256";
      outputHash = resolveHash;
      impureEnvVars = final.lib.fetchers.proxyImpureEnvVars;
      nativeBuildInputs = with final; [ curl jq ];
      SSL_CERT_FILE = "${final.cacert}/etc/ssl/certs/ca-bundle.crt";
      REFERID = "263d62f31cbb49e0868005059abcb0c9";
      DOWNLOADSURL = "https://www.blackmagicdesign.com/api/support/us/downloads.json";
      SITEURL = "https://www.blackmagicdesign.com/api/register/us/download";
      PRODUCT = product;
      VERSION = version;
      USERAGENT = builtins.concatStringsSep " " [
        "User-Agent: Mozilla/5.0 (X11; Linux ${final.stdenv.hostPlatform.linuxArch})"
        "AppleWebKit/537.36 (KHTML, like Gecko)"
        "Chrome/77.0.3865.75"
        "Safari/537.36"
      ];
      REQJSON = builtins.toJSON {
        "firstname" = "NixOS";
        "lastname" = "Linux";
        "email" = "someone@nixos.org";
        "phone" = "+31 71 452 5670";
        "country" = "nl";
        "street" = "-";
        "state" = "Province of Utrecht";
        "city" = "Utrecht";
        "product" = product;
      };
    } ''
      DOWNLOADID=$(
        curl --silent --compressed "$DOWNLOADSURL" \
          | jq --raw-output '.downloads[] | .urls.Linux?[]? | select(.downloadTitle | test("^'"$PRODUCT $VERSION"'( Update)?$")) | .downloadId'
      )
      echo "downloadid is $DOWNLOADID"
      test -n "$DOWNLOADID"
      RESOLVEURL=$(curl \
        --silent \
        --header 'Host: www.blackmagicdesign.com' \
        --header 'Accept: application/json, text/plain, */*' \
        --header 'Origin: https://www.blackmagicdesign.com' \
        --header "$USERAGENT" \
        --header 'Content-Type: application/json;charset=UTF-8' \
        --header "Referer: https://www.blackmagicdesign.com/support/download/$REFERID/Linux" \
        --header 'Accept-Encoding: gzip, deflate, br' \
        --header 'Accept-Language: en-US,en;q=0.9' \
        --header 'Authority: www.blackmagicdesign.com' \
        --header 'Cookie: _ga=GA1.2.1849503966.1518103294; _gid=GA1.2.953840595.1518103294' \
        --data-ascii "$REQJSON" \
        --compressed \
        "$SITEURL/$DOWNLOADID")
      echo "resolveurl is $RESOLVEURL"
      curl \
        --retry 3 --retry-delay 3 \
        --header "Upgrade-Insecure-Requests: 1" \
        --header "$USERAGENT" \
        --header "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" \
        --header "Accept-Language: en-US,en;q=0.9" \
        --compressed \
        "$RESOLVEURL" \
        > $out
    '';
    sourceRoot = ".";
    installPhase = let
      appimageName = "DaVinci_Resolve_${version}_Linux.run";
    in ''
      runHook preInstall
      export HOME=$PWD/home
      mkdir -p $HOME
      mkdir -p $out
      test -e ${final.lib.escapeShellArg appimageName}
      ${final.appimageTools.appimage-exec}/bin/appimage-exec.sh -x $out ${final.lib.escapeShellArg appimageName}
      mkdir -p $out/{"Apple Immersive/Calibration",configs,DolbyVision,easyDCP,Extras,Fairlight,GPUCache,Immersive/Canon/STMap,logs,Media,"Resolve Disk Database",.crashreport,.license,.LUT}
      mkdir -p $out/lib/udev/rules.d
      cp $out/share/etc/udev/rules.d/99-BlackmagicDevices.rules $out/lib/udev/rules.d/
      cp $out/share/etc/udev/rules.d/99-ResolveKeyboardHID.rules $out/lib/udev/rules.d/
      echo 'SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="096e", MODE="0666"' > $out/lib/udev/rules.d/99-DavinciPanel.rules
      echo 'KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="096e", MODE="0666"' >> $out/lib/udev/rules.d/99-DavinciPanel.rules
      test -f $out/lib/udev/rules.d/99-BlackmagicDevices.rules
      test -f $out/lib/udev/rules.d/99-ResolveKeyboardHID.rules
      test -f $out/lib/udev/rules.d/99-DavinciPanel.rules
      runHook postInstall
    '';
    dontStrip = true;
    postFixup = ''
      for program in $out/bin/*; do
        isELF "$program" || continue
        addDriverRunpath "$program"
      done
      for program in $out/libs/*; do
        isELF "$program" || continue
        if [[ "$program" != *"libcudnn_cnn_infer"* ]];then
          echo $program
          addDriverRunpath "$program"
        fi
      done
    '';
    desktopItems = with final; [
      (makeDesktopItem {
        name = "davinci-resolve";
        desktopName = "Davinci Resolve";
        genericName = "Video Editor";
        exec = "davinci-resolve";
        icon = "davinci-resolve";
        comment = "Professional video editing, color, effects and audio post-processing";
        categories = ["AudioVideo" "AudioVideoEditing" "Video" "Graphics"];
        startupWMClass = "resolve";
      })
      (makeDesktopItem {
        name = "blackmagicraw-player";
        desktopName = "Blackmagic RAW Player";
        exec = "blackmagicraw-player %f";
        icon = "blackmagicraw-player";
        mimeTypes = ["application/x-braw-clip" "application/x-braw-sidecar"];
        categories = ["Video" "AudioVideo"];
      })
      (makeDesktopItem {
        name = "blackmagicraw-speedtest";
        desktopName = "Blackmagic RAW Speed Test";
        exec = "blackmagicraw-speedtest";
        icon = "blackmagicraw-speedtest";
        categories = ["Video" "AudioVideo"];
      })
      (makeDesktopItem {
        name = "davinci-control-panels-setup";
        desktopName = "DaVinci Control Panels Setup";
        exec = "davinci-control-panels-setup";
        icon = "davinci-control-panels-setup";
        categories = ["Settings"];
      })
      (makeDesktopItem {
        name = "davinci-fairlight-studio-utility";
        desktopName = "Fairlight Studio Utility";
        exec = "davinci-fairlight-studio-utility";
        icon = "davinci-resolve";
        categories = ["AudioVideo" "Audio"];
      })
    ];
  };
in {
  davinci-resolve = final.buildFHSEnv {
    inherit (davinci) pname version;
    targetPkgs = pkgs: with pkgs; [
      alsa-lib aprutil bzip2 davinci dbus expat fontconfig freetype glib libGL libGLU libarchive libcap librsvg libtool libuuid libxcrypt-legacy libxkbcommon nspr ocl-icd opencl-headers python3 python3.pkgs.numpy libdrm libxkbfile krb5 nss libxcb-cursor udev xdg-utils libice libsm libx11 libxcomposite libxcursor libxdamage libxext libxfixes libxi libxinerama libxrandr libxrender libxt libxtst libxxf86vm libxcb libxcb-util libxcb-image libxcb-keysyms libxcb-render-util libxcb-wm xkeyboard-config zlib
    ];
    runScript = "${final.bash}/bin/bash ${final.writeText "davinci-wrapper" ''
      export QT_XKB_CONFIG_ROOT="${final.xkeyboard_config}/share/X11/xkb"
      export QT_PLUGIN_PATH="${davinci}/libs/plugins:$QT_PLUGIN_PATH"
      export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib:/usr/lib32:${davinci}/libs
      if [ $# -gt 0 ]; then
        exec "$@"
      else
        exec ${davinci}/bin/resolve
      fi
    ''}";
    extraInstallCommands = let
      execName = "davinci-resolve";
      mkWrapper = name: bin: final.writeShellScript name ''exec "$(dirname "$0")/${execName}" ${bin} "$@"'';
      wrappers = {
        "blackmagicraw-player" = "${davinci}/BlackmagicRAWPlayer/BlackmagicRAWPlayer";
        "blackmagicraw-speedtest" = "${davinci}/BlackmagicRAWSpeedTest/BlackmagicRAWSpeedTest";
        "davinci-control-panels-setup" = ''"${davinci}/DaVinci Control Panels Setup/DaVinci Control Panels Setup"'';
        "davinci-fairlight-studio-utility" = ''"${davinci}/Fairlight Studio Utility/Fairlight Studio Utility"'';
      };
    in ''
      mkdir -p $out/share/applications
      ln -s ${davinci}/share/applications/*.desktop $out/share/applications/
      mkdir -p $out/share/icons/hicolor/{128x128,256x256}/apps
      ln -s ${davinci}/graphics/DV_Resolve.png $out/share/icons/hicolor/128x128/apps/davinci-resolve.png
      ln -s ${davinci}/graphics/DV_Panels.png $out/share/icons/hicolor/128x128/apps/davinci-control-panels-setup.png
      ln -s ${davinci}/graphics/blackmagicraw-player_256x256_apps.png $out/share/icons/hicolor/256x256/apps/blackmagicraw-player.png
      ln -s ${davinci}/graphics/blackmagicraw-speedtest_256x256_apps.png $out/share/icons/hicolor/256x256/apps/blackmagicraw-speedtest.png
      ${final.lib.concatStringsSep "\n" (final.lib.mapAttrsToList (name: bin: ''ln -s ${mkWrapper name bin} $out/bin/${name}'') wrappers)}
      mkdir -p $out/share/mime/packages
      ln -s ${davinci}/share/resolve.xml $out/share/mime/packages/
      ln -s ${davinci}/share/blackmagicraw.xml $out/share/mime/packages/
      mkdir -p $out/lib/udev/rules.d
      ln -s ${davinci}/lib/udev/rules.d/99-BlackmagicDevices.rules $out/lib/udev/rules.d/
      ln -s ${davinci}/lib/udev/rules.d/99-ResolveKeyboardHID.rules $out/lib/udev/rules.d/
      ln -s ${davinci}/lib/udev/rules.d/99-DavinciPanel.rules $out/lib/udev/rules.d/
    '';
    passthru = { inherit davinci; };
    meta = with final.lib; {
      description = "Professional video editing, color, effects and audio post-processing";
      homepage = "https://www.blackmagicdesign.com/products/davinciresolve";
      license = licenses.unfree;
      platforms = ["x86_64-linux"];
      sourceProvenance = with sourceTypes; [binaryNativeCode];
      mainProgram = "davinci-resolve";
    };
  };
}
