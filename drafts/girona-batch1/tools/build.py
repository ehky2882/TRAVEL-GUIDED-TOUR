"""Build Girona batch 1 script files from source/scripts-*.txt.

Writes, per tour:  scripts/NN_slug_clean.txt, scripts/NN_slug_tts-safe.txt, md/NN_slug.md
plus GIRONA-SCRIPTS.md (all clean scripts in one document).
Usage: python3 -I tools/build.py <batch dir>
"""
import re, sys, pathlib

root = pathlib.Path(sys.argv[1])
src = "".join((root / "source" / f).read_text() for f in sorted(p.name for p in (root / "source").glob("scripts-*.txt")))

# Phonetic respellings for the TTS-safe version. Lowercase-led, no caps runs, no hyphens.
# Applied longest key first, whole-word.
RESPELL = {
    # titles / venues
    "Hotel Museu Llegendes de Girona": "Hotel Moozayoo Lyuhzhendus duh Jeerohna",
    "Museum Hotel of the Legends of Girona": "Museum Hotel of the Legends of Jeerohna",
    "El Celler de Can Roca": "El Suhyay duh Kan Rokka",
    "Museu d'Història dels Jueus": "Moozayoo distoreea dels Jooayoos",
    "Església de Sant Pere de Galligants": "Esgleezeea duh San Pairuh duh Galeegans",
    "Sant Pere de Galligants": "San Pairuh duh Galeegans",
    "Bonastruc ça Porta": "Bonastrook sa Porta",
    "Pont de les Peixateries Velles": "Pon duh less Pushatereeus Vayus",
    "Edifici de les Aligues": "Edeefeesee duh less Aleegus",
    "Basilica de Sant Feliu": "Bazeelika duh San Feleeoo",
    "Plaça de la Independència": "Plassa duh la Indeppendensseea",
    "Plaça de Sant Domènec": "Plassa duh San Doomennek",
    "Pujada de Sant Domènec": "Poojahda duh San Doomennek",
    "Plaça de Sant Agustí": "Plassa duh San Agoostee",
    "Plaça de Sant Feliu": "Plassa duh San Feleeoo",
    "Pont de Sant Agustí": "Pon duh San Agoostee",
    "Plaça Calvet i Rubalcaba": "Plassa Kalvet ee Roobalkahba",
    "Plaça de la Catedral": "Plassa duh la Katuhdral",
    "Plaça de Catalunya": "Plassa duh Kataloonya",
    "Plaça de l'Oli": "Plassa duh Lolly",
    "Parc de la Devesa": "Park duh la Duhvayza",
    "Auditori de Girona": "Owditoree duh Jeerohna",
    "Catedral de Girona": "Katuhdral duh Jeerohna",
    "Cafè Le Bistrot": "Kaffay luh Beestro",
    "Café Le Bistrot": "Kaffay luh Beestro",
    "Le Bistrot": "luh Beestro",
    "Bòlit Sant Nicolau": "Bolleet San Neekoolow",
    "Sant Nicolau": "San Neekoolow",
    "Bòlit": "Bolleet",
    "Museu del Cinema": "Moozayoo del Seenema",
    "Museu d'Art": "Moozayoo Dart",
    "Casa de les Aigües": "Kasa duh less Eyegwus",
    "Cases de l'Onyar": "Kasus duh Loonyar",
    "Farinera Teixidor": "Fareenaira Tusheedor",
    "Mercat del Lleó": "Merkat del Yayoh",
    "Llibreria 22": "Yeebrereea Twenty Two",
    "La Vint i Dos": "la Veent ee Doss",
    "Nykteri's Cocktail Bar": "Nikteris Cocktail Bar",
    "Nykteri's": "Nikteris",
    "Pensió Bellmirall": "Penseeoh Belmeeral",
    "Carrer de Bellmirall": "Karreh duh Belmeeral",
    "Portal de la Barca": "Portal duh la Barka",
    "Casa Cacao": "Kasa Kakow",
    "Casa Masó": "Kasa Massoh",
    "Les Àligues": "less Aleegus",
    "Banys Àrabs": "Banyus Arabs",
    "Torre Gironella": "Torruh Jeeroonayya",
    "Gironella": "Jeeroonayya",
    "La Fábrica": "la Fabrika",
    "Rocambolesc": "Rokambolesk",
    "Divinum": "Deeveenoom",
    "Cal Ros": "Kal Ross",
    "Fonda Cal Ros": "Fonda Kal Ross",
    "Nord 1901": "Nord nineteen oh one",
    "Velodrom": "Vellodrom",
    # streets and places
    "Carrer de les Ballesteries": "Karreh duh less Bayustereeus",
    "Carrer de Santa Eugènia": "Karreh duh Santa Ayoozhenya",
    "Carrer de Sant Llorenç": "Karreh duh San Lyoorens",
    "Carrer de la Cort Reial": "Karreh duh la Kort Rayal",
    "Carrer de Santa Llúcia": "Karreh duh Santa Yooseea",
    "Carrer de Santa Clara": "Karreh duh Santa Klara",
    "Carrer de les Hortes": "Karreh duh less Ortus",
    "Carrer de la Llebre": "Karreh duh la Yebbruh",
    "Carrer de la Força": "Karreh duh la Forsa",
    "Carrer de l'Albereda": "Karreh duh Lalbuhrayda",
    "Carrer Nord": "Karreh Nord",
    "Voltes d'en Rosés": "Voltus den Roozez",
    "Sant Martí Sacosta": "San Martee Sakosta",
    "Sant Pere de Rodes": "San Pairuh duh Rodus",
    "Sant Miquel de Cruïlles": "San Meekel duh Krooeelyus",
    "Sant Domènec": "San Doomennek",
    "Sant Agustí": "San Agoostee",
    "Sant Feliu": "San Feleeoo",
    "Sant Narcís": "San Narsees",
    "Sant Daniel": "San Daneeel",
    "Saint Narcís": "Saint Narsees",
    "Pont de Pedra": "Pon duh Pedra",
    "Galligants": "Galeegans",
    "Taialà": "Tie a la",
    "Can Sunyer": "Kan Soonyay",
    "Can Roca": "Kan Rokka",
    "El Celler": "El Suhyay",
    "Onyar": "Oonyar",
    "Ter": "Tair",
    "Call": "Kye",
    "Catalunya": "Kataloonya",
    # people
    "Isabel López Vilalta": "Eezabel Lopez Veelalta",
    "Sandra Tarruella": "Sandra Tarrooayya",
    "Ricard Trenchs": "Reekard Trenks",
    "Josep Maria Fuses": "Joozep Mareea Foozus",
    "Joan Maria Viader": "Jooahn Mareea Veeaday",
    "Josep Fuses": "Joozep Foozus",
    "Elisabet Nolla": "Eleezabet Noyya",
    "Andreu Carulla": "Andrayoo Karooya",
    "Joan Morillo": "Jooahn Moreeyo",
    "Laura Tejero": "Lowra Teherro",
    "Marc Gascons": "Mark Gaskons",
    "Gascons": "Gaskons",
    "Els Tinars": "Els Teenars",
    "Ale Rivas": "Ahleh Reevas",
    "Christian and Amber Meier": "Christian and Amber Myer",
    "Christian Meier": "Christian Myer",
    "Kristof Ramon": "Kristof Rahmon",
    "Mariona Vilanova": "Mareeona Veelanova",
    "Guillem Terribas": "Geeyem Terreebas",
    "Just M. Casero": "Joost Em Kasero",
    "Miquel Casals": "Meekel Kasals",
    "Bruna Vila": "Broona Veela",
    "Guillem Bofill": "Geeyem Boofeel",
    "Antoni Canet": "Antonee Kanet",
    "Tomàs Mallol": "Toomas Mayol",
    "Enric Ansesa": "Enrik Anseza",
    "Jaume Faixó": "Jowmuh Fashoh",
    "Rafael Masó": "Rafa el Massoh",
    "Masó": "Massoh",
    "Alfons Teixidor": "Alfons Tusheedor",
    "Teixidor": "Tusheedor",
    "Martí Sureda": "Martee Sooraida",
    "Xavier Montsalvatge": "Shavier Montsalvadjuh",
    "Sala Montsalvatge": "Sala Montsalvadjuh",
    "Montsalvatge": "Montsalvadjuh",
    "Isidre Vicens": "Eezeedruh Veesens",
    "Anna Payet": "Anna Pyet",
    "Jordi Roca": "Jordee Rokka",
    "Joan Roca": "Jooahn Rokka",
    "Josep Roca": "Joozep Rokka",
    "Roca": "Rokka",
    "Joan": "Jooahn",
    "Josep": "Joozep",
    "Jordi": "Jordee",
    "Gerió": "Jeree oh",
    "Narcís": "Narsees",
    "Nahmanides": "Nahmannideez",
    "Terrània": "Terranya",
    "Temps de Flor": "Tems duh Flor",
    "Elena": "Elayna",
    # words
    "El Punt": "El Poon",
    "Noucentisme": "Nowsenteezmuh",
    "Modernisme": "Moderneezmuh",
    "apodyterium": "apoditeereeum",
    "mikveh": "mikvuh",
    "porrón": "porron",
    "butifarra": "booteefarra",
    "pizza de pagès": "pizza duh pajess",
    "pa de pagès": "pa duh pajess",
    "ratafia": "rattafeeya",
    "Escudella": "Eskoodaya",
    "Baelor": "Bayler",
    "Via Augusta": "Veea Owgusta",
    "Habsburg": "Habsburg",
    "Lycra": "Lycra",
    "G. Eiffel and Compagnie": "Jee Eiffel and Kompanyee",
    "Eiffel": "Eiffel",
    "Duroc": "Dooroc",
    "Traka": "Trakka",
    "Fábrica": "Fabrika",
    "Mafia": "Mafia",
    "Normal": "Normal",
    "Lleó": "Yayoh",
    "Àligues": "Aleegus",
    "Girona": "Jeerohna",
}
keys = sorted(RESPELL, key=len, reverse=True)
pat = re.compile(r"(?<![\w'])(" + "|".join(re.escape(k) for k in keys) + r")(?![\w])")


def tts(text):
    t = pat.sub(lambda m: RESPELL[m.group(1)], text)
    t = re.sub(r"\n*\[beat\]\n*", "\n\n", t)          # beat -> paragraph break
    t = t.replace("—", ",").replace("–", " ").replace("café", "cafe")
    t = re.sub(r"(?<=\w)-(?=\w)", " ", t)              # no hyphens
    t = t.replace("[", "").replace("]", "")
    t = re.sub(r"\n{3,}", "\n\n", t).strip() + "\n"
    return t


blocks = re.split(r"^### ", src, flags=re.M)[1:]
tours = []
for b in blocks:
    head, body = b.split("\n", 1)
    num, slug, title = [x.strip() for x in head.split("|")]
    body = body.strip()
    assert body.count("[beat]") == 1, (slug, body.count("[beat]"))
    assert not re.search(r"\d", body), (slug, re.findall(r".{20}\d.{20}", body))
    tours.append((num, slug, title, body))

(root / "scripts").mkdir(exist_ok=True)
(root / "md").mkdir(exist_ok=True)
combined = ["# Girona — Atlas audio scripts (batch 1)\n",
            f"{len(tours)} single-stop tours. British conversational voice (atlas-audio-tour skill). "
            "Clean text below; TTS-safe versions are in `scripts/`.\n"]
issues = []
for num, slug, title, body in tours:
    clean = f"{title}\n\n{body}\n"
    safe = tts(clean)
    for w in re.findall(r"\b[A-Z]{2,}\b", safe):
        issues.append((slug, "caps", w))
    if re.search(r"[àáèéíïòóúüçÀÁÈÉÍÒÓÚÇ·]", safe):
        issues.append((slug, "accent", re.findall(r"\w*[àáèéíïòóúüçÀÁÈÉÍÒÓÚÇ·]\w*", safe)))
    if re.search(r"\d|-|\[", safe):
        issues.append((slug, "digit/hyphen/bracket", re.findall(r".{10}[\d\-\[].{10}", safe)))
    words = len(body.replace("[beat]", "").split())
    (root / "scripts" / f"{num}_{slug}_clean.txt").write_text(clean)
    (root / "scripts" / f"{num}_{slug}_tts-safe.txt").write_text(safe)
    md = (f"# {num} · {title}\n\n*{words} words · about {round(words / 150 * 60)} seconds at an unhurried pace*\n\n"
          f"## Clean script\n\n{body}\n\n## TTS-safe script\n\n{safe.split(chr(10), 2)[2].strip()}\n")
    (root / "md" / f"{num}_{slug}.md").write_text(md)
    combined.append(f"\n---\n\n## {num} · {title}\n\n*{words} words · ~{round(words / 150 * 60)} s*\n\n{body}\n")
(root / "GIRONA-SCRIPTS.md").write_text("".join(combined))
print(len(tours), "tours")
for num, slug, title, body in tours:
    print(num, slug, len(body.replace('[beat]', '').split()), "words")
print("ISSUES:", *issues, sep="\n")
