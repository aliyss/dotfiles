{...}: {
  imports = [
    ./programs/adb.nix
    ./programs/hyprlock.nix
    ./programs/zoxide.nix
    ./services/keyd.nix
  ];
}
