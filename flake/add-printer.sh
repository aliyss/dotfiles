#!/usr/bin/env bash
set -euo pipefail

# Generic SMB printer setup.
# Site config is sourced from ~/Documents/printers/<site>/.env:
#   PRINTER_SERVER, PRINTER_SHARE, PRINTER_DESC
# Credentials are prompted and stored only in root-owned /etc/cups/printers.conf.

if [ $# -ne 1 ] && [ $# -ne 2 ]; then
  echo "usage: $0 <username> [site]" >&2
  echo "  site defaults to 'default' -> ~/Documents/printers/default/.env" >&2
  exit 1
fi
USERNAME="$1"
SITE="${2:-default}"

ENV_FILE="/home/aliyss/Documents/printers/$SITE/.env"
if [ -f "$ENV_FILE" ]; then
  set -a; source "$ENV_FILE"; set +a
fi

# Require env vars — no hardcoded defaults so repo stays free of site data.
: "${PRINTER_SERVER:?Set PRINTER_SERVER in $ENV_FILE}"
: "${PRINTER_SHARE:?Set PRINTER_SHARE in $ENV_FILE}"
SERVER="$PRINTER_SERVER"
SHARE="$PRINTER_SHARE"
DESC="${PRINTER_DESC:-$SHARE}"

# smbspool needs /etc/samba/smb.conf (NixOS only ships it with samba server)
if [ ! -f /etc/samba/smb.conf ]; then
  echo "Creating minimal /etc/samba/smb.conf (required by smbspool)..."
  mkdir -p /etc/samba
  printf '[global]\n' > /etc/samba/smb.conf
fi

PPD=$(compgen -G "/nix/store/*-hplip-*/share/cups/model/HP/hp-laserjet_700_m712-ps.ppd.gz" | head -1)
if [ -z "$PPD" ]; then
  echo "hplip PPD not found in the store — rebuild with the printing module first." >&2
  exit 1
fi

read -rsp "Password for $USERNAME: " PASSWORD
echo

lpadmin -p "$SHARE" \
  -v "smb://$USERNAME:$PASSWORD@$SERVER/$SHARE" \
  -P "$PPD" \
  -D "$DESC" \
  -E

echo "Printer '$SHARE' added. Test with:  lp -d $SHARE <file>   (VPN must be up if remote)"
echo "Delete it again with:                sudo lpadmin -x $SHARE"
