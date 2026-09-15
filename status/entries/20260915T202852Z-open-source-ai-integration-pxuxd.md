# Automated the "More like this" rebuild: new rebuild-related job in publish-catalog.yml regenerates, validates and commits to main with [skip ci] on every content merge, before the mirror and Supabase seed. Vector cache deliberately rejected (a stale cache fails silently; compute is free). ⚠️ The commit-and-push path CANNOT be exercised from a web session — watch the next city launch or pin batch for a 'chore(catalog): rebuild More like this suggestions' commit on main.

_2026-09-15 20:28 UTC · branch `open-source-ai-integration-pxuxd`_
