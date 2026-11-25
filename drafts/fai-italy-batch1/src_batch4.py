import json, pathlib
S = pathlib.Path("src"); T = {}
FAI=["FAI","fy"]

T["32_villa-dei-vescovi"] = dict(title="Villa dei Vescovi",
clean="""Before Palladio, there was this. A bishop's house on a hilltop, built to behave like a Roman villa.

From the drive below, look up the slope through the vineyard. The villa sits on its terrace at the top of a small hill in the Euganean Hills, with a great open loggia running along its upper floor, and the countryside of the Veneto rolling away around it.

It was commissioned in the early fifteen hundreds by the bishops of Padua, and the man who made it happen was Cardinal Francesco Pisani, with the nobleman Alvise Cornaro managing the works and the estate. The design came from the Veronese architect Giovanni Maria Falconetto. When he died in fifteen thirty-five, his pupil Andrea da Valle built it, and the painter and architect Giulio Romano almost certainly had a hand in it too. The heavy rusticated stone of the ground floor may be his.

The model was the Roman house, built round a central courtyard, with a gallery above where you'd walk and talk. It was meant to run round all four sides. Only two survive, but you can still do the walking.

Inside, look for the work of a Flemish painter, Lambert Sustris, who arrived from Rome in fifteen forty-one. He filled the rooms with myths and with landscapes full of Roman ruins: Ariadne abandoned on Naxos, Orpheus and Eurydice, Apollo flaying the satyr Marsyas. One room is named after a small boy eating grapes.

[beat]

And here's the thing about these walls. In sixteen thirty they were whitewashed over, and the paintings were forgotten for more than three hundred years. They came back to light in the twentieth century, after the bishops sold the villa in nineteen sixty-two. The new owner, Vittorio Olcese, bought it on the advice of the great art historian Roberto Longhi, and restored the frescoes. His family gave it to the FAI in two thousand and five.

When you've seen the rooms, walk the length of the western loggia, where painted boys climb through trellises and fake Roman statues stand in painted niches. Then go down to the old stables, where the wine shop pours the wines of these hills.""",
respell=[["Vescovi","ves ko vee"],["Palladio","pa lah dee oh"],["Euganean","yoo gay nee an"],["Veneto","ven eh toh"],["Padua","pad yoo ah"],["Francesco Pisani","fran ches ko pee zah nee"],["Alvise Cornaro","al vee zeh kor nah ro"],["Giovanni Maria Falconetto","jo van nee maria fal ko net toh"],["Falconetto","fal ko net toh"],["Andrea da Valle","an dray ah da val leh"],["Giulio Romano","joo lee oh ro mah no"],["Lambert Sustris","lam bert soos triss"],["Ariadne","ah ree ad nee"],["Naxos","nax oss"],["Eurydice","yoo rid i see"],["Marsyas","mar see as"],["Vittorio Olcese","vee tor ee oh ol cheh zeh"],["Roberto Longhi","ro bair toh lon ghee"],FAI],
sources=["https://fondoambiente.it/luoghi/villa-dei-vescovi","https://fondoambiente.it/villa-dei-vescovi-eng","https://fondoambiente.it/il-fai/beni/grazie-a-chi-sostiene-villa-dei-vescovi/","https://it.wikipedia.org/wiki/Villa_dei_Vescovi"],
notes=["The donors were Maria Teresa Olcese Valoti and Pierpaolo Olcese, in 2005; the villa opened in 2011.","Giulio Romano's involvement is 'quasi certo' (Wikipedia), and the rustication is only possibly his; the script hedges both.","Sustris arrived in Padua in 1541 (Wikipedia).","The 1630 whitewash and the 1966 rediscovery are from Wikipedia; the script says 'twentieth century'.","FAI also offers a multimedia room narrated by Marco Paolini; it isn't mentioned."])

T["33_madonna-della-corona"] = dict(title="Santuario Madonna della Corona",
clean="""Seven hundred and seventy-four metres up, on a ledge in a cliff, someone decided to build a church. The mountain is part of the wall.

Come down from Spiazzi on foot, along the road with its bronze Stations of the Cross, through the tunnel cut into the rock in nineteen twenty-two, and stop on the walkway where the sanctuary comes into view. It clings to the vertical face of Monte Baldo, with the valley of the Adige dropping away beneath you.

Hermits linked to the abbey of San Zeno in Verona were living on this cliff around the year one thousand. By the twelve hundreds there was a small chapel. In the fourteen thirties the site passed to the Knights of Malta, who kept it for nearly four hundred years.

The heart of the place is a small statue, a Pietà about seventy centimetres high, carved in local stone and painted, with the Virgin holding the dead Christ. An inscription on it gives the year fourteen thirty-two and the name of Lodovico Castelbarco, and it's traditionally taken as his gift. There's a lovelier story, that angels carried the statue here from Rhodes in fifteen twenty-two as the island fell to the Ottomans. The sanctuary itself calls that a pious tradition, and gently points out that the dates don't work.

[beat]

The church you'll walk into is surprisingly recent. It was rebuilt between nineteen seventy-five and nineteen seventy-eight, and at the back, the bare rock of the mountain forms part of the apse. Set into it, around the Pietà, is a bronze crown of thorns with golden rays and groups of angels. John Paul the Second came here in nineteen eighty-eight.

Look, too, for the ex-votos, the painted thank-you tablets left by people who believed their prayers were answered. There are a hundred and sixty-seven, and the oldest is from fifteen forty-seven.

If you've the legs and the time, there's another way up: the Path of Hope, from Brentino in the valley below, climbing about six hundred metres on steps cut into the rock. It takes an hour and a half, and there's no bus back, so it's a walk for the committed.""",
respell=[["Madonna della Corona","ma don na del la ko ro na"],["Spiazzi","spyat see"],["Monte Baldo","mon tay bal doh"],["Adige","ah dee jeh"],["San Zeno","san zeh no"],["Verona","veh ro na"],["Pietà","pyeh tah"],["Lodovico Castelbarco","lo doh vee ko kas tel bar ko"],["Ottomans","ot o mans"],["Brentino","bren tee no"],["ex-votos","ex vo toes"]],
sources=["https://www.madonnadellacorona.it/","https://www.madonnadellacorona.it/presentazione-e-storia/","https://www.madonnadellacorona.it/come-raggiungere-il-santuario/","https://it.wikipedia.org/wiki/Santuario_della_Madonna_della_Corona"],
notes=["Altitude 774 m (official); Wikipedia says 775.","The official site calls the 1522 Rhodes legend a 'pia tradizione' contradicted by the dating.","The rock forming part of the apse is my reading of 'the apse rock' where Bonente's bronze is set; check it on site.","The Path of Hope: CAI 73, about 600 m of climb, about 1 h 30. The step count (1,614, Wikipedia) isn't used.","Knights of Malta: 1434–37 to 1806."])

T["34_palazzo-della-ragione"] = dict(title="Palazzo della Ragione, Padua",
clean="""The roof over your head is a boat, turned upside down. Underneath it is one of the largest hanging halls in Europe.

Stand in the middle of the great hall and look up. The wooden ceiling curves overhead like the hull of an enormous ship. All around the walls, in tier after tier, are hundreds of painted panels. And at one end there's a huge wooden horse.

The palace went up from twelve eighteen, as Padua's hall of justice, and between thirteen oh six and thirteen oh nine a friar called Giovanni degli Eremitani knocked three rooms into one and roofed it in larch. The hall is eighty-two metres long and twenty-seven wide, and nearly forty metres to the top of the roof. It's raised high above the street, which is why it's called a hanging hall.

Now the walls. There are three hundred and thirty-three panels, and they're a map of how the medieval mind thought the universe worked: the months, the signs of the zodiac, the planets, the trades, all tied together by the astrology of the Paduan philosopher Pietro d'Abano. The first cycle was attributed to Giotto and his workshop. It was lost in a fire in fourteen twenty, and painted again by Nicolò Miretto and his collaborators.

The horse is a copy of the horse from Donatello's great bronze of Gattamelata, outside the Basilica of Saint Anthony. It was made for a joust in the fourteen sixties and it stands nearly six metres high.

[beat]

And then, easy to miss, there's a stone. The stone of shame. A bankrupt had to strip down to his shirt and underpants and sit on it three times, saying cedo bonis, I give up my goods. It's a reminder that this was a court as well as a cathedral of astrology.

Since two thousand and six there's also been a Foucault pendulum swinging in the hall, proving that the earth turns.

When you come down, walk through the arcades beneath the hall. The markets of Piazza delle Erbe and Piazza della Frutta are on either side, and the covered market underneath has been feeding Padua for centuries.""",
respell=[["Palazzo della Ragione","pa lat so del la ra jo neh"],["Padua","pad yoo ah"],["Paduan","pad yoo an"],["Giovanni degli Eremitani","jo van nee del yee eh reh mee tah nee"],["Pietro d'Abano","pyeh tro dah ba no"],["Giotto","jot toh"],["Nicolò Miretto","nee ko loh mee ret toh"],["Donatello","don a tel lo"],["Gattamelata","gat ta meh lah ta"],["cedo bonis","cheh doh bo niss"],["Foucault","foo ko"],["Piazza delle Erbe","pyat sa del leh air beh"],["Piazza della Frutta","pyat sa del la froot ta"]],
sources=["https://padovamusei.it/it/sedi-monumentali/palazzo-ragione/il-palazzo-ragione","https://www.padovamusei.it/","https://padovamusei.it/it/biglietti-orari-musei","https://it.wikipedia.org/wiki/Palazzo_della_Ragione_(Padova)"],
notes=["Dimensions 82 × 27 m are official; 'nearly forty metres' high is Wikipedia's.","333 panels is the official figure.","Fire in 1420 (official and Wikipedia; Wikipedia also says 1430 elsewhere).","Horse: Wikipedia says commissioned by the Capodilista for a 1466 parade, 5.75 m high; the official site says made by Annibale Capodilista for a joust. The script says 'a joust in the fourteen sixties'.","The pendulum since 2006 is official.","The markets are from Wikipedia."])

T["35_san-giorgio-maggiore"] = dict(title="San Giorgio Maggiore",
clean="""Everyone who stands on the waterfront at San Marco photographs this church across the water. Come over here, and you get to look back.

Step off the boat at the San Giorgio stop and turn to face the church. A gleaming white front, with columns and triangular pediments stacked one in front of another, and a dome rising behind. Then turn round. Across the basin, the Doge's Palace and the bell tower of San Marco.

The island has belonged to Benedictine monks since nine eighty-two, when the doge gave it to a monk called Giovanni Morosini to found a monastery. They're still here.

The church is Andrea Palladio's. He was called in to rebuild the monks' refectory in fifteen sixty, and then the church itself, which began in fifteen sixty-six. The dome went up in fifteen seventy-six, the choir was finished in fifteen ninety-one. Palladio died in fifteen eighty, so he never saw it done, and the front you're looking at was built about thirty years after his death. It's based on his ideas, but scholars think it isn't quite what he'd drawn.

Inside, it's all light and grey stone and white plaster. Go up to the chancel and look for two big late paintings by Tintoretto: The Last Supper, and The Gathering of the Manna.

[beat]

One more piece of history happened here. In seventeen ninety-nine, the cardinals came to this island to elect a pope. The conclave ran into eighteen hundred, and the new pope, Pius the Seventh, was crowned in this church.

The bell tower, seventy-five metres high, has a lift to the top and one of the best views in Venice, though it's been closed for maintenance lately, so check before you queue. If it's shut, simply walk round to the back of the island and look across the lagoon to the Lido. It's the quietest corner of central Venice.""",
respell=[["San Giorgio Maggiore","san jor jo mad jaw ray"],["San Giorgio","san jor jo"],["San Marco","san mar ko"],["Giovanni Morosini","jo van nee mo ro see nee"],["Andrea Palladio","an dray ah pa lah dee oh"],["Palladio","pa lah dee oh"],["Tintoretto","tin to ret toh"],["Pius","pie us"],["Lido","lee doh"],["Doge","doj"]],
sources=["https://it.wikipedia.org/wiki/Basilica_di_San_Giorgio_Maggiore","https://www.abbaziasangiorgio.it/","https://www.cini.it (HTTP 403, not read)"],
notes=["Facade: built about 30 years after Palladio's death by Simone Sorella with Scamozzi advising; 'not quite what he'd drawn' follows Wikipedia's 'recent studies'.","Palladio died in 1580; this is general knowledge, consistent with 'thirty years after' a facade of about 1610.","The bell tower is temporarily closed (official notice, undated).","The Fondazione Cini and the Borges labyrinth were not verifiable, so they're omitted."])

T["36_caffe-pedrocchi"] = dict(title="Caffè Pedrocchi, Padua",
clean="""For more than eighty years this café never closed, day or night. People called it the café without doors.

Stand on Via Otto Febbraio and look at the building. It's a long, pale, columned thing, more like a temple than a coffee shop, and at one end there's a pointed neo-Gothic wing that looks as if it wandered in from a different century. That's the Pedrocchino, added in eighteen thirty-nine for the pastry kitchen.

The café belonged to Antonio Pedrocchi, who inherited his father's coffee shop and dreamed of something monumental. He hired the Venetian architect Giuseppe Jappelli, and the Caffè Pedrocchi opened in eighteen thirty-one. The French writer Stendhal sat here and said it was in Padua that he first began to see life the Venetian way, with women sitting in cafés.

Inside, there are three famous rooms in a row, white, red and green, the colours of the Italian flag, given their hangings after the Veneto joined Italy. Have a look at the green room in particular. By tradition, this was where you could sit and read the newspapers without having to buy anything, so it was full of penniless students, and people say it's where the Italian phrase for being broke, essere al verde, being in the green, comes from. I can't swear to that one, but I'd like it to be true.

[beat]

The students mattered here. On the eighth of February eighteen forty-eight, a student was wounded inside the café during the uprising against Austrian rule, a spark for the revolts that followed. In the white room, you'll find what's said to be a bullet hole in the wall.

Upstairs, the first floor opened in eighteen forty-two, with rooms in every style Jappelli could think of: Etruscan, Greek, Roman, Gothic, Moorish and Egyptian. It now holds the city's Museum of the Risorgimento.

Before you go, order the house speciality, the caffè Pedrocchi. There's one rule, and the café insists on it: you don't add sugar, and you don't stir. They'll tell you why.""",
respell=[["Caffè Pedrocchi","kaf feh peh drok kee"],["Pedrocchi","peh drok kee"],["Pedrocchino","peh drok kee no"],["Via Otto Febbraio","vee ah ot toh feb bry oh"],["Antonio","an toe nee oh"],["Giuseppe Jappelli","joo sep pay yap pel lee"],["Jappelli","yap pel lee"],["Stendhal","sten dal"],["Padua","pad yoo ah"],["Veneto","ven eh toh"],["essere al verde","es seh reh al vair deh"],["Etruscan","eh trus kan"],["Risorgimento","ree sor jee men toh"]],
sources=["https://www.caffepedrocchi.it/","https://www.caffepedrocchi.it/la-storia/","https://www.caffepedrocchi.it/le-sale/","https://www.caffepedrocchi.it/contatti/","https://it.wikipedia.org/wiki/Caff%C3%A8_Pedrocchi"],
notes=["'Open day and night until 1916' and 'café without doors' are Wikipedia-only.","The 1839 Pedrocchino is Wikipedia-only.","The Stendhal quote is from the official history page; the book isn't named because the sources disagree.","The 'essere al verde' etymology is Wikipedia's claim; the script frames it as hearsay.","The bullet hole is Wikipedia, unfootnoted; the script says 'what's said to be'.","'Don't sugar, don't stir' is from the official homepage."])

T["37_casa-del-petrarca"] = dict(title="Casa del Petrarca, Arquà Petrarca",
clean="""One of the greatest poets ever to write in Italian came to this hillside to grow old. These days the whole village carries his name.

You're on Via Valleselle in Arquà Petrarca, in the Euganean Hills. Find the gate of the house, a stone building from the twelve hundreds that still keeps much of its fourteenth-century character, set on the slope above the village.

Francesco Petrarca, Petrarch to us, came here in thirteen sixty-nine. The house may have been a gift from Francesco da Carrara, the lord of Padua, and Petrarch spent his last five years here, reading, writing and gardening. He died here, in his little study, on the night of the eighteenth to the nineteenth of July, thirteen seventy-four. Tradition says he was found with his head resting on his books.

Inside, the rooms were painted in the fifteen hundreds with scenes from his own poems, from the Canzoniere, the songs for Laura, and from his Latin epic Africa. In the central room, look for the scenes from his song of metamorphoses, where love keeps changing the poet into something new.

Then find the cat. In a niche is a mummified cat, and for centuries visitors were told it was Petrarch's own. It's a lovely story. It also seems to have been invented in the sixteen hundreds by one of the later owners of the house, a man called Girolamo Gabrielli, who knew exactly what his visitors wanted.

[beat]

And I rather like that. Even the fake bits of this house are about love for the poet.

When you leave, walk down into the village to the parish church of Santa Maria Assunta. In front of it stands Petrarch's tomb, a sarcophagus of red Verona marble raised six years after his death by his son-in-law. The Latin on it begins: this stone covers the cold bones of Francesco Petrarca. It's a very quiet end for such a famous man.""",
respell=[["Casa del Petrarca","kah za del peh trar ka"],["Arquà Petrarca","ar kwah peh trar ka"],["Via Valleselle","vee ah val leh sel leh"],["Euganean","yoo gay nee an"],["Francesco Petrarca","fran ches ko peh trar ka"],["Petrarca","peh trar ka"],["Petrarch","pet rark"],["Francesco da Carrara","fran ches ko da kar rah ra"],["Padua","pad yoo ah"],["Canzoniere","kan tso nyeh reh"],["Girolamo Gabrielli","jee ro la mo ga bree el lee"],["Santa Maria Assunta","santa maria as soon ta"]],
sources=["https://it.wikipedia.org/wiki/Casa_del_Petrarca","https://padovamusei.it/it/sedi-monumentali/casa-petrarca/casa-petrarca","https://www.arquapetrarca.com/petrarca/","https://www.arquapetrarca.com/cosa-vedere/","https://www.arquapetrarca.com/"],
notes=["Arrival 1369 in all sources; the gift is hedged ('forse').","The cat being invented by Girolamo Gabrielli in the 1600s is Wikipedia's account.","Tomb: on the sagrato of Santa Maria Assunta, raised six years after his death by Francescuolo da Brossano."])

T["38_giardini-della-biennale"] = dict(title="Giardini della Biennale",
clean="""Napoleon pulled down churches to give Venice a park. Within a century, the park had turned into the most famous art show in the world.

From the entrance on the waterfront, look along the avenue into the trees. Scattered through the gardens, half hidden, are small buildings in wildly different styles. Each one belongs to a different country.

The gardens began with a decree in December eighteen oh seven, when Napoleon's government ordered Venice to have public green space. The architect Giannantonio Selva laid them out, and to make room, churches and convents were demolished, among them San Domenico and San Nicolò di Castello. The park opened in August eighteen ten.

In eighteen ninety-five the city held its first international art exhibition here, the first Biennale, and more than two hundred thousand people came. Other countries soon wanted their own buildings. Belgium was first, in nineteen oh seven. Today there are twenty-nine national pavilions in the Giardini.

So this is a park that doubles as an architecture museum. Look out for Josef Hoffmann's pavilion for Austria, from nineteen thirty-four. Gerrit Rietveld's for the Netherlands, rebuilt in nineteen fifty-three. Alvar Aalto's little prefabricated pavilion for Finland, from nineteen fifty-six. Carlo Scarpa's for Venezuela. And Sverre Fehn's Nordic pavilion of nineteen sixty-two, shared by Sweden, Norway and Finland.

[beat]

What I love is how unserious it all looks from the path. A few dozen countries, each with a little house in a Venetian garden, taking turns to tell the world who they think they are.

Since nineteen eighty the Biennale has run an architecture exhibition as well as the art one, and the pavilions open when an exhibition is on. Part of the old gardens, though, has always stayed a public park.

If the pavilions are closed, look out for Carlo Scarpa's work in the gardens. Besides the Venezuelan pavilion, he made a sculpture garden here in nineteen fifty-two, and once you've seen his way with water and concrete, you'll spot him everywhere in this city.""",
respell=[["Giardini della Biennale","jar dee nee del la bee en nah leh"],["Giardini","jar dee nee"],["Biennale","bee en nah leh"],["Giannantonio Selva","jan nan toe nee oh sel va"],["San Domenico","san doh meh nee ko"],["San Nicolò di Castello","san nee ko loh dee kas tel lo"],["Josef Hoffmann","yo sef hof man"],["Gerrit Rietveld","herrit reet felt"],["Alvar Aalto","al var al toh"],["Carlo Scarpa","kar lo skar pa"],["Sverre Fehn","svair reh fain"]],
sources=["https://it.wikipedia.org/wiki/Giardini_della_Biennale","https://www.labiennale.org/it/storia","https://www.labiennale.org/it/luoghi/giardini-della-biennale","https://www.labiennale.org/it/biglietti","https://www.labiennale.org/it"],
notes=["The 29 pavilions are the official count; Wikipedia says 30, including Qatar (2025).","Napoleonic decree 7 December 1807; opened 20 August 1810 (Wikipedia).","Free public access: Wikipedia says about 18,000 m² stayed a public garden. Nothing official says so.","Avoid dating the current exhibition: Arte 2026 closes 22 November 2026."])

T["39_villa-pisani"] = dict(title="Villa Pisani, Stra",
clean="""A hundred and fourteen rooms, one for each doge of Venice up to the man who built it.

Stand on the road by the Brenta and look at the long front of the villa across its forecourt. Columns and statues crowd the centre, and the wings stretch out on either side. This is the grandest of all the villas along the river, and it was meant to be.

It was built for the Pisani, one of the richest families in Venice. Work began in seventeen twenty-one to designs by Girolamo Frigimelica, and after his death the architect Francesco Maria Preti finished it in seventeen fifty-six. The original hundred and fourteen rooms were a tribute to Alvise Pisani, the hundred-and-fourteenth doge. Over time it grew to a hundred and sixty-eight.

Inside, go straight to the ballroom and look up. The ceiling is by Giambattista Tiepolo, the Apotheosis of the Pisani Family, the whole clan lifted into the clouds in a swirl of gods and allegories. It's the family asking to be remembered as nearly divine.

The family lost it to gambling debts, and in eighteen oh seven they sold it to Napoleon, for his stepson Eugène, the viceroy of Italy. Then came the Habsburgs, then the Savoys. Tsars and kings stayed here. And in nineteen thirty-four, it was where Mussolini and Hitler held their first official meeting.

[beat]

Which is rather a lot of history for a summer house.

Now go out into the park, fourteen hectares of it. At the end of the long pool, the stables have a grand facade like a stage set, which is more or less what it was. And somewhere in the garden is the maze, its box hedges curling round a little tower topped with a statue of Minerva. It's been here since the early seventeen hundreds.

The maze usually closes from November to March, so if you're here in spring or summer, go and get lost in it. Minerva will be waiting in the middle.""",
respell=[["Villa Pisani","villa pee zah nee"],["Pisani","pee zah nee"],["Stra","strah"],["Brenta","bren ta"],["Girolamo Frigimelica","jee ro la mo free jee meh lee ka"],["Francesco Maria Preti","fran ches ko maria preh tee"],["Alvise Pisani","al vee zeh pee zah nee"],["Giambattista Tiepolo","jam bat tees ta tee eh po lo"],["Tiepolo","tee eh po lo"],["Eugène","er zhen"],["Habsburgs","haps burgs"],["Savoys","sa voys"],["Minerva","min er va"]],
sources=["https://it.wikipedia.org/wiki/Villa_Pisani_(Stra)","https://www.villapisani.beniculturali.it (HTTP 503, not read)","https://villapisani.cultura.gov.it (HTTP 503, not read)"],
notes=["Only Wikipedia was readable because the official sites were down. Re-check before recording.","The 114 rooms 'in omaggio al 114º doge Alvise Pisani' and the 168 rooms today are from Wikipedia.","The Tiepolo title is 'Apoteosi della famiglia Pisani'.","The 1934 meeting month isn't given; the script says only 1934.","Maze closed November–March is from Wikipedia and may be outdated.","The stables 'like a stage set' follow Wikipedia's 'finta facciata' used as a stage backdrop."])

T["40_ca-giustinian"] = dict(title="Ca' Giustinian, Venice",
clean="""Verdi slept here. So did Proust. These days it's where the Venice Biennale is run.

You're at the very end of the Grand Canal, by the San Marco Vallaresso landing. The Gothic palace on the water's edge, with its pointed windows, is Ca' Giustinian. Behind you, across the water, the white dome of the Salute and the tip of the Dogana.

It was built around fourteen seventy-one for the Giustinian, one of the oldest families of the Venetian nobility. It's really two palaces joined together, the Giustinian and the Badoer-Tiepolo, which is why the front seems to go on a little longer than you'd expect. In the sixteen hundreds it passed to the Morosini, and in eighteen twenty it became a hotel, the Albergo all'Europa. Among the guests were the French writer Théophile Gautier, Marcel Proust, and Giuseppe Verdi.

In the nineteen thirties it changed again, into the city's first municipal casino, and a new hall was built for it, the Hall of Columns, with Murano mirrors and glass lights shaped like small roses. It was used until the early nineteen eighties and then shut.

[beat]

What I like is that the palace keeps reinventing itself to suit the city. Family house, hotel, casino, and now, since a full restoration in two thousand and eight and two thousand and nine, the headquarters of La Biennale di Venezia, running art, architecture, cinema, dance, music and theatre from these rooms.

The ground floor is open to everyone. There's a bookshop, and a café called L'ombra del leone, The Lion's Shadow, in the old Hall of Mirrors. Go through and find the terrace. It looks straight out over the last stretch of the Grand Canal to the Punta della Dogana and the basin of San Marco, and it's one of the few places right on the water where you can simply sit down.""",
respell=[["Ca' Giustinian","ka joo stee nee an"],["Giustinian","joo stee nee an"],["San Marco Vallaresso","san mar ko val la res so"],["San Marco","san mar ko"],["Salute","sa loo teh"],["Dogana","doh gah na"],["Badoer-Tiepolo","ba doh air tee eh po lo"],["Morosini","mo ro see nee"],["Albergo all'Europa","al bair go al leh oo ro pa"],["Théophile Gautier","tay oh feel go tee ay"],["Marcel Proust","mar sel proost"],["Giuseppe Verdi","joo sep pay vair dee"],["Murano","moo rah no"],["La Biennale di Venezia","la bee en nah leh dee veh net sya"],["L'ombra del leone","lom bra del leh oh neh"],["Punta della Dogana","poon ta del la doh gah na"]],
sources=["https://it.wikipedia.org/wiki/Ca%27_Giustinian","https://www.labiennale.org/it/luoghi/ca%E2%80%99-giustinian","https://www.labiennale.org/it/luoghi","https://www.labiennale.org/it/listituzione","https://www.labiennale.org/it/asac/informazioni"],
notes=["Built 'around 1471' (Biennale); Wikipedia says the second half of the fifteenth century.","The guests Gautier, Proust and Verdi are from Wikipedia; Turner and Chateaubriand are not supported.","Biennale HQ since 2010, after restoration in 2008–09.","The 1866 Veneto cession signed here is weakly sourced, so it's omitted.","Café L'ombra del leone in the former Sala degli Specchi, open daily 9–21 (Biennale page).","Terrace access outside café hours is not stated.","The Salute dome and Dogana tip are visible from Vallaresso: general knowledge, consistent with Wikipedia's terrace view."])

T["41_ca-pesaro"] = dict(title="Ca' Pesaro, Venice",
clean="""A duchess left this palace to Venice in her will, on one condition: that it be used for modern art.

From the San Stae landing, look along the Grand Canal to the great white palace a little way down. Its base is carved with lion heads and monstrous faces, the stone above it is cut into diamond points, and two big doorways open straight onto the water, crowned with grotesque masks and statues.

This was the palace of the Pesaro family, and it's one of the great Baroque palaces of Venice. The design is by Baldassare Longhena. Building started in sixteen fifty-nine, and it was so slow that Longhena died, in sixteen eighty-two, with the facade only up to the second floor. Antonio Gaspari finished it in seventeen ten.

The Pesaro line died out in eighteen thirty, the collections were scattered, and the palace went through other hands until it came to the Duchess Felicita Bevilacqua La Masa. In her will of eighteen ninety-eight she gave it to the city, to promote modern art and help young artists. In nineteen oh two the city opened its International Gallery of Modern Art here, and it's been here ever since.

[beat]

And here's what I love. Behind one of the most theatrical Baroque fronts in Venice is a collection of the twentieth century. Look for Rodin's Thinker, for the sculptor Medardo Rosso, for Kandinsky, and for Klimt's Judith, all gold and fury, unless she's away on loan, as she is from time to time.

On the top floor there's a second museum altogether, the Museum of Oriental Art, and the same ticket gets you in.

When you leave, take the waterbus from San Stae and look back at the palace from the water. That's how it was meant to be seen, sliding past, all those masks watching you go.""",
respell=[["Ca' Pesaro","ka peh za ro"],["Pesaro","peh za ro"],["San Stae","san stah eh"],["Baldassare Longhena","bal das sah reh lon geh na"],["Longhena","lon geh na"],["Salute","sa loo teh"],["Antonio Gaspari","an toe nee oh gas pa ree"],["Felicita Bevilacqua La Masa","feh lee chee ta beh vee lak wa la mah za"],["Rodin","ro dan"],["Medardo Rosso","meh dar doh ros so"],["Kandinsky","kan din skee"],["Klimt","klimt"],["Baroque","ba rock"]],
sources=["https://capesaro.visitmuve.it/la-sede-e-la-storia/","https://capesaro.visitmuve.it/percorsi-e-collezioni/","https://capesaro.visitmuve.it/informazioni-pratiche/","https://it.wikipedia.org/wiki/Ca%27_Pesaro"],
notes=["Construction: official 1659; Wikipedia 1628/1652. The script uses the official date.","Klimt's Giuditta II is on loan to MUVEC Mestre from 21 September 2026 to 14 February 2027, hence 'unless she's away on loan'.","Chagall's title and the oriental collection details (Enrico di Borbone, armour) were not confirmed, so they're omitted.","Bequest: official 1898 will; Wikipedia says the Comune acted on 5 December 1899."])

T["42_monte-fontana-secca"] = dict(title="Monte Fontana Secca",
clean="""In November nineteen seventeen, the front line of the First World War came up this mountain. A century later, the cows are coming back.

You're on the high pastures of the Monte Grappa massif, between the peaks of Monte Valderoa, Monte Solarolo and Monte Fontana Secca. Look around for the low stone buildings of the malga, the summer dairy farm, and then look out. On a clear day the view runs down the valley of the Piave all the way to the Venetian lagoon.

These hundred and fifty hectares of meadow and woodland were given to the FAI in twenty fifteen by Bruno and Liliana Collavo, in memory of their parents, Aldo Collavo and Erminia Secco.

But first, the war. After the defeat at Caporetto in the autumn of nineteen seventeen, Italy's line fell back to the Grappa and the Piave. On the twenty-first and twenty-second of November, the summit here was taken by the Austro-German army, after it had been defended by the Alpine troops of the Vallecamonica battalion. If you walk the paths you'll still find trenches, tunnels and memorial stones. The ridge route that links them is called the Alta Via degli Eroi, the High Way of the Heroes, and it leads to the great war memorial on the summit of Cima Grappa.

[beat]

What the FAI is doing here is quietly ambitious. Not preserving a ruin, but bringing a working mountain farm back to life, with no mains water and no mains electricity. The old herdsman's house has been restored and opened as a place to tell the story of the mountain, with a film narrated by the actress Michela Cescon. The old stalls have been rebuilt to welcome visitors. And the pastures are meant for the Burlina, a cow found nowhere but the Veneto, and close to disappearing.

Up here the dairy makes the local mountain cheeses, Morlacco and Bastardo.

Before you come, check what's open with the FAI, because the work is still going on. And then walk a stretch of the Alta Via degli Eroi. It's an extraordinary thing, to stand in a meadow full of cows and see a line of trenches running through it.""",
respell=[["Monte Fontana Secca","mon tay fon tah na sek ka"],["Monte Grappa","mon tay grap pa"],["Monte Valderoa","mon tay val deh ro ah"],["Monte Solarolo","mon tay so la ro lo"],["malga","mal ga"],["Piave","pyah veh"],["Bruno and Liliana Collavo","broo no and lee lee ah na kol lah vo"],["Aldo Collavo","al doh kol lah vo"],["Erminia Secco","air mee nee ah sek ko"],["Caporetto","ka po ret toh"],["Vallecamonica","val leh ka mo nee ka"],["Alta Via degli Eroi","al ta vee ah del yee eh roy"],["Cima Grappa","chee ma grap pa"],["Michela Cescon","mee keh la chess kon"],["Burlina","boor lee na"],["Veneto","ven eh toh"],["Morlacco","mor lak ko"],["Bastardo","bas tar doh"],FAI],
sources=["https://fondoambiente.it/luoghi/monte-fontana-secca-e-col-de-spadarot","https://fondoambiente.it/news/il-fai-apre-al-pubblico-la-malga-di-monte-fontana-secca","https://fondoambiente.it/news/monte-fontana-secca-il-progetto-di-restauro-e-valorizzazione","https://www.fondoambiente.it/news/monte-fontana-secca-nuova-vita-al-compendio-agricolo-pastorale"],
notes=["Donation year: 2015 in the header and news items; the FAI body text says 2014. The script uses 2015.","'Burlina found nowhere but the Veneto' paraphrases FAI's 'only native Veneto breed'.","Opening status is uncertain (the Stallone was due summer 2026), so the script tells listeners to check.","The shortlist coordinates were updated to FAI's map link: 45.92272, 11.80777.","'Defended by … before it was taken' compresses FAI's account; check the wording."])

T["43_ponte-vecchio-bassano"] = dict(title="Ponte Vecchio, Bassano del Grappa",
clean="""Palladio was asked for a stone bridge. He offered one, the town said no, and he gave them a wooden one instead. It's been washed away, burned and blown up since, and it keeps coming back.

Stand on the riverbank at Bassano and look at the bridge across the Brenta. A long, covered timber bridge on wooden piers, five spans, with a pitched roof and simple columns along each side, like a barn laid across the water.

There's been a bridge here since at least twelve oh nine. After a flood in fifteen sixty-seven, the town asked Andrea Palladio to rebuild it. He proposed three stone arches, and the council turned him down. So in the summer of fifteen sixty-nine he drew a wooden bridge, much like the one before, but refined, and that's the shape that has lasted.

It has had to be rebuilt again and again. A flood took it in seventeen forty-eight, and it was rebuilt to Palladio's design. Napoleon's stepson Eugène burned it in eighteen thirteen. And on the seventeenth of February nineteen forty-five, partisans blew it up. Each time, the town put back the same bridge.

It's also called the Ponte degli Alpini, the bridge of the Alpine troops. Since nineteen twenty-eight it's been dedicated to the soldiers, especially the Alpini, who crossed it on their way to the front in the First World War. There's even a popular song about it, Sul ponte di Bassano, often sung by the Alpini.

[beat]

People will tell you the Alpini rebuilt it after the last war. Strictly speaking, a building firm did, in nineteen forty-eight. But many of the workmen were former Alpini, and they wore their feathered hats on the job, and that's how the legend was born. I think it's a better story than the truth, and it might even be truer.

The bridge was restored again between twenty fifteen and twenty twenty-one, lifted about forty-five centimetres, and reopened in October twenty twenty-one.

At the end of the bridge is the Nardini distillery, founded in seventeen seventy-nine and said to be the oldest in Italy. Bassano is grappa country, so stop for a small glass, and look back at the bridge while you drink it.""",
respell=[["Ponte Vecchio","pon tay vek yo"],["Bassano del Grappa","bas sah no del grap pa"],["Bassano","bas sah no"],["Brenta","bren ta"],["Andrea Palladio","an dray ah pa lah dee oh"],["Palladio","pa lah dee oh"],["Eugène","er zhen"],["Ponte degli Alpini","pon tay del yee al pee nee"],["Alpini","al pee nee"],["Sul ponte di Bassano","sool pon tay dee bas sah no"],["Nardini","nar dee nee"],["grappa","grap pa"]],
sources=["https://it.wikipedia.org/wiki/Ponte_Vecchio_(Bassano_del_Grappa)","https://www.comune.bassano.vi.it/ (homepage only)","https://www.vivibassano.it (DNS failure, not read)"],
notes=["Only Wikipedia was readable; re-check before recording.","1209 is the first documented mention, not a construction date.","1945: Wikipedia credits partisans with the sabotage of 17 February 1945.","The 1948 rebuild was by Impresa Giulio Tessarolo & Figli; the Alpini rebuilding is a 'leggenda' (Wikipedia).","Nardini 1779, 'the oldest distillery in Italy', is a claim via nardini.it, hence 'said to be'."])

for k, v in T.items():
    if S / f"{k}.json".exists() or "35_san-giorgio" in str(S / f"{k}.json") or "38_giardini" in str(S / f"{k}.json"):
        continue  # src/*.json is now the source of truth (FAI removed 2026-11-24); never overwrite
    (S / f"{k}.json").write_text(json.dumps(v, ensure_ascii=False, indent=1))
print(len(T))
