"""Batch 8: nine new tours added 2026-11-24 (owner request). Writes src/78..86 JSON."""
import json, pathlib
src = pathlib.Path(__file__).resolve().parent / "src"

T = {}

T["78_palazzo-mondadori"] = dict(
title="Palazzo Mondadori, Segrate",
clean="""No two of these arches are the same. Look along the row and you'll see it straight away.

Via Arnoldo Mondadori, on the eastern edge of Milan, with the airport not far away. Across the water in front of you, a long glass building hangs inside a line of tall white concrete arches, and to either side are two low buildings with curving walls, one round, one shaped rather like a leaf. This is a working office, so you're looking from outside, which is how it was meant to be seen.

It's the headquarters of the publisher Mondadori, and it exists because of a trip to Brazil. Between nineteen fifty and nineteen sixty-five the company's staff grew from about three hundred and thirty to three thousand, and it badly needed a new home. In nineteen sixty-five Giorgio Mondadori saw Oscar Niemeyer's Foreign Ministry in Brasília, the Itamaraty, and in nineteen sixty-eight he asked Niemeyer to design one for him. It was built between nineteen seventy and nineteen seventy-five.

Now have a look at how the glass block sits. It doesn't stand on the ground at all. Five floors of offices, two hundred metres long, are hung from the arches above, a system the engineer Bruno Contarini worked out when the first scheme wouldn't stand up. And the arches themselves change their rhythm as they go. Niemeyer was rather pleased about that. Nobody, he said, had ever seen a colonnade where the arches were all different from each other.

The water is part of the design too, about twenty thousand square metres of it, set in a park by the landscape architect Pietro Porcinai.

[beat]

And here's the thing. Niemeyer called this advertising architecture. It needs no sign, because the building is the sign. A publisher's name, written in concrete, for everyone driving past on the way to the airport.

Before you go, look out in the water for the tall steel sculpture by Arnaldo Pomodoro, the Column of Large Sheets, which is about the power of communication. Then walk a little way along the road and watch the arches shift as you move.""",
respell=[["Segrate","segrahtay"],["Mondadori","mondadoree"],["Niemeyer","neemayer"],["Brasília","brazeelya"],["Itamaraty","eetamarachee"],["Contarini","kontareenee"],["Porcinai","porcheenai"],["Arnaldo Pomodoro","arnaldo pomodoro"],["Arnoldo","arnoldo"],["Giorgio","jorjo"]],
sources=["https://en.wikipedia.org/wiki/Mondadori_Palace","https://www.mondadorigroup.com/about-us/our-headquarters","https://atlantearchitetturacontemporanea.cultura.gov.it/en/736-2/"],
notes=["Dates: commissioned 1968, built 1970-1975 (Wikipedia, Mondadori); some sources give 1968-1975 for the works, so the script uses 1970-1975 for construction.","Staff 335 to 3,000 between 1950 and 1965: Mondadori's own headquarters page; rounded to 'about three hundred and thirty'.","Water area 20,000 m2 and 'advertising architecture': Mondadori headquarters page.","The building is private offices; the script says so and keeps the listener outside.","Renovated 2023-2025 for the 50th anniversary; not mentioned, as it doesn't change what the listener sees."])

T["79_ville-jacques-couelle"] = dict(
title="Ville Jacques Couëlle, Monti Mannu",
clean="""These houses are trying very hard not to look like houses. That was the whole idea.

You're at Monti Mannu, in the hills above Abbiadori, just outside Porto Cervo. In front of you, among the granite boulders and the scrub, there are walls that curve instead of running straight, windows of odd shapes, and rooms that seem to have grown out of the rock rather than been built on it.

They're the work of Jacques Couëlle, a French architect who never trained as one and who thought of himself as more of a sculptor. He was a friend of Picasso and Dalí, and he was known, a little unkindly, as the architect of billionaires. In nineteen sixty-two, when the Aga Khan began building the Costa Smeralda, Couëlle was one of the architects asked to give it a look of its own, alongside Luigi Vietti and Michele Busiri Vici. With his son Savin he built the Hotel Cala di Volpe. Then he turned to this hillside, and in nineteen sixty-eight he built Villa La Grotta, the cave, which he meant as his own home. Others followed around it.

Have a look at how little of it is flat. Couëlle wanted houses shaped by the land, the sun and the wind, the way a shell or a burrow is shaped, so that you can't quite say where the inside stops and the outside begins.

[beat]

What I find rather moving is where the story went next. For years the villas were shut away, after they were seized from organised crime. In May twenty twenty-six they were handed to the town of Arzachena, about thirty thousand square metres of buildings and land, and that October they opened to the public for the very first time. The plan now is a museum of the Costa Smeralda itself, telling the story of the coast from the inside of one of its strangest houses.

They aren't open every day yet, so check before you come. And if you'd like to see the same hand on a grander scale, drive down to the coast at Cala di Volpe and look at the hotel, with its rough walls and towers, as if a village had been carved rather than built.""",
respell=[["Couëlle","koo ell"],["Monti Mannu","montee mannoo"],["Abbiadori","abbyadoree"],["Porto Cervo","porto chairvo"],["Dalí","dahlee"],["Aga Khan","ahga kahn"],["Costa Smeralda","kosta smeralda"],["Luigi Vietti","looeejee vyettee"],["Busiri Vici","boozeeree veechee"],["Savin","savan"],["Cala di Volpe","kahla dee volpay"],["Villa La Grotta","villa la grotta"],["Arzachena","artsakena"]],
sources=["https://www.costasmeralda.it/en/article/jacques-couelles-villas-become-the-costa-smeralda-r-museum/","https://www.unionesarda.it/en/sardinia/arzachena-the-ville-couelle-opens-to-the-public-for-the-first-time-yz93c619","https://www.unionesarda.it/en/sardinia/ville-couelle-the-confiscated-property-will-become-the-costa-smeralda-museum-bpx2kqki","https://www.unionesarda.it/en/sardinia/arzachena-wants-quot-ville-jacques-couelle-monti-mannu-quot-property-seized-from-the-mafia-sgc5xcdo","https://en.wikipedia.org/wiki/Jacques_Cou%C3%ABlle"],
notes=["Transfer to the Municipality of Arzachena in May 2026 and first public opening on 10-11 October (2026): costasmeralda.it and L'Unione Sarda. The first opening happened during a national open-days event; the script does not name the organiser, per owner instruction.","'Seized from organised crime': L'Unione Sarda says 'confiscated from organized crime'; one headline says 'mafia', which the script avoids.","Villa La Grotta 1968, intended as his own home: costasmeralda.it.","Opening hours are not regular; the script tells the listener to check."])

T["80_castello-di-sammezzano"] = dict(
title="Castello di Sammezzano",
clean="""A Tuscan nobleman spent nearly forty years filling a farmhouse in the hills above the Arno with an imaginary Moorish palace.

You're at Sammezzano, above the village of Leccio, south-east of Florence, among some of the tallest trees in Italy. Ahead of you, through the park, is a long building with battlements and a tower, which looks fairly ordinary from outside. That's the trick. The surprise is all indoors.

There was a farm here by sixteen oh five, built by the Ximenes of Aragon. In the eighteen hundreds it came to Ferdinando Panciatichi Ximenes d'Aragona, and from eighteen fifty-three to eighteen eighty-nine he remade it, room by room, in the Moorish style that was the height of fashion. He designed it himself and paid for it himself, and every brick, every piece of stucco and every tile was made here, by local workers he trained for the job. There's an entrance hall, a corridor hung with plaster stalactites, a ballroom, and the famous Peacock Room, all of it in colour and pattern from floor to ceiling. The story goes that there's a room for every day of the year.

King Umberto the First came to stay in eighteen seventy-eight. After the war the castle was a luxury hotel, and film crews loved it: Pasolini shot his Arabian Nights here, and Matteo Garrone his Tale of Tales.

[beat]

And then it was left empty. For years it changed hands at auction and slowly fell apart, until people simply refused to let it go. In twenty sixteen it came top of a national poll of the places Italians most wanted saved, with more than fifty thousand votes. In twenty twenty-five it was bought by the Moretti family, who plan a long restoration.

It's private, and the doors open only on rare occasions, so check before you come. But do look at the trees. The park holds the largest group of giant sequoias in Italy, fifty-seven of them, all more than thirty-five metres tall. Planted by the same man, who clearly didn't do anything by halves.""",
respell=[["Sammezzano","sammetsahno"],["Leccio","letcho"],["Arno","arno"],["Ximenes","kseemenes"],["Ferdinando Panciatichi","ferdinando panchateekee"],["d'Aragona","daragona"],["Umberto","oombairto"],["Pasolini","pazoleenee"],["Matteo Garrone","matayo garronay"],["Moretti","moretti"],["sixteen oh five","sixteen oh five"]],
sources=["https://it.wikipedia.org/wiki/Castello_di_Sammezzano","https://en.wikipedia.org/wiki/Sammezzano"],
notes=["'Nearly forty years': the remodelling ran from 1853 to 1889 (it.wikipedia). 'Imaginary Moorish palace' is framing for the Orientalist style the sources describe.","Rooms built 1853 (entrance), 1862 (stalactite corridor), 1867 (ballroom), tower dated 1889: it.wikipedia.","'365 rooms' is reported by en.wikipedia; the script frames it as 'the story goes'.","2016 poll: 50,141 votes (it.wikipedia). The organiser is not named, per owner instruction.","2025 purchase by the Moretti family for EUR 18 million, about EUR 50 million of planned restoration: it.wikipedia.","57 adult giant sequoias, all over 35 m: it.wikipedia.","Access: private, open only on occasional days."])

T["81_antica-edicola-mantova"] = dict(
title="Antica Edicola dei Giornali, Mantua",
clean="""This may well be one of the prettiest newsstands in Italy, and it was moved here because it was getting in the way of a church.

You're in Piazza Canossa, in the old centre of Mantua. In front of you, standing on its own, is a small eight-sided kiosk of iron, wood and glass, on a low stone base, with pointed windows all the way round and a little metal spire on top, like a lantern that's wandered in from a Gothic cathedral.

People often call it Liberty, Italy's word for Art Nouveau, but have a look at those windows. They're paired pointed arches, which makes it neo-Gothic, a nineteenth-century idea of the Middle Ages rather than a twentieth-century one.

In eighteen eighty-two the town gave a Mantuan called Ulisse Sicola permission to open a newspaper kiosk in the square in front of Sant'Andrea, the great church by Leon Battista Alberti. In nineteen twenty-five he was asked to move it here, so as not to interfere, in the words of the time, with the triumphal architecture of the basilica. I rather like that. The newspaper man was told he was spoiling the view.

It very nearly didn't survive. In nineteen eleven its roof was replaced with a cap of concrete that blocked the little upper windows, and by the late twentieth century it was in a sorry state. It was protected in nineteen ninety-one, bought the following year after a public appeal, and put back the way it was meant to look. For a while it sold flowers instead of newspapers.

[beat]

What's worth knowing, standing here, is how much care has gone into something so small. In twenty twenty-three it was restored again, piece by piece, removing the rust and replacing only what couldn't be saved. Now it's lit up as a tiny gallery, with exhibitions of local photographers. A lantern for the city, after all.

From here it's a short walk to Piazza Mantegna and the front of Sant'Andrea. Stand there for a moment and picture the kiosk in front of that enormous arch. You can see why somebody asked it to move.""",
respell=[["Antica Edicola dei Giornali","anteeka edeekola day jornahlee"],["Mantua","mantyooa"],["Piazza Canossa","pyatsa kanossa"],["Ulisse Sicola","ooleesay seekola"],["Sant'Andrea","santandraya"],["Leon Battista Alberti","layon batteesta albairtee"],["Piazza Mantegna","pyatsa mantenya"],["Liberty","liberty"]],
sources=["https://fondoambiente.it/antica-edicola-dei-giornali-eng","https://fondoambiente.it/news/il-restauro-dellantica-edicola-di-mantova-una-lanterna-della-cultura","https://fondoambiente.it/luoghi/antica-edicola-dei-giornali"],
notes=["Owner named it 'Antica Edicola Liberty'; the official name is Antica Edicola dei Giornali, and the primary sources describe its style as neo-Gothic. The script says both.","Original site: 'Piazza Sant'Andrea' (English page) and 'Piazza Mantegna' (2023 news) are the same square in front of the basilica; the script says 'the square in front of Sant'Andrea' and later 'Piazza Mantegna'.","1911 concrete cap, protection on 18 October 1991, purchase 1992 after a public appeal, 2023 restoration and photo exhibitions: FAI news (2023). The buyer is not named, per owner instruction.","Owner's coordinate reverse-geocodes to 7 Piazza Matilde Canossa: correct."])

T["82_piazza-del-duomo-trento"] = dict(
title="Piazza del Duomo, Trento",
clean="""A mountain city, a long way from any sea, put the god of the sea in the middle of its main square. There's a pun involved.

You're in Piazza del Duomo, in the centre of Trento, beside the big fountain with Neptune on top. Behind it, along one side of the square, runs the long stone flank of the cathedral. To the left of the cathedral, as you face it, is the old bishops' palace with its tall civic tower, and on the side of the square opposite the cathedral, a row of arcaded houses with their fronts painted all over.

Start with the fountain. The town council decided on it in seventeen sixty-six, and a sculptor from Lavarone called Giongo made it, with the Neptune and the tritons and sea horses carved by Stefano Salterio. Why Neptune, here? Nobody wrote it down, but the city's Roman name was Tridentum, and Neptune carries a trident. Getting water to it was the hard part. The first pipes burst, and the water only began to flow on the eighth of July, seventeen sixty-nine. A month later the council banned people from washing nappies, tripe and frogs in it. The Neptune you see is a bronze copy. The original is in the courtyard of Palazzo Thun, round the corner.

Then turn to the cathedral. Work on the building you see began in twelve twelve, under the master builder Adamo d'Arogno, and it's here that the Council of Trent opened, on the thirteenth of December, fifteen forty-five. Its early sessions were held in the cathedral choir, as the Church gathered to answer the Protestant Reformation.

[beat]

And here's the thing. The fountain cost the city a fortune, and people were furious. Not long after it opened, someone pinned a note to it asking the chief magistrate to turn its stones into bread. The square has always been where Trento argued with itself.

Before you go, walk over to the painted houses, Casa Cazuffi and Casa Rella, and look up at the frescoes. Then find the single lime tree under the civic tower. To go and sit under the lime tree, in Trento, once meant you'd been thrown out of home.""",
respell=[["Trento","trento"],["Tridentum","trydentum"],["Lavarone","lavaronay"],["Giongo","jongo"],["Stefano Salterio","stefano saltairio"],["Palazzo Thun","palatso toon"],["Adamo d'Arogno","adamo darronyo"],["Casa Cazuffi","kahza katsoofee"],["Casa Rella","kahza rella"],["Duomo","dwomo"]],
sources=["https://it.wikipedia.org/wiki/Piazza_Duomo_(Trento)","https://it.wikipedia.org/wiki/Fontana_del_Nettuno_(Trento)","https://it.wikipedia.org/wiki/Duomo_di_Trento"],
notes=["Fountain: council resolution 23 December 1766; designer Giongo of Lavarone (it.wikipedia gives both 'Francesco Antonio' and 'Flavio Antonio', so only the surname is used); statues by Stefano Salterio; water first flowed 8 July 1769; proclamation of 13 August 1769 against washing 'pannolini, trippe, rane'; original Neptune moved to Palazzo Thun in 1939, bronze copy since 1945.","The Tridentum/trident link is offered by it.wikipedia as a hypothesis; the script says 'nobody wrote it down'.","The 'turn these stones into bread' note: it.wikipedia, citing Tovazzi.","Cathedral: first stone 29 February 1212 under Adamo d'Arogno; opening session of the Council 13 December 1545 in the choir: it.wikipedia (Duomo di Trento).","Lime tree saying 'andar sotto al tiglio': it.wikipedia (Piazza Duomo).","Layout check: Palazzo Pretorio forms the east side and meets the cathedral at the corner; the painted houses are on the north side, opposite the cathedral's flank."])

T["83_palazzo-ducale-venezia"] = dict(
title="Doge's Palace, Venice",
clean="""Most buildings put the heavy part at the bottom. This one does it the other way round, and somehow gets away with it.

You're on the Piazzetta, the open space between St Mark's Square and the water, facing the long side of the Doge's Palace. The lagoon is to your right. In front of you, two storeys of slender white arches hold up a great flat wall of pink and white stone, laid in a diamond pattern and pierced by only a few tall windows.

For centuries this was the heart of the Venetian Republic: the home of the Doge, its elected ruler, and the seat of its councils, its law courts and its prison. Have a look at the columns of the arcade at ground level. Each has a carved capital, full of figures, virtues and vices, the months, the trades. Most of what you see are copies. In the restoration of the eighteen seventies dozens of the worn originals were taken down and put inside, where you can still see them.

Now look along to the far end, by the basilica. That tall carved gateway is the Porta della Carta, built between fourteen thirty-eight and fourteen forty-two by Giovanni and Bartolomeo Bon, the ceremonial way in. Giacomo Casanova left by it after escaping from the prison cells under the lead roof, the Piombi, which is a fairly stylish way to leave a jail.

Inside, the Great Council Hall burned in fifteen seventy-seven, taking with it paintings by Bellini, Carpaccio and Titian. It was rebuilt, and Tintoretto painted Paradise across the wall behind the Doge's throne. Round the top of the room run the portraits of the Doges, except one. Marino Faliero tried to seize power in thirteen fifty-five, and where his face should be, there's a black cloth.

[beat]

What I love about that heavy wall on its lace of arches is the message. One of the great powers of the Mediterranean chose not to build a fortress. It built something that looks as if it's floating.

Before you go in, walk down to the waterfront and onto the little bridge, the Ponte della Paglia. Look along the canal at the side of the palace and you'll see the Bridge of Sighs, the covered bridge that took prisoners across to the jail.""",
respell=[["Doge's","dohjes"],["Doge","dohj"],["Doges","dohjes"],["Piazzetta","pyatsetta"],["Porta della Carta","porta della karta"],["Bartolomeo Bon","bartolomayo bon"],["Giovanni","jovannee"],["Giacomo Casanova","jakomo kazanova"],["Piombi","pyombee"],["Carpaccio","karpatcho"],["Tintoretto","tintoretto"],["Marino Faliero","mareeno falyairo"],["Ponte della Paglia","pontay della palya"]],
sources=["https://en.wikipedia.org/wiki/Doge%27s_Palace","https://it.wikipedia.org/wiki/Palazzo_Ducale_(Venezia)"],
notes=["Orientation: the palace forms the east side of the Piazzetta; facing it, the lagoon (Molo) is to the right, the basilica to the left. The owner's coordinate reverse-geocodes to 1 San Marco, the palace.","Capitals: 42 replaced by copies after 1876 (en.wikipedia); the script says 'dozens' and 'the eighteen seventies'.","Porta della Carta 1438-1442 by Giovanni and Bartolomeo Bon; Casanova left by it: en.wikipedia.","1577 fire and lost works (Bellini, Carpaccio, Titian among others), Tintoretto's Paradiso behind the throne, Faliero's black cloth (coup of 1355): en.wikipedia.","The palace is a museum with timed entry; no opening details are given in the script."])

T["84_buco-del-piombo"] = dict(
title="Buco del Piombo, Erba",
clean="""This cave is so big that people compare it to the Duomo of Milan. Wait until you see the front door.

You're in the Valle Bova, above Crevenna, high over the town of Erba, at the foot of a sheer cliff of pale grey limestone. Ahead of you the cliff opens into an enormous mouth, forty-five metres high and thirty-eight wide, and set into it, like a cork in a bottle, is a stone building with windows.

That's the first thing to have a look at. In the Middle Ages someone built a wall across the entrance and turned the cave into a fortress. You can still see the square holes in the rock where the beams of its floors once rested. For centuries the people of Erba came up here to hide, in times of war and of plague. Today the old building holds a small museum, a ticket office and a café.

The name means the hole of lead. It isn't about any mine. Look at the walls inside the entrance and you'll see why: the limestone has been turned grey by the tiny living things growing on it, very much the colour of lead.

Long before people, the cave belonged to bears. A whole layer of cave bear bones was found inside, and later the Romans used it too. By the nineteenth century it was a fashionable outing. The viceroy Eugène de Beauharnais came, and on the first of September eighteen eighty, so did Queen Margherita.

[beat]

What's worth knowing, standing here, is how close it came to being lost. It was shut for twelve years, tangled up in rockfalls and paperwork, and only opened again in May twenty twenty-four, with cavers leading the visits. Beyond the entrance run more than four hundred metres of passages, still not fully explored.

Check before you come, because visits are guided and not every day. And if you have time afterwards, follow the path down the Valle Bova. On the far side, hidden in the woods, is a much smaller cave, the Tamborin, where people lived thousands of years before the bears were forgotten.""",
respell=[["Buco del Piombo","bookoh del pyombo"],["Valle Bova","vallay bova"],["Crevenna","krevenna"],["Erba","airba"],["Duomo","dwomo"],["Eugène de Beauharnais","oozhen duh boharnay"],["Margherita","margereeta"],["Tamborin","tamboreen"]],
sources=["https://showcaves.com/english/it/showcaves/Piombo.html","https://www.ilgiorno.it/lecco/cronaca/il-buco-del-piombo-la-caverna-e-accessibile-59624e53","https://fondoambiente.it/luoghi/valle-bova-val-caino-e-grotta-del-buco-del-piombo"],
notes=["Entrance 45 m high and 38 m wide: Il Giorno (2024) and showcaves.com agree. The Duomo comparison is Il Giorno's.","Name from the lead-grey colour of the limestone (microorganisms): showcaves.com.","Medieval fortification with beam holes, refuge in war and disease, cave bear deposit ('Banco degli Orsi'), late Roman use: showcaves.com.","Queen Margherita on 1 September 1880: Il Giorno. Beauharnais visit: the Valle Bova page.","Reopened May 2024 after twelve years, with speleologists; more than 400 m of passages: Il Giorno.","Tamborin cave on the opposite side of the valley: the Valle Bova page.","Owner's coordinate is on the waterfall path about 100 m from the cave-entrance node in OpenStreetMap (45.82594, 9.19896)."])

T["85_villa-necchi-campiglio"] = dict(
title="Villa Necchi Campiglio, Milan",
clean="""In the middle of Milan, behind a garden wall, a family of sewing-machine makers built themselves a heated swimming pool in the nineteen thirties. It was only the second pool in the whole city.

You're in the garden on Via Mozart, a few streets from the centre. In front of you is the pool, long and blue, and beyond it a pale, flat-fronted house with tall windows and a terrace, set well back from the street, as if it would rather not be noticed.

It was built between nineteen thirty-two and nineteen thirty-five by the architect Piero Portaluppi, for two sisters, Nedda and Gigina Necchi, and Gigina's husband, Angelo Campiglio. They came from Pavia, and they'd done very well out of enamelled cast iron and sewing machines. They wanted everything new: a lift, a dumbwaiter, intercoms, telephones in the rooms, and the pool, the first in Milan on private land. Money, it's fair to say, was not the problem.

Have a look at the clean lines of the house. That's Portaluppi, and the brand-new taste for stripped-back modern design. Then, from nineteen thirty-eight, the family asked Tomaso Buzzi to soften it, and inside some rooms turned eighteenth-century and frilly. The house wears both styles at once, which I rather enjoy.

There are darker chapters too. During the war the family left, and the house was requisitioned as the home of Alessandro Pavolini, one of the leaders of the last Fascist government. After that the British moved in, then the Dutch consul, before the family got it back.

[beat]

And here's the thing. The sisters had no children, and they worried about what would become of it. So they left it to be opened to the public, exactly as they'd lived in it. It opened in May two thousand and eight, and film-makers have loved it ever since. Luca Guadagnino shot I Am Love here, and Ridley Scott used it in House of Gucci.

Before you leave, step into the winter garden, the glass veranda full of plants, and look for the little guest room kept for a prince who designed sets for La Scala. Then walk out past the tennis court, and look back at how quiet the house manages to be.""",
respell=[["Necchi Campiglio","neckee kampeelyo"],["Necchi","neckee"],["Campiglio","kampeelyo"],["Via Mozart","veea motsart"],["Piero Portaluppi","pyairo portaloopee"],["Portaluppi","portaloopee"],["Nedda","nedda"],["Gigina","jeejeena"],["Angelo","anjelo"],["Pavia","paveea"],["Tomaso Buzzi","tomazo bootsee"],["Alessandro Pavolini","alessandro pavoleenee"],["La Scala","la skahla"],["Luca Guadagnino","looka gwadanyeeno"],["Ridley Scott","ridley scott"]],
sources=["https://en.wikipedia.org/wiki/Villa_Necchi_Campiglio","https://it.wikipedia.org/wiki/Villa_Necchi_Campiglio","https://fondoambiente.it/luoghi/villa-necchi-campiglio"],
notes=["Built 1932-1935 by Piero Portaluppi; lift, dumbwaiter, intercoms, telephones, heated pool; the second pool in Milan after the municipal one and the first on private land: Wikipedia (en, it).","Tomaso Buzzi from 1938: Wikipedia.","Wartime requisition as Alessandro Pavolini's residence, then the British, then the Dutch consul: it.wikipedia.","Bequest and opening in May 2008: Wikipedia. The recipient is not named, per owner instruction.","I Am Love (2009, Luca Guadagnino) and House of Gucci (2021, Ridley Scott): en.wikipedia.","The 'Camera del principe' was kept for Prince Henry of Hesse (Enrico d'Assia), a set designer for La Scala: it.wikipedia."])

T["86_idrovora-di-sassu"] = dict(
title="Idrovora di Sassu, Arborea",
clean="""The ground you're standing on used to be under water. This building is why it isn't.

You're on the road out of Arborea, on the flat land south of Oristano, where long straight canals run between the fields. In front of you, standing out above the flat land, is a pale building with a tower and rounded wings, which looks a bit like a ship, and a bit like a power station drawn by a futurist painter.

It's a drainage pumping station, an idrovora, and it opened on the fourth of November, nineteen thirty-four, in front of the most senior Fascist officials on the island. All of this flat country was once marsh and lagoon. The pond of Sassu alone covered about two thousand hectares, and it was a breeding ground for malaria. From nineteen eighteen a company drained it field by field, and built a brand-new town to farm it. They called the town Mussolinia. After the war, unsurprisingly, it became Arborea.

Have a look at the shape. The engineer, Flavio Scano, gave it a tall central block with long windows and two half-round towers either side. Now look at the small tower for the power lines. On its flat roof sits a little square block ringed with teeth, which is meant to look like an electrical transformer. And all over, as decoration, you'll find the bundle of rods that was the Fascist emblem.

[beat]

What's worth knowing, standing here, is that it still works. The pumps inside are still keeping the water out, ninety years on. A machine, dressed up as a monument to the regime that built it, that has quietly gone on outlasting it. When it turned ninety, in twenty twenty-four, people were let inside to see it for the first time.

It's a working site, so the gates are usually closed. But follow the canals back towards the centre of Arborea and look out for the museum of the land reclamation. It tells the story of how a swamp became one of the most orderly farm landscapes in Italy, and you'll see the grid of it all around you as you drive.""",
respell=[["Idrovora di Sassu","eedrovora dee sassoo"],["idrovora","eedrovora"],["Sassu","sassoo"],["Arborea","arboraya"],["Oristano","oristahno"],["Mussolinia","moosoleenya"],["Flavio Scano","flahvyo skahno"]],
sources=["https://www.sardegnacultura.it/en/articles/arborea-idrovora-di-sassu","https://www.unionesarda.it/news-sardegna/oristano-provincia/arborea-festeggiati-i-90-anni-dellidrovora-di-sassu-g2cx5o75","https://www.lonelyplanet.com/italy/sardinia/arborea/attractions/mub-museo-della-bonifica/a/poi-sig/1457759/1325266"],
notes=["COORDINATE: the owner supplied 39.93087, 8.56061, which reverse-geocodes to SP 5 near Cabras, about 12 km north. OpenStreetMap has a named node 'Idrovora Sassu' on the SP 49 at Arborea (39.82326, 8.57722), matching the sources (SP 49, Arborea, 09092). The shortlist uses the OSM point; confirm with the owner.","Inaugurated 4 November 1934 with Fascist authorities; Sassu pond about 2,000 ha; engineer Flavio Scano; transformer-like toothed block on the power-line tower; fasces as decoration: Sardegna Cultura.","Società Bonifiche Sarde from 1918: Sardegna Cultura caption.","Opened to the public for the first time for its 90th anniversary (2024): L'Unione Sarda.","'Still working': L'Unione Sarda describes the pumps as draining the canals of Arborea; treat 'still works' as current per that 2024 report.","Museum: MUB, Museo della Bonifica, Arborea (Lonely Planet listing); opening hours not checked."])

for k, v in T.items():
    (src / f"{k}.json").write_text(json.dumps(v, ensure_ascii=False, indent=1))
    print(k)
