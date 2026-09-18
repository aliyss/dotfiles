{ pkgs, ... }: {
  xdg.portal = {
    enable = true;
    config = {
      common.default = ["gtk"];
      hyprland.default = ["gtk" "hyprland"];
    };
    # No extraPortals here: programs.hyprland adds xdg-desktop-portal-hyprland
    # and its wayland-session module adds xdg-desktop-portal-gtk automatically.
    # Listing any portal here duplicates its systemd unit and breaks the build
    # ("xdg-desktop-portal-*.service: File exists" in user-units).
  };
}
