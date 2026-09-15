#!/usr/bin/env bash
#
# Prove `get_catalog_since(rev)` returns exactly what changed, and returns it
# byte-identical to what `get_catalog()` would have sent.
#
# WHY THIS EXISTS
# ---------------
# docs/delta-catalog-fetch-design.md § Phase 1 names one hard constraint: there
# must be ONE shaper, not two. A hand-written delta shaper would drift from the
# real builder and the drift would be invisible -- new builds quietly receiving
# a different tour shape from old ones, which is the 2026-08-19 incident
# (`places`, `priceTier`, `isPrivate` gone for 14 hours) restricted to whichever
# rows changed that day.
#
# catalog_since.sql answers that by filtering the snapshot rather than shaping
# anything. This test is what proves the answer: it asserts every delta element
# is byte-for-byte the element `get_catalog()` carries for the same id.
#
# 🔴 THE FIXTURE IS SYNTHETIC ON PURPOSE, and so is test-migrations.sh's.
# backend/README.md: "no file in this directory matches what is running -- the
# live definition is the accumulation of migrations that each rebuilt the
# function from whatever their author had; running them in any order does not
# reproduce it." split_link_pins.sql proves it by refusing to apply to a chain
# rebuilt from source. So the snapshot here is built by a stand-in with the
# right SHAPE -- four arrays of objects carrying `id` -- which is the whole of
# what get_catalog_since depends on. It never reads a tour's other keys.
#
#   bash backend/test-catalog-since.sh
#
# Exit 0 = pass · 1 = wrong answer · 2 = COULD NOT VERIFY (not a pass).
set -euo pipefail
echo "RUN test-catalog-since.sh · rev $(git rev-parse --short HEAD 2>/dev/null || echo '?') · $(date -u +%Y-%m-%dT%H:%M:%SZ)"

PGBIN=""
for c in "$(command -v initdb 2>/dev/null || true)" /usr/lib/postgresql/*/bin/initdb \
         /opt/homebrew/opt/postgresql@16/bin/initdb; do
    [ -x "$c" ] && { PGBIN="$(dirname "$c")"; break; }
done
[ -z "$PGBIN" ] && { echo "COULD NOT VERIFY - no PostgreSQL found. This is NOT a pass."; exit 2; }

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CATALOG="$REPO/TRAVEL GUIDED TOUR/Resources/Tours.json"
PGDIR="$(mktemp -d /tmp/pgsince.XXXXXX)"
AS=""; [ "$(id -u)" = "0" ] && { AS=yes; chown postgres:postgres "$PGDIR"; }
run(){ if [ -n "$AS" ]; then su postgres -c "$1"; else eval "$1"; fi; }
trap 'run "$PGBIN/pg_ctl -D $PGDIR/data -m immediate stop" >/dev/null 2>&1 || true; rm -rf "$PGDIR"' EXIT
run "$PGBIN/initdb -D $PGDIR/data -A trust -U postgres" >/dev/null 2>&1
run "$PGBIN/pg_ctl -D $PGDIR/data -l $PGDIR/log -o '-k $PGDIR -c listen_addresses=' -w start" >/dev/null 2>&1
PSQL="$PGBIN/psql -h $PGDIR -U postgres -q -v ON_ERROR_STOP=1"; Q="$PGBIN/psql -h $PGDIR -U postgres -tAc"

cat > "$PGDIR/pre.sql" <<'SQL'
create role anon; create role authenticated; create schema if not exists auth;
create table auth.users (id uuid primary key, email text, raw_user_meta_data jsonb);
create function auth.uid() returns uuid language sql stable as $f$ select null::uuid $f$;
SQL
# The snapshot stand-in: four arrays of objects carrying `id`, which is the
# whole contract get_catalog_since depends on. Extra keys are carried so the
# byte-identity assertion has something to be wrong about.
cat > "$PGDIR/snap.sql" <<'SQL'
create table public.catalog_snapshot (id boolean primary key default true,
    payload jsonb, refreshed_at timestamptz not null default now());
create or replace function public.refresh_catalog_snapshot() returns void language plpgsql as $fn$
begin
  insert into public.catalog_snapshot (id, payload, refreshed_at) values (true, jsonb_build_object(
    'tours',   (select coalesce(jsonb_agg(jsonb_build_object('id',t.id,'title',t.title,
                  'city',t.city,'country',t.country,'tags',to_jsonb(t.tags),
                  'stops',(select coalesce(jsonb_agg(jsonb_build_object('id',s.id,'title',s.title,
                            'order',s."order") order by s."order"),'[]') from public.stops s where s.tour_id=t.id))
                  order by t.title),'[]') from public.tours t
                 where t.status='published' and t.kind is distinct from 'link'),
    'linkPins',(select coalesce(jsonb_agg(jsonb_build_object('id',t.id,'title',t.title,
                  'sourceURL',t.source_url) order by t.title),'[]') from public.tours t
                 where t.status='published' and t.kind='link'),
    'makers',  (select coalesce(jsonb_agg(jsonb_build_object('id',m.id,'displayName',m.display_name)),'[]')
                  from public.makers m),
    'places',  (select coalesce(jsonb_agg(jsonb_build_object('id',p.id,'name',p.name)),'[]')
                  from public.places p)),
    clock_timestamp())
  on conflict (id) do update set payload = excluded.payload, refreshed_at = excluded.refreshed_at;
end $fn$;
create or replace function public.get_catalog() returns jsonb language sql stable
as $fn$ select payload from public.catalog_snapshot where id $fn$;
SQL

BASE="schema.sql add_video_urls.sql add_video_role.sql add_link_pin_kind.sql
      add_link_pins.sql add_country.sql places.sql add_catalog_rev.sql"
for f in $BASE catalog_since.sql; do cp "$REPO/backend/$f" "$PGDIR/"; done
python3 "$REPO/backend/seed_from_toursjson.py" --input "$CATALOG" -o "$PGDIR/seed.sql" 2>/dev/null
python3 - "$CATALOG" "$PGDIR/mut.json" > "$PGDIR/mutids.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
multi = [t for t in d["tours"] if len(t["stops"]) >= 4]
multi[0]["title"] = "MUTATED TOUR TITLE"                     # a tour row changes
multi[1]["stops"][0]["title"] = "MUTATED STOP"               # only a STOP changes
d["makers"][0]["bio"] = "MUTATED BIO"                        # a maker changes
json.dump(d, open(sys.argv[2], "w"), indent=2, ensure_ascii=False)
print(json.dumps({"tour": multi[0]["id"], "stoponly": multi[1]["id"],
                  "maker": d["makers"][0]["id"]}))
PY
python3 "$REPO/backend/seed_from_toursjson.py" --input "$PGDIR/mut.json" -o "$PGDIR/seed2.sql" 2>/dev/null
[ -n "$AS" ] && chown postgres:postgres "$PGDIR"/*.sql "$PGDIR"/*.json
run "$PSQL -f $PGDIR/pre.sql" >/dev/null
for f in $BASE; do run "$PSQL -f $PGDIR/$f" >/dev/null 2>&1 || { echo "FAIL applying $f"; exit 1; }; done
run "$PSQL -c 'alter table public.makers add column if not exists platform text'" >/dev/null
run "$PSQL -c 'alter table public.makers add column if not exists handle text'" >/dev/null
run "$PSQL -f $PGDIR/snap.sql" >/dev/null
run "$PSQL -f $PGDIR/catalog_since.sql" >/dev/null
echo "  schema + catalog_since.sql applied"
run "$PSQL -f $PGDIR/seed.sql" >/dev/null
run "$PSQL -c 'select public.refresh_catalog_snapshot()'" >/dev/null

fail=0
say(){ printf '  %-42s %s\n' "$1" "$2"; }
HEAD=$(run "$Q \"select (public.get_catalog_since(0)->>'rev')::bigint\"")

FULL=$(run "$Q \"select length(public.get_catalog()::text)\"")
D0=$(run "$Q \"select length(public.get_catalog_since(0)::text)\"")
DH=$(run "$Q \"select length(public.get_catalog_since($HEAD)::text)\"")
say "full catalog bytes" "$FULL"
say "since(0) bytes (everything)" "$D0"
say "since(head) bytes (nothing changed)" "$DH"
[ "$DH" -lt 200 ] || { echo "FAIL - an up-to-date client is sent $DH bytes; it should be a near-empty envelope."; fail=1; }

n=$(run "$Q \"select jsonb_array_length(public.get_catalog_since($HEAD)->'tours')\"")
[ "$n" = 0 ] || { echo "FAIL - $n tours returned when nothing changed."; fail=1; }
n=$(run "$Q \"select jsonb_array_length(public.get_catalog_since(0)->'tours')\"")
m=$(run "$Q \"select jsonb_array_length(public.get_catalog()->'tours')\"")
[ "$n" = "$m" ] || { echo "FAIL - since(0) returned $n tours, the full catalog has $m."; fail=1; }
say "since(0) returns the whole catalog" "$n = $m tours"

echo "  --- mutate: one tour, one STOP only, one maker ---"
run "$PSQL -f $PGDIR/seed2.sql" >/dev/null
T=$(run "$Q \"select jsonb_array_length(public.get_catalog_since($HEAD)->'tours')\"")
MK=$(run "$Q \"select jsonb_array_length(public.get_catalog_since($HEAD)->'makers')\"")
DH2=$(run "$Q \"select length(public.get_catalog_since($HEAD)::text)\"")
say "tours in delta (want 2)" "$T"
say "makers in delta (want 1)" "$MK"
say "delta bytes vs full" "$DH2 vs $FULL"
[ "$T" = 2 ]  || { echo "FAIL - expected 2 changed tours (one edited, one whose STOP changed), got $T."; fail=1; }
[ "$MK" = 1 ] || { echo "FAIL - expected 1 changed maker, got $MK."; fail=1; }

# 🔴 The anti-drift assertion. Every delta element must be the SAME JSONB as the
# one get_catalog() carries for that id -- not merely similar.
drift=0
for sec in tours linkPins makers places; do
  bad=$(run "$Q \"
    with d as (select public.get_catalog_since($HEAD) x), f as (select public.get_catalog() y)
    select count(*) from jsonb_array_elements((select x from d)->'$sec') e
     where e is distinct from (select j from jsonb_array_elements((select y from f)->'$sec') j
                                where j->>'id' = e->>'id');\"")
  [ "$bad" = 0 ] || { echo "FAIL - $bad '$sec' rows differ from what get_catalog() sends for the same id."; fail=1; drift=1; }
done
# Only claim this when it is true. A verdict line printed regardless of the
# result is how a broken check reads as a passing one.
[ "$drift" = 0 ] && say "every delta row byte-identical to full" "yes (all 4 sections)"

[ "$fail" = 0 ] || exit 1
echo "SINCE OK - delta returns exactly what changed, identical to the full catalog's bytes."
