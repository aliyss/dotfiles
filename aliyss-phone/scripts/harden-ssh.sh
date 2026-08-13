#!/usr/bin/env fish

set PHONE_IP (tailscale ip -4 aliyss-termux)

if test -z "$PHONE_IP"
    echo "Error: Could not find aliyss-termux on Tailscale."
    exit 1
end

set PAYLOAD "
sshd_config=\"\$PREFIX/etc/ssh/sshd_config\"

sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' \"\$sshd_config\"
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' \"\$sshd_config\"
sed -i 's/^#*ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' \"\$sshd_config\"

if ! grep -q '^PasswordAuthentication' \"\$sshd_config\"; then
    printf '%s\n' 'PasswordAuthentication no' 'PermitRootLogin no' 'ChallengeResponseAuthentication no' 'MaxAuthTries 3' >> \"\$sshd_config\"
fi

chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

pkill sshd; sshd
"

echo "Hardening SSH on $PHONE_IP..."
printf '%s' $PAYLOAD | ssh -o StrictHostKeyChecking=accept-new -p 8022 aliyss@$PHONE_IP 'bash -s'

echo "Done! Verify key-only login still works: ssh -p 8022 aliyss@aliyss-termux"