#!/usr/bin/env python3
"""
seed_tags.py — first-pass auto-assignment of the controlled Atlas tag vocabulary
onto every tour in Resources/Tours.json. OUTPUT IS A PROPOSAL FOR HUMAN REVIEW,
not a final migration. Heuristics are deliberately conservative (title + category +
existing curated tags + shortDescription) — themes and edge cases need eyeballing.

Run:  python3 scripts/seed_tags.py
Writes: docs/tag-migration-review.md  (per-tour proposal + coverage stats)
"""
import json, collections, os, re

ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TJ=os.path.join(ROOT,"TRAVEL GUIDED TOUR","Resources","Tours.json")

# ---------------------------------------------------------------------------
# THE CONTROLLED VOCABULARY  (facet -> [tags])  — single source of truth
# ---------------------------------------------------------------------------
VOCAB = {
 "Place type": ["Religious Building","Museum & Gallery","Park & Garden","Public Square",
   "Tower & Skyscraper","Bridge","Monument & Memorial","Market & Arcade","Theatre & Venue",
   "Library","Street & District","Civic & Government","Waterfront","Notable Building"],
 "Theme": ["Architecture & Design","History","Art","Literature","Music & Performance",
   "Food & Drink","Faith & Spirituality","Power & Politics","Money & Trade",
   "Immigration & Community","Crime & Scandal","Death & Remembrance",
   "Engineering & Innovation","War & Conflict","Maritime"],
 "Style & era": ["Medieval / Gothic","Baroque","Georgian / Neoclassical","Beaux-Arts",
   "Victorian","Art Deco","Modernist","Brutalist","Contemporary","Gilded Age"],
 "Experience": ["Iconic Landmark","Hidden Gem","Viewpoint & Panorama","Green Escape",
   "Free to Visit","After Dark","Designed by a Master"],
 "Architect": ["Álvaro Siza","Eduardo Souto de Moura","Fernando Távora","Norman Foster",
   "Renzo Piano","Frank Gehry","Christopher Wren","Charles Holden","Denys Lasdun",
   "Inigo Jones","Giles Gilbert Scott","Herzog & de Meuron","Frank Lloyd Wright",
   "Cass Gilbert","McKim, Mead & White","Inês Lobo","Luís Pedro Silva"],
}

# category -> (theme tag, default place-type hint)
CAT_THEME={"architecture":"Architecture & Design","history":"History","culturalHeritage":None,
 "sacredSites":"Faith & Spirituality","natureAndParks":None,"visualArt":"Art",
 "musicAndPerformance":"Music & Performance","literature":"Literature","foodAndDrink":"Food & Drink",
 "hiddenGems":None}
CAT_PLACE={"sacredSites":"Religious Building","natureAndParks":"Park & Garden",
 "visualArt":"Museum & Gallery","musicAndPerformance":"Theatre & Venue","literature":"Library"}

# title keyword -> place type (precise; title only)
TITLE_PLACE=[
 (r"cathedral|church|chapel|synagogue|basilica|minster|abbey|priory|temple|mosque|monaster", "Religious Building"),
 (r"museum|gallery", "Museum & Gallery"),
 (r"library", "Library"),
 (r"\bpark\b|garden|cemeter|graveyard|fields", "Park & Garden"),
 (r"square|plaza|piazza|circus", "Public Square"),
 (r"bridge", "Bridge"),
 (r"market|arcade|bazaar", "Market & Arcade"),
 (r"theatre|theater|globe|stadium|arena|cinema|opera|rivoli|playhouse|concert", "Theatre & Venue"),
 (r"memorial|monument|cenotaph|obelisk|statue|liberty|cross bones", "Monument & Memorial"),
 (r"shard|skyscraper|gherkin|empire state|chrysler|flatiron|one world|woolworth|tower", "Tower & Skyscraper"),
 (r"\bhall\b|bank|exchange|guildhall|parliament|federal hall|customs|city hall|courthouse|senate house", "Civic & Government"),
 (r"street|lane|yard|dials|alley|garden$|mall\b|carnaby|soho|chinatown|broadway|arcade|hatton|district|quarter|row", "Street & District"),
 (r"pier|beach|harbour|harbor|quay|dock|waterfront|terminal|piscina|wharf|island", "Waterfront"),
 (r"station|metro|library|house|building|works|headquarters|pavilion|hotel|factory|warehouse|silo", "Notable Building"),
]

# style/era from tags + shortDescription (lowercased)
STYLE_KW={"Medieval / Gothic":[r"\bgothic\b","medieval","romanesque","perpendicular"],"Baroque":["baroque","rococo"],
 "Georgian / Neoclassical":["georgian","neoclassic","palladian","pombaline","greek revival","federal style"],
 "Beaux-Arts":["beaux-arts","beaux arts"],"Victorian":["victorian"],"Art Deco":["art deco","art-deco"],
 "Modernist":["modernis","bauhaus","international style"],"Brutalist":["brutalis"],
 "Gilded Age":["gilded age"],"Contemporary":["contemporary","pritzker"]}

# theme keywords (tags + shortDescription)
THEME_KW={"Money & Trade":[r"finance",r"wall street",r"trade",r"bank",r"exchange",r"diamond",r"commerce",r"gilded age",r"stock exchange",r"merchant",r"wholesale"],
 "Power & Politics":[r"royal",r"monarch",r"palace",r"parliament",r"government",r"crown",r"whitehall",r"king",r"queen",r"political",r"city hall",r"mayor",r"diplomat",r"state "],
 "Immigration & Community":[r"immigran",r"jewish",r"chinese",r"chinatown",r"huguenot",r"harlem",r"community",r"tenement",r"diaspora",r"settled here"],
 "Crime & Scandal":[r"heist",r"burglar",r"crime",r"scandal",r"slum",r"rooker",r"red-light",r"prison",r"gallows",r"murder",r"thieves"],
 "Death & Remembrance":[r"cemeter",r"graveyard",r"memorial",r"cenotaph",r"tomb",r"burial",r"outcast dead",r"martyr",r"buried"],
 "Engineering & Innovation":[r"engineer",r"dome",r"cantilever",r"power station",r"reinforced concrete",r"suspension",r"wobbl",r"structural",r"span",r"feat of"],
 "War & Conflict":[r"blitz",r"wartime",r"war",r"bomb",r"churchill",r"battle",r"siege",r"fortress",r"blockade",r"second world war",r"first world war"],
 "Maritime":[r"maritime",r"dock",r"harbour",r"harbor",r"port",r"ship",r"naval",r"cruise",r"seafront",r"wharf",r"quay",r"fishing",r"sailors"],
 "Food & Drink":[r"market",r"food",r"cheese",r"wine",r"port wine",r"restaurant",r"oyster",r"brewery",r"coffee",r"culinary",r"foodie"],
 "Faith & Spirituality":[r"church",r"cathedral",r"chapel",r"sacred",r"monaster",r"worship",r"saint",r"synagogue",r"priory",r"congregation"],
 "Literature":[r"writer",r"novel",r"poet",r"author",r"dickens",r"shakespeare",r"literary",r"manuscript",r"bookshop"],
 "Music & Performance":[r"music",r"concert",r"theatre",r"theater",r"opera",r"jazz",r"performance",r"band",r"stage",r"recording studio"],
 "Art":[r"art",r"gallery",r"galleries",r"sculpture",r"mural",r"painting",r"exhibition",r"artist"],
 "History":[r"histor",r"medieval",r"ancient",r"heritage",r"founded in",r"dating from",r"centuries"],
 "Architecture & Design":[r"architect",r"architectur",r"facade",r"modernis",r"brutalis",r"baroque",r"gothic",r"art deco",r"designed by"]}

# experience
EXP_VIEW=["viewpoint","panorama","skyline","observation","miradouro","vista","overlook","rooftop"]
EXP_HIDDEN=["hidden gem","hidden","tucked","overlooked","secret","unmarked","easy to miss","backstreet"]
EXP_GREEN=["park","garden","green","tranquil","leafy","lawn"]

ARCH_KW={"Álvaro Siza":["siza"],"Eduardo Souto de Moura":["souto de moura"],"Fernando Távora":["távora","tavora"],
 "Norman Foster":["norman foster"],"Renzo Piano":["renzo piano"],"Frank Gehry":["gehry"],
 "Christopher Wren":["christopher wren"],"Charles Holden":["charles holden"],"Denys Lasdun":["lasdun"],
 "Inigo Jones":["inigo jones"],"Giles Gilbert Scott":["giles gilbert scott","gilbert scott"],
 "Herzog & de Meuron":["herzog & de meuron","herzog and de meuron","de meuron"],
 "Frank Lloyd Wright":["frank lloyd wright","lloyd wright"],"Cass Gilbert":["cass gilbert"],
 "McKim, Mead & White":["mckim","stanford white"],"Inês Lobo":["inês lobo","ines lobo"],
 "Luís Pedro Silva":["luís pedro silva","luis pedro silva"]}

def seed(t):
    title=(t.get('title') or '').lower()
    short=(t.get('shortDescription') or '').lower()
    longd=(t.get('longDescription') or '').lower()
    tags=" ".join(t.get('tags') or []).lower()
    cat=t['primaryCategory']
    txt_ts=title+" "+short+" "+tags          # precise sources (no transcript)
    txt_all=txt_ts+" "+longd                  # for architect/theme depth
    out={f:set() for f in VOCAB}

    # PLACE TYPE — title first, then category fallback
    for pat,pt in TITLE_PLACE:
        if re.search(pat,title): out["Place type"].add(pt)
    if not out["Place type"] and cat in CAT_PLACE: out["Place type"].add(CAT_PLACE[cat])
    if not out["Place type"]: out["Place type"].add("Notable Building")

    # THEME — category lead + keyword scan
    lead=CAT_THEME.get(cat)
    if lead: out["Theme"].add(lead)
    for th,kws in THEME_KW.items():
        if any(re.search(k,txt_all) for k in kws): out["Theme"].add(th)
    if not out["Theme"]: out["Theme"].add("History")

    # STYLE & ERA
    for st,kws in STYLE_KW.items():
        if any(re.search(k,txt_ts) or re.search(k,longd) for k in kws): out["Style & era"].add(st)

    # ARCHITECT
    for a,kws in ARCH_KW.items():
        if any(k in txt_all for k in kws): out["Architect"].add(a)

    # EXPERIENCE
    if any(k in txt_all for k in EXP_VIEW): out["Experience"].add("Viewpoint & Panorama")
    if cat=='hiddenGems' or any(k in txt_all for k in EXP_HIDDEN): out["Experience"].add("Hidden Gem")
    if "Park & Garden" in out["Place type"] or any(k in txt_ts for k in EXP_GREEN): out["Experience"].add("Green Escape")
    if any(k in txt_all for k in ["free","no ticket","free to","free of charge"]): out["Experience"].add("Free to Visit")
    if any(k in txt_all for k in ["nightlife","after dark","red-light","bars","clubs","by night"]): out["Experience"].add("After Dark")
    if out["Architect"]: out["Experience"].add("Designed by a Master")
    return out

def main():
    d=json.load(open(TJ)); T=d['tours']
    mk={m['id']:m['displayName'] for m in d['makers']}
    cov=collections.Counter(); rows=[]
    for t in T:
        s=seed(t)
        for f in s:
            for tag in s[f]: cov[tag]+=1
        flags=[]
        if len(s["Place type"])>2: flags.append("multi-placetype?")
        if not any(s.values()): flags.append("EMPTY")
        rows.append((t,s,flags))
    # write review
    out=[]
    out.append("# Tag migration — auto-seed review (FIRST PASS, needs human correction)\n")
    out.append(f"_{len(T)} tours. Heuristic seed from title + category + curated tags + descriptions. "
               "Style/Architect/Place-from-title are fairly reliable; Theme nuance and the long tail need eyeballing._\n")
    out.append("## Coverage — tours per proposed tag\n")
    for facet,taglist in VOCAB.items():
        out.append(f"\n**{facet}**\n")
        for tag in taglist:
            out.append(f"- `{tag}` — {cov.get(tag,0)}")
    out.append("\n\n## Per-tour proposals\n")
    out.append("| # | Tour | City | Old category | Proposed tags |")
    out.append("|---|------|------|--------------|---------------|")
    for i,(t,s,flags) in enumerate(rows,1):
        allt=[]
        for f in VOCAB:
            allt+=sorted(s[f])
        fl=(" ⚠️ "+",".join(flags)) if flags else ""
        out.append(f"| {i} | {t['title']} | {t.get('city','')} | {t['primaryCategory']} | "
                   f"{', '.join(allt)}{fl} |")
    os.makedirs(os.path.join(ROOT,'docs'),exist_ok=True)
    rp=os.path.join(ROOT,'docs','tag-migration-review.md')
    open(rp,'w').write("\n".join(out))
    print("tours:",len(T))
    print("wrote",rp)
    print("\n=== coverage (tours per tag) ===")
    for facet,taglist in VOCAB.items():
        print(f"\n[{facet}]")
        for tag in taglist: print(f"  {cov.get(tag,0):3}  {tag}")
    avg=sum(cov.values())/len(T)
    print(f"\navg proposed tags/tour: {avg:.1f}")

if __name__=="__main__": main()
