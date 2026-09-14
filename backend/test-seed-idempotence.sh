#!/usr/bin/env bash
#
# Prove that a seed which changes nothing WRITES nothing.
#
# WHY THIS EXISTS
# ---------------
# `seed_from_toursjson.py` used to end every upsert with `updated_at = now()`
# unconditionally, so an identical re-seed rewrote every row in the catalogue —
# measured here, 3,745 of 3,745 tours, 424 of 424 makers, 303 of 303 places and
# all 4,117 stops, about five times a day. That is pure WAL, bloat and
# autovacuum on the instance that was unreachable for 11h45m on 2026-09-14, and
# it made `updated_at` useless as a "what changed?" signal because the answer
# was always "everything" (docs/delta-catalog-fetch-design.md § 5).
#
# 🔴 THE REGRESSION IS INVISIBLE WITHOUT THIS TEST. Re-adding an unconditional
# `updated_at = now()`, or adding a column to the `set` list and forgetting the
# `where` guard, produces a seed that is still CORRECT — the content lands, the
# app is fine, CI is green. The only symptom is churn and a delta cursor that
# silently returns the whole catalogue. Nothing else in this repo would notice.
#
#   bash backend/test-seed-idempotence.sh
#
# Creates a throwaway cluster in a temp dir, throws it away afterwards, and
# touches nothing else. Exit 0 = pass. Exit 1 = fail. Exit 2 = COULD NOT VERIFY,
# which is NOT a pass.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CATALOG="$ROOT/TRAVEL GUIDED TOUR/Resources/Tours.json"
echo "RUN test-seed-idempotence · rev $(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo '?') · $(date -u +%Y-%m-%dT%H:%M:%SZ)"

PGBIN=""
for c in "$(command -v initdb 2>/dev/null || true)" /usr/lib/postgresql/*/bin/initdb \
         /opt/homebrew/opt/postgresql@16/bin/initdb; do
    [ -x "$c" ] && { PGBIN="$(dirname "$c")"; break; }
done
[ -n "$PGBIN" ] || { echo "COULD NOT VERIFY - no PostgreSQL found (apt-get install postgresql)"; exit 2; }
[ -f "$CATALOG" ] || { echo "COULD NOT VERIFY - no catalogue at $CATALOG"; exit 2; }

PGDIR="$(mktemp -d /tmp/pgseed.XXXXXX)"
cleanup() {
    "$PGBIN/pg_ctl" -D "$PGDIR/data" -m immediate stop >/dev/null 2>&1 || true
    rm -rf "$PGDIR"
}
trap cleanup EXIT
[ "$(id -u)" = "0" ] && chown postgres:postgres "$PGDIR"
asdb() { if [ "$(id -u)" = "0" ]; then su postgres -c "$1"; else eval "$1"; fi; }

asdb "$PGBIN/initdb -D $PGDIR/data -A trust -U postgres" >/dev/null 2>&1
asdb "$PGBIN/pg_ctl -D $PGDIR/data -l $PGDIR/log -o '-k $PGDIR -c listen_addresses=' -w start" >/dev/null 2>&1
PSQL="psql -h $PGDIR -U postgres -q -v ON_ERROR_STOP=1"
Q()  { psql -h "$PGDIR" -U postgres -tAc "$1" 2>/dev/null | tr -d '[:space:]'; }

# Supabase ships these roles and an auth schema; schema.sql references both.
$PSQL -c "create role anon; create role authenticated; create schema auth;
          create table auth.users (id uuid primary key);" >/dev/null 2>&1 \
  || { echo "COULD NOT VERIFY - could not prepare the cluster"; exit 2; }

# The real schema, then the migrations that add columns the seed writes.
# usernames.sql and paid_tours.sql are NOT applied: they depend on the accounts
# stack, and the two columns the seed needs from them are added directly.
for m in schema.sql add_link_pin_kind.sql add_video_urls.sql add_video_role.sql \
         add_link_pins.sql add_country.sql places.sql; do
    $PSQL -f "$ROOT/backend/$m" >/dev/null 2>&1 \
      || { echo "COULD NOT VERIFY - $m did not apply to a clean cluster"; exit 2; }
done
$PSQL -c "alter table public.makers add column if not exists platform text;
          alter table public.makers add column if not exists handle text;" >/dev/null 2>&1

# The change under test.
$PSQL -f "$ROOT/backend/catalog_rev.sql" >/dev/null 2>&1 \
  || { echo "  x catalog_rev.sql failed to apply"; exit 1; }
# It advertises itself as safe to re-run.
$PSQL -f "$ROOT/backend/catalog_rev.sql" >/dev/null 2>&1 \
  || { echo "  x catalog_rev.sql is NOT idempotent - it fails on a second run"; exit 1; }
echo "  ok catalog_rev.sql applies and re-applies"

gen() { python3 "$ROOT/backend/seed_from_toursjson.py" --input "$1" -o "$2" 2>/dev/null; }
gen "$CATALOG" "$PGDIR/seed.sql" || { echo "COULD NOT VERIFY - seed generation failed"; exit 2; }
[ "$(id -u)" = "0" ] && chown postgres:postgres "$PGDIR"/*.sql
$PSQL -f "$PGDIR/seed.sql" >/dev/null 2>&1 || { echo "  x the seed did not apply to a clean database"; exit 1; }

TOURS=$(Q "select count(*) from public.tours")
[ "${TOURS:-0}" -gt 100 ] || { echo "COULD NOT VERIFY - only '${TOURS:-0}' tours loaded"; exit 2; }
echo "  ok seeded $TOURS tours / $(Q 'select count(*) from public.stops') stops / $(Q 'select count(*) from public.makers') makers / $(Q 'select count(*) from public.places') places"

fail=0
say_fail() { echo "  x $1"; fail=1; }

# --- THE MAIN CLAIM -------------------------------------------------------
# An identical re-seed must not write a single row.
# ⚠️ The marker is load-bearing, and getting it wrong is how this test first
# reported a failure that was not there. A relative window ("written in the
# last two minutes") cannot tell a row written by the FIRST seed from one
# written by the second, because on a fresh cluster both are seconds old.
# Take an exact instant between the two runs and compare against that.
# Epoch seconds rather than a timestamp literal: the shell helper collapses
# whitespace, which would mangle '2026-09-14 18:11:26+00' into nonsense.
REV0=$(Q "select max(rev) from public.tours")
MARK=$(Q "select extract(epoch from clock_timestamp())")
XID=$(Q "select pg_snapshot_xmax(pg_current_snapshot())::text::bigint")
$PSQL -f "$PGDIR/seed.sql" >/dev/null 2>&1 || say_fail "the seed failed on a second run"
REV1=$(Q "select max(rev) from public.tours")
[ "$REV0" = "$REV1" ] || say_fail "an identical re-seed moved max(tours.rev) $REV0 -> $REV1"
for tbl in tours makers places stops; do
    n=$(Q "select count(*) from public.$tbl where extract(epoch from updated_at) > $MARK")
    [ "${n:-x}" = "0" ] || say_fail "an identical re-seed rewrote $n $tbl row(s) - the 'where' guard is gone"
    # 🔴 And the same question asked of the STORAGE, not the bookkeeping.
    # `updated_at` is maintained by a trigger that declines to move it when the
    # content is unchanged — so for `stops` in particular a row can be rewritten
    # (new tuple, new WAL, new dead row for autovacuum) with `updated_at`
    # sitting perfectly still. That is precisely the waste this change exists to
    # remove, and the timestamp check above is structurally blind to it.
    # `xmin` is the transaction that produced the row version, so comparing it
    # against a snapshot taken between the two runs sees the rewrite itself.
    n=$(Q "select count(*) from public.$tbl where xmin::text::bigint >= $XID")
    [ "${n:-x}" = "0" ] || say_fail "an identical re-seed produced $n new $tbl row version(s) - wasted writes"
done
[ "$fail" = "0" ] && echo "  ok an identical re-seed writes nothing (0 rows across all four tables)"

# --- AND IT MUST STILL NOTICE REAL CHANGES --------------------------------
# 🔴 The failure mode this guards against is a guard that is TOO broad — one
# that suppresses genuine edits. That would stop content reaching phones, which
# is far worse than the churn this fixes.
python3 - "$CATALOG" "$PGDIR" <<'PY'
import json, sys
src, out = sys.argv[1], sys.argv[2]
d = json.load(open(src))
t = next((x for x in d["tours"] if len(x["stops"]) >= 3), d["tours"][0])
open(out + "/target.txt", "w").write(t["id"])

a = json.loads(json.dumps(d))                    # one tour's title
next(x for x in a["tours"] if x["id"] == t["id"])["title"] += " (edited)"
json.dump(a, open(out + "/m_title.json", "w"))

b = json.loads(json.dumps(d))                    # one STOP's coordinate
bt = next(x for x in b["tours"] if x["id"] == t["id"])
bt["stops"][0]["latitude"] = round(bt["stops"][0]["latitude"] + 0.0007, 6)
json.dump(b, open(out + "/m_stop.json", "w"))

c = json.loads(json.dumps(d))                    # a stop inserted MID-WALK
ct = next(x for x in c["tours"] if x["id"] == t["id"])
new = json.loads(json.dumps(ct["stops"][0]))
new["id"] = "0fa1dead-0000-4000-8000-00000000beef"
new["title"], new["order"] = "Inserted stop", 2
for s in ct["stops"]:
    if s["order"] >= 2:
        s["order"] += 1
ct["stops"].append(new)
ct["stops"].sort(key=lambda s: s["order"])
json.dump(c, open(out + "/m_insert.json", "w"))
PY
TID=$(cat "$PGDIR/target.txt")

check_one_change() {   # <fixture> <description>
    local before after moved
    before=$(Q "select max(rev) from public.tours")
    gen "$PGDIR/$1" "$PGDIR/mut.sql"
    [ "$(id -u)" = "0" ] && chown postgres:postgres "$PGDIR/mut.sql"
    if ! $PSQL -f "$PGDIR/mut.sql" >"$PGDIR/mut.out" 2>&1; then
        say_fail "$2: the seed FAILED - $(grep -im1 error "$PGDIR/mut.out")"
        return
    fi
    moved=$(Q "select count(*) from public.tours where rev > $before")
    after=$(Q "select count(*) from public.tours where rev > $before and id = '$TID'")
    if [ "${moved:-0}" = "1" ] && [ "${after:-0}" = "1" ]; then
        echo "  ok $2 - exactly one tour's rev moved, and it is the right one"
    else
        say_fail "$2: $moved tour(s) moved, target moved=$after (want 1 and 1)"
    fi
}

check_one_change m_title.json  "a tour title change is noticed"
check_one_change m_stop.json   "a STOP edit moves its parent tour"
check_one_change m_insert.json "a stop inserted mid-walk renumbers without a unique violation"

n=$(Q "select count(*) from public.stops where tour_id = '$TID'")
[ "${n:-0}" -ge 4 ] || say_fail "the target tour ended with $n stops"

if [ "$fail" != "0" ]; then echo "FAILED"; exit 1; fi
echo "PASS - the seed is idempotent, and still notices every real change."
