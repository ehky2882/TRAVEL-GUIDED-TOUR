"""Brasília batch 1 — clean scripts 01–12 (stay, dine, drink, shop).

Each entry: number, slug, Google Maps name, category, lat, lon, sources, clean text.
Clean text keeps years as digits (house style, see drafts/fukuoka-batch1); build.py
spells them out for the TTS-safe copy.
"""

TOURS = [
dict(n=1, slug="brasilia-palace-hotel", gmaps="Brasília Palace Hotel", cat="Stay",
lat=-15.788682, lon=-47.830524,
sources=[
 "https://pt.wikipedia.org/wiki/Brasília_Palace_Hotel",
],
text="""Brasília Palace Hotel

This hotel opened in June 1958, almost two years before there was a capital for anyone to visit.

Stand on the forecourt by the main entrance, with the road behind you. In front of you is a long, low building, three floors high, lifted on slim columns, with the glass of the lobby set back underneath. The water you can glimpse beyond it is Lake Paranoá.

Oscar Niemeyer drew it, and the engineer Joaquim Cardozo, who calculated almost everything that went up in Brasília in those years, did the structure. It was built for one reason. Juscelino Kubitschek, the president who willed this city into being, needed somewhere to put the people he wanted to impress. He called it his favourite building, and he walked visitors round it himself.

The guest book shows it worked. Queen Elizabeth the Second stayed here. So did Eisenhower, Indira Gandhi, Che Guevara and Jean-Paul Sartre. And the story the hotel still tells is that Tom Jobim and Vinícius de Moraes first played their song Água de Beber in the bar.

Then the walls. Athos Bulcão, the artist whose tiles you will see all over this city, made a blue and white tile panel for the garden, and a fresco for the function room, one of the very few frescoes he ever painted. Both are protected now by the national heritage service.

And here's the thing. On the fifth of August 1978, a coffee maker someone forgot to switch off started a fire on the third floor. Nobody was hurt, but the hotel closed, and for almost thirty years the most glamorous address in Brasília stood as a burnt shell on the edge of the lake.

[beat]

It reopened in 2006, and Athos Bulcão, by then in his late eighties, came to see his two panels uncovered again. If you have a few minutes, walk through to the garden side and find that tile wall, then follow the shore road south east. The low white palace about a kilometre along is the Palácio da Alvorada, where the president lives. It opened the same month as this hotel.
"""),

dict(n=2, slug="royal-tulip-brasilia-alvorada", gmaps="Royal Tulip Brasília Alvorada", cat="Stay",
lat=-15.787059, lon=-47.829462,
sources=[
 "https://artsandculture.google.com/asset/hotel-brasília-alvorada-tomie-ohtake/3gG43pORXoiK3Q",
 "https://edicao.correiobraziliense.com.br/correiobraziliense/2021/12/05/093058/pdf/A03-POL-0512-DIG.pdf",
 "https://www.frommers.com/destinations/brasilia/hotels/golden-tulip-braslia-alvorada",
 "https://www.anoreg.org.br/congresso/?p=358",
],
text="""Royal Tulip Brasília Alvorada

A city built in straight lines, and a hotel that refuses to draw one.

Stand at the entrance, facing the building, with the access road behind you. What you are looking at is a great curve, a semicircle of rooms that bends away from you on both sides and wraps round towards the water. The lake is on the far side.

The architect was Ruy Ohtake, from São Paulo. The project was launched in 1997, the flats opened in 2000 and the hotel in 2001. I always think Ohtake was arguing, his whole career, that a building could be playful and still be serious. Here he answered Niemeyer's lakeside palaces with something softer: no columns on parade, just one long, continuous sweep.

There is a family story in this site, too. Ruy's mother was Tomie Ohtake, who left Kyoto for Brazil in the nineteen thirties and became one of the country's great abstract painters. For this hotel she made a sculpture in painted carbon steel, about ten metres tall, dated 2001. So mother and son are both here, in the same commission, which is rather lovely when you think about it.

What's worth knowing, standing here, is where you are. The Palácio da Alvorada, the president's official home, is about eight hundred and fifty metres along this shore, and the Brasília Palace Hotel next door opened in 1958 to house the president's guests. Forty years later, the city was still building on that idea: a hotel by the lake, within sight of the head of state.

[beat]

If you fancy it, walk round to the lake side in the late afternoon. The curve catches the low sun, and from the water's edge you can look back across the lake to the Plano Piloto, the original plan of the city, laid out along the far horizon.
"""),

dict(n=3, slug="hotel-nacional", gmaps="Hotel Nacional", cat="Stay",
lat=-15.795660, lon=-47.886801,
sources=[
 "https://www.metropoles.com/distrito-federal/um-dia-no-decadente-hotel-nacional-que-foi-icone-de-hospedagem-no-df",
 "https://www.metropoles.com/distrito-federal/apos-ordem-de-despejo-hotel-nacional-fecha-e-passara-por-reformas",
 "https://bdce.unb.br/wp-content/uploads/tainacan-items/92648/201661/correio_braziliense_2005_02_27_item09_hemerotecadigital.pdf",
 "https://edicao.correiobraziliense.com.br/correiobraziliense/2025/10/22/13592f/pdf/A17-CID-2210-DIG.pdf",
],
text="""Hotel Nacional

In 1968 Queen Elizabeth the Second came to Brasília, and the city had nowhere to put her. So she slept here.

Stand on the pavement of the Hotel Sector South, facing the tall slab with its name across the top. Ten floors of concrete and glass, a broad podium at its feet, and the revolving doors that once spun all day. The Monumental Axis, the city's great central avenue, runs just behind you.

It opened in 1961, while the capital was still being finished around it. The architect, Nauro Esteves, designed close to a hundred buildings in Brasília's first thirteen years, and this was the grandest. Three hundred and forty seven rooms. Wood panelled corridors. A different carpet pattern on every floor, so you always knew where you were.

The Queen had the presidential suite, and there was a plaque in the lobby to say so. Charles de Gaulle stayed too, and as he was nearly two metres tall, a bed was made specially. Jimmy Carter, Ronald Reagan and Indira Gandhi all came through, and for decades deputies and senators simply lived here, because in the early capital there was nowhere else half as comfortable.

And here's the thing. That same lack of anywhere else is what made it, and what undid it. As embassies, flats and newer hotels arrived, the galas moved on. By the twenty tens the furniture was still the original, the air conditioning was old and the revolving doors no longer turned. It was sold at auction in 2018, and in June 2020 a court order emptied it and closed it.

[beat]

So this is a stop to look at rather than check into. Works to restore it were announced in late 2025, with a small museum of the hotel's history planned inside. Walk a few minutes east and you reach the Conic and the bus station, the centre Lúcio Costa drew for this city, and you will see why the capital's first grand hotel was put exactly here.
"""),

dict(n=4, slug="mangai", gmaps="Mangai", cat="Dine",
lat=-15.817433, lon=-47.836940,
sources=[
 "https://www.mangai.com.br/",
 "https://jornaldebrasilia.com.br/top-of-mind-2023/empate-na-categoria-restaurante-brasileiro/",
 "https://cdn.fodors.com/world/south-america/brazil/brasilia-and-the-west/places/brasilia/restaurants",
],
text="""Mangai

A restaurant from the far north east of Brazil, on the shore of a lake in the middle of the country. That is Brasília in a sentence.

Find the entrance on the lake side of the Sports Clubs Sector South, and stop before you go in. Ahead of you is a long, low building with the water behind it, and the arches of the JK Bridge a little way down the shore. Inside, past the door, is a buffet that seems to go on for ever.

Mangai started in 1990 in Paraíba, in Brazil's north east, as a small shop selling produce from the sertão, the dry backlands. It grew into a chain that now runs from João Pessoa and Natal to Recife and São Paulo, and it calls itself the biggest restaurant of Brazilian cooking in Brazil. This lakeside branch, opened in 2008, was its first in the capital.

The buffet runs to more than two hundred dishes, priced by weight. Look for carne de sol, beef salted and dried in the sun, often served on a hot griddle with melted queijo de manteiga, a soft butter cheese. Then pão de macaxeira, a bread made with cassava, and cuscuz, which here means a steamed corn cake, not the North African grain. Finish with cocada, a coconut sweet, or ice cream served in half a coconut shell.

What's worth knowing is why this food is here at all. Brasília was built in the late nineteen fifties largely by workers from the north east, the candangos, who came by the tens of thousands and stayed. So this is not an exotic import. In a sense, it is the city's home cooking.

[beat]

Come at lunchtime, take a table on the terrace and let the light move across the water. Afterwards, the lakeside paths lead along the shore towards the JK Bridge, a good walk if the afternoon is not too hot.
"""),

dict(n=5, slug="daniel-briand", gmaps="Daniel Briand Pâtissier & Chocolatier", cat="Dine",
lat=-15.777001, lon=-47.882712,
sources=[
 "https://blogs.correiobraziliense.com.br/marcas-e-negocios/2024/10/12/um-pedaco-de-paris-em-brasilia/",
 "https://edicao.correiobraziliense.com.br/correiobraziliense/2025/09/26/09312a/pdf/D05-DIV-2609-DIG.pdf",
 "https://curtamais.com.br/brasilia/2015/04/08/daniel-briand-patissier-chocolatier/",
],
text="""Daniel Briand Pâtissier & Chocolatier

Daniel Briand's father was a baker in France. At fifteen, Daniel had to choose between school and an apprenticeship in pastry. He chose pastry, and he has called it the turning point of his life.

You should be on the shopping street of Quadra 104 North, the low row of shops that serves the blocks of flats around you, in front of Block A. Look for small tables on the pavement and, through the window, checked tablecloths, old mirrors and black and white photographs. That is the place.

It opened in 1995. Briand had married a Brazilian woman he met in Paris, and she wanted a French café in Brazil. He has said he started out working here without a permit, until the butcher next door rented him the shop. It has never moved. Some of his staff have been with him for sixteen or twenty years.

Start with the croissant, because that is the whole reason this place exists. The aim from the first day was a croissant in Brasília as good as one in Paris. At lunch the dish to order is duck leg confit, from the south west of France, with herbed potatoes, slices of apple and orange, and a green salad. And at Christmas there is a new bûche de Noël every year.

And here's the thing. Lúcio Costa planned every residential block in this city to have a small commercial strip like this one: a bakery, a pharmacy, a newsagent, all in walking distance of your front door. This café is that idea working as it was meant to: thirty years on the same corner, serving the same neighbours.

[beat]

When you are done, walk into the block of flats behind the shops. Most of the buildings stand on columns, so you can cross underneath them, through the gardens, from one side of the superquadra to the other. It is the best way to understand how people here actually live.
"""),

dict(n=6, slug="mane-mercado", gmaps="Mané Mercado - Complexo Gastronômico", cat="Dine",
lat=-15.783218, lon=-47.902032,
sources=[
 "https://www.archdaily.com/pt/982147/mercado-mane-bloco-arquitetos",
 "https://www.quintoandar.com.br/guias/?p=2472318",
 "https://blogs.correiobraziliense.com.br/marcas-e-negocios/2025/11/15/complexo-de-experiencias-gastronomicas/amp/",
 "https://gironews.com/food-service/mane-mercado-encerra-operacao-em-sao-paulo-apos-10-meses-de-funcionamento/",
],
text="""Mané Mercado

The roof above this food hall was built for the 2007 Pan American Games, and then it sat largely empty for years.

Stand at the main entrance, on the Monumental Axis side, with the great round bowl of the Mané Garrincha National Stadium off to one side and the Nilson Nelson arena on the other. In front of you, under a wide steel roof, are long communal tables, bars and the counters of more than a dozen kitchens.

The architects were BLOCO Arquitetos, a Brasília practice run by Daniel Mangabeira, Henrique Coutinho and Matheus Seco. They opened it in 2022. Rather than pulling the old structure down, they kept its steel roof and built the market underneath: about four thousand square metres, put together as a temporary use until a planned sports complex takes the site.

Have a look at how it works. It isn't a canteen where you queue at a counter. Waiters bring dishes from all the different kitchens to your table, so one group can eat from several places at once. There are long shared tables, a wine cellar and a children's play room.

What's worth knowing, standing here, is that the most interesting thing about this building is how little was built. Brasília's habit was always the grand new gesture. This is the opposite: an unloved leftover from a sporting event, given a second life for the price of what was already there.

[beat]

Stalls change often, so walk the whole length of the hall before you choose. Then, if you have the energy, the TV Tower is about a kilometre south east along the axis, and its viewing deck shows you the whole plan of the city laid out below.
"""),

dict(n=7, slug="beirute", gmaps="Beirute", cat="Drink",
lat=-15.819818, lon=-47.907474,
sources=[
 "https://www.correiobraziliense.com.br/cidades-df/2021/04/4918656-bar-icone-de-brasilia-beirute-completa-55-anos-nesta-sexta-feira.html",
 "https://www.correiobraziliense.com.br/divirtasemais/2024/04/6839297-os-sabores-de-brasilia.html",
],
text="""Beirute

People in Brasília have made a verb out of this bar. You don't go to the Beirute. You beirute.

Stand on the corner of the shopping street at Quadra 109 South, where the tables spill out under the trees. You will see the waiters before you see the sign: in their jackets, moving fast between plastic chairs. The shops on this strip are low and plain, and the bar takes up its corner as if it has always been there, which, for this city, it nearly has.

It opened on the sixteenth of April 1966. Two brothers from Lebanon, Youssef Sarkis Maaraouri and Youssef Sarkis Kaawai, had just arrived in Brasília and bought this corner shop to open an Arab restaurant. In December 1970, two of their waiters, brothers from Ceará called Bartô and Chico, offered to buy them out. It has stayed with that family ever since. It is often called the oldest bar in Brasília still open.

Order a chopp, which is a cold draught beer, and something from the Lebanese side of the menu, the esfihas, small open pies, or the kibe. The house version of the kibe is called a kibeirute.

And here's the thing. In a city planned down to the last kerb, nobody planned this. It grew out of a corner shop, and it became the place where every crowd in Brasília ends up at the same tables: students, civil servants, journalists, musicians. Renato Russo, of the band Legião Urbana, had a regular table here by a tree.

[beat]

A second Beirute opened in 2017 at 107 North, but this is the original. Before you leave, look at the walls inside, which are hung with newspaper stories about the bar itself. Then walk a few minutes west, through the superquadra, and you reach the W3 South, the city's old main shopping avenue.
"""),

dict(n=8, slug="ernesto-cafes-especiais", gmaps="Ernesto Cafés Especiais", cat="Drink",
lat=-15.830702, lon=-47.924234,
sources=[
 "https://sprudge.com/brasilia-coffee-guide-97546.html",
 "https://perfectdailygrind.com/pt/2022/01/07/guia-de-cafeterias-de-brasilia/",
 "https://curtamais.com.br/brasilia/2015/04/08/ernesto-cafes-especiais/",
],
text="""Ernesto Cafés Especiais

Brazil grows more coffee than any other country on earth. This café is one of the places in Brasília that set out to serve it at its best.

You should be on the shopping street of Quadra 115 South, in front of Block C. A low row of shops, a few tables outside, and through the door a counter with a bakery case. The blocks of flats around you are the superquadras of the far south of the Asa Sul, the southern wing of the city.

It opened in July 2011. Its founder, Juliana Pedro, had lived for years in São Paulo and spent much of that time in its cafés, and she came back wanting the same thing here. It is now one of the oldest specialty coffee houses in the city, and one of the largest, with a second branch in the north wing.

Have a look at the menu board before you order. Specialty coffee means the beans are traced to where they were grown, and here that usually means Brazilian farms. Then the thing locals come for is the pão de queijo, the little cheese bread, made here with cheese from the Serra da Canastra, the mountains in Minas Gerais famous for it.

What's worth knowing, standing here, is how recent all of this is. This place is not yet fifteen years old and already counts as one of the city's veterans. A café that tells you which region your cup came from is, in the country that grows the most coffee in the world, a fairly new kind of pride.

[beat]

When you have finished, walk through the nearest superquadra rather than round it. The buildings stand on columns, so the ground floor is open, and you can cross the whole block through its gardens. In the late afternoon it is one of the quietest walks in the city.
"""),

dict(n=9, slug="clube-do-choro", gmaps="Clube do Choro de Brasília", cat="Drink",
lat=-15.789312, lon=-47.899141,
sources=[
 "https://en.wikipedia.org/wiki/Clube_do_Choro_de_Bras%C3%ADlia",
 "https://www.correiodamanha.com.br/nacional/centro-oeste/2024/03/118485-musicos-constroem-historia-do-choro-em-brasilia.html",
 "https://www.opovo.com.br/noticias/brasil/2024/02/29/choro-e-declarado-patrimonio-cultural-do-brasil.html",
],
text="""Clube do Choro de Brasília

Choro is the music Rio de Janeiro played before samba existed. And one of its most important homes is here, nearly a thousand kilometres inland, in a building by Oscar Niemeyer.

Stand in front of the low, curved white building on the Cultural Promotion Sector, just west of the TV Tower. It is a semicircle, wrapped round an open courtyard. Inside are classrooms, a concert hall with a café, and four hundred and twenty seats.

The club began as an informal gathering of musicians. In 1967 and 1968 the great mandolin player Jacob do Bandolim spent time in Brasília and held evenings with local players. Nine years later, on the ninth of September 1977, they met at the home of the flautist Odette Ernest Dias and founded this club. Their first home was a disused cloakroom of the convention centre on this very spot.

By the late nineteen eighties it was falling apart, with equipment stolen and eviction on the cards. In 1993, a mandolin player, Reco do Bandolim, took it over and saved it. A music school followed, named after the guitarist Raphael Rabello and said to be the first in Brazil devoted to choro. And in November 2011 Niemeyer's new building opened, on the site of the old cloakroom.

And here's the thing. Choro is a music of small groups, a flute, a guitar, a mandolin, a tambourine, playing fast and close together, often in someone's front room. Brasília was built by people from all over Brazil, and this is one of the ways they brought home with them. In 2024 choro was recognised as part of Brazil's national cultural heritage, partly at this club's request.

[beat]

In 2023 Paul McCartney played a surprise concert here for about five hundred people. Check the programme and book ahead, as the hall is small. If you arrive early, sit in the courtyard and listen to the students practising.
"""),

dict(n=10, slug="casa-de-cha", gmaps="Casa de Chá", cat="Drink",
lat=-15.800775, lon=-47.860810,
sources=[
 "https://www.correiobraziliense.com.br/cidades-df/2024/11/6968410-conheca-a-casa-de-cha-de-brasilia-projetada-por-niemeyer-na-decada-de-1960.html",
 "https://www.poder360.com.br/brasilia/casa-de-cha-de-niemeyer-e-reaberta-na-praca-dos-tres-poderes/",
 "https://blogs.correiobraziliense.com.br/candangando/quase-desconhecida-casa-de-cha-de-brasilia/amp/",
],
text="""Casa de Chá

At the very centre of Brazilian power there is a café, and most people walk straight over the top of it.

Stand on the Square of the Three Powers with the presidential palace, the Planalto, on one side, the Supreme Court on the other and Congress behind you. Look down rather than up. Set into the paving is a small, low pavilion, sunk half below the level of the square, so its roof barely rises above the stones.

Oscar Niemeyer designed it in 1965 and 1966, and it was finished in 1967. In his memoirs he called it a restaurant for the square. Because it is half buried, the people inside sit with their eyes at the height of the paving, looking out across the square as if from a hide. It opened in 1975 as a Chinese restaurant, closed in 1979, and spent most of the next forty years shut or hired out for events.

In June 2024 it reopened as a café run by Senac, the national training service, and the kitchen is staffed partly by its cookery students. The menu leans on the Cerrado, the savanna that surrounds Brasília. Look for pequi, a strongly scented local fruit, and baru, a nut from the Cerrado tree of that name. There are pão de queijo, pamonha, a sweet corn parcel, and a tea they call céu de Brasília, Brasília sky, which changes colour when you add a drop of lemon.

And here's the thing. Niemeyer gave the most formal square in the country a place for nothing more important than a cup of tea, and then hid it, so that it never competes with the palaces around it. More than forty five thousand people came in its first hundred days.

[beat]

Before you go in, look just beyond the café to the long white Pantheon of the Fatherland, a few steps away. Then, from your table, look out across the square at ground level. Few seats in Brasília give you that view of it.
"""),

dict(n=11, slug="feira-da-torre-de-tv", gmaps="Feira da Torre de TV", cat="Shop",
lat=-15.790332, lon=-47.894696,
sources=[
 "https://pt.wikipedia.org/wiki/Torre_de_TV_de_Brasília",
 "https://www.buenasdicas.com/feira-torre-de-tv-4271/",
 "https://www.correiobraziliense.com.br/cidades-df/2022/01/4977656-confira-a-historia-dos-artesaos-que-embelezam-a-feira-da-torre.html",
 "https://jornaldebrasilia.com.br/brasilia/talento-e-percurso-de-artesaos-iluminam-a-historia-da-feira-da-torre/",
],
text="""Feira da Torre de TV

The market at your feet started in the nineteen seventies as a few stalls in the shade of a television mast.

Stand on the Monumental Axis at the foot of the TV Tower, with its three concrete legs and steel mast rising above you. Around it, spread across three or four pavilions, are the stalls of the Feira da Torre, the tower market. Once they were tents on the grass. Since 2010 they have had a permanent home.

Have a look at what is actually made here, rather than what is merely sold. There are miniature Congress buildings and key rings, of course. But walk on and you find ceramics, macramé, hammocks, leather and work in seeds and stone. The thing to look for is capim dourado, golden grass, a shiny wild grass from the Cerrado, woven into bracelets, bags and boxes that glint like brass.

Some of the people behind these counters have been here for decades. In 2022, one craftsman had been working with stone, seeds and golden grass at this market for thirty five years. One potter, who taught herself, has sold ceramics here since 1984.

What's worth knowing, standing here, is that the market is the TV Tower's other half. Lúcio Costa, who planned the city, designed this tower himself, one of very few major buildings here not by Niemeyer. He drew a monument. Nobody drew the market. It simply grew up around the tower's feet, and fifty years on it is as much a part of this place as the mast.

[beat]

Come early, around nine, before the midday sun, as shade between the pavilions is scarce, and check the opening days before you set off, because even the stallholders give different answers. When you are done, take the lift up the tower. At seventy five metres, the viewing deck shows you the whole cross of the city's plan.
"""),

dict(n=12, slug="fundacao-athos-bulcao", gmaps="Fundação Athos Bulcão", cat="Shop",
lat=-15.8178, lon=-47.9135, coord_note="APPROXIMATE — the shop moved from CLS 404 Sul (OSM still shows the old address) to CRS 510 Bloco B Loja 51, W3 Sul; no map source places the new unit. Point is on the W3 Sul frontage by quadra 510/511, ±150 m. Check the pin by hand before wiring.",
sources=[
 "https://www.fundathos.org.br/",
 "https://www.correiodamanha.com.br/especiais/2024/12/amp/173687-athos-bulcao-32-anos-de-preservacao-da-sua-memoria.html",
 "https://jornaldebrasilia.com.br/brasilia/nas-galerias-e-a-ceu-aberto-conheca-a-arte-de-athos-bulcao-em-brasilia/",
 "https://edicao.correiobraziliense.com.br/correiobraziliense/2025/07/02/11287f/pdf/A13-CID-0207-DIG.pdf",
],
text="""Fundação Athos Bulcão

If you have spent even an hour in Brasília, you have already seen Athos Bulcão's work. You probably just didn't know his name.

You should be on the W3 South, the long avenue of shops along the western edge of the south wing, at Quadra 510, in front of Block B. The foundation's shop is a ground floor unit with his patterns in the window: blue and white tiles, bold geometric prints, simple shapes repeated in a way you will start to recognise everywhere.

Athos Bulcão was born in Rio de Janeiro in 1918. As a young man he worked as an assistant to the painter Cândido Portinari on the church at Pampulha, in Belo Horizonte, and in 1958 his friend Oscar Niemeyer invited him to Brasília to help build the city. He stayed for fifty years. The tiles on the Igrejinha, the panels in the Congress, the wall of concrete blocks on the National Theatre: those are all his.

The shop sells his patterns on things you can take home: actual tiles, mugs, umbrellas, necklaces, sandals, prints and books. The foundation was set up in 1992 to look after his work, and its collection holds more than seven hundred pieces.

And here's the thing. Athos often handed the builders boxes of his tiles with a few rules and no fixed plan, and let them lay the pieces as they chose, so that no two walls came out quite the same. The bricklayer became a kind of co author. Buying a single one of his tiles here is the nearest you can get to taking Brasília home with you.

[beat]

The foundation has moved more than once, and talk of a permanent home keeps coming and going, so check the address and hours before you visit. Then go and find the real thing. The Igrejinha, the little church at Quadra 307 South, is wrapped in his tiles, about a kilometre north east of here.
"""),
]
