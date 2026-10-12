#!/usr/bin/env python3
"""Split the Mumbai batch source into clean + TTS script files.

    python3 drafts/mumbai-batch1/tools/build_scripts.py <source.md> <out-dir>

Source format: one block per tour, opened by
    === NN | slug | Title
    Vantage: ...
    ---
    narration ...

Writes, per tour:
    mumbai_NN_<slug>.txt      clean script (keeps [beat] as an authoring marker)
    mumbai_NN_<slug>_TTS.txt  TTS-safe: phonetic respellings (lowercase, no
                              hyphens), no brackets, [beat] -> paragraph break,
                              dashes -> commas, '&' -> 'and'
and one combined mumbai-batch1-scripts.md holding every clean script.

Exits 1 if any TTS file still holds a digit, a hyphen, a bracket, or a
respelling key it failed to replace.
"""
import os
import re
import sys

# Respellings: lowercase, no caps, no hyphens. Longest keys are applied first.
RESPELL = {
    "Chhatrapati Shivaji Maharaj Vastu Sangrahalaya": "chuttra puttee shiva jee maha raj vaastoo sungra haa lie",
    "Chhatrapati Shivaji Maharaj Marg": "chuttra puttee shiva jee maha raj marg",
    "Castella de Aguada": "kass tella day ag waa da",
    "Bal Gangadhar Tilak": "baal gunga dar tilluck",
    "Sitaram Khanderao Vaidya": "seeta raam kaan day rao vied ya",
    "Dadoba Waman Khot": "daa doe baa waa mun kote",
    "Jagannath Shankarseth": "jugger naat shunker sate",
    "Jamsetjee Jejeebhoy": "jum shed jee jee jee boy",
    "Jamsetji": "jum shed jee",
    "Ganesh Chaturthi": "gun aysh chuh toor tee",
    "Senapati Bapat Marg": "say naa puttee baa put marg",
    "Nagindas Master": "nuggin daas master",
    "Shahid Bhagat Singh": "shah heed bug gut sing",
    "Knesseth Eliyahoo": "kuh ness eth elly yah hoo",
    "Jijamata Udyan": "jee jaa maa taa ood yaan",
    "Bomanji Petit": "bo mun jee petty",
    "Kohinoor": "koh ee noor",
    "Khotachiwadi": "koh tah chee waa dee",
    "Kanchanjunga": "kun chun jung gaa",
    "Sangrahalaya": "sungra haa lie",
    "Chowpatty": "chow puttee",
    "Girgaon": "geer gaon",
    "Girangaon": "geer un gaon",
    "Koliwada": "koh lee waa daa",
    "Kolis": "koh leez",
    "Koli": "koh lee",
    "Mumbadevi": "moom baa day vee",
    "Matunga": "mah toong gaa",
    "Udupi": "oo doo pee",
    "Kamath": "kaa mutt",
    "Kamala": "kaa muh laa",
    "Parel": "puh rail",
    "Colaba": "kuh laa baa",
    "Bunder": "bunder",
    "Nariman": "naa ree mun",
    "Worli": "wor lee",
    "Bandra": "baan draa",
    "Byculla": "bye kulla",
    "Tardeo": "tar day oh",
    "Dadar": "daa dur",
    "Kelkar": "kel car",
    "Juhu": "joo hoo",
    "Mahim": "maa him",
    "Chimbai": "chim bye",
    "Charni": "char nee",
    "Cumballa": "kum bulla",
    "Kurla": "koor laa",
    "Malad": "maa lud",
    "Alibaug": "ah lee baag",
    "Elephanta": "elly fanta",
    "Gymkhana": "jim kaa naa",
    "Azad Maidan": "aa zaad my daan",
    "Maidan": "my daan",
    "Kala Ghoda": "kaa laa go daa",
    "Ghoda": "go daa",
    "Chor Bazaar": "chor buzz aar",
    "Bhendi Bazaar": "bhen dee buzz aar",
    "Bazaar": "buzz aar",
    "Shor": "shor",
    "chor": "chor",
    "shor": "shor",
    "Bhau Daji Lad": "bow daa jee laad",
    "Bhau Daji": "bow daa jee",
    "Wittet's": "wittet's",
    "Wittet": "wittet",
    "Correa": "kor ree uh",
    "Trishna": "trish naa",
    "Ayub's": "eye yoobs",
    "Ayub": "eye yoob",
    "Ajaz": "aa jaaz",
    "Shaikh": "shake",
    "Bhagnani": "bug naa nee",
    "Mohandas": "moe hun daas",
    "Sindhi": "sin dee",
    "pani puri": "paa nee poo ree",
    "puris": "poo reez",
    "puri": "poo ree",
    "wala": "waa laa",
    "Konkan": "kong kun",
    "Mangalore": "mang guh lore",
    "koliwada": "koh lee waa daa",
    "rawas": "raa vus",
    "reshmi": "resh mee",
    "seekh": "seek",
    "baida": "bay daa",
    "paratha": "puh raa taa",
    "paneer": "puh neer",
    "Dosas": "doe saaz",
    "Idlis": "id leez",
    "Upma": "oop maa",
    "rava": "raa vaa",
    "ghee": "ghee",
    "bhel puri": "bell poo ree",
    "pav bhaji": "paav baa jee",
    "sev": "sayv",
    "kulfi": "kool fee",
    "kurtas": "kur taaz",
    "chawls": "chawlz",
    "gaothan": "gao tun",
    "jalapeño": "hala pain yo",
    "Kejriwal": "kej ree waal",
    "Nayudu": "nai doo",
    "Lala Amarnath": "laa laa um ur naat",
    "Naoroji": "now roe jee",
    "Dadabhai": "daa daa bye",
    "Kerse": "kurss",
    "Mirza": "meer zaa",
    "Vaidya": "vied ya",
    "Thadani": "taa daa nee",
    "Watsa": "wat saa",
    "Mallyeka": "mall yay kaa",
    "Bhanage": "bah naa gay",
    "Zacharias": "zakka rye us",
    "Cardoz": "kar doze",
    "Shonan Purie Trehan": "show nun poo ree tray hun",
    "Shilpa Shetty": "shil paa shetty",
    "Ranjit Bindra": "run jeet bin draa",
    "Minal": "mee naal",
    "Tendulkar": "ten dull kar",
    "Sachin": "sutch in",
    "Shivaji": "shiva jee",
    "Maratha": "muh raa taa",
    "Marathi": "muh raa tee",
    "Marwari": "mar waa ree",
    "Jehangir": "juh haan geer",
    "Kapur Mahal": "kuh poor muh hul",
    "Zaver Mahal": "zuh ver muh hul",
    "Keval Mahal": "kay vul muh hul",
    "Mahal": "muh hul",
    "Keval": "kay vul",
    "Zaver": "zuh ver",
    "Kapur": "kuh poor",
    "Saracenic": "sarra sennick",
    "Rajput": "raaj poot",
    "Moorish": "moorish",
    "Mughal": "moo gul",
    "Deccan": "deck un",
    "Udyan": "ood yaan",
    "Mahatma Gandhi": "muh haat maa gaan dee",
    "Gandhi": "gaan dee",
    "Marg": "marg",
    "Naka": "naa kaa",
    "Pali": "paa lee",
    "Bhavan": "bah vun",
    "Radha": "raa daa",
    "Sai Baba": "sigh baa baa",
    "Kemps": "kemps",
    "Dr E Moses": "doctor ee moses",
    "N C Kelkar": "en see kel car",
    "C K Nayudu": "see kay nai doo",
    "D N Mirza": "dee en meer zaa",
    "F G B Hawkins": "eff gee bee hawkins",
    "V B Gandhi": "vee bee gaan dee",
    "Dr Bhau Daji Lad": "doctor bow daa jee laad",
    "Dr ": "doctor ",
    "INTACH": "in tack",
    "UNESCO": "you nesco",
    "ELCO": "elko",
    "AER": "air",
    "DJs": "dee jays",
    "DJ": "dee jay",
    "Eau Bar": "oh bar",
    "Bombayites": "bom bay ites",
    "Irani": "ee raa nee",
    "Iranis": "ee raa neez",
    "Zoroastrian": "zorro ass tree un",
    "Baghdadi": "bag daa dee",
    "Gujarati": "goo juh raa tee",
    "Karnataka": "kar naa tuh kaa",
    "Maharashtra's": "maa haa raash traz",
    "Partition": "partition",
    "Leopold": "lee oh pold",
    "Trident": "trident",
    "Nataraj": "nut uh raaj",
    "Tilak": "tilluck",
    "Khot": "kote",
}
SPOKEN_FIXES = [
    (r"\[beat\]", ""),
    (r"\s*&\s*", " and "),
    (r"(\w)–(\w)", r"\1 \2"),      # unspaced en dash: Bandra–Worli
    (r"\s*[—–]\s*", ", "),        # em/en dash
    (r"(\w)-(\w)", r"\1 \2"),      # hyphenated compounds
    (r"\bCafé\b", "cafay"),
    (r"\bcafé\b", "cafay"),
    (r"\bcafés\b", "cafays"),
    (r"\bcafe\b", "caff ay"),
    (r"\bCafe\b", "caff ay"),
]


def tts(text):
    for k in sorted(RESPELL, key=len, reverse=True):
        text = re.sub(r"(?<![\w])" + re.escape(k) + r"(?![\w])", RESPELL[k], text)
    for pat, rep in SPOKEN_FIXES:
        text = re.sub(pat, rep, text)
    text = re.sub(r",\s*,", ",", text)
    text = re.sub(r",\s*\.", ".", text)
    text = re.sub(r",\s*([:;?])", r"\1", text)
    text = re.sub(r"^,\s*", "", text, flags=re.M)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip() + "\n"


def main():
    src, out = sys.argv[1], sys.argv[2]
    os.makedirs(out, exist_ok=True)
    blocks = re.split(r"^=== ", open(src, encoding="utf-8").read(), flags=re.M)[1:]
    combined, bad = ["# Mumbai batch 1: clean scripts\n"], []
    for b in blocks:
        head, rest = b.split("\n", 1)
        num, slug, title = [x.strip() for x in head.split("|")]
        vantage, body = rest.split("\n---\n", 1)
        body = body.strip() + "\n"
        clean = f"MUMBAI — {num} — {title.upper()}\n{vantage.strip()}\n---\n{body}"
        base = f"mumbai_{num}_{slug.replace('-', '_')}"
        open(os.path.join(out, base + ".txt"), "w", encoding="utf-8").write(clean)
        t_title = tts(title).strip().upper()
        t_body = tts(body)
        open(os.path.join(out, base + "_TTS.txt"), "w", encoding="utf-8").write(
            f"MUMBAI, {num}, {t_title}\n---\n{t_body}")
        for pat, why in [(r"\d", "digit"), (r"-", "hyphen"), (r"[\[\]<>{}()]", "bracket")]:
            if re.search(pat, t_body):
                bad.append(f"{base}: {why} left in TTS body: {re.findall('.{0,20}'+pat+'.{0,20}', t_body)[:2]}")
        words = len(body.replace("[beat]", "").split())
        combined.append(f"\n---\n\n## {num} · {title}\n\n*{vantage.strip()}* · {words} words · about {round(words/150*60)} s\n\n{body}")
        print(f"{num}  {words:4d} words  {base}")
    open(os.path.join(out, "mumbai-batch1-scripts.md"), "w", encoding="utf-8").write("".join(combined))
    if bad:
        print("\n".join(bad)); sys.exit(1)
    print(f"OK — {len(blocks)} tours, clean + TTS written, TTS bodies free of digits/hyphens/brackets")


if __name__ == "__main__":
    main()
