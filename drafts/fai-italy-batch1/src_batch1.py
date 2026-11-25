import json, pathlib
S = pathlib.Path("src"); S.mkdir(exist_ok=True)
T = {}

T["01_castello-della-manta"] = dict(
title="Castello della Manta",
clean="""Nine men, nine women, and a fountain that makes you young again. They've been waiting upstairs for about six hundred years.

From the inner courtyard of the castle at Manta, look up at the walls around you. Plain, heavy stone, built for keeping people out rather than inviting them in. On a clear day, the pointed peak behind you to the west is Monviso.

This started life in the thirteenth century as a military outpost for the Marquisate of Saluzzo. What changed it was a man called Valerano, the illegitimate son of Marquis Tommaso the Third, who became lord here and regent of the marquisate. In the early fourteen hundreds, he turned a fortress into a home, and then he did something rather remarkable with one room.

That room is the Baronial Hall, and its walls were painted around fourteen twenty by an artist nobody can name. He's simply called the Master of the Manta Castle. Along one wall stand nine heroes: Hector, Alexander, Julius Caesar, Joshua, David, Judas Maccabeus, King Arthur, Charlemagne and Godfrey of Bouillon. Facing them, nine heroines from the ancient world. All eighteen are dressed in the very latest fashions of the fourteen hundreds, which is a bit like painting Julius Caesar in a good suit. Scholars have long suspected that some of those faces belong to the Saluzzo family themselves.

The source was a romance called The Wandering Knight, written by Valerano's own father. So this is a family that put its favourite book on the walls, and quite possibly itself into the pictures.

[beat]

Then there's the south wall: the Fountain of Youth. The old and the frail arrive at one side, they climb into the water, and they come out the other side young and very pleased with themselves. It's one of the rare surviving paintings of the subject anywhere, and it's funny, which you don't expect from the Middle Ages.

The castle passed through several families and fell into ruin, before Countess Elisabetta De Rege Provana gave it to the FAI in nineteen eighty-five.

Before you leave, walk down to the little church at the foot of the castle. It has its own cycle of frescoes on the Passion of Christ, from the fifteenth and sixteenth centuries, and after the heroes upstairs it's a very different kind of story.""",
respell=[["Saluzzo","sa loot so"],["Valerano","va le rah no"],["Tommaso","tom mah so"],["Monviso","mon vee so"],
["Maccabeus","mack a bee us"],["Bouillon","boo yon"],["Elisabetta De Rege Provana","eh lee za bet ta deh ray jay pro vah na"],
["Charlemagne","shar le main"],["FAI","fy"]],
sources=["https://fondoambiente.it/luoghi/castello-della-manta","https://fondoambiente.it/luoghi/castello-della-manta/visita","https://it.wikipedia.org/wiki/Castello_della_Manta"],
notes=["Construction: FAI says thirteenth century; Wikipedia says twelfth. Script follows FAI.",
"Fresco date 'around fourteen twenty' is from Wikipedia; FAI gives no date.",
"Family-portrait identifications are scholarly suggestions, so the script says 'long suspected'.",
"Donation: FAI says 1985; Wikipedia adds a 1984 loan. Script uses 1985.",
"Monviso in the background is from the FAI page."])

T["02_castello-e-parco-di-masino"] = dict(
title="Castello e Parco di Masino",
clean="""One family held this hilltop for more than nine hundred years. When the last of them sold it, in nineteen eighty-eight, the FAI had to find the money from a whole roll call of backers to keep it in one piece.

The hill you're on is part of the Serra d'Ivrea, the long, straight ridge you can see stretching away across the plain. It isn't a range of hills at all. It's rubble, pushed here by a glacier, and it's one of the largest and best preserved glacial ridges in Europe. The castle sits on top, looking out over the Canavese.

The family were the counts Valperga, and they liked to say they descended from Arduin of Ivrea, crowned King of Italy in the year one thousand and two. Whether that's true is rather beside the point. A family that claims a king for an ancestor builds accordingly.

Inside, have a look for the Salone dei Savoia. Its walls are painted with twenty-two cities of Piedmont and Savoy, but for a long time you couldn't see them at all. They'd been painted over. After years of restoration, the room was revealed to the public in twenty twenty-two. Then there's the library, more than twenty-five thousand volumes, and the Gallery of Poets, finished in eighteen fourteen, with writers painted in order from Dante onwards.

And here's the thing about Masino. It's a house that tells you, room by room, who it wanted to be seen with: kings in the ancestry, the House of Savoy on the walls, the great poets in the corridor.

[beat]

The garden is quieter about it. Somewhere below the castle is an eighteenth-century maze, among the largest in Italy, made of around a thousand clipped hornbeams. It was replanted from an old drawing found in the family archives, so you're walking a design the Valperga would recognise.

If you've time, find the maze first and get yourself properly lost. Then come back up to the terrace for the view along the Serra, and you'll see exactly why someone wanted to own this hill for nine centuries.""",
respell=[["Masino","ma zee no"],["Serra d'Ivrea","sair ra dee vray ah"],["Ivrea","ee vray ah"],["Canavese","ka na vay zeh"],
["Valperga","val pair ga"],["Arduin","ar doo in"],["Salone dei Savoia","sa lo nay day sa voy ah"],["Savoy","sa voy"],["Dante","dan tay"],["FAI","fy"],["Piedmont","peed mont"]],
sources=["https://fondoambiente.it/luoghi/castello-e-parco-di-masino","https://fondoambiente.it/castello-e-parco-di-masino-eng","https://it.wikipedia.org/wiki/Castello_di_Masino"],
notes=["'More than nine hundred years' follows FAI ('più di nove secoli'); Wikipedia says ten centuries.",
"Descent from Arduin is a family claim; script frames it that way.",
"Maze: FAI says 'tra i più grandi in Italia' with 'mille piante di carpini'. Wikipedia's 'second largest' is from a 2017 article and is not used.",
"Gallery of Poets 'finished in 1814' and 'from Dante' are from Wikipedia.",
"The FAI EN page calls it a 'royal palace'; that is not used."])

T["03_collezione-enrico-villa-flecchia"] = dict(
title="Collezione Enrico a Villa Flecchia",
clean="""Most collectors hang their landscapes facing a wall. This one hung them facing the landscape.

Villa Flecchia stands on the edge of Magnano, on the low glacial ridge called the Serra. Turn so the village is behind you and look out. Fields, woods and small villages run flat towards the horizon, and the only thing that breaks it is the long, level line of the Serra itself, curving round the great glacial basin of Ivrea.

The house is modern, built between nineteen fifty-five and nineteen seventy, with simple lines and every window turned to this view. It belonged to the architect Piero Enrico and his wife Franca. In twenty eleven they gave it to the FAI, with everything inside it, and Piero explained why: he wanted to preserve, over time, what he had collected with love and sacrifice over the course of his life.

What he collected was paintings, more than sixty of them, and almost all landscapes. His passion was for the painters who shaped art in Piedmont from the late eighteen hundreds to the middle of the twentieth century, whether they were born here or simply chose it. Look for Antonio Fontanesi, the great Romantic landscape painter of Piedmont, and Lorenzo Delleani, who painted these same hills and mountains. Then walk on to Francesco Menzio, and to the abstract work of Luigi Spazzapan, and watch the landscape slowly come apart into colour and shape.

That's the quiet pleasure of this house. Inside, a hundred years of people trying to paint this part of the world. Outside every window, the world they were trying to paint.

[beat]

Visits here are by arrangement and on set days, so do check before you come. And when you leave, walk up into Magnano itself. It's a small village of medieval origin, sitting right on top of the ridge, and from its edge you can see the Serra from the inside.""",
respell=[["Flecchia","flek ya"],["Magnano","man yah no"],["Ivrea","ee vray ah"],["Piero","pyair oh"],["Franca","fran ka"],
["Fontanesi","fon ta nay zee"],["Delleani","del lay ah nee"],["Menzio","men tsee oh"],
["Spazzapan","spat sa pan"],["Enrico","en ree ko"],["FAI","fy"],["Piedmont","peed mont"],["Serra","sair ra"]],
sources=["https://fondoambiente.it/luoghi/beni-fai","https://fondoambiente.it/luoghi/collezione-enrico-a-villa-flecchia"],
notes=["Opening days and hours were not on the pages read; script tells listeners to check.",
"FAI names Fontanesi, Spazzapan, Oliviero, Pasini, Delleani and Menzio; the script names four of them.",
"No individual works are named on the FAI page, so none are named here."])

T["04_sacra-di-san-michele"] = dict(
title="Sacra di San Michele",
clean="""You came up here by road. For a thousand years, most people came up on their knees.

At the top of the path from the car park, stop and look up. The abbey rises straight out of the rock of Monte Pirchiriano, nine hundred and sixty-two metres up, at the mouth of the Susa Valley. Its foundations are a base of masonry twenty-six metres tall, built because there simply wasn't enough mountain to stand a church on.

The story begins with a hermit, Giovanni Vincenzo, who came up here to be alone, and a French count, Hugh of Montboissier, who paid for something rather grander. The official date for the building is between nine eighty-three and nine eighty-seven. Benedictine monks arrived in the eleventh century, and since eighteen thirty-six the abbey has been in the care of the Rosminian fathers.

Inside, you'll climb the Staircase of the Dead. It's called that because it was once lined with tombs, and the monks were buried along the way up. At the top is the Zodiac Portal, carved by a sculptor called Niccolò in the eleven twenties. The signs of the zodiac run up the stone, and they're there as a reminder that time is passing. The portal is being restored at the moment, so you may find some of it under wraps.

If the place feels familiar, there's a reason. Umberto Eco was partly inspired by this abbey when he wrote The Name of the Rose.

[beat]

But the real point of the Sacra is the line it sits on. It was a stop on the Way of Saint Michael, the pilgrim route that linked Mont-Saint-Michel in France with the sanctuary of Monte Sant'Angelo in the south of Italy. Three abbeys to the same archangel, each one perched somewhere improbable. Piedmont now calls this its symbol, and standing here you can see why.

Before you go, find the ruins on the north side and the lonely tower of the Bell'Alda. The legend says a young woman called Alda leapt from it to escape soldiers, and angels caught her. She survived, tried it again to show off to the village, and that time the angels didn't bother.""",
respell=[["Sacra di San Michele","sack ra dee san mee kay lay"],["Sacra","sack ra"],["Pirchiriano","peer kee ree ah no"],["Susa","soo za"],
["Giovanni Vincenzo","jo van nee vin chen tso"],["Montboissier","mon bwah see ay"],["Rosminian","roz min ee an"],["Niccolò","nee ko loh"],
["Umberto Eco","oom bair toh ay ko"],["Mont-Saint-Michel","mon san mee shell"],["Monte Sant'Angelo","mon tay san tan jeh lo"],
["Bell'Alda","bel al da"],["Alda","al da"],["Piedmont","peed mont"]],
sources=["https://www.sacradisanmichele.com/","https://sacradisanmichele.com/la-sacra/","https://sacradisanmichele.com/informazioni/","https://it.wikipedia.org/wiki/Sacra_di_San_Michele"],
notes=["Altitude: 962 m is the summit (official site); Wikipedia puts the building at 960 m on a 26 m base. Script says 962 m 'up'.",
"Founding: the official site's 983–987 is used. Wikipedia also cites 999–1002.",
"Rosminians: the official homepage says 1837; the history page and Wikipedia say 1836. Script uses 1836.",
"Sculptor is spelled Niccolò (Wikipedia); his dates are 1120–1130.",
"Zodiac Portal restoration notice dated 21 Oct 2026; re-check before recording.",
"Symbol of Piedmont: designation confirmed on Wikipedia; the regional law number was not verified, so it isn't cited."])

T["05_villa-taranto"] = dict(
title="Giardini Botanici di Villa Taranto",
clean="""A Scotsman on a train read a property advert in The Times, and this garden is what came of it.

Just inside the gates, the paths fan out ahead of you down the hillside towards Lake Maggiore, with the water glinting through the trees. Everything you're about to walk through was planted on purpose by one man.

He was Captain Neil McEacharn, born in London in eighteen eighty-four to a wealthy Scottish family, and botany was the great passion of his life. Around nineteen thirty he bought a villa here called La Crocetta, and renamed it Villa Taranto, after an ancestor, Marshal Macdonald, whom Napoleon had made Duke of Taranto. Then he spent the next ten years building a garden.

Have a look for the Valletta, the little ravine. In the winter of nineteen thirty-eight, a hundred men dug it out by hand, and it's crossed by a dry-stone footbridge thirty-five metres long. The water for all the fountains and terraces comes up from the lake, through a system McEacharn installed in nineteen thirty-four.

In the greenhouse is the gift. The giant water lily Victoria cruziana, grown from seed sent from Stockholm in nineteen fifty-six. From the middle of June into October its leaves reach about two metres across, and each one can hold around ten kilos.

Here's what I love about this place. McEacharn built it as a private paradise, and then, after the war, he opened the gates. The public has been coming in since nineteen fifty-two, and these days the garden counts its plants in the thousands of species and varieties, gathered from all over the world.

[beat]

He died in April nineteen sixty-four, on the veranda, looking out over what he'd made. He's buried in the garden, in the small mausoleum chapel built the following year.

If you've the legs for it, finish there. Then, depending on the season, look for the tulip labyrinth in spring, sixty varieties along a winding path about four hundred metres long, or the dahlia maze from summer into autumn.""",
respell=[["McEacharn","mack eck ern"],["Maggiore","mad jaw ray"],["La Crocetta","la kro chet ta"],["Taranto","ta ran toh"],
["Valletta","val let ta"],["Victoria cruziana","victoria kroo zee ah na"],["Macdonald","mack donald"]],
sources=["https://www.villataranto.it/","https://www.villataranto.it/storia/","https://www.villataranto.it/il-fondatore/","https://www.villataranto.it/giardini/","https://www.villataranto.it/specie-botaniche-rare/","https://www.villataranto.it/fioriture/","https://it.wikipedia.org/wiki/Villa_Taranto"],
notes=["Purchase: the official pages say 1930 and 1931 in different places, so the script says 'around nineteen thirty'.",
"'Ten years building': works ran 1931–1940 (official history page).",
"Plant counts on the history page are about 1,000 non-native plants and about 20,000 varieties and species; the script says 'thousands' to stay safe.",
"The Valletta was dug in winter 1938–39; the script says 'the winter of nineteen thirty-eight'.",
"Season: April to October. Check the dates for the tulip, dahlia and Victoria displays before recording."])

T["06_castel-savoia"] = dict(
title="Castel Savoia",
clean="""A queen wanted a summer house with a view of Monte Rosa. Her husband never got to sleep in it.

Stand on the drive, a little way back from the building, so you can take in all of it at once. A three-storey villa of local stone with five pointed towers, all at different heights, one of them octagonal, and every spire a different shape. Behind you, if the cloud allows, the glacier of the Lyskamm and the Monte Rosa massif.

The queen was Margherita of Savoy. She first came to Gressoney on holiday in eighteen eighty-nine and fell for it, and she chose this slope, about fourteen hundred and forty metres up, for a house of her own. The first stone was laid in the summer of eighteen ninety-nine, to designs by Emilio Stramucci, who had worked on the royal palace in Turin. King Umberto was assassinated at Monza in nineteen hundred, four years before the house was finished.

It's called a castle, but it's really a grand villa dressed up as one, and that mix of styles was exactly what she asked for. She followed the building closely.

Inside, have a look at the carving. The oak staircase, the panelling and the ceilings are covered with Savoy emblems and with flowers chosen to echo her name. Margherita is Italian for daisy. And here's the gift: there are no kitchens in the house. She had them built about thirty metres away, and the food came through an underground tunnel on a little railway with electric trolleys, then up a lift to the dining room. A queen's summer house where you'd never smell the cooking.

[beat]

She came every summer until nineteen twenty-five, and friends like the poet Giosuè Carducci stayed nearby. After her death the house was sold to a Milanese industrialist who kept it almost exactly as it was, and in nineteen eighty-one the Aosta Valley bought it.

When you've seen the rooms, walk down to the rock garden at the foot of the building, then follow the drive to Villa Belvedere, where her guests and the royal guard were lodged. Look back from there and you'll have the towers and the mountain in one frame.""",
respell=[["Castel Savoia","kas tell sa voy ah"],["Monte Rosa","mon tay ro za"],["Lyskamm","liss kam"],["Margherita","mar geh ree ta"],
["Savoy","sa voy"],["Gressoney","gress oh nay"],["Emilio Stramucci","eh mee lee oh stra moo chee"],["Umberto","oom bair toh"],
["Monza","mon tsa"],["Giosuè Carducci","jo zoo eh kar doo chee"],["Villa Belvedere","villa bel veh deh reh"],["Aosta","ah os ta"]],
sources=["https://it.wikipedia.org/wiki/Castel_Savoia","https://www.lovevda.it (returned HTTP 503 twice; not read)"],
notes=["Only one source could be read, because the regional tourism site was down. Re-check the dates (1899–1904), the architect and the kitchen railway against lovevda.it or regione.vda.it before recording.",
"The daisy reading: the source says the floral motifs 'explicitly recall' the queen's name. 'Margherita is Italian for daisy' is plain fact.",
"The Walser context of Gressoney was not covered by any source read, so it is left out.",
"Opening hours were not found."])

for k, v in T.items():
    if S / f"{k}.json".exists() or "35_san-giorgio" in str(S / f"{k}.json") or "38_giardini" in str(S / f"{k}.json"):
        continue  # src/*.json is now the source of truth (FAI removed 2026-11-24); never overwrite
    (S / f"{k}.json").write_text(json.dumps(v, ensure_ascii=False, indent=1))
print(len(T))
