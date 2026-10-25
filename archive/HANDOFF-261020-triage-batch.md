# Handoff 2026-10-20: 26-pin triage batch from 17 creators

## What shipped

A contributor (arthur.yung) pasted 33 links: 23 Instagram reels and 10 TikTok short links. Each was triaged first and
nothing was added until they had approved the list.

- **26 link pins added**, from 17 creators. 5 creators are new: @tigerjohnson04, @josh.snaith11 and @georgiastylianides
  on Instagram, and @thearchitectscookbook and @ernesto.rojas on TikTok.
- **7 links skipped:**
  - three already pinned: Cinemateket, Re:think CPH, The Egg
  - Seagram (TikTok), the same "Episode 22" video @archiwhisperer already has pinned from Instagram
  - the dolmens/Karnak explainer, which was filmed in a studio and is not about one place
  - Anne Gates Studio, which has no storefront
  - Heath Ceramics, skipped by the contributor because the video does not say which location it means
- Two posts were narrowed to one subject. From @thedesignssuite's "Let's talk housing" part 3, only **McGrath Road** was
  pinned, because the same creator already pins Dunboyne Road. From @ninosbuildings' Bruce Goff video, only **Boston Avenue
  Methodist Church** was pinned, at the contributor's choice; the Tulsa Spotlight Theatre was left out.
- 28 images (26 heroes and 2 new TikTok avatars) went to gh-pages in one commit, `98f30b3`: 28 additions and nothing else.
  The ninosbuildings avatar was regenerated but **not** uploaded, because that creator already exists and overwriting a
  live URL is forbidden.

## Fix: TikTok oEmbed went blank (`scripts/make-link-pin.py`)

As of 2026-10-20, `tiktok.com/oembed` returns only the iframe for every post: no title, no author, no thumbnail. Every
TikTok link failed with "no thumbnail", and `triage-account.py` reported all of them as DEAD. The new `tiktok_page_meta()`
reads the same fields from the video page's `__UNIVERSAL_DATA_FOR_REHYDRATION__` JSON when oEmbed has none. If the page
changes shape it returns `{}`, so the existing refusal still fires. Selftest: 78/78.

⚠️ **`triage-account.py` still runs `vm.tiktok.com` links straight through and reports them DEAD.** Resolve each one first
(`curl -w '%{redirect_url}'`) and triage the full `/@user/video/<id>` URL. The page JSON also carries a `poi` (TikTok
location tag) and `subtitleInfos` (auto-captions), which identified the Tulsa buildings and the three Ernesto Rojas shops.

## Coordinates worth knowing

- **Schmidl Mausoleum**: 47.4787, 19.1787, by the cemetery's west entrance (dark-tourism.com). The existing Kozma Street
  cemetery pin sits about 480 m east, so the new pin was not stacked on it.
- **SOBEK**: Kronprinsessegade 15 (its own site), on the King's Garden edge.
- **Traktørstedet Vestamager**: the city is **Tårnby**, at the contributor's choice.
- **Modfruit**: The Barnyard, Carmel (Carmel Valley side). The video says "Bay Area"; it is about two hours south.
- The nine stacked pins sit exactly on the existing entry's coordinate. Places are left to Edward:
  `status/owner/place-triage-261020.md`.

## Owner

`status/owner/place-triage-261020.md` holds 4 joins and 5 new places. No Supabase reseed is owed: publish-catalog seeds it
on merge.
