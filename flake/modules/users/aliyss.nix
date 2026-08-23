{ ... }: let
  sshKeys = import ../../lib/ssh-keys.nix;
in {
  users.users.aliyss = {
    isNormalUser = true;
    description = "aliyss";
    extraGroups = ["networkmanager" "wheel" "docker" "uinput" "video"];
    openssh.authorizedKeys.keys = sshKeys;
  };
}
