{pkgs, ...}: {
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "/run/current-system/sw/bin/start-hyprland";
        user = "aliyss";
      };
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --time-format '%I:%M %p | %a • %h | %F' --cmd start-hyprland";
        user = "greeter";
      };
    };
  };

  # GNOME Keyring for NetworkManager secrets (VPN + 802.1X WiFi like eduroam)
  # Provides org.freedesktop.secrets for nm-applet / nm-openconnect-auth-dialog
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
  security.pam.services.hyprlock.enableGnomeKeyring = true;
  security.pam.services.login.enableGnomeKeyring = true;

  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal";
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };

  console.useXkbConfig = true;
}
