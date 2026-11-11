# Handoff 2026-11-07: 50-pin triage batch (mostly Fukuoka food)

A contributor (not the owner) pasted 66 links from about 50 creators and asked for a triage first. They then approved it with "go, use Hirao main store, skip 35 and 60".

## What shipped
- **50 link pins** from 38 creators, 28 of them new. 21 are Fukuoka restaurants and shops. The rest are architecture and history from Weil am Rhein (Vitra ×3), New York, San Francisco, Seoul, Bali, Hong Kong, Bahrain, Rotterdam and elsewhere.
- Every restaurant was identified by searching its name, its caption address or the sign on its cover frame. Each Japanese address was geocoded through GSI to house-number precision. Japanese and Korean venues carry bilingual titles.
- Heroes: 50, plus one avatar for @fabie_schmidt. They went to gh-pages in a single plumbing commit (`e6d7401`, 51 additions and nothing else), because `upload-images.py`'s gh API write returned 403 through the proxy.
- Validator: 0 errors. The Wikidata spine lookups were refreshed (50 asked, 0 failed).

## Not minted (owner board: `status/owner/pins-261107-held.md`)
- 4 posts whose place could not be identified (one @brian.l.heyburn, three @fabie_schmidt).
- 3 posts that raise an advertising question: the Marisfrolg brand account, a `#pr` post and a `#klookkreator` post.
- Ikeda Kasuri (the caption's address and the directory listings disagree), Menya Kanetora (the creator's review is negative), and Cinema on the Moon (no street address; tabelog is blocked in this environment).
- Skipped on the contributor's word: the T+L yatai tour (a route) and the Takayama pawnshop. Skipped as same-creator duplicates: the Storm King TikTok cross-post, and @archimarathon's Gion Ishi Sakashita and Organic Building.

## Places (owner board: `status/owner/place-triage-261107.md`)
Eight sites, none created or joined: Imaya (3 entries), Nanzoin (2 new), Grace Farms, Doshi Retreat, Etxebarri, Atlantikos, Syracuse Cathedral (71 m), and Operaparken (join, 28 m).

## Traps hit
- `make-link-pin.py --batch` applies one category and one tag set to every pin and ignores `--title`. For a mixed batch, run it once per URL with `--title`, `--slug`, `--category` and `--tags`, then combine the outputs.
- `merge-link-pins.py` refuses a title containing `?`. "I'm donut?" became "I'm Donut Tenjin | アイムドーナツ 天神店". The hero filename was already `im-donut-tenjin-…` and did not change.
