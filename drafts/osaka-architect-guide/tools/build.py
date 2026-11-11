#!/usr/bin/env python3
"""Build the Osaka architect's guide scripts.

For every tour writes, into ../scripts/:
  NN_<slug>_clean.txt     the script as written (house style: years as digits, [beat] marker kept)
  NN_<slug>_tts-safe.txt  phonetic respellings, years and numbers spelled out, no caps, no hyphens,
                          no brackets or markup, [beat] replaced by a paragraph break
  NN_<slug>.md            clean script + respelling table + venue data + primary sources
and ../scripts/00_index.md listing all 34.

Then checks every TTS-safe file: no digits, no hyphens, no brackets, no all-caps words.
Run: python3 -I build.py
"""
import os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from scripts_a import SCRIPTS_A  # noqa: E402
from scripts_b import SCRIPTS_B  # noqa: E402

OUT = os.path.join(os.path.dirname(HERE), "scripts")

# Phonetic respellings: lowercase-style, no caps, no hyphens. Longest keys are applied first.
RESPELL = {
    "Sumiyoshi-zukuri": "Soomee yoshee zookoo ree", "Sumiyoshi Taisha": "Soomee yoshee Tye shah",
    "Sumiyoshi": "Soomee yoshee", "Sorihashi": "Soree hahshee", "Jingu": "Jeengoo", "Ise": "Eesay",
    "Hankai": "Hahn kye", "Tennoji": "Ten noh jee",
    "Dojimahama": "Dohjeemah hahmah", "Kitashinchi": "Keetah sheenchee", "Kajima": "Kahjeemah",
    "Shigaraki": "Sheegah rahkee", "Shiga": "Sheegah", "Masami Ehara": "Mahsahmee Ehhahrah",
    "Zentis": "Zentiss", "Upstairz": "Upstairs", "Crittall": "Krittle",
    "Shin-Kabukiza": "Sheen Kahbookee zah", "Togo Murano": "Toh goh Moorahnoh", "Murano": "Moorahnoh",
    "Kengo Kuma": "Kengoh Koomah", "Kuma": "Koomah", "karahafu": "kahrah hahfoo",
    "Junji Ito": "Joonjee Eetoh", "Gutai": "Gootye", "Jiro Yoshihara": "Jeeroh Yoshee hahrah",
    "Kazuo Shiraga": "Kahzoo oh Sheerahgah", "Atsuko Tanaka": "Ahtsookoh Tahnahkah",
    "Yayoi Kusama": "Yah yoy Koosahmah", "Tsuchi": "Tsoochee", "Kumokumo": "Koomoh koomoh",
    "Midosuji": "Meedoh soojee", "Namba": "Nahmbah", "Kansai": "Kahn sye",
    "Okawa": "Oh kahwah", "Yodo": "Yohdoh", "Tenmabashi": "Tenmah bahshee",
    "Nakanoshima": "Nahkah noh sheemah", "Noum": "Noh oom",
    "Takahiro Matsuo": "Tahkah heeroh Mahtsoo oh", "Kohei Nawa": "Koh hay Nahwah", "Nawa": "Nahwah",
    "Fu and Rai": "Foo and Rye", "Fujin": "Foojeen", "Raijin": "Rye jeen",
    "Hajime Yoneda": "Hahjeemay Yonnay dah", "Hajime": "Hahjeemay", "Edobori": "Eddoh boree",
    "Kindai": "Keendye", "Kobe": "Kohbay", "Michel Bras": "Meeshel Brah", "Hokkaido": "Hokkye doh",
    "Utsubo": "Ootsooboh",
    "Mizuno-yaki": "Meezoonoh yahkee", "Mizuno": "Meezoonoh", "Dotonbori": "Doh tonn boree",
    "okonomiyaki": "okonnomee yahkee", "Okonomiyaki": "Okonnomee yahkee",
    "yoshoku-yaki": "yoh shoh koo yahkee", "yamaimo-yaki": "yahmah eemoh yahkee",
    "Minami": "Meenahmee", "Bib Gourmand": "Bib Goormahn", "Hozenji Yokocho": "Hoh zen jee Yokkoh choh",
    "Hozenji": "Hoh zen jee", "Yokocho": "Yokkoh choh",
    "Imai-cho": "Eemye choh", "Imai Gakki": "Eemye Gahkkee", "Imai": "Eemye", "Nara": "Nahrah",
    "Kitsune": "Keetsoonay", "kitsune": "keetsoonay", "udon": "oodon", "dashi": "dahshee",
    "kombu": "kombo", "Kyushu": "Kyoo shoo", "Nakaza Cuidaore": "Nahkah zah Kwee dah oh ray",
    "Nakaza": "Nahkah zah",
    "Kushikatsu": "Kooshee kahtsoo", "Daruma": "Dahroomah", "Shinsekai": "Sheen sekkye",
    "Tsutenkaku": "Tsoo ten kahkoo", "Yoshie Hyakuno": "Yoshee eh Hyahkoo noh", "Takohishi": "Tahkoh heeshee",
    "Hidekazu Akai": "Heeday kahzoo Ahkye", "Katsuya Ueyama": "Kahtsoo yah Oo eh yahmah",
    "Kyoto": "Kyohtoh", "sen apiece": "sen apiece",
    "Kuromon": "Kooroh mon", "Nipponbashi": "Neeppon bahshee", "Sakai": "Sahkye", "Kii": "Kee",
    "Enmyoji": "En myoh jee", "Doguyasuji": "Doh goo yah soojee",
    "Nayuta": "Nah yootah", "Amerikamura": "Ahmayree kah moorah", "Shinsaibashi-suji": "Sheen sye bahshee soojee",
    "Nishi-Shinsaibashi": "Neeshee Sheen sye bahshee", "Shinsaibashi": "Sheen sye bahshee",
    "Kitahama Retro": "Keetah hahmah Retro", "Kitahama": "Keetah hahmah", "Meiji": "Mayjee",
    "Tosabori": "Toh sah boree", "Godai Tomoatsu": "Goh dye Toh moh ahtsoo", "Naniwabashi": "Nahneewah bahshee",
    "LiLo Coffee Kissa": "Leeloh Coffee Keessah", "LiLo": "Leeloh", "Hotta": "Hottah", "Nakamura": "Nahkah moorah",
    "Shin-Umeda Shokudogai": "Sheen Oomeh dah Shoh koo doh gye", "Umeda": "Oomeh dah",
    "Hankyu": "Hahn kyoo", "JR": "Jay Arr", "Nakazakicho": "Nahkah zahkee choh",
    "TRUCK": "Truck", "Asahi": "Ahsahee", "Tokuhiko Kise": "Toh koo heekoh Keesay",
    "Hiromi Karatsu": "Heeroh mee Kahrah tsoo", "Tamatsukuri": "Tahmah tsookooree", "Nagano": "Nahgahnoh",
    "Shigeki Hattori": "Sheegekkee Hattoree", "graf": "graff",
    "Sennichimae": "Sen neechee mah eh", "Shitennoji": "Shee ten noh jee", "Imamiya Ebisu": "Eemah meeyah Ebbeesoo",
    "dogu": "dohgoo", "Taisho": "Tye shoh",
    "Daimaru": "Dye mahroo", "William Merrell Vories": "William Merrell Vorees", "Vories": "Vorees",
    "Tadao Ando": "Tahdah oh Ahndoh", "Ando": "Ahndoh",
    "Katsuhiko Endo": "Kahtsoo heekoh Endoh", "Endo": "Endoh", "Taiji Fujimori": "Tye jee Foojee moree",
    "Cesar Pelli": "Sayzar Pelly", "Suita": "Soo eetah", "Joan Miró": "Zhoo ahn Meeroh",
    "Jiro Takamatsu": "Jeeroh Tahkah mahtsoo",
    "Einosuke Iwamoto": "Ay noh skay Eewah mohtoh", "Iwamoto": "Eewah mohtoh",
    "Shinichiro Okada": "Sheen eechee roh Ohkahdah", "Kingo Tatsuno": "Keengoh Tahtsoonoh",
    "Yasushi Kataoka": "Yahsooshee Kahtah ohkah",
    "VS.": "Vee Ess", "Umekita": "Oomeh keetah", "Nikken Sekkei": "Neekken Sekkay",
    "Mitsubishi Jisho Sekkei": "Meetsoo beeshee Jeeshoh Sekkay", "SANAA": "Sahnah",
    "Kazuyo Sejima": "Kahzoo yoh Sejjeemah", "Ryue Nishizawa": "Ryoo eh Neeshee zahwah",
    "Daito Manabe": "Dye toh Mahnahbay",
    "Namura": "Nahmoorah", "Kitakagaya": "Keetah kahgah yah", "Kizu": "Keezoo", "Chishima Tochi": "Cheesheemah Tohchee",
    "Hiroshi Hara": "Heeroshee Hahrah", "Hara": "Hahrah", "Takimi Koji": "Tahkeemee Kohjee", "Showa": "Shohwah",
    "Taro Okamoto": "Tahroh Ohkah mohtoh", "Okamoto": "Ohkah mohtoh", "Kenzo Tange": "Kenzoh Tahngay",
    "Tange": "Tahngay", "Kisho Kurokawa": "Keeshoh Kooroh kahwah",
    "Maishima": "Mye sheemah", "Friedensreich Hundertwasser": "Freedenz rysh Hoonderr vahsser",
    "Takeo Yasui": "Tahkay oh Yahsooee", "Yasui": "Yahsooee", "Shoichi Sano": "Shoh eechee Sahnoh",
    "Gas Building Shokudo": "Gas Building Shoh koo doh", "Hiranomachi": "Heerah noh mahchee",
    "Ikoma": "Eekohmah", "So Hyozo": "Soh Hyoh zoh", "Sakaisuji": "Sahkye soojee", "Senba": "Sen bah",
    "Nankai": "Nahn kye", "Jon Jerde": "Jon Jerdee", "Jerde": "Jerdee",
    "Miyakojima-dori": "Meeyah koh jeemah dohree", "nagaya": "nahgah yah", "Tenjinbashisuji": "Ten jeen bahshee soojee",
    "Mizukake Fudo": "Meezoo kahkay Foodoh", "Fudo": "Foodoh", "Kanbi Fujiyama": "Kahn bee Foojee yahmah",
    "Katsura Harudanji": "Kahtsoorah Hahroo dahnjee",
    "Tachu Naito": "Tah choo Nye toh", "Hitachi": "Heetahchee",
    "Chikatsu Asuka Fudoki no Oka": "Cheekahtsoo Ahsookah Foo dohkee noh Ohkah", "Chikatsu Asuka": "Cheekahtsoo Ahsookah",
    "kofun": "kohfoon", "Arc de Triomphe": "Ark duh Tree omf",
}

ONES = "zero one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen".split()
TENS = "_ _ twenty thirty forty fifty sixty seventy eighty ninety".split()

def two(n):
    if n < 20:
        return ONES[n]
    t, o = divmod(n, 10)
    return TENS[t] + ("" if o == 0 else " " + ONES[o])

def year(y):
    hi, lo = divmod(y, 100)
    if 2000 <= y <= 2009:
        return "two thousand" + ("" if y == 2000 else " and " + ONES[y - 2000])
    if lo == 0:
        return two(hi) + " hundred"
    if lo < 10:
        return two(hi) + " oh " + ONES[lo]
    return two(hi) + " " + two(lo)

def tts(text):
    t = text
    t = re.sub(r"\n*\[beat\]\n*", "\n\n", t)          # beat -> natural paragraph pause
    t = t.replace("Expo '70", "Expo seventy")
    t = t.replace("40 Sky Bar", "Forty Sky Bar").replace("50 Best", "Fifty Best")
    for k in sorted(RESPELL, key=len, reverse=True):
        pat = r"(?<![A-Za-z])" + re.escape(k) + r"(?![A-Za-z])"
        t = re.sub(pat, RESPELL[k], t)
    t = re.sub(r"\b(1[0-9]{3}|20[0-9]{2})s\b", lambda m: year(int(m.group(1))) .replace("ty", "ties") if False else year(int(m.group(1))) + "s", t)
    t = re.sub(r"\b(1[0-9]{3}|20[0-9]{2})\b", lambda m: year(int(m.group(1))), t)
    t = t.replace("-", " ")
    t = re.sub(r"[ \t]+", " ", t)
    t = re.sub(r"\n{3,}", "\n\n", t)
    return t.strip() + "\n"

def check(name, t):
    errs = []
    if re.search(r"\d", t): errs.append("digit: " + ", ".join(sorted(set(re.findall(r"\S*\d\S*", t)))))
    if "-" in t: errs.append("hyphen")
    if re.search(r"[\[\]{}<>()*_#`]", t): errs.append("bracket/markup")
    caps = re.findall(r"\b[A-Z]{2,}\b", t)
    if caps: errs.append("caps: " + ", ".join(sorted(set(caps))))
    if errs:
        print(f"FAIL {name}: " + "; ".join(errs))
    return not errs

def main():
    os.makedirs(OUT, exist_ok=True)
    rows, ok = [], True
    for (n, slug, title, tts_title, cat, lat, lon, body, sources) in SCRIPTS_A + SCRIPTS_B:
        base = f"{n:02d}_{slug}"
        clean = f"{title}\n\n{body.strip()}\n"
        safe_title = tts_title or tts(title).strip()
        safe = tts(f"{safe_title}\n\n{body.strip()}")
        open(os.path.join(OUT, base + "_clean.txt"), "w").write(clean)
        open(os.path.join(OUT, base + "_tts-safe.txt"), "w").write(safe)
        ok &= check(base, safe)
        words = len(re.findall(r"[A-Za-z']+", body.replace("[beat]", "")))
        used = [(k, v) for k, v in sorted(RESPELL.items()) if re.search(r"(?<![A-Za-z])" + re.escape(k) + r"(?![A-Za-z])", clean)]
        md = [f"# {n:02d} · {title}", "",
              f"**Category:** {cat} · **Coordinates (WGS-84):** {lat:.6f}, {lon:.6f} · **Length:** {words} words (about {round(words/150*60)} s at 150 wpm)", "",
              "## Script (clean)", "", body.strip().replace("[beat]", "*[beat]*"), "",
              "## TTS-safe version", "", f"See `{base}_tts-safe.txt`. Spoken title: **{safe_title}**.", ""]
        if used:
            md += ["## Respellings used", "", "| Written | Spoken |", "|---|---|"]
            md += [f"| {k} | {v} |" for k, v in used]
            md += [""]
        md += ["## Primary sources read before writing", ""] + [f"- {s}" for s in sources] + [""]
        open(os.path.join(OUT, base + ".md"), "w").write("\n".join(md))
        rows.append(f"| {n:02d} | {title} | {cat} | {lat:.6f}, {lon:.6f} | {words} | `{base}_clean.txt` · `{base}_tts-safe.txt` · `{base}.md` |")
    idx = ["# Osaka: an architect's city guide, audio scripts", "",
           "34 single-stop tours in the Atlas British voice (atlas-audio-tour skill), written after reading each venue's "
           "own site or the best available primary source (listed in each tour's `.md`). Clean + TTS-safe text for every tour.", "",
           "| # | Tour | Category | Lat, Lon | Words | Files |", "|---|---|---|---|---|---|"] + rows + [""]
    open(os.path.join(OUT, "00_index.md"), "w").write("\n".join(idx))
    print(f"wrote {len(rows)} tours to {OUT}; checks {'PASSED' if ok else 'FAILED'}")
    return 0 if ok else 1

if __name__ == "__main__":
    sys.exit(main())
