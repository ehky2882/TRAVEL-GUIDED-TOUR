import json, pathlib
S = pathlib.Path("src"); T = {}
FAI=["FAI","fy"]

T["44_casa-e-collezione-laura"] = dict(title="Casa e Collezione Laura",
clean="""This house used to be a church. Then an antique dealer and his wife moved in with six thousand works of art.

You're on Via Cavour in Ospedaletti, on the Riviera di Ponente, between Sanremo and Bordighera, with the bright light of the sea all around. The building in front of you is Villa San Luca, and if its shape reminds you of a church, that's because it was one.

It was built as an Anglican church, and it was badly damaged in the Second World War. From nineteen fifty-three, Luigi Anton Laura, an antique dealer with an international name, and his wife Renata Salesi, known to everyone as Nera, turned it into their home.

What they filled it with is the point. Around six thousand pieces, gathered over more than fifty years of buying and selling. Two great worlds sit side by side: the decorative art of eighteenth-century Europe, with Italian, French and English furniture, silver and maiolica, and the art of East Asia and the Middle East, with Chinese porcelain and oriental antiquities.

[beat]

Here's what I find rather lovely about it. Most dealers spend their lives letting beautiful things go. This one kept the ones he couldn't bear to part with, and put them in a former church, where they could be looked at with something like devotion.

The house was given to the FAI in two thousand and one, and it opened to the public in twenty twenty-one. Visits are by guided tour only, and the house closes for a winter break from early November, so book ahead.

On the tour, ask the guide to show you where East meets West, the rooms where Chinese porcelain stands next to French furniture. It's the whole collection, and the whole couple, in a single glance.""",
respell=[["Ospedaletti","os peh da let tee"],["Riviera di Ponente","riv ee air ah dee po nen teh"],["Sanremo","san reh mo"],["Bordighera","bor dee gheh ra"],["Villa San Luca","villa san loo ka"],["Luigi Anton Laura","loo ee jee an ton low ra"],["Renata Salesi","reh nah ta sa leh zee"],["Nera","neh ra"],["maiolica","my ol ee ka"],["Via Cavour","vee ah ka voor"],FAI],
sources=["https://fondoambiente.it/luoghi/casa-e-collezione-laura","https://fondoambiente.it/casa-e-collezione-laura-eng/","https://fondoambiente.it/luoghi/beni-fai"],
notes=["The ex-Anglican church, damaged in WWII and converted from 1953, is from the FAI Italian page.","No garden is described in the sources, so none is mentioned.","The donor isn't named, so the script says only 'given to the FAI in 2001'.","Guided tours only; winter closure from 2 November."])

T["45_antica-barberia-giacalone"] = dict(title="Antica Barberia Giacalone, Genoa",
clean="""Ten square metres, coloured glass on every surface, and you can still get a shave.

You're on Vicolo dei Caprettari, one of the narrow caruggi of old Genoa. Look for the small shop window glittering in the alley. That's the barber's.

A barber called Giacalone opened it in eighteen eighty-two. In nineteen twenty-two his son Italo decided to redo the whole interior, and what he made is the shop you see now. The walls and the ceiling are covered with coloured glass and oval mirrors. There are Liberty lamps, and at the back the plain white tiles every proper barber's shop has. It's the size of a small bedroom, about ten square metres, and every one of them is decorated.

The Giacalone family kept it until nineteen ninety-two. When Italo died, the shop was at real risk of being lost. So the Genoa branch of the FAI organised a public appeal, the people of the city chipped in, and the foundation bought it from his heirs.

[beat]

And then the FAI did something rather sensible. It didn't turn the shop into a museum. It restored it and kept it working, so it's still a barber's, still cutting the hair of Genoese regulars and curious visitors, still doing the job it was built for in eighteen eighty-two.

I think that's the best kind of conservation. Not a room behind a rope, but a room that's still being used for the thing it's good at.

If you've got a quarter of an hour and a chin that needs attention, go in and ask for a shave. If not, stand at the window for a minute and watch the light bounce round that glass. It's one of the smallest treasures in the city, and one of the most cheerful.""",
respell=[["Barberia Giacalone","bar beh ree ah jah ka lo neh"],["Giacalone","jah ka lo neh"],["Vicolo dei Caprettari","vee ko lo day kap ret tah ree"],["caruggi","ka roo jee"],["Genoa","jen oh ah"],["Genoese","jen oh eez"],["Italo","ee ta lo"],FAI],
sources=["https://fondoambiente.it/luoghi/antica-barberia-giacalone","https://fondoambiente.it/the-old-giacalone-barber-shop-eng","https://fondoambiente.it/news/nuova-luce-per-l-antica-barberia-giacalone","https://fondoambiente.it/luoghi/beni-fai"],
notes=["The founder's first name isn't given.","Art Déco (1922) and Liberty lamps are both FAI's terms.","Bought by FAI from the heirs in 1992 via a public subscription promoted by the FAI Genoa delegation.","Still working: the English page gives Tuesday to Saturday, 10:00–18:30. 'Ask for a shave' assumes shaves are offered; check it.","No chairs or carved wood are mentioned in the sources, so they are omitted."])

T["46_abbazia-di-san-fruttuoso"] = dict(title="Abbazia di San Fruttuoso",
clean="""There's no road to this abbey. You arrive by boat, or on foot over the mountain, which is exactly why it's here.

From the little beach, look up at the abbey. It sits right at the back of a tiny bay, between the green slopes of the Portofino headland and the water, with its domed tower above the arches. High on the rocks above the bay is a square stone watchtower.

The story goes that in the seven hundreds a bishop called Prosper of Tarragona fled the Arab invasion of Spain with the relics of Saint Fructuosus, a martyr of his city. By tradition, the saint himself showed Prosper this bay in a dream. Whatever the truth, the place made sense. It was hidden, and it had a spring of fresh water.

The abbey you see was rebuilt in the tenth century as a Benedictine monastery. Go into the cloister and look for the tombs of the Doria, the great family of Genoa. Seven members of the family who died between twelve seventy-five and thirteen oh five are buried here, in white marble and grey stone.

Then that tower. The Doria built it in fifteen sixty-two to protect the village and its spring from Barbary pirates, and armed it with three bronze cannon.

[beat]

So it's an abbey that ran out of monks but never quite stopped being a refuge. In nineteen eighty-three Frank and Orietta Pogson Doria Pamphilj gave it to the FAI, which has restored it, spring and all.

Before you leave, look out at the bay. Since nineteen fifty-four, a bronze statue of Christ has stood on the seabed out there. You won't see it from the beach, but on a calm day divers and snorkellers go out to it, and the boats pass right over the top.""",
respell=[["San Fruttuoso","san froo twoh zo"],["Portofino","por toe fee no"],["Prosper of Tarragona","pros per of ta ra go na"],["Fructuosus","fruk too oh sus"],["Benedictine","ben eh dik tin"],["Doria","doh ree ah"],["Genoa","jen oh ah"],["Barbary","bar ba ree"],["Frank and Orietta Pogson Doria Pamphilj","frank and or ee et ta pog son doh ree ah pam fee lee"],FAI],
sources=["https://fondoambiente.it/luoghi/abbazia-di-san-fruttuoso","https://www.fondoambiente.it/abbazia-di-san-fruttuoso-eng/","https://it.wikipedia.org/wiki/Abbazia_di_San_Fruttuoso"],
notes=["Rebuilt in the tenth century (FAI); Wikipedia says late tenth to early eleventh century.","The Doria tombs (seven, died 1275–1305) are from Wikipedia; FAI calls them fourteenth-century.","No dragon legend is in the sources, so it is omitted."])

T["47_casa-carbone"] = dict(title="Casa Carbone, Lavagna",
clean="""Step inside this house and you're in the eighteen nineties. Nothing much has moved since.

You're in the centre of Lavagna, on the coast between Chiavari and Sestri Levante. The way in is from Piazza Cordeviola, under the arcade. Above you is a nineteenth-century townhouse, and behind it, hidden from the street, a garden.

The house passed through a family of marble workers, the Bianchi, then the Raffo, and then the Carbone, who lived here right up to the end of the twentieth century. The last of them were a brother and sister. Emanuele Carbone was a bank director with an artist's eye, and he was the one who imagined the house having a public future. His sister Siria completed the bequest, and in nineteen eighty-seven the house came to the FAI.

What they left is a home that's perfectly intact, a portrait of a comfortable family at the end of the eighteen hundreds. Start in the central salon, the only real reception room in the house, and then go through to the smaller rooms around it, crowded with furniture and ornaments in the eclectic taste of the late eighteen hundreds. Look up at the ceilings, painted in tempera with Ligurian themes, and down at the floors, with their decorative mosaics. On the walls hang Genoese paintings from the sixteen to the eighteen hundreds.

[beat]

It isn't grand, and that's what makes it interesting. This is what the well-off of a small Ligurian town thought a good life looked like, kept exactly as they left it.

The house opens at weekends in spring and autumn, and closes for the winter, so check before you come. In summer the FAI holds aperitifs in the garden, and that's the best way to see it: a glass in the hand, in the green space behind the house, in a town that has no idea it's there.""",
respell=[["Casa Carbone","kah za kar bo neh"],["Carbone","kar bo neh"],["Lavagna","la van ya"],["Chiavari","kya va ree"],["Sestri Levante","ses tree leh van teh"],["Piazza Cordeviola","pyat sa kor deh vee oh la"],["Bianchi","byan kee"],["Raffo","raf fo"],["Emanuele","eh ma noo eh leh"],["Siria","see ree ah"],["Ligurian","lih gyoo ree an"],["Genoese","jen oh eez"],FAI],
sources=["https://fondoambiente.it/luoghi/casa-carbone","https://fondoambiente.it/casa-carbone-eng"],
notes=["The house is nineteenth-century, not 1950s.","'Pink house' is not supported by the sources, so it isn't used.","The entrance at Piazza Cordeviola 15 under the arcade is from the FAI English page.","Winter closure from 2 November; special openings on 28–29 November 2026."])

T["48_villa-rezzola"] = dict(title="Villa Rezzola, Lerici",
clean="""Shelley, Byron and D.H. Lawrence all loved this gulf. This is the garden that looks out over it.

From the terrace below the villa, turn and face the sea. The garden drops away in terraces towards the water, and beyond it is the Gulf of La Spezia, the Gulf of Poets. Nearby runs a long pergola of fifty-six pillars, hung with wisteria.

The house stands on medieval remains and is documented from the seventeen hundreds. It belonged first to the Botti, a Ligurian noble family. Then, from nineteen hundred, an English couple, Helen Lavinia and William Percy Cochrane, changed it to their taste: bow windows, panelled rooms, and a large park.

In nineteen thirty-five it passed to Countess Mara Braida Carnevale, and then to her daughter Maria Adele, known as Pupa, who lived here with her husband Piero Miniati until her death in twenty twenty. She left it to the FAI.

The house has its share of drama. In the Second World War it housed the Italian navy's high command, and then it was taken over by the Germans. One of the officers living here, Captain Rudolf Jacobs, took off his uniform and joined the partisans.

[beat]

What I like about the garden is how practical it is. Along the wisteria walk there are kitchen gardens, orchards and a rose garden on one side, and a big Italian lawn on the other. There are basins and cisterns feeding greenhouses and seed beds. It's a garden that was meant to feed the house as well as delight it. On the staircase landings, look down for the black and white pebble mosaics, the Ligurian risseu.

The park was restored in twenty twenty-three and twenty twenty-four, and the house itself is still being restored.

Before you go, climb to the belvedere tower. From the top, the whole Gulf of La Spezia opens up beneath you, and you'll see why the poets kept coming back.""",
respell=[["Villa Rezzola","villa ret so la"],["Lerici","leh ree chee"],["Shelley","shelly"],["La Spezia","la spet sya"],["Botti","bot tee"],["Ligurian","lih gyoo ree an"],["Helen Lavinia","helen la vin ee ah"],["Cochrane","kock ran"],["Mara Braida Carnevale","mah ra bry da kar neh vah leh"],["Maria Adele","maria ah deh leh"],["Pupa","poo pa"],["Piero Miniati","pyair oh mee nee ah tee"],["Rudolf Jacobs","roo dolf yah kobs"],["risseu","ree seh oo"],FAI],
sources=["https://fondoambiente.it/luoghi/villa-rezzola","https://fondoambiente.it/villa-rezzola-eng","https://fondoambiente.it/il-fai/beni/villa-rezzola-restauro-e-valorizzazione-del-parco/","https://fondoambiente.it/luoghi/beni-fai"],
notes=["'Documented from the 1700s' is not a build date. The restoration page calls it early-twentieth-century; the script follows the Bene page.","Bequeathed in 2020 by Maria Adele Carnevale Miniati.","Park works ran October 2023 to December 2024 (PNRR). Interiors are 'attualmente in restauro'.","Citrus is not mentioned in the sources, so it is omitted.","Hours conflict on the English page; check before visiting."])

T["49_tellaro"] = dict(title="Tellaro",
clean="""There's a story in this village that an octopus once saved it from pirates. It's written up in Latin on the church.

Walk out to the very end of the village, to the church of San Giorgio, sitting on a spur of rock with the sea on three sides. Its bell tower and its apse face straight out over the water. Behind you, the houses of Tellaro are stacked up the cliff.

The church was built in the fifteen hundreds on the remains of a Genoese fort from the thirteen hundreds, and its bell tower was made out of one of the fort's towers. It was consecrated in fifteen eighty-four.

Now the octopus. The legend says that one night Saracen pirates were creeping up on the sleeping village, and a giant octopus climbed out of the sea, wrapped its tentacles round the bell rope and rang the alarm. The villagers woke and drove the pirates off. Look outside the church for the plaque, in Latin, which tells the story with a perfectly straight face.

[beat]

What I love is that there may be a grain of truth in it. In the sixteen sixties a lookout fell asleep during a raid, and the bell rang anyway. Perhaps it was the wind on the rope. Perhaps it was an octopus. The village has always preferred the octopus.

Tellaro has had some notable neighbours. The writer and film director Mario Soldati lived here from nineteen sixty, and died here in nineteen ninety-nine. And just along the coast, at Fiascherino, D.H. Lawrence and Frieda spent the winter of nineteen thirteen in a little pink villa, where he worked on The Rainbow.

There's only one road into Tellaro, and it hugs the cliffs from Lerici. If you've the time, walk back along it to Fiascherino, look down at the coves Lawrence looked at, and you'll understand why he stayed.""",
respell=[["Tellaro","tel la ro"],["San Giorgio","san jor jo"],["Genoese","jen oh eez"],["Saracen","sa ra sen"],["Mario Soldati","mario sol dah tee"],["Fiascherino","fyas keh ree no"],["Frieda","free da"],["Lerici","leh ree chee"]],
sources=["https://it.wikipedia.org/wiki/Tellaro_(Lerici)","https://it.wikipedia.org/wiki/Chiesa_di_San_Giorgio_(Lerici)","https://it.wikipedia.org/wiki/Fiascherino","https://it.wikipedia.org/wiki/Mario_Soldati","https://www.comune.lerici.sp.it (homepage only)","https://www.turismoinliguria.it (HTTP 503)"],
notes=["The lookout asleep: Wikipedia gives 19 July 1660 (Casalis says 1666); the script says 'sixteen sixties'. 'Perhaps it was the wind' follows the village article's account of wind moving the ropes.","Lawrence stayed September 1913 to June 1914 and wrote L'arcobaleno (The Rainbow) there. The script says 'the winter of 1913' and 'worked on'.","The underwater nativity is unverified, so it is omitted."])

T["50_teatrino-di-vetriano"] = dict(title="Teatrino di Vetriano",
clean="""Seventy-one square metres, eighty seats, two tiers of boxes, and a Guinness record for being the smallest historic public theatre in the world.

You're in the hamlet of Vetriano, high in the hills above Lucca. From the outside, you'd hardly guess there was a theatre here at all. That's because it used to be a hayloft.

In eighteen eighty-nine a local engineer, Virgilio Biagini, gave the village an old hayloft on one condition: that it be turned into a theatre. Twenty-two villagers formed a society to do it. Each paid a little every month, and each gave their labour for free. The theatre opened in eighteen ninety-one.

Inside, it's like stepping into a jewellery box. The locals call it La Bomboniera, the sweet box. Sixty seats in the stalls, twenty more in two little tiers of balconies, the boxes painted with coats of arms, garlands and masks. And then the curtain, painted in the late eighteen hundreds with the sister arts of painting, music and poetry, and a Latin motto that roughly means: to make progress, and to give honest pleasure.

[beat]

That motto is the whole place, really. It was built by people with no money and a great deal of determination, so that a mountain village could have plays, music and somewhere to gather.

It was abandoned in the nineteen sixties and declared unsafe. In nineteen ninety-seven the Biagini heirs gave it to the FAI and to the town, and after a careful restoration it reopened in September two thousand and two. The restorers even had local supporters adopt the straw-seated chairs to help pay for them. Since then it's hosted small seasons, concerts, and even performances with La Scala in Milan.

Visits are by booking, so arrange one before you climb up here. And when you're inside, look for the little wooden flowers by the box office. Each one stands for somebody who helped bring this theatre back to life.""",
respell=[["Teatrino di Vetriano","teh ah tree no dee veh tree ah no"],["Vetriano","veh tree ah no"],["Lucca","look ka"],["Virgilio Biagini","veer jee lee oh bya jee nee"],["Biagini","bya jee nee"],["La Bomboniera","la bom bon yeh ra"],["La Scala","la ska la"],["Guinness","ginness"],FAI],
sources=["https://fondoambiente.it/luoghi/teatrino-di-vetriano","https://it.wikipedia.org/wiki/Teatrino_di_Vetriano"],
notes=["Dates: 1889 donation; FAI says inaugurated 1891, the Wikipedia infobox says 1890.","Seats: 80 (FAI and infobox); the Wikipedia body says 85.","The Guinness recognition is FAI's claim; Wikipedia dates it to 1997.","The motto 'Progredi et honeste delectare' and its paraphrase 'to make progress, and to give honest pleasure' are my rendering.","The wooden flowers at the box office are from Wikipedia (sponsors 'adopted' them).","Visits by booking (Wikipedia, based on a 2013 page)."])

T["51_torre-e-casa-campatelli"] = dict(title="Torre e Casa Campatelli, San Gimignano",
clean="""San Gimignano once had seventy-two towers. Fourteen are left, and this is the only one that's still exactly the size it was built.

You're on Via San Giovanni, the main street climbing into the town. Look up at the tall, plain tower of stone rising out of the house in front of you. It's twenty-eight metres high, and it's the Torre Campatelli.

Most of the town's medieval towers were later cut down or lost altogether. This one kept its full original volume, which makes it rather special among the fourteen survivors.

In the eighteen hundreds the tower and the eighteenth-century house built around it were bought by the Campatelli, a Florentine family of landowners and businesspeople, who turned it into a comfortable upper-middle-class home. Inside, have a look at the great salon with its neo-Renaissance fireplace and seventeenth-century portraits, the little sitting room, the study and the dining room. On the dining room walls are paintings by Guido Peyron, the uncle of the last owner. There's even a tiny family chapel.

[beat]

That last owner was Lydia Campatelli, who was born in nineteen twenty-five and died in two thousand and five. It's thanks to her that the house came down to us intact, and in two thousand and five she left it to the FAI.

So you get two things here at once. A medieval tower, from a town that built them like trophies. And inside it, a nineteenth-century family who simply lived there, among the furniture and the portraits, with San Gimignano going on outside the windows.

Before you leave, climb up to the attic, where the FAI projects a short film about a thousand years of the town's history on the walls of the tower itself. Then step back out onto Via San Giovanni and count the towers you can see. Fourteen is fewer than you'd think.""",
respell=[["Torre e Casa Campatelli","tor reh eh kah za kam pa tel lee"],["Campatelli","kam pa tel lee"],["San Gimignano","san jee meen yah no"],["Via San Giovanni","vee ah san jo van nee"],["Torre Campatelli","tor reh kam pa tel lee"],["Guido Peyron","gwee doh peh ron"],["Lydia","lid ee ah"],["Florentine","flor en tine"],FAI],
sources=["https://fondoambiente.it/luoghi/torre-e-casa-campatelli","https://fondoambiente.it/torre-e-casa-campatelli-eng","https://en.wikipedia.org/wiki/Torre_e_Casa_Campatelli (HTTP 404)"],
notes=["The 72 towers once and 14 now, and 'the only one to keep its original volume', are from FAI.","No construction date for the tower is given (the English page's '1300' is inconsistent), so none is stated.","'Most of the towers were later cut down or lost' is inferred from 72 to 14.","Donated by Lydia Campatelli (1925–2005) in 2005.","'Fourteen is fewer than you'd think' is the narrator's flourish."])

T["52_abbazia-di-san-galgano"] = dict(title="Abbazia di San Galgano",
clean="""The roof of this church is the sky. And on the hill above it, a knight's sword is still stuck in the rock.

Stand in the middle of the nave of the abbey. Great Gothic walls of stone and brick rise on either side of you, the pointed windows open to the air, and over your head there's nothing at all. Grass underfoot, clouds above.

The story starts with a knight called Galgano Guidotti, who gave up his life as a soldier. On Christmas Day, eleven eighty, so the tradition goes, he drove his sword into the ground on the hill of Montesiepi, meaning to turn it into a cross. He lived there as a hermit until he died the following year.

After him came the Cistercian monks, who began building this great abbey in twelve eighteen, and it was consecrated in twelve eighty-eight. Then came the long decline. One account says that in fifteen fifty an abbot sold off the lead from the roof. The vaults fell in in seventeen eighty-one, the bell tower collapsed in seventeen eighty-six, and three years later the church was deconsecrated and left open to the weather.

[beat]

And here's the thing. It's more beautiful as a ruin than it could ever have been with its roof on. The light comes straight in, and the building feels less like a church than like the memory of one.

Now walk up the hill, a few minutes away, to the chapel of Montesiepi. It's a round building, with a dome made of rings of alternating coloured stone, built where Galgano lived. In the middle of the floor is the rock, and sticking out of it, under a protective cover, the hilt of a sword and a stump of corroded blade.

Before you leave the chapel, look into the little side chapel on the left. Its walls were painted by Ambrogio Lorenzetti in the thirteen thirties, with a Madonna enthroned and an Annunciation. They're faded now, but they're by one of the great painters of Siena, in a hermit's chapel on a hill.""",
respell=[["San Galgano","san gal gah no"],["Galgano Guidotti","gal gah no gwee dot tee"],["Galgano","gal gah no"],["Montesiepi","mon teh syeh pee"],["Cistercian","sis ter shun"],["Tuscany","tusk a nee"],["Ambrogio Lorenzetti","am bro jo lo ren tset tee"],["Siena","see eh na"]],
sources=["https://www.sangalgano.info/ (unofficial)","https://it.wikipedia.org/wiki/Abbazia_di_San_Galgano","https://it.wikipedia.org/wiki/Eremo_di_Montesiepi"],
notes=["Consecration 1288 (Wikipedia); sangalgano.info says 1268.","The lead roof sale in 1550 by the commendatory Girolamo Vitelli is single-sourced (unofficial), hence 'one account says'.","The sword is a hilt and corroded blade fragment under a PMMA case.","The Lorenzetti frescoes date from 1334–36 and include a Maestà, the Annunciation and Eve.","Films (Nostalghia etc.) came only from a model summary, so they are omitted.","'Few minutes away' and 'on the left' for the side chapel are from the sources (chapel on the left of the entrance)."])

T["53_villa-gamberaia"] = dict(title="Villa Gamberaia, Settignano",
clean="""The New York Times once put this garden on its list of twenty-five you should see in your lifetime. It hardly raises its voice.

You're on the hillside at Settignano, above Florence. Find the long grass walk that runs the length of the garden, with the villa on one side. At one end, the walk opens out to the view: the city of Florence and the valley of the Arno, laid out below you.

The name may come from gamberi, the freshwater crayfish once raised in ponds round here. In the fourteen and fifteen hundreds the land belonged to the Gamberelli, the family of the sculptors Antonio and Bernardo Rossellino. But the villa itself was built by Zanobi Lapi, whose name and the date sixteen ten are recorded in an inscription.

Then came the Capponi family, in the early seventeen hundreds, and they gave the garden much of its shape. That long grass walk was once a bowling green. Off it are small, separate garden rooms. Look for the grotto garden, the nymphaeum, with its sculpture in relief, still fed by water from the springs on the hill above. And look for the lemon house, which goes back to the very beginning.

[beat]

The most famous thing here, though, came much later. In eighteen ninety-six, a Romanian princess, Jeanne Ghyka, bought the run-down villa, and around nineteen hundred she swept away an old vegetable patch in front of the house and replaced it with a water parterre: long, still pools, mirrored side by side, edged with box and cypress. Edith Wharton didn't care for it. Almost everyone else since has disagreed with her.

The house burned in August nineteen forty-four, set alight by retreating German soldiers, and it was rescued ten years later by Marcello Marchi, who restored it. The gardens opened to the public in nineteen fifty-six. The villa is still a private home, but the garden can be visited by ticket, so check the calendar and book before you come.

Before you leave, stand at the end of the water parterre and look back at the house reflected in the pools. It's the picture everybody takes, and for once, everybody's right.""",
respell=[["Villa Gamberaia","villa gam beh ry ah"],["Gamberaia","gam beh ry ah"],["Settignano","set teen yah no"],["Arno","ar no"],["gamberi","gam beh ree"],["Gamberelli","gam beh rel lee"],["Antonio and Bernardo Rossellino","an toe nee oh and bair nar doh ros sel lee no"],["Zanobi Lapi","tsa no bee lah pee"],["Capponi","kap po nee"],["nymphaeum","nim fee um"],["Jeanne Ghyka","zhan ghee ka"],["Edith Wharton","ee dith wor ton"],["Marcello Marchi","mar chel lo mar kee"],["Tuscany","tusk a nee"]],
sources=["https://www.villagamberaia.com/","https://www.villagamberaia.com/en/history","https://www.villagamberaia.com/en/the-gardens-of-gamberaia","https://it.wikipedia.org/wiki/Villa_Gamberaia"],
notes=["Capponi: Wikipedia says 1718; Acton (quoted on the official site) says 1717. The script says 'early seventeen hundreds'.","The parterre was built 1898–1900 (Wikipedia). Ledyard later replaced the flower borders with box and yew; the script says 'edged with box and cypress', which describes it now.","The 1944 fire was set by retreating Germans (Wikipedia)."])

for k, v in T.items():
    if S / f"{k}.json".exists() or "35_san-giorgio" in str(S / f"{k}.json") or "38_giardini" in str(S / f"{k}.json"):
        continue  # src/*.json is now the source of truth (FAI removed 2026-11-24); never overwrite
    (S / f"{k}.json").write_text(json.dumps(v, ensure_ascii=False, indent=1))
print(len(T))
