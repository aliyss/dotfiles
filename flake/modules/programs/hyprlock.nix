{ ... }: {
  security.pam.services.hyprlock = {
    text = "auth include login";
    fprintAuth = false;
    enableGnomeKeyring = true;
  };

  programs.hyprlock = {
    enable = true;
  };
}
