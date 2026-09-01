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
    price_tier int, is_private boolean
);
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
insert into public.tours values
  ('11111111-1111-1111-1111-111111111111', 'Test tour', null, 'single', 299, false),
  -- A link pin, so split_link_pins.sql has something to lift out of `tours`.
  ('22222222-2222-2222-2222-222222222222', 'Test pin', null, 'link', null, false);

-- The social layer private_friends_social.sql rewrites. Supabase supplies
-- auth.uid() from the request's JWT; the stub below reads the same GUC GoTrue
-- sets, so a test can switch identity with `set request.jwt.claim.sub`.
create schema if not exists auth;
create or replace function auth.uid() returns uuid language sql stable as $fn$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid;
$fn$;
create table public.makers (
    id uuid primary key, user_id uuid, display_name text,
    is_private boolean not null default false
);
create table public.follows (
    follower_id uuid, followee_id uuid, status text,
    created_at timestamptz not null default now(),
    primary key (follower_id, followee_id)
);
create or replace function public.owns_maker(m uuid)
returns boolean language sql stable security definer set search_path = public as $fn$
    select exists (select 1 from public.makers where id = m and user_id = auth.uid());
$fn$;
-- A private account (P), the friend it accepted (F), and a stranger (S).
insert into public.makers (id, user_id, display_name, is_private) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'aaaaaaaa-1111-0000-0000-000000000001', 'Private P', true),
  ('bbbbbbbb-0000-0000-0000-000000000002', 'bbbbbbbb-1111-0000-0000-000000000002', 'Friend F',  false),
  ('cccccccc-0000-0000-0000-000000000003', 'cccccccc-1111-0000-0000-000000000003', 'Stranger S', false);
insert into public.follows (follower_id, followee_id, status) values
  ('bbbbbbbb-1111-0000-0000-000000000002', 'aaaaaaaa-0000-0000-0000-000000000001', 'accepted');
SQL
[ -n "$AS" ] && chown postgres:postgres "$PGDIR"/*.sql
run "$PSQL -f $PGDIR/base.sql" >/dev/null

# Order matters: add_link_pins anchors on the key add_video_role inserts.
MIGRATIONS=(add_video_role.sql add_link_pins.sql split_link_pins.sql private_friends_social.sql)
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

# 🔴 The reported bug: a private account had accepted a follower, and both its
# follower lists still came back empty for that friend. Assert all three
# viewers, because a gate that is merely OPEN is as wrong as one stuck shut -
# the stranger case is what proves the fix did not just delete the rule.
#   P = private maker, F = the follower it accepted, S = a stranger.
sees() {  # sees <auth-uid> -> "<can_see_social>/<rows from list_followers>"
    # -q so psql's "SET" command tag doesn't land in front of the answer.
    run "$PGBIN/psql -h $PGDIR -U postgres -qtAc \
      \"set request.jwt.claim.sub = '$1';
        select public.can_see_social('aaaaaaaa-0000-0000-0000-000000000001')::text
               || '/' ||
               (select count(*) from public.list_followers(
                    'aaaaaaaa-0000-0000-0000-000000000001'));\"" 2>/dev/null \
      | tr -d '[:space:]'
}
friend=$(sees 'bbbbbbbb-1111-0000-0000-000000000002')
owner=$(sees 'aaaaaaaa-1111-0000-0000-000000000001')
stranger=$(sees 'cccccccc-1111-0000-0000-000000000003')
[ "$friend" = "true/1" ] || { echo "  x accepted FOLLOWER still refused a private account's followers (got '${friend:-nothing}', want true/1)"; fail=1; }
[ "$owner" = "true/1" ]  || { echo "  x OWNER lost access to their own followers (got '${owner:-nothing}', want true/1)"; fail=1; }
[ "$stranger" = "false/0" ] || { echo "  x STRANGER can now read a private account's followers (got '${stranger:-nothing}', want false/0)"; fail=1; }

if [ "$fail" = "0" ]; then
    echo "MIGRATIONS OK - ${#MIGRATIONS[@]} applied, idempotent, all catalog keys and places intact,"
    echo "               private social graph visible to owner + accepted followers only"
else
    echo "MIGRATIONS FAILED"
fi
exit $fail
