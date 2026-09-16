# Tir na nog, Makiyaki Ginza Onodera, Ginza Kojyu: 3 pins at the same Ginza 5-chome centroid

_opened 2026-09-16 · clear with `git rm status/owner/ginza-5chome-3way-collision.md`_

Follow-up to ginza-shimokitazawa-pin-precision.md (now cleared). Re-geocoded
all 15 stacked pins from real addresses found via web search — most
separated cleanly, see the PR for the full before/after.

These three didn't: Tir na nog (5-9-5 Ginza), Makiyaki Ginza Onodera
(5-14-14 Ginza), and Ginza Kojyu (5-4-8 Ginza, from the #910 batch) are
all genuinely in Ginza 5-chome, and Nominatim has no building-level data
for any of the three addresses -- its best answer for all of them is the
same 5-chome neighbourhood-boundary centroid. Not a geocoding mistake on
my part this time, just a data ceiling. A real fix needs either a paid
geocoder with Japan building-level coverage, or you supplying
coordinates by hand (e.g. from Google Maps) for these three.
