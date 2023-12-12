{ pkgs, prismlauncher, ... }:

let prismLchr = prismlauncher.packages.${pkgs.system}.default;
in {
  programs.prismlauncher = {
    enable = true;
    package = prismLchr;
  };
}
