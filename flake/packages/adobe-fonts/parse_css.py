#!/usr/bin/env python3
"""
Parse Typekit kit.css to extract @font-face opentype URLs and their
font-family/weight/style metadata, so retag can derive desktop names
without hardcoding PS_TO_META.

Each @font-face in kit.css looks like:
  @font-face {
  font-family:"auto-pro-small-caps";
  src:url("https://use.typekit.net/af/658368/.../31/a?primer=...&fvd=i9&v=3") format("opentype");
  font-display:auto;font-style:italic;font-weight:900;font-stretch:normal;
  }

We extract the opentype URL and the associated family/weight/style, plus fvd/af,
and write:
  urls.txt – one opentype URL per line (in order)
  mapping.json – list of {url, family, weight, style, stretch, fvd, af}
"""

import re
import sys
import json
import pathlib

if len(sys.argv) != 4:
    print(f"Usage: {sys.argv[0]} kit.css urls.txt mapping.json", file=sys.stderr)
    sys.exit(1)

kit_css = pathlib.Path(sys.argv[1]).read_text(errors="ignore")
urls_path = pathlib.Path(sys.argv[2])
mapping_path = pathlib.Path(sys.argv[3])

# Find all @font-face blocks
blocks = re.findall(r'@font-face\s*\{([^}]+)\}', kit_css, re.S)

urls = []
mapping = []

fvd_to_weight = {
    "1": 100, "2": 200, "3": 300, "4": 400, "5": 500,
    "6": 600, "7": 700, "8": 800, "9": 900,
}

for block in blocks:
    # Extract font-family
    m_family = re.search(r'font-family\s*:\s*"?([^";]+)"?', block)
    family = m_family.group(1).strip().strip('"').strip("'") if m_family else ""
    # weight
    m_weight = re.search(r'font-weight\s*:\s*([0-9]+)', block)
    weight = int(m_weight.group(1)) if m_weight else 400
    # style
    m_style = re.search(r'font-style\s*:\s*([a-z]+)', block)
    style = m_style.group(1) if m_style else "normal"
    # stretch
    m_stretch = re.search(r'font-stretch\s*:\s*([a-z]+)', block)
    stretch = m_stretch.group(1) if m_stretch else "normal"
    # Find opentype url
    m_url = re.search(r'url\("([^"]+)"\)\s*format\("opentype"\)', block)
    if not m_url:
        # Fallback to woff2 if no opentype
        m_url = re.search(r'url\("([^"]+)"\)\s*format\("woff2"\)', block)
        if not m_url:
            continue
    url = m_url.group(1)
    # Extract fvd and af
    m_fvd = re.search(r'[?&]fvd=([^&]+)', url)
    fvd = m_fvd.group(1) if m_fvd else ""
    m_af = re.search(r'/af/([^/]+)/', url)
    af = m_af.group(1) if m_af else ""
    # Only keep opentype
    if 'format("opentype")' not in block and 'format("woff2")' in block:
        # will be handled as fallback, but prefer opentype
        pass
    # Only add if URL contains /a? (opentype endpoint) – the /a? is opentype, /l? is woff2, /d? is woff
    if "/a?" not in url:
        # Try to find the /a? variant in the same block (there are 3 urls per block)
        # The block has 3 src urls: woff2, woff, opentype – we already extracted the opentype one
        # So if we didn't get opentype, skip
        if 'format("opentype")' not in block:
            continue
    urls.append(url)
    mapping.append({
        "url": url,
        "family": family,
        "weight": weight,
        "style": style,
        "stretch": stretch,
        "fvd": fvd,
        "af": af,
    })

# Deduplicate urls while preserving order (same font may appear in multiple kits)
seen = set()
uniq_urls = []
uniq_mapping = []
for u, m in zip(urls, mapping):
    if u not in seen:
        seen.add(u)
        uniq_urls.append(u)
        uniq_mapping.append(m)

urls_path.write_text("\n".join(uniq_urls) + "\n" if uniq_urls else "")
mapping_path.write_text(json.dumps(uniq_mapping, indent=2))

print(f"parsed {len(blocks)} @font-face blocks, {len(uniq_urls)} opentype urls", file=sys.stderr)
for m in uniq_mapping[:5]:
    print(f"  {m['family']} weight {m['weight']} style {m['style']} fvd {m['fvd']} -> {m['url'][:80]}", file=sys.stderr)
