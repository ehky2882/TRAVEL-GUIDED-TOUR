#!/usr/bin/env python3
"""Generate idempotent seed SQL for the Atlas catalog from Tours.json.

Reads the bundled catalog (the source of truth) and emits INSERT ... ON
CONFLICT (id) DO UPDATE statements for makers -> tours -> stops, in FK order,
wrapped in a transaction. Re-runnable safely (upserts by id; stops for each
tour are replaced).

Usage:
    python3 backend/seed_from_toursjson.py                 # -> stdout
    python3 backend/seed_from_toursjson.py -o backend/seed.sql
    python3 backend/seed_from_toursjson.py --input path/to/Tours.json

Then run the output against Supabase (SQL editor, or `psql < seed.sql`).
Audio/image URLs are copied as-is — blob storage is out of scope here.
"""
import argparse
import json
import os
import sys

DEFAULT_INPUT = os.path.join(
    os.path.dirname(__file__), "..", "TRAVEL GUIDED TOUR", "Resources", "Tours.json"
)

# Closed sets — mirror schema.sql enums. Seeding a value outside these would
# fail the INSERT, so we catch it early with a clear message.
# 'link' is a link pin — someone else's post, played through that platform's
# embed. It carries no audio, so it is exempt from the audio checks below.
# ⚠️ Postgres has its own copy of this list as the `tour_kind` enum; both must
# agree or the seed is rejected by the type. See backend/add_link_pin_kind.sql.
KINDS = {"single", "multiStop", "link"}
TRIGGER_MODES = {"geofenced", "manual"}
CATEGORIES = {
    "history", "architecture", "visualArt", "musicAndPerformance", "literature",
    "foodAndDrink", "natureAndParks", "hiddenGems", "culturalHeritage", "sacredSites",
}


# How many tours one seed may delete before it refuses. A real content removal
# is a handful of rows; anything near this is a truncated or mis-parsed
# catalogue, and the right answer to that is to abort rather than empty the
# table. Generous enough for a whole city (the largest bureau is ~101 tours)
# and nowhere near the 4,000+ rows that are live.
PRUNE_CEILING = 300

# Below this many entries the catalogue is not small, it is BROKEN. Nothing
# legitimate shrinks it by an order of magnitude, and a partially-read file
# must never be allowed to author a delete.
MIN_SANE_TOURS = 1000


def q(value):
    """Quote a scalar as a SQL literal (text/number/bool/None)."""
    if value is None:
        return "NULL"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return repr(value)
    return "'" + str(value).replace("'", "''") + "'"


def date_or_null(value):
    """
    Quote a date for a `date` column, treating blank as NULL.

    🔴 `q("")` renders `''`, and Postgres accepts that for `text` and REJECTS it
    for `date` — `invalid input syntax for type date: ""`. The whole seed runs in
    one transaction under ON_ERROR_STOP=1, so one blank aborts the lot and the
    catalogue stops reaching the app.

    That is not hypothetical: **104 link pins carry `createdAt: ""`** rather than
    omitting the key, and the seed folds pins into `tours`, so they land in this
    column. An audit of `data["tours"]` alone does not see them — which is
    exactly how this shipped and broke the catalogue publish on 2026-09-15.

    ⚠️ The catalogue carries THREE shapes for this key, not two, and only one is
    fatal. Measured over 3,900 rows: 3,737 plain `"YYYY-MM-DD"`, 140 absent or
    blank, and **23 full ISO timestamps** (`"2026-09-05T00:00:00Z"`). Postgres
    accepts a timestamp for a `date` and truncates it, and `add_related_tours.sql`
    reads the column back out through `to_char(..., 'YYYY-MM-DD')`, so those 23
    normalise on their own and reach the app in the one format
    `Tour.createdAt` sorts by. They are passed through deliberately.
    """
    if value is None:
        return "NULL"
    text = str(value).strip()
    return q(text) if text else "NULL"


def text_array(values):
    """Render a Python list[str] as a Postgres text[] literal, or NULL."""
    if values is None:
        return "NULL"
    if len(values) == 0:
        return "ARRAY[]::text[]"
    inner = ", ".join("'" + str(v).replace("'", "''") + "'" for v in values)
    return f"ARRAY[{inner}]::text[]"


def merge_link_pins(data):
    """Fold the catalog's `linkPins` array back into `tours`.

    🔴 The split is a WIRE-FORMAT concern, not a storage one. Link pins travel
    under their own top-level key so that a build predating `TourKind.link`
    skips them as an unknown key instead of throwing on an unknown `kind` and
    losing the whole catalog decode — see
    `TRAVEL GUIDED TOUR/Data/ToursData.swift`.

    In Postgres they are ordinary rows in `public.tours` with `kind = 'link'`,
    exactly as before; it is `get_catalog` that splits them back out on the way
    out (`backend/split_link_pins.sql`). So everything below this line — the
    validator, the place membership check, the emitted SQL — keeps seeing one
    list of tours and needs no change at all.

    ⚠️ This must run BEFORE `validate_places`: the AMNH place legitimately
    names link pins among its members, and they would otherwise read as
    references to unknown tours and abort the seed.

    Tolerates a catalog that predates the split (no `linkPins` key), and one
    that has pins in both places (idempotent — merges by id, keeping `tours`).
    """
    pins = data.pop("linkPins", None) or []
    if not pins:
        return
    seen = {t["id"] for t in data["tours"]}
    data["tours"].extend(p for p in pins if p["id"] not in seen)


def validate_places(data):
    """Places are optional; when present their membership must resolve.

    Identity is exact-coordinate equality (owner decision 2026-08-18), which
    the Swift validator enforces. Here we only guard what the SQL cannot: a
    tourId that names no tour would produce an update touching zero rows and
    a place that silently loses a member.
    """
    places = data.get("places") or []
    tour_ids = {t["id"] for t in data["tours"]}
    seen = {}
    for p in places:
        if len(p.get("tourIds") or []) < 2:
            raise SystemExit(f"ERROR: place '{p.get('name')}' has fewer than 2 tours")
        for tid in p["tourIds"]:
            if tid not in tour_ids:
                raise SystemExit(f"ERROR: place '{p['name']}' references unknown tour {tid}")
            if tid in seen:
                raise SystemExit(
                    f"ERROR: tour {tid} is claimed by both '{seen[tid]}' and '{p['name']}'"
                )
            seen[tid] = p["name"]
    return places


def validate(data):
    errors = []
    # 🔴 THE FIRST CHECK, BECAUSE THE SEED NOW DELETES. Every other error here
    # stops a bad row; this one stops a bad FILE from authoring a mass delete.
    # A truncated read, a half-written catalogue or a merge that dropped an
    # array all look like "a smaller catalogue" to the code below, and the
    # prune would faithfully remove the difference. Nothing legitimate shrinks
    # the catalogue by an order of magnitude — a whole city is ~100 entries.
    if len(data["tours"]) < MIN_SANE_TOURS:
        sys.exit(
            f"ERROR: catalogue holds only {len(data['tours'])} entries, under the "
            f"{MIN_SANE_TOURS} floor. Refusing to seed: the prune would treat "
            "everything missing as deleted. Check the file before retrying."
        )
    maker_ids = {m["id"] for m in data["makers"]}
    for t in data["tours"]:
        if t["kind"] not in KINDS:
            errors.append(f"tour {t['id']} has unknown kind '{t['kind']}'")
        if t["primaryCategory"] not in CATEGORIES:
            errors.append(f"tour {t['id']} has unknown category '{t['primaryCategory']}'")
        if t["makerId"] not in maker_ids:
            errors.append(f"tour {t['id']} references unknown makerId '{t['makerId']}'")
        for s in t["stops"]:
            if s["triggerMode"] not in TRIGGER_MODES:
                errors.append(f"stop {s['id']} has unknown triggerMode '{s['triggerMode']}'")
    if errors:
        sys.stderr.write("Validation failed:\n  " + "\n  ".join(errors) + "\n")
        sys.exit(1)


def upsert_tail(table, pairs, touch_updated_at=True):
    """Render the `on conflict (id) do update` tail of an idempotent upsert.

    `pairs` is [(column, new_value_expression)] — normally
    ('title', 'excluded.title'), occasionally a coalesce that keeps what the
    database already holds.

    🔴 THE `where` GUARD IS THE POINT, AND IT IS GENERATED FROM THE SAME LIST
    AS THE `set`. Without it every upsert rewrote every row on every seed,
    whether or not anything had changed — measured against the real catalogue,
    an identical re-seed touched 3,745 of 3,745 tours, 424 of 424 makers and
    303 of 303 places. That is pure WAL, pure bloat and pure autovacuum work on
    an instance that ran out of memory for 11h45m on 2026-09-14, and it also
    made `updated_at` useless as a "what changed?" signal, because the answer
    was always "everything". See `docs/delta-catalog-fetch-design.md` § 6.

    ⚠️ Generating both halves from one list is deliberate. A hand-maintained
    `where` clause beside a hand-maintained `set` clause drifts the first time
    someone adds a column — and it drifts SILENTLY, in the dangerous direction:
    the new column changes, the guard does not notice, and the edit never
    reaches a phone. This is the same rotting-checklist failure
    `scripts/check-catalog-contract.py` exists to catch.

    ⚠️ Compare against `excluded.<col>`, never the raw literal. `excluded` has
    already been coerced to the column's type, so `numeric` meets `numeric` and
    an enum meets its own enum rather than an untyped string.
    """
    sets = ", ".join(f"{c} = {e}" for c, e in pairs)
    if touch_updated_at:
        sets += ", updated_at = now()"
    olds = ", ".join(f"{table}.{c}" for c, _ in pairs)
    news = ", ".join(e for _, e in pairs)
    return (
        f"on conflict (id) do update set {sets}\n"
        f"where ({olds}) is distinct from ({news});\n"
    )


def emit(data, out):
    makers, tours = data["makers"], data["tours"]
    places = validate_places(data)
    stop_count = sum(len(t["stops"]) for t in tours)

    w = out.write
    w("-- Generated by backend/seed_from_toursjson.py — do not edit by hand.\n")
    w(f"-- Source catalog: {len(makers)} makers / {len(tours)} tours / {stop_count} stops\n")
    w("begin;\n\n")

    # 🔴 Stops are upserted row by row now (they used to be deleted and
    # re-inserted wholesale), so inserting a stop into the middle of a walk
    # renumbers the ones after it and transiently collides with
    # `unique (tour_id, "order")`. Deferring the check to COMMIT judges the
    # final state instead of each intermediate step.
    #
    # ⚠️ This only has an effect once `backend/catalog_rev.sql` has made that
    # constraint DEFERRABLE; on a database that predates it the statement is a
    # harmless no-op, so the warning below is the only thing that would tell
    # anyone. A seed is otherwise unaffected — the single failure it prevents
    # is a stop REORDER, which is why this does not refuse to run.
    w("set constraints all deferred;\n")
    w(
        "do $$\n"
        "begin\n"
        "    if not exists (select 1 from pg_constraint\n"
        "                    where conrelid = 'public.stops'::regclass\n"
        "                      and conname = 'stops_tour_id_order_key'\n"
        "                      and condeferrable) then\n"
        "        raise notice 'stops_tour_id_order_key is not DEFERRABLE -- "
        "apply backend/catalog_rev.sql; reordering a walk''s stops would fail until then';\n"
        "    end if;\n"
        "end $$;\n\n"
    )

    w("-- makers\n")
    for m in makers:
        w(
            "insert into public.makers "
            "(id, display_name, avatar_url, avatar_emoji, bio, website_url, platform, handle) values ("
            f"{q(m['id'])}, {q(m['displayName'])}, {q(m.get('avatarURL'))}, "
            f"{q(m.get('avatarEmoji'))}, {q(m['bio'])}, {q(m.get('websiteURL'))}, "
            f"{q(m.get('platform'))}, {q(m.get('handle'))})\n"
            + upsert_tail("makers", [
                ("display_name", "excluded.display_name"),
                ("avatar_url", "excluded.avatar_url"),
                ("avatar_emoji", "excluded.avatar_emoji"),
                ("bio", "excluded.bio"),
                ("website_url", "excluded.website_url"),
                # platform/handle (backend/usernames.sql): a maker the catalogue
                # carries without them keeps what the database already holds —
                # the guard trigger derives one on insert — so a seed can never
                # blank a handle.
                #
                # ⚠️ The coalesce has to appear on BOTH sides, which is exactly
                # why the guard is generated from this list rather than written
                # out again by hand: comparing against a bare
                # `excluded.platform` would read every maker the catalogue
                # carries without a platform as changed, on every seed, forever.
                ("platform", "coalesce(excluded.platform, makers.platform)"),
                ("handle", "coalesce(excluded.handle, makers.handle)"),
            ])
        )

    # NOTE (paid tours, V2 Step 6): price_tier is deliberately absent from
    # both the column list and the DO UPDATE set. It is set per tour by the
    # maker in the app, not carried in Tours.json — so a content re-seed must
    # leave an existing tour's price untouched, and a brand-new tour defaults
    # to NULL (= free). Do not add it here.
    # Places come before tours: tours.place_id references them.
    #
    # NOTE the reset below. place_id lives on the tour row, so a tour that
    # LEAVES a place has to be actively cleared — an upsert alone would leave
    # the stale link in place and the tour would keep appearing on a place page
    # it no longer belongs to. Membership is re-derived from the catalog on
    # every seed, so clearing first is the only way it can shrink.
    if places:
        w("\n-- places\n")
        for p in places:
            w(
                "insert into public.places "
                "(id, name, description, latitude, longitude, city, address, "
                "hero_image_url, additional_image_urls) "
                f"values ({q(p['id'])}, {q(p['name'])}, {q(p.get('description'))}, "
                f"{p['latitude']}, {p['longitude']}, {q(p.get('city'))}, "
                f"{q(p.get('address'))}, {q(p.get('heroImageURL'))}, "
                f"{text_array(p.get('additionalImageURLs'))})\n"
                + upsert_tail("places", [
                    ("name", "excluded.name"),
                    ("description", "excluded.description"),
                    ("latitude", "excluded.latitude"),
                    ("longitude", "excluded.longitude"),
                    ("city", "excluded.city"),
                    ("address", "excluded.address"),
                    ("hero_image_url", "excluded.hero_image_url"),
                    ("additional_image_urls", "excluded.additional_image_urls"),
                ])
            )

    w("\n-- tours\n")
    for t in tours:
        w(
            "insert into public.tours "
            "(id, title, short_description, long_description, maker_id, hero_image_url, "
            "additional_image_urls, video_urls, video_role, source_url, source_author, "
            "kind, intro_audio_url, total_duration_seconds, "
            "walking_distance_meters, centroid_latitude, centroid_longitude, city, country, "
            "related_tour_ids, authored_on, "
            "primary_category, tags, price_usd, status, published_at) values ("
            f"{q(t['id'])}, {q(t['title'])}, {q(t['shortDescription'])}, "
            f"{q(t['longDescription'])}, {q(t['makerId'])}, {q(t['heroImageURL'])}, "
            f"{text_array(t.get('additionalImageURLs'))}, {text_array(t.get('videoURLs'))}, "
            f"{q(t.get('videoRole'))}, "
            # Link pins only — every other kind carries NULL. Absent here
            # would mean a curated pin silently loses the post it stands for
            # on the next content merge.
            f"{q(t.get('sourceURL'))}, {q(t.get('sourceAuthor'))}, "
            f"{q(t['kind'])}, "
            f"{q(t.get('introAudioURL'))}, {q(t['totalDurationSeconds'])}, "
            f"{q(t.get('walkingDistanceMeters'))}, {q(t['centroidLatitude'])}, "
            f"{q(t['centroidLongitude'])}, {q(t.get('city'))}, {q(t.get('country'))}, "
            f"{text_array(t.get('relatedTourIds'))}, "
            # 🔴 `authored_on`, NOT `created_at`. The audit column is
            # `not null default now()` and holds the moment the row was
            # SEEDED, so serving it as the catalogue's `createdAt` would look
            # fixed and rank by seed order — which is worse than the four sort
            # controls plainly doing nothing. This one is nullable on purpose:
            # a tour with no authored date has none, and sorts last.
            f"{date_or_null(t.get('createdAt'))}, "
            f"{q(t['primaryCategory'])}, "
            f"{text_array(t.get('tags', []))}, {q(t.get('priceUSD', 0))}, "
            "'published', now())\n"
            # ⚠️ `status`, `published_at`, `place_id` and `price_tier` are
            # deliberately absent from this list. The first two are written on
            # INSERT only; `place_id` is maintained by the membership pass
            # below; `price_tier` is set by the maker in the app and must
            # survive a content re-seed (see the NOTE above). Including any of
            # them in the guard would read as a change on every seed.
            + upsert_tail("tours", [
                ("title", "excluded.title"),
                ("short_description", "excluded.short_description"),
                ("long_description", "excluded.long_description"),
                ("maker_id", "excluded.maker_id"),
                ("hero_image_url", "excluded.hero_image_url"),
                ("additional_image_urls", "excluded.additional_image_urls"),
                ("video_urls", "excluded.video_urls"),
                ("video_role", "excluded.video_role"),
                ("source_url", "excluded.source_url"),
                ("source_author", "excluded.source_author"),
                ("kind", "excluded.kind"),
                ("intro_audio_url", "excluded.intro_audio_url"),
                ("total_duration_seconds", "excluded.total_duration_seconds"),
                ("walking_distance_meters", "excluded.walking_distance_meters"),
                ("centroid_latitude", "excluded.centroid_latitude"),
                ("centroid_longitude", "excluded.centroid_longitude"),
                ("city", "excluded.city"),
                ("country", "excluded.country"),
                ("related_tour_ids", "excluded.related_tour_ids"),
                # ⚠️ coalesce on BOTH sides, the platform/handle pattern: a
                # tour the catalogue carries without an authored date keeps
                # whatever the database already holds, so a seed run from an
                # older Tours.json can never blank one that has been backfilled.
                ("authored_on", "coalesce(excluded.authored_on, tours.authored_on)"),
                ("primary_category", "excluded.primary_category"),
                ("tags", "excluded.tags"),
                ("price_usd", "excluded.price_usd"),
            ])
        )

    # --- prune tours and pins that have left the catalogue ---------------
    #
    # 🔴 Until this existed the seed was UPSERT-ONLY, so deleting content from
    # Tours.json reached the gh-pages mirror and the bundled seed and NEVER
    # reached Postgres -- which is the app's PRIMARY source. The app went on
    # serving it. CLAUDE.md § Egress documented this as a known two-part manual
    # change; this is the missing half.
    #
    # 🔴 THE GUARD KEYS ON THE MAKER, NOT THE TOUR, AND THAT IS THE DESIGN.
    # `status` cannot tell a seeded tour from a maker's own upload -- measured
    # against production on 2026-09-17, ALL 4,382 rows are 'published'. What
    # does separate them is ownership: a seeded tour always belongs to a maker
    # that is in Tours.json, an in-app upload belongs to an account that is not
    # (500 makers live against 472 in the catalogue -- 28 real accounts). So
    # restricting the delete to catalogue makers cannot touch a user's work.
    #
    # ⚠️ Verified the same day: exactly ONE tour row was absent from the
    # catalogue -- "Pigalle Duperré Basketball" by "Wes the Wanderer", whose
    # maker row is NOT in Tours.json. This prune therefore deletes nothing
    # today, which is the right state in which to ship a destructive statement.
    #
    # ⚠️ ids are compared LOWERCASED ON BOTH SIDES. Pin ids are UPPERCASE in
    # Tours.json and lowercase out of Postgres; CLAUDE.md records that a naive
    # comparison "reports every pin as missing", and here that would mean
    # DELETING EVERY PIN.
    #
    # `stops`, library entries and journey rows are `on delete cascade`, so a
    # pruned tour takes its own dependents with it.
    w("\n-- prune tours and pins that no longer exist in the catalog\n")
    keep_tours = ", ".join(q(t["id"].lower()) for t in data["tours"])
    keep_makers = ", ".join(q(m["id"].lower()) for m in data["makers"])
    w(
        "do $$\n"
        "declare doomed int;\n"
        "begin\n"
        "    select count(*) into doomed from public.tours\n"
        f"     where lower(id::text) not in ({keep_tours})\n"
        f"       and lower(maker_id::text) in ({keep_makers});\n"
        # 🔴 A ceiling checked against the REAL table, inside the transaction.
        # The Python guard cannot see the database; this can. Under
        # ON_ERROR_STOP=1 a raise here aborts the whole seed, so a catalogue
        # that passed validation and would still gut the table takes nothing
        # with it.
        f"    if doomed > {PRUNE_CEILING} then\n"
        "        raise exception 'prune would delete % tours (ceiling %); "
        "refusing -- read the catalogue before retrying', doomed, "
        f"{PRUNE_CEILING};\n"
        "    end if;\n"
        "    delete from public.tours\n"
        f"     where lower(id::text) not in ({keep_tours})\n"
        f"       and lower(maker_id::text) in ({keep_makers});\n"
        "    raise notice 'pruned % tour row(s)', doomed;\n"
        "end $$;\n"
    )

    # Membership, re-derived from the catalog on every seed.
    #
    # ⚠️ The reset is load-bearing. place_id lives on the TOUR row, so a tour
    # that leaves a place has to be actively cleared — an upsert alone leaves
    # the stale link behind and the tour keeps showing on a place page it no
    # longer belongs to. Clearing first is the only way membership can shrink.
    w("\n-- place membership\n")
    # ⚠️ The clear is now scoped to tours that are NOT about to be re-linked.
    # Clearing every place_id and immediately setting it back again was ~700
    # tours rewritten twice on every seed — a real change to those rows as far
    # as Postgres and any change-tracking trigger is concerned, so it would have
    # defeated the whole point of the guards above for exactly the tours that
    # belong to a place.
    member_ids = [tid for p in places for tid in p["tourIds"]]
    if member_ids:
        keep = ", ".join(q(t) for t in member_ids)
        w(
            "update public.tours set place_id = null\n"
            f" where place_id is not null and id not in ({keep});\n"
        )
    else:
        w("update public.tours set place_id = null where place_id is not null;\n")

    # 🔴 And the places themselves have to be able to DISAPPEAR. The upsert
    # above can create and update a place but never remove one, so a place
    # deleted from Tours.json survived in the database as an EMPTY row — it
    # kept its name and its point on the map while owning nothing. Nothing
    # downstream objects: the row is valid, the count check simply reads one
    # too many, and the app is handed a place with no contents.
    #
    # This is exactly how `Westerkerk` leaked on 2026-09-11. Splitting the
    # Jordaan out of it left one entry describing Westerkerk, so the place was
    # dissolved in the catalogue — and the live count then read 267 against a
    # catalogue of 266, with 0 tours pointing at the orphan.
    #
    # ⚠️ ORDER IS LOAD-BEARING: this must come AFTER the place_id reset above,
    # because tours.place_id references places. Clear the links, then prune.
    w("\n-- prune places that no longer exist in the catalog\n")
    if places:
        keep = ", ".join(q(p["id"]) for p in places)
        w(f"delete from public.places where id not in ({keep});\n")
    else:
        w("delete from public.places;\n")
    for p in places:
        ids = ", ".join(q(t) for t in p["tourIds"])
        w(
            f"update public.tours set place_id = {q(p['id'])}\n"
            f" where id in ({ids}) and place_id is distinct from {q(p['id'])};\n"
        )

    # 🔴 STOPS ARE NO LONGER DELETED AND RE-INSERTED WHOLESALE.
    #
    # They used to be: `delete from stops where tour_id = X` followed by an
    # insert per stop, for EVERY tour, on EVERY seed — 4,117 deletes and 4,117
    # inserts five times a day to express, almost always, no change at all. It
    # also meant `stops` could not be dated even in principle, which is half of
    # why a delta cursor was impossible (docs/delta-catalog-fetch-design.md § 5).
    #
    # Now: remove only the stops that have actually gone, then upsert the rest
    # behind the same guard the other tables use. A tour whose stops are
    # unchanged costs one `delete ... where id not in (...)` that matches
    # nothing, and nothing else.
    #
    # ⚠️ A stop edit must still move its parent TOUR, or a cursor reading
    # `tours.rev` would never learn a coordinate had moved. That is a trigger,
    # not something this script can do — `backend/catalog_rev.sql` § 5.
    w("\n-- stops (remove what is gone, upsert what changed, per tour in order)\n")
    for t in tours:
        if t["stops"]:
            ids = ", ".join(q(s["id"]) for s in t["stops"])
            w(
                f"delete from public.stops where tour_id = {q(t['id'])}\n"
                f" and id not in ({ids});\n"
            )
        else:
            w(f"delete from public.stops where tour_id = {q(t['id'])};\n")
        for s in t["stops"]:
            w(
                "insert into public.stops "
                "(id, tour_id, \"order\", title, caption, latitude, longitude, audio_url, "
                "audio_duration_seconds, trigger_mode, trigger_radius_meters, image_url, "
                "transcript_text) values ("
                f"{q(s['id'])}, {q(t['id'])}, {q(s['order'])}, {q(s['title'])}, "
                f"{q(s.get('caption'))}, {q(s['latitude'])}, {q(s['longitude'])}, "
                f"{q(s['audioURL'])}, {q(s['audioDurationSeconds'])}, {q(s['triggerMode'])}, "
                f"{q(s.get('triggerRadiusMeters', 30))}, {q(s.get('imageURL'))}, "
                f"{q(s.get('transcriptText'))})\n"
                # `stops.updated_at` only exists once catalog_rev.sql has been
                # applied, so it is not written here — the trigger that file
                # installs maintains it, and a database that predates the
                # migration seeds exactly as it otherwise would.
                + upsert_tail("stops", [
                    ("tour_id", "excluded.tour_id"),
                    ('"order"', 'excluded."order"'),
                    ("title", "excluded.title"),
                    ("caption", "excluded.caption"),
                    ("latitude", "excluded.latitude"),
                    ("longitude", "excluded.longitude"),
                    ("audio_url", "excluded.audio_url"),
                    ("audio_duration_seconds", "excluded.audio_duration_seconds"),
                    ("trigger_mode", "excluded.trigger_mode"),
                    ("trigger_radius_meters", "excluded.trigger_radius_meters"),
                    ("image_url", "excluded.image_url"),
                    ("transcript_text", "excluded.transcript_text"),
                ], touch_updated_at=False)
            )

    # 🔴 The catalog is MATERIALISED (backend/catalog_snapshot.sql):
    # `get_catalog()` serves a pre-built row rather than rebuilding ~11 MB of
    # JSON per request. Nothing above is visible to the app until the snapshot
    # is rebuilt, so this call is what makes a seed take effect.
    #
    # It is the LAST statement and it is INSIDE the transaction, which is also
    # what fixes the torn read: MVCC keeps every reader on the previous
    # COMPLETE catalog until this commits, then moves them to the new complete
    # one. Before this, a client landing mid-seed could be served a mixture —
    # observed live on 2026-09-06, `tours` already updated while `places` was
    # still the old value.
    #
    # `to_regprocedure` returns NULL when the function is absent, so a database
    # that predates the migration seeds exactly as it always did rather than
    # failing on an unknown function.
    w(
        "\n-- Rebuild the materialised catalog (no-op if not yet migrated).\n"
        "do $$\n"
        "begin\n"
        "    if to_regprocedure('public.refresh_catalog_snapshot()') is not null then\n"
        "        perform public.refresh_catalog_snapshot();\n"
        "    else\n"
        "        raise notice 'refresh_catalog_snapshot() not present -- "
        "apply backend/catalog_snapshot.sql';\n"
        "    end if;\n"
        "end $$;\n"
    )

    w("\ncommit;\n")
    sys.stderr.write(
        f"OK: emitted seed for {len(makers)} makers / {len(tours)} tours / "
        f"{stop_count} stops / {len(places)} places\n"
    )


def main():
    p = argparse.ArgumentParser(description="Generate Atlas catalog seed SQL from Tours.json")
    p.add_argument("--input", default=DEFAULT_INPUT, help="path to Tours.json")
    p.add_argument("-o", "--output", help="output .sql file (default: stdout)")
    args = p.parse_args()

    with open(args.input) as f:
        data = json.load(f)
    merge_link_pins(data)
    validate(data)

    if args.output:
        with open(args.output, "w") as out:
            emit(data, out)
    else:
        emit(data, sys.stdout)


if __name__ == "__main__":
    main()
