#!/usr/bin/env python3
"""Build the MD + TTS-safe TXT for each clean script in ../scripts/.

Clean   scripts/NN-slug.txt        (hand-written, the source of truth)
MD      scripts/NN-slug.md         (clean script + metadata, respellings, sources)
TTS     scripts/NN-slug_tts.txt    (phonetic respellings, no [beat], no hyphens)

TTS rules (owner's standing preference): phonetic respelling only, lowercase
respellings, no caps, no hyphens, no brackets or markup, [beat] becomes a
paragraph break, years already spelled out in the clean script.
"""
import os
import re
import sys
import unicodedata

HERE = os.path.dirname(os.path.abspath(__file__))
SCRIPTS = os.path.join(HERE, "..", "scripts")

# slug -> (place, city, lat, lon, tts title, respellings, sources)
TOURS = {
    "01-tours-aillaud": dict(
        place="Les Tours Aillaud (Tours Nuages), avenue Pablo-Picasso",
        city="Nanterre, France", lat=48.889872019056696, lon=2.226992520173109,
        tts_title="The Eye oh Towers",
        resp=[("Désordre apparent, ordre caché", "day zordruh appa ron, ordruh cashay"),
              ("Parc André-Malraux", "park on dray mal ro"),
              ("Giscard d'Estaing", "zhee scar day stan"),
              ("grands ensembles", "gron zon som bluh"),
              ("La Défense", "la day fonce"),
              ("Florence Rieti", "florence ree etty"),
              ("Fabio Rieti", "fabby oh ree etty"),
              ("Émile Aillaud", "ay meel eye oh"),
              ("Aillaud", "eye oh"),
              ("Nanterre", "non tair"),
              ("Pablo-Picasso", "pablo picasso")],
        sources=["https://fr.wikipedia.org/wiki/Tours_Aillaud"]),
    "02-cite-de-la-muette-drancy": dict(
        place="Cité de la Muette / Mémorial de la Shoah de Drancy, avenue Jean-Jaurès",
        city="Drancy, France", lat=48.91915597553556, lon=2.4550710393194985,
        tts_title="Seetay de la Mwet and the Dronsee Memorial",
        resp=[("Cité de la Muette", "seetay de la mwet"),
              ("Eugène Beaudouin", "oo zhen bo dwan"),
              ("Marcel Lods", "marsell lod"),
              ("Vladimir Bodiansky", "vladimir bodee ansky"),
              ("Jean Prouvé", "zhon proovay"),
              ("Jean-Jaurès", "zhon zho ress"),
              ("Auschwitz-Birkenau", "owsh vits beer kuh now"),
              ("Shelomo Selinger", "shlomo selinger"),
              ("letter shin", "letter sheen"),
              ("Drancy", "dronsee"),
              ("Shoah", "show ah"),
              ("the cité", "the seetay")],
        sources=["https://fr.wikipedia.org/wiki/Cit%C3%A9_de_la_Muette",
                 "https://www.europeremembers.com/pois/411/the-shoah-memorial-drancy",
                 "https://uk.tourisme93.com/drancy-camp-memorial.html",
                 "https://www.visitparisregion.com/fr/memorial-de-la-shoah-drancy"]),
    "03-la-grande-borne": dict(
        place="La Grande Borne (Grigny / Viry-Châtillon)",
        city="Grigny, France", lat=48.652242798164714, lon=2.375369277186132,
        tts_title="La Grond Born",
        resp=[("François-Xavier Lalanne", "fron swah zav yay la lan"),
              ("Place de l'Œuf", "plass duh luff"),
              ("Laurence Rieti", "lo ronce ree etty"),
              ("Fabio Rieti", "fabby oh ree etty"),
              ("La Grande Borne", "la grond born"),
              ("Émile Aillaud", "ay meel eye oh"),
              ("Aillaud", "eye oh"),
              ("Labyrinthe", "la bee rant"),
              ("Méridien", "may ree dee an"),
              ("Peupleraie", "pupluh ray"),
              ("arrondissement", "arron deese mon"),
              ("Gilles", "zheel"),
              ("Grigny", "green yee"),
              ("A6 motorway", "A six motorway"),
              ("Nanterre", "non tair")],
        sources=["https://fr.wikipedia.org/wiki/La_Grande_Borne",
                 "https://inventaire.iledefrance.fr/illustration/IVR11_20129100024NUC4A",
                 "https://www.centrepompidou.fr/fr/ressources/oeuvre/cbqr8dk",
                 "https://francearchives.gouv.fr/facomponent/c61ba65509ff92ce89d2f67f93d033a962aa1069"]),
    "04-arcades-du-lac": dict(
        place="Les Arcades du Lac & Le Viaduc, Lac de la Sourderie",
        city="Montigny-le-Bretonneux (Saint-Quentin-en-Yvelines), France",
        lat=48.76701302046429, lon=2.046248488948336,
        tts_title="Lay Zarcad doo Lack",
        resp=[("Les Arcades du Lac", "lay zarcad doo lack"),
              ("Lac de la Sourderie", "lack duh la soor duh ree"),
              ("Montigny-le-Bretonneux", "mon teen yee luh bruh ton nuh"),
              ("Taller de Arquitectura", "tie air day arkee tek toora"),
              ("Ricardo Bofill", "ricardo bo feel"),
              ("Le Viaduc", "luh vee a duke"),
              ("the Viaduc", "the vee a duke"),
              ("Pont d'Avignon", "pon da veen yon"),
              ("Chenonceau", "shuh non so"),
              ("Segovia", "seg oh via"),
              ("Bofill", "bo feel"),
              ("château", "shatto"),
              ("Versailles", "vair sigh")],
        sources=["https://www.e-architect.com/france/les-arcades-du-lac",
                 "https://www.designboom.com/?p=410821",
                 "https://ww3.rics.org/uk/en/modus/built-environment/homes-and-communities/visions-of-the-future--paris-s-grands-ensembles.html",
                 "https://www.universalis.fr/encyclopedie/ricardo-bofill/"]),
    "05-etoiles-de-renaudie": dict(
        place="Les Étoiles de Renaudie / Centre Jeanne-Hachette",
        city="Ivry-sur-Seine, France", lat=48.813755821253395, lon=2.3850938211113766,
        tts_title="Lay Zay twahl duh Ro no dee",
        resp=[("Les Étoiles de Renaudie", "lay zay twahl duh ro no dee"),
              ("Centre Jeanne-Hachette", "sontruh zhan ash et"),
              ("Renée Gailhoustet", "ruh nay guy oo stay"),
              ("Jean Renaudie", "zhon ro no dee"),
              ("Danielle Casanova", "danny ell casanova"),
              ("Mairie d'Ivry", "mairy deev ree"),
              ("Ivry-sur-Seine", "eev ree soor senn"),
              ("Gailhoustet", "guy oo stay"),
              ("Renaudie", "ro no dee")],
        sources=["https://www.pariszigzag.fr/?p=122806",
                 "https://itinerances.citedelarchitecture.fr/sites/default/files/documents/2017-09/fo_ensembledhabitationdaniellecasanova_def.pdf",
                 "https://inventaire.iledefrance.fr/dossier/pdf/4efc5c99-57f7-4711-9f52-d4a17fd95db7/atelier-du-peintre-d-isaac-celnikier-varsovie-1923-paris-2011-situe-dans-l-ensemble-de-logements-jeanne-hachette.pdf",
                 "https://www.ivry94.fr/fileadmin/www.ivry94.fr/MEDIA/Cadre_de_vie/Projets-urbains/2021-IMV525_Dossier-JeanneHachette.pdf"]),
    "06-orgues-de-flandre": dict(
        place="Les Orgues de Flandre, avenue de Flandre (Paris 19e)",
        city="Paris, France", lat=48.8897756873707, lon=2.3750060164409814,
        tts_title="Lay Zorg duh Flondruh",
        resp=[("Les Orgues de Flandre", "lay zorg duh flondruh"),
              ("Orgues de Flandre", "org duh flondruh"),
              ("Martin Schulz van Treeck", "martin shoolts fan trake"),
              ("cité des Flamands", "seetay day fla mon"),
              ("Porte des Flamands", "port day fla mon"),
              ("Bassin de la Villette", "bassan duh la vee let"),
              ("Le Péril jeune", "luh pay reel zhun"),
              ("Cédric Klapisch", "sed rick kla peesh"),
              ("Avenue de Flandre", "avenue duh flondruh"),
              ("organs of Flandre", "organs of flondruh"),
              ("arrondissement", "arron deese mon"),
              ("Prélude", "pray lood"),
              ("Cantate", "con tat"),
              ("Sonate", "so nat"),
              ("Crimée", "cree may"),
              ("Riquet", "ree kay")],
        sources=["https://fr.wikipedia.org/wiki/Orgues_de_Flandre"]),
    "07-arenes-de-picasso": dict(
        place="Les Arènes de Picasso, place Pablo-Picasso",
        city="Noisy-le-Grand, France", lat=48.83902884679481, lon=2.555522868151227,
        tts_title="Lay Zarenn duh Picasso",
        resp=[("Les Arènes de Picasso", "lay zarenn duh picasso"),
              ("Manuel Núñez Yanowsky", "manwell noon yeth yanovsky"),
              ("Núñez Yanowsky", "noon yeth yanovsky"),
              ("Espaces d'Abraxas", "es pass dab rax us"),
              ("Marne-la-Vallée", "marn la va lay"),
              ("Noisy-le-Grand", "nwah zee luh gron"),
              ("Place Pablo-Picasso", "plass pablo picasso"),
              ("Park Güell", "park gwell"),
              ("Billy Ze Kick", "billy zuh kick"),
              ("Ricardo Bofill", "ricardo bo feel"),
              ("Vermines", "vair meen"),
              ("Boullée", "boo lay"),
              ("Gaudí", "gow dee"),
              ("camemberts", "camem bears")],
        sources=["https://fr.wikipedia.org/wiki/Ar%C3%A8nes_de_Picasso",
                 "https://www.pariszigzag.fr/insolite/arenes-de-picasso-noisy/",
                 "https://divisare.com/projects/332390-manuel-nunez-yanowsky-gili-merin-les-arenes-de-picasso"]),
    "08-choux-de-creteil": dict(
        place="Les Choux de Créteil / Résidence étudiante ARPEJ Les Choux, 2 boulevard Pablo-Picasso",
        city="Créteil, France", lat=48.78510463252899, lon=2.444722571831556,
        tts_title="Lay Shoo duh Cray tay",
        resp=[("Les Choux de Créteil", "lay shoo duh cray tay"),
              ("Lac de Créteil", "lack duh cray tay"),
              ("Choucrouterie Benoist", "shoo croo tree ben wah"),
              ("Gérard Grandval", "zhay rar gron val"),
              ("Tellement proches", "tell mon prosh"),
              ("Le Brio", "luh bree oh"),
              ("les Choux", "lay shoo"),
              ("Boulevard Pablo-Picasso", "boulevard pablo picasso"),
              ("boulevard Pablo-Picasso", "boulevard pablo picasso"),
              ("Noisy-le-Grand", "nwah zee luh gron"),
              ("the Aillaud towers", "the eye oh towers"),
              ("the Arènes", "the arenn"),
              ("Grandval", "gron val"),
              ("Nanterre", "non tair"),
              ("Créteil", "cray tay")],
        sources=["https://fr.wikipedia.org/wiki/Choux_de_Cr%C3%A9teil",
                 "https://www.whitemad.pl/en/les-choux-de-creteil-skyscrapers-covered-with-concrete-leaves/",
                 "https://www.arpej.fr/?p=49500",
                 "https://www.location-etudiant.fr/residence-ARPEJ-LES-CHOUX-DE-CRETEIL-Creteil-80839.html"]),
}


def tts(body, resp):
    t = body
    for src, dst in sorted(resp, key=lambda p: -len(p[0])):
        t = t.replace(src, dst)
    t = re.sub(r"\n*\[beat\]\n*", "\n\n", t)          # beat -> paragraph break
    t = re.sub(r"(?<=\w)-(?=\w)", " ", t)              # no hyphens
    t = re.sub(r"[\[\]{}<>*_#`]", "", t)               # no markup
    t = t.replace("—", ",").replace("–", ",")
    return re.sub(r"\n{3,}", "\n\n", t).strip() + "\n"


def problems(t):
    out = []
    if re.search(r"\d", t):
        out.append("digits")
    acc = sorted({c for c in t if unicodedata.combining(unicodedata.normalize("NFD", c)[-1:] or " ")
                  or c in "œŒ"})
    if acc:
        out.append("accents " + "".join(acc))
    if "-" in t:
        out.append("hyphen")
    return out


def main():
    bad = 0
    for slug, m in TOURS.items():
        raw = open(os.path.join(SCRIPTS, slug + ".txt"), encoding="utf-8").read()
        title, body = raw.split("\n", 1)
        body = body.strip()
        words = len(re.findall(r"[\w'’]+", body.replace("[beat]", "")))
        mins = words / 155
        tts_text = m["tts_title"] + "\n\n" + tts(body, m["resp"])
        p = problems(tts_text)
        if p:
            bad += 1
            print(f"{slug}: TTS problems: {p}", file=sys.stderr)
        open(os.path.join(SCRIPTS, slug + "_tts.txt"), "w", encoding="utf-8").write(tts_text)
        used = [(s, d) for s, d in m["resp"] if s in body or s == title]
        md = [f"# {title}", "",
              f"**Series:** Grands Ensembles · **Place:** {m['place']}  ",
              f"**City:** {m['city']}  ",
              f"**Coordinates:** {m['lat']}, {m['lon']}  ",
              f"**Length:** {words} words · about {int(mins)}:{int((mins % 1) * 60):02d} at a natural pace  ",
              f"**TTS title:** {m['tts_title']}", "",
              "## Script (clean)", "", body, "",
              "## Respellings (used in the TTS-safe version)", "",
              "| Written | Say it |", "|---|---|"]
        md += [f"| {s} | {d} |" for s, d in used]
        md += ["", "`[beat]` marks a deliberate pause. The TTS-safe file replaces it with a paragraph break.",
               "", "## Sources read before writing", ""]
        md += [f"- {u}" for u in m["sources"]]
        open(os.path.join(SCRIPTS, slug + ".md"), "w", encoding="utf-8").write("\n".join(md) + "\n")
        print(f"{slug}: {words} words, ~{mins:.1f} min, {len(used)} respellings, TTS {'OK' if not p else 'CHECK'}")
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
