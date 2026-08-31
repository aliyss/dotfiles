{ lib, pkgs, ... }: {
  networking.hostName = "aliyss-blisspla";

  services.xserver = {
    enable = true;
    videoDrivers = ["intel" "modesetting"];
  };

  # --- Battery / power optimization (laptop) ---
  # TLP handles adaptive CPU governor, NVMe APST, USB autosuspend, charge thresholds.
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      ENERGY_PERF_POLICY_ON_BAT = "power";
      USB_AUTOSUSPEND = 2;
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };
  # TLP manages the CPU governor/EPP; NixOS's powerManagement.enable boots a
  # cpufreq.service that pins the governor and fights TLP. Let TLP own it.
  powerManagement.enable = lib.mkForce false;

  # Allow the video group to control backlight so brightnessctl works from
  # wlr-which-key without root.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
  '';

  # No active NPU workload — leave the Intel NPU block powered down.
  hardware.cpu.intel.npu.enable = lib.mkForce false;

  # Don't autostart the Android container; start it on demand instead.
  # (waydroid module doesn't expose enableOnBoot — gate the service directly.)
  systemd.services.waydroid-container.wantedBy = lib.mkForce [];

  # Trim always-on daemons (TeamViewer, FortiClient). Their shared configs in
  # modules/default.nix set enable=true, so force off here.
  services.teamviewer.enable = lib.mkForce false;
  services.forticlient.enable = lib.mkForce false;
  # Desktop-only RGB lighting daemon; pointless on the laptop.
  services.hardware.openrgb.enable = lib.mkForce false;

  # Tailscale: keep the tailscaled unit *defined* so the wlr-which-key toggle can
  # start/stop it, but don't autostart it at boot — no VPN daemon idle-draining
  # battery when you aren't on the tailnet.
  services.tailscale.enable = true;
  systemd.services.tailscaled.wantedBy = lib.mkForce [];
}