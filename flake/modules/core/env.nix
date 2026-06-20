{ pkgs, ... }: {
  environment.variables = {
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
    YDOTOOL_SOCKET = "/tmp/ydotools";
    RUST_BACKTRACE = "1";
    LSP_USE_PLISTS = "true";
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
    GSETTINGS_SCHEMA_DIR = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas/";
    WINEPREFIX = "~/.wine";
    VDPAU_DRIVER = "va_gl";
    LIBVA_DRIVER_NAME = "nvidia";
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };
}
