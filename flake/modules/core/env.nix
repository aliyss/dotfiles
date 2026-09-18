{ pkgs, ... }: {
  environment.homeBinInPath = true;
  environment.variables = {
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
    YDOTOOL_SOCKET = "/run/user/1000/.ydotool_socket";
    RUST_BACKTRACE = "1";
    LSP_USE_PLISTS = "true";
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
    GSETTINGS_SCHEMA_DIR = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas/";
    WINEPREFIX = "~/.wine";
    VDPAU_DRIVER = "va_gl";
    LIBVA_DRIVER_NAME = "nvidia";
    # Fix WebKitGTK (nm-openconnect-auth-dialog) on Nvidia+Wayland: blank SSO window / MESA nvidia_drm_gbm.so
    WEBKIT_DISABLE_DMABUF_RENDERER = "1";
    WEBKIT_DISABLE_COMPOSITING_MODE = "1";
    # Workaround for Intel Vulkan ICD eyes preferring llvmpipe on some setups.
    # Arch file name order does not guarantee this across driver updates.
    # Only set on hosts that need the Intel ICD to win.
    # VK_DRIVER_FILES = "${pkgs.mesa}/share/vulkan/icd.d/intel_icd.x86_64.json";
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    # WebKitGTK does TLS through libsoup, which loads its TLS backend from
    # glib-networking's GIO module — and gvfs/dconf are the only things that
    # contribute to this list, so the module was never present. Missing it makes
    # every https navigation in a webkit view fail with libsoup's
    #   "TLS support is not available"
    # which SSO-v2 clients (e.g. Cisco Secure Client's acwebhelper, or
    # nm-openconnect-auth-dialog for AnyConnect WebAuth) surface as
    #   "Authentication failed due to problem navigating to the single sign-on URL"
    # (acwebhelper logs the libsoup line above) or as a blank login window.
    GIO_EXTRA_MODULES = ["${pkgs.glib-networking}/lib/gio/modules"];
  };
}
