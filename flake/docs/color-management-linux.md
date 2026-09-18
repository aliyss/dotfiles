# Linux Color Management — NixOS / `~/.config/flake` — HGK PDF/X Workflow

*Linux adaptation of `IDCE_HowTo_PDF-Workflow_RZ-DE.pdf` (HGK | IDCE | Pat Löffel | 09.24) · Affinity by Canva v3 on NixOS · 2026-09-01*

> This document is the **Linux / NixOS** counterpart to the original macOS/Windows How-To (`IDCE_HowTo_PDF-Workflow_RZ-DE.md`). It shows how every Adobe step (`Bearbeiten → Farbeinstellungen`, Bridge Sync, InDesign `PDF/X-4`, Photoshop Proof) maps to **Linux + Affinity v3** and how all ICC profiles are **declaratively installed** via your `~/.config/flake`.

---

## 1. What Changes on Linux

| Original (macOS / Windows) | Linux / NixOS + Affinity v3 | Path on this system |
|---|---|---|
| `Download → .zip → /Library/Application Support/Adobe/Color/Profiles/Recommended` | **Nix package `eci-icc-profiles`** unpacks to `/nix/store/.../share/color/icc` → symlinked to `~/.local/share/color/icc`, `/run/current-system/sw/share/color/icc`, and Wine `drive_c/windows/system32/spool/drivers/color` | `~/.config/flake/packages/eci-icc-profiles/default.nix` |
| `Photoshop → Bearbeiten → Farbeinstellungen → Europa, Druckvorstufen 3` | `Affinity → Einstellungen → Farbe` (global for Pixel/Vector/Layout Studios) | see §2 |
| `Bridge → Creative Suite-Farbeinstellungen → Synchronisieren` | **Entfällt** — Affinity is one unified app, all Studios share `Einstellungen → Farbe` | — |
| `InDesign → PDF-Vorgaben → PDF/X-4:2008` | `Layout Studio → Dokument-Setup + Datei → Export → PDF/X-4 / PDF (press ready)` | see §4 |
| `Photoshop → Ansicht → Proof einrichten → cmd+Y` | `Pixel Studio → Ebene → Neue Anpassungsebene → Soft Proof` → toggle eye | see §5 |

---

## 2. ICC Profiles — What Is Installed & Where

### 2.1 Package: `eci-icc-profiles` (`~/.config/flake/packages/eci-icc-profiles/default.nix`)

Declarative Nix derivation that fetches **official ECI + Adobe** bundles and flattens all `*.icc` into `$out/share/color/icc` (38 profiles).

**Fetched with workable direct links (verified 2026-09-01):**

| Profile pack | Direct link (clickable, `lib/exe/` — the `/_media/...` URL requires a session and returns HTML) | Contents relevant for HGK |
|---|---|---|
| **ECI Offset 2009** (legacy HGK Standard) | <https://www.eci.org/lib/exe/eci_offset_2009.zip> | `ISOcoated_v2_eci.icc` (FOGRA39L), **`ISOcoated_v2_300_eci.icc` (HGK Standard — 300% TAC, FOGRA39L)**, `PSO_LWC_*`, `PSO_Uncoated_*`, `SC_paper_eci` etc. — 12 ICCs |
| **PSO Coated v3** (FOGRA51, Premium coated, ISO 12647-2:2013) | <https://www.eci.org/lib/exe/pso-coated_v3.zip> | `PSOcoated_v3.icc` |
| **PSO Uncoated v3 (FOGRA52)** (uncoated white) | <https://www.eci.org/lib/exe/pso-uncoated_v3_fogra52.zip> | `PSOuncoated_v3_FOGRA52.icc` |
| **eciRGB v2** (ECI working RGB) | <https://www.eci.org/lib/exe/ecirgbv20.zip> | `eciRGB_v2.icc`, `eciRGB_v2_ICCv4.icc` |
| **Adobe ICC Profiles CS4** (end-user) | <https://download.adobe.com/pub/adobe/iccprofiles/win/AdobeICCProfilesCS4Win_end-user.zip> | **`AdobeRGB1998.icc`** (HGK RGB workspace), `CoatedFOGRA27/39`, `USWebCoatedSWOP`, `JapanColor*`, `AppleRGB`, `ColorMatchRGB` |

> **Why `lib/exe/` not `/_media/`?** The ECI DokuWiki at <https://www.eci.org/doku.php?id=en:downloads#icc_profiles_from_eci> renders links as `lib/exe/pso-coated_v3.zip`. Fetching `/_media/...` without a DokuWiki session returns a 40 KB HTML (`en:start`). Use the `lib/exe/` links above for `fetchurl`/`curl -L`.

**Also useful but not bundled (system already provides or available on demand):**

- Generic `sRGB IEC61966-2.1` — shipped by `colord`/`xdg-data` on NixOS; if you need an explicit file: <https://www.color.org/srgbprofiles.xalter> or bundled in `colord` source.
- eciCMYK exchange (`eciCMYK v2`): <https://www.eci.org/lib/exe/eci_cmyk_v2.zip> (not needed for HGK Bogen, but included in the `ecicmyk.zip` lineage).
- Supplement 2020 lamination (`PSO Coated v3 gloss/matte laminate`): <https://www.eci.org/lib/exe/eci-offset-profiles_supplement2020-surface-finishing_v3b.zip>
- WAN-IFRA newspaper profiles: <https://www.wan-ifra.org/de/articles/2015/09/30/newspaper-colour-profile-download> (referenced on ECI downloads).

**Source page to browse all packs:** <https://www.eci.org/doku.php?id=en:downloads> — section **“ICC profiles from ECI”** → tables for *Offset profiles*, *Gravure PSR V2*, *Working colour space eciRGB*, *Exchange colour space eciCMYK*, and *Old versions*.

**Registry:** Color.org mirrors: <https://registry.color.org/profile-registry/PSOcoated_v3> and <https://registry.color.org/profile-registry/PSOuncoated_v3_FOGRA52>.

### 2.2 Where Profiles Live After `home-manager switch`

```bash
# 1. User XDG (native Linux apps: GIMP, Krita, Scribus, Inkscape, Darktable, colord)
~/.local/share/color/icc/        # home.file symlink → /nix/store/...-eci-icc-profiles/share/color/icc
# 38 *.icc shown via:
ls -1 ~/.local/share/color/icc | sort

# 2. System XDG (all users, /run/current-system)
# after nixos-rebuild switch:
ls /run/current-system/sw/share/color/icc
# also:
ls /etc/color/icc                  # environment.etc."color/icc" symlink

# 3. Wine / Affinity (Affinity v3 runs under Wine via affinity-nix)
~/.local/share/affinity-v3/drive_c/windows/system32/spool/drivers/color
~/.local/share/affinity-v3/drive_c/windows/system32/color
~/.local/share/affinity/drive_c/...   # legacy affinity-v2 prefix, if present
~/.wine/drive_c/...                   # generic Wine prefix, if present

# 4. Affinity-internal bundled ICCs (read-only, not to be modified):
# /nix/store/...-affinity-extracted-sources/Affinity/Affinity/Resources/ICC/
# /nix/store/...-affinity-extracted-sources/Affinity/Affinity/Resources/etc/color/
```

**Key HGK aliases to check (must exist):**

```bash
for f in ISOcoated_v2_300_eci.icc ISOcoated_v2_eci.icc PSOcoated_v3.icc PSOuncoated_v3_FOGRA52.icc AdobeRGB1998.icc eciRGB_v2.icc; do
  ls -lh ~/.local/share/color/icc/$f && echo "OK $f" || echo "MISSING $f"
done
```

Expected: all **OK**.

### 2.3 NixOS Module Wiring (`~/.config/flake`)

**System module:** `flake/modules/profiles/creative.nix`

```nix
{ config, lib, pkgs, ... }:
with lib; let
  cfg = config.aliyss.profiles;
  eciIcc = pkgs.callPackage ../../packages/eci-icc-profiles { };
in mkIf cfg.creative {
  environment.systemPackages = [ eciIcc ];
  environment.pathsToLink = [ "/share/color" ];
  services.colord.enable = true;
  environment.etc."color/icc".source = "${eciIcc}/share/color/icc";
}
```

**Home module:** `flake/home-manager/profiles/creative.nix`

```nix
{ config, lib, pkgs, ... }:
let eciIcc = pkgs.callPackage ../../packages/eci-icc-profiles { };
in mkIf config.aliyss.profiles.creative {
  home.file.".local/share/color/icc" = {
    source = "${eciIcc}/share/color/icc";
    recursive = true;
  };
  home.activation.eciIccWine = lib.hm.dag.entryAfter ["writeBoundary"] ''
    for prefix in "$HOME/.local/share/affinity-v3" "$HOME/.local/share/affinity" "$HOME/.wine"; do
      mkdir -p "$prefix/drive_c/windows/system32/spool/drivers/color"
      for icc in "${eciIcc}/share/color/icc"/*.icc; do ln -sf "$icc" "$prefix/..." ; done
    done
  '';
}
```

**Enabled when:** `aliyss.profiles.creative = true` in `flake/local.nix` (already `true` on this machine).  
**Packages:** `flake/home-manager/packages.nix` adds `eciIcc` to `home.packages` when `cfg.creative`.

**Activation:**

```bash
NIXPKGS_ALLOW_UNFREE=1 home-manager switch -b backup --flake ~/.config/flake#aliyss
# verify:
ls ~/.local/share/color/icc | wc -l   # → 38
ls ~/.local/share/affinity-v3/drive_c/windows/system32/spool/drivers/color | wc -l  # → 38
# system-wide (after nixos-rebuild):
sudo nixos-rebuild switch --flake ~/.config/flake#aliyss-bequitta
ls /run/current-system/sw/share/color/icc | grep ISOcoated
```

---

## 3. Setting the Working Spaces in Affinity v3 on Linux

Identical to macOS/Windows, but on Linux the **system ICC search path** is `~/.local/share/color/icc` and `/run/current-system/sw/share/color/icc`. Affinity under Wine resolves Windows paths → same files.

1. Open **Affinity** (`affinity-v3` via `~/.config/flake` overlay).
2. `Bearbeiten → Einstellungen → Farbe` (Linux: `Edit → Settings → Colour`):
   - **RGB:** `Adobe RGB (1998)` → select `AdobeRGB1998.icc` (from `~/.local/share/color/icc`)
   - **CMYK:** `ISO Coated v2 300% (ECI)` → `ISOcoated_v2_300_eci.icc` — **HGK Standard**
   - **Grau:** `ISO Coated v2 300% (ECI)` grey or `Generic Gray`
   - **Rendering Intent:** `Relativ farbmetrisch` — **Black Point Compensation** ☑
   - **Warnungen:** `Beim Öffnen wählen` / `Beim Einfügen wählen` / `Fehlende Profile` → all ☑
3. **No Bridge sync needed** — unified app, all Studios share the setting.

**Per-document override:** `Dokument → Farbformat` / `Dokument → Farbprofil zuweisen/konvertieren`.

**New document preset:** `Datei → Neu → Farbe → CMYK/8 → ISO Coated v2 300% (ECI)` → Save as `HGK Standard_Adobe RGB_ISO Coated V2 300`.

---

## 4. PDF/X Export (Layout Studio) on Linux

Matches Adobe **InDesign → PDF/X-4:2008** 1:1.

```text
Datei → Neu
  → Farbformat: RGB/8 (work in RGB, keep gamut)
  → Farbprofil: ISO Coated v2 300% (ECI) — will be used at export
  → DPI: 300
  → Beschnitt: 3 mm all sides

Datei → Dokument-Setup → Beschnitt 3 mm prüfen

Datei → Export → PDF
  → Preset: PDF/X-4  (HGK Bogen, keeps transparency)
          or PDF/X-1a:2003 (for older RIPs / KDP)
          or PDF (press ready) (Affinity convenience)
  → Raster DPI: Farbbilder 300 / Graustufen 300 / 1-bit 1200 (unter „Mehr“)
  → ☑ Beschnitt einbeziehen
  → ☑ Schnittmarken (nur für HGK Bogen; für POD aus)
  → Ausgabe: Farbe → Konvertieren → Ziel: ISO Coated v2 300% (ECI) → ☑ ICC einbetten
  → Total Ink Coverage: Affinity zeigt kein TIC-Limit — manuell: Body text K100, large black C60 M40 Y40 K100 (240% = IngramSpark limit)
```

**Verification on Linux (no Acrobat needed):**

```bash
# CLI:
exiftool exported.pdf | grep -i "icc\|pdf/x\|bleed"
# or:
nix shell nixpkgs#poppler_utils -c pdfinfo exported.pdf
# inside Affinity: reopen PDF, check Document → Colour Format
```

---

## 5. Soft Proof (CMYK Preview) on Linux

Adobe `cmd+Y` → Affinity `Soft Proof` layer:

```
Ebene → Neue Anpassungsebene → Soft Proof
  → Profil: ISO Coated v2 300% (ECI)  (oder PSO Coated V3 / PSO Uncoated V3 je Papier)
  → Rendering: Relativ farbmetrisch
  → ☑ Papierfarbe simulieren (für ungestrichen/Zeitung)
  → ☑ Schwarze Druckfarbe simulieren (für gestrichen)
→ Ebene umbenennen: Softproof_Gestrichen_ISOv2
→ Auge toggeln = Preview on/off (assign cmd+Y in Einstellungen → Tastaturkürzel)
```

Works offline, no colord dependency, rendering is done by Affinity/lcms2.

---

## 6. Troubleshooting — Linux Specific

| Symptom | Cause | Fix (NixOS) |
|---|---|---|
| Affinity shows `sRGB` instead of `ISO Coated v2 300%` dropdown empty | ICC not in Wine prefix | `ls ~/.local/share/affinity-v3/drive_c/windows/system32/spool/drivers/color` → if missing, re-run `home-manager switch -b backup --flake ~/.config/flake#aliyss` (triggers `eciIccWine` activation) |
| `File → Export → PDF → Ziel-Profil` list empty | Native `~/.local/share/color/icc` missing | `ls ~/.local/share/color/icc/ISOcoated_v2_300_eci.icc` → if missing, `NIXPKGS_ALLOW_UNFREE=1 home-manager switch ...` and check `~/.config/flake/packages/eci-icc-profiles/default.nix` hashes |
| `colord` warnings, `colormgr get-profiles` shows nothing | `services.colord.enable = false` | Enable in `modules/profiles/creative.nix` (already enabled), then `sudo nixos-rebuild switch ... && systemctl restart colord` |
| Prints too dark / TIC rejection (295% vs 240%) | Rich black default C72 M68 Y67 K88 | In Layout Studio, set large black areas to `C60 M40 Y40 K100` (240%) and body text to `K100` only |
| Affinity file `.af` not opening on other machine | Affinity v3 new format not backward to v2 | Export as `PSD`/`TIFF` for exchange (`File → Export → PSD` keeps spare channels/vector masks) |

---

## 7. Uninstall / Update

```bash
# Remove profiles (if you later disable creative profile):
# edit flake/local.nix → aliyss.profiles.creative = false
# then:
NIXPKGS_ALLOW_UNFREE=1 home-manager switch -b backup --flake ~/.config/flake#aliyss
sudo nixos-rebuild switch --flake ~/.config/flake#aliyss-bequitta
# update hashes when ECI publishes new ZIPs:
nix store prefetch-file --json "https://www.eci.org/lib/exe/pso-coated_v3.zip"
# paste hash into flake/packages/eci-icc-profiles/default.nix
```

---

## 8. Workable Links — Official Sources (clickable)

- **ECI downloads overview:** <https://www.eci.org/doku.php?id=en:downloads> — all ICC packs, grey control strips, PDF/X docs.
- **ECI Offset 2009 (ISO Coated v2 + 300%):** <https://www.eci.org/lib/exe/eci_offset_2009.zip> — 16.6 MB, 12 profiles including `ISOcoated_v2_300_eci.icc`.
- **PSO Coated v3 (FOGRA51):** <https://www.eci.org/lib/exe/pso-coated_v3.zip> — 1.7 MB, `PSOcoated_v3.icc`.
- **PSO Uncoated v3 (FOGRA52):** <https://www.eci.org/lib/exe/pso-uncoated_v3_fogra52.zip> — 1.6 MB, `PSOuncoated_v3_FOGRA52.icc`.
- **eciRGB v2 (working RGB):** <https://www.eci.org/lib/exe/ecirgbv20.zip> — 4 KB, `eciRGB_v2.icc`.
- **Adobe ICC Profiles CS4 (AdobeRGB1998 etc.):** <https://download.adobe.com/pub/adobe/iccprofiles/win/AdobeICCProfilesCS4Win_end-user.zip> — 6.2 MB, `AdobeRGB1998.icc`.
- **ECI eciCMYK v2:** <https://www.eci.org/lib/exe/eci_cmyk_v2.zip> — exchange CMYK.
- **Supplement 2020 lamination (PSO Coated v3 gloss/matte):** <https://www.eci.org/lib/exe/eci-offset-profiles_supplement2020-surface-finishing_v3b.zip>
- **Gravure PSR V2 (all paper types):** <https://www.eci.org/lib/exe/eci_gravure_psr_v2_m1_2020.zip>
- **Color.org registry (FOGRA51):** <https://registry.color.org/profile-registry/PSOcoated_v3>
- **Color.org registry (FOGRA52):** <https://registry.color.org/profile-registry/PSOuncoated_v3_FOGRA52>
- **ECI Colour Standards → Offset:** <https://www.eci.org/doku.php?id=en:colorstandards:offset>
- **Local copy in this flake:** `~/.config/flake/packages/eci-icc-profiles/default.nix` (hash-pinned) and `~/.config/flake/modules/profiles/creative.nix` / `~/.config/flake/home-manager/profiles/creative.nix` (activation).
- **This guide:** `~/.config/flake/docs/color-management-linux.md` and `~/School/uni_workshops/digital_tools/lesson_1/resources/docs/Linux_Color-Management_NixOS.md` (same content, workable links preserved).

---

*Installed profiles on this machine (2026-09-01, `~/.local/share/color/icc`, 38 files):*

```
AdobeRGB1998.icc         ISOcoated_v2_300_eci.icc  PSOcoated_v3.icc
eciRGB_v2.icc            PSOuncoated_v3_FOGRA52.icc  ISOcoated_v2_eci.icc  ...
(full list: ls ~/.local/share/color/icc)
```

*Next steps for the course:* In Affinity, create a new document (`Datei → Neu → CMYK/8, 300 dpi, 3 mm Beschnitt, ISO Coated v2 300%`), place an RGB image from `Photoshop_Aufgaben-Resources/`, add a Soft Proof layer, and export via `PDF/X-4` — all using the Nix-provided profiles above. See also: `~/School/uni_workshops/digital_tools/lesson_1/resources/IDCE_HowTo_PDF-Workflow_Affinity-v3_RZ.md` (§2–5) and the bilingual exercises `IDCE_Digital Tools_Affinity_Aufgaben-Exercises_RZ.md`.

