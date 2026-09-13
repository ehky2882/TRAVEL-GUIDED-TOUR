#!/usr/bin/env bash
#
# Run backend/account_deletion.sql against a throwaway Postgres and prove what
# it does — before the owner pastes it into production.
#
#   bash backend/test-account-deletion.sh
#
# The fixture models the parts of the live schema the function touches: the
# auth.users cascades, the `restrict` constraints on tours and purchases, and
# Supabase's anon / authenticated / service_role roles with auth.uid() read
# from the request's JWT claim, exactly as PostgREST sets it.
#
# 🔴 What it must prove, in the owner's words (2026-09-13):
#   • only the account holder can trigger it — anon cannot, a session with no
#     user cannot, and one person's call never touches another person's rows;
#   • unsold tours are removed, sold tours stay ("Remove unsold, keep sold");
#   • the creator page is anonymised; purchases survive with the person removed.
#
# Exits 0 = every assertion passed; 1 = a FAILURE; 2 = COULD NOT VERIFY (no
# Postgres). A run that could not execute must never read as a pass.

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "RUN test-account-deletion · rev $(git -C "$HERE" rev-parse --short HEAD 2>/dev/null || echo '?') · $(date -u +%FT%TZ)"

PGBIN=""
for c in "$(command -v initdb 2>/dev/null || true)" /usr/lib/postgresql/*/bin/initdb \
         /opt/homebrew/opt/postgresql@16/bin/initdb; do
    [ -x "$c" ] && { PGBIN="$(dirname "$c")"; break; }
done
if [ -z "$PGBIN" ]; then
    echo "COULD NOT VERIFY - no PostgreSQL found. This is NOT a pass."
    exit 2
fi

PGDIR="$(mktemp -d /tmp/pgdel.XXXXXX)"
AS=""
[ "$(id -u)" = "0" ] && { AS=1; chown postgres:postgres "$PGDIR"; }
run() { if [ -n "$AS" ]; then su postgres -c "$1"; else eval "$1"; fi; }
cleanup() {
    run "$PGBIN/pg_ctl -D $PGDIR/data -m immediate stop" >/dev/null 2>&1 || true
    rm -rf "$PGDIR"
}
trap cleanup EXIT

run "$PGBIN/initdb -D $PGDIR/data -A trust -U postgres" >/dev/null 2>&1
run "$PGBIN/pg_ctl -D $PGDIR/data -l $PGDIR/log -o '-k $PGDIR -c listen_addresses=' -w start" >/dev/null 2>&1
PSQL="$PGBIN/psql -h $PGDIR -U postgres -q -v ON_ERROR_STOP=1"

A=aaaaaaaa-0000-0000-0000-000000000001      # the person deleting
B=bbbbbbbb-0000-0000-0000-000000000002      # someone else
MA=aaaaaaaa-1111-0000-0000-000000000001     # A's creator page
MB=bbbbbbbb-1111-0000-0000-000000000002     # B's creator page
T_UNSOLD=aaaaaaaa-2222-0000-0000-000000000001
T_SOLD=aaaaaaaa-2222-0000-0000-000000000002
T_B=bbbbbbbb-2222-0000-0000-000000000003

cat > "$PGDIR/fixture.sql" <<SQL
create role anon; create role authenticated; create role service_role;
create schema auth;
create table auth.users (id uuid primary key);
create function auth.uid() returns uuid language sql stable as
  \$\$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid \$\$;
grant usage on schema auth to anon, authenticated, service_role;
grant execute on function auth.uid() to anon, authenticated, service_role;
grant usage on schema public to anon, authenticated, service_role;

create table public.makers (
    id uuid primary key, display_name text not null, avatar_url text, avatar_emoji text,
    avatar_initials text, avatar_color text, bio text not null, website_url text,
    link_2_url text, link_3_url text,
    user_id uuid references auth.users (id) on delete set null,
    platform text, handle text,
    updated_at timestamptz not null default now());
create unique index makers_platform_handle_key on public.makers (platform, handle);
create table public.released_handles (
    platform text not null, handle text not null, maker_id uuid,
    released_at timestamptz not null default now(), primary key (platform, handle));
create table public.tours (
    id uuid primary key, title text not null,
    maker_id uuid not null references public.makers (id) on delete restrict);
create table public.stops (
    id uuid primary key, tour_id uuid not null references public.tours (id) on delete cascade);
create table public.purchases (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references auth.users (id) on delete set null,
    tour_id uuid not null references public.tours (id) on delete restrict,
    maker_id uuid not null references public.makers (id) on delete restrict);
create table public.follows (
    follower_id uuid not null references auth.users (id) on delete cascade,
    followee_id uuid not null references public.makers (id) on delete cascade);
create table public.user_saved_makers (
    user_id uuid not null references auth.users (id) on delete cascade,
    maker_id uuid not null references public.makers (id) on delete cascade);
create table public.user_library (
    user_id uuid not null references auth.users (id) on delete cascade,
    tour_id uuid not null references public.tours (id) on delete cascade);
create function public.refresh_catalog_snapshot() returns timestamptz language sql as \$\$ select now() \$\$;
revoke all on function public.refresh_catalog_snapshot() from public, anon, authenticated;

insert into auth.users values ('$A'), ('$B');
insert into public.makers (id, display_name, bio, avatar_url, website_url, user_id, platform, handle) values
  ('$MA', 'Alice Real Name', 'Alice bio', 'https://x/alice.jpg', 'https://alice.example', '$A', 'dozent', 'alice'),
  ('$MB', 'Bob Real Name',   'Bob bio',   null, null, '$B', 'dozent', 'bob');
insert into public.tours values
  ('$T_UNSOLD', 'A unsold', '$MA'), ('$T_SOLD', 'A sold', '$MA'), ('$T_B', 'B tour', '$MB');
insert into public.stops values (gen_random_uuid(), '$T_UNSOLD'), (gen_random_uuid(), '$T_SOLD');
insert into public.purchases (user_id, tour_id, maker_id) values ('$B', '$T_SOLD', '$MA');
insert into public.follows values ('$B', '$MA'), ('$A', '$MB');
insert into public.user_saved_makers values ('$B', '$MA');
insert into public.user_library values ('$A', '$T_B'), ('$B', '$T_UNSOLD');
SQL

[ -n "$AS" ] && chown postgres:postgres "$PGDIR"/*.sql && cp "$HERE/account_deletion.sql" "$PGDIR/" && chown postgres "$PGDIR/account_deletion.sql"
MIG="$HERE/account_deletion.sql"; [ -n "$AS" ] && MIG="$PGDIR/account_deletion.sql"

run "$PSQL -f $PGDIR/fixture.sql" >/dev/null
echo "--- applying account_deletion.sql (receipt below) ---"
run "$PSQL -f $MIG -tA"
echo "--- and again, to prove it is safe to re-run ---"
run "$PSQL -f $MIG -tA" >/dev/null

fail=0
q() { run "$PSQL -tA -c \"$1\"" 2>&1; }
check() {  # name, sql, expected
    local got; got="$(q "$2")"
    if [ "$got" = "$3" ]; then echo "  ok    $1"
    else echo "  FAIL  $1"; echo "        expected: $3"; echo "        got:      $got"; fail=1; fi
}
as() {  # role, sub, sql  -> output (errors included)
    run "$PSQL -tA -c \"set role $1; select set_config('request.jwt.claim.sub', '$2', false); $3\"" 2>&1 | tail -n +2
}

echo "--- who can call it ---"
out="$(as anon '' 'select public.delete_my_account_content();' || true)"
if echo "$out" | grep -q "permission denied"; then echo "  ok    anon is refused"; else echo "  FAIL  anon was not refused: $out"; fail=1; fi
out="$(as authenticated '' 'select public.delete_my_account_content();' || true)"
if echo "$out" | grep -q "sign in required"; then echo "  ok    a session with no user is refused"; else echo "  FAIL  no-user session not refused: $out"; fail=1; fi
check "nothing changed by refused calls" "select count(*) from public.tours" "3"

echo "--- A deletes their own account content ---"
out="$(as authenticated "$A" 'select public.delete_my_account_content();')"
echo "        returned: $out"
check "A's unsold tour is gone"             "select count(*) from public.tours where id = '$T_UNSOLD'" "0"
check "its stops cascaded"                  "select count(*) from public.stops where tour_id = '$T_UNSOLD'" "0"
check "A's SOLD tour stays"                 "select count(*) from public.tours where id = '$T_SOLD'" "1"
check "B's tour untouched"                  "select count(*) from public.tours where id = '$T_B'" "1"
check "A's page anonymised"                 "select display_name || '|' || bio || '|' || coalesce(avatar_url,'∅') || '|' || coalesce(website_url,'∅') from public.makers where id = '$MA'" "Former creator||∅|∅"
check "B's page untouched"                  "select display_name from public.makers where id = '$MB'" "Bob Real Name"
check "followers of A's page removed"       "select count(*) from public.follows where followee_id = '$MA'" "0"
check "A's own follow of B not yet removed" "select count(*) from public.follows where follower_id = '$A'" "1"
check "A's username held for 30 days"     "select handle || '|' || maker_id from public.released_handles" "alice|$MA"
check "saves of A's page removed"           "select count(*) from public.user_saved_makers where maker_id = '$MA'" "0"
if echo "$out" | grep -q "$MA" && echo "$out" | grep -q "\"keptTourIds\": \[\"$T_SOLD\"\]" && echo "$out" | grep -q "$T_UNSOLD" && ! echo "$out" | grep -q "$MB"; then
    echo "  ok    summary lists A's page, A's removed and kept tours, and nothing of B's"
else echo "  FAIL  summary: $out"; fail=1; fi

echo "--- a second call is harmless ---"
as authenticated "$A" 'select public.delete_my_account_content();' >/dev/null
check "sold tour still there" "select count(*) from public.tours where id = '$T_SOLD'" "1"

echo "--- then the login is deleted (the Edge Function's step 4) ---"
q "delete from auth.users where id = '$A'" >/dev/null
check "A's library cascaded"            "select count(*) from public.user_library where user_id = '$A'" "0"
check "A's follows cascaded"            "select count(*) from public.follows where follower_id = '$A'" "0"
check "page survives, detached"         "select coalesce(user_id::text,'null') from public.makers where id = '$MA'" "null"
check "B's purchase survives"           "select count(*) from public.purchases where tour_id = '$T_SOLD' and user_id = '$B'" "1"
out="$(q "delete from public.makers where id = '$MA'" || true)"
if echo "$out" | grep -q "violates foreign key"; then echo "  ok    a page with a sold tour cannot be deleted (buyer keeps access)"; else echo "  FAIL  page deletion was not restricted: $out"; fail=1; fi

echo
if [ "$fail" = 0 ]; then echo "PASS — account_deletion.sql behaves as specified"; exit 0
else echo "FAILURE — see above"; exit 1; fi
