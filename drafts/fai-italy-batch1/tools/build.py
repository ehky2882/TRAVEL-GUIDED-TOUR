"""Build clean .txt, TTS-safe .txt and .md for each tour from src/NN_slug.json.

src JSON: {"title": str, "tts_title": str|null, "clean": str (paragraphs, may contain [beat] lines),
           "respell": [[from, to], ...], "sources": [str], "notes": [str]}
TTS-safe rules: respellings applied (longest first), [beat] lines removed, hyphens -> spaces,
dashes -> commas, digits forbidden (script must already spell numbers), no brackets.
"""
import json, re, sys, pathlib
root = pathlib.Path(__file__).resolve().parent.parent
src, out = root / "src", root / "scripts"
out.mkdir(exist_ok=True)

def tts(text, pairs):
    for a, b in sorted(pairs, key=lambda p: -len(p[0])):
        text = text.replace(a, b)
    text = "\n\n".join(p for p in text.split("\n\n") if p.strip() != "[beat]")
    text = re.sub(r"\s+[—–]\s+", ", ", text)
    text = text.replace("—", ", ").replace("–", " ").replace("-", " ")
    text = re.sub(r" {2,}", " ", text)
    return text

bad = 0
for f in sorted(src.glob("*.json")):
    d = json.loads(f.read_text())
    stem = f.stem
    clean = d["clean"].strip()
    if re.search(r"\d", clean):
        print(f"{stem}: DIGITS in clean script: {re.findall(r'.{0,20}\d+.{0,20}', clean)[:3]}"); bad += 1
    safe = tts(clean, d.get("respell", []))
    ttitle = d.get("tts_title") or tts(d["title"], d.get("respell", []))
    for bad_pat in [r"\[", r"\]", r"\d", r"-", r"[A-Z]{2,}"]:
        m = re.search(bad_pat, safe)
        if m and not (bad_pat == r"[A-Z]{2,}" and safe[m.start():m.end()] in ("I",)):
            print(f"{stem}: TTS-safe violates {bad_pat!r} near: {safe[max(0,m.start()-25):m.end()+25]!r}"); bad += 1
    (out / f"{stem}_clean.txt").write_text(f"{d['title']}\n\n{clean}\n")
    (out / f"{stem}_tts-safe.txt").write_text(f"{ttitle}\n\n{safe}\n")
    words = len(clean.replace('[beat]', '').split())
    md = [f"# {d['title']}", "", f"*{words} words, about {round(words/150*60)} seconds at a natural pace.*", "",
          "## Clean script", "", clean, "", "## TTS-safe script", "", f"**{ttitle}**", "", safe, ""]
    if d.get("respell"):
        md += ["## Respellings", "", "| Written | Spoken as |", "|---|---|"]
        md += [f"| {a} | {b} |" for a, b in d["respell"]] + [""]
    md += ["## Sources read", ""] + [f"- {s}" for s in d["sources"]] + [""]
    if d.get("notes"):
        md += ["## Fact-check notes", ""] + [f"- {n}" for n in d["notes"]] + [""]
    (out / f"{stem}.md").write_text("\n".join(md))
    print(f"{stem}: {words} words")
sys.exit(1 if bad else 0)
