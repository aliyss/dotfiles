{ config, lib, pkgs, ... }:
with lib;
let
  cfgSystem = config.aliyss.adobeFonts;
  cfgProfile = config.aliyss.profiles;
  # Use same derivation as system – keep in sync via adobeFonts.enable
  adobeFonts = pkgs.callPackage ../../packages/adobe-fonts { };
  enabled = cfgSystem.enable && (cfgProfile.creative || true);
in
mkIf enabled {
  # User-local fonts for native Linux apps (fontconfig) – we now keep the
  # working local copy in ~/.local/share/fonts/adobe (24 GDI-split families,
  # typographic Auto Pro) instead of symlinking the Nix store directly.
  # The Nix store still provides fonts.packages for system, but the user
  # copy is managed by the activation below to avoid overwriting the
  # manually fixed GDI-split fonts on each home-manager switch.
  # home.file.".local/share/fonts/adobe" is intentionally disabled – see activation.

  # Affinity on Linux (affinity-nix, Wine). Wine's font subsystem looks in
  # drive_c/windows/Fonts  and registers via HKLM\Software\Microsoft\Windows NT\CurrentVersion\Fonts.
  # Fontconfig bridging is unreliable for CFF OTF, so we explicitly symlink/copy into each prefix.
  home.activation.adobeFontsWine = hm.dag.entryAfter ["writeBoundary"] ''
    set -euo pipefail
    ADOBE_SRC="${adobeFonts}/share/fonts/opentype"
    LOCAL_ADOBE="$HOME/.local/share/fonts/adobe"
    # Ensure local adobe has the working GDI-split fonts (typographic Auto Pro, GDI split per style)
    # If not, generate them from ADOBE_SRC using the fixed retag logic (GDI split, distinct weights)
    # Generic: works for any number of fonts (24 for whl2slc, more if multiple kits)
    expected=$(ls -1 "$ADOBE_SRC"/*.otf 2>/dev/null | wc -l)
    if [ ! -d "$LOCAL_ADOBE" ] || [ "$(ls -1 "$LOCAL_ADOBE"/*.otf 2>/dev/null | wc -l)" -ne "$expected" ]; then
      echo "adobe-fonts: generating local GDI-split fonts in $LOCAL_ADOBE..."
      mkdir -p "$LOCAL_ADOBE"
      ${pkgs.python3.withPackages (ps: [ ps.fonttools ])}/bin/python3 - "$ADOBE_SRC" "$LOCAL_ADOBE" <<'PYEOF2'
import pathlib, sys, re, glob, os
from fontTools.ttLib import TTFont
src_dir = pathlib.Path(sys.argv[1])
dst_dir = pathlib.Path(sys.argv[2])
PS_TO_STYLE = {
    "AutoPro-Light": "Light", "AutoPro-LightSmallCaps": "Light Small Caps",
    "AutoPro-LightItalic1": "Light Italic 1", "AutoPro-LightItalic2": "Light Italic 2", "AutoPro-LightItalic3": "Light Italic 3", "AutoPro-LightItalicSmallCaps": "Light Italic Small Caps",
    "AutoPro-Regular": "Regular", "AutoPro-RegularSmallCaps": "Regular Small Caps",
    "AutoPro-RegularItalic1": "Regular Italic 1", "AutoPro-RegularItalic2": "Regular Italic 2", "AutoPro-RegularItalic3": "Regular Italic 3", "AutoPro-RegularItalicSmallCaps": "Regular Italic Small Caps",
    "AutoPro-Bold": "Bold", "AutoPro-BoldSmallCaps": "Bold Small Caps",
    "AutoPro-BoldItalic1": "Bold Italic 1", "AutoPro-BoldItalic2": "Bold Italic 2", "AutoPro-BoldItalic3": "Bold Italic 3", "AutoPro-BoldItalicSmallCaps": "Bold Italic Small Caps",
    "AutoPro-Black": "Black", "AutoPro-BlackSmallCaps": "Black Small Caps",
    "AutoPro-BlackItalic1": "Black Italic 1", "AutoPro-BlackItalic2": "Black Italic 2", "AutoPro-BlackItalic3": "Black Italic 3", "AutoPro-BlackItalicSmallCaps": "Black Italic Small Caps",
}
weight_map = {"Light": 300, "Regular": 400, "Bold": 700, "Black": 900}
variant_offset = {
    "Light": 0, "Light Small Caps": 1, "Light Italic 1": 2, "Light Italic 2": 3, "Light Italic 3": 4, "Light Italic Small Caps": 5,
    "Regular": 0, "Regular Small Caps": 1, "Regular Italic 1": 2, "Regular Italic 2": 3, "Regular Italic 3": 4, "Regular Italic Small Caps": 5,
    "Bold": 0, "Bold Small Caps": 1, "Bold Italic 1": 2, "Bold Italic 2": 3, "Bold Italic 3": 4, "Bold Italic Small Caps": 5,
    "Black": 0, "Black Small Caps": 1, "Black Italic 1": 2, "Black Italic 2": 3, "Black Italic 3": 4, "Black Italic Small Caps": 5,
}
for ps in sorted(PS_TO_STYLE.keys()):
    src = src_dir / f"{ps}.otf"
    if not src.exists():
        continue
    style = PS_TO_STYLE[ps]
    tt = TTFont(str(src))
    # Distinct weight
    w = 400
    for k,v in weight_map.items():
        if k in style:
            w = v
            break
    w += variant_offset[style] * 10
    if w > 1000:
        w = 1000
    # GDI split: 1 = Auto Pro + style (unique), 2=Regular, 16=Auto Pro, 17=style, no 21/22
    gdi_family = f"Auto Pro {style}" if style != "Regular" else "Auto Pro"
    name = tt['name']
    for nid in [1,2,16,17,21,22]:
        for plat, enc, lang in [(1,0,0),(3,1,1033)]:
            try:
                name.removeNames(nameID=nid, platformID=plat, platEncID=enc, langID=lang)
            except: pass
    for plat, enc, lang in [(1,0,0),(3,1,1033)]:
        name.setName(gdi_family, 1, plat, enc, lang)
        name.setName("Regular", 2, plat, enc, lang)
        name.setName("Auto Pro", 16, plat, enc, lang)
        name.setName(style, 17, plat, enc, lang)
    # Keep other names (0,3,4,5,6) as is, but ensure 4 and 6 are correct
    # Update CFF
    try:
        cff = tt['CFF '].cff
        cff.fontNames = [ps]
        top = cff.topDictIndex[0]
        top.FamilyName = gdi_family
        top.FullName = style
    except: pass
    # OS/2
    try:
        tt['OS/2'].usWeightClass = w
        tt['OS/2'].fsSelection = 64 | 256
        if tt['OS/2'].version < 4:
            tt['OS/2'].version = 4
        tt['head'].macStyle = 0
    except: pass
    dst = dst_dir / f"{ps}.otf"
    tt.save(str(dst))
    print(f"  {ps} -> {gdi_family} / {style} w{w}")
PYEOF2
      ${pkgs.fontconfig}/bin/fc-cache -f "$LOCAL_ADOBE" 2>/dev/null || true
    fi
    # Use local adobe for Wine sync if it has the expected count, otherwise Nix store
    if [ -d "$LOCAL_ADOBE" ] && [ "$(ls -1 "$LOCAL_ADOBE"/*.otf 2>/dev/null | wc -l)" -eq "$expected" ]; then
      ADOBE_SRC="$LOCAL_ADOBE"
    fi
    echo "adobe-fonts: syncing $ADOBE_SRC to Wine prefixes..."

    for prefix in "$HOME/.local/share/affinity" "$HOME/.local/share/affinity-v3" "$HOME/.wine"; do
      if [ -d "$prefix" ]; then
        dest="$prefix/drive_c/windows/Fonts"
        mkdir -p "$dest"
        for f in "$ADOBE_SRC"/*.otf; do
          [ -f "$f" ] || continue
          base=$(basename "$f")
          # Prefer symlink (Nix store is stable), fallback to copy on exotic FS
          if [ ! -e "$dest/$base" ]; then
            ln -sf "$f" "$dest/$base" 2>/dev/null || cp -n "$f" "$dest/$base" 2>/dev/null || true
          else
            # Update stale symlink if source changed (hash bump)
            if [ -L "$dest/$base" ] && [ "$(readlink "$dest/$base")" != "$f" ]; then
              ln -sf "$f" "$dest/$base" 2>/dev/null || true
            fi
          fi
        done
        echo "adobe-fonts: synced $(ls -1 "$ADOBE_SRC" | wc -l) fonts to $dest"

        # Register in Wine registry – Affinity enumerates via
        # HKLM\Software\Microsoft\Windows NT\CurrentVersion\Fonts and
        # HKLM\Software\Wine\Fonts\External Fonts (Z:\nix\store\...). Without this,
        # only fonts present at prefix creation (e.g. JetBrainsMono) appear, so
        # Black Italic 2/3 were invisible until now. We patch system.reg directly
        # (wine reg is not in PATH for affinity-nix) and kill wineserver to reload.
        if [ -f "$prefix/system.reg" ]; then
          # Backup once
          [ -f "$prefix/system.reg.bak.adobe" ] || cp "$prefix/system.reg" "$prefix/system.reg.bak.adobe"
          for f in "$ADOBE_SRC"/*.otf; do
            [ -f "$f" ] || continue
            base=$(basename "$f" .otf)
            # Derive Family + Style via fontconfig – after GDI split, family is "Auto Pro,Auto Pro Black Italic 1" (typographic,GDI) and style is "Black Italic 1,Regular"
            # Take the last (GDI) entry for Wine registry: GDI family + GDI style (each font is its own GDI family with Regular)
            family_raw=$(${pkgs.fontconfig}/bin/fc-query -f "%{family}\n" "$f" | head -n1)
            style_raw=$(${pkgs.fontconfig}/bin/fc-query -f "%{style}\n" "$f" | head -n1)
            # Split by comma and take last
            family=$(echo "$family_raw" | tr ',' '\n' | tail -n1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            style=$(echo "$style_raw" | tr ',' '\n' | tail -n1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            # Fallback if empty
            [ -z "$family" ] && family=$(echo "$family_raw" | cut -d',' -f1 | xargs)
            [ -z "$style" ] && style=$(echo "$style_raw" | cut -d',' -f1 | xargs)
            # Wine key name: "Family Style (TrueType)" – matches JetBrains entries (GDI family + GDI style)
            key="$family $style (TrueType)"
            # Z: path for Nix store (Wine maps Z: -> /) – double \\ for Wine registry (\\ -> \ on Windows)
            winpath=$(echo "$f" | sed 's|/|\\\\|g; s|^\\\\|Z:\\\\|')
            # Add to all relevant Fonts keys if not already present – check per-section, not globally
            # Wine has 5 Fonts sections: Windows, Windows NT, Wow6432Node variants, and External Fonts
            # Previously we only handled 2 and missed the others, and used single \ instead of \\ for registry
            ${pkgs.python3}/bin/python3 - "$prefix/system.reg" "$key" "$winpath" <<'PYEOF'
import sys, pathlib, re
reg_path, key, winpath = sys.argv[1], sys.argv[2], sys.argv[3]
text = pathlib.Path(reg_path).read_text(errors="ignore")
# Ensure all relevant sections exist (with timestamp variant)
def ensure_section(sec_name):
    global text
    if sec_name not in text:
        text += f"\n{sec_name} 0\n"
        return
ensure_section(r"[Software\Microsoft\Windows\CurrentVersion\Fonts]")
ensure_section(r"[Software\Microsoft\Windows NT\CurrentVersion\Fonts]")
ensure_section(r"[Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Fonts]")
ensure_section(r"[Software\Wow6432Node\Microsoft\Windows NT\CurrentVersion\Fonts]")
ensure_section(r"[Software\Wine\Fonts\External Fonts]")
for sec_name in [r"[Software\Microsoft\Windows\CurrentVersion\Fonts]", r"[Software\Microsoft\Windows NT\CurrentVersion\Fonts]", r"[Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Fonts]", r"[Software\Wow6432Node\Microsoft\Windows NT\CurrentVersion\Fonts]", r"[Software\Wine\Fonts\External Fonts]"]:
    m = re.search(re.escape(sec_name) + r"[^\n]*\n", text)
    if not m:
        continue
    header = m.group(0)
    m_block = re.search(re.escape(sec_name) + r"[^\n]*\n(.*?)(?=\n\[|$)", text, re.S)
    block = m_block.group(1) if m_block else ""
    if f'"{key}"=' in block:
        # Update stale path if store hash bumped
        import re as _re
        m_line = _re.search(_re.escape(f'"{key}"') + r'="([^"]*)"', block)
        if m_line and m_line.group(1) != winpath:
            old = f'"{key}"="{m_line.group(1)}"'
            new = f'"{key}"="{winpath}"'
            print(f"adobe-fonts: updating \"{key}\" {m_line.group(1)} -> {winpath} in {sec_name}", file=sys.stderr)
            text = text.replace(old, new, 1)
        else:
            continue
    else:
        print(f"adobe-fonts: registering \"{key}\" -> {winpath} in {sec_name} ({reg_path})", file=sys.stderr)
        idx = text.index(header) + len(header)
        insert = f'"{key}"="{winpath}"\n'
        text = text[:idx] + insert + text[idx:]
pathlib.Path(reg_path).write_text(text)
PYEOF
          done
          # Invalidate Wine font cache – will regenerate on next Affinity start
          rm -f "$prefix/.win32-font-cache" "$prefix/drive_c/windows/Fonts/*.cache" 2>/dev/null || true
        fi
      fi
    done
    # Kill wineserver for this prefix so Affinity re-reads registry on next launch
    for prefix in "$HOME/.local/share/affinity" "$HOME/.local/share/affinity-v3"; do
      if [ -d "$prefix" ]; then
        # wineserver is per-prefix via WINESERVER env; try generic kill
        wineserver -k 2>/dev/null || true
        # Also touch to force reload
        touch "$prefix/system.reg" 2>/dev/null || true
      fi
    done

    # Refresh fontconfig caches for native and Wine
    mkdir -p "$HOME/.local/share/fonts"
    ${pkgs.fontconfig}/bin/fc-cache -f "$HOME/.local/share/fonts" 2>/dev/null || true
    ${pkgs.fontconfig}/bin/fc-cache -f "$HOME/.local/share/fonts/adobe" 2>/dev/null || true

    # Verify at least the Text_idml used fonts are present
    for ps in "AutoPro-Black.otf" "AutoPro-BlackItalic1.otf" "AutoPro-BlackItalic2.otf"; do
      if [ ! -f "$HOME/.local/share/fonts/adobe/$ps" ] && [ ! -f "$HOME/.local/share/fonts/$ps" ]; then
        echo "warn: $ps missing in ~/.local/share/fonts/adobe (HM adobeFontsWine)" >&2
      fi
      for prefix in "$HOME/.local/share/affinity-v3" "$HOME/.local/share/affinity"; do
        if [ -d "$prefix" ] && [ ! -e "$prefix/drive_c/windows/Fonts/$ps" ]; then
          echo "warn: $ps missing in $prefix/drive_c/windows/Fonts" >&2
        fi
      done
    done
  '';
}
