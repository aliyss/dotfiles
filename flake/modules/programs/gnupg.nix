{ pkgs, lib, ... }: {
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = lib.mkForce pkgs.pinentry-gtk2;
  };

  programs.ssh.askPassword = "";
}
