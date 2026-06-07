# Atlas — Handoff Notes (2026-06-07, session 26)

Web/PM session — **TestFlight 1.0 (35) cut and shipped**. No Swift /
asset / project-structure changes beyond the `project.pbxproj` build
bump. Catalog unchanged at **149 tours / 3 makers**.

---

## What happened
- Build bumped **34 → 35** direct-to-main (`ce32d88`) — app-target
  `CURRENT_PROJECT_VERSION` lines only (2 instances); test-target lines
  stay `1`. `MARKETING_VERSION` stays `1.0`.
- `xcodebuild archive` clean at `/tmp/Atlas-20260607-0649.xcarchive`
  (~4 min). Embedded version verified `1.0 (35)`.
- **No validation error 90474** — the `UIRequiresFullScreen=YES` /
  iPad-orientation fix from build 34 (`62d00df`) held; archive validated
  clean.
- Owner uploaded via Xcode Organizer. **1.0 (35) is live on TestFlight.**

## What build 35 carries
- **PR #159** — Player presented from the top window: gapless
  full-screen transition + floating island on retract (session 24).
- **PR #160** — place-search perf: instant city suggestions via
  `MKLocalSearchCompleter` + on-tap resolve spinner (session 25).
- **7 tours' new photo galleries:** Intrepid, Little Island, Manhattan
  Bridge, Chelsea Hotel, Four Freedoms Park, Unisphere, Cooper Union.

## Notes for next session
- Archive was Apple Development–signed; Organizer re-signs with the
  Distribution cert at Distribute App (normal flow, every prior build).
- Carried open follow-ups (unchanged): on-device M-qa pass incl.
  multi-stop walking tours; design/polish pass (Theme tokens still
  placeholder); the cosmetic `MKMapItem.placemark` iOS-26 deprecation
  warning in `PlaceSearchService`; device pass on the Player
  drag-to-dismiss + volume/AirPlay (sim can't exercise these).

## How to resume
1. Session-start ritual (git/PR health + read this HANDOFF).
2. Latest live build is **1.0 (35)**. Next TestFlight cut: bump 35 → 36.
