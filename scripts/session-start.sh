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

git fetch -q --prune origin 2>/dev/null

b "1. WHERE YOU ARE  (the shared checkout is used by every local session)"
BR=$(git rev-parse --abbrev-ref HEAD)
DIRTY=$(git status --porcelain | wc -l | tr -d ' ')
printf '   branch  : %s\n   changes : %s uncommitted\n   vs main : %s ahead, %s behind\n' \
  "$BR" "$DIRTY" "$(git rev-list --count origin/main..HEAD 2>/dev/null)" "$(git rev-list --count HEAD..origin/main 2>/dev/null)"
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
b "Now read the newest handoff:"
ls archive/HANDOFF-*.md 2>/dev/null | tail -1 | sed 's/^/   /'
