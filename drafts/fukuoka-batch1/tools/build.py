#!/usr/bin/env python3
"""Build the Fukuoka batch: clean .txt, TTS-safe .txt and a .md sheet per tour.

Usage: python3 -I build.py   (run from this folder)
Reads source_clean.txt and meta.json; writes ../scripts/.
"""
import json, os, re

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "scripts")

ONES = "zero one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen".split()
TENS = "_ _ twenty thirty forty fifty sixty seventy eighty ninety".split()

def two(n):
    if n < 20:
        return ONES[n]
    t, o = divmod(n, 10)
    return TENS[t] + ("" if o == 0 else " " + ONES[o])

def year(n):
    """British spoken year, no hyphens: 1905 nineteen oh five, 2005 two thousand and five, 2023 twenty twenty three."""
    if n < 1000:
        h, r = divmod(n, 100)
        return ONES[h] + " " + (two(r) if r >= 10 else "oh " + ONES[r])
    if 2000 <= n <= 2009:
        return "two thousand" + ("" if n == 2000 else " and " + ONES[n - 2000])
    hi, lo = divmod(n, 100)
    if lo == 0:
        return two(hi) + " hundred"
    return two(hi) + " " + (two(lo) if lo >= 10 else "oh " + ONES[lo])

def decade(n):  # 1960 -> nineteen sixties
    hi, lo = divmod(n, 100)
    w = two(lo)
    w = w[:-1] + "ies" if w.endswith("y") else w + "s"
    return two(hi) + " " + w

def numbers(text):
    text = re.sub(r"\b(1[0-9]{3}|20[0-9]{2})s\b", lambda m: decade(int(m.group(1))), text)
    text = re.sub(r"\b([0-9]{3,4})\b", lambda m: year(int(m.group(1))), text)
    return text

def tts(text, resp):
    text = text.replace("[beat]\n\n", "").replace("\n[beat]", "").replace("[beat]", "")
    text = numbers(text)
    text = text.replace("B·B·B", "three bee").replace("BBB&", "three bee and")
    text = text.replace("&", " and ")
    for a, b in sorted(resp.items(), key=lambda kv: -len(kv[0])):
        text = re.sub(r"(?<![\w])" + re.escape(a) + r"(?![\w])", b, text)
    text = re.sub(r"(?<=\w)-(?=\w)", " ", text)       # no hyphens anywhere
    text = re.sub(r"\b([A-Z]{2,})\b", lambda m: m.group(1).capitalize(), text)  # no all-caps
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip() + "\n"

def main():
    meta = json.load(open(os.path.join(HERE, "meta.json"), encoding="utf-8"))
    resp = meta["respellings"]
    src = open(os.path.join(HERE, "source_clean.txt"), encoding="utf-8").read()
    os.makedirs(OUT, exist_ok=True)
    blocks = re.split(r"^=== ", src, flags=re.M)[1:]
    rows = []
    for b in blocks:
        head, body = b.split("\n", 1)
        num_slug, title = [x.strip() for x in head.split("|", 1)]
        num, slug = num_slug.split(" ", 1)
        body = body.strip()
        m = meta["tours"][slug]
        clean = f"{title}\n\n{body}\n"
        tts_title = m.get("tts_title", title)
        safe = tts(f"{tts_title}\n\n{body}\n", resp)
        stem = f"{num}_{slug.replace('-', '_')}"
        open(os.path.join(OUT, stem + "_clean.txt"), "w", encoding="utf-8").write(clean)
        open(os.path.join(OUT, stem + "_tts-safe.txt"), "w", encoding="utf-8").write(safe)
        words = len(re.findall(r"[A-Za-z0-9'’·&-]+", body.replace("[beat]", "")))
        used = {a: r for a, r in resp.items() if re.search(r"(?<![\w])" + re.escape(a) + r"(?![\w])", f"{title}\n{body}")}
        md = [f"# {num} · {title}", "",
              f"**Category:** {m['category']} · **Google Maps name:** {m['gmaps']} · **Coordinates (WGS-84):** {m['lat']}, {m['lon']}", "",
              f"**Length:** {words} words, about {round(words/150*60/10)*10} seconds at a natural pace. "
              f"**Files:** `{stem}_clean.txt`, `{stem}_tts-safe.txt`", "",
              "## Clean script", "", f"**{title}**", "", body, "",
              "## Respellings used in the TTS-safe version", ""]
        if tts_title != title:
            md.append(f"- Title: **{title}** → *{tts_title}*")
        md += [f"- {a} → *{r}*" for a, r in used.items()] or ["- None"]
        md += ["", "Years are spelled out in the TTS-safe file, `[beat]` is replaced by a paragraph break, "
               "and hyphens and all-caps are removed.", "", "## Sources read before writing", ""]
        md += [f"- {s}" for s in m["sources"]]
        if m.get("notes"):
            md += ["", "## Notes", "", m["notes"]]
        open(os.path.join(OUT, stem + ".md"), "w", encoding="utf-8").write("\n".join(md) + "\n")
        rows.append((num, title, m["category"], m["gmaps"], m["lat"], m["lon"], words, stem))
    idx = ["# Fukuoka city guide: audio tour scripts", "",
           "Thirty single-stop tours from the Fukuoka architect's-guide list. Each has a clean script, a TTS-safe script and a sheet "
           "(`.md`) with respellings, coordinates and the sources read before writing.", "",
           "| # | Tour | Category | Google Maps name | Coordinates | Words | Files |", "|---|---|---|---|---|---|---|"]
    for num, title, cat, gm, lat, lon, w, stem in rows:
        idx.append(f"| {num} | {title} | {cat} | {gm} | {lat}, {lon} | {w} | `{stem}` |")
    open(os.path.join(OUT, "00_INDEX.md"), "w", encoding="utf-8").write("\n".join(idx) + "\n")
    print(f"built {len(rows)} tours")

if __name__ == "__main__":
    main()
