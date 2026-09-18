#!/usr/bin/env python3
"""
Retag Adobe Typekit web OTFs to match IDML expectations.

Web OTFs from https://use.typekit.net/af/.../a? have broken name table:
  family="", style="Regular", ps="-",fullname="-"
But CFF fontNames contains correct PS (e.g. AutoPro-BlackItalicSmallCaps).

We rewrite name table to:
  family "Auto Pro", style per IDML, fullname per IDML, ps = CFF name,
  + version/copyright from IDML.

Reference: ~/Downloads/Text d_Auto Pro_Black.idml:Resources/Fonts.xml
  24 styles, family Auto Pro, FontType OpenTypeCFF, Version 2.500/2.502
"""

import sys, pathlib, re
from fontTools.ttLib import TTFont

# Exact mapping from PS to (family, style, fullname, version) for known Auto Pro kit whl2slc.
# Kept for precise FullName/version matching the IDML, but fallback handles any future kit.
# Family always derived from PS prefix (AutoPro- -> Auto Pro, etc.), style from suffix.
PS_TO_META = {
    "AutoPro-Light": ("Auto Pro", "Light", "Auto Pro Light", "2.500"),
    "AutoPro-LightSmallCaps": ("Auto Pro", "Light Small Caps", "Auto Pro Light Small Caps", "2.502"),
    "AutoPro-LightItalic1": ("Auto Pro", "Light Italic 1", "Auto Pro Light Italic 1", "2.500"),
    "AutoPro-LightItalic2": ("Auto Pro", "Light Italic 2", "Auto Pro Light Italic 2", "2.500"),
    "AutoPro-LightItalic3": ("Auto Pro", "Light Italic 3", "Auto Pro Light Italic 3", "2.500"),
    "AutoPro-LightItalicSmallCaps": ("Auto Pro", "Light Italic Small Caps", "Auto Pro Light It SmCp", "2.500"),
    "AutoPro-Regular": ("Auto Pro", "Regular", "Auto Pro", "2.500"),
    "AutoPro-RegularSmallCaps": ("Auto Pro", "Regular Small Caps", "Auto Pro Regular Small Caps", "2.502"),
    "AutoPro-RegularItalic1": ("Auto Pro", "Regular Italic 1", "Auto Pro Regular Italic 1", "2.500"),
    "AutoPro-RegularItalic2": ("Auto Pro", "Regular Italic 2", "Auto Pro Regular Italic 2", "2.500"),
    "AutoPro-RegularItalic3": ("Auto Pro", "Regular Italic 3", "Auto Pro Regular Italic 3", "2.500"),
    "AutoPro-RegularItalicSmallCaps": ("Auto Pro", "Regular Italic Small Caps", "Auto Pro Reg It SmCp", "2.500"),
    "AutoPro-Bold": ("Auto Pro", "Bold", "Auto Pro Bold", "2.500"),
    "AutoPro-BoldSmallCaps": ("Auto Pro", "Bold Small Caps", "Auto Pro Bold Small Caps", "2.502"),
    "AutoPro-BoldItalic1": ("Auto Pro", "Bold Italic 1", "Auto Pro Bold Italic 1", "2.500"),
    "AutoPro-BoldItalic2": ("Auto Pro", "Bold Italic 2", "Auto Pro Bold Italic 2", "2.500"),
    "AutoPro-BoldItalic3": ("Auto Pro", "Bold Italic 3", "Auto Pro Bold Italic 3", "2.500"),
    "AutoPro-BoldItalicSmallCaps": ("Auto Pro", "Bold Italic Small Caps", "Auto Pro Bold It SmCp", "2.500"),
    "AutoPro-Black": ("Auto Pro", "Black", "Auto Pro Black", "2.500"),
    "AutoPro-BlackSmallCaps": ("Auto Pro", "Black Small Caps", "Auto Pro Black Small Caps", "2.502"),
    "AutoPro-BlackItalic1": ("Auto Pro", "Black Italic 1", "Auto Pro Black Italic 1", "2.500"),
    "AutoPro-BlackItalic2": ("Auto Pro", "Black Italic 2", "Auto Pro Black Italic 2", "2.500"),
    "AutoPro-BlackItalic3": ("Auto Pro", "Black Italic 3", "Auto Pro Black Italic 3", "2.500"),
    "AutoPro-BlackItalicSmallCaps": ("Auto Pro", "Black Italic Small Caps", "Auto Pro Black It SmCp", "2.500"),
}
# For reproducibility with >24 or other families, PS_TO_META is optional – ps_to_fallback handles any PS.

COPYRIGHT = "Copyright (c) Underware, Den Haag (NL). All rights reserved."
# Unique ID pattern from retagged files: "2.500;REAL;PS" – keep dynamic

def ps_to_fallback(ps: str):
    """Generate family/style/fullname from PS if not in hardcoded dict (future kits)."""
    base = ps.removeprefix("AutoPro-")
    m = re.match(r'^(Light|Regular|Bold|Black)(Italic([123])?)?(SmallCaps)?$', base)
    if not m:
        return ("Auto Pro", base, f"Auto Pro {base}", "2.500")
    weight, italic, num, sc = m.groups()
    style = weight
    if italic:
        style += " Italic"
        if num:
            style += f" {num}"
    if sc:
        style += " Small Caps"
    fullname = f"Auto Pro {style}"
    # Truncate to match IDML style for small caps italic variants?
    # Keep full – InDesign matches PS, not fullname.
    version = "2.502" if sc and not italic else "2.500" if not sc else "2.500"
    # Actually only RegularSmallCaps etc use 2.502 per IDML – but keep 2.500 for simplicity
    if ps in ["AutoPro-LightSmallCaps", "AutoPro-RegularSmallCaps", "AutoPro-BoldSmallCaps", "AutoPro-BlackSmallCaps"]:
        version = "2.502"
    return ("Auto Pro", style, fullname, version)

def retag_one(src: pathlib.Path, dst_dir: pathlib.Path, all_ps: list[str] | None = None, css_mapping: list[dict] | None = None):
    tt = TTFont(str(src))
    cff = tt['CFF '].cff
    ps = cff.fontNames[0] if cff.fontNames else None
    if not ps:
        # Fallback extract from CFF raw
        ps = src.stem
    # ps is str
    if isinstance(ps, bytes):
        ps = ps.decode('ascii')

    meta = PS_TO_META.get(ps)
    if meta is None:
        print(f"warn: {src.name} has unknown PS {ps!r}, using fallback", file=sys.stderr)
        family, style, fullname, ver = ps_to_fallback(ps)
    else:
        family, style, fullname, ver = meta
    # For generic handling of >24 or new kits, all_ps may be provided to assign distinct weights
    # without hardcoding variant_offset for unknown styles.
    # css_mapping from kit.css is also available for future kits.

    version_str = f"Version {ver} Adobe Fonts (24.09.2018)"
    unique = f"{ver};REAL;{ps}"

    # Rewrite name table – both Mac (1,0,0) and Windows (3,1,1033)
    name = tt['name']
    # Ensure WWS names (21/22) and typographic (16/17) are correctly set for
    # Windows GDI/DirectWrite to enumerate >4 styles per family. Previously we
    # removed them, causing only 4 to show (GDI 4-style limit). Now set them
    # to same as 1/2 and enable WWS/USE_TYPO_METRICS bits so all 24 enumerate.
    for nid in [16, 17, 21, 22]:
        for plat, enc, lang in [(1, 0, 0), (3, 1, 1033)]:
            try:
                name.removeNames(nameID=nid, platformID=plat, platEncID=enc, langID=lang)
            except Exception:
                pass
    for plat, enc, lang in [(1, 0, 0), (3, 1, 1033)]:
        name.setName(COPYRIGHT, 0, plat, enc, lang)
        name.setName(family, 1, plat, enc, lang)
        name.setName(style, 2, plat, enc, lang)
        name.setName(unique, 3, plat, enc, lang)
        name.setName(fullname, 4, plat, enc, lang)
        name.setName(version_str, 5, plat, enc, lang)
        name.setName(ps, 6, plat, enc, lang)
        # WWS + typographic for Windows >4 styles per family
        name.setName(family, 16, plat, enc, lang)
        name.setName(style, 17, plat, enc, lang)
        name.setName(family, 21, plat, enc, lang)
        name.setName(style, 22, plat, enc, lang)

    # Update CFF FontName to match PS (already does, but enforce)
    cff.fontNames = [ps]
    # Also update CFF TopDict FullName if present
    try:
        top = cff.topDictIndex[0]
        top.FullName = fullname
        top.FamilyName = family
        top.Weight = style
    except Exception:
        pass

    # Fix OS/2 weight class and head macStyle/fsSelection sync
    # Give each of the 24 styles a distinct usWeightClass so Wine GDI (which
    # deduplicates by weight+italic+bold) enumerates all – otherwise only 4 show.
    # Use *10 offset to keep distinct across fontconfig buckets (50/51/52… instead of 50/50.1)
    # Keep typographic family as Auto Pro (16) for DirectWrite, but split GDI family (1)
    # per style so GDI shows 24 families (each Regular) while typographic shows 1 family with 24.
    # This matches the working local fix that made Affinity show Auto Pro (27) correctly.
    try:
        weight_map = {"Light": 300, "Regular": 400, "Bold": 700, "Black": 900}
        w = 400
        for k, v in weight_map.items():
            if k in style:
                w = v
                break
        # Generic distinct offset: for known styles use hardcoded, for unknown use sorted order within family
        variant_offset_map = {
            "Light": 0, "Light Small Caps": 1, "Light Italic 1": 2, "Light Italic 2": 3, "Light Italic 3": 4, "Light Italic Small Caps": 5,
            "Regular": 0, "Regular Small Caps": 1, "Regular Italic 1": 2, "Regular Italic 2": 3, "Regular Italic 3": 4, "Regular Italic Small Caps": 5,
            "Bold": 0, "Bold Small Caps": 1, "Bold Italic 1": 2, "Bold Italic 2": 3, "Bold Italic 3": 4, "Bold Italic Small Caps": 5,
            "Black": 0, "Black Small Caps": 1, "Black Italic 1": 2, "Black Italic 2": 3, "Black Italic 3": 4, "Black Italic Small Caps": 5,
        }
        if style in variant_offset_map:
            variant_offset = variant_offset_map[style]
        elif all_ps is not None:
            # Generic: sort all PS for this family and assign 0..n
            family_ps = sorted([p for p in all_ps if p.startswith(ps.split("-")[0] + "-")])
            # For other families (e.g., different prefix), sort all
            if ps in family_ps:
                variant_offset = family_ps.index(ps) % 10
            else:
                variant_offset = sorted(all_ps).index(ps) % 10
        else:
            variant_offset = 0
        w = w + variant_offset * 10
        if w > 1000:
            w = 1000
        tt['OS/2'].usWeightClass = w
        # For GDI split: each font is its own GDI family with Regular style, so fsSelection is Regular+USE_TYPO
        # Keep WWS off and no 21/22 (typographic only) – Wine DirectWrite typographic will use 16/17
        tt['OS/2'].fsSelection = 64 | 256  # REGULAR + USE_TYPO_METRICS
        if tt['OS/2'].version < 4:
            tt['OS/2'].version = 4
        tt['head'].macStyle = 0
        # Update GDI vs typographic names: GDI 1 = Auto Pro + style (unique), 2=Regular, 16=Auto Pro, 17=style
        # This is done above in name table section, but ensure here that 1/2 are correctly set for GDI split
        # (name table already set 1/2 to style and 16/17 to Auto Pro/style – we override 1/2 here to GDI split)
        # Re-apply GDI split for nameIDs 1/2
        gdi_family = f"Auto Pro {style}" if style != "Regular" else "Auto Pro"
        for plat, enc, lang in [(1, 0, 0), (3, 1, 1033)]:
            try:
                name.removeNames(nameID=1, platformID=plat, platEncID=enc, langID=lang)
                name.removeNames(nameID=2, platformID=plat, platEncID=enc, langID=lang)
            except:
                pass
            name.setName(gdi_family, 1, plat, enc, lang)
            name.setName("Regular", 2, plat, enc, lang)
            # Ensure typographic remains
            name.setName(family, 16, plat, enc, lang)
            name.setName(style, 17, plat, enc, lang)
            # Remove WWS 21/22 (since we are typographic, not WWS)
            try:
                name.removeNames(nameID=21, platformID=plat, platEncID=enc, langID=lang)
                name.removeNames(nameID=22, platformID=plat, platEncID=enc, langID=lang)
            except:
                pass
    except Exception as e:
        print(f"warn: weight/name patch failed for {ps}: {e}", file=sys.stderr)

    dst = dst_dir / f"{ps}.otf"
    tt.save(str(dst))
    print(f"  {src.name} -> {dst.name}  family={family!r} style={style!r} ps={ps!r}")
    return dst

def main():
    if len(sys.argv) not in (3, 4):
        print(f"Usage: {sys.argv[0]} <raw_dir> <out_dir> [mapping.json]", file=sys.stderr)
        sys.exit(1)
    raw_dir = pathlib.Path(sys.argv[1])
    out_dir = pathlib.Path(sys.argv[2])
    mapping_path = pathlib.Path(sys.argv[3]) if len(sys.argv) == 4 else None
    out_dir.mkdir(parents=True, exist_ok=True)

    files = sorted(raw_dir.glob("*.otf"))
    if not files:
        print(f"error: no .otf files in {raw_dir}", file=sys.stderr)
        sys.exit(1)

    css_mapping = None
    if mapping_path and mapping_path.exists():
        import json
        try:
            css_mapping = json.loads(mapping_path.read_text())
            print(f"loaded CSS mapping with {len(css_mapping)} entries from {mapping_path}", file=sys.stderr)
        except Exception as e:
            print(f"warn: failed to load mapping {mapping_path}: {e}", file=sys.stderr)

    all_ps = []
    for f in files:
        try:
            tt_tmp = TTFont(str(f))
            cff_tmp = tt_tmp['CFF '].cff
            ps_tmp = cff_tmp.fontNames[0] if cff_tmp.fontNames else f.stem
            if isinstance(ps_tmp, bytes):
                ps_tmp = ps_tmp.decode('ascii')
            all_ps.append(ps_tmp)
        except:
            all_ps.append(f.stem)

    for f in files:
        retag_one(f, out_dir, all_ps, css_mapping)

    # Validate we got 24 expected PS
    got = {p.stem for p in out_dir.glob("*.otf")}
    expected = set(PS_TO_META.keys())
    missing = expected - got
    extra = got - expected
    if missing:
        print(f"warn: missing PS after retag: {sorted(missing)}", file=sys.stderr)
    if extra:
        print(f"warn: extra PS (fallback) {sorted(extra)}", file=sys.stderr)

if __name__ == "__main__":
    main()
