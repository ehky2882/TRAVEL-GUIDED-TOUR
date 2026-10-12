#!/usr/bin/env python3
"""Build the Kuala Lumpur architect's-guide scripts.

For every tour in scripts_part*.py this writes four files to ../scripts/:
  NN_slug_clean.txt / .md      — the authoring script ([beat] kept, years as digits)
  NN_slug_tts-safe.txt / .md   — phonetic respellings, no caps, no hyphens, no
                                  brackets, no [beat] (paragraph break instead),
                                  years and dates spelled out in full
It also writes ../coordinates.tsv and two combined files, then lints every
TTS-safe text and exits 1 if any rule is broken.
"""
import glob, importlib.util, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, "scripts")

tours = []
for f in sorted(glob.glob(os.path.join(HERE, "scripts_part*.py"))):
    sp = importlib.util.spec_from_file_location(os.path.basename(f)[:-3], f)
    m = importlib.util.module_from_spec(sp); sp.loader.exec_module(m)
    tours += m.TOURS

ONES = "zero one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen".split()
TENS = "_ _ twenty thirty forty fifty sixty seventy eighty ninety".split()
def two(n):
    if n < 20: return ONES[n]
    t, o = divmod(n, 10)
    return TENS[t] + ("" if o == 0 else " " + ONES[o])
def year(y):
    hi, lo = divmod(y, 100)
    if y >= 2000 and y < 2010: return "two thousand" + ("" if lo == 0 else " and " + ONES[lo])
    if lo == 0: return two(hi) + " hundred"
    if lo < 10: return two(hi) + " oh " + ONES[lo]
    return two(hi) + " " + two(lo)
def decade(y):  # 1960s -> nineteen sixties
    hi, lo = divmod(y, 100)
    w = two(lo)
    w = w[:-1] + "ies" if w.endswith("y") else w + "s"
    return two(hi) + " " + w
ORD = {1:"first",2:"second",3:"third",4:"fourth",5:"fifth",8:"eighth",9:"ninth",10:"tenth",
       12:"twelfth",15:"fifteenth",18:"eighteenth",23:"twenty third",26:"twenty sixth",
       28:"twenty eighth",30:"thirtieth",31:"thirty first"}

# Phonetic respellings for a British TTS voice. Longest keys first; whole words.
RESPELL = {
 "Masjid Negara": "Mahsjid Neh gah rah", "Muzium Negara": "Moo zee um Neh gah rah",
 "Perpustakaan Negara Malaysia": "Per poo stah kah ahn Neh gah rah Malaysia",
 "Tugu Negara": "Too goo Neh gah rah", "Negeri Sembilan": "Neh gree Sem bee lahn",
 "Rumah Penghulu Abu Seman": "Roo mah Peng hoo loo Ah boo Seh mahn",
 "Badan Warisan": "Bah dahn Wah ree sahn", "Masjid Jamek": "Mahsjid Jah mek",
 "Sin Sze Si Ya": "Sin See See Yah", "Sin Sze Ya": "Sin See Yah", "Si Sze Ya": "See See Yah",
 "Kwai Chai Hong": "Kwhy Chye Hong", "Thean Hou": "Tee ahn How", "Tian Hou": "Tee en How",
 "Shui Wei Sheng Niang": "Shway Way Shung Nee ahng",
 "Menara Tabung Haji": "Meh nah rah Tah boong Hah jee", "Tabung Haji": "Tah boong Hah jee",
 "Menara Tun Perak": "Meh nah rah Toon Peh rak", "Menara Merdeka Maybank": "Meh nah rah Mer day kah Maybank",
 "Menara Maybank": "Meh nah rah Maybank", "Menara KH": "Meh nah rah Kay Aitch",
 "Kompleks Dayabumi": "Kom pleks Dye ah boo mee", "Dayabumi": "Dye ah boo mee",
 "Bangunan Parlimen Malaysia": "Bah ngoo nahn Par lee men Malaysia",
 "Bangunan Zhongshan": "Bah ngoo nahn Jong shahn", "Zhongshan": "Jong shahn",
 "Taman Eko Rimba Kuala Lumpur": "Tah mahn Eh koh Rim bah Kuala Lumpur",
 "Dataran Merdeka": "Dah tah rahn Mer day kah", "Stadium Merdeka": "Stadium Mer day kah",
 "Merdeka 118": "Mer day kah one one eight", "Merdeka": "Mer day kah", "Makam Pahlawan": "Mah kahm Pah lah wahn",
 "Dewan Rakyat": "Day wahn Rahk yaht", "Dewan Negara": "Day wahn Neh gah rah",
 "Pasar Seni": "Pah sar Seh nee", "Pasar Budaya": "Pah sar Boo dye ah",
 "Medan Pasar": "Meh dahn Pah sar", "Kampung Attap": "Kahm poong Ah tahp",
 "Kampung Baru": "Kahm poong Bah roo", "Bukit Bintang": "Boo kit Bin tahng",
 "Bukit Nanas": "Boo kit Nah nahs", "Bukit Aman": "Boo kit Ah mahn",
 "Changkat Bukit Bintang": "Chahng kaht Boo kit Bin tahng",
 "Jalan Sultan Hishamuddin": "Jah lahn Sool tahn Hee shah moo din",
 "Jalan Sultan Ismail": "Jah lahn Sool tahn Iss my eel",
 "Jalan Tun H.S. Lee": "Jah lahn Toon Aitch Ess Lee", "Jalan Tun Perak": "Jah lahn Toon Peh rak",
 "Jalan Tun Razak": "Jah lahn Toon Rah zak", "Jalan Raja Chulan": "Jah lahn Rah jah Choo lahn",
 "Jalan Raja Laut": "Jah lahn Rah jah Lowt", "Jalan Raja": "Jah lahn Rah jah",
 "Jalan Kamunting": "Jah lahn Kah moon ting", "Jalan Dang Wangi": "Jah lahn Dahng Wahng ee",
 "Jalan Kia Peng": "Jah lahn Kee ah Peng", "Jalan Cenderasari": "Jah lahn Chen deh rah sah ree",
 "Jalan Petaling": "Jah lahn Peh tah ling", "Jalan Balai Polis": "Jah lahn Bah lye Poh liss",
 "Jalan Sin Chew Kee": "Jah lahn Sin Chew Kee", "Jalan Hang Kasturi": "Jah lahn Hahng Kahs too ree",
 "Jalan Lembah Perdana": "Jah lahn Lem bah Per dah nah", "Jalan Perdana": "Jah lahn Per dah nah",
 "Jalan Damansara": "Jah lahn Dah mahn sah rah", "Jalan Parlimen": "Jah lahn Par lee men",
 "Jalan Binjai": "Jah lahn Bin jye", "Jalan Rotan": "Jah lahn Roh tahn", "Jalan Riong": "Jah lahn Ree ong",
 "Jalan Stonor": "Jah lahn Stonor", "Jalan Ceylon": "Jah lahn Ceylon", "Jalan Galloway": "Jah lahn Galloway",
 "Jalan Pudu": "Jah lahn Poo doo", "Jalan Sultan": "Jah lahn Sool tahn", "Jalan Saloma": "Jah lahn Sah loh mah",
 "Lebuh Pudu": "Leh boo Poo doo", "Lebuh Ampang": "Leh boo Ahm pahng",
 "Lorong Panggung": "Loh rong Pahng goong", "Persiaran KLCC": "Per see ah rahn Kay El See See",
 "Persiaran Petronas": "Per see ah rahn Petronas",
 "Perdana Botanical Garden": "Per dah nah Botanical Garden",
 "Raja Chulan": "Rah jah Choo lahn", "Jalan": "Jah lahn",
 "Hijjas Kasturi Associates": "Hee jahs Kahs too ree Associates", "Hijjas Kasturi": "Hee jahs Kahs too ree",
 "Hijjas": "Hee jahs", "Baharuddin Abu Kassim": "Bah hah roo din Ah boo Kah sim",
 "Hisham Albakri": "Hee shahm Al bah kree", "Ho Kok Hoe": "Hoh Kok Hoh",
 "Tunku Abdul Rahman": "Toon koo Ab dool Rah mahn", "Mahathir Mohamad": "Mah hah teer Moh hah mahd",
 "Sultan Abdul Samad": "Sool tahn Ab dool Sah mahd", "Yap Ah Loy": "Yap Ah Loy",
 "Seng Meng Lee": "Seng Meng Lee", "Chung Piang Lai": "Choong Pee ahng Lye",
 "Sungai Ujong": "Soong eye Oo jong", "Kapitan Cina": "Kah pee tahn Chee nah", "Kapitan": "Kah pee tahn",
 "Ho Kee Soon": "Hoh Kee Soon", "Ho Sook Chan": "Hoh Sook Chahn", "Ho Kow": "Hoh Cow",
 "Hainam": "Hye nahm", "Hainanese": "Hye nah neez", "Hainan": "Hye nahn",
 "Suryati Jawirunnah": "Soor yah tee Jah wee roo nah", "Zainal Abidin Hassan": "Zye nahl Ah bee din Hah sahn",
 "Yuen Sze To": "Yoo en See Toh", "Lissa Yeoh": "Lissa Yoh", "Way Cheng Yeoh": "Way Cheng Yoh",
 "Darren Teoh": "Darren Tay oh", "Teoh": "Tay oh", "Ng Ping Ho": "Eng Ping Hoh",
 "Cheryl Samad": "Cheryl Sah mahd", "Mervyn Lee": "Mervyn Lee", "Choo Kia Peng": "Choo Kee ah Peng",
 "Phang": "Fahng", "Yong Koon": "Yong Koon", "Ngeok Foh": "Nyok Foh",
 "Rob Tan": "Rob Tan", "Liza Ho": "Liza Hoh", "CK Kho": "See Kay Koh",
 "Shin Chang": "Shin Chahng", "Shin Tseng": "Shin Tsung",
 "James Robert Vethavanam": "James Robert Veh tah vah nahm",
 "Keys and Dowdeswell": "Keys and Dowdz well", "Felix de Weldon": "Felix de Weldon",
 "Stanley Jewkes": "Stanley Jooks", "William Ivor Shipley": "William Ivor Shipley",
 "Hoessein Enas": "Hoo sayn Eh nahs", "Yee I-Lann": "Yee Ee Lahn",
 "Pinaree Sanpitak": "Pee nah ree Sahn pee tahk", "Ai Weiwei": "Eye Way way",
 "Divina Proportione": "Dee vee nah Pro por tsee oh neh", "Burle Marx": "Burl Marks",
 "César Pelli": "Say zar Pelly", "Rub el Hizb": "Roob el Hizb",
 "Kumpulan Akitek": "Koom poo lahn Ah kee tek", "Arkitek MAA": "Ar kee tek Em Ay Ay",
 "BEP Architects": "Bee Ee Pee Architects", "VERITAS Design Group": "Veritas Design Group",
 "Bai Chuan Management": "Bye Chwahn Management", "Think City": "Think City",
 "Yayasan Ilham": "Yah yah sahn Il hahm", "ILHAM Gallery": "Il hahm Gallery", "ILHAM": "Il hahm",
 "Ilham Tower": "Il hahm Tower", "Ilham": "Il hahm",
 "Tandang Records": "Tahn dahng Records", "Royal Selangor": "Royal Seh lahng or",
 "Selangor": "Seh lahng or", "Setapak": "Seh tah pahk", "Terengganu": "Teh reng gah noo",
 "Istana Satu": "Iss tah nah Sah too", "Kedah": "Keh dah", "Johor": "Joh hor", "Melaka": "Meh lah kah",
 "Malacca": "Mah lah kah", "Shah Alam": "Shah Ah lahm", "Bangsar": "Bahng sar", "Pudu": "Poo doo",
 "Gombak": "Gom bak", "Klang Valley": "Klahng Valley", "Klang": "Klahng", "Karlshamn": "Karls hahm",
 "Robson Heights": "Robson Heights", "Mazu": "Mah zoo", "Guanyin": "Gwahn yin",
 "Bendahara": "Ben dah hah rah", "Tun Perak": "Toon Peh rak", "Tun Razak": "Toon Rah zak",
 "Tuanku": "Too ahn koo", "Petaling": "Peh tah ling", "Chi Cheung Kai": "Chee Chung Kye",
 "Kamunting": "Kah moon ting", "Dang Wangi": "Dahng Wahng ee",
 "Saloma Link": "Sah loh mah Link", "Saloma": "Sah loh mah",
 "Dewakan": "Day wah kahn", "dewa": "day wah", "makan": "mah kahn",
 "Yut Kee": "Yoot Kee", "Sek Yuen": "Sek Yoo en", "Restoran": "Res toh rahn",
 "Bijan": "Bee jahn", "Pahit": "Pah hit", "pahit": "pah hit", "Trigona": "Trig oh nah",
 "Ah Loke": "Ah Loke", "Nan Tong": "Nahn Tong", "BackHome": "Back Home",
 "nasi lemak": "nah see leh mak", "Nasi Lemak": "Nah see Leh mak", "Nasi lemak": "Nah see leh mak",
 "Tanglin": "Tang lin", "sambal": "sahm bahl", "kopitiams": "koh pee tee ahms", "kopitiam": "koh pee tee ahm",
 "kopi": "koh pee", "kaya": "kah yah", "roti babi": "roh tee bah bee",
 "rendang": "ren dahng", "masak lemak": "mah sak leh mak", "pandan": "pahn dahn",
 "assam boi": "ah sahm boy", "kelulut": "keh loo loot", "madu": "mah doo",
 "limau hantu": "lee mow hahn too", "Buah keluak": "Boo ah keh loo ak", "buah keluak": "boo ah keh loo ak",
 "kemili": "keh mee lee", "kelarai": "keh lah rye", "kain pelikat": "kine peh lee kaht",
 "RuMa": "Roo mah", "rumah": "roo mah", "penghulu": "peng hoo loo", "Penghulu": "Peng hoo loo",
 "sirih junjung": "see ree joon joong", "tengkolok": "teng koh lok", "songket": "song ket",
 "keris": "keh riss", "keluak": "keh loo ak", "iwan": "ee wahn", "chhatris": "chut trees",
 "wantan": "won ton", "pipa": "pee pah", "Abu Seman": "Ah boo Seh mahn",
 "KLoé Hotel": "Klo ee Hotel", "KLoé": "Klo ee", "Chloe": "Klo ee",
 "LOKL Coffee Co": "Lokal Coffee Company", "LOKL": "Lokal", "PS150": "Pee Ess one fifty",
 "REXKL": "Rex Kay El", "BookXcess": "Book Excess", "APW": "Ay Pee Double you", "VCR": "Vee See Ar",
 "KLCC Park": "Kay El See See Park", "KLCC": "Kay El See See", "KL Tower": "Kay El Tower",
 "KL Forest Eco Park": "Kay El Forest Eco Park", "KL Sentral": "Kay El Sentral", "KL": "Kay El",
 "KDU": "Kay Dee You", "YTL": "Why Tee El", "UNESCO": "Yoo nes koh", "Komuter": "Commuter",
 "A. B. Hubback": "Ay Bee Hubback", "A. C. Norman": "Ay See Norman", "R. A. J. Bidwell": "Ar Ay Jay Bidwell",
 "T. Y. Lee": "Tee Why Lee", "B-29": "Bee twenty nine",
}
KEYS = sorted(RESPELL, key=len, reverse=True)
PAT = re.compile("|".join(r"(?<![\w])" + re.escape(k) + r"(?![\w])" for k in KEYS))
MONTHS = "January February March April May June July August September October November December".split()

def tts(text):
    t = text.replace("[beat]\n\n", "").replace("[beat]", "")
    t = PAT.sub(lambda m: RESPELL[m.group(0)], t)
    # dates: "31 August 1957" -> "the thirty first of August, nineteen fifty seven"
    t = re.sub(r"\b(\d{1,2}) (%s) (\d{4})\b" % "|".join(MONTHS),
               lambda m: f"the {ORD[int(m.group(1))]} of {m.group(2)}, {year(int(m.group(3)))}", t)
    t = re.sub(r"\b(\d{1,2}) (%s)\b" % "|".join(MONTHS),
               lambda m: f"the {ORD[int(m.group(1))]} of {m.group(2)}", t)
    t = re.sub(r"\b(1[0-9]|20)(\d0)s\b", lambda m: decade(int(m.group(0)[:4])), t)
    t = re.sub(r"\b(1[5-9]\d\d|20[0-4]\d)\b", lambda m: year(int(m.group(0))), t)
    t = t.replace(" — ", ", ").replace("—", ", ").replace("–", " ")
    t = re.sub(r"(?<=\w)-(?=\w)", " ", t)
    t = t.replace("é", "e").replace("’", "'")
    t = re.sub(r"\n{3,}", "\n\n", t)
    return t

def lint(name, t):
    errs = []
    for pat, why in [(r"\d", "digit"), (r"-", "hyphen"), (r"[\[\]\(\)\{\}<>*_#`]", "bracket/markup"),
                     (r"\b[A-Z]{2,}\b", "ALL-CAPS word"), (r"\bbeat\b", "beat marker")]:
        for m in re.finditer(pat, t):
            errs.append(f"{name}: {why}: …{t[max(0,m.start()-25):m.end()+25]!r}")
    return errs

os.makedirs(OUT, exist_ok=True)
errors, combo_clean, combo_tts, tsv = [], [], [], []
for t in tours:
    base = f"{t['num']}_{t['slug']}"
    clean = f"{t['title']}\n\n{t['text'].strip()}\n"
    ttitle = PAT.sub(lambda m: RESPELL[m.group(0)], t["title"]).replace("(", "").replace(")", "").replace("é", "e")
    tsafe = tts(f"{ttitle}\n\n{t['text'].strip()}\n")
    errors += lint(base, tsafe)
    meta = (f"- **Google Maps name:** {t['gmaps']}\n- **Category:** {t['category']}\n"
            f"- **Coordinates (WGS-84):** {t['lat']:.6f}, {t['lon']:.6f}\n")
    body_md = t['text'].strip()
    files = {
        f"{base}_clean.txt": clean,
        f"{base}_tts-safe.txt": tsafe,
        f"{base}_clean.md": f"# {t['title']}\n\n{meta}- **Version:** clean (authoring script; `[beat]` marks the engineered pause)\n\n---\n\n{body_md}\n",
        f"{base}_tts-safe.md": f"# {t['title']} (TTS-safe)\n\n{meta}- **Version:** TTS-safe — paste the text below the rule into the TTS tool\n\n---\n\n{tsafe.split(chr(10),2)[2].strip()}\n",
    }
    for fn, body in files.items():
        with open(os.path.join(OUT, fn), "w", encoding="utf-8") as fh: fh.write(body)
    combo_clean.append(f"## {t['num']} · {t['title']}\n\n*{t['category']} · {t['gmaps']} · {t['lat']:.6f}, {t['lon']:.6f}*\n\n{body_md}\n")
    combo_tts.append(tsafe.strip() + "\n")
    tsv.append(f"{t['num']}\t{t['slug']}\t{t['lat']:.6f}\t{t['lon']:.6f}\t{t['category']}\t{t['gmaps']}")

with open(os.path.join(ROOT, "coordinates.tsv"), "w") as fh: fh.write("\n".join(tsv) + "\n")
with open(os.path.join(ROOT, "ALL_SCRIPTS_clean.md"), "w") as fh:
    fh.write("# Kuala Lumpur — an architect's guide · all 42 scripts (clean)\n\n" + "\n---\n\n".join(combo_clean))
with open(os.path.join(ROOT, "ALL_SCRIPTS_tts-safe.txt"), "w") as fh:
    fh.write("\n\n\n".join(combo_tts))

print(f"{len(tours)} tours, {len(tours)*4} script files written to {OUT}")
if errors:
    print(f"LINT FAILED: {len(errors)} problems"); print("\n".join(errors[:80])); sys.exit(1)
print("LINT OK: no digits, hyphens, brackets, caps words or beat markers in any TTS-safe text")
