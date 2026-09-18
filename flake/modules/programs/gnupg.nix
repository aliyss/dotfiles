{ pkgs, lib, ... }: {
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = lib.mkForce pkgs.pinentry-gnome3;
  };

  programs.ssh.askPassword = "";
}
