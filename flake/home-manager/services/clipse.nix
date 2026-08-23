{
  pkgs,
  lib,
  ...
}: let
  listener = pkgs.writeShellScript "clipse-listen" ''
    ${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.clipse}/bin/clipse --wl-store &
    ${pkgs.wl-clipboard}/bin/wl-paste --type image/png --watch ${pkgs.clipse}/bin/clipse --wl-store &
    wait
  '';
in {
  systemd.user.services.clipse-listen = {
    Unit = {
      Description = "Clipse clipboard history monitor";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = listener;
      Restart = "on-failure";
      RestartSec = "2";
    };
    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };
}
