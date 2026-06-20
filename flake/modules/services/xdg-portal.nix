{ pkgs, ... }: {
  xdg.portal = {
    enable = true;
    config = {
      common.default = ["gtk"];
      hyprland.default = ["gtk" "hyprland"];
    };
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };
}
