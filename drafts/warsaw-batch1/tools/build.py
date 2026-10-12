#!/usr/bin/env python3
"""Build the Warsaw batch 1 deliverables from source/*.txt.

For each tour it writes, into scripts/:
  warsaw_NN_slug.md       clean script, markdown, with metadata + sources
  warsaw_NN_slug.txt      clean script, plain text ([beat] kept as authoring marker)
  warsaw_NN_slug_TTS.txt  TTS-safe: phonetic respellings (lowercase, no hyphens),
                          no brackets/markup, [beat] removed, numbers as words

Fails loudly if a TTS file still contains a digit, a bracket, a hyphen,
an all-caps word, or any non-ASCII letter (an unrespelled Polish name).
"""
import re, sys, pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC, OUT = ROOT / "source", ROOT / "scripts"

# Phonetic respellings for a British TTS voice. Longest keys are applied first.
RESPELL = {
    # multi-word / phrases first
    "Krakowskie Przedmieście": "krakoff skyeh pshed myesh cheh",
    "Bar Mleczny Prasowy": "bar mlechni prah sovi",
    "bar mleczny": "bar mlechni",
    "Pałac Kultury i Nauki": "pa wats kool too ri ee now kee",
    "Plac Zbawiciela": "plats zbah vee cheh la",
    "Plac Konstytucji": "plats kon sti toots yee",
    "Plac Defilad": "plats deh fee lad",
    "Plac Małachowskiego": "plats ma wa hoff skyeh go",
    "Plac Krasińskich": "plats kra sheen skeeh",
    "Plac Mirowski": "plats mee roff skee",
    "Plac Zawiszy": "plats za vee shi",
    "Plac Konesera": "plats ko neh seh ra",
    "Aleja Wyzwolenia": "alaya viz vo len ya",
    "Aleje Jerozolimskie": "alayeh yeh ro zo leem skyeh",
    "Teatr Dramatyczny": "teh atr dra ma titch ni",
    "Nowy Świat": "novi shvyat",
    "Bęc Zmiana": "bents zmyana",
    "Pan Tu Nie Stał": "pan too nyeh stow",
    "Pan tu nie stał": "pan too nyeh stow",
    "Hala Koszyki": "hala koshi kee",
    "Hala Mirowska": "hala mee roff ska",
    "Bazar Różyckiego": "bazar roo zhits kyeh go",
    "Bez Gwiazdek": "bez gvyaz dek",
    "Elektrownia Powiśle": "elek trov nya po veesh leh",
    "Warszawa Powiśle": "var sha va po veesh leh",
    "Warszawa Ochota": "var sha va o ho ta",
    "Warszawa Skarpa": "var sha va skar pa",
    "Pawilony Nowy Świat": "pa vee loni novi shvyat",
    "Pawilon Cepelii": "pa vee lon tseh pel yee",
    "Muzeum Neonów": "moo zeh oom neh o noof",
    "Muzeum Sztuki Nowoczesnej": "moo zeh oom shtoo kee no vo ches nay",
    "Muzeum Historii Żydów Polskich": "moo zeh oom his tor yee zhi doof pol skeeh",
    "Muzeum Polskiej Wódki": "moo zeh oom pol skyay vood kee",
    "Narodowa Galeria Sztuki": "na ro do va gal er ya shtoo kee",
    "Biblioteka Uniwersytecka w Warszawie": "bib lyo teh ka oo nee ver si tets ka v var sha vyeh",
    "Sąd Najwyższy": "sont nai vizh shi",
    "Kościół Wniebowstąpienia Pańskiego": "kosh choow vnyeh bof stom pyen ya pan skyeh go",
    "Pałac Królikarnia": "pa wats kroo lee kar nya",
    "Fotoplastikon Warszawski": "foto plasti kon var shaff skee",
    "Rynek Starego Miasta": "rinek sta reh go myasta",
    "Osiedle Za Żelazną Bramą": "o shed leh za zheh laz nom bra mom",
    "Za Żelazną Bramą": "za zheh laz nom bra mom",
    "Saska Kępa": "sas ka kem pa",
    "Bulwar Flotylli Wiślanej": "bool var flo til lee veesh la nay",
    "Złota 44": "zwo ta forty four",
    "Caffe Kafka": "kaffay kafka",
    "Ogród BUW": "o grood boov",
    "Hinc omnia": "hink omnia",
    "Nulla poena sine lege": "noola poyna seeneh legeh",
    "Ius est ars boni et aequi": "yoos est ars bonee et eye kwee",
    "Po lin": "po leen",
    "La Nona Ora": "la nona ora",
    "Szanghaj": "shang hai",
    # people
    "Ignacy Jan Paderewski": "ignatsi yan pah deh reff skee",
    "Paderewski": "pah deh reff skee",
    "Władysław": "vwa dis waff",
    "Enrico Marconi": "enreeko markoni",
    "Lech Wałęsa": "lek va wen sa",
    "Anda Rottenberg": "anda rottenberg",
    "Tadeusz Kantor": "tadeh oosh kantor",
    "Wilhelm Sasnal": "vilhelm sasnal",
    "Monika Sosnowska": "monika sos noff ska",
    "Mateusz Baumiller": "mateh oosh bow miller",
    "Maria Jeglinska": "marya yeh gleen ska",
    "Beza Projekt": "beza proyekt",
    "Segiet Oniszh": "seg yet onish",
    "Mikołaj Wojciechowski": "mee ko wai voy cheh hoff skee",
    "Konrad Sojka": "konrad soy ka",
    "Robert Trzópek": "robert tshoo pek",
    "Juliusz Dzierżanowski": "yool yoosh jer zha noff skee",
    "JEMS Architekci": "jems arhee tekt chee",
    "Stanisław Skibniewski": "stah nee swaff skeeb nyeff skee",
    "Cubryna": "tsoo bri na",
    "APA Wojciechowski Architekci": "ah pah ah voy cheh hoff skee arhee tekt chee",
    "Julita Wójcik": "yoo leeta vooy cheek",
    "Arseniusz Romanowicz": "ar sen yoosh roman ovich",
    "Piotr Szymaniak": "pyotr shi man yak",
    "Bartosz Szymczak": "bartosh shim chak",
    "Tom Aikens": "tom aykens",
    "Zygmunt Stępiński": "zig moont stem peen skee",
    "Andrzej Milewski": "and zhay mee leff skee",
    "Stanisław Kucharski": "stah nee swaff koo har skee",
    "Andrzej Chołdzyński": "and zhay how jin skee",
    "Bogna Świątkowska": "bog na shvyont koff ska",
    "Justyna Burzyńska": "yoo stina boo zhin ska",
    "Maciek Lebiedowicz": "mah chek leh byeh do vich",
    "Józef Gosławski": "yoo zef go swaff skee",
    "Feliks Stamm": "feh leeks stamm",
    "Julian Różycki": "yool yan roo zhits kee",
    "Lev Rudnev": "lyev rood nyev",
    "Ilona Karwińska": "eelona kar veen ska",
    "Thomas Phifer": "thomas fifer",
    "Phifer": "fifer",
    "Stefan Szyller": "stefan shiller",
    "Zygmunt Otto": "zig moont otto",
    "Gabriel Narutowicz": "gabryel na roo to vich",
    "Narutowicz": "na roo to vich",
    "Eligiusz Niewiadomski": "eh lee gyoosh nyeh vya dom skee",
    "Maurizio Cattelan": "mowritsyo kattelan",
    "Rainer Mahlamäki": "rainer mah la mah kee",
    "Ilmari Lahdelma": "eelmaree lah del ma",
    "Marek Budzyński": "marek boo jin skee",
    "Zbigniew Badowski": "zbeeg nyeff ba doff skee",
    "Budzyński": "boo jin skee",
    "Karol Szymanowski": "karol shi ma noff skee",
    "Kazimierz Twardowski": "ka zhee myesh tvar doff skee",
    "Jan Łukasiewicz": "yan woo ka shyeh vich",
    "Alfred Tarski": "alfred tarskee",
    "Stanisław Leśniewski": "stah nee swaff lesh nyeff skee",
    "Adam Myjak": "adam mee yak",
    "Irena Bajerska": "eerena bah yer ska",
    "Witold Wołodkiewicz": "veetold vo wod kyeh vich",
    "Wacław Zalewski": "vats waff za leff skee",
    "Piotr Wicha": "pyotr vee ha",
    "Krzysztof Kieślowski": "kshish tof kyesh loff skee",
    "Domenico Merlini": "domeneeko merleenee",
    "Carlo Thomatis": "karlo tomatis",
    "Stanisław August": "stah nee swaff owgoost",
    "Tadeusz Kościuszko": "tadeh oosh kosh choosh ko",
    "Xawery Dunikowski": "ksa veh ri doo nee koff skee",
    "Józef Chudy": "yoo zef hoo di",
    "Krempa": "krem pa",
    "Bernardo Bellotto": "bernardo bellotto",
    "Konstanty Hegel": "kon stanti hegel",
    "Kołłątaj": "ko won tai",
    "Zakrzewski": "za kshef skee",
    "Dekert": "deh kert",
    "Barss": "barss",
    "Józef Sigalin": "yoo zef see ga leen",
    "Stanisław Jankowski": "stah nee swaff yan koff skee",
    "Jan Knothe": "yan kno teh",
    "Jerzy Czyż": "yeh zhi chish",
    "Jan Furman": "yan foorman",
    "Andrzej Skopiński": "and zhay sko peen skee",
    "Bohdan Lachert": "boh dan la hert",
    "Lachert": "la hert",
    "Józef Szanajca": "yoo zef sha nai tsa",
    "Szymon and Helena Syrkus": "shi mon and helena sir koos",
    "Stanisław Barylski": "stah nee swaff ba ril skee",
    "Henryk Oderfeld": "hen rik oder feld",
    "Marian Lalewicz": "mar yan la leh vich",
    "Włodzimierz Gall": "vwo jee myesh gall",
    "Praesens": "pray sens",
    "Jan Karski": "yan karskee",
    "Daniel Libeskind": "daniel lee bes kind",
    "Libeskind": "lee bes kind",
    "Augustus the Second": "augustus the second",
    # institutions, brands, words
    "Europejski": "ehro pay skee",
    "Lourse": "loorss",
    "Zachęta": "za hen ta",
    "Orbis": "orbis",
    "Mamastudio": "mama stoodio",
    "Ultralight": "ultra light",
    "Koszykowa": "koshi kova",
    "Koszyki": "koshi kee",
    "Lwowska": "lvoff ska",
    "Marszałkowska": "mar shaw koff ska",
    "Prasowy": "prah sovi",
    "pierogi": "pyeh rogee",
    "Wiślana": "veesh lana",
    "Powiśle": "po veesh leh",
    "Podhale": "pod ha leh",
    "karminadle": "kar mee nad leh",
    "oscypek": "oss tsi pek",
    "Dobra": "dobra",
    "Charlotte": "sharlot",
    "Kulturalna": "kool too ral na",
    "Kruczkowskiego": "krooch koff skyeh go",
    "Poniatowski": "pon ya toff skee",
    "Śródmieście": "shrood myesh cheh",
    "Życie Warszawy": "zhi cheh var sha vi",
    "Oboźna": "o bozh na",
    "Rozbrat": "roz brat",
    "Cepelia": "tseh pel ya",
    "Metropol": "metro pol",
    "Empik": "em pick",
    "Nowogrodzka": "no vo grots ka",
    "Mokotowska": "mo ko toff ska",
    "bęc": "bents",
    "zmiana": "zmyana",
    "Łódź": "wootch",
    "Mirów": "mee roof",
    "Praga": "praga",
    "Targowa": "tar go va",
    "Ząbkowska": "zomb koff ska",
    "pyzy": "pi zi",
    "Kraków": "krakoff",
    "Zamość": "za moshch",
    "Skłodowska-Curie": "skwo doff ska kyooree",
    "Kamionek": "ka myo nek",
    "Syrenka": "si ren ka",
    "Bambino": "bambeeno",
    "Krucza": "kroo cha",
    "Królewska": "kroo leff ska",
    "Artibus": "artibus",
    "Muranów": "moo ra noof",
    "POLIN": "po leen",
    "Polin": "po leen",
    "Lwów": "lvoof",
    "Ochota": "o ho ta",
    "Towarowa": "to va ro va",
    "Śląsko": "shlon sko",
    "Spodek": "spo dek",
    "Katowice": "ka to vee tseh",
    "Wschodnia": "fs hod nya",
    "Stadion": "stad yon",
    "Ursynów": "oor si noof",
    "Królikarnia": "kroo lee kar nya",
    "Mokotów": "mo ko toof",
    "Vicenza": "vee chen tsa",
    "Koneser": "ko neh ser",
    "Wyborowa": "vi bo ro va",
    "Luksusowa": "look soo so va",
    "Żubrówka": "zhoo broof ka",
    "Hoser": "hozer",
    "Kołłątaj": "ko won tai",
    "MDM": "em dee em",
    "TR Warszawa": "tee ar var sha va",
    "Katowicka": "ka to veets ka",
    "Świętokrzyski": "shvyen to kshis kee",
    "RS Architektura Krajobrazu": "ar es arhee tek too ra kra yo bra zoo",
    "Złota": "zwo ta",
    "Żagiel": "zha gyel",
    "Lwów–Warsaw": "lvoof warsaw",
    "Plater": "plater",
    "Emilii": "emeelee",
    "Wołówka": "vo woof ka",
    "Rozbrat 20": "roz brat twenty",
    "façades": "fassahds",
    "façade": "fassahd",
    "Różycki": "roo zhits kee",
    "UNESCO": "yoo nesko",
    "Romanowicz": "roman ovich",
    "Dunikowski": "doo nee koff skee",
    "Karowa": "ka ro va",
}

KEYS = sorted(RESPELL, key=len, reverse=True)


def respell(text):
    # placeholder pass so a replacement can't be re-matched by a shorter key
    holders = {}
    for i, k in enumerate(KEYS):
        if k in text:
            tag = f"\x00{i}\x00"
            text = re.sub(r"(?<![A-Za-zÀ-ž])" + re.escape(k) + r"(?![A-Za-zÀ-ž])", tag, text)
            holders[tag] = RESPELL[k]
    for tag, val in holders.items():
        text = text.replace(tag, val)
    return text


def tts(text):
    text = re.sub(r"\n*[ \t]*\[beat\][ \t]*\n*", "\n\n", text)
    text = respell(text)
    text = text.replace("“", "").replace("”", "").replace('"', "")
    text = re.sub(r"\s*[—–]\s*", ", ", text)
    text = text.replace("-", " ")
    text = text.replace("é", "e").replace("â", "a")
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip() + "\n"


def parse():
    tours = []
    for f in sorted(SRC.glob("*.txt")):
        for block in re.split(r"^=== ", f.read_text(), flags=re.M)[1:]:
            head, body = block.split("\n---\n", 1)
            lines = head.split("\n")
            num, slug, title, gmaps, coords, cat = [x.strip() for x in lines[0].split("|")]
            meta = dict(l.split(": ", 1) for l in lines[1:] if l.strip())
            tours.append(dict(num=num, slug=slug, title=title, gmaps=gmaps, coords=coords,
                              cat=cat, vantage=meta["Vantage"],
                              sources=[s.strip() for s in meta["Sources"].split(";")],
                              body=body.strip()))
    return tours


def main():
    OUT.mkdir(exist_ok=True)
    tours = parse()
    problems = []
    rows = []
    for t in tours:
        base = OUT / f"warsaw_{t['num']}_{t['slug'].replace('-', '_')}"
        words = len(re.sub(r"\[beat\]", "", t["body"]).split())
        mins = words / 150
        header = (f"WARSAW — {t['num']} — {t['title'].upper()}\n"
                  f"{t['cat']} · single stop · British register · ~{words} words (~{mins:.1f} min)\n"
                  f"Google Maps: {t['gmaps']} · {t['coords']}\n"
                  f"Vantage: {t['vantage']}\n---\n")
        (base.with_suffix(".txt")).write_text(header + t["body"] + "\n")
        md = (f"# {t['title']}\n\n"
              f"| | |\n|---|---|\n| Tour | Warsaw {t['num']} · {t['cat']} · single stop |\n"
              f"| Google Maps name | {t['gmaps']} |\n| Coordinates (WGS-84) | {t['coords']} |\n"
              f"| Vantage | {t['vantage']} |\n| Length | ~{words} words, about {mins:.1f} minutes |\n\n"
              f"## Script\n\n" + t["body"].replace("[beat]", "*[beat]*") + "\n\n"
              f"## Sources read before writing\n\n" + "\n".join(f"- <{s}>" for s in t["sources"]) + "\n")
        (base.with_suffix(".md")).write_text(md)
        spoken_title = tts(t["title"]).strip()
        tts_text = spoken_title + "\n\n" + tts(t["body"])
        (OUT / (base.name + "_TTS.txt")).write_text(tts_text)
        # TTS guards
        for pat, why in [(r"\d", "digit"), (r"[\[\]{}<>()]", "bracket"), (r"-", "hyphen"),
                         (r"\b[A-Z]{2,}\b", "all-caps word"), (r"[^\x00-\x7F’]", "non-ASCII")]:
            for m in re.finditer(pat, tts_text):
                ctx = tts_text[max(0, m.start() - 25): m.end() + 25].replace("\n", " ")
                problems.append(f"{base.name}_TTS: {why}: …{ctx}…")
        rows.append((t, words, mins))
    if problems:
        print("\n".join(problems))
        print(f"FAIL: {len(problems)} TTS problem(s)")
        sys.exit(1)
    for t, w, m in rows:
        print(f"{t['num']} {t['slug']:34} {w:4d} words {m:.1f} min")
    print(f"OK: {len(rows)} tours, {len(rows) * 3} files")


main()
