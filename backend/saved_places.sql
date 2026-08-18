-- Saved places, synced across a signed-in user's devices.
--
-- WHAT THIS DOES
--   Creates one table so that bookmarking a place on your phone shows up on
--   your iPad, the same way saved tours and recently-played already do.
--
-- WHAT IT DOES NOT DO
--   Nothing existing is changed. No tour, place, maker or library row is
--   touched. Saving a place already works without this — it just stays on the
--   one device until you run it.
--
-- SAFE TO RUN TWICE. Every statement is guarded.
--
-- HOW TO RUN IT
--   Supabase dashboard -> SQL Editor -> New query -> paste all of this -> Run.
--   Expect: "Success. No rows returned."

create table if not exists public.user_saved_places (
    user_id  uuid not null references auth.users (id) on delete cascade,
    place_id uuid not null references public.places (id) on delete cascade,
    saved_at timestamptz not null default now(),
    primary key (user_id, place_id)
);

-- Each user reads and writes only their own rows. Identical rule to
-- user_library and user_recently_viewed.
alter table public.user_saved_places enable row level security;

drop policy if exists user_saved_places_own on public.user_saved_places;
create policy user_saved_places_own on public.user_saved_places
    for all using (user_id = auth.uid()) with check (user_id = auth.uid());

grant select, insert, update, delete on public.user_saved_places to authenticated;

-- Check it worked — run this on its own afterwards, expect an empty result
-- rather than an error:
--   select * from public.user_saved_places;
