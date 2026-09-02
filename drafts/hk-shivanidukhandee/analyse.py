#!/usr/bin/env python3
"""Offline analysis of cached embed HTML.

Imports the PRODUCTION tool's own helpers where it can, so this mirror cannot
drift from what make-link-pin.py will actually do at wire-in time.
"""
import json, re, sys, os, importlib.util
from pathlib import Path

SPEC = importlib.util.spec_from_file_location(
    "mlp", "/home/user/TRAVEL-GUIDED-TOUR/scripts/make-link-pin.py")
mlp = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(mlp)          # module-level code only; main() is under __main__

def unesc(x):
    if not x: return ""
    for _ in range(2):
        try: nxt = json.loads(f'"{x}"')
        except json.JSONDecodeError: break
        if nxt == x: break
        x = nxt
    return x.replace("\\/", "/")

def grab(html, pat):
    g = re.search(pat, html)
    return g.group(1) if g else None

rows = []
for f in sorted(Path("embeds").glob("*.html")):
    code = f.stem
    html = f.read_text(errors="replace")
    size = len(html.encode())
    # 🔴 THE blocked-post test: contextJSON null = Instagram withholds the media
    # context from a logged-out reader. NOT the same as "deleted".
    ctx = re.search(r'contextJSON["\\]*\s*:\s*("(?:[^"\\]|\\.)*"|null)', html)
    ctx_raw = ctx.group(1) if ctx else None
    ctx_null = (ctx_raw == "null") if ctx_raw is not None else None
    handle = grab(html, r'\\"username\\":\\"(.*?)\\"')
    thumb  = grab(html, r'\\"display_url\\":\\"(.*?)\\"')
    cap    = grab(html, r'\\"edge_media_to_caption\\":\{\\"edges\\":\[\{\\"node\\":\{\\"text\\":\\"(.*?)\\"\}')
    playable, why = mlp.instagram_playability(html)
    rows.append(dict(code=code, size=size, ctx_null=ctx_null, has_ctx_key=ctx_raw is not None,
                     handle=handle, thumb=unesc(thumb) if thumb else None,
                     caption=unesc(cap).strip() if cap else "",
                     plays_inline=playable, why=why))
json.dump(rows, open("analysis.json","w"), ensure_ascii=False, indent=1)
ok = [r for r in rows if r["handle"] and r["thumb"]]
bad = [r for r in rows if not (r["handle"] and r["thumb"])]
print(f"analysed {len(rows)}  |  readable {len(ok)}  |  NO handle+thumb {len(bad)}")
if bad:
    print("  blocked/unreadable:")
    for r in bad: print(f"    {r['code']}  {r['size']}B  ctx_null={r['ctx_null']}")
import collections
print("handles:", collections.Counter(r["handle"] for r in ok).most_common())
