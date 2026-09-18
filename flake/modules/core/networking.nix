{
  inputs,
  ...
}: {
  networking.networkmanager.enable = true;

  # AnyConnect WebAuth — generic SSO-v2 "Login window" support (e.g. Cisco
  # endpoints that only offer <sso-v2-login> webview, no external browser).
  # The gateway's config-auth dictates <sso-v2-token-cookie-name> and
  # <form><input type="sso">, so openconnect alone dies with "No SSO handler"
  # and needs NetworkManager + networkmanager-openconnect's nm-openconnect-auth-dialog
  # (WebKitGTK webview). This module ships `vpn-connect`/`vpn-disconnect`
  # which delete+recreate the profile on every connect (cookie-flags=2, agent-owned)
  # so every connect runs a fresh SSO instead of reusing an expired cookie.
  #
  # Fully runtime: no hardcoded VPN or WiFi profiles live in the repo.
  # Define them under ~/Documents:
  #   ~/Documents/vpn/<name>/.env  ->  TYPE=nm + NM_PROFILE=<name> or TYPE=cisco + CISCO_HOST=<gateway>
  #   ~/Documents/wifi/eduroam.env ->  identity / anonymous-identity for eduroam (PEAP/MSCHAPv2)
  # Example: ~/Documents/vpn/example/.env with
  #   TYPE="nm"
  #   NM_PROFILE="example"
  #   # gateway/identity live in the .env or NM profile, not in Nix.
  # See home-manager/apps/vpn.nix (vpn-launch) for the dispatcher.
  imports = [inputs.anyconnect-webauth.nixosModules.default];

  services.anyconnect-webauth = {
    enable = true;
    # No hardcoded connections — add per-site profiles imperatively via
    # NetworkManager (nmcli) or by dropping a file under ~/Documents/vpn/<name>/.
    # Declarative examples (if you prefer Nix-managed profiles, put them in
    # local.nix which is gitignored):
    #   connections.<name> = { gateway = "vpn.example.com"; connectionName = "<name>"; };
    connections = {};
  };

  # eduroam is now fully runtime / unmanaged by Nix. If you need it, create it
  # once via nm-applet or:
  #   nmcli connection add type wifi con-name eduroam ifname wlan0 ssid eduroam \
  #     wifi-sec.key-mgmt wpa-eap 802-1x.eap peap 802-1x.phase2-auth mschapv2 \
  #     802-1x.identity "$EDUROAM_IDENTITY" 802-1x.anonymous-identity "$EDUROAM_ANON" \
  #     802-1x.password-flags 1 802-1x.system-ca-certs yes
  # then `nmcli connection up eduroam --ask` (password stored agent-owned in
  # GNOME keyring). Keep credentials in ~/Documents/wifi/eduroam.env, not here.
  # See cat.eduroam.org for CA pinning if you want stricter than system-ca-certs.

  # nm-applet is the secret agent that opens the openconnect login window: it is
  # autostarted with the session (hypr/hyprland_source.lua, which also sets the
  # GDK/WEBKIT workarounds WebKitGTK needs under Hyprland) and added to
  # systemPackages by services.anyconnect-webauth above.

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [80 443 25565];
    # Only allow SSH from Tailscale
    interfaces."tailscale0" = {
      allowedTCPPorts = [ 22 ];
    };
  };
}
