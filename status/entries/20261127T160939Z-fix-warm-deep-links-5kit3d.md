# Fix links that do nothing when the app is already open

_2026-11-27 16:09 UTC · branch `fix-warm-deep-links-5kit3d`_

Shared tour/creator links did nothing when the app was already open (the layer was presented before the scene became active, and could land under an open page or the full player). Fix waits for the scene, clears what is in the way, then presents. Code PR: waits for owner OK + device test.
