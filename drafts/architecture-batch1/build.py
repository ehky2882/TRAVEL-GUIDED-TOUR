#!/usr/bin/env python3
"""Render each src/NNN_slug.txt into scripts/: _clean.txt, _tts-safe.txt (when needed) and .md.

Source format (plain text):
    TITLE: Casa Nido
    TTS_TITLE: Casa Needo            (optional; respelt title for TTS)
    PLACE: Torrefiel, Valencia, Spain
    COORD: 39.49546, -0.37637 (area)
    SOURCE: https://...              (repeat; primary sources read before writing)
    RESPELL: Torrefiel => torrayfee-el   (repeat; applied to the TTS-safe text only)
    ---
    <script paragraphs; [beat] on its own line where a pause belongs>
"""
import os, re, sys, glob
HERE = os.path.dirname(os.path.abspath(__file__))
YEAR = re.compile(r"\b(1[0-9]|20)\d\d\b")
def check_tts(t):
    bad = []
    if re.search(r"\d", t): bad.append("digits")
    if re.search(r"[\[\]<>{}*_#`]", t): bad.append("markup/brackets")
    return bad
for src in sorted(glob.glob(os.path.join(HERE, "src", "*.txt"))):
    stem = os.path.splitext(os.path.basename(src))[0]
    head, body = open(src, encoding="utf-8").read().split("\n---\n", 1)
    meta = {"SOURCE": [], "RESPELL": []}
    for line in head.splitlines():
        if ":" not in line: continue
        k, v = line.split(":", 1); k = k.strip(); v = v.strip()
        if k in meta and isinstance(meta[k], list): meta[k].append(v)
        else: meta[k] = v
    body = body.strip()
    title = meta["TITLE"]
    clean = f"{title}\n\n{body}\n"
    tts = body
    for r in meta["RESPELL"]:
        a, b = [x.strip() for x in r.split("=>")]
        tts = re.sub(re.escape(a), b, tts)
    tts = re.sub(r"\n*\[beat\]\n*", "\n\n", tts)
    tts = re.sub(r"[—–]", ",", tts)        # dashes read badly in some voices
    tts = tts.replace(" ,", ",").replace(",,", ",")
    tts_title = meta.get("TTS_TITLE", title)
    tts = f"{tts_title}\n\n{tts}\n"
    need_tts = "[beat]" in body or meta["RESPELL"] or tts_title != title
    out = os.path.join(HERE, "scripts", stem)
    open(out + "_clean.txt", "w", encoding="utf-8").write(clean)
    if need_tts:
        open(out + "_tts-safe.txt", "w", encoding="utf-8").write(tts)
        bad = check_tts(tts)
        if bad: print(f"WARN {stem}: TTS-safe still has {', '.join(bad)}", file=sys.stderr)
    words = len(re.findall(r"\b\w+\b", body.replace("[beat]", "")))
    md = [f"# {title}", "", f"**Place:** {meta.get('PLACE','')}  ", f"**Coordinate (WGS-84):** {meta.get('COORD','')}  ",] + ([f"**Note:** {meta['NOTE']}  "] if meta.get('NOTE') else []) + [
          f"**Length:** {words} words (about {round(words/150*60)} seconds)", "", "## Script (clean)", "", body, "",
          "## Sources read before writing", ""] + [f"- {s}" for s in meta["SOURCE"]]
    if meta["RESPELL"]:
        md += ["", "## TTS respellings", "", "| Written | Spoken as |", "|---|---|"] + \
              [f"| {a.strip()} | {b.strip()} |" for a, b in (r.split("=>") for r in meta["RESPELL"])]
    open(out + ".md", "w", encoding="utf-8").write("\n".join(md) + "\n")
    print(f"{stem}: {words} words{' + tts-safe' if need_tts else ''}")
