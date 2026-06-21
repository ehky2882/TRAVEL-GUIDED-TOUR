-- Atlas backend — media storage for maker uploads (V2 Step 4)
--
-- Run AFTER backend/accounts.sql (needs the owns_maker() / is_admin() helpers).
-- Creates two public Supabase Storage buckets for maker-uploaded audio + images,
-- and the storage.objects RLS so a maker can only write under their own
-- "{maker_id}/..." prefix while anyone can read (public buckets serve via CDN).
--
-- The existing Atlas catalog keeps its audio/images on gh-pages — those URLs are
-- unchanged. Only NEW maker uploads land in these buckets; tour/stop rows simply
-- store whatever public URL the file ends up at. See docs/maker-dashboard-design.md.

begin;

-- ===========================================================================
-- Buckets (public-read; objects served at
--   https://<project>.supabase.co/storage/v1/object/public/<bucket>/<path>)
-- ===========================================================================
insert into storage.buckets (id, name, public)
values ('tour-audio',  'tour-audio',  true),
       ('tour-images', 'tour-images', true)
on conflict (id) do nothing;

-- ===========================================================================
-- RLS on storage.objects (Supabase enables RLS on this table by default).
-- Path convention: "{maker_id}/{tour_id}/{filename}". The first path segment is
-- the owning maker, so owns_maker() on segment[1] authorizes writes.
-- ===========================================================================
drop policy if exists "tour media public read" on storage.objects;
create policy "tour media public read" on storage.objects
    for select using (bucket_id in ('tour-audio', 'tour-images'));

drop policy if exists "maker upload own media" on storage.objects;
create policy "maker upload own media" on storage.objects
    for insert to authenticated
    with check (
        bucket_id in ('tour-audio', 'tour-images')
        and public.owns_maker(((storage.foldername(name))[1])::uuid)
    );

drop policy if exists "maker update own media" on storage.objects;
create policy "maker update own media" on storage.objects
    for update to authenticated
    using (
        bucket_id in ('tour-audio', 'tour-images')
        and public.owns_maker(((storage.foldername(name))[1])::uuid)
    );

drop policy if exists "maker delete own media" on storage.objects;
create policy "maker delete own media" on storage.objects
    for delete to authenticated
    using (
        bucket_id in ('tour-audio', 'tour-images')
        and public.owns_maker(((storage.foldername(name))[1])::uuid)
    );

drop policy if exists "admin manage media" on storage.objects;
create policy "admin manage media" on storage.objects
    for all to authenticated
    using (public.is_admin()) with check (public.is_admin());

commit;
