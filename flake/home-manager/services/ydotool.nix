{pkgs, ...}: {
  services.ydotool = {
    enable = true;
    description = "Ydotool daemon for ydotool";
    serviceConfig = {ExecStart = "${pkgs.ydotool}/bin/ydotoold";};
    wantedBy = ["default.target"];
  };
}
