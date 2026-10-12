# Kuala Lumpur architect's guide — clean scripts, part 1 (STAY, DINE, DRINK).
# Each entry: num, slug, google_maps_name, category, lat, lon, title, text.
# Clean text keeps years as digits and [beat] as the authoring marker;
# build.py derives the TTS-safe version.

TOURS = [
dict(num="01", slug="the-majestic-hotel-kuala-lumpur", category="STAY",
     gmaps="The Majestic Hotel Kuala Lumpur, Autograph Collection", lat=3.138563, lon=101.692064,
     title="The Majestic Hotel",
     text="""For fourteen years, the national art collection of Malaysia hung in a hotel.

Stand on the pavement of Jalan Sultan Hishamuddin with the white domes of the old railway station behind you. Up the slope in front, set back behind its lawn, is a long, pale facade of arches and pilasters with a cornice running along the top. That's the original Majestic, opened in 1932. The tall block rising beside it is new, and we'll come to that.

Have a look at the old building first. The architects were the firm Keys and Dowdeswell, and they gave it a split personality: classical arches and columns for dignity, and the cleaner lines of Art Deco for modernity. It's the look of a colony that wanted to seem both ancient and up to date. When it opened it had fifty-one rooms, modern plumbing that was something of a boast at the time, and a roof garden with a dance floor that could seat three hundred and fifty. Arriving by train, you simply crossed the road.

Its history is a fair summary of the country's. During the war the Japanese used it as a transit camp. In 1951, the Independence of Malaya Party held its very first meeting here. By the seventies, the smart crowd had drifted to new hotels in Bukit Bintang, and in 1983 the government gazetted the building as a historic landmark and closed the hotel. From 1984 it became the National Art Gallery, which is how a hotel ended up full of paintings.

And here's the thing. The building was saved not by sentiment but by a trade. In the nineties the developer YTL was given the hotel in exchange for building the nation a new art gallery. It restored the old wing, added the fifteen-storey tower beside it, and reopened the Majestic in December 2012.

[beat]

Before you leave, turn round and look at the railway station across the road. The two have faced each other since 1932 — one for arriving, one for staying. The footbridge over the Klang River will take you on to Central Market in about ten minutes."""),

dict(num="02", slug="hotel-stripes-kuala-lumpur", category="STAY",
     gmaps="Hotel Stripes Kuala Lumpur, Autograph Collection", lat=3.157242, lon=101.700546,
     title="Hotel Stripes",
     text="""When this hotel opened in February 2017, it handed out red bricks to its neighbours.

Jalan Kamunting, outside the hotel's front door. Look along the street in either direction and you'll see low rows of shophouses with covered walkways under their upper floors — the five-foot ways that let you walk the length of a Malaysian street without getting rained on. Hotel Stripes is the tall newcomer among them.

This is one of the older corners of Kuala Lumpur. In the colonial era it was a tin-mining settlement, and in the late nineteenth century the British administration had its wooden and thatched buildings replaced with brick and tile, because thatch and a growing town do not mix. What survives now is mostly mid-century shophouses and family businesses that have been here for generations — Yut Kee, the Hainanese coffee shop, and Ah Loke the tailor among them.

The site has a private story, too. The very first office of YTL, the company that built the hotel, stood on this plot. So when it came to opening, the company threw a street party and gave nine of its neighbours — local business owners on Jalan Kamunting — a red brick each, as a token of thanks.

I rather like that gesture, because it says what the building is trying to do. Inside, the restaurant has red-brick arcades, dark wood floors and copper chandeliers shaped like sputniks. Up on the roof there's a pool and a bar with a view across to the KL Tower. It's a contemporary hotel that has chosen, quite deliberately, to look as if it grew up on this street rather than landing on it.

[beat]

From the front door, Yut Kee is round the corner, and it's the obvious next stop — a Hainanese breakfast that has been served since 1928. If you'd rather keep walking, the shophouse rows of Jalan Kamunting reward a slow stroll; look up at the upper-floor windows, where the street's real age shows."""),

dict(num="03", slug="the-ruma-hotel-and-residences", category="STAY",
     gmaps="The RuMa Hotel and Residences", lat=3.152416, lon=101.714374,
     title="The RuMa Hotel and Residences",
     text="""There's a birdcage at the front door of this hotel, and it's there because of the canaries.

You're on Jalan Kia Peng, in the leafy stretch of the Golden Triangle just south of the Petronas Towers. The RuMa is the dark, quietly detailed building in front of you. Step up to the entrance and look into the foyer: you should see a large round cage of terracotta, with a bronze fountain inside it.

RuMa comes from rumah, the Malay word for home. The interiors were led by Andy Hall, a British designer based in Shanghai, and he began not with a style but with research into the two industries that built this city: tin mining and rubber.

The cage is the tin. In mines, miners once carried canaries in small metal cages, because the birds sensed dangerous gas before people did. Here that humble object has been blown up in terracotta and turned into a welcome. Inside, a double staircase appears to drill up through a ceiling tiled in copper, another nod to what came out of the ground. The rubber plantations, meanwhile, are in the bedrooms, which borrow the look of colonial planters' houses.

Look closely at the walls and you'll find kelarai, a traditional hand-woven panel, and the checked cotton cloth called kain pelikat worked into the furnishings. These are everyday Malaysian materials, the kind you'd find in a grandmother's house rather than a palace.

And that's the interesting bit. Luxury hotels usually tell you how far you've travelled. This one keeps trying to tell you where you've arrived, and the story it chooses is not the glamorous one. Kuala Lumpur grew out of muddy tin fields, and the most expensive room in the house is dressed in their memory.

[beat]

When you leave, walk a few minutes south-east to Jalan Stonor and find the Badan Warisan heritage centre. In its garden stands Rumah Penghulu Abu Seman, an old timber house from Kedah — the real thing, raised on stilts, that a hotel like this one is quietly quoting."""),

dict(num="04", slug="kloe-hotel", category="STAY",
     gmaps="KLoé Hotel", lat=3.146949, lon=101.717741,
     title="KLoé Hotel",
     text="""The hotel in front of you opened in March 2020, which, you may recall, was not a vintage month for hotels.

You're on Jalan Bukit Bintang at number two hundred and twenty-seven, the quieter eastern end of the street, away from its busiest stretch. KLoé is the pair of new towers in front of you. Look at what they're made of: bare concrete for the frame, with clay brick, timber and metal laid against it. Nothing is painted to look like something else.

The name runs Kuala Lumpur's initials into Chloe, from the Greek word for a young green shoot, and that little sprout appears in the hotel's logo. It was dreamed up by Ng Ping Ho, a film director and producer, and designed from the ground up by the local practice Domaine Architects. It's small for a city hotel — eighty-five rooms — and that's the point.

Here's what I find most interesting. Most hotels hire one designer and let them furnish every corner. KLoé went the other way and filled itself with the work of the city's own makers: furniture, ceramics and artworks by local designers and craftspeople, alongside mid-century Scandinavian pieces. Five of the suites, called the Lofts, were conceived with local tastemakers, each around a creative pursuit. One, a room for cooks and eaters, was put together by the chef and broadcaster Sarah Benjamin.

So the building works as a kind of catalogue. Stay a night and you've been introduced to a generation of Malaysian designers without visiting a single gallery.

[beat]

From here, walk west along Jalan Bukit Bintang and the street gets steadily louder, brighter and more crowded until you reach the shopping malls and the hawker stalls beyond. It's worth doing once, if only to see how quickly the city changes its mind about what it wants to be."""),

dict(num="05", slug="dewakan", category="DINE",
     gmaps="Dewakan", lat=3.154719, lon=101.718505,
     title="Dewakan",
     text="""The most decorated restaurant in Malaysia began life as a university project.

Look up. You should be at the foot of Naza Tower on Persiaran KLCC, a few minutes' walk from the Petronas Towers. Dewakan is on the forty-eighth floor, so from the pavement there are forty-seven storeys of glass between you and dinner.

It opened in 2015 inside KDU University College in Shah Alam, as a teaching kitchen with ambitions. The chef, Darren Teoh, moved it to this tower a few years later, and the stars followed. It now holds two Michelin stars, and it was the first restaurant in Malaysia to be given a Michelin Green Star, the award for sustainability.

The name is the clue to the cooking. It runs two Malay words together: dewa, meaning god, and makan, to eat. And what Teoh's kitchen eats is almost entirely Malaysian. Not dishes, so much as ingredients — things gathered from farms, jungles, hills and the sea. Kelulut honey, made by tiny stingless bees. A wild citrus from Johor called limau hantu, the ghost lime. Buah keluak, the black seed that is poisonous until it has been properly prepared.

The gift detail is a wild yam called kemili. The team spent about seven years learning to cook it, and in the end borrowed a technique from Latin America, treating it with alkali the way corn is treated for tortillas, to turn it into a kind of dough.

[beat]

That's the argument this restaurant makes. Malaysian food is usually celebrated for its famous dishes. Dewakan suggests the larder is the real treasure, and that most of it has never been on a menu at all.

If you've eaten here, or are simply passing, walk a few minutes west to KLCC Park and look back at this tower from the lake. Then try to work out which window is the forty-eighth floor — it's harder than it looks."""),

dict(num="06", slug="yut-kee", category="DINE",
     gmaps="Yut Kee", lat=3.156483, lon=101.700302,
     title="Yut Kee",
     text="""The menu in here has barely changed since 1928.

You're at number one, Jalan Kamunting, outside a three-storey building that used to be a house. If it's a weekend morning, the queue on the pavement will tell you you're in the right place. Inside, the walls are covered with faded newspaper and magazine clippings, and the room has the plain, bright look of the old Malaysian coffee shops — the kopitiams — of a generation or two ago.

Yut Kee was opened in January 1928 by a cook from Hainan Island, in southern China, who had worked as a private chef for the household of Choo Kia Peng, one of the leading Chinese figures in colonial Kuala Lumpur. After he died in 1947, his three wives kept the business going. His grandson, Mervyn Lee, runs it now and says he has seen fifth-generation customers.

For eighty-six years it traded from a building on Jalan Dang Wangi, round the corner. In 2014 it moved here, and the regulars simply followed.

Now, the food. The famous dish is roti babi: bread stuffed with shredded pork, onion and crab, then fried, and eaten with Worcestershire sauce, which comes to the table as a matter of course. There's a Hainanese chicken chop with gravy, and kaya, the coconut jam, made the slow way in a double boiler and spread on toast.

And here's the thing about that bottle of Worcestershire. Hainanese cooks often worked in British kitchens, and they took the colonial menu home and made it their own. A chicken chop with gravy is not an English dish and not a Chinese one. It's a Kuala Lumpur dish, and this is one of the last places that still cooks it as if nothing had happened since.

[beat]

Before you go, order a slice of the marble cake to take with you; it's baked in-house and it's the one the regulars buy. Then walk the few minutes round the corner to Jalan Dang Wangi and picture the old shop, where all this started."""),

dict(num="07", slug="restoran-sek-yuen", category="DINE",
     gmaps="Restoran Sek Yuen", lat=3.135594, lon=101.712161,
     title="Restoran Sek Yuen",
     text="""In the kitchen behind this facade, they still cook over wood fires.

Jalan Pudu, number three hundred and thirteen. Look for the standalone building with steps leading up to its entrance, a little apart from the shophouse row. Next door, at three hundred and fifteen, is its younger sibling: an extension added in the seventies, said to be one of the first air-conditioned restaurants in the city.

The story starts on the street. In the early 1940s, three brothers of the Phang family sold wantan noodles from a hawker cart. When the war came they fled, and when it ended they came back, which not every hawker did. In 1948 they opened a proper restaurant, and later in the fifties put up the building you're looking at.

Go in, and look up first. The ceilings are high on purpose, to let the heat rise in a room that was built before air conditioning. Then look around: the old fans, tables and chairs, and photographs and newspaper cuttings of the restaurant's own past on the walls. In the sixties this was a fashionable place for wedding banquets.

The gift detail is in the kitchen. Sek Yuen still cooks on wood-fired stoves and a wood-fired steamer, which almost nobody in the city bothers with any more, because wood is slow, dirty and hard to control. It's held to be the key to the traditional flavours the restaurant has always served.

Try the pipa duck: split open and pressed flat until it looks like the Chinese lute it's named after, then roasted and served with lemon sauce.

[beat]

What you're tasting is not nostalgia, exactly. It's what Cantonese restaurant cooking in this city tasted like before electricity made everything faster.

Before you leave, step back to the far side of the pavement and look at how the building stands apart from its neighbours, steps and all. Then come back for dinner if you can, when the place is at its busiest."""),

dict(num="08", slug="bijan-bar-and-restaurant", category="DINE",
     gmaps="Bijan Bar and Restaurant", lat=3.148392, lon=101.705971,
     title="Bijan Bar and Restaurant",
     text="""Twenty-odd years ago, you could struggle to find a proper Malay restaurant in the middle of Kuala Lumpur.

Number three, Jalan Ceylon. You're on a short, sloping street between Bukit Bintang and the city centre, and Bijan is the low colonial-era building in front of you, with its terrace and bar opening onto the street.

Bijan is the Malay word for sesame, and the restaurant was the idea of three friends — Yuen Sze To, Lissa Yeoh and Way Cheng Yeoh — who began researching it in 2002. Their problem was simple. Malay food was everywhere in Malaysia, in homes, at stalls and at weddings, but hardly anyone served it in a restaurant setting, with the care you'd expect for French or Japanese cooking. In 2004, Tourism Malaysia named it the country's best Malay restaurant.

The cooking leans on recipes handed down in the owners' own families, then sharpened with a few restaurant habits — cuts of beef, such as ribs, that you wouldn't normally find in a Malay dish, and plating that takes its time. Look out for the rendang, the slow-cooked spiced beef, and the dishes cooked in masak lemak, a rich turmeric and coconut gravy.

[beat]

What's worth knowing, standing here, is that this restaurant helped change what people thought Malay food was for. Not just something you ate at home, but something you could take a guest to. Plenty of modern Malay restaurants have followed since.

From here, walk up the hill to Changkat Bukit Bintang, a short street of old shophouses turned into bars and restaurants, where the city goes to have dinner and keep going."""),

dict(num="09", slug="nasi-lemak-tanglin", category="DINE",
     gmaps="Nasi Lemak Tanglin", lat=3.144078, lon=101.690677,
     title="Nasi Lemak Tanglin",
     text="""If you arrive after ten o'clock, the chicken may already be gone.

Jalan Cenderasari, on the edge of the government quarter, a short walk from the National Mosque. You're looking for the Tanglin food centre, a covered hawker hall, and inside it, stall number six. If there's a queue, you've found it.

The stall goes back to 1948, when a cook called Suryati Jawirunnah began selling nasi lemak — rice cooked in coconut milk — from a small wooden shack on this very spot, long before the hawker hall was built round it. Her son, Zainal Abidin Hassan, took over and made the sambal himself every morning. Her granddaughter runs it now. Three generations, one stall.

Nasi lemak is the closest thing Malaysia has to a national breakfast, and the plate is built the same way everywhere: coconut rice, crisp fried anchovies, peanuts, cucumber and a spoonful of chilli sambal. The gift detail is that sambal. Suryati cooked hers slowly for three to four hours, and the family still does. It comes out dark red and caramel-sweet, with a heat that arrives a moment later.

Then come the extras, which is where people get competitive: fried chicken, cockles in sambal, squid, beef in a dark sauce. They go fast. The stall opens at seven in the morning and is usually finished by around noon.

[beat]

Here's what I love about this place. It sits a short walk from the police headquarters at Bukit Aman and from the National Mosque, so on any morning the queue is a mix of office workers, officers in uniform and families after prayers, all waiting at the same counter. It's one of the more democratic institutions in the city.

When you've eaten, walk down the hill to Masjid Negara, the National Mosque, and look up at its folded concrete roof. If you've time, the Perdana Botanical Garden is just beyond, and a good place to walk off breakfast."""),

dict(num="10", slug="ps150", category="DRINK",
     gmaps="PS150", lat=3.141045, lon=101.698096,
     title="PS150",
     text="""The way in is through a toy shop.

Number one hundred and fifty, Jalan Petaling, at the southern end of Chinatown. That's where the name comes from: Petaling Street, one-fifty. Look for a small, brightly lit shopfront full of old toys and retro figures. The bar's name is on a modest sign on the wall, and the entrance is a door at the back of the shop.

The building is a pre-war shophouse with a past. In the 1980s it was a brothel, and later a hostel for migrant workers, before it was left empty. When the bar moved in, the owners kept as much of the decay as they could: plaster peeling in its own good time, bare brick, tree roots pushing through the walls.

Once you're through, the bar unfolds in three rooms, and each one is a different period. First, the Opium Den, small and close, with beaded curtains. Then an open-air courtyard. Then the main bar, with a red neon sign that reads Chi Cheung Kai, the old Cantonese name for Petaling Street.

The menu follows the same idea. It's arranged by era — vintage, classic, tiki, disco and contemporary — so you can drink your way from the nineteenth century to the present, and the flavours are local: pandan, lychee, chilli.

[beat]

What's interesting is the timing. PS150 opened in 2016, when this end of Chinatown was mostly closed shutters after dark, and in its first year it was the only bar from Malaysia on the list of Asia's Fifty Best Bars. A good deal of the neighbourhood's revival since has followed in its footsteps.

The upstairs café, Merchant's Lane, ran in the same building for nearly ten years and closed at the start of 2026. From here, Kwai Chai Hong is a couple of minutes' walk away, off Lorong Panggung: a little restored back lane with murals of 1960s street life, and the best place in Chinatown to see what these shophouses looked like from behind."""),
]
