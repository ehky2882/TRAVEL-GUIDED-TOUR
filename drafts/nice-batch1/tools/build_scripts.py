#!/usr/bin/env python3
"""Build the Nice batch-1 scripts from scripts.src.txt.

For every tour it writes four files to scripts/:
  NN_<slug>_clean.txt / .md      the script as written, [beat] kept as an authoring marker
  NN_<slug>_tts-safe.txt / .md   for the TTS engine: phonetic respellings (lowercase, no
                                 hyphens), [beat] removed (the paragraph break is the pause),
                                 no markup, no digits, no all-caps words, title respelled

Usage: python3 -I tools/build_scripts.py   (run from drafts/nice-batch1)
"""
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent
SRC = HERE / "scripts.src.txt"
OUT = HERE / "scripts"

# Longest phrases first; applied with letter boundaries, case-sensitive.
RESPELL = [
    ("Musée d'Art Moderne et d'Art Contemporain", "the museum of modern and contemporary art"),
    ("Monument aux Morts de Rauba-Capèu", "Mon oo mon oh mor duh rowba kapeyoo"),
    ("Moulin à Huile d'Olive Alziari", "Moolan ah weel doleev al zee ah ree"),
    ("Cathédrale Orthodoxe Russe Saint-Nicolas", "Ka tay drahl or toe dox rooss san nee ko lah"),
    ("Musée National Marc Chagall", "Mew zay nah syo nal mark shah gal"),
    ("Musée des Arts Asiatiques", "Mew zay day zar ah zee ah teek"),
    ("Les Distilleries Idéales", "Lay dee stee luh ree ee day al"),
    ("Église Sainte-Jeanne-d'Arc", "Ay gleez sant zhan dark"),
    ("La Revue du Vin de France", "lah ruh vyoo doo van duh fronss"),
    ("Rue Saint-François-de-Paule", "roo san fron swah duh pole"),
    ("Avenue du Docteur Ménard", "avenue doo dok ter may nar"),
    ("Avenue Stephen Liégeard", "avenue stephen lee ay zhar"),
    ("Promenade des Anglais", "prom nahd day zong lay"),
    ("Promenade du Paillon", "prom nahd doo pie yon"),
    ("Palais Caïs de Pierlas", "pa lay kah eess duh pyair lah"),
    ("Place Charles-Félix", "plass sharl fay leeks"),
    ("Jean-François de La Pérouse", "zhon fron swah duh lah pay rooz"),
    ("Hôtel Le Negresco", "Oh tel luh neh gress ko"),
    ("Hôtel du Couvent", "Oh tel doo koo von"),
    ("Hôtel La Pérouse", "Oh tel lah pay rooz"),
    ("Hôtel Windsor", "Oh tel windsor"),
    ("Colline du Château", "koleen doo shah toe"),
    ("Quai Rauba Capèu", "kay rowba kapeyoo"),
    ("Rauba-Capèu", "rowba kapeyoo"),
    ("Rauba capèu", "Rowba kapeyoo"),
    ("rauba capèu", "rowba kapeyoo"),
    ("Baie des Anges", "bay day zonj"),
    ("Part des Anges", "par day zonj"),
    ("Musée Masséna", "mew zay mah say nah"),
    ("Musée Matisse", "mew zay mah teess"),
    ("Villa Masséna", "veela mah say nah"),
    ("Cours Saleya", "koor sah lay ah"),
    ("Café du Cycliste", "kaffay doo see kleest"),
    ("Café de Turin", "kaffay duh too ran"),
    ("Chez Acchiardo", "Shay ah kyar doh"),
    ("Chez Pipo", "Shay pee po"),
    ("La Merenda", "lah meh ren dah"),
    ("Le Plongeoir", "luh plon zhwar"),
    ("Confiserie Florian", "kon fee zuh ree flo ree on"),
    ("Maison Auer", "mayzon ow er"),
    ("Palais Lascaris", "pa lay lass kah reess"),
    ("Tête Carrée", "tet ka ray"),
    ("Place Garibaldi", "plass garibaldi"),
    ("Place Yves Klein", "plass eve klyne"),
    ("Place Saint-François", "plass san fron swah"),
    ("Place Royale", "plass rwah yal"),
    ("Place Victor-Emmanuel", "plass victor emmanuel"),
    ("Place Napoléon", "plass napoleon"),
    ("Quai des Docks", "kay day docks"),
    ("Quai Papacino", "kay pah pah chee no"),
    ("Rue de la Préfecture", "roo duh lah pray fek toor"),
    ("Rue de l'Opéra", "roo duh lopay rah"),
    ("Rue Raoul Bosio", "roo rah ool bo zee oh"),
    ("Rue Honoré Ugo", "roo onoray oo go"),
    ("Rue Dalpozzo", "roo dal pot so"),
    ("Rue Gubernatis", "roo goo bair nah tees"),
    ("Rue Bavastro", "roo bah vas tro"),
    ("Rue Robilant", "roo ro bee lon"),
    ("Rue Droite", "roo drwat"),
    ("Avenue Saint-Lambert", "avenue san lom bair"),
    ("Avenue Nicolas the Second", "avenue nicholas the second"),
    ("Parc Phoenix", "park phoenix"),
    ("Gorges du Loup", "gorzh doo loo"),
    ("Studio Méditerranée", "studio may dee teh rah nay"),
    ("Saint-Barthélemy", "san bar tay luh mee"),
    ("Édouard-Jean Niermans", "ay dwar zhon near mahns"),
    ("Alexandru Negrescu", "alek zan droo neh gress koo"),
    ("Henri-Chrétien", "on ree kray tyan"),
    ("Henri Negresco", "on ree neh gress ko"),
    ("Henri Auer", "on ree ow er"),
    ("Henri Fisch", "on ree fish"),
    ("Henri Vidal", "on ree vee dal"),
    ("Yves Bayard", "eve bye ar"),
    ("Yves Klein", "eve klyne"),
    ("Klein's", "klyne's"),
    ("Klein", "klyne"),
    ("Valéry Grégo", "valeh ree gray go"),
    ("Bernard Redolfi", "bernard reh dol fee"),
    ("Redolfi", "reh dol fee"),
    ("Joël Ducoroy", "zho el doo kor wah"),
    ("Pierrick Sorin", "pyeh reek so ran"),
    ("Mauro Benetti", "mow ro ben etty"),
    ("La Luna", "lah loona"),
    ("Bar barrit", "bar bah ree"),
    ("Nicolas Rubinstein", "nee ko lah rubinstein"),
    ("Dominique Le Stanc", "dom ee neek luh stonk"),
    ("Le Stanc", "luh stonk"),
    ("Val Maira", "val my rah"),
    ("René Livieri", "ruh nay lee vyeh ree"),
    ("Olivier Labarde", "olivee ay lah bard"),
    ("César Martin", "say zar mar tan"),
    ("Nicolas Alziari", "nee ko lah al zee ah ree"),
    ("Alziari", "al zee ah ree"),
    ("André Malraux", "on dray mal roe"),
    ("André Hermant", "on dray air mon"),
    ("André Masséna", "on dray mah say nah"),
    ("Victor Masséna", "victor mah say nah"),
    ("Charles Marcq", "sharl mark"),
    ("Jean-Baptiste Gubernatis", "zhon bap teest goo bair nah tees"),
    ("Jean-François Bodin", "zhon fron swah bo dan"),
    ("Michel Marot", "mee shell mah roe"),
    ("Michel Péna", "mee shell pay nah"),
    ("Jacques Droz", "zhak droh"),
    ("Eugène Klementieff", "oo zhen klem en tee eff"),
    ("Mikhail Preobrazhensky", "mee kah eel pray oh bra zhen skee"),
    ("Preobrazhensky", "pray oh bra zhen skee"),
    ("Nicholas Alexandrovich", "nicholas alek san dro vich"),
    ("Lascaris-Vintimille", "lass kah reess van tee meel"),
    ("Roger Séassal", "ro zhay say ah sal"),
    ("Séassal", "say ah sal"),
    ("Alfred Janniot", "alfred zhan yo"),
    ("Marshal Foch", "marshal fosh"),
    ("Sacha Sosno", "sasha soz no"),
    ("Sosno", "soz no"),
    ("Francis Chapus", "fron seess sha poo"),
    ("Louis Nucéra", "loo ee noo say rah"),
    ("Antoine Spinelli", "on twan spinelli"),
    ("Hans-Georg Tersling", "hans gay org tersling"),
    ("Louis the Fourteenth", "louis the fourteenth"),
    ("Jeanne Augier", "zhan oh zhyay"),
    ("Augier", "oh zhyay"),
    ("Touët-sur-Var", "too et soor var"),
    ("Tourrettes", "too ret"),
    ("Cemenelum", "seh meh neh lum"),
    ("Cimiez", "see myay"),
    ("Vésubie", "vay zoo bee"),
    ("Madeleine", "mad lenn"),
    ("Mont Boron", "mon bo ron"),
    ("Col d'Èze", "kol dez"),
    ("Côte d'Azur", "coat dah zoor"),
    ("Belle Époque", "bel ay pock"),
    ("trompe-l'oeil", "tromp loy"),
    ("Cuisine Nissarde", "kwee zeen nee sard"),
    ("Niçoises", "nee swahz"),
    ("Niçoise", "nee swahz"),
    ("niçoise", "nee swahz"),
    ("Niçois", "nee swah"),
    ("pissaladière", "pee sah lah dyair"),
    ("Cailletier", "kai uh tyay"),
    ("Provençal", "pro von sal"),
    ("Visitation", "visitation"),
    ("confiserie", "kon fee zuh ree"),
    ("Florentine", "florentine"),
    ("Florian", "flo ree on"),
    ("Baccarat", "bah kah rah"),
    ("Chagall's", "shah gal's"),
    ("Chagall", "shah gal"),
    ("Matisse", "mah teess"),
    ("Negresco", "neh gress ko"),
    ("Niermans", "near mahns"),
    ("Masséna", "mah say nah"),
    ("Lascaris", "lass kah reess"),
    ("Acchiardo", "ah kyar doh"),
    ("Pipo", "pee po"),
    ("Peixes", "pay shesh"),
    ("Pérouse", "pay rooz"),
    ("Couvent", "koo von"),
    ("Grégo", "gray go"),
    ("Auer", "ow er"),
    ("Gubernatis", "goo bair nah tees"),
    ("Bellet", "bel lay"),
    ("Paillon", "pie yon"),
    ("Ponchettes", "pon shet"),
    ("Pénitents", "penitents"),
    ("MAMAC", "mah mak"),
    ("Tange's", "tang ay's"),
    ("Tange", "tang ay"),
    ("Kenzo", "ken zo"),
    ("tiradito", "teera deeto"),
    ("ceviche", "seh vee chay"),
    ("oursins", "oor san"),
    ("pointus", "pwan too"),
    ("daube", "dohb"),
    ("Daube", "Dohb"),
    ("pistou", "pee stoo"),
    ("socca", "sokka"),
    ("tapenade", "ta puh nahd"),
    ("gnocchi", "nyokki"),
    ("Gnocchi", "Nyokki"),
    ("Arènes", "ah renn"),
    ("Prix de Rome", "pree duh rom"),
    ("Paris to Nice", "Paris to Neece"),
    ("Salon Royal", "sah lon rwah yal"),
    ("Opéra", "opera"),
    ("Cimiez", "see myay"),
    ("Cycliste", "see kleest"),
    ("Studio Mumbai", "studio mumbai"),
    ("Ben,", "Ben,"),
    ("Médecin", "mayd san"),
    ("Caïs", "kah eess"),
    ("Bosio", "bo zee oh"),
    ("apéritif", "a peri teef"),
    ("café", "kaffay"),
    ("Café", "Kaffay"),
    ("décor", "day kor"),
    ("Époque", "ay pock"),
    ("Èze", "ez"),
    ("Nice", "Neece"),
]

def respell(text: str) -> str:
    for src, dst in RESPELL:
        text = re.sub(r"(?<![A-Za-zÀ-ÿ])" + re.escape(src) + r"(?![A-Za-zÀ-ÿ])", dst, text)
    return text

def tts_safe(title_tts: str, body: str) -> str:
    paras = [p.strip() for p in body.split("\n\n")]
    paras = [p for p in paras if p and p != "[beat]"]
    out = respell("\n\n".join(paras))
    out = out.replace("—", ", ").replace("–", ", ")
    out = re.sub(r"(?<=\w)-(?=\w)", " ", out)       # no hyphens
    out = out.replace("-", " ")
    out = re.sub(r"[\[\]{}<>*_#`]", "", out)        # no markup / brackets
    out = re.sub(r" {2,}", " ", out)
    return title_tts + "\n\n" + out.strip() + "\n"

def check_tts(name: str, text: str) -> list:
    errs = []
    if re.search(r"\d", text):
        errs.append("digit")
    if "-" in text:
        errs.append("hyphen")
    caps = [w for w in re.findall(r"\b[A-Z]{2,}\b", text)]
    if caps:
        errs.append("all-caps: " + ",".join(sorted(set(caps))))
    if re.search(r"[\[\]<>]", text):
        errs.append("bracket")
    accented = sorted(set(re.findall(r"\S*[À-ÿ]\S*", text)))
    if accented:
        errs.append("accented words left: " + " ".join(accented))
    return [f"{name}: {e}" for e in errs]

def main() -> int:
    raw = SRC.read_text(encoding="utf-8")
    blocks = re.split(r"^=== ", raw, flags=re.M)[1:]
    OUT.mkdir(exist_ok=True)
    problems, rows = [], []
    for b in blocks:
        head, body = b.split("\n", 1)
        num, slug, title, title_tts = [x.strip() for x in head.split("|")]
        body = body.strip()
        if re.search(r"\d", body):
            problems.append(f"{num} clean: digit in body")
        stem = f"{num}_{slug}"
        clean = f"{title}\n\n{body}\n"
        (OUT / f"{stem}_clean.txt").write_text(clean, encoding="utf-8")
        (OUT / f"{stem}_clean.md").write_text(f"# {title}\n\n{body}\n", encoding="utf-8")
        tts = tts_safe(title_tts, body)
        problems += check_tts(stem, tts)
        (OUT / f"{stem}_tts-safe.txt").write_text(tts, encoding="utf-8")
        t_title, t_body = tts.split("\n\n", 1)
        (OUT / f"{stem}_tts-safe.md").write_text(f"# {t_title}\n\n{t_body}", encoding="utf-8")
        words = len(body.replace("[beat]", "").split())
        rows.append((num, title, words, round(words / 150 * 60)))
    for r in rows:
        print(f"{r[0]}  {r[2]:4d} words  ~{r[3]//60}:{r[3]%60:02d}  {r[1]}")
    for p in problems:
        print("PROBLEM", p)
    print(f"{len(rows)} tours, {len(problems)} problems")
    return 1 if problems else 0

if __name__ == "__main__":
    sys.exit(main())
