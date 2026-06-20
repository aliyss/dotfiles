{ pkgs, ... }: {
  programs.fish = {
    enable = true;
    shellAliases = {
      ll = "ls -l";
      screenshot = ''grim -g "$(slurp -d)" - | wl-copy'';
    };
  };

  users.defaultUserShell = pkgs.fish;
  environment.shells = with pkgs; [fish];
}
