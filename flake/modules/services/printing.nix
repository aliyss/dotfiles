{ pkgs, ... }: {
  # CUPS printing — generic SMB backend support (e.g. campus / corporate
  # print servers over VPN). The NixOS cups module wires the SMB backend
  # itself (samba's smbspool → `smb` backend in the cups-progs ServerBin tree),
  # so only the daemon and the HP drivers are needed here.
  #
  # Site-specific queues (server/share/credentials) are NOT hardcoded here;
  # they live under ~/Documents/printers/<name>/.env and are added at
  # runtime via `printer-setup` (home-manager/apps/printing.nix) or
  # `add-printer.sh` in the flake root. Credentials are never stored in the
  # repo, only in root-owned /etc/cups/printers.conf after setup.
  #
  # smbspool refuses to start without a parseable /etc/samba/smb.conf
  # ("Can't load /etc/samba/smb.conf - run testparm to debug it"), and on
  # NixOS that file only exists with the full Samba *server* module. Provide
  # a minimal empty one instead — don't conflict with services.samba if it is
  # ever enabled later (its module defines the same path; remove this then).
  environment.etc."samba/smb.conf".text = ''
[global]
  '';

  # Queues are added per-machine at runtime (see above); no declarative queue here.
  services.printing.enable = true;
  # Socket-activated: no idle cupsd draining battery on the laptop.
  services.printing.startWhenNeeded = true;
  services.printing.drivers = [
    # hplip with static PPDs enabled (off by default) + no Qt GUI, so the
    # HP LaserJet Enterprise 700 M712 PostScript PPD is available to lpadmin.
    (pkgs.hplip.override {
      withStaticPPDInstall = true;
      withQt5 = false;
    })
  ];
}
