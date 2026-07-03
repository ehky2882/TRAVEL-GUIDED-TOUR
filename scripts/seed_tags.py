#!/usr/bin/env python3
"""
seed_tags.py — first-pass auto-assignment of the controlled Atlas tag vocabulary
(the "v2" faceted taxonomy) onto every tour in Resources/Tours.json.

OUTPUT IS A PROPOSAL FOR HUMAN REVIEW, not a final migration. Heuristics are
deliberately conservative (title + old primaryCategory + curated existing tags +
short/long descriptions). Place-type-from-title, Style, and Architect are fairly
reliable; Theme nuance, the `Notable Building` fall-through, and the editorial
Experience tags (`Iconic Landmark`, `Free to Visit`, `After Dark`) need eyeballing.

This is a REFRESH of the original 243-tour seeder for the current 509-tour /
9-maker catalog (adds Tokyo, Kyoto, Hong Kong, San Francisco, Toronto). New facet tags and
architects were added for those cities — see docs/tag-taxonomy-v2.md.

Run:    python3 scripts/seed_tags.py
Writes: docs/tag-migration-review.md   (per-tour proposal + coverage stats)
"""
import json, collections, os, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TJ = os.path.join(ROOT, "TRAVEL GUIDED TOUR", "Resources", "Tours.json")

MAKER_METRO = {
    '00000000-0000-0000-0000-000000000001': 'NYC',
    'f24fa1d2-4846-40fc-b9f9-8d61797a34f3': 'OPO',
    'B1A9EAF0-7B07-46A4-BDAE-F28D430A55FA': 'LIS',
    '9c40396a-74ed-49d2-9796-a41edb9e4105': 'LDN',
    'ae9eeb8a-9dc4-45ed-a39a-cdbb091e9382': 'HKG',
    'b7e4d2a1-9c3f-4e85-a6d2-1f0c8b5e3a70': 'SFO',
    'be5797bb-8d86-5b3f-99d4-09b2ffac65bd': 'TYO',
    '50b53af5-68ac-5e6e-8185-ae367326632d': 'KYO',
    'caa0cba1-9fc2-5993-b5cc-4f3380470bd1': 'YYZ',
}

# ---------------------------------------------------------------------------
# THE CONTROLLED VOCABULARY  (facet -> [tags])  — single source of truth.
# Mirror any edit here into docs/tag-taxonomy-v2.md and the validators.
# ---------------------------------------------------------------------------
VOCAB = {
 "Place type": ["Religious Building","Museum & Gallery","Park & Garden","Public Square",
   "Tower & Skyscraper","Bridge","Monument & Memorial","Market & Arcade","Theatre & Venue",
   "Library","Street & District","Civic & Government","Waterfront","Shop & Flagship","Notable Building"],
 "Theme": ["Architecture & Design","History","Art","Literature","Music & Performance",
   "Food & Drink","Faith & Spirituality","Power & Politics","Money & Trade",
   "Immigration & Community","Crime & Scandal","Death & Remembrance",
   "Engineering & Innovation","War & Conflict","Maritime","Fashion & Retail"],
 "Style & era": ["Medieval / Gothic","Baroque","Georgian / Neoclassical","Beaux-Arts",
   "Victorian","Art Deco","Modernist","Metabolist","Brutalist","Contemporary","Gilded Age",
   "Colonial","Mission / Spanish Revival"],
 "Experience": ["Iconic Landmark","Hidden Gem","Viewpoint & Panorama","Green Escape",
   "Free to Visit","After Dark","Public Art","Designed by a Master"],
 "Architect": ["Álvaro Siza","Eduardo Souto de Moura","Fernando Távora","Norman Foster",
   "Renzo Piano","Frank Gehry","Christopher Wren","Charles Holden","Denys Lasdun",
   "Inigo Jones","Giles Gilbert Scott","Herzog & de Meuron","Frank Lloyd Wright",
   "Cass Gilbert","McKim, Mead & White","Inês Lobo","Luís Pedro Silva",
   "Kengo Kuma","Kenzō Tange","Tadao Ando","SANAA","Toyo Ito","Fumihiko Maki",
   "Shigeru Ban","Sou Fujimoto","Kisho Kurokawa","I. M. Pei","Mies van der Rohe",
   "Le Corbusier","Philip Johnson","William Van Alen","Thomas Heatherwick",
   "Santiago Calatrava","Bernard Maybeck","Daniel Burnham","Zaha Hadid","Jean Nouvel"],
}

# old primaryCategory -> (lead theme, default place-type hint)
CAT_THEME = {"architecture":"Architecture & Design","history":"History","culturalHeritage":None,
 "sacredSites":"Faith & Spirituality","natureAndParks":None,"visualArt":"Art",
 "musicAndPerformance":"Music & Performance","literature":"Literature","foodAndDrink":"Food & Drink",
 "hiddenGems":None}
CAT_PLACE = {"sacredSites":"Religious Building","natureAndParks":"Park & Garden",
 "visualArt":"Museum & Gallery","musicAndPerformance":"Theatre & Venue","literature":"Library"}

# title keyword -> place type (precise; title only). Adds CJK/romaji cues for the new cities.
TITLE_PLACE = [
 (r"cathedral|church|chapel|synagogue|basilica|minster|abbey|priory|temple|shrine|mosque|monaster|jinja|-ji\b|taisha", "Religious Building"),
 (r"museum|gallery", "Museum & Gallery"),
 (r"library", "Library"),
 (r"\bpark\b|garden|cemeter|graveyard|fields|koen|gyoen", "Park & Garden"),
 (r"square|plaza|piazza|circus|crossing", "Public Square"),
 (r"bridge|ohashi", "Bridge"),
 (r"market|arcade|bazaar|yokocho", "Market & Arcade"),
 (r"theatre|theater|globe|stadium|arena|cinema|opera|rivoli|playhouse|concert|kabuki|hall\b", "Theatre & Venue"),
 (r"memorial|monument|cenotaph|obelisk|statue|liberty|cross bones|peace park", "Monument & Memorial"),
 (r"shard|skyscraper|gherkin|empire state|chrysler|flatiron|one world|woolworth|tower|skytree|mori|hills", "Tower & Skyscraper"),
 (r"flagship|prada|dior|boutique|department store|store\b|omotesando", "Shop & Flagship"),
 (r"\bhall\b|bank|exchange|guildhall|parliament|federal hall|customs|city hall|courthouse|senate|diet", "Civic & Government"),
 (r"street|lane|yard|dials|alley|dori|gai|mall\b|carnaby|soho|chinatown|broadway|hatton|district|quarter|row|ginza|shibuya|shinjuku", "Street & District"),
 (r"pier|beach|harbour|harbor|quay|dock|waterfront|terminal|piscina|wharf|island|bay|bund", "Waterfront"),
 (r"station|metro|house|building|works|headquarters|pavilion|hotel|factory|warehouse|silo|toilet|capsule|forum", "Notable Building"),
]

STYLE_KW = {"Medieval / Gothic":[r"\bgothic\b","medieval","romanesque","perpendicular"],"Baroque":["baroque","rococo"],
 "Georgian / Neoclassical":["georgian","neoclassic","palladian","pombaline","greek revival","federal style"],
 "Beaux-Arts":["beaux-arts","beaux arts"],"Victorian":["victorian"],"Art Deco":["art deco","art-deco"],
 "Modernist":["modernis","bauhaus","international style"],"Metabolist":["metabolis","nakagin","capsule tower"],
 "Brutalist":["brutalis"],"Gilded Age":["gilded age"],"Contemporary":["contemporary","pritzker","21st-century","21st century"],
 "Colonial":["colonial"],"Mission / Spanish Revival":["mission revival","spanish revival","spanish colonial","mission district"]}

THEME_KW = {"Money & Trade":[r"finance",r"wall street",r"\btrade",r"\bbank",r"exchange",r"diamond",r"commerce",r"merchant",r"wholesale",r"tycoon"],
 "Power & Politics":[r"royal",r"monarch",r"palace",r"parliament",r"government",r"crown",r"whitehall",r"political",r"city hall",r"mayor",r"diet building",r"imperial"],
 "Immigration & Community":[r"immigran",r"jewish",r"chinese",r"chinatown",r"huguenot",r"harlem",r"community",r"tenement",r"diaspora",r"settled here",r"japantown"],
 "Crime & Scandal":[r"heist",r"burglar",r"\bcrime",r"scandal",r"slum",r"rooker",r"red-light",r"prison",r"gallows",r"murder",r"thieves",r"yakuza"],
 "Death & Remembrance":[r"cemeter",r"graveyard",r"memorial",r"cenotaph",r"tomb",r"burial",r"outcast dead",r"martyr",r"buried",r"atomic"],
 "Engineering & Innovation":[r"engineer",r"\bdome",r"cantilever",r"power station",r"reinforced concrete",r"suspension",r"wobbl",r"structural",r"\bspan",r"feat of",r"earthquake"],
 "War & Conflict":[r"blitz",r"wartime",r"\bwar\b",r"\bbomb",r"churchill",r"battle",r"siege",r"fortress",r"blockade",r"world war"],
 "Maritime":[r"maritime",r"\bdock",r"harbour",r"harbor",r"\bport\b",r"\bship",r"naval",r"cruise",r"seafront",r"wharf",r"quay",r"fishing",r"sailors",r"junk boat"],
 "Food & Drink":[r"market",r"\bfood",r"cheese",r"\bwine",r"restaurant",r"oyster",r"brewery",r"coffee",r"culinary",r"foodie",r"ramen",r"izakaya",r"sushi",r"dim sum"],
 "Faith & Spirituality":[r"church",r"cathedral",r"chapel",r"sacred",r"monaster",r"worship",r"saint",r"synagogue",r"priory",r"shrine",r"temple",r"buddhis",r"shinto",r"zen"],
 "Literature":[r"writer",r"novel",r"poet",r"author",r"dickens",r"shakespeare",r"literary",r"manuscript",r"bookshop"],
 "Music & Performance":[r"music",r"concert",r"theatre",r"theater",r"opera",r"\bjazz",r"performance",r"\bband\b",r"\bstage",r"kabuki"],
 "Art":[r"\bart\b",r"gallery",r"galleries",r"sculpture",r"mural",r"painting",r"exhibition",r"artist",r"teamlab"],
 "Fashion & Retail":[r"flagship",r"boutique",r"fashion",r"luxury",r"department store",r"shopping",r"prada",r"dior",r"ginza"],
 "History":[r"histor",r"medieval",r"ancient",r"heritage",r"founded in",r"dating from",r"centuries",r"edo"],
 "Architecture & Design":[r"architect",r"architectur",r"facade",r"modernis",r"brutalis",r"baroque",r"gothic",r"art deco",r"designed by",r"design"]}

EXP_VIEW = ["viewpoint","panorama","skyline","observation","miradouro","vista","overlook","rooftop","peak"]
EXP_HIDDEN = ["hidden gem","tucked","overlooked","secret","unmarked","easy to miss","backstreet"]
EXP_GREEN = ["park","garden","green","tranquil","leafy","lawn"]
EXP_ART = ["public art","installation","mural","teamlab","tokyo toilet","sculpture park"]

ARCH_KW = {"Álvaro Siza":["siza"],"Eduardo Souto de Moura":["souto de moura"],"Fernando Távora":["távora","tavora"],
 "Norman Foster":["norman foster","hsbc"],"Renzo Piano":["renzo piano"],"Frank Gehry":["gehry"],
 "Christopher Wren":["christopher wren"],"Charles Holden":["charles holden"],"Denys Lasdun":["lasdun"],
 "Inigo Jones":["inigo jones"],"Giles Gilbert Scott":["giles gilbert scott","gilbert scott"],
 "Herzog & de Meuron":["herzog & de meuron","de meuron"],"Frank Lloyd Wright":["frank lloyd wright","lloyd wright"],
 "Cass Gilbert":["cass gilbert"],"McKim, Mead & White":["mckim","stanford white"],"Inês Lobo":["inês lobo","ines lobo"],
 "Luís Pedro Silva":["luís pedro silva","luis pedro silva"],
 "Kengo Kuma":["kengo kuma"],"Kenzō Tange":["kenzo tange","kenzō tange"],"Tadao Ando":["tadao ando"],
 "SANAA":["sanaa","kazuyo sejima"],"Toyo Ito":["toyo ito"],"Fumihiko Maki":["fumihiko maki"],
 "Shigeru Ban":["shigeru ban"],"Sou Fujimoto":["sou fujimoto"],"Kisho Kurokawa":["kurokawa"],
 "I. M. Pei":["i.m. pei","i. m. pei","ieoh ming pei"],"Mies van der Rohe":["mies van der rohe"],
 "Le Corbusier":["le corbusier"],"Philip Johnson":["philip johnson"],"William Van Alen":["van alen"],
 "Thomas Heatherwick":["heatherwick"],"Santiago Calatrava":["calatrava"],"Bernard Maybeck":["maybeck"],
 "Daniel Burnham":["burnham"],"Zaha Hadid":["zaha hadid"],"Jean Nouvel":["jean nouvel"]}


def text(t, longd=True):
    ks = ['title', 'shortDescription'] + (['longDescription'] if longd else [])
    return " ".join([str(t.get(k) or '') for k in ks] + (t.get('tags') or [])).lower()


def seed(t):
    title = (t.get('title') or '').lower()
    tt = text(t, False)      # precise sources (no long description)
    ta = text(t, True)       # full text for theme/architect depth
    cat = t.get('primaryCategory')
    out = {f: set() for f in VOCAB}

    # PLACE TYPE — title first; then old-category fallback; then a *specific*-only
    # scan of the short description (skips the broad Notable Building pattern, the
    # last TITLE_PLACE entry, so descriptions resolve to a real type instead of the
    # catch-all); then Notable Building as the final fallback.
    for pat, pt in TITLE_PLACE:
        if re.search(pat, title): out["Place type"].add(pt)
    if not out["Place type"] and cat in CAT_PLACE: out["Place type"].add(CAT_PLACE[cat])
    if not out["Place type"]:
        short = (t.get('shortDescription') or '').lower()
        for pat, pt in TITLE_PLACE[:-1]:      # specific patterns only, not Notable Building
            if re.search(pat, short): out["Place type"].add(pt)
    if not out["Place type"]: out["Place type"].add("Notable Building")

    # THEME — old-category lead + keyword scan
    lead = CAT_THEME.get(cat)
    if lead: out["Theme"].add(lead)
    for th, kws in THEME_KW.items():
        if any(re.search(k, ta) for k in kws): out["Theme"].add(th)
    if not out["Theme"]: out["Theme"].add("History")

    # STYLE & ERA
    for st, kws in STYLE_KW.items():
        if any(re.search(k, tt) or re.search(k, ta) for k in kws): out["Style & era"].add(st)

    # ARCHITECT
    for a, kws in ARCH_KW.items():
        if any(k in ta for k in kws): out["Architect"].add(a)

    # EXPERIENCE (editorial tags Iconic Landmark / Free to Visit / After Dark are NOT auto-set)
    if any(k in ta for k in EXP_VIEW): out["Experience"].add("Viewpoint & Panorama")
    if cat == 'hiddenGems' or any(k in ta for k in EXP_HIDDEN): out["Experience"].add("Hidden Gem")
    if "Park & Garden" in out["Place type"] or any(k in tt for k in EXP_GREEN): out["Experience"].add("Green Escape")
    if any(k in ta for k in EXP_ART): out["Experience"].add("Public Art")
    if out["Architect"]: out["Experience"].add("Designed by a Master")
    return out


def main():
    d = json.load(open(TJ)); T = d['tours']
    cov = collections.Counter(); by_metro = collections.defaultdict(collections.Counter); rows = []
    for t in T:
        s = seed(t)
        m = MAKER_METRO.get(t.get('makerId', ''), '?')
        for f in s:
            for tag in s[f]:
                cov[tag] += 1; by_metro[m][tag] += 1
        flags = []
        if len(s["Place type"]) > 2: flags.append("multi-placetype?")
        if s["Place type"] == {"Notable Building"}: flags.append("place=NotableBuilding-only?")
        rows.append((t, s, m, flags))

    out = []
    out.append("# Tag migration — auto-seed review (FIRST PASS, needs human correction)\n")
    out.append(f"_{len(T)} tours / 9 makers. Heuristic seed from title + old primaryCategory + curated "
               "existing tags + descriptions. Place-from-title, Style, and Architect are fairly reliable; "
               "Theme nuance, the `Notable Building` fall-through, and the editorial Experience tags "
               "(`Iconic Landmark`, `Free to Visit`, `After Dark`) are 0 by design and need human authoring._\n")
    out.append("## Coverage — tours per proposed tag\n")
    for facet, taglist in VOCAB.items():
        out.append(f"\n**{facet}**\n")
        for tag in taglist:
            out.append(f"- `{tag}` — {cov.get(tag, 0)}")
    # Per-city review pack — the owner skims one maker at a time (decision D10).
    # ⚠️ flags a tour that needs a human look: place resolved only to the
    # Notable Building catch-all, or an implausibly wide place-type guess.
    METRO_ORDER = ["NYC", "LDN", "LIS", "OPO", "HKG", "SFO", "TYO", "KYO", "YYZ", "?"]
    METRO_NAME = {"NYC": "New York", "LDN": "London", "LIS": "Lisbon", "OPO": "Porto",
                  "HKG": "Hong Kong", "SFO": "San Francisco", "TYO": "Tokyo",
                  "KYO": "Kyoto", "YYZ": "Toronto", "?": "Unknown maker"}
    out.append("\n\n## Per-tour proposals — grouped by city (skim one at a time)\n")
    out.append("Each city lists its flag count so you know where the review effort is. "
               "⚠️ = needs a human look (place resolved only to `Notable Building`, or an over-wide guess).\n")
    for m in METRO_ORDER:
        mrows = [(t, s, fl) for (t, s, mm, fl) in rows if mm == m]
        if not mrows:
            continue
        flagged = sum(1 for _, _, fl in mrows if fl)
        out.append(f"\n### {METRO_NAME[m]} ({m}) — {len(mrows)} tours · {flagged} flagged ⚠️\n")
        out.append("| Tour | Old category | Proposed tags |")
        out.append("|------|--------------|---------------|")
        for t, s, flags in sorted(mrows, key=lambda r: (bool(not r[2]), (r[0].get('title') or ''))):
            allt = []
            for f in VOCAB:
                allt += sorted(s[f])
            fl = (" ⚠️ " + ",".join(flags)) if flags else ""
            title = (t.get('title') or '').replace("|", "/")
            out.append(f"| {title} | {t.get('primaryCategory','')} | {', '.join(allt)}{fl} |")

    os.makedirs(os.path.join(ROOT, 'docs'), exist_ok=True)
    rp = os.path.join(ROOT, 'docs', 'tag-migration-review.md')
    open(rp, 'w').write("\n".join(out))
    print("tours:", len(T)); print("wrote", rp)
    for facet, taglist in VOCAB.items():
        print(f"\n[{facet}]")
        for tag in taglist: print(f"  {cov.get(tag,0):3}  {tag}")
    avg = sum(cov.values()) / len(T)
    print(f"\navg proposed tags/tour: {avg:.1f}")


if __name__ == "__main__":
    main()
