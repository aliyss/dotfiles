# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  pkgs,
  inputs,
  config,
  lib,
  ...
}: {
  imports = [
    # Untouched hardware configuration file
    ./hardware-configuration.nix
  ];

  # BOOTLOADER
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelModules = [
    "i2c-dev"
    "i2c-piix4"
    # Virtual Camera. Custom DroidCam v4l2loopback driver needed for video.
    "v4l2loopback"
    # Virtual Microphone. Custom DroidCam v4l2loopback driver needed for audio.
    "snd-aloop"
  ];
  boot.extraModulePackages = [
    pkgs.linuxPackages.v4l2loopback # Webcam loopback
  ];

  # HOSTNAME
  networking.hostName = "aliyss-bequitta";

  # NETWORKING
  networking.networkmanager.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [80 443 25565];
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
  # sound.enable = true;

  # SERVICES
  services = {
    # Sound
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      wireplumber = {
        enable = true;
        configPackages = [
          (pkgs.writeTextDir "share/wireplumber/bluetooth.lua.d/51-bluez-config.lua" ''
            bluez_monitor.properties = {
            	["bluez5.enable-sbc-xq"] = true,
            	["bluez5.enable-msbc"] = true,
            	["bluez5.enable-hw-volume"] = true,
            	["bluez5.headset-roles"] = "[ hsp_hs hsp_ag hfp_hf hfp_ag ]"
            }
          '')
        ];
      };
    };
    # Bluetooth
    blueman.enable = true;
    # Display
    xserver = {
      enable = true;
      videoDrivers = ["nvidia"];
      displayManager.gdm = {
        enable = false;
        wayland = true;
      };
      # Keymaps
      xkb = {
        variant = "colemak_dh_iso";
        layout = "us";
      };
    };

    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --time-format '%I:%M %p | %a • %h | %F' --cmd Hyprland";
          # command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --time-format '%I:%M %p | %a • %h | %F' --cmd Hyprland";
          # command = "${config.programs.hyprland.package}/bin/Hyprland";
          user = "greeter";
        };
      };
    };

    # USB
    devmon.enable = true;
    gvfs.enable = true;
    udisks2.enable = true;

    # hardware.openrgb = {
    #   enable = true;
    #   package = pkgs.openrgb-with-all-plugins;
    # };
  };

  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal"; # Without this errors will spam on screen
    # Without these bootlogs will spam on screen
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };

  console = {
    useXkbConfig = true;
  };

  security.pam.services.hyprlock = {
    # text = "auth include system-auth";
    text = "auth include login";
    fprintAuth = false;
    enableGnomeKeyring = true;
  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
    rootless = {
      enable = true;
      setSocketVariable = true;
      daemon.settings = {
        runtimes = {
          nvidia = {
            path = "${pkgs.nvidia-docker}/bin/nvidia-container-runtime";
          };
        };
      };
    };
    daemon.settings = {
      userns-remap = "default";
    };
  };

  # DEFAULT USER ACCOUNT
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.aliyss = {
    isNormalUser = true;
    description = "aliyss";
    extraGroups = ["networkmanager" "wheel" "docker" "uinput"];
  };

  # NIXPKGS CONFIG
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.cudaSupport = true;
  # nixpkgs.config.pulseaudio = true;

  # SYSTEM PROFILE PACKAGES
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # Lock
    greetd.tuigreet

    # Terminal
    foot

    # Editor
    ## Vim: for quick configurations in case graphics dies
    neovim
    ## Emacs: for everything else
    ((emacsPackagesFor emacs29-pgtk).emacsWithPackages
      (epkgs: [epkgs.vterm epkgs.lsp-tailwindcss epkgs.dap-mode]))
    ### Emacs: Additional Packages, compatibility with config.org file
    # youtube-dl
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
    nodePackages.prettier
    nodePackages.localtunnel
    ## TailwindCSS
    tailwindcss
    ## Typescript
    typescript
    ## Rust
    rustywind
    rustc
    cargo
    rustfmt
    rust-analyzer
    clippy
    openssl
    pkg-config
    gcc
    ## Flutter
    flutter
    ## Python
    python311
    (python311.withPackages (ps:
      with ps; [
        pip
        # python-openstackclient
      ]))
    ## Configuration Files
    nil
    ## Nix
    nixfmt-classic

    # Hardware
    pavucontrol

    # Browser
    firefox-wayland

    # Theme
    ## Wallpaper for Hyprland
    swww
    ## Cursor
    hyprcursor

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
    ydotool

    gsettings-desktop-schemas
    xdg-user-dirs

    # Gaming
    ## Minecraft Editor
    mcaselector
    ## wine-staging (version with experimental features)
    wineWowPackages.staging
    ## winetricks (all versions)
    winetricks
    ## native wayland support (unstable)
    wineWowPackages.waylandFull

    (lutris.override {
      extraPkgs = pkgs: [
        # List package dependencies here
      ];
    })

    # Camera (DroidCam)
    v4l-utils
    android-tools
    adb-sync
    scrcpy
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # NIX_LD
  programs.nix-ld.enable = true;

  # HYPRLAND
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
    ];
  };

  # SHELL CONFIGURATION
  ## ssh
  programs.ssh.askPassword = "";
  ## zsh
  programs.fish = {
    enable = true;
    shellAliases = {
      ll = "ls -l";
      screenshot = ''grim -g "$(slurp -d)"'';
    };
  };
  ## Default Shell
  users.defaultUserShell = pkgs.fish;
  ## Environment Shell
  environment.shells = with pkgs; [fish];

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
    mwProCapture.enable = true;
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = [pkgs.libvdpau-va-gl];
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
    (nerdfonts.override {fonts = ["JetBrainsMono"];})
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

  # environment.loginShellInit = ''
  #   if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
  #     exec dbus-launch Hyprland
  #   fi
  # '';

  environment.variables = {
    XDG_CURRENT_DESKTOP = "Hyrland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyrland";
    YDOTOOL_SOCKET = "/tmp/ydotools";
    RUST_BACKTRACE = "1";
    LSP_USE_PLISTS = "true";
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
    GSETTINGS_SCHEMA_DIR = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas/";
    WINEPREFIX = "~/.wine";
    VDPAU_DRIVER = "va_gl";
    LIBVA_DRIVER_NAME = "nvidia";
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    # GBM_BACKEND = "nvidia-drm";
  };

  environment.etc = let
    mkEglFile = n: library: let
      suffix = lib.optionalString (library != "wayland") ".1";
      pkg =
        if library != "wayland"
        then config.hardware.nvidia.package
        else pkgs.egl-wayland;

      fileName = "${toString n}_nvidia_${library}.json";
      library_path = "${pkg}/lib/libnvidia-egl-${library}.so${suffix}";
    in {
      "egl/egl_external_platform.d/${fileName}".source = pkgs.writeText fileName (builtins.toJSON {
        file_format_version = "1.0.0";
        ICD = {inherit library_path;};
      });
    };
  in
    {"egl/egl_external_platform.d".enable = false;}
    // mkEglFile 10 "wayland"
    // mkEglFile 15 "gbm"
    // mkEglFile 20 "xcb"
    // mkEglFile 20 "xlib";

  # FLAKE
  nix = {
    settings.experimental-features = ["nix-command" "flakes"];
    registry.nixpkgs.flake = inputs.nixpkgs;
    nixPath = ["nixpkgs=${inputs.nixpkgs}"];
  };
}
