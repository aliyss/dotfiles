{ pkgs, ... }: {

  services.emacs = {
    enable = true;
    defaultEditor = true;
  };
}
