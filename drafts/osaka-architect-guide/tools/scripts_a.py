# Osaka architect's guide, scripts 01-17 (clean versions).
# Each entry: (number, slug, title, tts_title or None, category, lat, lon, script, sources)
# Years are digits in the clean version (house style); build.py spells them out for TTS.

SCRIPTS_A = [
(1, "zentis_osaka", "Zentis Osaka", None, "Stay", 34.695778, 135.496384,
"""It's a business district by the river, all office towers, and the hotel that opened here in July 2020 decided to be about as unlike an office as it possibly could.

Stand on the pavement outside the entrance on Dojimahama, with the street behind you. In front of you is a building of dark brick laid in a strict grid, sixteen storeys of it, and at street level a small garden: a Japanese maple and a cherry tree where most of its neighbours would put a revolving door.

Start with that grid. The outside was done by Kajima Design, and the brief was to fit in with the offices around it while making room for the greenery. So the frame looks almost corporate from a distance, and then it softens the closer you get. Brick, rather than glass, is the tell.

Inside is the work of the British designer Tara Bernerd, and she treated it like a converted warehouse that happens to be brand new. Exposed brick, timber beams, heavy ironwork, a staircase of blue limestone, and tall black-framed Crittall windows looking onto the garden. A fireplace opens on two sides, so the lounge and the garden terrace share the same fire.

Have a look at the details if you go in. The bedside tables are Shigaraki pottery, from Shiga, just across the mountains. The charcoal brushwork over every bed is by an Osaka artist, Masami Ehara. Even the room plans were drawn up like a bento box, everything in its compartment.

And here's the thing. This was the very first hotel under the Zentis name, the new label from the group that runs the Palace Hotel in Tokyo, and they chose a street of offices to launch it. It works because it doesn't pretend the offices aren't there. It just gives you a living room in the middle of them.

[beat]

If you fancy a drink, the restaurant and bar, Upstairz, is on the second floor, with a covered terrace of its own. Or turn round and walk a couple of blocks north into Kitashinchi, Osaka's grown-up bar district, where the evenings start rather later than you'd expect.""",
["https://zentishotels.com/en/osaka/archive/202011103599 (Zentis press release, 10 Nov 2020)",
 "https://www.design-anthology.com/story/zentis-osaka"]),

(2, "hotel_royal_classic_osaka", "Hotel Royal Classic Osaka", None, "Stay", 34.665912, 135.499875,
"""This corner of Namba lost one of the city's best-loved buildings in 2009. What you're looking at is the way it was brought back.

Cross to the far side of Midosuji, the big boulevard, and look back at the hotel. Down at the bottom, a long run of curving gables, one after another, like a row of rooftops on a temple. Above them, a tall tower wrapped in thin layers of aluminium fins.

Those gables are the memory. From 1958 this was the Shin-Kabukiza, a theatre designed by Togo Murano, one of the great architects of post-war Japan, and its front was a whole cascade of karahafu, the swooping gable you see over temple gates and castle doorways. The theatre closed in 2009 and the building came down.

When the new hotel went up, the architect was Kengo Kuma, who admired Murano enormously. So he rebuilt that gabled front across the lower floors, and put his own tower of fins on top. The hotel opened on the first of December 2019, and its logo is literally the two ideas together, Murano's gables under Kuma's fins.

Inside, it calls itself a museum hotel. Around a hundred and eighty works by twenty-nine artists, chosen by the curator Junji Ito, and at the heart of it the Gutai group, the radical Kansai artists of the fifties and sixties: Jiro Yoshihara, Kazuo Shiraga, Atsuko Tanaka. There's Yayoi Kusama too, if you're keeping count.

What's worth thinking about, standing here, is that this is a copy. Murano's building is gone. Some people find that a bit sad, an old building dressed up as itself. I rather think it's honest. The street got its gables back, and nobody's pretending the tower behind them is from 1958.

[beat]

On the ground floor, facing the boulevard, there's a café called Tsuchi, which Kuma designed as well, and it's open to anyone. For the view, go up to the bar on the twentieth floor, Kumokumo, and look east across the night skyline.""",
["https://www.hotel-royalclassic.jp/ (official site)",
 "https://bijutsutecho.com/magazine/news/headline/20860",
 "https://dime.jp/genre/825238/"]),

(3, "hotel_noum_osaka", "Hotel Noum Osaka", "Hotel Noh oom Osaka", "Stay", 34.692237, 135.514640,
"""Osaka used to call itself the city of water, and this is one of the few hotels that really lets you feel it.

Stand on the riverside path in front of the hotel, with the building behind you, and look out. That wide, slow river is the Okawa, which was once the main course of the Yodo River. Across the water and along the banks, trees and parkland. Then turn round: an eight-storey building, plain and pale, with a ground floor of big windows and people drinking coffee behind them.

That ground floor is the clever bit. The café and lounge by reception is open to anyone, from seven in the morning to eleven at night, so the lobby of the hotel works as a neighbourhood café. The coffee comes from Berth Coffee, a roaster in Tokyo.

Upstairs there are fifty rooms, from bunk beds for people travelling cheaply to suites with big beds and river views. It's a hostel and a hotel in one, which makes the lobby a fairly mixed crowd. On the roof, a sauna, where they hold yoga classes as well.

Here's what I like about it. Most of Osaka's hotels face the street, the stations or the shopping. This one faces the river, and so does the café, and so do many of the rooms. Rivers built this city. Rice, timber and goods came in by water for centuries, and the merchants' warehouses lined these banks. It's nice to stay somewhere that still treats the river as the front door.

[beat]

If you fancy a walk, follow the river upstream, east past Tenmabashi bridge and then north along the park. In early April those banks are one long tunnel of cherry blossom. Or head downstream, west, and in a few minutes you reach the eastern tip of Nakanoshima island, where the river splits in two and the old commercial city begins.""",
["https://www.timeout.com/osaka/hotels/hotel-noum-osaka",
 "https://www.timeout.jp/osaka/ja/ホテル/hotel-noum-osaka",
 "https://rurubu.jp/andmore/article/19335"]),

(4, "conrad_osaka", "Conrad Osaka", None, "Stay", 34.693593, 135.495468,
"""The reception desk here is about two hundred metres off the ground. You'll want to start at the bottom, though.

Start in the ground-floor entrance of Nakanoshima Festival Tower West, on the island of Nakanoshima, with the river a block away. The hotel takes the top eight floors of the tower, thirty-three to forty, and its lobby is right at the very top. Before you go up, look for the video piece in the entrance by the artist Takahiro Matsuo: millions of tiny particles drifting as if there's no gravity. The colour shifts through the day, from white to blue to gold.

Now take the lift to the fortieth floor. When the doors open, the first thing you'll see is a sculpture by Kohei Nawa called Fu and Rai. That's the wind god and the thunder god, Fujin and Raijin, the pair you'll find guarding temple gates all over Japan, usually with bulging eyes, a bag of wind and a ring of drums. Nawa has turned them into clusters of soft, glistening spheres. Gods made of bubbles.

There are nearly four hundred works of art around the hotel, and most of them are about wind, water and light. And the reason is through the windows: the river, the bay, the mountains behind the city.

Here's the thing about that lobby. A normal hotel puts its public rooms at the bottom and sells the view by the night, to whoever books a room. Putting the lobby, the restaurants and the bar on the fortieth floor means the best view in the building belongs to anyone who walks in.

[beat]

So if you're not staying, have a drink anyway. The 40 Sky Bar and Lounge sits next to the lobby, looking out across the city. And when you come back down, the tower's twin to the east holds Festival Hall, one of the city's great concert halls, while the museums at the western end of Nakanoshima are a short walk along the river.""",
["https://www.art-tourism.jp/en/article/conrad-osak_en (art at Conrad Osaka)",
 "https://robbreport.com.my/travel/new-conrad-osaka/",
 "https://hospitalitydesign.com/?p=56515"]),

(5, "hajime", "HAJIME", "Hahjeemay", "Dine", 34.688599, 135.496201,
"""The chef here started out as an engineer, designing parts for electronic devices. You can still taste it.

Hajime is on the ground floor of a quiet building on Edobori, a few streets south of the river. From outside there's very little to see, which is rather the point. You should be on the pavement in front of a discreet entrance with the restaurant's name on it, in a neighbourhood of offices and small flats.

The man behind it is Hajime Yoneda. Born in Osaka in 1972, he studied engineering at Kindai University and went to work as a design engineer, saving up for cookery school. He trained in Osaka and Kobe, went to France in 2002, and later cooked under Michel Bras, the great French chef of vegetables and landscapes, at his restaurant in Hokkaido.

He opened here in May 2008. About a year and a half later the Michelin guide gave it three stars, which at the time made it the only three-star restaurant in Osaka.

Have a look at how the restaurant describes itself. The motto is that the universe exists in a remarkably delicate harmony, and it measures its cooking in tenths: a tenth of a degree, a tenth of a millimetre, a tenth of a gram. That's an engineer's tolerance. But what arrives on the plate is meant to feel like nature, like a hillside or a garden, not like a circuit board.

And that's the interesting bit. Precision and wildness usually pull in opposite directions. Here the precision is how you get the wildness. Every leaf on the plate is placed to look as if it simply fell there.

[beat]

You'll need a reservation, made well ahead, and the long tasting menu is an evening's commitment. If you've come by day, walk a few minutes west to Utsubo Park, a long, leafy strip with a rose garden, where the office workers of this neighbourhood eat lunch on the benches.""",
["https://www.hajime-artistes.com/ (official site)",
 "https://ai.sony/blog/The-Future-Kitchen-Series-Chef-Hajime-Yoneda-Part1",
 "https://en.wikipedia.org/wiki/Hajime_(restaurant)",
 "https://guide.michelin.com/at/en/osaka-region/osaka/restaurant/hajime"]),

(6, "mizuno", "Mizuno", "Meezoonoh", "Dine", 34.668372, 135.503220,
"""Okonomiyaki is supposed to be pancake batter, cabbage and whatever you fancy. The best thing on the menu here doesn't use any flour at all.

You're in the covered arcade a few steps in from Dotonbori and the canal, in the thick of the neon. Look for the queue. Inside, everything is cooked on hot iron plates.

It opened in 1945. The air raids that year had burned Minami, this whole southern district, almost flat, and the family started again with a single iron plate, selling yoshoku-yaki, the thin, cheap griddled pancake that came before okonomiyaki. It's still on the menu. The family has run it through three generations since.

Now, the dish to order. It's yamaimo-yaki, made with nothing but grated mountain yam, the slippery, sticky root you'll find all over Japanese cooking. No flour, no binding, just yam on the griddle. It starts soft, almost creamy, and as it sits on the hot plate the outside turns crisp. Eat it slowly and you get both. The house special, the Mizuno-yaki, is the other one people come for. And the shop is quite proud that it doesn't drown everything in sauce: the idea is that you taste what's in it.

The Michelin guide has given it a Bib Gourmand, its prize for good cooking at a fair price, several years running.

Here's what's worth knowing. Dotonbori sells itself on spectacle, giant crabs and running men and lights. But the places that have lasted here are the ones that kept their heads down and their griddles hot. This one started on a bomb site with one iron plate. It's still, essentially, a pancake shop.

[beat]

Afterwards, find Hozenji Yokocho, two narrow stone lanes with a moss-covered statue at their heart. It's a couple of minutes' walk, and about as quiet as this neighbourhood gets.""",
["https://www.mizuno-osaka.com/ (official site)",
 "https://www.gltjp.com/ja/directory/item/12081/",
 "https://livejapan.com/ja/in-kansai/in-pref-osaka/in-namba_dotonbori_shinsaibashi/article-a2000114/"]),

(7, "dotonbori_imai_honten", "Dotonbori Imai Honten", "Doh tonn boree Eemye Hon ten", "Dine", 34.668651, 135.502710,
"""This family has sold tea to theatregoers, trumpets to jazz musicians, and udon to everybody, all on the same street.

Dotonbori, the south side of the canal. Look for a calm, low wooden shopfront in the middle of all the noise. Inside, it's quiet, polished and rather old-fashioned, which on this street is the most surprising thing of all.

The story starts around 1815, when the founder came to Dotonbori from Imai-cho in Nara. In 1838 his daughter opened a teahouse for the theatre crowds, because this street was lined with theatres. Generations later, the family turned it into a shop selling Western musical instruments, Imai Gakki, which became one of the best known in the country and grew up alongside Dotonbori's jazz scene.

Then the war. The air raids burned this district, and when the family came back in 1946 they sold whatever they could: agar jelly, shaved ice, sweet bean soup. And, rather quietly, noodles. Customers loved the noodles. That was that.

Order the kitsune udon. Kitsune means fox, and the dish is udon topped with a sheet of sweet-simmered fried tofu, which foxes, in Japanese folklore, are supposed to adore. Osaka claims the dish as its own invention. But the reason to come is the broth, the dashi. It was perfected in 1949 by the fifth-generation head and his wife, using kombu seaweed from Hokkaido and dried mackerel and sardine flakes from Kyushu. It's clear, pale and deep.

And here's the thing. On a street that reinvents itself every few years, this family has reinvented itself three times without ever leaving. Teahouse, music shop, noodle house. Same street, same name.

[beat]

When you come out, walk along the canal and look for the building called Nakaza Cuidaore. Nakaza was the great theatre that stood there, the one that teahouse was built to serve. Its name survives on the building, even though the stage is long gone.""",
["https://d-imai.com/ (official site)",
 "https://d-imai.com/history/ (official history)"]),

(8, "kushikatsu_daruma_shinsekai_sohonten", "Kushikatsu Daruma Shinsekai Sohonten", "Kooshee kahtsoo Dahroomah Sheen sekkye Soh hon ten", "Dine", 34.651558, 135.506226,
"""There's one rule here, and it's been the rule for longer than anyone can remember. You only dip once.

You should be on a side street in Shinsekai, a few minutes south of Tsutenkaku tower, outside the original branch of Daruma. A narrow counter, a hot fryer, steel trays of brown sauce along the bar, and a queue on the pavement most hours of the day.

It opened in 1929, on land that had been an amusement park called Luna Park, and back then it wasn't called Daruma at all. The founder, Yoshie Hyakuno, called it Takohishi and sold beef and potato on skewers, fried in batter, for one sen apiece. That's a hundredth of a yen. Food for workers, cheap and fast.

After the war, her son rebuilt the shop and renamed it. And he added the thing you'll notice in front of you: a bowl of raw cabbage, free.

Here's why the cabbage matters. The sauce trays are shared by everyone at the counter. Dip your skewer once, before you bite, and that's it. Put a bitten skewer back in and you've put it in everybody's sauce. So if you want more sauce, you use a leaf of cabbage as a scoop. The cabbage is the rule's way out. Rather elegant, when you think about it.

The shop nearly closed in 2001. The third-generation owner had decided to retire, and it was a regular customer, the actor Hidekazu Akai, who begged him not to let it go. The business passed to Katsuya Ueyama, who still runs it, and there are now branches across Osaka and Kyoto.

[beat]

When you've eaten, walk back up to Tsutenkaku and go to the top. Up there you'll find Billiken, a little smiling god of good luck. People rub the soles of his feet for fortune. After a plate of fried skewers, it seems only fair.""",
["https://www.kushikatu-daruma.com/ (official site)",
 "https://www.kushikatu-daruma.com/history/ (official history)"]),

(9, "kuromon_market", "Kuromon Market", "Kooroh mon Market", "Dine", 34.665328, 135.506980,
"""People here call this street Osaka's kitchen. It's been feeding the city for about two hundred years.

Nipponbashi, at one end of a long covered arcade. Stalls run away from you on both sides: fish on ice, crabs, fruit stacked in pyramids, and people eating standing up. The arcade is about five hundred and eighty metres from end to end.

It began in the early eighteen hundreds, when fishmongers started trading here, selling catches brought up from Sakai and the Kii coast to the south. The name means the black gate. There was a temple nearby, Enmyoji, and its gate was painted black, so everybody called the market after it.

In 1902 it became an official market, and ten years later a great fire swept through Namba and took the temple and the black gate with it. The market burned again in the war, and came back again. So there's no gate to look for. Just the name.

Today there are around a hundred and fifty shops. Have a look at the way the old fishmongers and the newer stalls sit side by side. Some still sell mainly to restaurants. Others grill scallops and slice tuna to eat on the spot. Come early in the morning and you'll see the wholesale side of it, the delivery bikes and the chefs with lists.

And here's the thing. A market like this is usually a place you visit with a shopping bag and a recipe. This one has become a place you visit with an appetite. Some people mind that. But the deliveries still go out every morning, and the restaurants of Minami still buy their fish here.

[beat]

From the southern end, keep walking south into Nipponbashi's electronics and anime streets, or turn west and you'll reach Doguyasuji in about ten minutes, the street where all those restaurants buy their knives and pans.""",
["https://kuromon.com/ (official site, not retrievable: HTTP 403)",
 "https://osaka-info.jp/experience/ja/osaka/spot/208",
 "https://tabi-mag.jp/os0080/",
 "https://www.gltjp.com/ja/article/item/20365/"]),

(10, "bar_nayuta", "Bar Nayuta", "Bar Nah yootah", "Drink", 34.671967, 135.498383,
"""There's no menu. You tell the bartender what you like, and they make you something that didn't exist until a minute ago.

Near Triangle Park in Amerikamura, find the foot of an ordinary building of bars and shops. Have a look at the signboards by the door for a small, intricate geometric symbol. That's your sign. The bar is on the fifth floor, and you go in through a door low enough to make most people duck.

Inside it's dim, wooden and cluttered. Bottles crowd the shelves and spill down onto the floor, and many of them are the bar's own: infusions, bitters and liqueurs made in house. It looks less like a cocktail bar than an alchemist's workshop, which I suspect is deliberate.

The name is worth a moment. Nayuta is an old Buddhist word for an unimaginably large number, used in the traditional Japanese counting system for a figure with sixty or more noughts after it. A fair description of the possible drinks.

It opens at five in the evening and stays open until three in the morning, every day. In 2025 it was one of two Osaka bars on the extended list of Asia's 50 Best Bars.

What's worth noticing is how Osaka does this differently from Tokyo or Kyoto. In those cities, the great bars tend to be hushed, formal and precise. Here, the same skill comes with a bit of mischief: the low door, the hidden sign, the bottles on the floor. It's serious about the drink and not at all serious about itself.

[beat]

When you come back down, Triangle Park is where Amerikamura gathers at night, young people sitting on the steps with cans and skateboards. Walk east from it and you'll reach Shinsaibashi-suji, the long covered shopping street, in about five minutes.""",
["https://www.timeout.com/osaka/bars-and-pubs/bar-nayuta",
 "https://www.timeout.com/osaka/news/2-osaka-bars-named-in-asias-50-best-bars-2025-extended-list-101425",
 "https://ssl.tabelog.com/en/osaka/A2701/A270202/27017544/"]),

(11, "kitahama_retro", "Kitahama Retro", "Keetah hahmah Retro", "Drink", 34.691717, 135.507487,
"""Tea and scones, in a red-brick building put up for stockbrokers in the last year of the Meiji era. It shouldn't work. It does.

In front of you, on a street in Kitahama by the Tosabori River, is a tiny two-storey building of red brick, squeezed between much bigger neighbours. The windows and door are framed in cut granite, and through the glass you'll see cakes on a counter and a narrow stair going up.

It was built in 1912 for a club of people in the share trade. Kitahama was Osaka's financial district, and still is: the stock exchange is just round the corner. The style borrows from Britain, from the Glasgow school, with that mixture of sturdy brick and slightly whimsical detail.

After the war it became the head office of a building-materials company, and then it sat empty, as old buildings in this district so often did. In 1997 it reopened as a British tearoom, and it was registered as a cultural property soon after.

Go in if there's room, and climb to the first floor. It's small, and from the window you look out across the river towards Nakanoshima island. The afternoon tea comes on a tiered stand. The scones are the point.

Here's what I find rather lovely. Osaka could have kept this building as a museum of itself, a plaque on a locked door. Instead somebody put a kettle on. A building that's used is a building that's looked after, and the queue outside does more for it than any plaque would.

[beat]

Before you go, walk a few minutes west to the Osaka Exchange building and look for the statue of Godai Tomoatsu out front, the man who helped found the exchange. Then cross Naniwabashi bridge to Nakanoshima, where the red-brick Central Public Hall is waiting.""",
["https://www.mec-h.com/town/mh-osaka/174",
 "https://osaka-info.jp/experience/ja/osaka/spot/449",
 "https://intojapanwaraku.com/rock/travel-rock/60271/",
 "https://www.city.osaka.lg.jp/toshikeikaku/cmsfiles/contents/0000100/100550/0_tyuuou-sigen.pdf"]),

(12, "lilo_coffee_roasters", "LiLo Coffee Roasters", "Leeloh Coffee Roasters", "Drink", 34.674063, 135.498223,
"""This coffee shop started life as a hairdresser's coffee bar. The hairdresser just wanted a better house blend.

A back street in Nishi-Shinsaibashi, the Amerikamura side of Midosuji, outside a small shopfront on the ground floor of a narrow building. Look in and you'll see a counter, baristas working very close to the customers, and bean containers stacked almost to the ceiling.

It opened on the eighth of August 2014. The owner, Hotta, ran the beauty salon upstairs and served coffee to his clients. He wanted to roast his own, so he took over the ground floor below. The head roaster, Nakamura, started on a one-kilo roaster. These days it's an eight-kilo machine, roasting several hundred kilos a month.

Have a look at the cards on the counter. Each bean has its own illustrated card with its origin, how it tastes and what to brew it with. Ask, and the barista on shift will point you to their favourite of the day and two or three others to suit your taste. Then you choose the method: paper filter, metal filter, French press or cold brew. There are usually about twenty beans on offer.

And here's the bit worth knowing. Most specialty coffee chases a clean cup, polite and balanced. Nakamura goes the other way. He's looking for a strong first impression, a bean with character, something that surprises you on the first sip, even if it's not quite so tidy.

[beat]

From here, Triangle Park is about two minutes' walk, the centre of Amerikamura, and if you like this, the shop has a little sister elsewhere in the city, LiLo Coffee Kissa, done up as an old-fashioned Japanese coffee house. Or cross Midosuji for Shinsaibashi-suji and the old Daimaru department store.""",
["https://kurasu.kyoto/blogs/kurasu-journal/lilo-coffee-roasters-osaka-december-2017s-kurasucoffee-roaster",
 "https://www.timeout.com/osaka/restaurants/lilo-coffee-roasters"]),

(13, "shin_umeda_shokudogai", "Shin-Umeda Shokudogai", "Sheen Oomeh dah Shoh koo doh gye", "Drink", 34.703907, 135.497910,
"""Overhead, every couple of minutes, a train. Underneath, about a hundred tiny bars and restaurants, and the smell of grilling.

You should be under the railway viaduct between JR Osaka station and Hankyu Umeda, at the entrance to a warren of narrow passages. Look in: low ceilings, steamed windows, signboards one after another, and people drinking highballs standing at counters barely wider than a shelf.

It opened in 1950, and the reason is rather touching. It was set up as a relief scheme for people retired from the national railway, a way of giving them a livelihood after the war, in the space under the tracks. Eighteen shops opened that first year. Now there are about a hundred.

The name means the new Umeda food road. Some say it was called a road because the passages are so narrow, lined with so many places to eat, that they're less a building than a street. Have a look at the size of the shops as you walk in. Many of them seat eight or ten at most. The kitchens are about the size of a cupboard.

What's worth knowing, standing here, is that this is the real public space of Umeda. The department stores and the glass towers all round you are new, polished and rebuilt every few years. This has barely changed, because it can't. It's wedged between railway arches. Office workers come here at six, a salaryman next to a student next to a pensioner, and for an hour or so they're all just people at a counter.

[beat]

Most shops take cash, and many of them are standing only. If you'd rather walk than drink, head east under the tracks and keep going for about ten minutes. You'll reach Nakazakicho, a neighbourhood of old wooden row houses that came through the war, now full of tiny cafés.""",
["https://insideosaka.com/shin-umeda-shokudogai/",
 "https://japantravel.navitime.com/en/area/jp/spot/02301-1903447/",
 "https://www.walkerplus.com/trend/matome/article/206829/",
 "https://tabelog.com/matome/14251/"]),

(14, "truck", "TRUCK", "Truck", "Shop", 34.717653, 135.562894,
"""They only sell their furniture in one place, and this is it. If you want a sofa from TRUCK, you come to a quiet residential street in Asahi ward.

Ahead of you, a low group of brick buildings among trees, with a workshop, a shop and, right by it, a café. There's no shopping street here, no neon. Just a furniture maker's yard, built from scratch.

TRUCK is two people. Tokuhiko Kise grew up in Osaka, learned furniture making in Nagano and went independent at twenty-three. Hiromi Karatsu studied textile design at the Osaka University of Arts and became an illustrator. In 1996 they bought an old building in Tamatsukuri and turned it into a shop, a workshop and their home, all in one. TRUCK opened in January 1997.

In 2009 they moved everything here, to a site they built over about two and a half years, from buying the land to planting the trees and laying the brick walls. Shop, workshop and home came along. So did the leather studio, which turns the offcuts from TRUCK sofas into small hand-stitched things.

Have a look at the wood if you go in. American white oak and Japanese oak, chosen for their knots, cracks and rough grain rather than despite them. Every piece is made by hand in the workshop on site, and they build and live with prototypes for a long time before they sell anything.

The interesting bit is this. They say they make furniture they want for themselves, regardless of trends, to be used for a lifetime. Don't worry about scratches, they say, use it with love. That's a philosophy that sits very badly with modern retail. It's exactly why people make the journey out here.

[beat]

Check the days before you come: it's closed on Tuesdays and Wednesdays. And stop at Bird, the café TRUCK opened when it moved here. You'll be eating at TRUCK tables on TRUCK chairs, which is the best showroom there is.""",
["https://truck-furniture.co.jp/en/about/ (official site)",
 "https://www.shift.jp.org/guide/?p=38662",
 "https://rurubu.jp/andmore/article/8364"]),

(15, "graf_studio", "graf studio", "Graf studio", "Shop", 34.690442, 135.491342,
"""Six friends started this in 1993: a designer, a product designer, a carpenter, a furniture maker, an artist and a chef. That last one is the clue.

You should be on the western end of Nakanoshima, the long island between the rivers, outside a plain building with big windows on the ground floor. Through them, a shop of furniture and household things, and a kitchen. Upstairs, a gallery space.

The group first called itself decorative mode number three, and from 1998 it became graf. The founder and leader is the designer Shigeki Hattori. They've been based here on Nakanoshima since the early two thousands, and today they design spaces, products and graphics, make and sell furniture, and run food and music events. The ground floor has graf shop and graf kitchen. The first floor, which they call graf porch, holds exhibitions.

Have a look round the shop if it's open. Much of the furniture is their own, plain, solid and made to be lived with. The everyday objects sit beside it as if in somebody's house, which is the idea.

Here's what makes graf rather unusual. Most design studios keep the chef out of the room. graf put one in among the founders. Food isn't a sideline here, it's part of the design. A table isn't finished until somebody's eaten at it.

And they chose this end of the island before either of the big art museums arrived. Now those museums are its neighbours, and the area has become one of the most interesting corners of the city.

[beat]

Those neighbours are worth the next half hour. The black box of the Nakanoshima Museum of Art is a couple of minutes away, and beside it, the National Museum of Art, which has put almost all of itself underground.""",
["https://www.graf-d3.com/ (official site)",
 "https://www.city.osaka.lg.jp/contents/wdu120/sakuya-konohana/person/22_01.html",
 "https://rurubu.jp/andmore/article/3785"]),

(16, "sennichimae_doguyasuji", "Sennichimae Doguyasuji Shopping Street", "Sen neechee mah eh Doh goo yah soojee Shopping Street", "Shop", 34.663935, 135.503517,
"""Every plastic sushi in every restaurant window in Osaka came from somewhere. A good many of them came from here.

You should be under the arcade on Doguyasuji, a covered street about a hundred and fifty metres long, a short walk south of Namba's theatres. On both sides, shops crammed to the ceiling: knives, pots, piles of bowls, paper lanterns, shop curtains, signboards and plastic food so convincing it's faintly alarming.

It's a professional street. These are the shops where chefs and restaurant owners come to equip a kitchen, and the name says it: dogu means tools. The tools for running a restaurant.

It started in 1882, as a pilgrims' road. People walked from the temples here at Sennichimae down to Shitennoji and to Imamiya Ebisu shrine, and second-hand dealers and sellers of household goods set up along the way to catch them. In the Taisho era, the early twentieth century, the shops turned into wholesalers and specialists. The arcade went up in 1970.

Have a look at the knife shops first. Osaka is the home of Sakai knives, from the city just to the south, and a good shop here will sharpen and engrave what you buy. Then find a food-sample shop. The plastic food on sale is the same as you see in restaurant windows.

What's worth knowing is that this is the backstage of Osaka's eating. Dotonbori is the stage, the lights and the queues. This is where the props are made, and the trays and the lanterns and the curtains with the shop's name dyed in. Walk through it and you understand how a city of tiny restaurants equips itself.

[beat]

There are around fifty shops, and every October the street holds a festival with bargain stalls. If you've bought a knife, celebrate it with a meal: Kuromon Market is about ten minutes' walk east.""",
["https://www.doguyasuji.or.jp/ (official site)",
 "https://osaka-info.jp/spot/sennichimae-doguyasuji-shopping-street/",
 "https://osaka-info.jp/experience/ja/osaka/spot/205"]),

(17, "daimaru_shinsaibashi", "Daimaru Shinsaibashi", "Dye mahroo Sheen sye bahshee", "Shop", 34.673257, 135.500957,
"""The front of this department store is nearly a hundred years old. Everything behind it is new. That's either a triumph or a compromise, depending on who you ask.

Stand on the Midosuji side, on the pavement of the big boulevard, and look up at the old building. Stone and brick, a rich, ornamented facade, carved details rising to the roofline. It's one of the most elaborate fronts on the whole of Midosuji.

It was designed by the office of William Merrell Vories, an American who came to Japan to teach English and stayed to build schools, churches and houses. The store went up in four stages, from 1922 to 1933, and was famous for its Art Deco interiors, its lift halls and its stairs. During the war, much of the metal was taken away, and parts of the stair railings were replaced in wood.

When Daimaru rebuilt the store, it kept this Midosuji front in place, structure and all, rather than taking it down and rebuilding it. Behind it is a modern store, which reopened in September 2019, and wherever possible the old decorative materials were reused inside.

Have a look for the animals as you walk round. The decoration is full of creatures drawn from Aesop's fables.

Keeping a facade and replacing the building behind it is a common compromise, and architects argue about it endlessly. Some people in Osaka objected that much of Vories' interior was lost. Others point out that the street kept its finest front, and that a working department store is what keeps a building alive. I'd say go inside, look carefully at what was saved, and decide for yourself.

[beat]

Then walk round to the entrance on the other side, on the Shinsaibashi-suji shopping street. Above it is a peacock in relief, spreading its tail. It's the best single piece of the old building, and most people walk under it without looking up.""",
["https://www.daimaru.co.jp/shinsaibashi/ (official site)",
 "https://www.walkerplus.com/article/209229/",
 "https://data.shinkenchiku.online/articles/SK_2020_03_108-0/",
 "https://www.city.osaka.lg.jp/toshikeikaku/cmsfiles/contents/0000331/331288/209_ikensyo_youshi.pdf"]),
]
