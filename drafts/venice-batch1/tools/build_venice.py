#!/usr/bin/env python3
"""Build the Venice batch scripts from src/scripts.md.

For each tour writes, into scripts/:
  NN_<slug>_clean.md / .txt      the authoring version ([beat] kept as a marker)
  NN_<slug>_tts-safe.md / .txt   the version read to the voice

TTS-safe rules (owner standing preference):
  - phonetic respelling of hard names, lowercase, no hyphens, no capitals-for-emphasis
  - no markup or brackets; [beat] becomes a plain paragraph break
  - years and numbers already spelled out in the clean text; hyphens dropped
  - titles respelled too when the title itself would trip TTS

Usage: python3 -I build_venice.py <batch dir>
"""
import re, sys
from pathlib import Path

# Longest keys first so multi-word names win over their parts.
RESPELL = {
    "Ca' Corner della Regina": "car corner della reh jee na",
    "Ca' Rampani": "car ram pah nee",
    "Ca' Macana": "car ma kah na",
    "Ca' Foscari": "car foss ka ree",
    "Ca' di Dio": "car dee dee oh",
    "Rio Ca' di Dio": "ree oh car dee dee oh",
    "Ca' d'Oro alla Vedova": "car doro alla veh doh va",
    "Cà D'Oro alla Vedova": "car doro alla veh doh va",
    "Ca' d'Oro": "car doro",
    "Calle de Ca' Corner": "kal lay day car corner",
    "Cantinone del Vino già Schiavi": "kanti noh nay del vee no jah skee ah vee",
    "già Schiavi": "jah skee ah vee",
    "Già Schiavi": "jah skee ah vee",
    "Riva degli Schiavoni": "ree va del yee skee a voh nee",
    "Sansovino": "san so vee no",
    "Patricia Urquiola": "patricia oor kee oh la",
    "Urquiola": "oor kee oh la",
    "Murano": "moo rah no",
    "Zattere": "zat teh ray",
    "Giudecca": "joo deck a",
    "Dorothée Meilichzon": "doro tay may lish zon",
    "Meilichzon": "may lish zon",
    "Adriatica": "adree ah tee ka",
    "Palazzo Papadopoli": "pa lat so pappa doppo lee",
    "Papadopoli": "pappa doppo lee",
    "Calle Tiepolo": "kal lay tee eh polo",
    "Tiepolo": "tee eh polo",
    "Gian Giacomo de' Grigi": "jan jah ko mo day gree jee",
    "Coccina": "kot chee na",
    "Arrivabene Valenti Gonzaga": "arree va beh nay va len tee gon zah ga",
    "Gilberto": "jil bair toe",
    "Córdoba": "kor doba",
    "Bergamo": "bair ga mo",
    "Venissa": "ven issa",
    "Mazzorbo": "mat sor bo",
    "Burano": "boo rah no",
    "Torcello": "tor chello",
    "Dorona": "doh roh na",
    "Gianluca Bisol": "jan loo ka bee sol",
    "Prosecco": "pro secco",
    "Andrea Gritti": "an dray a gree tee",
    "Gritti": "gree tee",
    "Pisani": "pee zah nee",
    "Campo Santa Maria del Giglio": "kampo santa maria del jeel yo",
    "Santa Maria del Giglio": "santa maria del jeel yo",
    "traghetto": "tra get toe",
    "Rio Terà de le Carampane": "ree oh teh rah day lay karam pah nay",
    "Carampane": "karam pah nay",
    "rio terà": "ree oh teh rah",
    "Bortoluzzi": "bor toe loot see",
    "Francesco Agopyan": "fran chess ko a go pee an",
    "Piera": "pee eh ra",
    "cassopipa": "kasso pee pa",
    "fritto misto": "free toe mee sto",
    "Ponte de le Tette": "pon tay day lay tet tay",
    "Osteria alle Testiere": "osteh ree a allay test yeh ray",
    "alle Testiere": "allay test yeh ray",
    "Testiere": "test yeh ray",
    "Calle del Mondo Novo": "kal lay del mondo no vo",
    "Campo Santa Maria Formosa": "kampo santa maria for mo za",
    "Santa Maria Formosa": "santa maria for mo za",
    "Bruno Gavagnin": "bruno ga van yeen",
    "Luca di Vita": "luka dee vee ta",
    "Da Mario": "dah mario",
    "Querini Stampalia": "kweh ree nee stam pah lee a",
    "Campiello Querini": "kam pee ello kweh ree nee",
    "Salizada dei Greci": "sali tsah da day greh chee",
    "salizada": "sali tsah da",
    "San Zaccaria": "san zakka ree a",
    "San Giorgio dei Greci": "san jor jo day greh chee",
    "Benedetta Fullin": "beneh detta fool in",
    "Manuel Trevisan": "manuel treh vee zan",
    "Salvatore Sodano": "salva toe ray so dah no",
    "Campania": "kam pah nya",
    "Veneto": "veh neh toe",
    "Trattoria al Gatto Nero": "tratto ree a al gatto neh ro",
    "Fondamenta della Giudecca": "fonda menta della joo deck a",
    "Ruggero": "roo jeh ro",
    "Massimiliano": "massi mee lee ah no",
    "Bovo": "bo vo",
    "Strada Nova": "strah da no va",
    "Vedova": "veh doh va",
    "polpette": "pol pet tay",
    "cicchetti": "chee ket tee",
    "bacaro": "back a ro",
    "saor": "sa or",
    "Baccalà": "bakka lah",
    "baccalà": "bakka lah",
    "Fondamenta Nani": "fonda menta nah nee",
    "Rio di San Trovaso": "ree oh dee san tro vah zo",
    "Squero di San Trovaso": "skweh ro dee san tro vah zo",
    "San Trovaso": "san tro vah zo",
    "squero": "skweh ro",
    "Sisto Gastaldi": "sisto ga stal dee",
    "Alessandra De Respinis": "alless andra day res pee nees",
    "Bottegon": "botteh gon",
    "Al Timon": "al tee mon",
    "Fondamenta degli Ormesini": "fonda menta del yee or meh zee nee",
    "Ormesini": "or meh zee nee",
    "Fondamenta della Misericordia": "fonda menta della mizeh ree kor dee a",
    "bragozzo": "bra got so",
    "Cannaregio": "kanna reh jo",
    "Il Mercante": "eel mer kan tay",
    "Campo dei Frari": "kampo day frah ree",
    "Caffè dei Frari": "kaff ay day frah ree",
    "Frari": "frah ree",
    "Alessandro Zampieri": "alless andro zam pee eh ree",
    "Titian": "tishun",
    "Caffè Florian": "kaff ay flor ee an",
    "Caffè Quadri": "kaff ay kwah dree",
    "Floriano Francesconi": "flor ee ah no fran cheh sko nee",
    "Floriano": "flor ee ah no",
    "Alla Venezia Trionfante": "alla veh net see a tree on fan tay",
    "Procuratie Nuove": "pro koo rah tee eh nwo vay",
    "Procuratie Vecchie": "pro koo rah tee eh vek ee eh",
    "Casanova": "kaza no va",
    "Carlo Goldoni": "karlo gol doh nee",
    "Riccardo Selvatico": "ree kar doe sel vah tee ko",
    "Lodovico Cadorin": "lodo vee ko ka doh rin",
    "Fortuny Showroom and Factory": "for too nee showroom and factory",
    "Mariano Fortuny y Madrazo": "mariano for too nee ee ma drah zo",
    "Fortuny": "for too nee",
    "Fondamenta San Biagio": "fonda menta san bee ah jo",
    "Molino Stucky": "mo lee no stookee",
    "Granada": "gra nah da",
    "Henriette Negrin": "on ree et neg rin",
    "Elsie McNeill Lee": "elsie mac neel lee",
    "Tessitura Luigi Bevilacqua": "tessi too ra loo ee jee beh vee lak wa",
    "Luigi Bevilacqua": "loo ee jee beh vee lak wa",
    "Giacomo Bevilacqua": "jah ko mo beh vee lak wa",
    "Bevilacqua": "beh vee lak wa",
    "Campo San Zan Degolà": "kampo san zan deg o lah",
    "Santa Croce": "santa kro chay",
    "Giovanni Mansueti": "jo vah nee man soo eh tee",
    "Jacquard": "jack ard",
    "soprarizzo": "so pra reet so",
    "Basilica della Salute": "ba zilli ka della sa loo tay",
    "Salute": "sa loo tay",
    "Dresden": "dresden",
    "Calle de le Botteghe": "kal lay day lay bot teh gay",
    "papier-mâché": "pap yay mash ay",
    "bauta": "bow ta",
    "Campo Santa Margherita": "kampo santa mar geh ree ta",
    "Dorsoduro": "dor so doo ro",
    "Accademia": "akka deh mee a",
    "Libreria Acqua Alta": "lee breh ree a akwa alta",
    "Calle Longa Santa Maria Formosa": "kal lay longa santa maria for mo za",
    "Acqua Alta": "akwa alta",
    "acqua alta": "akwa alta",
    "Luigi Frizzo": "loo ee jee freet so",
    "Luigi": "loo ee jee",
    "Fondazione Querini Stampalia": "fon dat see oh nay kweh ree nee stam pah lee a",
    "Giovanni Querini Stampalia": "jo vah nee kweh ree nee stam pah lee a",
    "Carlo Scarpa": "karlo scarpa",
    "Negozio Olivetti": "neh got see oh olly vetty",
    "Olivetti": "olly vetty",
    "Aurisina": "ow ree zee na",
    "Alberto Viani": "al bair toe vee ah nee",
    "Punta della Dogana": "poon ta della doh gah na",
    "Dogana da Mar": "doh gah na da mar",
    "Giuseppe Benoni": "joo zep pay beh no nee",
    "François Pinault": "fran swah pee no",
    "Tadao Ando": "ta dow ando",
    "Bourse de Commerce": "boorse de commerce",
    "Fondazione Giorgio Cini": "fon dat see oh nay jor jo chee nee",
    "Vittorio Cini": "vee tor ee oh chee nee",
    "Giorgio": "jor jo",
    "Paolo Veronese": "pow lo veh ro neh zay",
    "Baldassare Longhena": "bal da sah ray long gay na",
    "Le Stanze del Vetro": "lay stan zay del veh tro",
    "Palladio": "pa lah dee oh",
    "Fondazione Prada": "fon dat see oh nay prah da",
    "Domenico Rossi": "do meh nee ko rossi",
    "Corner della Regina": "corner della reh jee na",
    "Caterina Cornaro": "ka teh ree na kor nah ro",
    "Monte di Pietà": "mon tay dee pee eh tah",
    "Christoph Büchel": "kris toff boo shel",
    "Pescheria": "pesk eh ree a",
    "Giardini della Biennale": "jar dee nee della bee en nah lay",
    "Giardini": "jar dee nee",
    "Biennale": "bee en nah lay",
    "Josef Hoffmann": "yo sef hoffman",
    "Sverre Fehn": "svair reh fain",
    "Sant'Elena": "sant eh leh na",
    "Castello": "kass tello",
    "Basilica di San Giorgio Maggiore": "ba zilli ka dee san jor jo ma jor ay",
    "San Giorgio Maggiore": "san jor jo ma jor ay",
    "San Giorgio": "san jor jo",
    "Vicenza": "vee chen za",
    "Simone Sorella": "see mo nay so rella",
    "Tintoretto": "tinto retto",
    "Piazzetta": "pee at setta",
    "Lido": "lee doe",
    "Scala Contarini del Bovolo": "skah la kon ta ree nee del bo vo lo",
    "Corte Contarini del Bovolo": "kor tay kon ta ree nee del bo vo lo",
    "Contarini": "kon ta ree nee",
    "Bovolo": "bo vo lo",
    "Campo Manin": "kampo ma neen",
    "Giorgio Spavento": "jor jo spa ven toe",
    "Giovanni Candi": "jo vah nee kan dee",
    "Brabantio": "bra ban tee oh",
    "Ponte della Costituzione": "pon tay della kos tee too tsee oh nay",
    "Santiago Calatrava": "santee ah go kala trah va",
    "Calatrava": "kala trah va",
    "Piazzale Roma": "pee at sah lay roma",
    "Santa Lucia": "santa loo chee a",
    "Università Iuav di Venezia": "oonee vair see tah ee oo av dee veh net see a",
    "Iuav": "ee oo av",
    "Tolentini": "toe len tee nee",
    "Campazzo dei Tolentini": "kam pat so day toe len tee nee",
    "Vincenzo Scamozzi": "veen chen zo ska mot see",
    "Theatine": "thee a tine",
    "Sergio Los": "sair jo loss",
    "verum ipsum factum": "vair um ipsum fak tum",
    "Giambattista Vico": "jam bat teesta vee ko",
    "Cimitero di San Michele": "chee mee teh ro dee san mee keh lay",
    "San Michele in Isola": "san mee keh lay in ee zo la",
    "San Michele": "san mee keh lay",
    "San Cristoforo": "san kris toe foro",
    "Mauro Codussi": "mow ro ko doo see",
    "Codussi": "ko doo see",
    "Istrian": "istree an",
    "Rialto": "ree al toe",
    "Pescheria": "pesk eh ree a",
    "Rocco": "rocco",
    "Ca'": "car",
    "Riva": "ree va",
    "doges": "dohjes",
    "Doge": "dohj",
    "fondamenta": "fonda menta",
    "Fondamenta": "fonda menta",
    "palazzi": "pa lat see",
    "Palazzo": "pa lat so",
    "palazzo": "pa lat so",
    "aperitivo": "a peh ree tee vo",
    "ombra": "om bra",
    "crostini": "kro stee nee",
    "campiello": "kam pee ello",
    "Campo": "kampo",
    "campo": "kampo",
    "Calle": "kal lay",
    "loggia": "lo ja",
    "terrazzo": "teh rat so",
    "spritz": "spritz",
    "Arsenale": "arseh nah lay",
    "Antiche": "an tee kay",
    "Schiavi": "skee ah vee",
    "Rampani": "ram pah nee",
    "Il Palazzo Experimental": "eel pa lat so experimental",
    "Trattoria": "tratto ree a",
    "trattoria": "tratto ree a",
    "Terrazzo": "teh rat so",
    "osteria": "osteh ree a",
    "Osteria": "osteh ree a",
}

def respell(text):
    keys = sorted(RESPELL, key=len, reverse=True)
    pat = re.compile("|".join(r"(?<![\w'])" + re.escape(k) + r"(?![\w])" for k in keys))
    return pat.sub(lambda m: RESPELL[m.group(0)], text)

def tts(text):
    t = text.replace("[beat]", "")
    t = respell(t)
    t = t.replace("—", ",").replace("–", " ")
    t = re.sub(r"(?<=\w)-(?=\w)", " ", t)       # no hyphens
    t = t.replace("Sant'", "sant ").replace("’", "'")
    t = re.sub(r"[\[\]\(\)\*_#<>]", "", t)        # no markup or brackets
    t = re.sub(r"[ \t]+", " ", t)
    t = re.sub(r" ,", ",", t)
    t = re.sub(r"\n{3,}", "\n\n", t).strip()
    return t + "\n"

def main(batch):
    batch = Path(batch)
    src = (batch / "src" / "scripts.md").read_text()
    out = batch / "scripts"; out.mkdir(exist_ok=True)
    rows = []
    for block in src.split("=== ")[1:]:
        head, body = block.split("\n", 1)
        nn, slug, section, gname, lat, lon, title = [x.strip() for x in head.split("|")]
        body = body.strip() + "\n"
        stem = f"{nn}_{slug}"
        words = len(re.findall(r"[A-Za-z']+", body.replace("[beat]", "")))
        mins = words / 150
        meta = (f"**{section}** · Google Maps: *{gname}* · {lat}, {lon}  \n"
                f"~{words} words · about {int(mins)}:{int(mins%1*60):02d} at a natural pace")
        (out / f"{stem}_clean.md").write_text(f"# {title}\n\n{meta}\n\n---\n\n{body}")
        (out / f"{stem}_clean.txt").write_text(f"{title}\n\n{body}")
        tt, tb = tts(title).strip(), tts(body)
        (out / f"{stem}_tts-safe.md").write_text(
            f"# {title} — TTS-safe\n\nRead this version to the voice. Each beat is a plain paragraph break; names are respelled; "
            f"years are spelled out; no hyphens, capitals-for-emphasis or brackets.\n\n---\n\n{tt}\n\n{tb}")
        (out / f"{stem}_tts-safe.txt").write_text(f"{tt}\n\n{tb}")
        rows.append((nn, slug, section, gname, lat, lon, words))
    with open(batch / "coordinates.tsv", "w") as f:
        f.write("nn\tslug\tsection\tgoogle_maps_name\tlat\tlon\twords\n")
        for r in rows: f.write("\t".join(map(str, r)) + "\n")
    print(f"built {len(rows)} tours -> {out}")
    for r in rows: print(f"  {r[0]} {r[1]:38} {r[6]:4} words")

if __name__ == "__main__":
    main(sys.argv[1])
