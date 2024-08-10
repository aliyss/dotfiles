{pkgs, ...}: let
  yazi-glow = pkgs.fetchFromGitHub {
    owner = "Reledia";
    repo = "glow.yazi";
    rev = "536185a4e60ac0adc11d238881e78678fdf084ff";
    hash = "sha256-Dc/zdxfzAUM5NX8PxzfljRbYvO9f9syuLO8yBr+R3qg=";
  };
in {
  programs.yazi = {
    enable = true;
    # plugins = {
    #   "glow.yazi" = yazi-glow;
    # };
    enableZshIntegration = true;
  };
}
