{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.forticlient-nixos.nixosModules.forticlient
  ];

  systemd.tmpfiles.rules = [
    "L+ /usr/bin/modutil - - - - ${pkgs.nssTools}/bin/modutil"
    # FortiClient GUI's unlock flow hardcodes /usr/bin/pkexec (absent on NixOS).
    "L+ /usr/bin/pkexec - - - - ${pkgs.polkit}/bin/pkexec"
  ];

  # The GUI shows an "Unlock" tab on install (sidebar.js checks
  # `isManaged && !managed_by_ems` — true for any standalone client) and auto-runs
  # `/usr/bin/pkexec /opt/forticlient/unlock-gui.sh`. unlock-gui.sh is a no-op; it
  # only exists for the SUCCESS status callback to flip `locked.isNotElevated`.
  # There's no polkit agent (and no prompt would even show) on Hyprland, so grant
  # exactly this script via a scoped rule instead of prompting.
  security.polkit.extraConfig = ''
    polkit.addRule(function (action, subject) {
      if (
        action.id == "org.freedesktop.policykit.exec" &&
        subject.user == "aliyss" &&
        action.lookup("program") == "/opt/forticlient/unlock-gui.sh"
      ) {
        return polkit.Result.YES;
      }
    });
  '';

  services.forticlient = {
    enable = true;
    extraLibraries = with pkgs; [libgbm gtk2];
    gnomeKeyring.pamServices = ["login" "greetd"];
    package = inputs.forticlient-nixos.packages.x86_64-linux.forticlient.override {
      # VPN-ONLY client (forticlient_vpn_7.4.3.5411). The full "forticlient"
      # build bundles the EMS/endpoint machinery whose license gate kills the
      # tunnel ~10s after connect ("IPsec VPN has been disabled while
      # registered to EMS"). The stripped VPN-only build may not enforce
      # that gate. Same sha256 as the original links.fortinet.com redirect.
      version = "7.4.3.5411";
      url = "https://links.fortinet.com/forticlient/deb/vpnagent";
      sha256 = "d2c0366decbf0b907fbf0d9306b8ac0b705d2d9cb4eb7b946ae06ce5388d4e5a";
    };
  };
}
