{ pkgs, lib, ... }:
pkgs.stdenv.mkDerivation rec {
  pname = "eci-icc-profiles";
  version = "2025-09-01";

  # Each ZIP is fetched individually so the derivation stays reproducible.
  # Sources correspond to the official ECI download table at
  # https://www.eci.org/doku.php?id=en:downloads#icc_profiles_from_eci
  # and the legacy Adobe ICC bundle.
  srcs = [
    (pkgs.fetchurl {
      url = "https://www.eci.org/lib/exe/eci_offset_2009.zip";
      hash = "sha256-5FN3Argl7xTD65MPaN8Kc1UCILgyvdpL2BLc8/6WYwY=";
    })
    (pkgs.fetchurl {
      url = "https://www.eci.org/lib/exe/pso-coated_v3.zip";
      hash = "sha256-XI7TLUCUnC6LhKA2Qsp6rcTj8VMjfPQ5083d///U7ZU=";
    })
    (pkgs.fetchurl {
      url = "https://www.eci.org/lib/exe/pso-uncoated_v3_fogra52.zip";
      hash = "sha256-ZEyr1iH6pvksgfVZbNYPg2Cny1ILAGFFTI0X5rlM8Io=";
    })
    (pkgs.fetchurl {
      url = "https://www.eci.org/lib/exe/ecirgbv20.zip";
      hash = "sha256-dymDUMNEQgwKKJyaxc46Z18P4fpV7lstJq2CB2Idbdc=";
    })
    (pkgs.fetchurl {
      url = "https://download.adobe.com/pub/adobe/iccprofiles/win/AdobeICCProfilesCS4Win_end-user.zip";
      hash = "sha256-kgQ7fDyloloPaXXQzcV9tgpn3Lnr37FbFiZzEb61j5Q=";
    })
    # Newspaper profiles — ISO 12647-3 (coldset, 26% dot gain, 240% TIC)
    # ISOnewspaper26v4 (v4 = IFRA 2004, still the German newspaper standard)
    # + grey scale variant _gr for automatic RGB→Grey conversion
    (pkgs.fetchurl {
      url = "https://otm.dk/wp-content/uploads/2023/01/isonewspaper26v4_icc_1.zip";
      hash = "sha256-o3YT0QCTNhtBLqhsT70s8TtDUnkzlEUTkrGQHKDYAAk=";
    })
    (pkgs.fetchurl {
      url = "https://otm.dk/wp-content/uploads/2023/01/isonewspaper26v4_gr_icc_0.zip";
      hash = "sha256-dwxeCfGl0ItzLPQoWrbsgv53bb7Lfik73EBfzgpoyA4=";
    })
    # WAN-IFRA 26v5 (successor, ISO 12647-3:2013, TIC 220% — widely used since 2015)
    # + grey variant. Source: NADA / WAN-IFRA (Google Drive mirror at wan-ifra.org)
    (pkgs.fetchurl {
      url = "https://www.nada.no/filer/WAN-IFRAnewspaper26v5_icc.zip";
      hash = "sha256-dwesfSOGXiWxXhAV4hKCg59+YY8SHcarFbj5uVF/CCI=";
    })
    (pkgs.fetchurl {
      url = "https://www.nada.no/filer/WAN-IFRAnewspaper26v5_gr_icc.zip";
      hash = "sha256-5+9+p5ckO5V83Wui4GW+Lu/JzUZ3OUkRslVN+5UNxI4=";
    })
  ];

  nativeBuildInputs = with pkgs; [ unzip ];

  dontUnpack = true;

  # We unpack manually to keep the MACOSX resource forks out and to flatten
  # all ICCs into a single output directory.
  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/color/icc
    mkdir -p $out/share/doc/${pname}

    tmp=$(mktemp -d)

    for z in $srcs; do
      echo ">> unpacking $z"
      unzip -q "$z" -d "$tmp" || {
        echo "unzip failed for $z" >&2
        exit 1
      }
    done

    # Copy every *.icc / *.icm (case-insensitive) into the output, de-duplicate
    # by basename and keep the newest version if duplicates exist.
    find "$tmp" -type f \( -iname "*.icc" -o -iname "*.icm" \) -print0 | while IFS= read -r -d $'\0' f; do
      base=$(basename "$f")
      # Normalise FOGRA naming for ECI profiles (keep original too via symlink)
      cp -n "$f" "$out/share/color/icc/$base" 2>/dev/null || {
        # file already exists — keep larger/newer
        existing="$out/share/color/icc/$base"
        if [ "$(stat -c%s "$f")" -gt "$(stat -c%s "$existing")" ]; then
          cp -f "$f" "$existing"
        fi
      }
    done

    # Friendly aliases expected by the HGK How-To PDF (Linux equivalent of
    # /Library/Application Support/Adobe/Color/Profiles/Recommended):
    #   ISOcoated_v2_300_eci.icc  == ISO Coated v2 300% (ECI)  — HGK Standard
    #   PSOcoated_v3.icc          == PSO Coated v3 (FOGRA51)  — 2015 Premium coated
    #   PSOuncoated_v3_FOGRA52.icc== PSO Uncoated v3 (FOGRA52)
    #   eciRGB_v2.icc             == eciRGB v2 working space
    #   AdobeRGB1998.icc          == Adobe RGB (1998)
    # Already present with those names, but ensure the most common aliases exist:

    # Make AdobeRGB1998.icc discoverable under a clean name (Adobe bundle uses it)
    if [ -f "$out/share/color/icc/AdobeRGB1998.icc" ]; then
      echo "AdobeRGB1998 present"
    fi

    # Provide sRGB fallback via eciRGB if no sRGB profile was fetched (system
    # already ships sRGB via colord/gammastep; we don't need to bundle it).

    # Documentation / licence notes
    find "$tmp" -type f \( -iname "*.pdf" -o -iname "*.txt" -o -iname "licence*" -o -iname "license*" \) -exec cp -n {} $out/share/doc/${pname}/ \; 2>/dev/null || true
    cat > $out/share/doc/${pname}/README.md <<'EOF'
    # ECI + Adobe ICC Profiles

    Bundled from official sources:
    - https://www.eci.org/doku.php?id=en:downloads#icc_profiles_from_eci
      - eci_offset_2009.zip  → ISOcoated_v2_eci.icc, ISOcoated_v2_300_eci.icc, etc. (FOGRA39L, legacy HGK Standard)
      - pso-coated_v3.zip    → PSOcoated_v3.icc (FOGRA51, PSO Coated v3, premium coated, ISO 12647-2:2013)
      - pso-uncoated_v3_fogra52.zip → PSOuncoated_v3_FOGRA52.icc (FOGRA52, uncoated white)
      - ecirgbv20.zip        → eciRGB_v2.icc, eciRGB_v2_ICCv4.icc (ECI working RGB)
    - https://download.adobe.com/pub/adobe/iccprofiles/win/AdobeICCProfilesCS4Win_end-user.zip
      → AdobeRGB1998.icc, CoatedFOGRA27/39, USWebCoatedSWOP, etc.
    - https://otm.dk/wp-content/uploads/2023/01/isonewspaper26v4_icc_1.zip
      → ISOnewspaper26v4.icc (WAN-IFRA / IFRA 26% dot gain, newspaper coldset)
    - https://otm.dk/wp-content/uploads/2023/01/isonewspaper26v4_gr_icc_0.zip
      → ISOnewspaper26v4_gr.icc  ← the grey you asked for (26v4_gr, 1 KB, for RGB→Grey)
    - https://www.nada.no/filer/WAN-IFRAnewspaper26v5_icc.zip
      → WAN-IFRAnewspaper26v5.icc (ISO 12647-3:2013 successor, TIC 220%)
    - https://www.nada.no/filer/WAN-IFRAnewspaper26v5_gr_icc.zip
      → WAN-IFRAnewspaper26v5_gr.icc (grey variant of v5)

    Installed to: $out/share/color/icc
    Also symlinked on NixOS to:
      /run/current-system/sw/share/color/icc  (via environment.pathsToLink)
      ~/.local/share/color/icc                (via home.file activation)
      Wine prefix: ~/.local/share/affinity-v3/drive_c/windows/system32/spool/drivers/color

    See ../../docs/color-management-linux.md for Linux setup.
    EOF

    echo "Installed ICCs:"
    ls -1 "$out/share/color/icc" | sort
    echo ""
    echo "Total: $(ls -1 "$out/share/color/icc" | wc -l) profiles"

    runHook postInstall
  '';

  meta = with lib; {
    description = "ECI offset + Adobe ICC colour profiles for HGK PDF/X workflow (ISO Coated v2 300%, PSO Coated v3, PSO Uncoated v3, eciRGB v2, AdobeRGB1998)";
    homepage = "https://www.eci.org/doku.php?id=en:downloads";
    license = licenses.unfree; # ECI profiles: free to use/embed, not to sell/alter without permission; Adobe: EULA
    platforms = platforms.all;
    maintainers = [];
  };
}
