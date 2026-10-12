#!/usr/bin/env python3
"""Build the Vienna batch 1 script files from the three clean source files.

For every tour it writes, under drafts/vienna-batch1/scripts/:
  NN_slug_clean.txt      NN_slug_clean.md
  NN_slug_tts-safe.txt   NN_slug_tts-safe.md

The TTS-safe text is derived from the clean text: [beat] markers are dropped
(the paragraph break carries the pause), proper nouns are replaced with
lowercase phonetic respellings, and hyphens, ampersands and slashes are
removed. It then refuses to write anything that still contains a digit, a
bracket, a hyphen, an all-caps word or an unrespelled German character.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "source"
OUT = ROOT / "scripts"

# Longest / most specific first. Applied with word boundaries.
RESPELL = [
    ("Hotel Altstadt Vienna", "Hotel alt shtat Vienna"),
    ("Spittelberggasse", "shpittel berg gasser"),
    ("Spittelberg", "shpittel berg"),
    ("Kirchengasse", "keer khen gasser"),
    ("Wiesenthal", "vee zen tahl"),
    ("Matteo Thun", "mat tay oh toon"),
    ("Atıl Kutoğlu", "ah till koo toe loo"),
    ("Elfrid Wimmer-Repp", "el freed vimmer rep"),
    ("Brigitte Kowanz", "bri gitta koh vants"),
    ("Prachensky", "pra khen skee"),
    ("Attersee", "atter zay"),
    ("Helnwein", "heln vine"),
    ("Biedermeier", "beeder my er"),
    ("Führichgasse", "fyoo rikh gasser"),
    ("Carl Auböck", "carl ow burk"),
    ("Wittmann", "vit man"),
    ("Oswald Haerdtl", "oz valt hairdl"),
    ("Haerdtl", "hairdl"),
    ("Friedrich Kiesler", "freed rikh keez ler"),
    ("Kiesler", "keez ler"),
    ("Öfferl", "urf erl"),
    ("Naber", "nah ber"),
    ("Burggarten", "boorg garten"),
    ("Schubertring", "shoobert ring"),
    ("Ringstraße", "ring shtrasser"),
    ("Atelier Heiss", "atel yay hice"),
    ("Florian Weitzer", "flor ee an vite ser"),
    ("J. & L. Lobmeyr", "jay and el lob my er"),
    ("Lobmeyr", "lob my er"),
    ("Kärntner Straße", "kairnt ner shtrasser"),
    ("Meissl and Schadn", "my sl and shahdn"),
    ("Pferdinand", "fair dee nand"),
    ("Stadtpark", "shtat park"),
    ("Johann Strauss", "yo hahn strauss"),
    ("Landstraßer Gürtel", "lant shtrasser gur tel"),
    ("Gürtel", "gur tel"),
    ("Georg Lippert", "gay org lippert"),
    ("Roland Rohn", "roland rone"),
    ("Erwin Wurm", "air veen voorm"),
    ("Steirereck", "shtire er eck"),
    ("Meierei", "my er eye"),
    ("Reitbauer", "rite bower"),
    ("PPAG", "pee pee ay gee"),
    ("Prückel Creme", "proo kel krem"),
    ("Prückel", "proo kel"),
    ("Stubenring", "shtooben ring"),
    ("Dr-Karl-Lueger-Platz", "doctor karl loo eh ger plats"),
    ("MAK", "mack"),
    ("Maxime Lurion", "max eem loo ree on"),
    ("Lurion", "loo ree on"),
    ("Jakob Gartner", "yah kob gartner"),
    ("Jugendstil", "yoo gent shteel"),
    ("Stella Kadmon", "stella kad mon"),
    ("Der liebe Augustin", "dare leeber ow goos teen"),
    ("Zum Schwarzen Kameel", "tsoom shvart sen ka mail"),
    ("Kameel", "ka mail"),
    ("Johann Baptist Cameel", "yo hahn baptist ka mail"),
    ("Cameel", "ka mail"),
    ("Bognergasse", "bogner gasser"),
    ("Stiebitz", "shtee bits"),
    ("Ferdinand Georg Waldmüller", "ferdinand gay org valt mooler"),
    ("Portois and Fix", "por twah and fix"),
    ("Am Hof", "am hofe"),
    ("Engel Apotheke", "engel apo tay keh"),
    ("Gasthaus Pöschl", "gast house pursh l"),
    ("Pöschl", "pursh l"),
    ("Gasthaus", "gast house"),
    ("Beisl", "by zl"),
    ("Weihburggasse", "vy boorg gasser"),
    ("Franziskanerplatz", "fran tsis kahner plats"),
    ("Hermann Czech", "hair man chekh"),
    ("Falter", "fal ter"),
    ("Mayer am Pfarrplatz", "my er am far plats"),
    ("Pfarrplatz", "far plats"),
    ("Heiligenstädter Straße", "hy ligen shtetter shtrasser"),
    ("Heiligenstadt", "hy ligen shtat"),
    ("St Jakob", "saint yah kob"),
    ("Heuriger", "hoy rigger"),
    ("Beethovengang", "bait hoven gang"),
    ("Kleines Café", "kline es caffay"),
    ("Karl Prantl", "karl prantl"),
    ("Stephansplatz", "shtef ans plats"),
    ("Das LOFT", "dass loft"),
    ("SO/ Vienna", "so Vienna"),
    ("Praterstraße", "prah ter shtrasser"),
    ("Prater", "prah ter"),
    ("Leopoldstadt", "lay oh pold shtat"),
    ("Jean Nouvel", "zhon noo vel"),
    ("Pipilotti Rist", "pippi lotty rist"),
    ("Schwedenplatz", "shvay den plats"),
    ("Urania", "oo rah nee ah"),
    ("Café Sperl", "caffay shperl"),
    ("Sperl", "shperl"),
    ("Gumpendorfer Straße", "goompen dorfer shtrasser"),
    ("Lehárgasse", "lay har gasser"),
    ("Lehár", "lay har"),
    ("Naschmarkt", "nash markt"),
    ("Ronacher", "ron akher"),
    ("Wilhelm Jelinek", "vil helm yel ee nek"),
    ("Anton Groß", "anton grohss"),
    ("Thonet", "toe net"),
    ("Hagengesellschaft", "hah gen geh zell shaft"),
    ("Josef Hoffmann", "yo zef hoffman"),
    ("Hoffmann", "hoffman"),
    ("Koloman Moser", "kolo man moser"),
    ("Linke Wienzeile", "linker veen tsy leh"),
    ("Operngasse", "opern gasser"),
    ("Friedrichstraße", "freed rikh shtrasser"),
    ("Adolf Loos", "adolf lohs"),
    ("Looshaus", "lohs house"),
    ("Loos", "lohs"),
    ("Schiele", "sheela"),
    ("Oskar Kokoschka", "oskar ko kosh ka"),
    ("Kokoschka", "ko kosh ka"),
    ("Karl Kraus", "karl krowss"),
    ("Robert Musil", "robert moo zil"),
    ("Josef Zotti", "yo zef tsotty"),
    ("Zotti", "tsotty"),
    ("Strandbar Herrmann", "shtrant bar hair man"),
    ("Herrmannpark", "hair man park"),
    ("Emanuel Herrmann", "eh mah noo el hair man"),
    ("Herrmann", "hair man"),
    ("Landstraße", "lant shtrasser"),
    ("Alexander Kaiser", "alexander kyzer"),
    ("Ludwig", "lood vig"),
    ("Wiener Werkstätte", "veener vairk shtetter"),
    ("Josef Kniže", "yo zef kuh nee zheh"),
    ("Knize", "kuh nee zheh"),
    ("Kohlmarkt", "kole markt"),
    ("Michaelerplatz", "mikh ah eler plats"),
    ("Marlene Dietrich", "mar lay neh dee trikh"),
    ("Champs-Élysées", "shonz ay lee zay"),
    ("Julianna Mühlbauer", "yoo lee anna mool bower"),
    ("Klaus Mühlbauer", "klowss mool bower"),
    ("Mühlbauer", "mool bower"),
    ("Floridsdorf", "flor idz dorf"),
    ("Seilergasse", "zy ler gasser"),
    ("Neuer Markt", "noyer markt"),
    ("Kühn Malvezzi", "koon mal vetsy"),
    ("Neubaugasse", "noy bow gasser"),
    ("Neubau", "noy bow"),
    ("Georg Raphael Donner", "gay org raphael donner"),
    ("Augarten", "ow garten"),
    ("Spiegelgasse", "shpee gel gasser"),
    ("Claudius Innocentius du Paquier", "clow dee oos inno chen tee oos doo pack ee ay"),
    ("Babenberg", "bah ben berg"),
    ("Michael Powolny", "michael po vol nee"),
    ("Meissen", "my sen"),
    ("Georg-Coch-Platz", "gay org kokh plats"),
    ("Othmar Schimkowitz", "ot mar shim ko vits"),
    ("Goldman and Salatsch", "goldman and zah latch"),
    ("Euboea", "you bee ah"),
    ("Hofburg", "hofe boorg"),
    ("Joseph Maria Olbrich", "yo zef maria ol brikh"),
    ("Olbrich", "ol brikh"),
    ("Karlsplatz", "karls plats"),
    ("Karlskirche", "karls keer kheh"),
    ("Stadtbahn", "shtat barn"),
    ("Kirche am Steinhof", "keer kheh am shtine hofe"),
    ("Steinhof", "shtine hofe"),
    ("Baumgartner Höhe", "bowm gartner her eh"),
    ("Richard Luksch", "rikh ard looksh"),
    ("Severin", "sev er een"),
    ("Margaret Stonborough-Wittgenstein", "margaret stone burra vit gen shtine"),
    ("Haus Wittgenstein", "house vit gen shtine"),
    ("Wittgenstein", "vit gen shtine"),
    ("Kundmanngasse", "koond man gasser"),
    ("Paul Engelmann", "paul eng el man"),
    ("Engelmann", "eng el man"),
    ("Rochusmarkt", "rokh oos markt"),
    ("Wotrubakirche", "vot roo ba keer kheh"),
    ("Fritz Wotruba", "fritz vot roo ba"),
    ("Wotruba", "vot roo ba"),
    ("Georgenberg", "gay orgen berg"),
    ("Mauer", "mower"),
    ("Fritz Gerhard Mayr", "fritz gare hard my er"),
    ("Karl-Marx-Hof", "karl marx hofe"),
    ("Karl Ehn", "karl ain"),
    ("Zwölfter-Februar-Platz", "tsverlf ter feb roo ar plats"),
    ("Waschsalon", "vash sa lon"),
    ("Werkbundsiedlung", "vairk boont zeed loong"),
    ("Werkbund", "vairk boont"),
    ("Hietzing", "heet sing"),
    ("Roter Berg", "roter bairg"),
    ("Josef Frank", "yo zef frank"),
    ("Margarete Schütte-Lihotzky", "mar ga ray teh shoota lee hots key"),
    ("Gerrit Rietveld", "gerrit reet felt"),
    ("Rietveld", "reet felt"),
    ("Richard Neutra", "richard noy tra"),
    ("Hugo Häring", "hugo hair ing"),
    ("André Lurçat", "on dray loor sah"),
    ("Library & Learning Center", "Library and Learning Center"),
    ("WU", "vay oo"),
    ("Zaha Hadid", "zah ha ha deed"),
    ("Hauptallee", "howpt al lay"),
    ("Josefsplatz", "yo zefs plats"),
    ("Johann Bernhard Fischer von Erlach", "yo hahn bairn hard fisher fon air lakh"),
    ("Joseph Emanuel", "yo zef eh mah noo el"),
    ("Palais Pallavicini", "pa lay pala vee cheeny"),
    ("Palais Pálffy", "pa lay pal fee"),
    ("Hofmobiliendepot", "hofe mo bee lee en deh po"),
    ("Andreasgasse", "an dray as gasser"),
    ("Mariahilfer Straße", "ma ree ah hilfer shtrasser"),
    ("Möbel Museum Wien", "murbel museum veen"),
    ("Georg Roy", "gay org roy"),
    ("Haas-Haus", "harss house"),
    ("Hans Hollein", "hans hol line"),
    ("Hollein", "hol line"),
    ("Flakturm", "flak toorm"),
    ("Friedrich Tamms", "freed rikh tamms"),
    ("Yppenplatz", "ippen plats"),
    ("Ottakring", "otta kring"),
    ("Brunnenmarkt", "broo nen markt"),
    ("Brunnengasse", "broo nen gasser"),
    ("Neulerchenfeld", "noy lair khen felt"),
    ("Thaliastraße", "tah lee ah shtrasser"),
    ("Zentralfriedhof", "tsen trahl freed hofe"),
    ("Simmering", "zimmer ing"),
    ("Max Hegele", "max hay geh leh"),
    ("Karl Lueger", "karl loo eh ger"),
    ("Lueger", "loo eh ger"),
    ("Kahlenberg", "kah len berg"),
    ("Grinzing", "grin tsing"),
    ("Nussdorf", "nooss dorf"),
    ("Jan Sobieski", "yan so bee es key"),
    ("Sobieski", "so bee es key"),
    ("Josefskirche", "yo zefs keer kheh"),
    ("Donau City", "doe now city"),
    ("thirty-two A", "thirty two ay"),
    ("Graben's", "grah ben's"),
    ("Graben", "grah ben"),
    ("cipollino", "chip oh leeno"),
    ("Wimmer", "vimmer"),
    ("Hegele", "hay geh leh"),
    ("Hadid", "ha deed"),
    ("Wien", "veen"),
    ("Wiener", "veener"),
    ("Georg", "gay org"),
    ("Johann", "yo hahn"),
    ("Josef", "yo zef"),
    ("St", "Saint"),
]

# "Czech" is a nationality in the Knize script and a surname elsewhere.
CZECH_SURNAME = re.compile(r"\bCzech(?= (?:is|has|laid|to)\b)|\bCzech's\b")


def to_tts(text):
    text = "\n".join(l for l in text.splitlines() if l.strip() != "[beat]")
    text = CZECH_SURNAME.sub(lambda m: m.group(0).replace("Czech", "chekh"), text)
    for a, b in RESPELL:
        text = re.sub(r"(?<![\w])" + re.escape(a) + r"(?![\w])", b, text)
    for x, y in (("façade", "facade"), ("Café", "Caffay"), ("cafés", "caffays"), ("café", "caffay")):
        text = text.replace(x, y)
    text = text.replace("&", "and").replace("/", " ")
    text = re.sub(r"(?<=\w)-(?=\w)", " ", text)
    text = text.replace(" — ", ", ").replace("—", ", ")
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text).strip() + "\n"
    return text


BAD = [
    (re.compile(r"\d"), "digit"),
    (re.compile(r"[\[\]\(\)\{\}<>/&*_#]"), "bracket or markup"),
    (re.compile(r"-"), "hyphen"),
    (re.compile(r"\b[A-Z]{2,}\b"), "all-caps word"),
    (re.compile(r"[äöüÄÖÜßéèáàíóúçığžÉ]"), "unrespelled accent"),
    (re.compile(r"\bbeat\b", re.I), "beat marker"),
]


def check(name, text, kind):
    problems = []
    for rx, what in BAD:
        for m in rx.finditer(text):
            if kind == "clean" and what in ("hyphen", "unrespelled accent", "all-caps word", "beat marker", "bracket or markup"):
                continue
            ctx = text[max(0, m.start() - 25): m.end() + 25].replace("\n", " ")
            problems.append(f"{name} [{kind}] {what}: ...{ctx}...")
    if kind == "clean":
        # The clean version keeps [beat] and accents, but may never carry a digit.
        pass
    return problems


def md(text):
    title, _, body = text.partition("\n")
    return f"# {title.strip()}\n\n{body.strip()}\n"


def main():
    src = "".join(p.read_text() for p in sorted(SRC.glob("clean-*.txt")))
    blocks = re.split(r"^=== ", src, flags=re.M)[1:]
    OUT.mkdir(exist_ok=True)
    problems, rows = [], []
    for blk in blocks:
        head, body = blk.split("\n", 1)
        num, slug = head.split()
        clean = body.strip() + "\n"
        tts = to_tts(clean)
        stem = f"{num}_{slug}"
        problems += check(stem, clean, "clean")
        problems += check(stem, tts, "tts-safe")
        if "[beat]" not in clean:
            problems.append(f"{stem}: clean has no [beat]")
        rows.append((stem, clean, tts))
    if problems:
        print("\n".join(problems))
        sys.exit(1)
    for stem, clean, tts in rows:
        (OUT / f"{stem}_clean.txt").write_text(clean)
        (OUT / f"{stem}_clean.md").write_text(md(clean))
        (OUT / f"{stem}_tts-safe.txt").write_text(tts)
        (OUT / f"{stem}_tts-safe.md").write_text(md(tts))
    print(f"OK {len(rows)} tours -> {len(rows) * 4} files in {OUT}")


if __name__ == "__main__":
    main()
