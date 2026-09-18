{ lib, stdenv, curl, cacert, python3, kitIds ? ["whl2slc"], kitId ? null }:
let
  pythonWithFonts = python3.withPackages (ps: [ ps.fonttools ]);
  # kitIds for your Adobe Fonts web projects – https://use.typekit.net/<kitId>.css
  # Single kit whl2slc contains the full Auto Pro family (24 styles) as used in
  # ~/Downloads/Text d_Auto Pro_Black.idml. Add more Ids here if you have multiple kits.
  # For backwards compat, also accept single kitId.
  allKitIds = if kitId != null then [kitId] else kitIds;
  kitIdStr = builtins.head allKitIds;
in
stdenv.mkDerivation rec {
  pname = "adobe-fonts-${builtins.concatStringsSep "-" allKitIds}";
  version = "2026-09-18";

  # Fixed-output derivation – fetches from Adobe at build time (license requires fetch, not vendor).
  # To update when Adobe rotates af/ hashes: ./update.sh whl2slc  or  nix build --rebuild (copy expected hash).
  outputHashAlgo = "sha256";
  outputHashMode = "recursive";
  outputHash = "sha256-3TMC5P12MgROJdykmIn5UUtE1sQtpPpW9V3qjPQrX8Y=";

  nativeBuildInputs = [ curl cacert pythonWithFonts ];

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    export SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt
    export CURL_CA_BUNDLE=$SSL_CERT_FILE

    echo ">> Fetching Typekit CSS for kits ${builtins.concatStringsSep " " allKitIds}..."
    mkdir -p $TMPDIR/work
    > "$TMPDIR/kit.css"
    for kit in ${builtins.concatStringsSep " " allKitIds}; do
      echo ">> Fetching https://use.typekit.net/$kit.css"
      curl -fsSL -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36" \
           -H "Accept: text/css,*/*;q=0.1" \
           "https://use.typekit.net/$kit.css" -o "$TMPDIR/kit-$kit.css"
      echo "--- $kit.css head ---"
      head -n 20 "$TMPDIR/kit-$kit.css" || true
      purl=$(grep -o 'https://p\.typekit\.net[^"]*\.css[^"]*' "$TMPDIR/kit-$kit.css" | head -n1 || true)
      if [ -n "$purl" ]; then
        echo ">> Also fetching $purl"
        curl -fsSL -H "User-Agent: Mozilla/5.0" "$purl" -o "$TMPDIR/p-$kit.css" || true
        cat "$TMPDIR/p-$kit.css" >> "$TMPDIR/kit-$kit.css" 2>/dev/null || true
      fi
      cat "$TMPDIR/kit-$kit.css" >> "$TMPDIR/kit.css"
      echo "" >> "$TMPDIR/kit.css"
    done

    echo "--- combined kit.css head ---"
    head -n 40 "$TMPDIR/kit.css" || true
    wc -l "$TMPDIR/kit.css"

    # Parse @font-face blocks to extract family/weight/style and opentype URLs
    # This preserves the association between the CSS declarations and the font files,
    # so we can derive the desktop family/style without hardcoding PS_TO_META.
    echo ">> Parsing @font-face blocks for opentype URLs and metadata..."
    ${pythonWithFonts}/bin/python3 ${./parse_css.py} "$TMPDIR/kit.css" "$TMPDIR/urls.txt" "$TMPDIR/mapping.json"
    cat "$TMPDIR/mapping.json" | head -n 100
    wc -l "$TMPDIR/urls.txt"
    cat "$TMPDIR/urls.txt"

    if [ "$(wc -l < "$TMPDIR/urls.txt")" -eq 0 ]; then
      echo "error: no font URLs found in kit.css" >&2
      cat "$TMPDIR/kit.css" >&2
      exit 1
    fi

    mkdir -p "$TMPDIR/raw"
    i=0
    while IFS= read -r url; do
      [ -z "$url" ] && continue
      i=$((i+1))
      # Use first kit as Referer (all kits share same primer)
      kit_first="${kitIdStr}"
      echo ">> [$i] fetching $url"
      curl -fsSL -H "User-Agent: Mozilla/5.0" -H "Origin: https://localhost" -H "Referer: https://use.typekit.net/$kit_first.css" \
           "$url" -o "$TMPDIR/raw/$i.otf"
      head -c 4 "$TMPDIR/raw/$i.otf" | od -An -tx1 | tr -d ' \n' | grep -q "4f54544f\|774f4632" || {
        echo "warn: $i not OTF/wOF2, dumping head"
        head -c 200 "$TMPDIR/raw/$i.otf" | od -An -tx1 | head
      }
    done < "$TMPDIR/urls.txt"

    echo ">> Downloaded $(ls -1 "$TMPDIR/raw" | wc -l) files"
    ls -lh "$TMPDIR/raw"

    # Retag: fix name table (Typekit web OTF has broken names: family="", ps="-")
    # Use the CSS-derived mapping (family/weight/style from @font-face) plus CFF PS for accurate desktop names
    # The mapping.json is derived at build time from the fetched CSS, so any future kit with more fonts will be handled without hardcoding
    mkdir -p $out/share/fonts/opentype
    ${pythonWithFonts}/bin/python3 ${./retag.py} "$TMPDIR/raw" "$out/share/fonts/opentype" "$TMPDIR/mapping.json"

    echo ">> Installed fonts:"
    ls -1 "$out/share/fonts/opentype" | sort
    echo "Total: $(ls -1 "$out/share/fonts/opentype" | wc -l) fonts"

    # Validate against IDML expectations (at least the 3 used styles must exist)
    for needed in "AutoPro-Black.otf" "AutoPro-BlackItalic1.otf" "AutoPro-BlackItalic2.otf"; do
      if [ ! -f "$out/share/fonts/opentype/$needed" ]; then
        echo "error: expected $needed missing" >&2
        echo "Have:" >&2
        ls -1 "$out/share/fonts/opentype" >&2
        exit 1
      fi
    done

    # No truetype duplicate – opentype is sufficient; truetype copy only doubled fc-list entries (24→48) and caused the 27 vs 24 duplicate count

    # Provide fontconfig cache hint
    mkdir -p $out/share/doc/${pname}
    cp "$TMPDIR/kit.css" $out/share/doc/${pname}/kit.css 2>/dev/null || true
    cat > $out/share/doc/${pname}/README.md <<EOF
# Adobe Fonts – Auto Pro (kit ${kitIdStr})

Fetched from https://use.typekit.net/${kitIdStr}.css
Version ${version}. Retagged to match IDML PostScriptNames (family Auto Pro, 24 styles).

Sources:
- CSS: https://use.typekit.net/${kitIdStr}.css
- Fonts: https://use.typekit.net/af/.../a? (opentype)
- IDML reference: ~/Downloads/Text d_Auto Pro_Black.idml (Resources/Fonts.xml)

Installed to: \$out/share/fonts/opentype (~24 OTF)
Also available via NixOS fonts.packages (fontconfig) and HM Wine sync to affinity prefixes.
EOF

    runHook postInstall
  '';

  meta = with lib; {
    description = "Adobe Fonts – Auto Pro (Typekit kit ${kitIdStr}) – retagged for InDesign/Affinity IDML compatibility";
    homepage = "https://use.typekit.net/${kitIdStr}.css";
    license = licenses.unfree; # Adobe Fonts EULA – fetch at build, not redistributable via cache
    platforms = platforms.all;
  };
}
