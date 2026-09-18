# Adobe Fonts – Auto Pro (Typekit kit whl2slc)

Extractor that **fetches** `https://use.typekit.net/whl2slc.css` at **build time** (FOD, not vendored) and retags the web OTFs to match the InDesign IDML:

* Source kit: `whl2slc` – 24 styles of **Auto Pro** (Underware, Version 2.500/2.502) used in `~/Downloads/Text d_Auto Pro_Black.idml`
* Deliverable: `AutoPro-*.otf` with `family="Auto Pro"` and correct `FontStyleName` / `PostScriptName` (e.g. `AutoPro-BlackItalic1`) – validated against `Resources/Fonts.xml`
* Web OTFs are deliberately stripped (`family=""`, `ps="-"`) – retag reads `CFF FontName` and rewrites the `name` table via `fontTools` (`packages/adobe-fonts/retag.py`).

## Layout

```
flake/packages/adobe-fonts/
  default.nix  – FOD mkDerivation, fetches kit.css + 24× /af/.../a? (opentype), retags, installs to $out/share/fonts/{opentype,truetype}
  retag.py     – fontTools retag logic (PS_TO_META hard-coded from IDML)
  update.sh    – updates outputHash after Adobe rotates af/ hashes
  README.md
```

## How it installs

* **System** (`flake/modules/hardware/fonts.nix:7`): `fonts.packages += adobeFonts` when `aliyss.adobeFonts.enable` (default `true`) → `fontconfig` system-wide (`/run/current-system/sw/share/fonts/opentype`).
* **User** (`flake/home-manager/profiles/adobe-fonts.nix:14`): `home.file."~/.local/share/fonts/adobe"` symlink farm.
* **Affinity Wine** (`flake/home-manager/profiles/adobe-fonts.nix:22` `adobeFontsWine` activation): symlinks every `*.otf` into
  `~/.local/share/affinity/drive_c/windows/Fonts`,
  `~/.local/share/affinity-v3/drive_c/windows/Fonts`,
  `~/.wine/drive_c/windows/Fonts` and runs `fc-cache`. Mirrors the ICC sync in `profiles/creative.nix:23` `eciIccWine`.

## Updating

Adobe rotates `af/` hashes sporadically (kit last published `2026-09-17` per kit.css header). When `nixos-rebuild` fails with `hash mismatch had ... got ...`:

```bash
cd ~/.config/flake/packages/adobe-fonts
./update.sh whl2slc    # fetches expected hash and patches default.nix outputHash
# or manually:
nix build --impure --expr '(import <nixpkgs> {}).callPackage ./default.nix { kitId="whl2slc"; }' 2>&1 | grep got:
# copy sha256-... into default.nix outputHash
```

Then `nixos-rebuild --flake .#aliyss-bequitta` / `home-manager switch`.

## Verify

```bash
fc-list | grep -i "Auto Pro"
# → Auto Pro:style=Black, Black Italic 1, Black Italic 2, etc (24 styles)
ls ~/.local/share/fonts/adobe | grep AutoPro
ls ~/.local/share/affinity-v3/drive_c/windows/Fonts/AutoPro-*.otf
# Open Affinity Designer/Photo – Typography panel should list Auto Pro without substitution
# Open ~/Downloads/Text\ d_Auto\ Pro_Black.idml – no Myriad/LegacySerif substitution
```

## License

Adobe Fonts EULA – fonts are **not redistributed** via the Nix cache. The derivation fetches from `use.typekit.net` at build time; do not commit `*.otf` to git. Keep kit private if required (`aliyss.adobeFonts.kitId` is in `modules/options.nix:16` and can be overridden in `local.nix`).

## IDML reference

`Resources/Fonts.xml` in the IDML declares 24 Auto Pro fonts (Status Installed):

```
AutoPro-Light, LightSmallCaps, LightItalic1/2/3, LightItalicSmallCaps,
AutoPro-Regular, … Bold … Black … (each with SmallCaps + Italic1/2/3 variants)
```

Used in stories: `Black`, `Black Italic 1`, `Black Italic 2` (see `Stories/Story_*.xml`).
