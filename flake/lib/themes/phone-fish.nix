{
  theme,
  lib,
  ...
}: ''
  set fish_greeting
  fish_vi_key_bindings

  if status is-interactive
    set fish_cursor_default     block      blink
    set fish_cursor_insert      line       blink
    set fish_cursor_replace_one underscore blink
    set fish_cursor_visual      block

    function fish_user_key_bindings
      fish_default_key_bindings -M insert
      fish_vi_key_bindings --no-erase insert
    end
  end

# Dynamic alias using MagicDNS name
alias aliyss-termux="ssh -p 22 aliyss@aliyss-bequitta"
alias bequitta="aliyss-termux"
alias tailscale="tailscale-cli"

# Update commands (mirror the desktop's update-system / update-home)
alias update-system="bash ~/dotfiles/aliyss-phone/update-system.sh"
alias update-home="bash ~/dotfiles/aliyss-phone/update-home.sh"
alias update-phone="bash ~/dotfiles/aliyss-phone/update-home.sh"
alias upgrade-flake="nix flake update --flake ~/dotfiles/flake"

  # Ensure essential services and packages are running/installed
  if status is-interactive
      # Start SSH daemon if not running
      if not pgrep -x "sshd" >/dev/null
          sshd
      end

      # Auto-install missing packages
      if not command -v nvim >/dev/null
          echo "Installing missing package: neovim..."
          pkg install -y neovim
      end
      if not command -v htop >/dev/null
          echo "Installing missing package: htop..."
          pkg install -y htop
      end
  end
''