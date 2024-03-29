# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, ... }:

{
  imports = [
    # Untouched hardware configuration file
    ./hardware-configuration.nix
  ];

  # BOOTLOADER
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelModules = [ "i2c-dev" "i2c-piix4" ];

  # HOSTNAME
  networking.hostName = "aliyss-bequitta";

  # NETWORKING
  networking.networkmanager.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 25565 ];
  };

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # NETWORKING PROXY
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # TIMEZONE
  time.timeZone = "Europe/Zurich";

  # INTERNATIONALISATION PROPERTIES
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_CH.UTF-8";
    LC_IDENTIFICATION = "de_CH.UTF-8";
    LC_MEASUREMENT = "de_CH.UTF-8";
    LC_MONETARY = "de_CH.UTF-8";
    LC_NAME = "de_CH.UTF-8";
    LC_NUMERIC = "de_CH.UTF-8";
    LC_PAPER = "de_CH.UTF-8";
    LC_TELEPHONE = "de_CH.UTF-8";
    LC_TIME = "de_CH.UTF-8";
  };

  # SOUND
  sound.enable = true;

  # SERVICES
  services = {
    # Sound
    pipewire.enable = true;
    pipewire.pulse.enable = true;
    pipewire.wireplumber.enable = true;
    # Bluetooth
    blueman.enable = true;
    # Display
    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
      displayManager.gdm = {
        enable = true;
        wayland = true;
      };
      # Keymaps
      xkb = {
        variant = "colemak_dh_iso";
        layout = "us";
      };
    };
    # hardware.openrgb = {
    #   enable = true;
    #   package = pkgs.openrgb-with-all-plugins;
    # };
  };

  virtualisation.docker.enable = true;
  # DEFAULT USER ACCOUNT
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.aliyss = {
    isNormalUser = true;
    description = "aliyss";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = with pkgs; [ ];
  };

  # NIXPKGS CONFIG
  nixpkgs.config.allowUnfree = true;
  # nixpkgs.config.pulseaudio = true;

  # SYSTEM PROFILE PACKAGES
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # Terminal
    foot

    # Editor
    ## Vim: for quick configurations in case graphics dies
    neovim
    ## Emacs: for everything else
    ((emacsPackagesFor emacs29-pgtk).emacsWithPackages
      (epkgs: [ epkgs.vterm epkgs.lsp-tailwindcss ]))
    ### Emacs: Additional Packages, compatibility with config.org file
    youtube-dl
    #### required to install some language servers
    unzip
    gcc
    mpv

    # Language Support
    ## NodeJS
    nodejs_20
    ### Globally installed Node Packages
    nodePackages.typescript
    nodePackages.typescript-language-server
    nodePackages.eslint
    nodePackages.eslint_d
    nodePackages.jsonlint
    nodePackages.tailwindcss
    nodePackages.vercel
    nodePackages."@tailwindcss/language-server"
    rustywind
    tailwindcss
    nodePackages.prettier
    nodePackages.localtunnel
    ## Typescript
    typescript
    ## Rust
    rustc
    cargo
    rustfmt
    rust-analyzer
    clippy
    openssl
    pkg-config
    flutter
    ## Python
    python3
    # (pkgs.python3.withPackages (ps: with ps; [ python-openstackclient ]))
    ## Configuration Files
    nil
    ## Nix
    nixfmt

    # Hardware
    pulseaudio

    # Browser
    firefox-wayland

    # Wallpaper for Hyprland
    swww

    # Screenshots
    grim
    slurp

    # Git
    git
    ## Github CLI for git
    gh

    # Other Useful Packages
    wget
    wl-clipboard

    mcaselector
    gsettings-desktop-schemas
    xdg-user-dirs

  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # HYPRLAND
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # SHELL CONFIGURATION
  ## ssh
  programs.ssh.askPassword = "";
  ## zsh
  programs.zsh = {
    enable = true;
    shellAliases = {
      ll = "ls -l";
      screenshot = ''grim -g "$(slurp -d)"'';
    };
    ohMyZsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "fino-time";
    };
  };
  ## Default Shell
  users.defaultUserShell = pkgs.zsh;
  ## Environment Shell
  environment.shells = with pkgs; [ zsh ];

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

  # HARDWARE
  hardware = {
    # Display
    opengl = {
      enable = true;
      driSupport = true;
    };
    nvidia = {
      modesetting.enable = true;
      nvidiaSettings = true;
    };
    # Sound
    pulseaudio.enable = false;
    pulseaudio.support32Bit = true;
    # Bluetooth
    bluetooth.enable = true;
  };

  # FONTS
  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
  ];

  environment.variables = {
    RUST_BACKTRACE = "1";
    LSP_USE_PLISTS = "true";
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
    GSETTINGS_SCHEMA_DIR =
      "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas/";

  };

  # FLAKE
  nix = { settings.experimental-features = [ "nix-command" "flakes" ]; };
}
