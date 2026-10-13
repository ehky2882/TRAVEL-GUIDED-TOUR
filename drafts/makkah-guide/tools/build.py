#!/usr/bin/env python3
"""Build the Makkah guide deliverables from drafts/makkah-guide/source/*.txt.

Writes, for every tour:
  scripts/NN_slug_clean.txt     the authoring script, with [beat] markers
  scripts/NN_slug_tts-safe.txt  phonetic respelling, no hyphens, no brackets, no [beat]
and one combined MAKKAH-GUIDE.md (index, coordinates, scripts, respellings, sources, flags).

Re-run after any edit to source/. It exits 1 if a TTS-safe file still contains a digit,
a hyphen, a bracket, a non-ASCII letter, an all-caps word or a mid-word apostrophe.
"""
import pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC, OUT = ROOT / "source", ROOT / "scripts"

# Google Maps name, lat, lon, coordinate source, category
META = {
    "01": ("Raffles Makkah Palace", 21.419223, 39.824979, "OSM", "Stay"),
    "02": ("Fairmont Makkah Clock Royal Tower", 21.418038, 39.825302, "OSM", "Stay"),
    "03": ("Conrad Jabal Omar Makkah", 21.419329, 39.822078, "OSM", "Stay"),
    "04": ("Al Shorfa Restaurant", 21.419733, 39.82646, "Google", "Dine"),
    "05": ("Kabsa Hashi", 21.452752, 39.868801, "Google", "Dine"),
    "06": ("Al Qarmoshi Yemeni Restaurant", 21.426602, 39.807081, "Google", "Dine"),
    "07": ("Arika Um Qasem", 21.386563, 39.792393, "Google", "Dine"),
    "08": ("Al Romansiah - الرومانسية", 21.400914, 39.880772, "Google", "Dine"),
    "09": ("Al Baik Aziziya Makkah", 21.416927, 39.861186, "Google", "Dine"),
    "10": ("Cafe Moment", 21.420311, 39.823815, "Google", "Drink"),
    "11": ("nootropic cafe and roastery مقهى ومحمصة نوتروبك", 21.440653, 39.800355, "Google", "Drink"),
    "12": ("Asante Roastery | محمصة اسانتي", 21.352867, 39.895026, "Google", "Drink"),
    "13": ("cultivo cafe and roastry  مقهى ومحمصة كالتيفو", 21.46286, 39.967878, "Google", "Drink"),
    "14": ("Abdul Samad Al Qurashi", 21.418569, 39.825599, "OSM", "Shop"),
    "15": ("Abraj Al-Bait Shopping Center", 21.418597, 39.826666, "Google", "Shop"),
    "16": ("Masjid al-Haram", 21.423658, 39.82536, "Google", "Visit"),
    "17": ("Safaa and Marwah (Saee)", 21.422076, 39.827531, "Google", "Visit"),
    "18": ("Makkah Al Mukarramah Library", 21.424907, 39.829817, "Google", "Visit"),
    "19": ("Exhibition of the Two Holy Mosques Architecture", 21.433782, 39.754361, "Google", "Visit"),
    "20": ("The Kiswa Factory of the Holy Ka'aba", 21.434722, 39.756922, "Google", "Visit"),
    "21": ("Mecca Museum", 21.446147, 39.807936, "Google", "Visit"),
    "22": ("Hira Cultural District", 21.456188, 39.869063, "Google", "Visit"),
    "23": ("Hira Cave, Mount of Light", 21.457254, 39.858974, "Google", "Visit"),
    "24": ("Bay'ah Mosque", 21.424717, 39.867493, "OSM", "Visit"),
    "25": ("Tuwa Well", 21.431619, 39.816657, "Google", "Visit"),
    "26": ("Masjid al Jinn", 21.433454, 39.828965, "OSM", "Visit"),
    "27": ("Al Muallaa Cemetery", 21.435021, 39.827908, "Google", "Visit"),
    "28": ("Aisha Al Rajhi Mosque", 21.381866, 39.873747, "Google", "Visit"),
    "29": ("Jamaraat Bridge", 21.420775, 39.873156, "OSM", "Visit"),
    "30": ("Haramain High Speed Railway - Makkah", 21.417655, 39.788532, "OSM", "Visit"),
    "31": ("Mecca Gate", 21.362361, 39.666722, "Wikipedia", "Visit"),
    "32": ("Jabal Thawr", 21.377000, 39.849868, "OSM (summit)", "Visit"),
    "33": ("Al Kaaba", 21.422545, 39.82619, "Google", "Observe"),
    "34": ("Makkah Clock Tower", 21.419341, 39.825412, "Google", "Observe"),
    "35": ("Mina", 21.414605, 39.894564, "Google", "Observe"),
    "36": ("Jamarat (Mina Station 3)", 21.418396, 39.87064, "OSM", "Observe"),
    "37": ("Mt Arafat", 21.354885, 39.984116, "Google", "Observe"),
    "38": ("Arak Park", 21.383342, 39.876428, "Google", "Observe"),
}

SOURCES = {
    "01": ["https://www.raffles.com/makkah/", "https://all.accor.com/hotel/A5E4/index.en.shtml", "https://guide.michelin.com/en/hotels-stays/Mecca/raffles-makkah-palace-15081", "https://en.wikipedia.org/wiki/The_Clock_Towers"],
    "02": ["https://www.fairmont.com/en/hotels/makkah/makkah-clock-royal-tower.html", "https://en.wikipedia.org/wiki/The_Clock_Towers", "https://en.wikipedia.org/wiki/Ajyad_Fortress"],
    "03": ["https://www.tradearabia.com/news/TTN_313707.html", "https://www.forbestravelguide.com/hotels/makkah-saudi-arabia/conrad-makkah-jabal-omar", "https://en.wikipedia.org/wiki/Jabal_Omar"],
    "04": ["https://www.rotana.com/rayhaanhotelandresorts/kingdomofsaudiarabia/makkah/almarwarayhaanbyrotana/diningout/alshorfa", "https://wanderlog.com/place/details/1179033 (Google listing + review summary)", "https://halalbooking.com/en/umrah/makkah/food-guide"],
    "05": ["https://wanderlog.com/place/details/2813421/kabsa-hashi (Google listing + review summary)", "https://magicpin.com/saudi-arabia/Mecca/Al-Sulaimaniyyah-Mecca/Restaurant/Kabsa-Hashi-Restaurant/store/2287437", "https://halalxplorer.com/the-food-and-drink-scene-in-makkah-and-madinah-saudi-arabia/"],
    "06": ["https://wanderlog.com/place/details/8582028 (Google listing + review summary)", "https://halalxplorer.com/the-food-and-drink-scene-in-makkah-and-madinah-saudi-arabia/"],
    "07": ["https://wanderlog.com/place/details/8582086 (Google listing)", "https://halalxplorer.com/the-food-and-drink-scene-in-makkah-and-madinah-saudi-arabia/", "Saudipedia: العريكة (Arika)"],
    "08": ["https://www.agbi.com/companies/al-romansiah", "https://www.alromansiah.com/al-romansiah-restaurants-promoted-the-quality-and-distinct-service-in-its-new-identity", "https://wanderlog.com/place/details/3964496 (Google listing + review summary)"],
    "09": ["https://familybusinesshistories.org/spotlights/albaik/", "https://en.wikipedia.org/wiki/Albaik", "https://wanderlog.com/place/details/1179083/al-baik-aziziya-makkah"],
    "10": ["https://halalxplorer.com/cafe-moment-cafe-with-the-best-view-in-makkah/", "https://wanderlog.com/place/details/5678990/cafe-moment (Google listing + review summary)"],
    "11": ["https://wanderlog.com/place/details/3966607 (Google listing + review summary)"],
    "12": ["https://wanderlog.com/place/details/4525955 (Google listing + review summary)", "https://qr.finedinemenu.com/asante-coffee-or-al-awali (menu; page did not render)"],
    "13": ["https://wanderlog.com/place/details/9573411 (Google listing + review summary)"],
    "14": ["https://www.parfumo.com/PerfumeBrand/Abdul_Samad_Al_Qurashi", "https://beautyworld-middle-east.ae.messefrankfurt.com/dubai/en/exhibitor-search.detail.html/abdul-samad-al-qurashi.html", "https://www.ampliz.com/company/abdul-samad-al-qurashi/83586998"],
    "15": ["https://en.wikipedia.org/wiki/The_Clock_Towers", "https://en.wikipedia.org/wiki/Ajyad_Fortress"],
    "16": ["https://en.wikipedia.org/wiki/Great_Mosque_of_Mecca", "https://en.wikipedia.org/wiki/Mohamed_Kamal_Ismail"],
    "17": ["https://saudipedia.com/en/article/1509/religion/the-grand-mosque/what-is-al-masaa", "https://en.wikipedia.org/wiki/Great_Mosque_of_Mecca"],
    "18": ["https://www.islamiclandmarks.com/makkah-other/birthplace-of-the-prophet-saw", "https://muslim.sg/articles/5-historical-places-to-visit-in-makkah", "https://muhammadencyclopedia.com/article/first-demolition-and-re-construction-of-the-birthplace-of-prophet-muhammad"],
    "19": ["https://en.wikipedia.org/wiki/The_Two_Holy_Mosques_Architecture_Exhibition", "https://www.arabnews.com/makkah-exhibition-features-historical-aspects-two-holy-mosques", "https://madainproject.com/exhibition_of_the_two_holy_mosques_architecture", "https://en.wikipedia.org/wiki/Kaaba"],
    "20": ["https://en.wikipedia.org/wiki/Kiswah", "https://visitsaudi.com/en/makkah/attractions/the-kiswa-factory-of-the-holy-kaaba-in-makkah", "https://www.bernama.com/en/news.php?id=2430681"],
    "21": ["https://www.lonelyplanet.com/saudi-arabia/mecca/attractions/makkah-museum/a/poi-sig/1531499/1340988", "https://avestagroup.eu/projects/al-zaher-palace/", "https://artessere.com/al-zaher-palace-museum"],
    "22": ["https://saudipedia.com/en/hira-cultural-district", "https://www.arabnews.com/node/2508426", "https://arab.news/2bryk", "https://english.ajel.sa/business/revelation-exhibition-in-makkah-offers-immersive-journey-into-islamic-history"],
    "23": ["https://en.wikipedia.org/wiki/Jabal_al-Nour"],
    "24": ["https://en.wikipedia.org/wiki/Bay%27ah_Mosque", "https://en.wikipedia.org/wiki/Mina,_Saudi_Arabia"],
    "25": ["https://thepilgrim.co/bir-tuwa/", "https://ihadis.com/en/bukhari/hadith/1573", "https://wanderlog.com/place/details/4899997/tuwa-well"],
    "26": ["https://discovermakkah.sa/en/places-worth-visiting/landmarks/mosque-of-the-jinn", "https://visitsaudi.com/en/makkah/attractions/masjid-al-jinn"],
    "27": ["https://en.wikipedia.org/wiki/Jannat_al-Mu%27alla", "https://madainproject.com/jannat_ul_mualla"],
    "28": ["https://mosqpedia.org/masajid/aisha-al-rajhi-mosque/", "https://www.arabnews.com/news/456717", "https://visitsaudi.com/en/makkah/attractions/masjid-al-rajhi"],
    "29": ["https://en.wikipedia.org/wiki/Jamaraat_Bridge", "https://en.wikipedia.org/wiki/Mina,_Saudi_Arabia"],
    "30": ["https://en.wikipedia.org/wiki/Haramain_High-Speed_Railway", "https://worldarchitecture.org/architecture-news/ecezf/foster--partners-designs-stations-with-treelike-flexible-roofs-for-saudi-arabian-cities.html", "https://www.designboom.com/architecture/foster-partners-haramain-high-speed-rail-saudi-arabia-06-13-2019/"],
    "31": ["https://en.wikipedia.org/wiki/Mecca_Gate", "https://www.arabnews.com/node/1543431"],
    "32": ["https://en.wikipedia.org/wiki/Jabal_Thawr"],
    "33": ["https://en.wikipedia.org/wiki/Kaaba", "https://en.wikipedia.org/wiki/Great_Mosque_of_Mecca"],
    "34": ["https://en.wikipedia.org/wiki/The_Clock_Towers", "https://www.lokalee.app/tours/makkah-clock-tower-museum-general-entry-ticket"],
    "35": ["https://en.wikipedia.org/wiki/Mina,_Saudi_Arabia"],
    "36": ["https://en.wikipedia.org/wiki/Al_Mashaaer_Al_Mugaddassah_Metro_line", "https://en.wikipedia.org/wiki/Mina,_Saudi_Arabia"],
    "37": ["https://en.wikipedia.org/wiki/Mount_Arafat", "https://en.wikipedia.org/wiki/Masjid_al-Namirah"],
    "38": ["https://discovermakkah.sa/en/places-worth-visiting/landmarks/arak-park", "https://wanderlog.com/list/geoCategory/105953/top-things-to-do-and-attractions-in-mecca"],
}

# Phonetic respellings: lowercase-looking English words, no hyphens, no caps runs.
# Ordered longest first so phrases win over their parts.
RESPELL = [
    ("Abdullah ibn al-Zubayr", "Abdullah ibn az Zubair"),
    ("Abu Ja'far al-Mansur", "Aboo Jaafar al Mansoor"),
    ("Abdullah ibn Mas'ud", "Abdullah ibn Masood"),
    ("Abdullah ibn Umar", "Abdullah ibn Omar"),
    ("Shakour Abu Ghazalah", "Shakoor Aboo Ghazaala"),
    ("Abdul Samad Al Qurashi", "Abdul Samad al Kurayshee"),
    ("Mohamed Kamal Ismail", "Mohammed Kamaal Ismaeel"),
    ("Al Mashaaer Al Mugaddassah Metro", "Mashaa ir Mukaddasa Metro"),
    ("Al Madinah Al Munawarah Road", "Madeena Munawwara Road"),
    ("Makkah Al Mukarramah Library", "Makkah al Mukarrama Library"),
    ("Nasr bin al-Harith bin Kaab Street", "Nasr bin al Haarith bin Kaab Street"),
    ("Ibrahim Al Joufaili Street", "Ibraheem al Jufailee Street"),
    ("Al Masjid Al Haram Road", "Masjid al Harahm Road"),
    ("Al Marwa Rayhaan", "al Marwa Rayhaan"),
    ("Masjid al-Haram", "Masjid al Harahm"),
    ("Masjid al-Haras", "Masjid al Harras"),
    ("Masjid al-Khayf", "Masjid al Khaif"),
    ("Masjid al-Jinn", "Masjid al Jinn"),
    ("Masjid Namirah", "Masjid Nameera"),
    ("Jannat al-Mu'alla", "Jannat al Moo alla"),
    ("Jabal al-Rahmah", "Jabbal ar Rahma"),
    ("Jabal al-Nour", "Jabbal an Noor"),
    ("Jabal Thawr", "Jabbal Thowr"),
    ("Jabal Omar", "Jabbal Omar"),
    ("Jabal Kuda", "Jabbal Kooda"),
    ("Ghar Thawr", "Ghaar Thowr"),
    ("Surat al-Jinn", "Soorat al Jinn"),
    ("Maqam Ibrahim", "Makaam Ibraheem"),
    ("Abd al-Muttalib", "Abdul Muttalib"),
    ("Abu Talib", "Aboo Taalib"),
    ("Abu Bakr", "Aboo Bakr"),
    ("Abraj Al-Bait Shopping Center", "Abraj al Bayt Shopping Centre"),
    ("Abraj Al Bait", "Abraj al Bayt"),
    ("Abraj Al-Bait", "Abraj al Bayt"),
    ("Mina Station Three", "Meena Station Three"),
    ("Jamarat (Mina Station 3)", "Jamaraht, Meena Station Three"),
    ("Safaa and Marwah (Saee)", "Safa and Marwa"),
    ("The Kiswa Factory of the Holy Ka'aba", "The Kisswa Factory of the Holy Kahbah"),
    ("Al Muallaa Cemetery", "al Moo alla Cemetery"),
    ("Aisha Al Rajhi", "Aysha al Rajhee"),
    ("Suleiman Al Rajhi", "Sulaiman al Rajhee"),
    ("Khalid Al Faisal", "Khaalid al Faisal"),
    ("Dar Al-Handasah", "Dar al Handasa"),
    ("Saudi Binladin Group", "Saudi Bin Laden Group"),
    ("Mimar Sinan", "Meemar Sinahn"),
    ("Sinan's", "Sinahn's"),
    ("Selim the Second", "Seleem the Second"),
    ("Evliya Çelebi", "Evliya Chelebi"),
    ("Dia Aziz Dia", "Deeya Azeez Deeya"),
    ("Samir Elabd", "Sameer el Abd"),
    ("Sadeq Bek", "Saadik Bek"),
    ("Abbas Qattan", "Abbas Kattaan"),
    ("Bayt al-Mawlid", "Bait al Mowlid"),
    ("Al-Zahir Palace", "al Zaahir Palace"),
    ("Az-Zahir", "az Zaahir"),
    ("Al-Hajun", "al Hajoon"),
    ("Al Hajun", "al Hajoon"),
    ("Al-Naseem", "an Naseem"),
    ("Ash-Shawqiyyah", "ash Shawkeeya"),
    ("Ar-Rashidiyyah", "ar Rasheedeeya"),
    ("Ar-Rusayfah", "ar Rusaifa"),
    ("Al Qadisiyyah Road", "al Kaadiseeya Road"),
    ("Al Mursalat", "al Mursalaat"),
    ("At Taysir", "at Taiseer"),
    ("Al Awali", "al Awaalee"),
    ("Umm al-Joud", "Oom al Jood"),
    ("Umm Al-Qura", "Oom al Koora"),
    ("Dhu al-Hijjah", "Dhul Hijja"),
    ("Dhu Tuwa", "Dhoo Toowa"),
    ("Arika Um Qasem", "Areeka Oom Kaasim"),
    ("Al Qarmoshi", "al Karmooshee"),
    ("Al Romansiah", "al Romanseeya"),
    ("Al Shorfa", "al Shorfa"),
    ("Al Baik Aziziya Makkah", "al Bayk Azeezeeya Makkah"),
    ("Al Baik", "al Bayk"),
    ("Albaik", "al Bayk"),
    ("Al Majlis", "al Majlis"),
    ("Al Kaaba", "al Kahbah"),
    ("Al-Bait", "al Bayt"),
    ("King Abdulaziz", "King Abdul Azeez"),
    ("Abdulaziz", "Abdul Azeez"),
    ("Mu'alla", "Moo alla"),
    ("Qur'anic", "Koranic"),
    ("Qur'an", "Koran"),
    ("Ka'aba", "Kahbah"),
    ("Kaaba", "Kahbah"),
    ("Bay'ah", "Bay ah"),
    ("Mas'a", "Masaa"),
    ("sa'i", "sa ee"),
    ("Tan'eem", "Tan eem"),
    ("Ja'far", "Jaafar"),
    ("Swissôtel", "Swissotel"),
    ("cafés", "cafes"),
    ("café", "cafe"),
    ("Café", "Cafe"),
    ("façade", "facade"),
    ("Zürich", "Zurich"),
    ("Hambela", "Hambella"),
    ("Arafah", "Arafa"),
    ("Arafat", "Arafaht"),
    ("Namirah", "Nameera"),
    ("Muzdalifah", "Muzdaleefa"),
    ("Jamaraat", "Jamaraht"),
    ("Jamarat", "Jamaraht"),
    ("jamarat", "jamaraht"),
    ("Mina", "Meena"),
    ("Hira", "Heera"),
    ("Thawr", "Thowr"),
    ("Tuwa", "Toowa"),
    ("Jarwal", "Jarwal"),
    ("Misfalah", "Misfala"),
    ("Kiswa", "Kisswa"),
    ("kiswa", "kisswa"),
    ("Haram", "Harahm"),
    ("haram", "harahm"),
    ("Hijra", "Hijra"),
    ("Hijazi", "Hijaazi"),
    ("Hijaz", "Hijaaz"),
    ("Hajj", "Hajj"),
    ("Hajar", "Haajar"),
    ("Hatim", "Hateem"),
    ("hizam", "hizaam"),
    ("Khadijah", "Khadeeja"),
    ("Quraysh", "Koraish"),
    ("Jibril", "Jibreel"),
    ("Uthman", "Uthmaan"),
    ("Ansar", "Ansaar"),
    ("Aqaba", "Akaba"),
    ("Abbasids", "Abbaasids"),
    ("Abbasid", "Abbaasid"),
    ("Ajyad", "Ajyaad"),
    ("Bulbul", "Bulbul"),
    ("Aziziyah", "Azeezeeya"),
    ("Asir", "Aseer"),
    ("Taif", "Taa if"),
    ("Ihsan", "Ihsaan"),
    ("Rami", "Raamee"),
    ("Baqi", "Bakee"),
    ("Saud", "Saood"),
    ("Hambella", "Hambella"),
    ("Rahmah", "Rahma"),
    ("Rusayfah", "Rusaifa"),
    ("Mashaaer", "Mashaa ir"),
    ("Mugaddassah", "Mukaddasa"),
    ("Zubayr", "Zubair"),
    ("Mansur", "Mansoor"),
    ("Mansour", "Mansoor"),
    ("Umar", "Omar"),
    ("Mawlid", "Mowlid"),
    ("Mukarramah", "Mukarrama"),
    ("Umrah", "Umra"),
    ("Joufaili", "Jufailee"),
    ("Narjes", "Narjis"),
    ("Rayhaan", "Rayhaan"),
    ("Majlis", "Majlis"),
    ("mashrabiya", "mashrabeeya"),
    ("sahn", "sahn"),
    ("tannour", "tanoor"),
    ("Tamees", "Tamees"),
    ("masoub", "masoob"),
    ("mutabbaq", "mutabbak"),
    ("areeka", "areeka"),
    ("Areeka", "Areeka"),
    ("kabsa", "kabsa"),
    ("hashi", "haashee"),
    ("Hashi", "Haashee"),
    ("madghout", "madghoot"),
    ("maqluba", "makloobah"),
    ("mandi", "mandee"),
    ("qahwa", "kahwa"),
    ("karak", "karak"),
    ("bakhoor", "bukhoor"),
    ("rehal", "rihaal"),
    ("nootropic", "noo tropic"),
    ("Nootropic", "Noo tropic"),
    ("Asante", "Asantay"),
    ("Cultivo", "Kultivo"),
    ("teppanyaki", "teppan yaki"),
    ("Jacquard", "Jakard"),
    ("granodiorite", "grano diorite"),
    ("Teflon", "Teflon"),
    ("V60", "vee sixty"),
    ("Moment", "Moment"),
    ("Happold", "Happold"),
    ("Bukhari", "Bukhaaree"),
    ("Hambela", "Hambella"),
    ("Mas'ud", "Masood"),
    ("Abraham", "Abraham"),
    ("Ismail", "Ismaeel"),
    ("Ibrahim", "Ibraheem"),
]

FORBIDDEN = re.compile(r"[0-9\[\]\(\)\{\}<>\-–—]|[^\x00-\x7F]|\b[A-Z]{2,}\b|[a-z]'[a-z]{3,}")
CONTRACTION_OK = re.compile(r"\b(?:\w+'(?:s|ll|re|ve|d|t|m))\b", re.I)


def respell(text):
    used = []
    for a, b in RESPELL:
        pat = re.compile(r"(?<![\w'])" + re.escape(a) + r"(?![\w'])")
        if pat.search(text):
            if a != b:
                used.append((a, b))
            text = pat.sub(b, text)
    return text, used


def tts_safe(clean):
    t = re.sub(r"\n*\[beat\]\n*", "\n\n", clean)
    t, used = respell(t)
    t = re.sub(r"(?<=\w)-(?=\w)", " ", t)          # forty-three -> forty three
    t = t.replace("’", "'")
    t = re.sub(r"[ \t]+", " ", t)
    t = re.sub(r"\n{3,}", "\n\n", t).strip() + "\n"
    return t, used


def parse():
    tours = []
    for f in sorted(SRC.glob("*.txt")):
        for block in re.split(r"^@@ ", f.read_text(), flags=re.M)[1:]:
            head, body = block.split("\n", 1)
            num, slug, title = [x.strip() for x in head.split("|")]
            tours.append((num, slug, title, body.strip()))
    return tours


def main():
    OUT.mkdir(exist_ok=True)
    tours = parse()
    problems, md_rows = [], []
    for num, slug, title, body in tours:
        clean = f"{title}\n\n{body}\n"
        tts, used = tts_safe(clean)
        (OUT / f"{num}_{slug}_clean.txt").write_text(clean)
        (OUT / f"{num}_{slug}_tts-safe.txt").write_text(tts)
        scan = CONTRACTION_OK.sub("", tts)
        bad = sorted(set(m.group(0) for m in FORBIDDEN.finditer(scan)))
        if bad:
            problems.append((num, slug, bad))
        words = len(re.sub(r"\[beat\]", "", body).split())
        secs = round(words / 2.6)
        name, lat, lon, src, cat = META[num]
        md_rows.append(f"| {num} | {cat} | {name.replace('|', '\\|')} | `{lat}, {lon}` | {src} | {words} | ~{secs // 60}:{secs % 60:02d} |")
        resp = "\n".join(f"| {a} | {b} |" for a, b in used) or "| — | — |"
        srcs = "\n".join(f"- {s}" for s in SOURCES[num])
        tour_md = (
            f"# {num} · {title}\n\n"
            f"| | |\n|---|---|\n"
            f"| Category | {cat} |\n"
            f"| Google Maps name | {name.replace('|', chr(92) + '|')} |\n"
            f"| Coordinates (WGS-84) | `{lat}, {lon}` ({src}) |\n"
            f"| Length | {words} words, ~{secs // 60}:{secs % 60:02d} |\n"
            f"| Files | `{num}_{slug}_clean.txt` · `{num}_{slug}_tts-safe.txt` |\n\n"
            f"## Script (clean)\n\n{body}\n\n"
            f"## Script (TTS-safe)\n\n{tts.split(chr(10), 2)[2].strip()}\n\n"
            f"## TTS respellings\n\n| Written | Spoken as |\n|---|---|\n{resp}\n\n"
            f"## Sources read\n\n{srcs}\n"
        )
        (OUT / f"{num}_{slug}.md").write_text(tour_md)
        md_rows[-1] += f" [{num}_{slug}.md](scripts/{num}_{slug}.md) |"
    header = (ROOT / "tools" / "md-header.md").read_text()
    md = header + "\n## Index\n\n| # | Category | Google Maps name | Coordinates (WGS-84) | Coord source | Words | Est. length | Tour file |\n|---|---|---|---|---|---|---|---|\n" + "\n".join(md_rows) + "\n"
    (ROOT / "MAKKAH-GUIDE.md").write_text(md)
    print(f"built {len(tours)} tours -> {OUT}")
    for p in problems:
        print("TTS-SAFE PROBLEM", p)
    sys.exit(1 if problems else 0)


if __name__ == "__main__":
    main()
