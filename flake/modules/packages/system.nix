{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    tuigreet
    foot
    neovim
    ((emacsPackagesFor emacs30-pgtk).emacsWithPackages
      (epkgs: [epkgs.vterm epkgs.lsp-tailwindcss epkgs.dap-mode]))
    unzip
    gcc
    mpv
    php
    phpPackages.composer
    nodejs_24
    typescript
    typescript-language-server
    eslint
    eslint_d
    tailwindcss
    tailwindcss-language-server
    prettier
    localtunnel
    rustywind
    rustc
    cargo
    rustfmt
    rust-analyzer
    clippy
    openssl
    pkg-config
    hyprls
    hyprlang
    flutter
    python3
    (python3.withPackages (ps: with ps; [pip]))
    go
    air
    gopls
    nil
    nixfmt
    pavucontrol
    awww
    hyprcursor
    clipse
    (wlr-which-key.overrideAttrs (oldAttrs: {
      version = "1.3.0";
      src = pkgs.fetchFromGitHub {
        owner = "MaxVerevkin";
        repo = "wlr-which-key";
        rev = "v1.3.0";
        hash = "sha256-2dVTN5aaXeGBUKhsuUyDfELyL4AcKoaPXD0gN7ydL/Y=";
      };
      cargoHash = "";
    }))
    grim
    slurp
    git
    gh
    wget
    wl-clipboard
    ydotool
    gsettings-desktop-schemas
    xdg-user-dirs
    mcaselector
    v4l-utils
    android-tools
    adb-sync
    scrcpy
    pinentry-gtk2
  ];
}
