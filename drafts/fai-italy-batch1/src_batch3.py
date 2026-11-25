import json, pathlib
S = pathlib.Path("src"); T = {}
FAI=["FAI","fy"]

T["22_aula-del-simonino"] = dict(title="Aula del Simonino",
clean="""Above the door of this house, a painted inscription still says that a blessed child was born here. It's a lie, and the FAI has kept it there on purpose.

You're on Via del Simonino, in the old centre of Trento. Look at the front of the building: the fifteenth-century windows uncovered in the restoration, and the eighteenth-century figures and lettering painted back in. The room behind it was, until recently, known as the Chapel of the Simonino.

Here's what happened. In Easter week of fourteen seventy-five, a little boy called Simon, about two years old, went missing, and was found dead in a ditch beside a house belonging to a Jewish family. The Prince-Bishop of Trento, Johannes Hinderbach, backed the accusation that the town's small Jewish community had killed him in a ritual murder. It was the old blood libel, and it had no truth in it at all.

Jewish men were arrested and tortured for months. In June that year they were executed. The women were put on trial after them. The community was expelled from Trento, and the FAI notes that Jews did not return to live in the city until nineteen ninety-two. Even at the time, a papal envoy spoke out against the accusation.

[beat]

And yet the child became a cult. Simon was venerated as a martyr for almost five hundred years, with processions, relics and chapels like this one. It wasn't until nineteen sixty-five that the cult was finally suppressed, the processions stopped, and his remains were taken away.

In twenty eighteen the house was given to the FAI by Marina Larcher Fogazzaro. Rather than tidy the story away, the foundation turned the room into a place to tell it. Inside, you listen on headphones to a sound piece of about twenty minutes, narrated by the actress Daria Deflorian.

When you leave, walk to Piazza Duomo. Since January twenty twenty-five there's been a plaque there remembering the Jews of Trento who were tortured and killed in fourteen seventy-five. It's worth standing in front of both.""",
respell=[["Simonino","see mo nee no"],["Trento","tren toh"],["Johannes Hinderbach","yo han ness hin der bahk"],["Hinderbach","hin der bahk"],["Marina Larcher Fogazzaro","ma ree na lar ker fo gat sa ro"],["Daria Deflorian","dah ree ah deh flo ree an"],["Piazza Duomo","pyat sa dwo mo"],["Via del Simonino","vee ah del see mo nee no"],FAI],
sources=["https://fondoambiente.it/luoghi/beni-fai","https://fondoambiente.it/luoghi/cappella-del-simonino","https://it.wikipedia.org/wiki/Simonino_di_Trento"],
notes=["The child's name, age and discovery date differ between FAI (Simone Lomferdorm, a little over two, found 24 March) and Wikipedia (Simon Unverdorben, about two and a half, missing 23 March). The script says 'Simon, about two years old' and 'Easter week'.","1965: FAI says papal decree; Wikipedia says Archbishop Gottardi. The script says 'the cult was finally suppressed' without naming who.","The 1992 return of Jews to Trento is FAI's claim.","The plaque in Piazza Duomo (27 January 2025) is from Wikipedia.","Eighteen men arrested (Wikipedia); the script says 'Jewish men' without a number.","Handle with care: check the final audio with the FAI team if possible."])

T["23_castello-di-avio"] = dict(title="Castello di Avio",
clean="""At the very top of this castle is a small round room where a painter showed lovers being shot through the heart with arrows. It's one of the earliest pictures of romantic love you'll find in Italy that has nothing religious about it.

From the gate, look up the hill. The castle climbs Monte Vignola in stages, with terraced vineyards at its feet, a lone tower called the Picadora partway up, and at the top the keep and the remains of the lord's palace. Below you is the Vallagarina, the valley of the Adige, the old road between Italy and the north.

It's mentioned as Castellum Ava as early as ten fifty-three. For most of its life it belonged to the Castelbarco family, vassals of the Bishop of Trento, who turned a military post into a small feudal court. In thirteen thirty-three they entertained the future Emperor Charles the Fourth here. In fourteen eleven they left it, by will, to the Republic of Venice.

Find the Guards' House first. Its walls were painted in the middle of the thirteen hundreds with battles, knights and sieges: the arts of war a young knight had to learn, shown almost like a training manual.

Then, if the keep is open, climb to the top floor and the Room of Love. It was painted around thirteen forty, in soft pinks and greens, with scenes of courtly love, and those arrows finding their mark.

[beat]

So here's the castle in a nutshell. Downstairs, how to fight. Upstairs, what you were fighting for.

In nineteen seventy-seven Countess Emanuela Castelbarco Pindemonte Rezzonico, a granddaughter of the conductor Arturo Toscanini, gave the castle to the FAI, and it opened to the public the following year.

On your way back down, stop at the Picadora tower. It's said this was where the castle carried out its hangings, which is a rather sobering thought among all those vines.""",
respell=[["Avio","ah vee oh"],["Monte Vignola","mon tay vin yo la"],["Picadora","pee ka doh ra"],["Vallagarina","val la ga ree na"],["Adige","ah dee jeh"],["Castellum Ava","kas tell um ah va"],["Castelbarco","kas tel bar ko"],["Trento","tren toh"],["Emanuela Castelbarco Pindemonte Rezzonico","eh ma noo eh la kas tel bar ko pin deh mon teh ret so nee ko"],["Arturo Toscanini","ar too ro tos ka nee nee"],FAI],
sources=["https://fondoambiente.it/luoghi/castello-di-avio","https://it.wikipedia.org/wiki/Castello_di_Sabbionara"],
notes=["The Room of Love is dated 1335–1345 by FAI; Wikipedia says mid-fourteenth century and attributes it differently. The script says 'around thirteen forty'.","The FAI page currently shows the keep (Mastio) as temporarily closed for maintenance, so the script says 'if the keep is open'.","'One of the earliest pictures of romantic love… nothing religious' paraphrases Wikipedia's 'rare example of early-fourteenth-century secular painting'. Soften it if needed.","The Picadora hangings are from Wikipedia ('in the past').","'Lovers shot through the heart' follows FAI's 'arrows piercing the heart of a lady and a knight'."])

T["24_castello-del-buonconsiglio"] = dict(title="Castello del Buonconsiglio",
clean="""The bishops who ruled Trento lived here for centuries. The castle's best-loved painting is a calendar, and one month is missing.

Stand back from the castle on Via Bernardo Clesio, so you can see how it grew. On the left, the oldest part, the Castelvecchio, with its great round tower, rebuilt in fourteen forty. Then the long Renaissance palace, and the Baroque link between them, added at the end of the sixteen hundreds.

The Renaissance palace was the work of Bernardo Cles, Prince-Bishop of Trento and cardinal, one of the great organisers of the Council of Trent. He wanted a residence fit for the gathering of the whole Catholic world, and in fifteen thirty-one he brought in painters to fill it. Among them was Girolamo Romanino from Brescia, who painted the loggia of the Lions' Courtyard. Have a look for his heroines and villains up there: Judith and Holofernes, Lucretia, Cleopatra, Samson and Delilah. It's lively, slightly wild painting for a bishop's house.

Then there's the Eagle Tower, and the reason a lot of people come. Around fourteen hundred, Bishop Giorgio of Liechtenstein had its room painted with the Cycle of the Months: the whole year of noble and peasant life in the countryside, one month at a time. The painter was probably from Bohemia. There are eleven panels, not twelve. March was lost in a fire.

[beat]

The castle has a darker memory too. In nineteen sixteen, when Trento was still Austrian, the Italian patriots Cesare Battisti and Fabio Filzi were tried here and hanged in the meadow beneath the eastern walls, now called the Martyrs' Ditch. Damiano Chiesa had been shot there that May.

When you've seen the rooms, go down to the Martyrs' Ditch. It's a quiet patch of grass under the walls, and it's the moment this bishops' castle became part of Italy's story.""",
respell=[["Buonconsiglio","bwon kon seel yo"],["Bernardo Clesio","bair nar doh kleh zee oh"],["Castelvecchio","kas tel vek yo"],["Bernardo Cles","bair nar doh kless"],["Trento","tren toh"],["Girolamo Romanino","jee ro la mo ro ma nee no"],["Brescia","bresh ya"],["Holofernes","hol oh fer neez"],["Lucretia","loo kree sha"],["Giorgio","jor jo"],["Liechtenstein","lick ten stine"],["Cesare Battisti","cheh za reh bat tees tee"],["Fabio Filzi","fah bee oh feel tsee"],["Damiano Chiesa","dah mee ah no kyeh za"]],
sources=["https://www.buonconsiglio.it/ (homepage only; history pages returned HTTP 500)","https://it.wikipedia.org/wiki/Castello_del_Buonconsiglio"],
notes=["The official history pages were down (HTTP 500), so the facts rest on Wikipedia. Re-check before recording.","Battisti and Filzi were hanged on 12 July 1916 and Chiesa was shot on 19 May 1916, all in the Fossa dei Martiri.","The Torre Aquila may be visitable by guided tour only; that isn't stated."])

T["25_muse-trento"] = dict(title="MUSE, Museo delle Scienze",
clean="""Look at the roofline and you'll see mountains. That's not an accident.

From the lawn in front of the museum, take in the whole building: long and low, with a jagged, sharply pointed roof that rises and falls like a ridge of peaks. The architect was Renzo Piano, and the outline is meant to recall the mountains of Trentino, and especially the Dolomites.

It opened in July twenty thirteen, on the site of the old Michelin factory, and Piano designed the new neighbourhood around it too, Le Albere. A tyre works became a science museum, which feels about right for a city that's always had to make the most of a narrow valley floor.

Inside, the whole museum is built on one idea, a mountain you explore from the top down. Start on the fourth floor, with the high peaks and a glacier made of real ice. Then work your way down through alpine nature, geology and the history of the people of the Alps, all the way to the lowest level, where the story becomes the history of life itself. At the western end there's a tropical greenhouse, six hundred square metres of mountain rainforest.

And running through the middle of it all is the Big Void, a tall open space that links every floor. Hanging in it are animals, as if they're flying or leaping across the gap, and the complete skeleton of a fin whale that washed up on the coast near Livorno in nineteen ninety-five.

[beat]

What I like about MUSE is that it doesn't ask you to look at science behind glass. It asks you to walk downhill through it. More than five million people have done so since it opened.

Before you start, go right up to the terrace on the fifth floor. From there you can see over Trento and along the Adige valley to the real mountains, and then the building's roof starts to make sense.""",
respell=[["MUSE","moo zeh"],["Museo delle Scienze","moo zeh oh del leh shen tseh"],["Renzo Piano","ren tso pyah no"],["Trentino","tren tee no"],["Dolomites","dol oh mites"],["Michelin","mish lan"],["Le Albere","leh al beh reh"],["Livorno","lee vor no"],["Trento","tren toh"],["Adige","ah dee jeh"]],
sources=["https://www.muse.it/","https://www.muse.it/home/scopri-il-museo/","https://www.muse.it/home/scopri-il-museo/sei-piani-di-meraviglia/","https://www.muse.it/home/pianifica-la-visita/","https://it.wikipedia.org/wiki/MUSE_-_Museo_delle_Scienze"],
notes=["Opening: 27 July 2013 (Wikipedia); the official site says July 2013. The script says July.","The mountain-profile reading is from Wikipedia; the official site says the building follows 'the metaphor of the mountain'.","LEED Gold is Wikipedia-only, so it isn't used.","The fin whale stranded near Livorno in 1995 is from Wikipedia.","'Over five million visitors' was reached by the end of 2024 (Wikipedia)."])

T["26_mart-rovereto"] = dict(title="Mart, Rovereto",
clean="""Walk in between two old palaces on the main street, and you come out under a dome the same size as the Pantheon.

You're on Corso Bettini in Rovereto. Find the narrow passage between the two eighteenth-century palazzi, Palazzo Alberti and Palazzo dell'Annona, and walk through it. You'll come out into a round piazza, open to the sky but covered by a great dome of glass and steel.

That piazza is forty metres across. The museum says it's exactly the diameter of the Pantheon in Rome, and the dome rises twenty-five metres above you. The building is by the Swiss architect Mario Botta, working with the Rovereto engineer Giulio Andreolli. The first stone went down in nineteen ninety-seven, and it opened in December two thousand and two.

I think the trick is rather clever. From the street you'd barely know it was there. Botta tucked a big modern museum in behind the historic front of the town, and gave you a doorway instead of a facade.

[beat]

Inside are five thousand square metres of galleries, and one of the most important collections of twentieth-century Italian art: Giorgio de Chirico, Carlo Carrà, Giorgio Morandi, Felice Casorati, Mario Sironi. And at the heart of it all, Fortunato Depero, the Futurist from this very region. The museum was founded partly to bring his work together with the province's own collection.

So when you leave, go and see Depero at home. The Casa d'Arte Futurista Depero is in the old town at Via Portici thirty-eight, a few minutes' walk away. It's as bright and strange as you'd hope. One ticket covers the Mart and Casa Depero, so there's no excuse.""",
respell=[["Mart","mart"],["Rovereto","ro veh reh toh"],["Corso Bettini","kor so bet tee nee"],["palazzi","pa lat see"],["Palazzo Alberti","pa lat so al bair tee"],["Palazzo dell'Annona","pa lat so del lan no na"],["piazza","pyat sa"],["Pantheon","pan thee on"],["Mario Botta","mario bot ta"],["Giulio Andreolli","joo lee oh an dreh oh lee"],["Giorgio de Chirico","jor jo deh kee ree ko"],["Carlo Carrà","kar lo kar rah"],["Giorgio Morandi","jor jo mo ran dee"],["Felice Casorati","feh lee chay ka zo rah tee"],["Mario Sironi","mario see ro nee"],["Fortunato Depero","for too nah toh deh peh ro"],["Depero","deh peh ro"],["Casa d'Arte Futurista Depero","kah za dar teh foo too rees ta deh peh ro"],["Via Portici","vee ah por tee chee"]],
sources=["https://en.wikipedia.org/wiki/Museum_of_Modern_and_Contemporary_Art_of_Trento_and_Rovereto","https://it.wikipedia.org/wiki/Museo_di_arte_moderna_e_contemporanea_di_Trento_e_Rovereto","https://www.mart.tn.it/","https://www.mart.tn.it/mart/l-architettura-122802","https://www.mart.tn.it/biglietti"],
notes=["The 40 m and 'exactly like the Pantheon' figures are the official site's claim; the Pantheon's dimensions were not independently checked.","Dome material: the official site says glass and steel; the Wikipedias say steel and plexiglass. The script uses the official wording.","The combined ticket (Mart, Casa Depero, Galleria Civica, within two months) is from the official tickets page.","The artist list is drawn from both Wikipedias."])

T["27_ponte-del-diavolo-cividale"] = dict(title="Ponte del Diavolo, Cividale del Friuli",
clean="""The townspeople made a deal with the devil to get this bridge built. Then they cheated him.

Stand on the bridge, or on the riverbank just below it, and look down at the Natisone, running a startling green between the rocks. The bridge crosses in two arches, and you'll see they aren't the same size. That's because the middle pier stands on a great natural boulder sitting in the riverbed, slightly off-centre, and the builders simply used it.

Work began in fourteen forty-two, to a design by a master builder from Bissone called Iacopo Dugaro. After him came Erardo of Villach, and then Bartolomeo delle Cisterne, who saw it through. It's twenty-two and a half metres high, and the deck was first paved in fifteen oh one, so it took most of the century.

That long, difficult build is probably where the legend comes from. The story goes that the people of Cividale couldn't manage it, so they asked the devil. He agreed to build it in return for the soul of the first living thing to cross. His mother carried the boulder for the middle pier in her apron. And in the morning, the townspeople sent across a dog. Or a cat, depending on who's telling it.

[beat]

The real drama came in the twentieth century. On the twenty-seventh of October nineteen seventeen, during the retreat after Caporetto, the Italian army blew the bridge up. It was rebuilt the following year in exactly the same form, and reopened in May nineteen eighteen. So the bridge you're standing on is a faithful copy of itself.

From here, walk up into the old town and find the Tempietto Longobardo, the little Lombard temple, built around seven sixty, with its stucco saints standing high on the wall. It's part of the UNESCO site for the Lombards in Italy, and it's one of the most extraordinary small rooms in the country.""",
respell=[["Ponte del Diavolo","pon tay del dee ah vo lo"],["Cividale del Friuli","chee vee dah leh del free oo lee"],["Cividale","chee vee dah leh"],["Natisone","na tee zo neh"],["Bissone","bis so neh"],["Iacopo Dugaro","yah ko po doo gah ro"],["Erardo","eh rar doh"],["Villach","fil lahk"],["Bartolomeo delle Cisterne","bar toh lo meh oh del leh chee stair neh"],["Caporetto","ka po ret toh"],["Tempietto Longobardo","tem pyet toh lon go bar doh"],["UNESCO","you ness co"],["Lombard","lom bard"]],
sources=["https://it.wikipedia.org/wiki/Ponte_del_Diavolo_(Cividale_del_Friuli)","https://www.cividale.com/it/il_ponte_del_diavolo","https://www.cividale.com/it/il_tempietto_longobardo","https://www.cividale.com/it/cividale_longobarda_patrimonio_dellunesco"],
notes=["The builder is Iacopo (Iacomo) Dugaro da Bissone; the contract was signed 11 December 1441.","Rebuilding: Wikipedia says Austrians, cividale.com says Germans with local workers. The script avoids naming who.","Height 22.5 m; the sources don't say whether that's above the river.","'One of the most extraordinary small rooms in the country' is my opinion, framed as the narrator's."])

T["28_basilica-di-aquileia"] = dict(title="Basilica di Aquileia",
clean="""Under your feet is a floor laid not long after Christianity stopped being illegal. It's the largest early Christian mosaic in the western world.

Step inside the basilica and look down. A carpet of mosaic stretches almost the whole length of the church: fish, birds, shepherds, inscriptions, and a great deal of sea.

It was laid by Bishop Theodore in the years just after three thirteen, when the Emperor Constantine allowed Christians to worship openly. It covers more than seven hundred and sixty square metres. For centuries nobody could see it at all. It was only brought back to light between nineteen oh nine and nineteen twelve.

Have a look for three things. First, Jonah, a story told in episodes: thrown to a sea monster, swallowed, spat out again, and finally resting under a vine. Then the Good Shepherd, with a sheep across his shoulders. And then a strange little fight between a cockerel and a tortoise. The cockerel, crowing at dawn, has long been read as the light of Christ. The tortoise, in this reading, stands for darkness, and its name in Greek was thought to come from Tartarus, the underworld.

Look in the fishing scene, too, for Theodore's own inscription. It begins Theodore, you are blessed, and it thanks him for building the church.

[beat]

Here's what I find so moving. These are some of the first Christian pictures anyone made in public, and they're not grand or solemn. They're cheerful. Fish and birds and a man getting swallowed by a whale.

The church above you came later. It was rebuilt in the Romanesque style and consecrated by Patriarch Poppo in ten thirty-one, and he raised the great bell tower outside, more than seventy metres tall.

Before you go, find the Crypt of the Excavations. There's more fourth-century mosaic down there, from Theodore's northern hall, and it's quieter, and rather more mysterious.""",
respell=[["Aquileia","ah kwee lay ah"],["Theodore","thee oh dor"],["Constantine","kon stan tine"],["Tartarus","tar ta rus"],["Patriarch Poppo","patriarch pop poh"],["Poppo","pop poh"],["Romanesque","ro man esk"]],
sources=["https://www.basilicadiaquileia.it/","https://www.basilicadiaquileia.it/it/basilica/storia","https://www.basilicadiaquileia.it/it/15767/orari","https://www.basilicadiaquileia.it/it/15451/visite-individuali","https://it.wikipedia.org/wiki/Basilica_di_Santa_Maria_Assunta_(Aquileia)"],
notes=["'Largest early Christian mosaic in the western world, 760 m²' is the official site's claim.","The cockerel and tortoise interpretation and the Tartarus etymology are from Wikipedia and are framed as interpretation.","Bell tower 'over 70 m' (Wikipedia verbatim); 73 m is unverified.","Aquileia's Roman history isn't covered by the sources read, so it is left out."])

T["29_mausoleo-di-teodorico"] = dict(title="Mausoleo di Teodorico",
clean="""The roof of this building is one single stone, more than two hundred tonnes of it, and somebody got it up there in the sixth century.

From the lawn outside, walk round until you can see the whole thing. Two storeys of pale stone blocks, both ten-sided, the lower one with deep arched recesses. And on top, a shallow dome, ten metres seventy-six across, carved from one piece of stone.

This is the tomb of Theodoric the Great, the Ostrogoth king who ruled Italy from Ravenna. It was built around five twenty, of stone from Aurisina near Trieste, laid dry, without mortar. Nobody is quite sure how they lifted the dome. The usual estimate is around two hundred and thirty tonnes, and newer calculations put it nearer two hundred and ninety.

Now look along the rim of the dome. Those twelve stone handles probably helped with moving and lifting it, and they carry the names of eight apostles and the four evangelists. Then look for the crack running across it. Legend says lightning split the dome and killed Theodoric while he was sitting inside, as punishment for his sins. He was actually dead and buried by then, but it's a good story.

Inside the upper room is a great tub of red porphyry, which tradition says held his body. His remains didn't stay. When the Byzantines took Ravenna, the tomb was turned into a chapel, and the king's bones were removed and scattered.

[beat]

So it's a building that's lost the one thing it was built to hold, and still looks entirely certain of itself.

Before you leave, walk round the outside of the upper storey and look for the band of carving that runs round it, a pattern like a row of pincers. It's the only decoration in Ravenna taken from Gothic goldwork, the jewellery of Theodoric's own people, a little signature from the Goths in a city full of Byzantine mosaics.""",
respell=[["Mausoleo di Teodorico","mow zo leh oh dee teh oh doh ree ko"],["Theodoric","thee odd or ick"],["Ostrogoth","oss tro goth"],["Ravenna","ra ven na"],["Aurisina","ow ree zee na"],["Trieste","tree est"],["porphyry","por fur ee"],["Byzantines","biz an teens"],["Byzantine","biz an teen"]],
sources=["https://it.wikipedia.org/wiki/Mausoleo_di_Teodorico","https://www.turismo.ra.it/cultura-e-storia/monumenti-unesco/mausoleo-di-teodorico","https://www.ravennamosaici.it/ (does not cover this monument)"],
notes=["The stone is Aurisina, not Istrian, per both sources. Aurisina 'near Trieste' is general knowledge.","Weight: Wikipedia 230 t, tourism site 290 t (newer calculations); both are given.","The date around 520 is the tourism site's figure; Wikipedia hedges.","The pincer frieze is from Wikipedia only.","'He was actually dead and buried by then' is my rationalising aside; the legend has him killed by the lightning."])

T["30_sant-apollinare-in-classe"] = dict(title="Sant'Apollinare in Classe",
clean="""Out here among the fields south of Ravenna is a church with a meadow painted on the end wall, and it's the greenest thing you'll see indoors all year.

Walk down the nave, between the two rows of marble columns, and stop where you can take in the whole apse ahead of you. Below, a green valley full of rocks, bushes and birds. In the middle, a figure in white with his arms raised. Above, a great starry disc with a jewelled cross.

This is the basilica of Saint Apollinaris, the first bishop of Ravenna, and that's him, praying, at the centre of the meadow. It was consecrated on the ninth of May, five forty-nine, by Maximian, the first archbishop of Ravenna, and it was paid for by a banker called Julian Argentarius.

Have a look at the sheep. There are twelve white lambs either side of Apollinaris, and they stand for the twelve apostles. Higher up, three more lambs gaze up towards the cross, and they're thought to be Peter, James and John. Either side of the disc, in the clouds, are Moses and Elijah. Put those together and the scene is probably a symbolic picture of the Transfiguration, the moment the three disciples saw Christ shining on the mountain. And right at the centre of the cross, in a small round medallion, is the face of Christ himself.

[beat]

What I love about it is that it doesn't show the miracle at all. No blinding figure, no terrified disciples. Just a cross in the stars, three sheep looking up, and a meadow in flower. It trusts you to know the story.

The columns either side of you are of Proconnesian marble, from an island in the Sea of Marmara, twelve on each side. The church has been part of Ravenna's UNESCO World Heritage site since nineteen ninety-six.

When you leave, walk out into the grounds and look back at the round bell tower, from the ninth century, with its windows getting wider as they go up: one opening, then two, then three. It's one of the loveliest silhouettes in Romagna.""",
respell=[["Sant'Apollinare in Classe","san tap pol lee nah reh in klas seh"],["Apollinaris","ap ol in air iss"],["Ravenna","ra ven na"],["Maximian","max im ee an"],["Julian Argentarius","julian ar jen tair ee us"],["Elijah","ee lie ja"],["Proconnesian","pro ko nee zhan"],["Marmara","mar ma ra"],["Romagna","ro man ya"],["UNESCO","you ness co"]],
sources=["https://it.wikipedia.org/wiki/Basilica_di_Sant%27Apollinare_in_Classe","https://www.ravennamosaici.it/ (does not cover this basilica)","Direzione regionale Musei page: host did not resolve, not read"],
notes=["Only Wikipedia could be read; re-check against the official museum page before recording.","The Transfiguration reading is 'probabilmente' in Wikipedia, so the script says 'probably'.","Proconnesus 'an island in the Sea of Marmara' is general knowledge, not from the page.","'One of the loveliest silhouettes in Romagna' is the narrator's opinion.","The port of Classis isn't covered by the sources, so it is left out."])

T["31_palazzo-di-teodorico"] = dict(title="Palazzo di Teodorico, Ravenna",
clean="""This is called Theodoric's Palace. It almost certainly isn't.

On Via di Roma, at the corner of Via Alberoni, stop in front of the tall brick facade. A big central arch, a row of smaller arches above, and two columns set into the windows facing the street. It looks like the front of something rather grand, and that's exactly the problem.

For centuries people assumed this was what was left of the palace of Theodoric, the Ostrogoth king. The name stuck, and it's stuck ever since. But the building is later than him, probably from the middle of the seven hundreds, more than two centuries after he died.

So what is it? The leading idea, put forward in nineteen twenty-one, is that it's the front of a church, San Salvatore ad Calchi, which was pulled down in the early fifteen hundreds. Behind the facade were two round staircases leading up to a gallery, which fits a church rather well. Scholars still argue about it, but the church has the better case.

[beat]

And here's a curious link. For more than three hundred years, from fifteen sixty-four until eighteen ninety-seven, the great porphyry tub from Theodoric's tomb was set into this very building. So the king's supposed coffin was on show in the king's supposed palace, and neither of them was quite what it said.

The two columns in the windows, by the way, were put in during the restoration of the eighteen nineties and nineteen hundreds.

If you want to see the real palace, walk a short way along Via di Roma to Sant'Apollinare Nuovo. On its wall is a mosaic of Theodoric's palace from the early five hundreds, his court made in glass and gold. It's the nearest any of us will get to the real thing.""",
respell=[["Palazzo di Teodorico","pa lat so dee teh oh doh ree ko"],["Theodoric","thee odd or ick"],["Via di Roma","vee ah dee ro ma"],["Via Alberoni","vee ah al beh ro nee"],["Ostrogoth","oss tro goth"],["San Salvatore ad Calchi","san sal va toh reh ad kal kee"],["porphyry","por fur ee"],["Sant'Apollinare Nuovo","san tap pol lee nah reh nwo vo"],["Ravenna","ra ven na"]],
sources=["https://it.wikipedia.org/wiki/Palazzo_di_Teodorico","https://www.turismo.ra.it/cultura-e-storia/palazzo-teodorico/ (HTTP 404)","https://it.wikipedia.org/wiki/Mausoleo_di_Teodorico (for the porphyry tub's time here, 1564–1897)"],
notes=["The San Salvatore ad Calchi identification is the prevailing hypothesis (Gerola, 1921), not certain.","The mid-eighth-century date is 'verosimilmente' (probably).","The two columns were inserted during Corrado Ricci's 1897–1907 restoration.","The tub's stay here is from the Mausoleum's Wikipedia page.","Check the walk from here to Sant'Apollinare Nuovo on a map.","Opening status is unverified."])

for k, v in T.items():
    if S / f"{k}.json".exists() or "35_san-giorgio" in str(S / f"{k}.json") or "38_giardini" in str(S / f"{k}.json"):
        continue  # src/*.json is now the source of truth (FAI removed 2026-11-24); never overwrite
    (S / f"{k}.json").write_text(json.dumps(v, ensure_ascii=False, indent=1))
print(len(T))
