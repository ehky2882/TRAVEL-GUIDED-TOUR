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


def q(value):
    """Quote a scalar as a SQL literal (text/number/bool/None)."""
    if value is None:
        return "NULL"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return repr(value)
    return "'" + str(value).replace("'", "''") + "'"


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


def emit(data, out):
    makers, tours = data["makers"], data["tours"]
    places = validate_places(data)
    stop_count = sum(len(t["stops"]) for t in tours)

    w = out.write
    w("-- Generated by backend/seed_from_toursjson.py — do not edit by hand.\n")
    w(f"-- Source catalog: {len(makers)} makers / {len(tours)} tours / {stop_count} stops\n")
    w("begin;\n\n")

    w("-- makers\n")
    for m in makers:
        w(
            "insert into public.makers "
            "(id, display_name, avatar_url, avatar_emoji, bio, website_url) values ("
            f"{q(m['id'])}, {q(m['displayName'])}, {q(m.get('avatarURL'))}, "
            f"{q(m.get('avatarEmoji'))}, {q(m['bio'])}, {q(m.get('websiteURL'))})\n"
            "on conflict (id) do update set "
            "display_name = excluded.display_name, avatar_url = excluded.avatar_url, "
            "avatar_emoji = excluded.avatar_emoji, bio = excluded.bio, "
            "website_url = excluded.website_url, updated_at = now();\n"
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
                f"{text_array(p.get('additionalImageURLs'))}) "
                "on conflict (id) do update set "
                "name = excluded.name, description = excluded.description, "
                "latitude = excluded.latitude, longitude = excluded.longitude, "
                "city = excluded.city, address = excluded.address, "
                "hero_image_url = excluded.hero_image_url, "
                "additional_image_urls = excluded.additional_image_urls, "
                "updated_at = now();\n"
            )

    w("\n-- tours\n")
    for t in tours:
        w(
            "insert into public.tours "
            "(id, title, short_description, long_description, maker_id, hero_image_url, "
            "additional_image_urls, video_urls, video_role, source_url, source_author, "
            "kind, intro_audio_url, total_duration_seconds, "
            "walking_distance_meters, centroid_latitude, centroid_longitude, city, country, "
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
            f"{q(t['primaryCategory'])}, "
            f"{text_array(t.get('tags', []))}, {q(t.get('priceUSD', 0))}, "
            "'published', now())\n"
            "on conflict (id) do update set "
            "title = excluded.title, short_description = excluded.short_description, "
            "long_description = excluded.long_description, maker_id = excluded.maker_id, "
            "hero_image_url = excluded.hero_image_url, "
            "additional_image_urls = excluded.additional_image_urls, "
            "video_urls = excluded.video_urls, video_role = excluded.video_role, "
            "source_url = excluded.source_url, source_author = excluded.source_author, "
            "kind = excluded.kind, "
            "intro_audio_url = excluded.intro_audio_url, "
            "total_duration_seconds = excluded.total_duration_seconds, "
            "walking_distance_meters = excluded.walking_distance_meters, "
            "centroid_latitude = excluded.centroid_latitude, "
            "centroid_longitude = excluded.centroid_longitude, city = excluded.city, "
            "country = excluded.country, "
            "primary_category = excluded.primary_category, tags = excluded.tags, "
            "price_usd = excluded.price_usd, updated_at = now();\n"
        )

    # Membership, re-derived from the catalog on every seed.
    #
    # ⚠️ The reset is load-bearing. place_id lives on the TOUR row, so a tour
    # that leaves a place has to be actively cleared — an upsert alone leaves
    # the stale link behind and the tour keeps showing on a place page it no
    # longer belongs to. Clearing first is the only way membership can shrink.
    w("\n-- place membership\n")
    w("update public.tours set place_id = null where place_id is not null;\n")
    for p in places:
        ids = ", ".join(q(t) for t in p["tourIds"])
        w(f"update public.tours set place_id = {q(p['id'])} where id in ({ids});\n")

    w("\n-- stops (clear then re-insert per tour, in order)\n")
    for t in tours:
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
                "on conflict (id) do update set "
                "tour_id = excluded.tour_id, \"order\" = excluded.\"order\", "
                "title = excluded.title, caption = excluded.caption, "
                "latitude = excluded.latitude, longitude = excluded.longitude, "
                "audio_url = excluded.audio_url, "
                "audio_duration_seconds = excluded.audio_duration_seconds, "
                "trigger_mode = excluded.trigger_mode, "
                "trigger_radius_meters = excluded.trigger_radius_meters, "
                "image_url = excluded.image_url, transcript_text = excluded.transcript_text;\n"
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
