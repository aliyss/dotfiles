{pkgs, ...}: {
  # Packages I require for work only.
  packages = with pkgs; [
    slack
    anydesk
  ];
}
