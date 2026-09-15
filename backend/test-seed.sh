#!/usr/bin/env bash
#
# Prove Phase 0: a re-seed of UNCHANGED content must write nothing.
#
# WHY THIS EXISTS
# ---------------
# `seed_from_toursjson.py` used to write `updated_at = now()` on every row it
# touched, so the column recorded when the SEED last ran rather than when a row
# last changed. Every changed-since cursor therefore returns the whole
# catalogue, which is why `docs/delta-catalog-fetch-design.md` calls the
# conditional upserts load-bearing (§ 6, Phase 0).
#
# That fix is invisible. Nothing fails, nothing looks different, and the only
# way to know it still works is to seed twice and count what moved. A
# regression here would be silent and would quietly disable delta fetching for
# whoever builds it next — so this runs the real generator against the real
# schema, twice, and reads `pg_stat_user_tables`.
#
# 🔴 COMPARING VALUES IS NOT ENOUGH. The old place-membership code cleared
# `place_id` to null and set it straight back, so the final value was identical
# either way while the row was written twice. `n_tup_upd` counts actual row
# versions and is the only honest measure here.
#
#   bash backend/test-seed.sh
#
# Creates a throwaway cluster in a temp dir and removes it afterwards.
# Needs `initdb`/`pg_ctl`:  Debian: apt-get install -y postgresql
#                           macOS:  brew install postgresql@16
#
# Exit 0 = pass · 1 = rewrites detected · 2 = COULD NOT VERIFY (not a pass).
set -euo pipefail

echo "RUN test-seed.sh · rev $(git rev-parse --short HEAD 2>/dev/null || echo '?') · $(date -u +%Y-%m-%dT%H:%M:%SZ)"

PGBIN=""
for c in "$(command -v initdb 2>/dev/null || true)" /usr/lib/postgresql/*/bin/initdb \
         /opt/homebrew/opt/postgresql@16/bin/initdb; do
    [ -x "$c" ] && { PGBIN="$(dirname "$c")"; break; }
done
if [ -z "$PGBIN" ]; then
    echo "COULD NOT VERIFY - no PostgreSQL found. This is NOT a pass."
    echo "  macOS:  brew install postgresql@16"
    echo "  Debian: apt-get install -y postgresql"
    exit 2
fi

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CATALOG="$REPO/TRAVEL GUIDED TOUR/Resources/Tours.json"
# SEED_GEN lets the control case run an older generator, which is how this test
# was itself verified: at 9d63cb8~1 it reports tours upd=5215, makers 424,
# places 303. A test that cannot fail is not a test.
GEN="${SEED_GEN:-$REPO/backend/seed_from_toursjson.py}"

# The socket path is capped near 107 bytes; a scratchpad path blows that alone.
PGDIR="$(mktemp -d /tmp/pgseed.XXXXXX)"
AS=""
[ "$(id -u)" = "0" ] && { AS="yes"; chown postgres:postgres "$PGDIR"; }
run() { if [ -n "$AS" ]; then su postgres -c "$1"; else eval "$1"; fi; }
cleanup() {
    run "$PGBIN/pg_ctl -D $PGDIR/data -m immediate stop" >/dev/null 2>&1 || true
    rm -rf "$PGDIR"
}
trap cleanup EXIT

run "$PGBIN/initdb -D $PGDIR/data -A trust -U postgres" >/dev/null 2>&1
run "$PGBIN/pg_ctl -D $PGDIR/data -l $PGDIR/log -o '-k $PGDIR -c listen_addresses=' -w start" >/dev/null 2>&1
PSQL="$PGBIN/psql -h $PGDIR -U postgres -q -v ON_ERROR_STOP=1"
Q="$PGBIN/psql -h $PGDIR -U postgres -tAc"

# Supabase ships these; schema.sql references them and would fail for a reason
# that has nothing to do with the seed.
cat > "$PGDIR/pre.sql" <<'SQL'
create role anon;
create role authenticated;
create schema if not exists auth;
create table auth.users (id uuid primary key, email text, raw_user_meta_data jsonb);
create function auth.uid() returns uuid language sql stable as $f$ select null::uuid $f$;
create function auth.role() returns text language sql stable as $f$ select 'anon'::text $f$;
SQL

SCHEMA=(schema.sql add_video_urls.sql add_video_role.sql add_link_pin_kind.sql
        add_link_pins.sql add_country.sql places.sql)
for f in "${SCHEMA[@]}"; do cp "$REPO/backend/$f" "$PGDIR/$f"; done

python3 "$GEN" --input "$CATALOG" -o "$PGDIR/seed.sql" 2>/dev/null
echo "  generator: $GEN"
echo "  seed.sql:  $(wc -c < "$PGDIR/seed.sql") bytes"
[ -n "$AS" ] && chown postgres:postgres "$PGDIR"/*.sql

run "$PSQL -f $PGDIR/pre.sql" >/dev/null
for f in "${SCHEMA[@]}"; do
    if run "$PSQL -f $PGDIR/$f" >/dev/null 2>"$PGDIR/e"; then echo "  ok   $f"
    else echo "  FAIL $f"; tail -4 "$PGDIR/e"; exit 1; fi
done

# usernames.sql adds these two, but it also patches the catalog builder and
# needs the split_link_pins / catalog_snapshot chain ahead of it. This test is
# about the seed, not migration order — backend/test-migrations.sh covers that.
run "$PSQL -c 'alter table public.makers add column if not exists platform text'" >/dev/null
run "$PSQL -c 'alter table public.makers add column if not exists handle text'" >/dev/null

echo "  --- seed run 1 (populate) ---"
run "$PSQL -f $PGDIR/seed.sql" >/dev/null
run "$PSQL -c 'select pg_stat_reset()'" >/dev/null
echo "  --- seed run 2 (byte-identical input; must write nothing) ---"
run "$PSQL -f $PGDIR/seed.sql" >/dev/null

echo
printf '%-8s %8s %8s %8s\n' table upd ins del
fail=0
for t in tours makers places stops; do
    read -r u i d <<<"$(run "$Q \"select coalesce(n_tup_upd,0), coalesce(n_tup_ins,0), coalesce(n_tup_del,0) from pg_stat_user_tables where relname='$t'\"" | tr '|' ' ')"
    printf '%-8s %8s %8s %8s\n' "$t" "$u" "$i" "$d"
    # stops is the KNOWN remaining cost: the seed still deletes and re-inserts
    # every stop of every tour. That is the next Phase 0 item and it needs a
    # migration (stops has no updated_at) plus an answer to the
    # unique (tour_id, "order") constraint, which delete-first makes safe.
    [ "$t" = stops ] && continue
    [ "$u" != 0 ] || [ "$i" != 0 ] || [ "$d" != 0 ] && { fail=1; }
done

rows=$(run "$Q \"select count(*) from public.tours\"")
stops=$(run "$Q \"select count(*) from public.stops\"")
placed=$(run "$Q \"select count(*) from public.tours where place_id is not null\"")
echo
echo "  catalogue intact: $rows tours · $stops stops · $placed tours in a place"
[ "$rows" = 0 ] && { echo "COULD NOT VERIFY - the seed loaded nothing."; exit 2; }

if [ "$fail" = 0 ]; then
    echo "SEED OK - an unchanged re-seed rewrote no tour, maker or place row."
    echo "  (stops still rewrites every row; that is the next Phase 0 item.)"
else
    echo "FAIL - an unchanged re-seed rewrote rows. The conditional upserts in"
    echo "  backend/seed_from_toursjson.py are not doing their job; updated_at"
    echo "  no longer means 'this row changed'. See docs/delta-catalog-fetch-design.md § 6."
    exit 1
fi
