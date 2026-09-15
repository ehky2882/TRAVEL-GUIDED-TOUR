# Link pins joined "More like this" in both directions (#926, merged). Verified on the live RPC: 3,482 entries carry neighbours (1,580 tours + 1,902 pins), 23,951 references, 0 unresolvable, 790 pin references under tours. Egress +291,452 bytes gzip-1 — the whole feature is now 604,716 bytes, 19% of the payload. Owner reviewed on build 163 and confirmed it reads well. ⚠️ OUTSTANDING: the nearbySubtitleText fix (a pin no longer claiming a zero duration in Nearby Tours) merged AFTER 163 was cut, so it is not on any build yet.

_2026-09-15 19:14 UTC · branch `pins-more-like-this-closeout`_
