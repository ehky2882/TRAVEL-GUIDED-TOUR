"""Remove every mention of FAI from the scripts (owner, 2026-11-24: the tours are not FAI's and must not read as promotion)."""
import json, glob, re, sys
R = {
"01": [("before Countess Elisabetta De Rege Provana gave it to the FAI in nineteen eighty-five.", "before Countess Elisabetta De Rege Provana gave it away in nineteen eighty-five, so that it could be restored and opened to the public.")],
"02": [("When the last of them sold it, in nineteen eighty-eight, the FAI had to find the money from a whole roll call of backers to keep it in one piece.", "When the last of them sold it, in nineteen eighty-eight, it took money from a whole roll call of backers to buy it and keep it in one piece.")],
"03": [("In twenty eleven they gave it to the FAI, with everything inside it,", "In twenty eleven they gave it away, with everything inside it, so that it could be opened to visitors,")],
"07": [("and in nineteen eighty-nine his heirs gave it to the FAI.", "and in nineteen eighty-nine his heirs gave it away, so that it could be opened to the public.")],
"08": [("He and his wife Giovanna gave the villa to the FAI in nineteen ninety-six, and they kept living on the top floor.", "He and his wife Giovanna gave the villa away in nineteen ninety-six, so that the public could see it, and they kept living on the top floor.")],
"09": [("The FAI decided to leave them there.", "They've been left exactly where they were."),
       ("In twenty fifteen she left it to the FAI, with its original furniture", "In twenty fifteen she left it, so that it could be opened to the public, with its original furniture")],
"10": [("It was rescued in the nineteen seventies by Giulia Maria Crespi, one of the founders of the FAI, who bought it and gave it to the foundation.", "It was rescued in the nineteen seventies by Giulia Maria Crespi, a Milanese campaigner for Italy's heritage, who bought it so that it could be saved and opened to the public.")],
"11": [("restored it and gave it to the FAI in two thousand and nine, so that nothing would change after he'd gone.", "restored it and, in two thousand and nine, gave it away so that nothing would change after he'd gone.")],
"12": [("Monzino died without heirs in nineteen eighty-eight, and left the villa to the FAI.", "Monzino died without heirs in nineteen eighty-eight, and left the villa so that it could be opened to the public.")],
"13": [("The family gave it to the FAI in twenty eleven.", "The family gave it away in twenty eleven, so that it could be seen by the public."),
       ("It's a lovely way to go from one FAI house to another, by land, past the boats.", "It's a lovely way to go from one house on the water to another, by land, past the boats.")],
"14": [("The FAI took on the palace in twenty nineteen, entrusted to it by the foundation that had cared for it.", "In twenty nineteen the foundation that had cared for the palace passed it on, so that it could be restored and opened to visitors.")],
"15": [("The castle was given to the FAI in nineteen ninety, restored, and opened in two thousand and one.", "The castle was given away in nineteen ninety, restored, and opened to the public in two thousand and one.")],
"22": [("It's a lie, and the FAI has kept it there on purpose.", "It's a lie, and it has been kept there on purpose."),
       ("The community was expelled from Trento, and the FAI notes that Jews did not return to live in the city until nineteen ninety-two.", "The community was expelled from Trento, and Jews did not return to live in the city until nineteen ninety-two."),
       ("In twenty eighteen the house was given to the FAI by Marina Larcher Fogazzaro. Rather than tidy the story away, the foundation turned the room into a place to tell it.", "In twenty eighteen the house was given away by Marina Larcher Fogazzaro, so that it could be opened to the public. Rather than tidy the story away, the room has been turned into a place to tell it.")],
"23": [("gave the castle to the FAI, and it opened to the public the following year.", "gave the castle away, and it opened to the public the following year.")],
"32": [("His family gave it to the FAI in two thousand and five.", "His family gave it away in two thousand and five, so that it could be opened to the public.")],
"42": [("were given to the FAI in twenty fifteen by Bruno and Liliana Collavo,", "were given away in twenty fifteen by Bruno and Liliana Collavo, to be looked after and opened to visitors,"),
       ("What the FAI is doing here is quietly ambitious.", "What's happening here is quietly ambitious."),
       ("Before you come, check what's open with the FAI, because the work is still going on.", "Before you come, check what's open, because the work is still going on.")],
"44": [("The house was given to the FAI in two thousand and one, and it opened to the public in twenty twenty-one.", "The house was given away in two thousand and one, so that it could be seen by the public, and it opened in twenty twenty-one.")],
"45": [("So the Genoa branch of the FAI organised a public appeal, the people of the city chipped in, and the foundation bought it from his heirs.", "So there was a public appeal, the people of the city chipped in, and the shop was bought from his heirs."),
       ("And then the FAI did something rather sensible. It didn't turn the shop into a museum.", "And then something rather sensible happened. Nobody turned the shop into a museum.")],
"46": [("In nineteen eighty-three Frank and Orietta Pogson Doria Pamphilj gave it to the FAI, which has restored it, spring and all.", "In nineteen eighty-three Frank and Orietta Pogson Doria Pamphilj gave it away, so that it could be restored, spring and all, and opened to the public.")],
"47": [("and in nineteen eighty-seven the house came to the FAI.", "and in nineteen eighty-seven the house was given away, so that it could be opened to the public."),
       ("In summer the FAI holds aperitifs in the garden,", "In summer there are aperitifs in the garden,")],
"48": [("She left it to the FAI.", "She left it so that it could be opened to the public.")],
"50": [("In nineteen ninety-seven the Biagini heirs gave it to the FAI and to the town,", "In nineteen ninety-seven the Biagini heirs gave it away, to be shared with the town,")],
"51": [("and in two thousand and five she left it to the FAI.", "and in two thousand and five she left it so that it could be opened to the public."),
       ("where the FAI projects a short film", "where a short film is projected")],
"54": [("In two thousand and eight the FAI bought them, with a gift from the bank Intesa Sanpaolo, and set about bringing them back.", "In two thousand and eight they were bought, with a gift from the bank Intesa Sanpaolo, and the work of bringing them back began.")],
"56": [("The FAI puts it beautifully: here infinity isn't a landscape outside you, it's a place inside you.", "Here, infinity isn't a landscape outside you. It's a place inside you."),
       ("The garden came to the FAI in twenty seventeen, entrusted by the town of Recanati and Leopardi's study centres, and it's been restored and opened to everyone.", "In twenty seventeen the town of Recanati and Leopardi's study centres handed the garden over to be restored, and it's now open to everyone.")],
"58": [("The FAI says it's the second highest waterfall in Italy after the Marmore.", "It's said to be the second highest waterfall in Italy, after the Marmore."),
       ("The FAI has looked after the park since two thousand and two.", "The park was restored and reopened in the early two thousands.")],
"60": [("it gave the whole bay to the FAI, in the late nineteen eighties, so it couldn't be built on.", "it gave the whole bay away, in the late nineteen eighties, so it couldn't be built on.")],
"62": [("The church holds a rare collection of Byzantine frescoes, and the FAI has restored them.", "The church holds a rare collection of Byzantine frescoes, now restored."),
       ("The Province of Lecce entrusted the abbey to the FAI in twenty twelve.", "In twenty twelve the Province of Lecce handed the abbey over to be restored and opened to visitors.")],
"66": [("and in twenty twenty-five the FAI recognised it, which should help pay for its restoration.", "and in twenty twenty-five it was recognised in a national vote for places worth saving, which should help pay for its restoration.")],
"67": [("This small house in the Sassi was the FAI's first property in Basilicata, and it doesn't so much show you Matera as tell it.", "This small house in the Sassi doesn't so much show you Matera as tell it."),
       ("In two thousand and four the Fodale and Latorre families gave it to the FAI, and the foundation decided not to fill it with furniture, but with a story.", "In two thousand and four the Fodale and Latorre families gave it away, so that it could be opened to the public, and the decision was made not to fill it with furniture, but with a story.")],
"69": [("Since twenty sixteen the FAI has cared for the wood on behalf of the Sila National Park, and the Mollo sisters gave the Casino to the FAI in memory of their brother.", "Since twenty sixteen the wood has been cared for on behalf of the Sila National Park, and the Mollo sisters gave the Casino away in memory of their brother."),
       ("so check with the FAI before you travel.", "so check before you travel.")],
"70": [("In nineteen ninety-nine the Region of Sicily entrusted it to the FAI, which restored the old irrigation channels and brought it back.", "In nineteen ninety-nine the Region of Sicily handed it over to be rescued, and the old irrigation channels were restored and the garden brought back.")],
"71": [("The garden was given to the FAI in two thousand and eight by the Donnafugata winery, whose vineyards surround it.", "The garden was given away in two thousand and eight by the Donnafugata winery, whose vineyards surround it, so that it could be opened to visitors.")],
"76": [("which the FAI has restored so you can picture", "which have been restored so you can picture"),
       ("In two thousand and two the Region of Sardinia entrusted it to the FAI, and the restoration is still going on.", "In two thousand and two the Region of Sardinia handed it over to be restored, and the work is still going on."),
       ("so get in touch with the FAI to arrange one.", "so arrange one before you come.")],
"77": [("which in twenty seventeen asked the FAI to open them up to visitors.", "which in twenty seventeen opened them up to visitors."),
       ("the FAI counts around thirty-five thousand water birds", "around thirty-five thousand water birds have been counted here,")],
}
bad = 0
for n, pairs in R.items():
    f = glob.glob(f"src/{n}_*.json")[0]; d = json.load(open(f))
    for a, b in pairs:
        if a not in d["clean"]: print("MISSING", n, a[:60]); bad += 1; continue
        d["clean"] = d["clean"].replace(a, b)
    d["respell"] = [r for r in d.get("respell", []) if r[0] != "FAI"]
    json.dump(d, open(f, "w"), ensure_ascii=False, indent=1)
for f in sorted(glob.glob("src/*.json")):
    d = json.load(open(f))
    for field in ("title", "clean"):
        if re.search(r"\bFAI\b|Fondo Ambiente", d[field]): print("STILL", f, field); bad += 1
sys.exit(1 if bad else 0)
