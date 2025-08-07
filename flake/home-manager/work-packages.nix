{pkgs, ...}: let
  gdk = pkgs.google-cloud-sdk.withExtraComponents (with pkgs.google-cloud-sdk.components; [
    gke-gcloud-auth-plugin
  ]);
in {
  # Packages I require for work only.
  packages = with pkgs; [
    slack
    anydesk
    gdk
    claude-code
  ];
}
