#!/usr/bin/env fish

set PHONE_IP (tailscale ip -4 aliyss-termux)

if test -z "$PHONE_IP"
    echo "Error: Could not find aliyss-termux on Tailscale."
    exit 1
end

echo "Syncing to $PHONE_IP..."

# Sync colors
scp -P 8022 ~/.config/aliyss-phone/colors.properties aliyss@$PHONE_IP:~/.termux/colors.properties

# Sync fish config
scp -P 8022 ~/.config/aliyss-phone/config.fish aliyss@$PHONE_IP:~/.config/fish/config.fish

# Reload Termux
ssh -p 8022 aliyss@$PHONE_IP "termux-reload-settings"

# Remove default Termux login message (motd)
ssh -p 8022 aliyss@$PHONE_IP "touch ~/.hushlogin"

echo "Done!"
