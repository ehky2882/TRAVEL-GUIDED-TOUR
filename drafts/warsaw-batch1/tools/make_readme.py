#!/usr/bin/env python3
"""Regenerate README.md (index + pronunciation table) from source/ and build.py."""
import re, pathlib
ROOT = pathlib.Path(__file__).resolve().parent.parent
src = (ROOT / "tools/build.py").read_text()
ns = {}; exec(src[src.index("RESPELL = {"):src.index("KEYS =")], ns)
rows, text = [], ""
for f in sorted((ROOT / "source").glob("*.txt")):
    t = f.read_text(); text += t
    for b in re.split(r"^=== ", t, flags=re.M)[1:]:
        num, slug, title, gm, co, cat = [x.strip() for x in b.split("\n")[0].split("|")]
        rows.append(f"| {num} | {cat} | {title} | {gm} | {co} | `warsaw_{num}_{slug.replace('-', '_')}` |")
pron = [f"| {k} | {v} |" for k, v in sorted(ns["RESPELL"].items(), key=lambda kv: kv[0].lower()) if k in text]
body = (ROOT / "tools/readme_body.md").read_text()
(ROOT / "README.md").write_text(body.replace("@@ROWS@@", "\n".join(rows)).replace("@@PRON@@", "\n".join(pron)))
print(f"README: {len(rows)} tours, {len(pron)} respellings")
