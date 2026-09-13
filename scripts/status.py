#!/usr/bin/env python3
"""The live board, assembled from one file per entry instead of one shared file.

WHY THIS EXISTS. `STATUS.md` was a single file that every parallel session
prepended to, at the same three line numbers: the "Last verified" chain, the
builds table, and the branches table. Git conflicts are LINE-based, so two
sessions writing there collided every time — whether or not they disagreed
about anything. In the seven days before this was written, 67 commits touched
that file, and three pull requests in two days were blocked by a conflict in
it. Not one was a disagreement about code:

    #776  the catalogue version check   — blocked 2 days, docs conflict only
    #820  the Search count fix          — blocked 1 day,  docs conflict only
    #843  this board's own update       — conflicted while open

THE FIX IS STRUCTURAL, NOT A CONVENTION. A session never edits a shared file;
it ADDS a file whose name cannot collide (UTC timestamp + branch slug). Git
merges two new files at two different paths without a conflict, always. There
is no anchor to prepend to, so there is nothing to collide over.

    status/entries/<UTC>-<branch>.md   one session update. Never edited.
    status/owner/<slug>.md             one thing owed by the owner. DELETE to clear.
    status/builds/<number>.md          one TestFlight build. Numbers are unique
                                       already: they are github.run_number.

⚠️ Clearing an owner item is `git rm`, not an edit. Two sessions clearing two
different items touch two different paths, so that does not conflict either.

READING THE BOARD

    python3 scripts/status.py                 # the whole board, newest first
    python3 scripts/status.py --owner         # only what the owner owes
    python3 scripts/status.py --entries 5     # the last five session updates

WRITING TO IT — always through this script, never by hand. It generates the
filename, so two sessions cannot pick the same one:

    python3 scripts/status.py --add-entry "one-line summary" --body notes.md
    python3 scripts/status.py --add-owner  "slug" "title" --body notes.md
    python3 scripts/status.py --add-build  152 "what it carries" --body notes.md
    python3 scripts/status.py --clear-owner slug        # prints the git rm to run

`--body -` reads from stdin. With no body, the title is the whole entry.

🔴 WHAT DID NOT MOVE. `STATUS.md` still holds the sections that change rarely
and are edited deliberately: Content, Known debt, Verification traps. Those are
prose that gets revised, not a log that gets appended, and they have never been
the thing that conflicted.

🔴 THE BRANCHES TABLE IS GONE ON PURPOSE. It listed which branches were ahead of
main — which `scripts/session-start.sh` already derives from git on every run.
A hand-maintained copy of something git knows is stale the moment it is written,
and it was the second-most-conflicted region of the file.
"""
import argparse
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
STATUS_DIR = ROOT / "status"
ENTRIES, OWNER, BUILDS = STATUS_DIR / "entries", STATUS_DIR / "owner", STATUS_DIR / "builds"


def _slug(text, limit=48):
    s = re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")
    return (s[:limit].rstrip("-")) or "entry"


def _branch():
    try:
        b = subprocess.run(["git", "rev-parse", "--abbrev-ref", "HEAD"],
                           cwd=ROOT, capture_output=True, text=True, timeout=10).stdout.strip()
    except Exception:
        b = ""
    return _slug(b.replace("claude/", ""), 32) or "detached"


def _now():
    return datetime.now(timezone.utc)


def _read_body(arg):
    if arg is None:
        return ""
    if arg == "-":
        return sys.stdin.read().strip()
    p = Path(arg)
    if not p.exists():
        sys.exit(f"error: --body file not found: {arg}")
    return p.read_text(encoding="utf-8").strip()


def _write(path: Path, text: str):
    # 'x' mode: fails rather than silently overwriting a file another session
    # wrote. An overwrite already destroyed one session's handoff in this repo
    # (2026-09-11), because it checked for a free name and THEN wrote — a race.
    path.parent.mkdir(parents=True, exist_ok=True)
    try:
        with open(path, "x", encoding="utf-8") as f:
            f.write(text if text.endswith("\n") else text + "\n")
    except FileExistsError:
        sys.exit(f"error: {path.relative_to(ROOT)} already exists — refusing to overwrite.\n"
                 f"       Another session may have written it. Re-run to get a new timestamp.")
    print(f"wrote {path.relative_to(ROOT)}")


def add_entry(title, body):
    stamp = _now().strftime("%Y%m%dT%H%M%SZ")
    path = ENTRIES / f"{stamp}-{_branch()}.md"
    head = f"# {title}\n\n_{_now().strftime('%Y-%m-%d %H:%M UTC')} · branch `{_branch()}`_\n"
    _write(path, head + (f"\n{body}\n" if body else ""))


def add_owner(slug, title, body):
    path = OWNER / f"{_slug(slug)}.md"
    head = f"# {title}\n\n_opened {_now().strftime('%Y-%m-%d')} · clear with `git rm {path.relative_to(ROOT)}`_\n"
    _write(path, head + (f"\n{body}\n" if body else ""))


def add_build(number, title, body):
    if not str(number).isdigit():
        sys.exit("error: build number must be the numeric github.run_number, read back from the run list")
    path = BUILDS / f"{int(number)}.md"
    head = f"# Build {number} — {title}\n\n_{_now().strftime('%Y-%m-%d %H:%M UTC')}_\n"
    _write(path, head + (f"\n{body}\n" if body else ""))


def _files(d, newest_first=True):
    if not d.exists():
        return []
    fs = sorted([p for p in d.iterdir() if p.suffix == ".md"], reverse=newest_first)
    return fs


def show(entries_limit, owner_only):
    print(f"BOARD · assembled {_now().strftime('%Y-%m-%d %H:%M UTC')} · "
          f"{len(_files(OWNER))} owner item(s), {len(_files(ENTRIES))} entries, {len(_files(BUILDS))} builds")
    print("⚠️  Perishable state is NOT stored here. Run scripts/session-start.sh for what is live.\n")

    owed = _files(OWNER, newest_first=False)
    print("=" * 72)
    print(f"OWED BY THE OWNER — {len(owed)} item(s)" if owed else "OWED BY THE OWNER — nothing")
    print("=" * 72)
    for p in owed:
        print(f"\n--- {p.name} ---\n{p.read_text(encoding='utf-8').strip()}")
    if owner_only:
        return

    builds = _files(BUILDS)[:3]
    if builds:
        print("\n" + "=" * 72)
        print("RECENT BUILDS")
        print("=" * 72)
        for p in sorted(builds, key=lambda x: int(x.stem), reverse=True):
            print(f"\n--- build {p.stem} ---\n{p.read_text(encoding='utf-8').strip()}")

    ents = _files(ENTRIES)[:entries_limit]
    if ents:
        print("\n" + "=" * 72)
        print(f"SESSION ENTRIES — newest {len(ents)} of {len(_files(ENTRIES))}")
        print("=" * 72)
        for p in ents:
            print(f"\n--- {p.name} ---\n{p.read_text(encoding='utf-8').strip()}")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--entries", type=int, default=3, help="how many session entries to print (default 3)")
    ap.add_argument("--owner", action="store_true", help="print only what the owner owes")
    ap.add_argument("--add-entry", metavar="TITLE")
    ap.add_argument("--add-owner", nargs=2, metavar=("SLUG", "TITLE"))
    ap.add_argument("--add-build", nargs=2, metavar=("NUMBER", "TITLE"))
    ap.add_argument("--clear-owner", metavar="SLUG")
    ap.add_argument("--body", metavar="FILE", help="body text from a file, or - for stdin")
    a = ap.parse_args()

    if a.add_entry:
        return add_entry(a.add_entry, _read_body(a.body))
    if a.add_owner:
        return add_owner(a.add_owner[0], a.add_owner[1], _read_body(a.body))
    if a.add_build:
        return add_build(a.add_build[0], a.add_build[1], _read_body(a.body))
    if a.clear_owner:
        p = OWNER / f"{_slug(a.clear_owner)}.md"
        if not p.exists():
            sys.exit(f"error: no such owner item: {p.relative_to(ROOT)}\n"
                     f"       open items: {', '.join(x.stem for x in _files(OWNER)) or '(none)'}")
        print(f"git rm {p.relative_to(ROOT)}")
        print("⚠️  Clearing is a DELETE, not an edit — that is what keeps it conflict-free.")
        return
    show(a.entries, a.owner)


if __name__ == "__main__":
    # Piping into `head` closes the pipe early; without this, an ordinary
    # `status.py | head` ends in a BrokenPipeError traceback that reads like
    # the script failed. Exit quietly instead, the way a shell tool should.
    try:
        main()
    except BrokenPipeError:
        try:
            sys.stdout.close()
        finally:
            os._exit(0)
