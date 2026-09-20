{
  lib,
  pkgs,
  ...
}: let
  # TEMPORARY shutdown-wake test: set to false to disable TLP and restore
  # NixOS-managed power management, then `nixos-rebuild switch` and test
  # `shutdown -h 0`. Flip back to true (or delete this flag) to revert.
  enableTlp = false;
in {
  # LLM now unified in modules/profiles/llm.nix (CUDA on bequitta, Vulkan on blisspla)
  # hosts/blisspla/services/local-llm.nix is deprecated — kept for reference but not imported

  networking.hostName = "aliyss-blisspla";

  # The Vulkan device smoke check helper is added to the host profile in
  # flake.nix's blisspla NixOS config, where the flakeside package is directly
  # available. Nothing to do here.

  services.xserver = {
    enable = true;
    videoDrivers = ["intel" "modesetting"];
  };

  # --- Intel Arc (Meteor Lake) GPU ---
  # DaVinci Resolve ships only the OpenCL *loader* (ocl-icd) and finds no
  # physical GPU unless the vendor ICD is present. intel-compute-runtime is the
  # Intel NEO OpenCL driver that makes the Arc iGPU show up as an OpenCL device.
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-compute-runtime # OpenCL (NEO) + Level Zero for Arc/Xe — required by Resolve
      intel-media-driver # VA-API (iHD) hardware video decode/encode
    ];
  };
  # Prefer the modern iHD VA-API backend on the Xe iGPU. The shared
  # modules/core/env.nix sets LIBVA_DRIVER_NAME="nvidia" (for the NVIDIA
  # desktop); this Intel-only laptop needs iHD, so force it.
  environment.variables.LIBVA_DRIVER_NAME = lib.mkForce "iHD";

  # --- Battery / power optimization (laptop) ---
  # TLP handles adaptive CPU governor, NVMe APST, USB autosuspend, charge thresholds.
  services.tlp = lib.mkIf enableTlp {
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
  # (With TLP off, powerManagement falls back to its NixOS default = enabled.)
  powerManagement.enable = lib.mkIf enableTlp (lib.mkForce false);

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
