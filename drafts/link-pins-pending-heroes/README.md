# Pending: hero images for 20 @urbanistariel / @littlecommunication.jp link pins

**Context.** A web/remote session (no `gh` CLI available there) minted 20 link pins and merged
them into `Tours.json` on this branch — `claude/atlas-upload-link-pins-t3ybji`. Coordinates,
titles, categories and tags were confirmed with the owner and are already committed.
`swift scripts/validate-tours.swift` / `python3 scripts/validate-tours-mirror.py` are clean
(0 errors, 0 warnings).

**What's missing.** The 20 hero images were cropped locally in that session but could not be
uploaded — no `gh` CLI, and the GitHub MCP file-write tools available there don't support binary
content (tested: they write text literally instead of decoding it, which would corrupt an image).
So `Tours.json` on this branch already points every one of these pins at a `heroImageURL` that
**does not exist yet on gh-pages** — nothing must merge to `main` until that's fixed.

Two other links from the original batch (Rotterdam/Eendrachtsplein, London/Electric Cinema) were
dropped entirely — TikTok's oEmbed returned no thumbnail for either — and are **not** in
`Tours.json` and **not** in `pins.tsv` below. Nothing to do for those two; the owner said not to
worry about them.

## What to run (on a session with normal network + `gh` CLI)

```bash
# 1. Check out this branch
git fetch origin claude/atlas-upload-link-pins-t3ybji
git checkout claude/atlas-upload-link-pins-t3ybji

# 2. Re-generate the 20 hero crops (Tours.json already has the matching entries —
#    this step only needs to reproduce the image files, nothing else).
#    Run once per line in pins.tsv:  <num> <url> <lat> <lon> <city> <country> <category> <tags> <title>
mkdir -p /tmp/heroes
while IFS=$'\t' read -r num url lat lon city country cat tags title; do
  python3 scripts/make-link-pin.py \
    --url "$url" --lat "$lat" --lon "$lon" \
    --city "$city" --country "$country" \
    --category "$cat" --tags "$tags" --title "$title" \
    --out-dir /tmp/heroes \
    > /tmp/heroes/pin$num.json 2> /tmp/heroes/pin$num.stderr
done < drafts/link-pins-pending-heroes/pins.tsv
# (The JSON/stderr output can be ignored/deleted — Tours.json already has these pins.
#  This just re-produces the cropped .webp files in /tmp/heroes.)

# 3. Drop the avatar file if it reappeared — it's already live, byte-identical, no need to re-upload
rm -f /tmp/heroes/avatar-tiktok-urbanistariel.webp

# 4. Upload all 20 heroes to gh-pages in ONE commit
python3 scripts/upload-images.py --dir /tmp/heroes --message "Heroes for 20 link pins: Lyon, Zaanse Schans, Leiden, Bergen op Zoom, Ito, Maastricht, Rotterdam, Amsterdam, Stockholm, Copenhagen, Edinburgh, Canterbury, Paris" --verify

# 5. Confirm nothing broke
python3 scripts/check-image-duplicates.py --pins

# 6. Open the PR from claude/atlas-upload-link-pins-t3ybji into main, let CI go green, merge
```

Once the PR is open and CI is green, this is a content-only change (`Resources/Tours.json` +
`gh-pages` images) so it auto-merges per `CLAUDE.md` § Merging PRs — no owner approval gate.
Don't forget the DB side: `python3 backend/seed_from_toursjson.py` after merge so Supabase's
`get_catalog` (the primary source) picks up the 20 new pins, not just the gh-pages mirror.

Delete this `drafts/link-pins-pending-heroes/` folder once the heroes are uploaded and the PR is
merged — it's a todo list, not a durable record.
