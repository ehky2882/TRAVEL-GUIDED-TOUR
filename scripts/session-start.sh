#!/usr/bin/env bash
# Print the CURRENT state of this project. Run at the start of every session.
#
# WHY THIS EXISTS: CLAUDE.md is excellent at durable facts (why a bug happened,
# why a decision was made) and dangerous at perishable ones (is an agreement
# accepted? is a PR open? which branch is the shared checkout on?). Perishable
# facts change with no commit, so nothing in the repo updates them and they rot
# in place — on 2026-08-19 the owner was told four times by four sessions that
# an agreement they had already accepted was unaccepted, because a stale line
# sat in CLAUDE.md being read as current fact.
#
# The rule this enforces: DO NOT REPORT PERISHABLE STATE FROM A DOCUMENT.
# Run this. If something cannot be checked here, say you could not check it.
#
# Read-only. Touches no branch, no working tree, no remote state.

set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)" || exit 1
REPO="ehky2882/TRAVEL-GUIDED-TOUR"
b() { printf '\n\033[1m%s\033[0m\n' "$*"; }

# ⚠️ `git fetch --prune origin` routinely times out against this repo's git proxy — it hung
# past 2 minutes here and the whole script produced NOTHING, which reads as a broken script
# rather than a slow fetch. Bound it, and fall back to the narrow fetch that does work.
FETCH_NOTE=""
if ! timeout 45 git fetch -q --prune origin 2>/dev/null; then
  timeout 45 git fetch -q origin main 2>/dev/null \
    && FETCH_NOTE="⚠️  full fetch timed out; only origin/main is fresh — § 4 branch list may be stale" \
    || FETCH_NOTE="🔴 git fetch FAILED — everything below is from your last fetch, not the remote"
fi

b "1. WHERE YOU ARE  (the shared checkout is used by every local session)"
BR=$(git rev-parse --abbrev-ref HEAD)
DIRTY=$(git status --porcelain | wc -l | tr -d ' ')
printf '   branch  : %s\n   changes : %s uncommitted\n   vs main : %s ahead, %s behind\n' \
  "$BR" "$DIRTY" "$(git rev-list --count origin/main..HEAD 2>/dev/null)" "$(git rev-list --count HEAD..origin/main 2>/dev/null)"
[ -n "$FETCH_NOTE" ] && echo "   $FETCH_NOTE"
[ "$BR" != "main" ] && echo "   ⚠️  NOT ON main — another session may be mid-task here. Do not switch branches or"
[ "$BR" != "main" ] && echo "       build from this folder without checking. Use a worktree for your own work."
[ "$DIRTY" -gt 0 ] && echo "   ⚠️  UNCOMMITTED CHANGES — find out whose before touching anything."
echo "   worktrees:"; git worktree list | sed 's/^/     /'

b "2. WHAT IS IN FLIGHT RIGHT NOW  (other sessions are working in parallel)"
gh pr list --repo "$REPO" --state open --limit 30 \
  --json number,title,isDraft,mergeable,mergeStateStatus,updatedAt \
  --jq '.[]|"   #\(.number)\(if .isDraft then " [DRAFT]" else "" end) \(.title[0:52])\n       \(.mergeable)/\(.mergeStateStatus)  updated \(.updatedAt[5:16])"' 2>/dev/null \
  || echo "   (gh unavailable)"
echo "   branches ahead of main with no open PR:"
for r in $(git branch -r --format='%(refname:short)' | grep '^origin/' | grep -v 'origin/HEAD\|origin/main\|origin/gh-pages'); do
  n=$(git rev-list --count "origin/main..$r" 2>/dev/null); [ "${n:-0}" -gt 0 ] || continue
  s=${r#origin/}
  gh pr list --repo "$REPO" --state open --head "$s" --json number --jq '.[].number' 2>/dev/null | grep -q . && continue
  printf '     %-46s +%s\n' "$s" "$n"
done

b "3. BEFORE YOU OPEN OR MERGE A PR"
echo "   Someone else may already have done it — this has happened twice (#504/#502, #516/#514)."
git log origin/main --oneline -8 | sed 's/^/     /'

b "4. STAGED CONTENT  (read from origin/main — a branch copy lies)"
git show origin/main:drafts/AUDIO-PENDING-SURVEY.md 2>/dev/null | head -12 | sed 's/^/   /' \
  || echo "   (no tracker on main)"

b "5. EXTERNAL STATE — VERIFY, NEVER ASSERT"
echo "   These live outside the repo and change with no commit. CLAUDE.md CANNOT be trusted for them."
for u in https://dozent.world https://dozent.world/privacy/ https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/Tours.json; do
  printf '   %-56s HTTP %s\n' "$u" "$(curl -s -o /dev/null -w '%{http_code}' -L --max-time 12 "$u" 2>/dev/null)"
done
# The RELEASED App Store version needs no key and works from any session.
# Only an UNRELEASED version's review state needs the ASC key below.
printf '   %-56s ' "App Store (released, public lookup)"
curl -s --max-time 12 "https://itunes.apple.com/lookup?bundleId=com.ehky.TRAVEL-GUIDED-TOUR&country=us" 2>/dev/null \
  | python3 -c 'import json,sys
try:
    r = json.load(sys.stdin)["results"][0]
    print(r["version"] + "  released " + r["currentVersionReleaseDate"][:10])
except Exception:
    print("lookup failed")' 2>/dev/null || echo "lookup failed"

# The PRIMARY catalogue source is the Supabase RPC; the mirror above is only the
# fallback. Sample it — it has been timing out (57014) on a real fraction of calls.
#
# 🔴 --compressed --max-filesize 2000 is an EGRESS fix and is load-bearing.
# get_catalog returns the WHOLE catalogue: ~10.5 MB raw, ~3.5 MB gzipped. This
# check wants the STATUS CODE and threw all of it away to /dev/null — so four
# samples cost ~44 MB of Supabase egress at the start of EVERY session, which
# is a large slice of the quota the owner was emailed about. The server still
# runs the full query (~1.7s, unchanged), the status still arrives in the
# headers BEFORE any body, so a 57014 timeout is still caught exactly as
# before; curl just stops reading once 2 KB has landed.
# ⚠️ curl exits 63 ("filesize exceeded") on success here — that is expected.
# %{http_code} is still correct, which is the only thing this test reads.
# Do NOT "tidy" these flags away: it silently restores a 5,000x egress cost.
if [ -f "TRAVEL GUIDED TOUR/Data/SupabaseConfig.swift" ]; then
  _sb_url=$(grep -o 'https://[a-z0-9]*\.supabase\.co' "TRAVEL GUIDED TOUR/Data/SupabaseConfig.swift" | head -1)
  _sb_key=$(grep -o 'sb_publishable_[A-Za-z0-9_-]*' "TRAVEL GUIDED TOUR/Data/SupabaseConfig.swift" | head -1)
  if [ -n "$_sb_url" ] && [ -n "$_sb_key" ]; then
    _ok=0
    for _i in 1 2 3 4; do
      _c=$(curl -s --compressed --max-filesize 2000 \
             -o /dev/null -w '%{http_code}' --max-time 20 -X POST "$_sb_url/rest/v1/rpc/get_catalog" \
             -H "apikey: $_sb_key" -H "Authorization: Bearer $_sb_key" \
             -H "Content-Type: application/json" -d '{}' 2>/dev/null)
      [ "$_c" = "200" ] && _ok=$((_ok+1))
    done
    printf '   %-56s %s/4 OK\n' "Supabase get_catalog (PRIMARY source)" "$_ok"
    [ "$_ok" -lt 4 ] && echo "                      ⚠️ 57014 statement timeout — app falls back to the gh-pages mirror"
  fi
fi

if [ -n "$(ls ~/Downloads/AuthKey_*.p8 2>/dev/null)" ] && python3 -c 'import jwt,certifi' 2>/dev/null; then
  python3 - <<'PY' 2>/dev/null || echo "   App Store Connect: query failed"
import os,glob,time,json,ssl,urllib.request,jwt,certifi
kp=sorted(glob.glob(os.path.expanduser("~/Downloads/AuthKey_*.p8")))[0]
kid=os.path.basename(kp)[8:-3]; ctx=ssl.create_default_context(cafile=certifi.where()); now=int(time.time())
t=jwt.encode({"iss":"f34324bd-aa34-4de0-8acb-2537b0e9325e","iat":now,"exp":now+600,"aud":"appstoreconnect-v1"},
             open(kp).read(),algorithm="ES256",headers={"kid":kid,"typ":"JWT"})
def g(p):
    r=urllib.request.Request("https://api.appstoreconnect.apple.com/v1/"+p,headers={"Authorization":"Bearer "+t})
    return json.loads(urllib.request.urlopen(r,context=ctx).read())
v=g("apps/6771030927/appStoreVersions?limit=1")["data"][0]["attributes"]
print(f"   App Store       : {v['versionString']} {v['appStoreState']}  release={v['releaseType']}")
bs=g("builds?filter[app]=6771030927&limit=1&sort=-uploadedDate")["data"]
if bs:
    a=bs[0]["attributes"]
    print(f"   latest build    : {a['version']} {a['processingState']} ({a['uploadedDate'][:16]})")
    print("   agreement       : ACCEPTED — a build uploaded and processed; an unaccepted")
    print("                     Program License Agreement blocks uploads outright.")
PY
else
  echo "   App Store Connect: SKIPPED (no key at ~/Downloads/AuthKey_*.p8, or PyJWT/certifi missing)"
  echo "                      Say you did not check it. Do NOT repeat what CLAUDE.md says."
fi
echo
echo "   Cannot be checked from here — ask the owner, never assert:"
echo "     • EU Digital Services Act trader declaration"
echo "     • Stripe account standing"
echo "     • Tax / banking / agreements in ASC Business (Apple exposes no API)"
b "What the owner owes right now:"
if [ -f scripts/status.py ]; then
  python3 scripts/status.py --owner 2>/dev/null | sed 's/^/   /' \
    || echo "   (scripts/status.py failed — read status/owner/ directly)"
else
  echo "   (scripts/status.py missing — read status/owner/ directly)"
fi
echo
echo "   Full board: python3 scripts/status.py"
echo "   🔴 Record what happened with scripts/status.py, NEVER by editing STATUS.md —"
echo "      that is what blocked #776, #820 and #843 behind documentation conflicts."

b "Now read the newest handoff:"
ls archive/HANDOFF-*.md 2>/dev/null | tail -1 | sed 's/^/   /'
