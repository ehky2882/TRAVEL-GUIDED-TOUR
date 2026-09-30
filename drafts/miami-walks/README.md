# Miami walks W1–W5: wire-in pick-map

**5 multi-stop walks, 33 stops · Atlas Studio MIA (`aed488af-23d3-514f-90f1-035ca2285d0d`) · staged 2026-09-29**

The 30 Miami singles are live (#1103). These walks are the rest of the author's non-gated corpus:
`miami_tour_master_list.md` § 4 in the owner's 2026-09-29 Dropbox drop, which also carried the MP3s. The master
list's standpoints, plus a whisper-tiny transcript of every recording, drove the stop list and order below.

## 🔴 Still owed before wire-in

1. **The Grove intro recording** (`miami_w4_00_intro.mp3`). The drop's file is **byte-identical to Calle Ocho's
   Woodlawn stop** (`miami_w3_c_woodlawn.mp3`); its transcript opens "The gate of Woodlawn Park Cemetery stands
   before you… Calle Ocho at 32nd Avenue". The Grove's real intro is missing. `miami-grove-walk_stop0.mp3` is **not**
   on gh-pages; the other 32 are (`579feac8`).
2. ~~**The 33 walk scripts**~~ ✅ **received 2026-09-30**, all 33 clean + `_TTS` pairs, in `scripts/`. Each clean script was matched against its recording's transcript (88–100% on the opening 120 words); only the Grove intro fails, because its recording is the wrong file. They are on `main`, against the drafts-stay-on-staging convention, because this session could push only to its own branch and the container is temporary.
3. **Photos: 7 of 11 done (2026-09-30), on gh-pages**, all credited in `drafts/CREDITS.md`:
   `miami-pitch_stop5` (Olympia), `miami-calle-ocho_stop2` (Walk of Fame), `miami-calle-ocho_stop5` (Woodlawn),
   `miami-grove_stop1` (Charles Ave), `miami-grove_stop2` (Plymouth), `miami-grove_stop4` (Vizcaya gate),
   `miami-water-line_stop2` (Venetian Causeway). `miami-ocean-drive_stop4` (the Senator Hotel: an owner-supplied historic B&W print, **source unknown**, upscaled 1.2× from 1024×753). `miami-water-line_stop3` (Maurice Gibb Park sign, owner photo). **Still owed:**
   W5-4 Purdy Avenue, W5-5 Sunset Harbour. Openverse had nothing usable for the Senator or Sunset Harbour, and only
   weak candidates for Gibb and Purdy, so these need owner photos.

## Walks

| Walk | Title | Tour slug | Stops | Audio total | Author's route |
|---|---|---|---:|---:|---|
| W1 | *The Pitch* | `miami-pitch-walk` | 9 | 13 min 59 s | ~1.7–2 mi |
| W2 | *Ocean Drive* | `miami-ocean-drive-walk` | 7 | 10 min 29 s | ~2 mi |
| W3 | *Calle Ocho* | `miami-calle-ocho-walk` | 6 | 8 min 52 s | ~1.5 mi (Woodlawn is far west) |
| W4 | *The Grove* | `miami-grove-walk` | 5 | 7 min 25 s (incl. the wrong intro file) | ~3.5 mi |
| W5 | *The Water Line* | `miami-water-line-walk` | 6 | 8 min 37 s | ~1 mi |

Tour/stop ids at wire-in: uuid5 `atlas-tour:mia:<tour slug>` and `atlas-stop:mia:<tour slug>:<order>`,
following the singles, **but check the existing multi-stop scheme first** (e.g. an ATL, GLA or IST walk) and use that if it differs.
Audio is `audio/<tour slug>_stop<order>.mp3`, the Chicago/Glasgow walk convention. The intro is stop 0 at the start point.

## Stops

Coordinates were derived 2026-09-29, reverse-geocoded, and park/cemetery points checked against OSM outlines. Confidence: 27 high, 6 medium.
**A stop that re-visits a live single reuses its coordinate EXACTLY**, because several singles are places now (The
Barnacle, Casa Casuarina). A stop sits ON its subject (owner, 2026-09-23), so W2-2 uses the Lummus Park point
even though the script stands on the hotel-side sidewalk.

| Stop | Label | lat | lon | conf | Image | Audio | s | Note |
|---|---|---|---|---|---|---|---:|---|
| W1-0 | Intro | 25.771200 | -80.192300 | high | **new** | `miami-pitch-walk_stop0.mp3` | 80 | SE 4th St at the Fort Dallas Park frontage, under the Metromover by Riverwalk station; start point beside stop |
| W1-1 | Palm Cottage, Fort Dallas Park | 25.770931 | -80.192335 | high | `royal-palm-hotel-site_hero` | `miami-pitch-walk_stop1.mp3` | 108 | OSM building way435740415 at 60 SE 4th St, wikidata Q429555 = Palm Cottage; own point, not the Royal Palm sing |
| W1-2 | Dade County Courthouse | 25.774587 | -80.195136 | high | `dade-county-courthouse_hero` | `miami-pitch-walk_stop2.mp3` | 83 | reuses single dade-county-courthouse exactly |
| W1-3 | Miami-Dade Cultural Center | 25.774463 | -80.196586 | high | `miami-dade-cultural-center_hero` | `miami-pitch-walk_stop3.mp3` | 85 | reuses single miami-dade-cultural-center exactly |
| W1-4 | Alfred I. duPont Building | 25.774540 | -80.190642 | high | `dupont-building_hero` | `miami-pitch-walk_stop4.mp3` | 87 | reuses single dupont-building exactly |
| W1-5 | Olympia Theater (connective) | 25.774104 | -80.190476 | high | **new** | `miami-pitch-walk_stop5.mp3` | 98 | OSM theatre node 1025611004, 174 E Flagler St, south side of Flagler directly opposite duPont |
| W1-6 | Gesu Church | 25.775983 | -80.191663 | high | `gesu-church_hero` | `miami-pitch-walk_stop6.mp3` | 86 | reuses single gesu-church exactly |
| W1-7 | Freedom Tower | 25.780312 | -80.189714 | high | `freedom-tower_hero` | `miami-pitch-walk_stop7.mp3` | 112 | reuses single freedom-tower exactly |
| W1-8 | Bayfront Park | 25.775380 | -80.186166 | high | `bayfront-park_hero` | `miami-pitch-walk_stop8.mp3` | 100 | reuses single bayfront-park exactly |
| W2-0 | Intro | 25.767250 | -80.135500 | high | **new** | `miami-ocean-drive-walk_stop0.mp3` | 77 | inside South Pointe Park polygon at its Washington Ave / South Pointe Dr entrance (point-in-polygon checked);  |
| W2-1 | South Pointe Park | 25.765923 | -80.133447 | high | `south-pointe-park_hero` | `miami-ocean-drive-walk_stop1.mp3` | 70 | reuses single south-pointe-park exactly / reverse lands on P1 parking lot but point-in-polygon confirms it is  |
| W2-2 | Ocean Drive | 25.780613 | -80.129893 | high | `ocean-drive-art-deco_hero` | `miami-ocean-drive-walk_stop2.mp3` | 110 | reuses single ocean-drive-art-deco exactly / Lummus Park centroid on the beach side; author wanted hotel-side  |
| W2-3 | Casa Casuarina | 25.782015 | -80.130630 | high | `casa-casuarina_hero` | `miami-ocean-drive-walk_stop3.mp3` | 85 | reuses single casa-casuarina exactly |
| W2-4 | The Senator (connective) | 25.782947 | -80.130886 | medium | **new** | `miami-ocean-drive-walk_stop4.mp3` | 89 | OSM address node 1201 Collins Ave (east side, just north of 12th St); building demolished 1988, no named featu |
| W2-5 | Española Way | 25.786906 | -80.132850 | high | `espanola-way_hero` | `miami-ocean-drive-walk_stop5.mp3` | 82 | on OSM pedestrian way1017291502 (Washington -80.13182 to Drexel -80.13300), ~15 m in from Drexel; 44 m W of si |
| W2-6 | Lincoln Road (east end) | 25.790750 | -80.132500 | high | `lincoln-road_hero` | `miami-ocean-drive-walk_stop6.mp3` | 116 | Lincoln Road Mall footway between Washington (-80.1320) and Drexel (-80.1331); 400 m E of single 07 |
| W3-0 | Intro | 25.765720 | -80.216570 | high | **new** | `miami-calle-ocho-walk_stop0.mp3` | 81 | SW 8th St x SW 13th Ave (13th Ave way ends 25.76580,-80.21657 at 8th St) |
| W3-1 | Cuban Memorial Boulevard | 25.765400 | -80.216700 | high | `cuban-memorial-boulevard_hero` | `miami-calle-ocho-walk_stop1.mp3` | 108 | reuses single cuban-memorial-boulevard exactly |
| W3-2 | Calle Ocho Walk of Fame (connective) | 25.765690 | -80.218050 | medium | **new** | `miami-calle-ocho-walk_stop2.mp3` | 76 | SW 8th St at ~SW 14th Ave, midway 13th Ave to Tower Theater; stars run 12th-17th Ave so any point on the stret |
| W3-3 | Tower Theater | 25.765357 | -80.219672 | high | `tower-theater_hero` | `miami-calle-ocho-walk_stop3.mp3` | 75 | reuses single tower-theater exactly |
| W3-4 | Domino Park | 25.765491 | -80.219374 | high | `maximo-gomez-park_hero` | `miami-calle-ocho-walk_stop4.mp3` | 110 | reuses single maximo-gomez-park exactly |
| W3-5 | Woodlawn Park Cemetery gate (connective) | 25.764470 | -80.248550 | high | **new** | `miami-calle-ocho-walk_stop5.mp3` | 82 | OSM gate node 3262295528 on the entrance drive off SW 8th St (way 319768604), matches 3260 SW 8th St address p |
| W4-0 | Intro | 25.725420 | -80.253100 | medium | **new** | `miami-grove-walk_stop0.mp3` ⚠️ held | 82 | inside NW corner of Charlotte Jane Memorial Park Cemetery (way1328880265) at Charles Ave x Douglas Rd (25.7255 |
| W4-1 | Charles Avenue (connective) | 25.725510 | -80.246295 | medium | **new** | `miami-grove-walk_stop1.mp3` | 86 | OSM building way638572551 = 3298 Charles Ave (Mariah Brown House address); connective subject is the avenue, p |
| W4-2 | Plymouth Congregational Church (connective) | 25.722030 | -80.248380 | medium | **new** | `miami-grove-walk_stop2.mp3` | 84 | OSM building way436040740 = 3400 Devon Rd (13 m tall), between Devon Rd and Main Hwy; unnamed in OSM, church p |
| W4-3 | The Barnacle / Peacock Park | 25.725332 | -80.242557 | high | `the-barnacle_hero` | `miami-grove-walk_stop3.mp3` | 111 | reuses single the-barnacle exactly / reverse returns 3190 Via Abitare Way but point-in-polygon confirms it is  |
| W4-4 | Vizcaya approach (connective) | 25.745800 | -80.212400 | medium | **new** | `miami-grove-walk_stop4.mp3` | 82 | just inside the Vizcaya grounds polygon on the entrance drive off S Miami Ave (drive leaves the avenue at 25.7 |
| W5-0 | Intro | 25.790590 | -80.139950 | high | **new** | `miami-water-line-walk_stop0.mp3` | 68 | Lincoln Rd x Lenox Ave (Lenox way at -80.13999) |
| W5-1 | Lincoln Road (west end) | 25.790565 | -80.140950 | high | `lincoln-road_hero` | `miami-water-line-walk_stop1.mp3` | 100 | west end of Lincoln Road footway (ends -80.14107 at Alton Rd, beside 1111 Lincoln Rd garage) |
| W5-2 | Venetian Causeway foot (connective) | 25.791770 | -80.144330 | high | **new** | `miami-water-line-walk_stop2.mp3` | 82 | junction of Venetian Way (bridge end -80.14432), Dade Blvd and Purdy Ave |
| W5-3 | Maurice Gibb Memorial Park (connective) | 25.793100 | -80.144800 | high | **new** | `miami-water-line-walk_stop3.mp3` | 73 | inside Maurice Gibb Memorial Park polygon (way258236772, point-in-polygon checked), near its 18th St/Purdy NE  |
| W5-4 | Purdy Avenue (connective) | 25.794500 | -80.144450 | high | **new** | `miami-water-line-walk_stop4.mp3` | 77 | on Purdy Ave midway 18th St (25.79353) and 20th St (25.79550), beside Sunset Harbour marina |
| W5-5 | Sunset Harbour (connective) | 25.795500 | -80.144350 | high | **new** | `miami-water-line-walk_stop5.mp3` | 117 | Purdy Ave bends into 20th St at 25.79548,-80.14441 |

⚠️ **Stops under 60 m apart (overlapping 40 m geofences), not moved:** W1-0→W1-1 (30 m, intro beside its first stop);
W1-4→W1-5 (51 m, duPont and the Olympia face each other across Flagler); W3-0→W3-1 (38 m); W3-3→W3-4 (33 m, the
Tower Theater and Domino Park, the same pair as singles 25 and 08).

⚠️ **Reused singles with a stale README hero:** use the live catalogue's `heroImageURL` for each reused single
(e.g. `dupont-building_hero-2`, `gesu-church_hero-2`, `tower-theater_hero-2`), never the `_hero` shown above by slug.

## The author's own open items
`miami_session_handoff.md` (in the drop) lists **pre-record flags 25–66** as open. Many are walk facts that go
out of date: causeway status, Alton Road roadwork, the pump station, route estimates. They were recorded anyway.
Worth a verify-or-soften pass before the walks go live.
