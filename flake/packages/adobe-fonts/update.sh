#!/usr/bin/env bash
# Update hash for adobe-fonts FOD after kit changes.
# Usage: ./update.sh [kitId]
# Requires: nix, curl
set -euo pipefail
KIT="${1:-whl2slc}"
DIR="$(cd "$(dirname "$0")" && pwd)"
FILE="$DIR/default.nix"

echo ">> Fetching kit $KIT for hash preview..."
curl -fsSL -H "User-Agent: Mozilla/5.0" "https://use.typekit.net/${KIT}.css" -o /tmp/kit.css
echo "   kit.css sha256: $(nix hash file /tmp/kit.css 2>/dev/null || sha256sum /tmp/kit.css | cut -d' ' -f1)"
echo ""

# Try to build with placeholder hash to get expected hash
echo ">> Building (will fail with correct hash if placeholder outdated)..."
set +e
out=$(nix build --impure --expr "(import <nixpkgs> {}).callPackage $FILE { kitId = \"$KIT\"; }" 2>&1)
rc=$?
echo "$out"
set -e

# Extract expected hash from error
if echo "$out" | grep -q "got:"; then
  got=$(echo "$out" | grep -o 'got:[[:space:]]*sha256-[A-Za-z0-9+/=]*' | head -n1 | awk '{print $2}')
  if [ -n "$got" ]; then
    echo ""
    echo ">> Updating $FILE outputHash to $got"
    # Replace outputHash line
    sed -i "s|outputHash = \".*\";|outputHash = \"$got\";|" "$FILE"
    echo "   Done. Verify with: nix build .#adobe-fonts  (or nixos-rebuild)"
  fi
else
  if [ $rc -eq 0 ]; then
    echo ">> Build succeeded – hash already correct."
  else
    echo ">> Could not extract hash automatically. Run manually:"
    echo "   nix build --impure --expr \"(import <nixpkgs> {}).callPackage $FILE { kitId = \\\"$KIT\\\"; }\" 2>&1 | grep got:"
  fi
fi
