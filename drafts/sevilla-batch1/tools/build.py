"""Build TTS-safe .txt and .md files from the *_clean.txt scripts.
Usage: python3 -I build.py <scripts dir>
"""
import re, sys, pathlib, importlib.util
here = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("resp", here / "respellings.py")
resp = importlib.util.module_from_spec(spec); spec.loader.exec_module(resp)
sys.path.insert(0, str(here)); from venues import VENUES

table = {**resp.WORDS, **resp.PHRASES}
keys = sorted(table, key=len, reverse=True)
rx = re.compile(r"(?<![\w])(" + "|".join(re.escape(k) for k in keys) + r")(?![\w])")

def tts(text):
    used = {}
    def sub(m):
        k = m.group(1); used[k] = table[k]; return table[k]
    out = rx.sub(sub, text)
    out = re.sub(r"^\s*\[beat\]\s*$", "", out, flags=re.M)
    out = out.replace("—", ", ").replace("-", " ").replace('"', "").replace("“", "").replace("”", "")
    out = re.sub(r"[\[\]\(\)\{\}<>*_#]", "", out)
    out = re.sub(r"\n{3,}", "\n\n", out).strip() + "\n"
    if re.search(r"\d", out): raise SystemExit("digit left in TTS text:\n" + out[:200])
    if re.search(r"\b[A-Z]{2,}\b", out): raise SystemExit("caps left: " + str(re.findall(r"\b[A-Z]{2,}\b", out)))
    return out, used

d = pathlib.Path(sys.argv[1])
for v in VENUES:
    clean = d / f"{v['n']:02d}_{v['slug']}_clean.txt"
    text = clean.read_text()
    t, used = tts(text)
    (d / f"{v['n']:02d}_{v['slug']}_tts-safe.txt").write_text(t)
    title, body = text.split("\n", 1)
    words = len(text.split())
    md = [f"# {v['n']:02d} · {title}", "",
          f"- **Category:** {v['cat']}",
          f"- **Google Maps name:** {v['gmaps']}",
          f"- **Coordinates (WGS-84):** {v['lat']}, {v['lon']}",
          f"- **Length:** {words} words, about {round(words/150*60/10)*10} seconds at a natural pace",
          "", "## Script (clean)", "", body.strip().replace("[beat]", "*[beat]*"), "",
          "## Respellings used in the TTS-safe version", ""]
    real = {k: w for k, w in used.items() if k != w and k not in ("de","De","la","las","los","y","La","Las")}
    if real:
        md += ["| As written | TTS-safe |", "|---|---|"] + [f"| {k} | {w} |" for k, w in sorted(real.items())]
    else:
        md.append("None.")
    md += ["", "`[beat]` is removed in the TTS-safe version and replaced with a paragraph break." , "",
           "## Sources read before writing", ""] + [f"- {s}" for s in v["sources"]] + [""]
    (d / f"{v['n']:02d}_{v['slug']}.md").write_text("\n".join(md))
print("built", len(VENUES))
