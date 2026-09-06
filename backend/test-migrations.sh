#!/usr/bin/env bash
#
# Compile-and-run every catalog migration against a throwaway Postgres.
#
# WHY THIS EXISTS
# ---------------
# Three migrations have now reached the owner's SQL Editor with errors that a
# single local run would have caught in seconds — most recently
# `too many parameters specified for RAISE`, which is a COMPILE error, so the
# guarded branch it lived in never had to execute for it to fail.
#
# These files are pasted by hand into a live production database. That is the
# worst possible place to discover a syntax error, and the owner is
# non-technical about SQL. Run this before handing one over.
#
#   bash backend/test-migrations.sh
#
# It creates a cluster in a temp dir, throws it away afterwards, and touches
# nothing else. Needs `initdb`/`pg_ctl` on PATH or in the usual Debian spot.

set -euo pipefail

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

# Short path: the Unix socket name is capped at ~107 bytes, and a scratchpad
# path blows that on its own.
PGDIR="$(mktemp -d /tmp/pgmig.XXXXXX)"
AS=""
[ "$(id -u)" = "0" ] && { AS="su postgres -c"; chown postgres:postgres "$PGDIR"; }
run() { if [ -n "$AS" ]; then su postgres -c "$1"; else eval "$1"; fi; }
cleanup() {
    run "$PGBIN/pg_ctl -D $PGDIR/data -m immediate stop" >/dev/null 2>&1 || true
    rm -rf "$PGDIR"
}
trap cleanup EXIT

run "$PGBIN/initdb -D $PGDIR/data -A trust -U postgres" >/dev/null 2>&1
run "$PGBIN/pg_ctl -D $PGDIR/data -l $PGDIR/log -o '-k $PGDIR -c listen_addresses=' -w start" >/dev/null 2>&1
PSQL="$PGBIN/psql -h $PGDIR -U postgres -q -v ON_ERROR_STOP=1"

# The starting shape: get_catalog() composed over get_catalog_core(), which is
# what the live database actually looks like and what every migration must
# leave intact. Deliberately WITHOUT the keys the migrations add.
cat > "$PGDIR/base.sql" <<'SQL'
-- Supabase ships these two roles; a migration that grants execute on a catalog
-- function needs them to exist or it fails for a reason that has nothing to do
-- with the migration.
create role anon;
create role authenticated;
create table public.tours (
    id uuid primary key, title text, video_urls text[], kind text,
    price_tier int, is_private boolean,
    -- Supabase filters the catalog to published rows two ways: an explicit
    -- `where t.status = 'published'` in the builder AND this RLS policy. The
    -- fixture models the RLS half, because `catalog_snapshot.sql` builds the
    -- payload once AS `anon` and the whole security argument rests on that
    -- evaluating exactly as it does for a real anonymous reader.
    status text not null default 'published'
);
alter table public.tours enable row level security;
create policy tours_public_read on public.tours
    for select using (status = 'published');
-- Supabase grants anon table access and lets RLS do the filtering. Without
-- this the catalog RPC would fail for anon in production too, so the fixture
-- was previously modelling a database that could not have worked.
grant usage on schema public to anon, authenticated;
grant select on public.tours to anon, authenticated;
create or replace function public.get_catalog_core()
returns jsonb language sql stable as $fn$
  select jsonb_build_object(
    'makers', jsonb_build_array(jsonb_build_object('id', 'maker-1', 'isPrivate', false)),
    'tours', (
    select coalesce(jsonb_agg(jsonb_build_object(
      'id',                   t.id,
      'title',                t.title,
      'videoURLs',            to_jsonb(t.video_urls),
      'kind',                 t.kind::text,
      'priceTier',            t.price_tier,
      'isPrivate',            t.is_private
    )), '[]'::jsonb) from public.tours t));
$fn$;
create or replace function public.get_catalog()
returns jsonb language sql stable as $fn$
  select public.get_catalog_core() || jsonb_build_object('places',
    jsonb_build_array(jsonb_build_object('id', 'place-1')));
$fn$;
insert into public.tours (id, title, video_urls, kind, price_tier, is_private, status) values
  ('11111111-1111-1111-1111-111111111111', 'Test tour', null, 'single', 299, false, 'published'),
  -- A link pin, so split_link_pins.sql has something to lift out of `tours`.
  ('22222222-2222-2222-2222-222222222222', 'Test pin', null, 'link', null, false, 'published'),
  -- 🔴 An UNPUBLISHED tour. Materialising the catalog means one role builds it
  -- and everyone is served the result, so the role it is built as decides what
  -- the whole world can see. This row must never reach the snapshot.
  ('33333333-3333-3333-3333-333333333333', 'SECRET DRAFT', null, 'single', null, false, 'draft');
SQL
[ -n "$AS" ] && chown postgres:postgres "$PGDIR"/*.sql
run "$PSQL -f $PGDIR/base.sql" >/dev/null

# Order matters: add_link_pins anchors on the key add_video_role inserts, and
# catalog_snapshot must be LAST — it renames whatever get_catalog() is at the
# time aside as the builder, so anything that still patches the chain has to
# have run first.
MIGRATIONS=(add_video_role.sql add_link_pins.sql split_link_pins.sql catalog_snapshot.sql)
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

fail=0
for m in "${MIGRATIONS[@]}"; do
    cp "$HERE/$m" "$PGDIR/$m"
    [ -n "$AS" ] && chown postgres:postgres "$PGDIR/$m"
    # 🔴 Gate on the EXIT CODE, never on grepping the output. psql prefixes
    # errors with "psql:<file>:<line>: ERROR:", so an anchored ^ERROR match
    # silently passes a migration that failed — which this script did, and
    # which is the same false-pass class the check exists to prevent.
    # ON_ERROR_STOP=1 is what makes the exit code trustworthy.
    if out=$(run "$PSQL -f $PGDIR/$m" 2>&1); then
        echo "  ok $m"
    else
        echo "  x $m FAILED"
        printf '%s\n' "$out" | grep -i "error\|context" | head -3 | sed 's/^/      /'
        fail=1
        continue   # a second run would only report the same thing
    fi
    # Re-run: every one of these advertises itself as idempotent.
    if ! out=$(run "$PSQL -f $PGDIR/$m" 2>&1); then
        echo "  x $m is NOT idempotent - it fails on a second run"
        printf '%s\n' "$out" | grep -i "error" | head -2 | sed 's/^/      /'
        fail=1
    fi
done

# 🔴 The check that matters most. A migration that replaces get_catalog()
# instead of patching get_catalog_core() severs the composition and silently
# drops every place, price and private account - with no error at all. So
# assert the KEYS, not the exit code.
# Only meaningful if the migrations actually applied — otherwise this reports
# a missing column, which is a consequence of the real failure above, not a
# second finding.
if [ "$fail" != "0" ]; then
    echo "MIGRATIONS FAILED"
    exit 1
fi

run "$PSQL -c \"update public.tours set video_role='narration',
      source_url='https://x/y', source_author='@a';\"" >/dev/null

# 🔴 THE SNAPSHOT IS A SNAPSHOT — prove it in both directions.
# The update above is now invisible until the catalog is rebuilt. That is the
# whole point of the change, and it is also its one new failure mode: a seed
# that upserts rows and forgets to refresh leaves every phone on stale content
# with nothing erroring. Assert stale-before and fresh-after, so neither half
# can rot silently.
stale=$(run "$PGBIN/psql -h $PGDIR -U postgres -tAc \
  \"select coalesce(get_catalog()->'tours'->0->>'videoRole', '<null>');\"" 2>/dev/null | tr -d '[:space:]')
[ "$stale" = "<null>" ] || {
    echo "  x get_catalog() is NOT a snapshot - it saw an unrefreshed write (videoRole='$stale')"; fail=1; }

run "$PSQL -c \"select public.refresh_catalog_snapshot();\"" >/dev/null
fresh=$(run "$PGBIN/psql -h $PGDIR -U postgres -tAc \
  \"select coalesce(get_catalog()->'tours'->0->>'videoRole', '<null>');\"" 2>/dev/null | tr -d '[:space:]')
[ "$fresh" = "narration" ] || {
    echo "  x refresh_catalog_snapshot() did not take effect (videoRole='$fresh', want 'narration')"; fail=1; }

# Exactly one row, ever. The single-row idiom is a primary key plus a check
# constraint, so a second row must be impossible rather than merely unusual.
rows=$(run "$PGBIN/psql -h $PGDIR -U postgres -tAc \
  \"select count(*) from public.catalog_snapshot;\"" 2>/dev/null | tr -d '[:space:]')
[ "$rows" = "1" ] || { echo "  x catalog_snapshot holds '$rows' rows, want exactly 1"; fail=1; }
if run "$PSQL -c \"insert into public.catalog_snapshot (id, payload) values (false, '{}'::jsonb);\"" >/dev/null 2>&1; then
    echo "  x a SECOND catalog_snapshot row was accepted - the single-row constraint is not doing its job"; fail=1
fi

# 🔴 The security shape. Materialising means one role builds the payload and
# everyone is served it, so who can reach it matters more than before:
# the table must be unreachable directly, and the function must still work.
if run "$PGBIN/psql -h $PGDIR -U postgres -tAc \
  \"set local role anon; select payload from public.catalog_snapshot;\"" >/dev/null 2>&1; then
    echo "  x anon can read catalog_snapshot DIRECTLY - it should only be reachable via get_catalog()"; fail=1
fi
# `set local role` prints its own SET tag first, so read the LAST line.
anon_ok=$(run "$PGBIN/psql -h $PGDIR -U postgres -tAc \
  \"set local role anon; select jsonb_array_length(get_catalog()->'tours');\"" 2>/dev/null | tail -1 | tr -d '[:space:]')
[ "$anon_ok" = "1" ] || { echo "  x anon cannot call get_catalog() (got '${anon_ok:-nothing}')"; fail=1; }

# The builder must survive under its new name, or a future migration that
# patches get_catalog_core() would be patching something nothing calls.
# Read it AS anon, which is how refresh_catalog_snapshot() calls it.
built=$(run "$PGBIN/psql -h $PGDIR -U postgres -tAc \
  \"set local role anon; select jsonb_array_length(public.get_catalog_built()->'tours');\"" 2>/dev/null | tail -1 | tr -d '[:space:]')
[ "$built" = "1" ] || { echo "  x get_catalog_built() is gone or broken (got '${built:-nothing}')"; fail=1; }

# 🔴 THE ONE THAT WOULD MATTER MOST IF IT REGRESSED.
# The snapshot is built once and served to everybody, so a builder run as too
# privileged a role publishes unpublished work to the world — with no error
# anywhere, because a bigger catalog looks exactly like a healthy one. Assert
# the draft is absent from what get_catalog() actually serves.
leaked=$(run "$PGBIN/psql -h $PGDIR -U postgres -tAc \
  \"select count(*) from jsonb_array_elements(get_catalog()->'tours') t
     where t->>'title' = 'SECRET DRAFT';\"" 2>/dev/null | tr -d '[:space:]')
[ "$leaked" = "0" ] || {
    echo "  x UNPUBLISHED CONTENT LEAKED into the snapshot ($leaked row(s)) - the builder ran too privileged"; fail=1; }

# ...and the negative control: prove that assertion could fail. Built as the
# table OWNER, RLS does not apply and the draft DOES come through — so the
# check above is testing the role, not just passing for free.
owner_sees=$(run "$PGBIN/psql -h $PGDIR -U postgres -tAc \
  \"select count(*) from jsonb_array_elements(public.get_catalog_built()->'tours') t
     where t->>'title' = 'SECRET DRAFT';\"" 2>/dev/null | tr -d '[:space:]')
[ "$owner_sees" = "1" ] || {
    echo "  x negative control failed: the owner-built catalog does not contain the draft either (got '${owner_sees:-nothing}'), so the leak test proves nothing"; fail=1; }

missing=$(run "$PGBIN/psql -h $PGDIR -U postgres -tAc \"
  select string_agg(k, ', ') from (
    select k from unnest(array['id','title','videoURLs','videoRole','kind',
                               'priceTier','isPrivate','sourceURL','sourceAuthor']) k
    where not (get_catalog()->'tours'->0) ? k
  ) m;\"" 2>/dev/null | tr -d '[:space:]')
[ -n "$missing" ] && { echo "  x tour keys MISSING after migration: $missing"; fail=1; }

places=$(run "$PGBIN/psql -h $PGDIR -U postgres -tAc \
  \"select jsonb_array_length(coalesce(get_catalog()->'places','[]'::jsonb));\"" 2>/dev/null | tr -d '[:space:]')
[ "$places" = "1" ] || { echo "  x places layer LOST (got '${places:-nothing}') - the composition was severed"; fail=1; }

# 🔴 The split itself. A link pin left inside `tours` is the original bug: one
# unknown `kind` fails the WHOLE catalog decode on every build predating
# TourKind.link, silently. Assert both halves - that the pin left `tours`, and
# that it actually arrived in `linkPins` rather than being dropped on the floor.
split=$(run "$PGBIN/psql -h $PGDIR -U postgres -tAc \
  \"select jsonb_array_length(get_catalog()->'tours') || '/' ||
            jsonb_array_length(coalesce(get_catalog()->'linkPins','[]'::jsonb)) || '/' ||
            (select count(*) from jsonb_array_elements(get_catalog()->'tours') t
              where t->>'kind' = 'link');\"" 2>/dev/null | tr -d '[:space:]')
[ "$split" = "1/1/0" ] || { echo "  x link pins NOT split correctly (tours/linkPins/strays = '${split:-nothing}', want 1/1/0)"; fail=1; }

if [ "$fail" = "0" ]; then
    echo "MIGRATIONS OK - ${#MIGRATIONS[@]} applied, idempotent, all catalog keys and places intact"
else
    echo "MIGRATIONS FAILED"
fi
exit $fail
