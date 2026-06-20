{ pkgs, ... }:
let
  gdk = pkgs.google-cloud-sdk.withExtraComponents (with pkgs.google-cloud-sdk.components; [
    gke-gcloud-auth-plugin
  ]);
in with pkgs; [
  slack
  anydesk
  gdk
  teams-for-linux
]
