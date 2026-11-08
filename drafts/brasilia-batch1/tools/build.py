#!/usr/bin/env python3
"""Build Brasília batch 1 scripts: clean .txt, TTS-safe .txt and a per-tour .md.

    python3 -I build.py            # writes ../scripts/, ../README.md, ../coordinates.tsv

TTS-safe rules (owner's standing preference):
  * phonetic respelling only: no caps, no hyphens
  * no code / markup / brackets; [beat] removed and replaced by a paragraph break
  * years spelled out in full; every other digit spelled out too
  * proper-noun titles respelled when the title itself trips TTS
"""
import os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from scripts_01_12 import TOURS as A
from scripts_13_22 import TOURS as B
from scripts_23_32 import TOURS as C

TOURS = sorted(A + B + C, key=lambda t: t["n"])
OUT = os.path.join(HERE, "..", "scripts")

# Longest keys first, so "Lúcio Costa" wins over "Costa" etc. Case-sensitive, whole words.
RESPELL = {
 # people
 "Juscelino Kubitschek": "Zhooseleeno Koobitchek",
 "Sarah Kubitschek": "Sarah Koobitchek",
 "Kubitschek": "Koobitchek",
 "Oscar Niemeyer": "Oscar Neemyer", "Niemeyer's": "Neemyer's", "Niemeyer": "Neemyer",
 "Lúcio Costa's": "Loosio Costa's", "Lúcio Costa": "Loosio Costa",
 "Athos Bulcão's": "Ahtoss Boolsowng's", "Athos Bulcão": "Ahtoss Boolsowng", "Athos's": "Ahtoss's", "Athos": "Ahtoss",
 "Joaquim Cardozo": "Zhwakeen Cardozo",
 "Roberto Burle Marx": "Roberto Boorlee Marks", "Burle Marx": "Boorlee Marks",
 "Alfredo Ceschiatti": "Alfredo Seskyatti", "Ceschiatti": "Seskyatti",
 "Marianne Peretti": "Marianne Peretti",
 "Carlos Alberto Naves": "Carlos Alberto Nahvess",
 "Hubert Van Doorne": "Hubert van Doorna",
 "Gotfredo Tralli": "Gotfredo Tralli",
 "Honório Peçanha": "Onoreeoh Pessanya",
 "Honestino Guimarães": "Onesteeno Geemaraynss",
 "José Carlos Sussekind": "Zhozay Carlos Soosekeend",
 "Cláudio Santoro": "Klowdeeo Santoro",
 "João Filgueiras Lima": "Zhwowng Feelgayrass Leema",
 "Lelé's": "Lelleh's", "Lelé": "Lelleh",
 "Darcy Ribeiro": "Darsee Reebayro",
 "Dilermando's": "Deelermando's", "Dilermando Reis": "Deelermando Hayss",
 "Tancredo Neves": "Tankredo Nevess",
 "Ruy Ohtake": "Hooee Ohtahkay", "Tomie Ohtake": "Tommy Ohtahkay", "Ruy's": "Hooee's", "Ohtake": "Ohtahkay",
 "Nauro Esteves": "Nowroo Estevess",
 "Vinícius de Moraes": "Veeneesee us de Morice",
 "Tom Jobim": "Tom Zhobeen",
 "Jean-Paul Sartre": "Zhon Paul Sartra",
 "Che Guevara": "Chay Gevahra",
 "Indira Gandhi": "Indira Gandhi",
 "Charles de Gaulle": "Sharl de Goal",
 "Alfredo Volpi": "Alfredo Volpee", "Volpi": "Volpee",
 "Francisco Galeno": "Franseesko Galeno",
 "Márcia": "Marseea",
 "Cândido Portinari": "Kandeedo Porteenari", "Portinari": "Porteenari",
 "Bruno Giorgi": "Brunoh Jorjee",
 "Sergio Rodrigues": "Sairzheeo Hodreegess",
 "Milton Ramos": "Milton Hahmoss",
 "Sérgio Rocha": "Sairzheeo Hosha",
 "Marcelo Campelo": "Marselo Kampelo", "Campelo's": "Kampelo's",
 "Stellio Seabra": "Stelleeo Seeahbra",
 "Di Cavalcanti": "Dee Kavalkanchee",
 "Youssef Sarkis Maaraouri": "Yoossef Sarkees Mahrahooree",
 "Youssef Sarkis Kaawai": "Yoossef Sarkees Kahwye",
 "Bartô": "Bartoh", "Chico": "Sheeko",
 "Renato Russo": "Henahtoo Hoosoo",
 "Legião Urbana": "Lezheeowng Oorbahna",
 "Juliana Pedro": "Zhooleeahna Pedro",
 "Jacob do Bandolim": "Zhakob doo Bandoleeng",
 "Odette Ernest Dias": "Odette Ernest Jeeass",
 "Reco do Bandolim": "Heko doo Bandoleeng",
 "Raphael Rabello": "Rafa ell Habello",
 "Daniel Mangabeira": "Daniel Mangabayra", "Henrique Coutinho": "Enreekee Kocheenyo", "Matheus Seco": "Mateoos Seko",
 "Daniel Briand's": "Daniel Bree on's", "Daniel Briand": "Daniel Bree on", "Briand": "Bree on",
 "Alexandre Chan": "Alexandre Chan",
 "Arreghini": "Arreggeenee",
 "Gustav Lindenthal": "Gustav Lindentahl",
 "Nilson Nelson": "Neelson Nelson",
 "Mané Garrincha": "Maneh Gahreensha", "Mané Mercado": "Maneh Mercahdo",
 "Dom Bosco": "Dom Bosko", "John Bosco": "John Bosko",
 # places, institutions, things
 "Brasília Palace Hotel": "Brazeelya Palace Hotel",
 "Brasílians": "Brazeelyans", "Brasília's": "Brazeelya's", "Brasília": "Brazeelya",
 "Palácio da Alvorada": "Palasseeo da Alvorahda", "Alvorada": "Alvorahda",
 "Palácio Itamaraty": "Palasseeo Eetamaratchee", "Itamaraty": "Eetamaratchee",
 "Lake Paranoá": "Lake Pahrah noh ah", "Paranoá": "Pahrah noh ah",
 "Plano Piloto": "Plahno Peeloto",
 "Esplanada": "Esplanahda",
 "Planalto": "Planowtoo",
 "Paraíba": "Paraeeba", "João Pessoa": "Zhwowng Pessoah", "Recife": "Heseefee", "Natal": "Natow",
 "São Paulo": "Sowng Powloo",
 "Rio de Janeiro": "Reeoh de Zhanayro",
 "Minas Gerais": "Meenass Zhereyess",
 "Belo Horizonte": "Belo Oreezonchee",
 "Pampulha": "Pampoolya",
 "Ceará": "Seeahrah",
 "Serra da Canastra": "Serra da Kanastra",
 "sertão": "sairtowng",
 "Cerrado": "Seh hahdoo",
 "Miranda de Ebro": "Miranda de Ebro",
 "Catetinho": "Katecheenyo", "Catete": "Katetchee",
 "Igrejinha Nossa Senhora de Fátima": "Eegrezheenya Nossa Senyora de Fatima",
 "Igrejinha": "Eegrezheenya",
 "Nossa Senhora Aparecida": "Nossa Senyora Apahreseeda",
 "Catedral Metropolitana": "Katedrow Metropoleetahna",
 "Congresso Nacional": "Kongresso Nasseeonow",
 "Santuário": "Santooareeoh",
 "Ermida": "Ermeeda",
 "Memorial JK": "Memorial Zhota Kah",
 "Museu Nacional": "Moozayoo Nasseeonow",
 "Museu BB": "Moozayoo bay bay",
 "Teatro Nacional": "Teahtro Nasseeonow",
 "Hotel Nacional": "Hotel Nasseeonow",
 "Mercado": "Mercahdo",
 "Villa Lobos": "Villa Lobos",
 "Martins Pena": "Marteens Pena",
 "Instituto Central de Ciências": "Insteechootoo Sentrow de Seeensseeass",
 "Minhocão": "Meenyokowng",
 "Hospital SARAH Lago Norte": "Hospital Sarah Lahgo Nortchee",
 "Lago Norte": "Lahgo Nortchee", "Lago Sul": "Lahgo Sool",
 "Centro Cultural Banco do Brasil": "Sentro Kooltoorow Banko doo Brazeel",
 "Banco do Brasil": "Banko doo Brazeel",
 "SQS 308 Sul": "Super kwadra three oh eight Sool",
 "superquadras": "super kwadras", "superquadra": "super kwadra",
 "Torre de TV": "Torree dee Tay Vay",
 "TV": "tee vee",
 "MC": "em see",
 "Feira da Torre de TV": "Fayra da Torree dee Tay Vay",
 "Feira da Torre": "Fayra da Torree",
 "Rodoviária do Plano Piloto": "Hodoveeahreea doo Plahno Peeloto",
 "Rodoviária": "Hodoveeahreea",
 "Eixão": "Ayshowng",
 "Conic": "Konnick",
 "Birosca": "Beeroska",
 "Ponte JK": "Ponchee Zhota Kah",
 "JK Bridge": "Zhota Kah Bridge",
 "JK's": "Zhota Kah's", "JK": "Zhota Kah",
 "Juscelino": "Zhooseleeno",
 "Pontão do Lago Sul": "Pontowng doo Lahgo Sool", "Pontão": "Pontowng",
 "Projeto Orla": "Prozhetoo Orla",
 "Espaço Lúcio Costa": "Espasso Loosio Costa",
 "Casa de Chá": "Kahza de Shah",
 "Senac": "Senack",
 "Fundação Athos Bulcão": "Foondassowng Ahtoss Boolsowng",
 "Clube do Choro de Brasília": "Kloobee doo Shoro de Brazeelya",
 "Clube do Choro": "Kloobee doo Shoro",
 "Choro": "Shoro", "choro": "shoro",
 "Ernesto Cafés Especiais": "Ernesto Kafez Espesseeyice",
 "Beirute": "Bayroochee", "beirute": "bayroochee",
 "BLOCO Arquitetos": "Bloko Arkeetetoss",
 "Cine Brasília": "Seenee Brazeelya",
 "Meteoro": "Meteoroh",
 "candangos": "kandangoos",
 "Água de Beber": "Ahgwa de Bebair",
 "Asa Sul": "Ahza Sool",
 "Mangai": "Mangah ee",
 # food and drink
 "carne de sol": "karnee de sol",
 "queijo de manteiga": "kayzho de manchayga",
 "pão de macaxeira": "powng de makashayra",
 "pão de queijo": "powng de kayzho",
 "cuscuz": "kooskooss",
 "cocada": "kokahda",
 "chopp": "shoppee",
 "esfihas": "esfeehas",
 "kibeirute": "keebayroochee",
 "kibe": "keebee",
 "pequi": "peh kee",
 "baru": "bah roo",
 "pamonha": "pamonya",
 "céu de Brasília": "say oo de Brazeelya",
 "capim dourado": "kapeeng dorahdoo",
 "bûche de Noël": "boosh de no el",
 "serpentário": "serpentahreeoh",
 "Pâtissier & Chocolatier": "Pateesee ay and Shokolatee ay",
 "O Sol faz a festa": "Oo Sow fahss a festa",
 "Cultural Complex of the Republic": "Cultural Complex of the Republic",
}

ONES = "zero one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen".split()
TENS = "_ _ twenty thirty forty fifty sixty seventy eighty ninety".split()

def two(n):
    if n < 20: return ONES[n]
    t, o = divmod(n, 10)
    return TENS[t] + ("" if o == 0 else " " + ONES[o])

def year(y):
    if 2000 <= y <= 2009: return "two thousand" + ("" if y == 2000 else " and " + ONES[y - 2000])
    hi, lo = divmod(y, 100)
    if lo == 0: return two(hi) + " hundred"
    if lo < 10: return two(hi) + " oh " + ONES[lo]
    return two(hi) + " " + two(lo)

def code(n_str):
    # quadra numbers etc: 104 -> one oh four, 115 -> one fifteen, 510 -> five ten
    d0, rest = n_str[0], n_str[1:]
    if rest[0] == "0": return ONES[int(d0)] + " oh " + ONES[int(rest[1])]
    return ONES[int(d0)] + " " + two(int(rest))

def numbers(s):
    s = re.sub(r"\bW3\b", "double you three", s)
    s = re.sub(r"\b(1[0-9]{3}|20[0-9]{2})\b", lambda m: year(int(m.group(1))), s)
    s = re.sub(r"\b([1-9][0-9]{2})\b", lambda m: code(m.group(1)), s)
    s = re.sub(r"\b([0-9]{1,2})\b", lambda m: two(int(m.group(1))), s)
    assert not re.search(r"\d", s), re.findall(r".{20}\d.{20}", s)
    return s

KEYS = sorted(RESPELL, key=len, reverse=True)
PAT = re.compile("|".join(r"(?<![\w])" + re.escape(k) + r"(?![\w])" for k in KEYS))

def tts(clean):
    s = clean.replace("\n[beat]\n", "\n")
    s = re.sub(r"\[beat\]", "", s)
    s = PAT.sub(lambda m: RESPELL[m.group(0)], s)
    s = numbers(s)
    s = s.replace(" - ", ", ").replace("-", " ")
    s = s.replace("&", "and")
    s = re.sub(r"[\[\]{}<>*_#`|]", "", s)
    s = re.sub(r"\n{3,}", "\n\n", s)
    # no all-caps words of two letters or more
    caps = re.findall(r"\b[A-Z]{2,}\b", s)
    assert not caps, caps
    return s.strip() + "\n"

def words(s): return len(re.findall(r"[\w’']+", s.replace("[beat]", "")))

def main():
    os.makedirs(OUT, exist_ok=True)
    rows, idx = [], []
    for t in TOURS:
        base = f"{t['n']:02d}_{t['slug'].replace('-', '_')}"
        clean = t["text"].strip() + "\n"
        safe = tts(clean)
        open(os.path.join(OUT, base + "_clean.txt"), "w").write(clean)
        open(os.path.join(OUT, base + "_tts-safe.txt"), "w").write(safe)
        w = words(clean); mins = w / 150
        coord = f"{t['lat']}, {t['lon']}"
        note = t.get("coord_note")
        md = [f"# {t['n']:02d} · {t['gmaps']}", "",
              f"- **Category:** {t['cat']}",
              f"- **Google Maps name:** {t['gmaps']}",
              f"- **Coordinate (WGS-84):** `{coord}`" + (f"  \n  ⚠️ {note}" if note else ""),
              f"- **Length:** {w} words · about {int(mins)} min {int(round((mins % 1) * 60)):02d} s at 150 wpm",
              "- **Primary sources read before writing:**"]
        md += [f"  - <{u}>" for u in t["sources"]]
        md += ["", "## Clean script", "", clean.strip(), "", "## TTS-safe script", "", safe.strip(), ""]
        open(os.path.join(OUT, base + ".md"), "w").write("\n".join(md))
        rows.append(f"{t['slug']}\t{t['lat']}\t{t['lon']}\t{t['cat']}\t{t['gmaps']}" + ("\tAPPROXIMATE" if note else ""))
        idx.append(f"| {t['n']:02d} | {t['cat']} | {t['gmaps']} | `{coord}`{' ⚠️' if note else ''} | {w} |")
    open(os.path.join(HERE, "..", "coordinates.tsv"), "w").write("slug\tlat\tlon\tcategory\tgmaps_name\tflag\n" + "\n".join(rows) + "\n")
    print("\n".join(idx))

if __name__ == "__main__":
    main()
