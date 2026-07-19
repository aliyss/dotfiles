{ theme, lib, ... }: ''
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
alias bequitta="ssh -p 22 aliyss@aliyss-bequitta"
alias tailscale="tailscale-cli"
''
